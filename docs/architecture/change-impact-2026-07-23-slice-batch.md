# Design Change Impact Report — 2026-07-23 Vertical-Slice Propagation Batch

> **Date**: 2026-07-23
> **Author**: technical-director (gate: TD-CHANGE-IMPACT)
> **Verdict**: CONCERNS — five ADRs required user decisions (now resolved, see §Resolutions); one new ADR (ADR-0015) pending options analysis.
> **Sources**: `prototypes/last-seal-vertical-slice/REPORT.md`; the `(Slice revision 2026-07-23)` passages in `design/gdd/{game-concept,voxel-world,building-system,building-ui,villager-ai-behavior,resource-item-database}.md`; all 14 ADRs; `design/gdd/time-tick-system.md` (tick-rate authority).

---

## Change Summary

The vertical slice ("The Last Seal", 5 build days) validated the full build→furnish→live loop at near-production quality and grew scope on user direction. The propagated changes:

- **16k world target** (16,000×16,000×32) — storage/residency-gated; the 2000×2000×32 baseline is slice-validated at 60 FPS (ADR-0014). Naive full-world-at-boot allocation projects to ~11 GB, ~3× over the 4 GB ceiling — a storage problem, not a rendering problem (draw calls are decoupled from world size by the streamed view window).
- **2-block character scale + body-column occupancy** — villagers are 2 cells tall; the anti-stuck/seal rules treat the vertical body-column as the villager's space.
- **Floor terrain-replace + terrain dig orders** — two new terrain-removal exceptions routed through the same batched write API + `cells_removed`-class signal; floor-replace stores the original terrain cell as `restore_value` (reversible).
- **CW-winding + backface-culling hard requirement** — Godot 4.7 front faces are clockwise; the slice shipped CCW + `CULL_DISABLED` as a documented, expired mitigation (2× overdraw).
- **Build/editor mode + click routing** — a master "Bauen" toggle gates build tools; outside Build Mode a world click routes to villager-or-project Selection.
- **Draft-first persistent build projects** — release/pause/change-orders/worker demolition/plan-only undo; project entities are persistent, selectable, and serialization-relevant.
- **Ghost-anchored picking** — DDA picking treats ghost/draft cells as solid (an `extra_solid` predicate); dig-orders and water do not pick.
- **Room/roof/house tools + slice view**; **multi-cell furniture footprints** (bed = 2 cells).
- **Unstuck watchdog + seal prevention + stuck telemetry** — a deterministic teleport rescue for Traveling/Working villagers; a build-write refusal that avoids entrapment; `villager_unstuck` counters.
- **Resource costs deferred**; **furniture removal becomes job-based** (per user resolution 3).

---

## Per-ADR Assessment

| Detailed rationale for each entry is preserved below the summary table. |
|---|

### ADR-0001 — Inter-System Reference & DI Pattern — ✅ Still Valid
No new module violates tiering; project entities live inside Building System (injected-tier); the Save/Load orchestrator was already anticipated (ADR-0012). **Keep.**

### ADR-0002 — Tuning/Config Data Strategy — ✅ Still Valid
Every new constant slots into the existing per-module `Config` Resource pattern (`ghost_alpha_draft/_released`, `build_grid_opacity`, slice-view actions; `unstuck_watchdog_threshold_ticks`, `unstuck_rescue_search_radius`, `unstuck_rescue_max_radius`; Room/House footprint constants). The `ghost_alpha_released ≥ ghost_alpha_draft` ordering is a `validate()` cross-field case. **Keep.**

### ADR-0003 — Voxel World Rendering (GridMap) — ✅ Already Superseded
Superseded by ADR-0014; slice re-confirms GridMap non-viability at scale. No action.

### ADR-0004 — Physics Backend & Picking Strategy — ✅ Still Valid
Verified against the candidate flag: the ghost-anchored `extra_solid` predicate is **not** an ADR-0004 concern — it modifies the DDA block-picking predicate owned by **ADR-0014 §4**. ADR-0004 owns only the villager `Area3D` hit-test; the placement pick still issues zero physics queries, so the separation guarantee holds. The new "villager-wins-ties" Selection precedence equals this ADR's `pick_tie_epsilon` rule. **Keep.**

### ADR-0005 — Boot Sequencing & Initialization Gate — ✅ Still Valid
The RID-Ready unified gate is untouched. Its ADR-0014-derived window-build timing note is revisited by ADR-0015, not by editing this gate. **Keep.**

### ADR-0006 — Data Definition Immutability & Reference Format — ✅ Still Valid
Multi-cell furniture adds a `footprint` field; the two-type authoring/view split absorbs a new field structurally. Resource costs deferred (no cost fields yet). **Keep** — add `footprint` when the RID story lands.

### ADR-0007 — AI Pathfinding, Navigation & Room Analysis — ✅ Still Valid (reinforced)
Dig-order terrain removal routes through the same write + `cells_removed` signal, already covered by ADR-0007's incremental `AStar3D` patching on any standability-changing write. The watchdog rescue-target BFS is a new consumer of the shared `is_standable` predicate — validating the shared-predicate design. **Keep.**

