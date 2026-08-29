#!/bin/bash

# Chapter 2, Task 7 — Automated Welcome Email Simulation
# Generates a personalized welcome message file for each new hire.

INPUT_FILE="$1"
MESSAGES_DIR="$(dirname "$INPUT_FILE")/welcome_messages"

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

mkdir -p "$MESSAGES_DIR"

generated_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')
    local first_initial="${first_name:0:1}"
    echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]'
}

generate_welcome_message() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local username
    username=$(generate_username "$full_name")

    # Only generate a message for employees who actually have an
    # account on the system — otherwise we'd be "welcoming" someone
    # whose provisioning was skipped or failed upstream.

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — no account exists, skipping welcome message"
        log_event "generate_welcome_messages.sh" "SKIP" "$full_name ($username) — no account exists"
        skipped_count=$((skipped_count + 1))
        return
    fi

    # Skip locked/offboarded accounts — no reason to "welcome" someone
    # whose access has already been revoked.
    if sudo passwd -S "$username" 2>/dev/null | grep -q " L "; then
        echo "[SKIPPED] $full_name ($username) — account is locked/offboarded"
        log_event "generate_welcome_messages.sh" "SKIP" "$full_name ($username) — account is locked/offboarded"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local message_file="$MESSAGES_DIR/${username}_welcome.txt"

    cat > "$message_file" << EOF
Subject: Welcome to TechNova Solutions Ltd., $full_name!

Hi $full_name,

Welcome to the $department team at TechNova Solutions Ltd.! We're glad
to have you on board as our new $role.

YOUR LOGIN DETAILS
-------------------
Username: $username
Temporary Password: (shared with you separately by IT — see your
department administrator if you have not received it)

IMPORTANT: You are required to change your password immediately the
first time you log in. The system will prompt you automatically.

FIRST-DAY CHECKLIST
--------------------
- Log in and set your new password
- Read your department handbook (ask your administrator for access)
- Introduce yourself on your team's communication channel
- Confirm your workstation/account access with your administrator

If you run into any issues logging in, contact IT support.

Welcome aboard!
TechNova Solutions Ltd. — IT Onboarding
EOF

    if [ -f "$message_file" ]; then
        echo "[GENERATED] $full_name — welcome message saved to $message_file"
        log_event "generate_welcome_messages.sh" "SUCCESS" "$full_name ($username) — welcome message generated"
        generated_count=$((generated_count + 1))
    else
        echo "[FAILED]    $full_name — could not write welcome message"
        log_event "generate_welcome_messages.sh" "FAILURE" "$full_name ($username) — could not write welcome message"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Generating welcome messages from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    generate_welcome_message "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Messages generated: $generated_count"
echo "Skipped: $skipped_count"
echo "Saved to: $MESSAGES_DIR"
