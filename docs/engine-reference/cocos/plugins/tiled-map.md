# Cocos Creator — TiledMap Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

## Why This File Exists

The built-in `TiledMap` component is the standard way to render tile
maps in Cocos Creator 2D games. It is also the **canonical grid
representation for 2D pathfinding** (since Cocos has no built-in 2D
navmesh — see `../modules/navigation.md`).

The TiledMap component is bundled with the engine; no installation is
required.

## Authoring

1. Create maps in the [Tiled editor](https://www.mapeditor.org/) (`.tmx` / `.tsx`)
2. Drop the `.tmx` and any referenced tileset images into `assets/tiled/`
3. Cocos auto-imports and creates a `TiledMapAsset`
4. Add a `TiledMap` component to a scene node, assign the asset

## Component API

```typescript
import { TiledMap, TiledLayer, GID, TMXObject, UITransform } from 'cc';

const map = this.getComponent(TiledMap)!;

// Get a tile layer by name
const groundLayer = map.getLayer('ground') as TiledLayer;

// Get a tile GID at tile coords
const gid: GID = groundLayer.getTileGIDAt(5, 10);

// Read object layer (rectangles, polygons, etc.)
const objects = map.getObjectGroup('spawns');
const playerSpawn: TMXObject = objects.getObject('player_start');
```

## Tile Coordinates vs World Coordinates

TiledMap uses **tile coordinates** (integer cell indices), not world
coordinates. Convert with the map's tile size:

```typescript
const tileSize = map.getTileSize();   // Size in pixels
const worldPos = new Vec3(tileX * tileSize.width, tileY * tileSize.height, 0);
```

## Layer Types

| Layer | API | Notes |
|-------|-----|-------|
| `TiledLayer` (tile layer) | `getTileGIDAt(x, y)` | Grid of tile GIDs |
| `TiledObjectGroup` | `getObject(name)` | Spawn points, regions, polygons |
| `TiledImageLayer` | `getTexture()` | Background image |

## Performance Notes
- Map is rendered as a single batched mesh — adding/removing tiles at
  runtime is expensive
- For maps > 4096×4096 tiles, split into chunks
- Use `TiledLayer.setCullingEnabled(true)` (default) to skip off-screen tiles
- Isometric / hexagonal maps are supported but have higher per-frame cost

## 2D Pathfinding on a TiledMap

Cocos has no built-in 2D NavMesh. The standard pattern:

1. Read the tile layer's GID grid into a 2D array at scene load
2. Mark non-walkable tiles (collider layers, slopes) as obstacles
3. Use a community A* library (e.g. `@cocos/a-star` or a hand-rolled
   implementation) to compute paths
4. Convert path tile coords back to world coords to move the agent

```typescript
// Sketch — use a community A* library
const walkable = groundLayer.getGIDs().map(row =>
    row.map(gid => !isColliderGid(gid))
);
const path = aStar.findPath(walkable, startTile, endTile);
// path: Array<{x: number, y: number}>
```

## Common Mistakes
- Modifying tile GIDs at runtime without re-batching — visual tearing
  and 1-frame desync
- Using object layer "polygon" shapes for collision detection — these
  are not colliders; use them for area detection only
- Re-importing `.tmx` over a file that has been edited in both Tiled
  and Cocos — Tiled wins; manual edits to the `.tsx` are lost
- Treating GID `0` as "transparent tile" — it means "no tile"; check
  for `0` before reading tile properties
- Forgetting to set the map's `fillMode` — default is `NONE` and the
  map renders at native size, not scaling to fit the camera

## Verified Sources
- Tiled editor: <https://www.mapeditor.org/>
- Cocos TiledMap API: <https://docs.cocos.com/creator/3.8/manual/en/editor/components/tiledmap.html>
