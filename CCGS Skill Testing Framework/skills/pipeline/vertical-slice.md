# Skill Test Spec: /vertical-slice

## Skill Summary

`/vertical-slice [--review full|lean|solo]` is the Pre-Production validation
build: one complete [start → challenge → resolution] loop at near-production
quality, answering a falsifiable question about player experience *and* build
feasibility. It reads the concept (`design/gdd/game-concept.md`, or
`design/game-brief.md` at `rigor: minimal`), the systems index, the architecture
and the control manifest, defines the validation question and a 3–5 minute scope,
asks to record the plan in `production/session-state/active.md`, then asks "May I
create the vertical slice directory at `prototypes/[concept-name]-vertical-slice/`
and begin implementation?". Every slice file starts with a
`VERTICAL SLICE - NOT FOR PRODUCTION` header in that file's own comment syntax.

After a one-question-at-a-time debrief it writes
`prototypes/[concept-name]-vertical-slice/REPORT.md` (from
`.claude/docs/templates/vertical-slice-report.md`) and a `prototypes/index.md`
row, one ask naming both. Verdicts are **PROCEED / PIVOT / KILL**, plus
**NOT ASSESSED** when nobody has played the loop through from scratch — ranked
above PROCEED and below PIVOT and KILL, and never recorded as PROCEED. The verdict
feeds `/gate-check production`, which FAILs a built slice with any NO among its
Vertical Slice Validation items, so PROCEED is not available after such a NO. In
`full` review mode `creative-director` reviews the result via **CD-PLAYTEST**
(APPROVE / CONCERNS / REJECT, or NOT ASSESSED): APPROVE keeps the recommendation;
CONCERNS go to the user (Revise / Accept / Discuss); REJECT means PROCEED cannot
stand — the user chooses PIVOT or KILL and the report records the director's
reason. PIVOT writes a `PIVOT-NOTE.md`; KILL runs a five-item soundness check and
appends to `prototypes/GRAVEYARD.md`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PROCEED, PIVOT, KILL, NOT ASSESSED
- [ ] Contains "May I" language before creating the slice directory and before writing REPORT.md, PIVOT-NOTE.md and GRAVEYARD.md
- [ ] Has a next-step handoff per verdict (PROCEED → `/create-epics`, `/create-stories`, `/sprint-plan`, `/gate-check production`; PIVOT → `/design-system`, `/architecture-decision`, `/vertical-slice`; KILL → `/brainstorm` or `/prototype`)
- [ ] Documents CD-PLAYTEST: spawned in `full`, skipped with a note in `lean`/`solo`

---

## Director Gate Checks

- **Full mode**: CD-PLAYTEST — `creative-director` receives the REPORT.md content,
  the validation question and the pillars and core fantasy (from
  `design/gdd/game-concept.md`, or the pitch and "what they feel" line from
  `design/game-brief.md`). APPROVE → the recommendation stands; CONCERNS → shown
  with the recommendation, and the user decides (Revise / Accept / Discuss);
  REJECT → a PROCEED cannot stand: the user chooses PIVOT or KILL, and REPORT.md
  records the director's reason (a PIVOT or KILL stands); NOT ASSESSED [missing
  input] → neither backs nor overturns the recommendation: the input is supplied
  and the gate re-run, or `CD-PLAYTEST: NOT ASSESSED — [input]` is recorded. Any
  change to REPORT.md and its `prototypes/index.md` row is asked first. When the
  slice's own verdict is NOT ASSESSED the gate is skipped: "CD-PLAYTEST skipped —
  the slice has not been played yet."
- **Lean mode**: skipped — "CD-PLAYTEST skipped — Lean mode."
- **Solo mode**: skipped — "CD-PLAYTEST skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — slice built, played unaided, PROCEED

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `engine.language: GDScript`,
  `modes.review_mode: solo`
- `design/gdd/game-concept.md` (core fantasy, pillars), `design/gdd/systems-index.md`,
  `docs/architecture/architecture.md` and `docs/architecture/control-manifest.md`
  exist; `prototypes/` has no `ember-trail-vertical-slice/`
- In the debrief the player finished the loop unaided, reached the first meaningful
  action in 40 seconds, felt the core fantasy and hit no fun blocker; the user
  answers PROCEED

**Input:** `/vertical-slice`

**Expected behavior:**
1. Reads the concept, systems index, architecture and manifest; states a
   validation question covering player experience AND build feasibility
