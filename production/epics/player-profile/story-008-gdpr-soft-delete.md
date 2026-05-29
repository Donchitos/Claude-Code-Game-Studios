# Story 008: GDPR Soft Delete (Account Deletion Request)

> **Epic**: Player Profile
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture; ADR-0004: Authentication Architecture
**ADR Decision Summary**: Soft delete sets `is_deleted=true`, anonymizes display/avatar, invalidates Redis + Supabase Auth. Hard delete (30 days later) is a scheduled job. All queries use `WHERE is_deleted=false`.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-PP-14**: Deletion request → `is_deleted=true`, `deleted_at=NOW()`, `deletion_scheduled_at=NOW()+30days`; `display_name="[deleted]"`, `avatar_id="default_avatar"`; Redis keys deleted; Supabase Auth account disabled; deleted userId excluded from matchmaking queries; player cannot authenticate; HTTP 200 returned

---

## Implementation Notes

- `POST /v1/account/delete` endpoint (authenticated): single transaction sets soft-delete fields atomically
- Redis invalidation: `Redis.del(`profile:${userId}`)` immediately after commit
- Supabase Auth disable: `supabase.auth.admin.updateUserById(userId, { ban_duration: '876000h' })` (effectively permanent)
- `WHERE is_deleted = false` clause must be on all profile reads and matchmaking queries — add this as a global query constraint or Supabase RLS policy
- Cancellation window: if player logs back in within 30 days → `POST /v1/account/restore` sets `is_deleted=false`, re-enables Auth
- Hard-delete scheduled job: not part of this story; flag for Infrastructure/Ops epic

---

## QA Test Cases

- **AC-PP-14**: Soft delete sets all fields
  - Given: Authenticated player with active profile
  - When: `POST /v1/account/delete`
  - Then: DB row: `is_deleted=true`, `deleted_at` within 5s of now, `deletion_scheduled_at = deleted_at + 30days`, `display_name="[deleted]"`, `avatar_id="default_avatar"`; Redis key deleted; Auth disabled (login returns 400); matchmaking `SELECT` with `WHERE is_deleted=false` returns 0 rows for this userId

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/gdpr-soft-delete_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (profile exists)
- Unlocks: Story 009 (computed fields)
