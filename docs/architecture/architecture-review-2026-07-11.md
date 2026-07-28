# Architecture Review Report

- **Date:** 2026-07-11
- **Mode:** `/architecture-review` (full)
- **Engine:** Godot 4.7-stable
- **GDDs Reviewed:** 11 (all approved MVP)
- **ADRs Reviewed:** 13 (all `Proposed`)
- **Engine specialist consulted:** `godot-specialist` (second-opinion pass complete)

---

## Verdict: CONCERNS

Coverage is complete and internal consistency is strong — all 13 architecture-worthy
decisions the master `architecture.md` called for exist, each addresses its mapped
requirements, the dependency graph is acyclic, and every ADR targets Godot 4.7 with no
deprecated-API use. It is **not a PASS** because **nothing is `Accepted` yet**, three ADRs
are explicitly **provisional pending a performance spike that has not run**, and there are
five should-fix defects. It is **not a FAIL** — there are no coverage gaps and no blocking
cross-ADR conflicts.

---

## Traceability Summary

The `tr-registry.yaml` was an empty template at review time, and **the GDDs contain no
TR-ID labels at all** (verified by grep — zero `TR-` occurrences across `design/gdd/*.md`).
The TR-IDs referenced throughout the ADRs and `architecture.md` are an
architecture-session construct that was never written back into the GDDs. `architecture.md`
recorded an approved interpretive call: of ~349 technical requirements, ~295 are fully
GDD-specified (covered by GDD + architecture Module Ownership, no ADR needed) and ~54
represent genuine open decisions clustered into 13 ADRs. **All 13 ADRs now exist.**

Total ADR-worthy clusters: 13 — **Covered: 13 · Partial: 0 · Gaps: 0** (plus 1 phantom-TR note).

| # | Required ADR (from architecture.md) | File | Mapped TR cluster | Status |
|---|---|---|---|---|
| 1 | Inter-System Reference & DI | adr-0001 | building-ui-038, villager-info-ui-023, villager-ai-016, resource-item-db-007, needs-mood-025 | Covered |
| 2 | Tuning/Config Data Strategy | adr-0002 | swm-030, voxel-023, camera-019, time-tick-020, building-038, building-ui-037, needs-mood-020, build-val-016 | Covered |
| 3 | Voxel World Rendering | adr-0003 | voxel-025/017/018, building-002/026/003/035/039/041, villager-info-ui-014/015 | Covered |
| 4 | Physics Backend & Picking | adr-0004 | villager-info-ui-014/015/016 | Covered (see phantom-TR note) |
| 5 | Boot Sequencing & Init Gate | adr-0005 | swm-004/023, resource-item-db-019, building-ui-008 | Covered |
| 6 | Data Immutability & Ref Format | adr-0006 | resource-item-db-010/023 | Covered |
| 7 | AI Pathfinding & Room Analysis | adr-0007 | villager-ai-009/010/011/035/036, build-val-008/009/019 | Covered |
| 8 | Villager AI Execution/Threading | adr-0008 | villager-ai-013/041/047 | Covered |
| 9 | Deterministic Movement/Occupancy | adr-0009 | building-040, villager-ai-046 | Covered |
| 10 | Cross-System UI/World Input | adr-0010 | camera-020, building-ui-028/029, villager-info-ui-002 | Covered |
| 11 | UI Timer/Expiry Pattern | adr-0011 | building-ui-014/015/018/040 | Covered |
| 12 | Save/Load Serialization | adr-0012 | voxel-021, building-023/033, villager-ai-027, needs-mood-026..029, swm-013/024 | Covered (VS-tier) |
| 13 | Multi-Scene Concurrency | adr-0013 | swm-033 | Covered (VS-tier) |

### Phantom-TR note (not a coverage gap)

