# Skill Test Spec: /prototype

## Skill Summary

`/prototype [concept] [--path html|engine|paper] [--review full|lean|solo]
[--spike]` runs a throwaway concept prototype before GDDs are written. It first
confirms intent with `AskUserQuestion` (Prototype this concept / Skip — concept
already proven / Mid-production spike), forms a falsifiable hypothesis ("If the
player [does X], they will feel [Y] — we will know this is true if [Z]") and asks
for the riskiest assumption. It picks an HTML, Engine or Paper path (genre table,
recommendation pre-stated), presents a 3–5 bullet plan, asks to record it as a
checkpoint in `production/session-state/active.md`, then asks "May I create the prototype
directory at `prototypes/[concept-name]-concept/` and begin implementation?".
Every prototype file starts with a `PROTOTYPE - NOT FOR PRODUCTION` header in
that file's own comment syntax (`#` in GDScript and Python, `//` in C#, C++ and
JavaScript, `<!-- -->` in HTML and Markdown), and standards are intentionally
relaxed.

After a one-question-at-a-time debrief, it fills
`.claude/docs/templates/prototype-report.md`, asks to write
`prototypes/[concept-name]-concept/REPORT.md` and add its row to
`prototypes/index.md` (one ask naming both). Verdicts are **PROCEED / PIVOT / KILL**. PIVOT writes a
`PIVOT-NOTE.md`; KILL runs a five-item soundness check and appends to
`prototypes/GRAVEYARD.md`. In `full` review mode `creative-director` reviews the
result via **CD-PLAYTEST** and answers APPROVE / CONCERNS / REJECT: APPROVE keeps
the recommendation; CONCERNS go to the user, who decides (Revise / Accept /
Discuss); REJECT means a PROCEED cannot stand — the user chooses PIVOT or KILL,
and REPORT.md records the director's reason. A NOT ASSESSED answer (the director
lacked an input) is never an approval. `--spike` replaces the
whole flow with a ~4-hour spike that asks before creating its folder, asks
before writing `SPIKE-NOTE.md` and clearing the spike from `active.md`, and has
no CD gate and no PROCEED/PIVOT/KILL.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PROCEED, PIVOT, KILL, NOT ASSESSED (a prototype nobody has played)
- [ ] Contains "May I create" / "May I write" language before creating the prototype directory and the report
- [ ] Has a next-step handoff per verdict (PROCEED → `/design-review`, `/gate-check`, `/map-systems`, `/design-system`; PIVOT → `/prototype` or `/brainstorm`; KILL → `/brainstorm`)

---

## Director Gate Checks

- **Full mode**: CD-PLAYTEST — `creative-director` receives the REPORT.md
  content, the hypothesis and the pillars (from `design/gdd/game-concept.md`, or
  the pitch and "what they feel" line from `design/game-brief.md`) and returns
  APPROVE / CONCERNS / REJECT, or NOT ASSESSED when it lacked an input.
  APPROVE → the recommendation stands; CONCERNS → shown with the recommendation,
  and the user decides (Revise / Accept / Discuss); REJECT → a PROCEED cannot
  stand: the user chooses PIVOT or KILL, and REPORT.md records the director's
  reason; NOT ASSESSED → never an approval: the missing input is named, and the
  gate is re-run or the review recorded as NOT ASSESSED. If neither document
  exists: "CD-PLAYTEST skipped — game pillars not yet defined at concept
  prototype stage."
- **Lean mode**: skipped — "CD-PLAYTEST skipped — Lean mode."
- **Solo mode**: skipped — "CD-PLAYTEST skipped — Solo mode."
- **Spike mode**: no CD gate and no phase gate, in any review mode.

---

## Test Cases

### Case 1: Happy Path — Engine Prototype, PROCEED

**Fixture:**
- `design/gdd/game-concept.md` describes a 2D platformer; `project.yaml` has
  `engine.name: Godot` and `engine.language: GDScript`
- `prototypes/` has no `grapple-hook-concept/`
- Review mode: `solo`
- In the debrief the user reports the hypothesis CONFIRMED and answers PROCEED

**Input:** `/prototype grapple-hook traversal`

**Expected behavior:**
1. `AskUserQuestion` confirms intent; user picks "Prototype this concept"
2. Skill states a falsifiable hypothesis in the If / feel / know-if form and asks
   for the riskiest assumption
3. Path widget pre-states an Engine recommendation (traversal feel is the
   hypothesis)
4. Plan is presented and confirmed, with the ask naming
   `production/session-state/active.md`; the checkpoint is written there
5. Skill asks "May I create the prototype directory at
   `prototypes/grapple-hook-concept/` and begin implementation?"; every GDScript
   file it writes starts with `# PROTOTYPE - NOT FOR PRODUCTION` (GDScript
   comments use `#`; a `//` header would not parse)
