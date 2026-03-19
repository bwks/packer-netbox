variable "ubuntu_image_url" {
  type        = string
  description = "URL for the Ubuntu 24.04 cloud image"
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "ubuntu_image_checksum" {
  type        = string
  description = "Checksum for the Ubuntu cloud image (use 'file:' prefix for checksum URL)"
  default     = "file:https://cloud-images.ubuntu.com/noble/current/SHA256SUMS"
}

variable "disk_size" {
  type        = string
  description = "Virtual disk size (sparse/thin provisioned)"
  default     = "32G"
}

variable "memory" {
  type        = number
  description = "Memory in MB for the build VM"
  default     = 4096
}

variable "cpus" {
  type        = number
  description = "Number of CPUs for the build VM"
  default     = 2
}

variable "ssh_username" {
  type        = string
  description = "SSH username for provisioning"
  default     = "packer"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for provisioning"
  default     = "packer"
  sensitive   = true
}

variable "netbox_version" {
  type        = string
  description = "NetBox version to install (git tag). Use 'latest' for the most recent release."
  default     = "latest"
}
