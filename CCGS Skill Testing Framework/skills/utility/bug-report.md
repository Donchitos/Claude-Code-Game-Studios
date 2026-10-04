# Skill Test Spec: /bug-report

## Skill Summary

`/bug-report` has four modes, chosen from the argument: a plain description
(**Description Mode**), `analyze [path]` (**Analyze Mode** — read code and
report potential bugs), `verify [BUG-ID]` (**Verify Mode**) and `close [BUG-ID]`
(**Close Mode**). With no argument it asks for a bug description first.

Description Mode parses the description, searches the codebase with Grep/Glob
for related files, and drafts the report template: Title, ID `BUG-[NNNN]`,
Severity on the `S1-Critical / S2-High / S3-Medium / S4-Low` scale, Priority
on the `P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix` ladder
(which must match `/bug-triage`), Status `Open`, Classification (Category,
System, Frequency, Regression — for a bug spanning systems, `System` is the one
whose code must change), Environment (Build, Platform, Scene/Level),
Reproduction Steps with Expected and Actual Result, and Technical Context
(likely affected files, related systems). It presents the report and asks
"May I write this to `production/qa/bugs/BUG-[NNNN].md`?" — `Verdict: **COMPLETE**`
on write, `Verdict: **BLOCKED**` if declined. The ID is the highest existing
number plus one; several reports in one run (Analyze Mode) take consecutive IDs,
and one ask names every file. Next steps: `/bug-triage`, and
`/hotfix [BUG-ID]` for S1/S2. No director gates are used.

Verify and Close Mode find the bug file by its number, whatever its padding —
an older three-digit file with a slug included. Verify runs a related test with
`commands.test` from `project.yaml` (never a runner line from memory). When no
test ran — none covers the bug, `commands.test` is unset, or the run did not
complete — or the bug is Visual or UI, it asks whether the user played the
reproduction steps: `[No longer occurs]` → VERIFIED FIXED, recorded as a manual
verification with the build; `[Still occurs]` → STILL PRESENT; `[Not played yet]`
→ CANNOT VERIFY. It asks "May I update" before setting the Status; only a
`Verified Fixed` bug can be closed, and Close Mode shows the closure record and
asks before it writes anything.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED (and VERIFIED FIXED / STILL PRESENT / CANNOT VERIFY for Verify Mode)
- [ ] Contains "May I write" language before writing the report and "May I update" before changing an existing bug file
- [ ] Has a next-step handoff (`/bug-triage`; `/hotfix [BUG-ID]` for S1/S2; `/bug-report verify` → `close`)

---

## Director Gate Checks

None. `/bug-report` is an operational documentation skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — User describes a crash, full report produced

**Fixture:**
- `production/qa/bugs/` does not exist yet
- The code root contains a boss-arena scene script

**Input:** `/bug-report The game crashes to desktop every time the player enters the boss arena — progress is blocked`

**Expected behavior:**
1. Description Mode (no keyword)
2. Skill parses the description and greps the codebase for boss-arena files
3. Drafts the report template: Category `Crash`, Severity `S1-Critical`,
   Status `Open`, reproduction steps, Expected Result (no crash) and Actual
   Result (crash to desktop), likely affected files from the search
4. Globs `production/qa/bugs/BUG-*.md`, finds none, allocates `BUG-0001`, presents the
   report and asks "May I write this to `production/qa/bugs/BUG-0001.md`?"
5. On approval writes the file, creating `production/qa/bugs/`; Verdict is COMPLETE
6. Next steps: `/bug-triage`, and `/hotfix [BUG-ID]` because the bug is S1

**Assertions:**
- [ ] Report contains Title, ID, Severity, Priority, Status, Category, System, Build, Reproduction Steps, Expected Result and Actual Result
- [ ] Severity uses the S1–S4 scale (`S1-Critical` here) and Priority uses the P1–P4 labels
- [ ] "Likely affected files" is filled from the codebase search
- [ ] "May I write" names `production/qa/bugs/BUG-0001.md` — no bug files exist yet
- [ ] Variant — with `BUG-0001.md` and `BUG-0003.md` already present, the new ID is
      `BUG-0004`: the highest existing number plus one, not the file count plus one
- [ ] Verdict is COMPLETE after the write
- [ ] `/hotfix [BUG-ID]` is suggested because severity is S1

---

### Case 2: No Argument — Asks for a description before drafting

**Fixture:**
- No existing bug reports

**Input:** `/bug-report`

