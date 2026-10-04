# Skill Test Spec: /content-audit

## Skill Summary

`/content-audit [system-name | --summary]` compares the content counts the design
specifies against what has been built. It reads `design/gdd/systems-index.md`
for systems and their MVP/priority tier, takes the planned named content from the
`entities:` and `items:` sections of `design/registry/entities.yaml` when the
registry has entries, and pre-scans GDDs with two greps (Summary presence and
digit-plus-content-noun counts) before full-reading only the GDDs it needs
(Phase 1). It then globs the implementation directories for each content type —
`assets/data/**/enemies/**`, `assets/data/**/items/**`, scene files under the
resolved code root, and so on (Phase 2) — and produces a gap table
`System | Content Type | Specified | Found | Gap | Status` with per-row Status
COMPLETE / IN PROGRESS / EARLY / NOT STARTED, HIGH PRIORITY flags, and a summary
line (Phase 3). The full report is written to `docs/content-audit-[YYYY-MM-DD].md`
only after "May I write"; `--summary` writes nothing. `modes.workflow` sets the
scope: `full` audits every GDD count, `standard` only counts in the required GDD
sections (naming any left out), and `minimal` has no systems index to audit
against. The run closes COMPLETE, or `NOT ASSESSED — NO DATA` when a required
input is absent, nothing in scope gives a count, or a Found count could not be
taken (code root unresolved) — never COMPLETE for a run that could not compute a
gap. No director gates are invoked.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains status and verdict keywords: COMPLETE, IN PROGRESS, EARLY, NOT STARTED, NOT ASSESSED
- [ ] Contains "May I write" before the optional report write to `docs/content-audit-[YYYY-MM-DD].md`
- [ ] Has a next-step handoff (what to do after gap table is reviewed)

---

## Director Gate Checks

None. Content audit is an analysis skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — All specified content present

**Fixture:**
- `modes.workflow` resolves to `full`
- `design/gdd/systems-index.md` lists Enemies (MVP) and Items (MVP)
- `design/registry/entities.yaml` has no entries
- `design/gdd/enemies.md` specifies "4 enemy types: Grunt, Sniper, Tank, Boss"
- `design/gdd/items.md` specifies "3 items"
- `assets/data/enemies/` contains `grunt.json`, `sniper.json`, `tank.json`, `boss.json`
- `assets/data/items/` contains 3 item `.json` files

**Input:** `/content-audit`

**Expected behavior:**
1. Skill reads the systems index; the empty registry is skipped and the GDD scan is used
2. The pre-scan greps find both GDDs declare content counts; both are full-read
3. Skill globs `assets/data/**/enemies/**` and `assets/data/**/items/**`
4. Gap table: Enemies — Specified 4, Found 4, Gap 0, COMPLETE; Items — Specified 3, Found 3, Gap 0, COMPLETE
5. Summary line: 7 specified, 7 found, overall gap 0%
6. Skill presents the table and asks "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"
7. Output ends with `Verdict: COMPLETE — content audit finished.`

**Assertions:**
- [ ] Gap table uses the columns System, Content Type, Specified, Found, Gap, Status
- [ ] Both rows show Specified = Found, Gap 0 and Status COMPLETE
- [ ] Summary line reports 7 specified, 7 found and 0% gap
- [ ] No HIGH PRIORITY flag is raised
- [ ] No file is written before the "May I write" ask is answered yes

---

### Case 2: Gaps Found — MVP enemy content barely started

**Fixture:**
- `modes.workflow` resolves to `full`
- `design/gdd/systems-index.md` tags Enemies as MVP
- `design/gdd/enemies.md` specifies "3 enemy types: Grunt, Sniper, Boss"
- `assets/data/enemies/` contains only `grunt.json`

**Input:** `/content-audit enemies`

**Expected behavior:**
1. Single-system audit: skill skips the pre-scan and full-reads `design/gdd/enemies.md`
2. Skill finds 1 enemy definition file
3. Gap table row: Enemies — Specified 3, Found 1, Gap 2, Status EARLY (33%)
4. Enemies is flagged HIGH PRIORITY: status EARLY and MVP-tagged
5. Skill asks "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"; on yes, the report's HIGH PRIORITY Gaps section lists Enemies with its rationale
6. Next steps include "Run `/create-stories [epic-slug]` for each HIGH PRIORITY gap."

**Assertions:**
- [ ] Specified (3), Found (1) and Gap (2) are all shown
- [ ] Status is EARLY for 1 of 3 (33%), not IN PROGRESS or NOT STARTED
- [ ] Enemies is flagged HIGH PRIORITY because it is EARLY and MVP-tagged
- [ ] Skill flags the gap now; it does not assume the content will be added later
- [ ] Next steps point to `/create-stories` for the HIGH PRIORITY gap

