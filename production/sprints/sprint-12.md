# Sprint 12 — Working Days 111–120 (nominal anchor 2026-07-29) — THE SPRINT THE GAME BECOMES LOOKABLE

> **Sizing is in stories and sprint-sessions, not agent-days** (milestone-02 Notes). Per-story day
> figures below are **relative-complexity anchors, never calendar predictions.**
> Review mode: **lean** (`production/review-mode.txt`) — the PR-SPRINT feasibility gate is skipped.
>
> **S11 made the game reachable. S12 makes it legible.** Sprint 11 closed six instances of
> shipped-green-and-uncalled in one day: the build-tool chain, `FurnitureRegistry`, the camera, the
> world lighting, `BuildValidation`, and both villager work gates. The shipped game now has a camera,
> a sun, a hosted build chain, real authored items, a reverse verb, and work that is only credited to
> workers who showed up.
>
> **What it does not have is anything to look at.** The mesher knows exactly **one** terrain colour,
> a built bed is **invisible**, and the moment the whole milestone exists for — a villager claiming a
> bed in a room it helped build and sleeping there — **has never been observed in the running game**,
> only in an integration test.
>
> ⚑ **M02 has five sprints (S09–S13). This is the fourth. One sprint remains after this one.**

---

## ⚑ The two crowns

### Crown 1 — `vox-022` / `vox-023`: the world stops being one colour

Verified by direct source read on 2026-07-27, not inferred:

```gdscript
# src/voxel_world/voxel_world_grid.gd:262
const TERRAIN_BLOCK_TYPE_ID: int = 1          # the ONLY id generate_terrain ever writes (:637, :1783)

# src/voxel_world/voxel_world_mesher.gd:147
const DEBUG_BLOCK_COLORS: Dictionary[int, Color] = {
	1: Color("9CAD6E"),  # art-bible SS4.3 Lowland band -- Story 006's only terrain block-type id today
}
const DEBUG_UNKNOWN_COLOR: Color = Color(1.0, 0.0, 1.0)   # everything else renders magenta
```

**One id in, one colour out, hardcoded in a `const Dictionary`.** No palette work — none — can produce
a single pixel of visual variation in the terrain until the world generates more than one block type
and the mesher reads its appearance from data instead of a constant.

**This is the single biggest visual lever available**, and it is the one the **user personally owns**:
the project's asset and palette owner is actively mid-edit on `design/art/palette.json`,
`design/art/palette-system.md`, `design/art/palette_tables.md` and the palette PNGs **right now**.
Scheduling this first is not a preference; it is putting the lever in the hand that is already on it.

⚑ **And it unblocks a second thing, which is why it is sequenced before the lighting sign-off.**
`presentation-004`'s own closure note says the art bible's 1.7 / 0.5 lighting values *"blow the real
terrain out: the mesher's single terrain colour is the art bible's 9CAD6E lowland olive, which
renders near-white at those values."* **The shipped 0.95 / 0.28 is a number derived from a
placeholder.** Signing AC3 off against a one-colour world would ratify a value chosen to compensate
for the very thing this sprint fixes. **AC3 is therefore scheduled strictly after `vox-022`/`023`.**

### Crown 2 — `scene-009`: the last step of the payoff loop

`neues-spiel/tools/payoff_loop_demo.tscn` drives the **real** shipped build chain end to end and
produced `production/qa/evidence/01-before.png` … `05-furnished.png`. Read the tool, not the report:
it ends at `_attempt_furniture_stage(...)` and then quits. **There is no claim stage and no sleep
stage.**

> **The payoff loop is demonstrated as far as "house built, bed placed." That is all.**
> A villager claiming that bed and sleeping in it has been proven in
> `shelter_recovery_live_pair_test.gd` and **never once in the running game.**

That gap is exactly the shape of the nine defects this project has now hit: green, correct, and
unobserved in the product. Sprint 10's crown *was* inert in the shipped game for a full sprint and
nobody knew, because the test was green. **Closing this is how we find out whether it is inert
again.**

---

## ⚑ The anti-vacuity lever is mandatory on every story in this sprint

Sprint 11's retrospective is unambiguous: **a passing test proves code is correct; it cannot prove
code is reached.** The suite was green at 1383 before S11 and green at 1541 after, and it was green
*through* six live defects. Not one of them was found by a test — they were found by counting nodes
in the live scene tree, by booting the game and asking where everyone stands, and by reading a
screenshot against its own report.

**Every story below carries a named ANTI-VACUITY LEVER: a specific assertion that demonstrably FAILS
on today's build.** The lever must be written into the story file's own Test Evidence section, and
its failure on the pre-story build must be **observed and recorded in the commit body** — the
`scene-006` / `scene-007` deletion-probe discipline. A story whose lever passes before the story is
written has not been written.

**A story with no lever does not enter this sprint.** `/story-readiness` checks for it.

---

## Sprint Goal

**Give the world more than one colour, and finish the loop in the game rather than in a test.** Land
multi-block-type terrain generation and a data-driven block appearance table (`vox-022` → `vox-023`)
so the project's palette owner finally has a surface to paint. In parallel give furniture a view
layer (`presentation-005`) so a built bed can be seen at all, and close the payoff loop's last step
(`scene-009`) — a villager claims a bed in a room it helped build and sleeps there, observed in the
shipped game and photographed. Diagnose the 19/30 construction plateau before anyone mistakes it for
a performance problem. Pay the two S11 debts that lapsed (`bv-007`'s wiring guard, the
`sprint-status.yaml` back-fill). Take the four decisions that have now blocked work for two, three,
four and five sprints — or drop the stories they block from the plan rather than schedule them a
fourth time.

## Capacity

- **Measured cadence** (S1–S11): 8, 9, 9, 8, 8, 13, 12, 13, 18, 14, **18** stories/session.
  **15 items is inside the band** and matches S11's shape exactly.
- **Total:** 10 nominal days · **Buffer (20%): 2 days**, pre-committed to two named consumers:
  1. **PRIMARY — `vox-022`.** The **first change to terrain generation since `vox-006`**, touching
     `VoxelWorldGrid`'s packed chunk storage (`block_type_ids: PackedByteArray`) and, potentially,
     the on-disk region-file format that ADR-0015's paged residency reads. Adding ids to a byte array
     is cheap; **changing what an already-serialized region file means is not.**
     **Named lever:** if the storage/format question proves load-bearing, **reduce the design scope —
     ship 2–3 height-banded ids rather than a biome system — never the data-driven-ness.** A
     hardcoded three-colour table is the same defect as a hardcoded one-colour table.
     Escalate a format question to technical-director; do not invent a migration.
  2. **SECONDARY — `scene-009`'s authoring.** Its file does not exist. `scene-007`'s estimate rose
     **1.0 → 2.0 during authoring**, and authoring is where the `FurnitureRegistry` instance was
     found. Budget for the same.
- **Available:** 8 days. **Committed:** Must 6 items = 6.25 · Should 6 = 3.0 · Nice 3 = 2.0.
- **Longest Must lane = 2.5** (lane T). **Throughput is not the binding constraint.** The binding
  constraints, in order: (1) **three story files that do not exist yet**, (2) **the terrain work needs
  design input from the palette owner**, (3) **five unmade decisions**, two of which have blocked the
  same two stories for three and two sprints.

### Parallel-lane capacity model

