# Logging / Monitoring — Game Design Document

> **System**: Logging / Monitoring
> **Priority**: Horizontal
> **Layer**: Foundation
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The Logging / Monitoring system is the observability foundation for BRAWLZONE. It defines a structured logging interface that every other system uses to record technical events (errors, warnings, state transitions, latency measurements), and a server-side metrics pipeline that surfaces operational health signals to the engineering team. It is distinct from Analytics / Telemetry, which tracks player behavior — this system tracks what the server and client are doing technically. It has no game-system dependencies; it is the lowest layer, usable before any other system is initialized. The server emits structured JSON logs (compatible with any log aggregator), the client emits structured logs to a crash reporter, and both carry a shared correlation ID per player session enabling end-to-end request tracing.

---

## 2. Player Fantasy

Players never see a log line. What they experience is the consequence: a bug gets fixed before it reaches public release because crash reports caught it in beta; a server performance regression is detected and rolled back within minutes rather than hours because tick-rate monitoring fired an alert; a matchmaking outage lasts four minutes instead of forty because the on-call engineer received a page with a correlation ID already attached. The player fantasy is invisibility — the system works so the game feels smooth, fast, and trustworthy without the player ever knowing it exists.

---

## 3. Detailed Rules

### 3.1 Log Levels

| Level | Constant | When to Use | Alert? |
|-------|----------|-------------|--------|
| DEBUG | `LOG_LEVEL.DEBUG` | Verbose internal state — only in dev/staging | No |
| INFO | `LOG_LEVEL.INFO` | Normal lifecycle events (session start, match created) | No |
| WARN | `LOG_LEVEL.WARN` | Degraded conditions that do not stop execution (retry attempt, cache miss) | No (threshold) |
| ERROR | `LOG_LEVEL.ERROR` | Failures that affect a user or a single session (request failed, payment rejected) | Threshold-based |
| FATAL | `LOG_LEVEL.FATAL` | Server process cannot continue; requires immediate restart | Always |

Dev/staging default log level: `DEBUG`. Production default log level: `INFO`.

### 3.2 Structured Log Format

Every log line (server-side) is a JSON object with the following required fields:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 string | UTC time of the log event |
| `level` | string | One of DEBUG / INFO / WARN / ERROR / FATAL |
| `service` | string | Emitting service name (e.g. `"match-server"`, `"matchmaking"`, `"api"`) |
| `correlationId` | string (UUID) | Per-session tracing ID (see §3.5) |
| `message` | string | Human-readable description |
| `metadata` | object | Structured context (key-value pairs; no PII — see §3.7) |

Optional fields: `userId` (UUID only — never display name or email), `sessionId`, `errorCode`, `durationMs`, `httpStatus`.

### 3.3 Logger Interface

All game systems import a shared `ILogger` interface. The underlying implementation (pino, winston, or equivalent) is injected at startup. Swapping the vendor requires no changes to any game system.

```typescript
interface ILogger {
  debug(message: string, metadata?: Record<string, unknown>): void;
  info(message: string, metadata?: Record<string, unknown>): void;
  warn(message: string, metadata?: Record<string, unknown>): void;
  error(message: string, metadata?: Record<string, unknown>): void;
  fatal(message: string, metadata?: Record<string, unknown>): void;
  child(context: Record<string, unknown>): ILogger;  // scoped child logger
}
```

The `child()` method creates a scoped logger that pre-binds context fields (e.g., `correlationId`, `sessionId`) so callers do not repeat them on every call.

### 3.4 Server Metrics

The following metrics are collected continuously on the Node.js server and exposed via an internal metrics endpoint (`GET /internal/metrics` — not public-facing):

| Metric | Unit | Description |
|--------|------|-------------|
| `tick_rate_hz` | Hz | Actual game loop tick rate (target: 20 Hz) |
| `active_sessions` | count | Number of currently running match sessions |
| `matchmaking_queue_depth` | count | Players in matchmaking queue per mode |
| `db_query_latency_p99_ms` | ms | 99th percentile PostgreSQL query latency |
| `socket_messages_per_sec` | count/s | Inbound Socket.io message rate |
| `api_error_rate_per_min` | count/min | HTTP 5xx responses per minute |
| `memory_used_mb` | MB | Node.js process RSS memory |
| `api_response_time_p99_ms` | ms | 99th percentile API response time |

