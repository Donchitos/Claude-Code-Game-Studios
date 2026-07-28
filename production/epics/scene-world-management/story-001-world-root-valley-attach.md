# Story 001: World Root + single-Valley attach topology

> **Epic**: Scene/World Management
> **Status: Complete (2026-07-23 — 165/165 suite green, parent-verified; NEEDS-DECISION flag carried, unresolved)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

> ⚠️ **NEEDS DECISION (does NOT block Milestone 01)** — Boot-flow conflict flagged, not resolved here.
> `scene-world-management.md` Core Rule 1 / AC1 (TR-scene-world-management-034) boots **straight into the
> Valley with no menu**. The approved `design/ux/main-menu.md` spec (Approved 2026-07-23, Open Questions
> #1/#2) requires, at **Alpha tier**, a new `MainMenu` state inserted between `Booting` and `InValley`,
> plus an ADR-0012 amendment making `.load()` a Continue-button action rather than boot-automatic.
> **For Milestone 01 this story implements the boot-straight-to-Valley behavior as written** — the Main
> Menu is explicitly Alpha-tier and out of M01 scope (`milestone-01` §Out of Scope, `main-menu.md`
> Milestone-placement note). The conflict is a **forward-looking** one: when the Main Menu ships, this
> story's Core Rule 1 wording, the States table, and ADR-0012 need a companion revision.
> **Owner of the resolution**: technical-director (via a `scene-world-management.md` revision pass +
> ADR-0012 amendment). Do not resolve in this story; carry the flag so it is not lost.

## Context

**GDD**: `design/gdd/scene-world-management.md` (Core Rules 1 & 2, AC1, AC2)
**Requirement**: `TR-scene-world-management-034`, `TR-scene-world-management-035`, `TR-scene-world-management-036`, `TR-scene-world-management-037`, `TR-scene-world-management-038`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: ADR-0001: Inter-System Reference & DI Pattern (primary — Scene/World Management is injected-tier; `GameWorld.tscn`'s root IS the World Root); ADR-0013: Multi-Scene Concurrency Model (secondary — establishes the World Root container topology, though the multi-scene half is VS-tier and out of M01)
**ADR Decision Summary**: The World Root is a thin, persistent container node owned by Scene/World Management, alive for the whole process, that anchors the scene tree; the Valley scene attaches under it at boot and persists for the session. Scene handoff must NEVER use `change_scene_to_file()`/`change_scene_to_packed()`/`reload_current_scene()` nor assign `SceneTree.current_scene` directly. The World Root node itself is never freed.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes** (from ADR-0013 + GDD Core Rule 2): the banned APIs (`change_scene_to_file`/`change_scene_to_packed`/`reload_current_scene`/direct `current_scene` assignment) replace the engine's single `current_scene` wholesale and would destroy the persistent World Root — a code-review-blocking guardrail. MVP is single-scene (LOW-risk on its own); the multi-scene facets of ADR-0013 (`100_000`-unit offset, per-scene toggles) are **VS-tier and not built here**. Cross-reference `docs/engine-reference/godot/` before any scene-topology API is used.

**Control Manifest Rules (Foundation + Presentation Layer)**:
- Required (Foundation): Scene/World Management is injected-tier, wired in `GameWorld.tscn`, logic in `setup()`.
- Forbidden (Presentation, ADR-0013): never `change_scene_to_file`/`reload_current_scene`/direct `current_scene` assignment for scene handoff; never separate SubViewports with own `World3D`s; never a second `WorldEnvironment` node. (The multi-scene positive rules are VS-tier — not implemented in M01.)
- Guardrail: the World Root is never freed; single cell/scene topology change goes through this system as the only legal entry point.

---

## Acceptance Criteria

*From `design/gdd/scene-world-management.md`, scoped to this story (MVP-tagged only):*

- [ ] AC1 [MVP]: On launch, once boot completes, the Valley scene is active and receiving player input with **no menu and no loading screen** shown. (See NEEDS-DECISION flag above — M01 behavior.)
- [ ] AC2 [MVP]: The Valley scene is a child of the persistent World Root; Voxel World, Camera & Input, Time & Tick System, and Villager AI & Behavior are children of the Valley root and remain valid for the entire play session.
- [ ] The World Root node is never freed during a session (instance identity is stable from boot onward).
- [ ] Scene handoff uses child add/remove under the World Root — never `change_scene_to_file`/`change_scene_to_packed`/`reload_current_scene`, and never a direct `SceneTree.current_scene` assignment (grep-verifiable, code-review-blocking).

---

## Implementation Notes

*Derived from GDD Core Rules 1 & 2 and ADR-0013 (MVP subset):*

- The World Root is `GameWorld.tscn`'s root (per ADR-0001's ownership note) — the same node that hosts the Foundation Spine's boot gate. This story owns its **scene-topology behavior** (Valley attach, never-freed guarantee, banned-API guardrail); the Foundation Spine epic owns the boot-gate mechanism on the same node.
- Attach the Valley scene as a child of the World Root; Foundation/Core systems (Voxel World, Camera & Input, Time & Tick, Villager AI, later Building System) attach under the Valley scene as a **hosting relationship**, not a data dependency.
- MVP is single-scene only. Do NOT build Dungeon scene concurrency, the `100_000`-unit offset, or per-scene `Camera3D.current`/`AudioListener3D`/`DirectionalLight3D` toggles — those are VS-tier (ADR-0013).
- The actual Valley-attach *timing* (only after RID Ready) is story 002's gate integration — this story establishes the topology; story 002 gates when the attach fires.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Story 002: gating the Valley attach on RID Ready and the DB-failure HALT (this story owns topology, not the gate).
- Story 003: the transition-signal contract surface (`transition_begun`/`transition_ended`) and transition state machine.
- All VS-tier multi-scene work (Dungeon sibling scenes, offset, per-scene toggles, ADR-0013 positive rules) — Milestone 02+.
- The Main Menu / `MainMenu` state — Alpha-tier, out of M01 (see NEEDS-DECISION flag).

---

## QA Test Cases

*Automated test specs — the developer implements against these:*

- **AC1 (boot → Valley active, no menu)**:
  - Given: the game booted to completion (RID Ready) in a headless integration harness.
  - When: the scene tree and input target are inspected.
  - Then: the Valley scene is the active, input-receiving scene, with no menu/loading-screen node interposed.
  - Edge cases: no `MainMenu` node exists in the M01 tree (forward-conflict guard).

- **AC2 (hosting topology)**:
  - Given: the Valley scene loaded under the World Root.
  - When: the tree is inspected.
  - Then: Valley is a child of the World Root, and Voxel World / Camera & Input / Time & Tick / Villager AI are children of the Valley root and are valid.
  - Edge cases: each hosted system remains a valid instance across several frames (session-lifetime check).

- **AC (World Root never freed + banned APIs absent)**:
  - Given: the running session and the source tree.
  - When: the World Root instance id is sampled at boot and later; and grep for `change_scene_to_file|change_scene_to_packed|reload_current_scene|current_scene *=`.
  - Then: the instance id is unchanged, and the grep returns zero matches in this system's code.
  - Edge cases: property-form `current_scene =` assignment is the quieter footgun — assert it too.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration test at `neues-spiel/tests/integration/scene_world_management/world_root_valley_attach_test.gd` — must exist and pass headless (World Root persistence + one-Valley topology).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Foundation Spine story 001 (GameWorld root + injected-tier scaffold) — the World Root IS GameWorld's root. Foundation Spine story 002 (boot gate) is required for the *gated* attach, which story 002 of this epic covers.
- Unlocks: Story 002 (boot-gate integration), Story 003 (transition contract surface).
