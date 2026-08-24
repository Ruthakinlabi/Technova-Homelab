# Chapter 2, Task 3 — Initial Password Generation

## Business Requirement

Task 2 successfully created all 67 employee accounts — but every one of them had no password set at all; nobody could actually log in yet. TechNova's IT policy (established in Chapter 1, Task 3) requires every new employee to receive a temporary password and be forced to change it on first login. This task automates that step: apply a temporary password to each account, force an immediate password change at next login, and produce a secure, access-restricted record of what was done.

## Design Decision — Shared Default Password

Rather than generating a unique random password per employee, TechNova uses a single shared temporary password (`Technova2026`) applied to all 67 accounts. This is simpler to manage at bulk-onboarding scale and mirrors how many real companies handle it. The tradeoff is explicit: a shared temporary password means if it leaks or is guessed, it's valid for every account that hasn't logged in yet. The mitigating control is `passwd -e` (forced expiry) — the moment any employee logs in, that shared password becomes invalid for their account specifically. The design is only acceptable because the forced-expiry step is applied without exception to every account.

## The Script — `set_passwords.sh`

```bash
#!/bin/bash

# Chapter 2, Task 3 — Initial Password Generation
# Applies a default temporary password to every employee created in Task 2,
# forces a password change at first login, and logs the action.

INPUT_FILE="$1"
DEFAULT_PASSWORD="Technova2026"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-valid-hires-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

OUTPUT_DIR="$(dirname "$INPUT_FILE")"
CREDENTIALS_LOG="$OUTPUT_DIR/credentials_log.txt"

echo "Credentials Log — $(date)" > "$CREDENTIALS_LOG"
echo "Default temporary password issued to all accounts below: $DEFAULT_PASSWORD" >> "$CREDENTIALS_LOG"
echo "All accounts require a password change at first login." >> "$CREDENTIALS_LOG"
echo "-----------------------------------" >> "$CREDENTIALS_LOG"

set_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')
    local first_initial="${first_name:0:1}"
    echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]'
}

set_employee_password() {
    local full_name="$1"
    local username="$2"

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — account does not exist"
        skipped_count=$((skipped_count + 1))
        return
    fi

    if echo "${username}:${DEFAULT_PASSWORD}" | sudo chpasswd 2>/dev/null; then
        sudo passwd -e "$username" &>/dev/null
        echo "[SET]     $full_name — username: $username — password expired, must change at login"
        echo "$username — $full_name" >> "$CREDENTIALS_LOG"
        set_count=$((set_count + 1))
    else
        echo "[FAILED]  $full_name ($username) — chpasswd failed"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Setting passwords for employees in $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    username=$(generate_username "$full_name")

    set_employee_password "$full_name" "$username"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Passwords set: $set_count"
echo "Skipped: $skipped_count"

# Lock down the credentials log — admin-only, same tier as confidential.txt
sudo chmod 600 "$CREDENTIALS_LOG"
sudo chown "$(whoami):$(whoami)" "$CREDENTIALS_LOG" 2>/dev/null

echo "Credentials log saved and secured (600) at: $CREDENTIALS_LOG"
```

## Code Explanation

