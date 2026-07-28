# Epic: Voxel World / Grid Data

> **Layer**: Foundation
> **GDD**: design/gdd/voxel-world.md
> **Architecture Module**: Voxel World / Grid Data (the `Vector3i`-addressed cell grid; raw read/write primitives; change-signal emission; procedural terrain; chunked mesher + paged residency storage tier)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 21 stories created (019 = vox-018 MISS remediation, filed 2026-07-25; **020/021 = TD
> Addendum D rulings D7/D2, filed 2026-07-26** — both PROVISIONAL pending user ratification of
> `production/architecture-decisions-m02-preflight-2026-07-26.md`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Grid config + coordinate math + bounds | Logic | Ready | ADR-0002 |
| 002 | Chunked packed-array storage + O(1) accessors + single-cell signal | Logic | Ready | ADR-0014 |
| 003 | Bulk write + batched signal (per-cell before/after) | Logic | Ready | ADR-0014 |
| 004 | Neighbor lookup + DDA cell-picking | Integration | Ready | ADR-0004 |
| 005 | iterate_occupied (torn-read-free) | Integration | Ready | ADR-0014 |
| 006 | Procedural terrain generation + single batched gen signal | Logic | Ready | ADR-0002 |
| 007 | Chunked mesher CW-winding + culling ENABLED (TECH DEBT 1) | Visual/Feel | Ready | ADR-0014 |
| 008 | Floor terrain-replace write path (restore_value) | Integration | Ready | ADR-0014 |
| 009 | Terrain dig-order removal write path (1..5 family) | Integration | Ready | ADR-0014 |
| 010 | Region-file format + paged residency working set | Integration | Ready | ADR-0015 |
| 011 | Async region I/O + terrain-gen on capped WorkerThreadPool | Integration | Ready | ADR-0015 |
| 012 | Time-based per-frame page-in / eviction budget | Integration | Ready | ADR-0015 |
| 013 | Read-through in-flight-write cache | Integration | Ready | ADR-0015 |
| 014 | Load-before-write for far-world mutations | Integration | Ready | ADR-0015 |
| 015 | Mesh view-window streaming (build + unload budgets) | Integration | Ready | ADR-0014 |
| 016 | ADR-0015 C1 — async cap + bounded gen cost (TECH DEBT 3) | Config/Data | Ready | ADR-0015 |
| 017 | ADR-0015 C4 — completion-driven drain (TECH DEBT 3) | Integration | Ready | ADR-0015 |
| 018 | Live Valley view-window wiring + 60-FPS-with-culling measurement (criterion #12) | Integration | Complete | ADR-0014 |
| 019 | Mesher chunk-build read-loop optimization + budget re-tune + re-measure (vox-018 MISS remediation #1) | Logic | Complete | ADR-0014 |
| 020 | Mesh invalidation — dirty-marking + budgeted rebuild drain + `chunk_became_resident` (TD D7) | Integration | Ready | ADR-0014 / ADR-0015 |
| 021 | Boot-scoped mesh radius + `view_radius_chunks` 24 → 12 retune (TD D2) | Integration | Ready | ADR-0014 / ADR-0005 |

## Overview

Voxel World is the single source of truth for the block-level composition of the
world — procedural valley terrain and every placed building block, on one
`Vector3i`-addressed grid. It owns the O(1) accessor API (`get_cell`,
`raycast_cells`, `get_neighbors`, `set_cell`/`clear_cell`, `bulk_write` with its
exactly-one-signal guarantee, `iterate_occupied`), the `cell_changed` /
`cells_changed_batch` signals, the chunked face-culled mesher (ADR-0014), and the
paged region-file residency tier (ADR-0015) that keeps resident memory bounded by
footprint, not world size — transparently to every consumer. Block picking is DDA
grid-walk on the data layer, never a physics collider.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0014: Chunked Voxel Rendering & Large-World Storage | 16×16 chunk `ArrayMesh` face-culled mesher; **faces wind CW, backface culling ENABLED** (4.7 front-face is clockwise); view-window streaming with per-frame build+unload budgets; ghosts = pooled `MeshInstance3D`; DDA picking on the data layer | HIGH |
| ADR-0015: Large-World Storage & Residency (16k) | Paged region-file residency (supersedes ADR-0014's full-world-at-boot clause); resident set = camera-near ∪ settlement chunks; time-based page/evict budgets; read-through in-flight-write cache; region I/O + terrain-gen on a capped `WorkerThreadPool`, never synchronous on the frame — **Accepted, spike-validated 2026-07-23** | HIGH |
| ADR-0004: Physics Backend & Picking Strategy | Block picking = manual DDA grid-walk driven by `get_world_ray()`; zero physics colliders on blocks | HIGH |
| ADR-0012: Save/Load Serialization Strategy | Voxel save format IS ADR-0015's region files (chunked by construction); occupied cells only via `iterate_occupied()` — **VS-tier for the save orchestrator** | MEDIUM |
| ADR-0002 / ADR-0001 | Terrain/streaming tunables from typed `.tres` config; injected-tier module | MEDIUM |

Engine-risk basis (4.7 policy): **HIGH** — the rendering domain is the top
flagged knowledge gap. LLM instinct is wrong on multiple post-cutoff facts that
this epic depends on: Godot 4.7 front-face winding is **clockwise** (the slice's
multi-session "missing faces" root cause), `WorkerThreadPool.wait_for_task_completion()`
returns an Error code (not the Callable's return value — a spike bug), and
`GridMap` is measurably non-viable at scale. Every mesher/residency API must be
cross-referenced against `docs/engine-reference/godot/` and audited against the
engine's actual convention, never a self-stored assumption.

## GDD Requirements

38 TRs registered (`TR-voxel-world-*`). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-voxel-world-025 | Rendering representation (chunked mesher, not GridMap) | ADR-0014 ✅ |
| TR-voxel-world-052 | CW winding + backface culling ENABLED per engine convention | ADR-0014 ✅ (slice propagation) |
| TR-voxel-world-017 / -018 | DDA cell-picking mechanism, no colliders | ADR-0004 / ADR-0014 ✅ |
| TR-voxel-world-051 | Load-before-write for far-world (non-resident) mutations | ADR-0015 ✅ |
| TR-voxel-world-021 | Serialize occupied cells only; region-file format | ADR-0012 / ADR-0015 ✅ |
| TR-voxel-world-023 | Terrain/streaming tunables from config | ADR-0002 ✅ |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; remaining TRs
are GDD-specified. No untraced requirements.

**At-risk / deferred**: `duplicate_deep()` / typed `Dictionary[Vector3i,...]`
syntax (4.4+) are MEDIUM-risk API-verification items, not open decisions. The
save-orchestrator half of ADR-0012 is VS-tier; M01 builds the region-file storage
format and residency, not the full save/load flow.

## Milestone 01 Notes — HOME OF TWO TECH DEBTS

- **TECH DEBT 1 — Mesher CW-winding rewrite lands here.** The slice shipped on
  CCW + `CULL_DISABLED` (a documented, now-EXPIRED 2× overdraw mitigation). This
  epic rewrites faces to wind CW with backface culling RE-ENABLED (TR-voxel-world-052),
  audited against the engine's actual convention, with no missing-face regressions.
  Milestone-01 Must-Ship "Mesher CW-winding rewrite + culling re-enable"
  (nominal owner `godot-shader-specialist`); architecturally it is Voxel World's
  mesher. Do it early, before asset scale-up (milestone risk register).
- **TECH DEBT 3 — ADR-0015 C1/C4 residency tuning lands here.** The two carried
  tuning items are implemented as stories with **measured** values (not open
  decisions), recorded as config changes with rationale (using the Foundation
  Spine `.tres` + rationale pattern). Milestone-01 Must-Ship "ADR-0015 C1/C4
  residency tuning."
- Performance gate: 60 FPS on the production window with culling RE-ENABLED
  (headroom expected — slice held 60 FPS at 2× faces on `CULL_DISABLED`).

## Milestone 02 Notes — two stories added 2026-07-26 (TD Addendum D)

Both stories are downstream actions of `production/architecture-decisions-m02-preflight-2026-07-26.md`
**Addendum D** (technical-director, **PROVISIONAL pending user ratification**). Both are scheduled into
**Sprint 9**, on the `godot-gdscript-specialist` lane, and **must be serialized in this order** — they edit
the same file (`voxel_world_mesh_streamer.gd`):

- **`vox-020` (D7) — mesh invalidation.** Corrects a **false premise** that had propagated into
  `sprint-09.md` D7 and `scene-005`'s Guardrail: the mesher *does* subscribe to `cell_changed` /
  `cells_changed_batch` (`voxel_world_mesher.gd:163`), so the streamer subscribing to nothing is correct
  layering, not a bug. The two **real** defects: the rebuild is unbudgeted and synchronous inside the signal
  handler (~69 ms for a 9-chunk edit at 7.7 ms/chunk), and residency page-in emits no signal, so an
  early-meshed chunk never re-meshes. Fixed by dirty-marking + a rebuild phase **drained first** inside the
  **existing** `mesh_build_budget_ms` (no new knob — a separate budget would permit 7.7 + 7.7 ms in one
  16.6 ms frame and regress vox-019's p95 of 16.947 ms) + a new `chunk_became_resident` grid signal.
  Sequences **before `scene-005`**, parallel-safe with `building-023`.
- **`vox-021` (D2) — boot/steady-state radius.** `view_radius_chunks` **24 → 12** (`.tres`) plus a new
  `boot_mesh_radius_chunks = 8` consumed only by `build_initial_window`; growth to full via the existing
  budgeted `update_view_window`. Boot ceiling **3.0 s total / ≤ 2.5 s mesh phase** (technical-director,
  replacing the producer's provisional 5 s). ⚑ **Flagged to the user:** the visible extent halves,
  384 → 192 world units — a look-and-feel call with two named alternatives (accept longer fill-in, or fund
  greedy meshing — ADR-0014 §2's reserve — sooner). Sequences **after `vox-020`, before `scene-005`**.

Pending ADR amendments (technical-director-owned, not blockers on either story): **ADR-0014** gains the
dirty-set/budgeted-drain contract (§2), the rebuild-phase ordering + shared-window rule and the
boot-scoped initial radius (§3); **ADR-0015** gains the `chunk_became_resident` residency signal.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/voxel-world.md` are verified
- The CW-winding rewrite passes with culling re-enabled and no missing-face regressions
- ADR-0015 C1/C4 values are measured and recorded as config changes with rationale
- Logic/Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories voxel-world` to break this epic into implementable stories.
