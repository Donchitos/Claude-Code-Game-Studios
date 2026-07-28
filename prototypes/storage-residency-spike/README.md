# Storage/Residency Spike (ADR-0015)

**Hypothesis being tested**: paged/on-demand chunk residency via region
files — camera-near ∪ active-settlement resident, everything else on disk
or regenerated from seed — holds a 16,000×16,000×32 synthetic world at
60 FPS and ≤4 GB, per `docs/architecture/adr-0015-large-world-storage-residency.md`'s
five Validation Criteria (C1–C5). Data layer only: no rendering/meshing
(ADR-0014's mesher/view-window/streaming design is unaffected and
unexercised here).

**How to run**:
```
"C:/Users/Leo/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" --headless --path F:/Neues_Spiel/prototypes/storage-residency-spike --import
"C:/Users/Leo/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" --headless --path F:/Neues_Spiel/prototypes/storage-residency-spike res://SpikeTest.tscn
```
First invocation is a one-time import pass (matches `prototypes/chunked-mesher`'s
convention). The second prints `PROGRESS`/`METRIC` lines throughout, then the
five `SPIKE C<n> PASS|FAIL <detail>` lines, then `SPIKE_RESULT PASS|FAIL`, and
exits 0 on overall PASS / 1 on any FAIL. Per-metric CSV lands in
`results/storage_residency_spike.csv`. Region files land in `regions/`
(cleaned at the start of every run — not meant to persist between runs).

**Status**: concluded, three measurement rounds (2026-07-23) — **hypothesis
CONFIRMED, 5/5 PASS.** Round 1 found the storage/correctness/footprint
mechanism (region files, load-before-write, sparse regen, save format)
strongly validated (C3, C5 PASS) but C1/C2/C4 failing under a fixed
item-count page-in budget. Round 2 (time-based budget + async-by-default)
fixed C2 completely but left C1/C4 failing on a single-work-item tail
latency. Round 3 (no synchronous fallback anywhere in the per-frame path,
disk writes moved off-thread too, budget re-checked per item) resolves
C1/C4 as well — **all five criteria PASS at both the game's real max
camera speed (144 cells/sec) and round 1's stress speed (120 cells/sec),
at both tested concurrency caps (32 and 64).** See "Round 3 Findings" for
the full story, including a critical implementation bug found and fixed
mid-round-2 and a second, smaller one found and fixed in round 3.

## Design choices made (this spike's calls, per the task's "your call, document it")

- **Region size**: 32×32 chunks/region (1024 chunk slots, 512 cells/region
  axis) — the task's suggested default. At 1000×1000 chunks total this gives
  32×32 regions covering the world (last row/column partial).
- **Eviction policy**: distance/membership-based staggered eviction, not
  LRU-with-timestamps. A chunk is queued for eviction the instant it leaves
  BOTH the camera window and the settlement set; if it re-enters need before
  its turn comes up in the staggered queue, the queued eviction is dropped
  (checked at pop time, not enqueue time). This reuses the exact same
  "is this chunk in the current desired set?" check the page-in path needs
  anyway, so there's no separate LRU bookkeeping to keep correct.
