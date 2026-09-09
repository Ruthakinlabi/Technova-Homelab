# Chapter 3, Task 5 — Disabling Direct Root Login

## Business Requirement

`root` is the one account on this server with no restrictions at all — it can touch any file, any user, any process, no permission checks in the way. Every other account is limited to something (a department, a home folder, a set of permissions). `root` isn't limited to anything.

Before this task, the server's configuration didn't explicitly say "no one may log in directly as root over SSH." It wasn't actively being used that way, but leaving it unstated is exactly the kind of gap that becomes a real problem later — for example, if anyone ever set up a convenience SSH key for root, nothing would have stopped it.

This task closes that gap for good: nobody logs in *as* root directly. Anyone who needs root-level power logs in as themselves first, then uses `sudo` for that one specific action — the same pattern already used for every privileged command throughout this entire project.

## Step 1: Check the Current Setting

```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T | grep -i permitrootlogin
Missing privilege separation directory: /run/sshd
```

## Error — Missing `/run/sshd` (Same Cause as Task 4)

This is the identical issue hit during Task 4: `/run/sshd` is a working directory SSH needs, but `/run` gets wiped clean automatically whenever the WSL instance restarts — it's meant to be rebuilt fresh each time, not something that persists. Not a config mistake, just an environment detail that goes missing between sessions.

**Fix:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo mkdir -p /run/sshd
```

## Step 2: Edit the Configuration

```bash
sudo nano /etc/ssh/sshd_config
```

Changed:
```
#PermitRootLogin prohibit-password
```
To:
```
PermitRootLogin no
```

Placed near the top of the file, **before** the `Match User ruth1` block added in Task 4 — this ensures the setting applies globally, with no exception for any account, including `ruth1`. Root login should never be allowed for anyone.

## Step 3: Validate Before Restarting

```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -t
Missing privilege separation directory: /run/sshd
```
Same error reappeared momentarily since the fix from Step 1 hadn't been applied yet in this exact sequence — resolved immediately after running `mkdir -p /run/sshd`:
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -t
```
No output — config is valid.

## Step 4: Restart and Confirm

```
ruth1@DESKTOP-DD7VGNC:~$ sudo service ssh restart
```

**Confirming the real, effective setting — globally:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T | grep -i permitrootlogin
permitrootlogin no
```
✅ Root login disabled by default.

**Confirming no exception exists for `ruth1` specifically:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo sshd -T -C user=ruth1 | grep -i permitrootlogin
permitrootlogin no
```
✅ Confirms the setting applies even to the account with the password-authentication exception from Task 4 — that exception was scoped only to `PasswordAuthentication`, not to root login, and the two remain correctly independent of each other.

## Step 5: Confirm `sudo` Is Completely Unaffected

```
ruth1@DESKTOP-DD7VGNC:~$ sudo whoami
root
ruth1@DESKTOP-DD7VGNC:~$ whoami
ruth1
```
✅ `sudo` still elevates correctly when needed, and the shell's actual logged-in identity remains `ruth1` at all other times — exactly the intended pattern: log in as yourself, elevate only for the specific command that needs it.

## Step 6: Live Test — Direct Root Login Attempt

```
ruth1@DESKTOP-DD7VGNC:~$ ssh root@localhost
root@localhost: Permission denied (publickey).
```
✅ Rejected immediately. SSH doesn't even offer a password prompt for root — it goes straight to denial, since root has no SSH key configured and password authentication is already disabled system-wide from Task 4. Two independent protections are now stacked on this one account.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Config validates before restart | No errors | ✅ Pass (after `/run/sshd` fix) |
| Global root login disabled | `permitrootlogin no` | ✅ Confirmed via `sshd -T` |
| No exception for `ruth1` | `permitrootlogin no` for ruth1 specifically | ✅ Confirmed via `sshd -T -C user=ruth1` |
| `sudo` unaffected | Elevates correctly, identity unchanged | ✅ Confirmed |
| Live root login attempt rejected | `Permission denied` | ✅ Confirmed |

## Errors Encountered — Summary

1. **Missing `/run/sshd` directory** — recurring WSL environment issue (also seen in Task 4), not a config mistake; fixed with `sudo mkdir -p /run/sshd`.

## Status

**✅ Completed**

Direct root login is now disabled system-wide, with no exceptions for any account. Confirmed through the authoritative effective-configuration check (`sshd -T`), confirmed independently for the `ruth1` account specifically, and confirmed live with a rejected root login attempt. Normal `sudo`-based privileged work remains completely unaffected.
