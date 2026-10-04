# Skill Test Spec: /tech-debt

## Skill Summary

`/tech-debt` tracks technical debt through four subcommands: `scan`, `add`,
`prioritize` and `report`. With no subcommand it prints usage and stops with
Verdict FAIL. `scan` searches the code root (resolved per engine: `src/`,
`Assets/` or `Source/`) for `TODO`, `FIXME`, `HACK` and `@deprecated` markers,
duplicated blocks, files over 500 lines and functions over 50 lines, sorts the
findings into six debt categories, states how many files it covered, and asks
"May I write these findings to `docs/tech-debt-register.md`?" before appending
(never overwriting) entries — updating a matching `Open` row, and proposing an
`Open` row whose pattern is gone as `Resolved [date]`. New rows follow the
skill's Debt Register Format (next `TD-NNN`, ten columns, an `Added` date). A
scan over zero source files is `NOT ASSESSED — no source files to scan`, an
unresolved code root is `NOT ASSESSED — code root unresolved`, and both write
nothing. `add` collects an
entry through prompts and three `AskUserQuestion` choices, then asks "May I append
this entry to `docs/tech-debt-register.md`?". `prioritize` scores each register
item as `impact ÷ effort` from its Impact and Effort columns, re-sorts
and asks before writing it back. `report` is read-only. No director gates are
invoked. Verdicts: COMPLETE, BLOCKED (user declined a write), FAIL (missing
subcommand), NOT ASSESSED.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, FAIL, NOT ASSESSED
- [ ] Contains "May I write" language (writes `docs/tech-debt-register.md`)
- [ ] Has a next-step handoff (Phase 3: `/sprint-plan`, `/tech-debt report`)

---

## Director Gate Checks

None. Tech debt tracking is an internal codebase analysis skill; no gates are
invoked.

---

## Test Cases

### Case 1: Happy Path — Scan appends new findings to an existing register

**Fixture:**
- `project.yaml`: `engine.name: godot`; `modes.automation` unset (collaborative)
- `docs/tech-debt-register.md` is in the skill's Debt Register Format and has 2 `Open` rows:
  - TD-001 — Code Quality, Files `src/core/save_system.gd`: a `# HACK` workaround for a save-path bug. That `HACK` comment is no longer in the file
  - TD-002 — Code Quality, Files `src/gameplay/combat.gd`: the `# TODO` comments in that file
- `src/gameplay/combat.gd` has 2 `# TODO` comments and 1 `# FIXME` comment
- `src/ui/hud.gd` is 620 lines long; 12 source files in `src/` in total

**Input:** `/tech-debt scan`

**Expected behavior:**
1. Skill resolves the code root to `src/` and scans it for debt indicators
2. Findings include the 2 TODOs, the FIXME (treated as a bug disguised as debt) and `hud.gd` as a file over 500 lines
3. Each finding is sorted into one of the six categories (Architecture, Code Quality, Test, Documentation, Dependency, Performance)
4. The output states the denominator — 12 source files scanned
5. Matching against the register: the 2 TODOs share TD-002's file and kind, so they update TD-002; TD-001's `HACK` is gone, so TD-001 is proposed as `Resolved [date]`; the FIXME and `hud.gd` become new rows TD-003 and TD-004
6. Skill presents the findings and the TD-001 resolution, then asks "May I write these findings to `docs/tech-debt-register.md`?" — one approval covers both
7. On approval, TD-001's Status becomes `Resolved YYYY-MM-DD` and the row stays; TD-002 is updated; TD-003 and TD-004 are appended with all ten columns, Status `Open`, `Added` set to today (`YYYY-MM-DD`) and Priority `—`
8. Verdict: **COMPLETE** — scan findings written to register

