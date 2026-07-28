# Epic: Building UI

> **Layer**: Presentation
> **GDD**: design/gdd/building-ui.md (979 lines — the largest single design doc in the project)
> **UX Specs**: design/ux/hud.md (zones Z1–Z6, `/ux-review` APPROVED 2026-07-12) · design/ux/projects-panel.md (zone Z7, `/ux-review` APPROVED 2026-07-23)
> **Architecture Module**: Building UI (pure presentation/routing layer — the build HUD, the click-routing arbitration and resulting Selection, the ghost/marker/hover presentation vocabulary, the Projects Panel; owns no simulation state)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 18 stories created (see Stories table below)

## Overview

Building UI is the hand the player builds with, and — after the 2026-07-23 slice
revision — the whole build-mode interaction layer, not just a toolbar. It owns
the three-zone HUD (bottom toolbar + context panel, top-right time controls,
top-right notification area) plus the Projects Panel zone the UX spec added
(Z7); the **Build Mode** master gate and the four-step **Esc chain**; the
**click-routing arbitration** that turns a non-placement world click into a
Selection (villager XOR project XOR none); the shared **hover-suppression flag**
every world-pick consumer honors; the always-on hover highlight, the build grid,
and the ghost/marker presentation vocabulary (material tint, alpha-as-commitment,
State-Orange invalid override, inflated replace/dig boxes); Build Validation's
toast/anchor surface with its grace, debounce, promotion and reconciliation
lifecycle; the Slice View render cutoff; and the MVP's one global HUD element,
the time controls.

It renders and it routes. Every value it displays lives in the system it mirrors
(Building System, Build Validation, Resource & Item Database, Time & Tick). Its
only owned state is exhaustively scoped by GDD Rule 2: per-tool last-selected
material, toast/anchor presentation state, and the current Selection — none of
it serialized, none of it consumed by another system.

