#!/bin/bash


CONFIG_FILE="./backup.config"

# ---------- 1. Load configuration -------------------------
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"


# ---------- 2. Logging system -----------------------------
LOGFILE="$BACKUP_DESTINATION/backup.log"

log() {
    level="$1"
    shift
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $level: $*" | tee -a "$LOGFILE"
}


# ---------- 3. Prevent multiple script runs ---------------
LOCKFILE="/tmp/backup.lock"

if [ -f "$LOCKFILE" ]; then
    log ERROR "Backup already running. Exiting."
    exit 1
fi

touch "$LOCKFILE"
cleanup_lock() { rm -f "$LOCKFILE"; }
trap cleanup_lock EXIT


# ---------- 4. Dry-run detection ---------------------------
DRYRUN=0
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
    log INFO "Dry run enabled - no changes will be made."
fi


# ---------- 5. Helper: notification (fake email) -----------
notify() {
    if [ "$EMAIL_NOTIFICATION" != "none" ]; then
        echo "$(date): $1" >> email.txt
    fi
}


# ---------- 6. List mode ----------------------------------
if [ "$1" == "--list" ]; then
    log INFO "Available backups:"
    ls -lh "$BACKUP_DESTINATION" | grep "backup-"
    exit 0
fi


# ---------- 7. Restore mode -------------------------------
if [ "$1" == "--restore" ]; then
    BACKUP_FILE="$2"
    TARGET_DIR="$4"

    if [ ! -f "$BACKUP_FILE" ]; then
        log ERROR "Backup file not found"
        exit 1
    fi

    if [ -z "$TARGET_DIR" ]; then
        log ERROR "No restore destination provided"
        exit 1
    fi

    log INFO "Restoring $BACKUP_FILE to $TARGET_DIR"

    if [ $DRYRUN -eq 1 ]; then
        log INFO "Would restore $BACKUP_FILE to $TARGET_DIR"
        exit 0
    fi

    mkdir -p "$TARGET_DIR"
    tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR"
    log SUCCESS "Restore completed"
    exit 0
fi


# ---------- 8. Verify backup -------------------------------
verify_backup() {
    BACKUP_FILE="$1"

    CHECKSUM_FILE="${BACKUP_FILE}.md5"

    if [ ! -f "$BACKUP_FILE" ] || [ ! -f "$CHECKSUM_FILE" ]; then
        log ERROR "Backup or checksum missing"
        exit 1
    fi

    log INFO "Verifying $BACKUP_FILE"

    NEW_SUM=$(md5sum "$BACKUP_FILE" | cut -d " " -f1)
    OLD_SUM=$(cut -d " " -f1 "$CHECKSUM_FILE")

    if [ "$NEW_SUM" != "$OLD_SUM" ]; then
        log ERROR "Checksum failed!"
        exit 1
    fi

    TEMP_DIR=$(mktemp -d)
    TEST_FILE=$(tar -tzf "$BACKUP_FILE" | head -n 1)
    tar -xzf "$BACKUP_FILE" "$TEST_FILE" -C "$TEMP_DIR" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        log ERROR "Test extract failed"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    rm -rf "$TEMP_DIR"
    log SUCCESS "Backup verified successfully"
}


# ---------- 9. Normal backup mode -------------------------
SOURCE_FOLDER="$1"

if [ -z "$SOURCE_FOLDER" ]; then
    log ERROR "No folder given. Usage: ./backup.sh /path/to/folder"
    exit 1
fi

if [ ! -d "$SOURCE_FOLDER" ]; then
    log ERROR "Source folder does not exist"
    exit 1
fi


# ---------- 10. Ensure backup destination exists ----------
if [ ! -d "$BACKUP_DESTINATION" ]; then
    log INFO "Creating backup directory: $BACKUP_DESTINATION"
    mkdir -p "$BACKUP_DESTINATION"
fi


# ---------- 11. Check available disk space ----------------
REQUIRED=$(du -s "$SOURCE_FOLDER" | awk '{print $1}')
AVAILABLE=$(df "$BACKUP_DESTINATION" | awk 'NR==2 {print $4}')

if [ "$AVAILABLE" -lt "$REQUIRED" ]; then
    log ERROR "Not enough disk space for backup"
    exit 1
fi


# ---------- 12. Build filename ----------------------------
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
BACKUP_NAME="backup-$TIMESTAMP.tar.gz"
BACKUP_PATH="$BACKUP_DESTINATION/$BACKUP_NAME"


# ---------- 13. Exclusions from config --------------------
IFS=',' read -r -a parsed <<< "$EXCLUDE_PATTERNS"
EXCLUDES=()

for ex in "${parsed[@]}"; do
    EXCLUDES+=("--exclude=$ex")
done


# ---------- 14. Create backup ------------------------------
log INFO "Starting backup of $SOURCE_FOLDER"

if [ $DRYRUN -eq 1 ]; then
    log INFO "Would create archive at $BACKUP_PATH"
else
    tar -czf "$BACKUP_PATH" "${EXCLUDES[@]}" -C "$SOURCE_FOLDER" .
fi

log SUCCESS "Backup created: $BACKUP_PATH"


# ---------- 15. Create checksum ----------------------------
if [ $DRYRUN -eq 1 ]; then
    log INFO "Would create checksum $BACKUP_PATH.md5"
else
    md5sum "$BACKUP_PATH" > "$BACKUP_PATH.md5"
    log SUCCESS "Checksum created"
fi


# ---------- 16. Verify it ----------------------------------
if [ $DRYRUN -eq 0 ]; then
    verify_backup "$BACKUP_PATH"
fi


# ---------- 17. Cleanup old backups ------------------------
log INFO "Running cleanup..."

cd "$BACKUP_DESTINATION" || exit 1

today=$(date +%s)
daily=()
weekly=()
monthly=()

for file in backup-*.tar.gz; do
    [ -e "$file" ] || continue

    file_date=$(echo "$file" | sed -E 's/backup-([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')
    file_epoch=$(date -d "$file_date" +%s)
    age_days=$(( (today - file_epoch) / 86400 ))

    if [ $age_days -le 6 ]; then daily+=("$file")
    elif [ $age_days -le 27 ]; then weekly+=("$file")
    else monthly+=("$file")
    fi
done

delete_extra() {
    limit=$1
    shift
    files=("$@")

    extra=$(( ${#files[@]} - limit ))

    if [ $extra -gt 0 ]; then
        to_delete=$(printf "%s\n" "${files[@]}" | sort | head -n $extra)
        for del in $to_delete; do
            if [ $DRYRUN -eq 1 ]; then
                log INFO "Would delete $del"
            else
                rm -f "$del" "$del.md5"
                log INFO "Deleted old backup: $del"
            fi
        done
    fi
}

delete_extra "$DAILY_KEEP"   "${daily[@]}"
delete_extra "$WEEKLY_KEEP"  "${weekly[@]}"
delete_extra "$MONTHLY_KEEP" "${monthly[@]}"

log SUCCESS "Backup job completed"
notify "Backup completed successfully"
