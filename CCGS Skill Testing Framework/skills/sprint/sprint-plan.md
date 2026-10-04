# Skill Test Spec: /sprint-plan

## Skill Summary

`/sprint-plan` (`new`, `update` or `status`) plans a sprint from the story
backlog. It globs `production/epics/**/story-*.md`, greps their status lines and
plans from the stories marked `Ready`, as many as `story_granularity` allows; it
reads the previous sprint (identified from the injected Existing Sprints listing)
for velocity and carryover, and the milestone in `production/milestones/` and
GDDs for context when they exist. For `new` it numbers the sprint one past the
highest `sprint-NNN.md` in the listing and presents a draft with Must Have /
Should Have / Nice to Have task tables and a Carryover from Previous Sprint table
(every not-Complete story of the previous sprint, listed there only) before any
write, and prepares `production/sprint-status.yaml` alongside it. The review
mode comes from the injected config block, `--review` overriding it for one run;
the skill never asks for one and never writes `modes.review_mode` or
`production/review-mode.txt`. In full review mode the PR-SPRINT producer gate
reviews the draft; in lean and solo modes the gate is skipped with a note. A QA
plan check runs in every mode. The skill asks "May I write the
sprint plan to `production/sprints/sprint-NNN.md` and
`production/sprint-status.yaml`?" before persisting. Verdicts: COMPLETE (both
files written) or BLOCKED (no stories found, or write declined).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language (skill writes sprint file)
- [ ] Has a next-step handoff (`/qa-plan sprint`, `/story-readiness`, `/dev-story`)

---

## Director Gate Checks

| Gate ID   | Trigger condition                                  | Mode guard                |
|-----------|----------------------------------------------------|---------------------------|
| PR-SPRINT | After the draft is presented, before write approval | full only (not lean/solo) |

PR-SPRINT verdicts: REALISTIC / CONCERNS / UNREALISTIC — or NOT ASSESSED
[missing input] (`.claude/docs/director-gates.md`), which is never treated as
REALISTIC.

---

## Test Cases

### Case 1: Happy Path — Ready backlog generates sprint

**Fixture:**
- The injected Existing Sprints listing shows `sprint-001.md` and `sprint-002.md`
- `production/milestones/milestone-02.md` exists
- 5 stories under `production/epics/` across 2 epics have `Status: Ready`
- `project.yaml` sets `modes.review_mode: full` and
  `modes.story_granularity: balanced` (6–10 stories per sprint)
- `production/qa/qa-plan-sprint-003.md` exists
- The producer returns REALISTIC

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill reads the milestone and the previous sprint (sprint-002)
2. Skill globs `production/epics/**/story-*.md`, greps the status lines, and
   plans all 5 `Ready` stories — fewer than `balanced` allows, so the backlog is
   the limit
3. Skill numbers the new sprint 003 (sprint-002 is the highest in the listing)
   and presents the draft without asking to write
4. Skill spawns PR-SPRINT with the story list, capacity, carryover and milestone
   constraints; presents the REALISTIC assessment
5. QA plan check finds `production/qa/qa-plan-sprint-003.md` and notes it
6. Skill asks "May I write the sprint plan to `production/sprints/sprint-003.md`
   and `production/sprint-status.yaml`?"
7. User approves; both files are written; verdict COMPLETE

**Assertions:**
- [ ] Stories come from `production/epics/**/story-*.md` via the status grep, and only `Ready` stories are planned
- [ ] All 5 `Ready` stories are planned — `balanced` allows 6–10, so none is held back
- [ ] Sprint draft is shown before any write prompt or gate invocation
- [ ] PR-SPRINT gate is invoked in full mode after the draft is presented
- [ ] "May I write" prompt names both `production/sprints/sprint-003.md` (next after sprint-002) and `production/sprint-status.yaml`
- [ ] Verdict is COMPLETE after both files are written

---

### Case 2: Blocked Path — No stories in the backlog

**Fixture:**
- `production/epics/` contains no story files (`production/epics/**/story-*.md` matches nothing)
- No `--review` flag, no `modes.review_mode` in `project.yaml`, no `production/review-mode.txt`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Phase 0 takes the review mode from the injected config block — with nothing
   configured, the `modes.rigor` value — and asks no review-depth question
2. Phase 1's glob returns nothing; skill outputs "No stories found under
   `production/epics/`. Run `/create-stories` first (at `standard`/`full`,
   `/create-epics` before it)."
