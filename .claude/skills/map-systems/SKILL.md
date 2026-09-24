---
name: map-systems
description: "Decompose a concept into individual systems, map dependencies, prioritize design order, create the systems index."
argument-hint: "[next | system-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Agent, Bash(bash "*/.claude/skills/map-systems/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


When this skill is invoked:

## Parse Arguments

Two modes:

- **No argument**: `/map-systems` — Run the full decomposition workflow (Phases 1-5)
  to create or update the systems index.
- **`next`**: `/map-systems next` — Pick the highest-priority undesigned system
  from the index and hand off to `/design-system` (Phase 6).


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` = one-line system descriptions;
`balanced` = a brief paragraph per system + dependency notes (default);
`thorough` = full system-by-system rationale + relationship analysis. Apply it to
every section you author.

> **Where the per-system prose goes.** `templates/systems-index.md`'s Systems
> Enumeration is a fixed-column table with no description column, so at
> `balanced` and `thorough` the prose belongs in `## Overview` — one short
> paragraph per system at `balanced`, plus relationship analysis at `thorough` —
> and in the `## Dependency Map` layer notes. **Do not add a column to the
> enumeration table** — it is a fixed contract in
> `.claude/docs/templates/systems-index.md`, and its consumers
> (`/design-system` §6 and §7, `/create-epics`) are written against the columns it
> defines. Widening it is a schema change, not a formatting choice.
>
> **How the consumers actually read it.** Nothing parses this table
> positionally. The two scripts that mention `systems-index.md`
> (`gdd-structure-check.sh:51`, `review-scope.sh:40`) match it **by filename** in a
> `case` statement and parse no columns at all; the two skills key on the
> **`Category` column by name** (`design-system:229`, `:780`). So `Category` is
> the column that must never be renamed or dropped, and the table stays a fixed
> contract because every consumer is written against the set of columns the
> template defines.
> At `terse`, the table plus a one-paragraph `## Overview` is the whole output.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` / `standard` — required before `/design-system` (systems must be mapped
  before per-system GDDs are authored).
- `minimal` — not required (the game brief replaces the systems index). Can
  still be run voluntarily.

---

## Phase 1: Read Concept (Required Context)

Read the game concept and any existing design work. This provides the raw material
for systems decomposition.

**Required:**
- Read `design/gdd/game-concept.md` (at `minimal`, read `design/game-brief.md`
  instead) — **fail with a clear message if neither is found**:
  > "No game concept found. Run `/brainstorm` first to create one, then come back
  > to decompose it into systems."

**Optional (read if they exist):**
- Read `design/gdd/game-pillars.md` — pillars constrain priority and scope
- Read `design/gdd/systems-index.md` — if exists, **resume** from where it left off
  (update, don't recreate from scratch)
- Glob `design/gdd/*.md` — check which system GDDs already exist

**If the systems index already exists:**
- Read it and present current status to the user
- Use `AskUserQuestion` to ask:
  "The systems index already exists with [N] systems ([M] designed, [K] not started).
  What would you like to do?"
  - Options: "Update the index with new systems", "Design the next undesigned system",
    "Review and revise priorities"

---

## Phase 2: Systems Enumeration (Collaborative)

Extract and identify all systems the game needs. This is the creative core of the
skill — it requires human judgment because concept docs rarely enumerate every
system explicitly.

### Step 2a: Extract Explicit Systems

Scan the game concept for directly mentioned systems and mechanics:
- Core Mechanics section (most explicit)
- Core Loop section (implies what systems drive each loop tier)
- Technical Considerations section (networking, procedural generation, etc.)
- MVP Definition section (required features = required systems)

### Step 2b: Identify Implicit Systems

For each explicit system, identify the **hidden systems** it implies. Games always
need more systems than the concept doc mentions. Use this inference pattern:

- "Inventory" implies: item database, equipment slots, weight/capacity rules,
  inventory UI, item serialization for save/load
- "Combat" implies: damage calculation, health system, hit detection, status effects,
  enemy AI, combat UI (health bars, damage numbers), death/respawn
- "Open world" implies: streaming/chunking, LOD system, fast travel, map/minimap,
  point of interest tracking, world state persistence
- "Multiplayer" implies: networking layer, lobby/matchmaking, state synchronization,
  anti-cheat, network UI (ping, player list)
- "Crafting" implies: recipe database, ingredient gathering, crafting UI,
  success/failure mechanics, recipe discovery/learning
- "Dialogue" implies: dialogue tree system, dialogue UI, choice tracking, NPC
  state management, localization hooks
- "Progression" implies: XP system, level-up mechanics, skill tree, unlock
  tracking, progression UI, progression save data

Explain in conversation text why each implicit system is needed (with examples).

### Step 2c: User Review

Present the enumeration organized by category. For each system, show:
- Name
- Category
- Brief description (1 sentence)
- Whether it was explicit (from concept) or implicit (inferred)

Then use `AskUserQuestion` to capture feedback:
- "Are there systems missing from this list?"
- "Should any of these be combined or split?"
- "Are there systems listed that this game does NOT need?"

**At `collaborative`** — iterate until the user approves the enumeration.
**At `guided`** — ask once, apply the answer, and proceed; do not loop.
**At `autonomous`** — do not ask. Record the enumeration and its inferred systems
via `log_decision` and proceed.

> **The loop needed an exit that does not depend on being asked.**
> `automation-modes.md:56` defines `autonomous` as *"No `AskUserQuestion`"*, so a
> loop terminating on "the user approves" has no termination path there at all.
> Same class as Step 5b, one level up: that was an unconditional *write* gate,
> this is an unconditional *control-flow loop* around the question.

---

## Phase 3: Dependency Mapping (Collaborative)

For each system, determine what it depends on. A system "depends on" another if
it cannot function without that other system existing first.

### Step 3a: Map Dependencies

For each system, list its dependencies. Use these dependency heuristics:
- **Input/output dependencies**: System A produces data System B needs
- **Structural dependencies**: System A provides the framework System B plugs into
- **UI dependencies**: Every gameplay system has a corresponding UI system that
  depends on it (but UI is designed after the gameplay system)

### Step 3b: Sort by Dependency Order

Arrange systems into layers:
1. **Foundation**: Systems with zero dependencies (designed and built first)
2. **Core**: Systems depending only on Foundation systems
3. **Feature**: Systems depending on Core systems
4. **Presentation**: UI and feedback systems that wrap gameplay systems
5. **Polish**: Meta-systems, tutorials, analytics, accessibility

### Step 3c: Detect Circular Dependencies

Check for cycles in the dependency graph. If found:
- Highlight them to the user
- Propose resolutions (interface abstraction, simultaneous design, breaking the
  cycle by defining a contract between the two systems)

### Step 3d: Present to User

Show the dependency map as a layered list. Highlight:
- Any circular dependencies
- Any "bottleneck" systems (many others depend on them — these are high-risk)
- Any systems with no dependents (leaf nodes — lower risk, can be designed late)

Use `AskUserQuestion` to ask: "Does this dependency ordering look right? Any
dependencies I'm missing or that should be removed?"

**Review mode check** — apply before spawning TD-SYSTEM-BOUNDARY:
- `solo` → skip. Note: "TD-SYSTEM-BOUNDARY skipped — Solo mode." Proceed to priority assignment.
- `lean` → skip (not a PHASE-GATE). Note: "TD-SYSTEM-BOUNDARY skipped — Lean mode." Proceed to priority assignment.
- `full` → spawn as normal.

**After dependency mapping is approved, spawn `technical-director` via `Agent` using gate TD-SYSTEM-BOUNDARY (`.claude/docs/director-gates/td-system-boundary.md`) before proceeding to priority assignment.**

Pass: the dependency map summary, layer assignments, bottleneck systems list, any circular dependency resolutions.

Present the assessment. If REJECT, revise the system boundaries with the user before moving to priority assignment. If CONCERNS, note them inline in the systems index and continue.

---

## Phase 4: Priority Assignment (Collaborative)

Assign each system to a priority tier based on what milestone it's needed for.

### Step 4a: Auto-Assign Based on Concept

Use these heuristics for initial assignment:
- **MVP**: Systems mentioned in the concept's "Required for MVP" section, plus their
  Foundation-layer dependencies
- **Vertical Slice**: Systems needed for a complete experience in one area
- **Alpha**: All remaining gameplay systems
- **Full Vision**: Polish, meta, and nice-to-have systems

### Step 4b: User Review

Present the priority assignments in a table. For each tier, explain why systems
were placed there.

Use `AskUserQuestion` to ask: "Do these priority assignments match your vision?
Which systems should be higher or lower priority?"

Explain reasoning in conversation: "I placed [system] in MVP because the core loop
requires it — without [system], the 30-second loop can't function."

**How to phrase the reasoning** — this governs what you *say*, not a column you
write. Neither table has a `Why` column: Systems Enumeration is
`# / Name / Category / Priority / Status / Design Doc / Depends On`, and
Recommended Design Order is `Order / System / Priority / Layer / Agent(s) /
Est. Effort`. The rationale lives in the conversation above and, for anything
the user should still see after the session, in the index's `## Overview`
paragraph. Do not invent a column for it.

Mix technical necessity with player-experience reasoning. A purely technical
justification — "the damage system needs damage math" — is insufficient on its
own when the system directly shapes what the player feels. Good reasoning names
both, and cites the pillar it serves:
- "Required for the core loop — without it the player's main choice has no
  consequence (Pillar [N]: [pillar name])"
- "This is where [system]'s identity is established — the stat definitions here
  are what make it feel different from [the sibling system]"
- "Foundation for every later economy decision — the player must understand
  costs before any of the choices built on top of it mean anything"

> **Fill the brackets from *this* project.** The bracketed slots are not
> decoration. Worked examples from another genre (a tower-defense "Ballista's
> punch-through identity… what makes it feel different from Archer", "Pillar 2:
> Placement is the Puzzle") get reproduced verbatim by a run against a different
> game, which then carries that game's vocabulary instead of its own.

**Review mode check** — apply before spawning PR-SCOPE:
- `solo` → skip. Note: "PR-SCOPE skipped — Solo mode." Proceed to writing the systems index.
- `lean` → skip (not a PHASE-GATE). Note: "PR-SCOPE skipped — Lean mode." Proceed to writing the systems index.
- `full` → spawn as normal.

**After priorities are approved, spawn `producer` via `Agent` using gate PR-SCOPE (`.claude/docs/director-gates/pr-scope.md`) before writing the index.**

Pass: total system count per milestone tier, estimated implementation volume per tier (system count × average complexity), team size, stated project timeline.

Present the assessment. If UNREALISTIC, offer to revise priority tier assignments before writing the index. If CONCERNS, note them and continue.

### Step 4c: Determine Design Order

Combine dependency sort + priority tier to produce the final design order:
1. MVP Foundation systems first
2. MVP Core systems second
3. MVP Feature systems third
4. Vertical Slice Foundation/Core systems
5. ...and so on

This is the order the team should write GDDs in.

---

## Phase 5: Create Systems Index (Write)

### Step 5a: Draft the Document

Using the template at `.claude/docs/templates/systems-index.md`, populate the
systems index with all data from Phases 2-4:
- Fill the enumeration table
- Fill the dependency map
- Fill the recommended design order
- Fill the high-risk systems
- Fill progress tracker (all systems "Not Started" initially, unless GDDs already exist)

### Step 5b: Approval

Present a summary of the document:
- Total systems count by category
- MVP system count
- First 3 systems in the design order
- Any high-risk items

**At `automation: collaborative`** — ask: "May I write the systems index to
`design/gdd/systems-index.md`?" Wait for approval. Write the file only after
"yes."

**At `automation: guided`** — present the summary above, name the destination
(`design/gdd/systems-index.md`), and write it without waiting for an explicit
"yes", per `.claude/docs/automation-modes.md`. Say what you wrote afterwards.

> **Keep this line scoped to its mode.** `automation-modes.md` says `guided`
> *"proceeds after a short summary, does not wait for explicit yes"*, and this
> skill's own Collaborative Protocol section is scoped to `collaborative`. An
> unconditional "wait for approval" here collides with both.

**Review mode check** — apply before spawning CD-SYSTEMS:
- `solo` → skip. Note: "CD-SYSTEMS skipped — Solo mode." Proceed to Phase 7 next steps.
- `lean` → skip (not a PHASE-GATE). Note: "CD-SYSTEMS skipped — Lean mode." Proceed to Phase 7 next steps.
- `full` → spawn as normal.

**After the systems index is written, spawn `creative-director` via `Agent` using gate CD-SYSTEMS (`.claude/docs/director-gates/cd-systems.md`).**

Pass: systems index path, game pillars and core fantasy (from `design/gdd/game-concept.md`), MVP priority tier system list.

Present the assessment. If REJECT, revise the system set with the user before GDD authoring begins. If CONCERNS, record them in the systems index as a `> **Creative Director Note**`
placed **directly beneath the `## Priority Tiers` table**, naming the tier each
concern applies to — e.g. `> **Creative Director Note** (MVP): …`.
`templates/systems-index.md` has a Priority Tiers *definition table*, not a
section per tier, so there is no "top of the tier section" to write to — do not
direct the writer to one.

### Step 5c: Update Session State

After writing, create `production/session-state/active.md` if it does not exist, then update it with:
- Task: Systems decomposition
- Status: Systems index created
- File: design/gdd/systems-index.md
- Next: Design individual system GDDs

**Verdict: COMPLETE** — systems index written to `design/gdd/systems-index.md`.
If the user declined: **Verdict: BLOCKED** — user did not approve the write.

---

## Phase 6: Design Individual Systems (Handoff to /design-system)

This phase is entered when:
- The user says "yes" to designing systems after creating the index
- The user invokes `/map-systems [system-name]`
- The user invokes `/map-systems next`

### Step 6a: Select the System

- If a system name was provided, find it in the systems index
- If `next` was used, pick the highest-priority undesigned system (by design order)
- If the user just finished the index, ask:
  "Would you like to start designing individual systems now? The first system in
  the design order is [name]. Or would you prefer to stop here and come back later?"

Use `AskUserQuestion` for: "Start designing [system-name] now, pick a different
system, or stop here?"

### Step 6b: Hand Off to /design-system

Once a system is selected, invoke the `/design-system [system-name]` skill.

The `/design-system` skill handles the full GDD authoring process:
- Gathers context from game concept, systems index, and dependency GDDs
- Creates a file skeleton immediately
- Walks through all 8 required sections one at a time (collaborative, incremental)
- Cross-references existing docs to prevent contradictions
- Routes to specialist agents for domain expertise
- Writes each section to file as soon as it's approved
- Runs `/design-review` when complete
- Updates the systems index

**Do not duplicate the /design-system workflow here.** This skill owns the systems
*index*; `/design-system` owns individual system *GDDs*.

### Step 6c: Loop or Stop

After `/design-system` completes, use `AskUserQuestion`:
- "Continue to the next system ([next system name])?"
- "Pick a different system?"
- "Stop here for this session?"

If continuing, return to Step 6a.

---

## Phase 7: Suggest Next Steps

After the systems index is created (or after designing some systems), present next actions using `AskUserQuestion`:

- "Systems index is written. What would you like to do next?"
  - [A] Start designing GDDs — run `/design-system [first-system-in-order]`
  - [B] Run `/gate-check systems-design` — triggers the CD-SYSTEMS and TD-SYSTEM-BOUNDARY gates automatically for a formal director sign-off on the system set
  - [C] Stop here for this session

**The gate-check option ([B]) is worth highlighting**: running `/gate-check systems-design` triggers both the CD-SYSTEMS and TD-SYSTEM-BOUNDARY gates, catching scope issues, missing systems, and boundary problems before they're locked in across many documents. It is optional but recommended for new projects.

After any individual GDD is completed:
- "Run `/design-review design/gdd/[system].md` in a fresh session to validate quality"
- "Run `/gate-check systems-design` when all MVP GDDs are complete"

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

This skill follows the collaborative design principle at every phase:

1. **Question -> Options -> Decision -> Draft -> Approval** at every step
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Missing systems? Combine or split?"
   - Phase 3: "Dependency ordering correct?"
   - Phase 4: "Priority assignments match your vision?"
   - Phase 5: "May I write the systems index?"
   - Phase 6: "Start designing, pick different, or stop?" then hand off to `/design-system`
3. **"May I write to [filepath]?"** before every file write
4. **Incremental writing**: Update the systems index after each system is designed
5. **Handoff**: Individual GDD authoring is owned by `/design-system`, which handles
   incremental section writing, cross-referencing, design review, and index updates
6. **Session state updates**: Write to `production/session-state/active.md` after
   each milestone (index created, system designed, priorities changed)

**Never** auto-generate the full systems list and write it without review.
**Never** start designing a system without user confirmation.
**Always** show the enumeration, dependencies, and priorities for user validation.

## Context Window Awareness

If context reaches or exceeds 70% at any point, append this notice:

> **Context is approaching the limit (≥70%).** The systems index is saved to
> `design/gdd/systems-index.md`. Open a fresh Claude Code session to continue
> designing individual GDDs — run `/map-systems next` to pick up where you left off.

---

## Recommended Next Steps

- Run `/design-system [first-system-in-order]` to author the first GDD (use design order from the index)
- Run `/map-systems next` to always pick the highest-priority undesigned system automatically
- Run `/design-review design/gdd/[system].md` in a fresh session after each GDD is authored
- Run `/gate-check pre-production` when all MVP GDDs are authored and reviewed
