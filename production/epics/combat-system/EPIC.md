# Epic: Combat System

> **Layer**: Core
> **GDD**: design/gdd/combat-system.md
> **Architecture Module**: Combat Resolver
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories combat-system`

## Overview

Combat Resolver is the server-side module that handles all hit detection, damage calculation, and status effect application during the match simulation phase. It exposes `resolveHit(attacker, target, ability)` → `DamageResult` and `applyStatusEffect(target, effect)`. Key combat rules: BURNING bypasses SHIELDED (explicit design choice), lag compensation rewinds hit detection by `floor(min(rtt, 200ms) / 50ms)` ticks, and all combat math is deterministic (no `Math.random()` in the damage path). Status effects (BURNING, SHIELDED, STUNNED, SLOWED) have defined durations and interaction priorities.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Server-Side Game Loop | Combat Resolver called in simulation phase; lag compensation formula defined | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/combat-system.md` verified
- BURNING bypasses SHIELDED — unit test covering this interaction
- Lag compensation correctly rewinds hit detection by 0–4 ticks (unit tests for each rtt band)
- No `Math.random()` in damage calculation path (code review gate)
- All 4 status effects (BURNING, SHIELDED, STUNNED, SLOWED) have unit tests covering duration and interaction

## Next Step

Run `/create-stories combat-system` to break this epic into implementable stories.