3. Skill stops without inventing work items; verdict BLOCKED
4. No gate is invoked and nothing is written

**Assertions:**
- [ ] Verdict is BLOCKED
- [ ] Output contains "No stories found under `production/epics/`" and recommends `/create-stories`
- [ ] No sprint draft is produced from invented work items
- [ ] PR-SPRINT gate is NOT invoked
- [ ] No review-depth question is asked, and no write happens — `project.yaml` gains no `modes.review_mode` and no `production/review-mode.txt` is created

---

### Case 3: Gate returns CONCERNS — Sprint overloaded, revised before write

**Fixture:**
- 8 `Ready` stories estimated at 16 days in total; available capacity is 10 days
- `project.yaml` sets `modes.review_mode: full` and `modes.story_granularity: balanced`
- A QA plan for the sprint exists in `production/qa/`
- The producer returns CONCERNS: the sprint is overloaded

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill drafts the sprint with all 8 stories and presents it
2. PR-SPRINT runs; producer returns CONCERNS
3. Skill asks via `AskUserQuestion`: "Producer flagged concerns with this sprint
   plan. How do you want to proceed?" with [A] Proceed as planned,
   [B] Adjust scope, [C] Extend the sprint timeline
4. User selects [B]; skill revises the story list and re-presents the plan
5. Skill asks "May I write" for the revised plan; writes on approval

**Assertions:**
- [ ] CONCERNS from PR-SPRINT surfaces through `AskUserQuestion` ([A] Proceed / [B] Adjust scope / [C] Extend timeline) before any write
- [ ] On [B], the revised plan is re-presented before write approval
- [ ] The revised sprint (not the original) is written, and `production/sprint-status.yaml` lists the revised stories
- [ ] Verdict is COMPLETE after revision and write

---

### Case 4: Lean Mode — PR-SPRINT skipped, QA plan check still runs

**Fixture:**
- 4 `Ready` stories under `production/epics/`
- `project.yaml` sets `modes.rigor: standard` and pins no review mode (no
  `modes.review_mode`, no `production/review-mode.txt`, no `--review`), so the
  injected block reads `review_mode: lean (rigor:standard)`
- No QA plan for this sprint exists in `production/qa/`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill reads `review_mode` from the injected config block — `lean` — and asks
   no review-depth question
2. Skill drafts the sprint and presents it
3. PR-SPRINT is skipped; output notes "PR-SPRINT skipped — Lean mode."
4. The QA plan check still runs: skill states "This sprint has no QA plan …" and
   asks via `AskUserQuestion` with [A] Run /qa-plan sprint now and
   [B] Skip for now
5. User selects [A]; skill asks for direct approval of the write
6. User approves; both files are written; verdict COMPLETE

**Assertions:**
- [ ] PR-SPRINT gate is NOT invoked in lean mode
- [ ] Output contains "PR-SPRINT skipped — Lean mode."
- [ ] The QA plan check still runs in lean mode — the missing QA plan is surfaced explicitly with the [A]/[B] choice, not passed silently
- [ ] User approval is still required before the write (gate skip ≠ approval skip)
- [ ] The resolved `lean` is used without a review-depth question, and the write names only the sprint plan and `production/sprint-status.yaml` — `project.yaml` gains no `modes.review_mode` and no `production/review-mode.txt` is created
- [ ] Verdict is COMPLETE after the write

---

### Case 5: Edge Case — Previous sprint still has open stories

**Fixture:**
- The injected Existing Sprints listing shows `sprint-002.md` as the latest sprint
- `production/sprint-status.yaml` still holds sprint 2; 2 of its stories are not
  `done`: one `in-progress`, and one `ready-for-dev` that was never started (its
  story file says `Status: Ready`)
- 5 other stories have `Status: Ready`
- `project.yaml` sets `modes.review_mode: full` and `modes.story_granularity: balanced`
- A QA plan for the sprint exists in `production/qa/`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill reads sprint-002 for velocity and carryover, and numbers the new
   sprint 003
2. Skill plans the 5 other `Ready` stories in the Must Have / Should Have / Nice
   to Have tables
3. The 2 unfinished sprint-002 stories appear in the "Carryover from Previous
   Sprint" table with a reason and a new estimate — the unstarted one there
   only, although its story file says `Ready`
4. The carryover is passed to PR-SPRINT with the proposed story list
5. Skill asks "May I write the sprint plan to `production/sprints/sprint-003.md`
   and `production/sprint-status.yaml`?" and writes on approval; the new yaml
   lists the 2 carryover stories alongside the 5 new ones

