# Unity 6.3 — Cinemachine
# Unity 6.3 — Cinemachine

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Status:** Production-Ready
**状态：** 生产就绪
**Package:** `com.unity.cinemachine` v3.0+ (Package Manager)
**包：** `com.unity.cinemachine` v3.0+（Package Manager）

---

## Overview
## 概述

**Cinemachine** is Unity's virtual camera system that enables professional, dynamic camera
behavior without manual scripting. It's the industry standard for Unity camera work.

**Cinemachine** 是 Unity 的虚拟摄像机系统，无需手动编写脚本即可实现专业、动态的摄像机行为。它是 Unity 摄像机工作的行业标准。

**Use Cinemachine for:**
- 3rd person follow cameras
- Cutscenes and cinematics
- Camera blending and transitions
- Dynamic camera framing
- Screen shake and camera effects

**使用 Cinemachine 的场景：**
- 第三人称跟随摄像机
- 过场动画和电影化场景
- 摄像机混合和过渡
- 动态摄像机取景
- 屏幕震动和摄像机效果

**⚠️ Knowledge Gap:** Cinemachine 3.0 (Unity 6) is a major rewrite from 2.x.
Many API names and components changed.

**⚠️ 知识盲区：** Cinemachine 3.0（Unity 6）相比 2.x 是一次重大重写。
许多 API 名称和组件已变更。

---

## Installation
## 安装

### Install via Package Manager
### 通过 Package Manager 安装

1. `Window > Package Manager`
2. Unity Registry > Search "Cinemachine"
3. Install `Cinemachine` (version 3.0+)

1. `Window > Package Manager`
2. Unity Registry > 搜索 "Cinemachine"
3. 安装 `Cinemachine`（版本 3.0+）

---

## Core Concepts
## 核心概念

### 1. **Virtual Cameras**
### 1. **虚拟摄像机**
- Define camera behavior (position, rotation, lens)
- Multiple virtual cameras can exist; only one is "live" at a time

- 定义摄像机行为（位置、旋转、镜头）
- 可以存在多个虚拟摄像机；一次只有一个为"活动"状态

### 2. **Cinemachine Brain**
### 2. **Cinemachine Brain**
- Component on main Camera
- Blends between virtual cameras
- Applies virtual camera settings to Unity Camera

- 主摄像机上的组件
- 在虚拟摄像机之间混合
- 将虚拟摄像机设置应用到 Unity Camera

### 3. **Priorit**ies**
### 3. **优先级**
- Virtual cameras have priority values
- Highest priority camera is active
- Blends smoothly when priority changes

- 虚拟摄像机有优先级值
- 最高优先级的摄像机为活动状态
- 优先级变化时平滑混合

---

## Basic Setup
## 基本设置

### 1. Add Cinemachine Brain to Main Camera
### 1. 将 Cinemachine Brain 添加到主摄像机

```csharp
// Automatically added when creating first virtual camera
// Or manually: Add Component > Cinemachine Brain
```

### 2. Create Virtual Camera
### 2. 创建虚拟摄像机

`GameObject > Cinemachine > Cinemachine Camera`

`GameObject > Cinemachine > Cinemachine Camera`

This creates a **CinemachineCamera** GameObject with default settings.

这会创建一个带有默认设置的 **CinemachineCamera** GameObject。

---

## Virtual Camera Components
## 虚拟摄像机组件

### CinemachineCamera (Unity 6 / Cinemachine 3.0+)
### CinemachineCamera（Unity 6 / Cinemachine 3.0+）

```csharp
using Unity.Cinemachine;

public class CameraController : MonoBehaviour {
    public CinemachineCamera virtualCamera;

    void Start() {
        // Set priority (higher = active)
        virtualCamera.Priority = 10;

        // Set follow target
        virtualCamera.Follow = playerTransform;

        // Set look-at target
        virtualCamera.LookAt = playerTransform;
    }
}
```

---

## Follow Modes (Body Component)
## 跟随模式（Body 组件）

### 3rd Person Follow (Orbital Follow)
### 第三人称跟随（Orbital Follow）

```csharp
// In Inspector:
// CinemachineCamera > Body > 3rd Person Follow

// Configure:
// - Shoulder Offset: (0.5, 0, 0) for over-shoulder
// - Camera Distance: 5.0
// - Vertical Damping: 0.5 (smooth up/down)
```

### Framing Transposer (Smooth Follow)
### 构图移调器（Framing Transposer，平滑跟随）

```csharp
// CinemachineCamera > Body > Position Composer

// Configure:
// - Screen Position: Center (0.5, 0.5)
// - Dead Zone: Don't move camera if target within zone
// - Damping: Smooth following
```

### Hard Lock (Exact Follow)
### 硬锁定（Hard Lock，精确跟随）

```csharp
// CinemachineCamera > Body > Hard Lock to Target
// Camera exactly matches target position (no offset or damping)
```

---

## Aim Modes (Aim Component)
## 瞄准模式（Aim 组件）

### Composer (Frame Target)
### Composer（构图目标）

```csharp
// CinemachineCamera > Aim > Composer

// Configure:
// - Tracked Object Offset: Aim at target's head instead of feet
// - Screen Position: Where target appears on screen
// - Dead Zone: Don't rotate if target within zone
```

### Look At Target
### 看向目标（Look At Target）

```csharp
// CinemachineCamera > Aim > Rotate With Follow Target
// Camera rotation matches target rotation (e.g., first-person)
```

---

## Blending Between Cameras
## 摄像机之间的混合

### Priority-Based Blending
### 基于优先级的混合

