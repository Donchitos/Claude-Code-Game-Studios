# Claude Code Game Studios -- Complete Workflow Guide

> **How to go from zero to a shipped game using the Agent Architecture.**
>
> This guide walks you through every phase of game development using the
> 49-agent system, 73 slash commands, and 12 automated hooks. It assumes you
> have Claude Code installed and are working from the project root.
>
> The pipeline has 7 phases. Each phase has a formal gate (`/gate-check`)
> that must pass before you advance. The authoritative phase sequence is
> defined in `.claude/docs/workflow-catalog.yaml` and read by `/help`.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Phase 1: Concept](#phase-1-concept)
3. [Phase 2: Systems Design](#phase-2-systems-design)
4. [Phase 3: Technical Setup](#phase-3-technical-setup)
5. [Phase 4: Pre-Production](#phase-4-pre-production)
6. [Phase 5: Production](#phase-5-production)
7. [Phase 6: Polish](#phase-6-polish)
8. [Phase 7: Release](#phase-7-release)
9. [Cross-Cutting Concerns](#cross-cutting-concerns)
10. [Appendix A: Agent Quick-Reference](#appendix-a-agent-quick-reference)
11. [Appendix B: Slash Command Quick-Reference](#appendix-b-slash-command-quick-reference)
12. [Appendix C: Common Workflows](#appendix-c-common-workflows)

---

## Quick Start

### What You Need

Before you start, make sure you have:

- **Claude Code** installed and working
- **Git** with Git Bash (Windows) or standard terminal (Mac/Linux)
- **jq** (optional but recommended -- hooks fall back to `grep` if missing)
- **Python 3** (optional -- some hooks use it for JSON validation)

### Step 1: Clone and Open

```bash
git clone <repo-url> my-game
cd my-game
```

### Step 2: Run /start

If this is your first session:

```
/start
```

This guided onboarding asks where you are and routes you to the right phase:

- **Path A** -- No idea yet: routes to `/brainstorm`
- **Path B** -- Vague idea: routes to `/brainstorm` with seed
- **Path C** -- Clear concept: routes to `/setup-engine` and `/map-systems`
- **Path D1** -- Existing project, few artifacts: normal flow
- **Path D2** -- Existing project, GDDs/ADRs exist: runs `/project-stage-detect`
  then `/adopt` for brownfield migration

### Step 3: Verify Hooks Are Working

Start a new Claude Code session. You should see output from the
`session-start.sh` hook:

```
=== Claude Code Game Studios -- Session Context ===
Branch: main
Recent commits:
  abc1234 Initial commit
===================================
```

If you see this, hooks are working. If not, check `.claude/settings.json` to
make sure the hook paths are correct for your OS.

### Step 4: Ask for Help Anytime

At any point, run:

```
/help
```

This reads your current phase from `production/stage.txt`, checks which
artifacts exist, and tells you exactly what to do next. It distinguishes
between REQUIRED next steps and OPTIONAL opportunities.

### Step 5: Create Your Directory Structure

Directories are created as needed. The system expects this layout:

```
src/                  # Game source code
  core/               # Engine/framework code
  gameplay/           # Gameplay systems
  ai/                 # AI systems
  networking/         # Multiplayer code
  ui/                 # UI code
  tools/              # Dev tools
assets/               # Game assets
  art/                # Sprites, models, textures
  audio/              # Music, SFX
  vfx/                # Particle effects
  shaders/            # Shader files
  data/               # JSON config/balance data
design/               # Design documents
  gdd/                # Game design documents
  narrative/          # Story, lore, dialogue
  levels/             # Level design documents
  balance/            # Balance spreadsheets and data
  ux/                 # UX specifications
docs/                 # Technical documentation
  architecture/       # Architecture Decision Records
  api/                # API documentation
  postmortems/        # Post-mortems
tests/                # Test suites
prototypes/           # Throwaway prototypes
production/           # Sprint plans, milestones, releases
  sprints/
  milestones/
  releases/
  epics/              # Epic and story files (from /create-epics + /create-stories)
  playtests/          # Playtest reports
  session-state/      # Ephemeral session state (gitignored)
  session-logs/       # Session audit trail (gitignored)
```

> **Tip:** You do not need all of these on day one. Create directories as you
> reach the phase that needs them. The important thing is to follow this
> structure when you do create them, because the **rules system** enforces
> standards based on file paths. Code in `src/gameplay/` gets gameplay rules,
> code in `src/ai/` gets AI rules, and so on.

---

## Phase 1: Concept

### What Happens in This Phase

You go from "no idea" or "vague idea" to a structured game concept document
with defined pillars and a player journey. This is where you figure out
**what** you are making and **why**.

### Phase 1 Pipeline

```
/brainstorm  -->  game-concept.md  -->  /design-review  -->  /setup-engine
     |                                        |                    |
     v                                        v                    v
  10 concepts     Concept doc with       Validation          Engine pinned in
  MDA analysis    pillars, MDA,          of concept          technical-preferences.md
  Player motiv.   core loop, USP         document
                                                                   |
                                                                   v
                                                             /prototype
                                                       (concept prototype — 1-3 days)
                                                        PROCEED ↓     PIVOT → /brainstorm
                                                                   |
                                                                   v (PROCEED)
                                                             /map-systems
                                                                   |
                                                                   v
                                                            systems-index.md
                                                            (all systems, deps,
                                                             priority tiers)
```

### Step 1.1: Brainstorm With /brainstorm

This is your starting point. Run the brainstorm skill:

```
/brainstorm
```

Or with a genre hint:

```
/brainstorm roguelike deckbuilder
```

**What happens:** The brainstorm skill guides you through a collaborative 6-phase
ideation process using professional studio techniques:

1. Asks about your interests, themes, and constraints
2. Generates 10 concept seeds with MDA (Mechanics, Dynamics, Aesthetics) analysis
3. You pick 2-3 favorites for deep analysis
4. Performs player motivation mapping and audience targeting
5. You choose the winning concept
6. Formalizes it into `design/gdd/game-concept.md`

The concept document includes:

- Elevator pitch (one sentence)
- Core fantasy (what the player imagines themselves doing)
- MDA breakdown
- Target audience (Bartle types, demographics)
- Core loop diagram
- Unique selling proposition
- Comparable titles and differentiation
- Game pillars (3-5 non-negotiable design values)
- Anti-pillars (things the game intentionally avoids)

### Step 1.2: Review the Concept (Optional but Recommended)

```
/design-review design/gdd/game-concept.md
```

Validates structure and completeness before you proceed.

### Step 1.3: Choose Your Engine

```
/setup-engine
```

Or with a specific engine:

```
/setup-engine godot 4.6
```

**What /setup-engine does:**

- Populates `.claude/docs/technical-preferences.md` with naming conventions,
  performance budgets, and engine-specific defaults
- Detects knowledge gaps (engine version newer than LLM training data) and
  advises cross-referencing `docs/engine-reference/`
- Creates version-pinned reference docs in `docs/engine-reference/`

**Why this matters:** Once you set the engine, the system knows which
engine-specialist agents to use. If you pick Godot, agents like
`godot-specialist`, `godot-gdscript-specialist`, and `godot-shader-specialist`
become your go-to experts.

### Step 1.4: Decompose Your Concept Into Systems

Before writing individual GDDs, enumerate all the systems your game needs:

```
/map-systems
```

This creates `design/gdd/systems-index.md` -- a master tracking document that:

- Lists every system your game needs (combat, movement, UI, etc.)
- Maps dependencies between systems
- Assigns priority tiers (MVP, Vertical Slice, Alpha, Full Vision)
- Determines design order (Foundation > Core > Feature > Presentation > Polish)

This step is **required** before proceeding to Phase 2. Research from 155 game
postmortems confirms that skipping systems enumeration costs 5-10x more in
production.

### Phase 1 Gate

```
/gate-check concept
```

**Requirements to pass:**

- Engine configured in `technical-preferences.md`
- `design/gdd/game-concept.md` exists with pillars
- `design/gdd/systems-index.md` exists with dependency ordering

**Verdict:** PASS / CONCERNS / FAIL. CONCERNS is passable with acknowledged
risks. FAIL blocks advancement.

---

## Phase 2: Systems Design

### What Happens in This Phase

You create all the design documents that define how your game works. Nothing
gets coded yet -- this is pure design. Each system identified in the systems
index gets its own GDD, authored section by section, reviewed individually,
and then all GDDs are cross-checked for consistency.

### Phase 2 Pipeline

```
/map-systems next  -->  /design-system  -->  /design-review
       |                     |                     |
       v                     v                     v
  Picks next system    Section-by-section     Validates 8
  from systems-index   GDD authoring          required sections
                       (incremental writes)   APPROVED/NEEDS REVISION
       |
       |  (repeat for each MVP system)
       v
/review-all-gdds
       |
       v
  Cross-GDD consistency + design theory review
  PASS / CONCERNS / FAIL
```

### Step 2.1: Author System GDDs

Design each system in dependency order using the guided workflow:

```
/map-systems next
```

This picks the highest-priority undesigned system and hands off to
`/design-system`, which guides you through creating its GDD section by section.

You can also design a specific system directly:

```
/design-system combat-system
```

**What /design-system does:**

1. Reads your game concept, systems index, and any upstream/downstream GDDs
2. Runs a Technical Feasibility Pre-Check (domain mapping + feasibility brief)
3. Walks you through each of the 8 required GDD sections one at a time
4. Each section follows: Context > Questions > Options > Decision > Draft > Approval > Write
5. Each section is written to file immediately after approval (survives crashes)
6. Flags conflicts with existing approved GDDs
7. Routes to specialist agents per category (systems-designer for math,
   economy-designer for economy, narrative-director for story systems)

**The 8 required GDD sections:**

| # | Section | What Goes Here |
|---|---------|---------------|
| 1 | **Overview** | One-paragraph summary of the system |
| 2 | **Player Fantasy** | What the player imagines/feels when using this system |
| 3 | **Detailed Rules** | Unambiguous mechanical rules |
| 4 | **Formulas** | Every calculation, with variable definitions and ranges |
| 5 | **Edge Cases** | What happens in weird situations? Explicitly resolved. |
| 6 | **Dependencies** | What other systems this connects to (bidirectional) |
| 7 | **Tuning Knobs** | Which values designers can safely change, with safe ranges |
| 8 | **Acceptance Criteria** | How do you test that this works? Specific, measurable. |

Plus a **Game Feel** section: feel reference, input responsiveness (ms/frames),
animation feel targets (startup/active/recovery), impact moments, weight profile.

### Step 2.2: Review Each GDD

Before the next system starts, validate the current one:

```
/design-review design/gdd/combat-system.md
```

Checks all 8 sections for completeness, formula clarity, edge case resolution,
bidirectional dependencies, and testable acceptance criteria.

**Verdict:** APPROVED / NEEDS REVISION / MAJOR REVISION. Only APPROVED GDDs
should proceed.

### Step 2.3: Small Changes Without Full GDDs

For tuning changes, small additions, or tweaks that do not warrant a full GDD:

```
/quick-design "add 10% damage bonus for flanking attacks"
```

This creates a lightweight spec in `design/quick-specs/` instead of a full
8-section GDD. Use it for tuning, number changes, and small additions.

### Step 2.4: Cross-GDD Consistency Review

After all MVP system GDDs are approved individually:

```
/review-all-gdds
```

This reads ALL GDDs simultaneously and runs two analysis phases:

**Phase 1 -- Cross-GDD Consistency:**
- Dependency bidirectionality (A references B, does B reference A?)
- Rule contradictions between systems
- Stale references to renamed or removed systems
- Ownership conflicts (two systems claiming the same responsibility)
- Formula range compatibility (does System A's output fit System B's input?)
- Acceptance criteria cross-check

**Phase 2 -- Design Theory (Game Design Holism):**
- Competing progression loops (do two systems fight for the same reward space?)
- Cognitive load (more than 4 active systems at once?)
- Dominant strategies (one approach that makes all others irrelevant)
- Economic loop analysis (sources and sinks balanced?)
- Difficulty curve consistency across systems
- Pillar alignment and anti-pillar violations
- Player fantasy coherence

**Output:** `design/gdd/gdd-cross-review-[date].md` with a verdict.

### Step 2.5: Narrative Design (If Applicable)

If your game has story, lore, or dialogue, this is when you build it:

1. **World-building** -- Use `world-builder` to define factions, history,
   geography, and rules of your world
2. **Story structure** -- Use `narrative-director` to design story arcs,
   character arcs, and narrative beats
3. **Character sheets** -- Use the `narrative-character-sheet.md` template

### Phase 2 Gate

```
/gate-check systems-design
```

**Requirements to pass:**

- All MVP systems in `systems-index.md` have `Status: Approved`
- Each MVP system has a reviewed GDD
- Cross-GDD review report exists (`design/gdd/gdd-cross-review-*.md`)
  with verdict of PASS or CONCERNS (not FAIL)

---

## Phase 3: Technical Setup

### What Happens in This Phase

You make key technical decisions, document them as Architecture Decision Records
(ADRs), validate them through review, and produce a control manifest that
gives programmers flat, actionable rules. You also establish UX foundations.

### Phase 3 Pipeline

```
/create-architecture  -->  /architecture-decision (x N)  -->  /architecture-review
        |                          |                                   |
        v                          v                                   v
  Master architecture       Per-decision ADRs              Validates completeness,
  document covering         in docs/architecture/          dependency ordering,
  all systems               adr-*.md                       engine compatibility
                                                                      |
                                                                      v
                                                         /create-control-manifest
                                                                      |
                                                                      v
                                                         Flat programmer rules
                                                         docs/architecture/
                                                         control-manifest.md
        Also in this phase:
        -------------------
        /ux-design  -->  /ux-review
        Accessibility requirements doc
        Interaction pattern library
```

### Step 3.1: Master Architecture Document

```
/create-architecture
```

Creates the overarching architecture document in `docs/architecture/architecture.md`
covering system boundaries, data flow, and integration points.

### Step 3.2: Architecture Decision Records (ADRs)

For each significant technical decision:

```
/architecture-decision "State Machine vs Behavior Tree for NPC AI"
```

**What happens:** The skill guides you through creating an ADR with:
- Context and decision drivers
- All options with pros/cons and engine compatibility
- Chosen option with rationale
- Consequences (positive, negative, risks)
- Dependencies (Depends On, Enables, Blocks, Ordering Note)
- GDD Requirements Addressed (linked by TR-ID)

ADRs go through a lifecycle: Proposed > Accepted > Superseded/Deprecated.

**Minimum 3 Foundation-layer ADRs are required** before the gate check.

**Retrofitting existing ADRs:** If you already have ADRs from a brownfield
project:

```
/architecture-decision retrofit docs/architecture/adr-005.md
```

This detects which template sections are missing and adds only those, never
overwriting existing content.

### Step 3.3: Architecture Review

```
/architecture-review
```

Validates all ADRs together:
- Topological sort of ADR dependencies (detects cycles)
- Engine compatibility verification
- GDD Revision Flags (flags GDD sections that need updates based on ADR choices)
- TR-ID registry maintenance (`docs/architecture/tr-registry.yaml`)

### Step 3.4: Control Manifest

```
/create-control-manifest
```

Takes all Accepted ADRs and produces a flat programmer rules sheet:

```
docs/architecture/control-manifest.md
```

This contains Required patterns, Forbidden patterns, and Guardrails organized
by code layer. Stories created later embed the manifest version date so
staleness can be detected.

### Step 3.5: Accessibility Requirements

Create `design/accessibility-requirements.md` using the template. Commit to a
tier (Basic / Standard / Comprehensive / Exemplary) and fill the 4-axis feature
matrix (visual, motor, cognitive, auditory).

This document is required in Phase 3 because UX specs (written in Phase 4)
reference this tier — it is a design prerequisite, not a UX deliverable.

### Phase 3 Gate

```
/gate-check technical-setup
```

**Requirements to pass:**

- `docs/architecture/architecture.md` exists
- At least 3 ADRs exist and are Accepted
- Architecture review report exists
- `docs/architecture/control-manifest.md` exists
- `design/accessibility-requirements.md` exists

---

## Phase 4: Pre-Production

### What Happens in This Phase

You create UX specs for key screens, prototype risky mechanics, turn design
documents into implementable stories, plan your first sprint, and build a
Vertical Slice that proves the core loop is fun.

### Phase 4 Pipeline

```
/ux-design  -->  /vertical-slice  -->  /create-epics  -->  /create-stories  -->  /sprint-plan
    |                   |                   |                   |                       |
    v                   v                   v                   v                       v
  UX specs       Production-quality   Epic files in       Story files in          First sprint with
  design/ux/     end-to-end build     production/         production/             prioritized stories
                 in prototypes/       epics/*/EPIC.md     epics/*/story-*.md      production/sprints/
                 PROCEED/PIVOT/KILL   (one per module)    (one per behaviour)     sprint-*.md
    |                                                          |
    v                                                          v
 /ux-review                                             /story-readiness
 (validates specs                                       (validates each story
  before epics)                                          before pickup)
                                                               |
                                                               v
                                                           /dev-story
                                                         (implements the story,
                                                          routes to right agent)
```

### Step 4.1: UX Specs for Key Screens

Before writing epics, create UX specs so that story authors know what screens
exist and what player interactions they must support.

**UX Specs:**

```
/ux-design main-menu
/ux-design core-gameplay-hud
```

Three modes: screen/flow, HUD, and interaction patterns. Output goes to
`design/ux/`. Each spec includes: player need, layout zones, states,
interaction map, data requirements, events fired, accessibility, localization.

Reads your `accessibility-requirements.md` (written in Phase 3) and your
input method config from `technical-preferences.md` to drive accessibility
and input coverage checks — no need to re-specify them per screen.

> **Tip:** `/design-system` emits a 📌 UX Flag for every system with UI
> requirements. Use those flags as a checklist for which screens need specs.

**Interaction Pattern Library:**

```
/ux-design interaction-patterns
```

Create `design/ux/interaction-patterns.md` — 16 standard controls plus
game-specific patterns (inventory slot, ability icon, HUD bar, dialogue box,
etc.) with animation and sound standards.

**UX Review:**

```
/ux-review all
```

Validates UX specs for GDD alignment and accessibility tier compliance.
Produces APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED verdict.

### Step 4.2: Build the Vertical Slice

The vertical slice is the production-quality proof that you can build the full
game loop end-to-end before committing to full Production.

```
/vertical-slice
```

**What it proves:** Does a player, starting from nothing, experience the core
fantasy within a few minutes, without developer guidance?

**What it builds:** A near-production-quality playable build covering at least
one complete [start → challenge → resolution] cycle. Uses real architecture
layers, real naming conventions, no hardcoded values — but not final art or
audio. This is not a throwaway like the concept prototype; it demonstrates
production pipeline feasibility.

**Note on concept prototyping:** If you ran `/prototype` in Phase 1 (Concept),
you already validated the core idea is fun. The vertical slice now validates
you can build it properly. They answer different questions. If you skipped the
concept prototype, now is a reasonable time to run one first before investing
in the full slice.

**Verdict:** The vertical slice produces a PROCEED / PIVOT / KILL verdict.
- **PROCEED** → move to Step 4.3 (epics and stories)
- **PIVOT** → revise affected GDDs with `/design-system [mechanic]`, then re-run `/vertical-slice`
- **KILL** → return to `/brainstorm` with what you learned

### Step 4.3: Create Epics and Stories From Design Artifacts

```
/create-epics layer: foundation
/create-stories [epic-slug]   # repeat for each epic
/create-epics layer: core
/create-stories [epic-slug]   # repeat for each core epic
```

`/create-epics` reads your GDDs, ADRs, and architecture to define epic scope —
one epic per architectural module. Then `/create-stories` breaks each epic into
implementable story files in `production/epics/[slug]/`. Each story embeds:
- GDD requirement references (TR-IDs, not quoted text -- stays fresh)
- ADR references (only from Accepted ADRs; Proposed ADRs cause `Status: Blocked`)
- Control manifest version date (for staleness detection)
- Engine-specific implementation notes
- Acceptance criteria from the GDD

Once stories exist, run `/dev-story [story-path]` to implement one — it routes
automatically to the correct programmer agent.

### Step 4.4: Validate Stories Before Pickup

```
/story-readiness production/epics/combat/story-combat-damage-calc.md
```

Checks: Design completeness, Architecture coverage, Scope clarity, Definition
of Done. Verdict: READY / NEEDS WORK / BLOCKED.

### Step 4.5: Effort Estimation

```
/estimate production/epics/combat/story-combat-damage-calc.md
```

Provides effort estimates with risk assessment.

### Step 4.6: Plan Your First Sprint

```
/sprint-plan new
```

**What happens:** The `producer` agent collaborates on sprint planning:
- Asks for sprint goal and available time
- Breaks the goal into Must Have / Should Have / Nice to Have tasks
- Identifies risks and blockers
- Creates `production/sprints/sprint-01.md`
- Populates `production/sprint-status.yaml` (machine-readable story tracking)

### Step 4.7: Vertical Slice (Hard Gate)

Before advancing to Production, you must build and playtest a Vertical Slice:

- One complete end-to-end core loop, playable from start to finish
- Representative quality (not placeholder everything)
- Played unguided in at least 3 sessions
- Playtest report written (`/playtest-report`)

This is a **hard gate** -- `/gate-check` will auto-FAIL if a human has not
played the build unguided.

### Phase 4 Gate

```
/gate-check pre-production
```

**Requirements to pass:**

- At least 1 UX spec reviewed in `design/ux/`
- UX review completed (APPROVED or NEEDS REVISION with documented risks)
- At least 1 prototype with README
- Story files exist in `production/epics/[epic-slug]/`
- At least 1 sprint plan exists
- At least 1 playtest report exists (Vertical Slice played in 3+ sessions)

---

## Phase 5: Production

### What Happens in This Phase

This is the core production loop. You work in sprints (typically 1-2 weeks),
implementing features story by story, tracking progress, and closing stories
through a structured completion review. This phase repeats until your game
is content-complete.

### Phase 5 Pipeline (Per Sprint)

```
/sprint-plan new  -->  /story-readiness  -->  implement  -->  /story-done
       |                     |                    |                |
       v                     v                    v                v
  Sprint created       Story validated      Code written     8-phase review:
  sprint-status.yaml   READY verdict        Tests pass       verify criteria,
  populated                                                  check deviations,
                                                             update story status
       |
       |  (repeat per story until sprint complete)
       v
  /sprint-status  (quick 30-line snapshot anytime)
  /scope-check    (if scope is growing)
  /retrospective  (at sprint end)
```

### Step 5.1: The Story Lifecycle

The production phase centers on the **story lifecycle**:

```
/story-readiness  -->  implement  -->  /story-done  -->  next story
```

**1. Story Readiness:** Before picking up a story, validate it:

```
/story-readiness production/epics/combat/story-combat-damage-calc.md
```

This checks design completeness, architecture coverage, ADR status (blocks
if ADR is still Proposed), control manifest version (warns if stale), and
scope clarity. Verdict: READY / NEEDS WORK / BLOCKED.

**2. Implementation:** Work with the appropriate agents:

- `gameplay-programmer` for gameplay systems
- `engine-programmer` for core engine work
- `ai-programmer` for AI behavior
- `network-programmer` for multiplayer
- `ui-programmer` for UI code
- `tools-programmer` for dev tools

All agents follow the collaborative protocol: they read the design doc, ask
clarifying questions, present architectural options, get your approval, then
implement.

**3. Story Completion:** When a story is done:

```
/story-done production/epics/combat/story-combat-damage-calc.md
```

This runs an 8-phase completion review:
1. Find and read the story file
2. Load referenced GDD, ADRs, and control manifest
3. Verify acceptance criteria (auto-checkable, manual, deferred)
4. Check for GDD/ADR deviations (BLOCKING / ADVISORY / OUT OF SCOPE)
5. Prompt for code review
6. Generate completion report (COMPLETE / COMPLETE WITH NOTES / BLOCKED)
7. Update story `Status: Complete` with completion notes
8. Surface the next ready story

Tech debt discovered during review is logged to `docs/tech-debt-register.md`.

### Step 5.2: Sprint Tracking

Check progress anytime:

```
/sprint-status
```

Quick 30-line snapshot reading from `production/sprint-status.yaml`.

If scope is growing:

```
/scope-check production/sprints/sprint-03.md
```

This compares current scope against the original plan and flags scope increase,
recommends cuts.

### Step 5.3: Content Tracking

```
/content-audit
```

Compares GDD-specified content against what has been implemented. Catches
content gaps early.

### Step 5.4: Design Change Propagation

When a GDD changes after stories have been created:

```
/propagate-design-change design/gdd/combat-system.md
```

Git-diffs the GDD, finds affected ADRs, generates an impact report, and
walks you through Superseded/update/keep decisions.

### Step 5.5: Multi-System Features (Team Orchestration)

For features spanning multiple domains, use team skills:

```
/team-combat "healing ability with HoT and cleanse"
/team-narrative "Act 2 story content"
/team-ui "inventory screen redesign"
/team-level "forest dungeon level"
/team-audio "combat audio pass"
```

Each team skill coordinates a 6-phase collaborative workflow:
1. **Design** -- game-designer asks questions, presents options
2. **Architecture** -- lead-programmer proposes code structure
3. **Parallel Implementation** -- specialists work simultaneously
4. **Integration** -- gameplay-programmer wires everything together
5. **Validation** -- qa-tester runs against acceptance criteria
6. **Report** -- coordinator summarizes status

The orchestration is automated, but **decision points stay with you**.

### Step 5.6: Sprint Review and Next Sprint

At the end of a sprint:

```
/retrospective
```

Analyzes planned vs. completed, velocity, blockers, and actionable improvements.

Then plan the next sprint:

```
/sprint-plan new
```

### Step 5.7: Milestone Reviews

At milestone checkpoints:

```
/milestone-review "alpha"
```

Produces feature completeness, quality metrics, risk assessment, and go/no-go
recommendation.

### Phase 5 Gate

```
/gate-check production
```

**Requirements to pass:**

- All MVP stories complete
- Playtesting: 3 sessions covering new player, mid-game, and difficulty curve
- Fun hypothesis validated
- No confusion loops in playtest data

---

## Phase 6: Polish

### What Happens in This Phase

Your game is feature-complete. Now you make it good. This phase focuses on
performance, balance, accessibility, audio, visual polish, and playtesting.

### Phase 6 Pipeline

```
/perf-profile  -->  /balance-check  -->  /asset-audit  -->  /playtest-report (x3)
       |                  |                    |                    |
       v                  v                    v                    v
  Profile CPU/GPU    Analyze formulas     Verify naming,      Cover: new player,
  memory, optimize   and data for         formats, sizes      mid-game, difficulty
  bottlenecks        broken progressions                      curve

  /tech-debt  -->  /team-polish
       |                |
       v                v
  Track and        Coordinated pass:
  prioritize       performance + art +
  debt items       audio + UX + QA
```

### Step 6.1: Performance Profiling

```
/perf-profile
```

Guides you through structured performance profiling:
- Establish targets (FPS, memory, platform)
- Identify bottlenecks ranked by impact
- Generate actionable optimization tasks with code locations and expected gains

### Step 6.2: Balance Analysis

```
/balance-check assets/data/combat_damage.json
```

Analyzes balance data for statistical outliers, broken progression curves,
degenerate strategies, and economy imbalances.

### Step 6.3: Asset Audit

```
/asset-audit
```

Verifies naming conventions, file format standards, and size budgets across
all assets.

### Step 6.4: Playtesting (Required: 3 Sessions)

```
/playtest-report
```

Generates structured playtest reports. Three sessions are required, covering:
- New player experience
- Mid-game systems
- Difficulty curve

### Step 6.5: Technical Debt Assessment

```
/tech-debt
```

Scans for TODO/FIXME/HACK comments, code duplication, overly complex functions,
missing tests, and outdated dependencies. Each item categorized and prioritized.

### Step 6.6: Coordinated Polish Pass

```
/team-polish "combat system"
```

Coordinates 4 specialists in parallel:
1. Performance optimization (performance-analyst)
2. Visual polish (technical-artist)
3. Audio polish (sound-designer)
4. Feel/juice (gameplay-programmer + technical-artist)

You set priorities; the team executes with your approval at each step.

### Step 6.7: Localization and Accessibility

```
/localize src/
```

Scans for hardcoded strings, concatenation that breaks translation, text that
does not account for expansion, and missing locale files.

Accessibility is audited against the tier committed in Phase 3's accessibility
requirements document.

### Phase 6 Gate

```
/gate-check polish
```

**Requirements to pass:**

- At least 3 playtest reports exist
- Coordinated polish pass completed (`/team-polish`)
- No blocking performance issues
- Accessibility tier requirements met

---

## Phase 7: Release

### What Happens in This Phase

Your game is polished, tested, and ready. Now you ship it.

### Phase 7 Pipeline

```
/release-checklist  -->  /launch-checklist  -->  /team-release
        |                       |                      |
        v                       v                      v
  Pre-release             Full cross-department    Coordinate:
  validation across       validation (Go/No-Go     build, QA sign-off,
  code, content,          per department)           deployment, launch
  store, legal
                    Also: /changelog, /patch-notes, /hotfix
```

### Step 7.1: Release Checklist

```
/release-checklist v1.0.0
```

Generates a comprehensive pre-release checklist covering:
- Build verification (all platforms compile and run)
- Certification requirements (platform-specific)
- Store metadata (descriptions, screenshots, trailers)
- Legal compliance (EULA, privacy policy, ratings)
- Save game compatibility
- Analytics verification

### Step 7.2: Launch Readiness (Full Validation)

```
/launch-checklist
```

Complete cross-department validation:

| Department | What Is Checked |
|-----------|---------------|
| **Engineering** | Build stability, crash rates, memory leaks, load times |
| **Design** | Feature completeness, tutorial flow, difficulty curve |
| **Art** | Asset quality, missing textures, LOD levels |
| **Audio** | Missing sounds, mixing levels, spatial audio |
| **QA** | Open bug count by severity, regression suite pass rate |
| **Narrative** | Dialogue completeness, lore consistency, typos |
| **Localization** | All strings translated, no truncation, locale testing |
| **Accessibility** | Compliance checklist, assistive feature testing |
| **Store** | Metadata complete, screenshots approved, pricing set |
| **Marketing** | Press kit ready, launch trailer, social media scheduled |
| **Community** | Patch notes draft, FAQ prepared, support channels ready |
| **Infrastructure** | Servers scaled, CDN configured, monitoring active |
| **Legal** | EULA finalized, privacy policy, COPPA/GDPR compliance |

Each item gets a **Go / No-Go** status. All must be Go to ship.

### Step 7.3: Generate Player-Facing Content

```
/patch-notes v1.0.0
```

Generates player-friendly patch notes from git history and sprint data.
Translates developer language into player language.

```
/changelog v1.0.0
```

Generates an internal changelog (more technical, for the team).

### Step 7.4: Coordinate the Release

```
/team-release
```

Coordinates release-manager, QA, and DevOps through:
1. Pre-release validation
2. Build management
3. Final QA sign-off
4. Deployment preparation
5. Go/No-Go decision

### Step 7.5: Ship

The `validate-push` hook will warn you when pushing to `main` or `develop`.
This is intentional -- release pushes should be deliberate:

```bash
git tag v1.0.0
git push origin main --tags
```

### Step 7.6: Post-Launch

**Hotfix workflow** for critical production bugs:

```
/hotfix "Players losing save data when inventory exceeds 99 items"
```

Bypasses normal sprint processes with a full audit trail:
1. Creates a hotfix branch
2. Implements the fix
3. Ensures backport to development branch
4. Documents the incident

**Post-mortem** after launch stabilizes:

```
Ask Claude to create a post-mortem using the template at
.claude/docs/templates/post-mortem.md
```

---

## Cross-Cutting Concerns

These topics apply across all phases.

### Director Review Modes

Director gates are specialist agents that review your work at key workflow steps.
By default they run at every checkpoint. You can control how much review you get.

**Set your review intensity once during `/start`.** Saved to `production/review-mode.txt`.

| Mode | What runs | Best for |
|------|-----------|----------|
| `full` | All director gates at every step | New projects, learning the system |
| `lean` | Directors only at phase transitions (`/gate-check`) | Experienced devs |
| `solo` | No director reviews | Game jams, prototypes, maximum speed |

**Override for a single run** without changing your global setting:

```
/brainstorm space horror --review full
/architecture-decision --review solo
```

The `--review` flag works on all gate-using skills. Change the global mode at any
time by editing `production/review-mode.txt` directly or re-running `/start`.

Full gate definitions and check pattern: `.claude/docs/director-gates.md`

---

### The Collaboration Protocol

This system is **user-driven collaborative**, not autonomous.

**Pattern:** Question > Options > Decision > Draft > Approval

Every agent interaction follows this pattern:
1. Agent asks clarifying questions
2. Agent presents 2-4 options with trade-offs and reasoning
3. You decide
4. Agent drafts based on your decision
5. You review and refine
6. Agent asks "May I write this to [filepath]?" before writing

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for the full protocol with
examples.

### The AskUserQuestion Tool

Agents use the `AskUserQuestion` tool for structured option presentation.
The pattern is Explain then Capture: full analysis in conversation text first,
then a clean UI picker for the decision. Use it for design choices,
architecture decisions, and strategic questions. Do not use it for open-ended
discovery questions or simple yes/no confirmations.

### Agent Coordination (3-Tier Hierarchy)

```
Tier 1 (Directors):    creative-director, technical-director, producer
                                          |
Tier 2 (Leads):        game-designer, lead-programmer, art-director,
                       audio-director, narrative-director, qa-lead,
                       release-manager, localization-lead
                                          |
Tier 3 (Specialists):  gameplay-programmer, engine-programmer,
                       ai-programmer, network-programmer, ui-programmer,
                       tools-programmer, systems-designer, level-designer,
                       economy-designer, world-builder, writer,
                       technical-artist, sound-designer, ux-designer,
                       qa-tester, performance-analyst, devops-engineer,
                       analytics-engineer, accessibility-specialist,
                       live-ops-designer, prototyper, security-engineer,
                       community-manager, godot-specialist,
                       godot-gdscript-specialist, godot-shader-specialist,
                       godot-csharp-specialist, godot-gdextension-specialist,
                       unity-specialist, unity-dots-specialist,
                       unity-shader-specialist, unity-addressables-specialist,
                       unity-ui-specialist, unreal-specialist,
                       ue-blueprint-specialist, ue-gas-specialist,
                       ue-replication-specialist, ue-umg-specialist
```

**Coordination rules:**
- Vertical delegation: Directors > Leads > Specialists. Never skip tiers for
  complex decisions.
- Horizontal consultation: Agents at the same tier may consult each other but
  must not make binding decisions outside their domain.
- Conflict resolution: Design conflicts go to `creative-director`. Technical
  conflicts go to `technical-director`. Scope conflicts go to `producer`.
- No unilateral cross-domain changes.

### Automated Hooks (Safety Net)

The system has 12 hooks that run automatically:

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `session-start.sh` | Session start | Shows branch, recent commits, detects active.md for recovery |
| `detect-gaps.sh` | Session start | Detects fresh projects (no engine, no concept) and suggests `/start` |
| `pre-compact.sh` | Before compaction | Dumps session state into conversation for auto-recovery |
| `post-compact.sh` | After compaction | Reminds Claude to restore session state from `active.md` |
| `notify.sh` | Notification event | Shows Windows toast notification via PowerShell |
| `validate-commit.sh` | Before commit | Checks for design doc references, valid JSON, no hardcoded values |
| `validate-push.sh` | Before push | Warns on pushes to main/develop |
| `validate-assets.sh` | Before commit | Checks asset naming and size |
| `validate-skill-change.sh` | Skill file written | Advises running `/skill-test` after `.claude/skills/` changes |
| `log-agent.sh` | Agent start | Logs agent invocations for audit trail |
| `log-agent-stop.sh` | Agent stop | Completes agent audit trail (start + stop) |
| `session-stop.sh` | Session end | Final session logging |

### Context Resilience

**Session state file:** `production/session-state/active.md` is a living
checkpoint. Update it after each significant milestone. After any disruption
(compaction, crash, `/clear`), read this file first.

**Incremental writing:** When creating multi-section documents, write each
section to file immediately after approval. This means completed sections
survive crashes and context compactions. Previous discussion about written
sections can be safely compacted.

**Automatic recovery:** The `session-start.sh` hook detects and previews
`active.md` automatically. The `pre-compact.sh` hook dumps state into the
conversation before compaction.

**Sprint status tracking:** `production/sprint-status.yaml` is the
machine-readable story tracker. Written by `/sprint-plan` (init) and
`/story-done` (status updates). Read by `/sprint-status`, `/help`, and
`/story-done` (next story). Eliminates fragile markdown scanning.

### Brownfield Adoption

For existing projects that already have some artifacts:

```
/adopt
```

Or targeted:

```
/adopt gdds
/adopt adrs
/adopt stories
/adopt infra
```

This audits existing artifacts for **format** (not existence), classifies gaps
as BLOCKING/HIGH/MEDIUM/LOW, builds an ordered migration plan, and writes
`docs/adoption-plan-[date].md`. Core principle: MIGRATION not REPLACEMENT --
it never regenerates existing work, only fills gaps.

Individual skills also support retrofit mode:

```
/design-system retrofit design/gdd/combat-system.md
/architecture-decision retrofit docs/architecture/adr-005.md
```

These detect which sections are present vs. missing and fill only the gaps.

### Gate System

Phase gates are formal checkpoints. Run `/gate-check` with the transition name:

```
/gate-check concept              # Concept -> Systems Design
/gate-check systems-design       # Systems Design -> Technical Setup
/gate-check technical-setup      # Technical Setup -> Pre-Production
/gate-check pre-production       # Pre-Production -> Production
/gate-check production           # Production -> Polish
/gate-check polish               # Polish -> Release
```

**Verdicts:**
- **PASS** -- all requirements met, advance to next phase
- **CONCERNS** -- requirements met with acknowledged risks, passable
- **FAIL** -- requirements not met, blocks advancement with specific remediation

When a gate passes, `production/stage.txt` is updated (only then), which
controls the status line and `/help` behavior.

### Reverse Documentation

For code that exists without design docs (common after brownfield adoption):

```
/reverse-document src/gameplay/combat/
```

Reads existing code and generates GDD-format design documentation from it.

---

## Appendix A: Agent Quick-Reference

### "I need to do X -- which agent do I use?"

| I need to... | Agent | Tier |
|-------------|-------|------|
| Come up with a game idea | `/brainstorm` skill | -- |
| Design a game mechanic | `game-designer` | 2 |
| Design specific formulas/numbers | `systems-designer` | 3 |
| Design a game level | `level-designer` | 3 |
| Design loot tables / economy | `economy-designer` | 3 |
| Build world lore | `world-builder` | 3 |
| Write dialogue | `writer` | 3 |
| Plan the story | `narrative-director` | 2 |
| Plan a sprint | `producer` | 1 |
| Make a creative decision | `creative-director` | 1 |
| Make a technical decision | `technical-director` | 1 |
| Implement gameplay code | `gameplay-programmer` | 3 |
| Implement core engine systems | `engine-programmer` | 3 |
| Implement AI behavior | `ai-programmer` | 3 |
| Implement multiplayer | `network-programmer` | 3 |
| Implement UI | `ui-programmer` | 3 |
| Build dev tools | `tools-programmer` | 3 |
| Review code architecture | `lead-programmer` | 2 |
| Create shaders / VFX | `technical-artist` | 3 |
| Define visual style | `art-director` | 2 |
| Define audio style | `audio-director` | 2 |
| Design sound effects | `sound-designer` | 3 |
| Design UX flows | `ux-designer` | 3 |
| Write test cases | `qa-tester` | 3 |
| Plan test strategy | `qa-lead` | 2 |
| Profile performance | `performance-analyst` | 3 |
| Set up CI/CD | `devops-engineer` | 3 |
| Design analytics | `analytics-engineer` | 3 |
| Check accessibility | `accessibility-specialist` | 3 |
| Plan live operations | `live-ops-designer` | 3 |
| Manage a release | `release-manager` | 2 |
| Manage localization | `localization-lead` | 2 |
| Prototype quickly | `prototyper` | 3 |
| Audit security | `security-engineer` | 3 |
| Communicate with players | `community-manager` | 3 |
| Godot-specific help | `godot-specialist` | 3 |
| GDScript-specific help | `godot-gdscript-specialist` | 3 |
| Godot shader help | `godot-shader-specialist` | 3 |
| GDExtension modules | `godot-gdextension-specialist` | 3 |
| Unity-specific help | `unity-specialist` | 3 |
| Unity DOTS/ECS | `unity-dots-specialist` | 3 |
| Unity shaders/VFX | `unity-shader-specialist` | 3 |
| Unity Addressables | `unity-addressables-specialist` | 3 |
| Unity UI Toolkit | `unity-ui-specialist` | 3 |
| Unreal-specific help | `unreal-specialist` | 3 |
| Unreal GAS | `ue-gas-specialist` | 3 |
| Unreal Blueprints | `ue-blueprint-specialist` | 3 |
| Unreal replication | `ue-replication-specialist` | 3 |
| Unreal UMG/CommonUI | `ue-umg-specialist` | 3 |

### Agent Hierarchy

```
                    creative-director / technical-director / producer
                                         |
          ---------------------------------------------------------------
          |            |           |           |          |        |       |
    game-designer  lead-prog  art-dir  audio-dir  narr-dir  qa-lead  release-mgr
          |            |           |           |          |        |        |
     specialists  programmers  tech-art  snd-design  writer   qa-tester  devops
     (systems,    (gameplay,             (sound)     (world-  (perf,     (analytics,
      economy,     engine,                           builder)  access.)   security)
      level)       ai, net,
                   ui, tools)
```

**Escalation rule:** If two agents disagree, go up. Design conflicts go to
`creative-director`. Technical conflicts go to `technical-director`. Scope
conflicts go to `producer`.

---

## Appendix B: Slash Command Quick-Reference

### All 73 Commands by Category

#### Onboarding and Navigation (6)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/start` | Guided onboarding, routes to right workflow | Any (first session) |
| `/help` | Context-aware "what do I do next?" | Any |
| `/project-stage-detect` | Full project audit to determine current phase | Any |
| `/setup-engine` | Configure engine, pin version, set preferences | 1 |
| `/adopt` | Brownfield audit and migration plan | Any (existing projects) |
| `/skill-improve` | Improve a skill via test-fix-retest loop | Any |

#### Game Design (6)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/brainstorm` | Collaborative ideation with MDA analysis | 1 |
| `/map-systems` | Decompose concept into systems index | 1-2 |
| `/design-system` | Guided section-by-section GDD authoring | 2 |
| `/quick-design` | Lightweight spec for small changes | 2+ |
| `/review-all-gdds` | Cross-GDD consistency and design theory review | 2 |
| `/propagate-design-change` | Find ADRs/stories affected by GDD changes | 5 |

#### UX and Interface (2)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/ux-design` | Author UX specs (screen/flow, HUD, patterns) | 4 |
| `/ux-review` | Validate UX specs for accessibility and GDD alignment | 4 |

#### Architecture (4)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/create-architecture` | Master architecture document | 3 |
| `/architecture-decision` | Create or retrofit an ADR | 3 |
| `/architecture-review` | Validate all ADRs, dependency ordering | 3 |
| `/create-control-manifest` | Flat programmer rules from Accepted ADRs | 3 |

#### Stories and Sprints (8)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/create-epics` | Translate GDDs + ADRs into epics (one per module) | 4 |
| `/create-stories` | Break a single epic into story files | 4 |
| `/dev-story` | Implement a story — routes to the correct programmer agent | 5 |
| `/sprint-plan` | Create or manage sprint plans | 4-5 |
| `/sprint-status` | Quick 30-line sprint snapshot | 5 |
| `/story-readiness` | Validate story is implementation-ready | 4-5 |
| `/story-done` | 8-phase story completion review | 5 |
| `/estimate` | Effort estimation with risk assessment | 4-5 |

#### Reviews and Analysis (13)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/design-review` | Validate GDD against 8-section standard | 1-2 |
| `/code-review` | Architectural code review | 5+ |
| `/balance-check` | Game balance formula analysis | 5-6 |
| `/asset-audit` | Asset naming, format, size verification | 6 |
| `/asset-spec` | Per-asset visual specs and AI generation prompts | 5-6 |
| `/content-audit` | GDD-specified content vs. implemented | 5 |
| `/consistency-check` | Cross-GDD entity and formula inconsistency scan | 2+ |
| `/scope-check` | Scope creep detection | 5 |
| `/perf-profile` | Performance profiling workflow | 6 |
| `/tech-debt` | Tech debt scanning and prioritization | 6 |
| `/gate-check` | Formal phase gate with PASS/CONCERNS/FAIL | All transitions |
| `/reverse-document` | Generate design docs from existing code | Any |
| `/security-audit` | Security vulnerability audit (save, network, input) | 6-7 |

#### QA and Testing (9)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/qa-plan` | Generate QA test plan for a sprint or feature | 5 |
| `/smoke-check` | Critical path smoke test gate before QA hand-off | 5-6 |
| `/soak-test` | Soak test protocol for extended play sessions | 6 |
| `/regression-suite` | Map test coverage, identify fixed bugs lacking regression tests | 5-6 |
| `/test-setup` | Scaffold test framework and CI/CD pipeline | 4 |
| `/test-helpers` | Generate engine-specific test helper libraries | 4-5 |
| `/test-evidence-review` | Quality review of test files and manual evidence | 5 |
| `/test-flakiness` | Detect non-deterministic tests from CI logs | 5-6 |
| `/skill-test` | Validate skill files for structural and behavioral correctness | Any |

#### Production Management (6)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/milestone-review` | Milestone progress and go/no-go | 5 |
| `/retrospective` | Sprint retrospective analysis | 5 |
| `/bug-report` | Structured bug report creation | 5+ |
| `/bug-triage` | Re-evaluate open bugs for priority, severity, and owner | 5+ |
| `/playtest-report` | Structured playtest session report | 4-6 |
| `/onboard` | Onboard a new team member | Any |

#### Release (6)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/release-checklist` | Pre-release validation | 7 |
| `/launch-checklist` | Full cross-department launch readiness | 7 |
| `/changelog` | Auto-generate internal changelog | 7 |
| `/patch-notes` | Player-facing patch notes | 7 |
| `/hotfix` | Emergency fix workflow | 7+ |
| `/day-one-patch` | Scoped patch for issues found after gold master | 7+ |

#### Creative (4)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/prototype` | Concept prototype — validate core idea before GDDs | 1 |
| `/art-bible` | Guided Art Bible authoring — visual identity spec | 1-2 |
| `/vertical-slice` | Production-quality end-to-end build before Production | 4 |
| `/localize` | String extraction and validation | 6-7 |

#### Team Orchestration (9)

| Command | Purpose | Phase |
|---------|---------|-------|
| `/team-combat` | Combat feature: design through implementation | 5 |
| `/team-narrative` | Narrative content: structure through dialogue | 5 |
| `/team-ui` | UI feature: UX spec through polished implementation | 5 |
| `/team-level` | Level: layout through dressed encounters | 5 |
| `/team-audio` | Audio: direction through implemented events | 5-6 |
| `/team-polish` | Coordinated polish: perf + art + audio + QA | 6 |
| `/team-release` | Release coordination: build + QA + deployment | 7 |
| `/team-live-ops` | Live-ops planning: seasonal events, battle pass, retention | 7+ |
| `/team-qa` | Full QA cycle: strategy, execution, coverage, sign-off | 6-7 |

---

## Appendix C: Common Workflows

### Workflow 1: "I just started and have no game idea"

```
1. /start (routes you based on where you are)
2. /brainstorm (collaborative ideation, pick a concept)
3. /setup-engine (pin engine and version)
4. /design-review on concept doc (optional, recommended)
5. /map-systems (decompose concept into systems with deps and priorities)
6. /gate-check concept (verify you're ready for Systems Design)
7. /design-system per system (guided GDD authoring)
```

### Workflow 2: "I have designs and want to start coding"

```
1. /design-review on each GDD (make sure they're solid)
2. /review-all-gdds (cross-GDD consistency)
3. /gate-check systems-design
4. /create-architecture + /architecture-decision (per major decision)
5. /architecture-review
6. /create-control-manifest
7. /gate-check technical-setup
8. /create-epics layer: foundation + /create-stories [slug] (define epics, break into stories)
9. /sprint-plan new
10. /story-readiness -> implement -> /story-done (story lifecycle)
```

### Workflow 3: "I need to add a complex feature mid-production"

```
1. /design-system or /quick-design (depending on scope)
2. /design-review to validate
3. /propagate-design-change if modifying existing GDDs
4. /estimate for effort and risk
5. /team-combat, /team-narrative, /team-ui, etc. (appropriate team skill)
6. /story-done when complete
7. /balance-check if it affects game balance
```

### Workflow 4: "Something broke in production"

```
1. /hotfix "description of the issue"
2. Fix is implemented on hotfix branch
3. /code-review the fix
4. Run tests
5. /release-checklist for hotfix build
6. Deploy and backport
```

### Workflow 5: "I have an existing project and want to use this system"

```
1. /start (choose Path D -- existing work)
2. /project-stage-detect (determines current phase)
3. /adopt (audits existing artifacts, builds migration plan)
4. /design-system retrofit [path] (fill GDD gaps)
5. /architecture-decision retrofit [path] (fill ADR gaps)
6. /gate-check at appropriate transition
```

### Workflow 6: "Starting a new sprint"

```
1. /retrospective (review last sprint)
2. /sprint-plan new (create next sprint)
3. /scope-check (ensure scope is manageable)
4. /story-readiness per story before pickup
5. Implement stories
6. /story-done per completed story
7. /sprint-status for quick progress checks
```

### Workflow 7: "Shipping the game"

```
1. /gate-check polish (verify Polish phase is complete)
2. /tech-debt (decide what's acceptable at launch)
3. /localize (final localization pass)
4. /release-checklist v1.0.0
5. /launch-checklist (full cross-department validation)
6. /team-release (coordinate the release)
7. /patch-notes and /changelog
8. Ship!
9. /hotfix if anything breaks post-launch
10. Post-mortem after launch stabilizes
```

### Workflow 8: "I'm lost / don't know what to do next"

```
1. /help (reads your phase, checks artifacts, tells you what's next)
2. If /help doesn't help: /project-stage-detect (full audit)
3. If stage seems wrong: /gate-check at the transition you think you're at
```

---

## Tips for Getting the Most Out of the System

1. **Always start with design, then implement.** The agent system is built
   around the assumption that a design document exists before code is written.
   Agents reference GDDs constantly.

2. **Use team skills for cross-cutting features.** Do not try to manually
   coordinate 4 agents yourself -- let `/team-combat`, `/team-narrative`,
   etc. handle the orchestration.

3. **Trust the rules system.** When a rule flags something in your code, fix
   it. The rules encode hard-won game development wisdom (data-driven values,
   delta time, accessibility, etc.).

4. **Compact proactively.** At ~65-70% context usage, compact or `/clear`.
   The pre-compact hook saves your progress. Do not wait until you are at the
   limit.

5. **Use the right tier of agent.** Do not ask `creative-director` to write a
   shader. Do not ask `qa-tester` to make design decisions. The hierarchy
   exists for a reason.

6. **Run /help when uncertain.** It reads your actual project state and tells
   you the single most important next step.

7. **Run `/design-review` before handing designs to programmers.** This
   catches incomplete specs early, saving rework.

8. **Run `/code-review` after every major feature.** Catch architectural
   issues before they propagate.

9. **Prototype risky mechanics first.** A day of prototyping can save a week
   of production on a mechanic that does not work.

10. **Keep your sprint plans honest.** Use `/scope-check` regularly. Scope
    creep is the number one killer of indie games.

11. **Document decisions with ADRs.** Future-you will thank present-you for
    recording *why* things were built the way they were.

12. **Use the story lifecycle religiously.** `/story-readiness` before pickup,
    `/story-done` after completion. This catches deviations early and keeps
    the pipeline honest.

13. **Write to files early and often.** Incremental section writing means your
    design decisions survive crashes and compactions. The file is the memory,
    not the conversation.
