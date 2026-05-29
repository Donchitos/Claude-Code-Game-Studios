# Epic: In-Match HUD

> **Layer**: Presentation
> **GDD**: design/gdd/in-match-hud.md
> **Architecture Module**: In-Match HUD (Presentation) + Match State Consumer (Feature client)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories in-match-hud`

## Overview

The In-Match HUD is the real-time display layer during an active match. It renders player positions, HP bars, ability cooldowns, status effect icons, and a match timer by reading from the `MatchStateBuffer` interpolation ring buffer at 60fps via requestAnimationFrame — not via React state updates. This separation keeps the JS thread within the 16.6ms frame budget. Touch controls (virtual joystick for movement, ability buttons) emit `BASIC_ATTACK` and `USE_ABILITY` socket events. The HUD also displays the game-mode-specific score/win condition indicator.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Client State Management | MatchStateBuffer ring buffer (not Zustand); interpolated at 60fps via rAF | LOW |
| ADR-0002: Real-Time Transport Protocol | match_state events populate the buffer; BASIC_ATTACK/USE_ABILITY emitted | LOW |
| ADR-0003: Server-Side Game Loop | Client interpolates between ticks; renders at 60fps; server authoritative | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/in-match-hud.md` verified
- HUD renders at 60fps with no frame drops during 8-player match (Flipper JS thread profile)
- All player HP bars, ability cooldowns, status effects visible and accurate
- Touch controls emit correct socket events (integration test with mock server)
- rAF loop cancelled on HUD unmount (no memory leak after 10 matches)
- Safe area insets handled; controls not obscured by notch/home indicator

## Next Step

Run `/create-stories in-match-hud` to break this epic into implementable stories.
