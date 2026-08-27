#!/bin/bash

# Chapter 2, Task 4 — Automated Directory Updates
# Appends new hires to each department's responsibility_matrix.txt,
# under a clearly labeled automation section — never overwrites
# existing Chapter 1 entries.

INPUT_FILE="$1"
BATCH_DATE=$(date +%Y-%m-%d)

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

# Same department -> path mapping approach as provision_users.sh,
# but resolving to a directory path instead of a group name.
declare -A DEPT_TO_PATH=(
    ["Engineering"]="/srv/technova/departments/engineering"
    ["Sales"]="/srv/technova/departments/sales"
    ["Finance"]="/srv/technova/departments/finance"
    ["HR"]="/srv/technova/departments/hr"
    ["Marketing"]="/srv/technova/departments/marketing"
    ["CustomerSupport"]="/srv/technova/departments/CustomerSupport"
    ["ProductMgt"]="/srv/technova/departments/productmgt"
    ["DevOps"]="/srv/technova/departments/devops"
)

updated_count=0
skipped_count=0

# Tracks which departments have already had the section header written
# during this run, so it's only added once per file, not once per employee.
declare -A HEADER_WRITTEN

update_employee_matrix() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local dept_path="${DEPT_TO_PATH[$department]}"

    if [ -z "$dept_path" ]; then
        echo "[SKIPPED] $full_name — no path mapping found for department '$department'"
        log_event "update_matrices.sh" "SKIP" "$full_name — no path mapping found for department '$department'"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local matrix_file="$dept_path/responsibility_matrix.txt"

    if ! sudo test -f "$matrix_file"; then
        echo "[SKIPPED] $full_name — responsibility_matrix.txt not found for $department"
        log_event "update_matrices.sh" "SKIP" "$full_name — responsibility_matrix.txt not found for $department"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if [ -z "${HEADER_WRITTEN[$department]}" ]; then
        sudo bash -c "echo '' >> '$matrix_file'"
        sudo bash -c "echo '--- Auto-Onboarded Employees (Batch: $BATCH_DATE) ---' >> '$matrix_file'"
        HEADER_WRITTEN[$department]=1
    fi

    if sudo bash -c "echo '$full_name — $role' >> '$matrix_file'"; then
        echo "[UPDATED] $full_name — $department — $role"
        log_event "update_matrices.sh" "SUCCESS" "$full_name — $department — $role"
        updated_count=$((updated_count + 1))
    else
        echo "[FAILED]  $full_name — could not write to $matrix_file"
        log_event "update_matrices.sh" "FAILURE" "$full_name — could not write to $matrix_file"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Updating responsibility matrices from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    update_employee_matrix "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Matrices updated: $updated_count"
echo "Skipped: $skipped_count"
