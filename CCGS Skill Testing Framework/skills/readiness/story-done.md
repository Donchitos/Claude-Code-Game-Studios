# Skill Test Spec: /story-done

## Skill Summary

`/story-done` closes the loop between design and implementation. Run at the
end of implementing a story, it reads the story file, re-reads the current
requirement text from `docs/architecture/tr-registry.yaml` (never the story's
quoted copy) and the governing ADR's `## Decision` / `## Consequences`, verifies
each acceptance criterion (automatically, by batched `AskUserQuestion`, or as
`DEFERRED — requires playtest session`), builds a criterion-to-test
traceability table, checks test evidence, and checks GDD/ADR/manifest/scope
deviations (categorised BLOCKING / ADVISORY / OUT OF SCOPE). Review mode then
decides the QA coverage gate (QL-TEST-COVERAGE) and the code review step
(LP-CODE-REVIEW in `full`, a `/code-review` question in `lean`, a noted skip in
`solo`). It produces a COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED
verdict and, only after an `AskUserQuestion` choice, updates the story file,
optionally appends to `docs/tech-debt-register.md`, and surfaces the next story —
with no sprint plan, from `bash .claude/scripts/story-status.sh`, the list `/help`
and `/sprint-status` read, run after the story file is written. It says what a
screenshot shows only after opening it, and asks about behaviour criteria rather
than reading them off the code.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥5 phase headings (complex multi-phase skill)
- [ ] Contains verdict keywords: COMPLETE, COMPLETE WITH NOTES, NOT ASSESSED, BLOCKED
- [ ] `allowed-tools` includes Write/Edit, so ask-before-write language is present ("Use `AskUserQuestion` before writing anything" — covering the story file and the tech-debt register)
- [ ] Has a next-step handoff (surfaces next story from sprint)

---

## Test Cases

### Case 1: Happy Path — All acceptance criteria met, no deviations

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (→ `workflow: standard`,
  `qa.level: standard`, `review_mode: lean`) and `engine.name: Godot`, so
  `tests/unit/` is the test root
- Story file at `production/epics/core/story-light-pickup.md` with:
  - `Type: Logic` and 3 acceptance criteria, all implemented as described:
    AC-1 "Picking up a light adds it to the inventory", AC-2 "A pickup at the
    carry limit is refused", AC-3 "The picked-up light leaves the world"
  - `TR-light-001`; the story quotes an older wording of the requirement, while
    `tr-registry.yaml` holds the current text, which the implementation matches
  - `ADR: ADR-0003` (Accepted), whose guidance was followed
  - A `## Test Evidence` section naming `tests/unit/light/pickup_test.gd`, which
    exists with one test per criterion — `test_pickup_adds_to_inventory`,
    `test_pickup_refused_at_limit`, `test_pickup_removes_world_light` — so every
    criterion maps to a test
  - `Status: In Progress`
- The `/dev-story` checkpoint in `production/session-state/active.md` names this
  story as **Current task** and carries `Run result: OBSERVED — the light leaves
  the floor and the inventory count rises —
  production/qa/evidence/story-light-pickup/01-pickup.png`; that image exists
- Implementation files listed in the story exist in the code root
- A sprint plan in `production/sprints/` has other READY / NOT STARTED Must Have stories

**Input:** `/story-done production/epics/core/story-light-pickup.md`

**Expected behavior:**
1. Skill reads the story and extracts its fields
2. Skill greps `tr-registry.yaml` for `TR-light-001` and uses that current text
3. Skill maps the ADR's headings and reads only `## Decision` and `## Consequences`
4. Skill verifies each criterion and builds the traceability table: AC-1..AC-3
   each map to their test function, all COVERED
5. Test evidence found — reported as "Test file present at `<path>`" (existence,
   not a pass claim); the checkpoint's `Run result: OBSERVED` is noted with its
   retained path
6. No deviations
7. Phase 4b notes "QL-TEST-COVERAGE skipped — Lean mode."
8. Phase 5 (lean) asks "Code review is skipped in lean mode. Did you run `/code-review` on the implemented files?"
9. Completion report with verdict COMPLETE
10. `AskUserQuestion` "Verification complete. How do you want to proceed?"; on "Close the story", the file is updated
11. Skill surfaces the next ready stories from the sprint

