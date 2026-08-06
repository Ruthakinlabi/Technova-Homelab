# Task 6 — Confidential Business Documents

## Business Requirement

With handbooks in place (Task 5), TechNova's leadership raised a more sensitive concern.

Each department handles information that should never be visible outside its own team — Finance's payroll figures, Engineering's unreleased product plans, Sales' active deal terms, HR's employee records. Unlike the handbook, which is openly readable by the whole department, this information is restricted even within the department itself: only the Department Administrator can view or modify it.

Each department maintains a `confidential.txt` file containing sensitive operational information relevant to that team — the strictest access tier in TechNova's permission model so far.

## Design

Unlike the handbook (group-readable by all members), `confidential.txt` excludes the department group from read/write entirely:

| File | Owner (Admin) | Group (Department) | Others |
|---|---|---|---|
| `confidential.txt` | read + write | no access | none |

In octal: `600` — owner read/write only, nothing for group or others. The file still sits inside the department's `2770` directory, so outsiders are blocked at the directory level as always; `600` adds a second, tighter wall that blocks even fellow department members.

## Step 1 — Create Files, Set Permissions (all four departments)

```bash
sudo -u eadeyemi nano /srv/technova/departments/engineering/confidential.txt
sudo chmod 600 /srv/technova/departments/engineering/confidential.txt

sudo -u goko nano /srv/technova/departments/sales/confidential.txt
sudo chmod 600 /srv/technova/departments/sales/confidential.txt

sudo -u dibr nano /srv/technova/departments/finance/confidential.txt
sudo chmod 600 /srv/technova/departments/finance/confidential.txt

sudo -u dojo nano /srv/technova/departments/hr/confidential.txt
sudo chmod 600 /srv/technova/departments/hr/confidential.txt
```

## Step 2 — Verify Ownership and Permissions

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/sales/confidential.txt
-rw------- 1 goko sales 699 Aug  6 07:58 /srv/technova/departments/sales/confidential.txt
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/finance/confidential.txt
-rw------- 1 dibr finance 690 Aug  6 08:00 /srv/technova/departments/finance/confidential.txt
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/hr/confidential.txt
-rw------- 1 dojo hr 697 Aug  6 08:01 /srv/technova/departments/hr/confidential.txt
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /srv/technova/departments/engineering/confidential.txt
-rw------- 1 eadeyemi engineering 914 Aug  6 05:10 /srv/technova/departments/engineering/confidential.txt
```

All four confirmed `-rw-------`: owner read/write only, zero access for group or others, despite each file still carrying its department's group label (inherited via setgid, as expected — group *label* and group *permissions* are independent).

## Step 3 — Test: Engineering Member Denied (mogunleye)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - mogunleye
Password:
mogunleye@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/confidential.txt
cat: /srv/technova/departments/engineering/confidential.txt: Permission denied
mogunleye@DESKTOP-DD7VGNC:~$ echo "test" >> /srv/technova/departments/engineering/confidential.txt
-bash: /srv/technova/departments/engineering/confidential.txt: Permission denied
mogunleye@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Both read and write correctly denied — despite `mogunleye` belonging to the `engineering` group, which has full access to every other file in the same directory.

## Step 4 — Test: Engineering Admin Succeeds (eadeyemi)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - eadeyemi
Password:
eadeyemi@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/engineering/confidential.txt
TechNova Solutions Ltd. — Engineering Department
CONFIDENTIAL — Administrator Access Only

1. UNRELEASED PRODUCT ROADMAP
Q4 2026: Migration of core platform to microservices architecture.
Q1 2027: Launch of TechNova Analytics module (client-facing beta).
Target launch is not to be shared outside department leadership
until formal announcement.

2. INFRASTRUCTURE ACCESS
Root-level production server credentials are rotated monthly and
stored in the Administrator's encrypted vault — not in this file
or any shared location.

3. PERFORMANCE / DISCIPLINARY NOTES
Any performance concerns regarding Engineering staff are logged
here by the Administrator only, for HR escalation if required.

4. VENDOR CONTRACTS
Current cloud infrastructure vendor contract renews March 2027.
Negotiated rate and terms are confidential and not to be discussed
with vendor sales representatives without Administrator sign-off.
eadeyemi@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Full read access confirmed for the admin.

## Step 5 — Test: Sales Member Denied (djam)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - djam
Password:
djam@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/sales/confidential.txt
cat: /srv/technova/departments/sales/confidential.txt: Permission denied
djam@DESKTOP-DD7VGNC:~$ echo "test" >> /srv/technova/departments/sales/confidential.txt
-bash: /srv/technova/departments/sales/confidential.txt: Permission denied
djam@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Both read and write correctly denied.

## Step 6 — Test: Finance Member Denied (ceze)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - ceze
Password:
ceze@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/finance/confidential.txt
cat: /srv/technova/departments/finance/confidential.txt: Permission denied
ceze@DESKTOP-DD7VGNC:~$ echo "test" >> /srv/technova/departments/finance/confidential.txt
-bash: /srv/technova/departments/finance/confidential.txt: Permission denied
ceze@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Both read and write correctly denied.

## Step 7 — Test: HR Member Denied (saki)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - saki
Password:
saki@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/hr/confidential.txt
cat: /srv/technova/departments/hr/confidential.txt: Permission denied
saki@DESKTOP-DD7VGNC:~$ echo "test" >> /srv/technova/departments/hr/confidential.txt
-bash: /srv/technova/departments/hr/confidential.txt: Permission denied
saki@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Both read and write correctly denied.

## Step 8 — Test: Remaining Admins Succeed (goko, dibr, dojo)

**Login error — wrong password on first attempt for goko:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - goko
Password:
su: Authentication failure
```

