# Claude Code Game Studios -- Complete Workflow Guide

> **How to go from zero to a shipped game using the Agent Architecture.**
>
> This guide walks you through every phase of game development using the
> 48-agent system, 37 slash commands, and automated hooks. It assumes you
> have Claude Code installed and are working from the project root.

---

## Table of Contents

1. [Phase 0: Setup & Configuration](#phase-0-setup--configuration)
2. [Phase 1: Ideation & Concept](#phase-1-ideation--concept)
3. [Phase 2: Pre-Production & Design](#phase-2-pre-production--design)
4. [Phase 3: Prototyping & Validation](#phase-3-prototyping--validation)
5. [Phase 4: Production Sprint Workflow](#phase-4-production-sprint-workflow)
6. [Phase 5: Implementation Deep-Dive](#phase-5-implementation-deep-dive)
7. [Phase 6: Testing & Quality Assurance](#phase-6-testing--quality-assurance)
8. [Phase 7: Polish & Optimization](#phase-7-polish--optimization)
9. [Phase 8: Localization & Accessibility](#phase-8-localization--accessibility)
10. [Phase 9: Release & Launch](#phase-9-release--launch)
11. [Phase 10: Post-Launch & Live Ops](#phase-10-post-launch--live-ops)
12. [Appendix A: Agent Quick-Reference](#appendix-a-agent-quick-reference)
13. [Appendix B: Slash Command Quick-Reference](#appendix-b-slash-command-quick-reference)
14. [Appendix C: Common Workflows](#appendix-c-common-workflows)

---

## Phase 0: Setup & Configuration

### What You Need

Before you start, make sure you have:

- **Claude Code** installed and working
- **Git** with Git Bash (Windows) or standard terminal (Mac/Linux)
- **jq** (optional but recommended -- hooks fall back to `grep` if missing)
- **Python 3** (optional -- some hooks use it for JSON validation)

### Step 0.1: Clone and Configure

Clone the repository and open it in your editor:

```bash
git clone <repo-url> my-game
cd my-game
```

### Step 0.2: Run /start (Recommended for New Users)

If you're new to the project or don't yet know what game you're building:

```
/start
```

This guided onboarding asks where you are (no idea, vague idea, clear concept,
existing work) and routes you to the right phase. Skip this if you already have
a game concept and engine decision.

### Step 0.3: Choose Your Engine

Run `/setup-engine` in Claude Code. This is the single most important
configuration step -- it tells every agent what engine, language, and toolchain
you're using:

```bash
/setup-engine godot 4.6
```

Or run `/setup-engine` with no arguments to get an interactive recommendation
based on your game's needs (2D/3D, platforms, team size, language preferences).

**What `/setup-engine` does:**

- Pins the engine and version in `CLAUDE.md`
- Populates `.claude/docs/technical-preferences.md` with naming conventions,
  performance budgets, and engine-specific defaults
- Detects knowledge gaps (engine version newer than LLM training data) and
  fetches current docs from the web so agents suggest correct APIs
- Creates version-pinned reference docs in `docs/engine-reference/`

**Why this matters:** Once you set the engine, the system knows which
engine-specialist agents to use. If you pick Godot, agents like
`godot-specialist`, `godot-gdscript-specialist`, and `godot-shader-specialist`
become your go-to experts. The Unity and Unreal specialists remain available
but won't be primary.

> **Manual alternative:** You can also edit the Technology Stack section in
> `CLAUDE.md` directly if you prefer.

### Step 0.3: Verify Hooks Are Working

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

### Step 0.4: Create Your Directory Structure

The directories listed in `CLAUDE.md` don't all exist yet. Create them as
needed -- the system expects this layout:

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
```

> **Tip:** You don't need all of these on day one. Create directories as you
> reach the phase that needs them. The important thing is to follow this
> structure when you do create them, because the **rules system** enforces
> standards based on file paths. Code in `src/gameplay/` gets gameplay rules,
> code in `src/ai/` gets AI rules, and so on.

---

## Phase 1: Ideation & Concept

### What Happens in This Phase

You go from "no idea" or "vague idea" to a structured game concept document.
This is where you figure out **what** you're making.

> **Tip:** If you ran `/start` in Phase 0 and chose Path A or B, you're already
> here. `/start` routes you to `/brainstorm` automatically.

### Step 1.1: Brainstorm With `/brainstorm`

This is your starting point if you skipped `/start`. Run the brainstorm skill:

```
/brainstorm
```

Or with a genre hint:

```
/brainstorm roguelike deckbuilder
```

**What happens:** The brainstorm skill guides you through a collaborative 6-phase
ideation process using professional studio techniques:

Agent: "Let's explore game concepts. What genre or theme interests you? (Optional,
       or leave blank for open exploration)"

User: "Roguelike deckbuilder"

Agent: "I've generated 10 concept seeds combining roguelike and deckbuilder mechanics.
       Here are the top 3:

       **Concept A: Spell Compiler** - Code-themed deckbuilder where cards are functions
       **Concept B: Memory Palace** - Psychological thriller where cards are memories
       **Concept C: Ecosystem Builder** - Nature theme where cards are species

       Which concept(s) would you like me to develop with MDA analysis?"

User: "Concept B sounds unique"

Agent: [Performs MDA Analysis, Player Motivation mapping, Audience Targeting, Verb-First
       Design for Concept B, showing work at each stage and asking for feedback]

       "Here's the complete analysis. Should I formalize this into a structured
       concept document?"

User: "Yes"

Agent: [Creates structured concept document with top ideas, target audience,
       core mechanics, and emotional goals]

### Step 1.2: Document the Winning Concept

Take the brainstorm output and formalize it. Use the **game concept template**:

```
Ask Claude to create a game concept document using the template at
.claude/docs/templates/game-concept.md
```

This template includes:
- Elevator pitch (one sentence)
- Core fantasy (what the player imagines themselves doing)
- MDA breakdown
- Target audience (Bartle types, demographics)
- Core loop diagram
- Unique selling proposition
- Comparable titles and differentiation

### Step 1.3: Define Your Game Pillars

Before you go further, lock in your **game pillars** -- the 3-5 non-negotiable
design values that guide every decision. Use the template:

```
Ask Claude to create a game pillars document using the template at
.claude/docs/templates/game-pillars.md
```

Example pillars:
- **Meaningful Choices**: Every decision changes something permanently
- **Emergent Storytelling**: Systems create unique narratives, not scripts
- **Accessible Depth**: Easy to start, deep to master

Also define **anti-pillars** -- things your game intentionally avoids:
- We do NOT pursue: photorealism, competitive balance, linear narrative

> **When you're happy with your concept and pillars, you're ready for
> Pre-Production.**

---

## Phase 2: Pre-Production & Design

### What Happens in This Phase

You create all the design documents that define how your game works. Nothing
gets coded yet -- this is pure design and architecture.

### Step 2.1: Decompose Your Concept Into Systems

Before writing individual GDDs, enumerate all the systems your game needs:

```
/map-systems
```

This creates `design/gdd/systems-index.md` — a master tracking document that:

- Lists every system your game needs (combat, movement, UI, etc.)
- Maps dependencies between systems
- Assigns priority tiers (MVP, Vertical Slice, Alpha, Full Vision)
- Determines design order (Foundation → Core → Feature → Presentation → Polish)

Then design each system in dependency order:

```
/map-systems next
```

This picks the highest-priority undesigned system and hands off to `/design-system`,
which guides you through creating its GDD section by section. Each completed GDD
goes through `/design-review` before the next starts.

You can also write a specific system's GDD directly:

```
/design-system combat-system
```

### Step 2.2: Create the Game Design Document (GDD)

For each major system in your game, create a design document in `design/gdd/`.
Use the template:

```
Ask Claude to create a GDD using the template at
.claude/docs/templates/game-design-document.md
```

**The `design-docs` rule** (`.claude/rules/design-docs.md`) requires every GDD
to have these 8 sections:

| # | Section | What Goes Here |
|---|---------|---------------|
| 1 | **Overview** | One-paragraph summary of the system |
| 2 | **Player Fantasy** | What the player imagines/feels when using this system |
| 3 | **Detailed Rules** | Unambiguous mechanical rules -- if two designers read this, they'd build the same thing |
| 4 | **Formulas** | Every calculation, with variable definitions and ranges |
| 5 | **Edge Cases** | What happens in weird situations? Explicitly resolved. |
| 6 | **Dependencies** | What other systems this connects to (bidirectional) |
| 7 | **Tuning Knobs** | Which values designers can safely change, with safe ranges |
| 8 | **Acceptance Criteria** | How do you test that this works? Specific, measurable. |

**Example GDD files you might create:**
- `design/gdd/core-loop.md` -- The fundamental play loop
- `design/gdd/combat-system.md` -- How combat works
- `design/gdd/progression-system.md` -- How the player advances
- `design/gdd/inventory-system.md` -- Item management
- `design/gdd/ability-system.md` -- Player abilities and skills

### Step 2.2: Use the Game Designer Agent for Complex Mechanics

For systems that need deep mechanical thinking, delegate to `game-designer`:

```
Ask the game-designer agent to design a crafting system that supports
emergent recipes (players discover combinations) with a skill progression
tied to experimentation. The system should feel rewarding without being
grindy. Target audience is Explorers and Achievers.
```

**What happens:** The `game-designer` agent collaborates with you to create the design:

Agent: "I'll help design the crafting system. First, some questions:
       - Should recipes be discovered through experimentation or taught explicitly?
       - How punishing should failed crafting attempts be?
       - Target audience - primarily Explorers or Achievers?"

User: "Discovered through experimentation. Moderate punishment - waste ingredients
      but gain partial skill XP. Target Explorers primarily."

Agent: "Based on that, here are three mechanical approaches:

       **Option A: Pure Discovery** - No hints, full freedom
       Pros: Maximum exploration reward
       Cons: High frustration risk, may need wiki

       **Option B: Hint System** - Visual cues when ingredients are compatible
       Pros: Guided exploration, less frustration
       Cons: Less satisfying 'eureka' moments

       **Option C: Hybrid** - Free experimentation + optional journal hints unlocked by skill
       Pros: Supports both playstyles, progressive scaffolding
       Cons: More complex to implement

       I recommend Option C because it respects Explorers while providing safety nets,
       and the journal hints can be gated behind skill progression for Achievers.
       Which approach fits your vision?"

User: "Option C sounds perfect"

Agent: [Drafts GDD sections iteratively - Overview, Player Fantasy, Detailed Rules,
       Formulas, Edge Cases - showing each and incorporating feedback]

       "I need detailed formula work for success rates and skill progression curves.
       Let me consult the systems-designer for the math."

Agent: [After consultation] "Complete draft ready with formulas validated by
       systems-designer. The economy-designer flagged that ingredient costs
       need balancing - I've incorporated their recommendations.

       May I write this to design/gdd/crafting-system.md?"

User: "Yes"

Agent: [Writes file]

### Step 2.3: Design Review

Before any design doc goes to programmers, run a review:

```
/design-review design/gdd/crafting-system.md
```

**What happens:** The skill checks the document against the 8-section
standard, verifying:
- Are all sections present and complete?
- Are formulas unambiguous with defined variables?
- Are edge cases explicitly resolved (not "TBD")?
- Do dependencies list both directions?
- Are acceptance criteria testable?

Fix any issues flagged before proceeding.

### Step 2.4: Create Narrative Design (if applicable)

If your game has story, lore, or dialogue, this is when you build it:

1. **World-building** -- Use `world-builder` to define factions, history,
   geography, and rules of your world
2. **Story structure** -- Use `narrative-director` to design story arcs,
   character arcs, and narrative beats
3. **Character sheets** -- Use the `narrative-character-sheet.md` template
   for each major character

The `narrative` rule (`.claude/rules/narrative.md`) enforces:
- Lore consistency across documents
- Canon levels (Core Canon vs Flavor vs Apocrypha)
- Character voice profiles
- World rule documentation

### Step 2.5: Technical Architecture

Before coding starts, make key technical decisions:

```
/architecture-decision "State Machine vs Behavior Tree for NPC AI"
```

**What happens:** The skill guides you through creating an Architecture Decision Record:

Agent: "I'll help document this architectural decision. First, let me understand
       the context. What's driving this decision right now?"

User: "We need to choose between state machine and behavior tree for NPC AI.
      We have 50+ enemy types planned."

Agent: "Given 50+ enemy types, here's my analysis:

       **Option A: Finite State Machine**
       Pros: Simple, debuggable, less overhead
       Cons: Becomes unwieldy with complex behaviors, hard to reuse logic

       **Option B: Behavior Tree**
       Pros: Highly reusable, scales well, visual debugging
       Cons: Steeper learning curve, slightly more overhead

       **Option C: Utility AI**
       Pros: Emergent behaviors, dynamic decision-making
       Cons: Harder to debug, needs careful tuning

       For 50+ types, I recommend Behavior Trees - the reusability and
       scalability outweigh the learning curve.

       Should I create an ADR documenting this decision?"

User: "Yes, go with Behavior Trees"

Agent: [Creates ADR in docs/architecture/ with context, decision drivers,
       all options with pros/cons, chosen option with rationale, and consequences]

**For complex architectural decisions, use the `technical-director` agent:**

```
Ask the technical-director agent to evaluate whether we should use an
ECS architecture or a traditional component system for our gameplay
entities, considering our team size (solo) and engine choice (Godot 4).
```

Agent: "Let me analyze the ECS vs traditional component decision for your context:

       [Performs detailed analysis considering Godot 4's scene system, solo dev
       workflow, learning curve, debugging tools, performance needs]

       **Recommendation: Traditional Godot node-based components**

       Reasoning: [Detailed rationale]

       Shall I create an ADR documenting this decision with full analysis?"

User: "Yes"

Agent: [Creates comprehensive ADR]

### Step 2.6: Milestone Planning

Define your project milestones using the template:

```
Ask Claude to create a milestone definition using the template at
.claude/docs/templates/milestone-definition.md
```

Typical indie milestones:
1. **Vertical Slice** -- One level, fully playable, representative quality
2. **Alpha** -- All core systems functional, placeholder art OK
3. **Beta** -- Content complete, all features in, polishing begins
4. **Release Candidate** -- Bug fixes only, ready for launch
5. **Gold** -- Ship it

> **When all your design documents are reviewed and your architecture is
> decided, you're ready to start building.**

---

## Phase 3: Prototyping & Validation

### What Happens in This Phase

Before committing to full production, you validate risky or uncertain
mechanics with throwaway prototypes. This saves weeks of wasted production
effort.

### Step 3.1: Identify What Needs Prototyping

Not everything needs a prototype. Prototype when:
- A mechanic is novel and you're not sure it's fun
- A technical approach is risky and you're not sure it's feasible
- Two design options both seem viable and you need to feel the difference

### Step 3.2: Run the Prototype Skill

```
/prototype "grappling hook movement with momentum"
```

**What happens:** The skill collaborates with you to set up the prototype:

Agent: "Let's prototype the grappling hook movement. First, let me clarify the
       hypothesis we're testing:

       - Are we testing if momentum-based grappling feels good?
       - Or testing technical feasibility of the physics?
       - Or comparing different control schemes?

       What's the core question this prototype needs to answer?"

User: "Testing if momentum transfer feels satisfying and creates skill expression"

Agent: "Got it. Here's my proposed setup:

       **Hypothesis**: Grappling hook with momentum transfer will feel satisfying
       and create emergent movement options through skill-based physics manipulation

       **Success Criteria**:
       - Player can chain 3+ grapple points fluidly without losing momentum
       - Momentum feels predictable enough to plan, expressive enough to surprise
       - Players discover unintended movement tricks within 5 minutes

       **Prototype Scope** (1-2 hours max):
       - Basic grapple point attachment
       - Momentum calculation and transfer
       - Simple test level with various grapple configurations
       - No art, UI, or sounds - pure mechanics

       Does this match what you want to validate?"

User: "Perfect, but add one more criteria: can we swing around corners"

Agent: "Updated success criteria to include corner swinging. Should I create
       prototypes/grappling-hook/ and implement this?"

User: "Yes"

Agent: [Creates directory structure, README with hypothesis/criteria/status,
       delegates to prototyper agent for minimal implementation]

**Key rule:** The `prototype-code` rule (`.claude/rules/prototype-code.md`)
intentionally relaxes coding standards for prototypes - hardcoded values OK,
no tests required, but README with hypothesis and findings is mandatory.

### Step 3.3: Evaluate the Prototype

Play/test the prototype and answer:
- Does the hypothesis hold? Is it fun / feasible / better?
- What surprised you?
- What would change for production?

Update the prototype README with findings and a **verdict**: Ship It, Rework,
or Kill It.

### Step 3.4: Run a Playtest Report

If you had others test the prototype:

```
/playtest-report
```

This generates a structured report template covering:
- Tester demographics and context
- Task completion rates
- Confusion points and friction
- Moments of delight
- Quantitative ratings
- Prioritized takeaways

> **When your prototypes have validated (or invalidated) your riskiest
> assumptions, you're ready for production.**

---

## Phase 4: Production Sprint Workflow

### What Happens in This Phase

This is the core production loop. You work in sprints (typically 1-2 weeks),
implementing features, fixing bugs, and tracking progress. This phase repeats
until your game is content-complete.

### Step 4.1: Create Your First Sprint

```
/sprint-plan new
```

**What happens:** The skill delegates to `producer` to collaborate on sprint planning:

Agent: "Let's plan your sprint. First, what's your primary goal for this sprint?
       (One sentence that defines success)"

User: "Implement core combat system with basic attacks and health"

Agent: "How much time do you have available this sprint? (hours or days)"

User: "20 hours over 2 weeks"

Agent: "Based on 'core combat system' I'm breaking this into tasks. Here's my
       proposed structure:

       **Must Have** (sprint fails without these):
       - Damage calculation system (design/gdd/combat-system.md formulas)
       - Health component with damage handling
       - Basic attack input and execution
       - Unit tests for damage calculation

       **Should Have** (important but can slip):
       - Hit reactions and feedback VFX
       - Death state handling
       - Combat stat data files

       **Nice to Have** (if time permits):
       - Attack combo system
       - Damage numbers UI

       **Risks I see**:
       - No combat design doc exists yet (blocker - need to create first)
       - VFX requires technical-artist involvement

       Does this task breakdown match your vision? Any tasks to add/remove/reprioritize?"

User: "Move combo system to Should Have - it's important for feel"

Agent: "Updated. Should I create production/sprints/sprint-01.md with this plan?"

User: "Yes"

Agent: [Creates sprint plan with goal, categorized tasks, 20hr capacity estimate,
       risk register, and dependencies]

### Step 4.2: The Daily Work Loop

Each session follows this pattern:

```
1. Start a Claude Code session
   (session-start hook shows branch, sprint status, recent commits)

2. Pick a task from the sprint plan
   ("I'm working on the combat damage calculation system")

3. Claude identifies the right agent(s) to help
   - game-designer if the design needs work
   - gameplay-programmer for implementation
   - systems-designer for formula details

4. Implement the feature (see Phase 5 for details)

5. Write tests (verification-driven development)

6. Commit your work
   (validate-commit hook checks for design doc references,
    valid JSON data, no hardcoded values)

7. Repeat until the session's context is getting full (~65-70%)

8. /clear to start fresh, or compact to continue
```

### Step 4.3: Sprint Tracking

Check on sprint progress anytime:

```
/sprint-plan status
```

If scope is growing:

```
/scope-check production/sprints/sprint-03.md
```

This compares current scope against the original plan and flags:
- Tasks added since sprint start
- Scope increase percentage
- Recommendations for what to cut

### Step 4.4: Sprint Review & Retrospective

At the end of a sprint:

```
/retrospective
```

This analyzes:
- What was planned vs. what was completed
- Velocity (tasks/points completed)
- What went well
- What went poorly
- Blockers encountered
- Actionable improvements for next sprint

Then plan the next sprint:

```
/sprint-plan new
```

The new sprint incorporates carry-over tasks, retrospective learnings, and
updated priorities.

### Step 4.5: Milestone Reviews

At milestone checkpoints:

```
/milestone-review "alpha"
```

This produces a comprehensive report:
- Feature completeness percentage
- Quality metrics (bug counts, test coverage)
- Risk assessment
- Go/no-go recommendation
- Action items to reach the milestone

---

## Phase 5: Implementation Deep-Dive

### What Happens in This Phase

This is where code gets written. The agent system ensures code quality through
path-specific rules, automated hooks, and structured delegation.

### Step 5.1: Single-System Implementation

For a single gameplay system (e.g., "implement the damage calculation"):

```
Ask the gameplay-programmer agent to implement the damage calculation
system as specified in design/gdd/combat-system.md. The formulas are in
section 4. Use the project's data-driven approach with config files in
assets/data/.
```

**What happens:** The `gameplay-programmer` agent collaborates on implementation:

Agent: "I've read design/gdd/combat-system.md. Before implementing, I need to
       clarify a few details:

       Section 4 shows the damage formula: `base_damage * (1 + attack_stat * 0.1) * type_modifier`

       Questions:
       - Should attack_stat be clamped to a max value?
       - Where should type_modifiers live - per weapon or per damage type?
       - Do you want damage rounding (floor/ceil/round)?

       Also, I don't see a design doc for the health component yet. Should I
       create a minimal one or do you want to design that separately?"

User: "Clamp attack_stat to 0-100. Type modifiers per damage type. Round down.
      Create minimal health doc - just current/max HP and damage handling."

Agent: "Got it. Here's my implementation approach:

       **Files to create**:
       - src/gameplay/combat/damage_calculator.gd (core formula logic)
       - src/gameplay/combat/health_component.gd (HP tracking)
       - assets/data/combat_damage.json (base damage values, type modifiers)
       - design/gdd/health-system.md (minimal doc)

       **Architecture**:
       - DamageCalculator as stateless utility (testable)
       - HealthComponent as node component (signals for damage/death)
       - All values from config file (gameplay-code rule)

       May I proceed with implementation?"

User: "Yes"

Agent: [Implements with automatic rule enforcement - data-driven values, delta time
       independence, signal-based communication, dependency injection for testing]

       "Implementation complete. Files created:
       - src/gameplay/combat/damage_calculator.gd
       - src/gameplay/combat/health_component.gd
       - assets/data/combat_damage.json (validated JSON structure)
       - design/gdd/health-system.md

       Ready for testing. Should I draft unit tests?"

User: "Yes"

Agent: [Writes tests]

### Step 5.2: Multi-System Feature (Team Orchestration)

For features that span multiple domains, use a team skill:

```
/team-combat "healing ability with HoT (heal-over-time) and cleanse"
```

**What happens:** The team skill orchestrates collaborative 6-phase development:

**Phase 1 - Design**:
Agent (game-designer): "I'll design the healing ability. Questions:
       - Should HoT stack or refresh duration?
       - What debuffs should cleanse remove - all, or specific categories?
       - Mana cost scaling with heal amount?"

User: [Answers questions]

Agent: [Creates design doc, shows draft] "Design ready. Approve to proceed to architecture?"

User: "Approved"

**Phase 2 - Architecture**:
Agent (gameplay-programmer): "Here's my proposed code structure:
       - HealAbility class extending BaseAbility
       - HoT as separate buff component (reusable)
       - Cleanse as utility function (may be used elsewhere)

       This work or want changes?"

User: "Approved"

**Phase 3 - Parallel Implementation**:
Agent (coordinator): "Starting parallel implementation:
       - gameplay-programmer: HealAbility + HoT buff code
       - ai-programmer: AI logic for when NPCs should use heal
       - technical-artist: HoT VFX particle spec
       - sound-designer: Heal cast and HoT tick SFX spec

       I'll check back when all are complete."

[Each specialist asks clarifying questions and shows their work before finalizing]

**Phase 4 - Integration**:
Agent (gameplay-programmer): "All components ready. Integrating now..."
       [Shows integrated result] "Working in test scene. Ready for validation?"

**Phase 5 - Validation**:
Agent (qa-tester): "Testing against acceptance criteria from design doc..."
       [Reports results] "2 edge cases found: [details]. Should we fix or defer?"

User: "Fix the critical one, defer the other"

**Phase 6 - Report**:
Agent (coordinator): "Feature complete. Status:
       ✓ Design, architecture, implementation, integration done
       ✓ Critical bugs fixed
       - 1 minor edge case deferred to backlog
       Ready to merge."

Other team skills work similarly:
- `/team-narrative` -- Story content from structure to written dialogue
- `/team-ui` -- UI feature from wireframe to polished implementation
- `/team-level` -- Level from layout to fully dressed with encounters
- `/team-audio` -- Audio from direction to implemented events

### Step 5.3: AI Systems

For NPC behavior, pathfinding, or decision-making:

```
Ask the ai-programmer agent to implement a patrol/investigate/chase
behavior tree for enemy NPCs as specified in design/gdd/enemy-ai.md.
```

**What happens:** The `ai-programmer` agent asks clarifying questions before implementing:

Agent: "I've read design/gdd/enemy-ai.md. Before building the behavior tree, I need
       to clarify some behaviors:

       - During patrol, should NPCs stop at waypoints or continuous loop?
       - For investigate state: how long should they search before returning to patrol?
       - Chase transition: should they chase immediately on sight or require 'confirmation time'?
       - What happens if player breaks line-of-sight during chase?

       Also, I see performance budget is 2ms/frame for all AI. How many NPCs will
       be active simultaneously (worst case)?"

User: "Stop at waypoints for 2 seconds. Search for 8 seconds. Immediate chase on sight.
      Break LOS = return to last known position, search there, then investigate.
      Max 15 NPCs active."

Agent: "Got it. That gives me ~0.13ms per NPC. I'll use a hierarchical behavior tree
       with shared pathfinding queries to stay under budget.

       My approach:
       - Root selector: Chase > Investigate > Patrol
       - All timing/ranges from assets/data/enemy_ai.json (data-driven per ai-code rule)
       - Debug visualization showing current state + detection radius
       - Telegraph attacks with 0.5s windup (visible to player)

       Approve this approach?"

User: "Yes"

Agent: [Implements with rule enforcement: 2ms budget, data-driven params, debug viz,
       telegraphed intentions]

       "Implementation complete. Tested with 20 NPCs - running at 1.8ms/frame.
       Debug visualization shows state colors (green=patrol, yellow=investigate,
       red=chase). Ready for review?"

The `ai-code` rule automatically enforces performance budgets, data-driven parameters,
debug visualization, and player-fair behavior.

### Step 5.4: Engine-Specific Work

When you need engine-specific expertise:

```
# For Godot:
Ask the godot-specialist agent to review our scene tree architecture
and suggest improvements for performance and maintainability.

# For a specific subsystem:
Ask the godot-gdscript-specialist to refactor our signal architecture
to reduce coupling between the combat and UI systems.
```

Engine specialists know:
- Engine-specific patterns and anti-patterns
- Performance optimization techniques for that engine
- Proper use of engine subsystems (Godot signals, Unity Addressables, UE GAS)
- When to use native extensions vs scripting

### Step 5.5: Architecture Decision Records

When you face a significant technical choice during implementation:

```
/architecture-decision "Event Bus vs Direct Signals for System Communication"
```

This documents the decision so future-you (or future contributors) understand
*why* things were built this way.

### Step 5.6: Code Review

After implementing a feature:

```
/code-review src/gameplay/combat/damage_calculator.gd
```

**What happens:** The skill performs collaborative architectural review:

Agent: "Reviewing src/gameplay/combat/damage_calculator.gd...

       **Architectural Compliance**:
       ✓ Matches ADR-003 (stateless utility pattern)
       ✓ Data-driven values (gameplay-code rule)
       ✗ Issue: Direct reference to HealthComponent - breaks dependency injection

       **SOLID Principles**:
       ✓ Single Responsibility - only calculates damage
       ✗ Dependency Inversion - tightly coupled to HealthComponent type

       **Testability**:
       ✗ Hard to mock HealthComponent dependency

       **Performance**:
       ✓ No allocations in hot path
       ⚠ Warning: Type lookup in dictionary every call - consider caching

       **Recommendations**:
       1. HIGH: Add interface for HealthComponent to enable mocking
       2. MEDIUM: Cache type modifier lookups
       3. LOW: Add null checks for edge cases

       Should I show you how to fix issue #1 (dependency injection)?"

User: "Yes, show me"

Agent: [Shows refactored code with interface]

       "This change lets you pass any object with take_damage(), making it testable.
       Approve this refactor?"

User: "Approved"

Agent: [Applies changes] "Code review complete. All high-priority issues resolved."

---

## Phase 6: Testing & Quality Assurance

### What Happens in This Phase

Testing runs throughout production, not just at the end. The system supports
test-driven development with automated enforcement.

### Step 6.1: Write Tests First (Verification-Driven Development)

The project enforces **verification-driven development**: write tests before
or alongside implementation, not after.

The `test-standards` rule (`.claude/rules/test-standards.md`) enforces:
- Test naming: `test_[system]_[scenario]_[expected_result]`
- Structure: Arrange / Act / Assert
- No external state dependencies
- Tests clean up after themselves
- Each test file mirrors the source file it tests

```
Ask the qa-tester agent to write test cases for the damage calculation
system based on the acceptance criteria in design/gdd/combat-system.md.
```

**What happens:** The `qa-tester` agent collaborates on test case creation:

Agent: "I've read the acceptance criteria from design/gdd/combat-system.md. Before
       writing tests, let me confirm the test scope:

       From the acceptance criteria, I see:
       - Base damage formula must produce expected values
       - Type modifiers apply correctly
       - Edge case: attack_stat clamped at 0-100
       - Edge case: negative damage becomes 0

       Questions:
       - Should I include integration tests with HealthComponent or just unit tests?
       - Do you want performance tests (e.g., 1000 calculations < Xms)?
       - Any specific edge cases beyond those in the doc?"

User: "Unit tests only for now. Add performance test - target 10,000 calcs < 1ms.
      Also test what happens with invalid damage types."

Agent: "Got it. Here's my test plan:

       **Unit Tests**:
       - test_damage_basic_calculation (base formula, known values)
       - test_damage_type_modifiers (each modifier from config)
       - test_damage_attack_stat_clamping (below 0, above 100)
       - test_damage_negative_becomes_zero
       - test_damage_invalid_type (undefined type in config)
       - test_damage_rounding (verify floor behavior)

       **Performance Test**:
       - test_damage_performance_10k_calculations

       Approve this test suite?"

User: "Yes"

Agent: [Writes tests following test-standards rule: proper naming, Arrange/Act/Assert
       structure, no external dependencies, cleanup]

       "Test suite complete. All 7 tests written. Ready to run?"

### Step 6.2: Bug Reporting

When you find a bug:

```
/bug-report "Healing spell applies damage instead of healing when
target has a shield buff active"
```

This creates a structured bug report with:
- Severity (Critical / Major / Minor / Cosmetic)
- Priority (P0-P4)
- Steps to reproduce
- Expected vs actual behavior
- System/component affected
- Related design doc

### Step 6.3: Test Planning

For milestone validation:

```
Ask the qa-lead agent to create a test plan for the Alpha milestone,
covering combat, progression, and UI systems.
```

**What happens:** The `qa-lead` agent collaborates on comprehensive test planning:

Agent: "I'll create a test plan for the Alpha milestone. First, let me understand
       the scope:

       From the milestone definition, I see these systems are in scope:
       - Combat system
       - Progression system
       - UI systems

       Questions:
       - What platforms are we testing? (Windows, Linux, Mac, mobile?)
       - What's our target performance? (60fps? 30fps?)
       - Any known risky areas that need extra test coverage?
       - Timeline - when does testing need to complete?"

User: "Windows and Linux. Target 60fps. Combat AI is risky - lots of edge cases.
      Testing deadline is end of next week."

Agent: "Got it. Here's my proposed test plan structure:

       **Functional Tests** (3 days):
       - Combat: Damage calculation, status effects, death states, AI behavior
       - Progression: XP gain, level-up, skill unlocks, stat increases
       - UI: Menus, HUD, inventory, settings

       **Edge Case Tests** (1 day):
       - Combat AI: Line-of-sight breaks, pathfinding failures, stuck states
       - Boundary conditions: Max level, inventory full, negative damage

       **Regression Suite** (1 day):
       - Re-run all previous milestone tests

       **Performance Benchmarks** (1 day):
       - 60fps with 15 enemies, complex VFX
       - Memory under 2GB
       - Load times under 5s

       **Platform Tests** (1 day):
       - Windows 10/11
       - Ubuntu 22.04 LTS

       This fits the timeline. Approve or adjust?"

User: "Approved"

Agent: [Creates detailed test plan using test-plan.md template]

### Step 6.4: Balance Testing

After implementing economy or progression systems:

```
/balance-check assets/data/combat_damage.json
```

This analyzes your balance data for:
- Statistical outliers
- Broken progression curves
- Degenerate strategies (one option dominates all others)
- Economy imbalances (inflation, deflation, exploits)

---

## Phase 7: Polish & Optimization

### What Happens in This Phase

Your game is feature-complete. Now you make it *good*. This phase focuses on
performance, visual polish, audio, and feel.

### Step 7.1: Performance Profiling

```
/perf-profile
```

**What happens:** The skill guides you through structured performance profiling:

Agent: "Starting performance profiling. First, let's establish your targets:
       - Target FPS?
       - Target memory limit?
       - Target platform(s)?"

User: "60fps on mid-range PC. Under 2GB RAM. Windows/Linux."

Agent: "Running profiler on current build...

       **Current Performance**:
       - Average FPS: 48
       - Frame time: 20.8ms (target: 16.6ms for 60fps)
       - Memory: 2.4GB (400MB over target)

       **Bottlenecks Identified** (ranked by impact):
       1. Combat AI: 8.2ms/frame (49% of frame time) - HIGH PRIORITY
       2. Particle VFX: 3.1ms/frame (18% of frame time) - MEDIUM
       3. UI rendering: 2.8ms/frame (17% of frame time) - MEDIUM
       4. Physics: 1.9ms/frame (11% of frame time) - LOW

       **Memory Issues**:
       1. Texture atlas not compressed: +280MB - HIGH PRIORITY
       2. Audio buffers not streaming: +120MB - HIGH PRIORITY

       **Recommendations**:
       1. Combat AI: Implement hierarchical behavior tree, reduce per-frame checks
       2. Textures: Enable GPU compression
       3. Audio: Stream longer sounds instead of loading all

       Should I generate detailed optimization tasks for the top 3 issues?"

User: "Yes"

Agent: [Generates actionable optimization tasks with code locations and expected gains]

**For deeper analysis, use the `performance-analyst` agent:**

```
Ask the performance-analyst agent to analyze our combat system for
frame time spikes. We're seeing hitches when 10+ enemies are active.
```

Agent: "I'll analyze the combat system performance. Let me profile with varying
       enemy counts...

       **Analysis Results**:
       - 5 enemies: 58fps stable
       - 10 enemies: 52fps with occasional drops to 45fps
       - 15 enemies: 38fps with spikes down to 22fps

       **Root Cause**: Behavior tree re-evaluates entire tree every frame for
       every NPC. With 15 NPCs, that's 15 full tree traversals = 8.2ms.

       **Solution Options**:
       1. Stagger updates: Only update 5 NPCs per frame (rotation)
       2. Cache tree results: Re-evaluate only on state change
       3. Simplify tree: Reduce node count from 12 to 6

       I recommend Option 2 + 3: Cache results AND simplify the tree.
       Expected gain: 8.2ms -> 1.5ms (6.7ms saved = +40fps)

       Should I show you the refactored behavior tree?"

User: "Yes"

Agent: [Shows optimized implementation]

### Step 7.2: Visual Polish

Use the team polish skill for comprehensive polishing:

```
/team-polish "combat system"
```

**What happens:** The team polish skill coordinates collaborative polish passes:

Agent (coordinator): "Starting polish pass for combat system. Let me assess
       current state and identify polish priorities...

       **Current State Analysis**:
       - Performance: 48fps (needs optimization)
       - Visual feedback: Hit effects present but underwhelming
       - Audio: SFX in place but mixing needs work
       - Feel: Input response good, but impacts lack weight

       I'll coordinate 4 specialists in parallel. First, let me get your polish
       priorities - rank these:
       - Performance (hitting 60fps)
       - Visual impact (VFX, shaders, feedback)
       - Audio polish (mixing, spatial, punch)
       - Feel/juice (screen shake, hitstop, particles)"

User: "Performance #1, then visual impact, then feel, then audio"

**Phase 1 - Performance** (performance-analyst):
Agent: "Running combat performance optimization..."
       [Implements optimizations from previous profiling]
       "Now at 62fps stable. Performance target met."

**Phase 2 - Visual Impact** (technical-artist):
Agent: "Analyzing visual feedback. I see hit VFX but they're generic. Questions:
       - Should different damage types have distinct visual feedback?
       - Do you want critical hits to be visually distinct?
       - Screen shake on hits - subtle or pronounced?"

User: "Distinct per damage type. Crits should pop. Subtle screen shake."

Agent: [Creates polished VFX specifications and shader improvements]
       "VFX polish complete. Want to see a comparison video?"

**Phase 3 - Feel** (technical-artist + gameplay-programmer):
Agent: "Adding hitstop (frame freeze) on impacts, particle bursts on crits,
       subtle camera shake. Testing feel..."
       "Hitstop feels good at 100ms for normal hits, 200ms for crits. Approve?"

User: "Approved"

**Phase 4 - Validation** (qa-tester):
Agent: "Running regression tests on all combat polish changes..."
       "All tests pass. No bugs introduced."

Agent (coordinator): "Polish pass complete:
       ✓ Performance: 48fps -> 62fps
       ✓ Visual: Enhanced VFX, type-specific effects, crit feedback
       ✓ Feel: Hitstop, particles, camera shake
       ✓ Tests: All passing
       Ready to merge."

### Step 7.3: Audio Implementation

```
/team-audio "combat audio"
```

**What happens:** The team audio skill coordinates the full collaborative audio pipeline:

**Phase 1 - Audio Direction** (audio-director):
Agent: "Let's define the audio direction for combat. What's the emotional goal?
       - Brutal and visceral?
       - Tactical and precise?
       - Magical and fantastical?
       - Fast and arcade-like?"

User: "Tactical and precise with some weight to impacts"

Agent: "Got it. Here's my audio direction for combat:

       **Audio Pillars**:
       - Clarity: Every action has distinct, recognizable sound
       - Spatial awareness: Enemy positions clear from audio alone
       - Feedback: Successful actions feel satisfying
       - Atmosphere: Tension maintained without fatigue

       **Priorities**:
       1. Weapon sounds must be punchy but not fatiguing
       2. Footsteps critical for spatial awareness
       3. Enemy attack telegraphs via audio cues
       4. Hit confirmation with satisfying impact sounds

       Approve this direction?"

User: "Approved"

**Phase 2 - SFX Specification** (sound-designer):
Agent: "Based on the audio direction, here's my SFX event list:

       **Player Actions**:
       - weapon_swing_light, weapon_swing_heavy (distinct whoosh)
       - footstep_walk, footstep_run (material-aware)
       - ability_cast_start, ability_cast_release

       **Impacts**:
       - hit_flesh_light, hit_flesh_heavy (with pitch variation)
       - hit_armor_deflect (metallic ping)
       - critical_hit (special layered impact)

       **Enemy Audio**:
       - enemy_attack_windup (0.5s telegraph)
       - enemy_footstep (louder than player for spatial awareness)

       Each sound has variation pool (3-5 variants) to avoid repetition.
       Missing anything critical?"

User: "Add dodge/roll sound"

Agent: "Added dodge_roll event. Complete SFX spec ready."

**Phase 3 - Audio Implementation** (technical-artist):
Agent: "Implementing audio system with:
       - Event-based triggers (no hardcoded audio calls)
       - 3D spatial audio with distance attenuation
       - Priority system (critical sounds never cut off)
       - Dynamic mixing (combat music layer + SFX balance)

       Questions:
       - Max simultaneous sounds limit? (recommend 32)
       - Distance attenuation curve - linear or logarithmic?"

User: "32 sounds max. Logarithmic attenuation."

Agent: [Implements audio middleware integration]

**Phase 4 - Integration** (gameplay-programmer):
Agent: "Wiring audio events to gameplay code...
       - Weapon swings: Connected to animation events
       - Footsteps: Tied to movement speed and surface type
       - Impacts: Hooked to damage events
       - Enemy telegraphs: 0.5s before attack execution

       Ready for audio playtest."

Agent (coordinator): "Combat audio pipeline complete. Test in-game and provide feedback
       on balance, clarity, and feel."

### Step 7.4: Technical Debt

Before release, assess your tech debt:

```
/tech-debt
```

This scans the codebase for:
- TODO/FIXME/HACK comments
- Code duplication
- Overly complex functions
- Missing tests
- Outdated dependencies

Each debt item gets categorized and prioritized. You decide what to fix
before release vs. what to defer.

---

## Phase 8: Localization & Accessibility

### Step 8.1: Localization Scan

```
/localize src/
```

This scans for:
- Hardcoded strings that should be externalized
- String concatenation that breaks translation
- Text that doesn't account for expansion (German text is ~30% longer)
- Missing locale files

### Step 8.2: Accessibility Review

```
Ask the accessibility-specialist agent to audit our UI system for
WCAG compliance, colorblind support, and input remapping.
```

The `ui-code` rule already enforces some accessibility:
- Localization-ready strings (no hardcoded text)
- Keyboard and gamepad input support
- Text scaling support
- Colorblind-friendly design

The `accessibility-specialist` goes deeper:
- Screen reader compatibility
- Key remapping completeness
- Subtitle and caption support
- Motion sensitivity options
- Difficulty/assist options

---

## Phase 9: Release & Launch

### What Happens in This Phase

Your game is polished, tested, and ready. Now you ship it.

### Step 9.1: Release Checklist

```
/release-checklist v1.0.0
```

This generates a comprehensive pre-release checklist covering:
- Build verification (all platforms compile and run)
- Certification requirements (platform-specific)
- Store metadata (descriptions, screenshots, trailers)
- Legal compliance (EULA, privacy policy, ratings)
- Save game compatibility
- Analytics and telemetry verification

### Step 9.2: Launch Readiness (Full Validation)

```
/launch-checklist
```

This is the nuclear option -- a complete cross-department validation:

| Department | What's Checked |
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

### Step 9.3: Generate Player-Facing Content

```
/patch-notes v1.0.0
```

Generates player-friendly patch notes from git history and internal data.
Translates developer language ("refactored state machine") into player
language ("improved enemy behavior responsiveness").

```
/changelog v1.0.0
```

Generates an internal changelog (more technical, for the team).

### Step 9.4: Coordinate the Release

```
/team-release
```

**What happens:** The team release skill coordinates all departments for launch:

**Phase 1 - Pre-Release Validation** (release-manager):
Agent: "Starting release coordination for v1.0.0. First, status check across
       all departments...

       Reviewing launch checklist results:
       ✓ Engineering: All green
       ✓ QA: 2 minor bugs open (non-blocking)
       ✓ Art/Audio: Complete
       ✓ Localization: Complete
       ⚠ Store: Screenshots pending approval
       ✗ Marketing: Launch trailer not finalized

       Two blockers identified. Timeline impact?"

User: "Screenshots approved this morning. Trailer done by end of day."

Agent: "Got it. Updated timeline: Release tomorrow pending trailer completion.
       Should I proceed with build preparation?"

User: "Yes"

**Phase 2 - Build Management** (release-manager):
Agent: "Creating release build v1.0.0...
       - Windows build: ✓ Complete, tested, 2.1GB
       - Linux build: ✓ Complete, tested, 2.3GB
       - Checksums generated
       - Version manifest created
       - Update server configured

       All builds ready for deployment."

**Phase 3 - Final QA Sign-Off** (qa-lead):
Agent: "Running final regression suite on release builds...
       - All critical tests: ✓ Pass
       - All high-priority tests: ✓ Pass
       - Platform-specific tests: ✓ Pass

       QA signs off for release. No blocking issues."

**Phase 4 - Deployment Preparation** (devops-engineer):
Agent: "CI/CD pipeline ready. Deployment plan:
       1. Upload builds to CDN (12:00 UTC)
       2. Update store listings (12:30 UTC)
       3. Enable download access (13:00 UTC - launch time)
       4. Monitor server load and error rates

       Rollback plan ready if critical issues detected.
       Approve deployment schedule?"

User: "Approved"

**Phase 5 - Go/No-Go Decision** (producer):
Agent: "Final go/no-go check:
       ✓ All builds validated
       ✓ QA sign-off complete
       ✓ Store metadata approved
       ✓ Launch trailer complete (confirmed)
       ✓ Marketing materials ready
       ✓ Support team briefed
       ✓ Deployment plan approved

       All systems GO. Recommend proceeding with launch at 13:00 UTC tomorrow.
       Final approval?"

User: "GO for launch"

Agent: "Launch approved. Deployment begins 12:00 UTC tomorrow. I'll monitor and
       report status updates."

### Step 9.5: Ship

The `validate-push` hook will warn you when pushing to `main` or `develop`.
This is intentional -- release pushes should be deliberate:

```
git tag v1.0.0
git push origin main --tags
```

---

## Phase 10: Post-Launch & Live Ops

### Step 10.1: Hotfix Workflow

When a critical bug appears in production:

```
/hotfix "Players losing save data when inventory exceeds 99 items"
```

This bypasses normal sprint processes with a full audit trail:
1. Creates a hotfix branch
2. Tracks approvals
3. Implements the fix
4. Ensures the fix is backported to the development branch
5. Documents the incident

### Step 10.2: Post-Mortem

After launch dust settles:

```
Ask Claude to create a post-mortem using the template at
.claude/docs/templates/post-mortem.md
```

This covers:
- What went well
- What went poorly
- What was surprising
- Key metrics (sales, reviews, crash rates)
- Lessons for the next project

### Step 10.3: Live Operations (if applicable)

For games with ongoing content:

```
Ask the live-ops-designer agent to design a seasonal content cadence
with battle pass, weekly events, and monthly content drops. Target
retention for the 30-60-90 day cohorts.
```

The `live-ops-designer` handles:
- Season/event calendar
- Battle pass design
- Content cadence planning
- Retention mechanics
- Live economy tuning
- Engagement analytics

### Step 10.4: Community Management

```
Ask the community-manager agent to draft patch notes for v1.0.1,
respond to the top 5 community complaints from the feedback channel,
and prepare a "known issues" post.
```

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
| Unity-specific help | `unity-specialist` | 3 |
| Unreal-specific help | `unreal-specialist` | 3 |

### Agent Hierarchy

```
                    creative-director / technical-director / producer
                                         |
          ---------------------------------------------------------------
          |            |           |           |          |        |
    game-designer  lead-prog  art-dir  audio-dir  narr-dir  qa-lead  release-mgr
          |            |           |           |          |        |
     specialists  programmers  tech-art  snd-design  writer   qa-tester  devops
```

**Escalation rule:** If two agents disagree, go up. Design conflicts go to
`creative-director`. Technical conflicts go to `technical-director`. Scope
conflicts go to `producer`.

---

## Appendix B: Slash Command Quick-Reference

### By Workflow Stage

| Stage | Commands |
|-------|----------|
| **Onboarding** | `/start` |
| **Ideation** | `/brainstorm` |
| **Design** | `/map-systems`, `/design-system`, `/design-review`, `/architecture-decision` |
| **Sprint** | `/sprint-plan`, `/estimate`, `/scope-check`, `/retrospective` |
| **Implementation** | `/code-review`, `/prototype`, `/tech-debt` |
| **Testing** | `/balance-check`, `/playtest-report`, `/perf-profile` |
| **Assets** | `/asset-audit`, `/localize` |
| **Release** | `/release-checklist`, `/launch-checklist`, `/changelog`, `/patch-notes`, `/hotfix` |
| **Production** | `/milestone-review`, `/onboard` |
| **Teams** | `/team-combat`, `/team-narrative`, `/team-ui`, `/team-release`, `/team-polish`, `/team-audio`, `/team-level` |

---

## Appendix C: Common Workflows

### Workflow 1: "I just started and have no game idea"

```
1. /start (asks where you are, routes you to the right workflow)
   — or /brainstorm if you prefer to jump straight to ideation
2. Pick the best concept from the brainstorm output
3. Create a game concept doc (templates/game-concept.md)
4. Define game pillars (templates/game-pillars.md)
5. /design-review on your concept doc
6. /map-systems to decompose concept into systems with dependencies and priorities
7. /design-system to author per-system GDDs (guided, section-by-section)
```

### Workflow 2: "I have a design and want to start coding"

```
1. /design-review on each GDD to make sure they're solid
2. /architecture-decision for your first major tech choice
3. /sprint-plan new to plan your first sprint
4. Start implementing with gameplay-programmer / engine-programmer
5. /code-review after each major feature
6. Write tests alongside code
7. Commit frequently (hooks validate automatically)
```

### Workflow 3: "I need to add a complex feature"

```
1. Create/update the GDD for the feature in design/gdd/
2. /design-review to validate the design
3. /estimate to understand effort and risk
4. Use the appropriate /team-* skill:
   - /team-combat for combat features
   - /team-narrative for story content
   - /team-ui for UI features
   - /team-level for new levels/areas
   - /team-audio for audio work
5. /code-review the implementation
6. /balance-check if it affects game balance
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

### Workflow 5: "I'm approaching a milestone"

```
1. /milestone-review to check progress
2. /scope-check to see if scope has crept
3. /tech-debt to assess debt before milestone
4. /perf-profile to check performance targets
5. /team-polish for final polish pass
6. /release-checklist when ready to ship
```

### Workflow 6: "Starting a new sprint"

```
1. /retrospective to review the last sprint
2. /sprint-plan new to create the next sprint
3. /scope-check to ensure scope is manageable
4. Start working through sprint tasks
5. /sprint-plan status to check progress mid-sprint
```

### Workflow 7: "Shipping the game"

```
1. /milestone-review for final milestone
2. /tech-debt to decide what's acceptable at launch
3. /localize for final localization pass
4. Accessibility audit via accessibility-specialist
5. /launch-checklist for full cross-department validation
6. /team-release to coordinate the release
7. /patch-notes and /changelog for player communications
8. Ship!
9. /hotfix if anything breaks post-launch
10. Post-mortem after launch stabilizes
```

---

## Tips for Getting the Most Out of the System

1. **Always start with design, then implement.** The agent system is built
   around the assumption that a design document exists before code is written.
   Agents reference GDDs constantly.

2. **Use team skills for cross-cutting features.** Don't try to manually
   coordinate 4 agents yourself -- let `/team-combat`, `/team-narrative`,
   etc. handle the orchestration.

3. **Trust the rules system.** When a rule flags something in your code, fix
   it. The rules encode hard-won game development wisdom (data-driven values,
   delta time, accessibility, etc.).

4. **Compact proactively.** At ~65-70% context usage, compact or `/clear`.
   The pre-compact hook saves your progress. Don't wait until you're at the
   limit.

5. **Use the right tier of agent.** Don't ask `creative-director` to write a
   shader. Don't ask `qa-tester` to make design decisions. The hierarchy
   exists for a reason.

6. **Run `/design-review` before handing designs to programmers.** This
   catches incomplete specs early, saving rework.

7. **Run `/code-review` after every major feature.** Catch architectural
   issues before they propagate.

8. **Prototype risky mechanics first.** A day of prototyping can save a week
   of production on a mechanic that doesn't work.

9. **Keep your sprint plans honest.** Use `/scope-check` regularly. Scope
   creep is the #1 killer of indie games.

10. **Document decisions with ADRs.** Future-you will thank present-you for
    recording *why* things were built the way they were.
