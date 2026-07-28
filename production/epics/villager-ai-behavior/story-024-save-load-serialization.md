# Story 024: Villager AI save/load serialization (VS-tier)

> **Epic**: Villager AI & Behavior
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (Save/Load Serialization Strategy)
**ADR Decision Summary**: Villager AI exposes `serialize() -> Dictionary` / `deserialize(data)`; `deserialize()` owns stale claim/bed-id revalidation. The `villager_ai` top-level key is a plain `Dictionary` via `FileAccess.store_var()/get_var()`. On load, a claim whose job no longer exists dissolves and the villager re-enters Deciding — never crash on a stale reference.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `FileAccess.store_*` returns `bool` since 4.4 — check it; `get_var()` has no success signal (check `FileAccess.open()` null). Never a custom `SaveGameData` Resource via `ResourceSaver`. Never `duplicate_deep()`.

**Control Manifest Rules (this layer)**:
- Required (Foundation): plain `Dictionary` serialize/deserialize; `deserialize()` revalidates stale claims/bed ids; saves fire on `transition_ended(success=true)`.
- Forbidden: a custom Resource save; swallowing save/write failures silently.
- Guardrail: synchronous at VS for non-voxel state; population ceiling 20–30.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `serialize()` writes per-villager state: position (`current_cell`), current activity/state, claimed job id, owned bed id, need levels (via Needs GDD contract, mocked).
- [ ] Given a deserialized claimed-job or bed-owner id that no longer exists, on load the stale claim/bed dissolves and the villager enters Deciding — never crashes (AC38, Edge Case 11; testable now against a mocked serializer contract).
- [ ] Round-trip: serialize → deserialize reproduces equivalent villager state for valid references.

---

## Implementation Notes

*Derived from ADR-0012 Implementation Guidelines:*

- `deserialize()` owns stale claim/bed-id revalidation — dissolve and re-enter Deciding on a missing reference.
- Use plain `Dictionary` (no Resource); check `FileAccess` return values at the orchestrator boundary.
- Needs levels serialize per the Needs GDD contract (mocked here at VS tier).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The Save/Load orchestrator (Foundation, injected-tier) — this story supplies only the Villager AI serialize/deserialize contract.
- Voxel/region-file save format (Voxel World / ADR-0015).

---

## QA Test Cases

- **AC38** (integration against a mocked serializer): Given a deserialized claimed-job/bed id that no longer exists, When load completes, Then the stale reference dissolves and the villager enters Deciding — no crash.
- Round-trip: serialize → deserialize reproduces equivalent state for valid references.
- Edge cases: missing job id; missing bed id; both stale simultaneously.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/villager_ai/serialization_test.gd` — must exist and pass (mocked serializer contract).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 011 (claim state), 018 (bed ownership state)
- Unlocks: None
- **NEEDS-DECISION**: Save/Load is explicitly Vertical-Slice-tier and **out of scope for Milestone 01** (per `milestone-01-foundation-core.md` Out of Scope). AC38 is testable NOW against a mocked serializer, but the full story should be sequenced into the Vertical Slice, not M01. Confirm sequencing before scheduling.
