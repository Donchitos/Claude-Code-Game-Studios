# Epic: Battle Pass / Play Pass

> **Layer**: Feature
> **GDD**: design/gdd/battle-pass.md
> **Architecture Module**: Battle Pass System
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories battle-pass`

## Overview

The Battle Pass / Play Pass system has two components: a free-tier Battle Pass (all players earn BP XP via matches; gates cosmetic rewards at tier milestones) and Play Pass (a paid monthly subscription via IAP that grants premium tier rewards, removes ads, and provides a monthly diamond allotment). BP XP is credited in the Match Flow fan-out via `BattlePassSystem.creditBPXP()`. Play Pass status is the `has_play_pass` flag in `player_profiles`, set by IAP fulfillment and cleared by RevenueCat CANCELLATION webhook. This epic is designed last in the Alpha block as it depends on Currency, Inventory, IAP, and Reward all being frozen first.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | BattlePassSystem.creditBPXP fires in allSettled fan-out | LOW |
| ADR-0011: IAP Integration | Play Pass INITIAL_PURCHASE → has_play_pass=true; CANCELLATION → false | LOW |
| ADR-0008: Economy Transaction Safety | BP XP grant idempotent; reward grants idempotent | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅, ADR-0011 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/battle-pass.md` verified
- BP XP credited after each match; tier progression correct (integration test)
- Play Pass purchase → `has_play_pass=true`; AdMob suppressed within 2 app opens
- Play Pass cancellation → `has_play_pass=false`; AdMob resumes on next app open
- BP reward grant idempotent (duplicate BP credit is no-op)

## Next Step

Run `/create-stories battle-pass` to break this epic into implementable stories.
