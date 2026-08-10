#!/bin/bash

# Task 1 — Employee Data Source Validation
# Validates a CSV of new hires before any account creation occurs.
# Outputs: valid_hires.csv (clean data for Task 2) and invalid_hires_report.txt (for HR)

INPUT_FILE="$1"
VALID_DEPARTMENTS=("Engineering" "Sales" "Finance" "HR" "Marketing" "CustomerSupport" "ProductMgt" "DevOps")

OUTPUT_DIR="$(dirname "$INPUT_FILE")"
VALID_OUTPUT="$OUTPUT_DIR/valid_hires.csv"
INVALID_OUTPUT="$OUTPUT_DIR/invalid_hires_report.txt"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

# Start each output file fresh, with a header row on the valid CSV
echo "full_name,department,role" > "$VALID_OUTPUT"
echo "Invalid Records Report — $(date)" > "$INVALID_OUTPUT"
echo "-----------------------------------" >> "$INVALID_OUTPUT"

line_number=0

echo "Validating $INPUT_FILE ..."
echo "-----------------------------------"

tail -n +2 "$INPUT_FILE" | while IFS=',' read -r full_name department role; do
    line_number=$((line_number + 1))

    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    error=""

    if [ -z "$full_name" ]; then
        error="missing full_name"
    elif [ -z "$department" ]; then
        error="missing department"
    elif [ -z "$role" ]; then
        error="missing role"
    else
        dept_valid=false
        for d in "${VALID_DEPARTMENTS[@]}"; do
            if [ "$department" == "$d" ]; then
                dept_valid=true
                break
            fi
        done
        if [ "$dept_valid" == false ]; then
            error="invalid department '$department'"
        fi
    fi

    if [ -n "$error" ]; then
        echo "[INVALID] Row $((line_number + 1)): $error   (raw: $full_name,$department,$role)"
        echo "Row $((line_number + 1)): $error   (raw: $full_name,$department,$role)" >> "$INVALID_OUTPUT"
    else
        echo "[VALID]   Row $((line_number + 1)): $full_name — $department — $role"
        echo "$full_name,$department,$role" >> "$VALID_OUTPUT"
    fi
done

echo "-----------------------------------"
echo "Valid records saved to: $VALID_OUTPUT"
echo "Invalid records report saved to: $INVALID_OUTPUT"
