# Story 004: Log Rate Limiting & FATAL Bypass

> **Epic**: Logging / Monitoring
> **Status**: Complete
> **Layer**: Foundation (Ops — Horizontal)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/logging-monitoring.md`
**Requirement**: `TR-ops-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture
**ADR Decision Summary**: Per-errorCode rate limiting prevents log storms; FATAL is never rate-limited; suppression notices logged when lines are dropped.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure Node.js in-memory rate limiting. No game engine API involved.

---

## Acceptance Criteria

- [ ] **AC-07**: `LOG_RATE_LIMIT_PER_CODE=10`; 100 errors with same `errorCode` in 5 seconds → exactly 10 records + 1 suppression notice logged; 89 records dropped
- [ ] **AC-08**: 50 FATAL calls with same message in 5 seconds → all 50 written (FATAL is not rate-limited)
- [ ] **AC-window-reset**: After the 5-second window expires, the counter resets; logs with the same `errorCode` are allowed again up to the limit

---

## Implementation Notes

- Rate limiter: `Map<errorCode, { count, windowStart }>` — per error code; reset window every 5 seconds
- When `count > LOG_RATE_LIMIT_PER_CODE`: drop the log; if this is the first drop in the window: emit 1 suppression notice `{ dropped: true, errorCode, count: 'N+' }`
- FATAL: bypass rate limiter entirely; always write
- Thread safety: Node.js is single-threaded; no mutex needed

---

## QA Test Cases

- **AC-07**: Rate limiting
  - Given: `LOG_RATE_LIMIT_PER_CODE=10`; 100 calls to `logger.error(msg, { errorCode: 'DB_TIMEOUT' })` within 5s
  - When: Window ends
  - Then: 10 actual log lines + 1 suppression notice in output stream; total lines = 11 (not 100)

- **AC-08**: FATAL not rate-limited
  - Given: `LOG_RATE_LIMIT_PER_CODE=10`; 50 calls to `logger.fatal(msg, { errorCode: 'TICK_OVERRUN' })` within 5s
  - When: Counted
  - Then: All 50 log lines present in output

- **AC-window-reset**: Window reset
  - Given: 10 errors with `errorCode: 'DB_TIMEOUT'` logged at T=0; 5-second window elapses
  - When: `logger.error` called with same errorCode at T=6000ms
  - Then: Log line written (not suppressed); counter reset to 1

---

## Out of Scope

- Story 001: `ILogger` interface (already implemented)
- Story 002: PII redaction (already implemented)
- Story 003: Tick rate monitoring
- Story 005: Vendor swap / buffer recovery
- Rate limiting logs WITHOUT an `errorCode` field — only `meta.errorCode` is rate-limited per code; logs without errorCode pass through unconditionally

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/logging-monitoring/rate-limiting-fatal_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (logger infrastructure)
- Unlocks: Story 005 (vendor abstraction)
