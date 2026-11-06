# Unity 6.3 — Physics Module Reference
# Unity 6.3 — 物理模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 physics improvements, solver changes
**知识盲区：** Unity 6 的物理改进、求解器变更

---

## Overview
## 概述

Unity 6.3 uses **PhysX 5.1** (improved from PhysX 4.x in 2022 LTS):
- Better solver stability
- Improved performance
- Enhanced collision detection

Unity 6.3 使用 **PhysX 5.1**（相较 2022 LTS 的 PhysX 4.x 有所改进）：
- 更好的求解器稳定性
- 更高的性能
- 增强的碰撞检测

---

## Key Changes from 2022 LTS
## 相对 2022 LTS 的关键变更

### Default Solver Iterations Increased
### 默认求解器迭代次数已提高
Unity 6 increased default solver iterations for better stability:

Unity 6 提高了默认求解器迭代次数，以获得更好的稳定性：

```csharp
// Default changed from 6 to 8 iterations
Physics.defaultSolverIterations = 8; // Check if relying on old behavior
```

### Enhanced Collision Detection
### 增强的碰撞检测

```csharp
// ✅ Unity 6: Improved Continuous Collision Detection (CCD)
rigidbody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
// Better handling of fast-moving objects
```

---

## Core Physics Components
## 核心物理组件

### Rigidbody
### Rigidbody

```csharp
// ✅ Best practice: Use AddForce, not direct velocity writes
Rigidbody rb = GetComponent<Rigidbody>();
rb.AddForce(Vector3.forward * 10f, ForceMode.Impulse);

// ❌ Avoid: Direct velocity assignment (can cause instability)
rb.velocity = new Vector3(0, 10, 0); // Only use when necessary
```

### Colliders
### 碰撞体（Colliders）

```csharp
// Primitive colliders: Box, Sphere, Capsule (cheapest)
// Mesh colliders: Expensive, use only for static geometry

// ✅ Compound colliders (multiple primitives) > single mesh collider
```

---

## Raycasting
## 射线检测

### Efficient Raycasting (Avoid Allocations)
### 高效的射线检测（避免分配）

```csharp
// ✅ Non-allocating raycast
if (Physics.Raycast(origin, direction, out RaycastHit hit, maxDistance)) {
    Debug.Log($"Hit: {hit.collider.name}");
}

// ✅ Multiple hits (non-allocating)
RaycastHit[] results = new RaycastHit[10];
int hitCount = Physics.RaycastNonAlloc(origin, direction, results, maxDistance);
for (int i = 0; i < hitCount; i++) {
    Debug.Log($"Hit {i}: {results[i].collider.name}");
}

// ❌ Avoid: RaycastAll (allocates array every call)
RaycastHit[] hits = Physics.RaycastAll(origin, direction); // GC allocation!
```

### LayerMask for Selective Raycasting
### 使用 LayerMask 进行选择性射线检测

```csharp
// ✅ Use LayerMask to filter collisions
int layerMask = 1 << LayerMask.NameToLayer("Enemy");
Physics.Raycast(origin, direction, out RaycastHit hit, maxDistance, layerMask);
```

---

## Physics Queries
## 物理查询

### OverlapSphere (Check for nearby objects)
### OverlapSphere（检查附近对象）

```csharp
// ✅ Non-allocating version
Collider[] results = new Collider[10];
int count = Physics.OverlapSphereNonAlloc(center, radius, results);
for (int i = 0; i < count; i++) {
    // Process results[i]
}
```

### SphereCast (Thick raycast)
### SphereCast（粗射线检测）

```csharp
// Useful for character controllers
if (Physics.SphereCast(origin, radius, direction, out RaycastHit hit, maxDistance)) {
    // Hit something with a sphere-shaped ray
}
```

---

## Collision Events
## 碰撞事件

### OnCollisionEnter / Stay / Exit
### OnCollisionEnter / Stay / Exit

```csharp
void OnCollisionEnter(Collision collision) {
    // Triggered when collision starts
    Debug.Log($"Collided with {collision.gameObject.name}");

    // Access contact points
    foreach (ContactPoint contact in collision.contacts) {
        Debug.DrawRay(contact.point, contact.normal, Color.red, 2f);
    }
}
```

### OnTriggerEnter / Stay / Exit
### OnTriggerEnter / Stay / Exit

