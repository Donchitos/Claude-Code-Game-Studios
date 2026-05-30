# Story 004: Offline Queue — Request Persistence & Drain

> **Epic**: API Client
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/api-client.md`
**Requirement**: `TR-api-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture
**ADR Decision Summary**: Offline requests queued in a FIFO array (max 50 entries); drain sequentially on reconnection; entries expire after 60s.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: `@react-native-community/netinfo` for online/offline detection.

---

## Acceptance Criteria

- [x] **AC-09**: Device offline at call time; mock returns 200 after reconnection → resolves with 200; 1 HTTP call (after reconnect)
- [x] **AC-10**: Offline + queue at `MAX_QUEUE_SIZE` (50); 51st request → oldest rejects with `code "QUEUE_FULL"`; queue stays at 50; new request enqueued
- [x] **AC-11**: Offline; `QUEUE_ENTRY_TTL_MS = 5000`; 6000ms pass → expired entry rejects with `code "QUEUE_EXPIRED"`; no HTTP call made for it
- [x] Queue drains sequentially on reconnect (not parallel)
- [x] Pre-flight online check happens before every HTTP call (not just at module init)

---

## Implementation Notes

- Use `NetInfo.addEventListener()` to detect online/offline state; drain queue when `isConnected` transitions to `true`
- Queue is an in-memory FIFO array `PendingRequest[]`; each entry: `{ requestConfig, resolve, reject, queuedAt }`
- Pre-flight check in the Axios request interceptor (before token attachment): if offline → push to queue, reject caller with `NetworkOfflineError`
- On drain: process queue entries in order; skip entries where `Date.now() - queuedAt > QUEUE_ENTRY_TTL_MS` (reject those with `QueueExpiredError`)
- Queue overflow: when queue is full (`queue.length >= MAX_QUEUE_SIZE`), remove the oldest entry (shift) → reject it with `QueueFullError`, then push the new entry

---

## Out of Scope

- App backgrounded during retry (in-memory retry state lost — acknowledged by GDD as acceptable)

---

## QA Test Cases

- **AC-09**: Offline queue drain on reconnect
  - Given: `NetInfo` reports offline; `apiClient.post('/v1/analytics/events', data)` called
  - When: `NetInfo` reports online after 3 seconds
  - Then: Queue drains; HTTP POST made; promise resolves with mock 200 response

- **AC-10**: Queue overflow drops oldest
  - Given: `MAX_QUEUE_SIZE=50`; 50 requests queued (all offline)
  - When: 51st request issued
  - Then: Oldest entry rejects with `{ code: 'QUEUE_FULL' }`; new request occupies slot 50; queue length = 50

- **AC-11**: TTL expiry
  - Given: Request queued at T=0; `QUEUE_ENTRY_TTL_MS=5000`; device comes online at T=6000
  - When: Queue drains
  - Then: Entry rejects with `{ code: 'QUEUE_EXPIRED' }`; no HTTP call made for it

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/api-client/offline-queue_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (API Client base)
- Unlocks: Story 005
