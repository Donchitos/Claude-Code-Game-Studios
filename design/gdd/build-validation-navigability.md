# Build Validation & Navigability

> **Status**: Approved (2026-07-10 — full review NEEDS REVISION → revised; re-review NEEDS REVISION (narrow) → patched; verification pass CLEAN)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-10
> **Last Verified**: 2026-07-10
> **Implements Pillar**: Pillar 4 — Clarity over complexity (visible validity, legible warnings); Pillar 1 — The building IS the game (rooms gain meaning); Pillar 3 — Cozy, but with stakes (gentle guidance, never blocking)

## Summary

Build Validation & Navigability is the game's structural analyst: it
watches what the player builds (via the Building System's
construction-completed signals) and answers two questions the builder
systems deliberately don't — *"is this a room?"* (enclosure detection:
floor, walls, roof) and *"can a villager actually get there?"*
(reachability, using Villager AI's exact walkability rules —
`villager_clearance` = 3, `max_step_height` = 1, registered constants).
It never blocks anything (Building System Core Rule 10); it recognizes,
confirms, and gently warns: a completed room earns its "shelter" status,
and a walled-in bed earns a visible, fixable warning instead of silent
villager failure.

> **Quick reference** — Layer: `Feature/Gameplay` · Priority: `MVP` · Key deps: `Building System, Villager AI & Behavior`

## Overview

**Player-facing:** this system is how the game *understands* what the
player built. Its two player-visible outputs are a confirmation and a
warning. The confirmation: when walls, floor, and roof close around a
space with a usable way in, the game recognizes "a room" — the concept's
core loop payoff ("complete a house — shell → furnish → villager moves
in") gets its formal moment. The warning: when something the villagers
need is unreachable (a bed sealed behind walls, per the no-doors MVP), a
gentle, non-modal cue appears — complementing the Building System's
orange unreachable-*blueprint* ghosts (its Edge Case 5) with the
completed-structure half the review flagged as its Open Question 7. Per
Pillar 4 the player always sees WHY something is invalid; per Pillar 3
the tone is guidance, never punishment; per Core Rule 10 of the Building
System, nothing is ever prevented — the player may build "wrong" freely.

**System-facing:** this is a pure analysis layer — it owns no world
data and mutates nothing. It consumes: the Building System's
construction-completed/removed signals and combined planned-occupancy
view, Voxel World's physical occupancy, and Villager AI's walkability
definition (consumed verbatim, never redefined — its Rule 10). It
produces: room/enclosure status, per-object reachability status, and
the signals the Villager Info UI and Needs display build on. Analysis
runs incrementally on structure-change events, not per frame.

Out of scope: pathfinding itself (Villager AI / AI ADR), blocking or
auto-correcting placements (never — Building Core Rule 10), the
NavigationServer3D/rebake implementation question (building ADR), and
whether enclosure affects need recovery values (a design decision made
in Section C, with the value table owned by Needs & Mood).

## Player Fantasy

**"The game sees what I made."**

An indirect fantasy of *recognition and gentle stewardship support*:

1. **Being understood.** I pile up walls, a floor, a roof — and the game
   says "that's a room." My creation isn't just blocks to the simulation;
   it has *meaning*. (The formal delivery of Pillar 1's promise that
   building carries function.)
2. **The completion beat.** The moment the last roof block settles and
   the room registers is a micro-payoff on the way to the concept's core
   loop peak ("complete a house... villager moves in") — recognition
   makes finishing feel *official*.
3. **A helpful eye, not a hall monitor.** When I've accidentally sealed
   the bed in, the game quietly points instead of scolding or stopping
   me. I stay the author; the game is a considerate assistant. NOT the
   fantasy: a building-code inspector (blocking), a nagging tutorial, or
   a puzzle validator with pass/fail states.

Reference feeling: Stonehearth's room detection ("this is now a
bedroom") and The Sims' room recognition — both make enclosure feel
meaningful without policing it.

> `creative-director` not consulted — Lean mode (non-high-risk section).
> Sourced from game-concept.md core loop + Pillars 1/3/4. Review manually
> before production.

## Detailed Design

### Core Rules

**Room detection (the no-doors MVP definition)**

1. A **candidate interior cell** is a cell that is **standable per
   Villager AI's Rule 8, consumed verbatim** — a solid cell directly
   below (built floor or terrain) and the cell plus the two cells above
   it empty (`villager_clearance` = 3) — AND **roofed**: scanning
   straight up from the cell, the NEAREST solid cell sits at most
   `max_room_height` (default 8) above it. [TR-build-validation-navigability-021] Standability already
   guarantees that roof is at least `villager_clearance` cells up — a
   crawlspace (roof 1–2 above the floor) is never interior (Edge Case
   13). For this analysis, furniture occupancy is transparent: a cell
   occupied by furniture evaluates as if empty (furniture never counts
   as floor, wall, or roof), so a furniture item's own cell has a
   well-defined candidate status (Rule 5, Edge Case 8). [TR-build-validation-navigability-022] **"Solid" means
   Voxel World block occupancy only** — character positions (including
   a villager mid-F4-vacate) never affect candidacy; this analysis
   reads only static physical occupancy (AC38 guards the isolation). [TR-build-validation-navigability-023] A
   **candidate region** is a maximal orthogonally-connected set of
   candidate interior cells (orthogonal adjacency defines region
   *membership* only; movement/reachability uses the villager movement
   graph, Rule 2). [TR-build-validation-navigability-024]
2. A candidate region is a **valid room** iff: it has at least
   `min_room_cells` (default 2) interior cells, AND at least one
   villager-walkable connection to the outside world exists. [TR-build-validation-navigability-025] Both halves
   of that test are pinned:
   - **The reach graph is the villager movement graph, consumed
     verbatim** (Villager AI Rules 8–9: standability with
     `villager_clearance` = 3, orthogonal steps with `max_step_height`
     = 1, and diagonal steps ONLY when both flanking orthogonal cells
     are passable — no corner-cutting). It is NOT a plain 4- or
     8-neighbor flood-fill: it is exactly the graph a villager may walk. [TR-build-validation-navigability-008]
   - **The outside world** is any standable cell that is NOT roofed (no
     solid cell within `max_room_height` straight above — open sky, the
     same scan as Rule 1). The connection test walks the movement graph
     outward from the region's interior cells until it reaches an
     open-sky standable cell, or exhausts all reachable cells (→
     Sealed). [TR-build-validation-navigability-009] Reaching another enclosed space's interior is NOT
     "outside" — a chain of enclosed spaces is outside-connected only
     if the chain reaches open sky. **The trace may pass through any
     standable cell, including another region's interior** (2026-07-10
     re-review ruling): two regions touching only corner-to-corner
     remain two regions (Rule 1 membership is orthogonal), but a legal
     flanked diagonal between them constitutes a genuine opening — a
     villager can physically walk that route, so a region whose only
     path to open sky runs through its corner-neighbor's interior and
     door IS outside-connected. Intended, not borrowing (Edge Case 14). [TR-build-validation-navigability-026]
   The MVP's "door" is simply a walkable gap in the walls; Vertical
   Slice doors will formalize these openings without changing this
   definition.