**Expected behavior:**
1. No argument → skill asks the user for a bug description before proceeding
2. No template is drafted and nothing is written until a description arrives
3. Once the user answers ("Sometimes the audio cuts out"), Description Mode proceeds;
   unknown values (e.g. Build, Frequency) remain visible in the draft for the user to correct
4. "May I write" is asked before the file is created

**Assertions:**
- [ ] Skill asks for a description instead of drafting from nothing
- [ ] No report is drafted or written before the description is given
- [ ] "May I write" precedes the write
- [ ] Verdict is COMPLETE only after the file is written

---

### Case 3: Close Mode — Bug not yet verified is refused

**Fixture:**
- `production/qa/bugs/BUG-0007.md` exists with `**Status**: Open`

**Input:** `/bug-report close BUG-0007`

**Expected behavior:**
1. Close Mode reads `production/qa/bugs/BUG-0007.md`
2. Status is not `Verified Fixed`, so the skill stops:
   "Bug BUG-0007 must be Verified Fixed before it can be closed. Run `/bug-report verify BUG-0007` first."
3. No Closure Record is appended and the Status field is not changed

**Assertions:**
- [ ] The "must be Verified Fixed before it can be closed" message is shown
- [ ] `/bug-report verify BUG-0007` is named as the next step
- [ ] No Closure Record is written and `BUG-0007.md` is not edited
- [ ] No "May I update" ask is issued (nothing to update)

---

### Case 4: Multi-System Bug — One report, primary and related systems

**Fixture:**
- No existing reports
- The code root has a save manager and a level-complete UI screen

**Input:** `/bug-report After finishing a level, the save system freezes and the UI doesn't show the completion screen`

**Expected behavior:**
1. Description Mode drafts **one** report
2. Classification `System` names the save system — its freeze is what must be
   fixed, and the missing completion screen follows from it; Technical Context
   "Related systems" lists the UI; "Likely affected files" lists files for both
   from the codebase search
3. Skill asks "May I write" once for one `BUG-[NNNN].md`
4. Verdict is COMPLETE after the write

**Assertions:**
- [ ] A single report is created (not one per system)
- [ ] `System` is the save system, the one whose code must change; the UI is under Related systems
- [ ] Likely affected files cover both systems
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — Analyze Mode, no gate

**Fixture:**
- `src/save/save_manager.gd` exists and contains an unguarded null dereference and an unclosed file handle
- `production/qa/bugs/` holds `BUG-0011.md` (the highest existing number)

**Input:** `/bug-report analyze src/save/save_manager.gd`

**Expected behavior:**
1. Analyze Mode reads the target file
2. Identifies potential bugs (null reference, resource leak) and drafts one report
   per bug with the trigger scenario and a recommended fix
3. Allocates consecutive IDs, `BUG-0012` and `BUG-0013`, one per report
4. Presents the reports and asks once, naming both files: "May I write these to
   `production/qa/bugs/BUG-0012.md`, `production/qa/bugs/BUG-0013.md`?"
5. No director agents are spawned; no gate IDs appear

**Assertions:**
- [ ] One report per potential bug, each with a trigger scenario and recommended fix
- [ ] The two reports get different, consecutive IDs (`BUG-0012`, `BUG-0013`) — never the same ID twice
- [ ] The single "May I write" ask names every file before any report is saved
- [ ] No director gate is invoked and no gate skip messages appear
- [ ] If the user declines, Verdict is BLOCKED and nothing is written

---

### Case 6: Verify Mode — older three-digit file found by its number, CANNOT VERIFY

**Fixture:**
- `production/qa/bugs/` holds a bug file for bug 42 written in the older form:
  a three-digit number followed by a slug (`-save-corruption.md`), with
  `**Status**: Fixed — Pending Verification`
- The bug's root-cause code path is gone from `src/save/`, but no test in
  `tests/` covers the save system, and the reproduction needs a console suspend
  that no automated check can drive

**Input:** `/bug-report verify BUG-0042`

**Expected behavior:**
1. Verify Mode globs `production/qa/bugs/BUG-*.md` and takes the file whose
   number is 42 — the three-digit, slugged file — instead of stopping on a
   missing `BUG-0042.md`
2. It checks the root-cause code path (changed) and looks for a related test
   (none), then greps for the pattern recurring
3. No test ran, so it asks via `AskUserQuestion` whether the user played the
   reproduction steps on a build with the fix — `[No longer occurs]` /
   `[Still occurs]` / `[Not played yet]`; the user answers `[Not played yet]`
4. The verdict is **CANNOT VERIFY**: it names what is missing (no related test)
   and says that playing the reproduction steps settles it
