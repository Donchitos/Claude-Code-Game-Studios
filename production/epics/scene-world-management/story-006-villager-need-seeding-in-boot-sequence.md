# Story 006: Villager need seeding in the boot sequence — a spawned villager carries REAL need records before ACTIVE

> **Epic**: Scene / World Management
> **Status: Complete (2026-07-27 — 1330/1330 suite green 0 orphans, parent-verified; non-vacuity demonstrated)
> **Layer**: Foundation (boot sequencing) → drives Core (Needs & Mood spawn state)
> **Type**: Integration
> **Estimate**: 0.5 days *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*; **+0.5 contingency** reserved against the unreproduced failure recorded below
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**The gap this closes (verified on disk 2026-07-27):** `needs-mood-006` landed
`NeedsMood.initialize_villager(villager_id, active_needs = ACTIVE_NEEDS)` — the F4 spawn-init entry point
that seeds every active need at 100 and derives the villager's starting mood. It is fully implemented,
fully unit-tested (`tests/unit/needs_mood/spawn_init_and_need_activation_test.gd`), and **called from
nowhere in `src/`**.

`src/scene_world_management/valley.gd` assigns the provider at two sites — `_wire_villager_population()`
(the legacy always-present villager, id 0) and the roster loop in `spawn_starting_roster()` — but neither
site ever *seeds*. So in the shipped game every villager exists with **zero need records**.

**Why no test caught it, and why no obvious test can:** the entire `NeedsMood` query surface is
deliberately biased to answer "as if fine" for an untracked villager. `get_need_value` returns `100.0`,
`get_need_state` returns `SATISFIED`, `get_mood_band` returns `HAPPY`, `has_urgent_need` returns `false` —
each **without creating a record**. An unseeded villager is therefore *indistinguishable by query* from a
correctly seeded one at t=0. The divergence only appears under time: `_pass_f1_decay` iterates
`_need_records`, so a villager with no record **never decays, never crosses `urgency_threshold`, never
emits `need_urgent`, and never triggers the tier-1 sleep priority.** The payoff loop that
`needs-mood-010` (THE CROWN) proved end-to-end against a hand-seeded fixture **cannot start in
production** — not because the loop is wrong, but because nobody wound it up.

### ⚑ The reported first attempt did NOT reproduce — premise corrected, and it changes this story's shape

The task that raised this gap recorded that a first wiring attempt "turned the suite red (18 errors, 1
failure) and was reverted", and warned against assuming a one-line change. **That failure did not
reproduce against the current working tree.** Measured 2026-07-27 by the producer:
`_needs_mood.initialize_villager(...)` was added at *both* assignment sites (line ~425 and the roster loop
at ~572) and the full suite was run headless:

| Suite | Result |
|---|---|
| `res://tests/unit` | **878 test cases · 0 errors · 0 failures · 0 flaky · 0 orphans · exit 0** |
| `res://tests/integration` | **429 test cases · 0 errors · 0 failures · 0 flaky · 0 orphans · exit 0** |
| **Total** | **1307/1307 green** — the same 1307 `needs-mood-006` closed against |

The probe edit was reverted; `valley.gd` is unchanged on disk. Three candidate causes were read and
**each is ruled out as the source of a red suite**:

1. **Boot order / unwired `config`** — `NeedsMood.config` is Inspector-wired in `valley.tscn`
   (`config = ExtResource("18_needsmoodcfg")`, line 75), so it is non-null the moment `@onready` resolves.
   `set_need_value` dereferences `config.urgency_threshold` (`needs_mood.gd:519`) with no `_is_set_up`
   guard, so seeding *runs* pre-`setup()` without erroring. **This is still a real defect — see
   AC-SEED-AFTER-SETUP — but it is a silent-correctness defect, not a crash.**
2. **Tests asserting needs are untouched at spawn** — none exist. `decay_state_machine_test.gd`'s
   unknown-id tests construct their own bare `NeedsMood`; they never observe a booted `Valley`.
