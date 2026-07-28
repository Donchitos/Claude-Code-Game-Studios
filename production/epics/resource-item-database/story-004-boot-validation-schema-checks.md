# Story 004: Boot validation — per-entry schema checks

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-23 — 250/250 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-005`, `TR-resource-item-database-024`, `TR-resource-item-database-028`, `TR-resource-item-database-040`, `TR-resource-item-database-041`, `TR-resource-item-database-043`, `TR-resource-item-database-049`, `TR-resource-item-database-050`, `TR-resource-item-database-051`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — primary (validation pipeline + structured result); ADR-0005 — secondary (Failed = terminal, same severity model as config blocking-invariants)
**ADR Decision Summary**: Boot validation runs a per-entry check pipeline producing a STRUCTURED result (id, source file, violated check, offending field). Failed = terminal halt (one shared severity model, never a new scheme).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Assert on the structured validation result, never on log strings (dependency-injectable, headless-testable). Do not use `ConfigFile`/JSON — definitions are typed `.tres`.

**Control Manifest Rules (this layer)**:
- Required: config/definition `validate()` at boot; GDD-declared BLOCKING invariant → terminal boot-halt (RID Failed pattern) — one terminal-halt severity model reused, never a new one.
- Required: two-type split — validation reads the private `ItemDefinitionResource` authoring type.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] Validation runs the per-entry pipeline over all entries (GDD States/Transitions: Validating). [TR-resource-item-database-005]
- [ ] An id that is not valid snake_case (uppercase 6a / spaces 6b / hyphens 6c) halts boot naming the entry — each sub-case (GDD AC6). [TR-resource-item-database-024]
- [ ] Two entries with the same id halt boot naming BOTH entries AND both source files (GDD AC3). [TR-resource-item-database-040]
- [ ] An entry with an unknown category (4a) or unknown material_family value (4b) halts boot naming the entry (GDD AC4). [TR-resource-item-database-041]
- [ ] An entry missing a required field halts boot naming entry + field — tested for an always-consumed field (5a) AND an Alpha-deferred required-present field (5b) (GDD AC5). [TR-resource-item-database-028]
- [ ] A `building_material` with `material_family: none` (24a), or a non-building-material with a family set (24b), halts boot naming the entry (GDD AC24). [TR-resource-item-database-051]
- [ ] A negative or non-integer `tier` halts boot naming the entry (GDD AC23). [TR-resource-item-database-050]
- [ ] A stackable entry with `max_stack_size < 1` halts boot naming the entry (GDD AC20). [TR-resource-item-database-049]
- [ ] A non-stackable entry with `max_stack_size` authored succeeds SILENTLY — no warning (GDD AC21). [TR-resource-item-database-043]

---

## Implementation Notes

*Derived from ADR-0006 / ADR-0005 Implementation Guidelines:*

- Build the validation as a pipeline over entries; each check appends a structured record (entry id, source file, violated check, offending field) to the result — do not short-circuit on the first failure (aggregate reporting is proven in Story 005).
- snake_case check: reject uppercase, spaces, hyphens. Category/family are fixed enums (Core Rule 5) — reject free text.
- category↔family pairing: `building_material` requires a family from the Visual Direction Note set; every other category requires `none`.
- `tier` must be integer ≥ 0. `max_stack_size` ≥ 1 only WHERE `stackable`; on a non-stackable entry the field is ignored SILENTLY (a warning would be guaranteed noise since the field is required-present on every entry).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: reserved ids/category, retired ledger, tier-0 coverage, multi-error aggregate report, terminal Failed presentation.
- Story 006: `visual_asset` resolution validation.
- Story 008: `footprint` category-pairing / presence validation.

---

## QA Test Cases

- **AC-1 (snake_case)**: Given ids `WoodBlock` / `wood block` / `wood-block`; When booting; Then each halts naming the entry.
- **AC-2 (duplicate id)**: Given two entries sharing an id in two files; When booting; Then halt names both entries and both files.
- **AC-3 (unknown enum)**: Given an unknown category (4a) and unknown family (4b); When booting; Then each halts naming the entry.
- **AC-4 (missing field)**: Given a missing `display_name` (5a) and a missing `storage_category` (5b, Alpha-deferred); When booting; Then each halts naming entry + field.
- **AC-5 (pairing)**: Given a `building_material` with family `none` (24a) and a `furniture_fixture` with a family set (24b); When booting; Then each halts naming the entry.
- **AC-6 (tier)**: Given `tier = -1` and `tier = 1.5`; When booting; Then each halts naming the entry.
- **AC-7 (stack)**: Given stackable `max_stack_size = 0`; When booting; Then halt. Given non-stackable with `max_stack_size` set; When booting; Then boot succeeds with no warning.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/validation_schema_checks_test.gd` (GdUnit4) — asserts on the structured result records (never log strings); synthetic invalid fixtures; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (Autoload + Validating state must be DONE).
- Unlocks: Story 005, Story 006, Story 008.
