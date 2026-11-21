# Skill Test Spec: /start

## Skill Summary

`/start` is the first-time onboarding skill. Phase 1 reads the project with
`project-state.sh` without printing it (engine, code root and source files,
concept or brief, GDDs, ADRs, other work, and whether `origin` still points at
the template repo); `source_files: unknown` is reported as an unknown code root,
never as no code. When the message that started the skill already asks for a game
in plain words (the person did not type `/start`), it asks and reads nothing and
starts `/prototype` with the Skill tool: the one step it runs itself, because a
typed `/start` runs its turn on the skill's own model and the build must run on the
session's. Phase 2 asks where the user is with four options (A Make me a game
(playable in minutes), B An idea, or none yet, C Clear concept, D Existing work);
the engine is not asked here, `/setup-engine` chooses it.

Phase 3 routes by answer and names only the immediate next step. Route A asks
nothing more, skips Phases 4 to 6 and writes no setting: `/prototype`'s card is its
assumptions card, and Phase 7 names `/prototype`. Route C with no engine offers
`Build it now (Recommended)`, which goes on as route A; with an engine set or named
it offers `Browser sketch first`, not recommended. Phase 4 works
out the stage (B/C: `Concept`; D: from the GDD and ADR counts), the rigor and the
goal. The rigor is kept when `modes.rigor` is set, otherwise inferred from what the
user said (`settings-guidance.md` §3; no signal or no idea → `minimal`). The goal is
kept when `project.goal` is set, otherwise guessed from the user's words (one of
jam, learn, hobby, portfolio, sell, early_access, publisher, mobile, other; no
signal → `hobby`, a selling goal winning a tie). It shows all three on an
assumptions card, which names `/project-settings` for later changes, and asks one
question: `Save them` / `Change something` / `Don't save`. It asks no rigor or goal
question: `Change something` changes a value on the card. Only an explicit yes
writes: the stage through `set-stage.sh` (`project.yaml` and the legacy mirror
`production/stage.txt`), and an inferred rigor and a guessed goal through
`config-set.sh`. Phase 5 asks the automation question unless the
key is set, and writes the pick through `config-set.sh`. `/start` never writes
any of the six knobs `modes.rigor` fronts (`modes.review_mode`,
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`team.size`) or `production/review-mode.txt`.

