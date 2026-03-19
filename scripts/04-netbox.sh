#!/usr/bin/env bash
# Install NetBox from source (official method)
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

NETBOX_HOME="/opt/netbox"
NETBOX_USER="netbox"

# Determine the latest version if needed
NETBOX_VERSION="${NETBOX_VERSION:-latest}"
if [ "$NETBOX_VERSION" = "latest" ]; then
  NETBOX_VERSION=$(curl -s https://api.github.com/repos/netbox-community/netbox/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
fi
echo "Installing NetBox v${NETBOX_VERSION}"

# Create netbox system user
groupadd --system "$NETBOX_USER" || true
useradd --system --gid "$NETBOX_USER" --home-dir "$NETBOX_HOME" --shell /bin/bash "$NETBOX_USER" || true

# Clone NetBox
git clone --depth 1 --branch "v${NETBOX_VERSION}" https://github.com/netbox-community/netbox.git "$NETBOX_HOME"
chown -R "$NETBOX_USER":"$NETBOX_USER" "$NETBOX_HOME"

# Generate a secret key
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')

# Create NetBox configuration
cp "$NETBOX_HOME/netbox/netbox/configuration_example.py" "$NETBOX_HOME/netbox/netbox/configuration.py"

cat > "$NETBOX_HOME/netbox/netbox/configuration.py" <<PYEOF
ALLOWED_HOSTS = ['*']

DATABASE = {
    'NAME':     'netbox',
    'USER':     'netbox',
    'PASSWORD': 'netbox',
    'HOST':     'localhost',
    'PORT':     '',
    'CONN_MAX_AGE': 300,
}

REDIS = {
    'tasks': {
        'HOST': 'localhost',
        'PORT': 6379,
        'USERNAME': '',
        'PASSWORD': '',
        'DATABASE': 0,
        'SSL': False,
    },
    'caching': {
        'HOST': 'localhost',
        'PORT': 6379,
        'USERNAME': '',
        'PASSWORD': '',
        'DATABASE': 1,
        'SSL': False,
    },
}

SECRET_KEY = '${SECRET_KEY}'
PYEOF

chown "$NETBOX_USER":"$NETBOX_USER" "$NETBOX_HOME/netbox/netbox/configuration.py"
chmod 600 "$NETBOX_HOME/netbox/netbox/configuration.py"

# Copy gunicorn config to expected location
cp "$NETBOX_HOME/contrib/gunicorn.py" "$NETBOX_HOME/gunicorn.py"
chown "$NETBOX_USER":"$NETBOX_USER" "$NETBOX_HOME/gunicorn.py"

# Run the NetBox upgrade script (creates venv, runs migrations, collects static files)
sudo -u "$NETBOX_USER" "$NETBOX_HOME/upgrade.sh"

# Create a superuser creation script for post-deploy use
cat > "$NETBOX_HOME/create-superuser.sh" <<'SCRIPT'
#!/usr/bin/env bash
# Run this after deployment to create the initial admin user:
#   sudo /opt/netbox/create-superuser.sh
set -euo pipefail
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py createsuperuser
SCRIPT
chmod +x "$NETBOX_HOME/create-superuser.sh"

# Set up NetBox housekeeping cron job
cat > /etc/cron.d/netbox-housekeeping <<CRON
# NetBox housekeeping — runs daily at 04:30
30 4 * * * netbox /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py housekeeping
CRON

# Create systemd service for NetBox (gunicorn)
cat > /etc/systemd/system/netbox.service <<SERVICE
[Unit]
Description=NetBox WSGI Service
Documentation=https://docs.netbox.dev/
After=network-online.target postgresql.service redis-server.service
Wants=network-online.target

[Service]
Type=simple
User=netbox
Group=netbox
WorkingDirectory=/opt/netbox/netbox
ExecStart=/opt/netbox/venv/bin/gunicorn \\
    --pid /var/tmp/netbox.pid \\
    --pythonpath /opt/netbox/netbox \\
    --config /opt/netbox/gunicorn.py \\
    netbox.wsgi
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
SERVICE

# Create systemd service for NetBox RQ (background tasks)
cat > /etc/systemd/system/netbox-rq.service <<SERVICE
[Unit]
Description=NetBox Request Queue Worker
Documentation=https://docs.netbox.dev/
After=network-online.target netbox.service
Wants=network-online.target

[Service]
Type=simple
User=netbox
Group=netbox
WorkingDirectory=/opt/netbox/netbox
ExecStart=/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py rqworker high default low
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
SERVICE

# Enable services
systemctl daemon-reload
systemctl enable netbox netbox-rq
