# Analytics / Telemetry — Game Design Document

> **System**: Analytics / Telemetry
> **Priority**: Horizontal
> **Layer**: Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The Analytics / Telemetry system is the behavioral observability layer for BRAWLZONE. It defines the canonical event taxonomy — what player and system events exist, what data they carry, and how they are named — and the end-to-end pipeline from client-side event emission through batched HTTP delivery to server-side ingestion and deduplication. It is a horizontal system: always active, with no runtime game dependencies. No other system depends on Analytics to function; it is purely observational. Analytics data drives game balance tuning, matchmaking quality improvements, economy calibration, quest targeting, and live-ops decisions. The system must never degrade game performance, must respect player consent and privacy regulations (GDPR, COPPA), and must define a stable event schema that downstream consumers (Quest/Mission, Moderation/Reporting, A/B testing via Remote Config) can rely on without breaking changes.

---

## 2. Player Fantasy

Players do not interact with Analytics directly — but they feel its effects. When the development team sees that 70% of matches in the 1v1 Duel mode end within 90 seconds of one player falling to 30% health, they know the comeback mechanic needs tuning. When quest completion data shows that new players abandon the "Win 3 Matches" quest at an 80% rate, the team reduces it to "Win 1 Match." When IAP funnel data identifies the exact screen where free-to-play players stop engaging with the Diamond shop, the team redesigns that screen. The player fantasy is a game that gets better over time — one that feels like it was designed specifically for them because the team can observe what is and is not working at scale.

**User Story:** As a player, I want the game to improve continuously — bugs fixed faster, balance kept fair, quests that feel achievable — knowing that my aggregated, anonymized gameplay data contributes to those improvements without ever exposing my identity.

---

## 3. Detailed Rules

### 3.1 Event Naming Convention

- Event names use `UPPER_SNAKE_CASE` with a category prefix separated by an underscore.
- Format: `CATEGORY_ACTION` (e.g., `MATCH_STARTED`, `ECONOMY_DIAMOND_SPENT`)
- Categories: `SESSION`, `MATCH`, `ECONOMY`, `PROGRESSION`, `UI`, `ERROR`, `IAP`, `ONBOARDING`
- Event property keys use `camelCase` (e.g., `matchId`, `characterId`, `diamondsSpent`)
- Event names are treated as a public API — once shipped, they must not be renamed or have required fields removed without a versioned migration plan

### 3.2 Required Fields on Every Event

Every event — regardless of category — carries the following base fields:

| Field | Type | Description |
|-------|------|-------------|
| `eventName` | string | The event constant (e.g., `MATCH_STARTED`) |
| `eventId` | UUID v4 | Unique ID for deduplication (client-generated) |
| `userId` | UUID | Supabase pseudonymous user UUID |
| `sessionId` | UUID | Correlation ID from Socket.io connection (see Logging GDD §3.5) |
| `clientTimestamp` | ISO 8601 | Client-local UTC time of the event |
| `serverTimestamp` | ISO 8601 | Server time of ingestion (added by server) |
| `platform` | string | `"ios"` or `"android"` |
| `appVersion` | string | Expo manifest version (e.g., `"1.2.3"`) |
| `buildNumber` | string | Expo build number |
| `consentTier` | number | `0` (anonymous) or `1` (opted-in) |

### 3.3 Consent Model

**Tier 0 — Anonymous (always collected):**
Session lifecycle events and match outcome aggregates. Legal basis: legitimate interest (service improvement). Collected regardless of consent status. No PII. COPPA-mode users are hard-locked to Tier 0.

**Tier 1 — Behavioral (opt-in required):**
Economy events, progression events, UI interaction events, IAP events, onboarding events. Requires explicit analytics consent at first launch or in Settings. If consent is revoked, Tier 1 collection stops immediately for new events; a server-side async deletion job purges the player's historical Tier 1 records within 30 days.

Consent state is stored in the Player Profile (`analyticsConsent: boolean`) and checked at event emission time. No consent gate is applied to Error events — these are classified as Tier 0 for service integrity.

### 3.4 Event Taxonomy

