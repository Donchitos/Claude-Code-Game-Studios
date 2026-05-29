# Epic: Ad System

> **Layer**: Feature
> **GDD**: design/gdd/ad-system.md
> **Architecture Module**: Ad System (client SDK gate + server reward validation)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories ad-system`

## Overview

The Ad System shows AdMob ads to free players only. Play Pass subscribers (`has_play_pass = true`) have AdMob SDK never initialized — zero ad footprint. The client conditionally calls `MobileAds().initialize()` after profile load, guarded by the `has_play_pass` flag. Rewarded ads grant 25 coins via a server-validated token flow: client requests a one-time `adToken` from the server before loading the ad, then submits it after viewing. The server validates the token (single-use, 10-minute TTL) and credits coins via the Currency System.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0016: Ad SDK Integration | has_play_pass gate; conditional MobileAds.initialize(); adToken single-use validation | LOW |
| ADR-0008: Economy Transaction Safety | Coin grant uses adToken as idempotency key | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0016 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/ad-system.md` verified
- Play Pass subscriber: AdMob.initialize() never called (network inspector verification)
- Free player watches rewarded ad → +25 coins within 2s of completion
- Duplicate reward-grant with same adToken → 403, balance unchanged
- adToken expires after 10 minutes → 403 returned

## Next Step

Run `/create-stories ad-system` to break this epic into implementable stories.