| Lane | Owner | Must sequence | Must lane-days |
|---|---|---|---|
| **T — terrain & appearance (crown 1)** | `godot-gdscript-specialist` | `vox-022` → `vox-023` | 2.5 |
| **V — the view layer** | `godot-specialist` | `presentation-005` | 1.5 |
| **L — the loop's last step (crown 2)** | `godot-specialist` | `scene-009` | 1.5 |
| **S — the spike** | `ai-programmer` | `spike-plateau` | 0.5 |
| **G — lapsed debts** | `ai-programmer` | `bv-007-guard` | 0.25 |
| **Doc** | `systems-designer` | *(Should)* `needs-mood-009` — **only if D6(ii) is ruled at Day 0** | 0 Must |
| **Art** | `art-director` / user | *(Should)* AC3 + golden-hour re-shoot + CD close | 0 Must |

**No cross-lane convergence, and no serial chain deeper than 2** — the deliberate contrast with S11's
depth-5 lane C. The one soft coupling is stated below and it is a *sequencing* coupling, not a
dependency: `scene-009` is mechanically independent of `presentation-005`, but **its 06/07
screenshots are meaningless without it** — a villager visibly sleeping in thin air is not evidence.
Run them in parallel; take the captures last.

## ⛔ Day-0 gates (all three close before the first `/dev-story` on any lane)

| # | Gate | Owner | Why it is a gate, not a task |
|---|---|---|---|
| **G1** | **`/qa-plan sprint` → `production/qa/qa-plan-sprint-12-*.md`** | qa-lead | It was a gate in S11 **and it held** — the plan existed before any lane started, after S10's identical DoD line was ignored entirely. Keep what worked. Do not demote it back to a DoD line. |
| **G2** | **Author `vox-022`, `vox-023` and `scene-009`** | producer *(design input: art-director + user for bands/palette; TD for storage format and the furniture render mechanism)* | Three of the sprint's four Must stories **have no file on disk.** This is the same gate shape as `scene-007` in S11 and `presentation-003` in S10 — both times the gate worked, and both times authoring surfaced something the plan had not priced (`scene-007`: +1.0 day and a fifth uncalled construction site). **Each authored story must carry its anti-vacuity lever in its own Test Evidence section**, then `/story-readiness`. **Invent no design**: bands and materials come from the art bible's SS4.3 height bands and the user's palette, not from the producer. |
| **G3** | **Record hygiene back-fill** | producer | Three concrete, verified record defects, all cheap, all of which will corrupt a later count if left: **(a)** the five S11 mid-sprint additions (`cam-013`, `presentation-004`, `villager-ai-022`, `scene-008`, `build-validation-009`) were **never entered in `sprint-status.yaml`** — a DoD line that has now failed twice, so it becomes a gate; **(b)** `production/epics/villager-ai-behavior/` contains **two files numbered `story-022`** — renumber one; **(c)** `presentation-001`'s own `Status` header still reads *"Sub-scope A Complete … Sub-B awaits villager-ai-019"* although Sub-B landed — correct it, including the flagged scope gap. |

**Also due at S12 start, per the milestone's own Review Schedule:** *"Cluster D go/no-go + CD check on
protected items (Cluster B)."* See **D3** and **D12**.

## Tasks

### Must Have (the two crowns, the view, the spike, the lapsed debt)

