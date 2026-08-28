# Chapter 2, Task 6 — Bulk Offboarding

## Business Requirement

Of the 70 people hired in this wave, five were brought on specifically as fixed-term contractors to support the product launch. Their contracts have now ended, and HR sent over the list. Manually running `usermod -L`, `passwd -e`, and an archive step five separate times is exactly the kind of repetition this chapter exists to eliminate.

## The Contractors

| Name | Username | Department | Reason |
|---|---|---|---|
| Femi Adebisi | fadebisi | Engineering | Contract ended |
| Kunle Fashola | kfashola | Engineering | Contract ended |
| Segun Oyelaran | soyelaran | Marketing | Contract ended |
| Zainab Lawal | zlawal | Marketing | Contract ended |
| Samuel Falade | sfalade | Marketing | Contract ended |

Real, already-active accounts from Tasks 1–5 — passwords set, home directories populated — giving the archiving step genuine data to work with.

## Why "Archive," Not "Leave It" or "Delete It"

Chapter 1's Task 9 preserved a single departing employee's home directory in place — fine for one person, not sustainable at scale. Archiving compresses the home directory into a single file, moved out of the active `/home` directory into dedicated storage: data fully preserved for audit or handover, but no longer sitting among active employees' files.

## The Script — `offboard_contractors.sh`

```bash
#!/bin/bash

# Chapter 2, Task 6 — Bulk Offboarding
# Locks accounts, expires passwords, and archives home directories
# for a batch of departing contractors.

INPUT_FILE="$1"
ARCHIVE_DIR="/srv/technova/archived_employees"

source "$(dirname "$0")/log_utils.sh"
init_log

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-contractors-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

OUTPUT_DIR="$(dirname "$INPUT_FILE")"
REPORT_FILE="$OUTPUT_DIR/offboarding_report.txt"
BATCH_DATE=$(date '+%Y-%m-%d')

echo "Offboarding Report — Batch: $BATCH_DATE" > "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"

offboarded_count=0
skipped_count=0

offboard_employee() {
    local username="$1"
    local full_name="$2"
    local department="$3"
    local reason="$4"

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — account does not exist"
        log_event "offboard_contractors.sh" "SKIP" "$full_name ($username) — account does not exist"
        echo "SKIPPED — $full_name ($username) — account does not exist" >> "$REPORT_FILE"
        skipped_count=$((skipped_count + 1))
        return
    fi

    sudo usermod -L "$username"
    sudo passwd -e "$username" &>/dev/null

    local home_dir="/home/$username"
    local archive_name="${username}_$(date +%Y%m%d).tar.gz"

    if sudo test -d "$home_dir"; then
        sudo tar -czf "$ARCHIVE_DIR/$archive_name" -C /home "$username" 2>/dev/null
        if [ -f "$ARCHIVE_DIR/$archive_name" ]; then
            sudo rm -rf "$home_dir"
            echo "[OFFBOARDED] $full_name ($username) — $department — locked, expired, archived to $archive_name"
            log_event "offboard_contractors.sh" "SUCCESS" "$full_name ($username) — $department — reason: $reason — archived to $archive_name"
            echo "OFFBOARDED — $full_name ($username) — $department — reason: $reason — archive: $archive_name" >> "$REPORT_FILE"
            offboarded_count=$((offboarded_count + 1))
        else
            echo "[FAILED]  $full_name ($username) — archive creation failed"
            log_event "offboard_contractors.sh" "FAILURE" "$full_name ($username) — archive creation failed"
            echo "FAILED — $full_name ($username) — archive creation failed" >> "$REPORT_FILE"
            skipped_count=$((skipped_count + 1))
        fi
    else
        echo "[FAILED]  $full_name ($username) — home directory not found"
        log_event "offboard_contractors.sh" "FAILURE" "$full_name ($username) — home directory not found"
        echo "FAILED — $full_name ($username) — home directory not found" >> "$REPORT_FILE"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Offboarding contractors from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r username full_name department reason; do
    username=$(echo "$username" | xargs)
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    reason=$(echo "$reason" | xargs)

    offboard_employee "$username" "$full_name" "$department" "$reason"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Offboarded: $offboarded_count"
echo "Skipped: $skipped_count"
echo "Report saved to: $REPORT_FILE"

echo "-----------------------------------" >> "$REPORT_FILE"
echo "Total offboarded: $offboarded_count" >> "$REPORT_FILE"
echo "Total skipped: $skipped_count" >> "$REPORT_FILE"

sudo chmod 600 "$REPORT_FILE"
```

