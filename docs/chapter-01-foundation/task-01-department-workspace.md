# Task 1 — Department Workspace

## Business Requirement

Create a dedicated workspace for each department in an appropriate location
within the Linux filesystem. The workspace must support future expansion as
the company grows.

## Environment

- OS: Ubuntu (WSL2)
- Working filesystem: native Linux filesystem (`/srv`), not the Windows-mounted
  drive (`/mnt/c/...`), since permission and ownership models do not behave
  correctly on Windows-mounted paths under WSL.

## Design Decision — Why `/srv`

The Filesystem Hierarchy Standard (FHS) defines `/srv` as the location for
data served by or belonging to the site/organization itself. Department
workspaces, handbooks, and confidential documents fall directly under that
definition.

Alternatives considered and rejected:

| Location | Purpose (per FHS)                        | Why not used here                          |
|----------|-------------------------------------------|---------------------------------------------|
| `/home`  | Personal directories for individual users | Departments are not user accounts           |
| `/opt`   | Third-party/add-on software packages      | Not applicable — this is organizational data|
| `/var`   | Variable data (logs, caches, spool files) | Not deliberately-created business data      |

## Directory Structure/srv/technova/departments/
├── hr/
├── finance/
├── sales/
└── engineering/One parent directory (`/srv/technova/departments/`) holding one subfolder per
department. Onboarding a new department later requires only one additional
`mkdir` command — no restructuring of existing departments.

## Commands Used

Created step by step for clarity while learning:

```bash
# Create the base path (parent directories don't exist yet, hence -p)
sudo mkdir -p /srv/technova/departments

# Create each department folder
sudo mkdir /srv/technova/departments/hr
sudo mkdir /srv/technova/departments/finance
sudo mkdir /srv/technova/departments/sales
sudo mkdir /srv/technova/departments/engineering
```

Equivalent one-line version (used in later tasks/scripts for efficiency):

```bash
sudo mkdir -p /srv/technova/departments/{hr,finance,sales,engineering}
```

## Verification

```bash
ls -l /srv/technova/departments/
```

Expected output: four directories (`hr`, `finance`, `sales`, `engineering`),
currently owned by `root:root` with default permissions.

## Notes

- Ownership and group assignment are deliberately **not** configured in this
  task. Department Linux groups don't exist yet — they're created in Task 2.
  Assigning ownership now would mean redoing it once those groups exist.
- All work was performed inside the WSL Linux filesystem to ensure `chmod`/
  `chown`/`setgid` behave as they would on a real Linux server, since the
  rest of this chapter depends on correct permission handling.
### What went well

- The directory structure follows Linux filesystem conventions.
- Company data is separated from user home directories.
- The design is scalable and easy to maintain.

### What could be improved

In a larger organization, departmental data might be hosted on dedicated storage systems or network file servers (such as NFS or Samba) rather than a single local server. However, for a startup with one Ubuntu server and ten employees, this design is simple, secure, and appropriate.

### Production Considerations

As TechNova grows, this directory structure can be integrated with centralized authentication services (such as LDAP or Active Directory), shared storage, automated backups, and access auditing without requiring major structural changes.
## Status

✅ Complete — ready for Task 2 (Department Identity / Groups)
