<p align="center">
  <h1 align="center">Game Studios</h1>
  <p align="center">
    Turn a single coding session into a full game development studio.
    <br />
    49 agents. 74 workflows. Claude Code and OpenCode. Any tool-capable model.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 Agents"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/workflows-74-green" alt="74 Workflows"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-15-orange" alt="15 Hooks"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-14-red" alt="14 Rules"></a>
  <a href="https://code.claude.com/docs"><img src="https://img.shields.io/badge/Claude%20Code-supported-f5f5f5" alt="Claude Code"></a>
  <a href="https://opencode.ai/v2/docs/"><img src="https://img.shields.io/badge/OpenCode-supported-111111" alt="OpenCode"></a>
</p>

---

## Why This Exists

Building a game solo with AI is powerful — but a single chat session has no
structure. No one stops you from hardcoding magic numbers, skipping design docs,
or writing spaghetti code. There's no QA pass, no design review, no one asking
"does this actually fit the game's vision?"

**Game Studios** gives your AI session the structure of a real studio: directors
who guard the vision, department leads who own their domains, and specialists who
do the hands-on work. Each agent has defined responsibilities, escalation paths,
and quality gates.

The result: you still make every decision, but now you have a team that asks the
right questions, catches mistakes early, and keeps your project organized from
first brainstorm to launch.

## Two Harnesses, One Studio

The repository is **dual-harness**. The canonical studio lives in `.claude/`;
OpenCode gets a generated adapter in `.opencode/`.

| | Claude Code | OpenCode |
|---|---|---|
| Entry point | `CLAUDE.md` | `AGENTS.md` |
| Agents | `.claude/agents/` | `.opencode/agents/` |
| Workflows | `/skills` | `.opencode/commands/` + `.opencode/skills/` |
| Hooks | `.claude/settings.json` → `.claude/hooks/` | `.opencode/plugins/ccgs/` → `.claude/hooks/` |
| Rules | native path-scoped rules | plugin injection from `.claude/rules/` |
| Models | Claude tiers (optional) | any tool-capable model, no pins |

Edit `.claude/`, then run `python3 tools/sync-opencode.py`. CI fails if the
adapter is stale. See [`.opencode/docs/sync-and-maintenance.md`](.opencode/docs/sync-and-maintenance.md).

## What's Included

| Category | Count | Description |
|----------|-------|-------------|
| **Agents** | 49 | Specialized subagents across design, programming, art, audio, narrative, QA, and production |
| **Workflows** | 74 | Slash commands for every phase (`/start`, `/design-system`, `/create-epics`, `/dev-story`, `/story-done`, ...) |
| **Hooks** | 15 | Validation on commits, pushes, reads, writes, registries, assets, and session lifecycle |
| **Rules** | 14 | Path-scoped coding standards for gameplay, engine, AI, UI, network, data, shaders, tests, and scenes |
| **Templates** | 62 | GDD, UX, ADR, sprint, HUD, accessibility, and other document templates |

## Studio Hierarchy

Agents are organized into three tiers:

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

Each agent declares a model in the Claude layer or inherits the session model.
The **OpenCode adapter removes every model pin**, so all agents and commands
inherit whatever model is selected in OpenCode. This is what makes the template
usable with local open-weight models.

### Engine Specialists

| Engine | Lead Agent | Sub-Specialists |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replication, UMG/CommonUI |

## Slash Commands

Type `/` in either harness to access the 74 workflows:

**Onboarding & Navigation** — `/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt` `/settings`

**Game Design** — `/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**Art & Assets** — `/art-bible` `/asset-spec` `/asset-audit`

**UX & Interface** — `/ux-design` `/ux-review`

**Architecture** — `/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**Stories & Sprints** — `/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**Reviews & Analysis** — `/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA & Testing** — `/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**Production** — `/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**Release** — `/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creative & Content** — `/prototype` `/vertical-slice` `/onboard` `/localize`

**Team Orchestration** — `/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## Does It Produce Games, or Documents?

A fair question. The upstream project measured four games built from one brief at
different `modes.rigor` levels:

| `modes.rigor` | Docs before first line of game code | Time |
|---|---:|---:|
| `minimal` | **1** (the one-page brief) | 0 min |
| `standard` | 30 | 58 min |

All produced a running, tested game. The extra documents bought traceability, not
a better game. `minimal` is the default for that reason; raise it when the project
grows.

### It runs the game and looks at it

A passing test says nothing about a menu drawn off-screen. A story that changes
anything the player sees is not closed until the game has been launched,
observed, and a screenshot retained in `production/qa/evidence/`. A parse check
is not a run. This holds at every rigor level, including `minimal`, where
automated tests are waived but the look is not.

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- Python 3 — reads `project.yaml`; every skill and hook uses it
- Bash — runs the shared hooks (macOS, Linux, or Git Bash on Windows)
- **Recommended**: `jq` for hook JSON parsing

