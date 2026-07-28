# Sprint 11 — Working Days 101–110 (nominal anchor 2026-07-28) — THE REAL-BED SPRINT

> **Sizing is in stories and sprint-sessions, not agent-days** (milestone-02 Notes). Per-story day
> figures below are **relative-complexity anchors**, never calendar predictions.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **S10 proved the payoff loop. It proved it against doubles at exactly one point.** Milestone
> criterion #5 is MET: a real `NeedsMood` and a real `VillagerAi` were paired with no mock at that
> seam, a real `FurnitureRegistry.place()` laid a genuine 2-cell bed, and a real `BuildValidation`
> classified the room as sheltered. What was **not** real is the *item*: `res://data/items/` does not
> exist, so `ResourceItemDatabase` holds zero entries, `is_need_functional(&"bed")` returns **false**
> in production, and `CommitPipeline`'s furniture palette query returns an **empty list**. The bed the
> crown slept in is a registry object with no `ItemDefinitionResource` behind it.
>
> **This sprint makes the bed a real thing you can author, place, and tear down** — and it pays the
> demolition debt D8 left owing.

---

## ⚑ The crown: `rid-009` (MVP data content — the bed stops being a double)

**Why this and nothing else.** Everything the milestone has proved about shelter converges on one
predicate, and that predicate is currently answered by a `null` check. Verified by direct code read,
not by prose:

```gdscript
# src/build_validation/build_validation_config.gd:203
func is_need_functional(definition_id: StringName) -> bool:
    var definition: ItemDefinition = ResourceItemDatabase.get_by_id(definition_id)
    if definition == null:
        return false                       # ← this is the branch production takes, always
    return need_functional_item_ids.has(definition.get_id())
```

`need_functional_item_ids` already defaults to `[&"bed"]`. The config `.tres` is authored. The
consumer (`build_validation.gd:669`) is wired. **The only missing input in the entire chain is a
`bed.tres` file.** Its absence is why:

- `build-validation-006`'s shelter classification **cannot fire end-to-end for a real bed** — and the
  S10 DoD line requiring that re-verification, marked **BLOCKING**, was not met (sign-off §4.1);
- `build-validation-008`'s Warning tier cannot fire end-to-end either, and AC35's decorative case is
  still `[PROVISIONAL — mocked definition]`;
- `CommitPipeline`'s `list_ids_by_category(&"furniture_fixture")` (commit_pipeline.gd:541) returns an
  **empty palette** — meaning **no human can place a bed in the shipped game at all**, which is half
  of milestone criterion #6's own wording.

The crown is a Config/Data story. That is not a demotion — it is the leverage. One story flips a
false branch to a true branch in three separate shipped, tested, green systems.

---

## ⚑ Six findings from reading story files and source, not tables (surfaced, not absorbed)

**F1 — `rid-009` states a dependency line that is false on disk.**
Its Dependencies read: *"Story 001 (schema), Story 004 + Story 008 (validation incl. footprint),
Story 005 (tier-0 coverage), Story 003 (lookup API), Story 007 (missing_item exclusion) — **all
DONE**."* Verified 2026-07-27 against each file's own `Status` line: 001 ✓, 003 ✓, 004 ✓, 005 ✓ —
but **`rid-006` is `Ready`, `rid-007` is `Ready`, and `rid-008` is `Ready`.** Two of the six
dependencies named in the "all DONE" sentence are not done. **`rid-007` and `rid-008` are therefore
scheduled ahead of `rid-009` in this sprint**, not assumed.

**F2 — you cannot author the bed alone; the content set is atomic by construction.**
Verified in `src/resource_item_database/resource_item_database.gd`: `_load_definitions()`
early-returns `success = true` when `data_dir` is missing (today's state — that is why boot is
green with zero items). The moment the directory exists with **any** entry, `_validate_entries()`
runs `_check_tier0_family_coverage()`, which requires ≥ 1 tier-0 `building_material` per family in
`_TIER0_REQUIRED_FAMILIES`. **A lone `bed.tres` halts boot on a coverage gap.** `rid-009`'s four
entries (`wood_block`, `stone_block`, `thatch_block`, `bed`) are one indivisible deliverable.
This is a sequencing fact, not a preference — and it is the crown's named buffer lever.

**F3 — `rid-006` must land AFTER `rid-009`, and it converts content into an art hand-off.**
`rid-006` makes a null `visual_asset` a **terminal boot halt**. Today it would be vacuous (no
entries). Land it *before* content and it stays vacuous; land it *after* content authored without
meshes and it **halts boot**. Sequenced `009 → 006`, and `rid-009`'s four entries must each carry a
real typed `Mesh`. Flagged plainly: **this is an art deliverable sitting inside a Config/Data
story** (three tier-0 material meshes in the Visual Direction Note colours + the bed).

**F4 — `building-011` has already landed, and it IS the `011` the C1 chain means. The chain is
depth 4, not 5.**
D8's option (c) named the S11 opener as `building-009 → 011 → 012 → 015 → 017`. Verified in
`building-012`'s own Dependencies: *"Story 002 (project entity), Story 009 (demolition writeback),
**Story 011 (undo restore)**."* That is plan-only undo/redo — **Complete 2026-07-27, 1355/1355**.
Same story, already satisfied. **The chain this sprint owes is `009 → 012 → 015 → 017`, serial
depth 4.** One story cheaper than the D8 ruling assumed.

