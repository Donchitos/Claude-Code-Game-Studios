# Game Studio Agent Architecture -- Quick Start Guide

## What Is This?

This is a complete Claude Code agent architecture for game development. It
organizes 48 specialized AI agents into a studio hierarchy that mirrors
real game development teams, with defined responsibilities, delegation
rules, and coordination protocols. It includes engine-specialist agents
for Godot, Unity, and Unreal — each with dedicated sub-specialists for
major engine subsystems. All design agents and templates are grounded in
established game design theory (MDA Framework, Self-Determination Theory,
Flow State, Bartle Player Types). Use whichever engine set matches your project.

## How to Use

### 1. Understand the Hierarchy

There are three tiers of agents:

- **Tier 1 (Opus)**: Directors who make high-level decisions
  - `creative-director` -- vision and creative conflict resolution
  - `technical-director` -- architecture and technology decisions
  - `producer` -- scheduling, coordination, and risk management

- **Tier 2 (Sonnet)**: Department leads who own their domain
  - `game-designer`, `lead-programmer`, `art-director`, `audio-director`,
    `narrative-director`, `qa-lead`, `release-manager`, `localization-lead`

- **Tier 3 (Sonnet/Haiku)**: Specialists who execute within their domain
  - Designers, programmers, artists, writers, testers, engineers

### 2. Pick the Right Agent for the Job

Ask yourself: "What department would handle this in a real studio?"

| I need to... | Use this agent |
|-------------|---------------|
| Design a new mechanic | `game-designer` |
| Write combat code | `gameplay-programmer` |
| Create a shader | `technical-artist` |
| Write dialogue | `writer` |
| Plan the next sprint | `producer` |
| Review code quality | `lead-programmer` |
| Write test cases | `qa-tester` |
| Design a level | `level-designer` |
| Fix a performance problem | `performance-analyst` |
| Set up CI/CD | `devops-engineer` |
| Design a loot table | `economy-designer` |
| Resolve a creative conflict | `creative-director` |
| Make an architecture decision | `technical-director` |
| Manage a release | `release-manager` |
| Prepare strings for translation | `localization-lead` |
| Test a mechanic idea quickly | `prototyper` |
| Review code for security issues | `security-engineer` |
| Check accessibility compliance | `accessibility-specialist` |
| Get Unreal Engine advice | `unreal-specialist` |
| Get Unity advice | `unity-specialist` |
| Get Godot advice | `godot-specialist` |
| Design GAS abilities/effects | `ue-gas-specialist` |
| Define BP/C++ boundaries | `ue-blueprint-specialist` |
| Implement UE replication | `ue-replication-specialist` |
| Build UMG/CommonUI widgets | `ue-umg-specialist` |
| Design DOTS/ECS architecture | `unity-dots-specialist` |
| Write Unity shaders/VFX | `unity-shader-specialist` |
| Manage Addressable assets | `unity-addressables-specialist` |
| Build UI Toolkit/UGUI screens | `unity-ui-specialist` |
| Write idiomatic GDScript | `godot-gdscript-specialist` |
| Create Godot shaders | `godot-shader-specialist` |
| Build GDExtension modules | `godot-gdextension-specialist` |
| Plan live events and seasons | `live-ops-designer` |
| Write patch notes for players | `community-manager` |
| Brainstorm a new game idea | Use `/brainstorm` skill |

### 3. Use Slash Commands for Common Tasks

