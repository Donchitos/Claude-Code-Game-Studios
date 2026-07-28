# Story 003: Config Resource pattern — typed `.tres` + `validate()` two-tier clamp/halt

> **Epic**: Foundation Spine (Boot, DI, Config & Test Harness)
> **Status: Complete (2026-07-23 — 36/36 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: N/A — ADR-driven infrastructure. This story establishes the config pattern every GDD's Tuning Knobs section consumes.
**Requirement**: `TR-scene-world-management-030`, `TR-voxel-world-023`, `TR-camera-input-019`, `TR-time-tick-system-020`, `TR-building-system-038`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time. All five state the same "tunables read from data/config, never hardcoded" requirement this pattern satisfies uniformly.)*

**ADR Governing Implementation**: ADR-0002: Tuning/Config Data Strategy (primary); ADR-0001 (secondary — config is injected via the same `@export` mechanism); ADR-0005 (secondary — blocking-invariant halt reuses the boot-halt path)
**ADR Decision Summary**: One custom `Resource`-derived config class per module, typed `@export` fields (one per Tuning Knob, GDD-default values), stored as `.tres` text files. Each exposes `validate() -> Array[String]`, called once at boot in the owner's `setup()`. Two tiers: single-field range issue → warn + clamp + proceed; GDD-declared BLOCKING cross-value invariant → terminal boot-halt (reusing RID's Failed pattern). Config is read-only at runtime from every consumer.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes** (from ADR-0002 Engine Compatibility + Control Manifest "Engine Facts"): `load()`/`preload()` on the same `.tres` path returns the **same shared cached object** (`ResourceLoader` `CACHE_MODE_REUSE`, refcounted) — a runtime write to any config field is visible to every holder, project-wide, silently. This is the reason config MUST be read-only. `.tres` (text) vs `.res` (binary) is purely extension-driven. Do NOT introduce `duplicate_deep()` (4.5+). Cross-reference `docs/engine-reference/godot/`.

**Control Manifest Rules (Foundation Layer)**:
- Required: one custom `Resource`-derived config class per module, typed `@export` fields, stored as `.tres`; injected modules get config as another `@export`; Autoloads `load()` their own via `const CONFIG_PATH`. Every config class exposes `validate() -> Array[String]`, called once at boot in the owner's `setup()`. Single-field range issue → warn + clamp + proceed; GDD-declared BLOCKING cross-value invariant → terminal boot-halt.
- Forbidden: never write to a config Resource field at runtime (grep `config\.\w* *=` outside the config class's own clamp logic = zero); never `ConfigFile` or JSON for tuning data.
- Guardrail: config loads once at boot; validation must stay low-single-digit ms.

---

## Acceptance Criteria

*Derived from ADR-0002 Decision + Validation Criteria:*

- [ ] A `Resource`-derived config class pattern is established with typed `@export` fields and a `validate() -> Array[String]` method, backed by a `.tres` text file (never `.res`).
- [ ] Injected-tier modules receive their config as an `@export var config: <System>Config` (ADR-0001 mechanism); the config is trivially constructable in a test via `<System>Config.new()` + direct field assignment, no file I/O.
- [ ] `setup()` calls `config.validate()` once at boot: a single-field out-of-range value produces a warning string, is clamped to the nearest valid bound, and boot proceeds.
- [ ] A GDD-declared BLOCKING cross-value invariant that fails `validate()` triggers the terminal boot-halt (the same path as ADR-0005 story 002's RID-Failed halt) — no new severity model is invented.
- [ ] No config field is written to outside a `validate()`/clamp call (grep-verifiable).
- [ ] All config files use the `.tres` extension (verifiable: zero `.res` config files).

---

## Implementation Notes

*Derived from ADR-0002 Decision (validation tiers + immutability rule) and Key Interfaces:*

- Config class shape (ADR-0002 §Key Interfaces):
  ```gdscript
  class_name <System>Config extends Resource
  @export var some_knob: float = <GDD-stated default>
  func validate() -> Array[String]:
      var issues: Array[String] = []
      # single-field: append warning; caller clamps
      return issues
  ```
- Two validation tiers in `setup()`:
  - single out-of-range scalar → `validate()` warning string → clamp to nearest bound → proceed (NEVER halt for an isolated scalar);
  - cross-value invariant a GDD marks BLOCKING → treat non-empty result as boot-halt via the ADR-0005 terminal pattern.
- Autoload-tier services (TimeTickSystem, RID) load their own config via `const CONFIG_PATH` + `load()` in their own `setup()` (their concrete config lives in their epics) — this story establishes the **pattern + the clamp/halt handling**, demonstrated with a reference config class; per-module config `.tres` files are authored alongside each module's own story.
- Cross-module invariants (e.g. Build Validation reading Building System's config for `max_room_height >= wall_height`) are validated by whichever module's GDD states them — a documented per-instance exception, NOT built generically here.
- Immutability is absolute after boot clamp: config is read-only from every consumer.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Story 002: the boot-halt path itself (this story reuses it for blocking-invariant failures).
- Concrete per-module config classes and their `.tres` files (`TimeTickConfig`, `VoxelWorldConfig`, `CameraInputConfig`, etc.) — authored in each module's own epic/story with defaults from that GDD's Tuning Knobs section.
- Specific cross-module blocking invariants (needs-mood ladder-ordering, build-validation height) — those are Milestone-02 Feature-layer concerns; this story only establishes that the blocking-halt tier exists.

---

## QA Test Cases

*Automated test specs — the developer implements against these (ADR-0002 Validation Criteria):*

- **AC-3 (valid config → no issues, proceed)**:
  - Given: a reference config constructed via `.new()` with all fields at GDD defaults.
  - When: `validate()` runs.
  - Then: it returns an empty array and boot proceeds.
  - Edge cases: boundary values exactly at the safe-range edges → valid, no warning.

- **AC-3 (single-field out-of-range → warn + clamp + proceed)**:
  - Given: a config with one scalar set outside its documented safe range.
  - When: `setup()` runs `validate()` and applies clamping.
  - Then: a warning string is produced, the field is clamped to the nearest valid bound, and boot proceeds (no halt).
  - Edge cases: below-min clamps to min; above-max clamps to max; the clamp write is the ONLY sanctioned config write.

- **AC-4 (blocking invariant → terminal halt)**:
  - Given: a config whose GDD-declared BLOCKING cross-value invariant is violated.
  - When: `setup()` evaluates `validate()`.
  - Then: the terminal boot-halt path fires (same as RID-Failed), reusing the ADR-0005 mechanism — no new severity scheme.
  - Edge cases: a single-field warning present alongside a blocking failure → still halts (blocking dominates).

- **AC (read-only enforcement)**:
  - Given: the source tree.
  - When: grep `config\.\w* *=` outside config classes' own clamp logic.
  - Then: zero matches.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit test at `neues-spiel/tests/unit/foundation/config_resource_validate_test.gd` — must exist and pass headless (covers valid / clamp-warn / blocking-halt tiers).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config injected via the `@export` mechanism), Story 002 (blocking-invariant halt reuses the boot-halt path). Both must be DONE.
- Unlocks: Story 004 (headless boot test proves external config reads), and every module epic's config `.tres` authoring.
