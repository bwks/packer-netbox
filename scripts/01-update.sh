#!/usr/bin/env bash
# Update system packages and install prerequisites
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Wait for any background apt processes (cloud-init, unattended-upgrades)
while lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || lsof /var/lib/apt/lists/lock >/dev/null 2>&1; do
  echo "Waiting for apt lock..."
  sleep 5
done
echo "Apt locks are free"

apt-get update
apt-get -y dist-upgrade

# NetBox system dependencies
apt-get -y install \
  git \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  build-essential \
  libxml2-dev \
  libxslt1-dev \
  libffi-dev \
  libpq-dev \
  libssl-dev \
  zlib1g-dev \
  curl \
  wget
