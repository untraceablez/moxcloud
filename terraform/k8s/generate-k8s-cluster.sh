#!/bin/bash

# generate-k8s-cluster.sh
# Script to generate main.tf and vars.tf files for Kubernetes control and worker nodes
#
# Usage: ./generate-k8s-cluster.sh [control_count] [worker_count]
# Default: 3 control nodes, 3 worker nodes

set -e

# Configuration
CONTROL_COUNT="${1:-3}"
WORKER_COUNT="${2:-3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_DIR="$SCRIPT_DIR/control"
WORKER_DIR="$SCRIPT_DIR/worker"

echo "=== Kubernetes Cluster Generator ==="
echo "Control nodes: $CONTROL_COUNT"
echo "Worker nodes:  $WORKER_COUNT"
echo ""

# Function to generate vars.tf
generate_vars_tf() {
    local output_file=$1

    cat > "$output_file" <<'EOF'
variable "ssh_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/RZbm5RbLL35DXml9VP8H0AJOqQcJ/pEAXLYTk5k4aK2EUSAmDZX2eHdpHnExa54LUh/W9TFV0zBpLFwJtL5ZWB5Sqrj2LBFWrpgsE6rgyAnffTQwoABQ0cac7ETqhHSL3X2FAooOUQPvoYvte+bnbfeS/qpgSkJjYepxqjFsdVxoWCBipdUCQwPe7uCdAhyWn8ftV4GVsvSI7jeUx/FFpwxfElOreuYyDL9TIvWtASrrrZgg4nY5x9hXYbd5GpyZD2HXp03CT1KULSB7jadaPTsTf9HJiNu+Gg9xnDlQZDWArK3aCUCc1T2rtS/Fgt9IK0t3qvmdFT0Lekf+f53361GZYV9Xb4+lgHBlHqM1l6AOSvw+HrJgvNnqeoOQ+ikgtUgik/E7i0EkAr0lFqrZrTFi3dRBgl6tG+gjbaQufhjqURuXqNtUYY8AscUCwzz3kGNsGIhESFCTbkVZxcTCZA8qCT9yCpmWCiCRrBgTpjDUdblwsw4LvPaGhJVPsTq06ncxXDYwHsZrWxM6rJc6uqvksi/6R+A9wEChVbx0nqhmdQrvOZsTxQVitNSYB4dNNtO1zZHU0GpCGdav+8SIqpSk1wP8WQQYafXieXGgoydk0ABOkAzwYcVcdX/KyuximETDTaPoAf1rwiFgEfnA7+612vF8o+IlF+7S1NbHww=="
}

variable "proxmox_host_01" {
  default = "cave"
}

variable "proxmox_host_02" {
  default = "mine"
}

variable "proxmox_host_03" {
  default = "plant"
}

variable "proxmox_host_04" {
  default = "tower"
}

variable "template_name" {
  default = "terraform-12-17-25"
}

variable "proxmox_api_url" {
  default = "https://10.0.0.192:8006/api2/json"
}

variable "proxmox_api_token_id" {
  default = "terraform-prov@pve!token-01"
}

variable "proxmox_api_token_secret" {
  default = "4eb5e927-10d4-4180-b65c-35e44b38967b"
}

variable "vm_ip_prefix" {
  default = "10.0.0.0"
}

variable "vm_ip_start_octet" {
  default = 61
}

variable "vm_gateway" {
  default = "10.0.0.1"
}

variable "vm_subnet_mask" {
  default = "/24"
}
EOF

    echo "✓ Generated $output_file"
}

# Function to generate control node main.tf
generate_control_tf() {
    local count=$1
    local output_file="$CONTROL_DIR/main.tf"

    cat > "$output_file" <<'EOF'
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

locals {
  target_hosts = [
    var.proxmox_host_01,
    var.proxmox_host_02,
    var.proxmox_host_03,
    var.proxmox_host_04,
  ]
}

# --- Resource Definition ---
resource "proxmox_vm_qemu" "k8sDev" {
  # Create control plane instances
EOF

    echo "  count = $count" >> "$output_file"

    cat >> "$output_file" <<'EOF'

  # --- VM Naming ---
  name = "k8s-dev-ctrl-0${count.index + 1}"

  # --- Target Node ---
  target_node = local.target_hosts[count.index % length(local.target_hosts)]

  # --- Source Template ---
  clone = var.template_name

  # --- VM Base Configuration ---
  agent    = 1 # Enable QEMU guest agent
  os_type  = "cloud-init"
  cpu {
    cores = 2
    sockets  = 1
    }
  memory   = 2048 # 2GB RAM
  scsihw   = "virtio-scsi-pci"
  boot     = "order=scsi0" # Explicitly set boot order, scsi0 first
  tags     = "k8s,control-plane"

  # --- Disk Configuration ---
  # The 'disks' block is specific to provider v3+ and contains only disk definitions

  disks {
    # Cloud-Init Drive (attached via IDE for compatibility)
    ide {
      ide2 { # Usually ide2 for cloudinit, check your template/setup
        cloudinit {
          storage = "local-zfs" # Storage for the temporary cloud-init ISO
        }
      }
    }
    # Main OS Disk
    scsi {
      scsi0 {
        disk {
          # Arguments are now directly under scsi0, not a nested 'disk' block
          storage = "talos-hosts" # Storage Pool ID for the disk
          size    = 32    # Size in GB (no 'G')
          # iothread = true  # Use iothread
          # 'type' and 'storage_type' are removed as they caused errors.
          # For RBD storage pools defined in Proxmox, 'storage_type' might be implicit.
          # You might need a 'format' argument depending on provider version/storage type
          # e.g., format = "raw" for RBD/LVM-thin, format = "qcow2" for file storage
        }
      }
    }
  } # End of disks block

  # --- Network Configuration ---
  # 'network' block is now top-level under the resource
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr0"
    tag    = 5
  }

  # --- Cloud-Init Configuration ---
  # 'ipconfig0' and 'sshkeys' are now top-level under the resource
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"

  sshkeys = <<EOT
  ${var.ssh_key}
  EOT

  # --- Lifecycle ---
  lifecycle {
    ignore_changes = [
      # Note: ignore_changes on network might prevent TF from updating IPs if needed.
      # Consider removing if you want TF to manage network fully.
      network,
    ]
  }
}
EOF

    echo "✓ Generated $output_file with $count control nodes"
}

