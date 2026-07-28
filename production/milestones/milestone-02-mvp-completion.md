# Milestone: 02 — MVP Completion (The Loop Pays Off)

## Overview

- **Target Date**: nominal window **2026-07-27 → 2026-08-07** (advisory — see Duration)
- **Type**: Production (second and final Production milestone of the MVP; follows M01's
  GO WITH CONDITIONS verdict, `production/milestones/milestone-01-review-2026-07-26.md`)
- **Duration**: **~5 sprints / ~52–58 stories** (S09–S13). Expressed in **stories and
  sprint-sessions**, NOT agent-days — see Notes for why the inherited "~10 working days"
  figure is retired.
- **Number of Sprints**: 5 planned (S09, S10, S11, S12, S13), sized by `/sprint-plan`

## Milestone Goal

Complete the MVP. M01 proved the *forward* loop mechanically — the player draws a
building, workers build it, villagers navigate it without getting stuck. M02 owes the
three things the player actually *feels*: the **payoff** (a villager needs shelter, moves
into the room you built, and recovers there — the mechanic behind M01's warm-light
scaffolding, which today signals nothing real), the **settlement answering back** (idle
life, ambient motion in the composed frame, and a UI to read the settlement through), and
the **reverse verbs** (change your mind, tear it down). At the end, the concept's core
hypothesis — *"is drawing a room, furnishing it, and watching a villager live there
satisfying?"* — is testable by a human being for the first time.

---

## Success Criteria

The milestone is complete ONLY when all of these are met. Each is independently
verifiable against the named evidence path.

- [ ] **1. Build Validation & Navigability implemented** — room detection (roofed +
      floored + walkable-to-outside), region formation/split/merge, sealed-space warnings,
      and shelter classification, event-driven and never per-frame. Every Logic AC from
      `design/gdd/build-validation-navigability.md` (AC1–AC35, AC37, AC38) has a passing
      blocking test.
      *Evidence*: `neues-spiel/tests/unit/build_validation/` + `neues-spiel/tests/integration/build_validation/` (green headless, 0 orphans)

- [ ] **2. The reachability property corpus is green and in CI** — build-validation AC36:
      100 checked-in seeds × 50 sampled (start, target) pairs = 5,000 verdicts, this
      system's reachability agreeing with Villager AI's pathfinder on every one, total
      corpus runtime **≤ 60 s** in CI. This is the guard against two independent
      implementations of the movement rules drifting apart.
      *Evidence*: `neues-spiel/tests/integration/build_validation/reachability_property_corpus_test.gd` + recorded runtime in `production/qa/evidence/`

- [ ] **3. Needs & Mood implemented** — per-tick decay (F1), the three-rung recovery
      ladder (F2: `ground_penalty` < `unsheltered_bed_multiplier` < 1.0, table-driven by
      source enum, no hardcoded two-source branch), mood smoothing (F3), spawn init (F4),
      edge-triggered urgent/satisfied signals, and the **blocking** config-load invariant
      (AC29). Every Logic AC in `design/gdd/needs-mood-system.md` except the two
      Save/Load-deferred (AC24, AC25) has a passing blocking test.
      *Evidence*: `neues-spiel/tests/unit/needs_mood/` (green headless)

- [ ] **4. The real-time-rate pass is recorded** — the `ticks_per_second` 2.0 → 4.0 change
      doubled the real-time meaning of every downstream per-tick rate. Needs & Mood is the
      system that inherits it. Every rate in the Needs & Mood Tuning Knobs table has a
      stated real-time equivalent at `ticks_per_second = 4.0`, and the GDD's pacing
      cross-reference (~9 min to urgent; the deliberate ~6–7 min build-to-urgency gap) is
      either **confirmed** at the new rate or **retuned with rationale**. Resolved as part
      of Cluster A, not after it.
      *Evidence*: `design/quick-specs/needs-mood-real-time-rate-pass-2026-07-XX.md` + `design/gdd/time-tick-system.md` Open Question closed + `design/gdd/needs-mood-system.md` knob table updated

- [ ] **5. The payoff loop closes end-to-end, live-pair, no mocks at the seam** — a REAL
      Needs instance and a REAL villager with an owned **sheltered** bed: decay from 100 →
      urgent → claim → travel → sleep → recover at the sheltered rate → satisfied → wake,
      with both events observed in order (needs-mood AC34 + villager-ai-018 AC22–AC27).
      **This is the milestone's reason to exist** — the criterion that makes shelter mean
      something mechanically.
      *Evidence*: `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` + a run-level capture in `production/qa/evidence/`

