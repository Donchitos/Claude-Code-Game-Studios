# Story 009: The payoff loop's last step, IN THE GAME — a villager claims a bed in a room it helped build, and sleeps in it

> **Epic**: Scene & World Management
> **Status**: BLOCKED on villager-ai story-024 (2026-07-27). Not started-and-abandoned — attempted, and the attempt found why it cannot be done yet.
> **Layer**: Core (integration / scene assembly) → produces Presentation evidence
> **Type**: Integration
> **Estimate**: **1.5 days** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*. Authored at gate G2 of Sprint 12; the sprint anchored 1.5 and authoring did **not** move it, but authoring surfaced one genuinely open mechanism question (§ Open Decision 1 — how the villager is brought to a **sheltered** sleep without the tool supplying simulation state) that could move it. See **Sizing and the descope ladder**.
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

---

## Context

### What the shipped game currently proves, and where it stops

`neues-spiel/tools/payoff_loop_demo.tscn` drives the **real** shipped build chain end to end
and produced `production/qa/evidence/01-before.png` … `05-furnished.png`. Read the tool, not
the report: `_run_demo()` ends at `await _attempt_furniture_stage(...)` and then
`get_tree().quit()`. **There is no claim stage and no sleep stage.**

> **The payoff loop is demonstrated as far as "house built, bed placed." That is all.**
> A villager claiming that bed and sleeping in it has been proven in
> `tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` and **never once in the
> running game.**

The tool is already honest about the gap — `_attempt_furniture_stage`'s last branch prints:

> *"REPORT — villager id=%d has NOT claimed a bed this run (needs a real Rest-need trigger
> this demo's timeframe did not necessarily reach — reported honestly, not assumed)."*

That line is the shape of this story: the tool knows what it did not observe, says so, and
stops. This story is what turns that report line into an observation.

### ⚑ Why this is a crown and not a nice-to-have

`scene-008` proved that **milestone criterion #5 was INERT in the shipped product for a whole
sprint while its test was green.** `Valley._wire_build_project_lifecycle()` constructed
`FurnitureBedProvider.new(furniture_registry, null)` — a null validation — so
`is_bed_sheltered()` structurally returned `false` for every bed in the shipped game, no
matter how perfect the room. The behaviour was real, covered, and green. The game simply
never asked the question.

That is the ninth of nine ship-green-and-uncalled defects on this project, and the sprint's
own retrospective is unambiguous: **a passing test proves code is correct; it cannot prove
code is reached.** The suite was green at 1383 before Sprint 11 and green at 1541 after, and
it was green *through* six live defects. Not one was found by a test.

**This story is how we find out whether criterion #5 is inert again.**

### Everything it needs already exists in the shipped scene — verified 2026-07-27

| Collaborator | Hosted by | Reached via |
|---|---|---|
| `BuildValidation` | `scene-008` (commit `7cedffa`) | `Valley.get_build_validation()` |
| `VillagerOnSiteGate` / `VillagerSealPreventionGate` | `scene-008` | `Valley.get_villager_onsite_gate()` / `…_seal_prevention_gate()` |
| `FurnitureRegistry`, `FurnitureBedProvider` | `scene-007` | `Valley.get_furniture_registry()` / `…_furniture_bed_provider()` |
| the whole build-tool + project-lifecycle chain | `scene-007` | `Valley.get_build_editor_mode()`, `…_commit_pipeline()`, `…_build_project_registry()`, `…_construction_job_queue()` |
| a camera | `cam-013` | `Valley.get_valley_camera()` |
| a sun and environment | `presentation-004` | `Valley.get_sun_light()` / `…_world_environment()` |
| the villager and its needs | `villager-ai-021`, `scene-006` | `Valley.get_villagers()`, `Valley.get_needs_mood()` |

**Nothing new needs hosting. This story adds no module.** It drives what is already there,
past the point the demo currently stops, and asserts what it observes.