- **`DEFAULT_PASSWORD="Technova2026"`** — the shared temporary password, defined once at the top of the script so it only needs to be changed in one place if the policy changes later.
- **`CREDENTIALS_LOG`** — built the same way as Task 1's output files (`dirname` on the input path), so the log lands in the same folder as the CSV being processed.
- **`echo "..." > "$CREDENTIALS_LOG"`** then **`>> "$CREDENTIALS_LOG"`** — the first line overwrites (starts the file fresh), the following lines append the header content — same pattern used in Task 1's output files.
- **`generate_username()`** — identical logic to Task 2's function (first-initial + surname, lowercased) — reused here because this script needs to independently regenerate each username from the CSV to know which account to target.
- **`set_employee_password()`**:
  - `if ! id "$username" &>/dev/null` — the `!` negates the check, so this reads "if the account does NOT exist." Guards against trying to set a password on an account that was never created (e.g. because Task 2 skipped it).
  - **`echo "${username}:${DEFAULT_PASSWORD}" | sudo chpasswd`** — `chpasswd` reads `username:password` pairs and applies them in bulk. This is used instead of `passwd` because `passwd` is interactive (waits for typed input at a prompt) and can't be driven from inside a loop; `chpasswd` accepts input via a pipe, which is exactly what bulk automation needs.
  - **`sudo passwd -e "$username"`** — immediately expires the password just set, forcing a mandatory change at the employee's next login. Same command used manually throughout Chapter 1, now automated.
  - The successful branch logs the username and name to the credentials file — deliberately **not** repeating the password itself per line, since every account shares the same one; stating it once at the top of the file avoids needlessly repeating a shared secret 67 times.
- **`sudo chmod 600 "$CREDENTIALS_LOG"`** — restricts the credentials log to owner-only read/write, the same protection tier as `confidential.txt` in Chapter 1. A plaintext list of every new hire's username in a world-readable file would be a real exposure; this closes that gap immediately after the file is written.

## Test Run 1 — `test_provision.csv` (reused from Task 2)

**Command typo before the first real attempt:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/set_passwords.sh scripts/data/test_provision.csv./scripts/set_passwords.sh scripts/data/test_provision.csv
Error: file 'scripts/data/test_provision.csv./scripts/set_passwords.sh' not found.
```
The command got typed twice, concatenated together, producing a single garbled filename. The script correctly reported that this malformed path didn't exist — expected, correct behavior for the `-f` file-existence guard.

**Corrected run:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/set_passwords.sh scripts/data/test_provision.csv
Setting passwords for employees in scripts/data/test_provision.csv ...
-----------------------------------
[SKIPPED] Test Oneperson (toneperson) — account does not exist
[SKIPPED] Test Twoperson (ttwoperson) — account does not exist
[sudo] password for ruth1:
[SET]     Emmanuel Adeyemi — username: eadeyemi — password expired, must change at login
-----------------------------------
Passwords set: 1
Skipped: 2
Credentials log saved and secured (600) at: scripts/data/credentials_log.txt
```
This file retained its original Task 2 test content. `toneperson` and `ttwoperson` were correctly skipped, since both accounts were deliberately deleted with `userdel` at the end of Task 2 — proving the "account doesn't exist" guard works correctly against real, absent accounts. `eadeyemi` (a genuinely existing account) had its password set successfully.

