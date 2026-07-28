# ADR-0016: Build-Project Entity Lifecycle

## Status
Accepted (2026-07-23 — prototype-validated across the vertical slice, 2026-07-22/23; user-approved dedicated ADR per the 2026-07-23 slice-propagation batch. Evidence: `prototypes/last-seal-vertical-slice/REPORT.md` + slice commits 32edfbf, 555b4aa, b2259f4. Now specified in building-system.md TR-building-system-102..126.)

## Date
2026-07-23

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Core / Gameplay Data (build-project entity model + state machine) |
| **Knowledge Risk** | LOW — this ADR is a data-model/state-machine decision over already-settled primitives (Voxel World writes, the villager job queue, ADR-0009 occupancy); it introduces no novel engine API. It was exercised end-to-end in the slice, not paper-designed. |
| **References Consulted** | building-system.md (Slice revision 2026-07-23, Rules 14a–14n, TR-102..126); `prototypes/last-seal-vertical-slice/REPORT.md`; ADR-0009, ADR-0012 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Completed — validated by the vertical slice itself (persistent projects, change orders, worker demolition, plan-only undo all built and playtested; tester debrief "Ich bin sehr begeistert" at the persistent-projects build). This ADR ratifies a proven model rather than proposing an untried one. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Building System is injected-tier, owns this model); ADR-0009 (occupancy semantics the demolition/seal path reads); ADR-0007 (villager job execution the release/build phase drives) |
| **Enables** | Building UI's Projects Panel + Selection routing (ADR-0010 §4, building-ui TR-075..088); Villager AI worker attribution (villager-ai TR-097); persistent-project serialization (ADR-0012) |
| **Blocks** | Building System, Building UI, and Villager AI production `/dev-story` work touching the project lifecycle |
| **Ordering Note** | MVP-relevant (the slice made the Stonehearth-style workflow CORE UX). Independent of ADR-0015; the entity model is orthogonal to world-storage residency. |

## Context

### Problem Statement
The vertical slice's verdict: the Stonehearth-style build workflow — draft → release → workers build → demolish — "emerged as CORE UX during the slice and must be first-class in the building GDDs, not an afterthought" (REPORT.md). building-system.md now specifies a persistent **build-project entity** (TR-102..126) that groups blueprint cells into a selectable, releasable, pausable, changeable, demolishable unit with a lifecycle and worker attribution. No ADR governs this cross-system entity model, its state machine, its undo semantics, or its persistence contract — this ADR is that governing decision, ratifying exactly the model the slice validated.

### Constraints
- Built cells are authoritative Voxel World data; they must mutate **only via worker-executed jobs**, never via a direct edit or an undo of already-built geometry (plan-only undo — building-system Rule 14, REPORT.md)
- The model must be prototype-faithful: the slice's implementation is the specification, not an idealized redesign (REPORT.md: "Production implementation is written from scratch" but the *design* is the slice's)
- Building System owns the entity; Building UI is a pure renderer/router (ADR-0010 §4, building-ui contract); Villager AI only feeds attribution, never owns project state
- Furniture removal is now job-based too (2026-07-23 user resolution) — demolition orders cover blocks AND furniture uniformly, no instant-removal carve-out
- Occupancy/seal semantics for demolition and worker-executed writes are ADR-0009's, not re-decided here

### Requirements
- A persistent project entity with a defined lifecycle: Draft → Released(BUILDING) ⇄ Paused → Done, plus demolition orders
- Deterministic grouping/merge of adjacent blueprint cells into one project (26-neighborhood)
- Change orders that attach to already-released or done projects without recreating them
- Worker attribution: which villagers built/are building a project
- Plan-only undo/redo: the undo stack governs the *plan* (draft cells / queued orders), never built geometry
- Click-selection of a project from any of its cells (reverse index)
- Project persistence until empty; serialization of the entity (ADR-0012)

## Decision

**A persistent, Building-System-owned build-project entity with an explicit lifecycle state machine, 26-neighborhood grouping/merge, change orders attaching to released/done projects, worker attribution fed by Villager AI, plan-only undo (built cells mutate only via jobs), cell→project reverse-index selection, and persistence-until-empty — exactly as slice-validated and specified in building-system.md TR-102..126.**

**1. Entity + lifecycle state machine.** A project is a persistent entity aggregating blueprint/built cells with a state:
- **Draft** — cells planned, not yet job-eligible; freely edited/undone (plan-only undo, §5).
- **Released → BUILDING** — the project's cells become jobs villagers claim and execute (ADR-0007 job flow); on release the draft phase closes.
- **Paused** — no new jobs offered; in-flight claims revoked gracefully; queued cells untouched (building-system TR-110). Resumes to BUILDING with the same remaining cells, never re-created.
- **Done** — all cells built.
- **Demolition orders** — a project (or a change-order subset) can be queued for worker-executed demolition, covering blocks **and furniture** (2026-07-23 resolution); demolition is job-based, not instant.

