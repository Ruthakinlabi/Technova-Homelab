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

*(Chapter 1 was refined from an originally planned 15 tasks down to 9 high-quality ones — several validation-only tasks were consolidated into the final Security Audit rather than repeating tests already proven earlier in the chapter.)*

**Appendix 1 — Additional Departments:** Marketing, Customer Support, Product Management, and DevOps added to reflect company growth ahead of Chapter 2.

**Appendix 2 — Username Standardization:** all accounts normalized to a consistent `first-initial + surname` convention.

### Chapter 2 — Bash Automation
- [ ] Task 1 — Employee Data Source
- [ ] Task 2 — Automated User Provisioning
- [ ] Task 3 — Initial Password Generation
- [ ] Task 4 — Automated Directory Updates
- [ ] Task 5 — Logging and Error Reporting
- [ ] Task 6 — Bulk Offboarding
- [ ] Task 7 — Script Validation & Idempotency
- [ ] Task 8 — Automation Audit

## Environment

Built and tested on Ubuntu (WSL2).

## Author

Akinlabi Ruth
