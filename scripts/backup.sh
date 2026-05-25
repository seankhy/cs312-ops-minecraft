#!/bin/bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BUCKET="cs312-hsunyu-minecraft-backups"

WORLD_DIR=$(sudo find /var/lib/rancher/k3s/storage -name "world" 2>/dev/null | head -1)

if [ -z "$WORLD_DIR" ]; then
  echo "World directory not found"
  exit 1
fi

sudo tar -czf /tmp/world-backup-${TIMESTAMP}.tar.gz -C "$(dirname $WORLD_DIR)" world
aws s3 cp /tmp/world-backup-${TIMESTAMP}.tar.gz s3://${BUCKET}/backups/world-${TIMESTAMP}.tar.gz
aws s3 cp /tmp/world-backup-${TIMESTAMP}.tar.gz s3://${BUCKET}/world.tar.gz
sudo rm /tmp/world-backup-${TIMESTAMP}.tar.gz
echo "Backup complete: world-${TIMESTAMP}.tar.gz"