**Successful retry:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - goko
Password:
You are required to change your password immediately (administrator enforced).
Changing password for goko.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
goko@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/sales/confidential.txt
TechNova Solutions Ltd. — Sales Department
CONFIDENTIAL — Administrator Access Only

1. ACTIVE DEAL TERMS
Negotiated discount rates and custom contract terms for enterprise
clients are recorded here, not in the shared CRM notes visible to
the full team.

2. COMMISSION STRUCTURE
Individual commission rates and bonus thresholds are confidential
and must not be discussed between team members.

3. AT-RISK ACCOUNTS
Clients flagged as likely to churn, along with retention strategy,
are tracked here for Administrator-level planning only.

4. PERFORMANCE / DISCIPLINARY NOTES
Any performance concerns regarding Sales staff are logged here by
the Administrator only, for HR escalation if required.
goko@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Read access confirmed for Sales admin.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - dibr
Password:
You are required to change your password immediately (administrator enforced).
Changing password for dibr.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
dibr@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/finance/confidential.txt
TechNova Solutions Ltd. — Finance Department
CONFIDENTIAL — Administrator Access Only

1. PAYROLL DATA
Individual salary figures, bonus payouts, and payroll adjustments
are recorded here. Never to be discussed outside Finance leadership.

2. COMPANY FINANCIAL POSITION
Current cash reserves, outstanding liabilities, and unreleased
quarterly figures ahead of official reporting.

3. VENDOR/BANKING DETAILS
Banking relationships and account details for company operating
accounts. Access strictly limited to the Administrator.

4. PERFORMANCE / DISCIPLINARY NOTES
Any performance concerns regarding Finance staff are logged here
by the Administrator only, for HR escalation if required.
dibr@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Read access confirmed for Finance admin.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ su - dojo
Password:
You are required to change your password immediately (administrator enforced).
Changing password for dojo.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
dojo@DESKTOP-DD7VGNC:~$ cat /srv/technova/departments/hr/confidential.txt
TechNova Solutions Ltd. — Human Resources Department
CONFIDENTIAL — Administrator Access Only

1. EMPLOYEE RECORDS
Individual salary bands, disciplinary history, and performance
reviews for all TechNova staff across every department.

2. ONGOING INVESTIGATIONS
Any active workplace complaint or investigation details, restricted
to the Administrator until formally resolved.

3. HEALTH / LEAVE RECORDS
Medical leave documentation and related personal information,
covered under strict confidentiality regardless of department.

4. COMPANY-WIDE SALARY BANDS
Reference salary ranges used for hiring and promotion decisions
across all departments — restricted to prevent internal pay disputes.
dojo@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Read access confirmed for HR admin.

## Verification Summary

| Test | Department | Result |
|---|---|---|
| Member denied read | Engineering, Sales, Finance, HR | ✅ Pass |
| Member denied write | Engineering, Sales, Finance, HR | ✅ Pass |
| Admin read access | Engineering, Sales, Finance, HR | ✅ Pass |
| File retains department group label despite restricted access | All four | ✅ Confirmed via `ls -l` |

## Errors Encountered — Summary

1. **`su: Authentication failure`** for `goko` — incorrect password on first login attempt; resolved on retry.

All other steps completed without error on first attempt.

## Why This Matters

This task tests the clearest distinction yet between group **membership** and group **permissions**. Every confidential.txt file still belongs to its department's group (inherited automatically via the Task 4 setgid configuration), yet regular department members — who have full read/write access to every other file in the same directory — are completely denied access to this one file. This is only possible because `600` permissions explicitly grant zero rights to the group, overriding what group membership would otherwise allow. It's a direct, testable demonstration of the Principle of Least Privilege: access is scoped by role (administrator vs. member), not simply by department affiliation.

## Status

**✅ Completed**

All four departments have a `confidential.txt`, owned and readable/writable only by the department administrator (`600` permissions). Verified across all four departments that regular members are denied both read and write access, while administrators retain full access. No configuration errors encountered; one authentication retry (incorrect password) during testing.


