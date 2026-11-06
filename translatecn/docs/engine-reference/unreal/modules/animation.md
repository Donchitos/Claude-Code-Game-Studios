# Unreal Engine 5.8 — Animation Module Reference
# Unreal Engine 5.8 — 动画模块参考

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.4-5.8 animation authoring improvements, Control Rig 2.0

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.4-5.8 的动画创作改进、Control Rig 2.0

> **UE 5.8 changes:** Smart names are deprecated — `FSmartName`,
> `FSmartNameMapping` and `FSmartNameContainer` carry `UE_DEPRECATED(5.8, "Smart
> names and their mappings are no longer used")` (`Engine/Source/Runtime/Engine/Classes/Animation/SmartName.h`).
> Non-reflected deprecated Animation, Control Rig, Persona and Live Link APIs
> from 5.0-5.6 were removed (e.g. `UMotionWarpingComponent::GetCharacterOwner`
> → `GetOwnerAdapter()->GetActor()`). Control Rig Physics and the RigMapper
> retargeting tool are Beta; Animation Mixing in Sequencer and Direct Mesh
> Controls are Experimental. Source: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** Smart name 已弃用 — `FSmartName`、
> `FSmartNameMapping` 与 `FSmartNameContainer` 带有 `UE_DEPRECATED(5.8, "Smart
> names and their mappings are no longer used")`（`Engine/Source/Runtime/Engine/Classes/Animation/SmartName.h`）。
> 5.0-5.6 中非反射的已弃用 Animation、Control Rig、Persona 与 Live Link API 已被移除（例如 `UMotionWarpingComponent::GetCharacterOwner`
> → `GetOwnerAdapter()->GetActor()`）。Control Rig Physics 与 RigMapper 重定向工具为 Beta；Sequencer 中的 Animation Mixing 与 Direct Mesh Controls 为实验性。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

UE 5.8 animation systems:
- **Animation Blueprint**: State machine-based animation logic
- **Control Rig**: Runtime procedural animation (production-ready in UE5)
- **IK Rig + Retargeter**: Modern retargeting system
- **Sequencer**: Cinematic animation

UE 5.8 动画系统：
- **Animation Blueprint**：基于状态机的动画逻辑
- **Control Rig**：运行时程序化动画（UE5 中生产就绪）
- **IK Rig + Retargeter**：现代重定向系统
- **Sequencer**：过场动画

---

## Animation Blueprint
## Animation Blueprint

### Create Animation Blueprint
### 创建 Animation Blueprint

1. Content Browser > Right Click > Animation > Animation Blueprint
2. Select parent class: `AnimInstance`
3. Select skeleton

1. Content Browser > Right Click > Animation > Animation Blueprint
2. 选择父类：`AnimInstance`
3. 选择骨架

### Animation State Machine
### 动画状态机

```cpp
// In Animation Blueprint Event Graph:
// - State Machine drives animation states (Idle, Walk, Run, Jump)
// - Blend Spaces for directional movement

// Access in C++:
UAnimInstance* AnimInstance = Mesh->GetAnimInstance();
AnimInstance->Montage_Play(AttackMontage);
```

---

## Play Animation Montages
## 播放动画蒙太奇

### Animation Montage
### Animation Montage

```cpp
// Play montage
UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
AnimInstance->Montage_Play(AttackMontage, 1.0f);

// Stop montage
AnimInstance->Montage_Stop(0.2f, AttackMontage);

// Check if montage is playing
bool bIsPlaying = AnimInstance->Montage_IsPlaying(AttackMontage);
```

### Montage Notify Events
### 蒙太奇通知事件

```cpp
// Add notify event in Animation Montage (right-click timeline > Add Notify > New Notify)
// Implement in C++:

UCLASS()
class UMyAnimInstance : public UAnimInstance {
    GENERATED_BODY()

public:
    UFUNCTION()
    void AnimNotify_AttackHit() {
        // Called when notify is reached
        DealDamage();
    }
};
```

---

## Blend Spaces
## 混合空间

### 1D Blend Space (Speed Blending)
### 1D 混合空间（速度混合）

```cpp
// Create: Content Browser > Animation > Blend Space 1D
// Horizontal Axis: Speed (0 = Idle, 1 = Walk, 2 = Run)
// Add animations at key points

// Use in Anim Blueprint:
// - Get speed from character
// - Feed into Blend Space
```

### 2D Blend Space (Directional Movement)
### 2D 混合空间（方向性移动）

```cpp
// Create: Content Browser > Animation > Blend Space
// Horizontal Axis: Direction X (-1 to 1)
// Vertical Axis: Direction Y (-1 to 1)
// Place animations (Fwd, Back, Left, Right, diagonal)
```

---

## Control Rig (Procedural Animation)
## Control Rig（程序化动画）

### Create Control Rig
### 创建 Control Rig

1. Content Browser > Animation > Control Rig
2. Select skeleton
3. Build rig hierarchy (bones, controls, IK)

1. Content Browser > Animation > Control Rig
2. 选择骨架
3. 构建 Rig 层级（骨骼、控制器、IK）

