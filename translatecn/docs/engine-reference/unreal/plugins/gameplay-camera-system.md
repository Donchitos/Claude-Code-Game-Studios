# Unreal Engine 5.8 — Gameplay Camera System
# Unreal Engine 5.8 — Gameplay 相机系统

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Status:** ⚠️ Experimental (introduced in UE 5.5; still flagged Experimental in 5.8)
**Plugin:** `GameplayCameras` (built-in, enable in Plugins)

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**状态：** ⚠️ 实验性（UE 5.5 引入；5.8 中仍标记为 Experimental）
**插件：** `GameplayCameras`（内置，在 Plugins 中启用）

> **UE 5.8 changes:** The camera component can run its own camera system
> ("standalone" mode, the default) or only a camera evaluation context. The
> player camera manager now runs whatever is the view target as a "blackbox";
> for blending or child directors a procedural camera must be activated with
> dedicated new methods such as "Activate Gameplay Camera". Rig/modifier
> activation and shake start/stop methods were moved; there is a new "aim-at"
> camera action and a camera action service. `GameplayCameras.uplugin` (5.8.1)
> is flagged Experimental and enabled by default. Source: UE 5.8 release notes,
> https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** 相机组件可以运行自己的相机系统（"standalone"模式，也是默认模式），或仅承担相机求值上下文。玩家相机管理器现在以"黑盒"方式运行任何作为视图目标的对象；对于混合或子导演，必须使用专门的新方法（如"Activate Gameplay Camera"）激活程序化相机。Rig/修饰器的激活方法，以及震动的启动/停止方法已迁移；新增了"aim-at"相机动作与相机动作服务。`GameplayCameras.uplugin`（5.8.1）标记为 Experimental，且默认启用。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

**Gameplay Camera System** is a modular camera management framework introduced in UE 5.5.
It replaces traditional camera setups with a flexible, node-based system that handles
camera modes, blending, and context-aware camera behavior.

**Gameplay Camera System** 是 UE 5.5 引入的模块化相机管理框架。它以灵活的、基于节点的系统取代传统相机设置，处理相机模式、混合以及上下文感知的相机行为。

**Use Gameplay Cameras for:**
- Dynamic camera behavior (3rd person, aiming, vehicles, cinematic)
- Context-aware camera switching (combat, exploration, dialogue)
- Smooth camera blending between modes
- Procedural camera motion (camera shake, lag, offset)

**使用 Gameplay Cameras 的场景：**
- 动态相机行为（第三人称、瞄准、载具、过场）
- 上下文感知的相机切换（战斗、探索、对话）
- 模式之间的平滑相机混合
- 程序化相机运动（相机震动、延迟、偏移）

**⚠️ Warning:** This plugin is experimental in UE 5.5-5.8. Expect API changes in future versions.

**⚠️ 警告：** 该插件在 UE 5.5-5.8 中为实验性。未来版本预计会有 API 变更。

---

## Core Concepts
## 核心概念

### 1. **Camera Rig**
- Defines camera configuration (position, rotation, FOV, etc.)
- Modular node graph (similar to Material Editor)

### 1. **Camera Rig**
- 定义相机配置（位置、旋转、FOV 等）
- 模块化节点图（类似材质编辑器）

### 2. **Camera Director**
- Manages which camera rig is active
- Handles blending between camera rigs

### 2. **Camera Director**
- 管理当前激活的相机 Rig
- 处理相机 Rig 之间的混合

### 3. **Camera Nodes**
- Building blocks for camera behavior:
  - **Position Nodes**: Orbit, Follow, Fixed Position
  - **Rotation Nodes**: Look At, Match Actor Rotation
  - **Modifiers**: Camera Shake, Lag, Offset

### 3. **Camera Nodes**
- 相机行为的构建块：
  - **位置节点（Position Nodes）**：Orbit、Follow、Fixed Position
  - **旋转节点（Rotation Nodes）**：Look At、Match Actor Rotation
  - **修饰器（Modifiers）**：Camera Shake、Lag、Offset

---

## Setup
## 设置

### 1. Enable Plugin
### 1. 启用插件

`Edit > Plugins > Gameplay Cameras > Enabled > Restart`

`Edit > Plugins > Gameplay Cameras > Enabled > Restart`

### 2. Add Camera Component
### 2. 添加相机组件

```cpp
#include "GameplayCameras/Public/GameplayCameraComponent.h"

UCLASS()
class AMyCharacter : public ACharacter {
    GENERATED_BODY()

public:
    AMyCharacter() {
        // Create camera component
        CameraComponent = CreateDefaultSubobject<UGameplayCameraComponent>(TEXT("GameplayCamera"));
        CameraComponent->SetupAttachment(RootComponent);
    }

protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Camera")
    TObjectPtr<UGameplayCameraComponent> CameraComponent;
};
```

