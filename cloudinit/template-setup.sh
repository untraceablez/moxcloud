#!/bin/bash

ENV_FILE="./.env"

# Function to create the sample .env file
create_sample_env() {
  echo "Creating sample $ENV_FILE..."
  cat << EOF > "$ENV_FILE"
# Cloud-Init User
# The default admin user to be created in the template.
# SSH keys will be assigned to this user.
CI_USER="admin"

# Cloud-Init User Password
# The password for the default admin user.
CI_USER_PASSWORD="admin"

# Cloud-Init DNS Settings
# Comma-separated list for multiple servers
CI_DNS_SERVERS="1.1.1.1,8.8.8.8"
CI_DNS_DOMAIN="homelab.local"

# Cloud-Init SSH Keys
# Space-separated list of public key FILE PATHS
CI_SSH_KEY_FILES="~/.ssh/your_key.pub"

# Cloud-Init Packages
# Space-separated list of additional packages to install into the image.
# qemu-guest-agent is already installed by the script.
CI_PACKAGES="neofetch htop qemu-utils"
EOF
}

# Check if .env file exists. If not, create it and exit.
if [ ! -f "$ENV_FILE" ]; then
  create_sample_env
  echo "" # Add newline for readability
  echo "Please update the generated .env file then run this script again."
  exit 0
fi

# --- Script continues from here ONLY if .env exists ---
echo "$ENV_FILE found. Proceeding with configuration..."

# Source the .env file to get current values
source "$ENV_FILE"

if [[ -f template-config.txt ]]; then
  rm template-config.txt
fi

# Prompt for user and password
read -p "Enter username (default: admin): " CI_USER
if [ -z "$CI_USER" ]; then
  CI_USER="admin"
fi

read -sp "Enter user password (default: admin): " CI_USER_PASSWORD
echo "" # Add newline after hidden password input
if [ -z "$CI_USER_PASSWORD" ]; then
  CI_USER_PASSWORD="admin"
fi

# Update the .env file with the user credentials
sed -i "s/^CI_USER=.*/CI_USER=\"$CI_USER\"/" "$ENV_FILE"
sed -i "s/^CI_USER_PASSWORD=.*/CI_USER_PASSWORD=\"$CI_USER_PASSWORD\"/" "$ENV_FILE"

# Prompt for packages to install
read -p "Enter space-separated list of packages to install (default: neofetch htop qemu-utils): " PACKAGES
if [ -z "$PACKAGES" ]; then
  PACKAGES="neofetch htop qemu-utils"
fi

# Update the .env file with the new packages
sed -i "s/^CI_PACKAGES=.*/CI_PACKAGES=\"$PACKAGES\"/" "$ENV_FILE"

read -p "Enter VM ID (default: 9000): " VM_ID
if [ -z "$VM_ID" ]; then
  VM_ID=9000
fi

read -p "Enter RELEASE (default: noble): " RELEASE
if [ -z "$RELEASE" ]; then
  RELEASE="noble"
fi

DATE=$(date +%m-%d-%y)
read -p "Enter VM NAME (default: cloudinit-template-$DATE). If you want the current date in your name, enter your name like so \'my-template-DATE\': " VM_NAME
if [ -z "$VM_NAME" ]; then
  VM_NAME="cloudinit-template-$DATE"
elif [[ "$VM_NAME" == *"-DATE"* ]]; then
  VM_NAME="${VM_NAME/-DATE/-$DATE}"
fi

read -p "Enter VM STORAGE (default: local-lvm): " VM_STOR
if [ -z "$VM_STOR" ]; then
  VM_STOR="local-lvm"
fi

# Prompt for hours (24-hour format, comma-separated)
read -p "Enter hours in 24-hr format to run template-script.sh (e.g., 9,21): " HOURS
if [ -z "$HOURS" ]; then
  HOURS="9,21"
fi

# Prompt for day-of-month
read -p "Enter the day of the month you want the script to run (default *):" DAYOFMONTH
if [ -z "$DAYOFMONTH" ]; then
  DAYOFMONTH="*"
fi

# Prompt for month
read -p "Enter the months you want the script to run (default *):" MONTH
if [ -z "$MONTH" ]; then
  MONTH="*"
fi

# Prompt for days of the week
read -p "Enter days of the week to run template-script.sh (e.g., Mon,Wed,Fri or * for every day): " DAYS_OF_WEEK
if [ -z "$DAYS_OF_WEEK" ]; then
  DAYS_OF_WEEK="Mon,Fri"
fi

CRON_JOBS=""
IFS=',' read -ra HOUR_ARRAY <<< "$HOURS" # Split the hours by comma
first_cron=true
for hour in "${HOUR_ARRAY[@]}"; do
  if [[ "$hour" =~ ^([0-1]?[0-9]|2[0-3])$ ]]; then
    minute="0" # Set minute to 0
    if $first_cron ; then
      CRON_JOBS="$minute $hour $DAYOFMONTH $MONTH $DAYS_OF_WEEK $SCRIPT_PATH"
      first_cron=false
    else
      CRON_JOBS="$CRON_JOBS $minute $hour $DAYOFMONTH $MONTH $DAYS_OF_WEEK $SCRIPT_PATH"
    fi
  else
    echo "Error: Invalid hour format: $hour"
    exit 1
  fi
done

# Clear crontab before adding new jobs
crontab -r 2>/dev/null

echo "Cron job entries:"
echo "$CRON_JOBS"

# Add the generated cron jobs to crontab
echo "$CRON_JOBS" | crontab -

# Display the entered values for verification
echo "VM ID: $VM_ID"
echo "RELEASE: $RELEASE"
echo "VM NAME: $VM_NAME"
echo "VM STORAGE: $VM_STOR"
echo "CRON_JOBS=\"$CRON_JOBS\""

# Save all variables to template-config.txt
echo "VM_ID=$VM_ID" >> template-config.txt
echo "RELEASE=$RELEASE" >> template-config.txt
echo "VM_NAME=$VM_NAME" >> template-config.txt
echo "VM_STOR=$VM_STOR" >> template-config.txt
echo "CRON_JOBS=\"$CRON_JOBS\"" >> template-config.txt

echo ""
echo "Configuration saved to template-config.txt."