3. **The crown double-seeding** — `shelter_recovery_live_pair_test.gd` builds its own `NeedsMood` via
   `_make_needs_mood()` and seeds via `set_need_value`; it never touches `Valley`'s hosted instance. Its
   two `Valley`-facing tests (`test_production_wiring_gameworld_assigns_real_needs_mood_to_villager_needs_provider`,
   `test_no_other_call_site_assigns_needs_provider`) assert provider identity and a call-site grep — neither
   is sensitive to seeding.

**What this means for the story:** the work is **not** "fix 18 errors". The work is **making the call site
legal under ADR-0005 and making it provable at all** — because a green suite is exactly what this defect
already produces. Should the reported failure resurface during implementation, the +0.5 contingency covers
diagnosis; **do not revert on red, diagnose and record the cause in the commit body.**

**GDD**: `design/gdd/needs-mood-system.md` (F4 spawn initialization) + `design/gdd/scene-world-management.md`
(Booting state / boot orchestration)
**Requirement**:
- `TR-needs-mood-system-056` — every active need is 100 and mood equals `mean_active` at spawn (F4).
  **`needs-mood-006` satisfied this in the module; this story is the only place it can be satisfied in the
  shipped game.**
- `TR-scene-world-management-004` / `-034` — boot gate: Valley attaches after RID Ready, all initialization
  completes before ACTIVE.
- `TR-villager-ai-behavior-065` — the starting roster is placed at world generation; **its members must be
  fully-formed villagers, and a villager with no needs is not one.**

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0005** (Boot Sequencing & Initialization Gate) — primary;
**ADR-0001** (Inter-System Reference & DI) — secondary; **ADR-0002** (config-derived spawn values) —
secondary.

**ADR Decision Summary**: ADR-0005 makes `GameWorld`'s boot orchestration the single ordering authority:
Valley attaches, `_setup_injected_tier()` sweeps every module's `setup()`, `_run_world_genesis()` builds the
world and spawns the roster, then — and only then — ACTIVE. `needs-mood-006`'s own Control Manifest states
the rule this story must obey verbatim: *"initialization happens in an explicitly-callable method reached
from the boot path, **never in `_ready()`**"*. `Valley._wire_villager_population()` is called from
`Valley._ready()` — **seeding villager 0 there would satisfy the suite and violate the ADR.** That is the
single most important constraint in this story.

**Engine**: Godot 4.7-stable | **Risk**: **LOW** — pure GDScript call-site wiring against two already-landed,
already-tested public surfaces. The risk in this story is not technical difficulty; it is **writing an
assertion that cannot tell success from failure**.

**Control Manifest Rules (this layer — boot sequencing):**
- **Required**: seeding is reached from the boot path through an explicitly-callable method, after the
  owning module's `setup()` has completed; it is driven through the already-landed
  `NeedsMood.initialize_villager()` public surface, never by reimplementing F4 or by writing
  `set_need_value` from `valley.gd`; every villager that exists at ACTIVE has been seeded exactly once.