**GDD**: `design/gdd/scene-world-management.md` (boot orchestration), `design/gdd/needs-mood-system.md`
(Core Rule 4 — the sheltered/unsheltered recovery multiplier), `design/gdd/villager-ai-behavior.md`
(bed claiming, Rule 7 mid-activity, the SLEEPING state), `design/gdd/build-validation-navigability.md`
(what makes a room sheltered)
**Requirement**:
- `TR-scene-world-management-004` / `-034` / `-035` / `-036` — the boot gate and the Valley as the structural parent; unchanged and must survive.
- `TR-needs-mood-system-025` — the live-pair integration requirement this story finally observes **in the product** rather than in a harness.
- `TR-building-system-102` / `-103` — the cell → owning-project reverse index that lets "the villager built this bed" be **proven**, not assumed.

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0005** (Boot Sequencing — the real `GameWorld` boot
this asserts against) — primary; **ADR-0016** (Build-Project Entity Lifecycle — how a cell
becomes built by worker-executed job, which is what makes "built by that villager" a
checkable fact) — primary; **ADR-0001** (DI) — secondary; **ADR-0009** (deterministic
movement/occupancy ordering — the villager's travel to its bed) — secondary.

**Engine**: Godot 4.7-stable | **Risk**: **MEDIUM** — no new module, no new API, no new
engine surface expected; the risk is entirely in **timing and observability** (getting a real
villager to a real *sheltered* sleep inside a wall-clock cap, without the tool supplying
anything the product should supply — § Open Decision 1).

**Control Manifest Rules (this layer — scene assembly + capture tooling):**
- **Required**: everything is driven through **hosted production paths only** — `Valley`'s
  own getters, `BuildEditorMode.arm_tool()` as the sole arming path, `CommitPipeline.commit()`,
  `BuildProjectRegistry.release_project()`, the real `ConstructionTickLoop` completion write.
  Screenshots go through the **shipped** `Camera3D` only.
- **Forbidden**: ⚑ **a tool may supply NOTHING the product is supposed to supply — no
  lighting, no cells, no props, no clock.** (Generalised from `presentation-004`'s AC6, which
  found three capture tools each hand-rolling the golden-hour recipe so the product could
  stay dark forever while every screenshot looked fine.) Specifically here: **never** a
  direct `VoxelWorldGrid` write, **never** a tool-supplied light or ground plane, **never** a
  tool-owned camera, **never** a fabricated bed or room, **never** a hand-written need value
  (§ Open Decision 1), **never** a second `setup()` call site (CONTRACTS.md §1).
- **Guardrail**: **an acceptance assertion that passes on today's build is not an
  assertion**, and **a picture that does not match its own report is worse than no picture**
  — the `05-furnished` precedent, where the tool skipped the shot rather than fake it.

---

## ⚑ Open Decision 1 — how the villager reaches a *sheltered* sleep, without the tool supplying simulation state

This is the one genuinely open mechanism in the story, and it collides head-on with the
sprint's tool-honesty rule. The villager must be **actually tired** — the tool may not make
it tired by fiat.

There is also a live design finding working against us. Sprint 12's **D10** (the hen-and-egg
pacing finding) states it plainly: *"the villager gets tired and goes to sleep **before** the
room that would let it sleep well exists … the villager's first sleep is therefore always the
**unsheltered** one."* So the naive shape — wait for the need to go urgent — is likely to
produce a sleep in the wrong place at the wrong time, and a `07-sleeping.png` of a villager
asleep in a field is not evidence of anything.

- **(a) Real decay, accelerated by the product's own time-warp.** `TimeTickSystem` ships
  `pause()` / `resume()` / `set_warp()` (story tick-003, TR-time-tick-system-023/024/039/040/045)
  — a **player-facing shipped feature**, one of `TimeTickConfig.time_warp_options`. Using it
  is the tool driving a product control, not the tool supplying simulation state. Decay,
  urgency, travel, claim and recovery all remain entirely the product's.