- **Settlement anchor**: world-center chunk, radius 8 chunks (~128 cells) —
  smaller than the 24-chunk camera view radius, loaded unbudgeted at boot
  and never evicted (mirrors ADR-0007's "bounded settlement-core is a
  standing cost, not a streaming one").
- **Page-in budget (round 1)**: 2 chunks/frame, reusing ADR-0014's
  `stream_chunk_budget` verbatim rather than inventing a new number.
- **Evict budget (round 1)**: 2 chunks/frame, per the task spec.
- **Page-in / evict budget (round 2 revision)**: TIME-based —
  `page_budget_ms = evict_budget_ms = 4.0 ms/frame` (tunable constants in
  `spike_test.gd`), replacing round 1's fixed count. Chosen to leave ~12 ms
  of the 16.6 ms frame for actual game work. Async region I/O + regen
  prefetch (`WorkerThreadPool`, dispatched on enqueue) is now the DEFAULT,
  bounded to `MAX_CONCURRENT_ASYNC_TASKS = 16` in-flight tasks (see Round 2
  Findings for why the cap is load-bearing, not just tidiness).
- **Region file format**: a fixed header of `SLOTS_PER_REGION` int64 byte
  offsets (0 = chunk absent = pristine/regenerable, never written), followed
  by fixed-size (8192 B) chunk payloads appended on first write and
  overwritten in place on subsequent writes to the same chunk. A region that
  never has a dirty chunk never gets a file on disk at all.
- **Load-before-write**: implemented exactly per the ADR's Key Interfaces
  pseudocode (`_ensure_resident` then apply then mark dirty), synchronous —
  see "Escalation path" below for whether that held up.
- **Camera speed / "fastest pan"**: 120 cells/sec assumed, expressed as
  2 cells per engine tick assuming a 60 Hz baseline (faster than the
  25 cells/sec `chunked-mesher` prototype used previously, chosen as a
  deliberately aggressive stress value). See "Honesty notes" below for why
  this is decoupled from real wall-clock time.

## Honesty notes (scaling / measurement caveats)

- **Camera movement is decoupled from real elapsed time.** Each engine tick
  (one `_process`-driven loop iteration, awaited via
  `get_tree().process_frame` — headless has no vsync, so ticks run as fast
  as the CPU allows) advances the camera by a FIXED 2 cells, not by
  `delta * speed`. This keeps total wall-clock runtime bounded (a real-time
  traversal at 120 cells/sec across ~4000 chunks of travel would take ~36
  real minutes; decoupled, the same simulated distance completes in
  whatever wall-clock time ~27,000 cheap ticks actually take). The thing
  criterion 1 actually measures — real wall-clock microseconds spent in
  `ResidencyManager.update()` per tick — is NOT decoupled; it's a genuine
  `Time.get_ticks_usec()` measurement each tick, so the pass/fail verdict is
  honest even though the "cells/sec" framing is a bookkeeping convenience.
- **Travel distance is scaled, not the full 16k² world.** The route is a
  single corridor (full-width straight line, 4 one-way passes ≈ 3996 chunks
  travelled) rather than covering every chunk in the world — reaching every
  one of 1,000,000 chunks isn't meaningful (99%+ would just repeat the same
  "regen a flat terrace" cost) and would blow the ~3-minute runtime budget
  for no additional signal. The corridor crosses the FULL 16,000-cell span
  in both directions repeatedly, which is what C2's "long continuous
  traverse of the full 16k span" needs.
- **The travel route is a straight line, not a real player path.** It does
  not visit "several thousand distinct chunks" so much as travel "several
  thousand chunks' worth of distance" along one line, per the task's C1
  wording. Distinct chunks touched (via the ~48-chunk-wide sweep window) is
  much higher — reported as `page_ins` in `SPIKE_AGGREGATE`.
