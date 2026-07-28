# Story 004: Tick accumulator + global tick signal (drift-free)

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-23 — 206/206 suite green, parent-verified; TR-046 joint assertion landed)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-032`, `TR-time-tick-system-033`, `TR-time-tick-system-034`, `TR-time-tick-system-028`, `TR-time-tick-system-029`, `TR-time-tick-system-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution & Threading) — primary (base tick rate = 4.0 ticks/sec, the tick signal simulation drives off); ADR-0002 — secondary (`ticks_per_second` from config)
**ADR Decision Summary**: Base tick rate = 4.0 ticks/sec (time-tick-system.md authoritative); exactly one global `tick` broadcast per tick — no per-consumer timers anywhere in the project. Simulation is tick-driven, never raw delta.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Runs in `_physics_process` (fixed 60 Hz step — verify 4.7 default is still 60). Accumulator MUST be GDScript `float` (float64) so long sessions don't lose sub-tick precision. `time_warp` is already baked into `game_delta`, so ticks naturally fire at `ticks_per_second × time_warp` — do not multiply again.

**Control Manifest Rules (this layer)**:
- Required: simulation runs on `game_delta` / the tick signal (base rate 4.0 ticks/sec); never blend raw delta and `game_delta` for one piece of state.
- Forbidden: per-consumer `Timer` nodes for tick timing — one shared global broadcast (ties to ADR-0011's no-per-consumer-timers precedent).

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] The accumulator is drift-free: a tick fires each time it crosses `tick_interval` via SUBTRACTION (never reset to 0) (GDD AC9). [TR-time-tick-system-032]
- [ ] Over 10,000 ticks at fixed `raw_delta`, accumulated drift stays under one `tick_interval` (GDD AC23). [TR-time-tick-system-032] [TR-time-tick-system-034]
- [ ] The accumulator runs in `_physics_process` (fixed step) (GDD Formulas). [TR-time-tick-system-033]
- [ ] With `time_warp = N`, ticks fire at `ticks_per_second × N` over one real-time second (GDD AC10). [TR-time-tick-system-028]
- [ ] No ticks fire while paused (GDD AC13). [TR-time-tick-system-029]
- [ ] Exactly ONE global `tick` broadcast occurs per tick; all subscribers share the same emission — no per-consumer timers (GDD AC22). [TR-time-tick-system-007]

---

## Implementation Notes

*Derived from ADR-0008 / ADR-0002 Implementation Guidelines:*

- `tick_accumulator += game_delta`; `while tick_accumulator >= tick_interval: emit tick(); tick_accumulator -= tick_interval`. Never `= 0` — subtraction is what keeps it drift-free.
- `tick_interval = 1 / ticks_per_second` (config `ticks_per_second = 4.0` → 0.25 s).
- Because pause makes `game_delta = 0`, the accumulator does not advance while paused — ticks stop with no special-case branch. Confirm no tick emits at `game_delta == 0`.
- Declare a single project-global `tick` signal on the Autoload; consumers `connect` to it. Do not create per-system timers.
- Worked example (GDD, `ticks_per_second=4.0`): `time_warp=2`, accumulator 0.2200 → `+0.0334` → 0.2534 → tick fires (crosses 0.25) → `-0.25` → 0.0034 carries forward.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the max-ticks-per-frame safety cap on catch-up.
- Story 006: scene-transition non-suspension of the accumulator.

---

## QA Test Cases

- **AC-1 (subtract not reset)**: Given accumulator at 0.2534, `tick_interval=0.25`; When processed; Then one tick fires and residue 0.0034 carries forward.
- **AC-2 (drift bound)**: Given 10,000 ticks at fixed `raw_delta`; When total simulated time is compared to `10000 × tick_interval`; Then |drift| < one `tick_interval`.
- **AC-3 (warp scaling)**: Given `time_warp=2`; When ticks are counted over one simulated second; Then count ≈ `ticks_per_second × 2`.
- **AC-4 (no ticks paused)**: Given paused; When physics frames advance; Then zero ticks fire.
- **AC-5 (single broadcast)**: Given M subscribers; When one tick is due; Then exactly one `tick` emission is observed by all (spy asserts one emit, M receipts).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/time_tick_system/tick_accumulator_test.gd` (GdUnit4) — deterministic 10k-tick harness at fixed `raw_delta`; must pass; drift-corpus runtime kept under the CI ≤60 s budget.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (game_delta), Story 003 (pause/warp state) — both DONE.
- Unlocks: Story 005, Story 006, Story 007.
