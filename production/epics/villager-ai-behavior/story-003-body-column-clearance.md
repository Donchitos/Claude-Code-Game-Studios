# Story 003: Body-column occupancy model (2-block character clearance)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 474/474 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-098`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (Deterministic Movement & Occupancy Ordering) — primary; ADR-0007 (shared predicates)
**ADR Decision Summary**: With the 2-block character scale, occupancy is a **body-column** — the discrete `current_cell` (feet) plus the cell(s) above spanning the villager's height — derived deterministically from the single authoritative discrete `current_cell`, interpolation-free. It is the reusable definition of "the villager's space" that anti-stuck (Rules 15–17) and seal-prevention/walled-in queries must use.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Pure derivation from a `Vector3i`; no engine API risk. The column is a function of `current_cell` only — never `_visual_position`.

**Control Manifest Rules (this layer)**:
- Required (Core layer): Occupancy is a body-column, not a single cell — every occupancy/seal/walled-in query derives the vertical body-column (feet `current_cell` + the cell(s) above spanning its height) from the single authoritative discrete `current_cell`. The derivation is deterministic and interpolation-free — the "single unambiguous answer" property holds for the column exactly as for one cell.
- Forbidden: deriving the body-column from `_visual_position` or interpolation progress; a second copy of the clearance span.
- Guardrail: negligible cost — a pure function returning the column cells.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] The villager model is 2 cells tall (feet cell + one cell directly above forms the visible body); the body-column the anti-stuck rules treat as the villager's space is the same 3-cell span as standability clearance (2-cell body + 1 buffer headroom cell).
- [ ] A `body_column(cell) -> Array[Vector3i]` (or equivalent) derives the column from a single discrete `current_cell`, deterministically and without reading interpolation state.
- [ ] The numeric clearance constant is unchanged from Story 002 — this story only names the concept so anti-stuck/seal checks have a precise, reusable definition; checking only the feet cell must be shown insufficient (a check that passes on feet alone while the body clips a low ceiling is a defect the column prevents).
- [ ] Seal-prevention and walled-in queries (Stories 015/016) consume this column, not the single cell.

---

## Implementation Notes

*Derived from ADR-0009 (slice propagation) Implementation Guidelines:*

- The column derivation reuses the `villager_clearance` span from Story 002 — do not introduce a second constant.
- Expose the column as a pure helper so the watchdog rescue BFS (Story 014), the watchdog trigger (Story 015), seal-prevention (Story 016), and walled-in detection all share it.
- Interpolation-free: the column is `[cell, cell + up, cell + 2*up]` (or the registered span) computed from `current_cell`; never derived from `_visual_position`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the discrete `current_cell` tick-quantized authoritative value it derives from.
- Story 015/016: the anti-stuck / seal consumers of this column.

---

## QA Test Cases

- **AC (column derivation)**: Given a `current_cell`, When `body_column` is computed, Then it returns the deterministic 3-cell vertical span (feet + body + buffer). Edge cases: same input always same output (determinism).
- **AC (feet-only insufficiency)**: Given a feet cell that is standable but whose body cell is blocked by a low ceiling, When the body-column check runs, Then it reports the villager's space as obstructed (a feet-only check would incorrectly pass).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/body_column_test.gd` — must exist and pass.

**Status**: [x] Created — `neues-spiel/tests/unit/villager_ai/body_column_test.gd` (11 test functions), full suite green (474/474, exit 0)

---

## Dependencies

- Depends on: 002 (walkability predicates + clearance constant)
- Unlocks: 004, 014, 015, 016