- **Forbidden**: seeding from `_ready()` or from any `_process`/`_physics_process` path
  (ADR-0005 + `needs-mood-006` Control Manifest); a second `setup()` call site; reaching into any private
  member of `NeedsMood` (`_need_records`/`_mood_records` in particular) from `valley.gd` or from a test's
  Act phase; re-seeding an already-seeded villager in a way that overwrites live values
  (`needs-mood-012`'s AC24 — load-restored smoothing state).
- **Guardrail**: **an acceptance assertion that passes on today's build is not an assertion.** Every AC
  below must fail if the production seeding call is deleted. See AC-PROBE-IS-NON-VACUOUS.

---

## The Pattern — third occurrence, recorded deliberately

This is the **third time on this project** a production API shipped green, complete, tested and **uncalled**:

| # | API | Shipped | Found by | Fixed by |
|---|---|---|---|---|
| 1 | `VoxelWorldGrid.generate_terrain()` | vox-006 | the Valley booting an empty grid, S9 | `scene-005` |
| 2 | `Valley.spawn_starting_roster()` | villager-ai-021 | the Valley booting with zero villagers, S9 | `scene-005` |
| 3 | `NeedsMood.initialize_villager()` | needs-mood-006 | this story | this story |

All three were **green on the day they landed**, all three had passing tests written against them, and all
three were discovered only when something actually **ran** — never by a test, never by a story-list diff,
never by a review of the epic that owned the API. Note also that #1 and #2 were both found in the *same*
sprint and fixed by the *same* story, which is the tell: this is not three coincidences, it is one
structural gap recurring.

> **The rule this establishes: a new production API needs a proven caller in the same sprint, or it is dead
> code with green tests.** "Proven" means an assertion that observes the API's effect *through the boot
> path or the production call graph* — not a unit test that calls it directly. A unit test proves the API
> works. Only a caller proves the game uses it.

The corollary, which is what makes this class of defect so cheap to ship and so expensive to find: when a
module's read surface is designed to answer benign defaults for unknown ids — a good, defensible design
choice that `NeedsMood` makes deliberately and documents — **the absence of a caller is invisible to every
query.** Defensive defaults and dead-code detection are in direct tension. That tension is the reason a
guard is proposed below rather than left to vigilance.

---

## Acceptance Criteria

- [x] **AC-SEED-BEFORE-ACTIVE**: At the instant `GameWorld`'s boot state first reads `BootState.ACTIVE`,
      **every** villager reported by `Valley.get_villagers()` — the always-present villager 0 *and* every
      member `spawn_starting_roster()` created — has a real, tracked `sleep` need record and a real mood
      record in the hosted `NeedsMood` instance. Asserted headlessly, non-vacuously (see
      AC-PROBE-IS-NON-VACUOUS). A boot that HALTs (RID Failed, or a BLOCKING config invariant) never reaches
      seeding — existing halt semantics unchanged and still terminal. [TR-needs-mood-system-056,
      TR-scene-world-management-004]
- [x] **AC-SEED-NOT-FROM-READY**: The seeding call is **not** reachable from `Valley._ready()`. Specifically,
      `_wire_villager_population()` — which `_ready()` calls — must not gain an `initialize_villager` call;
      villager 0's seeding moves to an explicitly-callable method reached from `GameWorld`'s boot
      orchestration (the existing `_run_world_genesis()` phase is the natural home; **the exact method shape
      is the technical-director's / implementer's call, the constraint is not**). Grep-guarded by test on the
      established non-writer-guard precedent: zero `initialize_villager` occurrences inside
      `_wire_villager_population`'s body or any `_ready`/`_process`/`_physics_process` call graph.
      [ADR-0005; `needs-mood-006` Control Manifest "never in `_ready()`"]
- [x] **AC-SEED-AFTER-SETUP**: Seeding runs strictly **after** `NeedsMood.setup()` has completed
      (`is_set_up()` reads `true` at the moment of the first seeding call). Rationale, recorded in-file:
      `set_need_value` derives `NeedState` from `config.urgency_threshold`, and `setup()` is where
      `config.validate()`'s two-tier clamp/BLOCKING policy is applied — seeding first would derive spawn
      state from **unvalidated, unclamped** config values. Asserted by ordering, not by reading the code.
      [ADR-0002, ADR-0005]
- [x] **AC-SEED-EVERY-ROSTER-MEMBER**: `spawn_starting_roster()` seeds **each villager it creates**, exactly
      once, at the same point it already assigns `needs_provider`. With `starting_villager_count = 3` in a
      test config, all three spawned villagers plus villager 0 hold records (4 total). A partial or zero
      placement remains a valid, deterministic outcome — the villagers that *were* placed are seeded, and
      no record is created for a villager that was not.
      [TR-villager-ai-behavior-065]
- [x] **AC-PROBE-IS-NON-VACUOUS**: The test proving AC-SEED-BEFORE-ACTIVE **fails when the production
      seeding call is removed**, and this is demonstrated, not asserted — the story's commit body records the
      observed failure output from one deliberate removal run. ⚑ **The obvious assertion is vacuous and must
      not be used**: `get_need_value(id, &"sleep") == 100.0` passes on today's *unseeded* build, because the
      query returns `100.0` for an untracked villager by design. Two forms are known to work; pick one and
      state which in the commit body:
      **(a) the time probe** — drive N ticks through the real tick source and assert the value is *strictly
      below* 100.0 (an unseeded villager never enters `_pass_f1_decay`'s iteration and stays at the default
      forever; at the shipped `decay_per_tick_sleep = 0.07`, even a single tick moves a seeded villager to
      99.93);
      **(b) an additive read-only observability accessor** on `NeedsMood` (e.g. a tracked-record predicate or
      count) — if this route is taken, keep it minimal and additive, name it in the commit body, and do not
      expose `_need_records` itself.
- [x] **AC-SEED-IS-IDEMPOTENT-AT-BOOT**: Seeding a villager that already holds records does not reset live
      values. Calling `spawn_starting_roster()` a second time (its own already-tested "no growth bookkeeping"
      shape) re-seeds nobody's live values, and a villager whose `sleep` has already decayed keeps the decayed
      value. This is `initialize_villager`'s own landed guarantee — this AC proves it survives *through the
      boot path*, it does not re-test the module. [`needs-mood-006` idempotence AC; `needs-mood-012` AC24]
- [x] **AC-NO-BOOT-EVENTS**: A full boot emits **zero** `need_urgent`, `need_satisfied` and
      `mood_band_changed` signals. A villager born at 100 has crossed nothing; the first legitimate event is
      the urgency cross ~1072 ticks later (`(100 − 25) / 0.07` at the shipped config). Asserted by a listener
      connected before boot. [`needs-mood-006` "no spawn events" AC]
- [x] **AC-SUITE-GREEN-AND-DIAGNOSED**: The full suite is green at the story's close (currently
      1307 blocking cases, 0 orphans). **If the reported 18-errors/1-failure result resurfaces, the failure is
      diagnosed and its cause recorded in the commit body — it is not worked around by reverting the wiring
      or by relaxing an AC above.** Any pre-existing test that must change to accommodate correct production
      behaviour is named individually in the commit body with the reason.

