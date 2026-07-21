# Skill Test Spec: $help

## Skill Summary

`$help` analyzes what has been done and what comes next in the project workflow.
It is read-only (, formatting task) and reads `production/stage.txt`,
the active sprint file, and recent session state to produce a concise situational
guidance summary. The skill optionally accepts a context query (e.g., `$help testing`)
to surface relevant skills for a specific topic.

The output is always informational — no files are written and no director gates
are invoked. The verdict is always HELP COMPLETE. The skill serves as a workflow
navigator, suggesting 2-3 next skills based on the current project state.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: HELP COMPLETE
- [ ] Does NOT contain "May I write" language (skill is read-only)
- [ ] Has a next-step handoff (suggests 2-3 relevant skills based on state)

---

## Director Gate Checks

None. `$help` is a read-only navigation skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Production stage with active sprint

**Fixture:**
- `production/stage.txt` contains `Production`
- `production/sprints/sprint-004.md` exists with in-progress stories
- `production/session-state/active.md` has a recent checkpoint

**Input:** `$help`

**Expected behavior:**
1. Skill reads stage.txt and active sprint
2. Skill identifies current sprint number and in-progress story count
3. Skill outputs: current stage, sprint summary, and 3 suggested next skills
   (e.g., `$sprint-status`, `$dev-story`, `$story-done`)
4. Suggestions are ranked by relevance to current sprint state
5. Verdict is HELP COMPLETE

**Assertions:**
- [ ] Current stage is shown (Production)
- [ ] Active sprint number and story count are mentioned
- [ ] Exactly 2-3 next-skill suggestions are given (not a list of all skills)
- [ ] Suggestions are appropriate for Production stage
- [ ] Verdict is HELP COMPLETE
- [ ] No files are written

---

### Case 2: Concept Stage — Shows concept-to-systems-design workflow path

**Fixture:**
- `production/stage.txt` contains `Concept`
- No sprint files, no GDD files
- `technical-preferences.md` is configured (engine selected)

**Input:** `$help`

**Expected behavior:**
1. Skill reads stage.txt — detects Concept stage
2. Skill outputs the Concept-stage workflow: brainstorm → map-systems → design-system
3. Suggested skills are: `$brainstorm`, `$map-systems` (if concept exists)
4. Current progress is noted: "Engine configured, concept not yet created"

**Assertions:**
- [ ] Stage is identified as Concept
- [ ] Workflow path shows the expected sequence for this stage
- [ ] Suggestions do not include Production-stage skills (e.g., `$dev-story`)
- [ ] Verdict is HELP COMPLETE

---

### Case 3: No stage.txt — Shows full workflow overview

**Fixture:**
- No `production/stage.txt`
- No sprint files
- `technical-preferences.md` has placeholders

**Input:** `$help`

**Expected behavior:**
1. Skill cannot determine stage from stage.txt
2. Skill runs project-stage-detect logic to infer stage from artifacts
3. If stage cannot be inferred: outputs the full workflow overview from
   Concept through Release as a reference map
4. Primary suggestion is `$start` to begin configuration

**Assertions:**
- [ ] Skill does not crash when stage.txt is absent
- [ ] Full workflow overview is shown when stage cannot be determined
- [ ] `$start` or `$project-stage-detect` is a top suggestion
- [ ] Verdict is HELP COMPLETE

---

### Case 4: Context Query — User asks for help with testing

**Fixture:**
- `production/stage.txt` contains `Production`
- Active sprint has a story with `Status: In Review`

**Input:** `$help testing`

**Expected behavior:**
1. Skill reads context query: "testing"
2. Skill surfaces skills relevant to testing: `$qa-plan`, `$smoke-check`,
   `$regression-suite`, `$test-setup`, `$test-evidence-review`
3. Output is focused on testing workflow, not general sprint navigation
4. Currently in-review story is highlighted as a testing candidate

**Assertions:**
- [ ] Context query is acknowledged in output ("Help topic: testing")
- [ ] At least 3 testing-relevant skills are listed
- [ ] General sprint skills (e.g., `$sprint-plan`) are not the primary suggestions
- [ ] Verdict is HELP COMPLETE

---

### Case 5: Director Gate Check — No gate; help is read-only navigation

**Fixture:**
- Any project state

**Input:** `$help`

**Expected behavior:**
1. Skill produces workflow guidance summary
2. No director agents are spawned
3. No gate IDs appear in output
4. No write tool is called

**Assertions:**
- [ ] No director gate is invoked
- [ ] No write tool is called
- [ ] No gate skip messages appear
- [ ] Verdict is HELP COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Reads stage, sprint, and session state before generating suggestions
- [ ] Suggestions are specific to the current project state (not generic)
- [ ] Context query (if provided) narrows the suggestion set
- [ ] Does not write any files
- [ ] Verdict is HELP COMPLETE in all cases

---

## Coverage Notes

- The case where the active sprint is complete (all stories Done) is not
  separately tested; the skill would suggest `$sprint-plan` for the next sprint.
- The `$help` skill does not validate whether suggested skills are available —
  it assumes standard skill catalog availability.
- Stage detection fallback (when stage.txt is absent) delegates to the same
  logic as `$project-stage-detect` and is not re-tested here in detail.
