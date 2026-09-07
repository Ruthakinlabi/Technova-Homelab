#!/bin/bash

# Chapter 3, Task 3 — Automated SSH Key Provisioning
# Generates and installs an SSH key pair for every eligible employee
# who doesn't already have one. Skips locked/offboarded accounts and
# anyone already provisioned (Task 2's manual three, or a prior run
# of this script).

source "$(dirname "$0")/log_utils.sh"
init_log

# Accounts explicitly excluded from automated provisioning — not
# locked, but should never be touched by this script (e.g. the WSL
# host user itself, which isn't a TechNova employee).
EXCLUDE_USERS=("ruth1")

provisioned_count=0
skipped_existing_count=0
skipped_locked_count=0
skipped_excluded_count=0

is_excluded() {
    local username="$1"
    for excluded in "${EXCLUDE_USERS[@]}"; do
        if [ "$username" == "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

provision_employee_key() {
    local username="$1"
    local home_dir="/home/$username"
    local ssh_dir="$home_dir/.ssh"
    local key_file="$ssh_dir/id_ed25519"

    if is_excluded "$username"; then
        skipped_excluded_count=$((skipped_excluded_count + 1))
        return
    fi

    # Skip locked/offboarded accounts entirely — no reason to issue
    # SSH access to someone who can't log in at all.
    if sudo passwd -S "$username" 2>/dev/null | grep -q " L "; then
        echo "[SKIPPED] $username — account is locked/offboarded"
        log_event "provision_ssh_keys.sh" "SKIP" "$username — account is locked/offboarded"
        skipped_locked_count=$((skipped_locked_count + 1))
        return
    fi

    # Skip anyone who already has a key pair — from Task 2's manual
    # setup, or a previous run of this script. Never regenerate an
    # existing key; doing so would silently break working access.
    if sudo test -f "$key_file"; then
        echo "[SKIPPED] $username — key pair already exists"
        log_event "provision_ssh_keys.sh" "SKIP" "$username — key pair already exists"
        skipped_existing_count=$((skipped_existing_count + 1))
        return
    fi

    # Generate the key pair non-interactively:
    # -N "" sets an empty passphrase without prompting.
    # -f specifies the output file path directly, also without prompting.
    # -q suppresses the randomart/fingerprint output for a cleaner batch log.
    if sudo -u "$username" -H ssh-keygen -t ed25519 -C "${username}@technova.com" -N "" -f "$key_file" -q; then
        sudo -u "$username" -H bash -c "cat '$key_file.pub' >> '$ssh_dir/authorized_keys'"
        sudo chmod 700 "$ssh_dir"
        sudo chmod 600 "$ssh_dir/authorized_keys"
        sudo chmod 600 "$key_file"
        sudo chmod 644 "$key_file.pub"

        echo "[PROVISIONED] $username — key pair generated and installed"
        log_event "provision_ssh_keys.sh" "SUCCESS" "$username — key pair generated and installed"
        provisioned_count=$((provisioned_count + 1))
    else
        echo "[FAILED]      $username — ssh-keygen failed"
        log_event "provision_ssh_keys.sh" "FAILURE" "$username — ssh-keygen failed"
    fi
}

echo "Provisioning SSH keys for eligible employees ..."
echo "-----------------------------------"

for username in $(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}'); do
    provision_employee_key "$username"
done

echo "-----------------------------------"
echo "Provisioned: $provisioned_count"
echo "Skipped (already had a key): $skipped_existing_count"
echo "Skipped (locked/offboarded): $skipped_locked_count"
echo "Skipped (excluded): $skipped_excluded_count"
