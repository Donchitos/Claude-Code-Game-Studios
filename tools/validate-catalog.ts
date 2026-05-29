#!/usr/bin/env ts-node
/**
 * Build-time catalog validation script.
 * Run: npx ts-node tools/validate-catalog.ts
 * Exits with code 1 if validation fails.
 */

import * as fs from 'fs';
import * as path from 'path';

const CATALOG_PATH = path.join(__dirname, '../server/src/data/content-catalog.json');

interface CatalogRecord {
  id: string;
  type: string;
  status: string;
  [key: string]: unknown;
}

interface Catalog {
  catalog_version: number;
  records: CatalogRecord[];
}

function validate(): void {
  const errors: string[] = [];

  if (!fs.existsSync(CATALOG_PATH)) {
    console.error(`ERROR: content-catalog.json not found at ${CATALOG_PATH}`);
    process.exit(1);
  }

  let catalog: Catalog;
  try {
    catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
  } catch (e) {
    console.error(`ERROR: Failed to parse content-catalog.json: ${e}`);
    process.exit(1);
  }

  const idSet = new Set<string>();
  const ID_PATTERN = /^[a-z_]+:[a-z0-9_-]+$/;

  for (const record of catalog.records) {
    // Required fields
    if (!record.id) {
      errors.push(`Record missing 'id': ${JSON.stringify(record).slice(0, 80)}`);
      continue;
    }
    if (!record.type) {
      errors.push(`Record "${record.id}" missing 'type'`);
    }
    if (!record.status) {
      errors.push(`Record "${record.id}" missing 'status'`);
    }

    // ID format
    if (!ID_PATTERN.test(record.id)) {
      errors.push(`Record "${record.id}" has invalid ID format (must match {type}:{slug})`);
    }

    // Duplicate check
    if (idSet.has(record.id)) {
      errors.push(`Duplicate ID: "${record.id}"`);
    }
    idSet.add(record.id);
  }

  // Required record counts
  const characters = catalog.records.filter(r => r.type === 'character');
  const abilities = catalog.records.filter(r => r.type === 'ability');
  const modes = catalog.records.filter(r => r.type === 'mode');

  if (characters.length < 8)  errors.push(`Need ≥8 characters, got ${characters.length}`);
  if (abilities.length < 18)  errors.push(`Need ≥18 abilities, got ${abilities.length}`);
  if (modes.length < 3)       errors.push(`Need ≥3 modes, got ${modes.length}`);

  // Active ability cooldown check
  for (const ab of abilities.filter(a => a.abilityType === 'active')) {
    if (typeof ab.cooldownSec !== 'number' || ab.cooldownSec <= 0) {
      errors.push(`Ability "${ab.id}" has invalid cooldownSec: ${ab.cooldownSec}`);
    }
  }

  if (errors.length > 0) {
    console.error('Catalog validation FAILED:');
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  console.log(`✓ Catalog valid: ${catalog.records.length} records (${characters.length} chars, ${abilities.length} abilities, ${modes.length} modes)`);
}

validate();
