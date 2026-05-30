# ADR-0007: Content Catalog Architecture (Static Bundle + Remote Overlay)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

All canonical game content records (characters, abilities, game modes, maps, IAP packs, cosmetics, quest templates) are loaded from a static JSON bundle at server startup and exposed through `IContentCatalog`. Remote Config can push a runtime overlay to tune numeric values without a redeploy. All IDs use the `{type}:{slug}` canonical format. The catalog is read-only at runtime; no code path may mutate it.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW |
| **References Consulted** | `design/gdd/content-catalog.md`, `design/gdd/character-system.md`, `design/gdd/ability-skill.md`, `design/gdd/game-mode.md`, `design/gdd/map-arena.md`, `design/gdd/deck-loadout.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 |
| **Enables** | ADR-0003 (ability lookups in simulation), ADR-0007 itself enables Character System, Ability Registry, Game Mode Config, Deck/Loadout Validator, IAP system |
| **Blocks** | All systems that perform lookups by canonical ID |
| **Ordering Note** | Must be Accepted and implemented before any system that calls `catalog.get()` |

## Context

### Problem Statement

The game has 8 characters, 18 abilities, 3 game modes, 6 maps, IAP packs, cosmetics, and quest templates — all referenced by string IDs across server systems. Without a canonical source of truth, IDs drift (seen in the cross-review: `brawler_kai` vs `character:kai`). Without a runtime overlay mechanism, tuning a single value (e.g. `maxSkillSpreadMMR`) requires a server redeploy.

### Current State

No content catalog implemented. GDDs reference `character:{slug}` IDs after normalization in cross-review 2026-05-29. 

### Constraints

- IDs must be normalized to `{type}:{slug}` format across all systems (enforced by cross-review)
- Catalog is read at server startup; no DB query per lookup in the hot path
- Remote Config overlay applies only to numeric tuning values (prices, durations, MMR thresholds) — structural records (character definitions, ability logic) cannot be overlaid
- Client receives a `ContentCatalogSnapshot` via `GET /v1/catalog` — read-only for display purposes

### Requirements

- All canonical records loaded into memory at startup (step 4 of server init order)
- `catalog.get(id)` returns null for unknown IDs (never throws)
- `catalog.getAll(type)` returns all records of a given type
- `applyOverlay(map)` is the only write path — called only by Remote Config after a successful remote fetch
- The catalog ships with the static bundle; `applyOverlay` patches numeric fields at runtime

## Decision

The Content Catalog is an **in-memory singleton** initialized from a static JSON bundle (`server/src/data/content-catalog.json`). Remote Config can push a key-value overlay that patches numeric tuning values. The catalog is read-only after `applyOverlay()` completes; all subsequent reads are O(1) map lookups.

### Architecture

```
SERVER STARTUP (step 4):
  ContentCatalogService.init()
  ├── load content-catalog.json from disk
  ├── parse and validate all records (schema check; throw on invalid)
  ├── build Map<string, CatalogRecord> keyed by canonical ID
  └── expose IContentCatalog singleton

REMOTE CONFIG (after server startup):
  RemoteConfig.onRefresh()
  └── catalog.applyOverlay({ 'mm:maxSkillSpreadMMR': 300, ... })
      └── patches numeric values in place; structural records unchanged

RUNTIME READS (all hot-path systems):
  catalog.get('character:vex')       → CharacterDefinition | null
  catalog.get('ability:piercing_shot') → AbilityDefinition | null
  catalog.getAll('character')        → CharacterDefinition[]
  catalog.get('mode:duel_1v1')       → GameModeConfig | null
  catalog.get('map:serpent_canyon')  → MapConfig | null

CLIENT (display only):
  GET /v1/catalog → ContentCatalogSnapshot (all records, current overlay applied)
```

### Key Interfaces

```typescript
type ContentType = 'character' | 'ability' | 'mode' | 'map' | 'iap_pack' | 'cosmetic' | 'quest_template' | 'battle_pass_season';

interface IContentCatalog {
  get<T extends CatalogRecord>(id: string): T | null;
  getAll<T extends CatalogRecord>(type: ContentType): T[];
  applyOverlay(map: Record<string, number | string>): void;
  // Invariant: applyOverlay called only by RemoteConfig; never in test code
  // Invariant: read-only at runtime after init; no mutation outside applyOverlay
}

// Canonical ID format — enforced by catalog validator on startup
// {type}:{slug}  e.g. 'character:vex', 'ability:piercing_shot', 'mode:duel_1v1'
// Slug: lowercase, hyphen-separated, no spaces