| ID | Task | Story File | Agent/Owner | Est. | Dependencies | Acceptance Criteria + ⚑ ANTI-VACUITY LEVER |
|----|------|-----------|-------------|------|-------------|--------------------|
| **vox-022** | **⚑ CROWN 1a — Multi block-type terrain generation.** The world stops being one material | *(to be authored, G2)* `production/epics/voxel-world/story-022-multi-block-type-terrain-generation.md` | godot-gdscript-specialist | 1.5 | `vox-006` ✓, `vox-002` ✓, `vox-010` ✓ (all Complete). **Blocked on nothing** — day one on lane T | `generate_terrain` and the lazy per-chunk regeneration path (`voxel_world_grid.gd:1760`) both emit **more than one** `block_type_id`, selected by the art bible's SS4.3 height bands — **the same rule in both paths, expressed once**, never two copies that can drift. Ids stay inside the packed-byte range 0–255 (the existing `set_cell`/`bulk_write` assertions). ⚑ **The region-file question is explicit, not discovered**: state in the story whether already-serialized region files remain readable, and if not, escalate the format call to TD rather than inventing a migration. ⚑ **LEVER — FAILS TODAY:** *generate a chunk column spanning the full height range and assert **≥ 2 distinct non-empty `block_type_id` values** are present* (target ≥ 3). Today `TERRAIN_BLOCK_TYPE_ID = 1` is the only id written anywhere, so this assertion fails on the current build. **Record the observed failure in the commit body.** |
| **vox-023** | **⚑ CROWN 1b — Block appearance becomes DATA.** The mesher stops holding a hardcoded colour dict | *(to be authored, G2)* `production/epics/voxel-world/story-023-data-driven-block-appearance-table.md` | godot-gdscript-specialist | 1.0 | **`vox-022` (in-sprint, HARD — colouring one id differently is vacuous)** | `voxel_world_mesher.gd`'s `const DEBUG_BLOCK_COLORS` is replaced by a **config Resource**, following `world_lighting_config.tres`'s landed precedent from `presentation-004` (*"the recipe is a config Resource, not literals — grep-guarded — so the values are tunable data like everything else here"*). `DEBUG_UNKNOWN_COLOR` magenta is **retained** as the visible-fail path for an unmapped id — this project's "visible fail, never silent" rule. ⚑ **The user must be able to change a terrain colour by editing data and nothing else.** ⚑ **LEVER — TWO, both FAIL TODAY:** (1) *grep-assert zero hardcoded block colours in `src/voxel_world/`* — fails against `voxel_world_mesher.gd:147`; (2) *assert the mesher renders **zero** `DEBUG_UNKNOWN_COLOR` faces for **every** id `vox-022`'s generator can emit* — fails the instant `vox-022` emits id 2 against today's one-entry table |
| **presentation-005** | **Furniture view layer (F7) — a built bed becomes visible.** Deferred once already | *(to be authored, G2 — or `/create-stories`)* `production/epics/presentation-experience/story-005-furniture-view-layer.md` | godot-specialist | 1.5 | `building-016` ✓, `building-028` ✓, `rid-009` ✓ (`visual_asset` is already a typed `Mesh` on every entry), `scene-007` ✓ (`FurnitureRegistry` is now hosted, `valley.gd:1005`). **Blocked on nothing** | A placed/completed furniture item gains a world-space view, **hosted in `Valley` and reported through `get_injected_tier_modules()`** — the only landed hosting precedent, the same one `presentation-003`'s `VillagerBodyPresenter` and `scene-007` followed. It **reads** the registry's placed/removed signals and **never writes** — BV-1's prohibition on furniture reaching the voxel grid is exactly what makes `build-validation-002`'s transparency guarantee true by construction and **must survive untouched** (grep-guard it, as Sub-B did). Consumes `rid-009`'s `visual_asset` `Mesh` directly. ⚑ **The TD render-mechanism call (MultiMesh vs per-item `MeshInstance3D`) is named in D11 — but it is NOT a blocker**: the landed precedent is a per-entity presenter, and following it needs no new ruling. Take the ruling if it arrives; otherwise follow precedent and record the choice. ⚑ **LEVER — FAILS TODAY, and it is a LIVE-TREE COUNT, the technique that found `cam-013`:** *boot the real `GameWorld`, complete a bed through the real chain, then **count the furniture view nodes in the live scene tree** and assert exactly the footprint's worth.* **Today that count is zero** — `src/presentation/` contains no furniture presenter and zero references to furniture (verified 2026-07-27) |
| **scene-009** | **⚑ CROWN 2 — The payoff loop's last step, IN THE GAME.** A villager claims a bed in a room it helped build, and sleeps in it | *(to be authored, G2)* `production/epics/scene-world-management/story-009-payoff-loop-claim-and-sleep-in-the-shipped-game.md` | godot-specialist | 1.5 | `scene-007` ✓, `scene-008` ✓, `building-017` ✓, `rid-009` ✓, `villager-ai-018` ✓, `needs-mood-010` ✓. **Blocked on nothing.** *(Soft: `presentation-005` for the captures only — see the note above)* | Extend `neues-spiel/tools/payoff_loop_demo.gd` past its furniture stage with a **claim stage** and a **sleep stage** (`06-claimed`, `07-sleeping`), driven **only** through hosted production paths — the tool's existing contract holds absolutely: **it never writes a cell, never supplies lighting, never stages a prop, and it stops honestly rather than shooting a picture that does not match its own report.** Alongside the tool, a headless integration assertion in the **real booted `GameWorld`** (not a harness) that the claimed bed is one **built by that villager's own construction work**, that the room is classified sheltered by the **hosted** `BuildValidation`, and that recovery credits the **×1.0 sheltered** rate rather than ×0.7. ⚑ **Why this is a crown and not a nice-to-have: `scene-008` proved that criterion #5 was INERT in the shipped product for a whole sprint while its test was green** (a null validation made `is_bed_sheltered()` false for every bed). This story is how we find out whether it is inert again. ⚑ **LEVER — FAILS TODAY:** *remove the claim/hosting wiring once, re-run in isolation, record the observed failure in the commit body* — the `scene-006`/`scene-007` deletion probe, verbatim. **And the plain fact: no such capture has ever been produced, so `06`/`07` cannot exist on today's build.** |
| **spike-plateau** | **The 19/30 construction plateau — time-boxed diagnosis.** ⚑ **A SPIKE, not a fix** | *(spike — deliverable is a written finding, not a feature)* | ai-programmer | 0.5 **HARD TIME-BOX** | `scene-008` ✓ (it is what surfaced the plateau) | After `scene-008`, `payoff_loop_demo` plateaus at **19/30 wall cells for ~180 s**. `scene-008`'s own commit flagged it honestly as *"most likely the villager cycling through seal-prevention refusals as the room closes around it — expected gate behaviour, not investigated, flagged so nobody reads it as a performance problem."* ⚑ **PRODUCER-SUPPLIED HYPOTHESIS, verified on disk at S11 close and NOT in the original note:** `villager-ai-016` (*"Seal prevention negative-write gate **& livelock escape** (F6)"*) is **Complete since 2026-07-25** and ships an escape hatch — *"once `abandon_count >= seal_prevention_abandon_limit`, `allow_write` flips true; the villager becomes sealed and the watchdog rescues it."* **A 180 s stall means either the escape is never reached in the shipped game, or the limit is large relative to the demo's cap.** Both are worth knowing; the first is a defect in a system marked Complete. ⚑ **DELIVERABLE, and the acceptance bar: reproduce the plateau at least once and record the observed `abandon_count` and `seal_prevention_abandon_limit` values at the stall.** Then exactly one of: **(a)** a defect story with a failing test, **(b)** a written "expected behaviour" ruling with the tuning rationale, or **(c)** "not reproduced — closed". ⚑ **Explicitly NOT a performance investigation.** ⚑ **STOP AT THE BOX.** If 0.5 is spent without a reproduction, write that down and stop — do not convert a spike into an open-ended debug |
| **bv-007-guard** | **`BuildValidation` tick-source production-wiring guard.** ⚑ **A DoD line that has now LAPSED TWICE** | *(task, tracked — deliberately NOT folded into a DoD line a third time)* | ai-programmer | 0.25 | `scene-008` ✓ (which finally gave `BuildValidation` a production `setup()` call at all) | Sprint 10's sign-off §4.3 asked for it; Sprint 11 folded it into the DoD as *"~0.1 day"* and **it did not happen.** Verified 2026-07-27: `build_validation.gd:348` self-wires from `/root/TimeTickSystem`, but **that code landed in S10 (`f61d1b3`)** and **no test pins it** — and until `scene-008` landed, `setup()` was never called in production, so the self-wire never ran in the shipped game either. ⚑ **This is the ninth-instance failure mode in miniature: a nil-safe optional field whose absence silently freezes celebration pacing at tick 0.** ⚑ **LEVER — FAILS TODAY:** *assert **exactly one** production call site wires the tick source (the `needs-mood-010` grep pattern), and that `_tick_count` **advances** in a booted `GameWorld`* — remove `scene-008`'s hosting once and record the failure. **Tracked as a Must line item precisely because "folded into the DoD" has already failed it twice** |

### Should Have (the sign-offs the sprint unblocks, and the decision-gated work)

