# Epic: Item Database

> **Layer**: Foundation
> **GDD**: design/gdd/item-database.md
> **Architecture Module**: Item Database (#3)
> **Status**: Complete
> **Stories**: 2 stories created (2026-07-16), both Complete — see table below

## Overview

This epic implements the game's read-only item catalog: a global, non-family-scoped
`items/{itemId}` Firestore collection that every acquisition system (Shop, Gacha,
Pet Equipment) reads from but never writes to (`write: if false` at the rules level
— prices and content are admin-seeded only). The catalog is fetched once per
session via a cached `FutureProvider` (`itemCatalogProvider`), not a realtime
`snapshots()` listener, since catalog content changes on a content-update cadence
(~monthly), not per-user-action. This module owns nothing persistent beyond the
catalog itself; its entire job is exposing a clean, cached read surface other
Feature-layer systems depend on.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0006: Item Catalog Data Access Pattern | Global `items/{itemId}` collection; one-time cached `get()` via `itemCatalogProvider` (not `.autoDispose`, not `snapshots()`); read-only Security Rule; 500-item hard cap (MVP 30); `slot`/`price`/`sortOrder` parsed defensively (`as String?`/`(x as num).toInt()`, never a direct unsafe cast) | LOW (cloud_firestore ^5.x, one-time fetch, no realtime/offline-transaction complexity) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-item-database-001 | Global top-level `items/{itemId}` collection, not family-scoped | ADR-0006 ✅ |
| TR-item-database-002 | One-time `get()` plus session-lifetime `FutureProvider` (not `.autoDispose`, not `snapshots()`) | ADR-0006 ✅ |
| TR-item-database-003 | Read-only Security Rule (`allow read`; `write: if false`) | ADR-0006 ✅ |
| TR-item-database-004 | Catalog hard cap of 500 items (MVP ships 30) before pagination is required | ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/item-database.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- The defensive-parsing rules from ADR-0006 (nullable `slot`, `num`-safe `price`/`sortOrder` casts) are exercised by at least one test using the real MVP 30-item shape (12/30 items have `slot: null`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | ItemModel + Defensive Firestore Parsing | Logic | Complete | ADR-0006 |
| 002 | itemCatalogProvider (Session-Cached Read) | Integration | Complete | ADR-0006 |

**Dependency note**: TR-item-database-003 (read-only Security Rules) is already satisfied — deployed and `security-engineer`-reviewed as part of Data Persistence Layer Story 002 (`firestore.rules` lines 37-41). Only TR-001/002/004 require new stories here.

**Recommended build order**: 001 → 002 (002 depends directly on 001's `ItemModel`/`fromFirestore`).

## Next Step

Epic complete. `itemCatalogProvider`/`ItemModel` now exist for future Feature/Presentation-layer epics (Shop #13, Gacha/Loot #12, Pet Equipment #15, Pet Room Screen UI #18) to consume.
