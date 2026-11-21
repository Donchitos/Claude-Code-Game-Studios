---
name: start
description: "Guides a first-time user through onboarding and picks the right workflow. Use when the user is new, just cloned or installed the studio, has no idea or engine yet, asks where to begin, or wants to bring in an existing game. A request for a game itself ('make me a game where...') is /prototype's."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill, Bash(bash .claude/scripts/project-state.sh*), Bash(bash .claude/scripts/set-stage.sh *), Bash(bash .claude/scripts/config-set.sh *)
model: sonnet
---

# Guided Onboarding

The entry point for a new user. It assumes no game idea, no engine and no experience: it reads
the project, asks where the user is starting from, shows what it assumes about the project, and
names the one next step. It never runs that step itself, except for a game the person described
in their own words, which goes straight to `/prototype` (One-shot 1).

The main path leads: make a game (`/prototype`), change it after play, grow it into a project.
The design documents, the agents and the `team-*` pipelines are studio mode, the path at rigor
`standard` and `full` (Phase 6).

It writes these settings to `project.yaml`, all through helpers, and only after an explicit yes:
`project.stage` (with its legacy mirror `production/stage.txt`), `project.goal`, `modes.rigor`
and `modes.automation`. It never writes `modes.review_mode` or `production/review-mode.txt`, and none
of the other knobs rigor fronts (`modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity`, `team.size`): a written value pins that knob over the rigor expansion,
and a mirror file outranks it. The make-me-a-game route writes nothing: `/prototype`'s card is
that route's assumptions card.

Ask with the question tool. Without one, list the options numbered and end your turn to wait. The
question is the last thing in the reply: no path, note or advice after it. A skipped or dismissed
question is not an answer: ask again in plain text.

The questions in Phases 2, 4 and 5 shape the project, so they are asked in every automation mode.
The engine is not one of them: `/setup-engine` chooses it. Phase 6's last question follows a
`modes.automation` already in `project.yaml`, per `.claude/docs/automation-modes.md`; with none
set, ask it.

## Phase 1: Read the project

**A game already asked for.** When the message that started this skill asks for a game itself
("make me a game", or a description of one: "a game where you herd sheep with a dog") and the
person did not type `/start`, ask nothing and read nothing. Say in one line that you are taking
them straight to the build, then start `/prototype` with the Skill tool and no arguments: it
reads their message as their words and asks only what is missing. This is the one step this
skill runs itself, and only because it was started for them: a typed `/start` runs its turn on
this skill's own model, and the build must run on the session's (Phase 7).

**A game brought.** When that message brings a game the person already has (a path to an
`.html` file or a folder, or "bring in my game"), do the same with `/prototype --from <path>`.

Run `bash .claude/scripts/project-state.sh` and keep its rows. Do not show them yet; they check
the user's answer in Phase 2.

| Row | Use |
|---|---|
| `engine`, `code_root`, `source_files` | Is an engine set, and how much code is there. `source_files` of `unknown` means the code root could not be found: say that, never "no code" |
| `concept` | `design/gdd/game-concept.md` or `design/game-brief.md` exists |
| `gdd_files`, `adr` | Design documents and architecture decisions on disk (they set the stage in Phase 4) |
| `prototype`, `sprint`, `milestone`, `story` | Other existing work |
| `origin_url` | Contains `donchitos/claude-code-game-studios`, matched case-insensitively: the clone still points at the template repo, so a push or pull request would go there. A fork under another owner is the user's own |
| `stage` | The stage already recorded, if any |

