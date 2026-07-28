# Story 012: Needs & Mood save/load serialization (VS-tier)

> **Epic**: Needs & Mood System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

> ⚠️ **Vertical-Slice-tier — NOT Milestone 02 content.** Milestone 02 explicitly
> defers AC24/AC25 pending the Save/Load & World Persistence GDD. This story
> exists so `TR-needs-mood-system-026…029` are not orphaned and so the
> serialization shape is designed while the state model is fresh. It is
> implementable now against a **mocked serializer**; do not schedule it into an
> M02 sprint.

## Context

**GDD**: `design/gdd/needs-mood-system.md` (Edge Case 8, AC24/AC25)
**Requirement**: `TR-needs-mood-system-026`, `TR-needs-mood-system-027`, `TR-needs-mood-system-028`, `TR-needs-mood-system-029`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012 (Save/Load Serialization Strategy) — primary
**ADR Decision Summary**: Plain `Dictionary` via `FileAccess.store_var()/get_var()`, one binary file for non-voxel state, with `needs_mood` as a top-level key alongside `voxel_world`, `building_system`, `villager_ai`. Each system exposes `serialize() -> Dictionary` / `deserialize(data)`; the Save/Load orchestrator treats each system's payload as an opaque blob. Never a custom `SaveGameData` Resource; never silently swallow a write failure.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `FileAccess.open()` returns null on failure — check via `get_open_error()`; `store_var()` returns a bool that must be checked. Godot 4.4+ changed several `FileAccess` return types — verify against `docs/engine-reference/godot/` before use.

**Control Manifest Rules (this layer)**:
- Required (Foundation): `serialize()`/`deserialize()` pair; payload under the `needs_mood` top-level key; save data is user data — never git-tracked, never Inspector-edited.
- Required (Foundation): saves fire exclusively on `transition_ended(success = true)`.
- Forbidden: re-initializing mood via F4 on load (it would erase the smoothing state); crashing on schema drift; swallowing a write failure.
- Guardrail: payload is per-villager floats plus one mood float — trivially small at the 20–30 population ceiling.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] Per-villager need values **and** the smoothed mood are serialized (Edge Case 8). [TR-needs-mood-system-026]
- [ ] **AC24**: Given a save with need values and mood, When loaded, Then mood is restored **as-saved**, never re-initialized via F4. [TR-needs-mood-system-027]
- [ ] **AC25**: Given a saved need type no longer in the schema, When loaded, Then it is dropped with a log line, never a crash. [TR-needs-mood-system-028]
- [ ] On load, the per-need queryable state is **re-derived from the restored values** with no signal replay — values are the persisted truth, the state machine is reconstructed from them. [TR-needs-mood-system-029]
- [ ] A need present in the schema but absent from the save initializes at 100 (story 006's activation path), not at 0.

---

## Implementation Notes

*Derived from ADR-0012 Implementation Guidelines:*

- Payload shape: `{ "villagers": { villager_id: { "needs": { need_name: value }, "mood": float } } }`. Keep it flat and versionable; the orchestrator owns `save_format_version`.
- The AC24 trap is a plausible-looking bug: calling the spawn-init path on load "because it initializes cleanly" would silently erase 40 ticks of smoothing state. Load and spawn are **different entry points** — keep them separate functions and say so in the doc comment.
- Re-derivation on load: for each restored value, compute `Satisfied`/`Urgent` from the threshold; `Recovering` is never restored (a loading villager is not mid-report — Villager AI re-reports after its own deserialize).
- Schema drift: unknown need keys are logged via `push_warning` with the key name and dropped. Do not attempt migration.
- Ordering: per `CONTRACTS.md`'s load sequence, Villager AI is restored before Needs & Mood; do not assume the reverse.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: spawn initialization (the path this one must **not** reuse).
- The Save/Load orchestrator itself and the on-disk file format (its own VS epic).
- Villager AI's stale claim/bed-id revalidation (`villager-ai-024`).

---

## QA Test Cases

- **Round trip**: Given three villagers with distinct need values and moods, When serialized and deserialized through a mocked serializer, Then every value and mood matches exactly.
- **AC24**: Given a saved mood of 63.2 with sleep at 30.0, When loaded, Then mood is 63.2 — not 30.0 (F4 would have produced `mean_active`).
- **AC25**: Given a save containing a `thirst` need not in the schema, When loaded, Then it is dropped, a warning is logged naming the key, and no error is raised.
- **State re-derivation**: Given a restored sleep value of 12.0 (below `urgency_threshold`), When loaded, Then the state reads `Urgent` with **no** `need_urgent` emission (no signal replay).
- **Missing need**: Given a save lacking an active schema need, When loaded, Then that need initializes at 100.
- Edge cases: an empty save payload yields an initialized-but-empty system, not a crash; a restored value outside 0–100 is clamped with a warning; `Recovering` is never a restored state.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/needs_mood/save_load_serialization_test.gd` — must exist and pass (mocked serializer).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (values + state), 005 (mood), 006 (activation path for missing needs)
- Blocked on (scheduling, not code): the Save/Load & World Persistence GDD — VS-tier
- Unlocks: nothing in M02
