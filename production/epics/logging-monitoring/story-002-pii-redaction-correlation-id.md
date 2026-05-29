# Story 002: PII Redaction & Correlation ID Round-Trip

> **Epic**: Logging / Monitoring
> **Status**: Complete
> **Layer**: Foundation (Ops — Horizontal)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/logging-monitoring.md`
**Requirement**: `TR-ops-???` *(pending `/architecture-review` — registry not yet populated)*

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture; ADR-0004: Authentication Architecture
**ADR Decision Summary**: PII fields auto-redacted in log pipeline; correlationId propagated across HTTP and Socket.io connections for distributed tracing.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — Express HTTP middleware and Socket.io integration. No game engine API involved.

---

## Acceptance Criteria

- [x] **AC-03**: Log call with `metadata: { email: "user@test.com" }` → output contains `email: "[REDACTED]"`; WARN emitted noting redaction
- [x] **AC-04**: Socket.io connection + subsequent HTTP request → logs filtered by correlationId show both WebSocket session logs and HTTP request log under the same ID
- [x] **AC-09**: HTTP request with no `X-Correlation-ID` header → `fallback-{UUID}` assigned; WARN logged noting missing header; request completes normally

---

## Implementation Notes

- PII redaction: pino serializer that checks for known PII fields (`email`, `password`, `phone`, `ip`) in metadata; replaces values with `[REDACTED]`; logs a WARN with the field name
- Correlation ID: Express middleware assigns `req.correlationId = req.headers['x-correlation-id'] || 'fallback-' + randomUUID()`; attached to pino child logger for request duration
- Socket.io: assign correlationId at authentication; attach to socket logger; propagate to all handlers for that socket

---

## QA Test Cases

- **AC-03**: PII redaction
  - Given: `logger.info('User login', { email: 'user@test.com', userId: 'abc' })`
  - When: Log line captured
  - Then: JSON contains `email: '[REDACTED]'`; `userId: 'abc'` (not redacted); WARN `{ event: 'pii_redacted', field: 'email' }` also logged

- **AC-04**: Correlation ID round-trip
  - Given: Socket connects with correlationId `corr-123`; same session makes HTTP request with `X-Correlation-ID: corr-123`
  - When: Logs filtered by `correlationId: 'corr-123'`
  - Then: Both socket session logs and HTTP request log appear in results

- **AC-09**: Missing correlation header — fallback assigned
  - Given: HTTP request arrives with no `X-Correlation-ID` header
  - When: Express correlation middleware processes the request
  - Then: `req.correlationId` set to a string matching `/^fallback-[0-9a-f-]{36}$/` (UUID v4); WARN log emitted with message noting missing header; HTTP response returned normally (no 4xx)
  - Edge cases: Header present but empty string → treat as missing; UUID uniqueness across concurrent requests

---

## Out of Scope

- Story 001: `ILogger` interface and `createLogger()` factory (already implemented)
- Story 003: Tick rate critical alert logic
- Story 004: Log rate limiting per error code
- Story 005: Logger vendor swap / output buffer recovery
- Request body or response payload redaction (only metadata fields passed to logger)
- Recursive PII redaction in nested objects (only top-level metadata keys)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/logging-monitoring/pii-redaction-correlation_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (logger infrastructure)
- Unlocks: Story 003 (tick rate alerts)

---

## Completion Notes
**Completed**: 2026-05-29
**Criteria**: 3/3 passing (all auto-verified by tests)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/logging-monitoring/pii-redaction-correlation_test.ts` (13 tests, 19 total across suite)
**Code Review**: Pending — before sprint close-out
