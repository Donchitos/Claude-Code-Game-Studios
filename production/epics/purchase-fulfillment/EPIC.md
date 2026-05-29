# Epic: Purchase Fulfillment

> **Layer**: Feature
> **GDD**: design/gdd/purchase-fulfillment.md
> **Architecture Module**: Purchase Fulfillment
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

Purchase Fulfillment is the server-side atomic transaction layer that executes multi-step grants triggered by IAP webhook events. A single RevenueCat `INITIAL_PURCHASE` event for a diamond pack triggers: `creditDiamonds(+50)` + `grantItem('character:colt')` + `grantItem('skin:colt_default')` + `UPDATE player_profiles` — all in a single `pg` transaction using sub-keys derived from the webhook `event_id`. If the transaction fails partway, the full retry is safe because each sub-key is idempotent. After commit, Redis is invalidated and `profile:refresh` + `inventory:updated` are emitted.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: IAP Integration | Purchase Fulfillment.fulfill(event) called from webhook handler; event_id as base idempotency key | LOW |
| ADR-0008: Economy Transaction Safety | Single pg transaction; sub-keys: event_id+':d', event_id+':char', event_id+':skin' | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0011 ✅, ADR-0008 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/purchase-fulfillment.md` verified
- Full IAP purchase → diamonds + character + skin granted in single transaction (sandbox test)
- Partial failure (simulate DB error mid-transaction) → full rollback; retry succeeds idempotently
- RevenueCat webhook replay (same event_id) → all sub-keys are no-ops; balance/inventory unchanged
- `profile:refresh` + `inventory:updated` both emitted after fulfillment

## Next Step

Run `/create-stories purchase-fulfillment` to break this epic into implementable stories.
