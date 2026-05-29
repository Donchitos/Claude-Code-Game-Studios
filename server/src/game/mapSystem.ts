import { IContentCatalog, CatalogRecord } from '../catalog/contentCatalog';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface SpawnPoint { x: number; y: number; }

export interface MapConfig extends CatalogRecord {
  type: 'map';
  displayName: string;
  widthLgu: number;
  heightLgu: number;
  safeBoundaryInset: number;
  modeCompatibility: string[];
  spawnPoints: SpawnPoint[];
}

export interface Vector2 { x: number; y: number; }

// ---------------------------------------------------------------------------
// MapSelector
// ---------------------------------------------------------------------------

export class MapSelector {
  private readonly catalog: IContentCatalog;
  private readonly recentMaps = new Map<string, string>(); // modeId → last used mapId

  constructor(catalog: IContentCatalog) {
    this.catalog = catalog;
  }

  /**
   * Selects a map for the given mode.
   * Suppresses the most-recently-played map (weight 0) if other options exist.
   * Returns null if no compatible map found.
   */
  selectForMode(modeId: string): string | null {
    const candidates = this.catalog
      .getAll<MapConfig>('map')
      .filter((m) => m.status === 'active' && m.modeCompatibility.includes(modeId));

    if (candidates.length === 0) return null;

    const lastUsed = this.recentMaps.get(modeId);
    const filtered = candidates.filter((m) => m.id !== lastUsed);
    const pool = filtered.length > 0 ? filtered : candidates; // fallback if single-map pool

    if (pool.length === 0) return null;

    // Simple uniform random — in production this would be weighted
    const selected = pool[Math.floor(Math.random() * pool.length)];
    this.recentMaps.set(modeId, selected.id);
    return selected.id;
  }
}

// ---------------------------------------------------------------------------
// SpawnAssigner
// ---------------------------------------------------------------------------

const MIN_SPAWN_DISTANCE_1V1 = 12;
const MIN_SPAWN_DISTANCE_FFA = 10;
const MIN_SPAWN_DISTANCE_DEFAULT = 8;

export class SpawnAssigner {
  assignSpawns(map: MapConfig, playerCount: number, modeId: string): SpawnPoint[] {
    const minDist = modeId === 'mode:duel_1v1' ? MIN_SPAWN_DISTANCE_1V1
                  : modeId === 'mode:ffa_8'   ? MIN_SPAWN_DISTANCE_FFA
                  : MIN_SPAWN_DISTANCE_DEFAULT;

    // Greedy selection: pick spawn points that satisfy distance constraints
    const selected: SpawnPoint[] = [];
    const available = [...map.spawnPoints];

    for (let i = 0; i < playerCount && available.length > 0; i++) {
      const candidateIdx = available.findIndex((candidate) =>
        selected.every((s) => this.distance(s, candidate) >= minDist)
      );
      if (candidateIdx >= 0) {
        selected.push(available.splice(candidateIdx, 1)[0]);
      } else {
        // Fallback: just take the next available point
        selected.push(available.shift()!);
      }
    }

    return selected;
  }

  private distance(a: SpawnPoint, b: SpawnPoint): number {
    return Math.sqrt((a.x - b.x) ** 2 + (a.y - b.y) ** 2);
  }
}

// ---------------------------------------------------------------------------
// BoundaryEnforcer
// ---------------------------------------------------------------------------

export class BoundaryEnforcer {
  clampToSafeBounds(map: MapConfig, pos: Vector2): Vector2 {
    const inset = map.safeBoundaryInset;
    return {
      x: Math.max(inset, Math.min(map.widthLgu - inset, pos.x)),
      y: Math.max(inset, Math.min(map.heightLgu - inset, pos.y)),
    };
  }

  isOutsideSafeBounds(map: MapConfig, pos: Vector2): boolean {
    const inset = map.safeBoundaryInset;
    return pos.x < inset || pos.x > map.widthLgu - inset ||
           pos.y < inset || pos.y > map.heightLgu - inset;
  }
}

// ---------------------------------------------------------------------------
// ZoneManager (FFA only)
// ---------------------------------------------------------------------------

export interface ZonePhase {
  startDelaySec: number;
  initialRadius: number;
  endRadius: number;
  durationSec: number;
  damagePerSec: number;
}

export class ZoneManager {
  /**
   * Returns the current zone radius at `matchTimeSec`.
   * `phases` is an array of sequential shrink phases.
   */
  getRadius(matchTimeSec: number, phases: ZonePhase[]): number {
    let elapsed = matchTimeSec;

    for (const phase of phases) {
      if (elapsed < phase.startDelaySec) {
        return phase.initialRadius;
      }
      elapsed -= phase.startDelaySec;
      if (elapsed < phase.durationSec) {
        const alpha = elapsed / phase.durationSec;
        return phase.initialRadius + (phase.endRadius - phase.initialRadius) * alpha;
      }
      elapsed -= phase.durationSec;
    }

    // After all phases: final radius of last phase
    return phases.length > 0 ? phases[phases.length - 1].endRadius : Infinity;
  }

  /** Returns zone damage for one tick (50ms) for a player outside the zone. */
  getDamagePerTick(phase: ZonePhase): number {
    return phase.damagePerSec * 0.05; // 50ms = 0.05s
  }
}