Phase 6 prints the path for the rigor (Path D's existing-work path included;
at `minimal` a D user with no brief is told where the brief comes from) and
asks which step to take first (with no engine set, `/prototype` straight after
`/brainstorm`); Phase 7 prints a single "Type `[skill]` to begin." line and starts
nothing. A returning user (engine set and a concept or
brief present) skips onboarding. No director gates apply. Verdict: COMPLETE.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec`, no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] States the write rule for every write: the stage, an inferred rigor and a guessed goal only after an explicit yes to the save question that names `project.yaml` and `production/stage.txt`; `modes.automation` from the user's pick, and never when the save was declined
- [ ] Has a next-step handoff at the end (Phase 7: "Type `[skill]` to begin.")
- [ ] `allowed-tools` includes `Skill`, used only by Phase 1's game-already-asked-for step

---

## Director Gate Checks

None. `/start` is a utility setup skill. No director agents exist yet at the
point this skill runs.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Happy Path — Fresh repo, Path A, rigor inferred

**Fixture:**
- No `project.yaml`, no `production/stage.txt`; `technical-preferences.md`
  holds only placeholders (runs without the Fixture Defaults block)
- No design documents, prototypes or source code; `origin` is the user's own repo
- The user picks `B) An idea, or none yet` and answers "none", then `Save them`,
  then `Guided`

**Input:** `/start`

**Expected behavior:**
1. Phase 1 runs `project-state.sh` without printing its rows
2. Phase 2 offers exactly A–D, A being `Make me a game (playable in minutes)`; no
   engine question is asked
3. Path B asks for the idea in plain text, then names only `/brainstorm open` as the
   next step and leaves the full path for later
4. Phase 4 shows the card: stage `Concept`, rigor `minimal` with the reason (no
   concept yet), goal `hobby` marked guessed, and asks to save them to
   `project.yaml` and the stage to `production/stage.txt`; it asks no rigor or goal
   question
5. After `Save them`, `set-stage.sh Concept` creates `project.yaml` and writes
   `production/stage.txt`, `config-set.sh modes.rigor minimal` adds the rigor and
   `config-set.sh project.goal hobby` adds the goal
6. Phase 5 asks the automation question; `config-set.sh modes.automation guided` runs on the pick
7. Phase 6 prints the minimal path in this order, since no engine is set:
   `/brainstorm`, `/prototype` (recommended next), `/setup-engine`,
   `/create-stories`, `/dev-story`; it asks which step to take first
8. Phase 7 prints only "Type `[skill]` to begin."; verdict COMPLETE

**Assertions:**
- [ ] Phase 2 offers exactly the four A–D options and no engine choice
- [ ] No rigor question is asked; the inferred `minimal` is on the card with its reason
- [ ] No goal question is asked; the card's Goal line is `hobby`, marked guessed
- [ ] Nothing is written before the explicit `Save them`
- [ ] `project.stage` and `production/stage.txt` are both `Concept`
- [ ] `project.yaml` ends up holding only `project.stage`, `project.goal`, `modes.rigor` and `modes.automation` from `/start`: none of the six rigor-fronted knobs, and no `production/review-mode.txt`
- [ ] `project.yaml` has exactly one `modes:` block, holding `rigor` and `automation`
- [ ] Phase 6 prints the minimal path with `/prototype` straight after `/brainstorm` and before `/setup-engine`
- [ ] The next skill is not started; Verdict is COMPLETE

---

### Case 2: Returning User — Onboarding skipped

**Fixture:**
- `project.yaml` has `engine.name: Godot` and `modes.rigor: minimal`; no explicit `modes.review_mode`
- `design/game-brief.md` exists

**Input:** `/start`

**Expected behavior:**
1. Phase 1 finds the engine set and the brief present
2. The skill skips onboarding and names the engine (Godot) and the brief
3. Review mode is reported as `solo` (from `modes.rigor: minimal`)
4. The skill points to `/next-step`

**Assertions:**
- [ ] The A–D starting-point question is not asked
- [ ] The message names the configured engine (Godot) and the brief path
- [ ] Review mode is reported as `solo`, resolved from rigor
- [ ] No write is made to `project.yaml` or `production/stage.txt`

---

### Case 3: Existing Work on Unity — Path D, stage from the files, rigor already set

**Fixture:**
- `project.yaml` has `engine.name: Unity`, `project.goal: sell`,
  `modes.rigor: standard` and `modes.automation: collaborative`
- C# scripts exist under `Assets/Scripts/`; `design/gdd/` holds 3 system GDDs;
  no `design/gdd/game-concept.md`, no `docs/architecture/`
- The user picks `D) Existing work` and `Save them`

**Input:** `/start`

**Expected behavior:**
1. Phase 1 resolves the code root as `Assets/` and finds source files there (it
   does not scan `src/` and conclude there is no code)
2. Phase 3 D shares what it found (source files, 3 GDDs, engine Unity) and names
   `/project-stage-detect` as the immediate step
3. Phase 4's card shows stage `Systems Design` (GDDs, no ADRs), and rigor
   `standard` and goal `sell` as already set
4. After the yes, `set-stage.sh "Systems Design"` writes both files; no rigor or goal
   write
5. Phase 5 says "Automation is `collaborative`" and asks nothing
6. Phase 6 prints the existing-work path at `standard`: `/project-stage-detect`,
   `/adopt`, `/design-system retrofit`, `/architecture-decision retrofit`,
   `/architecture-review`, `/gate-check`

**Assertions:**
- [ ] Source files are found under `Assets/`, not reported as absent
- [ ] Stage `Systems Design` is written to both `project.yaml` and `production/stage.txt`, after the yes
- [ ] No rigor or automation question is asked, and neither key is rewritten
- [ ] With `project.goal` already set, the card keeps `sell` without a guess, and `config-set.sh project.goal` does not run
- [ ] The existing-work path at `standard` includes the GDD, ADR and registry retrofit steps
- [ ] Verdict is COMPLETE

---

### Case 4: Clone Still Wired to the Template Repo — remote note, never run

**Fixture:**
- Fresh project as in Case 1
- `.git/config` has `[remote "origin"]` with url
  `https://github.com/Donchitos/Claude-Code-Game-Studios.git`