- **(b) The boot-seeded initial need value.** `scene-006` / `needs-mood-006`'s
  `NeedsMood.initialize_villager()` is the **production** path that sets a villager's starting
  needs at world genesis. Choosing a starting value that brings the first urgency after the
  room exists is a **product** decision surface, not a tool hack — but it changes what every
  boot does, so it belongs to design (and it is adjacent to D10(b)).
- **(c) The tool calls `NeedsMood.set_need_value()` directly.** ⚑ **REJECTED.** It is a public
  production API, but a *capture tool* writing a need value is exactly the banned shape: the
  tool supplying what the product supplies. It would let the demo produce a beautiful
  `07-sleeping.png` on a build where natural urgency never fires — the `presentation-004`
  failure mode, reproduced.

**Producer recommendation: (a), falling back to (b) if (a) cannot reach a sheltered sleep
inside the wall-clock cap — and (c) never.** Whichever is used, **the tool's report states
which, in the run output**, so the screenshot can never be read as claiming more than the run
did.

⚑ **And the D10 consequence must be handled, not designed around:** the villager may
legitimately have already taken an *unsheltered* sleep earlier in the run. That is real
product behaviour and the story must not suppress it. The assertion is about the **sheltered**
sleep — the one in the claimed bed, in the built room — and the report must distinguish the
two explicitly. *(D10 itself is a creative-director call and is **not** this story's to
decide; the producer recommendation there is (a) leave it, revisited after R8.)*

---

## Sizing and the descope ladder (pre-declared)

| Sub-scope | Contents | Anchor | Carries |
|---|---|---|---|
| **A — the headless proof in the real booted game** | claim + sheltered classification + ×1.0 recovery credit, asserted against the real `GameWorld`, plus the deletion probe | 1.0 | **The whole point.** This is what tells us whether criterion #5 is inert again |
| **B — the demo tool's claim and sleep stages** | the two new stages, their report lines, `06-claimed` / `07-sleeping` | 0.5 | The human-observable half, and the first time a person can *see* the loop close |

**Ladder if a trim is needed** (decide on signal, not by default):
1. **If `presentation-005` slips, ship B's stages and report lines but record the missing
   captures as a NAMED DEBT.** A `07-sleeping.png` showing a villager asleep in **thin air**
   — because the bed has no view layer — is not evidence. The sprint says this explicitly and
   the `05-furnished` precedent already does it: *honesty over a picture.*
2. **Never cut Sub-scope A.** Without it this story has not asked the question it exists to
   ask, and it must be reported as such rather than closed green.
3. **Never** let the tool fabricate a bed, a room, a light, a cell, or a need value to make a
   stage reachable. A stage that cannot be reached prints why and the tool moves on — the
   contract the tool already holds itself to.

---

## Acceptance Criteria

- [ ] **AC-CLAIM-STAGE-IS-REAL**: `tools/payoff_loop_demo.gd` gains a **claim stage** after
      its furniture stage. The villager claims the bed **through the hosted production path
      only** — the real `FurnitureBedProvider` the real `Valley` constructed, driven by the
      villager's own real need — and the stage reports the claimed cell, the claiming
      villager id, and the bed's owning project id. `06-claimed` is captured through the
      **shipped** camera. The tool claims nothing on the villager's behalf.
- [ ] **AC-SLEEP-STAGE-IS-REAL**: a **sleep stage** follows, observing the villager reach
      `VillagerAi.State.SLEEPING` **at its claimed bed cell**, with
      `NeedsMood.get_need_state(villager_id, &"sleep")` reading `RECOVERING`. `07-sleeping` is
      captured through the shipped camera. If the run does not reach a sheltered sleep inside
      its wall-clock cap, the stage **prints why and skips the shot** — never a picture that
      does not match its report.
- [ ] **AC-THE-BED-WAS-BUILT-BY-THAT-VILLAGER** ⚑ *what makes this the payoff loop and not
      just "a villager slept"*: the claimed bed's cells are owned by a project whose
      construction work was **credited to that same villager** — proven through
      `BuildProjectRegistry.project_at_cell()` and the job/claim record, not asserted from the
      demo's narrative order. ⚑ **`scene-008` made this checkable**: work is now credited only
      to a villager physically on site, so "that villager built it" is a fact the data can
      answer. [TR-building-system-102/-103, ADR-0016]
