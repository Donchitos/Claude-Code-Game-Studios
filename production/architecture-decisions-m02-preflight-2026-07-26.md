# M02 Pre-Flight Technical Rulings — 2026-07-26

> **Status**: **PROVISIONAL — pending user ratification** (away-mode ruling).
> **Author**: technical-director. **Scope**: the technical conflicts raised in
> the "Landed-Code Deltas" sections of `production/epics/build-validation-navigability/EPIC.md`
> and `production/epics/needs-mood-system/EPIC.md`.
> **Binding intent**: these rulings are binding on Sprint 9 story authoring once
> ratified. Until then, treat them as the planning assumption.
>
> **This document does not rewrite any ADR.** Each ruling names its ADR home;
> the ADR edits are a separate, later pass. No production code was changed by
> this pass. Two documentation conflicts (items NM-5, NM-7) were checked against
> `neues-spiel/CONTRACTS.md` directly; only NM-7 required an edit (made).
>
> **Not ruled here** (routed to creative-director/designer): the
> `LoopPayoffSignalSurface` signal-shape question (BV-5) and the real-time
> pacing decision (needs-mood story 009).

## Verification basis

Every ruling below was checked against the landed source, not the epic
summaries. Files read in full or in relevant part:

- `neues-spiel/src/voxel_world/cell_contents.gd`, `voxel_world_grid.gd`
  (`bulk_write`, `_apply_write`, `_apply_write_to_resident_chunk`,
  `_queue_pending_write`, `_apply_pending_writes`, `_bg_regenerate_from_seed`,
  signal declarations)
- `neues-spiel/src/building_system/construction_tick_loop.gd`
  (`_on_tick`, `_complete_jobs`, `set_occupancy_predicate`,
  `set_seal_prevention_predicate`, `required_ticks_for`),
  `blueprint_cell.gd`, `commit_pipeline.gd` (furniture seams)
- `neues-spiel/src/villager_ai/villager_ai.gd`
  (`is_standable`, `is_step_legal`, `body_column`, `is_cell_in_body_column`,
  `_is_solid`/`_is_passable`, the `*_after_write` twins, `VILLAGER_CLEARANCE`,
  `MAX_STEP_HEIGHT`, `needs_provider`/`_has_urgent_need`),
  `villager_nav_graph.gd` (`predicate_source` parameter shape)
- `neues-spiel/src/resource_item_database/item_definition_resource.gd`,
  `item_definition.gd` (field inventory)
- `neues-spiel/CONTRACTS.md`, `docs/architecture/architecture.md`,
  `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`,
  ADR-0007, ADR-0016
- `design/gdd/build-validation-navigability.md` (Rules 1/5/8, signal table),
  `design/gdd/needs-mood-system.md` (Core Rule 4, F2 variable table, knob table)

---

## BV-1 — Furniture occupancy: where it lives, and what Build Validation injects

**Verified.** `CellContents` carries exactly `block_type_id` + `material_id` and
nothing else. `ConstructionTickLoop._on_tick()` collects
`changes[cell] = job.blueprint_cell.contents` for **every** completing job
regardless of `BlueprintCell.Category`, and `_complete_jobs()` issues them as a
single `voxel_world.bulk_write(changes)`. So a completed FURNITURE cell would
today write a solid block record into the data layer — it would read as
structure and would fail `is_standable`'s clearance loop. The conflict is real,
and its root is in the Building System's completion write, **not** in Build
Validation. Nothing regresses today: `CommitPipeline` never sets
`Category.FURNITURE` (its own doc comment names story building-028 as the future
real caller), so zero furniture cells exist in the landed build.

Also verified, and load-bearing: the GDD needs more than transparency. Rule 5,
Rule 8 and the signal table are written **per furniture item** —
`shelter_status_changed(item id, sheltered: bool)`, "need-functional furniture",
"one emission per transition per item". A cell-level "is furniture here" boolean
cannot satisfy that; Build Validation needs item identity.

### RULING

**Furniture is not voxel data. It never enters `VoxelWorldGrid`.**

1. **`CellContents` does not change.** No furniture flag, no third id, no
   sentinel block type. The voxel data layer stays "one cell = one block record"
   (Voxel World Core Rule 2), and it stays opaque about what those ids mean.
2. **Furniture occupancy lives in a Building-System-owned furniture registry**
   (`building-028`), keyed by placed-item identity, holding at minimum:
   item id, occupied cells (from `ItemDefinition.get_footprint()`), and the
   definition id. This is the same architectural move the codebase already made
   twice: unbuilt Planned blueprint cells are deliberately absent from the grid,
   and ghost/draft picking is an `extra_solid` **overlay predicate** on the DDA
   path rather than data written into the grid (Control Manifest, ADR-0014 §4).
3. **`ConstructionTickLoop` must exclude `Category.FURNITURE` from its
   `bulk_write` payload** and route a completing furniture cell to the furniture
   registry instead. `construction_completed` still names the cell. This is a
   **blocking AC on `building-028`**, with a regression test asserting that
   completing a FURNITURE-category job leaves `voxel_world.get_cell()` empty at
   that cell.
4. **Rule 1 (furniture evaluates as-if-empty) is then satisfied by
   construction**, with no branch anywhere in Build Validation and no change to
   `is_standable`. It is the identical mechanism `villager_ai.gd`'s
   `is_standable` doc comment already relies on for Planned blueprint cells.
5. **The seam Build Validation injects is the furniture registry, not a cell
   predicate.** Shape: a duck-typed, nil-safe `Object` dependency (the landed
   precedent is `VillagerAi.needs_provider` / `job_queue` / `population`),
   exposing an enumeration of placed furniture records. A `null` provider means
   "no furniture exists" — a correct, non-crashing default that is exactly true
   until `building-028` lands.
6. **"Need-functional" is Build Validation's own data-driven config knob**, not
   a new RID field. `ItemDefinitionResource` has no need-recovery flag and does
   not need one for MVP; it has `category: StringName`. Build Validation's
   config carries a typed `@export` list of need-functional categories/ids
   (ADR-0002), resolved through `ResourceItemDatabase.get_by_id(...)`. Do not
   hardcode `&"bed"`.

**Explicitly out of this ruling** (design, not architecture): whether furniture
should *block villager movement*. Under this ruling it does not, because it is
not in the walkability data. If the designer later wants beds to be
impassable, that is a walkability-overlay decision (the `extra_solid` pattern
again) — it is **never** to be solved by writing furniture into the voxel grid.
Flag to creative-director/game-designer; not an M02 blocker.

**ADR home**: ADR-0016 (Build-Project Entity Lifecycle) — it already owns
furniture-uniform demolition; the "furniture is registry-resident, never
grid-resident" clause belongs in its Decision section. Secondary note in
ADR-0007 that walkability is unaffected by furniture.

**Consequence for sequencing**: build-validation story 002's furniture-
transparency AC **loses its hard dependency on `building-028`** — it becomes a
proof-by-construction test (furniture cell reads empty). Story 002 can start as
soon as 001 does. Story **006 still needs `building-028`** for item enumeration,
but only for the registry query, and it can be developed against the mocked
provider and un-mocked later. The hard blocker moves off Cluster A's critical
path and onto `building-028`'s AC list.

---

## BV-2 — What Build Validation subscribes to for M02

**Verified, and the epic's framing understates the problem.** There is a
correctness hazard in triggering off `construction_completed`:
`ConstructionTickLoop._complete_jobs()` emits `construction_completed` from
`completed_jobs`, unconditionally, *after* calling `bulk_write`. But
`VoxelWorldGrid._apply_write()` (story vox-014, ADR-0015 "load-before-write")
**queues** a write whose chunk is not resident and returns `null` — the write
lands later, from `_apply_pending_writes()`, whenever the chunk pages in. So
`construction_completed(cells)` can name cells whose data is **not yet in the
grid**. A Build Validation pass triggered by it would analyse stale data and
emit a wrong verdict. `cells_changed_batch` fires only when a record actually
changed — including from `_apply_pending_writes()`, at the moment the deferred
write really lands.

