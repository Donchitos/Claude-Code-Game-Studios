# Story 020: Mesh invalidation — dirty-marking + budgeted rebuild drain + `chunk_became_resident` (TD ruling D7)

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-26 — 1042/1042 suite green 0 orphans, parent-verified)
> **Layer**: Presentation (mesher/streamer tier) + Foundation (one additive residency signal)
> **Type**: Integration (invalidation lifecycle + per-frame budget discipline)
> **Estimate**: **M** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*
> **Lane**: `godot-gdscript-specialist`
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**Source ruling**: `production/architecture-decisions-m02-preflight-2026-07-26.md` **Addendum D — D7**
(technical-director, **PROVISIONAL pending user ratification**). This story is downstream action #18 of
that addendum. The spec below is the ruling; it is not re-derived here.

**The escalated premise was FALSE and is corrected by this story's existence.** sprint-09.md's D7 open
item and `scene-005`'s Control Manifest Guardrail both state that *"`VoxelWorldMeshStreamer` subscribes to
no signal and has no invalidation path, so a block the player places is written to the grid and never
appears."* The verification behind it (*zero occurrences of `cells_changed_batch` in
`voxel_world_mesh_streamer.gd`*) is true **about that file** and the conclusion drawn from it is not. The
invalidation path lives one layer down, in the mesher:

- `voxel_world_mesher.gd:163-164` — `setup()` connects **both** `grid.cell_changed` and
  `grid.cells_changed_batch`.
- `_on_cell_changed` / `_on_cells_changed_batch` → `_chunk_keys_touched_by()` → `build_chunk()` for every
  **tracked** touched chunk, deduped (`_chunk_nodes.has(key)` is the tracked gate).
- `_chunk_keys_touched_by()` already dirties the cross-chunk **X/Z seam neighbour** — the exact counterpart
  to `_is_chunk_local_air()` case 3, which resolves a seam face through `_is_air()`/`get_cell()` against
  the neighbour chunk. **This is correct and must not be touched.**
- `setup()` is genuinely reached in production: `Valley.get_injected_tier_modules()` returns
  `_voxel_world_mesher` and `GameWorld._setup_injected_tier()` calls `setup()` on every entry.
- The write path is live end-to-end: `CommitPipeline` → job → `ConstructionTickLoop._on_tick` →
  `voxel_world.bulk_write(changes)` → `cells_changed_batch` → mesher rebuild.

**The streamer subscribing to nothing is correct layering, not a bug**: the mesher owns chunk *content*,
the streamer owns chunk *membership*. Adding a streamer subscription would duplicate
`_chunk_keys_touched_by()` and double-rebuild every dirty chunk. That is why AC-NO-STREAMER-SUBSCRIPTION
below is a *guard*, not a task.

**What is actually broken — two real defects this story closes:**

- **Defect 1 (performance, the real D7 bug).** `_on_cells_changed_batch` rebuilds every touched tracked
  chunk in **one synchronous pass inside the signal handler, on the main thread, with no time budget**. At
  the measured **7.7 ms/chunk** (vox-019: 40.4 → 7.7 ms via the bulk `ChunkSnapshot`), a demolition or a
  large floor commit spanning 9 chunks is a **~69 ms frame spike** — a direct violation of the control
  manifest's "no unbounded work in the frame path".