#### SESSION Category (Tier 0)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `SESSION_STARTED` | App foreground / cold launch | `platform`, `appVersion`, `isFirstSession` |
| `SESSION_ENDED` | App background / explicit close | `sessionDurationSec`, `matchesPlayedThisSession` |
| `SESSION_CRASH` | Unhandled JS exception | `errorCode`, `errorMessage` (scrubbed), `stackHash` |
| `SESSION_DEEPLINK_OPENED` | Deeplink URL launched app | `deeplinkType`, `referrer` |

#### MATCH Category (Tier 0)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `MATCH_QUEUE_ENTERED` | Player joins matchmaking queue | `gameMode`, `queueTimestamp` |
| `MATCH_QUEUE_EXITED` | Player leaves queue before match found | `gameMode`, `waitDurationSec`, `reason` |
| `MATCH_FOUND` | Matchmaking success | `gameMode`, `waitDurationSec`, `mmrDelta` (range, not exact) |
| `MATCH_STARTED` | Match countdown completes | `matchId`, `gameMode`, `characterId`, `deckHash` |
| `MATCH_ENDED` | Match result screen shown | `matchId`, `gameMode`, `outcome`, `durationSec`, `kills`, `mmrChange` |
| `MATCH_DISCONNECTED` | Player disconnects mid-match | `matchId`, `gameMode`, `matchProgressPct` |
| `MATCH_RECONNECTED` | Player reconnects to active match | `matchId`, `reconnectLatencyMs` |
| `MATCH_TIMEOUT` | Match reaches max duration | `matchId`, `gameMode` |
| `MATCH_BOT_SUBSTITUTED` | Bot replaces disconnected player | `matchId`, `gameMode` |

#### ECONOMY Category (Tier 1)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `ECONOMY_DIAMOND_EARNED` | Diamonds credited to account | `source` (e.g., `"match_win"`, `"quest_complete"`), `amount`, `balanceAfter` |
| `ECONOMY_DIAMOND_SPENT` | Diamonds debited from account | `sink` (e.g., `"character_purchase"`, `"skin_purchase"`), `amount`, `balanceAfter` |
| `ECONOMY_REWARD_GRANTED` | Post-match reward distributed | `matchId`, `rewardType`, `amount` |
| `ECONOMY_PLAY_PASS_APPLIED` | Play Pass bonus applied to reward | `matchId`, `bonusAmount` |

#### PROGRESSION Category (Tier 1)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `PROGRESSION_XP_EARNED` | XP credited after match | `matchId`, `amount`, `source`, `totalXp` |
| `PROGRESSION_LEVEL_UP` | Player reaches new level | `newLevel`, `previousLevel` |
| `PROGRESSION_CHARACTER_UNLOCKED` | Earnable character unlocked | `characterId`, `unlockMethod` (e.g., `"progression"`, `"purchase"`) |
| `PROGRESSION_QUEST_STARTED` | Quest becomes active | `questId`, `questType` |
| `PROGRESSION_QUEST_COMPLETED` | Quest objective met | `questId`, `questType`, `completionTimeSec` |
| `PROGRESSION_QUEST_ABANDONED` | Quest manually cancelled | `questId`, `questType`, `progressPct` |

#### UI Category (Tier 1, sampled at 50% by default)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `UI_SCREEN_VIEWED` | Screen becomes visible | `screenName`, `previousScreen`, `durationMs` (on exit) |
| `UI_CTA_TAPPED` | Primary CTA button tapped | `screenName`, `ctaId` |
| `UI_SHOP_ITEM_VIEWED` | Shop item detail shown | `itemId`, `itemType`, `priceInDiamonds` |

#### ERROR Category (Tier 0)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `ERROR_API_REQUEST_FAILED` | API Client request exhausts retries | `endpoint`, `errorCode`, `httpStatus`, `retryCount` |
| `ERROR_SOCKET_DISCONNECTED` | Socket.io connection drops | `reason`, `reconnectAttempt` |
| `ERROR_PAYMENT_FAILED` | IAP purchase fails | `productId`, `errorCode` (scrubbed of PII) |
| `ERROR_CONTENT_LOAD_FAILED` | Content Catalog fetch fails | `contentType`, `errorCode` |

