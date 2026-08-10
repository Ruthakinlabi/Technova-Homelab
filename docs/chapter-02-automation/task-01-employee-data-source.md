# Chapter 2, Task 1 — Employee Data Source

## Business Requirement

TechNova is hiring 70 new employees across 8 departments. HR exported the list as a CSV. Before any account gets created, the script must validate every row — catching bad data (missing fields, misspelled departments, blank rows) before it becomes a broken account, rather than after.

## CSV Schema

```
full_name,department,role
```

## Directory Setup

**First attempts to create the script failed silently — no error, but nothing saved:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ nano ~/technova-homelab/scripts/validate_hires.sh
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ nano ~/Technova-Homelab/scripts/validate_hires.sh
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ nano ~/Technova-Homelab/scripts/validate_hires.sh
```
`nano` opens a blank editor regardless of whether the target folder exists, but it cannot actually *save* into a directory that isn't there yet — so each of these was a dead end.

**Resolved:**
```bash
mkdir -p ~/Technova-Homelab/scripts/data
```
`mkdir` creates a new directory. `-p` tells it to create any missing parent directories along the way and not error out if part of the path already exists — this single command created both `scripts/` and `scripts/data/` at once.

```bash
nano ~/Technova-Homelab/scripts/validate_hires.sh
```
This attempt succeeded, since the folder now existed.

```bash
chmod +x ~/Technova-Homelab/scripts/validate_hires.sh
```
`chmod` changes a file's permissions. `+x` adds the "execute" permission — without this, Bash would refuse to run the file directly as a program, even though the content inside is valid script code.

```bash
nano ~/Technova-Homelab/scripts/data/new_hires.csv
```
Created the 70-row employee CSV inside the new `data/` subfolder.

## The Validation Script — Full Code, Explained Line by Line

```bash
#!/bin/bash
```
Called a **shebang**. Not a comment — it tells the operating system which program should interpret this file. `/bin/bash` is the path to the Bash interpreter. Without a valid shebang, the system can't tell this text file is meant to run as a script.

```bash
INPUT_FILE="$1"
```
`$1` is the **first argument** given when the script is run — e.g. in `./validate_hires.sh scripts/data/new_hires.csv`, `$1` is `scripts/data/new_hires.csv`. Stored in a named variable (`INPUT_FILE`) so the rest of the script reads more clearly than repeating `$1` everywhere.

```bash
VALID_DEPARTMENTS=("Engineering" "Sales" "Finance" "HR" "Marketing" "CustomerSupport" "ProductMgt" "DevOps")
```
A Bash **array** — a list of values under one name. This holds every department TechNova currently recognizes; anything in the CSV that doesn't exactly match one of these 8 gets flagged later.

```bash
OUTPUT_DIR="$(dirname "$INPUT_FILE")"
```
`dirname` extracts just the folder portion of a path — given `scripts/data/new_hires.csv`, it returns `scripts/data`. `$(...)` is **command substitution**: it runs the command inside and captures its output into the variable. This means the output files will automatically be created in the same folder as the input CSV, without a hardcoded path.

```bash
VALID_OUTPUT="$OUTPUT_DIR/valid_hires.csv"
INVALID_OUTPUT="$OUTPUT_DIR/invalid_hires_report.txt"
```
Two variables holding the full paths for the two files this script will produce.

```bash
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-csv>"
    exit 1
fi
```
`[ -z "$INPUT_FILE" ]` tests whether a string is empty. This checks: "did the user forget to give a filename?" `$0` is a special variable holding the script's own name, used here to print a helpful usage message. `exit 1` stops the script immediately — exit code `1` conventionally signals failure, useful later if this script gets chained into larger automation that needs to know whether this step succeeded.

```bash
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi
```
`-f` checks that a path exists **and** is a regular file. `!` negates it. So: "if the file does NOT exist, error out and stop" — catches typos in the filename before the script tries to read something that isn't there.

```bash
echo "full_name,department,role" > "$VALID_OUTPUT"
echo "Invalid Records Report — $(date)" > "$INVALID_OUTPUT"
echo "-----------------------------------" >> "$INVALID_OUTPUT"
```
The single `>` **overwrites** a file (creating it if needed) — used here to start both output files fresh every time the script runs, rather than endlessly growing old files from previous runs. `$(date)` inserts the current system date/time into the report header. The double `>>` on the next line **appends** instead of overwriting, adding a separator line under the header without erasing it.

```bash
line_number=0
```
A counter, starting at zero, used purely to report which CSV row is being processed in messages — not used for any validation logic itself.

```bash
echo "Validating $INPUT_FILE ..."
echo "-----------------------------------"
```
Printed header so the script's progress is readable on screen.

```bash
tail -n +2 "$INPUT_FILE" | while IFS=',' read -r full_name department role; do
```
The core loop, in pieces:
- **`tail -n +2 "$INPUT_FILE"`** — `tail` normally shows the end of a file, but `-n +2` means "start printing from line 2 onward," which skips line 1 — the CSV header — so it's never mistakenly validated as if it were an employee row.
- **`|`** — pipes that output into the next command as input.
- **`while ... read -r full_name department role; do`** — reads the input **one line at a time**, splitting each line into the three named variables.
- **`IFS=','`** — Internal Field Separator. By default Bash splits on whitespace; setting it to a comma is what makes `read` correctly split a CSV line like `Tolu Bakare,Engineering,Software Engineer` into three separate values instead of one long string.
- **`-r`** — stops `read` from treating backslashes as special escape characters, so raw text is captured exactly as written.

```bash
    line_number=$((line_number + 1))
