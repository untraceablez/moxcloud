# Getting Started: Prerequisites and Setup

This guide will help you set up your environment with all the necessary prerequisites for deploying VM clusters with Mox Cloud.

## Table of Contents

- [Overview](#overview)
- [Proxmox VE Setup](#proxmox-ve-setup)
- [Terraform/OpenTofu Installation](#terraformopentofu-installation)
- [Creating a Proxmox API User](#creating-a-proxmox-api-user)
- [Verification](#verification)

## Overview

Mox Cloud requires the following components to be installed and configured:

1. **Proxmox VE** - The virtualization platform
2. **Terraform** or **OpenTofu** - Infrastructure as Code (IaC) tool
3. **Proxmox API User** - Service account for Terraform/OpenTofu to manage VMs

## Proxmox VE Setup

### What is Proxmox VE?

Proxmox Virtual Environment (VE) is an open-source server virtualization management platform that combines KVM hypervisor and LXC containers.

### Installation Resources

**Official Documentation:**
- [Proxmox VE Installation Guide](https://www.proxmox.com/en/proxmox-ve/get-started)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Quick Installation](https://www.proxmox.com/en/proxmox-ve/quick-installation)

**Recommended Tutorials:**
- [Proxmox VE Installation Tutorial (YouTube - Craft Computing)](https://www.youtube.com/watch?v=GoZaMgEgrHw)
- [Proxmox VE Beginner's Guide (TechnoTim)](https://technotim.live/posts/proxmox-install/)
- [Proxmox VE Post-Install Configuration](https://tteck.github.io/Proxmox/)

### System Requirements

**Minimum Requirements:**
- 64-bit CPU (Intel EMT64 or AMD64)
- 2 GB RAM (4+ GB recommended)
- 32 GB hard disk space
- Network card
- Bootable USB drive for installation

**Recommended for Production:**
- Multi-core CPU with VT-x/AMD-V support
- 32+ GB RAM
- SSD storage (ZFS or Ceph recommended)
- Redundant network interfaces
- IPMI/BMC for remote management

### Quick Installation Steps

1. Download the Proxmox VE ISO installer from [proxmox.com/downloads](https://www.proxmox.com/en/downloads)
2. Create a bootable USB drive using:
   - [Rufus](https://rufus.ie/) (Windows)
   - [balenaEtcher](https://www.balena.io/etcher/) (Cross-platform)
   - `dd` command (Linux/macOS)
3. Boot from the USB drive and follow the installation wizard
4. Access the web interface at `https://<your-proxmox-ip>:8006`

### Post-Installation Configuration

After installing Proxmox, you should:

1. **Update the system:**
   ```bash
   apt update && apt upgrade -y
   ```

2. **Configure storage pools** (if using Ceph, ZFS, or other storage):
   - Navigate to Datacenter → Storage in the web UI
   - Add your storage pools

3. **Set up networking:**
   - Configure bridges (vmbr0, vmbr1, etc.)
   - Set up VLANs if needed

4. **Enable IOMMU** (for PCI passthrough, if needed):
   ```bash
   # Edit /etc/default/grub
   # Add: intel_iommu=on (or amd_iommu=on for AMD)
   update-grub
   reboot
   ```

## Terraform/OpenTofu Installation

### Choosing Between Terraform and OpenTofu

**Terraform** (by HashiCorp):
- Industry standard, widely adopted
- Commercial backing and support
- Licensed under BSL (Business Source License) as of v1.6+

**OpenTofu** (Linux Foundation):
- Open-source fork of Terraform (pre-BSL)
- Community-driven, MPL 2.0 licensed
- Drop-in replacement for Terraform
- Committed to staying open-source

**For Mox Cloud:** Both work identically. Choose based on your preference for licensing and support model.

### Installing Terraform

**Official Resources:**
- [Terraform Installation Guide](https://developer.hashicorp.com/terraform/install)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

#### Ubuntu/Debian

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt update
sudo apt install terraform
```

#### Fedora/RHEL/CentOS

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install terraform
```

#### macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

#### Verify Installation

```bash
terraform --version
```

### Installing OpenTofu

**Official Resources:**
- [OpenTofu Installation Guide](https://opentofu.org/docs/intro/install/)
- [OpenTofu Documentation](https://opentofu.org/docs/)

#### Ubuntu/Debian

```bash
# Download the installer script
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

# Give it execution permissions
chmod +x install-opentofu.sh

# Install OpenTofu
./install-opentofu.sh --install-method deb

# Clean up
rm install-opentofu.sh
```

#### Fedora/RHEL/CentOS

```bash
# Download the installer script
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

# Give it execution permissions
chmod +x install-opentofu.sh

# Install OpenTofu
./install-opentofu.sh --install-method rpm

# Clean up
rm install-opentofu.sh
```

#### macOS (Homebrew)

```bash
brew install opentofu
```

#### Manual Installation (Any Platform)

```bash
# Download the binary from https://github.com/opentofu/opentofu/releases
# Extract and move to your PATH
sudo mv tofu /usr/local/bin/
```

#### Verify Installation

```bash
tofu --version
```

## Creating a Proxmox API User

To allow Terraform/OpenTofu to manage VMs, you need to create an API user with appropriate permissions.

### Step 1: Create the User

1. Log into the Proxmox web interface
2. Navigate to **Datacenter** → **Permissions** → **Users**
3. Click **Add** to create a new user

**Recommended Settings:**
- **User name:** `terraform-prov@pve`
- **Realm:** `Proxmox VE authentication server`
- **Group:** (optional) Create a `terraform` group
- **Expire:** `never` or set an appropriate expiration

### Step 2: Create an API Token

1. Navigate to **Datacenter** → **Permissions** → **API Tokens**
2. Click **Add**
3. Select your user: `terraform-prov@pve`
4. Enter a **Token ID:** `token-01`
5. **Uncheck** "Privilege Separation" (allows token to inherit user permissions)
6. Click **Add**

**Important:** Copy the token secret immediately! It will only be shown once.

Example output:
```
Token ID: terraform-prov@pve!token-01
Secret: 4eb5e927-10d4-4180-b65c-35e44b38967b
```

### Step 3: Assign Permissions

The user needs specific permissions to manage VMs and storage.

#### Option 1: Administrator Access (Easiest)

1. Navigate to **Datacenter** → **Permissions**
2. Click **Add** → **User Permission**
3. **Path:** `/`
4. **User:** `terraform-prov@pve`
5. **Role:** `Administrator`

#### Option 2: Restricted Permissions (Recommended for Production)

Create a custom role with only necessary permissions:

1. Navigate to **Datacenter** → **Permissions** → **Roles**
2. Click **Create** to create a new role: `TerraformProv`
3. Add the following privileges:

**VM Privileges:**
- `VM.Allocate` - Create/remove VM
- `VM.Clone` - Clone VM
- `VM.Config.CDROM` - Modify CD-ROM
- `VM.Config.CPU` - Modify CPU settings
- `VM.Config.Cloudinit` - Modify cloud-init settings
- `VM.Config.Disk` - Modify disk
- `VM.Config.HWType` - Modify hardware type
- `VM.Config.Memory` - Modify memory
- `VM.Config.Network` - Modify network
- `VM.Config.Options` - Modify VM options
- `VM.Monitor` - View VM status
- `VM.Audit` - View VM config
- `VM.PowerMgmt` - Power management (start, stop, reset)

**Datastore Privileges:**
- `Datastore.AllocateSpace` - Allocate disk space
- `Datastore.Audit` - View datastore info

**User Privileges:**
- `User.Modify` - For cloud-init user creation

4. Assign the role to the user:
   - Navigate to **Datacenter** → **Permissions**
   - Click **Add** → **User Permission**
   - **Path:** `/`
   - **User:** `terraform-prov@pve`
   - **Role:** `TerraformProv`

### Step 4: Configure Mox Cloud Variables

Update your Terraform variables file with the API credentials:

Edit `terraform/k8s/vars.tf` (or generate with the script):

```hcl
variable "proxmox_api_url" {
  default = "https://<your-proxmox-ip>:8006/api2/json"
}

variable "proxmox_api_token_id" {
  default = "terraform-prov@pve!token-01"
}

variable "proxmox_api_token_secret" {
  default = "your-secret-token-here"
}
```

**Security Note:** Never commit API secrets to version control! Consider using:
- Environment variables
- `.tfvars` files (add to `.gitignore`)
- Secret management tools (Vault, SOPS, etc.)

## Verification

### Test Proxmox Access

Try accessing the Proxmox web interface:
```bash
curl -k https://<your-proxmox-ip>:8006/api2/json
```

### Test API Token

```bash
export PROXMOX_API_TOKEN_ID="terraform-prov@pve!token-01"
export PROXMOX_API_SECRET="your-secret-here"

curl -k -H "Authorization: PVEAPIToken=$PROXMOX_API_TOKEN_ID=$PROXMOX_API_SECRET" \
  https://<your-proxmox-ip>:8006/api2/json/version
```

You should see JSON output with the Proxmox version information.

### Test Terraform/OpenTofu

```bash
cd terraform/k8s/control
terraform init  # or 'tofu init' for OpenTofu

# Should download the Proxmox provider successfully
```

## Next Steps

Once you have completed the prerequisites:

1. **[Getting Started with Cloud-Init Scripts](02-Cloud-Init-Scripts.md)** - Set up automated VM templates
2. **[Getting Started with Terraform Generator](03-Terraform-Generator.md)** - Deploy your cluster

## Troubleshooting

### Proxmox Web Interface Not Accessible

- Check firewall rules: `ufw status` or `iptables -L`
- Verify Proxmox is running: `systemctl status pve-cluster`
- Check network configuration: `ip addr show`

### API Token Authentication Fails

- Verify "Privilege Separation" is unchecked
- Check token expiration in Proxmox UI
- Ensure user has correct permissions at `/` path
- Verify you're using the full token ID format: `user@pve!token-id`

### Terraform Provider Download Fails

- Check internet connectivity
- Verify Terraform/OpenTofu version: `terraform version`
- Try manual provider installation from [registry.terraform.io](https://registry.terraform.io/)

### Permission Denied Errors

- Review the user's role assignments
- Check the path permissions (should be `/` for full access)
- Verify the token is not expired
- Ensure the user exists in the correct realm (`@pve`)

## Additional Resources

### Official Documentation
- [Proxmox VE Admin Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)

### Community Resources
- [r/Proxmox Reddit Community](https://www.reddit.com/r/Proxmox/)
- [Proxmox Forum](https://forum.proxmox.com/)
- [Proxmox Wiki](https://pve.proxmox.com/wiki/)
- [Awesome Proxmox](https://github.com/bfranske/awesome-proxmox)

### Video Tutorials
- [Proxmox VE Full Course (Learn Linux TV)](https://www.youtube.com/watch?v=LCjuiIswXGs)
- [Terraform with Proxmox (TechnoTim)](https://www.youtube.com/watch?v=1nf3WOEFq1Y)