### 3.5 Correlation ID

A correlation ID (UUID v4) is generated server-side at Socket.io connection time and returned to the client in the connection acknowledgment payload. The client attaches it as `X-Correlation-ID` on all subsequent HTTP requests via the API Client. The server attaches it to every log line emitted during that session. On reconnection within `RECONNECT_CORRELATION_WINDOW_MS` (default: 300 000 ms / 5 min), the existing ID is reused. After that window, a new ID is issued. This allows a complete player session trace — from login to match end — to be filtered by a single UUID in any log aggregator.

### 3.6 Client-Side Logging

Client-side logging has two layers:

**Crash Reporter (Sentry or equivalent):** Installed as a global error handler. On unhandled JS exception or React error boundary trigger, flushes the current log buffer synchronously to disk (best-effort) before the process terminates. Crash reports include the correlation ID, app version, build number, and device class (model + OS version — not a unique device identifier).

**Routine Log Buffer:** In-memory ring buffer of the last `CLIENT_LOG_BUFFER_SIZE` (default: 200) log entries. Not written to disk during normal operation — included in crash report payload if a crash occurs within the same session. Routine logs are sent to the server only if the error level is ERROR or FATAL (via a fire-and-forget API Client call).

### 3.7 PII Policy

The following fields are **never** logged in any log line, error report, or metric:

- User email address
- Display name
- Password or password hash
- Payment tokens (RevenueCat, Stripe)
- Raw IP address (log region/country only if needed)
- Device advertising ID (IDFA / GAID)

`userId` (the Supabase UUID) is permitted in log lines. A PII sanitizer middleware runs as a defense-in-depth layer: it scans outbound log records for known PII field names (`email`, `password`, `token`, `displayName`, `ip`, `name`) and redacts their values, replacing them with `[REDACTED]` and emitting a `WARN`. Systems are required to self-censor at the call site — the sanitizer is a safety net, not a substitute for correct logging.

### 3.8 Log Retention Policy

| Level | Retention | Rationale |
|-------|-----------|-----------|
| FATAL / ERROR | 90 days | Incident investigation window |
| WARN / INFO | 14 days | Operational visibility; volume cost |
| DEBUG | 3 days (staging) / not stored (production) | Development only |

### 3.9 Alerting Thresholds

Alerts fire to the on-call channel (PagerDuty or equivalent). All thresholds use hysteresis: an alert does not resolve until the metric has been within the safe range for `ALERT_RECOVERY_WINDOW_SEC` (default: 60 s) continuously, preventing flapping.

| Metric | Warning Threshold | Critical Threshold | Window |
|--------|------------------|--------------------|--------|
| `tick_rate_hz` | < 18 Hz for 60 s | < 15 Hz for 30 s | Rolling |
| `api_error_rate_per_min` | > 20 errors/min | > 60 errors/min | 5 min avg |
| `db_query_latency_p99_ms` | > 200 ms | > 500 ms | 5 min avg |
| `memory_used_mb` | > 600 MB | > 900 MB | Instant |
| `active_sessions` | Drop > 30% in 60 s | Drop > 50% in 30 s | Rolling |
| FATAL log count | Any single FATAL | — | Instant |

### 3.10 Rate Limiting (Log Flood Protection)

To prevent a single bug from generating millions of identical log entries and exhausting the log aggregator budget:

- In production: maximum `LOG_RATE_LIMIT_PER_CODE` (default: 10) identical ERROR or WARN records per unique `errorCode` per 10-second window. Additional records are dropped and a single suppression notice is logged at the end of the window.
- FATAL is exempt from rate limiting — always written.
- In dev/staging: limit is `LOG_RATE_LIMIT_DEV` (default: 100) to avoid masking bugs.

---

## 4. Formulas

### 4.1 Tick Rate Degradation

