# Epic: Pet State Machine

> **Layer**: Core
> **GDD**: design/gdd/pet-state-machine.md
> **Architecture Module**: Pet State Machine (#6)
> **Status**: Complete
> **Stories**: 4 stories created (2026-07-16), all Complete — see table below

## Overview

This epic implements Mochi's two-layer mood model: a persistent **Base Mood**
(a pure Riverpod derivation from Time & Decay's energy float — SLEEPING/SAD/
TIRED/CONTENT/HAPPY bands) and a transient **Triggered State** (EXCITED/
SHOWING_OFF/PLEASED/BOUNCING/LEVELING_UP, Flame-side only, never persisted or
mirrored to Riverpod). This module owns the energy→mood lookup table (delegated
here from Time & Decay), the triggered-state priority ordering with
non-interruptible LEVELING_UP, and the requirement that triggered-state timers
must correctly pause/resume across app backgrounding via Flame's native
`pauseWhenBackgrounded` mechanism — confirmed source-accurate against real Flame
1.37 during ADR authoring, and exercised successfully end-to-end by the vertical
slice (mood-color transitions were observed working, once a related Bridge-layer
bug in this epic's dependency was fixed).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0007: Pet State Machine Architecture | Base Mood = pure Riverpod derivation; Triggered State = Flame-side ephemeral, frame-ticked `TimerComponent`; priority ordering with non-interruptible LEVELING_UP; nothing may disable `pauseWhenBackgrounded` | MEDIUM — pause/resume behavior is source-verified against Flame 1.37, but depends on the shared root `FlameGame` never disabling `pauseWhenBackgrounded` (a cross-cutting constraint any future system must respect) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-petstate-001 | Two-layer model: persistent Base Mood plus transient Triggered State | ADR-0007 ✅ |
| TR-petstate-002 | Base Mood is a pure lookup on the energy float (energy owned by Time & Decay) | ADR-0007 ✅ |
| TR-petstate-003 | Triggered-state priority ordering, with non-interruptible LEVELING_UP | ADR-0007 ✅ |
| TR-petstate-004 | Triggered-state timers pause and resume correctly across app backgrounding | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/pet-state-machine.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- A test or manual evidence doc confirms the cold-start mood-seed behavior works correctly not just on app launch but on every fresh mount of the component hosting Mochi (see the Bridge epic's replay-scope fix — this epic's correctness depends on it)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Base Mood Pure Lookup + Providers | Logic | Complete | ADR-0007 |
| 002 | Cold-Start Base Mood Bridge Wiring | Integration | Complete | ADR-0007 |
| 003 | Triggered-State Priority Machine | Integration | Complete | ADR-0007 |
| 004 | Triggered-State Timer Backgrounding Pause/Resume | Integration | Complete | ADR-0007 |

**Recommended build order**: 001 → 002 → 003 → 004 (each depends directly on the previous — Story 002 extends the same `MochiComponent`/`_onEvent` switch Story 003 widens, and Story 004 needs Story 003's active triggered state to pause against).

## Next Step

Epic complete. `MochiComponent`, `petMoodProvider`, and the full triggered-state machine now exist and are ready for downstream consumers: Pet Interaction (#14), Pet Equipment (#15), Pet Leveling (#16), Seed Buffer (#10) — all emit trigger events this epic consumes — and Pet Room Screen UI (#18), which owns the actual `FlameGame`/`GameWidget` this epic's `MoodEventBridge`/`MochiComponent` were deliberately built to slot into.
