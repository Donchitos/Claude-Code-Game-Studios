# Dive Runtime & Event Log

> **Status**: Revised post-review 2026-07-04 — NEEDS REVISION blockers addressed in-doc; determinism, architecture-shape, storage, netcode, and replay-harness ADRs pending
> **Author**: user + agents
> **Last Updated**: 2026-07-04
> **Implements Pillar**: Pillar 1: Every Death Has an Author; Pillar 3: The Board Is Honest, the Water Is Not; Pillar 5: The Show Must Go On
> **Review**: `/design-review` 2026-07-04 (systems, game, qa, godot, network, performance specialists) — verdict NEEDS REVISION; blocking items resolved below. User-ratified decisions: numeric model = exact-hash, tolerance ruled out for canonical hashing (fixed-point vs pinned-float left to ADR); revive edge reserved; determinism scope = same-build/same-platform; combat-lethal at extraction → `incapacitated` (deep → `dead`).

## Overview

The Dive Runtime & Event Log is the foundation layer that defines a dive as a deterministic sequence of authored state changes, from start conditions through extraction, defeat, timeout, or abandonment. It owns the shared rules clock, lifecycle boundaries, participant state transitions, and structured event facts that later systems consume for combat resolution, oxygen pressure, loot banking, Heat, Public Ledger entries, Showrunner callbacks, persistence, and future netcode. The player does not interact with this system directly; it exists so every meaningful outcome can be traced, replayed, tested, summarized, and remembered without relying on presentation-only logs or one-off system memory.

## Player Fantasy

The player should feel that every dive leaves a true record. When a rival drowns behind a sealed bulkhead, oxygen runs out one room from extraction, a desperate relic play saves the run, or a betrayal becomes the episode's defining beat, the game remembers the real chain of events. The fantasy is not operating a log; it is surviving a hostile show where every loss, comeback, extraction, wound, and mistake can be traced back to authored causes. The deep is cruel, but it does not cheat, and the Showrunner can only name what actually happened.

## Detailed Design

### Core Rules

1. **One authoritative session per dive.** Each dive runs as a single authoritative
   rules session created from an immutable `DiveConfig` and advanced only by
   fixed-step simulation ticks. Render frames, animation callbacks, UI signals,
   camera, and audio are presentation: they may never create, modify, or reorder
   gameplay facts.

2. **`DiveConfig` is the dive's immutable birth certificate.** Recorded at session
   creation: log schema version, content version hash, seed, match type, wreck id,
   participant roster with loadouts and start positions, extraction rules,
   end-condition policy, and enabled systems. Everything needed to re-simulate the
   dive is the config plus the command stream — nothing else.

3. **Three internal contracts — never one god object.** The system is specified as
   three separable contracts: the **Simulation Authority** (owns authoritative
   state; validates and applies all changes), the **Event Emitter** (the only
   component that stamps and commits events), and the **Append-Only Event Log**
   (stores committed facts). Downstream systems bind to these contracts and may not
   reach around them.

4. **Commands in, facts out.** Every state-changing intent enters as a tick-indexed
   command — player input, rival AI, creature AI, environment triggers, and any
   future director or network client all use the same command path. No system
   mutates authoritative state directly from input or presentation.

5. **Fixed tick phase order.** Every tick resolves in fixed phases: command intake →
   validation → intent staging → world/wet-substrate update → actor and action
   resolution → combat/oxygen/extraction/loot resolution → participant state
   transitions → terminal check → event commit. Within a phase, ordering is
   deterministic: system order, then participant/actor id, then command sequence.

6. **Canonical ordering is positional, not temporal.** Event order is
   `(dive_id, tick, phase_slot, sequence)`. Wall-clock timestamps exist for display
   and debugging only and are never an ordering source. Tick rate is a tuning knob
   (working assumption 60 Hz), finalized in Technical Setup.

