# Skill Test Spec: /sprint-status

## Skill Summary

`/sprint-status` is a Haiku-tier read-only skill that produces a concise sprint
snapshot. It uses the sprint named by its argument, or the most recently
modified file in `production/sprints/`, and reads `production/sprint-status.yaml`
as the source of truth for story status (falling back to markdown scanning with
a warning when the yaml is absent). It greps the story files'
`Last Updated` fields and flags an In Progress story as STALE when its date is
more than 4 days old. The burndown verdict is On Track / At Risk / Behind,
derived from completion % against time consumed %, and any STALE story upgrades
it to at least At Risk. Fast escalation flags go at the top of the output: the
SPRINT AT RISK critical flag, the Must Haves completion flag, and the missing
stories flag. When no sprint files exist it points to `/sprint-plan new` at
`standard`/`full` workflow, and reports build-order progress at `minimal` —
where, if every unfinished story is Blocked, Draft or unstatused, it names them
(each blocked one with its blocker) and never reports the build order done. It
never writes files, invokes no director gates, and makes at most one
recommendation.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings or numbered check sections
- [ ] Contains burndown verdict keywords: On Track, At Risk, Behind
- [ ] Does NOT require "May I write" language (read-only skill)
- [ ] Has a next-step handoff (the Recommendation section)

---

## Director Gate Checks

None. `/sprint-status` is a read-only reporting skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Mixed sprint, At Risk with a blocked Must Have

**Fixture:**
- `production/sprints/sprint-004.md` is the most recently modified sprint file
- `production/sprint-status.yaml` covers sprint 4: it started 13 days ago and
  ends 7 days from today (65% of time consumed)
- The yaml lists 6 stories:
  - 3 with `status: done`
  - 2 with `status: in-progress`, both last updated within the past 2 days
  - 1 with `status: blocked`, `priority: must-have`,
    `blocker: "Waiting on physics ADR acceptance"`

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill selects `sprint-004.md` and reads `production/sprint-status.yaml`
2. Skill computes 65% time consumed and 3/6 = 50% complete — 15 points behind
3. A blocked Must Have with 35% of sprint time remaining (under 40%) triggers
   the critical flag at the top: "SPRINT AT RISK: … Recommend replanning with
   `/sprint-plan update`."
4. Skill outputs the status table with the blocker in the Blocker column and
   the burndown verdict At Risk

**Assertions:**
- [ ] Output includes "Progress: 3/6 tasks (50%)" and a status table listing all 6 stories
- [ ] The blocked story is named with "Waiting on physics ADR acceptance" in its Blocker column
- [ ] Burndown is At Risk (50% complete vs 65% time consumed — 15 points behind)
- [ ] The SPRINT AT RISK critical flag appears at the top, recommending `/sprint-plan update`
- [ ] Skill does not write any files

---

### Case 2: All Stories Complete — On Track with completion flag

**Fixture:**
- `production/sprints/sprint-004.md` is the most recently modified sprint file
- `production/sprint-status.yaml` covers sprint 4: it started 5 days ago and ends
  5 days from today (50% of time consumed)
- All 5 stories have `status: done` (3 `must-have`, 2 `should-have`)

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill reads the yaml — 5/5 complete
2. 100% complete against 50% time consumed → On Track
3. The completion flag appears at the top: "All Must Haves complete. Team can
   pull from Should Have backlog."
4. Must-Haves at Risk reads "None."; the Attention Needed section is omitted
5. Skill ends with a single recommendation

**Assertions:**
- [ ] Burndown is On Track
- [ ] The completion flag "All Must Haves complete. Team can pull from Should Have backlog." appears at the top
- [ ] Output shows "Progress: 5/5 tasks (100%)"
- [ ] Output makes at most one recommendation (or "Sprint is on track — no action needed.")
- [ ] No files are written

---

### Case 3: No Sprint Files — Guidance to run /sprint-plan

**Fixture:**
- `production/sprints/` directory is absent
- `project.yaml` sets `modes.workflow: standard`

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill finds no sprint files
2. At `standard` workflow, skill reports: "No sprint files found. Start a sprint
   with `/sprint-plan new`."
3. Skill stops

**Assertions:**
- [ ] Skill does not error or crash when no sprint file exists
- [ ] Output states "No sprint files found" and recommends `/sprint-plan new`
- [ ] Skill stops there — no burndown verdict and no status table are emitted
- [ ] The `workflow: minimal` build-order report is not used at `standard`

---

### Case 4: Edge Case — Stale In Progress Story (flagged)

**Fixture:**
- `production/sprints/sprint-004.md` is the most recently modified sprint file
- `production/sprint-status.yaml` covers sprint 4: 10-day sprint, 5 days elapsed
  (50% of time consumed); 4 stories — 2 `done`, 2 `in-progress` (50% complete)
- `production/epics/combat/story-003-dash.md` (in progress) has
  `> **Last Updated**: [6 days before today]`
- `production/epics/combat/story-004-parry.md` (in progress) has
  `> **Last Updated**: [3 days before today]`
- No stories are Blocked

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill resolves the dates with one grep for the `Last Updated` field across
   `production/epics/**/story-*.md`
