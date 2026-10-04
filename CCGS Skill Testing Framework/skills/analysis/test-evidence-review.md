# Skill Test Spec: /test-evidence-review

## Skill Summary

`/test-evidence-review` reviews the **quality** of the test files and evidence
documents behind stories — `/smoke-check` covers existence and passing. It
takes a scope: a single story path, `sprint` (the most recent plan in
`production/sprints/`), or a system name (`production/epics/[system]/story-*.md`);
with no argument it asks which. If the resolved scope holds zero stories it stops
with `NOT ASSESSED — no stories in scope` and routes to the skill that creates
them. For each story it collects Story Type, evidence path and acceptance
criteria with targeted greps, locates the evidence (`tests/unit/[system]/`,
`tests/integration/[system]/`, `production/qa/evidence/`,
`production/qa/smoke-*.md`), and reviews automated tests for assertion count,
edge cases, naming and formula traceability, and manual evidence for criterion
linkage, sign-offs, retained screenshots and freshness. It resolves `qa.level`
and `testing.strict` the way `/story-done` does: at `qa.level: minimal` a Logic,
Integration or Config/Data story with no test evidence is
`WAIVED (qa.level: minimal)`, not MISSING, and a gap in a test that does exist is
ADVISORY; Visual/Feel and UI evidence is never waived; otherwise each gap takes
its story type's gate level from `testing.strict.<type>` (unset → a
plain-boolean `testing.strict` legacy value applies to every type; else the
`coding-standards.md` default). Each story gets ADEQUATE, INCOMPLETE, MISSING,
NOT ASSESSED or WAIVED; the overall verdict is the worst present, with NOT
ASSESSED outranking ADEQUATE only, and WAIVED below ADEQUATE. The report is presented in
conversation, and the skill asks "May I write this test evidence review to
`production/qa/evidence-review-[date].md`?" as an optional step. It never
modifies test files or evidence docs and invokes no director gates. The run ends
COMPLETE, or CONCERNS when BLOCKING items were found.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: ADEQUATE, INCOMPLETE, MISSING, NOT ASSESSED, and the run-level COMPLETE / CONCERNS
- [ ] Contains "May I write" language for the optional `production/qa/evidence-review-[date].md`
- [ ] Has a next-step handoff (Section 7: BLOCKING items before `/story-done`, `/test-helpers`, sign-off routing)
- [ ] The `resolve_config` injection names `qa.level` and `testing.strict`, and the skill states the `WAIVED (qa.level: minimal)` result and the per-type `testing.strict.<type>` gate level

---

## Director Gate Checks

None. Test evidence review is an advisory quality skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Single Logic story with a strong test

**Fixture:**
- `project.yaml`: `engine.name: godot`, so the unit-test root is `tests/unit/`; `modes.automation` unset (collaborative)
- `production/epics/combat/story-001-damage-calc.md` (slug `damage-calc`): `## Test Evidence` gives Story Type Logic and the path `tests/unit/combat/damage-calc_test.gd`; `## Acceptance Criteria` includes "damage is never below 1" and "critical hits multiply damage by 2.0"
- `tests/unit/combat/damage-calc_test.gd` opens with `# Story: production/epics/combat/story-001-damage-calc.md`, has 4 test functions with 3+ assertions each, named like `test_damage_calc_zero_armor_returns_base_damage` and `test_damage_calc_max_crit_doubles_damage`, and names the GDD's `damage_formula` in a comment

**Input:** `/test-evidence-review production/epics/combat/story-001-damage-calc.md`

**Expected behavior:**
1. Single-story mode: skill reads the story's Test Evidence and Acceptance Criteria
2. Section 3 finds the test file under `tests/unit/combat/`
3. Section 4: assertion coverage is normal (3+ per function); "zero" and "max" cases cover the numeric criteria; names follow `test_[scenario]_[expected]`; the formula is referenced
4. Story verdict: **ADEQUATE**; overall verdict ADEQUATE; 0 BLOCKING items
5. Report is presented in conversation, then the skill asks "May I write this test evidence review to `production/qa/evidence-review-[date].md`?" as optional
6. Verdict: **COMPLETE**

