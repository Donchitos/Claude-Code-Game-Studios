---
paths:
  - "**/*.json"
  - "**/*.yaml"
  - "**/Data/**"
---

# Data File Rules

- All data must be data-driven configuration — gameplay/behavior values live here, not in C++ or Blueprint literals
- All JSON/YAML files must be syntactically valid — broken data files block the entire build/cook pipeline
- Every data file must have a documented schema (JSON Schema, or a `UScriptStruct` / `UDataAsset` row struct documented in the corresponding ADR)
- File naming: lowercase with underscores, following `[system]_[name].json` / `[system]_[name].yaml` — no uppercase, no spaces
- Use consistent key naming: `camelCase` for keys within JSON/YAML files
- Numeric values must include a companion comment / doc explaining what the numbers mean and their unit
- No orphaned data entries — every entry must be referenced by code or another data file
- Version data files when making breaking schema changes; include sensible defaults for all optional fields
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** naming and structure (`combat_enemies.json`, matches a `FCombatEnemyRow` schema):

```json
{
  "goblin": {
    "baseHealth": 50,
    "baseDamage": 8,
    "moveSpeed": 3.5,
    "lootTable": "loot_goblin_common"
  },
  "goblin_chief": {
    "baseHealth": 150,
    "baseDamage": 20,
    "moveSpeed": 2.8,
    "lootTable": "loot_goblin_rare"
  }
}
```

**Incorrect** (`EnemyData.json`):

```json
{
  "Goblin": { "hp": 50 }
}
```

Violations: uppercase filename, uppercase key, no `[system]_[name]` pattern, missing required fields (`baseDamage` / `moveSpeed` / `lootTable`), abbreviated key (`hp`).
