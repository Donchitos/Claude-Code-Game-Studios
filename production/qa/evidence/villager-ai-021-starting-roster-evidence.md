# Starting Roster Spawn Evidence — Story villager-ai-021

**Date**: 2026-07-26
**Story**: `production/epics/villager-ai-behavior/story-021-starting-roster-spawn.md`
**Test file**: `neues-spiel/tests/integration/villager_ai/starting_roster_test.gd` (10/10 passing)
**Status**: Advisory companion evidence (QA plan Call-out 4, `production/qa/qa-plan-sprint-9-2026-07-26.md`) —
the headless integration test above is the BLOCKING evidence for this story's
Done status; this document is the human-visible companion the QA plan
additionally requests.

---

## Honest scope note (read before the log below)

This story is the **LOGICAL roster only** (TD ruling VB-1/VB-2 disposition
recorded in `production/architecture-decisions-m02-preflight-2026-07-26.md`):
a villager's visible/rendered body is `presentation-003`'s job, scheduled for
Sprint 10 — no such body exists anywhere in this codebase yet. `VillagerAi`
itself `extends Node` (no `Node3D`, no mesh, no transform). Because of this,
a windowed/GPU screenshot of a booted Valley would show **nothing new** —
the roster's cells are tracked internally (`current_cell`), not rendered.

The QA plan's own companion-evidence checklist (`villager-ai-021`'s entry
under "Manual QA Checklist") asks for "a screenshot of the booted Valley
showing the starting roster... standing on valid ground." That specific
artifact cannot be produced honestly today without either (a) building a
placeholder body — out of this story's explicit scope, delegated to
`presentation-003` — or (b) faking a visual that doesn't reflect real
production state. Per this project's collaboration protocol, this deviation
is flagged explicitly rather than silently worked around: the evidence below
substitutes a **captured console/log run** of the real, production
`Valley.spawn_starting_roster()` method (the same code path the headless test
exercises), which is the closest honest "a human can see the roster exists"
proxy available until `presentation-003` lands a renderable body.

A second, separate, pre-existing gap this evidence also surfaces honestly:
`Valley` still boots with an empty `VoxelWorldGrid` (terrain pages in
asynchronously post-boot, ADR-0015) — there is no world-generation story yet
that calls `spawn_starting_roster()` automatically. The run below simulates
"world generation completes" by filling a small standable plane around the
real world-center cell by hand, exactly as the story's own AC47 wording
("when world generation completes") anticipates a future world-gen story
will do for real.

---

## Methodology

Headless run via `godot --headless --path neues-spiel -s <one-off SceneTree
script>` (not part of `tests/run-tests.cmd` — a manual, one-off evidence
capture, mirroring `villager-ai-stress-evidence.md`'s own "advisory, not a
test-suite member" precedent):

1. Boot a real `GameWorld` + `Valley` through the ADR-0005 gate (a
   `MockResourceItemDatabase` configured Ready-immediately — the same
   boot-gate fixture `world_root_valley_attach_test.gd` already establishes).
2. Read `Valley.get_voxel_world()`'s own real, hosted `VoxelWorldGrid` and
   fill a 21×21 flat standable plane centered on
   `VillagerRosterSpawner.world_center_cell(...)`.
3. Assign a fresh `VillagerAIConfig` with `starting_villager_count = 5`
   (Vertical Slice tier) to `Valley.villager_ai_config`.
4. Call the real `Valley.spawn_starting_roster()` and print every returned
   villager's id/state/cell/standability/setup status.

## Captured output

```
World center cell: (1000, 8, 1000)
Pre-existing default villager (villager_id 0): state=DECIDING current_cell=(0, 0, 0)
spawn_starting_roster() returned 5 villagers:
  villager_id=1 state=DECIDING current_cell=(1000, 8, 1000) is_standable=true is_set_up=true parent=Valley
  villager_id=2 state=DECIDING current_cell=(999, 8, 999) is_standable=true is_set_up=true parent=Valley
  villager_id=3 state=DECIDING current_cell=(999, 8, 1000) is_standable=true is_set_up=true parent=Valley
  villager_id=4 state=DECIDING current_cell=(999, 8, 1001) is_standable=true is_set_up=true parent=Valley
  villager_id=5 state=DECIDING current_cell=(1000, 8, 999) is_standable=true is_set_up=true parent=Valley
Valley child count: 16
get_villagers() total (default + spawned): 6
```

## Reading the result against AC47

- **"Exactly N villagers exist at valid standable cells near the world
  center"**: `spawn_starting_roster()` returned exactly 5 (the configured
  `starting_villager_count`), every one `is_standable == true`, all within a
  handful of cells of `world_center_cell` (nearest-ring-first, the exact
  center cell itself won ring 0).
- **"Each spawned villager begins in Deciding with a well-formed
  `current_cell`"**: every villager reports `state=DECIDING`,
  `is_set_up=true`, and a `current_cell` matching its assigned standable
  placement (never `(0,0,0)`/unset).
- **Growth beyond the starting roster is not implemented here**: confirmed
  separately by this story's own test
  (`test_valley_spawn_starting_roster_has_no_growth_bookkeeping_of_its_own`)
  — no arrival/recruitment logic exists anywhere in `VillagerRosterSpawner`
  or `Valley`.
- The pre-existing single default villager (`villager_id 0`, predating this
  story) is visibly UNCHANGED (`current_cell=(0,0,0)`, its own historical
  placement) — confirming this story's roster capability is additive, not a
  replacement, exactly as documented in `Valley`'s own class doc comment.

## Known follow-up (not this story's scope, flagged for the parent/producer)

`Valley.spawn_starting_roster()` is deliberately **not** wired into `_ready()`
— see `Valley`'s own class doc comment (mirrors the pre-existing
`VillagerNavGraph.build()` deferral: the world has no terrain resident yet at
the synchronous boot instant, ADR-0015's async chunk paging). A future
world-generation story is the natural call site (exactly like
`VillagerNavGraph.build()`'s own already-reserved slot). Until that story
lands, a real booted Valley still shows only the one pre-existing default
villager — the roster capability is real, tested, and production-ready, but
not yet automatically triggered.
