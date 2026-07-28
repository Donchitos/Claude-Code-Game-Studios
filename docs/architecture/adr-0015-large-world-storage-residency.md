# ADR-0015: Large-World Storage & Residency (16k Target)

## Status
Accepted (spike-validated 2026-07-23 — the storage/streaming spike PASSED all five Validation Criteria at the game's real max camera speed (144 cells/sec, derived from `camera_input.gd`) and an aggressive stress speed (120 cells/sec), at both tested async concurrency caps (32 and 64); see `prototypes/storage-residency-spike/README.md` + `results/`, commits afb609c + 799ddbc. Four empirically-validated text refinements applied — see Decision §1/§3/§6 and Validation Criteria.). Supersedes ONLY ADR-0014's full-world-at-boot allocation clause (Decision §1) for the 16,000×16,000×32 production target; ADR-0014's mesher, view-window, and streaming design remain Accepted and unchanged. Provisional-until-spike gate followed the ADR-0007/0008 QQ3 precedent.

## Date
2026-07-23

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Rendering / World Data (storage residency) |
| **Knowledge Risk** | MEDIUM — the residency mechanism is plain file I/O + the existing chunk model; the risk is empirical (page-in latency, sustained-travel memory) not API-novelty. `FileAccess` region-file reads/writes and `store_var`/`get_var` on packed arrays are the same 4.4+ surface ADR-0012 already vetted. |
| **References Consulted** | `docs/engine-reference/godot/` (modules/rendering.md, current-best-practices.md); ADR-0014 measurements; `prototypes/last-seal-vertical-slice/REPORT.md` |
| **Post-Cutoff APIs Used** | None beyond ADR-0014's baseline and ADR-0012's `store_var`/`get_var` return-type handling |
| **Verification Required** | COMPLETED — the storage/streaming spike PASSED 5/5 (2026-07-23) at real max (144 c/s) and stress (120 c/s) camera speeds, at async caps 32 and 64. See Validation Criteria for the measured evidence. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0014 (Chunked Voxel Rendering) — this ADR changes only *which chunks are resident and where far chunks live*, behind ADR-0014's unchanged chunk model and public accessor API |
| **Supersedes** | ADR-0014 Decision §1's "allocated for the FULL world at boot" clause (for the 16k target only) — nothing else in ADR-0014 |
| **Enables** | The 16,000×16,000×32 production world target (voxel-world.md Tuning Knobs, Slice revision 2026-07-23) |
| **Blocks** | ADR-0012's chunked-save decision, ADR-0013's dungeon-offset recompute, ADR-0005's window-build timing note — all three await this ADR's residency model (see Cascading Updates) |
| **Ordering Note** | Not implementation-startable until the spike passes and Status flips to Accepted. The 2000×2000×32 baseline (ADR-0014) is unaffected and remains buildable now. |

## Context

### Problem Statement
ADR-0014 allocates the full world's packed chunk data at boot — validated at 2000×2000×32 (~172 MB). The vertical slice's production target is **16,000×16,000×32** (voxel-world.md, Slice revision 2026-07-23): an 8× linear / ~64× areal jump. A naive linear projection is **≈11 GB resident at boot** (172 MB × ~64), ~3× over the project's 4 GB memory ceiling (`.claude/docs/technical-preferences.md`). This is a **storage/residency problem, not a rendering problem** — draw calls are already decoupled from world size by ADR-0014's streamed view window; the only open question is whether all 16k×16k×32 cell data can stay resident at once (it cannot) and what to do instead.

### Constraints
- Godot 4.7-stable; the residency change must sit entirely behind ADR-0014's existing chunk model and Voxel World's unchanged public accessor API (O(1) `get`/`set` by `Vector3i`, `cell_changed` signal, `raycast_cells` DDA)
- 4 GB memory ceiling (`technical-preferences.md`); must hold during sustained travel across the world, not just at boot
- The world is bounded (16k×16k×32), not infinite/streaming-scale — a genuinely infinite-world architecture over-solves this
- Far-world writes exist and are not rare: terrain dig orders (TR-voxel-world-051) and building writes can target chunks not currently resident; villager nav (ADR-0007) covers only a bounded settlement region, so most far chunks have no live consumer but can still be mutated by player-directed orders
- The existing streaming budget/discipline (ADR-0014 §3: `stream_chunk_budget`, staggered unload) must be reused, not replaced — the slice's one 133 ms hitch came from an unload burst, a solved-by-discipline problem this ADR must not reintroduce

### Requirements
- Resident memory bounded to a function of the view/settlement footprint, NOT of world size — flat as the world scales from 2k to 16k
- Correct reads AND writes to chunks not currently resident (a dig order on a far chunk must not corrupt or drop data)
- Save/load must scale without a single monolithic multi-GB pass (aligns ADR-0012's named chunking escape hatch)
- No new frame hitch at the streaming edge beyond ADR-0014's already-accepted streaming cost

## Decision

**Paged / on-demand chunk residency via region files. Only camera-near and active-settlement chunks are resident; far chunks live in on-disk region files, paged in on approach and evicted staggered when they leave the margin. A load-before-write rule guarantees correctness for far-world mutations. The save format IS the set of region files, aligning ADR-0012's chunking escape hatch. Sparse regeneration of unvisited far terrain (Candidate B) is a planned optimization layer within this model, not the load-bearing mechanism.**

**1. Residency set = camera-near ∪ active-settlement, bounded, world-size-independent.** The resident working set is the union of (a) chunks within ADR-0014's existing view radius of the camera, and (b) the bounded settlement-core region the villager nav graph already covers (ADR-0007, `nav_region_size`). Everything else is not resident. Resident memory is therefore a function of that footprint, not of the 16k×16k extent — flat as the world grows. ADR-0014's `view_radius_chunks` and staggered-unload discipline drive paging; this ADR adds the disk tier they page against.

**Budget is TIME-BASED, not a fixed item count** *(spike-validated 2026-07-23)*. Page-in and eviction integration are each bounded per frame by a **time budget** (`page_budget_ms` / `evict_budget_ms`, validated at 4.0 ms each — chosen to leave ~12 ms of the 16.6 ms frame for game work), NOT by a fixed chunks-per-frame count. The spike proved a fixed count (ADR-0014's `stream_chunk_budget = 2`, tuned for ~25 c/s) **under-provisions ~12×** once camera speed rises to the game's real max (144 c/s ⇒ ~24 new chunks/frame) — a chronic backlog that made memory climb ~5.7× and blew the frame budget. A time budget scales automatically with actual per-chunk cost and resolved the memory-flatness criterion completely (44→254 MB fixed-count → flat 38–84 MB time-based). The budget is **re-checked after every single integrated item** (not once per frame), so a burst of ready items in one frame cannot collectively exceed it — the excess defers to a later frame.

**2. Region files (fixed-size chunk groups on disk).** The world is partitioned into fixed-size **regions** (a square block of chunks, exact dimensions a spike-tuned knob `region_size_chunks`), each a single file of packed chunk arrays (`store_var` on the same `PackedByteArray`-class storage ADR-0014 §1 uses). A region is read into memory when any of its chunks enters the residency margin and written back when its dirty chunks are evicted. Region granularity (not per-chunk files) bounds file-handle churn and amortizes I/O.

**3. Load-before-write rule (correctness for far-world mutations).** Any write to a cell in a non-resident chunk (a dig order, a building write, a save-triggered flush) MUST first page in that chunk's region, apply the write to the resident copy, mark it dirty, and let normal staggered eviction flush it. A write is never applied to disk blind or dropped. Because writes route through Voxel World's existing batched write API (voxel-world Core Rule 6/8), this rule lives in one place — the write path — not in every caller (Building System, dig-order execution, etc. are unchanged). For the MVP/slice scope, far-world writes are player-directed and low-frequency, so a page-in on the write path is acceptable (asynchronous per §6; never blocking the frame).

**Read-through in-flight-write cache (edge case of the same rule)** *(spike-validated 2026-07-23)*. When a dirty chunk is evicted, its flush to disk runs asynchronously (§6). If that same chunk is re-needed **before its flush completes** (a fast reverse-and-return camera path, or a read racing its own not-yet-durable write), the read MUST be served from an in-memory cache of the not-yet-durable bytes (`_write_in_flight_data`), **never** re-read from the region file — the file may be mid-write and incomplete. This is not a separate mechanism but the load-before-write invariant extended to the flush window: the authoritative bytes live in memory until the write is durable. The spike introduced this precisely because moving eviction flushes off-thread (§6) opened the race; the read-through cache closed it (C3 correctness: 20/20 mutate→evict→re-page-in round trips byte-identical).

**4. Save format = region files.** A save is the set of dirty/persisted region files plus the small non-voxel state (project entities, villager state, etc.). This is exactly the chunked-save escape hatch ADR-0012 §Alt-C named — adopting paged residency makes chunked saves fall out of the storage model rather than being a separate decision. Region files are user data (`.gitignore`d), consistent with ADR-0012's save-data category.

**5. Sparse far-terrain regeneration (Candidate B) — planned optimization layer, not load-bearing.** Unvisited far regions need not occupy region files at all if terrain generation is deterministic from the seed: store only *mutated* far chunks (player deltas) and regenerate untouched terrain on page-in. This shrinks both resident and persisted footprint dramatically (settlements are a tiny fraction of 16k²) but leans on cheap, deterministic, versioned regen — a real constraint on terrain gen. It is therefore layered *within* the paging model (a region file that holds only deltas + a "regen the rest" flag) as a fast-follow after the paging mechanism is validated, never the primary mechanism.

**6. No synchronous disk I/O or terrain-gen in the per-frame path — full stop** *(spike-validated 2026-07-23; the sharpened form of the original escape hatch)*. Region reads, region-flush writes, AND terrain regeneration all run on a **capped `WorkerThreadPool`** (`MAX_CONCURRENT_ASYNC_TASKS`, validated at 32 and 64 — worst-frame nearly identical between them, so the exact cap is not load-bearing). A chunk whose background task has not finished, **or could not even be dispatched because the pool is at capacity, simply stays queued for a later frame** — it is NEVER regenerated or read synchronously on the main thread as a fallback. This is the load-bearing correction the spike surfaced: **a synchronous fallback IS the failure mode.** Async-I/O-with-a-sync-fallback (the original §6 framing) improved the *average* case (~4× cheaper ticks) but left a worst-case tail of ~55 ms (real speed) — because a single unusually expensive item (a tree-dense chunk's regen at ~15–17 ms, or an unlucky ~48 ms disk op under OS/AV overhead) that lands on the main thread cannot be preempted or subdivided by any budget. Removing every synchronous fallback dropped the worst frame to ~13–15 ms across all four speed×cap combinations (`io_worst` and `regen_worst` = 0.00 ms by construction). The cap-miss path being "stay queued," not "run it now," is what makes the cap value itself non-critical. A GDExtension/native swap remains available behind the same interface if ever needed (matching ADR-0014's mesher escape hatch), but is not required.

   **One accepted synchronous exception — per-region header I/O, never per-tick.** A region file's fixed header (the `SLOTS_PER_REGION` int64 offset table) is read/created synchronously the first time that region is touched — a one-time-per-region cost (measured 31–63 ms *cumulative across an entire 27k–32k-tick run*, never a per-tick spike, invisible in every worst-frame number). This is the only sanctioned main-thread file operation and it does not recur per frame.

   **Production note (drain-loop efficiency).** The spike's drain loop re-scans every not-yet-ready queued item every tick (`deferred_pagein_events`/`deferred_evict_events` reach tens of millions across a run) — harmless to frame time (well under budget throughout) but wasteful. A production implementation (Voxel World `/dev-story`) should make the drain **completion-driven** — re-examine only items whose background task just completed, via a completion callback/signal — rather than polling `is_task_completed` across the whole queue each tick.

### Architecture Diagram
```
Voxel World public API (UNCHANGED — ADR-0014 §1):
  get(Vector3i) / set(Vector3i) / cell_changed / raycast_cells
        │
        ▼
Residency manager (NEW — this ADR):
  resident set = camera-near chunks (ADR-0014 view radius)
               ∪ active-settlement chunks (ADR-0007 nav region)
        │                                   │
   page-in on approach                 staggered eviction
   (ADR-0014 stream budget)            (ADR-0014 unload discipline)
        │                                   │
        ▼                                   ▼
  Region files on disk (packed chunk arrays; region_size_chunks)
        ▲
        │ load-before-write: a write to a non-resident chunk pages in
        │ its region FIRST, applies to the resident copy, marks dirty
   Far-world write (dig order TR-voxel-world-051, building write)

Save = set of persisted region files + small non-voxel state
       (project entities per ADR-0016, villager state per ADR-0012)

Optimization layer (Candidate B, fast-follow): unvisited far regions
  store only player deltas; untouched terrain regenerated from seed
  on page-in (requires deterministic versioned terrain gen)
```

### Key Interfaces
```gdscript
# Internal to Voxel World — NOT a new public API (ADR-0014's accessors are unchanged).
# The residency tier is transparent to every consumer.

# Residency manager (implementation detail):
func _ensure_resident(chunk: Vector3i) -> void   # page in the chunk's region if absent
func _on_write(cell: Vector3i, value: int) -> void:
    _ensure_resident(_chunk_of(cell))            # load-before-write rule (Decision §3)
    _apply_write(cell, value)                    # existing batched write path
    _mark_region_dirty(_region_of(cell))

func _evict(chunk: Vector3i) -> void             # staggered, ADR-0014 unload budget;
                                                 # flushes dirty region to disk first
```

## Alternatives Considered

### Alternative A: Paged / on-demand region-file residency (+ B as a layer) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: the only candidate that decouples resident memory from world size *structurally*; reuses ADR-0014's streaming budget/discipline wholesale; the save format falls out for free (aligns ADR-0012); B slots in as an optimization without re-architecting.
- **Cons**: introduces disk I/O on the (low-frequency) far-world write path and the streaming edge — the exact thing the spike must prove stays under budget; a dirty-region flush discipline that must be correct (a dropped flush is data loss).
- **Rejection Reason**: N/A — chosen (pending spike).

### Alternative B: Sparse storage for far/unvisited regions (procedural + delta) — ADOPTED AS A LAYER, NOT STANDALONE
- **Description**: keep only mutated far chunks; regenerate unvisited terrain from the seed on demand, storing only player deltas.
- **Pros**: smallest possible resident + save footprint (settlements are a tiny fraction of 16k²); no full-terrain region files for untouched world.
- **Cons**: requires deterministic, cheap, *versioned* regen from seed (a hard constraint on terrain gen — any gen change must not silently alter already-visited-but-unsaved terrain); "has this cell been touched?" bookkeeping.
- **Rejection Reason**: powerful but too load-bearing to rest the whole residency guarantee on; adopted as a fast-follow optimization *within* A (Decision §5) where its regen-determinism risk is contained.

### Alternative C: Reduced persisted footprint (compression / bit-packing), still fully resident
- **Description**: shrink bytes-per-cell (palette/RLE/bitfield) to fit 16k²×32 under 4 GB without paging at all.
- **Pros**: simplest — no paging, no disk I/O on the hot path, smallest change from ADR-0014.
- **Cons**: the required reduction is ~64× areal growth under a 4 GB ceiling; realistic compression buys ~4–8× at meaningful density, not 64× — a scaling *ceiling*, not a solution. It defers the problem rather than solving it and still fails at the target.
- **Rejection Reason**: does not reach the 16k target; would need paging anyway once density rises. Compression may still be applied *inside* region files as an orthogonal win, but it is not the residency mechanism.

## Consequences

### Positive
- Resident memory is bounded by footprint, not world size — the 4 GB ceiling holds at 16k and beyond.
- ADR-0014's entire rendering/streaming design is preserved; this is purely a storage tier beneath it.
- Chunked saves (ADR-0012) and a natural on-disk format fall out of the residency model rather than being separate work.
- B's sparse-regen optimization has a clean home without a second architecture pass.

### Negative
- Introduces a disk tier with dirty-flush correctness obligations (a dropped or mis-ordered flush is data loss) — mitigated by centralizing flush in eviction and load-before-write in the single write path.
- Far-world writes incur a synchronous page-in in the base design — acceptable at MVP/slice far-write frequency, but the named async escape hatch (Decision §6) exists if measured otherwise.

### Risks
- **Risk**: page-in latency at the streaming edge causes a frame hitch during fast travel.
  **Mitigation**: reuse ADR-0014's per-frame stream budget for region loads; async `WorkerThreadPool` I/O is the named escape hatch. **The spike measures this directly.**
- **Risk**: sustained travel across a 16k-scale world leaks resident memory if eviction lags page-in.
  **Mitigation**: eviction shares ADR-0014's staggered-unload budget; the spike asserts a held ceiling under sustained travel, not just steady state.
- **Risk (B layer)**: a terrain-gen change silently alters unvisited terrain that a save assumed regenerable.
  **Mitigation**: versioned seed/gen; a gen-version bump forces affected regions to persist rather than regen. Deferred with the B layer itself.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| voxel-world.md | Tuning Knobs (Slice revision 2026-07-23): "Production target 16,000×16,000×32 ... gated behind a dedicated storage/streaming spike (a successor to ADR-0014) that must resolve one of: paged/on-demand chunk loading, sparse storage for far/unvisited regions, or a reduced persisted footprint" | Paged/on-demand region-file residency (option 1), with sparse-regen (option 2) as a layer; reduced-footprint (option 3) rejected as insufficient |
| voxel-world.md | TR-voxel-world-051 (terrain dig orders on any cell) | Load-before-write rule (Decision §3) makes far-world dig-order writes correct against non-resident chunks |
| voxel-world.md | Dependencies (Slice revision): save payload scales ~64× at the 16k target | Save format = region files (Decision §4), aligning ADR-0012's chunking escape hatch |

## Performance Implications
- **CPU**: region page-in/flush is amortized file I/O on the existing stream budget; far-world writes add one synchronous page-in each (low frequency). Spike-measured.
- **Memory**: bounded to the resident working set (camera-near ∪ settlement) — target flat vs world size; the whole point of the ADR. Spike asserts the 4 GB ceiling holds under sustained travel.
- **Load Time**: boot no longer allocates the full world — it loads only the initial residency set, which should *reduce* ADR-0014's ~2.6 s initial window build's storage component (feeds ADR-0005's timing note).
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no production voxel storage implemented yet. This ADR is authored before Voxel World's production `/dev-story` work; ADR-0014's full-boot allocation was never shipped beyond the prototype.

## Validation Criteria (THE SPIKE — this ADR's Accept gate, modeled on ADR-0007/0008 QQ3) — PASSED 5/5 (2026-07-23)

The synthetic-16k-scale storage/streaming spike (`prototypes/storage-residency-spike/`, commits afb609c + 799ddbc) PASSED all five criteria over three measurement rounds, at the game's **real max camera speed (144 cells/sec, derived from `camera_input.gd`: `PAN_SPEED_FACTOR 1.2 × DISTANCE_MAX 120`)** and an aggressive stress speed (120 c/s), at async caps 32 and 64:

1. **Page-in latency at the streaming edge** — **PASS.** Worst frame **13.3–14.5 ms** across all four speed×cap combinations (p95 ~4.6–5.3 ms, avg ~3.1–3.3 ms), inside the 16.6 ms budget. `io_worst` and `regen_worst` = **0.00 ms by construction** (no main-thread disk/gen). [Round 1's fixed-count design failed here at 106 ms; time-based budget (§1) + no-sync-fallback (§6) closed it.]
2. **Memory ceiling under sustained travel** — **PASS.** Peak **43.9–83.7 MB** (≤4 GB ceiling, ~1–2% utilization), **flat** across a repeated full-16k-span corridor traverse. [Fixed-count design climbed 44→254 MB; time-based budget made it flat.]
3. **Write-to-unloaded-chunk correctness** — **PASS.** 20/20 scattered far-chunk mutate→evict→re-page-in round trips byte-identical (the read-through in-flight-write cache, §3, closed the flush-window race).
4. **Eviction under budget** — **PASS.** Staggered within the time budget; worst eviction-active tick 11.9–14.5 ms, zero unload-burst hitch.
5. **Save/load round-trip via region files** — **PASS.** 40/40 chunks byte-identical after full flush + brand-new-instance reload. **Disk footprint 0.77 MB vs a naive full-world save of 7.63 GB (~1,600× reduction)**, from only 49 region files of a possible 1,024. Aggregate: **99.50% of page-ins were regenerations, 0.50% (322) disk loads** — direct validation of Decision §5 (the disk tier exists almost entirely for correctness, not bulk terrain).

Two implementation bugs were found and fixed before the numbers were trusted (per the spike's honesty rule): (i) `WorkerThreadPool.wait_for_task_completion()` returns an Error code, not the Callable's value — the background task writes its result into a mutex-guarded dict instead; (ii) uncapped prefetch dispatch produced a single 10.1-second tick — fixed by the concurrency cap, whose role became "stay queued on cap-miss" rather than "sync fallback." Round 3's decisive lever was removing every synchronous fallback (§6), not raising the cap (worst frame moved ~0.3 ms between cap 32 and 64).

## Cascading Updates This ADR Unlocks (on Accept)
- **ADR-0012 (Save/Load)**: finalize the chunked-save decision — region files become the save format; the no-chunking clause is superseded for the 16k target. (Impact note already recorded there, Slice propagation 2026-07-23.)
- **ADR-0013 (Multi-Scene)**: recompute the dungeon spatial-offset/coordinate budget against the 16k world span (the `100_000` offset's margin, ~6× at 16k). (Impact note already recorded there.)
- **ADR-0005 (Boot Sequencing)**: revise the initial-window-build timing note — boot loads only the initial residency set, not the full world.

## Related Decisions
- Supersedes only ADR-0014's full-world-at-boot clause; depends on the rest of ADR-0014 unchanged.
- Aligns ADR-0012's Alternative C chunking escape hatch as the adopted save format.
- Feeds the coordinate-budget recompute ADR-0013 defers.
- Follows the ADR-0007/0008 provisional-until-spike gate pattern (QQ3) for its own Accept criteria.
