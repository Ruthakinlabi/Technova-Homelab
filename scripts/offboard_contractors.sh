#!/bin/bash

# Chapter 2, Task 6 — Bulk Offboarding
# Locks accounts, expires passwords, and archives home directories
# for a batch of departing contractors.

INPUT_FILE="$1"
ARCHIVE_DIR="/srv/technova/archived_employees"

source "$(dirname "$0")/log_utils.sh"
init_log

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-contractors-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

OUTPUT_DIR="$(dirname "$INPUT_FILE")"
REPORT_FILE="$OUTPUT_DIR/offboarding_report.txt"
BATCH_DATE=$(date '+%Y-%m-%d')

echo "" >> "$REPORT_FILE"
echo "Offboarding Report — Batch: $BATCH_DATE" >> "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"

offboarded_count=0
skipped_count=0

offboard_employee() {
    local username="$1"
    local full_name="$2"
    local department="$3"
    local reason="$4"

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — account does not exist"
        log_event "offboard_contractors.sh" "SKIP" "$full_name ($username) — account does not exist"
        echo "SKIPPED — $full_name ($username) — account does not exist" >> "$REPORT_FILE"
        skipped_count=$((skipped_count + 1))
        return
    fi

    # Lock the account — primary control, disables the password hash.
    sudo usermod -L "$username"

    # Expire the password — secondary safety net, same layered-defense
    # reasoning as Chapter 1 Task 9.
    sudo passwd -e "$username" &>/dev/null

    # Archive the home directory: compress into a single file, move
    # out of the active /home directory, then remove the original.
    local home_dir="/home/$username"
    local archive_name="${username}_$(date +%Y%m%d).tar.gz"

    if sudo test -d "$home_dir"; then
        sudo tar -czf "$ARCHIVE_DIR/$archive_name" -C /home "$username" 2>/dev/null
        if [ -f "$ARCHIVE_DIR/$archive_name" ]; then
            sudo rm -rf "$home_dir"
            echo "[OFFBOARDED] $full_name ($username) — $department — locked, expired, archived to $archive_name"
            log_event "offboard_contractors.sh" "SUCCESS" "$full_name ($username) — $department — reason: $reason — archived to $archive_name"
            echo "OFFBOARDED — $full_name ($username) — $department — reason: $reason — archive: $archive_name" >> "$REPORT_FILE"
            offboarded_count=$((offboarded_count + 1))
        else
            echo "[FAILED]  $full_name ($username) — archive creation failed"
            log_event "offboard_contractors.sh" "FAILURE" "$full_name ($username) — archive creation failed"
            echo "FAILED — $full_name ($username) — archive creation failed" >> "$REPORT_FILE"
            skipped_count=$((skipped_count + 1))
        fi
    else
        echo "[FAILED]  $full_name ($username) — home directory not found"
        log_event "offboard_contractors.sh" "FAILURE" "$full_name ($username) — home directory not found"
        echo "FAILED — $full_name ($username) — home directory not found" >> "$REPORT_FILE"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Offboarding contractors from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r username full_name department reason; do
    username=$(echo "$username" | xargs)
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    reason=$(echo "$reason" | xargs)

    offboard_employee "$username" "$full_name" "$department" "$reason"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Offboarded: $offboarded_count"
echo "Skipped: $skipped_count"
echo "Report saved to: $REPORT_FILE"

echo "-----------------------------------" >> "$REPORT_FILE"
echo "Total offboarded: $offboarded_count" >> "$REPORT_FILE"
echo "Total skipped: $skipped_count" >> "$REPORT_FILE"

sudo chmod 600 "$REPORT_FILE"
