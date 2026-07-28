# Story 005: Analysis pass lifecycle, batched trigger, snapshot & never-blocks guards

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1100/1100 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent scene-005)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-006`, `TR-build-validation-navigability-052`, `TR-build-validation-navigability-048`, `TR-build-validation-navigability-044`, `TR-build-validation-navigability-045`, `TR-build-validation-navigability-038`, `TR-build-validation-navigability-028`, `TR-build-validation-navigability-053`, `TR-build-validation-navigability-054`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (event-driven trigger; room analysis, incremental snapshot patching) for the trigger seam; ADR-0016 (Build-Project Entity Lifecycle) — **its `construction_completed`-as-analysis-trigger clause is SUPERSEDED for Build Validation only** by BV-2; ADR-0012 (Save/Load) for the not-serialized/full-re-derive rule
**ADR Decision Summary**: `VoxelWorldGrid.cells_changed_batch` is the single structural trigger — it fires only when a record actually changed, including from `_apply_pending_writes()` when a deferred write really lands, and it is a strict superset of construction completion (demolition, undo restores, future dig orders all reach the grid through `_apply_write`). `construction_completed` remains valid for consumers that care about *jobs* completing rather than *data* changing — Build Validation is not one of them. Build Validation is **not deserialized** on load: all statuses are fully re-derived (ADR-0012).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Godot signal connections are **synchronous by default** — load-bearing for Rule 10's "all emissions of one analysis pass are delivered synchronously within one frame; consumers may treat same-frame delivery as one pass." Do not add `CONNECT_DEFERRED` on the emission path.

**Control Manifest Rules (this layer)**:
- Required: injected-tier module, all wiring in `setup()`; analysis is event-driven off the batched construction signal.
- Required (ADR-0012): on load, Build Validation is NOT deserialized — full re-derive.
- Forbidden: per-frame analysis; a full snapshot rebuild per event (that silently reintroduces O(world) cost and violates Rule 7's event-scoping); blocking/reverting a placement; any call into a villager movement or behavior API.
- Guardrail: at most one analysis pass per batched trigger.

**RESOLVED — the trigger is `cells_changed_batch`, and ONLY that** (was Epic Known
Conflict 2). Technical-director ruling **BV-2**,
`production/architecture-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL,
pending user ratification** (away-mode ruling; treat as the planning assumption
until ratified).

**Ruling: Build Validation subscribes to `VoxelWorldGrid.cells_changed_batch` as
its single structural trigger. It does NOT subscribe to
`ConstructionTickLoop.construction_completed` at all.** Reasons, in the ruling's
own order:

- **Correctness (the decisive one).** `_complete_jobs()` emits
  `construction_completed` unconditionally *after* `bulk_write`, but
  `VoxelWorldGrid._apply_write()` (ADR-0015 load-before-write) **queues** a write
  whose chunk is not resident and returns `null` — the write lands later, from
  `_apply_pending_writes()`. So `construction_completed(cells)` can name cells
  whose data is **not yet in the grid**, and a pass triggered by it would analyse
  stale data and emit a wrong verdict.
- **Simplicity.** One trigger, one subscription, no dedupe. Subscribing to both
  would double-fire every construction tick.
- **Completeness.** Strict superset: demolition (`building-009`), undo restores
  and any future dig order all reach the grid through `_apply_write`. Rule 7's
  "completed OR removed" trigger pair is satisfied by **one** subscription, and
  Build Validation needs **no code change** when demolition lands.
- **Not noise.** Page-in and seed regeneration are explicitly silent
  (`_bg_regenerate_from_seed` never marks dirty and never emits); `bulk_write`
  emits exactly once per call and never emits an empty batch.

**Ordering note for the implementer**: `cells_changed_batch` fires *during*
`bulk_write`, i.e. **before** `BlueprintCell` micro-states flip to `BUILT` and
before `construction_completed`. This module reads voxel data only and mutates
nothing, so it is order-insensitive w.r.t. the other subscribers
(`VillagerNavGraph` already binds the same signal). **Do not introduce any read of
`BlueprintCell` state from Build Validation.**