**Assertions:**
- [ ] The scan covers the resolved code root `src/` for TODO, FIXME, HACK, `@deprecated`, files >500 lines and functions >50 lines
- [ ] Each finding is assigned one of the six debt categories
- [ ] The number of files scanned is stated with the findings
- [ ] "May I write" names `docs/tech-debt-register.md` and comes after the findings are shown
- [ ] The two TODO findings update TD-002 instead of adding a duplicate row
- [ ] TD-001 is proposed as `Resolved [date]` inside the same approval, and is kept in the register rather than deleted
- [ ] New rows take the next IDs (TD-003, TD-004) and carry an `Added` date; the register is updated in place, never replaced
- [ ] Verdict is COMPLETE

---

### Case 2: No Subcommand — Usage and FAIL

**Fixture:**
- `docs/tech-debt-register.md` exists
- `src/` contains source files with TODO comments

**Input:** `/tech-debt`

**Expected behavior:**
1. Phase 1 finds no subcommand
2. Skill outputs usage listing `scan`, `add`, `prioritize` and `report`
3. Skill stops — no scan runs and the register is not read or written
4. Verdict: **FAIL** — missing required subcommand

**Assertions:**
- [ ] Usage lists the four subcommands
- [ ] No scan is performed and no file is written
- [ ] Verdict is FAIL, stating the subcommand is missing

---

### Case 3: Empty Code Root — NOT ASSESSED, not a clean scan

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `src/` exists but contains no source files
- `docs/tech-debt-register.md` exists with 3 entries

**Input:** `/tech-debt scan`

**Expected behavior:**
1. Skill resolves the code root to `src/` and counts the files the scan covered: zero
2. Skill reports **NOT ASSESSED — no source files to scan**, explaining that "no debt indicators found" would describe an empty search, not the codebase
3. Skill stops: no "May I write" prompt, no register write, no COMPLETE verdict

**Assertions:**
- [ ] A zero-file scan is reported as NOT ASSESSED — no source files to scan
- [ ] Output does not claim "no debt found" or a clean codebase
- [ ] The register is not written and no write is offered
- [ ] No COMPLETE verdict is emitted

---

### Case 3b: Code Root Unresolved — NOT ASSESSED, nothing scanned on a guess

**Fixture:**
- `project.yaml` has no `engine.name`; `.claude/docs/technical-preferences.md` reads `[TO BE CONFIGURED]`
- Both `src/` and `Source/` exist and hold source files, so the tree does not decide the root
- `docs/tech-debt-register.md` exists with 3 entries

**Input:** `/tech-debt scan`

**Expected behavior:**
1. The code root cannot be resolved per `.claude/docs/code-root-resolution.md`
2. Skill reports `NOT ASSESSED — code root unresolved` and stops
3. Neither directory is scanned on a guess; no "May I write" prompt, no register write, no COMPLETE verdict

**Assertions:**
- [ ] Verdict is `NOT ASSESSED — code root unresolved`
- [ ] No debt findings are reported from a guessed root
- [ ] The register is not written and no write is offered

---

### Case 4: Add Mode — User declines the write

**Fixture:**
- `docs/tech-debt-register.md` exists with 4 entries
- `modes.automation` unset (collaborative)

**Input:** `/tech-debt add`

**Expected behavior:**
1. Skill asks in plain text for the description and affected files
2. Skill uses `AskUserQuestion` for the category — six options, Architecture through Performance
3. Skill uses `AskUserQuestion` for the fix effort — S, M, L, XL
4. Skill uses `AskUserQuestion` for the impact if left unfixed — Low, Med, High, Critical
5. Skill presents the complete new entry
6. Skill asks "May I append this entry to `docs/tech-debt-register.md`?"
7. User declines — nothing is written
8. Verdict: **BLOCKED** — user declined write

**Assertions:**
- [ ] Category is collected with `AskUserQuestion` offering the six debt categories
- [ ] Effort is collected with `AskUserQuestion` offering S / M / L / XL
- [ ] Impact is collected with `AskUserQuestion` offering Low / Med / High / Critical, so `prioritize` can score the row
- [ ] The full entry is shown before the append prompt
- [ ] On decline the register is unchanged and the verdict is BLOCKED

---