- [ ] **AC-SHELTER-IS-THE-HOSTED-VALIDATION'S-VERDICT**: the room is classified sheltered by
      the **hosted** `BuildValidation` — `Valley.get_build_validation()`, the instance
      `scene-008` wired into `FurnitureBedProvider` in place of the old `null` — and
      `is_bed_sheltered(claimed_cell)` reads `true` in the **real booted game**. ⚑ **This is
      the exact assertion that was structurally false for a whole sprint while its unit test
      was green.**
- [ ] **AC-RECOVERY-CREDITS-THE-SHELTERED-RATE**: the sleep recovers at the **×1.0 sheltered**
      rate, not the unsheltered multiplier. Asserted against
      `NeedsMoodConfig.unsheltered_bed_multiplier` **read live from the shipped config**
      (`0.7` today) — **never a literal `0.7` and never a literal `1.0`** — so a retune cannot
      make this assertion silently meaningless. The negative half is asserted too: an
      identical bed outside a sheltered room recovers at the unsheltered rate, so a naive
      "always sheltered" regression fails.
- [ ] **AC-ASSERTED-IN-THE-REAL-BOOTED-GAMEWORLD** ⚑ *the sprint's requirement, verbatim*: the
      assertions above run against a **real booted `GameWorld`** — not a harness, not a mock
      grid, not a hand-assembled `Valley`. The existing hosted modules are used through
      `Valley`'s own getters. A boot that HALTs never reaches any of this; existing halt
      semantics unchanged and still terminal. [ADR-0005]
- [ ] **AC-THE-RUN-IS-OBSERVABLE-IN-THE-TOOL'S-OWN-REPORT** ⚑ *the sprint's requirement,
      verbatim — "the lever must be observable in the demo tool's own report"*: the demo
      prints, in its own run output, (a) the claimed bed cell and claiming villager id,
      (b) the hosted `BuildValidation`'s shelter verdict for that cell, (c) the recovery
      multiplier actually credited, alongside the config's sheltered/unsheltered values, and
      (d) **which need-trigger mechanism the run used** (§ Open Decision 1). A reader of the
      log can tell, without opening a test file, whether the loop closed.
- [ ] **AC-THE-TOOL-SUPPLIES-NOTHING-THE-PRODUCT-SHOULD** ⚑ *generalised from
      `presentation-004` AC6, grep-guarded*: the tool performs **zero** direct
      `VoxelWorldGrid` writes (`set_cell` / `bulk_write` / `clear_cell`), constructs **zero**
      lights, environments, ground planes and cameras of its own, fabricates **zero** beds or
      rooms, and writes **zero** need or mood values. Every cell in the finished room and the
      bed reaches Voxel World data **only** via `ConstructionTickLoop`'s own real
      tick-driven completion write. The one sanctioned camera control remains the single real
      `CameraInput.set_target()` pan the tool already performs — never a raw transform write.
      Extend the tool's existing guard rather than writing a second one.
- [ ] **AC-D10-IS-REPORTED-NOT-SUPPRESSED**: if the villager took an earlier **unsheltered**
      sleep before the room existed, the report says so plainly and distinguishes it from the
      sheltered sleep this story asserts. ⚑ **That earlier sleep is the D10 hen-and-egg
      finding, which is a creative-director design question and NOT a defect** — it must not
      be tuned away, hidden, or worked around inside this story.
- [ ] **AC-CAPTURES-OR-A-NAMED-DEBT**: `06-claimed.png` and `07-sleeping.png` exist in
      `production/qa/evidence/` **and match their own report** — or their absence is recorded
      as a **named debt with the reason** in the commit body and the sprint smoke artifact.
      ⚑ **If `presentation-005` has not landed, the bed has no view layer and `07-sleeping`
      would show a villager asleep in thin air: skip the shot, name the debt.**
