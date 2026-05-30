# Epic: IAP System

> **Layer**: Feature
> **GDD**: design/gdd/iap-system.md
> **Architecture Module**: IAP System + Purchase Fulfillment
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The IAP System handles all in-app purchases via RevenueCat, which abstracts both iOS App Store and Google Play. The client initiates purchases via `react-native-purchases`; RevenueCat validates receipts and delivers HMAC-signed server-to-server webhook events to `POST /v1/iap/webhook`. The server validates the webhook signature, identifies the product from the Content Catalog (`type: 'iap_pack'`), and calls `PurchaseFulfillment.fulfill(event)` for atomic delivery. All webhook events use `event.id` as the idempotency key, making RevenueCat retries safe. RevenueCat must be initialized with the player's `userId` as the app user ID.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: IAP Integration | RevenueCat webhooks; HMAC signature validation; rawBodyMiddleware; event_id idempotency | LOW |
| ADR-0008: Economy Transaction Safety | Atomic fulfillment transaction; idempotency key = event_id sub-keys | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0011 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/iap-system.md` verified
- Purchase with `diamond_pack_sm` → `profile:refresh` shows +50 diamonds within 10s (sandbox test)
- Duplicate webhook (same event_id) → balance unchanged, server returns 200
- Invalid HMAC signature → server returns 401, nothing fulfilled
- `Purchases.logIn(userId)` called before any purchase; verified via RevenueCat dashboard

## Next Step

Run `/create-stories iap-system` to break this epic into implementable stories.
