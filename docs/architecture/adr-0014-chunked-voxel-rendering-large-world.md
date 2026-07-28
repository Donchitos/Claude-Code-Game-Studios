# ADR-0014: Chunked Voxel Rendering & Large-World Storage

## Status
Accepted (2026-07-11 — validated empirically by `prototypes/chunked-mesher/` at full 2000×2000×32 scale before authoring; user/creative-director decision: large world for exploration + distant dungeons. Supersedes ADR-0003.)

**(Slice propagation 2026-07-23)** Remains Accepted at the 2000×2000×32 baseline. Amended in place: CW-winding + backface-culling-enabled mesher requirement (Decision §2), ghost-anchored `extra_solid` picking predicate recorded under §4. The full-world-at-boot storage clause (§1) is **superseded by ADR-0015 (Large-World Storage & Residency, Accepted spike-validated 2026-07-23)** for the 16k target — paged region-file residency replaces full-world allocation; the mesher/view-window/streaming design here is unaffected. See `change-impact-2026-07-23-slice-batch.md`.

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Rendering / World Data |
| **Knowledge Risk** | LOW — every load-bearing API was exercised by the validating prototype on 4.7 itself (not paper-verified) |
| **References Consulted** | `docs/engine-reference/godot/` (modules/rendering.md, current-best-practices.md); prototype measurements |
| **Post-Cutoff APIs Used** | None beyond 4.x baseline (`ArrayMesh.add_surface_from_arrays`, `MeshInstance3D.visibility_range_end`, `RenderingServer.get_rendering_info`) |
| **Verification Required** | Completed — validated by running prototype on 4.7 (see Measurements) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0006 (definitions supply per-material visuals), game-concept large-world constraint (2026-07-11) |
| **Supersedes** | ADR-0003 (GridMap approach — correct at the old ~100×100 bound, measurably fails at the new one; see Context) |
| **Enables** | Large-world exploration + distant-dungeon content; ADR-0013's spatial-offset model gains headroom |
| **Blocks** | Voxel World and Building System `/dev-story` implementation |
| **Unchanged from ADR-0003** | DDA picking against the data layer (§3), pooled-`MeshInstance3D` ghost previews (§4), boot-time MeshLibrary→material derivation from RID |

## Context

The creative decision of 2026-07-11 changes the world-scale constraint from a
bounded ~100×32×100 valley to a **large world (target 2000×2000×32, minimum
1000×1000)** for exploration and distant dungeons, with density growing over
time. Measured on real hardware (see `prototypes/perf-spike-qq3/REPORT.md`
addendum), the accepted GridMap approach fails hard beyond the old bound:
full view ~35 FPS at 500², 7.5 FPS / 65,835 draw calls at 1000², >16 GB RSS
(killed) at 2000². Two structural causes: every block is submitted as
geometry (even the ~90% that are buried), and `Dictionary` cell storage costs
~500 B/cell.

## Decision

**Chunked, face-culled voxel rendering with packed chunk storage and a
streamed view window.**

1. **Storage**: the world is divided into 16×16-column chunks; each chunk's
   cell data lives in a packed array (`PackedByteArray`-class storage,
   ~1–4 B/cell), allocated for the FULL world at boot. **(Slice propagation
   2026-07-23) The full-world-at-boot allocation clause is SUPERSEDED by
   ADR-0015 (Large-World Storage & Residency, Accepted spike-validated
   2026-07-23) for the 16k target.** It is validated and remains correct at the
   2000×2000×32 baseline (~172 MB); the 16,000×16,000×32 production target
   projects to ~11 GB resident (~3× over the 4 GB ceiling) — a storage/residency
   problem, not a rendering one (draw calls are already decoupled from world
   size via the streamed view window). ADR-0015 replaces full-world allocation
   with **paged/on-demand region-file residency** (camera-near ∪ settlement
   resident; time-based streaming budget; no synchronous per-frame I/O/gen),
   superseding ONLY this clause; the mesher, view-window, and streaming design
   below are unaffected. Voxel World's public
   API is unchanged (O(1) `get`/`set` by `Vector3i`, `cell_changed` signal,
   `raycast_cells` DDA) — only the internal representation changes from
   `Dictionary[Vector3i, CellData]` to chunked packed arrays behind the same
   accessors. Downstream consumers (Building System, Villager AI, Build
   Validation, ADR-0009 occupancy) are untouched.
