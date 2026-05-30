# Story 005: Economy Field Write & profile:refresh Push

> **Epic**: Player Profile
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture; ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: Economy writes commit to PostgreSQL, invalidate Redis cache, then emit `profile:refresh` via Socket.io to player's user room. Client does not display updated balance until push arrives.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-11**: Diamond balance change → client does NOT display updated balance until server-confirmed write complete; `profile:refresh` Socket.io event emitted after PostgreSQL commit; client updates displayed balance ONLY on receiving this event
- [x] If PostgreSQL commit fails → client balance remains at pre-transaction value; no `profile:refresh` emitted
- [x] Redis cache for profile invalidated (`DEL profile:{userId}`) after every economy write (success)
- [x] `profile:refresh` emitted to `user:{userId}` socket room — not to the player's match room

---

## Implementation Notes

- After any economy write (`creditCoins`, `creditDiamonds`, `grantItem`): `await Redis.del(`profile:${userId}`)`; then `io.to(`user:${userId}`).emit('profile:refresh', { profile: await getProfile(userId) })`
- Client-side (ProfileStore): on `profile:refresh` event: `setProfile(event.profile)` — triggers React re-render with confirmed values
- Client MUST NOT optimistically update economy values; show a loading spinner or unchanged value while the server processes
- User room: each player joins `user:{userId}` room on socket authentication; this room is used for all per-player pushes

---

## QA Test Cases

- **AC-PP-11**: No optimistic update + profile:refresh
  - Given: Player's displayed diamond balance = 0; currency system credits +50 diamonds
  - When: `creditDiamonds()` called server-side
  - Then: Client balance remains 0 until `profile:refresh` received; after receipt, displays 50; PostgreSQL has 50; Redis `profile:{userId}` was deleted and re-populated

- **AC-rollback**: Failed commit → no client update
  - Given: PostgreSQL `UPDATE` throws a constraint error
  - When: Economy write attempted
  - Then: Transaction rolled back; `Redis.del()` NOT called; `profile:refresh` NOT emitted; client balance unchanged

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/player-profile/economy-write-push_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (cache), Story 001 (profile exists), Real-time Transport Story 002 (user room)
- Unlocks: Currency System epic, Reward System epic
