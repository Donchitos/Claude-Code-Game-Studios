# Building System

> **Status**: Approved (2026-07-10 — full review NEEDS REVISION -> revised -> re-review APPROVED; see design/gdd/reviews/building-system-review-log.md) — **amended 2026-07-23** with USER-CONFIRMED vertical-slice findings (see `prototypes/last-seal-vertical-slice/REPORT.md`); passages touched by this pass are marked "(Slice revision 2026-07-23)"
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-23
> **Last Verified**: 2026-07-09 (full review); slice amendment 2026-07-23 not yet re-reviewed
> **Implements Pillar**: Pillar 1 — The building IS the game (primary); Pillar 4 — Clarity over complexity (transparent costs/validity)

## Summary

The Building System is the game's central verb — it turns player intent into
structures. It owns the placement toolset (drag tools for walls/floors/roofs,
free single-block placement, furniture placement), placement validity, ghost
previews, undo/redo, material selection from the Resource & Item Database
palette, and build-over-time construction progress. It composes the
primitives owned by its four dependencies (Voxel World's grid writes and
raycast, Camera & Input's mouse-ray and action signals, the item database's
definitions, Time & Tick's game delta) into a fluid, expressive building
loop — the *planning* half of which (drag tools, surface-aware picking,
undo) was validated by the 2026-07-09 concept prototype (verdict:
PROCEED); the *construction* half (build-over-time) was a design hypothesis
at the 2026-07-10 review and is now **playtest-confirmed by the 2026-07-23
vertical slice** (verdict: PROCEED — see Game Feel and
`prototypes/last-seal-vertical-slice/REPORT.md`).

**(Slice revision 2026-07-23)** The slice validated a materially larger
Detailed Design than the 2026-07-10 review anticipated: an explicit **Build/
Editor Mode** gates the whole toolset; blueprint cells are grouped into
persistent **Build Project** entities (draft → release → build → done, with
pause/resume/cancel and change orders); removal of anything already built
(player blocks or terrain) is now job-gated (demolition/dig orders) rather
than instant; and terrain itself becomes narrowly removable through dig-order
"mining zone" projects — bounded and labor-gated, preserving the anti-pillar
(no unbounded/instant terraforming). These are USER-CONFIRMED outcomes of the
slice, not new proposals; they are folded into Core Rules below with new
TR-IDs (102+), continuing this document's numbering without renumbering any
existing ID.

> **Quick reference** — Layer: `Core/Gameplay` · Priority: `MVP` · Key deps: `Voxel World, Camera & Input, Resource & Item Database, Time & Tick System, Villager AI & Behavior (worker attribution, build-order/scaffolding/stuck-telemetry seam — Slice revision 2026-07-23)`

## Overview

**Player-facing:** Building is the game's primary means of expression
(Aesthetic #1) and its core loop's satisfying atom: "laying a room and
seeing it take shape." The player draws walls that extrude upright in one
action, places floors and roof formations over footprints, and freely sets
or replaces individual blocks and furniture within that structure — hybrid
drag-plus-free-place, exactly as the concept prototype validated. Undo/redo
is a first-class affordance: misclicks are never punished, so experimenting
stays fearless. Per Pillar 1, everything placed has mechanical meaning —
this system is where "the building IS the game" physically happens.

**System-facing:** the Building System is an interpreter and composer. It
receives raw signals (a `build_place` action fired; the mouse world-ray is
X) from Camera & Input, decides what they mean in the current tool context,
validates the result (in bounds? cell free or replaceable? material
selected?), and issues writes through Voxel World's low-level API. It owns
everything between raw input and grid mutation: tool modes, drag logic
locked to the picked surface, placement validity, the undo/redo stack,
ghost previews, and construction-over-time state driven by Time & Tick's
game delta (so building pauses when the game pauses). It never renders the
world (Voxel World's signal-driven rendering reacts to writes) and never
decides *what exists* to build with (the Resource & Item Database's
palette does).

Out of scope here: whether a finished room is *navigable/livable* for
villagers is Build Validation & Navigability's domain (a separate MVP
system); wave-vs-base spatial rules await the wave-defense prototype;
the rendering/meshing implementation is the future building ADR's
decision. **(Slice revision 2026-07-23)** Doors and windows did NOT arrive
as dedicated items during the Vertical Slice — the slice interim (a door is
simply a walkable gap in a wall; a sealed room without one is not
sheltered) is kept and is now the confirmed Production requirement
(pathing-transparent door/window ITEMS that keep a room sealed for shelter
analysis — see Open Question 6 and Art Bible §7.6's discoverability
handoff); resource costs remain explicitly deferred to the Production
economy (Core Rule 14, unchanged) — Build Projects (new, below) are the
carrier entity Alpha costs will attach to.

## Player Fantasy

**"I am shaping a home with my own hands — and it's *mine*."**

This is the system that carries the game's #1 aesthetic (Expression) and
the concept's stated pride moment: *"pride when a plain plot becomes a
warm, furnished home."* The fantasy has three beats:

1. **Effortless intent.** I think "wall there" and a wall of ghosts rises
   there — one drag, full height, instant. The tools feel like an
   extension of my hands, not a form to fill out. (Prototype-proven for
   the *planning* interaction: vertical extrusion and surface-aware
   picking were exactly the moments the tester called out as *"hochziehen
   der Wände ist super"* — note the prototype's walls became real
   instantly; in production, what rises instantly is the blueprint.)
2. **Fearless play.** Misclicks are never punished: while planning, I can
   try a roof shape, hate it, and undo it freely — so I experiment until
   it's right. Undo/redo is not a convenience feature; it is what makes
   expression psychologically safe. *(Slice revision 2026-07-23 — supersedes
   the parenthetical below the 2026-07-10 review had accepted: undoing
   *already-constructed* work is no longer instant. Undo/redo now reaches
   only plan entries — Core Rule 17/TR-building-system-119. Tearing down
   something already built is a deliberate act with its own honest weight:
   a demolition order, executed block by block by a villager, exactly
   mirroring the labor that put it up. The asymmetry the 2026-07-10 review
   accepted is now sharper by design, not softened — "fearless" applies to
   planning; construction and demolition both carry real cost, confirmed
   fun rather than friction in the slice's free play.)*
3. **Earned pride.** The house doesn't pop into existence — it goes up over
   time, so finishing it feels like something *happened*, and the result is
   visibly the sum of my choices: this material, this roofline, this block
   I placed by hand where the drag tool wouldn't. *(Design hypothesis —
   build-over-time was explicitly OUT of the prototype's scope; this beat
   is validated only when the MVP playtest confirms construction pacing
   feels earned rather than tedious. Second caveat, per the 2026-07-10
   cross-review: at MVP, walls carry no mechanical value — the minimal
   roof-on-pillars "carport" is the mechanical optimum (Build Validation
   Edge Case 6, an accepted known gap). Until the Vertical Slice
   wall-coverage rule lands, "earned pride" in elaborate builds rests on
   player expression, not system incentive — deliberate, not hidden.)*

Reference feeling: Stonehearth's self-built homes (the validated draw of
the whole concept) crossed with Minecraft's direct block-level authorship
(the Visual Direction Note's shape reference). NOT the fantasy: a CAD tool
(precision over feel), a free sandbox (structure exists — rooms, walls,
roofs are first-class objects), or a decorator placing stickers on a
finished stat-box (the building IS the stats, Pillar 1).

> `creative-director` not consulted — Lean mode (non-high-risk section).
> Fantasy framing sourced from game-concept.md Core Fantasy + prototype
> REPORT.md tester evidence. Review manually before production.

## Detailed Design

### Core Rules

**Toolset and mode model**

1. Building happens through a modal toolset of exactly six MVP tools: Wall,
   Floor, Roof, Block (place/remove), Furniture, and Undo/Redo (the latter
   always available, not modal). One tool is active at a time; activating a
   tool deactivates the previous one; cancel (right-click or Esc) returns to
   no-tool (camera-only) mode. [TR-building-system-042]
2. Every placement tool follows one pipeline: **pick → preview → commit**.
   The current mouse world-ray (Camera & Input) is forwarded to Voxel
   World's raycast to pick a cell/surface; a ghost preview shows exactly
   what a commit would create; the `build_place` action commits it.
   Nothing is ever created without its preview having been visible. [TR-building-system-002]
3. **Surface-aware targeting** (prototype-validated): placement attaches to
   the picked block's face, or replaces the picked block in place. Drag
   operations lock their working height/plane to the surface picked at
   drag start — never to a fixed ground plane. [TR-building-system-043]
4. **Wall tool**: a drag defines a line segment; on commit the wall
   extrudes upright to the current wall height (default 3 cells,
   adjustable 1–8) in one action. Walls are one-action full-height
   objects, never layer-by-layer slabs. [TR-building-system-044]
5. **Floor tool**: a drag defines a rectangle on the picked plane; commit
   fills it one cell thick with the selected material. [TR-building-system-045]
6. **Roof tool**: the player picks one of four formations — Flat, Gable,
   Hip, Shed (Flach/Sattel/Walm/Pult, prototype-validated) — and drags a
   footprint; commit generates the formation's cell set over it. [TR-building-system-046]
7. **Block tool**: single-cell place (attach/replace per Rule 3) or remove. [TR-building-system-047]
8. **Furniture tool**: places furniture entries from the Resource & Item
   Database (`furniture_fixture` category — MVP list: `bed` only, resolving
   that GDD's Open Question 1). Furniture requires support: the cell(s)
   below must be occupied (ground or built floor). Furniture occupies its
   cells like blocks do (one cell = one occupant, Voxel World Core Rule 2). [TR-building-system-048]
   **(Slice revision 2026-07-23)** Furniture may occupy a multi-cell
   **footprint**, not just one cell: MVP's `bed` is 1×2. A footprint is a
   fixed list of cell offsets from the picked anchor cell; a commit is
   valid iff every offset cell independently satisfies this rule's support
   requirement and Core Rule 9's availability check. All footprint cells
   are written/read as **one furniture entity** — Voxel World's "one cell
   = one occupant" model is satisfied by every footprint cell referencing
   the same occupant id, not by N separate entities. `furniture_cell_count`
   is therefore per-item, not always 1 (F5 updated below). [TR-building-system-124]

**Build/editor mode** *(new subsection, Slice revision 2026-07-23 — gates
everything above)*

8a. Building tools arm **only inside an explicit Build/Editor Mode.**
    Outside Build Mode, none of the six tools (Rule 1) can be armed and no
    ghost preview exists — the toolset is fully inert. [TR-building-system-102]
8b. Build Mode is entered two ways: (1) an explicit UI toggle, or (2)
    arming any tool directly from the palette while outside Build Mode —
    arming a tool always auto-enters Build Mode first, so a player's very
    first click on a tool icon just works. Build Mode is exited only by
    the explicit UI toggle or the Esc chain (Rule 8c) — never as a side
    effect of a single tool deactivation. [TR-building-system-103]
8c. **Esc chain**: Esc is layered and Build Mode is always the LAST link.
    From Dragging, Esc aborts the drag (existing Tool state machine). From
    ToolArmed, Esc returns to Idle (existing Rule, unchanged — still inside
    Build Mode). From Idle (no tool armed, already inside Build Mode), a
    further Esc exits Build Mode itself, handing world clicks back to
    selection (Rule 8d). A single Esc therefore never skips a link: closing
    a drag never also closes Build Mode in the same press. [TR-building-system-104]
8d. **Outside Build Mode**, this system does not consume world clicks at
    all — they belong to villager/project selection per Camera & Input's
    click-ownership arbitration (ADR-0010). This is the default state
    (Off) after boot and after the Esc chain's final link. [TR-building-system-105]

**Placement validity** (owned here, per Voxel World's ownership boundary)

9. A commit is valid iff: every target cell is inside world bounds; every
   target cell is empty (or is the picked cell in a replace-in-place); a
   material/furniture entry is selected and available (MVP: the tier-0 set
   plus `bed`); the command's total cell count is at most
   `max_cells_per_command` (default 512 — see Tuning Knobs); and furniture
   support (Rule 8) holds. Invalid commits are rejected with visible
   feedback (see UI Requirements) — never silently. The cell cap bounds
   every per-command quantity in this system at once: preview size, undo
   payload, and job-queue injection. [TR-building-system-049]
   *Furniture support clarification*: a blueprint floor cell counts as
   support for a furniture *blueprint* (you can plan a bed on a planned
   floor), but the furniture cell's construction may only start once its
   support cell is Built. [TR-building-system-050]
10. Validity here is *geometric availability* only. Whether a structure is
    navigable or livable for villagers (room enclosure, reachable door) is
    owned by Build Validation & Navigability — this system never blocks a
    placement for livability reasons. [TR-building-system-051]

**Blueprint-then-build** (build-over-time)

11. A valid commit does NOT write blocks into the grid. It creates
    **blueprint cells**: planned cells rendered as ghosts, owned by this
    system, invisible to Voxel World's data layer. [TR-building-system-052]
12. Blueprint cells are converted to real blocks by **villager
    construction**. The job contract:
    - **Every blueprint cell is one job** *(Slice revision 2026-07-23 —
      narrowed)*: **only for cells belonging to a Build Project in the
      BUILDING state** (see the new Build Projects subsection below). A
      Draft cell — one whose project has not yet been released, or whose
      change-order batch has not yet been released — generates no job and
      is invisible to `claim_job`; villagers ignore it entirely. The queue
      of BUILDING-eligible cells is ordered by commit time; ordering
      defines *availability for display and tie-breaking*, not forced
      servicing order — Villager AI may choose among available jobs by its
      own criteria (e.g., proximity, or the outside-in/edge-first build
      ordering flagged as a Production requirement — Open Questions). [TR-building-system-053] [TR-building-system-106]
    - **`claim_job` records the claiming villager** against the cell (and
      rolls up onto its project) for **worker attribution** — a queryable,
      display-only fact (Building UI's project window; a future
      Township/reputation input), never a mechanical gate. [TR-building-system-109]
    - **One job per villager at a time**; a villager finishes or abandons
      its current job before claiming another. [TR-building-system-054]
    - **Per-cell claims allow parallelism**: N villagers may simultaneously
      work N distinct cells, including cells of the same command (a
      15-cell wall can be built by several villagers at once). [TR-building-system-055]
    - **"On site"** means the villager occupies the target cell or an
      orthogonally adjacent cell (including directly below/above).
      Construction progress advances per game tick (Time & Tick System)
      only while a claiming villager is on site. [TR-building-system-056]
    - When a cell's build time elapses, this system issues the Voxel World
      write and retires the blueprint cell. [TR-building-system-057]
    *(Contract CONFIRMED 2026-07-10 by villager-ai-behavior.md — claim
    locking (its Rule 4, Edge Case 3), travel/arrival (its F1), and
    abandonment (its Rule 3, Edge Case 4) are all specified there. The
    queue semantics above remain owned HERE and are not renegotiable
    without revising this GDD.)*
13. Construction consumes game time, not raw time: while paused nothing
    builds; time-warp accelerates construction (Time & Tick's game delta /
    tick events). [TR-building-system-058]
14. **MVP cost rule**: tier-0 materials and the MVP bed are free — no
    resource is consumed by placement or construction (implements the
    tier-0 bootstrap, Resource & Item Database Core Rule 6). [TR-building-system-059] The blueprint
    pipeline is the future seam where Alpha resource costs attach (reserve/
    consume at construction, per the Stonehearth hauling model) — costs are
    NOT designed here. **(Slice revision 2026-07-23, user decision
    2026-07-22 — reaffirmed)** the Build Project entity (below) is
    explicitly named as that future cost carrier; this GDD still does not
    design the economy.

**Build Projects (persistent lifecycle)** *(new subsection, Slice
revision 2026-07-23 — validated end-to-end by the vertical slice as the
game's core build UX, not an afterthought)*

14c. **Grouping.** Every valid commit's new blueprint cells are grouped
    into a **Build Project** entity by spatial adjacency: any new cell that
    is **26-neighbor-adjacent** (full 3D Moore neighborhood, F6) to a cell
    already belonging to an existing project of the **same kind** (Rule
    14i) attaches to that project instead of starting a new one. When a
    single commit's cells touch two or more previously separate projects at
    once, all of them merge into one. Grouping is resolved by a **union-find
    pass over the whole batch** before any single cell's membership is
    finalized, so the outcome never depends on iteration order within the
    batch (parallel villager completions and multi-cell commits are
    equally deterministic). If merged projects disagree only in
    attribution/history, the lowest-numbered (earliest-created) project id
    survives and absorbs the others' cells and worker-attribution
    records. [TR-building-system-107]
14d. **A single higher-level tool commit is always one batch** for the
    purposes of Rule 14c, regardless of how many primitive cell-sets it
    internally produces (a house-template stamp emits walls + floor + roof
    in one pass) — guaranteeing one project even for a geometry where two
    sub-shapes would not otherwise be mutually 26-adjacent (e.g. a roof cap
    with a gap before its supporting wall completes). Room-rect, auto-roof,
    and house-template tools (Building UI's domain for their UX) satisfy
    this system's contract by emitting a normal batch of Draft blueprint
    cells into exactly one project — they add no new system-level
    behavior beyond Rules 14c/14d. [TR-building-system-126]
14e. **Project states** (rollup over its cells, not a flag set
    independently): **DRAFT** (every cell is a Draft cell; no job exists;
    villagers ignore it entirely) → **BUILDING** (released — see Rule 14f
    — at least one cell is queued/UnderConstruction and none of its Draft
    batches are the ENTIRE remaining content) → **PAUSED** (player-paused;
    no new jobs offered, existing claims revoked per the existing graceful-
    abandon contract, Villager AI's Rule 3/Edge Case 4) → **DONE** (every
    cell in the project has reached Built/Removed — see Rule 14i for dig
    projects — and no Draft batch is pending). [TR-building-system-108]
14f. **Release ("Bau starten")** is a **per-project** action: it transitions
    every Draft cell currently in the project (or, for a change order on an
    already-built project, just that pending batch — Rule 14h) into
    BUILDING, making them job-eligible per Rule 12. `claim_job` serves
    BUILDING-state work only — never DRAFT, PAUSED, or a project's
    not-yet-released change-order batch. [TR-building-system-109]
14g. **Pause/Resume**: pausing a BUILDING project stops offering new jobs
    and revokes any in-flight claims (villagers abandon gracefully, exactly
    as an undo-triggered revocation already does — Edge Case 4); the
    project's cells remain queued. Resuming re-offers the same remaining
    cells as jobs and returns the project to BUILDING. Pause/resume never
    touches Built cells or Draft cells outside the paused batch. [TR-building-system-110]
14h. **Change orders**: a new commit whose cells are 26-adjacent (Rule 14c)
    to an existing project that is BUILDING, PAUSED, or DONE does **not**
    start a new project — it attaches as a new **pending batch** on that
    project, displayed as "Änderungen geplant" (changes planned) until the
    player releases that batch specifically (Rule 14f). A DONE project
    that gains a pending change-order batch is no longer fully DONE for
    rollup purposes (Rule 14e) until the batch, too, reaches Built or is
    canceled — the project's overall state simply reflects whichever of
    its cells/batches are least-finished. [TR-building-system-112]
14i. **Project persistence.** A project is a **long-lived entity**: reaching
    DONE does not delete it — it persists as the future carrier for
    resource costs, scaffolding state, and saved templates (Open
    Questions). **A project disappears only when it becomes empty** —
    every one of its cells has been canceled (Draft, free) or demolished/
    excavated away (Built/Removed, via Rules 14j–14m). Clicking any cell
    that belongs to a project **selects that project** (its info surface,
    owned by Building UI) in **any** mode and with **no tool armed** —
    this is the one form of building-system interaction that works even
    outside Build Mode (Rule 8d's exception). [TR-building-system-111] [TR-building-system-113]

**Removal, demolition, dig orders, and undo** *(retitled and substantially
revised, Slice revision 2026-07-23 — supersedes the "instant removal"
model the 2026-07-10 review had accepted; see Core Rules 16–17 below)*

14b. **Occupancy authority split.** *Physical* occupancy (collision,
    pathing, line-of-sight) is Voxel World's authority — blueprint cells
    are deliberately non-solid until Built, so walking "through" a planned
    wall is correct behavior, and Edge Case 6 guarantees a cell never
    becomes solid under a character. *Planned* occupancy (what will exist:
    placement validity, Build Validation's enclosure analysis, future
    planners) must query this system's combined view (Voxel World blocks +
    blueprint cells). Consumers must never treat raw Voxel World state as
    "what the player has built or plans to build." [TR-building-system-060]

15. **Terrain is not removable** *(Slice revision 2026-07-23 — narrowed,
    not reversed)*: terrain can never be removed **instantly** or by the
    plain single-cell removal path. Only player-built cells (blueprint or
    constructed) and player-placed furniture can be removed that way. [TR-building-system-061] This is the
    MVP implementation of the anti-pillar "no unbounded terraforming" —
    and it resolves Voxel World's Open Question ("do consuming systems
    need a natural/built distinction?") with **yes**: the game must be able
    to distinguish terrain cells from built cells. [TR-building-system-062] *(How — a Voxel World
    data flag vs. this system's own built-cell record — is an
    implementation choice for the building ADR.)* The one narrow exception
    validated by the slice is **dig-order mining** (Rule 14m,
    TR-building-system-121): terrain becomes removable only through a
    bounded, job-gated project, never at player-fiat instant speed —
    preserving the anti-pillar's actual intent (no *unbounded or
    instant* terraforming) rather than relaxing it.
16. **Removal of built cells is job-gated, not instant** *(Slice revision
    2026-07-23 — supersedes the 2026-07-10 review's "instant in MVP"
    rule)*: targeting a Built cell with the removal tool (or a project-wide
    cancel, Rule 14k) creates a **demolition order** instead of writing the
    removal immediately — see Rules 14j–14m. Removing a **blueprint**
    (not-yet-Built) cell is unchanged and remains instant/free: the removal
    tool's behavior branches on the target cell's own micro-state — Draft
    → instant cancel, no job (also reachable via undo, unchanged); Queued/
    UnderConstruction (released but not yet Built) → instant cancel and the
    claiming villager's job is revoked, exactly as before; Built → a
    demolition order (new). [TR-building-system-063] [TR-building-system-123]
    **Furniture now follows this same job-gated path** *(Slice revision
    2026-07-23, tick-rate/furniture resolution — supersedes the
    instant-removal carve-out this rule previously stated here; user
    decision AGAINST the carve-out)*: targeting Built furniture with the
    removal tool creates a **demolition order** on the furniture cell's
    owning Build Project — or, if the furniture cell has no owning
    project, a standalone removal order using the identical Rule 14j
    mechanics — executed block-by-block by a claiming villager exactly as
    for structural cells. The furniture entity/occupant record is cleared
    from Voxel World, and the item is no longer ownable/claimable, only
    once that order completes (see Rule 17b's revised timing below).
    Removing a not-yet-Built furniture blueprint is unchanged: it branches
    on micro-state exactly like any other cell above (Draft → instant
    cancel; Queued/UnderConstruction → instant cancel, claim revoked).
    **A multi-cell furniture footprint (F5) demolishes atomically as one
    job**, not per-cell — mirroring placement's no-partial-commit rule
    (Edge Case 19) — so a 1×2 bed can never be left half-torn-down with
    one footprint cell gone and the other still standing. [TR-building-system-127]
    **17b — Furniture-revocation contract** *(added 2026-07-10, from the
    needs-mood review — Edge Case 11's interruption previously had no
    notification mechanism: Villager AI's Rule 10b covers only MOVING
    villagers and cannot inform a stationary sleeper; timing REVISED
    2026-07-23, tick-rate/furniture resolution — see Rule 16 above)*:
    removing a piece of OWNED furniture (MVP: a bed with an owner) emits a
    furniture-revocation event to the owning villager, symmetric to the
    job-revocation contract in the blueprint lifecycle. Villager AI
    consumes it in its Edge Cases 5–6; Needs learns via the villager's
    `stop_recovery` call. **The event now fires on demolition-order
    completion, not at order creation**: furniture removal is no longer
    instant, so an in-use bed keeps functioning normally until a villager
    actually finishes tearing it down, at which point the occupant is
    revoked exactly as before. [TR-building-system-064]

14j. **Demolition orders** (Slice revision 2026-07-23, new): a demolition
    order is created **already released** — unlike build/dig Draft cells it
    has no staging step, since tearing something down needs no blueprint
    to reconsider. It is executed by villagers **block by block**,
    mirroring Rule 12's construction job contract in reverse (one cell =
    one job; on-site rules per Rule 12 unchanged), taking
    `base_demolition_ticks` per cell. Once a cell's demolition completes,
    this system issues the Voxel World clear and the cell is gone; if the
    cell was a floor-excavation replacement of terrain (Rule 14l), the
    original terrain's `restore_value` is written back instead of leaving
    an empty cell. [TR-building-system-114] [TR-building-system-115]
14k. **Project cancel ("Abriss")** converts an entire project at once:
    every remaining Draft cell (including any not-yet-released change-order
    batch) is canceled for free, exactly as a single Draft cancel already
    was; every Built cell is converted to an already-released demolition
    order (Rule 14j) in the same action — the player does not additionally
    press "Bau starten" to tear a canceled project down. [TR-building-system-117]
14l. **Floor excavation** (Slice revision 2026-07-23, new): a floor-tool
    drag that starts on a terrain top surface **replaces the terrain cell
    flush** (Stonehearth-style) rather than stacking a floor cell on top of
    it (which would create an unwanted step). Because Core Rule 15 still
    forbids terrain removal outside a job, this is a narrow, tracked
    exception: the original terrain cell's value is stored as
    `restore_value` on the blueprint entry. If that entry is later
    canceled (Draft), undone (still-pending), or demolished (Built, Rule
    14j), the stored terrain is restored rather than left empty — no floor
    replacement can ever result in unbounded/permanent terrain loss. [TR-building-system-120]
14m. **Terrain dig orders / mining zones** (Slice revision 2026-07-23, new):
    the removal tool, when it targets terrain instead of a player cell,
    marks Draft dig cells inside a new or existing project of **kind
    `dig`** (Rule 14c's adjacency/merge rule applies identically, but a
    dig-kind project only ever merges with other dig-kind projects — it
    never merges with a `build`-kind project even if spatially adjacent).
    Dig projects follow the exact same DRAFT → BUILDING (released) →
    PAUSED/DONE lifecycle (Rules 14e–14h); their terminal per-cell state is
    **Removed**, not Built. Released dig cells are subject to the same
    `max_cells_per_command` cap as any other command (Core Rule 9) — mining
    is bounded, never a free-form terraform. **On-site amendment**: for a
    dig job specifically, the target cell itself is EXCLUDED from the
    "on site" set defined by TR-building-system-056 — a villager may stand
    only on an orthogonal neighbor of the cell it is excavating, never on
    the cell itself. *(Slice-validated fix: the unamended rule let a
    villager dig the block directly under its own feet and become
    trapped.)* [TR-building-system-121] [TR-building-system-122]
17. **Undo/redo** operates on player *commands* (one wall drag = one
    command = one undo step, exactly as prototyped). Undoing a command
    cancels its still-pending blueprint cells. **(Slice revision
    2026-07-23 — supersedes "if some cells were already constructed, those
    blocks are removed instantly")**: undo/redo now operate on **plan
    entries exclusively and never reach a Built cell**. If some of a
    command's cells have already reached Built, undoing that command
    cancels only the cells still in Draft/Queued/UnderConstruction and
    leaves the Built cells standing exactly as they are — undo does not
    even queue a demolition order for them; a player who wants those torn
    down must use the removal tool or Abriss (Rule 14k) separately. Redo
    replays the command as new blueprint cells. [TR-building-system-065] [TR-building-system-119] The stack is bounded (default 50 commands); it is
    cleared when a scene transition **completes** (the transition-COMPLETE
    signal, never transition-begin — an aborted/failed transition must
    leave the stack untouched; per Scene/World Management's side-effect
    discipline rule, REVISED 2026-07-10 re-review) and never persists
    into save files. [TR-building-system-066]

### States and Transitions

**Build Mode state machine** (Slice revision 2026-07-23, new — gates
everything below it):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Off | Boot; explicit UI toggle off; Esc while at Idle (last link, Rule 8c) | Explicit UI toggle on; any tool armed from the palette (auto-enter) | World clicks belong to villager/project selection (Camera & Input's arbitration, ADR-0010); no tool reachable, no ghost [TR-building-system-105] |
| On | UI toggle on; arming a tool | Explicit UI toggle off; Esc while at Idle | Tool state machine below is live; clicking any project cell still selects it regardless of tool-armed state (Rule 14i) [TR-building-system-102] [TR-building-system-103] |

**Tool state machine** (player-facing; only reachable while Build Mode is On):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Idle (no tool) | Boot **into Build Mode**, cancel, tool deactivation | Tool selected (stays On), **or a further Esc exits Build Mode itself (Rule 8c, Slice revision 2026-07-23)** | Camera-only; no ghost, no commits |
| ToolArmed | Tool selected | Cancel / other tool / drag start | Ghost preview follows the pick each frame [TR-building-system-026] |
| Dragging | Drag threshold reached (`cursor_travel_px >= drag_threshold_px`, F4) with `build_place` held | Release (commit), cancel (abort), or other tool selected (abort) | Preview **re-rasterizes every frame** as the cursor moves — the full pending result (wall segment, floor rect, roof footprint) is always current, never frozen at drag start; above `preview_degradation_threshold` cells the preview degrades to an outline (see Tuning Knobs); working plane locked per Core Rule 3 [TR-building-system-003] |
| Suspended | Camera & Input enters Suspended (scene transition) | Camera & Input reactivates | All interaction halted mid-anything: an in-progress drag is aborted without commit [TR-building-system-067] |

**Blueprint cell lifecycle** (per cell; also called a "Draft cell" while its
project/change-order batch has not been released — same system state, UX
term only, Slice revision 2026-07-23):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Planned (= Draft) | Valid commit created it | Job claimed, or canceled | Ghost visual; occupies no grid cell; counted as "pending" for its command's undo step; **job-eligible only once its project is BUILDING** (Core Rule 12, Slice revision 2026-07-23) [TR-building-system-068] [TR-building-system-106] |
| UnderConstruction | Villager claims its job and is on site | Build time elapses, or canceled | Progress accumulates per game tick; visually distinct from Planned (see Visual/Audio) [TR-building-system-069] |
| Built (terminal for the cell; not for the project) | Build time complete | Demolition order created (Rule 14j) | This system writes the block via Voxel World; the cell itself is terminal, but **its project persists and only a demolition order can move it onward** (Slice revision 2026-07-23 — supersedes the old "instant removal" path) |
| Canceled (terminal) | Player removal/undo while still Draft/Queued/UnderConstruction | — | Ghost removed; any claimed job is revoked (villager abandons gracefully — provisional, Villager AI GDD). **Never reachable from Built** (Slice revision 2026-07-23) — see Rule 16/17 |

**Build Project lifecycle** (Slice revision 2026-07-23, new — rolls up
over the cells above; applies identically to `build`-kind and `dig`-kind
projects, Rule 14m, except the terminal per-cell state is Removed instead
of Built for `dig`):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| DRAFT | First commit whose cells don't 26-adjoin any existing project | Release ("Bau starten") | No jobs exist; villagers ignore every cell entirely; free to edit (draft eraser) or fully undo [TR-building-system-108] |
| BUILDING | Release of the project or of a pending change-order batch | Pause; or every cell reaches Built/Removed with no pending batch (→ DONE) | Cells are job-eligible; `claim_job` serves them; worker attribution recorded per claim [TR-building-system-109] |
| PAUSED | Player pause | Resume (→ BUILDING) | No new jobs offered; in-flight claims revoked gracefully; queued cells untouched [TR-building-system-110] |
| DONE | Every cell Built/Removed, no pending Draft batch | A new adjacent commit attaches a change-order batch (→ BUILDING once released); or Abriss (Rule 14k) demolishes it back toward empty | Persists as a long-lived entity — does NOT disappear on reaching DONE [TR-building-system-111] |
| *(deleted)* | Every cell in the project has been canceled or demolished/excavated away — the cell set is empty | — | The project entity itself is removed only at this point (Rule 14i) [TR-building-system-111] |

### Interactions with Other Systems

- **Voxel World** (upstream, MVP): the only mutation path — this system
  calls the write API (set/clear cell) when blueprint cells complete or
  built cells are removed, and the raycast/read API for picking and
  validity checks. [TR-building-system-070] It listens to Voxel World's write signals to keep undo
  bookkeeping honest (a cell changed by anything else invalidates affected
  undo entries) [TR-building-system-071] — with two contract rules:
  - **Self-write exemption**: writes originating from this system (cell
    completion, undo removal) are tagged and MUST be ignored by its own
    undo-invalidation listener. Godot signals are synchronous — without
    this rule, unwinding a command would re-enter the listener mid-unwind
    and could self-invalidate the very entries being processed. [TR-building-system-024]
  - **Batching**: when multiple cells complete or are removed in the same
    frame (parallel villagers, multi-cell undo), this system uses Voxel
    World's bulk-write API so ONE batched signal fires, per that GDD's
    explicit batching mandate (its Edge Cases) — never one signal per cell. [TR-building-system-072]
- **Camera & Input** (upstream, MVP): consumes InputMap action signals
  (`build_place`, `build_remove`, tool-select actions — the action list
  extends that GDD's set) and the mouse world-ray query. Enters Suspended
  with it (that GDD's Active/Suspended states). [TR-building-system-073] The open "pan margin"
  question from that GDD can now be answered: building must reach the
  world edge, so the pan bound needs no extra building-driven margin (see
  Open Questions).
- **Resource & Item Database** (upstream, MVP): queries the palette
  (`building_material` + `furniture_fixture`, tier-0 rule) and reads
  `material_family`/`visual_asset` for previews. [TR-building-system-074] Confirms that GDD's
  provisional "primary consumer" contract.
- **Time & Tick System** (upstream, MVP): construction progress advances
  by game ticks (2.0/s base); pause halts construction; time-warp
  accelerates it. Uses tick events, not raw delta. [TR-building-system-058]
- **Villager AI & Behavior** (MVP sibling, undesigned — PROVISIONAL):
  consumes the construction-job queue (claim job → path to site → work →
  report done). This GDD defines the queue's behavior; the AI GDD must
  confirm claiming, pathing-failure, and abandonment semantics.
  **(Slice revision 2026-07-23)** `claim_job` now serves only BUILDING-
  project cells (Core Rule 12/14f) and must record worker attribution per
  claim; demolition jobs (Rule 14j) reuse the same claim/on-site contract;
  dig jobs (Rule 14m) use an amended on-site set that excludes the target
  cell itself. Three Production requirements surfaced by the slice remain
  **owned by Villager AI, not this GDD** — recorded here only as the seam
  this system's job supply must not preclude: (1) **outside-in/edge-first
  build-order planning** (this system's queue ordering is commit-time only,
  Core Rule 12 — job *selection* among available cells is entirely
  Villager AI's criteria to extend); (2) **scaffolding/ladders** for tall
  builds (no system-level change here; a future seam, like resource costs);
  (3) **stuck telemetry as a hard requirement** — the slice's unstuck
  watchdog (~3s) plus seal-prevention with a livelock guard is a
  **validated interim safety net, not the final solution** (Villager AI's
  Tuning Knobs own the actual tick value — pointer only, see this GDD's
  Tuning Knobs).
- **Build Validation & Navigability** (MVP, downstream): reads completed
  structures (and possibly blueprints) to judge enclosure/livability.
  This system exposes "a construction completed" signals for it —
  **batched per FRAME** (the same batching mandate as the Voxel World
  bulk-writes above): N cells completing in one frame, across any number
  of commands and villagers, fire ONE completion signal. [TR-building-system-075] *(Contract
  required by that GDD's Edge Case 10/AC19 — added 2026-07-10 by its
  design review; without it, N parallel completions could trigger N
  region re-analyses in one frame.)*
- **Building UI** (MVP, downstream): renders the tool palette, material
  selection, wall-height stepper, roof-formation picker, and undo/redo
  buttons; displays validity feedback. All state it shows lives here. [TR-building-system-076]
  **(Slice revision 2026-07-23)** also renders the Build Mode toggle, the
  per-project window (state, release/pause/resume/Abriss controls, worker
  attribution) and project-click selection; the room-rect/auto-roof/house-
  template higher-level tools are entirely Building UI's UX to design —
  this GDD only guarantees they land as one project batch (Rule 14d). This
  is a **flagged reciprocal update building-ui.md still needs** (not made
  in this pass — out of scope for this document).
- **Scene/World Management** (Foundation, upstream): hosting; the undo
  stack clears on transition-COMPLETE (Core Rule 17 — never on begin, so
  a load-failure abort leaves undo intact) [TR-building-system-066]; tool state machine suspends
  via Camera & Input's Suspended state.
- **Save/Load & World Persistence** (Vertical Slice, downstream,
  provisional): must serialize open blueprint cells and construction
  progress (built cells live in Voxel World's data). [TR-building-system-023] The undo stack is
  explicitly NOT saved. [TR-building-system-033]

## Formulas

*(`systems-designer` consulted — mandatory for this high-risk section even in
Lean mode. Review produced 4 revisions and 3 additions; all incorporated.)*

### F1 — Wall cell set from a drag

`wall_cell_count = line_length(start_cell, end_cell) × wall_height`

The dragged segment is rasterized into a deterministic run of cells on the
locked working plane (Bresenham-style stepping for diagonals — equal
displacements always yield equal cell counts); each run cell extrudes
`wall_height` cells upward from the picked surface. [TR-building-system-077]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `start_cell`, `end_cell` | Vector3i | within world bounds, same working plane | Drag endpoints (start = pick at drag start, per Core Rule 3) |
| `line_length` | int | 1 – world-bounded | Rasterized run length; `start == end` degenerates to 1 (single column) |
| `wall_height` | int | 1–8, default 3 | Clamped at the input layer (UI stepper), not re-clamped here |

Example: a 5-cell drag at default height → 5 × 3 = **15 blueprint cells**.

### F2 — Floor cell set from a drag

`floor_cell_count = (|dx| + 1) × (|dz| + 1)` — a 1-cell-thick rectangle on
the locked plane. Zero-length drag degenerates to a single 1×1 tile. [TR-building-system-078] The
practical maximum is `max_cells_per_command` (512, Core Rule 9) — the
binding limit for any single commit; the world grid dimensions only bound
the preview clamp (Edge Case 1).

Example: dragging 3 cells in x and 4 in z → 4 × 5 = **20 blueprint cells**.

### F3 — Construction time per blueprint cell

`cell_build_ticks = base_build_ticks[category]`

A cell under active construction (villager on site) completes after
`base_build_ticks` tick events (Time & Tick System). Tick counts are
warp-invariant: time-warp changes wall-clock speed, never the tick count. [TR-building-system-079]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `base_build_ticks[block]` | int | ≥ 1, default 4 | 2.0s at 1x warp (ticks_per_second = 2.0) |
| `base_build_ticks[furniture]` | int | ≥ 1, default 8 | 4.0s at 1x warp — furniture is more deliberate |

**Burst rule (per villager/job)**: the tick budget applies **independently
per active job** — each villager with an UnderConstruction cell processes
tick bursts (up to `max_ticks_per_frame = 10` after a stall or at high
warp) on its own cell. Per job, a burst applies at most enough ticks to
complete the *current* cell; excess ticks do NOT roll over to that
villager's next cell — it starts with the next processed tick event.
Construction throughput therefore scales with the number of working
villagers (N villagers can complete at most N cells per frame), and each
individual construction stays visually plausible at any warp. [TR-building-system-080]

Example: a 3-run × 3-high wall = 9 cells × 4 ticks = 36 ticks = **18s of
game time at 1x warp** — *excluding villager travel time between cells and
assuming one villager. Total real-time-to-complete for an N-cell command is
deliberately NOT modeled here: it depends on villager count, pathing, and
job scheduling (Villager AI & Behavior's domain).*

**(Slice revision 2026-07-23)** Demolition orders (Rule 14j) use the
identical mechanism with a separate base value, `base_demolition_ticks`
(Tuning Knobs) — `cell_demolition_ticks = base_demolition_ticks[category]`,
same burst rule, same warp-invariance. The slice validated the job-gated
*mechanism* (a villager walks to a Built cell and tears it down block by
block) but did not measure or tune a specific pace — the default below is
an `[assumption]`, not a playtest-validated value (per this doc's
provenance rule), pending a dedicated demolition-pacing playtest.

### F4 — Click vs drag discrimination

`is_drag = cursor_travel_px >= drag_threshold_px` while `build_place` is
held; release below the threshold is a click (single commit). [TR-building-system-081]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `cursor_travel_px` | float | ≥ 0 | Screen-space pixels (Camera & Input's unit), not world cells |
| `drag_threshold_px` | float | 4–12, default 6 | Prototype-validated |

### F5 — Roof and furniture cell counts (scalar stubs)

`roof_cell_count = f(formation, footprint)` — each formation (Flat/Gable/
Hip/Shed) defines a deterministic cell count over its footprint. **Flat is
specified now** (unblocking AC15 for MVP):
`flat_roof_cell_count = (|dx| + 1) × (|dz| + 1)` — identical to F2, one
cell thick on the plane above the footprint's highest picked surface.
Gable/Hip/Shed functions are specified alongside the shape algorithm at
Vertical Slice detail (see below). [TR-building-system-007]

`furniture_cell_count = |footprint(item)|` **(Slice revision 2026-07-23 —
supersedes "= 1 for all MVP furniture")**: furniture now occupies a
per-item footprint (a fixed list of cell offsets, Core Rule 8), not
always a single cell. MVP's only furniture item, `bed`, has a 1×2
footprint → `furniture_cell_count = 2`. [TR-building-system-082] [TR-building-system-124]

| Variable | Type | Range | Description |
|----------|------|-------|--------------|
| `footprint(item)` | array of Vector3i offsets | 1–N cells, fixed per item definition | The item's cell shape relative to its anchor (picked) cell; MVP `bed` = 2 offsets |

Example: placing `bed` → `furniture_cell_count = 2` (was 1 before the
slice's multi-cell furniture finding).

### F6 — 26-neighbor adjacency predicate (Slice revision 2026-07-23, new)

`is_26_adjacent(cell_a, cell_b) = (chebyshev_distance(cell_a, cell_b) == 1)`,
where `chebyshev_distance(a, b) = max(|a.x−b.x|, |a.y−b.y|, |a.z−b.z|)`.
This is the exact test Core Rule 14c (project grouping/change orders) and
Rule 14m (dig-project grouping) apply between every pair of candidate
cells — full 3D Moore neighborhood (including edge- and corner-touching
cells), not face-only (6-neighbor) or edge-only (18-neighbor). [TR-building-system-107]

| Variable | Type | Range | Description |
|----------|------|-------|--------------|
| `cell_a`, `cell_b` | Vector3i | within world bounds | The two cells being tested for project-merge adjacency |
| `chebyshev_distance` | int | ≥ 0 | Max per-axis absolute difference; 0 = same cell |
| `is_26_adjacent` | bool | {true, false} | true iff the cells are neighbors (including diagonally) in 3D — the merge/attach trigger |

Output is a boolean, unbounded input domain (any two in-bounds cells).
Example: `cell_a = (4, 1, 4)`, `cell_b = (5, 1, 5)` → distance = max(1, 0,
1) = 1 → `is_26_adjacent = true` (a purely diagonal touch still merges).
`cell_b = (6, 1, 4)` → distance = 2 → `false` (one cell of empty space
between them does not merge).

### Deliberately NOT formulas (and why)

- **Roof shape generation** — a per-formation construction algorithm
  (which cells, at which heights), not a scalar computation; specified as
  shape rules in the roof asset/design spec at Vertical Slice detail. Only
  its cell *count* (F5) is a formula because F3's queue consumes it.
- **Pick raycast** — owned by Voxel World (its GDD: native/DDA, deferred
  to the building ADR).
- **Undo stack behavior** — rules (Core Rule 17), not math.
- **Project batch-merge/union-find grouping** *(Slice revision
  2026-07-23)* — a graph algorithm (which cells belong to which project),
  not a scalar computation; F6 supplies its one reusable predicate, but the
  union-find pass itself (Core Rule 14c) is a rule, not a formula.
- **Outside-in/edge-first build-order sequencing** *(Slice revision
  2026-07-23)* — a Villager AI job-selection policy over this system's job
  supply (Core Rule 12), not owned or computed here.

## Edge Cases

1. **Drag extends beyond world bounds.** The preview clamps to the bounded
   grid and shows only the in-bounds portion; commit creates exactly what
   the preview showed. A drag entirely out of bounds commits nothing. [TR-building-system-083]
2. **Replace-in-place targeting a terrain cell.** Invalid — replacing is
   removal + placement, and terrain is not removable (Core Rule 15).
   Attaching to a terrain cell's face remains valid (that's how building
   on the ground works). [TR-building-system-084]
3. **Commit targeting a cell that already holds a blueprint cell.**
   Invalid. Blueprint cells count as occupied for placement validity even
   though they are invisible to Voxel World's data layer — otherwise two
   commands could queue contradictory builds for one cell. [TR-building-system-085]
4. **No valid pick under the cursor** (ray misses the world). The ghost
   preview is hidden and `build_place` is a no-op — no error spam; the
   absence of a ghost IS the feedback (plus cursor state, see UI
   Requirements). [TR-building-system-086]
5. **Blueprint cell is unreachable for the villager** (player walled it
   in). The job stays in the queue and is retried periodically; the ghost
   persists indefinitely — never auto-canceled. **The failure is never
   silent**: once a job is reported unreachable, its ghost switches to a
   pulsing orange tint (the Visual Direction Note's state axis) and a
   small non-modal UI hint appears ("a build spot can't be reached") —
   this system owns the signal; the unreachability *detection* comes from
   Villager AI's pathing failures (its Rule 6). The player resolves it
   by undoing/removing either the blueprint or the obstruction. This
   deliberate patient-but-visible design protects the MVP's "earned pride"
   moment from silent failure (a first-timer who seals a room sees orange,
   not nothing). [TR-building-system-087] *(Retry cadence: `unreachable_retry_ticks`, owned by the
   Villager AI GDD's Tuning Knobs — confirmed 2026-07-10.)*
6. **Construction target cell is occupied by a character** (villager or
   other unit standing in it). The blueprint is valid; construction of
   that specific cell is deferred until the cell is clear. [TR-building-system-037] *(Nudge-aside
   is specified in Villager AI's Rule 7 + F4 — confirmed 2026-07-10; note
   its refinement: Working/Sleeping occupants are never interrupted.)*
7. **Undo of a partially built command.** Pending blueprint cells are
   canceled, already-built cells are removed instantly (Core Rule 17); any
   villager mid-construction on an affected cell has its job revoked and
   re-enters normal behavior *(graceful abandon — specified in Villager
   AI's Rule 3 + Edge Case 4, confirmed 2026-07-10)*. [TR-building-system-065]
8. **Redo into a changed world.** Redo re-validates every cell of the
   command; cells that are no longer valid (occupied since the undo) are
   dropped from the redo with the standard invalid-feedback, valid cells
   are re-created as blueprints. A redo where zero cells survive is a
   no-op with feedback. [TR-building-system-088]
9. **Undo stack overflow.** Beyond the bounded depth (default 50), the
   oldest command is discarded silently — it simply becomes permanent. Any
   new command clears the redo branch (standard undo semantics). [TR-building-system-089]
10. **Scene transition with pending blueprints.** Blueprints persist and
    the Valley keeps simulating during dungeon excursions (Scene/World
    Management Core Rule 4): the villager keeps building while the player
    is away. [TR-building-system-090] The undo stack, however, clears on transition-complete
    (Core Rule 17) — returning players cannot undo pre-transition
    commands. [TR-building-system-066]
11. **Furniture removed while in use** (bed targeted by the removal tool
    while a villager sleeps in it). *(Timing REVISED 2026-07-23,
    tick-rate/furniture resolution — supersedes "removal is never blocked
    by usage" as an instant fact)*: ordering the removal is never blocked
    by usage — the demolition order is created immediately regardless of
    occupancy (Rule 16) — but the furniture-revocation event now fires
    only once a villager completes that demolition job, not at order
    creation. Until then the sleeping villager continues using the bed
    normally. On completion, the furniture-revocation event (Core Rule
    17b) notifies the owner; the villager is interrupted and re-plans
    *(interruption semantics — specified in Villager AI's Edge Case 5 and
    Needs' Edge Case 3, confirmed 2026-07-10)*. [TR-building-system-064]
12. **Tool switched or Suspended entered mid-drag.** The drag aborts
    without commit (States table); no partial blueprint is ever created by
    an aborted drag. [TR-building-system-067]

**Added by the vertical slice (Slice revision 2026-07-23)**

13. **A single commit batch touches two or more previously separate
    projects of the same kind at once.** All touched projects merge into
    one (Core Rule 14c); the lowest-numbered (earliest-created) project id
    survives and absorbs the others' cells and worker-attribution history —
    a deterministic, order-independent choice, never an arbitrary winner. [TR-building-system-107]
14. **A new draft is 26-adjacent to a `dig`-kind project while drawing a
    `build`-kind command (or vice versa).** No merge occurs — kind is a
    hard partition (Rule 14m); a second, separate project is created even
    though the cells touch. [TR-building-system-121]
15. **A change-order batch is drawn against a DONE project.** The project's
    rollup state leaves DONE and shows "Änderungen geplant" (Rule 14h)
    until the new batch is separately released; the project's already-Built
    cells and worker-attribution history are untouched. [TR-building-system-112]
16. **Draft eraser used to carve a gap out of an unreleased wall draft**
    (e.g. a door gap before release). The targeted cells, still in Draft
    micro-state, are erased instantly with no job and no notification —
    this is plan editing, indistinguishable in cost from never having
    drawn them (Rule 16/TR-building-system-123). [TR-building-system-123]
17. **Removal tool targets a Built cell that is mid-demolition-claim by
    another action (e.g. Abriss fires while a lone `build_remove` demolition
    order on the same cell is already queued).** The second request is a
    no-op on an already-queued demolition cell — exactly one demolition job
    exists per cell, never a duplicate (mirrors Core Rule 3's "already
    holds a blueprint cell" invalid-commit rule, applied to the demolition
    queue). [TR-building-system-114]
18. **A canceled/demolished floor-excavation cell's stored terrain has
    itself changed since replacement** (e.g. Voxel World's terrain data
    was altered by an unrelated system in the interim — not possible in
    MVP's static terrain, but the bookkeeping must not assume otherwise).
    `restore_value` writes back exactly the value captured at the moment
    of replacement, not a re-derived "current" terrain state — restoration
    is a snapshot, never a live query. [TR-building-system-120]
19. **A multi-cell furniture footprint's cells are only partially
    supported or only partially free** (e.g. a 1×2 bed where one of the
    two cells lacks support, or overlaps an existing blueprint/built
    cell). The entire commit is invalid — Core Rule 9's availability check
    and Core Rule 8's support check apply to every footprint cell
    independently; there is no partial placement of a multi-cell
    furniture item. [TR-building-system-124]
20. **A dig job's target cell is directly beneath a villager's current
    standing cell.** The villager is never considered "on site" for that
    job while standing on the target (Rule 14m's on-site amendment) — it
    must stand on an orthogonal neighbor instead, which the job-claim logic
    (Villager AI's domain) must select in preference to the now-excluded
    cell. [TR-building-system-122]

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Voxel World | ✅ Designed | Write API (set/clear cell), raycast picking, read API for validity, write signals for undo bookkeeping |
| Camera & Input | ✅ Designed | InputMap action signals (`build_place`, `build_remove`, tool selects), mouse world-ray query, Suspended state |
| Resource & Item Database | ✅ Designed | Palette queries (`building_material`, `furniture_fixture`), `tier` (free set), `material_family`, `visual_asset` |
| Time & Tick System | ✅ Designed | Tick events for construction progress (F3); pause/warp semantics via game time |
| Villager AI & Behavior | ✅ Designed (2026-07-10); slice extensions flagged 2026-07-23, not yet reciprocated in that GDD | Job claiming, on-site presence, pathing failure/abandon semantics for the construction queue (Core Rule 12) — **contract CONFIRMED** by villager-ai-behavior.md (its Core Rules 3–7 + F1 arrival rule, F4 nudge-aside); `unreachable_retry_ticks` is owned there. **(Slice revision 2026-07-23)** additionally: worker-attribution recording on claim (Rule 14f), the dig-job on-site exclusion (Rule 14m), and the three Production requirements this system's job supply must not preclude — outside-in/edge-first build ordering, scaffolding/ladders, and stuck telemetry (unstuck watchdog + seal-prevention, validated interim only) — all owned there, **flagged here as a reciprocal update that GDD still needs, not made in this pass** |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Villager AI & Behavior | MVP | ✅ Designed | The mutual seam's other direction: consumes this system's construction-job queue as its work supply (its Rules 4–7) — listed upstream above for what this system consumes FROM it, listed here because it cannot do its Work activity without this queue (added 2026-07-10, cross-review fix) |
| Build Validation & Navigability | MVP | ✅ Designed | Completed structures + construction-completed signals (contract confirmed by build-validation-navigability.md) |
| Building UI | MVP | Undesigned | Tool state, palette selection, wall-height, roof formation, undo/redo state, validity feedback *(provisional)*. **(Slice revision 2026-07-23)** additionally: Build Mode toggle, per-project window (state/release/pause/resume/Abriss/worker attribution), project-click selection, room-rect/auto-roof/house-template tool UX — **flagged reciprocal update, not made in this pass** |
| Onboarding / Tutorial | Vertical Slice | Undesigned | The MVP toolset as teachable verbs *(provisional)*. **(Slice revision 2026-07-23)** the slice's own tester needed one explanation round for the draft→release→build workflow and never discovered the door-gap convention unaided — both are now named onboarding-content requirements, not just "teach the six tools" |
| Township Progression | Alpha | Undesigned | Built structures as prosperity inputs *(provisional — prosperity variable itself still open)* |
| Economy Balance (Sinks) | Alpha | Undesigned | Future build costs as a resource sink *(provisional — costs not designed here, Core Rule 14; explicitly reaffirmed deferred by user decision 2026-07-22 — the Build Project entity, Rule 14e, is the confirmed future cost carrier)* |
| Save/Load & World Persistence | Vertical Slice | Undesigned | Blueprint cells + construction progress serialization; undo stack explicitly excluded *(provisional)* [TR-building-system-023] [TR-building-system-033]. **(Slice revision 2026-07-23)** must now also serialize: Build Project entities (state, kind, cell membership, worker-attribution history — the persistence Rule 14i explicitly requires), pending demolition orders, and floor-excavation `restore_value` entries |
| Resource & Item Database | Vertical Slice (Production) | Undesigned | **(Slice revision 2026-07-23, new)** a future `door`/`window` fixture category — pathing-transparent items that keep a room sealed for shelter analysis (Open Question 6); this system would place them via the existing Furniture tool pipeline (Core Rule 8) once they exist |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `wall_height` (player-adjustable stepper) | 3 | 1–8 | How tall a one-action wall extrudes (F1). Prototype-validated default. Raising the max above 8 risks accidental towers dominating the silhouette. **Lockstep invariant**: Build Validation's `max_room_height` (8) must stay ≥ this knob's maximum, and `villager_clearance` (3) equals this knob's default (= minimum walkable interior) — retune together (added 2026-07-10, cross-review fix) [TR-building-system-091] |
| `drag_threshold_px` | 6 | 4–12 | Click-vs-drag feel (F4). Too low: clicks become accidental drags; too high: short drags feel unresponsive. Prototype-validated |
| `base_build_ticks[block]` | 4 (= 2.0s at 1x) | 1–20 | Construction pacing per block (F3). The core "watching it take shape" pacing — tune against the MVP hypothesis (finishing a small house should feel earned, not tedious) |
| `base_build_ticks[furniture]` | 8 (= 4.0s at 1x) | 1–40 | Furniture construction pacing (F3) |
| `max_cells_per_command` | 512 | 128–2048 | Hard cap on blueprint cells per commit (Core Rule 9). 512 admits the longest possible wall (64-cell run × height 8); larger floors take multiple drags. Bounds preview draw calls, undo payload, and job-queue injection in one number [TR-building-system-049] |
| `preview_degradation_threshold` | 128 | 32–512 | Above this cell count, the live drag preview degrades from per-cell ghosts to an outline/bounding representation (Dragging state) — protects the frame budget on large drags while keeping the commit exact [TR-building-system-035] |
| `undo_stack_depth` | 50 | 10–200 | How far back a player can undo (Core Rule 17, Edge Case 9). Worst-case memory is now bounded and checkable: 200 commands × 512 cells × a small per-cell record ≈ low single-digit MB — negligible against the 4 GB ceiling. The cap exists for predictability |
| Unreachable-job retry cadence | see `unreachable_retry_ticks` (20) | — | Owned by the Villager AI GDD's Tuning Knobs (confirmed 2026-07-10) — pointer only, value not duplicated here |
| `project_merge_neighborhood` (Slice revision 2026-07-23) | 26 (full Moore) | {6, 18, 26} | Which cells count as adjacent for project grouping/change orders (F6, Core Rule 14c). 6 = face-only (stricter merging, more separate projects for the same footprint); 26 = default, matches the slice's "contiguous drafts merge" behavior including diagonal touches. Raising strictness (toward 6) makes projects feel more fragmented; the slice validated 26 only — 6/18 are named as an enum-safe range, not separately playtested `[assumption for the non-26 values]` |
| `draft_ghost_alpha` (Slice revision 2026-07-23) | 0.50 | 0.30–0.70 | Translucency of a Draft/Planned (unreleased or paused) blueprint ghost — the more tentative visual tier. Distinguishes an unreleased plan from released/queued work at a glance, alongside the existing Planned-vs-UnderConstruction distinctness requirement (TR-building-system-069) |
| `queued_ghost_alpha` (Slice revision 2026-07-23) | 0.70 | 0.50–0.90 | Translucency of a released/queued (BUILDING, not yet claimed) blueprint ghost — more opaque than Draft, reading as "committed to," short of UnderConstruction's progress-fill treatment. Must stay `> draft_ghost_alpha` or the two tiers become indistinguishable |
| `base_demolition_ticks[block]` (Slice revision 2026-07-23) | 4 `[assumption]` | 1–20 | Demolition pacing per block (F3 addendum, Rule 14j) — mirrors `base_build_ticks[block]`'s default as a neutral placeholder; the slice validated the job-gated *mechanism*, not this specific pace. Needs a dedicated tuning pass before Production |
| `base_demolition_ticks[furniture]` (added 2026-07-23, tick-rate/furniture resolution) | 8 `[assumption]` | 1–40 | Demolition pacing for furniture (F3 addendum, Rule 14j/16) — mirrors `base_build_ticks[furniture]`'s default as a neutral placeholder now that furniture removal is job-gated rather than instant (Rule 16); needs the same dedicated tuning pass as `base_demolition_ticks[block]` |
| Unstuck watchdog cadence (Slice revision 2026-07-23) | ~3s interim (validated as a safety net, not final) | — | Owned by the Villager AI GDD's Tuning Knobs — pointer only, value not duplicated here. The slice's watchdog + seal-prevention livelock guard is the interim mitigation; stuck telemetry (frequency counters) is the named Production requirement that will drive its real tuning |

All values are data-driven per the coding standard (no hardcoding); the
Building UI exposes only `wall_height` to the player — the rest are
designer-facing config. [TR-building-system-038]

## Visual/Audio Requirements

**Visual** (specs owned by art-director/art bible; requirements set here):

- **Picked-block highlight**: the block under the cursor is always visibly
  highlighted while a tool is armed (prototype-validated as essential). [TR-building-system-092]
- **Ghost previews** follow the Visual Direction Note's colorblind-safe
  blue–orange state axis: valid preview = cool blue-tinted translucent
  ghost; invalid = unmistakable orange tint. Never red-green. [TR-building-system-093]
- **Planned vs UnderConstruction** must be visually distinct: Planned =
  static translucent ghost; UnderConstruction = visible progress (e.g.
  scaffold/fill rising with tick progress — exact treatment to the art
  bible). [TR-building-system-069]
- **Materials** render per the database's `visual_asset` + the Note's
  material↔meaning families; blocks are FLUSH (cell_size 1.0, no gap —
  supersedes the prototype's 0.96). [TR-building-system-094]
- **New assets required**: ghost/preview materials (valid + invalid),
  under-construction treatment, picked-block highlight.

**Audio** (MVP-light):

- Commit confirm (soft placement sound), invalid-commit feedback (gentle
  negative, not punishing), per-cell completion tick, and a small
  "command complete" flourish when a whole wall/floor/roof finishes. [TR-building-system-095]
  Per-material placement sounds are a future schema field (Resource & Item
  Database Open Question 4) — not MVP.

## Game Feel

**Feel reference**: the 2026-07-09 concept prototype is the feel target
for the **planning loop** (pick → preview → commit, wall extrusion,
surface-aware editing, undo) — it was tuned hands-on until *"Ich finde
das super."* The **construction loop** (blueprint-then-build pacing,
watching blocks turn real) was explicitly OUT of the prototype's scope
and is a design hypothesis until the MVP playtest — its feel target is
Stonehearth's deliberate construction warmth crossed with Minecraft's
direct block authorship. *(The construction loop's felt weight is
delivered by Villager AI's visible labor — RESOLVED 2026-07-10: that GDD
is designed and owns the animation-to-progress lockstep in its Game Feel
section.)*

**Input responsiveness**:
- The ghost preview updates on the same frame as cursor movement (raw
  input path — Camera & Input uses raw delta precisely so this stays
  responsive even while the game is paused). [TR-building-system-096]
- Building while paused is fully allowed: tools, previews, commits, and
  undo all work in pause — only *construction progress* waits for game
  time. (Planning calmly while paused is core to "real-time with pause.") [TR-building-system-097]
- Commit feedback is immediate: blueprint ghosts appear the instant of a
  valid commit, even though blocks build over time. [TR-building-system-098]

**Impact moments** (triggers and channels specified here; exact asset
values to the art bible/audio spec, each with a measurable hook):
1. **Wall rise** — trigger: commit of a multi-cell command. Channels: all
   ghost cells appear on the SAME frame as the commit (never staggered),
   plus the commit-confirm sound (Visual/Audio Requirements). [TR-building-system-098]
2. **Per-cell completion** — trigger: a cell's Built transition. Channels:
   one completion tick sound per cell (rate-limited to at most one sound
   per frame when parallel villagers finish simultaneously — the batched
   write, Interactions) and a single-cell visual accent on the completed
   block (e.g., brief scale/brightness pop, ≤0.3s, non-blocking; exact
   curve to the art bible). [TR-building-system-099]
3. **Command completion** — trigger: the LAST cell of a command reaching
   Built. Channels: the "command complete" flourish sound (distinct from
   the per-cell tick) + a one-shot visual accent spanning the command's
   cells (≤1s; exact treatment to the art bible). Fires once per command
   regardless of size — a 1-cell command fires only this, not both a tick
   and a flourish. [TR-building-system-100]

**Weight profile**: planning is weightless (instant, fluid, undoable);
construction has weight (time, villager labor) — **delivered by Villager
AI's visible labor and animation-to-progress lockstep (its Game Feel
section), not by this system's timers alone**; this system supplies the
time cost (F3), Villager AI supplies the felt weight. This contrast IS
the design: expression stays frictionless while results feel earned.

**Feel acceptance criteria** (subjective, playtest-verified):
- A first-time player builds an enclosed room within minutes without
  instruction (re-verify the prototype result in the production build).
- No tester describes placement as "fiddly" or fights the camera/snapping.
- Undo is discovered and used naturally during free play.

## UI Requirements

Owned by the Building UI GDD (downstream); this system requires it to
present: tool palette (6 tools), material palette (tier-0 set, from the
database), wall-height stepper (1–8), roof-formation picker (4 formations),
undo/redo buttons with Ctrl+Z / Ctrl+Y bindings (prototype-validated; a
held key repeats at the OS key-repeat rate, each repeat = exactly one undo
step — no custom acceleration), and non-punishing invalid-commit feedback
near the cursor. [TR-building-system-101] All displayed state lives in this system; the UI renders
and triggers, never owns. [TR-building-system-076]

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| Prototype feel findings + tuning values | `prototypes/building-concept/REPORT.md` | Wall extrusion, surface-aware picking, drag threshold, roof formations, undo | Source of validated values for `wall_height` and `drag_threshold_px` ONLY — `base_build_ticks` is a design hypothesis, NOT prototype-measured (build-over-time was out of prototype scope) |
| Flush blocks, material families, blue–orange state axis | `design/art/visual-direction-note.md` | §2b, material↔meaning language | Visual constraint |
| Grid write/read/raycast ownership; natural-vs-built open question | `design/gdd/voxel-world.md` | Core Rules 2/5, Open Questions | Ownership boundary; this GDD resolves its open question (Core Rule 15) |
| Action signals, mouse world-ray, Suspended state, pan margin question | `design/gdd/camera-input.md` | Core Rules 7–10, Open Questions | Input contract; this GDD answers the pan-margin question (see Open Questions) |
| Tick events, pause/warp, max_ticks_per_frame | `design/gdd/time-tick-system.md` | Core Rules, Formulas | F3's time base + burst rule |
| Palette, tier-0 set, `bed`, visual_asset | `design/gdd/resource-item-database.md` | Core Rules 5–8, Open Question 1 | Data contract; this GDD resolves its Open Question 1 (bed only) |
| MVP definition, Pillar 1, anti-pillar (no terraforming) | `design/gdd/game-concept.md` | MVP Definition, Pillars | Scope authority |
| Construction-job queue contract | `design/gdd/villager-ai-behavior.md` | Job claim/abandon (its Rules 3–7, F1, F4) | CONFIRMED 2026-07-10 |
| Vertical slice validation — build/editor mode, projects, dig orders, draft eraser, floor excavation, multi-cell furniture, worker attribution, anti-stuck package | `prototypes/last-seal-vertical-slice/REPORT.md` | Playtest observations + Production requirements list | Source of ALL Slice revision 2026-07-23 content in this document — USER-CONFIRMED, not proposals (2026-07-22/23) |
| Door/window discoverability affordance handoff | `design/art/art-bible.md` §7.6 | Confirmed slice failure: "door = wall gap" undiscoverable without explanation | Cross-reference for Open Question 6; the affordance question stands until door/window ITEMS ship |

## Acceptance Criteria

*(`qa-lead` consulted during authoring (5 rewrites/splits + 9 missing
criteria) AND a second fresh qa-lead pass ran in the 2026-07-09 full
design review (3 more rewrites/splits + 11 added criteria: AC6b, 15/15b,
36/36b splits and AC39–49). Criteria marked [PROVISIONAL] depend on the
undesigned Villager AI GDD or the Vertical Slice roof shape spec — their
Building-System-owned halves remain blocking unit tests now. Note: AC22/
AC23 and AC27/AC29 are intentionally similar but test different
boundaries — unit mock vs. Time & Tick integration; mixed-state undo vs.
batch atomicity.)*

**Tools and mode**
1. **GIVEN** no active tool, **WHEN** a tool is selected, **THEN** the state is ToolArmed and a ghost preview follows the pick each frame. [TR-building-system-026]
2. **GIVEN** Tool A armed, **WHEN** Tool B is selected, **THEN** A deactivates and B arms — exactly one tool is ever active. [TR-building-system-042]
3. **GIVEN** a tool armed, **WHEN** cancel fires (Esc/right-click), **THEN** the state returns to Idle and the ghost is hidden. [TR-building-system-042]

**Placement, validity, and formulas**
4. **GIVEN** an armed tool with a valid pick, **WHEN** `build_place` commits, **THEN** blueprint cells are created exactly matching the visible preview. [TR-building-system-002]
5. **GIVEN** a 5-cell wall drag at `wall_height` 3, **WHEN** committed, **THEN** exactly 15 blueprint cells exist (F1). [TR-building-system-077]
6. **GIVEN** a wall click below the drag threshold, **WHEN** committed, **THEN** exactly 1 column of `wall_height` cells is created via the click path (F4). [TR-building-system-081]
6b. **GIVEN** a drag where `cursor_travel_px >= drag_threshold_px` but `start_cell == end_cell`, **WHEN** committed, **THEN** exactly 1 column of `wall_height` cells is created via the Dragging path (F1 degenerate — distinct code path from AC6). [TR-building-system-077]
7. **GIVEN** a floor drag of 3 cells in x and 4 in z, **WHEN** committed, **THEN** exactly 20 blueprint cells exist (F2). [TR-building-system-078]
8. **GIVEN** a drag started on a block at height y > 0, **WHEN** dragging, **THEN** all preview/committed cells lie on that block's plane, never the ground plane (Core Rule 3). [TR-building-system-043]
9. **GIVEN** a drag extending past world bounds, **WHEN** committed, **THEN** only the in-bounds portion shown by the preview is created (Edge Case 1). [TR-building-system-083]
10. **GIVEN** a commit targets a cell already holding a constructed block or terrain (not replace-in-place), **WHEN** `build_place` fires, **THEN** it is rejected with visible feedback and no blueprint is created. [TR-building-system-049]
11. **GIVEN** a commit targets a cell holding a blueprint cell, **WHEN** `build_place` fires, **THEN** it is rejected (Edge Case 3). [TR-building-system-085]
12. **GIVEN** a terrain cell, **WHEN** `build_remove` targets it, **THEN** removal is rejected (Core Rule 15). [TR-building-system-061]
13. **GIVEN** a built cell, **WHEN** `build_remove` targets it, **THEN** a demolition order is created and the cell is NOT removed immediately — the write occurs only once a claiming villager completes `base_demolition_ticks` on site (Core Rule 16, Slice revision 2026-07-23 — supersedes the prior "removed instantly" behavior). [TR-building-system-114]
13b. **GIVEN** a Draft or Queued/UnderConstruction (not-yet-Built) cell, **WHEN** `build_remove` targets it, **THEN** it is canceled instantly with no job — unchanged from before the slice (Core Rule 16's micro-state branch). [TR-building-system-123]
14. **GIVEN** a terrain cell, **WHEN** replace-in-place targets it, **THEN** the commit is rejected (Edge Case 2). [TR-building-system-084]
15. **GIVEN** the roof tool with the Flat formation and a 3×4 footprint drag, **WHEN** committed, **THEN** exactly 20 blueprint cells are created one plane above the footprint's highest picked surface (F5 Flat — testable now). [TR-building-system-082]
15b. **[PROVISIONAL — shape spec at VS]** **GIVEN** the roof tool with Gable/Hip/Shed and a footprint drag, **WHEN** committed, **THEN** a deterministic, non-zero cell set matching that formation is created, with the preview shown pre-commit (F5). [TR-building-system-007]
16. **GIVEN** the furniture tool with `bed` selected, **WHEN** targeting a cell with empty support below, **THEN** the commit is invalid; **WHEN** targeting a supported cell, **THEN** it is valid (Core Rule 8). [TR-building-system-048]
17. **GIVEN** furniture is in use, **WHEN** `build_remove` targets it, **THEN** a demolition order is created immediately (never blocked by usage), but the furniture is not removed and the occupant is not revoked until a villager completes that order *(Slice revision 2026-07-23, tick-rate/furniture resolution — supersedes the prior "removal succeeds immediately" assertion)* (Edge Case 11). [TR-building-system-064]
18. **GIVEN** the MVP data set, **WHEN** the palette is queried, **THEN** exactly the tier-0 materials and `bed` are offered (Core Rule 9). [TR-building-system-074]
19. **GIVEN** any MVP commit or completed construction, **WHEN** it occurs, **THEN** no resource is consumed (Core Rule 14). [TR-building-system-059]

**Construction and time**
20. **GIVEN** a blueprint cell fed `base_build_ticks` worth of tick events via a mocked on-site job, **WHEN** the last tick applies, **THEN** the Voxel World write occurs and the cell is Built (F3 — unit-testable without Villager AI). [TR-building-system-079]
21. **[PROVISIONAL — Villager AI]** **GIVEN** a real villager and a queued job, **WHEN** it claims, paths to site, and works, **THEN** the full claim→build→report cycle completes (integration test once that GDD lands). [TR-building-system-053]
22. **GIVEN** zero tick events are emitted over an interval, **WHEN** progress is checked, **THEN** UnderConstruction progress is unchanged (this system reacts only to ticks). [TR-building-system-058]
23. **GIVEN** the game is actually paused (integration), **WHEN** real time passes, **THEN** no construction progresses (companion to AC22, tested at the Time & Tick boundary). [TR-building-system-058]
24. **GIVEN** time-warp 2x, **WHEN** a cell builds, **THEN** wall-clock time halves but the tick count to complete is unchanged (F3 warp-invariance). [TR-building-system-079]
25. **GIVEN** a tick burst of 10, **WHEN** the current cell needs 2 more ticks, **THEN** that cell completes and no further queued cell receives leftover ticks that frame (F3 burst rule). [TR-building-system-080]
26. **GIVEN** the game is paused, **WHEN** a tool commits, **THEN** blueprint cells are created identically to the unpaused case (AC4); **WHEN** undo/redo fires, **THEN** the stack mutates and blueprints update exactly as when unpaused (building-while-paused, Game Feel). [TR-building-system-097]

**Undo/redo**
27. **GIVEN** a command with pending and already-built cells, **WHEN** undone, **THEN** pending cells are canceled and the already-Built cells are left standing untouched — no removal, no demolition order queued (Core Rule 17, Edge Case 7, Slice revision 2026-07-23 — supersedes "built cells are removed instantly"). [TR-building-system-119]
28. **GIVEN** an undone command whose cells are now partially occupied, **WHEN** redone, **THEN** only still-valid cells are re-created; invalid ones are dropped with feedback (Edge Case 8). [TR-building-system-088]
29. **GIVEN** a 15-cell wall command with a mix of still-pending and already-Built cells, **WHEN** undo fires once, **THEN** all still-pending cells cancel in that single step and the Built cells are left standing (per-command granularity is unchanged; Built-cell exclusion is new, Slice revision 2026-07-23). [TR-building-system-065] [TR-building-system-119]
30. **GIVEN** the stack holds `undo_stack_depth` commands, **WHEN** a new command commits, **THEN** the oldest is discarded silently (Edge Case 9). [TR-building-system-089]
31. **GIVEN** any undo has occurred, **WHEN** a new command commits, **THEN** the redo branch is cleared. [TR-building-system-089]
32. **GIVEN** a scene transition, **WHEN** it completes, **THEN** the undo stack is empty (Core Rule 17). [TR-building-system-066]
32b. **GIVEN** a 3-command undo stack, **WHEN** a transition is triggered but ABORTS (target scene fails to load), **THEN** all 3 commands remain undoable — no begin-signal side effect touched the stack *(added 2026-07-10 re-review: the undo-abort trap fix)*. [TR-building-system-066]
33. **GIVEN** a command's built cell was modified by another system, **WHEN** that command is undone, **THEN** the stale entry is skipped without error or double-removal (undo bookkeeping, Interactions). *(Slice revision 2026-07-23 — narrower in practice now: since undo never targets Built cells at all (AC27/29), this guards only the self-write-exemption bookkeeping around still-pending entries, not a built-cell removal race.)* [TR-building-system-071]

**Lifecycle and edge behavior**
34. **GIVEN** a scene transition, **WHEN** it completes, **THEN** pending blueprint cells and their construction progress persist — only the undo stack clears (Edge Case 10). [TR-building-system-090]
35. **GIVEN** a blueprint cell no villager can reach, **WHEN** any amount of game time passes, **THEN** the job remains queued and the ghost is never auto-canceled (Edge Case 5). [TR-building-system-087]
36. **GIVEN** a mocked "cell occupied" state for a construction-in-progress job, **WHEN** construction would start, **THEN** that cell's progress is skipped and the job stays queued while all other queued cells process normally (Edge Case 6 — Building-owned half, unit-testable now). [TR-building-system-037]
36b. **[PROVISIONAL — Villager AI]** **GIVEN** a real character occupying a construction target cell, **WHEN** construction would start, **THEN** the nudge-aside/deferral integration behaves per the Villager AI GDD (integration test once that GDD lands). [TR-building-system-037]
37. **GIVEN** Suspended is entered mid-drag, **WHEN** the transition starts, **THEN** the drag aborts with no commit and no partial blueprint (Edge Case 12). [TR-building-system-067]
38. **GIVEN** no valid pick (ray misses the world), **WHEN** `build_place` fires, **THEN** nothing happens and the ghost is hidden (Edge Case 4). [TR-building-system-086]

**Added by design review (2026-07-09)**
39. **GIVEN** a drag whose cell count would exceed `max_cells_per_command`, **WHEN** committed, **THEN** the commit is rejected with visible feedback and zero blueprint cells are created (Core Rule 9 cap). [TR-building-system-049]
40. **GIVEN** Suspended is entered (scene transition) while a cell is UnderConstruction, **WHEN** tick events continue, **THEN** construction progress continues to accumulate — Suspended halts tool interaction only, never construction (Edge Case 10). [TR-building-system-090]
41. **GIVEN** a Planned blueprint cell, **WHEN** the player directly removes it (not via undo), **THEN** it transitions to Canceled, the ghost is removed, and any claimed job is revoked (Blueprint lifecycle). [TR-building-system-068]
42. **GIVEN** an armed placement tool with no material/furniture selected, **WHEN** `build_place` fires on an otherwise valid pick, **THEN** the commit is rejected with visible feedback (Core Rule 9). [TR-building-system-049]
43. **GIVEN** a mocked job-claim for a Planned cell, **WHEN** the claim registers, **THEN** the cell transitions to UnderConstruction and its state is queryable as distinct from Planned (Blueprint lifecycle; feeds the visual-distinctness requirement). [TR-building-system-068]
44. **GIVEN** Dragging state, **WHEN** a different tool is selected mid-drag, **THEN** the drag aborts with no commit (Tool state table exit). [TR-building-system-067]
45. **GIVEN** two villagers with claimed jobs on distinct cells of the same command, **WHEN** a tick burst arrives, **THEN** each job's progress advances independently and at most one cell completes per villager that frame (F3 per-villager burst rule). [TR-building-system-080]
46. **GIVEN** this system completes a cell (its own Voxel World write), **WHEN** its undo-invalidation listener receives the resulting write signal, **THEN** the signal is recognized as self-originated and NO undo entry is invalidated (Interactions self-write exemption). [TR-building-system-024]
47. **GIVEN** N cells complete in the same frame (parallel villagers or multi-cell undo removal), **WHEN** the writes are issued, **THEN** Voxel World's bulk-write API is used and exactly ONE batched signal fires (Interactions batching rule). [TR-building-system-072]
48. **GIVEN** a job is reported unreachable, **WHEN** the report registers, **THEN** the affected ghost switches to the pulsing orange unreachable tint and the non-modal UI hint appears; **WHEN** the obstruction is removed and the job is claimed again, **THEN** the ghost returns to the normal Planned visual (Edge Case 5). [TR-building-system-087]
49. **GIVEN** the furniture tool, **WHEN** a bed blueprint targets a cell supported by a *blueprint* floor cell, **THEN** the commit is valid but the bed's construction cannot start until the support cell is Built (Core Rule 9 furniture clarification). [TR-building-system-050]

**Added by re-review (2026-07-10)**
50. **GIVEN** a drag whose pending cell count exceeds `preview_degradation_threshold`, **WHEN** the preview updates, **THEN** it renders as an outline/bounding representation rather than per-cell ghosts, while the eventual commit remains cell-exact (Dragging state, Tuning Knobs). [TR-building-system-039]
51. *(Cross-reference, not a Building AC)*: the full claim→build→report integration cycle promised by AC21 is concretely owned by **Villager AI AC40/40b** (added 2026-07-10); AC21 is fulfilled by those tests. Performance at population scale is gated by **Villager AI AC39** (milestone-gated) — this system's per-villager burst cost (F3) is part of what that AC measures.

**Added by the vertical slice (2026-07-23) — Build Mode, Projects, Demolition/Dig, Undo scope, Floor Excavation, Multi-Cell Furniture**
*(all BLOCKING logic/state-machine unit tests per the testing standard unless marked otherwise; items citing Villager AI's claim/on-site mechanics are marked PROVISIONAL, mirroring AC21/36b)*

**Build/editor mode**
52. **GIVEN** Build Mode Off, **WHEN** a tool-select action fires, **THEN** Build Mode transitions to On and the selected tool arms in the same action (Rule 8b). [TR-building-system-102] [TR-building-system-103]
53. **GIVEN** Build Mode On at Idle (no tool armed), **WHEN** Esc fires, **THEN** Build Mode transitions to Off and world clicks return to selection; **GIVEN** a tool armed or a drag in progress, **WHEN** Esc fires, **THEN** only that layer exits and Build Mode remains On (Esc chain, Rule 8c). [TR-building-system-104]
54. **GIVEN** Build Mode Off, **WHEN** a world click fires, **THEN** this system does not consume it at all — no tool, ghost, or commit is reachable (Rule 8d). [TR-building-system-105]

**Project grouping and merge**
55. **GIVEN** two separate commits whose cells are 26-adjacent (F6), **WHEN** the second commits, **THEN** both sets of cells belong to exactly one Build Project (Rule 14c). [TR-building-system-107]
56. **GIVEN** a single commit batch that touches two previously separate same-kind projects at once, **WHEN** resolved, **THEN** both merge into one project keyed by the lower (earlier-created) project id, deterministically regardless of cell iteration order (Rule 14c, Edge Case 13). [TR-building-system-107]

**Per-project release and worker attribution**
57. **GIVEN** a project in DRAFT, **WHEN** "Bau starten" is pressed, **THEN** every one of its cells becomes job-eligible BUILDING work, and none of them were claimable before that action (Rule 14f). [TR-building-system-109]
58. **[PROVISIONAL — Villager AI]** **GIVEN** a villager claims a job on a BUILDING project's cell, **WHEN** the claim registers, **THEN** the villager's id is recorded on that cell and rolled up onto the project's worker-attribution record, queryable by Building UI (Rule 12/14f — the claim mechanic itself is Villager AI's, the recording contract is this system's). [TR-building-system-109]

**Pause/Resume**
59. **GIVEN** a BUILDING project, **WHEN** paused, **THEN** no new jobs are offered and any in-flight claim is revoked gracefully (mirrors Edge Case 4); **WHEN** later resumed, **THEN** the same remaining cells become job-eligible again without re-creating them (Rule 14g). [TR-building-system-110]

**Persistence and click-selection**
60. **GIVEN** a project whose every cell has reached Built/Removed, **WHEN** checked, **THEN** the project entity still exists as DONE — it is never deleted on completion (Rule 14i). [TR-building-system-111]
61. **GIVEN** a project whose last remaining cell is canceled or demolished/excavated away, **WHEN** that resolves, **THEN** the project entity itself is deleted — the one and only condition under which a project disappears (Rule 14i). [TR-building-system-111]
62. **GIVEN** any project in any state (DRAFT/BUILDING/PAUSED/DONE) and no tool armed, **WHEN** one of its cells is clicked, **THEN** the project is selected — this works in Build Mode Off too, the sole exception to AC54 (Rule 14i/8d). [TR-building-system-113]

**Change orders**
63. **GIVEN** a DONE project, **WHEN** a new 26-adjacent commit is made, **THEN** it attaches as a pending "Änderungen geplant" batch on the SAME project (not a new project) and the project's already-Built cells are unaffected (Rule 14h). [TR-building-system-112]
64. **GIVEN** that pending batch, **WHEN** it alone is released, **THEN** only its cells become job-eligible BUILDING work — the project's other, already-Built cells are untouched by that release (Rule 14f/14h). [TR-building-system-112]

**Demolition orders and Abriss**
65. **GIVEN** a Built cell targeted by the removal tool, **WHEN** it fires, **THEN** a demolition order is created already in released/BUILDING state — no separate "Bau starten" step is needed for teardown (Rule 14j). [TR-building-system-114] [TR-building-system-115]
66. **GIVEN** a demolition job fed `base_demolition_ticks` worth of on-site tick events via a mocked claim (mirrors AC20's mocked-job pattern), **WHEN** the last tick applies, **THEN** the Voxel World clear occurs and the cell is gone (Rule 14j). [TR-building-system-115]
67. **GIVEN** a project with both remaining Draft cells and Built cells, **WHEN** Abriss (project cancel) fires, **THEN** the Draft cells cancel for free instantly AND every Built cell receives an already-released demolition order, all in one action (Rule 14k). [TR-building-system-117]

**Undo scope (plan-only)**
68. **GIVEN** a command whose cells have all already reached Built (nothing pending remains), **WHEN** undo fires, **THEN** nothing happens to those cells — undo has zero effect on fully-Built work, not even queuing a demolition order (Rule 17, companion to AC27/29). [TR-building-system-119]

**Floor excavation**
69. **GIVEN** a floor-tool drag started on a terrain top surface, **WHEN** committed, **THEN** the terrain cell is replaced flush (not stacked into a step) and its original value is captured as `restore_value` on the blueprint entry (Rule 14l). [TR-building-system-120]
70. **GIVEN** such an entry is later canceled, undone while still pending, or demolished, **WHEN** resolved, **THEN** the captured `restore_value` is written back in place of the cell — never left empty (Rule 14l, Edge Case 18). [TR-building-system-120]

**Dig projects and on-site exclusion**
71. **GIVEN** the removal tool targets a terrain cell, **WHEN** committed, **THEN** Draft dig cells are created in a new or existing `dig`-kind project, and this project never merges with an adjacent `build`-kind project even if 26-adjacent (Rule 14m, Edge Case 14). [TR-building-system-121]
72. **[PROVISIONAL — Villager AI]** **GIVEN** a released dig cell, **WHEN** a villager's on-site eligibility is evaluated, **THEN** standing on the target cell itself never counts as on-site — only an orthogonal neighbor cell does (Rule 14m's amendment to TR-building-system-056, Edge Case 20). [TR-building-system-122]

**Draft eraser (removal-tool branching)**
73. **GIVEN** the removal tool targets a cell still in Draft micro-state, **WHEN** it fires, **THEN** the cell is erased instantly with no job created and no notification (Rule 16, Edge Case 16). [TR-building-system-123]
74. **GIVEN** the removal tool targets a Queued/UnderConstruction (released but not yet Built) cell, **WHEN** it fires, **THEN** it cancels instantly and any claimed job is revoked — unchanged from the pre-slice behavior (Rule 16's micro-state branch). [TR-building-system-123]

**Multi-cell furniture**
75. **GIVEN** the furniture tool with `bed` selected targeting an anchor cell whose 1×2 footprint is only partially supported or partially blocked, **WHEN** committed, **THEN** the entire commit is rejected — there is no partial placement of a multi-cell item (Rule 8, Edge Case 19). [TR-building-system-124]
76. **GIVEN** a valid `bed` commit, **WHEN** it resolves, **THEN** exactly one furniture entity is created spanning both footprint cells, each cell referencing the same occupant id (F5, `furniture_cell_count = 2`). [TR-building-system-124]

**Higher-level tools (system-side contract only)**
77. **GIVEN** a house-template stamp whose internally-generated sub-shapes (walls/floor/roof) would not all be mutually 26-adjacent on their own, **WHEN** committed as one action, **THEN** every resulting cell belongs to exactly one project (Rule 14d) — the tool's own UX (room-rect, auto-roof, template picker) is Building UI's to design; this AC covers only this system's batch-merge guarantee. [TR-building-system-126]

## Open Questions

1. **Villager AI job contract** — **RESOLVED 2026-07-10**: the queue
   semantics are owned here (Core Rule 12); `villager-ai-behavior.md`
   confirms the contract and supplies every remaining half — claim
   mechanics + atomic race handling (its Rules 4, Edge Case 3), graceful
   abandon (its Rule 3), retry cadence (`unreachable_retry_ticks`, its
   Tuning Knobs), nudge-aside (its Rule 7 + F4), and the arrival/
   tick-boundary rule feeding F3 (its F1).
2. **Roof shape algorithms** — the per-formation cell-set functions behind
   F5 (Gable/Hip/Shed geometry over arbitrary footprints, odd-width
   ridges, minimum footprints). → *roof shape spec at Vertical Slice
   detail (game-designer + art-director)*
3. **Natural-vs-built distinction implementation** — Voxel World data flag
   vs. this system's own built-cell record (Core Rule 15 resolved the
   *design* question with "yes, needed"; the *mechanism* is architectural).
   → *building ADR via `/create-architecture`*
3b. **Mid-path solidification race** *(added by the 2026-07-10 re-review;
   RESOLVED 2026-07-11 via ADR-0009)* — villager movement is continuous
   game-delta interpolation (Villager AI F1), but Edge Case 6's "a cell
   never becomes solid under a character" guarantee is tick-discrete.
   **Resolution**: a villager's occupied cell is always the discrete,
   tick-boundary-quantized `current_cell` (it occupies its `from_cell`
   for the whole transit, never the `to_cell` until arrival) — this
   system's occupancy check always reads that discrete value, never an
   interpolation-progress float. [TR-building-system-040] The blueprint-completing-mid-transit
   case (a villager walking through a still-non-solid blueprint location
   when it completes, per the intentional non-solid-blueprints rule, Core
   Rule 14b) is one instance of the general race ADR-0009 resolves: Voxel
   World's write signal fires synchronously, so Villager AI's existing
   re-path-on-blocking-write contract redirects the villager before its
   next frame's visual interpolation advances further — no special-case
   handling needed beyond the general mechanism.
   → *ADR-0009 (cross-pointer in villager-ai-behavior.md OQ 3)*
3c. **Aggregate ghost ceiling + degraded-preview mechanism** *(added by
   the 2026-07-10 re-review)* — no settlement-wide cap exists on
   simultaneous Planned/UnderConstruction ghosts (only per-command 512 +
   per-preview 128), and the degraded outline preview has no stated
   draw-call story or re-rasterization cadence. Both are rendering-budget
   concerns for whichever approach the building ADR picks; the memory
   claim in Tuning Knobs should also gain an explicit per-record byte
   assumption there. → *building ADR + pre-VS performance spike* [TR-building-system-041]
4. **Rendering/meshing approach** — GridMap vs MultiMesh vs chunked/greedy
   mesher (inherited from game-concept; blueprint ghosts add a rendering
   requirement to whichever approach wins). → *building ADR*
5. **Alpha cost model** — where costs attach in the blueprint pipeline
   (reserve at commit vs consume at construction), hauling integration
   (Stonehearth model per user intent). → *Gathering & Production Chains +
   Storage & Inventory GDDs (Alpha)*
6. **Doors/windows at Vertical Slice** — how openings integrate with the
   wall tool (punch through existing walls? a dedicated fixture tool?).
   → *this GDD's VS revision*
7. **Should this system passively warn about unlivable structures** —
   **RESOLVED 2026-07-10**: fully split and owned. The
   unreachable-*blueprint* half lives here (Edge Case 5, orange ghosts);
   the completed-structure half lives in
   `build-validation-navigability.md` (sealed-space warnings, room
   detection, the 3-tier shelter recovery ladder). This system still
   never blocks (Core Rule 10 unchanged).
