# Task Estimate: MVP Implementation Re-Baseline

> **Generated**: 2026-07-23
> **Trigger**: Gate-check blocker #2 — "re-baseline the estimate with slice velocity"
> (`production/gate-checks/2026-07-23-pre-production-to-production.md`); slice REPORT
> "Next steps" seed the sprint plan with measured velocity.
> **Supersedes**: `production/estimates/estimate-mvp-baseline-2026-07-11.md` (38d, UNCALIBRATED).
> **Status**: First CALIBRATED baseline — grounded in 5 measured build days of the
> vertical slice (`prototypes/last-seal-vertical-slice/REPORT.md`).

## Task Description

Re-estimate the 11 MVP systems (production rewrite, from scratch) to the first playable
integrated build, using the velocity actually measured during the vertical slice instead
of the uncalibrated stories/day assumption the 38d baseline was built on. Same scope
boundary as the old baseline (MVP set only), plus the two Creative-Director-protected
early items and the three tracked tech-debt stories now scheduled into early Production.

## What Changed Since the 38d Baseline

The 38d figure (2026-07-11) was explicitly labelled "NO historical velocity data exists
yet" and used an **uncalibrated ~3-4 stories/day** assumption. The slice has now produced
real velocity data. The unit of measure also changed:

| | Old baseline (2026-07-11) | This re-baseline (2026-07-23) |
|---|---|---|
| Velocity unit | ~3-4 stories/day (assumed) | ~1 feature package/day incl. tests (**measured**) |
| Integration cost | 1-2 blockers of ~1 day each; 4 "delicate seams" as HIGH risk | 11 modules integrated in **1 day** via CONTRACTS.md (**measured**) |
| Wiring/rework | not separated | **+20%** on feature work; ~1 day/week for crash-class + wiring gaps (**measured**) |
| UI cost | Presentation budgeted as blocked-on-UX, expensive | UI packages **same cost as logic** (programmatic HUD) (**measured**) |
| Confidence | Medium (zero velocity data) | **High** on velocity; Medium on production-quality delta |

## The Measured Velocity (assumption set for this estimate)

All figures below assume the workflow that produced the slice data, and are only valid
while these hold:

1. **Agent-driven development** — one specialist agent drives one ~1-day feature package
   to a hard verification gate; packages split to ~1 day each (long packages stall and
   need continuation nudges — slice Lessons Learned).
2. **Headless test gate** — a GdUnit4 headless E2E/LOOP test runs as a commit gate and
   catches every *logic* regression. It does **not** catch wiring/visual/UX gaps — those
   surfaced only from the human tester and are the source of the +20% wiring overhead.
3. **Contracts-file integration pattern** — a central CONTRACTS.md lets parallel agents
   integrate many modules in ~1 day; every later contract addition needs the same
   discipline or a wiring gap reaches the tester.
4. **Production quality bar (NEW vs slice)** — the slice ran at relaxed prototype standards
   (hardcoded values, singletons OK, `CULL_DISABLED`, no data-driven config). Production
   demands data-driven config, DI-over-singletons, blocking unit tests per logic AC, doc
   comments, and ADR compliance. This delta is the main reason a production package is not
   cheaper than a slice package despite the faster measured velocity.