3. A candidate region with NO walkable connection to the outside is a
   **sealed space** — never a room. If it contains furniture, it raises
   the sealed-space warning (Rule 8); if empty, it is silently ignored
   (players may build solid decorative masses freely). [TR-build-validation-navigability-027]
4. Room detection confers no persistent identity in MVP — rooms are
   re-derived facts about the world, not named objects. [TR-build-validation-navigability-028] (Room
   naming/assignment is a future feature, see Open Questions.)

**Shelter status and the recovery ladder**

5. A piece of furniture is **sheltered** iff its cell lies inside a valid
   room; otherwise it is **unsheltered**. This flag is this system's one
   mechanical output. [TR-build-validation-navigability-029]
6. The sleep recovery ladder consumes the flag: **sheltered bed = 1.0 ·
   unsheltered bed = `unsheltered_bed_multiplier` (0.7) · ground =
   `ground_penalty` (0.4)**. The rate values remain owned by the Needs &
   Mood GDD's source→rate table (this GDD supplies only the
   sheltered/unsheltered classification — its table gains one row,
   patched with permission). [TR-build-validation-navigability-030] This is Pillar 1 made literal: the *room* is
   worth +30% sleep quality over the bare bed.
7. Analysis is **event-driven, never per-frame**: re-evaluation of the
   affected region runs when the Building System signals a construction
   completed or a built cell removed (its batched signals bound the event
   rate). Between events, all statuses are stable. [TR-build-validation-navigability-006] MVP analyzes **built
   structures only** — blueprint-stage unreachability is already covered
   by the Building System's orange ghosts (its Edge Case 5). [TR-build-validation-navigability-031]

**Warnings and confirmations (never blocking)**

8. Three player-facing outputs, all non-modal, severity-tiered:
   - **Confirmation** (positive): a candidate region becomes a valid room
     → the "room recognized" moment (one-shot celebration cue +
     persistent subtle status; edge-detected and paced per Rule 11). [TR-build-validation-navigability-032]
   - **Warning — sealed space with need-functional furniture**:
     **need-functional** furniture (furniture with a need-recovery
     function — MVP: the bed; decorative/inert furniture never warns)
     exists in a sealed space → persistent gentle warning naming the
     problem ("the bed can't be reached — the room has no opening"). [TR-build-validation-navigability-033]
   - **Info — unsheltered bed**: a claimed/placed bed outside any valid
     room AND not inside a sealed space (i.e. in the open) → low-key
     hint ("a roof would make this a proper home"), because it works,
     just sub-optimally. [TR-build-validation-navigability-034]
   **The tiers are mutually exclusive per furniture item — Warning
   supersedes Info**: a bed in a sealed space emits the sealed-space
   Warning only, never additionally the unsheltered Info hint (one
   problem, one cue — a helpful eye, not a nag). [TR-build-validation-navigability-035] The mechanical
   `shelter_status_changed` flag (Rule 10) is independent of both tiers
   and fires for ALL furniture regardless of type. [TR-build-validation-navigability-036]
9. This system never blocks, reverts, or auto-fixes a placement (Building
   System Core Rule 10). [TR-build-validation-navigability-037] It also never moves villagers or triggers
   behavior — Villager AI does its own reach checks at claim time (its
   F2/Rule 11); this system's outputs are for the *player's*
   understanding. [TR-build-validation-navigability-038]

**Signal contract and analysis memory**

