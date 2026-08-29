# Chapter 2, Task 7 — Automated Welcome Email Simulation

## Business Requirement

Once `set_passwords.sh` runs, a new hire's credentials exist only in the restricted `credentials_log.txt` — accessible to IT, but with no actual communication prepared to hand the employee. This task simulates that final onboarding step: for every successfully provisioned employee, generate a personalized welcome message as a text file, ready to be pasted into a real email once mail infrastructure exists in a later chapter.

## Design Decision — Files, Not Fake Email Sending

Faking SMTP-style output would misrepresent what's actually happening. Generating clean, individual text files that could be copy-pasted into an email client (or fed into real mail delivery later) is honest about what this task automates: content generation, not delivery.

## The Script — `generate_welcome_messages.sh`

```bash
#!/bin/bash

# Chapter 2, Task 7 — Automated Welcome Email Simulation
# Generates a personalized welcome message file for each new hire.

INPUT_FILE="$1"
MESSAGES_DIR="$(dirname "$INPUT_FILE")/welcome_messages"

source "$(dirname "$0")/log_utils.sh"
init_log

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-valid-hires-csv>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file '$INPUT_FILE' not found."
    exit 1
fi

mkdir -p "$MESSAGES_DIR"

generated_count=0
skipped_count=0

generate_username() {
    local full_name="$1"
    local first_name last_name
    first_name=$(echo "$full_name" | awk '{print $1}')
    last_name=$(echo "$full_name" | awk '{print $NF}')
    local first_initial="${first_name:0:1}"
    echo "${first_initial}${last_name}" | tr '[:upper:]' '[:lower:]'
}

generate_welcome_message() {
    local full_name="$1"
    local department="$2"
    local role="$3"

    local username
    username=$(generate_username "$full_name")

    if ! id "$username" &>/dev/null; then
        echo "[SKIPPED] $full_name ($username) — no account exists, skipping welcome message"
        log_event "generate_welcome_messages.sh" "SKIP" "$full_name ($username) — no account exists"
        skipped_count=$((skipped_count + 1))
        return
    fi

    # Skip locked/offboarded accounts — no reason to "welcome" someone
    # whose access has already been revoked.
    if sudo passwd -S "$username" 2>/dev/null | grep -q " L "; then
        echo "[SKIPPED] $full_name ($username) — account is locked/offboarded"
        log_event "generate_welcome_messages.sh" "SKIP" "$full_name ($username) — account is locked/offboarded"
        skipped_count=$((skipped_count + 1))
        return
    fi

    local message_file="$MESSAGES_DIR/${username}_welcome.txt"

    cat > "$message_file" << EOF
Subject: Welcome to TechNova Solutions Ltd., $full_name!

Hi $full_name,

Welcome to the $department team at TechNova Solutions Ltd.! We're glad
to have you on board as our new $role.

YOUR LOGIN DETAILS
-------------------
Username: $username
Temporary Password: (shared with you separately by IT — see your
department administrator if you have not received it)

IMPORTANT: You are required to change your password immediately the
first time you log in. The system will prompt you automatically.

FIRST-DAY CHECKLIST
--------------------
- Log in and set your new password
- Read your department handbook (ask your administrator for access)
- Introduce yourself on your team's communication channel
- Confirm your workstation/account access with your administrator

If you run into any issues logging in, contact IT support.

Welcome aboard!
TechNova Solutions Ltd. — IT Onboarding
EOF

    if [ -f "$message_file" ]; then
        echo "[GENERATED] $full_name — welcome message saved to $message_file"
        log_event "generate_welcome_messages.sh" "SUCCESS" "$full_name ($username) — welcome message generated"
        generated_count=$((generated_count + 1))
    else
        echo "[FAILED]    $full_name — could not write welcome message"
        log_event "generate_welcome_messages.sh" "FAILURE" "$full_name ($username) — could not write welcome message"
        skipped_count=$((skipped_count + 1))
    fi
}

echo "Generating welcome messages from $INPUT_FILE ..."
echo "-----------------------------------"

while IFS=',' read -r full_name department role; do
    full_name=$(echo "$full_name" | xargs)
    department=$(echo "$department" | xargs)
    role=$(echo "$role" | xargs)

    generate_welcome_message "$full_name" "$department" "$role"
done < <(tail -n +2 "$INPUT_FILE")

echo "-----------------------------------"
echo "Messages generated: $generated_count"
echo "Skipped: $skipped_count"
echo "Saved to: $MESSAGES_DIR"
```

