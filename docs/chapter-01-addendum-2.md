# Appendix 2 — Username Standardization

## Business Requirement

During Chapter 1, several usernames were created as informal shortened forms (`goko`, `sade`, `djam`, `dibr`, `faki`, `saki`, `raki`) rather than following the `first-initial + surname` convention used for the rest of the company (`eadeyemi`, `mogunleye`, `ebello`). This was flagged and formally documented as an accepted deviation back in Task 3.

Revisiting it now: with the company scaling (Appendix 1's four new departments, and Chapter 2's 70-employee automated onboarding coming up), management decided the shortened usernames don't look professional enough for a growing company, and asked IT to standardize every account to the same first-initial-surname format before automation begins. Doing this now, before Chapter 2, also means the onboarding script won't need to handle two different naming styles — one predictable format start to finish.

## Renaming Convention

`first initial + full surname`, all lowercase — matching the format already used for `eadeyemi`, `mogunleye`, `ebello`, `ceze`, and `dojo` since Task 3.

| Old Username | Real Name | New Username |
|---|---|---|
| `goko` | Grace Okoro | `gokoro` |
| `sade` | Sunday Adebayo | `sadebayo` |
| `djam` | David James | `djames` |
| `dibr` | Deborah Ibrahim | `dibrahim` |
| `faki` | Favour Akinyemi | `fakinyemi` |
| `saki` | Samuel Akinwale | `sakinwale` |
| `raki` | Ruth Akinlabi | `rakinlabi` |
| `bnwa` | Blessing Nwachukwu | `bnwachukwu` |

(`ceze` and `dojo` already matched the convention — no change needed.)

## Command Used, Explained

```bash
sudo usermod -l gokoro -d /home/gokoro -m goko
```

`usermod` is the command for modifying an *existing* Linux user account (as opposed to `useradd`, which creates a new one). This single command does three separate things at once, one per flag:

- **`-l gokoro`** — the `-l` (lowercase L) flag changes the account's **login name**. This is the actual rename: the system will now recognize `gokoro` as the username instead of `goko`. Important: this does *not* change the UID (user ID number) — internally, Linux still treats this as "the same person," just with new login text. This matters because permissions, file ownership, and group membership are all tracked by UID, not by name, so nothing about the account's actual access changes.
- **`-d /home/gokoro`** — the `-d` flag sets the account's new **home directory path**. Without this, the account would be renamed to `gokoro` but Linux would still expect her home folder to be at the old path `/home/goko` — a mismatch that causes login issues and confusion.
- **`-m`** — this tells `usermod` to **physically move** the contents of the old home directory (`/home/goko`) to the new path (`/home/gokoro`) specified by `-d`. Without `-m`, the *setting* would point to the new path, but the actual folder and its files would stay behind at the old location — `-m` is what makes the two agree.

The last argument, `goko`, is the account's **current** (soon to be old) username — `usermod` needs to know which existing account to modify.

So in plain terms: *"Rename the account currently called `goko` to `gokoro`, and move her home folder from `/home/goko` to `/home/gokoro` to match."*

This same command, with only the names changed, was run for all seven renames plus Blessing's:

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l gokoro -d /home/gokoro -m goko
[sudo] password for ruth1:
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l sadebayo -d /home/sadebayo -m sade
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l djames -d /home/djames -m djam
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l dibrahim -d /home/dibrahim -m dibr
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l fakinyemi -d /home/fakinyemi -m faki
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l sakinwale -d /home/sakinwale -m saki
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l rakinlabi -d /home/rakinlabi -m raki
```

All seven completed with no errors or output — `usermod` stays silent on success, which is normal Linux behavior (no output = nothing went wrong).

## Verification

```bash
getent passwd gokoro sadebayo djames dibrahim fakinyemi sakinwale rakinlabi
```

`getent passwd <username>` looks up an account's full record from the system's user database (the same data `/etc/passwd` holds) — it's the standard way to confirm an account's UID, group, home directory, and shell all in one line, without needing to open `/etc/passwd` directly.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd gokoro sadebayo djames dibrahim fakinyemi sakinwale rakinlabi
gokoro:x:1004:1003:Grace Okoro:/home/gokoro:/bin/bash
sadebayo:x:1005:1003:Sunday Adebayo:/home/sadebayo:/bin/bash
djames:x:1006:1003:David James:/home/djames:/bin/bash
dibrahim:x:1010:1005:Deborah Ibrahim:/home/dibrahim:/bin/bash
fakinyemi:x:1011:1005:Favour Akinyemi:/home/fakinyemi:/bin/bash
sakinwale:x:1008:1004:Samuel Akinwale:/home/sakinwale:/bin/bash
rakinlabi:x:1009:1004:Ruth Akinlabi:/home/rakinlabi:/bin/bash
```