Ignore `phase_inferred`: it guesses from file counts, and a project with code but no design
documents is not in Production. If the helper fails, say so and read the same facts by hand
(engine in `project.yaml`, the two concept files, the code root's files, `design/gdd/`).

The helper does not report rigor, automation or the goal. Read `project.yaml`, if it exists, and
note whether `modes.rigor`, `modes.automation` and `project.goal` are set: a set value is kept,
and it is neither guessed nor asked again (Phases 4 and 5).

**Returning user** (an engine is set and `concept` is present): ask nothing. Say the engine, the
concept or brief found, and the review mode: `modes.review_mode` if set, otherwise the one
`modes.rigor` implies (`minimal` → `solo`, `standard` → `lean`, `full` → `full`). Suggest `/next-step` for the next step, add the
template-remote note if it applies, and stop.

## Phase 2: Ask where the user is

Ask with the question tool: "Welcome! Where are you starting from with your game?" Options:
- `A) Make me a game (playable in your browser)`: a browser game built from a few quick answers, any
  of which can be "you pick".
- `B) An idea, or none yet`: nothing yet, or a theme, feeling or genre ("something with space",
  "a cozy farming game").
- `C) Clear concept`: the core idea and genre are known, nothing is written down yet.
- `D) Existing work`: design documents, prototypes, code or plans already exist.

With `engine.name` set to an engine other than `web`, A reads `A) Make me a game`: a throwaway
prototype of one mechanic in that engine, with a browser sketch as one option.

Wait for the answer. If it contradicts Phase 1, say what you found once and ask again: D on an
empty project ("this looks like a fresh template; would A or B fit better?"), or B with code on
disk ("I found code in `[code_root]`; did you mean D?"). D on an empty project with no game
found (Phase 3) asks first, in plain text, where their game is: a path, or drop it in this
folder; an answer with no game in it gets the A-or-B question. If no option fits, let the user
describe their situation and route from that.

## Phase 3: Route

Name the immediate next step only. The full path waits for Phase 6, after the rigor is known.

- **A, make me a game:** ask nothing more. `/prototype` asks the quick questions and shows a card
  of what it will build before it builds anything. Skip Phases 4 to 6: that card is this route's
  assumptions card, and this route writes no setting (a rigor left unset reads as `minimal`). Go
  to Phase 7 with `/prototype`.
- **B, an idea or none yet:** ask in plain text: "What's the idea, in a few words? A theme,
  feeling or genre is enough, or say none." None: `/brainstorm open`, which explores freely. A
  hint: `/brainstorm [their words]`, taken as it is. A hint, with no engine set: ask "How would
  you like to go on?" with `Build it now (Recommended)` (`/prototype [their words]`: pitches
  from the idea, then a playable browser game) / `Shape the idea first`
  (`/brainstorm [their words]`). `Build it now` goes on as route A. Describe it as "turns an idea, or none, into
  a written design the next step builds from"; how long that design is depends on the rigor, so
  leave that for Phase 6.
- **C, clear concept:** ask for the concept in one sentence (genre and core mechanic), as plain
  text. Then ask: "How would you like to proceed?" With no engine set and none named in the
  sentence, the options are `Build it now (Recommended)` (`/prototype` makes it a playable
  browser game) / `Formalize it first` (`/brainstorm [concept]` writes it down) /
  `Jump straight in` (`/setup-engine` now, write the design after). With an engine set or named:
  `Formalize it first` / `Jump straight in` / `Browser sketch first` (`/prototype --path html`, a
  throwaway in the browser; not recommended, since the game is rebuilt in the engine). The next
  step is their pick. `Build it now` goes on as route A, and so does `Browser sketch first`, with
  `/prototype --path html` as the skill to type.
- **D, existing work, a game first:** look for a game they made elsewhere: an `.html` file up to
  two folders deep, outside `prototypes/`, `.claude/`, `docs/`, `design/`, `production/`,
  `references/`, `node_modules/`, `dist/` and `build/`, whose page has a `<script>` and a
  `<canvas>`, `requestAnimationFrame` or an engine loader; or a folder holding such an
  `index.html` (Glob, then Grep). One to three found: offer each by name, plus "Something else".
  A pick ends on "Type `/prototype --from <path>` to begin: it brings a copy in exactly as it
  is." Skip Phases 4 to 6, as on route A. A folder with a `package.json` at its top is not one of
  these: it is a web project with its own build (`/setup-engine web`). A page with no script is
  not offered.
