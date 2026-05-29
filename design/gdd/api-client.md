# API Client — Game Design Document

> **System**: API Client
> **Priority**: MVP
> **Layer**: Foundation
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The API Client is a thin, typed wrapper around the native `fetch` API (or `axios`) that centralizes all non-realtime HTTP communication between the React Native / Expo client and the Node.js backend. It handles base URL configuration per environment (dev / staging / production), automatic attachment of the Supabase JWT to every authenticated request, a unified request/response pipeline with structured error normalization, exponential-backoff retry logic for transient failures, per-request timeout enforcement, and offline-state detection with a pre-flight queue that drains on reconnection. Every other client-side system — Analytics/Telemetry, Remote Config, Push Notifications, IAP, Player Profile, and Content Catalog — calls the backend exclusively through this module. Socket.io real-time match transport is outside this system's scope.

---

## 2. Player Fantasy

Players never think about the API Client, and that is precisely the goal. When a player opens BRAWLZONE on a spotty mobile connection, taps into their profile, redeems a reward, or triggers a push notification opt-in, the app should respond gracefully — retrying quietly in the background, surfacing a friendly "reconnecting…" indicator only when genuinely offline, and never losing a request that was issued before connectivity dropped. The system's job is to make every other feature feel rock-solid and instantaneous: the IAP receipt posts correctly on the first try, the player profile loads from a fresh JWT after a token refresh without the player ever seeing a login prompt, and Remote Config values arrive before the main menu renders. The player fantasy is reliability and transparency — the network layer is invisible when things go well and politely honest when they do not.

**User Story:** As a player on a mobile network, I want the app to handle connection hiccups automatically so that my purchases, profile updates, and notifications never silently fail or force me to re-authenticate unexpectedly.

---

## 3. Detailed Rules

### 3.1 Initialization

The API Client is a singleton instantiated once at app startup (inside the Expo root provider). It reads `API_BASE_URL` from the Expo public environment variable manifest (`process.env.EXPO_PUBLIC_API_BASE_URL`) and stores it as the immutable base URL for the session. No re-initialization occurs at runtime.

### 3.2 Request Lifecycle

Every outbound HTTP request follows this exact sequence:

1. **Pre-flight online check** — If the device is currently offline (detected via `@react-native-community/netinfo`), the request is placed in the **pending queue** (see §3.6) and the caller receives a `NetworkOfflineError` immediately. The pending queue replays queued requests in FIFO order once connectivity is restored.
2. **Token attachment** — The client calls `supabase.auth.getSession()` to retrieve the current JWT. If a valid session exists, the `Authorization: Bearer <token>` header is added. If no session exists and the endpoint is marked `requiresAuth: true`, the request is rejected immediately with `AuthRequiredError` — no network call is made.
3. **Request construction** — The client merges caller-supplied headers with the default headers (`Content-Type: application/json`, `Accept: application/json`, `X-App-Version: <Expo manifest version>`) and serializes the body as JSON if provided.
4. **Timeout wrapper** — The request is raced against an `AbortController` that fires after `REQUEST_TIMEOUT_MS` (default: 10 000 ms). If the abort fires first, the attempt is classified as a `TimeoutError`.
5. **HTTP dispatch** — The `fetch` call is issued.
6. **Response classification** — The raw response is classified by HTTP status: `2xx` → success; `401` → token-expiry path; `429` → rate-limit path; other `4xx` → non-retryable; `5xx` → retryable server error; network/timeout → retryable transient error.
7. **Response parsing** — If `Content-Type` is not `application/json` or `JSON.parse` throws on a `2xx`, classified as `MalformedResponseError` (not retried).
8. **Return to caller** — Typed `ApiResponse<T>` on success; normalized `ApiError` thrown on failure.

### 3.3 Token Expiry Handling

On `401`: call `supabase.auth.refreshSession()` once. On success, replay the original request with the new token (does not count against retry budget). On failure, emit `AUTH_SESSION_EXPIRED` on the global event bus and reject with `SessionExpiredError`.

### 3.4 Rate Limit Handling (429)

Read `Retry-After` header (seconds); default to `RATE_LIMIT_DEFAULT_WAIT_MS` if absent. Wait, then retry. This retry counts against `MAX_RETRY_ATTEMPTS`. On exhaustion, throw `RateLimitError`.

### 3.5 Retry Policy

Retries apply to: `TimeoutError`, `NetworkError`, HTTP `5xx`. Do not apply to: non-401/429 `4xx`, `MalformedResponseError`, `AuthRequiredError`, `SessionExpiredError`. Maximum attempts: `MAX_RETRY_ATTEMPTS` (default 3) after the initial failure. Each attempt gets a fresh timeout window.

### 3.6 Request Queue (Offline)

FIFO array capped at `MAX_QUEUE_SIZE` (default 50). Each entry holds full request descriptor, caller callbacks, and `queuedAt` timestamp. Entries older than `QUEUE_ENTRY_TTL_MS` (default 60 000 ms) are expired at drain time with `QueueExpiredError`. Drains sequentially (not parallel) on reconnection. When full, oldest entry is dropped with `QueueFullError` and new entry is appended.