---

## Implementation Notes

*Derived from ADR-0005 (the one boot orchestration site), ADR-0001 (drive landed public surfaces), ADR-0002
(config-derived spawn values):*

- **Two call sites, two different fixes.** The roster loop in `spawn_starting_roster()` is already on the
  boot path (`GameWorld._run_world_genesis()` calls it, after every module's `setup()`) — seeding there is
  legal as written and is a one-line addition next to the existing `needs_provider` assignment. Villager 0
  is the one that needs moving: its provider assignment lives in `_wire_villager_population()`, which
  `_ready()` calls, and that is the site AC-SEED-NOT-FROM-READY forbids. **Leave the provider assignment
  where it is** — `shelter_recovery_live_pair_test.gd`'s `test_no_other_call_site_assigns_needs_provider`
  grep-guards exactly one assigning file, and `valley.gd`'s own class doc calls that site "the ONLY call
  site in `src/` that ever assigns `VillagerAi.needs_provider`". Only the *seeding* moves.
- **Drive the landed surface, never reimplement F4.** `initialize_villager(villager_id)` with **no second
  argument** — the `active_needs` override exists solely for `needs-mood-006`'s own mocked-schema test path
  and its doc comment states "production NEVER passes a second argument". Passing `ACTIVE_NEEDS` explicitly
  is not equivalent in intent and should not be done.
- **The seeding is `O(active needs)` per villager, once per spawn**, and `ACTIVE_NEEDS` is `[SLEEP]` at MVP.
  This adds no measurable boot cost and does not interact with `scene-005`'s AC-BOOT-BUDGET ceiling
  (3.0 s total / ≤ 2.5 s mesh phase). Do not re-measure boot for this story.
- **Where the probe should live.** `tests/integration/scene_world/world_genesis_boot_test.gd` already boots a
  real `GameWorld` and asserts the world is populated at ACTIVE — the population's *initialization* is the
  same class of boot invariant and belongs beside it, not in a new isolated file. Prefer extending it over
  creating a parallel boot harness.
- Cross-reference `docs/engine-reference/godot/` before touching any engine API (**BLOCKING**, as in M01) —
  though this story is expected to touch none.

---

## Out of Scope

*Handled elsewhere, or surfaced as missing — do not implement here:*

- **F4 itself** — the seeding math, idempotence semantics and new-need activation are `needs-mood-006`,
  Complete. `needs_mood.gd` should not need to change at all, with the single narrow exception permitted by
  AC-PROBE-IS-NON-VACUOUS option (b).
- **Restoring needs/mood from a save** (`needs-mood-012`, AC24) — the explicit **not**-F4 path. This story
  must not make that path harder: seeding stays non-overwriting, which is what keeps load-restored smoothing
  state intact.
- **Why-strings** (`needs-mood-007`) and **burst/pause/warp determinism** (`needs-mood-008`) — they consume
  seeded state; they do not create it.
- **The despawn / removal counterpart.** There is no `NeedsMood` teardown API and no villager-despawn path in
  the shipped game, so records accumulate for the session. That is correct and harmless at MVP roster scale
  (one villager) and is **not** silently absorbed here — it is named in Open Decisions below as a future
  story's problem, not this one's.
- **Seeding needs for villagers created by any future growth/arrivals/recruitment path** — no such path
  exists (`starting_roster_test.gd` asserts `spawn_starting_roster` has no growth bookkeeping of its own).
  When one lands, it inherits this story's rule; it does not retro-fit it.
- **Implementing the dead-code guard proposed below.** This story *recommends* it and sizes it; it does not
  build it. That is a user decision (see Open Decisions).

---

## QA Test Cases

- **AC-SEED-BEFORE-ACTIVE**: Given a headless boot of the real `GameWorld` with a `MockResourceItemDatabase`
  configured ready-immediately, When boot state first reads `ACTIVE`, Then every villager in
  `valley.get_villagers()` holds a tracked `sleep` record and a mood record in `valley.get_needs_mood()`.
  Given a RID `Failed` outcome, Then no seeding occurred and the halt stays terminal.
- **AC-SEED-NOT-FROM-READY**: Given the source tree, When `valley.gd`'s `_ready()` /
  `_wire_villager_population()` / `_process` call graphs are scanned for `initialize_villager`, Then zero
  occurrences are found.
- **AC-SEED-AFTER-SETUP**: Given an instrumented boot, Then the first `initialize_villager` call is observed
  strictly after `NeedsMood.is_set_up()` first reads `true`, and strictly before `ACTIVE`.
- **AC-SEED-EVERY-ROSTER-MEMBER**: Given `starting_villager_count = 3` in a test config, When boot completes,
  Then 4 villagers exist and all 4 hold records. Given a world with too few standable cells, Then only the
  villagers actually placed hold records, deterministically, with no crash.
- **AC-PROBE-IS-NON-VACUOUS**: Given a booted world, When N ticks are driven through the real tick source,
  Then villager 0's `sleep` value is strictly below 100.0. **Negative control (run once, by hand, recorded
  in the commit body):** Given the production seeding call is deleted, When the same test runs, Then it
  FAILS. A test that passes both ways does not satisfy this AC.
