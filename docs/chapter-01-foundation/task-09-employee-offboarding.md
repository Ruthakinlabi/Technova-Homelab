# Task 9 — Employee Offboarding

## Business Requirement

David James, a Sales employee (`djam`), has accepted a new opportunity elsewhere and is leaving TechNova. HR needs his access revoked promptly and securely — but his departmental files and home directory must be preserved, since they may be needed for future auditing, handover to a replacement, or reference.

This distinguishes offboarding from simple deletion: the goal is to remove access without destroying data. Deleting the account outright would also orphan any files he owns, potentially breaking things unexpectedly (e.g. commission records tied to his username in `confidential.txt`, if such references exist).

## Responsibilities

1. Lock David's account so he can no longer log in.
2. Expire his password immediately (belt-and-suspenders alongside the lock).
3. Preserve his home directory and any files in the Sales workspace — no deletion.
4. Verify he can no longer authenticate.
5. Verify his historical files remain intact and accessible to the Sales administrator for audit purposes.
6. Document why disabling is preferable to deleting.

## Why Disable, Not Delete

- **Audit trail** — a disabled account with intact history answers "what did David have access to, and when did it end?" A deleted account leaves no record.
- **File ownership integrity** — deleting a user can orphan files (owned by a now-nonexistent UID), which shows up as a raw number instead of a username in `ls -l` and complicates cleanup.
- **Reversibility** — if the departure turns out to be a leave of absence, or he's rehired later, re-enabling a locked account is trivial. Deletion is not easily reversible.
- **Real-world practice** — mirrors how companies actually handle offboarding: disable immediately, retain data per retention policy, purge much later if ever.

## Why Two Commands Were Used to Restrict Login (`usermod -L` and `passwd -e`)

Both commands were also used in Task 3 (onboarding) — but they serve different purposes depending on context.

**In Task 3 (onboarding):** `passwd -e` was run right after setting an initial password on an account the person is expected to log into. Expiring the password forces the *next login* through a mandatory "set a new password" flow.

**In this task (offboarding):** `passwd -e` still technically expires the current password, but David has no legitimate reason to log in and set a new one — nobody is resetting anything. Here it functions as a **secondary safety net** alongside `usermod -L`: even if the lock were somehow bypassed later, an expired password still cannot be used to authenticate. `usermod -L` is the primary control (disables the password hash entirely, visible as `!` in `/etc/shadow`); `passwd -e` is layered defense, not a "force reset."

## Commands and Output

**Step 1 — Lock the account:**
```bash
sudo usermod -L djam
```

**Step 2 — Confirm locked status:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S djam
djam L 2026-08-06 0 99999 7 -1
```
✅ Status `L` confirms the account is locked.

**Step 3 — Confirm the password hash itself is disabled:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo grep '^djam:' /etc/shadow
djam:!$y$j9T$JEERcUVFOL.Ff.o4C00WD1$l18RydAL6Vg/xsCckQxftldJ4suf57R.23iT4NV.20D:20671:0:99999:7:::
```
The leading `!` before the hash confirms the password is locked at the authentication level, not just flagged — this is what `usermod -L` actually does under the hood.

**Step 4 — Confirm login is blocked:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - djam
Password:
su: Authentication failure
```
✅ Login correctly denied.

**Step 5 — Expire the password (secondary safety net):**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -e djam
passwd: password changed.
```

**Step 6 — Set explicit account expiration date:**
```bash
sudo usermod -e $(date +%Y-%m-%d) djam
```

## Verification — Data Preserved

**Home directory intact:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -la /home/djam
total 28
drwxr-x---  3 djam sales 4096 Aug  6 03:52 .
drwxr-xr-x 16 root root  4096 Aug  6 12:50 ..
-rw-------  1 djam sales  501 Aug  6 08:06 .bash_history
-rw-r--r--  1 djam sales  220 Mar 31  2024 .bash_logout
-rw-r--r--  1 djam sales 3771 Mar 31  2024 .bashrc
drwxr-xr-x  2 djam sales 4096 Aug  6 03:48 .landscape
-rw-r--r--  1 djam sales    0 Aug  6 03:48 .motd_shown
-rw-r--r--  1 djam sales  807 Mar 31  2024 .profile
```
✅ Home directory and all files still owned by `djam:sales`, nothing deleted or orphaned.

**Sales workspace contributions intact:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo cat /srv/technova/departments/sales/responsibility_matrix.txt
Sales Responsibility Matrix
===========================

Grace Okoro
Role: Sales Manager
Responsibilities:
- Manage sales operations
- Approve quotations
- Monitor team performance

Sunday Adebayo
Role: Sales Executive
Responsibilities:
- Customer acquisition
- Lead follow-up
- Product demonstrations

David James
Role: Sales Executive
Responsibilities:
- Client relationship management
- Weekly sales reporting
```
✅ David's entry remains in the responsibility matrix, exactly as it was before offboarding — his contribution history is preserved for audit/handover purposes.

**Sales admin retains full normal access:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - goko
Password:
goko@DESKTOP-DD7VGNC:~$ ls -l /srv/technova/departments/sales/
total 16
-rw------- 1 goko sales  699 Aug  6 07:58 confidential.txt
-rw-r----- 1 goko sales 1924 Aug  6 03:10 department_handbook.txt
-rw-rw---- 1 goko sales  244 Aug  6 03:51 handbook_suggestions.txt
-rw-rw---- 1 goko sales  413 Aug  6 08:31 responsibility_matrix.txt
goko@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Confirms offboarding one employee had no side effects on the department's normal operation — the admin's access and all four departmental files remain exactly as configured.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Account locked (`passwd -S` shows `L`) | Locked | ✅ Pass |
| Password hash disabled in `/etc/shadow` (`!` prefix) | Disabled | ✅ Pass |
| Login attempt fails | Denied | ✅ Pass |
| Home directory preserved | Untouched | ✅ Pass |
| Departmental file contributions preserved | Untouched | ✅ Pass |
| Sales admin access unaffected | Normal | ✅ Pass |

## Errors Encountered

None — all commands executed successfully on the first attempt.

## Status

**✅ Completed**

David James's account (`djam`) has been locked and his password expired, blocking all login while preserving his home directory and every contribution he made to the Sales department workspace. Verified via `/etc/shadow`, failed login attempt, and confirmation that his files and the department admin's access remain fully intact.
