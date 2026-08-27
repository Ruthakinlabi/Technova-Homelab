#!/bin/bash

# Chapter 2, Task 5 — Shared Logging Utility
# Sourced by other scripts (not run directly) to provide a single,
# consistent logging format across the whole onboarding pipeline.

LOG_DIR="$(dirname "${BASH_SOURCE[0]}")/data"
LOG_FILE="$LOG_DIR/onboarding_log.txt"

# Ensures the log file exists before anything tries to write to it.
init_log() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
}

# log_event <SCRIPT_NAME> <STATUS> <MESSAGE>
# STATUS should be one of: SUCCESS, FAILURE, SKIP, INVALID
log_event() {
    local script_name="$1"
    local status="$2"
    local message="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$script_name] [$status] $message" >> "$LOG_FILE"
}