10. **Signal contract** — this system emits exactly four signals; no
    other emissions exist [TR-build-validation-navigability-039]:

    | Signal | Payload | Trigger | Consumers |
    |--------|---------|---------|-----------|
    | `shelter_status_changed` | item id, `sheltered: bool` | A furniture item's sheltered flag transitions (Rule 5) — exactly one emission per transition, for ALL furniture types | Needs & Mood (recovery ladder), UIs [TR-build-validation-navigability-036] |
    | `room_recognized` | region cells, `celebrate: bool`, `pass_group_id` | A region transitions non-Room → Room (edge-detected per Rule 11; `celebrate` paced per Rule 11; all emissions from one analysis pass share one `pass_group_id` — the same-pass grouping rule, Rule 11) | UIs (one-shot cue + quiet persistent status) [TR-build-validation-navigability-040] |
    | `sealed_space_warning` | region cells, affected item ids, why-string | Every qualifying analysis pass while a sealed space contains need-functional furniture (re-emit semantics, AC22) | UIs [TR-build-validation-navigability-041] |
    | `unsheltered_furniture_info` | item id, why-string | Every qualifying analysis pass while a bed sits unsheltered in the open (Rule 8 exclusivity: never for sealed-space items) | UIs [TR-build-validation-navigability-042] |

    Warning and Info are separate typed signals, not severity payloads
    of one signal. `shelter_status_changed` is the only signal Needs
    consumes; the other three are presentational. [TR-build-validation-navigability-043] All current statuses
    are additionally queryable at any time (state + events model — the
    same consumption contract Needs & Mood established). [TR-build-validation-navigability-044] **All
    emissions of one analysis pass are delivered synchronously within
    one frame; consumers may treat same-frame delivery as one pass —
    the reconciliation unit** *(added 2026-07-10, Building UI review:
    grounds its tier-swap detection; the warning/info signals carry no
    explicit pass id — `room_recognized`'s `pass_group_id` exists for
    celebration grouping only)*. [TR-build-validation-navigability-045]
    **There is deliberately NO "cleared" signal**: Warning/Info are
    level-triggered re-emissions, and their clearing mechanism IS the
    cessation of re-emission plus the queryable current state — the UI
    reconciles its active toasts against each pass's emissions. [TR-build-validation-navigability-046] A tier
    change (e.g. the seal is fixed but the bed remains unsheltered in
    the open) therefore appears as the Warning ceasing and the Info
    beginning in the same pass; the UI must retire the stale Warning
    surface in favor of the new Info hint as part of that reconcile
    (flagged in UI Requirements' seam). [TR-build-validation-navigability-047]
11. **Transient analysis memory (edge detection + pacing).** The system
    keeps a transient, never-serialized snapshot of the previous
    analysis result (per-cell region classification + per-item shelter
    flags), used ONLY to edge-detect transitions (Rules 8/10) — it is
    memory for eventing, never a compute cache. [TR-build-validation-navigability-048] Region continuity for
    the one-shot: a newly valid room fires `room_recognized` only if
    NONE of its interior cells belonged to a valid room in the previous
    snapshot — merges and splits of existing rooms never re-fire it. [TR-build-validation-navigability-049]
    (Accepted consequence, MVP: a previously-Sealed pocket merging into
    an existing valid room gets no celebration — the region as a whole
    was not "new"; its furniture's `shelter_status_changed` still fires
    correctly.)
    **Snapshot updates are incremental**: after a pass, only the
    entries touched by that pass's affected region (cells + items) are
    patched; untouched entries persist unchanged. A full snapshot
    rebuild happens ONLY on the load pass — an implementation that
    rebuilds the whole snapshot per event would silently reintroduce
    O(world) cost and violate Rule 7's event-scoping (see Open
    Question 5). [TR-build-validation-navigability-006]
    Celebration pacing: at most one celebration per
    `room_cue_cooldown_ticks` (Tuning Knobs) — with a **same-pass
    grouping rule** (2026-07-10 re-review, user decision): ALL rooms
    recognized in one analysis pass emit `room_recognized` with
    `celebrate = true` and a shared `pass_group_id`; the UI presents
    the group as ONE combined celebration (one chime, highlights on
    all rooms — finishing two huts at once is one moment, never an
    arbitrary winner). The cooldown window starts after the group;
    recognitions in LATER passes inside the window emit with
    `celebrate = false` (quiet status only). [TR-build-validation-navigability-050] On world load, the
    initial full pass (Edge Case 11)
    seeds the snapshot silently: statuses become queryable, but no
    transition events (`shelter_status_changed`, `room_recognized`)
    fire; Warning/Info emissions DO fire on the load pass (they reflect
    persisting causes, not transitions — a sealed bed is re-warned
    immediately after load). [TR-build-validation-navigability-051] This refines Rule 4: "no persistent
    identity" means nothing serialized and no player-facing room
    objects — the transient snapshot is rebuilt from the world on every
    load. [TR-build-validation-navigability-028]

### States and Transitions

**Per candidate region:**

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Open | Region fails enclosure (no roof/floor coverage or below `min_room_cells`) | Structure change re-evaluation | No status shown — just ordinary outdoors/incomplete construction |
| Room (valid) | Enclosure met + walkable outside connection | Structure change breaks a condition | "Room recognized" one-shot on entry; furniture inside is sheltered |
| Sealed | Enclosure met, NO walkable outside connection — reachable from Open directly (one command can enclose and seal a box in a single commit) or from Room (the last gap closes) | An opening is created / region dissolves | Sealed-space warning iff need-functional furniture inside (Rule 8); furniture inside is unsheltered (a sealed "room" shelters no one) [TR-build-validation-navigability-027] |

**Per furniture item:** Sheltered ↔ Unsheltered (derived purely from its
cell's region state; changes emit a status event for the Needs recovery
ladder and the UI).

### Interactions with Other Systems

- **Building System** (upstream, MVP): construction-completed/removed
  signals trigger re-analysis. **Contract: completion signals are
  batched per FRAME** (the same batching mandate as its Voxel World
  bulk-writes) — N cells completing in one frame, across any number of
  commands and villagers, reach this system as ONE signal → at most one
  re-analysis pass per frame from construction (Edge Case 10, AC19;
  reciprocal note added to building-system.md 2026-07-10). [TR-build-validation-navigability-052] The combined
  planned-occupancy view is available but unused in MVP (built-only
  analysis, Rule 7). Resolves its Open Question 7 (completed-structure
  warnings live here).
- **Villager AI & Behavior** (upstream, MVP): walkability definition
  consumed verbatim (its Rules 8–10; registry constants). [TR-build-validation-navigability-010] No runtime
  calls in either direction — this system runs its own region/reach
  analysis using the same rules; villager pathing stays the AI's own job. [TR-build-validation-navigability-053]
- **Voxel World** (upstream, MVP): physical occupancy reads for the
  region analysis. Read-only. [TR-build-validation-navigability-054]
- **Needs & Mood System** (MVP, downstream): consumes the
  sheltered/unsheltered flag per bed for its source→rate table (extended
  to the 3-tier ladder — patch). Values stay owned there. [TR-build-validation-navigability-030]
- **Villager Info UI / Building UI** (MVP, downstream, provisional):
  display the warnings, info hints, and room confirmations; the
  why-string ("no opening") comes from this system. Dismissal/re-show
  presentation — including a minimum re-show interval so a dismissed
  warning does not re-pop while the player is actively editing the
  affected region — is owned THERE (this system re-emits per pass,
  AC22). The on-demand inspection surface (room-status query,
  active-warnings review list) is likewise a UI-owned seam over this
  system's queryable state (Rule 10) — flagged for those GDDs' reviews.
- **Township Progression** (Alpha, downstream, provisional): "housed
  villagers" (owned bed, sheltered) is an obvious prosperity input —
  flagged as a seam, not designed here.
- **Save/Load** (Vertical Slice, downstream, provisional): nothing to
  serialize — all statuses are re-derivable from the world on load (a
  deliberate property of Rule 4). [TR-build-validation-navigability-028]

## Formulas

*(`systems-designer` consulted — mandatory for this high-risk section
even in Lean mode. Verdict: this system owns no formulas; one hidden
tuning invariant found and recorded in Tuning Knobs.)*

**None.** This system evaluates boolean predicates over an
algorithmically-detected region (flood-fill class, deferred to the
building/AI ADR) and passes through a classification flag consumed by
the Needs & Mood GDD's rate table — there is no original numeric
computation here to formalize.

