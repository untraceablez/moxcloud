#!/bin/bash

# --- Dependency Check ---
check_and_install_packages() {
  local packages_to_install=()
  
  # Check for wget
  if ! command -v wget &> /dev/null; then
    echo "wget not found. Adding to install list."
    packages_to_install+=("wget")
  fi
  
  # Check for virt-customize (from libguestfs-tools)
  if ! command -v virt-customize &> /dev/null; then
    echo "libguestfs-tools (virt-customize) not found. Adding to install list."
    packages_to_install+=("libguestfs-tools")
  fi
  
  # If the array is not empty, update apt and install missing packages
  if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "Updating apt repositories..."
    sudo apt update
    echo "Installing missing packages: ${packages_to_install[@]}"
    sudo apt install -y "${packages_to_install[@]}"
    
    if [ $? -ne 0 ]; then
      echo "Error: Failed to install required packages. Exiting."
      exit 1
    fi
    echo "Required packages installed."
  else
    echo "All required packages are already installed."
  fi
}

# Run the dependency check
check_and_install_packages
# --- END Dependency Check ---


# Set the following variables in order to make the script function. 
TEMPLATE_CONFIG="./template-config.txt"
TEMPLATE_SETUP="./template-setup.sh"
ENV_FILE="./.env"

# Check for .env file and source it
if [[ -f "$ENV_FILE" ]]; then
  echo "Sourcing variables from $ENV_FILE..."
  source "$ENV_FILE"
else
  echo "Error: $ENV_FILE not found."
  echo "Please run ./template-setup.sh or create it manually."
  exit 1
fi

# Check for preexisting template-config.txt
if [[ -f "$TEMPLATE_CONFIG" && -s "$TEMPLATE_CONFIG" ]]; then
  # File exists and is not empty, source it and continue.
  source "$TEMPLATE_CONFIG"
  echo "template-config.txt sourced successfully."

  # Place your main script logic here.
  echo "Provisioning VM Template..."
LOCAL_MANIFEST="./$RELEASE-server-cloudimg-amd64.manifest"
REMOTE_MANIFEST="https://cloud-images.ubuntu.com/$RELEASE/current/$RELEASE-server-cloudimg-amd64.manifest"

# Read the space-separated list from .env into the KEY_FILES array
IFS=' ' read -r -a KEY_FILES <<< "$CI_SSH_KEY_FILES"

# Downloads local copy of manifest if not already present
if [ ! -f "$LOCAL_MANIFEST" ]; then
  echo "Local manifest file does not exist. Downloading..."
  wget "$REMOTE_MANIFEST"

  if [ $? -eq 0 ]; then
    echo "Download complete."
  else
    echo "Download failed."
    rm -f "$LOCAL_MANIFEST"
  fi
else
  echo "Local manifest file exists. No download needed."
fi

# Main loop for script. Compares cloud-init image manifests before refreshing template.
REMOTE_TMP_MANIFEST=$(mktemp)
wget -q "$REMOTE_MANIFEST" -O "$REMOTE_TEMP_MANIFEST"

if ! cmp -s "$LOCAL_MANIFEST" < "$REMOTE_TEMP_MANIFEST" || ! sudo qm status $VM_ID >/dev/null 2>&1; then
  echo "Manifest files differ or template is missing. Now updating cloud-init image..."
  rm -rf "$LOCAL_MANIFEST"
  cp "$REMOTE_TMP_MANIFEST" "$LOCAL_MANIFEST"
  rm -f $RELEASE-server-cloudimg-amd64.img
  wget https://cloud-images.ubuntu.com/$RELEASE/current/$RELEASE-server-cloudimg-amd64.img
  echo "Updated image downloaded."
  
  # --- IMPROVED: Check if VM exists before trying to destroy it ---
  if sudo qm status $VM_ID >/dev/null 2>&1; then
    echo "Attempting to destroy existing template (VM ID: $VM_ID)..."
    sudo qm destroy $VM_ID --destroy-unreferenced-disks true
    if [ $? -ne 0 ]; then
        echo "Error: Failed to destroy existing VM template. It may be locked or have other issues."
        exit 1
    fi
    echo "Existing template destroyed."
  fi
  