- **Defect 2 (correctness, the more likely cause of any observed "missing terrain").** Residency page-in
  emits **nothing**. `VoxelWorldGrid` has exactly three emit sites (`set_cell` 1036, `bulk_write` 1090,
  `_apply_pending_writes` 1191); neither `_integrate_one_finished_read` (1651) nor
  `_try_serve_from_in_flight_write` (1556) emits when a chunk becomes resident. `get_chunk_snapshot()`
  returns `null` for a non-resident chunk and `build_chunk()` writes `.mesh = null`. **The mesh window and
  the residency window share the same `view_radius_chunks`**, so in steady state a chunk routinely enters
  the mesh window before its async, budgeted page-in lands — and then **never re-meshes**. That is a
  permanent hole. `scene-005`'s genesis-before-mesh ordering closes the **boot** case only; the leading
  edge of a moving camera outrunning async page-in is untouched by it.

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-025` (rendering representation; 60 FPS on the production window with
culling ENABLED), `TR-voxel-world-053` (paged/on-demand residency; no synchronous per-frame I/O or
generation), `TR-voxel-world-023` (streaming tunables from config)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0014** (Chunked Voxel Rendering) — this story is the subject of the
pending ADR-0014 amendment (Decision §2 gains the dirty-set/budgeted-drain contract; §3 gains the rebuild
phase's ordering and shared-window rule); **ADR-0015** (Residency) — the subject of the pending amendment
adding `chunk_became_resident` to the residency tier. **Both amendments are technical-director-owned
downstream actions #20/#21 of Addendum D; this story implements the ruled behaviour and does not author
the ADR text.**

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM-HIGH — rendering is the top post-cutoff knowledge-gap
domain, but this story adds **no new engine API surface**: it reuses `_drain_budgeted`, `build_chunk`, and
a plain `signal`. The risk is in the ordering/budget contract, which the ACs pin.

**Control Manifest Rules (this layer):**
- **Required**: all meshing work stays inside a **time-budgeted drain**; the rebuild phase is drained
  **first**; `_chunk_keys_touched_by()`'s seam-neighbour behaviour is preserved byte-for-byte; the mesher
  remains the only owner of chunk content and the streamer the only owner of chunk membership.
- **Forbidden**: a **new budget knob** for rebuild (see AC-BUDGETED-DRAIN's rationale — it would regress
  vox-019's measured p95); subscribing `VoxelWorldMeshStreamer` to any grid signal; persisting a dirty set
  across `unload_chunk()`; any change to emitted winding/culling/geometry (vox-007/vox-019's guards stay
  green and unchanged); `CULL_DISABLED`; synchronous region I/O or terrain generation on the frame path.
- **Guardrail**: full blocking regression suite green with zero orphans at every commit; draw calls remain
  ≤ 2000; `mesher_winding_derivation_test.gd`, `mesher_material_contract_test.gd` and
  `mesher_bulk_read_equivalence_test.gd` remain green **unchanged** — this story changes *when* a chunk is
  rebuilt, never *what* it emits.

---

## Acceptance Criteria

- [ ] **AC-DIRTY-NOT-REBUILD** — `VoxelWorldMesher`'s two change handlers (`_on_cell_changed`,
      `_on_cells_changed_batch`) change from *rebuild now* to **mark dirty now**. A private
      `_dirty_chunks: Dictionary[Vector2i, bool]` is populated instead of calling `build_chunk()` inside
      the handler; `get_dirty_chunk_keys() -> Array[Vector2i]` and `clear_dirty(key: Vector2i) -> void` are
      the public surface the streamer drives. **Asserted, not assumed**: a `bulk_write` spanning N tracked
      chunks performs **zero** `build_chunk()` calls during signal dispatch (call-count assertion on an
      instrumented mesher) and leaves exactly N keys dirty. This is the fix for Defect 1 — the ~69 ms
      9-chunk spike ceases to exist as a code path. [TR-voxel-world-025]
- [ ] **AC-BUDGETED-DRAIN** — The rebuild drain runs through the **existing** `_drain_budgeted` inside the
      **existing `VoxelWorldConfig.mesh_build_budget_ms`** (default 4.0), as **ONE shared window covering
      rebuild-then-build. NO NEW KNOB.** *Rationale, which is binding and must be recorded in the config /
      call-site doc comment:* an independent rebuild budget would let `_drain_budgeted`'s progress
      guarantee integrate one chunk in **each** phase — worst case **7.7 + 7.7 = 15.4 ms of meshing in a
      16.6 ms frame**, which would **regress vox-019's measured p95 of 16.947 ms**. A shared window keeps
      the worst case at exactly **one chunk per frame** — today's measured profile — while giving the
      player's own edit priority over a distant window-edge chunk. Asserted by a test that dirties K
      chunks *and* moves the window so J new chunks are needed, then proves at most one meshing operation
      (rebuild **or** build) occurs per `_sync_window` call at the shipped budget. `mesh_unload_budget_ms`
      keeps its **own separate** window — a different work class (`queue_free`, not meshing) — and is
      unchanged. [TR-voxel-world-023, TR-voxel-world-025]
- [ ] **AC-REBUILD-FIRST** — `VoxelWorldMeshStreamer._sync_window` gains a **rebuild phase drained FIRST**:
      strictly before the build-new phase and strictly before the unload phase. Proven by an ordering
      assertion over an instrumented call log (rebuild of an existing key precedes any new-chunk build in
      the same call), not by reading the code. Ordering rationale: the player's own edit is always the
      most recently-relevant geometry on screen; a window-edge chunk they are driving toward is not.
      Latency cost, accepted and named: **at most one frame** for a single-block placement — the progress
      guarantee always integrates one dirty chunk per call, the same guarantee entry-meshing already ships.
- [ ] **AC-UNLOAD-CLEARS-DIRTY** — `unload_chunk(key)` **erases** `key` from the dirty set. **No dirty-set
      persistence across unload, and no bookkeeping is built for it**: `build_chunk()` always reads
      *current* grid state, so a chunk re-entering the window is correct **by construction**. Pinned by a
      test — dirty a tracked chunk, unload it, re-enter it via the window, assert the resulting mesh
      matches a chunk built fresh from the same grid state and that the dirty set never held a stale key.
      Do **not** add cross-unload dirty tracking; this AC exists to forbid it.
- [ ] **AC-UNTRACKED-NO-BOOKKEEPING** — The dirty set is populated **only for keys already present in
      `_chunk_nodes`** (the existing "tracked" gate). A change to a cell in an untracked chunk records
      **nothing** — dirty-set size is unchanged after such a write, asserted directly. Same reasoning as
      AC-UNLOAD-CLEARS-DIRTY: an untracked chunk is built fresh from current state whenever it enters the
      window, so tracking it would be unbounded growth in exchange for zero information.
- [ ] **AC-SEAM-NEIGHBOUR** — `_chunk_keys_touched_by()` is **unchanged**; its existing cross-chunk X/Z
      seam-neighbour dirtying is preserved and now covered by a **regression test**: a write to a cell on a
      chunk's outer local-x/local-z edge marks **both** the owning chunk **and** the seam neighbour dirty
      (when both are tracked), and the neighbour's rebuilt geometry differs from its pre-write geometry —
      proving the seam face actually re-resolved through `_is_chunk_local_air()` case 3. A write to an
      interior cell marks exactly one key. [TR-voxel-world-052 adjacency — geometry itself unchanged]
- [ ] **AC-PAGEIN-SIGNAL** — `VoxelWorldGrid` gains `signal chunk_became_resident(chunk_key: Vector2i)`,
      emitted from `_integrate_one_finished_read` **and** `_try_serve_from_in_flight_write`, **after**
      `_chunks[chunk_key]` is assigned (emit-after-assign is load-bearing: a synchronous handler must
      observe the resident chunk, and `get_chunk_snapshot()` must not return `null` inside the handler).
      `VoxelWorldMesher.setup()` subscribes and **marks the key dirty if tracked**. This closes **Defect 2
      through the same machinery, with no second mechanism**. Asserted: a chunk meshed while non-resident
      (mesh `null` / empty arrays) becomes correctly meshed after its page-in lands, within one budgeted
      `_sync_window` call — the permanent-hole class ceases to exist. The signal fires **once** per
      residency integration and never on eviction. [TR-voxel-world-053]
- [ ] **AC-NO-STREAMER-SUBSCRIPTION** — `VoxelWorldMeshStreamer` subscribes to **no** grid signal —
      **grep-guarded by test**: zero `cells_changed_batch`, `cell_changed` or `chunk_became_resident`
      *connect* occurrences in `voxel_world_mesh_streamer.gd`. Layering confirmed by the ruling: the mesher
      owns chunk **content**, the streamer owns chunk **membership**. A streamer subscription would
      duplicate `_chunk_keys_touched_by()` and double-rebuild every dirty chunk. This AC is the standing
      guard against "fixing" D7 the way the escalation originally proposed.
- [ ] **AC-BOOT-UNBOUNDED** — `build_initial_window` passes **unbounded** (the existing `< 0.0` →
      `-1` UNBOUNDED contract in `_budget_usec`) to the **rebuild phase too**, not only to the build phase
      — so the two phases share one consistent boot contract. Asserted; and asserted that **the dirty set
      is empty at boot regardless**, so the unbounded rebuild phase is a no-op at boot in practice. ADR-0005
      is unaffected: `build_initial_window` still runs inside WIRING, strictly before `ACTIVE`.
- [ ] **AC-SUITE-GREEN** — The full blocking regression suite runs green headless with **zero orphans** at
      every commit (GdUnit4 exit code AND printed orphan count both clean — carried S7/S8 discipline).
      `mesher_winding_derivation_test.gd`, `mesher_material_contract_test.gd` and
      `mesher_bulk_read_equivalence_test.gd` remain green **with zero test edits** — this story changes
      *when* a chunk is rebuilt, never *what* it emits. Forbidden-pattern grep families
      (`CULL_DISABLED`, `SceneTree.paused`, `Engine.time_scale`, synchronous render-thread I/O/gen) stay
      absent.

---

## Implementation Notes

*Derived from Addendum D / D7 §§1–6. The ruling names the shape; these notes name the seams, not a
prescribed implementation.*

- **Order of work that keeps the suite green at every step** (do not batch these): (1) add
  `_dirty_chunks` + `get_dirty_chunk_keys()` / `clear_dirty()` while the handlers still rebuild → suite
  green; (2) flip the handlers to mark-only and add the streamer's rebuild phase in the **same** commit
  (a mark-only handler with no drain is a regression) → suite green; (3) add `chunk_became_resident` and
  its subscription → suite green; (4) add the grep guard and the seam regression test.
- **The rebuild phase's item list** is `mesher.get_dirty_chunk_keys()` filtered to keys still tracked,
  drained by the same `_drain_budgeted(items, start_usec, budget_usec, action)` the build and unload
  phases already use. The shared window means the **same `build_start_usec` and the same
  `_budget_usec(build_budget_ms)`** are passed to the rebuild drain and then to the build drain — that
  single shared start timestamp *is* the mechanism that caps the frame at one chunk. Do not compute a
  second start timestamp.
- **`clear_dirty(key)` is called by the drained action**, immediately after `build_chunk(key)` returns, so
  a key that the budget did not reach stays dirty for the next frame. A key that is unloaded between
  frames is erased by `unload_chunk()` (AC-UNLOAD-CLEARS-DIRTY) and must not reappear.
- **`chunk_became_resident` emit placement**: after the `_chunks[chunk_key]` assignment in each of the two
  sites, not before, and outside any early-return path that leaves the chunk non-resident. Cross-reference
  the two existing emit-site idioms (`set_cell` 1036, `bulk_write` 1090) for the established emit style.
- **Do not touch `_chunk_keys_touched_by()`.** It is already correct for the seam case; AC-SEAM-NEIGHBOUR
  covers it with a test so that a future refactor cannot silently drop it.
- Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01.
  Typed `Dictionary[Vector2i, bool]` is already exercised in this file family (`_chunk_nodes` is
  `Dictionary[Vector2i, MeshInstance3D]`), so this story introduces no new typed-collection risk.

---

## Out of Scope

- **Greedy meshing** — ADR-0014 §2's named optimisation reserve. **Residual risk accepted and named by the
  ruling**: a multi-chunk demolition now settles over ~1 chunk/frame instead of one spike — ~9 frames for a
  9-chunk edit. The real lever is the **7.7 ms per-chunk cost**, and that lever is greedy meshing, which is
  **not in this story**.
- **The GDExtension mesher escalation** (ADR-0014 §5) — a distinct lever, filed only if measurement demands
  it.
- **Any change to the boot/steady-state radius** — that is **vox-021**, which sequences immediately after
  this story and edits the same file. **Serialize them.**
- **Streamer subscribing to grid signals** — explicitly forbidden (AC-NO-STREAMER-SUBSCRIPTION).
- **Dirty-set persistence across unload / untracked-chunk bookkeeping** — explicitly forbidden
  (AC-UNLOAD-CLEARS-DIRTY, AC-UNTRACKED-NO-BOOKKEEPING). The ruling's own words: *"Pin this with a test; do
  not build bookkeeping for it."*
- **The ADR-0014 / ADR-0015 amendment text** — technical-director-owned (Addendum D downstream actions
  #20/#21). This story implements the ruled behaviour; it does not author ADR text.
- **Any change to emitted winding / culling / geometry** — vox-007/vox-019's guards are the regression net.

---

## QA Test Cases

- **AC-DIRTY-NOT-REBUILD (Logic, unit)**: Given an instrumented mesher tracking N chunks, When a
  `bulk_write` touches cells in all N, Then `build_chunk()` call count during dispatch is **0** and
  `get_dirty_chunk_keys()` returns exactly those N keys. [TR-voxel-world-025]
- **AC-BUDGETED-DRAIN (Integration)**: Given K dirty chunks and J newly-desired chunks at the shipped
  `mesh_build_budget_ms = 4.0`, When `_sync_window` runs once, Then at most **one** meshing operation
  (rebuild or build) occurred. Given a **new** rebuild budget knob is searched for in
  `voxel_world_config.gd`, Then none exists (grep guard).
- **AC-REBUILD-FIRST (Integration)**: Given both a dirty tracked chunk and a newly-desired chunk, When
  `_sync_window` runs with a budget large enough for several items, Then the rebuild appears **before** any
  new build and both appear before any unload in the ordered call log.
- **AC-UNLOAD-CLEARS-DIRTY (Integration)**: Given a dirty tracked chunk, When `unload_chunk()` runs, Then
  the key is absent from `get_dirty_chunk_keys()`; When the chunk later re-enters the window, Then its
  mesh equals a chunk built fresh from current grid state.
- **AC-UNTRACKED-NO-BOOKKEEPING (Logic, unit)**: Given a write to a cell in an **untracked** chunk, Then
  `get_dirty_chunk_keys()` is unchanged in size and content.
- **AC-SEAM-NEIGHBOUR (Logic, unit)**: Given two tracked adjacent chunks, When a cell on their shared X (or
  Z) seam is written, Then **both** keys are dirty and the neighbour's rebuilt arrays differ from its
  pre-write arrays; When an interior cell is written, Then exactly one key is dirty.
- **AC-PAGEIN-SIGNAL (Integration)**: Given a tracked chunk meshed while its data was **not** resident
  (mesh `null`/empty), When its async page-in integrates, Then `chunk_became_resident(key)` fires exactly
  once, the key is marked dirty, and one budgeted `_sync_window` call produces correct geometry. Given an
  eviction, Then the signal does **not** fire.
- **AC-NO-STREAMER-SUBSCRIPTION (grep guard, test)**: Given `voxel_world_mesh_streamer.gd`, When scanned
  for `cell_changed` / `cells_changed_batch` / `chunk_became_resident` connect sites, Then zero occurrences.
- **AC-BOOT-UNBOUNDED (Integration)**: Given `build_initial_window`, Then the rebuild phase receives the
  UNBOUNDED budget contract (`< 0.0` → `-1`) exactly as the build phase does; Then the dirty set is empty
  at boot.
- **AC-SUITE-GREEN (gate)**: full blocking suite headless, zero orphans, zero edits to the three existing
  mesher tests.

---

## Test Evidence

**Story Type**: Integration (BLOCKING)
**Required evidence**:
- `neues-spiel/tests/integration/voxel_world/mesh_invalidation_budget_test.gd` — the invalidation
  lifecycle + budget/ordering assertions (AC-DIRTY-NOT-REBUILD, AC-BUDGETED-DRAIN, AC-REBUILD-FIRST,
  AC-UNLOAD-CLEARS-DIRTY, AC-UNTRACKED-NO-BOOKKEEPING, AC-SEAM-NEIGHBOUR, AC-PAGEIN-SIGNAL,
  AC-NO-STREAMER-SUBSCRIPTION, AC-BOOT-UNBOUNDED) — must exist, pass headless, and run in the commit gate.
- The three existing mesher tests (`mesher_winding_derivation_test.gd`,
  `mesher_material_contract_test.gd`, `mesher_bulk_read_equivalence_test.gd`) green with **zero edits**.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete/landed): **vox-015** (`build_initial_window` / `update_view_window` /
  `_sync_window` / `_drain_budgeted` — the machinery this story adds a phase to), **vox-007** (the mesher
  and its `_chunk_keys_touched_by` seam logic), **vox-019** (the 7.7 ms/chunk measured cost the shared-budget
  rationale rests on, and the `ChunkSnapshot` read path `build_chunk` uses), **vox-010→014** (the residency
  integration sites `chunk_became_resident` is emitted from), **vox-003** (`bulk_write` + `cells_changed_batch`).
- **Blocked on**: nothing. Every surface it touches is landed.
- **Sequencing**: **BEFORE `scene-005`** (Addendum D downstream action #18 lists `scene-005` as blocked by
  this story — it closes scene-005's Open Decision #4 and corrects its Control Manifest Guardrail).
  **Parallel-safe with `building-023`** (disjoint files: ghost preview is pooled `MeshInstance3D` over the
  pick path, never the chunk mesher or the streamer). **`vox-021` sequences immediately after this story —
  both edit `voxel_world_mesh_streamer.gd`, so they must be serialized.**
- **Unlocks**: `scene-005` (guardrail corrected, Open Decision #4 closed); the player-placed block appearing
  without a frame spike; the steady-state page-in hole class (Defect 2) closing — which is the precondition
  for any human playtest reading the build as visually correct.
- **Open decisions**: none. D7 is ruled. The two ADR amendments (#20 ADR-0014, #21 ADR-0015) are
  technical-director-owned and do not block this story's implementation.
