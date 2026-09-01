# Chapter 2 — Addendum 2: Role Correction, GECOS Fix, Cumulative Reporting

Follow-up to Chapter 2's Task 8 Automation Audit and Addendum 1, resolving the three remaining known issues: an incorrect role, a cosmetic account typo, and a script design flaw.

---

## Issue #3 — Blessing Nwachukwu Had an Incorrect Role

**The issue:** Blessing Nwachukwu (Chapter 1, Task 13's new hire) was listed in Engineering's `responsibility_matrix.txt` as **"Department Administrator"** — factually wrong. She's a regular Software Engineer, not an admin. This error originated because her matrix entry was never properly created when she was onboarded (she predates the automated matrix system), and a placeholder role was used without verification when the company roster was assembled in Task 7.

**Compounding problem:** during Addendum 1's contamination cleanup, her incorrect entry was mistaken for one of the duplicate admin entries being removed (since it read `Blessing Nwachukwu — Department Administrator`, matching the exact pattern of the real duplicate admins being deleted) — so she was removed from the file entirely, rather than corrected.

**Resolution:**
```bash
sudo nano /srv/technova/departments/engineering/responsibility_matrix.txt
```
Added her back to the Auto-Onboarded Employees section with the correct role:
```
Blessing Nwachukwu — Software Engineer
```

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo grep -i "nwachukwu" /srv/technova/departments/engineering/responsibility_matrix.txt
Chidinma Nwachukwu — QA Engineer
Blessing Nwachukwu — Software Engineer
```
Both Nwachukwus (different people, shared surname) confirmed present and correctly distinguished — no mix-up between them.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo grep -c "—" /srv/technova/departments/engineering/responsibility_matrix.txt
12
```
Count rose from 11 (the confirmed real hires) to **12**, correctly reflecting Blessing added back with her accurate role.

**Note:** the four Appendix 1 department admins (Tobiloba Ajayi, Ngozi Eke, Kingsley Uche, Amaka Nwosu) were reviewed as part of this same issue and found to be **correctly** listed as "Department Administrator" — that genuinely is their function, so no change was needed for them. Only Blessing's entry was actually wrong.

**Status: ✅ Resolved.**

---

## Issue #4 — `mogunleye`'s GECOS Field Had a Typo

**The issue:** Michael Ogunleye's account was created back in Chapter 1, Task 3 with a typo in the full-name field — `useradd -c "Miceal Ogunleye"` instead of "Michael Ogunleye." This was cosmetic (didn't affect login, permissions, or group membership) but incorrect in every system record referencing his account (`getent passwd`, `id`, etc.) since account creation.

**Resolution:**
```bash
sudo usermod -c "Michael Ogunleye" mogunleye
```
`usermod -c` updates only the GECOS/comment field — username, UID, group, home directory, shell, and password remain completely untouched.

**Verification:**
```bash
getent passwd mogunleye
```
Expected and confirmed: `mogunleye:x:1002:1002:Michael Ogunleye:/home/mogunleye:/bin/bash` — name corrected, every other field unchanged from before.

**Status: ✅ Resolved.**

---

## Issue #5 — `offboarding_report.txt` Was Overwritten, Not Cumulative

**The issue:** `offboard_contractors.sh` started each report with `>` (overwrite):
```bash
echo "Offboarding Report — Batch: $BATCH_DATE" > "$REPORT_FILE"
```
This meant every script run **erased** the previous run's report entirely. This was first noticed in Task 6: after testing on 1 contractor (`fadebisi`) and then running the remaining 4 in a second batch, the final `offboarding_report.txt` only showed those last 4 — Femi Adebisi's successful offboarding had been silently wiped from the report file, even though it genuinely happened and remained correctly recorded in the shared `onboarding_log.txt`.

**Resolution:**
```bash
nano ~/Technova-Homelab/scripts/offboard_contractors.sh
```
Changed the report's opening lines from overwrite to append, with a blank-line separator added before each new batch's header so multiple runs remain visually distinct within one continuous file:

Before:
```bash
echo "Offboarding Report — Batch: $BATCH_DATE" > "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"
```

After:
```bash
echo "" >> "$REPORT_FILE"
echo "Offboarding Report — Batch: $BATCH_DATE" >> "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"
```

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ grep -B1 "Offboarding Report" scripts/offboard_contractors.sh
echo "" >> "$REPORT_FILE"
echo "Offboarding Report — Batch: $BATCH_DATE" >> "$REPORT_FILE"
```
Confirms the blank-line separator and the append operator (`>>`) are both correctly in place. `>>` on a file that doesn't exist yet still creates it normally, so this change is safe for both first-ever runs and subsequent ones.

**Not re-tested against real accounts** — since all 5 real contractors are already offboarded, deliberately avoided re-running the script against them just to test this fix; the change itself was verified directly in the script rather than through a live run, to avoid taking any unnecessary action against already-correctly-offboarded accounts.

**Status: ✅ Resolved (fix verified in script; full end-to-end validation deferred to the next real offboarding batch).**

---

## Summary

| # | Issue | Root Cause | Fix | Status |
|---|---|---|---|---|
| 3 | Blessing Nwachukwu listed with wrong role, then accidentally deleted during cleanup | Placeholder role never verified; later mistaken for a duplicate during Addendum 1's cleanup | Re-added with correct role (Software Engineer) | ✅ Resolved |
| 4 | `mogunleye` GECOS typo ("Miceal") | Typo at account creation, Chapter 1 Task 3 | `usermod -c "Michael Ogunleye" mogunleye` | ✅ Resolved |
| 5 | `offboarding_report.txt` overwritten each run | Script used `>` instead of `>>` | Changed to append with batch separator | ✅ Resolved (fix verified, live re-test deferred) |

## Status

**✅ All three remaining known issues from the Task 8 Automation Audit are now resolved**, alongside the two already closed in Addendum 1 (missing department matrices, duplicate-data contamination). Chapter 2's known-issues list is now fully cleared, with one item (#5) noted as fix-verified-but-not-yet-exercised against a real offboarding run — worth confirming the next time `offboard_contractors.sh` is genuinely used.
