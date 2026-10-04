# Skill Test Spec: /milestone-review

## Skill Summary

`/milestone-review` reviews a milestone's progress from its definition in
`production/milestones/` (when one exists) and the sprint reports in
`production/sprints/`: feature completeness, quality metrics, code health, risk,
velocity, scope recommendations and a Go/No-Go recommendation (NOT ASSESSED /
GO / CONDITIONAL GO / NO-GO). Blocked stories and their blockers come from
`production/sprint-status.yaml` and the story files, open bugs from
`production/qa/bugs/`. Before producing any report it records each input as
FOUND or ABSENT; a section whose inputs are absent reads
`NOT ASSESSED — NO DATA`, and if every required input is absent it stops with
that as the whole verdict. In full review mode it spawns `producer` with the
PR-MILESTONE gate before the Go/No-Go recommendation is generated; the
producer's verdict (ON TRACK / AT RISK / OFF TRACK) is shown inline, and AT RISK
or OFF TRACK raises an `AskUserQuestion` on how to frame the recommendation. In
lean and solo modes the gate is skipped with a note. The skill asks "May I write
this to `production/milestones/[milestone-name]-review.md`?" before persisting.
Verdicts: COMPLETE (review saved), BLOCKED (write declined), or
`NOT ASSESSED — NO DATA` (no inputs at all).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, NOT ASSESSED
- [ ] Contains Go/No-Go recommendation values: GO, CONDITIONAL GO, NO-GO
- [ ] Contains "May I write" language (skill writes review document)
- [ ] Has a next-step handoff (`/gate-check`, `/sprint-plan`)

---

## Director Gate Checks

| Gate ID       | Trigger condition                              | Mode guard                |
|---------------|------------------------------------------------|---------------------------|
| PR-MILESTONE  | Before the Go/No-Go recommendation is generated | full only (not lean/solo) |

PR-MILESTONE verdicts: ON TRACK / AT RISK / OFF TRACK — or NOT ASSESSED
[missing input] (`.claude/docs/director-gates.md`), on which the skill never
recommends GO.

---

## Test Cases

### Case 1: Happy Path — Nearly complete milestone with one deferred feature

**Fixture:**
- `production/milestones/milestone-03.md` exists (milestone-definition template)
  with 8 features in its Feature List
- 7 features have `Status: Complete`
- 1 feature has `Status: Deferred` (deferred to milestone-04)
- `production/sprints/sprint-007.md` through `sprint-009.md` exist with the
  headings `/sprint-plan` writes
- The features' stories exist under `production/epics/`; none is `Blocked`
- `project.yaml` sets `modes.review_mode: full`
- The producer returns ON TRACK

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill reads `milestone-03.md`, globs the sprint reports (N = 3) and greps
   their sections, then greps the story files for Blocked statuses (none)
2. Skill compiles the review: 7 features under Fully Complete; the deferred
   feature is not counted as complete
3. Skill spawns `producer` with PR-MILESTONE, passing milestone name and target
   date, completion percentage, blocked story count (0), velocity data and cut
   candidates
4. The producer's ON TRACK verdict is shown inline in the Go/No-Go section; no
   framing question is asked
5. Skill presents the review and asks "May I write this to
   `production/milestones/milestone-03-review.md`?"
6. User approves; file is written; verdict COMPLETE

**Assertions:**
- [ ] The deferred feature is not listed under Fully Complete and is not counted as complete in the completion percentage (7 of 8)
- [ ] PR-MILESTONE is spawned in full mode before the Go/No-Go recommendation, with completion percentage and blocked story count passed
- [ ] The producer's ON TRACK verdict appears inline in the Go/No-Go section, and no framing `AskUserQuestion` is raised (only AT RISK and OFF TRACK raise one)
- [ ] Skill asks "May I write" before writing, naming `production/milestones/milestone-03-review.md`
- [ ] Verdict is COMPLETE after the write

---

### Case 2: Blocked Milestone — Producer returns OFF TRACK

**Fixture:**
- `production/milestones/milestone-03.md` lists 5 features
- 2 features have `Status: Complete`
- 3 features have `Status: Blocked`; each has one story under
  `production/epics/[its epic]/` whose file carries `> **Status**: Blocked` and
  a `BLOCKED:` note naming its blocker
