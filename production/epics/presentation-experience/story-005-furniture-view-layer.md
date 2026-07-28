# Story 005: A built bed becomes visible — the furniture view layer (F7)

> **Epic**: Presentation & Experience
> **Status**: Complete with one open AC (2026-07-27 — 1603/1603 suite green, 0 orphans, parent-verified). AC-VISIBLE-IN-THE-GAME has no fresh screenshot: two demo runs stalled at villager-ai-024's 27/30 plateau and never reached the furniture stage.
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/resource-item-database.md` (`visual_asset`, a typed `Mesh` on every entry — ADR-0006), `design/gdd/building-system.md` (furniture placement / multi-cell footprint, Story building-016), `design/art/art-bible.md` (furniture reads as a placed object, not a ghost).
**Requirement**: Art-Bible/GDD-traced — this story has **no TR-ID of its own**, mirroring `presentation-003`'s own identical note. The downstream requirement it closes is milestone criterion #6's human-observable half ("Furniture placeable / buildable / claimable" — the code-complete half landed in Sprint 11; this story is the first time a built item is visible at all) and R8 (external playtest), which was blocked in part on this gap.
**ADR Governing Implementation**: **ADR-0001** (DI/hosting precedent — the `Valley`-hosted, `get_injected_tier_modules()`-reported shape every module in this file follows) — primary; **ADR-0006** (`visual_asset` is a typed `Mesh`, never a path string — consumed directly) — primary; **ADR-0016** (BV-1's furniture-never-reaches-`VoxelWorldGrid` prohibition, and why this story must never be the exception) — primary.

**Engine**: Godot 4.7-stable | **Risk**: LOW — a per-entity `MeshInstance3D`/`Node3D` view, no new engine surface; `Mesh.get_aabb()`/`AABB.get_center()` cross-referenced against `docs/engine-reference/godot/` (not flagged in `deprecated-apis.md`, `breaking-changes.md`, or `modules/rendering.md`'s 4.4–4.7 changelist).

### How this was found (and re-verified before writing this file)

Sprint 12's own crown-2 framing: *"the mesher knows exactly one terrain colour, **a built bed is invisible**, and the moment the whole milestone exists for — a villager claiming a bed in a room it helped build and sleeping there — has never been observed in the running game."* Verified directly, 2026-07-27:

```
Files under src/presentation/ matching "furniture" (case-insensitive): 0
src/presentation/ directory listing: ambient_life_config.gd, chimney_smoke_emitter.gd,
  interior_clutter_placer.gd, loop_payoff_adapter.gd, loop_payoff_signal_surface.gd,
  payoff_detail.gd, torch_flicker.gd, villager_body_presenter.gd, villager_body_view.gd,
  villager_hit_proxy.gd, world_lighting.gd, world_lighting_config.gd — no furniture file.
```

**The live-tree count (the lever, run against the unchanged build before any code in this story was written)**: booted the real `GameWorld`/`Valley` headless, called the hosted `FurnitureRegistry.place(&"bed", [cells])` directly — the exact call shape `ConstructionTickLoop._complete_jobs` already uses in production — and counted nodes in the live tree matching the view-naming convention this story defines:

```
SCRATCH BASELINE: placed bed item_id=1, registry now holds 1 item(s):
  [{ "item_id": "1", "definition_id": &"bed", "cells": [(2, 0, 2), (2, 0, 3)] }]
