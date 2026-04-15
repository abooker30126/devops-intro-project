#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing Graphite dependencies ==="
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-dev gunicorn

echo "=== Installing Graphite components via pip ==="
sudo pip3 install \
  whisper \
  carbon \
  graphite-web

echo "=== Creating Graphite directories ==="
sudo mkdir -p /opt/graphite/storage/whisper
sudo mkdir -p /opt/graphite/conf

echo "=== Setting permissions ==="
sudo chown -R www-data:www-data /opt/graphite

echo "=== Initializing Graphite database ==="
sudo graphite-manage migrate --run-syncdb

echo "=== Creating systemd service for Carbon Cache ==="
sudo tee /etc/systemd/system/carbon-cache.service > /dev/null <<EOF
[Unit]
Description=Graphite Carbon Cache
After=network.target

[Service]
ExecStart=/usr/local/bin/carbon-cache --config=/opt/graphite/conf/carbon.conf start
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable carbon-cache
sudo systemctl start carbon-cache

echo "=== Graphite installation complete ==="
