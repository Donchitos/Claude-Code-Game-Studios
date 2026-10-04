# Skill Test Spec: /localize

## Skill Summary

`/localize` runs the localization pipeline through one required subcommand:
`scan`, `extract`, `validate`, `status`, `brief`, `cultural-review`,
`vo-pipeline`, `rtl-check`, `freeze` or `qa`. It works on a single source string
table under `assets/data/strings/` (`strings-en.json` is the English source; the
other locales sit beside it) and writes reports under `production/localization/`.

`scan`, `validate` and `status` are read-only. `extract` shows a diff of new
keyed entries and asks "May I write these new entries to
`assets/data/strings/strings-en.json`?" before appending only the diff; its
verdict is **COMPLETE**. With no subcommand the skill prints usage and stops with
verdict **FAIL** — missing required subcommand. A scan whose code root cannot be
resolved reports `NOT ASSESSED — code root unresolved`; a status run with no
string table reports `NOT ASSESSED — no string table found`. `cultural-review`
and `qa` spawn `localization-lead`; `qa` issues a per-locale
PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL verdict, first match FAIL →
NOT ASSESSED → PASS WITH CONDITIONS → PASS. Its checks are playthrough-based, so a
locale nobody has played is NOT ASSESSED, and the release gate does not count it
as passed. No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, FAIL, NOT ASSESSED, PASS WITH CONDITIONS
- [ ] Contains "May I write" collaborative protocol language before writing the string table or a report
- [ ] Has a next-step handoff (the Recommended Workflow chain ending in `/gate-check release`)
- [ ] The QA gate note is tiered: at `workflow: full` the Polish → Release gate requires PASS or PASS WITH CONDITIONS for every translated locale being shipped (recommended at `standard`, dropped at `minimal`)
- [ ] The `freeze` question names the file it writes — "This writes `production/localization/freeze-status.md`" — before the user answers

---

## Director Gate Checks

None. `/localize` is a pipeline utility and spawns no director. The only agent
it spawns is `localization-lead` (an operations-tier agent), and only in the
`cultural-review` and `qa` modes.

---

## Test Cases

### Case 1: Extract — New Strings Keyed and Appended After Approval

**Fixture:**
- `project.yaml` has `engine.name: Godot`, so the code root is `src/`
- `src/ui/hud.gd` wraps three strings in `tr()` that have no entry in
  `assets/data/strings/strings-en.json`
- No `production/localization/freeze-status.md` exists

**Input:** `/localize extract`

**Expected behavior:**
1. Skill scans source files for localized string references and compares them
   against the table in `assets/data/strings/`
2. Skill proposes one new entry per unkeyed string, with a key in the form
   `[category].[subcategory].[description]` (e.g. `ui.hud.health_label`)
3. Each new entry carries a `context` field: where it appears, maximum length,
   placeholder meaning
4. Skill presents the diff and asks "May I write these new entries to
   `assets/data/strings/strings-en.json`?"
5. On approval it writes only the new entries (not a full replacement);
   verdict is COMPLETE

**Assertions:**
- [ ] Proposed keys follow `[category].[subcategory].[description]`
- [ ] Every new entry includes a `context` field
- [ ] The diff is shown and "May I write" names `assets/data/strings/strings-en.json` before any write
- [ ] Only the three new entries are written — existing entries are not rewritten
- [ ] Verdict is COMPLETE

---

### Case 2: No Subcommand — Usage and FAIL

**Fixture:**
- Any project state

**Input:** `/localize`

**Expected behavior:**
1. Skill finds no subcommand in the argument
2. Skill outputs usage (the ten modes) and stops
3. Verdict is FAIL — missing required subcommand

**Assertions:**
- [ ] Usage listing the available modes is printed
- [ ] Verdict is FAIL with the reason "missing required subcommand"
- [ ] No scan, extract or validation work is performed
- [ ] No file is written and no "May I write" ask appears

---

### Case 3: Validate — Gaps Reported by Locale, Nothing Written

**Fixture:**
- `assets/data/strings/` holds `strings-en.json`, `strings-fr.json` and
  `strings-de.json`
- `strings-de.json` lacks 4 keys present in the English source
- One French entry omits the `{playerName}` placeholder its English source has

**Input:** `/localize validate`

**Expected behavior:**
1. Skill reads every string table file in `assets/data/strings/`
2. For `de` it reports the 4 keys as Completeness gaps
3. For `fr` it reports a Placeholder mismatch on the affected key
4. Results are grouped by locale and severity
5. Skill writes nothing — validate is read-only

**Assertions:**
- [ ] The 4 missing keys are named and attributed to the `de` locale
- [ ] The placeholder mismatch is reported against the `fr` locale and its key
- [ ] Output is grouped by locale and severity
- [ ] No file is written or modified, and no "May I write" ask appears

---

### Case 4: Status With No String Table — NOT ASSESSED

**Fixture:**
- `assets/data/strings/` does not exist

**Input:** `/localize status`