interface CharacterDefinition {
  id: string;          // 'character:{slug}'
  name: string;        // display name
  maxHp: number;
  baseSpeed: number;
  passiveType: string;
  passiveConfig: Record<string, number>;
  defaultSkinId: string;  // 'skin:{slug}'
  availableAbilities: string[];  // 'ability:{slug}'[]
  xpToUnlock: number;
}

interface AbilityDefinition {
  id: string;          // 'ability:{slug}'
  name: string;
  type: 'basic' | 'active';
  damage: number;
  cooldownMs: number;
  range: number;
  statusEffect?: StatusEffectDefinition;
}

interface GameModeConfig {
  id: string;           // 'mode:duel_1v1' | 'mode:squad_3v3' | 'mode:ffa_8'
  displayName: string;
  playerCount: number;
  teamSize: number;
  maxDurationSec: number;
  winCondition: 'last_standing' | 'team_elimination' | 'score_target';
}
```

### Implementation Guidelines

- `content-catalog.json` is the build artifact; source of truth is the GDDs; any discrepancy is a bug
- Server startup throws if any required record is missing (fail-fast; never silently degrade)
- `applyOverlay()` only patches fields that exist in the record — unknown keys are ignored with a warning log
- The overlay never changes IDs, type fields, or array-type fields — only numeric and string scalars
- Client receives the full catalog snapshot for display purposes; it must not use the catalog for game logic

## Alternatives Considered

### Alternative 1: Database-Backed Catalog

- **Description**: Store all content records in PostgreSQL; query them per-request.
- **Pros**: Easy to update without redeploy; admin panel can edit records live.
- **Cons**: Every `catalog.get()` becomes a DB query; unacceptable in the 20Hz tick loop.
- **Rejection Reason**: Tick loop calls ability lookups synchronously; DB queries are async and would block the tick.

### Alternative 2: Hardcoded Constants in Code

- **Description**: Define character stats, ability damage, etc. as TypeScript constants.
- **Pros**: Type-safe; no JSON parsing; no runtime loading.
- **Cons**: No runtime tuning without redeployment; constants drift from GDDs over time.
- **Rejection Reason**: Remote Config overlay requirement eliminates compile-time constants for tuning values.

## Consequences

### Positive

- All `catalog.get()` calls are O(1) Map lookups — zero impact on tick budget
- Remote Config overlay enables live tuning of MMR thresholds, ability damage, match durations without redeploy
- Startup validation catches ID drift before any player is affected

### Negative

- Static bundle must be rebuilt and redeployed for structural content changes (new characters, abilities)
- `content-catalog.json` can drift from GDDs if not kept in sync (mitigated by CI validation script)

### Neutral

- Client receives the catalog for display; it is a snapshot — client never writes to it

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Overlay patches wrong field (typo in key) | Low | Medium | Log warning on unknown key; integration test overlays in CI |
| content-catalog.json out of sync with GDDs | Medium | Medium | CI script compares catalog IDs against GDD ability/character lists |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| catalog.get() latency | — | O(1) / <0.1ms | — |
| Server startup (catalog load) | — | <100ms | — |
| Catalog memory footprint | — | <5MB | — |

## Migration Plan

New project.

**Rollback plan**: Revert `content-catalog.json` to previous version; redeploy. Overlay can be reset by pushing an empty overlay via Remote Config.

## Validation Criteria

- [ ] Server startup fails fast (throw) if any character, ability, or mode record is missing from catalog
- [ ] `catalog.get('unknown:id')` returns null (never throws)
- [ ] `applyOverlay({ 'mm:maxSkillSpreadMMR': 300 })` updates the live value within 100ms
- [ ] Client receives full catalog snapshot from `GET /v1/catalog`
- [ ] CI script confirms all IDs in GDDs match IDs in `content-catalog.json`

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/content-catalog.md` | Content Catalog | Static bundle + remote overlay | In-memory map from JSON bundle; `applyOverlay()` from Remote Config |
| `design/gdd/character-system.md` | Character System | CharacterDefinition per character | `catalog.get('character:{slug}')` returns typed definition |
| `design/gdd/ability-skill.md` | Ability | 18 canonical abilities | `catalog.getAll('ability')` returns all 18 |
| `design/gdd/game-mode.md` | Game Mode | 3 mode configs | `catalog.get('mode:duel_1v1' | 'mode:squad_3v3' | 'mode:ffa_8')` |
| `design/gdd/deck-loadout.md` | Deck/Loadout | Validate ability ownership | `loadout.validate()` calls `catalog.get(abilityId)` for each slot |

## Related

- ADR-0001: Content Catalog is in the Server Foundation layer per the system layer map
- ADR-0003: Game loop calls `catalog.get(abilityId)` in simulation phase
- ADR-0012: Session Manager uses `catalog.get('mode:{id}')` to build MatchConfig
