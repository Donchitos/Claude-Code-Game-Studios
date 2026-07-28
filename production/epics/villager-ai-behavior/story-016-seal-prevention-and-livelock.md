# Story 016: Seal prevention negative-write gate & livelock escape (F6)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-25 — 938/938 suite green, parent-verified; anti-stuck ladder complete)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-101`, `TR-villager-ai-behavior-102`, `TR-villager-ai-behavior-106`, `TR-villager-ai-behavior-107`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (Deterministic Movement & Occupancy Ordering)
**ADR Decision Summary**: Seal prevention is a negative-write gate the Building System write path MUST accept — a Planned→Built write that would entrap a villager is gated by reading the discrete `current_cell`/body-column (never `_visual_position`). The one deliberate exception — a builder sealing itself with its own same-job completion write — proceeds unconditionally and is self-healed by the watchdog.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `would_trap_builder` evaluates the builder's `current_cell` against Rules 8–9 as if the write had already committed. Dig/demolition writes are exempt (never refused for this reason).

**Control Manifest Rules (this layer)**:
- Required (Core): Seal prevention is a negative-write gate the Building System write path MUST accept; reads discrete `current_cell`/body-column. The one exception (builder sealing itself with its own same-job completion) proceeds unconditionally and is watchdog-self-healed.
- Forbidden: reading `_visual_position` in the gate; refusing dig/demolition completions for entrapment.
- Guardrail: `abandon_count` is monotonic per (job, villager) pair, bounded above by `seal_prevention_abandon_limit`.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `allow_write = NOT would_trap_builder OR (abandon_count >= seal_prevention_abandon_limit) OR (job_type != build)`.
- [ ] Given a build-job completion that would leave its builder with zero legal steps, the write is refused, the claim releases back to the queue, and `abandon_count` for that (job, villager) pair increments by 1 (AC54, Edge Case 15).
- [ ] Given a dig or demolition job whose completion would trap the builder, the write proceeds unconditionally — dig/demolition never trigger seal-prevention refusal (AC55, Rule 16 exemption).
- [ ] Given the same (job, villager) pair refused `seal_prevention_abandon_limit` times, the next attempt writes unconditionally regardless of the trap check — the builder is sealed by its own work and the watchdog (Story 015) rescues it on its normal schedule (AC56, Edge Case 16).
- [ ] `abandon_count` resets when the job is claimed by a DIFFERENT villager.

---

## Implementation Notes

*Derived from ADR-0009 (F6) Implementation Guidelines:*

- `would_trap_builder` reads the body-column (Story 003) and Rules 8–9 predicates as if the write committed — true iff the builder would then have zero legal steps.
- Refusal reuses the shared claim-release path (Story 011) — the same negative-write gate the Building System write path rejects and requeues.
- `abandon_count` is per (job, villager); reset on a different-villager claim.
- Livelock escape: once `abandon_count >= seal_prevention_abandon_limit`, `allow_write` flips true; the villager becomes sealed and the watchdog rescues it — a deliberate self-healing tradeoff over an unresolvable livelock.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 015: the watchdog rescue that self-heals a deliberately-sealed builder.
- Story 017: the dig on-site exclusion (a different self-undermine guard).

---

## QA Test Cases

- **AC54**: Given a build completion that would trap the builder, When evaluated, Then refused, claim released, `abandon_count` += 1.
- **AC55**: Given a dig/demolition completion that would trap the builder, When evaluated, Then it proceeds unconditionally.
- **AC56**: Given the same (job, villager) refused `seal_prevention_abandon_limit` times, When it attempts again, Then the write proceeds regardless of the trap check.
- Edge cases: `abandon_count` resets on a different-villager claim; monotonic bound; the one-exception self-seal path leaves the builder to the watchdog.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/seal_prevention_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (body-column), 011 (claim release), 012 (build cycle write path), 015 (watchdog self-heal)
- Unlocks: 017
