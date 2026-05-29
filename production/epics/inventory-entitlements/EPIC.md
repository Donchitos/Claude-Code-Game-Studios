# Epic: Inventory / Entitlements

> **Layer**: Feature
> **GDD**: design/gdd/inventory-entitlements.md
> **Architecture Module**: Inventory / Entitlements
> **Status**: Ready
> **Stories**: 3/3 Complete

## Overview

Inventory / Entitlements tracks all items owned by a player: characters, skins, and cosmetics. The `entitlements` table has a `UNIQUE(user_id, item_id, idempotency_key)` constraint to prevent double-grants. `grantItem()` is idempotent — duplicate key returns `{ duplicate: true }` silently. `revokeItem()` throws `CANNOT_REVOKE_FREE_CHARACTER` for the 8 base characters. `hasItem()` reads from a Redis cache (TTL 60s) with PostgreSQL fallback. All writes emit `inventory:updated` via Socket.io. Free characters are pre-granted on account creation; all other items require explicit grant.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Economy Transaction Safety | grantItem idempotency key UNIQUE constraint; revokeItem invariants | LOW |
| ADR-0005: Database Architecture | entitlements table; Redis inv:{userId} cache | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0008 ✅, ADR-0005 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/inventory-entitlements.md` verified
- Duplicate grantItem (same idempotency key) → returns { duplicate: true }, DB unchanged (unit test)
- `revokeItem` on free character → CANNOT_REVOKE_FREE_CHARACTER thrown (unit test)
- `hasItem` cache miss → PostgreSQL fallback; correct result (integration test)
- All 8 free characters present in new account's entitlements (new account smoke test)
- `inventory:updated` socket event received within 500ms of grant (integration test)

## Next Step

Run `/create-stories inventory-entitlements` to break this epic into implementable stories.
