# Story 025: A builder always has a way down

> **Epic**: Villager AI & Behavior
> **Status**: Ready — BLOCKING. It is the root cause behind three separate stalls.
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2 days
> **Manifest Version**: 2026-07-27
> **Last Updated**: 2026-07-28

## Context

**GDD**: `design/gdd/villager-ai-behavior.md` (job selection, pathfinding),
`design/gdd/building-system.md` (construction jobs)
**ADR Governing Implementation**: ADR-0007 v1.1 (pathfinding, incl. the scaffolding
amendment) — primary; ADR-0008 (execution), ADR-0009 (deterministic movement, and the
two discrete climb mutations this story is the counterpart to)

**Engine**: Godot 4.7-stable | **Risk**: HIGH

### The finding, in one sentence

**A villager that climbs onto its own work cannot reliably get back down.**

`villager-ai-024` gave builders a way UP — a discrete climb onto the self-sealed cell,
plus scaffolding as the real mechanism. Nothing guarantees the reverse. The result is a
builder marooned on top of a wall or a roof, wandering and then sleeping there, while the
remaining cells are never built.

### Measured, in three distinct geometries

All from the real hosted `payoff_loop_demo`, not fixtures.

**1. Wall layer 3 — SOLVED, and it is the proof the mechanism works.**
Erection disabled: 27/30 wall cells. Erection enabled: 30/30 in 16.1s. Scaffolding
supplies the ascent and the descent together, so nothing strands.

**2. Roof interior — no scaffolding is ever built there.**

    SCAFFDIAG cell=(993, 9, 1002) seen=3 PLANNED=true cells=1
    SCAFFDIAG cell=(993, 9, 1003) seen=3 PLANNED=true cells=1
    scaffold cells standing at roof stage: 0

The two interior roof cells are detected, clear the persistence gate, and plan
successfully — and nothing is ever standing, because the planned support would have to
sit INSIDE a room the finished walls have sealed. Roof stops at 10/12.

**3. Wall crown with a ground-level opening — the builder strands and stops working.**

    STALLDIAG room walls villager=(993, 9, 1004) state=5 pending=5
      [(994,6,1004) (994,7,1004) (994,8,1004) (992,7,1002) (992,8,1002)]
    STALLDIAG room walls villager=(992, 9, 1004) state=3 pending=5  [unchanged]

Interior is x=993, z=1002..1003 at y=6..8; the villager sits at **y=9** throughout —
WANDERING, then SLEEPING, never building. The pending set never moves. Two of those cells
float above an erased door cell; the other three are an untouched corner column the
marooned builder simply never returns to.

### What has already been ruled OUT, so nobody re-treads it

Five hypotheses were formed by reading code tonight and all five were refuted by
measurement. Recorded so this story starts from evidence:

- ~~The new vertical escape loop in `would_trap_builder`~~ — guarding it scaffold-only
  changed nothing.
- ~~The `_served_cells` latch~~ — a real defect, fixed, and not this one.
- ~~Dismantle removing the descent~~ — `SC-INV-2` landed and the roof numbers did not
  move by a single cell.
- ~~"The builder walks in and correctly refuses to seal itself in"~~ — it is never
  inside; the interior is y=6..8 and it sits at y=9.
- ~~"Erasing a drafted cell disorders the project"~~ — erasing the TOP cell of a column
  instead gives 29/29 in 15.6s, the same speed as untouched.

**Working rule for this story: measure in the stall window.** End-of-run positions say
nothing about what happened during the stall, and reading them as if they did is what
produced two of the five wrong answers.

---

## Acceptance Criteria

- [ ] AC1: After ANY construction job completes, the claiming villager has a path back to
      standable settlement ground. Asserted on a real booted `GameWorld`, not a fixture.
- [ ] AC2: The guarantee holds where no scaffolding exists — a builder on a wall crown,
      or on a finished roof, must still get down. `SC-INV-2` only protects a descent that
      already exists; this must create one.
- [ ] AC3: Determinism survives (ADR-0009): same world, same villager, same route down.
- [ ] AC4: Seal prevention is not weakened, and `villager-ai-016`'s livelock escape stays
      reachable.
- [ ] AC5: The demo's wall stage reaches 30/30 WITH a ground-level opening present —
      today that geometry gives 24/29.
- [ ] AC6: A villager never sleeps above the build site with work still pending. The demo
      already reports this in plain language; the report must come back clean.

## Anti-Vacuity Lever

Two assertions, both failing today, and they fail in DIFFERENT geometries so neither can
mask the other:

1. **Crown descent.** Drive the real hosted chain to build a room with a ground-level
   opening. At every poll where the built count does not advance, assert the villager's
   cell is not above the wall top with cells still pending. Today this trips within
   seconds: y=9, state WANDERING, pending frozen at 5.
2. **Roof descent.** Build walls to completion, draft the roof, and assert
   `find_path(villager_cell, settlement ground)` is non-empty once the roof project
   reaches DONE or its cap. Today the villager finishes at y=10 with an empty path.

Record both observed failures verbatim in the commit body, as
`villager-ai-024` did.

## Out of Scope

- Doors. A sealed room still cannot be entered and that independently blocks the interior
  roof — a real, separate need, deliberately NOT bundled here. A door story written on
  top of an unsolved descent would inherit this failure and look like its own.
- Retiring ADR-0009's climb mutations. They stay until their counters read zero; this
  story is what should eventually make that true, and the counters (40 and 9 per run
  today) are the measure.
- Multi-villager work sharing.

## QA Test Cases

**AC1/AC2 — the way down exists**
- Given: a real booted game, a construction job just completed on a raised structure.
- Then: `find_path` from the villager to standable settlement ground is non-empty.

**AC5 — the doorway geometry stops costing cells**
- Given: the demo's room with one ground-level cell erased.
- Then: all 29 remaining wall cells reach BUILT.

**AC6 — nobody sleeps on the roof with work pending**
- Given: a full demo run.
- Then: no BEDLESS sleep is reported above the build site while cells remain pending.

**AC4 — seal prevention intact**
- Given: a villager whose next write would trap it.
- Then: it still refuses, the abandon count still rises, and the livelock escape is still
  reachable.
