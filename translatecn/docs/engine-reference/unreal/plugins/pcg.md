# Unreal Engine 5.8 — PCG (Procedural Content Generation)
# Unreal Engine 5.8 — PCG（程序化内容生成）

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Status:** Production-Ready (as of UE 5.7)
**Plugin:** `PCG` (built-in, enable in Plugins)

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**状态：** 生产就绪（自 UE 5.7 起）
**插件：** `PCG`（内置，在 Plugins 中启用）

> **UE 5.8 changes:** Non-destructive manual editing of PCG data (selection,
> exclusion, modification, restore; a Data Overrides window), complex metadata
> attributes (arrays, structs, sets, maps), embedded subgraphs stored inside a
> graph, a graph parameters hierarchy editor, and GPU runtime scatter "within
> the same performance range as the landscape GPU grass system". New nodes
> include metadata array operations, Align Points, Apply Spline to Component
> and Teleport Actors and Components. `UPCGComponent` exposes a
> `SourceDataContainer` through the execution source interface. Source: UE 5.8
> release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** PCG 数据的非破坏性手动编辑（选择、排除、修改、恢复；Data Overrides 窗口）、复杂元数据属性（数组、结构体、集合、映射）、存储在图表内部的内嵌子图、图表参数层级编辑器，以及 GPU 运行时散布"性能范围与场景观 GPU 草丛系统相当"。新增节点包括元数据数组操作、Align Points、Apply Spline to Component 和 Teleport Actors and Components。`UPCGComponent` 通过执行源接口暴露 `SourceDataContainer`。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

**Procedural Content Generation (PCG)** is Unreal's node-based framework for generating
procedural content at massive scale. It's designed for populating large open worlds with
foliage, rocks, props, buildings, and other environmental detail.

**程序化内容生成（PCG）** 是 Unreal 用于大规模生成程序化内容的基于节点的框架。它旨在为大型开放世界填充植被、岩石、道具、建筑及其他环境细节。

**Use PCG for:**
- Procedural foliage placement (trees, grass, rocks)
- Biome-based environment generation
- Road/path generation
- Building/structure placement
- World detail population (props, clutter)

**使用 PCG 的场景：**
- 程序化植被放置（树木、草、岩石）
- 基于生物群系的环境生成
- 道路/路径生成
- 建筑/结构放置
- 世界细节填充（道具、杂物）

**DON'T use PCG for:**
- Gameplay logic (use Blueprints/C++)
- One-off manual placement (use editor tools)

**不要使用 PCG 的场景：**
- 玩法逻辑（请使用蓝图/C++）
- 一次性手动放置（请使用编辑器工具）

**⚠️ Note:** PCG was experimental in UE 5.0-5.6, became production-ready in UE 5.7.

**⚠️ 注意：** PCG 在 UE 5.0-5.6 中为实验性，在 UE 5.7 中达到生产就绪。

---

## Core Concepts
## 核心概念

### 1. **PCG Graph**
- Node-based graph (similar to Material Editor)
- Defines generation rules

### 1. **PCG Graph**
- 基于节点的图（类似材质编辑器）
- 定义生成规则

### 2. **PCG Component**
- Placed in level, executes PCG Graph
- Generates content in defined volume

### 2. **PCG Component**
- 放置于关卡中，执行 PCG Graph
- 在定义的体积内生成内容

### 3. **PCG Data**
- Point data (positions, rotations, scales)
- Spline data (paths, roads, rivers)
- Volume data (density, biome masks)

### 3. **PCG Data**
- 点数据（位置、旋转、缩放）
- 样条数据（路径、道路、河流）
- 体积数据（密度、生物群系遮罩）

### 4. **Nodes**
- **Samplers**: Generate points (Grid, Poisson, Surface)
- **Filters**: Remove points based on rules (Density, Tag, Bounds)
- **Modifiers**: Transform points (Offset, Rotate, Scale)
- **Spawners**: Instantiate meshes/actors at points

### 4. **节点**
- **采样器（Samplers）**：生成点（Grid、Poisson、Surface）
- **过滤器（Filters）**：按规则移除点（Density、Tag、Bounds）
- **修饰器（Modifiers）**：变换点（Offset、Rotate、Scale）
- **生成器（Spawners）**：在点上实例化网格/Actor

---

## Setup
## 设置