- The user picks `B) An idea, or none yet` with the hint "a small weekend puzzler", then `Save them`

**Input:** `/start`

**Expected behavior:**
1. `origin_url` matches the template repo case-insensitively
2. Path B names `/brainstorm a small weekend puzzler` as the immediate step
3. The card infers rigor `minimal` from "weekend" and "small"
4. After the Phase 6 path, the skill adds once that `origin` still points at the
   Claude Code Game Studios template repo, suggests `git remote rename origin template` then
   `git remote add origin <your repo URL>`, and says to skip `UPGRADING.md`'s own
   `git remote add template` step since that remote now exists
5. The commands are suggested only; no git command is run

**Assertions:**
- [ ] The template-origin note appears exactly once, after the path
- [ ] Both suggested commands are given as written above
- [ ] The note says to skip `UPGRADING.md`'s `git remote add template` step after the rename, and why
- [ ] No git command is executed
- [ ] The card's rigor is `minimal`, with the user's words as the reason

---

### Case 5: Director Gate Check — No gate; start is a utility setup skill

**Fixture:**
- Fresh project and answers as in Case 1

**Input:** `/start`

**Expected behavior:**
1. The skill completes the onboarding flow through Phase 7
2. No director agent is handed any work
3. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in the output

**Assertions:**
- [ ] No director gate runs
- [ ] No gate skip messages appear (gates are absent, not suppressed)
- [ ] The skill reaches COMPLETE without any gate verdict

---

### Case 6: Path D With Rigor Unset — inferred from the description, not asked

**Fixture:**
- `project.yaml` has `engine.name: Godot` and no `modes` block
- `src/` holds GDScript files; `design/gdd/` holds 4 system GDDs; no
  `docs/architecture/`
- The user picks `D) Existing work` and says "a commercial game for Steam with
  one clear core loop", then picks `Save them`, then `Collaborative`

**Input:** `/start`

**Expected behavior:**
1. Phase 3 D names `/project-stage-detect` as the immediate step and prints no tiered path yet
2. The card shows stage `Systems Design`, rigor `standard` and goal `sell`, each
   with the user's words ("commercial", "Steam") as the reason, and the line naming
   `/project-settings`
3. The save question offers only `Save them` / `Change something` / `Don't save`; no
   rigor or goal question is asked
4. After `Save them`, `modes.rigor: standard` is written with the stage, and
   `config-set.sh project.goal sell` writes the goal
5. Phase 6 prints the existing-work path at `standard`, including
   `/design-system retrofit`, `/architecture-decision retrofit` and
   `/architecture-review`

**Assertions:**
- [ ] No tiered path is printed before the rigor is known
- [ ] No rigor question is asked; the card names `/project-settings` as the way to change it
- [ ] The written rigor is the inferred `standard`, and the written goal the guessed `sell`
- [ ] None of the six rigor-fronted knobs is written; the file holds one `modes:` block

---

### Case 7: Existing `modes:` Block — rigor and automation go into it, never a second one

**Fixture:**
- `project.yaml` has `engine.name: Godot` and an existing block `modes:` with
  only `review_mode: lean` under it; `modes.rigor` and `modes.automation` are
  unset (runs without the Fixture Defaults block, since it tests how the keys
  are added)
- No `design/game-brief.md` and no concept, so this is not a returning user
- The user picks `B) An idea, or none yet` and answers "none", `Save them`, then `Guided`

**Input:** `/start`

**Expected behavior:**
1. `set-stage.sh Concept` adds the `project:` block to the existing file, and
   `config-set.sh project.goal hobby` adds the goal under it
2. `config-set.sh modes.rigor minimal` and `config-set.sh modes.automation guided`
   add both keys under the existing `modes:` block
3. `review_mode: lean` is left as the user had it

**Assertions:**
- [ ] The finished `project.yaml` has exactly one `modes:` key, holding `review_mode`, `rigor` and `automation`, and one `project:` key, holding `stage` and `goal`
- [ ] The existing `review_mode: lean` is unchanged and `/start` writes none of the other rigor-fronted knobs
- [ ] There is one save question for the stage, rigor and goal, and the automation pick needs no further ask

---

