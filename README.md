<p align="center">
  <h1 align="center">Claude Code Game Studios</h1>
  <p align="center">
    Turn a single Claude Code session into a full game development studio.
    <br />
    49 agents. 74 skills. One coordinated AI team.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 Agents"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-74-green" alt="74 Skills"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-17-orange" alt="17 Hooks"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-11-red" alt="11 Rules"></a>
  <a href="https://code.claude.com/docs/en/overview"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="Built for Claude Code"></a>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20this%20project-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee"></a>
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Support%20this%20project-ea4aaa?logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

---

## Why This Exists

Building a game solo with AI is powerful — but a single chat session has no structure. No one stops you from hardcoding magic numbers, skipping design docs, or writing spaghetti code. There's no QA pass, no design review, no one asking "does this actually fit the game's vision?"

**Claude Code Game Studios** solves this by giving your AI session the structure of a real studio. Instead of one general-purpose assistant, you get 49 specialized agents organized into a studio hierarchy — directors who guard the vision, department leads who own their domains, and specialists who do the hands-on work. Each agent has defined responsibilities, escalation paths, and quality gates.

The result: you still make every decision, but now you have a team that asks the right questions, catches mistakes early, and keeps your project organized from first brainstorm to launch.

---

## Table of Contents

- [What's Included](#whats-included)
- [Studio Hierarchy](#studio-hierarchy)
- [Slash Commands](#slash-commands)
- [Getting Started](#getting-started)
- [Upgrading](#upgrading)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Design Philosophy](#design-philosophy)
- [Customization](#customization)
- [Platform Support](#platform-support)
- [Community](#community)
- [Supporting This Project](#supporting-this-project)
- [License](#license)

---

## What's Included

| Category | Count | Description |
|----------|-------|-------------|
| **Agents** | 49 | Specialized subagents across design, programming, art, audio, narrative, QA, and production |
| **Skills** | 74 | Slash commands for every workflow phase (`/start`, `/design-system`, `/create-epics`, `/create-stories`, `/dev-story`, `/story-done`, etc.) |
| **Hooks** | 17 | Automated validation on commits, pushes, asset changes, session lifecycle, agent audit trail, gap detection, tool failures, permission denials, and design drift |
| **Rules** | 11 | Path-scoped coding standards enforced when editing gameplay, engine, AI, UI, network code, and more |
| **Templates** | 40 | Document templates for GDDs, UX specs, ADRs, sprint plans, HUD design, accessibility, and more |

## Studio Hierarchy

Agents are organized into three tiers, matching how real studios operate:

```
Tier 1 — Directors (Opus)
  creative-director    technical-director    producer

Tier 2 — Department Leads (Sonnet)
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists (Sonnet/Haiku)
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

### Engine Specialists

The template includes agent sets for all three major engines. Use the set that matches your project:

| Engine | Lead Agent | Sub-Specialists |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replication, UMG/CommonUI |

## Slash Commands

Type `/` in Claude Code to access all 74 skills:

**Onboarding & Navigation**
`/start` `/help` `/studio-init` `/project-stage-detect` `/setup-engine` `/adopt`

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
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creative & Content**
`/prototype` `/onboard` `/localize`

**Team Orchestration** (coordinate multiple agents on a single feature)
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [Claude Code](https://code.claude.com/docs/en/overview) — install with `curl -fsSL https://claude.ai/install.sh | bash`
  (macOS/Linux/WSL), `irm https://claude.ai/install.ps1 | iex` (Windows PowerShell), or `brew install --cask claude-code`
- **Recommended**: [jq](https://jqlang.github.io/jq/) (for hook validation) and Python 3 (for JSON validation)

All hooks fail gracefully if optional tools are missing — nothing breaks, you just lose validation.

### Setup

There are two ways to install. They give you the same studio; they differ in how
upgrades work.

#### Option A — Plugin (recommended)

The agents, skills, and hooks install as a Claude Code plugin and update in place.
Nothing to merge, ever.

```bash
claude
```
```
/plugin marketplace add Donchitos/Claude-Code-Game-Studios
/plugin install claude-code-game-studios@ccgs
/studio-init
```

`/studio-init` scaffolds the project side — `CLAUDE.md`, path-scoped rules, document
templates, engine reference docs, permissions, and the directory tree — into your repo.
Those files are then **yours**: edit them freely. Later, `/plugin update
claude-code-game-studios` refreshes the studio without touching a line of your work.

#### Option B — Clone the template

Best if you want to fork the studio itself and edit agents or skills directly.

```bash
git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
cd my-game
claude
```

Everything is already in place — `/studio-init` detects this and does nothing.
Upgrades come via `git merge` (see [UPGRADING.md](UPGRADING.md)), which means resolving
conflicts in files you have edited. That's the cost this option carries and Option A doesn't.

> **Do not use both.** If you clone the template *and* install the plugin, every hook is
> registered twice: two session banners, duplicated audit-log lines, and `active.md`
> archived twice per session. Pick one. If you install the plugin into an existing clone,
> delete the `hooks` block from your `.claude/settings.json` — the plugin supplies it.

#### Then start work

**Run `/start`** — the system asks where you are (no idea, vague concept, clear design,
existing work) and guides you to the right workflow. No assumptions.

Or jump directly to a specific skill if you already know what you need:
- `/brainstorm` — explore game ideas from scratch
- `/setup-engine godot 4.7` — configure your engine if you already know
- `/project-stage-detect` — analyze an existing project

## Upgrading

Already using an older version of this template? See [UPGRADING.md](UPGRADING.md)
for step-by-step migration instructions, a breakdown of what changed between
versions, and which files are safe to overwrite vs. which need a manual merge.

## Project Structure

```
CLAUDE.md                           # Master configuration
.claude-plugin/
  plugin.json                       # Plugin manifest (agents, skills, hooks)
  marketplace.json                  # Marketplace listing for /plugin marketplace add
.claude/
  settings.json                     # Hooks, permissions, safety rules (clone mode)
  agents/                           # 49 agent definitions (markdown + YAML frontmatter)
  skills/                           # 74 slash commands (subdirectory per skill)
  hooks/                            # 17 hook scripts (bash, cross-platform)
    hooks.json                      # Same hooks, plugin-root paths (plugin mode)
  rules/                            # 11 path-scoped coding standards
  statusline.sh                     # Status line script (context%, model, stage, epic breadcrumb)
  docs/
    workflow-catalog.yaml           # 7-phase pipeline definition (read by /help)
    templates/                      # 40 document templates
src/                                # Game source code
assets/                             # Art, audio, VFX, shaders, data files
design/                             # GDDs, narrative docs, level designs
docs/                               # Technical documentation and ADRs
tests/                              # Test suites (unit, integration, performance, playtest)
tools/                              # Build and pipeline tools
prototypes/                         # Throwaway prototypes (isolated from src/)
production/                         # Sprint plans, milestones, release tracking
```

## How It Works

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

### Automated Safety

**Hooks** run automatically on every session:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse (Bash) | Checks for hardcoded values, TODO format, JSON validity, design doc sections — exits early if the command is not `git commit` |
| `validate-push.sh` | PreToolUse (Bash) | Warns on pushes to protected branches — exits early if the command is not `git push` |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Validates naming conventions and JSON structure — exits early if the file is not in `assets/` |
| `session-start.sh` | Session open | Shows current branch and recent commits for orientation |
| `detect-gaps.sh` | Session open | Detects fresh projects (suggests `/start`) and missing design docs when code or prototypes exist |
| `pre-compact.sh` | Before compaction | Preserves session progress notes |
| `post-compact.sh` | After compaction | Reminds Claude to restore session state from `active.md` |
| `notify.sh` | Notification event | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | SessionEnd (session close) | Archives `active.md` to session log and records git activity |
| `log-agent.sh` | Agent spawned | Audit trail start — logs subagent invocation |
| `log-agent-stop.sh` | Agent stops | Audit trail stop — completes subagent record |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Advises running `/skill-test` after any `.claude/skills/` change |
| `validate-agent-manifest.sh` | PostToolUse (Write/Edit) | Warns when a new agent is not listed in the plugin manifest — plugin users would never see it |
| `log-tool-failure.sh` | PostToolUseFailure | Records failed tool calls to `production/session-logs/tool-failures.log` for retrospectives |
| `log-permission-denied.sh` | PermissionDenied | Records blocked operations (force push, `rm -rf`, `.env` reads) for the security audit trail |
| `detect-design-drift.sh` | FileChanged (`design/**.md`) | Notices GDDs edited outside the session and suggests `/propagate-design-change` |
| `log-turn-failure.sh` | StopFailure | Stamps `active.md` when a turn dies on an API error, so session recovery knows it resumed from a failure |

> **Note**: `validate-commit.sh`, `validate-assets.sh`, and `validate-skill-change.sh` fire on every Bash/Write tool call and exit immediately (exit 0) when the command or file path is not relevant. This is normal hook behavior — not a performance concern.

**Permission rules** in `settings.json` auto-allow safe operations (git status, test runs) and block dangerous ones (force push, `rm -rf`, reading `.env` files).

### Path-Scoped Rules

Coding standards are automatically enforced based on file location:

| Path | Enforces |
|------|----------|
| `src/gameplay/**` | Data-driven values, delta time usage, no UI references |
| `src/core/**` | Zero allocations in hot paths, thread safety, API stability |
| `src/ai/**` | Performance budgets, debuggability, data-driven parameters |
| `src/networking/**` | Server-authoritative, versioned messages, security |
| `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design/gdd/**` | Required 8 sections, formula format, edge cases |
| `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototypes/**` | Relaxed standards, README required, hypothesis documented |

## Design Philosophy

This template is grounded in professional game development practices:

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
- **Pick your engine** — use the Godot, Unity, or Unreal agent set (or none)
- **Set review intensity** — `full` (all director gates), `lean` (phase gates only), or `solo` (none). Set during `/start` or edit `production/review-mode.txt`. Override per-run with `--review solo` on any skill.

## Platform Support

Primary development and testing on **Windows 10** with Git Bash. All hooks use POSIX-compatible patterns (`grep -E`, not `grep -P`) and include fallbacks for missing tools, so they should run on macOS and Linux. The `notify.sh` hook uses PowerShell for Windows toast notifications and is a no-op elsewhere — desktop notifications on macOS/Linux are not yet wired. Cross-platform testing is ongoing; please file issues for any platform-specific breakage.

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
