# Story 007: missing_item fallback definition + exclusion from listings

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-27 — own suite 7/7 green; full gate re-verified by parent once the concurrent building-012 lands)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-038`, `TR-resource-item-database-033`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — primary
**ADR Decision Summary**: A built-in, fully-inert `missing_item` definition (category `missing`, family `none`, tier 0, non-stackable/haulable, magenta placeholder, "Missing Item") is the fallback for any unknown/retired stored id. It is EXCLUDED from all listing queries — reachable only via direct get-by-id.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `missing_item` is a code-defined built-in, not an authored `.tres` (Story 005 rejects an authored one). Return it as the same getter-only `ItemDefinition` wrapper type as any other definition.

**Control Manifest Rules (this layer)**:
- Required: cross-system references are opaque string ids only; unknown ids resolve here, never crash a consumer.
- Forbidden: `missing_item` never appears in a palette, category, family, tier, or list-all result.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] A stored id not in the current database resolves via the fallback path to the fully inert `missing_item` — category `missing`, family `none`, tier 0, non-stackable, non-haulable, magenta placeholder, display name "Missing Item" (GDD AC9a). [TR-resource-item-database-038]
- [ ] Each distinct missing id is logged exactly once per load event (GDD Edge Case 1). [TR-resource-item-database-038]
- [ ] `missing_item` never appears in ANY listing query (by category `missing`, by family, by tier, list-all) — reachable only via direct get-by-id (GDD AC27). [TR-resource-item-database-033]

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

- Define `missing_item` as a built-in inert definition with the exact fields from Edge Case 1 (a deliberately conspicuous magenta placeholder visual — the actual asset is authored in Story 009 / art pipeline).
- The fallback resolution is a dedicated path (e.g. `resolve_or_missing(id)`) distinct from `get_by_id` returning not-found (Story 003) — callers that MUST render (world loading) use the fallback.
- De-dup logging per load event: track which missing ids have been logged this load; log each distinct id once.
- Exclusion: ensure every listing query iterates authored entries only; `missing_item` is never in the listed set.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the base `get_by_id` not-found result.
- Story 005: rejecting an AUTHORED `missing_item`/`missing` entry.
- Save/Load (VS+, Milestone 02): AC9b — per-load logging across a save round-trip is DEFERRED pending the Save/Load & World Persistence GDD. This story implements the resolution + once-per-load logging; the save-round-trip integration test is out of scope.

---

## QA Test Cases

- **AC-1 (inert fallback)**: Given a stored id absent from the DB; When resolved via the fallback path; Then it returns `missing_item` with EVERY field per Edge Case 1.
- **AC-2 (log once per load)**: Given the same missing id resolved 3 times in one load; When logged; Then exactly one log entry for that id. Given two distinct missing ids; Then two entries.
- **AC-3 (exclusion)**: Given a Ready DB; When any listing query runs (category `missing`, by family, by tier, list-all); Then `missing_item` never appears.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/missing_item_fallback_test.gd` (GdUnit4) — factory fixtures; must pass. (AC9b save round-trip explicitly deferred to Milestone 02.)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (lookup API) + Story 005 (reserved-id rejection) — both DONE.
- Unlocks: Story 009 (content smoke can assert `missing_item` never leaks into the shipped palette).
