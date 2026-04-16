#!/usr/bin/env bash
# /opt/scripts/bootstrap.sh
# First-boot helper — called via user-data or cloud-init.

set -euo pipefail

echo "[bootstrap] Starting first-boot configuration..."

# ── Fetch instance metadata (IMDSv2) ───────────────────────
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
        http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
        http://169.254.169.254/latest/meta-data/placement/region)

echo "[bootstrap] Instance: ${INSTANCE_ID} in ${REGION}"

# ── Start application service ──────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable app.service
sudo systemctl start app.service || echo "[bootstrap] app.service not ready yet — skipping"

echo "[bootstrap] First-boot configuration complete."
