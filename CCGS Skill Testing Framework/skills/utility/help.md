# Skill Test Spec: /help

## Skill Summary

`/help` tells the user where they are in the pipeline and the one thing to do
next. It is read-only and declares the Haiku tier (`model: haiku`), which is
used only when the user types `/help` in Manual mode — in auto mode, or when
Claude starts the skill itself, the session model runs it
(`.claude/docs/model-tiers.md`). Before it runs, it is handed the resolved
config block (`project.stage`, `workflow`) and the output of
`.claude/scripts/story-status.sh`; it reads the session checkpoint itself (Step 3). It then reads
`.claude/docs/workflow-catalog.yaml`, resolves step completion for the current
phase with one call to `bash .claude/scripts/artifact-check.sh --phase [phase]`,
and in Production reads `production/sprint-status.yaml`.

When `workflow` resolves to `minimal` (the default, because `modes.rigor`
defaults to `minimal`) it skips the phase ladder, reads the session checkpoint
(Step 3), and walks the minimal path (Step 4m): engine →
`design/game-brief.md` → stories → `/dev-story` ↔ `/story-done`. The optional
argument is **what the user just finished or is stuck
on** — the skill uses it to advance past the named step, and confusion language
in it adds an escalation footer. It is not a topic filter.

Output is a short "Where You Are" block with `✓ Done`, exactly one `→ Next up`,
optional `~ Also available`, and `Coming up after that`. The verdict line is
`Verdict: **COMPLETE** — next steps identified.` No files are written and no
director gates are invoked.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Frontmatter sets `model: haiku`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Does NOT contain "May I write" language, and `allowed-tools` has no Write or Edit (skill is read-only)
- [ ] Has a next-step handoff (one `→ Next up` recommendation plus escalation paths)

---

## Director Gate Checks

None. `/help` is a read-only navigation skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Production stage with active sprint

**Fixture:**
- `project.yaml` sets `project.stage: Production` and `modes.rigor: standard`
  (so `workflow` resolves to `standard`)
- `production/sprints/sprint-004.md` exists
- `production/sprint-status.yaml` lists one story `status: in-progress`, two
  `status: ready-for-dev`, three `status: done`, and one `status: blocked` with a
  `blocker` field
- `production/session-state/active.md` has a STATUS block naming the in-progress story

**Input:** `/help`

**Expected behavior:**
1. Skill takes `project.stage: Production` and `workflow: standard` from the config block
2. Skill reads `.claude/docs/workflow-catalog.yaml` and runs
   `bash .claude/scripts/artifact-check.sh --phase production`
3. Skill reads `production/sprint-status.yaml`: the in-progress story is
   "currently active", ready-for-dev stories are "next up", done stories count as
   complete, the blocked story is named with its `blocker` text
4. Because `active.md` shows an active task, it is surfaced prominently at the top:
   "It looks like you were working on [story]"
5. Output uses the Step 7 shape headed `## Where You Are: Production`, with a
   single `→ Next up (REQUIRED)` step
6. Verdict is COMPLETE

**Assertions:**
- [ ] Heading reads `## Where You Are: Production`
- [ ] `production/sprint-status.yaml` is read; the in-progress story is surfaced as currently active
- [ ] The blocked story appears with its `blocker` field
- [ ] Exactly one `→ Next up (REQUIRED)` step is shown (not a list of all skills)
- [ ] The in-progress story from `active.md` is surfaced at the top ("It looks like you were working on …")
- [ ] Verdict is COMPLETE
- [ ] No files are written

---

### Case 2: Concept Stage — engine configured, no concept document

**Fixture:**
- `project.yaml` sets `project.stage: Concept`, `modes.rigor: full`, and
  `engine.name: "Godot"` (`full`, because at `standard` the art bible is
  required only when visual-asset stories exist — `.claude/docs/workflow-modes.md`
  — and a Concept-stage project has no stories to decide it by)
- No `design/gdd/game-concept.md`, no `design/art/art-bible.md`, no
  `design/gdd/systems-index.md`, no sprint files

**Input:** `/help`

**Expected behavior:**
1. Skill maps `Concept` to the catalog phase `concept`
2. `artifact-check.sh --phase concept` reports `engine-setup` PRESENT (matched by
   `engine.name` in `project.yaml`) and `game-concept`, `art-bible`, `map-systems` ABSENT