| ID | Task | Story File | Agent/Owner | Est. | Dependencies | Acceptance Criteria + ⚑ LEVER |
|----|------|-----------|-------------|------|-------------|--------------------|
| **presentation-004 AC3** | **Art-director sign-off on the provisional lighting values 0.95 / 0.28.** ⚑ **Sequenced strictly AFTER `vox-022`/`023`** | `production/epics/presentation-experience/story-004-world-lighting-and-environment-hosting.md` (open AC on a landed story) | art-director *(user)* | 0.5 | **`vox-022` + `vox-023` (in-sprint, ORDERING — not a stated dependency, a correctness constraint)** | ⚑ **THE ORDERING IS THE POINT, and it is this plan's own finding.** `presentation-004`'s closure note says the art bible's own 1.7 / 0.5 *"blows the real terrain out: the mesher's single terrain colour is the art bible's 9CAD6E lowland olive, which renders near-white at those values."* **0.95 / 0.28 is a value chosen to compensate for a one-colour placeholder world.** Signing it off before the terrain has real materials ratifies the workaround. ⚑ **Acceptance: the sign-off is recorded against a windowed capture of MULTI-COLOUR terrain, and states explicitly whether 0.95 / 0.28 survived, changed, or moved back toward the art bible's 1.7 / 0.5.** Overturning is a `.tres` edit — the story made sure of that. **A sign-off recorded against a one-colour capture does not close this AC** |
| **presentation-004 deviation** | **The rendered-luminance proof still owed** | same story file | godot-specialist | 0.25 | `presentation-004` ✓ | `presentation-004` recorded its own deviation rather than glossing it: the lever asked for luminance measured on **rendered** output; what shipped is a **computed Lambertian estimate**. It was shown to discriminate (shipped values inside the band, 1.7/0.5 over, near-zero under) — but it is not what was written. ⚑ **Either produce the rendered measurement, or formally retire the requirement with a written rationale** (`coding-standards.md` does exclude visual fidelity from automation, so retiring it is a legitimate outcome). **What is not acceptable is leaving it recorded-as-owed for a second sprint** |
| **crit-9-close** | **Criterion #9's written, dated CD close entry — and criterion #8's golden-hour re-shoot** | evidence: `production/qa/evidence/ambient-life-wave-1-evidence.md` | creative-director *(qa-lead facilitates)* | 0.5 | `villager-ai-019` ✓, `presentation-001` Sub-B ✓ (both landed S11) | ⚑ **Both prerequisites for criterion #9 landed in S11 and the criterion still did NOT close** — the evidence doc reads *"awaiting art-director/creative-director review"*. Criterion #9 is met **only on a written, dated CD close entry**, never on a green suite. **This is a signature, not work.** ⚑ **And the golden-hour re-shoot is now MANDATORY rather than advisory, which is new**: `presentation-004`'s AC6 made all three capture tools stop supplying lighting, so **every golden-hour capture this project has ever produced was shot under tool light that no longer exists.** Re-shoot against the real sun. The other three CD advisories (foliage hue, torch colour, Dusk/Horizon tests) stay explicitly outstanding if unresolved — **do not let this session silently absorb them as closed** |
| **needs-mood-009** | **Real-time-rate pass at `ticks_per_second = 4.0` (criterion #4).** ⛔ **D6(ii)-gated — THIRD sprint** | `production/epics/needs-mood-system/story-009-real-time-rate-pass.md` (`Status: Ready`) | systems-designer | 1.0 | In-epic deps `002`/`003`/`005`/`008` all ✓. ⛔ **EXTERNAL: D6(ii)** | Unchanged in scope from S11 (see `sprint-11.md` for the full AC set and F8's self-contradiction). ⚑ **NEW SCHEDULING RULE, and it is a change: if D6(ii) is not ruled by the close of Day 0, this story is DROPPED FROM THE PLAN — not carried a fourth time.** It has consumed planning attention across three sprints while never once being workable. **Hard guard unchanged: no `.tres` edit, no AC anchor move, no test edit. A config diff means the ruling was not followed.** ⚑ **LEVER:** `config_pacing_anchor_test.gd` must **fail** if a future retune silently changes the shipped anchor without updating the sweep |
| **villager-ai-020** | **Breather beat — unblocked by `villager-ai-013` landing** | `production/epics/villager-ai-behavior/story-020-breather-beat.md` (`Status: Ready`) | ai-programmer | 0.5 | **`villager-ai-013` ✓ (landed S11 — this was its named in-sprint consumer)** | Cluster B is **CD-protected**; cutting it needs CD sign-off. `013` was scheduled in S11 partly *because* `020` depends on it; landing `013` and then never pulling `020` would waste that reasoning. ⚑ **LEVER:** deterministic under the tick contract — assert **zero** wall-clock reads (`OS.get_ticks_msec` / `Time.get_ticks_msec`) anywhere on the decision path, per ADR-0009 |
| **rid-008-ac31a** | **Verify or retire `rid-008`'s AC31a** | `production/epics/resource-item-database/story-008-furniture-footprint-validation.md` | godot-gdscript-specialist | 0.25 | `rid-008` ✓, `rid-009` ✓ (real content now exists to test against) | `rid-008` shipped with AC31a *"documented as structurally unreachable"* — a missing `footprint` on a `furniture_fixture` cannot occur because the `@export` carries a default. ⚑ **An acceptance criterion that cannot fail is not an acceptance criterion.** Now that real content exists, either **construct the unreachable state** and prove the halt, or **formally retire AC31a** with the structural argument written into the story file. Do not leave it as a passing-by-impossibility line |

### Nice to Have (pull only if lanes T, V and L clear)

| ID | Task | Story File | Agent/Owner | Est. | Dependencies | Acceptance Criteria + ⚑ LEVER |
|----|------|-----------|-------------|------|-------------|--------------------|
| **building-ui-001** | **HUD host scaffold — Cluster D's first stake (criterion #10).** ⛔ **TD-HUD-ruling-gated — SECOND sprint** | `production/epics/building-ui/story-001-hud-host-scaffold.md` (`Status: Ready`) | godot-specialist | 1.0 | `building-001` ✓. ⛔ **EXTERNAL: the TD hosting ruling (building-ui KC1/KC3)** | ⚑ **`scene-007` already answered this exact architectural question for the tool tier, and landed**: `Valley` hosts and reports through `get_injected_tier_modules()`; `GameWorld` calls `setup()`. *Decide once, apply twice* was the S11 recommendation — half of it is now shipped precedent. ⚑ **Same new rule as `needs-mood-009`: if the ruling is not in hand by the close of Day 0, this is DROPPED, not carried a third time.** ⚑ **LEVER:** grep-assert the HUD writes **no** simulation state — zero `VoxelWorldGrid.set_cell`/`bulk_write`/`clear_cell`, zero config-field writes. Note `src/ui/` does not exist; this epic starts from zero (KC1, recorded, not a defect) |
| **building-027** | **Block remove-mode routing — criterion #11's one remaining wording question** | `production/epics/building-system/story-027-*.md` | godot-specialist | 0.5 | `building-009` ✓, `building-015` ✓ (both landed S11) | Criterion #11 names *"worker-executed block demolition with `restore_value` write-back, the removal tool, the draft eraser branch, **and block remove-mode**."* The first three landed. ⚑ **First establish whether `building-015` already satisfies the remove-mode wording** — `building-031` turned out to be fully absorbed by `015`, and the same may be true here. **Verify AC-by-AC before writing any code**, exactly as `031`'s closure did. If satisfied, close it as absorbed and record the verification; if not, ship the gap only |
| **crit-13-authoring** | **Author the mid-range hardware baseline story (criterion #13).** ⛔ **FIFTH consecutive sprint blocked on two unowned TD decisions** | *(does not exist — voxel-world ends at `story-021`, and this sprint adds `022`/`023`)* | producer, once TD decides | 0.5 | ⛔ **EXTERNAL: target hardware class + VSync mode, both technical-director, both still unowned** | ⚑ **Criterion #13 is PROTECTED — it is never on the cut lever — so an unowned decision here cannot be traded away. It converts one-for-one into milestone risk, and M02 has ONE sprint left after this one.** `vox-018`'s measurement tool is reusable verbatim (windowed, culling ON, VSync OFF for true compute). **The story cannot be authored until the hardware class exists.** This is the fifth consecutive sprint making the request — see **E1** |

## Critical Path

```
lane T   vox-022 ─→ vox-023 ─────────────────────→ [presentation-004 AC3]   (ordering, not dependency)
lane V   presentation-005 ────────────────┐
                                          ↓  (captures only — NOT a mechanical dependency)
lane L   scene-009 ───────────────────────┴────→ 06-claimed / 07-sleeping
lane S   spike-plateau      (0.5, hard time-box)
lane G   bv-007-guard       (0.25)
lane Doc [needs-mood-009]   — only if D6(ii) ruled at Day 0
lane Art [crit-9 CD close + golden-hour re-shoot]
```

- **Longest Must lane: T, depth 2** (`vox-022 → vox-023`), ~2.5 lane-days of 8 available.
  **Deliberately the opposite shape of S11**, whose lane C was depth 5 and where a slip at
  `building-009` would have pushed four stories. Nothing here pushes more than one.
- **Four Must items start day one, blocked on nothing:** `vox-022`, `presentation-005`, `scene-009`,
  `spike-plateau`.
- ⚑ **The one coupling worth restating: `scene-009` is mechanically independent of
  `presentation-005`, but its evidence is not.** A `07-sleeping.png` showing a villager asleep in
  thin air is not evidence of anything. **Take the captures after the view layer lands** — and if the
  view layer slips, `scene-009` ships its headless proof and **records the missing capture as a named
  debt**, rather than shooting a picture that does not match its own report. That is the
  `payoff_loop_demo` precedent: *honesty over a picture*.
- **The S10/S11 tree-hygiene rule still applies**: a suite run is only evidence about the change under
  test if nothing else in the tree is mid-edit. ⚑ **Specific to this sprint: the user's asset/palette
  lane (`design/art/palette.json`, `palette-system.md`, the vegetation `.glb` models,
  `tools/asset-pipeline/`) is actively uncommitted right now.** It touches no `.gd` and no `src/`, so
  it does not poison a suite run — **but `vox-023` will land in the same area conceptually. Coordinate
  the palette hand-off explicitly rather than discovering a conflict.**

**Recommended trim order, if one is needed** (decide mid-sprint, on signal):
1. **`crit-13-authoring` (Nice)** — only because it is TD-blocked anyway. **Trimming it is not a
   scope decision, it is an unmade decision showing up as one. Escalate, do not absorb.**
2. **`building-027` (Nice)** — may prove already-absorbed and cost nothing.
3. **`building-ui-001` (Nice)** — but read **D3** first; this is the story the Cluster D signal is
   measuring.
4. **`rid-008-ac31a` / `presentation-004 deviation` (Should)** — small debts; slipping them one
   sprint is honest, slipping them two is a pattern.
5. **Never trim**: `vox-022`/`vox-023` (the sprint's reason to exist and the user's own lever),
   `scene-009`, `presentation-005`, `bv-007-guard` (twice-lapsed), the spike's time-box, or
   `/team-qa sprint` + the consolidated smoke artifact.

## Carryover from Sprint 11

| Item | Reason | New Estimate |
|---|---|---|
| **`needs-mood-009`** | **Decision-blocked on D6(ii), not capacity-trimmed. Third sprint.** New rule: ruled by Day 0 or dropped from the plan | 1.0 (Should) |
| **`building-ui-001`** | **Decision-blocked on the TD HUD ruling, not capacity-trimmed. Second sprint.** `scene-007` shipped the precedent for the same question. Same new rule | 1.0 (Nice) |
| **`presentation-004` AC3** | Deliberately left open at S11 close; values ship provisional. **Now correctly sequenced after the terrain work** | 0.5 (Should) |
| **`presentation-004`'s rendered-luminance deviation** | Recorded honestly at landing, still owed | 0.25 (Should) |
| **`bv-007`'s tick-source guard** | **S10 sign-off §4.3 → S11 DoD "~0.1 day" → not done.** Promoted from a folded DoD line to a **tracked Must item** because folding has failed it twice | 0.25 (Must) |
| **Criterion #9's CD close + criterion #8's golden-hour re-shoot** | Prerequisites landed S11; the signature did not. Re-shoot is newly mandatory because tools stopped lighting | 0.5 (Should) |
| **Furniture view layer (F7)** | Deferred out of S11 on stated grounds. **Verified still absent 2026-07-27.** Now a Must — it blocks criterion #6's human-observable half **and R8 for a second sprint** | 1.5 (Must) |
| **`presentation-001` Sub-B's scope gap** | Decision owed to producer/CD — see **D12**. Not schedulable as work until decided | — (decision) |
| **`sprint-status.yaml` back-fill + the two record defects** | DoD line failed twice → **Day-0 gate G3** | 0.25 (G3) |
| **Criterion #13 / hardware class / VSync** | **Fifth sprint unowned.** Protected criterion — pure milestone risk | 0.5 (Nice, TD-gated) |
| **Multi-cell furniture REDO atomicity** | **Correctly still deferred** — its named trigger (a second multi-cell item) has not fired. The bed remains MVP's only multi-cell item. Not scheduled, not forgotten | — (deferred) |
| **Criterion #2's reachability corpus** | **HELD, unchanged, and must not be silently upgraded.** Wording stays: *"5,000-verdict spec not yet met; the 1,000-verdict shipped configuration is 0/0 disagreement."* The S09 `nav_region_size` 200→40 retune (6697.6 ms → 266.6 ms) remains the un-actioned TD lever on density | — (deferred) |
| **R8 — external playtest** | **Becomes schedulable at the END of this sprint, for the first time.** It was blocked on F7 (invisible bed) and F6 (unhosted tools); F6 closed in S11 and F7 closes here. See **Dependencies** | — (end of S12) |
| **Both pre-flight ruling documents** | Unratified, **fourth sprint**. User-owned signature. Not schedulable work | — |

## Milestone-Criteria Advancement Map (what this sprint moves)

| # | Criterion | S12 disposition |
|---|-----------|----------------|
| #1 | Build Validation implemented | **MET (9/9, S11).** No stories this sprint. |
| #2 | Reachability corpus ≤ 60 s in CI | **HELD, unchanged.** ⚑ Do not let a concurrent-suite CPU-starvation artifact be read as a real breach of the 60 s ceiling — that is a load artifact and **must never be "fixed."** |
| #3 | Needs & Mood implemented | MVP-complete since S10. |
| #4 | Real-time-rate pass | **CLOSES only if D6(ii) is ruled at Day 0.** Otherwise dropped — not deferred a fourth time. |
| #5 | Payoff loop live-pair | **MET and now LIVE.** ⚑ `scene-009` is the check that it **stays** live — S11 proved it had been inert for a whole sprint under a green test. |
| #6 | Furniture placeable / buildable / claimable | **Code-complete since S11. `presentation-005` closes its human-observable half** — the first time a built bed is visible at all. |
| #7 | `presentation-002` signals something real | **MET (S11, `build-validation-009`).** |
| #8 | Ambient life wave 1 in the composed Valley | **ADVANCES** — golden-hour re-shoot against the real sun (now mandatory). Foliage hue, torch colour, Dusk/Horizon remain outstanding. |
| #9 | "World lacks life" CLOSED by the CD | **CLOSES on a signature, not on work.** Both prerequisites landed S11. ⚑ **Met only on a written, dated CD close entry.** |
| #10 | Building UI + Villager Info UI | **Depends entirely on the TD HUD ruling.** See **D3** — this is what the Cluster D signal is measuring. |
| #11 | Lifecycle breadth — demolition | **Closed on code S11.** `building-027`'s remove-mode wording is the one open question — **check whether `015` already absorbs it** before writing anything. |
| #12 | Plan-only undo | MET (S10). Redo-atomicity trigger not fired. |
| #13 | Mid-range hardware baseline | **STILL NO STORY. FIFTH sprint, two unowned TD decisions. Protected — untradeable — with ONE sprint left after this.** See **E1**. |
| #14 | `/team-qa sprint` sign-off every sprint | **Habit continues.** G1 keeps the QA plan a gate. |

## Risks

| Risk | Prob. | Impact | Mitigation |
|------|------|--------|------------|
| **`vox-022` touches terrain generation for the first time since `vox-006`, and the packed chunk storage feeds ADR-0015's on-disk region files** | Medium | **High** | Buffer's **primary** named consumer. **State the region-file compatibility question in the story file at authoring, before any code** — do not discover it. Named lever: **reduce design scope (2–3 height bands, not a biome system), never the data-driven-ness.** Escalate a format/migration question to TD rather than inventing one. |
| **The terrain work needs design input the producer must not invent** (which bands, which materials, which palette entries) | **High** | Medium | The bands come from the **art bible's SS4.3**, the colours from the **user's palette**, and the user is **actively editing that palette right now**. G2's authoring gate explicitly names art-director + user as design input. ⚑ **A producer-invented palette is worse than a one-colour world**, because it looks decided. |
| **Three of four Must stories have no story file** | Medium | Med-High | Buffer's **secondary** named consumer. G2 on day one. Precedent is good: this gate worked in S10 (`presentation-003`) and S11 (`scene-007` — where authoring raised the estimate 1.0 → 2.0 **and found a fifth uncalled construction site**). **Authoring is where this project finds things.** |
| **⚑ A TENTH ship-green-and-uncalled lands somewhere nobody is looking** | **High** | **High** | Nine instances; six closed in one day. **The countermeasure is now three-layered and every layer is mandatory this sprint**: (1) the anti-vacuity lever on every story; (2) the boot-invariant block, which grew again in S11 (camera count, villager placement, all three work gates); (3) ⚑ **NEW — the caller check runs against the WHOLE hosted module list at planning time, not only against this sprint's new APIs.** That third one is the gap instances 6–9 slipped through: none of them added new API, they had been uncalled for many sprints. |
| **A nil-safe/permissive default hides the next one** | **High** | **High** | S11's deepest lesson: both villager gates defaulted **permissive** when unwired, so `ConstructionTickLoop` credited work to absent villagers, and a null validation made **criterion #5 inert in the product while green in test**. ⚑ **Rule for this sprint: any injected collaborator whose absence changes behaviour must assert at boot or appear in the boot-invariant block. Never both optional and consequential.** `presentation-005`'s registry subscription and `vox-023`'s appearance table are both exactly this shape. |
| **A dev tool compensates for a missing product feature and hides it again** | Medium | **High** | `presentation-004` found this: three capture tools each supplied the art bible's golden-hour recipe, so the product could stay dark forever with every screenshot looking fine. AC6 made all three light nothing. ⚑ **Generalise it as a standing rule: a tool may supply NOTHING the product is supposed to supply — no lighting, no cells, no props, no clock.** `scene-009` extends a capture tool; hold it to this absolutely. |
| **The spike becomes an open-ended debugging session** | Medium | Medium | **Hard 0.5 time-box with a named stop rule**: if spent without a reproduction, write that down and stop. Deliverable is a **written finding**, not a fix. Producer-supplied hypothesis (the `villager-ai-016` livelock escape) gives it a concrete first probe rather than a blank start. |
| **Two stories are scheduled for the third and second time on unmade decisions** | **High** | Medium | ⚑ **Policy change this sprint: ruled by Day 0, or dropped from the plan.** Repeatedly scheduling decision-blocked work manufactures a false sense of capacity loss and, per the milestone's own anti-signal, risks a cut lever being pulled for the wrong reason. |
| **Criterion #13 is protected, unowned and story-less for the FIFTH sprint, with one sprint left** | **High** | **High** | Escalated as **E1** for the fifth time. **It cannot be traded on the cut lever**, so this is pure milestone risk with no absorption path. `vox-018`'s tool is reusable verbatim. **This now genuinely threatens the M02 gate.** |
| **`scene-009`'s captures slip because the view layer slips** | Medium | Low-Med | Stated in the Critical Path: ship the headless proof, **record the missing capture as a named debt**, never shoot a misleading picture. The `payoff_loop_demo` precedent already does exactly this — it skipped `05-furnished` rather than fake it. |
| **Godot 4.7 API deviations beyond the LLM cutoff** | Medium | Low-Med | `vox-023` (materials/shaders), `presentation-005` (MultiMesh / MeshInstance3D) and `building-ui-001` (Control/CanvasLayer) are all post-cutoff-change domains. Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01 and S09–S11. |
| **The recurring build-validation fixture trap + the "world is not empty after boot" trap** | Medium | Low-Med | Both bit agents in S11. The second is newly written down: **chunks lazily regenerate real terrain the moment residency is requested**, so tests building geometry against a real booted grid must build above `base_height + amplitude` or probe for clear cells. ⚑ **`vox-022` changes what terrain generation produces — re-read every fixture that assumes a single block type.** |

## Dependencies on External Factors

- **USER / art-director: the terrain band-to-material mapping and its palette entries.** The single
  highest-value input this sprint. The producer must not invent it.
- **USER RULING on D6(ii)** — decides whether criterion #4 closes or `needs-mood-009` leaves the plan.
- **TD RULING on HUD hosting (building-ui KC1/KC3)** — decides whether Cluster D starts.
  ⚑ `scene-007` already shipped the answer for the tool tier.
- **TD DECISION: target hardware class + VSync mode** — **fifth sprint**, blocking criterion #13's
  story from even being authored.
- **TD CALL on the furniture render mechanism (D11)** — *nice to have, explicitly not a blocker*:
  the landed per-entity presenter precedent (`presentation-003`) is followable without a ruling.
- **TD CALL on region-file compatibility** if `vox-022`'s storage change proves load-bearing.
- **CD RULING on the hen-and-egg pacing finding (D10)** — a design question, not a bug.
- **CD SIGN-OFF: a written, dated close entry** on "world lacks life" (criterion #9), plus the
  golden-hour re-shoot and the three remaining wave-1 advisories.
- **CD/PRODUCER decision on `presentation-001` Sub-B's scope gap (D12).**
- **CD TONE DECISION on villager names (D5)** — `VillagerAi` carries only `villager_id: int`;
  `villager-info-ui-003` names it as a hard gate. *"Hilda"* and *"Villager #3"* are different games.
- **USER RATIFICATION of both pre-flight ruling documents** — `architecture-decisions-m02-preflight-2026-07-26.md`
  and `creative-decisions-m02-preflight-2026-07-26.md`. **Fourth sprint.** A signature, not work.
- **R8 — external playtest.** ⚑ **Becomes schedulable for the first time at the END of this sprint**,
  if `presentation-005` and `scene-009` both land. Its blocking condition was always the S10 smoke
  check's own gate: *"a villager visibly moving in and sleeping should be observed by a human at
  least once before any external playtest."* **This sprint is what makes that observation possible.**
- **Control-manifest version 2026-07-23** — re-confirm unchanged before lanes start. Owner: TD.

## Definition of Done for this Sprint

- [ ] **G1 closed before the first `/dev-story`**: `production/qa/qa-plan-sprint-12-*.md` exists
- [ ] **G2 closed**: `vox-022`, `vox-023` and `scene-009` authored, **each with its anti-vacuity lever
      written into its own Test Evidence section**, and `/story-readiness` run against all three
- [ ] **G3 closed**: `sprint-status.yaml` back-filled with S11's five mid-sprint additions; the
      duplicate `villager-ai` `story-022` renumbered; `presentation-001`'s stale `Status` header
      corrected
- [ ] ⚑ **EVERY story that lands recorded its anti-vacuity lever FAILING on the pre-story build**,
      with the observed failure in the commit body — **BLOCKING, no exceptions.** A lever that passed
      before the story was written means the story proved nothing
- [ ] **The world generates ≥ 2 distinct terrain block types and the mesher reads their appearance
      from a data Resource** — **BLOCKING**; grep-assert zero hardcoded block colours in
      `src/voxel_world/`
- [ ] **A furniture view node count > 0 in the LIVE scene tree after a bed completes** — the
      live-tree-count technique, **BLOCKING**
- [ ] **`06-claimed` and `07-sleeping` exist in `production/qa/evidence/` and match their own
      report** — or their absence is recorded as a named debt with the reason. ⚑ **Never a picture
      that does not match its report** (the `05-furnished` precedent)
- [ ] **`scene-009`'s deletion probe run and its observed failure recorded** — **BLOCKING**
- [ ] **`bv-007`'s tick-source guard exists as a test**, not as a recommendation — **BLOCKING;
      third attempt**
- [ ] **The spike produced a written finding** with the observed `abandon_count` /
      `seal_prevention_abandon_limit` at the stall, and exactly one of: defect story, expected-
      behaviour ruling, or "not reproduced — closed"
- [ ] Every Logic/Integration story has a passing GdUnit4 headless test — **BLOCKING**
- [ ] **Decision-blocked vs capacity-trimmed stated explicitly for every unlanded story** — the
      milestone's cut-lever anti-signal depends on this distinction and it must never be ambiguous
- [ ] Grep guards green: no hardcoded block colours; furniture view **writes nothing** (BV-1
      transparency survives); HUD writes no simulation state (if pulled); no wall-clock on any
      decision path; zero `SceneTree.paused` / `Engine.time_scale`; `_visual_position` allowlist
- [ ] **No injected collaborator is both optional and consequential** — each either asserts at boot
      or appears in the boot-invariant block
- [ ] **No capture tool supplies anything the product should supply** — no lighting, no cells, no
      props, no clock (generalised from `presentation-004`'s AC6)
- [ ] **The caller check was run against the WHOLE hosted module list**, not just this sprint's new
      APIs, and the result recorded — the gap instances 6–9 slipped through
- [ ] Any red suite run re-run **in isolation** before any change is reverted on its basis
      (S10 §5). ⚑ **And never run two suites concurrently** — CPU starvation makes the reachability
      corpus breach its 60 s ceiling, which is a load artifact and **must never be "fixed"**
- [ ] Full blocking suite green headless, **0 orphans, exit 0, both checked explicitly**, on every
      story commit; E2E LOOP green on every commit
- [ ] All engine APIs confirmed against `docs/engine-reference/godot/` — **BLOCKING**
- [ ] Design/ADR/registry docs updated for any deviation (incl. the `building-015`-flagged stale
      `tr-registry.yaml` TR-123 clause, if still un-annotated)
- [ ] A single consolidated `production/qa/smoke-sprint-12-*.md` produced **at hand-off**
- [ ] **`/team-qa sprint` sign-off exists: APPROVED or APPROVED WITH CONDITIONS** — criterion #14
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] **Start-of-S12 review held**: Cluster D go/no-go (**D3**) + CD check on Cluster B's protected
      items, per the milestone's own Review Schedule
- [ ] **End-of-S12: R8 scheduled** if `presentation-005` and `scene-009` both landed — the first
      moment the MVP hypothesis is testable by a human being

## Open Decisions Surfaced by This Plan (producer → user)

Surfaced, not resolved. **D10 and D12 are new. D3 is the one that changes what S13 is planned around.**

### D10 — ⚑ NEW: the hen-and-egg pacing finding. A creative question, not a bug.

**The observation, stated plainly:** the villager gets tired and goes to sleep **before** the room
that would let it sleep well exists. The need curve and the build curve are out of phase — the player
is asked to care about shelter at a moment when shelter is not yet buildable, and the villager's first
sleep is therefore always the *unsheltered* one.

**Do not file this as a bug.** Nothing is malfunctioning: F1 decay, the recovery ladder, and the
construction tick loop are each behaving exactly as specified. **What is in question is whether the
first thing a new player feels is "I am building a home" or "I am already failing."**

- **(a) Leave it. It is the intended tension.** The first unsheltered sleep *teaches* what shelter is
  for — the ×0.7 vs ×1.0 difference lands hardest when the player has felt both. Cost: the opening
  minutes read as pressure rather than invitation. Zero work.
- **(b) Retune the phase so the first sleep is sheltered** — delay first urgency, or seed the starting
  villager with a higher initial need value, so a competent player gets the roof up first. Cost: this
  is `needs-mood-009`'s territory (`ticks_per_second = 4.0` real-time equivalents), so it **collides
  with D6(ii)** — decide them together or not at all. ⚑ **And note: `needs-mood-009` carries a hard
  "no `.tres` edit" guard, so a retune cannot ride along inside it.**
- **(c) Seed the world with one pre-built shelter** so the loop's first turn is *maintenance* rather
  than *rescue*. Cost: changes what the opening frame teaches; a Cluster 0-shaped scope addition.

**Producer recommendation: (a) for MVP, revisited after R8.** This is precisely the kind of question
an external playtest answers and internal argument does not — and R8 becomes schedulable at the end of
**this** sprint for the first time. **Deciding it now, before a human has played it, spends a
creative decision on a guess.** ⚑ **But it is a CD call, and if the CD's read is that the opening
tone is wrong, deciding early is cheaper than retuning in S13.**

### D3 — Cluster D: the literal signal and the anti-signal point in opposite directions

**The literal signal fires.** The milestone's lever table: *"Cluster D has not started by S12 → trim
steps 4–5 (both UIs to minimum viable)."* Cluster D has not started; `building-ui-001` was the one
story that would have made "started" honest and it did not land.

**The anti-signal covers exactly this case.** *"Do NOT pull the lever for a sprint that lands fewer
stories than planned for **decision** reasons… every slip on this project came from blocked decisions,
never from capacity."* `building-ui-001` did not land because **the TD HUD-hosting ruling never
arrived** — while `scene-007` answered the same architectural question for the tool tier and landed
comfortably inside the sprint. **Capacity was never close to being the constraint.**

**Both clauses are in the milestone document and they disagree. This must be decided, not resolved by
quoting one and ignoring the other.**

- **(a) Do not pull; take the TD ruling this sprint and commit to ~16 core Cluster D stories**,
  pre-declaring the polish tail (building-ui `012`–`018`, villager-info-ui `005`–`007`) out of MVP.
  The anti-signal is the operative clause; the missing input is a signature.
- **(b) Pull steps 4–5 now** — both UIs reduced to minimum viable (need bars + mood band + why-string;
  tool palette + ghost feedback + project state). **With one sprint left after this one, 25 UI stories
  were never landing regardless of the ruling.** Pulling now is a *scheduling* judgement about S13,
  not a punishment for a blocked decision.
- **(c) Leave it open one more sprint.** ⚑ **Not recommended** — it is the option that has already
  been taken twice and it is why the question is now urgent.

**Producer recommendation: (b), and I want to be honest that this differs from S11's recommendation
of (a).** What changed is arithmetic, not principle. S11 recommended committing to ~16 stories because
the epics had just been created and two sprints remained. **After S12 there is exactly one sprint
left.** At the measured cadence, S13 must also carry the milestone review, `/gate-check`, R8's
findings, and criterion #13 — sixteen new UI stories cannot fit alongside that, whatever the TD rules.
**Pulling to minimum-viable now is not conceding to a blocked decision; it is sizing S13 honestly
while it is still a choice.** ⚑ **Take the TD ruling anyway** — the minimum-viable UIs still need a
host, and `scene-007` already shipped the precedent for it. **This is your call.**

### D6(ii) — `needs-mood-009`'s self-contradiction, third sprint (blocks criterion #4)

Unchanged from S11: the story's 5th AC requires correcting `design/gdd/building-system.md`'s
`base_build_ticks` and both `base_demolition_ticks` mirrors, while its own Dependencies section says
*"Coordinate (do not edit from here)"* about the same lines. **Same document, opposite instructions.**

- **(a) Grant repo-wide, annotation-only authority** *(recommended, unchanged)*. Its hard guard — *no
  `.tres` edit, no AC anchor move, no test edit* — makes the blast radius of a wrong edit **provably
  nil**: it can only change comment text. Amend the Dependencies line to match the AC.
- **(b) Split into a needs-mood-only story + a separate repo-wide sweep.** Re-creates the
  miss-an-occurrence trap the widened AC exists to prevent. **Three sprints of the CD's own prediction
  have now elapsed.**
- **(c) Defer a fourth time.** ⚑ **Not available under this plan's new rule** — unruled by Day 0 means
  the story leaves the plan rather than occupying a slot it cannot use.

**Producer recommendation: (a).** One sweep, one change, one rationale artifact, zero value edits.
⚑ **See D10(b): if the phase retune is chosen, it does NOT belong inside this story.**

### D11 — ⚑ NEW: the furniture render mechanism (TD) — named so it does not silently become a blocker

`presentation-005` needs a call between **MultiMesh** (cheap at scale, awkward for per-item meshes) and
**per-item `MeshInstance3D`** (simple, matches `rid-009`'s typed `Mesh` `visual_asset` exactly).

⚑ **This is deliberately filed as a decision that does not block.** The project has a landed precedent —
`presentation-003`'s `VillagerBodyPresenter`, a per-entity presenter hosted in `Valley` — and
`scene-007` set the explicit rule of *following the only landed precedent when no ruling exists*.
**If the TD ruling arrives, take it; otherwise follow precedent and record the choice in the story.**
MVP has one multi-cell furniture item; the scale argument for MultiMesh does not bite yet.

**Producer recommendation: follow the landed precedent, record it, revisit if furniture count grows.**

### D12 — ⚑ NEW: `presentation-001` Sub-B's scope gap

Sub-B landed the two idle behaviours that existing FSM state can actually support (a SIT draw, a
PAUSE_LOOK draw). The art bible also names *"glancing at an unfinished build"* and *"brief exchanges
between bonded villagers"*. **Neither has any FSM state behind it — there is no build awareness and no
bond concept in the simulation at all** — and inventing them would be new simulation, which the story
explicitly forbids itself. The author flagged it rather than quietly dropping it.

- **(a) Accept Sub-B as the two FSM-backed behaviours** and move the other two to VS-tier. Zero cost.
- **(b) Schedule the simulation they require** — build awareness and a bond concept — as Cluster B
  stories. ⚑ **Cost is far larger than a presentation story**: these are simulation features wearing
  presentation clothing, and Cluster B is CD-protected, so this would expand a protected cluster.
- **(c) Leave undecided.** ⚑ **Blocks criterion #9's CD close from being unambiguous**, because the CD
  is being asked to close "world lacks life" against a wave-1 that is knowingly partial.

**Producer recommendation: (a), decided before the criterion #9 close session** — so the CD signs off
on a scope that has been named, rather than discovering the gap while signing.

### D4 / E1 — Criterion #13 is protected, unowned and story-less for the FIFTH sprint

**Target hardware class** and **VSync mode**, both technical-director, both still unowned. The
measurement story cannot be authored without the hardware class. ⚑ **Criterion #13 is never on the
cut lever, so this cannot be traded away — it converts one-for-one into milestone risk, and after
this sprint M02 has ONE sprint left.** `vox-018`'s tool is reusable verbatim (windowed, culling ON,
VSync OFF for true compute).

**Recommendation, for the fifth consecutive sprint: assign the hardware-class call at Day 0 so the
story can be authored and measured in S13.** ⚑ **If it is not assigned this sprint, the honest thing
is to record criterion #13 as at risk of missing the M02 gate**, rather than carrying it a sixth time
as though a sixth request will work where five did not.

### D5 — Villager names: a tone call, now two sprints from mattering

`VillagerAi` carries only `villager_id: int`. `villager-info-ui-003`'s Dependencies name **Known
Conflict 2 — the villager-name ruling (creative-director)** as a hard gate. Villagers have visible
bodies, a camera to be seen through, and — if D3(b) is taken — a minimum-viable info panel in S13.
**"Hilda" and "Villager #3" are different games.** CD tone decision, not an engineering default.

## Notes

- **Dependencies-satisfied check.** Every scheduled story was verified against **its own story file's
  `## Dependencies` section and `Status` line**, read on disk 2026-07-27 — never against an epic or
  milestone summary table. `needs-mood-009` → `002`/`003`/`005`/`008` all ✓ + **D6(ii) external**;
  `building-ui-001` → `building-001` ✓ + **TD ruling external**; `villager-ai-020` → `villager-ai-013`
  ✓ (landed S11); `rid-008-ac31a` → `rid-008` ✓ + `rid-009` ✓; `presentation-005` → `building-016` ✓,
  `building-028` ✓, `rid-009` ✓, `scene-007` ✓; `building-027` → `building-009` ✓, `015` ✓.
  **Three of the fifteen items have no story file** (`vox-022`, `vox-023`, `scene-009`) and are
  listed under gate G2 with a named author — **they are not fabricated.**
- **This is the fourth consecutive sprint where reading story headers and source, rather than tables,
  changed the plan.** S09 found the `building-012` inversion; S10 found `needs-mood-010`'s
  self-contradiction; S11 found `rid-009`'s false "all DONE" line and, from **source**, that the whole
  build-tool tier was in no scene. **S12's finds are:** (1) `villager-ai-016`'s livelock escape is
  Complete and shipping, which makes the 19/30 plateau a sharper question than "expected gate
  behaviour"; (2) `presentation-004`'s AC3 **cannot honestly be signed off before the terrain work**,
  because the provisional values exist to compensate for the single terrain colour; (3) `building-031`
  was absorbed by `015`, so **`building-027` may be absorbed too — verify before writing code**; and
  (4) five S11 stories were never entered in `sprint-status.yaml`.
- **⚑ The most important structural change this sprint: the caller check is widened.** S10's rule was
  *"every story adding a public API needs a caller story in the same sprint."* That rule produced
  `scene-007` and it worked — **and it caught none of instances 6, 7, 8 or 9**, because those modules
  added no new API; they had simply been uncalled for many sprints. **The check must run against the
  whole hosted module list at planning time.** The question is not *"what did this sprint add?"* but
  *"what does the live scene tree actually contain?"*
- **On sizing.** 6 Must + 6 Should + 3 Nice = **15 items**, against a measured band of 8–18 (S1–S11:
  8, 9, 9, 8, 8, 13, 12, 13, 18, 14, 18). Longest Must lane **2.5** of 8 available — deliberately
  shallow after S11's depth-5 lane C. **Throughput is not the risk.** The risks are three unwritten
  story files, one design input the producer must not invent, and five unmade decisions.
- **On the two decision-blocked stories.** `needs-mood-009` (third sprint) and `building-ui-001`
  (second) are scheduled **with an explicit Day-0 expiry**. Repeatedly re-scheduling work that cannot
  start manufactures a phantom capacity problem and, per the milestone's own anti-signal, risks a cut
  lever being pulled for exactly the wrong reason. **Get the ruling or take them off the plan.**
- **We will know this sprint was scoped right if:** the shipped game renders terrain in more than one
  colour and the user can change one of those colours by editing data alone; a furniture view node
  count in the **live scene tree** goes from zero to non-zero; `07-sleeping.png` exists and shows a
  villager asleep in a bed **inside a room that villager helped build**, matching its own report; the
  19/30 plateau has a written answer rather than a shrug; `bv-007`'s guard exists as a **test** on its
  third attempt; and **every unlanded story is labelled decision-blocked or capacity-trimmed, with no
  ambiguity left for the sign-off to resolve.**
- **Next step:** close **G1** (`/qa-plan sprint`), **G2** (author `vox-022`, `vox-023`, `scene-009`
  with their levers) and **G3** (record back-fill) — all three before any `/dev-story`. Then start
  `vox-022` (lane T), `presentation-005` (lane V), `scene-009` (lane L) and `spike-plateau` (lane S)
  **in parallel on day one**; all four are blocked on nothing.
