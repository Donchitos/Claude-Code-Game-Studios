# Story 017: Furniture demolition — job-gated, atomic multi-cell

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1448/1448 suite green 0 orphans, parent-verified; completes the demolition chain 009->012->015->017 and makes the Sprint-10 crown's claim revocation non-vacuous)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-127` (secondary: `TR-building-system-064`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: Furniture removal is job-based too — demolition orders cover blocks AND furniture uniformly, no instant-removal carve-out. The furniture entity/occupant record clears only on job completion; multi-cell footprints demolish atomically as ONE job.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (Integration: furniture-revocation seam with Villager AI/Needs; ADR-0016 knowledge risk LOW)
**Engine Notes**: The furniture-revocation event fires on demolition-order COMPLETION, not at order creation (revised 2026-07-23). Villager AI consumes it (its Edge Cases 5–6); Needs learns via `stop_recovery`.

**Control Manifest Rules (this layer — Core)**:
- Required: demolition is job-based and uniform for blocks AND furniture — no instant-removal carve-out; the furniture entity/occupant record clears only on job completion; a multi-cell footprint demolishes atomically as ONE job.
- Forbidden: never an instant furniture removal; never a per-cell partial teardown of a multi-cell footprint (mirrors placement's no-partial-commit rule); never fire the revocation event at order creation.
- Guardrail: one demolition job per furniture entity (not per footprint cell).

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC17: GIVEN furniture is in use, WHEN `build_remove` targets it, THEN a demolition order is created immediately (never blocked by usage), but the furniture is not removed and the occupant is not revoked until a villager completes that order (Edge Case 11). [TR-064/127]
- [ ] A demolition order on Built furniture attaches to its owning Build Project — or, if none, a standalone removal order using the identical Rule 14j mechanics. [TR-127]
- [ ] A multi-cell furniture footprint (e.g. the 1×2 bed) demolishes atomically as ONE job — never left half-torn-down with one footprint cell gone and the other standing. [TR-127]
- [ ] Removing a not-yet-Built furniture blueprint is unchanged: Draft → instant cancel; Queued/UnderConstruction → instant cancel, claim revoked (micro-state branch, Story 015). [TR-127]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 16/17b, TR-127/064:*

- Targeting **Built** furniture with the removal tool creates a **demolition order** on the furniture cell's owning Build Project — or, if the furniture cell has no owning project, a **standalone removal order** using the identical Story 009 (Rule 14j) mechanics — executed by a claiming villager exactly as for structural cells (`base_demolition_ticks[furniture]` default 8, an `[assumption]`).
- The furniture entity/occupant record is cleared from Voxel World, and the item is no longer ownable/claimable, **only once that order completes**.
- A multi-cell footprint (Story 016) demolishes **atomically as one job**, not per-cell — mirroring placement's no-partial-commit rule (Edge 19) — so a 1×2 bed can never be left half-torn-down.
- **Furniture-revocation contract (17b)**: removing OWNED furniture (a bed with an owner) emits a furniture-revocation event to the owning villager — but the event fires on demolition-order COMPLETION, not at order creation. An in-use bed keeps functioning normally until a villager finishes tearing it down, at which point the occupant is revoked. Villager AI consumes the event (Edge Cases 5–6); Needs learns via `stop_recovery`.
- Not-yet-Built furniture removal is unchanged (Story 015's micro-state branch): Draft → instant cancel; Queued/UnderConstruction → instant cancel, claim revoked.
- Integration seam: the revocation-event consumption is Villager AI/Needs — mark that half PROVISIONAL; unit-test this system's order-creation, atomic-completion, and event-timing (event fires on completion).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: the block demolition tick loop (furniture reuses the same execution contract).
- Story 016: multi-cell furniture PLACEMENT (this story tears it down).
- Villager AI's interruption/re-plan on revocation; Needs' `stop_recovery` handling — those systems' domains.

---

## QA Test Cases

**AC17 — job-gated furniture removal, deferred revocation**
- Given: a Built bed currently in use (a sleeping owner, mocked).
- When: the removal tool targets it.
- Then: a demolition order is created immediately (not blocked by usage); the bed is NOT removed and the occupant is NOT revoked yet.
- When: a villager completes the demolition (mocked on-site ticks).
- Then: the furniture entity/occupant record clears and the furniture-revocation event fires (on completion, not at creation).
- Edge cases: an unowned bed fires no revocation event; the order attaches to the owning project, or is standalone if none.

**Atomic multi-cell teardown**
- Given: a 1×2 bed (Built).
- When: demolition runs.
- Then: it is ONE job; on completion both footprint cells clear together — never one gone with the other standing.

**Not-yet-Built furniture removal (unchanged)**
- Given: a Draft or Queued/UnderConstruction furniture blueprint.
- When: the removal tool fires.
- Then: Draft → instant cancel; Queued/UnderConstruction → instant cancel + claim revoked (no demolition order).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/building_system/furniture_demolition_test.gd` (order-creation/atomicity/event-timing unit-testable now; revocation consumption PROVISIONAL pending Villager AI/Needs).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 016 (multi-cell furniture placement), Story 009 (demolition contract), Story 015 (not-yet-Built micro-state branch).
- Unlocks: uniform block+furniture demolition (removes the last instant-removal carve-out).
