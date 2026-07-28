# Creative Direction — M02 Pre-Flight Rulings

> ⚠️ **PROVISIONAL — PENDING USER RATIFICATION.** Produced under an away-mode
> delegation (creative-director, autonomous pass). These are rulings with full
> rationale, not approved changes. Nothing in `production/session-state/` was
> touched, no code or config was edited, nothing was committed. Both rulings
> below become binding only on the user's ratification.

**Date**: 2026-07-26
**Author**: creative-director (delegated, autonomous)
**Rules on**: Milestone 02 criterion #4 (pacing half) and criterion #7 (payoff
signal shape)
**Sources read**: `production/epics/needs-mood-system/story-009-real-time-rate-pass.md`;
`design/gdd/needs-mood-system.md` (F1–F4, Tuning Knobs, Game Feel);
`design/quick-specs/tick-rate-retune-2026-07-25.md`;
`design/gdd/building-system.md` (F3, Tuning Knobs);
`production/epics/build-validation-navigability/story-009-loop-payoff-real-signal-wiring.md`;
`neues-spiel/src/presentation/loop_payoff_signal_surface.gd`;
`design/gdd/build-validation-navigability.md` (Rule 11, Visual/Audio, Tuning Knobs, AC21/32/32b);
`design/gdd/game-concept.md` (Pillars); `prototypes/last-seal-vertical-slice/REPORT.md`.

---

# Ruling 1 — Real-Time Pacing: **Option B, unmodified. All three knobs ship at their GDD defaults.**

## Context

