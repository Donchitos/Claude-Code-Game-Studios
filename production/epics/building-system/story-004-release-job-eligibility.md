# Story 004: Release ("Bau starten") + job-eligibility transition

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 711/711 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-109` (release half), `TR-building-system-106` (queue eligibility)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: Release ("Bau starten") transitions a project's Draft cells into BUILDING, making them jobs villagers claim and execute (ADR-0007 job flow); `claim_job` serves BUILDING-state work only.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. Public transition surface: `release_project(project_id: int) -> void` (Draft → BUILDING) per ADR-0016 Key Interfaces.

**Control Manifest Rules (this layer — Core)**:
- Required: Released(BUILDING) makes the project's cells jobs villagers claim and execute; job eligibility is gated on release; the BUILDING-eligible queue is ordered by commit time (availability/tie-breaking, not forced servicing order).
- Forbidden: `claim_job` must never serve DRAFT, PAUSED, or an unreleased change-order batch.
- Guardrail: release is a per-project (or per-batch) action, bounded by that project's cell set.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC57: GIVEN a project in DRAFT, WHEN "Bau starten" is pressed, THEN every one of its cells becomes job-eligible BUILDING work, and none of them were claimable before that action (Rule 14f). [TR-109]
- [ ] `claim_job` serves BUILDING-state work only — never DRAFT, PAUSED, or a not-yet-released change-order batch. [TR-109]
- [ ] The BUILDING-eligible queue is ordered by commit time; ordering defines availability for display and tie-breaking, not forced servicing order. [TR-106]

---

## Implementation Notes

*Derived from ADR-0016 Decision §1 + building-system Rules 14f, TR-106/109:*

- `release_project(project_id)`: transitions every Draft cell currently in the project (or, for a change order on an already-built project, just that pending batch — Story 007) into BUILDING, making them job-eligible per Rule 12.
- After release, the project's cells appear in the BUILDING-eligible queue, ordered by commit time. This ordering is for display and tie-breaking only — Villager AI may choose among available jobs by its own criteria (proximity, outside-in ordering) — do not force servicing order here.
- `claim_job` must be structurally incapable of returning DRAFT, PAUSED, or unreleased change-order-batch cells.
- This story does NOT record worker attribution (Story 005) and does NOT execute the build tick loop (pre-slice construction pipeline) — it only flips eligibility and exposes the queue.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: recording the claiming villager's id (worker attribution).
- Story 006: pause/resume.
- Story 007: releasing a change-order batch specifically.
- The construction tick loop that turns a claimed cell into a Built cell — pre-slice foundation.

---

## QA Test Cases

**AC57 — release makes cells job-eligible**
- Given: a project in DRAFT with N cells.
- When: `release_project` is called.
- Then: state == BUILDING AND all N cells are enumerable via `claim_job`; before the call, `claim_job` returned none of them.
- Edge cases: releasing an empty project is a no-op; a DRAFT project's cells are never claimable pre-release.

**claim_job gating**
- Given: projects in DRAFT, BUILDING, and PAUSED states plus an unreleased change-order batch.
- When: `claim_job` enumerates work.
- Then: only BUILDING (released) cells are offered; DRAFT/PAUSED/unreleased-batch cells are excluded.

**Queue ordering**
- Given: cells committed at times t1 < t2 < t3, released.
- When: the BUILDING-eligible queue is read.
- Then: ordering reflects commit time; the order is advisory (display/tie-break), not a forced-servicing constraint.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/release_job_eligibility_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity + rollup).
- Unlocks: Story 005 (attribution), Story 006 (pause/resume), Story 007 (change-order release).
