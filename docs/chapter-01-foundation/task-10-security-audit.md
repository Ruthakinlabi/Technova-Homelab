# Task 10 — Security Audit

*(Final task of Chapter 1. This is a review of current system state, not a re-run of prior tests — each finding either checks configuration directly or references the task where it was already verified.)*

## Business Requirement

Chapter 1 is complete: workspaces, groups, employee accounts, tiered file permissions, onboarding, and offboarding are all in place. This audit is a single consolidated review confirming the entire server is in the state it's supposed to be, closing out the chapter with a findings report rather than scattered pass/fail notes across nine separate docs.

## 1. Department Ownership and Group Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /srv/technova/departments/engineering
drwxrws--- 2 eadeyemi engineering 4096 Aug  6 08:40 /srv/technova/departments/engineering
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /srv/technova/departments/sales
drwxrws--- 2 goko sales 4096 Aug  6 08:31 /srv/technova/departments/sales
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /srv/technova/departments/finance
drwxrws--- 2 dibr finance 4096 Aug  6 08:31 /srv/technova/departments/finance
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /srv/technova/departments/hr
drwxrws--- 2 dojo hr 4096 Aug  6 08:32 /srv/technova/departments/hr
```

| Department | Expected Owner | Actual Owner | Expected Group | Actual Group | Result |
|---|---|---|---|---|---|
| Engineering | eadeyemi | eadeyemi | engineering | engineering | ✅ Pass |
| Sales | goko | goko | sales | sales | ✅ Pass |
| Finance | dibr | dibr | finance | finance | ✅ Pass |
| HR | dojo | dojo | hr | hr | ✅ Pass |

## 2. File-Level Permission Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/engineering
total 16
-rw------- 1 eadeyemi  engineering  914 Aug  6 05:10 confidential.txt
-rw-r----- 1 eadeyemi  engineering 1862 Aug  6 03:43 department_handbook.txt
-rw-rw---- 1 eadeyemi  engineering  346 Aug  6 12:53 handbook_suggestions.txt
-rw-r--r-- 1 mogunleye engineering    0 Aug  5 02:52 project_notes.txt
-rw-rw---- 1 eadeyemi  engineering  596 Aug  6 08:40 responsibility_matrix.txt

ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/sales
total 16
-rw------- 1 goko sales  699 Aug  6 07:58 confidential.txt
-rw-r----- 1 goko sales 1924 Aug  6 03:10 department_handbook.txt
-rw-rw---- 1 goko sales  244 Aug  6 03:51 handbook_suggestions.txt
-rw-rw---- 1 goko sales  413 Aug  6 08:31 responsibility_matrix.txt

ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/finance
total 16
-rw------- 1 dibr finance  690 Aug  6 08:00 confidential.txt
-rw-r----- 1 dibr finance 1879 Aug  6 03:20 department_handbook.txt
-rw-rw---- 1 dibr finance  236 Aug  6 04:05 handbook_suggestions.txt
-rw-rw---- 1 dibr finance  363 Aug  6 08:31 responsibility_matrix.txt

ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/hr
total 16
-rw------- 1 dojo hr  697 Aug  6 08:01 confidential.txt
-rw-r----- 1 dojo hr 2042 Aug  6 03:29 department_handbook.txt
-rw-rw---- 1 dojo hr  230 Aug  6 04:14 handbook_suggestions.txt
-rw-rw---- 1 dojo hr  381 Aug  6 08:32 responsibility_matrix.txt
```

| File Type | Expected | Sales | Finance | HR | Engineering |
|---|---|---|---|---|---|
| `confidential.txt` | 600 | ✅ | ✅ | ✅ | ✅ |
| `department_handbook.txt` | 640 | ✅ | ✅ | ✅ | ✅ |
| `handbook_suggestions.txt` | 660 | ✅ | ✅ | ✅ | ✅ |
| `responsibility_matrix.txt` | 660 | ✅ | ✅ | ✅ | ✅ |

**Finding (minor):** Engineering's directory contains `project_notes.txt`, a leftover test artifact from Task 4's setgid verification — owned by `mogunleye` (not the admin) with default `644` permissions rather than an intentionally assigned tier. It poses no real exposure (the department directory itself blocks outside traversal at `2770`), but it's inconsistent with the rest of the workspace, where every file has a deliberately assigned permission tier. **Recommended action:** remove it, or formally fold it into the responsibility matrix / suggestions pattern if it has ongoing purpose.

