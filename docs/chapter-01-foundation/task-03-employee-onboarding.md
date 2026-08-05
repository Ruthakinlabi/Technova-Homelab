Task 3 — Employee Onboarding
Business Requirement

With the departmental structure established, TechNova Solutions Ltd. is ready to onboard its first employees.

Each employee requires a secure Linux account to access company resources. To ensure consistency across the organization, every account must:

Have a personal home directory.
Use Bash as the default login shell.
Belong to the appropriate department group.
Receive an initial password.
Be required to change the password upon first login.

Department Administrators will later assume ownership of departmental resources, making user creation a prerequisite for future permission management tasks.

Environment
Operating System: Ubuntu 24.04 LTS (WSL2)
Filesystem: Native Linux filesystem
Project: TechNova Homelab
Current Phase: Chapter 1 – Building the Foundation
Technical Objective

Provision Linux user accounts for all TechNova employees while implementing a consistent identity management model that supports future growth.

Each user account should include:

Home directory
Bash login shell
Department-based primary group
User information (GECOS field)
Temporary password
Mandatory password reset at first login
Username Convention

To keep usernames short, unique, and easy to remember, TechNova uses abbreviated usernames rather than full surnames.

Examples:

Employee	Username
Emmanuel Adeyemi	eadeyemi
Michael Ogunleye	mogunleye
Esther Bello	ebello
Grace Okoro	goko
Sunday Adebayo	sade
David James	djam
Daniel Ojo	dojo
Samuel Akinwale	saki
Ruth Akinlabi	raki
Deborah Ibrahim	dibr
Favour Akinyemi	faki
Chioma Eze	ceze

This naming convention prioritizes uniqueness and ease of administration while remaining consistent across the organization.

Commands Used

sudo useradd -m -s /bin/bash -g engineering \
-c "Emmanuel Adeyemi" eadeyemi

The same approach was used for every employee.

Passwords were assigned using:

sudo passwd username

Users were then required to change their passwords during their first login:

sudo passwd -e username

Verification

User accounts were verified using:

id username

uid=1001(eadeyemi) gid=1002(engineering) groups=1002(engineering)

User information was verified using:

getent passwd username

eadeyemi:x:1001:1002:Emmanuel Adeyemi:/home/eadeyemi:/bin/bash

Password expiration policy was confirmed using:

sudo passwd -S username

Challenges Encountered

Several minor syntax mistakes occurred during onboarding:

A missing space between the user's full name and username caused useradd to display its usage message.
getent password was mistakenly used instead of getent passwd.
One password entry failed because the confirmation did not match and had to be re-entered successfully.

These issues were identified, corrected, and documented during implementation.
During implementation, a naming inconsistency was introduced while creating user accounts. Some usernames followed the original convention of using the employee's first initial and surname (e.g., eadeyemi), while others were created using shortened forms (e.g., goko, raki).

Since passwords had already been assigned and the accounts had not yet been integrated into any production services, two approaches were considered:

Renaming the existing user accounts using usermod.
Keeping the existing usernames and formally adopting the shortened format as the project's username convention.

To avoid unnecessary administrative changes and maintain project momentum, the second approach was chosen.

As a result, the shortened usernames became the official naming convention for the TechNova Homelab project.

Lessons Learned

Linux usernames should follow a consistent naming convention.
The -c option stores descriptive user information in the GECOS field.
Password expiration can be enforced immediately using passwd -e.
Verification after each administrative action helps identify configuration mistakes early.
Small syntax errors are common during manual administration and reinforce the importance of verifying commands before execution.

Skills Practiced
Linux user management (useradd)
Account verification (id, getent)
Password management (passwd)
Password expiration policies
Linux identity management
Group-based access control
User provisioning best practices

Status

✅ Completed

All TechNova employees have been successfully onboarded with secure Linux accounts, assigned to the appropriate department groups, and configured to change their passwords on first login.