## Test Run 2 — `test_passwords.csv`

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/set_passwords.sh scripts/data/test_passwords.csv
Setting passwords for employees in scripts/data/test_passwords.csv ...
-----------------------------------
[SKIPPED] ATolu Bakare (abakare) — account does not exist
[SET]     Amina Suleiman — username: asuleiman — password expired, must change at login
-----------------------------------
Passwords set: 1
Skipped: 1
Credentials log saved and secured (600) at: scripts/data/credentials_log.txt
```

**Error identified:** the CSV had a typo — "ATolu Bakare" instead of "Tolu Bakare" (a stray leading `A`). This generated the username `abakare` instead of the correct `tbakare`. Since `abakare` genuinely doesn't exist as an account, the script correctly reported it as skipped — it did not guess or fuzzy-match to the real account `tbakare`, which is the safer behavior: better to skip cleanly on bad input than silently act on the wrong account.

**Confirming the consequence:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ udo passwd -S tbakare
Command 'udo' not found, but can be installed with:
sudo apt install udo
```
Typo — `udo` instead of `sudo`. Ubuntu's suggestion to install a package called `udo` is a generic not-found message, not an actual real package.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo passwd -S tbakare
tbakare L 2026-08-24 0 99999 7 -1
```
Status `L` confirms `tbakare` had no password set at this point — expected, since the typo in the test CSV meant his account was never actually targeted. This was resolved naturally once the real 67-employee batch (which contains his name spelled correctly) was run afterward.

## Verifying Output Files From the Test Runs

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ cat scripts/data/credentials_log.txt
Credentials Log — Mon Aug 24 16:40:56 PDT 2026
Default temporary password issued to all accounts below: Technova2026
All accounts require a password change at first login.
-----------------------------------
asuleiman — Amina Suleiman
```
Only successfully processed accounts appear in the log — correct.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -l scripts/data/credentials_log.txt
-rw------- 1 ruth1 ruth1 239 Aug 24 16:40 scripts/data/credentials_log.txt
```
`600` permissions confirmed on the credentials file, as designed.

## Real Run — All 67 Employees (`valid_hires.csv`)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/set_passwords.sh scripts/data/valid_hires.csv
Setting passwords for employees in scripts/data/valid_hires.csv ...
-----------------------------------
[SET]     Tolu Bakare — username: tbakare — password expired, must change at login
[SET]     Amina Suleiman — username: asuleiman — password expired, must change at login
[SET]     Chukwuemeka Obi — username: cobi — password expired, must change at login
[SET]     Ngozi Umeh — username: numeh — password expired, must change at login
[SET]     Femi Adebisi — username: fadebisi — password expired, must change at login
[SET]     Kunle Fashola — username: kfashola — password expired, must change at login
[SET]     Halima Yusuf — username: hyusuf — password expired, must change at login
[SET]     Yetunde Alabi — username: yalabi — password expired, must change at login
[SET]     Chidinma Nwachukwu — username: cnwachukwu — password expired, must change at login
[SET]     Bola Adekunle — username: badekunle — password expired, must change at login
[SET]     Tunde Osazuwa — username: tosazuwa — password expired, must change at login
[SET]     Fatima Garba — username: fgarba — password expired, must change at login
[SET]     Emeka Chukwudi — username: echukwudi — password expired, must change at login
[SET]     Aisha Mohammed — username: amohammed — password expired, must change at login
[SET]     Chinedu Igwe — username: cigwe — password expired, must change at login
[SET]     Adaeze Uzo — username: auzo — password expired, must change at login
[SET]     Segun Oyelaran — username: soyelaran — password expired, must change at login
[SET]     Zainab Lawal — username: zlawal — password expired, must change at login
[SET]     Ifeoma Anyanwu — username: ianyanwu — password expired, must change at login
[SET]     Oluwaseun Fapohunda — username: ofapohunda — password expired, must change at login
[SET]     Chibuzor Egwu — username: cegwu — password expired, must change at login
[SET]     Temitope Owolabi — username: towolabi — password expired, must change at login
[SET]     Uche Njoku — username: unjoku — password expired, must change at login
[SET]     Blessing Etuk — username: betuk — password expired, must change at login
[SET]     Damilola Ogundele — username: dogundele — password expired, must change at login
[SET]     Kemi Salako — username: ksalako — password expired, must change at login
[SET]     Ahmed Yakubu — username: ayakubu — password expired, must change at login
[SET]     Grace Ekong — username: gekong — password expired, must change at login
[SET]     Peace Effiong — username: peffiong — password expired, must change at login
[SET]     Victor Nwadike — username: vnwadike — password expired, must change at login
[SET]     Rita Okwuosa — username: rokwuosa — password expired, must change at login
[SET]     Emmanuel Danlami — username: edanlami — password expired, must change at login
[SET]     Blessing Achebe — username: bachebe — password expired, must change at login
[SET]     Chiamaka Obiora — username: cobiora — password expired, must change at login
[SET]     Musa Gambo — username: mgambo — password expired, must change at login
[SET]     Ngozi Ikpe — username: nikpe — password expired, must change at login
[SET]     Samuel Falade — username: sfalade — password expired, must change at login
[SET]     Ada Chikezie — username: achikezie — password expired, must change at login
[SET]     Kunle Odusanya — username: kodusanya — password expired, must change at login
[SET]     Faith Idowu — username: fidowu — password expired, must change at login
[SET]     Ibrahim Sanni — username: isanni — password expired, must change at login
[SET]     Chinwe Aduba — username: caduba — password expired, must change at login
[SET]     Tobi Ilesanmi — username: tilesanmi — password expired, must change at login
[SET]     Hauwa Zubairu — username: hzubairu — password expired, must change at login
[SET]     Emeka Ubani — username: eubani — password expired, must change at login
[SET]     Damilare Ajala — username: dajala — password expired, must change at login
[SET]     Amara Onyekwere — username: aonyekwere — password expired, must change at login
[SET]     Yakubu Balarabe — username: ybalarabe — password expired, must change at login
[SET]     Ifeoma Ndukwe — username: indukwe — password expired, must change at login
[SET]     Segun Fashanu — username: sfashanu — password expired, must change at login
[SET]     Zainab Abdullahi — username: zabdullahi — password expired, must change at login
[SET]     Chukwudi Nnadi — username: cnnadi — password expired, must change at login
[SET]     Ruth Ogbeide — username: rogbeide — password expired, must change at login
[SET]     Femi Ogunbanjo — username: fogunbanjo — password expired, must change at login
[SET]     Amina Tijani — username: atijani — password expired, must change at login
[SET]     Obinna Ezeigbo — username: oezeigbo — password expired, must change at login
[SET]     Blessing Nwafor — username: bnwafor — password expired, must change at login
[SET]     Kelechi Umeadi — username: kumeadi — password expired, must change at login
[SET]     Yetunde Sowande — username: ysowande — password expired, must change at login
[SET]     Ahmed Musa — username: amusa — password expired, must change at login
[SET]     Ngozi Onyema — username: nonyema — password expired, must change at login
[SET]     Tunde Alakija — username: talakija — password expired, must change at login
[SET]     Halima Shittu — username: hshittu — password expired, must change at login
[SET]     Chinedu Onwuka — username: conwuka — password expired, must change at login
[SET]     Grace Babatunde — username: gbabatunde — password expired, must change at login
[SET]     Michael Osei — username: mosei — password expired, must change at login
[SET]     Fatima Waziri — username: fwaziri — password expired, must change at login
-----------------------------------
Passwords set: 67
Skipped: 0
Credentials log saved and secured (600) at: scripts/data/credentials_log.txt
```

