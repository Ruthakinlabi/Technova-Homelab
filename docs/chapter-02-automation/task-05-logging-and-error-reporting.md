# Chapter 2, Task 5 — Logging and Error Reporting

## Business Requirement

Tasks 1 through 4 each printed their own results to the screen — useful in the moment, but gone the second the terminal is closed. TechNova's IT policy requires every onboarding run to produce a persistent, timestamped log recording what succeeded, what failed, and why, so any run can be reviewed later without relying on scrollback or memory.

## Design — Shared Logging Utility

Rather than each script inventing its own logging format, a single shared file (`log_utils.sh`) defines two functions — `init_log` and `log_event` — that every other script `source`s and calls. This guarantees one consistent log format across the entire onboarding pipeline, the same "write once, reuse everywhere" principle behind Task 2's `create_employee_account()` function.

## The Script — `log_utils.sh`

```bash
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
```

## Code Explanation

- **`${BASH_SOURCE[0]}`** — a special Bash variable holding the path of the currently executing file, even when it's been `source`d into another script (unlike `$0`, which reports the *calling* script's name). This ensures the log directory resolves correctly no matter which script sources this file.
- **`init_log()`** — creates the log directory (`mkdir -p`, safe if it already exists) and the log file itself (`touch`, creates if missing, no-op if present) before any writes happen.
- **`log_event()`** — the shared logging function. Every call produces one line in the format `[timestamp] [script] [status] message`, giving every script in the pipeline the exact same structure.

## Standalone Test — `test_log.sh`

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ chmod +x ~/Technova-Homelab/scripts/test_log.sh
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/test_log.sh
Test entries written. Check scripts/data/onboarding_log.txt
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ cat scripts/data/onboarding_log.txt
[2026-08-27 15:53:04] [test_log.sh] [SUCCESS] This is a test entry
[2026-08-27 15:53:04] [test_log.sh] [SKIP] This is a test skip
```
✅ Correct format confirmed before touching any of the real scripts.

## Wiring Into `provision_users.sh`, `set_passwords.sh`, `update_matrices.sh`

Each script received two additions:
1. `source "$(dirname "$0")/log_utils.sh"` and `init_log`, added near the top.
2. One `log_event` call added alongside every existing `echo` in each script's core function, matching the same SUCCESS/SKIP/FAILURE outcome already being printed.

## Bug 1 — Duplicated Code Block

While retrofitting `provision_users.sh`, the `if id "$username" &>/dev/null; then ... fi` block was accidentally duplicated — the `log_event` line got pasted as a second, separate block instead of being added into the existing one. This wasn't dangerous (the first block would `return` before the second ever ran), but it meant the `log_event` call in the unreachable second copy would never actually execute. **Fixed** by deleting the duplicate and keeping a single, correct block with the `log_event` call properly included.

## Bug 2 — Stray Annotation Text Pasted Into the Script

A more serious issue was caught during review: the actual script file contained literal text that was never valid Bash —

```bash
source "$(dirname "$0")/log_utils.sh"     ← these two lines, right here
init_log                                   ← this is correct placement
```

The `← these two lines, right here` / `← this is correct placement` annotations (originally just explanatory notes in chat, pointing at where to place the code) had been copy-pasted directly into the script file itself. `source` happened to tolerate the trailing text without crashing, but this was fragile and unintentional — the kind of stray text that could break a script badly in a less forgiving spot. **Fixed** by removing the annotation text, leaving only the two valid lines:
```bash
source "$(dirname "$0")/log_utils.sh"
init_log
```

Confirmed clean afterward via `cat scripts/provision_users.sh`, showing the corrected two-line block with no extraneous text.

## End-to-End Test — All Three Scripts, Shared Log

**Test CSV (`test_task5.csv`):**
```
full_name,department,role
Testson Oneperson,Engineering,Test Role
Testdaughter Twoperson,Sales,Test Role
```

**Provisioning:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/provision_users.sh scripts/data/test_task5.csv
[sudo] password for ruth1:
[CREATED] Testson Oneperson — username: toneperson — department: Engineering — role: Test Role
[CREATED] Testdaughter Twoperson — username: ttwoperson — department: Sales — role: Test Role
-----------------------------------
Accounts created: 2
Accounts skipped: 0
```

