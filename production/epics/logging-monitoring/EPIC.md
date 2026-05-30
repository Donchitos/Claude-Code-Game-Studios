# Epic: Logging / Monitoring

> **Layer**: Foundation (Ops — Horizontal)
> **GDD**: design/gdd/logging-monitoring.md
> **Architecture Module**: Logging Service (server-side, cross-cutting)
> **Status**: Ready
> **Stories**: 5/5 Complete

## Overview

Logging / Monitoring provides structured JSON server-side logging for all error, warning, and info events across every system. Logs include `level`, `timestamp`, `system`, `message`, and contextual fields. At MVP, logs are written to stdout (Railway captures and displays them). Error logs include stack traces. Critical paths (tick overrun, economy write failure, auth error) always produce structured log entries. This is the operational backbone that makes production debugging possible.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Client-Server Architecture | Logging in cross-cutting Ops layer; applies to all server systems | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0001 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/logging-monitoring.md` verified
- All server error paths produce a structured JSON log entry
- Tick overrun (>35ms) logs a warning with duration and matchId
- Economy write failure logs error with userId, idempotency key, and error type
- Log entries parseable by standard log aggregation tools (Railway, Datadog)

## Next Step

Run `/create-stories logging-monitoring` to break this epic into implementable stories.
