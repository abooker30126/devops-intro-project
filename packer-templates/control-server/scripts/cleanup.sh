#!/usr/bin/env bash
set -euxo pipefail

echo "=== Cleaning up apt cache ==="
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "=== Zeroing disk for smaller AMI ==="
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

echo "=== Cleanup complete ==="
