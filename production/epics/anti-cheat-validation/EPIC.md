# Epic: Anti-Cheat / Validation

> **Layer**: Feature (Full Vision — deferred)
> **GDD**: design/gdd/anti-cheat-validation.md
> **Architecture Module**: Anti-Cheat / Validation (Ops — Full Vision)
> **Status**: Ready (deferred — Full Vision milestone)
> **Stories**: Not yet created — run `/create-stories anti-cheat-validation`

## Overview

Anti-Cheat / Validation provides additional server-side integrity checks beyond the baseline protections already provided by the server-authoritative architecture. At MVP and VS, server authority alone (no client-trusted game state) provides sufficient baseline anti-cheat. Full Vision adds: input velocity capping (detect improbably frequent inputs), position delta validation (reject teleportation), ability rate limiting (detect auto-clickers), and suspicious pattern flagging for admin review. This epic is L-effort and intentionally deferred — the server-authoritative loop is the primary defense.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Client-Server Architecture | Server-authoritative baseline is the primary anti-cheat mechanism; anti-cheat is additive | LOW |
| ADR-0003: Server-Side Game Loop | Input validation in tick Phase 2 is where additional checks apply | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0001 ✅, ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/anti-cheat-validation.md` verified
- Input velocity cap rejects >N inputs per tick (N = mode-appropriate rate)
- Position delta validation rejects teleportation (>max speed * tick_ms movement)
- Flagged accounts queryable by admin dashboard
- No false positives on legitimate high-speed play (QA with fast human testers)

## Next Step

Run `/create-stories anti-cheat-validation` to break this epic into implementable stories.