```
`$((...))` is Bash **arithmetic evaluation** — increments the row counter by 1 on every loop pass.

```bash
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)
```
Each field is piped through `xargs`, which (used bare like this) trims leading/trailing whitespace. This prevents a CSV like `Tolu Bakare, Engineering ,Software Engineer` (stray space after a comma) from failing an exact-match check later just because of extra spaces.

```bash
    error=""
```
Resets a per-row error message on every loop pass, so an error from a previous row can't leak into the next one's result.

```bash
    if [ -z "$full_name" ]; then
        error="missing full_name"
    elif [ -z "$department" ]; then
        error="missing department"
    elif [ -z "$role" ]; then
        error="missing role"
    else
```
A chain of `elif` ("else if") checks, evaluated top to bottom, stopping at the first true condition — checking in order whether the name, department, or role field is blank.

```bash
        dept_valid=false
        for d in "${VALID_DEPARTMENTS[@]}"; do
            if [ "$department" == "$d" ]; then
                dept_valid=true
                break
            fi
        done
        if [ "$dept_valid" == false ]; then
            error="invalid department '$department'"
        fi
    fi
```
`"${VALID_DEPARTMENTS[@]}"` expands the array into its individual values so the `for` loop can check each one. `break` exits the loop early the moment a match is found — no need to keep checking. If the loop finishes with no match, `dept_valid` stays `false` and the row is flagged with the specific bad department name.

```bash
    if [ -n "$error" ]; then
        echo "[INVALID] Row $((line_number + 1)): $error   (raw: $full_name,$department,$role)"
        echo "Row $((line_number + 1)): $error   (raw: $full_name,$department,$role)" >> "$INVALID_OUTPUT"
    else
        echo "[VALID]   Row $((line_number + 1)): $full_name — $department — $role"
        echo "$full_name,$department,$role" >> "$VALID_OUTPUT"
    fi
