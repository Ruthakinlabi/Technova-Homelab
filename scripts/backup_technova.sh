#!/bin/bash

# Chapter 4, Task 3 — Automated Daily Backup
# Backs up everything identified as in-scope in Task 1.

BACKUP_DIR="/srv/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/technova_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
  /srv/technova/departments \
  /srv/technova/archived_employees \
  /etc/ssh/sshd_config \
  /etc/ssh/sshd_config.bak \
  /etc/fail2ban/jail.local

echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup created: $BACKUP_FILE" >> "$BACKUP_DIR/backup_log.txt"