| Command | What it does |
|---------|-------------|
| `/start` | First-time onboarding — asks where you are, guides you to the right workflow |
| `/design-review` | Reviews a design document |
| `/code-review` | Reviews code for quality and architecture |
| `/playtest-report` | Creates or analyzes playtest feedback |
| `/balance-check` | Analyzes game balance data |
| `/sprint-plan` | Creates or updates sprint plans |
| `/architecture-decision` | Creates an ADR |
| `/asset-audit` | Audits assets for compliance |
| `/milestone-review` | Reviews milestone progress |
| `/onboard` | Generates onboarding docs for a role |
| `/prototype` | Scaffolds a throwaway prototype |
| `/release-checklist` | Validates pre-release checklist |
| `/changelog` | Generates changelog from git history |
| `/retrospective` | Runs sprint/milestone retrospective |
| `/estimate` | Produces structured effort estimates |
| `/hotfix` | Emergency fix with audit trail |
| `/tech-debt` | Scan, track, and prioritize tech debt |
| `/scope-check` | Detect scope creep against plan |
| `/localize` | Localization scan, extract, validate |
| `/perf-profile` | Performance profiling and bottleneck ID |
| `/gate-check` | Validate phase readiness (PASS/CONCERNS/FAIL) |
| `/project-stage-detect` | Analyze project state, detect stage, identify gaps |
| `/reverse-document` | Generate design/architecture docs from existing code |
| `/setup-engine` | Configure engine + version, populate reference docs |
| `/map-systems` | Decompose concept into systems, map dependencies, guide per-system GDDs |
| `/design-system` | Guided, section-by-section GDD authoring for a single game system |
| `/team-combat` | Orchestrate full combat team pipeline |
| `/team-narrative` | Orchestrate full narrative team pipeline |
| `/team-ui` | Orchestrate full UI team pipeline |
| `/team-release` | Orchestrate full release team pipeline |
| `/team-polish` | Orchestrate full polish team pipeline |
| `/team-audio` | Orchestrate full audio team pipeline |
| `/team-level` | Orchestrate full level creation pipeline |
| `/launch-checklist` | Complete launch readiness validation |
| `/patch-notes` | Generate player-facing patch notes |
| `/brainstorm` | Guided game concept ideation from scratch |

### 4. Use Templates for New Documents

Templates are in `.claude/docs/templates/`:

- `game-design-document.md` -- for new mechanics and systems
- `architecture-decision-record.md` -- for technical decisions
- `risk-register-entry.md` -- for new risks
- `narrative-character-sheet.md` -- for new characters
- `test-plan.md` -- for feature test plans
- `sprint-plan.md` -- for sprint planning
- `milestone-definition.md` -- for new milestones
- `level-design-document.md` -- for new levels
- `game-pillars.md` -- for core design pillars
- `art-bible.md` -- for visual style reference
- `technical-design-document.md` -- for per-system technical designs
- `post-mortem.md` -- for project/milestone retrospectives
- `sound-bible.md` -- for audio style reference
- `release-checklist-template.md` -- for platform release checklists
- `changelog-template.md` -- for player-facing patch notes
- `release-notes.md` -- for player-facing release notes
- `incident-response.md` -- for live incident response playbooks
- `game-concept.md` -- for initial game concepts (MDA, SDT, Flow, Bartle)
- `pitch-document.md` -- for pitching the game to stakeholders
- `economy-model.md` -- for virtual economy design (sink/faucet model)
- `faction-design.md` -- for faction identity, lore, and gameplay role
- `systems-index.md` -- for systems decomposition and dependency mapping
- `project-stage-report.md` -- for project stage detection output
- `design-doc-from-implementation.md` -- for reverse-documenting existing code into GDDs
- `architecture-doc-from-code.md` -- for reverse-documenting code into architecture docs
- `concept-doc-from-prototype.md` -- for reverse-documenting prototypes into concept docs

### 5. Follow the Coordination Rules

1. Work flows down the hierarchy: Directors -> Leads -> Specialists
2. Conflicts escalate up the hierarchy
3. Cross-department work is coordinated by the `producer`
4. Agents do not modify files outside their domain without delegation
5. All decisions are documented

## First Steps for a New Project

**Don't know where to begin?** Run `/start`. It asks where you are and routes
you to the right workflow. No assumptions about your game, engine, or experience level.

