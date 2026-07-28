# Story 002: Boot-gate integration — Valley attaches only after RID Ready; DB-failure → terminal HALT

> **Epic**: Scene/World Management
> **Status: Complete (2026-07-23 — 198/198 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/scene-world-management.md` (Core Rule 1 boot gate, States table Booting row, AC17a/AC17b, Edge Case "Boot ordering (MVP)")
**Requirement**: `TR-scene-world-management-004`, `TR-scene-world-management-023`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: ADR-0005: Boot Sequencing & Initialization Gate (primary — Scene/World Management's Booting state is the boot-gate *host*; the gate *mechanism* is owned by the `foundation-spine` epic); ADR-0001 (secondary — injected-tier `setup()`)
**ADR Decision Summary**: The Valley attaches (and Building/Villager AI initialize) only after Resource & Item Database reaches `Ready`; on RID `Failed`, boot halts on a terminal error screen and the Valley is never attached — no empty-palette Valley. This story is the **scene-topology reaction** to the Foundation Spine's gate, not the gate itself.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: the boot-HALT is state-machine non-progression, NOT `SceneTree.paused` (forbidden project-wide) — nothing is instantiated at HALT, so there is nothing to pause (GDD Open Questions, re-review #3). The gate resolves synchronously in the common case (Autoloads ready before the Main Scene). Cross-reference `docs/engine-reference/godot/`.

**Control Manifest Rules (Foundation Layer)**:
- Required: unified boot gate — Booting state gates ALL injected-tier `setup()` behind RID `Ready`/`Failed`; on Failed → boot-halt screen, NO `setup()` calls, terminal.
- Forbidden: never poll for boot readiness; `SceneTree.paused` is project-wide forbidden (the HALT is non-progression, not an engine pause).
- Guardrail: the boot gate stays low-single-digit ms.

---

## Acceptance Criteria

*From `design/gdd/scene-world-management.md`, scoped to this story (MVP-tagged):*

- [ ] AC17a [MVP]: Given RID reaches `Ready` during boot, the Building System's and Villager AI's initialization each occur **only after** DB-Ready is observed.
- [ ] AC17b [MVP]: Given RID fails to reach `Ready`, boot halts on an error screen and the Valley scene is **never attached / made active** — no empty-palette Valley.
- [ ] The Valley scene attach (story 001's topology) is triggered on the gate's success path, not before.
- [ ] The HALT is terminal (requires application restart) and is implemented as state-machine non-progression — no `SceneTree.paused`.

---

## Implementation Notes

*Derived from ADR-0005 (host relationship) + GDD Booting-state row:*

- This story **consumes** the Foundation Spine's boot gate (ADR-0005 story 002 in `foundation-spine`) — it does not re-implement the `BootState` machine or the check-then-connect. It wires Scene/World Management's Valley-attach as the success-path action and the HALT-screen display as the failure-path action.
- On gate success (WIRING → ACTIVE): attach the Valley scene under the World Root (story 001), then the injected-tier `setup()` sweep initializes Building/Villager AI — order guaranteed by the gate, so AC17a holds by construction.
- On gate Failed (HALTED): show the boot-halt error screen (reuses the transition-overlay UI, TR-scene-world-management-032) and do NOT attach the Valley. Assert no Valley node exists in the tree.
- Test against the same mock RID double the Foundation Spine gate tests use — Ready and Failed variants.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- The `BootState` machine + RID check-then-connect mechanism — `foundation-spine` story 002 (this story reacts to it).
- Story 001: the World Root + Valley topology itself (this story only gates *when* the attach fires).
- Story 003: the transition-signal contract surface.
- RID's concrete validation pipeline — `resource-item-database` epic.

---

## QA Test Cases

*Automated test specs — the developer implements against these:*

- **AC17a (Ready → ordered init)**:
  - Given: boot driven with a mock RID reporting Ready.
  - When: boot completes.
  - Then: the Valley is attached, and Building System / Villager AI `setup()` (init) is observed to occur only after DB-Ready — never before.
  - Edge cases: Ready via synchronous `is_ready()` and via the deferred `validation_complete` signal both produce the same ordering.

- **AC17b (Failed → HALT, no Valley)**:
  - Given: boot driven with a mock RID reporting Failed.
  - When: boot runs.
  - Then: the boot-halt error screen is shown, state is HALTED, and no Valley scene node exists in the tree.
  - Edge cases: assert Building/Villager AI `setup()` was never called; assert `SceneTree.paused` was not used to implement the halt.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration test at `neues-spiel/tests/integration/scene_world_management/boot_gate_integration_test.gd` — must exist and pass headless (Ready→attach ordering + Failed→HALT-no-Valley).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (World Root + Valley topology) and Foundation Spine story 002 (the boot-gate mechanism) — both DONE.
- Unlocks: Story 003 (transition contract surface), and the Milestone-01 "Foundation systems run together in one scene" integration.