2. Presents a 3–5 minute scope and the build plan; the confirmation names
   `production/session-state/active.md`, and the checkpoint is written there
3. Asks "May I create the vertical slice directory at
   `prototypes/ember-trail-vertical-slice/` and begin implementation?"; every
   GDScript file it writes starts with `# VERTICAL SLICE - NOT FOR PRODUCTION`
4. Iterates with the user until the loop is playable, then asks for the
   from-scratch playthrough and puts the six debrief questions one at a time
5. Drafts the report from `.claude/docs/templates/vertical-slice-report.md` with a
   day-by-day velocity log; asks "May I write this report to
   `prototypes/ember-trail-vertical-slice/REPORT.md` and add its row to
   `prototypes/index.md`?"; writes both
6. Notes "CD-PLAYTEST skipped — Solo mode."
7. PROCEED routes to `/create-epics layer:foundation`, `/create-epics layer:core`,
   `/create-stories`, `/sprint-plan` and `/gate-check production`

**Assertions:**
- [ ] The validation question has both a player-experience and a build-feasibility part
- [ ] Scope is confirmed, and the checkpoint ask names `active.md`, before any slice file is written
- [ ] The directory ask comes before any slice file; each GDScript file's header is a `#` comment, never `//`
- [ ] The debrief questions are asked one at a time, after the from-scratch playthrough
- [ ] REPORT.md and the `prototypes/index.md` row are written only after one ask naming both; the row records PROCEED
- [ ] The formal stage step is `/gate-check production` (Pre-Production → Production), not `/gate-check pre-production`

---

### Case 2: Failure Path — a built slice with a NO cannot PROCEED

**Fixture:**
- As Case 1, but in the debrief the player needed the developer to explain the
  core action (question 1: no)
- The user answers PROCEED anyway, then picks PIVOT when asked

**Input:** `/vertical-slice`

**Expected behavior:**
1. The skill does not record PROCEED: `/gate-check production` FAILs a built slice
   with any NO among its Vertical Slice Validation items
   (`.claude/skills/gate-check/references/gate-production.md`)
2. It asks the user to choose PIVOT or KILL, naming question 1's answer as the reason
3. The user picks PIVOT; REPORT.md is written, after its ask, with verdict PIVOT
   and the NO named
4. The PIVOT route runs: the two carry-forward questions, one at a time, then "May I
   write this to `prototypes/ember-trail-vertical-slice/PIVOT-NOTE.md`?"

**Assertions:**
- [ ] PROCEED is not written to REPORT.md or `prototypes/index.md` while a validation item is NO
- [ ] The user, not the skill, chooses between PIVOT and KILL
- [ ] The report names the failed validation item
- [ ] PIVOT-NOTE.md is written only after its ask, with what worked, what failed and what the next slice should prove

---

### Case 3: Mode Variant — CD-PLAYTEST in full, skipped in lean and solo

**Fixture:**
- A slice has been debriefed with a PROCEED recommendation and REPORT.md written
- Run A: `modes.review_mode: full`; CD-PLAYTEST returns APPROVE
- Run B: `modes.review_mode: lean`
- Run C: `modes.review_mode: full`, input `/vertical-slice --review solo`

**Expected behavior:**
1. Run A: `creative-director` is spawned for CD-PLAYTEST after REPORT.md is
   written, with the REPORT.md content, the validation question and the pillars
   and core fantasy; APPROVE leaves PROCEED standing and REPORT.md unchanged
2. Run B: no spawn; "CD-PLAYTEST skipped — Lean mode."
3. Run C: `--review solo` overrides the resolved `full`; no spawn; "CD-PLAYTEST
   skipped — Solo mode."

**Assertions:**
- [ ] Run A spawns CD-PLAYTEST only after REPORT.md exists, with the three inputs
- [ ] Run A's APPROVE keeps the recommendation and triggers no REPORT.md update ask
- [ ] Runs B and C spawn no director and print their skip notes
- [ ] No other director gate is spawned in any run

---

### Case 4: Edge Case — the slice is built but nobody has played it

**Fixture:**
- The loop became demonstrable, but the user cannot play it through from scratch
  this session
- `modes.review_mode: full`

**Input:** `/vertical-slice`

**Expected behavior:**
1. The Phase 5 playthrough does not happen, so the verdict is NOT ASSESSED, with
   the reason
2. REPORT.md, after its ask, records the velocity log and NOT ASSESSED; the
   `prototypes/index.md` row records NOT ASSESSED
