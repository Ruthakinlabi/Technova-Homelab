#!/bin/bash
source "$(dirname "$0")/log_utils.sh"
init_log
log_event "test_log.sh" "SUCCESS" "This is a test entry"
log_event "test_log.sh" "SKIP" "This is a test skip"
echo "Test entries written. Check scripts/data/onboarding_log.txt"
