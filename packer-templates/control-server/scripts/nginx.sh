#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing NGINX ==="
sudo apt-get update -y || true
sudo apt-get install -y nginx

echo "=== Removing default site ==="
sudo rm -f /etc/nginx/sites-enabled/default || true

echo "=== Installing reverse proxy configs ==="
sudo cp /tmp/nginx/jenkins.conf /etc/nginx/sites-available/
sudo cp /tmp/nginx/grafana.conf /etc/nginx/sites-available/
sudo cp /tmp/nginx/app.conf /etc/nginx/sites-available/

sudo ln -sf /etc/nginx/sites-available/jenkins.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/grafana.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/

echo "=== Restarting NGINX ==="
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=== NGINX reverse proxy configuration complete ==="
