# Story 021: Starting roster spawn at world generation

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-26 — 968/968 suite green, parent-verified; spawn surface tested but not boot-wired: no world generation exists in the boot path — see follow-up)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-065`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (DI/setup) — primary; ADR-0002 (config knob)
**ADR Decision Summary**: At world generation this system places `starting_villager_count` villagers (config: MVP = 1, Vertical Slice = 5) at valid standable cells near the world center. This GDD owns the STARTING population; Township Progression (Alpha) owns all growth beyond it.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Placement cells must pass the shared `is_standable` predicate (Story 002). Population ceiling is a design commitment (20–30 Full Vision); MVP = 1, VS = 5.

**Control Manifest Rules (this layer)**:
- Required: injected-tier module; spawn logic runs in `setup()`/world-gen, not `_ready()`; `starting_villager_count` is a config knob.
- Forbidden: placing villagers on non-standable cells; hardcoding the count.
- Guardrail: bounded by the population ceiling; spawn is a one-time world-gen step.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given `starting_villager_count` = N (mocked config), when world generation completes, exactly N villagers exist at valid standable cells near the world center (AC47).
- [ ] Each spawned villager begins in Deciding with a well-formed `current_cell` on a standable cell.
- [ ] Growth beyond the starting roster is NOT handled here (Township Progression, Alpha) — this story only places the starting set.

---

## Implementation Notes

*Derived from ADR-0001/0002 Implementation Guidelines:*

- Read `starting_villager_count` from config; select N standable cells near the world center via the shared predicate.
- Instantiate villagers with a valid `current_cell`; enter Deciding.
- Keep placement deterministic given the same world seed / config (reuse the lexicographic convention where a tie-break is needed).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Population growth / arrivals / recruitment (Township Progression, Alpha).

---

## QA Test Cases

- **AC47**: Given `starting_villager_count` = N (mocked), When world-gen completes, Then exactly N villagers exist at valid standable cells near center, each in Deciding.
- Edge cases: N = 1 (MVP); N = 5 (VS); no standable cell near center within a fallback search (deterministic placement).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/villager_ai/starting_roster_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (config/scaffold), 002 (is_standable for valid placement)
- Unlocks: None
