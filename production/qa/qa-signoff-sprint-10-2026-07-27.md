# QA Sign-Off — Sprint 10 (THE PAYOFF SPRINT — Milestone 02 Criterion #5)

**Date**: 2026-07-27
**QA Lead**: qa-lead (this artifact)
**Sprint file**: `production/sprints/sprint-10.md` ("Sprint Result — CLOSED 2026-07-27")
**QA plan**: **none found.** No `production/qa/qa-plan-sprint-10-*.md` exists on disk (checked via glob
against `production/qa/`). This is a DoD line item ("QA plan exists for Sprint 10 ... run `/qa-plan sprint`
before implementation begins") that was not produced. Recorded as a condition below, not silently absorbed.
**Milestone criterion #14**: the second `qa-signoff-sprint-*.md` artifact, and per Sprint 9's own condition
#4, this is the first sprint to also produce a single consolidated smoke-check artifact at hand-off
(`production/qa/smoke-sprint-10-2026-07-27.md`, written alongside this document).

---

## 1. Scope confirmation — verified against story files and `sprint-status.yaml`, not the Sprint Result's own summary line

`sprint-status.yaml` tracks **16 stories** for Sprint 10: the 15 originally planned (10 Must + 3 Should +
2 Nice) plus `scene-006`, added mid-sprint. The Sprint Result section's own headline claims **"16/16
scheduled stories complete."** This does not hold up: two Nice-to-have stories still read `Status: Ready`
on their own story files and `blocked`/`backlog` in `sprint-status.yaml`:

| Story | yaml status | Story file `Status` line | Actually shipped? |
|---|---|---|---|
| `build-validation-009` | `blocked` | Ready | **No** — externally gated on TD concurrence (CD Ruling 2 / `@export RefCounted` collision) that was never given |
| `building-009` | `backlog` | Ready | **No** — never pulled; correctly so, per D8's resolution (option (c): ship the crown on `028+016`, schedule the full C1 demolition chain as S11's opener) |

**Corrected count: 14/16 tracked stories complete**, not 16/16. This is not a quality problem — both
stories are Nice-to-have, both were the plan's own first- and second-named trim candidates, and not
pulling `building-009` is the direct, correct consequence of D8 being resolved toward option (c) (full C1
chain deferred to S11). But the Sprint Result's own summary line is factually wrong as written and should
be corrected — condition below.

**A second, smaller inaccuracy in the same Sprint Result paragraph**: it opens with "Suite grew 1264 ->
1383." Reading every landed story's own header in landing order gives a fully monotonic sequence starting
from Sprint 9's parent-verified close (1198): **1198 → 1241 (villager-ai-018 / needs-mood-005 /
building-028, day-one parallel) → 1250 (needs-mood-004) → 1264 (building-016) → 1298 (presentation-003 /
needs-mood-010) → 1307 (needs-mood-006) → 1320 (bv-007) → 1330 (scene-006) → 1345 (needs-mood-007) → 1355
(building-011) → 1383 (bv-008, final)**. 1264 is a mid-sprint checkpoint (after `building-016`), not the
sprint's starting count — the correct opening figure is **1198**, not 1264. Minor, but the same paragraph
now carries two small factual errors; flagged together below as one condition.

The 14 stories actually complete, verified against each story file's own `Status` line (not the sprint
file's table):

