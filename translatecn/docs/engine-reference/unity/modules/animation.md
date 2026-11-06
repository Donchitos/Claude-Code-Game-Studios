# Unity 6.3 — Animation Module Reference
# Unity 6.3 — 动画模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 animation improvements, Timeline enhancements
**知识盲区：** Unity 6 的动画改进、Timeline 增强

---

## Overview
## 概述

Unity 6.3 animation systems:
- **Animator Controller (Mecanim)**: State machine-based (RECOMMENDED)
- **Timeline**: Cinematic sequences, cutscenes
- **Animation Rigging**: Procedural runtime animation
- **Legacy Animation**: Deprecated, avoid

Unity 6.3 动画系统：
- **Animator Controller（Mecanim）**：基于状态机（推荐）
- **Timeline**：电影化序列、过场动画
- **Animation Rigging**：程序化运行时动画
- **旧版动画（Legacy Animation）**：已弃用，应避免使用

---

## Key Changes from 2022 LTS
## 相对 2022 LTS 的关键变更

### Animation Rigging Package (Production-Ready in Unity 6)
### Animation Rigging 包（在 Unity 6 中生产就绪）

```csharp
// Install: Package Manager > Animation Rigging
// Runtime IK, aim constraints, procedural animation
```

### Timeline Improvements
### Timeline 改进
- Better performance
- More track types
- Improved signal system

- 更好的性能
- 更多轨道类型
- 改进的信号系统

---

## Animator Controller (Mecanim)
## Animator Controller（Mecanim）

### Basic Setup
### 基本设置

```csharp
// Create: Assets > Create > Animator Controller
// Add to GameObject: Add Component > Animator
// Assign Controller: Animator > Controller = YourAnimatorController
```

### State Transitions
### 状态过渡

```csharp
Animator animator = GetComponent<Animator>();

// ✅ Trigger transition
animator.SetTrigger("Jump");

// ✅ Bool parameter
animator.SetBool("IsRunning", true);

// ✅ Float parameter (blend trees)
animator.SetFloat("Speed", currentSpeed);

// ✅ Integer parameter
animator.SetInteger("WeaponType", 2);
```

### Animation Layers
### 动画层
- **Base Layer**: Default animations (locomotion)
- **Override Layers**: Replace base layer (e.g., weapon swap)
- **Additive Layers**: Add on top of base (e.g., breathing, aim offset)

- **基础层（Base Layer）**：默认动画（移动）
- **覆盖层（Override Layers）**：替换基础层（例如武器切换）
- **叠加层（Additive Layers）**：在基础层之上叠加（例如呼吸、瞄准偏移）

```csharp
// Set layer weight (0-1)
animator.SetLayerWeight(1, 0.5f); // 50% blend
```

---

## Blend Trees
## 混合树（Blend Trees）

### 1D Blend Tree (Speed blending)
### 一维混合树（速度混合）

```csharp
// Idle (Speed = 0) → Walk (Speed = 0.5) → Run (Speed = 1.0)
animator.SetFloat("Speed", moveSpeed);
```

### 2D Blend Tree (Directional movement)
### 二维混合树（方向性移动）

```csharp
// X-axis: Strafe (-1 to 1)
// Y-axis: Forward/Back (-1 to 1)
animator.SetFloat("MoveX", input.x);
animator.SetFloat("MoveY", input.y);
```

---

## Animation Events
## 动画事件

### Trigger Events from Animation Clips
### 从动画剪辑触发事件

```csharp
// Add in Animation window: Right-click timeline > Add Animation Event
// Must have matching method on GameObject:

public void OnFootstep() {
    // Play footstep sound
    AudioSource.PlayClipAtPoint(footstepClip, transform.position);
}

public void OnAttackHit() {
    // Deal damage
    DealDamageInFrontOfPlayer();
}
```

---

## Root Motion
## 根运动（Root Motion）

### Character Movement via Animation
### 通过动画驱动角色移动

```csharp
Animator animator = GetComponent<Animator>();
animator.applyRootMotion = true; // Move character based on animation

void OnAnimatorMove() {
    // Custom root motion handling
    transform.position += animator.deltaPosition;
    transform.rotation *= animator.deltaRotation;
}
```

---

## Animation Rigging (Unity 6+)
## Animation Rigging（Unity 6+）

### IK (Inverse Kinematics)
### IK（反向运动学）

```csharp
// Install: Package Manager > Animation Rigging
// Add: Rig Builder component + Rig GameObject

// Two Bone IK (Arm/Leg)
// - Add Two Bone IK Constraint
// - Assign Tip (hand/foot), Mid (elbow/knee), Root (shoulder/hip)
// - Set Target (where hand/foot should reach)

// Runtime control:
TwoBoneIKConstraint ikConstraint = rig.GetComponentInChildren<TwoBoneIKConstraint>();
ikConstraint.data.target = targetTransform;
ikConstraint.weight = 1f; // 0-1 blend
```