**Assertions:**
- [ ] Requirement text comes from `tr-registry.yaml`, not the story's stale quote — the wording difference produces no deviation
- [ ] Skill reads only the ADR's `## Decision` and `## Consequences` spans, not the whole file
- [ ] Each criterion is listed with its status (`auto-verified` / `confirmed` / `FAILS` / `DEFERRED`) and appears in a Criterion | Test | Status traceability table
- [ ] Test evidence is reported as present, without claiming the tests pass
- [ ] In `lean` mode the skill asks whether `/code-review` was run, and records the answer in the Completion Notes `Code Review:` line
- [ ] The traceability table maps each of AC-1..AC-3 to its test function, with no UNTESTED row
- [ ] The `Run result:` line is read from the checkpoint (whose **Current task** names this story) and noted with its retained path
- [ ] Verdict is COMPLETE — every criterion maps to a test, the run was observed and retained, and no deviations exist
- [ ] No file is edited before the Phase 7 `AskUserQuestion`; on "Close the story" the story gets `Status: Complete`, a `Last Updated:` date and a `## Completion Notes` section
- [ ] After completion, skill surfaces the next READY / NOT STARTED Must Have or Should Have story from `production/sprints/` and suggests `/story-readiness [path]`

---

### Case 2: Criteria needing manual or playtest verification

**Fixture:**
- As Case 1, plus two more criteria:
  - (a) "Player sees correct animation on pickup" — no automated test; a frame of
    the animation is retained at `production/qa/evidence/story-light-pickup/02-pickup-anim.png`
  - (b) "Pickup state persists across a full level run" — needs a full game build
- 1 of the 5 criteria ends up with no covering test

**Input:** `/story-done production/epics/core/story-light-pickup.md`

**Expected behavior:**
1. Criterion (a) is a subjective/gameplay criterion → skill asks via a batched
   `AskUserQuestion` ("Does [criterion]?" — `Yes — passes` / `No — fails` / `Not tested yet`)
2. The user answers `Yes — passes`. The retained frame is the observation the
   evidence rule requires; the answer covers the motion a still cannot show, and
   counts as the manual test
3. Criterion (b) is marked `DEFERRED — requires playtest session` and does not block
4. The traceability table shows (b) UNTESTED; 1 of 5 (≤50%) → ADVISORY
5. The Completion Notes list the deferred item and "Untested criteria: [AC-N list]. Recommend adding tests in a follow-up story."

**Assertions:**
- [ ] Skill asks the user about the unverifiable criterion rather than assuming it passes, batching up to 4 such questions per call — a behaviour criterion is never marked verified from reading the code
- [ ] Before the report says what `02-pickup-anim.png` shows, the image is opened with `Read`; the checkpoint's `Run result:` text is quoted as `/dev-story`'s description, never restated as the skill's own observation
- [ ] The playtest-only criterion is marked `DEFERRED — requires playtest session`
- [ ] Verdict is COMPLETE WITH NOTES, and the report lists the DEFERRED criterion — neither BLOCKED nor NOT ASSESSED, since a DEFERRED criterion does not block and does not fire the NOT ASSESSED trigger
- [ ] The deferred criterion is named in the Completion Notes `Criteria:` line, with the untested-criteria recommendation
- [ ] Variant — if the user answers `No — fails` for (a), the criterion is `FAILS`, the verdict is BLOCKED, and the skill does not proceed to Phase 7 on its own
- [ ] Variant — no image for this story is retained under `production/qa/evidence/` and the checkpoint carries no `Run result:` line: the user's `Yes — passes` for (a) is an assertion, not evidence, so the missing observation is flagged at the Logic gate level (BLOCKING by default) and the verdict is BLOCKED — never COMPLETE WITH NOTES on the confirmation alone
- [ ] Skill still asks via `AskUserQuestion` before updating the story file

---

### Case 3: Blocked Path — GDD deviation detected

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- The current `tr-registry.yaml` text for the story's TR-ID: "Player can carry max 3 light sources"
- Implementation in the code root has `MAX_CARRIED_LIGHTS = 5` in gameplay code

**Input:** `/story-done production/epics/core/story-light-pickup.md`

**Expected behavior:**
1. The GDD rules check (against the current registry text) finds the implementation contradicts "max 3"
2. The hardcoded-values check also flags the gameplay literal that belongs in a data file
3. The contradiction is categorised BLOCKING and cited with its GDD/TR reference
4. Verdict BLOCKED; skill lists what must be fixed and offers to help, and does not advance to Phase 7 on its own
5. If the user explicitly asks to close anyway, the Phase 7 menu appears (always asked, even in autonomous mode — `scope_changes`)

**Assertions:**
- [ ] Skill detects the mismatch between the current requirement text and the implemented value
- [ ] The deviation is reported neutrally as BLOCKING with the GDD/TR reference — the skill does not edit code or the GDD to reconcile it
- [ ] Verdict is BLOCKED, and Phase 7 is not entered unless the user explicitly asks to close anyway
- [ ] Closing a BLOCKED story goes through the Phase 7 `AskUserQuestion` regardless of automation mode
- [ ] If closed via "Accept deviations as-is and close anyway", the deviation is recorded in the Completion Notes `Deviations:` line

---

### Case 4: Edge Case — No argument, auto-detect current story

