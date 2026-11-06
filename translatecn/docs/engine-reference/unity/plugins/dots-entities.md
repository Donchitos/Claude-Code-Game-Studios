# Unity 6.3 — DOTS / Entities (ECS)
# Unity 6.3 — DOTS / Entities（ECS）

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Status:** Production-Ready (Entities 1.3+, Unity 6.3 LTS)
**状态：** 生产就绪（Entities 1.3+，Unity 6.3 LTS）
**Package:** `com.unity.entities` (Package Manager)
**包：** `com.unity.entities`（Package Manager）

---

## Overview
## 概述

**DOTS (Data-Oriented Technology Stack)** is Unity's high-performance ECS (Entity Component System)
framework. It's designed for games with massive scale (1000s-10,000s of entities).

**DOTS（面向数据的技术栈，Data-Oriented Technology Stack）** 是 Unity 的高性能 ECS（实体组件系统，Entity Component System）框架。它专为超大规模的游戏（数千至数万个实体）而设计。

**Use DOTS for:**
- RTS games (1000s of units)
- Simulations (crowds, traffic, physics)
- Procedural content generation
- Performance-critical systems

**使用 DOTS 的场景：**
- RTS 游戏（数千个单位）
- 模拟（人群、交通、物理）
- 程序化内容生成
- 性能关键的系统

**DON'T use DOTS for:**
- Small games (overhead not worth it)
- Gameplay requiring frequent structural changes
- Heavy use of UnityEngine APIs (MonoBehaviour is easier)

**不要使用 DOTS 的场景：**
- 小型游戏（开销不值得）
- 需要频繁进行结构性变更的玩法
- 大量使用 UnityEngine API（MonoBehaviour 更简单）

**⚠️ Knowledge Gap:** Entities 1.0+ (Unity 6) is a complete rewrite from 0.x.
Many tutorials for Entities 0.x are now outdated.

**⚠️ 知识盲区：** Entities 1.0+（Unity 6）相比 0.x 是一次完全重写。
许多针对 Entities 0.x 的教程现已过时。

---

## Installation
## 安装

### Install via Package Manager
### 通过 Package Manager 安装

1. `Window > Package Manager`
2. Unity Registry > Search "Entities"
3. Install:
   - `Entities` (ECS core)
   - `Burst` (LLVM compiler)
   - `Jobs` (auto-installed)
   - `Mathematics` (SIMD math)

1. `Window > Package Manager`
2. Unity Registry > 搜索 "Entities"
3. 安装：
   - `Entities`（ECS 核心）
   - `Burst`（LLVM 编译器）
   - `Jobs`（自动安装）
   - `Mathematics`（SIMD 数学）

---

## Core Concepts
## 核心概念

### 1. **Entity**
### 1. **实体（Entity）**
- Lightweight ID (int)
- No behavior, just an identifier

- 轻量级 ID（int）
- 没有行为，只是一个标识符

### 2. **Component**
### 2. **组件（Component）**
- Data only (no methods)
- Struct implementing `IComponentData`

- 仅含数据（无方法）
- 实现 `IComponentData` 的结构体（struct）

### 3. **System**
### 3. **系统（System）**
- Logic that operates on components
- Struct implementing `ISystem`

- 对组件进行操作的逻辑
- 实现 `ISystem` 的结构体

### 4. **Archetype**
### 4. **原型（Archetype）**
- Unique combination of component types
- Entities with same components share archetype

- 组件类型的唯一组合
- 拥有相同组件的实体共享同一原型

---

## Basic ECS Pattern
## 基本 ECS 模式

### Define Component
### 定义组件

```csharp
using Unity.Entities;
using Unity.Mathematics;

// ✅ Component: Data only, no methods
public struct Position : IComponentData {
    public float3 Value;
}

public struct Velocity : IComponentData {
    public float3 Value;
}
```

---

### Define System
### 定义系统

```csharp
using Unity.Entities;
using Unity.Burst;

// ✅ System: Logic that processes entities
[BurstCompile]
public partial struct MovementSystem : ISystem {
    [BurstCompile]
    public void OnUpdate(ref SystemState state) {
        float deltaTime = SystemAPI.Time.DeltaTime;

        // Query all entities with Position + Velocity
        foreach (var (transform, velocity) in
            SystemAPI.Query<RefRW<Position>, RefRO<Velocity>>()) {

            transform.ValueRW.Value += velocity.ValueRO.Value * deltaTime;
        }
    }
}
```

