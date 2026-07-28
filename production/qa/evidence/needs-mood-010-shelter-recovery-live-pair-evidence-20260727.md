# Shelter Recovery Live-Pair Round Trip — Evidence (Story needs-mood-010, AC34, milestone criterion #5)

**Date**: 2026-07-27
**Story**: `production/epics/needs-mood-system/story-010-live-pair-shelter-recovery.md`
**QA gate**: AC34 (Blocking, Integration) — the milestone's own criterion #5 measurement point
**Test**: `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` (8 test functions,
all passing, headless, GdUnit4)
**Engine**: Godot 4.7-stable, headless (`--headless -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd`)
**Full suite at capture time**: 1298 test cases, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans,
exit code 0.

---

## What was proven, unmocked

Per this story's own resolution of its Dependencies/Implementation Notes contradiction (Sprint 10
plan, D8 option (c)): the seam that may never be mocked is Needs & Mood <-> Villager AI, and this run
additionally keeps the furniture/shelter chain feeding that seam real rather than doubled —
`building-017` (demolition) alone stays test-triggered, exactly as its Out of Scope section names.

- A real `NeedsMood` instance (`src/needs_mood/needs_mood.gd`) and a real `VillagerAi` instance
  (`src/villager_ai/villager_ai.gd`), `needs_provider` assigned directly to the real module.
- A real `FurnitureRegistry` (`src/building_system/furniture_registry.gd`) with a real 2-cell bed
  placed via its own production `place()` call.
- A real `BuildValidation` (`src/build_validation/build_validation.gd`) classifying that bed's
  shelter status via a real enclosed room (floor + roof over both footprint cells, open-sky escape
  on the same platform) versus a real open, unroofed placement for the unsheltered variant.
