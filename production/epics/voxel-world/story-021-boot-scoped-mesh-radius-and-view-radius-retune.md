# Story 021: Boot-scoped mesh radius + `view_radius_chunks` 24 → 12 retune (TD ruling D2)

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-26 — boot 2.44-2.52s vs the 3.0s ceiling, PASS; story scope 208/208 green; parent re-verifies the full gate once bv-004 lands)
> **Layer**: Presentation (mesher/streamer tier) + Config/Data (`.tres`)
> **Type**: Integration (boot-phase radius threading) + Config/Data (retune) + one Advisory measurement
> **Estimate**: **S–M** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*
> **Lane**: `godot-gdscript-specialist`
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**Source ruling**: `production/architecture-decisions-m02-preflight-2026-07-26.md` **Addendum D — D2**
(technical-director, **PROVISIONAL pending user ratification**). This story is downstream action #19 of
that addendum, and it closes `scene-005` Open Decisions **#1** (no boot budget exists) and **#2**
(boot-scoped mesh radius shape).

**The verdict, stated plainly: the radius is not the whole problem —
`view_radius_chunks = 24` is unaffordable at boot AND in steady state.**

Arithmetic at the measured **7.7 ms/chunk** (vox-019), `CHUNK_SIZE` 16, `CELL_SIZE` 1.0:

| Radius | Chunks | Mesh cost | Visible extent |
|---|---|---|---|
| 24 (current) | 49×49 = 2401 | **18.5 s** | 384 u |
| 12 | 25×25 = 625 | 4.8 s | **192 u** |
| 8 | 17×17 = 289 | **2.2 s** | 128 u |

