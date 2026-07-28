# Story 017: Dig/demolition on-site exclusion (self-undermine guard)

> **Epic**: Villager AI & Behavior
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-103`, `TR-villager-ai-behavior-108`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (occupancy semantics) — primary; ADR-0016 (job-based demolition)
**ADR Decision Summary**: For dig and demolition jobs, the on-site position directly above the target cell is excluded from eligibility — a villager may not stand on the block it is digging out; it must approach from an orthogonal side. This does not apply to build jobs (blueprints are non-solid, standing on/adjacent to a not-yet-Built cell is safe).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Real incident this guards: a villager dug the block directly beneath its own feet, instantly failing its own standability check the moment the write committed. Demolition is job-based and uniform for blocks AND furniture (ADR-0016).

**Control Manifest Rules (this layer)**:
- Required (Core): demolition is job-based and worker-executed (uniform for blocks and furniture). On-site eligibility for dig/demolition excludes the directly-above position.
- Forbidden: standing on the dig target for a dig/demolition job; applying this exclusion to build jobs.
- Guardrail: a pure eligibility predicate on the on-site rule (Story 012).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] For dig and demolition jobs, the on-site position directly above the target cell is excluded from eligibility — the villager must approach from an orthogonal side (AC57, Rule 17, Edge Case 17).
- [ ] Given a dig job whose ONLY otherwise-eligible on-site position is directly above the target cell, that position is excluded and the villager approaches orthogonally (or the job is treated as not-currently-on-site-able from above).
- [ ] The exclusion does NOT apply to build jobs — standing on/adjacent to a not-yet-Built cell remains valid on-site (blueprints non-solid).

---

## Implementation Notes

*Derived from ADR-0009/0016 Implementation Guidelines:*

- Extend the on-site eligibility check (Story 012) with a `job_type`-aware exclusion: for `dig`/`demolish`, drop the directly-above cell from the eligible on-site set.
- Keep build-job on-site semantics unchanged.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: the base on-site rule and work-progress accrual.
- Story 016: seal-prevention (dig/demolition are exempt there; this is a separate guard).

---

## QA Test Cases

- **AC57**: Given a dig job whose only on-site position is directly above the target, When on-site eligibility is evaluated, Then that position is excluded and an orthogonal approach is required.
- Edge cases: build job → directly-above (or on-cell) position remains valid; demolition of furniture uses the same exclusion.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/dig_onsite_exclusion_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 012 (on-site rule / build cycle)
- Unlocks: None
