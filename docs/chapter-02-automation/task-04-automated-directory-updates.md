# Chapter 2, Task 4 — Automated Directory Updates

## Business Requirement

67 employees now have working accounts and passwords — but on paper, they don't exist yet. Each department's `responsibility_matrix.txt` was manually maintained in Chapter 1, listing only the original handful of staff. This task closes that gap: after provisioning, the onboarding script automatically appends every new hire's name and role to the correct department's `responsibility_matrix.txt` — no manual editing required.

## Design Decision — Preserving Chapter 1's Format

Chapter 1's `responsibility_matrix.txt` files use a structured, multi-line format per person. New entries are appended under a clearly labeled section header instead, keeping hand-written Chapter 1 records visually distinct from bulk-automated ones:

```
--- Auto-Onboarded Employees (Batch: <date>) ---
<Full Name> — <Role>
```

## The Script — `update_matrices.sh`

```bash
#!/bin/bash

# Chapter 2, Task 4 — Automated Directory Updates
# Appends new hires to each department's responsibility_matrix.txt,
# under a clearly labeled automation section — never overwrites
# existing Chapter 1 entries.

INPUT_FILE="$1"
BATCH_DATE=$(date +%Y-%m-%d)

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-valid-hires-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

declare -A DEPT_TO_PATH=(
    ["Engineering"]="/srv/technova/departments/engineering"
    ["Sales"]="/srv/technova/departments/sales"
    ["Finance"]="/srv/technova/departments/finance"
    ["HR"]="/srv/technova/departments/hr"
    ["Marketing"]="/srv/technova/departments/marketing"
    ["CustomerSupport"]="/srv/technova/departments/CustomerSupport"
    ["ProductMgt"]="/srv/technova/departments/productmgt"
    ["DevOps"]="/srv/technova/departments/devops"
)

updated_count=0
skipped_count=0
declare -A HEADER_WRITTEN

update_employee_matrix() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local dept_path="${DEPT_TO_PATH[$department]}"

    if [ -z "$dept_path" ]; then
        echo "[SKIPPED] $full_name — no path mapping found for department '$department'"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local matrix_file="$dept_path/responsibility_matrix.txt"

    if ! sudo test -f "$matrix_file"; then
        echo "[SKIPPED] $full_name — responsibility_matrix.txt not found for $department"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if [ -z "${HEADER_WRITTEN[$department]}" ]; then
        sudo bash -c "echo '' >> '$matrix_file'"
        sudo bash -c "echo '--- Auto-Onboarded Employees (Batch: $BATCH_DATE) ---' >> '$matrix_file'"
        HEADER_WRITTEN[$department]=1
    fi

    if sudo bash -c "echo '$full_name — $role' >> '$matrix_file'"; then
        echo "[UPDATED] $full_name — $department — $role"
        updated_count=$((updated_count + 1))
    else
        echo "[FAILED]  $full_name — could not write to $matrix_file"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Updating responsibility matrices from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    update_employee_matrix "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Matrices updated: $updated_count"
echo "Skipped: $skipped_count"
```

## Code Explanation

- **`DEPT_TO_PATH`** — maps department names to filesystem paths, same centralized-mapping pattern as Task 2's `DEPT_TO_GROUP`.
- **`sudo test -f "$matrix_file"`** — checks file existence with root privileges (see Bug 1 below for why this was necessary).
- **`HEADER_WRITTEN` associative array** — ensures the section header is written once per department per run, not once per employee.
- **`sudo bash -c "echo '...' >> '$file'"`** — writes into admin-owned, `640`-permission files using root privileges, same as an admin would need `sudo` for.

## Bug 1 — Permission-Blind File Check

**First test run:**
```
[SKIPPED] Tolu Bakare — responsibility_matrix.txt not found for Engineering
[SKIPPED] Amina Suleiman — responsibility_matrix.txt not found for Sales
```

Both files genuinely existed — false negative. The original check (`[ ! -f "$matrix_file" ]`) ran as the regular user, who cannot see into `2770`-restricted directories. **Fix:** `sudo test -f "$matrix_file"`, running the check with root privileges.

## Bug 2 — Malformed Test Syntax

**After the first fix attempt:**
```
./scripts/update_matrices.sh: line 56: [: too many arguments
[UPDATED] Tolu Bakare — Engineering — Software Engineer
./scripts/update_matrices.sh: line 56: [: too many arguments
[UPDATED] Amina Suleiman — Sales — Sales Executive
```

The fix was pasted *inside* the old brackets instead of replacing them: `if [ ! sudo test -f "$matrix_file" ]; then`. `[` expects a simple expression, not an entire separate command — this produced "too many arguments." The script didn't crash and both entries were still written, but the syntax was still wrong. **Fix:** removed the brackets entirely — `if ! sudo test -f "$matrix_file"; then`.

