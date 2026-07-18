# Epic: Time & Decay

> **Layer**: Foundation
> **GDD**: design/gdd/time-decay.md
> **Architecture Module**: Time & Decay (#2)
> **Status**: Complete
> **Stories**: 2 stories created (2026-07-16), both Complete — see table below

## Overview

This epic implements the pure, on-foreground calculation that turns real-world
elapsed time into Mochi's current energy: `computeEnergy(storedEnergy,
lastApprovedAt, now)`. It is a stateless calculation module — it owns no Firestore
writes, runs no background timer, and recomputes only when the app comes to the
foreground. `lastApprovedAt` and `storedEnergy` are owned by Data Persistence (#4)
and written by Parent Approval (#11); this module only reads and derives from them.
Its output (the energy float, via `energyProvider`) feeds Pet State Machine (#6),
which owns the energy→mood lookup table this GDD only references.

**Exit-criteria note (from `/gate-check` 2026-07-13 Pre-Production→Production and
the vertical slice)**: the formula must use `now.difference(lastApprovedAt)` (never
`now - lastApprovedAt` — `DateTime` has no `operator-`) and
`.inMicroseconds / Duration.microsecondsPerHour` (never `.inMinutes / 60.0`, which
truncates sub-minute elapsed time). Both corrections were already applied to
`time-decay.md` itself on 2026-07-13 — implement directly from the GDD's current
Core Rule 2, which already has the corrected formula.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0005: Time & Decay Calculation Strategy | Pure on-foreground calculation, zero Firestore writes; clock-manipulation guard (clamp `hoursElapsed` to [0, 168]); energy→mood lookup delegated to Pet State Machine (#6); `now` injected as a parameter, never read from the wall clock inside the function; recomputed via `AppLifecycleListener(onResume:)`, not a plain timer | LOW (pure Dart calculation, no engine API surface) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-time-decay-001 | Energy is computed on app-foreground only; no background timer | ADR-0005 ✅ |
| TR-time-decay-002 | Decay = f(now − lastApprovedAt), no per-second recompute, pure function | ADR-0005 ✅ |
| TR-time-decay-003 | Clock-manipulation guard: clamp `hoursElapsed` to [0, 168] | ADR-0005 ✅ |
| TR-time-decay-004 | Pure calculation, zero Firestore writes, exposes `energyProvider` | ADR-0005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/time-decay.md` are verified
- All Logic and Integration stories have passing test files in `tests/` — this system is 100% Logic-tier (pure function), so full unit-test coverage is mandatory per `.claude/docs/coding-standards.md`
- Test cases explicitly cover: null `lastApprovedAt` (new profile baseline), clock-rollback (negative elapsed clamped to 0), and multi-day elapsed (clamped at 168h)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | computeEnergy Pure Calculation | Logic | Complete | ADR-0005 |
| 002 | energyProvider (Firestore-Backed Wiring + Resume Tick) | Integration | Complete | ADR-0005 |

**Dependency note**: unlike Data Persistence Layer and Flutter-Flame Bridge, this epic has no "already satisfied" or "not independently implementable" TRs — all 4 GDD requirements map cleanly onto these 2 stories. Story 002 does introduce a small new concern: `storedEnergy`/`lastApprovedAt`/`createdAt` aren't modeled anywhere yet (`ChildProfile` from auth-account deliberately excludes them) — Story 002 reads them directly via its own minimal Firestore read, not by extending `ChildProfile`.

**Recommended build order**: 001 → 002 (002 depends directly on 001's pure function).

## Next Step

Epic complete — `energyProvider` now exists and unblocks Pet State Machine (#6), which was waiting on it (`petMoodProvider` depends on `energyProvider`). Return to `/create-stories pet-state-machine`.
