# Epic: Reward System

> **Layer**: Feature
> **GDD**: design/gdd/reward-system.md
> **Architecture Module**: Reward System
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories reward-system`

## Overview

The Reward System calculates and grants match-end coin rewards based on placement, kills, damage dealt, and game mode participation. It fires as part of the Match Flow fan-out (`Promise.allSettled()`) after match end, using idempotency keys derived from `matchId + userId`. Reward amounts are data-driven (defined in content catalog / remote config) and account for win/loss bonus multipliers. After granting, it emits `profile:refresh` so the client sees the updated coin balance. Bot players (isBot=true) are excluded from reward grants.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | Reward fires in Phase 2 allSettled; idempotency key = matchId+userId+':reward' | LOW |
| ADR-0008: Economy Transaction Safety | creditCoins with idempotency key; no double-grant possible | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅, ADR-0008 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/reward-system.md` verified
- Win bonus applies correctly for 1v1, 3v3, FFA modes (unit tests for each mode)
- Bot players receive no coin grant (isBot check unit test)
- Reward grant idempotent: retrying same matchId → no double-grant
- `profile:refresh` emitted after grant; client shows updated balance within 500ms (manual QA)

## Next Step

Run `/create-stories reward-system` to break this epic into implementable stories.
