# Milestone Review: 01 — Foundation + Core (Playable Integrated Build) — GO/NO-GO

**Generated**: 2026-07-26 · **Producer** · Review mode: **lean** (PR-MILESTONE gate skipped per
`production/review-mode.txt` — I am the producer of record; no sub-verdict spawned).
**Supersedes**: `milestone-01-review-2026-07-24.md` (status assessment only; that document's
**CD Scope Ruling (2026-07-25)** section remains the live, still-provisional ruling).

## Overview

- **Target**: ~22 expected working days / ~3 sprints (optimistic 18 / pessimistic 29)
- **Actual**: **8 sprints closed (S1–S8), zero carryover and zero unplanned rework in every one**
- **Suite**: **951/951 blocking** + advisory perf suites, **0 orphans, green on every commit** across S6–S8
- **S8 result**: 13/13 (10 Must + `vox-019` planned-buffer remediation + 2 Nice)
- **Verdict**: **GO WITH CONDITIONS** — see below. Nothing on the condition list is development
  risk; it is two signatures and roughly one agent-day of observation/demo evidence.

The milestone's reason to exist is met and durable: the player-drawn → worker-built → villager-inhabited
loop runs on the production codebase, is green in the commit gate, has real player-facing verbs, has a
safety layer that guarantees no permanent stuck, and now has a measured 60-FPS-with-culling PASS.

---

## Per-Criterion Status

Criteria numbered 1–13 in milestone-file checkbox order.