#### IAP Category (Tier 1)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `IAP_PURCHASE_INITIATED` | Player taps "Buy" on a product | `productId`, `priceUsd`, `currencyCode` |
| `IAP_PURCHASE_COMPLETED` | RevenueCat receipt validated | `productId`, `transactionId` (hashed), `priceUsd` |
| `IAP_PURCHASE_FAILED` | Purchase flow fails or is cancelled | `productId`, `failureReason` |
| `IAP_SUBSCRIPTION_CHANGED` | Play Pass subscribed or lapsed | `eventType` (`"subscribed"` / `"renewed"` / `"lapsed"`), `productId` |

#### ONBOARDING Category (Tier 1)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `ONBOARDING_STARTED` | Tutorial flow begins | `triggeredBy` (`"first_login"` / `"manual"`) |
| `ONBOARDING_STEP_COMPLETED` | Tutorial step acknowledged | `stepId`, `stepName`, `durationSec` |
| `ONBOARDING_STEP_SKIPPED` | Tutorial step skipped | `stepId`, `stepName` |
| `ONBOARDING_COMPLETED` | Full tutorial finished | `totalDurationSec`, `stepsSkipped` |

### 3.5 Client-Side Event Pipeline

1. **Emit** — system calls `analytics.track(eventName, properties)`. Base fields are merged automatically. Consent tier is checked; Tier 1 events are dropped silently if consent is Tier 0.
2. **Validate** — required base fields checked; missing fields log a `WARN` and the event is dropped (not queued).
3. **Enqueue** — event appended to the in-memory queue. Also written to `AsyncStorage` under key `analytics_queue` (survives app restart/crash). Queue is capped at `MAX_QUEUE_SIZE` (default: 500) events; when full, oldest events are evicted (head-of-queue drop).
4. **Flush triggers** — the queue flushes when any of the following occurs:
   - Every `FLUSH_INTERVAL_SEC` (default: 30 s) on a background timer
   - Queue depth reaches `FLUSH_BATCH_SIZE` (default: 50) events
   - App is backgrounded (`AppState` change to `"background"`)
   - Server sends `X-Analytics-Flush: 1` header on any API response
5. **Batch POST** — all queued events sent as a single `POST /v1/analytics/events` payload via the API Client. If the API Client is offline, the flush is deferred; the queue is preserved in `AsyncStorage`.
6. **Retry** — on failure, retry up to `MAX_FLUSH_RETRIES` (default: 3) times with exponential backoff. On 4xx (excluding 429), do not retry — drop the batch and log an ERROR. On exhaustion, drop the batch and log an ERROR.
7. **Deduplication (server-side)** — the server checks `eventId` against a Redis set with 24-hour TTL. Duplicate `eventId` values are acknowledged (200 OK) but not persisted.
8. **Clear** — on successful ingestion, events are removed from both the in-memory queue and `AsyncStorage`.

### 3.6 PII Policy

- `userId` is the Supabase UUID — a pseudonymous identifier. Never log email, display name, or device advertising IDs.
- Cross-match kill references use session-scoped SHA-256 hashes of `userId`, not the raw UUID.
- Error messages are regex-scrubbed before being added to event properties: patterns matching email addresses, JWT tokens, or UUIDs in error strings are replaced with `[REDACTED_VALUE]`.
- Device model and OS version are permitted (class identifiers, not unique IDs).

---

## 4. Formulas

### 4.1 Flush Trigger

```
flush = (queue_depth >= FLUSH_BATCH_SIZE)
     OR (time_since_last_flush >= FLUSH_INTERVAL_SEC)
     OR (app_state == "background")
     OR (server_flush_header_received)
```

### 4.2 Event Volume Estimates (per DAU)

| Category | Events per Match | Matches per DAU (avg) | Events per DAU |
|----------|-----------------|----------------------|----------------|
| SESSION | ~4 | — | ~4 |
| MATCH | ~6 | 5 | ~30 |
| ECONOMY | ~4 | 5 | ~20 |
| PROGRESSION | ~2 | 5 | ~10 |
| UI (50% sampled) | ~3 | 5 | ~8 |
| ERROR | ~0.1 | 5 | ~1 |
| IAP | ~0.05 | — | ~0.05 |
| ONBOARDING | 0 (post-onboarding) | — | 0 |
| **Total** | | | **~73 events/DAU** |

At 100 000 DAU: ~7.3M events/day, ~85 events/second peak. One batch per 50 events = ~1.46M batches/day.

### 4.3 Queue Retention After Crash

```
events_recovered = min(events_in_AsyncStorage_at_crash, MAX_QUEUE_SIZE)
```