```csharp
void OnTriggerEnter(Collider other) {
    // Trigger collider (Is Trigger = true)
    if (other.CompareTag("Pickup")) {
        Destroy(other.gameObject);
    }
}
```

---

## Character Controllers
## 角色控制器

### CharacterController Component
### CharacterController 组件

```csharp
CharacterController controller = GetComponent<CharacterController>();

// ✅ Move with collision detection
Vector3 move = transform.forward * speed * Time.deltaTime;
controller.Move(move);

// Apply gravity manually
if (!controller.isGrounded) {
    velocity.y += Physics.gravity.y * Time.deltaTime;
}
controller.Move(velocity * Time.deltaTime);
```

---

## Physics Materials
## 物理材质

### Friction & Bounciness
### 摩擦力与弹性

```csharp
// Create: Assets > Create > Physic Material
// Assign to collider: Collider > Material

// PhysicMaterial settings:
// - Dynamic Friction: 0.6 (sliding friction)
// - Static Friction: 0.6 (starting friction)
// - Bounciness: 0.0 - 1.0
// - Friction Combine: Average, Minimum, Maximum, Multiply
// - Bounce Combine: Average, Minimum, Maximum, Multiply
```

---

## Joints
## 关节（Joints）

### Fixed Joint (Attach two rigidbodies)
### Fixed Joint（连接两个刚体）

```csharp
FixedJoint joint = gameObject.AddComponent<FixedJoint>();
joint.connectedBody = otherRigidbody;
```

### Hinge Joint (Door, wheel)
### Hinge Joint（门、轮子）

```csharp
HingeJoint hinge = gameObject.AddComponent<HingeJoint>();
hinge.axis = Vector3.up; // Rotation axis
hinge.useLimits = true;
hinge.limits = new JointLimits { min = -90, max = 90 };
```

---

## Performance Optimization
## 性能优化

### Physics Layer Collision Matrix
### 物理层碰撞矩阵
`Edit > Project Settings > Physics > Layer Collision Matrix`
- Disable unnecessary collision checks between layers
- Massive performance gain

`Edit > Project Settings > Physics > Layer Collision Matrix`
- 禁用层与层之间不必要的碰撞检测
- 可带来大幅性能提升

### Fixed Timestep
### 固定时间步长
`Edit > Project Settings > Time > Fixed Timestep`
- Default: 0.02 (50 FPS physics)
- Lower = more accurate, higher CPU cost
- Match game's target framerate if possible

`Edit > Project Settings > Time > Fixed Timestep`
- 默认值：0.02（50 FPS 物理）
- 越小越精确，CPU 开销越高
- 尽可能匹配游戏的目标帧率

### Simplified Collision Geometry
### 简化碰撞几何体
- Use primitive colliders (box, sphere, capsule) over mesh colliders
- Bake mesh colliders at build time, not runtime

- 使用基元碰撞体（box、sphere、capsule）而非网格碰撞体
- 在构建时烘焙网格碰撞体，而非运行时

---

## Common Patterns
## 常见模式

### Ground Check (Character Controller)
### 地面检测（Character Controller）

```csharp
bool IsGrounded() {
    float rayLength = 0.1f;
    return Physics.Raycast(transform.position, Vector3.down, rayLength);
}
```

### Apply Explosion Force
### 施加爆炸力

```csharp
void ApplyExplosion(Vector3 explosionPos, float radius, float force) {
    Collider[] colliders = Physics.OverlapSphere(explosionPos, radius);
    foreach (Collider hit in colliders) {
        Rigidbody rb = hit.GetComponent<Rigidbody>();
        if (rb != null) {
            rb.AddExplosionForce(force, explosionPos, radius);
        }
    }
}
```

---

## Debugging
## 调试

### Physics Debugger (Unity 6+)
### 物理调试器（Physics Debugger，Unity 6+）
- `Window > Analysis > Physics Debugger`
- Visualize colliders, contacts, queries

- `Window > Analysis > Physics Debugger`
- 可视化碰撞体、接触点、查询

### Gizmos
### Gizmos

```csharp
void OnDrawGizmos() {
    Gizmos.color = Color.red;
    Gizmos.DrawWireSphere(transform.position, detectionRadius);
}
```

---

## Sources
## 来源
- https://docs.unity3d.com/6000.0/Documentation/Manual/PhysicsOverview.html
- https://docs.unity3d.com/ScriptReference/Physics.html