- [ ] **6. Furniture is placeable, buildable, and claimable** — the player places a bed
      (RID `furniture_fixture`, tier-0 free, support-required), workers build it, a
      villager claims it as the move-in moment, and removing it dissolves ownership and
      wakes the sleeper. Without this criterion, criterion #5 has no bed to happen in.
      *Evidence*: `neues-spiel/tests/unit/building_system/` (furniture placement/multi-cell/demolition) + `neues-spiel/tests/integration/villager_ai/` (bed claim/revocation)

- [ ] **7. `presentation-002`'s scaffolding signals something real** — the loop-payoff
      warm-light/cue surface fires off the genuine `room_recognized` (with the
      `celebrate` / `pass_group_id` pacing contract) and `shelter_status_changed`
      emissions, not a stub. A grep-guard proves no placeholder emitter remains on the
      payoff path.
      *Evidence*: `neues-spiel/tests/integration/presentation/loop_payoff_real_signal_test.gd` + `production/qa/evidence/loop-payoff-wired-evidence-*.md`

- [ ] **8. Ambient life wave 1 is complete IN the composed Valley** — the three components
      the M01 addendum honestly recorded as unwired (chimney smoke, interior clutter,
      foliage sway) now have real hosts and are visible in `game_world.tscn`, plus the
      four CD advisories that gate the *warmth read*: golden-hour re-shoot at integration
      (advisory #2), foliage hue in Material-family greens/browns (#3), torch color locked
      to Hearth Gold with no State-Orange drift (#4), and the **Dusk Test (§7.1) +
      Horizon Test (Principle 4)** both executed (#7).
      *Evidence*: `production/qa/evidence/ambient-life-wave-1-evidence.md` (advisory closure section + golden-hour/Dusk/Horizon PNGs)

- [ ] **9. The "world lacks life" finding is formally CLOSED by the Creative Director** —
      `villager-ai-019` idle/wandering micro-behaviors landed, unblocking
      `presentation-001` **Sub-scope B** (the CD's stated highest-mood-value-per-cost
      item). CD ruled at the wave-1 sign-off that the slice debrief's #1 finding stays
      OPEN until Sub-B lands; this criterion is met only on a written CD close, not on
      Sub-B's tests passing.
      *Evidence*: `production/qa/evidence/ambient-life-wave-1-evidence.md` (CD close entry, dated) + `neues-spiel/tests/unit/villager_ai/` (019 idle behaviors)

- [ ] **10. Building UI and Villager Info UI ship as real UX-spec'd systems** — M01 shipped
      minimal interaction only. This is the build-editor mode, the tool/palette surface,
      **ghost preview feedback while drawing** (`building-023` — today the player draws
      blind), project state readout, and the villager panel showing need values, mood band,
      and the why-string (consumed verbatim from Needs & Mood's Core Rule 11 templates).
      *Evidence*: `production/qa/evidence/` manual walkthrough docs (ADVISORY per testing standards) + `neues-spiel/tests/unit/ui/` interaction tests where logic exists

- [ ] **11. Lifecycle breadth — demolition at minimum** — the player can tear down what
      they built: worker-executed block demolition with `restore_value` write-back,
      the removal tool, the draft eraser branch, and block remove-mode. Ranked first in
      Cluster C because players reach for tear-down before any other reverse verb.
      *Evidence*: `neues-spiel/tests/unit/building_system/` (009/031/015/027-remove) + `neues-spiel/tests/integration/building_system/`

- [ ] **12. Plan-only undo is real** — `building-011`. M01's criterion #6 named "plan-only
      undo" as-written; only the undo/redo *stack core* (`032`) landed. Undo must never
      mutate a Built cell.
      *Evidence*: `neues-spiel/tests/unit/building_system/plan_only_undo_test.gd` + the existing non-writer grep-guard extended to the undo path

- [ ] **13. A mid-range hardware baseline exists and is measured** — M01 criterion #12
      PASSed on an **RX 7900 XT**; the project has **no verified mid-range claim** behind
      the 21.3% headroom figure. Define the target hardware class as an explicit decision,
      then re-measure using `vox-018`'s tool verbatim (windowed, culling ON, VSync OFF for
      true compute). **Separately, the VSync-mode decision is unowned** — `project.godot`
      sets no override; escalate to technical-director and record it.
      *Evidence*: `production/qa/evidence/voxel-world-60fps-midrange-baseline-*.md` + a `docs/architecture/` ADR or quick-spec recording the hardware class and the VSync decision with an owner

- [ ] **14. Quality and process gates hold** — 0 open S1/S2; full blocking suite green
      headless with **0 orphans on every commit**; E2E LOOP green on every commit; and a
      **`/team-qa sprint` sign-off report exists for every M02 sprint** (APPROVED or
      APPROVED WITH CONDITIONS). No such artifact exists for *any* of S1–S8 — this is a
      standing Production → Polish gate blocker, and M02 is where the habit starts.
      *Evidence*: `production/qa/qa-signoff-sprint-[09..13].md` + `production/qa/smoke-*.md` + CI record

---

## The Cluster Shape — honest sizing

Sizing is in **stories** and **serial chains**, per the M01 review's own re-baseline
instruction. "New" means the story file does **not exist yet** and must be produced by
`/create-stories` (see Missing Stories). "Exists" means a `Status: Ready` story file was
verified on disk 2026-07-26.

### Cluster 0 — Loop-completion residue (NOT deferred — simply never scheduled) ⚑ NEW FINDING

The CD scope ruling (2026-07-25) deferred a *named* list: `006/007/008/009`, furniture
`016/017/028`, dig `013/014`, Abriss `010`, tool-batch `018`, removal `031/015`,
`villager-ai-013`. These six stories are **not on that list** and were never scheduled in
S1–S8. They are unfinished M01-adjacent work, not deferrals, and three of them are
directly loop-facing.

| Story | Why it matters | Status |
|---|---|---|
| `building-023` ghost-preview rendering | **The player currently draws blind.** No ghost/preview implementation exists in `neues-spiel/src/` (verified by search). All four M01 drawing verbs shipped without placement feedback | Exists, Ready |
| `building-001` build editor mode | The mode the tool palette and Building UI live inside — a Cluster D prerequisite | Exists, Ready |
| `villager-ai-021` starting roster spawn | **The Valley boots with no villagers.** M01's addendum confirms an empty grid; the C3 telemetry run had to spawn its own | Exists, Ready |
| `building-011` plan-only undo/redo | Criterion #12 above; named as-written in M01 criterion #6 | Exists, Ready |
| `building-012` floor-excavation restore-value | The write-back demolition (`009`) depends on for correctness | Exists, Ready |
| `villager-ai-023` scene-transition continuity | Villager state across the transition contract | Exists, Ready |

**Size: 6 stories, all existing. Sequence FIRST in S09** — `023` and `021` in particular
change what every later playtest and UI story is being evaluated against.

### Cluster A — The payoff mechanic (**PROTECT** — the milestone's reason to exist)

⚑ **Producer correction to the M01 review's sketch**: that sketch filed furniture
(`016/017/028`) under Cluster C's "lower tier". **That is wrong and would have broken the
milestone.** The payoff is *shelter → recovery*, and recovery's headline rung is a bed:
needs-mood AC34 requires a real villager sleeping in an **owned sheltered bed**, and
villager-ai-018 states plainly that *claiming a bed IS the move-in moment*. Furniture is
Cluster A's spine, not Cluster C's tail. It is re-homed here and inherits PROTECT.

| Item | Stories | Status |
|---|---|---|
| Build Validation & Navigability epic | ~9 **new** (38 ACs, incl. the AC36 property corpus as its own story) | **No epic, no stories** |
| Needs & Mood epic | ~8 **new** (35 ACs) | **No epic, no stories** |
| Furniture chain: `building-028` base → `016` multi-cell → `017` demolition | 3 existing | Ready |
| `villager-ai-018` sleep & home / bed claim (Integration) | 1 existing | Ready |
| Real-time-rate pass (criterion #4) | 1 **new** quick-spec + config story | Missing |

**Size: ~22 stories (17 new, 5 existing). Two serial chains**: `build-validation → needs-mood → live-pair AC34`, and `furniture-028 → 016 → villager-ai-018 → AC34`. Both converge on criterion #5. **This is ~2 sprints on its own.**

### Cluster B — Life (**PROTECT** — CD-protected, closes the oldest open finding)

| Item | Stories | Status |
|---|---|---|
| `villager-ai-019` wandering/idle micro-behaviors | 1 existing | Ready |
| `presentation-001` Sub-scope B (gated on 019) + golden-hour re-shoot + Dusk/Horizon tests | sub-scope of 1 existing | Sub-A Complete |
| `villager-ai-013` nudge-aside (CD's named pull-forward trigger is precisely the `013`+`019` seam) | 1 existing | Ready |
| `villager-ai-020` breather beat | 1 existing | Ready |
| Ambient host wiring (smoke → occupancy, clutter → furniture, foliage → vegetation) | folded into Cluster A's hosts + Sub-B | — |

**Size: ~4 stories, all existing.** Cheapest cluster by far, highest mood value per cost
by the CD's own ranking. **Note the synergy**: Cluster A *creates* the hosts the three
unwired ambient components need — room recognition (occupancy for smoke) and furniture
placement (interior clutter). Scheduling A before B is not just dependency order, it is
what makes B cheap.

### Cluster C — Lifecycle breadth (**THE CUT LEVER**)

Ranked by player expectation. Everything here is an existing `Ready` story.

| Tier | Items | Stories |
|---|---|---|
| C1 — least cuttable | `building-009` demolition, `031` removal-tool base, `015` draft-eraser branch, `027` remove-mode | 4 |
| C2 | `building-007` change orders | 1 |
| C3 | `building-006` pause/resume, `building-008` click-selection | 2 |
| C4 — lowest | `building-010` Abriss, `018` tool-batch, `013`/`014` dig-mining, `villager-ai-017` dig on-site exclusion | 5 |

**Size: up to 12 stories, all existing.** C1 is protected by criterion #11. C2–C4 are the
lever (see Cut-Lever Policy).

### Cluster D — Presentation layer

| Item | Stories | Status |
|---|---|---|
| Building UI epic (979-line GDD — the largest single design doc in the project) | ~9 **new** | **No epic, no stories** |
| Villager Info UI epic (368-line GDD) | ~5 **new** | **No epic, no stories** |
| Main-menu / pause-menu UX specs (pre-production gate blocker #4) | authored in parallel, not gated by the loop | Missing spec |

**Size: ~14 stories, all new.** Hard-depends on Cluster A (Villager Info UI consumes
Needs & Mood values, mood band, and why-string verbatim) and on Cluster 0's
`building-001`/`023`. **Cannot start before Cluster A lands** — this is a sequencing fact,
not a preference.

### Cluster E — Platform, hardware, and process hygiene

| Item | Stories | Status |
|---|---|---|
| Mid-range hardware baseline re-measurement (criterion #13) | 1 **new** (voxel-world epic; `vox-018`'s tool reusable verbatim) | Missing |
| VSync-mode decision (unowned) | decision + ADR/quick-spec, technical-director | Missing |
| `/team-qa sprint` sign-off, every sprint (criterion #14) | process, qa-lead | Standing |
| 1–2 external silent-walkthrough playtests (M01 stretch, unspent) | process, producer | Missing |
| `/asset-spec` entity inventory (M01 stretch, unspent) | art-director | Missing |

**Size: ~2 stories + 3 process/decision items.**

### Roll-up

| Cluster | Stories | New | Existing | Disposition |
|---|---|---|---|---|
| 0 — loop residue | 6 | 0 | 6 | Sequence first |
| A — payoff | ~22 | 17 | 5 | **PROTECT** |
| B — life | ~4 | 0 | 4 | **PROTECT** |
| C — lifecycle breadth | up to 12 | 0 | 12 | **CUT LEVER** (C1 protected) |
| D — presentation UI | ~14 | 14 | 0 | Trim second |
| E — platform/process | ~2 | 2 | 0 | Criterion #13 protected |
| **Total (full)** | **~60** | **33** | **27** | |
| **Total (committed, C trimmed to C1, D trimmed)** | **~48–52** | | | Planning target |

---

## Missing Stories — input for `/create-stories`

**33 of ~60 stories do not exist.** These must be authored before the sprints that
schedule them. All four systems below have **APPROVED GDDs** and **no epic** —
`production/epics/index.md` states plainly that their epics are created when the layer is
approached (`/create-epics layer: feature`). That is now.

| # | Epic to create | Source GDD | Approx. stories | Blocks |
|---|---|---|---|---|
| 1 | **build-validation-navigability** (Feature) | `design/gdd/build-validation-navigability.md` (38 ACs) | ~9 — incl. **one dedicated story for the AC36 property corpus** (100 seeds / 5,000 verdicts / ≤60 s CI; the single riskiest test artifact in the MVP) | Criteria #1, #2, #5, #7 |
| 2 | **needs-mood-system** (Feature) | `design/gdd/needs-mood-system.md` (35 ACs) | ~8 — decay/signals, recovery ladder, mood smoothing, spawn init, config invariant (AC29 blocking), why-string templates, burst/warp determinism, live-pair AC34 | Criteria #3, #4, #5 |
| 3 | **building-ui** (Presentation) | `design/gdd/building-ui.md` (979 lines) | ~9 | Criterion #10 |
| 4 | **villager-info-ui** (Presentation) | `design/gdd/villager-info-ui.md` (368 lines) | ~5 | Criterion #10 |

Plus two standalone stories in existing epics:

| # | Story | Epic | Blocks |
|---|---|---|---|
| 5 | Real-time-rate pass for Needs & Mood at `ticks_per_second = 4.0` | needs-mood-system (or time-tick-system) | Criterion #4 |
| 6 | Mid-range hardware baseline re-measurement | voxel-world | Criterion #13 |

**Not a story — a decision** (do not let these be written as stories): the **VSync-mode**
call (owner: technical-director) and the **target hardware class** definition (owner:
technical-director, input from producer). Both are inputs to criterion #13's story, not
substitutes for it.

**Also missing, non-blocking**: main-menu / pause-menu UX specs (`design/ux/`), the
`/asset-spec` entity inventory (`design/assets/entity-inventory.md`).

---

## Out of Scope (Explicitly NOT Milestone 02)

- **Roof formations beyond Flat** (Gable / Hip / Shed) — VS-tier reserve. `building-026`
  shipped Flat MVP and that is the MVP bar unless the Creative Director pulls them forward.
- **Save/Load & World Persistence** — VS-tier. Consequently needs-mood **AC24/AC25** and
  build-validation **AC26** stay explicitly deferred and are excluded from criteria #1/#3;
  `villager-ai-024` stays unscheduled.
- **Doors and windows as objects** — VS-tier. Build Validation's Open Question 1 (should a
  valid room require wall enclosure — the "cozy carport") is a **VS decision**, not an M02
  one. MVP accepts the carport.
- **Wall coverage requirement / mechanically meaningful walls** — same VS decision.
- **Audio, resource economy and costs, professions, relationships, combat, wave defense,
  township progression, onboarding** — VS-tier or later per `design/gdd/systems-index.md`.
- **Mood consequences** (work speed, breaks, celebration) — Needs & Mood Rule 8 keeps mood
  display-only in MVP; the seam is reserved, not built.
- **Accessibility full pass** — Full Vision.

### The three M01 items still owned by the user — inbound dependencies, NOT M02 content

These are listed so nobody re-plans them as work. They are signatures and a demo:

1. **C1** — ratify (or overturn) the CD Scope Ruling 2026-07-25 (scopes M01 #6/#7/#9).
2. **C2** — ratify the re-tune values quick-spec 2026-07-25 (M01 #4's numbers).
3. **C3 human half** — the build-and-inhabit demo walkthrough (a person draws a
   walled/floored/roofed room, workers build it, a villager moves in).

**If C1 is overturned toward as-written M01 breadth**, Cluster C stops being a cut lever —
it becomes M01 rework and pre-empts roughly one M02 sprint. That risk is in the register.

---

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Crash rate | 0 known S1 crash classes open (incl. typed-Array regression) | Regression call in headless E2E gate |
| Frame rate | ≥ 60 FPS with culling ON — **and a measured mid-range figure**, not an RX 7900 XT figure | `vox-018` tool, windowed, VSync OFF for true compute |
| Critical bugs | 0 open S1 | Bug tracker |
| Major bugs | 0 open S2 | Bug tracker |
| Logic test coverage | Blocking unit test per Logic AC | GdUnit4 headless report |
| Property corpus | Reachability corpus green, **≤ 60 s** in CI | CI timing record |
| Integration | E2E LOOP green on every commit; 0 orphans on every commit | CI gate |
| **QA sign-off** | `/team-qa sprint` report per sprint — **the M01 gap** | `production/qa/qa-signoff-sprint-NN.md` |
| Visual/Feel | CD sign-off on ambient wave-1 advisories + Sub-B | ADVISORY, `production/qa/evidence/` |

---

## Risk Register

| # | Risk | Probability | Impact | Mitigation | Owner | Status |
|---|------|------------|--------|-----------|-------|--------|
| R1 | **The ~10-working-day inherited budget vs. ~60 stories of real scope.** The 32-day MVP re-baseline priced M02 at ~10 agent-days ≈ ~10 stories. Actual scope is ~6× that | **High** | Medium | Budget replaced with a story/sprint baseline in this file. Cluster C is the named lever; policy below. Re-check at every sprint close | producer | **Open — mitigated by this document** |
| R2 | **Two brand-new epics (build-validation, needs-mood) carry 73 ACs between them and have zero stories today.** Sprint 1 cannot schedule what does not exist | **High** | High | Run `/create-epics layer: feature` then `/create-stories` for both **before S09 planning closes**. Treat as a gate on S09, not as S09 content | producer | Open |
| R3 | **Build-validation AC36's property corpus is the riskiest single test artifact in the MVP** — 5,000 cross-implementation verdicts under a 60 s CI ceiling, guarding against pathfinder/validator divergence | Medium | High | Own story, sequenced early in Cluster A (a late failure here means one of two *shipped* implementations is wrong). Time-box; if the ceiling is missed, reduce sampled pairs before reducing seeds | technical-director | Open |
| R4 | **No verified mid-range hardware baseline** — M01 #12 PASSed on an RX 7900 XT; the 21.3% headroom figure is not a mid-range claim, and the whole MVP performance story rests on it | Medium | **High** | Criterion #13. Define the hardware class as an explicit decision, re-measure with `vox-018`'s tool verbatim, early in M02 — not at the milestone gate | technical-director | Open |
| R5 | **The VSync-mode decision is unowned** — VSync-on p95 (16.947 ms) sits ~2.1% over budget by display arithmetic; `project.godot` sets no override, so the shipped behavior is an implicit engine default | Medium | Medium | Escalate to technical-director as an explicit, recorded decision. Bundle with R4's measurement story | technical-director | Open |
| R6 | **The `ticks_per_second` 2.0 → 4.0 caveat is inherited by Needs & Mood** — every per-tick rate's real-time meaning doubled, and Needs & Mood is *entirely* per-tick rates (decay, recovery, mood smoothing). Shipping the GDD defaults unexamined ships a pacing bug | **High** | Medium | Criterion #4 makes the pass a milestone gate, resolved *inside* Cluster A. The GDD's own pacing cross-reference (~9 min to urgent) is the acceptance anchor | systems-designer | Open |
| R7 | **No `/team-qa sprint` sign-off artifact exists for ANY sprint (S1–S8)** — a standing Production → Polish gate blocker. Not an M01 blocker; it becomes one later | **High** | Medium | Criterion #14. Run `/team-qa sprint` at S09 close and every sprint after. Retro-run for S8 if cheap | qa-lead | Open |
| R8 | **No external playtest has ever been run** (M01 stretch, unspent). The slice's affordance gaps — the door-gap — were only ever found this way, and M02 is the milestone where the *hypothesis itself* is finally testable | Medium | **High** | Schedule 1–2 silent walkthroughs **after criterion #5 lands** (that is the first moment the loop pays off) and before the milestone gate. Feed findings into Cluster D | producer | Open |
| R9 | **The CD ruling is still unratified** (M01 condition C1). If overturned, Cluster C converts from cut lever to mandatory M01 rework | Medium | High | Surfaced in the Out-of-Scope section as an inbound dependency. If overturned, re-plan M02 with C1+C2 tiers as Must and drop Cluster D's Villager Info UI to the trim line | user / producer | Open (inbound) |
| R10 | **Cluster D hard-depends on Cluster A and cannot be parallelized against it** — Villager Info UI consumes Needs & Mood values, band, and why-string verbatim; Building UI needs `building-001`/`023`. A Cluster A slip pushes Cluster D one-for-one | Medium | Medium | Sequence Cluster 0's `building-001`/`023` in S09 so Building UI is unblocked independently of Needs & Mood; only Villager Info UI is truly A-gated | producer | Open |
| R11 | **Ghost preview (`building-023`) was never scheduled** — all four M01 drawing verbs shipped without placement feedback; every playtest until it lands is evaluating a blind-drawing UX | Medium | Medium | Cluster 0, sequenced in S09 before any external playtest (R8) | godot-specialist | Open |
| R12 | **`/asset-spec` entity inventory still pending** (M01 stretch, unspent) — blocks asset scale-up; also blocks the ambient advisories that require *real* art (foliage hue #3, prop palette #5) | Medium | Low-Med | Assign to art-director in S09. Note it gates criterion #8's advisory closure, so it is no longer purely a scale-up concern | art-director | Open |
| R13 | **Godot 4.7 API deviations beyond LLM cutoff** — M02 is UI-heavy (Control nodes, theming) and UI is a post-cutoff-change domain | Medium | Low-Med | Check `docs/engine-reference/godot/` before every API use — BLOCKING, as in M01 | godot-specialist | Open |

---

## Cut-Lever Policy

The lever is pulled in a fixed order, on a named signal, and never silently.

**Order of trimming:**

1. **Cluster C tier C4** (Abriss, tool-batch, dig-mining, dig on-site exclusion) — → VS-tier.
2. **Cluster C tier C3** (pause/resume, click-selection) — → VS-tier.
3. **Cluster C tier C2** (change orders) — → VS-tier.
4. **Cluster D — Villager Info UI reduced to a minimum-viable panel** (need bars + mood
   band + why-string; drop the rest of the UX spec).
5. **Cluster D — Building UI reduced to the tool palette + ghost feedback + project state.**

**Never cut without escalation:** Cluster A (any part, including furniture), Cluster B
(CD-protected — cutting requires **CD sign-off**, same protection M01's items carried),
Cluster C tier **C1** (criterion #11 — demolition is the reverse verb players reach for
first), Cluster 0, and criteria #13/#14.

**Signals that pull the lever:**

| Signal | Checked at | Action |
|---|---|---|
| Cluster A's build-validation + needs-mood stories are not both feature-complete, with criterion #5's live-pair test green | **End of S10** | Trim steps 1–2 (drop C4 and C3) |
| Criterion #5 still not green | **End of S11** | Trim step 3 (drop C2 — Cluster C reduces to C1 only) |
| Cluster D has not started by S12 | **Start of S12** | Trim steps 4–5 (both UIs to minimum viable) |
| Criterion #2's corpus exceeds the 60 s CI ceiling twice | any sprint | Reduce sampled pairs per seed before reducing seed count; escalate to technical-director if still over |
| CD ruling overturned (R9) | on ratification | Re-plan: C1+C2 become Must, drop trim steps 4–5 immediately |

**Anti-signal — do NOT pull the lever for these:** a sprint that lands fewer stories than
planned for *decision* reasons (pending ratification, unowned VSync call). M01's evidence
is unambiguous: every slip on this project came from blocked decisions, never from
capacity. Check which one it is before cutting scope.

---

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|
| Build Validation & Navigability | Building System completion signals ✓, Villager AI walkability/movement graph ✓ | (M01, landed) | Satisfied |
| Needs & Mood | Time & Tick ✓, Villager AI recovery reports, Build Validation shelter flag | Cluster A internal | In this milestone |
| Criterion #5 (payoff loop) | Build Validation **and** Needs & Mood **and** furniture chain **and** `villager-ai-018` | Cluster A internal | In this milestone |
| `presentation-001` Sub-B | `villager-ai-019` | Cluster B internal | In this milestone |
| Ambient smoke / interior clutter hosts | Room recognition (Build Validation), furniture placement (Cluster A) | Cluster A | In this milestone |
| Villager Info UI | Needs & Mood (values, band, why-string — consumed verbatim) | Cluster A | In this milestone |
| Building UI | `building-001` build editor mode, `building-023` ghost preview | Cluster 0 | In this milestone |
| `building-009` demolition | `building-012` floor-excavation restore-value | Cluster 0 | In this milestone |
| All Cluster A/D stories | The four missing epics created and storied | producer | **Pending — R2** |
| Milestone close | M01 declared CLOSED (C1, C2, C3-human) | user | **Pending — inbound** |

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| CD Scope Ruling ratification (M01 C1) | user | Pending | Cluster C converts to M01 rework — R9 |
| Re-tune values ratification (M01 C2) | user | Pending | M01 #4 basis; no M02 dev impact |
| Target hardware class definition | technical-director | Not started | Criterion #13 cannot be measured — R4 |
| VSync-mode decision | technical-director | **Unowned** | Ships an implicit engine default — R5 |
| Entity inventory / asset specs (`/asset-spec`) | art-director | Pending (M01 stretch, unspent) | Gates criterion #8's art-dependent advisories — R12 |
| CD sign-off on Sub-B / "world lacks life" close | creative-director | Pending Sub-B | Criterion #9 cannot close |
| External playtesters (1–2 silent walkthroughs) | producer to arrange | Not scheduled | R8 — the MVP hypothesis goes untested by a human |

---

## Review Schedule

| Date / Point | Review Type | Attendees |
|------|-----------|-----------|
| Before S09 planning closes | **Epic/story creation gate** — the four missing epics exist and are storied (R2) | Producer, game-designer, ux-designer |
| End of S09 | Early progress check — Cluster 0 landed? Cluster A started? Hardware baseline measured? | Producer, TD |
| End of S10 | **Cut-lever checkpoint #1** — criterion #5 status governs Cluster C's fate | Producer, CD, TD |
| End of S11 | **Cut-lever checkpoint #2** + first external playtest (R8) if criterion #5 is green | Full team + playtesters |
| Start of S12 | Cluster D go/no-go + CD check on protected items (Cluster B) | Producer, CD |
| End of S13 | Milestone review (`/milestone-review`) + `/gate-check` for Production → Polish | Full team |

---

## Notes

- **On the retired budget.** The 32-day MVP re-baseline
  (`production/estimates/estimate-rebaseline-2026-07-23.md`) priced M02 at ~10 working
  days against a 1-story/agent-day anchor — i.e. **~10 stories**. M02's four clusters plus
  the newly surfaced residue are **~60 stories**. The M01 review already diagnosed the
  cause: *the day conversion was wrong, the work estimate was roughly right.* M01 was
  budgeted at ~22 days / ~3 sprints and delivered **80 stories across 8 sprints**, every
  one landing its full commit set in a single session (8/8, 9/9, 9/9, 8/8, 8/8, 13/13,
  12/12, 13/13), with zero carryover and zero unplanned rework throughout. **This
  milestone is therefore budgeted in stories and sprint-sessions.** The calendar window at
  the top is derived from that measured cadence and is advisory only.
- **Throughput is not the binding constraint on this project.** The binding constraints in
  M02 are, in order: (1) **33 stories that do not exist yet** (R2), (2) the two serial
  chains inside Cluster A converging on criterion #5, (3) two unowned decisions (hardware
  class, VSync), and (4) the three inbound user-owned M01 signatures. Every M01 slip came
  from a blocked decision, never from capacity — see the Cut-Lever Policy's anti-signal.
- **The furniture re-homing is the most consequential change in this plan.** The M01
  review's M02 sketch filed furniture under Cluster C's "lower tier: furniture
  (016/017/028)". Had that stood, Cluster C's cut lever would have taken the bed with it —
  and criterion #5, the milestone's entire reason to exist, would have become unbuildable
  by its own scope decision. Furniture is Cluster A.
- **Cluster 0 is new information**, not a re-litigation of the CD ruling. `building-001`,
  `011`, `012`, `023` and `villager-ai-021`, `023` appear on no deferral list; they were
  simply never scheduled across S1–S8. `building-023` (ghost preview) and `villager-ai-021`
  (starting roster) were verified absent from `neues-spiel/src/` by search on 2026-07-26.
- **Story files were verified on disk, not assumed.** Every existing story named in this
  document was confirmed present under `production/epics/` with `Status: Ready` on
  2026-07-26. Nothing scheduled here is invented; everything not on disk is listed under
  Missing Stories for `/create-stories`.
- **We will know this milestone was scoped right if**: criterion #5 goes green by the end
  of S11; the first external playtest reports that the shelter payoff *reads* without a
  facilitator explaining it; and Cluster C's cut lever is pulled at most one tier deep.
- **Next steps**: (1) run `/create-epics layer: feature` for build-validation-navigability
  and needs-mood-system, then `/create-stories` for both; (2) run `/create-epics layer:
  presentation` for building-ui and villager-info-ui; (3) run `/sprint-plan new` for S09
  with Cluster 0 + the head of Cluster A; (4) escalate the hardware-class and VSync
  decisions to technical-director; (5) run `/qa-plan sprint` and `/team-qa sprint` from S09
  onward without exception.