**Assertions:**
- [ ] Skill reads the previous sprint (sprint-002, identified from the injected listing)
- [ ] The 2 unfinished stories appear in the "Carryover from Previous Sprint" table with Reason and New Estimate — not silently dropped
- [ ] The unstarted sprint-002 story appears only under Carryover — not again in Must Have / Should Have / Nice to Have, although its status is `Ready`
- [ ] The carryover is passed to the PR-SPRINT gate
- [ ] The written `production/sprint-status.yaml` lists the 2 carryover stories with their previous priority and current status (`in-progress`, `ready-for-dev`)

---

### Case 6: Gate returns UNREALISTIC — Stories deferred before the write

**Fixture:**
- The injected Existing Sprints listing shows `sprint-002.md` as the latest sprint
- 9 `Ready` stories estimated at 20 days in total; available capacity is 10 days
- `project.yaml` sets `modes.review_mode: full` and `modes.story_granularity: balanced`
- A QA plan for the sprint exists in `production/qa/`
- The producer returns UNREALISTIC and names 4 stories to defer

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill drafts sprint 003 with the 9 stories and presents it
2. PR-SPRINT runs; producer returns UNREALISTIC
3. Skill revises the selection — the 4 named stories move down to Should Have or
   Nice to Have — and re-presents the revised plan
4. The QA plan check runs, then skill asks "May I write" for the revised plan
5. User approves; both files are written; verdict COMPLETE

**Assertions:**
- [ ] UNREALISTIC does not end the run, and the original plan is never written — the selection is revised first
- [ ] The 4 named stories are deferred to Should Have or Nice to Have, not dropped from the plan
- [ ] The revised plan is re-presented before the "May I write" prompt
- [ ] The written `production/sprint-status.yaml` carries the deferred stories as `should-have` or `nice-to-have` with `status: backlog`
- [ ] Verdict is COMPLETE after the write

---

### Case 7: Gate returns NOT ASSESSED — No story estimates

**Fixture:**
- 5 `Ready` stories, none with its `Estimate` filled in
- `project.yaml` sets `modes.review_mode: full` and `modes.story_granularity: balanced`
- A QA plan for the sprint exists in `production/qa/`
- The producer returns NOT ASSESSED — the stories carry no estimates
- Asked for estimates, the user has none yet and goes ahead

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Skill drafts the sprint and presents it; PR-SPRINT returns NOT ASSESSED
2. Skill names the missing input (story estimates) and does not treat the
   result as REALISTIC; with no estimates to supply, it records PR-SPRINT as
   `NOT ASSESSED — [missing input]` in the plan's header
3. The QA plan check runs; the "May I write" prompt repeats that PR-SPRINT was
   not assessed
4. User approves; both files are written; verdict COMPLETE

**Assertions:**
- [ ] The missing input (story estimates) is named in the output
- [ ] NOT ASSESSED is not presented as REALISTIC — nothing says the plan's feasibility was reviewed
- [ ] The CONCERNS options ([A] Proceed / [B] Adjust scope / [C] Extend timeline) are not raised for NOT ASSESSED
- [ ] The written plan's header records PR-SPRINT as NOT ASSESSED with the missing input, and the "May I write" prompt says so before the write

---

## Protocol Compliance

- [ ] Shows the draft sprint before invoking PR-SPRINT or asking to write
- [ ] Always asks "May I write" before writing, naming both the sprint file and `production/sprint-status.yaml`
- [ ] Never asks for a review depth and never writes `modes.review_mode` or `production/review-mode.txt` — the resolved value (or `--review`) is used
- [ ] PR-SPRINT gate only runs in full mode
- [ ] Skip message appears in lean and solo mode output
- [ ] The QA plan check runs in every review mode
- [ ] Verdict (COMPLETE or BLOCKED) is clearly stated at the end of the skill output

---

## Coverage Notes

- `update` and `status` modes are not tested.
- No milestone file is not tested; the skill notes "no milestone defined —
  planning against the story backlog alone" and continues rather than blocking.
- Story files that exist with none marked `Ready` are not tested.
- Solo mode behavior is equivalent to lean (gate skipped, user approval
  required) and is not separately tested.
- The cases pin `story_granularity` to `balanced` (6–10 stories per sprint);
  the `coarse` (2–4) and `fine` (15–25) allocations are not tested.
