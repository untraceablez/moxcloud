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
  default = "cloudinit-template-10-18-25"
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