---

### Case 3: No Design Inputs — Nothing to audit against

**Fixture:**
- `modes.workflow` resolves to `full`
- `design/gdd/systems-index.md` does not exist
- `design/gdd/` contains no GDDs
- `design/registry/entities.yaml` has no entries

**Input:** `/content-audit`

**Expected behavior:**
1. Skill records its inputs as FOUND / ABSENT; the systems index, GDDs and registry entries are all ABSENT
2. Every required input is ABSENT, so the skill stops
3. Output reports `NOT ASSESSED — NO DATA`, naming the missing systems index and GDDs and the skills that produce them (`/map-systems`, `/design-system`)
4. No gap table and no gap percentage are produced (no division by zero)
5. No report write is offered and no file is written

**Assertions:**
- [ ] Verdict is `NOT ASSESSED — NO DATA`, not COMPLETE
- [ ] No gap table or overall gap percentage is produced
- [ ] Output names the missing inputs and the skills that produce them
- [ ] No "May I write" prompt appears and no file is written

---

### Case 3b: No Counts Anywhere — GDDs exist but none gives a count

**Fixture:**
- `modes.workflow` resolves to `full`
- `design/gdd/systems-index.md` lists Core Loop
- `design/gdd/core-loop.md` has a `## Summary` and describes mechanics only — no content count, no named list
- `design/registry/entities.yaml` has no entries

**Input:** `/content-audit`

**Expected behavior:**
1. The systems index and the GDD are FOUND, so the skill does not stop at the insufficient-input check
2. Scan (b) matches nothing; `core-loop.md` has a Summary, so it is noted "No auditable content counts" without a full read
3. No row carries a Specified count, so no Gap, Status or overall gap percentage is computed (Specified is 0)
4. The run closes `Verdict: NOT ASSESSED — NO DATA`, saying no GDD gives a count and naming `/design-system` to add counts

**Assertions:**
- [ ] No overall gap percentage is computed and no row is marked COMPLETE
- [ ] Verdict is `NOT ASSESSED — NO DATA`, never COMPLETE over an empty gap table
- [ ] Output says no GDD gives a count and names `/design-system`

---

### Case 4: Edge Case — A pre-Summary GDD describes content without a count

**Fixture:**
- `modes.workflow` resolves to `full`
- `design/gdd/systems-index.md` lists Enemies and Quests
- `design/gdd/enemies.md` has a `## Summary` and specifies "3 enemy types: Grunt, Sniper, Boss"; `assets/data/enemies/` has all 3
- `design/gdd/quests.md` has no `## Summary` section and says the game has "a handful of side quests" with no number or named list
- User answers yes to the report write

**Input:** `/content-audit`

**Expected behavior:**
1. Skill globs `design/gdd/*.md` for the denominator: N = 3, since the glob also counts `systems-index.md` (read in step 1; it has no `## Summary`); the Summary grep matches only `enemies.md`; the content-count grep matches only `enemies.md`
2. Failing open on the missing Summary, the skill full-reads `quests.md` rather than treating it as out of scope — the fail-open rule wins over the content-count narrowing
3. Skill records the Quests content type as "Unspecified" and flags it as a design gap; it does not invent a count
4. Enemies row is COMPLETE (3 of 3)
5. The written report `docs/content-audit-[YYYY-MM-DD].md` lists `quests.md` under "Unspecified Content Counts"
6. The report notes that counts are approximations based on file scanning

**Assertions:**
- [ ] `quests.md` is full-read because it lacks `## Summary`, even though the content-count grep did not match it
- [ ] The Quests content is recorded as "Unspecified", never given an estimated count
- [ ] The Unspecified Content Counts section of the report names `quests.md`
- [ ] The Enemies row is still audited normally (Specified 3, Found 3, COMPLETE)
- [ ] The report carries the approximation caveat

---

### Case 5: Gate Compliance — No gate; optional report requires approval

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: full`
- GDDs specify 10 content items; 9 are found in the implementation directories

**Input:** `/content-audit`

**Expected behavior:**
1. Skill reads the design inputs and scans the implementation; produces the gap table
2. No director gate is invoked regardless of review mode
3. Skill presents the gap table and summary before any write
4. Skill asks "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"
5. If the user says no, nothing is written; no asset file is ever modified

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Gap table is presented without auto-writing any file
- [ ] The report write is offered for `docs/content-audit-[YYYY-MM-DD].md` but not forced
- [ ] Skill does not modify any asset files

---

### Case 6: Standard Workflow — Only counts in the required sections are audited

**Fixture:**
- `modes.workflow` resolves to `standard`
- `design/gdd/systems-index.md` lists Enemies (MVP)
- `design/gdd/enemies.md` `## Detailed Design` specifies "3 enemy types: Grunt, Sniper, Boss"; its `## Tuning Knobs` section mentions "2 elite variants"
- `assets/data/enemies/` contains `grunt.json`, `sniper.json`, `boss.json`