## Code Explanation

- **`if ! id "$username" &>/dev/null`** — same existence-guard pattern used across every earlier script; skips anyone whose account was never actually created.
- **`sudo passwd -S "$username" | grep -q " L "`** — added specifically for this task, after realizing the full employee list includes the 6 people locked/offboarded in Task 6. Checks the account's status line for the ` L ` (locked) flag and skips generating a welcome message for anyone whose access has already been revoked.
- **`cat > "$message_file" << EOF ... EOF`** — a **heredoc**: everything between `<< EOF` and the closing `EOF` is written literally into the file, with variables like `$full_name` still substituted. Cleaner than a long chain of `echo` commands for multi-line content.
- **No real password included** — deliberate. Even in a simulated file, the message directs the employee to get their password from IT/their admin rather than embedding it in plaintext, modeling good practice for when real email delivery exists later.

## Building the Full Company Roster

Unlike earlier tasks, which only touched the 67 recent hires, this task was run against **everyone** — the original 13 Chapter 1 employees, the 4 Appendix 1 department admins, and the 67 from the recent hiring wave.

**Confirming account details for the original 17 (not from memory, from the live system):**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ getent passwd eadeyemi mogunleye ebello bnwachukwu gokoro sadebayo djames dibrahim ceze fakinyemi dojo sakinwale rakinlabi tajayi neke kuche anwosu
eadeyemi:x:1001:1002:Emmanuel Adeyemi:/home/eadeyemi:/bin/bash
mogunleye:x:1002:1002:Miceal Ogunleye:/home/mogunleye:/bin/bash
ebello:x:1003:1002:Esther Bello:/home/ebello:/bin/bash
bnwachukwu:x:1013:1002:Blessing Nwachukwu:/home/bnwachukwu:/bin/bash
gokoro:x:1004:1003:Grace Okoro:/home/gokoro:/bin/bash
sadebayo:x:1005:1003:Sunday Adebayo:/home/sadebayo:/bin/bash
djames:x:1006:1003:David James:/home/djames:/bin/bash
dibrahim:x:1010:1005:Deborah Ibrahim:/home/dibrahim:/bin/bash
ceze:x:1012:1005:Chioma Eze:/home/ceze:/bin/bash
fakinyemi:x:1011:1005:Favour Akinyemi:/home/fakinyemi:/bin/bash
dojo:x:1007:1004:Daniel Ojo:/home/dojo:/bin/bash
sakinwale:x:1008:1004:Samuel Akinwale:/home/sakinwale:/bin/bash
rakinlabi:x:1009:1004:Ruth Akinlabi:/home/rakinlabi:/bin/bash
tajayi:x:1014:1006:Tobiloba Ajayi:/home/tajayi:/bin/bash
neke:x:1015:1007:Ngozi Eke:/home/neke:/bin/bash
kuche:x:1016:1008:Kingsley Uche:/home/kuche:/bin/bash
anwosu:x:1017:1009:Amaka Nwosu:/home/anwosu:/bin/bash
```

**Confirming roles from the actual `responsibility_matrix.txt` files** (rather than guessing) surfaced two corrections to an earlier assumed draft: Favour Akinyemi is actually **Finance Officer** (not Accountant), and Samuel Akinwale is actually **HR Officer** (not HR Assistant).

**Final roster header (`all_employees.csv`):**
```
full_name,department,role
Emmanuel Adeyemi,Engineering,Engineering Manager
Miceal Ogunleye,Engineering,Software Engineer
Esther Bello,Engineering,Software Engineer
Blessing Nwachukwu,Engineering,Department Administrator
Grace Okoro,Sales,Sales Manager
Sunday Adebayo,Sales,Sales Executive
David James,Sales,Sales Executive
Deborah Ibrahim,Finance,Finance Manager
Chioma Eze,Finance,Accountant
Favour Akinyemi,Finance,Finance Officer
Daniel Ojo,HR,HR Manager
Samuel Akinwale,HR,HR Officer
Ruth Akinlabi,HR,HR Coordinator
Tobiloba Ajayi,Marketing,Department Administrator
Ngozi Eke,CustomerSupport,Department Administrator
Kingsley Uche,ProductMgt,Department Administrator
Amaka Nwosu,DevOps,Department Administrator
```

**Known caveat, logged, not fixed here:** Blessing Nwachukwu's "Department Administrator" role is a **placeholder, not confirmed** — she's actually a regular Engineering employee (onboarded in Chapter 1 Task 13, before the automated matrix system existed), so no documented role exists for her anywhere on the system. Similarly, the four Appendix 1 admins' role is confirmed only as "Department Administrator" — no more specific title exists in any record, since those departments never received Chapter 1's full documentation setup.

Full roster assembled by appending the 67 recent hires beneath this header:
```bash
cd ~/Technova-Homelab
cat scripts/data/valid_hires.csv | tail -n +2 >> scripts/data/all_employees.csv
```

## Real Run — Full Company Roster (~85 People)

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ./scripts/generate_welcome_messages.sh scripts/data/all_employees.csv
Generating welcome messages from scripts/data/all_employees.csv ...
-----------------------------------
[GENERATED] Emmanuel Adeyemi — welcome message saved to scripts/data/welcome_messages/eadeyemi_welcome.txt
[GENERATED] Miceal Ogunleye — welcome message saved to scripts/data/welcome_messages/mogunleye_welcome.txt
[GENERATED] Esther Bello — welcome message saved to scripts/data/welcome_messages/ebello_welcome.txt
[GENERATED] Blessing Nwachukwu — welcome message saved to scripts/data/welcome_messages/bnwachukwu_welcome.txt
[GENERATED] Grace Okoro — welcome message saved to scripts/data/welcome_messages/gokoro_welcome.txt
[GENERATED] Sunday Adebayo — welcome message saved to scripts/data/welcome_messages/sadebayo_welcome.txt
[SKIPPED] David James (djames) — account is locked/offboarded
[GENERATED] Deborah Ibrahim — welcome message saved to scripts/data/welcome_messages/dibrahim_welcome.txt
[GENERATED] Chioma Eze — welcome message saved to scripts/data/welcome_messages/ceze_welcome.txt
[GENERATED] Favour Akinyemi — welcome message saved to scripts/data/welcome_messages/fakinyemi_welcome.txt
[GENERATED] Daniel Ojo — welcome message saved to scripts/data/welcome_messages/dojo_welcome.txt
[GENERATED] Samuel Akinwale — welcome message saved to scripts/data/welcome_messages/sakinwale_welcome.txt
[GENERATED] Ruth Akinlabi — welcome message saved to scripts/data/welcome_messages/rakinlabi_welcome.txt
[GENERATED] Tobiloba Ajayi — welcome message saved to scripts/data/welcome_messages/tajayi_welcome.txt
[GENERATED] Ngozi Eke — welcome message saved to scripts/data/welcome_messages/neke_welcome.txt
[GENERATED] Kingsley Uche — welcome message saved to scripts/data/welcome_messages/kuche_welcome.txt
[GENERATED] Amaka Nwosu — welcome message saved to scripts/data/welcome_messages/anwosu_welcome.txt
[SKIPPED]  () — no account exists, skipping welcome message
[GENERATED] Tolu Bakare — welcome message saved to scripts/data/welcome_messages/tbakare_welcome.txt
[GENERATED] Amina Suleiman — welcome message saved to scripts/data/welcome_messages/asuleiman_welcome.txt
[GENERATED] Chukwuemeka Obi — welcome message saved to scripts/data/welcome_messages/cobi_welcome.txt
[GENERATED] Ngozi Umeh — welcome message saved to scripts/data/welcome_messages/numeh_welcome.txt
[SKIPPED] Femi Adebisi (fadebisi) — account is locked/offboarded
[SKIPPED] Kunle Fashola (kfashola) — account is locked/offboarded
... (remaining GENERATED entries for the rest of the 67, omitted here for length)
[SKIPPED] Segun Oyelaran (soyelaran) — account is locked/offboarded
[SKIPPED] Zainab Lawal (zlawal) — account is locked/offboarded
[SKIPPED] Samuel Falade (sfalade) — account is locked/offboarded
-----------------------------------
Messages generated: 78
Skipped: 7
Saved to: scripts/data/welcome_messages
```

