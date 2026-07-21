# Skill Test Spec: $qa-plan

## Skill Summary

`$qa-plan` generates a structured QA test plan for a feature or sprint milestone.
It reads story files for the specified sprint, extracts acceptance criteria from
each story, cross-references test standards from `coding-standards.md` to assign
the appropriate test type (unit, integration, visual, UI, or config/data), and
produces a prioritized QA plan document.

The skill asks "May I write to `production/qa/qa-plan-sprint-NNN.md`?" before
persisting the output. If an existing test plan for the same sprint is found, the
skill offers to update rather than replace. The verdict is COMPLETE when the plan
is written. No director gates are used — gate-level story readiness is handled by
`$story-readiness`.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the plan
- [ ] Has a next-step handoff (e.g., `$smoke-check` or `$story-readiness`)

---

## Director Gate Checks

None. `$qa-plan` is a planning utility. Story readiness gates are separate.

---

## Test Cases

### Case 1: Happy Path — Sprint with 4 stories generates full test plan

**Fixture:**
- `production/sprints/sprint-003.md` lists 4 stories with defined acceptance criteria
- Stories span types: 1 logic (formula), 1 integration, 1 visual, 1 UI
- `coding-standards.md` is present with test evidence table

**Input:** `$qa-plan sprint-003`

**Expected behavior:**
1. Skill reads sprint-003.md and identifies 4 stories
2. Skill reads each story's acceptance criteria
3. Skill assigns test types per coding-standards.md table:
   - Logic story → Unit test (BLOCKING)
   - Integration story → Integration test (BLOCKING)
   - Visual story → Screenshot + lead sign-off (ADVISORY)
   - UI story → Manual walkthrough doc (ADVISORY)
4. Skill drafts QA plan with story-by-story test type breakdown
5. Skill asks "May I write to `production/qa/qa-plan-sprint-003.md`?"
6. File is written on approval; verdict is COMPLETE

**Assertions:**
- [ ] All 4 stories are included in the plan
- [ ] Test type is assigned per coding-standards.md (not guessed)
- [ ] Gate level (BLOCKING vs ADVISORY) is noted for each story
- [ ] "May I write" is asked with the correct file path
- [ ] Verdict is COMPLETE

---

### Case 2: Story With No Acceptance Criteria — Flagged as UNTESTABLE

**Fixture:**
- `production/sprints/sprint-004.md` lists 3 stories; one story has empty
  acceptance criteria section

**Input:** `$qa-plan sprint-004`

**Expected behavior:**
1. Skill reads all 3 stories
2. Skill detects the story with no AC
3. Story is flagged as `UNTESTABLE — Acceptance Criteria required` in the plan
4. Other 2 stories receive normal test type assignments
5. Plan is written with the UNTESTABLE story flagged; verdict is COMPLETE

**Assertions:**
- [ ] UNTESTABLE label appears for the story with no AC
- [ ] Plan is not blocked — the other stories are still planned
- [ ] Output suggests adding AC to the flagged story (next step)
- [ ] Verdict is COMPLETE (the plan is still generated)

---

### Case 3: Existing Test Plan Found — Offers update rather than replace

**Fixture:**
- `production/qa/qa-plan-sprint-003.md` already exists from a previous run
- Sprint-003 has 2 new stories added since the last plan

**Input:** `$qa-plan sprint-003`

**Expected behavior:**
1. Skill reads sprint-003.md and detects 2 stories not in the existing plan
2. Skill reports: "Existing QA plan found for sprint-003 — offering to update"
3. Skill presents the 2 new stories and their proposed test assignments
4. Skill asks "May I update `production/qa/qa-plan-sprint-003.md`?" (not overwrite)
5. Updated plan is written on approval

**Assertions:**
- [ ] Skill detects the existing plan file
- [ ] "update" language is used (not "overwrite")
- [ ] Only new stories are proposed for addition — existing entries preserved
- [ ] Verdict is COMPLETE

---

### Case 4: No Stories Found for Sprint — Error with guidance

**Fixture:**
- `production/sprints/sprint-007.md` does not exist
- No other sprint file matching sprint-007

**Input:** `$qa-plan sprint-007`

**Expected behavior:**
1. Skill attempts to read sprint-007.md — file not found
2. Skill outputs: "No sprint file found for sprint-007"
3. Skill suggests running `$sprint-plan` to create the sprint first
4. No plan is written; no "May I write" is asked

**Assertions:**
- [ ] Error message names the missing sprint file
- [ ] `$sprint-plan` is suggested as the remediation step
- [ ] No write tool is called
- [ ] Verdict is not COMPLETE (error state)

---

### Case 5: Director Gate Check — No gate; QA planning is a utility

**Fixture:**
- Sprint with valid stories and AC

**Input:** `$qa-plan sprint-003`

**Expected behavior:**
1. Skill generates and writes QA plan
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Skill reaches COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Reads coding-standards.md test evidence table before assigning test types
- [ ] Assigns BLOCKING or ADVISORY gate level per story type
- [ ] Flags stories with no AC as UNTESTABLE (does not silently skip them)
- [ ] Detects existing plan and offers update path
- [ ] Asks "May I write" before creating or updating the plan file
- [ ] Verdict is COMPLETE when plan is written

---

## Coverage Notes

- The case where `coding-standards.md` is missing (skill cannot assign test types)
  is not fixture-tested; behavior would follow the BLOCKED pattern with a note
  to restore the standards file.
- Multi-sprint planning (spanning 2 sprints) is not tested; the skill is designed
  for one sprint at a time.
- Config/data story type (balance tuning → smoke check) follows the same
  assignment pattern as other types in Case 1 and is not separately tested.