```
tick_degradation_pct = (TARGET_TICK_RATE_HZ - actual_tick_rate_hz) / TARGET_TICK_RATE_HZ × 100
```

- `TARGET_TICK_RATE_HZ = 20`
- Warning fires at > 10% degradation (< 18 Hz) for 60 s
- Critical fires at > 25% degradation (< 15 Hz) for 30 s

### 4.2 API Error Rate

```
error_rate = (count of HTTP 5xx responses in window) / window_duration_min
```

Window: 5-minute rolling. Warning: > 20/min. Critical: > 60/min.

### 4.3 Alert Recovery Hysteresis

```
alert_resolves = metric_in_safe_range for ALERT_RECOVERY_WINDOW_SEC consecutive seconds
```

Default: 60 s. Prevents alert flapping when a metric oscillates near the threshold.

---

## 5. Edge Cases

**5.1 Log Destination Unavailable:** If the log aggregator endpoint is unreachable, the logger buffers up to `LOG_BUFFER_OVERFLOW_MAX` (default: 10 000) lines in memory, then drops oldest entries with a counter. On reconnection, buffered lines are flushed in order. If the buffer overflows, a single WARN is written locally noting how many lines were dropped.

**5.2 Log Flood (Rate Limit Exceeded):** When an `errorCode` exceeds the per-window limit, subsequent records for that code are counted but not written. At the end of the window, one log line is written: `"[SUPPRESSED] errorCode=X: N records dropped in 10s window"`.

**5.3 Correlation ID Missing:** If a request arrives at the server without `X-Correlation-ID` (e.g., direct API call, webhook from RevenueCat), the server generates a fallback UUID prefixed `fallback-` and uses it for the request's log scope. This indicates a call path that does not route through the API Client — flagged as a WARN.

**5.4 Client Crash Before Log Flush:** The global error handler attempts a synchronous flush to crash reporter storage. Success is not guaranteed (process may be terminated by OS). Crash reports that arrive without a full log buffer are still accepted — partial context is better than none. The `correlationId` is always written first in the flush sequence to maximize its chance of surviving.

**5.5 PII Detected in Log Line:** Sanitizer detects a known PII field name → replaces value with `[REDACTED]` → emits a WARN with the field name and the calling service → record is written in redacted form. Does not throw or drop the record.

**5.6 Metric Scrape Failure:** If the `/internal/metrics` endpoint does not respond within 5 s, the monitoring system logs a WARN and uses the last known values for that metric. After 3 consecutive scrape failures (15 s), a CRITICAL alert fires for "metrics unavailable."

---

## 6. Dependencies

### 6.1 Upstream

None. The Logging / Monitoring system has no dependencies on other game systems. It is initialized before any other system.

### 6.2 Downstream (Systems That Write to Logging)

Every system in the project uses the `ILogger` interface. Key emitters:

| System | What It Logs |
|--------|-------------|
| Match Server | Tick rate, session lifecycle, state sync errors |
| Matchmaking Engine | Queue depth, match creation, timeout events |
| API Client | Request/response lifecycle, retry attempts, errors |
| Authentication | Login, logout, token refresh, session expiry |
| IAP System | Purchase initiation, receipt validation, fulfillment |
| Database layer | Query latency, connection pool exhaustion |

### 6.3 Bidirectional Notes

- **Analytics / Telemetry** emits `ERROR_OCCURRED` analytics events when the logging system records an ERROR — the two systems cooperate but do not depend on each other.
- **Remote Config** reads alert thresholds at startup from the config service, allowing threshold tuning without redeployment.

---

## 7. Tuning Knobs

All values in `server/src/config/logging.ts` (server) and `mobile/src/config/logging.ts` (client).

