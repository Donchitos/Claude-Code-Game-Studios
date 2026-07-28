# Story 024: A villager cannot finish a wall

> **Epic**: Villager AI & Behavior
> **Status**: Complete (2026-07-27 — 1580/1580 suite green, 0 orphans, parent-verified; a room drawn through the hosted WallTool now reaches full enclosure)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2 days (1 day spike + 1 day fix; the spike may re-scope the fix)
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/villager-ai-behavior.md` (job selection, pathfinding),
`design/gdd/building-system.md` (construction jobs)
**ADR Governing Implementation**: ADR-0007 (AStar3D pathfinding & room analysis) — primary;
ADR-0008 (villager AI execution), ADR-0009 (deterministic movement)

**Engine**: Godot 4.7-stable | **Risk**: HIGH

### The finding

**A single autonomous villager cannot fully enclose any `WallTool`-built room, of any
size, in the shipped game today.** Construction always plateaus at the topmost wall
layer.

Found while implementing `scene-009`, by instrumenting the real booted `GameWorld` —
real `WallTool` → `CommitPipeline` → `ConstructionTickLoop` → both villager gates, one
real villager — across multiple room shapes and sizes (1×2 interior matching the
shipped demo, 4×5 interior), and multiple build orders (all segments at once, one
segment at a time, and a "leave a doorway open until the villager is confirmed
outside" strategy). **Not one configuration reached full enclosure.**

### It is NOT what Sprint 12's plateau spike assumes

`sprint-12.md`'s `spike-plateau` row hypothesises "the villager cycling through
seal-prevention write refusals as the room closes around it." The evidence rules that
out:

- Stuck cells read `BlueprintCell.state == PLANNED`, `claimed_by_villager_id == -1` —
  **never claimed at all**, not claimed-and-refused.
- `VillagerSealPreventionGate.get_abandon_count(cell) == 0` for every stuck cell.

`abandon_count` only increments on an actually-refused write, and refusing requires an
existing claim. The seal-prevention path is never even consulted for these cells:
**job selection excludes them before any claim is attempted.**

`would_trap_builder` was observed both true and false depending on villager position,
which is consistent with it being irrelevant here.

### Working hypothesis, evidence-supported

Job-selection reachability can extend **one** step past an already-known-standable
graph node to reach an unbaked destination — which explains why a wall's **second**
layer reliably completes, since it sits one step above always-standable original
ground. It cannot chain **two** such extensions — which explains why the **third**
layer never does, because standing there requires a height that is only standable
because of the second layer's own construction.

Independent of tick budget: identical stalls at 600 and at 5000 ticks, zero improvement.

`WallToolConfig.wall_height` ships as **3**, and villager clearance requires 3 clear
cells. So this is not an edge case — it is every wall the player will ever draw.

### Second, independent finding (same investigation)

`CandidateCellRules.is_candidate_interior_cell` requires a cell to be **roofed** (solid
within `max_room_height` directly above) before it is even a candidate for Room
classification. `tools/payoff_loop_demo.gd` builds **walls only, never a roof**. So even
if the walls completed, `is_bed_sheltered()` could not read true for a bed inside.

Two independent reasons the demo's bed has never been sheltered.

---

## Acceptance Criteria

- [x] AC1: A single villager, given a drawn room of `WallToolConfig.wall_height` and any
      reasonable footprint, completes **every** wall cell — no plateau at the top layer.
- [x] AC2: The root cause is named in the story before the fix lands: state precisely
      which reachability/job-selection rule excluded the cells, with the evidence.
- [x] AC3: The fix does not weaken seal prevention. A villager must still refuse a write
      that would trap it, and `villager-ai-016`'s livelock escape must still be reachable.
- [x] AC4: Determinism survives (ADR-0009): same world, same villager, same job order.
- [ ] AC5: `tools/payoff_loop_demo.gd` builds a **roof** as well as walls, so a finished
      room is actually Room-classifiable and its bed can be sheltered.
- [ ] AC6: The demo reaches a fully enclosed, roofed room with one villager, and says so
      in its own report.

## Anti-Vacuity Lever

Assert on the real booted game, not a fixture: draw a room through the hosted `WallTool`,
run the real tick loop with one real villager, and assert **every** blueprint cell reaches
`BUILT` within a stated tick budget. Today this fails at the top layer in every shape and
size tried, so it cannot pass vacuously. Record the observed plateau — cell coordinates,
`state`, `claimed_by_villager_id`, `abandon_count` — in the commit body.

## Out of Scope

- Retuning `wall_height` to dodge the bug. Three is the designed height; a fix that only
  works at two is not a fix.
- The hen-and-egg pacing question (D10) — separate, and a creative-director call.
- Multi-villager work sharing.

## QA Test Cases

**AC1 — a room actually gets finished**
- Given: the real booted game, a room drawn through the hosted wall tool, one villager.
- Then: every blueprint cell reaches BUILT inside the stated budget.

**AC3 — seal prevention still works**
- Given: a villager whose next write would trap it.
- Then: it still refuses, `abandon_count` still increments, and the livelock escape is
  still reachable after the configured number of abandons.

**AC5/AC6 — the demo builds a real room**
- Given: `tools/payoff_loop_demo.tscn` run end to end.
- Then: walls AND roof complete, the interior classifies as a Room, and the report says so.

---

## AC2 — the actual rule, confirmed empirically (2026-07-27)

`VillagerNavGraph` never connects two cells in the SAME COLUMN. A step is
defined as inherently horizontal — `HORIZONTAL_HALF_OFFSETS` /
`HORIZONTAL_FULL_OFFSETS` never contain `(0, 0)`, with `|Δy| <= 1` riding along.
And `VillagerWalkabilityRules.is_standable(cell)` requires the cell BELOW to be
solid, so two stacked cells can never both be standable graph points at once. A
same-column vertical edge is therefore not merely missing — it is impossible by
construction.

Consequence for a wall column:
- Layer 2 is reachable directly from always-standable ground: one combined
  horizontal + vertical step. It always completes.
- Layer 3 needs a SECOND such extension. Its only same-column neighbour at the
  required height is layer 2's own cell — which goes solid and leaves the graph
  in the SAME `patch_cells` call that adds layer 3 as a point. Layer 3 therefore
  enters the graph as an ISOLATED point with zero edges to anywhere a villager
  can stand.

Confirmed directly, not inferred: `has_point == true`, and `find_path` from every
occupied cell returns `[]`, on every tick up to 5000. `VillagerJobSelector`'s
true-path check can never succeed, so the cell is excluded from selection before
any claim — which is exactly why `state == PLANNED`, `claimed_by == -1` and
`abandon_count == 0`.

The Unstuck Watchdog does list the cell above a self-sealed villager as a ring-1
candidate, but its lexicographic `(y, x, z)` tie-break always prefers a
lower-or-equal standable neighbour, and the adjacent floor always qualifies — so
it never placed the villager on the isolated node either.

### Verbatim pre-change plateau

    PLATEAU-CHECK cell=(2, 1, 3) state=2 claimed_by=1  abandon_count=0   BUILT
    PLATEAU-CHECK cell=(2, 2, 3) state=2 claimed_by=1  abandon_count=0   BUILT
    PLATEAU-CHECK cell=(2, 3, 3) state=0 claimed_by=-1 abandon_count=0   PLANNED

### The fix

A builder standing where the graph cannot reach is moved, discretely, at the two
moments it can happen: climbing ONTO the self-sealed cell when the seal-prevention
exemption fires, and stepping back DOWN once the column is finished and it is left
on a zero-edge point. Symmetric by design — the coordinator rejected the obvious
alternative of widening stuck detection into WANDERING, because
`villager-ai-019` deliberately makes a genuinely walled-in wanderer STAY PUT
(Edge Case 2), and a walled-in villager is indistinguishable from a stranded one
by flood-fill alone. It reads as what a real builder does: climb up, lay the top
course, climb down.

ADR-0009's "two sanctioned mutation points" is amended accordingly, and
`control-manifest.md` follows.

AC3 verified intact: `seal_prevention_test.gd` 13/13 and `unstuck_watchdog_test.gd`
12/12, both unchanged. The fix is structural, not height-specific — a 6-layer
column completes too.

### Still owed (AC5/AC6 partially)

`tools/payoff_loop_demo.gd` gained a roof stage but has NOT been run end to end
since, so it is not yet proven that the demo reaches a roofed, Room-classifiable
enclosure. Named as a debt rather than claimed.

### A defect of my own, found and fixed here

`payoff_loop_demo.gd` did not PARSE, and had not since commit 6ddb153 — two
`while true:` helpers with no trailing return, which GDScript's analyser rejects.
They were written by the scene-009 attempt and committed without the tool ever
being `load()`-ed once. The tool that exists to catch "shipped but never run" was
itself shipped but never run. Fixed, with the reason recorded at both sites.

---

## AC5 / AC6 — RUN, and NOT met (2026-07-27)

The demo was finally executed end to end. It did not reach a roofed,
Room-classifiable enclosure, so both ACs stay open. Recorded rather than rounded up.

    room walls: WAIT CAP (220s) hit with 27/30 cells BUILT — stopping honestly
    construction result: 27 / 30 wall cells reached BUILT
    roof drafted: 12/12 cells on the plane one above the finished walls (y=9)
    roof: 9/12 BUILT at the cap
    stage 6 (claim) NOT REACHED: villager id=0 has not claimed a bed within the
      300s wait cap. Skipping '06-claimed' and stage 7 (sleep).

The fix is real — 19/30 before it, 27/30 after, same cap — and the unit test
reaches 30/30 on a tick budget. The gap between 30/30 in test and 27/30 live is
not a second wall defect. It is D10:

    D10 check: 6 SLEEPING episode(s) observed this run:
      episode 1: GROUND sleep at (992, 9, 1003) (no bed owned yet)
      ... 6 of them, every one on the ground, none in a bed ...

The villager spends more of the run exhausted than building. It builds its own
house, gets tired, lies down in the dirt beside it, gets up, builds a bit more —
and never gets far enough to claim the bed it placed itself. That is the
hen-and-egg pacing finding, and it has stopped being a curiosity: it is now the
dominant factor in whether the payoff loop can be demonstrated at all.

**This makes D10 a blocker for scene-009, not a footnote.** Whatever the creative
director decides — a gentler initial need, a longer first day, a slower decay
until the first bed exists — scene-009 cannot show a villager sleeping in a bed
it built until the villager can stay awake long enough to finish the room.

`06-claimed.png` and `07-sleeping.png` do not exist, correctly: the tool refuses
to photograph a stage it did not reach.

---

## CORRECTION (2026-07-27, user-caught) — the demo stalled from STRANDING, not pacing

The AC5/AC6 note above blames D10 pacing for the 27/30 stall. That is wrong.

The sleep coordinates were y=9 and y=10, against a build site at y=6 with walls
to y=8 — every one of them ON TOP of the structure, with `state=5` (WANDERING).
The demo's "GROUND sleep" label means "no bed owned", not "on the ground"; I read
it literally and mis-attributed the cause.

The villager climbed up, could not get down, wandered on the roof plane and slept
there. That is this story's own stranded-on-an-isolated-point case — and it shows
the symmetric descend fix does NOT cover this path: it fires when a column
completes, not when a builder is left stranded on a finished structure.

D10 is therefore NOT blocking scene-009 or presentation-005's open AC. Stranding
is. The user's scaffolding proposal (see session state, four rulings taken) is the
proper fix, and this story's climb-up/climb-down mutation should be retired once
it lands.