### 1. Enable Plugin
### 1. 启用插件

`Edit > Plugins > PCG > Enabled > Restart`

`Edit > Plugins > PCG > Enabled > Restart`

### 2. Create PCG Volume
### 2. 创建 PCG Volume

1. Place Actors > Volumes > PCG Volume
2. Scale volume to desired generation area

1. Place Actors > Volumes > PCG Volume
2. 将体积缩放到期望的生成区域

### 3. Create PCG Graph
### 3. 创建 PCG Graph

1. Content Browser > PCG > PCG Graph
2. Open PCG Graph Editor

1. Content Browser > PCG > PCG Graph
2. 打开 PCG Graph 编辑器

---

## Basic Workflow
## 基本工作流

### Example: Forest Generation
### 示例：森林生成

#### 1. Create PCG Graph
#### 1. 创建 PCG Graph

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

**节点设置：**
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
#### 2. 将图表分配到体积

1. Select PCG Volume
2. Details Panel > PCG Component > Graph = Your PCG Graph
3. Click "Generate" button

1. 选中 PCG Volume
2. Details 面板 > PCG Component > Graph = 你的 PCG Graph
3. 点击"Generate"按钮

---

## Key Node Types
## 关键节点类型

### Samplers (Point Generation)
### 采样器（点生成）

#### Grid Sampler
#### Grid Sampler

- Regular grid of points
- Configure:
  - **Grid Size**: Distance between points
  - **Offset**: Random offset per point

- 规则网格点阵
- 配置：
  - **Grid Size**：点与点之间的距离
  - **Offset**：每个点的随机偏移

#### Poisson Disk Sampler
#### Poisson Disk Sampler

- Random points with minimum distance
- Configure:
  - **Points Per m²**: Density
  - **Min Distance**: Spacing between points

- 带最小间距的随机点
- 配置：
  - **Points Per m²**：密度
  - **Min Distance**：点之间的间距

#### Surface Sampler
#### Surface Sampler

- Points on mesh surfaces or landscape
- Configure:
  - **Points Per m²**: Density
  - **Surface Only**: Only surface, not volume

- 网格表面或场景观上的点
- 配置：
  - **Points Per m²**：密度
  - **Surface Only**：仅表面，不含体积内部

---

### Filters (Point Removal)
### 过滤器（点移除）

#### Density Filter
#### Density Filter

- Remove points based on density value
- Input: Texture or noise
- Use for: Biome masks, clearings, paths

- 根据密度值移除点
- 输入：纹理或噪声
- 用途：生物群系遮罩、空地、路径

#### Tag Filter
#### Tag Filter

- Filter points by tag
- Use for: Conditional spawning

- 按标签过滤点
- 用途：条件生成

#### Bounds Filter
#### Bounds Filter

- Keep only points within bounds
- Use for: Limiting generation to specific areas

- 仅保留边界内的点
- 用途：将生成限制在特定区域

---

### Modifiers (Point Transformation)
### 修饰器（点变换）

#### Rotate
#### Rotate

- Randomize point rotation
- Configure:
  - **Min/Max Rotation**: Rotation range per axis

- 随机化点的旋转
- 配置：
  - **Min/Max Rotation**：各轴的旋转范围

#### Scale
#### Scale

- Randomize point scale
- Configure:
  - **Min/Max Scale**: Scale range

- 随机化点的缩放
- 配置：
  - **Min/Max Scale**：缩放范围

#### Project to Ground
#### Project to Ground

- Snap points to landscape surface

- 将点吸附到场景观表面

---

### Spawners (Mesh/Actor Instantiation)
### 生成器（网格/Actor 实例化）

#### Static Mesh Spawner
#### Static Mesh Spawner

- Spawn static meshes at points
- Configure:
  - **Mesh List**: Array of meshes (random selection)
  - **Culling Distance**: LOD/culling settings

- 在点上生成静态网格
- 配置：
  - **Mesh List**：网格数组（随机选取）
  - **Culling Distance**：LOD/剔除设置

#### Actor Spawner
#### Actor Spawner

- Spawn Blueprint actors at points
- Use for: Gameplay actors, interactive objects

- 在点上生成蓝图 Actor
- 用途：玩法 Actor、可交互对象

---

## Data Sources
## 数据源

### Landscape
- Use landscape as input for sampling
- Automatically projects to landscape height

