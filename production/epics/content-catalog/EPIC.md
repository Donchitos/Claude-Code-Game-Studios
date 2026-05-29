# Epic: Content Catalog

> **Layer**: Foundation
> **GDD**: design/gdd/content-catalog.md
> **Architecture Module**: Content Catalog Service
> **Status**: Ready
> **Stories**: 5 stories created

## Overview

The Content Catalog is the in-memory singleton that holds all canonical game content records: 8 characters, 18 abilities, 3 game modes, 6 maps, IAP packs, cosmetics, quest templates, and battle pass season configs. It loads from `server/src/data/content-catalog.json` at server startup (step 4 of the init sequence), validates all records, and exposes `IContentCatalog` for O(1) lookups by canonical `{type}:{slug}` ID. Remote Config can push a numeric overlay at runtime. The catalog is read-only at runtime after `applyOverlay()` completes. The client receives a snapshot via `GET /v1/catalog` for display purposes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | Static JSON bundle + Remote Config overlay; read-only at runtime; `{type}:{slug}` canonical IDs | LOW |
| ADR-0001: Client-Server Architecture | Content Catalog in Server Foundation layer; loaded at step 4 of init order | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/content-catalog.md` verified
- Server startup throws on missing required records (fail-fast)
- `catalog.get('unknown:id')` returns null, never throws
- `applyOverlay()` patches numeric values within 100ms
- CI script confirms all GDD-referenced IDs exist in `content-catalog.json`
- `GET /v1/catalog` returns full snapshot (integration test)

## Next Step

Run `/create-stories content-catalog` to break this epic into implementable stories.
