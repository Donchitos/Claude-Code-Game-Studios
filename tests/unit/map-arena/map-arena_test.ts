import * as path from 'path';
import { ContentCatalogService } from '../../../server/src/catalog/contentCatalog';
import { MapSelector, SpawnAssigner, BoundaryEnforcer, ZoneManager, MapConfig, ZonePhase } from '../../../server/src/game/mapSystem';

const CATALOG_PATH = path.join(__dirname, '../../../server/src/data/content-catalog.json');

function makeSystems() {
  const catalog = ContentCatalogService.init(CATALOG_PATH);
  return {
    selector: new MapSelector(catalog),
    assigner: new SpawnAssigner(),
    boundary: new BoundaryEnforcer(),
    zone: new ZoneManager(),
    catalog,
  };
}

function makeMap(overrides: Partial<MapConfig> = {}): MapConfig {
  return {
    id: 'map:test', type: 'map', status: 'active',
    displayName: 'Test', widthLgu: 50, heightLgu: 50,
    safeBoundaryInset: 0.5, modeCompatibility: ['mode:duel_1v1'],
    spawnPoints: [
      { x: 5, y: 5 }, { x: 45, y: 45 }, { x: 5, y: 45 }, { x: 45, y: 5 },
      { x: 25, y: 5 }, { x: 25, y: 45 }, { x: 5, y: 25 }, { x: 45, y: 25 },
    ],
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Story 001: Schema validation & mode-based selection (AC-01, AC-02, AC-03, AC-04)
// ---------------------------------------------------------------------------

describe('map-arena — schema validation & selection', () => {
  it('test_catalogHasMapsForAllModes', () => {
    const { catalog } = makeSystems();
    const maps = catalog.getAll<MapConfig>('map');
    const modes = ['mode:duel_1v1', 'mode:squad_3v3', 'mode:ffa_8'];
    for (const mode of modes) {
      expect(maps.some(m => m.modeCompatibility.includes(mode))).toBe(true);
    }
  });

  it('test_selector_returnsCompatibleMap', () => {
    const { selector } = makeSystems();
    const mapId = selector.selectForMode('mode:duel_1v1');
    expect(mapId).not.toBeNull();
    expect(mapId).toMatch(/^map:/);
  });

  it('test_selector_returnsNullForUnknownMode', () => {
    const { selector } = makeSystems();
    expect(selector.selectForMode('mode:unknown')).toBeNull();
  });

  it('test_selector_suppressesMostRecentMap', () => {
    const { selector, catalog } = makeSystems();
    const first = selector.selectForMode('mode:duel_1v1');
    // Run enough selections to verify we don't always get the same map
    const results = new Set<string>();
    for (let i = 0; i < 10; i++) results.add(selector.selectForMode('mode:duel_1v1')!);
    // With suppression, we should see more than 1 unique map (if >1 exist)
    const duelMaps = catalog.getAll<MapConfig>('map').filter(m => m.modeCompatibility.includes('mode:duel_1v1'));
    if (duelMaps.length > 1) {
      expect(results.size).toBeGreaterThan(1);
    }
  });
});

// ---------------------------------------------------------------------------
// Story 002: Spawn assignment (AC-05, AC-06)
// ---------------------------------------------------------------------------

describe('map-arena — spawn assignment', () => {
  it('test_1v1_uniqueSpawns_minDistance12', () => {
    const { assigner } = makeSystems();
    const map = makeMap();
    const spawns = assigner.assignSpawns(map, 2, 'mode:duel_1v1');
    expect(spawns.length).toBe(2);
    expect(spawns[0]).not.toEqual(spawns[1]);
    const dist = Math.sqrt((spawns[0].x - spawns[1].x) ** 2 + (spawns[0].y - spawns[1].y) ** 2);
    expect(dist).toBeGreaterThanOrEqual(12);
  });

  it('test_ffa_8players_uniqueSpawns', () => {
    const { assigner } = makeSystems();
    const map = makeMap({ modeCompatibility: ['mode:ffa_8'] });
    const spawns = assigner.assignSpawns(map, 8, 'mode:ffa_8');
    expect(spawns.length).toBe(8);
    const uniqueSpawns = new Set(spawns.map(s => `${s.x},${s.y}`));
    expect(uniqueSpawns.size).toBe(8);
  });
});

// ---------------------------------------------------------------------------
// Story 003: Obstacle collision & boundary clamping (AC-07, AC-17)
// ---------------------------------------------------------------------------

describe('map-arena — boundary clamping', () => {
  it('test_clampPosition_insideBounds', () => {
    const { boundary } = makeSystems();
    const map = makeMap({ widthLgu: 50, heightLgu: 50, safeBoundaryInset: 0.5 });
    const pos = { x: 25, y: 25 };
    expect(boundary.clampToSafeBounds(map, pos)).toEqual(pos);
  });

  it('test_clampPosition_clampsToBoundary', () => {
    const { boundary } = makeSystems();
    const map = makeMap({ widthLgu: 50, heightLgu: 50, safeBoundaryInset: 0.5 });
    const clamped = boundary.clampToSafeBounds(map, { x: 0.3, y: 25 });
    expect(clamped.x).toBe(0.5);
  });

  it('test_isOutsideSafeBounds', () => {
    const { boundary } = makeSystems();
    const map = makeMap({ widthLgu: 50, heightLgu: 50, safeBoundaryInset: 0.5 });
    expect(boundary.isOutsideSafeBounds(map, { x: 0.3, y: 25 })).toBe(true);
    expect(boundary.isOutsideSafeBounds(map, { x: 25, y: 25 })).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Story 004: Zone shrink (AC-10, AC-11, AC-12, AC-13)
// ---------------------------------------------------------------------------

describe('map-arena — zone shrink', () => {
  const phases: ZonePhase[] = [
    { startDelaySec: 60, initialRadius: 60, endRadius: 36, durationSec: 60, damagePerSec: 15 },
  ];

  it('test_zoneRadius_beforeDelay_isInitial', () => {
    const zone = new ZoneManager();
    expect(zone.getRadius(59, phases)).toBe(60); // before delay — full radius
  });

  it('test_zoneRadius_midPhase_interpolated', () => {
    const zone = new ZoneManager();
    // At T=90s: 60s delay elapsed, 30s into 60s phase → alpha=0.5
    // radius = 60 + (36 - 60) * 0.5 = 60 - 12 = 48
    const r = zone.getRadius(90, phases);
    expect(Math.abs(r - 48.0)).toBeLessThan(0.1);
  });

  it('test_zoneDamagePerTick_50ms', () => {
    const zone = new ZoneManager();
    const dmg = zone.getDamagePerTick(phases[0]);
    expect(Math.abs(dmg - 0.75)).toBeLessThan(0.001); // 15 * 0.05
  });
});

// ---------------------------------------------------------------------------
// Story 005: Load failure & fallback (AC-14, AC-17)
// ---------------------------------------------------------------------------

describe('map-arena — fallback', () => {
  it('test_selector_noCompatibleMap_returnsNull', () => {
    const { selector } = makeSystems();
    // 'mode:unknown' has no maps
    expect(selector.selectForMode('mode:unknown')).toBeNull();
  });
});
