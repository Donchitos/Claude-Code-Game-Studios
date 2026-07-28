# Story 006: Shelter classification & `shelter_status_changed`

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1115/1115 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-029`, `TR-build-validation-navigability-036`, `TR-build-validation-navigability-030`, `TR-build-validation-navigability-058`, `TR-build-validation-navigability-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (room analysis); ADR-0001 (signal/reference boundary — Needs & Mood is a downstream consumer, no back-calls)
**ADR Decision Summary**: Build Validation's outputs are `shelter_status_changed`, room/warning events, and queryable state — a one-way boundary. It supplies only the sheltered/unsheltered classification; the recovery **rate values** stay owned by the Needs & Mood source→rate table.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Signal emissions are synchronous by default — AC16 asserts an **emission count of 1 per transition**, not a consumer count. Multiple `connect()` calls on one signal do not multiply emissions; write the test to count emits at the source.

**Control Manifest Rules (this layer)**:
- Required: the sheltered flag is this system's one mechanical output; Needs & Mood consumes it and owns the rate values.
- Forbidden: emitting `shelter_status_changed` on a non-transition (level-triggered re-emission belongs to the Warning/Info tiers only); embedding recovery multipliers in this module beyond the config knob's advisory check (story 001).
- Guardrail: exactly one emission per transition, for ALL furniture types.

