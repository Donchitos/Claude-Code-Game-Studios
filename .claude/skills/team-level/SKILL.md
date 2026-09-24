---
name: team-level
description: "Orchestrate the level team — level-designer, narrative-director, world-builder, art-director, systems-designer, qa-tester — for complete area creation."
argument-hint: "[level name or area to design] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-level/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

When this skill is invoked:

**Decision Points:** At each step transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next step.
In `guided` mode the pipeline advances automatically unless a step is BLOCKED;
in `autonomous` mode it runs end to end, recording each step outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`review_mode` sets gate depth:
- `full` — spawn all director and lead gates as described
- `lean` — skip director gates unless they are PHASE-GATE type (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE)
- `solo` — skip all director gate spawning entirely; run the skill without any agent gates

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `level-designer` + `gameplay-programmer`. Other agents consulted via these two, not spawned separately.
- **`small`**: + `systems-designer` + `art-director`.
- **`studio`**: + `narrative-director` + `world-builder` + `accessibility-specialist`.
Directors (CD/TD/PR) still spawn at phase gates regardless of size; a non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Step 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names eight and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever, measured
at roughly 10x. What was wrong is that nothing said so, so a reader could not
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

1. **Read the argument** for the target level or area (e.g., `tutorial`,
   `forest dungeon`, `hub town`, `final boss arena`).