### ADR-0008 — Villager AI Execution & Threading — ✅ Still Valid
The watchdog adds a cheap O(villagers) per-tick check for Traveling/Working agents; no change to the FSM or `max_deciding_per_tick` staggering. The 4.0 tick rate (resolution 1) fires more Deciding passes per second but the per-tick budget still bounds them. **Keep.**

### ADR-0009 — Deterministic Movement & Occupancy Ordering — ⚠️ Needs Review → **Updated in place**
Three impacts: (1) **body-column occupancy** — occupancy is no longer a single cell but a 2-cell column derived from the discrete `current_cell`; the tick-quantized principle is intact, the cardinality is not. (2) **Watchdog teleport** — the ADR quoted F1's "never teleport" as absolute and `current_cell` changing "only at tick-boundary arrival"; the watchdog is a sanctioned deterministic teleport (deterministic trigger tick + F2 lexicographic tie-break BFS), so determinism holds but the literal wording was falsified. (3) **Seal prevention** — a new consumer of discrete occupancy semantics. **Update in place** (done): extend occupancy to the body-column, add the teleport as a second sanctioned discrete `current_cell` mutation path, add seal-prevention as a consumer. Not a supersede.

### ADR-0010 — Cross-System UI/World Input Arbitration — ⚠️ Needs Review → **Updated in place**
Two new arbitration layers the ADR never covered: the **Build Mode master toggle** (placement vs Selection) and **any-mode Selection routing** (villager vs project). Building UI itself frames this as consistent with its existing hover-suppression gate. **Update in place** (done): add mode-gated click routing + Selection arbitration extending the hover-suppression gate. Not a supersede.

### ADR-0011 — UI Timer/Expiry Management — ✅ Still Valid
Grace/debounce/invalid-cue timers unchanged; new project-event toasts fit the centralized manager. **Keep.**

### ADR-0012 — Save/Load Serialization Strategy — ⚠️ Needs Review → **Note added, gated on ADR-0015**
16k save payload scales ~64× areally, pushing the monolithic/synchronous decision toward its own named chunking/threading escape hatches. New serialized state (`restore_value`, project entities incl. `worker_ids`/status/change orders, stuck-telemetry counters) is absorbed structurally by the "each system serializes itself" contract. VS-tier, not MVP-blocking; the chunking decision cannot finalize until ADR-0015 exists. **Note added** (done); no decision change yet.

### ADR-0013 — Multi-Scene Concurrency Model — ⚠️ Needs Review (minor) → **Note added, gated on ADR-0015**
The `100_000` dungeon offset's "50× margin" claim was vs the 2000-cell span; at 16k it is ~6×, and the float32 ULP trade-off grows. No Dungeon scene exists — not blocking. **Note added** (done); recompute folds into ADR-0015's coordinate-budget analysis.

### ADR-0014 — Chunked Voxel Rendering & Large-World Storage — ⚠️ Needs Review → **Updated in place + successor pending**
(a) The mesher never fixed triangle **winding**; TR-voxel-world-052 now requires CW winding + culling enabled (CCW+`CULL_DISABLED` is an expired mitigation). (b) The **full-world-at-boot allocation** clause breaks at 16k (~11 GB). The mesher/view-window/streaming architecture stands at the validated 2000² baseline. **Update in place** (done): add the winding/culling requirement, record the ghost-anchored `extra_solid` predicate under §4, and flag the full-world-at-boot clause as under supersession review by pending **ADR-0015 (Large-World Storage & Residency)**.

---

## Summary Table

| ADR | Status | Action |
|-----|--------|--------|
| 0001 DI Pattern | ✅ Still Valid | Keep |
| 0002 Tuning/Config | ✅ Still Valid | Keep (register new knobs) |
| 0003 Voxel Rendering (GridMap) | ✅ Already Superseded | None |
| 0004 Physics/Picking | ✅ Still Valid | Keep (`extra_solid` → ADR-0014) |
| 0005 Boot Sequencing | ✅ Still Valid | Keep |
| 0006 Data Definition | ✅ Still Valid | Keep (add `footprint`) |
| 0007 Pathfinding/Nav | ✅ Still Valid | Keep (reinforced) |
| 0008 AI Execution | ✅ Still Valid | Keep |
| **0009 Occupancy Ordering** | **⚠️ → Updated** | Body-column + teleport + seal-prevention |
| **0010 Input Arbitration** | **⚠️ → Updated** | Build Mode gate + Selection routing |
| 0011 UI Timers | ✅ Still Valid | Keep |
| **0012 Save/Load** | **⚠️ → Note added** | New serialized state; gated on ADR-0015 |
| **0013 Multi-Scene** | **⚠️ → Note added (minor)** | Offset margin vs 16k; gated on ADR-0015 |
| **0014 Chunked Rendering** | **⚠️ → Updated + successor** | CW winding/culling in place; storage → ADR-0015 |