## Code Explanation

- **`sudo tar -czf "$ARCHIVE_DIR/$archive_name" -C /home "$username"`** — `-c` create, `-z` gzip-compress, `-f` output filename. `-C /home` changes into `/home` before archiving, so the archived path is clean (`username/...`) rather than the full absolute path.
- **Archive filename includes the date** — avoids silently overwriting an existing archive in a hypothetical future rehire scenario.
- **Verification before deletion** — `sudo rm -rf "$home_dir"` only runs after confirming the archive file actually exists, so a failed `tar` can't result in data loss with no fallback.
- **`REPORT_FILE` locked to `600`** — same protection tier as `credentials_log.txt`, since it lists real departing employees and reasons.

## Test Run — One Contractor First

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/offboard_contractors.sh scripts/data/test_offboard.csv
Offboarding contractors from scripts/data/test_offboard.csv ...
-----------------------------------
[OFFBOARDED] Femi Adebisi (fadebisi) — Engineering — locked, expired, archived to fadebisi_20260827.tar.gz
[SKIPPED]  () — account does not exist
-----------------------------------
Offboarded: 1
Skipped: 1
Report saved to: scripts/data/offboarding_report.txt
```

**Note on the blank `[SKIPPED]  ()` line:** the test CSV had a trailing blank line after the one real data row, which the loop still attempted to process — an empty row correctly produced a skip rather than crashing, since `id ""` fails cleanly. Not a bug, but worth noting for Task 7 (Script Validation), which will need to test this exact kind of malformed-input scenario deliberately.

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S fadebisi
fadebisi L 1970-01-01 0 99999 7 -1
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l /srv/technova/archived_employees/
total 4
-rw-r--r-- 1 root root 2321 Aug 27 16:59 fadebisi_20260827.tar.gz
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls /home/ | grep fadebisi
```
✅ Locked, archived, home directory removed — no output from the `grep` confirms `fadebisi` is no longer in `/home`.

## Real Run — Remaining 4 Contractors

A separate CSV (`contractors_remaining.csv`) was used for the remaining four, since `fadebisi` had already been fully offboarded in the test — re-running him through the full 5-person list would have incorrectly reported a "home directory not found" failure for an employee who was actually processed successfully.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/offboard_contractors.sh scripts/data/contractors_remaining.csv
Offboarding contractors from scripts/data/contractors_remaining.csv ...
-----------------------------------
[OFFBOARDED] Kunle Fashola (kfashola) — Engineering — locked, expired, archived to kfashola_20260827.tar.gz
[OFFBOARDED] Segun Oyelaran (soyelaran) — Marketing — locked, expired, archived to soyelaran_20260827.tar.gz
[OFFBOARDED] Zainab Lawal (zlawal) — Marketing — locked, expired, archived to zlawal_20260827.tar.gz
[OFFBOARDED] Samuel Falade (sfalade) — Marketing — locked, expired, archived to sfalade_20260827.tar.gz
-----------------------------------
Offboarded: 4
Skipped: 0
Report saved to: scripts/data/offboarding_report.txt
```

## Error — `passwd -S` Does Not Accept Multiple Usernames

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S fadebisi kfashola soyelaran zlawal sfalade
Usage: passwd [options] [LOGIN]
...
```

