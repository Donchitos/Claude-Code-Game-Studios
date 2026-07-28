# Story 023: The stray villager at the world corner

> **Renumbered 2026-07-27**: filed as story-022, which collided with the
> pre-existing `story-022-max-deciding-retune.md` from Sprint 9. Renumbered to
> 023. Commits 0e94aa1 and earlier refer to it as villager-ai-022.

> **Epic**: Villager AI & Behavior
> **Status**: Complete (2026-07-27 — 1522/1522 suite green, 0 orphans, parent-verified; live boot reports 1 villager at (998, 6, 1002), none at the origin)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/villager-ai-behavior.md` (Rule 14b — starting roster)
**ADR Governing Implementation**: ADR-0009 (deterministic movement & occupancy ordering) — primary

**Engine**: Godot 4.7-stable | **Risk**: LOW

### How this was found

By running the game and printing where everybody is, via
`tools/settlement_overview_capture.gd`:

```
REPORT — villagers spawned: 2
REPORT — villager at (0, 0, 0)
REPORT — villager at (998, 6, 1002)
```

`Valley.get_villagers()` returns `_villager_ai` — the `VillagerAi` node baked into
`Valley.tscn`, villager_id 0 — followed by everyone `spawn_starting_roster()` placed.
The roster spawner picks standable cells near the world centre, which is why villager 1
stands at (998, 6, 1002). Villager 0 is never placed by anything, so it keeps its
default cell: (0, 0, 0), the far corner of the 2000×2000 world at height zero, roughly
1400 cells from the settlement.

It is not inert. It has its needs seeded (`seed_default_villager_needs()`), it gets a
real body view from `VillagerBodyPresenter`, it counts in `get_villagers()`, and it
decides and ticks like any other villager — in a corner of the map nobody will ever look
at, on terrain that may not even be standable.

Tests never caught it because every test that cares about villager placement constructs
its villagers deliberately. Only booting the real scene and asking "where is everyone?"
surfaces it.

---

## Acceptance Criteria

- [x] AC1: After boot completes, no villager reported by `Valley.get_villagers()` stands
      at cell (0, 0, 0) unless the world centre genuinely is (0, 0, 0).
- [x] AC2: Villager 0 is placed by the same `VillagerRosterSpawner` cell-selection path
      as every other roster member — one placement rule, not two.
- [x] AC3: If no standable cell can be found for villager 0, that is a deterministic,
      logged outcome, never a villager silently left at the origin.
- [x] AC4: `starting_villager_count` remains honest: the number of villagers a player
      ends up with matches the configured count. State explicitly in the story whether
      villager 0 counts toward it — today the shipped game yields count+1 settlers, and
      that discrepancy is part of this bug.
- [x] AC5: A boot invariant is added to Valley's existing assertion block covering AC1.

## Design Note — two candidate shapes

Both are legitimate; the implementer should pick one and record the reason.

1. **Place villager 0 like everyone else.** Smallest change: run the spawner's cell
   selection for it too, before or alongside the roster. Keeps the scene-hosted node,
   which several stories reference as "the always-present default, villager_id 0".
2. **Stop hosting a default villager in the scene.** Cleaner conceptually — the roster
   spawner becomes the only way a villager comes into being — but touches every story
   that assumes `_villager_ai` exists from boot (needs seeding, body presenter, the
   `seed_default_villager_needs()` call site, and Valley's own module wiring).

Shape 1 is the recommendation on scope grounds. Shape 2 is the better architecture and
should be raised with the technical director if the assumption is cheap to unwind.

## Anti-Vacuity Lever

Assert on the real booted scene, not on a hand-built villager: after `GameWorld` reaches
ACTIVE, every villager in `Valley.get_villagers()` must stand on a cell the voxel world
reports as standable. On today's build villager 0 fails that at (0, 0, 0).

## Out of Scope

- Changing `starting_villager_count`'s value (a balance call).
- Any change to how the spawner chooses cells; this story reuses it, it does not retune it.

## QA Test Cases

**AC1/AC5 — nobody is left at the origin**
- Given: the real `game_world.tscn` booted to ACTIVE with world generation run.
- Then: no entry of `get_villagers()` reports cell (0, 0, 0).

**AC2 — one placement rule**
- Given: boot complete.
- Then: every villager stands on a cell the voxel world reports standable, and all of
  them lie within the spawner's search radius of the world centre.

**AC4 — the roster count is honest**
- Given: `starting_villager_count = N`.
- Then: `get_villagers().size()` equals the documented expectation, and the story states
  which convention was chosen.

---

## Closure Note (2026-07-27)

Shape 1 taken as recommended: villager 0 is now placed through the same
`VillagerRosterSpawner` cell-selection path as every other roster member, via a
shared `place_villager_at_cell()`. The scene-hosted node stays, so every story
that references "the always-present default, villager_id 0" keeps its contract.

COUNT CONVENTION (AC4) — villager 0 COUNTS TOWARD `starting_villager_count`.
Chosen because TR-villager-ai-behavior-065 reads "this system places
`starting_villager_count` villagers" — a total, not an addition to a
pre-existing one. This is also what fixes the reported symptom: the shipped
config of 1 used to yield two settlers, and now yields one.

Proof is on the real booted game, not a fixture:

    settlement_overview_capture: REPORT — villagers spawned: 1
    settlement_overview_capture: REPORT — villager at (998, 6, 1002)

Incidental find, fixed and documented rather than papered over: a test fixture
(`_fill_flat_plane`) wrote a flat plane at a fixed height, which collided with
villager 0's clearance column once villager 0 began depending on real terrain.
The synthetic fill was removed from the `_boot_valley()`-based tests, which no
longer need it.
