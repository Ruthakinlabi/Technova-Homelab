# Chapter 3, Task 1 — SSH Server Setup & Hardening Baseline

## Business Requirement

TechNova is opening a second office in Abuja, and several employees have asked to work remotely a few days a week. Right now, every employee account authenticates with a password — acceptable when everyone logged in from the same building, but not once login attempts start coming from home networks and a different city entirely. Before any employee logs in remotely, the CTO wants passwords out of the equation altogether, replaced with SSH key-based authentication, direct root login disabled, and active defense against repeated login attempts.

Before any of that can happen, the server needs a properly configured SSH service to connect to in the first place. This task establishes that baseline: install the SSH server, back up its configuration before touching anything, review what's actually in it, and confirm it's running and reachable — setting up exactly what the rest of this chapter will build on.

## What Is SSH, and Why Does This Task Exist?

SSH (Secure Shell) is the standard way to log into a remote Linux server over a network, instead of sitting physically in front of it. Everything done in this project so far has been typed directly into your own machine. SSH is what would let an employee in Abuja, or working from home, log into TechNova's server from far away, securely.

Two separate pieces of software are involved:
- **SSH client** — the program *you* use to connect *out* to another machine.
- **SSH server** (`sshd` — "SSH daemon") — the program that *listens* for incoming connections and lets people log *in*. This is what needs to be installed and configured before anyone can remotely access it.

This task installs and configures the server side, and reviews its default settings before making any real changes.

## Step 1: Check Whether the SSH Server Was Already Installed

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ dpkg -l | grep openssh-server
```
`dpkg -l` lists every installed package on the system. Piping it through `grep openssh-server` filters that list down to just the package we care about. No output meant it wasn't installed yet.

## Step 2: Update the Package List, Then Install OpenSSH Server

```bash
sudo apt update
```
Refreshes Ubuntu's local record of what software versions are currently available — doesn't install or change anything, just prepares for the next command.

```bash
sudo apt install openssh-server -y
```
Installs the SSH server software. `-y` automatically answers "yes" to any prompts so the install runs without pausing.

**What happened during installation:**
```
Creating SSH2 RSA key; this may take some time ...
3072 SHA256:MEdfkbuKJqJE96+kRYWgrq3uWvWiX5bd9xAnPnNLRvc root@DESKTOP-DD7VGNC (RSA)
Creating SSH2 ECDSA key; this may take some time ...
256 SHA256:zLRAOunXVDXbeVPQuMUj/wy09TXYkvQWckU17jk5WNM root@DESKTOP-DD7VGNC (ECDSA)
Creating SSH2 ED25519 key; this may take some time ...
256 SHA256:5WVWHoLFJukkQc1Kk4b5SaGmrvmpOwM0psn7pY4fYFA root@DESKTOP-DD7VGNC (ED25519)
```

The SSH server has its own identity, proven with cryptographic keys — three types generated (RSA, ECDSA, ED25519, different algorithms for the same purpose), called **host keys**. Their job: let a connecting client verify "am I actually talking to TechNova's real server, or has someone intercepted this connection?" This is different from the *employee* keys Task 2 will create:
- Host keys (this task): "Is this server who it claims to be?"
- Employee keys (Task 2): "Is this person who they claim to be?"

```
Creating config file /etc/ssh/sshd_config with new version
```
The server's configuration file was created fresh during installation at `/etc/ssh/sshd_config`.

## Step 3: Start and Confirm the SSH Service

**Before starting:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo service ssh status
○ ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: inactive (dead)
TriggeredBy: ● ssh.socket
```
"Loaded" means the system knows the service exists; `Active: inactive (dead)` meant it wasn't running yet — nobody could connect at this point.