- [ ] **AC-NO-NEW-COLLABORATOR-IS-BOTH-OPTIONAL-AND-CONSEQUENTIAL** ⚑ *the sprint's deepest
      rule, applied even though this story hosts nothing new*: this story introduces **no**
      new injected collaborator. If implementation finds it needs one, that collaborator
      **asserts at boot or appears in Valley's boot-invariant block** — never a nil-safe
      optional whose absence quietly changes behaviour. **That is precisely the shape that
      made criterion #5 inert while green.**
- [ ] **AC-SUITE-GREEN-AND-DIAGNOSED**: the full blocking suite is green headless, 0 orphans,
      exit 0, both checked explicitly; E2E LOOP green. Any pre-existing test that changes is
      named individually in the commit body with its reason. A red run is re-run **in
      isolation** before any change is reverted on its basis (S10 §5), and never concurrently
      with a second suite.

---

## ⚑ Anti-Vacuity Lever

**Carried verbatim in substance from `sprint-12.md`'s Must table. It FAILS on today's build,
and its failure must be observed and recorded in the commit body** — the `scene-006` /
`scene-007` deletion-probe discipline, which `scene-007`'s own Deletion-Probe Record shows
the exact format for.

> **Remove the claim/hosting wiring once, re-run in isolation, and record the observed
> failure in the commit body.**
>
> **And the plain fact: no such capture has ever been produced, so `06` / `07` cannot exist
> on today's build.**

**The probe, named concretely so it is not improvised at implementation time.** Restore the
pre-`scene-008` condition in exactly one line and observe the failure:

- **Removal:** in `Valley._wire_build_project_lifecycle()`, pass `null` in place of the
  hosted `BuildValidation` when constructing `FurnitureBedProvider` — i.e. re-create the
  exact defect `scene-008` closed, one line, nothing else touched.
- **Expected observation:** `is_bed_sheltered(claimed_cell)` reads `false` in the real booted
  game, so **AC-SHELTER-IS-THE-HOSTED-VALIDATION'S-VERDICT fails** and
  **AC-RECOVERY-CREDITS-THE-SHELTERED-RATE fails** with the unsheltered multiplier credited.
  The villager still sleeps — which is exactly why the test must assert the *rate*, not the
  *sleep*.
- **Restore** byte-for-byte, confirm `git diff` clean, re-run green.

⚑ **The lever's two halves are both required, and they check different things.** The
deletion probe proves the assertion discriminates. The **capture** half proves the loop was
observed by a human at all: `06-claimed.png` and `07-sleeping.png` do not exist on today's
build and cannot, because the tool quits before the claim stage.

**A second, cheaper pre-story observation to record alongside it**: run today's
`payoff_loop_demo` unmodified and record its own honest line —
*"villager id=N has NOT claimed a bed this run"* — as the documented pre-story state. The
tool already tells us what it has never seen; quote it.

⚑ **Explicitly banned vacuous shapes here**: asserting the villager reached `SLEEPING`
(it does that today, unsheltered, per D10); asserting `get_owned_bed_cell() != null` as the
only evidence; asserting `Valley.get_build_validation() != null` (`scene-008` already
guarantees that and it proves nothing about the bed); comparing the recovery rate against a
literal `1.0` or `0.7`; and any assertion whose expected value does not change when
`BuildValidation` is unwired from the bed provider.

---

## Out of Scope

*Handled elsewhere, or surfaced as missing — do not implement here:*

- **The furniture view layer (F7).** `presentation-005` owns it. This story is **mechanically
  independent** of it — the coupling is evidence-only. If it slips, ship the headless proof
  and name the capture debt.
- **Any change to `BuildValidation`'s logic, either villager gate's rules, the bed-claim
  policy, the recovery ladder, or the construction tick loop.** All built, all green,
  `scene-008` hosted them. This story **drives** them. If any needs a change to be drivable,
  that is a finding to record and escalate, not a fix to make here.
