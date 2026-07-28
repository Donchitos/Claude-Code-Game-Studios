# Needs & Mood System

> **Status**: APPROVED (2026-07-10 — full review NEEDS REVISION → 11
> must-fixes revised in-session incl. reciprocal villager-ai/building
> patches → verification pass CLEAN after 3 residual mirror-defects fixed;
> see design/gdd/reviews/needs-mood-system-review-log.md)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-10
> **Last Verified**: 2026-07-10
> **Implements Pillar**: Pillar 2 — A settlement that feels alive (primary); Pillar 1 — The building IS the game (furniture satisfies needs: the Building→Needs seam); Pillar 4 — Clarity over complexity (needs/mood shown up front)

## Summary

The Needs & Mood System owns the values that make villagers feel alive:
which needs exist (MVP: sleep), how fast they decay per game tick, when
they become urgent, how activities and furniture restore them, and how
overall need satisfaction rolls up into a single visible **mood**. It is
the scoreboard of the concept's unique hook — furniture carries function —
because a bed's mechanical meaning ("this room is shelter") is defined
here as need-recovery data. Villager AI consumes its urgency signals and
performs the recovery activities; this system never moves a villager.

> **Quick reference** — Layer: `Gameplay` · Priority: `MVP` · Key deps: `Villager AI & Behavior, Time & Tick System, Build Validation & Navigability`

## Overview

**Player-facing:** needs and mood close the game's core loop: build →
furnish → *watch it matter*. The player never manages needs directly —
they read a villager's visible mood and need levels (Villager Info UI)
and respond by building: a bed turns exhausted ground-sleeping into
restful nights, and the villager's mood visibly lifts. Per Pillar 4, the
causality must be legible up front: WHY a villager is unhappy (no bed,
poor sleep) is always readable, so the fix is always buildable. This is
the concept's MVP hypothesis made measurable — "a villager with needs
(sleep) that the home satisfies + visible mood."

