#!/bin/bash

# Chapter 2, Task 2 — Automated User Provisioning
# Reads valid_hires.csv and creates a Linux account for each employee.

INPUT_FILE="$1"

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

# Maps each CSV department name to its actual Linux group name.
# Kept explicit (not auto-lowercased) because group names in this
# system aren't perfectly uniform (e.g. CustomerSupport keeps its casing).
declare -A DEPT_TO_GROUP=(
    ["Engineering"]="engineering"
    ["Sales"]="sales"
    ["Finance"]="finance"
    ["HR"]="hr"
    ["Marketing"]="marketing"
    ["CustomerSupport"]="CustomerSupport"
    ["ProductMgt"]="productmgt"
    ["DevOps"]="devops"
)

created_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')

    local first_initial="${first_name:0:1}"
    local username
    username=$(echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]')
    echo "$username"
}
create_employee_account() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local username
    username=$(generate_username "$full_name")

    # Check for an existing account with this username first —
    # skip rather than error out, so one conflict doesn't halt the batch.
    if id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — username already exists"
        log_event "provision_users.sh" "SKIP" "$full_name ($username) — username already exists"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local group="${DEPT_TO_GROUP[$department]}"

    if [ -z "$group" ]; then
        echo "[SKIPPED] $full_name — no group mapping found for department '$department'"
        log_event "provision_users.sh" "SKIP" "$full_name — no group mapping found for department '$department'"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if sudo useradd -m -s /bin/bash -g "$group" -c "$full_name" "$username" 2>/dev/null; then
        echo "[CREATED] $full_name — username: $username — department: $department — role: $role"
        log_event "provision_users.sh" "SUCCESS" "$full_name — username: $username — department: $department — role: $role"
        created_count=$((created_count + 1))
    else
        echo "[FAILED]  $full_name ($username) — useradd command failed"
        log_event "provision_users.sh" "FAILURE" "$full_name ($username) — useradd command failed"
        skipped_count=$((skipped_count + 1))
    fi
}

# Using process substitution (< <(...)) instead of a pipe here —
# this keeps the while loop running in the CURRENT shell, not a
# subshell, so created_count/skipped_count actually persist after
# the loop ends. This is the fix for Task 1's subshell limitation.
while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    create_employee_account "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Accounts created: $created_count"
echo "Accounts skipped: $skipped_count"
