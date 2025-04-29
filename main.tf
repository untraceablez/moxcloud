terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
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
  ]
}

# --- Resource Definition ---
resource "proxmox_vm_qemu" "k8sTest" {
  # Create instances (set back to 9 if needed, using 3 for testing based on your paste)
  count = 9

  # --- VM Naming ---
  name = "k8s-test-0${count.index + 1}"

  # --- Target Node ---
  target_node = local.target_hosts[count.index % 3]

  # --- Source Template ---
  clone = var.template_name

  # --- VM Base Configuration ---
  agent    = 1 # Enable QEMU guest agent
  os_type  = "cloud-init"
  cores    = 2
  sockets  = 1
  cpu_type = "kvm64"
  memory   = 2048 # 2GB RAM
  scsihw   = "virtio-scsi-pci"
  boot     = "order=scsi0" # Explicitly set boot order, scsi0 first
  tags     = "k8s"

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
          storage = "vms" # Storage Pool ID for the disk
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

  # --- Cloud-Init Configuration ---
  # 'ipconfig0' and 'sshkeys' are now top-level under the resource
  ipconfig0 = "ip=${var.vm_ip_prefix}.${var.vm_ip_start_octet + count.index}${var.vm_subnet_mask},gw=${var.vm_gateway}"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  # --- Lifecycle ---
  lifecycle {
    ignore_changes = [
      # Note: ignore_changes on network might prevent TF from updating IPs if needed.
      # Consider removing if you want TF to manage network fully.
      network,
    ]
  }
}
