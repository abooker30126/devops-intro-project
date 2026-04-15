#!/usr/bin/env bash
set -euxo pipefail

echo "=== Disabling broken command-not-found apt hook (Jammy bug) ==="
if [ -f /etc/apt/apt.conf.d/50command-not-found ]; then
  sudo mv /etc/apt/apt.conf.d/50command-not-found /etc/apt/apt.conf.d/50command-not-found.disabled || true
fi

echo "=== Updating system packages ==="
# Jammy sometimes throws a non-fatal cnf-update-db error; treat it as non-fatal
sudo apt-get update -y || true

echo "=== Upgrading system packages ==="
sudo apt-get upgrade -y || true

echo "=== Installing base utilities ==="
sudo apt-get install -y curl wget git unzip software-properties-common ca-certificates
