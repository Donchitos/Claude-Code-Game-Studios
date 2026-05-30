# Epic: Ability / Skill System

> **Layer**: Foundation
> **GDD**: design/gdd/ability-skill.md
> **Architecture Module**: Ability Registry
> **Status**: Ready
> **Stories**: 7/7 Complete

## Overview

The Ability Registry owns 18 canonical ability definitions, their cooldown defaults, damage values, range, and status effect specs. It loads from the Content Catalog at server startup. The Match Server's simulation phase uses the registry for ability validation (cooldown check, ownership) and damage resolution. Two ability slots per character: slot 0 (basic attack, always available) and slot 1 (unlocked via character XP). Abilities are identified by `ability:{slug}` canonical IDs.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | AbilityDefinition sourced from catalog; `catalog.get('ability:{slug}')` | LOW |
| ADR-0003: Server-Side Game Loop | Cooldown validation in tick Phase 2; ability use queued in Phase 1 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅, ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/ability-skill.md` verified
- All 18 ability definitions loaded and validated at startup
- Cooldown enforcement tested: using ability before cooldown expires → rejected
- Status effect application covered by unit tests
- `ability.get('unknown:id')` returns null; does not crash simulation

## Next Step

Run `/create-stories ability-skill` to break this epic into implementable stories.
