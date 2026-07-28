# Milestone: 01 — Foundation + Core (Playable Integrated Build)

## Overview

- **Target Date**: [not set — express in working days; see Duration]
- **Type**: Production (first Production milestone; follows the vertical-slice PROCEED verdict)
- **Duration**: ~22 expected working days (optimistic ~18 / pessimistic ~29) — the
  Foundation + Core + integration + CD-protected subset of the 32-day MVP re-baseline
  (`production/estimates/estimate-rebaseline-2026-07-23.md`, categories 1-3 + part of 6)
- **Number of Sprints**: ~3 (at ~2-week sprints with 20% buffer; sized by `/sprint-plan`)

## Milestone Goal

Rebuild — to production standards, from scratch — the Foundation and Core layers the
vertical slice proved, integrated into a single playable build: the player draws a
building, workers build it over time, and villagers navigate and live inside the world
without getting stuck. This milestone converts the throwaway slice into the durable
spine every later system attaches to (data-driven config, DI, blocking tests, ADR
compliance), pays down the three tech debts the slice deferred, and starts the two
Creative-Director-protected experience items early so Pillar 2 (living settlement) and
the loop payoff are not left to end-of-project polish. At the end we can demonstrate and
evaluate the core build-and-inhabit loop on the production codebase.

## Success Criteria

The milestone is complete ONLY when all of these are met. Each is testable.

- [ ] **Boot + DI + config spine**: game boots through the ADR-0005 initialization gate;
      systems are wired via DI (ADR-0001) and read tuning from external config
      (ADR-0002/0006) — verified by a headless boot test.
- [ ] **Foundation systems integrated**: Scene/World Management, Time & Tick, Resource &
      Item Database, Camera & Input, and Voxel World all pass their per-system unit tests
      and run together in one scene.
- [ ] **Mesher CW-winding rewrite landed**: faces wound to Godot CLOCKWISE fronts with
      backface culling RE-ENABLED (slice shipped on `CULL_DISABLED`); no missing-face
      regressions, verified against engine convention (not self-stored assumptions).
- [ ] **Per-tick re-tuning pass done**: `max_deciding_per_tick` and tick-budget values
      re-tuned against production load, recorded as a config change with rationale.
- [ ] **ADR-0015 C1/C4 residency tuning**: the two carried tuning items implemented as
      stories with measured values, not open decisions.
- [ ] **Building System playable**: draft-first projects (draw → release → workers build),
      room/roof/house tools, change orders, worker-executed demolition, plan-only undo —
      full lifecycle (ADR-0016) with logic ACs covered by unit tests.
- [ ] **Villager AI playable**: FSM + AStar3D pathfinding, body-column occupancy,
      deterministic movement ordering (ADR-0009), threading model (ADR-0008), and the
      anti-stuck watchdog + seal prevention — watchdog telemetry exposed in F3.
- [ ] **Integrated playable build**: the full Foundation+Core loop (build a house →
      workers build it → villagers navigate it) passes a headless E2E LOOP test on every
      commit.
- [ ] **Ambient-life wave 1 present** (CD-protected): first pass of world life (ambient
      motion / plants / animals per Art Bible) visible in the build.
- [ ] **Loop-payoff communication scaffolding present** (CD-protected): warm-light reward
      feedback and the cue/hook layer that will communicate the shelter→recovery payoff
      (the recovery *mechanic* itself lands with Needs & Mood in Milestone 02).
- [ ] All S1 and S2 bugs resolved.
- [ ] Performance within budget: 60 FPS on the production window with culling RE-ENABLED
      (slice held 60 FPS at 2× faces on `CULL_DISABLED`, so headroom is expected).
- [ ] Build stable (headless E2E green) for the length of the pre-milestone review window.

## Feature List

### Must Ship (Milestone Fails Without These)

| Feature | Design Doc | Owner | Sprint Target | Status |
|---------|-----------|-------|--------------|--------|
| Boot/DI/config spine + test harness + CONTRACTS.md | ADR-0001/0002/0005/0006 | godot-gdscript-specialist | S1 | Not Started |
| Scene/World Management | design/gdd/scene-world-management.md | godot-specialist | S1 | Not Started |
| Time & Tick System (+ per-tick re-tune) | design/gdd/time-tick-system.md | godot-gdscript-specialist | S1 | Not Started |
| Resource & Item Database | design/gdd/resource-item-database.md | godot-gdscript-specialist | S1 | Not Started |
| Camera & Input | design/gdd/camera-input.md | godot-specialist | S1 | Not Started |
| Voxel World / Grid Data (chunk storage) | design/gdd/voxel-world.md | godot-gdscript-specialist | S1-S2 | Not Started |
| Mesher CW-winding rewrite + culling re-enable | ADR-0014 (amended) | godot-shader-specialist | S2 | Not Started |
| ADR-0015 C1/C4 residency tuning | ADR-0015 | godot-gdscript-specialist | S2 | Not Started |
| Building System (projects lifecycle, tools, change orders, undo, demolition) | design/gdd/building-system.md | godot-gdscript-specialist | S2 | Not Started |
| Villager AI (FSM, AStar3D, occupancy, threading, anti-stuck) | design/gdd/villager-ai-behavior.md | ai-programmer | S2-S3 | Not Started |
| Integration-to-playable (CONTRACTS.md, headless E2E) | — | producer/godot-specialist | S3 | Not Started |

### Should Ship (Planned but Cuttable)

