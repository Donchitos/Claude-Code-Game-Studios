# Unreal Engine 5.8 — PCG (Procedural Content Generation)

**Last verified:** 2026-08-16
**Status:** Production-Ready (as of UE 5.7)
**Plugin:** `PCG` (built-in, enable in Plugins)

---

## Overview

**Procedural Content Generation (PCG)** is Unreal's node-based framework for generating
procedural content at massive scale. It's designed for populating large open worlds with
foliage, rocks, props, buildings, and other environmental detail.

**Use PCG for:**
- Procedural foliage placement (trees, grass, rocks)
- Biome-based environment generation
- Road/path generation
- Building/structure placement
- World detail population (props, clutter)

**DON'T use PCG for:**
- Gameplay logic (use Blueprints/C++)
- One-off manual placement (use editor tools)

**⚠️ Note:** PCG was experimental in UE 5.0-5.6, became production-ready in UE 5.7.

---

## What's New in UE 5.8

- **Manual editing**: non-destructive editing of PCG output via selection and exclusion — hand-tweak generated content without breaking regeneration
- **Complex attributes**: arrays, structures, sets, and maps supported as metadata
- **Embedded subgraphs**: custom subgraphs can be stored inside PCG graphs
- **Graph Parameters Editor**: parameter categorization and hierarchy tools
- **GPU runtime performance**: now within the same performance range as the landscape GPU grass system
- **Procedural Vegetation Editor (Experimental)**: in-engine vegetation creation with growth, grafting, and trimming

---

## Core Concepts

### 1. **PCG Graph**
- Node-based graph (similar to Material Editor)
- Defines generation rules

### 2. **PCG Component**
- Placed in level, executes PCG Graph
- Generates content in defined volume

### 3. **PCG Data**
- Point data (positions, rotations, scales)
- Spline data (paths, roads, rivers)
- Volume data (density, biome masks)

### 4. **Nodes**
- **Samplers**: Generate points (Grid, Poisson, Surface)
- **Filters**: Remove points based on rules (Density, Tag, Bounds)
- **Modifiers**: Transform points (Offset, Rotate, Scale)
- **Spawners**: Instantiate meshes/actors at points

---

## Setup

### 1. Enable Plugin

`Edit > Plugins > PCG > Enabled > Restart`

### 2. Create PCG Volume

1. Place Actors > Volumes > PCG Volume
2. Scale volume to desired generation area

### 3. Create PCG Graph

1. Content Browser > PCG > PCG Graph
2. Open PCG Graph Editor

---

## Basic Workflow

### Example: Forest Generation

#### 1. Create PCG Graph

**Node Setup:**
```
Input (Volume)
  ↓
Surface Sampler (sample volume surface, points per m²: 0.5)
  ↓
Density Filter (use texture mask or noise)
  ↓
Static Mesh Spawner (tree meshes)
  ↓
Output
```

#### 2. Assign Graph to Volume

1. Select PCG Volume
2. Details Panel > PCG Component > Graph = Your PCG Graph
3. Click "Generate" button

---

## Key Node Types

### Samplers (Point Generation)

#### Grid Sampler
- Regular grid of points
- Configure:
  - **Grid Size**: Distance between points
  - **Offset**: Random offset per point

#### Poisson Disk Sampler
- Random points with minimum distance
- Configure:
  - **Points Per m²**: Density
  - **Min Distance**: Spacing between points

#### Surface Sampler
- Points on mesh surfaces or landscape
- Configure:
  - **Points Per m²**: Density
  - **Surface Only**: Only surface, not volume

---

### Filters (Point Removal)

#### Density Filter
- Remove points based on density value
- Input: Texture or noise
- Use for: Biome masks, clearings, paths

#### Tag Filter
- Filter points by tag
- Use for: Conditional spawning

#### Bounds Filter
- Keep only points within bounds
- Use for: Limiting generation to specific areas

---

### Modifiers (Point Transformation)

#### Rotate
- Randomize point rotation
- Configure:
  - **Min/Max Rotation**: Rotation range per axis