3. CD-PLAYTEST is not spawned: "CD-PLAYTEST skipped — the slice has not been
   played yet."
4. Next steps: finish the playthrough and debrief from the `active.md` checkpoint,
   then update REPORT.md after asking; the slice is not taken to
   `/gate-check production` as if it had passed

**Assertions:**
- [ ] The verdict is NOT ASSESSED — never PROCEED — and its reason is stated
- [ ] NOT ASSESSED is ranked above PROCEED and below PIVOT and KILL
- [ ] CD-PLAYTEST is not spawned for an unplayed slice, and the skip is announced
- [ ] PROCEED's next steps are not offered

---

### Case 5: Director Gate — CD-PLAYTEST returns REJECT, CONCERNS or NOT ASSESSED

**Fixture:**
- A slice has been debriefed with a PROCEED recommendation and REPORT.md written;
  `modes.review_mode: full`; `design/gdd/game-concept.md` holds the pillars
- Run A: CD-PLAYTEST returns REJECT — the core fantasy is not present. Asked PIVOT
  or KILL, the user picks KILL; no playtest session showed an emotional high
  point, and this is the third slice attempt on the concept
- Run B: CD-PLAYTEST returns CONCERNS — the resolution beat undercuts a pillar; the
  user picks `Accept with noted concerns`
- Run C: CD-PLAYTEST returns NOT ASSESSED — the pillars were missing from the
  context it received

**Input:** `/vertical-slice`

**Expected behavior:**
1. Run A: the REJECT is read as the gate's word, not as a slice verdict. PROCEED
   cannot stand: the skill asks the user to choose PIVOT or KILL; the user picks
   KILL; after "May I update `prototypes/[concept-name]-vertical-slice/REPORT.md`
   and its `prototypes/index.md` row?" both record KILL and REPORT.md records the
   director's reason. Phase 8's KILL route runs: two checklist items apply, so the
   KILL is sound, and it asks "May I append this to `prototypes/GRAVEYARD.md`?"
2. Run B: the concerns are shown beside PROCEED with `Revise the recommendation` /
   `Accept with noted concerns` / `Discuss further`; on Accept, PROCEED stands and,
   after the update ask, REPORT.md records the concerns
3. Run C: the missing input is named; the gate is re-run with the pillars, or
   `CD-PLAYTEST: NOT ASSESSED — [input]` is recorded after the update ask; PROCEED
   is neither confirmed nor overturned by it

**Assertions:**
- [ ] The director's answer is read as APPROVE / CONCERNS / REJECT / NOT ASSESSED — never as a PROCEED / PIVOT / KILL of its own
- [ ] Run A: PROCEED is not kept after the REJECT; the user chooses PIVOT or KILL, and the director's reason is in REPORT.md
- [ ] Run A: the GRAVEYARD.md entry is appended only after its ask, with a specific kill reason
- [ ] Run B: the user decides; the recommendation changes only if the user revises it
- [ ] Run C: NOT ASSESSED is not treated as APPROVE
- [ ] Every REPORT.md / `prototypes/index.md` update follows an ask naming both

---

## Protocol Compliance

- [ ] Reads the concept (or the brief at `minimal`) before defining the validation question
- [ ] Confirms scope before building; asks before recording the plan in `active.md` and before creating `prototypes/[concept-name]-vertical-slice/`
- [ ] Keeps slice files under `prototypes/`, each with the `VERTICAL SLICE - NOT FOR PRODUCTION` header in its own comment syntax
- [ ] Asks before writing REPORT.md (with its `prototypes/index.md` row), PIVOT-NOTE.md, GRAVEYARD.md and any post-gate report update
- [ ] Never records PROCEED after a NO validation item, and never for a slice nobody has played
- [ ] Applies the review mode before CD-PLAYTEST and prints the skip note when skipped
- [ ] Ends with the per-verdict next steps

---

## Coverage Notes

- The multi-turn build loop, the day-3 sunk-cost stop and the day-by-day velocity
  log need a live run to verify.
- Reading a prior `PIVOT-NOTE.md` on a re-run to frame the new validation question
  is not tested.
- The `rigor: minimal` path (the brief's pitch and "what they feel" line in place
  of pillars) is not given its own fixture.
- A KILL whose soundness checklist gives 0–1 items (one targeted PIVOT suggested
  instead) is not tested.
- The networked-game limit (a local slice cannot validate network feel) is
  advisory text, not tested.
