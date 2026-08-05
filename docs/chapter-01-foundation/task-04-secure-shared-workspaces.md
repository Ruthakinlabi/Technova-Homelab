# Task 4 — Secure Shared Workspaces

## Business Requirement

TechNova Solutions Ltd. has successfully onboarded its first employees.
However, the department workspaces created during initial infrastructure
setup were still owned by `root` and could not yet be used for daily
operations.

Management required each department to have a secure collaborative
workspace where team members can create, modify, and share files with
colleagues in the same department, while employees outside the department
are fully blocked. All newly created files within a department must
automatically inherit that department's group ownership, regardless of
who creates them. Department administrators assume ownership of their
workspace and manage it without needing root privileges.

## Technical Objectives

1. Department administrator becomes the owner of the department directory.
2. Department group becomes the group owner.
3. Department members can read, create, modify files, and enter the directory.
4. Outsiders cannot view, enter, or modify the directory.
5. New files automatically inherit the department's group (setgid).
6. Principle of Least Privilege applied throughout.

## Step 1 — Set Ownership

```bash
sudo chown eadeyemi:engineering /srv/technova/departments/engineering
sudo chown goko:sales /srv/technova/departments/sales
sudo chown dibr:finance /srv/technova/departments/finance
sudo chown dojo:hr /srv/technova/departments/hr
```

## Step 2 — Set Permissions and Setgid

`2770` = setgid bit + owner (rwx) + group (rwx) + others (none).

```bash
sudo chmod 2770 /srv/technova/departments/engineering
sudo chmod 2770 /srv/technova/departments/sales
sudo chmod 2770 /srv/technova/departments/finance
sudo chmod 2770 /srv/technova/departments/hr
```

## Step 3 — Verify Ownership and Permissions

```bash
ls -ld /srv/technova/departments/engineering
ls -ld /srv/technova/departments/sales
ls -ld /srv/technova/departments/finance
ls -ld /srv/technova/departments/hr
```

Confirmed each directory shows `drwxrws---`, correct owner (admin), and
correct group (department) — the `s` in the group execute position
confirms setgid is active.

## Step 4 — Test Setgid Inheritance (Positive Test)

**4.1 — Switch to an Engineering employee (not the admin):**

```bash
su - mogunleye
```

**Errors encountered during this step:**

Attempt 1:
su - mogunleye
Password:
You are required to change your password immediately (administrator enforced).
Changing password for mogunleye.
Current password:
su: Authentication token manipulation error
Cause: the current password entered during the forced password-change
prompt was not accepted/confirmed correctly, so the change failed mid-way.

Attempt 2:
su - mogunleye
Password:
su: Authentication failure
Cause: incorrect password entered on the login attempt itself.

Attempt 3 (successful):
su - mogunleye
Password:
You are required to change your password immediately (administrator enforced).
Changing password for mogunleye.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
Password change completed successfully on the third attempt; session
started normally.

**4.2 — Confirm identity:**
```bash
whoami
```
Output: `mogunleye`

**4.3 — Navigate to the Engineering workspace:**
```bash
cd /srv/technova/departments/engineering
```
Successful — no permission errors, confirming `mogunleye`'s `engineering`
group membership grants entry.

**4.4 — Create a test file:**
```bash
touch project_notes.txt
```

**4.5 — Verify group inheritance:**
```bash
ls -l project_notes.txt
```
Output:
-rw-r--r-- 1 mogunleye engineering 0 Aug 5 02:52 project_notes.txt
Confirms: owner is `mogunleye` (the creator), but group is `engineering`
— inherited from the parent directory via the setgid bit, not from the
user's own primary group. This is the exact behavior the setgid bit is
meant to produce.

```bash
exit
```

## Step 5 — Test Access Denial for Outsiders (Negative Test)

**5.1 — Switch to a Sales employee:**

**Errors encountered:**
su -sade
Password:
su: Authentication failure
Cause: missing space between `su -` and `sade` (`su -sade` was
interpreted incorrectly), combined with an incorrect password on the
first two attempts.

Successful attempt:
```bash
su - sade
```
Password:
You are required to change your password immediately (administrator enforced).
Changing password for sade.
Current password:
New password:
Retype new password:
You must choose a longer password.
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
Note: the first new-password attempt was rejected for being too short
(`You must choose a longer password.`); a longer password was accepted
on the second attempt.

**5.2 — Attempt to access departments Sales does NOT belong to:**

```bash
cd /srv/technova/departments/engineering
```
Output:
-bash: cd: /srv/technova/departments/engineering: Permission denied
```bash
cd /srv/technova/departments/hr
```
Output:
-bash: cd: /srv/technova/departments/hr: Permission denied
```bash
cd /srv/technova/departments/finance
```
Output:
-bash: cd: /srv/technova/departments/finance: Permission denied
All three correctly denied — confirms outsiders cannot enter departments
they don't belong to.

**5.3 — Confirm Sales can still access their own department:**

```bash
cd /srv/technova/departments/sales
```
Successful — no error, prompt changes to:
sade@DESKTOP-DD7VGNC:/srv/technova/departments/sales$
Confirms `sade` retains normal access within his own department while
being fully blocked from every other department.

## Verification Summary

| Test | Expected | Result |
|---|---|---|
| Engineering employee creates file in workspace | File inherits `engineering` group | ✅ Pass |
| Engineering employee enters own workspace | Access granted | ✅ Pass |
| Sales employee enters Engineering workspace | Permission denied | ✅ Pass |
| Sales employee enters HR workspace | Permission denied | ✅ Pass |
| Sales employee enters Finance workspace | Permission denied | ✅ Pass |
| Sales employee enters own (Sales) workspace | Access granted | ✅ Pass |

## Errors Encountered — Summary

1. **`su: Authentication token manipulation error`** — occurred when the
   forced password-change flow was interrupted/mismatched; resolved by
   retrying `su -` and completing the password change cleanly.
2. **`su: Authentication failure`** (mogunleye and sade, multiple times)
   — incorrect password entered; resolved by re-attempting with the
   correct password.
3. **`su -sade` typo** — missing space between the `-` flag and the
   username caused `su` to misparse the argument; corrected to `su - sade`.
4. **Password rejected as too short** (`You must choose a longer
   password.`) during sade's forced password change — resolved by
   choosing a longer replacement password.

All errors were self-corrected through retry; no configuration changes
were required to resolve them — they were user-input errors, not
permission or setgid misconfigurations.

## Why This Testing Matters

A configuration isn't complete until it's tested. Without the setgid
test, group ownership on new files could silently default to each
creator's personal group instead of the department group — breaking
collaboration as the team grows. Without the negative-access test, a
misconfigured `chmod` (e.g. leaving "others" with read access) could go
unnoticed until an actual data leak occurred. Testing both the positive
case (department member, full access) and negative case (outsider,
no access) is what confirms least-privilege was actually achieved, not
just configured.

## Status

**✅ Completed**

Ownership, group ownership, permissions, and setgid successfully
configured on all four department workspaces. Setgid inheritance verified
for Engineering. Cross-department access denial verified using a Sales
account against Engineering, HR, and Finance, with same-department access
confirmed still functional.
