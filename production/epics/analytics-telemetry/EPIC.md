# Epic: Analytics / Telemetry

> **Layer**: Foundation (Ops — Horizontal)
> **GDD**: design/gdd/analytics-telemetry.md
> **Architecture Module**: Analytics Service (cross-cutting, both client and server)
> **Status**: Ready
> **Stories**: 4 stories created

## Overview

Analytics / Telemetry provides a fire-and-forget event sink that records player behavior events from both the client and server without blocking any game or economy hot path. Events carry a consistent schema: `userId`, `timestamp`, `event`, and typed `properties`. At MVP, events are written to structured JSON logs; post-launch they migrate to a managed analytics service (Mixpanel, Amplitude, or BigQuery) by swapping the sink in `AnalyticsService`. Required events include `match_started`, `match_ended`, `character_selected`, `ability_used`, `iap_purchased`, `level_up`, `quest_completed`, `screen_viewed`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0015: Analytics Event Architecture | Fire-and-forget via setImmediate; structured JSON log sink; no await in hot path | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0015 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/analytics-telemetry.md` verified
- `analyticsService.track()` adds ≤0.1ms to any calling function (benchmark)
- All 8 required events appear in logs during a full match session (manual QA)
- No PII (email, device ID, IP) in any event properties (code review gate)

## Next Step

Run `/create-stories analytics-telemetry` to break this epic into implementable stories.
