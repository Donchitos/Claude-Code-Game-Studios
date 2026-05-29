# Epic: Lobby & Team Formation

> **Layer**: Presentation
> **GDD**: design/gdd/lobby.md
> **Architecture Module**: Lobby & Team Formation (Presentation)
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Lobby screen is where players select a game mode and enter the matchmaking queue. It shows mode selection (Duel 1v1, Squad 3v3, FFA 8), an animated queue timer while waiting, and the `match_found` transition to Character Select. It listens for `match_found` and `dequeued` socket events. The screen handles the `match_found` → `queue_cancel` race condition (server-side boolean prevents cancellation after match formation). Party slot display is shown as a stub at MVP (solo queue only); party member avatars appear in VS when Party/Presence ships.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Real-Time Transport Protocol | match_found and dequeued socket events; dequeued reason field | LOW |
| ADR-0006: Client State Management | Profile store provides player MMR display | LOW |
| ADR-0009: Matchmaking Architecture | dequeued event includes reason: 'match_found'|'player_cancelled'|'timeout'|'queue_error' | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/lobby.md` verified
- Queue timer increments correctly while waiting
- `match_found` → navigates to Character Select screen
- `queue_cancel` before match found → returns to mode select; `dequeued` event received
- `dequeued` with reason `'queue_error'` → error message shown to player
- Handles iOS safe area insets; tested on iOS 16 notch device and Android

## Next Step

Run `/create-stories lobby` to break this epic into implementable stories.