### 场景观（Landscape）
- 将场景观作为采样输入
- 自动投影到场景观高度

### Splines
- Generate content along splines (roads, rivers, paths)
- Example: Trees along path

### 样条（Splines）
- 沿样条生成内容（道路、河流、路径）
- 示例：沿路径放置树木

### Textures
- Use textures as density masks
- Paint biomes, clearings, areas

### 纹理（Textures）
- 将纹理用作密度遮罩
- 绘制生物群系、空地、区域

---

## Biome Example (Mixed Forest)
## 生物群系示例（混合森林）

### Graph Setup
### 图表设置

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
## 基于样条的生成（道路与树木）

### 1. Create PCG Graph
### 1. 创建 PCG Graph

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
### 2. 向 PCG Volume 添加样条组件

1. PCG Volume > Add Component > Spline
2. Draw spline path
3. PCG Graph reads spline data

1. PCG Volume > Add Component > Spline
2. 绘制样条路径
3. PCG Graph 读取样条数据

---

## Runtime Generation
## 运行时生成

### Trigger Generation from C++
### 从 C++ 触发生成

```cpp
#include "PCGComponent.h"

UPCGComponent* PCGComp = /* Get PCG Component */;
PCGComp->Generate(); // Execute PCG graph
```

### Stream Generation (Large Worlds)
### 流式生成（大型世界）

- PCG automatically streams with World Partition
- Only generates content in loaded cells

- PCG 会随 World Partition 自动流送
- 仅在已加载的单元格中生成内容

---

## Performance
## 性能

### Optimization Tips
### 优化建议

- Use **culling distance** on spawned meshes (LOD)
- Limit **density** (fewer points = better performance)
- Use **Hierarchical Instanced Static Meshes (HISM)** for repeated meshes
- Enable **streaming** for large worlds

- 对生成的网格使用**剔除距离**（LOD）
- 限制**密度**（点越少性能越好）
- 对重复网格使用**层级实例化静态网格（HISM）**
- 为大型世界启用**流送**

### Debug Performance
### 调试性能

```cpp
// Console commands:
// pcg.graph.debug 1 - Show PCG debug info
// stat pcg - Show PCG performance stats
```

---

## Common Patterns
## 常见模式

### Forest with Clearings
### 带空地的森林

```
Surface Sampler
  ↓
Density Filter (noise texture with clearings)
  ↓
Tree Spawner (pine, oak, birch)
```

---

### Rocks on Steep Slopes
### 陡坡上的岩石

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
### 沿道路的道具

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
## 调试

### PCG Debug Visualization
### PCG 调试可视化

```cpp
// Console commands:
// pcg.debug.display 1 - Show points and generation bounds
// pcg.debug.colormode points - Color-code points
```

### Graph Debugging
### 图表调试

- PCG Graph Editor > Debug > Show Debug Points
- Visualize points at each node in the graph

- PCG Graph Editor > Debug > Show Debug Points
- 可视化图表中每个节点处的点

---

## Migration from UE 5.6 (Experimental) to 5.7 (Production)
## 从 UE 5.6（实验性）迁移到 5.7（生产版）

### API Changes
### API 变更

```cpp
// ❌ OLD (5.6 experimental API):
// Some nodes renamed, API unstable

// ✅ NEW (5.7 production API):
// Stable node types, documented API
```

**Migration:** Rebuild PCG graphs using stable 5.7 nodes. Test thoroughly.

**迁移：** 使用稳定的 5.7 节点重建 PCG 图表。请充分测试。

---

## Limitations
## 限制

- **Not for gameplay logic**: Use Blueprints/C++ for game rules
- **Large graphs can be slow**: Optimize with filters and density reduction
- **Runtime generation overhead**: Pre-generate when possible

- **不用于玩法逻辑**：游戏规则请使用蓝图/C++
- **大型图表可能较慢**：通过过滤器和降低密度来优化
- **运行时生成开销**：尽可能预生成

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/procedural-content-generation-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/pcg-quick-start-in-unreal-engine/
- UE 5.7 Release Notes (PCG Production-Ready announcement)

- https://docs.unrealengine.com/5.7/en-US/procedural-content-generation-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/pcg-quick-start-in-unreal-engine/
- UE 5.7 发行说明（PCG 生产就绪公告）
