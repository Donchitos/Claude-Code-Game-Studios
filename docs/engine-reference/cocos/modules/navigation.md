# Cocos Creator Navigation — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.x — Built-in navigation added
- **Recast/Detour** integration — native navmesh generation for 3D
- **NavMeshAgent** component — runtime pathfinding on baked navmesh
- **NavMeshObstacle** — dynamic obstacles that affect agent paths
- **2D navigation**: no built-in pathfinding; community solutions (A* on tilemap) or `@cocos/creator-recast` plugin

### v3.8 — Improvements
- NavMesh generation options exposed in editor (cell size, agent radius, slope limit)
- `NavMeshAgent.avoidanceQuality` API for crowd avoidance tuning

## Current API Patterns

### Baking a NavMesh
1. Mark static colliders as "Navigation Static" (red overlay in editor)
2. Open **Project Settings → Navigation** (导航)
3. Configure: agent radius, agent height, max slope, step height
4. Click **Bake** — generates `NavMesh.asset` in the scene
5. Visualize the result with the navigation gizmo

### NavMeshAgent (3D runtime)
```typescript
import { _decorator, Component, NavMeshAgent, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('EnemyAI')
export class EnemyAI extends Component {
    @property({ type: NavMeshAgent })
    public agent: NavMeshAgent | null = null;

    @property({ type: Vec3 })
    public target: Vec3 = new Vec3();

    update(dt: number) {
        if (this.agent && !this.agent.isStopped) {
            this.agent.destination = this.target;
        }
    }
}
```

### NavMeshObstacle (dynamic)
```typescript
const obstacle = this.getComponent(NavMeshObstacle)!;
obstacle.carve = true;        // Permanently carve a hole in navmesh
obstacle.shape = NavMeshObstacle.Shape.BOX;
obstacle.size = new Vec3(2, 2, 2);
```

### 2D Navigation (community approach)
For 2D games, no built-in pathfinding. Recommended:
- **A\*** algorithm implementation (custom or community package)
- Use the **Tilemap** as the grid representation
- Cache the pathfinding grid; rebuild only when obstacles change

```typescript
// Sketch only — use a community package like @cocos/a-star
const path = astar.findPath(grid, startCell, endCell);
```

## Common Mistakes
- Forgetting to bake the NavMesh after editing geometry — `NavMeshAgent.destination` does nothing
- Setting `agent.destination` every frame — path recalculation cost; throttle to once per 0.5s
- Not marking obstacles as static — dynamic obstacles need `NavMeshObstacle` component
- Using 2D pathfinding on a NavMesh designed for 3D — wrong coordinate space
- Expecting crowd avoidance to handle 100+ agents — performance cliff at scale
- Not configuring `agent.radius` / `agent.height` per agent type — agents get stuck in tight spaces
