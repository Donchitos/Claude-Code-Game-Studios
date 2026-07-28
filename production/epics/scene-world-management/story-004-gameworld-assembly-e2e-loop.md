# Story 004: GameWorld scene assembly + headless E2E LOOP test — THE INTEGRATION CROWN

> **Epic**: Scene / World Management
> **Status: Complete (2026-07-24 — 636/636 suite green, parent-verified — THE CROWN: milestone criterion #8 met)
> **Layer**: Foundation (scene composition) → integrates Core (Building + Villager AI)
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/scene-world-management.md` (composition) + Milestone 01 exit criterion #8
**Requirement**: Milestone 01 Must-Ship "Integrated playable build" + Quality Gate "Headless
E2E LOOP test green on every commit"
*(No new TR — this story is the assembly seam the milestone's integration-to-playable row names;
it consumes the ACs the per-system stories already own.)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI) — primary; ADR-0005
(Boot Sequencing & Initialization Gate) — secondary; ADR-0013 (Multi-Scene Concurrency) — secondary
**ADR Decision Summary**: The Valley wires the Foundation + Core tier modules (Voxel World grid +
chunked mesher, Camera & Input, Building System, Villager AI) into GameWorld's `injected_tier_modules`
via DI (`setup()` wiring, spine-001 pattern), booting behind the ADR-0005 gate. No module reaches
across the DI boundary; the assembled scene is the first build in which the build-and-inhabit loop
runs end-to-end.

**Engine**: Godot 4.7-stable | **Risk**: HIGH (integration — the historical failure mode is wiring
gaps E2E cannot catch until the systems are actually assembled)
**Engine Notes**: Assembly-only — no new engine APIs beyond those the consumed stories already
cross-referenced. The E2E LOOP test runs fully headless (GdUnit4); villager movement asserts on the
discrete `current_cell` (never `_visual_position`); the place-a-block path asserts on Voxel World grid
data + the batched `cells_changed_batch` signal (vox-003, DONE). Keep the typed-Array crash-class
regression call in this test.

**Control Manifest Rules (this layer — scene composition):**
- Required: all tier modules wired via `injected_tier_modules` DI (ADR-0001); the Valley attaches
  only after the RID Ready boot gate (ADR-0005 / scene-002 precedent); the E2E LOOP test is headless
  and runs in the commit gate.
- Forbidden: no direct cross-module references outside the injected DI surface; no physics colliders
  introduced for the block-pick or villager-move paths (ADR-0004 / ADR-0009 stay intact); no
  `SceneTree.paused` / `Engine.time_scale`.
- Guardrail: the loop test asserts BOTH halves independently (place-a-block AND villager-walk) so a
  single-half failure is diagnosable, not a monolithic red.

---

## Acceptance Criteria

- [ ] AC-ASSEMBLY: GameWorld assembles Voxel World (grid + mesher), Camera & Input, Building System,
      and Villager AI into the Valley via `injected_tier_modules` (DI, ADR-0001) and boots through the
      ADR-0005 initialization gate — verified by a headless scene-boot assertion (all modules present,
      wired, and Ready).
- [ ] AC-PLACE-A-BLOCK: a placement committed through the real pick pipeline (screen ray → camera
      `get_world_ray()` → voxel DDA → tool commit → construction tick) results in a real Voxel World
      cell write — the block appears in grid data and exactly ONE batched `cells_changed_batch` fires
      — asserted headlessly (consumes building-021 commit + building-029 tick-write).
- [ ] AC-VILLAGER-WALKS: a villager runs a Deciding pass (villager-ai-005/006), queries an AStar3D
      path (villager-ai-007), and follows it cell-by-cell to arrival — asserted on discrete
      `current_cell` transitions ending at the target (consumes villager-ai-009).
- [ ] AC-E2E-GATE: the E2E LOOP test lives in `neues-spiel/tests/integration/scene_world/` and is
      wired into the commit gate (Milestone 01 criterion #8 + Quality Gate "Headless E2E LOOP test
      green on every commit"); the typed-Array crash-class regression call is included.

---

## Implementation Notes

*Derived from ADR-0001/0005/0013 + spine-001 DI scaffold + scene-001/002 attach precedent:*

- Extend the GameWorld `setup()` wiring (spine-001) to inject the Voxel World, Camera & Input,
  Building System, and Villager AI tier modules; attach the Valley behind the RID Ready gate exactly
  as scene-002 established. No new autoloads (Time & Tick + RID remain the only two).
- The place-a-block path drives the existing seams: building-021 commit → building-029 construction
  tick loop issues the Voxel World write via the DONE `bulk_write` (vox-003). The batched write seam
  hardening (building-033) is NOT required here — 029's per-completion write is sufficient for the
  loop; assert the single batched signal via vox-003's exactly-one-signal guarantee.
- The villager-walk path drives villager-ai-005→006 (decide) and 007→008→009 (path + follow). The
  test may seed a wander/travel target; the fully-closed job-claim→build loop (building-030 +
  villager-ai-011/012) is next-sprint and explicitly out of scope here.
- Keep both halves as separate assertions in one test scene so a half-failure is isolatable.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- building-033: the batched write seam + self-write exemption (blocked by building-032 undo stack) —
  next sprint; 029's direct write suffices for the loop.
- building-030 + villager-ai-011/012: the fully-closed job-claim→build→completion loop ("a villager
  builds the placed block" end-to-end) — next sprint. This story proves both halves live in one
  assembled scene, not the closed job loop.
- vox-015 mesh view-window streaming (the #12 60-FPS-with-culling measurement scale) — separate story.

---

## QA Test Cases

- **AC-ASSEMBLY**: Given a headless boot, When GameWorld `setup()` runs, Then all four tier modules
  are injected and Ready behind the ADR-0005 gate; no module holds a non-DI cross-reference.
- **AC-PLACE-A-BLOCK**: Given an armed tool and a valid pick, When commit → construction ticks
  elapse, Then the target cell is Built in Voxel World grid data and exactly one `cells_changed_batch`
  fires for the completion frame.
- **AC-VILLAGER-WALKS**: Given a villager and a reachable target, When it decides and travels, Then
  its `current_cell` advances along the AStar3D path and ends at the target (assert on discrete cells,
  not visual position).
- **AC-E2E-GATE**: Given the commit gate, When the suite runs headless, Then the E2E LOOP test is
  present and green, including the typed-Array regression call.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/scene_world/gameworld_e2e_loop_test.gd` — must
exist, pass headless, and be wired into the commit gate.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: building-021 (commit) + building-029 (tick-write) [in-sprint]; villager-ai-009
  (traveling) [in-sprint, itself gated on 005/006/007/008]; vox-007 (mesher, DONE); vox-010
  (residency, DONE); scene-001 (World Root + Valley attach, DONE); spine-001 (GameWorld DI scaffold,
  DONE).
- Unlocks: Milestone 01 criterion #8 (integrated playable build) as the commit-gate regression;
  criterion #13 sustained-stability window; the closed job-loop (S7) that binds place-a-block to a
  villager builder.
