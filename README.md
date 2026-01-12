<div align="center">
  <img src="mox-cloud.png" width="200" alt="Mox Cloud Background">

  <h1>Mox Cloud</h1>
  <p><strong>A launch platform for automated cluster deployment via Terraform, cloud-init, and Proxmox.</strong></p>

  [![GitHub Release](https://img.shields.io/github/v/release/untraceablez/moxcloud)](https://github.com/untraceablez/moxcloud/releases)
  [![License](https://img.shields.io/github/license/untraceablez/moxcloud)](https://github.com/untraceablez/moxcloud/blob/main/LICENSE)
  [![GitHub Stars](https://img.shields.io/github/stars/untraceablez/moxcloud)](https://github.com/untraceablez/moxcloud/stargazers)
  [![GitHub Issues](https://img.shields.io/github/issues/untraceablez/moxcloud)](https://github.com/untraceablez/moxcloud/issues)

   [Documentation](https://docs.moxcloud.org) · [Report Bug](https://github.com/untraceablez/moxcloud/issues)
</div>

---

[Proxmox](https://www.proxmox.com), [`cloud-init`](https://cloud-init.io/), and [Terraform](https://developer.hashicorp.com/terraform) {or [OpenTofu](https://opentofu.org/) for those inclined..}. These are all great technologies for automating the deployment, base configuration, and hosting of virtual machines. 

This repository, [Mox Cloud](https://github.com/untraceablez/moxcloud), aims to allow you to clone this repo, run through some first-time setup scripts, and end up with an automated process for deploying clusters of VMs to a standalone Proxmox instance or cluster. 

The main goal is to deploy VMs for using as nodes in a [Kubernetes](https://kubernetes.io/), but you could use this to deploy traditional clusters for load-balancers, the [Grafana Stack](https://grafana.com/about/grafana-stack/), or anything else you can imagine!

## Structure

* `cloudinit`: This directory features the scripts needed to generate a customized cloud-init image, as well as a cron job to pull down the latest img from Canonical on a schedule. This allows us to have a constantly fresh template from which to deploy our VMs. 

* `terraform`: This directory contains all the files for deploying your actual VM clusters. Within this directory is an example directory for deploying a 6 node (3 control, 3 worker) cluster oriented for Kubernetes. Use this as a starting point for creating your own files. 

## Quick Start

### Using the Self-Extracting Installer

The easiest way to get started is with the single-file installer:

```bash
# Download the installer (from releases or build it yourself)
wget https://github.com/untraceablez/moxcloud/releases/latest/download/moxcloud-install.sh

# Run the installer
bash moxcloud-install.sh

# Follow the setup wizard
cd moxcloud
./template-setup.sh

# Create your cloud-init template
./template-script.sh
```

### Building the Installer

If you want to build the installer yourself:

```bash
git clone https://github.com/untraceablez/moxcloud.git
cd moxcloud
./build-installer.sh
```

This creates `moxcloud-install.sh` - a single file you can distribute to users.

## Manual Setup

If you prefer to work directly with the repository:

1. Clone this repository
2. Navigate to `cloudinit/`
3. Run `./template-setup.sh` to configure your template
4. Run `./template-script.sh` to create the cloud-init template in Proxmox
5. Use the Terraform configurations in `terraform/` to deploy VMs

### Thanks

* A big thanks to the folks working on the [telmate/proxmox](https://github.com/Telmate/terraform-provider-proxmox) provider for Terraform. Without their awesome code, this repo wouldn't do much of anything!

* Credit to Volkan Baga & Wizards of the Coast, the name of this repository, and the fun little background, are inspired by Mox Opal, a beautiful and powerful Magic: The Gathering card. 
