# Epic: Quest / Mission System

> **Layer**: Feature
> **GDD**: design/gdd/quest-mission.md
> **Architecture Module**: Quest System
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Quest / Mission System assigns daily and weekly quests to players, tracks progress across matches, and grants coin rewards on completion. Quest templates are defined in the Content Catalog (`type: 'quest_template'`). Progress is stored in the `quest_progress` table. After each match, `QuestSystem.processMatchResult()` fires as part of the Match Flow fan-out, updating progress for active quests. Daily quests reset at UTC midnight; weekly quests reset on Monday UTC. Completed quests grant coins via the Currency System with idempotency keys.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | QuestSystem.processMatchResult fires in allSettled fan-out | LOW |
| ADR-0008: Economy Transaction Safety | Quest completion coin grant uses idempotency key | LOW |
| ADR-0007: Content Catalog Architecture | Quest templates sourced from catalog (`type: 'quest_template'`) | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/quest-mission.md` verified
- Quest progress increments correctly after a qualifying match (integration test)
- Quest completion grants coins (idempotent — duplicate completion event is no-op)
- Daily reset occurs at UTC midnight (unit test with mocked clock)
- Weekly reset occurs on Monday UTC (unit test with mocked clock)
- Quest progress visible in profile immediately after match via `profile:refresh`

## Next Step

Run `/create-stories quest-mission` to break this epic into implementable stories.