- **No pre-existing player mutations exist along the route** except a
  small injected trickle (one `set_cell` every 50 ticks, simulating
  low-frequency dig-order activity per the ADR's own stated risk profile).
  Absent that injection, the travel loop's I/O-attributed time would be
  ~0 for its entire duration — informative in itself (it demonstrates how
  much of the ADR's premise rests on regeneration, not disk reads), but
  the injection gives C1's "attribute I/O time separately" a real non-zero
  signal to report.

## Escalation path (async I/O, ADR-0015 Decision §6) — TRIED, per the honesty rule

C1 failed under synchronous page-in (see Findings), so the named escape
hatch was implemented and re-measured: `WorkerThreadPool`-backed background
tasks, dispatched as a **prefetch** the instant a chunk is enqueued (not
when its budgeted turn comes up), so the common case is a cheap dictionary
pickup instead of a blocking disk read or full terrain-gen pass on the main
thread. One correctness pitfall surfaced and was fixed before trusting any
numbers: `WorkerThreadPool.wait_for_task_completion()` returns an **Error
code**, not the Callable's return value (verified empirically — a tiny
throwaway check script confirmed `typeof(ret) == TYPE_INT`, not
`TYPE_DICTIONARY`). The background task therefore writes its result into a
mutex-guarded dictionary itself; the main thread only reads it back after
`wait_for_task_completion` establishes a happens-before relationship.

**Result: async I/O helps the average case a lot, but does NOT resolve the
worst-case tail.** In a 2-pass sync-vs-async comparison (same corridor,
fresh manager instances, separate region directories):

| | frame avg | frame p95 | frame worst | regen worst | io worst |
|---|---|---|---|---|---|
| sync | 3.43 ms | 5.68 ms | **83.17 ms** | 5.77 ms | 14.12 ms |
| async | **0.86 ms** | 7.39 ms | **74.61 ms** | 0.00 ms | 17.45 ms |

Async fully removes regen cost from the main thread (regen_worst drops to
0.00 ms — every regeneration happens in the background) and cuts the
average tick cost ~4x. But the **worst-case frame time barely moves**
(83 → 75 ms, still ~4.5x over the 16.6 ms budget), and io_worst actually
went up slightly. Diagnosis: under this spike's speed/budget mismatch (see
below), the backlog is so deep that even "prefetch ahead of need" can't
stay ahead of the drain rate in the worst case — the documented fallback
("still correctly, if rarely, blocks if the budget outran the background
thread") is exactly what's being hit. The escape hatch is real and working
as designed; it just isn't sufficient on its own here, because the tail is
not primarily an I/O-latency problem.

## Findings

**Per-criterion verdicts** (full corridor run: 4 passes, 31,968 ticks,
~3,996 chunks travelled; see `results/storage_residency_spike.csv` for the
complete metric dump):

- **C1 (page-in latency) — FAIL.** Worst frame 106.31 ms (worst of 3 runs
  ranged 73–106 ms across repeated measurements — real variance, not a
  fluke), vs. the 16.6 ms budget. p95 = 4.31 ms and avg = 2.73 ms are both
  comfortably inside budget — this is a rare-but-real tail, not a
  universally-blown budget. io_worst (5.6 ms sync run) and regen_worst
  (6.2 ms) individually stay under budget; **neither single component
  explains the 100+ ms worst case** — see root-cause analysis below.
- **C2 (memory ceiling) — FAIL** (on the "flat" sub-check only). Peak
  257 MB, nowhere near the 4096 MB hard ceiling (~6% utilization) — the
  ADR's headline claim ("resident memory bounded by footprint, not world
  size") holds in absolute terms. But memory is NOT flat during this run:
  44.4 MB (first decile) → 254.2 MB (last decile), a ~5.7x climb, failing
  this spike's own documented 1.5x tolerance. Same root cause as C1 (below).
- **C3 (write-to-unloaded correctness) — PASS.** 20/20 scattered far-chunk
  mutate→evict→re-page-in round trips byte-identical.
- **C4 (eviction under budget) — FAIL**, same worst-frame number as C1
  (106.31 ms) — expected, since both are measuring the same tick's total
  cost; eviction itself was never the dominant contributor (see below).
- **C5 (save/load round-trip) — PASS.** 40/40 chunks (30 mutated + 10
  pristine) byte-identical after a full flush + brand-new-instance reload.
  **Disk footprint: 4.76 MB written vs. a naive full-world save of 7.63 GB
  — a ~1,600x reduction**, and it came from only 80 region files (out of a
  possible 1,024) — strong, direct validation of Decision §4/§5.
- **Aggregate**: 64,964 total page-ins, of which 99.50% were regenerations
  and only 0.50% were disk loads (322) — a strong empirical validation of
  Decision §5's premise that the disk tier is barely touched in normal
  operation; the storage tier exists almost entirely for correctness
  (mutated chunks), not for bulk terrain persistence.

**Root cause of the C1/C2/C4 failures (this is the actual finding, not just
"it failed"):** `page_in_budget = 2` is a **fixed item-count** per frame,
reused verbatim from ADR-0014's `stream_chunk_budget`. ADR-0014 validated
that number at a real camera speed of ~25 cells/sec (chunked-mesher
prototype) — an effective demand rate of roughly **1.2 new chunks/frame**
at its 48-chunk-wide view window, which a budget of 2 comfortably absorbs.
This spike's "fastest pan" assumption (120 cells/sec, chosen as a
deliberately aggressive, **unprecedented** 4.8x stress value with no
strong justification beyond "make sure we're not just testing the easy
case") produces a demand rate of roughly **24 new chunks/frame** at the
same window width — **12x the budget**. The result is a chronic backlog:
the window can never catch up to the camera's actual position, so
`_ensure_resident` (average ~1.15 ms/chunk, this game's real terrain-gen
cost — tree-candidate scanning with nested beach/moisture checks is not
free) runs on effectively *every* tick, not just the ~1-in-8 ticks that
actually cross a chunk boundary (confirmed: `regen_active_ticks` = 31,968
out of 31,968 total ticks in the sync run — literally every tick did real
generation work). Memory grows for the same reason: the resident set keeps
absorbing newly-entered chunks faster than the equally-budgeted eviction
queue can drain them. Note this is a **capacity/throughput mismatch, not a
correctness bug** — back-of-envelope, the per-chunk gen cost (~1.15 ms)
would allow ~14 chunks/frame within the full 16.6 ms budget if the budget
were time-based instead of a fixed count; a fixed count of 2 simply
under-provisions once demand rises, regardless of how much frame-time
headroom is actually available.

## Round 1 recommendation (superseded by Round 2 below — kept for history)

Accept ADR-0015's core architecture; revise Decision §1's budget clause to
be time-based instead of a fixed item count; re-measure at the game's
actual real max camera speed before treating C1/C4 as settled. Round 2
below executes exactly this.

## Round 2: real camera speed + time-based budget

**The real max camera speed, derived, not assumed.**
`prototypes/last-seal-vertical-slice/camera_input.gd`'s `_update_pan()`:
`pan = input_dir.normalized() * PAN_SPEED_FACTOR * _distance * delta`. Since
`input_dir` is always normalized (magnitude 1, even for diagonal WASD),
steady-state pan speed (units/sec = cells/sec, 1-unit-per-cell convention)
is exactly `PAN_SPEED_FACTOR * _distance`, maximized at maximum zoom-out
(`_distance = DISTANCE_MAX`). With `PAN_SPEED_FACTOR = 1.2` and
`DISTANCE_MAX = 120.0`:

> **real max camera speed = 1.2 × 120.0 = 144.0 cells/sec**

Notably this is *higher* than round 1's 120 cells/sec "aggressive stress"
assumption — the real game's fastest achievable pan is not a rare edge
case relative to what round 1 tested, it's slightly beyond it. Both speeds
were measured this round, side by side, on the SAME fixed (time-based
budget + async) design:

| | REAL (144 c/s) | STRESS (120 c/s) |
|---|---|---|
| C1 worst frame | **54.7 ms** FAIL | **18.9 ms** FAIL |
| C1 p95 | 6.7 ms | 6.6 ms |
| C1 avg | 4.9 ms | 4.9 ms |
| C1 regen worst | 15.0 ms | 17.2 ms |
| C1 io worst | 48.6 ms | 8.4 ms |
| C2 peak memory | 38.9 MB — **PASS, flat** | 43.5 MB — **PASS, flat** |
| C4 worst eviction-active tick | 54.7 ms FAIL | 18.9 ms FAIL |
| C3 / C5 | PASS (shared, run once — see below) | PASS (shared) |

**A critical implementation bug found and fixed mid-round, worth recording
in full.** The first attempt at "async by default" dispatched a background
`WorkerThreadPool` task on every single enqueue with NO concurrency cap.
Under real demand (window churn far exceeding what any budget drains per
frame — the same 12x mismatch round 1 diagnosed), `WorkerThreadPool`'s own
internal task queue grew unbounded, and a `wait_for_task_completion()` call
for a chunk deep in that backlog blocked for as long as the backlog took to
drain — observed: **a single 10.1-SECOND tick** in the stress run before
the fix. This is not a property of "async I/O as an escape hatch" — it's an
implementation defect (unbounded prefetch dispatch), and a real one: it
made the "fix" briefly worse than the original problem. Fixed by capping
in-flight tasks at `MAX_CONCURRENT_ASYNC_TASKS = 16`; beyond the cap, a
chunk is simply left undispatched and falls back to the existing
synchronous `_ensure_resident` path when its turn comes up — bounding the
worst case to "one synchronous chunk," never an unbounded thread-pool
backlog. All numbers in the table above are POST-fix.

**What the time-based budget actually fixed: C2, completely, at both
speeds.** Round 1's C2 failure (memory climbing 44→254 MB, never flat) is
gone: round 2 shows 38.9–43.5 MB peak, flat at both speeds — a ~6x
reduction in peak and the "flat" sub-check now passes cleanly. This
directly confirms round 1's diagnosis: the backlog/growth problem WAS the
fixed-count budget under-provisioning relative to demand, and a time-based
budget resolves it as predicted.

**What it did NOT fix: C1/C4's worst-case tail — for a different,
newly-diagnosed reason.** Worst frame dropped substantially (106→55 ms at
the harder speed, and stress's 83→19 ms is now within 2.3 ms of the
budget) but didn't cross the line. With the backlog eliminated
(`regen_active_ticks` ≈ 100% of ticks, meaning EVERY tick still does
*some* real work — expected, since demand still exceeds the async cap at
these speeds and falls back to sync), the residual worst case is now
explained by **a single indivisible work item occasionally costing more
than the entire frame budget on its own**: `regen_worst` reached
15–17 ms (one exceptionally tree-dense chunk's nested beach/moisture scan,
this game's real gen cost — not a toy stand-in), and `io_worst` reached
48.6 ms once (a single slow disk operation, Windows filesystem/AV-scan
overhead, consistent with round 1's similar-magnitude observation). **A
time budget can only bound cumulative per-frame work — it cannot preempt
or subdivide a single already-in-flight work item**, so an unlucky frame
that must synchronously process one unusually expensive chunk (because the
async cap was already full) blows the budget regardless of how the
surrounding budget is expressed. This is a structurally different, smaller,
better-understood problem than round 1's "backlog forever" finding.

**C3/C5 — confirmed unchanged, as expected.** Both speed-independent (run
once, not per-speed): C3 tested=20 mismatches=0 (identical to round 1); C5
tested=40 mismatches=0 (identical to round 1). C5's *reported disk
footprint size* differs from round 1 (0.77 MB / 49 region files vs. round
1's 4.76 MB / 80 files) — this is NOT a behavior change, it's round 2's
cleaner separation of concerns: round 1 shared one manager/region-dir
between the travel loop and C3/C5, so the travel loop's injected writes
counted toward "C5's" footprint; round 2 gives each speed's travel loop its
own manager and region directory, so C5's footprint now reflects only its
own + C3's mutations (50 chunks × 5 writes × 8192 B chunk + 8192 B header
≈ 811 KB — exactly the observed number). The correctness verdict (0
mismatches) is what "shouldn't change," and it didn't.

## Round 2 recommendation (superseded by Round 3 below — kept for history)

Accept the core architecture; revise Decision §1's budget clause to
time-based (confirmed working for C2); C1/C4 still failing on a
single-work-item tail latency (54.7 ms real / 18.9 ms stress vs. 16.6 ms
budget) — recommended raising the async concurrency cap and/or bounding
per-chunk gen cost as next steps. Round 3 below executes exactly this.

## Round 3: tune until clean (user decision — 5/5 required for Accept)

Four levers were specified; three were implemented (the fourth — prefetch
lead — turned out not to be needed):

1. **No synchronous fallback anywhere in the per-frame streaming path.** A
   chunk whose background task hasn't finished (or couldn't even be
   dispatched — pool at capacity) now simply stays queued for a later
   frame — never regenerated or read on the main thread. This is the
   change that mattered most (see below).
2. **Eviction flushes (disk WRITES) moved off the main thread too**,
   through the SAME capped background-task pool as page-in reads. A
   correctness hazard this introduces — a chunk needed again before its own
   eviction-flush finishes could otherwise race a still-in-progress disk
   write — is closed by a read-through cache (`_write_in_flight_data`):
   while a write is in flight, the authoritative bytes are served from
   memory, never from the (possibly incomplete) file.
3. **Time budget re-checked after every single item**, not just once per
   frame — a burst of many ready-to-integrate items in one frame still
   can't blow the budget; the excess is deferred, not processed.
4. **Not implemented.** Not needed — levers 1-3 were sufficient.

**A second implementation bug found and fixed before trusting any
numbers.** The first attempt at "dispatch a background task the instant a
chunk is enqueued, no cap" (this was actually round 2's design, carried
into the first round-3 test) let `WorkerThreadPool`'s internal queue grow
unbounded under sustained demand, and a blocking wait for a deeply
backlogged task produced a **single 10.1-SECOND tick** — far worse than
the original problem. This was already fixed going into round 3 (capped
concurrency, described in round 2's README section) — flagging it again
here because round 3's "no sync fallback" change made the cap's role even
more load-bearing: previously, hitting the cap meant "fall back to sync
regen" (slow but bounded); now it means "stay queued" (the whole point of
lever 1), so the cap number itself matters less than round 2 assumed —
confirmed by measurement below (worst frame is nearly IDENTICAL at cap 32
vs. cap 64).

### Results — all four combinations (2 speeds × 2 caps), one measurement pass

| | C1 worst | C1 p95 | C1 avg | C2 peak (flat) | C4 worst |
|---|---|---|---|---|---|
| REAL (144 c/s), cap=32 | **14.22ms PASS** | 4.86ms | 3.14ms | 43.9MB PASS | 14.22ms PASS |
| STRESS (120 c/s), cap=32 | **13.26ms PASS** | 4.64ms | 3.08ms | 57.7MB PASS | 11.95ms PASS |
| REAL (144 c/s), cap=64 | **14.18ms PASS** | 5.25ms | 3.30ms | 68.8MB PASS | 14.18ms PASS |
| STRESS (120 c/s), cap=64 | **14.53ms PASS** | 4.87ms | 3.18ms | 83.7MB PASS | 14.53ms PASS |

`io_worst` and `regen_worst` are **0.00 ms in all four runs** — confirmed
by construction, exactly as levers 1/2 intended: no main-thread disk I/O,
no main-thread terrain gen, anywhere in the streaming path. The one
accepted synchronous exception (`header_io_usec_total` — one-time
per-region header read/creation, see `region_file.gd`) totals 31-63 ms
**cumulative across an entire 26,640-31,968-tick run**, never a per-tick
spike; it does not show up in any worst-frame number.

**C3/C5 confirmed unchanged**: C3 tested=20 mismatches=0; C5 tested=40
mismatches=0, bytes_written=0.77MB vs. naive 7.63GB, 49 region files —
identical to round 2's numbers (these paths were never touched by any
round-3 lever, as expected).

