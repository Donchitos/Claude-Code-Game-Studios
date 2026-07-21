# Skill Test Spec: $bug-report

## Skill Summary

`$bug-report` creates a structured bug report document from a user description.
It produces a report with the following required fields: Title, Repro Steps,
Expected Behavior, Actual Behavior, Severity (CRITICAL/HIGH/MEDIUM/LOW), Affected
System(s), and Build/Version. If the user's initial description is missing any
required field, the skill asks follow-up questions to fill the gaps before
producing the draft.

The skill checks for possibly duplicate reports (by comparing to existing files
in `production/bugs/`) and offers to link rather than create a new report. Each
report is written to `production/bugs/bug-[date]-[slug].md` after a "May I write"
ask. No director gates are used — bug reporting is an operational utility.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the report
- [ ] Has a next-step handoff (e.g., `$bug-triage` to reprioritize, `$hotfix` for critical)

---

## Director Gate Checks

None. `$bug-report` is an operational documentation skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — User describes a crash, full report produced

**Fixture:**
- `production/bugs/` directory exists and is empty
- No similar existing reports

**Input:** `$bug-report` (user describes: "Game crashes when player enters the boss arena")

**Expected behavior:**
1. Skill extracts: Title = "Game crashes when entering boss arena"
2. Skill recognizes crash reports as CRITICAL severity
3. Skill confirms repro steps, expected (no crash), actual (crash), affected system
   (arena/boss), and build version with the user
4. Skill drafts the full structured report
5. Skill asks "May I write to `production/bugs/bug-2026-04-06-game-crashes-boss-arena.md`?"
6. File is written on approval; verdict is COMPLETE

**Assertions:**
- [ ] All 7 required fields are present in the report
- [ ] Severity is CRITICAL for a crash report
- [ ] Filename follows the `bug-[date]-[slug].md` convention
- [ ] "May I write" is asked with the full file path
- [ ] Verdict is COMPLETE

---

### Case 2: Minimal Input — Skill asks follow-up questions for missing fields

**Fixture:**
- User provides: "Sometimes the audio cuts out"
- No existing reports

**Input:** `$bug-report`

**Expected behavior:**
1. Skill identifies missing required fields: repro steps, expected vs. actual,
   severity, affected system, build
2. Skill asks targeted follow-up questions for each missing field (one at a time
   or in a structured prompt)
3. User provides answers
4. Skill compiles complete report from answers
5. Skill asks "May I write?" and writes on approval

**Assertions:**
- [ ] At least 3 follow-up questions are asked to fill missing fields
- [ ] Each required field is filled before the report is finalized
- [ ] Report is not written until all required fields are present
- [ ] Verdict is COMPLETE after all fields are filled and file is written

---

### Case 3: Possible Duplicate — Offers to link rather than create new

**Fixture:**
- `production/bugs/bug-2026-03-20-audio-cut-out.md` already exists with
  similar title and MEDIUM severity

**Input:** `$bug-report` (user describes: "Audio randomly stops working")

**Expected behavior:**
1. Skill scans existing reports and finds the similar audio bug
2. Skill reports: "A similar bug report exists: bug-2026-03-20-audio-cut-out.md"
3. Skill presents options: link as duplicate (add note to existing), create new anyway
4. If user chooses link: skill adds a cross-reference note to the existing file
   (asks "May I update the existing report?")
5. If user chooses create new: normal report creation proceeds

**Assertions:**
- [ ] Existing similar report is surfaced before creating a new one
- [ ] User is given the choice (not forced to link or create)
- [ ] If linking: "May I update" is asked before modifying the existing file
- [ ] Verdict is COMPLETE in either path

---

### Case 4: Multi-System Bug — Report created with multiple system tags

**Fixture:**
- No existing reports

**Input:** `$bug-report` (user describes: "After finishing a level, the save system
  freezes and the UI doesn't show the completion screen")

**Expected behavior:**
1. Skill identifies 2 affected systems from the description: Save System and UI
2. Report is drafted with both systems listed under Affected System(s)
3. Severity is assessed (likely HIGH — data loss risk from save freeze)
4. Skill asks "May I write" with the appropriate filename
5. Report is written with both systems tagged; verdict is COMPLETE

**Assertions:**
- [ ] Both affected systems are listed in the report
- [ ] Single report is created (not one per system)
- [ ] Severity reflects the most impactful component (save freeze → HIGH or CRITICAL)
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; bug reporting is operational

**Fixture:**
- Any bug description provided

**Input:** `$bug-report`

**Expected behavior:**
1. Skill creates and writes the bug report
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Skill reaches COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Collects all 7 required fields before drafting the report
- [ ] Asks follow-up questions for any missing required fields
- [ ] Checks for similar existing reports before creating a new one
- [ ] Asks "May I write to `production/bugs/bug-[date]-[slug].md`?" before writing
- [ ] Verdict is COMPLETE when the report file is written

---

## Coverage Notes

- The case where the user provides a severity that seems too low for the
  described impact (e.g., LOW for a crash) is not tested; the skill may suggest
  a higher severity but ultimately respects user input.
- Build/version field is required but may be "unknown" if the user doesn't know —
  this is accepted as a valid value and not tested separately.
- Report slug generation (sanitizing the title into a filename) is an
  implementation detail not assertion-tested here.