# Function to generate worker node main.tf
generate_worker_tf() {
    local count=$1
    local output_file="$WORKER_DIR/main.tf"

    cat > "$output_file" <<'EOF'
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

locals {
  target_hosts = [
    var.proxmox_host_01,
    var.proxmox_host_02,
    var.proxmox_host_03,
    var.proxmox_host_04,
  ]
}

# --- Resource Definition ---
resource "proxmox_vm_qemu" "k8sDevWorker" {
  # Create worker instances
EOF

    echo "  count = $count" >> "$output_file"

    cat >> "$output_file" <<'EOF'

  # --- VM Naming ---
  name = "k8s-dev-wrkr-0${count.index + 1}"

  # --- Target Node ---
  target_node = local.target_hosts[count.index % length(local.target_hosts)]

  # --- Source Template ---
  clone = var.template_name

  # --- VM Base Configuration ---
  agent    = 1 # Enable QEMU guest agent
  os_type  = "cloud-init"
  cpu {
    cores = 2
    sockets  = 1
    }
  memory   = 2048 # 2GB RAM
  scsihw   = "virtio-scsi-pci"
  boot     = "order=scsi0" # Explicitly set boot order, scsi0 first
  tags     = "k8s,worker"

  # --- Disk Configuration ---
  # The 'disks' block is specific to provider v3+ and contains only disk definitions

  disks {
    # Cloud-Init Drive (attached via IDE for compatibility)
    ide {
      ide2 { # Usually ide2 for cloudinit, check your template/setup
        cloudinit {
          storage = "local-zfs" # Storage for the temporary cloud-init ISO
        }
      }
    }
    # Main OS Disk
    scsi {
      scsi0 {
        disk {
          # Arguments are now directly under scsi0, not a nested 'disk' block
          storage = "talos-hosts" # Storage Pool ID for the disk
          size    = 32    # Size in GB (no 'G')
          # iothread = true  # Use iothread
          # 'type' and 'storage_type' are removed as they caused errors.
          # For RBD storage pools defined in Proxmox, 'storage_type' might be implicit.
          # You might need a 'format' argument depending on provider version/storage type
          # e.g., format = "raw" for RBD/LVM-thin, format = "qcow2" for file storage
        }
      }
    }
  } # End of disks block

  # --- Network Configuration ---
  # 'network' block is now top-level under the resource
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr0"
    tag    = 5
  }

  # --- Cloud-Init Configuration ---
  # 'ipconfig0' and 'sshkeys' are now top-level under the resource
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"

  sshkeys = <<EOT
  ${var.ssh_key}
  EOT

  # --- Lifecycle ---
  lifecycle {
    ignore_changes = [
      # Note: ignore_changes on network might prevent TF from updating IPs if needed.
      # Consider removing if you want TF to manage network fully.
      network,
    ]
  }
}
EOF

    echo "✓ Generated $output_file with $count worker nodes"
}

# Validate inputs
if ! [[ "$CONTROL_COUNT" =~ ^[0-9]+$ ]] || [ "$CONTROL_COUNT" -lt 0 ]; then
    echo "Error: Control count must be a non-negative integer"
    exit 1
fi

if ! [[ "$WORKER_COUNT" =~ ^[0-9]+$ ]] || [ "$WORKER_COUNT" -lt 0 ]; then
    echo "Error: Worker count must be a non-negative integer"
    exit 1
fi

# Generate the files
generate_vars_tf "$CONTROL_DIR/vars.tf"
generate_vars_tf "$WORKER_DIR/vars.tf"
generate_control_tf "$CONTROL_COUNT"
generate_worker_tf "$WORKER_COUNT"

echo ""
echo "=== Summary ==="
echo "Generated Terraform configurations for:"
echo "  - $CONTROL_COUNT control plane nodes (k8s-dev-ctrl-01 to k8s-dev-ctrl-0$CONTROL_COUNT)"
echo "  - $WORKER_COUNT worker nodes (k8s-dev-wrkr-01 to k8s-dev-wrkr-0$WORKER_COUNT)"
echo ""
echo "Files created:"
echo "  - $CONTROL_DIR/main.tf"
echo "  - $CONTROL_DIR/vars.tf"
echo "  - $WORKER_DIR/main.tf"
echo "  - $WORKER_DIR/vars.tf"
echo ""
echo "Next steps:"
echo "  1. Review the generated files"
echo "  2. Initialize Terraform: cd control && terraform init"
echo "  3. Plan deployment: terraform plan"
echo "  4. Apply configuration: terraform apply"
echo ""
echo "Note: Each directory (control/worker) should be applied separately."