- **AC-SEED-IS-IDEMPOTENT-AT-BOOT**: Given a booted world whose villager 0 `sleep` has decayed to a known
  value below 100, When `spawn_starting_roster()` is called a second time, Then villager 0's `sleep` is
  unchanged and no villager's live value was reset.
- **AC-NO-BOOT-EVENTS**: Given listeners connected to `need_urgent`, `need_satisfied` and
  `mood_band_changed` before boot, When boot completes, Then all three counts are zero.
- **AC-SUITE-GREEN-AND-DIAGNOSED**: Given the full headless suite (`tests/run-tests.cmd`), When it runs at
  the story's close, Then exit code 0 with 0 errors, 0 failures, 0 orphans.

---

## Test Evidence

**Story Type**: Integration (BLOCKING)
**Required evidence**:
- `neues-spiel/tests/integration/scene_world/world_genesis_boot_test.gd` — extended with the seeding-at-boot
  invariant block; must exist, pass headless, and run in the commit gate. (A new
  `neues-spiel/tests/integration/scene_world/villager_need_seeding_boot_test.gd` is acceptable if the
  implementer judges the existing file has grown unwieldy — state which was chosen in the commit body.)
- Grep-guard test for AC-SEED-NOT-FROM-READY, on the established non-writer / literal-guard precedent
  (`building-023`, `build-validation-002`, `shelter_recovery_live_pair_test.gd`'s own
  `_find_files_assigning` helper is the closest existing shape and can be reused).