done
```
`-n` is the opposite of `-z` — true if the string is **not** empty. If `error` was ever set, this prints and logs an `[INVALID]` line (to screen and to the report file); otherwise it prints and logs a `[VALID]` line, appending the clean row to the valid-records CSV. `$((line_number + 1))` corrects the displayed row number to match the CSV's actual line number, since the header (line 1) was skipped before counting began. `done` closes the loop.

```bash
echo "-----------------------------------"
echo "Valid records saved to: $VALID_OUTPUT"
echo "Invalid records report saved to: $INVALID_OUTPUT"
```
Final summary printed after the loop finishes.

## Known Limitation

Because the loop is fed through a pipe (`tail ... | while ...`), it runs in a **subshell** — a separate mini-process. Any variable changed *inside* the loop (like an internal running count) would be lost once the loop ends, since a subshell's memory doesn't carry back to the main script. This is why totals were checked externally with `grep -c` rather than the script reporting its own count. This will be restructured properly in Task 2 using a function-based approach instead of a pipe.

## Run 1 — Screen Output Only (before file-saving was added)

```bash
./scripts/validate_hires.sh scripts/data/new_hires.csv
```

```
Validating scripts/data/new_hires.csv ...
-----------------------------------
[VALID]   Row 2: Tolu Bakare — Engineering — Software Engineer
[VALID]   Row 3: Amina Suleiman — Sales — Sales Executive
[VALID]   Row 4: Chukwuemeka Obi — Finance — Accountant
[VALID]   Row 5: Ngozi Umeh — HR — HR Assistant
[VALID]   Row 6: Femi Adebisi — Engineering — DevOps Engineer
[VALID]   Row 7: Kunle Fashola — Engineering — Backend Developer
[VALID]   Row 8: Halima Yusuf — Finance — Financial Analyst
[VALID]   Row 9: Yetunde Alabi — HR — Recruiter
[VALID]   Row 10: Chidinma Nwachukwu — Engineering — QA Engineer
[VALID]   Row 11: Bola Adekunle — Sales — Account Manager
[VALID]   Row 12: Tunde Osazuwa — Finance — Financial Analyst
[VALID]   Row 13: Fatima Garba — HR — HR Generalist
[VALID]   Row 14: Emeka Chukwudi — Engineering — Frontend Developer
[VALID]   Row 15: Aisha Mohammed — Sales — Sales Executive
[VALID]   Row 16: Chinedu Igwe — Finance — Accountant
[VALID]   Row 17: Adaeze Uzo — HR — HR Assistant
[VALID]   Row 18: Segun Oyelaran — Marketing — Content Strategist
[VALID]   Row 19: Zainab Lawal — Marketing — Digital Marketer
[VALID]   Row 20: Ifeoma Anyanwu — Marketing — Brand Manager
[VALID]   Row 21: Oluwaseun Fapohunda — CustomerSupport — Support Agent
[VALID]   Row 22: Chibuzor Egwu — CustomerSupport — Support Agent
[VALID]   Row 23: Temitope Owolabi — CustomerSupport — Support Lead
[VALID]   Row 24: Uche Njoku — ProductMgt — Product Analyst
[VALID]   Row 25: Blessing Etuk — ProductMgt — Product Owner
[VALID]   Row 26: Damilola Ogundele — DevOps — Site Reliability Engineer
[VALID]   Row 27: Kemi Salako — DevOps — Cloud Engineer
[INVALID] Row 28: missing full_name   (raw: ,Finance,Accountant)
[VALID]   Row 29: Ahmed Yakubu — HR — HR Assistant
[INVALID] Row 30: invalid department 'Enginering'   (raw: Obiora Madu,Enginering,Software Engineer)
[VALID]   Row 31: Grace Ekong — Sales — Sales Executive
[INVALID] Row 32: missing role   (raw: Yusuf Tanko,Finance,)
[VALID]   Row 33: Peace Effiong — HR — HR Generalist
[VALID]   Row 34: Victor Nwadike — Engineering — QA Engineer
[VALID]   Row 35: Rita Okwuosa — Sales — Sales Executive
[VALID]   Row 36: Emmanuel Danlami — Finance — Accountant
[VALID]   Row 37: Blessing Achebe — HR — Payroll Officer
[VALID]   Row 38: Chiamaka Obiora — Engineering — DevOps Engineer
[VALID]   Row 39: Musa Gambo — Sales — Account Manager
[VALID]   Row 40: Ngozi Ikpe — Finance — Financial Analyst
[VALID]   Row 41: Samuel Falade — Marketing — SEO Specialist
[VALID]   Row 42: Ada Chikezie — Engineering — Backend Developer
[VALID]   Row 43: Kunle Odusanya — Sales — Sales Executive
[VALID]   Row 44: Faith Idowu — Finance — Accountant
[VALID]   Row 45: Ibrahim Sanni — HR — HR Assistant
[VALID]   Row 46: Chinwe Aduba — CustomerSupport — Support Agent
[VALID]   Row 47: Tobi Ilesanmi — ProductMgt — Product Analyst
[VALID]   Row 48: Hauwa Zubairu — DevOps — Cloud Engineer
[VALID]   Row 49: Emeka Ubani — HR — Recruiter
[VALID]   Row 50: Damilare Ajala — Engineering — Software Engineer
[VALID]   Row 51: Amara Onyekwere — Sales — Sales Executive
[VALID]   Row 52: Yakubu Balarabe — Finance — Accountant
[VALID]   Row 53: Ifeoma Ndukwe — HR — HR Generalist
[VALID]   Row 54: Segun Fashanu — Marketing — Content Strategist
[VALID]   Row 55: Zainab Abdullahi — CustomerSupport — Support Agent
[VALID]   Row 56: Chukwudi Nnadi — ProductMgt — Product Owner
[VALID]   Row 57: Ruth Ogbeide — DevOps — Site Reliability Engineer
[VALID]   Row 58: Femi Ogunbanjo — Engineering — Backend Developer
[VALID]   Row 59: Amina Tijani — Sales — Account Manager
[VALID]   Row 60: Obinna Ezeigbo — Finance — Accountant
[VALID]   Row 61: Blessing Nwafor — HR — HR Assistant
[VALID]   Row 62: Kelechi Umeadi — Marketing — Digital Marketer
[VALID]   Row 63: Yetunde Sowande — CustomerSupport — Support Lead
[VALID]   Row 64: Ahmed Musa — ProductMgt — Product Analyst
[VALID]   Row 65: Ngozi Onyema — DevOps — Cloud Engineer
[VALID]   Row 66: Tunde Alakija — Engineering — Frontend Developer
[VALID]   Row 67: Halima Shittu — Sales — Sales Executive
[VALID]   Row 68: Chinedu Onwuka — Finance — Accountant
[VALID]   Row 69: Grace Babatunde — HR — HR Generalist
[VALID]   Row 70: Michael Osei — Marketing — Brand Manager
[VALID]   Row 71: Fatima Waziri — Sales — Account Manager
```

**Totals confirmed via `grep -c`:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/validate_hires.sh scripts/data/new_hires.csv | grep -c '\[INVALID\]'
3
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/validate_hires.sh scripts/data/new_hires.csv | grep -c '\[VALID\]'
67
```
✅ 67 valid + 3 invalid = 70 data rows, matching the CSV exactly. Only 3 errors appeared here (not 4, as in earlier drafts of this CSV) because "Marketing" is now a genuinely valid department — a row that would previously have failed as "invalid department" now correctly passes, proving the validation check reads from the live department array rather than anything hardcoded to the original four.

