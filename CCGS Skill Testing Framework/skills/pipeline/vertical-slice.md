# Skill Test Spec: $vertical-slice

## Skill Summary

`$vertical-slice` validates whether a production-quality, end-to-end game loop
is feasible before a project advances from Pre-Production to Production. It
defines a falsifiable validation question, confirms scope before implementation,
collects playtest evidence, and produces a PROCEED, PIVOT, or KILL result.

---

## Static Assertions

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has two or more phases
- [ ] Contains PROCEED, PIVOT, and KILL verdicts
- [ ] Requests approval before creating the slice directory or writing reports
- [ ] Ends with next steps for each verdict

---

## Test Cases

### Case 1: Valid Pre-Production Input

**Fixture:**
- Game concept, systems index, architecture, control manifest, and relevant GDDs exist.
- The user supplies a focused three-to-five minute game loop.

**Expected behavior:**
1. The skill defines a falsifiable player-experience and build-feasibility question.
2. It presents the systems, loop, quality target, success criteria, and time limit for approval.
3. It does not begin implementation before the user confirms scope.

**Assertions:**
- [ ] The validation question includes both player experience and build feasibility
- [ ] Scope covers the complete start-to-challenge-to-resolution loop
- [ ] No implementation files are created before approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Scope Is Too Large

**Fixture:**
- Proposed slice requires more than five minutes of gameplay or more than three weeks to build.

**Expected behavior:**
1. The skill flags the scope as unsuitable for a vertical slice.
2. It asks to cut content rather than lower the quality target.
3. It waits for a revised scope before implementation.

**Assertions:**
- [ ] The warning identifies the time or gameplay-length constraint
- [ ] Quality is not silently reduced to make the scope fit
- [ ] The user is asked to approve the revised scope

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Implementation Approval and Recovery

**Fixture:**
- The user approves the scope and confirms an intended Git worktree.

**Expected behavior:**
1. The skill asks before creating `prototypes/[concept-name]-vertical-slice/`.
2. It records a recovery checkpoint in `production/session-state/active.md`.
3. It pauses and requests direction if a required worktree cannot be selected.

**Assertions:**
- [ ] The implementation directory is not created without approval
- [ ] The checkpoint records the validation question and current phase
- [ ] Missing worktree isolation blocks implementation rather than being ignored

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Evidence-Based PIVOT

**Fixture:**
- A playtest cannot complete the full loop without guidance or exposes a material architecture issue.

**Expected behavior:**
1. The skill collects concrete playtest observations before reporting.
2. It produces a PIVOT result with the failed assumption and carry-forward notes.
3. It does not recommend Production until the revised slice is validated.

**Assertions:**
- [ ] The report separates observed evidence from recommendations
- [ ] The PIVOT path identifies what must change in design or architecture
- [ ] Next steps route back to the affected design or architecture workflow

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Full Review Mode

**Fixture:**
- A completed report recommends PROCEED.
- Review mode is `full`.

**Expected behavior:**
1. The skill delegates the CD-PLAYTEST review to a generic sub-agent using the creative-director role profile.
2. It supplies the report, validation question, game pillars, and core fantasy.
3. It records any creative-director override before finalizing the result.

**Assertions:**
- [ ] Delegation uses `roles/creative-director.md`, not a fixed custom agent registration
- [ ] Lean and solo modes document the expected skipped review
- [ ] The final recommendation reflects the director review when it runs

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses generic Codex sub-agent delegation with the appropriate role profile
- [ ] Preserves user approval before implementation and report writes
- [ ] Collects actual playtest evidence before choosing a verdict
- [ ] Does not promote the project automatically

## Coverage Notes

Live engine builds and external playtests require a configured game project, so
this spec validates the workflow contract rather than runtime gameplay quality.
