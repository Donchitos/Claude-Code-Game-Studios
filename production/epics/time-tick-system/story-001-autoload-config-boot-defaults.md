# Story 001: Time & Tick Autoload skeleton + config resource + boot defaults

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-23 — 46/46 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-020`, `TR-time-tick-system-038`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0001 (Inter-System Reference & DI Pattern) — secondary
**ADR Decision Summary**: One custom `Resource`-derived config class, typed `@export` field per tuning knob, stored as a `.tres`; this system is one of only two Autoloads and `load()`s its own config via `const CONFIG_PATH`. Config exposes `validate() -> Array[String]`, called once at boot.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Autoloads fully `_ready()` **before** the Main Scene loads (declared order, synchronous) — boot defaults are set here, not deferred. `load()` on the same `.tres` returns the shared cached object — treat config as read-only.

**Control Manifest Rules (this layer)**:
- Required: ONLY `TimeTickSystem` and `ResourceItemDatabase` are Autoloads; Autoloads `load()` their own config via `const CONFIG_PATH`; one custom `Resource` config class with typed `@export` fields stored as `.tres` (ADR-0002/0001).
- Required: config `validate() -> Array[String]` called once at boot; single-field range issue → warn + clamp + proceed (ADR-0002).
- Forbidden: never write to a config Resource field at runtime (`config.x = ...` outside the config class's own clamp logic must grep to zero); never `ConfigFile`/JSON for tuning data.
- Guardrail: config loads once at boot.

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] No hardcoded values — `time_warp_options`, `ticks_per_second`, `max_ticks_per_frame`, and `max_raw_delta` are all read from the typed config resource (GDD AC18). [TR-time-tick-system-020]
- [ ] At boot the system defaults to `paused = false`, `time_warp = 1` (GDD AC14). [TR-time-tick-system-038]
- [ ] Config `validate()` runs once at boot; out-of-safe-range single-field values warn + clamp; the system proceeds.
- [ ] `TimeTickSystem` is registered as an Autoload and readies before the Main Scene; it consumes no other system (zero upstream dependencies).

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0001 Implementation Guidelines:*

- Create a `TimeTickConfig extends Resource` with typed `@export` fields: `ticks_per_second: float` (default 4.0), `max_ticks_per_frame: int` (default 10), `max_raw_delta: float` (default 0.1), and the `time_warp_options` set ({1,2,3}). Store as a `.tres` text file.
- `TimeTickSystem` (Autoload) declares `const CONFIG_PATH` and `load()`s its own config in `setup()` (or the Autoload equivalent). Do NOT read config in `_ready()` under a code-assigned-wiring assumption.
- `validate()` returns `Array[String]`; safe ranges from GDD Tuning Knobs (`ticks_per_second` 1.0–5.0, `max_ticks_per_frame` 5–30, `max_raw_delta` 0.05–0.2). Single-field range issue → warn + clamp + proceed (not a terminal halt — no BLOCKING cross-value invariant here).
- Set `paused = false`, `time_warp = 1` as initial owned state (NOT config — these are runtime state defaults per GDD Edge Case "Game boot").

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the `game_delta` formula itself.
- Story 003: pause/warp toggle behaviour.
- Story 004: the tick accumulator and `tick` signal.
- Story 007: re-tuning the config values against production load.

---

## QA Test Cases

*Derived from GDD acceptance criteria (lean mode — qa-lead gate skipped; specs authored from ACs).*

- **AC-1 (config-driven)**: all four tunables read from config.
  - Given: a `TimeTickConfig` `.tres` with non-default values.
  - When: the system loads config at boot.
  - Then: the system's effective tunables equal the config values, not hardcoded literals.
  - Edge cases: value outside safe range → clamped + warning string returned by `validate()`.
- **AC-2 (boot defaults)**: default state at init.
  - Given: a freshly-instantiated `TimeTickSystem`.
  - When: boot/init completes.
  - Then: `paused == false` and `time_warp == 1`.
  - Edge cases: config with no bearing on these defaults (they are runtime state, not config).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/time_tick_system/autoload_config_boot_test.gd` (GdUnit4) — instantiate via `Node.new()`, assign a mock config, call `setup()` directly; assert defaults and config-driven values without scene tree or Autoload registration.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation leaf; consumes nothing). Foundation-spine test harness (`foundation-spine` epic) is the shared scaffolding.
- Unlocks: Story 002 (game_delta), Story 003 (pause/warp), Story 004 (tick accumulator).
