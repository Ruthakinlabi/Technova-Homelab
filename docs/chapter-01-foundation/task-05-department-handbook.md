# Task 5 — Department Handbook

## Business Requirement

With departmental workspaces now secured and properly isolated (Task 4), TechNova's HR department raised a new requirement.

New hires have been asking the same onboarding questions repeatedly — where to find department resources, who to contact for what, expected working hours, communication norms, and general workplace conduct. Answering these one-on-one is no longer sustainable as the company grows.

HR requested that every department maintain its own **handbook** — a living reference document containing workplace guidelines specific to that team.

After discussion, management raised a concern: if every department member can edit the handbook directly, there's no accountability for changes, and the document risks becoming inconsistent or accidentally damaged. Instead, TechNova adopted a lightweight **review-based workflow**, similar to a pull request in software development — team members can propose changes, but only the department administrator can apply them to the official handbook.

## Design

Each department has **two files**:

| File | Purpose | Admin | Members | Outsiders |
|---|---|---|---|---|
| `department_handbook.txt` | Official, authoritative handbook | read + write | read-only | none |
| `handbook_suggestions.txt` | Inbox for proposed edits | read + write | read + write | none |

Members write proposed changes into `handbook_suggestions.txt`. The administrator reviews these and manually merges accepted changes into `department_handbook.txt` — the same propose → review → merge principle as a real pull request, implemented here with Linux file permissions instead of Git.

## Note on File Creation Method

Two approaches achieve the same outcome:

1. `sudo -u <admin> touch <file>` — creates the file already owned by the admin in a single command (used in this task).
2. `sudo touch <file>` followed by `sudo chown <admin>:<dept> <file>` — creates the file as root, then reassigns ownership in a second step.

Approach 1 was used here since it accomplishes the same result in one command instead of two.

## Step 1 — Create Files and Set Permissions (all four departments)

```bash
sudo -u eadeyemi nano /srv/technova/departments/engineering/department_handbook.txt
sudo -u eadeyemi nano /srv/technova/departments/engineering/handbook_suggestions.txt
sudo chmod 640 /srv/technova/departments/engineering/department_handbook.txt
sudo chmod 660 /srv/technova/departments/engineering/handbook_suggestions.txt
```

```bash
sudo -u goko nano /srv/technova/departments/sales/department_handbook.txt
sudo -u goko nano /srv/technova/departments/sales/handbook_suggestions.txt
sudo chmod 640 /srv/technova/departments/sales/department_handbook.txt
sudo chmod 660 /srv/technova/departments/sales/handbook_suggestions.txt
```

```bash
sudo -u dibr nano /srv/technova/departments/finance/department_handbook.txt
sudo -u dibr nano /srv/technova/departments/finance/handbook_suggestions.txt
sudo chmod 640 /srv/technova/departments/finance/department_handbook.txt
sudo chmod 660 /srv/technova/departments/finance/handbook_suggestions.txt
```

```bash
sudo -u dojo nano /srv/technova/departments/hr/department_handbook.txt
sudo -u dojo nano /srv/technova/departments/hr/handbook_suggestions.txt
sudo chmod 640 /srv/technova/departments/hr/department_handbook.txt
sudo chmod 660 /srv/technova/departments/hr/handbook_suggestions.txt
```

### Error encountered — `ls -l` denied for the WSL/root user

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l /srv/technova/departments/engineering/
ls: cannot open directory '/srv/technova/departments/engineering/': Permission denied
```

**Cause:** `ruth1` (the default WSL user) is not a member of any department group and the directory permissions (`2770`) block "others" entirely — this is expected, correct behavior, not a bug. Verified instead with `sudo`:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/engineering
total 8
-rw-r----- 1 eadeyemi  engineering 1752 Aug  6 02:55 department_handbook.txt
-rw-rw---- 1 eadeyemi  engineering  160 Aug  6 02:55 handbook_suggestions.txt
-rw-r--r-- 1 mogunleye engineering    0 Aug  5 02:52 project_notes.txt
```

Sales, Finance, and HR were verified the same way:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/sales
total 8
-rw-r----- 1 goko sales 1924 Aug  6 03:10 department_handbook.txt
-rw-rw---- 1 goko sales  154 Aug  6 03:11 handbook_suggestions.txt
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/finance/
total 8
-rw-r----- 1 dibr finance 1879 Aug  6 03:20 department_handbook.txt
-rw-rw---- 1 dibr finance  156 Aug  6 03:20 handbook_suggestions.txt
```

### Minor typo — wrong path

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /drv/technova/departments/finance
ls: cannot access '/drv/technova/departments/finance': No such file or directory
```

Typed `/drv` instead of `/srv` — corrected on the next attempt.

