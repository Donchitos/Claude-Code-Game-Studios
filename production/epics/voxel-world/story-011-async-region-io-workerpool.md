# Story 011: Async region I/O + terrain-gen on a capped WorkerThreadPool

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 463/463 suite green twice, parent-verified)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1–1.5 days
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`, `TR-voxel-world-026`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 (Large-World Storage & Residency) — primary
**ADR Decision Summary**: Region reads, region-flush writes, AND terrain regeneration ALL run on a capped `WorkerThreadPool` (`MAX_CONCURRENT_ASYNC_TASKS`). A chunk whose background task is unfinished — OR could not be dispatched because the pool is at capacity — simply STAYS QUEUED for a later frame; it is NEVER regenerated or read synchronously on the main thread as a fallback. A synchronous fallback IS the failure mode.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: **`WorkerThreadPool.wait_for_task_completion()` returns an Error code, NOT the Callable's return value** (spike bug). A background task must write its result into a mutex-guarded structure, never rely on the return of `wait_for_task_completion`. The one sanctioned synchronous exception is per-region header I/O (Story 010).

**Control Manifest Rules (this layer)**:
- Required: all region I/O and terrain-gen on a capped `WorkerThreadPool`; cap-miss items stay queued; background results written into a mutex-guarded structure.
- Forbidden: NEVER synchronous disk I/O or terrain-gen in the per-frame path — full stop; never a synchronous fallback when the pool is at capacity.
- Guardrail: `io_worst`/`regen_worst` = 0.00 ms by construction; the async concurrency cap value is non-critical (cap-miss = "stay queued", not "run sync").

---

## Acceptance Criteria

- [ ] Region reads, region-flush writes, and terrain regeneration all run on the capped `WorkerThreadPool`; none runs synchronously on the frame path. [TR-voxel-world-053]
- [ ] A chunk whose task is unfinished, or could not be dispatched (pool at capacity), stays queued for a later frame — never read/regenerated synchronously as a fallback. [TR-voxel-world-053]
- [ ] Background task results are consumed from a mutex-guarded structure, never from `wait_for_task_completion`'s return value. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 Decision §6:*

- Dispatch region read/flush and terrain-gen as `WorkerThreadPool` tasks, capped at `MAX_CONCURRENT_ASYNC_TASKS` (config knob, tuned in Story 016). If dispatch fails because the pool is full, leave the item queued — do NOT fall back to a synchronous read/gen (the slice's ~55 ms tail came exactly from a synchronous fallback).
- Each task writes its result (loaded chunk bytes / generated chunk) into a mutex-guarded structure; the main thread reads results from there. Never use `wait_for_task_completion()`'s return as data.
- The completion drain (which resident chunks became ready) is handled by Story 017 (completion-driven), and the per-frame time budget by Story 012.

---

## Out of Scope

- Story 012: the time-based per-frame budget on how many ready items get integrated.
- Story 016: measuring/tuning `MAX_CONCURRENT_ASYNC_TASKS` and per-chunk gen cost.
- Story 017: the completion-driven drain loop.

---

## QA Test Cases

- **AC-1 (no sync I/O in frame path)**: [TR-voxel-world-053]
  - Given: the Voxel World residency source
  - When: grep for synchronous region read/flush/terrain-gen calls on the main thread path
  - Then: zero — all such work is dispatched to the `WorkerThreadPool`; only per-region header I/O (Story 010) is synchronous
- **AC-2 (cap-miss stays queued)**: [TR-voxel-world-053]
  - Given: the pool saturated at `MAX_CONCURRENT_ASYNC_TASKS`
  - When: an additional chunk is needed
  - Then: it remains queued and is dispatched on a later frame; no synchronous fallback occurs; frame time shows no I/O spike
  - Edge cases: many chunks needed in one frame (mass approach) — all beyond the cap stay queued
- **AC-3 (mutex-guarded results)**: [TR-voxel-world-053]
  - Given: a completed background load
  - When: the main thread consumes the result
  - Then: it reads from the mutex-guarded structure, not from `wait_for_task_completion`'s return

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/async_region_io_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 010 (region format + resident set), Story 006 (terrain-gen to run async for far regions)
- Unlocks: Story 012, Story 013, Story 016, Story 017
