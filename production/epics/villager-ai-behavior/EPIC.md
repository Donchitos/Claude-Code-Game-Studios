# Epic: Villager AI & Behavior

> **Layer**: Core
> **GDD**: design/gdd/villager-ai-behavior.md
> **Architecture Module**: Villager AI & Behavior (per-villager state machine; walkability predicates — canonical ground truth; job-claim consumption; F1–F4 movement/selection formulas)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 26 stories created (see Stories table below)

## Overview

Villager AI & Behavior owns everything a villager does: perceiving the world,
choosing an activity (build/sleep/eat/wander) via a plain explicit FSM, pathing to
it with `AStar3D`, and performing it. It owns the **canonical** walkability
predicates (`is_standable`/`is_step_legal`) that Build Validation (M02) must reuse
rather than redefine, the discrete `current_cell` body-column occupancy model
(the sole authoritative value, changing only at tick boundaries), deterministic
same-tick claim/movement ordering, the tick-driven Deciding-pass staggering with
the `max_deciding_per_tick` budget, and the anti-stuck watchdog + seal-prevention
that guarantee no villager is ever teleported, clipped, or trapped by ordinary
means. It is the labor half of the game loop, consuming Building System's job queue.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: AI Pathfinding, Navigation & Room Analysis | Custom `AStar3D` (graph built once at boot, incrementally patched on `cell_changed`, deterministic bit-packed point IDs); shared walkability predicates as the single source of truth; **zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`** (grep-verifiable) | HIGH |
| ADR-0008: Villager AI Execution & Threading | Plain explicit FSM (`match`, discrete priority); FIFO Deciding queue + `max_deciding_per_tick` budget (spike-tuned initial value: 1); **zero `Thread`/`WorkerThreadPool` in Villager AI** for MVP/VS; unstuck watchdog telemetry | MEDIUM |
| ADR-0009: Deterministic Movement & Occupancy Ordering | Discrete `current_cell` body-column is authoritative; `current_cell` changes at exactly two tick-boundary points (travel arrival + watchdog rescue); visual lerp render-only; synchronous-signal race closure; seal-prevention read side | HIGH |
| ADR-0012 | `serialize()/deserialize()`; `deserialize()` owns stale claim/bed-id revalidation — **VS-tier orchestrator** | MEDIUM |
| ADR-0002 / ADR-0001 | AI tunables (budgets, watchdog thresholds) from typed `.tres` config; injected-tier module | MEDIUM |

Engine-risk basis (4.7 policy): **HIGH** — Navigation/AI-Pathfinding is a flagged
HIGH-risk domain with a critical post-cutoff fact: **`AStarGrid3D` does NOT exist
in Godot 4.7** (only `AStarGrid2D`), so manual `AStar3D` graph management is the
only built-in option, and `AStar3D` IDs are never auto-recycled on `remove_point()`.
`NavigationServer3D` is forbidden (navmesh cannot express the exact cell rules).
Default signal connections are synchronous (load-bearing for the ADR-0009 race
closure). Cross-reference `docs/engine-reference/godot/` before any nav API.

## GDD Requirements

77 TRs registered (`TR-villager-ai-behavior-*`). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-villager-ai-behavior-009 / -010 / -011 / -035 / -036 | Pathfinding, shared walkability predicates | ADR-0007 ✅ |
| TR-villager-ai-behavior-013 / -041 / -047 | Deciding staggering, tick-burst budget, threading model | ADR-0008 ✅ |
| TR-villager-ai-behavior-046 | Deterministic mid-path solidification ordering | ADR-0009 ✅ |
| TR-villager-ai-behavior-016 | Headless-mockable via DI | ADR-0001 ✅ |
| TR-villager-ai-behavior-027 | Serialize position/activity/claim/bed/needs; stale-id revalidation | ADR-0012 ✅ (VS) |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; remaining TRs
are GDD-specified (F1–F4 formulas, FSM priority, bed ownership). No untraced
requirements.

**At-risk / deferred**: The one measured watch-item is Deciding-pass cost (avg
11 ms / p95 35 ms GDScript stand-in per the spike); mitigations before threading
are named (cheaper pre-filter, smaller BFS bound, pass slicing) — an accepted-risk
boundary, not an open decision. Threading remains the named escape hatch, not
built. Save orchestrator is VS-tier.

## Milestone 01 Notes — HOME OF ONE TECH DEBT (shared)

- **TECH DEBT 2 — Per-tick re-tuning pass (`max_deciding_per_tick` portion) lands
  here.** Milestone-01 Must-Ship "Per-tick re-tuning pass done." This epic owns
  the **`max_deciding_per_tick`** knob (ADR-0008, spike-tuned initial value 1),
  re-tuned against production load. The **tick-budget / base-tick-rate** half is
  owned by the `time-tick-system` epic — one coordinated config change spanning
  both, recorded once with shared rationale via the Foundation Spine `.tres`
  discipline.