### Case 4a: Add Mode — Matches an Existing Open Entry

**Fixture:**
- `docs/tech-debt-register.md` exists with an `Open` entry for the same file
  and the same category as the one the user is about to add

**Input:** `/tech-debt add`

**Expected behavior:**
1. Steps 1–5 of Case 4 run as usual
2. **Match before appending:** before the append ask, the skill shows the
   existing `Open` entry (same file and category) and asks whether to update
   it instead of adding a duplicate
3. On "update", the matched entry is updated in place — no duplicate row is added
4. On "add anyway", a new entry is appended alongside the match

**Assertions:**
- [ ] A new entry with the same file and category as an existing `Open` entry is never appended without first showing the match and asking
- [ ] "Update" edits the matched row rather than adding a new one

---

### Case 4b: Report Mode Without a Register — NOT ASSESSED

**Fixture:**
- `docs/tech-debt-register.md` does not exist

**Input:** `/tech-debt report`

**Expected behavior:**
1. Skill looks for the register and does not find it
2. Verdict: **NOT ASSESSED** — no register to report on; run `/tech-debt scan` first
3. No trend or totals are printed and nothing is written

**Assertions:**
- [ ] Verdict is NOT ASSESSED, not a report of zero items or a "stable" trend
- [ ] The output names `/tech-debt scan` as the way to create the register
- [ ] No file is written

---

### Case 5: Prioritize in Full Review Mode — Scored, re-sorted, approved

**Fixture:**
- `project.yaml`: `modes.review_mode: full`
- `docs/tech-debt-register.md` has 4 entries: TD-001 High/S, TD-002 Low/L, TD-003
  Critical/M, TD-004 Med/— (Effort not yet estimated)

**Input:** `/tech-debt prioritize`

**Expected behavior:**
1. Skill reads `docs/tech-debt-register.md`
2. Each item is scored `impact ÷ effort` (Impact Low 1 … Critical 4; Effort S 1 … XL 4): TD-001 3.0, TD-003 2.0, TD-002 0.3; TD-004 is listed after them as "not scored — Effort not judged"
3. The register is re-sorted by score and the skill recommends which items belong in the next sprint
4. No director gate is invoked regardless of review mode
5. Skill presents the re-prioritized register, then asks "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"
6. On approval the file is written
7. Verdict: **COMPLETE** — register re-prioritized and saved

**Assertions:**
- [ ] Items are scored `impact ÷ effort` from their own columns and re-sorted: TD-001, TD-003, TD-002
- [ ] TD-004 gets no invented score; it is listed as not scored, naming the missing Effort
- [ ] A next-sprint recommendation is given
- [ ] No director gate is invoked in any review mode
- [ ] The write happens only after the "May I write" prompt is approved
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Requires a subcommand; without one prints usage and stops with FAIL
- [ ] `scan` resolves the code root per engine (`src/`, `Assets/`, `Source/`) and states the number of files covered
- [ ] A zero-file or unresolved-root scan is NOT ASSESSED and writes nothing
- [ ] Every register write is preceded by a "May I write" / "May I append" prompt naming `docs/tech-debt-register.md`, after the content is shown
- [ ] `scan` appends and never overwrites existing entries; a finding matching an `Open` row updates it, and an `Open` row whose pattern is gone is proposed `Resolved [date]`, never deleted
- [ ] New rows follow the Debt Register Format: the next `TD-NNN` ID, all ten columns, an `Added` date in `YYYY-MM-DD`
- [ ] A declined write ends with BLOCKED
- [ ] No director gates are invoked
- [ ] Ends with the Phase 3 next steps (`/sprint-plan`, `/tech-debt report`)

---

## Coverage Notes

- `report` mode with a register (read-only summary by category and effort,
  added and resolved counts from each row's `Added` and `Resolved` dates,
  flagging items older than 3 sprints, Verdict COMPLETE — debt report generated)
  is not tested here.
- Unity and Unreal scans differ only in the resolved root (`Assets/`,
  `Source/`) and are not tested separately.
