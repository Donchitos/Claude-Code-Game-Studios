# Web — Navigation Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** neither library ships pathfinding — this is always hand-written or a dependency

---

## Overview

**Neither PixiJS nor Three.js includes navigation.** There is no NavMesh baking,
no `NavigationAgent`, and no built-in pathfinding. Unlike Godot, Unity, and
Unreal, this is entirely your responsibility.

| Need | Approach |
|------|----------|
| Grid / tile movement | A* on the grid — write it yourself |
| Free 2D movement | A* on a navigation grid, then string-pull |
| 3D navmesh | `recast-navigation-js`, or bake offline and load |
| Local avoidance | Steering behaviors or RVO |
| Simple chase AI | Direct steering — no pathfinding needed |

Most 2D games need only grid A*, which is ~100 lines and adds nothing to the
bundle.

---

## A* on a Grid

```ts
interface Node { x: number; y: number; }

function aStar(start: Node, goal: Node, isWalkable: (n: Node) => boolean): Node[] {
  const open = new PriorityQueue<Node>();
  const gScore = new Map<string, number>();
  const cameFrom = new Map<string, Node>();
  // ... standard A*
}
```

### Heuristic must match movement
| Movement | Heuristic |
|----------|-----------|
| 4-directional | Manhattan |
| 8-directional | Octile / diagonal |
| Any-angle | Euclidean |

Using Euclidean with 4-directional movement makes the heuristic inadmissible in
effect and produces visibly odd paths. Match the heuristic to the movement rules.

---

## Performance — The Main-Thread Problem

Pathfinding is CPU-bound and shares the main thread with the game loop. A single
long path search across a large grid will drop frames.

**Mitigations, in order of preference:**

1. **Budget the search.** Cap nodes expanded per frame; resume next frame if unfinished. Most games can tolerate a path arriving 2–3 frames late
2. **Cache aggressively.** Static level geometry means paths between fixed points can be precomputed
3. **Stagger agents.** Never repath every agent on the same frame — spread requests across a rolling window
4. **Hierarchical pathfinding** for large maps: coarse region path first, then refine locally
5. **Web Worker** for heavy 3D navmesh queries. Worth it only when the search genuinely dominates; the postMessage round-trip adds latency and the grid must be transferable

```ts
// Frame-budgeted search
const MAX_NODES_PER_FRAME = 500;
let expanded = 0;
while (open.size > 0 && expanded < MAX_NODES_PER_FRAME) { /* ... */ expanded++; }
```

---

## Path Smoothing

Raw grid A* produces staircase paths. Two standard fixes:

- **String pulling / funnel** — remove intermediate nodes where a straight line between the surrounding nodes is unobstructed
- **Line-of-sight check** — walk the path, skipping any node reachable directly from an earlier one

```ts
function hasLineOfSight(a: Node, b: Node, isWalkable: (n: Node) => boolean): boolean {
  // Bresenham between a and b; false on the first blocked cell
}
```

Without smoothing, agents visibly zigzag along tile boundaries.

---

## Steering and Local Avoidance

Pathfinding gives the route; steering handles moment-to-moment motion.

```ts
// Seek toward the next waypoint
const desired = normalize(sub(waypoint, pos));
const steering = sub(scale(desired, maxSpeed), velocity);
velocity = clampLength(add(velocity, scale(steering, dt)), maxSpeed);
```

For crowds, add separation so agents don't stack. Full RVO is rarely needed
below a few dozen agents — simple separation plus repathing usually suffices.

---

## 3D Navigation

For 3D navmesh needs, `recast-navigation-js` wraps the Recast/Detour library
used across the industry. It is a WASM dependency — load it async and budget
its payload.

Alternative: bake the navmesh offline in Blender or a level tool, export as
geometry or a JSON graph, and run your own A* over it at runtime. Zero runtime
dependency, at the cost of tooling work.

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Frame drops when an agent repaths | Unbudgeted search on the main thread |
| Agents zigzag along tiles | No path smoothing |
| Odd-looking paths | Heuristic doesn't match movement rules |
| Frame spike when a group spawns | All agents pathing on the same frame |
| Agents stack on each other | No separation steering |
| Agent walks through a wall | Path computed against a stale walkability grid |

---

## Sources

- https://github.com/isaac-mason/recast-navigation-js
- https://www.redblobgames.com/pathfinding/a-star/introduction.html