**2. 26-neighborhood grouping/merge (deterministic).** Blueprint cells that are mutually 26-adjacent belong to one project; a commit whose cells bridge existing projects merges them so every resulting cell belongs to exactly one project (building-system TR-126, Rule 14d). A single house-template stamp whose internal sub-shapes aren't all mutually adjacent is still merged into one project by the batch-merge guarantee.

**3. Change orders attach to released/done projects.** An edit targeting an already-released or done project attaches as a change order (added cells become new jobs; removed cells become demolition orders) without recreating the project entity — the entity is stable across its whole lifetime (building-system TR-088, Rule 14h).

**4. Worker attribution.** When a villager claims a project's job, the claim records the villager id; the project exposes `worker_ids` aggregating its builders (villager-ai TR-097 feeds this; the project entity aggregates it). Attribution is read/display + save state, not a control channel.

**5. Plan-only undo/redo.** The undo stack governs the plan only: draft cells and queued orders. **Built cells are never mutated by undo** — once a cell is built it changes only via a worker-executed demolition job. Undo of a released-but-unbuilt cell removes the pending job; redo re-creates only still-valid cells, dropping invalidated ones with feedback (building-system TR-088). This is the "build-while-paused / plan calmly" model (TR-097): planning and undo work identically paused or unpaused.

**6. Selection via cell→project reverse index.** Every project cell maps back to its owning project via a reverse index, so a world click on any cell selects the whole project (building-system Rule 14i, TR-102/103). This is the DDA→owning-project resolution ADR-0010 §4's Selection routing calls into; clicking a project cell selects it regardless of tool-armed state.

**7. Persistence.** A project entity persists until it becomes empty (all cells built-and-then-demolished, or all draft cells removed). Building System's `serialize()` includes project entities (state, cells, `restore_value` for floor-replace cells, `worker_ids`, pending change/demolition orders); ADR-0012's per-system contract carries this opaquely. Undo/redo stack is excluded from save (ADR-0012, building-system TR-033).

### Architecture Diagram
```
Building System (owner — injected-tier, ADR-0001)
  Project entity:
    id, state ∈ {Draft, BUILDING, Paused, Done}, cells[], restore_value[],
    worker_ids[], pending change/demolition orders
        │
        ├─ grouping/merge: 26-neighborhood (TR-126)
        ├─ cell → project reverse index (TR-102/103)
        │       ▲
        │       └── ADR-0010 §4 Selection: world click → owning project
        │
        ├─ Released → jobs ──► Villager AI claims/executes (ADR-0007)
        │                          │ claim records villager id
        │                          ▼
        │                     worker_ids (attribution, TR-097)
        │
        ├─ Demolition orders (blocks + furniture) ──► worker-executed jobs
        │                                              (occupancy/seal per ADR-0009)
        │
        ├─ plan-only undo/redo: draft cells + queued orders ONLY
        │   (built cells mutate ONLY via demolition jobs)
        │
        └─ serialize(): project entities ──► ADR-0012 (opaque per-system)

Building UI (renderer/router — building-ui TR-075..088):
  Projects Panel cards mirror project state; routes clicks (ADR-0010 §4).
  Owns no project state.
```

### Key Interfaces
```gdscript
# Building System's project entity + public surface (extends architecture.md API Boundaries):
enum ProjectState { DRAFT, BUILDING, PAUSED, DONE }

# Attribution fed by Villager AI on job claim (villager-ai TR-097):
func on_job_claimed(project_id: int, villager_id: int) -> void   # records worker_ids

# Selection reverse index (ADR-0010 §4 calls this):
func project_at_cell(cell: Vector3i) -> int   # owning project id, or -1

# Lifecycle transitions (player intents via Building UI):
func release_project(project_id: int) -> void   # Draft → BUILDING
func pause_project(project_id: int) -> void      # BUILDING → Paused (graceful claim revoke)
func queue_demolition(project_id: int) -> void   # blocks + furniture, worker-executed

# Serialization (ADR-0012 per-system contract):
func serialize() -> Dictionary   # includes project entities; excludes undo stack
```

## Alternatives Considered

### Alternative A: Persistent project-entity model exactly as slice-validated — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: prototype-proven end-to-end (built, played, enthused-about in the slice); one clear owner (Building System); plan-only undo cleanly separates reversible planning from authoritative built geometry; furniture-uniform demolition removes a special case.
- **Cons**: a real stateful entity + reverse index + change-order machinery to implement and test — but this is inherent to the validated UX, not incidental.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Stateless blueprint cells (no project entity) — the pre-slice MVP model
- **Description**: keep the original loose blueprint-cell model with no grouping, no persistent entity, no per-project lifecycle.
- **Pros**: less state to manage.
- **Cons**: cannot express the Stonehearth workflow the slice proved CORE (release/pause/change-orders/per-project demolition, selection, attribution) — the tester's enthusiasm was specifically about the persistent-projects build.
- **Rejection Reason**: fails to support the validated core UX; the slice explicitly rejected it ("must be first-class ... not an afterthought").