- Sprint reports exist in `production/sprints/`; they name no blockers
- `project.yaml` sets `modes.review_mode: full`
- The producer returns OFF TRACK

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill reads the milestone and sprint reports, then greps the story files for
   `Blocked` statuses and `BLOCKED:` notes; compiles the 3 blocked features in
   the Blocked table with their blockers
2. Skill spawns PR-MILESTONE, passing a completion percentage of 40% and a
   blocked story count of 3
3. On OFF TRACK, skill asks via `AskUserQuestion`: "Producer verdict: OFF TRACK.
   The milestone is in jeopardy. This review will recommend NO-GO. How do you
   want to proceed?" with [A] Accept NO-GO, [B] Override to CONDITIONAL GO,
   [C] Stop
4. User selects [A]; the Go/No-Go recommendation is NO-GO
5. Skill presents the review, asks "May I write", and writes on approval

**Assertions:**
- [ ] Each blocked feature is named in the Blocked table with its blocker, taken from its story's `BLOCKED:` note — the sprint reports carry none, so a blocker not read from the story files is invented
- [ ] PR-MILESTONE receives the blocked story count (3), counted from the story files
- [ ] OFF TRACK raises the `AskUserQuestion` with Accept NO-GO / Override to CONDITIONAL GO / Stop before the recommendation is generated
- [ ] After [A], the recommendation is NO-GO — the skill does not issue GO against an OFF TRACK verdict
- [ ] "May I write" prompt still appears before the file is written

---

### Case 3: Full Mode — PR-MILESTONE returns AT RISK over scope drift

**Fixture:**
- `production/milestones/milestone-03.md` lists 6 complete features, 2 of which
  were not in the original definition (added mid-milestone)
- Sprint reports exist in `production/sprints/`
- `project.yaml` sets `modes.review_mode: full`
- The producer returns AT RISK, citing the 2 added features as scope drift and
  listing mitigations

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill compiles the review
2. PR-MILESTONE returns AT RISK with mitigations
3. Skill asks via `AskUserQuestion`: "Producer verdict: AT RISK. Milestone may
   slip. How should the Go/No-Go section be framed?" with [A] CONDITIONAL GO,
   [B] NO-GO, [C] GO
4. User selects [A]; the Go/No-Go section reads CONDITIONAL GO and lists the
   producer's conditions
5. Skill presents the review, asks "May I write", and writes on approval

**Assertions:**
- [ ] The producer's AT RISK assessment, including its scope-drift finding, is shown inline in the Go/No-Go section — not suppressed
- [ ] AT RISK raises the `AskUserQuestion` with CONDITIONAL GO / NO-GO / GO before the file is written
- [ ] After [A], the recommendation is CONDITIONAL GO and its Conditions list carries the producer's conditions
- [ ] The review is written only after "May I write" is approved

---

### Case 4: Edge Case — No milestone definition and no sprint data

**Fixture:**
- `production/milestones/` does not exist
- `production/sprints/` does not exist
- `production/risk-register/` does not exist
- No source files exist under the code root
- No story files, no `production/sprint-status.yaml` and no `production/qa/bugs/`
- `project.yaml` sets `modes.review_mode: full`

**Input:** `/milestone-review current`

**Expected behavior:**
1. Skill lists its inputs and records each as FOUND or ABSENT
2. Every required input is ABSENT, so the skill stops and reports
   `NOT ASSESSED — NO DATA` as the whole verdict
3. The report names what was missing and where it comes from: sprint reports
   are written by `/sprint-plan`; milestone definitions are authored by hand
   from `.claude/docs/templates/milestone-definition.md`
4. No milestone definition is fabricated, no gate is spawned, no file is written

**Assertions:**
- [ ] Skill does not crash and does not fill the review template with estimated values
- [ ] Verdict is `NOT ASSESSED — NO DATA` — not GO and not COMPLETE
- [ ] Output names the missing inputs and where each comes from (`/sprint-plan` for sprint reports; the milestone-definition template for milestones)
- [ ] PR-MILESTONE is not spawned and no "May I write" prompt appears

---

### Case 5: Lean/Solo Mode — PR-MILESTONE gate skipped

**Fixture:**
- `production/milestones/milestone-03.md` lists 5 features, all `Status: Complete`
- Sprint reports exist in `production/sprints/`
- `production/qa/bugs/` does not exist — no bug has been filed with `/bug-report`
- `project.yaml` sets `modes.review_mode: solo`

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill reads `review_mode` from the injected config block — `solo`
2. Skill compiles the review; with no bug files, the Quality Metrics bug lines
   read `NOT ASSESSED — NO DATA`