| Story | Type | Status at sign-off |
|---|---|---|
| villager-ai-018 | Integration | Complete (1241/1241) |
| needs-mood-005 | Logic | Complete (1241/1241) |
| needs-mood-004 | Logic | Complete (1250/1250) |
| building-028 | Logic | Complete (1241/1241) |
| needs-mood-006 | Logic | Complete (1307/1307) |
| needs-mood-007 | Logic | Complete (1345/1345) |
| needs-mood-008 | Logic | Complete (own suite 9/9; full-gate deferred to bv-008's count) |
| building-016 | Logic | Complete (1264/1264) |
| presentation-003 | Integration | Complete (1298/1298) |
| **needs-mood-010** | **Integration (THE CROWN)** | **Complete (1298/1298)** |
| scene-006 | Integration | Complete (1330/1330) |
| build-validation-007 | Logic | Complete (1320/1320) |
| build-validation-008 | Logic | Complete (1383/1383, final) |
| building-011 | Logic | Complete (1355/1355) |

---

## 2. Per-story verdict

| Story | Verdict | Evidence pointer |
|---|---|---|
| villager-ai-018 | **PASS** | `neues-spiel/tests/integration/villager_ai/sleep_and_home_test.gd` (exists, 10/10 per story header) |
| needs-mood-005 | **PASS** | `neues-spiel/tests/unit/needs_mood/mood_smoothing_and_bands_test.gd` (exists) |
| needs-mood-004 | **PASS** | `neues-spiel/tests/unit/needs_mood/recovery_interruption_and_rerating_test.gd` (exists) |
| building-028 | **PASS WITH NOTES** | `neues-spiel/tests/unit/building_system/furniture_placement_base_test.gd` (exists, carries the inherited BV-1 "never bulk_writes on FURNITURE completion" regression guard). **The DoD's own BLOCKING follow-on — re-verifying `build-validation-006`'s `is_need_functional` true branch non-vacuously — was NOT satisfied**: see §4.1, a real BLOCKING gap, not a cosmetic one. |
| needs-mood-006 | **PASS** | `neues-spiel/tests/unit/needs_mood/spawn_init_and_need_activation_test.gd` (exists on disk; note it is **untracked in git** per working-tree status at time of writing — not yet committed) |
| needs-mood-007 | **PASS WITH NOTES** | `neues-spiel/tests/unit/needs_mood/why_string_templates_test.gd` (exists). `ground_trapped` has no production reporter yet (honestly named in the story's own Implementation Notes — exercised only by mock until Villager AI reports it) |
| needs-mood-008 | **PASS** | `neues-spiel/tests/unit/needs_mood/burst_pause_warp_determinism_test.gd` (exists) |
| building-016 | **PASS WITH NOTES** | `neues-spiel/tests/unit/building_system/multi_cell_furniture_placement_test.gd` (exists). The multi-cell **redo** limitation (see §4.2) is real and confirmed in `plan_only_undo_redo_test.gd`'s own class doc comment |
| presentation-003 | **PASS** | `neues-spiel/tests/unit/presentation/villager_body_view_test.gd` + `tests/integration/presentation_experience/villager_body_integration_test.gd` (both exist). **The `_visual_position` call-site allowlist guard verified genuine** — see Gate 3 below |
| **needs-mood-010** | **PASS WITH NOTES** | `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` + `production/qa/evidence/needs-mood-010-shelter-recovery-live-pair-evidence-20260727.md` (both exist). **Verified genuinely unmocked at the Needs↔Villager-AI seam and real on the furniture/shelter side** — see Gate 2 below. Notes: the live-pair harness still seeds via the sanctioned `set_need_value` test-seam rather than the (now-real) `initialize_villager()` production path, and does not assert the why-string literal — both honestly disclosed in the story's own evidence doc, and neither narrows AC34's six checkboxes |
| scene-006 | **PASS** | `neues-spiel/tests/integration/scene_world/villager_need_seeding_boot_test.gd` (exists). **Non-vacuity independently verified** — see Gate 1 below |
| build-validation-007 | **PASS WITH NOTES** | `neues-spiel/tests/unit/build_validation/room_recognized_pacing_test.gd` (exists). `time_tick_system` is optional/duck-typed with no production-wiring assertion — see §4.3 |
| build-validation-008 | **PASS WITH NOTES** | `neues-spiel/tests/unit/build_validation/warning_info_tiers_test.gd` (exists). AC35's decorative-item case is explicitly `[PROVISIONAL — mocked definition]` in the story's own AC list (no non-need-functional item exists in MVP); end-to-end bed emission is blocked by the same missing RID content as building-028 (§4.1) |
| building-011 | **PASS** | `neues-spiel/tests/unit/building_system/plan_only_undo_redo_test.gd` (exists) |
| build-validation-009 | **NOT LANDED** | Nice-to-have, externally blocked on TD concurrence (never given); correctly not pulled |
| building-009 | **NOT LANDED** | Nice-to-have, correctly deferred per D8 option (c) |

---

## 3. Three headline verification gates — independently checked, not taken on the story's own say-so

### Gate 1 — `scene-006`'s non-vacuity claim: **PASS, genuinely time-based**

Read `neues-spiel/tests/integration/scene_world/villager_need_seeding_boot_test.gd` directly. Confirmed:
- The obvious vacuous form (`get_need_value(...) == 100.0`) is present in the test **only as a documented
  contrast**, explicitly commented "kept here as a documented contrast, never as this test's own proof."
- The actual proof (`test_ac_seed_before_active_real_boot_every_villager_decays_below_100_after_one_real_tick`)
  boots a **real** `GameWorld`/`Valley.tscn`, fires exactly one real tick through the actual global
  `TimeTickSystem` Autoload (`TimeTickSystem.tick.emit()` — never a mock), and asserts every villager's
  `sleep` value is **strictly less than 100.0** afterward. This is impossible for an unseeded villager
  (`_pass_f1_decay` only iterates tracked records), so the assertion is genuinely load-bearing.
- The story file itself records a negative-control run (production call deleted, test re-run, observed
  failure: `1 test cases | 0 errors | 1 failures | exit code 100`, villager 0 stayed at exactly 100.0,
  restored verbatim afterward) — consistent with the test file's own structure.
- This is exactly the non-vacuity bar the task asked to verify. **Confirmed, not assumed.**

### Gate 2 — `needs-mood-010`'s live-pair claim: **PASS, genuinely unmocked at the required seam**

Read `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` directly. Confirmed:
- A real `NeedsMood.new()` and a real `VillagerAi.new()` are constructed headless, and `villager.needs_provider`
  is assigned **directly to the real `NeedsMood` instance** — no mock at the Needs↔Villager-AI seam, exactly
  the story's own forbidding rule.
- The furniture/shelter side is **also real**, not mocked away: a real `FurnitureRegistry.place()` call lays
  a genuine 2-cell bed, and a real `BuildValidation` instance classifies it via an actual roofed/floored room
  on a real `VoxelWorldGrid`, bridged by a new `FurnitureBedProvider` adapter. Only `building-017` (demolition,
  deferred to S11 per the story's own Out of Scope) is stood in for by directly firing the adapter's
  `furniture_revoked` signal.
- `test_unsheltered_bed_recovers_at_unsheltered_multiplier_rate` exists and asserts the credited rate equals
  `base_recovery_per_tick_sleep * unsheltered_bed_multiplier` (×0.7) against a real unroofed placement.
- `test_poll_not_event_round_trip_completes_with_need_urgent_unconnected` exists and drives the full round
  trip with `need_urgent` deliberately never connected.
- `test_no_other_call_site_assigns_needs_provider` — grep-guards exactly one production assignment site
  (`valley.gd`).
- **Confirmed, not assumed**, with one honest note: the live-pair harness seeds preconditions via the
  sanctioned `set_need_value` test-only seam rather than the (by sprint's end, real) `initialize_villager()`
  production call, and never asserts the "sleeping rough — no shelter" why-string literal. The story's own
  evidence doc discloses this and states it does not narrow AC34's own six checkboxes — assessed as correct;
  carried forward as a minor note, not a defect.

### Gate 3 — `presentation-003`'s `_visual_position` guard: **PASS, genuine call-site allowlist**

Read `neues-spiel/tests/unit/presentation/villager_body_view_test.gd` directly.
`test_visual_position_raw_field_read_only_inside_villager_ai_directory` recursively scans every `.gd` file
under `res://src`, excludes only `res://src/villager_ai/` from the scan, and distinguishes a raw private
`_visual_position` field read from a call to the public `get_visual_position()` accessor by checking the
character immediately preceding each match (a word character means it's part of a longer identifier, i.e.
the accessor name, and is not a violation). This is a genuine call-site allowlist, not a filename check —
it would fail a hypothetical fourth reader anywhere in `src/` that touches the raw field directly, while
passing this story's own sanctioned accessor-based read. **Confirmed, not assumed.**

---

## 4. Deviations flagged this sprint (recorded honestly, not absorbed)

### 4.1 — `build-validation-006`'s `is_need_functional` true branch: still untestable, and this was a DoD BLOCKING item

The Sprint 10 DoD lists, as **BLOCKING**: *"`build-validation-006`'s `is_need_functional` true branch
re-verified non-vacuously against a real `ItemDefinitionResource` once `building-028` lands."* `building-028`
landed. The re-verification did not happen, because there is still no real bed resource to verify against:
`neues-spiel/data/` contains only `data/config/`, **no `data/items/` directory exists at all** (confirmed by
glob), and `shelter_classification_test.gd`'s own `test_is_need_functional_unknown_id_returns_false_without_error`
still asserts `config.is_need_functional(&"bed") == false`. The Sprint Result section names this directly and
honestly ("Blocked by missing content, not by code... RID content authoring (rid-008/009) is in no sprint —
it belongs in Sprint 11"), and `needs-mood-010`'s own crown runs on a registry-placed bed rather than an RID
item with the flag set, which is a different (and already-covered) code path. **This is a real, disclosed
gap — but it means a DoD line explicitly marked BLOCKING was not actually closed this sprint.** It should not
be read as satisfied; it is a hard carry-forward, not a completed item.

### 4.2 — Multi-cell furniture redo can produce a "half a bed"

`building-016`'s own AC75 guarantees atomic placement (all footprint cells or none). Undo also treats a
footprint atomically for cancellation (confirmed in `plan_only_undo_redo_test.gd`'s class doc: "an
all-pending footprint's siblings cancel TOGETHER in one undo() call"). **Redo does not carry the same
guarantee** — the same doc comment states redo "re-validates every cell independently," meaning a footprint
cell reoccupied since the undo is dropped while its sibling is re-created, which can leave a bed's other
cell rebuilt alone. This is named in the Sprint Result's own carry-forward ("the multi-cell furniture redo
limitation") and confirmed structurally here. Not a regression against any shipped guarantee (redo was never
specified to be atomic), but worth a dedicated AC before S11 if multi-cell items grow beyond the bed.

### 4.3 — `build-validation-007`'s tick source is optional, not asserted

`room_recognized_pacing_test.gd`'s own fixture comment states `BuildValidation.time_tick_system` is nil-safe
and nil is a valid, silently-accepted configuration (pacing simply freezes at tick 0). Unlike
`needs-mood-010`'s `needs_provider` seam, which carries an explicit "exactly one production call site"
grep guard, there is no equivalent assertion that a real tick source is ever wired for
`room_cue_cooldown_ticks` in the shipped game. If nobody wires it, celebration pacing silently never engages
(every recognition would celebrate, which is a soft failure, not a crash). Recommend a production-wiring
guard analogous to the crown's, if room-recognition celebration is meant to reliably pace in the shipped game.

### 4.4 — Carried, not new, deviations (confirmed still true)

- **No bed resource in `data/items/`** (§4.1) also means `build-validation-008`'s warning tiers cannot fire
  end-to-end for a real bed; AC35's decorative-item case is explicitly `[PROVISIONAL — mocked definition]`
  in the story's own AC list, confirmed by direct read.
- **`ground_trapped` has no production reporter** — confirmed directly in `needs-mood-007`'s own
  Implementation Notes ("currently has no production reporter... exercised by mock until Villager AI
  reports it").
- **`needs-mood-009`'s stale `ticks_per_second = 2.0` real-time prose** remains uncorrected — the story is
  deferred to S11 pending D6(ii)'s cross-GDD authority question, exactly as carried from the Sprint 9
  sign-off. Not scheduled this sprint; still open.
- **Both pre-flight ruling documents** (`architecture-decisions-m02-preflight-2026-07-26.md`,
  `creative-decisions-m02-preflight-2026-07-26.md`) — **not independently re-checked this session**; no
  evidence found in any file read that either has been ratified since Sprint 9. Carried at the same posture
  the sprint plan itself assumed (proceed as if ratified).

---

## 5. The process story this sprint tells

Two structural findings matter more than any single story's test count:

**Third occurrence of "ship-green-and-uncalled."** `VoxelWorldGrid.generate_terrain()` (S9),
`Valley.spawn_starting_roster()` (S9), and now `NeedsMood.initialize_villager()` (this sprint, `scene-006`)
all shipped fully implemented, fully unit-tested, and callable from nowhere in production. Each was found
only when something actually *ran* the boot path, never by a test or a story-list review. `scene-006`'s own
story file names the rule this now establishes: *a new production API needs a proven caller in the same
sprint, or it is dead code with green tests.* The chosen countermeasure — a growing boot-invariant assertion
block plus a planning-time habit (confirm a caller story exists in the same sprint a public API lands) —
is proportionate and was reasoned about explicitly (a broad grep-for-every-public-method guard was
considered and rejected for exactly the reason this project's grep guards have misfired before: high
false-positive rate against legitimately-deferred APIs). Worth watching whether a fourth occurrence lands in
a **mid-session** path rather than at boot — the chosen guard does not cover that case by its own
admission.

**A parent misdiagnosis, corrected in the sprint record.** An early wiring attempt for `scene-006` was
reported as turning the suite red (18 errors, 1 failure) and was reverted on that basis. The producer later
re-applied the identical change and measured green (1307/1307, both suites) — the red run had contained
another lane's half-finished intermediate state in the same working tree, not a real defect in the change
being judged. This is a genuine process lesson, not a code lesson: **a suite run is only evidence about the
change under test if nothing else in the tree is mid-edit.** Three lanes converging on one crown (as this
sprint's own plan flagged as its defining structural risk) makes this exact failure mode more likely, not
less — a red run during a multi-lane sprint should be re-run in isolation (clean stash / separate branch)
before a change is reverted on its basis. Recommend this become an explicit habit for any future
three-lanes-into-one-crown sprint, not just a lesson learned this once.

**The recurring fixture trap bit a fourth agent.** Per the Sprint Result: the same "sealing a gap with a
solid block can create a legal step-up that reopens the escape" trap (hit independently twice in S09) was
hit again this sprint, but this time the agent recognized it from the briefing. That is the briefing
process working as intended — worth naming as a positive data point alongside the two findings above.

---

## 6. Full regression suite

Read from each story's own `Status` line and the final `build-validation-008` header, cross-checked for
internal consistency (see §1's monotonic sequence). **Not independently re-run by this session** — no
test-runner invocation was made in this review; the consolidated smoke artifact
(`production/qa/smoke-sprint-10-2026-07-27.md`) records the same figures as the authoritative snapshot for
hand-off, per every story's own self-reported "parent-verified" tag.

- **Final**: **1383 test cases, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans, exit code 0**
  (`build-validation-008`'s own header, matching the Sprint Result's closing figure).
- **Start of sprint**: 1198 (Sprint 9's parent-verified close) — not 1264 as the Sprint Result's opening
  line states; see §1.

---

## 7. Open bug list

**S1/S2 count: 0.** No `production/qa/bugs/*.md` files exist for this sprint. No new defect discovered this
sprint was left open across a story boundary — the one corrected misdiagnosis (§5) was resolved within the
same story session. This satisfies the DoD's "no open S1/S2" line, with the same process caveat Sprint 9's
sign-off recorded: none of this sprint's findings went through `/bug-report`, so there is no tracking-system
record of them outside story files and evidence docs.

---

## 8. Final verdict: **APPROVED WITH CONDITIONS**

The crown is real. Independent inspection of the actual test files — not the story files' own claims —
confirms `needs-mood-010` pairs a genuine, unmocked `NeedsMood` and `VillagerAi` at the one seam that matters,
against a genuinely real furniture/shelter chain; confirms `scene-006`'s non-vacuity is authentic and
time-based; and confirms `presentation-003`'s `_visual_position` guard is a real call-site allowlist. This is
strong, well-disclosed work, continuing the maturity pattern Sprint 9 set.

**Conditions, named concretely:**

1. **Correct the Sprint Result's own summary line.** "16/16 scheduled stories complete" should read 14/16,
   with `build-validation-009` and `building-009` (both Nice-to-have) explicitly named as not pulled — the
   correct outcome given D8's resolution, but the current wording overclaims. The opening suite figure
   ("1264 -> 1383") should read 1198 -> 1383.
2. **`build-validation-006`'s `is_need_functional` true branch remains unverified against a real item**,
   despite being a DoD line marked BLOCKING and despite `building-028` having landed. No bed resource exists
   in `data/` at all. This is correctly named in the Sprint Result's own text but must not be read as
   satisfied — it is a hard carry-forward to whichever sprint lands RID content authoring (`rid-008/009`).
3. **No `qa-plan-sprint-10-*.md` exists.** Produce one at the start of Sprint 11's planning, or explicitly
   record why the habit lapsed this sprint — the DoD listed it as a pre-implementation gate and it did not
   happen.
4. **Both pre-flight ruling documents remain unratified** — same posture as Sprint 9, carried again.
5. **The multi-cell furniture redo limitation** (§4.2) and **`bv-007`'s unasserted tick-source wiring**
   (§4.3) are real, named gaps — neither blocks this sprint's own scope, both should get an owning story or
   AC before they matter (before a second multi-cell item ships; before celebration pacing is relied on in a
   playtest, respectively).

---

## 9. Carry forward to Sprint 11

- **RID content authoring (`rid-008`/`009`)** — the real bed resource. Unblocks `build-validation-006`'s
  true branch, `build-validation-008`'s end-to-end bed warnings, and lets `needs-mood-010`'s crown be
  re-verified against a real RID item rather than a registry-placed one (follow-on, not required to re-open
  AC34's own verdict).
- **The C1 demolition chain** (`building-009 → 011 → 012 → 015`, then `017`) as S11's opener, per D8 option
  (c) — `building-017` also closes `needs-mood-010`'s currently-mocked bed-revocation edge case
  non-vacuously.
- **`build-validation-009`** — still externally gated on TD concurrence (CD Ruling 2's implementation form
  vs. the `@export RefCounted` collision). Unblock the decision before scheduling it again.
- **`needs-mood-009`** — the stale `ticks_per_second = 2.0` real-time-rate pass, pending D6(ii)'s cross-GDD
  authority question. Confirm authority or split the story before S11 scheduling.
- **Multi-cell furniture redo atomicity** (§4.2) — needs an owning AC before a second multi-cell item ships.
- **`bv-007`'s tick-source production-wiring assertion** (§4.3) — add an equivalent guard to
  `needs-mood-010`'s "exactly one call site" grep pattern if celebration pacing must reliably fire in the
  shipped game.
- **The Cluster D UI epics** (Building UI 18 stories + Villager Info UI 7 stories) — still no epics created;
  must happen before S11 planning closes, per the sprint's own repeated flag (third consecutive sprint
  carrying this).
- **Produce `qa-plan-sprint-11-*.md` at the start of Sprint 11**, closing this sprint's own process gap
  before it repeats a second time.