In-memory events not yet flushed to AsyncStorage at crash time (~500 ms rescue window via global error handler) may be lost. AsyncStorage events always survive restart.

---

## 5. Edge Cases

**5.1 Offline Event Queueing:**
On flush, if the API Client returns `NetworkOfflineError`, the flush is abandoned (no retries — the API Client's own queue handles reconnection). The analytics queue stays in AsyncStorage. On next flush trigger after reconnection, the full queue is attempted.

**5.2 Failed Batch Submission Retry:**
On HTTP 5xx or timeout: retry up to `MAX_FLUSH_RETRIES` (3) times with exponential backoff (`BASE_FLUSH_RETRY_DELAY_MS = 2 000`, multiplier 2.0). On exhaustion: log ERROR, drop the in-memory batch, clear the AsyncStorage entries for that batch, continue. Dropping events on persistent server failure is preferred over unbounded queue growth.

**5.3 Consent Revocation Mid-Session:**
When `analyticsConsent` changes to `false`: immediately stop all Tier 1 event emission (checked synchronously at `analytics.track()`). Purge all Tier 1 events from the in-memory queue and AsyncStorage. Emit a `POST /v1/analytics/consent-revoked` request (Tier 0 — legal obligation) so the server initiates the 30-day historical deletion job.

**5.4 App Crash With Queued Events:**
The global error handler (see Logging GDD §3.6) triggers an emergency flush attempt. Success is not guaranteed — depends on how quickly the OS terminates the process. Events written to AsyncStorage before the crash are always recovered on the next app launch. In-memory events not yet persisted to AsyncStorage are lost; this is acceptable.

**5.5 Clock Skew Between clientTimestamp and serverTimestamp:**
If `|serverTimestamp - clientTimestamp| > CLOCK_SKEW_WARN_THRESHOLD_SEC` (default: 60 s), the server adds a `clockSkewSec` field to the persisted record and emits a `WARN`. The `serverTimestamp` is always used as the authoritative event time for queries. The `clientTimestamp` is preserved for client-relative duration analysis (e.g., time between two events in the same session).

**5.6 Duplicate eventId Received:**
Server checks Redis deduplication set. If `eventId` found: acknowledge with `200 OK`, do not persist. Client considers the batch delivered. No error is surfaced.

**5.7 Malformed Event (Missing Required Field):**
Client-side validation catches missing base fields before enqueue — event is dropped with a `WARN`, never queued. If a batch arrives server-side with a malformed event (e.g., missing `userId`), the entire batch is rejected with `400 Bad Request`, and the client retries (the batch retry policy applies). The malformed event is flagged in the server error logs with the failing field name.

---

## 6. Dependencies

### 6.1 Upstream

| Dependency | Purpose |
|------------|---------|
| API Client | Batch POST `/v1/analytics/events` |
| Authentication (Supabase) | `userId` attached to every event |
| Player Profile | `analyticsConsent` flag read at emission time |
| App lifecycle (React Native `AppState`) | Background flush trigger |
| `AsyncStorage` | Crash-safe event queue persistence |

### 6.2 Downstream (Systems That Emit Events)

Every system in the game emits to Analytics. Key emitters:

| System | Events Emitted |
|--------|---------------|
| Match Flow | `MATCH_*` events |
| Economy / Reward | `ECONOMY_*` events |
| IAP System | `IAP_*` events |
| XP & Progression | `PROGRESSION_*` events |
| Quest / Mission | `PROGRESSION_QUEST_*` events |
| Main Menu / UI | `UI_*` events |
| Tutorial / Onboarding | `ONBOARDING_*` events |
| API Client | `ERROR_API_REQUEST_FAILED` |
| Logging system | `SESSION_CRASH`, `ERROR_SOCKET_DISCONNECTED` |

### 6.3 Downstream Consumers of Analytics Data

| Consumer | What It Uses |
|----------|-------------|
| Quest / Mission System | Listens for `MATCH_ENDED` to evaluate quest completion (server-side, not via this pipeline) |
| Remote Config | Uses aggregated analytics to drive A/B test assignment |
| Moderation / Reporting | Uses match session events for behavior analysis |
| Game Designer / Balance | Uses match outcome data for balance tuning |

---

## 7. Tuning Knobs

All values in `mobile/src/config/analytics.ts`.

| Constant | Default | Safe Range | Description |
|----------|---------|------------|-------------|
| `FLUSH_INTERVAL_SEC` | 30 | 10 – 120 | Background timer flush interval |
| `FLUSH_BATCH_SIZE` | 50 | 10 – 200 | Events that trigger an immediate flush |
| `MAX_QUEUE_SIZE` | 500 | 100 – 2 000 | Max queued events before head-drop |
| `MAX_FLUSH_RETRIES` | 3 | 0 – 5 | Retry attempts on flush failure |
| `BASE_FLUSH_RETRY_DELAY_MS` | 2 000 | 500 – 10 000 | First retry delay (ms) |
| `CLOCK_SKEW_WARN_THRESHOLD_SEC` | 60 | 10 – 300 | Clock skew threshold before WARN |
| `UI_EVENT_SAMPLE_RATE` | 0.5 | 0.0 – 1.0 | Fraction of UI events collected (0=none, 1=all) |
| `DEDUP_TTL_HOURS` | 24 | 1 – 72 | Redis dedup window (server-side) |

**Notes:** Increasing `FLUSH_BATCH_SIZE` above 200 may cause batch POST payloads to exceed 100 KB on high-event screens — test payload size. `UI_EVENT_SAMPLE_RATE = 1.0` recommended for the first 30 days post-launch to establish a baseline; reduce to 0.5 once volume is understood.

---

## 8. Acceptance Criteria

**AC-01: Base Fields on Every Event**
Given any `analytics.track()` call. When the event is received server-side. Then the persisted record contains all 10 required base fields with non-null values.

**AC-02: Tier 1 Events Dropped Without Consent**
Given a player with `analyticsConsent = false`. When `ECONOMY_DIAMOND_SPENT` is emitted. Then no event appears in the server database for that userId for that eventName. Zero HTTP calls made for that event.

**AC-03: Tier 0 Events Always Collected**
Given a player with `analyticsConsent = false`. When `MATCH_ENDED` is emitted. Then the event is persisted server-side with correct properties.

**AC-04: Batch Flush on Interval**
Given 5 events queued and no other flush trigger. When 30 seconds elapse. Then a `POST /v1/analytics/events` request is made containing those 5 events.

**AC-05: Batch Flush on Size Threshold**
Given `FLUSH_BATCH_SIZE = 50`. When the 50th event is enqueued. Then a flush is triggered immediately without waiting for the interval timer.

**AC-06: Batch Flush on Background**
Given 10 events queued. When the app is backgrounded. Then a flush is triggered within 2 seconds of the background event.

**AC-07: Events Survive App Restart**
Given 20 events queued in AsyncStorage. When the app is force-killed and relaunched. Then all 20 events are in the queue on next launch and are flushed on the next trigger.

**AC-08: Retry on Server Error**
Given the server returns `500` on the first two flush attempts then `200`. When `MAX_FLUSH_RETRIES = 3`. Then the batch is delivered on the third attempt; three HTTP calls made; events cleared from queue.

**AC-09: Duplicate eventId Not Persisted**
Given the same batch is sent twice (same `eventId` values). When both are received. Then the database contains exactly one record per `eventId`. Both requests return `200 OK`.

**AC-10: Consent Revocation Purges Queue**
Given a player has 30 Tier 1 events queued. When `analyticsConsent` is set to `false`. Then all Tier 1 events are removed from in-memory queue and AsyncStorage. Tier 0 events in the queue are preserved.

**AC-11: Clock Skew Flagged**
Given a client event with `clientTimestamp` 90 seconds behind `serverTimestamp`. When ingested. Then the persisted record has `clockSkewSec = 90` and a WARN is emitted server-side. The event is persisted using `serverTimestamp` as the authoritative time.

**AC-12: UI Events Respect Sample Rate**
Given `UI_EVENT_SAMPLE_RATE = 0.5` and 1 000 `UI_SCREEN_VIEWED` events emitted in a test run. When results are counted. Then between 400 and 600 events are queued (±10% tolerance for RNG).

**AC-13: Malformed Event Dropped Client-Side**
Given an `analytics.track()` call with `userId` missing. When called. Then the event is not enqueued; a WARN is logged with the missing field name; zero HTTP calls made for that event.
