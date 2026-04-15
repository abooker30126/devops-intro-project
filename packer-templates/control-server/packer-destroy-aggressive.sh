#!/bin/bash
set -e

echo "=== PACKER AGGRESSIVE CLEANUP STARTED ==="

###############################################
# 1. Delete AMI + Snapshot from manifest.json
###############################################
if [ -f "manifest.json" ]; then
    AMI_ID=$(jq -r '.builds[0].artifact_id' manifest.json | cut -d':' -f2)

    if [ -n "$AMI_ID" ] && [ "$AMI_ID" != "null" ]; then
        echo "[+] Deregistering AMI: $AMI_ID"
        aws ec2 deregister-image --image-id "$AMI_ID" || true

        SNAPSHOT_ID=$(aws ec2 describe-images --image-ids "$AMI_ID" \
            --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' \
            --output text 2>/dev/null)

        if [[ -n "$SNAPSHOT_ID" && "$SNAPSHOT_ID" != "None" ]]; then
            echo "[+] Deleting snapshot: $SNAPSHOT_ID"
            aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID" || true
        else
            echo "[+] No snapshot found for AMI"
        fi
    else
        echo "[!] No AMI ID found in manifest.json"
    fi
else
    echo "[!] manifest.json not found — skipping AMI cleanup"
fi

###############################################
# 2. Delete leftover Packer security groups
###############################################
echo "[+] Searching for leftover Packer security groups..."
SG_IDS=$(aws ec2 describe-security-groups \
    --query "SecurityGroups[?starts_with(GroupName, 'packer')].GroupId" \
    --output text)

if [ -n "$SG_IDS" ]; then
    for SG in $SG_IDS; do
        echo "[+] Deleting security group: $SG"
        aws ec2 delete-security-group --group-id "$SG" || true
    done
else
    echo "[+] No Packer security groups found"
fi

###############################################
# 3. Delete leftover Packer keypairs
###############################################
echo "[+] Searching for leftover Packer keypairs..."
KEYS=$(aws ec2 describe-key-pairs \
    --query "KeyPairs[?starts_with(KeyName, 'packer')].KeyName" \
    --output text)

if [ -n "$KEYS" ]; then
    for KEY in $KEYS; do
        echo "[+] Deleting keypair: $KEY"
        aws ec2 delete-key-pair --key-name "$KEY" || true
    done
else
    echo "[+] No Packer keypairs found"
fi

###############################################
# 4. Delete orphan ENIs created by failed builds
###############################################
echo "[+] Searching for orphan ENIs..."
ENIS=$(aws ec2 describe-network-interfaces \
    --query "NetworkInterfaces[?Status=='available'].NetworkInterfaceId" \
    --output text)

if [ -n "$ENIS" ]; then
    for ENI in $ENIS; do
        echo "[+] Deleting orphan ENI: $ENI"
        aws ec2 delete-network-interface --network-interface-id "$ENI" || true
    done
else
    echo "[+] No orphan ENIs found"
fi

echo "=== PACKER AGGRESSIVE CLEANUP COMPLETE ==="