**Starting it:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo service ssh start
```
No output on success — normal for this command.

**Confirming it's running:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo service ssh status
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: active (running) since Mon 2026-09-07 02:28:10 PDT; 1min 6s ago
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 2503 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 2505 (sshd)
      Tasks: 1 (limit: 4604)
     Memory: 1.2M (peak: 1.6M)
        CPU: 45ms
     CGroup: /system.slice/ssh.service
             └─2505 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Sep 07 02:28:10 DESKTOP-DD7VGNC systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Sep 07 02:28:10 DESKTOP-DD7VGNC sshd[2505]: Server listening on 0.0.0.0 port 22.
Sep 07 02:28:10 DESKTOP-DD7VGNC sshd[2505]: Server listening on :: port 22.
Sep 07 02:28:10 DESKTOP-DD7VGNC systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

**Reading this output, piece by piece:**
- `Active: active (running)` — confirms the service is genuinely up, not just installed.
- `Main PID: 2505 (sshd)` — the actual process ID of the running SSH server; useful if you ever need to check on or stop this specific process directly.
- `Server listening on 0.0.0.0 port 22` — this is the key confirmation. "Listening" means the server is actively waiting for incoming connection attempts. `0.0.0.0` means it will accept connections addressed to any of the machine's network addresses (as opposed to only one specific one), and `port 22` confirms it's using SSH's standard port, matching the `#Port 22` default seen in the config file.
- The second `listening` line (`::`) is the same thing, just for IPv6 instead of IPv4 — modern systems typically listen on both address types simultaneously.

✅ SSH is now genuinely active and ready to accept connections.

## Step 4: Back Up the Configuration File Before Changing Anything

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```
Creates an exact duplicate of the live config, saved under a different name. If a future change breaks something, this untouched backup restores the original instantly.

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l /etc/ssh/sshd_config*
-rw-r--r-- 1 root root 3517 Aug 31 11:38 /etc/ssh/sshd_config
-rw-r--r-- 1 root root 3517 Sep  7 02:23 /etc/ssh/sshd_config.bak
```
Both files, same size (3517 bytes) — confirms an accurate, complete backup.

## Step 5: Reviewing the Default Configuration File

Most of `/etc/ssh/sshd_config` is comments (`#`) showing default values; an uncommented line actively overrides that default. The lines that matter for this chapter:

**`#Port 22`** — the network "door number" SSH listens on. Default, unchanged — matches what we just confirmed live in Step 3.

**`#PermitRootLogin prohibit-password`** — controls whether `root` can log in directly over SSH. Relevant to **Task 4** — direct root login is a major risk since `root` has unrestricted power over the whole system.

**`#PasswordAuthentication yes`** — controls whether password login is allowed at all. Currently allowed by default. This is exactly what **Task 3** will disable — the core of this chapter's shift away from passwords.

**`#PubkeyAuthentication yes`** — controls whether SSH key-based login is allowed. Already defaulted to `yes` — good, since this is the method **Task 2** will set up for every employee.

**`KbdInteractiveAuthentication no`** — an active (uncommented) setting disabling an older interactive-prompt login style. Already correctly `no`.

**`UsePAM yes`** — confirms SSH uses Linux's standard login-handling system rather than something custom. Left as default.

**`Subsystem sftp /usr/lib/openssh/sftp-server`** — enables secure file transfer over SSH. Not used yet, but available.

## What This Review Sets Up for the Rest of the Chapter

- `PubkeyAuthentication yes` already on → Task 2 can proceed with confidence.
- `PasswordAuthentication yes` (default) → Task 3 flips this to `no`.
- `PermitRootLogin prohibit-password` (default) → Task 4 tightens this further.

## Note on Existing Employee Accounts

Several of the 85 employee accounts from Chapter 2 have never been logged into, meaning they still technically hold the original shared temporary password rather than one the employee chose. Left as-is deliberately, rather than logging into 66+ accounts purely to trigger a change with no real practice value. This becomes a non-issue once Task 3 disables password authentication system-wide — none of these accounts will be reachable by password at all going forward, changed or not.

## Status

**✅ Completed**

OpenSSH server installed, host keys generated, service confirmed genuinely active and listening on port 22 (both IPv4 and IPv6), configuration backed up before any edits, and default settings reviewed line-by-line against this chapter's goals.