---

## Resolutions (user decisions, 2026-07-23)

1. **Tick rate → 4.0 ticks/s adopted as authoritative.** `design/gdd/time-tick-system.md` is the single authoritative source (Formulas constant + Tuning-Knob default + `.tres` default); consuming GDDs reference the constant, not a literal. **A parallel agent owns that GDD edit — technical-director did not touch any GDD.** No ADR change (ADR-0002 fixes the mechanism, not the value; ADR-0008 schedules per-tick regardless of rate).
2. **Dedicated project-lifecycle ADR approved → ADR-0016 reserved.** Covers the persistent project/building entity model, draft/release/paused/built/demolition-queued state machine, change orders, worker-executed demolition, and plan-only undo scope. **To be authored separately — not written in this batch.**
3. **Furniture removal becomes job-based.** The prior instant-removal carve-out is being removed from `building-system.md` by the parallel agent; furniture demolition follows the same worker-executed order path as block demolition. No ADR authored here; feeds ADR-0016's scope.

### Follow-ups
- **ADR-0015 (Large-World Storage & Residency)** — **AUTHORED 2026-07-23, Status Proposed (pending storage/streaming spike).** Decision: paged/on-demand region-file residency (Candidate A) as the load-bearing mechanism, with sparse far-terrain regen (Candidate B) as a fast-follow optimization layer; Candidate C rejected (compression buys ~4–8× vs the required ~64×). Accepted only after the spike passes (5 pass criteria: page-in latency, memory ceiling under sustained travel, write-to-unloaded-chunk correctness, eviction under budget, region-file save round-trip). Supersedes only ADR-0014's full-world-at-boot clause. On Accept, unlocks ADR-0012 (chunked saves = region files), ADR-0013 (offset recompute), ADR-0005 (window-build timing). See `adr-0015-large-world-storage-residency.md`.
- **ADR-0016 (Build-Project Entity Lifecycle)** — **AUTHORED 2026-07-23, Status Accepted (prototype-validated 2026-07-22/23; commits 32edfbf, 555b4aa, b2259f4).** Persistent draft→released(BUILDING)→paused→done projects + job-based demolition (incl. furniture), 26-neighborhood grouping/merge, change orders, worker attribution, plan-only undo, cell→project reverse-index selection, persistence-until-empty. Governs building-system TR-102..126, building-ui TR-075..088, villager-ai TR-097; serialized via ADR-0012. See `adr-0016-build-project-entity-lifecycle.md`.
- **ADR-0012 / ADR-0013** — impact notes recorded in-place this batch; no decision change until ADR-0015 lands.

### Spike outcome & finalization (2026-07-23)
- **ADR-0015 storage/streaming spike → PASS 5/5**, at the game's real max camera speed (144 c/s, derived from `camera_input.gd`) and stress (120 c/s), at async caps 32 and 64 (`prototypes/storage-residency-spike/`, commits afb609c + 799ddbc). Key numbers: worst frame 13–15 ms (budget 16.6); peak memory 44–84 MB flat (ceiling 4 GB); save footprint 0.77 MB vs 7.63 GB naive (~1,600×); 99.5% of page-ins were regens, 0.5% disk. **ADR-0015 → Accepted (spike-validated).** Four validated text refinements applied: (a) time-based budget (`page_budget_ms`/`evict_budget_ms` = 4.0 ms) not fixed count; (b) §6 hardened to "no synchronous disk I/O or terrain-gen in the per-frame path, full stop" — the sync fallback was the failure mode; (c) read-through in-flight-write cache added as an edge case of §3; (d) accepted one-time per-region header-I/O exception + production note to make the drain loop completion-driven.
- **ADR-0014** — full-world-at-boot clause now **formally superseded** by ADR-0015 (Status/§1 updated; mesher/view-window/streaming unaffected).
- **ADR-0012 → finalized (Accepted, unchanged contract).** Voxel save format IS ADR-0015's region files (chunked by construction — the Alternative-C escape hatch exercised); per-system serialize contract unchanged; new state (`restore_value`, project entities, telemetry) absorbed structurally.
- **ADR-0013 → finalized.** Dungeon offset **kept at `100_000`**, justification recomputed from ratio to absolute gap (84,000 units of separation vs the 16k span; ~6.25× ratio). Increasing the offset rejected — float32 ULP scales with magnitude (7.8 mm @ 100k → 62 mm @ 1M), trading imperceptible jitter for perceptible for no real separation gain. `10_000` fallback remains non-viable.

---

## Traceability

New slice-batch TR-IDs referenced by the propagation: `TR-voxel-world-050` (floor terrain-replace `restore_value`), `TR-voxel-world-051` (terrain dig orders), `TR-voxel-world-052` (CW winding/culling); `TR-villager-ai-behavior-099` (unstuck watchdog), `-100` (rescue-target selection), `-102` (seal prevention). Recorded in `requirements-traceability.md` §Slice Propagation 2026-07-23.