7. **No untracked randomness.** Combat resolution uses zero RNG (locked pivot
   decision). Any permitted variation — wreck layout, loot placement, ambience —
   must derive from the recorded `DiveConfig` seed so re-simulation is exact. The
   deal is random; the play is deterministic.

8. **Every command is validated; rejections are facts.** The authority validates
   each command against dive lifecycle, participant state, and command sequence.
   Rejected commands are committed as raw `command_rejected` events with a reason
   code — silent drops are forbidden.

9. **The log is append-only and raw.** No mutation, no deletion; corrections are new
   correction events. The log records committed facts only (`damage_applied`,
   `oxygen_threshold_crossed`, `loot_banked`, `participant_downed`) — never
   interpretation. No Feed points, barks, Heat, Marks, or recap labels in the raw
   log.

10. **Standard event envelope.** Every event carries: `schema_version`, `dive_id`,
    `tick`, `phase_slot`, `sequence`, `event_type`, emitting system, `subject_id`, and
    where applicable `target_id`, `instigator_id`, `source_command_id`, a `cause_event`
    reference, `contributing_events`, an optional `superseded_by` reference (stamped on
    an event that a later correction replaces; the correction carries `corrects`
    pointing back — this is how any consumer, including recap under AC5, resolves a
    correction from the log alone), and a location reference (stable room/zone id
    and/or quantized position), plus an event-type-specific payload of raw
    primitive values. No engine object references, node paths, or opaque blobs.
    `phase_slot` is stamped with the **generating** phase (the phase that resolved the
    fact), not the commit phase, so the `(tick, phase_slot, sequence)` ordering key
    (F2) groups facts by where they were resolved. The envelope is
    **forward-extensible**: later systems may add scoped fact fields (e.g. a
    relationship/alliance scope, so a betrayal beat is reconstructable) under a bumped
    `schema_version` without breaking existing consumers.

11. **Full cause chain from day one.** Every meaningful outcome — down, death,
    wounded evacuation, extraction, loot loss — must carry its authorship chain:
    source command, instigator, direct cause event, contributing events. An
    indirect kill (sealing a bulkhead so the water does the work, luring the eel
    into a rival) attributes to its true author. This is the mechanical foundation
    of Pillar 1: Every Death Has an Author. `contributing_events` references **direct**
    contributors only (transitive chain-walking is left to consumers), bounding
    per-event payload size. Cause graphs may be near-cyclic (mutual same-tick kills
    reference each other), so any consumer that walks the chain must terminate on a
    visited-id set, never assume acyclicity.

12. **Debug-replay guarantee.** Re-simulating `DiveConfig` + the recorded command
    stream must reproduce the final state hash and the event-log hash. The command
    stream is recorded separately from the event log: commands are the replay input
    record; the log is the semantic receipt. Each command carries a per-participant
    monotonic `command_seq` (the basis for the `bad_sequence` rejection); the
    Simulation Authority stamps every **admitted** command with a canonical
    `(tick, source_slot, command_seq)` order at admission, and **replay replays that
    recorded admitted order verbatim** — it never re-derives real submission order, so
    `H_cmd` is reproducible even when several sources submit within one tick. No
    player-facing replay is promised by this system.

13. **Terminal resolution is orderly.** When an end condition is met, the runtime
    finishes the current tick, rejects all further commands, commits terminal events
    with full cause chains, writes a final state snapshot with state/command/log
    hashes, and seals the log.