### 3.7 Endpoint Configuration

Endpoints declared as typed constants in `src/api/endpoints.ts` with `path`, `method`, and `requiresAuth` fields. Path parameters interpolated at call time via `pathParams` object.

### 3.8 Request/Response Types

`ApiResponse<T>` carries `data`, `requestId`, `httpStatus`. `ApiError` carries `code`, `message`, `httpStatus` (null for network errors), `requestId` (null if unavailable).

---

## 4. Formulas

### 4.1 Exponential Backoff

```
waitMs(n) = min(BASE_RETRY_DELAY_MS * (BACKOFF_MULTIPLIER ^ (n - 1)) + jitter, MAX_RETRY_DELAY_MS)
```

| Variable | Default | Description |
|---|---|---|
| `n` | 1, 2, 3 | Retry attempt index (1-based) |
| `BASE_RETRY_DELAY_MS` | 500 ms | Delay before the first retry |
| `BACKOFF_MULTIPLIER` | 2.0 | Exponential growth factor |
| `jitter` | `Math.random() * 200` | Random jitter in [0, 200] ms |
| `MAX_RETRY_DELAY_MS` | 8 000 ms | Hard ceiling per wait |

**Example** (jitter = 0): Retry 1 → 500 ms, Retry 2 → 1 000 ms, Retry 3 → 2 000 ms. Total backoff: 3 500 ms.

### 4.2 Timeout Threshold

`REQUEST_TIMEOUT_MS = 10 000` ms per attempt. Worst-case elapsed: `4 × 10 000 + 3 500 = 43 500 ms`.

### 4.3 Rate Limit Wait

`rateLimitWaitMs = Retry-After (s) × 1 000` OR `RATE_LIMIT_DEFAULT_WAIT_MS` (5 000 ms) if header absent.

---

## 5. Edge Cases

**5.1 Token Expiration Mid-Request:** Intercept `401` → refresh token once → replay request with new token → on refresh failure emit `AUTH_SESSION_EXPIRED` and reject with `SessionExpiredError`.

**5.2 Network Loss After Dispatch:** Fetch rejects with `NetworkError` → begin retry backoff → on confirmed offline, suspend retries and move to pending queue (if budget not exhausted) → drain on reconnection → caller's Promise held until drain or TTL expiry.

**5.3 HTTP 429:** Read `Retry-After` (or use default wait) → wait → retry (counts against budget) → on exhaustion throw `RateLimitError`.

**5.4 HTTP 500:** Retry with backoff up to `MAX_RETRY_ATTEMPTS` → on exhaustion throw `ServerError` with last status code and parsed error body (or generic message if unparseable).

**5.5 Timeout:** Each attempt aborted after `REQUEST_TIMEOUT_MS` → classified `TimeoutError` → retry with backoff → on exhaustion throw `TimeoutError`.

**5.6 Malformed Response:** `2xx` with non-JSON body → `MalformedResponseError` thrown immediately → no retry → fire-and-forget alert to Analytics/Telemetry via internal event.

**5.7 Queue Full Offline:** Oldest entry rejected with `QueueFullError` → new entry appended → queue size stays at `MAX_QUEUE_SIZE`.

**5.8 App Backgrounded During Retry:** Backoff timer may not survive OS suspension. In-memory retry state is lost. Calling systems must re-issue requests on foreground resume. API Client does not persist retry state across suspensions.

---

## 6. Dependencies

### 6.1 Upstream

| Dependency | Purpose |
|---|---|
| `@supabase/supabase-js` | JWT retrieval and session refresh |
| `@react-native-community/netinfo` | Online/offline detection, queue drain trigger |
| `EXPO_PUBLIC_API_BASE_URL` | Environment-specific base URL |
| Node.js backend (REST API) | Request target; must return `X-Request-ID` header |
| Internal event bus (`src/events/eventBus.ts`) | Publishing `AUTH_SESSION_EXPIRED` and malformed-response alerts |

### 6.2 Downstream

| System | Usage | Failure Impact |
|---|---|---|
| Analytics / Telemetry | Batch POST events; tolerates drop | Low |
| Remote Config | GET on launch; blocks main menu | High |
| Push Notifications | POST device token | Medium |
| IAP (RevenueCat bridge) | POST receipt validation | Critical |
| Player Profile | GET/PUT profile | High |
| Content Catalog | GET static data updates | Medium |

### 6.3 Events Emitted

- `AUTH_SESSION_EXPIRED` → consumed by Auth module (triggers logout/redirect).
- `MALFORMED_RESPONSE` → consumed by Analytics/Telemetry (error alerting).

---

## 7. Tuning Knobs

All values live in `src/api/apiClientConfig.ts`.