**System-facing:** this system is a per-villager value model on game
time. Each need is a 0–100 value decaying per tick; thresholds trigger
urgency (consumed by Villager AI's priority list) and wake/satisfaction;
recovery rates depend on HOW the need is satisfied — the Building→Needs
seam: furniture defines recovery quality (sheltered bed = full-rate
sleep; unsheltered bed = the ×0.7 middle rung; ground = penalized ×0.4 —
the 3-tier ladder, aligned here at the 2026-07-10 verification pass),
which is exactly how "the building IS the stats" (Pillar 1) enters the
simulation. Mood is a derived read-only aggregate
of need satisfaction (MVP: one need → simple mapping; the schema
anticipates more needs and, later, mood modifiers from Relationships/
events). This GDD owns all values and formulas; it owns NO behavior —
Villager AI decides and acts, this system scores.

Out of scope here: which activities exist and how villagers perform them
(Villager AI), what furniture exists (Resource & Item Database / Building
System), mood consequences beyond display (work-speed modifiers, breaks —
Alpha, flagged as an Open Question), and social/relationship needs
(Relationships & Bonds, Alpha).

## Player Fantasy

**"When they're doing well, it's because of me."**

The indirect care-taker fantasy, sharpened to cause and effect:

1. **Reading them.** A glance tells me how my villagers are doing — a
   mood face, a need bar. No spreadsheets, no digging (Pillar 4). Concern
   is legible before it becomes crisis.
2. **Fixing it by building.** Every unhappiness has a buildable answer —
   tired villager, no bed → I build a bed. The emotional loop IS the
   gameplay loop: worry → build → relief. (This is the furniture-carries-
   function hook felt from the caretaker's side.)
3. **Quiet satisfaction.** A settlement of well-rested, content villagers
   is the visible scoreboard of my stewardship — cozy, not min-maxed.
   Mood is a warm signal, not a punishment meter (Pillar 3: threats come
   from waves, not from villagers spiraling into misery).

Reference feeling: RimWorld's need bars for legibility — but explicitly
NOT its mental-break spiral (our mood informs, it does not punish in
MVP); Stonehearth's happiness as ambient warmth. NOT the fantasy: a
tamagotchi (constant urgent maintenance), or an opaque sim where
unhappiness is a puzzle to decode.

> `creative-director` not consulted — Lean mode (non-high-risk section).
> Sourced from game-concept.md (MVP hypothesis, Pillar 3/4) + the
> Building→Needs seam carry-forward. Review manually before production.

## Detailed Design

### Core Rules

**The need model**

1. A need is a per-villager float from 0 (desperate) to 100 (fully
   satisfied). Every need decays by its `decay_per_tick` on each game tick
   except while that need is being recovered. [TR-needs-mood-system-030]
2. **Fixed need schema** (same pattern as the item database's category
   set): the schema knows three needs from day one — `sleep` (MVP),
   `food` (Vertical Slice), `company` (Alpha). MVP fills only `sleep`
   with values. Adding a need type is a design change, not a data edit. [TR-needs-mood-system-031]
3. **Thresholds** (per need) — **state + events-as-hints consumption model**
   *(user decision, 2026-07-10 review — the prior edge-only wording clashed
   with Villager AI's level-polling Rules 2/13; this reconciles both)*:
   - This system maintains a QUERYABLE per-need state (Satisfied/Urgent/
     Recovering + current value) that consumers read at their own decision
     points. [TR-needs-mood-system-032] Villager AI reads state at its `decision_interval` — a missed
     event is therefore harmless, and Save/Load re-derives state from
     values with no signal replay. [TR-needs-mood-system-029]
   - The edge-triggered events remain as NOTIFICATIONS layered on top:
     `urgency_threshold` (default 25) crossing downward emits "need is
     urgent" once (an immediate-preemption hint for Villager AI Rule 2 and
     a display trigger); `satisfied_threshold` (default 95) crossing upward
     during recovery emits "need satisfied" once (wake hint, its Rule 13).
     Events never carry information the state doesn't — consumers MUST
     treat state as the source of truth and events as latency optimization. [TR-needs-mood-system-033]
4. **Recovery happens only through activities** (Villager AI performs
   them; this system scores them). [TR-needs-mood-system-034] Recovery rate depends on the
   **recovery source** — THE Building→Needs seam:

   | Source | Rate | Meaning |
   |--------|------|---------|
   | Owned bed, **sheltered** (inside a valid room) | `bed_recovery_per_tick` (full rate, ×1.0) | The full furniture-carries-function hook: bed + room = proper shelter |
   | Owned bed, **unsheltered** (no valid room) | full rate × `unsheltered_bed_multiplier` (default 0.7) | The bed works, the missing room visibly costs — makes building the room mechanically worthwhile (Pillar 1) |
   | Ground (no bed) | full rate × `ground_penalty` (default 0.4) | Survivable but visibly worse — the buildable-fix signal |

   The source→rate table is owned HERE, keyed by the **recovery-source
   enum** Villager AI reports *(widened at the 2026-07-10 review from the
   prior binary bed/ground)*: `bed_sheltered` / `bed_unsheltered` /
   `ground_no_bed_owned` / `ground_bed_unreachable` / `ground_trapped`.
   The three `ground_*` values share ONE rate row (ground, ×0.4) — the
   distinction exists for the why-string (Core Rule 11), not the math. [TR-needs-mood-system-035]
   The sheltered/unsheltered classification within the enum is supplied by
   Build Validation & Navigability (its Rule 5); reachability/trapped by
   Villager AI (its Rule 12, Edge Case 2). [TR-needs-mood-system-036] Future furniture (VS+) extends
   the table, and quality tiers can multiply it later.
   **Config validation** *(added 2026-07-10 review)*: the ladder ordering
   invariant `ground_penalty < unsheltered_bed_multiplier < 1.0` is
   checked at config load by THIS system (it owns the table); violation
   fails loudly at boot. [TR-needs-mood-system-020] The advisory smoke-check footnote in
   build-validation-navigability.md is a courtesy duplicate, not the
   enforcement.
5. **No death spiral** (Pillar 3): a need at 0 harms nothing in MVP — a
   villager with sleep at 0 simply ground-sleeps wherever it stands
   (Villager AI's urgent priority already guarantees this). Needs create
   care, never fail-states; threats come from waves, not neglect. [TR-needs-mood-system-037]

**Mood**

6. Mood is a derived, read-only 0–100 value: the mean of all active need
   values, **smoothed** over `mood_smoothing_ticks` so it drifts rather
   than flickers (a bad night lingers briefly; a good night's glow lasts).
   MVP: one need → mood ≈ smoothed sleep value. [TR-needs-mood-system-038]
7. Mood is displayed in three bands (colorblind-safe per the Visual
   Direction Note's state axis): **Happy** (≥ 70), **Content** (40–69),
   **Low** (< 40). Bands, not raw numbers, are the player-facing signal. [TR-needs-mood-system-039]
8. **MVP mood is display-only.** No gameplay consequences (work speed,
   breaks) until Alpha — that seam is Open Question 2. [TR-needs-mood-system-040]
9. All values are data-driven config (coding standard); nothing here is
   hardcoded. [TR-needs-mood-system-041]
10. **Recovery-report API** *(added 2026-07-10 review — the report was
    previously shapeless)*: Villager AI reports recovery via DISCRETE
    calls — `start_recovery(need, source_enum)` and
    `stop_recovery(need, reason)` — not per-tick pushes. [TR-needs-mood-system-042] Between start and
    stop, this system re-reads the CURRENT source enum each tick (which is
    how Edge Case 11's mid-recovery upgrade/downgrade re-rating works
    without a restart). [TR-needs-mood-system-043] **Intra-tick ordering**: start/stop reports and
    source changes land BEFORE that tick's F1–F3 pass — an interruption
    tick therefore credits ZERO recovery ("recovery stops that tick" is
    literal). [TR-needs-mood-system-044] In MVP, Villager AI only ever starts recovery while the need
    is Urgent (its Rule 12) — this system does not itself precondition on
    value (see the OQ4 caveat for the anticipatory-sleep landmine).
11. **Why-string ownership** *(user decision, 2026-07-10 review — the
    Pillar-4 deliverable was one example line with no rule)*: THIS system
    owns why-string selection and templates. Selection: the strongest
    current drain = the active need with the LOWEST value, tie-broken by
    schema order (sleep > food > company); empty when no need is below
    `satisfied_threshold` band relevance (mood Happy and nothing urgent). [TR-needs-mood-system-045]
    Templates, keyed by the reported source enum:
    - `ground_no_bed_owned` → "tired — no bed"
    - `ground_bed_unreachable` → "tired — bed unreachable" (the fix is a
      path, NOT another bed)
    - `ground_trapped` → "tired — trapped!" (defers to the distress cue)
    - `bed_unsheltered` → "sleeping rough — no shelter" (the build-a-room
      signal, the ladder's middle rung made legible)
    - `bed_sheltered` / not sleeping → no source suffix. [TR-needs-mood-system-046]
    **UI-slot precedence** (one slot, three feeders): Villager AI
    distress/trapped cue > this system's need-why > Build Validation's
    structural detail string ("the bed can't be reached — the room has no
    opening") — the BVN string appears in the building/bed context, never
    competing in the villager panel's why-slot. [TR-needs-mood-system-047]

### States and Transitions

**Per-need state** (per villager, per need):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Satisfied | Value > `urgency_threshold` (and not Recovering) | Value crosses ≤ threshold → Urgent; OR a `start_recovery` report → Recovering (possible in principle — MVP's AI only starts recovery while Urgent, its Rule 12) | Decays per tick; no signals [TR-needs-mood-system-048] |
| Urgent | Downward cross of `urgency_threshold` | A `start_recovery` report → Recovering *(aligned at the 2026-07-10 review: the prior "recovery raises value above it" described the VALUE's journey, not this state machine's edge — Urgent exits into Recovering on the report, and the value-above-threshold moment happens inside Recovering)* | "Need urgent" event emitted ONCE on entry; queryable state = Urgent; keeps decaying until recovery starts [TR-needs-mood-system-048] |
| Recovering | `start_recovery(need, source_enum)` report (Core Rule 10) | Upward cross of `satisfied_threshold` (→ Satisfied, "need satisfied" emitted ONCE), or `stop_recovery` report (interruption/revocation → Satisfied or Urgent purely by current value; NO new urgent event if the value never rose above the threshold — the original edge already fired and the queryable state still reads Urgent) | Value rises by the CURRENT source's rate per tick (re-read each tick — Edge Case 11); no decay [TR-needs-mood-system-048] |

**Mood bands**: Happy ↔ Content ↔ Low — transitions purely derived from
the smoothed value crossing 70/40; band changes emit a display event for
the Villager Info UI (and nothing else in MVP). [TR-needs-mood-system-049]

### Interactions with Other Systems

- **Villager AI & Behavior** (MVP, mutual — the primary seam): this
  system maintains queryable per-need STATE that Villager AI reads at its
  decision points, with the urgent/satisfied events as latency hints
  (Core Rule 3 — the consumption model pinned at the 2026-07-10 review);
  Villager AI reports recovery via `start_recovery`/`stop_recovery` with
  the source ENUM (Core Rule 10), which this system scores per Rule 4.
  The **Breather** (its Rules 7b/7c) is deliberately EXCLUDED: it reports
  nothing, recovers nothing, and does not pause decay — cosmetic pacing
  only *(exclusion made explicit here at the 2026-07-10 review)*. [TR-needs-mood-system-050]
  Confirms that GDD's provisional Needs interface — its Open Question 1
  is resolved by this GDD (and its PROVISIONAL markers are patched as of
  the 2026-07-10 review — verified in the file this time).
- **Time & Tick System** (upstream, MVP): all decay/recovery on tick
  events; pause halts everything; warp accelerates (a 3x day drains
  needs 3x faster in wall-clock — by design). [TR-needs-mood-system-051]
- **Building System / Resource & Item Database** (indirect): the
  recovery-source table (Rule 4) is keyed by item ids defined in the
  database and placed by the Building System — but neither system is
  called at runtime; Villager AI reports which source it is using. [TR-needs-mood-system-052]
- **Build Validation & Navigability** (MVP, upstream for the shelter
  flag): supplies the per-bed sheltered/unsheltered classification (its
  Rule 5) that selects between the table's top two rungs. Added
  2026-07-10 with the 3-tier ladder. [TR-needs-mood-system-036]
- **Villager Info UI** (MVP, downstream): displays need values, mood
  band, and the WHY (current strongest need drain + missing source, e.g.
  "tired — no bed"), per Pillar 4's legibility rule.
- **Relationships & Bonds** (Alpha, downstream, provisional): will add
  the `company` need's sources and mood modifiers beyond need means.
- **Save/Load** (Vertical Slice, downstream, provisional): serializes
  per-villager need values and mood smoothing state. [TR-needs-mood-system-026]

## Formulas

*(`systems-designer` consulted — mandatory for this high-risk section even
in Lean mode. Review produced 2 revisions (EMA snap rule, F2 stopping
point) and 2 additions (mean definition, spawn initialization); all
incorporated.)*

### F1 — Need decay (per tick, while not Recovering)

`value ← max(0, value − decay_per_tick[need])` [TR-needs-mood-system-030]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `value` | float | 0–100 | Current need value; comparisons are `<=`/`>=` crosses, never equality checks |
| `decay_per_tick[sleep]` | float | > 0, default 0.07 | Full drain 100→0 in ~1429 ticks ≈ 11.9 min game time at 1x |

Time-to-urgent from full: ceil((100 − 25) / 0.07) = 1072 ticks ≈ **8.9
min at 1x** (the chosen pacing; ceil because the signal fires on the
downward cross, per the qa-lead's boundary check).

### F2 — Need recovery (per tick, while Recovering)

`value ← min(100, value + base_recovery_per_tick[need] × source_multiplier)` [TR-needs-mood-system-053]
*(clamp added at the 2026-07-10 review — at legal knob extremes,
satisfied_threshold=100 + increment 2.0 breached the declared 0–100
domain and fed the violation into F3)*

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `base_recovery_per_tick[sleep]` | float | > 0, default 0.5 | Full-rate recovery (owned bed) |
| `source_multiplier` | float | 0–1 | Bed = 1.0; ground = `ground_penalty` = 0.4 |

**Stopping point**: the `satisfied_threshold` (95) cross is the true and
only value-based exit (state table) — the final tick may overshoot 95 by
up to one increment, capped by the domain clamp at 100; that slack is
intentional and the value is simply left where it lands.

Worked: urgent (25) → satisfied (95) = 70 points: **bed sheltered
140 ticks = 70s**; **bed unsheltered (×0.7) 200 ticks = 100s ≈ 1.7 min**
*(middle-rung example added at the 2026-07-10 review — the ladder's
signature value previously had no worked example)*; **ground 350 ticks
≈ 2.9 min** game time at 1x.

### F3 — Mood smoothing (per tick)

`mood ← mood + (mean_active − mood) / mood_smoothing_ticks` — with
explicit float division (`/ 40.0`), and a **snap rule**: if
`abs(mean_active − mood) < 0.05`, then `mood = mean_active` (prevents the
EMA asymptote from permanently stalling just below a band boundary, e.g.
69.97 vs Happy ≥ 70). [TR-needs-mood-system-038] [TR-needs-mood-system-054]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `mean_active` | float | 0–100 | Unweighted arithmetic mean over **active (schema-filled) needs only** — inactive needs (food/company before their tiers) are excluded, never defaulted [TR-needs-mood-system-055] |
| `mood_smoothing_ticks` | float | 10–120, default 40 | = 20s at 1x; ~63% caught up after 40 ticks, ~95% after 2 min |

### F4 — Spawn initialization

`needs ← 100 (each active need); mood ← mean_active` — mood initializes
**equal to** the spawn mean, never 0 (a cold-start at 0 would falsely
display "Low" for ~20s while F3 catches up). [TR-needs-mood-system-056]

### Burst rule (signal ordering)

Within a tick burst (up to `max_ticks_per_frame` = 10), F1–F3 apply per
tick **in order**, and threshold signals are emitted per-tick in-order —
never coalesced or deduplicated across the burst. [TR-needs-mood-system-057] (Today sleep's rates
cannot cross both thresholds in one burst — that is numeric coincidence,
not a guarantee; faster future needs rely on this rule.)

### Deliberately NOT formulas (and why)

- **Which activity recovers which need** — Villager AI behavior.
- **Band mapping** (70/40 comparisons) — a display rule, not math.
- **Mood consequences** — Alpha, Open Question 2.

## Edge Cases

1. **Recovery interrupted mid-way** (bed removed, job preemption). Two
   branches *(the below-threshold branch added at the 2026-07-10 review —
   previously only the above-threshold case was specified)*:
   - Value lands ABOVE `urgency_threshold` (e.g. 60): not a limbo — the
     need is simply Satisfied; decay resumes silently and Urgent
     re-triggers only on the next downward 25-cross. [TR-needs-mood-system-058]
   - Value still AT/BELOW `urgency_threshold` (slow recovery interrupted
     early): the need re-enters Urgent by value — NO new urgent event
     fires (the original edge already fired; the queryable state has read
     Urgent throughout, and Villager AI's state-based consumption — Core
     Rule 3 — needs no second event to act). [TR-needs-mood-system-059]
2. **Need reaches 0.** Value clamps and stays at 0; the Urgent signal
   fired once at the 25-cross and does NOT re-fire at 0 (edge-triggered,
   cross-not-equality). [TR-needs-mood-system-033] No harm occurs (Core Rule 5) — the villager
   ground-sleeps per Villager AI's urgent priority. [TR-needs-mood-system-037]
3. **Recovery source removed mid-recovery** (bed removed while sleeping —
   Building Edge Case 11 / Villager AI Edge Case 5). The notification
   chain *(pinned at the 2026-07-10 review — previously a three-way
   circular punt)*: Building System emits its **bed-revocation event** to
   the owning villager (its new furniture-revocation contract, symmetric
   to job revocation); Villager AI wakes and calls `stop_recovery`; per
   Core Rule 10's intra-tick ordering the stop lands BEFORE that tick's
   F-pass, so the removal tick credits ZERO recovery. [TR-needs-mood-system-060] The need re-enters
   Satisfied or Urgent purely by its current value (Edge Case 1). Villager
   AI owns the wake behavior; this system just stops scoring.
4. **Value sits exactly on a threshold across many ticks.** Signals fire
   only on *crossing* (`<=`/`>=` transitions between ticks), never on
   equality re-checks — a value parked at 25.0 emits nothing new. [TR-needs-mood-system-033]
5. **A new need activates at a tier boundary** (Vertical Slice adds
   `food`). Existing villagers initialize the new need at 100 on first
   load of the new version — nobody starts the patch day starving. [TR-needs-mood-system-061]
   `mean_active` simply gains a term (F3 definition).
6. **A future fast need crosses both thresholds inside one tick burst.**
   The burst rule guarantees per-tick, in-order signal emission —
   Villager AI receives urgent-then-satisfied in order, never a
   deduplicated nothing. [TR-needs-mood-system-057]
7. **Pause.** No decay, no recovery, no mood drift (everything is
   tick-driven); the UI keeps displaying the frozen values. [TR-needs-mood-system-062]
8. **Save/Load** *(Vertical Slice, provisional)*. Need values AND the
   smoothed mood are serialized [TR-needs-mood-system-026]; on load, mood is restored — never
   re-initialized via F4 (that would erase the smoothing state) [TR-needs-mood-system-027]. A saved
   need type no longer in the schema is dropped with a log line, never a
   crash. [TR-needs-mood-system-028]
9. **Time-warp 3x.** All rates are tick-based, so game-time pacing is
   invariant; wall-clock everything runs 3x — a deliberately
   faster-breathing settlement. [TR-needs-mood-system-063]
10. **Mood band flapping at a boundary** (69.9 ↔ 70.1). The EMA smoothing
    is the primary anti-flicker mechanism and the snap rule settles
    stable states. If playtests still show band flapping, add a ±1
    display hysteresis as a UI-side tuning — noted in Tuning Knobs, not
    pre-built.
11. **Recovery source UPGRADED mid-recovery** (the roof completes while
    the villager is already asleep in the until-now unsheltered bed —
    Build Validation emits `shelter_status_changed` during Recovering).
    The source→rate table is re-evaluated per tick: the new (higher) rate
    applies from the next tick onward; no restart, no signal, no lost
    progress. The mirror case (downgrade — roof removed mid-sleep)
    behaves identically with the lower rate. [TR-needs-mood-system-043] *(Added 2026-07-10 — the
    cross-review scenario walkthrough found this transition only
    implicitly defined.)*

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Time & Tick System | ✅ Approved | Tick events for all decay/recovery/mood math; pause/warp semantics [TR-needs-mood-system-051] |
| Villager AI & Behavior | ✅ Approved (mutual) | `start_recovery`/`stop_recovery` reports with the recovery-source ENUM (Core Rules 4, 10 — widened from binary bed/ground at the 2026-07-10 review; its Rules 11–12) [TR-needs-mood-system-042] |
| Build Validation & Navigability | ✅ Designed | The sheltered/unsheltered classification within the source enum (its Rule 5) *(row added at the 2026-07-10 review — this upstream was named in prose but missing from the formal table, violating bidirectionality)* [TR-needs-mood-system-036] |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Villager AI & Behavior | MVP | ✅ Designed (mutual) | "Need urgent"/"need satisfied" signals (its Rules 2, 13) — its provisional Needs interface is CONFIRMED by this GDD [TR-needs-mood-system-033] |
| Villager Info UI | MVP | ✅ Designed — contract CONFIRMED (its Rule 5 consumes values/band/why-string verbatim; status refreshed 2026-07-10) | Need values, mood band, the why-string (Core Rule 11 — this system owns selection + templates; precedence rule there) [TR-needs-mood-system-064] |
| Relationships & Bonds | Alpha | Undesigned | The `company` need slot + mood modifier seam *(provisional)* |
| Professions & Ranks / work systems | Alpha | Undesigned | Mood consequences (work speed etc.) once Open Question 2 resolves *(provisional)* |
| Save/Load & World Persistence | Vertical Slice | Undesigned | Need values + smoothed mood serialization (Edge Case 8) *(provisional)* [TR-needs-mood-system-026] |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `decay_per_tick[sleep]` | 0.07 | 0.03–0.2 | The session rhythm: ~9 min to urgent at default; 0.2 ≈ tamagotchi territory (avoid); 0.03 → ~20.8 min to urgent, well past the "~10-minute heartbeat" (dead air — the slow extreme is as risky as the fast one). **Pacing cross-reference** *(added 2026-07-10 review)*: a minimal room+bed builds in ~1–2 min (building-system F3) while urgency arrives at ~8.9 min — the ~6–7 min gap inside the concept's ~10-min MVP test window is a DELIBERATE HYPOTHESIS ("the wait is settlement-watching, not dead air"), tested by the MVP playtest probe in Game Feel, NOT tuned on paper. Retuning either side's knobs must revisit this note |
| `base_recovery_per_tick[sleep]` | 0.5 | 0.2–2.0 | Sleep duration (~70s in bed at default) |
| `ground_penalty` | 0.4 | 0.1–0.8 | How much worse bed-less sleep is — the strength of the "build a bed" signal. Too close to 1.0 kills the furniture hook |
| `unsheltered_bed_multiplier` | 0.7 | 0.5–0.9 | The middle rung of the recovery ladder (bed outside a valid room). **Invariant: `ground_penalty` < this < 1.0** — outside that order the ladder collapses. Owned HERE (this table is the source of truth); Build Validation supplies only the sheltered flag (added 2026-07-10, cross-review ownership fix) [TR-needs-mood-system-020] |
| `urgency_threshold` | 25 | 10–40 | When villagers drop work to satisfy a need |
| `satisfied_threshold` | 95 | 80–100 | When recovery ends (wake) |
| `mood_smoothing_ticks` | 40 | 10–120 | Mood inertia — how long a bad night lingers |
| Mood band boundaries | 70 / 40 | display contract | Shared verbatim with Villager Info UI — changing them is a UI-coupled design change [TR-needs-mood-system-039] |
| Band display hysteresis | 0 (off) | 0–3 | Anti-flapping reserve (Edge Case 10) — enable only if playtests show flicker |

All values data-driven per the coding standard; none are player-facing. [TR-needs-mood-system-041]

## Visual/Audio Requirements

This system renders nothing. It requires the Villager Info UI / art bible
to provide: three mood-band icons (readable at a glance, colorblind-safe
per the Visual Direction Note — never red-green), and a need-bar
treatment. Audio: none in MVP (an optional gentle band-up chime is a
Polish candidate, not a requirement).

## Game Feel

The feel target is a *breathing* settlement: needs create a ~10-minute
heartbeat (work → tire → sleep → refreshed) that the player senses
without watching numbers. Mood drifts rather than snaps (smoothing =
emotional inertia — villagers aren't light switches). Tone per Pillar 3:
a Low villager looks tired-cozy, never suffering-grimdark.

**Feel acceptance criteria** (subjective, playtest-verified; referenced
by AC35): a first-time player, asked "why is the villager unhappy?",
answers correctly within one need cycle without a tutorial; nobody
describes the needs as "nagging"; **(added 2026-07-10 review)** the
build→wait→payoff rhythm reads as intentional (players report the ~7-min
pre-urgency stretch as settlement-watching, not dead air — the Tuning
Knobs pacing hypothesis); and players notice and mention the mood lift
after building a bed UNPROMPTED (Beat 3's "quiet satisfaction" — the
display-only-mood bet made falsifiable).

## UI Requirements

None owned — supplies to Villager Info UI: per-need values (0–100), mood
band (3 states + display events on change), and the **why-string** —
selection rule, full template set (per source enum), and UI-slot
precedence are Core Rule 11 *(promoted from a single example line at the
2026-07-10 review)*. [TR-needs-mood-system-064] Pillar 4 contract: the UI must never show a mood
without the reason being one interaction away — and the reason must
never direct the player to the WRONG fix (a trapped villager's string
says "trapped", not "no bed"). [TR-needs-mood-system-046]

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| Urgency/wake signal consumption, recovery activities, bed ownership | `design/gdd/villager-ai-behavior.md` | Rules 2, 11–13; Open Question 1 | Mutual contract — CONFIRMED by this GDD (patch its provisional markers) |
| Tick events, pause/warp | `design/gdd/time-tick-system.md` | Core Rules | Time base |
| `bed` definition; furniture placement | `design/gdd/resource-item-database.md`, `design/gdd/building-system.md` | bed id, furniture tool | Recovery-source table keys (Rule 4) |
| MVP hypothesis, Pillars 1/3/4 | `design/gdd/game-concept.md` | MVP Definition, Pillars | Scope authority; "visible mood" mandate |
| Colorblind-safe state colors | `design/art/visual-direction-note.md` | State axis | Band display constraint |
| `bed`, `ticks_per_second`, `max_ticks_per_frame` | `design/registry/entities.yaml` | Registry facts | Data dependency; new constants registered at Phase 5 (thresholds, ground_penalty — consumed by Villager AI) |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Review produced 1 rewrite, 1 doc off-by-one fix (F1: 1072 ticks),
and 5 missing criteria; all incorporated. Villager AI activity reports
are mocked at the boundary per testing standards.)*

**Signals & decay**
1. **GIVEN** a need at 100 and no recovery, **WHEN** 1 tick fires, **THEN** the value decreases by exactly `decay_per_tick` (F1). [TR-needs-mood-system-030]
2. **GIVEN** a need below `decay_per_tick`, **WHEN** a tick fires, **THEN** the value clamps to exactly 0 and stays (F1). [TR-needs-mood-system-030]
3. **GIVEN** a need decaying across `urgency_threshold`, **WHEN** the cross occurs, **THEN** exactly one "need urgent" signal is emitted (edge-triggered). [TR-needs-mood-system-033]
4. **GIVEN** a need parked exactly at the threshold for many ticks, **WHEN** ticks fire, **THEN** no additional signals are emitted (Edge Case 4). [TR-needs-mood-system-033]
5. **GIVEN** a need at 0 for many ticks, **WHEN** ticks fire, **THEN** no repeated urgent signals are emitted (Edge Case 2). [TR-needs-mood-system-033]
6. **GIVEN** a need at 0 for many ticks, **WHEN** ticks fire, **THEN** no signal, event, or state change beyond the sustained clamp occurs — "harms nothing" is literal (Rule 5). [TR-needs-mood-system-037]
7. **GIVEN** no recovery, **WHEN** decaying from 100 at defaults, **THEN** the urgent signal fires after exactly ceil(75/0.07) = **1072 ticks** (F1 boundary test). [TR-needs-mood-system-030]

**Recovery**
8. **GIVEN** a Recovering need with a mocked bed source, **WHEN** 1 tick fires, **THEN** the value increases by exactly `base_recovery_per_tick` × 1.0 (F2). [TR-needs-mood-system-053]
9. **GIVEN** a mocked ground source, **WHEN** 1 tick fires, **THEN** the increase is × `ground_penalty` (F2). [TR-needs-mood-system-053]
10. **GIVEN** a mocked NEW source id with its own multiplier, **WHEN** Recovering, **THEN** F2 applies via table lookup — no hardcoded two-source branch (Rule 4 extensibility). [TR-needs-mood-system-065]
11. **GIVEN** a Recovering need crossing `satisfied_threshold`, **WHEN** the cross occurs, **THEN** exactly one "need satisfied" signal is emitted, recovery stops, and overshoot of at most one increment is retained (F2). [TR-needs-mood-system-033] [TR-needs-mood-system-053]
12. **GIVEN** no recovery-activity report from Villager AI, **WHEN** a need sits below the urgency threshold for many ticks, **THEN** it never enters Recovering — recovery cannot self-trigger from value alone (state table). [TR-needs-mood-system-048]
13. **GIVEN** a recovery interrupted between thresholds (e.g. 60), **WHEN** the interruption registers, **THEN** the need re-enters Satisfied, decays normally, and re-triggers Urgent only at the next 25-cross (Edge Case 1). [TR-needs-mood-system-058]

**Mood**
14. **GIVEN** a mocked `mean_active` differing from mood **by at least 0.05** (outside the F3 snap zone — precision fix, 2026-07-10 review), **WHEN** 1 tick fires, **THEN** mood moves by exactly (mean − mood) / `mood_smoothing_ticks` in float math (F3). [TR-needs-mood-system-038]
15. **GIVEN** abs(mean − mood) < 0.05, **WHEN** a tick fires, **THEN** mood snaps exactly to mean (F3 snap). [TR-needs-mood-system-054]
16. **GIVEN** `mean_active` stable at 70 for enough ticks that the snap condition is met, **WHEN** it fires, **THEN** mood == 70.0 exactly and Happy activates (F3 anti-asymptote, bounded claim). [TR-needs-mood-system-054]
17. **GIVEN** a new villager spawns, **WHEN** initialized, **THEN** every active need is 100 and mood equals `mean_active` — never 0 (F4). [TR-needs-mood-system-056]
18. **GIVEN** mood crossing a band boundary, **WHEN** the cross occurs, **THEN** exactly one band-change display event is emitted. [TR-needs-mood-system-049]
19. **GIVEN** default hysteresis = 0, **WHEN** mood crosses 70.00 or 40.00 exactly, **THEN** the band event fires at the boundary tick — no implicit dead zone (Edge Case 10). [TR-needs-mood-system-049]
20. **GIVEN** inactive schema needs (food/company pre-tier), **WHEN** `mean_active` is computed, **THEN** they are excluded — a lone sleep of 60 yields mean 60, not 86.7 (F3 definition). [TR-needs-mood-system-055]

**Time, lifecycle, persistence**
21. **GIVEN** a tick burst of `max_ticks_per_frame`, **WHEN** processed, **THEN** F1–F3 apply per tick in order and threshold signals are emitted in order, never coalesced (burst rule). [TR-needs-mood-system-057]
22. **GIVEN** identical tick counts dispatched at 1x vs 3x warp, **WHEN** F1/F2 apply, **THEN** the resulting values are identical — rates are functions of tick count, never wall-clock (Edge Case 9). [TR-needs-mood-system-063]
23. **GIVEN** pause (zero ticks), **WHEN** real time passes, **THEN** values and mood are unchanged (Edge Case 7). [TR-needs-mood-system-062]
24. **[Integration, VS+ — DEFERRED pending the Save/Load & World Persistence GDD]** **GIVEN** a save with need values and mood, **WHEN** loaded, **THEN** mood is restored as-saved, never re-initialized via F4 (Edge Case 8; mocked serializer now; tag convention aligned 2026-07-10). [TR-needs-mood-system-027]
25. **[Integration, VS+ — DEFERRED pending the Save/Load & World Persistence GDD]** **GIVEN** a saved need type no longer in the schema, **WHEN** loaded, **THEN** it is dropped with a log line, never a crash (Edge Case 8). [TR-needs-mood-system-028]
26. **GIVEN** a version adds a new active need (mocked schema change), **WHEN** an existing villager loads, **THEN** the new need initializes at 100 (Edge Case 5). [TR-needs-mood-system-061]
27. **GIVEN** default values, **WHEN** a full sleep cycle runs (100 → urgent → bed recovery → satisfied), **THEN** the urgent event fires at tick 1072 and the satisfied event at tick 1212 — EXACT tick counts, never wall-clock *(rewritten 2026-07-10: the prior "±5%" invited a wall-clock reading, a determinism violation; the cycle is fully deterministic in ticks)*. [TR-needs-mood-system-066]

**Added at the 2026-07-10 review:**
28. **GIVEN** a mocked `bed_unsheltered` source, **WHEN** 1 tick fires, **THEN** the increase is exactly `base_recovery_per_tick` × `unsheltered_bed_multiplier` (the ladder's middle rung — previously the doc's signature value had no AC). [TR-needs-mood-system-053]
29. **GIVEN** a config where `ground_penalty ≥ unsheltered_bed_multiplier` or `unsheltered_bed_multiplier ≥ 1.0`, **WHEN** config loads, **THEN** the load fails loudly naming the invariant (Core Rule 4 config validation — enforcement now lives in the OWNING doc). [TR-needs-mood-system-020]
30. **GIVEN** a need Recovering at the `bed_unsheltered` rate, **WHEN** the reported source enum changes to `bed_sheltered` mid-recovery (shelter_status_changed), **THEN** from the next tick the full rate applies with no restart, no signal, no lost progress; **AND** the mirror downgrade applies the lower rate identically (Edge Case 11 — previously zero coverage). [TR-needs-mood-system-043]
31. **GIVEN** a recovery interrupted while the value is still ≤ `urgency_threshold`, **WHEN** `stop_recovery` lands, **THEN** the need re-enters Urgent by value, NO second urgent event fires, and the queryable state reads Urgent throughout (Edge Case 1, below-threshold branch). [TR-needs-mood-system-059]
32. **GIVEN** each reported source enum value with an urgent sleep need, **WHEN** the why-string is queried, **THEN** it matches Core Rule 11's template for that enum exactly ("tired — no bed" / "tired — bed unreachable" / "tired — trapped!" / "sleeping rough — no shelter"); **AND GIVEN** no need is urgent and mood is Happy, **THEN** the why-string is empty. [TR-needs-mood-system-045] [TR-needs-mood-system-046]
33. **GIVEN** a value at 99.0 with `satisfied_threshold` = 100 and increment 2.0 (legal knob extremes), **WHEN** a recovery tick fires, **THEN** the value is exactly 100.0, never above (F2 domain clamp). [TR-needs-mood-system-053]
34. **[Integration — live pair, per the villager-ai AC40/40b precedent]** **GIVEN** a REAL Needs instance and a REAL Villager AI villager with an owned sheltered bed (no mocks at the seam), **WHEN** the need decays from 100 through urgent → the AI claims/travels/sleeps → recovery → satisfied → wake, **THEN** the full round trip completes: state transitions, `start_recovery`/`stop_recovery` calls, and both events observed in order — closing the mutual-mock coverage gap. [TR-needs-mood-system-025]
35. **[Visual/Feel, Advisory — playtest-gated]** The Game Feel acceptance criteria (legibility, no-nagging, pacing-hypothesis, unprompted-mood-notice) are evaluated at the MVP playtest and their outcomes recorded in `production/qa/evidence/` (previously orphaned from the AC list). [TR-needs-mood-system-067]

*Advisory (not a Logic AC): Rule 8's "mood is display-only" is an absence
claim — verified via an architectural contract check (no mood-consuming
API in work/scheduling code), owned alongside code review, not the
blocking test gate.*

## Open Questions

1. **Mood consequences** — work speed, breaks, celebration behaviors once
   mood stops being display-only. → *Professions & Ranks / economy GDDs,
   Alpha (the seam Rule 8 reserves)*
2. **`food` need design** — sources, hunger pacing, the eating activity,
   interplay with Gathering & Production. → *this GDD's Vertical Slice
   revision + Gathering & Production Chains GDD*
3. **`company` need + mood modifiers beyond need means** —
   → *Relationships & Bonds GDD, Alpha*
4. **Day/night rhythm** — shared open question with Villager AI (its OQ
   4): a clock would let sleep anticipate night instead of pure decay.
   **Caveat (2026-07-10 review — the dead-man landmine)**: Recovering's
   exit-on-satisfied-cross assumes recovery always STARTS below
   `satisfied_threshold`; any anticipatory-sleep design must define an
   immediate-satisfied case for recovery starting already above it, or
   the villager never receives the satisfied event and never wakes.
   → *Alpha, owner TBD (Time & Tick extension)*
5. **Furniture quality multiplying recovery** — the concept's
   crafting-quality tiers (a masterwork bed heals faster?) extend the
   source→rate table. → *crafting/quality GDDs, Alpha*
6. **Band hysteresis** — enable only if playtests show flapping (Edge
   Case 10, Tuning Knobs). → *MVP playtest*
7. **VS synchronized-spawn decay spike** *(2026-07-10 review)* — all ~5
   Vertical Slice villagers spawn together at need=100 (F4, villager-ai
   Rule 14b), so their decay clocks are synchronized: everyone turns
   tired at once around minute ~9. Pleasant day/night-adjacent beat or
   jarring simultaneous crisis? Decide (stagger spawn values? embrace as
   rhythm?) before VS tuning. → *this GDD's VS revision + villager-ai*
8. **EMA ramp-lag disclosure** *(2026-07-10 review)* — during active
   recovery, mood trails the true need value by ≈ recovery-rate ×
   `mood_smoothing_ticks` (~20 points at defaults; at extreme legal knobs
   the lag exceeds the scale). Acceptable inertia or does "mood visibly
   lifts" need a faster-catching smoothing during recovery? → *MVP
   playtest, alongside the band-hysteresis question*