Deliberately NOT formulas (and why):
- **Room validity** — a boolean predicate over Core Rules 1–3 (threshold
  comparisons and reachability), not a value computation.
- **Region detection / outside-connection test** — flood-fill/BFS-class
  algorithms; same treatment as Voxel World's raycast: deferred to the
  ADR. Analysis scope is bounded by connectivity itself, not by an
  arbitrary radius — deliberately unbounded by any knob: the affected
  region is fully recomputed per event, with no caching or incremental
  delta in MVP (Rule 11's snapshot is edge-detection memory, not a
  compute cache). [TR-build-validation-navigability-020] The cost axis this creates — region size grows with
  cumulative *connected build footprint*, independent of villager count
  — is MVP-reachable and explicitly measured by Open Question 5.
- **Recovery ladder values** (1.0 / 0.7 / 0.4) — owned by the Needs &
  Mood source→rate table; this system supplies only the sheltered flag.
- **Warning debounce** — inherited from the Building System's batched
  signals (a dependency, not a timing formula).

**Tuning invariant** (recorded in Tuning Knobs): `max_room_height ≥`
the Building System's maximum `wall_height` (currently 8 = 8) — these
must be retuned in lockstep, or tall single-story builds silently stop
registering as rooms.

## Edge Cases

1. **Connected interiors form ONE region.** Two "rooms" joined by a gap
   are one region in MVP (no interior doors exist to separate them).
   Correct and accepted — per-room subdivision arrives with doors at
   Vertical Slice. [TR-build-validation-navigability-024]
2. **A room is sealed by its last gap being built shut.** Room → Sealed
   on the construction-completed signal; all furniture inside flips to
   unsheltered; the sealed-space warning appears iff furniture is inside. [TR-build-validation-navigability-027]
   If a villager is inside, Villager AI's trapped handling (its Edge Case
   2) shows distress — two independent, complementary signals. [TR-build-validation-navigability-055]
3. **Villager sealed in WITH its bed.** The villager can still physically
   use the bed (its own reach check runs from *its* position), but
   recovery drops to unsheltered rate (a sealed space shelters no one,
   States table) and both warnings stand (sealed-space + AI distress).
   Deliberate: mechanically survivable, clearly signaled, player-fixable. [TR-build-validation-navigability-055]
4. **An opening exists but isn't walkable from outside** (hole onto a
   2-cell drop). Not a valid connection — openings must satisfy the
   walkability rules (step ≤ 1, clearance 3), not merely be holes. The
   region is Sealed. [TR-build-validation-navigability-009]
5. **Terrain as structure.** Terrain counts as floor and as wall (solid
   is solid) — a house built against a hillside or into a natural
   overhang can form valid rooms. No distinction between built and
   natural enclosure in MVP. [TR-build-validation-navigability-056]
6. **Roof-on-pillars (no walls).** Valid room by Rule 2 — the definition
   requires roof, floor, size, and reachability, not wall coverage. [TR-build-validation-navigability-057]
   **Accepted for MVP as a KNOWN design gap** (2026-07-10 cross-review,
   user decision): with zero material cost, the minimal carport reaches
   full shelter (1.0) — walls contribute no mechanical value at MVP,
   which the cross-review flagged as failing Pillar 1's own design test
   for walls specifically. This is a deliberate MVP scope-narrowing, NOT
   an oversight: the wall-coverage requirement (Open Question 1) is
   **priority #1 for this GDD's Vertical Slice revision**, and MVP
   playtest feedback about "why bother with walls" should be read as
   confirming this known gap, not as a new finding.
7. **A hole appears in the roof** (block removed). Cells under the hole
   lose candidate status; the region shrinks or splits; if what remains
   meets Rule 2 it stays a room. A bed now under open sky flips to
   unsheltered. Partial roof damage de-shelters only the affected cells'
   furniture. [TR-build-validation-navigability-058]
8. **Furniture in an opening/edge cell.** Its shelter status follows its
   own cell's candidate status (deterministic per Rule 1) — a bed exactly
   under the roof edge is sheltered; one cell further out is not. [TR-build-validation-navigability-029]
9. **Minimal bedroom.** `min_room_cells` = 2 → a bed cell plus one free
   interior cell is the smallest valid room. A 1-cell roofed niche
   holding a bed is NOT a room — the bed is unsheltered (info hint, not
   warning). [TR-build-validation-navigability-025] *(Knob-scoped claim, not absolute: `min_room_cells` = 1
   would make roofed niches count.)*
10. **Batched construction bursts.** One re-analysis per batched Building
    System signal, never per cell — and batching is per FRAME, not per
    command (Interactions): a 512-cell command completing over many
    frames (N working villagers → at most N cells per frame, Building
    F3) triggers one re-analysis per frame in which its cells complete;
    conversely, cells of MANY commands completing in the same frame are
    covered by that frame's single batched signal → still one pass. [TR-build-validation-navigability-052]
11. **World load.** A full analysis pass runs once on load; all statuses
    are re-derived from the world (nothing was serialized —
    Interactions). Load-time statuses must equal pre-save statuses
    (AC-tested). [TR-build-validation-navigability-051]
12. **Region at world edge.** The world boundary acts as neither wall nor
    opening — candidate cells simply end there; reachability uses
    in-bounds cells only. A "room" built against the world edge behaves
    exactly like one built against a cliff (case 5). [TR-build-validation-navigability-059]
13. **Sub-clearance "interior" (crawlspace).** A space whose roof sits
    1–2 cells above the floor has NO candidate interior cells (Rule 1's
    standability gate, `villager_clearance` = 3) and therefore forms no
    region at all: it is neither a room nor a sealed space. A bed inside
    such a crawlspace is simply **unsheltered** (Info tier); its
    unreachability is signaled by the existing complementary channel —
    Villager AI's claim-time reach check plus Needs' `bed_unreachable`
    why-string (its Core Rule 11) — not by the sealed-space Warning,
    which is scoped to candidate regions. [TR-build-validation-navigability-060] The same logic covers single
    cells under low eaves inside an otherwise valid room: they are not
    interior cells, and furniture on them is unsheltered (Edge Case 8
    semantics unchanged). *(Forward note for the VS roof-shape spec,
    Building System OQ 2: sloped Gable/Hip/Shed formations that drop
    interior height below 3 at edge cells will de-room exactly those
    cells by this rule — correct, but the shape spec should know.)*
