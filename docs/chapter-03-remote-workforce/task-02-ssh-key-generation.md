# Chapter 3, Task 2 — SSH Key-Pair Generation & Distribution

## Business Requirement

With the SSH server confirmed running (Task 1), the next question is: how does an actual employee prove who they are, without typing a password? The answer is an **SSH key pair** — two mathematically linked files, one kept secret by the employee, one placed on the server. Task 3 will disable password login system-wide, so this has to be in place first, or every employee gets locked out with no way back in.

Realistically, generating and distributing individual key pairs for 85 employees by hand would be enormous manual effort — but understanding exactly how one key pair works, end to end, for a single employee is the foundation everything else in this chapter builds on. This task focuses on getting that mechanism right for a representative employee (`eadeyemi`, Engineering's admin) before considering how it might scale.

## What Is an SSH Key Pair?

Two files, always created together, that work as a matched set:
- **Private key** — stays only on the employee's own computer, never shared. This is the actual proof of identity.
- **Public key** — safe to share freely. This gets copied onto the server, into a file listing which public keys are allowed to log in as this user.

The two are mathematically linked so a match can be verified, but the private key can't practically be derived from the public one. When an employee connects, the server issues a cryptographic challenge only the correct private key can answer — proving identity without a password ever being transmitted.

## Why Permissions Matter So Much Here

With SSH keys, wrong permissions usually mean **it simply refuses to work at all** — a private key readable by others, or a `.ssh` folder that's too open, gets rejected outright by SSH itself, regardless of whether the key is correct. This is a deliberate built-in security measure, not a bug.

## Step 1: Generate the Key Pair

**First attempt — accidental double-paste error:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo -u eadeyemi -H ssh-keygen -t ed25519 -C "eadeyemi@technova.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/eadeyemi/.ssh/id_ed25519): sudo -u eadeyemi -H ssh-keygen -t ed25519 -C "eadeyemi@technova.com"sudo -u eadeyemi -H ssh-keygen -t ed25519 -C "eadeyemi@t
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Saving key "sudo -u eadeyemi -H ssh-keygen -t ed25519 -C "eadeyemi@technova.com"sudo -u eadeyemi -H ssh-keygen" failed: Permission denied
```
**What happened:** the "Enter file in which to save the key" prompt was waiting for a simple Enter keypress to accept the default location — instead, the entire command got sent a second time into that prompt, which `ssh-keygen` interpreted as a literal (invalid) filename, causing the save to fail. No key pair was created and no damage occurred; simply re-run the command.

**Successful attempt:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo -u eadeyemi -H ssh-keygen -t ed25519 -C "eadeyemi@technova.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/eadeyemi/.ssh/id_ed25519):
Created directory '/home/eadeyemi/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/eadeyemi/.ssh/id_ed25519
Your public key has been saved in /home/eadeyemi/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:KPADtKAVUtnQglZUp8URTwksHBtjCefcL0ybhoLJyDA eadeyemi@technova.com
```

**Command explained:**
- `ssh-keygen` — the tool that generates SSH key pairs.
- `-t ed25519` — the key algorithm; modern, fast, and secure, matching one of the three host key types generated in Task 1.
- `-C "eadeyemi@technova.com"` — a comment embedded in the public key purely for identification later.
- `sudo -u eadeyemi -H` — runs the command as `eadeyemi`, with his home directory correctly set, so the keys land in `/home/eadeyemi/.ssh/` rather than root's.

**Reading the output:** SSH automatically created the `.ssh` folder since it didn't exist. `id_ed25519` is the private key; `id_ed25519.pub` is the public key. The fingerprint and randomart image are both just human-readable ways to visually verify a key's identity at a glance — not something used further in this task.

## Step 2: Verify File Permissions After Generation

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /home/eadeyemi/.ssh/
total 8
-rw------- 1 eadeyemi engineering 411 Sep  7 02:50 id_ed25519
-rw-r--r-- 1 eadeyemi engineering 103 Sep  7 02:50 id_ed25519.pub
```
✅ Private key locked to `600` (owner-only) automatically by SSH; public key at `644` (world-readable), correct since it's meant to be shared.

## Step 3: Place the Public Key into `authorized_keys`

```bash
sudo -u eadeyemi -H bash -c 'cat /home/eadeyemi/.ssh/id_ed25519.pub >> /home/eadeyemi/.ssh/authorized_keys'
```

`authorized_keys` is the file SSH checks on every login attempt — it lists which public keys are allowed to authenticate as this user. `>>` (append, not overwrite) is used because this file can hold multiple keys (e.g. one per device), so appending preserves anything already listed. In a real company, the employee would generate their own key pair and send only the `.pub` file to IT — we're performing both roles here since we're simulating both sides.

## Step 4: Lock Down Permissions

```bash
sudo chmod 700 /home/eadeyemi/.ssh
sudo chmod 600 /home/eadeyemi/.ssh/authorized_keys
```
`700` on the folder: owner can read/write/enter, nobody else can access it at all. `600` on `authorized_keys`: same strict standard as the private key.

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -ld /home/eadeyemi/.ssh
drwx------ 2 eadeyemi engineering 4096 Sep  7 02:52 /home/eadeyemi/.ssh
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ls -l /home/eadeyemi/.ssh/
total 12
-rw------- 1 eadeyemi engineering 103 Sep  7 02:52 authorized_keys
-rw------- 1 eadeyemi engineering 411 Sep  7 02:50 id_ed25519
-rw-r--r-- 1 eadeyemi engineering 103 Sep  7 02:50 id_ed25519.pub
```
✅ All permissions correct.

## Step 5: Test the Key — First Attempt

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo -u eadeyemi -H ssh -i /home/eadeyemi/.ssh/id_ed25519 eadeyemi@localhost
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ED25519 key fingerprint is SHA256:5WVWHoLFJukkQc1Kk4b5SaGmrvmpOwM0psn7pY4fYFA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
You are required to change your password immediately (administrator enforced).
...
WARNING: Your password has expired.
You must change your password now and login again!
Changing password for eadeyemi.
Current password:
passwd: Authentication token manipulation error
passwd: password unchanged
Connection to localhost closed.
```

**Two things happening here, easy to conflate:**
1. The "authenticity of host" prompt is SSH verifying the **server's** host key (generated in Task 1) for the first time this client has ever connected — accepting it with `yes` permanently remembers this server's identity for future connections.
2. The password prompt afterward is **not** SSH falling back to password authentication — this needed direct verification, done in Step 6 below.

## Step 6: Verifying What Actually Happened, via Verbose Mode

```bash
sudo -u eadeyemi -H ssh -v -i /home/eadeyemi/.ssh/id_ed25519 eadeyemi@localhost
```

Key lines from the verbose log:
```
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: publickey
debug1: Offering public key: /home/eadeyemi/.ssh/id_ed25519 ED25519 SHA256:KPADtKAVUtnQglZUp8URTwksHBtjCefcL0ybhoLJyDA explicit
debug1: Server accepts key: /home/eadeyemi/.ssh/id_ed25519 ED25519 SHA256:KPADtKAVUtnQglZUp8URTwksHBtjCefcL0ybhoLJyDA explicit
Authenticated to localhost ([127.0.0.1]:22) using "publickey".
```

**This confirms unambiguously: SSH key authentication succeeded.** The login was authenticated `using "publickey"` — never password. The key generation, `authorized_keys` placement, and permissions were all correct on the very first real attempt.

**So why the password prompt?** It appears *after* this line:
```
debug1: Entering interactive session.
...
WARNING: Your password has expired.
You must change your password now and login again!
Changing password for eadeyemi.
```

This is Linux's own account-level password expiry policy (the same `passwd -e` mechanism from Chapter 2, Task 3) triggering as a **separate step after successful login**, regardless of how authentication happened. `eadeyemi`'s account still carried an expired password from Chapter 2, since it had never been logged into before. SSH correctly identified him via key — a completely different system then required a password change before allowing the session to proceed further, exactly as it would for a console login too.

The `passwd: Authentication token manipulation error` was friction from attempting the interactive password-change prompt through this particular session; it didn't indicate any problem with the key setup.

## Step 7: Successful Password Change, Confirming the Full Session Works

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo -u eadeyemi -H ssh -i /home/eadeyemi/.ssh/id_ed25519 eadeyemi@localhost
...
WARNING: Your password has expired.
You must change your password now and login again!
Changing password for eadeyemi.
Current password:
New password:
Retype new password:
passwd: password updated successfully
Connection to localhost closed.
```

✅ Key authentication succeeded again, and this time the forced password change also completed successfully — fully resolving the leftover Chapter 2 expired-password condition for this account as a side effect of this task.

## What This Confirms for the Rest of the Chapter

- SSH key generation, placement, and permissions all work correctly end-to-end.
- Key-based authentication is fully functional and independent of the account's password state.
- **Once Task 3 disables password authentication entirely**, the `Authentications that can continue: publickey,password` line will change to show only `publickey` — worth confirming explicitly when we get there, since it directly tests whether the change actually took effect.

## Errors Encountered — Summary

1. **Accidental double-paste into `ssh-keygen`'s file-location prompt** — caused an invalid filename and a failed save; resolved by simply re-running the command and waiting for each prompt individually.
2. **Password-change friction on first login attempt** (`Authentication token manipulation error`) — unrelated to SSH key setup; resolved by retrying the login and completing the password change cleanly on the second attempt.

## Status

**✅ Completed**

Generated a working SSH key pair for `eadeyemi`, correctly placed the public key in `authorized_keys`, set all required permissions, and verified — via verbose SSH output — that authentication genuinely occurred via the key, not a password fallback. A leftover expired-password condition from Chapter 2 was also resolved for this account as part of testing.
