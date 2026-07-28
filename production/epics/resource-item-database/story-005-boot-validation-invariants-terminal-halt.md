# Story 005: Boot validation — reserved ids, retired ledger, tier-0 coverage, aggregate report + terminal Failed

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-24 — 305/305 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-030`, `TR-resource-item-database-042`, `TR-resource-item-database-031`, `TR-resource-item-database-035`, `TR-resource-item-database-006`, `TR-resource-item-database-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (Boot Sequencing & Initialization Gate) — primary (Failed = terminal halt); ADR-0006 — secondary (structured validation result)
**ADR Decision Summary**: Failed is a terminal halt — error screen shown, Valley scene never attached, nothing further instantiated; recovery requires fixing data and restarting. The structured result names EVERY invalid entry and its source file (proven at ≥3 independent violations).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Terminal halt is NOT `SceneTree.paused` and NOT process-exit — it is the RID Failed state (an error screen, nothing further instantiated). Assert on the structured result, not log strings.

**Control Manifest Rules (this layer)**:
- Required: one terminal-halt severity model (RID Failed pattern) reused by config blocking-invariants and data-definition validation — never invent a new severity scheme (ADR-0002/0005/0006).
- Required: on Failed → boot-halt, NO injected-tier `setup()` calls, terminal (ADR-0005).

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] An authored entry with id `missing_item` (10a) or category `missing` (10b) halts boot — reserved id / reserved category (GDD AC10). [TR-resource-item-database-030]
- [ ] A new entry whose id appears in the retired-ids ledger halts boot naming the entry and the ledger conflict (GDD AC11). [TR-resource-item-database-042]
- [ ] A data set whose tier-0 `building_material` entries do not cover every material family halts boot naming the uncovered family (GDD AC25 — the Core Rule 6 invariant, boot-enforced). [TR-resource-item-database-031]
- [ ] With THREE independent invalid entries of three different violation classes, boot halts and the error names ALL invalid entries, not just the first (GDD AC7). [TR-resource-item-database-035]
- [ ] On validation failure the DB exposes the structured validation result, remains permanently non-Ready for the session, and never partially answers queries (GDD AC26). [TR-resource-item-database-006] [TR-resource-item-database-007]

---

## Implementation Notes

*Derived from ADR-0005 / ADR-0006 Implementation Guidelines:*

- Reject authored use of reserved id `missing_item` and reserved category `missing` (Core Rule 5).
- Keep a retired-ids ledger in the data set (shipped MVP ledger is empty); reject any new entry whose id appears in it (Edge Case 6 — protects old saves from resolving to the WRONG thing).
- Tier-0 coverage: the tier-0 `building_material` set must contain ≥1 entry per material family — halt naming the uncovered family.
- Aggregate: the validation pipeline (Story 004) accumulates all records; on any failure, transition to Failed (terminal), expose the full structured result, and refuse every query for the session.
- The player-facing HALT presentation is Scene/World Management's concern (its AC17b) — this story exposes the structured result and the terminal non-Ready state it renders.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the per-entry schema checks that feed the aggregate.
- Story 006: `visual_asset` resolution failure shape.
- Scene/World Management epic: the boot-halt error screen UI.

---

## QA Test Cases

- **AC-1 (reserved)**: Given an authored `missing_item` id (10a) and a `missing` category (10b); When booting; Then each halts.
- **AC-2 (ledger)**: Given a synthetic ledger with id `old_plank` and a new entry `old_plank`; When booting; Then halt names the entry + ledger conflict.
- **AC-3 (tier-0 coverage)**: Given tier-0 wood + stone but no thatch; When booting; Then halt names the uncovered `thatch` family.
- **AC-4 (aggregate report)**: Given 3 entries violating 3 different classes (missing field + unknown category + duplicate id); When booting; Then the structured result names all 3 (not just the first).
- **AC-5 (terminal Failed)**: Given a failing set; When Failed; Then the structured result is exposed, the DB stays non-Ready all session, and every query returns an error result.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/validation_invariants_terminal_test.gd` (GdUnit4) — asserts on the structured result; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (per-entry check pipeline + structured result must be DONE).
- Unlocks: Story 007 (fallback), Story 009 (content smoke relies on a green validation path).
