# Chapter 4, Task 1 — Deciding What to Back Up

## The Situation

Someone accidentally deleted an important file at TechNova, and there was no way to get it back. It was gone for good. That's what started this whole chapter — management wants to make sure that never happens again.

The easy answer would be "just back up everything." But that's actually not a good plan. If you back up *everything*, including things that don't matter or that already exist safely somewhere else, you waste time and space, and it gets harder to find what actually matters when you really need it.

So before writing anything that actually creates backups, the first job is simpler: **decide exactly what's worth saving, what isn't, and why.**

## How We Decided What to Back Up

We asked one simple question about everything on the server: **"If this got deleted right now, could we get it back some other way, or would it be gone forever?"**

- If it would be gone forever → back it up.
- If we could easily get it back another way → don't bother backing it up.

## What We're Backing Up (and Why)

| What it is | Why it matters |
|---|---|
| Department folders (handbooks, private documents, staff lists) | If these are deleted, there's no way to recreate them. Nobody remembers a private company document word-for-word. |
| Records of employees who have left the company | These are kept on purpose, in case they're ever needed later. Losing them defeats the whole reason they were saved. |
| The settings that control secure remote login | This took a lot of real trial-and-error to get working correctly. Losing it means doing all that work over again from scratch. |
| The settings for the security tool that blocks suspicious login attempts | Same reason — real effort went into this, even though the tool itself isn't fully working yet. |
| The list of "approved logins" for each employee | If this is lost, every single employee gets locked out of the server at the same time. That's a big deal, so it's worth protecting. |

## What We're NOT Backing Up (and Why That's OK)

| What it is | Why we're skipping it |
|---|---|
| The project's own file history on GitHub | This is already safely stored online. Backing it up again here would just be doing the same job twice. |
| Old spreadsheets and log files from earlier automation work | Interesting to look back on, but nothing currently depends on them. The actual results of that work (real employee accounts) don't disappear if these files do. |
| Employees' private secret keys used to log in | This one's on purpose, not a mistake. A "private" key that's copied somewhere else stops being private. If someone loses their key, the right fix is to give them a brand new one — not dig up an old copy. |
| Basic account information built into the operating system itself | If the whole server had to be rebuilt from nothing, we already have detailed step-by-step notes from Chapters 1 through 3 showing exactly how to recreate it. |

## How Often We'll Back Things Up

**Once a day.** The files that matter most (department records) change fairly often — new people get added, documents get updated — so daily makes sense. The security settings barely ever change, but they're small, so there's no harm including them in the same daily backup instead of making things more complicated with a separate schedule.

## Where the Backup Will Actually Live

The backup copies will be stored in a separate folder, away from the original files. This protects against the exact mistake that started this whole chapter — someone accidentally deleting a file where the real, active data lives.

**Being honest about a limitation here:** a truly safe backup is normally stored on a completely separate device, or somewhere off-site — that way, if the whole computer breaks, the backup still survives. Right now, everything is running on one single computer, so the backup will technically still be sitting on the same machine as the original files. It's better than nothing (it protects against accidental deletion), but it wouldn't survive that one computer failing completely. This is a real limitation of the current setup, worth admitting honestly rather than pretending it's a perfect solution — and it's something we may improve on later.

## What's Done

We've now clearly decided: what to back up, what not to, how often, and where — along with honest reasons for every choice, including the one thing this plan doesn't fully solve yet.

Next: actually building the backup itself.
