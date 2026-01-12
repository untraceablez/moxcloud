# Getting Started: Terraform/OpenTofu Generator Script

This guide will help you use the Kubernetes cluster generator script to create and deploy VM clusters using Terraform or OpenTofu.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Understanding the Generator](#understanding-the-generator)
- [Basic Usage](#basic-usage)
- [Configuration](#configuration)
- [Deploying Your Cluster](#deploying-your-cluster)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Overview

The `generate-k8s-cluster.sh` script automates the creation of Terraform configuration files for deploying Kubernetes clusters on Proxmox. It generates:

- **Control plane nodes** - Master nodes that manage the cluster
- **Worker nodes** - Nodes that run your workloads
- **Variables files** - Configuration for both node types

**Benefits:**
- Quick cluster generation with custom node counts
- Consistent configuration across environments
- Self-contained control and worker directories
- Easy to version control and modify

## Prerequisites

Before using the generator script, ensure you have:

1. ✅ **Proxmox VE installed and configured**
   - See [Prerequisites and Setup Guide](01-Prerequisites-and-Setup.md)

2. ✅ **Cloud-init template created**
   - See [Cloud-Init Scripts Guide](02-Cloud-Init-Scripts.md)
   - Template should be available in Proxmox

3. ✅ **Terraform or OpenTofu installed**
   - `terraform --version` or `tofu --version` should work

4. ✅ **Proxmox API credentials**
   - API user created
   - API token generated
   - Proper permissions assigned

5. ✅ **Network configuration**
   - DHCP server running (or static IP plan)
   - VLANs configured if needed
   - Bridge interfaces set up (vmbr0, etc.)

## Understanding the Generator

### What Does It Generate?

The script creates a complete Terraform infrastructure setup:

```
terraform/k8s/
├── control/
│   ├── main.tf       # Control node infrastructure
│   └── vars.tf       # Control node variables
├── worker/
│   ├── main.tf       # Worker node infrastructure
│   └── vars.tf       # Worker node variables
└── generate-k8s-cluster.sh
```

### Key Features

**Separate Directories:**
- Control and worker nodes are independent
- Each has its own Terraform state
- Can be deployed/destroyed separately

**Generated Variables:**
- Identical vars.tf in both directories
- Contains Proxmox connection details
- Includes SSH keys, storage, and network settings

**Flexible Node Counts:**
- Specify any number of control/worker nodes
- Defaults to 3 control + 3 worker nodes
- Can be re-run to change counts

**Load Balancing:**
- Automatically distributes VMs across Proxmox hosts
- Uses round-robin distribution
- Optimizes resource utilization

## Basic Usage

### Step 1: Navigate to the K8s Directory

```bash
cd terraform/k8s
```

### Step 2: Review the Generator Script

Before running, check what will be configured:

```bash
# Make script executable if needed
chmod +x generate-k8s-cluster.sh

# View script help
./generate-k8s-cluster.sh --help
```

**Note:** The script doesn't have a traditional help flag, but you can view it with:
```bash
head -n 10 generate-k8s-cluster.sh
```

### Step 3: Customize Variables (Before First Run)

Edit the `generate_vars_tf()` function in the script to match your environment:

```bash
vim generate-k8s-cluster.sh
# or
nano generate-k8s-cluster.sh
```

**Important variables to customize:**

```bash
# SSH Key - Your public key
variable "ssh_key" {
  default = "ssh-rsa AAAA...your-key-here..."
}

# Proxmox Hosts - Your node names
variable "proxmox_host_01" {
  default = "pve-01"  # Change to your host names
}
variable "proxmox_host_02" {
  default = "pve-02"
}
# ... etc

# Template Name - From cloud-init setup
variable "template_name" {
  default = "cloudinit-template-01-12-26"  # Your template name
}

# API Credentials
variable "proxmox_api_url" {
  default = "https://192.168.1.100:8006/api2/json"  # Your Proxmox IP
}

variable "proxmox_api_token_id" {
  default = "terraform-prov@pve!token-01"
}

variable "proxmox_api_token_secret" {
  default = "your-secret-here"  # Your API token
}
```

### Step 4: Run the Generator

**Default configuration (3 control + 3 worker):**
```bash
./generate-k8s-cluster.sh
```

**Custom node counts:**
```bash
./generate-k8s-cluster.sh <control_count> <worker_count>

# Examples:
./generate-k8s-cluster.sh 3 3    # 3 control, 3 worker
./generate-k8s-cluster.sh 5 10   # 5 control, 10 worker
./generate-k8s-cluster.sh 1 3    # 1 control, 3 worker (dev cluster)
./generate-k8s-cluster.sh 3 0    # 3 control, 0 workers (control-only)
```

**Expected output:**
```
=== Kubernetes Cluster Generator ===
Control nodes: 3
Worker nodes:  3

✓ Generated /path/to/control/vars.tf
✓ Generated /path/to/worker/vars.tf
✓ Generated /path/to/control/main.tf with 3 control nodes
✓ Generated /path/to/worker/main.tf with 3 worker nodes

=== Summary ===
Generated Terraform configurations for:
  - 3 control plane nodes (k8s-dev-ctrl-01 to k8s-dev-ctrl-03)
  - 3 worker nodes (k8s-dev-wrkr-01 to k8s-dev-wrkr-03)

Files created:
  - /path/to/control/main.tf
  - /path/to/control/vars.tf
  - /path/to/worker/main.tf
  - /path/to/worker/vars.tf

Next steps:
  1. Review the generated files
  2. Initialize Terraform: cd control && terraform init
  3. Plan deployment: terraform plan
  4. Apply configuration: terraform apply

Note: Each directory (control/worker) should be applied separately.
```

### Step 5: Review Generated Files

Check the generated configurations:

```bash
# Review control node config
cat control/main.tf
cat control/vars.tf

# Review worker node config
cat worker/main.tf
cat worker/vars.tf

# Check count values
grep "count = " control/main.tf worker/main.tf
```

## Configuration

### Understanding vars.tf

The generated `vars.tf` contains all configuration variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `ssh_key` | Public SSH key for VM access | `ssh-rsa AAAA...` |
| `proxmox_host_01` - `04` | Proxmox node hostnames | `pve-01`, `cave` |
| `template_name` | Cloud-init template to clone | `cloudinit-template-01-12-26` |
| `proxmox_api_url` | Proxmox API endpoint | `https://192.168.1.100:8006/api2/json` |
| `proxmox_api_token_id` | API token identifier | `terraform-prov@pve!token-01` |
| `proxmox_api_token_secret` | API token secret | `4eb5e927-...` |
| `vm_ip_prefix` | IP address prefix | `10.0.0.0` |
| `vm_ip_start_octet` | Starting IP octet | `61` |
| `vm_gateway` | Default gateway | `10.0.0.1` |
| `vm_subnet_mask` | Subnet mask | `/24` |

### Understanding main.tf

The generated `main.tf` defines the VM infrastructure:

**Provider Configuration:**
```hcl
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}
```

**VM Resource:**
```hcl
resource "proxmox_vm_qemu" "k8sDev" {
  count = 3  # Number of nodes

  name = "k8s-dev-ctrl-0${count.index + 1}"  # k8s-dev-ctrl-01, -02, -03

  target_node = local.target_hosts[count.index % length(local.target_hosts)]

  clone = var.template_name

  # VM specs
  cpu {
    cores = 2
    sockets = 1
  }
  memory = 2048  # 2GB

  # ... more configuration
}
```

### VM Specifications

**Default Settings:**

| Setting | Control Nodes | Worker Nodes |
|---------|---------------|--------------|
| **Naming** | `k8s-dev-ctrl-01, -02, -03` | `k8s-dev-wrkr-01, -02, -03` |
| **CPU** | 2 cores, 1 socket | 2 cores, 1 socket |
| **Memory** | 2GB | 2GB |
| **Disk** | 32GB | 32GB |
| **Storage** | `talos-hosts` | `talos-hosts` |
| **Networks** | 2 (vmbr0, vmbr0+VLAN5) | 2 (vmbr0, vmbr0+VLAN5) |
| **Tags** | `k8s,control-plane` | `k8s,worker` |
| **IP Config** | DHCP on both NICs | DHCP on both NICs |

**To modify these settings**, edit the generator script before running it.

## Deploying Your Cluster

### Step 1: Initialize Terraform (Control Plane)

```bash
cd control
terraform init
```

**Or with OpenTofu:**
```bash
tofu init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding telmate/proxmox versions matching "3.0.2-rc05"...
- Installing telmate/proxmox v3.0.2-rc05...
- Installed telmate/proxmox v3.0.2-rc05

Terraform has been successfully initialized!
```

### Step 2: Plan Control Plane Deployment

```bash
terraform plan
```

**Review the output:**
- Shows all resources to be created
- Lists VM names and configurations
- Displays network and storage settings

**Look for:**
- ✅ Correct VM names
- ✅ Proper host distribution
- ✅ Expected resource counts
- ✅ Correct template reference

### Step 3: Deploy Control Plane

```bash
terraform apply
```

**Review the plan again, then type `yes` to confirm.**

**Expected output:**
```
Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

proxmox_vm_qemu.k8sDev[0]: Creating...
proxmox_vm_qemu.k8sDev[1]: Creating...
proxmox_vm_qemu.k8sDev[2]: Creating...

proxmox_vm_qemu.k8sDev[0]: Creation complete after 45s
proxmox_vm_qemu.k8sDev[1]: Creation complete after 47s
proxmox_vm_qemu.k8sDev[2]: Creation complete after 50s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**Deployment time:** ~1-2 minutes per VM

### Step 4: Verify Control Plane

**In Proxmox UI:**
1. Check VMs are created and running
2. Verify VM names: `k8s-dev-ctrl-01`, `-02`, `-03`
3. Check distribution across nodes
4. Review console output for errors

**From command line:**
```bash
# Check VM status
ssh admin@<vm-ip> "hostname && uptime"

# View cloud-init status
ssh admin@<vm-ip> "cloud-init status"
```

### Step 5: Deploy Workers

```bash
cd ../worker
terraform init
terraform plan
terraform apply
```

**Follow the same process as control plane deployment.**

### Step 6: Verify Full Cluster

**Check all VMs:**
```bash
# From Proxmox host
qm list | grep k8s

# Should show:
# VMID NAME              STATUS
# 101  k8s-dev-ctrl-01  running
# 102  k8s-dev-ctrl-02  running
# 103  k8s-dev-ctrl-03  running
# 104  k8s-dev-wrkr-01  running
# 105  k8s-dev-wrkr-02  running
# 106  k8s-dev-wrkr-03  running
```

**Get IP addresses:**
```bash
# From Proxmox host
for i in {101..106}; do
  echo -n "VM $i: "
  qm guest cmd $i network-get-interfaces | grep -A3 eth0 | grep ip-address
done
```

## Advanced Usage

### Scaling the Cluster

**Add more nodes:**
```bash
# Increase to 5 control nodes and 10 workers
./generate-k8s-cluster.sh 5 10

cd control
terraform plan   # Shows 2 new control nodes to add
terraform apply

cd ../worker
terraform plan   # Shows 7 new worker nodes to add
terraform apply
```

**Reduce nodes:**
```bash
# Decrease to 1 control node and 2 workers
./generate-k8s-cluster.sh 1 2

cd control
terraform plan   # Shows 2 control nodes to destroy
terraform apply  # Confirms destruction

cd ../worker
terraform plan   # Shows 1 worker to destroy
terraform apply
```

### Customizing VM Resources

Edit the generator script to modify default VM specs:

**Increase CPU and memory:**
```bash
# In generate-k8s-cluster.sh, find the cpu and memory lines:

cpu {
  cores = 4      # Change from 2 to 4
  sockets = 1
}
memory = 4096    # Change from 2048 to 4096 (4GB)
```

**Increase disk size:**
```bash
# Find the disk configuration:

disk {
  storage = "talos-hosts"
  size    = 64    # Change from 32 to 64GB
}
```

**After editing, regenerate:**
```bash
./generate-k8s-cluster.sh 3 3
cd control
terraform apply  # Updates existing VMs
```

### Using Different Storage Pools

**Edit the generator script:**
```bash
# Control plane on fast SSD storage
storage = "nvme-pool"

# Workers on bulk storage
storage = "hdd-pool"
```

### Static IP Configuration

By default, VMs use DHCP. For static IPs, modify the generator:

```bash
# Replace:
ipconfig0 = "ip=dhcp"

# With:
ipconfig0 = "ip=${var.vm_ip_prefix}.${var.vm_ip_start_octet + count.index}${var.vm_subnet_mask},gw=${var.vm_gateway}"
```

**Example result:**
- Control-01: `10.0.0.61/24`
- Control-02: `10.0.0.62/24`
- Control-03: `10.0.0.63/24`

### Multiple Clusters

Create separate configurations for different environments:

```bash
# Development cluster
./generate-k8s-cluster.sh 1 2

# Stage cluster
mkdir -p ../k8s-stage/control ../k8s-stage/worker
./generate-k8s-cluster.sh 3 3
# Edit VM names to k8s-stage-ctrl-*, k8s-stage-wrkr-*

# Production cluster
mkdir -p ../k8s-prod/control ../k8s-prod/worker
./generate-k8s-cluster.sh 5 10
# Edit VM names to k8s-prod-ctrl-*, k8s-prod-wrkr-*
```

### Version Control Best Practices

**What to commit:**
```bash
git add generate-k8s-cluster.sh
git add control/main.tf
git add worker/main.tf
# Don't commit vars.tf with secrets
```

**What to ignore (.gitignore):**
```
# Terraform state
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl

# Sensitive variables
**/vars.tf
*.tfvars

# SSH keys
*.pem
*.pub
keys/
```

**Using environment variables:**
```bash
export TF_VAR_proxmox_api_token_secret="your-secret"
export TF_VAR_ssh_key="$(cat ~/.ssh/id_rsa.pub)"

# Remove defaults from vars.tf, Terraform will use env vars
```

## Troubleshooting

### Generator Script Issues

#### "Permission denied" when running script

**Solution:**
```bash
chmod +x generate-k8s-cluster.sh
```

#### Script generates but values are wrong

**Check:**
1. Edit the script and verify the `generate_vars_tf()` function
2. Look for your customizations
3. Re-run after fixing

#### Count value not updating

**Cause:** You may be looking at old files

**Solution:**
```bash
# Force regeneration
rm -f control/main.tf worker/main.tf
./generate-k8s-cluster.sh 3 3
```

### Terraform Initialization Issues

#### "Failed to query available provider packages"

**Cause:** Network issues or provider registry down

**Solution:**
```bash
# Use mirror
terraform init -plugin-dir=/path/to/plugins

# Or download provider manually
wget https://github.com/Telmate/terraform-provider-proxmox/releases/download/v3.0.2-rc05/terraform-provider-proxmox_3.0.2-rc05_linux_amd64.zip
unzip terraform-provider-proxmox_3.0.2-rc05_linux_amd64.zip
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/telmate/proxmox/3.0.2-rc05/linux_amd64/
mv terraform-provider-proxmox ~/.terraform.d/plugins/registry.terraform.io/telmate/proxmox/3.0.2-rc05/linux_amd64/
```

#### "Provider version not compatible"

**Cause:** Terraform/OpenTofu version too old

**Solution:**
```bash
# Check version
terraform --version

# Update Terraform
# (Follow installation instructions from Prerequisites guide)

# Or modify version constraint in main.tf
version = ">= 2.0.0"  # Less restrictive
```

### Deployment Issues

#### "Error: Template 'X' not found"

**Cause:** Template name doesn't match Proxmox

**Solution:**
```bash
# List templates in Proxmox
qm list | grep template

# Update template_name in generator script
variable "template_name" {
  default = "actual-template-name"
}

# Regenerate and retry
./generate-k8s-cluster.sh 3 3
cd control
terraform apply
```

#### "Error: storage 'X' does not exist"

**Cause:** Storage pool name mismatch

**Solution:**
```bash
# Check available storage
pvesm status

# Update storage name in generator
storage = "correct-storage-name"

# Regenerate
./generate-k8s-cluster.sh 3 3
```

#### "401 unauthorized" errors

**Cause:** API credentials invalid or expired

**Solution:**
```bash
# Verify token in Proxmox UI:
# Datacenter → Permissions → API Tokens

# Test token manually
curl -k -H "Authorization: PVEAPIToken=terraform-prov@pve!token-01=your-secret" \
  https://192.168.1.100:8006/api2/json/version

# Update vars.tf with correct token
# Regenerate if needed
```

#### VMs created but won't start

**Cause:** Resource constraints or configuration errors

**Solution:**
```bash
# Check Proxmox host resources
pvesh get /nodes/pve-01/status

# Check VM logs in Proxmox UI
# Try starting manually
qm start 101

# Review cloud-init configuration
qm cloudinit dump 101 user
```

#### VMs start but can't SSH

**Cause:** SSH key not properly configured

**Solution:**
```bash
# Check cloud-init in Proxmox UI
# Verify SSH key in vars.tf matches your private key

# View key fingerprint
ssh-keygen -lf ~/.ssh/id_rsa.pub

# Access via Proxmox console to debug
# Check /var/log/cloud-init.log
```

### State Management Issues

#### "Resource already exists"

**Cause:** State file out of sync with reality

**Solution:**
```bash
# Import existing resource
terraform import proxmox_vm_qemu.k8sDev[0] pve-01/qemu/101

# Or refresh state
terraform refresh

# Or destroy and recreate
terraform destroy
terraform apply
```

#### "State lock" errors

**Cause:** Previous terraform run interrupted

**Solution:**
```bash
# Manually unlock (if safe)
terraform force-unlock <lock-id>

# Or remove lock file
rm -f .terraform.tfstate.lock.info
```

### Network Issues

#### VMs created but no IP address

**Cause:** DHCP not working or network misconfiguration

**Solution:**
```bash
# Check DHCP server is running
# Verify network bridge in Proxmox

# Use static IPs instead (see Advanced Usage)
# Or check VM console for network errors
```

#### Can't reach VMs on network

**Cause:** Firewall or VLAN configuration

**Solution:**
```bash
# Test from Proxmox host
ping <vm-ip>

# Check firewall rules
iptables -L

# Verify VLAN configuration
# Check bridge settings in Proxmox UI
```

## Best Practices

### Before Each Deployment

1. **Review the plan:**
   ```bash
   terraform plan > plan.txt
   cat plan.txt  # Review carefully
   ```

2. **Test in development first:**
   - Deploy 1 control + 1 worker to test
   - Verify functionality
   - Then scale up

3. **Backup existing clusters:**
   ```bash
   # Export VM configs
   for i in {101..106}; do
     qm config $i > vm-$i-backup.conf
   done
   ```

### During Deployment

1. **Monitor progress:**
   - Watch Proxmox UI during deployment
   - Check VM consoles for errors
   - Review cloud-init logs

2. **Don't interrupt:**
   - Let terraform complete
   - Don't Ctrl+C unless necessary
   - If interrupted, check state carefully

### After Deployment

1. **Verify all VMs:**
   ```bash
   # Test SSH access
   for ip in <vm-ips>; do
     ssh admin@$ip "hostname"
   done
   ```

2. **Document the deployment:**
   - Note VM IDs and IPs
   - Save Terraform output
   - Update documentation

3. **Backup Terraform state:**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d)
   ```

### Security

1. **Protect secrets:**
   - Never commit API tokens
   - Use environment variables or secret managers
   - Restrict access to vars.tf files

2. **Review generated configs:**
   - Check SSH keys before applying
   - Verify network settings
   - Confirm resource limits

3. **Regular updates:**
   - Keep cloud-init templates current
   - Update Terraform/OpenTofu versions
   - Patch VMs regularly

## Next Steps

After deploying your cluster:

1. **Install Kubernetes:**
   - Use kubeadm, k3s, RKE2, or Talos
   - Configure kubectl access
   - Set up CNI networking

2. **Configure cluster networking:**
   - Install network plugin (Calico, Cilium, Flannel)
   - Set up LoadBalancer (MetalLB)
   - Configure ingress controller

3. **Set up monitoring:**
   - Deploy Prometheus/Grafana
   - Configure metrics collection
   - Set up alerting

4. **Implement backup strategy:**
   - Velero for Kubernetes backups
   - Proxmox snapshots for VMs
   - etcd backups for control plane

## Additional Resources

- [Terraform Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)

## Example Workflows

### Development Cluster Setup

```bash
# 1. Generate minimal cluster
cd terraform/k8s
./generate-k8s-cluster.sh 1 2

# 2. Deploy
cd control && terraform init && terraform apply
cd ../worker && terraform init && terraform apply

# 3. Install k3s
ssh admin@<control-ip> "curl -sfL https://get.k3s.io | sh -"
```

### Production Cluster Setup

```bash
# 1. Generate HA cluster
cd terraform/k8s
./generate-k8s-cluster.sh 5 10

# 2. Review configuration
cat control/main.tf
cat worker/main.tf

# 3. Test plan
cd control && terraform init && terraform plan

# 4. Deploy in stages
terraform apply -target=proxmox_vm_qemu.k8sDev[0]  # First control node
terraform apply -target=proxmox_vm_qemu.k8sDev[1]  # Second control node
# ... verify each before continuing
terraform apply  # Deploy remaining
```

### Disaster Recovery

```bash
# 1. Export current state
cd control
terraform show > current-state.txt

# 2. Backup VMs in Proxmox
# (Use Proxmox backup tools)

# 3. If disaster occurs, restore from backup
# 4. Import into Terraform
terraform import proxmox_vm_qemu.k8sDev[0] pve-01/qemu/101

# 5. Verify state matches reality
terraform plan  # Should show no changes
```
