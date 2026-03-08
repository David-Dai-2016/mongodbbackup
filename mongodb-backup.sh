#!/usr/bin/env bash
set -euo pipefail

# =========================
# Mongo backup configuration
# =========================
MONGO_URI="${MONGO_URI:?MONGO_URI is required}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/mongodb}"
LOG_FILE="${LOG_FILE:-/var/log/mongodb-backup.log}"

# Retention
DAILY_RETENTION_DAYS="${DAILY_RETENTION_DAYS:-7}"
WEEKLY_RETENTION_WEEKS="${WEEKLY_RETENTION_WEEKS:-5}"
MONTHLY_RETENTION_MONTHS="${MONTHLY_RETENTION_MONTHS:-12}"

# Backup scope:
# Leave empty to back up all databases
# Example:
# DATABASES=("appdb" "analytics")
DATABASES=()

# Optional: load DATABASES from env, comma-separated
# Example: DATABASES_CSV=appdb,analytics
if [ -n "${DATABASES_CSV:-}" ]; then
  IFS=',' read -r -a DATABASES <<< "$DATABASES_CSV"
fi

# Current time info
NOW="$(date +%F_%H-%M-%S)"
DAY_OF_WEEK="$(date +%u)"   # 1..7 (Mon..Sun)
DAY_OF_MONTH="$(date +%d)"  # 01..31

mkdir -p "$BACKUP_ROOT/daily" "$BACKUP_ROOT/weekly" "$BACKUP_ROOT/monthly"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

run_backup() {
  local target_dir="$1"
  local label="$2"

  mkdir -p "$target_dir"

  if [ ${#DATABASES[@]} -eq 0 ]; then
    local file="$target_dir/mongodb_${label}_${NOW}.archive.gz"
    log "Starting ${label} full backup: $file"
    mongodump \
      --uri="$MONGO_URI" \
      --archive="$file" \
      --gzip
    log "Finished ${label} full backup: $file"
  else
    for db in "${DATABASES[@]}"; do
      local file="$target_dir/${db}_${label}_${NOW}.archive.gz"
      log "Starting ${label} backup for database '$db': $file"
      mongodump \
        --uri="$MONGO_URI" \
        --db="$db" \
        --archive="$file" \
        --gzip
      log "Finished ${label} backup for database '$db': $file"
    done
  fi
}

cleanup_old_backups() {
  log "Cleaning old daily backups..."
  find "$BACKUP_ROOT/daily" -type f -name "*.archive.gz" -mtime +"$DAILY_RETENTION_DAYS" -delete

  log "Cleaning old weekly backups..."
  find "$BACKUP_ROOT/weekly" -type f -name "*.archive.gz" -mtime +"$((WEEKLY_RETENTION_WEEKS * 7))" -delete

  log "Cleaning old monthly backups..."
  find "$BACKUP_ROOT/monthly" -type f -name "*.archive.gz" -mtime +"$((MONTHLY_RETENTION_MONTHS * 31))" -delete
}

# Always create daily backup
run_backup "$BACKUP_ROOT/daily" "daily"

# Weekly backup every Sunday
if [ "$DAY_OF_WEEK" = "7" ]; then
  run_backup "$BACKUP_ROOT/weekly" "weekly"
fi

# Monthly backup on the 1st day of month
if [ "$DAY_OF_MONTH" = "01" ]; then
  run_backup "$BACKUP_ROOT/monthly" "monthly"
fi

cleanup_old_backups
log "Backup job completed successfully."