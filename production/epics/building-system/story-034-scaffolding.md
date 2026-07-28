# Story 034: Scaffolding — the builder gets real ground to walk on

> **Epic**: Building System
> **Status**: NOT LANDED — first implementation pass parked (2026-07-27). Work preserved at production/parked/story-034-scaffolding-WIP.patch; the tree is back at the last green commit.
> **Layer**: Core
> **Type**: Integration (Building System + Villager AI nav + Build Validation)
> **Estimate**: 3 relative-complexity units (≈3× a single-module logic story). One
>   serial chain of three: **(1)** where a scaffold cell lives + the predicate read
>   source → **(2)** the ADR-0007 amendment landing in `VillagerNavGraph` → **(3)**
>   erect/dismantle lifecycle. Nothing in the chain parallelises. The real critical
>   path is the four **Open Decisions** below, not throughput — three of them are TD
>   rulings and one is a creative/design value.
> **Manifest Version**: 2026-07-27 *(bumped by the TD rulings below — ADR-0007 v1.1
>   landed the scaffolding amendment and `control-manifest.md` followed)*
> **Last Updated**: 2026-07-27

> **Numbering note**: this story was requested as `story-032-scaffolding.md`. `032` is
> already taken by `story-032-undo-redo-stack-core.md`, and `033` by
> `story-033-voxel-write-seam.md`. Filed as **034**, the next free number in
> `production/epics/building-system/`. (Second such collision today — see the
> `story-022` collision.)

## Context

**GDD**: `design/gdd/building-system.md` (Core Rules 11/12/14, F3 construction time,
Tuning Knobs), `design/gdd/villager-ai-behavior.md` (Rule 8/8a standability, Rule 9
step-legality, Rule 15/F5 unstuck watchdog, Rule 16/F6 seal prevention),
`design/gdd/build-validation-navigability.md` (Rule 1 candidate interior cell)
**ADR Governing Implementation**: **ADR-0007** (AStar3D pathfinding & shared
walkability predicates) — primary, and the one this story proposes to **amend**;
ADR-0009 (deterministic movement, occupancy, seal prevention), ADR-0016
(build-project entity lifecycle), ADR-0002 (config), ADR-0001 (DI)

**Engine**: Godot 4.7-stable | **Risk**: HIGH

---

### Why this story exists

`villager-ai-024` established the rule empirically and named it precisely:

> `VillagerNavGraph` never connects two cells in the **same column**. A step is
> defined as inherently horizontal — `HORIZONTAL_HALF_OFFSETS` /
> `HORIZONTAL_FULL_OFFSETS` never contain `(0, 0)`, with `|Δy| ≤ 1` riding along.
> And `VillagerWalkabilityRules.is_standable(cell)` requires the cell BELOW to be
> solid, so two stacked cells can never both be standable graph points at once. A
> same-column vertical edge is therefore not merely missing — **it is impossible by
> construction.**

The consequence, measured on the real booted game and not inferred: a wall's third
layer enters the graph as an **isolated point** with zero edges — `has_point == true`,
`find_path` from every occupied cell returns `[]` on every tick up to 5000. So
`VillagerJobSelector`'s true-path check can never succeed and the cell is excluded
from selection **before any claim is attempted** (`state == PLANNED`,
`claimed_by == -1`, `abandon_count == 0`).

**The landed fix works, and it works *around* the gap.** `villager-ai-024` moves the
builder discretely: `VillagerAi.climb_onto_self_sealed_cell()` when the seal-prevention
exemption fires, and `VillagerAi._relocate_if_marooned()` when the column finishes and
leaves it on a zero-edge point. That is two of ADR-0009's four sanctioned discrete
`current_cell` mutation points, spent on covering for a missing edge class.

**Scaffolding closes the gap instead of routing around it: the builder gets real
ground to walk on.**

### It also fixes a second, still-open symptom

`villager-ai-024`'s own **CORRECTION (2026-07-27, user-caught)** records that the
payoff demo's stall at 27/30 was not pacing (D10) — it was **stranding**:

    room walls: WAIT CAP (220s) hit with 27/30 cells BUILT — stopping honestly
    D10 check: 6 SLEEPING episode(s) observed this run:
      episode 1: GROUND sleep at (992, 9, 1003) (no bed owned yet)

Sleep coordinates at y=9 and y=10 against a build site at y=6 with walls to y=8 —
every one **on top of the structure**, `state=5` (WANDERING). The villager climbed up,
could not get down, wandered the roof plane and slept there. The symmetric descend fix
does **not** cover this path: it fires when a *column* completes, not when a builder is
left stranded on a *finished structure*.

**Stranding — not D10 — is what blocks `scene-009` and `presentation-005`'s open AC.**

---

### THE KEY PROPERTY: scaffolding is NOT a solid block

This is what makes the story cheap, and it must be stated explicitly because two
otherwise-expensive risks vanish for free because of it.