**Assertions:**
- [ ] The test file is located under `tests/unit/combat/` for the Logic story
- [ ] Assertion coverage, edge cases, naming and formula traceability are each reported
- [ ] Story verdict is ADEQUATE
- [ ] The report is shown before the optional "May I write" prompt
- [ ] Run ends with COMPLETE

---

### Case 2: Vacuous and Thin Tests — INCOMPLETE with a BLOCKING item

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.rigor: standard` (so `qa.level: standard` — tests are required); no `testing.strict` block
- `production/epics/combat/story-002-crit-roll.md` (slug `crit-roll`): Story Type Logic
- `tests/unit/combat/crit-roll_test.gd` has `func test_1()` with no assertions and `func test_crit_roll_applies_multiplier()` with one assertion

**Input:** `/test-evidence-review production/epics/combat/story-002-crit-roll.md`

**Expected behavior:**
1. Skill finds the test file and counts assertions per function
2. `test_1` has 0 assertions → flagged BLOCKING (passes vacuously, proves nothing); `test_1` is also flagged as a generic name
3. The one-assertion function is noted as potentially thin
4. Story verdict: **INCOMPLETE**
5. Follow-ups: "These must be resolved before `/story-done` can mark the story Complete…" and "Consider running `/test-helpers [system]`…"
6. Run ends with **CONCERNS** because BLOCKING items were found

**Assertions:**
- [ ] A test function with zero assertions is flagged BLOCKING
- [ ] `test_1` is flagged as a naming issue
- [ ] Story verdict is INCOMPLETE, not ADEQUATE
- [ ] Output states BLOCKING items must be resolved before `/story-done` and suggests `/test-helpers`
- [ ] Run ends with CONCERNS
- [ ] The test file is not modified
- [ ] Variant — with `testing.strict.logic: false` in `project.yaml`, the zero-assertion finding is ADVISORY, the story is still INCOMPLETE, and the run ends COMPLETE

---

### Case 3: Empty Sprint Scope at Minimal Workflow — NOT ASSESSED, not a clean report

**Fixture:**
- `project.yaml`: `modes.rigor: minimal` (the resolved block shows `workflow: minimal`)
- `production/sprints/` does not exist

**Input:** `/test-evidence-review sprint`

**Expected behavior:**
1. Sprint mode finds no sprint plan, so the scope holds zero stories
2. Skill stops and reports `NOT ASSESSED — no stories in scope`, naming the sprint scope and the empty `production/sprints/` path
3. Because the workflow is minimal (no sprints), it routes to `/test-evidence-review [epic-slug]` instead of `/sprint-plan new`
4. Skill does not continue to Section 3; no Summary table and no "BLOCKING items: 0" line are rendered

**Assertions:**
- [ ] Verdict is NOT ASSESSED — no stories in scope
- [ ] Output names which scope was searched and which path was empty
- [ ] At minimal workflow the route is `/test-evidence-review [epic-slug]`, not `/sprint-plan new`
- [ ] No empty report reading "BLOCKING items: 0 / ADVISORY items: 0" is produced

---

### Case 4: Story Type Unknown — Per-story NOT ASSESSED lifts the overall verdict

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `production/epics/combat/` contains `story-001-damage-calc.md` (Logic, test as in Case 1) and `story-003-hit-feedback.md`, whose `## Test Evidence` section states no Story Type and no evidence path
- Full-reading `story-003-hit-feedback.md` does not reveal a type either

**Input:** `/test-evidence-review combat`

**Expected behavior:**
1. System mode globs `production/epics/combat/story-*.md` and finds both stories
2. `story-001-damage-calc` is ADEQUATE
3. `story-003-hit-feedback` is **NOT ASSESSED**, with the reason stated: the story type cannot be determined, so the required evidence is unknown
4. It is not reported as MISSING
5. Overall verdict: **NOT ASSESSED** — it outranks ADEQUATE

**Assertions:**
- [ ] The untyped story is NOT ASSESSED, not MISSING
- [ ] The NOT ASSESSED reason (type cannot be determined) is stated for that story
- [ ] Overall verdict is NOT ASSESSED, not ADEQUATE
- [ ] The typed story is still reviewed and reported ADEQUATE

