# Epic: Map / Arena System

> **Layer**: Foundation
> **GDD**: design/gdd/map-arena.md
> **Architecture Module**: Map Config (server), Map Renderer (client)
> **Status**: Ready
> **Stories**: 5 stories created

## Overview

The Map / Arena System defines the 6 launch maps: their boundaries, spawn points, obstacle layouts, and LGU coordinate space (origin bottom-left, Y-axis up). Map configs are loaded from the Content Catalog. The server uses map configs for collision validation, spawn point assignment, and boundary enforcement in the simulation phase. The client renders map geometry as a static background for the match HUD. Each map config specifies the arena dimensions, spawn positions per mode, and static obstacle bounding boxes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | MapConfig sourced from catalog; `catalog.get('map:{slug}')` | LOW |
| ADR-0003: Server-Side Game Loop | Position validation against map boundaries in simulation phase | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅, ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/map-arena.md` verified
- All 6 map configs loaded and validated at startup
- Server rejects player positions outside map boundaries
- Spawn points produce non-overlapping start positions for all player counts
- Client renders correct map background for each map ID

## Next Step

Run `/create-stories map-arena` to break this epic into implementable stories.