**NARROWED — `building-028` is still needed, but only for per-item enumeration,
and this story may be developed against a mock** (was Epic Known Conflict 1).
Technical-director ruling **BV-1**,
`production/architecture-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL,
pending user ratification** (away-mode ruling; treat as the planning assumption
until ratified).

**Ruling: furniture is not voxel data — it lives in a Building-System-owned
furniture registry keyed by placed-item identity** (item id, occupied cells from
`ItemDefinition.get_footprint()`, definition id). The seam Build Validation
injects is **that registry**, not a cell predicate: a duck-typed, **nil-safe**
`Object` dependency (landed precedent: `VillagerAi.needs_provider` / `job_queue` /
`population`) exposing an enumeration of placed furniture records plus a
placed/removed signal. A `null` provider means "no furniture exists" — correct and
non-crashing, and exactly true until `building-028` lands.

**What this story still needs from `building-028`**: **per-item enumeration only**
(the item-id → cells mapping it classifies) and the placed/removed signal that is
this module's second trigger (BV-2). Everything else — transparency to the
structural analysis — is satisfied by construction in story 002 and needs no
furniture code at all.

**Development sequencing**: build and test this story **against the mocked
provider**, then un-mock when `building-028` lands. It is no longer a hard
schedule blocker on Cluster A's critical path; the blocker moved onto
`building-028`'s own AC list (its blocking AC: a completing FURNITURE-category job
never `bulk_write`s to the grid, with a regression test asserting
`voxel_world.get_cell()` is empty at that cell).

**"Need-functional" is Build Validation's own data-driven config knob**, not a new
`ItemDefinitionResource` field: a typed `@export` list of need-functional
categories/ids (ADR-0002) resolved through `ResourceItemDatabase.get_by_id(...)`.
**Do not hardcode `&"bed"`.**

**This story is the payoff-chain unblocker.** `shelter_status_changed` is the
single output the needs-mood epic consumes (milestone criteria #3/#5). Land it
before the presentational stories (007/008), which nothing downstream is waiting
on.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] A piece of furniture is **sheltered** iff its cell lies inside a valid room; otherwise it is **unsheltered**. This flag is this system's one mechanical output. [TR-029]
- [ ] The `shelter_status_changed` signal carries `(item id, sheltered: bool)` and fires when a furniture item's sheltered flag **transitions** — exactly one emission per transition, for ALL furniture types. [TR-036]
- [ ] **AC12**: **GIVEN** a bed inside a valid room, **WHEN** classified, **THEN** it is sheltered. [TR-029]
- [ ] **AC13**: **GIVEN** a roof hole opening above that bed's cell, **WHEN** re-analyzed, **THEN** the bed flips to unsheltered (Edge Case 7). [TR-058]
- [ ] **AC14**: **GIVEN** a bed in a sealed region, **WHEN** classified, **THEN** it is unsheltered (a sealed "room" shelters no one — States table). [TR-029]
- [ ] **AC15**: **GIVEN** a bed exactly under the roof edge vs. one cell outside it, **WHEN** analyzed, **THEN** the former is sheltered and the latter is not — purely a function of its own cell's candidate status (Edge Case 8). [TR-029]
- [ ] **AC16**: **GIVEN** a shelter-status change, **WHEN** it occurs, **THEN** exactly one `shelter_status_changed` signal is emitted per transition — Needs and UI subscribe to the same emission (assert emission count = 1, not consumer count). [TR-036]
- [ ] The sleep recovery ladder consumes the flag: **sheltered bed = 1.0 · unsheltered bed = `unsheltered_bed_multiplier` (0.7) · ground = `ground_penalty` (0.4)** — the rate values remain owned by the Needs & Mood source→rate table; this system supplies only the classification. [TR-030]
- [ ] Per-item shelter flags are part of the transient snapshot (story 005) so transitions are edge-detected; a re-analysis that leaves a flag unchanged emits nothing.
- [ ] Items are enumerated **only** through the injected, duck-typed furniture-registry provider (BV-1). A `null` provider yields zero items, zero emissions, and no error — the whole story is exercisable headless against a mock, with no `building-028` code present.
- [ ] "Need-functional" furniture is resolved from a typed config list of categories/ids via `ResourceItemDatabase.get_by_id(...)` — **no hardcoded `&"bed"`**, and no new field on `ItemDefinitionResource` (BV-1 §6).
- [ ] Furniture occupancy is never read from `CellContents` — grep-asserted. Under BV-1 furniture is never in the grid, so a `CellContents`-derived furniture check would be reading a value that structurally cannot exist.

---

## Implementation Notes

*Derived from ADR-0007/0001 Implementation Guidelines:*

- Classification is a pure lookup: the item's cell → its region (story 003) → that region's verdict (story 004). Sheltered iff the verdict is Room. No separate geometry.
- Edge Case 8 falls straight out of Rule 1: an item's shelter status follows **its own cell's** candidate status and region membership — never a bounding-box or "near a room" heuristic.
- Furniture occupancy stays transparent to the structural analysis (story 002, TR-022): the bed does not make its own cell non-candidate. That is what gives AC15 a well-defined answer.
- Edge-detection is against the previous snapshot's per-item flag map (story 005). Emit on transition only; do **not** re-emit level-triggered — that semantic belongs exclusively to the Warning/Info tiers (story 008).
- On the load pass, `shelter_status_changed` is **silent** (statuses become queryable, no transition events) — story 008 carries the AC31 assertion; this story must implement the silencing hook, not just honour it by accident.
- Do not implement the rate multipliers. This module owns the boolean; Needs & Mood owns 1.0 / 0.7 / 0.4.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: `room_recognized` and its celebration pacing.
- Story 008: the sealed-space Warning and unsheltered Info tiers, their exclusivity, and AC35's decorative-furniture case.
- Needs & Mood epic: the source→rate table and the recovery formulas.

---

## QA Test Cases

- **AC12 / AC14**: bed in a valid room → sheltered; bed in a sealed region → unsheltered.
- **AC13**: open a roof hole above the bed's cell → re-analysis flips it to unsheltered, one emission.
- **AC15**: bed exactly under the roof edge → sheltered; one cell further out → unsheltered.
- **AC16**: with two consumers connected to `shelter_status_changed`, When one transition occurs, Then the source emission count is exactly 1.
- **No-transition silence**: Given a re-analysis that leaves every flag unchanged, When it completes, Then zero `shelter_status_changed` emissions.
- Edge cases: an item whose region merges into a valid room (flag flips, one emission); an item in a region that splits (flag re-evaluated against its own new region); a multi-cell furniture item — classification follows its own occupied cell(s) per Rule 5 (coordinate with `building-016`).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/shelter_classification_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004 (Room/Sealed verdict), 005 (pass + snapshot edge detection). **External, soft**: `building-028` for **per-item enumeration + placed/removed signal only** — develop and test against the mocked, nil-safe provider and un-mock later (BV-1). Not a hard start blocker.
- Unlocks: 008, 009; **unblocks the needs-mood epic's recovery-ladder stories and milestone criterion #5**

