# Story 001: Villager AI config resource, DI scaffold & FSM state enum

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 295/295 suite green, parent-verified; Core layer opened)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-016`, `TR-villager-ai-behavior-090`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern) — primary; ADR-0002 (Tuning/Config Data Strategy); ADR-0008 (Villager AI Execution & Threading) for the FSM state set
**ADR Decision Summary**: New systems are injected-tier — typed `@export` refs wired in `GameWorld.tscn`, all wiring in an explicit `setup()`; one `Resource`-derived config class per module with typed `@export` fields (one per Tuning Knob) stored as a `.tres`, exposing `validate() -> Array[String]`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Scene tree readies bottom-up — scene-file `@export`s are populated before `_ready()`, code-assigned wiring is NOT; `load()` on a `.tres` returns the same shared cached object (config must be read-only). Never `@export` an Autoload.

**Control Manifest Rules (this layer)**:
- Required: injected-tier module; all wiring/validation in an explicitly-callable `setup()` that asserts its deps; `_ready()` does nothing beyond optionally calling `setup()`. One config class, typed `@export` fields, `.tres`, `validate()` called once at boot.
- Required (Feature layer): AI is a plain explicit FSM — state enum + `match`; tick-driven via Time & Tick's signal, never raw delta.
- Forbidden: `@export` an Autoload (`TimeTickSystem`/`ResourceItemDatabase`); read `@export` deps inside own `_ready()`; write to a config field at runtime; `ConfigFile`/JSON for tuning.
- Guardrail: config loads once at boot; validation low-single-digit ms.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `VillagerAIConfig` is a `Resource`-derived class with one typed `@export` per Tuning Knob (`move_speed`, `decision_interval`, `unreachable_retry_ticks`, `wander_radius`, `wander_interval`, `job_candidate_count`, `max_selection_candidates`, `jobs_before_break`, `breather_duration_ticks`, `starting_villager_count`, `max_deciding_per_tick`, `unstuck_watchdog_threshold_ticks`, `unstuck_rescue_search_radius`, `unstuck_rescue_max_radius`, `seal_prevention_abandon_limit`) at the GDD defaults, stored as a `.tres`.
- [ ] `validate() -> Array[String]` range-checks each knob against its GDD safe range; a single-field range issue warns + clamps + proceeds.
- [ ] The module is instantiable headless via `Node.new()` with mocks assigned to `@export` props / passed to `setup()` — zero scene tree, zero Autoload registration (TR-016 DI).
- [ ] A `State` enum defines exactly the six states `{ DECIDING, TRAVELING, WORKING, SLEEPING, BREATHER, WANDERING }`; per-villager state is driven by `match` on a tick signal, never raw delta.
- [ ] All gameplay values are read from the config resource — no hardcoded tunables anywhere in the module (TR-090).

---

## Implementation Notes

*Derived from ADR-0001/0002/0008 Implementation Guidelines:*

- One `VillagerAIConfig extends Resource`; injected as another `@export` on the module. Consumers read config; never write a config field at runtime (runtime-adjustable state gets its own owned var).
- `setup()` asserts dependencies are wired (Voxel World ref, Time & Tick, config) and calls `config.validate()` once. Boot gate (ADR-0005) gates `setup()` behind RID Ready/Failed — do not call `setup()` from `_ready()`.
- FSM is a single script: `enum State { … }` + `_tick_state()` with a `match _state` branch per state (bodies land in later stories). No behavior-tree or utility-AI addon (breaches the empty Allowed-Libraries list).
- Tick execution is driven by Time & Tick's tick signal (base tick rate 4.0 ticks/sec), never `_physics_process` raw delta.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the walkability predicates themselves.
- Story 005: the Deciding scheduler queue + budget behaviour.
- Story 006: the priority decision logic inside `_tick_deciding()`.

---

## QA Test Cases

**AC — config validate:**
- Given a `VillagerAIConfig` with `move_speed` set outside `1.5–6.0`, When `validate()` runs, Then a warning string is returned and the value is clamped into range (not a boot-halt).
- Edge cases: value exactly at each safe-range boundary (inclusive); every knob present with its GDD default.

**AC — headless DI (TR-016):**
- Given the module built via `Node.new()` with mock Voxel World / Time & Tick / config assigned to `@export`s, When `setup()` is called directly, Then it succeeds with no scene tree and no Autoload registration.
- Edge cases: a missing required dependency causes `setup()` to assert/fail rather than silently proceed.

**AC — state enum:**
- Given the `State` enum, When inspected, Then it contains exactly the six named states and no others.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/villager_ai/config_and_scaffold_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first story of the epic; assumes the Boot/DI/config spine from Milestone-01 Foundation exists)
- Unlocks: 002, 004, 005, 023
