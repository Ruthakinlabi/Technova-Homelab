# Task 3 — Employee Onboarding

## Business Requirement

With the departmental structure established (Tasks 1–2), TechNova Solutions
Ltd. is ready to onboard its first employees.

Each employee requires a secure Linux account to access company resources.
To ensure consistency across the organization, every account must:

- Have a personal home directory.
- Use Bash as the default login shell.
- Belong to the appropriate department group.
- Receive an initial password.
- Be required to change the password upon first login.

Department Administrators will later assume ownership of departmental
resources, making user creation a prerequisite for future permission
management tasks.

##Provision Linux user accounts for all TechNova employees, implementing a
consistent identity model that supports future growth. Each account
includes: home directory, Bash login shell, department-based primary
group, GECOS full-name field, temporary password, and mandatory password
reset at first login.

## Username Convention

| Employee          | Department            | Username    |
|-------------------|------------------------|-------------|
| Emmanuel Adeyemi  | Engineering (Admin)    | `eadeyemi`  |
| Michael Ogunleye  | Engineering            | `mogunleye` |
| Esther Bello      | Engineering            | `ebello`    |
| Grace Okoro       | Sales (Admin)          | `goko`      |
| Sunday Adebayo    | Sales                  | `sade`      |
| David James       | Sales                  | `djam`      |
| Deborah Ibrahim   | Finance (Admin)        | `dibr`      |
| Chioma Eze        | Finance                | `ceze`      |
| Favour Akinyemi   | Finance                | `faki`      |
| Daniel Ojo        | HR (Admin)             | `dojo`      |
| Samuel Akinwale   | HR                     | `saki`      |
| Ruth Akinlabi     | HR                     | `raki`      |

## Commands Used

```bash
# Engineering
sudo useradd -m -s /bin/bash -g engineering -c "Emmanuel Adeyemi" eadeyemi
sudo useradd -m -s /bin/bash -g engineering -c "Michael Ogunleye" mogunleye
sudo useradd -m -s /bin/bash -g engineering -c "Esther Bello" ebello

# Sales
sudo useradd -m -s /bin/bash -g sales -c "Grace Okoro" goko
sudo useradd -m -s /bin/bash -g sales -c "Sunday Adebayo" sade
sudo useradd -m -s /bin/bash -g sales -c "David James" djam

# Finance
sudo useradd -m -s /bin/bash -g finance -c "Deborah Ibrahim" dibr
sudo useradd -m -s /bin/bash -g finance -c "Chioma Eze" ceze
sudo useradd -m -s /bin/bash -g finance -c "Favour Akinyemi" faki

# HR
sudo useradd -m -s /bin/bash -g hr -c "Daniel Ojo" dojo
sudo useradd -m -s /bin/bash -g hr -c "Samuel Akinwale" saki
sudo useradd -m -s /bin/bash -g hr -c "Ruth Akinlabi" raki
```

Passwords assigned using:
```bash
sudo passwd <username>
```

Forced change at first login:
```bash
sudo passwd -e <username>
```

## Verification

Account and group membership:
```bash
id <username>
```
Example:
```text
uid=1001(eadeyemi) gid=1002(engineering) groups=1002(engineering)
```

Full account details:
```bash
getent passwd <username>
```
Example:
```text
eadeyemi:x:1001:1002:Emmanuel Adeyemi:/home/eadeyemi:/bin/bash
```

Password expiration status:
```bash
sudo passwd -S <username>
```

Group membership across the department:
```bash
getent group engineering sales finance hr
```

## Challenges Encountered

During implementation, a naming inconsistency was introduced while creating
user accounts. Some usernames followed the original convention of using the
employee's first initial and surname (e.g., `eadeyemi`), while others were
created using shortened forms (e.g., `goko`, `raki`).

Since passwords had already been assigned and the accounts had not yet been
integrated into any production services, two approaches were considered:

- Renaming the existing user accounts using `usermod`.
- Keeping the existing usernames and formally adopting the shortened format
  as the project's username convention.

To avoid unnecessary administrative changes and maintain project momentum,
the second approach was chosen. As a result, the shortened usernames became
the official naming convention for the TechNova Homelab project.

## Lessons Learned

- Linux usernames only need to be unique — naming convention is a
  readability choice, not a functional requirement.
- The `-c` option stores descriptive info (full name) in the GECOS field.
- `passwd -e` enforces an immediate password change at next login.
- Verifying after each account creation (`id`, `getent passwd`) catches
  mistakes early, before they compound across multiple accounts.
- Real projects rarely follow the original spec exactly knowing when to
  formalize a deviation (rather than backtrack) is itself a practical skill.

## Production Considerations

In enterprise environments, accounts are rarely created manually one by
one — they're provisioned through centralized identity management systems
or automated onboarding scripts. The accounts here were created manually
for learning purposes, but the group-based identity model established now
is designed to support automation later, when onboarding scales to dozens
of employees at once.

## Skills Practiced

- Linux user management (`useradd`)
- Account verification (`id`, `getent`)
- Password management (`passwd`)
- Password expiration policies
- Group-based access control
- Organizational/documentation decision-making under changing requirements

## Status

**✅ Completed**

12 employee accounts created across Engineering, Sales, Finance, and HR.
All accounts have home directories, Bash shells, correct group membership,
and expired passwords forcing a first-login change.

Ready for **Task 4 — Secure Shared Workspaces**.