This epic is **Milestone 02 Cluster D**, alongside `villager-info-ui`. Cluster D
is the **second** thing the Cut-Lever Policy trims (after Cluster C's C4→C3→C2
tiers). The lever's step 5 reduces this epic to *"the tool palette + ghost
feedback + project state"* — the twelve stories marked **CORE** below are
exactly that floor; stories 013–018 are the polish tail that step 5 drops.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Cross-System UI/World Input Arbitration | **Primary.** New-click ownership is structural (Godot's `_input()` → `_gui_input()` → `_unhandled_input()` order), not Camera & Input logic; the hover-suppression flag is an explicit redundant safety net checked only when STARTING a new pick/selection, and also gates ghost refresh (hover alone generates no consumable click); an in-progress drag's release is tracked via `_input()` + `set_input_as_handled()`, immune to HUD hover. **§4 (slice propagation)** extends the same gate — never a second dispatch mechanism — to the Build Mode gate and to villager-vs-project Selection routing | HIGH |
| ADR-0011: UI Timer & Expiry Management | A centralized `UITimerManager` (`Dictionary[key, TimerRecord]` + one shared `_process` loop), never N Godot `Timer` nodes. Raw-delta / pause-immune; a single guard flag freezes it on Suspended and resumes with exact remaining time. Resolves TR-building-ui-040 | MEDIUM |
| ADR-0001: Inter-System Reference & DI Pattern | Injected-tier module: typed `@export` refs wired in the hosting scene, all wiring/validation in an explicitly-callable `setup()`; headless-instantiable via `Node.new()` + mocks. Every headless AC in this epic depends on this shape | MEDIUM |
| ADR-0002: Tuning/Config Data Strategy | One `Resource`-derived `BuildingUiConfig`, typed `@export` per Tuning Knob (`toast_max_visible`, `min_reshow_interval`, `warning_grace_delay`, `invalid_cue_fade`, `ghost_alpha_draft`, `ghost_alpha_released`, `build_grid_opacity`, `projects_panel_max_visible_cards`), `.tres` text, `validate()` once at boot. `ghost_alpha_released`'s floor **tracks** `ghost_alpha_draft` — a cross-value invariant, warn-and-clamp tier (not BLOCKING) | MEDIUM |
| ADR-0016: Build-Project Entity Lifecycle | The Projects Panel is a pure renderer/router over `BuildProject` entities — it reads state/progress/`worker_ids` and routes release/pause/resume/cancel intents into Building System's public surface, owning no project state | MEDIUM |
| ADR-0005: Boot Sequencing & Initialization Gate | The palette is built from RID queries, so the HUD may not populate before `GameWorld` reaches `ACTIVE`; the HUD is an injected-tier module in the boot-gated `setup()` order | LOW |

Engine-risk basis (4.7 policy): **HIGH** — UI/Control is a flagged post-cutoff
change domain (M02 risk R13). The load-bearing unverified facts, carried forward
verbatim from the GDD's Open Question 7 and **still open**: 4.6's **dual-focus
system** (mouse/touch focus separate from keyboard/gamepad focus) is
**BLOCKING for story 015** specifically, because Edge Case 13's explicit focus
handoff depends on it; `mouse_filter` consumption semantics (ADR-0010 verified
these unchanged 4.4→4.7 — the ADR is the answer, do not re-litigate);
`InputEventKey.echo` key-repeat semantics (story 005 / AC9); and 4.5's AccessKit
APIs. Cross-reference `docs/engine-reference/godot/` before any Control API use.

## GDD Requirements

58 TRs registered (`TR-building-ui-*`). ADR-worthy coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-building-ui-028 / -029 / -069 | Shared hover-suppression gate for every world-pick consumer; drag-release must survive HUD hover | ADR-0010 ✅ |
| TR-building-ui-075 / -076 / -077 | Build Mode gate, four-step Esc chain, villager-XOR-project Selection routing | ADR-0010 §4 ✅ |
| TR-building-ui-040 / -052 / -053 / -015 | Timer architecture; wall-clock grace/debounce; pause-immune, Suspended-frozen with remaining time | ADR-0011 ✅ (RESOLVED — centralized manager) |
| TR-building-ui-038 | Headless-mockable via DI (the whole "Blocking — headless unit tests" AC block rests on this) | ADR-0001 ✅ |
| TR-building-ui-037 | All tuning values data-driven, never hardcoded | ADR-0002 ✅ |
| TR-building-ui-086 / -088 | Projects Panel renders lifecycle state + progress + workers; undo never lists a demolition step | ADR-0016 ✅ |
| TR-building-ui-008 | Palette built from RID queries at boot | ADR-0005 / ADR-0006 ✅ |

**Coverage summary**: Every ADR-worthy TR traces to an Accepted ADR. The
remaining TRs are GDD/UX-specified layout, mirror and lifecycle requirements
with no architectural ambiguity — except the six items in **Known Conflicts With
Landed Code** below, which are *missing upstream surfaces*, not undecided
architecture.

**At-risk / deferred**:
- **Higher-level tools (Rule 19, story 017)** depend on a cross-GDD propagation
  that has **not happened**: building-ui's own Open Question 9 states the Room /
  Auto-roof / House-stamp **cell-generation algorithms are Building System's
  domain and require that GDD's own revision**. This story is blocked at the
  design level, not the code level.
- **Door-gap affordance (Rule 22, folded into story 018)** commits only to *the
  requirement existing*; the exact treatment is an Art Bible §7.6 handoff and is
  explicitly superseded, not duplicated, the moment door/window ITEMS ship.
- **Shape-budget pairings** for replace-vs-dig markers (story 009) and project
  status icons (story 011) are **proposals**, not final — Art Bible §7.3 owns
  the shared assignment table and the first production icon pass must reconcile
  them so no two unrelated states share a silhouette.
- **Default key bindings** for the Rule 9b / slice-revision actions are
  `[assumption]` per hud.md's own convention. They are **already registered in
  `project.godot`** (verified 2026-07-26) — the ACTIONS are the commitment, the
  keys are revisitable after the first playtest.

## Milestone 02 Notes — Cluster D (trimmed SECOND)

- Delivers the Building-UI half of criterion **#10** ("Building UI and Villager
  Info UI ship as real UX-spec'd systems — the build-editor mode, the
  tool/palette surface, ghost preview feedback while drawing, project state
  readout").
- **Cut-Lever Policy, step 5**: *"Cluster D — Building UI reduced to the tool
  palette + ghost feedback + project state."* Stories **001–012 are that
  minimum-viable core**; stories **013–018 are the polish tail** the lever drops.
  The trim signal is *"Cluster D has not started by S12"*, checked at the start
  of S12.
- **This epic is only partly A-gated.** M02 risk R10 records the sequencing
  correctly: Villager Info UI is truly Cluster-A-gated, but Building UI needs
  only Cluster 0's `building-001` (build editor mode) and `building-023` (ghost
  preview). Sequence those two in S09 and this epic can run in parallel with
  Cluster A. Stories 013–015 (the toast/anchor surface) are the exception —
  they consume Build Validation's four-item seam contract and are A-gated.