---

### Case 5: Visual/Feel Evidence Without a Retained Screenshot, Full Review Mode — No gates

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.review_mode: full`
- `production/epics/combat/story-004-hit-flash.md` (slug `hit-flash`): Story Type Visual/Feel
- `production/qa/evidence/hit-flash-evidence.md` references every acceptance criterion, has every sign-off filled, and is dated after the sprint start
- No `*.png`, `*.jpg` or `*.gif` for this story exists in `production/qa/evidence/`

**Input:** `/test-evidence-review production/epics/combat/story-004-hit-flash.md`

**Expected behavior:**
1. Section 3 finds `production/qa/evidence/hit-flash-evidence.md`
2. Section 5: criterion linkage and sign-offs are complete, but no retained image exists for the story
3. The doc describes a visual check without evidence → story verdict **INCOMPLETE**, flagged BLOCKING
4. No director gate is invoked regardless of review mode
5. The evidence document is not edited
6. Run ends with **CONCERNS**

**Assertions:**
- [ ] A Visual/Feel evidence doc with no retained image is INCOMPLETE, even with complete sign-offs
- [ ] The missing screenshot is listed as a BLOCKING issue
- [ ] No director gate is invoked in any review mode
- [ ] The evidence document is not modified

---

### Case 6: UI Story Closed by Its Screenshots — No Sign-Off Required

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `production/epics/ui/story-007-inventory-screen.md` (slug `inventory-screen`): Story Type UI; its
  `## Test Evidence` names `production/qa/evidence/inventory-screen-populated.png` and
  `production/qa/evidence/inventory-screen-empty.png` — one per screen state it touches
- Both images exist and are dated after the sprint start
- No `inventory-screen-evidence.md`, no sign-off record and no walkthrough log exist

**Input:** `/test-evidence-review production/epics/ui/story-007-inventory-screen.md`

**Expected behavior:**
1. Section 3 uses the two paths the story states before searching
2. Section 5: a UI story is closed by the retained screenshot of each screen it touched
3. Story verdict **ADEQUATE**; run ends with **COMPLETE**

**Assertions:**
- [ ] The story's stated evidence paths are checked first, and both images are found
- [ ] The missing sign-off does not make the story INCOMPLETE — a UI story needs none
- [ ] No walkthrough log is demanded
- [ ] Story verdict is ADEQUATE

---

### Case 7: Unity Logic Story — Evidence at the Stated Engine Path

**Fixture:**
- `project.yaml`: `engine.name: unity`
- `production/epics/inventory/story-003-stack-merge.md`: Story Type Logic; its
  `## Test Evidence` names `Assets/Tests/EditMode/InventoryTests.cs`
- That file exists and holds one `[Test]` per acceptance criterion (4 in all), each with 3 or more `Assert.That` calls, named in the `[Scenario]_[Expected]` form (`MergeStacks_FullStack_SpillsToNewSlot`), with the empty-stack and max-stack cases covered
- The inventory GDD has no Formulas section, so formula traceability does not apply
- Nothing named `stack-merge_test.*` exists anywhere, and `tests/unit/` does not exist

**Input:** `/test-evidence-review production/epics/inventory/story-003-stack-merge.md`

**Expected behavior:**
1. Section 3 finds the test at the stated path under `Assets/Tests/EditMode/`
2. Section 4 reviews its assertions; story verdict **ADEQUATE**

**Assertions:**
- [ ] The test is found at the stated Unity path — the story is not reported MISSING
- [ ] The review does not require a `[story-slug]_test.*` name or a `tests/unit/` location

---

