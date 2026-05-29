# ADR-0015: Analytics Event Architecture (Fire-and-Forget Event Sink)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Analytics Engineer

## Summary

BRAWLZONE sends analytics events from both the client and server to a fire-and-forget event sink (initially console/file logging with structured JSON; production target is a managed analytics service). Events are never awaited in the hot path. This ADR defines the event schema, the fire-and-forget pattern, and the list of required events.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Ops |
| **Knowledge Risk** | LOW |
| **References Consulted** | `design/gdd/analytics-telemetry.md`, `design/gdd/logging-monitoring.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004 (userId for event attribution) |
| **Enables** | Analytics dashboards, A/B test instrumentation |
| **Blocks** | None — analytics is non-blocking and deferrable |
| **Ordering Note** | Deferrable to Alpha milestone |

## Context

### Problem Statement

Post-launch product decisions require data on player behavior (funnel drop-off, match mode popularity, economy flows, churn points). Analytics must not block game systems — a slow analytics sink cannot affect match latency or economy writes.

### Constraints

- Analytics events must never `await` in the game loop or economy hot path
- Events should carry a consistent schema (userId, timestamp, event name, properties)
- Client and server both emit events; server events are higher-trust
- MVP: structured JSON log sink; post-launch: migrate to managed service (Mixpanel / Amplitude)

### Requirements

- `track(event: string, properties: Record<string, unknown>)` — fire-and-forget; never throws
- Events: `match_started`, `match_ended`, `character_selected`, `ability_used`, `iap_purchased`, `level_up`, `quest_completed`, `screen_viewed`
- Server events include `userId`; client events include `userId` + `sessionId`
- No PII beyond `userId` in event properties — no email, device ID, IP address

## Decision

Implement a thin `AnalyticsService` wrapper with a fire-and-forget pattern. At MVP, events are written to structured JSON logs (server) and `console.log` (client). Migration to a managed service requires only changing the sink in `AnalyticsService`.

### Architecture

```
SERVER (hot-path system):
  // Never awaited:
  analyticsService.track('match_ended', { matchId, mode, duration, playerCount });
  // ↑ Returns immediately; event queued in background

  AnalyticsService.track(event, props):
    setImmediate(() => {
      const payload = { userId, timestamp: Date.now(), event, ...props };
      logger.info(JSON.stringify(payload));  // → structured log sink
      // Future: send to Mixpanel/Amplitude API
    })

CLIENT:
  AnalyticsService.track('screen_viewed', { screen: 'MainMenu' });
  // → fire-and-forget HTTP POST to analytics endpoint or local buffer
```

### Key Interfaces

```typescript
interface IAnalyticsService {
  track(event: AnalyticsEvent, properties?: Record<string, unknown>): void;  // void; never async
  identify(userId: string, traits?: Record<string, unknown>): void;
}

type AnalyticsEvent =
  | 'match_started' | 'match_ended' | 'character_selected' | 'ability_used'
  | 'iap_purchased' | 'level_up' | 'quest_completed' | 'screen_viewed'
  | 'queue_joined' | 'queue_cancelled' | 'match_found'
  | 'disconnect' | 'reconnect';
```

## Consequences

### Positive

- Analytics never affects game or economy performance
- Structured JSON logs are queryable immediately (grep, jq, log aggregation)
- Single sink interface makes production migration a one-file change

### Negative

- MVP analytics are in logs only — no real-time dashboard until post-launch migration
- Event loss is possible if process crashes before `setImmediate` fires

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Events lost on crash | Low | Low | Analytics data is advisory, not financial; loss is acceptable at MVP |

## Validation Criteria

- [ ] `match_ended` event appears in server logs after every match
- [ ] `analyticsService.track()` adds ≤0.1ms to any calling function (benchmark)
- [ ] No PII in event properties (code review gate)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/analytics-telemetry.md` | Analytics | Fire-and-forget events from client + server | setImmediate pattern; no await in hot path |
| `design/gdd/logging-monitoring.md` | Logging | Structured JSON logs | JSON payload format defined |

## Related

- ADR-0001: Analytics is in the cross-cutting Ops layer
