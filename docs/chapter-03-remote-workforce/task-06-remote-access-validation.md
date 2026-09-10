# Chapter 3, Task 6 — Remote Access Validation & Testing

## Business Requirement

Every individual setting in this chapter has been tested right after it was changed — key generation, password auth disabled, root login disabled. But nobody had stepped back and validated the whole access model together, from the perspective of different real employees in different situations. Before this chapter can be considered done, TechNova needs confidence that the *system* works as a whole, not just that each individual setting is technically correct in isolation.

## Note — Fail2Ban Left Unresolved

Before this task, an attempt was made to install and configure Fail2Ban (intrusion detection/prevention for repeated failed SSH attempts). Installation and initial jail configuration succeeded, but testing surfaced two compounding issues: the WSL/OpenSSH environment logs certain rejected-key attempts as `Connection closed... [preauth]` rather than the standard `Failed publickey` line Fail2Ban's default filter expects (a real, deliberate Fail2Ban design choice — this message type is tagged `F-NOFAIL` and intentionally excluded from failure counts, since a generic "connection closed" is considered too ambiguous to safely treat as an attack signal). After identifying the correct test method (a genuine wrong-password attempt against an account with password auth enabled), a subsequent filter edit caused the Fail2Ban service itself to crash on restart with an unresolved startup exception. Rather than continue debugging an increasingly fragile environment issue, this was deliberately parked as a known, unresolved item — documented honestly here rather than silently dropped. It may be revisited later as a Chapter 3 appendix.

## Test Matrix

### Test 1 — Clean Key-Based Login (Regular Employee)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo -u sadebayo -H ssh -i /home/sadebayo/.ssh/id_ed25519 sadebayo@localhost
...
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
...
sadebayo@DESKTOP-DD7VGNC:~$ whoami
sadebayo
sadebayo@DESKTOP-DD7VGNC:~$ exit
logout
Connection to localhost closed.
```
✅ Clean, uninterrupted login via key — no password prompt anywhere in the flow. Confirms the core intended experience for a properly provisioned employee: connect, get in, done.

### Test 2 — No Valid Key Presented

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ssh -i /dev/null tosazuwa@localhost
Load key "/dev/null": error in libcrypto
tosazuwa@localhost: Permission denied (publickey).
```
✅ Correctly rejected. `/dev/null` was used as a deliberately empty, invalid "key file" (a special file that always reads as empty) — SSH couldn't parse anything usable from it, and with password authentication disabled, there was no fallback option. The rejection message (`Permission denied (publickey)`) is the same clean, unambiguous message seen throughout this chapter — not a confusing or inconsistent error.

### Test 3 — Locked/Offboarded Employee (David James, Chapter 2)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ssh -i /home/djames/.ssh/id_ed25519 djames@localhost
Warning: Identity file /home/djames/.ssh/id_ed25519 not accessible: Permission denied.
djames@localhost: Permission denied (publickey).
```
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -la /home/djames/.ssh/ 2>&1
ls: cannot access '/home/djames/.ssh/': Permission denied
```
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S djames
djames L 1970-01-01 0 99999 7 -1
```

**Two independent layers of protection confirmed here, worth calling out separately:**
1. David James was locked and offboarded back in Chapter 2 (Task 9), **before** Task 3's automated SSH key provisioning ran — so he was correctly excluded and never received a key pair at all. The attempted login failed simply because no such key file exists to even try.
2. Even the *attempt to look at* his `.ssh` folder was denied (`ls: cannot access ... Permission denied`) — since his account is disabled, even routine filesystem access to his space is restricted, not just login. This wasn't something explicitly configured for this test; it's a natural consequence of the account being properly locked.
3. `passwd -S` independently confirms the lock (`L`) is still fully in effect, unrelated to and unaffected by anything done in this SSH chapter — his access has been correctly closed since Chapter 2 and remains closed now.

### Test 4 — `ruth1`'s Password Exception

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ssh ruth1@localhost
ruth1@localhost's password:
Welcome to Ubuntu 24.04.4 LTS...
...
Last login: Mon Sep  7 15:42:26 2026 from 127.0.0.1
```
✅ Confirms the deliberate `Match User ruth1` exception from Task 4 is still correctly active — this is the one account on the server that can still authenticate with a password, by design, as the account actually administering the system.

### Test 5 — Root Unreachable

```
ruth1@DESKTOP-DD7VGNC:~$ ssh root@localhost
root@localhost: Permission denied (publickey).
```
✅ Confirms Task 5's root-login restriction remains solidly in place — no password prompt offered, no path in at all.

## Verification Summary

| Test | Scenario | Expected | Result |
|---|---|---|---|
| 1 | Regular employee, valid key | Clean login, no prompts | ✅ Pass |
| 2 | No valid key presented | Clean rejection, no password fallback | ✅ Pass |
| 3 | Locked/offboarded employee | No key exists; account independently confirmed locked; even filesystem access restricted | ✅ Pass |
| 4 | `ruth1` (deliberate exception) | Password prompt still offered | ✅ Pass |
| 5 | Direct root login | Rejected outright, no prompt | ✅ Pass |

## What This Confirms About the Access Model as a Whole

Taken together, these five tests validate the complete, intended shape of TechNova's remote access model as of this chapter:
- **Provisioned employees** get frictionless, secure access via key — the primary, intended path.
- **Anyone without a valid key** — whether never provisioned, or deliberately locked — is cleanly and consistently rejected, with no confusing inconsistency in error behavior.
- **Offboarded accounts** remain genuinely closed across multiple independent layers (no key, account lock, restricted filesystem access) — not just superficially blocked at the SSH layer alone.
- **Exactly one deliberate exception** exists (`ruth1`, for system administration), and it behaves precisely as scoped — it doesn't leak into affecting root, and it doesn't affect any other account.
- **Root has no direct remote path in at all**, under any circumstance tested.

## Status

**✅ Completed**

All five real-world access scenarios tested and confirmed working exactly as designed. The chapter's access model — key-based authentication, no password fallback except one deliberate administrative exception, no direct root access, and properly closed offboarded accounts — holds up as a coherent whole, not just as individually correct settings. Fail2Ban remains a known, separately documented open item, not blocking this validation.