**Fixture:**
- `production/session-state/active.md` names `production/epics/core/story-oxygen-drain.md` as the active story
- That story file exists with `Status: In Progress`

**Input:** `/story-done` (no argument)

**Expected behavior:**
1. Skill reads `production/session-state/active.md` and takes the active story
2. Skill reads that story file and proceeds normally
3. The completion report's `**Story**:` line names the auto-detected path
4. If `active.md` names no story, skill reads the newest sprint plan for IN PROGRESS stories;
   with several, it asks "Which story are we completing?"; with none, it asks for the path

**Assertions:**
- [ ] Skill reads `production/session-state/active.md` first when no argument is given
- [ ] The report's `**Story**:` line names the auto-detected story file
- [ ] With several in-progress stories in the sprint, skill asks which one via `AskUserQuestion` instead of picking one
- [ ] If no story is found anywhere, skill asks the user to provide a path

---

### Case 5: Director Gate — LP-CODE-REVIEW across review modes

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and `qa.level: standard` (so the
  QA coverage gate is not skipped for `qa.level: minimal`)
- Story file at `production/epics/core/story-light-pickup.md`, `Type: Logic`
- All acceptance criteria verified, no GDD deviations, implementation files exist,
  and Case 1's run evidence (the `Run result: OBSERVED` checkpoint and its retained image)
- Review mode comes from `modes.review_mode` (legacy mirror `production/review-mode.txt`) or `--review`

**Case 5a — full mode:** `/story-done production/epics/core/story-light-pickup.md --review full`

**Expected behavior:**
1. After Phases 3–4, skill spawns `qa-lead` with gate QL-TEST-COVERAGE (unless `qa.level: minimal` or a Config/Data story)
2. Skill spawns `lead-programmer` with gate LP-CODE-REVIEW, passing the
   implementation file paths, story path, relevant GDD section and governing ADR
3. The verdict (APPROVE / CONCERNS / REJECT) is presented to the user
4. CONCERNS → `AskUserQuestion`: `Revise flagged issues` / `Accept and proceed` / `Discuss further`
5. REJECT → no Phase 6 verdict until the issues are resolved
6. NOT ASSESSED (a gate input was missing) → the skill names the missing input and
   never reads it as APPROVE: the input is supplied and the gate re-run, or the
   Phase 6 verdict is at best NOT ASSESSED

**Assertions (5a):**
- [ ] Skill uses the resolved review mode before deciding whether to spawn LP-CODE-REVIEW
- [ ] LP-CODE-REVIEW is spawned in full mode after the implementation checks, with the four context items
- [ ] A REJECT verdict prevents the story from reaching a COMPLETE verdict until resolved
- [ ] A CONCERNS verdict produces the three-option `AskUserQuestion`
- [ ] A NOT ASSESSED answer from either gate is never treated as APPROVE / ADEQUATE: unless the missing input is supplied and the gate re-run, the verdict is NOT ASSESSED, not COMPLETE
- [ ] Skill still asks via the Phase 7 `AskUserQuestion` before updating story status, even after APPROVE

**Case 5b — lean mode:** `--review lean`

**Assertions (5b):**
- [ ] LP-CODE-REVIEW does NOT spawn
- [ ] Skill asks "Did you run `/code-review` on the implemented files?" with the three listed options; all three proceed
- [ ] "QL-TEST-COVERAGE skipped — Lean mode." is noted

**Case 5c — solo mode:** `--review solo`

**Assertions (5c):**
- [ ] Neither LP-CODE-REVIEW nor QL-TEST-COVERAGE spawns, and no code-review question is asked
- [ ] Output notes "LP-CODE-REVIEW skipped — Solo mode." and "QL-TEST-COVERAGE skipped — Solo mode."
- [ ] Skill still requires the Phase 7 `AskUserQuestion` before marking the story Complete

---

### Case 6: UI story at `minimal`, no sprint plan — the screenshot closes it

**Fixture:**
- `project.yaml` sets `modes.rigor: minimal` (→ `workflow: minimal`,
  `qa.level: minimal`, `review_mode: solo`); there is no sprint plan in
  `production/sprints/` — the brief's build order is the plan
- `production/epics/mvp/` holds `story-001-*.md` (`Status: Complete`), this story
  `story-002-shop-panel.md` (`Status: In Progress`) and `story-003-*.md` (`Status: Ready`)
- `story-002-shop-panel.md` has `Type: UI` and two criteria: "The shop panel shows
  all 6 item slots inside the frame at 1280x720" and "Each slot shows its price"
- `production/qa/evidence/story-002-shop-panel/01-shop-open.png` exists and shows
  both; the checkpoint carries `Run result: OBSERVED` with that path; there is no
  evidence doc and no sign-off

**Input:** `/story-done production/epics/mvp/story-002-shop-panel.md`