## Bug 3 — Data Contamination From Uncleaned Test Runs (Both Departments)

Because the buggy test runs above weren't fully cleaned up before the real batch ran, **both** the Engineering and Sales matrices ended up with **triple-duplicated test entries** — confirmed via direct file inspection (see Verification section below). This was initially believed to affect only Sales; direct `cat` output later confirmed Engineering has the identical issue. Manual cleanup attempted on Engineering between test runs did not fully remove the contamination.

**Logged as a follow-up action item**, to be resolved alongside the Chapter 3 appendix work (see Known Gap below) rather than fixed retroactively now.

## Real Run — All 67 Employees

```
[UPDATED] Tolu Bakare — Engineering — Software Engineer
[UPDATED] Amina Suleiman — Sales — Sales Executive
... (44 UPDATED entries total, across Engineering, Sales, Finance, HR)
[SKIPPED] Segun Oyelaran — responsibility_matrix.txt not found for Marketing
[SKIPPED] Zainab Lawal — responsibility_matrix.txt not found for Marketing
[SKIPPED] Ifeoma Anyanwu — responsibility_matrix.txt not found for Marketing
[SKIPPED] Oluwaseun Fapohunda — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Chibuzor Egwu — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Temitope Owolabi — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Uche Njoku — responsibility_matrix.txt not found for ProductMgt
[SKIPPED] Blessing Etuk — responsibility_matrix.txt not found for ProductMgt
[SKIPPED] Damilola Ogundele — responsibility_matrix.txt not found for DevOps
[SKIPPED] Kemi Salako — responsibility_matrix.txt not found for DevOps
[SKIPPED] Samuel Falade — responsibility_matrix.txt not found for Marketing
[SKIPPED] Chinwe Aduba — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Tobi Ilesanmi — responsibility_matrix.txt not found for ProductMgt
[SKIPPED] Hauwa Zubairu — responsibility_matrix.txt not found for DevOps
[SKIPPED] Segun Fashanu — responsibility_matrix.txt not found for Marketing
[SKIPPED] Zainab Abdullahi — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Chukwudi Nnadi — responsibility_matrix.txt not found for ProductMgt
[SKIPPED] Ruth Ogbeide — responsibility_matrix.txt not found for DevOps
[SKIPPED] Kelechi Umeadi — responsibility_matrix.txt not found for Marketing
[SKIPPED] Yetunde Sowande — responsibility_matrix.txt not found for CustomerSupport
[SKIPPED] Ahmed Musa — responsibility_matrix.txt not found for ProductMgt
[SKIPPED] Ngozi Onyema — responsibility_matrix.txt not found for DevOps
[SKIPPED] Michael Osei — responsibility_matrix.txt not found for Marketing
-----------------------------------
Matrices updated: 44
Skipped: 23
```

## Known Gap — Missing Files for the Four New Departments

All 23 skips trace to one root cause: Appendix 1 created workspaces and groups for Marketing, CustomerSupport, ProductMgt, and DevOps, but never ran Chapter 1's Task 5–7 setup against them. The script correctly detected this and skipped safely — fail-safe, not fail-silent.

| Department | Skipped Employees |
|---|---|
| Marketing (7) | Segun Oyelaran, Zainab Lawal, Ifeoma Anyanwu, Samuel Falade, Segun Fashanu, Kelechi Umeadi, Michael Osei |
| CustomerSupport (6) | Oluwaseun Fapohunda, Chibuzor Egwu, Temitope Owolabi, Chinwe Aduba, Zainab Abdullahi, Yetunde Sowande |
| ProductMgt (5) | Uche Njoku, Blessing Etuk, Tobi Ilesanmi, Chukwudi Nnadi, Ahmed Musa |
| DevOps (5) | Damilola Ogundele, Kemi Salako, Hauwa Zubairu, Ruth Ogbeide, Ngozi Onyema |

**Decision:** left unresolved deliberately. Chapter 3 will include an appendix creating `responsibility_matrix.txt` (and related Chapter 1-style files) for these four departments, at which point these 23 employees can be re-processed.

## Verification — File Contents (Actual)