`ticks_per_second` moved 2.0 → 4.0 in the slice revision (user-ratified, "villagers
should work more"). Every real-time figure in the Needs & Mood GDD, and every
`= Ns at 1x` annotation in the Building System GDD, was computed at 2.0 and is
therefore 2× stale. The GDD's headline pacing claim — a ~6–7 minute gap between
shelter-readiness and need onset, inside a ~10-minute heartbeat — rests on two
stale halves.

Story 009 frames this as a binary: **A** retune the knobs to buy back the original
wall-clock pacing (`decay_per_tick` 0.07→0.035, `base_recovery_per_tick` 0.5→0.25,
`mood_smoothing_ticks` 40→80), or **B** keep the tick anchors and restate their
real-time meaning.

## Decision

**Option B. Ship `decay_per_tick[sleep] = 0.07`, `base_recovery_per_tick[sleep] = 0.5`,
`mood_smoothing_ticks = 40`. No knob changes. No carve-outs.**

The GDD's *real-time prose* is **RETUNED BY RESTATEMENT**, explicitly and by name —
criterion #4's "confirmed or retuned with rationale" is answered as: the tick
anchors are CONFIRMED; the wall-clock feel targets derived from them are
RESTATED to the following, which become the new official feel targets:

| Feel target | Old (stale, computed at TPS 2.0) | **New official (TPS 4.0)** |
|---|---|---|
| Settlement heartbeat (full cycle: satisfied → urgent → sleep → satisfied) | "~10-minute heartbeat" | **~4 min 45 s heartbeat** |
| Time to urgent from full (100 → 25) | 1072 ticks ≈ 8.9 min | 1072 ticks = **4 min 28 s** |
| Full drain (100 → 0) | 1429 ticks ≈ 11.9 min | 1429 ticks = **5 min 57 s** |
| Sleep, sheltered bed (25 → 95) | 140 ticks = 70 s | 140 ticks = **35 s** |
| Sleep, unsheltered bed (×0.7) | 200 ticks = 100 s | 200 ticks = **50 s** |
| Sleep, ground (×0.4) | 350 ticks ≈ 2.9 min | 350 ticks = **1 min 27 s** |
| Mood inertia (63% step response) | 40 ticks = 20 s | 40 ticks = **10 s** |
| Minimal room + bed build | "~1–2 min" (building F3) | **~30–60 s** |
| **The deliberate gap** (shelter ready → urgency) | "~6–7 min" | **~3 min** |

The `mood_smoothing_ticks` knob is explicitly included in the "no change" ruling.
I considered carving it out and reversed myself — see Alternatives, item 3.

## Rationale

**1. Option A puts the first payoff outside the test window. This is decisive.**

The milestone exists so that "is drawing a room, furnishing it, and watching a
villager live there satisfying?" becomes testable by a human for the first time.
The instrument is a ~10-minute unguided walkthrough. Trace both options through it:

*Option B (ship the anchors):*
- ~0:00–1:00 — player draws a hut; workers build (blocks 1 s/cell, bed 2 s)
- ~1:30 — shelter ready, bed claimable
- ~1:30–4:28 — **~3 minutes of settlement-watching** (the deliberate gap)
- ~4:28 — urgency; claim, travel, sleep (35 s)
- ~5:15 — wake at satisfied
- ~5:30–5:45 — mood climbs into Happy; the "quiet satisfaction" beat lands
- ~9:30 — second onset begins; second sleep completes just past the ten-minute mark

**One complete, unmistakable onset → shelter → recovery → mood-lift arc, finished
by minute six, with a second onset visibly beginning before the session ends.**

*Option A (buy back the original wall-clock):*
- ~2:30 — shelter ready (build times double back too)
- ~8:56 — urgency
- ~10:15 — wake
- ~10:45 — mood lift

**The payoff completes after the window closes.** A ten-minute unguided run at
Option A pacing shows a player: a hut being built, roughly six and a half minutes
of nothing, and a villager lying down as the session ends. The recovery — the
mechanic this entire milestone exists to make real — never arrives. The mood lift,
which the GDD's own Feel AC says the player must notice *unprompted*, never happens.

I will not ratify a pacing that makes the milestone's central hypothesis
unobservable inside the milestone's own test instrument.

**2. The "we lose the designed relationships" objection is arithmetically false.**

Every rate in this system is tick-denominated. Decay, recovery, smoothing, build
time, cue cooldown — all of them. The 2.0 → 4.0 change therefore preserved *every
internal ratio in the game exactly*. Mood is exactly as inertial relative to the
need cycle as it was designed to be. The bed is exactly as much better than the
ground. The gap is exactly the same fraction of the heartbeat. Nothing about the
game's internal rhythm changed. **Only the wall-clock tempo changed** — and
wall-clock only matters where it meets something that is *not* tick-denominated:
human attention span, the ten-minute probe, and human perceptual thresholds.

Against all three, faster is better here. Ten seconds of mood drift still reads
unmistakably as drift, not as a snap. Three minutes of settlement-watching is still
a wait. And a ~4:45 heartbeat fits the probe; a ~9:30 heartbeat does not.

Option A therefore spends a real cascade — two AC anchors (AC7, AC27), three GDD
arithmetic passages, two test files, all of which must move in perfect lockstep or
the suite goes green against a stale anchor — to buy a *slower* tempo we have
independent reason to believe is worse. That is not a trade-off. It is a pure loss
plus a regression risk.

**3. We have not yet earned a seven-minute wait.**

The slice's verdict was blunt: *"Atmosphere is the weak axis: direction right, mood
lacking — the world lacks life (audio, ambient motion, weather, interior detail)."*
Ambient life wave 1 is landing **in this milestone** (criterion #8) and is not
proven yet. The "the wait is settlement-watching, not dead air" hypothesis is a bet
on content we do not yet have. Betting on it for three minutes is a reasonable
risk. Betting on it for six-to-seven, in a world the last tester described as
lifeless, is how you get the slice's "mostly" verdict a second time.

Shorten the exposure while the content that has to fill it is still being built.
If Cluster D lands well and the settlement genuinely rewards watching, lengthening
the gap later is a one-line config change. That is the correct order of operations.

**4. The nagging risk is small and named.**

At these values a villager spends ~35 s of every ~4:45 cycle need-driven — roughly
12% of its life. The GDD's own "tamagotchi territory" marker is `decay_per_tick =
0.2` (94 s to urgent at TPS 4.0); we sit at nearly 3× slower than that, comfortably
inside the declared 0.03–0.2 safe band with headroom in both directions. The
reversal, if the probe reports nagging, is one config value.

**5. The producer's "two full observations" claim is optimistic — I am not relying on it.**

The arithmetic gives one complete cycle plus a strong second onset in ten minutes,
not two complete cycles (the second sleep finishes around 10:10–10:30). This ruling
stands on "one complete arc, comfortably inside the window, with a second onset
visible" — which is sufficient and honest. The story's rationale should be corrected
to match; overstating it invites a disappointed re-litigation later.

## Pillar Alignment

- **Pillar 2 (a settlement that feels alive)** — SERVED, and this is the deciding
  pillar. More observable life events per minute of play. A villager whose day has
  a visible rhythm reads as a person; one that does the same thing for nine minutes
  reads as a prop.
- **Pillar 4 (clarity over complexity)** — SERVED. Causal attribution decays with
  elapsed time. A player is far more likely to connect *"I built that bed"* to
  *"he's happier now"* across three minutes than across seven. This is the whole
  mechanism behind the "notices the mood lift unprompted" Feel AC.
- **Pillar 3 (cozy, but with stakes)** — NEUTRAL, watched. Cozy is threatened by
  needs that *nag*, not by needs that *cycle*. At 12% need-driven time we are not
  near that line. This is the pillar the falsification criterion below protects.
- **Pillar 1 (the building IS the game)** — SERVED, mildly. A shorter gap means the
  player's build is validated by a villager sooner, which is the mechanical meaning
  Pillar 1 demands that every structure carry.

## Aesthetic Impact (MDA)

Primary aesthetic served: **Fantasy** (stewardship of a living place) and
**Discovery** (noticing the settlement answer back). Both are *observation*
aesthetics — they are paid out in events per unit of attention, and a faster
heartbeat raises that rate directly. **Submission** (the relaxed, ambient register)
is the one at mild risk; it is protected by the nagging kill-criterion below.

Psychologically: this is a **Competence** delivery problem. The player's sense that
their build *worked* is the reward, and reward attribution weakens sharply with
delay. Option A's nine-minute delay between action and consequence is close to the
worst case for felt competence.

## Impact

- **game-designer / systems-designer** — story-009 becomes a pure documentation
  pass. No `.tres` edits, no AC anchor moves, no test edits. Scope shrinks.
- **`design/gdd/needs-mood-system.md`** — F1, F2, F3 real-time figures, the Tuning
  Knobs pacing cross-reference, and the **Game Feel section's "~10-minute heartbeat"
  and "~7-min pre-urgency stretch"** are restated to the table above. The Game Feel
  restatement is mine, not a mechanical conversion — do not skip it.
- **`design/gdd/building-system.md`** — F3's variable table (`= 2.0s`, `= 4.0s`),
  the two `base_build_ticks` Tuning Knob annotations, and both `base_demolition_ticks`
  mirrors are stale by the same factor. Coordinate; story-009 does not own that GDD.
- **qa-lead** — the playtest probe (story 011) inherits the falsification criteria
  below verbatim.
- **producer** — story-009's Option-A branch scope is dropped; its "two observations"
  rationale line is corrected.

### Propagation residue — this is a project-wide class, not a needs-mood bug

The tick-rate quick-spec already caught one instance outside Needs & Mood
(`decision_interval`, silently halved to 0.5 s). Here are three more:

- `build-validation-navigability.md` Tuning Knobs: `room_cue_cooldown_ticks`
  **"20 (= 10s at 1x)"** → actually **5 s** at TPS 4.0. *This one lands directly on
  Ruling 2's celebration pacing.*
- `building-system.md`: `base_build_ticks[block]` **"4 (= 2.0s at 1x)"** → **1.0 s**;
  `[furniture]` **"8 (= 4.0s at 1x)"** → **2.0 s**; both `base_demolition_ticks`
  mirrors inherit it.
- `villager-ai-behavior.md`: `unreachable_retry_ticks` and the watchdog cadence
  should be checked for the same annotation vintage.

**Recommendation:** widen story-009's doc-completeness AC from "search
needs-mood-system.md for second-based figures" to a **repo-wide grep of `design/`
for `at 1x` and any `= Ns`/`≈ N min` annotation authored before 2026-07-23**.
Every such annotation predating the slice revision is 2× stale by construction.
One sweep, one change, one rationale artifact — otherwise this bug will keep
surfacing one GDD at a time for another three sprints.

## Alternatives Considered

1. **Option A (full retune to preserve wall-clock).** Rejected — moves the first
   payoff outside the ten-minute probe (Rationale 1), buys back a slower tempo we
   have reason to believe is worse (Rationale 3), and pays a two-AC/two-test-file
   lockstep cascade for the privilege. The one thing it genuinely protects — the
   *designed internal relationships* — was never actually at risk (Rationale 2).

2. **A middle position** (e.g. `decay_per_tick` 0.055 → ~5:41 to urgent). Rejected.
   It incurs the same AC/test cascade as Option A while producing a number no one
   has any evidence for. If we are going to move this knob, we should move it
   *after* a human has played it, with the direction and magnitude the playtest
   indicates. Shipping the anchor and measuring dominates guessing on paper — which
   is the GDD's own stated position on this value.

3. **Hybrid: Option B for decay/recovery, Option A for `mood_smoothing_ticks` only
   (40 → 80).** Considered seriously, then **rejected on re-derivation.** The
   argument for it was that 10 s of inertia is too snappy to read as "emotional
   inertia," making mood a duplicate readout of the need bar. That argument does not
   survive the arithmetic: because the EMA's ramp lag is tick-denominated
   (≈ per-tick recovery delta × smoothing window = 0.5 × 40 = 20 points), mood's
   trail behind the need — and therefore *where in the cycle the band-up event
   fires* — is byte-identical at TPS 2.0 and 4.0. Only its wall-clock duration
   halved, and 10 s still reads unambiguously as drift rather than a snap. The
   carve-out would have bought a cosmetic difference at the cost of touching
   story-001's config defaults and story-005's worked example. Dropped.

4. **Defer the whole decision to the playtest.** Rejected — criterion #4 requires
   a recorded resolution *inside* Cluster A, and the probe cannot run until a value
   ships. Something has to be shipped to be measured. This ruling ships the cheaper,
   reversible one.

## Design Test — how we know this was right

**CONFIRM** the ruling if, in the story-011 ten-minute unguided walkthrough:
1. The tester observes at least one complete onset → shelter → recovery arc
   **unprompted**, and can say afterward what happened.
2. Asked *"why is the villager unhappy?"*, the tester answers correctly within one
   need cycle, with no tutorial.
3. The tester mentions the mood lift after the bed **unprompted** (the GDD's
   existing display-only-mood bet).
4. Nobody uses the word "nagging," or its German equivalents ("nervt", "ständig").

**KILL** the ruling — retune `decay_per_tick` **0.07 → 0.05** (a measured step, not
a reflex return to 0.035) — if either:
- The tester interrupts their own building more than once to attend to needs, or
  describes the villagers as always wanting something; or
- The tester reports the villager seems to sleep constantly.

**DO NOT respond by slowing decay** if the tester reports the pre-urgency stretch as
dead air or boring. That is an **ambient-life finding (Cluster D)**, not a pacing
finding, and the correct response is content, not a knob. Slowing decay in response
to a content problem makes the content problem *longer*. This distinction must be
written into the probe's reporting template, or it will be conflated under
observation pressure.

---

# Ruling 2 — Loop-Payoff Signal Shape: **the signal is untouched; a typed, optional detail sidecar carries the pacing contract.**

## Context

`LoopPayoffSignalSurface`'s sole signal is
`payoff_signaled(payoff_type: StringName, subject: StringName)`, and the module's
own contract forbids *"a new signal or a reshaped parameter list"* — a new payoff
kind must be a new `payoff_type` value. Milestone criterion #7 requires that
`room_recognized`'s `celebrate: bool` and `pass_group_id` survive to presentation.
Two facts do not fit into two opaque `StringName`s. The celebration beat is
CD-protected (Art Bible §5.6 lineage; build-validation Visual/Audio).

## Decision

**Preserve `payoff_signaled(payoff_type, subject)` byte-identical. Add an
additive, optional, *typed* detail sidecar on the same module.** Concretely:

```
signal payoff_signaled(payoff_type: StringName, subject: StringName)   # UNCHANGED

func emit_payoff(payoff_type: StringName, subject: StringName,
                 detail: PayoffDetail = null) -> void                   # trailing optional
func get_payoff_detail(payoff_type: StringName, subject: StringName) -> PayoffDetail
```

`PayoffDetail` is a small typed `RefCounted` (not a Dictionary — static typing is
enforced project-wide) carrying, for the recognition kinds:
`celebrate: bool`, `group_id: StringName`, `subjects: Array[StringName]`,
`cells: PackedVector3Array`.

**Binding implementation constraints (these are the load-bearing part, not the
class shape):**

1. `_active_payoffs[key]` **and** the detail are written **before**
   `payoff_signaled.emit(...)`, so a synchronous handler calling
   `get_payoff_detail()` from inside the handler sees the current record. Without
   this ordering the sidecar is useless.
2. `clear_payoff()` erases the detail alongside the key. No orphaned payloads.
3. No `CONNECT_DEFERRED` anywhere on this path (already an Engine Note on the
   story — promote it to an asserted grep-guard, not a comment).
4. Presentation holds **no** reference back to the analysis module. Everything
   needed to draw the beat arrives with the event.

**Type/subject assignment — and the general rule behind it:**

| Emission | `payoff_type` | `subject` | Detail carries |
|---|---|---|---|
| Same-pass recognition group | `&"room_celebrated"` | **the `pass_group_id`** | `celebrate=true`, all member room keys, all cells |
| Later-pass recognition inside cooldown | `&"room_recognized_quiet"` | region key | `celebrate=false`, `group_id` |
| Shelter change | `&"shelter_status"` | **item id** | `sheltered: bool` |

The rule this encodes, which the module contract was reaching for but never stated:
**`payoff_type` distinguishes KINDS — things with a different presentation
treatment and a separate lifetime. Per-occurrence facts go in the detail.**
`celebrate` passes the kind test (cue vs. no cue; the two must not refresh each
other). `sheltered` fails it (same channel, one live state per bed — encoding it as
two types would leave a toggling bed with two stale live keys and break the story's
own idempotency AC). `pass_group_id` is never a kind.

Choosing `subject = pass_group_id` for celebrations is deliberate and buys the
milestone's hardest assertion for free: the idempotency key *becomes* the
celebration event, so **"a same-pass group is ONE celebration"** is directly
provable via `get_active_payoff_count()` rather than inferred.

**Contract compliance.** The contract's *purpose* is that a consumer never has to
change its subscription when a new payoff kind appears. An optional trailing
parameter and an additive accessor preserve that exactly — a consumer that ignores
`detail` compiles and behaves verbatim. The signal, which is the actual contract
surface, does not move. This honors the letter and the spirit; a second signal
would violate both.

**Scope note:** I am ruling the *experience requirements* and the shape that meets
them. The **technical-director owns the final implementation form** and may
substitute an equivalent (`Resource` vs `RefCounted`, geometry handle vs inline
cells) provided all five conditions below remain assertable and constraints 1–4
hold. What is not negotiable is that celebrate, the group identity, and the
geometry all reach presentation **with** the event.

## The Minimum for the First Celebration a Player Ever Sees

Six conditions. The first five are machine-assertable; the sixth is the human one
and is the reason the other five exist.

1. **One group, one cue.** Every room recognized in the same analysis pass produces
   exactly one chime and one highlight sweep tracing *all* of them — never one chime
   per room.
   *QA:* emit N ∈ {2,3} same-pass recognitions → the celebration type's live-key
   count grows by exactly 1; `detail.subjects.size() == N`; the cue-trigger spy is
   invoked exactly once.

2. **It lands on the same beat as the last cell.** Recognition must feel *earned and
   immediate* (build-validation Game Feel). Synchronous, same frame, no queue.
   *QA:* assert the surface's frame counter at receipt equals the emission frame;
   grep-guard asserts no `CONNECT_DEFERRED` on the payoff path.

3. **The first celebration of a session is never suppressed.** The cooldown window
   may only be armed by a celebration that **actually fired a cue** — never by a
   load-pass emission, never by a quiet emission, never by transient seal/unseal
   churn during a natural build order (boxing four walls, then carving the doorway,
   is a real Sealed state and a real emission — build-validation says so explicitly).
   Without this, a player's first-ever room can arrive silent, and the beat is
   unrecoverable — there is no second first time.
   *QA:* given prior in-window pass activity but no prior *fired* celebration, the
   next `room_recognized` still arrives with `celebrate = true`.
   *(Note: at TPS 4.0 the window is 5 s, not the GDD's stale 10 s — see Ruling 1's
   residue list. Shorter makes accidental suppression less likely, but the rule
   still has to be explicit; do not let the shortened window paper over it.)*

4. **It reads as caused by the player's last action.** The highlight traces *the
   room the player just closed*. This is why the geometry must travel with the
   event rather than be re-queried afterward — a later pass can split or merge the
   region between emission and query, and the highlight would then trace something
   the player did not just do.
   *QA:* the detail's cells are non-empty and equal the recognized region's cells
   as of the emitting pass.

5. **Nothing competes with it.** No HUD, no toast (building-ui Rule 9d — the
   celebration is exclusively in-world). If a Building command-completion flourish
   fires in the same pass — which it usually will, since finishing the roof often
   completes both — the room cue **follows it by a breath rather than stacking**
   (one celebration, two layers).
   *QA:* grep-guard proves no HUD/toast consumer binds the celebration type; when
   both fire in one pass, the observed order is flourish-then-room, deterministically.

6. **A first-time player can tell what was just acknowledged.** If the tester cannot
   point at what the game congratulated them for, the beat failed regardless of
   how correct conditions 1–5 were. This is the actual acceptance criterion; the
   rest are its preconditions.
   *QA (playtest, story 011):* immediately after the first celebration, the tester
   is asked *"what just happened?"* and identifies the room without prompting.

## Pillar Alignment

- **Pillar 1 (the building IS the game)** — SERVED, decisively. This beat is the
  moment the game tells the player their drawing became a *thing with meaning*.
  It is the single most concentrated expression of Pillar 1 in the MVP.
- **Pillar 4 (clarity over complexity)** — SERVED, and it is why condition 4 is
  non-negotiable. A celebration whose subject is ambiguous is worse than none — it
  teaches the player that the game's feedback is noise.
- **Pillar 3 (cozy, but with stakes)** — SERVED via conditions 1 and 5. One chime
  for a group, and a cue that yields to the flourish rather than stacking on it, is
  the difference between "warm acknowledgement" and "slot machine."

## Aesthetic Impact (MDA)

**Sensation** and **Fantasy**. This is one of very few moments in the MVP where the
game speaks back in a purely sensory register. In Self-Determination terms it is
the **Competence** payout for the entire build verb — and competence rewards are
destroyed by three specific failures, which map exactly onto conditions 1, 3 and 4:
firing more than once for one accomplishment (cheapens), failing to fire at all
(erases), and firing ambiguously (confuses). Getting these right matters more than
the treatment's polish.

## Impact

- **technical-director** — owns the implementation form; must confirm constraints
  1–4 and that conditions 1–5 remain assertable under whatever form is chosen.
- **build-validation-navigability story-009** — unblocked once TD concurs; scope
  gains the `PayoffDetail` type and the ordering constraint, loses the back-query.
- **presentation-001 / art-director** — condition 5's "follows by a breath rather
  than stacking" is a presentation-owned stagger and is **not yet specified
  anywhere**. Flag it; the surface only guarantees observable ordering.
- **qa-lead** — conditions 1–5 convert directly into the story's QA cases; add
  condition 3's suppression case, which the story does not currently cover.
- **build-validation GDD** — the `room_cue_cooldown_ticks` "= 10s at 1x" annotation
  is stale (Ruling 1 residue list) and must be corrected in the same sweep.

## Alternatives Considered

1. **Option (a) — encode pacing into `payoff_type`, consumer re-queries for the
   group.** Rejected. Encoding `celebrate` as a type is correct and I have kept it.
   Encoding `pass_group_id` is not: it is a per-occurrence correlation id, so
   type-encoding it would mint an unbounded set of `payoff_type` values, one per
   pass, and the `type:subject` idempotency keys would never collide across passes —
   `_active_payoffs` grows without bound. That is a defect, not a taste objection.
   The re-query variant avoids that but inverts ADR-0001's injection direction
   (presentation would need a handle on the analysis module) and reads geometry
   *after* the pass that produced it, breaking condition 4.

2. **Option (b) — a second, additive signal**
   (`payoff_group_signaled(group_id, subjects, celebrate)`). Rejected. Explicitly
   forbidden by the module contract, and the prohibition is *right*: two signals
   means two subscription paths, an ordering question between them, and a consumer
   that can correctly handle one and silently miss the other. The contract exists
   to prevent exactly this.

3. **`Dictionary` payload instead of a typed record.** Rejected — the project
   enforces static typing in GDScript, and an untyped bag on a CD-protected path is
   precisely where a silently-missing `celebrate` key becomes a shipped bug.

4. **`subject = region key` for celebrations, group id in the detail only.**
   Rejected — it gives up the free proof of condition 1. With `subject = group_id`,
   "one group is one celebration" is a live-key count assertion instead of an
   inference over payload contents.

## Design Test — how we know this was right

- The integration test asserts all six of conditions 1–5's QA lines against the
  **real** emitters, with a mocked surface, headless.
- The grep-guard is green: no placeholder emitter, no `CONNECT_DEFERRED`, no HUD
  consumer on the celebration type.
- In the story-011 walkthrough, the tester identifies the celebrated room unprompted
  (condition 6) — and does **not** report the cue as "too much," which would signal
  condition 5's stagger is missing rather than the beat being wrong.
- Six months from now, adding a seventh payoff kind requires a new `payoff_type`
  value and zero changes to any existing consumer. If that stops being true, this
  shape was wrong.

---

## Open Items Handed Back

1. **User ratification of both rulings** — required before either is non-provisional.
2. **Technical-director concurrence on Ruling 2's implementation form** — the story
   names TD + CD jointly; this document is only the CD half.
3. **The repo-wide `at 1x` annotation sweep** (Ruling 1, Impact) — needs an owner
   and a home story. It is currently nobody's.
4. **The celebration stagger** ("follows by a breath rather than stacking") is
   unspecified in every document that mentions it. Presentation-layer owner needed.
