# Agent Test Spec: ai-programmer

## Agent Summary
Domain: NPC behavior, state machines, pathfinding, perception systems, and AI decision-making.
Does NOT own: player mechanics (gameplay-programmer), rendering or engine internals (engine-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references NPC behavior / AI systems)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
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
**Input:** "Implement player input handling for the WASD movement and dash ability."
**Expected behavior:**
- Does NOT produce player input or movement code
- Explicitly states this is outside its domain (player mechanics belong to gameplay-programmer)
- Redirects the request to `gameplay-programmer`
- May note that once player position is available via API, AI perception can reference it

### Case 3: Cross-domain coordination — level constraints
**Input:** "Design pathfinding for the warehouse level, but the level has narrow corridors that confuse the navmesh."
**Expected behavior:**
- Does NOT unilaterally modify level layout or navmesh assets
- Coordinates with `level-designer` to clarify navmesh requirements and corridor dimensions
- Proposes a pathfinding approach (e.g., navmesh with agent radius tuning, flow fields) conditional on level geometry
- Documents assumptions and flags blockers clearly

### Case 4: Performance escalation — custom data structures
**Input:** "The pathfinding priority queue is the bottleneck; I need a custom binary heap implementation for performance."
**Expected behavior:**
- Recognizes that a low-level, engine-integrated data structure is within engine-programmer's domain
- Escalates to `engine-programmer` with a clear description of the bottleneck and required interface
- May provide the algorithmic spec (binary heap interface, expected operations) to guide the engine-programmer
- Does NOT implement the low-level structure unilaterally if it requires engine memory management

### Case 5: Context pass — uses level layout for pathfinding design
**Input:** Level layout document provided in context showing two choke points: a doorway at (12, 0) and a bridge at (40, 5). Request: "Design the patrol route and threat response for enemies in this level."
**Expected behavior:**
- References the specific choke point coordinates from the provided context
- Designs patrol routes that leverage the choke points as tactical positions
- Specifies alert state transitions that funnel NPCs toward identified choke points during pursuit
- Does not invent geometry not present in the provided layout document

---

## Protocol Compliance

- [ ] Stays within declared domain (NPC behavior, pathfinding, perception, state machines)
- [ ] Redirects out-of-domain requests to correct agent (gameplay-programmer, engine-programmer, level-designer)
- [ ] Returns structured findings (behavior tree specs, state machine diagrams, code scaffolds)
- [ ] Does not modify player mechanics files without explicit delegation
- [ ] Escalates performance-critical low-level structures to engine-programmer
- [ ] Uses data-driven NPC configuration (waypoints, detection radii) not hardcoded values

---

## Coverage Notes
- Behavior tree output (Case 1) should be validated by a unit test in `tests/unit/ai/`
- Level-layout context (Case 5) verifies the agent reads and applies provided documents rather than inventing
- Performance escalation (Case 4) confirms the agent recognizes the engine-programmer boundary