| # | Criterion (as written) | Status | Evidence pointer |
|---|---|---|---|
| 1 | Boot + DI + config spine, headless boot test | **MET** | `spine-001..005` (S1–S2), `scene-002` boot gate, ADR-0005; `spine-004` headless boot integration test green |
| 2 | Foundation systems integrated (5 systems, per-system tests, one scene) | **MET** | Scene/World closed S3, Camera closed S4, Time&Tick/RID/Voxel green; `scene-004` crown (S6) runs all five in one scene |
| 3 | Mesher CW-winding rewrite + culling RE-ENABLED | **MET** | `vox-007` (S4); `production/qa/evidence/chunked-mesher-cw-winding-culling-evidence.md`; `CULL_DISABLED` grep-guard re-run green in `vox-019` |
| 4 | Per-tick re-tune recorded as a config change with rationale | **MET** ⚑ values provisional | `tick-007` (`max_ticks_per_frame` 10→12) + `villager-ai-022` (`max_deciding_per_tick` 1→5, `decision_interval` 2→4). **Measured, not modelled**: worst-case deciding wait at pop 30 **30 → 6 ticks**; burst amplification 23.1 ms isolated/non-recurring. `production/qa/smoke-2026-07-25.md` §1–8; `production/qa/evidence/villager-ai-stress-evidence-retune-20260725.md`. Shared rationale `design/quick-specs/tick-rate-retune-2026-07-25.md` (**provisional pending user ratification**) |
| 5 | ADR-0015 C1/C4 residency tuning — **stories with measured values** | **MET (as written)** | Upgraded past the planned certification-only close: `vox-016` (cap **32** confirmed against production code, gen-cost guard **1.0 ms**, worst traverse frame **5.5 ms**) `production/qa/smoke-2026-07-26.md`; `vox-017` (completion-driven drain, **1.24×** cost across 10× queue) `production/qa/evidence/voxel-world-completion-driven-drain-evidence-20260726-vox017.md`. No longer rests on a producer/TD razor |
| 6 | Building System playable — full ADR-0016 lifecycle incl. tools, change orders, demolition | **MET at CD-ruled scope** ⚑ **ruling unratified** | All four drawing verbs land: `building-024` wall (F1), `025` floor (F2), `026` roof (Flat MVP), `027` block (place). Each a pure resolver behind `CommitPipeline`, grep-guarded as non-writers. **Against as-written wording this is PARTIAL** — change orders (`007`), demolition (`009`), pause/resume (`006`), click-selection (`008`) are deferred by the **still-provisional CD ruling** |
| 7 | Villager AI playable incl. anti-stuck watchdog + seal prevention + F3 telemetry | **MET at CD-ruled scope** ⚑ **ruling unratified** | Anti-stuck ladder complete: `villager-ai-014` rescue-target BFS, `015` watchdog + rescue teleport + **F3 `villager_unstuck` telemetry** (the criterion's named item), `016` seal prevention + livelock escape **proven against the REAL build write**. **Against as-written this is PARTIAL** only by `013` nudge-aside (comfort tier), deferred by the same provisional ruling. See condition C3 — the ruling's own design test has not yet been executed at run level |
| 8 | Integrated playable build — headless E2E LOOP green on every commit | **MET** | `scene-004` crown (S6) in the commit gate; deepened by `villager-ai-012` (S7). Green on all 13 S8 commits |
| 9 | Ambient-life wave 1 present (CD-protected) — "visible in the build" | **PARTIAL** | Sub-A **CD-APPROVED WITH ADVISORIES** 2026-07-24 (smoke/sway/clutter/flicker; `production/qa/evidence/ambient-life-wave-1-evidence.md` §CD sign-off + 5 PNGs). **Two honest gaps**: (a) Sub-A is proven in standalone capture, **not wired into the live Valley** — the criterion says *visible in the build*; the golden-hour Valley re-shoot is owed (CD advisory #2); (b) CD ruled the debrief's *"world lacks life" finding* stays OPEN until Sub-B (`villager-ai-019`, M02). See condition C4 |
| 10 | Loop-payoff communication scaffolding (CD-protected) | **MET** | `presentation-002` (S5), CD-approved. The recovery *mechanic* is M02 by design, per the criterion's own wording |
| 11 | All S1 and S2 bugs resolved | **MET** | 0 open S1/S2. The one S7 process incident (presentation-001 particle orphans / exit-code mismatch) was root-caused and fixed same-day; 0 orphans held across all 13 S8 commits |
| 12 | 60 FPS on the production window, culling RE-ENABLED | **MET** ⚑ hardware caveat | `vox-018` returned an honest **MISS** (p95 51.5 ms) and root-caused it to `build_chunk`'s per-cell read loop; `vox-019` replaced it with a bulk `ChunkSnapshot`: **40.4 → 7.7 ms/chunk (~5.2×)**, byte-identical output (6/6 equivalence tests), **p95 13.06 ms true compute, 21.3% headroom**, **draw calls 709/2000**, **culling proven ON** (grep-guard + low-oblique captures both sessions). No `CULL_DISABLED` fallback anywhere. `production/qa/evidence/voxel-world-60fps-culling-evidence-20260725-vox019.md`. **Caveat carried forward**: measured on an RX 7900 XT — the project has no verified mid-range baseline, and the VSync-on number (16.947 ms) is a 60 Hz presentation-wait artifact, disclosed not omitted |
| 13 | Build stable (headless E2E green) for the pre-milestone review window | **PARTIAL** | Window defined at plan level (`sprint-08.md` §#13 Disposition) as the S8 commit sequence with 3 clauses. **Clauses 1 & 2 SATISFIED** — full blocking suite green headless with 0 orphans on all 13 commits; E2E LOOP green on all 13. **Clause 3 NOT SATISFIED as an observation** — `villager_unstuck` telemetry exists and is asserted by `villager-ai-015`'s unit/integration tests, but no run-level capture exists anywhere under `production/qa/evidence/` (grep: zero evidence artifacts reference it). Against the *milestone file's own* narrower wording ("headless E2E green for the window") this is MET; against the S8 definition's clause 3 it is not. See condition C3 |

**Tally**: MET 9 (#1,2,3,4,5,8,10,11,12) · **MET at CD-ruled scope, ruling unratified** 2 (#6,#7) · PARTIAL 2 (#9,#13)

### Criteria whose closure depends on the still-unratified CD ruling

⚑ **#6, #7, and #9.** The **CD Scope Ruling (2026-07-25)** in `milestone-01-review-2026-07-24.md`
is explicitly marked *PROVISIONAL — pending user ratification (away-mode)*. If ratified, #6 and #7
close at the loop-critical bar delivered in S8 and #9 closes on Sub-A-present. If overturned toward
as-written breadth, all three revert to PARTIAL and M01 needs a further **~7–9 agent-days** (change
orders + demolition ~6–8 ad, `013` nudge-aside ~1 ad, `019`+Sub-B ~2.5 ad) — i.e. **a second closing
sprint**. Separately, criterion **#4's values** come from `design/quick-specs/tick-rate-retune-2026-07-25.md`,
also marked provisional; the implementation smoke docs record them as "ratified per delegation," which
is not the same as user ratification. **Nothing here is a work item — it is a signature.**

---

## Verdict

> # GO WITH CONDITIONS
>
> Milestone 01 is substantively complete. Its highest-risk deliverables — the integrated loop, the
> mesher/culling rewrite, the 60-FPS unknown, and the anti-stuck safety layer — are all landed and
> measured. **I do not recommend declaring M01 CLOSED today**, because two criteria (#9, #13) have
> honest evidence gaps and three (#6, #7, #9) close only under a ruling the user has not yet ratified.
> All of it is retirable in **one short session (~1 agent-day) plus two decisions.**

**Why not a clean GO.** Two things would be dishonest to wave through. First, #13's own stability
definition names a *telemetry observation* that was never made — we have test-level proof the
watchdog fires, not run-level proof it fires and recovers agents across the window. That same
observation is the CD ruling's own stated design test for #7, so skipping it means the ruling closes
#7 without ever running the check the ruling wrote for itself. Second, #9's criterion says *"visible
in the build"* and Sub-A currently is not in the Valley build — it is in a capture harness.

**Why not NO-GO.** Nothing outstanding is development risk. There is no unretired unknown left
(#12 was the last one and it PASSed), no open S1/S2, no failing test, no carryover, and no
dependency on unfinished upstream work. Eight sprints of zero-rework delivery is the strongest
velocity signal this project has; the remaining items are evidence capture and sign-off.

**Honest note on schedule.** M01 was budgeted at ~22 working days / ~3 sprints and consumed 8
sprints. The per-story planning anchor never matched measured session throughput (8–13 stories per
single session), so the *day* estimate was wrong while the *work* estimate was roughly right —
re-baseline M02 in sessions/stories, not agent-days, or the same distortion repeats.

---

## Conditions — what must happen before M01 can be declared CLOSED

| # | Condition | Owner | Size | Closes |
|---|---|---|---|---|
| **C1** | **Ratify the CD Scope Ruling (2026-07-25)** on #6/#7 breadth (and its #9 framing) — or overturn it, which makes M01 a two-sprint close | user (CD ruling authored under delegation) | decision | #6, #7, #9 basis |
| **C2** | **Ratify the re-tune values** in `design/quick-specs/tick-rate-retune-2026-07-25.md` (`max_ticks_per_frame=12`, `max_deciding_per_tick=5`, `decision_interval=4`, `ticks_per_second` unchanged) — already implemented and measured; this confirms the closure basis | user | decision | #4 basis |
| **C3** | **Run the stability-window observation + the M01 demo, capture both to `production/qa/evidence/`**: (a) `villager_unstuck` counters observed firing and recovering agents over a real run with **no permanent stuck** — closes #13 clause 3 *and* executes the CD ruling's own #7 design test; (b) the ruling's own #6 design test — a **human** draws a walled/floored/roofed room, workers build it, a villager moves in — captured as a short walkthrough + screenshots | producer + godot-specialist / ai-programmer | ~1 ad, one session | #13, validates #6/#7 rulings |
| **C4** | **#9 disposition — pick one**: (i) wire Sub-A into the Valley and take the owed golden-hour capture (~0.5 ad; bundles with C3's demo session and makes the criterion literally true), or (ii) ratify that Sub-A-standalone satisfies "wave 1 present" and carry the Valley re-shoot to M02 with `019`/Sub-B. **My recommendation: (i)** — it is half a day, it retires a CD advisory, and it means the M01 demo shows a world with motion in it | user decides, godot-specialist executes | ~0.5 ad or 0 | #9 |

**Advisory, not blocking M01 close** (but must be fixed before the Production → Polish gate):
Sprint 8 has a QA plan (`qa-plan-sprint-8-2026-07-25.md`) and per-story smoke docs, but **no
sprint-level `/smoke-check sprint` and no `/team-qa sprint` sign-off report** — two unchecked items
in S8's own Definition of Done, and a pattern across all eight sprints (no sign-off artifact exists
in `production/qa/`). The Production → Polish gate requires one. Fold `/team-qa sprint` into the C3
session or schedule it at the head of M02.

**We will know this GO was right if**: C3's telemetry run shows the watchdog firing with zero
permanent-stuck; the human demo completes without a wiring gap the E2E test could not catch; and M02
opens with no M01 rework tickets in its first sprint.

---

## Recommended shape of Milestone 02

**Theme: *Complete the MVP — make the loop pay off, and let the settlement answer back.***

M01 proved the *forward* loop mechanically. M02 owes three things the player actually feels: the
**payoff** (shelter → recovery, the mechanic behind M01's scaffolding), the **reverse/edit verbs**
(change your mind, tear down), and **life + a UI to run it through**. The milestone file budgets M02
at ~10 working days to reach the 32-day MVP total — **that budget will not hold all four clusters
below.** Treat cluster sizing as M02's first scope negotiation, not an assumption.

### Cluster A — The loop payoff mechanic (PROTECT — this is M02's reason to exist)
Named by M01's own Out-of-Scope section as M02's job.
- **Build Validation & Navigability** — roofed + floored + walkable = livable; the gate the roof tool's mechanical meaning has been waiting for since `building-026` shipped Flat MVP.
- **Needs & Mood** — the recovery half. M01 shipped `presentation-002` scaffolding (criterion #10) with **no mechanic behind it**; until this lands, the warm-light reward signals nothing.
- **Carried caveat**: `design/gdd/time-tick-system.md`'s Open Question — the 2.0→4.0 `ticks_per_second` change doubled every downstream per-tick rate's real-time meaning. **Needs & Mood is the system that inherits it.** Resolve the real-time-equivalent pass as part of this cluster, not after.

### Cluster B — Life (CD-protected, closes the oldest open finding)
- **`villager-ai-019` idle behaviors** → unblocks **`presentation-001` Sub-B** → the CD's stated *highest mood-value-per-cost* item, and the only thing that closes the slice debrief's #1 **"world lacks life"** finding (CD ruled it stays OPEN until Sub-B).
- **Golden-hour Valley ambient re-shoot** (CD advisory #2) — unless already taken under condition C4.
- **`villager-ai-013` nudge-aside** — its CD-named pull-forward trigger is precisely the `013`+`019` seam; scheduling `019` is the moment to schedule `013` alongside it.
- Remaining Sub-A advisories for later waves (foliage hue, Hearth Gold torch lock, §6.3 clutter treatment, wave-2 air layers, Dusk/Horizon tests).

### Cluster C — Lifecycle breadth (the CD-ruling deferrals — the honest cut lever)
Proves ADR-0016 completeness. Ranked by player expectation:
- **`building-009` demolition** + `031`/`015` removal-tool + **`building-027` remove-mode** — players will reach for tear-down first; this is the least-cuttable of the cluster.
- **`building-007` change orders** — edit an already-built project.
- **`building-006` pause/resume**, **`building-008` click-selection**.
- Lower tier: furniture (`016/017/028`), dig/mining (`013/014`), Abriss (`010`), tool-batch (`018`).
- The M01 review sized this cluster at ~6–8 ad. **If M02 must fit ~10 days, this is where the cut comes from** — split it: demolition in M02, the rest to VS-tier.

### Cluster D — Presentation layer (minimum viable, per M01's Out-of-Scope note)
- **Building UI** and **Villager Info UI** as real UX-spec'd systems (M01 shipped minimal interaction only).
- **Main-menu / pause-menu UX specs** (pre-production gate blocker #4) — authored in parallel; not gated by the core loop.

### Explicitly NOT M02
- **Roof formations beyond Flat** (Gable/Hip/Shed) — VS-tier reserve unless the CD pulls them.
- Save/Load, audio, resource economy, combat, wave defense — VS-tier or later.

### M02 risks to open the register with
| Risk | Prob | Impact | Mitigation |
|---|---|---|---|
| **No verified mid-range hardware baseline** — #12 passed on an RX 7900 XT; the 21% headroom figure is not a mid-range claim | Medium | **High** | Define the target hardware class and re-measure early in M02. `vox-018`'s tool is reusable verbatim |
| **VSync-mode decision is unowned** — the VSync-on p95 (16.947 ms) sits 2.1% over budget by display arithmetic; `project.godot` sets no override | Medium | Medium | Escalate to technical-director / godot-specialist as an explicit decision, not an implicit engine default |
| **M02's ~10-day budget vs. four clusters** — the deferred pile grew across M01 | **High** | Medium | Scope-negotiate at M02 planning; Cluster C is the named lever. Re-baseline in **stories/sessions**, not agent-days |
| **No QA sign-off artifact exists for any sprint** — Production → Polish gate requires one | High | Medium | Run `/team-qa sprint` at M02 S1 and every sprint after |
| **No external playtest yet** (M01 stretch goal, unspent) | Medium | Medium | Schedule 1–2 silent walkthroughs before M02 scope lock — the slice's affordance gaps (door-gap) were only ever found this way |
| **Entity inventory / asset-spec still pending** (M01 stretch, unspent) | Medium | Low-Med | Blocks asset scale-up, not the loop. Assign to art-director early in M02 |

---

## Action Items

| # | Action | Owner | When |
|---|---|---|---|
| 1 | Ratify (or overturn) the CD Scope Ruling 2026-07-25 — condition C1 | user | before M01 close |
| 2 | Ratify the re-tune values quick-spec — condition C2 | user | before M01 close |
| 3 | Run the C3 session: `villager_unstuck` window observation + human build-and-inhabit demo, both to `production/qa/evidence/` | producer + specialists | before M01 close |
| 4 | Decide #9 disposition (Valley wiring + golden-hour capture, or ratify Sub-A-present) — condition C4 | user / godot-specialist | before M01 close |
| 5 | Run `/team-qa sprint` for Sprint 8 and adopt it as a standing per-sprint step | qa-lead | M01 close or M02 S1 |
| 6 | Re-baseline M02 in stories/sessions rather than agent-days; negotiate Cluster C scope | producer | M02 planning |
| 7 | Escalate the VSync-mode decision and define the mid-range hardware baseline | technical-director | M02 S1 |


---

## Addendum — Conditions C3 & C4 executed (2026-07-26, parent-verified)

**C4 — ambient visible in the build**: TorchFlicker + AmbientTorchLight are now real hosted Valley
children, boot-gated through the injected tier (commit b52df18); golden-hour capture taken from the
REAL game_world.tscn (2 PNGs in production/qa/evidence/). Honestly NOT wired: chimney smoke, interior
clutter, foliage sway — each needs an occupancy/room/vegetation host that does not exist yet (Valley
boots an empty grid). **Criterion #9 disposition: the "visible in the build" clause is now satisfied
for the components that have a real host; Sub-B and the remaining three components stay M02 work.**

**C3 — telemetry observation**: harness added (advisory tier) plus the run.
- Adversarial (story-016 sealed-room fixture, production defaults): watchdog fires 2, recoveries 2,
  search-failed 0, permanent stuck 0 — the positive proof clause 3 asked for.
- Natural (15 villagers, 600 ticks): **found a real defect the test suite could not see** — every
  builder self-sealing on its own final cell stayed permanently distressed (permanent stuck = 15),
  because its own "Cell Built" transition left Working the same tick the seal became true, so the
  watchdog counter never reached threshold. **Fixed** (commit 7dff4a8, root-caused, two BLOCKING
  regression tests added): the self-sealed sub-condition is now rescue-eligible in every state while
  the walled-in-but-standable sub-condition stays Traveling/Working-scoped.
- **After the fix**: permanent stuck 15 -> 0, fires 79, recoveries 79, search-failed 0 — and built
  cells rose 15 -> 79, since freed builders keep building. Adversarial scenario unchanged.

**Criterion #13 disposition: clause 3 is now SATISFIED** (observed, not merely unit-tested), and the
observation earned its keep by surfacing a defect that every green suite had missed.

Suite at addendum time: 953/953, 0 orphans, exit 0.

### Remaining to declare M01 CLOSED (user-owned)
1. **C1** — ratify (or overturn) the CD Scope Ruling 2026-07-25 (scopes #6/#7/#9).
2. **C2** — ratify the re-tune values quick-spec 2026-07-25 (#4's numbers).
3. **C3 human half** — the build-and-inhabit demo walkthrough: a person draws a walled/floored/roofed
   room, workers build it, a villager moves in.

Nothing else is outstanding on the development side.
