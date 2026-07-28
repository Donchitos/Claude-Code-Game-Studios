# Story 003: Read-only lookup API (get_by_id + listing queries)

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-23 — 138/138 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-032`, `TR-resource-item-database-039`, `TR-resource-item-database-044`, `TR-resource-item-database-031`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — primary (queries return getter-only wrappers); ADR-0001 — secondary (headless-mockable read API)
**ADR Decision Summary**: Read-only lookup only — get by id, list by category, by material family, by tier, list all. No write API. `get_by_id()` returns a fresh getter-only `ItemDefinition` wrapper. The database performs no gameplay logic.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Id lookup is a native dictionary get-by-key — no engine-version risk. Return typed collections (`Array[StringName]`/`Array[String]`) per the typed-collection preference.

**Control Manifest Rules (this layer)**:
- Required: cross-system references are opaque string ids only; consumers store ids, resolve meaning here.
- Forbidden: no write API; the database never computes costs, validates placement, or spawns anything.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] Read-only lookup API exists: get by id, list by category, by material family, by tier, list all — no write API; no gameplay logic (GDD Core Rule 8). [TR-resource-item-database-032]
- [ ] A query for an id not in the database returns an explicit not-found result and logs the id without crashing (GDD AC8). [TR-resource-item-database-039]
- [ ] A query for a category with zero entries (e.g. `raw_resource` in MVP) returns an empty list — a valid result, not an error (GDD AC12). [TR-resource-item-database-044]
- [ ] Querying by material family returns all and only entries of that family (GDD AC15). [TR-resource-item-database-032]
- [ ] "List all ids" returns every authored id exactly once and no unauthored id (GDD AC16). [TR-resource-item-database-032]
- [ ] Querying all tier-0 building materials returns exactly the tier-0 set (GDD AC14 — content assertion deferred to Story 009; the query logic is proven here on a fixture). [TR-resource-item-database-031]

---

## Implementation Notes

*Derived from ADR-0006 / ADR-0001 Implementation Guidelines:*

- Implement `get_by_id(id) -> ItemDefinition` (fresh wrapper), `list_ids_by_category`, `list_ids_by_material_family`, `list_ids_by_tier`, `list_all_ids`. All return getter-only wrappers or id lists — never the internal `ItemDefinitionResource`.
- `get_by_id` for an unknown id returns an explicit not-found result and logs the id once (Edge Case 2) — do NOT crash; the `missing_item` fallback resolution is Story 007.
- Empty-category query returns an empty typed list, not an error.
- The `missing_item` exclusion from listings is enforced in Story 007; here, listing queries operate over authored entries.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: `missing_item` fallback resolution and its exclusion from listings.
- Story 009: content assertions against the SHIPPED MVP data (tier-0 set, bed).
- Stories 004–006, 008: validation that populates the queryable set.

---

## QA Test Cases

- **AC-1 (API shape)**: Given a Ready DB with a fixture set; When each listing method is called; Then it returns the correct ids; no write/mutation method is exposed.
- **AC-2 (unknown id)**: Given an id not present; When `get_by_id` is called; Then an explicit not-found result returns, the id is logged, no crash.
- **AC-3 (empty category)**: Given a category with zero entries; When listed; Then an empty list (no error).
- **AC-4 (family filter)**: Given entries of families wood/stone/thatch; When listing by `wood`; Then all and only wood entries return.
- **AC-5 (list all)**: Given N authored entries; When listing all; Then N ids, each once, none unauthored.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/lookup_api_test.gd` (GdUnit4) — factory fixtures; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (schema/wrapper), Story 002 (Ready state + non-Ready guard) — both DONE.
- Unlocks: Story 007 (fallback + exclusion), Story 009 (content smoke).