Unlike `getent passwd`, which happily accepts multiple usernames in one call, `passwd -S` only accepts a single `[LOGIN]` argument — passing five usernames at once is invalid syntax, and `passwd` printed its full help text rather than a status. **Fix:** ran the check once per username instead:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S fadebisi
fadebisi L 1970-01-01 0 99999 7 -1
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S kfashola
kfashola L 1970-01-01 0 99999 7 -1
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S soyelaran
soyelaran L 1970-01-01 0 99999 7 -1
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S zlawal
zlawal L 1970-01-01 0 99999 7 -1
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S sfalade
sfalade L 1970-01-01 0 99999 7 -1
```
✅ All five confirmed locked (`L`).

## Verification — Archives and Home Directories

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l /srv/technova/archived_employees/
total 20
-rw-r--r-- 1 root root 2321 Aug 27 16:59 fadebisi_20260827.tar.gz
-rw-r--r-- 1 root root 2321 Aug 27 17:05 kfashola_20260827.tar.gz
-rw-r--r-- 1 root root 2319 Aug 27 17:05 sfalade_20260827.tar.gz
-rw-r--r-- 1 root root 2324 Aug 27 17:05 soyelaran_20260827.tar.gz
-rw-r--r-- 1 root root 2319 Aug 27 17:05 zlawal_20260827.tar.gz
```
✅ All five archives present.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls /home/ | grep -E "fadebisi|kfashola|soyelaran|zlawal|sfalade"
```
✅ No output — none of the five home directories remain in `/home`.

## Final Offboarding Report

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ cat scripts/data/offboarding_report.txt
Offboarding Report — Batch: 2026-08-27
-----------------------------------
OFFBOARDED — Kunle Fashola (kfashola) — Engineering — reason: Contract ended — archive: kfashola_20260827.tar.gz
OFFBOARDED — Segun Oyelaran (soyelaran) — Marketing — reason: Contract ended — archive: soyelaran_20260827.tar.gz
OFFBOARDED — Zainab Lawal (zlawal) — Marketing — reason: Contract ended — archive: zlawal_20260827.tar.gz
OFFBOARDED — Samuel Falade (sfalade) — Marketing — reason: Contract ended — archive: sfalade_20260827.tar.gz
-----------------------------------
Total offboarded: 4
Total skipped: 0
```

**Note:** because a fresh CSV was used for the second run, the report file only reflects the 4 people processed in that run — `fadebisi`'s successful offboarding from the earlier test only appears in the *first* report write (overwritten by the second run, since `REPORT_FILE` is reset with `>` at the start of each script execution). This is worth flagging as a minor design limitation: **the report reflects only the most recent run, not a cumulative record across multiple runs.** The shared `onboarding_log.txt` from Task 5, by contrast, *does* accumulate across runs (uses `>>` append), so the full history of all 5 offboardings is still recoverable from there even though the report file alone shows only 4.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Account locked | All 5 | ✅ Pass |
| Password expired | All 5 | ✅ Pass |
| Home directory archived (tar.gz created) | All 5 | ✅ Pass |
| Original home directory removed after archive confirmed | All 5 | ✅ Pass |
| Empty/malformed CSV row handled without crash | 1 blank row in test file | ✅ Pass |
| Offboarding report generated and secured (600) | Per-run | ✅ Pass (see note on non-cumulative report) |
| Shared log captures all 5 offboardings across both runs | `onboarding_log.txt` | ✅ Pass |

## Errors Encountered — Summary

1. **`passwd -S` does not accept multiple usernames** — attempted batch status check failed with a usage/help message; resolved by checking one username per command.
2. **Report file is overwritten per run, not cumulative** — a design limitation, not a bug: running the script in two separate batches (test + remaining 4) meant the final `offboarding_report.txt` only reflects the second run. The full record across both runs is still available in the shared `onboarding_log.txt`, which appends rather than overwrites.
3. **Blank trailing CSV row handled correctly** — produced a clean `[SKIPPED]` rather than a crash, confirming the existence-check logic degrades safely on malformed input.

## Status

**✅ Completed**

All 5 contractors (Femi Adebisi, Kunle Fashola, Segun Oyelaran, Zainab Lawal, Samuel Falade) successfully locked, password-expired, and archived to `/srv/technova/archived_employees/`, with home directories removed only after archive confirmation. Verified individually via `passwd -S`, archive directory listing, and confirmed absence from `/home`. One real script limitation identified (non-cumulative report file) and documented rather than silently left unnoticed.