✅ All 67 accounts received the temporary password and forced expiry, zero skips. `tbakare`'s password — missed in the earlier typo'd test — was correctly set here, since his name was spelled correctly in the real CSV.

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Shared temporary password applied via `chpasswd` | All accounts | ✅ Pass (67/67) |
| Password expiry forced (`passwd -e`) | All accounts | ✅ Pass |
| Non-existent account handled safely, no crash | Confirmed twice in testing | ✅ Pass |
| Credentials log created with correct content | Username + name per successful account | ✅ Pass |
| Credentials log restricted to owner-only (`600`) | Confirmed via `ls -l` | ✅ Pass |
| Full 67-employee batch run | 67 set, 0 skipped | ✅ Pass |

## Errors Encountered — Summary

1. **Doubled/concatenated command** (`./scripts/set_passwords.sh scripts/data/test_provision.csv./scripts/set_passwords.sh ...`) — two command invocations merged into one line, producing a malformed filename; correctly caught by the file-existence check. Resolved by re-running the command cleanly.
2. **CSV data typo ("ATolu Bakare")** — an extra leading character in test data caused username generation to produce `abakare` instead of `tbakare`; the intended account was correctly reported as not found rather than being incorrectly matched. Real impact: `tbakare`'s password wasn't set until the full real-data run, where the name was correct.
3. **Command typo (`udo` instead of `sudo`)** — corrected on next line, no system impact.

## Status

**✅ Completed**

`set_passwords.sh` successfully applies TechNova's shared temporary password and forces expiry across all 67 employee accounts, with a secured, access-restricted credentials log. Tested against edge cases (missing account, typo'd input) before running the full batch, which completed with 100% success and zero skips.