## Step 2 — Test: Engineering Member (mogunleye)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - mogunleye
Password:
mogunleye@DESKTOP-DD7VGNC:~$
```

**Read the handbook (expected: succeed):**
```
mogunleye@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/department_handbook.txt
TechNova Solutions Ltd. — Engineering Department Handbook
Last updated by: Emmanuel Adeyemi (Department Administrator)
...
```
✅ Succeeded — full handbook content displayed.

**Attempt direct edit (expected: fail):**
```
mogunleye@DESKTOP-DD7VGNC:~$ echo "Unauthorized edit test" >> /srv/technova/departments/engineering/department_handbook.txt
-bash: /srv/technova/departments/engineering/department_handbook.txt: Permission denied
```
✅ Correctly denied — members cannot write directly to the handbook.

**Write a suggestion (expected: succeed):**
```
mogunleye@DESKTOP-DD7VGNC:~$ echo "Suggestion from Michael Ogunleye, 2026-08-06: Add a section on code review turnaround time." >> /srv/technova/departments/engineering/handbook_suggestions.txt
mogunleye@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/handbook_suggestions.txt
Engineering Handbook — Suggested Changes
Add your suggestion below with your name and date. The Department
Administrator reviews this file periodically.

---
Suggestion from Michael Ogunleye, 2026-08-06: Add a section on code review turnaround time.
```
✅ Succeeded — suggestion recorded.

```
mogunleye@DESKTOP-DD7VGNC:~$ exit
logout
```

## Step 3 — Admin Merge Test (eadeyemi)

Confirming the WSL user itself (not logged in as any department member) is also denied direct write, matching the "outsiders/non-members have no access" rule:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ echo "The Engineering Department Handbook has been reviewed and updated to reflect the latest development workflow." >> /srv/technova/departments/engineering/department_handbook.txt
-bash: /srv/technova/departments/engineering/department_handbook.txt: Permission denied
```

Switched to the actual admin account to perform the merge:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - eadeyemi
Password:
eadeyemi@DESKTOP-DD7VGNC:~$ echo "The Engineering Department Handbook has been reviewed and updated to reflect the latest development workflow." >> /srv/technova/departments/engineering/department_handbook.txt
eadeyemi@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/department_handbook.txt
...
The Engineering Department Handbook has been reviewed and updated to reflect the latest development workflow.
```
✅ Succeeded — confirms the admin, and only the admin, can write directly to the handbook. This is the "merge" step of the pull-request-style workflow.

```
eadeyemi@DESKTOP-DD7VGNC:~$ exit
logout
```

## Step 4 — Cross-Department Access Test (Sales → Engineering)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - sade
Password:
sade@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/department_handbook.txt
cat: /srv/technova/departments/engineering/department_handbook.txt: Permission denied
sade@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Correctly denied — a Sales employee cannot read Engineering's handbook, even by direct path.

## Step 5 — Test: Sales Member (djam)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - djam
Password:
djam@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/sales/department_handbook.txt
TechNova Solutions Ltd. — Sales Department Handbook
...
```
✅ Read succeeded.

```
djam@DESKTOP-DD7VGNC:~$ echo "Unauthorized edit test" >> /srv/technova/departments/sales/department_handbook.txt
-bash: /srv/technova/departments/sales/department_handbook.txt: Permission denied
```
✅ Direct edit correctly denied.

```
djam@DESKTOP-DD7VGNC:~$ echo "Suggestion from David James, 2026-08-06: Add guidance on handling multi-department deals." >> /srv/technova/departments/sales/handbook_suggestions.txt
djam@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/sales/handbook_suggestions.txt
Sales Handbook — Suggested Changes
...
---
Suggestion from David James, 2026-08-06: Add guidance on handling multi-department deals.
```
✅ Suggestion write succeeded.

```
djam@DESKTOP-DD7VGNC:~$ exit
logout
```

