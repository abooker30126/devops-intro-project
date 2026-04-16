#!/bin/bash
set -euo pipefail

echo "[user_data] Setting hostname to ${hostname}..."
hostnamectl set-hostname "${hostname}"

echo "[user_data] Running bootstrap script..."
if [ -f /opt/scripts/bootstrap.sh ]; then
  chmod +x /opt/scripts/bootstrap.sh
  /opt/scripts/bootstrap.sh
fi

echo "[user_data] Starting Nginx..."
systemctl start nginx

echo "[user_data] First-boot setup complete."
