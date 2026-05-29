# Story 003: Tick Rate Alerts

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

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop; ADR-0001: Client-Server Architecture
**ADR Decision Summary**: Tick rate monitored against 20Hz target; CRITICAL alert fires to on-call channel when rate drops below threshold for 30s; hysteresis prevents flapping.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure Node.js time measurement (`process.hrtime`). No game engine API involved.

---

## Acceptance Criteria

- [x] **AC-05**: Game loop artificially slowed to 14Hz; 30 seconds elapse → CRITICAL alert fires to on-call channel within 35s of threshold breach
- [x] **AC-06**: CRITICAL tick rate alert active; tick rate recovers to 20Hz → alert does NOT resolve until 60 consecutive seconds at ≥18Hz have elapsed (hysteresis)
- [x] **AC-initial-state**: `TickRateMonitor` starts with `isAlertActive === false`; no FATAL log emitted before any threshold is crossed

---

## Implementation Notes

- Tick rate monitor: `TickRateMonitor` measures actual ticks per second using `hrtime`; running 5-second window
- Threshold: `TICK_RATE_CRITICAL_THRESHOLD_HZ = 16` (80% of 20Hz); below this for 30s → CRITICAL
- Alert channel: initially `logger.fatal({ alert: 'TICK_RATE_CRITICAL', currentHz, targetHz: 20 })`; Railway can alert on FATAL log patterns
- Hysteresis: `consecutiveSecondsAboveRecovery++`; only clear alert state when counter reaches `RECOVERY_HYSTERESIS_S = 60`

---

## QA Test Cases

- **AC-05**: Critical alert fires
  - Given: `TickRateMonitor` reports 14Hz for 31 consecutive seconds (mocked)
  - When: Monitor evaluates
  - Then: FATAL log with `{ alert: 'TICK_RATE_CRITICAL', currentHz: 14 }` emitted within 35s of first detection

- **AC-06**: Alert resolves only after hysteresis
  - Given: CRITICAL alert active; tick rate immediately recovers to 20Hz
  - When: 59 seconds elapse at ≥18Hz
  - Then: Alert NOT resolved (hysteresis not reached); at 60+ seconds → alert resolved; no FATAL log for that period

- **AC-initial-state**: Monitor starts non-alerting
  - Given: `TickRateMonitor` just constructed; no ticks recorded
  - When: `isAlertActive` is read
  - Then: `false`; no FATAL log emitted

---

## Out of Scope

- Story 001: `ILogger` interface and base logger (already implemented)
- Story 004: Log rate limiting per error code
- Story 005: Vendor abstraction / buffer recovery
- Wiring `TickRateMonitor` to the actual Match Server tick loop — that is done in the Match Server epic; this story only implements the monitor class itself
- Alerting via external services (PagerDuty, Slack) — MVP uses FATAL log; Railway triggers alerts on FATAL patterns

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/logging-monitoring/tick-rate-alerts_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (logger with FATAL level), Match Server epic (tick loop)
- Unlocks: Story 004 (rate limiting)