| Constant | Default | Safe Range | Description |
|---|---|---|---|
| `API_BASE_URL` | (from env) | Any valid HTTPS URL | Backend base URL |
| `REQUEST_TIMEOUT_MS` | 10 000 | 5 000 – 30 000 | Per-attempt timeout (ms) |
| `MAX_RETRY_ATTEMPTS` | 3 | 0 – 5 | Retries after initial failure |
| `BASE_RETRY_DELAY_MS` | 500 | 200 – 2 000 | First retry base delay (ms) |
| `BACKOFF_MULTIPLIER` | 2.0 | 1.5 – 3.0 | Exponential growth factor |
| `MAX_RETRY_DELAY_MS` | 8 000 | 2 000 – 30 000 | Backoff ceiling (ms) |
| `RATE_LIMIT_DEFAULT_WAIT_MS` | 5 000 | 1 000 – 60 000 | 429 fallback wait (ms) |
| `MAX_QUEUE_SIZE` | 50 | 10 – 200 | Offline queue capacity |
| `QUEUE_ENTRY_TTL_MS` | 60 000 | 10 000 – 300 000 | Queue entry expiry (ms) |
| `JITTER_MAX_MS` | 200 | 0 – 500 | Max random backoff jitter (ms) |

**Operator warnings:** `REQUEST_TIMEOUT_MS < 5 000` risks false timeouts on cellular; `MAX_RETRY_ATTEMPTS > 5` risks request storms; `MAX_QUEUE_SIZE > 200` risks memory pressure; `BACKOFF_MULTIPLIER < 1.5` approaches linear backoff.

---

## 8. Acceptance Criteria

**AC-01: Successful Authenticated Request**
Given online + valid JWT + mock returns `200`. When `GET /v1/player/profile` called. Then resolves with correct payload, `httpStatus 200`, and `Authorization: Bearer <jwt>` header present.

**AC-02: Unauthenticated Request Has No Auth Header**
Given `requiresAuth: false` endpoint. When called. Then outbound request has no `Authorization` header.

**AC-03: Auth Required, No Session → Immediate Rejection**
Given no session + `requiresAuth: true`. When called. Then rejects with `code "AUTH_REQUIRED"`, zero HTTP calls made.

**AC-04: Silent Token Refresh on 401**
Given mock returns `401` then `200`; refresh succeeds. When called. Then resolves with `200` payload; two HTTP calls; retry carries new token; `AUTH_SESSION_EXPIRED` not emitted.

**AC-05: Session Expired on Unrecoverable 401**
Given mock always returns `401`; refresh fails. When called. Then rejects with `code "SESSION_EXPIRED"`; `AUTH_SESSION_EXPIRED` emitted exactly once.

**AC-06: Retry on 500 With Exponential Backoff**
Given mock returns `500` × 3 then `200`; `MAX_RETRY_ATTEMPTS = 3`. When called. Then resolves; four HTTP calls; waits between attempts ≥ 500 ms, ≥ 1 000 ms, ≥ 2 000 ms (±200 ms jitter).

**AC-07: All Retries Exhausted → ServerError**
Given mock always returns `500`; `MAX_RETRY_ATTEMPTS = 3`. When called. Then rejects with `code "SERVER_ERROR"`, `httpStatus 500`; four HTTP calls.

**AC-08: Timeout Per Attempt**
Given mock hangs; `REQUEST_TIMEOUT_MS = 1 000`; `MAX_RETRY_ATTEMPTS = 0`. When called. Then rejects with `code "TIMEOUT"` within 1 200 ms; one HTTP call.

**AC-09: Offline Request Queued and Replayed**
Given offline at call time; mock returns `200` after reconnection. When called then NetInfo goes online. Then resolves with `200`; one HTTP call after reconnection.

**AC-10: Queue Overflow Drops Oldest**
Given offline + queue at `MAX_QUEUE_SIZE` (50). When 51st request issued. Then oldest rejects with `code "QUEUE_FULL"`; queue remains at 50; new request enqueued.

**AC-11: Queued Request Expires After TTL**
Given offline; `QUEUE_ENTRY_TTL_MS = 5 000`; 6 000 ms pass. When device comes online and queue drains. Then expired entry rejects with `code "QUEUE_EXPIRED"`; no HTTP call made for it.

**AC-12: 429 With Retry-After Respected**
Given mock returns `429` with `Retry-After: 2` then `200`. When called. Then resolves; two HTTP calls; inter-call wait ≥ 2 000 ms and ≤ 2 500 ms.

**AC-13: Malformed Response Not Retried**
Given mock returns `200` with non-JSON body. When called. Then rejects immediately with `code "MALFORMED_RESPONSE"`; exactly one HTTP call.

**AC-14: Base URL Is Environment-Driven**
Given `EXPO_PUBLIC_API_BASE_URL = "https://staging-api.brawlzone.io"`. When any call made. Then outbound URL begins with that value.

**AC-15: Default Headers Present on Every Request**
Given any call. When outbound request captured. Then `Content-Type: application/json`, `Accept: application/json`, and `X-App-Version: <non-empty>` are all present.
