# Story 009: Real-time-rate pass at `ticks_per_second = 4.0` (milestone criterion #4)

> **Epic**: Needs & Mood System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md` (Tuning Knobs + F1/F2/F3 pacing prose); `design/gdd/time-tick-system.md` (the Open Question this closes)
**Requirement**: `TR-needs-mood-system-041`, `TR-needs-mood-system-030`, `TR-needs-mood-system-053`, `TR-needs-mood-system-038`, `TR-needs-mood-system-066`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary
**ADR Decision Summary**: All tunables live in the typed `.tres` config at GDD-stated defaults, and a value change is a recorded config change with rationale — not an inline edit. Safe ranges are declared per knob and enforced by `validate()`; any retune must land inside the declared range or the range itself must be re-declared in the GDD.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: `TimeTickConfig.ticks_per_second` landed at **4.0** (raised from 2.0, Slice revision 2026-07-23) and `max_ticks_per_frame` at **12** (Sprint 8 re-tune). Every real-time figure written in the Needs & Mood GDD was computed at 2.0 and is therefore **2× off as written**. Tick *counts* are unaffected by the rate; only their wall-clock meaning changed.

**Control Manifest Rules (this layer)**:
- Required (Foundation): config values are data; a change is recorded with rationale (quick-spec), never a silent edit.
- Required (Feature): rates are functions of tick count, never wall-clock — this pass changes what the numbers *mean in seconds*, never how the math is expressed.
- Forbidden: changing a shipped knob without updating the GDD's stated arithmetic and every AC that pins a tick count in the same change.
- Guardrail: any retuned value must sit inside its GDD safe range, or the range is re-declared explicitly with rationale.

---

## Decision — RESOLVED: Option B, unmodified

**Creative-director Ruling 1**,
`production/creative-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL,
pending user ratification** (away-mode ruling; binding once ratified, and the
planning assumption until then).

**Ship `decay_per_tick[sleep] = 0.07`, `base_recovery_per_tick[sleep] = 0.5`,
`mood_smoothing_ticks = 40`. No knob changes. No carve-outs.** The tick anchors
are **CONFIRMED**; the wall-clock feel targets derived from them are **RETUNED BY
RESTATEMENT** — which is how criterion #4's "confirmed or retuned with rationale"
is answered. **Option A's branch is dropped from this story's scope entirely**, as
is any middle value.

### New official feel targets (these replace the stale prose)

| Feel target | Old (stale, computed at TPS 2.0) | **New official (TPS 4.0)** |
|---|---|---|
| Settlement heartbeat (satisfied → urgent → sleep → satisfied) | "~10-minute heartbeat" | **~4 min 45 s** |
| Time to urgent from full (100 → 25) | 1072 ticks ≈ 8.9 min | 1072 ticks = **4 min 28 s** |
| Full drain (100 → 0) | 1429 ticks ≈ 11.9 min | 1429 ticks = **5 min 57 s** |
| Sleep, sheltered bed (25 → 95) | 140 ticks = 70 s | 140 ticks = **35 s** |
| Sleep, unsheltered bed (×0.7) | 200 ticks = 100 s | 200 ticks = **50 s** |
| Sleep, ground (×0.4) | 350 ticks ≈ 2.9 min | 350 ticks = **1 min 27 s** |
| Mood inertia (63% step response) | 40 ticks = 20 s | 40 ticks = **10 s** |
| Minimal room + bed build | "~1–2 min" (building F3) | **~30–60 s** |
| **The deliberate gap** (shelter ready → urgency) | "~6–7 min" | **~3 min** |

### Rationale (CD)

1. **Option A puts the first payoff outside the test window — decisive.** The
   milestone's instrument is a ~10-minute unguided walkthrough. At Option B the
   arc runs: ~1:30 shelter ready → ~3 min of settlement-watching → ~4:28 urgency
   → 35 s sleep → ~5:30–5:45 mood climbs into Happy → ~9:30 second onset begins.
   **One complete, unmistakable onset → shelter → recovery → mood-lift arc,
   finished by minute six, with a second onset visibly beginning.** At Option A:
   shelter ~2:30, urgency ~8:56, wake ~10:15, mood lift ~10:45 — the recovery, the
   mechanic this milestone exists to make real, **never arrives inside the probe**.
2. **The "we lose the designed relationships" objection is arithmetically false.**
   Every rate here is tick-denominated, so 2.0 → 4.0 preserved **every internal
   ratio exactly**. Only the wall-clock tempo changed, and wall-clock only matters
   where it meets something non-tick-denominated: attention span, the ten-minute
   probe, and perceptual thresholds. Against all three, faster is better here.