---

### Create Entities
### 创建实体

```csharp
using Unity.Entities;
using Unity.Mathematics;

public partial class EntitySpawner : SystemBase {
    protected override void OnUpdate() {
        var em = EntityManager;

        // Create entity
        Entity entity = em.CreateEntity();

        // Add components
        em.AddComponentData(entity, new Position { Value = float3.zero });
        em.AddComponentData(entity, new Velocity { Value = new float3(1, 0, 0) });
    }
}
```

---

## Hybrid ECS (MonoBehaviour + ECS)
## 混合 ECS（MonoBehaviour + ECS）

### Baker (Convert GameObject to Entity)
### Baker（将 GameObject 转换为实体）

```csharp
using Unity.Entities;
using UnityEngine;

public class PlayerAuthoring : MonoBehaviour {
    public float speed;
}

public class PlayerBaker : Baker<PlayerAuthoring> {
    public override void Bake(PlayerAuthoring authoring) {
        var entity = GetEntity(TransformUsageFlags.Dynamic);

        AddComponent(entity, new Position { Value = authoring.transform.position });
        AddComponent(entity, new Velocity { Value = new float3(authoring.speed, 0, 0) });
    }
}
```

**How it works:**
1. Add `PlayerAuthoring` to GameObject in editor
2. Baker automatically converts to Entity at runtime
3. Entity has Position + Velocity components

**工作原理：**
1. 在编辑器中向 GameObject 添加 `PlayerAuthoring`
2. Baker 在运行时自动转换为实体
3. 该实体拥有 Position + Velocity 组件

---

## Queries
## 查询

### Query All Entities with Components
### 查询所有拥有指定组件的实体

```csharp
foreach (var (position, velocity) in
    SystemAPI.Query<RefRW<Position>, RefRO<Velocity>>()) {

    position.ValueRW.Value += velocity.ValueRO.Value * deltaTime;
}
```

---

### Query with Entity
### 带实体的查询

```csharp
foreach (var (position, velocity, entity) in
    SystemAPI.Query<RefRW<Position>, RefRO<Velocity>>().WithEntityAccess()) {

    // Access entity ID
    Debug.Log($"Entity: {entity}");
}
```

---

### Query with Filters
### 带筛选条件的查询

```csharp
// Only entities with "Enemy" tag
foreach (var position in
    SystemAPI.Query<RefRW<Position>>().WithAll<EnemyTag>()) {
    // Process enemies only
}
```

---

## Jobs (Parallel Execution)
## Job（并行执行）

### IJobEntity (Parallel Foreach)
### IJobEntity（并行 Foreach）

```csharp
using Unity.Entities;
using Unity.Burst;

[BurstCompile]
public partial struct MovementJob : IJobEntity {
    public float DeltaTime;

    // Execute runs in parallel for each entity
    void Execute(ref Position position, in Velocity velocity) {
        position.Value += velocity.Value * DeltaTime;
    }
}

[BurstCompile]
public partial struct MovementSystem : ISystem {
    public void OnUpdate(ref SystemState state) {
        var job = new MovementJob {
            DeltaTime = SystemAPI.Time.DeltaTime
        };
        job.ScheduleParallel(); // Parallel execution
    }
}
```

---

## Burst Compiler (Performance)
## Burst 编译器（性能）

### Enable Burst
### 启用 Burst

```csharp
using Unity.Burst;

[BurstCompile] // 10-100x faster than regular C#
public partial struct MySystem : ISystem {
    [BurstCompile]
    public void OnUpdate(ref SystemState state) {
        // Burst-compiled code
    }
}
```

**Burst Restrictions:**
- No managed references (classes, strings, etc.)
- Only blittable types (structs, primitives, Unity.Mathematics types)
- No exceptions

**Burst 限制：**
- 不能使用托管引用（类、字符串等）
- 仅支持可直接复制类型（blittable 类型：结构体、基元类型、Unity.Mathematics 类型）
- 不支持异常

---

## Entity Command Buffers (Structural Changes)
## 实体命令缓冲区（Entity Command Buffers，结构性变更）

### Deferred Structural Changes
### 延迟结构性变更