- **⚑ Cross-cluster hazard the Cut-Lever Policy does not currently price** (see
  Known Conflict 4): the Projects Panel's per-state action buttons call
  Building System lifecycle APIs that live in **Cluster C**, on the lever, at
  tiers **C3** (`building-006` pause/resume) and **C4** (`building-010` Abriss).
  Trim steps 1–2 fire *before* step 5. Pulling the lever as written would ship a
  Projects Panel whose *Pause* / *Fortsetzen* / *Abriss* buttons have no backing
  call — a panel that displays a lifecycle the player cannot drive. **Escalated
  to producer/user; do not resolve inside a story.**
- No CD-protected item lands here.

## Known Conflicts With Landed Code (report-only — resolve before the affected story)

Recorded here so no story silently invents a resolution. Each names an owner.
Verified against `neues-spiel/src/` on 2026-07-26.

1. **No UI system exists in `src/` at all.** There is no `src/ui/` directory,
   no Control node anywhere, and `Valley.tscn` hosts no HUD. This epic starts
   from zero — hence story 001's scaffold/host scope. *(Not a defect; recorded
   so estimates are read correctly.)* Owner: producer (recorded).

2. **The wall-height stepper has no runtime home.** GDD Rule 6 / AC7 / AC39 make
   `wall_height` a *player-facing runtime* 1–8 stepper. Landed `wall_height` is
   an `@export` on `WallToolConfig extends ConfigResource`, and
   `neues-spiel/CONTRACTS.md` §2 **Forbidden** states plainly: *"Never write to
   a config Resource field at runtime outside its own `validate()`"* (grep-verified
   zero matches today), with the engine fact that `load()` caching makes any such
   write visible project-wide. `WallTool` exposes no runtime setter — only the
   static `wall_cell_set(..., wall_height)`. A runtime `wall_height` holder on
   `WallTool` (seeded from the config default, clamped to its range) is required.
   Owner: technical-director + building-system. **Blocks story 004.**

3. **The tools, the undo stack, the project registry and the job queue are not
   hosted.** `Valley.get_injected_tier_modules()` returns exactly: voxel grid,
   mesher, mesh streamer, camera input, `ToolStateMachine`, `PlacementPick`,
   `CommitPipeline`, `ConstructionTickLoop`, `VillagerAi`, `TorchFlicker`.
   `WallTool` / `FloorTool` / `RoofTool` / `BlockTool` and `UndoRedoStack` are
   `Node`s that exist but are in no scene and have no `Valley` getter;
   `BuildProjectRegistry` and `ConstructionJobQueue` are `RefCounted` and are
   constructed nowhere in `src/`. The HUD has nothing to mirror for palette
   selection, roof formation, undo availability, or the project list until
   `building-001` (build editor mode) or a dedicated hosting story wires them.
   Owner: technical-director + building-system. **Blocks stories 003, 004, 005,
   011.**

