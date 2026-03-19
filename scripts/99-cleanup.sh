#!/usr/bin/env bash
# Clean up build artifacts — keep cloud-init enabled for post-deploy customization
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Remove the packer build user
userdel -r packer 2>/dev/null || true

# Clean apt cache
apt-get -y autoremove --purge
apt-get -y clean
rm -rf /var/lib/apt/lists/*

# Clear machine-id so each deployed VM gets a unique one
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Reset cloud-init so it runs again on next boot
cloud-init clean --logs

# Clear temp and log files
rm -rf /tmp/* /var/tmp/*
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true

# Zero out free space for better compression (optional, helps with sparse images)
dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
rm -f /EMPTY
sync
