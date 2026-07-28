# Epic: Presentation Experience (Ambient Life & Loop-Payoff Communication)

> **Layer**: Presentation
> **GDD**: N/A — Art-Bible-driven micro-epic. Source of truth: `design/art/art-bible.md` §6.5 (Ambient Life & Motion) + §5.6 (Expression & Personality Without Faces), with §5.3 (individuation) and §8.9 (technical budgets) as constraints. Follows the **foundation-spine GDD-less precedent** (an epic may be doc-driven rather than GDD-driven when the source doc is authoritative).
> **Architecture Module**: No single module — Presentation/experience layer. Per `production/epics/index.md` §"CD-protected items — mapping gap", neither CD item maps to any Foundation or Core architectural module in architecture.md; this micro-epic is their sanctioned home so they are not silently deferred to polish.
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 3 stories created (002 Complete; 003 added 2026-07-26 from TD ruling VB-1/VB-2)

## Overview

This micro-epic is the home for Milestone 01's two **CD-protected, Should-Ship
experience items** (milestone-01 review exit criteria #9 and #10), which have no
Foundation/Core GDD module and no governing ADR of their own. It exists to give
them an explicit, tracked home rather than letting them slip to a later polish
pass by default — the milestone review flagged their "not placed" status as a
silent-deferral risk against explicit Creative-Director protection.

It delivers (1) **Ambient-life wave 1** — the CD-confirmed first production wave
of cheap motion/life that directly answers the 2026-07-23 debrief's #1 finding
("the world lacks life"): chimney smoke, foliage sway, villager idle behaviors,
interior clutter, torch flicker (Art Bible §6.5, CONFIRMED user decision
2026-07-23); and (2) **Loop-payoff communication scaffolding** — the event/signal
surface that lets the core loop's payoff be *communicated*, built scaffolding-only
in M01 so the Feature-layer mechanic (needs/mood + reward feedback) can plug into
a stable surface later, per the milestone's own scaffolding-vs-mechanic split.

Both items are **presentation of state the simulation already produces** — they add
no new simulation. Ambient life reuses the existing villager FSM and the mesher's
rendered world; the loop-payoff surface reuses the foundation-spine signal/DI
contract. Nothing here touches the slice-validated static foundation (chunky
textures, golden-hour light, horizon fog, warm room lights, §6.5) — it adds motion
and communication *on top* of it.

## Governing ADRs

This epic is **Art-Bible-governed, not ADR-governed** (like foundation-spine is
ADR-governed rather than GDD-governed). No ADR decides ambient-life direction —
that is a Creative/Art-Director call captured in the Art Bible. The ADRs below are
**context / integration touch-points** the stories must respect, not decision
sources for the epic's scope:

| ADR | Relationship | Engine Risk |
|-----|-------------|-------------|
| ADR-0008: Villager AI Execution & Threading | Context — the villager idle-behaviors hook (story-001 sub-scope B) *reads* the villager FSM's Idle/Wandering state; it must not add simulation, only presentation of existing state | HIGH (villager AI domain) |
| ADR-0014: Chunked Voxel Rendering | Context — environmental ambient motion (smoke/sway/clutter/flicker) attaches to and is seen against the mesher's rendered world; nothing bakes into committed-block materials | HIGH (rendering domain) |
| ADR-0001: Inter-System Reference & DI Pattern | Context — the loop-payoff scaffolding (story-002) is a signal/event surface built on the spine's DI + signal contract; injected-tier, headless-mockable. Also **governing** for story-003's injected-tier `setup()` + duck-typed nil-safe providers | MEDIUM |
| ADR-0004: Physics Backend & Picking Strategy | **Governing for story-003** — the villager hit proxy is an `Area3D` + `CollisionShape3D` on collision layer 1, hosted on `VillagerBodyView`. Not a manifest violation: the manifest's physics prohibitions are scoped to *block/world* picking (lines 89/98); villager hit-testing is affirmatively required by lines 64/82/152/219 | HIGH (physics/picking) |
| ADR-0009: Deterministic Movement & Occupancy Ordering | **Governing for story-003** — two-layer position model; the view is a pure per-frame mirror of `VillagerAi.get_visual_position()`, stores nothing, interpolates nothing, and sets `physics_interpolation_mode = OFF` explicitly | HIGH (villager AI domain) |

**Engine risk (highest touch-point): HIGH** — the visible ambient elements sit on
the rendering domain and the idle-behaviors hook sits on the villager-AI domain,
both post-cutoff HIGH-risk areas. All GPUParticles3D / vertex-shader / light-energy
/ FSM-read APIs must be cross-referenced against `docs/engine-reference/godot/`
before use. Torch/lantern flicker MUST respect Art Bible **A5 (sub-3Hz)** — no free
pass on flicker rate.

## Requirements (Art-Bible-traced, no TR-IDs)

Neither CD item has a TR-ID in `docs/architecture/tr-registry.yaml` — they are
experience/presentation concerns with no GDD module (confirmed: registry grep for
ambient/foliage/smoke/idle/payoff returns only neighbouring-system rows, none for
these items). Traceability therefore runs to the Art Bible, not the TR registry:

| Requirement | Source | ADR Coverage |
|-------------|--------|--------------|
| Ambient-life wave 1 = chimney smoke, foliage sway, villager idle behaviors, interior clutter, torch flicker | Art Bible §6.5 (CONFIRMED 2026-07-23) | N/A — Art-Bible-driven; ADR-0008/0014 are integration context only |
| Expression/personality via idle behaviors (stretch, glance at unfinished build, sit at furnished table, brief exchanges) | Art Bible §5.6 | N/A — reuses villager FSM (ADR-0008 context) |
| Torch/lantern flicker respects sub-3Hz | Art Bible §6.5 note + A5 | N/A |
| Loop-payoff communication surface (event/signal the Feature-layer mechanic plugs into) | milestone-01 exit criterion #10 (scaffolding-vs-mechanic split) | ADR-0001 signal/DI pattern (context) |

**Untraced-requirement note:** because these are Art-Bible-driven with no TR-IDs
and no decision-owning ADR, the normal "untraced → Blocked" rule does not apply
in its usual form (there is nothing for an ADR to cover). Instead the binding gate
is **Creative-Director sign-off**: per the milestone and epics-index note, cutting
or reshaping either item requires CD sign-off, and the visual result requires
art-director/CD approval as its acceptance evidence.

## Milestone 01 Notes

- **Home of the two M01 CD-protected Should-Ship items** (exit criteria #9
  ambient-life wave 1, #10 loop-payoff scaffolding). Their placement here resolves
  the milestone review's Action Item #3 and closes the epics-index CD-mapping gap.
- **These stories are dependency-gated, not immediately schedulable.** Ambient life
  needs the mesher (vox-007) rendering a world and the villager FSM/movement stories
  in place; the environmental sub-scope can begin as soon as the mesher lands, the
  villager-idle sub-scope only after the villager wandering/idle states exist. They
  land in the **Presentation pass (Sprint 5+)**, after Sprint 4's mesher critical
  chain and the Core villager/building work — not in Sprint 4.
- **CD sign-off is required to cut either item.** Owner remains godot-specialist per
  the milestone; art-director/creative-director own the visual/experience bar.

## Definition of Done

This epic is complete when:
- All three stories are implemented, reviewed, and closed via `/story-done`
- The villager body substrate (story-003) exists: a presentation-tier `VillagerBodyView` per villager that
  can be **seen, clicked (ADR-0004 layer 1), hidden by a slice, and hung an icon on** — with `VillagerAi`
  still `extends Node` and the pure-mirror/no-new-simulation invariants grep-verified
- Ambient-life wave 1 renders all five confirmed elements to the Art Bible §6.5 bar,
  with art-director/CD sign-off (Visual/Feel evidence in `production/qa/evidence/`)
- Torch/lantern flicker is verified sub-3Hz (A5)
- The loop-payoff communication surface exists, is headless-mockable, and has a
  passing signal-contract test — a Feature-layer mechanic can bind to it without
  the surface changing shape
- No new simulation was introduced (ambient life and loop-payoff are presentation
  of existing state only — grep/review-verified)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Ambient-life wave 1 (chimney smoke, foliage sway, villager idle-behaviors hook, interior clutter, torch flicker) | Visual/Feel | Ready | N/A (Art Bible §6.5; ADR-0008/0014 context) |
| 002 | Loop-payoff communication scaffolding (event/signal surface) | Integration | Ready | ADR-0001 (signal/DI surface) |
| 003 | Villager body view, hit proxy & slice hook — **the substrate three epics are blocked on** (CORE tier) | Integration | Ready | ADR-0004 · ADR-0009 · ADR-0001 (Art Bible §5.2/§5.3) |

**Story 003 note (added 2026-07-26).** Authored by the producer from technical-director rulings **VB-1**
(the ruling) + **VB-2** (the story spec) in
`production/architecture-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL, pending user
ratification**. It is scheduled as a Sprint 10 **Must**. Two epic-level consequences:

- **It is this epic's first CORE-tier story** — a hard blocker for `villager-info-ui-002/005/006`,
  `building-ui-016`'s characters clause, and this epic's own `presentation-001` **Sub-B**. Its
  Art-Bible-traced, TR-less requirement shape follows the same precedent as 001/002.
- **`presentation-001` Sub-B (villager idle behaviors) now has an in-epic prerequisite it did not have when
  it was deferred to S10/S11** (TD downstream action #16). Sub-B is invisible until 003 lands — villagers
  have no body to idle with. The ordering costs nothing at current scheduling, but it must not be
  re-ordered ahead of 003.

## Next Step

These stories are gated behind the Sprint 4 mesher chain (vox-007) and the Core
villager movement/idle stories. Schedule them into the **Presentation pass
(Sprint 5+)** once those dependencies land. Run
`/story-readiness production/epics/presentation-experience/story-001-ambient-life-wave-1.md`
when the mesher is green.
