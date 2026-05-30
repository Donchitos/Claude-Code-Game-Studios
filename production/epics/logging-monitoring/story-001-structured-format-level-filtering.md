# Story 001: Structured Log Format & Level Filtering

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

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture
**ADR Decision Summary**: Structured JSON logs on server; 5 severity levels; filter by LOG_LEVEL_PRODUCTION; all logs go to stdout (Railway captures).

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure Node.js logging library (pino). No game engine API involved.

---

## Acceptance Criteria

- [x] **AC-01**: Any log call at INFO or above in production → valid JSON with `timestamp, level, service, correlationId, message`
- [x] **AC-02**: `LOG_LEVEL_PRODUCTION=INFO`; `logger.debug()` called → no log line written to aggregator
- [x] All 5 levels supported: DEBUG, INFO, WARN, ERROR, FATAL

---

## Implementation Notes

- Logger implementation: `pino` with JSON output (fast, structured, Railway-compatible)
- Fields: `{ timestamp: ISO8601, level: string, service: string, correlationId: string, message: string, ...metadata }`
- `LOG_LEVEL_PRODUCTION` env var controls minimum level; defaults to `INFO` in production, `DEBUG` in development
- `ILogger` interface: `debug(msg, meta?)`, `info(msg, meta?)`, `warn(msg, meta?)`, `error(msg, meta?)`, `fatal(msg, meta?)`

---

## QA Test Cases

- **AC-01**: Structured format
  - Given: `logger.info('Server started')` called in production mode
  - When: Log line emitted to stdout
  - Then: JSON parseable; contains `timestamp`, `level: 'INFO'`, `service: 'brawlzone-server'`, `message: 'Server started'`; no extra non-JSON text

- **AC-02**: Debug filtered in production
  - Given: `LOG_LEVEL_PRODUCTION = 'INFO'`
  - When: `logger.debug('Debug detail')` called
  - Then: No log line written (captured via stream mock in test)

- **AC-all-levels**: All 5 severity levels callable without error
  - Given: Logger initialized in production mode
  - When: `logger.debug()`, `logger.info()`, `logger.warn()`, `logger.error()`, `logger.fatal()` each called with a string message
  - Then: INFO, WARN, ERROR, FATAL lines emitted; DEBUG suppressed; no TypeError or runtime error thrown for any call
  - Edge cases: Empty string message; message with special JSON characters (`"`, `\n`, `{`)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/logging-monitoring/structured-format_test.ts`

**Status**: [x] Created and passing — 6/6 tests pass

---

## Out of Scope

- Story 002: PII redaction (email, password, phone, IP auto-scrubbing)
- Story 002: Correlation ID round-trip propagation
- Story 003: Tick rate alert logic
- Story 004: Rate limiting & FATAL bypass
- Story 005: Vendor abstraction swap/buffer behaviour (`ILogger` interface is defined here but the swappability proof is Story 005)

---

## Dependencies

- Depends on: None (horizontal; can be implemented first)
- Unlocks: Story 002 (PII redaction)

---

## Completion Notes
**Completed**: 2026-05-29
**Criteria**: 3/3 passing (all auto-verified by tests)
**Deviations**: ADVISORY — `export const logger` singleton; ADR-0001 prefers DI over singletons. Mitigated: JSDoc warning on singleton; all tests and callers use `createLogger()` injection. No gameplay impact.
**Test Evidence**: Logic — `tests/unit/logging-monitoring/structured-format_test.ts` (6/6 pass)
**Code Review**: Pending — scheduled before sprint close-out