## 3. Account and Group Membership Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent group engineering sales finance hr
engineering:x:1002:
sales:x:1003:
finance:x:1005:
hr:x:1004:
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd eadeyemi mogunleye ebello bnwa goko sade djam dibr ceze faki dojo saki raki
eadeyemi:x:1001:1002:Emmanuel Adeyemi:/home/eadeyemi:/bin/bash
mogunleye:x:1002:1002:Miceal Ogunleye:/home/mogunleye:/bin/bash
ebello:x:1003:1002:Esther Bello:/home/ebello:/bin/bash
bnwa:x:1013:1002:Blessing Nwachukwu:/home/bnwa:/bin/bash
goko:x:1004:1003:Grace Okoro:/home/goko:/bin/bash
sade:x:1005:1003:Sunday Adebayo:/home/sade:/bin/bash
djam:x:1006:1003:David James:/home/djam:/bin/bash
dibr:x:1010:1005:Deborah Ibrahim:/home/dibr:/bin/bash
ceze:x:1012:1005:Chioma Eze:/home/ceze:/bin/bash
faki:x:1011:1005:Favour Akinyemi:/home/faki:/bin/bash
dojo:x:1007:1004:Daniel Ojo:/home/dojo:/bin/bash
saki:x:1008:1004:Samuel Akinwale:/home/saki:/bin/bash
raki:x:1009:1004:Ruth Akinlabi:/home/raki:/bin/bash
```

✅ All 13 accounts present, each with the correct primary group ID matching their department, correct home directory, and Bash shell.

**Finding (informational, not an error):** `mogunleye`'s GECOS field reads "Miceal Ogunleye" — a typo of "Michael" made at account creation in Task 3. Cosmetic only; does not affect access control. Worth correcting with `usermod -c "Michael Ogunleye" mogunleye` for accuracy, but not a security issue.

## 4. Former Employee Access Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S djam
djam L 1970-01-01 0 99999 7 -1
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo grep '^djam:' /etc/shadow
djam:!$y$j9T$JEERcUVFOL.Ff.o4C00WD1$l18RydAL6Vg/xsCckQxftldJ4suf57R.23iT4NV.20D:0:0:99999:7::20671:
```

✅ Status still shows `L` (locked), and the password hash still carries the `!` prefix — the lock from Task 9 remains fully in effect at audit time.

**Note on shadow field values:** the last-change field reads `0` (epoch date, 1970-01-01) because `passwd -e` forces an immediate expiry by resetting it to the earliest possible date. The final field, `20671`, is the account expiration date set via `usermod -e` in Task 9 (days since epoch, corresponding to Aug 6 2026) — confirming both layers of the offboarding control (password expiry and account expiration date) are correctly and independently in place.

## 5. New Employee Inheritance Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id bnwa
uid=1013(bnwa) gid=1002(engineering) groups=1002(engineering)
```

✅ Blessing's group membership remains correctly set to `engineering` — the access inheritance verified live in Task 13 is still intact at audit time.

## 6. Setgid Configuration Audit

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /srv/technova/departments/engineering /srv/technova/departments/sales /srv/technova/departments/finance /srv/technova/departments/hr
drwxrws--- 2 eadeyemi engineering 4096 Aug  6 08:40 /srv/technova/departments/engineering
drwxrws--- 2 dibr     finance     4096 Aug  6 08:31 /srv/technova/departments/finance
drwxrws--- 2 dojo     hr          4096 Aug  6 08:32 /srv/technova/departments/hr
drwxrws--- 2 goko     sales       4096 Aug  6 08:31 /srv/technova/departments/sales
```

✅ All four departments still show the `s` in the group-execute position — setgid remains active and unaltered since Task 4.

## Findings Report

```
TechNova Security Audit — Chapter 1 Close-Out
Date: 2026-08-06
Auditor: Ruth

1. Department Ownership & Group          [ PASS ]
2. File Permission Tiers (all 4 depts)   [ PASS ] (1 minor finding — stray test file)
3. Account & Group Membership            [ PASS ] (1 cosmetic finding — GECOS typo)
4. Former Employee Access Revoked        [ PASS ]
5. New Employee Inheritance Intact       [ PASS ]
6. Setgid Configuration Intact           [ PASS ]

Discrepancies found:
- Engineering: project_notes.txt (leftover Task 4 test artifact, default
  permissions, owned by mogunleye rather than admin) — no security
  exposure, but inconsistent with workspace convention.
- mogunleye: GECOS field contains a typo ("Miceal" instead of "Michael")
  from Task 3 account creation — cosmetic only.

Corrective action taken: None yet — both findings are low-risk and
logged for cleanup at the start of Chapter 2.
```

## Why This Approach

An audit reviews the current state of a system presumed already configured — it doesn't reconstruct every test from scratch. Tasks 4 through 9 already proved each permission tier behaves correctly under live conditions. This task's job was to confirm none of that configuration had silently drifted, and in doing so it surfaced two small, real findings (the stray test file and the GECOS typo) that none of the individual task tests would have caught, since neither one is a permission failure — exactly the kind of thing a fresh, systematic pass is designed to catch.

## Status

**✅ Completed — Chapter 1 Closed Out**