**Expected behavior:**
1. At `qa.level: minimal` the Logic, Integration and Config/Data evidence checks,
   the >50%-untested escalation and Phase 4b are skipped ("QL-TEST-COVERAGE
   skipped — qa.level minimal.") — but the UI screenshot check runs
2. The retained screenshot satisfies the UI gate; no evidence doc or sign-off is asked for
3. Phase 4 runs the manifest, hardcoded-value and scope checks only (no GDD/ADR
   traceability at `minimal`); Phase 5 notes "LP-CODE-REVIEW skipped — Solo mode."
4. Verdict COMPLETE; after the Phase 7 approval the story is marked Complete
5. Phase 8 takes the no-sprint branch: it runs `bash .claude/scripts/story-status.sh`
   after the story file is written; `story-003` is on its first `TODO` line →
   "Run `/dev-story [path]`"

**Assertions:**
- [ ] The UI screenshot check runs at `qa.level: minimal` and is satisfied by the retained image alone — no evidence doc or sign-off is required for a UI story
- [ ] Verdict is COMPLETE, not BLOCKED for a missing sign-off
- [ ] Phase 8 names `story-003` and recommends `/dev-story` directly — no `/story-readiness` line at `minimal`, and no Sprint Close-Out Sequence
- [ ] The next story comes from `bash .claude/scripts/story-status.sh`, run after this story's `Status: Complete` is written — not from a grep of one epic folder
- [ ] Variant — `production/epics/combat/story-001-arena.md` reads `**Status:** In Review`: it is Next Up (the script lists `IN_REVIEW` first, across every epic folder), and the Next Up line recommends `/story-done [path]` to close it, not `/dev-story`
- [ ] Variant — no image under `production/qa/evidence/` and no `Run result:` line: the UI gate is still BLOCKING at `qa.level: minimal`, so the verdict is BLOCKED
- [ ] Variant — `story-003` is `Blocked`, naming its blocker, and no other story is unfinished: Phase 8 prints no Next Up, names `story-003` with its blocker, suggests clearing it, and never says the build order is done

---

### Case 7: NOT ASSESSED — a criterion nobody could evaluate

**Fixture:**
- As Case 1, plus a fourth criterion, AC-4: "The pickup code is robust" — it
  names no observable outcome, so no test, run or playtest could settle it

**Input:** `/story-done production/epics/core/story-light-pickup.md`

**Expected behavior:**
1. AC-1..AC-3 verify as in Case 1
2. AC-4 cannot be evaluated at all — not DEFERRED (no session could settle it as
   written) and not failed
3. Verdict NOT ASSESSED, naming AC-4 and what would make it checkable (rewrite it
   as an observable condition)
4. The skill does not proceed to Phase 7 on its own

**Assertions:**
- [ ] Verdict is NOT ASSESSED — not COMPLETE or COMPLETE WITH NOTES, and not BLOCKED (nothing is known to fail)
- [ ] Output names AC-4, why it cannot be evaluated, and what would make it checkable
- [ ] Phase 7 is entered only if the user explicitly asks to close anyway; it then always prompts (`scope_changes`), and the Completion Notes record AC-4 as never evaluated
- [ ] Variant — AC-4 is a checkable criterion that the user answers `Not tested yet`: it is UNTESTED in the traceability table and the verdict is NOT ASSESSED, naming what would settle it
- [ ] Variant — another criterion also FAILS: the verdict is BLOCKED (BLOCKED is evaluated before NOT ASSESSED)

---

## Protocol Compliance

- [ ] Asks via `AskUserQuestion` before updating the story file
- [ ] Appends to `docs/tech-debt-register.md` only when the user picks "Close and log advisory deviations as tech debt", as rows of `/tech-debt`'s register table with an `Added` date — never as free bullets
- [ ] Presents the complete report (criteria, traceability, test evidence, deviations, scope) before asking
- [ ] Ends by surfacing the next ready story (sprint plan) or the next story in the epic folder (no sprint plan)
- [ ] Never closes a BLOCKED or NOT ASSESSED story on its own — only on the user's explicit request, through Phase 7
- [ ] Never skips code review silently: `full` spawns LP-CODE-REVIEW, `lean` asks, `solo` notes the skip

---

## Coverage Notes

- The full 8-phase flow of the skill is exercised across Cases 1-3; not all
  edge cases within each phase are covered.
- Tech debt logging (`docs/tech-debt-register.md`) is covered only through the
  Phase 7 option and the row-format line in Protocol Compliance; no case writes
  a row.
- The `production/sprint-status.yaml` update and the session-state checkpoint
  (both silent, after the Phase 7 approval) are not primary assertions.
- Case 6 covers the no-sprint-plan branch at `minimal`; the Sprint Close-Out
  Sequence is not tested here.
- Stories with multiple TR-IDs or multiple ADRs are not explicitly tested.