**The decisive point `scene-005`'s lever list does not state: shrinking only the boot radius moves the
cost, it does not remove it.** `_collect_window` uses `view_radius_chunks`, so `update_view_window` grows
the window back to full at ~1 chunk/frame (7.7 ms/chunk exceeds the 4.0 ms `mesh_build_budget_ms`, so
`_drain_budgeted`'s progress guarantee yields exactly one). Booting at radius 8 while `view_radius_chunks`
stays 24 trades an 18.5 s freeze for **~35 s of visible pop-in** — strictly worse for playability. Both
knobs move, or neither is worth moving.

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-026` (terrain/mesh available before the first visible scene — **and its
"~2.6 s initial view-window mesh build" parenthetical is a confirmed-stale ADR-0014 prototype figure**,
corrected by this story's evidence to ~2.2 s at `boot_mesh_radius_chunks = 8`, with the 18.5 s figure
noted as applying to the now-superseded radius 24), `TR-voxel-world-023` (streaming tunables from config),
`TR-voxel-world-025` (60 FPS on the production window with culling ENABLED)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0014** (Chunked Voxel Rendering — the pending amendment's
boot-scoped initial radius clause, §3); **ADR-0005** (Boot Sequencing) — **holds unchanged**:
`build_initial_window` still runs inside WIRING, strictly before `ACTIVE`, only with a smaller radius;
**ADR-0002** (typed `.tres` config with validated ranges and a two-tier warn/BLOCKING discipline).

**Engine**: Godot 4.7-stable | **Risk**: LOW-MEDIUM — no new engine API; one new `@export int`, one `.tres`
value, one parameter threaded into an existing private method. The measurement half carries the usual
real-GPU/windowed methodology risk, mitigated by reusing vox-018/vox-019's tool and methodology verbatim.

**Control Manifest Rules (this layer):**
- **Required**: every radius comes from config (ADR-0002) — **no literal radii in code**;
  `boot_mesh_radius_chunks` is consumed at exactly **one** call site; `visibility_range_end` stays derived
  from `view_radius_chunks` so the distance fade remains consistent automatically; the measurement runs
  **WINDOWED on a real GPU with VSync OFF** (S8 finding: VSync floors frame-time measurement at 16.67 ms),
  phase-split, to `production/qa/evidence/`.
- **Forbidden**: a second code path, a timer, a camera-move trigger, or any new state to grow the window
  (growth is the **existing** budgeted `update_view_window` and nothing else); a boot-scoped radius
  **larger** than `view_radius_chunks`; manufacturing the boot number by shrinking the world extent;
  measuring headless and calling it a boot-time result; `CULL_DISABLED`; any synchronous per-frame I/O or
  generation.
- **Guardrail**: full blocking suite green with zero orphans at every commit; draw calls remain ≤ 2000;
  the mesher's emitted geometry is untouched (vox-007/vox-019 guards green, unchanged).

---

## Acceptance Criteria

- [ ] **AC-VIEW-RADIUS-RETUNE** — `VoxelWorldConfig.view_radius_chunks` **24 → 12**, as a pure `.tres` data
      change (`neues-spiel/data/config/voxel_world_config.tres`), with the rationale recorded in the
      `@export`'s doc comment in the established Foundation-Spine pattern: *at the measured 7.7 ms/chunk,
      radius 24 = 2401 chunks = 18.5 s of meshing and a window `update_view_window` can never maintain;
      radius 12 = 625 chunks = 4.8 s.* `validate()` returns **no unexpected clamp** (12 is inside
      `VIEW_RADIUS_CHUNKS_MIN` 2 / `MAX` 64). **This is the knob that makes the steady-state window
      actually maintainable at the current mesher cost** — instantly reversible, no code.
      [TR-voxel-world-023]
- [ ] **AC-BOOT-RADIUS-KNOB** — New `@export var boot_mesh_radius_chunks: int = 8` on `VoxelWorldConfig`,
      validated in `validate()` against **new** `BOOT_MESH_RADIUS_CHUNKS_MIN = 2` /
      `BOOT_MESH_RADIUS_CHUNKS_MAX = VIEW_RADIUS_CHUNKS_MAX`, **plus a clamp+warn (non-BLOCKING, ADR-0002
      two-tier) when it exceeds `view_radius_chunks`** — a boot window larger than the steady-state window
      is a configuration error that must not halt boot but must not be silently honoured either. Asserted
      by test at all four boundaries (below MIN, above MAX, above `view_radius_chunks`, in range).
      [TR-voxel-world-023, ADR-0002]
- [ ] **AC-BOOT-ONLY-CONSUMER** — `boot_mesh_radius_chunks` is consumed **only** by `build_initial_window`,
      threaded as a **radius parameter into the existing `_collect_window`** — **no new state, no timer, no
      camera-move trigger, no second code path**. Grep-guarded by test: exactly one read of
      `boot_mesh_radius_chunks` in `neues-spiel/src/` outside its own declaration/doc comment, and it is
      inside `build_initial_window`'s call graph. `_collect_window`'s existing bounds filtering
      (`_is_chunk_in_world`) is unchanged and applies identically at the smaller radius.
- [ ] **AC-STEADY-STATE-UNCHANGED** — `update_view_window` (and `get_desired_window_keys`) continue to use
      **`view_radius_chunks`**, unchanged. Growth from the boot window to the full window happens **over
      frames via the already-budgeted `update_view_window`, with no new mechanism**: 289 → 625 = **336
      chunks at ~1 chunk/frame ≈ 5.6 s of gradual fill, during which the player is already interactive** —
      the correct place to spend it, rather than in a frozen boot window. Asserted: after
      `build_initial_window`, the desired-window key count equals the radius-8 window; after enough
      `update_view_window` calls, it equals the radius-12 window; the streamer's per-call meshing count
      never exceeds the shared `mesh_build_budget_ms` progress guarantee.
- [ ] **AC-VISIBILITY-RANGE-DERIVED** — `visibility_range_end` remains **derived** from
      `view_radius_chunks` via the existing
      `VoxelWorldMeshStreamer.compute_visibility_range_end(view_radius_chunks)` — so the distance fade
      stays consistent automatically with no second edit. Asserted:
      `compute_visibility_range_end(12) == 192.0` (12 × 16 × 1.0) and no literal fade distance exists
      anywhere in `src/`.
- [ ] **AC-ADR-0005-ORDER-HOLDS** — `build_initial_window` still runs **inside WIRING, exactly once,
      strictly before `BootState.ACTIVE`** (ADR-0005 unchanged), and **no synchronous I/O and no unbounded
      per-frame work is introduced** — the growth path is the existing budgeted step, not a boot-time loop.
      Proven by the existing boot-ordering assertions staying green plus one added assertion that the
      initial window's key count equals the **boot** radius, not the steady-state radius.
- [ ] **AC-BOOT-BUDGET-3S (Advisory, measured, time-boxed)** — A **windowed** run on a real GPU with
      **VSync OFF**, at the shipped 2000×2000 config, records **boot-to-ACTIVE wall clock split into its
      phases** (residency page-in / nav-graph build / initial mesh window / roster spawn) into a dated
      evidence doc under `production/qa/evidence/`, on the vox-018/vox-019 tool precedent (hardware class,
      engine build and launch command stated verbatim; raw log attached). **Verdict against the
      technical-director's ceiling: total boot-to-ACTIVE ≤ 3.0 s, of which the initial mesh phase
      ≤ 2.5 s.** *Rationale for the ceiling, recorded in the evidence doc:* this codebase has **no boot
      loading overlay** (`game_world.gd`'s own honest note), so boot is a **frozen window**, and ~3 s is
      the threshold above which a frozen window reads as a hang. **Projected mesh phase under this ruling:
      ~2.2 s — PASS with headroom.** On MISS: record the honest verdict, apply **one** named lever
      (`boot_mesh_radius_chunks` 8 → 6 = 13×13 = 169 chunks ≈ 1.3 s), re-measure **once**, then escalate to
      technical-director. **Never manufacture the number by shrinking the world extent, and never disable
      culling.**
- [ ] **AC-EXTENT-EVIDENCE (Advisory)** — The same session captures **≥1 screenshot at the new
      `view_radius_chunks = 12` from the settlement camera distance**, so the user can make the
      look-and-feel call named in Open Decisions below on a picture rather than on a number. The evidence
      doc states the visible-extent change explicitly: **384 → 192 world units, a halving.**
- [ ] **AC-SUITE-GREEN** — Full blocking regression suite green headless with **zero orphans** at every
      commit (GdUnit4 exit code AND printed orphan count both clean). Any pre-existing test that hardcodes
      radius 24 is updated to read the config value rather than the literal — **and that edit is named in
      the commit body**, because a config retune must not be absorbed silently into a test constant.

---

## Implementation Notes

*Derived from Addendum D / D2 §§1–5. The ruling names the knobs and the growth mechanism; these notes name
the seams.*

- **Two edits, one parameter.** (1) `.tres` + doc comment for `view_radius_chunks`; (2)
  `boot_mesh_radius_chunks` `@export` + its two range constants + the two `validate()` branches (range
  clamp, and the `> view_radius_chunks` warn-clamp); (3) `_collect_window(desired, center)` gains a
  `radius` parameter (or an explicit radius-taking sibling — specialist's call), with `update_view_window`
  passing `config.view_radius_chunks` and `build_initial_window` passing
  `config.boot_mesh_radius_chunks`. **That is the whole code change.** If it grows beyond this, stop — the
  ruling explicitly forbids a second code path.
- **`get_desired_window_keys` is a public surface** used by tests and by `scene-005`'s ordering assertions;
  it must keep meaning *steady-state* window. Do not overload it with the boot radius.
- **Serialize with vox-020.** Both stories edit `voxel_world_mesh_streamer.gd` (vox-020 adds the rebuild
  phase to `_sync_window`; this story threads a radius into `_collect_window`). **This story runs AFTER
  vox-020.** Doing them concurrently is a merge conflict in the sprint's most performance-sensitive file.
- **Measure last, and measure once.** The AC-BOOT-BUDGET-3S run is only meaningful once both config values
  and the parameter threading are landed. Reuse vox-018's measurement tool and methodology verbatim — do
  not author a new tool and do not re-derive the 4.7 rendering APIs (vox-018 already verified them; reuse
  that verification).
- Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01.

---

## Out of Scope

- **Greedy meshing** — ADR-0014 §2's named optimisation reserve, and the **real** lever on the 7.7 ms
  per-chunk cost that forces this radius decision in the first place. See Open Decisions: it is one of the
  two named alternatives if the halved visible extent is judged unacceptable. **Not built here.**
- **The mesh-invalidation dirty set / budgeted rebuild drain** — that is **vox-020**, which sequences
  immediately before this story.
- **`mesh_build_budget_ms`** — unchanged at 4.0, and (post-vox-020) a **shared** rebuild+build window.
  This story does not retune it.
- **`nav_region_size`** — `scene-005`'s lever (3); a `VillagerAIConfig` knob, not a voxel-world one. If the
  boot budget misses on the nav-graph phase rather than the mesh phase, that is a `scene-005` lever, not
  this story's.
- **A boot loading overlay** (`TR-scene-world-management-032`) — still absent; it is the thing that would
  make a >3 s boot acceptable, and it is a scene-world-management story that does not exist. Named, not
  built.
- **The `TR-voxel-world-026` registry correction** itself — a doc task filed by this story's evidence, not
  an edit this story makes to the registry.

---

## QA Test Cases

- **AC-VIEW-RADIUS-RETUNE (Config/Data, smoke)**: Given the shipped `.tres`, Then
  `view_radius_chunks == 12` and `validate()` reports no clamp; the doc-comment rationale cites the
  measured 7.7 ms/chunk and the 2401 vs 625 chunk counts. Record in `production/qa/smoke-[date].md`.
- **AC-BOOT-RADIUS-KNOB (Logic, unit)**: Given `boot_mesh_radius_chunks = 1`, Then clamped to 2 with a
  warning; Given 999, Then clamped to `VIEW_RADIUS_CHUNKS_MAX` with a warning; Given
  `boot_mesh_radius_chunks = 20` with `view_radius_chunks = 12`, Then clamped to 12 with a **non-BLOCKING**
  warning and boot proceeds; Given 8 with 12, Then untouched and no warning.
- **AC-BOOT-ONLY-CONSUMER (grep guard, test)**: Given `neues-spiel/src/`, When scanned for
  `boot_mesh_radius_chunks`, Then exactly one read outside the declaration, inside `build_initial_window`'s
  call graph.
- **AC-STEADY-STATE-UNCHANGED (Integration)**: Given a boot, Then the initial window key count equals the
  radius-8 window; When `update_view_window` is driven repeatedly at the same focus, Then the tracked set
  grows toward the radius-12 window and never exceeds it; Then per-call meshing count respects the budget's
  progress guarantee.
- **AC-VISIBILITY-RANGE-DERIVED (Logic, unit)**: `compute_visibility_range_end(12) == 192.0`; grep proves no
  literal fade distance in `src/`.
- **AC-ADR-0005-ORDER-HOLDS (Integration)**: Given an instrumented boot, Then `build_initial_window` is
  called exactly once, strictly before ACTIVE, with the boot radius.
- **AC-BOOT-BUDGET-3S / AC-EXTENT-EVIDENCE (Advisory, real GPU, WINDOWED, VSync OFF)**: Given a windowed
  run at the shipped 2000×2000 config, Then a dated evidence doc records phase-split boot wall clock,
  hardware class, engine build, launch command, raw log, ≥1 settlement-distance screenshot at radius 12,
  and an honest PASS/MISS against **3.0 s total / 2.5 s mesh phase**; on MISS the single named lever
  (boot radius 8 → 6) is applied, re-measured once, then escalated.

---

## Test Evidence

**Story Type**: Integration + Config/Data (BLOCKING) + one Advisory performance measurement
**Required evidence**:
- `neues-spiel/tests/integration/voxel_world/boot_mesh_radius_test.gd` — the knob validation, single-consumer
  grep guard, boot-vs-steady-state window assertions and the ADR-0005 ordering assertion — must exist and
  pass headless in the commit gate.
- Config/Data (BLOCKING, smoke): the `view_radius_chunks` 24 → 12 and `boot_mesh_radius_chunks = 8` `.tres`
  values + rationale recorded in `production/qa/smoke-[date].md`.
- Performance (Advisory): `production/qa/evidence/boot-mesh-radius-boot-budget-[date].md` — windowed, real
  GPU, **VSync OFF**, phase-split, with the 3.0 s / 2.5 s verdict and the radius-12 look-and-feel screenshot.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete/landed): **vox-015** (`build_initial_window` / `update_view_window` /
  `_collect_window` — the machinery this story parameterises), **vox-019** (the measured 7.7 ms/chunk cost
  the entire radius arithmetic rests on, and its measurement tool/methodology this story reuses),
  **vox-010→014** (residency — the page-in the smaller boot window also shrinks), **spine-003** (the typed
  `.tres` config + `validate()` two-tier pattern).
- **Blocked on**: **`vox-020` (in-sprint, HARD sequencing — not a logical dependency but a
  same-file serialization requirement: both edit `voxel_world_mesh_streamer.gd`).** Run vox-020 first.
- **Sequencing**: **AFTER `vox-020`, BEFORE `scene-005`.** `scene-005`'s AC-BOOT-BUDGET is re-pointed at
  this story's 3.0 s ceiling and this story pre-applies `scene-005`'s named lever (1) (boot-scoped mesh
  radius), so `scene-005` no longer has to discover it.
- **Unlocks**: `scene-005` AC-BOOT-BUDGET (ceiling now a technical-director decision, not a producer
  provisional); a steady-state window `update_view_window` can actually maintain at the current mesher cost.
- **Open decisions this story surfaces (producer → user)**:
  1. ⚑ **The visible extent halves: 384 → 192 world units.** This is a **look-and-feel decision, not a
     technical one**, and it is flagged for the user rather than absorbed. The technical ruling is sound —
     radius 24 is unaffordable both at boot and in steady state at the measured 7.7 ms/chunk — but *how far
     the player can see* is a felt property of a colony builder, and 192 units is half of what the shipped
     config promised. **Two named alternatives, either of which restores extent at a cost:**
     **(a) Accept longer fill-in** — keep `view_radius_chunks` higher (e.g. 16 or 20) and accept that the
     window fills in over tens of seconds of visible pop-in at ~1 chunk/frame; cheapest, ships today,
     trades a static horizon for a visibly-growing one.
     **(b) Fund greedy meshing sooner** — ADR-0014 §2's named optimisation reserve, currently unscheduled.
     It attacks the 7.7 ms/chunk cost directly, which is the actual constraint; a 2–3× reduction would make
     radius 20–24 affordable again. Cost: a new story on an already-committed sprint sequence, in the
     project's highest engine-risk domain.
     **Producer note:** the ruling's radius 12 is the right default to ship *now* (it is reversible in a
     `.tres` and it is the only option that is affordable in both phases), and the AC-EXTENT-EVIDENCE
     screenshot exists precisely so this call is made on a picture. If the answer is "192 is too close",
     (b) is the durable fix and (a) is the stopgap.