3. **We have not yet earned a seven-minute wait.** The slice verdict was
   *"atmosphere is the weak axis… the world lacks life."* Ambient life wave 1
   (criterion #8) is landing in this milestone and is unproven. Betting three
   minutes on "the wait is settlement-watching, not dead air" is reasonable;
   betting six-to-seven is how you get the slice's "mostly" verdict twice.
4. **The nagging risk is small and named.** ~35 s of every ~4:45 cycle is
   need-driven (~12%); the GDD's own "tamagotchi territory" marker is
   `decay_per_tick = 0.2` — we sit ~3× slower, inside the declared 0.03–0.2 band.
5. **Correction to this story's prior rationale**: the producer's "**two** full
   observations in ten minutes" claim was optimistic. The arithmetic gives **one
   complete cycle plus a strong second onset** (the second sleep finishes ~10:10–
   10:30). The ruling stands on that, honestly stated; do not restate the two-cycle
   claim anywhere.

### Kill criterion (inherited verbatim by the story-011 probe)

**KILL the ruling — retune `decay_per_tick` 0.07 → 0.05** (a measured step, *not* a
reflex return to 0.035) — if either: the tester interrupts their own building more
than once to attend to needs / describes the villagers as always wanting
something; **or** the tester reports the villager seems to sleep constantly.

**CONFIRM** if, in the ten-minute unguided walkthrough: one complete onset →
shelter → recovery arc is observed **unprompted** and can be recounted; *"why is
the villager unhappy?"* is answered correctly within one cycle with no tutorial;
the mood lift after the bed is mentioned **unprompted**; and nobody uses the word
"nagging" or its German equivalents ("nervt", "ständig").

**DO NOT respond by slowing decay** if the tester reports the pre-urgency stretch
as dead air or boring. That is an **ambient-life finding (Cluster D)**, not a
pacing finding, and the correct response is content, not a knob — **slowing decay
in response to a content problem makes the content problem longer.** This
distinction must be written into the probe's reporting template, or it will be
conflated under observation pressure.

---

## Acceptance Criteria

*From `production/milestones/milestone-02-mvp-completion.md` criterion #4, against `design/gdd/needs-mood-system.md`:*

- [ ] Every rate in the Needs & Mood Tuning Knobs table carries a **stated real-time equivalent at `ticks_per_second = 4.0`** — `decay_per_tick`, `base_recovery_per_tick`, `mood_smoothing_ticks`, and the derived time-to-urgent / sleep-duration figures.
- [ ] The GDD's pacing cross-reference is resolved **explicitly, by name**: the tick anchors are **CONFIRMED**, the wall-clock feel targets are **RETUNED BY RESTATEMENT** to the table above. Leaving the old prose in place is a failure of this AC.
- [ ] Every stale 2.0-rate real-time figure in `design/gdd/needs-mood-system.md` is corrected: F1's "~1429 ticks ≈ 11.9 min" and "1072 ticks ≈ 8.9 min", F2's "140 ticks = 70s / 200 ticks = 100s / 350 ticks ≈ 2.9 min", F3's "= 20s at 1x", and the Tuning Knobs pacing note.
- [ ] **The Game Feel section's "~10-minute heartbeat" and "~7-min pre-urgency stretch" are restated** to **~4 min 45 s** and **~3 min**. The CD flagged this as *"mine, not a mechanical conversion — do not skip it."*
- [ ] **REPO-WIDE `at 1x` ANNOTATION SWEEP (widened per the CD's recommendation).** The doc AC is no longer needs-mood-only: grep **all of `design/`** for `at 1x` and for any `= Ns` / `≈ N min` annotation authored **before 2026-07-23**; every such annotation is 2× stale by construction. Known stale spots that must be in the sweep's result set:
  - `build-validation-navigability.md` Tuning Knobs — `room_cue_cooldown_ticks` **"20 (= 10s at 1x)"** → actually **5 s**. *(This one lands directly on CD Ruling 2's celebration-cooldown pacing — see build-validation story 009 minimum 3.)*
  - `building-system.md` — `base_build_ticks[block]` **"4 (= 2.0s at 1x)"** → **1.0 s**; `[furniture]` **"8 (= 4.0s at 1x)"** → **2.0 s**; **both `base_demolition_ticks` mirrors** inherit the same factor.
  - `needs-mood-system.md` — the F1/F2/F3 + Tuning Knobs figures listed in the AC above.
  - `villager-ai-behavior.md` — `unreachable_retry_ticks` and the watchdog cadence must be **checked** for the same annotation vintage.
  - Already caught by `design/quick-specs/tick-rate-retune-2026-07-25.md`: `decision_interval` (silently halved to 0.5 s) — do not re-fix, but cite it as the precedent.
  **One sweep, one change, one rationale artifact.** The CD's reasoning: otherwise this bug keeps surfacing one GDD at a time for another three sprints. *(Note: the sweep needs an owner — it is listed in the CD's "Open Items Handed Back" as currently nobody's. This AC gives it a home in this story unless the user reassigns it.)*
- [ ] The **kill criterion** (`decay_per_tick` 0.07 → 0.05 on a nagging report; **explicitly NOT** slowing decay in response to a dead-air/boring report, which is a Cluster D content finding) is recorded in the quick-spec **and** written into story 011's probe reporting template.
- [ ] The GDD burst-rule prose "`max_ticks_per_frame` = 10" is corrected to the landed value (**12**) or restated as "the configured value" — tests already assert against config (story 008).
- [ ] The decision (Option A or B) and its rationale are recorded in `design/quick-specs/needs-mood-real-time-rate-pass-2026-07-XX.md`, following the `design/quick-specs/tick-rate-retune-2026-07-25.md` precedent.
- [ ] The `time-tick-system` GDD Open Question flagging the downstream per-tick-rate re-tune is **closed**, naming this quick-spec as its resolution.
- [ ] `design/registry/entities.yaml` entries touched by the outcome (`decay_per_tick` figures if retuned; the real-time annotations on `ticks_per_second`) are updated in the same change.
- [ ] A **config-anchor regression test** proves the shipped `.tres` values still produce the documented tick anchors — a future silent retune fails the suite instead of drifting.
- [ ] **No `.tres` edit, no AC anchor move, no test edit.** Under the ruling this is a **pure documentation pass**: AC7 (1072) and AC27 (1072/1212) are untouched, `decay_state_machine_test.gd` and `burst_pause_warp_determinism_test.gd` are untouched. If this story produces a config diff, the ruling was not followed.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Conversion is one line of arithmetic per knob: `real_time_seconds = ticks / 4.0`. The trap is not the math, it is **missing an occurrence** — and per the widened AC the occurrences span the whole of `design/`, not just F1/F2/F3 and the Tuning Knobs table.
- Do not change how any formula is *expressed*, and **do not change any value**. Rates stay per-tick; only the annotation changes. Wall-clock must never enter the code.
- The quick-spec should state, in this order: the trigger (`ticks_per_second` 2.0 → 4.0), the affected knobs, **the ruling (Option B, tick anchors CONFIRMED / feel targets RESTATED)** with the CD's rationale, the resulting real-time figures, the **kill criterion and its explicit non-trigger** (dead air ⇒ content, not a knob), and the falsification plan (story 011's probe).
- The `mood_smoothing_ticks` carve-out (40 → 80) was considered and **rejected on re-derivation**: the EMA's ramp lag is tick-denominated (per-tick recovery delta × window = 0.5 × 40 = 20 points), so mood's trail behind the need — and where in the cycle the band-up event fires — is **byte-identical** at TPS 2.0 and 4.0. Only its wall-clock duration halved, and 10 s still reads unambiguously as drift. Do not reopen it without new evidence.
- Coordinate with the building-system side: `building-system` F3's build pacing inherited the same doubling, so the "room+bed builds in ~1–2 min" half of the gap claim is also 2× off. State the corrected gap using **both** corrected halves, or the confirmed/retuned verdict rests on one stale number.
- Record this as a **config change with rationale**, exactly as the Sprint 8 tick-rate re-tune was — same file shape, same discipline.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 002/003/005/008: the math and tests this pass is measured against.
- Story 011: the playtest that falsifies the pacing hypothesis.
- `time-tick-system`: the tick rate itself (already landed and ratified).
- Building System's own F3 pacing re-statement — coordinate, but do not edit its GDD from this story.

---

## QA Test Cases

*Config/Data story — smoke check plus one regression guard (testing standards).*

- **Anchor guard**: Given the shipped `NeedsMoodConfig.tres`, When the time-to-urgent and time-to-satisfied tick counts are derived from it, Then they equal the values documented in the GDD and asserted by stories 002/008 — a mismatch fails the suite.
- **Range guard**: Given any retuned value, When `validate()` runs, Then no clamp warning is produced (i.e. the new value is genuinely inside its declared safe range, not clamped into it).
- **Doc completeness (repo-wide)**: Given **all of `design/`**, When grepped for `at 1x` and for `= Ns` / `≈ N min` annotations, Then every one of them is consistent with `ticks_per_second = 4.0` — no surviving 2.0-rate figure anywhere, specifically including `room_cue_cooldown_ticks`, both `base_build_ticks` annotations, and both `base_demolition_ticks` mirrors.
- **No-cascade guard**: Given the story's diff, When inspected, Then it contains **zero** changes under `neues-spiel/` (no `.tres`, no test) — the pass is documentation plus the quick-spec plus the new anchor guard only.
- **Smoke check**: `production/qa/smoke-[date].md` records a boot + one full observed cycle at the shipped values, with the real-time duration measured and compared to the documented figure.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: `production/qa/smoke-[date].md` (smoke check pass) **plus** `neues-spiel/tests/unit/needs_mood/config_pacing_anchor_test.gd` (regression guard) **plus** the recorded quick-spec `design/quick-specs/needs-mood-real-time-rate-pass-2026-07-XX.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (decay anchors), 003 (recovery rates), 005 (smoothing), 008 (the determinism tests this pass must not silently break)
- **No longer blocked** — the Option A / Option B decision is RESOLVED (CD Ruling 1, Option B unmodified; provisional pending user ratification). **Scope shrank**: this is now a pure documentation pass. **Scope widened** in one direction only: the doc AC is repo-wide, not needs-mood-only.
- Coordinate (do not edit from here): `design/gdd/building-system.md`'s F3 variable table and both `base_demolition_ticks` mirrors are stale by the same factor and are in the sweep's scope but not this epic's ownership.
- Unlocks: 010 (the live pair should run against ratified values), 011 (the playtest probe measures the shipped pacing)