- **D, existing work:** say what Phase 1 found ("N source files under `[code_root]`, N design
  documents, engine [X / not set]"). When `gdd_files` is 1 or more and Glob finds no
  `prototypes/*/index.html`, the design is written but there is nothing to play yet:
  - No engine set, or `web`: the next step is a playable first, `/prototype` built from their
    concept doc (`/prototype design/gdd/game-concept.md`; with no concept doc, the GDD that
    describes the whole game). Say in one line: "Your design documents stay the source of truth;
    the brief `/prototype` writes is only a summary for the build."
  - An engine other than `web`: the next step stays `/project-stage-detect`. Say in one line that
    `/prototype --path html` is the fast option: a browser sketch of the core game,
    thrown away when the engine build starts.

  Otherwise: `/setup-engine` when no engine is set and there is no more than a concept; else
  `/project-stage-detect`.

Then, except on route A, say: "I'll lay out the full path in a moment."

## Phase 4: Show what you assume, then save it

Work out three values.

**Stage.** Paths B and C: `Concept`. Path D, from the Phase 1 rows:

| On disk | Stage |
|---|---|
| no engine, or nothing beyond a concept (`gdd_files` 0) | `Concept` |
| `gdd_files` 1 or more, `adr` 0 | `Systems Design` |
| `adr` 1 or more | `Technical Setup` |

**Rigor.** If `modes.rigor` is already set in `project.yaml`, keep it and say so. Otherwise infer
it from what the user said in Phases 2 and 3, using the signals in
`.claude/docs/settings-guidance.md` §3:

| The user's words mention | Rigor |
|---|---|
| open world, RPG, sim, sandbox, factions, crafting, economy, MMO, multiplayer, many systems | `full` |
| release, commercial, Steam, one clear core loop | `standard` |
| jam, weekend, prototype, first game, small, just trying | `minimal` |
| nothing above, or no idea yet | `minimal` (the default) |

A path B hint is still a description: "some kind of open-world survival sim" is `full`.

On path D, count the system GDDs: `gdd_files` less `game-concept.md` and `systems-index.md`
when they exist. About 9 or more (`.claude/docs/settings-guidance.md` §4) proposes `standard`,
with the reason "[N] system design documents; most projects this size run `standard`", unless
the words above point to `full`. A `modes.rigor` already set is still kept.

**Goal.** If `project.goal` is already set, keep it and say so. Otherwise guess it from what the
user said in Phases 2 and 3; it is never a question of its own:

| The user's words mention | Goal |
|---|---|
| a game jam, or a theme with a deadline | `jam` |
| learning, a first game, practice, a course or class | `learn` |
| a portfolio, a job, showing their work | `portfolio` |
| selling it, Steam, a price, commercial, wishlists | `sell` |
| early access | `early_access` |
| a publisher, a pitch, funding | `publisher` |
| mobile, a phone, iOS, Android, an app store | `mobile` |
| a purpose none of the rows above fits | `other` |
| fun, themselves or friends, or nothing above | `hobby` (the default) |

When two fit, a selling goal wins over the others, and `early_access` or `publisher` over `sell`.

Show the card:

```
What I'll set up
  Stage:  [stage]  ([why, from what was found or picked])
  Rigor:  [value]  ([why, in the user's words] | [N] system design documents | already set)
          minimal: short brief, coarse stories, tests optional; about 4 steps to code
          standard: studio mode; about 8 design documents before code; standard QA evidence
          full: studio mode; standard plus validation builds; evidence everywhere
  Goal:   [value]  ([why, in the user's words] | guessed | already set)
          jam, learn, hobby, portfolio, sell, early_access, publisher, mobile or other
  /project-settings changes any of these any time.
```

Then ask with the question tool: "Save these to `project.yaml` (and the stage to
`production/stage.txt`)?" Options: `Save them` / `Change something` / `Don't save`. Ask no
question about the rigor or the goal itself: the card shows them, and the user changes them there
or later with `/project-settings`.

- **Change something:** ask what to change, starting with a *guessed* goal, then show the card
  again with the new value and "you said" as its reason, and ask the save question again. A value
  changed here is saved even when it was already set.
- **Save them:** run `bash .claude/scripts/set-stage.sh "[stage]"`, then
  `bash .claude/scripts/config-set.sh modes.rigor [value]` and
  `bash .claude/scripts/config-set.sh project.goal [value]`, each only when that key was not
  already set or was changed on the card. Check the read-back rows match. Say: "Saved. Rigor
  `[value]` sets six other settings; `/project-settings` shows them and changes any of them."
- **Don't save**, or anything other than an explicit yes: write nothing, keep the values for this
  run, and say they were not saved.

If a helper exits non-zero, show its output, say which setting was not written, and go on with the
value for this run.

## Phase 5: Ask how much to confirm

If `modes.automation` is already set, say "Automation is `[value]`" and go on. Otherwise ask:
"Last one: how much should I confirm with you as we work?" Options:
- `Guided (Recommended)`: I decide small things and still stop for big ones (scope changes,
  deletions, schema changes).
- `Collaborative`: I ask before each significant step and show drafts before writing.
- `Autonomous`: I proceed and log decisions, stopping only for the always-ask categories. Fastest,
  most tokens.

