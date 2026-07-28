# Sprint 8 — Working Days 71–80 (nominal anchor 2026-07-25) — THE MILESTONE-CLOSING SPRINT

> Duration is expressed in **working days** per the milestone re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on session
> cadence. **Calendar note (seven-times-confirmed):** Sprints 1–7 each landed their full commit in
> single back-to-back sessions (8/8, 9/9, 9/9, 8/8, 8/8, 13/13, 12/12) — measured throughput ran far
> above the 1-story/agent-day planning rate. The per-story estimate is the *planning anchor*, not a
> calendar prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **This is the sprint that closes Milestone 01.** The milestone's spine — the integrated
> build-and-inhabit loop — is MET and durable (S6 assembly crown #8, S7 closed-job-loop crown #2).
> This sprint retires the remaining open/partial criteria to their *loop-soundness* bar per the CD
> scope ruling (2026-07-25): the long-blocked **#4 re-tune** (values now decided), the one unretired
> unknown **#12 60-FPS measurement**, the player-facing **#6 drawing verbs** (four tools), the
> safety-critical **#7 anti-stuck base** (014→015→016), plus the cheap closure items **#5** and **#13**.

## Sprint Goal

Close M01. Land the coordinated per-tick re-tune at the decided values (**tick-007 + villager-ai-022**,
criterion #4), run the 60-FPS-with-culling measurement on the live Valley EARLY (**vox-018**, criterion
#12 — the one unretired unknown), stand up the four player-facing drawing verbs (**building-024/025/026/027**,
criterion #6 loop-critical subset), and land the safety-critical anti-stuck ladder base
(**villager-ai-014 → 015 → 016**, criterion #7 — the goal's literal "without getting stuck"). Close #5 on
ADR-0015 certification (vox-016/017 available as opportunistic measured-value pulls) and define the #13
stability window at plan level. After this sprint: run `/milestone-review current` for the M01 Go/No-Go.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — **reserved primarily for `vox-018`'s remediation risk** (M01's one
  unretired unknown: if the 60-FPS-with-culling measurement MISSES, named remediation stories are filed —
  greedy meshing / `visibility_range_end` / budget re-tune — and criterion #12 stays OPEN), plus the
  anti-stuck chain's real-integration surface and unplanned work.
  - **AMENDMENT 2026-07-25 — Buffer consumed by planned remediation (vox-019):** `vox-018` returned an
    honest **MISS** (p95 51.5 ms vs 16.6 ms; MEASURED root cause = `VoxelWorldMesher.build_chunk` ~40 ms/chunk
    dominated by the per-cell `get_cell` read loop; draw calls + culling PASS). The reserved buffer is now
    **spent as planned** on **vox-019** (read-loop optimization #1 + budget re-tune #2, radius tightening #3
    held as a fallback lever inside vox-019, GDExtension #4 as the escalation if vox-019 misses). This is the
    buffer working as designed, not scope creep — vox-019 draws from existing epic scope (voxel-world) and
    the ADR-0014 §2/§5 named reserves. Criterion #12 stays **OPEN** until vox-019's re-measurement renders a
    PASS.
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor (`estimate-rebaseline-2026-07-23.md`); Sprints
  1–7 delivered 8/8…12/12 in single sessions — throughput is *not* the binding constraint. The binding
  constraints this sprint are the **one unknown (`vox-018`)** and the **serial depth-3 anti-stuck chain**.
- **Committed:** Must 10 stories = 10.5 story-days *(serial sum)*; Nice 2 stories = 1.75 story-days.

**Parallel-lane capacity model (as S5/S6/S7 used):** the 8-available figure is **per-lane wall-clock**, not
a serial story-day sum. Three parallel owner-lanes run concurrently:

- **godot-gdscript-specialist** (residency/tick lane): `vox-018` (2.5) → `tick-007` (1.0) → *(Nice)* `vox-016`
  → `vox-017`. ~3.5 Must lane-days. **`vox-018` sequenced FIRST — it is the unretired unknown.**
- **godot-specialist** (the drawing-verbs lane): `building-024 → 025 → 026 → 027`. ~3.0 lane-days. All four
  are independent (deps 020/021/022 all DONE S5/S6) — one-owner-serial, no in-sprint chain.
- **ai-programmer** (re-tune half + the anti-stuck ladder): `villager-ai-022` (1.0, config, independent) +
  the serial chain `villager-ai-014 → 015 → 016` (3.0). ~4.0 lane-days — **the binding lane** (longest, and
  the chain is serial depth-3).

Max lane = **~4.0 lane-days** (ai-programmer), inside 8 with ~4 headroom. Critical path ≈ the anti-stuck
chain (014→015→016, 3.0 serial) OR `vox-018` (2.5 + remediation risk) — both watched (see Critical Path).

### Sprint 7 actuals (calibration context)

- **12/12 stories Complete** (6 Must, 3 Should, 3 Nice; presentation-001 = Sub-A, CD-approved with 7
  advisories, Sub-B formally open awaiting villager-ai-019).
- **THE CROWN (villager-ai-012) landed: the closed job loop** — release → queue → F2 select → claim →
  travel → on-site work → construction ticks → real voxel write → report → re-decide, all real components.
  **Milestone M01 criterion #2 MET.**
- Suite **682 → 843 blocking + 5 advisory perf**, green with 0 orphans on every story commit.
- **Perf stress basis for the re-tune produced** (villager-ai-025): worst per-tick 3.02 ms @30 villagers
  (5.5× under budget); FINDING — Rule 2 periodic recheck keeps the Deciding queue chronically full (bounded,
  never quiescent). This is the key input the #4 re-tune decision was made against.
- **Zero unplanned rework, zero carryover.** One gate near-miss (presentation-001 exit-code/orphan mismatch)
  caught by parent verification and fixed same-day.

## Tasks

### Must Have (Critical Path — close M01: #4 re-tune, #12 measurement, #6 verbs, #7 anti-stuck base)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-018 | **60-FPS-with-culling measurement on the live Valley (criterion #12) — THE UNRETIRED UNKNOWN, SEQUENCED FIRST** — wire `VoxelWorldMeshStreamer` into `Valley._process`, measure FPS/frame-time/draw-calls WINDOWED on a real GPU, culling ENABLED | `production/epics/voxel-world/story-018-60fps-culling-measurement.md` | godot-gdscript-specialist | 2.5 | vox-015 ✓ (S6 streaming machinery), scene-004 ✓ (S6 Valley assembly), vox-007 ✓, cam-006 ✓ | Live wiring: `update_view_window()` every frame, `build_initial_window()` once behind the transition overlay; draw calls ≤ 2000 tracking the window not world size; Advisory real-GPU evidence doc under `production/qa/evidence/` (FPS avg/p95/max + draw calls + PNGs + raw log); **honest PASS/MISS verdict** — on MISS, file named remediation stories, criterion #12 stays OPEN, NO `CULL_DISABLED` fallback |
| vox-019 | **Mesher read-loop optimization + budget re-tune + re-measure (vox-018 MISS remediation #1) — BUFFER CONSUMED (amendment 2026-07-25)** — bulk/direct chunk-array read instead of ~8,448 per-cell `get_cell` calls/chunk (byte-identical mesh output), re-tune `mesh_build_budget_ms`, re-run the vox-018 measurement same methodology | `production/epics/voxel-world/story-019-mesher-read-loop-optimization.md` | godot-gdscript-specialist | 1.5–2.5 | vox-018 ✓ (measured root cause + measurement tool), vox-015 ✓, vox-007 ✓, vox-002 ✓ | Profile-confirmed read-loop optimization with before/after per-chunk cost; **byte-identical** winding/culling/vertex output (new `mesher_bulk_read_equivalence_test.gd` + existing winding/material grep-guards green); `mesh_build_budget_ms` re-tuned to the measured cost; **re-measurement WINDOWED, honest PASS/MISS** — PASS closes #12; still-MISS → radius tightening applied + re-measured once → still-MISS → GDExtension escalation story filed, #12 stays OPEN; NO `CULL_DISABLED`; suite green throughout |
| tick-007 | **Per-tick re-tune — tick-budget half (criterion #4)** — record `max_ticks_per_frame` 10→12 (`ticks_per_second` unchanged at 4.0) as a config `.tres` change with shared rationale | `production/epics/time-tick-system/story-007-per-tick-retune-pass.md` | godot-gdscript-specialist | 1.0 | Decided values (`design/quick-specs/tick-rate-retune-2026-07-25.md`, provisional pending ratification); ADR-0008 | `max_ticks_per_frame=12`, `ticks_per_second=4.0` (no change) recorded as a config edit + `validate()` + rationale citing the quick-spec; ~50% stall-margin claim confirmed (AC4 of the quick-spec); coordinated as ONE change with villager-ai-022; per-frame cost guardrail (<0.5 ms) holds; passing test |
| villager-ai-022 | **Per-tick re-tune — Deciding half + `decision_interval` (criterion #4)** — `max_deciding_per_tick` 1→5 AND `decision_interval` 2→4 ticks (the quick-spec's third knob — **`decision_interval`'s scope home is THIS story** per quick-spec §7); **re-run story-025 stress harness at the new defaults as this story's evidence** | `production/epics/villager-ai-behavior/story-022-max-deciding-retune.md` | ai-programmer | 1.0 | villager-ai-025 ✓ (S7 measurement basis); Decided values (quick-spec, provisional); ADR-0002/0008 | `max_deciding_per_tick=5` AND `decision_interval=4` recorded as ONE coordinated config change with tick-007, shared rationale = the quick-spec; **story-025 stress harness RE-RUN at the new defaults** (quick-spec Risk 1 / AC1 — replaces the [ESTIMATED] ~5.47 ms with a measured figure; queue reaches quiescence between cycles per §4 F-retune-2; worst-case ticks-to-decide ≤ 6); frame budget holds at 1x AND 3x warp at pop 30; determinism unaffected (ADR-0009); no FSM/staggering change |
| building-024 | **Wall tool (F1) — drag→line rasterization + wall-height extrude (criterion #6)** | `production/epics/building-system/story-024-wall-tool.md` | godot-specialist | 1.0 | building-020 ✓, building-021 ✓, building-022 ✓ (all S5/S6) | Deterministic Bresenham line rasterization (equal displacements → equal cell counts); `wall_height` from typed `.tres` (default 3, clamped 1–8 at input); blueprint cells only; bounded by `max_cells_per_command`; passing unit test |
| building-025 | **Floor tool (F2) — drag→rectangle fill on the locked plane (criterion #6)** | `production/epics/building-system/story-025-floor-tool.md` | godot-specialist | 0.5 | building-020 ✓, building-021 ✓, building-022 ✓ | Deterministic rectangle fill on the locked plane; blueprint cells only; bounded by `max_cells_per_command`; passing unit test |
| building-026 | **Roof tool — Flat formation MVP + formation-picker seam (criterion #6)** — ⚑ NAMED RELEASE VALVE | `production/epics/building-system/story-026-roof-tool.md` | godot-specialist | 1.0 | building-020 ✓, building-021 ✓, building-022 ✓ | Deterministic Flat-formation cell set over the footprint; formation chosen before the drag; **Flat ONLY — do NOT build Gable/Hip/Shed (VS-tier reserve)**; blueprint cells only; bounded by the cap; passing unit test. **This is the sprint's honest cut lever (CD ruling): if S8 runs tight, roof drops to M02 — walls+floor+block still prove the draw-a-shelter verb; a roofless demo undersells Pillar 1 by 1 day but does not break loop-soundness.** |
| building-027 | **Block tool — single-cell place/replace, PLACE MODE ONLY in M01 (criterion #6)** | `production/epics/building-system/story-027-block-tool.md` | godot-specialist | 0.5 | building-020 ✓, building-021 ✓, building-022 ✓ | Single-cell place (surface-aware attach, or replace-in-place); blueprint cell only; **remove mode OUT of M01** (routes to removal-tool 031 → M02 per CD ruling); replace-in-place of terrain invalid; passing unit test |
| villager-ai-014 | **Rescue-target BFS (F5 expanding-ring search) — anti-stuck base (criterion #7)** — the rescue target the watchdog teleports to | `production/epics/villager-ai-behavior/story-014-rescue-target-bfs-f5.md` | ai-programmer | 1.0 | villager-ai-002 ✓ (is_standable), villager-ai-003 ✓ (body-column) | Expanding-ring BFS finds the nearest standable, body-column-clear rescue cell; deterministic ring order; bounded search; passing unit test. **Unlocks 015 (the watchdog hard-depends on this for its teleport target — the review's "minimum 015+016" was under-scoped by one story; the true safety base is 014+015+016 per the CD ruling).** |
| villager-ai-015 | **Unstuck watchdog trigger, rescue teleport & F3 telemetry — anti-stuck base (criterion #7)** — the watchdog + the criterion's named F3 telemetry | `production/epics/villager-ai-behavior/story-015-unstuck-watchdog-telemetry.md` | ai-programmer | 1.0 | **villager-ai-014 (in-sprint)**, villager-ai-003 ✓, villager-ai-011 ✓ (S7 claim-release path) | Watchdog detects a Traveling/Working agent with zero legal step over the timeout; teleports to the F5 rescue target; **F3 `villager_unstuck` telemetry counter** (the criterion names this explicitly); claim released cleanly on rescue; deterministic; passing unit test |
| villager-ai-016 | **Seal-prevention negative-write gate & livelock escape (F6) — anti-stuck base (criterion #7)** — a player's build can never permanently entrap a villager | `production/epics/villager-ai-behavior/story-016-seal-prevention-and-livelock.md` | ai-programmer | 1.0 | villager-ai-003 ✓, villager-ai-011 ✓, villager-ai-012 ✓ (S7 build-write path), **villager-ai-015 (in-sprint)** | Seal-prevention gate rejects a build write that would entomb an occupant (negative-write gate); livelock escape breaks oscillation; guarantees no permanent-stuck under player builds (the slice testers' #1 flagged failure mode); deterministic; passing integration test |

### Nice to Have (opportunistic #5 measured-value close — pull only if the residency lane clears)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-016 | **ADR-0015 C1 — async concurrency cap + bounded per-chunk gen cost (measured)** — the measured-value closure of criterion #5 (baseline #5 closes on certification; this UPGRADES it to as-written) | `production/epics/voxel-world/story-016-c1-async-cap-gen-cost-tuning.md` | godot-gdscript-specialist | 0.75 | vox-011 ✓, vox-012 ✓, vox-015 ✓ | Async concurrency cap + bounded per-chunk gen cost with a recorded measurement. Pull only after `vox-018` + `tick-007` land with lane headroom. |
| vox-017 | **ADR-0015 C4 — completion-driven residency drain loop** — the second measured-value closure of criterion #5 | `production/epics/voxel-world/story-017-c4-completion-driven-drain.md` | godot-gdscript-specialist | 1.0 | vox-011 ✓ | Completion-driven residency drain loop with a measured envelope. Pull only if the residency lane clears vox-016 with headroom. |

## Milestone-Criteria Closure Map (what this sprint closes)

| # | Criterion | S8 disposition |
|---|-----------|----------------|
| #4 | Per-tick re-tune | **CLOSES** via tick-007 + villager-ai-022 (decided values; villager-ai-022 folds the story-025 re-run) — pending value ratification |
| #12 | 60 FPS on production window, culling RE-ENABLED | **MISS on vox-018** (p95 51.5 ms; measured cause = mesher per-cell read loop) → **stays OPEN**; remediation **vox-019** filed (read-loop opt + budget re-tune; radius-tighten fallback; GDExtension escalation if still miss). **CLOSES ON vox-019 re-measurement PASS.** |
| #6 | Building System playable | **CLOSES to the CD-ruling loop-critical subset** via building-024/025/026/027 (breadth — change-orders/demolition/pause — deferred to M02) |
| #7 | Villager AI playable (anti-stuck + F3 telemetry) | **CLOSES to the safety base** via villager-ai-014→015→016 (013 nudge-aside = comfort tier, deferred M02 with a named pull-forward trigger) |
| #5 | ADR-0015 C1/C4 residency tuning | **CLOSES on certification** (vox-013/014, S6 — ADR-0015 Accepted); vox-016/017 available as Nice opportunistic measured-value upgrade. See disposition below. |
| #13 | Build stable for the review window | **DEFINED at plan level** (see below) + green-commit observation over S8. No story. |

## #5 Disposition — CLOSE ON CERTIFICATION (chosen)

**Decision (producer + TD basis):** Criterion #5 closes on the ADR-0015 **certification** already banked in
S6 (`vox-013` read-through in-flight-write cache + `vox-014` load-before-write closed the last residency
invariants; ADR-0015 is **Accepted**). The invariants that make the residency tier *correct* are certified
and green. C1 (async concurrency cap / bounded gen cost) and C4 (completion-driven drain) are
performance-**hardening** tunings — they reduce load risk, they are **not loop-soundness gates**. This is the
same razor the CD ruling applied to #6/#7: *soundness over breadth*. Closing #5 on certification protects the
Must budget for the safety-critical anti-stuck work and the vox-018 remediation buffer.

**Why not just run vox-016/017?** They are cheap (0.75 + 1.0 day) and Ready, so rather than hard-defer them
they sit as **Nice-to-Have opportunistic pulls**: if the residency lane clears vox-018 + tick-007 with
headroom, running them UPGRADES #5 from "closed on certification" to "closed with measured values" (the
criterion's as-written wording) at no cost to the Must set. **Named pull-forward trigger:** if `vox-018`'s
measurement surfaces residency-driven per-frame cost (streaming stalls / unload bursts under the live loop),
pull vox-016/017 forward as the direct remediation — they are the async-cap and drain levers.

## #13 Disposition — STABILITY WINDOW DEFINITION (plan-level, no story)

The M01 "build stable for the pre-milestone review window" criterion has never had an agreed observation
duration. **Producer definition for M01 close:**

> The M01 stability window = **the full S8 story-commit sequence**. The window is SATISFIED when, across
> every S8 story commit (≥ the 10 Must commits), ALL of the following hold with zero regressions:
> 1. the full blocking suite runs green **headless with zero orphans** on every commit (the S1–S7 standard);
> 2. the assembled **E2E LOOP test** (`scene-004`, criterion #8) stays green on every commit;
> 3. after villager-ai-015 lands, the **F3 `villager_unstuck` telemetry** shows the watchdog firing and
>    recovering agents, and **no villager remains permanently stuck** across the window (the CD ruling's #7
>    design test).

**Evidence pointer:** the CI green-on-every-commit record (the S1–S7 durable pattern) + the
`villager_unstuck` telemetry captured in `production/qa/evidence/` when villager-ai-015 lands. No dev work,
no story — a producer definition + observation over the sprint the milestone closes in. If S8 lands clean
(as S1–S7 all did), the window elapses within the sprint and #13 closes at `/milestone-review`.

## Critical Path

Two watched paths this sprint — not one binding lane:

1. **The anti-stuck chain (`villager-ai-014 → 015 → 016`)** — serial depth-3 on the ai-programmer lane,
   ~3.0 lane-days. This is the longest serial chain and the safety-critical spine of #7. `015` hard-depends
   on `014` (rescue target); `016` depends on `015` (self-heal). Sequence 014 FIRST on the ai lane;
   villager-ai-022 (config, independent) fills the lane while 014 runs. Do not let 016 sit on the last day.
2. **`vox-018` — the unretired unknown** — 2.5 days + unknown remediation risk. Sequence it FIRST on the
   gdscript lane (the milestone review's critical-path item 3: "do this early — it is the one unretired
   unknown"). The 2-day buffer is reserved for its MISS-remediation branch.

**Owner lanes (serialization mitigation):**
- **godot-gdscript-specialist:** `vox-018` **(FIRST — the unknown)** → `tick-007` → *(Nice)* `vox-016` → `vox-017`.
- **godot-specialist:** `building-024 → 025 → 026 → 027` (four independent verbs; roof-026 is the cut lever).
- **ai-programmer:** `villager-ai-022` (independent config) ‖ `villager-ai-014 → 015 → 016` (serial base).

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 7 delivered 12/12 — no carryover, zero unplanned rework. The S7 "open for S8" set (re-tune, #12 measurement, anti-stuck ladder, building tools) is scheduled below as planned, not as incomplete carryover. | — |

## Out of Scope (deferred, with honest reasons — per the CD scope ruling 2026-07-25)

- **Building lifecycle breadth (M02):** `007` change-orders, `009` block demolition, `006` pause/resume,
  `008` click-selection, plus furniture (`016/017/028`), dig/mining (`013/014`), Abriss (`010`), tool-batch
  (`018`), removal-tool (`031/015`). These are the *reverse/edit* verbs — the forward loop (draw→build→done)
  is sound without them. This is the ~6–8 ad the review sized as "only if the ruling holds it" — **the CD
  ruling does not hold it.**
- **`villager-ai-013` nudge-aside (F4) — M02, WITH A NAMED PULL-FORWARD TRIGGER.** It handles a
  builder-waits-for-an-idle-occupant *comfort* case, not a permanent-stuck case (014/015/016 already
  guarantee recovery). **Trigger (CD ruling watch-item):** `013` and `019` (idle wandering) are both
  deferred; together that leaves a seam where an idle villager parked in a builder's only target cell stalls
  that *build cell*. If S8 playtesting surfaces builders visibly frozen on an idle parker, **pull `013`
  forward** — it is the direct 1-ad fix. Absent that signal, it stays M02.
- **`presentation-001` Sub-scope B** (villager idle behaviors) + the Valley golden-hour ambient re-shoot
  (CD advisory #2) — Sub-B formally depends on `villager-ai-019` (not scheduled). CD framed ambient life as
  a later wave; #9 closes on Sub-A-present per the CD ruling. Deferred to the sprint that schedules
  `villager-ai-019` (M02). Bundle the re-shoot with that work. **CD-protected — surfaced, not silently dropped.**
- **Roof formations beyond Flat** (Gable/Hip/Shed) — VS-tier reserve; building-026 ships Flat MVP only.
- **vox-016/017 as Must** — held as Nice opportunistic pulls; #5 closes on certification (see disposition).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **The CD scope ruling + the re-tune values are PROVISIONAL pending user ratification** — this entire plan is sized against the ruling (loop-critical subset) and the quick-spec's decided values. If either is not ratified, the Must set and/or sizing change | Medium | High | Both artifacts are away-mode delegated decisions with full rationale. **The plan proceeds AS IF ratified** (per autonomous progression) but ratification is the gating external dependency — flagged below. If the ruling is overturned toward as-written breadth, M01 becomes a 2-sprint close (S8+S9) per the review's strict-as-written sizing (~18–22 ad). If the re-tune values change, tick-007/villager-ai-022 re-run against the new numbers (config-only, cheap). |
| **`vox-018` is M01's ONE unretired unknown** — the 60-FPS-with-culling target has never been measured on the live Valley loop; rendering could surface remediation | Medium | High (it gates criterion #12; a MISS keeps #12 OPEN into M02) | Sequenced FIRST on the gdscript lane; the 2-day buffer is reserved for its MISS-remediation branch. Honest verdict enforced: on MISS, file named remediation stories (greedy meshing / `visibility_range_end` / budget re-tune), NO `CULL_DISABLED` fallback. Headroom is *expected* (slice held 60 FPS at 2× faces on CULL_DISABLED) but expected ≠ measured. |
| **The anti-stuck chain is a serial depth-3 chain integrating REAL build-write + claim-release paths** (015 teleport + claim release; 016 build-write seal gate) — the historical failure mode is wiring gaps where two real systems meet | Medium | Med-High | Sequence 014 FIRST; villager-ai-022 fills the lane while 014 runs. Each story asserts independently (BFS target / watchdog fire+telemetry / seal-gate reject). 011 (claim release) and 012 (build write) are proven green from S7 — the chain consumes stable seams, not new ones. Buffer reserved for the join. |
| **`vox-018` is HIGH engine-risk** — rendering is the top post-cutoff knowledge-gap domain (draw-call enum, `RenderingServer.get_rendering_info` 4.7 API, windowed-vs-headless GPU measurement) | Medium | Med | Cross-reference every rendering API against `docs/engine-reference/godot/` (BLOCKING). Measurement runs WINDOWED on a real GPU via the `mesher_evidence`/`camera_sandbox` tool-scene precedent, NOT in the boot chain, NOT headless. |
| **Building tools land four verbs on one owner-lane** — all four depend on the same S5/S6 pick/commit base; a base regression would strand all four | Low | Med | All deps (020/021/022) are proven green and closed. The four tools are independent leaf rasterizers emitting cell-sets into the already-landed commit pipeline — no in-sprint chain, no shared new code. Roof-026 is the named cut lever if the lane runs tight. |
| **#5 closed on certification may be contested at review** — the criterion as-written names "tuning stories with measured values" | Low | Low | Disposition documented above with the producer+TD basis (soundness over breadth razor); vox-016/017 held as Nice pulls to upgrade to measured values at no Must cost if the lane clears. |
| **Recurring typed-Array crash class** (0 in S1–S7) | Low | Low | Regression call retained inside the E2E gate; watched on the new anti-stuck teleport/seal-write and drawing-tool commit paths this sprint exercises. |

## Dependencies on External Factors

- **USER RATIFICATION of two provisional decisions (the gating dependency):**
  1. **The CD scope ruling (2026-07-25)** on criteria #6/#7 breadth — this plan's Must set IS the ruling's
     loop-critical subset. Binding on S8 planning only once ratified.
  2. **The re-tune values** (`design/quick-specs/tick-rate-retune-2026-07-25.md`): `max_ticks_per_frame=12`,
     `max_deciding_per_tick=5`, `decision_interval=4`, `ticks_per_second=4.0` unchanged. tick-007 +
     villager-ai-022 implement exactly these. If ratified, the 4-sprint-blocked criterion #4 finally closes.
  - **Registry impact on ratification:** `max_ticks_per_frame` 10→12 in `design/registry/entities.yaml`
    (quick-spec §10); `max_deciding_per_tick`/`decision_interval` are GDD-local, no registry action.
- **Control-manifest version 2026-07-23** — all S8 stories embed this version. Confirmed current S1–S7;
  re-confirm unchanged before the lanes start. Owner: technical-director.
- **No art/audio external dependency** for the committed set (tick config, voxel measurement, building-tool
  logic, villager AI logic). vox-018's PNG evidence is a real-GPU screenshot, not new art.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed — **M01's remaining loop-critical criteria closed**: #4 (re-tune),
      #6 (four drawing verbs), #7 (anti-stuck base + F3 telemetry), and #12 (60-FPS measurement rendered
      to an honest PASS/MISS verdict)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (building-024/025/026/027, villager-ai-014/015) has a passing GdUnit4 headless unit
      test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (vox-018 live-wiring half, villager-ai-016) has a passing headless integration
      test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] Config re-tune (tick-007 + villager-ai-022) recorded as ONE coordinated `.tres` change with the
      quick-spec as shared rationale; **story-025 stress harness RE-RUN at the new defaults** and the
      measured figure recorded (replaces the quick-spec's [ESTIMATED] ~5.47 ms) — BLOCKING for #4 close
- [ ] vox-018 Advisory real-GPU evidence doc exists under `production/qa/evidence/` (FPS/frame-time/draw-calls
      + ≥1 PNG + raw log + hardware class + engine build) with a PASS/MISS verdict; on MISS, remediation
      stories filed and criterion #12 recorded OPEN — no `CULL_DISABLED` fallback
- [ ] All AStar/nav/rendering/particle APIs confirmed against `docs/engine-reference/godot/` — BLOCKING
      (vox-018 rendering; villager-ai-014/015/016 nav)
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit tests)
- [ ] #13 stability window (defined above) observed green across the S8 commit sequence; `villager_unstuck`
      telemetry evidence captured after villager-ai-015 lands
- [ ] QA plan exists for Sprint 8 (`production/qa/qa-plan-sprint-8-*.md`) — run `/qa-plan sprint` before
      implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR/registry docs updated for the ratified re-tune (registry `max_ticks_per_frame` 10→12) and
      any deviation
- [ ] Code reviewed and merged (trunk-based)
- [ ] **After the sprint: run `/milestone-review current` for the M01 Go/No-Go**

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-8 QA plan. Run `/qa-plan sprint` before the
> last story is implemented. The Production → Polish gate requires a QA sign-off report, which requires a
> QA plan. vox-018's PASS/MISS measurement conditions, the re-tune's re-measurement AC, and the anti-stuck
> chain's watchdog-fire/seal-reject assertions in particular need defining up front.

## Notes

- **Dependencies-satisfied check:** every S8 committed story was verified against its real story-file
  `## Dependencies` section (not the request list). vox-018 → vox-015 ✓/scene-004 ✓/vox-007 ✓/cam-006 ✓
  (all S4–S6); tick-007 → decided values (quick-spec) + ADR-0008; villager-ai-022 → villager-ai-025 ✓ (S7)
  + decided values; building-024/025/026/027 → 020 ✓/021 ✓/022 ✓ (S5/S6); villager-ai-014 → 002 ✓/003 ✓;
  villager-ai-015 → 014 (in-sprint) + 003 ✓ + 011 ✓; villager-ai-016 → 003 ✓/011 ✓/012 ✓ + 015 (in-sprint);
  vox-016 → 011 ✓/012 ✓/015 ✓; vox-017 → 011 ✓. **All scheduled story files EXIST and are Status: Ready**
  (verified 2026-07-25). No unsatisfied dependency in the committed set.
- **The re-tune is ONE coordinated change:** tick-007 (`max_ticks_per_frame`) + villager-ai-022
  (`max_deciding_per_tick` + `decision_interval`), shared rationale = `tick-rate-retune-2026-07-25.md`.
  **`decision_interval`'s scope home is villager-ai-022** (quick-spec §7 — neither story listed it before;
  adding it to villager-ai-022's ACs alongside `max_deciding_per_tick` is this plan's resolution). The
  story-025 stress RE-RUN at the new defaults is **folded into villager-ai-022's evidence** (its AC1 already
  requires it) rather than a separate story — keeps the story count inside the S6/S7 velocity band.
- **Scope check:** all committed stories are drawn from existing epics (voxel-world, time-tick-system,
  building-system, villager-ai-behavior) — no fabricated stories. The Must set IS the CD scope ruling's
  loop-critical subset (not an addition beyond it). Run `/scope-check sprint-8` before implementation.
- **Velocity:** 10 Must + 2 Nice = 12 stories, matching the S6/S7 band (13/13, 12/12). Max lane ~4.0
  lane-days inside 8 available; 2-day buffer reserved for the vox-018 unknown and the anti-stuck join.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story`, then sequence
  `vox-018` (gdscript, FIRST) and `villager-ai-014` (ai, FIRST) as the two critical-path openers.


---

## Sprint Result — CLOSED 2026-07-26

**13/13 complete** (10 Must + vox-019 remediation + 2 Nice). Suite 843 -> 951, green with 0 orphans on every story commit.

Milestone criteria closed this sprint:
- **#4 re-tune** — tick-007 (max_ticks_per_frame 12) + villager-ai-022 (K=5, decision_interval 4): worst-case deciding wait at pop 30 measured 30 -> 6 ticks; burst amplification measured 23.1ms, isolated and non-recurring.
- **#12 60 FPS with culling** — vox-018 measured an honest MISS (p95 51.5ms) and root-caused it to build_chunk's per-cell read loop; vox-019 (planned buffer) replaced it with a bulk ChunkSnapshot: 40.4 -> 7.7ms per chunk, byte-identical output, p95 13.06ms true compute (21% headroom), draw calls 709, culling proven ON. PASS.
- **#6 building playable (CD-ruled scope)** — all four drawing verbs land: wall (F1), floor (F2), roof (Flat MVP), block (place). Every tool is a pure resolver behind CommitPipeline; grep-guarded as non-writers.
- **#7 villager AI (CD-ruled scope)** — anti-stuck ladder complete: rescue-target BFS (014), watchdog + F3 telemetry (015), seal prevention + livelock escape proven against the REAL build write (016).
- **#5 residency** — upgraded from banked certification to MEASURED values: C1 (cap 32 confirmed, gen-cost guard 1.0ms, worst frame 5.5ms) and C4 (completion-driven drain: 1.24x cost across 10x queue size).

Findings recorded: the spike's 144 cells/s camera speed is stale (real: 42.0); vsync floors frame-time measurements at 16.67ms (measure true compute with vsync off); Godot 4.7 cannot @export RefCounted/Object.

Deferred per CD ruling (M02): building 006/007/008/009, villager-ai-013, presentation-001 Sub-B + the golden-hour ambient re-shoot, roof formations beyond Flat, block remove-mode.
