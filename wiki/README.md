# Mox Cloud Wiki

Welcome to the Mox Cloud documentation! This wiki provides comprehensive guides for deploying automated VM clusters on Proxmox using cloud-init and Terraform/OpenTofu.

## Getting Started Guides

Follow these guides in order to set up your environment and deploy your first cluster:

### 1. [Prerequisites and Setup](01-Prerequisites-and-Setup.md)
**Time Required:** 1-2 hours (depending on Proxmox installation)

Learn how to install and configure the foundational components:
- Installing Proxmox VE
- Installing Terraform or OpenTofu
- Creating a Proxmox API user and token
- Configuring permissions and access

**Start here if:** You're setting up a new environment or need to configure API access.

### 2. [Cloud-Init Scripts](02-Cloud-Init-Scripts.md)
**Time Required:** 30-45 minutes

Create automated VM templates using cloud-init:
- Understanding cloud-init
- Configuring the setup script
- Creating VM templates
- Automating template updates
- Customizing packages and SSH keys

**Start here if:** You have Proxmox configured and need to create VM templates.

### 3. [Terraform Generator Script](03-Terraform-Generator.md)
**Time Required:** 30-60 minutes (first deployment)

Deploy VM clusters using the generator script:
- Understanding the generator
- Configuring cluster parameters
- Deploying control plane and worker nodes
- Scaling your cluster
- Advanced customization

**Start here if:** You have VM templates ready and want to deploy clusters.

## Quick Reference

### Complete Workflow

```bash
# 1. Install prerequisites (see guide 1)
# - Install Proxmox VE
# - Install Terraform or OpenTofu
# - Create API user and token

# 2. Create cloud-init template (see guide 2)
cd cloudinit/
./template-setup.sh    # Configure
./template-script.sh   # Create template

# 3. Generate and deploy cluster (see guide 3)
cd terraform/k8s/
./generate-k8s-cluster.sh 3 3   # Generate configs

cd control/
terraform init
terraform apply         # Deploy control plane

cd ../worker/
terraform init
terraform apply         # Deploy workers
```

### Common Commands

**Check Proxmox VMs:**
```bash
qm list                           # List all VMs
qm status <vmid>                  # Check VM status
qm start <vmid>                   # Start VM
qm stop <vmid>                    # Stop VM
```

**Terraform Operations:**
```bash
terraform init                    # Initialize Terraform
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform destroy                 # Destroy resources
terraform show                    # Show current state
```

**Cloud-Init:**
```bash
cloud-init status                 # Check cloud-init status (on VM)
cloud-init clean                  # Reset cloud-init (on VM)
qm cloudinit dump <vmid> user     # View cloud-init config
```

## Documentation Structure

```
wiki/
├── README.md                        # This file - Overview and index
├── 01-Prerequisites-and-Setup.md    # Proxmox, Terraform, API setup
├── 02-Cloud-Init-Scripts.md         # Template creation and automation
└── 03-Terraform-Generator.md        # Cluster deployment
```

## Troubleshooting Quick Links

### Prerequisites Issues
- [Proxmox installation problems](01-Prerequisites-and-Setup.md#troubleshooting)
- [API authentication failures](01-Prerequisites-and-Setup.md#api-token-authentication-fails)
- [Permission errors](01-Prerequisites-and-Setup.md#permission-denied-errors)

### Cloud-Init Issues
- [Script permission denied](02-Cloud-Init-Scripts.md#script-fails-with-permission-denied)
- [Package installation fails](02-Cloud-Init-Scripts.md#packages-fail-to-install)
- [SSH keys not working](02-Cloud-Init-Scripts.md#ssh-keys-not-working)
- [Template creation errors](02-Cloud-Init-Scripts.md#troubleshooting)

### Terraform/Deployment Issues
- [Generator script errors](03-Terraform-Generator.md#generator-script-issues)
- [Terraform initialization fails](03-Terraform-Generator.md#terraform-initialization-issues)
- [Deployment failures](03-Terraform-Generator.md#deployment-issues)
- [Network problems](03-Terraform-Generator.md#network-issues)

## Project Resources

### Main Repository
- [Mox Cloud GitHub](https://github.com/untraceablez/moxcloud)
- [Latest Releases](https://github.com/untraceablez/moxcloud/releases)
- [Report Issues](https://github.com/untraceablez/moxcloud/issues)

### External Documentation
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

### Community Resources
- [r/Proxmox](https://www.reddit.com/r/Proxmox/) - Reddit community
- [Proxmox Forum](https://forum.proxmox.com/) - Official forum
- [r/Terraform](https://www.reddit.com/r/Terraform/) - Terraform community

## Use Cases

### Development Clusters
Perfect for testing and development:
- **Setup:** 1 control node + 2 worker nodes
- **Resources:** Minimal CPU/RAM requirements
- **Use:** Testing Kubernetes deployments, learning, development

### Staging/Testing Clusters
Mirror production for testing:
- **Setup:** 3 control nodes + 3-5 worker nodes
- **Resources:** Medium resources
- **Use:** Pre-production testing, CI/CD pipelines

### Production Clusters
High availability production workloads:
- **Setup:** 5+ control nodes + 10+ worker nodes
- **Resources:** High CPU/RAM allocation
- **Use:** Production workloads, critical services

### Learning Kubernetes
Great for learning and experimentation:
- **Setup:** 1 control + 1 worker (minimal)
- **Resources:** Very low requirements
- **Use:** Learning K8s, experimentation, tutorials

## Feature Highlights

### Automated Template Management
- Automatically downloads latest Ubuntu cloud images
- Compares manifests to detect updates
- Scheduled template refreshes via cron
- Consistent base configuration across all VMs

### Flexible Cluster Deployment
- Deploy any number of control/worker nodes
- Independent control and worker management
- Easy scaling up or down
- Load balancing across Proxmox hosts

### Infrastructure as Code
- Version-controlled configurations
- Repeatable deployments
- Easy disaster recovery
- Environment-specific customization

### Self-Contained Design
- Each component is independent
- No external dependencies
- Easy to understand and modify
- Portable across environments

## Contributing

Found an issue or want to contribute? Check out:
- [GitHub Issues](https://github.com/untraceablez/moxcloud/issues) - Report bugs
- [Pull Requests](https://github.com/untraceablez/moxcloud/pulls) - Submit improvements

## Roadmap

Potential future enhancements:
- Multi-cluster management
- Alternative Kubernetes distributions (k3s, RKE2, Talos)
- Automated Kubernetes installation
- Storage provisioning (Ceph, Longhorn)
- Monitoring stack deployment
- Backup and disaster recovery automation

## Credits

**Mox Cloud** is maintained by [untraceablez](https://github.com/untraceablez)

**Thanks to:**
- [Telmate](https://github.com/Telmate/terraform-provider-proxmox) - Proxmox Terraform provider
- [Proxmox VE Team](https://www.proxmox.com/en/) - Virtualization platform
- [Cloud-Init Team](https://cloud-init.io/) - Cloud instance initialization
- [HashiCorp](https://www.hashicorp.com/) / [OpenTofu](https://opentofu.org/) - Infrastructure as Code tools
- [Canonical](https://canonical.com/) - Ubuntu cloud images
- [Volkan Baga](https://baga.de/) & [Wizards of the Coast](https://company.wizards.com/) - Inspiration from [Mox Opal](https://scryfall.com/card/som/179/mox-opal)

## License

This project is licensed under the terms specified in the [LICENSE](../LICENSE) file.

---

**Ready to get started?** Begin with [Prerequisites and Setup →](01-Prerequisites-and-Setup.md)
