---
name: prototype
description: "Asks a few questions, writes a one-page brief, builds a playable browser game as one HTML folder it plays and screenshots; with an engine set, a throwaway engine or paper prototype. Ends on proceed, pivot or kill. Use when the user says make me a game, wants to try a game idea or mechanic, needs a quick spike, asks to change a game it made, or says they love or hate it."
argument-hint: "[what to make] [--from <your game>] [--path html|engine|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/one-shot-new.sh *), Bash(bash .claude/scripts/page-shot.sh *), Bash(bash .claude/scripts/vendor-three.sh *), Bash(bash .claude/scripts/one-shot-check.sh *), Bash(bash .claude/scripts/one-shot-run.sh *), Bash(bash .claude/scripts/one-shot-tune.sh *), Bash(bash .claude/scripts/one-shot-share.sh *), Bash(bash .claude/scripts/references-save.sh *), Bash(bash .claude/scripts/one-shot-grow.sh *), Bash(bash .claude/scripts/door-in.sh *), Bash(bash .claude/scripts/test-run.sh web*), Bash(npm ci), Bash(npm install --save-exact *), Bash(npm run *), Bash(npm test), Bash(git rev-parse *), Bash(git init), Bash(git add prototypes/*), Bash(git add -- *), Bash(git rm src/*), Bash(git tag grown/*), Bash(git tag baseline/*), Bash(git commit -m *), Bash(git tag one-shot/*), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git restore --source *), Bash(printenv CLAUDE_CODE_EFFORT_LEVEL)
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Prototype

## Purpose

Two kinds of build, chosen by the project's engine:

- **The one-shot:** one round of questions from the genre's sheet, a good brief from the
  answers, then a playable game in the browser built from that brief alone, run and looked at
  before it is handed over. It leaves behind what the next hour builds on: the brief,
  `config.js` with every tuning value, and a git tag.
- **The engine or paper prototype:** a throwaway build that answers one question.

Every route ends on PROCEED, PIVOT or KILL, or NOT ASSESSED when nobody has played the build.

Ask with the question tool. Without one, list the options numbered and end your turn to wait. The
question is the last thing in the reply: nothing after it. A skipped or dismissed question is
not an answer: ask again in plain text. Every ask follows
`.claude/docs/automation-modes.md` (collaborative asks always · guided major-only · autonomous
logs and proceeds; `automation_always_ask` categories always prompt).

## Choose the route

Read `engine.name` from `project.yaml`. Absent, empty or `[TO BE CONFIGURED]` is not set; with
no `project.yaml` engine, read the engine line in `CLAUDE.md` the same way.

| What is set | Route |
|---|---|
| `--spike` typed after the skill name, or a quick test picked at the questions | Spike Mode |
| `--from <path>`, or a game the person already has | One-shot 0, then the one-shot from its handover |
| `--path engine` or `--path paper` | Phases 1-9 |
| `--path html`, no engine, or `engine.name: Web` | The one-shot: One-shot 1 to 3 |
| An engine named | Phases 1-9; Phase 3 offers the browser sketch as one option, not recommended. Chosen, it goes on at One-shot 1 with Phase 1's question |

**No engine set when the skill starts: the browser game comes first,** built and handed over
whatever is asked at the card. A wish for an engine (one installed, netcode to prove, the engine
to ship on) is one card line, as the card file says, and `/setup-engine` is the handover's next
step. Never run `/setup-engine` inside a one-shot; only `--path engine` skips the browser game.

Ask no question to choose the route.

## One-shot 0: Bring it in

**For a game the person already has, read `references/one-shot-0-door.md` and follow it:** a
copy comes in exactly as it is, tagged, and is played and screenshotted untouched.

## One-shot 1: The questions and the brief

**Read `references/one-shot-1-card.md` and `.claude/genres/chipsets.yaml` now, and follow the
card file.** The brief it writes has the shape of `.claude/docs/templates/game-brief.md`.

## One-shot 2: The build

**Read `references/one-shot-2-build.md` and `references/one-shot-2c-self-check.md` now, and
follow the build file:** this session builds the game itself, and starts a builder only for an
effort the person picked. Read them again if the conversation was compacted or resumed during
the build.

## One-shot 3: Hand over

**Read `references/one-shot-3-handover.md` now and follow it,** to the end: the card, the commit,
then the play and the verdict. A one-shot writes no report and reads no Phase 6-9 file: the card
and the commits are its record. The one exception is the engine route's browser sketch, which
`references/3-choose-path.md` sends on to Phases 6-9.

## One-shot 4: Change it

**When the person asks for a change after the handover, read `references/one-shot-4-change.md`
and follow it,** for each change, during the debrief or after it, with
`references/one-shot-files.md` (the game's folder and the tweak panel it can add).
A request to share or export the game follows the same file's Share it section.

## One-shot 5: Grow it

**On Keep going after play (One-shot 3, section 3), read `references/one-shot-5-grow.md` and
follow it:** one question, keep iterating or grow it into a web project at the project root.
With that file not there, growing is switched off: say they can ask for a change any time.
"Grow it" at any point after play (the change loop's line, or `/next-step`) asks the verdict
first when it has not been given; on Keep going, One-shot 5 asks its one question. After the grow, each feature or change the person asks for follows that file's section 9: one feature a sitting.

---

Phases 1-9 are the engine and paper route.

## Phase 1: Define the Question

**Read `references/1-question.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Load Concept Context

**Read `references/2-load-context.md` now and follow it** (its fallback is `.claude/docs/technical-preferences.md`) — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Choose the Prototype Path

**Read `references/3-choose-path.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Plan the Prototype

**Read `references/4-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Implement

**Read `references/5-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Playtest Debrief

**Read `references/6-debrief.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Generate Prototype Report

**Read `references/7-report.md` and `.claude/docs/templates/prototype-report.md` now, and follow the first** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Creative Director Review

**Read `references/8-cd-review.md` now and follow it** (the gates are in `.claude/docs/director-gates.md`) — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 9: Summary and Next Steps

**Read `references/9-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Spike Mode

**Triggered by:** `--spike` typed after the skill name, or "Mid-production spike" chosen in Phase 1.

**Read `references/spike-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Important Constraints

**Every route:**

- Prototype code never imports from production source files, and production code never imports
  from `prototypes/`.
- **3 PIVOT verdicts on the same concept force a KILL decision.** Ask: "Is this the right idea,
  or am I in the sunk cost trap?" A new concept prototyped fresh usually beats a fourth
  iteration of a struggling one.
- Building 2-3 different concept variants and keeping the best beats iterating one concept to
  death.
- **Networked or multiplayer games:** a local build cannot validate how a networked mechanic
  feels. Latency changes how combat, movement and prediction feel. Use a local build to learn
  whether the mechanic is *interesting*, never as evidence that it *feels good* under real
  network conditions; that needs real peers or simulated latency.

**Engine and paper route only:**

- Total effort is capped at 1 day: a concept prototype tests one mechanic. If scope grows, stop
  and simplify the question.
- No polish: no menus, no game over, no music, no UI unless it is the mechanic.
- If stuck after 2 hours of engine iteration, reframe the question or switch paths.
- On PROCEED, production code is written from scratch; the prototype's code is never refactored
  into production. (A one-shot instead may grow into the project, on PROCEED's grow question.)
