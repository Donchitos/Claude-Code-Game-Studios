# Agent Test Spec: ai-programmer

## Agent Summary
Domain: NPC behavior, state machines, pathfinding, perception systems, and AI decision-making.
Does NOT own: player mechanics (gameplay-programmer), rendering or engine internals (engine-programmer), enemy behavior design (game-designer), navmesh authoring tools (tools-programmer).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references NPC behavior / AI systems)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over player mechanics or engine rendering

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement a patrol-and-alert behavior tree for a guard NPC: patrol between waypoints, detect the player within 10 units, then enter an alert state and pursue."
**Expected behavior:**
- Produces a behavior tree spec (nodes: Selector, Sequence, Leaf actions) plus corresponding code scaffold
- Defines clearly named states: Patrol, Alert, Pursue
- Uses a perception/detection check as a condition node, not inline in movement code
- Waypoints are data-driven (passed as a resource or export), not hardcoded positions
- Output includes doc comments on public API

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Build an editor tool that lets level designers paint navmesh regions and bake them."
**Expected behavior:**
- Does NOT build the navmesh authoring tool
- Explicitly states this is outside its domain (navigation mesh authoring tools belong to tools-programmer)
- Redirects the request to `tools-programmer`
- Any input it gives the tool's owner is what its pathfinding needs from the baked navmesh (agent radius, area costs, dynamic-obstacle support) — not the tool itself

### Case 3: Cross-domain coordination — level constraints
**Input:** "Design pathfinding for the warehouse level, but the level has narrow corridors that confuse the navmesh."
**Expected behavior:**
- Does NOT unilaterally modify level layout or navmesh assets
- Coordinates with `level-designer` to clarify navmesh requirements and corridor dimensions
- Proposes a pathfinding approach (e.g., navmesh with agent radius tuning, flow fields) conditional on level geometry
- Documents assumptions and flags blockers clearly

### Case 4: Performance work in its own domain — custom data structures
**Input:** "The pathfinding priority queue is the bottleneck; I need a custom binary heap implementation for performance."
**Expected behavior:**
- Treats the heap as its own work: "Implement and optimize pathfinding" is its Key Responsibility, and the priority queue is part of the pathfinding code — it does not hand the heap to engine-programmer
- Proposes the heap (interface, expected operations and their cost) and asks before writing it
- Keeps the pathfinding update inside its 2ms-per-frame AI budget
- Involves `engine-programmer` only if the fix needs a change to a core engine system (its "must not" line), not for the heap itself

### Case 5: Context pass — implements from the level layout and encounter spec
**Input:** Provided in context: a level layout document (from level-designer) marking patrol waypoints A–D and two choke points — a doorway at (12, 0) and a bridge at (40, 5) — and an encounter spec (from game-designer) stating "When alerted, guards fall back to the nearest choke point and hold it." Request: "Implement the patrol and alert response for this level's guards."
**Expected behavior:**
- References the specific waypoints and choke point coordinates from the provided layout
- Implements the alert transition exactly as the encounter spec states (fall back to the nearest choke point and hold) — does NOT design its own threat response
- Keeps waypoints and choke points in data, not hardcoded positions
- Does not invent geometry or behavior the documents do not give; where they leave a case open (e.g., both choke points equally near), asks the spec owner instead of deciding

---

## Protocol Compliance

- [ ] Stays within declared domain (NPC behavior, pathfinding, perception, state machines)
- [ ] Redirects out-of-domain requests to correct agent (tools-programmer for navmesh authoring tools, engine-programmer for core engine systems, game-designer for enemy behavior design)
- [ ] Returns structured findings (behavior tree specs, state machine diagrams, code scaffolds)
- [ ] Does not modify player mechanics files without explicit delegation
- [ ] Does its own pathfinding performance work, data structures included, and involves engine-programmer only for changes to core engine systems
- [ ] Uses data-driven NPC configuration (waypoints, detection radii) not hardcoded values
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Behavior tree output (Case 1) should be validated by a unit test in `tests/unit/ai/`
- Level-layout context (Case 5) verifies the agent implements the provided documents rather than inventing geometry or designing enemy behavior itself
- Pathfinding performance (Case 4) confirms the agent keeps work its Key Responsibilities assign it, and involves engine-programmer only for core engine changes
