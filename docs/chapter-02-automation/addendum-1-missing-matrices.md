# Chapter 2 — Addendum 1: Missing Department Matrices & Duplicate-Data Cleanup

## Business Requirement

Chapter 2's Automation Audit (Task 8) identified two unresolved issues carried forward from earlier tasks:
1. 23 employees across Marketing, CustomerSupport, ProductMgt, and DevOps had no `responsibility_matrix.txt` at all, since those four departments (created in Chapter 1's Appendix 1) never received Chapter 1's Task 5–7 documentation setup.
2. Engineering and Sales already carried duplicate test-data contamination from earlier debugging sessions in Tasks 4 and 5.

This addendum documents closing both gaps — including a new complication that emerged mid-fix, and how it was resolved.

## Part 1 — Creating the Four Missing Files

```bash
sudo -u tajayi touch /srv/technova/departments/marketing/responsibility_matrix.txt
sudo -u neke touch /srv/technova/departments/CustomerSupport/responsibility_matrix.txt
sudo -u kuche touch /srv/technova/departments/productmgt/responsibility_matrix.txt
sudo -u anwosu touch /srv/technova/departments/devops/responsibility_matrix.txt
```

Header content added per file (admin name, "Department Administrator" role, standard responsibilities), followed by:

```bash
sudo chmod 660 /srv/technova/departments/marketing/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/CustomerSupport/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/productmgt/responsibility_matrix.txt
sudo chmod 660 /srv/technova/departments/devops/responsibility_matrix.txt
```

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~$ sudo ls -l /srv/technova/departments/marketing/responsibility_matrix.txt
-rw-rw---- 1 tajayi marketing 214 Aug 31 10:19 /srv/technova/departments/marketing/responsibility_matrix.txt
ruth1@DESKTOP-DD7VGNC:~$ sudo ls -l /srv/technova/departments/CustomerSupport/responsibility_matrix.txt
-rw-rw---- 1 neke CustomerSupport 256 Aug 31 10:19 /srv/technova/departments/CustomerSupport/responsibility_matrix.txt
ruth1@DESKTOP-DD7VGNC:~$ sudo ls -l /srv/technova/departments/productmgt/responsibility_matrix.txt
-rw-rw---- 1 kuche productmgt 271 Aug 31 10:19 /srv/technova/departments/productmgt/responsibility_matrix.txt
ruth1@DESKTOP-DD7VGNC:~$ sudo ls -l /srv/technova/departments/devops/responsibility_matrix.txt
-rw-rw---- 1 anwosu devops 218 Aug 31 10:20 /srv/technova/departments/devops/responsibility_matrix.txt
```
✅ All four files created correctly: owned by the department admin, correct group, correct `660` permissions.

## Errors Encountered — Path Navigation

```
ruth1@DESKTOP-DD7VGNC:~$ ./scripts/update_matrices.sh scripts/data/employees.csv
-bash: ./scripts/update_matrices.sh: No such file or directory
```
Two mistakes stacked here: the command was run from `~` instead of `~/Technova-Homelab` (so the relative path didn't resolve), and it referenced a file that didn't exist (`employees.csv` instead of `all_employees.csv`). Resolved by `cd`-ing into the repo root and using the correct filename.

## Error — Blank CSV Line Crashes the Department Lookup

Running `update_matrices.sh` against the full roster initially failed partway through:
```
./scripts/update_matrices.sh: line 49: DEPT_TO_PATH: bad array subscript
[SKIPPED]  — no path mapping found for department ''
```

**Root cause found:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ grep -n '^$' scripts/data/all_employees.csv
19:
```
Line 19 of `all_employees.csv` was completely blank — left over from combining the manually-typed header block with the appended 67-row CSV. When the loop hit this line, `department` evaluated to an empty string, and looking up an empty key in the `DEPT_TO_PATH` associative array (`${DEPT_TO_PATH[""]}`) is invalid Bash syntax, not just an empty result — it throws a hard error rather than failing gracefully like the script's other guard checks do.

**Fix:**
```bash
sed -i '/^[[:space:]]*$/d' scripts/data/all_employees.csv
```
Deletes any line that is entirely empty or whitespace-only, in place. This solved the immediate problem by removing the bad data rather than patching the script — a reasonable call since the blank line was a one-off data artifact. **Noted as a minor future improvement**, not yet done: the script itself could be hardened to skip blank lines safely on its own, in case a future CSV has the same issue.

## Minor — Stray File Created and Removed

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ nano undate-matrices
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ git status
Untracked files:
        undate-matrices
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ rm undate-matrices
```
A typo while trying to open `update_matrices.sh` created an empty, wrongly-named file in the repo root. Caught via `git status` before being committed, and deleted.

## ⚠️ Significant Issue — Re-Running the Script Introduced New Contamination

After the blank-line fix, `update_matrices.sh` was run against `all_employees.csv` — which contains **all 84 people** (17 original Chapter 1/Appendix 1 employees + 67 recent hires), not just the 23 who were missing files.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/update_matrices.sh scripts/data/all_employees.csv
...
Matrices updated: 84
Skipped: 0
```

**The problem:** Engineering, Sales, Finance, and HR already had their real employees recorded from Task 4's original run. Since the script has no way to detect "this person is already listed," it appended a **second full set of entries** for every one of those 84 people into whichever department file already had them — meaning the duplicate-entry contamination that was previously confined to Engineering and Sales (from earlier test-run cleanup issues) spread to **all four original departments**.

This was not caught before the fix was committed:
```bash
git add scripts/data/all_employees.csv
git commit -m "fix(automation): handle empty lines in matrix updater and add missing matrices"
git push
```

## Fixing the Contamination — `dedupe_matrices.sh`

A dedicated cleanup script was written rather than hand-editing 8 files individually:

```bash
#!/bin/bash

# Chapter 2, Addendum 1 — Deduplicate responsibility_matrix.txt files
# Removes duplicate "Auto-Onboarded Employees" sections/entries across
# all departments, keeping exactly one clean entry per employee.

DEPARTMENTS=(engineering sales finance hr marketing CustomerSupport productmgt devops)
BASE_DIR="/srv/technova/departments"
CLEAN_DATE=$(date +%Y-%m-%d)

for dept in "${DEPARTMENTS[@]}"; do
    file="$BASE_DIR/$dept/responsibility_matrix.txt"

    if ! sudo test -f "$file"; then
        echo "[SKIPPED] $dept — file not found"
        continue
    fi

    header=$(sudo awk '/--- Auto-Onboarded Employees/{exit} {print}' "$file")
    entries=$(sudo awk '/--- Auto-Onboarded Employees/{found=1; next} found && /—/{print}' "$file" | awk '!seen[$0]++')
    entry_count=$(echo "$entries" | grep -c "—")

    {
        echo "$header"
        echo ""
        echo "--- Auto-Onboarded Employees (Cleaned: $CLEAN_DATE) ---"
        echo "$entries"
    } | sudo tee "$file" > /dev/null

    echo "[CLEANED] $dept — $entry_count unique entries kept"
done
```

**Run:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/dedupe_matrices.sh
[CLEANED] engineering — 16 unique entries kept
[CLEANED] sales — 15 unique entries kept
[CLEANED] finance — 13 unique entries kept
[CLEANED] hr — 15 unique entries kept
[CLEANED] marketing — 8 unique entries kept
[CLEANED] CustomerSupport — 7 unique entries kept
[CLEANED] productmgt — 6 unique entries kept
[CLEANED] devops — 6 unique entries kept
```

## Second Issue Found — Deduplication Wasn't Enough on Its Own

The script correctly removed exact line-for-line duplicates, but a review of the actual file contents revealed two remaining problems it couldn't catch:

1. **Department admins/original staff appeared twice, in two different formats.** People like Emmanuel Adeyemi already existed in the proper Chapter 1 multi-line format (`Name` / `Role:` / `Responsibilities:`) at the top of the file — but since `all_employees.csv` also included them, they now *also* appeared a second time as a flattened one-line entry (`Emmanuel Adeyemi — Engineering Manager`) in the Auto-Onboarded section. The dedup script's `!seen[$0]++` logic only catches *identical* lines — since the two formats are textually different, it correctly (but unhelpfully) treated them as two different entries.

2. **Leftover test data survived.** `Testson Oneperson — Test Role` (Engineering) and `Testdaughter Twoperson — Test Role` (Sales), both remnants of Task 5's `test_task5.csv` run, only appeared once each in their files — so deduplication had nothing to remove; a script has no way to know a name is fake without being told.

## Manual Cleanup

Both issues required judgment rather than pattern-matching, so they were fixed by hand, one department at a time:

```bash
sudo nano /srv/technova/departments/engineering/responsibility_matrix.txt
sudo nano /srv/technova/departments/sales/responsibility_matrix.txt
sudo nano /srv/technova/departments/finance/responsibility_matrix.txt
sudo nano /srv/technova/departments/hr/responsibility_matrix.txt
sudo nano /srv/technova/departments/marketing/responsibility_matrix.txt
sudo nano /srv/technova/departments/CustomerSupport/responsibility_matrix.txt
sudo nano /srv/technova/departments/productmgt/responsibility_matrix.txt
sudo nano /srv/technova/departments/devops/responsibility_matrix.txt
```

Removed from each file's Auto-Onboarded section:
- **Engineering:** Emmanuel Adeyemi, Michael Ogunleye, Esther Bello, Blessing Nwachukwu, `Testson Oneperson`
- **Sales:** Grace Okoro, Sunday Adebayo, David James, `Testdaughter Twoperson`
- **Finance:** Deborah Ibrahim, Chioma Eze, Favour Akinyemi
- **HR:** Daniel Ojo, Samuel Akinwale, Ruth Akinlabi
- **Marketing:** Tobiloba Ajayi
- **CustomerSupport:** Ngozi Eke
- **ProductMgt:** Kingsley Uche
- **DevOps:** Amaka Nwosu

## Final Verification — All 8 Files, Confirmed Clean

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ for dept in engineering sales finance hr marketing CustomerSupport productmgt devops; do
    echo "=== $dept ==="
    sudo cat /srv/technova/departments/$dept/responsibility_matrix.txt
    echo ""
done
```

Full output confirmed: every department's original Chapter 1/Appendix 1 content intact and untouched, followed by exactly one clean "Auto-Onboarded Employees" section with no repeated names and no test data remaining.

**Entry counts, cross-checked against Task 4/8's known-correct totals:**

| Department | Entries | Expected | Result |
|---|---|---|---|
| Engineering | 11 | 11 | ✅ |
| Sales | 11 | 11 | ✅ |
| Finance | 10 | 10 | ✅ |
| HR | 12 | 12 | ✅ |
| Marketing | 7 | 7 | ✅ |
| CustomerSupport | 6 | 6 | ✅ |
| ProductMgt | 5 | 5 | ✅ |
| DevOps | 5 | 5 | ✅ |

44 (original 4 departments) + 23 (new 4 departments) = **67**, matching every real hire from `valid_hires.csv` exactly once, across all 8 files.

## Summary of Every Issue Encountered and How It Was Resolved

| # | Issue | Cause | Fix |
|---|---|---|---|
| 1 | Command run from wrong directory | Ran from `~` instead of repo root | `cd` into `~/Technova-Homelab` |
| 2 | Wrong filename referenced | Typo'd `employees.csv` for `all_employees.csv` | Corrected filename |
| 3 | `bad array subscript` crash | Blank line in CSV → empty department key | `sed -i` removed blank lines |
| 4 | Stray untracked file | Typo while opening script in `nano` | Caught via `git status`, removed |
| 5 | Contamination spread to 4 more departments | Re-ran matrix updater against *all* 84 people, not just the 23 missing ones | Built `dedupe_matrices.sh` to remove exact-duplicate lines |
| 6 | Admins still duplicated (different formats) | Dedup only catches identical text, not same-person-different-format | Manual removal, one department at a time |
| 7 | Leftover test names survived | Appeared only once each, so dedup had nothing to remove | Manually identified and removed |

## Status

**✅ Fully Resolved**

Both issues originally flagged in the Task 8 audit — missing department matrices and duplicate test-data contamination — are now closed. All 8 department `responsibility_matrix.txt` files contain accurate, deduplicated records: original Chapter 1/Appendix 1 staff and admins in their proper documented format, and all 67 recently hired employees listed exactly once each in the Auto-Onboarded section. Along the way, five real errors were hit and resolved (wrong directory, wrong filename, a script-crashing blank line, a stray file, and — most significantly — a contamination-spreading side effect from re-running an existing script against the wrong scope of data), each documented here rather than glossed over.
