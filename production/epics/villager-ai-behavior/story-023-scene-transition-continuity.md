# Story 023: Scene-transition simulation continuity

> **Epic**: Villager AI & Behavior
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-068`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013 (Multi-Scene Concurrency) — reference; ADR-0008 (tick-driven FSM)
**ADR Decision Summary**: Villagers keep simulating in the Valley during scene transitions and dungeon excursions — there is NO Suspended state. Villagers pause only when game time pauses. The player returns to visible progress, not a freeze-frame.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Continuity is verified numerically (tick-count equality), not by observation. Villager tick-driven activities advance exactly as many ticks as elapsed Valley game time.

**Control Manifest Rules (this layer)**:
- Required: tick-driven activities advance on Time & Tick's game time regardless of active scene; no Suspended state for villagers.
- Forbidden: pausing villager simulation on scene transition (only game-time pause halts them); `SceneTree.paused`.
- Guardrail: continuity verified numerically via mocked transition signals.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given a scene-transition integration test driving mocked Scene/World Management transition signals, when the transition completes, villager tick-driven activities have advanced exactly as many ticks as elapsed Valley game time — continuity verified numerically (AC37, Edge Case 10).
- [ ] Villagers keep building/sleeping/wandering through a transition; the player returns to progress, not a freeze-frame.
- [ ] Villagers halt ONLY when game time pauses — never because of a scene transition.

---

## Implementation Notes

*Derived from ADR-0013/0008 Implementation Guidelines:*

- No Suspended state — the FSM keeps ticking on Time & Tick's signal during transitions.
- The integration test drives mocked transition signals and asserts tick-count equality between elapsed Valley game time and advanced villager activity.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Scene/World Management's transition mechanics (Foundation epic).

---

## QA Test Cases

- **AC37** (integration): Given mocked transition signals over a known Valley game-time span, When the transition completes, Then villager tick-driven activities advanced exactly that many ticks (numeric equality).
- Edge cases: game-time pause during a transition halts villagers; warp during a transition scales elapsed ticks correctly.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/scene_transition/villager_continuity_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 006 (tick-driven decision loop), 012 (ongoing work to continue through a transition)
- Unlocks: None
