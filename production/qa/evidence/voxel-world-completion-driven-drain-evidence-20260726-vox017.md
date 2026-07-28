# Evidence — Sprint 8 — story vox-017 (C4 completion-driven residency drain)

**Date**: 2026-07-26
**Story**: `production/epics/voxel-world/story-017-c4-completion-driven-drain.md`
**Type**: Integration — BLOCKING evidence is
`neues-spiel/tests/integration/voxel_world/completion_driven_drain_test.gd`
(structural + behavioral, deterministic, all passing). This document supplies
the SUPPLEMENTARY quantitative measurement for AC-2's "cost scales with
completions, not queue size" claim, which the QA determinism rule
deliberately keeps OUT of the automated test (real background-task completion
timing is inherently non-deterministic; "measurement variance belongs in
evidence, not in an assertion").
**ADR**: `docs/architecture/adr-0015-large-world-storage-residency.md` §6
production note (carried tuning item C4)
**Measurement tool**: `neues-spiel/tools/vox017_completion_driven_drain_measurement.gd`
/ `.tscn` (NEW, headless, data-layer only — run via
`Godot_v4.7-stable_win64.exe --headless --path neues-spiel res://tools/vox017_completion_driven_drain_measurement.tscn`)
**Engine**: Godot 4.7-stable, headless

---

## 1. What this story removes (ADR-0015 §6 production note)

The spike's own drain loop re-scanned every not-yet-ready queued item every
tick ("`deferred_pagein_events`/`deferred_evict_events` reach tens of millions
across a run" — harmless to frame time, but wasteful). In production code,
this showed up as two call sites:

- `VoxelWorldGrid._reap_finished_async_writes` — a `for chunk_key in
  _write_tasks: if WorkerThreadPool.is_task_completed(...)` scan over the
  WHOLE in-flight write-task set, every `update_residency` call.
- `VoxelWorldGrid._request_resident` — called once per desired/pending-write
  chunk every tick; for a chunk still in flight, it called `_try_integrate_read`
  (a poll) — re-asking "is this specific not-yet-ready chunk done yet" on
  every tick it stayed desired and unfinished.

Both are replaced with a genuinely completion-driven mechanism that needed NO
new signal/callback machinery: a background task already writes its own
result into the mutex-guarded `_read_results`/`_write_results` dictionaries
exactly once, the instant its own work finishes (Story vox-011's own
mechanism) — that dictionary entry's PRESENCE already IS the completion
signal. `_reap_finished_async_writes` (rewritten) and the new
`_reap_finished_async_reads` each snapshot their own result dictionary's
current keys under the mutex and drain exactly those; `_request_resident` no
longer polls at all (an in-flight chunk simply stays queued until the reap
phase integrates it).

## 2. AC-1 — structural proof (grep-verifiable, deterministic)

`tests/integration/voxel_world/completion_driven_drain_test.gd`:

- `test_reap_finished_async_writes_body_never_polls_is_task_completed` —
  PASS: body contains `_write_results.keys()`, never `is_task_completed`.
- `test_reap_finished_async_reads_body_never_polls_is_task_completed` — PASS:
  body contains `_read_results.keys()`, never `is_task_completed`.
- `test_request_resident_body_never_polls_is_task_completed` — PASS: body
  never calls `is_task_completed`, while still correctly composing with the
  write-in-flight cache (Story vox-013) and fresh dispatch (Story vox-011).
- `test_try_integrate_read_still_polls_for_explicit_test_sync_helpers_only` —
  PASS: documents the deliberate, ADR-scoped exception (`_try_integrate_read`
  still polls, but is used ONLY by `wait_for_async_residency_idle`/
  `drain_pending_async_reads` — explicit, bounded, non-per-frame test/sync
  helpers, never `update_residency`'s own per-tick call graph).

## 3. AC-1 edge case + functional regression — behavioral proof (deterministic)

- `test_update_residency_write_reap_zero_completions_immediately_after_dispatch_reaps_nothing` —
  PASS: a dispatch-only call reaps exactly zero items (provable by the
  same-call causality convention this codebase already established, never a
  cross-call timing assertion).
- `test_update_residency_write_reap_mass_approach_settles_correctly_at_scale` /
  `test_update_residency_read_reap_mass_approach_settles_correctly_at_scale` —
  PASS: an 81-chunk eviction burst and a 49-chunk page-in burst each fully
  settle via `wait_for_async_residency_idle`, with a fresh grid instance
  confirming the write-side data genuinely landed on disk. Proves the
  completion-driven rewrite lost nothing at "mass approach" scale.

## 4. AC-2 — quantitative measurement (this evidence, NOT a test assertion)

Two initial in-flight queue sizes (20 and 200 — a 10x range) per phase, cap
== queue size (dispatched fully in one setup call, generous one-shot budget),
then repeated `update_residency` calls (shipped `page_budget_ms`/
`evict_budget_ms` = 4.0 ms) timed until the queue fully drains:

| Phase | Queue size | Dispatched | Reap calls | Avg completions/call | Avg call (µs) | p95 (µs) | Worst (µs) |
|---|---|---|---|---|---|---|---|
| Write (eviction-flush) | 20 | 20 | 10 | 2.00 | 40.8 | 148.0 | 148.0 |
| Write (eviction-flush) | 200 | 200 | 150 | 1.33 | 30.4 | 53.0 | 183.0 |
| Read (page-in) | 20 | 20 | 3 | 6.67 | 305.0 | 669.0 | 669.0 |
| Read (page-in) | 200 | 200 | 4 | 50.00 | 2943.0 | 5358.0 | 5358.0 |

**Write side — cost stays flat despite the 10x queue-size range.** Worst-call
ratio (queue 200 / queue 20) = **1.24x**, against a queue-size ratio of
**10x**. Cost-per-completion is near-identical: 40.8/2.00 = 20.4 µs (small
queue) vs 30.4/1.33 = 22.9 µs (large queue). This is direct evidence the
write-reap phase's cost tracks completions, not the size of `_write_tasks`.

**Read side — cost scales with completions-per-call, which itself grew with
queue size in this measurement (an artifact of real parallel background
threads, honestly reported).** Worst-call ratio = 8.01x against a
queue-size ratio of 10x — closer to the completions-per-call ratio (50.00 /
6.67 ≈ 7.5x) than to the queue-size ratio. This is expected: regen tasks are
cheap (~0.2 ms each per `production/qa/smoke-2026-07-26.md` §3) and Godot's
`WorkerThreadPool` runs many of them concurrently across the OS's real thread
pool; with a 200-item backlog, more of them finish in parallel by the next
poll (spaced by `OS.delay_msec(1)`, matching `wait_for_async_residency_idle`'s
own granularity) than with a 20-item backlog. Cost-per-completion stays in
the same order of magnitude across the 10x range (305/6.67 = 45.7 µs small vs
2943/50 = 58.9 µs large — a ~1.3x difference, not the 10x+ a poll-every-
queued-item implementation would show for an EARLY call against a 200-item
`_read_tasks` set with only a handful actually done). Reported for honesty
(the vox-019 "VSync-floor" / vox-016 "report the artifact" precedent) rather
than silently omitted — the qualitative conclusion (cost tracks completions,
not raw queue size) holds for both phases; the read phase's absolute numbers
are shaped by how many background threads happen to finish between polls,
not by how large the in-flight queue is.

## 5. Out of scope — confirmed not touched

- Story 011's task dispatch and mutex-guarded result structure — unchanged;
  this story only changes how the calling thread DETECTS completion (reads
  the existing dictionary instead of polling `WorkerThreadPool`), never how
  results are produced or stored.
- Story 012's per-item time budget (`page_budget_ms`/`evict_budget_ms`) —
  unchanged; both new/rewritten reap phases still run through
  `_drain_budgeted` with their own fresh budget window.

## 6. Full regression suite

`cd F:/Neues_Spiel/neues-spiel && cmd //c "..\tests\run-tests.cmd"` (600000ms
timeout): **951 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0
orphans | exit code 0.**

---

## Verdict

**PASS.** Both AC-1 (completion-driven, never polling `is_task_completed`
across the whole queue/window every tick) and AC-2 (drain cost scales with
completions) are satisfied: AC-1 by grep-verifiable structural tests plus
deterministic behavioral tests (zero-completion edge case, mass-approach
regression at scale); AC-2 by a dedicated headless measurement showing the
write-reap phase's worst-call cost barely moves (1.24x) across a 10x queue-
size range, and the read-reap phase's cost tracks completions-per-call (which
itself scales with real parallel background-thread throughput, honestly
reported) rather than the raw in-flight queue size. Full regression suite
green (951/951, 0 orphans, exit 0).