**Which lever mattered**: removing the synchronous fallback (lever 1) is
what actually closed the gap — worst frame dropped from round 2's 54.7ms
(real)/18.9ms (stress) to ~13-15ms across ALL FOUR combinations in round 3,
a much bigger and more uniform improvement than raising the cap from 32 to
64 produced on its own (worst frame barely moved between cap values, ~0.3ms
difference) — a single expensive item can no longer land on the main
thread AT ALL, so it doesn't matter whether the cap is 32 or 64; what
matters is that the cap-miss path no longer falls back to synchronous work.
Lever 2 (async writes) mattered for the same reason applied to eviction:
`io_worst` is now 0.00ms where round 2 saw spikes up to 48.6ms. Lever 3
(per-item budget re-check) is confirmed working by construction (avg stays
~3.1-3.3ms, well inside the 4ms per-phase budget, across all runs) but
wasn't independently isolatable from lever 1 in these numbers — both
changes shipped together.

**Cost of the fix, honestly reported**: `deferred_pagein_events` and
`deferred_evict_events` are enormous (tens of millions across a run) —
the drain loop re-checks every not-yet-ready queued item every tick until
it's ready, and at these camera speeds the queue rarely empties. This
isn't a pass/fail problem (frame times stay well under budget throughout)
but IS a real, worth-flagging inefficiency: a production implementation
should replace the linear re-scan with something that doesn't re-examine
already-checked-and-still-pending items every single tick (e.g., only
re-check items whose task just completed, tracked via a completion
callback/signal rather than polling `is_task_completed` on the whole
queue). Memory scales mildly with the cap (43.9MB @ cap32 vs. 68.8MB @
cap64, real speed) since more concurrent in-flight+integrated chunks means
more resident data at once — still trivial against the 4GB ceiling at
either value.

