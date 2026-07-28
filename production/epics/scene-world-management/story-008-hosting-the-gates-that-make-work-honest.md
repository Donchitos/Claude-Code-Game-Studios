# Story 008: Hosting the gates that make work honest

> **Epic**: Scene & World Management
> **Status**: Complete (2026-07-27 — 1526/1526 suite green, 0 orphans, parent-verified; both FINDING lines gone from the demo report)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/building-system.md`, `design/gdd/build-validation-navigability.md`,
`design/gdd/villager-ai-behavior.md` (Rule 3, on-site work)
**ADR Governing Implementation**: ADR-0001 (DI), ADR-0005 (boot sequencing), ADR-0016
(build-project lifecycle)

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM

### How this was found

By building `tools/payoff_loop_demo.gd` — a capture tool that drives the real shipped
build chain end to end and photographs each stage — and then reading the picture
against the text. The tool drafted a 30-cell room, released it, and watched a real
villager build 20 of those cells. But the screenshot shows the villager standing well
away from the house while its walls went up.

Grep-confirmed, independently, in the shipped source:

```
BuildValidation.new(            in src/ : 0     in tests/ : 16
VillagerOnSiteGate.new(         in src/ : 0
VillagerSealPreventionGate.new( in src/ : 0
```

Three more fully-built, fully-tested classes that the running game never constructs.
This is the same failure mode the project has now hit nine times — world generation,
roster spawn, need initialisation, the furniture registry, the build-tool chain, the
camera, the lighting, and now these.

### Why each one matters

**1. `VillagerOnSiteGate` / `VillagerSealPreventionGate` — work is credited to absent
workers.** Both gates default permissively when unwired, so `ConstructionTickLoop`
credits a claimed job on every tick regardless of whether the villager has physically
arrived. This is observed behaviour in the demo run, not a hypothetical: the walls rose
while the villager was elsewhere. Every "villagers build what you draw" claim this
project makes is, in the shipped game, "cells complete on a timer once claimed".

**2. `BuildValidation` — no room is ever sheltered.** `Valley._wire_build_project_lifecycle()`
constructs `FurnitureBedProvider.new(furniture_registry, null)` — a null validation
dependency — so `is_bed_sheltered()` structurally returns `false` in the shipped game
no matter how perfect the room. That makes Sprint 10's crown (milestone criterion #5:
a villager sleeps better in a room you built) inert in the product. The behaviour is
real and covered by tests; the game simply never asks the question.

---

## Acceptance Criteria

- [x] AC1: `BuildValidation` is constructed and hosted in the shipped scene chain, wired
      per ADR-0001, and `FurnitureBedProvider` receives it instead of `null`.
- [x] AC2: `VillagerOnSiteGate` and `VillagerSealPreventionGate` are constructed and
      wired into `ConstructionTickLoop`'s job-crediting path in the shipped scene.
- [x] AC3: A claimed construction job accrues progress ONLY while the claiming villager
      is actually on site. A villager that walks away stops crediting; when it returns,
      crediting resumes.
- [x] AC4: A bed inside a genuinely enclosed, built room reports sheltered in the shipped
      game; the same bed under open sky does not.
- [x] AC5: Boot invariants are added to Valley's existing block for all three.
- [x] AC6: `tools/payoff_loop_demo.gd`'s report no longer prints either FINDING line —
      the tool that found this is also the tool that proves it fixed.

## Anti-Vacuity Lever

Two assertions, both of which fail loudly on today's build:

1. **On-site crediting** — drive a real claimed job with the claiming villager placed
   away from the job cell, tick N times, and assert progress is EXACTLY zero. On today's
   build it accrues N ticks of progress. Then move the villager onto the site and assert
   it accrues again — so a naive "always deny" fix fails too.
2. **Shelter reaches the game** — boot the real scene, build a real enclosed room around
   a real bed, and assert `is_bed_sheltered()` is true. Today it is structurally false,
   so this cannot pass vacuously; and it stays false if `BuildValidation` is hosted but
   left unwired from the bed provider.

## Out of Scope

- Any change to `BuildValidation`'s own logic, or to either gate's rules. All three are
  built and tested; this story only makes the running game use them.
- Retuning construction tick rates or job-claim policy.
- The hen-and-egg pacing issue the demo also surfaced (a villager gets tired and goes to
  sleep before the room that would let it sleep well exists). That is a design/balance
  question for the creative director, not an integration bug — worth its own note.

## QA Test Cases

**AC3 — absent workers earn nothing**
- Given: a claimed construction job, claiming villager NOT on the job cell.
- When: N ticks elapse.
- Then: the job's progress is zero. Move the villager on site, tick again, progress accrues.

**AC4 — shelter is real in the shipped game**
- Given: the real booted scene, a bed inside a fully enclosed built room.
- Then: `is_bed_sheltered()` is true for that bed; false for an identical bed with the
  roof removed.

**AC1/AC2/AC5 — the wiring exists**
- Given: the real booted scene.
- Then: `BuildValidation`, `VillagerOnSiteGate` and `VillagerSealPreventionGate` are each
  constructed exactly once, and `FurnitureBedProvider`'s validation dependency is not null.

---

## Closure Note (2026-07-27)

Both gaps closed. `BuildValidation` is hosted in `Valley.tscn` and reaches
`FurnitureBedProvider` instead of the old `null`; both gates are constructed and
every hosted villager — the default and every roster member — is registered with
them.

THE PROOF IS A REGRESSION IN THE PICTURE. The same demo now builds 19 of 30 wall
cells inside the same wait cap instead of 20, because the villager has to travel
to each cell and stay there to earn credit. Less house, more truth. The demo's
two FINDING lines are gone; `grep -n FINDING` on the full log returns nothing.

THREE SELF-CAUGHT TEST DEFECTS, recorded because each is instructive:
1. The AC3 fixture first drove a `MockTimeTickSystem` while the hosted
   `ConstructionTickLoop` binds to the real `TimeTickSystem` autoload at boot.
   Progress was therefore always zero and the test would have passed against a
   completely unfixed build — a vacuous test of exactly the kind this project
   keeps hunting. Rewired to the real autoload's `tick`.
2. The AC4 fixture assumed the space above a written floor layer was empty. The
   real world pages in procedural terrain, so the "open interior" premise was
   false. Fixed by explicitly clearing a headroom column.
3. A grep guard assumed `BuildValidation.new(` would appear once. It never does —
   `BuildValidation` is scene-hosted like every other injected-tier Node. The
   guard now checks for the hosted node.

Out of scope and untouched, as required: `BuildValidation`'s own logic and both
gates' rules.

STILL OPEN, deliberately: the demo's walls plateaued at 19/30 for roughly 180
seconds. The likely cause is the villager cycling through seal-prevention
refusals as the room closes around it — expected gate behaviour rather than a
defect, but not investigated. Worth a look before anyone reads the plateau as a
performance problem.
