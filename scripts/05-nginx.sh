#!/usr/bin/env bash
# Install and configure nginx as reverse proxy for NetBox
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -y install nginx

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create NetBox nginx config
cat > /etc/nginx/sites-available/netbox <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 25m;

    location /static/ {
        alias /opt/netbox/netbox/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox

# Validate config
nginx -t

systemctl enable nginx