### Case 8: Path D at `minimal` With No Brief — names where the brief comes from

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `modes.rigor: minimal` and
  `modes.automation: collaborative`
- `src/` holds 14 GDScript files; `design/gdd/` holds 2 system GDDs; no
  `docs/architecture/`; no `design/game-brief.md` and no
  `design/gdd/game-concept.md`
- The user picks `D) Existing work` and `Save them`

**Input:** `/start`

**Expected behavior:**
1. Phase 1 finds the engine set but no concept or brief, so the A–D question is asked
2. Phase 3 D names `/project-stage-detect` as the immediate step
3. The card shows `Systems Design` and rigor `minimal` as already set; Phase 5 asks nothing
4. Phase 6 prints the existing-work path at `minimal`: `/project-stage-detect`,
   `/adopt`, then the brief's source, with no GDD, ADR or registry retrofit
5. With no brief and 10 or more source files, the brief's source is
   `/reverse-document design src/`; `/brainstorm` is not offered as the source

**Assertions:**
- [ ] The minimal path lists `/project-stage-detect` and `/adopt`, and no `/design-system retrofit`, `/architecture-decision retrofit` or `/architecture-review`
- [ ] With no `design/game-brief.md`, the path names `/reverse-document design src/` as the brief's source, with the code root filled in
- [ ] `/brainstorm` is not named as the brief's source
- [ ] Variant — `src/` holds only 4 source files: the brief's source is `/brainstorm`, and `/reverse-document` is not named
- [ ] Variant — `design/game-brief.md` exists: this is the returning-user skip

---

### Case 9: Make Me a Game, Typed `/start` — handed over by name, nothing written

**Fixture:**
- Fresh project as in Case 1 (no `project.yaml`, runs without the Fixture Defaults block)
- The user picks `A) Make me a game (playable in minutes)`

**Input:** `/start`

