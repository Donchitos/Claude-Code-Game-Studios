# Story 002: Boot-sequencing gate — BootState machine + RID Ready/Failed gate

> **Epic**: Foundation Spine (Boot, DI, Config & Test Harness)
> **Status: Complete (2026-07-23 — 19/19 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: N/A — ADR-driven infrastructure. Source: `docs/architecture/architecture.md` §Initialization order (step 2 BLOCKING GATE) + `design/gdd/scene-world-management.md` Edge Case "Boot ordering (MVP)".
**Requirement**: `TR-scene-world-management-004`, `TR-scene-world-management-023`, `TR-resource-item-database-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: ADR-0005: Boot Sequencing & Initialization Gate (primary); ADR-0001 (secondary — the `setup()`/`GameWorld` wiring this gate drives)
**ADR Decision Summary**: `GameWorld`'s `Booting` state gates ALL injected-tier `setup()` calls behind Resource & Item Database's `Ready`/`Failed` outcome — a single unified gate — using check-then-connect: a synchronous `is_ready()` check first, a `validation_complete.connect(..., CONNECT_ONE_SHOT)` fallback if not yet ready. On `Failed`: show the boot-halt screen, call NO injected-tier `setup()`, terminal. `BootState = {WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED}`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes** (from ADR-0005 Engine Compatibility + Control Manifest): Autoloads fully `_ready()` **before** the Main Scene loads (declared order, synchronous) — so RID's validation has usually already completed when `GameWorld._ready()` runs, which is why the synchronous `is_ready()` branch is the common path; the signal-connect branch future-proofs async validation. `.connect(callable, CONNECT_ONE_SHOT)` is used, NOT a literal `await` (single-threaded, no suspension point between check and connect, so no race). Cross-reference `docs/engine-reference/godot/` before finalizing.

**Control Manifest Rules (Foundation Layer)**:
- Required: unified boot gate — `GameWorld`'s Booting state gates ALL injected-tier `setup()` behind RID `Ready`/`Failed`; check-then-connect (synchronous `is_ready()` first, `validation_complete.connect(..., CONNECT_ONE_SHOT)` fallback); on Failed → boot-halt screen, NO `setup()` calls, terminal; `BootState: {WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED}`.
- Required: boot loads only the initial residency set, NOT the full world.
- Forbidden: never poll for boot readiness (per-frame/`Timer` polling contradicts the event-driven principle — use the signal); no injected-tier `setup()` call site outside `GameWorld`'s Booting path.
- Guardrail: the boot GATE itself stays low-single-digit ms.

---

## Acceptance Criteria

*Derived from ADR-0005 Decision + Validation Criteria and scene-world-management.md AC17a/AC17b:*

- [ ] `GameWorld` implements `enum BootState { WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED }` and progresses WAITING_FOR_DATABASE → WIRING → ACTIVE on RID success.
- [ ] On boot, `GameWorld` uses check-then-connect against RID: if `ResourceItemDatabase.is_ready()` is true, settle synchronously; else `validation_complete.connect(..., CONNECT_ONE_SHOT)`. No polling / `Timer` fallback exists.
- [ ] On RID success, every injected-tier module's `setup()` is called exactly once during the WIRING phase, then state becomes ACTIVE. (AC17a: Building System / Villager AI init occur only after DB-Ready is observed.)
- [ ] On RID `Failed`, the boot-halt screen is shown, state becomes HALTED, and NO injected-tier `setup()` is ever called (AC17b: Valley never attached — enforced downstream in scene-world-management story 002). The halt is terminal.
- [ ] The gate is the single choke point: no injected-tier `setup()` call site exists outside `GameWorld`'s Booting completion path (grep-verifiable).

---

## Implementation Notes

*Derived from ADR-0005 Decision §3 (check-then-connect) and §4 (not an ADR-0001 violation):*

- The RID Autoload exposes `signal validation_complete(result: ValidationResult)` (`result.success: bool`, `result.issues: Array[ValidationIssue]`) and `is_ready() -> bool`. RID's concrete implementation is the `resource-item-database` epic — **this story depends on that signal/getter shape but uses a mock RID double** for its own tests (ADR-0005 Validation Criteria explicitly test against a mock RID-shaped double reporting Ready/Failed).
- Gate skeleton (ADR-0005 §3):
  ```gdscript
  func _ready() -> void:
      _boot_state = BootState.WAITING_FOR_DATABASE
      if ResourceItemDatabase.is_ready():
          _on_database_settled(true, [])
      else:
          ResourceItemDatabase.validation_complete.connect(
              func(result): _on_database_settled(result.success, result.issues),
              CONNECT_ONE_SHOT)

  func _on_database_settled(success: bool, issues: Array) -> void:
      if not success:
          _show_boot_halt_screen(issues); return  # NO setup() ever called
      _boot_state = BootState.WIRING
      for module in _injected_tier_modules: module.setup()
      _boot_state = BootState.ACTIVE
  ```
- `GameWorld`'s `_ready()` hosting the gate is the sanctioned pattern, NOT the forbidden "read `@export` deps in `_ready()`" rule — `GameWorld` is the orchestration root, calling each child's `setup()` explicitly only after the gate resolves (ADR-0005 §4).
- The boot-halt screen reuses the transition-overlay UI infrastructure (TR-scene-world-management-032); its concrete visual is scene-world-management's concern — this story only needs the halt path to fire and to suppress all `setup()` calls.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Story 001: the DI wiring + `setup()` convention on injected-tier modules (this story consumes it).
- Story 003: config `validate()` clamp/halt handling (the config blocking-halt reuses THIS story's halt path but is specified there).
- scene-world-management story 002: attaching (or refusing to attach) the Valley scene as a consequence of Ready/HALTED — this story owns the gate mechanism; scene-world owns the scene-topology reaction.
- RID's concrete validation pipeline and the real `validation_complete` signal — `resource-item-database` epic. This story tests against a mock RID double.

---

## QA Test Cases

*Automated test specs — the developer implements against these (ADR-0005 Validation Criteria):*

- **AC-1/AC-3 (Failed → no setup, halt shown)**:
  - Given: `GameWorld` constructed with a mock RID-shaped double that reports `Failed`.
  - When: boot runs.
  - Then: zero injected-tier `setup()` calls occur, the boot-halt screen is shown, and state is HALTED.
  - Edge cases: Failed via immediate `is_ready()`-false + `validation_complete(success=false)`; assert no `setup()` even if injected modules are present.

- **AC-2 (Ready via synchronous branch)**:
  - Given: `GameWorld` with a mock RID reporting `is_ready() == true` immediately.
  - When: boot runs.
  - Then: every injected-tier module's `setup()` is called exactly once and state ends ACTIVE.
  - Edge cases: two injected modules → each `setup()` called exactly once, order stable.

- **AC-2 (Ready via signal branch)**:
  - Given: `GameWorld` with a mock RID that is not ready at `_ready()` time, then later emits `validation_complete(success=true)`.
  - When: the signal fires.
  - Then: every injected-tier module's `setup()` is called exactly once and state ends ACTIVE.
  - Edge cases: a second `validation_complete` emission must NOT re-run `setup()` (CONNECT_ONE_SHOT).

- **AC (single choke point)**:
  - Given: the source tree.
  - When: grep for injected-tier `setup()` call sites.
  - Then: the only call site is `GameWorld`'s Booting completion path.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit test at `neues-spiel/tests/unit/foundation/boot_sequencing_gate_test.gd` — must exist and pass headless.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (GameWorld root + injected-tier `setup()` scaffold) must be DONE.
- Unlocks: Story 003 (config blocking-halt reuses this halt path), Story 004 (headless boot integration test), scene-world-management story 002 (boot-gate scene-topology reaction).
