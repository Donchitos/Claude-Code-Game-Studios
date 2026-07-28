# Story 010: Live-pair shelter recovery round trip (AC34, milestone criterion #5)

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — 1298/1298 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md` (AC34); `design/gdd/villager-ai-behavior.md` (its Rules 11–13, AC22–AC27)
**Requirement**: `TR-needs-mood-system-025`, `TR-needs-mood-system-032`, `TR-needs-mood-system-042`, `TR-needs-mood-system-036`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern) — primary; ADR-0008 (the FSM's poll-at-decision-points consumption model)
**ADR Decision Summary**: Modules are injected-tier and headless-constructible — a test builds both real modules with `Node.new()`, assigns the real counterpart to the `@export`/duck-typed seam, and calls `setup()` directly. That is exactly what makes an **unmocked** pair possible: no scene tree, no Autoload registration, no mock at the seam under test.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The landed seam is `neues-spiel/src/villager_ai/villager_ai.gd`'s duck-typed, nil-safe `needs_provider`, which calls exactly `has_urgent_need(villager_id: int) -> bool`. This story is where that field stops being nil and holds the real module. Ticks are driven by the `TimeTickSystem` Autoload — the test dispatches ticks deterministically rather than waiting on frames.

**Control Manifest Rules (this layer)**:
- Required (Foundation): both modules constructed headless via `Node.new()` + `setup()`; no scene tree, no Autoload registration in the test.
- Required (Feature): Villager AI polls need state at its decision points; the urgent event is a latency hint, not the trigger of record.
- Forbidden: any mock **at the Needs ↔ Villager AI seam** in this test — that is the entire point of the story. (Neighbours outside the seam — the voxel grid, the job queue — may still be doubles.)
- Guardrail: the round trip is dispatched in ticks, never wall-clock; the test must be deterministic and re-runnable.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC34**: Given a **REAL** Needs & Mood instance and a **REAL** Villager AI villager with an **owned sheltered bed** (no mocks at the seam), When the sleep need decays from 100 through urgent → the AI claims/travels/sleeps → recovery → satisfied → wake, Then the full round trip completes: state transitions, `start_recovery`/`stop_recovery` calls, and **both events observed in order**. [TR-needs-mood-system-025]
- [ ] The recovery is scored at the **sheltered** rate (×1.0) because the reported source enum is `bed_sheltered` — proving the Build Validation → source enum → rate path end-to-end, not just the table lookup. [TR-needs-mood-system-036]
- [ ] The villager's decision to pursue the need comes from **polling** the real queryable state (`has_urgent_need`), demonstrated by the round trip completing correctly even when the urgent event's connection is deliberately absent. [TR-needs-mood-system-032]
- [ ] `start_recovery` is called exactly once on sleep onset and `stop_recovery` exactly once on wake, with the reported source enum — no per-tick pushes. [TR-needs-mood-system-042]
- [ ] The production wiring exists: `GameWorld` assigns the real Needs & Mood module to Villager AI's `needs_provider` seam during the Booting path, so the shipped game exercises the same path the test does.
- [ ] A run-level capture of the round trip is recorded in `production/qa/evidence/` per milestone criterion #5.

---

## Implementation Notes

*Derived from ADR-0001/0008 Implementation Guidelines:*

- **This is the milestone's reason to exist.** Criterion #5 is the shelter payoff being mechanically real; everything else in this epic is the machinery underneath it.
- Build the pair explicitly: real `NeedsMoodSystem` + real villager, `needs_provider` assigned to the real module, ticks dispatched one at a time. Mock only what is *outside* the seam (world grid, job queue, the bed's existence).
- Dispatch the full cycle in ticks. At shipped defaults that is ~1072 ticks to urgent — dispatch them in a loop, do not simulate frames. Consider seeding the need lower for the fast path **and** running the full anchor at least once.
- Ordering assertion: `need_urgent` → `start_recovery` → (recovery ticks) → `need_satisfied` → `stop_recovery` → villager re-enters Deciding. Record the sequence, then assert the sequence — not just the endpoints.
- The poll-not-event proof: run one variant with the `need_urgent` signal deliberately unconnected. The round trip must still complete, because state is truth (Core Rule 3). This is the single most valuable assertion in the story.
- Wiring `needs_provider` in `GameWorld` is the moment the landed nil-safe seam becomes live. Confirm no other call site assigns it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 002–008: the unit-level behavior of each formula (already proven).
- `villager-ai-018`: bed claiming, ownership, ground-sleep fallback, wake behavior.
- `build-validation-navigability`: room detection and the shelter classification itself.
- Furniture chain (`building-028 → 016 → 017`): placing and building the bed.

---

## QA Test Cases

- **AC34 (round trip)**: Given a real pair and a villager owning a sheltered bed, When ticks are dispatched from need = 100, Then the observed sequence is exactly: state `Satisfied` → `need_urgent` → villager commits to the need → travels → `start_recovery(bed_sheltered)` → state `Recovering` → `need_satisfied` → `stop_recovery` → villager back in Deciding.
- **Sheltered rate**: Given the same run, When per-tick deltas during recovery are measured, Then each equals `base_recovery_per_tick × 1.0` (not ×0.7, not ×0.4).
- **Poll-not-event**: Given the same setup with `need_urgent` left unconnected, When the run repeats, Then the round trip still completes identically.
- **Call counts**: Given the same run, Then `start_recovery` was called exactly once and `stop_recovery` exactly once.
- **Determinism**: Given two identical runs, Then the tick indices of both events are identical.
- **Production wiring**: Given `GameWorld`'s Booting path, When it completes, Then Villager AI's `needs_provider` is non-null and is the real module instance.
- Edge cases: bed revoked mid-sleep in the live pair → the villager wakes and `stop_recovery` lands with zero credited that tick (story 004's rule, proven unmocked); an unsheltered bed in the same harness recovers at ×0.7 and the why-string reads "sleeping rough — no shelter".

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` — must exist and pass, **plus** a run-level capture in `production/qa/evidence/` (milestone criterion #5).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (recovery + table), 004 (interruption/re-rating), 006 (spawn init), 007 (why-string, for the unsheltered edge case), 008 (determinism harness)
- **External (must be landed and REAL, not mocked)**: `villager-ai-018` (bed claim / sleep / wake), the furniture chain `building-028 → 016 → 017`, `build-validation-navigability`'s shelter classification
- Unlocks: milestone criterion #5; the first external playtest (milestone R8), which is scheduled *after* this criterion goes green