---

## Create Camera Rig
## 创建 Camera Rig

### 1. Create Camera Rig Asset
### 1. 创建 Camera Rig 资产

1. Content Browser > Gameplay > Gameplay Camera Rig
2. Open Camera Rig Editor (node-based graph)

1. Content Browser > Gameplay > Gameplay Camera Rig
2. 打开 Camera Rig 编辑器（基于节点的图）

### 2. Build Camera Rig (Example: Third Person)
### 2. 构建 Camera Rig（示例：第三人称）

**Node Setup:**
```
Actor Position (Character)
  ↓
Orbit Node (Orbit around character)
  ↓
Offset Node (Shoulder offset)
  ↓
Look At Node (Look at character)
  ↓
Camera Output
```

**节点设置：**
```
Actor Position (Character)
  ↓
Orbit Node (Orbit around character)
  ↓
Offset Node (Shoulder offset)
  ↓
Look At Node (Look at character)
  ↓
Camera Output
```

---

## Camera Nodes
## 相机节点

### Position Nodes
### 位置节点

#### Orbit Node (Third Person)
#### Orbit 节点（第三人称）

- Orbits around target actor
- Configure:
  - **Orbit Distance**: Distance from target (e.g., 300 units)
  - **Pitch Range**: Min/Max pitch angles
  - **Yaw Range**: Min/Max yaw angles

- 围绕目标 Actor 旋转
- 配置：
  - **Orbit Distance**：与目标的距离（例如 300 单位）
  - **Pitch Range**：最小/最大俯仰角
  - **Yaw Range**：最小/最大偏航角

#### Follow Node (Smooth Follow)
#### Follow 节点（平滑跟随）

- Follows target with lag
- Configure:
  - **Lag Speed**: How quickly camera catches up
  - **Offset**: Fixed offset from target

- 带延迟地跟随目标
- 配置：
  - **Lag Speed**：相机追赶的速度
  - **Offset**：相对目标的固定偏移

#### Fixed Position Node
#### Fixed Position 节点

- Static camera position in world space

- 世界空间中的静态相机位置

---

### Rotation Nodes
### 旋转节点

#### Look At Node
#### Look At 节点

- Points camera at target
- Configure:
  - **Target**: Actor or component to look at
  - **Offset**: Look-at offset (e.g., aim at head instead of feet)

- 让相机朝向目标
- 配置：
  - **Target**：要看向的 Actor 或组件
  - **Offset**：注视偏移（例如对准头部而非脚部）

#### Match Actor Rotation
#### Match Actor Rotation

- Matches target actor's rotation
- Useful for first-person or vehicle cameras

- 匹配目标 Actor 的旋转
- 适用于第一人称或载具相机

---

### Modifier Nodes
### 修饰器节点

#### Camera Shake
#### Camera Shake

- Adds procedural shake (e.g., footsteps, explosions)
- Configure:
  - **Shake Pattern**: Perlin noise, sine wave, custom
  - **Amplitude**: Shake strength

- 添加程序化震动（例如脚步、爆炸）
- 配置：
  - **Shake Pattern**：Perlin 噪声、正弦波、自定义
  - **Amplitude**：震动强度

#### Camera Lag
#### Camera Lag

- Smooth dampening of camera movement
- Configure:
  - **Lag Speed**: Damping factor (0 = instant, higher = more lag)

- 对相机运动进行平滑阻尼
- 配置：
  - **Lag Speed**：阻尼系数（0 = 立即，值越高延迟越大）

#### Offset Node
#### Offset 节点

- Static offset from calculated position
- Useful for shoulder camera offset

- 相对计算位置的静态偏移
- 适用于肩部相机偏移

---

## Camera Director (Switching Between Rigs)
## Camera Director（在 Rig 之间切换）

### Assign Camera Rig
### 指定 Camera Rig

```cpp
#include "GameplayCameras/Public/GameplayCameraComponent.h"

void AMyCharacter::SetCameraMode(UGameplayCameraRig* NewRig) {
    if (CameraComponent) {
        CameraComponent->SetCameraRig(NewRig);
    }
}
```

### Blend Between Camera Rigs
### 在 Camera Rig 之间混合

```cpp
// Blend to aiming camera over 0.5 seconds
CameraComponent->BlendToCameraRig(AimingCameraRig, 0.5f);
```

---