2. **Gather context**:
   - Read the game concept at `design/gdd/game-concept.md`
   - Read game pillars at `design/gdd/game-pillars.md`
   - Read existing level docs in `design/levels/`
   - Read relevant narrative docs in `design/narrative/`
   - Read world-building docs for the area's region/faction

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: narrative-director` — Narrative purpose, characters, emotional arc
- `subagent_type: world-builder` — Lore context, environmental storytelling, world rules
- `subagent_type: level-designer` — Spatial layout, pacing, encounters, navigation
- `subagent_type: systems-designer` — Enemy compositions, loot tables, difficulty balance
- `subagent_type: art-director` — Visual theme, color palette, lighting, asset requirements
- `subagent_type: accessibility-specialist` — Navigation clarity, colorblind safety, cognitive load
- `subagent_type: qa-tester` — Test cases, boundary testing, playtest checklist

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

3. **Orchestrate the level design team** in sequence:

### Step 1: Narrative + Visual Direction (narrative-director + world-builder + art-director, parallel)

Spawn all three agents simultaneously — issue all three `Agent` calls before waiting for any result.

Spawn the `narrative-director` agent to:
- Define the narrative purpose of this area (what story beats happen here?)
- Identify key characters, dialogue triggers, and lore elements
- Specify emotional arc (how should the player feel entering, during, leaving?)

Spawn the `world-builder` agent to:
- Provide lore context for the area (history, faction presence, ecology)
- Define environmental storytelling opportunities
- Specify any world rules that affect gameplay in this area

Spawn the `art-director` agent to:
- Establish visual theme targets for this area — these are INPUTS to layout, not outputs of it
- Define the color temperature and lighting mood for this area (how does it differ from adjacent areas?)
- Specify shape language direction (angular fortress? organic cave? decayed grandeur?)
- Name the primary visual landmarks that will orient the player
- Read `design/art/art-bible.md` if it exists — anchor all direction in the established art bible

**The art-director's visual targets from Step 1 must be passed to the level-designer in Step 2** as explicit constraints. Layout decisions happen within the visual direction, not before it.

**Gate**: Use `AskUserQuestion` to present all three Step 1 outputs (narrative brief, lore foundation, visual direction targets) and confirm before proceeding to Step 2.

### Step 2: Layout and Encounter Design (level-designer)
Spawn the `level-designer` agent with the full Step 1 output as context:
- Narrative brief (from narrative-director)
- Lore foundation (from world-builder)
- **Visual direction targets (from art-director)** — layout must work within these targets, not contradict them

The level-designer should:
- Design the spatial layout (critical path, optional paths, secrets) — ensuring primary routes align with the visual landmark targets from Step 1
- Define pacing curve (tension peaks, rest areas, exploration zones) — coordinated with the emotional arc from narrative-director
- Place encounters with difficulty progression
- Design environmental puzzles or navigation challenges
- Define points of interest and landmarks for wayfinding — these must match the visual landmarks the art-director specified
- Specify entry/exit points and connections to adjacent areas

**Adjacent area dependency check**: After the layout is produced, check `design/levels/` for each adjacent area referenced by the level-designer. If any referenced area's `.md` file does not exist, surface the gap:
> "Level references [area-name] as an adjacent area but `design/levels/[area-name].md` does not exist."

Use `AskUserQuestion` with options:
- (a) Proceed with a placeholder reference — mark the connection as UNRESOLVED in the level doc and list it in the open cross-level dependencies section of the summary report
- (b) Pause and run `/team-level [area-name]` first to establish that area

Do NOT invent content for the missing adjacent area.

**Gate**: Use `AskUserQuestion` to present Step 2 layout (including any unresolved adjacent area dependencies) and confirm before proceeding to Step 3.

### Step 3: Systems Integration (systems-designer)
Spawn the `systems-designer` agent to:
- Specify enemy compositions and encounter formulas
- Define loot tables and reward placement
- Balance difficulty relative to expected player level/gear
- Design any area-specific mechanics or environmental hazards
- Specify resource distribution (health pickups, save points, shops)

**Gate**: Use `AskUserQuestion` to present Step 3 outputs and confirm before proceeding to Step 4.

### Step 4: Production Concepts + Accessibility (art-director + accessibility-specialist, parallel)

**Note**: The art-director's directional pass (visual theme, color targets, mood) happened in Step 1. This pass is location-specific production concepts — given the finalized layout, what does each specific space look like?

Spawn the `art-director` agent with the finalized layout from Step 2:
- Produce location-specific concept specs for key spaces (entrance, key encounter zones, landmarks, exits)
- Specify which art assets are unique to this area vs. shared from the global pool
- Define sight-line and lighting setups per key space (these are now layout-informed, not directional)
- Specify VFX needs that are specific to this area's layout (weather volumes, particles, atmospheric effects)
- Flag any locations where the layout creates visual direction conflicts with the Step 1 targets — surface these as production risks

Spawn the `accessibility-specialist` agent in parallel to:
- Review the level layout for navigation clarity (can players orient themselves without relying on color alone?)
- Check that critical path signposting uses shape/icon/sound cues in addition to color
- Review any puzzle mechanics for cognitive load — flag anything that requires holding more than 3 simultaneous states
- Check that key gameplay areas have sufficient contrast for colorblind players
- Output: accessibility concerns list with severity (BLOCKING / RECOMMENDED / NICE TO HAVE)

Wait for both agents to return before proceeding.

**Gate**: Use `AskUserQuestion` to present both Step 4 results. If the accessibility-specialist returned any BLOCKING concerns, highlight them prominently and offer:
- (a) Return to level-designer and art-director to redesign the flagged elements before Step 5
- (b) Document as a known accessibility gap and proceed to Step 5 with the concern explicitly logged in the final report

Do NOT proceed to Step 5 without the user acknowledging any BLOCKING accessibility concerns.

### Step 5: QA Planning (qa-tester)
Spawn the `qa-tester` agent to:
- Write test cases for the critical path
- Identify boundary and edge cases (sequence breaks, softlocks)
- Create a playtest checklist for the area
- Define acceptance criteria for level completion

4. **Compile the level design document** combining all team outputs into the
   level design template format.

The orchestrator already holds every sub-agent's output — **compile the document
itself; do not re-spawn `level-designer` and re-send all outputs verbatim.** That
second spawn pays a fresh agent's overhead plus a full re-transmission of context
the orchestrator already has, to move text it is already holding. After compiling
into the level-design template format, ask the user directly via
`AskUserQuestion`: "May I write the compiled level design to
`design/levels/[level-name].md`?" On approval, write it.

5. **Save to** `design/levels/[level-name].md` after that approval.

6. **Output a summary** with: area overview, encounter count, estimated asset
   list, narrative beats, any cross-team dependencies or open questions, open
   cross-level dependencies (adjacent areas referenced but not yet designed, each
   marked UNRESOLVED), and accessibility concerns with their resolution status.

## File Write Protocol

Per-agent artifacts (narrative docs, test checklists) are written by the
sub-agent that produced them, under the **bounded exception** documented above
under "Why this does not violate the Collaboration Protocol" — the path is one
you named, the artifact is new under `production/`, `docs/` or `tests/`, and the
phase is gated by an `AskUserQuestion`. A sub-agent does **not** prompt per write
inside those bounds; outside them it must ask. The **one exception is the final
compiled level-design document**: the
orchestrator already holds every input, so it compiles and writes that file
itself after its own "May I write …?" prompt (Step 4) — re-spawning an agent
just to write text the orchestrator is already holding is pure overhead.

Verdict: **COMPLETE** — level design document produced and all team outputs compiled.
Verdict: **BLOCKED** — one or more agents blocked; partial report produced with unresolved items listed.

## Next Steps

- Run `/design-review design/levels/[level-name].md` to validate the completed level design doc.
- Run `/dev-story` to implement level content once the design is approved.
- Run `/qa-plan` to generate a QA test plan for this level.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