### Case 8: No Test for a Logic Story — MISSING, and it outranks NOT ASSESSED

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.rigor: standard` (so `qa.level: standard` — a Logic story's test is required)
- `production/epics/combat/` contains `story-003-hit-feedback.md` (no Story Type, as in Case 4) and `story-005-knockback.md`: Story Type Logic, no evidence path stated
- No test exists for it: `tests/unit/combat/` does not exist, and no other test file names the slug `knockback` or references the story

**Input:** `/test-evidence-review combat`

**Expected behavior:**
1. `story-005-knockback` is a Logic story, so a unit test is required; the search of the unit-test root finds none
2. `story-005-knockback` is **MISSING** — the review ran and found nothing — and the gap is a BLOCKING item
3. `story-003-hit-feedback` is **NOT ASSESSED** (its type cannot be determined), not MISSING
4. Overall verdict: **MISSING** — a known failure outranks the story that could not be assessed
5. Run ends with **CONCERNS** because a BLOCKING item was found

**Assertions:**
- [ ] The Logic story with no test file is MISSING, not NOT ASSESSED
- [ ] The untyped story is NOT ASSESSED, not MISSING — the two are kept apart
- [ ] Overall verdict is MISSING, not NOT ASSESSED
- [ ] The missing test is listed as BLOCKING and the run ends with CONCERNS

---

### Case 9: `qa.level: minimal` — a Logic Story With No Test Is WAIVED; a UI Screenshot Is Not

**Fixture:**
- `project.yaml`: `engine.name: godot`, no `modes` block (so `qa.level: minimal` — tests are waived)
- `production/epics/combat/` contains `story-005-knockback.md` (Logic, no test anywhere, as in Case 8) and `story-008-pause-menu.md` (UI, no retained image for it in `production/qa/evidence/`)

**Input:** `/test-evidence-review combat`

**Expected behavior:**
1. `story-005-knockback` is **WAIVED (qa.level: minimal)** — not MISSING — and raises no BLOCKING item
2. `story-008-pause-menu` is **MISSING** and BLOCKING — the retained screenshot a UI story needs is never waived
3. Overall verdict: **MISSING**; the report's header shows `qa.level: minimal`
4. Run ends with **CONCERNS** because of the UI story alone
5. Variant — without the UI story, the overall verdict is **WAIVED**, there are 0 BLOCKING items, and the run ends **COMPLETE**

**Assertions:**
- [ ] The Logic story with no test is WAIVED (qa.level: minimal), not MISSING, and is not listed as BLOCKING
- [ ] The UI story with no screenshot is still MISSING and BLOCKING at `qa.level: minimal`
- [ ] The waived story is named as waived in the report, not dropped from it
- [ ] Variant: an all-waived scope reads WAIVED, with no "must be resolved before `/story-done`" prompt

---

## Protocol Compliance

- [ ] Collects Story Type, evidence path and acceptance criteria with targeted `## Test Evidence` / `## Acceptance Criteria` greps, full-reading a story only when its Test Evidence section is missing or ambiguous
- [ ] An empty scope stops with `NOT ASSESSED — no stories in scope`, naming the scope and routing onward
- [ ] Each story gets ADEQUATE, INCOMPLETE, MISSING or NOT ASSESSED, and a NOT ASSESSED story states its reason
- [ ] Overall verdict is the worst story verdict; NOT ASSESSED outranks ADEQUATE but not INCOMPLETE or MISSING; WAIVED ranks below ADEQUATE
- [ ] At `qa.level: minimal` a Logic, Integration or Config/Data story with no test evidence is WAIVED, never MISSING or BLOCKING; Visual/Feel and UI evidence is never waived
- [ ] BLOCKING vs ADVISORY per story type comes from `testing.strict.<type>` in the resolved block, falling back to a legacy plain-boolean `testing.strict` value applied to every type, then to the `coding-standards.md` default
- [ ] The report is presented before the optional "May I write" for `production/qa/evidence-review-[date].md`
- [ ] Does not modify test files or evidence documents
- [ ] No director gates are invoked
- [ ] Ends with COMPLETE, or CONCERNS when BLOCKING items were found — except an empty scope, which stops at `NOT ASSESSED — no stories in scope` before any report (Case 3)

---

## Coverage Notes

- Integration stories (playtest records in `production/session-logs/`) and
  Config/Data stories (`production/qa/smoke-*.md`) are not tested here.
- The no-argument path (the skill asks which scope to review) is not tested.
- The POTENTIALLY STALE freshness flag is not tested separately.