- **⚑ D10 — the hen-and-egg pacing finding.** The villager gets tired before the room that
  would let it sleep well exists. **A creative-director design question, not a bug.** This
  story **reports** it (AC-D10-IS-REPORTED-NOT-SUPPRESSED) and must not retune it away.
  Producer recommendation on D10 remains *(a) leave it for MVP, revisit after R8* — and R8
  becomes schedulable at the end of this sprint for the first time.
- **The 19/30 construction plateau.** `spike-plateau` owns it, hard-time-boxed at 0.5, with a
  producer-supplied hypothesis (`villager-ai-016`'s livelock escape). ⚑ **If the plateau
  makes this story's room take longer than its wall-clock cap, that is a finding to hand the
  spike, not a cap to quietly raise.**
- **`bv-007`'s tick-source guard.** Tracked separately as a Must line item precisely because
  folding it into a DoD line has already failed twice.
- **Any new hosted module, any second `setup()` call site, any new boot phase.**
- **Save/load of claim or sleep state** (ADR-0012, VS-tier).

---

## QA Test Cases

- **AC-THE-BED-WAS-BUILT-BY-THAT-VILLAGER**: Given a real booted `GameWorld` where a room and
  a bed were built through the hosted chain by villager N, When the bed's cells are queried
  via `BuildProjectRegistry.project_at_cell()`, Then they belong to a project whose
  construction work was credited to villager N.
- **AC-SHELTER-IS-THE-HOSTED-VALIDATION'S-VERDICT**: Given that bed inside the enclosed built
  room, When `Valley.get_furniture_bed_provider().is_bed_sheltered(cell)` is asked in the real
  booted game, Then it is `true`. Given the same bed with the roof removed, Then `false`.
  **Negative control (run once by hand, recorded in the commit body):** with `null` passed in
  place of the hosted `BuildValidation`, this reads `false` and the test FAILS.
- **AC-RECOVERY-CREDITS-THE-SHELTERED-RATE**: Given the villager sleeping in the claimed,
  sheltered bed, When recovery is observed across ticks, Then the credited per-tick rate
  equals the base sleep recovery rate (×1.0), not that rate scaled by
  `NeedsMoodConfig.unsheltered_bed_multiplier` — both values read live from the shipped
  config. Given an unsheltered bed, Then the scaled rate is credited.
- **AC-ASSERTED-IN-THE-REAL-BOOTED-GAMEWORLD**: Given a headless boot of the real `GameWorld`
  with a `MockResourceItemDatabase` configured ready-immediately, When boot state first reads
  `ACTIVE`, Then every collaborator this story uses is reached through `Valley`'s own getters
  and none is constructed by the test. Given a RID `Failed` outcome, Then no `setup()` ran and
  the halt stays terminal.
- **AC-THE-TOOL-SUPPLIES-NOTHING-THE-PRODUCT-SHOULD**: Given `tools/payoff_loop_demo.gd`, When
  scanned, Then zero `set_cell` / `bulk_write` / `clear_cell` calls, zero light /
  `WorldEnvironment` / `Camera3D` constructions, zero `set_need_value` / `set_mood_value`
  calls, and zero fabricated bed or wall cells are found.
- **AC-CLAIM-STAGE-IS-REAL / AC-SLEEP-STAGE-IS-REAL /
  AC-THE-RUN-IS-OBSERVABLE-IN-THE-TOOL'S-OWN-REPORT**: Given a full demo run, Then the log
  contains the claimed cell, the claiming villager id, the hosted shelter verdict, the
  credited multiplier against the config's two values, and the need-trigger mechanism used;
  and either both captures exist and match those lines, or the log states why each was
  skipped.
- **AC-D10-IS-REPORTED-NOT-SUPPRESSED**: Given a run in which the villager slept unsheltered
  before the room existed, Then the report names that sleep separately from the sheltered one.
- **AC-SUITE-GREEN-AND-DIAGNOSED**: Given `tests/run-tests.cmd`, Then exit code 0 with 0
  errors, 0 failures, 0 orphans; E2E LOOP green.

---

## Test Evidence

**Story Type**: Integration (**BLOCKING** — integration test required, `coding-standards.md`
Test Evidence table)

**Required evidence**:

- `neues-spiel/tests/integration/scene_world/payoff_loop_claim_and_sleep_boot_test.gd` — a
  **new** file on `scene-006`/`scene-008`'s precedent (a new file rather than extending
  `gameworld_e2e_loop_test.gd`, because that file bundles one expensive real production boot
  into a single test; state the choice and its reason in the commit body). It carries:
  - ⚑ **THE ANTI-VACUITY LEVER's assertion half, against the REAL booted `GameWorld`**: the
    claimed bed is one built by that villager's own construction work; the room is classified
    sheltered by the **hosted** `BuildValidation`; recovery credits the **×1.0 sheltered**
    rate rather than the config's unsheltered multiplier — every expected value read live
    from the shipped configs, never a literal.
  - The negative halves (unsheltered bed → scaled rate; roofless room → not sheltered), so a
    naive "always sheltered" regression fails.