### Alternative C: Full undo of built geometry (unrestricted undo)
- **Description**: let undo revert already-built cells directly, not just the plan.
- **Cons**: makes built geometry non-authoritative and bypasses worker execution and ADR-0009's occupancy/seal semantics (an undo could vaporize a cell under a villager with no job, no signal ordering guarantee); contradicts the "built cells change only via jobs" invariant the slice settled.
- **Rejection Reason**: breaks the authoritative-built-geometry invariant and the job-executed mutation contract.

## Consequences

### Positive
- The validated Stonehearth workflow is a first-class, ADR-governed model with a single owner and clean cross-system seams.
- Plan-only undo keeps built geometry authoritative and consistent with ADR-0009's job-executed-mutation guarantees.
- Furniture-uniform demolition removes the instant-removal carve-out (one demolition path).
- Serialization is a straightforward extension of ADR-0012's per-system contract.

### Negative
- A stateful entity with grouping/merge, a reverse index, change orders, and lifecycle transitions is real implementation surface — but it is the surface the proven UX requires.
- Building UI must faithfully mirror lifecycle state without owning it (ADR-0010 §4 routing discipline).

### Risks
- **Risk**: grouping/merge edge cases (a commit bridging two projects; a template stamp with non-adjacent sub-shapes) produce ambiguous ownership.
  **Mitigation**: the batch-merge guarantee (TR-126) makes every resulting cell belong to exactly one project by construction; asserted in AC.
- **Risk**: a demolition/change order racing a villager mid-execution.
  **Mitigation**: graceful claim revoke on pause/change (TR-110); occupancy/seal via ADR-0009; demolition is job-based so it serializes through the same execution path.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| building-system.md | TR-building-system-102/103: Build Mode + project cells select regardless of tool-armed state | Cell→project reverse index (Decision §6) |
| building-system.md | TR-building-system-110: Paused project — no new jobs, graceful claim revoke, queued cells untouched, resumes without re-creation | Paused state (Decision §1) |
| building-system.md | TR-building-system-120: floor terrain-replace `restore_value` captured, written back on cancel/undo/demolish, never left empty | `restore_value` carried on the project entity, serialized (Decision §1/§7) |
| building-system.md | TR-building-system-126: batch-merge — every cell of a multi-sub-shape stamp belongs to exactly one project | 26-neighborhood grouping/merge (Decision §2) |
| building-system.md | TR-building-system-088: change orders / redo re-creates only still-valid cells | Change orders attach to released/done projects (Decision §3); plan-only undo/redo (§5) |
| building-system.md | TR-building-system-075/076: one completion signal per project; Building UI mirrors, never owns | Building System owns entity; UI renders (Decision §1, diagram) |
| building-system.md | TR-building-system-097: build/plan/undo while paused | Plan-only undo works identically paused/unpaused (Decision §5) |
| villager-ai-behavior.md | TR-villager-ai-behavior-097 (claim attribution → `worker_ids`) | Worker attribution fed on job claim (Decision §4) |
| building-ui.md | TR-building-ui-075..088 (Projects Panel render/route) | UI mirrors lifecycle + routes via ADR-0010 §4 (Decision §6, diagram) |

## Performance Implications
- **CPU**: reverse-index lookup is O(1) per cell; grouping/merge is bounded by the committed batch's neighborhood, not world size. Negligible against the frame budget.
- **Memory**: one entity per active project + a cell→project index proportional to built/draft cell count — modest at settlement scale.
- **Load Time**: project entities deserialize with Building System's state (ADR-0012) — small vs voxel data.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no production code. The slice code is reference-only (REPORT.md: "Never import or refactor this code into production"); production is written from scratch against this ADR + building-system.md TR-102..126.

## Validation Criteria
- Unit: a commit bridging two projects yields exactly one merged project; a stamp with non-adjacent sub-shapes yields one project (TR-126).
- Unit: undo/redo mutates only draft/queued state; a built cell is never altered by undo (plan-only invariant); redo drops invalidated cells with feedback (TR-088).
- Unit: pausing a BUILDING project revokes in-flight claims gracefully and resumes the same remaining cells without re-creation (TR-110).
- Unit: `project_at_cell()` returns the owning project for any of its cells regardless of tool-armed state (TR-102/103).
- Integration: a demolition order (block and furniture) executes as worker jobs; `restore_value` is written back for demolished floor-replace cells, never left empty (TR-120).
- Round-trip: `serialize()`/`deserialize()` restores project entities (state, cells, `restore_value`, `worker_ids`, pending orders) exactly; undo stack excluded (ADR-0012, TR-033).

## Related Decisions
- Owned by an ADR-0001 injected-tier module; occupancy/seal semantics per ADR-0009; job execution per ADR-0007.
- Selection routing consumed by ADR-0010 §4; serialization by ADR-0012.
- Independent of ADR-0015 (world-storage residency) — the entity model is orthogonal to voxel-storage paging.