4. **`BuildProject` cannot express the Projects Panel's lifecycle.** Landed
   `BuildProject.ProjectState` is exactly `{DRAFT, BUILDING, PAUSED, DONE}` —
   there is **no Demolishing state and no demolishing flag**, and no
   pending-change-order concept. `BuildProjectRegistry` exposes only
   `release_project()`; the UX spec's Data Requirements name
   `release_project` / **`pause_project`** / **`queue_demolition`** as ADR-0016
   Key Interfaces, and the latter two do not exist. There are also no
   `built_cells` / `total_cells` accessors (progress `X/Y` must be derived from
   `get_cells()` micro-states) and **no project `name` field** (the spec's
   "Haus 3" / "Abbau 2" strings must be generated from `kind` + `id`).
   The missing calls live in `building-006` (pause/resume, **Cluster C tier C3**)
   and `building-010` (Abriss, **Cluster C tier C4**) — both on the cut lever,
   both trimmed *before* Cluster D. Owner: **producer escalation** (see the
   cross-cluster hazard above) + building-system. **Blocks story 011's button
   ACs.**

5. **The pick-solid contract has no landed substrate.** Rule 16 / AC50–52
   require ghost cells to pick as solid with **dig-order** and **water** exempt.
   `PlacementPick` forwards one `set_extra_solid(Callable)` predicate into
   `VoxelWorldGrid.raycast_cells` and its own doc comment states wiring a real
   predicate "is a future story's job once that data model exists (none does
   yet)". There is **no dig-order cell class** — `build_project.gd` records that
   `BlueprintCell.MicroState` "does not yet model" the dig-order Removed state —
   and **no water cell type** is present in the grid. AC51 and AC52 are
   untestable against landed code. Owner: technical-director + building-system
   (this is building-ui Open Question 9's propagation). **Blocks story 008's
   exemption ACs and story 017.**

6. **Slice View has no renderer hook.** Rule 20 / AC64–65 need a horizontal
   render cutoff over world geometry, ghosts, **and characters**. Neither
   `VoxelWorldMesher` nor `VoxelWorldMeshStreamer` exposes a cutoff/clip
   parameter; chunks are whole-column `MeshInstance3D`s keyed by `Vector2i`, so
   the cutoff must be either a clip-plane uniform on
   `VoxelWorldMesher.get_shared_material()`'s `ShaderMaterial` or a per-chunk
   re-mesh — an architecture choice this epic must not make alone. The
   "characters" clause is currently vacuous: villagers have no visual body at
   all (see the villager-info-ui epic's Known Conflict 1). Owner:
   technical-director + godot-shader-specialist. **Blocks story 016.**

7. **Time controls have no returned-state API** *(minor — wording, not code)*.
   Rule 2 / Rule 10 / AC13 require the display be written **exclusively from the
   API's returned state**, never a UI-local latch. `TimeTickSystem.pause()` and
   `.resume()` return `void`; only `set_warp()` returns `bool`. The authoritative
   values are the public `paused` / `time_warp` fields, and emission is
   synchronous — so the contract's *intent* is satisfied by re-reading those two
   fields immediately after the synchronous call, and the AC must be restated in
   those terms rather than asserting on a return value. Owner: producer
   (recorded); **no code change implied**.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Every "Blocking — headless unit tests" AC in `design/gdd/building-ui.md`
  (AC1–22, 27–41, 42–69) that is not gated by a Known Conflict above has a
  passing test under `neues-spiel/tests/unit/ui/`
- Every "Advisory" AC (AC23–29) has a walkthrough/screenshot artifact under
  `production/qa/evidence/`
- Grep proves the HUD writes no simulation state: zero
  `VoxelWorldGrid.set_cell`/`bulk_write`/`clear_cell` calls and zero config-field
  writes anywhere in the UI module
- The 1280×720 minimum-layout check passes with all three zones plus Z4/Z7
  non-intersecting, and the grayscale (A1) pass distinguishes every stateful
  element by shape + label
- The seven Known Conflicts above are each closed by their named owner, or their
  dependent ACs are explicitly deferred with a recorded rationale

## Stories

| # | Story | Type | Tier | Status | ADR |
|---|-------|------|------|--------|-----|
| 001 | HUD host scaffold, zone layout, Suspended & the UI timer manager | Integration | **CORE** | Ready | ADR-0001/0002/0011 |
| 002 | Build Mode gate, tool arming/highlight & the four-step Esc chain | Logic | **CORE** | Ready | ADR-0010 |
| 003 | Context panel & the RID-driven material/furniture palette | Integration | **CORE** | Ready | ADR-0005/0006 |
| 004 | Wall-height stepper, roof-formation picker & keyboard parity | Logic | **CORE** | Ready | ADR-0002 |
| 005 | Undo/redo controls & the plan-only undo scope | Logic | **CORE** | Ready | ADR-0016 |
| 006 | Time controls (pause + 1x/2x/3x) | Logic | **CORE** | Ready | ADR-0001 |
| 007 | Hover-suppression shared gate & drag-release immunity | Integration | **CORE** | Ready | ADR-0010 |
| 008 | Pick-solid contract, always-on hover highlight & build grid | Integration | **CORE** | Ready | ADR-0010 |
| 009 | Ghost, marker & invalid-commit presentation | Integration | **CORE** | Ready | ADR-0002 |
| 010 | Selection routing — villager XOR project XOR none | Logic | **CORE** | Ready | ADR-0010 |
| 011 | Projects Panel — cards, per-state actions, progress & workers | Integration | **CORE** | Ready | ADR-0016 |
| 012 | Projects Panel scalability — priority sort, overflow row, selection pin | Logic | Polish | Ready | ADR-0016 |
| 013 | Toast lifecycle A — identity, grace, severity, cap & overflow | Logic | Polish | Ready | ADR-0011 |
| 014 | Toast lifecycle B — debounce, promotion, reconciliation & tier-swap | Logic | Polish | Ready | ADR-0011 |
| 015 | Issues anchor & HUD keyboard focus cycling | Logic | Polish | Ready | ADR-0011 |
| 016 | Slice View — horizontal render cutoff & the "Ebene" indicator | Integration | Polish | Ready | ADR-0014 |
| 017 | Higher-level tools — Room, Auto-roof & House stamp | Integration | Polish | Ready | ADR-0016 |
| 018 | Advisory presentation evidence pass & door-gap affordance | Integration | Polish | Ready | — |

**Type totals**: 8 Logic, 10 Integration. **Tier totals**: 12 CORE, 6 Polish.

**Dependency order**: 001 → 002 → {003 → 004, 005, 006, 007} → 008 → 009 → 010 →
011 → 012, with 013 → 014 → 015 as their own chain (A-gated) unblocked after 001,
016 unblocked after 008, 017 after 009+011, and 018 last (it consumes every
other story's rendered result).

**Needs-decision / flags**:
- **003 / 004 / 005 / 011**: blocked on the module-hosting question (Known
  Conflict 3) — technical-director. **004** additionally needs the runtime
  `wall_height` holder (Known Conflict 2).
- **008 / 017**: blocked on the pick-solid substrate (Known Conflict 5).
- **011**: blocked on the project lifecycle gap (Known Conflict 4) — **and this
  is the cross-cluster cut-lever hazard; escalate before scheduling.**
- **013 / 014 / 015**: Cluster-A-gated — they consume Build Validation's
  four-item UI seam contract (`build-validation-navigability` story 008).
  **015 is additionally BLOCKED on the Godot 4.6 dual-focus verification** (GDD
  Open Question 7) — godot-specialist, before the story starts.
- **016**: blocked on the render-cutoff mechanism decision (Known Conflict 6).
- **017**: blocked at the **design** level — Building System's GDD has not been
  revised to own the Room/Auto-roof/House-stamp cell generation (GDD Open
  Question 9). Do not write the algorithms here.

## Next Step

Run `/story-readiness production/epics/building-ui/story-001-hud-host-scaffold.md`,
then `/dev-story` to begin. Work stories in dependency order — each story's
`Depends on:` field lists what must be DONE first. Resolve the seven Known
Conflicts above before the stories they block, and escalate the Cluster-C/
Cluster-D cut-lever hazard to the user before story 011 is scheduled.
