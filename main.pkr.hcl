packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "netbox" {
  # Base image
  iso_url      = var.ubuntu_image_url
  iso_checksum = var.ubuntu_image_checksum
  disk_image   = true

  # Output
  output_directory = "output"
  vm_name          = "netbox-ubuntu-24.04.qcow2"
  format           = "qcow2"

  # Disk — sparse/thin provisioned qcow2
  disk_size            = var.disk_size
  disk_compression     = true
  disk_discard         = "unmap"
  disk_detect_zeroes   = "unmap"

  # VM resources
  memory   = var.memory
  cpus     = var.cpus
  accelerator = "kvm"

  # Cloud-init seed ISO via cd_files
  cd_files = [
    "http/meta-data",
    "http/user-data",
  ]
  cd_label = "cidata"

  # Network
  net_device = "virtio-net"

  # SSH connection for provisioning
  communicator     = "ssh"
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "10m"
  shutdown_command  = "sudo shutdown -P now"

  # Headless build
  headless = true

  # QEMU args — enable virtio for better performance
  qemuargs = [
    ["-serial", "mon:stdio"],
  ]
}

build {
  sources = ["source.qemu.netbox"]

  # Wait for cloud-init to finish before provisioning
  # Exit code 0=running, 1=done, 2=done with recoverable errors — all acceptable
  provisioner "shell" {
    inline = [
      "sudo cloud-init status --wait || true",
    ]
  }

  provisioner "shell" {
    scripts = [
      "scripts/01-update.sh",
      "scripts/02-postgresql.sh",
      "scripts/03-redis.sh",
      "scripts/04-netbox.sh",
      "scripts/05-nginx.sh",
      "scripts/99-cleanup.sh",
    ]
    environment_vars = [
      "NETBOX_VERSION=${var.netbox_version}",
    ]
    execute_command   = "sudo -E bash -eu '{{ .Path }}'"
    expect_disconnect = false
  }
}