SCRATCH BASELINE: furniture view nodes in live tree AFTER a real placed bed = 0
SCRATCH BASELINE: Valley.get_child_count() = 29
```

**Today, a real placed bed produces zero view nodes.** `05-furnished.png` (`production/qa/evidence/`) is **not** used as corroborating evidence here — it is stale (timestamped before `vox-022`/`vox-023`, single-colour terrain) and does not reflect the current build; the live-tree count above is the sole recorded pre-story observation, per the sprint's own "count nodes in the live tree" technique (the one that found the missing camera, `cam-013`).

### Why this is more than a missing node

BV-1 (`ADR-0016`, the `architecture-decisions-m02-preflight-2026-07-26.md` ruling) is load-bearing: *"Furniture is not voxel data. It never enters `VoxelWorldGrid`."* `BuildValidation`'s transparency guarantee (`build-validation-002`) is true **by construction** only because nothing downstream of `FurnitureRegistry` writes back into simulation state. A furniture view layer is the first consumer of `FurnitureRegistry` whose entire job is to *react visibly* to placement — exactly the shape most tempting to accidentally wire bidirectionally (e.g. "let the view also mark the cell as decorated"). This story's hard constraint, restated as its own AC and grep-guarded: **the view reads `FurnitureRegistry`'s signals and never writes to it.**

### Render mechanism decision (D11) — followed, not re-litigated

Sprint 12 named the TD call (MultiMesh vs per-item `MeshInstance3D`, D11) explicitly **as a non-blocker**: *"the landed precedent is a per-entity presenter, and following it needs no new ruling. Take the ruling if it arrives; otherwise follow precedent and record the choice."* No ruling arrived. **This story follows `presentation-003`'s landed precedent exactly**: `VillagerBodyPresenter` (a `Node3D` presenter, `Valley`-hosted, `setup()`/`is_set_up()`-wired) owns the create/free lifecycle of one `VillagerBodyView` per roster entry. `FurniturePresenter`/`FurnitureView` mirror that shape one-for-one, keyed by `FurnitureRegistry`'s own `item_id` string instead of an `int` villager id.

**Recorded rationale for why per-entity, not MultiMesh, at MVP scope**: MVP has exactly one multi-cell furniture item (the bed); the MultiMesh scale argument (cheap at hundreds/thousands of instances, awkward for heterogeneous per-item meshes) does not bite at this content volume. Revisit if furniture item variety/count grows — the same escape-hatch discipline this project already applies to greedy meshing and AI threading (control-manifest.md, Cross-Cutting Constraints: *"escape hatches are named, not preemptively built"*).

---

## Acceptance Criteria

- [ ] **AC-VIEW**: `FurnitureView` (`class_name FurnitureView`, `extends Node3D`) hosts a child `MeshInstance3D`. `func set_visual(mesh: Mesh) -> void` assigns the mesh and repositions the child so the mesh's own AABB rests bottom-aligned and horizontally centered at this view's local origin — computed from `Mesh.get_aabb()`, never a hardcoded per-item constant. A `null` mesh is inert (no crash).
- [ ] **AC-FOOTPRINT-POSITION**: `func position_over_footprint(cells: Array[Vector3i]) -> void` sets this view's own `global_position` to the horizontal center (average of every occupied cell's `VoxelWorldGrid.cell_to_world()` on X/Z) and the occupied cells' own floor level on Y — so a multi-cell footprint (the bed's `Vector2i(1, 2)`) renders centered across both cells, never offset toward one. Called exactly once, at creation — a placed item is static; this class carries **no** `_process()`.
- [ ] **AC-PRESENTER**: `FurniturePresenter` (`class_name FurniturePresenter`, `extends Node3D`) owns the create/free lifecycle of one `FurnitureView` per `FurnitureRegistry.get_placed_furniture()` record, keyed by `item_id` — mirrors `VillagerBodyPresenter.refresh()`'s own two-pass diff (create for new ids, free for ids no longer present) exactly. `setup()`/`is_set_up()` follow the same explicit-entry-point contract every injected-tier module in this codebase uses (ADR-0001).
- [ ] **AC-SELF-RESYNCING**: `FurniturePresenter.setup()` connects `FurnitureRegistry.furniture_changed` to `refresh()` — unlike `VillagerBodyPresenter` (which needs an external caller to re-sync after each roster spawn, since no "villager added" signal exists), `FurnitureRegistry` already emits on every placement **and** removal (Story building-017), so no external re-sync caller is needed anywhere else in the boot chain.
- [ ] **AC-READ-ONLY-BY-CONSTRUCTION** ⚑ *the hard constraint, grep-guarded*: `FurniturePresenter`/`FurnitureView` call **exactly two** members on `FurnitureRegistry` — `get_placed_furniture()` (a read) and the `furniture_changed` signal (a subscription). **Zero** calls to `place()`/`remove()` or any other mutating member, anywhere in `src/presentation/`. This is BV-1's transparency guarantee holding by construction, mirroring `presentation-001` Sub-B's own "zero mutating calls" guard on `VillagerAi` — grep-guarded the same way.
- [ ] **AC-NO-SELECTION**: zero `Selection`-related references anywhere in the new files — mirrors `presentation-003`'s own TRAP 2, extended by the existing `src/presentation/`-wide grep guard (`villager_body_view_test.gd`'s `test_presentation_module_source_contains_zero_selection_references`, which already scans the whole directory non-recursively and therefore automatically covers the two new files with zero test changes).
- [ ] **AC-HOSTED**: `FurniturePresenter` is a structural child of `Valley` (`Valley.tscn`), wired via `_wire_build_project_lifecycle()` (the same method that constructs `FurnitureRegistry` — `furniture_registry` is assigned there, not in `_wire_hosted_modules()`, because the registry does not exist yet when that earlier method runs), and appended to `get_injected_tier_modules()` — the sole sanctioned `setup()` call site (`GameWorld._setup_injected_tier()`), never a second one.
- [ ] **AC-BOOT-INVARIANT** ⚑ *Sprint 12's own deepest rule: "any injected collaborator whose absence changes behaviour must assert at boot or appear in the boot-invariant block — never both optional and consequential"*: `Valley`'s existing boot-invariant block (`_assert_lighting_boot_invariant`, `_assert_build_validation_gates_boot_invariant`, etc.) gains `_assert_furniture_presenter_boot_invariant()`, asserting `FurniturePresenter` is hosted (non-null) **and** its `furniture_registry` is wired (non-null) — loudly, at boot, never a silent zero-views-forever the way an unwired `roster_provider` would be if it were consequential (it is not, today, because `_wire_build_project_lifecycle()` constructs `FurnitureRegistry` unconditionally — but the assert exists so a future refactor cannot silently reintroduce the null-and-consequential shape).
- [ ] **AC-VISIBLE-IN-THE-GAME**: after this story, `tools/payoff_loop_demo.gd`'s furniture stage — already driving the real chain to a completed bed — produces a `05-furnished` capture (through the shipped camera, no tool-supplied lighting/props) that shows an actual bed-shaped mesh standing inside the built room, not an empty interior. Re-captured fresh (the existing `05-furnished.png` predates `vox-022`/`vox-023` and is not evidence for this story).
- [ ] **AC-LEVER** ⚑ *the anti-vacuity lever, carried verbatim in substance from `sprint-12.md`'s Must table*: boot the real `GameWorld`, complete a bed through the real chain, then **count the furniture view nodes in the live scene tree** and assert **exactly the footprint's worth** — one `FurnitureView` per placed item (never one per occupied cell; BV-1's "one footprint, one entity" rule, `furniture_footprint_group.gd`'s own class doc comment: *"never create N separate entities for one footprint"*, applies identically on the view side). **Today that count is zero** (see the recorded pre-story observation above).

## Out of Scope

- **A hit/pick proxy for furniture.** No `Area3D`, no `collision_layer`, no Selection integration of any kind — this story ships visibility only. `presentation-003`'s `VillagerHitProxy` precedent exists for villagers because clicking a villager is an already-shipped interaction; nothing in this milestone's scope asks a player to click a placed bed yet.
- **MultiMesh batching.** Named and deferred per D11 above — revisit only on measured need (furniture item count/variety growth), never preemptively.
- **Any change to `FurnitureRegistry`, `FurnitureFootprintGroup`, `ConstructionTickLoop`, or `BuildValidation`.** All built, tested, and hosted — this story only adds a reader.
- **Slice View integration.** `VillagerBodyView.set_slice_level`'s TRAP 1 (zeroing `collision_layer` in lockstep with `visible`) does not apply here — there is no collision layer to zero (Out of Scope above). A future story may wire `FurnitureView` into the Slice View cutoff; this one does not, and a furniture item stays visible at every slice level today (documented, not silently decided).
- **Animation, material variation by wear/decay, or any per-frame update on the view.** The view is built once from `visual_asset` and never touched again.

---

## QA Test Cases

**AC-VIEW / AC-FOOTPRINT-POSITION — the mesh sits correctly, headless**
- Given: a `FurnitureView` with a mock `BoxMesh` assigned via `set_visual()`.
- Then: the child `MeshInstance3D`'s local position lifts the mesh's own AABB minimum Y to the view's local y = 0, and centers the AABB on local X/Z — verified against the mesh's real `get_aabb()`, not a hardcoded constant.
- Given: `position_over_footprint([Vector3i(2,0,2), Vector3i(2,0,3)])` (the bed's real 1×2 footprint shape).
- Then: `global_position` equals the average of both cells' `VoxelWorldGrid.cell_to_world()` on X/Z, and the lower of the two cells' floor level on Y.

**AC-PRESENTER / AC-SELF-RESYNCING — create/free lifecycle against a real `FurnitureRegistry`**
- Given: a `FurniturePresenter` wired to a real `FurnitureRegistry` (not a mock — this collaborator is a concrete, already-`class_name`d `RefCounted`, mirrors `FurnitureBedProvider`'s own typed-not-duck-typed precedent), `setup()` called.
- When: `registry.place(&"bed", [cells])` fires.
- Then: exactly one new `FurnitureView` appears, keyed by the returned `item_id`, with no explicit `refresh()` call needed (the signal drove it).
- When: `registry.remove(item_id)` fires.
- Then: that view is freed (`is_instance_valid()` false), and no other view is touched.

**AC-READ-ONLY-BY-CONSTRUCTION — the hard constraint, grep-guarded**
- Given: every `.gd` file under `src/presentation/`.
- Then: a regex scan for `furniture_registry\.(\w+)\s*\(` finds only `get_placed_furniture` as the captured method name — `place`/`remove` never appear as a call, mirroring `villager_body_view_test.gd`'s own `test_presentation_module_makes_zero_mutating_calls_into_villager_ai` allowlist-regex pattern exactly.

**AC-HOSTED / AC-BOOT-INVARIANT — the real booted game**
- Given: the real `GameWorld.tscn` booted to `ACTIVE`.
- Then: `Valley.get_furniture_presenter()` is non-null, appears in `Valley.get_injected_tier_modules()`, and `is_set_up()` is true; `FurniturePresenter.furniture_registry` is the SAME instance `Valley.get_furniture_registry()` returns.
- **Negative control (deletion probe, run once by hand, recorded in the commit body)**: with the `_furniture_presenter.furniture_registry = _furniture_registry` wiring line removed, `_assert_furniture_presenter_boot_invariant()` fails loudly at boot — never a silent zero.

**AC-LEVER — the live-tree count**
- Given: the real `GameWorld` booted, a bed completed through the real build chain (`WallTool`/`RoofTool` → `CommitPipeline` → `ConstructionTickLoop` → `FurnitureRegistry.place()`, the same chain `gameworld_e2e_loop_test.gd`/`multi_cell_furniture_placement_test.gd` already exercise).
- Then: exactly **one** `FurnitureView` exists under `Valley` (one footprint, one entity — never two, one per cell). Today (pre-story, recorded above): zero.

---

## ⚑ Anti-Vacuity Lever

**Carried verbatim in substance from `sprint-12.md`'s Must table, and it FAILS on today's build — observed and recorded above, not asserted from the ADR alone:**

> Boot the real `GameWorld`, complete a bed through the real chain, then **count the furniture view nodes in the live scene tree** and assert exactly the footprint's worth. **Today that count is zero** — `src/presentation/` contains no furniture presenter and zero references to furniture.

**Pre-story observation (recorded 2026-07-27, before any file in this story was written)**:

```
SCRATCH BASELINE: placed bed item_id=1, registry now holds 1 item(s):
  [{ "item_id": "1", "definition_id": &"bed", "cells": [(2, 0, 2), (2, 0, 3)] }]
SCRATCH BASELINE: furniture view nodes in live tree AFTER a real placed bed = 0
SCRATCH BASELINE: Valley.get_child_count() = 29
```

Produced by booting the real `GameWorld`/`Valley` headless and calling the hosted `FurnitureRegistry.place(&"bed", [cells])` directly — the exact call shape `ConstructionTickLoop._complete_jobs` already uses in production, not an invented shortcut. The throwaway probe script itself was not committed (mirrors the project's existing "pre-story observation, quoted, not a permanent artifact" convention, e.g. `scene-009`'s own pre-story `payoff_loop_demo` quote).

⚑ **Explicitly banned vacuous shapes here** (mirrors `scene-009`'s own list): asserting `Valley.get_furniture_registry() != null` (already guaranteed since `scene-007`, proves nothing about the view); asserting `FurniturePresenter != null` alone without also placing a real item and counting views; counting `MeshInstance3D` nodes generically (would also match `AmbientTorchIndicator`, `BodyMesh`/`HeadMesh` on every villager, etc. — the count must be specific to `FurnitureView` instances).

---

## Test Evidence

**Story Type**: Integration (**BLOCKING** — integration test required, `coding-standards.md` Test Evidence table)

**Required evidence**:

- `neues-spiel/tests/unit/presentation/furniture_view_test.gd` — headless unit coverage of `FurnitureView.set_visual`/`position_over_footprint` against mock meshes/cells, no scene tree dependency beyond `add_child`/`auto_free` (mirrors `villager_body_view_test.gd`'s own structure).
- `neues-spiel/tests/unit/presentation/furniture_presenter_test.gd` — headless unit coverage of `FurniturePresenter` create/free lifecycle against a real `FurnitureRegistry` instance (concrete `RefCounted`, not a mock — mirrors `FurnitureBedProvider`'s own established "typed, not duck-typed" precedent for this exact collaborator), including the signal-driven self-resync (AC-SELF-RESYNCING) and the read-only grep guard (AC-READ-ONLY-BY-CONSTRUCTION).
- `neues-spiel/tests/integration/scene_world/furniture_view_layer_boot_test.gd` — **the anti-vacuity lever itself**: boots the real `GameWorld`, then calls the hosted, real `Valley.get_furniture_registry().place(&"bed", [cells])` directly — the exact call shape `ConstructionTickLoop._complete_jobs` already uses in production — and asserts the live furniture-view-node count is exactly 1, both via `FurniturePresenter.get_view_count()` and via a real `Node.find_children()` tree walk (the lever's own literal wording: "count the furniture view nodes in the live scene tree"). **Deviation from this story's own original plan, recorded honestly**: rather than driving the full `WallTool`/`RoofTool` → `CommitPipeline` → `ConstructionTickLoop` chain (which requires a `MockTimeTickSystem` and duplicates coverage `multi_cell_furniture_placement_test.gd` already owns), this test calls the registry directly — the object genuinely new here is `FurniturePresenter`/`FurnitureView`'s REACTION to a placement, not the construction chain that produces one. Also carries AC-HOSTED/AC-BOOT-INVARIANT's positive assertions and a removal-frees-the-view regression check.
- **The deletion probe, recorded in the commit body** (`world_root_valley_attach_test.gd`/`scene-007`'s own Deletion-Probe Record format): remove the `_furniture_presenter.furniture_registry = _furniture_registry` wiring line in `Valley._wire_build_project_lifecycle()`, re-run `furniture_view_layer_boot_test.gd` in isolation, quote the observed assertion failure, restore byte-for-byte, confirm `git diff` clean, re-run green.
- **Existing tests updated consciously, not incidentally** (both counts move by exactly one hosted child): `tests/integration/scene_world_management/world_root_valley_attach_test.gd` (`valley.get_child_count()` 29 → 30, plus a `valley.get_furniture_presenter()` presence assertion) and `tests/integration/scene_world/gameworld_e2e_loop_test.gd` (`world.injected_tier_modules.size()` 25 → 26). Each edit is one line plus its own comment naming this story, mirroring every prior hosting story's own "count moved, updated consciously" paragraph.
- **A fresh `05-furnished.png` capture** via `tools/payoff_loop_demo.gd`, replacing the stale pre-`vox-022`/`vox-023` one, showing an actual bed mesh inside the built room.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete, verified 2026-07-27): `building-016` (multi-cell footprint), `building-028` (`FurnitureRegistry`, single-cell base), `rid-009` (real authored `data/items/bed.tres` with a typed `Mesh` `visual_asset`, footprint `Vector2i(1, 2)`), `scene-007` (`FurnitureRegistry` hosted, `valley.gd`), `presentation-003` (the per-entity presenter precedent this story follows one-for-one).
- **Blocked on**: **nothing.** Day one on lane V.
- **Unlocks**:
  - Milestone criterion #6's human-observable half.
  - `scene-009`'s `06-claimed`/`07-sleeping` captures (mechanically independent, evidence-only coupling — `scene-009`'s own story file already names this).
  - R8 (external playtest), jointly with `scene-009`.

---

## Notes

- Cross-reference `docs/engine-reference/godot/` before touching any engine API (**BLOCKING**, as in M01 and S09–S12). `Mesh.get_aabb()`/`AABB.get_center()`/`MeshInstance3D` checked against `deprecated-apis.md`/`breaking-changes.md`/`modules/rendering.md`'s 4.4–4.7 changelist — none flagged; `VillagerBodyView`'s own caution (avoiding `Transform3D * AABB` operator overload uncertainty) does not apply here since no such multiplication is used.
- `05-furnished.png`'s existing copy predates this sprint's terrain work and must not be read as evidence for this story or for `vox-022`/`vox-023` — noted explicitly so a reviewer does not mistake a stale screenshot for a fresh one.
- `FurnitureRegistry.get_placed_furniture()`'s record shape (`{"item_id": String, "definition_id": StringName, "cells": Array[Vector3i]}`) is unchanged by this story — this is a new reader, not a new writer or a shape change.

---

## Closure Note (2026-07-27)

A placed bed now has a view. The lever was the live-tree count — the same
technique that found the missing camera — and it moved from zero to exactly one
view per footprint:

    SCRATCH BASELINE: placed bed item_id=1, registry now holds 1 item(s)
    SCRATCH BASELINE: furniture view nodes in live tree AFTER a real placed bed = 0
    SCRATCH BASELINE: Valley.get_child_count() = 29

Deletion probe, run and recorded rather than asserted:

    Assertion failed: Valley: FurniturePresenter.furniture_registry must be
    wired to the SAME hosted FurnitureRegistry instance -- never left null,
    never a second one
      at: res://src/scene_world_management/valley.gd:1042

Restored byte-for-byte; the diff carries only the intended addition.

RENDER MECHANISM: per-entity view/presenter, mirroring presentation-003's landed
pair one for one. The MultiMesh-versus-per-item question was named as
non-blocking and no ruling arrived, so the only landed precedent was followed.
The MVP has exactly one multi-cell furniture type, so MultiMesh's scaling
argument does not bite yet. Recorded so a future ruling can overturn it knowingly.

READ-ONLY BY CONSTRUCTION, grep-guarded: the view reads the registry's signals
and never writes. BV-1 forbids furniture from reaching the voxel grid, and that
prohibition is what makes build-validation-002's transparency guarantee true by
construction — so the guard protects a guarantee, not just a convention.

### The one open AC

AC-VISIBLE-IN-THE-GAME has no fresh screenshot. Two demo runs stalled at 27/30
walls and never reached the furniture stage — that is villager-ai-024's known
plateau compounded by D10's pacing, not this story's code. Bed rendering IS
proven headlessly: `furniture_view_layer_boot_test.gd` confirms the real
`data/items/bed.tres` mesh attaches and positions across the footprint. What is
missing is a picture, and it stays missing rather than being borrowed from an
older run — `05-furnished.png` on disk is stale (14:13, before the terrain
recolour) and must NOT be presented as evidence for this story.
