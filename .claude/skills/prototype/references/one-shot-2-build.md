# /prototype — One-shot 2: The build

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

A good brief built at high effort makes the deepest games; the same brief at medium makes thinner ones. The build follows the brief and the rules below, nothing else from Claude Code Game Studios: the genre sheet has done its work in the brief.

**In this file:** 1 Who builds · 2 The rules · 3 Build it · 4 Day-one screens · 5 The small
check · 6 The report

## 1. Who builds

1. Run `bash .claude/scripts/one-shot-new.sh <name> --question "<the brief's Question>" --title
   "<the title>"`. It makes `prototypes/<name>/` from the lean starter and copies the brief
   there. When the brief lives in `prototypes/<name>/brief.md` alone (One-shot 1, section 1),
   write it there now as the card showed it, over any copy the script made of
   `design/game-brief.md`, which is the other game's. An `exists` row means the folder is
   already there: ask One-shot 1 section 6's question (carry on with that game, or a new one
   beside it). Any other failure: say what it printed and stop.
2. **This session builds the game,** from section 2 on, at its own effort. A builder is started
   only when the brief's Effort line names a level the person picked ("build it at medium") and
   the Agent tool has an `effort` input: `subagent_type` general-purpose, `effort` that level, no
   model, in the foreground, and this whole prompt, filled in:

   ```text
   Build the browser game in prototypes/<name>/ from its brief, prototypes/<name>/brief.md.
   Read .claude/skills/prototype/references/one-shot-2-build.md from "## 2. The rules" to its
   end and follow it. Images the brief names: <its references/ files, or none>.
   ```

   An Agent tool with no `effort` input means `CLAUDE_CODE_EFFORT_LEVEL` fixes every agent's
   effort: build it here.
3. Say one line as it starts, with the time it started (the `time` row `one-shot-new.sh`
   printed) and no estimate: "Building at this session's effort since <time>", "Building at
   <effort> effort on a builder since <time>", or "Building at the effort
   CLAUDE_CODE_EFFORT_LEVEL sets since <time>".

   **Asked how long, or what we are waiting for,** while a build or a change is being made: run
   `date +%H:%M` first and count the minutes since it started (this `time` row, or the clock
   noted when the change started). Never guess the time. Say how long it has run and what is
   left: "Running 32 minutes (since 14:05); it is in its last check." During a build, what is left comes from the game's
   `evidence/` folder, read and never run: no `self-check.tsv` yet means it is still building;
   `self-check.tsv` means the small check; `checklist.tsv` means the last step, checking the
   brief line by line. During a change those files are the first build's and say nothing: what
   is left is the One-shot 4 step this session is on (making it, its light check, then the
   accept question).