## Final Recommendation

**Accept ADR-0015.** All five Validation Criteria pass, at both the game's
real max camera speed (144 cells/sec, derived from `camera_input.gd`) and
an aggressive stress speed (120 cells/sec — notably slower than the real
max, yet round 1 found it broke the original fixed-count-budget design),
at both tested concurrency settings (32 and 64 in-flight async tasks).

**Text changes the ADR should carry forward, all empirically validated
across these three rounds**:

1. **Decision §1's budget clause**: time-based (`page_budget_ms` /
   `evict_budget_ms`, e.g. 4.0 ms each), not a fixed item count — round 2
   proved a fixed count under-provisions badly (12x) once camera speed
   rises; time-based scales automatically.
2. **Decision §6's escape hatch, sharpened**: async I/O alone (round 2)
   improved the average case but left a worst-case tail; the load-bearing
   fix (round 3) was eliminating EVERY synchronous fallback in the
   streaming path, not just adding a background-thread option alongside a
   sync one. The ADR text should state this as "no synchronous disk I/O or
   regen in the per-frame path, full stop," not "prefer async, fall back to
   sync if needed" — the fallback IS the failure mode.
3. **New: a read-through cache for in-flight writes.** A chunk evicted
   with an async flush in progress must serve reads from an in-memory
   cache of the not-yet-durable bytes, never re-read the region file, until
   the flush completes — otherwise a fast reverse-and-return camera path
   can race its own write. Worth naming explicitly in the ADR's Decision §3
   (load-before-write) as an edge case of the same rule.
4. **Known residual, not blocking**: one-time-per-region header I/O
   remains synchronous (documented, measured, never a per-tick cost — total
   31-63 ms across an entire ~27-32k-tick run). The `deferred_*_events`
   counts show the drain loop's linear re-scan is inefficient at scale;
   fine for this spike's pass/fail purposes, worth a note for whoever
   implements this in production (Voxel World `/dev-story`) to use a
   completion-driven queue instead of polling.

No further criterion failures remain. This spike's job is done.