2. story-003 is 6 days old — more than the 4-day threshold — and is flagged
   STALE; story-004 (3 days) is not
3. The Attention Needed table lists story-003 with its Last Updated date, Days
   Stale and the STALE note
4. The burndown, On Track by percentage alone, is upgraded to At Risk with the
   reason "At Risk — 1 stale story(ies): …" naming story-003 with its own age,
   6 days

**Assertions:**
- [ ] Dates come from the story files' `Last Updated` field via a single grep, not from `active.md` or a read per story
- [ ] story-003 (6 days) is flagged STALE by name in Attention Needed; story-004 (3 days) is not flagged
- [ ] Burndown is At Risk despite 50% complete against 50% time consumed, and the escalation reason gives the stale count (1) and story-003's own age (6 days) as separate figures
- [ ] Output does not conflate "stale" with "Blocked" — story-003 keeps its IN PROGRESS status with a STALE note

---

### Case 5: Gate Compliance — Read-only; no gate invocation

**Fixture:**
- `production/sprints/sprint-004.md` exists and `production/sprint-status.yaml`
  lists 4 stories (2 `done`, 2 `in-progress`) with sprint dates
- `project.yaml` sets `modes.review_mode: full`

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill reads the sprint and produces the status snapshot
2. Skill does NOT invoke any director gate regardless of review mode
3. Output is a plain status report with a Burndown verdict (On Track, At Risk or Behind)
4. Skill does not prompt for user approval or ask to write any file

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Output does not contain any "May I write" prompt
- [ ] Skill completes and returns a Burndown verdict without user interaction
- [ ] `review_mode` is not among the keys the skill resolves (it resolves `story_granularity` and `workflow`)

---

### Case 6: Default Minimal Workflow — Build-order progress, no sprint files

**Fixture:**
- `production/sprints/` does not exist
- `project.yaml` sets neither `modes.rigor` nor `modes.workflow`, so the injected
  block reads `workflow: minimal (rigor:minimal)`
- The injected `story-status.sh` list reads:
  ```
  IN_REVIEW    production/epics/core/story-003-dash.md
  IN_PROGRESS  production/epics/core/story-002-jump.md
  TODO         production/epics/core/story-004-parry.md  (Ready)
  COMPLETE     1 of 4
  ```

**Input:** `/sprint-status`

**Expected behavior:**
1. Skill finds no sprint files; at `workflow: minimal` it reports build-order
   progress instead of pointing to `/sprint-plan`
2. Skill prints "Build order: 1 of 4 stories complete"
3. Next is story-003 (In Review), the first line — ahead of story-002, which
   comes first in file order; skill recommends
   `/story-done production/epics/core/story-003-dash.md`
4. Skill stops — no burndown verdict, no status table, no write

**Assertions:**
- [ ] Output does not say "No sprint files found" and does not recommend `/sprint-plan new`
- [ ] Output shows "Build order: 1 of 4 stories complete" — the `In Review` story is not counted as complete
- [ ] Next is story-003, the first line of the list, with `/story-done` and its path — the story files are not re-ranked into file order
- [ ] No burndown verdict is emitted and no file is written

---

### Case 7: Minimal Workflow — Every unfinished story Blocked or Draft

**Fixture:**
- `production/sprints/` does not exist; the injected block reads
  `workflow: minimal (rigor:minimal)`
- The injected `story-status.sh` list reads:
  ```
  BLOCKED      production/epics/core/story-003-dash.md  (Blocked)
  OTHER        production/epics/core/story-004-parry.md  (Draft)
  COMPLETE     2 of 4
  ```
- story-003's file carries the note `BLOCKED: waiting on the dash animation`

**Input:** `/sprint-status`

**Expected behavior:**
1. There is no `IN_REVIEW`, `IN_PROGRESS` or `TODO` line and 2 of 4 stories are
   complete, so there is no Next and the build order is not done
2. Skill prints "Build order: 2 of 4 stories complete"
3. Skill names story-003 with its blocker and story-004 with its status, `Draft`
4. Skill makes one recommendation — clearing story-003's blocker — and stops

**Assertions:**
- [ ] Output never says the build order is done — no "Build order done" line, no three ways on
- [ ] No story is presented as Next — neither the Blocked story-003 nor the Draft story-004
- [ ] story-003 is named with its blocker, "waiting on the dash animation", from its `BLOCKED:` note
- [ ] story-004 is named with its status as written, `Draft`
- [ ] Output makes exactly one recommendation, and no file is written

---

## Protocol Compliance

- [ ] Does NOT use Write or Edit tools (read-only skill)
- [ ] Presents the story status table before the Burndown verdict
- [ ] Does not ask for approval
- [ ] Ends with at most one recommended next step
- [ ] Declares `model: haiku` (when a declared tier is used: `.claude/docs/model-tiers.md`)

---

## Coverage Notes

- At `workflow: minimal`, the all-Complete ("Build order done") and
  `STORIES none` branches are not tested.
- The markdown fallback when `production/sprint-status.yaml` is absent (with its
  "No `sprint-status.yaml` found" warning) is not tested.
- A sprint without dates ("burndown assessment skipped") is not tested.
- Selecting a specific sprint by argument (`/sprint-status 3`) is not tested;
  the cases above use the most recently modified sprint file.