14. **Sealed-log handoff.** Long-term state (profile, ledger, bloodline, stash) may
    only mutate from a *sealed* dive log, and import is idempotent — applying the
    same sealed log twice must not double-apply rewards, scars, or ledger entries.
    `dive_id` is a collision-free unique id (UUID or monotonic counter, **not**
    seed-derived — a replay-test run reuses the seed and must never alias a real
    dive's identity); idempotency is keyed on `dive_id + H_log`.

15. **One omniscient log, visibility-scoped projections.** The canonical log sees
    everything. HUD, VFX, audio, recap, and any future networked client receive only
    visibility-appropriate projections, preserving the fairness rule: no unearnable
    information.

### States and Transitions

**Dive lifecycle:**
`configured → loading → readying → active → terminal_pending → finalizing → completed`

| State | Meaning | Exit trigger |
|---|---|---|
| `configured` | `DiveConfig` validated and frozen | load begins |
| `loading` | Wreck, participants, systems instantiating | all systems report ready |
| `readying` | Pre-dive broadcast beat; loadouts already locked pre-reveal | start tick scheduled |
| `active` | Ticks advancing, commands accepted | end condition met |
| `terminal_pending` | End detected; current tick finishes; new commands rejected | terminal events committed |
| `finalizing` | Snapshot + hashes written; log sealing | log sealed |
| `completed` | Sealed log handed to persistence | — |

Exception path: `technical_aborted` (from `loading`/`readying`/`active`) covers
non-canonical failures only — crash, corrupt config. It produces no canonical
outcomes. **Player quit is never a technical abort**: it resolves as the participant
state `abandoned`, so the show remembers it.

**Participant lifecycle:** `registered → spawning → active`, then:

- `active ⇄ extracting` — extraction is interruptible
- `active`/`extracting` → `incapacitated` — defeat, the dredged-out lane
- `incapacitated → active` — **design-reserved revive edge** (self-rescue or ally
  revive per "the handshake"): the transition exists in the machine but its trigger
  rules are owned by the Combat GDD. Reserved now so this foundation machine need not
  be re-opened later; **FPP need not implement it.**
- `incapacitated` → `evacuated_wounded` — **death dial**: terminal, loses carried loot, gains a scar
- `active`/`extracting`/`incapacitated` → `dead` — the deep kills: drowning, creature, collapse, opt-in blood stakes
- `active`/`extracting`/`incapacitated` → `abandoned` — quit/disconnect; terminal and canonical

Terminal states: `extracted`, `evacuated_wounded`, `dead`, `abandoned`. Terminal
participants accept no commands but remain valid subjects, instigators, and cause
references for the rest of the dive (e.g. a mine set before a diver's death still
detonates and attributes to them).

Under future netcode, `abandoned` may be preceded by a transient, non-terminal
`disconnected` state with a grace/reconnect window before promotion (a dropped packet
must not instantly strip loot and write an obituary) — the state is reserved here, its
timeout deferred to the netcode ADR. In FPP a local quit resolves straight to
`abandoned`.

**First Playable Proof scope:** FPP implements the full participant machine
*including* `incapacitated`/`evacuated_wounded`. FPP end policy: the dive enters
`terminal_pending` when the **player** reaches a terminal state; a rival's terminal
state does not end the dive. The general end-condition mechanism stays in
`DiveConfig` for match types later.

**Actors** (creatures, hazards, projectiles, relic instances): their behavior states
are owned by their domain systems. The runtime records only their authoritative
facts — spawned, state-changed, destroyed/expired — and keeps their ids stable so
cause chains can reference them.

**Log states:** `open → sealing → sealed → imported`. Only the Event Emitter appends
while open; sealing is one-way; import is idempotent.

### Interactions with Other Systems

| System | Contract | Status |
|---|---|---|
| Controls & Casting | Produces tick-indexed commands (move, aim, flick-cast, sigil inputs, item keys, context actions); never mutates state | provisional — GDD pending |
| Rival AI / Creature AI | Submit intents through the same command path; decisions deterministic from seed + observable state | provisional — GDD pending |
| Wreck & Fog | Provides stable room/zone ids used in event locations; owns the visibility rules projections must respect | provisional — GDD pending |
| Oxygen & Extraction | Requests threshold, extraction start/interrupt/complete, and drowning facts; runtime validates and applies transitions | provisional — GDD pending |
| Relics / Wet Substrate / Combat | Own domain math; emit raw candidates (`cast_committed`, `substrate_changed`, `hit_landed`, `damage_applied`, `participant_downed`); only the Emitter stamps them | provisional — GDD pending |
| Loot & Banking | Owns inventory state; runtime records pickup/drop/bank/terminal-loss facts | provisional — GDD pending |
| HUD / VFX / Audio | Read-only consumers of committed events + snapshots; never create facts | binding |
| Feed, Heat, Marks & Public Ledger | Derive all interpretation post-commit; can never append to or rewrite the runtime log | binding |
| Showrunner (Tiers 1–3) | Consumes committed facts; any future director action enters as commands through the queue. No live outcome intervention in FPP; the Showrunner can never alter in-water outcomes | binding |
| Save / Profile / Bloodline / Memorial | Receive the sealed dive record (snapshot + hashes); scars, obituaries, heirlooms derive from terminal facts; import idempotent | binding |
| Dive Board & Match Types | Supplies `DiveConfig` including end-condition policy | provisional — GDD pending |
| Future Netcode | Clients submit commands; server authority validates and emits canonical events; client prediction never becomes fact | binding constraint |
| Tier 3 LLM | Between dives only; consumes finalized facts via ledger/recap data | binding |

Provisional contracts must be reconciled when those GDDs are authored; each is
mirrored in the Dependencies section for bidirectional traceability.

**Netcode foundation constraints** (decided now so the solo-first build does not
force a rewrite later; mechanisms deferred to the netcode ADR):

- **Topology is single-authority** (dedicated server or host-as-server), *not*
  symmetric peer-to-peer lockstep — already fixed by "server authority validates and
  emits canonical events." The netcode ADR decides protocol, network tick rate, and
  reconciliation; it does **not** re-open topology.
- **Speculative Replica** (a fourth concept, distinct from the three authoritative
  contracts): client prediction runs a client-local, non-authoritative instance of
  the same deterministic step function. Its output is **never** appended to the
  canonical append-only log and is wholly discarded/replaced on reconciliation. Named
  now so prediction never has to append-then-unwind the append-only log later.
- **Command admission is local-transport-only as specified.** Core Rule 5's "commands
  for tick N are present at tick N" and the `bad_sequence` rejection assume
  zero-latency local delivery. Networked admission (buffered input delay or rollback)
  is a separate later policy — network lateness must **not** flood the canonical log
  with `command_rejected` facts.
- **Projections are a pre-transmission cull.** Visibility-scoped projection logic
  (Core Rule 15) must be implementable as a server-side cull *before* data crosses to
  an untrusted client, not only as a client-side display filter — the projection may
  not assume safe access to the full omniscient log on a client machine (anti-wallhack;
  Pillar 3 fairness).

## Formulas

This is an infrastructure system, so these are deterministic definitions — not
balance math. They back the debug-replay guarantee (Core Rule 12), the canonical
ordering key (Core Rule 6), and the sealed-log hashes (Core Rules 13–14).

### F1 — Tick / time conversion

```
t_seconds = tick / TICK_RATE
FIXED_DT  = 1 / TICK_RATE
```

| Variable | Definition | Range | Notes |
|---|---|---|---|
| `TICK_RATE` | Authoritative sim ticks per second | 30–120 Hz; **working default 60** | Tuning knob; finalized in Technical Setup, then frozen per replay-compatible build |
| `tick` | Integer tick index since dive start | 0 … ~2^31 | Truth for time; monotonic |
| `t_seconds` | Display/debug wall-position of a tick | ≥ 0.0 | Never used for ordering or logic |

*Example:* at 60 Hz, `tick = 900` → `t_seconds = 15.0`; `FIXED_DT ≈ 0.01667`.

> **Implementation guards:** `t_seconds` must use **float** division — in GDScript
> `int / int` truncates (`901/60 → 15`, not `15.0167`), and the example above happens
> to divide evenly, hiding the bug. `TICK_RATE` and `CELL_SIZE` must be validated on
> `DiveConfig` load (`TICK_RATE ∈ [30,120]`, `CELL_SIZE > 0`) — both are unguarded
> division inputs that degenerate to ∞/NaN at 0. `tick` is scoped to `dive_id` and
> resets to 0 at the start of each dive (so the `~2^31` ceiling is per-dive).

### F2 — Canonical event ordering key

```
order_key(e) = (e.tick, e.phase_slot, e.sequence)
e1 precedes e2  ⇔  order_key(e1) < order_key(e2)   (lexicographic)
```

| Variable | Definition | Range |
|---|---|---|
| `phase_slot` | Integer index of the **generating** phase (that resolved the fact) in the fixed phase list (Core Rule 5); the commit phase is not a generating slot | 0 … 7 |
| `sequence` | Per-dive monotonic counter; assigned at commit as `next_sequence`, then `next_sequence += 1` | 0 … N_events−1 |

Because events commit in tick-then-phase order, `sequence` alone is already a total
order; the full tuple is stored so the log is groupable/queryable by tick and phase
without a sort. Guarantee: `sequence` is strictly increasing and non-decreasing in
`(tick, phase_slot)`.

*Example:* two hits resolve in the same tick 900, combat phase (slot 5): they commit
as `seq 4120` then `seq 4121`. `(900,5,4120) < (900,5,4121)` → first hit is
canonically first, deterministically, every replay.

### F3 — Location quantization

```
cell = ( floor(pos.x / CELL_SIZE), floor(pos.y / CELL_SIZE) )
```

| Variable | Definition | Range |
|---|---|---|
| `CELL_SIZE` | World units per log-quantization cell | tuning knob; default TBD with wreck scale |
| `room_id` | Stable id from Wreck & Fog (preferred location ref) | — |

Events prefer `room_id`; `cell` is the fallback when sub-room position matters (e.g.
a trap tile). Raw float positions are never stored in the log.

### F4 — Verification hashes

```
H_state(t) = hash( canon(authoritative_state @ tick t) )
H_cmd      = hash( concat over submission order:  canon(command_i) )
H_log      = hash( concat over canonical order:   canon(event_j) )
```

| Term | Definition |
|---|---|
| `canon(x)` | Deterministic serialization: sorted keys, fixed numeric encoding, stable id refs — **no** node paths, object refs, or float ambiguity |
| `hash` | A fixed digest function, pinned per build |
| `content_version_hash` | Digest of content/config affecting simulation; stored in `DiveConfig`; replay is only valid across matching values |

### F5 — Debug-replay equivalence (the guarantee behind Core Rule 12)

```
replay(DiveConfig, command_stream) ⟹
    H_state_final == recorded H_state_final
 ∧  H_log        == recorded H_log
```

Two runs with identical `DiveConfig` (same seed, same `content_version_hash`) on the
**same build and platform** must satisfy `H_state_A(t) == H_state_B(t)` for all `t`,
and `H_log_A == H_log_B`. (Cross-platform bit-exactness is out of scope until the
netcode ADR, where it becomes load-bearing.) The **runtime** emits periodic
`H_state(t)` checksums (`state_checksum_interval`) as a cheap early-warning that
localizes a divergence to within one interval; the **CI/replay harness** runs a
distinct exhaustive mode — per-tick `H_state` comparison — to report the *exact* first
diverging tick. The "first diverging tick" guarantee is the harness's, not the periodic
runtime knob's.

> **Note:** the replay guarantee rests on the **computation** model, not just
> serialization — authoritative values must be bit-reproducible *before* they are
> hashed. The ADR scope is therefore **"what math the Simulation Authority may use"**
> (fixed-point vs a pinned deterministic-float regime; engine `Vector2` /
> transcendental (`sin`/`cos`/`sqrt`) / any physics-driven state are candidates for
> **exclusion** from the authoritative path — presentation may use engine float math,
> the authority may not), not merely how `canon()` encodes floats.
> **Tolerance-based comparison is ruled out for canonical hashing** (user-ratified):
> `H_state`/`H_log` require exact equality, so `canon()` must produce an
> exact-reproducible encoding. An epsilon/tolerance check is permitted *only* for the
> periodic early-warning divergence checksum, never for the sealed hashes. The `hash`
> is a build-pinned digest via a stable API (e.g. SHA-256 through `HashingContext`),
> **not** the engine's internal `hash()`. Fixed-point-vs-pinned-float and the exact
> digest remain ADR candidates, parked in Open Questions.

## Edge Cases

- **Mutual same-tick kill.** Both participants resolve in the participant-transition
  phase, ordered by participant id; each terminal outcome gets a full cause chain
  referencing the other. Dive-end is evaluated only after both are committed.
- **Same-tick lethal denial vs. extraction completion.** Per the fixed phase order
  (Core Rule 5), combat/oxygen resolve **before** extraction, so a same-tick lethal
  outcome **prevents** the extraction — denied one frame from daylight. The terminal
  state is split by lethal **source**, per the Death Dial: an oxygen/drowning (the
  deep) cause routes the participant to `dead`; a **combat/rival** cause routes to
  `incapacitated` (extraction interrupted, then resolved by the death dial to
  `evacuated_wounded` — alive, loses carried loot, gains a scar). Only the deep kills
  outright. The drama still lands for oxygen deaths, while duel losses stay off the
  `dead` path (Pillar 1 + Death Dial fidelity). A legible extraction-channel
  vulnerability tell is required of Oxygen/Extraction + HUD so this reads as fair, not
  as the game cheating (cross-dependency).
- **Command for an already-terminal participant** → rejected as a
  `command_rejected` event, reason `participant_terminal`.
- **Stale/duplicate command sequence** → rejected, reason `bad_sequence`.
- **Crash before seal** → dive is `technical_aborted`; the log is never sealed and
  persistence never mutates. Idempotency protects against a partial import.
- **Player quit/disconnect** → resolves as `abandoned` (canonical, remembered); the
  dive proceeds to terminal per end policy. Never `technical_aborted`.
- **Malformed event** (missing required envelope field) → hard-fails in debug
  builds; a malformed event never silently commits.
- **Double handoff** (import runs twice) → idempotent no-op, keyed by `dive_id` +
  `H_log`.
- **Contested same-tick loot pickup** → resolved in the loot phase by participant
  id; one participant gets the pickup fact, the other a contested/rejected fact.
- **Cause reference to a corrected event** → the chain resolves to the latest
  authoritative fact; corrections are never deleted.
- **Replay divergence** (`H_state` mismatch) → the harness's exhaustive per-tick mode
  reports the exact first diverging tick (the periodic runtime checksum only narrows it
  to an interval); a CI/debug failure, not a runtime concern.
- **Empty salvage run** (zero rival) → valid; roster of one; player-terminal ends it.

## Dependencies

**Upstream (feeds the runtime):** Dive Board & Match Types — supplies `DiveConfig`
plus end-condition policy.

**Downstream (consume runtime facts/state):** Combat; Oxygen & Extraction; Loot &
Banking; Wreck & Fog; Relics; Wet Substrate; Rival AI; Creature AI; HUD/VFX/Audio;
Feed, Heat, Marks & Public Ledger; Showrunner (Tiers 1–3); Save/Profile/Bloodline/
Memorial; Recap/Obituary; future Netcode; Tier 3 LLM.

*Bidirectional obligation:* each listed GDD, when authored, must add Dive Runtime &
Event Log to its own Dependencies. Until then these are tracked as provisional
contracts in Detailed Design → Interactions with Other Systems.

## Tuning Knobs

| Knob | Affects | Safe range | Default |
|---|---|---|---|
| `TICK_RATE` | Sim resolution, replay compat, CPU cost | 30–120 Hz | 60 (frozen per build) |
| `CELL_SIZE` | Log location granularity | TBD w/ wreck scale | TBD |
| `state_checksum_interval` | How early replay divergence is caught vs. overhead | every 1–600 ticks | 30–60 ticks (≈0.5–1s @60Hz); per-tick reserved for CI/harness only |
| `snapshot_frequency` | Final/periodic snapshot cost | dive-end only … periodic | dive-end only (FPP) |
| `log_rejected_commands` | Log size vs. debuggability | debug-only / always | always (FPP) — cap under netcode (rejected-command amplification) |
| `event_granularity` | Which state changes count as "meaningful" facts | — | movement not logged per-tick; terminal-event payloads snapshot exact vitals (O2/HP) regardless |
| `command_granularity` | Command-stream size vs. fidelity | per-tick / intent-delta | continuous move/aim coalesced to intent-change deltas, not one record/tick |
| `log_retention` | Disk cost vs. debuggability across a career | per-dive … capped/rolling | TBD (storage ADR) |

## Visual/Audio Requirements

None player-facing — this is a headless authority system. Dev-facing only: an
optional event-log timeline/inspector overlay for debugging (dev tool, not shipped
UI). No art, VFX, or audio assets required.

## UI Requirements

None player-facing. The only surface is a developer log/replay inspector
(tools-programmer scope, not this GDD). Recap and HUD are separate systems that
*consume* this one.

## Acceptance Criteria

1. **Determinism (same build, same platform):** identical `DiveConfig` + command
   stream across two headless runs on the same build and platform → identical
   `H_state_final` and `H_log`. Cross-platform bit-exactness is deferred to the netcode
   ADR. *(Prototype v3's smoke test proves the direction, but is not the H_state/H_log
   hash harness this AC requires — that harness is its own prerequisite spike, blocked
   on the numeric-determinism ADR.)*
2. **Authored outcomes:** every terminal participant outcome carries a non-empty
   cause chain resolving to a source command or environmental cause event.
3. **Indirect authorship:** a seal-bulkhead → drowning kill attributes the
   instigator to the sealing participant, verifiable from the log alone.
4. **Append-only (bounded checks):** (a) the Event Log's public interface exposes no
   delete/update/overwrite method (API-surface introspection); (b) committing an event
   that reuses an existing `(tick, phase_slot, sequence)` is hard-rejected before
   commit; (c) a correction appends a new event carrying `corrects` → the original
   (and stamps the original's `superseded_by`), leaving entries `0…N-1` byte-identical
   to their pre-correction serialization and `log.size() == N+1`.
5. **Recap dogfood rule** *(forward contract — verified in the Recap/Obituary GDD's
   Definition of Done, not a blocker for closing this story):* recap/obituary
   generation consumes **only** the sealed event log via its query API; any recap beat
   (including betrayal and indirect/environmental kills) not producible from the log is
   a blocking schema defect filed against this envelope.
6. **Idempotent handoff** *(forward contract — verified in the Save/Profile GDD's
   Definition of Done):* importing the same sealed log twice yields ledger/scar/stash
   state value-for-value identical to importing once (snapshot diff, not mere
   non-crash); the second import is a no-op keyed by `dive_id + H_log`.
7. **Envelope validity:** every committed event passes the envelope schema (required
   fields present, primitive-typed, stable ids).
8. **No silent drops (per reason code):** for each defined rejection reason
   (`participant_terminal`, `bad_sequence`, and any added later) a command that should
   trigger it produces exactly one `command_rejected` event carrying that code.
9. **FPP end policy:** the player reaching a terminal state moves the dive to
   `terminal_pending` that same tick (readable after the tick's terminal-check phase,
   before the next tick begins); a rival terminal state does not.
10. **Presentation can't author:** (a) *static* — HUD/VFX/audio modules hold only
    read-only references to the Log/Emitter (no write method reachable from
    presentation code); (b) *dynamic (same build/platform)* — headless and
    with-presentation runs of the same dive produce byte-identical logs.
11. **Transition legality:** only documented dive- and participant-lifecycle edges are
    reachable; illegal transitions (commands accepted outside `active`; `active` →
    `dead` from a non-deep cause) are rejected, not silently applied.
12. **Quit ≠ abort:** a player quit resolves to participant `abandoned` (canonical,
    remembered); a crash/corrupt-config resolves to `technical_aborted` (no canonical
    outcomes, log never sealed). The two are never inverted.
13. **Same-tick precedence:** on a tick with both a lethal combat/oxygen outcome and an
    extraction completion, the extraction is denied and the terminal state matches the
    lethal source (oxygen → `dead`; combat → `incapacitated`).
14. **Mutual same-tick kill:** both participants reach terminal, ordered by participant
    id, each with a full cause chain referencing the other; dive-end is evaluated only
    after both commit.
15. **Ordering invariant:** for any produced log, `sequence` is strictly increasing and
    non-decreasing in `(tick, phase_slot)` (F2) — an always-on invariant check.
16. **Malformed event hard-fails:** an event missing a required envelope field never
    commits (hard-fail in debug builds).
17. **Perceived fairness (ADVISORY):** in an edge-case/recap playtest, players do not
    describe a same-tick extraction-denial outcome as a bug or a cheat — a legible tell
    surfaced the vulnerability window. (Visual/Feel evidence: screenshot + lead
    sign-off.)

## Open Questions

- **ADR (blocking replay):** the Simulation Authority's numeric model — fixed-point vs
  a pinned deterministic-float regime, **plus which math primitives the authoritative
  path may use** (engine `Vector2` / transcendentals / physics-driven state are
  exclusion candidates). Tolerance-based comparison is already ruled out for canonical
  hashing (see F5 note). Pinned `hash` = build-fixed digest via a stable API (e.g.
  SHA-256 through `HashingContext`), never the engine's internal `hash()`.
- **Blocker (needs technical-director):** no performance budgets exist yet
  (`technical-preferences.md` framerate / frame-budget / memory are all "TO BE
  CONFIGURED"). This system's per-tick CPU sub-budget, resident memory ceiling, and
  per-dive event/command count envelope must be set before the cost side of the
  Acceptance Criteria is testable; the `state_checksum_interval` and command-stream
  budgets derive from that split.
- **Design:** whether the event log + command stream are held fully in memory for the
  dive or streamed to disk incrementally (an unaddressed memory-growth decision).
- **ADR (engine, Godot 4.6) — route resolutions to the control manifest as forbidden
  patterns:** confirm `real_t` build precision, `RandomNumberGenerator` (PCG32)
  seed-stability across 4.3→4.6, and `var_to_bytes` byte-stability before any backs the
  replay guarantee; drive the tick loop from a manual accumulator, **not**
  `_physics_process` (which drops ticks past `max_physics_steps_per_frame`) for headless
  CI; implement the three contracts as `RefCounted`, **not** `Node`/autoload (autoload
  conflicts with a future multi-dive server); forbid `CONNECT_DEFERRED`, wall-clock APIs
  (`Time.get_ticks_msec`), and global `randi()`/`randf()` in the authoritative path;
  require an explicit `Dictionary` key-sort in `canon()`; never round-trip the sealed log
  through `.tres`/Variant serialization (not byte-stable across engine upgrades). Add an
  `engine_build_id` alongside `content_version_hash` if any float math survives the ADR.
- **ADR:** runtime architecture shape (autoload vs scene-local; typed Resources vs
  dictionaries; signal bus vs direct callbacks).
- **ADR:** event-log storage/serialization format (JSONL vs binary vs Resource;
  compression; retention).
- **ADR:** netcode authority model (host/server, RPC modes, prediction/
  reconciliation, snapshot/rollback, network tick rate).
- **ADR:** replay test harness design.
- **Design:** `CELL_SIZE` default (depends on wreck scale).
- **Design:** full same-tick precedence matrix beyond combat-before-extraction,
  resolved as downstream systems are authored.
- **Design:** event-granularity policy — which state changes are "meaningful" enough
  to log.