4. The handover's Effort line is the true one: `this session's`, `<effort> (set on the
   builder)`, or `set by CLAUDE_CODE_EFFORT_LEVEL`. Never a level nobody set.
5. The report (section 6) is the handover's material: a builder's comes back to this session,
   and built here, the lines go straight on the card. Check that
   `prototypes/<name>/evidence/check-run.yaml` is there; without it, the handover says "Not
   checked: the build recorded no check". Go on to One-shot 3.

## 2. The rules

You are building one browser game from its brief. Four hard rules:

1. **No emoji art.** Every figure, prop, tile, icon and HUD piece is drawn in code in the
   brief's Look, never an emoji or a font symbol (unless the brief asks for emoji by name),
   never a plain rectangle or circle standing in for a figure. Every enemy kind and unit has
   its own silhouette, never one shape recoloured or resized.
2. **No copying a game.** A named game and the genre's best games give values (a timing, a
   range, a count, what makes a moment work), never one game's signature: its mechanic as that
   game does it, its scene, screen layout, figures, names or minigame. A new name or an
   "original" label does not change this rule. Before building the hook, write one line to
   `evidence/nearest-game.txt`: "Nearest game: <name>; this one differs in <what>". Nothing to
   say there is a copy: change the hook's form first.
3. **Keep the brief's words.** Every look, view and reference word in In your words ("2.5D",
   "flat vector", "like Manor Lords") is built as named and listed in
   `evidence/brief-words.tsv` (section 5). One you cannot build is a miss with its reason, never
   a silent swap.
4. **Playable and not trivially easy.** It boots and plays from the start to a win or a loss,
   and the brief's Challenge is built, with its numbers from the genre's starting values.

And how to build:

- **The brief is the game.** Avoid first, then In your words, then the rest of the brief. Out of
  scope stays out. Look and references, First minute and Challenge are built as they read.
- **Always a game, never a plan.** Build it and run it yourself. A game you could not run is
  never reported as done: the report says so by name.
- **Every tuning value goes in `config.js`** from the first line of code, with `value`, `min`,
  `max` and `step`, read through `tune.<name>` each time it is needed: the sliders and the Keep
  check read them. Game logic runs on the step, never on a timer or the real clock.
- **Keep the starter's check hooks:** the fixed step, the clock hook, `window.game` (`scene`,
  `state`, `press`, `hold`, `step`) and the scene names `play` and `figures`: the small check
  plays through them.
- **3D:** run `bash .claude/scripts/vendor-three.sh prototypes/<name> [add-on ...]` with a
  10-minute timeout, then follow its `mode` row (`bundled`: a `<script src="vendor/three.js">`
  above config.js; `served`: an import map, and the report gives the `serve` command). Under the
  starter's `CHEAP` (every check asks for it): no antialias, pixel ratio 0.5, no shadows, no
  post effects. Never tune the game for a slow headless shot.
- **A slow check may run in the background** while you work on something else in the same
  turn. Collect each one before your report; never end your turn waiting on one: a notice that
  never comes ends the build with nothing handed over.
- **No waste.** Every minute goes into the game. Check it with the commands in the small check,
  as written there, about 5 minutes in all; never read the scripts to learn them. Write no robot
  player, simulator, probe or test harness of your own, and play nothing headless yourself. What
  the small check cannot show, the card names as not checked, and the person's play covers it.
- **A browser the sandbox stopped:** a `not_assessed` row with "no headless shell to try" and
  `socket() failed: Operation not permitted` is Claude Code's sandbox: install the shell once,
  outside it (`npx playwright install chromium-headless-shell`), and run the step again. Refused
  or failed: go on, and the report names what could not run.

## 3. Build it

- **The slice:** Build order step 1 with the goal and the way to lose: a start, a ramp and an
  end. Thin is the common failure: one verb and nothing that builds is not done. The brief's
  Features are the parts; the genre's staples on it are built, not skipped.
- **Your systems,** when the brief has them: each `in the slice` system built for real, each
  `thin stand-in` there, working and wired to the rest at its simplest, and each `later` one
  left out like Out of scope.
- **The first minute** plays as the brief's First minute says, taught by doing.
- **The challenge** arrives when the brief's Challenge says, and ramps. Its numbers start from
  the genre's starting values in `config.js`; the person's notes after play move them, never a
  script.
- **The look:** the brief's Look and references, its view and camera as named. The `figures`
  scene draws every enemy kind and unit side by side, each with its name under it. An image the
  prompt names is a reference: it guides the build and is never copied in, except a file that a
  line in the `notes.md` beside it marks `use`, which goes into `assets/` with `origin: you`.
- **Sound** through Web Audio, when the brief gives it.
- **Two to four players on one machine,** when the brief asks: split screen, a shared view or a
  hot seat, written for this game.

## 4. Day-one screens

From the brief's Goal & fail state and its Intent line, decide: the goal, failure (hard, soft or
none), what carries over between sessions, and what a restart clears.

| Screen | Build it when |
|---|---|
| Start: the title and the controls | Always |
| Pause | The game runs in real time |
| Game over and restart | Failure is hard |
| A restart or reset, and no game over | Failure is soft or none, or *no goal to reach* |
| Results | The game has an end |
| Mute | The game makes sound |

Controls are shown on screen, with standard defaults: nothing inverted unless the brief asks.
A staged failure (the game "crashes" on purpose) recovers, and its screen says it is part of the
game.

## 5. The small check

Follow `references/one-shot-2c-self-check.md` (beside this file). A few cheap fixed checks,
about 5 minutes: it opens with no errors, one screenshot of play looked at, a few scripted keys
show it responds, the brief's words are built and nothing is drawn with emoji; one fix round,
then the brief checklist from the shots and the code. The run is this one line:
`bash .claude/scripts/one-shot-check.sh prototypes/<name> --keys "Enter ArrowRight:1.5 Space wait:1"`,
with what leaves the title and a few seconds of the game's own keys.

## 6. The report

End with these lines, for the handover:

```text
How to play: <controls>
Small check: <each of the four rows: passed, failed or not assessed, and why>
Brief checklist: <passed> of <items>; <each item that is not a pass: id, its words, missing | broken | not assessed (why)>
Fixed: <what the fix round changed>
Nearest game: <name>; this one differs in <what>
Not as you said: <a brief word missed>: <why>
Still broken: <what>
Guessed: <what you decided that the brief did not say: taste, feel, the hook's numbers>
Shot: <the play screenshot's path>
```

Leave out Fixed, Not as you said, Still broken and Guessed when they are empty.