#### Scale
- Randomize point scale
- Configure:
  - **Min/Max Scale**: Scale range

#### Project to Ground
- Snap points to landscape surface

---

### Spawners (Mesh/Actor Instantiation)

#### Static Mesh Spawner
- Spawn static meshes at points
- Configure:
  - **Mesh List**: Array of meshes (random selection)
  - **Culling Distance**: LOD/culling settings

#### Actor Spawner
- Spawn Blueprint actors at points
- Use for: Gameplay actors, interactive objects

---

## Data Sources

### Landscape
- Use landscape as input for sampling
- Automatically projects to landscape height

### Splines
- Generate content along splines (roads, rivers, paths)
- Example: Trees along path

### Textures
- Use textures as density masks
- Paint biomes, clearings, areas

---

## Biome Example (Mixed Forest)

### Graph Setup

```
Input (Landscape)
  ↓
Surface Sampler (density: 1.0)
  ↓
┌─────────────────┬─────────────────┐
│ Tree Biome      │ Rock Biome      │
│ (density > 0.5) │ (density < 0.5) │
├─────────────────┼─────────────────┤
│ Tree Spawner    │ Rock Spawner    │
└─────────────────┴─────────────────┘
  ↓
Merge
  ↓
Output
```

---

## Spline-Based Generation (Road with Trees)

### 1. Create PCG Graph

```
Spline Input
  ↓
Spline Sampler (sample along spline)
  ↓
Offset (offset from spline path)
  ↓
Tree Spawner
  ↓
Output
```

### 2. Add Spline Component to PCG Volume

1. PCG Volume > Add Component > Spline
2. Draw spline path
3. PCG Graph reads spline data

---

## Runtime Generation

### Trigger Generation from C++

```cpp
#include "PCGComponent.h"

UPCGComponent* PCGComp = /* Get PCG Component */;
PCGComp->Generate(); // Execute PCG graph
```

### Stream Generation (Large Worlds)

- PCG automatically streams with World Partition
- Only generates content in loaded cells

---

## Performance

### Optimization Tips

- Use **culling distance** on spawned meshes (LOD)
- Limit **density** (fewer points = better performance)
- Use **Hierarchical Instanced Static Meshes (HISM)** for repeated meshes
- Enable **streaming** for large worlds

### Debug Performance

```cpp
// Console commands:
// pcg.graph.debug 1 - Show PCG debug info
// stat pcg - Show PCG performance stats
```

---

## Common Patterns

### Forest with Clearings

```
Surface Sampler
  ↓
Density Filter (noise texture with clearings)
  ↓
Tree Spawner (pine, oak, birch)
```

---

### Rocks on Steep Slopes

```
Landscape Input
  ↓
Surface Sampler
  ↓
Slope Filter (angle > 30°)
  ↓
Rock Spawner
```

---

### Props Along Road

```
Spline Input (road spline)
  ↓
Spline Sampler
  ↓
Offset (side of road)
  ↓
Street Light Spawner
```

---

## Debugging

### PCG Debug Visualization

```cpp
// Console commands:
// pcg.debug.display 1 - Show points and generation bounds
// pcg.debug.colormode points - Color-code points
```

### Graph Debugging

- PCG Graph Editor > Debug > Show Debug Points
- Visualize points at each node in the graph

---

## Migration from UE 5.6 (Experimental) to 5.7 (Production)

### API Changes

```cpp
// ❌ OLD (5.6 experimental API):
// Some nodes renamed, API unstable

// ✅ NEW (5.7 production API):
// Stable node types, documented API
```

**Migration:** Rebuild PCG graphs using stable 5.7 nodes. Test thoroughly.

---

## Limitations

- **Not for gameplay logic**: Use Blueprints/C++ for game rules
- **Large graphs can be slow**: Optimize with filters and density reduction
- **Runtime generation overhead**: Pre-generate when possible

---

## Sources
- https://docs.unrealengine.com/5.8/en-US/procedural-content-generation-in-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/pcg-quick-start-in-unreal-engine/
- UE 5.7 Release Notes (PCG Production-Ready announcement)
