# Epic: Match Flow System

> **Layer**: Feature
> **GDD**: design/gdd/match-flow.md
> **Architecture Module**: Match Flow (fan-out orchestrator)
> **Status**: Ready
> **Stories**: 3/3 Complete

## Overview

Match Flow is the orchestrator that runs when a match ends. It implements Architecture Principle 5 (Model B fan-out): first calls MMR synchronously with a 3000ms timeout (timeout → mmrDelta=0 → proceed), then fires Reward, XP, Quest, and Battle Pass in parallel via `Promise.allSettled()`. `match_end` is emitted to the client immediately after the fan-out is initiated — the client does not wait for economy settlement. All economy calls use idempotency keys derived from `matchId`. Failed fan-out systems are logged for retry; they never block the client.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | MMR sync (3000ms timeout) → allSettled(Reward, XP, Quest, BP) → match_end immediate | LOW |
| ADR-0008: Economy Transaction Safety | All economy writes carry matchId-derived idempotency keys | LOW |
| ADR-0012: Session & Match Lifecycle | Session Manager calls Match Flow after endMatch(); destroySession after fan-out | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/match-flow.md` verified
- `match_end` delivered within 3000ms (including MMR timeout case) — integration test
- `mmrDeltas` always present in `match_end` payload (no undefined entries)
- Reward, XP, Quest, BP all fire in parallel (Promise.allSettled log confirms simultaneous start)
- Failure in Reward system does not prevent XP grant — chaos test

## Next Step

Run `/create-stories match-flow` to break this epic into implementable stories.
