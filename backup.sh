#!/bin/bash

# === Configuration Section ===
# Directories to back up (customize these)
SOURCE_DIRS="$HOME/backup-script/sample-data"
# Destination for backups
BACKUP_DIR="$HOME/backup-script/backups"
# Timestamp format
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_$DATE.tar.gz"
# Retention policy
RETENTION_DAYS=7

# === Start Backup ===
echo "Starting backup of: $SOURCE_DIRS"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" $SOURCE_DIRS

# Check if tar was successful
if [ $? -eq 0 ]; then
    echo "Backup saved to: $BACKUP_DIR/$BACKUP_NAME"
else
    echo "Backup failed!"
    exit 1
fi

# === Delete Old Backups ===
echo "Deleting backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm {} \;
echo "Cleanup done. Script finished!"
