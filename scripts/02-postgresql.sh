#!/usr/bin/env bash
# Install and configure PostgreSQL for NetBox
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -y install postgresql

# Start PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# Create the NetBox database and user
# Password will be set to 'netbox' — should be changed post-deploy via cloud-init or manual config
sudo -u postgres psql <<SQL
CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD 'netbox';
ALTER DATABASE netbox OWNER TO netbox;
GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
SQL
