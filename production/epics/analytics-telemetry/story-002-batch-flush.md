# Story 002: Batch Flush — Interval, Size Threshold & Background

> **Epic**: Analytics / Telemetry
> **Status**: Complete
> **Layer**: Foundation (Ops — Horizontal)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/analytics-telemetry.md`
**Requirement**: `TR-ops-???` *(pending `/architecture-review`)*

**ADR Governing Implementation**: ADR-0015: Analytics Event Architecture
**ADR Decision Summary**: Events batched; flush on interval (30s), size threshold (50 events), or app background; queue persisted in AsyncStorage for crash recovery.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure TypeScript with injected adapters. No game engine API involved.

---

## Acceptance Criteria

- [x] **AC-04**: 5 events queued; 30 seconds elapse → `POST /v1/analytics/events` with those 5 events
- [x] **AC-05**: `FLUSH_BATCH_SIZE=50`; 50th event enqueued → flush triggered immediately
- [x] **AC-06**: 10 events queued; app backgrounded → flush triggered within 2 seconds of background event
- [x] **AC-07**: 20 events in AsyncStorage; app force-killed and relaunched → all 20 events in queue on next launch; flushed on next trigger

---

## Implementation Notes

- Queue: in-memory array + AsyncStorage mirror (async write after each enqueue)
- Flush triggers: `setInterval(flush, 30000)`, `queue.length >= FLUSH_BATCH_SIZE`, `AppState.addEventListener('background', flush)`
- App kill/relaunch recovery: `loadQueueFromStorage()` on init; merge with in-memory queue
- Flush: take all queued events; `POST /v1/analytics/events { events: [...] }`; on success: clear sent events from queue; on failure: keep in queue (Story 003)

---

## QA Test Cases

- **AC-04**: Interval flush
  - Given: 5 events queued; jest fake timers
  - When: 30 seconds advance
  - Then: HTTP POST called with those 5 events; queue cleared

- **AC-05**: Size threshold flush
  - Given: `FLUSH_BATCH_SIZE=50`; queue has 49 events
  - When: 50th event enqueued
  - Then: flush triggered immediately; HTTP POST made with all 50 events

- **AC-06**: Background flush
  - Given: 10 events queued
  - When: `AppState` transitions to `background`
  - Then: `POST /v1/analytics/events` called within 2 seconds of event

- **AC-07**: Crash recovery
  - Given: 20 events in AsyncStorage (simulate kill by clearing memory; reload from AsyncStorage)
  - When: `loadQueueFromStorage()` called on init
  - Then: 20 events in in-memory queue; flushed on next interval

---

## Out of Scope

- Story 001: event schema validation and consent filtering (already implemented)
- Story 003: retry on failure, consent revocation
- Story 004: malformed event handling

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/analytics-telemetry/batch-flush_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (queue infrastructure)
- Unlocks: Story 003 (retry/dedup)
