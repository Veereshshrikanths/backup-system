# Automated Backup System – Bash Script


* Create compressed `.tar.gz` backups of any folder
* Automatically skip unwanted folders like `.git`, `node_modules`, `.cache`, etc.
* Generate checksum files to verify backup integrity
* Automatically delete old backups based on a daily, weekly, and monthly retention policy
* Prevent multiple script executions at the same time
* Provide detailed logging of everything the script does
* Test the system without making changes using `--dry-run` mode
* Restore backups and list existing backups

### Why is it useful?

This script provides a reliable backup process for users or systems without expensive commercial backup tools. It ensures:

* No corrupted backup goes unnoticed
* Disk space is managed automatically
* Every run is fully traceable in a log file
* It can run unattended via cron jobs

## B. How to Use It

### Prerequisites

You need:
## B. How to Use It

### Prerequisites

### Example `backup.config`

```
BACKUP_DESTINATION=/home/veeresh/backups
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
EMAIL_NOTIFICATION=none
```

### 2. Basic Usage Examples

#### Create a backup

```bash
./backup.sh /home/user/documents
```

#### Dry run (no changes made)

```bash
./backup.sh --dry-run /home/user/documents
```

#### Verify a backup

```bash
./backup.sh verify /home/user/backups/backup-2025-01-10-1200.tar.gz
```

#### List all backups

```bash
./backup.sh --list
```

#### Restore a backup

```bash
./backup.sh --restore /home/user/backups/backup-2025-01-10-1200.tar.gz --to /home/user/restore
```

### 3. Command Options

 Command                                                

 `./backup.sh <folder>`           - Creates a backup                       
 `--dry-run`                      - Shows actions without executing       
 `verify <file>`                  - Ensures backup is valid                
 `--list`                         - Shows existing backups                 
 `--restore <file> --to <folder>` - Restores a backup                      

---

## C. How It Works

### 1. Backup Creation

* All selected files are packed into a `.tar.gz` archive.
* A checksum (`.md5`) file is generated to detect corruption.
* Logs record every step.

### 2. Backup Verification

Verification does two things:

1. Re-runs `md5sum` and checks if the checksum matches
2. Extracts a single file into a temporary folder and tests integrity

If either fails, the script reports an error.

### 3. Backup Rotation (Retention Logic)

Every backup is categorized by age:

* Last 7 backups = **daily**
* Next 4 backups = **weekly**
* Next 3 backups = **monthly**

Algorithm:

1. List all backups
2. Convert each backup filename’s date to a timestamp
3. Measure age in days
4. Classify:

```
0–6 days old   → daily
7–27 days old  → weekly
28+ days       → monthly
```

5. If category has more than allowed:

* Sort files oldest first
* Delete the extra backups

### 4. Folder Structure

Backups are stored like:

```
/home/veeresh/backups/
 ├── backup-2025-01-10-1200.tar.gz
 ├── backup-2025-01-10-1200.tar.gz.md5
 ├── backup-2025-01-12-0800.tar.gz
 ├── backup.log
 └── email.txt (optional)
```

---

## D. Design Decisions

### Why this approach?

* **Simple and portable**: Runs on any Linux without extra tools.
* **Checksum verification** ensures no silent data corruption.
* **Dry-run mode** makes testing safe.
* **Retention policy** avoids filling up disks over time.
* **Lock file** prevents simultaneous runs that could corrupt backups.

### Challenges Faced

1. **Order of argument parsing**

   * If `verify` was checked too late, the script would treat it as a folder.
   * Solution: Command modes (`verify`, `--restore`, etc.) are processed before normal backup logic.

2. **Deleting correct backups**

   * Sorting by date needed careful parsing of the filename.
   * Solved using pattern matching and `date` conversion.

3. **Checksum reliability**

   * Must check both checksum and extraction test.

### How they were solved

* Modular functions
* Clear conditional processing
* Systematic logging for debugging

---

## E. Testing

### 1. Create a test directory

```bash
mkdir testdata
echo "Hello" > testdata/file1.txt
echo "Backup System" > testdata/file2.txt
```

### 2. Run a real backup

```bash
./backup.sh testdata
```

Output sample:

```text
[2025-01-10 12:00:01] INFO: Starting backup of testdata
[2025-01-10 12:00:02] SUCCESS: Backup created
[2025-01-10 12:00:03] SUCCESS: Backup verified successfully
```

### 3. Dry run test

```bash
./backup.sh --dry-run testdata
```

Example output:

```text
Would create archive testdata-2025-01-10.tar.gz
Would create checksum testdata-2025-01-10.md5
```

### 4. Fake multiple backups (simulate days)

```bash
touch -d "10 days ago" /home/veeresh/backups/backup-2025-01-01-0800.tar.gz
```

Run again and see old backups deleted.

### 5. Verification test

```bash
./backup.sh verify /home/veeresh/backups/backup-2025-01-10-1200.tar.gz
```

### 6. Restore test

```bash
mkdir restored
./backup.sh --restore /home/veeresh/backups/backup-2025-01-10-1200.tar.gz --to restored
7. Error Handling Tests

Test: Missing folder
Command: ./backup.sh /no/such/folder
Expected result: Error message

Test: No config
Command: Rename or remove backup.config and run script
Expected result: Script exits with an informative error

Test: No space
Command: Simulate by filling the destination disk (or mock)
Expected result: Backup aborted with disk-space warning

Test: Run twice
Command: Launch the script twice concurrently
Expected result: Second run blocked by lockfile (/tmp/backup.lock)

---

## F. Known Limitations

* Incremental backups not yet supported.
* Restore always extracts the full archive (no single-file restore).
* Backup rotation depends on consistent filename format.
* Email is simulated (written to `email.txt` instead of SMTP).
* Not tested on macOS (GNU `date` required).

---

## Conclusion

This script provides a reliable, automated, and safe backup system using only Bash. It includes:

 - Solid error handling
 - Verification to prevent silent corruption
 - Automatic cleanup policies
 - Logging and test modes

It is suitable for personal systems, servers, student projects, and small business setups.