`architecture.md:435` maps `TR-camera-input-010` to the physics ADR, but that ID appears
in **no** ADR's addressed section and does **not** exist in `camera-input.md` (that GDD
specifies native `project_ray_origin`/`project_ray_normal` at lines 178–179 with no TR-ID
labels). During the ADR-0003/0004 rescope, block-picking moved to ADR-0003 and villager-hit
to ADR-0004; the underlying ray-projection requirement **is** covered (ADR-0003's DDA
picking consumes Camera & Input's `world_ray`). Drop or reconcile this phantom ID when the
TR registry is populated.

---

## Cross-ADR Conflicts

**No blocking conflicts.** The ownership handshakes most likely to collide were verified as
consistent:

- **Picking vs. physics layers** (ADR-0003 ↔ ADR-0004): 0003 claims block-picking touches
  zero physics layers; 0004 gives villagers Layer 1 for `Area3D` ray hits. Structurally
  separate by construction — mutually reinforcing.
- **Boot gate in `GameWorld._ready()`** (ADR-0005 ↔ ADR-0001): 0001 forbids relying on
  `_ready()` order for *code-assigned* wiring and mandates explicit `setup()`. 0005 puts the
  gate in `GameWorld._ready()` — the root, whose `_ready()` runs last (bottom-up tree), so
  children exist and scene-file exports are populated by then. Valid.
- **Occupancy model** (ADR-0008 ↔ ADR-0009): 0008 avoids threading *because* occupancy is
  not thread-safe; 0009 makes discrete `current_cell` the sole authority with synchronous
  `cell_changed`. Reinforcing.
- **Save format divergence** (ADR-0012 vs ADR-0002/0006): 0012 deliberately uses
  `FileAccess.store_var` dictionaries instead of `.tres`, explicitly reconciled as a
  different data category. Not a conflict.

### Minor consistency / staleness defects (should-fix, non-blocking)

1. **ADR-0002** still calls the Boot Sequencing ADR "not-yet-written" — it now exists as
   ADR-0005. Stale cross-reference.
2. **ADR-0004** internal contradiction: header says specialist validation is *pending*, but
   the Consequences section contains a *completed* 2026-07-11 validation. Its H1 title
   ("…Villager Hit-Testing Strategy") also differs from its filename and from how ADR-0003
   refers to it.
3. **`architecture.md` API Boundaries is now stale**: ADR-0005 adds a `RID.validation_complete`
   signal and ADR-0006 fixes `get_by_id()`'s return type to `ItemDefinition` — neither is
   reflected in the master doc's API section yet. Both ADRs flag this as a pending edit.

---

## ADR Dependency Order

Acyclic — no cycles, no dangling references. Topologically sorted:

```
Foundation (no deps):     ADR-0001, ADR-0003, ADR-0010, ADR-0011
Depends on Foundation:    ADR-0002(→1), ADR-0004(→3), ADR-0005(→1), ADR-0007(→3), ADR-0012(→1)
Second tier:              ADR-0006(→2), ADR-0008(→7), ADR-0009(→7)
Third tier:               ADR-0013(→3,4,7)
```

**Central gating fact:** all 13 ADRs are `Proposed`. Per `docs/CLAUDE.md`, any story
referencing a `Proposed` ADR is auto-blocked. Every dependency edge points to an un-Accepted
ADR. Expected for a first architecture pass, but no implementation can begin until the Accept
step runs — already a condition of the TD sign-off in `architecture.md`.

**Spike-gated provisional ADRs:** ADR-0003, ADR-0007, ADR-0008 are marked *PROVISIONAL
pending the pre-VS 30-villager performance spike* (Open Question QQ3). These three cannot move
to `Accepted` until that spike runs. As the rendering / pathfinding / AI-execution keystones,
the spike is the true critical-path item, not the ADR authoring.

---

## Engine Compatibility

Uniform Godot 4.7-stable across all 13 ADRs. No deprecated APIs used (`duplicate_deep()`
referenced but deliberately avoided; `FileAccess.store_*` 4.4 void→bool change accounted for
in ADR-0012). Every ADR has an Engine Compatibility section. No cross-ADR post-cutoff
contradictions.

### Engine Specialist Findings (`godot-specialist`)

The second-opinion pass independently confirmed the load-bearing claims — including a live
check that `AStarGrid3D` genuinely does not exist (404), validating ADR-0007's core premise —
and confirmed Jolt-default (4.6+), GridMap `use_collision=false`, `PhysicsRayQueryParameters3D`
defaults requiring explicit `collide_with_areas=true`, the `_input`/`_gui_input`/
`_unhandled_input` dispatch order + `set_input_as_handled()`, and `Camera3D.current` /
`AudioListener3D` / `WorldEnvironment` resource-swap semantics. It also noted that all six
engine-touching ADRs ran a documented validation pass that caught genuine first-draft errors
(ADR-0003 per-cell-vs-octant collision, ADR-0004 missing `collide_with_areas`, ADR-0013
SubViewport-input-isolation myth) — the process working as intended.

### Engine should-fix items (before ADRs move to Accepted)

- **ADR-0009 — pause-glide risk (highest-value catch):** the `_process(delta)` sample labels
  villager visual interpolation "raw-delta." `technical-preferences.md` Forbidden Patterns
  reserves raw delta for camera/UI only; entity motion must use `game_delta`. If
  `_visual_position` advances on raw delta and is not frozen when `game_delta = 0`, villagers
  would visibly glide while paused — a player-visible bug and a direct Forbidden-Pattern
  conflict. Confirm the intra-tick progress term is frozen during pause, or correct the sample.
- **ADR-0013 — float precision at `100_000`:** float32 ULP at that magnitude is ~7.8 mm; the
  ADR never mentions precision. Almost certainly imperceptible for 1-unit voxels, but should
  either explicitly accept the trade-off or drop the offset to `10_000` (still >100× the world
  bound) for near-zero jitter.
- **ADR-0004 — Jolt + `Area3D` ray query:** unverifiable from the reference docs as an absolute
  guarantee (it is the MVP's only physics interaction). De-risk with a 5-minute smoke test once
  the villager scene exists.
- **ADR-0007 — citation trail:** the AStarGrid3D claim checks out, but the cited
  `modules/navigation.md` does not actually cover `AStar3D`; fix the citation for auditability.

### Project-wide watch-items (checklist, not ADR-specific)

- 4.6→4.7 GDScript rule: typed-return overrides now require explicit `return` — add to the
  `godot-gdscript-specialist` PR checklist.
- 4.7 device-ID constants (`DEVICE_ID_MOUSE/KEYBOARD`): standing grep for `event.device == 0`
  before any input story ships (ADR-0010 owns input but never checks `event.device`).
- ADR-0010 scope gap: `building-ui.md`'s keyboard-completion path may touch 4.6's dual-focus
  (keyboard focus), which no ADR covers — extend or add a short note before that story.
- `AudioStreamPlayer` default `area_mask` 1→0 (4.7): note for future Dungeon audio.

---

## GDD Revision Flags (Architecture → Design feedback)

One soft flag — `scene-world-management.md` contains an Open Question assuming "SubViewports
isolate input for free." ADR-0013 verified this is false in Godot (input callbacks dispatch
scene-tree-wide; `SubViewport.handle_input_locally` only affects GUI routing) and chose the
shared-`World3D` model instead. Since it was already framed as an OQ the ADR resolved — not a
load-bearing design rule — this is advisory: update the GDD's OQ to point to ADR-0013's
resolution. **No systems-index Status change warranted.**

---

## Architecture Document Coverage

`architecture.md` is thorough; every MVP system maps to a layer/module with owned/exposed/
consumed surfaces, and no orphaned architecture exists. Two staleness edits are outstanding
(the RID API additions from ADR-0005/0006). No missing systems.

---

## Pre-Gate Checklist (Phase 9)

| Item | Status | Action |
|---|---|---|
| `tests/unit/` + `tests/integration/` | Missing | `/test-setup` |
| `.github/workflows/tests.yml` | Missing | `/test-setup` |
| `design/accessibility-requirements.md` | Missing | `/ux-design` |
| `design/ux/interaction-patterns.md` | Missing | `/ux-design` |
| `docs/architecture/control-manifest.md` | Missing | `/create-control-manifest` |

`/gate-check pre-production` is **not yet available** — test infrastructure and UX/accessibility
artifacts must exist first.

---

## Immediate Actions (highest-impact first)

1. **Run the pre-VS performance spike** (QQ3) — it gates ADR-0003/0007/0008 from
   `Proposed` → `Accepted` and is the real critical path.
2. **Apply the five should-fix patches** (ADR-0009 pause-glide, ADR-0013 precision, ADR-0004
   header/naming, ADR-0002 stale ref, `architecture.md` API sync), then move the six
   Foundation/Core ADRs (0001–0006) to `Accepted`.
3. **Run `/test-setup`** then **`/ux-design`** to clear the pre-gate blockers.

## Rerun Trigger

Re-run `/architecture-review` after the spike resolves the three provisional ADRs and after
each ADR moves to `Accepted`, to confirm coverage and status improve.

---

## Post-Review Patches Applied (2026-07-11)

The five should-fix defects were fixed in this same session, immediately after the review:

1. **ADR-0009 — pause-glide:** clarified in the `_process()` code sample that `_intra_tick_progress`
   is advanced by the tick system (`game_delta`), not by raw-delta `_process`, so villagers do not
   glide while paused; added an explicit prohibition on integrating raw delta into it.
2. **ADR-0013 — float precision:** added a Risks bullet recording the ~7.8 mm float32 ULP at the
   `100_000` offset as a conscious trade-off, with the `10_000` reduction as the zero-cost mitigation.
3. **ADR-0004 — verification contradiction:** header now reflects that `godot-specialist` validation
   was completed 2026-07-11 (matching the Consequences note), including the `collide_with_areas` fix.
4. **ADR-0002 — stale reference:** both "not-yet-written Boot Sequencing ADR" mentions now point to
   the authored **ADR-0005**.
5. **architecture.md — API sync:** RID's API block now lists `signal validation_complete(...)`
   (ADR-0005) and annotates `get_by_id()`'s immutable-view return contract (ADR-0006).

Follow-up patches (2026-07-11, autonomous overnight run — all five original patches
grep-verified as landed first):

6. **Phantom `TR-camera-input-010` dropped** from `architecture.md` item 4 (Must-Have list):
   the registry is now populated and confirms the ID exists nowhere; the underlying
   ray-projection requirement is covered by ADR-0003's DDA picking consuming `world_ray`.
7. **ADR-0003 stale references** (same defect class as patch 4, missed by the review): both
   "not-yet-written '3D Physics Backend…' ADR" mentions (Enables table + Related Decisions)
   now point to the authored **ADR-0004**.

Still open (not doc patches): the pre-VS performance spike (QQ3, gates ADR-0003/0007/0008), the
`Proposed`→`Accepted` transition for all 13 ADRs, and the two remaining pre-gate infrastructure
artifacts (control-manifest.md — blocked on ADR acceptance; tests/ + CI + ux docs landed
2026-07-11, commits bb4bb31 + 031730b).

> **Note on ADR-0004 filename vs title:** the H1 ("…Villager Hit-Testing Strategy") still differs
> from the filename (`physics-backend-picking-strategy`) and from `architecture.md`'s reference name.
> Left as-is deliberately — renaming the file risks breaking the cross-references in ADR-0003,
> ADR-0013, and `architecture.md`. Cosmetic only.