## Verification

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls scripts/data/welcome_messages/ | wc -l
78
```
✅ File count matches the script's own reported total exactly.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ grep "locked/offboarded" scripts/data/onboarding_log.txt
[2026-08-29 07:00:39] [generate_welcome_messages.sh] [SKIP] David James (djames) — account is locked/offboarded
[2026-08-29 07:00:40] [generate_welcome_messages.sh] [SKIP] Femi Adebisi (fadebisi) — account is locked/offboarded
[2026-08-29 07:00:40] [generate_welcome_messages.sh] [SKIP] Kunle Fashola (kfashola) — account is locked/offboarded
[2026-08-29 07:00:40] [generate_welcome_messages.sh] [SKIP] Segun Oyelaran (soyelaran) — account is locked/offboarded
[2026-08-29 07:00:41] [generate_welcome_messages.sh] [SKIP] Zainab Lawal (zlawal) — account is locked/offboarded
[2026-08-29 07:00:42] [generate_welcome_messages.sh] [SKIP] Samuel Falade (sfalade) — account is locked/offboarded
```
✅ Confirms all 6 people offboarded in Task 6 (David James included, from the original Chapter 1 offboarding) were correctly excluded from welcome-message generation — nobody with revoked access received a "welcome aboard" message.

**7th skip** — the blank trailing row in the CSV (same harmless pattern seen in Task 6), correctly logged with empty name/username rather than crashing.

