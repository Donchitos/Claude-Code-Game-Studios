# Review Log — Dive Runtime & Event Log

## Review — 2026-07-04 — Verdict: NEEDS REVISION (blockers resolved in-doc same session)
Scope signal: XL
Specialists: systems-designer, game-designer, qa-lead, godot-specialist, network-programmer, performance-analyst (senior synthesis inline)
Blocking items: 6 | Recommended: 6
Prior verdict resolved: First review

**Summary:** The architecture spine (commands-in/facts-out, the three contracts,
append-only log) was affirmed sound by both the netcode and engine specialists — no
redesign needed. The through-line concern across all six specialists: the
replay/determinism guarantee was stated more confidently than it was specified. Six
blocking items were fixed in-document this session; five ADRs remain the gating work
before implementation.

**User-ratified design decisions (2026-07-04):**
1. Numeric model = exact-hash; tolerance-based comparison ruled out for canonical
   hashing; fixed-point vs pinned-float left to the ADR.
2. `incapacitated → active` revive edge reserved (not foreclosed), gated behind Combat GDD.
3. Determinism AC scope = same-build/same-platform now; cross-platform deferred to netcode ADR.
4. Same-tick combat-lethal at extraction → `incapacitated` (Death Dial); the deep → `dead`.

**Blocking items resolved in this revision:**
- B1 Determinism reframed as a computation-model ADR ("what math the Authority may
  use"), tolerance ruled out for canonical hashing, AC1/AC10 scoped to same-build/platform.
- B2 F5 self-contradiction fixed: runtime periodic checksum (early-warning) vs harness
  exhaustive per-tick mode (exact first diverging tick).
- B3 Death Dial fidelity: same-tick lethal split by source (oxygen→dead, combat→incapacitated);
  revive edge reserved.
- B4 Envelope schema completed: added `phase_slot` (generating-phase semantics),
  `corrects`/`superseded_by` correction fields.
- B5 Command stream specified: per-participant `command_seq`, admitted-order canonicalization,
  replay-replays-recorded-order, `command_granularity` coalescing knob.
- B6 ACs repaired: AC4 bounded, AC5/AC6 reclassified as forward contracts, AC8 per-reason,
  AC10 split static/dynamic; added coverage ACs 11–17 (transition legality, quit≠abort,
  same-tick precedence, mutual kill, ordering invariant, malformed hard-fail, perceived fairness).

**Recommended items folded in:** netcode foundation constraints (topology single-authority,
Speculative Replica, local-transport-only admission, pre-transmission projection cull, reserved
`disconnected` grace state); formula guards (int/float division, TICK_RATE/CELL_SIZE validation,
dive_id uniqueness, contributing_events direct-only + cycle-safe walk); perf (state_checksum_interval
default 30–60 ticks, in-memory-vs-streamed open question, TD performance-budget blocker); Godot 4.6
engine constraints routed to the control manifest.

**Remaining gating work (ADRs, not doc edits):** numeric-determinism/math-model,
runtime architecture shape, event-log storage/serialization, netcode authority model,
replay test harness. Plus a technical-director performance-budget decision that the cost-side
ACs depend on.
