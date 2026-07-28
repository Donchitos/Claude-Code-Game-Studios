# Story 015: Unstuck watchdog trigger, rescue teleport & telemetry

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-25 — 920/920 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-099`, `TR-villager-ai-behavior-104`, `TR-villager-ai-behavior-080`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution) — primary; ADR-0009 (sanctioned discrete teleport)
**ADR Decision Summary**: The watchdog is a cheap O(villagers) per-tick check for Traveling/Working agents; it fires a deterministic rescue teleport at `unstuck_watchdog_threshold_ticks`, sets `current_cell` atomically at the tick boundary and snaps `_visual_position` to match. This is the ONE sanctioned discrete-teleport exception. Telemetry counters are a hard requirement.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Watchdog scope is strictly Traveling/Working — Idle/Wandering/Sleeping/Breather are NEVER rescued (Edge Case 2 stay-put behaviour, included here as the scope boundary). At `ticks_per_second = 4.0`, the default 12-tick threshold = 3.0 game-seconds at 1x.

**Control Manifest Rules (this layer)**:
- Required (Core): `current_cell` changes at EXACTLY two sanctioned points — tick-boundary travel arrival and this watchdog rescue; the rescue sets `current_cell` atomically and snaps `_visual_position` (no lerp). The claim releases exactly as Rule 6's unreachable-job flow.
- Forbidden: rescuing Idle/Wandering/Sleeping/Breather villagers; snapping during ordinary travel; a double-release or orphaned claim.
- Guardrail: cheap O(villagers) per-tick check; `villager_unstuck` per-villager + world total counters exposed to F3 debug (hard requirement, sizing input for production build-order/scaffolding work).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `stuck_tick_count` increments each tick a Traveling/Working villager has zero legal step from `current_cell` OR `current_cell` fails standability; it resets to 0 the instant relief is available.
- [ ] Given `stuck_tick_count >= unstuck_watchdog_threshold_ticks`, the villager is teleported to the F5 rescue cell (Story 014), any held job claim releases back to the queue, and a `villager_unstuck` event fires with incremented per-villager AND world total counters (AC51).
- [ ] Given a held claim at rescue time, the claim releases exactly as Rule 6's unreachable-job flow — no double-release, no orphaned claim; given no held claim (e.g. traveling to a bed), no claim-release side effect and bed ownership is unaffected (AC52).
- [ ] The rescue sets `current_cell` atomically at a tick boundary and snaps `_visual_position` to match; the villager re-enters Deciding at the new cell; the counter resets so a villager is rescued only once per stuck episode.
- [ ] Idle, Wandering, Sleeping, and Breather villagers with no legal step remain in place with the distress flag set and never teleport (AC32, Edge Case 2 — the scope boundary complement).

---

## Implementation Notes

*Derived from ADR-0008/0009 Implementation Guidelines:*

- Per-tick, iterate Traveling/Working villagers; update `stuck_tick_count` from the body-column legal-step check (Story 003) and standability (Story 002).
- On fire: call the F5 BFS (Story 014) for the target; teleport (`current_cell = rescue_cell`, snap `_visual_position`); release any claim via the shared release path (Story 011); increment both counters; emit `villager_unstuck`; re-enter Deciding.
- Counters: a per-villager count and a world total, both exposed to the F3 debug console. Do NOT drop them — they are the required telemetry for the production-grade replacement.
- Edge Case 2 is the explicit non-rescue complement: Idle/Wandering/Sleeping/Breather set a distress flag and stay put.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 014: the BFS target selection + search-failed event.
- Story 016: seal-prevention livelock escape that relies on the watchdog to self-heal.

---

## QA Test Cases

- **AC51**: Given a Traveling/Working villager stuck (no legal step / non-standable cell) for `unstuck_watchdog_threshold_ticks`, When the threshold is reached, Then it teleports to a standable unoccupied cell, its claim releases, and `villager_unstuck` fires with incremented per-villager + total counters.
- **AC52**: Given a held claim at rescue, Then release exactly once (no double-release/orphan); Given no claim (traveling to a bed), Then no claim-release side effect, bed ownership unaffected.
- **AC32**: Given an Idle/Wandering/Sleeping/Breather villager with no legal step, Then it stays put with the distress flag, never teleports.
- Edge cases: `stuck_tick_count` resets on relief; rescue only once per episode; snap (no lerp) on rescue.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/unstuck_watchdog_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 014 (rescue BFS), 003 (body-column), 011 (claim release path)
- Unlocks: 016