**F5 — `building-031` is NOT on the chain, despite its own Unlocks line implying it.**
`building-031`'s Unlocks names *"Story 015 (extends to Built → demolition)"*, but `building-015`'s
own Dependencies read only *"Story 002, Story 009, Story 012"*. **The consuming story's header is
authoritative** (the rule that found the S09 `building-012` inversion and S10's F1/F2), so `031`
runs **fully parallel** on a different lane. It is scheduled anyway because criterion #11's own
wording names the removal tool, and because it is the C1 chain's production caller.

**F6 — ⚑ THE FOURTH SHIP-GREEN-AND-UNCALLED, and this time it is a whole subsystem.**
The S10 sign-off (§5) asked whether a fourth occurrence would land somewhere the boot-invariant
guard does not cover. It has. Verified against `src/scene_world_management/Valley.tscn`'s node list
and `valley.gd::get_injected_tier_modules()` (12 modules: voxel grid / mesher / streamer, camera
input, `ToolStateMachine`, `PlacementPick`, `CommitPipeline`, `ConstructionTickLoop`, `NeedsMood`,
`VillagerAi`, `TorchFlicker`, `VillagerBodyPresenter`):

> **`WallTool`, `FloorTool`, `RoofTool`, `BlockTool`, `FurnitureTool`, `GhostPreview`,
> `UndoRedoStack`, `BuildEditorMode` are in no scene, and `BuildProjectRegistry` /
> `ConstructionJobQueue` are constructed nowhere in `src/`.**

building-ui's Known Conflict 3 recorded this on 2026-07-26 and it is **still true after
`building-001` (build editor mode) landed**. The consequences compound this sprint's own work:
filling the furniture palette with a real bed does not let a human place one, because the furniture
tool is not in the scene; and **the entire C1 demolition chain would ship green with no production
caller** — five stories of exactly the pattern the sign-off named three times. `scene-007` is
scheduled to close it (story file to be authored — see Missing Stories).

**F7 — furniture has no view layer. A placed, built bed is invisible.**
No consumer of `FurnitureRegistry` exists outside `building_system/`, `build_validation/` and
`villager_ai/furniture_bed_provider.gd`; `src/presentation/` contains no furniture presenter; and
BV-1 forbids a FURNITURE-category completion from ever `bulk_write`-ing to the voxel grid (that
prohibition is what makes `build-validation-002`'s furniture-transparency guarantee true by
construction — it is correct, and it is also why furniture can never be visible *via* the grid).
**No story exists for furniture rendering in any epic.** This is the reason `needs-mood-011` and the
R8 external playtest are deferred out of S11: the S10 smoke check's own gate condition — *"a villager
visibly moving in and sleeping should be observed by a human at least once before any external
playtest"* — cannot be met against an invisible bed. Listed under Missing Stories.

---

## Sprint Goal

**Make the bed real, and make the reverse verb work.** Land the RID content chain
(`rid-007` + `rid-008` → **`rid-009`** → `rid-006`) so `res://data/items/` finally exists and
`is_need_functional(&"bed")` is true in the shipped game — retiring the S10 BLOCKING DoD line that
was not met and un-mocking `bv-006`'s shelter classification and `bv-008`'s warning tiers. In
parallel, discharge D8 option (c) by shipping the C1 demolition chain
(`building-009 → 012 → 015 → 017`, plus the parallel removal tool `031`), closing criterion #11 and
paying `needs-mood-010`'s owed follow-on AC — the bed-revocation edge case re-verified against a
**real** demolition job rather than a directly-fired signal. Then host the build tools in the Valley
scene (`scene-007`) so none of it ships green-and-uncalled for the fourth time. Capacity-permitting,
open Cluster B's life work (`villager-ai-019` → `presentation-001` Sub-B), clear the `needs-mood-009`
documentation debt, and put the first stake in Cluster D.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved. **Named consumers, declared up front (the S08/S09/S10 practice,
  which has now worked three times):**
  1. **PRIMARY — `rid-009`.** It is the first story in this project's history whose deliverable is
     *shipped data*, and the moment `res://data/items/` becomes non-empty the RID boot pipeline runs
     its full per-entry **and cross-entry** check set against production content for the first time
     ever. A failure here does not redden one test — **it halts the game's boot.** **Named lever
     (from F2):** land the **three tier-0 materials as their own commit first** — that satisfies the
     family-coverage invariant on its own and gives a green boot to build on — **then** add the bed.
     **Never author the bed alone.** If a validation shape fails in a way that is not a five-minute
     data fix, escalate to technical-director rather than relaxing a boot check that was written to
     be terminal.
  2. **SECONDARY — `scene-007`.** Its **story file does not exist** (day-one authoring gate below),
     it is an ADR-0005 boot/hosting change in the same two files `scene-005` and `scene-006` touched,
     and it is the countermeasure to F6. **Named lever:** if authoring shows it is larger than 1.0,
     host the **tool tier only** (`BuildEditorMode` + the four tools + `FurnitureTool` +
     `GhostPreview`) and defer `BuildProjectRegistry` / `ConstructionJobQueue` / `UndoRedoStack`
     hosting to S12 — but **never ship the C1 chain with no caller and no named debt**.
- **Available:** 8 days
- **Committed:** Must 9 stories = 9.0 story-days *(serial sum)*; Should 4 = 3.5; Nice 2 = 1.5.
- **Measured cadence:** S1–S10 = 8, 9, 9, 8, 8, 13, 12, 13, 18, 14 stories/session. **15 stories is
  inside the band** and identical in size to S10's plan. Throughput is not the binding constraint;
  the binding constraints are (1) lane C's serial depth 5, (2) `rid-009`'s art hand-off, and
  (3) five unowned decisions.

### Parallel-lane capacity model

| Lane | Owner | Must sequence | Must lane-days |
|---|---|---|---|
| **R — the content lane (the crown)** | `godot-gdscript-specialist` | `rid-008` ∥ `rid-007` → **`rid-009`** → *(Should)* `rid-006` | 2.5 |
| **R2 — removal tool (independent)** | `godot-gdscript-specialist` | `building-031` | 1.0 |
| **C — the demolition lane** | `godot-specialist` | `building-009` → `012` → `015` → `017` → `scene-007` → *(Nice)* `building-ui-001` | 5.0 |
| **B — the life lane** | `ai-programmer` | *(Should)* `villager-ai-019` → `presentation-001` Sub-B → *(Nice)* `villager-ai-013` | 0 Must |
| **Doc** | `systems-designer` | *(Should)* `needs-mood-009` | 0 Must |

Max Must lane = **5.0** (lane C), inside 8 with ~3.0 headroom. Adding all Should + Nice takes lane C
to 6.0 and lane R to 3.5 — headroom ~2.0.

**Honest read, and the deliberate contrast with S10:** *there is no three-lane convergence this
sprint.* No story on this plan takes inputs from more than one lane. That is the single biggest
structural difference from S10 and it is why a same-sized sprint carries lower delivery risk. The
risk has moved rather than disappeared: it now sits in **serial depth** (lane C is 5 deep — a slip at
`building-009` pushes four stories) and in **one soft cross-lane coupling** — `building-017`'s
follow-on AC re-runs `needs-mood-010`'s live-pair test, which is the `ai-programmer` lane's file.
Serialize that re-run against anything lane B has open.

### Sprint 10 actuals (calibration context)

- **14/16 tracked stories complete** — the Sprint Result's own "16/16" was **corrected by the QA
  sign-off** (§1); `build-validation-009` (TD-gated) and `building-009` (correctly deferred per D8
  option (c)) never landed. Suite **1198 → 1383**, green with 0 orphans on every story commit.
  Sign-off verdict: **APPROVED WITH CONDITIONS**. The Sprint Result paragraph has since been
  corrected in place — sign-off condition #1 is **closed**.
- **THE CROWN LANDED.** Criterion #5 is MET, and QA verified it by reading the test file rather than
  the story's claim: real `NeedsMood` + real `VillagerAi` at the forbidden seam, real
  `FurnitureRegistry.place()`, real `BuildValidation` shelter classification, poll-not-event variant
  green with `need_urgent` deliberately unconnected, ×1.0 vs ×0.7 both asserted.
- **The loop can start in production** (`scene-006`) and **villagers have bodies**
  (`presentation-003`, with a genuine `_visual_position` call-site allowlist guard, QA-verified).
- **Two process findings carried in.** (a) *A suite run is only evidence about the change under test
  if nothing else in the tree is mid-edit* — an S10 revert was made on a red run that contained
  another lane's half-finished work; the identical change measured green when re-applied.
  **This sprint runs five stories on one serial lane in one tree — the same hazard.** (b) The
  recurring fixture trap bit a fourth agent, who recognised it from the briefing: the briefing
  process working.
- **Sign-off condition #3 (no QA plan) is the process gap this sprint fixes** — see the Day-0 gate.

## ⛔ Day-0 gates (both close before any `/dev-story`)

| # | Gate | Owner | Why it is a gate, not a task |
|---|---|---|---|
| **G1** | **`/qa-plan sprint` → `production/qa/qa-plan-sprint-11-2026-07-28.md`** | **qa-lead** | S10 listed the QA plan as a DoD line and **nothing gated on it, so it never happened** — the sign-off caught it as condition #3. Making it a DoD line again would repeat the failure verbatim. It is now a **gate before the first `/dev-story` call on any lane**. *(Recorded honestly for the S10 lapse: the sprint went from planning straight to three day-one parallel lane starts; the plan named the artifact but nothing blocked on its absence.)* |
| **G2** | **Author `scene-007`'s story file** | **producer** | Scheduled as a Must with no file on disk — the same shape as `presentation-003` in S10, where the day-one authoring gate worked. Unlike `presentation-003` there is **no TD spec to transcribe**; the scope must be derived from building-ui Known Conflict 3's verified list and ADR-0005's boot phases. **Invent no ACs beyond what KC3 and ADR-0005 already state**, then run `/story-readiness`. |

## Tasks

### Must Have (the crown and the debt)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| rid-008 | **Furniture `footprint` field + boot validation.** ⚑ Day one on lane R — gates the crown | `production/epics/resource-item-database/story-008-furniture-footprint-validation.md` | godot-gdscript-specialist | 1.0 | rid-001 ✓, rid-004 ✓ (its own header; both Complete) | `furniture_fixture` with valid `footprint` (both dims ≥ 1) accepted and queryable exactly as authored; missing `footprint` (31a) **or** a non-positive dimension (31b) **halts boot naming the entry AND the violated dimension** — both sub-cases; a non-`furniture_fixture` entry carrying an authored `footprint` halts boot naming the entry (category↔footprint pairing). ⚑ **Read the landed field before writing the check**: `@export var footprint: Vector2i = Vector2i(1, 1)` already exists on `ItemDefinitionResource` with an `ItemDefinition.get_footprint()` getter — this story adds the **two validation checks**, not the field. The `(1,2)` bed value is authored in `rid-009`, never here. Passing unit test |
| rid-007 | **`missing_item` fallback definition + exclusion from listings.** Day one, parallel to `rid-008` | `production/epics/resource-item-database/story-007-missing-item-fallback.md` | godot-gdscript-specialist | 1.0 | rid-003 ✓, rid-005 ✓ (its own header; both Complete). **Blocked on nothing** | An unknown stored id resolves via a **dedicated fallback path** (`resolve_or_missing`), distinct from `get_by_id`'s not-found result, to the fully inert built-in `missing_item` — every field per Edge Case 1; each distinct missing id logged **exactly once per load event**; `missing_item` **never appears in ANY listing query** (by category, family, tier, or list-all) — reachable only by direct get-by-id. `missing_item` is a **code-defined built-in, never an authored `.tres`** (rid-005 already rejects an authored one). AC9b's save round-trip stays deferred. Passing unit test |
| **rid-009** | **⚑ THE CROWN — MVP data content: the three tier-0 materials + the bed. `res://data/items/` comes into existence** | `production/epics/resource-item-database/story-009-mvp-data-content.md` | godot-gdscript-specialist *(art hand-off: `art-director` / user for the four meshes)* | 1.0 | rid-001 ✓, 003 ✓, 004 ✓, 005 ✓ + **rid-007 (in-sprint, HARD)** + **rid-008 (in-sprint, HARD — the bed needs the validated `footprint`)**. ⚑ **F1: the story's own "all DONE" line is wrong — 007 and 008 were NOT done** | Exactly `wood_block`, `stone_block`, `thatch_block` at tier 0 (one per family) + the `bed` `furniture_fixture`; tier-0 building-material query returns exactly those three; category queries return exactly their own ids with **no cross-category leakage** and `missing_item` never present; **`get_by_id("bed").footprint == (1, 2)`** — the slice-validated, user-locked value; **all 11 fields populated on every entry** including the four Alpha-deferred ones (`stackable`, `max_stack_size`, `haulable`, `storage_category`) — boot validation enforces presence. ⚑ **SEQUENCING IS LOAD-BEARING (F2): commit the three tier-0 materials FIRST — a lone `bed.tres` halts boot on the tier-0 family-coverage gap.** ⚑ **BLOCKING DoD inherited from S10, finally satisfiable: re-verify `build-validation-006`'s `is_need_functional(&"bed")` TRUE branch non-vacuously against the real authored `ItemDefinitionResource`** — `shelter_classification_test.gd` currently asserts it returns `false`; that assertion must become a real two-branch test. ⚑ **Also re-verify `build-validation-008`'s bed Warning tier end-to-end** (sign-off §4.4). Content smoke Smoke-1..4 recorded in `production/qa/smoke-*`; AC29 palette-legibility screenshot is **Advisory, non-blocking** |
| building-031 | **Removal-tool base — the C1 chain's production caller.** Independent; day one on lane R2 | `production/epics/building-system/story-031-removal-tool-base.md` | godot-gdscript-specialist | 1.0 | building-021 ✓, building-029 ✓ (its own header; both Complete). ⚑ **F5: `031`'s Unlocks names `015`, but `015`'s own header does NOT list `031` — they are NOT serially blocked** | Removal tool as a `ToolStateMachine` mode operating on blueprint cells and their micro-states, revoking claims on cells it removes; criterion #11's own named "removal tool" half. **Do not implement the Built→demolition extension here** — that is `building-015`'s scope. Passing unit test |
| building-009 | **Demolition orders (blocks) — C1's head, criterion #11.** ⚑ Day one on lane C; it gates three stories | `production/epics/building-system/story-009-demolition-orders-blocks.md` | godot-specialist | 1.0 | building-002 ✓ (its own header — **and nothing else**) | Worker-executed block demolition with `restore_value` write-back; **demolition is job-based and uniform — no instant-removal carve-out anywhere**, which is the invariant `building-017` later inherits to remove the last one. Its Unlocks line names `010`, `012`, `015` and `017`: **a slip here pushes three in-sprint stories**, so it starts day one on an otherwise-idle lane |
| building-012 | **Floor-excavation `restore_value` — Cluster 0 residue, now unblocked** | `production/epics/building-system/story-012-floor-excavation-restore-value.md` | godot-specialist | 1.0 | building-002 ✓, **building-011 ✓ (Complete 2026-07-27 — F4: this is the `011` the D8 chain meant)**, **building-009 (in-sprint, HARD)** | `restore_value` recorded on floor-over-terrain excavation and written back on demolish/cancel, so building over terrain is **reversible without destroying the terrain underneath**; coordinates with `TR-voxel-world-050`. Depth-2 on lane C |
| building-015 | **Draft-eraser / removal branch (Built → demolition routing)** | `production/epics/building-system/story-015-draft-eraser-removal-branch.md` | godot-specialist | 1.0 | building-002 ✓, **building-009 (in-sprint, HARD)**, **building-012 (in-sprint, HARD — `restore_value` on cancel)**. *(`building-031` is NOT a dependency per its own header — F5)* | The eraser branches on cell micro-state: a not-yet-Built cell is **cancelled** (with `restore_value` applied per `012`), a Built cell **routes into `009`'s demolition-order contract** — never an instant removal. This is the story that makes "tear it down" one uniform verb rather than two behaviours |
| building-017 | **Furniture demolition — closes criterion #6 to 4/4 and PAYS D8's OWED FOLLOW-ON AC** | `production/epics/building-system/story-017-furniture-demolition.md` | godot-specialist | 1.0 | building-016 ✓ (Complete S10), **building-009 (in-sprint)**, **building-015 (in-sprint)** — its own header, all three | Furniture demolition **reuses `009`'s job-based contract** and `015`'s not-yet-Built branch — removing the last instant-removal carve-out; a multi-cell footprint demolishes as **one entity**, never per-cell. ⚑ **THE DEBT, named explicitly (D8 option (c), recorded in the S10 plan): `needs-mood-010`'s bed-revocation edge case is currently proven by firing `FurnitureBedProvider.furniture_revoked` directly. This story owes its non-vacuous re-verification** — re-run `shelter_recovery_live_pair_test.gd`'s revocation case driven by a **real demolition job completing**, asserting wake + `stop_recovery` crediting zero that tick + ownership dissolving. Same discipline already applied twice (BV-1's furniture-transparency guard, `bv-006`'s need-functional branch). **Cross-lane note: that test file is the `ai-programmer` lane's — serialize the re-run** |
| scene-007 | **Build-tool & project-lifecycle hosting in the Valley scene — THE FOURTH SHIP-GREEN-AND-UNCALLED.** ⛔ **STORY FILE DOES NOT EXIST — see gate G2.** Sequenced LAST on lane C | *(to be authored)* `production/epics/scene-world-management/story-007-build-tool-and-project-lifecycle-hosting.md` | godot-specialist *(`.gd` review: godot-gdscript-specialist)* | 1.0 | building-001 ✓ (build editor mode), building-021 ✓, 029 ✓, 030 ✓, 032 ✓, scene-005 ✓, scene-006 ✓ + **building-031 (in-sprint — so the removal tool is hosted with the rest)** | Scope derived from building-ui **Known Conflict 3**'s verified list and ADR-0005's boot phases — **invent nothing beyond them**. `BuildEditorMode`, `WallTool`, `FloorTool`, `RoofTool`, `BlockTool`, `FurnitureTool`, `GhostPreview`, `UndoRedoStack` gain a scene home and a `Valley` getter; `BuildProjectRegistry` and `ConstructionJobQueue` (both `RefCounted`, constructed nowhere in `src/`) gain a construction site and are handed to the already-hosted `ConstructionTickLoop`. Hosting is **not** DI: `Valley` reports the list via `get_injected_tier_modules()`; `GameWorld` calls `setup()`. ⚑ **Non-vacuity is the whole story, exactly as in `scene-006`**: the proof is an integration assertion that a placement/demolition intent driven through the **hosted** tool reaches the grid or the job queue — **prove it by deleting the hosting call once and recording the observed failure in the commit body.** ⚑ **This closes the loop on the crown**: without it, `rid-009`'s real bed is in a palette no hosted tool can read |

### Should Have (life, documentation debt, and the content's validator)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| rid-006 | **`visual_asset` resolution validation (two failure shapes).** ⚑ Sequenced strictly AFTER `rid-009` — see F3 | `production/epics/resource-item-database/story-006-visual-asset-validation.md` | godot-gdscript-specialist | 0.5 | rid-004 ✓ (its own header) + **`rid-009` (in-sprint, ORDERING — not a stated dependency, a landing-order constraint)** | Boot validation checks **resource-load success FIRST**, then `visual_asset != null` — two distinct diagnostics, both terminal, order asserted (a broken `.tres` must be reported as *"entry failed to load"*, never as *"visual_asset unresolved"*). `visual_asset` is a typed `Mesh`, never a path string — **no filesystem existence check**. ⚑ **F3: landing this before `rid-009` makes it vacuous; landing it after content authored without meshes HALTS BOOT.** Its acceptance therefore includes: the four shipped entries pass it. Passing unit test |
| villager-ai-019 | **Wandering / idle micro-behaviors — Cluster B's opener, CD-protected** | `production/epics/villager-ai-behavior/story-019-wandering-micro-behaviors.md` | ai-programmer | 1.0 | villager-ai-006 ✓, 007 ✓ (its own header; both Complete). **Blocked on nothing** | Idle fall-through produces bounded, reachable wandering off the existing graph — never a new pathfinder; deterministic under the tick contract, no wall-clock. **This is the milestone's oldest open finding's unblocker** (criterion #9: the CD ruled the slice debrief's #1 "world lacks life" finding stays OPEN until `presentation-001` Sub-B lands, and Sub-B is gated on exactly this story). Passing unit test |
| presentation-001 Sub-B | **Ambient life wave 1, Sub-scope B — villager idle behaviors in the composed Valley** | `production/epics/presentation-experience/story-001-ambient-life-wave-1.md` *(Sub-scope B of an existing story; Sub-A Complete 2026-07-24)* | ai-programmer *(CD sign-off required)* | 1.0 | **villager-ai-019 (in-sprint, HARD — its own header: "the hook cannot play idle behaviors until an Idle/Wandering state exists to read")** + `presentation-003` ✓ (TD downstream item 16 added this prerequisite; it landed S10) | The idle/wandering hook plays in `game_world.tscn`, not in a harness. ⚑ **Criterion #9 is met only on a WRITTEN CD CLOSE, not on tests passing** — the evidence entry in `production/qa/evidence/ambient-life-wave-1-evidence.md` needs a dated CD close line. **Do not mark this criterion met from a green suite.** Advisory evidence (screenshots) per the testing standards |
| needs-mood-009 | **Real-time-rate pass at `ticks_per_second = 4.0` (criterion #4) — pure documentation.** ⛔ **Gated on decision D6(ii)** | `production/epics/needs-mood-system/story-009-real-time-rate-pass.md` | systems-designer | 1.0 | needs-mood-002 ✓, 003 ✓, 005 ✓, 008 ✓ (its own header; **all Complete — no in-sprint dependency**). ⛔ **EXTERNAL: D6(ii) cross-GDD authority ruling — see Open Decisions** | Every Needs & Mood rate carries a stated real-time equivalent at 4.0/s; the pacing cross-reference resolved **by name** (tick anchors CONFIRMED, feel targets RESTATED per CD Ruling 1 Option B); the Game Feel section's "~10-minute heartbeat" / "~7-min stretch" restated to **~4 min 45 s / ~3 min** (CD: *"mine, not a mechanical conversion — do not skip it"*); the **repo-wide `at 1x` sweep** across all of `design/`, including `build-validation-navigability.md`'s `room_cue_cooldown_ticks` "20 (= 10s at 1x)" → **5 s**; the kill criterion recorded with its explicit **non-trigger**; the `max_ticks_per_frame = 10` prose corrected to the landed **12**; a **config-anchor regression test** so a future silent retune fails the suite. ⚑ **HARD GUARD: no `.tres` edit, no AC anchor move, no test edit. If this story produces a config diff, the ruling was not followed.** ⚑ **F8 — the story contradicts itself**: its 5th AC requires editing `building-system.md`'s `base_build_ticks` / both `base_demolition_ticks` mirrors, while its Dependencies say *"Coordinate (do not edit from here)"* about the same lines. **D6(ii) is that contradiction, not a tidiness question** |

### Nice to Have (pull only if lanes C and R clear)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-ui-001 | **HUD host scaffold — Cluster D's first stake (criterion #10).** ⛔ Gated on the TD hosting ruling | `production/epics/building-ui/story-001-hud-host-scaffold.md` | godot-specialist | 1.0 | building-001 ✓ + **`scene-007` (in-sprint — sequence after it; they answer the SAME architectural question)**. ⛔ **EXTERNAL: technical-director ruling on Known Conflict 1/3 — which scene owns the HUD node** | The HUD `CanvasLayer`/`Control` host with the Z-zone system every other building-ui story docks into; **grep proves the HUD writes no simulation state** (zero `VoxelWorldGrid.set_cell`/`bulk_write`/`clear_cell`, zero config-field writes). ⚑ **Note: `src/ui/` does not exist — this epic starts from zero (KC1, recorded, not a defect).** ⚑ **Scheduling rationale: the milestone's cut-lever signal "Cluster D has not started by S12" fires at the START of S12.** This one story is what makes the honest answer "started". If it is trimmed, the lever fires — see D3 |
| villager-ai-013 | **Nudge-aside / vacate (F4) — the CD's named pull-forward trigger** | `production/epics/villager-ai-behavior/story-013-nudge-aside-vacate-f4.md` | ai-programmer | 0.5 | villager-ai-004 ✓, 006 ✓ (its own header; both Complete). **Blocked on nothing** | A blocked villager asks the occupant to step aside rather than re-pathing or freezing; deterministic ordering per ADR-0009. The CD named the `013`+`019` seam as precisely the moment the settlement stops reading as mechanical. Also unlocks `villager-ai-020` (breather beat) for S12. Passing unit test |

## Missing Stories (NOT fabricated — recorded for `/create-stories`)

| Story | Status | Who authors it | Blocks |
|---|---|---|---|
| **`scene-007`** — build-tool & project-lifecycle hosting (F6) | **Scheduled as Must in this sprint, file does NOT exist.** Unlike `presentation-003` there is **no TD spec to transcribe** — scope must be derived from `production/epics/building-ui/EPIC.md` **Known Conflict 3**'s verified module list and ADR-0005's boot phases | **Producer** (gate G2, day one). Then `/story-readiness` before `/dev-story` | The C1 chain's production caller; `rid-009`'s bed being placeable by a human; `building-ui-003/004/005/011` (KC3 names them explicitly) |
| **Furniture view / render layer** (F7) | **Does not exist in ANY epic.** `src/presentation/` has no furniture presenter, and BV-1 correctly forbids furniture from reaching the voxel grid — so a built bed is **invisible** in the running game | `/create-stories` in **presentation-experience** (the layer that owns world-space views) after a TD call on the render mechanism (MultiMesh vs. per-item `MeshInstance3D`) | **R8 external playtest**, `needs-mood-011`, and criterion #6's human-observable half. This is the reason both are deferred out of S11 |
| **Multi-cell furniture REDO atomicity** (sign-off §4.2) | **No story, no AC.** Placement is atomic (AC75) and undo cancels a footprint's siblings together, but **redo re-validates every cell independently** — it can rebuild one half of a bed. Confirmed in `plan_only_undo_redo_test.gd`'s own class doc | `/create-stories` in **building-system**, or an AC amendment on `building-016` | Nothing today (the bed is MVP's only multi-cell item). **Becomes a real defect the moment a second multi-cell item ships** — that is the trigger to schedule it, not sooner |
| **Mid-range hardware baseline re-measurement** (criterion #13) | **Still does not exist** — voxel-world ends at `story-021`. **Fourth consecutive sprint.** Two unowned TD decisions block authoring it | `technical-director` decides (hardware class + VSync), then `/create-stories` in voxel-world | Criterion #13 — **protected, never on the cut lever**, so this converts one-for-one into milestone risk |

**Not a story — a DoD task.** `build-validation-007`'s tick-source production-wiring assertion
(sign-off §4.3): `BuildValidation.time_tick_system` is nil-safe and nil is silently accepted, so
celebration pacing can freeze at tick 0 in the shipped game with no test noticing. Add a guard
analogous to `needs-mood-010`'s "exactly one production call site" grep. **Owner: `ai-programmer`
(bv-007's author), ~0.1 day, folded into this sprint's DoD** — not a story, and not allowed to lapse
a second time.

**Not stories — decisions.** Do not let these be written as work: **VSync mode** and **target
hardware class** (both technical-director); **TD concurrence on CD Ruling 2's implementation form**
(gates `bv-009`); **the HUD hosting ruling** (KC1/KC3); **D6(ii)**; **D3**; and **ratification of the
two provisional ruling documents** (user-owned, carried as an input, never scheduled).

## Milestone-Criteria Advancement Map (what this sprint moves)

| # | Criterion | S11 disposition |
|---|-----------|----------------|
| #1 | Build Validation implemented (AC1–35, 37, 38) | **HELD at 8/9 stories.** `bv-009` remains TD-gated and is **not scheduled** — second sprint. What *does* move: `bv-006`'s and `bv-008`'s mocked branches become real via `rid-009`. |
| #2 | Reachability corpus green ≤ 60 s in CI | **HELD, unchanged.** The wording must still read *"5,000-verdict spec not yet met; the 1,000-verdict shipped configuration is 0/0 disagreement."* **Do not let this sprint silently upgrade it.** The S09 `nav_region_size` 200→40 retune (6697.6 ms → 266.6 ms) remains the un-actioned TD lever on the density question. |
| #3 | Needs & Mood implemented | **MVP-complete since S10.** No code stories this sprint. |
| #4 | Real-time-rate pass recorded | **CLOSES if D6(ii) is ruled** — `needs-mood-009` (Should). Blocked on a decision, not on capacity. |
| #5 | Payoff loop closes live-pair | **MET (S10) — and its owed debt is PAID this sprint.** `building-017` re-verifies the bed-revocation edge case against a real demolition job instead of a directly-fired signal (D8 option (c)'s follow-on AC). |
| #6 | Furniture placeable, buildable, claimable | **3/4 → 4/4 on code** (`building-017` lands removal/revocation). ⚑ **But state it honestly: the criterion's *player-facing* half — "the player places a bed" — needs `rid-009` (the palette) AND `scene-007` (the hosted tool) AND a furniture view (missing). After S11 it is code-complete and human-unobservable.** |
| #7 | `presentation-002` signals something real | **NOT THIS SPRINT.** `bv-009` still blocked on TD concurrence + the `@export RefCounted` collision. Second sprint carrying an unmade decision. |
| #8 | Ambient life wave 1 complete in the composed Valley | **ADVANCES** — `presentation-001` Sub-B (Should). The four CD advisories (golden-hour re-shoot, foliage hue, torch colour, Dusk/Horizon tests) remain outstanding. |
| #9 | "World lacks life" formally CLOSED by the CD | **BECOMES CLOSABLE** — `villager-ai-019` → Sub-B. ⚑ **Met only on a written, dated CD close entry**, never on a green suite. |
| #10 | Building UI + Villager Info UI ship | **STARTS, minimally** — `building-ui-001` (Nice). ⚑ **The R2/D3 epic-creation gate is CLOSED**: both epics now exist on disk (building-ui 18 stories, villager-info-ui 7, all `Status: Ready`) — the S10 sign-off's "still no epics created" carry-forward is **stale**. villager-info-ui's Known Conflict 1 (villager body / collision layer) was **closed by `presentation-003`**. |
| #11 | Lifecycle breadth — demolition | **⚑ THE SPRINT'S SECOND TARGET. CLOSES on code**: `009` (block demolition) + `031` (removal tool) + `015` (draft eraser) + `017` (furniture). `building-027`'s remove-mode routing is the one remaining wording question — check whether `031` satisfies it or a follow-on is owed. |
| #12 | Plan-only undo is real | **MET (S10, `building-011`).** Its only open edge is redo atomicity (Missing Stories). |
| #13 | Mid-range hardware baseline | **STILL NO STORY, still two unowned decisions. Fourth consecutive sprint.** See E1. |
| #14 | `/team-qa sprint` sign-off every sprint | **HABIT CONTINUES, and the QA-plan half is repaired** — G1 makes it a gate, not a DoD line. |

## Critical Path

```
lane R   rid-008 ┐
                 ├→ rid-009 (THE CROWN) → [rid-006]
         rid-007 ┘
lane R2  building-031 ──────────────────────────────┐
                                                    ↓  (hosted together)
lane C   building-009 → building-012 → building-015 → building-017 → scene-007 → [building-ui-001]
                                                          ↓
                                              (re-runs needs-mood-010's live pair — lane B's file)
lane B   [villager-ai-019] → [presentation-001 Sub-B] → [villager-ai-013]
lane Doc [needs-mood-009]
```

- **Longest serial chain: lane C, depth 5** (`009 → 012 → 015 → 017 → scene-007`), ~5.0 lane-days.
  `building-009` gates three in-sprint stories — **start it on day one**, alongside `rid-008`,
  `rid-007` and `building-031`, all four of which are blocked on nothing.
- **No cross-lane convergence.** Unlike S10, no story here takes inputs from two lanes. The one soft
  coupling is `building-017` re-running `needs-mood-010`'s test file.
- **`rid-009` is the crown but it is NOT last** — deliberately. It sits at depth 2 on a short lane so
  that a content/validation surprise has room to be fixed inside the sprint, and so `rid-006`,
  `bv-006`'s re-verification and `bv-008`'s re-verification all have real data to run against with
  days to spare.
- **The S10 tree-hygiene lesson applies directly here**: five stories land on one serial lane in one
  working tree. **A red suite during lane C must be re-run in isolation (clean stash or separate
  branch) before any change is reverted on its basis.** S10 reverted a correct change on a red run
  that contained another lane's half-finished work.

**Recommended trim order, if one is needed** (decide at mid-sprint, on signal):
1. **`villager-ai-013` (Nice)** — pure cost, no in-sprint consumer; `villager-ai-020` is S12 anyway.
2. **`building-ui-001` (Nice)** — but **read D3 first**: trimming it is what makes the S12 cut-lever
   signal fire on Cluster D. That may be the correct outcome; it must not be an accident.
3. **`needs-mood-009` (Should)** — if D6(ii) is not ruled, it is trimmed *for you*.
4. **`presentation-001` Sub-B (Should)** — CD-protected; trimming it needs CD sign-off and it leaves
   criterion #9 open for a fourth sprint. Prefer trimming `rid-006` first.
5. **Never trim**: any Must; `scene-007` in particular (trimming it converts the entire C1 chain into
   the fourth ship-green-and-uncalled); the `bv-006`/`bv-008` re-verifications folded into `rid-009`;
   `/team-qa sprint` + the consolidated smoke artifact.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| **RID content authoring (`rid-008`/`009`)** | Named first in the S10 sign-off's own carry-forward list. Was in **no** sprint. **Now the crown**, with `rid-007` added ahead of it (F1) and `rid-006` behind it (F3). | 3.5 |
| **The C1 demolition chain** | D8 option (c)'s explicit commitment: *"the full C1 chain as S11's opener."* **F4 shortens it from 5 stories to 4** (`011` already landed). `031` added in parallel because criterion #11's wording names the removal tool. | 5.0 |
| **`building-009`** | Nice-tier in S10, correctly not pulled per D8. **Now Must, and the head of the chain.** | 1.0 |
| **`build-validation-006`'s `is_need_functional` true branch** | A **BLOCKING** S10 DoD line that was **not met** (sign-off §4.1, condition #2). Blocked by missing content, not by code. **Folded into `rid-009`'s DoD** — the content now exists, so the excuse does not. | 0 (folded) |
| **`build-validation-008`'s end-to-end bed Warning** | Same root cause (sign-off §4.4). **Folded into `rid-009`'s DoD.** | 0 (folded) |
| **`needs-mood-009`** | Deferred from S10 pending **D6(ii)**. Scheduled as **Should**, still gated on the ruling. **F8 shows the contradiction is inside the story file itself** — one AC orders the cross-GDD edits its own Dependencies section forbids. | 1.0 |
| **`build-validation-009`** | **NOT scheduled.** Still externally blocked on TD concurrence re: CD Ruling 2's `PayoffDetail` form vs. the measured Godot 4.7 `@export RefCounted` limitation. **Second sprint blocked on the same unmade decision.** Unblock the decision before scheduling it a third time. | — (deferred) |
| **Multi-cell furniture redo atomicity** | Sign-off §4.2. **No story, no AC.** Recorded under Missing Stories with a named trigger (a second multi-cell item), not scheduled — the bed is MVP's only multi-cell item. | — (deferred) |
| **`bv-007`'s tick-source production-wiring assertion** | Sign-off §4.3. **Folded into the DoD** as a ~0.1-day task for `ai-programmer`, not a story. | 0 (folded) |
| **Cluster D UI epics** | **Carry-forward is STALE.** Both epics exist on disk with all 25 story files at `Status: Ready` (verified 2026-07-27). What remains open is **D3's scope question**, not epic creation. | — |
| **`needs-mood-011` + R8 external playtest** | **Deferred to S12 — and NOT for capacity.** The S10 smoke check's own gate condition requires a human to observe a villager moving into a bed before any external playtest. **F7: a placed bed is invisible** (no furniture view exists anywhere) and **F6: the furniture tool is not in the scene**. `scene-007` fixes half of that this sprint; the view story does not exist yet. Running R8 now would test a settlement the player cannot furnish. | — (S12) |

## Sign-Off Conditions Carried In (from `qa-signoff-sprint-10-2026-07-27.md`)

| Condition | S11 disposition |
|---|---|
| **#1 — Correct the Sprint Result's "16/16" and "1264 → 1383"** | **CLOSED.** `sprint-10.md`'s Sprint Result now reads *"14/16 stories complete... CORRECTED 2026-07-27 by the QA sign-off"* and *"Suite grew 1198 → 1383"*. Verified on disk; no action. |
| **#2 — `bv-006`'s `is_need_functional` true branch still unverified (a BLOCKING DoD line that was not closed)** | **THIS SPRINT'S CROWN EXISTS TO CLOSE IT.** Folded into `rid-009`'s DoD as a BLOCKING line, with `bv-008`'s bed-warning re-verification alongside. **Not allowed to lapse twice.** |
| **#3 — No `qa-plan-sprint-10-*.md` was ever produced** | **Fixed structurally: G1 is a Day-0 GATE, not a DoD line.** The S10 lapse is recorded honestly above — the plan named the artifact but nothing blocked on its absence, and the sprint went straight to three day-one lane starts. |
| **#4 — Both pre-flight ruling documents remain unratified** | **User-owned, carried a third sprint. NOT scheduled as work.** This plan proceeds as-if-ratified, same posture as S8/S09/S10. Exposure this sprint: `needs-mood-009` cites CD Ruling 1 (Option B) and `bv-009` cites CD Ruling 2 — the latter is not scheduled, the former is a doc pass with a no-value-change guard. |
| **#5 — Multi-cell redo limitation + `bv-007`'s unasserted tick wiring** | Redo → **Missing Stories**, with an explicit trigger. `bv-007` wiring → **folded into the DoD**. Neither absorbed silently. |
| **§5 — "a suite run is only evidence if nothing else in the tree is mid-edit"** | **Named in the Critical Path as a working rule for lane C**, which runs five stories serially in one tree. A red run must be re-run in isolation before any revert. |
| **§5 — "a new production API needs a proven caller in the same sprint"** | **Applied as a planning check, and it is what produced `scene-007`.** Every Must story was checked for a production caller: `rid-009`'s callers already exist and are landed (`commit_pipeline.gd:541`, `build_validation_config.gd:203`); the C1 chain's caller is the removal tool, **which is in no scene** — hence F6 and `scene-007`. |

## Out of Scope (deferred from S11, with honest reasons)

- **`build-validation-009`** → deferred, TD-gated (second sprint). **`presentation-002`'s real
  signals (criterion #7) do not move this sprint** as a direct consequence.
- **`needs-mood-011` (game-feel probe) and the R8 external playtest** → **S12**, blocked on the
  furniture view (F7) and, until `scene-007` lands, on tool hosting (F6). Not a capacity call.
- **`needs-mood-012`** (Save/Load) and **build-validation AC26** — VS-tier, explicitly out of M02.
- **Cluster C tiers C2–C4** (`building-007` change orders; `006` pause/resume, `008` click-selection;
  `010` Abriss, `018` tool-batch, `013`/`014` dig-mining, `villager-ai-017`) — **the lever's own
  targets, untouched.** Note `building-010` (Abriss) becomes cheap after `009`+`015` land, and
  `building-ui-011`'s Projects-Panel buttons need `006`+`010` — see **D1**.
- **`villager-ai-020`** (breather beat) → S12; its own header depends on `013` (Nice this sprint).
- **`villager-ai-023`** (scene-transition continuity) → S12+. Third sprint deferred on value.
- **Cluster D beyond `building-ui-001`** — 24 remaining stories. See **D3**; several are blocked on
  Known Conflicts 2/4/5/6, which are TD decisions, not work.
- **Roof formations beyond Flat, doors/windows as objects, wall-coverage, mood consequences, audio,
  economy** — VS-tier per the milestone's Out of Scope section.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **`rid-009` is the first story to put real data in front of the RID boot pipeline, and a validation failure halts the GAME, not a test** | Medium | **High** | Buffer's **primary named consumer**. Named lever (F2): three tier-0 materials as their own commit first — that alone satisfies family coverage — **then** the bed; never the bed alone. `rid-007` and `rid-008` land ahead of it so the fallback and footprint checks are in place before content arrives. Escalate a stubborn validation shape to TD rather than relaxing a deliberately-terminal boot check. |
| **`rid-009` carries an art deliverable inside a Config/Data story** (four typed `Mesh` `visual_asset` bindings + the magenta `missing_item` placeholder) — and `rid-006` turns a null one into a boot halt | Medium | Medium | F3, stated plainly. `visual_asset` is consumed nowhere yet (the mesher's block colouring is an explicit debug placeholder), so **simple primitive meshes in the Visual Direction Note colours satisfy both stories**; the bed's real model is a later art pass, not a gate. **If meshes are not ready, ship `rid-009` and TRIM `rid-006`** — that ordering is safe; the reverse is not. |
| **Lane C is serial depth 5 and `building-009` gates three of them** | Medium | **High** | Day-one start on an otherwise-idle lane. `building-031` is deliberately placed on a *different* lane precisely because F5 proved it is not chained. Mid-sprint trip-wire: **if `building-015` has not started by ~day 6, trim `building-ui-001` and `villager-ai-013` immediately** rather than compressing `scene-007`, which is the sprint's anti-dead-code guarantee. |
| **`scene-007` has no story file AND no TD spec** — unlike `presentation-003`, which had VB-1/VB-2 to transcribe verbatim | Medium | Med-High | Buffer's **secondary named consumer**. Gate G2 on day one; scope derived **only** from building-ui KC3's verified module list and ADR-0005's boot phases, inventing nothing. Named lever: host the tool tier only and defer the registry/queue/undo-stack tier to S12 **as a named debt**. ⚑ **Its non-vacuity proof is the story** — delete the hosting call once, record the observed failure, exactly as `scene-006` did. |
| **Five decisions are unowned or unmade, and three of them have been carried ≥ 2 sprints** (D6(ii), D3, bv-009/TD concurrence, hardware class, VSync) | **High** | Medium | Every one is surfaced below with options and a recommendation. **This project's own evidence is unambiguous: every slip has come from a blocked decision, never from capacity** (milestone Cut-Lever anti-signal). Two Should/Nice items are gated on rulings this sprint and will simply not happen without them. |
| **Criterion #6 will be code-complete but human-unobservable after S11** — the bed is placeable by a hosted tool but has **no view** | **High** | Medium | Stated honestly in the advancement map rather than claimed as met. F7 is recorded under Missing Stories with a named owner path. **This is also the gating reason R8 slips to S12** — surfaced, not silently absorbed. |
| **Criterion #13 has no story and two unowned decisions, for the FOURTH consecutive sprint** | **High** | Medium | Escalated again as **E1**. **Protected criterion — it cannot be traded on the cut lever**, so an unowned decision converts one-for-one into milestone risk. `vox-018`'s tool is reusable verbatim (windowed, culling ON, VSync OFF). |
| **Multi-lane work in one tree produces misleading red runs** (measured in S10 — a correct change was reverted on a foreign-state red) | Medium | Medium | Named as a working rule on the Critical Path: **re-run in isolation before reverting.** Lane C's five serial stories make this the most likely sprint yet for a recurrence. |
| **The recurring build-validation fixture trap** — sealing a gap with a solid block creates a legal step-up and reopens the escape (hit 4× across S09–S10) | Medium | Low-Med | Lower exposure this sprint (no new build-validation fixtures scheduled), but `rid-009`'s re-verification of `bv-006`/`bv-008` touches those fixtures. **Assert the seal is still sealed after any sealing write.** |
| **Godot 4.7 API deviations beyond the LLM cutoff** — `scene-007` and `building-ui-001` are both in post-cutoff-change domains (scene hosting, Control/CanvasLayer/theming) | Medium | Low-Med | Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01, S09 and S10. |
| **Recurring typed-Array crash class** (0 occurrences S1–S10) | Low | Low | Regression call retained in the E2E gate. |

## Dependencies on External Factors

- **USER RATIFICATION of the two pre-flight ruling documents** —
  `production/architecture-decisions-m02-preflight-2026-07-26.md` and
  `production/creative-decisions-m02-preflight-2026-07-26.md`. Outstanding since 2026-07-26, **third
  sprint**. Not schedulable work — this is a signature.
- **USER RULING on D6(ii)** — cross-GDD authority for `needs-mood-009`'s repo-wide sweep. Decides
  whether criterion #4 closes this sprint or slips again.
- **USER RULING on D3** — Cluster D's committed scope (25 stories vs the milestone's assumed ~14).
  Decides what the S12 cut-lever checkpoint is even measuring.
- **TD concurrence on CD Ruling 2's implementation form** — gates `bv-009` and therefore criterion
  #7. Second sprint outstanding. Carries the measured `@export RefCounted` collision.
- **TD ruling on HUD hosting (building-ui KC1/KC3)** — gates `building-ui-001`. ⚑ **It is the same
  architectural question `scene-007` answers for the tool tier — decide once, apply twice.**
- **TD decisions: target hardware class + VSync mode** — both unowned, both blocking criterion #13's
  story from being authored. **Fourth sprint carrying this.**
- **TD decision on `bv-010`'s corpus density** — carried. The S09 `nav_region_size` 200→40 retune
  (6697.6 ms → 266.6 ms per seed) means higher density may now be nearly free; nobody has re-measured.
- **CD sign-off** — a **written, dated close entry** on the "world lacks life" finding once
  `presentation-001` Sub-B lands (criterion #9). Not implied by a green suite.
- **Art hand-off for `rid-009`'s four `visual_asset` meshes** + the magenta `missing_item` placeholder
  material. Primitive placeholders in the Visual Direction Note colours are sufficient for both
  `rid-009` and `rid-006`.
- **Control-manifest version 2026-07-23** — every S11 story embeds it. Confirmed current S1–S10;
  re-confirm unchanged before the lanes start. Owner: technical-director.

## Definition of Done for this Sprint

- [ ] **G1 closed before the first `/dev-story`**: `production/qa/qa-plan-sprint-11-2026-07-28.md`
      exists (sign-off condition #3 — **a gate, not a line item, this time**)
- [ ] **G2 closed before lane C reaches it**: `scene-007`'s story file authored from building-ui KC3
      + ADR-0005, with nothing invented, and `/story-readiness` run against it
- [ ] All Must Have stories completed — **`res://data/items/` exists with four valid entries and the
      player can tear down what they built**
- [ ] Every Logic story (`rid-007`, `rid-008`, `rid-006`, `building-009`, `012`, `015`, `017`, `031`,
      `villager-ai-019`, `013`) has a passing GdUnit4 headless unit test under
      `neues-spiel/tests/unit/…` — **BLOCKING**
- [ ] Every Integration story (`scene-007`, `presentation-001` Sub-B) has a passing headless test
      under `neues-spiel/tests/integration/…` — **BLOCKING**
- [ ] **`rid-009` content smoke Smoke-1..4 pass against the SHIPPED data** and are recorded in the
      consolidated smoke artifact — **BLOCKING**
- [ ] **`build-validation-006`'s `is_need_functional(&"bed")` TRUE branch is re-verified
      non-vacuously against the real authored `ItemDefinitionResource`** — the existing
      `test_is_need_functional_unknown_id_returns_false_without_error` becomes a genuine two-branch
      test. **BLOCKING — this line was marked BLOCKING in S10 and was NOT met** (sign-off §4.1)
- [ ] **`build-validation-008`'s bed Warning tier fires end-to-end against the real bed** —
      **BLOCKING** (sign-off §4.4)
- [ ] **`building-017` re-verifies `needs-mood-010`'s bed-revocation edge case against a REAL
      demolition job** (not a directly-fired `furniture_revoked`) — **BLOCKING; this is D8 option
      (c)'s owed follow-on AC and the reason the crown was allowed to ship in S10**
- [ ] **`scene-007`'s non-vacuity is PROVEN by deletion**: the hosting call removed once, the observed
      failure recorded in the commit body — **BLOCKING** (the `scene-006` discipline)
- [ ] **`bv-007`'s tick-source production-wiring guard added** (~0.1 day, `ai-programmer`) — sign-off
      §4.3; do not let it lapse a second time
- [ ] **A lone `bed.tres` is never committed** — the three tier-0 materials land first (F2); any
      intermediate commit must boot green
- [ ] Grep guards green: HUD writes no simulation state (if `building-ui-001` lands); undo never
      mutates a Built cell; zero mood references in work/scheduling code; zero `SceneTree.paused` /
      `Engine.time_scale`; `_visual_position` call-site allowlist
- [ ] **Any red suite run on lane C is re-run in isolation (clean stash / separate branch) before any
      change is reverted on its basis** (S10 §5 process finding)
- [ ] Full blocking suite green **headless with zero orphans on every story commit**; **E2E LOOP green
      on every commit**
- [ ] All engine APIs confirmed against `docs/engine-reference/godot/` — **BLOCKING**
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit
      tests). ⚑ **Exception to name explicitly: `rid-009` is a content story — its smoke check reads
      shipped `.tres` files by design; keep that in the smoke artifact, not in the unit suite**
- [ ] **Any story added to S11 after this plan is written is entered in `sprint-status.yaml` AND
      re-checked against the QA plan before sign-off** (S09 condition #2, carried)
- [ ] **A single consolidated `production/qa/smoke-sprint-11-*.md` exists at hand-off** — produced at
      hand-off, not reconstructed from the last story's evidence doc
- [ ] **`/team-qa sprint` sign-off report exists: APPROVED or APPROVED WITH CONDITIONS** —
      `production/qa/qa-signoff-sprint-11-*.md`. Milestone criterion #14
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR/registry docs updated for any deviation
- [ ] Code reviewed and merged (trunk-based)
- [ ] **End-of-S11 review: the milestone's Cut-Lever Checkpoint #2** (Producer + CD + TD). ⚑ **The
      signal is "criterion #5 still not green" — and criterion #5 IS green (S10). The lever
      therefore does NOT pull at this checkpoint. Record that affirmatively in the review** rather
      than letting silence imply a trim, exactly as the S10 plan asked. The *separate* Cluster D
      signal fires at the **start of S12**, not here — see D3.

## Open Decisions Surfaced by This Plan (producer → user)

Surfaced, not resolved. **D9 is new and it is the one that changes this sprint's shape.**

### D9 — ⚑ NEW: the fourth ship-green-and-uncalled is a whole subsystem. Do we schedule the hosting story?

Verified, not inferred: `Valley.tscn` hosts 12 modules; **`BuildEditorMode`, all four block tools,
`FurnitureTool`, `GhostPreview`, `UndoRedoStack` are in no scene, and `BuildProjectRegistry` /
`ConstructionJobQueue` are constructed nowhere in `src/`.** building-ui's Known Conflict 3 recorded
this on 2026-07-26 and it survived `building-001` landing. The S10 sign-off asked whether a fourth
occurrence would land outside the boot-invariant guard's reach. It has — and it is not one API, it is
the entire build-interaction tier.

- **(a) Author `scene-007` and schedule it as a Must** *(this plan's choice)*. Cost: one story plus a
  producer authoring gate, and lane C goes to depth 5. Benefit: the C1 chain gets a real caller,
  `rid-009`'s bed becomes placeable by a human, `building-ui-003/004/005/011` lose their KC3 blocker,
  and the pattern the sign-off named three times stops at three.
- **(b) Ship the C1 chain and `rid-009` without hosting, record the debt.** Cost: five demolition
  stories and a real bed all ship green with **zero production callers** — the exact defect class this
  project has now hit three times, at four times the scale. Benefit: lane C drops to depth 4.
- **(c) Do hosting FIRST and defer part of the C1 chain to S12.** Benefit: the safest ordering — every
  demolition story would land against a hosted tool. Cost: D8 option (c) promised the full C1 chain as
  S11's opener; this partially breaks that commitment, and criterion #11 slips.

**Producer recommendation: (a).** Hosting is the cheapest possible insurance against the project's
most-repeated defect class, it is the one story that converts three separate in-flight deliverables
from "green" to "actually reachable by a player", and it sits at the *end* of lane C where a slip
costs one story rather than four. **This is your call.**

### D6(ii) — `needs-mood-009` contradicts itself on cross-GDD authority (blocks criterion #4)

**F8, verified in the story file:** its 5th AC requires the sweep to correct `building-system.md`'s
`base_build_ticks` and **both** `base_demolition_ticks` mirrors; its Dependencies section says
*"Coordinate (do not edit from here): `design/gdd/building-system.md`'s F3 variable table and both
`base_demolition_ticks` mirrors ... are in the sweep's scope but not this epic's ownership."* Same
document, opposite instructions. This is not tidiness — it is why the story has now been deferred
twice.

- **(a) Grant `needs-mood-009` repo-wide, annotation-only authority** *(recommended)*. The story
  already carries a hard guard — *"No `.tres` edit, no AC anchor move, no test edit. If this story
  produces a config diff, the ruling was not followed"* — which makes the blast radius of a wrong
  edit **provably nil**: it can only change comment text. Amend the Dependencies line to match the AC.
- **(b) Split into `nm-009` (needs-mood only) + a separate repo-wide sweep task** owned by
  game-designer. Cost: **re-creates the exact "miss an occurrence" trap the widened AC exists to
  prevent** — the CD's own stated reason for widening it was *"otherwise this bug keeps surfacing one
  GDD at a time for another three sprints."* Two sprints of that prediction have already elapsed.
- **(c) Defer again.** Criterion #4 slips to S12 for the third time, and every stale `at 1x`
  annotation stays in the docs a human reads while playtesting.

**Producer recommendation: (a).** One sweep, one change, one rationale artifact, zero value edits.

### D3 — Cluster D is 25 stories, the epics now EXIST, and the S12 lever fires on it

**Correction to a stale carry-forward:** the S10 sign-off lists *"the Cluster D UI epics — still no
epics created"*. **False as of 2026-07-27** — `production/epics/building-ui/` (EPIC.md + 18 stories)
and `production/epics/villager-info-ui/` (EPIC.md + 7 stories) all exist at `Status: Ready`. The R2
gate is closed. villager-info-ui's Known Conflict 1 (the villager body / collision-layer decision) was
**closed by `presentation-003`** landing in S10.

What is still open is the **scope** question, and it is now one sprint from being decided *for* you:
25 stories against the milestone's assumed ~14, with the cut-lever's step 4/5 ("reduce both UIs to
minimum viable") firing at the **start of S12** if Cluster D has not started. This plan puts
`building-ui-001` in as a **Nice** — the single story that makes "started" honest — but a Nice is by
definition the first thing trimmed.

- **(a) Commit to ~16 CORE Cluster D stories now**, pre-declaring the polish tail (building-ui
  `012`–`018`, villager-info-ui `005`–`007`) out of MVP. Deciding *now* beats deciding at S12 because
  it changes what S12 is planned around.
- **(b) Reduce both UIs to minimum viable now** — need bars + mood band + why-string; tool palette +
  ghost feedback + project state. Effectively pulling lever steps 4–5 voluntarily, a sprint early,
  while it is still a choice rather than a signal.
- **(c) Leave it and let the S12 checkpoint decide.**

**Producer recommendation: (a)**, and **promote `building-ui-001` from Nice to Should** if you take
it — the commitment and the first story should land together. Note also **D1** (unchanged, now one
sprint from mattering): `building-ui-011`'s Projects Panel routes intents through `pause_project`
(`building-006`, C3) and `queue_demolition` (`building-010`, C4), neither of which exists, and the
lever trims C4/C3 *before* Cluster D — so pulling it as written ships a panel displaying a lifecycle
the player cannot drive. Producer recommendation stands: **scope `building-ui-011` render-only**.

### D4 / E1 — Criterion #13 is protected, unowned, and story-less for the FOURTH sprint

**Target hardware class** and **VSync mode**, both technical-director, both still "Not started" /
"Unowned"; the measurement story does not exist (voxel-world ends at `story-021`). Criterion #13 is
**never on the cut lever**, so an unowned decision here cannot be traded away — it converts one-for-one
into milestone risk, and M02 has two sprints left in its plan. `vox-018`'s tool is reusable verbatim.
**Recommendation: assign the hardware-class call this sprint so the story can be authored for S12.**
This is the fourth consecutive sprint making this request.

### D5 — Villager names: a tone call, now actively blocking

`VillagerAi` carries only `villager_id: int`. `villager-info-ui-003`'s own Dependencies name **Known
Conflict 2 — the villager-name ruling (creative-director)** as a hard gate. Villagers now have visible
bodies and will have clickable panels the sprint after next. **"Hilda" and "Villager #3" are different
games.** Creative-director tone decision, not an engineering default.

## Notes

- **Dependencies-satisfied check:** every S11 story was verified against its **own story file's
  `## Dependencies` section**, not against an epic or milestone summary table.
  `rid-007` → 003 ✓/005 ✓; `rid-008` → 001 ✓/004 ✓; `rid-009` → 001 ✓/003 ✓/004 ✓/005 ✓ + 007, 008
  (in-sprint — **its own "all DONE" claim was wrong, F1**); `rid-006` → 004 ✓ (+ ordering constraint
  on 009, F3); `building-009` → 002 ✓; `building-012` → 002 ✓/009 (in-sprint)/**011 ✓ (F4)**;
  `building-015` → 002 ✓/009/012 (in-sprint) — **031 is NOT a dependency (F5)**; `building-017` →
  016 ✓/009/015 (in-sprint); `building-031` → 021 ✓/029 ✓; `villager-ai-019` → 006 ✓/007 ✓;
  `villager-ai-013` → 004 ✓/006 ✓; `presentation-001` Sub-B → villager-ai-019 (in-sprint) +
  presentation-003 ✓; `needs-mood-009` → 002 ✓/003 ✓/005 ✓/008 ✓ + **D6(ii) external**;
  `building-ui-001` → building-001 ✓ + **TD hosting ruling external**.
  **14 of 15 scheduled story files EXIST and read `Status: Ready` on disk (verified 2026-07-27).**
  The fifteenth, `scene-007`, does not exist and is listed under Missing Stories with a named author
  and a day-one gate — it is not fabricated.
- **Three dependency defects and two stale carry-forwards were found by that check** (F1, F4, F5;
  plus the stale "no Cluster D epics" claim and the stale D8 chain length). **This is the third
  consecutive sprint where reading story headers rather than tables changed the plan** — S09 found
  the `building-012` inversion, S10 found `needs-mood-010`'s self-contradiction, S11 finds `rid-009`'s
  false "all DONE" line.
- **Two findings came from reading SOURCE, not stories** (F6 tool hosting, F7 no furniture view), and
  both changed the plan materially: F6 added a Must story, F7 deferred the external playtest. The
  lesson generalises: **story files describe intent; only the scene tree and the module list describe
  what the player can reach.**
- **The cut lever is NOT pulled by this plan.** Checkpoint #2 fires at the end of S11 and its signal
  is *"criterion #5 still not green"* — criterion #5 is green. **Record the non-pull affirmatively.**
  The Cluster D signal is separate and fires at the start of S12.
- **Velocity:** 9 Must + 4 Should + 2 Nice = **15 stories**, against a measured band of 8–18
  (S1–S10: 8, 9, 9, 8, 8, 13, 12, 13, 18, 14). Max Must lane **5.0** of 8 available; full set takes
  the longest lane to 6.0. **Buffer pre-committed to two named consumers** (`rid-009`'s first-ever
  shipped-data boot exposure, `scene-007`'s authoring unknown) rather than held vague — the practice
  that has now worked three sprints running.
- **We will know this sprint was scoped right if:** `res://data/items/` boots green on the first
  honest attempt with all four entries; `shelter_classification_test.gd` stops asserting
  `is_need_functional(&"bed") == false` and starts asserting both branches; `building-017`'s
  re-verification of the crown's revocation case passes against a real demolition job **without
  relaxing the assertion**; `scene-007`'s deletion probe produces a real, recorded failure; and the
  end-of-S11 checkpoint is a review that **affirmatively records the lever staying unpulled**.
- **Next step:** run **`/qa-plan sprint` (G1)** and **author `scene-007` (G2)** — both before any
  `/dev-story`. Then start `rid-008` + `rid-007` (lane R), `building-031` (lane R2) and
  `building-009` (lane C) **in parallel on day one**; all four are blocked on nothing.

---

## Sprint Result — CLOSED 2026-07-27

> **Counting method, stated because this project got it wrong once.** Every figure below was counted
> from `production/sprint-status.yaml` **and** from each story file's own `Status` line, read
> independently on disk. Nothing here is taken from a narrative or a commit message's own summary.
> Sprint 10's Result claimed 16/16 when the truth was 14/16, and the QA sign-off caught it.

**18 of 20 tracked stories complete.**

- **15 planned. 13 landed.**
- **2 did not land, and both are decision-blocked, not capacity-trimmed:** `needs-mood-009` (waiting
  on **D6(ii)**, the cross-GDD authority ruling — third sprint) and `building-ui-001` (waiting on the
  **TD HUD-hosting ruling** — second sprint). Neither was trimmed. Both sat idle with capacity
  available. **This distinction is load-bearing at the S12 checkpoint** — see the Cluster D reading
  below.
- **5 were added mid-sprint and all 5 landed:** `cam-013`, `presentation-004`, `villager-ai-022`,
  `scene-008`, `build-validation-009`.

**Suite: 1383 → 1541 (+158).** Verified on a clean single run: 1541 cases, 0 errors, 0 failures,
0 flaky, 0 skipped, **0 orphans, exit 0**.

### Three of the eighteen are complete-but-qualified. Named, not averaged in.

| Story | What is actually true |
|---|---|
| **`building-031`** | Closed as **absorbed by `building-015`**, verified AC-by-AC (commit `8a12604`). Its ACs are covered; **it shipped no distinct code of its own.** Counted complete because the acceptance criteria are met, named here because "18" would otherwise imply eighteen separate deliverables. |
| **`presentation-001` Sub-B** | Landed **with a flagged scope gap**. The art bible also names *"glancing at an unfinished build"* and *"brief exchanges between bonded villagers"*. Neither has any FSM state behind it — **no build awareness and no bond concept exist in the simulation** — and inventing them would be new simulation, which the story forbids itself. Recorded in the story file as a decision owed to producer/CD, not quietly dropped. ⚑ **Separately: the story file's own `Status` header was never updated** — it still reads *"Sub-scope A Complete (2026-07-24) … Sub-B awaits villager-ai-019"*. The yaml and the file disagree. Fix at S12 planning. |
| **`presentation-004`** | **AC3 (art-director sign-off on the shipped 0.95 energy / 0.28 ambient) is deliberately OPEN.** The values ship provisional and are overturnable by a `.tres` edit. It also carries a **recorded deviation**: the anti-vacuity lever asked for luminance measured on **rendered** output; what shipped is a computed Lambertian estimate. It was shown to discriminate (shipped values inside the band, the art bible's 1.7/0.5 over the top, near-zero under the bottom), but it is **not what was written**, and the rendered proof is still owed. |

### ⛔ A DoD line this sprint set for itself and then broke

The plan's own DoD reads: *"Any story added to S11 after this plan is written is entered in
`sprint-status.yaml` AND re-checked against the QA plan before sign-off (S09 condition #2, carried)."*
**None of the five mid-sprint additions was entered in `sprint-status.yaml`** — verified by grep on
2026-07-27; the file's `stories:` block still ends at `villager-ai-013`. The five stories exist on
disk, are Complete, and are traceable through git; the *index* is what is wrong. This is the second
consecutive sprint in which a process line was written as a DoD item and nothing gated on it.
**S12 turns the yaml back-fill into a Day-0 gate, exactly as S11 did for the QA plan after S10's
condition #3.**

---

## ⚑ The story of this sprint: nine instances of shipped-green-and-uncalled, six closed in a day

This project's dominant failure mode is not bugs. It is **code that is green-tested, correct, and
never called by the running game.** Sprint 11 brought the running count to **nine**, and closed
**six of them on a single day**.

| # | What was green and uncalled | Found in | Closed by |
|---|---|---|---|
| 1 | `generate_terrain` | pre-S10 | earlier sprint |
| 2 | `spawn_starting_roster` | pre-S10 | earlier sprint |
| 3 | `initialize_villager` (needs-mood-006) — F1 decay iterated nothing, so no villager could ever get tired | S10 | `scene-006` (S10) |
| 4 | **The entire build-interaction tier** — `BuildEditorMode`, `WallTool`, `FloorTool`, `RoofTool`, `BlockTool`, `FurnitureTool`, `GhostPreview`, `UndoRedoStack` in no scene; `BuildProjectRegistry` / `ConstructionJobQueue` constructed nowhere in `src/` | S11 planning (F6) | **`scene-007`** |
| 5 | **`FurnitureRegistry`** — constructed nowhere, so `ConstructionTickLoop.furniture_registry` and `FurnitureBedProvider.furniture_registry` were null in production and **no villager could claim a bed in the shipped game at all** | found while *authoring* `scene-007` | **`scene-007`** (`valley.gd:1005`) |
| 6 | **No `Camera3D` anywhere in the production scene chain.** The world generated, villagers spawned and wandered, the whole build chain was hosted — and **the shipped game rendered nothing to anybody** | S11, by counting the live tree | **`cam-013`** |
| 7 | **No `DirectionalLight3D` and no `WorldEnvironment` anywhere.** The game's only light was the torch | S11 | **`presentation-004`** |
| 8 | **`BuildValidation` constructed nowhere in `src/`** — 0 call sites in `src/`, 16 in `tests/` | S11, from a screenshot | **`scene-008`** |
| 9 | **`VillagerOnSiteGate` + `VillagerSealPreventionGate` constructed nowhere** | S11, same screenshot | **`scene-008`** |

### How they were found matters more than that they were found

**Not one of instances 4–9 was found by a test.** The suite was green at 1383 before this sprint and
green at 1541 after it, and it was green *through* every one of these defects.

- **`cam-013`** was found by **counting nodes in the live scene tree**: *"Counted at runtime, not
  inferred: the live tree reported zero."* It now reports one.
- **`villager-ai-022`** was found by **booting the game and asking where everyone stands.** Two
  villagers spawned; one stood at cell `(0,0,0)` — the far corner of a 2000×2000 world, ~1400 cells
  from the settlement, needs seeded, body attached, deciding and ticking every frame in a place
  nobody would ever look. The commit's own honest note: *"No test could have caught it — every
  placement test builds its villagers on purpose."*
- **`scene-008`** was found by **reading a screenshot against its own report.** `04-built.png` showed
  walls rising **while the villager stood well away from them.** Both work gates defaulted
  *permissively* when unwired, so `ConstructionTickLoop` credited a claimed job every tick whether or
  not the villager had ever arrived.
- **`presentation-004`** was found by noticing that **three separate capture tools each applied the
  art bible's golden-hour recipe themselves.** Every screenshot this project ever produced looked
  lit because *the tool* supplied the lighting — so the product could stay pitch dark indefinitely
  without a single piece of evidence looking wrong.

### The lesson, drawn explicitly

**A passing test proves code is correct. It cannot prove code is reached.** Everything in instances
4–9 was correct. All of it was tested. None of it ran.

Three mechanisms let correctness masquerade as reach, and each has a countermeasure:

1. **Permissive defaults make a missing wire invisible to every query.** Both villager gates returned
   "allowed" when unwired; `BuildValidation`'s bed provider returned `is_bed_sheltered() == false`
   for *every* bed regardless of the room — which meant **Sprint 10's crown, milestone criterion #5,
   was inert in the actual product while its test was green.** A nil-safe default is a decision to
   fail silently. → **Practice change: any injected collaborator whose absence changes behaviour must
   either assert at boot or be listed in the boot-invariant block. Never both optional and
   consequential.**
2. **Dev tools that compensate for a missing product feature hide it forever.** `presentation-004`'s
   AC6 is the part that closes the hole rather than the symptom: **all three capture tools now light
   nothing.** If a capture looks unlit again, that is a real regression in the game. →
   **Practice change: a capture tool may supply nothing the product is supposed to supply — no
   lighting, no cells, no props, no clock. Generalise AC6 to every tool this project ever writes.**
3. **The S10 countermeasure was necessary and insufficient.** S10 chose "a growing boot-invariant
   assertion block, plus the planning habit that every story adding a public API needs a caller story
   in the same sprint." That habit is what produced `scene-007` — it worked. But it caught **none** of
   instances 6, 7, 8 or 9, because those modules added no new API this sprint; they had been quietly
   uncalled for many sprints. → **Practice change: the caller check must run against the *whole*
   module list at sprint planning, not only against stories in the current sprint. Ask "what does the
   live scene tree contain?" — not "what did this sprint add?"**

**The single most valuable practice this sprint, and the one to keep:** every story carried an
**anti-vacuity lever** — a named assertion that *demonstrably fails on today's build*, proven by
deleting the production call and recording the observed failure. `scene-007`'s deletion probe,
`rid-009`'s three pinned-test flips, `villager-ai-022`'s "every villager must stand on a cell the
voxel world calls standable" (which the old build fails at the origin), `scene-008`'s regression *in
the picture*. **That discipline surfaced most of this sprint's real findings and it is mandatory on
every Sprint 12 story.**

Three self-caught test defects are worth recording for the same reason. `scene-008`'s on-site test
first drove a mock clock while the hosted tick loop binds to the real autoload, so progress was
always zero and **the test would have passed against a completely unfixed build** — a vacuous test of
exactly the kind this project keeps hunting, caught by its own author. `build-validation-009`'s
idempotency test roofed only the escape cell and read ROOM because the analysis pass never reseeded
the region. And a grep guard looked for `BuildValidation.new(`, which never appears, because it is
scene-hosted like every other module.

---

## What landed

**The crown — `rid-009`, the project's first authored game content.** `res://data/items/` came into
existence: three tier-0 materials (`wood_block`, `stone_block`, `thatch_block`) plus the `bed`, with
the tier-0 materials committed first so no intermediate commit could halt boot on a family-coverage
gap. `is_need_functional(&"bed")` is now TRUE in production, and the three pinned deliberately-false
assertions Sprint 10 left in the suite were flipped to genuine two-branch tests, with the flip
demonstrated rather than asserted (`production/qa/evidence/rid-009-bed-functional-flip-evidence.md`).

**The reverse verb — the C1 demolition chain, `009 → 012 → 015 → 017`.** Tearing down is a job, not a
delete: worker-executed block demolition with `restore_value` write-back, floor excavation that
remembers what the ground was, a draft eraser that branches on cell micro-state, and furniture
demolition that removes the last instant-removal carve-out. `building-031` was verified absorbed by
`015` rather than duplicated. **`building-017` paid D8 option (c)'s owed follow-on AC**: Sprint 10's
crown proved bed revocation by firing `furniture_revoked` directly; it is now driven by a **real
demolition job completing**, so the crown stops taking its own word for it.

**The build chain became reachable — `scene-007`.** The whole build-interaction tier gained a scene
home, with non-vacuity proven by deleting the hosting call and recording the observed failure.

**The game became something a person can look at.** `cam-013` gave the shipped game a camera (it had
none). `presentation-004` gave the world a sun and an environment (it had neither), as a config
Resource rather than literals, and made all three capture tools stop lighting anything.
`villager-ai-022` stopped a villager from living in the world corner and pinned the count convention:
villager 0 **counts toward** `starting_villager_count` — a configured 1 used to hand the player 2.

**Work stopped being credited to workers who did not show up — `scene-008`.** Three fully-built,
fully-tested classes the running game never constructed are now hosted and wired, with a boot
invariant for all three. The proof is a **regression in the picture**: the same demo now builds
**19 of 30** wall cells instead of 20, because the villager must actually walk there and stay to earn
credit. Less house, more truth.

**The payoff signal finally carries a payoff — `build-validation-009`.** Carried twice from Sprint 10
and delivered: milestone criterion **#7** closes. A `LoopPayoffAdapter` translates the genuine
`room_recognized` and `shelter_status_changed` emissions into real payoff types, non-vacuous by
construction — the crown test boots the real `GameWorld`, forces real chunk residency, writes real
cells, and **does not compile against the pre-story codebase.**

**Life — `villager-ai-019` and `villager-ai-013`.** Idle villagers wander off the existing graph
(never a new pathfinder), and a blocked villager asks the occupant to step aside rather than
freezing. `presentation-001` Sub-B poses the body while wandering, in the real game rather than a
harness.

Also written down for the first time, because two agents hit it independently in one day: **the world
is not empty after boot.** Chunks lazily regenerate real terrain the moment residency is requested,
so tests building geometry against a real booted grid must build above `base_height + amplitude` or
probe for clear cells.

---

## New tooling and evidence — and the honest limit of what it proves

Two capture tools now exist and are the project's primary reach-verification instruments:

- **`neues-spiel/tools/settlement_overview_capture.tscn`** — photographs the settlement through the
  game's own camera and **counts things in the live scene tree**. This is the tool that reported
  `Camera3D nodes hosted by the shipped Valley: 1`.
- **`neues-spiel/tools/payoff_loop_demo.tscn`** — **drives the real shipped build chain end to end.**
  It reads `wall_height` live from the hosted config (never hardcoded), arms only through
  `BuildEditorMode`, commits through `CommitPipeline`, releases into `ConstructionJobQueue`, then
  waits on the real tick loop and a real villager. **It never writes a cell into `VoxelWorldGrid`,
  never supplies its own lighting, never stages a prop.**

It produced `production/qa/evidence/01-before.png` through `05-furnished.png`.

> ### ⚑ Do not overclaim this. The payoff loop is demonstrated as far as *"house built, bed placed."*
>
> **It does NOT prove that the villager claims that bed and sleeps in it.** The tool has no claim
> stage and no sleep stage; it ends after the furniture stage and quits. A villager claiming a bed in
> a room it helped build, and sleeping there, **has never been observed in the running game** — only
> in an integration test. That is Sprint 12's headline.
>
> Two further honesty notes on this evidence. `04-built.png` was **kept as-is rather than re-shot
> after the fix**, because it is a picture of the bug — walls rising while the villager stands away
> from them — and a picture of the bug is worth having. And the tool **stops honestly**: when the
> wait cap hits, it prints that it refuses to fake the rest and **skips the screenshot entirely**
> rather than shoot a room that is not furnished.

---

## ⚑ Open, unresolved, and carried to Sprint 12 — nothing absorbed silently

| Item | State |
|---|---|
| **The 19/30 construction plateau** | Walls plateau at 19/30 for **~180 s**, most likely the villager cycling through seal-prevention refusals as the room closes around it. **Flagged, not investigated.** ⚑ **Producer note added at close:** `villager-ai-016` (seal prevention **and livelock escape**) is **Complete since 2026-07-25** and ships an escape hatch — `abandon_count >= seal_prevention_abandon_limit` flips `allow_write` true. A 180 s stall implies either the escape is not being reached in the shipped game, or the limit is large relative to the demo's cap. **That makes this more interesting, not less. Spike it before anyone reads it as a performance problem.** |
| **The hen-and-egg pacing finding** | The villager gets tired and sleeps **before** the room that would let it sleep well exists. **This is a creative-director question about pacing, not a bug.** Surfaced as a decision in the S12 plan. |
| **Furniture still has no view layer (F7)** | Re-verified on disk at close: `src/presentation/` contains **no furniture presenter** and zero references to furniture. A placed, built bed is still **invisible**. Blocks criterion #6's human-observable half and **R8, the external playtest, for a second sprint.** |
| **Criterion #9 does not close** | `villager-ai-019` and Sub-B both landed, but `production/qa/evidence/ambient-life-wave-1-evidence.md` reads *"awaiting art-director/creative-director review"*. The criterion is met **only on a written, dated CD close entry** — it is now **owed**, and it is a signature, not work. |
| **Criterion #8's four CD advisories** | Still outstanding — and the **golden-hour re-shoot is now mandatory rather than advisory**, because `presentation-004` changed what "lit" means: the tools no longer supply lighting, so every prior golden-hour capture was shot under tool light that no longer exists. |
| **`bv-007`'s tick-source production-wiring guard** | **S11 DoD line, NOT met.** Verified: `build_validation.gd:348` self-wires from `/root/TimeTickSystem`, but that code landed in **S10** (`f61d1b3`), and no guard test pins it. Worse, until `scene-008` landed today, `BuildValidation.setup()` was never called in production at all, so the self-wire never ran in the shipped game either. **Second lapse. Make it a real task, not a folded DoD line.** |
| **`presentation-004` AC3 + its rendered-luminance deviation** | Both open. See the qualified-completion table above. |
| **`presentation-001` Sub-B's scope gap** | Decision owed to producer/CD: accept Sub-B as the two FSM-backed behaviours, or schedule the simulation the other two would require. |
| **`rid-008`'s AC31a** | Shipped "documented as structurally unreachable". **Verify or retire that claim** — an AC that cannot fail is not an AC. |
| **`needs-mood-009` / `building-ui-001`** | Not landed. **Decision-blocked, not capacity-trimmed.** D6(ii) is now on its **third** sprint; the TD HUD ruling on its **second**. |
| **Criterion #13 (mid-range hardware baseline)** | **No story, two unowned TD decisions (hardware class, VSync), for the FIFTH consecutive sprint.** It is a **protected** criterion — it cannot be traded on the cut lever, so an unowned decision converts one-for-one into milestone risk. |
| **Both pre-flight ruling documents** | Unratified for a **fourth** sprint. User-owned. Not schedulable work. |
| **Multi-cell furniture REDO atomicity** | Still no story. Trigger (a second multi-cell item) not met. Correctly deferred. |
| **`sprint-status.yaml` back-fill** | The five mid-sprint additions. Day-0 gate in S12. |
| **Story-file ID collision** | `production/epics/villager-ai-behavior/` contains **two** files numbered `story-022`: `story-022-max-deciding-retune.md` (Not yet created) and `story-022-stray-default-villager-at-world-origin.md` (Complete). Renumber one. |

---

## Cut-Lever Checkpoint #2 — recorded affirmatively

**The lever is NOT pulled.** Its signal is *"criterion #5 still not green"* at the end of S11.
Criterion #5 is **green** (met in S10) — and this sprint went further: `scene-008` revealed criterion
#5 was **inert in the shipped product** (a null validation made `is_bed_sheltered()` return false for
every bed regardless of the room), and fixed it. Criterion #5 is now green *and* live. Recorded
affirmatively rather than left to silence, exactly as the plan required.

### ⚑ The separate Cluster D signal fires at the START of S12 — and it is a genuine producer call

The milestone's lever table says: *"Cluster D has not started by S12 → trim steps 4–5 (both UIs to
minimum viable)."* **Cluster D has not started.** `building-ui-001` was the single story that would
have made "started" honest, and it did not land.

**But the milestone's own anti-signal covers exactly this case:** *"do NOT pull the lever for a sprint
that lands fewer stories than planned for **decision** reasons… every slip on this project came from
blocked decisions, never from capacity."* `building-ui-001` did not land because the **TD HUD-hosting
ruling never arrived** — while `scene-007` answered *the same architectural question* for the tool
tier and landed comfortably. Capacity was not the constraint; it was never close.

**The literal signal and the anti-signal point in opposite directions. That is a decision for the
S12 checkpoint, not something to resolve by reading one clause and ignoring the other.** It is
surfaced as decision **D3** in the Sprint 12 plan with options and a recommendation.

---

## Milestone criteria — S11 movement, counted honestly

| # | Criterion | Movement |
|---|---|---|
| #1 | Build Validation implemented | **9/9 stories** — `bv-009` landed. `bv-006`'s and `bv-008`'s mocked branches became real via `rid-009`. |
| #2 | Reachability corpus ≤ 60 s in CI | **HELD, unchanged.** Still *"5,000-verdict spec not met; the 1,000-verdict shipped configuration is 0/0 disagreement."* Not silently upgraded. |
| #3 | Needs & Mood implemented | MVP-complete since S10. Unchanged. |
| #4 | Real-time-rate pass | **DID NOT CLOSE** — `needs-mood-009` decision-blocked on D6(ii), third sprint. |
| #5 | Payoff loop live-pair | **Green in S10, and made LIVE in the product this sprint** (`scene-008` — it was inert). Its owed debt is **paid** (`building-017`). |
| #6 | Furniture placeable/buildable/claimable | **Code-complete 4/4.** ⚑ **Still human-unobservable**: no furniture view layer exists (F7). |
| #7 | `presentation-002` signals something real | **✅ CLOSES** — `build-validation-009`, carried twice, delivered. |
| #8 | Ambient life wave 1 in the composed Valley | **ADVANCES** (Sub-B). Four CD advisories outstanding; the golden-hour re-shoot is now **mandatory**. |
| #9 | "World lacks life" formally CLOSED by CD | **NOT CLOSED.** Both prerequisites landed; the **written, dated CD close entry does not exist.** Owed. |
| #10 | Building UI + Villager Info UI | **DID NOT START** — `building-ui-001` decision-blocked. See the Cluster D reading above. |
| #11 | Lifecycle breadth — demolition | **✅ CLOSES on code** — `009` + `015` (absorbing `031`) + `017`. Check `building-027`'s remove-mode wording at S12 planning. |
| #12 | Plan-only undo | Met (S10). Redo-atomicity edge still open, trigger not met. |
| #13 | Mid-range hardware baseline | **STILL NO STORY. Fifth consecutive sprint. Protected — this is pure milestone risk.** |
| #14 | `/team-qa sprint` sign-off every sprint | QA plan existed as a **gate** this time and it held. Sign-off + consolidated smoke artifact due at hand-off. |

## Retrospective — what to keep, what to change

**Keep.** (1) The **anti-vacuity lever on every story** — it found more real defects than the test
suite did. (2) **Day-0 gates instead of DoD lines** for anything process-shaped; the QA plan existed
this sprint precisely because it was a gate. (3) **Authoring gates** — `scene-007`'s estimate rose
1.0 → 2.0 *during authoring*, and authoring is where the `FurnitureRegistry` instance was found.
(4) **Reading story headers and source rather than tables** — third consecutive sprint where it
changed the plan. (5) **Publishing the picture of the bug.**

**Change.** (1) The caller check must run against the **whole hosted module list**, not just this
sprint's new APIs — that is what instances 6–9 slipped through. (2) **No optional-and-consequential
collaborators**: assert at boot or list in the boot invariant. (3) **Tools supply nothing the product
should supply** — generalise `presentation-004`'s AC6. (4) **Back-fill `sprint-status.yaml` as a
gate**, since a DoD line has now failed twice. (5) **Stop scheduling decision-blocked stories a third
time** — `needs-mood-009` and `building-ui-001` have now consumed planning attention across three and
two sprints respectively while never being workable. Get the ruling or drop them from the plan.
