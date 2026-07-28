# Story 001: ItemDefinition two-type split + schema + getter-only immutability

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-23 — 13/13 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-010`, `TR-resource-item-database-048`, `TR-resource-item-database-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — primary
**ADR Decision Summary**: Two-type split — private `ItemDefinitionResource` (authoring, `@export`-editable) + public getter-only `ItemDefinition extends RefCounted` returned by `get_by_id()`, a fresh lightweight wrapper per call that WRAPS (never copies). `visual_asset` is a typed `Mesh` reference, never a path string. Never defensive-copy via `duplicate()`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `duplicate_deep()` (4.5+) exists but is deliberately AVOIDED — do not introduce it. `Object.get("/_private")` bypasses the getter-only pattern — the guarantee covers idiomatic misuse, not reflection (documented ADR-0006 residual risk). `load()` on a `.tres` returns the shared cached object.

**Control Manifest Rules (this layer)**:
- Required: private `ItemDefinitionResource` (`@export`-editable) + public getter-only `ItemDefinition extends RefCounted` (wraps, never copies); `visual_asset` is a typed `Mesh`, never a path string (ADR-0006).
- Required: multi-cell furniture adds a `footprint` field — the two-type split absorbs it structurally (Story 008 authors the validation).
- Forbidden: `ItemDefinition` has zero setters and zero writable `var`s; nothing outside RID holds an `ItemDefinitionResource`; cross-system references are opaque string ids only; never defensive-copy via `duplicate()`.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] Every entry carries the full schema — `id`, `display_name`, `category`, `material_family`, `tier`, `visual_asset`, `stackable`, `max_stack_size`, `haulable`, `storage_category`, and `footprint` (11 fields incl. the 2026-07-23 addition); a query returns each field exactly as authored (GDD AC2). [TR-resource-item-database-027]
- [ ] A definition returned by a query cannot be mutated by any idiomatic property/method (no such setter exists — enforced by the returned type's shape); a subsequent query for the same id returns the original authored values (GDD AC19). [TR-resource-item-database-010]
- [ ] A definition re-queried after intervening queries for other ids returns values equal to boot-time values — internal cache integrity, distinct from external-mutation resistance (GDD AC18). [TR-resource-item-database-048]

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

- `ItemDefinitionResource extends Resource` with typed `@export` fields for the full schema. `visual_asset` is `@export var visual_asset: Mesh` (typed reference), NOT a path string.
- `ItemDefinition extends RefCounted` wraps one `ItemDefinitionResource`, exposing getter-only accessors — zero setters, zero writable `var`s. `get_by_id()` returns a FRESH wrapper each call (cheap; wraps, does not copy).
- Do NOT `duplicate()` / `duplicate_deep()` — the wrapper's lack of setters is what makes sharing the underlying resource safe.
- Store the `footprint` field structurally now (Vector2i); its validation lands in Story 008.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Autoload load-once, Ready state, boot-gate signal.
- Story 003: the lookup API surface (`get_by_id`, listing queries).
- Story 004/005/006/008: boot validation of these fields.

---

## QA Test Cases

- **AC-1 (full-field round-trip)**: Given an authored entry populating ALL 11 fields (incl. the 4 Alpha-deferred + `footprint`); When queried by id; Then every field equals the authored value (a partial-field comparison must not pass).
- **AC-2 (getter-only immutability)**: Given a returned `ItemDefinition`; When a caller attempts idiomatic mutation; Then no setter exists (type-shape enforced) and a re-query returns unmutated values. Edge cases: document (do not test) the `Object.get()/set()` reflection bypass as residual risk.
- **AC-3 (cache integrity)**: Given a query for id A; When other ids are queried in between; Then a second query for A returns identical values.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/item_definition_immutability_test.gd` (GdUnit4) — factory-built fixture entries (no inline magic numbers except boundary cases); must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation leaf). Foundation-spine test harness is shared scaffolding.
- Unlocks: Story 002, Story 003, Story 008.
