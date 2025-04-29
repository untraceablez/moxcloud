variable "ssh_key" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFL6VqqEs9Sh/ccB/O3K7Hg6T0QnggoX8Byw34XPr9bv"
}

variable "proxmox_host_01" {
  default = "pve-test-01"
}

variable "proxmox_host_02" {
  default = "pve-test-02"
}

variable "proxmox_host_03" {
  default = "pve-test-03"
}

variable "template_name" {
  default = "ubuntu-2404-cloudinit-template"
}
variable "proxmox_api_url" {
  default = "https://10.0.0.192:8006/api2/json"
}

variable "proxmox_api_token_id" {
  default = "terraform-prov@pve!test-token-01"
}

variable "proxmox_api_token_secret" {
  default = "c64db78b-1ba7-4b32-9922-1b8f83f526bb"
}
variable "vm_ip_prefix" {
  default = "10.0.0."
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
