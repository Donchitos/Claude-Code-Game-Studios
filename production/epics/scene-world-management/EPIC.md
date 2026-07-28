# Epic: Scene/World Management

> **Layer**: Foundation
> **GDD**: design/gdd/scene-world-management.md
> **Architecture Module**: Scene/World Management (World Root lifecycle; the 3-signal transition contract; scene attach/detach topology)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 7 stories created — 001–003 (2026-07-23; epic closed 3/3 after S3), plus **story 004 (2026-07-24)** re-opening the epic to close the integration-to-playable / E2E LOOP gap (Milestone 01 criterion #8; scheduled Sprint 6), plus **story 005 (2026-07-26)** re-opening it again to close the world-genesis boot gap — the production Valley boots an EMPTY grid (scheduled Sprint 9), plus **story 006 (2026-07-27)** re-opening it a third time to close the villager-need-seeding boot gap — `NeedsMood.initialize_villager()` is called nowhere, so every shipped villager holds zero need records (scheduled Sprint 10), plus **story 007 (2026-07-27)** re-opening it a fourth time to host the entire build-interaction tier — eight `Node`s in no scene and three `RefCounted`s constructed nowhere, so **the player cannot build anything in the shipped game** (scheduled Sprint 11). Story 001 carries a NEEDS-DECISION flag (main-menu boot-flow conflict; does not block M01).

## Overview

Scene/World Management owns the World Root node and is the single legal entry
point for scene topology change. It exposes the transition state machine
(Booting / Active / Transitioning) and the `transition_begun()` /
`transition_ended(success)` contract that Camera & Input (Suspended), Building
System (undo-clear on COMPLETE), and the UI systems key off. At MVP it manages
the single always-loaded Valley scene; the two-live-scenes Valley+Dungeon model
is Vertical-Slice-tier and enters via ADR-0013. It consumes the Foundation Spine
epic's boot gate (it does not own the gate) and guarantees the World Root is
never freed and `change_scene_to_file`/`current_scene` are never used.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Boot Sequencing & Initialization Gate | Scene/World Management's Booting state is the boot-gate host; Valley attaches only after RID Ready (gate mechanism owned by `foundation-spine`) | MEDIUM |
| ADR-0013: Multi-Scene Concurrency Model | ONE shared `World3D`, Dungeon at `100_000`-unit offset; exactly one `WorldEnvironment`; per-scene toggles for `Camera3D.current`/`AudioListener3D`/`DirectionalLight3D.visible`, centralized in `_activate_scene`/`_deactivate_scene` — **VS-tier** (no Dungeon at MVP) | MEDIUM |
| ADR-0012: Save/Load Serialization Strategy | Savepoints fire exclusively on `transition_ended(success=true)`; Scene/World Management triggers, never owns, save data — **VS-tier** | MEDIUM |
| ADR-0001: Inter-System Reference & DI Pattern | Injected-tier module; wired in `GameWorld.tscn`; logic in `setup()` | MEDIUM |

Engine-risk basis (4.7 policy): MEDIUM. MVP is single-scene and LOW-risk on its
own, but the Accepted multi-scene decision (ADR-0013) touches post-cutoff engine
facts the LLM does not know: `_input`/`_unhandled_input` dispatch is SceneTree-
global (not per-Viewport), `DirectionalLight3D` affects the whole `World3D`, and
float32 ULP scales with magnitude (why the offset is kept at `100_000`). Verify
against `docs/engine-reference/godot/` before any scene-concurrency API is used.
The banned APIs (`change_scene_to_file`/`reload_current_scene`/direct
`current_scene`) are a code-review-blocking guardrail.

## GDD Requirements

34 TRs registered (`TR-scene-world-management-*`). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-scene-world-management-004 | Boot gate: RID Ready before Valley attaches; DB failure → terminal halt | ADR-0005 ✅ (host here) |
| TR-scene-world-management-010 | Exactly one scene has control; neither receives input mid-transition | GDD-specified ✅ |
| TR-scene-world-management-013 / -024 | Savepoint binds to transition-COMPLETE only, never begin/abort | ADR-0012 ✅ (VS-tier) |
| TR-scene-world-management-033 | Two-live-scenes partitioning (shared World3D, offset, per-scene toggles) | ADR-0013 ✅ (VS-tier) |
| TR-scene-world-management-030 | All transition tunables from config | ADR-0002 ✅ |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; remaining TRs
are GDD-specified (traced to the GDD + architecture.md Module Ownership). No
untraced requirements.

**At-risk / deferred**: TR-033 (multi-scene) and TR-013/-024 (savepoint binding)
are Accepted but **VS-tier** — out of Milestone 01 scope. MVP builds only the
single-Valley lifecycle + the transition-signal contract stubs the boot path
needs. Do not build Dungeon scene concurrency in M01.

## Milestone 01 Notes

- No tech-debt or CD-protected item lands here.
- M01 scope = World Root + boot-gate integration + single-Valley attach + the
  transition-signal contract (Foundation systems must "run together in one scene"
  per the milestone success criteria). Multi-scene is M02+/VS.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/scene-world-management.md` are verified
- Logic/Integration stories have passing test files in `tests/`
- A headless test proves World Root persistence and the one-begin→one-complete/abort invariant

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | World Root + single-Valley attach topology ⚠️ NEEDS-DECISION (main-menu conflict, does not block M01) | Integration | Ready | ADR-0001, ADR-0013 |
| 002 | Boot-gate integration — Valley attaches after RID Ready; DB-failure → HALT | Integration | Ready | ADR-0005 |
| 003 | Transition-signal contract surface + transition state machine | Integration | Ready | ADR-0001 |
| 004 | **GameWorld scene assembly + headless E2E LOOP test — THE INTEGRATION CROWN** (criterion #8) | Integration | Ready | ADR-0001, ADR-0005, ADR-0013 |
| 005 | **World genesis in the boot sequence — terrain, roster and nav graph before ACTIVE** (the Valley boots an EMPTY grid today) | Integration | Ready | ADR-0005, ADR-0015, ADR-0014, ADR-0001 |
| 006 | **Villager need seeding in the boot sequence** — a spawned villager carries REAL need records before ACTIVE (`NeedsMood.initialize_villager()` is called nowhere today) | Integration | Ready | ADR-0005, ADR-0001, ADR-0002 |
| 007 | **Build-tool & project-lifecycle hosting in the Valley scene** — the player can actually build (the whole build-interaction tier is in no scene today) | Integration | Ready | ADR-0005, ADR-0001, ADR-0016, ADR-0010 |

Dependency order: 001 → 002 → 003 (closed 3/3 after S3). **Story 004 (added 2026-07-24, Sprint 6)** re-opens the epic to assemble grid+mesher+camera+building+villager into GameWorld's `injected_tier_modules` and land the headless E2E LOOP test — it depends on Building (021+029) and Villager AI (009) reaching the place-a-block and villager-walk seams, plus the DONE mesher (vox-007), residency (vox-010), World Root (001), and GameWorld DI scaffold (spine-001). It closes the integration-to-playable / E2E LOOP gap the Milestone 01 Feature List named but never storyed.

**Story 005 (added 2026-07-26, Sprint 9)** re-opens the epic a second time. Story 004 assembled the modules;
nothing ever generated the world they operate on. `VoxelWorldGrid.generate_terrain()` is implemented and tested
(vox-006) but called nowhere in the boot chain — `valley.gd`'s own class doc says so, and defers **three** things
to "a future world-generation story": terrain, `VillagerNavGraph.build()`, and (since 2026-07-26)
`Valley.spawn_starting_roster()`. Story 005 is that story. It lives here rather than in `voxel-world` because the
deliverable is a **boot-phase ordering change** inside `game_world.gd` / `valley.gd` under ADR-0005 — this epic's
own governing ADR and own files — that drives already-landed voxel-world and villager-ai surfaces; it authors no
generation algorithm. Per ADR-0015 (which already superseded ADR-0014's full-world-at-boot clause) production
genesis is the **residency page-in of the boot window**, not a full-extent `generate_terrain()` call: that method
is measured non-viable at the shipped 2000×2000 config (52.2 s at 900×900, no completion in >200 s at 1000×1000 —
a `Dictionary` rehash cliff recorded in vox-018's evidence). Depends on nothing unlanded.

**Story 006 (added 2026-07-27, Sprint 10)** re-opens the epic a third time, for the **third occurrence of the
same pattern story 005 fixed twice**: a production API that shipped green, complete and tested — and called
from nowhere. `NeedsMood.initialize_villager()` (needs-mood-006) seeds a villager's needs and derives their
starting mood; `valley.gd` assigns `needs_provider` at two sites and seeds at neither, so every villager in
the shipped game holds **zero need records**. Because `NeedsMood`'s read surface deliberately answers benign
defaults for untracked ids, the gap is invisible to every query — it only manifests under time, since
`_pass_f1_decay` iterates existing records only, so an unseeded villager never decays, never goes urgent and
never sleeps. **The payoff loop needs-mood-010 proved end-to-end cannot start in production.** It lives here
rather than in `needs-mood` for the same reason story 005 did: the deliverable is a **boot-phase ordering
change** in `valley.gd` / `game_world.gd` under ADR-0005 — this epic's own governing ADR and own files —
driving an already-landed needs-mood surface. `needs_mood.gd` is expected not to change. The story carries the
epic's running record of this pattern (generate_terrain → spawn_starting_roster → initialize_villager) and the
rule it establishes: **a new production API needs a proven caller in the same sprint, or it is dead code with
green tests.** Depends on nothing unlanded.

**Story 007 (added 2026-07-27, Sprint 11)** re-opens the epic a fourth time, for the **fourth occurrence of the
pattern stories 005 and 006 fixed three times before it** — and the first that is not one API but an entire
subsystem. `Valley.tscn` hosts 12 injected-tier modules; `BuildEditorMode`, `WallTool`, `FloorTool`, `RoofTool`,
`BlockTool`, `FurnitureTool`, `GhostPreview` and `UndoRedoStack` are `Node`s in **no scene**, and
`BuildProjectRegistry`, `ConstructionJobQueue` and `PlanOnlyUndoGate` are `RefCounted` and **constructed nowhere
in `src/`**. Every one is fully implemented and green-tested. **Consequence: in the running game the player
cannot build anything** — `CommitPipeline` runs on its own deliberately-labelled placeholder cell-set resolver,
the blueprint cells it creates belong to no project because nothing listens to `blueprint_cells_created`, and
`VillagerAi.job_queue` is never assigned. building-ui's **Known Conflict 3** recorded this on 2026-07-26 and it
**survived `building-001` (build/editor mode) landing on top of it**. It lives here rather than in
`building-system` for the same reason 005 and 006 did: the deliverable is a **scene-topology and boot-phase
change** in `Valley.tscn` / `valley.gd` / `game_world.gd` under ADR-0005 and ADR-0001 — this epic's own governing
ADRs and own files — driving already-landed Building System surfaces. It authors no tool formula, no grouping
rule and no lifecycle transition. It is also the story that answers, for the tool tier, the **same architectural
question** the technical-director's outstanding HUD-hosting ruling (building-ui KC1/KC3) and sprint-11's open
decision **D9** ask: which scene owns a node that is neither a world object nor a config Resource. Depends on
nothing unlanded; sequenced last on Sprint 11's demolition lane so it hosts `building-031`'s removal tool in the
same pass.

MVP scope only — multi-scene (ADR-0013) and savepoint binding (ADR-0012) are VS-tier, deferred to Milestone 02+.

## Next Step

Run `/story-readiness production/epics/scene-world-management/story-001-world-root-valley-attach.md`, then `/dev-story` to begin implementation in dependency order. Resolve the story-001 NEEDS-DECISION flag with technical-director before the Main Menu ships (Alpha), not before M01.
