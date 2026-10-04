# Skill Test Spec: /qa-plan

## Skill Summary

`/qa-plan [sprint | feature: system-name | story: path]` generates a QA plan
before implementation. `sprint` reads the most recent file in
`production/sprints/` (or `production/sprint-status.yaml` when present) for its
story list; `feature:` globs `production/epics/*/story-*.md` by system name;
`story:` loads one file; no argument asks for the scope with `AskUserQuestion`.
A referenced story file that does not exist is noted as MISSING and the plan
continues; a scope with zero stories stops with `NOT ASSESSED — no stories in
scope` and a route (e.g. "No sprint plan found. Run `/sprint-plan new`.").

Story fields are collected with targeted greps. A declared `Type:` is accepted
as-is; a missing one is inferred from the acceptance criteria and flagged as a
gap. A story with no `## Acceptance Criteria` is full-read and reported as a QA
finding, never skipped. After a classification summary table, the plan
(Test Summary, Automated Tests Required, Manual QA Checklist, Smoke Test Scope,
Playtest Requirements, Definition of Done) is shown, then one `AskUserQuestion`
(multiSelect) asks whether to write `production/qa/qa-plan-[sprint-slug]-[date].md`
and whether to back-fill `## QA Test Cases` in the story files. `qa.level`
changes the plan's depth, but no level drops the Visual/Feel and UI screenshot
rows. No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains the verdict keyword `NOT ASSESSED` for an empty scope
- [ ] Asks for approval before writing: an `AskUserQuestion` option naming `production/qa/qa-plan-[sprint-slug]-[date].md`, and the rule "Never write the plan without asking"
- [ ] Has a next-step handoff (`/smoke-check sprint` after implementation, `/story-done` checks for the test files)

---

## Director Gate Checks

None. `/qa-plan` is a planning utility. It spawns no agents (`Agent` is not in
its allowed tools) and no director gates apply.

---

## Test Cases

### Case 1: Happy Path — Sprint With Four Typed Stories

**Fixture:**
- `production/sprints/sprint-003.md` is the most recent sprint and references 4
  story files, each with acceptance criteria and a declared Type: Logic,
  Integration, Visual/Feel, UI
- The stories reference GDDs in `design/gdd/`; `engine.name: Godot`
- `qa.level: standard`; `modes.automation: collaborative`

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill reads the most recent sprint file and reports "Building QA plan for 4
   stories in [scope]."
2. Story fields are collected with section greps; each declared Type is accepted
   without re-classification
3. A classification summary table is shown before the plan is generated
4. The plan's Test Summary maps Logic → unit test under `tests/unit/[system]/`,
   Integration → integration test under `tests/integration/[system]/`,
   Visual/Feel → screenshot + lead sign-off, UI → retained screenshot of each
   screen touched
5. The plan is shown, then one multiSelect `AskUserQuestion` offers "Write QA
   plan to production/qa/qa-plan-[sprint-slug]-[date].md" and the story
   back-fill option
6. After writing, next steps name `/smoke-check sprint` (after implementation)
   and `/story-done`

**Assertions:**
- [ ] All 4 stories appear in the plan, each with its declared Type unchanged
- [ ] The classification summary table appears before the plan
- [ ] Logic and Integration rows name test paths under `tests/unit/` and `tests/integration/`
- [ ] The UI row's manual verification is the retained screenshot of each screen touched, not a step-through
- [ ] Nothing is written before the multiSelect approval, and the written path is `production/qa/qa-plan-[sprint-slug]-[date].md`
- [ ] Next steps name `/smoke-check sprint` and `/story-done`

---

### Case 2: Story Without Acceptance Criteria and a Missing Story File

**Fixture:**
- The most recent sprint file references 4 story paths
- One story has no `## Acceptance Criteria` section
- One referenced story path does not exist on disk
- The other 2 stories are complete

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. The missing path is noted as MISSING and the plan continues
2. The story whose AC grep matched nothing is full-read, and the plan says it
   has no testable criteria — a QA finding, not a skipped story
3. The 2 complete stories are classified and planned normally
4. Approval is asked before writing

**Assertions:**
- [ ] The missing file is reported as MISSING without failing the whole plan
- [ ] The story with no acceptance criteria is full-read and reported as a QA finding
- [ ] That story is not silently dropped from the plan
- [ ] The two complete stories receive normal test assignments

---

### Case 3: Mode Variant — qa.level minimal

**Fixture:**
- Same 4-story sprint as Case 1
- `qa.level: minimal`

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill produces only a minimal smoke plan
2. The "Automated Tests Required" section is omitted and the Test Summary's
   "Automated Test Required" column is blanked
3. The Definition of Done drops the test-file and smoke rows only; it still
   requires a retained screenshot of each screen touched for the Visual/Feel
   and UI stories, and a signed-off evidence doc for the Visual/Feel story —
   `qa.level` waives tests, never the screenshot
4. Approval is asked before writing

**Assertions:**
- [ ] No "Automated Tests Required" section appears
- [ ] The Test Summary's automated-test column is blank
- [ ] The Definition of Done has no test-file or smoke-check rows
- [ ] The Definition of Done still requires the retained screenshot for the Visual/Feel and UI stories, and the signed-off evidence doc for the Visual/Feel story
- [ ] Approval is still asked before the plan is written

---

### Case 4: No Sprint Plan — NOT ASSESSED

**Fixture:**
- `production/sprints/` contains no files
- No `production/sprint-status.yaml`
- `modes.rigor: standard` (so sprints are expected)

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. The resolved scope contains zero stories
2. Skill stops before Phase 2 and reports `NOT ASSESSED — no stories in scope`,
   naming the scope searched and the empty path
3. Skill routes: "No sprint plan found. Run `/sprint-plan new`."
4. No plan is generated and no write approval is asked

**Assertions:**
- [ ] Verdict is `NOT ASSESSED — no stories in scope`
- [ ] The empty path `production/sprints/` is named
- [ ] `/sprint-plan new` is suggested
- [ ] No plan document with empty tables is produced, and nothing is written

---

### Case 5: Director Gate Check — None

**Fixture:**
- A sprint with typed stories and acceptance criteria
- Any review mode

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill classifies stories and generates the plan
2. No director or other agent is spawned; no gate IDs appear
3. The only interactive step after scope resolution is the single write approval

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears
- [ ] No subagent is spawned
- [ ] Phases 2–4 run without asking the user anything
- [ ] Exactly one approval prompt precedes the write

---

## Protocol Compliance

- [ ] Stops with `NOT ASSESSED — no stories in scope` when the scope is empty, and routes to the producing skill
- [ ] Notes missing story files as MISSING and continues
- [ ] Accepts declared `Type:` values; infers and flags a missing Type
- [ ] Never skips a story because its acceptance-criteria section is absent
- [ ] Shows the classification table and the plan before asking to write
- [ ] Writes only after the `AskUserQuestion` approval; back-fills story files only when that option is selected

---

## Coverage Notes

- `feature: [system-name]` and `story: [path]` scopes, and the no-argument
  scope question, are not separately tested.
- A story with no `Type:` field (inferred from acceptance criteria and flagged
  as a gap) is covered only by protocol compliance.
- The back-fill option (editing `## QA Test Cases` in each story file) is not
  tested in detail.
- At `rigor: minimal`, the empty-sprint route points to `/qa-plan feature:` or
  `/qa-plan story:` instead of `/sprint-plan new`; not separately tested.
