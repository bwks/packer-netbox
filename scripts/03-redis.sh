#!/usr/bin/env bash
# Install Redis for NetBox caching and task queuing
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -y install redis-server

systemctl enable redis-server
systemctl start redis-server

# Verify Redis is responding
redis-cli ping
