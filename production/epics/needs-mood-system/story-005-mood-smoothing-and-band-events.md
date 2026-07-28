# Story 005: F3 mood smoothing, snap rule, `mean_active` & band events

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — 1241/1241 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-038`, `TR-needs-mood-system-039`, `TR-needs-mood-system-040`, `TR-needs-mood-system-049`, `TR-needs-mood-system-054`, `TR-needs-mood-system-055`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (band boundaries and smoothing constant are config knobs shared verbatim with the UI) — primary; ADR-0001 (the UI reads mood through this module's query API, never through a back-reference)
**ADR Decision Summary**: Every tunable is a typed `@export` on the config Resource at its GDD default, read-only at runtime. The band boundaries (70 / 40) are a **display contract** shared verbatim with Villager Info UI — one owner, one source, no second copy in UI code.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript float math. Use **explicit float division** (`/ 40.0`) — integer division on a `mood_smoothing_ticks` typed as int would silently truncate the EMA step to zero for small deltas. Comparisons are crossings between ticks, never equality.

**Control Manifest Rules (this layer)**:
- Required (Foundation): `mood_smoothing_ticks` and both band boundaries come from config; nothing hardcoded.
- Required (Presentation contract): mood is exposed as a value + band + change event; the UI consumes it verbatim and never re-derives band boundaries.
- Forbidden: any mood-consuming reference in work/scheduling code (Rule 8 — MVP mood is display-only; statically checkable).
- Guardrail: F3 runs once per villager per tick after F1/F2 — one EMA step, no history buffer.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC14**: Given a `mean_active` differing from mood by **at least 0.05** (outside the snap zone), When 1 tick fires, Then mood moves by exactly `(mean_active − mood) / mood_smoothing_ticks` in float math (F3). [TR-needs-mood-system-038]
- [ ] **AC15**: Given `abs(mean_active − mood) < 0.05`, When a tick fires, Then mood snaps exactly to `mean_active` (F3 snap rule). [TR-needs-mood-system-054]
- [ ] **AC16**: Given `mean_active` stable at 70 for enough ticks that the snap condition is met, When it fires, Then `mood == 70.0` exactly and the **Happy** band activates — the anti-asymptote guarantee. [TR-needs-mood-system-054]
- [ ] **AC20**: Given inactive schema needs (`food`/`company` pre-tier), When `mean_active` is computed, Then they are **excluded, never defaulted** — a lone sleep of 60 yields mean 60, not 86.7. [TR-needs-mood-system-055]
- [ ] **AC18**: Given mood crossing a band boundary, When the cross occurs, Then exactly one band-change display event is emitted. [TR-needs-mood-system-049]
- [ ] **AC19**: Given the default `band_display_hysteresis = 0`, When mood crosses exactly 70.00 or 40.00, Then the band event fires at the boundary tick — no implicit dead zone (Edge Case 10). [TR-needs-mood-system-049]
- [ ] Bands are exactly **Happy ≥ 70**, **Content 40–69**, **Low < 40**, derived from the smoothed value only; mood itself is read-only to every consumer. [TR-needs-mood-system-039] [TR-needs-mood-system-038]
- [ ] **Advisory (not a blocking Logic AC)**: mood has zero consuming references in work/scheduling code — MVP mood is display-only (Core Rule 8), verified by an architectural contract/grep check owned alongside code review. [TR-needs-mood-system-040]

---

## Implementation Notes

*Derived from ADR-0002/0001 Implementation Guidelines:*

- F3 is the third and last step of the per-tick pass: F1 decay → F2 recovery → F3 mood. Mood must be computed from the values **after** this tick's F1/F2, never from the previous tick's.
- The snap rule exists to defeat the EMA asymptote at a band boundary (69.97 never reaching 70). Implement it as an explicit branch before the EMA step, not as a rounding of the result.
- `mean_active` iterates the **active set** from story 001's schema. An inactive need contributes no term and does not change the divisor — the count is the number of active needs, not the schema size.
- Band derivation is a pure function of the smoothed value plus `band_display_hysteresis` (default 0, so the pure comparison holds). Keep the hysteresis knob wired but inert — Edge Case 10 is a reserve, not a feature.
- Emit `mood_band_changed(villager_id, band)` on the cross only. The UI reads `get_mood()` / the band query for its steady state; the event is the refresh trigger, exactly as the need events are latency hints.
- Display-only means no scheduling, work-speed, or priority code may read mood. Add the grep/contract check with the story so it can never regress silently.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: F4 spawn initialization of mood (`mood ← mean_active`).
- Story 007: the why-string (which uses the Happy band as its empty condition).
- Story 008: burst ordering, pause, and warp behavior of the mood pass.
- Villager Info UI: rendering bands, icons, and bars (its own epic).

---

## QA Test Cases

- **AC14**: Given `mood = 100.0`, `mean_active = 60.0`, `mood_smoothing_ticks = 40.0`, When 1 tick fires, Then `mood == 99.0` exactly (`100 + (60 − 100)/40`).
- **AC15**: Given `mood = 69.98`, `mean_active = 70.0`, When a tick fires, Then `mood == 70.0` exactly.
- **AC16**: Given `mean_active` held at 70.0 and mood starting at 60.0, When ticks fire until the snap condition is met, Then `mood == 70.0` exactly and the band query reads **Happy**.
- **AC20**: Given `sleep = 60` active and `food`/`company` inactive, When `mean_active` is computed, Then it equals 60.0 exactly (not 86.7, not 20.0).
- **AC18**: Given mood descending through 70, When the cross occurs, Then exactly one band-change event with band `Content`; When further ticks fire without another cross, Then zero further events.
- **AC19**: Given `band_display_hysteresis = 0` and mood landing exactly on 70.00, When evaluated, Then the band is **Happy** (`>= 70`) and the event fired on that tick; Given mood landing exactly on 40.00, Then **Content** (`>= 40`).
- **Pass ordering**: Given a need recovering this tick, When the tick completes, Then mood was computed from the post-recovery value.
- **Display-only (advisory)**: Given the source tree, When grepped, Then no work/scheduling module references `get_mood`/the mood band.
- Edge cases: mood exactly at the snap threshold (`abs(delta) == 0.05`) uses the EMA branch, not the snap; two consecutive band crossings in one tick burst emit two events in order (story 008 owns the burst harness); `mood_smoothing_ticks` at both safe-range extremes (10 and 120) produces a finite, non-zero step.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/mood_smoothing_and_bands_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (config, schema, pass skeleton), 002 (need values to average)
- Unlocks: 006, 007, 008
