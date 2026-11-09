# Skill Test Spec: /prototype

## Skill Summary

`/prototype [what to make] [--path html|engine|paper] [--review full|lean|solo]
[--spike]` has two routes, chosen by `engine.name` with no question asked.

**The one-shot** (no engine set, `engine.name: web`, or `--path html`): one round
of questions drawn from the matched genre sheets (`.claude/genres/chipsets.yaml`
rows, `chipsets/<name>.md`), then a one-page brief shown as the card: Look and
references, First minute, Challenge, Features and the rest of the brief template,
with the Effort (high), Engine, Guessed and Writes lines under it and Build it /
Change something; nothing is written before Build it. This session builds it at
its own effort (a builder only when the person names another effort, "build it at
medium") and `one-shot-new.sh` makes `prototypes/<name>/` (`index.html`,
`config.js` with every tuning value, `assets/provenance.yaml`; the tweak panel
`tune.js` only when the person asks to tune). Then the small check: a few scripted
keys through `one-shot-check.sh --keys`, no robot player, four rows (boots, shot,
brief words, emoji and outlines), one fix round for text that is too small,
overlapping or off screen and screens that freeze, and the brief checklist marks
each brief line pass, missing, broken or not assessed. With no engine set,
the browser game is built and handed over first whatever is asked at the card; an
engine wish is the card's Engine line and the handover's Next line.
The results go into `evidence/check-run.yaml` through `one-shot-check.sh
--record`. The handover asks before committing and tagging `one-shot/<name>`, shows
the handover card, and goes on to the debrief (Phase 6).