## Script Updated to Save Output Files

The script was edited to add the `OUTPUT_DIR`/`VALID_OUTPUT`/`INVALID_OUTPUT` logic explained above, then re-saved and re-executed.

```bash
nano ~/Technova-Homelab/scripts/validate_hires.sh
chmod +x scripts/validate_hires.sh
```

## Run 2 — Error Encountered

```bash
./scripts/validate_hires.sh scripts/data/new_hires.csv
```

```
./scripts/validate_hires.sh: line 1: kk#!/bin/bash: No such file or directory
```

**What happened:** the script's very first line should read exactly `#!/bin/bash`. Somehow the characters `kk` ended up typed immediately before the `#` — likely a stray keystroke while editing in `nano` — making line 1 actually read `kk#!/bin/bash`, which is no longer a valid shebang.

**Why the script still ran correctly despite this:** when Bash can't parse a valid shebang on line 1, it falls back to treating the whole file as ordinary shell input starting from that same line. It tried to execute `kk#!/bin/bash` as a literal command — no such command exists, producing the `No such file or directory` error — but this only affected that one line. Every line after it (the real validation logic) executed normally, which is why the rest of the run completed successfully and matched Run 1's results exactly.

**Not yet fixed** — logged as a cleanup item: remove the stray `kk` from line 1 before Task 2 builds on this script.

## Run 2 — Full Results (identical validation outcome, now with file output)

```
Validating scripts/data/new_hires.csv ...
-----------------------------------
[... same 70 rows, same 3 flagged as INVALID, identical to Run 1 ...]
-----------------------------------
Valid records saved to: scripts/data/valid_hires.csv
Invalid records report saved to: scripts/data/invalid_hires_report.txt
```

## Verifying the Output Files