If you already know what you need, jump directly to the relevant path:

### Path A: "I have no idea what to build"

1. **Run `/start`** (or `/brainstorm open`) — guided creative exploration:
   what excites you, what you've played, your constraints
   - Generates 3 concepts, helps you pick one, defines core loop and pillars
   - Produces a game concept document and recommends an engine
2. **Set up the engine** — Run `/setup-engine` (uses the brainstorm recommendation)
   - Configures CLAUDE.md, detects knowledge gaps, populates reference docs
   - Creates `.claude/docs/technical-preferences.md` with naming conventions,
     performance budgets, and engine-specific defaults
   - If the engine version is newer than the LLM's training data, it fetches
     current docs from the web so agents suggest correct APIs
3. **Validate the concept** — Run `/design-review design/gdd/game-concept.md`
4. **Decompose into systems** — Run `/map-systems` to map all systems and dependencies
5. **Design each system** — Run `/design-system [system-name]` (or `/map-systems next`)
   to write GDDs in dependency order
6. **Test the core loop** — Run `/prototype [core-mechanic]`
7. **Playtest it** — Run `/playtest-report` to validate the hypothesis
8. **Plan the first sprint** — Run `/sprint-plan new`
9. Start building

### Path B: "I know what I want to build"

If you already have a game concept and engine choice:

1. **Set up the engine** — Run `/setup-engine [engine] [version]`
   (e.g., `/setup-engine godot 4.6`) — also creates technical preferences
2. **Write the Game Pillars** — delegate to `creative-director`
3. **Decompose into systems** — Run `/map-systems` to enumerate systems and dependencies
4. **Design each system** — Run `/design-system [system-name]` for GDDs in dependency order
5. **Create the initial ADR** — Run `/architecture-decision`
6. **Create the first milestone** in `production/milestones/`
7. **Plan the first sprint** — Run `/sprint-plan new`
8. Start building

### Path C: "I know the game but not the engine"

If you have a concept but don't know which engine fits:

1. **Run `/setup-engine`** with no arguments — it will ask about your game's
   needs (2D/3D, platforms, team size, language preferences) and recommend
   an engine based on your answers
2. Follow Path B from step 2 onward

### Path D: "I have an existing project"

If you have design docs, prototypes, or code already:

1. **Run `/start`** (or `/project-stage-detect`) — analyzes what exists,
   identifies gaps, and recommends next steps
2. **Configure engine if needed** — Run `/setup-engine` if not yet configured
3. **Validate phase readiness** — Run `/gate-check` to see where you stand
4. **Plan the next sprint** — Run `/sprint-plan new`

## File Structure Reference

```
CLAUDE.md                          -- Master config (read this first, ~60 lines)
.claude/
  settings.json                    -- Claude Code hooks and project settings
  agents/                          -- 48 agent definitions (YAML frontmatter)
  skills/                          -- 37 slash command definitions (YAML frontmatter)
  hooks/                           -- 8 hook scripts (.sh) wired by settings.json
  rules/                           -- 11 path-specific rule files
  docs/
    quick-start.md                 -- This file
    technical-preferences.md       -- Project-specific standards (populated by /setup-engine)
    coding-standards.md            -- Coding and design doc standards
    coordination-rules.md          -- Agent coordination rules
    context-management.md          -- Context budgets and compaction instructions
    review-workflow.md             -- Review and sign-off process
    directory-structure.md         -- Project directory layout
    agent-roster.md                -- Full agent list with tiers
    skills-reference.md            -- All slash commands
    rules-reference.md             -- Path-specific rules
    hooks-reference.md             -- Active hooks
    agent-coordination-map.md      -- Full delegation and workflow map
    setup-requirements.md          -- System prerequisites (Git Bash, jq, Python)
    settings-local-template.md     -- Personal settings.local.json guide
    hooks-reference/               -- Hook documentation and git hook examples
    templates/                     -- 28 document templates
```