3. PR-MILESTONE is skipped; output notes "PR-MILESTONE skipped — Solo mode."
4. The Go/No-Go section is presented without a producer verdict
5. Skill asks "May I write this to `production/milestones/milestone-03-review.md`?"
6. User approves; review file is written; verdict COMPLETE

**Assertions:**
- [ ] PR-MILESTONE gate is NOT invoked in solo mode
- [ ] Output contains "PR-MILESTONE skipped — Solo mode."
- [ ] The Go/No-Go section carries no producer verdict (no ON TRACK / AT RISK / OFF TRACK attributed to the producer)
- [ ] The Quality Metrics bug lines read `NOT ASSESSED — NO DATA` — not "0" — while the sections that have inputs are still produced
- [ ] User approval is still required before the write
- [ ] Verdict is COMPLETE after the write

---

### Case 6: Lean Mode from Rigor — PR-MILESTONE skipped with the Lean note

**Fixture:**
- `production/milestones/milestone-03.md` lists 4 features, all `Status: Complete`
- Sprint reports exist in `production/sprints/`
- `project.yaml` sets `modes.rigor: standard` and pins no review mode, so the
  injected block reads `review_mode: lean (rigor:standard)`

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill reads `review_mode` from the injected config block — `lean`
2. Skill compiles the review
3. PR-MILESTONE is skipped; output notes "PR-MILESTONE skipped — Lean mode."
4. The Go/No-Go section is presented without a producer verdict
5. Skill asks "May I write", writes on approval; verdict COMPLETE

**Assertions:**
- [ ] PR-MILESTONE gate is NOT invoked in lean mode
- [ ] Output contains "PR-MILESTONE skipped — Lean mode." — not the Solo note
- [ ] The Go/No-Go section carries no producer verdict
- [ ] User approval is still required before the write, and the verdict is COMPLETE after it

---

### Case 7: Gate returns NOT ASSESSED — Never GO

**Fixture:**
- `production/milestones/milestone-03.md` lists 5 features, all `Status: Complete`,
  but gives no Target Date
- Sprint reports exist in `production/sprints/`; the stories exist under
  `production/epics/` and none is `Blocked`
- `project.yaml` sets `modes.review_mode: full`
- The producer returns NOT ASSESSED — no target date to judge against
- Asked for the date, the user has none to give

**Input:** `/milestone-review milestone-03`

**Expected behavior:**
1. Skill compiles the review and spawns PR-MILESTONE; it returns NOT ASSESSED
2. Skill names the missing input (the target date) and treats the result as
   neither ON TRACK nor a reason to recommend GO
3. Nothing in the review's own findings calls for CONDITIONAL GO or NO-GO, so
   the Go/No-Go recommendation reads NOT ASSESSED, naming the missing target date
4. Skill asks "May I write", writes on approval; verdict COMPLETE

**Assertions:**
- [ ] The Go/No-Go recommendation is NOT ASSESSED — never GO — although every feature is Complete
- [ ] The missing target date is named in the Go/No-Go section
- [ ] The AT RISK and OFF TRACK framing questions are not raised for NOT ASSESSED
- [ ] "May I write" still appears before the file is written

---

## Protocol Compliance

- [ ] Records each input as FOUND or ABSENT before producing a report; reports `NOT ASSESSED — NO DATA` when every required input is absent, and for any single section whose inputs are absent
- [ ] In full mode, spawns PR-MILESTONE before generating the Go/No-Go recommendation, and presents the complete review before asking to write
- [ ] Always asks "May I write" before writing the review document
- [ ] PR-MILESTONE gate only runs in full mode; the skip message appears in lean and solo output
- [ ] Verdict is stated clearly — COMPLETE, BLOCKED (write declined) or `NOT ASSESSED — NO DATA` — and the Go/No-Go recommendation is one of NOT ASSESSED / GO / CONDITIONAL GO / NO-GO

---

## Coverage Notes

- `production/milestones/` absent while sprint reports exist (the skill says so
  and reviews against the sprint reports alone) is not tested.
- `current` selection skipping files that end `-review.md` is not tested.
- The declined-write path (verdict BLOCKED) is not tested.
- Velocity calculation specifics (story points vs. story count) are not
  verified here; they are implementation details of the review compilation phase.
