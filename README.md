

# Automated Backup System (Bash)

---

## A. Project Overview

### What does your script do?
This Bash script automatically creates compressed backups (`.tar.gz`) of any folder on your computer.  
It checks that each backup is not damaged, saves a checksum (a digital fingerprint), and removes old backups to save disk space.

### Why is it useful?
Manual backups are easy to forget and take time.  
This script helps you:
- Keep your files safe.
- Save space by deleting old backups.
- Verify that your backups are not corrupted.
- Run everything with just one command.

---

## B. How to Use It

### Installation Steps
## Clone this repository:
   ```bash
   git clone https://github.com/Veereshshrikanths/backup-system.git
   cd backup-system


## Overview
This project is a fully automated backup tool written in Bash.  
It allows you to back up any directory into a compressed `.tar.gz` file, verify its integrity, and automatically delete old backups according to retention rules.

---

##  Features
-  Creates timestamped `.tar.gz` backups (e.g. `backup-2025-11-10-0915.tar.gz`)
-  Reads configuration dynamically from `backup.config`
-  Generates and verifies SHA256 or MD5 checksums
-  Validates backup integrity (tests extraction)
-  Automatically deletes old backups (retention policy)
-  Excludes unnecessary files (e.g. `.git`, `node_modules`, `.cache`)
-  Gracefully handles missing directories and invalid input

---

##  Project Structure
backup-system/
├── backup.sh # Main backup script
├── backup.config # Configuration file
└── README.md # Project documentation

makefile
Copy code

---

## Configuration (`backup.config`)
You can customize the behavior of your backups using this file.

**Example:**
```bash
# Destination for backups
BACKUP_DEST="$HOME/backups"

# Files and folders to exclude (comma-separated)
EXCLUDE_PATTERNS=".git,node_modules,.cache"

# Checksum type (sha256 or md5)
CHECKSUM_TYPE="sha256"

# Retention policy (number of backups to keep)
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
# Usage
 ## Make the script executable
bash
Copy code
chmod +x backup.sh
Run the backup
bash
Copy code
./backup.sh /path/to/folder
Example:

bash
Copy code
./backup.sh ~/Documents/test-data
# Output Example
csharp
Copy code
[INFO] Creating backup: /home/veeresh/backups/backup-2025-11-10-0915.tar.gz
[SUCCESS] Backup created: /home/veeresh/backups/backup-2025-11-10-0915.tar.gz
[INFO] Generating sha256 checksum...
[SUCCESS] Checksum saved to: /home/veeresh/backups/backup-2025-11-10-0915.tar.gz.sha256
[INFO] Verifying checksum...
[SUCCESS] Checksum verified!
[INFO] Testing archive integrity...
[SUCCESS] Backup integrity test passed!
[INFO] Applying retention policy...
[INFO] No old backups to delete.
[DONE] Backup completed successfully!

# How It Works
The script reads user-defined settings from backup.config.

Compresses the target folder into a .tar.gz file.

Creates a checksum file (.sha256 or .md5) for verification.

Tests the archive integrity to ensure the backup is not corrupted.

Deletes older backups according to the retention policy.

# Retention Policy
Automatically keeps:

7 daily backups

4 weekly backups

3 monthly backups

Old backups beyond this limit are deleted automatically.

# Logs & Verification
You can manually verify the checksum using:

bash
Copy code
cd ~/backups
sha256sum -c backup-2025-11-10-0915.tar.gz.sha256
Expected output:

makefile
Copy code
backup-2025-11-10-0915.tar.gz: OK
# Testing
Create a test folder:

bash
Copy code
mkdir -p ~/Documents/test-data
echo "Hello Backup!" > ~/Documents/test-data/sample.txt
Run the script:

bash
Copy code
./backup.sh ~/Documents/test-data
Check backup folder:

bash
Copy code
ls -lh ~/backups
# Optional: Automate with Cron
To run daily at 2 AM:

bash
Copy code
crontab -e
Add this line:



#Error Example (Folder doesn’t exist)
./backup.sh ~/fake-folder

#Create a test folder
mkdir -p ~/Documents/test-data
echo "Test file 1" > ~/Documents/test-data/file1.txt
echo "Test file 2" > ~/Documents/test-data/file2.txt

#Create a backup
./backup.sh ~/Documents/test-data

#Create multiple backups (fake "days")

touch -d "5 days ago" ~/backups/backup-2025-11-05-0900.tar.gz
./backup.sh ~/Documents/test-data


#Observe automatic deletion
#When there are more than 14 backups:
[INFO] Found 15 backups, keeping 14, deleting 1 old backup.

#Verify checksum
sha256sum -c ~/backups/backup-2025-11-10-0915.tar.gz.sha256
 #output
 backup-2025-11-10-0915.tar.gz: OK
