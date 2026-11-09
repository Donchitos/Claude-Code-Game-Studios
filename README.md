<p align="center">
  <h1 align="center">Claude Code Game Studios</h1>
  <p align="center">
    Describe a game. Claude Code asks a few questions, writes a one-page brief,
    and builds a playable browser game from it.
    <br />
    Then you change it, grow it and finish it, one step at a time.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://code.claude.com/docs"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="Built for Claude Code"></a>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20this%20project-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee"></a>
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Support%20this%20project-ea4aaa?logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

---

## Make me a game

Open Claude Code in a copy of this repository and say what you want:

```
/prototype a fishing game where the rare fish only bite at dusk
```

1. **A few questions.** One round, picked from the genre: the choices that
   shape the game, how it should feel, how it looks, how hard it is, the goal.
   Each has a usual answer, so "you pick" works. A vague idea ("a racing game")
   gets two or three one-line pitches to choose from first.
2. **A one-page brief.** `design/game-brief.md`: your words kept as you typed
   them, the look, the first minute, the challenge, the features and what is
   left for later. You read it and say Build it, or change something first.
3. **A first build.** A browser game in `prototypes/<name>/` that opens with a
   double-click: every figure drawn, no emoji art, no copy of another game, and
   not trivially easy. Your session builds it at its own effort ("build it at
   medium" is cheaper and thinner).
4. **Checked before you get it.** A few scripted key presses in a headless
   browser show it opens with no errors and responds; text that is too small,
   overlapping or off screen and screens that freeze are fixed in one round; and
   every line of the brief is marked built, missing or broken from the
   screenshots and the code, or not assessed when it could not be checked. Your
   play is the real test: the handover card says what passed, what is still broken
   and what was guessed, and ends "Not yet played by a person".

Then it is yours to play. After that:

- **Change it by asking.** Each change is checked against what you said to
  keep and to avoid, and each one you accept is a checkpoint you can go back
  to. Ask to tune it and it gains a tweak panel with a slider for every value.
- **Share it.** A clean copy without the panel and the working files, ready
  for itch.io or a link.
- **Grow it.** When you like it, it becomes a real web project (Vite and
  TypeScript, its values in data files, tests and a build), and you add to it
  one feature a sitting: say the next feature, and it is built, checked and
  committed. After every feature the same seeded run is played again and any
  change is shown to you. Stories (`/create-stories`, `/dev-story`,
  `/story-done`) only when you ask for them.
- **Finish it.** `/cut` proposes what to cut and a polish list, and a date
  when the game is to sell.

Already have a browser game? `/prototype --from <path>` brings a copy in as it
is, so it can be changed and grown the same way.

## What it has been shown to do

- **The first build.** In a blind comparison on three game ideas, the brief
  made from its questions was picked over a hand-written brief all three
  times. All six games built from the two kinds of brief were ones the tester
  said they would build on, so on the games themselves the two kinds of brief
  tied.
- **Growing.** One game was grown from its first build through six stories
  into a game the tester would keep building. That is one game, not yet a
  pattern.
- **Not yet shown:** the engine route (Godot, Unity, Unreal) and deepening one
  system with a design document. Both are built and pass the framework's own
  checks, but neither has had a test like the two above.

The games themselves are deliberately **not** shipped here: this is a template
you clone to start your own project, and somebody else's game in your repo is
clutter, not evidence.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Engines](#engines)
- [Configuration](#configuration)
- [Upgrading](#upgrading)
- [Project Structure](#project-structure)
- [Hooks, Permissions and Rules](#hooks-permissions-and-rules)
- [Studio Mode](#studio-mode)
- [Design Philosophy](#design-philosophy)
- [Customization](#customization)
- [Platform Support](#platform-support)
- [Community](#community)
- [Supporting This Project](#supporting-this-project)
- [License](#license)

---

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [Claude Code](https://code.claude.com/docs/en/setup) — the native installer is recommended (`npm install -g @anthropic-ai/claude-code` also works, on Node.js 22+)
- [Python 3](https://www.python.org/) — reads `project.yaml` for every skill and hook; without it every setting silently falls back to its default
- Bash — runs every hook; built into macOS and Linux, and on Windows it comes with [Git for Windows](https://git-scm.com/downloads/win). Without it on Windows the hooks skip themselves, and session start says their checks are off
- **Chrome, Edge or Chromium** — `/prototype` plays and screenshots each game in it; without one, those checks say they were not assessed
- **Recommended**: [Node.js](https://nodejs.org/) (to grow a game into a web project, for a 3D game's three.js, and for the web engine's build and tests) and [jq](https://jqlang.github.io/jq/) (for hook validation)

Hooks fail gracefully if optional tools are missing — you just lose validation — with one deliberate exception: a commit that stages data JSON is blocked when there is no Python to validate it.

### Setup

1. **Clone or use as template**:
   ```bash
   git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
   cd my-game
   ```

2. **Open Claude Code in the project's root folder** (the one holding
   `CLAUDE.md` and `project.yaml`) and start a session:
   ```bash
   claude
   ```
   Starting it in a subfolder such as `src/` skips the project's hooks, deny
   rules and ask-first permission mode.

3. **Type `/prototype` and your idea**, or **run `/start`**, which asks where
   you are (make me a game, an idea or none yet, clear design, existing work)
   and guides you to the right workflow. No assumptions.

   Other ways in:
   - `/next-step` — names the one next step wherever you are
   - `/brainstorm` — explore game ideas from scratch
   - `/setup-engine godot 4.7` — configure an engine if you already know you want one
   - `/project-stage-detect` — analyze an existing project

## Engines

| Engine | `engine.name` | Code root | Notes |
|--------|---------------|-----------|-------|
| **Web** | `Web` | `src/` | The default for a new project. A one-shot needs no engine at all; a grown game is a web project. `/setup-engine web` offers a starter: nothing extra, three.js, Phaser or PixiJS |
| **Godot 4** | `Godot` | `src/` | GDScript, C# or GDExtension |
| **Unity** | `Unity` | `Assets/` | Unity compiles only `Assets/` and `Packages/` |
| **Unreal Engine 5** | `Unreal` | `Source/<Module>/` | C++ and Blueprints |

`/setup-engine` pins the engine version and writes its reference docs
(`docs/engine-reference/<engine>/`). With no engine set, `/prototype` builds
in the browser first; you pick an engine after you have played the game. Each
engine's folders and default commands come from one table,
`.claude/engines/engines.tsv`. If your code or tests live somewhere else, set
`engine.code_root` or `engine.test_root` in `project.yaml`.

## Configuration

`project.yaml` at the repo root is the single source of truth for how the
studio behaves on your project — engine, naming conventions, and a `modes`
block that controls how much process every skill enforces. `/start` writes it
for you; you rarely need to hand-edit it.

The one question that matters most is **`modes.rigor`** — `minimal`, `standard`,
or `full`. It's a single front door over six separate knobs (`workflow` —
which GDD sections are required, `docs.density`, `qa.level`,
`story_granularity`, `review_mode` — how many director agents review your work,
and `team.size`), so `/start` asks it once instead of six times:

- **`minimal`** (default) — the light path. No GDDs required, terse docs, minimal QA evidence, solo review. `/prototype` (questions, a brief, a first build) → play and change it → grow it on PROCEED → one feature a sitting: name it, and it is built, checked and committed. Stories (`/create-stories` → `/dev-story` ↔ `/story-done`) only when you ask.
- **`standard`** — 5 required GDD sections, balanced doc depth, standard QA evidence, lean review.
- **`full`** — all 8 GDD sections, thorough docs, full QA evidence on every story type, full director review.

`minimal` is the default because the heavier tier costs more to reach working
code without producing a better result, and gives nothing back when someone new
picks the project up. Raise it in one `/project-settings` call when your project grows
— `/next-step` and `/gate-check` will suggest it when they see the signs.

Two escape hatches keep one setting from being a blunt instrument.
**`system_overrides`** holds a single system to a higher standard than the rest
of the project — your combat system gets the full treatment while everything
else stays light. **`testing.strict`** sets, per test type (logic, integration,
visual, UI, config), whether missing evidence blocks a story or merely warns.

Any of the six underlying knobs can still be set individually if you want a mix
(e.g. `workflow: full` with `docs.density: terse` — comprehensive but compact).
Two of them — `review_mode` (`full` / `lean` / `solo`) and `team.size` — are
also **personal**: rigor sets the team-wide default, but you can override them
per-developer in a gitignored `project.local.yaml` without touching the shared
config. `modes.automation` (how often the AI pauses to ask before it acts) sits
outside rigor and is likewise personally overridable. `project.goal` (a jam
game, a hobby, a game to sell, and so on) is what you want from the game;
`/start` guesses it, and `/cut` reads it.

View or change any setting with the `/project-settings` skill:

```
/project-settings                              # view effective config
/project-settings modes.review_mode            # view one setting
/project-settings modes.rigor=full             # write to project.yaml (team-wide)
/project-settings --local modes.review_mode=solo   # write to project.local.yaml (just you)
```

Full schema and per-setting behavior: `.claude/docs/effects-map.md`.

## Upgrading

Already using an older version of this template? See [UPGRADING.md](UPGRADING.md)
for step-by-step migration instructions, a breakdown of what changed between
versions, and which files are safe to overwrite vs. which need a manual merge.

## Project Structure

```
CLAUDE.md                           # Master configuration
project.yaml                        # Project settings: engine, modes, goal
.claude/
  settings.json                     # Hooks, permissions, safety rules
  agents/                           # 49 agent definitions (markdown + YAML frontmatter)
  skills/                           # 75 skills, plus three old names (a subdirectory each)
  hooks/                            # 18 scripts (bash) — 15 event hooks, two helpers they
                                    #   source (yaml-helper.sh, update-check.sh), and one
                                    #   opt-in diagnostic you wire yourself
  scripts/                          # Helper scripts the skills and hooks run; each .sh has --help
  rules/                            # 14 path-scoped coding standards
  genres/                           # Genre sheets and look guidance /prototype asks and
                                    #   builds from
  engines/                          # The engine table (engines.tsv) and the web starter
  statusline.sh                     # Status line script (context%, model, stage, epic breadcrumb)
  docs/
    workflow-catalog.yaml           # 7-phase pipeline definition (read by /next-step)
    templates/                      # 62 document templates (+ per-section guidance)
prototypes/                         # One-shots, one folder each (isolated from src/)
references/                         # Optional: images and sounds you like, for /prototype
src/                                # Game source code (Godot, Web). The code root is
                                    #   ENGINE-SPECIFIC: Unity compiles only
                                    #   Assets/, Unreal builds from Source/<Module>/
assets/                             # Art, audio, VFX, shaders, data files
design/                             # The game brief, GDDs, narrative docs, level designs
docs/                               # Technical documentation, ADRs, engine references
tests/                              # Test suites (unit, integration, performance, playtest)
tools/                              # Build and pipeline tools
production/                         # Sprint plans, milestones, release tracking
studio-tests/                       # QA for the skills and agents themselves — see below
```

### Testing your customizations

Claude Code Game Studios is a template you are meant to edit. `studio-tests/` is how
you check that an edited or newly written skill still holds up — a catalog of all
75 skills and 49 agents, per-category quality rubrics, behavioral specs, and
templates for writing specs of your own.

```
/skill-test static [name]     # structural linter — 7 compliance checks
/skill-test category [name]   # category-specific quality rubric
/skill-test spec [name]       # behavioral spec assertions
/skill-test audit             # coverage report across skills and agents
/skill-improve [name]         # test-fix-retest loop; keeps or reverts on score change
```

It tests the *framework*, never your game — game tests live in `tests/`.

## Hooks, Permissions and Rules

**Hooks** run automatically on every session:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | Checks for hardcoded values, TODO format, JSON validity, design doc sections — exits early if the command is not `git commit` |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | Warns on pushes to protected branches, and on `git tag`, `git merge`, `gh release`, `butler push` and `steamcmd +run_app_build` — exits early for any other command |
| `validate-read.sh` | PreToolUse (Read) | Refuses a whole-file read of a design doc over 40 KB and answers with its headings, so the retry reads one section (`features.read_guard`) |
| `validate-write.sh` | PreToolUse (Write/Edit) | Warns, never blocks, when a write would break a rule the skills state: a file they never overwrite, the config guard, the prototype boundary, a localization freeze |
| `validate-registry.sh` | PreToolUse (Write/Edit) | Warns when a write to the entity or TR-ID registry would delete or renumber an entry, or set a status its header does not list |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Checks data-file JSON under `assets/`, `Assets/` or `Content/`, and asset naming in Godot's `assets/` only — exits early if the file is under none of them |
| `session-start.sh` | Session open | Shows current branch and recent commits for orientation |
| `detect-gaps.sh` | Session open | Detects fresh projects (suggests `/start`) and missing design docs when code or prototypes exist |
| `pre-compact.sh` | Before compaction | Logs the compaction (its output does not reach Claude — `session-start.sh` restores context afterwards) |
| `notify.sh` | Permission prompt, or idle about a minute | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | Every response end, in the background | Archives `active.md` to session log and records git activity |
| `log-agent.sh` | Agent spawned | Audit trail start — logs subagent invocation |
| `log-agent-stop.sh` | Agent stops | Audit trail stop — completes subagent record |
| `validate-agent-artifact.sh` | Agent stops | Warns when a subagent stops without writing the file its brief named |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Advises running `/skill-test` after any `.claude/skills/` change |

> **Note**: `validate-commit.sh`, `validate-push.sh`, `validate-read.sh`, `validate-write.sh`, `validate-registry.sh`, `validate-assets.sh` and `validate-skill-change.sh` fire on every Bash, PowerShell, Read, Write or Edit tool call and exit immediately (exit 0) when the command or file path is not relevant. This is normal hook behavior — not a performance concern.

**Permission rules** in `settings.json` auto-allow test runs and the framework's read-only helper scripts, and block dangerous operations (force push, `rm -rf`, reading `.env` files) in both the Bash and PowerShell tools. Read-only commands such as `git status`, `git log` and `ls` need no rule: Claude Code runs them without asking. The `git` rules match anywhere after `git`, so a git command whose text only mentions `push` followed later by ` +` or ` -f`, `clean` followed by ` -f`, or `reset` followed by `--hard` — a commit message such as `git commit -m "push + pull"` included — is denied too: reword the message.

### Path-Scoped Rules

Coding standards are automatically enforced based on file location. The paths
below are Godot's. Each rule also matches the Unity and Unreal layouts: the code
rules match C# under `Assets/**/Gameplay/` and C++ under `Source/**/Gameplay/` (and `Core`,
`AI`, `Networking`, `UI`), data matches JSON under `Assets/**/Data/` and
`Content/**/Data/`, shaders match by file type, and tests match
C# under `Assets/Tests/` and C++ under `Source/**/Tests/`.

| Path | Enforces |
|------|----------|
| `src/gameplay/**` | Data-driven values, delta time usage, no UI references |
| `src/core/**` | Zero allocations in hot paths, thread safety, API stability |
| `src/ai/**` | Performance budgets, debuggability, data-driven parameters |
| `src/networking/**` | Server-authoritative, versioned messages, security |
| `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design/gdd/**` | Required sections per `modes.workflow`, formula format, edge cases |
| `design/narrative/**` | Lore consistency, character voice, canon levels |
| `assets/data/**/*.json` | JSON validity, naming conventions, schema rules |
| `assets/shaders/**` | Naming conventions, performance targets, cross-platform rules |
| `**/*.tscn`, `**/*.tres` | Scene and resource files changed in the editor where possible; safe hand-edit rules |
| `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototypes/**` | A one-shot's tuning values in `config.js` and seeded randomness; relaxed standards for engine and paper prototypes |

## Studio Mode

Everything above is the light path: one brief, a game you play, one feature a
sitting as it grows. For a team, a long project, or a person who wants the paperwork, the
same project also has **studio mode**: 49 specialized agents in a studio
hierarchy, a design document per system, architecture decisions, epics and
sprints, phase gates, and `team-*` pipelines that coordinate several agents on
one feature. `/next-step` suggests it once when a grown game gets big (about
nine stories or features).

### What's Included

| Category | Count | Description |
|----------|-------|-------------|
| **Agents** | 49 | Specialized subagents across design, programming, art, audio, narrative, QA, and production |
| **Skills** | 75 | Slash commands for every workflow phase (`/prototype`, `/start`, `/design-system`, `/create-epics`, `/create-stories`, `/dev-story`, `/story-done`, etc.) |
| **Hooks** | 15 | Automated validation on commits, pushes, asset changes, design-doc reads, writes and registries, session lifecycle, agent audit trail, and gap detection |
| **Rules** | 14 | Path-scoped coding standards enforced when editing gameplay, engine, AI, UI, network code, scene and asset files, and more |
| **Templates** | 62 | Document templates for GDDs, UX specs, ADRs, sprint plans, HUD design, accessibility, and more |

### Studio Hierarchy

Agents are organized into three tiers, matching how real studios operate:

```
Tier 1 — Directors
  creative-director    technical-director    producer

Tier 2 — Department Leads
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

Each agent declares a model in its frontmatter: the three directors ask for
Opus, `lead-programmer` and fifteen specialists name Sonnet, and the remaining thirty
**inherit your session's model**. Treat the tiers as seniority of role, not as
a billing plan — most of the studio runs on whatever model you are already using.

### Engine Specialists

The template includes agent sets for the three major engines. Use the set that
matches your project (a web project uses the general programmers):

| Engine | Lead Agent | Sub-Specialists |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replication, UMG/CommonUI |

### Slash Commands

Type `/` in Claude Code to access all 75 skills (plus three old names that point to their new ones):

**Make a Game**
`/prototype` `/cut`

**Onboarding & Navigation**
`/start` `/next-step` `/project-stage-detect` `/setup-engine` `/adopt` `/project-settings`

**Game Design**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**Art & Assets**
`/art-bible` `/asset-spec` `/asset-audit`

**UX & Interface Design**
`/ux-design` `/ux-review`

**Architecture**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**Stories & Sprints**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**Reviews & Analysis**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA & Testing**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**Production**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**Release**
`/release-checklist` `/launch-checklist` `/write-changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creative & Content**
`/vertical-slice` `/onboard` `/localize`

**Team Orchestration** (coordinate multiple agents on a single feature)
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

### Does studio mode produce games, or documents?

A fair question, and the answer is a measurement. Games were built from one
brief at different `modes.rigor` levels, and the documents each wrote
**before its first line of game code** were counted. The lightest and the
heaviest:

| `modes.rigor` | Docs before first line of game code | Time |
|---|---:|---:|
| `minimal` | **1** (the one-page brief) | 0 min |
| `standard` | 30 | 58 min |

All of them produced a running, tested game. Two blind reviewers and a human
playtest then ranked the `standard` build **last** — the extra 29 documents
bought traceability, not a better game. That is why the light path is the
default.

### It runs the game and looks at it

A passing test says nothing about a menu drawn off-screen, so a story that
changes anything the player sees is not closed until the game has been
launched, observed, and a screenshot retained in `production/qa/evidence/`. A
parse check is not a run. This holds at every rigor level, including
`minimal`, where automated tests are waived but the look is not.

### Agent Coordination

Agents follow a structured delegation model:

1. **Vertical delegation** — directors delegate to leads, leads delegate to specialists
2. **Horizontal consultation** — same-tier agents can consult each other but can't make binding cross-domain decisions
3. **Conflict resolution** — disagreements escalate up to the shared parent (`creative-director` for design, `technical-director` for technical)
4. **Change propagation** — cross-department changes are coordinated by `producer`
5. **Domain boundaries** — agents don't modify files outside their domain without explicit delegation

### Collaborative, Not Autonomous

This is **not** an auto-pilot system. Every agent follows a strict collaboration protocol:

1. **Ask** — agents ask questions before proposing solutions
2. **Present options** — agents show 2-4 options with pros/cons
3. **You decide** — the user always makes the call
4. **Draft** — agents show work before finalizing
5. **Approve** — nothing gets written without your sign-off

You stay in control. The agents provide structure and expertise, not autonomy.

That is how a terminal session started at the project root behaves out of the
box. The `guided` and `autonomous` automation settings, and Claude Code's own
auto mode, trade some of these prompts for speed; see
[setup-requirements.md](.claude/docs/setup-requirements.md) for the routes into
auto mode.

## Design Philosophy

This template is grounded in professional game development practices:

- **Playable first** — a game you can play before documents about it
- **MDA Framework** — Mechanics, Dynamics, Aesthetics analysis for game design
- **Self-Determination Theory** — Autonomy, Competence, Relatedness for player motivation
- **Flow State Design** — Challenge-skill balance for player engagement
- **Bartle Player Types** — Audience targeting and validation
- **Verification-Driven Development** — Tests first, then implementation

## Customization

This is a **template**, not a locked framework. Everything is meant to be customized:

- **Add/remove agents** — delete agent files you don't need, add new ones for your domains
- **Edit agent prompts** — tune agent behavior, add project-specific knowledge
- **Modify skills** — adjust workflows to match your team's process
- **Add rules** — create new path-scoped rules for your project's directory structure
- **Tune hooks** — adjust validation strictness, add new checks
- **Pick your engine** — web, Godot, Unity or Unreal (see [Engines](#engines)); use the matching agent set, or none
- **Tune process weight** — `modes.rigor` and its underlying knobs in `project.yaml` (see [Configuration](#configuration)). Override per-run with `--review solo` on any skill that runs a review gate.

## Platform Support

Primary development on **Windows 10** with Git Bash. The hooks and scripts are also tested on **macOS** — its stock bash 3.2 and BSD tools, with and without `jq` — and on **Linux**. All hooks use POSIX-compatible patterns (`grep -E`, not `grep -P`) and include fallbacks for missing tools. The `notify.sh` hook uses PowerShell for Windows toast notifications and is a no-op elsewhere — desktop notifications on macOS/Linux are not yet wired. Please file issues for any platform-specific breakage.

## Community

- **Discussions** — [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) for questions, ideas, and showcasing what you've built
- **Issues** — [Bug reports and feature requests](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

---

## Supporting This Project

Claude Code Game Studios is free and open source. If it saves you time or helps you ship your game, consider supporting continued development:

<p>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

- **[Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)** — one-time support
- **[GitHub Sponsors](https://github.com/sponsors/Donchitos)** — recurring support through GitHub

Sponsorships help fund time spent maintaining skills, adding new agents, keeping up with Claude Code and engine API changes, and responding to community issues.

---

*Built for Claude Code. Maintained and extended — contributions welcome via [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions).*

## License

MIT License. See [LICENSE](LICENSE) for details.