5. It asks "May I update `production/qa/bugs/[that file]` to set Status: … Cannot
   Verify?", naming the file it found
6. It does not suggest `/bug-report close` — only a `Verified Fixed` bug can be
   closed

**Assertions:**
- [ ] The older three-digit file is found by its number; the skill does not report "No bug BUG-0042"
- [ ] The manual-play question is asked, with the three answers, before a verdict is given
- [ ] Verdict is CANNOT VERIFY, not VERIFIED FIXED — the changed code path is not taken as a pass, and "Not played yet" is not a pass
- [ ] Playing the reproduction steps is named as what would settle it
- [ ] The "May I update" ask names the file actually found, before the Status changes
- [ ] Close is not offered while the verdict is CANNOT VERIFY

---

### Case 7: Verify then Close — no test covers the bug, the user's play settles it

**Fixture:**
- `project.yaml` has no `modes` block (so `qa.level: minimal` — tests are waived)
  and no `commands` block
- `production/qa/bugs/BUG-0005.md`: Category `UI`, System `HUD`, "health bar does
  not update after healing", `**Status**: Fixed — Pending Verification`
- No test in the engine's test root covers the HUD

**Input:** `/bug-report verify BUG-0005`, then `/bug-report close BUG-0005`

**Expected behavior:**
1. Verify finds no related test and runs no runner line of its own — `commands.test`
   is unset, and it says so
2. It asks via `AskUserQuestion` whether the user played the reproduction steps
   on a build with the fix, and which build — `[No longer occurs]` /
   `[Still occurs]` / `[Not played yet]`; the user answers `[No longer occurs]`,
   build `0.3.1`
3. Verdict **VERIFIED FIXED**, a manual verification; it asks "May I update
   `production/qa/bugs/BUG-0005.md` to set Status: Verified Fixed …?" and, on
   yes, writes the Status with `**Verified by**: [user], manual, build 0.3.1`
4. Next step: `/bug-report close BUG-0005`
5. Close reads `Verified Fixed`, shows the closure record (`Verified by` from the
   verify record, `Regression test: Manual verification`) and the Status change,
   and asks "May I update `production/qa/bugs/BUG-0005.md` to mark it Closed?"
   before appending anything or changing the Status
6. On yes it appends the Closure Record and sets `**Status**: Closed`

**Assertions:**
- [ ] No test command is written from memory; the unset `commands.test` is named
- [ ] The manual-play question is asked with the three answers and the build is recorded as the user gave it
- [ ] Verdict is VERIFIED FIXED, recorded as manual (`[user], manual, build 0.3.1`) — a bug no test covers can reach Verified Fixed
- [ ] Close asks "May I update … to mark it Closed?" before the Closure Record is appended or the Status changed
- [ ] The Closure Record's Regression test reads "Manual verification"
- [ ] Variant — answering `[Still occurs]` gives STILL PRESENT (the bug is reopened and `/hotfix [BUG-ID]` suggested); answering `[Not played yet]` gives CANNOT VERIFY

---

## Protocol Compliance

- [ ] Selects the mode from the argument; asks for a description when none is given
- [ ] Uses the S1–S4 severity scale and the P1–P4 priority labels shared with `/bug-triage`
- [ ] Verify runs a related test with `commands.test` from `project.yaml`, never a runner line written from memory
- [ ] Verify says VERIFIED FIXED only when every check that applies passed — the related tests ran and passed, or, with no test run (or for a Visual or UI bug), the user played the reproduction steps on a named build and it no longer occurs, recorded as a manual verification; "Not played yet" with nothing else to settle it is CANNOT VERIFY
- [ ] The Reporter field never holds an email address or account ID taken from the session
- [ ] Searches the codebase for affected files before drafting
- [ ] Asks "May I write this to `production/qa/bugs/BUG-[NNNN].md`?" before writing
- [ ] Asks "May I update" before changing an existing bug file (Verify / Close); Close Mode shows the closure record and asks before appending it
- [ ] Finds the bug file by its number in Verify and Close Mode, and never closes a bug that is not `Verified Fixed`
- [ ] Verdict is COMPLETE on write, BLOCKED when the user declines

---

## Coverage Notes

- Verify Mode on a bug whose related test runs and passes (VERIFIED FIXED with
  no manual question) is not separately tested; Case 6 covers CANNOT VERIFY,
  Case 7 a manual VERIFIED FIXED and, as variants, STILL PRESENT.
- Close Mode's triage-report reference note is not separately tested.
- Verify or close with a number no file carries ("No bug [BUG-ID] in
  `production/qa/bugs/`", Verdict BLOCKED) is not separately tested.
