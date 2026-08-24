
# Chapter 2, Task 2 — Automated User Provisioning

## Business Requirement

Task 1 produced a clean, validated list of 67 new hires (`valid_hires.csv`). Manually running `useradd` 67 times — plus `passwd`, plus `passwd -e`, plus setting the right group for each — is exactly the bottleneck this chapter exists to remove.

The next step is a script that reads `valid_hires.csv` and creates every account automatically: home directory, correct shell, correct department group, no manual `useradd` calls. The script also needs to survive the messy realities of a live system — what if an employee's username already exists from a previous run? What if the script gets accidentally run twice on the same file? A script that crashes or silently duplicates work on the second run isn't actually production-ready, even if it works perfectly the first time.

## Responsibilities

1. Write a Bash script that reads `valid_hires.csv` line by line.
2. For each row, generate a username following TechNova's `first-initial + surname` convention (matching the standardization done in Appendix 2).
3. Create the account: home directory, Bash shell, correct department group — derived directly from the CSV's `department` column, no hardcoded department names in the account-creation logic itself.
4. Handle the case where a generated username already exists — skip it and log why, rather than crashing or creating a duplicate/conflicting account.
5. Wrap the account-creation logic in a function, not inline code, so it can be tested and reused independently.
6. Test it against the real 67-row file and confirm every account was created correctly.

## Why a Function, Not Inline Code

Task 1's script did everything inline, line by line, inside the loop. That was fine for validation — read a row, check it, print a result. Provisioning is different: the same exact sequence of steps (generate username, check for conflict, create account, assign group) needs to run once per employee, with only the input changing. That repetition is precisely what a function is for — write the logic once, call it 67 times, rather than duplicating the same block of commands throughout the script.

## Why Duplicate-Username Handling Matters Here Specifically

With 67 real employees and shared naming patterns in this dataset, it's entirely plausible for the first-initial + surname convention to produce a collision. A script that assumes every generated username is automatically unique will either crash outright or, worse, silently create a duplicate/conflicting account.

## The Script — `provision_users.sh`

```bash
#!/bin/bash

# Chapter 2, Task 2 — Automated User Provisioning
# Reads valid_hires.csv and creates a Linux account for each employee.

INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-valid-hires-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

# Maps each CSV department name to its actual Linux group name.
# Kept explicit (not auto-lowercased) because group names in this
# system aren't perfectly uniform (e.g. CustomerSupport keeps its casing).
declare -A DEPT_TO_GROUP=(
    ["Engineering"]="engineering"
    ["Sales"]="sales"
    ["Finance"]="finance"
    ["HR"]="hr"
    ["Marketing"]="marketing"
    ["CustomerSupport"]="CustomerSupport"
    ["ProductMgt"]="productmgt"
    ["DevOps"]="devops"
)

created_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')

    local first_initial="${first_name:0:1}"
    local username
    username=$(echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]')
    echo "$username"
}

create_employee_account() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local username
    username=$(generate_username "$full_name")

    # Check for an existing account with this username first —
    # skip rather than error out, so one conflict doesn't halt the batch.
    if id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — username already exists"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local group="${DEPT_TO_GROUP[$department]}"

    if [ -z "$group" ]; then
        echo "[SKIPPED] $full_name — no group mapping found for department '$department'"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if sudo useradd -m -s /bin/bash -g "$group" -c "$full_name" "$username" 2>/dev/null; then
        echo "[CREATED] $full_name — username: $username — department: $department — role: $role"
        created_count=$((created_count + 1))
    else
        echo "[FAILED]  $full_name ($username) — useradd command failed"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Provisioning employees from $INPUT_FILE ..."
echo "-----------------------------------"

# Using process substitution (< <(...)) instead of a pipe here —
# this keeps the while loop running in the CURRENT shell, not a
# subshell, so created_count/skipped_count actually persist after
# the loop ends. This is the fix for Task 1's subshell limitation.
while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    create_employee_account "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Accounts created: $created_count"
echo "Accounts skipped: $skipped_count"
```

## Code Explanation

**Input handling (top of script):** `INPUT_FILE="$1"` grabs the CSV path as the first command-line argument. Two guard clauses fail fast with a clear message if no file was given (`-z`, empty-string check) or if the given path doesn't exist (`-f`, file-exists check), instead of letting the script run into a confusing error later.

