# Epic: Disconnect Handler

> **Layer**: Core
> **GDD**: design/gdd/disconnect-handler.md
> **Architecture Module**: Disconnect Handler
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories disconnect-handler`

## Overview

The Disconnect Handler manages the grace period for players who lose their socket connection during an active match. On disconnect, it starts a `RECONNECT_GRACE_PERIOD_S` (30 seconds) timer per player. During the grace window, the player's slot is preserved in the match and their `isActive` flag is set to `false` (Match Server simulates them as idle). If the player reconnects within the window, the timer is cancelled and the player resumes normally. If the window expires, Bot AI takes over the slot. The handler also manages the `match_found` boolean flag to prevent the race condition between `match_found` and `queue_cancel`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Session & Match Lifecycle | disconnectTimers map; RECONNECT_GRACE_PERIOD_S = 30s; bot assignment on expiry | LOW |
| ADR-0002: Real-Time Transport Protocol | Socket disconnect event triggers handler; reconnect resumes socket room membership | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/disconnect-handler.md` verified
- Player disconnect → match continues with idle slot for 30 seconds (manual QA)
- Bot takes over slot after 30s of inactivity (integration test)
- Player reconnects at 29s → timer cancelled; player resumes (integration test)
- `RECONNECT_GRACE_PERIOD_S` constant equals `RECONNECT_WINDOW_S` in codebase

## Next Step

Run `/create-stories disconnect-handler` to break this epic into implementable stories.
