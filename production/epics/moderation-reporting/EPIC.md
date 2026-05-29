# Epic: Moderation / Reporting

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/moderation-reporting.md
> **Architecture Module**: Moderation / Reporting
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories moderation-reporting`

## Overview

Moderation / Reporting allows players to report others for toxic behavior or cheating during or after a match. Reports are stored server-side and fed to an admin dashboard for review. The system records report metadata (reporter, reported player, match context, timestamp, category) and can flag accounts for review. At MVP scope: report submission only (no automated action). Post-MVP: automated muting/banning based on report thresholds. Rate limiting prevents report spam.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Client-Server Architecture | Moderation in server Feature layer; reports stored server-side | LOW |
| ADR-0004: Authentication Architecture | Reporter and reported player identified by userId | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0001 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/moderation-reporting.md` verified
- Report submitted during match → stored with matchId, reporter, reported, category, timestamp
- Rate limiting: max 5 reports per userId per hour (integration test)
- Reports queryable by admin (basic admin endpoint, JWT-protected with admin claim)
- Self-report rejected (reporterId = reportedId → 400)

## Next Step

Run `/create-stories moderation-reporting` to break this epic into implementable stories.
