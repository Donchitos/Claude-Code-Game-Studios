# Epic: Needs & Mood System

> **Layer**: Feature
> **GDD**: design/gdd/needs-mood-system.md
> **Architecture Module**: Needs & Mood System (per-villager need floats; mood EMA; recovery source→rate table — the Building→Needs seam; why-string selection/templates/precedence; F1–F4 formulas)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 12 stories created (see Stories table below)

## Overview

Needs & Mood owns the values that make a villager feel alive: which needs exist
(MVP: `sleep`), how fast they decay per game tick, when they become Urgent, how
recovery is scored, and how satisfaction rolls up into a single visible **mood**.
It owns the **source→rate table** — the three-rung recovery ladder
(`bed_sheltered` ×1.0 > `bed_unsheltered` ×0.7 > ground ×0.4) that is the
mechanical meaning of "the building IS the game": a bed inside a valid room
recovers at full rate, the same bed without a roof visibly costs, the ground is
survivable but worse. It owns the ladder-ordering **BLOCKING** config invariant,
the queryable per-need state machine (state is truth, edge events are latency
hints), the mood EMA + snap rule, and the why-string the Villager Info UI shows
verbatim. It owns **no behavior**: Villager AI decides, travels, sleeps and
reports; this system scores. It is the scoreboard half of the MVP hypothesis and
the system Milestone 02's criterion #5 — the payoff loop — is built out of.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Tuning/Config Data Strategy | One `Resource`-derived config class, typed `@export` per Tuning Knob, `.tres` text; `validate() -> Array[String]` called once in `setup()`; two-tier policy — single-field range → clamp+warn, **GDD-declared BLOCKING cross-value invariant** (the ladder ordering) → `ConfigResource.format_blocking()` + terminal boot-halt | MEDIUM |
| ADR-0001: Inter-System Reference & DI Pattern | Injected-tier module (typed `@export`s wired in `GameWorld.tscn`); all wiring/validation in an explicitly-callable `setup()`; headless-mockable via `Node.new()` + assigned mocks, zero scene tree, zero Autoload registration | MEDIUM |
| ADR-0005: Boot Sequencing & Initialization Gate | `setup()` is called only from `GameWorld`'s Booting path behind the RID `Ready`/`Failed` gate; a BLOCKING config issue reuses the existing terminal boot-halt path, never a new one | MEDIUM |
| ADR-0008: Villager AI Execution & Threading | The consumer contract: Villager AI is a tick-driven plain FSM that **polls** need state at its decision points and treats urgent/satisfied events as latency hints; zero `Thread`/`WorkerThreadPool` touches Needs state | MEDIUM |
| ADR-0012 | `serialize()/deserialize()` under the `needs_mood` top-level key; mood restored **as-saved**, never re-initialized via F4 — **VS-tier** | MEDIUM |

Engine-risk basis (4.7 policy): **LOW** at the module level —
`docs/architecture/architecture.md` records Needs & Mood as "None
engine-specific — pure GDScript logic (LOW risk)". The MEDIUM entries above are
the shared Foundation patterns (config/DI/boot-gate), not needs-specific engine
surface. The one engine fact that matters: **default signal connections are
synchronous**, which is what makes the intra-tick ordering rule (reports land
before the F-pass) implementable without a queue.

## GDD Requirements

44 TRs registered (`TR-needs-mood-system-*`: 020, 025–029, 030–067). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-needs-mood-system-020 | Ladder-ordering invariant validated at config load, blocking | ADR-0002 ✅ (BLOCKING tier) |
| TR-needs-mood-system-041 / -031 | Data-driven values; fixed need schema | ADR-0002 / ADR-0006 pattern ✅ |
| TR-needs-mood-system-025 | Live-pair integration (real Needs + real villager, no mocks at the seam) | ADR-0001 ✅ (headless-mockable DI is what makes the *un*mocked pair constructible) |
| TR-needs-mood-system-051 / -057 / -062 / -063 | Tick-driven math; burst ordering; pause; warp invariance | ADR-0008 (tick consumption) ✅ |
| TR-needs-mood-system-026 … -029 | Need values + smoothed mood serialized; mood restored as-saved; schema drift dropped with a log line; state re-derived without signal replay | ADR-0012 ✅ (VS) |
| TR-needs-mood-system-030/-032/-033/-034/-035/-036/-037/-038/-039/-040/-042 … -050, -052 … -056, -058 … -061, -064 … -067 | F1–F4, state machine, source→rate table, why-string, edge cases | GDD-specified (no ADR-worthy decision) |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; the remainder
are GDD-specified formulas, state-table rows, and edge cases. No untraced
requirements.

**At-risk / deferred**: AC24/AC25 (Save/Load) are **explicitly deferred** by
Milestone 02's Out of Scope section pending the Save/Load & World Persistence
GDD — story 012 exists so the TRs are not orphaned, and is **not M02 content**.
AC35 (Game Feel) is Advisory/playtest-gated (story 011), not a blocking gate.

## Milestone 02 Notes — Cluster A, PROTECTED