**Input:** `/content-audit`

**Expected behavior:**
1. The count in `## Detailed Design`, a required section at `standard`, is audited: Enemies — Specified 3, Found 3, Gap 0, COMPLETE
2. The "2 elite variants" count sits in `## Tuning Knobs`, which `standard` does not require; it gets no gap row and is listed as not audited at this tier
3. Output ends with `Verdict: COMPLETE — content audit finished.`

**Assertions:**
- [ ] The Detailed Design count is audited and the Enemies row is COMPLETE
- [ ] The Tuning Knobs count is not in the gap table or the totals
- [ ] The output names the Tuning Knobs count as not audited at `standard` rather than dropping it silently

---

### Case 7: Minimal Workflow — No systems index to audit against

**Fixture:**
- `project.yaml`: `modes.rigor: minimal` (`workflow` resolves to `minimal`)
- `design/game-brief.md` exists; `design/gdd/systems-index.md` does not

**Input:** `/content-audit`

**Expected behavior:**
1. The systems index is ABSENT, as it normally is at `minimal`
2. Output reports `NOT ASSESSED — NO DATA`, naming the missing systems index and `/map-systems`, which creates it
3. No gap table, no gap percentage and no report write

**Assertions:**
- [ ] Verdict is `NOT ASSESSED — NO DATA`, not COMPLETE
- [ ] Output names `design/gdd/systems-index.md` as missing and `/map-systems` as the skill that produces it
- [ ] No gap percentage is computed and no file is written

---

### Case 8: Code Root Unresolved — The level count is not taken

**Fixture:**
- `modes.workflow` resolves to `full`
- `project.yaml` has no `engine.name`; `.claude/docs/technical-preferences.md` reads `[TO BE CONFIGURED]`; both `src/` and `Source/` exist, so the tree does not decide the root
- `design/gdd/systems-index.md` lists Levels (MVP) and Enemies (MVP)
- `design/gdd/levels.md` specifies "6 levels"; `design/gdd/enemies.md` specifies "3 enemy types: Grunt, Sniper, Boss"
- `assets/data/enemies/` contains 3 enemy files; no scene files exist under `assets/`

**Input:** `/content-audit`

**Expected behavior:**
1. Enemies is audited from `assets/data/`: Specified 3, Found 3, COMPLETE
2. The level scan needs the code root, which is unresolved: the Levels row's Found is `NOT ASSESSED — code root unresolved` — not 0, and its Status is not NOT STARTED
3. Levels gets no HIGH PRIORITY flag and stays out of both summary totals; the summary names it
4. The run closes `Verdict: NOT ASSESSED — NO DATA`, naming the unresolved code root

**Assertions:**
- [ ] The Levels row reads `NOT ASSESSED — code root unresolved`, never Found 0 or NOT STARTED
- [ ] The summary totals leave Levels out and say so
- [ ] Verdict is NOT ASSESSED, not COMPLETE

---

## Protocol Compliance

- [ ] Reads the systems index, the registry (when it has entries) and the in-scope GDDs before scanning the implementation
- [ ] A GDD with no `## Summary` is full-read even when the content-count grep did not match it
- [ ] Applies the resolved `modes.workflow`: `standard` audits only counts in the required GDD sections and names any it left out
- [ ] Gap table shows System, Content Type, Specified, Found, Gap, Status
- [ ] Row Status is one of: COMPLETE, IN PROGRESS, EARLY, NOT STARTED; a row whose Found could not be taken is `NOT ASSESSED` and stays out of the totals
- [ ] Writes only after "May I write" and only to `docs/content-audit-[YYYY-MM-DD].md`; `--summary` writes nothing
- [ ] A missing required input, a scope with no counts, or an untaken Found count yields `NOT ASSESSED — NO DATA`, never a computed gap percentage or COMPLETE
- [ ] No director gates are invoked
- [ ] On Unity, every content glob also runs under `Assets/` without a `data/` segment (e.g. `Assets/**/Items/**`, `*Item*.asset`) — a Unity project's items, abilities, quests and dialogue are never reported NOT STARTED from an `assets/data/`-only scan

---

## Coverage Notes

- `--summary` mode (prints the table, writes nothing, ends with "Run
  `/content-audit` without `--summary` to write the full report.") is not given
  its own case.
- Unity levels are found under the code root (`Assets/`, `*.unity`) and the
  other content types under `Assets/` (asserted in Protocol Compliance); Unreal
  levels under `Content/` (`*.umap`, with data assets as `*.uasset`); neither
  engine has its own case.
- Asset naming, size and format compliance is `/asset-audit`'s job, not this
  skill's.
