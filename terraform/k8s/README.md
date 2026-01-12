# Kubernetes Cluster Terraform Configuration

This directory contains Terraform configurations for deploying a Kubernetes cluster on Proxmox VE.

## Directory Structure

```
k8s/
├── control/          # Control plane nodes configuration
│   ├── main.tf       # Generated Terraform config for control nodes
│   └── vars.tf       # Generated variables file
├── worker/           # Worker nodes configuration
│   ├── main.tf       # Generated Terraform config for worker nodes
│   └── vars.tf       # Generated variables file
├── generate-k8s-cluster.sh  # Script to generate main.tf and vars.tf files
└── README.md         # This file
```

## Quick Start

### Generate Cluster Configuration

Use the provided script to generate the main.tf files with the desired number of nodes:

```bash
# Generate 3 control nodes and 3 worker nodes (default)
./generate-k8s-cluster.sh

# Generate 5 control nodes and 10 worker nodes
./generate-k8s-cluster.sh 5 10

# Generate only control nodes (0 workers)
./generate-k8s-cluster.sh 3 0
```

### Deploy Control Plane

```bash
cd control
terraform init
terraform plan
terraform apply
```

### Deploy Workers

```bash
cd worker
terraform init
terraform plan
terraform apply
```

## Configuration Details

### Variables (vars.tf)

Each directory (control and worker) gets its own `vars.tf` file with identical configuration:

- **Proxmox Hosts**: `pve-01`, `pve-02`, `pve-03`, `pve-04`
- **Template**: `terraform-12-17-25`
- **SSH Key**: Pre-configured RSA key for access
- **API Endpoint**: `https://192.168.1.42:8006/api2/json`
- **Network Settings**: IP prefix, gateway, subnet mask

The vars.tf files are generated automatically by the script to keep both directories self-contained.

### VM Specifications

**Control Plane Nodes:**
- Name: `k8s-dev-ctrl-01`, `k8s-dev-ctrl-02`, etc.
- CPU: 2 cores, 1 socket
- RAM: 2GB
- Disk: 32GB (on `talos-hosts` storage)
- Tags: `k8s,control-plane`
- Networks: 2 (vmbr0, vmbr0 with VLAN 5)

**Worker Nodes:**
- Name: `k8s-dev-wrkr-01`, `k8s-dev-wrkr-02`, etc.
- CPU: 2 cores, 1 socket
- RAM: 2GB
- Disk: 32GB (on `talos-hosts` storage)
- Tags: `k8s,worker`
- Networks: 2 (vmbr0, vmbr0 with VLAN 5)

### Node Distribution

Nodes are distributed across Proxmox hosts using round-robin:
- Uses `count.index % length(local.target_hosts)` for distribution
- Automatically balances across all available hosts

### Networking

- **Network 0**: Bridged to vmbr0, DHCP enabled
- **Network 1**: Bridged to vmbr0, VLAN 5, DHCP enabled
- Cloud-init handles initial network configuration

## Important Notes

1. **Separate State**: Control and worker nodes have separate Terraform state. Deploy them independently.

2. **Count Changes**: To modify the number of nodes, re-run the generator script and apply changes:
   ```bash
   ./generate-k8s-cluster.sh 5 5  # Increase to 5 of each
   cd control && terraform apply
   cd ../worker && terraform apply
   ```

3. **Storage Requirements**:
   - Cloud-init ISO: stored on `local-zfs`
   - VM disks: stored on `talos-hosts` (RBD/Ceph)

4. **Provider Version**: Using Telmate Proxmox provider v3.0.2-rc05

5. **Lifecycle Management**: Network changes are ignored to prevent unwanted updates during Terraform runs.

## Customization

### Modifying Variables

To customize variables (SSH key, Proxmox hosts, template name, etc.), edit the `generate_vars_tf()` function in the generator script before running it.

### Modifying VM Specifications

To customize VM specifications, edit the generator script:
- CPU cores: Modify `cores = 2` line
- Memory: Modify `memory = 2048` line
- Disk size: Modify `size = 32` line
- Storage pools: Modify `storage = "talos-hosts"` line
- Tags: Modify `tags = "k8s,control-plane"` or `tags = "k8s,worker"` lines

## Troubleshooting

### VMs not starting
- Check template exists: `terraform-12-17-25`
- Verify storage pools are accessible: `local-zfs`, `talos-hosts`
- Ensure Proxmox hosts are online

### Authentication errors
- Verify API token in `vars.tf` in each directory (control/worker)
- Check token permissions in Proxmox
- Regenerate vars.tf with correct credentials using the script

### Network issues
- Verify bridge `vmbr0` exists on all hosts
- Check VLAN 5 configuration
- Ensure DHCP server is running on both networks

## References

- [Telmate Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
