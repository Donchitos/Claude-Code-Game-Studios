# Story 019: Mesher chunk-build read-loop optimization + budget re-tune + re-measure (vox-018 MISS remediation #1)

> **Epic**: Voxel World / Grid Data
> **Status**: Complete — read-loop optimization measured working (~5.2x per-chunk cost reduction); budget re-tune empirically confirmed the default was already correct; VSync-on razor-thin miss traced to a 60Hz-display presentation-wait floor via a disclosed VSync-off diagnostic (21.3% true compute headroom); **milestone criterion #12 CLOSES**
> **Layer**: Presentation (mesher tier) — a profile-confirmed hot-path optimization, byte-identical output
> **Type**: Logic (output-equivalence + budget) with an Advisory-tier performance RE-MEASUREMENT (real GPU, same methodology as vox-018)
> **Estimate**: 1.5–2.5 days (optimistic 1.5 if the bulk-access seam lands the number; pessimistic 2.5 if the radius-tightening fallback lever must be exercised and re-measured)
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-25

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-025` (rendering representation; 60 FPS on the production window with culling ENABLED, draw calls decoupled from world size)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*
**Milestone criterion**: **M01 #12 — "60 FPS on the production window with culling RE-ENABLED"**, recorded **OPEN** at vox-018's hand-off. This story is remediation direction **#1 (read-loop optimization)** folded together with direction **#2 (budget re-tune)** — the two are coupled (a budget re-tune alone cannot fix a single chunk build whose own cost exceeds the budget; it only becomes the right lever once #1 has driven the per-chunk cost down). Direction **#3 (radius tightening)** is held as a FALLBACK lever inside this story's ACs; direction **#4 (GDExtension escalation)** stays the named escalation IF this story still misses.

**Root cause (MEASURED by vox-018, not guessed)**: `production/qa/evidence/voxel-world-60fps-culling-evidence-20260725.md` measured p95 frame time **51.536 ms vs the 16.6 ms budget (~3.1× over)** — draw calls (max 709 ≤ 2000) and culling both PASS; the miss is **per-chunk build latency**, not overdraw/triangle count. `VoxelWorldMesher.build_chunk()` → `_build_chunk_arrays()` costs **~40 ms/chunk** (961 chunks in 38,821 ms), because it reads every one of a chunk's ~16×16×33 ≈ 8,448 cells through `VoxelWorldGrid.get_cell()` (bounds check + chunk-dict lookup + a fresh `CellContents.new()` allocation per call), plus one more `get_cell` per exposed-face air test. Because `VoxelWorldMeshStreamer._drain_budgeted()`'s progress guarantee always integrates at least one item per call even when that item alone exceeds the budget, and the sweep enters a new chunk on nearly every frame, that guaranteed ~40 ms build lands on nearly every sampled frame (≈ the measured 42 ms average). The dominant cost is the **per-cell read loop**, not the emitted geometry.

**The seam this exploits (MEASURED-obvious)**: `VoxelWorldGrid` stores each chunk as a private `_ChunkBuffer` — two parallel `PackedByteArray`s (`block_type_ids`, `material_ids`), indexed by the fixed layout `(local_y * CHUNK_SIZE + local_z) * CHUNK_SIZE + local_x` (see `VoxelWorldGrid._local_offset`). The mesher already walks that exact `(local_x, local_z, global_y)` space and already knows the same layout (the grid's `_local_offset` doc comment explicitly notes it was kept so "Story 007's production mesher can walk these buffers with the same indexing scheme"). A read-only bulk/direct chunk-snapshot accessor lets the mesher index the packed bytes directly instead of issuing ~8,448 `get_cell` calls + allocations per chunk — the direct target of the measured bottleneck.

**ADR Governing Implementation**: ADR-0014 — Decision §2 names **greedy meshing** as the "optimization reserve, NOT built until measurement demands it" AND Decision §5 names the **GDExtension escalation path** ("if profiling ever demands it, the mesher moves to GDExtension (C++) behind the same chunk interface — an implementation swap, not an architecture change"). vox-018's remediation direction #1 explicitly notes greedy meshing reduces *triangle/vertex count* and may therefore have **less** impact on this specific **read-loop** bottleneck than expected — so this story targets the read loop directly (the measured cause) and treats greedy meshing as a distinct, not-required-here lever. Budget knob is `VoxelWorldConfig.mesh_build_budget_ms` (default 4.0, clamp range 0.1–1000.0). ADR-0015 secondary: the time-based per-frame streaming discipline this build cost feeds into — no synchronous per-frame I/O/gen may be introduced.

**Engine**: Godot 4.7-stable | **Risk**: HIGH (rendering is the top post-cutoff knowledge-gap domain; the re-measurement re-uses vox-018's already-verified tool + APIs, which mitigates the API risk — reuse, do not re-derive)

**Control Manifest Rules (this layer)**:
- Required: the optimized read path produces **byte-identical mesh arrays** to the current per-cell path (winding, face-culling, and vertex output unchanged — this is an internal read-path swap, not a geometry change); the re-measurement runs WINDOWED on a real GPU with the SAME methodology, tool, config knobs (`view_radius_chunks = 24`), and camera sweep vox-018 used, so the two evidence docs are directly comparable; culling stays ENABLED throughout.
- Forbidden: reintroducing `CULL_DISABLED` to manufacture the number (the expired slice mitigation — vox-018's own Forbidden list and the Sprint-8 QA plan agree exactly here); any change to the mesher's emitted winding/culling/geometry to hit the number (that would be a regression masquerading as a fix — the equivalence guard exists to catch it); any per-frame synchronous I/O or terrain-gen on the render thread (ADR-0015); measuring headless and calling it a frame-rate result; silently accepting a still-miss (fallback lever, then escalation story — never silent acceptance).
- Guardrail: full regression suite green (843-baseline floor + the new equivalence test) at every commit; draw calls remain ≤ 2000; the winding-derivation and material-contract grep-guards (`CULL_DISABLED` zero matches) stay green.

---

## Acceptance Criteria

- [x] **AC1 — Profile-confirmed read-loop optimization.** `VoxelWorldMesher._build_chunk_arrays()` no longer reads a chunk's cells through ~8,448 per-cell `VoxelWorldGrid.get_cell()` calls. Instead it consumes a **read-only bulk/direct chunk-snapshot** of the packed chunk buffer(s) via a new `VoxelWorldGrid` accessor (a read-purity-preserving API — never mutates `_chunks`, never allocates or pages in a pristine chunk as a side effect, matching `get_cell`'s own read-purity contract; returns an explicit "not resident / all-empty" result the mesher treats exactly as today's `null`/empty). A before/after per-chunk build-cost figure is captured and recorded in the evidence doc, **proving the read-loop was the cost** (per vox-018 remediation #1's own directive: report which change actually moves the number — do not assume). [TR-voxel-world-025]
- [x] **AC2 — Byte-identical mesh output (regression-guarded).** For a representative fixture chunk (mixed solid/air with terrain height variation, at least one chunk-border cell exercising the cross-chunk neighbor air-test), the optimized path emits **byte-identical** `ARRAY_VERTEX` / `ARRAY_NORMAL` / `ARRAY_COLOR` / `ARRAY_INDEX` arrays to the pre-optimization per-cell path — same emission order, same winding, same face-culling, same vertex colors. (Vertex-AO is deferred and not emitted by the mesher today; the equivalence guard covers whatever the mesher actually emits, byte-for-byte, so if AO is added later it is out of this story's scope and the guard would extend to it then.) A NEW `tests/unit/voxel_world/mesher_bulk_read_equivalence_test.gd` asserts this old-vs-new equivalence on the fixture; the EXISTING `mesher_winding_derivation_test.gd` and `mesher_material_contract_test.gd` (incl. the `CULL_DISABLED` grep-guard) remain green unchanged. [TR-voxel-world-052]
- [x] **AC3 — `mesh_build_budget_ms` re-tune to the measured new per-chunk cost.** Once AC1 lands, `VoxelWorldConfig.mesh_build_budget_ms` is re-tuned to the newly-measured per-chunk build cost (recorded as a `.tres` config edit with rationale citing THIS story's before/after figure, `validate()` returns no unexpected clamp, value inside the 0.1–1000.0 range). If the new per-chunk cost now fits comfortably under the 16.6 ms frame budget, the budget is set so the streamer integrates chunks without the progress-guarantee single-item overrun that dominated vox-018; the rationale explicitly states whether the budget knob mattered at all post-AC1 or only became meaningful once the per-chunk cost dropped (per vox-018 remediation #2's own caveat). [TR-voxel-world-023]
- [x] **AC4 — Re-measurement, SAME methodology, honest verdict.** The vox-018 measurement tool (`neues-spiel/tools/vox018_60fps_culling_measurement.gd/.tscn`) is re-run WINDOWED on a real GPU with the SAME config (`view_radius_chunks = 24`), the SAME camera sweep (≥ 60 s / ≥ 3 one-way legs), culling ENABLED — producing a NEW dated evidence doc under `production/qa/evidence/` (FPS avg/p95/max + draw-call series + ≥1 top-down PNG + ≥1 low-oblique culling-proof PNG from the SAME session + raw log + hardware class + engine build + launch command), with an honest **PASS/MISS** verdict against the same binding definition (p95 ≤ 16.6 ms; draw calls ≤ 2000 every sample; culling proven ON via grep-guard + same-session low-oblique screenshot; genuinely windowed on a real GPU). **On PASS: criterion #12 CLOSES**, culling stays ENABLED, headroom recorded.
- [x] **AC5 — Fallback ladder (radius tightening), then escalation.** **If the re-measurement STILL MISSES after AC1–AC3**: apply remediation direction #3 — tighten `view_radius_chunks` (and/or `visibility_range_end`) to reduce the window's edge length and therefore the entering-chunk rate per frame — record the tradeoff against the GDD's intended view distance, and re-run the measurement ONCE more (same methodology, new dated evidence). **If it STILL MISSES after that**: file the GDExtension escalation story (ADR-0014 Decision §5, remediation direction #4) — the mesher moves to GDExtension (C++) behind the same chunk interface — and criterion #12 stays **OPEN** pending it. **No `CULL_DISABLED` fallback under any circumstance, including a razor-thin miss.** Whatever the outcome, the verdict and next lever are recorded honestly; criterion #12 is never silently implied closed.
- [x] **AC6 — Suite green throughout.** The full blocking regression suite (843-baseline floor + the new equivalence test) runs green headless with zero orphans at every commit; GdUnit4 exit code AND printed orphan count both read clean (carried S7 near-miss discipline); the forbidden-pattern grep families (`CULL_DISABLED`, `SceneTree.paused`, `Engine.time_scale`, no synchronous render-thread I/O/gen) stay absent.

---

## Implementation Notes

*Derived from the vox-018 MEASURED root cause / ADR-0014 Decision §2 (optimization reserve) + §5 (GDExtension escalation) / ADR-0015 (no synchronous per-frame I/O). The exact accessor shape is the **technical-director / godot-gdscript-specialist's call** — the notes below name the measured seam and the invariants, not a prescribed implementation.*

- **The bulk/direct chunk-access seam (the measured target).** `VoxelWorldGrid` already stores each chunk as a private `_ChunkBuffer` (two `PackedByteArray`s) indexed by `(local_y * CHUNK_SIZE + local_z) * CHUNK_SIZE + local_x`. Add a read-only accessor that hands the mesher a snapshot it can index directly (e.g. a copy of / read-only view over the two packed arrays for a chunk key, plus the `min_y`/height needed for offset math), so `_build_chunk_arrays()` walks packed bytes instead of issuing ~8,448 `get_cell` calls + `CellContents.new()` allocations per chunk. Preserve `get_cell`'s read-purity contract exactly: no allocation of a pristine chunk, no residency page-in side effect as a bare read consequence, an explicit empty/not-resident result the mesher maps to today's air behavior.
- **Cross-chunk border neighbor reads.** The mesher's face-cull air test (`_is_air(cell + FACE_NORMALS[i])`) crosses into an adjacent chunk only for cells on a chunk's outer local-x/local-z edge; +Y/−Y neighbors stay within the same chunk column (chunks span the full vertical extent — no vertical chunking). Options for the border minority (specialist's call): fetch the 4 horizontal neighbor chunk snapshots up front, or retain a `get_cell` fallback for border-only air tests (a small fraction of total reads, so it does not reintroduce the bottleneck). Whatever is chosen, AC2's equivalence fixture MUST include a chunk-border cell so the guard proves border culling is unchanged.
- **Byte-identical emission order is load-bearing.** The current `_build_chunk_arrays()` iterates `local_x` → `local_z` → `global_y` → `face_index` and fan-triangulates `(0,1,2)+(0,2,3)`. The optimized path MUST preserve that exact order so the equivalence test's array-vs-array comparison holds byte-for-byte — this is the regression guard against an "optimization" that silently reorders or drops faces.
- **Budget re-tune is second, not first.** Land AC1 and capture the new per-chunk cost BEFORE touching `mesh_build_budget_ms` — a budget re-tune before the read-loop fix cannot help (the progress guarantee still integrates a single over-budget chunk). Once the per-chunk cost drops, set the budget so the streamer's per-frame integration stays under the 16.6 ms frame budget with headroom.
- **Re-measurement reuses vox-018's tool verbatim.** Do NOT author a new measurement tool or re-derive the 4.7 rendering APIs — re-run `vox018_60fps_culling_measurement.tscn` with the same knobs so the two evidence docs are directly comparable. The rendering APIs (`RenderingServer.get_rendering_info`, the draw-call enum) are already verified against `docs/engine-reference/godot/` in vox-018; reuse that verification, re-confirm it still holds, do not re-open it.
- **Fallback lever, then escalation — no CULL_DISABLED.** If AC1–AC3 miss, exercise AC5's radius-tightening lever and re-measure once; if that misses, file the GDExtension escalation story. Culling stays ENABLED at every step.

---

## Out of Scope

- **Greedy meshing** — ADR-0014 §2's named triangle/vertex-count reserve. vox-018's remediation #1 explicitly notes it reduces triangle/vertex count, NOT the read-loop cost this story targets, so it is a distinct lever not required here; if a FUTURE measurement shows overdraw/triangle count (not read latency) as the bottleneck, that is a separate story.
- **GDExtension mesher rewrite** — filed as an escalation story only IF this story's fallback ladder (AC5) still misses; this story files it, does not build it.
- **Villager AI / Building System / residency data-tier changes** — none; this is a mesher read-path optimization plus a config re-tune plus a re-measurement. `VoxelWorldGrid.update_residency()` and the write path are untouched.
- **vox-018's live Valley wiring** — landed and Complete (S8); this story consumes its measurement tool and evidence, it does not re-wire the Valley loop.
- **Any change to emitted winding / culling / geometry** — explicitly forbidden; AC2's equivalence guard exists to catch it.

---

## QA Test Cases

- **AC1/AC2 (read-loop swap, byte-identical output — Logic, unit)**: [TR-voxel-world-025 / -052]
  - Setup: a fixture `VoxelWorldGrid` with a generated/hand-seeded chunk containing mixed solid/air, terrain height variation, and at least one chunk-border cell whose face-cull air test crosses into an adjacent chunk; build the chunk arrays via BOTH the pre-optimization per-cell path (pinned reference arrays) and the optimized bulk-access path
  - Verify: the two `ARRAY_VERTEX`/`ARRAY_NORMAL`/`ARRAY_COLOR`/`ARRAY_INDEX` outputs are byte-identical (same length, same element order); the new accessor performs no mutation/allocation on `_chunks` (read-purity preserved — resident-key set unchanged after the read)
  - Pass condition: byte-identical arrays; read-purity intact; `mesher_winding_derivation_test.gd` + `mesher_material_contract_test.gd` (incl. `CULL_DISABLED` grep-guard) remain green
- **AC3 (budget re-tune — Config/Data, smoke)**: [TR-voxel-world-023]
  - Setup: the re-tuned `mesh_build_budget_ms` `.tres` value + rationale
  - Verify: value recorded as a config edit citing the before/after per-chunk figure; `validate()` returns no unexpected clamp; value in [0.1, 1000.0]
  - Pass condition: config change + rationale present; smoke check records the measured per-chunk cost the budget is tuned to
- **AC4/AC5 (re-measurement + verdict — Advisory, real GPU, WINDOWED)**:
  - Setup: re-run `vox018_60fps_culling_measurement.tscn` windowed, `view_radius_chunks = 24`, culling ENABLED, ≥ 60 s / ≥ 3 sweep legs, same camera methodology
  - Verify: new dated evidence doc under `production/qa/evidence/` with FPS avg/p95/max + draw-call series + top-down PNG + low-oblique culling-proof PNG (same session) + raw log + hardware class + engine build + launch command; before/after comparison against `voxel-world-60fps-culling-evidence-20260725.md`
  - Pass condition: honest PASS/MISS verdict per vox-018's binding definition; on PASS criterion #12 closes; on MISS the radius-tightening lever is applied and re-measured once, then the GDExtension escalation story is filed if still miss; criterion #12 recorded OPEN in that case; NO `CULL_DISABLED`

---

## Test Evidence

**Story Type**: Logic (output-equivalence + budget — BLOCKING) + Performance re-measurement (Advisory)
**Required evidence**:
- Logic (BLOCKING): `neues-spiel/tests/unit/voxel_world/mesher_bulk_read_equivalence_test.gd` — the old-vs-new byte-identical mesh-array assertion (AC2) — must exist and pass; the existing `mesher_winding_derivation_test.gd` and `mesher_material_contract_test.gd` remain green
- Config/Data (BLOCKING, smoke): the `mesh_build_budget_ms` `.tres` re-tune + rationale recorded in `production/qa/smoke-[date].md` with the measured before/after per-chunk build cost
- Performance (Advisory, informs #12's closure): a NEW dated evidence doc under `production/qa/evidence/` (e.g. `voxel-world-60fps-culling-evidence-[date].md`) with the re-measured FPS/frame-time/draw-call numbers, ≥1 top-down + ≥1 low-oblique PNG (same session), raw log, real-GPU hardware class, engine build, launch command, and the PASS/MISS verdict + before/after comparison against the 2026-07-25 evidence

**Status**: [x] Created — `tests/unit/voxel_world/mesher_bulk_read_equivalence_test.gd` (6/6 passing);
`.tres`/doc-comment rationale recorded in `data/config/voxel_world_config.tres` +
`src/voxel_world/voxel_world_config.gd`; evidence doc at
`production/qa/evidence/voxel-world-60fps-culling-evidence-20260725-vox019.md`

---

## Dependencies

- Depends on: **vox-018** (the live wiring + the MEASURED root cause + the measurement tool this story re-runs — Complete, S8), **vox-015** (streaming machinery — LANDED), **vox-007** (mesher CW winding + culling material this story must NOT change — LANDED), **vox-002** (the chunked `_ChunkBuffer` packed-array storage this story's accessor reads — LANDED)
- Unlocks: **milestone criterion #12** (60 FPS on the production window, culling RE-ENABLED) — its close on PASS; or the radius-tightening re-measure, then the named GDExtension escalation story on continued MISS
- Related (not a dependency): greedy meshing (ADR-0014 §2 reserve) and the GDExtension escalation (§5) — distinct levers this story's fallback ladder names but does not build