Minecraft's scaffolding has **no collision**: you pass through it, you stand on top of
it, and you climb it from the inside
(source: <https://minecraft.wiki/w/Scaffolding>). This story adopts that property
verbatim as its load-bearing design constraint, not as flavour.

**A scaffold cell is passable. It is never solid. It never satisfies any consumer's
`_is_solid` read.**

#### Risk that vanishes #1 — PHANTOM ROOMS

`BuildValidation` keys entirely on **solid** cells.
`CandidateCellRules.is_candidate_interior_cell` composes
`VillagerWalkabilityRules.is_standable` with `is_roofed`, and `is_roofed`'s upward scan
is `_is_solid(voxel_world, cell + (0, offset, 0))`, which is
`contents != null and not contents.is_empty()`. A non-solid scaffold cell can
**never** read as a wall or a roof, so scaffolding around a half-built house can never
declare it sheltered. **No scaffold-awareness is required anywhere in
`src/build_validation/`.** This is a structural guarantee from the passability
property, not a rule anyone has to remember.

#### Risk that vanishes #2 — SELF-SEALING

`VillagerSealPreventionGate` exists to stop a villager entombing itself behind a
Planned→Built write. **A villager cannot trap itself behind something it can walk
through.** Erecting scaffolding can never entrap anyone, so the gate needs **no**
scaffold-awareness, and `villager-ai-016`'s livelock escape is untouched. This story
changes zero lines in `villager_seal_prevention_gate.gd`.

> Corollary the implementer must not lose: because scaffolding is non-solid, it is
> also **not voxel data**. See Open Decision **D1** — this is the single largest
> unresolved question in the story.

---

### NAV-GRAPH CONSEQUENCE — a BOUNDED amendment, not general climbing

Two changes, both narrow, both scoped to scaffold cells only:

1. A scaffold cell is **standable without a solid cell beneath it** — it supports
   itself.
2. **Vertical edges become legal ONLY between two scaffold cells in the same column.**

**Nothing else about movement changes.** No ladders, no stairs, no jumping, no falling,
no general climbing. `max_step_height` stays 1. `villager_clearance` stays 3. Two
stacked non-scaffold cells still can never both be standable. This is deliberately the
smallest amendment that admits the missing edge class, and it needs a **technical-director
ruling** — this story proposes the wording, it does not edit the ADR.

---

## PROPOSED ADR-0007 AMENDMENT (exact wording — for TD ruling; DO NOT self-apply)

> ⚠️ **SUPERSEDED 2026-07-27 — the amendment has LANDED, and it is not verbatim this
> text.** `docs/architecture/adr-0007-ai-pathfinding-navigation-room-analysis.md` is now
> **v1.1** carrying §1a/§1b/**§2a**/**§2b**. The technical-director took this proposal as
> the base and changed it in three load-bearing places: (1) §1b now **requires** the
> `*_after_write` twins to receive the scaffold source — without it `would_trap_builder`
> fires on nearly every write; (2) §2a now **explicitly refuses** same-column steps whose
> endpoints are not both scaffold — `is_step_legal` would otherwise already accept them
> once §1a removes the structural prevention; (3) a new **§2b** requires the scaffold
> source to carry its own synchronous change signal, because a scaffold write is not a
> `VoxelWorldGrid` write and `cell_changed` will never fire for it. **Implement against
> the ADR, not against the text below.** Retained for provenance only.

> **Owner**: technical-director. **This story does not edit
> `docs/architecture/adr-0007-ai-pathfinding-navigation-room-analysis.md`.** The text
> below is the proposal, written to drop in as-is if accepted.

Add to **Decision**, after §1:

> **§1a — Scaffold standability (amendment, story `building-034`).** A cell occupied by
> a **scaffold** is standable **without** a solid cell beneath it — scaffolding supports
> itself. The standability predicate reads:
>
> > `cell` is standable iff **(** the cell directly below it is solid **OR** `cell`
> > itself is a scaffold cell **)** AND `cell` plus the `villager_clearance - 1` cells
> > directly above it are all passable.
>
> A scaffold cell is **passable**: it is never solid, never occludes, and never
> satisfies any consumer's solidity read. It therefore can never contribute a wall or a
> roof to Build Validation's Room/Sealed verdict (§3 is unchanged and stays
> scaffold-blind), and can never entrap a villager for the purposes of ADR-0009's
> seal-prevention gate.
>
> **§1b — The predicates keep their single-source-of-truth status.** Scaffold occupancy
> is **not** voxel data (the same ruling BV-1 already applies to furniture: "furniture is
> not voxel data — it never enters `VoxelWorldGrid`"). §1a therefore requires the shared
> predicates to read a **second occupancy source** alongside `VoxelWorldGrid`. That
> source is supplied as an **explicit parameter** on the shared predicate functions —
> never a module-global, never a singleton read, and never a second copy of the rules
> living in a consumer. Both consumers (Villager AI's `AStar3D` graph and Build
> Validation's BFS) continue to call one implementation. A caller that supplies **no**
> scaffold source observes exactly today's behaviour, which is what keeps §3's
> independence and the "no duplicated rules or constants" guarantee structural rather
> than disciplinary.

Add to **Decision**, after §2:

> **§2a — Scaffold vertical edges (amendment, story `building-034`).** The travel graph
> gains **exactly one** new edge class and no other: a **vertical edge between two
> scaffold cells in the same column** — `Δx = 0`, `Δz = 0`, `Δy = ±1`, and **both**
> endpoints are scaffold cells — is a legal step. Every other same-column pair remains
> structurally unconnectable, exactly as the horizontal-offset sets already guarantee.
> The step-legality predicate is otherwise unchanged: `|Δy| ≤ max_step_height` still
> governs every non-scaffold step, and the diagonal flanking rule is untouched (a
> vertical scaffold edge is never diagonal, so the flank check never runs on it).
>
> **This amendment is bounded and is not general climbing.** It introduces no ladder,
> stair, jump, or fall mechanic; it does not raise `max_step_height`; it does not change
> `villager_clearance`; and it grants no vertical traversal to any cell that is not a
> scaffold cell.

Add to **Validation Criteria**:

> - A unit test asserts a scaffold cell is standable with **air** beneath it, and — in
>   the same test — that two stacked **non-scaffold** cells are still never both
>   standable. The amendment must not widen beyond scaffolding.
> - A unit test asserts the vertical step is refused when **only one** endpoint is a
>   scaffold cell, in both directions.
> - A unit test asserts `CandidateCellRules.is_roofed` returns `false` for a column
>   whose only occupant above the query cell is scaffolding — scaffolding is never a
>   roof.
> - Grep-verifiable: the scaffold occupancy source appears as a parameter on the shared
>   predicates and nowhere as a second implementation of standability or step-legality.

**Downstream doc updates the amendment implies** (also TD-owned, not this story's edits):
`docs/architecture/control-manifest.md` Feature Layer "Walkability = two shared pure
functions" bullet, and its Manifest Version bump.

---

## Acceptance Criteria

Ruling ACs (AC1–AC4) are the **user's four binding rulings**, transcribed. AC5–AC9 are
the structural properties the rulings depend on.

- [ ] **AC1 — TRIGGER: automatic, on demand.** The system detects an unreachable
      target cell and erects scaffolding **exactly there**. The player only draws the
      room; there is no scaffolding tool, no scaffolding button, and no scaffolding
      material in any palette. Scaffolding is erected **only when needed** — a room
      whose every cell is already reachable produces **zero** scaffold cells.
      *(See **D5**: the detector this AC assumes does not exist today.)*
- [ ] **AC2 — BUILD COST: a real construction job, but fast.** Erecting a scaffold cell
      is a worker-executed construction job on the same tick loop as any other cell —
      nothing appears from nothing. Its tick cost is **markedly lower** than a wall
      cell's, read from config (`base_build_ticks[scaffold]`), never a literal, and
      strictly less than `base_build_ticks[block]`. *(See **D7** for the value.)*
- [ ] **AC3 — LIFETIME: auto-dismantled on project completion, TOP-DOWN.** When the
      owning project completes, its scaffolding is automatically dismantled from the
      **top down**, so the worker **rides it down** and can never strand itself. A
      **player-initiated cancel MAY** instead collapse the whole structure **bottom-up
      with no worker**, Minecraft-style. Both paths terminate with zero scaffold cells
      remaining and no villager left on a zero-edge graph point. *(See **D3**, **D4**.)*
- [ ] **AC4 — THE 6-LIMIT: horizontal cantilever, not height.** A scaffold cell may sit
      at most **6 cells sideways** from its supporting column. The limit constrains
      **overhang only** — scaffold height is unbounded by this rule. The value is a
      **config knob from day one** (`scaffold_max_cantilever_cells`, default 6), never a
      literal anywhere in `src/`, because items and skills will later **raise** this
      reach as a progression stat. *(See **D6** for the unit and the support definition.)*
- [ ] **AC5 — Scaffolding is never solid.** Every solidity read in the codebase
      (`VillagerWalkabilityRules._is_solid`, `CandidateCellRules._is_solid`, the mesher's
      face-culling occupancy read) reports a scaffold cell as **not solid**. Asserted
      directly, not assumed.
- [ ] **AC6 — No phantom rooms.** A half-built house fully surrounded by scaffolding is
      **not** classified as a Room and its bed is **not** sheltered. `src/build_validation/`
      contains zero scaffold-aware code — the property holds because there is nothing for
      it to read.
- [ ] **AC7 — Seal prevention is untouched.** `villager_seal_prevention_gate.gd` is
      unmodified by this story. `seal_prevention_test.gd` and `unstuck_watchdog_test.gd`
      pass unchanged, at their current counts.
- [ ] **AC8 — The nav-graph amendment is bounded.** A scaffold cell is standable with
      air beneath it; two stacked non-scaffold cells are still never both standable; a
      vertical step is legal only when **both** endpoints are scaffold cells. No other
      movement rule changes.
- [ ] **AC9 — Determinism survives (ADR-0009).** Same world, same villager, same job
      order ⇒ the same scaffold cells erected, in the same order, and dismantled in the
      same order. *(See **D8** — the erection route is currently undetermined.)*
- [ ] **AC10 — The payoff demo stops stranding.** `tools/payoff_loop_demo.gd` run end to
      end reaches a fully enclosed, roofed, Room-classifiable structure, and its report
      records **zero** sleep episodes above the build-site ground plane. This retires
      `villager-ai-024`'s AC5/AC6 debt.

---

## Anti-Vacuity Lever

**Two assertions on the real booted game, plus one deletion probe.** Fixture checks are
the guard, not the lever — the strongest levers this project has produced were live
scene-tree counts and real-booted-game assertions.

### Lever 1 (primary) — the top course becomes reachable, in the shipped game

Boot the real `Valley` scene through `GameWorld`'s boot gate (the harness
`neues-spiel/tests/integration/scene_world_management/build_validation_gates_hosting_test.gd`
already establishes — real `TimeTickSystem` autoload tick, hosted `WallTool`, hosted
`ConstructionTickLoop`, hosted gates, one real villager). Draw a room at the shipped
`WallToolConfig.wall_height` (= 3). Then assert, against the **hosted**
`VillagerNavGraph`:

```
find_path(villager.get_current_cell(), <standing cell for the top wall course>) != []
```

**This is provably false on today's build.** `villager-ai-024` measured it directly, not
by inference: `has_point == true` and `find_path` returns `[]` from **every** occupied
cell, on **every** tick up to 5000. There is no configuration, tick budget, or room
shape in which today's build satisfies this — so it cannot pass vacuously, and it cannot
be satisfied by a tick-budget increase.

### Lever 2 — the builder comes back down, in the shipped game

Same booted run. At the moment the owning project reaches `ProjectState.DONE`, assert:

```
find_path(villager.get_current_cell(), <the villager's spawn/settlement ground cell>) != []
```

i.e. the villager finishes standing somewhere **connected to the settlement ground
graph**. On today's build the demo's villager finishes on the roof plane at y=9/y=10
(`state=5`, WANDERING) on a zero-edge point, so the path is empty. **Also provably false
today**, and it is a different failure from Lever 1 — Lever 1 can be satisfied while
Lever 2 still fails, which is exactly the `villager-ai-024` correction's finding.

### Lever 3 — deletion probe (required, per this project's standing rule)

Delete the scaffold-erection call site **once**, re-run Levers 1 and 2, and record the
observed failure — cell coordinates, `state`, `claimed_by_villager_id`, the empty
`find_path` result — in the commit body. A green suite that stays green with the
production call removed is a vacuous suite.

### Guard assertions (unit tier, not the lever)

- A scaffold cell is standable with air beneath it; two stacked non-scaffold cells are
  not both standable. Today the first line of `VillagerWalkabilityRules.is_standable` is
  `if not _is_solid(voxel_world, cell + Vector3i(0, -1, 0)): return false`, so the first
  assertion cannot pass today **by construction**.
- `CandidateCellRules.is_roofed` is `false` for a column roofed only by scaffolding.
- A vertical step with one scaffold endpoint and one ordinary endpoint is refused, both
  directions.

---

## Out of Scope

- **General climbing, ladders, stairs, jumping, falling, or gravity of any kind.** The
  amendment is bounded to scaffold-to-scaffold vertical edges. Nothing else.
- **Retiring `villager-ai-024`'s climb-up/climb-down discrete mutation.** Recommended
  below as an **open recommendation**, deliberately not done here — it needs a TD/user
  ruling and should land only after scaffolding is proven in the shipped game.
- **A player-facing scaffolding tool.** Ruling 1 is explicit: automatic, on demand, the
  player only draws the room. No palette entry, no button, no material.
- **Retuning `wall_height`.** Three is the designed height; a fix that only works at two
  is not a fix (`villager-ai-024`'s own Out of Scope, inherited).
- **Multi-villager scaffold sharing / contention.** One builder, as today.
- **Scaffolding for demolition, dig, or excavation projects.** Build projects only
  (`BuildProject.Kind.BUILD`). Dig-order reachability is a separate question.
- **Scaffold visual polish** — silhouette, material, tint tiers, LOD. This story needs
  scaffolding to be *visible and legible*; art direction of it is the art department's
  call, and **D2** flags who owns the rendering path at all.
- **The hen-and-egg pacing question (D10 in `villager-ai-024`).** The correction in that
  story downgraded it from blocker to open design question; it stays a creative-director
  call, not this story's.
- **Save/load of scaffold state.** ADR-0012's per-system `serialize()` contract absorbs
  it structurally, but a scaffold that is by construction transient (erected on demand,
  dismantled on completion) may reasonably not be persisted at all. Named, not decided —
  and folded into **D3**, since the answer depends on whether scaffolding is its own
  entity.

---

## Open Decisions — what the four rulings do not answer

These are the real critical path. Each is stated with the evidence that produced it,
the options, and a recommendation. **None is decided by this story.**

### D1 — Where does a scaffold cell LIVE? *(TD ruling — largest open item)*

**The finding.** A scaffold cell **cannot** live in `VoxelWorldGrid`. `CellContents`
has exactly one occupancy axis: `is_empty()` is `block_type_id == EMPTY_BLOCK_TYPE_ID`
(= 0). **Any** non-zero block id is solid to **every** `_is_solid` reader in the
codebase — walkability, the roof scan, and the chunked mesher's face-culling. There is
no "passable block" concept anywhere in Voxel World, and inventing one changes
`is_empty()`'s meaning project-wide, in a module whose GDD states "one cell = one
occupant" and whose storage is a packed byte array.

**The precedent that fits.** TD ruling **BV-1** already answered this exact shape for
furniture: *"Furniture is not voxel data. It never enters `VoxelWorldGrid`... occupancy
lives in a Building-System-owned furniture registry."* `FurnitureRegistry` is the
landed implementation of that ruling and is the obvious model.

**Where the analogy breaks, and why this is a real decision.** Furniture is
walkability-**transparent** *by having nothing to read* — `CandidateCellRules`' doc
comment states this explicitly: *"This class therefore has no furniture-registry
parameter of any kind; the transparency property holds because there is nothing for it
to read."* **Scaffolding must do the opposite**: it must *change* walkability. And
`VillagerWalkabilityRules` is a static, `RefCounted`, never-instantiated library whose
predicates read **only** `voxel_world`.

- **Option (a) — scaffold registry + explicit overlay parameter on the predicates.**
  A `ScaffoldRegistry` mirroring `FurnitureRegistry`, plus a new optional parameter on
  `is_standable` / `is_step_legal`. Every existing call site that passes nothing keeps
  today's exact behaviour. **Note the standing tech debt this collides with**:
  `villager_walkability_rules.gd`'s own Out-of-Scope block names *"an overlay-predicate
  parameter unifying [the `*_after_write` twins] with this class is a later story."*
  Scaffolding may be that story's forcing function, and the TD should decide whether to
  unify the two overlay concepts or keep them separate.
- **Option (b) — a passability flag on `CellContents`.** Cheapest at the call sites,
  but redefines `is_empty()` for the whole project and touches storage, the mesher, the
  DDA pick, save format, and every `_is_solid` reader. High blast radius.
- **Option (c) — reuse the `*_after_write` override-aware twins' shape** as the overlay
  mechanism, rather than adding a parallel one.

**Recommendation: (a)**, with the TD explicitly ruling on whether it subsumes the named
`*_after_write` debt. It preserves the single-source-of-truth guarantee structurally,
keeps Build Validation scaffold-blind for free (it simply passes nothing), and matches
the BV-1 precedent this codebase already runs on.

### D2 — What does a scaffold cell look like to the mesher? *(TD + art ruling)*

If D1 lands on (a) or (c), scaffolding is **not in `VoxelWorldGrid`**, so the chunked
mesher never sees it and it renders as **nothing**. It is not a terrain block type and
has no entry in `BlockAppearanceConfig`. The player would watch a villager walk on air.

Options: a pooled-`MeshInstance3D` presentation tier (the **ghost-preview precedent** —
already pooled, already tinted, already bounded by `max_cells_per_command`); a dedicated
MultiMesh; or an appearance-config entry if D1 lands on (b). Owner is unclear between
Building System (which owns ghosts) and Presentation. **Recommendation: reuse the ghost
pool's mechanism with a distinct opaque tier** — no new mechanism design — but the
ownership and the visual read are a TD + art call.

### D3 — Does scaffolding belong to the owning BuildProject, or is it its own project?

**This is not cosmetic — one option is self-contradictory.** `BuildProject.recompute_state()`
sets `DONE` iff **every** tracked cell is `BUILT`. If scaffold cells are members of the
owning project, then:

- the project cannot reach `DONE` while scaffolding stands, **and**
- AC3 dismantles scaffolding *on project completion*.

That is circular: the trigger for removing the scaffolding is a state the scaffolding
prevents. Options:

- **(a) Its own entity/project, linked by owner id.** Sidesteps the circularity; needs a
  link field and possibly a third `BuildProject.Kind` (`SCAFFOLD`) or a separate
  registry. Also cleanly answers the save question in Out of Scope.
- **(b) Member cells of the owning project, excluded from the `recompute_state()` roll-up.**
  Cheaper, but adds a per-cell exclusion to a method whose doc comment currently states
  the rule with no exceptions — and every future reader of `recompute_state` must know it.

**Recommendation: (a).** The circularity in (b) is real and the exclusion is exactly the
kind of invisible special case that produces the next `villager-ai-024`.

### D4 — Player cancels the room mid-build while scaffolding stands, with a worker on it

Ruling 3 permits a cancel to collapse scaffolding **bottom-up with no worker**. It does
not say what happens to a villager **standing on it at that instant**.

**This project has no gravity.** Villagers are `Area3D`-only, with no physics colliders
(technical-preferences, ADR-0004). A Minecraft player falls; this villager does not — it
is simply left on a cell that instantly stops being standable, i.e. **a zero-edge graph
point**. That is precisely the stranding bug this story exists to fix, reintroduced
through the cancel path.

Options: **(i)** cancel-with-worker-present falls back to the top-down dismantle;
**(ii)** cancel collapses immediately and the existing `_relocate_if_marooned()` safety
net catches it — which argues **against** the retirement recommendation below;
**(iii)** cancel collapses and the worker is discretely relocated, which would be a
**fifth** sanctioned ADR-0009 `current_cell` mutation point.

**Recommendation: (i).** It needs no new mutation point, keeps ruling 3's fast path for
the common case (no worker present), and does not depend on a safety net this story may
retire. **User/TD ruling required** — this is where ruling 3 stops.

### D5 — Who DETECTS the unreachable cell? *(the trigger in AC1 has no implementation today)*

**Verified in source, not assumed.** The existing "unreachable" seam
(`ConstructionJobQueue.report_unreachable` → `BlueprintCell.is_unreachable` →
`job_reported_unreachable`) is **never reached for the cells scaffolding exists to
serve.** `VillagerAi._report_job_unreachable`'s own doc comment states it verbatim:

> only `_abandon_travel()`'s WORK branch ever calls this, and only for a job **this
> villager had just claimed** and then failed to path to (**never for F2's own silent
> pre-claim reachability skip, which never claims or reports anything**).

And `villager-ai-024` measured that top-course cells are **never claimed at all** —
`state == PLANNED`, `claimed_by_villager_id == -1`, `abandon_count == 0`. So the one
existing detector is structurally blind to exactly this case.

Options: **(a)** a new pre-claim detector in the job queue — when a released project has
`get_building_eligible_cells()` non-empty but `VillagerJobSelector` returns a `null`
choice across a full candidate sweep, the excluded cells are the scaffold targets;
**(b)** make F2's silent pre-claim skip report, reusing `report_unreachable`, at the
`unreachable_retry_ticks` (= 20) cadence that already exists; **(c)** a periodic sweep
owned by the Building System over every `PLANNED` cell in a `BUILDING` project.

**Recommendation: (b)** — it reuses a landed seam, a landed cadence, and a landed signal
rather than inventing a fourth reachability concept, and it makes `is_unreachable`'s
existing pulsing-orange ghost tint honest at the same time. Note (b) changes F2's
documented "silent" contract, so it is a **TD ruling**, not an implementation choice.

### D6 — What exactly does "6 cells sideways from its support" measure?

Ruling 4 is unambiguous about the intent (overhang, not height; config from day one;
raisable by progression) and silent on three mechanics:

1. **What counts as a support?** Original terrain ground only, or also a built wall, or
   also another scaffold column? Each yields a different reachable set.
2. **Which metric?** Chebyshev, Manhattan, or per-axis. Six diagonal cells is 6
   Chebyshev but ~8.5 Euclidean.
3. **Measured from the nearest support, or from the column the cell descends from?**

**Recommendation**: `scaffold_max_cantilever_cells: int = 6`, safe range **1–32** (headroom
for the progression stat ruling 4 requires), **Chebyshev** from the **nearest cell that is
itself supported** — matching `VillagerJobSelector.chebyshev_distance`, the metric this
codebase already uses for spatial pre-filtering. Support = solid-below **or** another
supported scaffold cell. Ruling needed from the user (it is a design-feel value, and it
is the number a future item will modify).

### D7 — What is `base_build_ticks[scaffold]`? *(creative/design value)*

AC2 says "markedly fewer ticks than a wall." Shipped `base_build_ticks[block]` = 4
(= 2.0 s at 1× and the 4.0 ticks/sec base rate). Structurally this needs a **third**
`BlueprintCell.Category` value (`SCAFFOLD`), a third branch in
`ConstructionTickLoop.required_ticks_for` and `required_demolition_ticks_for`, and two
new `ConstructionTickLoopConfig` fields (`base_build_ticks_scaffold`,
`base_demolition_ticks_scaffold`) with `_MIN`/`_MAX` constants and `validate()` clamps,
plus two rows in the building-system GDD's Tuning Knobs table.

**Provisional default — marked provisional**: `base_build_ticks_scaffold = 1`
(= 0.5 s at 1×, a quarter of a wall cell), `base_demolition_ticks_scaffold = 1`.
Range 1–20 to match its siblings. A designer/creative call, not a producer one.

### D8 — The erection route is undetermined, and AC9 requires it not to be

"Erect scaffolding exactly there" fixes the **destination**. It does not fix the
**path**: which supporting column, and in which order the cells are laid. Two different
valid routes give two different scaffold sets from the same world state, which breaks
AC9's determinism requirement (ADR-0009).

**Recommendation**: nearest supported column by **Chebyshev**, ties broken by the F2
lexicographic `(y, x, z)` convention via the already-public
`VillagerJobSelector.lexicographic_cell_less_than` — reusing the codebase's one
established tie-break rather than deriving a second. Erect bottom-up within a column.
Needs to be **stated in the story before implementation**, per `villager-ai-024`'s AC2
precedent ("the root cause is named in the story before the fix lands").

### D9 — May a scaffold cell overlap a cell the plan will later fill?

Because scaffolding is non-solid, **nothing prevents this today**: a scaffold cell and a
`PLANNED` blueprint cell can silently co-occupy one address, and the construction write
into that address would land with the scaffold still notionally there. Options:
**(a)** forbid overlap outright — a scaffold cell may only occupy an address with no
blueprint cell in any project; **(b)** allow, and dismantle that scaffold cell
immediately before the build job on the same address is claimed; **(c)** allow, and let
the completion write simply supersede it.

**Recommendation: (a).** It is the cheapest to reason about, it is checkable in one
place (`BuildProjectRegistry.project_at_cell(cell) != -1`), and it keeps AC5's "never
solid" guarantee free of an ordering hazard. (b) creates a claim-order race; (c) leaves
a scaffold record pointing at a solid cell.

### D10 — Top-down dismantle removes the cell the worker is standing on

AC3's "the worker rides it down" is under-specified in one place that matters. If the
worker stands **on** the top scaffold cell and dismantles **that** cell, it removes its
own support and lands on a non-point — the inverse of self-sealing, and the same
stranding class this story is fixing.

Options: **(i)** the worker descends one scaffold cell first, then dismantles the cell
**above** it — no new mutation point, the descent is an ordinary scaffold-to-scaffold
vertical step the amendment already makes legal; **(ii)** the worker dismantles its own
cell and is discretely moved down — a **fifth** ADR-0009 sanctioned mutation point.

**Recommendation: (i).** It uses the edge class this story adds, needs no ADR-0009
amendment at all, and is what makes "rides it down" literally true.

---

## OPEN RECOMMENDATION (not a decision) — retire `villager-ai-024`'s discrete mutation

Once scaffolding lands and is proven in the shipped game, **retire
`VillagerAi.climb_onto_self_sealed_cell()` and `VillagerAi._relocate_if_marooned()`** —
ADR-0009's sanctioned `current_cell` mutation points **(c)** and **(d)**.

**Rationale**: a teleport trick sitting beside real geometry is worse than either alone.
Two mechanisms that both answer "the builder is somewhere the graph cannot reach" will
diverge, and the discrete one will fire first and mask scaffolding's failures — exactly
the pattern that made the 27/30 stall read as a pacing problem for a full day.

**Countervailing evidence the ruling must weigh**: D4 option (ii) would *keep*
`_relocate_if_marooned()` deliberately, as the safety net for a bottom-up cancel with a
worker aboard. The two decisions are coupled and should be ruled on together.

**Requires**: TD/user ruling, an ADR-0009 amendment removing points (c) and (d) (or
demoting them to a named safety net), and a `control-manifest.md` update to the
"`current_cell` changes at EXACTLY four sanctioned points" bullet. **Not this story's
scope** — record only.

**We will know retirement was right if**: the payoff demo reaches a roofed enclosure
with `villager_unstuck` telemetry counters at **zero** for the build phase. If the
counters are non-zero after scaffolding lands, scaffolding is not covering a case it
should, and the retirement must wait.

---

## Dependencies

| Depends on | Why | Status |
|---|---|---|
| `villager-ai-024` | Names the rule, supplies the measured evidence and the correction this story acts on | Complete (2026-07-27) |
| `scene-007` (build-tool + project-lifecycle hosting) | The lever boots the **hosted** tool chain; an unhosted chain makes both levers untestable | Verify on disk before scheduling |
| `scene-008` (gates hosting) | Supplies the real-boot integration harness the lever reuses | Complete (2026-07-27) |
| `building-029` / `building-030` (tick loop, job queue) | Scaffold erection is a job on this loop | Complete |
| **ADR-0007 amendment ruling** | AC8 cannot be implemented before the TD rules | **RESOLVED 2026-07-27** — ADR-0007 **v1.1** landed §1a/§1b/§2a/§2b; `control-manifest.md` bumped to 2026-07-27. See *Technical Director Rulings* below |
| **D1 ruling (where a scaffold cell lives)** | Every other AC depends on it | **RESOLVED 2026-07-27** — Option (a), injected at `VillagerAi`'s delegation; see D1 below |
| **D7 value (`base_build_ticks_scaffold`)** | AC2's tick cost | **OPEN — user/design call.** Structure ruled; provisional `1`. Does not block implementation of D1–D6/D8–D10 |
| **D2 visual identity** | AC1 legibility | **OPEN — art call.** Rendering mechanism and owner ruled; does not block implementation |

## QA Test Cases

**AC1 — erected only when needed**
- Given: the real booted game, a room drawn at `wall_height = 1` (every cell reachable
  from original ground).
- Then: zero scaffold cells are erected, and the room still completes.

**AC1/AC10 — erected when needed**
- Given: the real booted game, a room drawn at the shipped `wall_height = 3`.
- Then: scaffolding is erected without player input; every wall cell reaches `BUILT`;
  at `DONE` the villager stands on a cell connected to the settlement ground graph.

**AC2 — a real job, faster than a wall**
- Given: a scaffold cell and a block cell, both claimed.
- Then: the scaffold cell completes in `base_build_ticks_scaffold` ticks, the block cell
  in `base_build_ticks_block`, and the former is strictly smaller. Neither completes in
  zero ticks.

**AC3 — top-down dismantle, worker rides it down**
- Given: a completed project with standing scaffolding and a worker on it.
- Then: scaffold cells are removed highest-first; at every intermediate step the worker
  stands on a cell that is still a graph point with at least one edge; the run ends with
  zero scaffold cells and the worker on the ground graph.

**AC4 — the 6-limit is config, not a literal**
- Given: an unreachable target 7 cells sideways from any support, with
  `scaffold_max_cantilever_cells = 6`.
- Then: no scaffold reaches it. Raise the knob to 7 in the test's own config instance and
  the same target is reached. Grep: no literal `6` governs cantilever anywhere in `src/`.

**AC5/AC6 — never solid, never a room**
- Given: a half-built house fully surrounded by scaffolding, with a bed inside.
- Then: `CandidateCellRules.is_roofed` is `false` for the interior; the interior is not a
  Room; `is_bed_sheltered()` is `false`. Complete the real roof and it becomes `true`.

**AC7 — seal prevention untouched**
- Given: `seal_prevention_test.gd` and `unstuck_watchdog_test.gd`, unmodified.
- Then: both pass at their current counts, and `git diff` shows zero changes to
  `villager_seal_prevention_gate.gd`.

**AC8 — the amendment is bounded**
- Given: a scaffold cell with air below; two stacked ordinary cells; a scaffold cell
  stacked on an ordinary standable cell.
- Then: the first is standable; the second pair is still never both standable; the
  vertical step in the third case is refused in both directions.

**AC9 — determinism**
- Given: the same world, villager, and job order, run twice.
- Then: identical scaffold cell sets, identical erection order, identical dismantle order.

---

## Technical Director Rulings (2026-07-27)

> **Authority**: technical-director. These rulings resolve **D1–D10** and the coupled
> retirement recommendation. The user's four rulings (AC1–AC4) and the defining
> non-solid property are **inputs**, not subjects — nothing below reopens them.
>
> **ADR-0007 has been amended by me, not by this story.**
> `docs/architecture/adr-0007-ai-pathfinding-navigation-room-analysis.md` is now **v1.1
> (2026-07-27)**, carrying **§1a** (scaffold standability), **§1b** (second occupancy
> source + the `after_write` clause + SC-INV-1), **§2a** (exactly one new edge class) and
> **§2b** (scaffold changes patch the graph on their own synchronous signal), plus new
> Validation Criteria, a performance budget, and a Godot 4.7 engine-verification note.
> `docs/architecture/control-manifest.md` is bumped to **Manifest Version 2026-07-27**
> with four new Feature-Layer bullets and one new Forbidden bullet.
> `.claude/docs/technical-preferences.md`'s ADR log records the amendment.
>
> I took the story's proposed wording as the base and **changed it in three places** —
> see D1 (the `after_write` finding), the §2a clause 2 finding, and §2b (the missing
> patch trigger). Those three are the load-bearing corrections.
>
> **Engine cross-reference (required, and it mattered)**: checked
> `docs/engine-reference/godot/` (4.7-stable pin) before ruling. This amendment
> introduces **no new engine API** — it adds candidate offsets and predicate branches to
> `AStar3D` calls whose surface was already 4.7-verified on 2026-07-11, and relies on
> default (synchronous) signal-connection flags, unchanged 4.4→4.7. Nothing here depends
> on a post-cutoff behaviour I could not verify against the pinned reference.

---

### D1 — Where a scaffold cell lives — **RULED: Option (a)**, with a named injection point

**Choice.** A Building-System-owned `ScaffoldRegistry` (`RefCounted`, mirroring
`FurnitureRegistry` exactly: keyed occupancy store, `Dictionary[Vector3i, …]` cell index,
one `scaffold_changed` signal, consumers re-enumerate and never read the payload). The
shared predicates gain **one explicit, defaulted parameter** carrying that occupancy
source. **Option (b) is rejected outright** — it redefines `CellContents.is_empty()`
project-wide and drags in storage, the mesher, the DDA pick and the save format for a
concept that is transient by construction.

**The injection point is `VillagerAi`'s existing one-line delegation**, not every call
site. `VillagerAi` holds the registry as an injected-tier `@export`-adjacent reference
(ADR-0001, wired exactly like `voxel_world`) and passes it into
`VillagerWalkabilityRules.is_standable(voxel_world, cell, scaffold_source = null)`. This
is not a stylistic preference — it is what makes the split *structural*:

- Every consumer that holds a `VillagerAi` becomes scaffold-aware **consistently and for
  free**: `VillagerNavGraph` (its `predicate_source`), `VillagerRescueTargetSearch`
  (same), the re-path filter. That matters: a scaffold-blind rescue-target BFS could never
  rescue a villager *onto* scaffolding and would read a villager *standing on* scaffolding
  as occupying a non-standable cell.
- Every consumer that calls the static class with only `voxel_world` — `BuildValidation`,
  `BuildValidationReachability`, `CandidateCellRules`, `Valley`'s boot invariant — stays
  **scaffold-blind by passing nothing**. AC6 holds because there is nothing to read, as
  the story argued.

**Reason.** Preserves ADR-0007's single-source-of-truth guarantee structurally; matches
the landed BV-1 precedent; and the resulting divergence between the two consumers is
**provably one-directional** — scaffold-awareness only ever *adds* standable cells and
edges, so the blind consumer always returns the more conservative verdict (fewer rooms,
fewer escape routes, more "sealed"). Scaffolding can never make a space read as a Room or
as unsealed. That asymmetry is why two different answers are safe here.

**The correction the story missed — and it is the sharpest one.** `would_trap_builder`
reads `VillagerAi._is_standable_after_write`, *not* the shared predicates. A villager
standing on a scaffold cell has **air beneath it**, so a scaffold-blind
`_is_standable_after_write` returns `false` at its very first line and
`would_trap_builder` returns `true` for essentially **every** write that villager
evaluates — firing the self-seal exemption continuously. **The `after_write` twins MUST
receive the same scaffold source.** The story's AC7 survives intact (zero lines change in
`villager_seal_prevention_gate.gd`), but its claim that "seal prevention needs no
scaffold-awareness" is true only of the *gate*, not of the gate's *inputs*. Making the
twins scaffold-aware **preserves** seal prevention; leaving them blind would break it.

**On the named `*_after_write` tech debt: do NOT unify.** Thread the scaffold parameter
through both shapes; leave the general overlay-predicate abstraction as the still-named,
still-deferred debt (BV-4 §6). Reason: unifying an override-mechanism and an
occupancy-source mechanism inside the story that first introduces the second one is how a
bounded amendment becomes an unbounded refactor, and the seal-prevention path is the worst
possible place to discover that mid-story.

**Performance clause (binding).** Scaffold membership must be an **O(1) keyed lookup**.
**No support, cantilever, or connectivity search may ever run inside a predicate** — those
are erection-time planning rules. `is_standable` is called ~47k times per graph build and
on every patch; a structural search there multiplies boot build by structure size.
Measured budget: **≤ +5% on the QQ3 patch-average (0.46 ms)** before this story may close.

**Forbids**: any `block_type_id` for scaffolding; any passability flag on `CellContents`;
a `ScaffoldRegistry` autoload/singleton/module-global; any scaffold read anywhere in
`src/build_validation/` or in the mesher; a second implementation of standability or
step-legality; any structural search inside a predicate.

---

### D2 — What the mesher sees — **RULED (technical): Building System owns a pooled presentation tier. Visual identity LEFT TO THE USER.**

**Choice.** Because D1 keeps scaffolding out of `VoxelWorldGrid`, the chunked mesher
never sees it — correct, and it must stay that way. Scaffolding is rendered by a
**Building-System-owned per-cell pooled `MeshInstance3D` tier**, mirroring
`GhostPreview._blueprint_ghost_pool`'s exact shape (`Dictionary[Vector3i, entry]`, pooled,
created/hidden rather than freed), driven by `ScaffoldRegistry.scaffold_changed` with a
re-enumeration — never a signal payload read. **Ownership is Building System, not
Presentation**: Building System already owns the only per-cell pooled world-space visual
mechanism in this codebase, and the scaffold's lifetime is exactly a build project's
lifetime.

**Material tier is distinct from a ghost.** Scaffolding is *built, real* geometry, not a
preview — it must not reuse the translucent ghost tint, or the player will read it as
"planned" and expect it to become a wall.

**Named escape hatch (not built now)**: if concurrent scaffold cell count ever exceeds
**256**, switch this tier to a single `MultiMesh` instance. At the cantilever-bounded
sizes this story can produce (≤ `scaffold_max_cantilever_cells` × structure height per
project), pooled instances stay far inside the 2000-draw-call budget.

**LEFT TO THE USER**: the visual identity — silhouette, material, colour, whether it reads
as timber poles, planks, or lashed frame. That is an art-direction call and the user is
the art authority; the story already scoped it out. My ruling constrains only *where the
pixels come from*, not *what they look like*. **"Renders as nothing" is not an acceptable
outcome and is not among the options.**

**Forbids**: a `BlockAppearanceConfig` entry or any terrain block type for scaffolding;
the mesher or any chunk-meshing code reading the scaffold registry; one un-pooled node
created per cell per change; reusing the ghost's translucent preview material.

---

### D3 — Ownership — **RULED: Option (a), its own entity, linked by owner id**

**Choice.** A scaffold structure is its own `BuildProject` with a **third
`BuildProject.Kind` value (`SCAFFOLD`)** and an `owner_project_id` link field, registered
in the same `BuildProjectRegistry`. Its cells are `BlueprintCell`s of a **third
`Category` value (`SCAFFOLD`)**, and a completing scaffold job routes to
`ScaffoldRegistry` **instead of** `VoxelWorldGrid` — the identical routing
`Category.FURNITURE` → `FurnitureRegistry` already established.

**Reason.** Option (b) is genuinely circular, as the story found: `recompute_state()`
reaches `DONE` iff every tracked cell is `BUILT`, and `DONE` is the dismantle trigger. It
also demands a per-cell exception inside a method whose doc comment states the rule with
no exceptions — the invisible special case that produces the next `villager-ai-024`. A
third `Kind` is cheap here (`kind` is read in exactly three places) and buys a real
guarantee for free: `BuildProjectRegistry.assign_cells` already gates grouping on
`existing_project.kind == kind`, so a scaffold project can **never** merge into the
structure it serves.

**Save/load — RULED, and against the "don't persist it" instinct: scaffolding IS
persisted.** `ScaffoldRegistry` gets `serialize()`/`deserialize()` under ADR-0012's
per-system contract, and scaffold projects persist like any other project. Reason: a
villager standing on scaffolding at save time would, on a non-persisting load, wake up on
a cell that no longer exists — **the exact stranding class this story exists to abolish,
reintroduced across the save boundary.** The payload is trivial (cells + owner id). "It's
transient so skip it" is precisely the reasoning that would cost a bug report.

**Forbids**: adding scaffold cells to the owning project's `cells`; any scaffold exception
branch in `recompute_state()`; a scaffold project that outlives its owner (its dismantle
is triggered by the owner reaching `DONE`, or by the owner's cancel).

---

### D4 — Cancel with a worker aboard — **RULED: Option (i)**

**Choice.** A player cancel checks the scaffold structure for occupancy first (any
villager whose **body-column** — `VillagerWalkabilityRules.body_column`, not its feet
cell — intersects any scaffold cell of that structure). Occupied ⇒ fall back to the
**top-down, worker-ridden dismantle** of AC3. Unoccupied ⇒ the fast **bottom-up collapse
with no worker**, exactly as ruling 3 permits.

**Reason.** This project has **no gravity** — villagers are `Area3D`-only with no
colliders (ADR-0004, technical-preferences). A Minecraft player falls; this villager does
not. It would simply be left on a cell that stopped being standable: a zero-edge graph
point. Option (ii) knowingly reintroduces the bug the story exists to fix and makes the
fix depend on the safety net we intend to delete. Option (iii) spends a **fifth** ADR-0009
sanctioned `current_cell` mutation point on a case that needs no mutation at all. Ruling 3
says a cancel **MAY** collapse bottom-up — permission, not obligation — and (i) honours it
in the common case (nobody on the scaffold) while never paying for it in the rare one.

**This ruling also decouples D4 from the retirement question**: the bottom-up-with-worker
path never occurs, so `_relocate_if_marooned` is no longer needed as a cancel safety net.
The story's "countervailing evidence" is now retired. See the retirement ruling below.

**Formalised as ADR-0007 §1b invariant SC-INV-1**: *no scaffold cell is ever removed while
any villager's body-column occupies it.* This is load-bearing, not hygiene — once
`would_trap_builder` counts scaffold cells as escape routes (D1), an escape route that can
be yanked away **would** weaken seal prevention. SC-INV-1 is what keeps it honest.

**Forbids**: options (ii) and (iii); a fifth sanctioned mutation point; any dismantle path
that removes a cell occupied by a body-column; a feet-cell-only occupancy check.

---

### D5 — Who detects the unreachable cell — **RULED: Option (b), with a named seam**

**Choice.** F2's silent pre-claim reachability skip becomes a **reporting** skip. Concretely:

1. `VillagerJobSelector.select_job` returns, alongside its existing result, the
   **deterministic list of candidates it probed and found unreachable** (it already
   computes exactly this set inside its round loop and throws it away). `select_job` stays
   a **pure static function** — it reports nothing itself and gains no dependency.
2. `VillagerAi` forwards that list to the existing `job_queue.report_unreachable(cell)`
   seam, throttled by the **already-landed** `_unreachable_retry_after_tick` cooldown map
   at the already-landed `unreachable_retry_ticks` (= 20) cadence, so a report can never
   storm per tick.
3. The **Building System** subscribes to the existing `job_reported_unreachable` signal
   and owns the erection response. **The AI detects; the Building System builds.**

**Reason.** (b) reuses a landed seam, a landed cadence, a landed signal and a landed
throttle rather than inventing a fourth reachability concept, and it makes
`BlueprintCell.is_unreachable`'s existing pulsing-orange ghost tint honest at the same
time. (c) is a periodic Building-System sweep over every `PLANNED` cell — an unbounded
per-tick cost and a second, competing definition of "reachable". (a) is (c) wearing the
job queue's clothes.

**This ruling explicitly amends F2's documented "silent" contract.** `VillagerAi
._report_job_unreachable`'s doc comment currently states — correctly, today — that it is
"never [called] for F2's own silent pre-claim reachability skip". That sentence must be
rewritten to record this ruling and its date. A doc comment that contradicts the code is
how `villager-ai-024` lost a day.

**Bound the response (required).** A cell can be unreachable for reasons scaffolding
cannot fix — walled off, or no support within the cantilever limit. The erection planner
must be allowed to return **"no plan"**, leave the cell flagged unreachable, and **not
re-plan** until the flag clears. Never erect a structure that does not make the target
reachable; never loop.

**Forbids**: options (a) and (c); `select_job` acquiring a job-queue reference or emitting
anything; Villager AI erecting scaffolding itself; an unthrottled per-tick report; a
scaffold plan produced for a cell no plan can serve.

---

### D6 — What the 6-limit measures — **RULED (mechanics). The value 6 is the user's, already ruled.**

**Choice, and it corrects the story's recommendation.**

1. **Metric: horizontal Chebyshev — `max(|Δx|, |Δz|)`, with Y excluded.** The story
   proposed reusing `VillagerJobSelector.chebyshev_distance`, but that function is **3D**
   (`maxi(|dx|, maxi(|dy|, |dz|))`). Using it would let height enter the limit and would
   silently convert ruling 4's *overhang* cap into a *height* cap — flatly contradicting
   "scaffold height is unbounded by this rule". Use a distinct horizontal helper, or the
   same function with Y zeroed at the call site, and say which in the code.
2. **Support**: a cell is *directly supported* if the cell directly below it is **solid**
   (terrain or a Built block — never another scaffold cell's "solidity", since scaffolding
   is never solid). A scaffold cell is *supported* if it is directly supported, or if the
   cell directly below it is a supported scaffold cell, or if it is horizontally adjacent
   at the same Y to a supported scaffold cell.
3. **Cantilever distance** is a plan-time BFS property: **0** for a cell with direct
   support or with a supported scaffold cell directly below it; otherwise **1 + the
   minimum** over its same-Y horizontally-adjacent supported scaffold cells. A vertical
   step never increases it (height is free); a horizontal step always does. Constraint:
   `cantilever_distance ≤ scaffold_max_cantilever_cells`.
4. **Config**: `scaffold_max_cantilever_cells: int = 6` on its own `ScaffoldConfig`
   `ConfigResource` (ADR-0002 one-config-per-module), safe range **1–32** with a
   `validate()` clamp — headroom for the progression stat ruling 4 requires. The **6** is
   the user's ruling, transcribed, not mine.

**Reason.** Ruling 4 fixed the intent (overhang, config, raisable); the mechanics had to
be pinned before AC4's "raise the knob to 7 and the same target is reached" test can even
be written. Computing it at plan time, never in a predicate, is what keeps D1's O(1)
clause true.

**Forbids**: 3D Chebyshev; Euclidean or Manhattan; any literal `6` governing cantilever
anywhere in `src/`; treating a scaffold cell as *solid* support; evaluating cantilever
inside `is_standable`/`is_step_legal`.

---

### D7 — `base_build_ticks[scaffold]` — **LEFT OPEN. This one is the user's.**

**Not ruled, deliberately.** How fast a scaffold cell goes up is a pacing/feel value, and
the user has been ruling on exactly this class of question all day. Ruling 2 already fixed
the two things that are *not* negotiable — a real job, never zero — and the rest is taste.

**What I DO rule (the structure it must land in):**
- A third `BlueprintCell.Category` value (`SCAFFOLD`) and a third branch in **both**
  `ConstructionTickLoop.required_ticks_for` and `required_demolition_ticks_for` (both are
  `match` with a `_` default — one line each).
- Two new `ConstructionTickLoopConfig` fields, `base_build_ticks_scaffold` and
  `base_demolition_ticks_scaffold`, each with `_MIN`/`_MAX` constants and a `validate()`
  clamp, siblings of the four that exist. Two new rows in the building-system GDD's Tuning
  Knobs table.
- **Hard technical constraints on whatever value the user picks**: `≥ 1` (ruling 2 —
  never zero, nothing appears from nothing) and **strictly `< base_build_ticks_block`**
  (AC2). The strict-inequality property is asserted by the AC2 test, **not** enforced as a
  BLOCKING cross-value invariant in `validate()` — ADR-0002 reserves that tier for
  GDD-declared invariants, and this is not one.
- **Provisional until the user rules**: `base_build_ticks_scaffold = 1`,
  `base_demolition_ticks_scaffold = 1`, range 1–20 to match siblings. Marked provisional
  in the config doc comment, in the GDD row, and in the commit body.

**My non-binding read, for whenever the user does rule it**: 1 tick (0.25 s at the shipped
4.0 ticks/sec) may be *too* fast to read as construction at all — the player may just see
scaffolding blink into existence, which is what ruling 2 was guarding against. **2** would
still be half a wall cell and would actually be visible. But that is a feel judgement, and
it is the user's.

---

### D8 — The erection route — **RULED: fully specified, deterministically**

AC9 requires this to be pinned before implementation, so it is pinned here.

1. **Target = a staging cell, not the blueprint cell's own address.** For an unreachable
   blueprint cell `C`, the plan targets a cell `A` such that `A` is **orthogonally**
   adjacent to `C` in X/Z with `|Δy| ≤ 1`. **Orthogonal only** — a diagonal `A` would
   invoke `is_step_legal`'s flanking rule and make reachability depend on two more cells
   for no gain. `A` must read empty in `VoxelWorldGrid`, carry no blueprint cell (D9), and
   not already be scaffold.
   *This clarifies AC1's "erects scaffolding exactly there": scaffolding is erected where
   it makes `C` reachable — beside `C` — never at `C`'s own address. That is the only
   reading consistent with ruling 1 ("only where a cell is unreachable") and with D9.*
2. **Column choice.** Prefer the column **directly below `A`**, descending to the first
   cell whose below-neighbour is solid (cantilever 0). If no support exists in that column
   within the world's vertical bounds, use the **nearest supported column by horizontal
   Chebyshev** within `scaffold_max_cantilever_cells`, and connect with a same-Y
   cantilever run.
3. **Selection order among valid plans**: (1) fewest scaffold cells; (2) smallest maximum
   cantilever distance; (3) `VillagerJobSelector.lexicographic_cell_less_than` on `A` —
   the codebase's one established tie-break, reused, never a second one.
4. **Erection order**: strictly ascending Y within a column, then the cantilever run,
   emitted from an **explicitly sorted** list.
5. **The plan is a pure function of (world state, target cell)** — never of the requesting
   villager. Two villagers asking about the same cell must get the same plan.

**Forbids**: RNG, wall-clock, frame counters; relying on `Dictionary` iteration/discovery
order for any emitted order; per-villager state in the planner; a diagonal staging cell; a
second tie-break convention.

---

### D9 — Overlap with a planned cell — **RULED: Option (a), forbid it**

**Choice.** A scaffold cell may only be created at an address that (i) reads **empty** in
`VoxelWorldGrid`, (ii) has **no blueprint cell in any non-`SCAFFOLD` project** —
`BuildProjectRegistry.project_at_cell(cell)` returns `-1` or resolves to a `SCAFFOLD`-kind
project — and (iii) holds **no furniture** (`FurnitureRegistry.has_occupant`). Checked in
**one** place, at plan time.

**Reason.** (b) creates a claim-order race between a dismantle job and a build job on the
same address. (c) leaves a scaffold record pointing at a cell that is now solid — an
occupancy source disagreeing with the voxel world, which is the failure mode D1's whole
shape exists to avoid. (a) costs one O(1) lookup and makes AC5's "never solid" guarantee
free of any ordering hazard. It composes cleanly with D8: the staging cell is beside the
target, so the constraint is satisfiable in practice, not merely safe.

*(iii) is belt-and-braces — furniture is passable, so a scaffold over a bed harms nothing
physically — but a scaffold cell sharing an address with a bed is a bookkeeping question
nobody should have to answer at 2am.*

**Forbids**: options (b) and (c); a construction write landing on an address that holds a
live scaffold record; performing this check anywhere but the plan-time gate.

---

### D10 — Dismantling the cell underfoot — **RULED: Option (i)**

**Choice.** The worker **descends one scaffold cell first** — an ordinary
scaffold-to-scaffold vertical step that ADR-0007 §2a now makes legal — and then dismantles
the cell **above** it. Dismantle order is strictly **descending Y**, ties broken
lexicographically on `(x, z)`.

**Reason.** It uses the edge class this story adds instead of a teleport, needs **no**
ADR-0009 amendment and no fifth mutation point, and is what makes AC3's "the worker rides
it down" literally rather than figuratively true. Option (ii) buys nothing and costs a
permanent widening of the discrete-mutation surface at the exact moment we are trying to
shrink it.

**Forbids**: option (ii); a fifth sanctioned `current_cell` mutation; dismantling any cell
inside the worker's own body-column (SC-INV-1); an ascending or unordered dismantle.

---

### COUPLED RULING — retiring `climb_onto_self_sealed_cell` / `_relocate_if_marooned`

**RULED: retire on evidence, not on landing. Not in this story. ADR-0009 is NOT amended today.**

The story is right that two mechanisms answering "the builder is somewhere the graph
cannot reach" will diverge, and that the discrete one firing first is what made a stranding
bug read as a pacing bug for a full day. It is **not** right that the cure is to delete the
net the moment the geometry lands — that is a single-step migration on the exact code path
whose failure mode is an unrecoverable villager, validated by a demo that has never yet
completed end to end.

**Two steps.**

- **Step 1 (with this story).** ADR-0009 points **(c)** and **(d)** stay, behaviourally
  unchanged. Each gains a **telemetry counter** in the existing `villager_unstuck` family,
  and **Lever 3's report must record both counters**. The masking objection is answered not
  by deletion but by **loudness**: the anti-vacuity levers assert both counters are
  **ZERO** for the build phase, so any firing **fails the lever**. A safety net that fails
  the build when it fires cannot hide anything.
- **Step 2 (a separate story, not this one).** After **two consecutive** green end-to-end
  payoff-demo runs with both counters at zero, delete both methods, amend ADR-0009 back to
  two sanctioned mutation points, and update `control-manifest.md`'s "EXACTLY four
  sanctioned points" bullet. Not before.

**D4's ruling removes the story's own countervailing evidence**: with cancel-with-worker
falling back to top-down dismantle, `_relocate_if_marooned` is no longer needed as a cancel
safety net. The two rulings are consistent — the net is kept for *evidence*, not for
*function*.

**We will know this was right if**: both counters read zero across the two runs and the
deletion in Step 2 changes no test's behaviour. **We will know it was wrong if** a counter
fires — in which case scaffolding is failing to cover a case it should, and the failure is
visible on the first run instead of hidden for a day.

---

### What I left to the user, and why

| Item | Why it is not mine |
|---|---|
| **D7's tick values** (`base_build_ticks_scaffold`, `base_demolition_ticks_scaffold`) | Pacing/feel. Ruling 2 fixed the constraints; the number is a design call. Structure is ruled, provisional 1/1 is marked provisional. |
| **D2's visual identity** (silhouette, material, colour, tier) | Art direction. I ruled *where the pixels come from* (pooled Building-System tier) and that "invisible" is not an option; what it looks like is the user's. |
| **D6's value `6`** | Already the user's ruling (AC4). I ruled only the metric, the support definition, the config shape and the safe range. |

Everything else in D1–D10 is a technical decision with a defensible right answer, and
leaving those open would only have cost another day.

### We will know these rulings were right if

- **Lever 1 and Lever 2 both pass on the real booted game**, and Lever 3's deletion probe
  reproduces the empty `find_path` with the scaffold call site removed.
- `seal_prevention_test.gd` (13/13) and `unstuck_watchdog_test.gd` (12/12) pass
  **unchanged**, and `would_trap_builder` does **not** start firing once villagers stand on
  scaffolding — the D1 `after_write` correction is the thing that makes this a real test.
- Nav patch-average cost stays within **+5%** of the QQ3 baseline.
- `src/build_validation/` still greps clean of any scaffold reference, and a half-built
  house wrapped in scaffolding still classifies as **not** a Room.
- Both `villager_unstuck` counters read **zero** for the build phase — which is what
  unlocks the retirement story.

---

## First implementation pass — PARKED, not landed (2026-07-27)

A full pass was written and then deliberately backed out. The gate was red and
the work regressed a previously green test, so it was not committed. The whole
diff plus every new file is preserved verbatim at
`production/parked/story-034-scaffolding-WIP.patch` — nothing is lost, and the
next pass starts from it rather than from scratch.

### What the pass actually produced

In the parked patch, written and unit-tested: the ADR-0007 nav amendment
(sections 1a, 1b, 2a, 2b), `ScaffoldRegistry`, `ScaffoldConfig`, the erection
planner (D8/D9/D6), the dismantle ordering (D10/D4/SC-INV-1),
`BlueprintCell.Category.SCAFFOLD` / `BuildProject.Kind.SCAFFOLD` / tick-loop
routing, the D5 detection wiring, both telemetry counters, and a placeholder
renderer class.

NOT done, and this is half the reason it could not land: the production wiring
into `Valley.tscn` / `valley.gd` was deferred, so the erection coordinator never
runs in the real game. The levers passed against the production classes called
directly, never through the hosted boot chain.

### Two real defects found and fixed during triage — keep these in the next pass

Both fixes are in the parked patch.

1. **The same-column gate broke its own binding promise.** ADR-0007 section 1b
   states that a caller passing no scaffold source observes EXACTLY
   pre-amendment behaviour. The gate as written returned `false` for every
   same-column pair without scaffolding, but the predicate previously fell
   through to the `|dy| <= MAX_STEP_HEIGHT` check and returned `true`. The TD
   rationale (two stacked cells can never both be standable, so the case never
   arises) holds only for callers that check standability first, and not every
   caller does. Correct gate: both endpoints scaffold means legal; exactly one
   means illegal (this is what actually closes general climbing); neither falls
   through to pre-amendment behaviour.
2. **The same defect existed a second time**, copied verbatim into
   `villager_ai.gd`'s `_is_step_legal_after_write`. Those after-write twins feed
   `would_trap_builder`, so the builder believed far more writes would trap it
   than actually would.

Fixing both turned `walkability_predicates_test` (18/18) and the new
`scaffolding_reachability_levers_test` (5/5) green.

### The defect that stopped the pass — unresolved

`wall_room_no_plateau_test`, villager-ai-024's own regression test, drops from
30/30 to 27/30 with an entire CORNER COLUMN stuck: `(1004, 6, 1008)`,
`(1004, 7, 1008)`, `(1004, 8, 1008)`, all `state=0`, all `claimed_by=-1`. Note
the shape differs from story-024's original symptom, where only the top layer
hung.

Ruled out during triage: the job-selector change is purely additive (it records
probed-unreachable cells, it does not alter selection order), and
`report_unreachable` only sets a flag that `claim_job` clears and that never
gates listing.

Prime suspect, NOT confirmed: the new same-column escape loop added to
`would_trap_builder` reports that an upward escape exists onto the very block
being placed. That escape is real only through story-024's sanctioned discrete
climb, not through a legal step, so seal prevention now permits writes it used
to refuse, and one of those writes seals off the corner approach. If that is
right, the fix is to require the vertical escape target to be a scaffold cell
rather than merely standable-after-write.

### Next pass should

1. Start from the parked patch; it already contains both triage fixes.
2. Resolve the corner-column regression BEFORE adding anything new.
3. Wire `ScaffoldRegistry` / `ScaffoldErectionCoordinator` / `ScaffoldPresentation`
   into `Valley` so the levers run through the hosted boot chain.
4. Add the live dismantle orchestrator on project DONE and on cancel.
5. Then the payoff-loop demo and the telemetry-zero proof.

### Unrelated observation, recorded not acted on

`reachability_property_corpus_test` measured 60.83s against its own 60s ceiling
on an otherwise idle machine, with the tree restored to the last green commit.
The same corpus measured 45.78s earlier today on identical code. That is machine
load drifting, not a code regression. Its Cut-Lever Policy would permit reducing
`PAIRS_PER_SEED`, and that lever was deliberately NOT pulled: coverage should not
be traded away for a transient. Worth watching; if it settles above the ceiling
on a genuinely quiet machine, escalate to the TD as the policy directs.

---

## SC-INV-2 did NOT fix the roof — hypothesis refuted by measurement (2026-07-28)

Second payoff-demo run, with SC-INV-2 and the derived bands in place.

    room walls: all 30 cells reached BUILT after 16.2s real time
    roof construction result: 10 / 12 cells reached BUILT
    D10 check: 5 SLEEPING episode(s)
      (992,10,1004) (994,10,1002) (992,10,1003) (992,10,1001) (994,10,1003)

Walls 30/30 again — reproducible, so scaffolding's win is real. Everything else
is identical to the run before the fix: same roof count, same five sleeps, same
five cells. The evidence PNGs came out BYTE-IDENTICAL to the previous run, which
incidentally confirms the determinism requirement holds end to end.

**So the hypothesis was wrong.** Dismantle taking away the builder's descent is
not what stalls the roof. SC-INV-2 stays, because it provably defers dismantle
while a builder is above the structure and its test passes on its own terms —
but it was not this defect, and claiming otherwise would be taking credit for a
coincidence.

THREE REFUTED HYPOTHESES IN ONE NIGHT: the vertical escape loop, the
served-cells latch, and now the dismantle trigger. Every one was plausible from
reading the code. Every one fell to a bisect. Reading has not identified a
single real cause tonight; measurement has identified all of them. That is worth
more as a working rule than any of the individual fixes.

### The defect, described more precisely than before

y=10 is ON TOP of the roof plane — walls run 6..8, the roof is drafted at 9. The
villager is therefore standing on built roof cells and cannot get down. The two
missing roof cells are almost certainly the interior ones, which can only be
reached by standing on already-built roof: exactly the "cannot chain two
extensions" geometry `villager-ai-024` named for walls, one storey higher.

### The next diagnostic, to run BEFORE writing any code

Two prints and one run:

1. `VillagerUnstuckTelemetry.get_self_seal_climb_total()` and
   `get_marooned_relocation_total()` at the end of the demo. Non-zero means the
   villager reached y=10 through the ADR-0009 climb mutation rather than through
   scaffolding — which would mean scaffolding never served the roof at all and
   the erection trigger simply never fires for roof cells.
2. The `ScaffoldRegistry` contents during the roof stage. Empty there would say
   either the persistence gate (3 reports) is never satisfied for roof cells, or
   `plan_for_target` finds no supported column within the cantilever limit above
   a finished room.

The corrected demo label is what makes this readable at a glance: "a villager
asleep above the build site is stranded, not merely tired", with the cell height
printed. The old wording is precisely what made the same symptom read as a
pacing question a day earlier.

---

## MEASURED: what scaffolding actually contributes, and what it does not (2026-07-28)

Two diagnostics were added to `tools/payoff_loop_demo.gd` and one control run
was performed, because the previous claim ("scaffolding brought the walls from
27/30 to 30/30") rested on a before/after coincidence rather than on evidence.

### The diagnostic run

    room walls: all 30 cells reached BUILT after 16.3s
    roof construction result: 10 / 12 cells reached BUILT
    scaffold cells standing at roof stage: 0 []
    ADR-0009 climb mutations this run: self_seal_climb=40 marooned_relocation=9

### The control run — erection response disabled, everything else identical

    room walls: WAIT CAP (220s) hit with 27/30 cells BUILT
    construction result: 27 / 30 wall cells reached BUILT
    roof construction result: 9 / 12
    bed construction result: 0 / 2

### What that settles

**Scaffolding's contribution is real and is exactly the last three wall cells.**
Disable erection and the demo falls back to precisely the historical 27/30;
enable it and the room closes. That is now measured, not inferred from a
before/after pair — which is what I should have had before saying it.

**The roof gets no scaffolding at all.** Zero cells standing at the roof stage,
so the roof stall is not a dismantle problem and never was: the erection trigger
simply never fires for roof cells. This is the open defect, and it is now
located precisely rather than suspected.

**The ADR-0009 retirement criterion is nowhere near met.** The TD ruled that the
climb mutations retire on evidence — the counters reading zero — not on
scaffolding landing. They read 40 and 9. Both mechanisms are carrying the build
today, and scaffolding is the smaller contributor. Retiring the climb hack now
would take the walls back below 27/30.

### Why the roof gets nothing — the next thing to check

A roof cell's blueprint is reported unreachable like any other, so either the
persistence gate never accumulates three reports for it, or
`ScaffoldErectionPlanner.plan_for_target` finds no supported column within the
cantilever limit for a cell suspended over a finished room's interior. The
second is the more likely of the two: a roof cell's support would have to rise
from inside the room the walls just enclosed, and the planner prefers the column
directly below the target.

Cheapest next measurement, and it should come before any code: print
`plan.has_plan()` and the report count per roof cell in
`_on_job_reported_unreachable`, and run once. Reading the planner will not
settle it — three hypotheses were read confidently tonight and all three were
refuted by bisect.

---

## The roof stall is a MISSING DOOR, not a scaffolding defect (2026-07-28)

One print, one run, and the answer is not what any of the three earlier
hypotheses guessed.

    SCAFFDIAG cell=(993, 9, 1002) seen=3 PLANNED=true cells=1
    SCAFFDIAG cell=(993, 9, 1003) seen=3 PLANNED=true cells=1
    scaffold cells standing at roof stage: 0

Exactly TWO roof cells ever report unreachable — the two interior ones, which
matches 10/12 precisely. Both clear the persistence gate. Both PLAN
SUCCESSFULLY. And yet nothing is standing when the roof stage reports.

The coordinates settle it. The demo's four wall segments enclose x 992..994,
z 1001..1004, so the interior is the single column x=993, z=1002..1003 — exactly
where the two missing roof cells are. Their scaffold support would have to stand
INSIDE that interior.

And the interior is sealed. The 30/30 wall success closed the room completely:
four segments, no gap, **no door**. No villager can get in, so the scaffold cell
is never built, so the roof over the middle is never finished.

**This is not a scaffolding defect.** Erection detected the need, cleared its own
gate, and produced a valid plan. The structure it planned simply sits in a room
nobody can enter. Scaffolding behaved correctly throughout.

### What it actually says about the game

A room with no door is not a house. Real settlements leave a doorway, and this
demo never did — it drew four solid walls because that was the simplest thing to
draft. The building system has no door concept yet, and until it does, the demo
should leave a deliberate one-cell gap at ground level in one segment. That is a
DEMO change, not a system change, and it is the smallest thing standing between
this tool and a finished roofed room.

Worth noticing: this defect was invisible while the walls stalled at 27/30,
because an unfinished wall IS a doorway. Fixing the walls is what sealed the
room. Every fix tonight has exposed the next problem one layer up — walls, then
descent, then entry.

### Next step, specified

Give the demo's wall drafting a doorway: skip the ground-level cell of one
segment (or draft that segment as two pieces with a one-cell gap), report the
door cell explicitly so the frame can be read, and re-run. Expect the roof to
complete and the bed/claim/sleep stages to become reachable for the first time.

---

## A doorway makes it WORSE — the system needs a door concept (2026-07-28)

The specified next step was to give the demo a doorway. Done, through the real
`RemovalTool` (erasing a drafted ground cell is exactly what a player does after
drawing a room), and measured:

    doorway at (992, 6, 1002): erased
    room walls: WAIT CAP (220s) hit with 24/29 cells BUILT
    roof construction result: 9 / 12
    bed construction result: 0 / 2

Against 30/30 with no doorway. **The doorway made the walls worse**, and the
change was reverted rather than kept.

### Why, and why it matters more than the demo

The most plausible reading, and it fits the numbers: with an opening the villager
walks INSIDE and builds from within. As the remaining cells would close it in,
seal prevention correctly refuses them — a builder must not trap itself. It has
no rule that says "leave, then finish from outside", so the last cells never get
built at all. Without a doorway it worked simply because the villager was never
inside in the first place.

**So the finding is not "the demo lacks a door". It is that the building system
has no DOOR CONCEPT.** An improvised gap is not a door; it is a hole that
disorders the build. A real door would be a component that

 - room recognition treats as a legal opening rather than a breach, so an
   enclosed room stays a Room with a door in it;
 - the build plan knows to place LAST and from OUTSIDE, so a builder is never
   inside a closing shell;
 - seal prevention can reason about — right now it can only see that a write
   would trap someone, never that a doorway means it would not.

Until that exists, a finished room is either sealed (no entry, interior roof
unbuildable) or open (builder trapped inside a shell it refuses to close). Both
states are reachable today and neither is a house.

### What still stands from this line of work

Scaffolding itself remains correct and its contribution is still the measured
27/30 -> 30/30 on the sealed-room geometry. Nothing here retracts that. The roof
remains unfinished for a reason now fully understood, and the fix is a system
story rather than a tool tweak — which is exactly why the demo change was
reverted instead of tuned until the numbers looked better.

### Recommended next story

`building-system: doors` — a door component with the three properties above.
Sized as a real story, not a patch. It blocks: the payoff loop's roof, therefore
the bed, therefore `scene-009`, therefore milestone criterion #5 in the product.

---

## CORRECTION: my explanation for the doorway regression was unsupported (2026-07-28)

The section above says the doorway run failed because "the villager walks INSIDE
and builds from within" and seal prevention then refuses the closing cells. I
wrote that as "the reading that fits". It does not fit — I checked the position
data afterwards and it contradicts me:

    villager after construction wait: state=3 pursued_activity=1
    current_cell=(992, 9, 1004)

y=9 with walls at 6..8 is ON TOP of the wall, not inside the room. The villager
was never trapped in a closing shell. My explanation was a guess wearing the
clothes of an analysis, and it is now in the permanent record, so it gets a
correction rather than a quiet edit.

**What remains measured and true:**
 - Without a doorway: 30/30 walls, room sealed, the two interior roof cells need
   scaffolding INSIDE, nothing can get in, roof stops at 10/12.
 - With an improvised doorway: 24/29 walls. Worse. Reverted.
 - Scaffolding's own contribution: 27/30 without erection, 30/30 with it.

**What is NOT established: why the doorway made the walls worse.** Candidates,
none tested: erasing a drafted cell may have re-partitioned the project or
changed job ordering; the missing cell may have removed support the scaffold
planner relied on; seal prevention may evaluate differently around an opening.
Each is a hypothesis, and tonight's score for hypotheses formed by reading is
0 for 4.

**The door-concept conclusion still stands, but on the OTHER evidence** — the
sealed-room measurement, which is direct: a finished room cannot be entered, and
its interior roof therefore cannot be scaffolded. That does not depend on
knowing why the improvised gap misbehaved. If anything, a gap that makes things
worse in a way nobody can yet explain is a further argument that "leave a hole"
is not a door.

**Before the door story is written**, the doorway regression should be bisected
like everything else tonight was: erase the cell but do NOT release, release but
erase a different cell, and so on, until the boundary is named. Writing a door
component on top of an unexplained regression would build on sand.

---

## The doorway regression, bisected: it is the OPENING, not the erase (2026-07-28)

The correction above set a precondition — bisect this before writing a door
story, or the story builds on sand. Done, in one run.

Same project mutation, different geometry: erase the TOP cell of a wall column
instead of the GROUND cell. One drafted cell removed either way; only one of them
creates an opening a villager can walk through.

    BISECT erase TOP cell (992, 8, 1002): erased
    room walls: all 29 cells reached BUILT after 15.6s

Against 24/29 when the erased cell was at ground level.

**So the erase itself costs nothing.** Removing a cell from a released project
does not re-partition it, does not disorder the jobs, and does not starve the
scaffold planner — 29/29 in 15.6s is the same speed as the untouched 30/30 run.
**The cost is the ground-level opening**, i.e. the fact that a villager can now
get inside.

That puts my original explanation back on the table — but this time on measured
ground rather than as a guess. What refuted it earlier was the villager's
position at the END of the wait (y=9, on top of a wall); that says nothing about
where it was DURING the build, and I over-read it. The honest state is: an
opening at ground level changes builder behaviour in a way that costs five wall
cells, and the mechanism inside that window is still unmeasured.

**Next measurement, one print:** log which cells remain unbuilt in the doorway
run, and the villager's cell each time the wall count stalls. If the unbuilt
cells cluster around the doorway, or the villager sits inside during the stall,
the "builds from within, then correctly refuses to seal itself in" reading is
confirmed and the door story can specify the fix precisely. If they do not, there
is a third mechanism nobody has proposed yet.

**What this already settles for the door story:** a hole is not a door, and now
there is a number attached to it. An opening that a builder can enter is not a
neutral gap in a wall — it changes how the wall gets built, measurably and for
the worse. A door component therefore cannot be "a cell we skip"; it has to be
something the build plan and the seal-prevention rule both understand.

---

## The stall window, measured: the builder is STRANDED ON TOP, never trapped inside (2026-07-28)

One print, one run, and it settles what two readings of mine got wrong in
opposite directions.

    STALLDIAG room walls villager=(993, 9, 1004) state=5 pending=5
      [(994,6,1004) (994,7,1004) (994,8,1004) (992,7,1002) (992,8,1002)]
    STALLDIAG room walls villager=(992, 9, 1003) state=5 pending=5  [same]
    STALLDIAG room walls villager=(992, 9, 1004) state=3 pending=5  [same]

The interior is x=993, z=1002..1003 at y=6..8. The villager sits at **y=9**
throughout — on the wall crown, not inside — first WANDERING (state 5), then
SLEEPING (state 3). It is not building at all. The pending set never changes.

**So the "walks in and correctly refuses to seal itself in" reading is dead**,
and so is the "the erase disorders the project" reading. What is actually
happening is the SAME defect as the roof: the builder gets on top of a structure
and cannot get down.

The pending cells corroborate it precisely:
 - `(992,7,1002)` and `(992,8,1002)` are the two cells directly ABOVE the erased
   door cell. With their support gone they are a floating column — the hardest
   possible reach, and exactly what scaffolding exists for.
 - `(994,6,1004)` upward is a whole corner column, untouched, on the far side.
   Nothing is wrong with it except that the only builder is marooned on a wall
   several cells away and never comes back down.

### What this reframes

The door is not the core problem, and "the building system needs a door concept"
was the right observation attached to the wrong cause. The recurring defect, now
seen three times tonight in three different guises, is:

  **A villager that climbs onto something it built cannot reliably get off it.**

 - Walls, layer 3: solved by scaffolding (measured 27/30 -> 30/30).
 - Roof interior: unsolved — no scaffolding is ever built there, because the
   support would stand inside a sealed room.
 - Wall crown with a doorway present: unsolved — the builder ends up on the crown
   and stays there, wandering then sleeping, while five cells go unbuilt.

`SC-INV-2` defers DISMANTLING while someone is up there, which is necessary but
not sufficient: it protects a descent that exists. It does nothing when no
scaffolding was ever built where the villager actually stranded. The
ADR-0009 climb mutations still firing 40 and 9 times a run are the same story
from the other side — they are how villagers get UP, with no counterpart for
getting DOWN that does not depend on scaffolding happening to be there.

### The story that should be written next

Not "doors" first. **"A builder always has a way down"** — a descent guarantee,
in the same family as `villager-ai-024`'s ascent fix and with the same shape of
lever: assert on a real booted game that after any construction job completes,
`find_path(villager_cell, settlement ground)` is non-empty. That fails today in
at least three distinct geometries, all of them reproduced above.

Doors remain a real and separate need — a sealed room still cannot be entered,
and that blocks the interior roof independently. But a door story written now
would inherit an unsolved descent problem and look like it failed.