**Expected behavior:**
1. Skill looks for the source string table and finds none
2. The whole status output is `NOT ASSESSED — no string table found`
3. Skill does not produce a coverage matrix of zeros, and does not pre-fill the
   source row as `100%`

**Assertions:**
- [ ] Output is `NOT ASSESSED — no string table found`
- [ ] No coverage matrix with zero counts is produced
- [ ] The source locale is not reported as `100%` coverage
- [ ] No file is written (status is read-only)

---

### Case 5: Director Gate Check — None; Cultural Review Uses localization-lead

**Fixture:**
- `assets/data/strings/strings-en.json` exists with player-facing strings
- Any review mode

**Input:** `/localize cultural-review`

**Expected behavior:**
1. Skill spawns `localization-lead` to audit strings and assets for cultural
   sensitivity
2. Findings are presented as a table with a severity of BLOCKING, ADVISORY or
   NOTE per finding
3. Skill asks "May I write this cultural review report to
   `production/localization/cultural-review-[date].md`?"
4. No director agent is spawned and no gate ID appears in output

**Assertions:**
- [ ] `localization-lead` is the only agent spawned
- [ ] No director gate (creative, technical, producer, art) is invoked and no gate skip message appears
- [ ] Each finding carries BLOCKING, ADVISORY or NOTE severity
- [ ] "May I write" names `production/localization/cultural-review-[date].md` before the report is written

---

### Case 6: Scan With an Unresolved Code Root — NOT ASSESSED, never "no hardcoded strings"

**Fixture:**
- `project.yaml` has no `engine.name`; `.claude/docs/technical-preferences.md`
  reads `[TO BE CONFIGURED]`
- Both `src/` and `Assets/` exist and hold UI code with hardcoded strings
  (ambiguous tree)

**Input:** `/localize scan`

**Expected behavior:**
1. Skill tries to resolve the code root and cannot (no engine, two candidate roots)
2. It reports `NOT ASSESSED — code root unresolved` for the hardcoded-string
   search and says which checks did not run
3. It does not guess `src/`, and does not report zero hits or "no hardcoded
   strings found" — that would read as "nothing to localize"
4. Nothing is written — scan is read-only

**Assertions:**
- [ ] Output reads `NOT ASSESSED — code root unresolved` for the code search
- [ ] No "no hardcoded strings" or zero-hit result is reported
- [ ] The code root is not assumed to be `src/`
- [ ] No file is written and no "May I write" ask appears

---

### Case 7: QA on a Locale Nobody Has Played — NOT ASSESSED

**Fixture:**
- `assets/data/strings/strings-en.json` and `strings-fr.json` exist and validate
  cleanly
- No one has played the French build: there are no in-game observations for the
  functional, overflow, contextual-accuracy or VO checks

**Input:** `/localize qa`

**Expected behavior:**
1. Skill spawns `localization-lead` for the QA plan
2. The playthrough-based checks have no results, and no BLOCKING finding is open,
   so the French verdict is **NOT ASSESSED**, naming each check that did not run
3. The verdict is not PASS or PASS WITH CONDITIONS on the strength of the string
   tables alone
4. Skill asks "May I write this localization QA report to
   `production/localization/loc-qa-fr-[date].md`?"; the report says the locale
   has not passed QA for the release gate

**Assertions:**
- [ ] The French Status is NOT ASSESSED, with the unrun checks named
- [ ] No PASS or PASS WITH CONDITIONS is issued for an unplayed locale
- [ ] "May I write" names the loc-qa report path before it is written
- [ ] The report does not present the locale as cleared for the Polish → Release gate

---

## Protocol Compliance

- [ ] Stops with usage and verdict FAIL when no subcommand is given
- [ ] `scan`, `validate` and `status` write no files
- [ ] Asks "May I write" with the target path before writing the string table (extract) or any report (brief, cultural-review, vo-pipeline script, rtl-check, qa)
- [ ] Extract writes only the diff of new entries, never a full replacement of the table
- [ ] Reports NOT ASSESSED instead of zero results when the code root or the string table is missing
- [ ] `qa` issues PASS, PASS WITH CONDITIONS, NOT ASSESSED or FAIL per locale, first match FAIL → NOT ASSESSED → PASS WITH CONDITIONS → PASS
- [ ] Ends with the Recommended Workflow chain / `/gate-check release` handoff

---

## Coverage Notes

- `scan` with a resolved code root (findings with file paths and line numbers)
  is not separately tested; Case 6 covers the unresolved root.
- `extract` while `freeze-status.md` shows Status: ACTIVE (new keys appended to
  `## Post-Freeze Changes` with a freeze-violation warning) is not tested.
- `freeze` (pre-freeze checklist and `AskUserQuestion` [A]/[B]), `brief`,
  `vo-pipeline` and `rtl-check` are not exercised by a dedicated case; `qa` is
  covered only for its NOT ASSESSED branch (Case 7).
- The `qa` gate note — a FAIL blocks release for that locale only — needs a live
  run with multiple locales to verify.