**Password setting:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/set_passwords.sh scripts/data/test_task5.csv
Setting passwords for employees in scripts/data/test_task5.csv ...
-----------------------------------
[SET]     Testson Oneperson — username: toneperson — password expired, must change at login
[SET]     Testdaughter Twoperson — username: ttwoperson — password expired, must change at login
-----------------------------------
Passwords set: 2
Skipped: 0
Credentials log saved and secured (600) at: scripts/data/credentials_log.txt
```

**Matrix update:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/update_matrices.sh scripts/data/test_task5.csv
Updating responsibility matrices from scripts/data/test_task5.csv ...
-----------------------------------
[UPDATED] Testson Oneperson — Engineering — Test Role
[UPDATED] Testdaughter Twoperson — Sales — Test Role
-----------------------------------
Matrices updated: 2
Skipped: 0
```

**Shared log — confirms all three scripts logged correctly to one file:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ cat scripts/data/onboarding_log.txt
[2026-08-27 15:53:04] [test_log.sh] [SUCCESS] This is a test entry
[2026-08-27 15:53:04] [test_log.sh] [SKIP] This is a test skip
[2026-08-27 16:09:28] [provision_users.sh] [SUCCESS] Testson Oneperson — username: toneperson — department: Engineering — role: Test Role
[2026-08-27 16:09:31] [provision_users.sh] [SUCCESS] Testdaughter Twoperson — username: ttwoperson — department: Sales — role: Test Role
[2026-08-27 16:09:40] [set_passwords.sh] [SUCCESS] Testson Oneperson — username: toneperson — password expired, must change at login
[2026-08-27 16:09:40] [set_passwords.sh] [SUCCESS] Testdaughter Twoperson — username: ttwoperson — password expired, must change at login
[2026-08-27 16:09:47] [update_matrices.sh] [SUCCESS] Testson Oneperson — Engineering — Test Role
[2026-08-27 16:09:47] [update_matrices.sh] [SUCCESS] Testdaughter Twoperson — Sales — Test Role
```
✅ All three scripts wrote to the same `onboarding_log.txt`, each entry correctly tagged with its own script name, a consistent timestamp format, and the same message content already shown on screen — confirming the shared logging design works as intended across the whole pipeline, not just in isolation.

## Cleanup

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo userdel -r toneperson
userdel: toneperson mail spool (/var/mail/toneperson) not found
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo userdel -r ttwoperson
userdel: ttwoperson mail spool (/var/mail/ttwoperson) not found
```
Expected, harmless message (WSL has no local mail system) — test accounts and home directories removed successfully.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Shared log function produces consistent format | `[timestamp] [script] [status] message` | ✅ Pass |
| `provision_users.sh` logs correctly | 2/2 entries captured | ✅ Pass |
| `set_passwords.sh` logs correctly | 2/2 entries captured | ✅ Pass |
| `update_matrices.sh` logs correctly | 2/2 entries captured | ✅ Pass |
| All three scripts write to the same log file | Confirmed via single `cat` | ✅ Pass |
| Duplicated code block bug found and fixed | `provision_users.sh` | ✅ Fixed |
| Stray annotation text found and fixed | `provision_users.sh` | ✅ Fixed |
| Test accounts cleaned up after verification | `userdel -r` x2 | ✅ Pass |

## Errors Encountered — Summary

1. **Duplicated `if id "$username"` block** in `provision_users.sh` — the `log_event` addition was pasted as a new block instead of edited into the existing one; the unreachable duplicate meant logging would never have actually fired. Fixed by removing the duplicate.
2. **Stray chat annotation text pasted into the script** — explanatory arrows (`←...`) meant only for the chat conversation ended up copied directly into `provision_users.sh`. Tolerated by `source` without crashing, but fragile and unintentional. Fixed by removing the annotation text.

## Status

**✅ Completed**

Shared logging utility (`log_utils.sh`) built and wired into all three existing onboarding scripts. Two real bugs caught and fixed during integration (duplicated logic block, stray pasted annotation text). End-to-end test across all three scripts confirmed every stage of onboarding now writes consistently to a single, timestamped, persistent log file.