# --- Build and run dynamic package install ---
  echo "Preparing to install custom packages..."
  IMAGE_FILE="$RELEASE-server-cloudimg-amd64.img"
  VIRT_CUSTOMIZE_ARGS=("-a" "$IMAGE_FILE" "--install" "qemu-guest-agent")

  if [ -n "$CI_PACKAGES" ]; then
      IFS=' ' read -r -a PKG_ARRAY <<< "$CI_PACKAGES"
      echo "Adding extra packages from .env: ${PKG_ARRAY[@]}"
      for pkg in "${PKG_ARRAY[@]}"; do
          VIRT_CUSTOMIZE_ARGS+=("--install" "$pkg")
      done
  else
      echo "No extra packages specified in CI_PACKAGES. Installing qemu-guest-agent only."
  fi

  # Add command to reset machine-id (resolves issues with using finished template with Terraform/OpenTofu)
  VIRT_CUSTOMIZE_ARGS+=("--run-command" "echo -n > /etc/machine-id")

  echo "Installing packages and customizing image..."
  sudo virt-customize "${VIRT_CUSTOMIZE_ARGS[@]}"
  # --- END PACKAGE INSTALL ---

  echo "Now customizing your VM.."
  sudo qm create $VM_ID --name $VM_NAME --memory 2048 --cores 1 --net0 virtio,bridge=vmbr0
  sudo qm importdisk $VM_ID $IMAGE_FILE $VM_STOR
  sudo qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_STOR:vm-$VM_ID-disk-0
  sudo qm set $VM_ID --boot c --bootdisk scsi0
  sudo qm set $VM_ID --ide2 $VM_STOR:cloudinit
  sudo qm set $VM_ID --serial0 socket --vga serial0
  sudo qm set $VM_ID --agent enabled=1

  # --- Stage Cloud-Init Settings ---
  
  echo "Staging cloud-init settings from .env..."
  
  # Set default user
  if [ -n "$CI_USER" ]; then
    sudo qm set $VM_ID --ciuser "$CI_USER"
    echo "Default user staged: $CI_USER"
  else
    echo "Warning: CI_USER not set in .env. Cloud image default user will be used."
  fi

  # Set network to DHCP
  echo "Staging network config for DHCP..."
  sudo qm set $VM_ID --ipconfig0 ip=dhcp

  # Stage DNS Settings
  if [ -n "$CI_DNS_SERVERS" ]; then
    sudo qm set $VM_ID --nameserver "$CI_DNS_SERVERS"
    echo "DNS servers staged: $CI_DNS_SERVERS"
  fi
  if [ -n "$CI_DNS_DOMAIN" ]; then
    sudo qm set $VM_ID --searchdomain "$CI_DNS_DOMAIN"
    echo "DNS search domain staged: $CI_DNS_DOMAIN"
  fi

  # Stage SSH Keys
  echo "Staging SSH Keys from paths in .env..."
  SSH_KEY_TEMP_FILE=$(mktemp)
  
  for KEY_FILE in "${KEY_FILES[@]}"; do
    # Use eval to correctly expand tilde (~)
    KEY_FILE_EXPANDED=$(eval echo "$KEY_FILE")
    if [ -f "$KEY_FILE_EXPANDED" ]; then
      cat "$KEY_FILE_EXPANDED" >> "$SSH_KEY_TEMP_FILE"
      echo "" >> "$SSH_KEY_TEMP_FILE" # Ensure newline between keys
    else
      echo "Warning: Key file $KEY_FILE (expanded to $KEY_FILE_EXPANDED) not found."
    fi
  done

  if [ -s "$SSH_KEY_TEMP_FILE" ]; then
    # File has content, so set it
    sudo qm set $VM_ID --sshkeys "$SSH_KEY_TEMP_FILE"
    echo "SSH Keys staged for cloud-init."
  else
    echo "No valid SSH keys were found. Skipping SSH key injection."
  fi

  # Clean up the temp file
  rm -f "$SSH_KEY_TEMP_FILE"
  
  # --- APPLY ALL STAGED CHANGES ---
  echo "Applying all staged cloud-init settings..."
  sudo qm cloudinit update $VM_ID
  echo "Cloud-init image has been updated."

  echo "Converting into cloud-init template"
  sudo qm template $VM_ID
else
  echo "Manifest files are the same and template exists, no update needed."
fi


else
  # File does not exist or is empty.
  if [[ -f "$TEMPLATE_CONFIG" ]]; then
      #The file exists, but it's empty, so delete it.
      rm "$TEMPLATE_CONFIG"
      echo "template-config.txt was empty and has been removed."
  else
      echo "template-config.txt does not exist."
  fi

# Run template-setup.sh
  if [[ -f "$TEMPLATE_SETUP" ]]; then
      echo "Running $TEMPLATE_SETUP..."
      ./"$TEMPLATE_SETUP"
  else
      echo "Error: $TEMPLATE_SETUP not found."
      exit 1 # Exit with an error code
  fi
fi