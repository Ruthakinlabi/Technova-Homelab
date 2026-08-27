#!/bin/bash

# Chapter 2, Task 3 — Initial Password Generation
# Applies a default temporary password to every employee created in Task 2,
# forces a password change at first login, and logs the action.

INPUT_FILE="$1"
DEFAULT_PASSWORD="Technova2026"

source "$(dirname "$0")/log_utils.sh"
init_log

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-valid-hires-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

OUTPUT_DIR="$(dirname "$INPUT_FILE")"
CREDENTIALS_LOG="$OUTPUT_DIR/credentials_log.txt"

echo "Credentials Log — $(date)" > "$CREDENTIALS_LOG"
echo "Default temporary password issued to all accounts below: $DEFAULT_PASSWORD" >> "$CREDENTIALS_LOG"
echo "All accounts require a password change at first login." >> "$CREDENTIALS_LOG"
echo "-----------------------------------" >> "$CREDENTIALS_LOG"

set_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')
    local first_initial="${first_name:0:1}"
    echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]'
}

set_employee_password() {
    local full_name="$1"
    local username="$2"

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — account does not exist"
        log_event "set_passwords.sh" "SKIP" "$full_name ($username) — account does not exist"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if echo "${username}:${DEFAULT_PASSWORD}" | sudo chpasswd 2>/dev/null; then
        sudo passwd -e "$username" &>/dev/null
        echo "[SET]     $full_name — username: $username — password expired, must change at login"
        log_event "set_passwords.sh" "SUCCESS" "$full_name — username: $username — password expired, must change at login"
        echo "$username — $full_name" >> "$CREDENTIALS_LOG"
        set_count=$((set_count + 1))
    else
        echo "[FAILED]  $full_name ($username) — chpasswd failed"
        log_event "set_passwords.sh" "FAILURE" "$full_name ($username) — chpasswd failed"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Setting passwords for employees in $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    username=$(generate_username "$full_name")

    set_employee_password "$full_name" "$username"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Passwords set: $set_count"
echo "Skipped: $skipped_count"

# Lock down the credentials log — admin-only, same tier as confidential.txt
sudo chmod 600 "$CREDENTIALS_LOG"
sudo chown "$(whoami):$(whoami)" "$CREDENTIALS_LOG" 2>/dev/null

echo "Credentials log saved and secured (600) at: $CREDENTIALS_LOG"