**Department-to-group map:** `declare -A DEPT_TO_GROUP` is a Bash associative array mapping each CSV department value to its actual Linux group name. This is what satisfies "no hardcoded department names in the account-creation logic itself" — the mapping lives in one lookup table, and `create_employee_account` just reads from it (`${DEPT_TO_GROUP[$department]}`) instead of containing `if department == "Engineering"` style branching. `CustomerSupport` is kept mixed-case because that's the real group name on the system; everything else happens to be lowercase.

**Counters:** `created_count` and `skipped_count` are plain integers, incremented inside the function, printed in the summary at the end.

**`generate_username()`:** implements the first-initial + surname convention.
- `awk '{print $1}'` grabs the first word (first name).
- `awk '{print $NF}'` grabs the *last* field regardless of how many words are in between — handles middle names safely.
- `${first_name:0:1}` is Bash substring syntax for "first character."
- The result is lowercased with `tr` so "Tolu Bakare" becomes `tbakare`.
- All variables are `local` so this function doesn't leak state into the rest of the script.

**`create_employee_account()`** is the core function. It takes one row's data as three parameters, so it can be called once per CSV line or independently for a single ad-hoc hire. It runs three checks in order, each with its own early return:

1. `id "$username" &>/dev/null` asks the system whether this username already exists, without printing anything. If it exists, log `SKIPPED` and stop — this is the collision-safety requirement, and also what makes the script safe to re-run on the same file.
2. If the department has no entry in `DEPT_TO_GROUP`, skip and log rather than creating an account with a broken group.
3. Otherwise, run `useradd -m -s /bin/bash -g "$group" -c "$full_name" "$username"` — `-m` creates the home directory, `-s /bin/bash` sets the shell, `-g "$group"` sets the department's group, `-c` sets the GECOS/comment field to the full name. Wrapped in `sudo`, since account creation needs root. The `if/then/else` checks the actual exit status of `useradd`, so a real failure is logged as `FAILED` rather than silently miscounted as success.

**Main loop:** `tail -n +2` skips the CSV header row. `IFS=',' read -r` splits each line on commas into the three variables. `xargs` on each variable trims stray leading/trailing whitespace. Each cleaned row is passed straight into `create_employee_account`.

The loop is fed via **process substitution** (`done < <(tail -n +2 "$INPUT_FILE")`) rather than a pipe (`tail ... | while ...`). This is a deliberate fix carried over from Task 1: piping into `while` runs the loop in a subshell, so any variables changed inside it (like `created_count`) are lost the moment the loop ends. Process substitution keeps the loop in the current shell, so the counters persist correctly into the final summary.

**Summary:** the final `echo` lines print the tally after the loop completes.

## Test Run — 3-Row `test_provision.csv`

```
ruth1@DESKTOP-DD7VGNC:~$ cd Technova-Homelab
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ chmod +x ~/Technova-Homelab/scripts/provision_users.sh
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ nano ~/Technova-Homelab/scripts/data/test_provision.csv
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/provision_users.sh scripts/data/test_provision.csv
Provisioning employees from scripts/data/test_provision.csv ...
-----------------------------------
[sudo] password for ruth1:
[CREATED] Test Oneperson — username: toneperson — department: Engineering — role: Test Role
[CREATED] Test Twoperson — username: ttwoperson — department: Sales — role: Test Role
[SKIPPED] Emmanuel Adeyemi (eadeyemi) — username already exists
-----------------------------------
Accounts created: 2
Accounts skipped: 1
```

**Verification:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id toneperson
uid=1018(toneperson) gid=1002(engineering) groups=1002(engineering)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id ttwoperson
uid=1019(ttwoperson) gid=1003(sales) groups=1003(sales)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd toneperson ttwoperson
toneperson:x:1018:1002:Test Oneperson:/home/toneperson:/bin/bash
ttwoperson:x:1019:1003:Test Twoperson:/home/ttwoperson:/bin/bash
```

**Cleanup (removing test accounts before the real run):**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo userdel -r toneperson
userdel: toneperson mail spool (/var/mail/toneperson) not found
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo userdel -r ttwoperson
userdel: ttwoperson mail spool (/var/mail/ttwoperson) not found
```
The "mail spool not found" message is expected and harmless — WSL doesn't set up a local mail system by default, so `userdel` simply notes there was nothing there to remove; the account and home directory were still deleted correctly.

**Test validation:** correct account created for each new row (`id` and `getent passwd` confirm correct UID, GID, home directory, and shell), and the pre-existing username (`eadeyemi`) was correctly skipped rather than causing a crash or duplicate.