- This epic is **Cluster A** in `production/milestones/milestone-02-mvp-completion.md`
  and inherits **PROTECT**. Cutting any part requires escalation; it is never on
  the cut lever.
- Delivers milestone criterion **#3** (every Logic AC except AC24/AC25 has a
  passing blocking test), criterion **#4** (the real-time-rate pass — story 009,
  resolved *inside* this cluster, not after it), and is one of the two halves of
  criterion **#5** (the live-pair payoff loop — story 010).
- **HOME OF THE `ticks_per_second` 2.0 → 4.0 INHERITANCE (R6).** The rate change
  landed in `time-tick-system` and doubled the real-time meaning of every
  downstream per-tick rate. Needs & Mood is *entirely* per-tick rates. Story 009
  owns the pass: it is a Config/Data story with a **decision input**, not a
  mechanical edit — see its Open Decision block.
- **External dependencies this epic does not own** (schedule them alongside, or
  story 010 cannot run):
  - `villager-ai-018` (sleep & home / bed claim — "claiming a bed IS the move-in
    moment") and the furniture chain `building-028 → 016 → 017`.
  - `build-validation-navigability` (its Rule 5 supplies the sheltered /
    unsheltered classification that selects the ladder's top two rungs).
  - Both are mocked at the boundary for stories 001–009; story 010 is the one
    story that requires them real.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Every Logic AC in `design/gdd/needs-mood-system.md` except AC24/AC25 has a
  passing blocking test under `neues-spiel/tests/unit/needs_mood/`
- The ladder invariant `ground_penalty < unsheltered_bed_multiplier < 1.0` halts
  boot loudly when violated (AC29) — proven, not asserted in prose
- F2 recovery resolves through a **table lookup**, with a test proving a
  brand-new source id works with no code change (AC10 — no hardcoded
  two-source branch)
- The real-time-rate pass (story 009) is recorded as a quick-spec, the GDD knob
  table carries real-time equivalents at `ticks_per_second = 4.0`, and the
  `time-tick-system` Open Question is closed
- The live-pair round trip (AC34) is green with **no mocks at the seam**
- A grep/contract check proves mood has zero consuming references in
  work/scheduling code (Rule 8, advisory)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Config resource, DI scaffold, need schema & BLOCKING ladder invariant | Integration | Ready | ADR-0002/0001/0005 |
| 002 | F1 decay, per-need state machine & edge-triggered urgent signal | Logic | Ready | ADR-0008 |
| 003 | Recovery-report API, source→rate table & F2 recovery | Logic | Ready | ADR-0002/0008 |
| 004 | Recovery interruption, mid-recovery re-rating & bed revocation | Logic | Ready | ADR-0008 |
| 005 | F3 mood smoothing, snap rule, `mean_active` & band events | Logic | Ready | ADR-0002 |
| 006 | F4 spawn initialization & new-need activation | Logic | Ready | ADR-0002 |
| 007 | Why-string selection, templates & UI-slot precedence | Logic | Ready | ADR-0001 |
| 008 | Burst ordering, pause & warp determinism (full-cycle tick anchors) | Logic | Ready | ADR-0008 |
| 009 | Real-time-rate pass at `ticks_per_second = 4.0` (criterion #4) | Config/Data | Ready | ADR-0002 |
| 010 | Live-pair shelter recovery round trip (AC34, criterion #5) | Integration | Ready | ADR-0001/0008 |
| 011 | Game Feel playtest probe (AC35, Advisory) | Visual/Feel | Ready | ADR: N/A — playtest evidence, no architectural pattern |
| 012 | Needs & Mood save/load serialization (VS-tier) | Integration | Ready | ADR-0012 |

**Type totals**: 7 Logic, 3 Integration, 1 Config/Data, 1 Visual/Feel.

**Sizing note**: estimates are **relative-complexity anchors** (~0.5–1.5
agent-days), not calendar predictions. This project's measured cadence is
8–13 stories per sprint-session; the binding constraint on this epic is its
**serial chain** (001 → 002 → 003 → 004 → 010) and the two external
dependencies story 010 needs real, not throughput.

**Needs-decision / flags**:
- **009** (real-time-rate pass): **decision RESOLVED** — CD Ruling 1
  (`production/creative-decisions-m02-preflight-2026-07-26.md`, **provisional
  pending user ratification**): **Option B unmodified**, ship 0.07 / 0.5 / 40, tick
  anchors CONFIRMED and feel targets RESTATED (~4:45 heartbeat, ~3 min gap). Scope
  **shrank** to a pure documentation pass (no `.tres`, no AC anchor, no test edits)
  and **widened** in one direction: its doc AC is now a **repo-wide `at 1x`
  annotation sweep** across `design/`, not needs-mood-only. Carries a named kill
  criterion (decay 0.07 → 0.05 on a nagging report; explicitly *not* on a dead-air
  report, which is a Cluster D content finding).
- **010** (live pair): the only story that requires `villager-ai-018`, the
  furniture chain, and `build-validation-navigability` to be REAL. Sequence it
  last within the epic and coordinate the three externals.
- **011** (Game Feel): Advisory, playtest-gated — not a Logic gate, not an
  MVP-Done blocker.
- **012** (save/load): **Vertical-Slice-tier; out of scope for Milestone 02**
  (AC24/AC25 are explicitly deferred by the milestone). Testable now against a
  mocked serializer; sequence into VS.

## Landed-Code Deltas (report-only — do NOT fix inside this epic)

Recorded 2026-07-26 against the landed spine. Each is a GDD/registry statement
that no longer matches shipped code. **Story 009 is the sanctioned place to
resolve #1 and #2**; the rest are doc-hygiene items for the GDD owner.

> **Ruling status (2026-07-26, both PROVISIONAL pending user ratification):**
> **#2** — resolved by **CD Ruling 1** (Option B unmodified; story 009's doc AC
> widened to a repo-wide `at 1x` sweep).
> **#3** — resolved by **TD NM-3**: Core Rule 4 is authoritative, the F2 variable
> table (GDD line ~266) is stale. Three rungs via source→rate table lookup; the
> two-multiplier form is **never** to be implemented — it would make the BLOCKING
> ladder invariant unenforceable and silently delete the "missing roof visibly
> costs" mechanic. **Story 003 already specifies three rungs correctly — no story
> change; the GDD line is the fix.**
> **#4** — resolved by **TD NM-6**: `has_urgent_need(villager_id) -> bool` is
> **canonized** as a required pure query, in addition to the documented surface.
> `architecture.md` must document it **before story 002 starts** (TD-owned,
> blocking); GDD + a new TR follow; `CONTRACTS.md` only when the module lands.
> **#5** — resolved by **TD NM-5**: canonical is the **three-arg**
> `start_recovery(villager_id, need, source_enum)` (and `stop_recovery(villager_id,
> need, reason)`); `architecture.md` is already correct. **Correction to the text
> below and to story 003's signature note: `CONTRACTS.md` contains NO
> `start_recovery` reference at all** — the documents actually carrying the
> signature are `architecture.md:373`, GDD line 159 / Core Rule 10, and
> `tr-registry.yaml` TR-042 + line 2222; the latter three elide `villager_id` and
> are the doc-fix targets.
> **#7** — resolved by **TD NM-7**: annotated in `CONTRACTS.md` §1 rather than
> deleted (`TR-needs-mood-system-025 (live-pair integration test — DI is its
> enabler per ADR-0001 Context, not itself a DI requirement)`). **This is the one
> `CONTRACTS.md` edit the TD made.** No story impact.

1. **GDD burst rule says `max_ticks_per_frame = 10`; the landed default is 12**
   (`neues-spiel/src/time_tick_system/time_tick_config.gd`, Sprint 8 re-tune per
   `design/quick-specs/tick-rate-retune-2026-07-25.md`; `entities.yaml` value 12).
   AC21 must be written against the **config value**, never the literal 10.
2. **Every real-time figure in the GDD is computed at 2.0 ticks/sec.** "1072
   ticks ≈ 8.9 min", "140 ticks = 70s", "`mood_smoothing_ticks` 40 = 20s at 1x".
   At the landed 4.0 the same tick counts are **4.5 min / 35 s / 10 s** — the
   pacing hypothesis (the deliberate ~6–7 min build-to-urgency gap) does not hold
   as written. Criterion #4 / story 009.
3. **F2's variable table lists only two multipliers** (`Bed = 1.0; ground = 0.4`)
   while Core Rule 4 and AC28 define three rungs. The 3-tier table in Rule 4 is
   authoritative; the F2 table is stale.
4. **The landed Villager AI seam is `has_urgent_need(villager_id) -> bool`**
   (`neues-spiel/src/villager_ai/villager_ai.gd`, duck-typed, nil-safe,
   `needs_provider`), which appears in neither the GDD nor `CONTRACTS.md`'s
   signature block. This epic must expose it **in addition to** the documented
   query API, or the landed FSM cannot be un-mocked.
5. **`start_recovery` arity differs by document**: GDD Core Rule 10 writes
   `start_recovery(need, source_enum)`; `docs/architecture/architecture.md` and
   `CONTRACTS.md` write `start_recovery(villager_id, need, source_enum)`. The
   architecture form is the implementable one (this system is per-villager) and
   is what the stories specify.
6. **`ground_trapped` has no reporter yet.** `villager-ai-018`'s ACs name only
   `ground_no_bed_owned` and `ground_bed_unreachable`. Story 007 implements the
   template for all three; the trapped value stays test-only until Villager AI
   reports it.
7. **`CONTRACTS.md` §1 cites `TR-needs-mood-system-025` as this system's DI
   TR-ID**, while `tr-registry.yaml` defines 025 as the live-pair integration
   requirement. Stories follow the registry (025 → story 010).

## Next Step

Run `/story-readiness production/epics/needs-mood-system/story-001-config-scaffold-and-ladder-invariant.md`,
then `/dev-story` to begin. Work stories in dependency order — each story's
`Depends on:` field lists what must be DONE first. Story 010 additionally
requires `villager-ai-018`, the furniture chain, and build-validation's shelter
flag to be landed and real.