- The AC-PROBE-IS-NON-VACUOUS negative-control result, recorded in the commit body — not a separate artifact.

**Status**: [x] Created — chose the NEW file
(`neues-spiel/tests/integration/scene_world/villager_need_seeding_boot_test.gd`), not an extension of
`world_genesis_boot_test.gd`: that file already bundles one expensive real 2000x2000 production boot into a
single test to avoid re-paying its cost, and this story's 7 ACs are an independent-enough cluster (10 test
functions) to make it unwieldy, exactly as this section's own named alternative anticipated.
`world_genesis_boot_test.gd` was NOT modified. Grep-guard test:
`test_ac_seed_not_from_ready_zero_initialize_villager_calls_in_ready_or_wire_or_process` (generalizes
`world_genesis_boot_test.gd`'s own `_extract_process_function_bodies` shape to an arbitrary named function).

**AC-PROBE-IS-NON-VACUOUS negative-control result (recorded 2026-07-27, per this AC's own requirement):**
chosen form is **(a) the time probe** (drives 1 real tick through the actual global `TimeTickSystem`
Autoload singleton — never a mock — and asserts every villager's `sleep` has strictly decayed below 100.0).
Demonstration: the `_valley.seed_default_villager_needs()` call in `GameWorld._run_world_genesis()` was
commented out; `test_ac_seed_before_active_real_boot_every_villager_decays_below_100_after_one_real_tick`
was re-run in isolation and **FAILED** (1 test cases | 0 errors | 1 failures | 0 orphans, exit code 100) —
villager 0's `sleep` stayed at exactly `100.0` after the tick (never seeded, never entered F1 decay's
iteration), while the roster-spawned villager (seeded via the OTHER, unaffected call site in
`Valley.spawn_starting_roster()`) correctly read below 100.0, so the test failed on villager 0's own
assertion specifically — not a syntax/harness error. The call was then restored verbatim
(`git diff` against `game_world.gd` confirmed a clean, comment-free restore), the class cache was rebuilt,
and the same test was re-run green. This is the demonstration AC-PROBE-IS-NON-VACUOUS requires: the
assertion is not vacuous, because it provably fails when the production seeding call it depends on is
removed.

**Full suite at story close**: `res://tests/unit` + `res://tests/integration` — **1330 test cases · 0
errors · 0 failures · 0 flaky · 0 skipped · 0 orphans · exit 0** (up from the pre-story 1307/1307 baseline
— the 23 new cases are this story's own `villager_need_seeding_boot_test.gd`). The previously-reported
18-errors/1-failure result did **not** resurface (consistent with the 2026-07-27 producer measurement
already recorded above in Context) — no diagnosis was required beyond what that section already recorded.

---

## Dependencies

- **Depends on** (all Complete): `needs-mood-006` (`initialize_villager` — this story is its named caller),
  `needs-mood-001`/`002`/`005` (config, decay/state machine, mood + `mean_active`), `villager-ai-021`
  (`spawn_starting_roster`), **`scene-005`** (the `_run_world_genesis()` boot phase this story hangs off —
  without it there is no post-`setup()` boot-path home for villager 0's seeding), `scene-004` (GameWorld
  assembly seam), `spine-002`/`003` (BootState + config pattern), `needs-mood-010` (THE CROWN — establishes
  that the loop it winds up is correct).
- **Blocked on**: nothing. Every surface it calls is landed and tested.
- **Unlocks**:
  - The Needs & Mood → Villager AI payoff loop **actually runs in the shipped game** — today it cannot start,
    because decay only iterates existing records. This is milestone criterion #5's production reality as
    distinct from its test-fixture reality.
  - Any run-level capture, playtest or screenshot in which a villager's mood or need state is expected to
    *change over time*.
  - `needs-mood-007` (why-strings) and the Villager Info UI epic — both read state that is currently frozen
    at its default for every production villager.
- **Open decisions this story surfaces (producer → user / technical-director)**:

  1. **⚑ THE GUARD — is a cheap structural check worth it, after three occurrences?** *(User decision; this
     story recommends but does not implement.)* Three options were considered:

     | Option | What it is | Cost | Honest weakness |
     |---|---|---|---|
     | **(a) Grep test for a production call site of every public entry point** | A test enumerating public methods across `src/` and asserting each has ≥1 non-definition call site in `src/` | ~1.0 day to build, ongoing maintenance | **High false-positive rate and low signal.** It cannot distinguish a real caller from a doc-comment mention, and it would fire on every legitimately-deferred API (`generate_terrain()` is *correctly* uncalled in `src/` today and grep-guarded to stay that way — this test would demand the opposite). This project has already been burned three times by grep guards whose premise was misread; a broad one adds a fourth surface for that. **Not recommended.** |
     | **(b) A boot-invariant assertion block** | One growing block in the existing boot integration test: "at `ACTIVE`, the world has terrain **and** a populated roster **and** every villager has need records" — one line added per landed system | ~0.1 day now, ~1 line per future system | Only covers boot-path systems. Will not catch a dead API in a mid-session code path. |
     | **(c) Nothing — rely on review vigilance** | Status quo | 0 | Has now failed three times, twice in one sprint. |

     > **Recommendation: (b).** It is the cheapest of the three by an order of magnitude, it asserts the thing
     > that actually matters (*the game state a player would see*, not a call-graph property), and it has a
     > natural growth path — every future boot-path system adds one line to a block that already exists. It
     > also directly encodes the sprint rule this story establishes: an API landing in sprint N gets its
     > caller asserted in sprint N. Its weakness is real and should be accepted knowingly: it covers boot,
     > not mid-session. Mid-session dead code stays a review responsibility.
     >
     > Pair it with a **planning-time** habit rather than a second test: at each `/sprint-plan`, for every
     > story that adds a public production API, confirm a caller story exists in the *same* sprint. That is
     > free, it is where the previous three failures were actually decidable, and it needs no code.
     >
     > **We will know this was right if:** the next new production API lands with its caller in the same
     > sprint, and the boot-invariant block catches at least one regression before a human does. **We will
     > know it was wrong if:** a fourth uncalled-API occurrence lands in a mid-session path, in which case the
     > guard was scoped too narrowly and option (a)'s cost becomes worth re-pricing.

  2. **The reported 18-errors/1-failure result is unexplained.** It did not reproduce (1307/1307 green,
     measured 2026-07-27, both suites). Either it predates a change now on disk, or the attempted wiring
     differed in shape from the two-site form measured here. **Recorded rather than dismissed**: if it
     resurfaces, AC-SUITE-GREEN-AND-DIAGNOSED governs, and the +0.5 contingency in this story's estimate is
     its budget.

  3. **No despawn / record-teardown counterpart exists.** `NeedsMood` has no API to drop a villager's
     records and the game has no despawn path, so records accumulate for the session lifetime. Harmless at
     the MVP roster (1 villager) and out of scope here — but it becomes real the first time a villager can
     die, leave, or be removed. **No story anywhere owns it.** Listing it as missing, not fabricating one.
