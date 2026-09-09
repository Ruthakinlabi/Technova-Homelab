# Technova-Homelab

A simulated company (TechNova Solutions Ltd.) used to practice Linux administration, security, networking, and cloud skills through realistic business scenarios.

## Why this project exists

To build hands-on, documented experience with real sysadmin workflows and create a portfolio that demonstrates practical skills, not just theory.

## Structure

The lab is organized as a roadmap of chapters, each simulating a stage in TechNova's growth — starting with core Linux administration and expanding into automation, networking, identity management, cloud infrastructure, and security operations.

Documentation for each task lives under `docs/`, organized by chapter:
docs/
├── chapter-01-foundation/
│ ├── task-01-department-workspace.md
│ └── ...
├── chapter-01-addendum.md
├── chapter-01-addendum-2.md
└── chapter-02-automation/
├── task-01-employee-data-source.md
└── ...


Each task file includes the business requirement, the commands used, verification steps, real terminal output (including errors and how they were resolved), and design decisions/rationale.

## Progress

### Chapter 1 — Building the Foundation
- [x] Task 1 — Department Workspace
- [x] Task 2 — Department Identity
- [x] Task 3 — Employee Onboarding
- [x] Task 4 — Secure Shared Workspaces
- [x] Task 5 — Department Handbook
- [x] Task 6 — Confidential Business Documents
- [x] Task 7 — Responsibility Matrix
- [x] Task 8 — Shared Project Workspace
- [x] Task 9 — Employee Offboarding
- [x] Task 10 — Security Audit

*(Refined from an originally planned 15 tasks down to 9 high-quality ones.)*

**Appendix 1 — Additional Departments:** Marketing, Customer Support, Product Management, and DevOps added to reflect company growth ahead of Chapter 2.

**Appendix 2 — Username Standardization:** all accounts normalized to a consistent `first-initial + surname` convention.

### Chapter 2 — Bash Automation
- [x] Task 1 — Employee Data Source
- [x] Task 2 — Automated User Provisioning
- [x] Task 3 — Initial Password Generation
- [x] Task 4 — Automated Directory Updates
- [x] Task 5 — Logging and Error Reporting
- [x] Task 6 — Bulk Offboarding
- [x] Task 7 — Automated Welcome Email Simulation
- [x] Task 8 — Automation Audit

**Appendix 1 — Missing Department Matrices & Duplicate-Data Cleanup:** created `responsibility_matrix.txt` for the four Appendix-1 departments and deduplicated contaminated entries in Engineering and Sales, introduced during earlier test runs.

**Appendix 2 — Role Correction, GECOS Fix, Cumulative Reporting:** corrected an inaccurate employee role, fixed a cosmetic account typo, and changed the offboarding report script from overwrite to append.

*(70 real new-hire records processed end-to-end: validated, provisioned, secured with a temporary password + forced first-login reset, added to departmental responsibility matrices, welcomed via a generated message, and logged throughout via a shared logging utility. All known issues from the Chapter 2 audit have since been resolved.)*

### Chapter 3 — Remote Workforce (in progress)
- [x] Task 1 — SSH Server Setup & Hardening Baseline
- [x] Task 2 — SSH Key-Pair Generation & Distribution
- [x] Task 3 — Automated SSH Key Provisioning
- [x] Task 4 — Disabling Password Authentication
- [ ] Task 5 — Disabling Direct Root Login
- [ ] Task 6 — Fail2Ban Installation & Configuration
- [ ] Task 7 — Remote Access Validation & Testing
- [ ] Task 8 — Security Audit

*(SSH server installed and hardened; 78 of 85 employees now have working SSH key pairs, verified via live login tests; password authentication disabled system-wide with a single deliberate exception preserved for server administration.)*

## Environment

Built and tested on Ubuntu (WSL2).

## Author

Ruth Akinlabi