✅ Every account now shows the new username, and critically, the **same UID as before** (e.g. `gokoro` is still UID `1004`, exactly as `goko` was) — proving the rename didn't create a new account, it renamed the existing one in place. Home directories also correctly updated to match.

## Confirming the Locked Account Survived the Rename

David James (`djames`, formerly `djam`) was offboarded and locked back in Task 9. Since renaming touches the account record, it was worth explicitly confirming the lock wasn't accidentally reset:

```bash
sudo passwd -S djames
```

`passwd -S` reports an account's **password status** in a compact code — whether it has a password set, whether it's locked, and expiration details.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S djames
djames L 1970-01-01 0 99999 7 -1
```

✅ Status still shows `L` (locked) — confirms the offboarding restriction carried over correctly through the username change. This makes sense because `usermod -l` only touches the login name and home directory; it doesn't touch the password/lock state at all, which lives in a separate part of the account record.

## Company-Wide Roster Check

To sanity-check every account on the system after all the renames, the following was run:

```bash
getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $5}'
```

Breaking this down:
- **`getent passwd`** (no username given) — lists *every* account record on the system, one per line, instead of looking up a specific user.
- **`awk -F: '...'`** — `awk` is a text-processing tool for working line by line with structured data. `-F:` tells it that fields in each line are separated by colons (`:`), which matches the format of a passwd entry (`username:x:UID:GID:full name:home:shell`).
- **`$3 >= 1000 && $3 < 65534`** — this is a filter condition. `$3` refers to the third colon-separated field, which is the UID. Real human user accounts on Ubuntu start at UID 1000; system/service accounts (which you don't want cluttering a roster) use lower numbers. `65534` is excluded as it's reserved for the `nobody` account. So this line says: "only show rows where the UID is a real human account."
- **`{print $1, $3, $5}`** — for every line that passes the filter, print field 1 (username), field 3 (UID), and field 5 (full name/GECOS field) — skipping the password placeholder, home directory, and shell, which weren't needed for a quick roster.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $5}'
ruth1 1000 ,,,
eadeyemi 1001 Emmanuel Adeyemi
mogunleye 1002 Miceal Ogunleye
ebello 1003 Esther Bello
dojo 1007 Daniel Ojo
ceze 1012 Chioma Eze
bnwa 1013 Blessing Nwachukwu
tajayi 1014 Tobiloba Ajayi
neke 1015 Ngozi Eke
kuche 1016 Kingsley Uche
anwosu 1017 Amaka Nwosu
gokoro 1004 Grace Okoro
sadebayo 1005 Sunday Adebayo
djames 1006 David James
dibrahim 1010 Deborah Ibrahim
fakinyemi 1011 Favour Akinyemi
sakinwale 1008 Samuel Akinwale
rakinlabi 1009 Ruth Akinlabi
```

This output caught one account that hadn't been renamed yet: **`bnwa` (Blessing Nwachukwu)** — still showing the old shortened username, unlike the seven that had already been fixed. This is exactly why running a full roster check after a batch of changes is useful — it surfaces gaps a one-by-one checklist can miss.

## Fixing the Missed Account

```bash
sudo usermod -l bnwachukwu -d /home/bnwachukwu -m bnwa
```

Same command pattern as before — renamed `bnwa` to `bnwachukwu`, moved her home directory to match.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo usermod -l bnwachukwu -d /home/bnwachukwu -m bnwa
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd bnwachukwu
bnwachukwu:x:1013:1002:Blessing Nwachukwu:/home/bnwachukwu:/bin/bash
```

✅ Confirmed — same UID (`1013`) as before, new username and home directory applied correctly.

## Final Username Reference (Post-Standardization)

| Department | Admin | Employees |
|---|---|---|
| Engineering | `eadeyemi` | `mogunleye`, `ebello`, `bnwachukwu` |
| Sales | `gokoro` | `sadebayo`, `djames` (offboarded, locked) |
| Finance | `dibrahim` | `ceze`, `fakinyemi` |
| HR | `dojo` | `sakinwale`, `rakinlabi` |
| Marketing | `tajayi` | — |
| Customer Support | `neke` | — |
| Product Management | `kuche` | — |
| DevOps | `anwosu` | — |

## Why This Matters

Every rename preserved the account's UID, meaning nothing about actual file ownership, group membership, or permissions changed — only the human-readable label did. This is an important distinction to understand: Linux permissions are fundamentally built on numeric IDs, not names, so an operation like this is safe to perform on a live system without breaking anything downstream, as long as `-d` and `-m` are used together to keep the home directory in sync with the new name.

## Status

**✅ Complete**

All eight informally-named accounts standardized to the `first-initial + surname` convention. UIDs preserved throughout (confirming no data or permission loss). Offboarded account (`djames`) confirmed to retain its locked status through the rename. One account (`bnwa`) was missed in the initial pass and caught via a full roster check, then corrected.