## Sample Output

```
Subject: Welcome to TechNova Solutions Ltd., Tolu Bakare!

Hi Tolu Bakare,

Welcome to the Engineering team at TechNova Solutions Ltd.! We're glad
to have you on board as our new Software Engineer.

YOUR LOGIN DETAILS
-------------------
Username: tbakare
Temporary Password: (shared with you separately by IT — see your
department administrator if you have not received it)

IMPORTANT: You are required to change your password immediately the
first time you log in. The system will prompt you automatically.

FIRST-DAY CHECKLIST
--------------------
- Log in and set your new password
- Read your department handbook (ask your administrator for access)
- Introduce yourself on your team's communication channel
- Confirm your workstation/account access with your administrator

If you run into any issues logging in, contact IT support.

Welcome aboard!
TechNova Solutions Ltd. — IT Onboarding
```

## Verification Summary

| Check | Expected | Result |
|---|---|---|
| Welcome message generated for existing, active accounts | 78 messages | ✅ Pass |
| Locked/offboarded accounts correctly excluded | 6 skipped (Task 6's 5 contractors + David James) | ✅ Pass |
| Blank CSV row handled without crash | 1 skipped cleanly | ✅ Pass |
| File count matches script's own reported total | `ls | wc -l` = 78 | ✅ Pass |
| No real password included in message content | Confirmed via sample output | ✅ Pass |
| Roles sourced from actual documentation, not assumed | Verified against 4 real matrix files | ✅ Pass (with 2 corrections made) |

## Known Issues Surfaced or Reconfirmed During This Task

Rather than scattering these across individual task docs, they're being tracked centrally for a Chapter 2 appendix / Chapter 3 cleanup pass:

1. **Blessing Nwachukwu has no documented role anywhere on the system** — "Department Administrator" used in the roster as an unconfirmed placeholder; she is actually a regular Engineering employee.
2. **Test-data contamination in Engineering and Sales matrices is now worse than previously recorded** — 5 duplicate "Auto-Onboarded Employees" headers each (3 from Task 4's original contamination, plus 1 more from Task 5's `test_task5.csv` run, never cleaned up).
3. **23 employees across Marketing, CustomerSupport, ProductMgt, DevOps still have no `responsibility_matrix.txt`** (Task 4 gap, unresolved).
4. **The four Appendix 1 admins have no documented role beyond "Department Administrator."**
5. **`mogunleye`'s GECOS field has a typo** ("Miceal" instead of "Michael") — cosmetic, unfixed.
6. **`offboarding_report.txt` is non-cumulative** — overwritten each run rather than appended (Task 6 finding).

## Status

**✅ Completed**

`generate_welcome_messages.sh` successfully generates personalized onboarding messages for every active employee across the full company roster (~85 people), correctly excluding all locked/offboarded accounts. Roles verified against real documentation rather than assumed, surfacing and correcting two inaccuracies in the process. A running list of known, unresolved issues from across Chapter 2 has been consolidated for future cleanup rather than left scattered.

