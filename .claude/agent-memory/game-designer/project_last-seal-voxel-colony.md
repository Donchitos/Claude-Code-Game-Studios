---
name: project-last-seal-voxel-colony
description: Core facts about "The Last Seal (Voxel)" project — game concept, design-doc ecosystem, and key tuning constants needed to sanity-check GDD math during reviews.
metadata:
  type: project
---

**Game**: "The Last Seal (Voxel)" — voxel colony-builder + squad tactics, Godot
4.7/GDScript, single-player. Pillars: 1) building IS the game (furniture
carries function), 2) settlement that feels alive, 3) cozy but with stakes
(waves, not neglect — no RimWorld-style mental-break spirals), 4) clarity
over complexity (causality always legible in the UI).

**Why**: repeated design-review sessions on this repo's `design/gdd/*.md`
files reference the same cross-cutting numbers and process; recording them
here avoids re-deriving from scratch each session.

**How to apply**: use these facts when sanity-checking formulas or pacing
claims in any GDD in `design/gdd/`.

- `ticks_per_second` = 2.0 (base, at 1x warp) — from `time-tick-system.md`.
  1 tick = 0.5s game time at 1x.
- `base_build_ticks[block]` = 4 ticks (2.0s), `base_build_ticks[furniture]`
  = 8 ticks (4.0s) — from `building-system.md` F3. A minimal MVP room
  (~20-40 blocks) + 1 bed builds in roughly 1-2 minutes of tick-time.
- MVP scope is deliberately tiny: 1 villager, 1 need (sleep), 1 room, 1 bed,
  free tier-0 materials, no threats. The concept's own test-scope note
  frames MVP as testing only "the first ~10 minutes" of the build→furnish→
  live loop, NOT sustained engagement.
- Process: this project runs a very rigorous, incremental, cross-referenced
  GDD authoring process (`design/gdd/systems-index.md` tracks 32 systems,
  status per system: Not Started / Designed / Approved). Multiple GDDs
  reference each other's Rules/Edge Cases by number and explicitly track
  "provisional" markers that get "patched"/"confirmed" as dependent GDDs
  land. A `gdd-cross-review-2026-07-10.md` batch-review event is a key
  reference point other GDDs cite.
- See also [[project-gdd-staleness-patterns]] for recurring cross-GDD gap
  types found during review.