## Example: Third Person + Aiming
## 示例：第三人称 + 瞄准

### 1. Create Two Camera Rigs
### 1. 创建两个 Camera Rig

**Third Person Rig:**
```
Actor Position → Orbit (distance: 300) → Look At → Output
```

**第三人称 Rig：**
```
Actor Position → Orbit (distance: 300) → Look At → Output
```

**Aiming Rig:**
```
Actor Position → Orbit (distance: 150) → Offset (shoulder) → Look At → Output
```

**瞄准 Rig：**
```
Actor Position → Orbit (distance: 150) → Offset (shoulder) → Look At → Output
```

### 2. Switch on Aim
### 2. 瞄准时切换

```cpp
UPROPERTY(EditAnywhere, Category = "Camera")
TObjectPtr<UGameplayCameraRig> ThirdPersonRig;

UPROPERTY(EditAnywhere, Category = "Camera")
TObjectPtr<UGameplayCameraRig> AimingRig;

void StartAiming() {
    CameraComponent->BlendToCameraRig(AimingRig, 0.3f); // Blend over 0.3s
}

void StopAiming() {
    CameraComponent->BlendToCameraRig(ThirdPersonRig, 0.3f);
}
```

---

## Common Patterns
## 常见模式

### Over-the-Shoulder Camera
### 越肩相机

```
Actor Position
  ↓
Orbit Node (distance: 250, yaw offset: 30°)
  ↓
Offset Node (X: 0, Y: 50, Z: 50) // Shoulder offset
  ↓
Look At Node (target: Character head)
  ↓
Output
```

---

### Vehicle Camera
### 载具相机

```
Vehicle Position
  ↓
Follow Node (lag: 0.2)
  ↓
Offset Node (behind vehicle: X: -400, Z: 150)
  ↓
Look At Node (target: Vehicle)
  ↓
Output
```

---

### First Person Camera
### 第一人称相机

```
Character Head Socket
  ↓
Match Actor Rotation
  ↓
Output
```

---

## Camera Shake
## 相机震动

### Trigger Camera Shake
### 触发相机震动

```cpp
#include "GameplayCameras/Public/GameplayCameraShake.h"

void TriggerExplosionShake() {
    if (APlayerController* PC = GetWorld()->GetFirstPlayerController()) {
        if (UGameplayCameraComponent* CameraComp = PC->FindComponentByClass<UGameplayCameraComponent>()) {
            CameraComp->PlayCameraShake(ExplosionShakeClass, 1.0f);
        }
    }
}
```

---

## Performance Tips
## 性能建议

- Limit camera shake frequency (don't trigger every frame)
- Use camera lag sparingly (expensive for high lag values)
- Cache camera rig references (don't search every frame)

- 限制相机震动频率（不要每帧触发）
- 谨慎使用相机延迟（高延迟值开销较大）
- 缓存相机 Rig 引用（不要每帧搜索）

---

## Debugging
## 调试

### Camera Debug Visualization
### 相机调试可视化

```cpp
// Console commands:
// GameplayCameras.Debug 1 - Show active camera rig info
// showdebug camera - Show camera debug info
```

---

## Migration from Legacy Cameras
## 从旧版相机迁移

### Old Spring Arm + Camera Component
### 旧的 Spring Arm + Camera Component

```cpp
// ❌ OLD: Spring Arm Component
USpringArmComponent* SpringArm;
UCameraComponent* Camera;

// ✅ NEW: Gameplay Camera Component
UGameplayCameraComponent* CameraComponent;
// Build orbit + look-at rig in Camera Rig asset
```

---

## Limitations (Experimental Status)
## 限制（实验性状态）

- **API Instability**: Expect breaking changes in later releases (5.8 already reworked component and activation APIs)
- **Limited Documentation**: Official docs still evolving
- **Blueprint Support**: Primarily C++ focused (Blueprint support improving)
- **Production Risk**: Test thoroughly before shipping

- **API 不稳定**：后续版本预计会有破坏性变更（5.8 已重构了组件与激活 API）
- **文档有限**：官方文档仍在完善中
- **蓝图支持**：主要聚焦 C++（蓝图支持正在改进）
- **生产风险**：上线前请充分测试

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/gameplay-cameras-in-unreal-engine/
- UE 5.5+ Release Notes
- **Note:** This system is experimental. Always check latest official docs for API changes.

- https://docs.unrealengine.com/5.7/en-US/gameplay-cameras-in-unreal-engine/
- UE 5.5+ 发行说明
- **注意：** 该系统为实验性。请始终查看最新的官方文档以了解 API 变更。