**Second trigger, when it exists**: furniture placement/removal does not touch the
grid under BV-1, so Build Validation additionally subscribes to the **furniture
registry's own placed/removed signal** (`building-028`) — two orthogonal sources,
one per data layer, no overlap, no double-fire. Until then, `cells_changed_batch`
alone is complete because no furniture exists.

**Still open — recorded, no code change implied:**
- **#3 — batching is per-TICK, not per-frame.** AC19 is worded in frames; one
  `bulk_write` per tick dispatch yields one batch signal (base rate 4.0/s), which
  is coarser than per-frame and therefore satisfies the guarantee a fortiori.
  Write the AC19 test against tick dispatches. Owner: producer (recorded).

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] Analysis is **event-driven, never per-frame**: re-evaluation of the affected region runs on `VoxelWorldGrid.cells_changed_batch` — the single structural trigger, covering completion, removal, and undo restore alike (its batching bounds the event rate). Between events, all statuses are stable. [TR-006]
- [ ] **The module subscribes to `cells_changed_batch` and to nothing else structural.** A grep/wiring assertion proves **zero** `construction_completed` connections and zero `BlueprintCell` reads in this module (BV-2).
- [ ] **Deferred/paged write (BV-2's correctness case)**: **GIVEN** a `bulk_write` whose target chunk is not resident — so `_apply_write()` queues it and returns `null`, and no cell data is in the grid at emit time — **WHEN** the chunk later pages in and `_apply_pending_writes()` lands the write, **THEN** exactly one analysis pass runs **at that moment** and its verdict reflects the now-present data. A pass triggered by the earlier job-completion instant (had the module bound `construction_completed`) would have read stale data — assert that no pass ran then.
- [ ] **AC19**: **GIVEN** a batched signal covering N cells changed in one tick dispatch — spanning multiple commands and villagers, **WHEN** received, **THEN** exactly one re-analysis pass runs over the affected region(s) (assert analysis call-count = 1 per batch, never per cell or per command). [TR-052]
- [ ] **AC20**: **GIVEN** no structure-change signals, **WHEN** N frames pass, **THEN** the instrumented analysis call-count stays 0 — event-driven, never per-frame. [TR-006]
- [ ] The system keeps a **transient, never-serialized snapshot** of the previous analysis result (per-cell region classification + per-item shelter flags), used ONLY to edge-detect transitions — it is memory for eventing, never a compute cache. [TR-048]
- [ ] **Snapshot updates are incremental**: after a pass, only the entries touched by that pass's affected region (cells + items) are patched; untouched entries persist unchanged. A full snapshot rebuild happens ONLY on the load pass. [TR-006]
- [ ] All current statuses are **queryable at any time** (state + events model) — the same consumption contract Needs & Mood established. [TR-044]
- [ ] **All emissions of one analysis pass are delivered synchronously within one frame**; consumers may treat same-frame delivery as one pass — the reconciliation unit. [TR-045]
- [ ] **AC33**: **GIVEN** a full analysis pass over any configuration with mocked villager interfaces, **WHEN** the pass completes, **THEN** zero calls into villager movement/behavior APIs are observed (Rule 9's second half — never moves villagers; call-count mock, companion to AC25's never-blocks half). [TR-038]
- [ ] Nothing is serialized — a full analysis pass runs once on load and all statuses are re-derived from the world (Rule 4 / ADR-0012). [TR-028]
- [ ] MVP analyzes **built structures only** — the Building System's combined planned-occupancy view is available but unused (Rule 7).

---

## Implementation Notes

*Derived from ADR-0016/0007/0012 Implementation Guidelines:*

- Bind `VoxelWorldGrid.cells_changed_batch` in `setup()` — **the only structural subscription**. It never emits an empty batch and fires only when a record actually changed, so no empty-pass guard and no dedupe are needed. Do **not** bind `construction_completed`; per BV-2 that signal can name cells whose data has not landed yet.
- One pass = seed the affected region from the batch's cells → form regions (story 003) → verdict each (story 004) → diff against the snapshot → emit → patch the snapshot. Emissions happen **inside** the pass, synchronously.
- The snapshot is two maps: `Dictionary[Vector3i, RegionClass]` and `Dictionary[item_id, bool]`. Patch only the keys the pass touched. **A full rebuild per event is the specific defect Rule 11 calls out** — it would reintroduce O(world) cost and violate Rule 7.
- The load pass is the one full-world pass: rebuild the whole snapshot, make statuses queryable, and fire **no transition events**. The transition-silencing mechanism belongs here; the load-pass emission assertions (AC31) are story 008's.
- The queryable surface is a plain getter API (region status by cell, shelter status by item id). UIs own the presentation; this module owns state + events only.
- AC33 is a negative assertion over a mocked `VillagerAi` **held only by the test harness** — under BV-4 this module holds no villager reference at all and reaches the predicates statically via `VillagerWalkabilityRules`. Scope the mock's call-count assertion to movement/behavior methods; the predicate calls are proven separately (and statically) as > 0.
- Rule 7's per-frame batching claim is inherited from the Building System — this module adds no debounce of its own (Formulas: "warning debounce — inherited, a dependency, not a timing formula").

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006/007/008: the four signals' payloads, edge-detection semantics, and pacing.
- Story 010: the property corpus.
- **AC26 (save/load re-derive equivalence) is deferred to Vertical Slice** per `milestone-02-mvp-completion.md` Out of Scope — do not implement a save round-trip test here.

---

## QA Test Cases

- **AC19**: Given one batched signal carrying N cells from multiple commands/villagers, When received, Then the instrumented pass count is exactly 1 (never N).
- **AC20**: Given no structure-change signals across N frames, When measured, Then pass count = 0.
- **Deferred/paged write (BV-2)**: Given a `bulk_write` to a non-resident chunk, When the job completes but the write is still queued, Then pass count = 0; When the chunk pages in and `_apply_pending_writes()` lands the write, Then pass count = 1 and the verdict reflects the landed data.
- **Single subscription**: Given the wired module, When its connections are enumerated, Then `cells_changed_batch` is bound exactly once and `construction_completed` is bound zero times; a construction tick therefore produces exactly one pass, not two.
- **Page-in silence**: Given a chunk paging in via `_bg_regenerate_from_seed` with no write, When measured, Then pass count = 0 (page-in is silent by contract).
- **AC33**: Given a full pass with a mocked `VillagerAi`, When it completes, Then movement/behavior API call-count = 0 (predicate calls excluded and asserted separately as > 0, proving the predicates ARE used).
- **Incremental snapshot**: Given a pass touching a small affected region inside a large previously-analyzed world, When it completes, Then snapshot entries outside the affected region are unchanged (identity-compared) and the touched entries are patched.
- **Load pass**: Given a world load, When the initial full pass runs, Then the whole snapshot is rebuilt and all statuses are queryable.
- **Synchronous delivery**: Given a pass emitting multiple signals, When observed, Then all arrive within the same frame as the trigger, in one synchronous burst.
- Edge cases: a batch whose cells span two disjoint regions → one pass, two regions evaluated; a batch that changes nothing structurally relevant → pass runs, no transitions detected, no emissions.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/build_validation/analysis_pass_lifecycle_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (DI + config), 004 (verdict — a pass needs something to classify). **No external blocker** — the trigger-surface decision is RESOLVED by BV-2 (`cells_changed_batch`, single subscription). `building-009` (demolition) no longer needs to ship a new signal for this module's benefit, and no demolition follow-up story is required.
- Unlocks: 006, 007, 008

