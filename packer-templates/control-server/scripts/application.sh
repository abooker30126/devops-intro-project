#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing Node.js 20 LTS ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential

echo "=== Creating application directory ==="
sudo mkdir -p /opt/app
sudo chown -R ubuntu:ubuntu /opt/app

echo "=== Cloning application repository ==="
sudo -u ubuntu git clone https://github.com/abooker30126/devops-intro-project.git /opt/app

echo "=== Installing application dependencies ==="
cd /opt/app
sudo -u ubuntu npm install --production

echo "=== Building application ==="
sudo -u ubuntu npm run build || true

echo "=== Creating systemd service for Node.js app ==="
sudo tee /etc/systemd/system/app.service > /dev/null <<EOF
[Unit]
Description=Node.js Application
After=network.target

[Service]
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/server.js
Restart=always
RestartSec=10
User=ubuntu
Environment=NODE_ENV=production

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling and starting app service ==="
sudo systemctl daemon-reload
sudo systemctl enable app
sudo systemctl restart app

echo "=== Application installation complete ==="
