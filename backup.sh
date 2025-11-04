#!/bin/bash
set -e

# === Configuration ===
CONFIG_FILE="./backup.config"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "[WARNING] No config file found, using defaults."
    BACKUP_DEST="$HOME/backups"
    EXCLUDE_PATTERNS=".git,node_modules,.cache"
    CHECKSUM_TYPE="sha256"
    DAILY_KEEP=7
    WEEKLY_KEEP=4
    MONTHLY_KEEP=3
fi

# === Input Validation ===
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/folder"
    exit 1
fi

SOURCE_DIR="$1"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "[ERROR] Source folder not found: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$BACKUP_DEST"

# === Variables ===
DATE=$(date +"%Y-%m-%d-%H%M")
BACKUP_NAME="backup-$DATE.tar.gz"
BACKUP_PATH="$BACKUP_DEST/$BACKUP_NAME"
CHECKSUM_FILE="$BACKUP_PATH.$CHECKSUM_TYPE"

# === Exclusions ===
EXCLUDES=()
IFS=',' read -ra PATTERNS <<< "$EXCLUDE_PATTERNS"
for pattern in "${PATTERNS[@]}"; do
    EXCLUDES+=(--exclude="$pattern")
done

# === Create Backup ===
echo "[INFO] Creating backup: $BACKUP_PATH"
tar -czf "$BACKUP_PATH" "${EXCLUDES[@]}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
echo "[SUCCESS] Backup created: $BACKUP_PATH"

# === Generate Checksum ===
echo "[INFO] Generating $CHECKSUM_TYPE checksum..."
if [ "$CHECKSUM_TYPE" == "sha256" ]; then
    sha256sum "$BACKUP_PATH" > "$CHECKSUM_FILE"
else
    md5sum "$BACKUP_PATH" > "$CHECKSUM_FILE"
fi
echo "[SUCCESS] Checksum saved to: $CHECKSUM_FILE"

# === Verify Checksum ===
echo "[INFO] Verifying checksum..."
if [ "$CHECKSUM_TYPE" == "sha256" ]; then
    if sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
        echo "[SUCCESS] Checksum verified!"
    else
        echo "[ERROR] Checksum mismatch!"
        exit 1
    fi
else
    if md5sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
        echo "[SUCCESS] Checksum verified!"
    else
        echo "[ERROR] Checksum mismatch!"
        exit 1
    fi
fi

# === Test Extract Backup ===
echo "[INFO] Testing archive integrity..."
if tar -tzf "$BACKUP_PATH" >/dev/null 2>&1; then
    echo "[SUCCESS] Backup integrity test passed!"
else
    echo "[ERROR] Backup archive corrupted!"
    exit 1
fi

# === Retention Policy (Delete Old Backups) ===
echo "[INFO] Applying retention policy..."

# Sort backups by modification time
BACKUPS=($(ls -1t "$BACKUP_DEST"/backup-*.tar.gz 2>/dev/null))
TOTAL_BACKUPS=${#BACKUPS[@]}

# Keep 7 daily, 4 weekly, 3 monthly
KEEP_LIMIT=$((DAILY_KEEP + WEEKLY_KEEP + MONTHLY_KEEP))
if [ $TOTAL_BACKUPS -gt $KEEP_LIMIT ]; then
    TO_DELETE=$((TOTAL_BACKUPS - KEEP_LIMIT))
    echo "[INFO] Found $TOTAL_BACKUPS backups, keeping $KEEP_LIMIT, deleting $TO_DELETE old backups."
    for ((i=KEEP_LIMIT; i<TOTAL_BACKUPS; i++)); do
        OLD_BACKUP="${BACKUPS[$i]}"
        echo "[INFO] Deleting old backup: $OLD_BACKUP"
        rm -f "$OLD_BACKUP" "$OLD_BACKUP.sha256" "$OLD_BACKUP.md5" 2>/dev/null || true
    done
else
    echo "[INFO] No old backups to delete."
fi

echo "[DONE] Backup completed successfully!"
