# Skill Test Spec: /estimate

## Skill Summary

`/estimate [task-description]` estimates the effort for one task. It reads the
task description from the argument (asking for clarification first if it is too
vague to estimate), the project context from `CLAUDE.md`, and any related GDD in
`design/gdd/` (Phase 1). It scans the affected code for complexity, integration
points and test coverage, and reads `production/sprints/` for similar completed
tasks and historical velocity (Phase 2). It analyzes code complexity, scope and
risk (Phase 3), then prints an estimate (Phase 4): a Complexity Assessment
table, an Effort Estimate in days for Optimistic / Expected / Pessimistic
scenarios, a recommended budget equal to the Expected figure, a Confidence of
High / Medium / Low with its drivers, Risk Factors, Dependencies, a Suggested
Breakdown with a total, and Notes and Assumptions — followed by a one-line
summary and `Verdict: COMPLETE — estimate generated.` Estimates are rounded to
half days. The skill is read-only and invokes no director gates.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains the Optimistic / Expected / Pessimistic scenarios, the High / Medium / Low confidence levels, and the `COMPLETE` verdict
- [ ] Does NOT require "May I write" language (read-only; states that no files are written)
- [ ] Has a next-step handoff (how to use the estimate in sprint planning)

---

## Director Gate Checks

None. Estimation is an advisory informational skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Clear task in a documented system with existing patterns

**Fixture:**
- `project.yaml`: `engine.name: godot`, so the code root is `src/`
- `design/gdd/combat.md` documents melee hit detection
- `src/combat/` holds the melee attack code; similar collision code already exists there
- `production/sprints/sprint-003.md` through `sprint-005.md` record completed combat tasks

**Input:** `/estimate Add hitbox detection to melee attacks`

**Expected behavior:**
1. Skill restates the task; the description is specific enough, so no clarification is asked
2. Skill reads `design/gdd/combat.md` because the task relates to a documented system
3. Skill scans `src/combat/` for affected files, integration points and existing tests
4. Skill reads `production/sprints/` for similar completed tasks and velocity
5. Output follows the Phase 4 template: Complexity Assessment, Effort Estimate (Optimistic / Expected / Pessimistic, in days), Recommended budget, Confidence, Risk Factors, Dependencies, Suggested Breakdown with a Total, Notes and Assumptions
6. Recommended budget equals the Expected figure; all figures are in half-day increments
7. A brief summary gives the recommended budget, the confidence level and the single biggest risk
8. Output ends with `Verdict: COMPLETE — estimate generated.`; no files are written

**Assertions:**
- [ ] The combat GDD and the sprint history are read before the estimate is produced
- [ ] Effort is given as three day figures (Optimistic, Expected, Pessimistic), not a single number
- [ ] Recommended budget equals the Expected figure, not the Optimistic one
- [ ] Figures are rounded to half days, not hours
- [ ] The closing summary names budget, confidence and the biggest risk
- [ ] No files are written

---

### Case 2: High Uncertainty — New subsystem, no architecture decided

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `src/` holds no source files for an online or matchmaking subsystem
- `design/gdd/online.md` describes the lobby with open "TBD" requirements, and says the networking approach (transport, host model) is not yet decided

**Input:** `/estimate Implement online lobby matchmaking`

**Expected behavior:**
1. Skill reads `design/gdd/online.md` and finds the unresolved requirements and the undecided networking approach
2. Code scan finds no existing subsystem; "Existing patterns available" is No
3. Risk Factors table lists the specific unknowns: the networking approach the GDD leaves undecided, new technology, unclear requirements
4. Confidence is Low, with the drivers explained
5. Phase 5 recommends a time-boxed spike via `/prototype` before committing
6. No files are written

**Assertions:**
- [ ] Confidence is Low when the task has an undecided approach, no existing code and TBD requirements
- [ ] The Risk Factors table names the specific unknowns driving the uncertainty
- [ ] Output recommends a time-boxed `/prototype` spike before committing
- [ ] No files are written

---

### Case 3: No Sprint Velocity Data — Estimate still produced, gap stated

**Fixture:**
- `project.yaml`: `engine.name: godot`; `src/core/` holds the inventory code the save touches
- `design/gdd/save-load.md` documents the save system clearly
- `production/sprints/` is empty — no historical sprints

**Input:** `/estimate Implement save and load of player inventory`

**Expected behavior:**
1. Skill reads the task, the GDD and the affected code
2. Skill looks for past sprint data and finds none
3. The estimate is still produced with all three scenarios and a recommended budget
4. Notes and Assumptions (or the Confidence explanation) states that no sprint history was available, so the figures are not calibrated to team velocity
5. No figure is padded silently to cover the missing data — any extra risk is called out explicitly
6. No files are written

**Assertions:**
- [ ] Skill does not error or stop when no sprint history exists
- [ ] Estimate is still produced with Optimistic, Expected and Pessimistic figures
- [ ] Output states that no sprint history was available for velocity calibration
- [ ] Any allowance for the missing data is stated as a risk, not hidden in the figures

---

### Case 4: Vague Task — Clarification before estimating

**Fixture:**
- `project.yaml`: `engine.name: godot`
- Project has GDDs and source code under `src/`; sprint history exists

**Input:** `/estimate make combat feel better`

**Expected behavior:**
1. Skill reads the task description and finds it too vague to estimate meaningfully (no scope, no named change)
2. Skill asks for clarification before proceeding
3. No Complexity Assessment, Effort Estimate or verdict is produced until the task is clarified
4. No files are written

**Assertions:**
- [ ] Skill asks for clarification for a task that names no concrete change
- [ ] No estimate figures are produced before the clarification is answered
- [ ] `Verdict: COMPLETE` is not printed for an unclarified task
- [ ] No files are written

---

### Case 5: Gate Compliance — No gate; estimates are informational

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.review_mode: full`
- Task relates to a documented system with medium complexity; its code is under `src/`

**Input:** `/estimate Add item pickup with inventory stacking`

**Expected behavior:**
1. Skill reads context, scans code and sprint history; produces the estimate
2. No director gate is invoked in any review mode
3. Estimate is presented as advisory output only
4. Next steps include "run `/sprint-plan update` to add it to the next sprint"

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output is purely informational — no approval or write prompt
- [ ] Next-step recommendation references `/sprint-plan`
- [ ] Estimate does not change based on review mode

---

## Protocol Compliance

- [ ] Reads the task argument, project context and any related GDD before estimating
- [ ] Reads `production/sprints/` for similar tasks and velocity when available
- [ ] Produces an effort range (Optimistic / Expected / Pessimistic days), not a single number
- [ ] Does not write any files
- [ ] No director gates are invoked
- [ ] Ends with Phase 5 next steps matched to the result (`/prototype` for Low confidence, `/create-stories` for tasks over 10 days, `/sprint-plan update` to schedule)

---

## Coverage Notes

- The skill estimates one task per run; a sprint file with several stories is
  not a supported input.
- The "task over 10 days → break it into smaller stories via `/create-stories`"
  branch is not given its own case.
- The accuracy of the day figures depends on the team and is not tested; the
  assertions check the range's structure, its sources and its stated drivers.