- Delivers Must-Ship "Villager AI playable": FSM + AStar3D pathfinding, body-column
  occupancy, deterministic movement ordering (ADR-0009), threading model (ADR-0008),
  anti-stuck watchdog + seal prevention (watchdog telemetry exposed in F3).
- No CD-protected item lands here.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/villager-ai-behavior.md` are verified
- Grep proves zero `NavigationServer3D`/`NavigationAgent3D` and zero `Thread`/`WorkerThreadPool` in Villager AI
- Deterministic ordering, anti-stuck watchdog, and seal-prevention have passing logic unit tests
- The `max_deciding_per_tick` re-tune is recorded as a config change with rationale

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Villager AI config resource, DI scaffold & FSM state enum | Integration | Ready | ADR-0001/0002/0008 |
| 002 | Walkability predicates (is_standable / is_step_legal) | Logic | Ready | ADR-0007 |
| 003 | Body-column occupancy model (2-block character clearance) | Logic | Ready | ADR-0009 |
| 004 | Deterministic position model & movement interpolation | Logic | Ready | ADR-0009 |
| 005 | Deciding scheduler — FIFO queue + max_deciding_per_tick budget | Logic | Ready | ADR-0008 |
| 006 | Activity priority decision loop | Logic | Ready | ADR-0008 |
| 007 | AStar3D graph build & shortest-path query | Logic | Ready | ADR-0007 |
| 008 | Incremental AStar3D patching on cell writes (incl. dig-order) | Integration | Ready | ADR-0007/0009 |
| 009 | Traveling state — path following & mid-travel re-path | Integration | Ready | ADR-0009/0007 |
| 010 | F2 job selection (nearest-reachable, bounded candidates) | Logic | Ready | ADR-0007 |
| 011 | Job claim/release pipeline with worker attribution | Integration | Ready | ADR-0016/0008 |
| 012 | On-site work & full claim→build→report cycle | Integration | Ready | ADR-0016/0009 |
| 013 | Nudge-aside vacate (F4 target selection) | Logic | Ready | ADR-0009 |
| 014 | Rescue-target BFS (F5 expanding-ring search) | Logic | Ready | ADR-0007/0009 |
| 015 | Unstuck watchdog trigger, rescue teleport & telemetry | Logic | Ready | ADR-0008/0009 |
| 016 | Seal prevention negative-write gate & livelock escape (F6) | Logic | Ready | ADR-0009 |
| 017 | Dig/demolition on-site exclusion (self-undermine guard) | Logic | Ready | ADR-0009/0016 |
| 018 | Sleep & home — bed claim (move-in moment) | Integration | Ready | ADR-0008/0012 |
| 019 | Wandering & idle micro-behaviors (F3) | Logic | Ready | ADR-0008/0007 |
| 020 | Breather beat (between-jobs rest) | Logic | Ready | ADR-0008 |
| 021 | Starting roster spawn at world generation | Integration | Ready | ADR-0001/0002 |
| 022 | max_deciding_per_tick production re-tune (TECH DEBT 2) | Config/Data | Ready | ADR-0002/0008 |
| 023 | Scene-transition simulation continuity | Integration | Ready | ADR-0013/0008 |
| 024 | Villager AI save/load serialization (VS-tier) | Integration | Ready | ADR-0012 |
| 025 | Performance stress validation (30-villager, Advisory) | Integration | Ready | ADR-0008/0007 |
| 026 | Extract `VillagerWalkabilityRules` static twin (behavior-preserving) | Logic | Ready | ADR-0007 |

**Type totals**: 14 Logic, 11 Integration, 1 Config/Data.

**Needs-decision / flags**:
- **026** (walkability static extraction): created by TD ruling **BV-4** in
  `production/architecture-decisions-m02-preflight-2026-07-26.md` (**provisional —
  pending user ratification**). Cross-epic sequencing: it **must land before
  `build-validation-navigability` story 001**, whose DI shape depends on it.
  Mechanical, behavior-preserving; its correctness proof is that the existing
  suite stays green with **zero** test edits.
- **022** (max_deciding_per_tick re-tune): cross-epic coordination — one config change with the time-tick-system base-tick-rate story, shared rationale.
- **024** (save/load): Vertical-Slice-tier; **out of scope for Milestone 01** — testable now against a mocked serializer, but sequence into VS.
- **025** (perf stress): Advisory/Performance, milestone-gated — not part of the Logic gate, not an MVP-Done blocker.

## Next Step

Run `/story-readiness production/epics/villager-ai-behavior/story-001-config-and-scaffold.md`, then `/dev-story` to begin. Work stories in dependency order — each story's `Depends on:` field lists what must be DONE first.