**Unit**: one focused solo+AI working day. Calendar time depends on real session frequency
(the slice's 5 build days spanned 11 calendar days with a gap).

## Effort Estimate

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | 26 | Parallel agents fully effective; CW mesher rewrite lands in one pass; no crash-class recurrence; external playtest surfaces no rework |
| **Expected** | **32** | Measured ~1 pkg/day + 20% wiring; one review round per system; CW rewrite + per-tick retune as planned; 1-2 wiring gaps caught late |
| Pessimistic | 42 | Production quality bar bites (property-corpus friction, data-driven refactors), mesher rewrite needs a second pass, Godot 4.7 API gaps, external playtest forces affordance rework |

**Recommended budget: 32 days** (expected), down from the 38d uncalibrated figure (**−16%**).

## Category Breakdown (comparable to the 38d baseline's categories)

Packages are ~1 day each incl. tests; "+20%" = wiring/rework overhead on feature work
(integration-to-playable is counted at 1 measured day, NOT ×1.2).

| # | Category | Old (d) | New pkgs | New (d, +20%) | Delta driver |
|---|----------|---------|----------|----------------|--------------|
| 1 | Boot/DI/config foundation (ADR-0001/0002/0005/0006) + test harness + CONTRACTS.md | 3 | 3 | 3.6 | ~flat |
| 2 | Foundation systems (Scene/World, Time & Tick, Resource DB, Camera, Voxel World) **+ mesher CW-winding rewrite + per-tick re-tune + ADR-0015 C1/C4 tuning** | 14 | 7.5 | 9.0 | Tightened by measured velocity; widened by 3 added tech-debt stories |
| 3 | Core (Building System, Villager AI) | 12 | 7 | 8.4 | Tightened — slice proved projects/AI/anti-stuck at ~1 pkg/day each |
| 4 | Feature (Build Validation + property corpus, Needs & Mood) | 7 | 3 | 3.6 | Tightened |
| 5 | Presentation (Building UI, Villager Info UI) | 6 | 2.5 | 3.0 | **Most tightened** — UI = logic cost (programmatic HUD) |
| 6 | Integration-to-playable (1d) + **ambient-life wave 1** + **loop-payoff communication** + smoke/external playtest | 3 | 4 | 4.6 | Integration tightened DOWN (1d proven); widened by 2 CD-protected items |
| | **Total** | **38** | **27** | **~32** | |

The three tech-debt stories the gate scheduled into early Production are folded into
category 2 explicitly: **mesher CW-winding rewrite + culling re-enable** (~1 pkg — the
slice shipped on `CULL_DISABLED`, 2× faces, with headroom to spare), **per-tick re-tuning
pass** (~0.5 pkg), and **ADR-0015 C1/C4 residency tuning** (~1 pkg). The two CD-protected
items (**ambient-life wave 1**, **loop-payoff communication scaffolding**) are new scope
vs the old baseline — they are the reason category 6 grew despite integration getting
cheaper.

## Where the Slice Evidence TIGHTENS the Range

- **Integration risk retired.** The old baseline's single biggest fear — the "4 delicate
  seams" (input arbitration, occupancy ordering, boot gate, tick contracts) surfacing late
  as HIGH-impact rework — is answered: 11 modules integrated in 1 day via CONTRACTS.md,
  E2E green on every commit. This removes the largest tail from the pessimistic case.
- **Velocity is now measured, not assumed.** The dominant risk on the 38d baseline
  ("velocity assumption uncalibrated — High likelihood") is closed.
- **UI is cheap.** Presentation dropped from 6d to ~3d because the programmatic HUD makes
  UI packages cost the same as logic packages; UI is no longer gated on separate UX-spec
  turnaround for the core loop.
- **Net effect on the range**: the spread narrows from **25-55d (30d spread)** to
  **26-42d (16d spread)**. The floor barely moves (you cannot beat ~1 pkg/day); the ceiling
  drops because the scariest unknowns are retired.

## Where the Slice Evidence WIDENS or Adds

- **Production-quality delta over slice standards.** The slice took five deliberate
  shortcuts (CW winding, no save/load, no resource costs, no streaming, doors-as-gaps).
  For the MVP specifically, save/load and resource costs are out of MVP tier, but the
  **CW mesher rewrite** and **data-driven/DI/blocking-test discipline** are real added cost
  the slice did not pay — this keeps a production package from being cheaper than a slice
  package.
- **Recurring crash class.** GDScript typed-Array params on untyped caller paths caused 3
  incidents in 5 days. Budgeted inside the +20% wiring overhead; keep the regression call
  in the E2E gate.
- **Two CD-protected items added** (~2 pkg): ambient-life wave 1 and loop-payoff
  communication were not in the 38d MVP scope.
- **Thin playtest depth.** 1 internal tester only; the pessimistic case carries affordance
  rework (e.g. the door-gap discoverability gap) that 1-2 external walkthroughs may surface.

## Confidence: High (velocity) / Medium (quality delta)

Velocity confidence is now **High** — it is measured across 5 build days on this exact
codebase, workflow, and engine, integrating the same 11 systems. The residual uncertainty
is **Medium** and concentrated in one place: how much more expensive the *production*
quality bar is than the *slice* quality bar (blocking test corpus, data-driven config, DI,
the CW rewrite). That delta is what separates the 32d expected from the 42d pessimistic.

## Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Production quality bar costs more than slice standards did | Medium | Medium | Sequence boot/DI/config + test harness FIRST (category 1) so the quality scaffolding exists before feature work; property corpus as its own story (<=60s CI) |
| CW mesher rewrite needs a second pass | Medium | Low-Medium | Do it early, before asset scale-up (gate condition); slice proved the geometry, only the winding/culling flips |
| Recurring typed-Array crash class | Medium | Low | Regression call already in the E2E gate; keep preview path deliberately untyped (slice Lessons Learned) |
| Late wiring/UX gaps (E2E cannot catch them) | Medium | Low-Medium | +20% wiring overhead budgeted; run 1-2 external silent-walkthroughs before scope lock |
| Godot 4.7 API deviations beyond LLM cutoff | Medium | Low-Medium | Check `docs/engine-reference/godot/` before every API use (existing rule) |

## Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|
| Control-manifest refresh (gate blocker #1) | Pending | Stories embedding stale manifest risk rework — do before first story |
| Main-menu + pause-menu UX specs (gate blocker #4) | Pending | Blocks only menu stories, not the core-loop MVP packages |
| Epics + stories created (gate blocker #3) | Pending | Prerequisite for sprint planning; does not change the day count |
| External playtest (CD + slice recommendation) | Optional pre-lock | Surfaces affordance rework that lands in the pessimistic case |

## Notes and Assumptions

- Scope boundary: the MVP set ONLY, plus the two CD-protected early items and the three
  tracked tech-debt stories. Vertical-Slice-tier systems (save/load, audio, combat, wave
  defense) are NOT included.
- Slice code is reference only — production is written from scratch (never imported).
- A "day" is one focused solo+AI working day; calendar time depends on session frequency.
- This estimate is the input to `production/milestones/milestone-01-foundation-core.md`,
  whose duration is the Foundation + Core + integration + CD-items subset of category 1-3
  and part of category 6 (~22 expected working days of this 32-day total).
