# Skill Test Spec: $sprint-plan

## Skill Summary

`$sprint-plan` reads the current milestone file and backlog stories, then
generates a new numbered sprint with stories prioritized by implementation layer
and priority score. In full mode the PR-SPRINT director gate runs after the
sprint draft is compiled (producer reviews the plan). In lean and solo modes
the gate is skipped. The skill asks "May I write to `production/sprints/sprint-NNN.md`?"
before persisting. Verdicts: COMPLETE (sprint generated and written) or
BLOCKED (cannot proceed due to missing data or gate failure).

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language (skill writes sprint file)
- [ ] Has a next-step handoff (what to do after sprint is written)

---

## Director Gate Checks

| Gate ID   | Trigger condition        | Mode guard         |
|-----------|--------------------------|--------------------|
| PR-SPRINT | After sprint draft built | full only (not lean/solo) |

---

## Test Cases

### Case 1: Happy Path — Backlog with stories generates sprint

**Fixture:**
- `production/milestones/milestone-02.md` exists with capacity `10 story points`
- Backlog contains 5 unstarted stories across 2 epics, mixed priorities
- `production/session-state/review-mode.txt` contains `full`
- Next sprint number is `003` (sprints 001 and 002 already exist)

**Input:** `$sprint-plan`

**Expected behavior:**
1. Skill reads current milestone to obtain capacity and goals
2. Skill reads all unstarted stories from backlog; sorts by layer + priority
3. Skill drafts sprint-003 with stories fitting within capacity
4. Skill presents draft to user before invoking gate
5. Skill invokes PR-SPRINT gate (full mode); producer approves
6. Skill asks "May I write to `production/sprints/sprint-003.md`?"
7. User approves; file is written

**Assertions:**
- [ ] Stories are sorted by implementation layer before priority
- [ ] Sprint draft is shown before any write or gate invocation
- [ ] PR-SPRINT gate is invoked in full mode after draft is ready
- [ ] Skill asks "May I write" before writing the sprint file
- [ ] Written file path matches `production/sprints/sprint-003.md`
- [ ] Verdict is COMPLETE after successful write

---

### Case 2: Blocked Path — Backlog is empty

**Fixture:**
- `production/milestones/milestone-02.md` exists
- No unstarted stories exist in any epic backlog

**Input:** `$sprint-plan`

**Expected behavior:**
1. Skill reads backlog — finds no unstarted stories
2. Skill outputs "No unstarted stories in backlog"
3. Skill suggests running `$create-stories` to populate the backlog
4. No gate is invoked; no file is written

**Assertions:**
- [ ] Verdict is BLOCKED
- [ ] Output contains "No unstarted stories" or equivalent message
- [ ] Output recommends `$create-stories`
- [ ] PR-SPRINT gate is NOT invoked
- [ ] No write tool is called

---

### Case 3: Gate returns CONCERNS — Sprint overloaded, revised before write

**Fixture:**
- Backlog has 8 stories totalling 16 points; milestone capacity is 10 points
- `review-mode.txt` contains `full`

**Input:** `$sprint-plan`

**Expected behavior:**
1. Skill drafts sprint with all 8 stories (over capacity)
2. PR-SPRINT gate runs; producer returns CONCERNS: sprint is overloaded
3. Skill presents concern to user and asks which stories to defer
4. User selects 3 stories to defer; sprint is revised to 5 stories / 10 points
5. Skill asks "May I write" with revised sprint; writes on approval

**Assertions:**
- [ ] CONCERNS from PR-SPRINT gate surfaces to user before any write
- [ ] Skill allows sprint to be revised after gate feedback
- [ ] Revised sprint (not original) is written to file
- [ ] Verdict is COMPLETE after revision and write

---

### Case 4: Lean Mode — PR-SPRINT gate skipped

**Fixture:**
- Backlog has 4 stories; milestone capacity is 8 points
- `review-mode.txt` contains `lean`

**Input:** `$sprint-plan`

**Expected behavior:**
1. Skill reads review mode — determines `lean`
2. Skill drafts sprint and presents it to user
3. PR-SPRINT gate is skipped; output notes "[PR-SPRINT] skipped — Lean mode"
4. Skill asks user for direct approval of the sprint
5. User approves; sprint file is written

**Assertions:**
- [ ] PR-SPRINT gate is NOT invoked in lean mode
- [ ] Skip is explicitly noted in output
- [ ] User approval is still required before write (gate skip ≠ approval skip)
- [ ] Verdict is COMPLETE after write

---

### Case 5: Edge Case — Previous sprint still has open stories

**Fixture:**
- `production/sprints/sprint-002.md` exists with 2 stories still `Status: In Progress`
- Backlog has 5 new unstarted stories
- `review-mode.txt` contains `full`

**Input:** `$sprint-plan`

**Expected behavior:**
1. Skill reads sprint-002 and detects 2 open (in-progress) stories
2. Skill flags: "Sprint 002 has 2 open stories — confirm carry-over before planning sprint 003"
3. Skill presents user with choice: carry stories over, defer them, or cancel
4. User confirms carry-over; carried stories are prepended to new sprint with `[CARRY]` tag
5. Sprint draft is built; PR-SPRINT gate runs; sprint is written on approval

**Assertions:**
- [ ] Skill checks the most recent sprint file for open stories
- [ ] User is asked to confirm carry-over before sprint planning continues
- [ ] Carried stories appear in the new sprint draft with a distinguishing label
- [ ] Skill does not silently ignore open stories from the previous sprint

---

## Protocol Compliance

- [ ] Shows draft sprint before invoking PR-SPRINT gate or asking to write
- [ ] Always asks "May I write" before writing sprint file
- [ ] PR-SPRINT gate only runs in full mode
- [ ] Skip message appears in lean and solo mode output
- [ ] Verdict is clearly stated at the end of the skill output

---

## Coverage Notes

- The case where no milestone file exists is not explicitly tested; behavior
  follows the BLOCKED pattern with a suggestion to run `$gate-check` for
  milestone progression.
- Solo mode behavior is equivalent to lean (gate skipped, user approval
  required) and is not separately tested.
- Parallel story selection algorithms are not tested here; those are unit
  concerns for the sprint-plan subagent.
