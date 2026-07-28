# Milestone Review: 01 — Foundation + Core (Playable Integrated Build)

> Generated: 2026-07-24 · Reviewer: producer · Review mode: lean (PR-MILESTONE gate skipped)
> Type: mid-milestone review (milestone not at its end date)

## Overview

- **Target Date**: not set — budget expressed as ~22 expected working days (opt ~18 / pess ~29)
- **Current Date**: 2026-07-24
- **Elapsed**: 3 sprints run back-to-back across ~2 calendar days
- **Sprints Completed**: 3 (S1 8/8, S2 9/9, S3 9/9 = **26 stories**, all green; suite 121 → 198 → 311; zero unplanned rework, zero carryover)
- **Story completion (M01 scope)**: **26 / 108 epic stories = 24%** · **2 / 8 epics closed** (foundation-spine 5/5, scene-world-management 3/3 — both small Foundation epics)

## Exit-Criteria Scoreboard (13 criteria)

**MET 2 · IN PROGRESS 2 · UNSTARTED 9**

| # | Exit Criterion | Verdict | Evidence / Gap |
|---|----------------|---------|----------------|
| 1 | Boot + DI + config spine (headless boot test) | **MET** | foundation-spine epic CLOSED 5/5; spine-004 headless boot test green (DI wiring + gate + config reads) |
| 2 | Foundation systems integrated (5 systems pass unit tests + run together) | **IN PROGRESS** | All 5 boot together (boot test green, 311 tests). But per-system depth is uneven: Scene/World 3/3 ✓, Time&Tick 5/7, RID 5/9, Camera 3/9, Voxel 4/17 — not all systems feature-complete |
| 3 | Mesher CW-winding rewrite + culling re-enable | **UNSTARTED** | Lives in voxel-world (4/17); mesher story not yet reached |
| 4 | Per-tick re-tuning pass (production load) | **UNSTARTED** | tick-005 shipped a max-ticks-per-frame *cap*, not the against-production-load re-tune; villager-side `max_deciding_per_tick` re-tune not done |
| 5 | ADR-0015 C1/C4 residency tuning | **UNSTARTED** | voxel-world; storage-residency-spike prototype active (de-risking) but production story not landed |
| 6 | Building System playable (full lifecycle) | **UNSTARTED** | 0 / 33 stories |
| 7 | Villager AI playable (FSM, AStar3D, occupancy, threading, anti-stuck) | **UNSTARTED** | 1 / 25 — only villager-ai-001 config/DI/FSM scaffold (epic opened, not playable) |
| 8 | Integrated playable build (headless E2E LOOP test) | **UNSTARTED** | Boot integration test exists; full build→workers-build→villagers-navigate LOOP cannot exist until #6 and #7 land |
| 9 | Ambient-life wave 1 (CD-protected) | **UNSTARTED** | Not placed in any epic; no stories created |
| 10 | Loop-payoff communication scaffolding (CD-protected) | **UNSTARTED** | Not placed in any epic; no stories created |
| 11 | All S1 + S2 bugs resolved | **MET** (provisional) | No open bugs; zero unplanned rework across 26 stories. Moving target — re-check at milestone end |
| 12 | Performance: 60 FPS, culling RE-ENABLED | **UNSTARTED** | Cannot be verified until #3 (mesher CW rewrite) re-enables culling on the production window |
| 13 | Build stable (headless E2E green) for review window | **IN PROGRESS** | Suite 311 green now; the sustained pre-milestone review window has not yet run |

**Headline:** the 24% that is done is the *Foundation* layer's small, low-integration stories. The **Core layer is essentially untouched — 1 / 58 stories** (building 0/33 + villager 1/25 = 1.7%). Every hard, integration-heavy criterion (#3–#8, #12) is still ahead.

## Remaining Inventory (M01 scope)

| Epic | Layer | Total | Done | Remaining |
|------|-------|------:|-----:|----------:|
| foundation-spine | Foundation | 5 | 5 | 0 (CLOSED) |
| scene-world-management | Foundation | 3 | 3 | 0 (CLOSED) |
| time-tick-system | Foundation | 7 | 5 | 2 |
| resource-item-database | Foundation | 9 | 5 | 4 |
| camera-input | Foundation | 9 | 3 | 6 |
| voxel-world | Foundation | 17 | 4 | 13 |
| building-system | Core | 33 | 0 | 33 |
| villager-ai-behavior | Core | 25 | 1 | 24 |
| **Totals** | | **108** | **26** | **82** |

Plus outside the epic count: **2 CD-protected items** (ambient-life wave 1, loop-payoff scaffolding — *unplaced*, no stories) and the **integration-to-playable / E2E LOOP** work (~1–2 stories). Effective remaining ≈ **~86 stories**.

## Re-Baseline

Two different units are in play and must not be conflated:

