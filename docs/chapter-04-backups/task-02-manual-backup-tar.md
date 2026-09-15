# Chapter 4, Task 2 — Doing a Backup Manually

## Business Requirements

Now that we've decided what needs backing up (Task 1), it's time to actually do it — by hand, once, before we let anything run automatically. This is the same idea as learning to change a tire yourself before trusting a machine to do it for you. If something ever goes wrong with an automatic version later, you need to actually understand what it's supposed to be doing.

The tool used here is called `tar`. All it really does is take a bunch of files and folders and squash them into one single file — optionally made smaller through compression. That one file becomes "the backup."

## Step 1: Create a place for the backup to live

```bash
sudo mkdir -p /srv/backups
```

This creates a new folder specifically for backups, separate from the real, everyday company files.

## Step 2: A Small Mistake, and Why It Happened

The very first attempt to run the backup command failed:

```
tar: Cowardly refusing to create an empty archive
```

**In plain terms:** the command was typed across several lines (using a `\` symbol to say "continue on the next line"), but the first attempt accidentally sent just the first line on its own — before any of the actual folders to back up had been included. `tar` was essentially being asked to "create a backup of nothing," and it sensibly refused instead of quietly creating a useless, empty file. This wasn't a bug — it's `tar` protecting against a genuinely pointless action. The fix was simply retyping the full command, all in one go.

## Step 3: Running the Real Backup

```bash
sudo tar -czvf /srv/backups/technova_backup_$(date +%Y-%m-%d).tar.gz \
  /srv/technova/departments \
  /srv/technova/archived_employees \
  /etc/ssh/sshd_config \
  /etc/ssh/sshd_config.bak \
  /etc/fail2ban/jail.local
```

**What each part means, in plain terms:**
- `tar` — the tool doing the work.
- `-c` — "create" a new backup.
- `-z` — compress it, so it takes up less space.
- `-v` — show every single file as it gets added, so you can watch it happen instead of it running silently.
- `-f /srv/backups/technova_backup_...` — the name of the backup file being created.
- `$(date +%Y-%m-%d)` — automatically inserts today's date into the filename, so every day gets its own backup instead of overwriting yesterday's.
- Everything after that — the actual list of folders and files decided on in Task 1.

This ran successfully and listed out every single file it added — every department folder, every archived former employee, and the SSH/security configuration files — confirming the backup captured exactly what was planned.

## Step 4: Checking What's Actually Inside the Backup

```bash
tar -tzvf /srv/backups/technova_backup_2026-09-15.tar.gz
```

This doesn't open or change anything — it just lists what's inside the backup file, so you can double-check it without touching the original files at all.

The listing confirmed everything expected was captured: all department folders (Finance, Sales, HR, Marketing, Engineering, DevOps, Product Management, Customer Support), all five archived former employees, and the SSH and Fail2Ban configuration files.

## Step 5: Confirming the Backup File Itself

```bash
ls -lh /srv/backups/
```

```
-rw-r--r-- 1 root root 29K Sep 15 02:54 technova_backup_2026-09-15.tar.gz
```

**In plain terms:** one single file, 29 kilobytes in size (very small — text files compress extremely well), dated today. This one file now contains a complete, compressed copy of everything decided on in Task 1.

## What We Learned From the Small Mistake

`tar` refusing to create an empty backup is actually a helpful safety feature, not an annoyance. In a real company, a script that silently created empty, useless "backups" every night — with nobody ever checking — could go unnoticed for months, giving a false sense of safety right up until the day someone actually needed to restore something and discovered there was nothing there. This small error is a preview of a bigger idea for later in this chapter: **a backup that isn't checked isn't really a backup, it's just an assumption.**

## Status

**✅ Completed**

A full manual backup was successfully created and verified, containing every item identified in Task 1's scope: department data, archived former employees, and SSH/security configuration files. One small mistake occurred (an incomplete command) and was immediately understood and corrected — no data was lost or missed as a result.

Ready for **Task 3 — Automating Backups with Cron**.
