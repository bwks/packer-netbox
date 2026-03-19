# packer-netbox

Packer build for a [NetBox](https://github.com/netbox-community/netbox) VM image using QEMU/KVM.

Produces a sparse qcow2 image based on Ubuntu 24.04 LTS with cloud-init enabled for post-deploy customization.

## What's Included

- **NetBox** (latest) installed from source with gunicorn WSGI server
- **PostgreSQL** with a pre-configured `netbox` database and user
- **Redis** for caching and task queuing
- **nginx** as a reverse proxy
- **systemd** services for NetBox, NetBox RQ worker, and all dependencies
- **Cloud-init** remains enabled for hostname, network, and user configuration at deploy time

## Prerequisites

- [Packer](https://www.packer.io/) >= 1.10
- [QEMU](https://www.qemu.org/) with KVM support
- `xorriso` (for cloud-init seed ISO generation)

## Build

```bash
packer init .
packer build .
```

The output image is written to `output/netbox-ubuntu-24.04.qcow2`.

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ubuntu_image_url` | Ubuntu 24.04 cloud image | Base image URL |
| `ubuntu_image_checksum` | SHA256SUMS from Ubuntu | Image checksum |
| `disk_size` | `32G` | Virtual disk size (sparse) |
| `memory` | `4096` | Build VM memory (MB) |
| `cpus` | `2` | Build VM CPUs |
| `netbox_version` | `latest` | NetBox version to install |

Override variables with `-var`:

```bash
packer build -var 'disk_size=64G' -var 'netbox_version=4.5.5' .
```

## Deploy

The image is a standard qcow2 that can be deployed to any KVM/QEMU hypervisor (Proxmox, libvirt, OpenStack, etc.).

Cloud-init runs on first boot. Provide a `user-data` config to set hostname, users, network, etc.

Example with libvirt/virt-install:

```bash
# Resize disk if needed
qemu-img resize netbox-ubuntu-24.04.qcow2 64G

# Boot with cloud-init
virt-install \
  --name netbox \
  --memory 4096 \
  --vcpus 2 \
  --import \
  --disk netbox-ubuntu-24.04.qcow2 \
  --cloud-init user-data=user-data.yml \
  --os-variant ubuntu24.04
```

## Post-Deploy

1. **Create a NetBox superuser:**

   ```bash
   sudo /opt/netbox/create-superuser.sh
   ```

2. **Change the database password** in both PostgreSQL and the NetBox config:

   ```bash
   sudo -u postgres psql -c "ALTER USER netbox WITH PASSWORD 'new-secure-password';"
   sudo vim /opt/netbox/netbox/netbox/configuration.py
   sudo systemctl restart netbox netbox-rq
   ```

3. **Access NetBox** at `http://<vm-ip>/`

## Project Structure

```
.
├── main.pkr.hcl           # Packer build definition
├── variables.pkr.hcl      # Configurable variables
├── http/
│   ├── meta-data           # Cloud-init metadata (build-time)
│   └── user-data           # Cloud-init userdata (build-time)
└── scripts/
    ├── 01-update.sh        # System update and dependencies
    ├── 02-postgresql.sh    # PostgreSQL install and DB setup
    ├── 03-redis.sh         # Redis install
    ├── 04-netbox.sh        # NetBox from source, systemd services
    ├── 05-nginx.sh         # nginx reverse proxy
    └── 99-cleanup.sh       # Cleanup, reset cloud-init
```

## License

MIT
