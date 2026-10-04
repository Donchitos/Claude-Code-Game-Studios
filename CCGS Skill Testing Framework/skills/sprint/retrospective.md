# Skill Test Spec: /retrospective

## Skill Summary

`/retrospective` generates a sprint or milestone retrospective. Before loading
any data it checks `production/retrospectives/` for an existing retrospective and
offers to update it or start fresh (archiving the old file). It reads the sprint
plan from `production/sprints/` (or the milestone definition), uses
`production/sprint-status.yaml` as the primary source for completion when it
exists, runs `git log` for the sprint period, counts TODO/FIXME/HACK markers, and
reads previous retrospectives to follow up their action items. The output covers
Metrics, Velocity Trend, What Went Well, What Went Poorly, Blockers Encountered,
Estimation Accuracy, Carryover Analysis, Technical Debt Status, Previous Action
Items Follow-Up, Action Items for Next Iteration, Process Improvements and a
Summary; a section whose inputs are absent reads `NOT ASSESSED — NO DATA`, and
every `blocked` story in the yaml is a Blocker with an action item. When no
sprint data exists it offers manual input or stop — and, at `workflow: minimal`,
a look back over the closed stories. No director gates are used —
retrospectives are team self-reflection artifacts. The skill asks "May I write
this to `production/retrospectives/retro-sprint-[N]-[date].md`?" (naming the
archive rename too after Start fresh) and afterwards offers to start
`/sprint-plan new`. Verdicts: COMPLETE
(retrospective saved) or BLOCKED (user stopped at the no-data prompt or declined
the write).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language (skill writes retrospective document)
- [ ] Has a next-step handoff (offer to start `/sprint-plan new`; `/gate-check` after a milestone retrospective)

---

## Director Gate Checks

None. Retrospectives are team self-reflection documents; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Sprint with mixed outcomes

**Fixture:**
- `production/sprints/sprint-005.md` exists with 6 stories; no earlier sprint
  plan exists in `production/sprints/`
- `production/sprint-status.yaml` covers sprint 5: 4 stories `done`, 1 `blocked`
  (`blocker: "Waiting on the save-format decision"`), 1 still `backlog`
- `project.yaml` sets `modes.workflow: standard`
- `production/retrospectives/` holds no retrospective at all

**Input:** `/retrospective sprint-005`

**Expected behavior:**
1. Skill globs `production/retrospectives/retro-sprint-005-*.md` — no match
2. Skill reads the sprint plan and `production/sprint-status.yaml`, using the
   yaml as the primary source for completion (4 of 6 done)
3. Skill runs `git log` for the sprint period and counts TODO/FIXME/HACK markers
4. Skill generates the retrospective in its template. With no earlier sprint or
   retrospective, Velocity Trend and Previous Action Items Follow-Up read
   `NOT ASSESSED — NO DATA`, naming what is missing
5. Skill presents the retrospective and top findings (completion rate, velocity
   trend — reported as not assessed — top blocker, most important action item)
6. Skill asks "May I write this to
   `production/retrospectives/retro-sprint-005-[today's date].md`?"
7. User approves; file is written; verdict COMPLETE
8. Skill asks whether to start sprint planning now (`/sprint-plan new`)

**Assertions:**
- [ ] Retrospective contains What Went Well, What Went Poorly and Action Items for Next Iteration sections
- [ ] Completion metrics come from `production/sprint-status.yaml` (4 of 6 done), not from markdown scanning
- [ ] The blocked story appears under Blockers Encountered with "Waiting on the save-format decision" as its Blocker, and an action item addresses it
- [ ] Velocity Trend reads `NOT ASSESSED — NO DATA` — no Increasing / Stable / Decreasing trend and no earlier-sprint rows are invented from a single sprint
- [ ] Previous Action Items Follow-Up reads `NOT ASSESSED — NO DATA` (no earlier retrospective), not an empty table
- [ ] "May I write" prompt names `production/retrospectives/retro-sprint-005-[today's date].md` and appears before the write
- [ ] Verdict is COMPLETE after the write, followed by the offer to start `/sprint-plan new`

---

### Case 2: No Sprint Data — Manual input fallback

**Fixture:**
- User calls `/retrospective sprint-009`
- `production/sprints/sprint-009.md` does NOT exist and
  `production/sprint-status.yaml` has no sprint 9
- `project.yaml` sets `modes.workflow: standard`
- No retrospective for sprint-009 exists

**Input:** `/retrospective sprint-009`

**Expected behavior:**
1. Skill finds no sprint plan for sprint-009
2. Skill outputs "No sprint data found for sprint-009 …"
3. Skill asks via `AskUserQuestion`: [A] Provide data manually, [B] Stop
4. User selects [A] and describes the sprint's tasks, dates and outcomes
5. Skill uses that input as the source of truth and formats it into the
   retrospective structure
6. Skill asks "May I write" and writes the document on approval

**Assertions:**
- [ ] Skill does not crash or produce an empty document when the sprint file is absent, and states that no sprint data was found for sprint-009
- [ ] `AskUserQuestion` offers [A] Provide data manually and [B] Stop — not [C] Look back over the closed stories, which is offered only at `workflow: minimal`
- [ ] Manual input is formatted into the retrospective structure (What Went Well / What Went Poorly / Action Items for Next Iteration)
- [ ] "May I write" prompt still appears before the file write

---

### Case 3: Prior Retrospective Exists — Update existing or start fresh

**Fixture:**
- `production/retrospectives/retro-sprint-005-[earlier date].md` already exists
  with content