| Feature | Design Doc | Owner | Sprint Target | Cut Impact | Status |
|---------|-----------|-------|--------------|-----------|--------|
| Ambient-life wave 1 (CD-protected) | Art Bible §5/§6 | godot-specialist | S3 | CD-flagged: cutting re-under-delivers Pillar 2 — cut only with CD sign-off | Not Started |
| Loop-payoff communication scaffolding (CD-protected) | Art Bible §5.3/§5.6/§6.5 | godot-specialist | S3 | CD-flagged: weakens the felt payoff the slice found "mostly" landed — cut only with CD sign-off | Not Started |

> These two are marked cuttable *only* to expose the schedule lever honestly. Per the
> pre-production gate, the Creative Director protected both as EARLY Production targets —
> they must not be silently deferred to polish. Cutting either requires CD sign-off.

### Stretch Goals (Only if Ahead of Schedule)

| Feature | Design Doc | Owner | Value Add |
|---------|-----------|-------|----------|
| 1-2 external silent-walkthrough playtests | slice REPORT §Phase 4 | producer | Surfaces affordance gaps (e.g. door-gap) before Milestone 02 scope lock |
| Entity inventory / asset-spec | design/assets/entity-inventory.md | art-director | Unblocks asset scale-up after the mesher rewrite |

## Out of Scope (Explicitly Deferred to Milestone 02+)

- **Build Validation & Navigability** and **Needs & Mood** (Feature layer) — the recovery
  half of the loop payoff lands here, in Milestone 02.
- **Building UI** and **Villager Info UI** as full Presentation-layer systems — Milestone 01
  ships only the *minimal* interaction UI needed for the build to be playable (toolbar to
  invoke tools, project selection); the polished UX-spec'd panels are Milestone 02.
- Save/Load, audio, resource economy/costs, streaming, doors/windows as items, combat,
  wave defense — all Vertical-Slice-tier or later.
- Main-menu / pause-menu UX specs (gate blocker #4) — authored in parallel, not gated by
  this milestone's core loop.

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Crash rate | 0 known S1 crash classes open (incl. typed-Array regression) | Regression call in headless E2E gate |
| Frame rate | >= 60 FPS on production window, culling RE-ENABLED | Performance profiling |
| Critical bugs | 0 open S1 | Bug tracker |
| Major bugs | 0 open S2 | Bug tracker |
| Logic test coverage | Blocking unit test per logic AC; property corpus <=60s CI | GdUnit4 headless report |
| Integration | Headless E2E LOOP test green on every commit | CI gate |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|
| Production quality bar costs more than slice standards | Medium | Medium | Sequence boot/DI/config + test harness FIRST; property corpus as its own story | producer | Open |
| Mesher CW rewrite needs a second pass | Medium | Low-Med | Do it early, before asset scale-up; slice proved geometry, only winding/culling flip | godot-shader-specialist | Open |
| Recurring typed-Array crash class | Medium | Low | Regression call in E2E gate; preview path deliberately untyped | godot-gdscript-specialist | Open |
| Late wiring/UX gaps (E2E can't catch them) | Medium | Low-Med | +20% wiring overhead budgeted; 1-2 external walkthroughs before M02 lock | producer | Open |
| CD-protected items pressured out under schedule | Medium | Medium | Marked cuttable only with CD sign-off; surfaced in every sprint status | producer | Open |
| Control manifest stale when first story starts | High | Medium | Gate blocker #1: refresh manifest BEFORE first story embeds it | technical-director | Open (gate blocker) |
| Godot 4.7 API deviations beyond LLM cutoff | Medium | Low-Med | Check docs/engine-reference/godot/ before every API use | godot-specialist | Open |

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|
| All feature stories | Control-manifest refresh (gate blocker #1) | technical-director | Pending |
| All feature stories | Foundation/Core epics + stories created (gate blocker #3) | producer | Pending |
| Building System | Voxel World, Camera & Input, Resource & Item DB, Time & Tick | (Foundation) | In this milestone |
| Villager AI | Voxel World, Time & Tick | (Foundation) | In this milestone |
| Loop-payoff *mechanic* (M02) | Needs & Mood, Build Validation | (Feature layer) | Out of scope — M02 |

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| Art Bible ambient-life / mood specs | Art Director | APPROVED 2026-07-23 | Low — bible signed off at the gate |
| Entity inventory / asset specs | Art Director | Pending (/asset-spec) | Blocks asset scale-up, not the core loop |

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| End of Sprint 1 | Early progress check (Foundation integrated?) | Producer, TD |
| Midpoint (Sprint 2) | Mid-milestone review (Core landing, mesher rewritten?) | Full team |
| Sprint 3 start | Pre-milestone review + CD check on protected items | Full team |
| Milestone end | Milestone review (`/milestone-review`) + Go/No-Go to M02 | Full team |

## Notes

- Duration is expressed in **working days**, not calendar dates, per the re-baseline
  (`production/estimates/estimate-rebaseline-2026-07-23.md`). Convert to a calendar target
  at `/sprint-plan` once session cadence is known (the slice's 5 build days spanned 11
  calendar days).
- The slice code (`prototypes/last-seal-vertical-slice/`) is reference only — every system
  here is written from scratch to production standards and never imported.
- This milestone is the first of a two-milestone MVP: Milestone 02 completes the Feature +
  Presentation layers (Build Validation, Needs & Mood, full UI, the loop-payoff mechanic),
  budgeted at ~10 working days to reach the full 32-day MVP total.
