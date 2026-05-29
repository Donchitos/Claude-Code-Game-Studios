# Epic: Remote Config / Live Tuning

> **Layer**: Foundation (Ops)
> **GDD**: design/gdd/remote-config.md
> **Architecture Module**: Remote Config Reader (server + client)
> **Status**: Ready
> **Stories**: 4 stories created

## Overview

Remote Config enables server-side live tuning of numeric game values without a redeploy. The server fetches a key-value config bundle from a remote source (initially a static JSON file in a CDN or environment variable set; long-term: Firebase Remote Config or LaunchDarkly) and calls `catalog.applyOverlay()` on successful fetch. Key values include `maxSkillSpreadMMR` (300), ability damage multipliers, coin reward amounts, and matchmaking timing parameters. The client receives overridden values via the catalog snapshot (`GET /v1/catalog`).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | `applyOverlay()` is the Remote Config write path; called only by Remote Config | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/remote-config.md` verified
- `maxSkillSpreadMMR` can be changed from 300 to 400 via remote config without redeploy
- Unknown overlay keys log a warning and are ignored
- Structural records (character IDs, ability types) cannot be overridden via overlay

## Next Step

Run `/create-stories remote-config` to break this epic into implementable stories.
