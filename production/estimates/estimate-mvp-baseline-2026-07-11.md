# Task Estimate: MVP Implementation Baseline

> **Generated**: 2026-07-11
> **Trigger**: Gate-check carried condition — "Run /estimate on the MVP set for the
> first timeline baseline" (`production/gate-checks/2026-07-11-systems-design-to-technical-setup.md`)
> **Status**: First baseline — NO historical velocity data exists yet.
> **Re-baseline**: After the first implemented epic (recommended: Time & Tick or
> Resource & Item Database), rerun `/estimate` with real sprint data.

## Task Description

Implement the 11 MVP systems (all GDDs approved, 13 Accepted ADRs, 471 registered
TR-IDs) up to the first playable build that tests the core hypothesis: draw a room,
furnish it, watch a villager live in it. Basis: solo dev + Claude Code agents,
GdUnit4 test mandate (BLOCKING for logic stories).

## Complexity Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Systems affected | 11 (all MVP systems) | 5 Foundation, 2 Core, 2 Feature, 2 Presentation |
| Requirements | 471 TR-IDs | ~100-140 stories after `/create-stories` bundling |
| New code vs modification | ~95% new | `src/` is empty; chunked-mesher prototype is reference only (throwaway, will be rewritten) |
| Integration points | 4 delicate seams | Input arbitration (ADR-0010), occupancy ordering (ADR-0009), boot gate (ADR-0005), tick contracts |
| Test coverage needed | High | Blocking unit tests for all logic ACs + property corpus (5,000 reachability verdicts, <=60s CI) |
| Existing patterns available | Yes | 13 Accepted ADRs + control manifest cover every known architecture question |

**Scope distribution (TR-IDs per system):** Building System 73, Villager AI 64,
Build Validation 51, Needs & Mood 44, Building UI 44, Resource DB 37,
Scene/World 34, Voxel World 34, Camera & Input 32, Villager Info UI 30,
Time & Tick 28.

## Effort Estimate

*Unit: focused working days in the established solo+AI workflow
(~2-3 sessions/day, ~3-4 stories/day — UNCALIBRATED assumption).*

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | 25 | AI parallelism fully effective, no integration surprises, tests pass headless first try |
| Expected | 38 | Normal pace, one review round per system, 1-2 integration blockers of ~1 day each |
| Pessimistic | 55 | Engine surprises (Godot 4.7 knowledge gaps), test-infrastructure friction, one seam needs redesign |

**Recommended budget: 38 days (~7-8 weeks calendar time at steady pace)**

This confirms the Producer warning from the gate check: the "~2-3 wks" label in
the systems index was sequencing intent, not an estimate — reality is ~3x that.

## Confidence: Medium

Drivers up: unusually complete design/architecture base (every requirement traced,
all risk spikes PASSED — rendering, QQ3, QQ5), established patterns for every known
question. Drivers down: **zero historical implementation velocity** (this is the
first baseline; the stories/day assumption is uncalibrated) and Godot 4.7 knowledge
gaps beyond the LLM cutoff.

## Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Velocity assumption uncalibrated | High | Medium | Re-baseline after the first epic — rerun `/estimate` with real sprint data |
| Building System (73 TRs) exceeds epic frame | Medium | Medium | At `/create-stories`, cut into tool-pipeline / job-queue / undo sub-epics |
| Test-infrastructure friction (headless GdUnit4, property corpus) | Medium | Medium | Run `/test-helpers` early; corpus budget (<=60s) as its own story |
| Godot 4.7 API deviations | Medium | Low-Medium | Check `docs/engine-reference/godot/` before every API use (existing rule) |
| The 4 integration seams surface late | Low | High | Build boot gate + DI wiring (ADR-0001/0005) as the very first epic, then integrate incrementally |

## Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|
| Vertical slice (bounded region) validates "fun" | Pending (roadmap step 2) | Per PR strategy, epics/stories start only after it — a PIVOT/KILL verdict would obsolete this baseline |
| Art bible S5-9 + asset specs | Pending | Blocks only visual-polish stories, not logic stories (placeholder assets suffice for the MVP hypothesis) |
| UX specs (HUD/menu/pause) | Pending | Blocks Building UI / Villager Info UI stories (~6 days of the budget) |

## Suggested Breakdown

| # | Sub-task | Estimate | Notes |
|---|----------|----------|-------|
| 1 | Boot/DI/config foundation (ADR-0001/0002/0005) + test helpers | 3 d | Must come first — everything else depends on it |
| 2 | Foundation systems (Time & Tick, Resource DB, Camera, Scene/World, Voxel World) | 14 d | Voxel World 4 d (mesher port + tests), rest 2-3 d each |
| 3 | Core (Building System, Villager AI) | 12 d | The two L systems; parallelizable once Foundation lands |
| 4 | Feature (Build Validation, Needs & Mood) | 7 d | Incl. property-test corpus |
| 5 | Presentation (Building UI, Villager Info UI) | 6 d | Needs UX specs |
| 6 | Integration, smoke gate, MVP playtest preparation | 3 d | `/smoke-check` + feel ACs |
| | **Total** | **~45 d gross -> 38 d expected** | Overlap through parallelization factored in |

## Notes and Assumptions

- **Unit**: a "day" = one focused solo+AI working day; calendar time depends on real
  session frequency.
- Scope boundary: the MVP set ONLY. Vertical-slice systems (combat, save/load,
  audio, wave defense, ...) are NOT included.
- The vertical slice (roadmap step 2) is a separate, prior throwaway build with
  deliberately relaxed standards — not part of these 38 days.
- Assumption: placeholder assets suffice for the MVP fun test; art production runs
  in parallel and does not block.