- Grep-guard test for AC-THE-TOOL-SUPPLIES-NOTHING-THE-PRODUCT-SHOULD, extending the tool's
  existing guard on the established non-writer-guard precedent (`building-023`,
  `build-validation-002`, and `shelter_recovery_live_pair_test.gd`'s `_find_files_assigning`
  helper — reuse it, it already generalises).
- ⚑ **THE DELETION PROBE, recorded in the commit body**, not a separate artifact: name the
  removed line (`FurnitureBedProvider`'s hosted `BuildValidation` argument in
  `Valley._wire_build_project_lifecycle()`), quote the observed failure verbatim (test name,
  the `false` shelter verdict, the credited unsheltered rate, statistics line, exit code),
  confirm the restore was byte-for-byte, confirm the re-run was green with `git diff` clean.
  **`scene-007`'s Deletion-Probe Record is the format to copy.**
- **The pre-story observation, in the commit body**: today's unmodified `payoff_loop_demo`
  run output, quoting its own *"has NOT claimed a bed this run"* line, plus the plain fact
  that `06-claimed.png` and `07-sleeping.png` do not exist.
- `production/qa/evidence/06-claimed.png` and `production/qa/evidence/07-sleeping.png` —
  **or a named debt with its reason**, per AC-CAPTURES-OR-A-NAMED-DEBT.
- **The § Open Decision 1 mechanism actually used, recorded in the commit body and in the
  tool's own report.**

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete, all verified 2026-07-27): `scene-007` (the hosted build-tool
  and project-lifecycle chain, plus `FurnitureRegistry`/`FurnitureBedProvider`), **`scene-008`**
  (the hosted `BuildValidation` and both villager gates — this story exists to check that
  fix stayed real), `building-017`, `rid-009` (real authored bed content with a typed `Mesh`
  `visual_asset`), `villager-ai-018` (bed claiming), `needs-mood-010` (the recovery ladder and
  the sheltered/unsheltered multiplier), `cam-013` (the shipped camera every capture goes
  through), `presentation-004` (the sun, so a capture shows anything at all).
- **Blocked on**: **nothing.** Day one on lane L. *(Soft, evidence-only: `presentation-005`
  for the captures — mechanically independent, see the ladder.)*
- **Unlocks**:
  - **Milestone criterion #5 becomes true IN THE PRODUCT rather than in a test** — or we find
    out it is inert again, which is the same value.
  - **R8, the external playtest** — schedulable for the first time at the end of this sprint.
    Its blocking condition was always the S10 smoke check's own gate: *"a villager visibly
    moving in and sleeping should be observed by a human at least once before any external
    playtest."* **This story is what makes that observation possible.**
  - Milestone criterion #6's human-observable half, jointly with `presentation-005`.
- **Open decisions this story surfaces (producer → user / creative-director)**:
  1. **The need-trigger mechanism** — § Open Decision 1. *Recommendation: the product's own
     time-warp (a), falling back to the boot-seeded initial need (b); never a tool-written
     need value (c).* **We will know this was right if** the run's report can name its
     mechanism and a reader agrees the product, not the tool, made the villager tired.
  2. **D10 — the hen-and-egg pacing finding** (creative-director). Reported by this story,
     decided elsewhere. *Producer recommendation: (a) leave it for MVP, revisit after R8 —
     deciding it now, before a human has played it, spends a creative decision on a guess.*