| Constant | Default | Safe Range | Description |
|----------|---------|------------|-------------|
| `LOG_LEVEL_PRODUCTION` | `INFO` | `INFO` / `WARN` | Minimum level written in production |
| `LOG_LEVEL_DEV` | `DEBUG` | Any | Minimum level written in dev/staging |
| `LOG_RATE_LIMIT_PER_CODE` | 10 | 1 – 100 | Max same-code ERROR/WARN per 10 s (production) |
| `LOG_RATE_LIMIT_DEV` | 100 | 10 – 1000 | Same, dev/staging |
| `LOG_RATE_LIMIT_WINDOW_MS` | 10 000 | 5 000 – 60 000 | Rate limit window (ms) |
| `LOG_BUFFER_OVERFLOW_MAX` | 10 000 | 1 000 – 100 000 | In-memory buffer before drop |
| `CLIENT_LOG_BUFFER_SIZE` | 200 | 50 – 1 000 | Client-side ring buffer entries |
| `RECONNECT_CORRELATION_WINDOW_MS` | 300 000 | 60 000 – 600 000 | Correlation ID reuse window on reconnect |
| `ALERT_RECOVERY_WINDOW_SEC` | 60 | 30 – 300 | Hysteresis before alert resolves |
| `TICK_RATE_WARN_HZ` | 18 | 16 – 19 | Tick rate warning threshold |
| `TICK_RATE_CRITICAL_HZ` | 15 | 10 – 17 | Tick rate critical threshold |
| `ERROR_RATE_WARN_PER_MIN` | 20 | 5 – 100 | API error rate warning |
| `ERROR_RATE_CRITICAL_PER_MIN` | 60 | 20 – 500 | API error rate critical |

---

## 8. Acceptance Criteria

**AC-01: Structured Log Format**
Given any log call at INFO or above in production. When the line reaches the log aggregator. Then it is valid JSON containing `timestamp`, `level`, `service`, `correlationId`, and `message`.

**AC-02: Log Level Filtering**
Given `LOG_LEVEL_PRODUCTION = INFO`. When a `logger.debug()` call is made. Then no log line is written to the aggregator.

**AC-03: PII Redaction**
Given a log call with `metadata: { email: "user@test.com" }`. When the line is processed. Then the output contains `email: "[REDACTED]"` and a WARN is emitted noting the redaction.

**AC-04: Correlation ID Round-Trip**
Given a Socket.io connection and subsequent HTTP request via the API Client. When the server logs are filtered by the correlation ID from the connection ack. Then both the WebSocket session logs and the HTTP request log appear under the same ID.

**AC-05: Tick Rate Critical Alert**
Given the game loop is artificially slowed to 14 Hz. When 30 seconds elapse. Then a CRITICAL alert fires to the on-call channel within 35 seconds of the threshold being breached.

**AC-06: Tick Rate Alert Resolves With Hysteresis**
Given a CRITICAL tick rate alert is active. When tick rate recovers to 20 Hz. Then the alert does not resolve until 60 consecutive seconds at ≥ 18 Hz have elapsed.

**AC-07: Log Rate Limiting in Production**
Given `LOG_RATE_LIMIT_PER_CODE = 10` and 100 errors with the same `errorCode` fire in 5 seconds. When the window ends. Then exactly 10 records plus 1 suppression notice appear; 89 records are dropped.

**AC-08: FATAL Bypasses Rate Limit**
Given 50 FATAL log calls with the same message in 5 seconds. When the window ends. Then all 50 are written — FATAL is not rate-limited.

**AC-09: Correlation ID Missing → Fallback**
Given an HTTP request with no `X-Correlation-ID` header. When processed by the server. Then a `fallback-` prefixed UUID is assigned, a WARN is logged noting the missing header, and the request completes normally.

**AC-10: Client Crash Report Contains Correlation ID**
Given a simulated unhandled JS exception during an active match session. When the crash report is received by the crash reporter. Then it contains a non-empty `correlationId` matching the session's ID.

**AC-11: Log Destination Unavailable — Buffer and Recover**
Given the log aggregator endpoint returns 503 for 60 seconds. When the endpoint recovers. Then buffered log lines (up to `LOG_BUFFER_OVERFLOW_MAX`) are flushed in order within 10 seconds of recovery.

**AC-12: Vendor Swap Does Not Change Call Sites**
Given the underlying logger is swapped from pino to winston. When the project is rebuilt. Then no changes are required to any game system that calls `ILogger` — only the logger factory in `src/logging/loggerFactory.ts` changes.
