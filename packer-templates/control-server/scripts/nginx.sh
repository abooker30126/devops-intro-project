#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing NGINX ==="
sudo apt-get update -y
sudo apt-get install -y nginx

echo "=== Enabling and starting NGINX ==="
sudo systemctl enable nginx
sudo systemctl start nginx

echo "=== NGINX installation complete ==="
