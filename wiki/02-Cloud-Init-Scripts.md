# Getting Started: Cloud-Init Scripts

This guide will walk you through using Mox Cloud's cloud-init scripts to create automated VM templates in Proxmox.

## Table of Contents

- [Overview](#overview)
- [What is Cloud-Init?](#what-is-cloud-init)
- [Directory Structure](#directory-structure)
- [Setup Process](#setup-process)
- [Configuration Options](#configuration-options)
- [Running the Scripts](#running-the-scripts)
- [Automated Template Updates](#automated-template-updates)
- [Troubleshooting](#troubleshooting)

## Overview

The cloud-init scripts in Mox Cloud automate the creation of VM templates in Proxmox. These templates serve as the foundation for deploying VMs with Terraform/OpenTofu, pre-configured with:

- Ubuntu Server (latest cloud image)
- Desired packages and utilities
- SSH keys for secure access
- Network configuration
- Default admin user

## What is Cloud-Init?

[Cloud-init](https://cloud-init.io/) is the industry-standard multi-distribution method for cross-platform cloud instance initialization. It:

- Configures network settings
- Sets up user accounts and SSH keys
- Installs packages
- Runs custom scripts on first boot
- Manages hostname and DNS settings

**Benefits:**
- Consistent VM initialization
- Automated configuration
- No manual post-deployment setup
- Works with most cloud platforms and hypervisors

**Learn More:**
- [Official Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/reference/examples.html)

## Directory Structure

```
cloudinit/
├── template-setup.sh       # Interactive configuration script
├── template-script.sh      # VM template creation script
├── .env                    # Generated configuration file
├── template-config.txt     # Generated VM settings
└── keys/                   # Directory for SSH public keys
```

## Setup Process

### Step 1: Navigate to the Cloud-Init Directory

```bash
cd cloudinit/
```

### Step 2: Run the Setup Script

The setup script creates your configuration and is interactive:

```bash
./template-setup.sh
```

**First Run:**
- Creates a sample `.env` file with default values
- Exits and asks you to review the file

**Second Run:**
- Prompts you for configuration values
- Creates `template-config.txt` with VM settings
- Sets up cron jobs for automated updates (optional)

### Step 3: Review the Generated .env File

After the first run, examine `.env`:

```bash
cat .env
```

Example `.env` file:
```bash
# Cloud-Init User
CI_USER="admin"

# Cloud-Init User Password
CI_USER_PASSWORD="admin"

# Cloud-Init DNS Settings
CI_DNS_SERVERS="1.1.1.1,8.8.8.8"
CI_DNS_DOMAIN="homelab.local"

# Cloud-Init SSH Keys
# Space-separated list of public key FILE PATHS
CI_SSH_KEY_FILES="~/.ssh/your_key.pub"

# Cloud-Init Packages
CI_PACKAGES="neofetch htop qemu-utils"
```

**Edit this file** before running setup again to customize your defaults.

### Step 4: Prepare SSH Keys

Place your SSH public keys in a known location (or use the `keys/` directory):

```bash
# Copy your public key to the keys directory
cp ~/.ssh/id_rsa.pub ./keys/my_key.pub

# Or generate a new key pair
ssh-keygen -t rsa -b 4096 -C "proxmox-admin" -f ./keys/proxmox_key
```

Update `.env` to point to your key(s):
```bash
CI_SSH_KEY_FILES="./keys/my_key.pub ./keys/another_key.pub"
```

### Step 5: Run Setup Again (Interactive Configuration)

```bash
./template-setup.sh
```

You'll be prompted for:

#### User Configuration
- **Username** (default: `admin`)
  - The default admin user created in VMs
- **Password** (default: `admin`)
  - Password for the admin user
  - **Important:** Change this for production!

#### Package Configuration
- **Packages to install** (default: `neofetch htop qemu-utils`)
  - Space-separated list of Ubuntu packages
  - `qemu-guest-agent` is installed automatically
  - Common additions: `curl wget git vim tmux python3-pip`

#### VM Template Settings
- **VM ID** (default: `9000`)
  - Proxmox VM ID for the template
  - Must be unique and not in use
  - Convention: 9000+ for templates

- **Release** (default: `noble`)
  - Ubuntu release codename
  - Options: `jammy` (22.04 LTS), `noble` (24.04 LTS), `mantic` (23.10)
  - See [Ubuntu Releases](https://wiki.ubuntu.com/Releases) for full list

- **VM Name** (default: `cloudinit-template-MM-DD-YY`)
  - Name for the template in Proxmox
  - Supports `DATE` placeholder: `my-template-DATE` → `my-template-01-12-26`

- **VM Storage** (default: `local-lvm`)
  - Proxmox storage pool for the template disk
  - Must match a storage pool in your Proxmox setup
  - Common options: `local-lvm`, `local-zfs`, `ceph`, custom pools

#### Cron Job Configuration (Optional)

Automatically update the template on a schedule:

- **Hours** (default: `9,21`)
  - 24-hour format, comma-separated
  - Example: `9,21` runs at 9 AM and 9 PM

- **Day of Month** (default: `*`)
  - Specific day(s) or `*` for every day
  - Example: `1,15` runs on 1st and 15th

- **Month** (default: `*`)
  - Specific month(s) or `*` for every month
  - Example: `1,6,12` runs in Jan, Jun, Dec

- **Days of Week** (default: `Mon,Fri`)
  - Day names or `*` for every day
  - Example: `Mon,Wed,Fri` or `*`

**Example Cron Schedules:**

```bash
# Run every Monday at 3 AM
Hours: 3
Day of Month: *
Month: *
Days of Week: Mon

# Run 1st and 15th of every month at 2 AM and 2 PM
Hours: 2,14
Day of Month: 1,15
Month: *
Days of Week: *

# Run Monday, Wednesday, Friday at 9 AM
Hours: 9
Day of Month: *
Month: *
Days of Week: Mon,Wed,Fri
```

### Step 6: Verify Configuration

After setup completes, verify your configuration files:

```bash
# Check .env settings
cat .env

# Check VM template config
cat template-config.txt

# Check cron jobs
crontab -l
```

Example `template-config.txt`:
```
VM_ID=9000
RELEASE=noble
VM_NAME=cloudinit-template-01-12-26
VM_STOR=local-lvm
CRON_JOBS="0 9 * * Mon,Fri /path/to/template-script.sh"
```

## Running the Scripts

### Create the VM Template

Once configured, create your first template:

```bash
./template-script.sh
```

**What the script does:**

1. **Dependency Check**
   - Installs `wget` if missing
   - Installs `libguestfs-tools` (`virt-customize`) if missing

2. **Download Cloud Image**
   - Downloads Ubuntu cloud image from [cloud-images.ubuntu.com](https://cloud-images.ubuntu.com/)
   - Compares manifest files to check for updates
   - Only downloads if image changed or is missing

3. **Customize Image**
   - Installs `qemu-guest-agent` and packages from `CI_PACKAGES`
   - Runs `virt-customize` to modify the image
   - Configures DNS settings

4. **Create Proxmox VM**
   - Destroys existing template (if VM ID exists)
   - Creates new VM with specified ID and name
   - Imports the cloud image as a disk
   - Configures cloud-init drive
   - Sets CPU, memory, and network settings
   - Converts VM to template

5. **Cleanup**
   - Removes temporary files
   - Keeps manifest for future comparisons

**Expected Output:**
```
All required packages are already installed.
Sourcing variables from ./.env...
template-config.txt sourced successfully.
Provisioning VM Template...
Local manifest file exists. No download needed.
Manifest files differ or template is missing. Now updating cloud-init image...
Updated image downloaded.
Attempting to destroy existing template (VM ID: 9000)...
VM 9000 destroyed successfully.
Creating cloud-init VM template...
VM 9000 created.
Importing disk...
Cloud-Init drive configured.
Template creation complete!
Template VM ID 9000 is ready for use.
```

### Verify the Template

1. **Check Proxmox Web UI:**
   - Navigate to your Proxmox node
   - Look for VM 9000 (or your chosen ID)
   - Should show a template icon

2. **Test Clone:**
   ```bash
   # Clone the template to test it
   qm clone 9000 999 --name test-clone
   qm start 999

   # Check the VM console in Proxmox UI
   # Should boot successfully with cloud-init

   # Clean up test
   qm stop 999
   qm destroy 999
   ```

## Configuration Options

### Environment Variables (.env)

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `CI_USER` | Default admin username | `admin` | `ubuntu`, `myuser` |
| `CI_USER_PASSWORD` | Default admin password | `admin` | `MySecureP@ss!` |
| `CI_DNS_SERVERS` | DNS servers (comma-separated) | `1.1.1.1,8.8.8.8` | `8.8.8.8,8.8.4.4` |
| `CI_DNS_DOMAIN` | DNS search domain | `homelab.local` | `example.com` |
| `CI_SSH_KEY_FILES` | SSH public key paths (space-separated) | `~/.ssh/your_key.pub` | `./keys/key1.pub ./keys/key2.pub` |
| `CI_PACKAGES` | Additional packages to install | `neofetch htop qemu-utils` | `vim curl git docker.io` |

### Template Configuration (template-config.txt)

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `VM_ID` | Proxmox VM ID | `9000` | Must be unique |
| `RELEASE` | Ubuntu release codename | `noble` | `jammy`, `noble`, etc. |
| `VM_NAME` | Template name in Proxmox | `cloudinit-template-DATE` | Supports DATE placeholder |
| `VM_STOR` | Storage pool name | `local-lvm` | Must exist in Proxmox |
| `CRON_JOBS` | Cron schedule for updates | varies | Standard cron format |

### Customizing Package Installation

Edit `.env` to add packages you want pre-installed:

```bash
# Development tools
CI_PACKAGES="git vim curl wget build-essential python3-pip"

# Docker environment
CI_PACKAGES="docker.io docker-compose"

# Monitoring tools
CI_PACKAGES="htop iotop nethogs ncdu"

# Minimal
CI_PACKAGES="qemu-utils"
```

**Note:** `qemu-guest-agent` is always installed (required for Proxmox integration).

### Using Multiple SSH Keys

You can add multiple keys for different users or purposes:

```bash
CI_SSH_KEY_FILES="./keys/admin.pub ./keys/deploy.pub ./keys/backup.pub"
```

All specified keys will be added to the default user's `authorized_keys`.

## Automated Template Updates

### How Automatic Updates Work

The cron job runs `template-script.sh` on your chosen schedule:

1. Downloads the latest manifest from Ubuntu
2. Compares with local manifest
3. If different (new image available):
   - Downloads new image
   - Destroys old template
   - Creates new template
   - Updates manifest
4. If same: exits without changes

**Benefits:**
- Always have the latest security patches
- Automated template maintenance
- No manual intervention needed

### Managing Cron Jobs

**View current cron jobs:**
```bash
crontab -l
```

**Edit cron jobs manually:**
```bash
crontab -e
```

**Disable automatic updates:**
```bash
crontab -r  # Removes all cron jobs
```

**Re-enable automatic updates:**
```bash
./template-setup.sh  # Re-run and configure schedule
```

### Manual Updates

Run the script manually anytime to update the template:

```bash
cd cloudinit/
./template-script.sh
```

## Troubleshooting

### Script Fails with "Permission Denied"

**Cause:** Scripts not executable

**Solution:**
```bash
chmod +x template-setup.sh template-script.sh
```

### "libguestfs-tools not found"

**Cause:** Missing dependency

**Solution:**
The script auto-installs, but if it fails:
```bash
sudo apt update
sudo apt install -y libguestfs-tools wget
```

### "Storage 'X' does not exist"

**Cause:** Storage pool name doesn't match Proxmox

**Solution:**
1. Check available storage in Proxmox UI: Datacenter → Storage
2. Re-run `./template-setup.sh` with correct storage name
3. Or edit `template-config.txt` directly:
   ```bash
   VM_STOR=local-zfs  # Change to your storage name
   ```

### "VM ID already exists"

**Cause:** VM with that ID is already running (not a template)

**Solution:**
```bash
# Check if VM exists
qm status 9000

# If it's a running VM you want to keep, choose a different ID
./template-setup.sh  # Use different VM_ID

# If you want to replace it
qm stop 9000
qm destroy 9000
./template-script.sh
```

### Cloud-Init Image Download Fails

**Cause:** Network issues or invalid release name

**Solution:**
1. Check internet connectivity
2. Verify release name is valid:
   - Visit https://cloud-images.ubuntu.com/
   - Look for your release (noble, jammy, etc.)
3. Try a different release in `template-config.txt`

### SSH Keys Not Working

**Cause:** Key file path is incorrect or key format is wrong

**Solution:**
1. Verify key files exist:
   ```bash
   ls -la ~/.ssh/id_rsa.pub
   ```
2. Check key format (should start with `ssh-rsa`, `ssh-ed25519`, etc.):
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```
3. Use absolute paths in `.env`:
   ```bash
   CI_SSH_KEY_FILES="/home/username/.ssh/id_rsa.pub"
   ```

### Template Created but VMs Won't Clone

**Cause:** Template might not be properly marked as template

**Solution:**
```bash
# Verify template status
qm config 9000 | grep template

# Should show: template: 1

# If not, convert manually
qm template 9000
```

### Packages Fail to Install

**Cause:** Package names incorrect or not available in repository

**Solution:**
1. Check package names on [packages.ubuntu.com](https://packages.ubuntu.com/)
2. Use exact package names (case-sensitive)
3. For multi-word packages, use exact name:
   ```bash
   # Correct
   CI_PACKAGES="build-essential docker.io python3-pip"

   # Incorrect
   CI_PACKAGES="build essential docker python3 pip"
   ```

### Cron Jobs Not Running

**Cause:** Cron service not running or syntax error

**Solution:**
```bash
# Check cron service
sudo systemctl status cron

# Start if stopped
sudo systemctl start cron

# View cron logs
grep CRON /var/log/syslog

# Test cron job manually
/path/to/template-script.sh
```

## Best Practices

### Security

1. **Change default passwords:**
   ```bash
   CI_USER_PASSWORD="YourStrongPasswordHere"
   ```

2. **Use SSH keys only:**
   - Disable password authentication after first boot
   - Use strong SSH key types (ed25519 preferred)

3. **Regular updates:**
   - Set up cron jobs to keep templates current
   - Review changes when Ubuntu releases new images

### Template Naming

Use descriptive, dated names:
```bash
VM_NAME="k8s-noble-DATE"
VM_NAME="production-template-DATE"
VM_NAME="dev-env-DATE"
```

The `DATE` placeholder makes it easy to track template age.

### Storage Selection

- **local-lvm:** Fast, local storage (good for testing)
- **local-zfs:** ZFS with snapshots and compression
- **ceph/rbd:** Distributed storage (for clusters)
- **NFS:** Network storage (shared across nodes)

Choose based on your Proxmox setup and use case.

### Package Management

Keep package lists organized by purpose:

```bash
# Minimal template
CI_PACKAGES="qemu-utils"

# Development template
CI_PACKAGES="git vim curl wget build-essential python3-pip nodejs npm"

# Container template
CI_PACKAGES="docker.io docker-compose kubectl"

# Monitoring template
CI_PACKAGES="prometheus-node-exporter telegraf"
```

Create multiple templates for different purposes by using different VM IDs and names.

## Next Steps

After creating your cloud-init template:

1. **[Getting Started with Terraform Generator](03-Terraform-Generator.md)** - Deploy VMs using the template
2. Test cloning and deploying VMs manually in Proxmox
3. Configure cloud-init settings in Terraform (SSH keys, networking, etc.)

## Additional Resources

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Proxmox Cloud-Init Guide](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Proxmox qm Command Reference](https://pve.proxmox.com/pve-docs/qm.1.html)
- [virt-customize Man Page](https://libguestfs.org/virt-customize.1.html)
