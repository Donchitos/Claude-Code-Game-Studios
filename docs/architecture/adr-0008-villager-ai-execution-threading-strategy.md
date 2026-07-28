# ADR-0008: Villager AI Execution & Threading Strategy

## Status
Accepted (2026-07-11 — pre-VS performance spike QQ3 PASSED at ADR-ceiling scale; see prototypes/perf-spike-qq3/REPORT.md. User-delegated decision.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Core / Scripting (AI decision architecture + tick-based scheduling) |
| **Knowledge Risk** | LOW-MEDIUM — no dedicated engine-reference module exists; this ADR's chosen design deliberately avoids `WorkerThreadPool`/threading, sidestepping that surface entirely (see Decision) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — no relevant 4.4-4.7 threading-model change; no known single-threaded GDScript performance cliff at this population scale. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0007 (AI Pathfinding, Navigation & Room-Analysis) — this ADR schedules/throttles ADR-0007's `AStar3D`-based job selection across many agents, it doesn't change the pathfinding mechanism itself |
| **Enables** | Villager AI `/dev-story` implementation, specifically its decision-loop and Deciding-state processing |
| **Blocks** | Villager AI implementation |
| **Ordering Note** | Was provisional pending the pre-VS performance spike — spike PASSED 2026-07-11 with tuning deliverable max_deciding_per_tick = 1 (see prototypes/perf-spike-qq3/REPORT.md) |

## Context

### Problem Statement
Two distinct questions remain open in `villager-ai-behavior.md` that neither `architecture.md` nor ADR-0007 addressed: (1) Open Question 2 — the AI's own decision-making architecture (behavior tree vs. utility layer vs. plain FSM), explicitly flagged as architectural and left unresolved through the systems-design gate; (2) TR-villager-ai-behavior-013's Deciding-pass staggering requirement — when many villagers become "Deciding" simultaneously (e.g., after a mass work-completion event or scene load), their F2 job-selection passes (each doing several candidate `AStar3D` pathfinds per ADR-0007) must be spread across frames/ticks to stay under the 16.6ms frame budget (TR-villager-ai-behavior-041), verified at Full Vision's 20-30 population ceiling under 1x/3x time-warp.

### Constraints
- `villager-ai-behavior.md` already fixes a 6-state agent machine (Deciding/Traveling/Working/Sleeping/Breather/Wandering) with a strict, discrete, non-blended priority order (Urgent need > Work > Idle/Wander) — not an open-ended or continuously-scored decision space
- Population ceiling 20-30 villagers (Full Vision), VS ships with ~5
- Deciding-pass staggering must use "a stable, deterministic villager order" (TR-013) — the same stable-order convention already established elsewhere in this GDD for tie-breaks
- Per-villager F2 job selection already has its own internal budget (`max_selection_candidates` = 15, Chebyshev pre-filter rounds, per ADR-0007's Context) — this ADR adds the aggregate, across-villagers budget on top of that existing per-villager one
- Must work correctly under 1x/3x time-warp (more ticks fire per real-time second at 3x, per Time & Tick System)

### Requirements
- A concrete decision-architecture choice for OQ2, closing the gap ADR-0007 didn't cover
- A concrete staggering mechanism: N villagers becoming Deciding in the same tick must not all run F2 selection in that same tick if N exceeds a budget
- The mechanism must be simple enough to reason about without introducing genuine multi-threading complexity, unless the pre-VS spike proves it's actually necessary

## Decision

**Plain explicit FSM for the AI decision architecture (not a behavior tree or utility-AI framework). Tick-staggered Deciding-pass processing via a per-tick budget (`max_deciding_per_tick`) and a stable-order FIFO queue — no threading (`WorkerThreadPool` or otherwise) for MVP/VS.**

**1. AI decision architecture: plain explicit FSM.** `villager-ai-behavior.md` already fully specifies a fixed 6-state machine with a strict, discrete priority list — not a set of continuously-scored candidate behaviors (which is what utility AI is designed for) and not a deeply nested tree of conditional fallback behaviors that grows in complexity over time (which is what behavior trees are designed for). An explicit FSM — an enum state variable plus one function per state handling entry/exit/tick behavior — implements the GDD's already-fixed rules directly, with no framework abstraction the GDD's own design doesn't need. Both alternatives are named and rejected below, not because they're bad patterns in general, but because they solve a flexibility problem this GDD's fixed, small state set doesn't have.

**2. Deciding-pass staggering: per-tick budget + stable-order FIFO queue.** When a villager becomes eligible for a Deciding pass (need-urgent trigger, job completion, `decision_interval` elapsed, etc.), it enters a pending queue rather than running F2 selection immediately. Each tick, at most `max_deciding_per_tick` villagers (a new `VillagerAIConfig` tuning knob, per ADR-0002's config pattern) are dequeued — in the same stable, deterministic villager order already used elsewhere in this GDD for tie-breaks — and run their full Deciding pass (including any `AStar3D` candidate pathfinds, per ADR-0007). Villagers beyond the budget remain queued and are processed on subsequent ticks, FIFO within the stable order. A villager already mid-Deciding-pass is never interrupted mid-pass by the budget — the budget caps how many NEW passes start per tick, not how long an in-progress pass may run.

**3. No threading for MVP/VS.** At a 20-30 villager ceiling, the tick-staggering mechanism alone is expected to bound worst-case per-tick cost without needing `WorkerThreadPool` or any other genuine parallelism — introducing threading would add real complexity (thread-safe access to Voxel World's occupancy dictionary, `AStar3D`'s graph, and Needs & Mood's per-villager state, none of which are designed as thread-safe in this architecture) for a population scale that a simple scheduling budget should already handle. `WorkerThreadPool` is named as an explicit escape hatch — not adopted now, revisited only if the pre-VS spike finds tick-staggering alone insufficient at the 30-villager ceiling.

### Architecture Diagram
```
Villager becomes Deciding-eligible (need-urgent / job-complete / interval)
        │
        ▼
Pending Deciding queue (stable villager order, FIFO)
        │
        ▼  each tick, dequeue up to max_deciding_per_tick villagers
        │
        ▼
Villager's full Deciding pass (F2 job selection incl. AStar3D pathfinds,
priority list: Urgent need > Work > Idle/Wander) — runs to completion,
never interrupted mid-pass by the next tick's budget check

Explicit FSM (per villager):
  enum State { DECIDING, TRAVELING, WORKING, SLEEPING, BREATHER, WANDERING }
  match state:
      State.DECIDING: ...   # one function per state, entry/exit/tick logic
      State.TRAVELING: ...  # inline in villager-ai-behavior.md's own rules —
      ...                   # no external framework, no tree, no score table
```

### Key Interfaces
```gdscript
# Villager AI's internal scheduling (implementation detail, not a public API):
var _deciding_queue: Array[int] = []  # villager ids, stable order maintained on enqueue
func _physics_process(delta: float) -> void:
    # driven by Time & Tick's tick signal, not raw delta — see architecture.md Data Flow
    pass

func _on_tick() -> void:
    var budget := config.max_deciding_per_tick
    while budget > 0 and not _deciding_queue.is_empty():
        var villager_id: int = _deciding_queue.pop_front()
        _run_deciding_pass(villager_id)  # full F2 selection, incl. AStar3D pathfinds
        budget -= 1

# Per-villager explicit FSM (implementation detail):
enum State { DECIDING, TRAVELING, WORKING, SLEEPING, BREATHER, WANDERING }
var _state: State = State.DECIDING
func _tick_state() -> void:
    match _state:
        State.DECIDING: _tick_deciding()
        State.TRAVELING: _tick_traveling()
        # ... one branch per state, matching villager-ai-behavior.md's rules directly
```

## Alternatives Considered

### Alternative A: Plain explicit FSM + tick-staggered budget, no threading — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: directly implements the GDD's already-fixed 6-state/strict-priority design with no framework overhead; staggering is simple to reason about and test (a queue + a counter); avoids thread-safety complexity entirely for a population scale that doesn't need it.
- **Cons**: if the AI's decision complexity grows substantially post-MVP (e.g., relationships/bonds, professions influencing decisions in Alpha), a plain FSM may need refactoring toward a more extensible pattern at that point — deferred, not a current cost.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Behavior tree
- **Description**: implement villager decisions as a tree of selector/sequence/condition/action nodes, using a behavior-tree framework or addon.
- **Pros**: scales well to deeply nested, frequently-changing conditional logic — valuable when a decision space grows organically over a project's lifetime.
- **Cons**: `villager-ai-behavior.md`'s decision space is small and fixed (6 states, one strict priority list) — a behavior tree here would essentially encode the same priority list through tree structure, adding framework indirection (node traversal, blackboard state) for no expressiveness the fixed design needs. Also introduces a third-party addon or a hand-rolled tree-execution engine as a new dependency, contradicting this project's stated aversion to unnecessary complexity (`technical-preferences.md`'s "Allowed Libraries / Addons: None configured yet").
- **Rejection Reason**: solves a flexibility/scale problem this project's fixed decision design doesn't currently have.

### Alternative C: Utility AI (scored candidate behaviors)
- **Description**: each candidate activity gets a continuous score; highest-scoring activity wins each Deciding pass.
- **Pros**: well-suited to blended, weighted decision-making where priorities aren't strictly categorical (e.g., "somewhat hungry and moderately tired" trading off smoothly).
- **Cons**: `villager-ai-behavior.md`'s priority order is explicitly discrete and strict (Urgent need > Work > Idle — a need being merely "urgent" always outranks work, full stop, never a blended trade-off), which is the opposite of what utility AI is designed to express; forcing a strict discrete order through a scoring system means picking scores far enough apart to never blend, which is just a strict FSM's priority list wearing a scoring-system costume.
- **Rejection Reason**: the GDD's design is categorically discrete, not continuously scored — utility AI's core value proposition doesn't apply here.

### Alternative D (threading question): `WorkerThreadPool` for parallel Deciding passes
- **Description**: run multiple villagers' Deciding passes concurrently on Godot's worker thread pool instead of tick-staggering them sequentially.
- **Pros**: could reduce worst-case latency if a single tick's full villager-count Deciding pass ever becomes the bottleneck.
- **Cons**: real thread-safety burden — Voxel World's occupancy dictionary, `AStar3D`'s graph, and Needs & Mood's per-villager state are none of them currently designed for concurrent access; retrofitting thread-safety (locks, or a more involved actor/message-passing redesign) is a substantial scope increase for a 20-30 villager ceiling that a simple scheduling budget is expected to already handle.
- **Rejection Reason**: solves a performance problem not yet confirmed to exist (unmeasured, pending the pre-VS spike), at a real, certain complexity cost. Named as the explicit escape hatch if the spike proves tick-staggering alone insufficient — not rejected as permanently wrong, rejected as premature, matching this project's established pattern (ADR-0003's chunked-mesher escape hatch, ADR-0007's provisional status).

## Consequences

### Positive
- Closes the OQ2 gap ADR-0007 didn't cover — every open architectural question in `villager-ai-behavior.md`'s explicit "deferred to the AI ADR" list is now resolved across ADR-0007 and this ADR together.
- No new third-party dependency, no addon — consistent with `technical-preferences.md`'s currently-empty Allowed Libraries list.
- Staggering is simple to unit-test: a queue length and a budget counter, no threading primitives to mock.

### Negative
- If villager decision complexity grows substantially in Alpha (professions, relationships influencing choices), the plain FSM may need a follow-up ADR to introduce more structure — an accepted future cost, not a current one.
- Tick-staggering adds latency for villagers queued behind the per-tick budget during a mass-Deciding event — bounded by design (worst case: `queue_length / max_deciding_per_tick` ticks of delay), but a real, measurable behavior change from "everyone decides instantly."

### Risks
- **Risk** (forward-looking, non-blocking): if the plain FSM is later refactored toward per-state polymorphic objects (a plausible evolution if Alpha-tier decision complexity grows, per the Negative consequence above), Godot 4.7's requirement that inherited method overrides include explicit `return` statements for typed return values will apply and must be followed — not relevant to the current single-script `match`-based FSM.
  **Mitigation**: no action needed now; a note for whoever performs that future refactor.
- **Risk** (forward-looking, non-blocking): if the pending-Deciding queue is ever "optimized" from `Array[int]` to a `PackedInt32Array`, Godot 4.7's changed packed-array element-assignment semantics (no longer invokes the full array property setter) would apply and should be checked at that time.
  **Mitigation**: not relevant to the current `Array[int]` design; noted for future reference only.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed no 4.4–4.7 change touches `WorkerThreadPool`, `Thread`, or GDScript's threading model, and confirmed there is no known Godot performance cliff for single-threaded GDScript at a 20-30 object scale — GDScript interpreter overhead only becomes a real concern at thousands+ of hot-path calls per frame, far beyond this project's population ceiling. The "avoid threading, stagger instead" reasoning was assessed as correct, not just permissible. Confirmed the enum + `match` FSM pattern, tick-driven execution, and `Array[int]` FIFO queue are all idiomatic with no current gotcha, flagging only the two forward-looking (non-blocking) notes above for future reference. Verdict: "safe to accept as written." No corrections were needed to the design itself.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| villager-ai-behavior.md | OQ2: "AI architecture — behavior tree vs. utility layer vs. plain FSM per agent" | Plain FSM, Decision §1 |
| villager-ai-behavior.md | TR-villager-ai-behavior-013: "Deciding-pass staggering: simultaneous mass-Deciding events must stagger F2 selection passes across frames in a stable, deterministic villager order" | Tick-staggered budget + FIFO queue, Decision §2 |
| villager-ai-behavior.md | TR-villager-ai-behavior-041: "Milestone-gated performance requirement: 16.6ms frame budget maintained at VS population (~5) and Full Vision ceiling (30)" | This ADR's mechanism is designed to satisfy it; actual verification is milestone-gated to the pre-VS spike, not solved by architecture alone |
| villager-ai-behavior.md | TR-villager-ai-behavior-047: "Pre-VS performance-spike requirement: synthetic 30-villager stress case... covering... staggered Deciding" | This ADR's staggering design is exactly what that spike measures |

## Performance Implications
- **CPU**: Bounds worst-case per-tick Deciding-pass cost to `max_deciding_per_tick` villagers' worth of F2 selection (including `AStar3D` pathfinds), regardless of how many become eligible simultaneously — the specific budget value is a tuning knob to be set empirically via the pre-VS spike, not fixed by this ADR.
- **Memory**: Negligible — one `Array[int]` queue of pending villager ids.
- **Load Time**: N/A.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- A unit test enqueues more villagers than `max_deciding_per_tick` in a single tick and asserts only the budgeted count runs a Deciding pass that tick, the rest remain queued in stable order, and are processed on subsequent ticks.
- The pre-VS performance spike (already tracked, `architecture.md` QQ3 / `villager-ai-behavior.md` OQ3) measures actual frame time at the 30-villager ceiling under 1x/3x warp with this staggering mechanism active; a PASS keeps this ADR Accepted as-is; a FAIL triggers evaluation of the `WorkerThreadPool` escape hatch.
- Grep-verifiable: zero `Thread`/`WorkerThreadPool` usage anywhere in Villager AI's implementation for MVP/VS.

## Related Decisions
- Depends on ADR-0007 for the `AStar3D` pathfinding this ADR schedules.
- Shares the pre-VS performance spike with ADR-0003 and ADR-0007 as its empirical validation step.
