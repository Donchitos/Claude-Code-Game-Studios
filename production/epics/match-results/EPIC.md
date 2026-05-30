# Epic: Match Results Screen

> **Layer**: Presentation
> **GDD**: design/gdd/match-results.md
> **Architecture Module**: Match Results Screen (Presentation)
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Match Results screen displays the outcome of a completed match: placement, kills, damage dealt, coins earned, XP gained, MMR delta, and rank tier change. It receives its data from two sources: the `match_end` socket payload (placement, mmrDeltas, which arrives immediately) and the subsequent `profile:refresh` (coin balance, XP, level after economy fan-out settles). The screen animates in results progressively — match_end data first, then economy updates as they arrive. MVP: shows placement + mmrDelta. Alpha: adds coins, XP, quest progress indicators.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | match_end arrives within 3000ms; profile:refresh arrives later after fan-out settles | LOW |
| ADR-0006: Client State Management | ProfileStore updated by profile:refresh; screen reads from store for post-match economy | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅, ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/match-results.md` verified
- Screen transitions from HUD within 500ms of `match_end` arrival
- Placement and mmrDelta displayed immediately from `match_end` payload
- Coin and XP gain updated when `profile:refresh` arrives (no flash of old values)
- "Play Again" button returns to Lobby without full app restart
- Screen tested on iOS and Android (safe area, scrollability)

## Next Step

Run `/create-stories match-results` to break this epic into implementable stories.