- `production/sprints/sprint-005.md` exists
- User re-runs `/retrospective sprint-005` and, when asked, selects [B] Start fresh

**Input:** `/retrospective sprint-005`

**Expected behavior:**
1. Before loading any sprint data, skill globs
   `production/retrospectives/retro-sprint-005-*.md` and finds the existing file
2. Skill asks via `AskUserQuestion`: "An existing retrospective was found:
   [filename]. How do you want to proceed?" with [A] Update existing and
   [B] Start fresh (archive the old one)
3. User selects [B]; skill compiles from a blank slate — the old file is not
   touched yet
4. Skill asks "May I write this to
   `production/retrospectives/retro-sprint-005-[today's date].md`?", and the
   same ask names the rename of the old file to its `-archived-[date]` name
5. User approves; skill renames the old file, then writes the new one; verdict
   COMPLETE

**Assertions:**
- [ ] Skill checks for an existing retrospective before loading sprint data
- [ ] User is offered Update existing or Start fresh — the old file is never silently overwritten
- [ ] The old file is not renamed before the "May I write" prompt is approved, and that prompt names both the new dated path `retro-sprint-005-[today's date].md` and the rename
- [ ] On approval, the old file is kept under an `-archived-[date]` name, not deleted or overwritten
- [ ] Verdict is COMPLETE after the write

---

### Case 4: Edge Case — Unresolved action items from previous retrospective

**Fixture:**
- `production/retrospectives/retro-sprint-004-[date].md` exists with 2 action
  items marked `[ ]` (not done)
- `production/sprints/sprint-005.md` exists; no retrospective for sprint-005 exists
- User runs `/retrospective sprint-005`

**Input:** `/retrospective sprint-005`

**Expected behavior:**
1. Skill reads previous retrospectives in `production/retrospectives/`
2. Skill checks whether the sprint-004 action items were addressed — 2 were not
3. The new retrospective's "Previous Action Items Follow-Up" table lists both
   items with a status other than Done
4. The follow-up table is separate from "Action Items for Next Iteration"

**Assertions:**
- [ ] Skill reads the prior retrospective in `production/retrospectives/` to check its action items
- [ ] Both unresolved items appear in the "Previous Action Items Follow-Up" table
- [ ] Their Status is Not Started or In Progress — not Done
- [ ] The follow-up table is distinct from the newly generated "Action Items for Next Iteration"

---

### Case 5: Gate Compliance — No gate invoked in any mode

**Fixture:**
- `production/sprints/sprint-005.md` exists with complete stories
- `project.yaml` sets `modes.review_mode: full`

**Input:** `/retrospective sprint-005`

**Expected behavior:**
1. Skill compiles the retrospective
2. No director gate is invoked (retrospectives are team self-reflection, not delivery gates)
3. Skill asks user for approval and writes the file on confirmation
4. Verdict is COMPLETE

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output does not contain any gate invocation or gate result notation
- [ ] Skill proceeds directly from compilation to the "May I write" prompt
- [ ] `review_mode` is not among the keys the skill resolves (it resolves `automation`, `workflow`, `qa.level`)

---

### Case 6: Minimal Workflow — Look back over the closed stories

**Fixture:**
- `project.yaml` sets neither `modes.rigor` nor `modes.workflow`, so the injected
  block reads `workflow: minimal (rigor:minimal)`
- `production/sprints/`, `production/milestones/` and
  `production/retrospectives/` do not exist
- 3 stories under `production/epics/core/` have `Status: Complete`; 1 has
  `Status: In Progress`

**Input:** `/retrospective sprint-001`

**Expected behavior:**
1. Skill finds no retrospective and no sprint data for sprint-001
2. At `workflow: minimal`, skill asks via `AskUserQuestion` with three options:
   [A] Provide data manually, [B] Stop, [C] Look back over the closed stories
3. User selects [C]; skill reads the 3 `Complete` stories and continues to
   Phase 3
4. The retrospective covers those 3 stories; the sections that need sprint data
   (planned vs actual, velocity, carryover, estimation accuracy) read
   `NOT ASSESSED — NO DATA`
5. Skill asks "May I write this to
   `production/retrospectives/retro-sprint-001-[today's date].md`?"; user
   approves; verdict COMPLETE

**Assertions:**
- [ ] The no-data prompt offers [C] Look back over the closed stories alongside [A] and [B]
- [ ] Choosing [C] continues to Phase 3 from the `Complete` stories — the run does not stop BLOCKED
- [ ] The `In Progress` story is not reported as completed work
- [ ] The sections that need sprint data read `NOT ASSESSED — NO DATA` rather than invented figures
- [ ] "May I write" appears before the write, and the verdict is COMPLETE after it

---

## Protocol Compliance

- [ ] Checks for an existing retrospective before loading sprint data
- [ ] A section whose inputs are absent reads `NOT ASSESSED — NO DATA` — never an estimate or an empty table
- [ ] Always presents the retrospective and its top findings before asking to write
- [ ] Always asks "May I write" before writing the retrospective file
- [ ] No director gates are invoked
- [ ] Verdict is COMPLETE after a write, BLOCKED when the user stops at the no-data prompt or declines the write
- [ ] Checks prior retrospectives for unresolved action items

---

## Coverage Notes

- Milestone retrospectives (`retro-[milestone-name]-[date].md`, followed by
  `/gate-check`) are not separately tested here.
- The [B] Stop choice at the no-data prompt and a declined write (both verdict
  BLOCKED) are not tested.