3. `✓ Done` lists Engine Setup
4. `→ Next up (REQUIRED)` is **Game Concept Document** with command `/brainstorm`
5. `Coming up after that` lists Art Bible (`/art-bible`) and Systems Map (`/map-systems`)
6. Verdict is COMPLETE

**Assertions:**
- [ ] Heading reads `## Where You Are: Concept`
- [ ] Engine Setup is shown under `✓ Done` (not reported missing)
- [ ] `→ Next up` is Game Concept Document via `/brainstorm`
- [ ] `/art-bible` and `/map-systems` appear under "Coming up after that", in that order
- [ ] No Production-stage skill (e.g. `/dev-story`, `/sprint-plan`) is suggested
- [ ] Verdict is COMPLETE

---

### Case 3: No stage recorded — phase inferred from artifacts

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` and has no `project.stage`
- No `production/stage.txt`
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist
- No `docs/architecture/adr-*.md`, no `production/epics/**/story-*.md`, code root empty

**Input:** `/help`

**Expected behavior:**
1. Config block reports `project.stage` as not set
2. Skill applies the Step 2 artifact inference (most-advanced match wins):
   `design/gdd/systems-index.md` exists and nothing further → `systems-design`
3. Skill reports the inferred phase normally with the Step 7 shape
4. `→ Next up (REQUIRED)` is System GDDs via `/design-system`. The catalog's
   `design-system` step has only a `note:` check, so `artifact-check.sh` reports
   it `NO_CHECK` with a note — a **MANUAL** step: the skill asks whether any
   system GDD is already done instead of asserting that none is
5. The input has no confusion language, so the Step 9 escalation block is not shown
6. Verdict is COMPLETE

**Assertions:**
- [ ] Skill does not stop or error when no stage is recorded
- [ ] Inferred phase is Systems Design (heading `## Where You Are: Systems Design`), not Concept
- [ ] `→ Next up` is System GDDs via `/design-system`
- [ ] The skill asks the user whether any system GDD is already done (MANUAL step), rather than reporting System GDDs as done or as not started
- [ ] The "Need more detail?" escalation block (`/project-stage-detect`, `/gate-check`, `/start`) is NOT shown
- [ ] Verdict is COMPLETE

---

### Case 4: Argument — user names the step they finished and says they are unsure

**Fixture:**
- `project.yaml` sets `project.stage: Systems Design` and `modes.rigor: standard`
- `design/gdd/systems-index.md` lists two MVP systems, both `Status: Approved`,
  and both system GDDs exist
- No `design/gdd/gdd-cross-review-*.md`
- The catalog's `design-review` step has no artifact check (`NO_CHECK`)

**Input:** `/help just finished design-review, not sure what's next`

**Expected behavior:**
1. The argument is read as the step the user just finished (Step 5), not as a topic filter
2. Skill advances past Per-System Design Review even though its artifact check is `NO_CHECK`
3. `→ Next up (REQUIRED)` is Cross-GDD Review via `/review-all-gdds`
4. "not sure" is confusion language, so the Step 9 "Need more detail?" block is
   appended with `/project-stage-detect`, `/gate-check` and `/start`
5. The `/settings` rigor line is NOT shown: the user does not sound overwhelmed by
   process and the project has not outgrown `standard` (no `settings-guidance.md § 4` trigger fires)
6. Verdict is COMPLETE

**Assertions:**
- [ ] Per-System Design Review is treated as done because the user named it
- [ ] `→ Next up` is Cross-GDD Review via `/review-all-gdds`
- [ ] Escalation block lists `/project-stage-detect`, `/gate-check` and `/start`
- [ ] No `/settings` rigor-change line appears
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — minimal path, no gate and no gate-check route

**Fixture:**
- `project.yaml` has `engine.name: "Godot"` and no `modes` block (`modes.rigor`
  defaults to `minimal`, so `workflow` resolves to `minimal`)
- `design/game-brief.md` exists
- `production/epics/core/story-001.md` is `Status: Complete`,
  `story-002.md` is `Status: In Progress`, `story-003.md` is `Status: Ready`
- Neither `active.md` (its CHECKPOINT names story-002 as the current task, with
  **Next step:** `/dev-story` on it) nor the git log (no commit mentions
  story-002) says story-002's implementation is written

**Input:** `/help`

**Expected behavior:**
1. `workflow: minimal` sends the skill past the rest of Step 2; `project.stage`
   is not mapped