## Real Run — All 67 Employees (`valid_hires.csv`)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo ./scripts/provision_users.sh scripts/data/valid_hires.csv
[sudo] password for ruth1:
Sorry, try again.
[sudo] password for ruth1:
Provisioning employees from scripts/data/valid_hires.csv ...
-----------------------------------
[CREATED] Tolu Bakare — username: tbakare — department: Engineering — role: Software Engineer
[CREATED] Amina Suleiman — username: asuleiman — department: Sales — role: Sales Executive
[CREATED] Chukwuemeka Obi — username: cobi — department: Finance — role: Accountant
[CREATED] Ngozi Umeh — username: numeh — department: HR — role: HR Assistant
[CREATED] Femi Adebisi — username: fadebisi — department: Engineering — role: DevOps Engineer
[CREATED] Kunle Fashola — username: kfashola — department: Engineering — role: Backend Developer
[CREATED] Halima Yusuf — username: hyusuf — department: Finance — role: Financial Analyst
[CREATED] Yetunde Alabi — username: yalabi — department: HR — role: Recruiter
[CREATED] Chidinma Nwachukwu — username: cnwachukwu — department: Engineering — role: QA Engineer
[CREATED] Bola Adekunle — username: badekunle — department: Sales — role: Account Manager
[CREATED] Tunde Osazuwa — username: tosazuwa — department: Finance — role: Financial Analyst
[CREATED] Fatima Garba — username: fgarba — department: HR — role: HR Generalist
[CREATED] Emeka Chukwudi — username: echukwudi — department: Engineering — role: Frontend Developer
[CREATED] Aisha Mohammed — username: amohammed — department: Sales — role: Sales Executive
[CREATED] Chinedu Igwe — username: cigwe — department: Finance — role: Accountant
[CREATED] Adaeze Uzo — username: auzo — department: HR — role: HR Assistant
[CREATED] Segun Oyelaran — username: soyelaran — department: Marketing — role: Content Strategist
[CREATED] Zainab Lawal — username: zlawal — department: Marketing — role: Digital Marketer
[CREATED] Ifeoma Anyanwu — username: ianyanwu — department: Marketing — role: Brand Manager
[CREATED] Oluwaseun Fapohunda — username: ofapohunda — department: CustomerSupport — role: Support Agent
[CREATED] Chibuzor Egwu — username: cegwu — department: CustomerSupport — role: Support Agent
[CREATED] Temitope Owolabi — username: towolabi — department: CustomerSupport — role: Support Lead
[CREATED] Uche Njoku — username: unjoku — department: ProductMgt — role: Product Analyst
[CREATED] Blessing Etuk — username: betuk — department: ProductMgt — role: Product Owner
[CREATED] Damilola Ogundele — username: dogundele — department: DevOps — role: Site Reliability Engineer
[CREATED] Kemi Salako — username: ksalako — department: DevOps — role: Cloud Engineer
[CREATED] Ahmed Yakubu — username: ayakubu — department: HR — role: HR Assistant
[CREATED] Grace Ekong — username: gekong — department: Sales — role: Sales Executive
[CREATED] Peace Effiong — username: peffiong — department: HR — role: HR Generalist
[CREATED] Victor Nwadike — username: vnwadike — department: Engineering — role: QA Engineer
[CREATED] Rita Okwuosa — username: rokwuosa — department: Sales — role: Sales Executive
[CREATED] Emmanuel Danlami — username: edanlami — department: Finance — role: Accountant
[CREATED] Blessing Achebe — username: bachebe — department: HR — role: Payroll Officer
[CREATED] Chiamaka Obiora — username: cobiora — department: Engineering — role: DevOps Engineer
[CREATED] Musa Gambo — username: mgambo — department: Sales — role: Account Manager
[CREATED] Ngozi Ikpe — username: nikpe — department: Finance — role: Financial Analyst
[CREATED] Samuel Falade — username: sfalade — department: Marketing — role: SEO Specialist
[CREATED] Ada Chikezie — username: achikezie — department: Engineering — role: Backend Developer
[CREATED] Kunle Odusanya — username: kodusanya — department: Sales — role: Sales Executive
[CREATED] Faith Idowu — username: fidowu — department: Finance — role: Accountant
[CREATED] Ibrahim Sanni — username: isanni — department: HR — role: HR Assistant
[CREATED] Chinwe Aduba — username: caduba — department: CustomerSupport — role: Support Agent
[CREATED] Tobi Ilesanmi — username: tilesanmi — department: ProductMgt — role: Product Analyst
[CREATED] Hauwa Zubairu — username: hzubairu — department: DevOps — role: Cloud Engineer
[CREATED] Emeka Ubani — username: eubani — department: HR — role: Recruiter
[CREATED] Damilare Ajala — username: dajala — department: Engineering — role: Software Engineer
[CREATED] Amara Onyekwere — username: aonyekwere — department: Sales — role: Sales Executive
[CREATED] Yakubu Balarabe — username: ybalarabe — department: Finance — role: Accountant
[CREATED] Ifeoma Ndukwe — username: indukwe — department: HR — role: HR Generalist
[CREATED] Segun Fashanu — username: sfashanu — department: Marketing — role: Content Strategist
[CREATED] Zainab Abdullahi — username: zabdullahi — department: CustomerSupport — role: Support Agent
[CREATED] Chukwudi Nnadi — username: cnnadi — department: ProductMgt — role: Product Owner
[CREATED] Ruth Ogbeide — username: rogbeide — department: DevOps — role: Site Reliability Engineer
[CREATED] Femi Ogunbanjo — username: fogunbanjo — department: Engineering — role: Backend Developer
[CREATED] Amina Tijani — username: atijani — department: Sales — role: Account Manager
[CREATED] Obinna Ezeigbo — username: oezeigbo — department: Finance — role: Accountant
[CREATED] Blessing Nwafor — username: bnwafor — department: HR — role: HR Assistant
[CREATED] Kelechi Umeadi — username: kumeadi — department: Marketing — role: Digital Marketer
[CREATED] Yetunde Sowande — username: ysowande — department: CustomerSupport — role: Support Lead
[CREATED] Ahmed Musa — username: amusa — department: ProductMgt — role: Product Analyst
[CREATED] Ngozi Onyema — username: nonyema — department: DevOps — role: Cloud Engineer
[CREATED] Tunde Alakija — username: talakija — department: Engineering — role: Frontend Developer
[CREATED] Halima Shittu — username: hshittu — department: Sales — role: Sales Executive
[CREATED] Chinedu Onwuka — username: conwuka — department: Finance — role: Accountant
[CREATED] Grace Babatunde — username: gbabatunde — department: HR — role: HR Generalist
[CREATED] Michael Osei — username: mosei — department: Marketing — role: Brand Manager
[CREATED] Fatima Waziri — username: fwaziri — department: Sales — role: Account Manager
-----------------------------------
Accounts created: 67
Accounts skipped: 0
```

**Note on the "Sorry, try again" line:** this was simply a mistyped sudo password on the first prompt, corrected on the second attempt — normal `sudo` behavior, not a script error.

## Result

All 67 accounts were created successfully with no skips — no username collisions occurred in this dataset, and every row resolved to a valid department group. This confirms:

- The first-initial + surname username convention worked cleanly across all 67 rows.
- The department-to-group mapping covered every department present in the CSV (Engineering, Sales, Finance, HR, Marketing, CustomerSupport, ProductMgt, DevOps) with no "no group mapping found" entries.
- The collision-check logic (tested and proven in the 3-row test run against the pre-existing `eadeyemi` account) was active for this run as well, even though no collision happened to occur in the real data.
- The script is safe to re-run on the same file: any account that already exists will be skipped and logged rather than duplicated or crashed on.

## Known Gap (carried to Task 3)

The requirement mentions `passwd` and `passwd -e` (forcing a password reset on first login) as part of the original manual process this script replaces. The current script creates the account, home directory, shell, and group, but does **not** yet set an initial password or force expiry — a natural next addition (Task 3), not a gap in what was tested here.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Username generated via first-initial + surname | Correct for all rows | ✅ Pass |
| Correct department → group mapping, no hardcoding | All 8 departments resolved | ✅ Pass |
| Duplicate username detected and skipped, not crashed | Confirmed against `eadeyemi` | ✅ Pass |
| Function-based structure (reusable, testable) | `generate_username`, `create_employee_account` | ✅ Pass |
| Counters accurate after loop (subshell issue fixed) | 67 created / 0 skipped, correctly tallied | ✅ Pass |
| Full 67-employee batch run | All created successfully | ✅ Pass |

## Status

**✅ Completed**

`provision_users.sh` successfully provisions accounts from a validated CSV — home directory, shell, and department group all set correctly, with safe handling of duplicate usernames and no hardcoded department logic. Tested on a 3-row sample (including a deliberate collision) and then on the full 67-employee batch, with 100% success and zero skips.