- **Estimate unit** = "one focused solo+AI working *package*-day" (~1 pkg/day). M01 = ~22 working-day *packages*.
- **Epic/story unit** = fine-grained agent-run stories. M01 = 108 stories; observed velocity **~9 stories/calendar-day back-to-back** (26 in ~2 days ≈ 13/day; use 9 conservatively), **~1 story/agent-run**.

**Remaining effort:**

| Basis | Figure |
|-------|--------|
| Remaining stories | ~82 epic + ~2 CD + ~2 integration ≈ **~86 stories** |
| Raw calendar (linear @ 9/day) | ~86 / 9 ≈ **~9.5 calendar days** back-to-back |
| **Risk-adjusted calendar** | **~13–16 calendar days** back-to-back |

The raw linear figure is **optimistic** and should not be quoted alone: the 26 completed stories are Foundation config/scaffold/query stories. The remaining 82 are dominated by the two hardest epics (Building 33, Villager AI 24) plus the risky Voxel mesher/residency chain (13) — higher integration density, threading, anti-stuck, and the +20% wiring overhead the re-baseline already flags. Foundation-velocity extrapolation does not transfer cleanly to Core, so a ~40–60% de-rating on the linear number is the honest read.

**Does the 22-working-day figure need formal revision? — No, not yet.**
- As an **effort envelope**, 22 working-day packages remains sound: **76% of stories remain, and the two hardest epics are untouched**, so the *work* has not shrunk. We have consumed roughly ~8–10 package-equivalents of the 22.
- In **calendar terms** the project is running well *ahead* of a 1-package/day assumption because ~9 stories close per calendar day — but that is a cadence observation, not an effort reduction. Do **not** cut the 22-day budget on the strength of Foundation velocity.
- **Recalibrate after the first 3–4 Core stories + the mesher/residency chain land.** Those are the first true measurement of Core velocity; that is the moment to formally revise (up or down).

## Top Risk

**The Voxel mesher CW-rewrite → ADR-0015 residency → integrated E2E LOOP chain (critical path, entirely unstarted).**
This single chain gates **five** exit criteria: mesher (#3), residency (#5), Building (#6) and Villager AI (#7) both consume voxel data/mesher output, performance-with-culling (#12) needs the CW rewrite to re-enable culling, and the E2E LOOP (#8) cannot go green until Building + Villager AI provide the loop. A second mesher pass or a residency surprise cascades into everything downstream.
- *Probability* Medium · *Impact* High · *Owner* godot-shader-specialist (mesher) / godot-gdscript-specialist (residency)
- *Mitigation in flight:* the `storage-residency-spike` prototype (uncommitted, in working tree) is active de-risking — good; keep it ahead of the Voxel World production stories.

**Secondary risk:** the two CD-protected items are **"not placed"** — no epic, no stories. That is a silent-deferral risk against explicit CD protection. They must get a home (a Presentation micro-epic or standalone M01 experience stories) before S4/S5, or they slip to polish by default.

## Go/No-Go Assessment

**Recommendation: CONDITIONAL GO — CONTINUE AS PLANNED (ON TRACK).**

Rationale: three sprints delivered 26/26 stories with zero rework and a fully green, growing suite — execution quality is excellent and the Foundation spine is proven. But this is a mid-milestone review, not a ship gate: 76% of stories and 100% of the risky Core + mesher/residency work remain. The milestone is *on track*, not *nearly done*.

Conditions to keep it on track:
1. **Sequence the mesher CW-rewrite + ADR-0015 residency chain FIRST** in the next sprint — retire the critical path before Building/Villager AI scale up.
2. **Create stories for the two CD-protected items** (or a Presentation micro-epic) so they are not silently deferred to polish — CD sign-off required to cut either.
3. **Hold the 22-working-day effort budget**; do not cut it on Foundation velocity. Recalibrate after the first 3–4 Core stories land.
4. **The E2E LOOP test is the integration proof for #8** — it cannot go green until a minimal Building + Villager AI loop exists; treat that as the milestone's true completion signal.

We will know this call was right if: the mesher/residency chain lands in ≤1 pass, the first 3–4 Building/Villager stories hold ≥6 stories/calendar-day (confirming Core velocity), and no CD item is silently dropped.

## Action Items

| # | Action | Owner | Deadline |
|---|--------|-------|----------|
| 1 | Next sprint: front-load Voxel mesher CW-rewrite + ADR-0015 C1/C4 residency (critical path) | producer / godot-shader-specialist | S4 plan |
| 2 | Land storage-residency-spike findings into the ADR-0015 production story before Voxel scale-up | godot-gdscript-specialist | before S4 voxel stories |
| 3 | Create stories (or a Presentation micro-epic) for ambient-life wave 1 + loop-payoff scaffolding | producer + art-director / godot-specialist | before S5 |
| 4 | Re-baseline calendar estimate after first 3–4 Core stories land (calibrate Core velocity) | producer | mid-S4 |
| 5 | Keep the E2E LOOP regression + typed-Array crash-class call in the commit gate | godot-gdscript-specialist | ongoing |