```csharp
using Unity.Entities;

public partial struct SpawnSystem : ISystem {
    public void OnUpdate(ref SystemState state) {
        var ecb = new EntityCommandBuffer(Allocator.Temp);

        // Defer entity creation (don't modify during iteration)
        foreach (var spawner in SystemAPI.Query<Spawner>()) {
            Entity newEntity = ecb.CreateEntity();
            ecb.AddComponent(newEntity, new Position { Value = spawner.SpawnPos });
        }

        ecb.Playback(state.EntityManager); // Apply changes
        ecb.Dispose();
    }
}
```

---

## Dynamic Buffers (Array-Like Components)
## 动态缓冲区（Dynamic Buffers，类数组组件）

### Define Dynamic Buffer
### 定义动态缓冲区

```csharp
public struct PathWaypoint : IBufferElementData {
    public float3 Position;
}
```

### Use Dynamic Buffer
### 使用动态缓冲区

```csharp
// Add buffer to entity
var buffer = EntityManager.AddBuffer<PathWaypoint>(entity);
buffer.Add(new PathWaypoint { Position = new float3(0, 0, 0) });
buffer.Add(new PathWaypoint { Position = new float3(10, 0, 0) });

// Query buffer
foreach (var buffer in SystemAPI.Query<DynamicBuffer<PathWaypoint>>()) {
    foreach (var waypoint in buffer) {
        Debug.Log(waypoint.Position);
    }
}
```

---

## Tags (Zero-Size Components)
## 标签（Tags，零尺寸组件）

### Define Tag
### 定义标签

```csharp
public struct EnemyTag : IComponentData { } // Empty component = tag
```

### Use Tag for Filtering
### 使用标签进行筛选

```csharp
// Only process entities with EnemyTag
foreach (var position in
    SystemAPI.Query<RefRW<Position>>().WithAll<EnemyTag>()) {
    // Enemy-specific logic
}
```

---

## System Ordering
## 系统排序

### Explicit Ordering
### 显式排序

```csharp
[UpdateBefore(typeof(PhysicsSystem))]
public partial struct InputSystem : ISystem { }

[UpdateAfter(typeof(PhysicsSystem))]
public partial struct RenderSystem : ISystem { }
```

---

## Performance Patterns
## 性能模式

### Chunk Iteration (Maximum Performance)
### 块（Chunk）迭代（最高性能）

```csharp
public void OnUpdate(ref SystemState state) {
    var query = SystemAPI.QueryBuilder().WithAll<Position, Velocity>().Build();

    var chunks = query.ToArchetypeChunkArray(Allocator.Temp);
    var positionType = state.GetComponentTypeHandle<Position>();
    var velocityType = state.GetComponentTypeHandle<Velocity>(true); // Read-only

    foreach (var chunk in chunks) {
        var positions = chunk.GetNativeArray(ref positionType);
        var velocities = chunk.GetNativeArray(ref velocityType);

        for (int i = 0; i < chunk.Count; i++) {
            positions[i] = new Position {
                Value = positions[i].Value + velocities[i].Value * deltaTime
            };
        }
    }

    chunks.Dispose();
}
```

---

## Migration from MonoBehaviour
## 从 MonoBehaviour 迁移

```csharp
// ❌ OLD: MonoBehaviour (OOP)
public class Enemy : MonoBehaviour {
    public float speed;
    void Update() {
        transform.position += Vector3.forward * speed * Time.deltaTime;
    }
}

// ✅ NEW: DOTS (ECS)
public struct EnemyData : IComponentData {
    public float Speed;
}

[BurstCompile]
public partial struct EnemyMovementSystem : ISystem {
    public void OnUpdate(ref SystemState state) {
        float dt = SystemAPI.Time.DeltaTime;
        foreach (var (transform, enemy) in
            SystemAPI.Query<RefRW<LocalTransform>, RefRO<EnemyData>>()) {
            transform.ValueRW.Position += new float3(0, 0, enemy.ValueRO.Speed * dt);
        }
    }
}
```

---

## Debugging
## 调试

### Entities Hierarchy Window
### Entities 层级窗口

`Window > Entities > Hierarchy`

`Window > Entities > Hierarchy`

- Shows all entities and their components
- Filter by archetype, component type

- 显示所有实体及其组件
- 按原型、组件类型筛选

### Entities Profiler
### Entities 性能分析器

`Window > Analysis > Profiler > Entities`

`Window > Analysis > Profiler > Entities`

- System execution times
- Memory usage per archetype

- 系统执行时间
- 每个原型的内存占用

---

## Sources
## 来源
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.burst@1.8/manual/index.html
- https://learn.unity.com/tutorial/entity-component-system