14. **Corner-touching regions.** Two candidate regions that touch only
    diagonally (corner-to-corner) are TWO regions with independent
    statuses (Rule 1's orthogonal membership), but the outside-trace
    walks the full movement graph: if the flanked diagonal between
    them is legal (both flanking cells passable), each region may
    reach open sky through the other's interior and opening — both can
    independently be valid rooms off one shared door. If either
    flanking cell is blocked, the diagonal is illegal and each region
    is evaluated on its own openings only. Intended behavior
    (2026-07-10 re-review ruling): flanked-diagonal legality means a
    genuine opening exists; reachability is correct, not borrowed. [TR-build-validation-navigability-026]

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Building System | ✅ Approved | Construction-completed/removed signals (batched) as the analysis trigger; combined planned-occupancy view (unused in MVP, reserved) [TR-build-validation-navigability-052] |
| Villager AI & Behavior | ✅ Approved | The walkability definition, consumed verbatim (`villager_clearance`=3, `max_step_height`=1, corner-cutting rule) — never redefined [TR-build-validation-navigability-010] |
| Voxel World | ✅ Approved | Physical occupancy reads for region analysis (read-only) [TR-build-validation-navigability-054] |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Needs & Mood System | MVP | ✅ Approved | The sheltered/unsheltered flag per bed — its source→rate table carries the 3-tier ladder *(patch applied and approved with that GDD)* [TR-build-validation-navigability-030] |
| Villager Info UI / Building UI | MVP | Building UI: ✅ Approved · Villager Info UI: Designed (not yet reviewed) | Warnings, info hints + why-strings (Building UI Rules 9–9c implement the seam contract — confirmed); room status for the villager panel *(Villager Info UI half provisional until its review)* |
| Township Progression | Alpha | Undesigned | "Housed villagers" (owned + sheltered bed) as a prosperity input *(provisional)* |
| Save/Load & World Persistence | Vertical Slice | Undesigned | Nothing — all statuses re-derive on load (deliberate; Edge Case 11) [TR-build-validation-navigability-028] |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `min_room_cells` | 2 | 1–9 | Smallest valid room (Edge Case 9). 1 would make roofed niches count; large values punish cozy starter huts |
| `max_room_height` | 8 | 8–16 | How high above an interior cell the roof may sit (Rule 1). **The safe range's lower bound IS the invariant: must stay ≥ the Building System's max `wall_height` (currently 8 = 8) — retune in lockstep** (enforced BLOCKING at config load, AC27), or tall single-story builds silently stop registering as rooms *(range corrected from 3–16 by the 2026-07-10 review — values 3–7 were inside the old "safe" range yet broke the invariant)* [TR-build-validation-navigability-016] |
| `unsheltered_bed_multiplier` | 0.7 | 0.5–0.9 | The middle rung of the recovery ladder. **Invariant: `ground_penalty` (0.4) < this < 1.0** — outside that order the ladder collapses and either beds or rooms stop mattering [TR-build-validation-navigability-061] |
| `room_cue_cooldown_ticks` | 20 (= 10s at 1x) | 0–120 | Celebration pacing (Rule 11): at most one celebration EVENT per window — a same-pass group counts as one event and every room in it carries `celebrate = true` (Rule 11 grouping); rooms recognized in later passes inside the window emit quiet status (`celebrate = false`) only. 0 = every pass celebrates [TR-build-validation-navigability-050] |

All values data-driven per the coding standard; none are player-facing. [TR-build-validation-navigability-062]

## Visual/Audio Requirements

Room-recognized moment: a subtle one-shot (brief warm highlight tracing
the room's bounds + a soft chime — cozy, not fanfare; exact treatment to
the art bible), fired only when `celebrate = true` (Rule 11 pacing;
quiet-status recognitions get no cue). Same-pass groups (Rule 11,
shared `pass_group_id`) are ONE celebration: one chime, with the
highlight tracing every room in the group — never one chime per room. [TR-build-validation-navigability-050] Warnings/info use the Visual
Direction Note's orange state family (consistent with the Building
System's unreachable ghosts) — **differentiated from each other by icon
SHAPE + label** (distinct silhouettes for the sealed-space warning icon
vs. the unsheltered info icon), never by hue or intensity alone (the
Note's §4 day-one pairing rule — intensity is not a valid
differentiation axis), never red-green. Exact icon designs go to the
art bible; the pairing axis is committed here. **New assets required**:
room-highlight effect, sealed-space warning icon, unsheltered info icon
(two distinct silhouettes).

## Game Feel

Recognition must feel *earned and immediate* — the room registers on the
same beat the last cell completes. If a Building System
command-completion flourish fires simultaneously (finishing the roof
often completes both), the room cue follows it by a breath rather than
stacking (one celebration, two layers). Warnings appear calmly after the
fact — never mid-drag, never interrupting the build flow. A transient
seal during a natural build order (boxing in all four walls in one
command, carving the doorway in the next) is a real Sealed state and a
real emission — this system stays honest and stateless about it.
Keeping that from reading as a mid-workflow scold is a UI-owned
presentation concern with TWO distinct mechanisms, neither owned here:
a first-appearance grace (short delay-before-show for new warnings)
and the dismissal re-show debounce — the dismissal debounce alone does
NOT cover first-appearance flicker (2026-07-10 re-review correction;
both mechanisms flagged to the Building UI review, and neither is
specified there yet).

**Feel acceptance criteria** (subjective, playtest-verified): the first
room recognition elicits visible delight ("it noticed!"); no tester
reads the sealed-space warning as punishment; nobody asks "what does
this warning mean."

## UI Requirements

None owned — this system supplies queryable state and events (Rule 10);
the SURFACES are owned by Building UI / Villager Info UI: room status
(on-demand query, not a permanent overlay — clutter violates Pillar 4's
calm), warnings with why-strings ("the bed can't be reached — the room
has no opening"), and the one-shot recognition event. Warnings must be
dismissable but re-assert if the cause persists after further building —
with the re-show debounce (minimum re-show interval; no re-pop while the
player is actively editing the affected region) explicitly a UI-owned
behavior over this system's per-pass re-emissions (AC22). **Seam flag
for the UI GDDs' reviews** — four items this contract requires that
neither UI GDD yet specifies: (1) an on-demand room-status /
active-warnings inspection surface; (2) the dismissal re-show debounce
(minimum re-show interval); (3) a first-appearance grace
(delay-before-show) for transient-seal flicker (Game Feel); (4)
tier-swap reconciliation — retiring a stale Warning toast when the
per-pass emissions shift to Info for the same item (Rule 10's
no-cleared-signal model). **RESOLVED 2026-07-10 by Building UI's
review**: its rebuilt Rules 9–9c implement all four items
(identity/dedup + grace + debounce + tier-swap reconcile + issues
anchor), and the original Rule 9 contradiction with item (2) is
retired. Building UI also rules that `room_recognized` has NO HUD
surface (its Rule 9d) — the celebration is exclusively this system's
in-world highlight + chime.

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| Construction signals, never-block rule, planned-occupancy view, Open Question 7 | `design/gdd/building-system.md` | Interactions, Core Rules 10/14b, OQ7 | Trigger source; **this GDD resolves its OQ7** (completed-structure warnings) |
| Walkability rules + constants | `design/gdd/villager-ai-behavior.md` | Rules 8–10 | Consumed verbatim (its Rule 10 mandate) |
| Source→rate table (3-tier ladder extension) | `design/gdd/needs-mood-system.md` | Core Rule 4 | Value ownership stays there; patch adds the unsheltered rung |
| "Does a room need a validated path before it's livable?" | `design/gdd/game-concept.md` | Open Questions | **Resolved by this GDD**: yes — reachability is a room condition (Rule 2) |
| Orange state family, colorblind-safe | `design/art/visual-direction-note.md` | State axis | Warning/info visual constraint |
| `villager_clearance`, `max_step_height`, `ground_penalty`, `bed` | `design/registry/entities.yaml` | Registry facts | Locked inputs; `unsheltered_bed_multiplier` + room knobs registered at Phase 5 |
| NavigationServer3D rebake cost | `docs/engine-reference/godot/` + future building ADR | High-risk flag | Implementation question, NOT resolved here. This design is *specified* in cell rules, but the implementation approach (cell flood-fill vs. event-scoped navmesh rebake) is the ADR's call — whichever wins must honor Rule 7's event contract (affected-region, per-frame-batched, call-count ACs) and Rule 2's exact movement graph. Backing-store requirement: O(affected-region) cell lookups (Open Question 5) [TR-build-validation-navigability-019] |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Review produced 5 rewrites and 6 missing criteria; all
incorporated. The 2026-07-10 full design review added AC27–36 and
rewrote AC5/16/17/18/19/21; the same-day re-review added AC32b/37/38,
extended AC31, and re-parameterized AC36. Building System signals and
Villager AI's distress signal are mocked at the boundary per testing
standards.)*

**Room detection**
1. **GIVEN** a 3×3 interior with full roof, floor, walls, and one 1-wide × 3-high walkable gap (step 0), **WHEN** analyzed, **THEN** it is a valid room (Rule 2). [TR-build-validation-navigability-025]
2. **GIVEN** the same structure fully sealed, **WHEN** the completion signal fires, **THEN** the region becomes Sealed and is not a room (Rule 3, Edge Case 2). [TR-build-validation-navigability-027]
3. **GIVEN** a sealed region containing a bed, **WHEN** analyzed, **THEN** the sealed-space warning is raised; **GIVEN** the same region empty, **THEN** no warning (Rule 3). [TR-build-validation-navigability-027]
4. **GIVEN** a candidate region of exactly `min_room_cells` with a walkable connection, **WHEN** analyzed, **THEN** it is a valid room; **GIVEN** one cell fewer, **THEN** it is not (Edge Case 9). [TR-build-validation-navigability-025]
5. **GIVEN** a room whose only opening leads onto a 2-cell drop, **WHEN** analyzed, **THEN** the region is Sealed (step-height violation); **GIVEN** an opening with less than 3 cells of vertical clearance, **THEN** likewise Sealed (clearance violation); **GIVEN** an opening whose outward path leads only into roofed pockets that never reach an open-sky standable cell, **THEN** likewise Sealed (Rule 2's outside definition — the trace runs along the movement graph until open sky, not just one cell past the door) (Edge Case 4). [TR-build-validation-navigability-009]
6. **GIVEN** an interior cell with roof exactly `max_room_height` above, **WHEN** analyzed, **THEN** it is a candidate cell; **GIVEN** one cell higher, **THEN** it is not (Rule 1 boundary). [TR-build-validation-navigability-021]
7. **GIVEN** two interiors connected by a gap, **WHEN** analyzed, **THEN** they form ONE region with one status (Edge Case 1). [TR-build-validation-navigability-024]
8. **GIVEN** a valid room split in two by removing a connecting roof/floor segment, **WHEN** analyzed, **THEN** two independent regions result, each independently evaluated against Rule 2 (Edge Case 7). [TR-build-validation-navigability-058]
9. **GIVEN** terrain forming the floor and one wall, **WHEN** analyzed, **THEN** the enclosure can be a valid room (Edge Case 5). [TR-build-validation-navigability-056]
10. **GIVEN** a roof on pillars with no walls (floored, reachable, ≥ min cells), **WHEN** analyzed, **THEN** it IS a valid room (Edge Case 6 — accepted MVP behavior). [TR-build-validation-navigability-057]
11. **GIVEN** a region at the world edge, **WHEN** analyzed, **THEN** the boundary is neither wall nor opening; reachability uses in-bounds cells only (Edge Case 12). [TR-build-validation-navigability-059]

**Shelter status and events**
12. **GIVEN** a bed inside a valid room, **WHEN** classified, **THEN** it is sheltered (Rule 5). [TR-build-validation-navigability-029]
13. **GIVEN** a roof hole opening above that bed's cell, **WHEN** re-analyzed, **THEN** the bed flips to unsheltered (Edge Case 7). [TR-build-validation-navigability-058]
14. **GIVEN** a bed in a sealed region, **WHEN** classified, **THEN** it is unsheltered (States table). [TR-build-validation-navigability-029]
15. **GIVEN** a bed exactly under the roof edge vs. one cell outside it, **WHEN** analyzed, **THEN** the former is sheltered and the latter is not — purely a function of its own cell's candidate status (Edge Case 8). [TR-build-validation-navigability-029]
16. **GIVEN** a shelter-status change, **WHEN** it occurs, **THEN** exactly one `shelter_status_changed` signal is emitted per transition — Needs and UI subscribe to the same emission (assert emission count = 1, not consumer count) (Rule 10). [TR-build-validation-navigability-036]
17. **GIVEN** an unsheltered bed in the open vs. a bed in a sealed space, **WHEN** classified, **THEN** the former emits exactly one `unsheltered_furniture_info` and ZERO `sealed_space_warning`, and the latter exactly one `sealed_space_warning` per pass and ZERO `unsheltered_furniture_info` — distinct signal types, mutually exclusive per item (Rule 8 exclusivity, Rule 10). [TR-build-validation-navigability-035]
18. **GIVEN** a region seals with both a villager and a bed inside, **WHEN** analyzed, **THEN** the sealed-space warning fires (and the Info-tier emission count for that bed is 0, Rule 8 exclusivity) and the bed flips to unsheltered, independently of Villager AI's distress signal — no suppression or coupling between the two (Edge Case 3; AI signal mocked separately). [TR-build-validation-navigability-055]

**Lifecycle, triggers, and contracts**
19. **GIVEN** a batched construction signal covering N cells completed in one frame — spanning multiple commands and villagers, **WHEN** received, **THEN** exactly one re-analysis pass runs over the affected region(s) (assert analysis call-count = 1 per frame-batch, never per cell or per command) (Rule 7, Edge Case 10, Interactions batching contract). [TR-build-validation-navigability-052]
20. **GIVEN** no structure-change signals, **WHEN** N frames pass, **THEN** the instrumented analysis call-count stays 0 — event-driven, never per-frame (Rule 7). [TR-build-validation-navigability-006]
21. **GIVEN** a candidate region becomes a valid room, **WHEN** the transition occurs, **THEN** exactly one `room_recognized` fires — and does NOT re-fire on later re-analyses that keep the room valid, NOR when that room later merges with or splits from other valid rooms (Rule 11 continuity: fires only if no interior cell was in a prior valid room). [TR-build-validation-navigability-049]
22. **GIVEN** a warning's cause persists, **WHEN** any later re-analysis runs, **THEN** the warning event re-emits every qualifying pass regardless of prior UI dismissal — dismiss/re-show presentation is the UI's own (advisory-tier) behavior (UI Requirements). [TR-build-validation-navigability-041]
23. **GIVEN** blueprint (unbuilt) cells forming a would-be roof, **WHEN** analyzed, **THEN** they do NOT count as solid — analysis is built-only in MVP (Rule 7). [TR-build-validation-navigability-031]
24. **GIVEN** mocked changed walkability constants in the registry, **WHEN** reachability is evaluated, **THEN** the updated values are used — no independent copies (Rule 2 verbatim-consumption). [TR-build-validation-navigability-010]
25. **GIVEN** any invalid/sealed configuration, **WHEN** the player completes the placement, **THEN** the Building System's completion signal and world state are unmodified — no block/revert call is ever observed (Rule 9 never-blocks, verified via mock call-count). [TR-build-validation-navigability-037]
26. **[PROVISIONAL — Save/Load]** **GIVEN** a world state, **WHEN** saved and reloaded (mocked), **THEN** all region and shelter statuses re-derive identically to pre-save (Edge Case 11). [TR-build-validation-navigability-028]

**Added by design review (2026-07-10)**
27. **GIVEN** a config where `max_room_height` < the Building System's maximum `wall_height`, **WHEN** config loads, **THEN** the load fails loudly naming the lockstep invariant (Tuning Knobs invariant (a), escalated from advisory to blocking — mirrors Needs & Mood AC29's pattern). [TR-build-validation-navigability-016]
28. **GIVEN** a floored, fully roofed structure whose roof sits exactly 2 cells above the floor, **WHEN** analyzed, **THEN** zero candidate interior cells exist (Rule 1 standability gate), no region forms, and a bed inside is unsheltered with an Info-tier emission and NO sealed-space warning (Edge Case 13). [TR-build-validation-navigability-060]
29. **GIVEN** a region whose only outside connection requires a diagonal step with both flanking orthogonal cells passable, **WHEN** analyzed, **THEN** it is a valid room (Rule 2 movement graph — legal flanked diagonal). [TR-build-validation-navigability-008]
30. **GIVEN** the same geometry with either flanking cell blocked, **WHEN** analyzed, **THEN** the region is Sealed (Rule 2 — no corner-cutting, consumed verbatim from Villager AI Rule 9). [TR-build-validation-navigability-008]
31. **GIVEN** a world load's initial full analysis pass over a world containing valid rooms, a persisting sealed-bed cause, AND an unsheltered-in-the-open bed, **WHEN** the pass completes, **THEN** zero `room_recognized` and zero `shelter_status_changed` emissions occur, all statuses are queryable and equal pre-save statuses (extends AC26), AND both the `sealed_space_warning` and the `unsheltered_furniture_info` re-emissions DO fire on this pass (Rule 11 silent seeding — transitions silent, persisting causes re-warned, both tiers). [TR-build-validation-navigability-051]
32. **GIVEN** two distinct regions become valid rooms in DIFFERENT analysis passes within `room_cue_cooldown_ticks` of each other, **WHEN** the second transition occurs, **THEN** both emit `room_recognized`, the first with `celebrate = true` and the second with `celebrate = false` (Rule 11 pacing — sequential case). [TR-build-validation-navigability-050]
32b. **GIVEN** two distinct regions become valid rooms in the SAME analysis pass, **WHEN** the pass completes, **THEN** both emit `room_recognized` with `celebrate = true` and an identical `pass_group_id`, and no third signal fires — the same-pass group is one celebration event, never an arbitrary winner (Rule 11 same-pass grouping); a room recognized in a LATER pass within the cooldown window then emits `celebrate = false`. [TR-build-validation-navigability-050]
33. **GIVEN** a full analysis pass over any configuration with mocked villager interfaces, **WHEN** the pass completes, **THEN** zero calls into villager movement/behavior APIs are observed (Rule 9's second half — never moves villagers; call-count mock, companion to AC25's never-blocks half). [TR-build-validation-navigability-038]
34. **GIVEN** a region seals with a villager but NO furniture inside, **WHEN** analyzed, **THEN** no sealed-space warning fires from this system (Rule 3 — warning iff need-functional furniture; Villager AI's distress is the only cue, mocked separately) (Edge Case 2). [TR-build-validation-navigability-027]
35. **[PROVISIONAL — no non-need-functional furniture exists in MVP; mocked definition]** **GIVEN** a decorative furniture item in a sealed space, **WHEN** analyzed, **THEN** `shelter_status_changed` fires (unsheltered) but Warning and Info emission counts are both 0 (Rule 8 need-functional scope, Rule 10). [TR-build-validation-navigability-036]
36. **[Integration — property test]** **GIVEN** the checked-in property-test corpus — a fixed list of 100 seeds committed to `tests/integration/build-validation/`, each seed generating a bounded 32×32×16 world (documented generator: procedural terrain per Voxel World's formula + random wall/floor/roof placement at 10–40% solid-fill density) and 50 sampled (start, target) pairs drawn from that world's standable cells — **WHEN** this system's reachability verdict and Villager AI's pathfinder evaluate every pair, **THEN** all 5,000 verdicts agree; any disagreement fails the test naming the seed and pair; total corpus runtime ≤ 60s in CI — guarding algorithmic divergence between the two independent implementations of the movement rules (Rule 2; complements AC24's constants-only check; generation parameters are test fixtures, not gameplay values). [TR-build-validation-navigability-063]
37. **GIVEN** two candidate regions touching only corner-to-corner where region A's sole path to open sky is a legal flanked diagonal into region B and out B's door, **WHEN** analyzed, **THEN** A and B are TWO regions and BOTH are valid rooms; **GIVEN** either flanking cell of that diagonal blocked, **THEN** A is Sealed while B remains a room (Edge Case 14, Rule 2's trace scope). [TR-build-validation-navigability-026]
38. **GIVEN** a mocked character occupying an otherwise-candidate interior cell, **WHEN** analyzed, **THEN** that cell's candidate status, its region's membership, and the region's Room/Sealed verdict are all identical to the unoccupied case — character positions never affect the analysis (Rule 1's block-occupancy-only clause; companion to AC33's never-calls-villager-APIs check). [TR-build-validation-navigability-023]

*Config-validation: invariant (a) `max_room_height ≥` Building's max
`wall_height` is BLOCKING at config load (AC27). Invariant (b)
`ground_penalty < unsheltered_bed_multiplier < 1.0` remains an advisory
smoke check here — its blocking enforcement is owned by Needs & Mood
(its AC29); this check is the courtesy duplicate. Authoring trap noted:
needs-mood's `ground_penalty` safe range (0.1–0.8) and
`unsheltered_bed_multiplier`'s (0.5–0.9) are not mutually safe at their
extremes — the load check, not the ranges, is the guarantee. [TR-build-validation-navigability-061]*

## Open Questions

1. **Wall coverage at Vertical Slice** — should a valid room eventually
   require some wall enclosure (retiring the "cozy carport", Edge Case
   6)? Decide together with doors. **Elevated to VS priority #1 by the
   2026-07-10 cross-review** (walls are mechanically inert at MVP — a
   known, accepted gap that VS must close). → *this GDD's VS revision*
2. **Doors** — when VS adds them, an opening becomes a formal object
   (walkable when open). The room definition (Rule 2) should survive
   unchanged; verify. → *VS revision + Building System OQ 6*
3. **Room identity and function** — persistent named rooms ("bedroom",
   "dining hall") once furniture functions multiply. → *VS+ with the
   furniture set*
4. **Wave damage interplay** — do breached walls (destroyed by waves)
   trigger re-analysis and warnings mid-combat, or after? → *Wave
   Defense GDD, after the `/prototype wave-defense` spike*
5. **Analysis performance — two distinct axes** *(reframed by the
   2026-07-10 review; the old "large worlds and 20–30 villagers"
   framing pointed the spike at the wrong variable)*:
   (a) **Signal/analysis frequency** — bounded to at most one pass per
   frame by the per-frame batching contract (Interactions, AC19);
   residual cost scales with completion rate at the 20–30 villager
   ceiling.
   (b) **Region-size cost — villager-count-INDEPENDENT and
   MVP-reachable**: the flood-fill is deliberately unbounded (Formulas)
   and uncached; region size grows with cumulative *connected build
   footprint* — one player with one villager can, over enough sessions,
   merge structures until any single-cell edit rescans the whole
   megastructure. The pre-VS spike MUST include a sprawling
   merged-structure case, independent of population stress. The
   load-time full-world pass (Edge Case 11) is this same cost order and
   belongs to the same spike case. [TR-build-validation-navigability-064]
   (c) **Snapshot resident memory** *(added by the re-review)*: Rule
   11's edge-detection snapshot is a STANDING memory cost (current +
   previous per-cell classification and per-item flags) scaling with
   the same connected-build-footprint variable — the spike must measure
   resident memory, not just pass latency; Rule 11's incremental-update
   mandate governs its compute side. [TR-build-validation-navigability-064] A sparse/pruned representation is
   the expected mitigation (ADR).
   Also owned by the ADR: the cell-rule vs. NavigationServer3D approach —
   **RESOLVED 2026-07-11 via ADR-0007: cell-rule, not NavigationServer3D.**
   This system runs its own independent BFS/flood-fill calling Villager
   AI's shared `is_standable`/`is_step_legal` predicates directly (the
   same functions Villager AI's own `AStar3D`-based pathfinding calls),
   honoring Rule 7's event contract and Rule 2's exact movement graph by
   construction — not a geometric navmesh approximation. [TR-build-validation-navigability-010] Backing data
   structure: Voxel World's own sparse `Dictionary[Vector3i, CellData]`
   (ADR-0003), giving O(affected-region) lookups natively —
   `GridMap.get_used_cells()`-style full iteration was never in the
   design (GridMap is a pure rendering mirror per ADR-0003, not the data
   layer this system queries). Chunk-boundary-vs-world-edge distinguishing
   (Edge Case 12) remains open pending Voxel World's chunked-streaming
   status, which has not been revisited since ADR-0003 kept the sparse
   dictionary as a single unbounded structure, not chunked — moot for
   MVP. → *pre-VS performance spike still required for regions (a)-(c)
   above (reciprocal axis in villager-ai-behavior.md OQ 3) — ADR-0007
   is itself PROVISIONAL pending that same spike.*
6. **"Housed" as a prosperity input** — formalize the owned-sheltered-bed
   status for Township Progression. → *Township Progression GDD, Alpha*