## Step 6 — Cross-Department Admin Test (Engineering admin → Sales)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - eadeyemi
Password:
eadeyemi@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/sales/department_handbook.txt
cat: /srv/technova/departments/sales/department_handbook.txt: Permission denied
eadeyemi@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Notably confirms that being a **department administrator does not grant access to other departments** — `eadeyemi` (Engineering's admin) is fully blocked from Sales' handbook, same as any regular outsider. Administrator privilege is scoped strictly to one's own department.

## Step 7 — Test: Finance Member (ceze)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - ceze
Password:
ceze@DESKTOP-DD7VGNC:~$ echo "Unauthorized edit test" >> /srv/technova/departments/finance/department_handbook.txt
-bash: /srv/technova/departments/finance/department_handbook.txt: Permission denied
```
✅ Direct edit correctly denied.

**Suggestion write — duplicate entry due to interrupted command:**
```
ceze@DESKTOP-DD7VGNC:~$ echo "Suggestion by Chioma Eze. 2026-08-06: Clarify expense approval turnaround time." >> /srv/technova/departments/finance/handbook_suggestions.txt
ceze@DESKTOP-DD7VGNC:~$ cat /srv/technova/depar^C
```
The first `cat` command was interrupted mid-type with `Ctrl+C`. The `echo` was then re-run, appending the same suggestion a second time:
```
ceze@DESKTOP-DD7VGNC:~$ echo "Suggestion by Chioma Eze. 2026-08-06: Clarify expense approval turnaround time." >> /srv/technova/departments/finance/handbook_suggestions.txt
```
Confirmed with `cat`:
```
ceze@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/finance/handbook_suggestions.txt
Finance Handbook — Suggested Changes
...
---
Suggestion by Chioma Eze. 2026-08-06: Clarify expense approval turnaround time.
Suggestion by Chioma Eze. 2026-08-06: Clarify expense approval turnaround time.
```
**Resolution:** opened the file with `nano` to manually remove the duplicate line:
```
ceze@DESKTOP-DD7VGNC:~$ nano /srv/technova/departments/finance/handbook_suggestions.txt
```

Handbook read also confirmed working normally for this account:
```
ceze@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/finance/department_handbook.txt
TechNova Solutions Ltd. — Finance Department Handbook
...
```

```
ceze@DESKTOP-DD7VGNC:~$ exit
logout
```

## Step 8 — Cross-Department Access Test (HR → Finance)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - raki
Password:
raki@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/finance/department_handbook.txt
cat: /srv/technova/departments/finance/department_handbook.txt: Permission denied
raki@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Correctly denied — an HR employee cannot read Finance's handbook.

## Step 9 — Test: HR Member (saki)

**Login error — wrong password on first attempt:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - saki
Password:
su: Authentication failure
```

**Stray input at the shell prompt:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ technova2026
^C
```
A password appears to have been typed directly at the bash prompt instead of at the `su` password prompt (no active `su` session was awaiting input at that point). Bash attempted to interpret it as a command; cancelled with `Ctrl+C` before it could error out further.

**Successful login on retry:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - saki
Password:
saki@DESKTOP-DD7VGNC:~$
```

**Attempt direct edit (expected: fail):**
```
saki@DESKTOP-DD7VGNC:~$ echo "Unauthorized edit test" >> /srv/technova/departments/hr/department_handbook.txt
-bash: /srv/technova/departments/hr/department_handbook.txt: Permission denied
```
✅ Correctly denied.

**Write a suggestion (expected: succeed):**
```
saki@DESKTOP-DD7VGNC:~$ echo "Suggestion from Samuel Akinwale, 2026-08-06: Add remote leave-request process." >> /srv/technova/departments/hr/handbook_suggestions.txt
saki@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/hr/handbook_suggestions.txt
HR Handbook — Suggested Changes
...
---
Suggestion from Samuel Akinwale, 2026-08-06: Add remote leave-request process.
```
✅ Succeeded.

```
saki@DESKTOP-DD7VGNC:~$ exit
logout
```

## Verification Summary

| Test | Department | Result |
|---|---|---|
| Member reads handbook | Engineering, Sales, Finance | ✅ Pass |
| Member denied direct edit of handbook | Engineering, Sales, Finance, HR | ✅ Pass |
| Member writes suggestion | Engineering, Sales, HR | ✅ Pass |
| Admin merges suggestion into handbook | Engineering | ✅ Pass |
| Outsider (different dept, regular staff) denied read | Sales → Engineering, HR → Finance | ✅ Pass |
| Outsider (different dept, admin) denied read | Engineering admin → Sales | ✅ Pass |
| WSL/root-level user denied directory listing without sudo | N/A (system-level) | ✅ Pass (expected) |

## Errors Encountered — Summary

1. **`ls: cannot open directory ... Permission denied`** — occurred when listing a department directory as the plain WSL user (`ruth1`), who belongs to no department group. Expected behavior; resolved by using `sudo ls`.
2. **Typo: `/drv/technova/...`** instead of `/srv/technova/...` — corrected on retry.
3. **Interrupted `cat` command (`Ctrl+C`) leading to a duplicate suggestion entry** (Finance) — the `echo` append was accidentally re-run; resolved by editing the file with `nano` to remove the duplicate line.
4. **`su: Authentication failure`** for `saki` — incorrect password on first attempt.
5. **Stray text (`technova2026`) typed directly at the bash prompt** instead of at an `su` password prompt — likely a password intended for the previous `su` attempt, entered a beat too late after the prompt had already failed. Cancelled with `Ctrl+C`; no system impact.

## Why This Testing Matters

This task validates a two-tier permission model within a single department — not just "in or out" like Task 4, but different access levels for different files based on trust and responsibility. The cross-department admin test (Step 6) was particularly important: it confirms that administrator privileges are scoped to one department only, preventing a subtle but realistic misconfiguration where an admin role is assumed to carry broader access than it should.

## Status

**✅ Completed**

All four departments have a `department_handbook.txt` (admin read/write, member read-only, outsiders none) and a `handbook_suggestions.txt` (admin and member read/write, outsiders none). Read access, write restrictions, suggestion submission, and admin-merge behavior were tested and verified across Engineering, Sales, Finance, and HR, including cross-department checks for both regular staff and administrators.