**Expected behavior:**
1. Phase 2's first answer reads `Make me a game (playable in minutes)`
2. Route A asks nothing more: no quick questions (they are `/prototype`'s), no stage
   and rigor card, no save question, no automation question
3. Phase 7 prints only "Type `/prototype` to begin."
4. `/prototype` is not started, and the Skill tool is not called: a typed `/start`
   runs its turn on this skill's own model, and the build must run on the session's

**Assertions:**
- [ ] No question follows the Phase 2 answer
- [ ] Nothing is written: no `project.yaml`, no `production/stage.txt`
- [ ] The last line is "Type `/prototype` to begin."
- [ ] No Skill tool call is made; Verdict is COMPLETE
- [ ] Variant — `engine.name: Godot` is set (and no concept): the first answer reads `A) Make me a game`, without "(playable in minutes)", and says it is a throwaway Godot prototype with a browser sketch as one option

---

### Case 10: A Game Asked For in Plain Words — straight to `/prototype`

**Fixture:**
- Fresh project as in Case 1
- The person types, as plain words and not as `/start`: "make me a game where you
  herd sheep with a dog", and the session starts `/start` for it

**Input:** the plain-words message above (the skill is started for the person)

**Expected behavior:**
1. Phase 1's first step sees a game already asked for, typed in plain words
2. The skill asks no question and runs no helper
3. It says in one line that it is taking the person straight to the build
4. It starts `/prototype` with the Skill tool and no arguments

**Assertions:**
- [ ] No question is asked and `project-state.sh` is not run
- [ ] The Skill tool starts `/prototype`, with no arguments (the person's message is their words)
- [ ] Nothing is written
- [ ] No verdict line: `/prototype` takes over
- [ ] Variant — the person typed `/start` and then "make me a game": this case does not apply; Phase 2 is asked as in Case 9

---

### Case 11: Clear Concept — Build it now with no engine, a sketch not recommended with one

**Fixture:**
- Fresh project as in Case 1
- The user picks `C) Clear concept`, gives "a top-down racing game where the track
  floods", then picks `Build it now (Recommended)`

**Input:** `/start`

**Expected behavior:**
1. Path C asks for the concept as plain text, then "How would you like to proceed?"
2. With no engine set and none named, the options are `Build it now (Recommended)` /
   `Formalize it first` / `Jump straight in`
3. `Build it now` goes on as route A: no card, no save, no automation question
4. Phase 7 prints only "Type `/prototype` to begin."

**Assertions:**
- [ ] `Build it now (Recommended)` is the first option
- [ ] Nothing is written after `Build it now`
- [ ] The last line is "Type `/prototype` to begin."
- [ ] Variant — `engine.name: Unity` is set (no concept): the options are `Formalize it first` / `Jump straight in` / `Browser sketch first`, the last saying it is not recommended because the game is rebuilt in the engine
- [ ] Variant — no engine set, but the sentence names one ("a Godot racing game"): the same three options as the Unity variant

### Case 12: A Guessed Goal Changed on the Card — saved as the user said

**Fixture:**
- Fresh project as in Case 1
- The user picks `B) An idea, or none yet` with the hint "a cozy farming game",
  then `Change something` and says "I want to sell it on Steam", then `Save them`,
  then `Guided`

**Input:** `/start`

**Expected behavior:**
1. The first card shows goal `hobby`, marked guessed: nothing in "a cozy farming
   game" points to another goal
2. `Change something` asks what to change, starting with the guessed goal; no goal
   question comes before the card
3. The card is shown again with goal `sell` and "you said" as its reason, and the
   save question is asked again
4. After `Save them`, `config-set.sh project.goal sell` writes the goal with the stage
   and the rigor

**Assertions:**
- [ ] The first card's goal is `hobby`, marked guessed, and no goal question comes before it
- [ ] The second card shows `sell` with "you said"; nothing is written before `Save them`
- [ ] The written goal is `sell`, through `config-set.sh`
- [ ] Variant — `project.goal: jam` is already set and the user changes it on the card to `portfolio`: `config-set.sh project.goal portfolio` runs, since a value changed on the card is saved even when it was already set

### Case 13: Path Shown at `standard` — main path first, the ladder labelled studio mode

**Fixture:**
- Fresh project as in Case 1, but `project.yaml` sets `modes.rigor: standard`
- The user picks `C) Clear concept`, gives "a trading sim across river towns", then
  `Formalize it first`, `Save them` and `Guided`

**Input:** `/start`

**Expected behavior:**
1. The card's rigor line reads `standard` (already set), and its `standard` and
   `full` rows say studio mode
2. Phase 6 opens with the main-path line (make a game, change it after play, grow
   it), then lists `/brainstorm` first and the `standard` path, headed as studio mode
3. One line says studio mode fits a team, a long project or someone who wants the
   paperwork
4. Phase 7 prints only "Type `/brainstorm [concept]` to begin."

**Assertions:**
- [ ] The main-path line comes before any step of the path
- [ ] The studio-mode line names the three fits, once
- [ ] No step is removed or reordered from the `standard` path
- [ ] Variant — path D at `standard`: no main-path line, the studio-mode line still shown

---

## Protocol Compliance

- [ ] Reads the project with `project-state.sh` before the first question, without printing it
- [ ] Asks the starting-point question with options A–D; leaves the engine to `/setup-engine`
- [ ] Never writes any of the six rigor-fronted knobs (`modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`) or `production/review-mode.txt`
- [ ] Shows the stage, rigor and goal on a card and writes them only on an explicit yes; asks no rigor or goal question
- [ ] Skips the automation question when the key is set
- [ ] Writes through `set-stage.sh` and `config-set.sh`, never by editing YAML by hand
- [ ] Prints the existing-work path only in Phase 6, after the rigor is known
- [ ] Starts the next skill only for a game asked for in plain words (Phase 1, through the Skill tool); every other completed run (not the returning-user skip, which ends at its `/next-step` pointer) ends with "Type `[skill]` to begin." and Verdict COMPLETE
- [ ] Route A, and C's `Build it now` and `Browser sketch first`, write no setting (`project.goal` included: `/prototype`'s card shows that route's goal) and skip the stage, rigor and goal card

---

## Coverage Notes

- Path C's `Formalize it first` and `Jump straight in` are not separately tested
  (Case 11 covers `Build it now` and the engine variants).
- The `standard` path for a new game is Case 13 (main path first, studio mode);
  the `full` path is not separately tested.
- The edge cases "picks D but project is empty" / "picks B but code exists" are
  not separately tested.
- `Don't save` (nothing written, the values kept for the run and reported as not
  saved, and no automation write) is not separately tested.