```bash
cat scripts/data/valid_hires.csv
```
```
full_name,department,role
Tolu Bakare,Engineering,Software Engineer
Amina Suleiman,Sales,Sales Executive
Chukwuemeka Obi,Finance,Accountant
Ngozi Umeh,HR,HR Assistant
Femi Adebisi,Engineering,DevOps Engineer
Kunle Fashola,Engineering,Backend Developer
Halima Yusuf,Finance,Financial Analyst
Yetunde Alabi,HR,Recruiter
Chidinma Nwachukwu,Engineering,QA Engineer
Bola Adekunle,Sales,Account Manager
Tunde Osazuwa,Finance,Financial Analyst
Fatima Garba,HR,HR Generalist
Emeka Chukwudi,Engineering,Frontend Developer
Aisha Mohammed,Sales,Sales Executive
Chinedu Igwe,Finance,Accountant
Adaeze Uzo,HR,HR Assistant
Segun Oyelaran,Marketing,Content Strategist
Zainab Lawal,Marketing,Digital Marketer
Ifeoma Anyanwu,Marketing,Brand Manager
Oluwaseun Fapohunda,CustomerSupport,Support Agent
Chibuzor Egwu,CustomerSupport,Support Agent
Temitope Owolabi,CustomerSupport,Support Lead
Uche Njoku,ProductMgt,Product Analyst
Blessing Etuk,ProductMgt,Product Owner
Damilola Ogundele,DevOps,Site Reliability Engineer
Kemi Salako,DevOps,Cloud Engineer
Ahmed Yakubu,HR,HR Assistant
Grace Ekong,Sales,Sales Executive
Peace Effiong,HR,HR Generalist
Victor Nwadike,Engineering,QA Engineer
Rita Okwuosa,Sales,Sales Executive
Emmanuel Danlami,Finance,Accountant
Blessing Achebe,HR,Payroll Officer
Chiamaka Obiora,Engineering,DevOps Engineer
Musa Gambo,Sales,Account Manager
Ngozi Ikpe,Finance,Financial Analyst
Samuel Falade,Marketing,SEO Specialist
Ada Chikezie,Engineering,Backend Developer
Kunle Odusanya,Sales,Sales Executive
Faith Idowu,Finance,Accountant
Ibrahim Sanni,HR,HR Assistant
Chinwe Aduba,CustomerSupport,Support Agent
Tobi Ilesanmi,ProductMgt,Product Analyst
Hauwa Zubairu,DevOps,Cloud Engineer
Emeka Ubani,HR,Recruiter
Damilare Ajala,Engineering,Software Engineer
Amara Onyekwere,Sales,Sales Executive
Yakubu Balarabe,Finance,Accountant
Ifeoma Ndukwe,HR,HR Generalist
Segun Fashanu,Marketing,Content Strategist
Zainab Abdullahi,CustomerSupport,Support Agent
Chukwudi Nnadi,ProductMgt,Product Owner
Ruth Ogbeide,DevOps,Site Reliability Engineer
Femi Ogunbanjo,Engineering,Backend Developer
Amina Tijani,Sales,Account Manager
Obinna Ezeigbo,Finance,Accountant
Blessing Nwafor,HR,HR Assistant
Kelechi Umeadi,Marketing,Digital Marketer
Yetunde Sowande,CustomerSupport,Support Lead
Ahmed Musa,ProductMgt,Product Analyst
Ngozi Onyema,DevOps,Cloud Engineer
Tunde Alakija,Engineering,Frontend Developer
Halima Shittu,Sales,Sales Executive
Chinedu Onwuka,Finance,Accountant
Grace Babatunde,HR,HR Generalist
Michael Osei,Marketing,Brand Manager
Fatima Waziri,Sales,Account Manager
```
✅ 67 clean rows plus header — exactly the valid records, ready to feed directly into Task 2's provisioning script.

```bash
cat scripts/data/invalid_hires_report.txt
```
```
Invalid Records Report — Mon Aug 10 12:59:00 PDT 2026
-----------------------------------
Row 28: missing full_name   (raw: ,Finance,Accountant)
Row 30: invalid department 'Enginering'   (raw: Obiora Madu,Enginering,Software Engineer)
Row 32: missing role   (raw: Yusuf Tanko,Finance,)
```
✅ Exactly the 3 invalid rows with specific reasons — this is the file that would realistically be sent back to HR for correction. The date in the header comes from the `date` command running live at script execution time, not a fixed value — correct behavior for a real audit trail.

## Minor Note

At one point the pasted terminal output showed jumbled text (`ste all of that output — the terminal ru` appearing mid-command). This was a copy-paste artifact from the chat itself, not an actual terminal error or script behavior — no action needed.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Header row excluded from validation | Row 1 skipped | ✅ Pass |
| Missing full_name detected | Flagged invalid | ✅ Pass (Row 28) |
| Misspelled department detected | Flagged invalid | ✅ Pass (Row 30) |
| Missing role detected | Flagged invalid | ✅ Pass (Row 32) |
| Valid department list is dynamic, not hardcoded to original 4 | "Marketing" now passes | ✅ Confirmed |
| Valid rows written to clean CSV | 67 rows saved | ✅ Pass |
| Invalid rows written to report file | 3 rows saved with reasons | ✅ Pass |
| Script still functions despite malformed shebang | Execution unaffected | ✅ Confirmed (see Run 2 error) |

## Errors Encountered — Summary

1. **`nano` run against a nonexistent `scripts/` directory** — files silently failed to save; resolved with `mkdir -p`.
2. **Malformed shebang (`kk#!/bin/bash`)** — stray characters typed before the shebang during editing. Produced a harmless error on line 1 but did not stop script execution, since Bash fell back to running the rest of the file as plain shell commands. Logged as an unresolved cleanup item.

## Known Limitation (carried into Task 2)

The validation loop still runs inside a subshell due to the `tail | while` pipe structure, meaning any internal running count wouldn't survive outside the loop. Task 2 will restructure this using a function-based approach to fix this properly.

## Status

**✅ Completed**

70-row CSV validated: 67 valid records, 3 invalid records correctly identified with specific reasons. Output split into a clean CSV (for Task 2) and a human-readable report (for HR). One cosmetic script error (malformed shebang) identified, explained, and logged for cleanup — did not affect functional correctness.
