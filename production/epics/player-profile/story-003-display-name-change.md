# Story 003: Display Name Change & Validation

> **Epic**: Player Profile
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture
**ADR Decision Summary**: Display name changes go through `PATCH /v1/profile/settings`; validation order: length → charset → profanity → uniqueness → cooldown; 30-day cooldown enforced by `display_name_last_changed_at`.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-06**: Valid name; last change >30 days ago → updated in DB + Redis invalidated; HTTP 200 with updated `display_name`
- [x] **AC-PP-07**: Name changed 10 days ago → HTTP 429, `DISPLAY_NAME_COOLDOWN`, `retry_after` (remaining seconds ≈20 days in seconds); `display_name` unchanged
- [x] **AC-PP-08**: Name already taken → HTTP 409, `DISPLAY_NAME_TAKEN`; cooldown NOT consumed; requestor's name unchanged
- [x] **AC-PP-09**: Validation errors: length <3 → 400 `TOO_SHORT`; >20 → 400 `TOO_LONG`; invalid chars → 400 `INVALID_CHARS`; profanity → 400 `PROFANITY`
- [x] First rename (default name, `display_name_last_changed_at = null`) always permitted regardless of account age

---

## Implementation Notes

- Validation order per GDD §3.6: (1) length, (2) character allowlist `^[A-Za-z0-9_-]+$`, (3) profanity blocklist, (4) uniqueness (`LOWER(display_name)` index), (5) cooldown
- Return FIRST failing check; stop at that check
- Cooldown: `display_name_last_changed_at IS NOT NULL AND NOW() - display_name_last_changed_at < INTERVAL '30 days'`
- `retry_after`: `(display_name_last_changed_at + INTERVAL '30 days' - NOW())` in seconds
- Race condition on uniqueness: catch PostgreSQL `23505` error; return 409 `DISPLAY_NAME_TAKEN` without consuming cooldown
- Atomic update: `UPDATE player_profiles SET display_name=$1, display_name_last_changed_at=NOW() WHERE user_id=$2`

---

## QA Test Cases

- **AC-PP-06**: Successful rename
  - Given: Player; `display_name_last_changed_at = null`; new name "VexKing99" (valid)
  - When: `PATCH /v1/profile/settings { display_name: "VexKing99" }`
  - Then: DB row has `display_name = "VexKing99"`; Redis cache invalidated; HTTP 200 with `{ display_name: "VexKing99" }`

- **AC-PP-07**: Cooldown enforcement
  - Given: Player changed name 10 days ago
  - When: Rename attempt
  - Then: HTTP 429; `{ code: "DISPLAY_NAME_COOLDOWN", retry_after: 1728000 }` (20 days in seconds ±tolerance); no DB write

- **AC-PP-09 validation**: Invalid chars
  - Given: Name "Vex King" (contains space)
  - When: Rename attempt
  - Then: HTTP 400; `{ code: "DISPLAY_NAME_INVALID_CHARS" }`; no DB query for uniqueness or cooldown

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/display-name-change_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004 (field ownership)
