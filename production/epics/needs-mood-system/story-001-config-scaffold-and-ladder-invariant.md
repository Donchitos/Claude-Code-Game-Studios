# Story 001: Config resource, DI scaffold, need schema & BLOCKING ladder invariant

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-26 — 1031/1031 suite green 0 orphans, agent-verified; parent re-verifies after the concurrent vox-020 lands)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-020`, `TR-needs-mood-system-031`, `TR-needs-mood-system-041`, `TR-needs-mood-system-051`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0001 (Inter-System Reference & DI Pattern); ADR-0005 (Boot Sequencing & Initialization Gate)
**ADR Decision Summary**: One `Resource`-derived config class per module extending `ConfigResource`, typed `@export` per Tuning Knob at GDD defaults, stored as `.tres` text; `validate() -> Array[String]` called exactly once in the owner's `setup()`. Two-tier policy, one return value: single-field range issue → clamp + warn + proceed; **GDD-declared BLOCKING cross-value invariant → `ConfigResource.format_blocking()` and the existing terminal boot-halt path**, never a new severity model. The module itself is injected-tier: typed `@export` deps wired in `GameWorld.tscn`, all wiring in an explicitly-callable `setup()`, `_ready()` does nothing beyond optionally calling it.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `load()` on a `.tres` returns the same shared cached object — config must be treated as read-only from every consumer. Scene-file `@export`s are populated before `_ready()`; code-assigned wiring is not, so never read a dependency in your own `_ready()`. `TimeTickSystem` is an Autoload — call it by global name, never `@export` it.

**Control Manifest Rules (this layer)**:
- Required (Foundation): one config class, typed `@export` fields, `.tres`; `validate()` called once at boot in `setup()`; injected-tier module receives its config as another `@export`; `setup()` asserts its dependencies; boot gate (ADR-0005) is the only `setup()` call site.
- Required (Foundation): a module whose BLOCKING result must reach `GameWorld`'s boot gate implements the duck-typed `get_boot_blocking_issues() -> Array[String]` — never a second `validate()` call site.
- Forbidden: `@export` an Autoload (`TimeTickSystem`/`ResourceItemDatabase`); write to a config field at runtime outside `validate()`'s own clamp; `ConfigFile`/JSON for tuning data.
- Guardrail: config loads once at boot; validation stays low-single-digit ms.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] `NeedsMoodConfig extends ConfigResource` exposes one typed `@export` per Tuning Knob at the GDD default: `decay_per_tick_sleep` (0.07), `base_recovery_per_tick_sleep` (0.5), `ground_penalty` (0.4), `unsheltered_bed_multiplier` (0.7), `urgency_threshold` (25), `satisfied_threshold` (95), `mood_smoothing_ticks` (40.0), `mood_band_happy` (70) / `mood_band_content` (40), `band_display_hysteresis` (0) — stored as a `.tres` text file. [TR-needs-mood-system-041]
- [ ] `validate()` range-checks each single-value knob against its GDD safe range (`decay_per_tick` 0.03–0.2, `base_recovery_per_tick` 0.2–2.0, `ground_penalty` 0.1–0.8, `unsheltered_bed_multiplier` 0.5–0.9, `urgency_threshold` 10–40, `satisfied_threshold` 80–100, `mood_smoothing_ticks` 10–120, hysteresis 0–3) — an out-of-range single field **clamps + warns + proceeds**, never halts.
- [ ] **AC29**: Given a config where `ground_penalty >= unsheltered_bed_multiplier` **or** `unsheltered_bed_multiplier >= 1.0`, When config loads, Then `validate()` returns a `BLOCKING:`-tagged issue naming the invariant `ground_penalty < unsheltered_bed_multiplier < 1.0` and the module reuses the terminal boot-halt path — loud failure, never a clamp. [TR-needs-mood-system-020]
- [ ] The need schema is **fixed and known from day one**: exactly `sleep` (MVP, active), `food` (VS, inactive), `company` (Alpha, inactive). Only `sleep` carries values in MVP; an inactive need is never defaulted into any computation. Adding a need type is a code/design change, not a data edit. [TR-needs-mood-system-031]
- [ ] The module is instantiable headless via `Node.new()` with mocks assigned to `@export` props / passed to `setup()` — zero scene tree, zero Autoload registration; `setup()` asserts its wired dependencies rather than silently proceeding.
- [ ] The per-tick math entry point is driven by Time & Tick's `tick` signal (Autoload, called by global name), never `_physics_process` raw delta and never a per-consumer `Timer`. The F-pass body itself is stories 002/003/005; this story lands the subscription and the strict F1 → F2 → F3 call-order skeleton. [TR-needs-mood-system-051]
- [ ] No gameplay value is hardcoded anywhere in the module — every number is read from the config resource. [TR-needs-mood-system-041]

---

## Implementation Notes

*Derived from ADR-0002/0001/0005 Implementation Guidelines:*

- `NeedsMoodConfig extends ConfigResource` (`src/foundation/config_resource.gd`), mirroring `TimeTickConfig`'s shape: `const *_MIN/_MAX` per ranged knob, clamp-in-place inside `validate()` (the one sanctioned runtime write to a config field).
- The ladder invariant is this project's **first genuine BLOCKING cross-value invariant** — `TimeTickConfig` never exercises that tier. Use `ConfigResource.format_blocking()` and `ConfigResource.has_blocking_issue()`; do not invent a second severity model, and do not clamp your way out of a violated ladder.
- The module is injected-tier: `@export var config: NeedsMoodConfig` plus whatever future deps stories add. `setup()` asserts, calls `config.validate()` once, and exposes `get_boot_blocking_issues()` so `GameWorld`'s Booting path can halt on a violated ladder.
- Tick subscription: `TimeTickSystem.tick` connected in `setup()` (synchronous default connection — load-bearing for story 003's intra-tick ordering rule). One handler, one strict pass order per tick: F1 decay → F2 recovery → F3 mood.
- Need schema as an `enum Need { SLEEP, FOOD, COMPANY }` plus an explicit active-set; `mean_active` (story 005) iterates the active set only.
- The bed/furniture ids that key the recovery table are **opaque string ids** — this system never calls Resource & Item Database or Building System at runtime (story 003's TR-052 check).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: F1 decay, the per-need state machine, and the urgent signal.
- Story 003: the source→rate table content and F2.
- Story 005: F3 mood math and band events.
- Story 009: whether the shipped `.tres` values are the *right* values at `ticks_per_second = 4.0` — this story ships the GDD defaults verbatim.

---

## QA Test Cases

**AC — config validate (single-field tier):**
- Given a `NeedsMoodConfig` with `decay_per_tick_sleep` = 0.5 (outside 0.03–0.2), When `validate()` runs, Then a warning string is returned and the value is clamped to 0.2 — boot proceeds.
- Edge cases: each knob exactly at both safe-range boundaries (inclusive, no warning); every knob present at its GDD default produces an empty issue array.

**AC29 — BLOCKING ladder invariant:**
- Given `ground_penalty = 0.7`, `unsheltered_bed_multiplier = 0.7`, When `validate()` runs, Then the returned array contains a `BLOCKING:`-prefixed issue naming `ground_penalty < unsheltered_bed_multiplier < 1.0`, and `ConfigResource.has_blocking_issue()` is true.
- Given `unsheltered_bed_multiplier = 1.0`, When `validate()` runs, Then the same BLOCKING outcome.
- Given `ground_penalty = 0.4`, `unsheltered_bed_multiplier = 0.7`, When `validate()` runs, Then no BLOCKING issue.
- Edge cases: a BLOCKING issue mixed with clamp warnings still dominates (`has_blocking_issue()` true); `setup()` on a blocking config does not proceed to normal operation.

**AC — need schema:**
- Given the `Need` enum, When inspected, Then it contains exactly `SLEEP`, `FOOD`, `COMPANY`; the active set contains exactly `SLEEP`.

**AC — headless DI:**
- Given the module built via `Node.new()` with a mock config assigned to its `@export`, When `setup()` is called directly, Then it succeeds with no scene tree and no Autoload registration.
- Edge cases: a missing config causes `setup()` to assert/fail rather than silently proceed.

**AC — tick subscription:**
- Given the module set up with a mock tick source, When a tick is dispatched, Then the F-pass entry point runs exactly once and in F1 → F2 → F3 order.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/needs_mood/config_scaffold_and_ladder_invariant_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None within this epic (assumes the Milestone-01 Foundation spine: `ConfigResource`, `GameWorld` boot gate, `TimeTickSystem` Autoload)
- Unlocks: 002, 003, 005
