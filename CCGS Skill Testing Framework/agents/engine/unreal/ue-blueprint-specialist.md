# Agent Test Spec: ue-blueprint-specialist

## Agent Summary
- **Domain**: Blueprint architecture, the Blueprint/C++ boundary, Blueprint graph quality, Blueprint performance optimization, Blueprint Function Library design
- **Does NOT own**: C++ implementation (engine-programmer or gameplay-programmer), art assets or shaders, UI/UX flow design (ux-designer)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; defers to unreal-specialist or lead-programmer for cross-domain rulings

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Blueprint architecture and optimization)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over C++ implementation decisions

---

## Test Cases

### Case 1: In-domain request — Blueprint graph performance review
**Input**: "Review our AI behavior Blueprint. It has tick-based logic running every frame that checks line-of-sight for 30 NPCs simultaneously."
**Expected behavior**:
- Identifies tick-heavy logic as a performance problem
- Recommends switching from EventTick to event-driven patterns (perception system events, timers, or polling on a reduced interval)
- Flags the per-NPC cost of simultaneous line-of-sight checks
- Suggests alternatives: AIPerception component events, staggered tick groups, or moving the system to C++ if Blueprint overhead is measured to be significant
- Output is structured: problem identified, impact estimated, alternatives listed

### Case 2: Out-of-domain request — C++ implementation
**Input**: "Write the C++ implementation for this ability cooldown system."
**Expected behavior**:
- Does not produce C++ implementation code
- Provides the Blueprint equivalent of the cooldown logic (e.g., using a Timeline or GameplayEffect if GAS is in use)
- States clearly: "C++ implementation is handled by engine-programmer or gameplay-programmer; I can show the Blueprint approach or describe the boundary where Blueprint calls into C++"
- Optionally notes when the cooldown complexity warrants a C++ backend

### Case 3: Domain boundary — unsafe raw pointer access in Blueprint
**Input**: "Our Blueprint calls GetOwner() and then immediately accesses a component on the result without checking if it's valid."
**Expected behavior**:
- Flags this as a runtime crash risk: GetOwner() can return null in some lifecycle states
- Provides the correct Blueprint pattern: IsValid() node before any property/component access
- Notes that Blueprint's null checks are not optional on Actor-derived references
- Does NOT silently fix the code without explaining why the original was unsafe

### Case 4: Blueprint graph complexity — readiness for Function Library refactor
**Input**: "Our main GameMode Blueprint has 600+ nodes in a single graph with duplicated damage calculation logic in 8 places."
**Expected behavior**:
- Diagnoses this as a maintainability and testability problem
- Recommends extracting duplicated logic into a Blueprint Function Library (BFL)
- Describes how to structure the BFL: pure functions for calculations, static calls from any Blueprint
- Notes that if the damage logic is performance-sensitive or shared with C++, it may be a candidate for migration to unreal-specialist review
- Output is a concrete refactor plan, not a vague recommendation

### Case 5: Context pass — Blueprint complexity budget
**Input context**: Project conventions specify a maximum of 100 nodes per Blueprint event graph before a mandatory Function Library extraction.
**Input**: "Here is our inventory Blueprint graph [150 nodes shown]. Is it ready to ship?"
**Expected behavior**:
- References the stated 150-node count against the 100-node budget from project conventions
- Flags the graph as exceeding the complexity threshold
- Does NOT approve it as-is
- Produces a list of candidate subgraphs for Function Library extraction to bring the main graph within budget

---

## Protocol Compliance

- [ ] Stays within declared domain (Blueprint architecture, performance, graph quality)
- [ ] Redirects C++ implementation requests to engine-programmer or gameplay-programmer
- [ ] Returns structured findings (problem/impact/alternatives format) rather than freeform opinions
- [ ] Enforces Blueprint safety patterns (null checks, IsValid) proactively
- [ ] References project conventions when evaluating graph complexity

---

## Coverage Notes
- Case 3 (null pointer safety) is a safety-critical test — this is a common source of shipping crashes
- Case 5 requires that project conventions include a stated node budget; if none is configured, the agent should note the absence and recommend setting one
- No automated runner; review manually or via `$skill-test`