- A new adapter, `FurnitureBedProvider` (`src/villager_ai/furniture_bed_provider.gd`), translating
  between `FurnitureRegistry`'s per-item records + `BuildValidation.get_shelter_status()` and
  `VillagerAi.bed_provider`'s exact duck-typed contract — "the wire between them" this story exists
  to build. It holds no furniture/shelter logic of its own; only `building-017`'s future removal
  emission is stood in for by directly triggering its own `furniture_revoked` signal (matching
  `villager-ai-018`'s own `MockBedProvider.revoke()` precedent, now on the real adapter).
- Ticks dispatched one at a time via a shared, manually-fired `MockTimeTickSystem` double (the one
  sanctioned neighbor-of-the-seam double, per this story's own Engine Notes) — never wall-clock,
  never a burst.

## The end-to-end assertion chain (`test_ac34_full_round_trip_sheltered_bed_exact_sequence_and_call_counts`)

1. **Real shelter proof, before any villager involvement**: `bed_provider.is_bed_sheltered(bed_cell)`
   is `true` — Build Validation's own live room classification, not a stand-in value.
2. **Seed + first real decay tick**: the need is seeded to `urgency_threshold + decay_per_tick_sleep`
   (the sprint's own named fast-path lever); the very first dispatched tick's real F1 decay pass
   crosses the threshold — `need_state_trace[0] == URGENT`, `need_urgent` observed exactly once.
3. **Poll, not event, on the same tick**: the villager's own Deciding pass (already queued from
   `setup()`) reads `has_urgent_need()` fresh in the SAME tick and commits — `villager_state_trace[0]
   == TRAVELING`, `has_owned_bed() == true`, owned cell equals the bed's canonical cell.
4. **Travels, arrives, sleeps**: the trace visits `SLEEPING`.
5. **`start_recovery` called exactly once**: `NeedState.RECOVERING` is entered exactly once across
   the whole trace — the only production code path into that state (verified against
   `needs_mood.gd`'s own source), so one entry is exactly one effective `start_recovery` call.
6. **`need_satisfied` fires exactly once** (the real F2 upward-cross).
7. **`stop_recovery` NOT called on natural wake**: every `RECOVERING`-exit in the trace is accounted
   for by a `need_satisfied` emission (difference = 0) — matches `villager-ai-018`'s own shipped,
   tested contract that natural wake never reports an interruption.
8. **Back in Deciding**: final state `DECIDING`, `PursuedActivity.NONE`, bed ownership retained.
9. **Sheltered rate, end to end**: the credited per-tick delta during Recovering equals
   `base_recovery_per_tick_sleep * 1.0` exactly (not ×0.7, not ×0.4) — proving Build Validation's
   `sheltered = true` verdict actually reached the `bed_sheltered` rate-table row.

## Companion assertions (separate test functions, same harness)

- **Poll-not-event** (`test_poll_not_event_...`): identical round trip with `need_urgent` left
  deliberately **unconnected** — completes identically. This is the story's own named "single most
  valuable assertion."
- **Unsheltered rate** (`test_unsheltered_bed_recovers_at_unsheltered_multiplier_rate`): a real
  unroofed bed placement classifies unsheltered; credited rate = `base_recovery_per_tick_sleep *
  unsheltered_bed_multiplier` (×0.7) exactly.
- **Revocation mid-sleep** (`test_bed_revoked_mid_sleep_...`): the adapter's own `furniture_revoked`
  signal fires while sleeping — immediate wake, ownership dissolved, need value unchanged (zero
  credited that tick), state reverts to `URGENT` (matching `needs-mood-004`'s Edge Case 3).
- **Determinism** (`test_determinism_two_identical_runs_...`): two fully independent instance graphs,
  identically seeded, produce identical sleep-onset and wake tick indices.
- **Full anchor** (`test_full_decay_anchor_from_100_reaches_urgent_at_real_tick_count`): from
  value = 100.0 at shipped defaults (`decay_per_tick_sleep = 0.07`, `urgency_threshold = 25.0`),
  `need_urgent` fires at exactly `ceil((100-25)/0.07) = 1072` ticks, run once, matching the sprint
  plan's own named figure.
- **Production wiring** (`test_production_wiring_...` / `test_no_other_call_site_assigns_needs_provider`):
  a real `GameWorld`/`Valley.tscn` boot assigns the SAME `NeedsMood` instance hosted on `Valley` to
  the hosted `VillagerAi.needs_provider`; a directory-wide grep confirms `valley.gd` is the only file
  under `src/` that ever writes `needs_provider =`.

## Production wiring landed

- `Valley` now hosts a `NeedsMood` node (`Valley.tscn`), wired with the shipped
  `data/config/needs_mood_config.tres`.
- `Valley._wire_villager_population()` assigns the hosted `NeedsMood` to the default villager's
  `needs_provider`; `Valley.spawn_starting_roster()` assigns the same instance to every
  roster-spawned villager. This is the only call site in `src/` assigning `needs_provider` (grep
  proof above).
- `NeedsMood` was added to `Valley.get_injected_tier_modules()` or the shipped Booting sweep
  (`GameWorld._setup_injected_tier()`).

**Note — concurrent-lane count changes**: `presentation-003` landed in the same sprint session and
also added a hosted module (`VillagerBodyPresenter`) to `Valley`. Both additions are reflected
together in the currently-landed `Valley.get_child_count()` (14) and
`injected_tier_modules.size()` (12) assertions in
`tests/integration/scene_world_management/world_root_valley_attach_test.gd` and
`tests/integration/scene_world/gameworld_e2e_loop_test.gd` — both counts were touched by both
stories' work landing in the same window; the final numbers on disk are correct for BOTH additions
together, verified by the full green suite run above.

## Deviations / honest gaps

- `needs-mood-006` (spawn init), `needs-mood-007` (why-string), `needs-mood-008` (determinism/burst
  harness) are still `Status: Ready` on disk, not `Complete` — `src/needs_mood/needs_mood.gd` has no
  `spawn_init`/`get_why_string` method and no dedicated burst-determinism additions beyond what
  `needs-mood-002/003/005` already ship. This story's own sanctioned test seam
  (`set_need_value`/`set_mood_value`, documented in `needs_mood.gd` itself as exactly this use) was
  used to seed preconditions instead of a production spawn-init call, and the why-string literal
  ("sleeping rough — no shelter") was NOT asserted — that string does not exist in the codebase yet.
  The ×0.7 unsheltered RATE is proven directly instead (the mechanically-real part of that edge
  case). Determinism was proven directly via two independent runs rather than via a dedicated
  `needs-mood-008` harness. None of this narrows AC34's own six checkboxes, all of which are met.
- `building-017` (furniture demolition/revocation) is deferred to S11 per this story's own Out of
  Scope section; the revocation edge case above triggers the adapter's own `furniture_revoked` signal
  directly rather than through a real demolition job, exactly as `villager-ai-018`'s own precedent
  already does. A follow-on AC (Sprint 10 plan D8 option (c)) re-verifies this non-vacuously once
  `building-017` lands.
