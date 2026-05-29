# Story 001: Event Schema & Consent Filtering

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
**ADR Decision Summary**: Fire-and-forget via setImmediate; no await in hot path; 10 required base fields; Tier 0 events always collected; Tier 1 dropped without consent.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-01**: Any `analytics.track()` call → persisted record contains all 10 required base fields with non-null values
- [ ] **AC-02**: Player `analyticsConsent=false`; Tier 1 event (`ECONOMY_DIAMOND_SPENT`) emitted → no event in DB for that userId; zero HTTP calls for that event
- [ ] **AC-03**: Player `analyticsConsent=false`; Tier 0 event (`MATCH_ENDED`) emitted → event persisted with correct properties

---

## Implementation Notes

- 10 required base fields: `eventId, userId, sessionId, clientTimestamp, serverTimestamp, eventName, eventVersion, platform, appVersion, properties`
- Tier 0 events: game-critical non-PII events; always collected regardless of consent
- Tier 1 events: economy, behavioral, PII-adjacent; dropped if `analyticsConsent=false`
- `analytics.track()` is `void` (never async); internally uses `setImmediate(() => enqueue(event))`

---

## QA Test Cases

- **AC-01**: Base fields present
  - Given: `analytics.track('MATCH_ENDED', { matchId: 'abc' })` called
  - When: Event ingested server-side
  - Then: DB record has all 10 fields; `eventId` is a non-empty UUID; `serverTimestamp` is a recent timestamp

- **AC-02**: Tier 1 dropped without consent
  - Given: `player.analyticsConsent = false`
  - When: `analytics.track('ECONOMY_DIAMOND_SPENT', { amount: 50 })`
  - Then: No HTTP call made; event not in DB; no error thrown

- **AC-03**: Tier 0 always collected
  - Given: `player.analyticsConsent = false`
  - When: `analytics.track('MATCH_ENDED', { ... })`
  - Then: Event persisted; `userId` and match properties present

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/analytics-telemetry/event-schema-consent_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (horizontal system; can be implemented independently)
- Unlocks: Story 002 (batch flush)
