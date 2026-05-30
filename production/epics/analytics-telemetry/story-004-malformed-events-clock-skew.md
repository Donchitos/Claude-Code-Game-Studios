# Story 004: Malformed Event Handling & Clock Skew Detection

> **Epic**: Analytics / Telemetry
> **Status**: Complete
> **Layer**: Foundation (Ops — Horizontal)
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/analytics-telemetry.md`
**Requirement**: `TR-ops-???` *(pending `/architecture-review`)*

**ADR Governing Implementation**: ADR-0015: Analytics Event Architecture
**ADR Decision Summary**: Malformed events (missing required fields) dropped client-side; WARN logged; clock skew >60s flagged; UI events sampled at configurable rate.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure TypeScript with injected adapters. No game engine API involved.

---

## Acceptance Criteria

- [x] **AC-11**: Event `clientTimestamp` 90s behind `serverTimestamp` → `clockSkewSec=90` persisted; WARN emitted; event persisted using `serverTimestamp` as authoritative time
- [x] **AC-12**: `UI_EVENT_SAMPLE_RATE=0.5`; 1000 `UI_SCREEN_VIEWED` events emitted → 400–600 events queued (±10% RNG tolerance)
- [x] **AC-13**: `analytics.track()` called with `userId` missing → event NOT enqueued; WARN logged with missing field name; zero HTTP calls

---

## Implementation Notes

- Malformed detection: validate required base fields before enqueue; use the registry to check which fields are required; any missing field → drop + log WARN
- Clock skew: server-side: `skew = serverTimestamp - clientTimestamp`; if `abs(skew) > 60000`: persist `clockSkewSec = skew / 1000`; use `serverTimestamp` for time-series queries
- Sample rate: `if (Math.random() <= UI_EVENT_SAMPLE_RATE)` before enqueue for sampled event types; UI events have `sampled: true` flag in registry

---

## QA Test Cases

- **AC-11**: Clock skew flagged
  - Given: Event with `clientTimestamp = serverTimestamp - 90000` (90s behind)
  - When: Server ingests
  - Then: `clockSkewSec = 90` in persisted record; `serverTimestamp` used as event time; WARN emitted

- **AC-12**: Sample rate applied to UI events
  - Given: `UI_EVENT_SAMPLE_RATE=0.5`; `Math.random` seeded to alternate above/below 0.5
  - When: 1000 `UI_SCREEN_VIEWED` events tracked with mocked random
  - Then: Approximately 500 events enqueued (between 400–600 for true RNG; for mocked alternating random: exactly 500)

- **AC-13**: Malformed event dropped
  - Given: `analytics.track('MATCH_ENDED', { matchId: 'abc' })` called without `userId` in context
  - When: Processing
  - Then: Event not in queue; `WARN: analytics event missing field: userId` logged; no HTTP call

---

## Out of Scope

- Stories 001–003: all implemented by prior stories
- Server-side persistent DB storage (MVP uses ILogger; DB persistence is post-MVP)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/analytics-telemetry/malformed-clock-skew_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (event schema validation infrastructure)
- Unlocks: No remaining analytics stories