---

## Notes

- Cross-reference `docs/engine-reference/godot/` before touching any engine API
  (**BLOCKING**, as in M01 and S09–S11). This story is expected to use **no** new engine API;
  any that appears must be verified against the reference before use.
- ⚑ **The recurring fixture traps both apply here.** (1) The build-validation fixture trap bit
  agents in S11. (2) *"The world is not empty after boot"*: chunks lazily regenerate real
  terrain the moment residency is requested, so anything building geometry against a real
  booted grid must build above `base_height + amplitude` or probe for clear cells. ⚑ **And
  `vox-022` lands in this same sprint and changes what terrain generation produces — a fixture
  that assumes a single terrain block type will need re-reading.**
- ⚑ **`scene-008`'s three self-caught test defects are the traps to expect again**, and they
  are worth re-reading before writing a line: a fixture driving a `MockTimeTickSystem` while
  the hosted `ConstructionTickLoop` binds the real `TimeTickSystem` autoload (which made a
  test pass against a completely unfixed build — a vacuous test of exactly the kind this
  project keeps hunting); a fixture assuming the space above a written floor was empty; and a
  grep guard assuming `BuildValidation.new(` appears at all, when scene-hosted modules are
  never constructed in `src/`.
- **Take the captures last.** `scene-009` is mechanically independent of `presentation-005`,
  but its evidence is not — run the lanes in parallel and shoot `06`/`07` after the view layer
  lands.
</content>
</invoke>

---

## Blocked Note (2026-07-27) — the attempt is the finding

This story cannot be honestly completed today, and the reason is worth more than
the story would have been.

**A single villager cannot finish a wall.** Instrumented runs against the real
booted game — real WallTool, real commit pipeline, real tick loop, real gates,
one real villager — never reached full enclosure in ANY room shape, size or
build order tried. Construction plateaus at the topmost wall layer, every time.
Written up as `villager-ai/story-024-villagers-cannot-finish-a-wall.md`, marked
BLOCKING, because it breaks the game's core promise: draw a room, your people
build it.

Since scene-009's premise is that the villager sleeps in a bed inside a room
**it built**, hand-placing the walls to make the test pass would fake precisely
the thing under test. So the story waits.

**It also corrected Sprint 12's own plateau hypothesis.** `spike-plateau`
assumes seal-prevention refusals. The stuck cells are `PLANNED` with
`claimed_by_villager_id == -1` and `abandon_count == 0` — never claimed, so the
seal-prevention path is never consulted. The exclusion happens in job selection,
before any claim. The spike must be redirected or it will search the wrong
system for its whole time-box.

**Second finding, independent:** `is_candidate_interior_cell` requires a cell to
be roofed before it is even a Room candidate, and `payoff_loop_demo` builds walls
only, never a roof. Two separate reasons the demo's bed has never been sheltered.

**Third, a fixture rule now written down:** `BuildValidation.get_shelter_status()`
serves a cached snapshot refreshed by `_run_analysis_pass` (subscribed to
`cells_changed_batch`) or `run_load_pass`. `VoxelWorldGrid.set_cell` fires only
the singular `cell_changed`, so a directly-placed roof never reaches the cache.
Any fixture using `set_cell` must call `run_load_pass` afterwards.

**What exists and where:** the reproduction case is parked at
`production/qa/evidence/scene-009-reproduction-not-a-live-test.gd.txt` — as
evidence, deliberately not as a live test, because it fails and this project does
not land failing tests. Its bed-construction, claim and sleep stages all PASS
against the real hosted chain; only the shelter verdict fails, correctly.
`tools/payoff_loop_demo.gd`'s claim and sleep stages are written but were never
executed, so `06-claimed.png` and `07-sleeping.png` do not exist. That is a named
debt, not a silent gap.