2. Skill reads `active.md`'s STATUS and CHECKPOINT blocks (Step 3), then goes to
   Step 4m
3. Skill runs `bash .claude/scripts/artifact-check.sh --path minimal`
4. The injected `story-status.sh` list has story-002 on the first `IN_PROGRESS`
   line; the skill does not re-run the script or re-rank the stories
5. Output uses the minimal shape: `## Where You Are: Minimal path — 1 of 3 stories complete`,
   with `✓ Done` giving the count of complete stories, not their titles
6. `→ Next up` is story-002 with `/dev-story [story-002 path]`
7. No phase label, no gate line; the concept doc, art bible, systems map, GDDs,
   sprint plan and `/gate-check` are not presented as required
8. No director agents are spawned and no write tool is called

**Assertions:**
- [ ] Heading reads `Minimal path — 1 of 3 stories complete`
- [ ] `active.md`'s checkpoint is read before the next step is chosen (Step 3 runs at `minimal`)
- [ ] `→ Next up` is story-002 via `/dev-story`, not story-003
- [ ] No `/gate-check` line and no "Approaching … gate" line appear
- [ ] Game concept, art bible, systems map and GDDs are not listed as next steps
- [ ] No director gate is invoked and no gate IDs appear in output
- [ ] No write tool is called
- [ ] Verdict is COMPLETE

---

### Case 6: Minimal path — the checkpoint says the work is written

**Fixture:**
- As Case 5, except `active.md`'s CHECKPOINT reads
  **Next step:** `/story-done production/epics/core/story-002.md` (what
  `/dev-story` writes when it finishes a story)

**Input:** `/help`

**Expected behavior:**
1. Step 3 runs at `minimal` and finds the checkpoint's next step
2. story-002 is still on the first `IN_PROGRESS` line, but `active.md` says its
   implementation is written, so `→ Next up` is story-002 with
   `/story-done [story-002 path]`
3. Verdict is COMPLETE

**Assertions:**
- [ ] `→ Next up` is story-002 via `/story-done`, not `/dev-story`
- [ ] story-002 is not counted or listed as complete
- [ ] Verdict is COMPLETE

---

### Case 7: Minimal path — only a blocked story and an unknown status remain

**Fixture:**
- As Case 5, except `story-002.md` is `Status: Blocked` (its file says it waits
  on the art for the player sprite) and `story-003.md` is `Status: Draft`

**Input:** `/help I'm stuck`

**Expected behavior:**
1. The injected list has no `IN_REVIEW`, `IN_PROGRESS` or `TODO` line: story-002
   is on a `BLOCKED` line and story-003 on an `OTHER` line (`Draft`)
2. The skill names story-002 with its blocker and story-003 with its status as
   written, and says nothing can be built next
3. It does **not** say the build order is done, and does not offer the "three
   ways on" of the every-story-Complete branch
4. `→ Next up` is clearing the first of them — story-002's blocker
5. "stuck" is confusion language, so the Step 9 "Need more detail?" block is
   appended — without its `/gate-check` line, since the minimal path has no
   phase gates
6. Verdict is COMPLETE

**Assertions:**
- [ ] story-002 is named with its blocker; story-003 is named with status `Draft`
- [ ] Neither story is recommended to `/dev-story` or `/story-done`
- [ ] The output does not say the build order is done
- [ ] Heading reads `Minimal path — 1 of 3 stories complete`
- [ ] The escalation block appears and has no `/gate-check` line
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Uses the injected config block for `project.stage` and `workflow` instead of re-reading them
- [ ] Resolves step completion with one `artifact-check.sh` call, not a Glob per step
- [ ] Gives exactly one primary (`→ Next up`) recommendation
- [ ] Never auto-runs the recommended skill
- [ ] Asks the user about `MANUAL` steps rather than assuming them done or not done
- [ ] Does not write any files
- [ ] Verdict is COMPLETE in all cases

---

## Coverage Notes

- The case where every story in `sprint-status.yaml` is done is not separately
  tested; the Step 8 gate warning would then apply.
- At `workflow: full` every optional step is listed under `~ Also available`;
  Case 2 runs at `full` only so that the art bible is required, and does not
  assert that listing.
- The minimal path's "every story Complete" branch (three ways on: play the
  build, `/create-stories`, `/settings`) is not separately tested.
