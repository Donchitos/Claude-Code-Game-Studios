# Story 005: Reconnection Logic

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol; ADR-0012: Session & Match Lifecycle
**ADR Decision Summary**: Max 5 reconnect attempts within 30s; exponential backoff 500ms-8000ms; server holds slot for RECONNECT_GRACE_PERIOD_S (30s); resync via snapshot on reconnect.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-09**: Network interrupted 10s then restored → client reconnects; receives `state_snapshot`; gameplay resumes without manual intervention [Manual QA]
- [ ] **AC-RT-10**: Network interrupted >30s → client shows "Connection Lost" overlay; stops reconnecting; server removes player after `RECONNECT_GRACE_PERIOD_S` [Manual QA]
- [ ] Reconnect attempts use exponential backoff: 500ms, 1000ms, 2000ms, 4000ms, 8000ms (±200ms jitter)
- [ ] Token expiry during disconnect → client refreshes token via HTTP before retrying socket connect
- [ ] `RECONNECT_GRACE_PERIOD_S` constant equals `RECONNECT_WINDOW_S` (invariant enforced in code)

---

## Implementation Notes

- Client reconnect state machine: `attempt=1`; `while attempt <= 5 && elapsed < 30000`: wait backoff; try `socket.connect()`; on success emit `session_join_request { matchId, userId }`
- Server: on `disconnect` event, start grace timer (30s); freeze player entity (`isActive = false`); on `session_join_request` within window: re-add to room, emit `state_snapshot`
- Backoff formula (from GDD §4.5): `min(500 * 2^(attempt-1) + rand(0, 200), 8000)`
- JWT expiry during disconnect: catch `auth_error { reason: 'TOKEN_EXPIRED' }` on reconnect; call API Client refresh; retry with new token
- Reconnect failure overlay: show "Connection Lost" UI with "Retry" (fresh attempt, not counted against window) and "Return to Menu" (forfeit)

---

## QA Test Cases

- **AC-RT-09** [Manual]: Reconnect within window
  - Setup: Active match; interrupt network at client for 10s; restore
  - Verify: Client reconnects automatically (no user action); match state snapshot received; game resumes
  - Pass condition: Match continues; player position correct; no "Connection Lost" overlay

- **AC-RT-10** [Manual]: Reconnect window exhausted
  - Setup: Active match; interrupt network at client for 35s
  - Verify: "Connection Lost" overlay appears with retry/return options; match continues server-side without player after 30s
  - Pass condition: Overlay shown within 32s of disconnect; server removes player from match state

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/realtime-transport-reconnection-evidence.md` + lead sign-off (manual QA steps above)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002 (room model for re-join)
- Unlocks: Story 006 (duplicate socket dedup)