### Use Control Rig in Animation Blueprint
### 在 Animation Blueprint 中使用 Control Rig

```cpp
// Add "Control Rig" node to Anim Blueprint
// Assign Control Rig asset
// Procedurally modify bones at runtime
```

### Control Rig in C++
### 在 C++ 中使用 Control Rig

```cpp
// Get control rig component
UControlRig* ControlRig = /* Get from animation instance */;

// Set control value
ControlRig->SetControlValue<FVector>(TEXT("IK_Hand_R"), TargetLocation);
```

---

## IK Rig & Retargeting (UE5)
## IK Rig 与重定向（UE5）

### Create IK Rig
### 创建 IK Rig

1. Content Browser > Animation > IK Rig
2. Select skeleton
3. Add IK goals (hands, feet)
4. Set up solver chains

1. Content Browser > Animation > IK Rig
2. 选择骨架
3. 添加 IK 目标（手、脚）
4. 设置解算链

### Retarget Animations
### 重定向动画

1. Create IK Rig for source skeleton
2. Create IK Rig for target skeleton
3. Create IK Retargeter asset
4. Assign source and target IK Rigs
5. Batch retarget animations

1. 为源骨架创建 IK Rig
2. 为目标骨架创建 IK Rig
3. 创建 IK Retargeter 资产
4. 分配源与目标 IK Rig
5. 批量重定向动画

### Retargeting in C++
### 在 C++ 中重定向

```cpp
// Retargeting is primarily editor-based
// Animations are retargeted once, then used normally
```

---

## Animation Notify States
## 动画通知状态

### Custom Notify State (Duration-Based Events)
### 自定义通知状态（基于持续时间的事件）

```cpp
UCLASS()
class UAnimNotifyState_Invulnerable : public UAnimNotifyState {
    GENERATED_BODY()

public:
    virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference) override {
        // Start invulnerability
        AMyCharacter* Character = Cast<AMyCharacter>(MeshComp->GetOwner());
        Character->bIsInvulnerable = true;
    }

    virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override {
        // End invulnerability
        AMyCharacter* Character = Cast<AMyCharacter>(MeshComp->GetOwner());
        Character->bIsInvulnerable = false;
    }
};
```

---

## Skeletal Mesh & Sockets
## 骨骼网格与插槽

### Attach Objects to Sockets
### 将物体附加到插槽

```cpp
// Create socket in Skeletal Mesh Editor (Skeleton Tree > Add Socket)

// Attach component to socket
UStaticMeshComponent* Weapon = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Weapon"));
Weapon->SetupAttachment(GetMesh(), TEXT("hand_r_socket"));
```

---

## Animation Curves
## 动画曲线

### Use Animation Curves
### 使用动画曲线

```cpp
// Add curve to animation:
// Animation Editor > Curves > Add Curve

// Read curve value in Anim Blueprint or C++:
UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
float CurveValue = AnimInstance->GetCurveValue(TEXT("MyCurve"));
```

---

## Root Motion
## 根运动

### Enable Root Motion
### 启用根运动

```cpp
// In Animation Sequence: Asset Details > Root Motion > Enable Root Motion

// In Character class:
GetCharacterMovement()->bAllowPhysicsRotationDuringAnimRootMotion = true;
```

---

## Animation Layers (Linked Anim Graphs)
## 动画层（Linked Anim Graphs）

### Use Linked Anim Layers
### 使用链接动画层

```cpp
// Create separate Anim Blueprints for layers (e.g., upper body, lower body)
// Link in main Anim Blueprint: Add "Linked Anim Graph" node

// Dynamically switch layers:
UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
AnimInstance->LinkAnimClassLayers(NewLayerClass);
```

---

## Sequencer (Cinematic Animation)
## Sequencer（过场动画）

### Create Sequence
### 创建序列

1. Content Browser > Cinematics > Level Sequence
2. Add tracks: Camera, Character, Animation, etc.

1. Content Browser > Cinematics > Level Sequence
2. 添加轨道：Camera、Character、Animation 等

### Play Sequence from C++
### 从 C++ 播放序列

```cpp
#include "LevelSequenceActor.h"
#include "LevelSequencePlayer.h"

ALevelSequenceActor* SequenceActor = /* Spawn or find in level */;
SequenceActor->GetSequencePlayer()->Play();
```

---

## Performance Tips
## 性能建议

### Animation Optimization
### 动画优化

```cpp
// LOD (Level of Detail) for skeletal meshes
// Reduce bone count for distant characters

// Anim Blueprint optimization:
// - Use "Anim Node Relevancy" (skip updates when not visible)
// - Disable updates when off-screen:
GetMesh()->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
```

---

## Debugging
## 调试

### Animation Debug Visualization
### 动画调试可视化

```cpp
// Console commands:
// showdebug animation - Show animation state info
// a.VisualizeSkeletalMeshBones 1 - Show skeleton bones

// Draw debug bones:
DrawDebugCoordinateSystem(GetWorld(), BoneLocation, BoneRotation, 50.0f, false, -1.0f, 0, 2.0f);
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/animation-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/control-rig-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/ik-rig-in-unreal-engine/
