# Task 7 — Responsibility Matrix

## Business Requirement

With handbooks (Task 5) and confidential records (Task 6) access-controlled, HR flagged a recurring gap: no single place shows who's responsible for what within a department. New hires and managers alike were asking "who owns this?" with no shared reference.

Each department now maintains a `responsibility_matrix.txt` — a living, jointly-maintained file mapping team members to their areas of responsibility. Unlike the handbook, it requires no review step: any department member can update it directly, since the cost of an outdated or slightly wrong entry is low, and gatekeeping would only slow the team down for no real security benefit.

## Design

| File | Admin | Members | Outsiders |
|---|---|---|---|
| `responsibility_matrix.txt` | read + write | read + write | none |

Same shape as `handbook_suggestions.txt` (`660`) — fully open within the department, blocked outside it. The difference is purpose, not permission: this file has no separate "official" version to merge into. Whatever the team maintains here is the record.

## Commands

```bash
sudo -u eadeyemi nano /srv/technova/departments/engineering/responsibility_matrix.txt
sudo -u goko nano /srv/technova/departments/sales/responsibility_matrix.txt
sudo -u dibr nano /srv/technova/departments/finance/responsibility_matrix.txt
sudo -u dojo nano /srv/technova/departments/hr/responsibility_matrix.txt
```

### Minor error — glob path didn't match

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l /srv/technova/departments/*/responsibility_matrix.txt
ls: cannot access '/srv/technova/departments/*/responsibility_matrix.txt': No such file or directory
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/*/responsibility_matrix.txt
ls: cannot access '/srv/technova/departments/*/responsibility_matrix.txt': No such file or directory
```

**Cause:** the plain user (`ruth1`) has no read/traverse access into the department directories, so shell glob expansion fails silently before `sudo` ever runs — `sudo` only affects the `ls` command itself, not the glob expansion that happens beforehand. Resolved by checking one explicit path at a time instead:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/engineering/responsibility_matrix.txt
-rw-r--r-- 1 eadeyemi engineering 524 Aug  6 08:30 /srv/technova/departments/engineering/responsibility_matrix.txt
```

## Set Permissions

```bash
sudo chmod 660 /srv/technova/departments/engineering/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/sales/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/finance/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/hr/responsibility_matrix.txt
```

## Test: Engineering Member Can Edit Directly

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - mogunleye
Password:
mogunleye@DESKTOP-DD7VGNC:~$ nano /srv/technova/departments/engineering/responsibility_matrix.txt
mogunleye@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ No permission error — `mogunleye` opened and edited the file directly, confirming full member read/write access (unlike Task 5's handbook, which explicitly blocked this).

## Test: Outsider Denied

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - sade
Password:
sade@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/responsibility_matrix.txt
cat: /srv/technova/departments/engineering/responsibility_matrix.txt: Permission denied
sade@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Sales employee correctly denied access to Engineering's responsibility matrix.

## Sales, Finance, HR

Same file created, same `660` permissions applied, same result pattern confirmed (member edits succeed, outsiders denied) — commands identical to Engineering with the respective admin/department substituted, omitted here for brevity.

## Verification Summary

| Test | Result |
|---|---|
| File created, owned by admin, correct department group | ✅ Pass |
| Member can read and write directly (no gatekeeping) | ✅ Pass (Engineering — mogunleye) |
| Outsider denied all access | ✅ Pass (Sales — sade, against Engineering) |

## Errors Encountered

1. **Glob (`*`) path resolution failed even with `sudo`** — `sudo` elevates the command being run, not the shell's own glob expansion that happens before the command executes. Resolved by targeting each department path explicitly.

## Why This Matters

This task is a deliberate contrast to Task 5: same department, same group, but a conscious decision that this file doesn't need a review gate — the cost of a wrong or outdated entry is low, and requiring admin approval for every small update would just create friction without meaningfully improving security. Recognizing when *not* to restrict is as much a part of access-control design as knowing when to.

## Status

**✅ Completed**

All four departments have a `responsibility_matrix.txt` with full member read/write access (`660`) and no outsider access. Verified directly for Engineering; same pattern applied and consistent across Sales, Finance, and HR.

Ready for **Task 8 — Shared Project Workspace**.
