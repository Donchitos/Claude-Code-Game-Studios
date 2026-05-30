import * as fs from 'fs';
import * as path from 'path';
import { ILogger } from '../logging/logger';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ContentType = 'character' | 'ability' | 'mode' | 'map' | 'iap_pack' | 'cosmetic' | 'quest_template' | 'battle_pass_season';
export type RecordStatus = 'active' | 'inactive' | 'deprecated';

export interface CatalogRecord {
  id: string;
  type: ContentType;
  status: RecordStatus;
  [key: string]: unknown;
}

export interface IContentCatalog {
  get<T extends CatalogRecord = CatalogRecord>(id: string): T | null;
  getAll<T extends CatalogRecord = CatalogRecord>(type: ContentType): T[];
  /**
   * Applies a sparse numeric/string overlay from Remote Config.
   * Only keys of the form `{recordId}.{fieldName}` are processed.
   * Unknown keys, structural fields, and type mismatches are silently skipped.
   */
  applyOverlay(map: Record<string, number | string>): void;
}

// ---------------------------------------------------------------------------
// Overlay allowlist — fields that Remote Config may patch
// ---------------------------------------------------------------------------

const OVERLAY_ALLOWED_FIELDS: ReadonlySet<string> = new Set([
  'maxHp', 'baseSpeed', 'damage', 'cooldownSec', 'range_units',
  'aoeRadius_units', 'effectMagnitude', 'effectDuration_ms',
  'maxDurationSec', 'xpToUnlock',
]);

// Fields that are structural and cannot be overlaid
const OVERLAY_BLOCKED_FIELDS: ReadonlySet<string> = new Set([
  'id', 'type', 'status', 'name', 'displayName', 'abilityType',
  'effectType', 'projectile', 'winCondition', 'modeCompatibility',
  'availableAbilities', 'isFree', 'defaultSkinId', 'passiveType',
  'passiveConfig', 'spawnPoints',
]);

// ---------------------------------------------------------------------------
// ContentCatalogService
// ---------------------------------------------------------------------------

interface BundledCatalog {
  catalog_version: number;
  generated: string;
  records: CatalogRecord[];
}

export class ContentCatalogService implements IContentCatalog {
  private readonly records = new Map<string, CatalogRecord>();
  private overlayVersion = 0;

  private constructor() {}

  /**
   * Loads the catalog from a JSON file path.
   * Throws on missing required records (fail-fast at server startup).
   */
  static init(catalogPath: string, logger?: ILogger): ContentCatalogService {
    const raw = fs.readFileSync(catalogPath, 'utf8');
    const bundle: BundledCatalog = JSON.parse(raw);

    const service = new ContentCatalogService();

    for (const record of bundle.records) {
      if (!record.id || !record.type) {
        throw new Error(`CATALOG_INVALID_RECORD: missing id or type on record ${JSON.stringify(record)}`);
      }
      if (!/^[a-z_]+:[a-z0-9_-]+$/.test(record.id)) {
        throw new Error(`CATALOG_INVALID_ID: "${record.id}" does not match {type}:{slug} format`);
      }
      if (service.records.has(record.id)) {
        throw new Error(`CATALOG_DUPLICATE_ID: "${record.id}" appears more than once`);
      }
      service.records.set(record.id, record);
    }

    // Validate required record counts
    const counts = {
      character: service.getAll('character').length,
      ability: service.getAll('ability').length,
      mode: service.getAll('mode').length,
      map: service.getAll('map').length,
    };

    if (counts.character < 8)  throw new Error(`CATALOG_MISSING_REQUIRED_RECORDS: need ≥8 characters, got ${counts.character}`);
    if (counts.ability < 18)   throw new Error(`CATALOG_MISSING_REQUIRED_RECORDS: need ≥18 abilities, got ${counts.ability}`);
    if (counts.mode < 3)       throw new Error(`CATALOG_MISSING_REQUIRED_RECORDS: need ≥3 modes, got ${counts.mode}`);

    logger?.info('CATALOG_LOADED', { ...counts, catalogVersion: bundle.catalog_version });

    return service;
  }

  /**
   * In-memory-only constructor for tests. Pass records directly.
   */
  static fromRecords(records: CatalogRecord[]): ContentCatalogService {
    const service = new ContentCatalogService();
    for (const r of records) service.records.set(r.id, r);
    return service;
  }

  get<T extends CatalogRecord = CatalogRecord>(id: string): T | null {
    return (this.records.get(id) as T) ?? null;
  }

  getAll<T extends CatalogRecord = CatalogRecord>(type: ContentType): T[] {
    const result: T[] = [];
    for (const record of this.records.values()) {
      if (record.type === type) result.push(record as T);
    }
    return result;
  }

  applyOverlay(map: Record<string, number | string>): void {
    for (const [key, value] of Object.entries(map)) {
      const dotIdx = key.indexOf('.');
      if (dotIdx < 0) continue;

      const recordId = key.slice(0, dotIdx);
      const field = key.slice(dotIdx + 1);

      if (OVERLAY_BLOCKED_FIELDS.has(field)) continue;
      if (!OVERLAY_ALLOWED_FIELDS.has(field)) continue;

      const record = this.records.get(recordId);
      if (!record) continue;

      // Only patch if types match
      if (typeof record[field] === typeof value) {
        record[field] = value;
      }
    }
  }

  /** Total record count — useful in tests. */
  get size(): number {
    return this.records.size;
  }
}

// ---------------------------------------------------------------------------
// Default catalog path helper
// ---------------------------------------------------------------------------

export function defaultCatalogPath(): string {
  return path.join(__dirname, '../data/content-catalog.json');
}