Mapping: `Guided` → `guided`, `Collaborative` → `collaborative`, `Autonomous` → `autonomous`. The
pick is the consent to write it: run `bash .claude/scripts/config-set.sh modes.automation [value]`,
unless the Phase 4 save was declined (then say it was not saved).

## Phase 6: Show the path

Say: "Here's your path at rigor `[value]`. Every skill still runs at any rigor; rigor changes
what's required, not what's allowed."

Except on path D, lead with the main path, in one line: "The main path: make a game
(`/prototype`), change it after you play it (ask in plain words), then grow it into a project
with the steps below." At `standard` or `full`, add one line after the path: "This is studio
mode: the design documents, agents and `team-*` pipelines. It fits a team, a long project, or
someone who wants the paperwork."

The path starts with the step Phase 3 named. When that was `/brainstorm` (path B and C's
`Formalize it first`), list `/brainstorm` first and `/setup-engine` after it: each runs without
the other. With no engine set, `/prototype` goes between them.

**`minimal`: 4 steps to running code**
1. `/setup-engine`: choose and configure the engine (web, unless you name another)
2. `/brainstorm`: write the one-page `design/game-brief.md`
3. `/create-stories`: turn the brief's Features list into stories (no epics or sprint plan needed)
4. `/dev-story`: the first line of game code

With no engine set, `/prototype` builds the brief as a playable browser game: list it
straight after `/brainstorm`, as the recommended next step, and `/setup-engine` after it.

**`standard`** (studio mode)
- Concept: `/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/map-systems` →
  `/gate-check`. With no engine set, `/setup-engine` moves after `/prototype`: the playable
  first, the engine last
- Systems Design: `/design-system` (once per system) → `/review-all-gdds` → `/gate-check`
- Architecture: `/create-architecture` → `/architecture-decision` (once per decision) →
  `/architecture-review` → `/create-control-manifest` → `/ux-design` (accessibility and
  interaction patterns) → `/test-setup` → `/gate-check`
- Pre-Production: `/ux-design` (HUD and key screens) → `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- Production: `/dev-story`

Each `/gate-check` moves the project one stage, and only when it passes.

**`full`** (studio mode): everything in `standard`, plus `/vertical-slice` and `/playtest-report`
in Pre-Production and `/design-review` after each GDD.

**Path D with existing work** (stage `Systems Design` or later, or code on disk) gets this instead.
Print only the steps that apply, and for the brief only the one source that applies. When Phase 3
named `/prototype` from their design documents, list it first, before the numbered steps; with an
engine other than `web`, add `/prototype --path html` after step 1 as the fast option. At
`minimal`:
1. `/project-stage-detect`: what stage the project is at and what is missing
2. `/adopt`: whether the existing files are in the format the skills read
3. `/setup-engine`: only when no engine is set; leave it out when `engine` names one
4. The brief, only if `concept` is absent: `/reverse-document design [code_root]` when the code
   root holds 10 or more source files (it writes the brief from the game), and then do not mention
   `/brainstorm` at all; `/brainstorm` only when it holds fewer

At `standard` and `full`, steps 1 to 3, then `/design-system retrofit [path]`,
`/architecture-decision retrofit [path]`, `/architecture-review` and `/gate-check`.

Present `minimal` as the documented floor, not a lesser mode, and name its trade once: no GDDs, so
design problems show up in code.

If `origin_url` pointed at the template repo, add: "Your clone's `origin` still points at the
Claude Code Game Studios template repo, so a push or pull request would go there. When you're ready, run
`git remote rename origin template`, then `git remote add origin <your repo URL>`. `UPGRADING.md`
pulls updates from `template`; skip its own `git remote add template` step, since that remote now
exists." Suggest it; do not run it.

Ask: "Would you like to start with [first step]?" Options: `Yes, start with [first step]` /
`Something else first`. Either answer leads to Phase 7, never to running the step.

## Phase 7: Hand off

Respond with exactly one line: "Type `[skill]` to begin." Do not start that skill yourself,
even after a yes: the user types it, so it runs on the session's model and not this skill's. If
they picked something else, name the skill for that instead, the same way. On route A the line
is "Type `/prototype` to begin." and `/prototype` reads the person's answers from this
conversation; after `Browser sketch first` it is "Type `/prototype --path html` to begin."

Verdict: **COMPLETE**, the user is oriented and handed off. A game already asked for (Phase 1)
gives no verdict: `/prototype` takes over. If the user stopped before Phase 7, say which settings
were saved and which were not.