```
ruth1@DESKTOP-DD7VGNC:~$ sudo cat /srv/technova/departments/engineering/responsibility_matrix.txt
Engineering Responsibility Matrix
================================
Department Administrator
-------------------------------------------------
Emmanuel Adeyemi
Role: Engineering Manager
Responsibilities:
- Lead the Engineering Department
- Review pull requests
- Approve production deployments

Michael Ogunleye
Role: Software Engineer
Responsibilities:
- Backend development
- API maintenance
- Bug fixing
Additional responsibility
- Participate in weekly architecture meetings

Esther Bello
Role: Software Engineer
Responsibilities:
- Frontend development
- UI testing
- Feature implementation

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Tolu Bakare — Software Engineer

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Tolu Bakare — Software Engineer

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Tolu Bakare — Software Engineer
Femi Adebisi — DevOps Engineer
Kunle Fashola — Backend Developer
Chidinma Nwachukwu — QA Engineer
Emeka Chukwudi — Frontend Developer
Victor Nwadike — QA Engineer
Chiamaka Obiora — DevOps Engineer
Ada Chikezie — Backend Developer
Damilare Ajala — Software Engineer
Femi Ogunbanjo — Backend Developer
Tunde Alakija — Frontend Developer
```

**Confirms the duplication issue affects Engineering, not just Sales as originally believed** — three repeated headers with "Tolu Bakare" tripled, before the 10 real additional employees appear correctly, each exactly once.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo cat /srv/technova/departments/sales/responsibility_matrix.txt
Sales Responsibility Matrix
===========================

Grace Okoro
Role: Sales Manager
Responsibilities:
- Manage sales operations
- Approve quotations
- Monitor team performance

Sunday Adebayo
Role: Sales Executive
Responsibilities:
- Customer acquisition
- Lead follow-up
- Product demonstrations

David James
Role: Sales Executive
Responsibilities:
- Client relationship management
- Weekly sales reporting

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Amina Suleiman — Sales Executive

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Amina Suleiman — Sales Executive

--- Auto-Onboarded Employees (Batch: 2026-08-24) ---
Amina Suleiman — Sales Executive
Bola Adekunle — Account Manager
Aisha Mohammed — Sales Executive
Grace Ekong — Sales Executive
Rita Okwuosa — Sales Executive
Musa Gambo — Account Manager
Kunle Odusanya — Sales Executive
Amara Onyekwere — Sales Executive
Amina Tijani — Account Manager
Halima Shittu — Sales Executive
Fatima Waziri — Account Manager
```

Same pattern confirmed — three duplicate headers, "Amina Suleiman" tripled, then 10 real employees each appearing correctly once.

## Bonus Verification — End-to-End Login Test

To confirm the automation produced fully functional accounts, not just correct database entries, a live login was attempted for an auto-onboarded employee:

```
ruth1@DESKTOP-DD7VGNC:~$ su - Tbakare
su: user Tbakare does not exist or the user entry does not contain all the required fields
```
Expected failure — Linux usernames are case-sensitive; `Tbakare` does not match the real username `tbakare`.

```
ruth1@DESKTOP-DD7VGNC:~$ su - tbakare
Password:
You are required to change your password immediately (administrator enforced).
Changing password for tbakare.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
...
tbakare@DESKTOP-DD7VGNC:~$ exit
logout
```
✅ Login succeeded with the correct lowercase username and immediately prompted for a mandatory password change — confirming Task 3's `passwd -e` forced-expiry is genuinely active on a real, automatically-provisioned account.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Header written once per department per run | Confirmed by design | ✅ Pass (logic correct; contamination is pre-existing data, not a logic failure) |
| Existing Chapter 1 entries preserved, not overwritten | All original entries intact in both files | ✅ Pass |
| Permission-blind file check identified and fixed | `sudo test -f` replaces plain `-f` | ✅ Fixed |
| Malformed test syntax identified and fixed | Brackets removed around `sudo test` | ✅ Fixed |
| All 8 departments covered without hardcoded logic | `DEPT_TO_PATH` map | ✅ Pass |
| Missing files handled without crashing the batch | 23 skips logged individually, batch completed | ✅ Pass |
| Auto-onboarded accounts are fully functional end-to-end | Live login + forced password change confirmed | ✅ Pass |
| Engineering & Sales matrices free of duplicate test data | — | ❌ Known issue, unresolved |

## Errors / Issues Encountered — Summary

1. **Permission-blind existence check** — fixed with `sudo test -f`.
2. **Malformed `[ ]` + `sudo test` combination** — fixed by removing the brackets.
3. **Duplicate test data in both Engineering and Sales matrices** — from earlier debugging runs not fully cleaned up; logged for cleanup alongside Chapter 3's appendix work.
4. **Missing `responsibility_matrix.txt` for 4 departments** — not a script bug; a genuine Appendix 1 gap. 23 employees correctly skipped and logged.

## Status

**⚠️ Completed with known, documented gaps**

44 of 67 employees successfully added to their department's responsibility matrix; 23 correctly skipped due to missing files for the four Appendix 1 departments. Both Engineering and Sales matrices contain unresolved duplicate test data from earlier debugging. A live login test confirmed the underlying automation (accounts, passwords, forced expiry) is fully functional end-to-end. All gaps logged for resolution alongside a planned Chapter 3 appendix.