Also verified: `cells_changed_batch` is **not** noise. Page-in and
seed-regeneration are explicitly silent (`_bg_regenerate_from_seed`: "never
marks anything dirty and never emits any signal — page-in must be
silent/transparent to consumers"). `bulk_write` emits exactly once per call and
never emits an empty batch.

### RULING

**Build Validation subscribes to `VoxelWorldGrid.cells_changed_batch` as its
single structural trigger. It does not subscribe to
`ConstructionTickLoop.construction_completed` at all.**

Rationale, in the decision-framework order:

- **Correctness**: it is the only signal that guarantees the data Build
  Validation is about to read is present (deferred-write hazard above).
- **Simplicity**: one trigger, one subscription, no dedupe logic. Subscribing to
  both would double-fire every construction tick.
- **Completeness**: it is a strict superset — construction completion,
  demolition (`building-009`, when it lands), undo restores, and any future dig
  order all reach the grid through `_apply_write`. Build Validation needs **no
  code change** when demolition lands. The GDD Rule 7 trigger pair
  ("completed OR removed") is satisfied by one subscription rather than two.
- **Batching**: preserved. One `bulk_write` per tick dispatch → one batch
  signal → at most one analysis pass per tick, which is coarser than the GDD's
  per-frame guarantee (this is the epic's own Known Conflict 3, unchanged).

**Second trigger, when it exists**: furniture placement/removal does not touch
the grid under BV-1, so Build Validation additionally subscribes to the
**furniture registry's own placed/removed signal** (`building-028`). Two
orthogonal sources, one per data layer, no overlap, no double-fire. Until
`building-028` lands, `cells_changed_batch` alone is complete because no
furniture exists.

**Ordering note for the implementer**: `cells_changed_batch` fires *during*
`bulk_write`, i.e. before `BlueprintCell` micro-states flip to `BUILT` and
before `construction_completed`. Build Validation reads voxel data only and
mutates nothing, so it is order-insensitive with respect to the other
subscribers (`VillagerNavGraph` already subscribes to the same signal). Do not
introduce any read of `BlueprintCell` state from Build Validation.

**ADR home**: ADR-0007 (event-driven trigger) with a correction note in
ADR-0016, whose current text names `construction_completed` as the analysis
trigger. The ADR-0016 clause is **superseded for Build Validation only** —
`construction_completed` remains valid for consumers that care about *jobs*
completing rather than *data* changing.

**Consequence for sequencing**: build-validation story 005's trigger wiring is
unblocked and gets *simpler* (one subscription, no demolition follow-up story).
`building-009` no longer needs to ship a new signal for Build Validation's
benefit. Story 005 must carry an AC proving a deferred/paged write still
triggers a pass.

---

## BV-4 — Walkability predicate DI shape

**Verified.** `is_standable`, `is_step_legal`, `body_column` and
`is_cell_in_body_column` are instance methods on `VillagerAi` (a `Node` carrying
`villager_id`, `config`, `voxel_world`, scheduler, nav graph, telemetry…). But
their *bodies* read only `voxel_world` and the two class constants
`VILLAGER_CLEARANCE = 3` / `MAX_STEP_HEIGHT = 1`. They read **no** per-villager
state — no `villager_id`, no `config`. Every instance therefore returns
identical answers, which means "which villager do I inject?" has no meaningful
answer. `VillagerNavGraph` already works around this by taking a
`predicate_source: VillagerAi` parameter on `build()`, `patch_cells()`,
`subscribe_to_voxel_world()` and `_resync_points()`.

Note also what ADR-0007 actually says: "Villager AI owns the walkability
predicates **as shared pure functions**" and "Villager AI **exposes two pure
query functions**". The landed instance-method shape is a drift from the ADR,
not a decision the ADR made.

### RULING

**Extract a pure static twin. Build Validation injects nothing and holds no
villager reference.**

1. New file `neues-spiel/src/villager_ai/villager_walkability_rules.gd`,
   `class_name VillagerWalkabilityRules extends RefCounted`, **static
   functions only**, never instantiated:
   - `static func is_standable(voxel_world: VoxelWorldGrid, cell: Vector3i) -> bool`
   - `static func is_step_legal(voxel_world: VoxelWorldGrid, from_cell: Vector3i, to_cell: Vector3i) -> bool`
   - `static func body_column(cell: Vector3i) -> Array[Vector3i]`
   - the `_is_solid` / `_is_passable` helpers move with them
2. **The constants move too.** `VILLAGER_CLEARANCE` and `MAX_STEP_HEIGHT` are
   declared on `VillagerWalkabilityRules` and nowhere else. `VillagerAi` keeps
   `const VILLAGER_CLEARANCE: int = VillagerWalkabilityRules.VILLAGER_CLEARANCE`
   (and likewise for `MAX_STEP_HEIGHT`) as a re-export alias so every existing
   call site — including `VillagerNavGraph`'s `VillagerAi.VILLAGER_CLEARANCE`
   read — compiles unchanged. There is still exactly **one literal** in the
   codebase, so the epic's "zero duplicated walkability constants" grep guard
   holds (the guard must test for duplicated *literals*, not for the identifier).
3. **`VillagerAi`'s public methods stay, as one-line delegations.** Signatures
   unchanged. Every landed test, `VillagerNavGraph`'s `predicate_source` calls,
   the seal-prevention gate and the rescue BFS keep working untouched. This is
   what makes the refactor safe: the existing suite is the regression net.
4. **Build Validation calls `VillagerWalkabilityRules.is_standable(voxel_world, cell)`
   statically.** It already injects `voxel_world`. It gains **no** new
   dependency, holds **no** reference to a gameplay entity, and cannot be
   null-ref'd by a despawned villager. Cross-module static utility calls are
   already sanctioned and in use — `VillagerAi` itself calls
   `VoxelWorldGrid.cell_to_world(...)` statically.
5. `VillagerNavGraph`'s `predicate_source` parameter may be migrated to the
   static class in the same story or left as-is; leaving it is acceptable
   because it delegates to the same single implementation. Do not do both.
6. **Known residual, deliberately not fixed here**: the `*_after_write` twins
   (`_is_standable_after_write`, `_is_step_legal_after_write`) re-implement the
   same control flow with override-aware reads. That duplication exists today
   and is the one sanctioned copy. The clean fix is an overlay predicate
   parameter on the extracted functions; it is a **post-M02** item — record it
   as technical debt, do not expand this story's scope.

Why not "inject a `VillagerAi`": the predicates are instance-independent, so the
injection would encode a lie about the dependency; `villager-ai-021` makes the
roster plural and the "the one villager" assumption evaporates; a despawned
villager becomes a freed reference inside a system whose Rule 9 forbids it from
ever failing loudly at the player; and the shape would be baked into all ten
build-validation stories' `setup()` and test fixtures, making it expensive to
reverse. Extraction is a mechanical, test-covered, one-story refactor and
restores ADR-0007's stated shape.

**ADR home**: ADR-0007, Decision §1 (Key Interfaces update: the shared
predicates' canonical call form). No new ADR.

**Consequence for sequencing**: a **new prerequisite story on the villager-ai
epic** — "extract `VillagerWalkabilityRules`, behavior-preserving" — must land
before `build-validation-001`. Estimate it as small (mechanical extraction plus
alias, existing suite must stay green with zero test edits; if any test needs
editing, the extraction was not behavior-preserving). Build-validation story 001
then has a *smaller* DI surface than planned: config + `voxel_world` +
(later) the furniture provider.

---

## NM-5 — `start_recovery` canonical signature

**Verified — and the epic's premise about `CONTRACTS.md` is wrong.**
`neues-spiel/CONTRACTS.md` contains **no** `start_recovery` reference anywhere
(it is a Foundation-spine contract sheet: DI, config, boot gate, data
immutability, severity, engine constraints — it has no needs-mood API block).
The documents that actually carry the signature:

- `docs/architecture/architecture.md:373` —
  `func start_recovery(villager_id: int, need: StringName, source_enum: RecoverySource) -> void`
- `design/gdd/needs-mood-system.md:159` and Core Rule 10 — `start_recovery(need, source_enum)`
- `docs/architecture/tr-registry.yaml` TR-needs-mood-system-042 and
  TR-villager-ai-behavior (line 2222) — both written `start_recovery(need, source_enum)`

### RULING

**Canonical: `start_recovery(villager_id: int, need: StringName, source_enum: RecoverySource) -> void`**
(and symmetrically `stop_recovery(villager_id, need, reason)`).

Needs & Mood is a per-villager system with no implicit "current villager"; the
landed sibling seam on the same module boundary is already villager-keyed
(`has_urgent_need(villager_id) -> bool`, see NM-6). Two seams into the same
system with inconsistent keying would be a defect. `architecture.md` is correct
as written and needs no edit.

**No `CONTRACTS.md` edit made** — there was nothing there to correct.

**Doc-hygiene items for the GDD/registry owner (not mine to edit):**
`design/gdd/needs-mood-system.md` Core Rule 10, TR-needs-mood-system-042, and
the villager-ai TR at `tr-registry.yaml:2222` all elide the `villager_id`
parameter and should be corrected to the three-arg form.

**ADR home**: none needed — `architecture.md`'s API Boundaries block is the
home and is already right.

**Consequence for sequencing**: needs-mood story 003 implements the three-arg
form as specified; no story changes. The GDD/registry fix is a doc task the
producer can batch, not a blocker.

---

## NM-6 — `has_urgent_need(villager_id) -> bool`

**Verified.** `neues-spiel/src/villager_ai/villager_ai.gd:474` declares
`var needs_provider: Object = null`, duck-typed against exactly one member,
`func has_urgent_need(villager_id: int) -> bool`; `_has_urgent_need()` (line
1303) is nil-safe and returns `false` when unwired. It is exercised by
`tests/unit/villager_ai/priority_decision_loop_test.gd`. Confirmed by grep that
the name appears in **no** document under `docs/` or `design/`.

### RULING

**Canonized.** `has_urgent_need(villager_id: int) -> bool` is a **required**
part of Needs & Mood's public query API, in addition to the GDD's documented
query surface — not a replacement for it. The landed consumer defines the seam;
un-mocking the Villager AI FSM is impossible without it, and criterion #5's
live-pair test runs through it.

Two supporting constraints:

- **Nil-safety stays on the consumer side.** Do not add a null-provider branch
  to Needs & Mood. `VillagerAi._has_urgent_need()`'s existing guard is the
  correct and already-tested location.
- **It must be a pure query.** No signal emission, no state mutation, no
  lazy-initialisation of a villager's need record as a side effect of being
  asked. It is polled from the FSM's decision point every tick (ADR-0008:
  "polls need state at its decision points").

**Where it must be documented** (three places, in priority order):

1. `docs/architecture/architecture.md` — Needs & Mood's "Exposes" row and the
   API Boundaries signature block, alongside `start_recovery`/`stop_recovery`.
   **This is the blocking one** — do it before needs-mood story 002 starts.
2. `design/gdd/needs-mood-system.md` — the query-API section, with a TR of its
   own (the registry currently has no TR covering it). GDD-owner task.
3. `neues-spiel/CONTRACTS.md` — **when the module lands**, not now. CONTRACTS.md
   documents as-built spine contracts; adding a signature block for an
   unimplemented module would break its own stated purpose.

**No `CONTRACTS.md` edit made** — premature by that file's own charter.

**ADR home**: none — this is an API-boundary documentation fix, not an
architectural decision.

**Consequence for sequencing**: needs-mood story 002 gains an AC
("`has_urgent_need(villager_id)` returns the queryable Urgent state, pure
query"). Story 010's live pair depends on it existing; nothing is blocked.

---

## NM-7 — `CONTRACTS.md` §1 TR-ID citation

**Verified.** `tr-registry.yaml` defines `TR-needs-mood-system-025` as the
**live-pair integration test** (AC34: real Needs + real Villager AI, no mocks at
the seam). `CONTRACTS.md` §1 (Dependency Injection) listed it flatly among that
section's TR-IDs, implying it is a DI-pattern requirement. It is not.

It is also not a pure mistake worth deleting: ADR-0001's own Context cites
TR-025 as one of the *drivers* for the DI decision ("Needs & Mood's live-pair
integration infra TR-025"), and the needs-mood epic states the trace correctly —
headless-mockable DI is what makes the *un*-mocked pair constructible. The
citation's substance is legitimate; its unqualified placement was misleading.

### RULING

**Annotate, do not delete.** Traceability to ADR-0001's stated driver is kept;
the false implication that 025 is a DI requirement is removed.

**`CONTRACTS.md` edit MADE** (§1, Governing ADR / TR-IDs line):

`TR-needs-mood-system-025` now reads
`TR-needs-mood-system-025 (live-pair integration test — DI is its enabler per ADR-0001 Context, not itself a DI requirement)`.

**ADR home**: none — CONTRACTS.md citation hygiene.

**Consequence for sequencing**: none. Stories follow the registry: 025 → story
010, as the epic already assumed.

---

## NM-3 — F2 variable table vs Core Rule 4

**Verified.** `design/gdd/needs-mood-system.md:266` (F2 variable table) reads
`source_multiplier | float | 0–1 | Bed = 1.0; ground = ground_penalty = 0.4` —
two rungs. Core Rule 4 (lines ~118–127) defines three:
bed sheltered ×1.0 > `unsheltered_bed_multiplier` (0.7) > `ground_penalty`
(0.4), with the five-value source enum collapsing the three `ground_*` values
onto one rate row. AC28 tests the middle rung explicitly. AC29 and
TR-needs-mood-system-020 make the ordering invariant
`ground_penalty < unsheltered_bed_multiplier < 1.0` a **BLOCKING** config
invariant. The Tuning Knobs table (line 402) states outright that
`unsheltered_bed_multiplier` is "Owned HERE (this table is the source of
truth)".

### RULING

**Confirmed. Core Rule 4 is authoritative; the F2 variable table is stale.**

Three independent artefacts (Rule 4, AC28, TR-020's blocking invariant, plus the
knob table's explicit ownership claim) agree on three rungs; only the F2
variable row disagrees. Implement three rungs via the **source→rate table
lookup** the epic's Definition of Done already requires (AC10: a brand-new
source id must work with no code change) — which means F2's `source_multiplier`
is a table lookup keyed by the source enum, and the variable row should never
have enumerated values in the first place.

**Do not implement the two-multiplier form under any circumstance** — it would
make the BLOCKING ladder invariant unenforceable (there would be no middle rung
to order) and would silently delete the "the missing roof visibly costs"
mechanic, which is the mechanical meaning of Cluster A.

**Designer fix required (I have not edited the GDD):**
`design/gdd/needs-mood-system.md` line 266's F2 variable table row should read
`source_multiplier | float | 0–1 | Looked up from the Core Rule 4 source→rate
table by source enum (bed_sheltered 1.0 / bed_unsheltered
unsheltered_bed_multiplier / ground_* ground_penalty)` — or simply point at Rule
4 rather than restating values. Route to the needs-mood GDD owner.

**ADR home**: none — GDD-internal consistency.

**Consequence for sequencing**: none. Needs-mood story 003 (source→rate table)
implements three rungs as already specified; story 001's BLOCKING invariant is
unaffected. This is a doc-hygiene ticket, not a story blocker.

---

## Summary of downstream actions this record creates

| # | Action | Owner | Blocks |
|---|--------|-------|--------|
| 1 | New villager-ai story: extract `VillagerWalkabilityRules` (behavior-preserving) | lead-programmer / villager-ai | `build-validation-001` |
| 2 | `building-028` gains blocking AC: FURNITURE-category completion never `bulk_write`s to the grid; furniture registry owns occupancy + item identity | building-system | `build-validation-006` |
| 3 | `building-028` exposes a placed/removed signal + item enumeration query (duck-typed, nil-safe provider) | building-system | `build-validation-006` |
| 4 | `build-validation-005`: single trigger = `cells_changed_batch`; AC must cover a deferred/paged write | build-validation | — |
| 5 | `architecture.md`: add `has_urgent_need(villager_id) -> bool` to Needs & Mood's exposed API | technical-director | `needs-mood-002` |
| 6 | GDD/registry doc fixes: `start_recovery` three-arg form (GDD Rule 10, TR-042, TR at registry L2222); F2 variable table → Rule 4 lookup | game-designer / GDD owner | nothing |
| 7 | ADR pass (separate): ADR-0016 furniture-residency clause; ADR-0007 predicate call form + trigger note | technical-director | nothing |
| 8 | Tech-debt register: `*_after_write` predicate twins → overlay-predicate parameter (post-M02) | technical-director | nothing |
| 9 | Design question to CD/game-designer: should furniture block villager movement? (not M02) | creative-director | nothing |

---
---

# Addendum — 2026-07-26 (same pass, second batch)

> **Status**: **PROVISIONAL — pending user ratification**, identical standing to
> the rulings above. Three items: NM-6's documentation obligation discharged,
> the producer's S09 open item **D2** (villagers have no body) ruled, and the
> `PayoffDetail`-vs-`@export` collision closed.
> **No production code was changed by this pass.** One documentation edit was
> made (`docs/architecture/architecture.md`, see NM-6-DONE).

---

## NM-6-DONE — `has_urgent_need` documented in `architecture.md`

Ruling NM-6 named `docs/architecture/architecture.md` as the **blocking**
documentation site, to be closed before `needs-mood-002` starts (a Must story in
Sprint 9). Verified the landed consumer before writing: `villager_ai.gd:474`
`var needs_provider: Object = null` — duck-typed, non-`@export`ed, nil-safe —
read exclusively through `_has_urgent_need()` (`:1303`), whose entire body is a
null guard plus `needs_provider.has_urgent_need(villager_id)`. The seam is
villager-keyed, boolean, and called from the tier-1 branch of the priority
decision loop. That is the contract now written down.

**Edits made** (four, all in `architecture.md`, all mirroring the surrounding
row/comment style rather than introducing a new one):

1. **Module Ownership → Feature Layer → Needs & Mood System, `Exposes` column.**
   The cell said "Need/mood/why-string query; urgency/satisfied threshold-cross
   events (latency hints only)". It now names the four query methods explicitly
   and adds `has_urgent_need` as *"pure urgency gate, polled by Villager AI's
   decision loop — ADR-0008"*. Backticked method names match the Voxel World /
   Building System rows' convention in the same table.
2. **Module Ownership → Core Layer → Villager AI & Behavior, `Consumes` column.**
   "Needs & Mood (poll need state)" → "Needs & Mood (polls
   `has_urgent_need(villager_id)` at every decision point — never trusts the
   threshold-cross events alone)". This is the consumer half of the same seam and
   restates the invariant already asserted in the Signal Ownership table
   ("Latency hints only — Villager AI still polls authoritative need state at
   decision points").
3. **API Boundaries → Needs & Mood block.** Added the signature between
   `get_why_string` and the two signals:
   `func has_urgent_need(villager_id: int) -> bool` with a trailing
   `# REQUIRED — the urgency gate Villager AI's decision loop polls every tick
   (ADR-0008)`. Placement is deliberate: it sits with the other queries, above
   the latency-hint signals it must never be replaced by.
4. **API Boundaries → Needs & Mood block, second `# GUARANTEE:` clause.** The
   purity contract, written in the same `# GUARANTEE:` idiom the Time & Tick,
   Resource DB, Building System and Build Validation blocks already use:
   > emits no signal, mutates no state, and never lazily initializes a villager's
   > need record as a side effect of being asked. An unknown/despawned
   > `villager_id` returns `false` **without creating a record**. Nil-safety for
   > an unwired provider belongs to the **caller**
   > (`VillagerAi._has_urgent_need`'s existing guard) — Needs & Mood carries no
   > null-provider branch of its own.

   The unknown-id clause is the one genuinely *new* decision here rather than a
   transcription. It follows forcibly from "no lazy record init": if the method
   may not create a record, it must answer something for an id it has never seen,
   and `false` is the only answer consistent with villager-ai Rule 9 (never fail
   loudly at the player) and with the consumer's own unwired default. Needs &
   Mood may emit a debug-tier warning; it may not create state and it may not
   assert.

5. **Also updated**: the Villager AI API-boundary block's inline comment
   ("Villager AI CONSUMES (does not expose) Needs & Mood's
   `start_recovery`/`stop_recovery`…") now also names the `has_urgent_need` poll,
   so the direction of the seam is unambiguous read from either block.

**`needs-mood-002` is unblocked.** Its added AC (per NM-6) is now traceable to a
written API-boundary contract rather than to a ruling document. The two
non-blocking documentation sites from NM-6 are unchanged in status: the GDD
query-API section + a new TR (GDD owner), and `CONTRACTS.md` **when the module
lands**, not before.

---

## VB-1 — The villager body: where it lives, what it is, and how it is clicked

*(Ruling on the producer's Sprint 9 open item **D2**. Owner assignment in
sprint-09.md was "technical-director + godot-specialist"; this is the TD half.)*

**Verified against `neues-spiel/src/` and `Valley.tscn`, 2026-07-26.** All of the
following is landed fact, not epic summary:

- `villager_ai.gd:347-348` — `class_name VillagerAi` / `extends Node`. Not
  `Node3D`. **One node per villager** is the actual architecture (`:882-884`
  documents this explicitly, which is why `get_state()` and `get_current_cell()`
  carry no `villager_id` parameter).
- `Valley.tscn` hosts exactly one `VillagerAi` of `type="Node"` with
  `villager_id = 0` and **no children**. The scene's only `MeshInstance3D` is the
  ambient torch indicator.
- `_visual_position: Vector3` (`:625`) is private, recomputed every `_process`
  frame (`:937-941`) from `_from_cell.lerp(_to_cell, _intra_tick_progress)`, and
  has **no public getter**. `get_current_cell() -> Vector3i` is the only public
  position API and is deliberately the discrete cell.
- Repo-wide, `Area3D` / `CollisionShape` appear under `src/` **only inside doc
  comments**.
- `src/presentation/` already exists as a populated presentation tier
  (`torch_flicker.gd`, `chimney_smoke_emitter.gd`, `interior_clutter_placer.gd`,
  `loop_payoff_signal_surface.gd`).
- Population target: `starting_villager_count` MVP = **1**, Vertical Slice = 5,
  Full-Vision ceiling **20–30** (villager-ai-behavior GDD, ADR-0004 Constraints).
- Art Bible §5.2: villagers are **2 cells tall**, ~45:55 head-to-body split,
  1 arm-block + 1 leg-block per side; §5.3 adds a per-villager accent hue applied
  as a **material swap on a shared mesh**.
- The prototype's form (`prototypes/last-seal-vertical-slice/villager_ai.gd:659-711`,
  **reference only, never imported**): a `Node3D` root per villager with
  `physics_interpolation_mode = OFF`, a capsule body + box head, position driven
  from `visual_position` each frame, `visible = current_cell.y <= _slice_level`.
  It had no collider at all — the prototype selected villagers some other way, so
  it is *not* precedent for the hit-test question.

### RULING

**The body is a separate presentation-tier view node, one per villager, driven by
pulling the AI node's visual position every frame. `VillagerAi` stays
`extends Node` and gains exactly one new public method.**

#### 1. Where it lives — a presentation-tier view, not a child of `VillagerAi`

Two new scripts under `neues-spiel/src/presentation/`:

- `villager_body_view.gd` — `class_name VillagerBodyView extends Node3D`.
  One instance per villager. Holds `villager_id: int` and a **duck-typed,
  nil-safe** `ai_source: Object` (the landed DI precedent: `needs_provider`,
  `job_queue`, `population`), from which it reads exactly three members:
  `get_visual_position()`, `get_current_cell()`, `get_state()`.
- `villager_body_presenter.gd` — `class_name VillagerBodyPresenter extends Node3D`.
  Valley-hosted, injected-tier `setup()`. Owns the create/free lifecycle: one
  `VillagerBodyView` per roster entry, freed on despawn. Injected with a
  duck-typed, nil-safe roster provider (a `null` provider means "no villagers",
  which is correct and non-crashing exactly as it is for every other landed
  provider seam).

**Why not a child `Node3D` of `VillagerAi`, and why not making `VillagerAi` a
`Node3D`.** `VillagerAi` is a Core-layer simulation node whose entire test
suite constructs it headlessly via `Node.new()` + mocks (ADR-0001). Giving it
mesh children moves rendering responsibility into a Core module, makes every
headless unit test allocate RenderingServer resources, and couples the FSM's
node type to a presentation choice we will revise the moment the art-bible-
faithful villager replaces the placeholder. The layering rule the codebase
already follows — Presentation reads Core, never the reverse — gives the answer
directly. `VillagerAi` remains `extends Node`; nothing about its instantiation,
its tests, or its `Valley.tscn` entry changes.

**Why not Valley-hosted-flat.** The presenter *is* Valley-hosted; the views are
its children. That gives one place that knows how many villagers exist and one
place to free them, which is what `villager-ai-021`'s roster makes necessary.

#### 2. The one new method on `VillagerAi`, and why it is not a second source of truth

```gdscript
## PRESENTATION ONLY. Returns the interpolated render position. Never read this
## from any logic path — occupancy, targeting, walled-in and seal-prevention
## checks all read get_current_cell() (ADR-0009 §2).
func get_visual_position() -> Vector3
```

It is a **read-only accessor over the existing field**. The lerp stays exactly
where ADR-0009 put it (`VillagerAi._process`); the view stores no position, caches
nothing, and performs no interpolation of its own — it assigns
`global_position = ai.get_visual_position()` in its own `_process`, every frame,
pull-only. That is the same "pure mirror, re-read every frame, signals are hints
not values" discipline the UI layer is already held to. One writer, N readers,
zero copies: no second source of truth is created.

**ADR-0009 consequence.** Its Validation Criteria include a grep guard:
"`_visual_position` is never referenced outside the movement/rendering code
path". A presentation-tier view **is** the rendering code path, so this is
compliant in substance — but the guard as written is a filename check today and
will now trip. It must be re-scoped to what it actually means: *no occupancy,
targeting, walled-in, seal-prevention or job-selection code reads the visual
position*, with an explicit allowlist of `villager_ai.gd`'s own `_process` plus
`src/presentation/`. Recorded as a downstream ADR-0009 amendment below. The
substantive invariant is unchanged and must stay grep-enforced.

`physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` is set
explicitly on `VillagerBodyView` — this is the *node the control manifest was
already referring to* ("Villager visual node sets `physics_interpolation_mode =
OFF` explicitly", manifest line 71, source ADR-0009). Until now that rule had no
node to apply to.

#### 3. What it is made of — per-villager `MeshInstance3D`, not `MultiMesh`

**Per-villager `MeshInstance3D` children of the view.** The villager count target
settles this without needing a measurement: MVP = 1, VS = 5, Full-Vision ceiling
20–30. At 30 villagers × ~3 mesh parts that is ~90 draw calls against a **2000**
draw-call budget — 4.5% of budget for the entire cast, and the voxel world is on
MultiMesh/chunked geometry precisely so that this headroom exists.

`MultiMesh` is rejected on four independent grounds, any one of which is
sufficient: it cannot carry a per-instance `Area3D` (so hit-testing would need a
parallel collider hierarchy anyway, defeating the consolidation); per-instance
hiding for Slice View becomes transform-hackery instead of `visible = false`;
Art Bible §5.3's accent hue is specified as a **material swap on a shared mesh**,
which is the per-instance-`MeshInstance3D` idiom, and §5.4's squad equipment
layer adds *structure* per instance, not just color; and the overhead-icon anchor
(story `villager-info-ui-005`) needs a real `Node3D` per villager to parent to.
**Revisit only if the population ceiling moves past ~200** — record that as the
trigger, not "if it feels slow".

Placeholder geometry for M02, matching Art Bible §5.2's scale fact and nothing
more: a 2-cell-tall figure, box or capsule body + box head at roughly the 45:55
split, one flat `StandardMaterial3D` per villager so the accent-hue channel has
somewhere to live later. **The art-bible-faithful villager (limb blocks,
profession gold trim, individuation palette, behavioral tells) is explicitly
later** — it is Art Bible §5.2/§5.3/§5.6 work and belongs to an art-production
story, not to this one. What M02 needs is a readable silhouette that can be
seen, clicked, hidden by a slice, and hung an icon on.

#### 4. Hit-testing — `Area3D` on the view, and no, it does not violate the manifest

**ADR-0004's mechanism stands, unchanged.** The `Area3D` + `CollisionShape3D`
lives as a child of `VillagerBodyView` — so it moves with the *visual* position
for free, which is the behaviourally correct answer (a click lands where the
player sees the villager, not where their discrete `current_cell` is mid-transit).

Concrete form:

```gdscript
class_name VillagerHitProxy
extends Area3D
var villager_id: int = 0
# collision_layer = 1 (ADR-0004 "villagers"), collision_mask = 0,
# monitoring = false (it never needs to detect anything), monitorable = true.
```

A typed proxy class rather than `set_meta(&"villager_id", …)`: the picker resolves
`intersect_ray()`'s `collider` to `VillagerHitProxy` and reads a typed `int`,
which honours the project's static-typing standard and is greppable.

**On the manifest question — ruled explicitly, because it was raised.** There is
**no violation and no new exception**. The manifest's physics prohibitions are
scoped by their own text to *block/world* picking:

- line 89: "Zero physics API calls in **Building System's** pick path";
- line 98: "Zero `PhysicsServer3D`/`RayCast3D` in any picking path
  (**Voxel World AND Building System**, grep-verifiable)".

Villager hit-testing is separately and affirmatively **required** by the same
manifest — line 64 (villagers carry a child `Area3D` + `CollisionShape3D`,
layer 1, mask 0), line 82 (the layer convention), line 152 (the click pick:
DDA block distance + `intersect_ray()` with `collision_mask = 1`,
`collide_with_areas = true`, `collide_with_bodies = false`, nearest wins,
villager wins within `pick_tie_epsilon`), and line 219 (the
`PhysicsRayQueryParameters3D` default-flags trap). ADR-0004 Decision §2 is the
source. The two picks are structurally disjoint by construction: Building
System's placement pick issues **zero** physics queries and is therefore
*incapable* of hitting a villager, which is what `TR-villager-info-ui-014`
actually asks for.

**The data-layer alternative was considered and rejected on reversibility, not
on merit.** At 30 villagers, a GDScript ray-vs-AABB sweep over the roster using
`get_visual_position()` would be cheap, physics-free, and manifest-purist. But
ADR-0004 is **Accepted**, `TR-villager-info-ui-014` requires a "dedicated
villager collision layer" *by name*, the control manifest encodes the layer
convention project-wide, and `villager-info-ui-002`'s ACs are written to it.
Overturning that costs an ADR supersession, a TR rewrite, a manifest revision and
a story rewrite, and buys a saving of roughly nothing at this entity count.
Against that, `Area3D` extends cleanly to the Squad & Combat hitboxes the layer
convention already reserves layers 2–8 for. **Keep ADR-0004. Do not introduce a
data-layer villager pick.** If someone later wants to remove physics from the
project entirely, this is the one call site to change — record it as the single
physics dependency it is.

#### 5. Slice View — the hook that un-vacuates `building-ui-016`

The view exposes `set_slice_level(level: int) -> void` and applies
`visible = ai.get_current_cell().y <= level` (the discrete cell, not the
interpolated one — a villager must not flicker in and out mid-lerp at the cutoff
boundary). Building UI owns the level; the view receives it and owns no copy of
it beyond the last value pushed.

**Two clauses the naive form gets wrong and the story must carry as ACs:**

- **Hiding must disable the hit proxy.** Godot does *not* disable an `Area3D`'s
  collision when an ancestor's `visible` goes false. Without an explicit
  `collision_layer = 0` while hidden (restored to 1 when shown), a sliced-away
  villager stays clickable — a direct violation of `building-ui-016`'s "a cell
  hidden by the cutoff cannot become a NEW hover target or Selection target".
- **Hiding must not touch Selection.** `building-ui-016` AC65 requires that
  slicing away the *currently selected* villager leaves Selection intact
  (Selection is UI state, not render state). The view therefore never reads,
  writes or signals Selection. It only stops rendering and stops being pickable.

`building-ui-016`'s "characters" clause stops being vacuous the moment this
lands; its AC can then be asserted against a real renderable instead of a mock.
Note this does **not** resolve `building-ui-016`'s *other* blocker (the shared
voxel material's clip-plane uniform vs. per-chunk re-mesh) — that is a separate
technical-director + `godot-shader-specialist` decision and is untouched here.

#### 6. Anchors and affordances — surfaces only, treatments later

The view carries a named child `Node3D` **`IconAnchor`** at the top of the 2-cell
figure (local y ≈ 2.0 plus a small clearance), which `villager-info-ui-005`'s
billboard manager parents to or reads a world position from. And it exposes a
seam `set_highlight(mode: HighlightMode) -> void` (`NONE` / `HOVER` / `SELECTED`)
whose M02 implementation may be as crude as a material tint. The actual outline
mechanism is `villager-info-ui-006` + `godot-shader-specialist` and is
deliberately **not** decided here — this story owes those stories a stable
surface to bind to, not a finished treatment.

**ADR home**: ADR-0004 gains a Decision clause naming `VillagerBodyView` as the
`Area3D`'s host (it currently says "each villager instance carries a child
`Area3D`", which was written when nobody had decided what a villager *instance*
was at the node level). ADR-0009 gains the `get_visual_position()` accessor and
the re-scoped grep guard. **No new ADR** — both are amendments to Accepted ADRs
whose decisions this ruling implements rather than changes.

---

## VB-2 — Story specification: villager body view & hit proxy

*Spec only. The producer authors the story file; I have not written one.*

| Field | Value |
|---|---|
| **Epic** | `presentation-experience` (Presentation layer, Art-Bible-governed) |
| **Story id** | `presentation-003` |
| **Suggested title** | Villager body view, hit proxy & slice hook — the substrate three epics are blocked on |
| **Type** | Integration |
| **Tier** | **CORE** (it is a hard blocker for four stories across two other epics) |
| **Estimate** | **1.0 agent-day** |
| **Suggested owner** | `godot-specialist` (scene/`Node3D`/`Area3D` work), with `godot-gdscript-specialist` review on the `.gd` files |
| **Source doc** | `design/art/art-bible.md` §5.2 (2-block scale) + §5.3 (accent channel), same GDD-less precedent the epic already uses |
| **Governing ADRs** | ADR-0004 (`Area3D` hit-test, layer 1) · ADR-0009 (two-layer position model, `physics_interpolation_mode = OFF`) · ADR-0001 (injected-tier `setup()`, duck-typed nil-safe providers) |
| **Manifest version** | 2026-07-23 |

**Why `presentation-experience` and not the two obvious alternatives.**
Not `villager-ai-behavior`: that is a Core-layer simulation epic, and putting a
mesh story in it is precisely the layering inversion §1 of VB-1 rejects. Not
`villager-info-ui`: that epic's own Known Conflict 1 says outright *"it is not a
UI story's job to fix"*, and the body has three consumers (Villager Info UI,
Building UI's Slice View, and this epic's own ambient-life idle behaviors) — a
shared substrate owned by a leaf UI epic will be scoped to that leaf's needs.
`presentation-experience` already owns `src/presentation/`, is already
Art-Bible-governed, and its own `presentation-001` Sub-B ("villager idle
behaviors") is *invisible without this story*.

### Sequencing

```
villager-ai-026 → villager-ai-021 → presentation-003 → ┬→ villager-info-ui-002 → 005 → 006
                  (roster is plural)                    ├→ building-ui-016 (characters clause)
                                                        └→ presentation-001 Sub-B (idle behaviors)
```

- **After `villager-ai-021` (starting roster spawn) — hard, for the integration
  AC only.** 021 is what turns "one hard-wired `VillagerAi` node in `Valley.tscn`"
  into a spawned, enumerable roster with a lifecycle; the presenter's
  create/free loop is written against exactly that. Authoring it first would mean
  writing the presenter against a single hard-coded node and rewriting it a
  sprint later.
- **But not *blocked* by 021 for development.** The roster provider is duck-typed
  and nil-safe, so every unit AC is testable against a mock roster today; only the
  end-to-end "N villagers spawn, N bodies appear, one despawns, one body frees"
  AC needs the real 021.
- **Before `villager-info-ui-002/005/006`** — all three are blocked on it outright
  (hit query, icon anchor, hover/outline).
- **Before `building-ui-016`** — for the "characters" half of the cutoff only;
  016's shader/clip-plane blocker is independent and still open.
- **Before `presentation-001` Sub-B.** This re-orders within its own epic:
  Sub-B (villager idle behaviors) is currently deferred to S10/S11 per sprint-09
  Cluster B, so the ordering costs nothing — but the producer should record that
  Sub-B now has an in-epic prerequisite it did not have before.
- **Sprint fit**: not an S09 Must (nothing in S09 consumes it), but it is the
  cheapest thing that unblocks the largest number of S10/S11 stories. Recommend
  **S10, early**, immediately after 021 lands.

### Acceptance criteria

**Blocking (headless unit tests, `neues-spiel/tests/unit/presentation/`):**

- [ ] `VillagerAi.get_visual_position() -> Vector3` exists, returns the same value
      `_visual_position` holds after a `_process` frame, and **`VillagerAi` still
      `extends Node`** — asserted, not assumed. Every pre-existing villager-ai
      test passes with **zero test edits**.
- [ ] `VillagerBodyView` is headless-instantiable via `Node3D.new()` + a mock
      `ai_source`; a `null` `ai_source` is inert, not a crash.
- [ ] The view stores **no** position of its own and performs **no**
      interpolation: grep proves zero `lerp(` in `villager_body_view.gd`, and the
      view's `global_position` after a frame equals `ai_source.get_visual_position()`
      exactly (not approximately).
- [ ] `physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF` on the
      view, set explicitly in code (manifest line 71 / ADR-0009 mitigation).
- [ ] The view carries a `VillagerHitProxy` (`Area3D`) with `collision_layer == 1`,
      `collision_mask == 0`, `monitoring == false`, and a `villager_id` matching
      its view's.
- [ ] A `PhysicsRayQueryParameters3D` query with `collision_mask = 1`,
      `collide_with_areas = true`, `collide_with_bodies = false` aimed at a
      positioned view **hits** and resolves to the correct `villager_id`; the same
      query with `collide_with_areas` left at its default **misses** (this second
      half is the regression guard for manifest line 219's documented trap — write
      it, it will save someone a day).
- [ ] Body height spans **exactly 2 cells** (Art Bible §5.2), asserted against the
      mesh AABB, not eyeballed.
- [ ] `set_slice_level(y)`: given a villager whose `get_current_cell().y > y`, the
      view is `visible == false` **and** its hit proxy's `collision_layer == 0`;
      restoring the level restores both. The visibility test uses the **discrete**
      cell, not the interpolated position.
- [ ] The view never reads, writes or emits anything Selection-related — grep
      proves zero references to Selection APIs (`building-ui-016` AC65's
      precondition).
- [ ] `IconAnchor` exists as a named child `Node3D` at the top of the figure and
      its world position tracks the body every frame.
- [ ] `set_highlight(NONE|HOVER|SELECTED)` exists and is observable (a state
      getter is enough); the treatment itself is out of scope.
- [ ] `VillagerBodyPresenter.setup()` is explicitly callable, asserts nothing it
      does not need, registers no Autoload, and creates exactly one view per
      roster entry from a **mocked** roster provider; a removed villager's view is
      freed.
- [ ] Grep proves the presentation module makes **zero** mutating calls into
      `VillagerAi` (pure-mirror invariant, same bar as the UI epics).

**Integration (needs real `villager-ai-021`):**

- [ ] With `starting_villager_count = N`, booting `Valley.tscn` produces exactly
      N visible bodies at the spawned villagers' positions, and the simulation's
      tick results are byte-identical to a run with the presenter absent
      (presentation adds no simulation — the epic's founding constraint).

**Advisory (`production/qa/evidence/`):**

- [ ] Screenshot: a villager standing on terrain at settlement-camera distance,
      readable as a 2-block figure. Screenshot: the same villager sliced away at a
      cutoff below its cell.

### Explicitly out of scope

Art-bible-faithful geometry (limb blocks, 45:55 head weight, profession gold
trim, §5.3 individuation palette, §5.6 behavioral tells) · the outline/hover
*shader* (`villager-info-ui-006`) · the distress billboard itself
(`villager-info-ui-005` — this story provides only the anchor) · the Slice View
clip-plane mechanism for world geometry (`building-ui-016`, still undecided) ·
villager names (a tone call, sprint-09 D5) · animation of any kind.

---

## PD-1 — `PayoffDetail`: `RefCounted` stands; the `@export` finding does not apply

**Verified.** The Sprint 8 finding is real and correctly recorded
(`sprint-08.md:291` — "Godot 4.7 cannot `@export` `RefCounted`/`Object`"), and
the landed workaround is real: every injected dependency in the codebase that
would otherwise have been `@export`ed is a plain duck-typed `var`
(`villager_ai.gd:474` `var needs_provider: Object = null`, `:489`
`var job_queue: Object = null`, `:461`
`var scheduler: VillagerDecidingScheduler = null`). Also verified: the landed
`LoopPayoffSignalSurface` (`src/presentation/loop_payoff_signal_surface.gd`) has
`signal payoff_signaled(payoff_type: StringName, subject: StringName)`,
`func emit_payoff(payoff_type, subject) -> void`, and
`var _active_payoffs: Dictionary[String, bool] = {}` keyed via `_make_key`.

### RULING

**The collision is a false alarm. `PayoffDetail` is a `RefCounted`, exactly as CD
Ruling 2 specifies, and no `@export` is involved anywhere on this path.**

`@export` governs one thing only: fields assigned from the editor inspector or
persisted into a `.tres`. `PayoffDetail` is none of those. It is **constructed at
emit time, passed as a method parameter, held in a runtime `Dictionary`, and read
synchronously by the handler in the same call stack**. It is not config (ADR-0002
config is `@export`ed on a `Resource`; this is not config), it is not injected
(ADR-0001's DI surface is where the `@export` workaround applies; this is not a
dependency), and it is **never serialized** (ADR-0012 — payoff state is transient
presentation state). The S8 finding and CD Ruling 2 do not intersect.

**Concrete form — `neues-spiel/src/presentation/payoff_detail.gd`:**

```gdscript
class_name PayoffDetail
extends RefCounted

var celebrate: bool = false
var group_id: StringName = &""
var subjects: Array[StringName] = []
var cells: Array[Vector3i] = []
var sheltered: bool = false
```

**One substitution from CD's sketch, which CD's scope note explicitly permits
("geometry handle vs inline cells"): `cells` is `Array[Vector3i]`, not
`PackedVector3Array`.** Cells are `Vector3i` everywhere else in this codebase
(`construction_completed_batch(cells: Array[Vector3i])`,
`bulk_write`, `raycast_cells`); `PackedVector3Array` would force a float
conversion at the producer and back at the consumer, and would make CD's
condition-4 QA ("the detail's cells equal the recognized region's cells as of the
emitting pass") an approximate comparison instead of an exact one. Exactness is
the point of that assertion.

**Surface changes on `LoopPayoffSignalSurface` — all additive:**

```gdscript
signal payoff_signaled(payoff_type: StringName, subject: StringName)   # UNCHANGED, byte-identical

func emit_payoff(payoff_type: StringName, subject: StringName,
                 detail: PayoffDetail = null) -> void                   # trailing optional
func get_payoff_detail(payoff_type: StringName, subject: StringName) -> PayoffDetail

var _payoff_details: Dictionary[String, PayoffDetail] = {}   # same _make_key as _active_payoffs
```

A trailing default parameter is source-compatible: every landed caller and every
landed test of `emit_payoff` compiles and behaves unchanged. **Confirmed against
CD's constraints 1–4:**

1. **Ordering** — `_active_payoffs[key]` **and** `_payoff_details[key]` are both
   written **before** `payoff_signaled.emit(...)`, so a synchronous handler
   calling `get_payoff_detail()` from inside the handler sees the current record.
   Non-negotiable; assert it with a handler that reads during the emit.
2. **`clear_payoff()` erases both** — one key, two dictionaries, no orphans.
   Assert `get_payoff_detail()` returns `null` after a clear.
3. **No `CONNECT_DEFERRED`** on this path — promote to an asserted grep-guard over
   `src/presentation/` and the consumer, as CD asked.
4. **No back-reference into the analysis module** — preserved. To disambiguate
   something story-009's current text can be misread on: *"loses the back-query"*
   means presentation never re-queries **Build Validation**. It does **not** mean
   `get_payoff_detail()` is dropped. Because the signal's parameter list is frozen
   byte-identical, the accessor on the surface is the *only* way the detail can
   reach a handler, and constraint 1 is precisely what makes that read safe.
   Keep it.

**One engine-risk item for the implementer, and it is cheap.** A typed
`Dictionary` whose **value type is a script class** (`Dictionary[String, PayoffDetail]`)
is supported from 4.4, but 4.7 is post-cutoff and the landed code only exercises
`Dictionary[String, bool]`. Make story-009's **first** step a 2-minute parse check.
If the 4.7 parser rejects it, fall back to an untyped-value `Dictionary` with an
explicit `as PayoffDetail` cast at the single read site, and record which form was
used in the commit body. Either way the story is unambiguous — this is the whole
point of ruling it now.

**Why not `Resource`** (the substitution CD pre-authorised): `Resource` is
`@export`-able, but nothing here needs to be `@export`ed, so the only reason to
pay for it is absent. Against it: `Resource` carries path/UID/`ResourceLoader`
caching semantics that make a transient per-event value object look like
authorable on-disk content, colliding with ADR-0006's "definitions are immutable,
loaded from disk" framing; and it puts accidental serialization one
`ResourceSaver.save()` away from a thing ADR-0012 says must never be saved.
`RefCounted` frees deterministically when the last reference drops, which is the
correct lifetime for a record whose whole life is bounded by `clear_payoff()`.

**All six of CD's minimums remain assertable under this form** — nothing in
conditions 1–5 depends on the class's base type; condition 1 counts live keys
(`get_active_payoff_count()`) and reads `detail.subjects.size()`, condition 4
reads `detail.cells`. Condition 6 is the playtest and is unaffected.

**TD concurrence with CD Ruling 2 is hereby given**, subject to user ratification
of both documents. `build-validation-009` (S10) has no remaining open input from
this side.

**ADR home**: none. This is an implementation-form ruling inside an existing
module contract, not an architectural decision.

---

## Summary of downstream actions this addendum creates

| # | Action | Owner | Blocks |
|---|--------|-------|--------|
| 10 | ✅ **DONE** — `architecture.md` documents `has_urgent_need(villager_id) -> bool` + its purity guarantee (4 edits) | technical-director | *was* `needs-mood-002` — now clear |
| 11 | **New story `presentation-003`** (villager body view, hit proxy, slice hook) — spec in VB-2, file not written | producer | `villager-info-ui-002/005/006`, `building-ui-016` characters clause, `presentation-001` Sub-B |
| 12 | ADR-0004 amendment: name `VillagerBodyView` as the `Area3D`'s host node | technical-director | nothing |
| 13 | ADR-0009 amendment: add the `get_visual_position()` presentation accessor; **re-scope the `_visual_position` grep guard** from a filename check to a call-site allowlist (`villager_ai.gd::_process` + `src/presentation/`) — the invariant it protects is unchanged and stays enforced | technical-director | `presentation-003` (its grep AC needs the new guard wording) |
| 14 | Control manifest: add `VillagerBodyView`/`VillagerHitProxy` as the concrete host for the existing line-64/71/152 rules (they currently describe a node that does not exist) | technical-director | nothing |
| 15 | `build-validation-009` spec update: `PayoffDetail` = `RefCounted`, `cells: Array[Vector3i]`, `Dictionary[String, PayoffDetail]` with a parse-check first step; `get_payoff_detail()` is **kept** (the dropped back-query was into Build Validation, not the surface) | producer / build-validation | nothing (S10 story) |
| 16 | Producer note: `presentation-001` Sub-B (villager idle behaviors) now has an in-epic prerequisite (`presentation-003`) it did not have when it was deferred to S10/S11 | producer | nothing |
| 17 | Still open, **not** ruled here: `building-ui-016`'s clip-plane-uniform vs. per-chunk-re-mesh mechanism (TD + `godot-shader-specialist`); target hardware class + VSync mode (sprint-09 D4); villager names (D5, creative-director) | technical-director / creative-director | `building-ui-016`, `villager-info-ui-003` |

---

# Addendum D — Mesh invalidation (D7) and the boot-scoped mesh radius

**Status: PROVISIONAL — pending user ratification.** Both rulings below are
technical-director decisions taken against the code as it stands on `main`
(65bc05b). Neither has been implemented; no production code was changed.

## D7 — Mesh invalidation: the escalated premise is FALSE

**Verdict: REJECT the premise as stated. RE-SCOPE the story.**

The escalation states that *"`VoxelWorldMeshStreamer` subscribes to NO grid
signal, so a chunk already inside the window is never re-meshed"* and concludes
that *"a block the player places is written to the grid and never appears."*
scene-005's Control Manifest Guardrail repeats this as verified fact.

The verification behind it — *"zero occurrences of `cells_changed_batch` in
`voxel_world_mesh_streamer.gd`"* — is true about that **file**. The conclusion
drawn from it is not. The invalidation path exists one layer down:

- `voxel_world_mesher.gd:163-164` — `setup()` connects **both**
  `grid.cell_changed` and `grid.cells_changed_batch`.
- `_on_cell_changed` / `_on_cells_changed_batch` → `_chunk_keys_touched_by()`
  → `build_chunk()` for every **tracked** touched chunk, deduped.
- `_chunk_keys_touched_by()` already dirties the **cross-chunk X/Z neighbour**
  when the cell sits on a chunk seam — the exact counterpart to
  `_is_chunk_local_air()` case 3, which resolves a seam face through
  `_is_air()`/`get_cell()` against the neighbour chunk. This is correct and
  must not be touched.
- `setup()` is genuinely reached in production: `Valley.get_injected_tier_modules()`
  returns `_voxel_world_mesher`, and `GameWorld._setup_injected_tier()` calls
  `setup()` on every entry.
- The write path is live end-to-end: `CommitPipeline` → job → `ConstructionTickLoop._on_tick`
  (connected to the `TimeTickSystem` autoload in its own `setup()`) →
  `voxel_world.bulk_write(changes)` → `cells_changed_batch` → mesher rebuild.

So the streamer subscribing to nothing is **correct layering**, not a bug: the
mesher owns chunk *content*, the streamer owns chunk *membership*. Adding a
streamer subscription would duplicate `_chunk_keys_touched_by()` and
double-rebuild every dirty chunk.

Two of the escalation's sub-questions dissolve on inspection:

- **"What happens to a dirty chunk that is currently unloaded?"** Nothing, and
  nothing is needed. `build_chunk()` always reads *current* grid state, so a
  chunk re-entering the window is correct by construction. No dirty-set
  persistence across unload. Pin this with a test; do not build bookkeeping for it.
- **"Must neighbour chunks of a boundary cell also be dirtied?"** Yes, and they
  already are. Keep `_chunk_keys_touched_by()` unchanged; add a regression test.

### What IS actually broken (two real defects)

**Defect 1 — the rebuild is unbudgeted and synchronous inside the signal
handler.** `_on_cells_changed_batch` rebuilds every touched tracked chunk in one
pass, on the main thread, with no time budget. At the measured **7.7 ms/chunk**
(vox-019), a demolition or a large floor commit spanning 9 chunks is a ~69 ms
frame spike. This violates the control manifest's "no unbounded work in the
frame path". This is the real D7 bug: a *performance* bug, not a correctness one.

**Defect 2 — residency page-in emits no signal, so an early-meshed chunk is a
permanent hole.** `VoxelWorldGrid` has exactly three emit sites (`set_cell` 1036,
`bulk_write` 1090, `_apply_pending_writes` 1191). Neither
`_integrate_one_finished_read` (1651) nor `_try_serve_from_in_flight_write`
(1556) emits anything when a chunk becomes resident. `get_chunk_snapshot()`
returns `null` for a non-resident chunk and `build_chunk()` writes `.mesh = null`.
The mesh window and the residency window share the same `view_radius_chunks`, so
in steady state a chunk routinely enters the mesh window before its async,
budgeted page-in lands — and then **never re-meshes**. This is the more likely
cause of any "terrain/blocks missing" symptom actually observed in game, and it
is the hole class scene-005's guardrail was reaching for.

### Ruling

1. The streamer continues to subscribe to **nothing**. Layering confirmed.
2. `VoxelWorldMesher`'s two handlers change from *rebuild now* to *mark dirty
   now* — a private `_dirty_chunks: Dictionary[Vector2i, bool]`, populated only
   for keys already in `_chunk_nodes`. Expose `get_dirty_chunk_keys()` and
   `clear_dirty(key)`; `unload_chunk()` erases the key from the dirty set.
3. `VoxelWorldGrid` gains `signal chunk_became_resident(chunk_key: Vector2i)`,
   emitted from `_integrate_one_finished_read` and
   `_try_serve_from_in_flight_write` after `_chunks[chunk_key]` is assigned. The
   mesher subscribes and marks the key dirty if tracked. This closes Defect 2
   through the same machinery, with no second mechanism.
4. `VoxelWorldMeshStreamer._sync_window` gains a **rebuild phase, drained first**,
   before the build-new phase and before the unload phase, through the existing
   `_drain_budgeted`.
5. **Budget: reuse `mesh_build_budget_ms` as ONE shared window covering
   rebuild-then-build. No new knob.** Rationale: an independent rebuild budget
   would let the progress guarantee integrate one chunk in *each* phase — worst
   case 7.7 + 7.7 = 15.4 ms of meshing in a 16.6 ms frame, which would regress
   vox-019's measured p95 of 16.947 ms. A shared window keeps the worst case at
   exactly one chunk per frame, i.e. today's measured profile, while giving the
   player's own edit priority over a distant window-edge chunk.
   `mesh_unload_budget_ms` keeps its own separate window (different work class —
   `queue_free`, not meshing). `build_initial_window` passes unbounded to the
   rebuild phase too; the dirty set is empty at boot regardless.
6. Latency cost: at most one frame for a single-block placement (the progress
   guarantee always integrates one dirty chunk per call). Imperceptible, and the
   same guarantee entry-meshing already ships.

Residual risk, accepted and named: a multi-chunk demolition now settles over
~1 chunk/frame instead of one spike — ~9 frames for a 9-chunk edit. The real
lever is the 7.7 ms per-chunk cost; greedy meshing remains ADR-0014's named
optimisation reserve and is **not** in this story.

**ADR home**: ADR-0014 amendment (Decision §2 gains the dirty-set/budgeted-drain
contract; §3 gains the rebuild phase's ordering and shared-window rule). ADR-0015
amendment for the new `chunk_became_resident` signal on the residency tier.

## D2 — Boot-scoped mesh radius

**Verdict: APPROVE a boot-scoped radius, but the radius is not the whole
problem — `view_radius_chunks = 24` is unaffordable at boot AND in steady state.**

Arithmetic at the measured 7.7 ms/chunk, `CHUNK_SIZE` 16, `CELL_SIZE` 1.0:

| Radius | Chunks | Mesh cost | Visible extent |
|---|---|---|---|
| 24 (current) | 49x49 = 2401 | **18.5 s** | 384 u |
| 12 | 25x25 = 625 | 4.8 s | 192 u |
| 8 | 17x17 = 289 | 2.2 s | 128 u |

The decisive point the escalation does not state: **shrinking only the boot
radius moves the cost, it does not remove it.** `_collect_window` uses
`view_radius_chunks`, so `update_view_window` grows the window back to full
every frame at ~1 chunk/frame (7.7 ms/chunk exceeds the 4.0 ms budget, so the
progress guarantee yields exactly one). Booting at radius 8 while
`view_radius_chunks` stays 24 trades an 18.5 s freeze for **~35 s of visible
pop-in** — strictly worse for playability.

### Ruling

1. **`VoxelWorldConfig.view_radius_chunks: 24 -> 12.`** A pure `.tres` data
   change (scene-005's own lever #2), instantly reversible, no code. This is the
   knob that makes the steady-state window actually maintainable at the current
   mesher cost. `visibility_range_end` is derived from it, so the distance fade
   stays consistent automatically.
2. **New `VoxelWorldConfig.boot_mesh_radius_chunks: int = 8.`** Consumed *only*
   by `build_initial_window`, threaded as a radius parameter into the existing
   `_collect_window` — no new state, no timer, no camera-move trigger, no second
   code path. Validated in `validate()` against new
   `BOOT_MESH_RADIUS_CHUNKS_MIN/MAX` (2 / `VIEW_RADIUS_CHUNKS_MAX`), plus a
   clamp+warn (non-BLOCKING, ADR-0002 two-tier) when it exceeds
   `view_radius_chunks`.
3. **Growth to full: over frames, via the already-budgeted `update_view_window`.
   No new mechanism.** Filling 289 -> 625 = 336 chunks at ~1 chunk/frame ≈ **5.6 s**
   of gradual fill, during which the player is already interactive — this is the
   correct place to spend it, not in a frozen boot window.
4. ADR-0005 holds unchanged: `build_initial_window` still runs inside WIRING,
   strictly before `ACTIVE`, only with a smaller radius. No sync I/O and no
   unbounded frame work is introduced — the growth path is the existing budgeted
   step.
5. **Boot budget (closes scene-005 Open Decision #1): total boot-to-ACTIVE
   ceiling 3.0 s, of which the initial mesh phase <= 2.5 s.** This replaces the
   producer's provisional 5 s. Rationale: this codebase has no boot loading
   overlay (`game_world.gd`'s own honest note), so boot is a frozen window, and
   ~3 s is the threshold above which a frozen window reads as a hang. Projected
   mesh phase under this ruling: ~2.2 s. PASS with headroom.

**Knobs named**: `view_radius_chunks` (retuned 24 -> 12),
`boot_mesh_radius_chunks` (new, default 8), `mesh_build_budget_ms` (unchanged
at 4.0, now a shared rebuild+build window).

## Corrections this addendum files

- **scene-005 Control Manifest Guardrail** — *"`VoxelWorldMeshStreamer`
  subscribes to nothing and has no invalidation path"* is **incorrect**. The
  invalidation path lives in `VoxelWorldMesher.setup()`. The real hazard is
  Defect 2 (page-in emits no signal), which the guardrail's boot-ordering rule
  mitigates at boot but not in steady state. Reword.
- **scene-005 Open Decision #4** (*"mesh invalidation has no owner"*) — closed by
  story `vox-020`.
- **`TR-voxel-world-026`'s "~2.6 s initial view-window mesh build"** — confirmed
  stale (ADR-0014 prototype figure). Correct to ~2.2 s at the newly-ruled
  `boot_mesh_radius_chunks = 8`, and note the 18.5 s figure applied to the
  now-superseded radius 24.

## Summary of downstream actions this addendum creates

| # | Action | Owner | Blocks |
|---|--------|-------|--------|
| 18 | **New story `vox-020`** (mesh invalidation budgeting + `chunk_became_resident`) — spec in D7, file not written | producer | `scene-005` |
| 19 | **New story `vox-021`** (boot-scoped mesh radius + `view_radius_chunks` retune) — spec in D2, file not written | producer | `scene-005` AC-BOOT-BUDGET |
| 20 | ADR-0014 amendment: dirty-set + budgeted rebuild drain (§2), rebuild phase ordering + shared budget window (§3), boot-scoped initial radius (§3) | technical-director | `vox-020`, `vox-021` |
| 21 | ADR-0015 amendment: `chunk_became_resident` signal on the residency tier | technical-director | `vox-020` |
| 22 | `scene-005` edits: reword the Guardrail, close Open Decision #4, adopt the 3.0 s boot ceiling in AC-BOOT-BUDGET, drop lever (1) (now pre-applied by `vox-021`) | producer | `scene-005` |
