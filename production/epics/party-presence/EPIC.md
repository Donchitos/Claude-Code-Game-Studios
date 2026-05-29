# Epic: Party / Presence System

> **Layer**: Feature (VS milestone)
> **GDD**: design/gdd/party-presence.md
> **Architecture Module**: Party / Presence
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories party-presence`

## Overview

Party / Presence enables friend groups of 2–6 players to queue for matches together. Presence shows player online status and current activity (in-menu, in-queue, in-match). Party formation uses a party code or friend invite via Socket.io events. When a party queues, the Matchmaking Engine receives the entire party as a unit and treats them as pre-grouped (party members placed on the same team in squad_3v3; together in FFA). Solo queue remains the default; party queue extends matchmaking to support groups. At MVP, solo queue only — this epic ships in VS milestone.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Real-Time Transport Protocol | Party and presence events routed via Socket.io; user rooms used for presence pushes | LOW |
| ADR-0004: Authentication Architecture | Party invite links scoped to authenticated users | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/party-presence.md` verified
- Party of 3 queues for squad_3v3 → all placed on same team in match
- Online status visible within 5s of friend coming online
- Party leader can queue and cancel; all members follow
- Solo queue unaffected when party system is inactive

## Next Step

Run `/create-stories party-presence` to break this epic into implementable stories.
