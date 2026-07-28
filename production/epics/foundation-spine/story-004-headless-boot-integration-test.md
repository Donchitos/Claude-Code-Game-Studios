# Story 004: Headless boot integration test — DI wiring + gate + config reads, green

> **Epic**: Foundation Spine (Boot, DI, Config & Test Harness)
> **Status: Complete (2026-07-23 — 128/128 suite green, parent-verified; Milestone SC#1 proven)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: N/A — ADR-driven infrastructure. This is the milestone's "headless boot test" that Milestone-01 Success Criterion #1 is verified against.
**Requirement**: `TR-resource-item-database-007`, `TR-scene-world-management-004`, `TR-building-ui-038`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time. This story proves the spine is headless-verifiable end to end.)*

**ADR Governing Implementation**: ADR-0005: Boot Sequencing & Initialization Gate (primary); ADR-0001 (DI wiring proven); ADR-0002 (external config reads proven)
**ADR Decision Summary**: The boot gate wires all injected-tier modules behind RID Ready and calls their `setup()`; this story proves that whole path runs green headless, exercising the DI mechanism (ADR-0001), the gate (ADR-0005), and external config reads (ADR-0002).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The GdUnit4 v6.1.3 harness is already stood up and green (`tests/README.md`, verified 2026-07-11); it runs headless with `--ignoreHeadlessMode`. This story adds the **boot integration test**, not the harness. A headless `Node.new()` construction never runs `_ready()`, so the test must drive `GameWorld`'s boot entry point explicitly (mirroring the `setup()`-parity rule from ADR-0001). Cross-reference `docs/engine-reference/godot/` for any GdUnit4 API specifics.

**Control Manifest Rules (Foundation Layer + Global)**:
- Required: tests instantiate with `Node.new()`, assign mocks to `@export` props, call `setup()` directly — zero scene tree, zero Autoload registration; the boot gate is a single choke point.
- Guardrail: RID tier-0 validation and the boot GATE each stay low-single-digit ms.
- Global: ripgrep has no `gdscript` type — always `rg --glob "*.gd"`. Logic/Integration stories need a passing GdUnit4 test before Done.

---

## Acceptance Criteria

*Derived from the epic Definition of Done ("a headless boot test proves DI wiring and external config reads") and Milestone-01 Success Criterion #1:*

- [ ] A headless integration test constructs `GameWorld` (or its boot entry point) with a mock RID double reporting `Ready` and proves the boot completes to `BootState.ACTIVE`.
- [ ] The test asserts every injected-tier module in the scene has had `setup()` called exactly once (DI wiring proven — ADR-0001).
- [ ] The test asserts at least one injected-tier module read a value from its injected config Resource rather than a hardcoded literal (external config reads proven — ADR-0002).
- [ ] A companion assertion proves the Failed path: a mock RID reporting `Failed` results in HALTED state and zero `setup()` calls (ADR-0005).
- [ ] The test runs green via `tests/run-tests.cmd` (GdUnit4 CLI headless) and lives under `neues-spiel/tests/integration/foundation/`.
- [ ] The test is deterministic (no random seeds, no wall-clock assertions) per project test standards.

---

## Implementation Notes

*Derived from ADR-0005 Validation Criteria + ADR-0001 test-path parity + `tests/README.md`:*

- Reuse the existing harness — do NOT re-stand-up GdUnit4. Add a suite `extends GdUnitTestSuite`, static typing enforced, following the `[system]_[feature]_test.gd` naming.
- Drive the boot entry point explicitly (the `setup()`/gate path), not via a live SceneTree `_ready()`, so the identical code path runs headless (ADR-0001 test-path parity).
- Use mock RID-shaped doubles for both Ready and Failed, exactly as ADR-0005's Validation Criteria describe; use reference injected-tier modules (from story 001) and a reference config (from story 003) as the fixtures.
- Keep the suite fast (low-single-digit ms boot) so it fits the property-corpus / CI budget the milestone quality gate expects (`property corpus <=60s CI`).
- Reports write to `neues-spiel/reports/` (gitignored) — do not commit them.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Stories 001–003: the GameWorld scaffold, gate, and config pattern themselves (this story integration-tests them, it does not build them).
- The property-based test corpus for individual gameplay systems (voxel/villager logic ACs) — those belong to each system's own epic; this story only proves the spine's boot path is headless-green.
- The full Foundation+Core E2E LOOP test (build → workers build → villagers navigate) — that is the Milestone-01 integration-to-playable feature (S3), not this spine test.
- scene-world-management story 002's Valley-attach/HALT scene behavior — asserted in that epic.

---

## QA Test Cases

*Automated test specs — the developer implements against these:*

- **AC-1/AC-2 (boot success proves DI wiring)**:
  - Given: `GameWorld` boot driven with a mock RID reporting Ready and N reference injected-tier modules present.
  - When: boot runs to completion.
  - Then: state is ACTIVE and each of the N modules has `setup()` called exactly once.
  - Edge cases: N=0 → boot still reaches ACTIVE with no `setup()` calls; N=2 → each exactly once.

- **AC-3 (external config read proven)**:
  - Given: a reference module wired with a config Resource whose knob is set to a non-default sentinel value.
  - When: boot completes and the module exposes/reads that knob.
  - Then: the module's behavior reflects the sentinel config value, proving it read config, not a literal.
  - Edge cases: changing the config field before boot changes the observed value (proving no hardcoding).

- **AC-4 (Failed path)**:
  - Given: `GameWorld` boot driven with a mock RID reporting Failed.
  - When: boot runs.
  - Then: state is HALTED and zero `setup()` calls occurred.
  - Edge cases: modules present but never wired — still zero `setup()`.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration test at `neues-spiel/tests/integration/foundation/boot_spine_integration_test.gd` — must exist and pass headless via `tests/run-tests.cmd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002, Story 003 all DONE (this test exercises all three).
- Unlocks: Story 005 (CONTRACTS.md references the green boot test as the spine's proof-of-life); downstream module epics inherit a proven boot substrate.
