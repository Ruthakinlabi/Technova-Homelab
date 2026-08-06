# Task 8 — New Employee Onboarding

## Business Requirement

Engineering has grown enough to justify hiring another Software Engineer. HR provided onboarding details for TechNova's newest employee:

**Blessing Nwachukwu** — Software Engineer, Engineering Department.

The real test here isn't creating the account — it's confirming that the permission model built in Tasks 1–7 actually scales as designed. If the department workspace, group structure, and setgid configuration were done correctly, onboarding a new employee should require **zero changes** to existing permissions — she should inherit full, correct access simply by being added to the right group.

## Commands — Account Creation

```bash
sudo useradd -m -s /bin/bash -g engineering -c "Blessing Nwachukwu" bnwa
sudo passwd bnwa
sudo passwd -e bnwa
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo useradd -m -s /bin/bash -g engineering -c "Blessing Nwachukwu" bnwa
[sudo] password for ruth1:
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd bnwa
New password:
Retype new password:
passwd: password updated successfully
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -e bnwa
passwd: password changed.
```

## Verification — Account Setup

**Typos on first two attempts:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id bwa
id: 'bwa': no such user
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id bwan
id: 'bwan': no such user
```
Cause: username mistyped twice (`bwa`, `bwan` instead of `bnwa`).

**Correct command:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id bnwa
uid=1013(bnwa) gid=1002(engineering) groups=1002(engineering)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd bnwa
bnwa:x:1013:1002:Blessing Nwachukwu:/home/bnwa:/bin/bash
```
✅ Account confirmed: correct UID, correct primary group (`engineering`), home directory, and Bash shell — all set in a single `useradd` command, no follow-up permission changes.

## Verification — Access Inheritance (logged in as Blessing)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - bnwa
Password:
You are required to change your password immediately (administrator enforced).
Changing password for bnwa.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
bnwa@DESKTOP-DD7VGNC:~$
```

**Attempted to read the handbook from her home directory (wrong location):**
```
bnwa@DESKTOP-DD7VGNC:~$ cat department_handbook.txt
cat: department_handbook.txt: No such file or directory
```
Expected — the handbook lives in the Engineering workspace, not her home directory. Corrected by navigating there first:

```
bnwa@DESKTOP-DD7VGNC:~$ cd /srv/technova/departments/engineering
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ cat department_handbook.txt
TechNova Solutions Ltd. — Engineering Department Handbook
...
The Engineering Department Handbook has been reviewed and updated to reflect the latest development workflow.
```
✅ Read access confirmed — inherited automatically via `engineering` group membership, no permission changes needed.

**Attempted direct edit (expected: denied):**
```
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ echo "test" >> department_handbook.txt
-bash: department_handbook.txt: Permission denied
```
✅ Correctly denied — Task 5's read-only-for-members rule applied automatically to a brand-new account, with no reconfiguration.

**Suggestion write (expected: succeed):**
```
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ echo "Suggestion from Blessing Nwachukwu, 2026-08-06: would love a pairing rotation for onboarding." >> handbook_suggestions.txt
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ cat handbook_suggestions.txt
Engineering Handbook — Suggested Changes
...
---
Suggestion from Michael Ogunleye, 2026-08-06: Add a section on code review turnaround time.
Suggestion from Blessing Nwachukwu, 2026-08-06: would love a pairing rotation for onboarding.
```
✅ Succeeded — full read/write access to the suggestions file, exactly as it works for existing staff.

**Confidential file access (expected: denied):**
```
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ cat confidential.txt
cat: confidential.txt: Permission denied
```
✅ Correctly denied — Task 6's admin-only restriction applied automatically; Blessing is a member, not the admin.

**Cross-department access (expected: denied):**
```
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ cd /srv/technova/departments/sales
-bash: cd: /srv/technova/departments/sales: Permission denied
```
✅ Correctly denied — no access outside Engineering.

```
bnwa@DESKTOP-DD7VGNC:/srv/technova/departments/engineering$ exit
logout
```

## Note — Setgid Inheritance Not Re-tested

This session verified read/write access across the handbook, suggestions file, and confidential file, plus cross-department denial. The specific test of creating a new file (`touch`) and confirming it inherits the `engineering` group via setgid — as done for `mogunleye` in Task 4 — was not repeated for Blessing in this session, since Task 4 already established the setgid mechanism works at the directory level for any user placed in the group. Group inheritance is a property of the directory configuration, not of the individual account, so this was not considered a required re-test.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Account created with correct group, home, shell | Pass | ✅ Pass |
| Read handbook | Allowed | ✅ Pass |
| Direct edit of handbook | Denied | ✅ Pass |
| Write to suggestions file | Allowed | ✅ Pass |
| Read confidential.txt | Denied | ✅ Pass |
| Access another department (Sales) | Denied | ✅ Pass |

## Errors Encountered

1. **`id bwa` / `id bwan`** — username typos on the first two verification attempts; resolved on the third try with the correct username (`bnwa`).
2. **`cat department_handbook.txt` from home directory** — file not found, since the command was run before navigating into the Engineering workspace; resolved with `cd` into the correct directory first.

## Why This Matters

No `chmod`, `chown`, or setgid command was run as part of this task — onboarding Blessing was purely an identity operation (`useradd` plus group assignment). Every access rule established in Tasks 4 through 6 applied to her automatically, immediately, from first login. This is the direct payoff of the group-based RBAC model designed back in Task 2: access is a function of group membership, decided once, and it scales without any per-employee permission work.

## Status

**✅ Completed**

Blessing Nwachukwu (`bnwa`) onboarded to Engineering with zero changes to existing permissions, ownership, or setgid configuration. All access rules — handbook read-only, suggestions read/write, confidential.txt denied, cross-department denied — verified working correctly on first login.

