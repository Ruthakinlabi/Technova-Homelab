# Chapter 3, Task 4 — Disabling Password Authentication

## Business Requirement

Every employee who needs SSH access now has a working key pair — 3 set up manually in Task 2, 75 more provisioned automatically in Task 3, covering 78 of TechNova's 85 accounts (the other 7 are locked/offboarded or aren't a real employee). With key-based access fully in place, the CTO's original mandate can finally be acted on: **"Before anyone logs in from Abuja, I want passwords out of the equation entirely."**

Right now, password login is still allowed system-wide. As long as that stays true, an attacker doesn't need to break a strong SSH key — they can just try the weak, still-shared `Technova2026` password on any account that hasn't changed it yet. This task closes that door permanently, while keeping one deliberate exception: `ruth1`, the account actually administering this server, keeps password access as a safety net.

## What This Task Does — and Doesn't — Change

Two separate systems are involved here, worth keeping distinct:
1. **SSH authentication** — "prove who you are to get in at all." This is what this task controls.
2. **Linux's own password-expiry check** (`chage`, `passwd -e`) — runs *after* someone is already logged in via key, separately asking "does this account's password need updating?" This task does not touch that — it's a different, harmless, pre-existing Chapter 2 condition that will keep appearing for accounts that haven't logged in yet, regardless of this change.

After this task: **a password alone gets you nowhere** for any account except `ruth1`. SSH refuses it outright, before a login attempt even gets that far.

## Step 1: Edit the Configuration

```bash
sudo nano /etc/ssh/sshd_config
```

Intended change:
```
PasswordAuthentication no

Match User ruth1
    PasswordAuthentication yes
```

`PasswordAuthentication no` applies globally. The `Match User ruth1` block creates an exception — SSH reads rules top-to-bottom, and settings inside a matched block override the global ones just for that user.

## Error 1 — The Change Was Never Actually Un-Commented

**First attempt at verification revealed the real, effective setting hadn't changed at all:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T | grep -i passwordauthentication
passwordauthentication yes
```

**Checking the file directly showed why:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo cat /etc/ssh/sshd_config | grep -A3 "PasswordAuthentication"
#PasswordAuthentication no

#Match User ruth1
    #PasswordAuthentication yes
```

**In plain terms:** every new line still had a `#` in front of it. A `#` marks a line as a comment — inert documentation that SSH ignores completely, not an active setting. The edit added the right words in the right place, but never actually turned anything on. SSH kept using its original default (`yes`) because, as far as it could tell, nothing had told it otherwise.

**Fix:** removed every `#` from the new lines:
```
PasswordAuthentication no

Match User ruth1
    PasswordAuthentication yes
```

## Error 2 — The Match Block Accidentally Swallowed an Unrelated Setting

**Running the validation check (correctly, this time, *before* restarting) caught a second problem immediately:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -t
/etc/ssh/sshd_config line 98: Directive 'UsePAM' is not allowed within a Match block
```

**In plain terms:** a `Match` block in SSH's config doesn't just apply to the lines directly inside it — it applies to **everything below it, until the file ends or another Match block starts**. Since the `ruth1` exception was placed in the middle of the file, every setting that came after it — including an unrelated pre-existing line, `UsePAM yes` — got unintentionally pulled inside that block. `UsePAM` happens to be one of a handful of settings SSH refuses to let a `Match` block touch at all, so it rejected the whole file rather than silently doing something wrong.

**Why this didn't break anything:** because `sudo sshd -t` was run *before* restarting the service, SSH caught the problem while the *old, working* configuration was still active and running. This is exactly the value of testing a config before applying it — the attempted restart that followed did fail (`Job for ssh.service failed`), but only because SSH correctly refused to load a broken file — the server never actually went down or locked anyone out.

**Fix:** moved the `Match User ruth1` block to the **very last lines of the entire file**, so it has nothing left below it to accidentally capture.

## Error 3 — A Missing Runtime Directory

**Next check still failed, but with an unrelated message:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -t
Missing privilege separation directory: /run/sshd
```

**In plain terms:** SSH needs a small working directory at `/run/sshd` to operate, normally created automatically when the service starts. `/run` is a special location that gets wiped clean automatically (e.g. on a WSL restart) — it's meant to be rebuilt fresh each time, not something that should ever need to persist. This wasn't a config mistake at all — just an environment detail that had gone missing.

**Fix:**
```bash
sudo mkdir -p /run/sshd
```

## Final Verification — Everything Confirmed Working

```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -t
```
No output — config is now valid.

```
ruth1@DESKTOP-DD7VGNC:~$ sudo service ssh restart
```
Succeeded cleanly.

**Checking the real, effective settings — not just what we think we wrote:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T | grep -i passwordauthentication
passwordauthentication no
```
✅ Password authentication is now genuinely disabled by default.

```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T -C user=ruth1 | grep -i passwordauthentication
passwordauthentication yes
```
✅ `ruth1`'s exception is correctly active.

```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T -C user=mosei | grep -i passwordauthentication
passwordauthentication no
```
✅ A regular employee correctly falls under the global `no` setting, not the exception.

**Live proof, an actual login attempt:**
```
ruth1@DESKTOP-DD7VGNC:~$ ssh mosei@localhost
mosei@localhost: Permission denied (publickey).
```
✅ SSH now refuses a password-only attempt outright — no password prompt is even offered. The message itself, `Permission denied (publickey)`, confirms SSH is now only willing to consider a key, exactly as intended.

## Important Note on the Earlier "Successful" Password Logins

Before Error 1 was caught and fixed, `mosei@localhost` and `ruth1@localhost` were both tested and **did** log in with a password — this looked like proof the change worked, but was actually proof it hadn't taken effect at all yet, since the config was still fully commented out at that point. This is a useful lesson in itself: a login *succeeding* isn't enough evidence a security change worked — checking the actual effective configuration (`sshd -T`) is what caught the real state of things, rather than trusting a test that happened to pass for the wrong reason.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Config syntax valid (`sshd -t`) | No errors | ✅ Pass (after 3 fixes) |
| Global password auth disabled | `passwordauthentication no` | ✅ Confirmed via `sshd -T` |
| `ruth1` exception active | `passwordauthentication yes` for ruth1 specifically | ✅ Confirmed via `sshd -T -C user=ruth1` |
| Regular employee follows global setting | `passwordauthentication no` for mosei | ✅ Confirmed via `sshd -T -C user=mosei` |
| Live password-only login attempt rejected | `Permission denied (publickey)` | ✅ Confirmed |
| Key-based login still works | Unaffected | ✅ Confirmed (`ybalarabe`, prior to the fix, unaffected throughout) |

## Errors Encountered — Summary

1. **New config lines left commented out (`#`)** — the setting was never actually active despite looking correct; caught by checking `sshd -T` (the real, effective config) rather than assuming the file edit worked.
2. **`Match` block placed mid-file, accidentally capturing `UsePAM`** — `Match` blocks apply to everything below them, not just their own indented lines; fixed by moving the block to the very end of the file.
3. **Missing `/run/sshd` directory** — an environment/runtime issue, not a config mistake; fixed with `sudo mkdir -p /run/sshd`.

Each error was caught by `sudo sshd -t` *before* a restart was allowed to proceed with faulty config — confirming the value of validating before applying, exactly as intended by using that command at all.

## Status

**✅ Completed**

Password authentication is now disabled system-wide, with a single deliberate exception preserved for `ruth1`, the account administering this server. Confirmed through the authoritative effective-configuration check (`sshd -T`), not just a login attempt, and further confirmed with a live rejected password-only login for a regular employee account.
