# Chapter 4, Task 1 — Backup Strategy & Scope

## Business Requirement

A developer's deleted file can't be recovered — that incident is already over, but it forced a question TechNova has never had to answer before: what happens the next time this happens? Management's instruction is simple to state and easy to get wrong in practice: make sure this doesn't happen again without a way back. But "back everything up" isn't a real plan. Before any backup script gets written, TechNova needs an actual decision about what gets backed up, how often, where, and — just as importantly — what deliberately doesn't.

## Design Principle Used to Decide Scope

The test applied to everything on the server: **is this irreplaceable, or is it regenerable from something else that's already safe?** Irreplaceable data goes in the backup. Regenerable data is deliberately left out, with the reasoning documented — not because it wasn't considered, but because backing it up would add noise without adding real protection.

## In Scope — Backed Up Daily

| Item | Path | Why |
|---|---|---|
| Department data | `/srv/technova/departments/` | Handbooks, confidential files, and responsibility matrices — if lost, nobody can recreate them from memory. |
| Archived former employees | `/srv/technova/archived_employees/` | This data exists specifically to be preserved for audit purposes (Chapter 2, Task 6's disable-don't-delete decision). Losing it defeats the reason it was archived in the first place. |
| SSH server configuration | `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config.bak` | Represents real, hard-won configuration work from Chapter 3 (three separate debugging sessions' worth). Losing it means re-solving already-solved problems. |
| Fail2Ban configuration | `/etc/fail2ban/jail.local` | Same reasoning — the configuration effort shouldn't be lost even while the service itself is pending a fix. |
| Employee `authorized_keys` files | `/home/*/.ssh/authorized_keys` | If lost, every employee's SSH access breaks simultaneously, even though their own private keys remain safe on their own machines. A single point of failure worth protecting. |

## Explicitly Out of Scope — With Reasoning

| Item | Why Excluded |
|---|---|
| The `Technova-Homelab` Git repository | Already continuously backed up via GitHub. A second local backup would be redundant. |
| `scripts/data/*.csv`, `onboarding_log.txt`, `credentials_log.txt` | Working artifacts from Chapter 2's automation runs. Historically interesting, not currently load-bearing — the accounts they created still exist and function independently of these files. |
| Employee **private** SSH keys (`id_ed25519`) | Deliberately excluded on principle, not oversight. A private key that exists in two places is no longer fully private, which undermines the entire point of key-based authentication built in Chapter 3. If an employee loses their private key, the correct real-world response is to generate a new key pair and update `authorized_keys` — not restore the old private key from backup. |
| General system account files (`/etc/passwd`, `/etc/group`, etc.) | A conscious scope decision for this project's current scale: if the whole system were lost, it would be rebuilt from the already-documented Chapter 1–3 process. Real companies at larger scale often do back these up — noted here as a boundary of this lab's current scope, not a gap nobody noticed. |

## Backup Frequency

**Daily**, for everything in scope. Department files change often enough (new hires added to matrices, occasional handbook edits) that daily makes sense. SSH/Fail2Ban configs change rarely, but they're small enough that including them in the same daily run adds negligible cost — simpler than maintaining a separate schedule just for infrequently-changing files.

## Backup Location — An Honest Limitation

Backups will be stored at `/srv/backups/` — a separate directory tree from `/srv/technova`, protecting against the specific incident that started this chapter (someone accidentally deleting a file *within* the department folders).

**This is not a true offsite or separate-media backup**, and that limitation is stated here deliberately rather than glossed over: this lab runs on a single WSL instance with no second disk, no separate machine, and no cloud storage configured. A backup on the same physical disk as the original data would not survive a full disk failure. This is a real, honest constraint of the environment, not an oversight — and it's the reason this chapter's task list includes an optional later task (Offsite/Secondary Copy) to explore what a genuinely separate backup location would look like, time permitting.

## Status

**✅ Completed**

Backup scope decided and documented: 5 categories of data identified as in-scope with individual justification, 4 categories explicitly excluded with reasoning, daily frequency selected based on actual data change patterns, and a clear-eyed limitation recorded regarding backup location within this lab's constraints.
