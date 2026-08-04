# Task 2 — Department Identity

## Business Requirement

Following the successful creation of the departmental workspace (Task 1),
TechNova's management raised a security concern: granting permissions to
every employee individually would become time-consuming, error-prone, and
difficult to audit as the company grows.

To address this, IT decided to implement Role-Based Access Control (RBAC)
using Linux groups. Each department gets a dedicated Linux group representing
its identity. All current and future employees will inherit access to
departmental resources through group membership rather than individual
permission assignments.

## Departments

- Engineering
- Sales
- Human Resources
- Finance

## Naming Convention

Group names match the department workspace folder names created in Task 1
(`/srv/technova/departments/{hr,finance,sales,engineering}`), using short,
lowercase, no-space identifiers:

| Department        | Group name    |
|--------------------|--------------|
| Engineering        | `engineering` |
| Sales               | `sales`       |
| Human Resources     | `hr`          |
| Finance             | `finance`     |

Keeping group names identical to the workspace folder names makes the
relationship between identity (group) and resource (workspace) immediately
obvious to anyone auditing the system later, and avoids ambiguity when
assigning group ownership in Task 4.

## Commands Used

```bash
sudo groupadd engineering
sudo groupadd sales
sudo groupadd hr
sudo groupadd finance
```

Note: an `engineering` group already existed on this system from a prior,
unrelated lab project. It was removed and recreated to ensure a clean group
with no leftover members, consistent with this project's history:

```bash
sudo groupdel engineering
sudo groupadd engineering
```

## Verification

```bash
getent group engineering sales hr finance
```
All four groups exist, with no members yet — consistent with the expected
outcome (identity layer only; user assignment happens in Task 3).

## Design Decision — Why Linux Groups Over Individual Permissions

- **Faster onboarding** — a new employee gains full departmental access by
  being added to one group, instead of having permissions set file-by-file.
- **Instant, clean offboarding** — removing a user from a group revokes
  access immediately, without touching the resources themselves.
- **No repetitive permission changes** — new files inherit group access
  automatically (once `setgid` is configured in Task 4), so permissions
  don't need to be reapplied per file.
- **Auditability** — `getent group <name>` gives a single, authoritative
  answer to "who has access to this department," rather than needing to
  inspect permissions across every file individually.
- **Scalability** — this model works identically whether TechNova has 4
  employees or 400; the process for granting/revoking access never changes.

## Status

✅ Complete — all four department groups created and verified.
No users assigned yet. Ready for Task 3 (Employee Onboarding).
