# Story 006: F4 spawn initialization & new-need activation

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — 1307/1307 suite green 0 orphans, parent-verified; production call site wired separately, see follow-up)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~0.5 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-056`, `TR-needs-mood-system-061`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (spawn values are config-derived, not literals) — primary; ADR-0005 (initialization order: needs are initialized per starting villager during the boot sequence, after the module's `setup()`)
**ADR Decision Summary**: Config is the only source of tunable values, and `setup()` is the single explicit initialization entry point — a villager's needs are initialized through a called API, never in `_ready()` and never inferred from scene state.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript. Note the ordering trap this AC exists to prevent: a mood field left at its zero-default displays **Low** for the ~10 s (at `ticks_per_second = 4.0`) the EMA needs to catch up — a cold-start visual bug, not a math bug.

**Control Manifest Rules (this layer)**:
- Required (Foundation): initialization happens in an explicitly-callable method reached from the boot path, never in `_ready()`.
- Required (Feature): the active-need set from story 001's schema governs what gets initialized; inactive needs are absent, not zeroed.
- Forbidden: initializing mood to 0 or to a literal; re-running F4 on an existing villager (that is what would erase smoothing state on load — story 012's AC24).
- Guardrail: initialization is O(active needs) per villager, once per spawn.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC17**: Given a new villager spawns, When initialized, Then every **active** need is 100 and mood equals `mean_active` — never 0 (F4). [TR-needs-mood-system-056]
- [ ] **AC26**: Given a version adds a new active need (mocked schema change), When an existing villager loads, Then the new need initializes at 100 and `mean_active` simply gains a term — nobody starts the patch day starving (Edge Case 5). [TR-needs-mood-system-061]
- [ ] Initialization is idempotent per villager id: calling it twice for the same, already-initialized villager does not silently reset live values (it is either rejected or a documented no-op — never a silent overwrite).
- [ ] A newly spawned villager's queryable state is `Satisfied` for every active need, with no urgent/satisfied/band event emitted at spawn.

---

## Implementation Notes

*Derived from ADR-0002/0005 Implementation Guidelines:*

- F4 is two lines and one trap: `needs ← 100 (each active need)` then `mood ← mean_active`. The trap is the second line — reuse story 005's `mean_active` function so the two can never diverge.
- New-need activation (AC26) is the same code path applied to an existing villager: for each active need with no stored value, initialize at 100. That makes the VS `food` rollout a schema flip plus a config value, not a migration script.
- Spawn is reported to this system by whoever creates villagers (`villager-ai-021` starting roster in production, a direct call in tests). This module does not watch the scene tree for new villagers.
- Do not emit events at spawn. A villager born at 100 has crossed nothing; the first legitimate event is the urgency cross ~1072 ticks later.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the `mean_active` and mood math themselves.
- Story 012: restoring mood from a save (the explicit **not**-F4 path, AC24).
- `villager-ai-021`: spawning the starting roster that calls this.

---

## QA Test Cases

- **AC17**: Given a fresh villager id, When initialized, Then `get_need_value(id, sleep) == 100.0`, mood `== 100.0` (mean of the single active need), and the band reads **Happy**.
- **AC17 (negative)**: Given a fresh villager, When initialized, Then mood is never 0.0 at any point observable by a query — no transient Low band.
- **AC26**: Given an existing villager with `sleep = 40` and a mocked schema change activating `food`, When the activation path runs, Then `food == 100.0`, `sleep == 40.0` (untouched), and `mean_active == 70.0`.
- **Idempotence**: Given an initialized villager with `sleep = 30`, When initialization is called again for the same id, Then `sleep` is still 30 (no silent reset).
- **No spawn events**: Given a spawn, When the initialization completes and one tick fires, Then zero urgent, satisfied, and band-change events were emitted.
- Edge cases: initializing two villagers in the same tick keeps their values independent; initializing with all needs inactive (a degenerate config) yields a documented, non-crashing mood (mean over an empty set must not divide by zero).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/spawn_init_and_need_activation_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (need values/state), 005 (`mean_active`, mood, bands)
- Unlocks: 010 (a live villager must be initialized before the round trip)
