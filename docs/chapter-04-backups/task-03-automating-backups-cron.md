# Chapter 4, Task 3 — Making Backups Happen Automatically

## The Situation, In Plain Terms

Task 2 proved a backup can be made correctly by hand. But "by hand" has one obvious weakness: it only happens if a person remembers to actually do it, every single day, forever. Real companies don't rely on someone remembering — they let the computer do it on a schedule, whether anyone is around or not.

The tool for this is called **cron**. Think of it as a built-in alarm clock for the computer — except instead of making a sound, it runs a command at whatever time you tell it to.

## Step 1: Turning the Backup Into a Proper Script

```bash
nano ~/Technova-Homelab/scripts/backup_technova.sh
```

```bash
#!/bin/bash

# Chapter 4, Task 3 — Automated Daily Backup
# Backs up everything identified as in-scope in Task 1.

BACKUP_DIR="/srv/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/technova_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
  /srv/technova/departments \
  /srv/technova/archived_employees \
  /etc/ssh/sshd_config \
  /etc/ssh/sshd_config.bak \
  /etc/fail2ban/jail.local

echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup created: $BACKUP_FILE" >> "$BACKUP_DIR/backup_log.txt"
```

**In plain terms:** this is the same backup command from Task 2, just turned into a script and made quieter (no on-screen output, since nobody will be watching it run at 2 AM), with one addition — every time it runs, it writes a short note into a log file recording exactly when it ran and what it created. Since nobody's watching, this log is the only proof it actually happened.

```bash
chmod +x ~/Technova-Homelab/scripts/backup_technova.sh
```

## Step 2: Testing It Manually First

```bash
sudo ~/Technova-Homelab/scripts/backup_technova.sh
```

```
tar: Removing leading `/' from member names
tar: Removing leading `/' from hard link targets
```

These two lines are just informational notices from `tar` — not errors. They simply mean `tar` is storing the file paths in a slightly adjusted way internally; this is completely normal and doesn't affect the backup at all.

```bash
cat /srv/backups/backup_log.txt
```
```
2026-09-16 04:06:22 - Backup created: /srv/backups/technova_backup_2026-09-16.tar.gz
```
✅ Confirms the script itself works correctly when run by hand, before trusting cron with it.

## Step 3: Scheduling It With Cron

```bash
sudo crontab -e
```

Added this line:
```
0 2 * * * /home/ruth1/Technova-Homelab/scripts/backup_technova.sh
```

**In plain terms:** cron reads five values before the actual command — minute, hour, day of month, month, and day of week. A `*` means "any/every." So `0 2 * * *` means: **"At minute 0 of hour 2 — exactly 2:00 AM — every single day, regardless of the date or day of the week."**

## Errors Encountered — Confirming the Schedule Actually Saved

**First attempt to check the schedule came back empty:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo crontab -l
...
# m h  dom mon dow   command
```
No line was actually present after the comments — the very first edit hadn't actually saved the new line. This was caught by deliberately checking with `crontab -l` rather than assuming the edit worked, and fixed by reopening `crontab -e` and confirming the line was typed and saved properly this time.

## Step 4: Proving It Actually Runs on Its Own

Since waiting until the real 2:00 AM schedule wasn't practical to observe directly, the schedule was **temporarily** changed to run a couple of minutes ahead of the current time, to watch it fire on its own.

**First timing mistake:**
```
ruth1@DESKTOP-DD7VGNC:~$ date
Wed Sep 16 04:13:05 PDT 2026
```
The crontab had been set to `2 2 * * *` (2:02 AM) — but the actual current time was already **04:13 AM**, meaning that scheduled time had already passed hours earlier that same day. Waiting a few minutes at that point would never have shown anything happening, since cron wouldn't fire again until 2:02 AM the *next* day. This was caught by checking the real current time with `date` before assuming the test would work — a good habit confirmed here: always check the actual current time before setting a "run soon" test.

**Corrected timing:**
```
ruth1@DESKTOP-DD7VGNC:~$ date
Wed Sep 16 04:11:07 PDT 2026
...
sudo crontab -l
...
16 4 * * * /home/ruth1/Technova-Homelab/scripts/backup_technova.sh
```
Reset to `16 4 * * *` (4:16 AM), correctly just a few minutes ahead of the real current time this time.

**Checked too early — nothing new yet:**
```
ruth1@DESKTOP-DD7VGNC:~$ date
Wed Sep 16 04:14:28 PDT 2026
ruth1@DESKTOP-DD7VGNC:~$ cat /srv/backups/backup_log.txt
2026-09-16 04:06:22 - Backup created: /srv/backups/technova_backup_2026-09-16.tar.gz
```
Checked at 04:14:28 — still two minutes before the scheduled 04:16 time, so correctly nothing new had happened yet. This wasn't a failure, just checking before the scheduled moment arrived.

**Waited properly, then checked again:**
```
ruth1@DESKTOP-DD7VGNC:~$ date
Wed Sep 16 04:15:54 PDT 2026
ruth1@DESKTOP-DD7VGNC:~$ cat /srv/backups/backup_log.txt
2026-09-16 04:06:22 - Backup created: /srv/backups/technova_backup_2026-09-16.tar.gz
2026-09-16 04:16:03 - Backup created: /srv/backups/technova_backup_2026-09-16.tar.gz
```
```
ruth1@DESKTOP-DD7VGNC:~$ ls -lh /srv/backups/
-rw-r--r-- 1 root root 170 Sep 16 04:16 backup_log.txt
-rw-r--r-- 1 root root  29K Sep 16 04:16 technova_backup_2026-09-16.tar.gz
```

✅ **This is the real proof.** A brand new line appeared in the log at exactly `04:16:03` — matching the scheduled time precisely — and the backup file's timestamp updated to match. Nobody typed the backup command themselves in that window. Cron ran it entirely on its own.

## Step 5: Restoring the Real Daily Schedule

```bash
sudo crontab -e
```

Changed back to:
```
0 2 * * * /home/ruth1/Technova-Homelab/scripts/backup_technova.sh
```

**Final confirmation:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo crontab -l
...
0 2 * * * /home/ruth1/Technova-Homelab/scripts/backup_technova.sh
```
✅ Confirmed correctly set back to the real production schedule: every day, at 2:00 AM.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Script runs correctly by hand | Backup + log entry created | ✅ Pass |
| Cron line actually saved | Present in `crontab -l` | ✅ Pass (after catching first empty save) |
| Cron fires at the correct scheduled time | New log entry appears unassisted | ✅ Pass, confirmed at 04:16:03 |
| No manual intervention during the test window | Nobody ran the script by hand during the wait | ✅ Confirmed |
| Real daily schedule restored afterward | `0 2 * * *` | ✅ Confirmed |

## What the Timing Mistakes Actually Taught

Both mix-ups here — the empty crontab save, and setting a test time that had already passed — are genuinely common first-time cron mistakes, not signs of doing anything wrong. The fix in both cases was the same underlying habit: **don't assume a schedule is correct — check it (`crontab -l`) and check the real current time (`date`) before trusting it to fire when expected.** That verify-before-trusting habit shows up again and again throughout this whole project, and cron is no exception.

## Status

**✅ Completed**

TechNova's backup now runs automatically every day at 2:00 AM, with no one needing to remember or trigger it manually. This was proven with a genuine live test — not just a scheduled line sitting untested — including two realistic timing mistakes that were caught and corrected along the way.