6. Debrief questions are asked one at a time; report drafted from
   `.claude/docs/templates/prototype-report.md`; "May I write this report to
   `prototypes/grapple-hook-concept/REPORT.md` and add its row to
   `prototypes/index.md`?"; a row is appended to `prototypes/index.md`
7. Note "CD-PLAYTEST skipped — Solo mode."; PROCEED routes to `/design-review`,
   `/gate-check`, `/art-bible`, `/map-systems`, `/design-system`, `/review-all-gdds`

**Assertions:**
- [ ] The hypothesis is falsifiable, with a measurable signal
- [ ] Engine is recommended in the path prompt before the user chooses
- [ ] The directory ask names `prototypes/grapple-hook-concept/` and comes before any prototype file is written
- [ ] Every prototype script carries the `PROTOTYPE - NOT FOR PRODUCTION` header as a `#` comment, never `//`; no file is written under the code root
- [ ] REPORT.md is written only after its ask, that ask also names `prototypes/index.md`, and the index gains a row with verdict PROCEED
- [ ] PROCEED next steps include `/map-systems` and `/design-system`

---

### Case 2: PIVOT — Carry-Forward Note Written

**Fixture:**
- A paper prototype of `trade-routes` has just been debriefed
- User answers PIVOT: the route planning was engaging, the upkeep maths was not
- Review mode: `solo`

**Input:** `/prototype trade-routes --path paper`

**Expected behavior:**
1. Paper path writes `prototypes/trade-routes-concept/rules.md` and
   `play-log.md` after the directory ask
2. REPORT.md is written after its ask with verdict PIVOT
3. Skill asks, one at a time: "What specifically worked in this prototype that
   we should preserve…?" and "What is the single most important thing to change?"
4. Skill asks "May I write this to `prototypes/trade-routes-concept/PIVOT-NOTE.md`?"
5. The note holds the original hypothesis, what to keep, what to change and the
   revised hypothesis; next steps are `/prototype [revised-concept]` or
   `/brainstorm [hint]`

**Assertions:**
- [ ] `--path paper` is honoured and produces `rules.md` and `play-log.md`
- [ ] The two carry-forward questions are asked separately
- [ ] "May I write" names `PIVOT-NOTE.md` before it is written
- [ ] The note contains a revised hypothesis
- [ ] Next steps offer `/prototype` for the revised concept or `/brainstorm`

---

### Case 3: KILL — Soundness Check and Graveyard Entry

**Fixture:**
- An HTML prototype of `procedural-dialogue` has been debriefed
- User answers KILL; the debrief shows testers never understood the core
  action after 2 playtests, no fun moment was observed, and the concept only
  worked when the developer explained it

**Input:** `/prototype procedural-dialogue --path html`

**Expected behavior:**
1. REPORT.md is written after its ask with verdict KILL
2. Skill runs the five-item KILL checklist; 3 items apply, so the verdict is sound
3. Skill asks "May I append this concept to `prototypes/GRAVEYARD.md`?"
4. The entry has Kill reason, What worked, What failed and Next time, with a
   specific kill reason (not "it was boring")
5. Next step: `/brainstorm open` or `/brainstorm [new-hint]`

**Assertions:**
- [ ] The KILL checklist is applied, with the 2+ rule deciding soundness
- [ ] "May I append" names `prototypes/GRAVEYARD.md` before writing
- [ ] The graveyard entry has all four fields and a specific kill reason
- [ ] Next steps route to `/brainstorm`

---

### Case 4: Spike Mode — No Debrief, No Gate, No PROCEED/PIVOT/KILL

**Fixture:**
- Project is in Production
- Review mode: `full`

**Input:** `/prototype rope-physics --spike`

**Expected behavior:**
1. Skill skips Phases 1–9 and runs Spike Mode
2. Asks for the spike question in plain text: "Can we [do X] using [approach Y]?"
3. Path widget as in Phase 3; scope limited to 2–3 bullets; ~4-hour cap
4. Asks "May I create `prototypes/rope-physics-spike-[date]/` and build the
   spike there?" before writing any spike file
5. Asks "Did the spike answer the question? YES or NO, and why in one sentence."
6. Asks once, naming both files, "May I write
   `prototypes/rope-physics-spike-[date]/SPIKE-NOTE.md` and clear the spike from
   `production/session-state/active.md`?"; then writes the note (question, result
   YES / NO / PARTIAL, what to do next) and updates `active.md`

**Assertions:**
- [ ] The intent widget and hypothesis/debrief phases are skipped
- [ ] The spike folder is created only after its ask
- [ ] `SPIKE-NOTE.md` and `active.md` are written only after an ask that names both
- [ ] Output is `SPIKE-NOTE.md` in a `-spike-[date]` folder, not a REPORT.md
- [ ] No CD-PLAYTEST spawn or skip note, even though review mode is `full`
- [ ] No PROCEED / PIVOT / KILL verdict is issued