**The engine or paper prototype** (an engine named) is a throwaway concept
prototype before GDDs are written. It first
confirms intent with `AskUserQuestion` (Prototype this concept / Skip — concept
already proven / Mid-production spike), forms a falsifiable hypothesis ("If the
player [does X], they will feel [Y] — we will know this is true if [Z]") and asks
for the riskiest assumption. It picks an Engine or Paper path (genre table,
recommendation pre-stated; the browser sketch is a third, non-recommended option
that continues at the one-shot's card), presents a 3–5 bullet plan, asks to record it as a
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

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Happy Path — Engine Prototype, PROCEED

**Fixture:**
- `design/gdd/game-concept.md` describes a 2D platformer; `project.yaml` has
  `engine.name: Godot` and `engine.language: GDScript`
- `prototypes/` has no `grapple-hook-concept/`
- Review mode: `solo`; `modes.workflow: standard` (pinned: unset resolves to
  minimal, which routes PROCEED to `/create-stories` and `/dev-story` instead of
  the step 7 list — Case 6 covers that route)
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
- Review mode: `full`; `modes.workflow: standard` (pinned: unset resolves to minimal,
  whose spike note and `active.md` wording Case 7 covers)
- `production/sprints/sprint-004.md` is the current sprint and `active.md` shows it

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
7. The note's "what to do next" offers: add to the current sprint / investigate
   further / abandon the idea. `active.md` is cleared back to the current sprint state

**Assertions:**
- [ ] The intent widget and hypothesis/debrief phases are skipped
- [ ] The spike folder is created only after its ask
- [ ] `SPIKE-NOTE.md` and `active.md` are written only after an ask that names both
- [ ] Output is `SPIKE-NOTE.md` in a `-spike-[date]` folder, not a REPORT.md
- [ ] No CD-PLAYTEST spawn or skip note, even though review mode is `full`
- [ ] No PROCEED / PIVOT / KILL verdict is issued
- [ ] At `standard`, the note's next-step options say "add to current sprint", and `active.md` returns to the current sprint state

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

### Case 7: Spike Mode at `workflow: minimal` — the build order, not a sprint

**Fixture:**
- `project.yaml`: `modes.workflow: minimal` (pinned: this case tests the `minimal`
  wording, the opposite of Case 4); review mode `full`
- No `production/sprints/` directory. `design/game-brief.md` lists a build order; the
  story in progress is `production/epics/core/story-002.md` (`Status: In Progress`),
  and `production/session-state/active.md` names it as the current task
- The user answers YES to the spike question

**Input:** `/prototype rope-physics --spike`

**Expected behavior:**
1. The spike runs as in Case 4, with the same asks: the spike folder, then one ask
   naming `SPIKE-NOTE.md` and `active.md`
2. `SPIKE-NOTE.md` holds the question tested, the result (YES / NO / PARTIAL) and
   what to do next: add the mechanic to the brief's build order / investigate
   further / abandon the idea. It does not offer "add to current sprint"
3. `active.md` is updated to clear the spike and return to the story in progress
   (story-002), not to a sprint state
4. No CD gate and no PROCEED / PIVOT / KILL

**Assertions:**
- [ ] The note's next-step options name the brief's build order instead of the current sprint
- [ ] After the write, `active.md` names story-002 as the current task and no sprint
- [ ] The spike folder and the note-and-`active.md` write each follow an ask that names the files
- [ ] No sprint file is created or referenced
- [ ] No CD-PLAYTEST spawn or skip note and no PROCEED / PIVOT / KILL verdict is issued

---

### Case 8: The one-shot — no engine set, Build it

**Fixture:**
- `project.yaml` has no `engine:` block; no `design/game-brief.md`; no `prototypes/`
- Chrome or Edge is installed; review mode `solo`
- The user answers "you pick" to the quick questions, Build it at the card, then
  Commit and tag

**Input:** `/prototype a lighthouse keeper relighting beacons in a storm`

**Expected behavior:**
1. No route or path question. One plain-text message asks one round of at most
   about eight questions drawn from the matched genre sheets, each with its usual
   answer so "you pick" works, with no question tool; what the typed line already
   answers is not asked, and after the reply there is no second round
2. The skill matches the genre on `.claude/genres/chipsets.yaml`'s rows and
   reads only the matched sheets in `chipsets/`, drawing the questions from them
3. The card is the whole brief, with Look and references, First minute and
   Challenge filled and the "you pick" answers marked *(provisional)*, then
   `Effort: high ...`, `Engine: web (guessed)`, a Guessed line and
   `Writes: design/game-brief.md, prototypes/<name>/`, then asks Build it /
   Change something; nothing is written before the answer
4. After Build it: `design/game-brief.md` is written from the brief template, with
   the typed words and the answers under `## In your words`, every Features item
   `[ ]` and Keep empty; `bash .claude/scripts/one-shot-new.sh` makes the folder
5. This session builds the game at its own effort; a builder runs only when the
   person named another effort, and the handover's Effort line says which
6. Before the handover the small check has run: `evidence/self-check.tsv`,
   `evidence/play.png` and `evidence/figures.png` exist, and no `bot.js` is written
7. Every tuning number is a `config.js` entry with value, min, max and step, read
   through `tune.<name>`; no `Math.random` in game code
8. Before the handover card, the brief's Features are marked `[x]` for what the
   build has, in `design/game-brief.md` and `prototypes/<name>/brief.md`
9. The handover asks before committing and tagging `one-shot/<name>`; the card
   says "Not yet played by a person"; then the Phase 6 debrief starts

**Assertions:**
- [ ] Before the card, the only ask is one plain-text message with the quick questions the typed line left open, and none is asked twice
- [ ] The "you pick" answers are marked *(provisional)* in the brief the card shows
- [ ] The built Features are `[x]` in the brief before the commit
- [ ] No file is written before Build it
- [ ] No robot player (no `bot.js`) and no probe or test file of the session's own is written
- [ ] `config.js` holds every tuning value; game code has no `Math.random`
- [ ] The commit and the tag happen only after their ask
- [ ] The handover names what was checked and what was not assessed

---

### Case 9: The one-shot's small check catches a frozen screen

**Fixture:**
- As Case 8, with Chrome or Edge installed
- The first build freezes after its start key: the screen stops changing while keys go in

**Input:** `/prototype a lighthouse keeper relighting beacons in a storm`, then Build it

**Expected behavior:**
1. Before handover the skill runs `bash .claude/scripts/one-shot-check.sh prototypes/<name>
   --keys "<inputs>"` (what leaves the title, then a few seconds of the game's own keys) and
   writes no `bot.js`
2. The `stuck` row fails; the skill fixes the screen in its one fix round and runs the check
   once more; what still fails goes on the card as "Still broken: <row>: <what>"
3. No agent plays the game: no qa-tester, reviewer or art review runs
4. The card carries the small check's rows and ends "Not yet played by a person"

**Assertions:**
- [ ] `evidence/self-check.tsv` and `evidence/play.png` are kept
- [ ] A failed row is fixed and checked once more, or named on the card as Still broken
- [ ] The check refuses a third run in a round; a later fix is checked with the one run it needs
- [ ] With no browser, the rows that could not run are *not assessed* by name, never passed

---

### Case 10: An engine wish waits for play

**Fixture:**
- As Case 8 (no engine set), with Chrome or Edge installed and Godot installed
- At the card the person says "I have Godot installed, use that if it's better"

**Input:** `/prototype a lighthouse keeper relighting beacons in a storm`, then the Godot line, then Build it

**Expected behavior:**
1. The card's Engine line reads `Engine: web now; Godot after you've played it`; `/setup-engine`
   does not run, and the browser game is built in `prototypes/<name>/index.html`
2. The small check runs as in Case 9; no review agent runs
3. The card carries the Next line naming `/setup-engine` Godot after play; a promised piece the
   build lacks is on Still to do

**Assertions:**
- [ ] No `/setup-engine` before the handover; an `index.html` is handed over
- [ ] No game-designer review, no look-first step and no review agent run

---

### Case 11: A 3D game that saves records its small check

**Fixture:**
- As Case 8, with Chrome or Edge installed
- The ask names a 3D game that remembers a best time; the brief's Look is a 3D look

**Input:** `/prototype a 3D marble run against the clock that remembers your best time`, then Build it

**Expected behavior:**
1. The small check's rows name the WebGL renderer (software in a headless browser is fine) and a
   `saved` row with the key the game keeps for next time
2. Before the card the skill runs `one-shot-check.sh prototypes/<name> --record boots=<r>
   shot=<r> outlines=<r>`, and `evidence/check-run.yaml` holds `kind: check-run/1`
3. What the check could not run (its sound, for one) is on the card as *not assessed* with why

**Assertions:**
- [ ] No row is recorded `not-applicable`, and a `not_run` carries its why
- [ ] `state.staged` is set only when the brief's Intent line holds *staged failure*
- [ ] The game never changes for a check: no code that looks for a headless browser, and its
      sound is what the brief asks for; a check that cannot run is *not assessed* on the card,
      never probed

---

### Case 12: A copy of a named game gets one question and is never built

**Fixture:**
- As Case 8: no `engine:` block, no `design/game-brief.md`, no `project.goal`
- The user picks "an original game in the genre", then Build it at the card

**Input:** `/prototype a Pac-Man clone with the same UI: arrow keys, eat every dot to clear the maze, a ghost touching you costs a life`

**Expected behavior:**
1. Before anything else, one question: "An original game in the genre of Pac-Man, or Pac-Man
   with your own twist?"
2. The words answer the rest, so no other question is asked before the card
3. The brief's Avoid line holds "Pac-Man's name, art, characters and UI"; the copy is never built

**Assertions:**
- [ ] One question before the card, and only that one
- [ ] The Avoid line is in the brief; the built game uses none of Pac-Man's name, art, characters or UI
- [ ] Variant: "a maze chase like Pac-Man, but you are a ghost" (named as a reference): no copy question
- [ ] Variant: "an original Pac-Man" (a new label on a copy): the same one question
- [ ] Variant: `design/game-brief.md` exists, written by `/brainstorm`: no questions; the card reads the brief, and `Writes:` names only `prototypes/<name>/`

---

## Protocol Compliance

- [ ] One-shot: no route question; at most one plain-text round of quick questions, only for what the person's words leave open; the card comes before any write, and only an explicit Build it goes on
- [ ] One-shot: only the autonomous automation mode asks no quick question; a run with no question tool still asks the open ones in plain text, and Build it as a numbered list
- [ ] One-shot: asks before committing and tagging `one-shot/<name>`
- [ ] One-shot: the small check runs before handover with no robot player; a row it could not run is *not assessed* by name, never passed
- [ ] One-shot: no review agent, art review or cold play run; the person's play is the test
- [ ] Engine and paper route: confirms intent with `AskUserQuestion` before building (unless `--spike`)
- [ ] Engine and paper route: forms a falsifiable hypothesis and stops if the concept is too vague to form one
- [ ] Engine and paper route: presents the plan and gets confirmation before building
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
