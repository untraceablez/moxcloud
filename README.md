# Proxmox Cloud-Init Template Scripts

This directory contains two scripts, `template-setup.sh` and `template-script.sh`, that work together to automatically download, provision, and maintain an Ubuntu cloud-init VM template on a Proxmox host.

## Overview

* `template-setup.sh`: This is the **interactive setup script** you run first. It creates your configuration files (`.env` and `template-config.txt`) and sets up a cron job to run the main script.
* `template-script.sh`: This is the **main provisioning script**. It handles dependency installation, downloads the latest Ubuntu cloud-init image, injects your custom settings (packages, SSH keys, DNS), and creates the Proxmox VM template. It is designed to be run by the setup script and the cron job.

## Features

* **SSH Key Authentication Only**: By default, this script provisions templates that rely on SSH key-based authentication. This aligns with the security standards of official cloud images, which disable password logins when an SSH key is present.
* **Automatic Dependency Installation**: Checks for and installs `wget` and `libguestfs-tools` on the Proxmox host if they are missing.
* **Daily Image Check**: Automatically checks a remote manifest file daily (via cron) to see if a newer Ubuntu cloud image is available.
* **Automatic Rebuilds**: If a new image is found, the script destroys the old template and builds a new one from scratch.
* **Custom Package Injection**: Installs `qemu-guest-agent` and any other packages you define in your `.env` file (e.g., `neofetch`, `htop`) directly into the template image using `virt-customize`.
* **SSH Key Injection**: Reads one or more SSH public key *paths* from your `.env` file and injects them into the template for passwordless access.
* **Network Configuration**: Sets default DNS servers and a DNS search domain for the template.
* **Interactive Cron Setup**: `template-setup.sh` guides you through setting up the cron job schedule.

## How to Use

1.  Place `template-setup.sh` and `template-script.sh` in the same directory on your Proxmox host (e.g., `/home/your-user/cloud-images`).
2.  Make the scripts executable:
    ```bash
    chmod +x template-setup.sh template-script.sh
    ```
3.  Run the setup script for the first time:
    ```bash
    ./template-setup.sh
    ```
4.  The script will see that no `.env` file exists, create a sample one, and exit with a message:
    `Please update the generated .env file then run this script again.`
5.  Edit the newly created `.env` file with your custom SSH key paths, DNS servers, and desired packages.
6.  Run the setup script a **second time**:
    ```bash
    ./template-setup.sh
    ```
7.  This time, the script will find the `.env` file and guide you through setting up the VM and cron job parameters (VM ID, Name, Storage, Schedule).
8.  After you complete the prompts, the script will build your first template. To log in, you must use the SSH key you provided and the **default username** for the cloud image (e.g., `ubuntu` for Ubuntu images).

    ```bash
    # Example Login
    ssh -i /path/to/your/private_key ubuntu@<VM_IP_ADDRESS>
    ```
    If you need to access the VM via the Proxmox web console, you will be logged in as the root user.

## File Descriptions

* **`template-setup.sh`**:
    The interactive, one-time setup script. It creates the `.env` file on its first run, then creates `template-config.txt` and the cron job on its second run.
* **`template-script.sh`**:
    The main worker script. It installs dependencies, compares image manifests, downloads images, customizes the image with `virt-customize`, and creates the VM template with `qm` commands.
* **`.env`** (Generated, **Git-Ignored**):
    Stores your custom configurations (SSH key paths, packages, DNS).
* **`template-config.txt`** (Generated, **Git-Ignored**):
    Stores the non-secret settings from the setup script (VM ID, name, storage, cron string).

## A Note on `.gitignore`

This solution is designed to work safely with Git. The scripts automatically generate a `.env` file and a `template-config.txt` file. 