---

### Case 5: Director Gate — CD-PLAYTEST by Review Mode and Pillars

**Fixture:**
- A concept prototype has been built and REPORT.md written with a PROCEED
  recommendation
- Run A: `--review full`, `design/gdd/game-concept.md` exists with pillars;
  `creative-director` returns REJECT — the core fantasy is not present; the user,
  asked PIVOT or KILL, picks PIVOT
- Run B: `--review full`, neither `game-concept.md` nor `design/game-brief.md` exists
- Run C: `--review lean`

**Input:** `/prototype [concept] --review [mode]`

**Expected behavior:**
1. Run A: `creative-director` is spawned for CD-PLAYTEST with the REPORT.md
   content, hypothesis and pillars. Its REJECT means the PROCEED recommendation
   cannot stand: the skill asks the user to choose PIVOT or KILL (it does not pick
   for them), the user picks PIVOT, and after an ask naming REPORT.md and
   `prototypes/index.md` the report records the director's verdict and reason and
   the final PIVOT recommendation; Phase 9 then runs the PIVOT route
2. Run B: no spawn; note "CD-PLAYTEST skipped — game pillars not yet defined at
   concept prototype stage."
3. Run C: no spawn; note "CD-PLAYTEST skipped — Lean mode."

**Assertions:**
- [ ] Run A spawns `creative-director` for CD-PLAYTEST after REPORT.md is written
- [ ] Run A: the director's verdict is read as one of APPROVE / CONCERNS / REJECT, not as a PROCEED / PIVOT / KILL of its own
- [ ] Run A: after the REJECT, PROCEED is not kept; the user is asked to choose PIVOT or KILL
- [ ] Run A's final recommendation is the user's PIVOT, and REPORT.md records it with the director's reason
- [ ] Run B skips with the "game pillars not yet defined" note instead of spawning without pillars
- [ ] Run C skips with the Lean-mode note
- [ ] No other director gate is spawned

---

### Case 6: NOT ASSESSED (Unplayed) and the `workflow: minimal` PROCEED Route

**Fixture:**
- Run A: the prototype was built this session but nobody has played it yet
- Run B: a PROCEED recommendation, `project.yaml` has `modes.workflow: minimal`

**Input:** `/prototype [concept]`

**Expected behavior:**
1. Run A: with no fun evidence yet, PROCEED/PIVOT/KILL are all unreachable; the
   skill reports NOT ASSESSED and stops rather than guessing, naming "play it,
   then run `/prototype [same concept]` again" as the next step
2. Run B: Phase 9's PROCEED route offers `/create-stories` (from the brief) then
   `/dev-story` on the first story, not the GDD/`/map-systems`/`/art-bible` path

**Assertions:**
- [ ] Run A's verdict is NOT ASSESSED, not a guessed PROCEED/PIVOT/KILL
- [ ] Run A's report and `prototypes/index.md` row both read NOT ASSESSED until a playtest happens
- [ ] Run B's recommended path is the `workflow: minimal` route (`/create-stories`, `/dev-story`), not the `standard`/`full` GDD pipeline

---

## Protocol Compliance

- [ ] Confirms intent with `AskUserQuestion` before building (unless `--spike`)
- [ ] Forms a falsifiable hypothesis and stops if the concept is too vague to form one
- [ ] Presents the plan and gets confirmation before building
- [ ] Asks before creating `prototypes/[concept-name]-concept/` and before writing REPORT.md (with its `prototypes/index.md` row), PIVOT-NOTE.md or GRAVEYARD.md
- [ ] In spike mode, asks before creating the spike folder and before writing `SPIKE-NOTE.md` and `active.md`
- [ ] Keeps prototype files under `prototypes/`, each with the `PROTOTYPE - NOT FOR PRODUCTION` header in its own comment syntax
- [ ] Applies the review mode before CD-PLAYTEST and prints the skip note when skipped
- [ ] Ends with the per-verdict next steps

---

## Coverage Notes

- "Skip — concept already proven" (records the evidence, suggests `/map-systems`
  or `/design-system`, and stops) is not tested.
- A concept too vague to form a hypothesis (skill stops and asks the user to
  narrow it) is covered only by protocol compliance.
- Reading a prior `PIVOT-NOTE.md` on the next run to seed the revised hypothesis
  is not tested.
- The engine-path multi-turn fix loop and the 2-hour sunk-cost rule need a live
  run to verify.
- CD-PLAYTEST APPROVE (the recommendation stands), CONCERNS (the user decides:
  Revise / Accept / Discuss), REJECT on a PIVOT or KILL recommendation (it
  stands) and NOT ASSESSED (never an approval) are not separately tested.
