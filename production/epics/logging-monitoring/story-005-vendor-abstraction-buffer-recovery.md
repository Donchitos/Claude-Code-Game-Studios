# Story 005: Vendor Abstraction & Buffer/Recovery

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
**ADR Decision Summary**: `ILogger` interface abstracts the underlying logger (pino/winston); call sites never depend on the concrete implementation; buffered during aggregator outage.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure Node.js in-memory buffer. No game engine API involved.

---

## Acceptance Criteria

- [ ] **AC-11**: Log aggregator goes down; 100 log lines buffered → aggregator recovers → all buffered lines flushed in FIFO order; no lines lost (up to `LOG_BUFFER_OVERFLOW_MAX`)
- [ ] **AC-12**: Underlying logger swapped from pino to winston → no changes required in any game system that calls `ILogger`; only `src/logging/logger.ts` (the factory) changes
- [ ] **AC-overflow**: Buffer at `LOG_BUFFER_OVERFLOW_MAX` capacity; new line arrives → oldest entry dropped; new entry appended; capacity unchanged

---

## Implementation Notes

- `ILogger` interface: `{ debug, info, warn, error, fatal }` — same signature as both pino and winston
- `loggerFactory.ts`: exports a singleton `ILogger`; internally creates `pino(...)` or `winston.createLogger(...)` based on config
- Buffer: in-memory ring buffer `LogLine[]` (max `LOG_BUFFER_OVERFLOW_MAX`); when aggregator is down, push to buffer instead of flushing; on recovery: flush buffer to aggregator in FIFO order
- Recovery detection: health-check the aggregator endpoint on a heartbeat; on success: flush buffer

---

## QA Test Cases

- **AC-11**: Buffer + recovery
  - Given: Aggregator mock returns 503; 100 log lines buffered
  - When: Aggregator returns 200 after 60s
  - Then: Within 10s of recovery: all buffered lines flushed in FIFO order; no lines lost (up to `LOG_BUFFER_OVERFLOW_MAX`)

- **AC-12**: Vendor swap is call-site transparent
  - Given: `loggerFactory.ts` changed to use winston internally
  - When: All game systems that call `logger.info()` are compiled
  - Then: Zero TypeScript compilation errors in game system files; only `loggerFactory.ts` changed

- **AC-overflow**: Buffer overflow drops oldest
  - Given: Buffer at `LOG_BUFFER_OVERFLOW_MAX = 100` capacity (100 buffered lines)
  - When: 101st log line arrives
  - Then: Oldest entry removed; new entry appended; buffer length remains 100

---

## Out of Scope

- HTTP-based log aggregator client (not needed at MVP; stdout → Railway captures)
- Persistent disk buffer (in-memory only at MVP)
- Story 001–004: all implemented by prior stories

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/logging-monitoring/vendor-abstraction-buffer_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (ILogger interface), Story 002 (all callers use ILogger)
- Unlocks: No remaining logging-monitoring stories