Pick one harness:

- [Claude Code](https://code.claude.com/docs/en/setup) — the native installer or
  `npm install -g @anthropic-ai/claude-code`
- [OpenCode V2](https://opencode.ai/v2/docs/) — the native installer or
  `npm install -g @opencode/cli`

### OpenCode setup

1. Clone or use this repository as a template.
2. Open a terminal at the repository root — the folder holding `AGENTS.md`,
   `opencode.jsonc`, and `project.yaml`.
3. Start OpenCode and connect a provider:

   ```bash
   opencode
   ```

   Use `/connect` and `/models` before your first prompt. The studio does not
   pin a model; with none selected, OpenCode falls back to a catalog default
   that may not be available in your account. See
   [`.opencode/docs/model-selection.md`](.opencode/docs/model-selection.md).

4. Run `/start`.

### Claude Code setup

1. Open Claude Code at the repository root.
2. Run `/start`.

Starting in a subfolder such as `src/` skips the project's hooks and deny rules.

### What `/start` asks

The system asks where you are (no idea, vague concept, clear design, existing
work) and guides you to the right workflow. It never runs the next step for you.

Or jump directly to a specific workflow:

- `/brainstorm` — explore game ideas from scratch
- `/setup-engine godot 4.7` — configure your engine
- `/project-stage-detect` — analyze an existing project

## Open Models

The OpenCode layer is designed for open-weight and local models:

- **No model pins.** Every agent and command inherits the session model.
- **Tool calling is required** for editing workflows. A text-only model can plan,
  but it cannot run `/dev-story`.
- **64k context recommended**, 32k practical minimum for the larger workflows.
- Local provider examples for Ollama, LM Studio, vLLM, and any OpenAI-compatible
  server are in [`.opencode/docs/model-selection.md`](.opencode/docs/model-selection.md).
- Role-based overrides are possible, but optional; see the same document.

## Configuration

`project.yaml` at the repo root is the single source of truth for how the studio
behaves on your project — engine, naming conventions, and a `modes` block that
controls how much process every skill enforces. `/start` writes it for you.

The one question that matters most is **`modes.rigor`** — `minimal`, `standard`,
or `full`. It is a single front door over six knobs (`workflow`, `docs.density`,
`qa.level`, `story_granularity`, `review_mode`, and `team.size`):

- **`minimal`** (default) — jam-game speed. No GDDs required, terse docs, minimal
  QA evidence, solo review. `/start` → `/setup-engine` → `/brainstorm` (a
  one-page brief) → `/create-stories` → `/dev-story` ↔ `/story-done`.
- **`standard`** — 5 required GDD sections, balanced doc depth, standard QA
  evidence, lean review.
- **`full`** — all 8 GDD sections, thorough docs, full QA evidence, full director
  review.

Use `/settings` to view or change any setting:

```
/settings                              # view effective config
/settings modes.review_mode            # view one setting
/settings modes.rigor=full             # write to project.yaml (team-wide)
/settings --local modes.review_mode=solo   # write to project.local.yaml (just you)
```

Full schema and per-setting behavior: [`.claude/docs/effects-map.md`](.claude/docs/effects-map.md).

### OpenCode configuration

`opencode.jsonc` controls the OpenCode adapter:

- `default_agent: studio`
- `experimental.subagent_depth: 3` — the director → lead → specialist chain
- `experimental.todo: true` — a task list for multi-step workflows
- `permissions` — ask-first shell, dangerous-command denies, `.env` and asset
  binary protection
- `instructions` — the OpenCode coordination, coding, and directory docs

Do not add a root `model` unless you want to pin the default. See
[`.opencode/docs/opencode-setup.md`](.opencode/docs/opencode-setup.md) and
[`.opencode/docs/permissions.md`](.opencode/docs/permissions.md).

## How It Works

### Agent Coordination

1. **Vertical delegation** — directors delegate to leads, leads to specialists.
2. **Horizontal consultation** — same-tier agents can consult but not make
   binding cross-domain decisions.
3. **Conflict resolution** — escalate to the shared parent (`creative-director`
   for design, `technical-director` for technical).
4. **Change propagation** — cross-department changes are coordinated by `producer`.
5. **Domain boundaries** — agents don't modify files outside their domain without
   explicit delegation.

### Collaborative, Not Autonomous

Every agent follows a strict collaboration protocol:

1. **Ask** — ask questions before proposing solutions
2. **Present options** — show 2–4 options with pros/cons
3. **You decide** — the user always makes the call
4. **Draft** — show work before finalizing
5. **Approve** — nothing gets written without your sign-off

In OpenCode, structured choices use the `question` tool. Subagents return options
to their caller; the caller puts them to you.

### Automated Safety

The same hook scripts run in both harnesses:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `validate-commit.sh` | before shell / Bash | Hardcoded values, TODO format, JSON validity, design-doc sections |
| `validate-push.sh` | before shell / Bash | Protected branches, tags, merges, releases, store uploads |
| `validate-read.sh` | before read | Refuses a whole-file read of a design doc over 40 KB and returns headings |
| `validate-write.sh` | before write/edit | Warns when a write would break a file, config, prototype, or localization rule |
| `validate-registry.sh` | before write/edit | Warns when an entity or TR-ID registry edit deletes or renumbers an entry |
| `validate-assets.sh` | after write/edit | Data JSON validity and asset naming |
| `validate-skill-change.sh` | after write/edit | Advises running `/skill-test` after a skill change |
| `session-start.sh` | session open, after compaction | Branch, commits, review mode, stage, active sprint, bugs, session state |
| `detect-gaps.sh` | session open | Fresh-project and missing-doc detection |
| `pre-compact.sh` | before compaction | Logs compaction |
| `session-stop.sh` | response end / idle | Archives session state and git activity |
| `notify.sh` | permission prompt / idle | Desktop notification (Claude Code; not ported to OpenCode) |
| `log-agent*.sh` | subagent start/stop | Agent audit trail (Claude Code; not ported to OpenCode) |
| `validate-agent-artifact.sh` | subagent stop | Warns when a named artifact is missing (Claude Code) |

OpenCode mapping and gaps: [`.opencode/docs/hooks-reference.md`](.opencode/docs/hooks-reference.md).

### Path-Scoped Rules

Rules in `.claude/rules/` are enforced by path in Claude Code. In OpenCode, the
adapter injects the matching rule when an agent first reads or edits a file under
that path. See [`.opencode/docs/rules-reference.md`](.opencode/docs/rules-reference.md).

## Project Structure

```
CLAUDE.md                           # Claude Code master configuration
AGENTS.md                           # OpenCode master configuration
opencode.jsonc                      # OpenCode config: agent, permissions, plugin, instructions
project.yaml                        # Project config (source of truth for both harnesses)
.claude/                            # Canonical studio layer + shared core
  agents/                           # 49 agent definitions
  skills/                           # 74 workflows (subdirectory per skill)
  hooks/ scripts/                   # 18 hook scripts + 34 helpers
  rules/                            # 14 path-scoped coding standards
  docs/                             # 130 docs and templates
.opencode/                          # Generated OpenCode adapter
  agents/                           # 49 subagents + studio primary agent
  skills/                           # 74 generated skills
  commands/                         # 74 slash commands
  plugins/ccgs/                     # Hook adapter and rule injection
  docs/                             # OpenCode-specific guidance
tools/                              # Build/pipeline tools + OpenCode generator and validator
src/                                # Game source (Godot). Engine-specific; see docs
assets/                             # Art, audio, VFX, shaders, data files
design/                             # GDDs, narrative, level designs
docs/                               # Technical documentation and ADRs
tests/                              # Unit, integration, performance, playtest
prototypes/                         # Throwaway prototypes (isolated from src/)
production/                         # Sprint plans, milestones, release tracking
studio-tests/                       # QA for the skills and agents themselves
```

## Testing Your Customizations

`studio-tests/` checks that an edited or newly written skill still holds up — a
catalog, per-category rubrics, behavioral specs, and templates.

```
/skill-test static [name]     # structural linter
/skill-test category [name]   # category-specific quality rubric
/skill-test spec [name]       # behavioral spec assertions
/skill-test audit             # coverage report
/skill-improve [name]         # test-fix-retest loop
```

For the OpenCode adapter:

```bash
python3 tools/sync-opencode.py --check
python3 tools/validate-opencode.py
```

## Customization

This is a **template**, not a locked framework:

- **Add/remove agents** — edit `.claude/agents/`, regenerate, test both harnesses
- **Edit agent prompts** — tune behavior and add project-specific knowledge
- **Modify workflows** — edit `.claude/skills/`, regenerate
- **Add rules** — create `.claude/rules/<name>.md` with `paths:` frontmatter
- **Tune hooks** — edit the canonical script and wire the OpenCode mapping
- **Pick your engine** — use the Godot, Unity, or Unreal set, and disable the rest
- **Tune process weight** — `modes.rigor` and its underlying knobs in `project.yaml`

## Platform Support

Primary development is on Linux and Windows (Git Bash). The hooks and scripts are
also tested on macOS — stock bash 3.2 and BSD tools, with and without `jq`. All
hooks use POSIX-compatible patterns (`grep -E`, not `grep -P`) and fall back when
optional tools are missing. `notify.sh` uses PowerShell for Windows toasts and is
a no-op elsewhere.

## Community

- **Discussions** — [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions)
- **Issues** — [Bug reports and feature requests](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

## Supporting This Project

The upstream project is free and open source. If it saves you time, consider
supporting continued development:

- [Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)
- [GitHub Sponsors](https://github.com/sponsors/Donchitos)

## License

MIT License. See [LICENSE](LICENSE) for details.
