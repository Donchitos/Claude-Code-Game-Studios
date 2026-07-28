# Epic: Time & Tick System

> **Layer**: Foundation
> **GDD**: design/gdd/time-tick-system.md
> **Architecture Module**: Time & Tick System (`game_delta`/pause/warp computation; the global `tick` signal; tick accumulator)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 7 stories created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Time & Tick Autoload skeleton + config resource + boot defaults | Integration | Ready | ADR-0002/0001 |
| 002 | game_delta computation (formula, clamp, raw-delta preservation) | Logic | Ready | ADR-0002 |
| 003 | Pause & time-warp state (toggle, store, independence) | Logic | Ready | ADR-0002/0001 |
| 004 | Tick accumulator + global tick signal (drift-free) | Logic | Ready | ADR-0008/0002 |
| 005 | Max-ticks-per-frame safety cap | Logic | Ready | ADR-0002 |
| 006 | Cross-system integration guarantees (time_scale, transition non-suspension) | Integration | Ready | ADR-0001 |
| 007 | Per-tick re-tuning pass (tick-budget half) + per-frame cost measurement | Config/Data | Ready (needs-decision + cross-epic coordination) | ADR-0008/0002 |

## Overview

Time & Tick System owns the game's simulated clock: `game_delta` (raw delta with
pause=0 and a 1×/2×/3× warp multiplier), the tick accumulator, and the global
`tick()` signal that Building System, Villager AI, and Needs & Mood (M02) drive
their simulation off. It is an Autoload (one of only two) and has an explicit
non-dependency contract — it consumes nothing, not even Scene/World Management.
It guarantees ticks never fire while paused, pause is idempotent, warp changes are
synchronous, and callers derive durations from tick COUNTS, never wall-clock
arithmetic. The engine-global `Engine.time_scale` and `SceneTree.paused` are
permanently forbidden — pause/warp are owned here so camera/UI/overlays stay live
on raw delta.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Villager AI Execution & Threading | Base tick rate = 4.0 ticks/sec (time-tick-system.md authoritative); tick-driven FSM; `max_deciding_per_tick` budget is a config knob (Villager AI-owned, but bounded per tick) | MEDIUM |
| ADR-0002 / ADR-0001 | Tick tunables from typed `.tres` config; Autoload-tier (`load()`s its own config via `const CONFIG_PATH`) | MEDIUM |
| ADR-0012 | (No direct save state — simulation clock is not serialized; consumers derive from tick counts) | LOW |

Engine-risk basis (4.7 policy): **MEDIUM**. Mostly LOW-risk core scene-tree/signal
territory the LLM knows well, but two items require verification against
`docs/engine-reference/godot/`: `_physics_process` fixed-step default (confirm
still 60Hz in 4.7 — the tick accumulator depends on it) and the absolute ban on
`Engine.time_scale` / `SceneTree.paused` (a project-wide guardrail; using either
would freeze camera/UI/overlays that must run on raw delta).

## GDD Requirements

28 TRs registered (`TR-time-tick-system-*`). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-time-tick-system-020 | All tick tunables from config | ADR-0002 ✅ |
| (base tick rate) | 4.0 ticks/sec base rate; `game_delta`/warp semantics | ADR-0008 + GDD ✅ |
| (pause/warp) | Ticks never fire paused; synchronous warp; duration via tick count | GDD-specified ✅ |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; remaining TRs
are GDD-specified. No untraced requirements. The `Engine.time_scale`/
`SceneTree.paused` bans are Global-Rule guardrails (technical-preferences.md +
Control Manifest).

**At-risk / deferred**: None. `_physics_process` step is an API-verification item.

## Milestone 01 Notes — HOME OF ONE TECH DEBT (shared)

- **TECH DEBT 2 — Per-tick re-tuning pass (tick-budget portion) lands here.**
  Milestone-01 Must-Ship "Per-tick re-tuning pass done: `max_deciding_per_tick`
  and tick-budget values re-tuned against production load, recorded as a config
  change with rationale." This epic owns the **tick-budget / base-tick-rate**
  half. The **`max_deciding_per_tick`** half is a Villager AI config knob
  (ADR-0008) and lands in the `villager-ai-behavior` epic — the re-tune is a
  coordinated config change spanning both epics, recorded once with shared
  rationale. Both use the Foundation Spine `.tres` + rationale discipline.
- No CD-protected item lands here.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/time-tick-system.md` are verified
- Grep proves zero `Engine.time_scale` / `SceneTree.paused` usage
- The tick-budget half of the per-tick re-tune is recorded as a config change with rationale
- Logic stories have passing test files in `tests/`

## Next Step

Run `/create-stories time-tick-system` to break this epic into implementable stories.
