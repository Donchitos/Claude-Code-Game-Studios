# Story 006: Project pause / resume

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-110`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: Paused offers no new jobs, revokes in-flight claims gracefully, leaves queued cells untouched, and resumes the SAME remaining cells without re-creation.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: Public surface `pause_project(project_id: int) -> void` per ADR-0016 Key Interfaces. Graceful claim revoke mirrors the undo-triggered revocation contract (Villager AI Rule 3/Edge Case 4).

**Control Manifest Rules (this layer — Core)**:
- Required: Paused revokes in-flight claims gracefully, offers no new jobs, leaves queued cells untouched, and resumes the SAME remaining cells without re-creation.
- Forbidden: pause/resume must never touch Built cells or Draft cells outside the paused batch; never re-create the remaining cells on resume.
- Guardrail: pause/resume operates only over the project's own cell set.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC59: GIVEN a BUILDING project, WHEN paused, THEN no new jobs are offered and any in-flight claim is revoked gracefully (mirrors Edge Case 4); WHEN later resumed, THEN the same remaining cells become job-eligible again without re-creating them (Rule 14g). [TR-110]
- [ ] Pause/resume never touches Built cells or Draft cells outside the paused batch. [TR-110]

---

## Implementation Notes

*Derived from ADR-0016 Decision §1 + building-system Rule 14g, TR-110:*

- `pause_project(project_id)`: BUILDING → PAUSED. Stop offering new jobs (queued cells become claim-ineligible) and revoke any in-flight claims — villagers abandon gracefully, exactly as an undo-triggered revocation does (Villager AI Edge Case 4). The project's queued cells remain (untouched, not canceled).
- Resume: PAUSED → BUILDING. Re-offer the SAME remaining cells as jobs (do NOT re-create them). Preserve construction progress on partially-built cells.
- Never touch Built cells or Draft cells outside the paused batch.
- The claim-revocation itself signals Villager AI; test this story's half with a mocked in-flight claim (the graceful-abandon behavior is Villager AI's, verified in integration).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The villager's graceful-abandon behavior on revocation — Villager AI's domain.
- Change-order batch pause semantics beyond "Draft cells outside the paused batch are untouched" (Story 007 owns change-order batches).

---

## QA Test Cases

**AC59 — pause then resume**
- Given: a BUILDING project with queued and one in-flight-claimed cell (mocked claim).
- When: `pause_project` is called.
- Then: state == PAUSED, no cell is claim-eligible, the in-flight claim is revoked (graceful signal emitted), and queued cells still exist.
- When: resumed.
- Then: state == BUILDING and the same remaining cells (same ids, not re-created) are claim-eligible again.
- Edge cases: a partially-built cell keeps its progress across pause/resume; pausing an already-PAUSED project is idempotent.

**Isolation**
- Given: a project with Built cells and an adjacent project's Draft cells.
- When: pause/resume runs.
- Then: neither the Built cells nor the other project's Draft cells are touched.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/pause_resume_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (release + job eligibility).
- Unlocks: Building UI pause/resume controls.