2. **Meshing**: one `ArrayMesh` per chunk, rebuilt whole on any cell change
   in that chunk (measured 1.1 ms — invisible under the 16.6 ms budget).
   Faces are emitted only where a cell borders air (face culling); vertical
   runs merge into single quads. Full greedy meshing is the named
   optimization reserve, NOT built until measurement demands it.
   **(Slice propagation 2026-07-23) Winding & backface culling — hard engine
   requirement.** Generated triangles MUST be wound **clockwise (CW)** and the
   material MUST ship with backface culling **ENABLED** — Godot 4.7's
   front-face convention is CW, an engine fact, not a project convention
   (TR-voxel-world-052). The vertical slice shipped CCW winding +
   `CULL_DISABLED` as a **documented, now-expired mitigation** (adopted after a
   multi-session "missing faces" investigation whose root cause was auditing
   against a self-stored CCW assumption instead of the engine's CW convention);
   it doubled overdraw, an accepted slice-only cost that held 60 FPS with ~10×
   headroom on the 2000×2000×32 window. The rewind to CW + culling-enabled must
   land before asset counts scale beyond slice levels — the 2× overdraw
   headroom will not survive a large jump in scene complexity. **Audit rule:
   face-winding checks validate against the engine's actual convention, never a
   self-stored one.**
3. **View window + streaming**: only chunks within a view radius
   (`view_radius_chunks`, prototype: 24 ≙ ~380 m) are meshed and instanced;
   `visibility_range_end` fades distant chunks. A per-frame build budget
   (`stream_chunk_budget`, prototype: 2) meshes newly-entered chunks as the
   camera moves; chunks beyond radius+margin are unloaded **staggered across
   frames** (the prototype's one 133 ms hitch came from an unload burst —
   production spreads `queue_free` with the same budget discipline).
4. **Ghosts & picking**: unchanged from ADR-0003 §3/§4 — DDA against the
   data layer (never render geometry), pooled tinted `MeshInstance3D` ghosts.
   **(Slice propagation 2026-07-23) Ghost-anchored picking predicate lives
   here.** The slice-validated "ghost cells pick as solid; dig-orders and water
   do not" contract is implemented as an **`extra_solid` predicate** on this
   §4 DDA path (`raycast_cells` consulting an overlay of uncommitted
   ghost/draft cells), NOT as anything in ADR-0004 (whose scope is the villager
   `Area3D` hit-test only). Building System's placement pick therefore still
   issues zero physics queries — the villager-separation guarantee (ADR-0004)
   is unaffected. The picking API and its predicate are owned by this ADR /
   Voxel World's read API.
5. **Escalation path**: if profiling ever demands it, the mesher moves to
   GDExtension (C++) behind the same chunk interface — an implementation
   swap, not an architecture change.

### Measurements (prototype, full 2000×2000×32, unoptimized GDScript)

| Metric | Value | Budget |
|---|---|---|
| Full-world packed data | 172 MB | ≤4 GB |
| Frame p95, all views | 16.7 ms (vsync-locked); **un-vsync re-measure 2026-07-11: avg 1.1-1.6 ms, p95 1.7 ms — ~10x headroom** | ≤16.6 ms |
| Draw calls max | 1,293 | ≤2000 |
| Edit → chunk rebuild | 1.1 ms avg | in-frame |
| Streaming (1,488 chunks in-flight) | p95 16.7 ms | in-frame |
| Initial window build (2,304 chunks) | 2.6 s | loading screen |

## Alternatives Considered

- **A: GridMap (ADR-0003, superseded)** — correct and simplest at the old
  ~100×100 bound (its spike PASS stands for that scope); measurably fails at
  the new bound (memory kill at 2000², draw-call explosion from 500²).
- **B: Manual `MultiMeshInstance3D` per block type** — still submits buried
  blocks; fails the same way for the same reason.
- **C: GDExtension native mesher now** — premature; GDScript already meets
  every budget at target scale. Named escalation path only.

## Consequences

- Voxel World's implementation is the most complex system in the project now
  (mesher + streaming); estimate grows accordingly (~3–5 weeks vs ~1).
- Initial window build (~2.6 s) needs the existing transition overlay
  (TR-scene-world-management-032) — no new UI.
- **ADR-0007 impact (flagged, not resolved here)**: `AStar3D` over ~4M
  standable cells is unmeasured. Mitigation consistent with the creative
  intent (villagers live in the settlement core; the far world is for
  player/squad exploration): the nav graph covers a bounded settlement
  region, not the whole world. Follow-up spike required before Villager AI
  implementation — tracked as architecture.md QQ5.
- Save format (ADR-0012): Voxel World's `serialize()` payload grows; packed
  chunks serialize naturally via `store_var` on packed arrays. Still opaque
  to the orchestrator. No structural change; expect larger files (~150–250 MB
  worst case at high density — revisit compression when measured).
- ADR-0013's `100_000` dungeon offset still exceeds the new 2000-unit world
  bound by 50× — no change needed.

## GDD Requirements Addressed

The full set ADR-0003 covered: TR-voxel-world-017/018/025, TR-building-system-002/026/003/035/039/041, TR-villager-info-ui-014/015 (picking + villager-hit separation carry over via section 4)
under the revised world-scale constraint (game-concept.md 2026-07-11 update),
plus the new exploration/distant-dungeon intent.

## Validation Criteria

- Grep-verifiable: zero `GridMap` usage in Voxel World's committed-block path;
  zero `PhysicsServer3D`/`RayCast3D` in picking (carried over from ADR-0003).
- Unit: cell `get`/`set` round-trip via the chunked accessor identical to the
  old Dictionary contract (same API, same semantics, `cell_changed` fires).
- Perf: production implementation re-run against the prototype's table above;
  no metric regresses past budget.
