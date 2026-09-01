#!/bin/bash

# Chapter 2, Addendum 1 — Deduplicate responsibility_matrix.txt files
# Removes duplicate "Auto-Onboarded Employees" sections/entries across
# all departments, keeping exactly one clean entry per employee.

DEPARTMENTS=(engineering sales finance hr marketing CustomerSupport productmgt devops)
BASE_DIR="/srv/technova/departments"
CLEAN_DATE=$(date +%Y-%m-%d)

for dept in "${DEPARTMENTS[@]}"; do
    file="$BASE_DIR/$dept/responsibility_matrix.txt"

    if ! sudo test -f "$file"; then
        echo "[SKIPPED] $dept — file not found"
        continue
    fi

    # Everything before the first "Auto-Onboarded" marker is the
    # original Chapter 1 content — kept exactly as-is, untouched.
    header=$(sudo awk '/--- Auto-Onboarded Employees/{exit} {print}' "$file")

    # Every "Name — Role" line from anywhere after the first marker,
    # across ALL repeated sections, deduplicated while preserving the
    # order each entry first appeared in.
    entries=$(sudo awk '/--- Auto-Onboarded Employees/{found=1; next} found && /—/{print}' "$file" | awk '!seen[$0]++')

    entry_count=$(echo "$entries" | grep -c "—")

    {
        echo "$header"
        echo ""
        echo "--- Auto-Onboarded Employees (Cleaned: $CLEAN_DATE) ---"
        echo "$entries"
    } | sudo tee "$file" > /dev/null

    echo "[CLEANED] $dept — $entry_count unique entries kept"
done