### Aim Constraint (Look At)
### 瞄准约束（Aim Constraint，看向目标）

```csharp
// Character looks at target
MultiAimConstraint aimConstraint = rig.GetComponentInChildren<MultiAimConstraint>();
aimConstraint.data.sourceObjects[0] = new WeightedTransform(targetTransform, 1f);
```

---

## Timeline (Cutscenes)
## Timeline（过场动画）

### Basic Timeline Setup
### 基本 Timeline 设置

```csharp
// Create: Assets > Create > Timeline
// Add to GameObject: Add Component > Playable Director
// Assign Timeline: Playable Director > Playable = YourTimeline

// Play from script:
PlayableDirector director = GetComponent<PlayableDirector>();
director.Play();
```

### Timeline Tracks
### Timeline 轨道
- **Activation Track**: Enable/disable GameObjects
- **Animation Track**: Play animations on Animator
- **Audio Track**: Synchronized audio playback
- **Cinemachine Track**: Camera movement
- **Signal Track**: Trigger events at specific times

- **激活轨道（Activation Track）**：启用/禁用 GameObject
- **动画轨道（Animation Track）**：在 Animator 上播放动画
- **音频轨道（Audio Track）**：同步音频播放
- **Cinemachine 轨道（Cinemachine Track）**：摄像机运动
- **信号轨道（Signal Track）**：在特定时间触发事件

### Signal System (Events)
### 信号系统（事件）

```csharp
// Create Signal Asset: Assets > Create > Signals > Signal
// Add Signal Emitter to Timeline track
// Add Signal Receiver component to GameObject

public class CutsceneEvents : MonoBehaviour {
    public void OnDialogueStart() {
        // Triggered by signal
    }
}
```

---

## Animation Playback Control
## 动画播放控制

### Play Animation Directly (No State Machine)
### 直接播放动画（不经过状态机）

```csharp
// ✅ CrossFade (smooth transition)
animator.CrossFade("Attack", 0.2f); // 0.2s transition

// ✅ Play (instant)
animator.Play("Idle");

// ❌ Avoid: Legacy Animation component
Animation anim = GetComponent<Animation>(); // DEPRECATED
```

---

## Animation Curves
## 动画曲线

### Custom Property Animation
### 自定义属性动画

```csharp
// In Animation window: Add Property > Custom Component > Your Script > Your Float

public class WeaponTrail : MonoBehaviour {
    public float trailIntensity; // Animated by clip

    void Update() {
        // Intensity controlled by animation curve
        trailRenderer.startWidth = trailIntensity;
    }
}
```

---

## Performance Optimization
## 性能优化

### Culling
### 剔除
- `Animator > Culling Mode`:
  - **Always Animate**: Always update (expensive)
  - **Cull Update Transforms**: Stop updating bones when off-screen (RECOMMENDED)
  - **Cull Completely**: Stop all animation when off-screen

- `Animator > Culling Mode`：
  - **Always Animate**：始终更新（开销较大）
  - **Cull Update Transforms**：脱离屏幕时停止更新骨骼（推荐）
  - **Cull Completely**：脱离屏幕时停止所有动画

### LOD (Level of Detail)
### LOD（细节层次）
- Simpler animations for distant characters
- Reduce skeleton bone count for LOD meshes

- 为远处角色使用更简单的动画
- 为 LOD 网格减少骨骼数量

---

## Common Patterns
## 常见模式

### Check if Animation Finished
### 检查动画是否结束

```csharp
AnimatorStateInfo stateInfo = animator.GetCurrentAnimatorStateInfo(0);
if (stateInfo.IsName("Attack") && stateInfo.normalizedTime >= 1.0f) {
    // Attack animation finished
}
```

### Override Animation Speed
### 覆盖动画速度

```csharp
animator.speed = 1.5f; // 150% speed
```

### Get Current Animation Name
### 获取当前动画名称

```csharp
AnimatorClipInfo[] clipInfo = animator.GetCurrentAnimatorClipInfo(0);
string currentClip = clipInfo[0].clip.name;
```

---

## Debugging
## 调试

### Animator Window
### Animator 窗口
- `Window > Animation > Animator`
- Visualize state machine, see active state

- `Window > Animation > Animator`
- 可视化状态机，查看当前活动状态

### Animation Window
### Animation 窗口
- `Window > Animation > Animation`
- Edit animation clips, add events

- `Window > Animation > Animation`
- 编辑动画剪辑，添加事件

---

## Sources
## 来源
- https://docs.unity3d.com/6000.0/Documentation/Manual/AnimationOverview.html
- https://docs.unity3d.com/Packages/com.unity.animation.rigging@1.3/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.timeline@1.8/manual/index.html
