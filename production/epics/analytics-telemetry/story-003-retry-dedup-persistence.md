# Story 003: Retry, Deduplication & Persistence

> **Epic**: Analytics / Telemetry
> **Status**: Ready
> **Layer**: Foundation (Ops — Horizontal)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/analytics-telemetry.md`
**Requirement**: `TR-ops-???`

**ADR Governing Implementation**: ADR-0015: Analytics Event Architecture
**ADR Decision Summary**: 500 responses → retry up to MAX_FLUSH_RETRIES; server deduplicates by eventId (UNIQUE constraint); consent revocation purges Tier 1 events from queue.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-08**: Server returns 500 twice then 200; `MAX_FLUSH_RETRIES=3` → delivered on 3rd attempt; 3 HTTP calls; events cleared from queue
- [ ] **AC-09**: Same batch sent twice (same `eventId` values) → DB has exactly 1 record per eventId; both requests return 200
- [ ] **AC-10**: Player revokes consent; 30 Tier 1 events queued → all Tier 1 events removed from queue and AsyncStorage; Tier 0 events preserved

---

## Implementation Notes

- Server: `eventId` UNIQUE constraint; `INSERT ... ON CONFLICT (event_id) DO NOTHING RETURNING *`; return 200 on duplicate (not 409)
- Client retry: on 500: increment retry count; wait backoff; retry; on `MAX_FLUSH_RETRIES` exhausted: log; keep in queue for next interval
- Consent revocation: `analyticsService.revokeConsent(userId)` → filter queue: remove Tier 1 events; update AsyncStorage
- Tier classification: Tier 0 events listed in `src/analytics/tier0Events.ts`

---

## QA Test Cases

- **AC-08**: Retry on server error
  - Given: Server returns 500 × 2 then 200; `MAX_FLUSH_RETRIES=3`
  - When: Flush attempted
  - Then: 3 HTTP calls total; events cleared from queue after 3rd (successful) call

- **AC-09**: Deduplication
  - Given: Same batch of 5 events (same eventIds) POST'd twice
  - When: Both received server-side
  - Then: DB has exactly 5 records; second POST returns 200 (not error)

- **AC-10**: Consent revocation purges Tier 1
  - Given: 30 Tier 1 events + 5 Tier 0 events in queue
  - When: `revokeConsent()` called
  - Then: In-memory queue has only 5 Tier 0 events; AsyncStorage contains only Tier 0 events

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/analytics-telemetry/retry-dedup-persistence_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (batch flush infrastructure)
- Unlocks: Story 004 (malformed events)
