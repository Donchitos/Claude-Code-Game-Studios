# Agent Test Spec: ue-blueprint-specialist

## Agent Summary
- **Domain**: Blueprint architecture, the Blueprint/C++ boundary, Blueprint graph quality, Blueprint performance optimization, Blueprint Function Library design
- **Does NOT own**: C++ implementation (gameplay-programmer exposes the C++ hooks Blueprint calls), art assets or shaders, UI/UX flow design (ux-designer)
- **Gate IDs**: None; defers C++/Blueprint boundary architecture rulings to unreal-specialist

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Blueprint architecture and optimization)
- [ ] `tools:` list matches the agent's role (Read/Write/Edit for Blueprint-facing files; no server or deployment tools, and Bash withheld via `disallowedTools:`)
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over C++ implementation decisions

---

## Test Cases

### Case 1: In-domain request — Blueprint graph performance review
**Input**: "Review our AI behavior Blueprint. It has tick-based logic running every frame that checks line-of-sight for 30 NPCs simultaneously."
**Expected behavior**:
- Identifies tick-heavy logic as a performance problem
- Recommends switching from EventTick to event-driven patterns (perception system events, timers, or polling on a reduced interval) — never polling every frame when an event would suffice
- Flags the per-NPC cost of simultaneous line-of-sight checks, including any loop over the NPC array inside Tick
- Recommends profiling first (`stat game`, Blueprint profiler), and treats moving the system to C++ as warranted when the measured Blueprint overhead is significant — 30 NPCs is below its automatic C++ threshold (tick logic with more than 100 instances)
- Output names, for each finding, the Performance Rule or Review Checklist item it breaks and the replacement pattern

### Case 2: Out-of-domain request — C++ implementation
**Input**: "Write the C++ implementation for this ability cooldown system."
**Expected behavior**:
- Classifies the cooldown system with its boundary rules: ability-system logic is on its "Must Be C++" list, so it does not offer a Blueprint reimplementation of the system
- Describes the boundary instead: C++ defines the framework and exposes hooks (`BlueprintCallable`, `BlueprintNativeEvent`, `BlueprintImplementableEvent`); Blueprint supplies tuning values (`EditAnywhere` / `BlueprintReadWrite`) and simple event responses such as cooldown feedback
- Routes the C++ implementation to gameplay-programmer (its named partner for exposing C++ hooks to Blueprint) and the boundary decision to unreal-specialist, rather than writing the C++ system itself

### Case 3: Domain boundary — unsafe raw pointer access in Blueprint
**Input**: "Our Blueprint calls GetOwner() and then immediately accesses a component on the result without checking if it's valid."
**Expected behavior**:
- Flags this as a runtime crash risk under its Review Checklist item "Error/failure paths are handled (not just the happy path)": GetOwner() can return null in some lifecycle states
- Provides the correct Blueprint pattern: IsValid() node before any property/component access, with the invalid branch handled
- Notes that Blueprint's null checks are not optional on Actor-derived references
- Does NOT silently fix the code — explains why the original was unsafe and asks before editing the Blueprint

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
- References the stated 150-node count against the 100-node event-graph budget from project conventions
- Flags the graph as exceeding the complexity threshold
- Does NOT approve it as-is
- Produces a list of candidate subgraphs for Function Library extraction to bring the main graph within budget
- Applies its own standard (maximum 20 nodes per function graph) to the extracted functions, keeping it distinct from the project's event-graph budget rather than substituting one number for the other

---

## Protocol Compliance

- [ ] Stays within declared domain (Blueprint architecture, performance, graph quality)
- [ ] Routes C++ implementation requests to gameplay-programmer and boundary rulings to unreal-specialist
- [ ] Grounds findings in its own Performance Rules and Blueprint Review Checklist, naming the rule each finding breaks, rather than freeform opinions
- [ ] Enforces Blueprint safety patterns (null checks, IsValid) proactively
- [ ] References project conventions when evaluating graph complexity, alongside its own per-function node limit

---

## Coverage Notes
- Case 3 (null pointer safety) is a safety-critical test — this is a common source of shipping crashes
- Case 5 requires that project conventions include a stated node budget; if none is configured, the agent falls back to its own standard (maximum 20 nodes per function graph) and says so
- No automated runner; review manually or via `/skill-test`
