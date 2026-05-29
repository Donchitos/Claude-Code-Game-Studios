# Epic: Shop & Offers Screen

> **Layer**: Presentation (Alpha)
> **GDD**: design/gdd/shop-offers-screen.md
> **Architecture Module**: Shop & Offers Screen (Presentation)
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Shop & Offers screen is the primary monetization surface. It displays diamond packs (IAP), the Play Pass subscription offer, character and skin bundles (diamonds), and daily coin offers (coins). All prices and items are sourced from the Content Catalog (`type: 'iap_pack'`, `type: 'cosmetic'`). Diamond pack purchases are handled via RevenueCat (`Purchases.purchase()`). Coin purchases use the API Client. The screen reads the player's `has_play_pass` flag to conditionally show the Play Pass CTA or the "Current Subscriber" badge. All price displays use localized currency via RevenueCat's `PackageType`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: IAP Integration | RevenueCat Purchases.purchase() for IAP; profile:refresh after fulfillment | LOW |
| ADR-0007: Content Catalog Architecture | Shop items sourced from catalog (`type: 'iap_pack'`, `type: 'cosmetic'`) | LOW |
| ADR-0006: Client State Management | ProfileStore provides has_play_pass and balances | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0011 ✅, ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/shop-offers-screen.md` verified
- Diamond pack purchase → balance updated via `profile:refresh` within 10s (sandbox test)
- Play Pass subscriber sees "Current Subscriber" badge; no purchase CTA
- Prices display in correct local currency (RevenueCat localization)
- Shop items match Content Catalog entries; no hardcoded prices

## Next Step

Run `/create-stories shop-offers-screen` to break this epic into implementable stories.