```csharp
public CinemachineCamera normalCamera; // Priority: 10
public CinemachineCamera aimCamera;    // Priority: 5

void StartAiming() {
    // Set aim camera to higher priority
    aimCamera.Priority = 15; // Now active
    // Brain automatically blends from normalCamera to aimCamera
}

void StopAiming() {
    aimCamera.Priority = 5; // Back to normal
}
```

### Custom Blend Times
### 自定义混合时间

```csharp
// Create Custom Blends Asset:
// Assets > Create > Cinemachine > Cinemachine Blender Settings

// In Cinemachine Brain:
// - Custom Blends = your asset
// - Configure blend times per camera pair
```

---

## Camera Shake
## 摄像机震动

### Impulse Source (Trigger Shake)
### 冲量源（Impulse Source，触发震动）

```csharp
using Unity.Cinemachine;

public class ExplosionShake : MonoBehaviour {
    public CinemachineImpulseSource impulseSource;

    void Explode() {
        // Trigger camera shake
        impulseSource.GenerateImpulse();
    }
}
```

### Impulse Listener (Receive Shake)
### 冲量监听器（Impulse Listener，接收震动）

```csharp
// Add to CinemachineCamera:
// Add Component > CinemachineImpulseListener

// Impulse listener automatically receives shake from nearby Impulse Sources
```

---

## Freelook Camera (Third Person with Mouse Look)
## 自由视角摄像机（Freelook Camera，带鼠标视角的第三人称）

### Cinemachine Free Look
### Cinemachine Free Look

```csharp
// GameObject > Cinemachine > Cinemachine Free Look

// Creates 3 rigs (Top, Middle, Bottom) that blend based on vertical input
// Configure:
// - Orbit Radius: Distance from target
// - Height Offset: Camera height at each rig
// - X/Y Axis: Mouse or joystick input
```

---

## State-Driven Camera (Anim ator-Based)
## 状态驱动摄像机（State-Driven Camera，基于 Animator）

### Cinemachine State-Driven Camera
### Cinemachine State-Driven Camera

```csharp
// GameObject > Cinemachine > Cinemachine State-Driven Camera

// Configure:
// - Animated Target: Character with Animator
// - Layer: Animator layer to track
// - State: Assign camera per animation state (Idle, Run, Jump, etc.)

// Camera automatically switches based on animation state
```

---

## Dolly Tracks (Cutscenes)
## 推轨（Dolly Tracks，过场动画）

### Cinemachine Dolly Track
### Cinemachine Dolly Track

```csharp
// 1. Create Spline: GameObject > Cinemachine > Cinemachine Spline

// 2. Create Dolly Camera:
//    GameObject > Cinemachine > Cinemachine Camera
//    Body > Spline Dolly
//    Assign Spline

// 3. Animate dolly position on spline (Timeline or script)
```

---

## Common Patterns
## 常见模式

### Third-Person Follow Camera
### 第三人称跟随摄像机

```csharp
// CinemachineCamera
// - Follow: Player Transform
// - Body: 3rd Person Follow (shoulder offset, distance: 5)
// - Aim: Composer (frame player at center)
```

---

### Aiming Camera (Zoom In)
### 瞄准摄像机（拉近）

```csharp
// Normal Camera (Priority 10):
//   - Distance: 5.0

// Aim Camera (Priority 5):
//   - Distance: 2.0
//   - FOV: Narrower

// Script:
void StartAiming() {
    aimCamera.Priority = 15; // Blend to aim camera
}
```

---

### Cutscene Camera Sequence
### 过场动画摄像机序列

```csharp
// Use Timeline:
// 1. Create Timeline (Assets > Create > Timeline)
// 2. Add Cinemachine Track
// 3. Add virtual cameras as clips
// 4. Timeline automatically blends between cameras
```

---

## Migration from Cinemachine 2.x (Unity 2021)
## 从 Cinemachine 2.x（Unity 2021）迁移

### API Changes (Unity 6 / Cinemachine 3.0)
### API 变更（Unity 6 / Cinemachine 3.0）

```csharp
// ❌ OLD (Cinemachine 2.x):
CinemachineVirtualCamera vcam;
vcam.m_Follow = target;

// ✅ NEW (Cinemachine 3.0+):
CinemachineCamera vcam;
vcam.Follow = target; // Cleaner API
```

**Major Changes:**
- `CinemachineVirtualCamera` → `CinemachineCamera`
- `m_Follow`, `m_LookAt` → `Follow`, `LookAt` (no "m_" prefix)
- Components renamed for clarity
- Better performance

**主要变更：**
- `CinemachineVirtualCamera` → `CinemachineCamera`
- `m_Follow`、`m_LookAt` → `Follow`、`LookAt`（去除 "m_" 前缀）
- 为提升清晰度重命名了组件
- 更好的性能

---

## Performance Tips
## 性能提示

- Limit active virtual cameras (only activate when needed)
- Use lower-priority cameras instead of destroying/creating
- Disable virtual cameras when far from player

- 限制活动的虚拟摄像机数量（仅在需要时激活）
- 使用较低优先级的摄像机，而不是销毁/创建
- 远离玩家时禁用虚拟摄像机

---

## Debugging
## 调试

### Cinemachine Debug
### Cinemachine 调试

```csharp
// Window > Analysis > Cinemachine Debugger
// Shows active camera, blend info, shot quality
```

---

## Sources
## 来源
- https://docs.unity3d.com/Packages/com.unity.cinemachine@3.0/manual/index.html
- https://learn.unity.com/tutorial/cinemachine
