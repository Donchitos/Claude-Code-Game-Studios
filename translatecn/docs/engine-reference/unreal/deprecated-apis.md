# Unreal Engine 5.8 — Deprecated APIs
# Unreal Engine 5.8 — 已弃用 API

**Last verified:** 2026-10-17 (Deprecated in UE 5.8, Gameplay Ability System row, summary); 2026-02-13 (rest of file, written against 5.7)

**最后验证：** 2026-10-17（UE 5.8 中的弃用项、Gameplay Ability System 行、总结）；2026-02-13（文件其余部分，基于 5.7 编写）

Quick lookup table for deprecated APIs and their replacements.
Format: **Don't use X** → **Use Y instead**

已弃用 API 及其替代方案的速查表。格式：**不要用 X** → **改用 Y**

---

## Deprecated in UE 5.8
## UE 5.8 中的弃用项

From the 5.8 release notes' Upgrade Notes and the 5.8 engine headers (sources at
the end of this file). Deprecated items still compile with a warning unless the
Notes column says otherwise.

来自 5.8 发行说明的升级说明与 5.8 引擎头文件（来源见本文件末尾）。除非"说明"列另有标注，弃用项仍能编译，但会产生警告。

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `UE_LOG(...)` | `UE_LOGF(Category, Verbosity, "fmt", ...)` | Not deprecated yet: Epic says UE_LOG "will eventually be deprecated" and asks for `UE_LOGF`. The header documents the format as a printf-style literal given as `"..."` or `UTF8TEXT("...")`. 5.8 ships `ConvertUELog.py` for most uses |
| `#if PLATFORM_IOS` (and other `PLATFORM_*`) | `#if UE_PLATFORM_IOS` (`UE_PLATFORM_*`) | Optional migration; `PLATFORM_IOS` can be stomped by Apple framework headers |
| `CppStandardVersion.Cpp17` / `Cpp14` | `CppStandardVersion.Default` (C++20) | Obsolete in 5.8: code no longer compiles with them |
| Raw Input plugin (`RawInput`) | Game Input for Windows plugin (`GameInputWindows`, Beta) | `"DeprecatedEngineVersion": "5.8"` in `RawInput.uplugin` |
| PhysicsMover (Mover plugin) | ChaosMover plugin | Removed in 5.8, not just deprecated |
| `FActiveGameplayEffectHandle(int32)` | `FActiveGameplayEffectHandle::GenerateNewHandle` or `GetInstantExecutedHandle()` | `UE_DEPRECATED(5.8, ...)` |
| `FSmartName`, `FSmartNameMapping`, `FSmartNameContainer` | None: remove the use | `UE_DEPRECATED(5.8, "Smart names and their mappings are no longer used")` |
| `UFadeFunction`, `FFadeFunctionData`, `EWaveEditorFadeMode` | `UTransformationFadeFunction`, `UWaveformTransformationFade` | Waveform Editor |
| `URigHierarchy::FindBone` / `FindControl` / `FindNull` in Blueprint | `Contains(Key)`, `GetBoneType(Key)`, `GetControlSettings(Key)`, `IsSelected(Key)`, `GetIndex(Key)` | Control Rig; existing graphs keep working with warnings |
| `PluginName.ini` / `BasePluginName.ini` in a plugin | `DefaultPluginName.ini` | Plugin config files |
| `r.Water.SingleLayer.ForceVelocity` | `r.Water.SingleLayer.VelocityOutputPass` (or the project setting) | Rendering CVar |
| `EWindowType::GameWindow` | `EWindowType::Normal` | Slate |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| `UE_LOG(...)` | `UE_LOGF(Category, Verbosity, "fmt", ...)` | 尚未弃用：Epic 表示 UE_LOG"最终会被弃用"，并要求使用 `UE_LOGF`。头文件中将其格式说明为 printf 风格的字符串字面量，写作 `"..."` 或 `UTF8TEXT("...")`。5.8 随附 `ConvertUELog.py` 可转换大多数用法 |
| `#if PLATFORM_IOS`（及其他 `PLATFORM_*`） | `#if UE_PLATFORM_IOS`（`UE_PLATFORM_*`） | 可选迁移；`PLATFORM_IOS` 可能被 Apple 框架头文件覆盖 |
| `CppStandardVersion.Cpp17` / `Cpp14` | `CppStandardVersion.Default`（C++20） | 在 5.8 中已废弃：代码无法再使用它们编译 |
| Raw Input 插件（`RawInput`） | Game Input for Windows 插件（`GameInputWindows`，Beta） | `RawInput.uplugin` 中的 `"DeprecatedEngineVersion": "5.8"` |
| PhysicsMover（Mover 插件） | ChaosMover 插件 | 在 5.8 中已被移除，而非仅仅弃用 |
| `FActiveGameplayEffectHandle(int32)` | `FActiveGameplayEffectHandle::GenerateNewHandle` 或 `GetInstantExecutedHandle()` | `UE_DEPRECATED(5.8, ...)` |
| `FSmartName`、`FSmartNameMapping`、`FSmartNameContainer` | 无：请移除相关用法 | `UE_DEPRECATED(5.8, "Smart names and their mappings are no longer used")` |
| `UFadeFunction`、`FFadeFunctionData`、`EWaveEditorFadeMode` | `UTransformationFadeFunction`、`UWaveformTransformationFade` | Waveform Editor |
| 蓝图中的 `URigHierarchy::FindBone` / `FindControl` / `FindNull` | `Contains(Key)`、`GetBoneType(Key)`、`GetControlSettings(Key)`、`IsSelected(Key)`、`GetIndex(Key)` | Control Rig；现有图表仍可工作，但会有警告 |
| 插件中的 `PluginName.ini` / `BasePluginName.ini` | `DefaultPluginName.ini` | 插件配置文件 |
| `r.Water.SingleLayer.ForceVelocity` | `r.Water.SingleLayer.VelocityOutputPass`（或项目设置） | 渲染 CVar |
| `EWindowType::GameWindow` | `EWindowType::Normal` | Slate |

---

## Input
## 输入

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `InputComponent->BindAction()` | Enhanced Input `BindAction()` | New input system |
| `InputComponent->BindAxis()` | Enhanced Input `BindAxis()` | New input system |
| `PlayerController->GetInputAxisValue()` | Enhanced Input Action Values | New input system |

**Migration:** Install Enhanced Input plugin, create Input Actions and Input Mapping Contexts.

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| `InputComponent->BindAction()` | Enhanced Input `BindAction()` | 新输入系统 |
| `InputComponent->BindAxis()` | Enhanced Input `BindAxis()` | 新输入系统 |
| `PlayerController->GetInputAxisValue()` | Enhanced Input Action Values | 新输入系统 |

**迁移：** 安装 Enhanced Input 插件，创建 Input Action 与 Input Mapping Context。

---

## Rendering
## 渲染

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Legacy material nodes | Substrate material nodes | Substrate is production-ready in 5.7 and on by default for new projects |
| Forward shading (default) | Deferred + Lumen | Lumen is default in UE5 |
| Old lighting workflow | Lumen Global Illumination | Real-time GI |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| 旧版材质节点 | Substrate 材质节点 | Substrate 在 5.7 中生产就绪，且新项目默认启用 |
| 前向着色（默认） | 延迟渲染 + Lumen | Lumen 是 UE5 中的默认方案 |
| 旧光照工作流 | Lumen 全局光照 | 实时 GI |

---

## World Building
## 世界构建

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| UE4 World Composition | World Partition (UE5) | Streaming large worlds |
| Level Streaming Volumes | World Partition Data Layers | Better level streaming |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| UE4 World Composition | World Partition（UE5） | 大型世界的流送 |
| Level Streaming Volumes | World Partition Data Layers | 更好的关卡流送 |

---

## Animation
## 动画

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Old animation retargeting | IK Rig + IK Retargeter | UE5 retargeting system |
| Legacy control rig | Control Rig 2.0 | Production-ready rigging |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| 旧动画重定向 | IK Rig + IK Retargeter | UE5 重定向系统 |
| 旧版 Control Rig | Control Rig 2.0 | 生产就绪的绑定 |

---

## Gameplay
## 玩法

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `UGameplayStatics::LoadStreamLevel()` | World Partition streaming | Use Data Layers |
| Hardcoded input bindings | Enhanced Input system | Rebindable, modular input |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| `UGameplayStatics::LoadStreamLevel()` | World Partition 流送 | 使用 Data Layers |
| 硬编码输入绑定 | Enhanced Input 系统 | 可重绑定、模块化输入 |

---

## Gameplay Ability System
## Gameplay Ability System

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `UGameplayAbility::AbilityTags` (direct access) | `GetAssetTags()` to read; `SetAssetTags()` in the constructor to set | `UE_DEPRECATED_FORGAME(5.5, ...)` in the 5.8 header: "This is being made non-mutable, private and renamed to AssetTags in the future" |
| `FActiveGameplayEffectHandle(int32)` | `GenerateNewHandle` / `GetInstantExecutedHandle()` | Deprecated in 5.8 |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| `UGameplayAbility::AbilityTags`（直接访问） | 用 `GetAssetTags()` 读取；在构造函数中用 `SetAssetTags()` 设置 | 5.8 头文件中的 `UE_DEPRECATED_FORGAME(5.5, ...)`："This is being made non-mutable, private and renamed to AssetTags in the future" |
| `FActiveGameplayEffectHandle(int32)` | `GenerateNewHandle` / `GetInstantExecutedHandle()` | 在 5.8 中弃用 |

---

## Niagara (VFX)
## Niagara（视觉特效）

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Cascade particle system | Niagara | Cascade is fully deprecated |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| Cascade 粒子系统 | Niagara | Cascade 已完全弃用 |

---

## Audio
## 音频

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Old audio mixer | MetaSounds | Procedural audio system |
| Sound Cue (for complex logic) | MetaSounds | More powerful, node-based |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| 旧音频混音器 | MetaSounds | 程序化音频系统 |
| Sound Cue（用于复杂逻辑） | MetaSounds | 更强大、基于节点 |

---

## Networking
## 网络

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `DOREPLIFETIME()` (basic) | `DOREPLIFETIME_CONDITION()` | Conditional replication for optimization |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| `DOREPLIFETIME()`（基础版） | `DOREPLIFETIME_CONDITION()` | 用于优化的条件复制 |

---

## C++ Scripting
## C++ 脚本

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `TSharedPtr<T>` for UObjects | `TObjectPtr<T>` | UE5 type-safe pointers |
| Manual RTTI checks | `Cast<T>()` / `IsA<T>()` | Type-safe casting |

| 已弃用 | 替代方案 | 说明 |
|------------|-------------|-------|
| 用于 UObject 的 `TSharedPtr<T>` | `TObjectPtr<T>` | UE5 类型安全指针 |
| 手动 RTTI 检查 | `Cast<T>()` / `IsA<T>()` | 类型安全的类型转换 |

---

## Quick Migration Patterns
## 快速迁移模式

### Input Example
### 输入示例

```cpp
// ❌ Deprecated
void AMyCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
}

// ✅ Enhanced Input
#include "EnhancedInputComponent.h"

void AMyCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent);
    if (EIC) {
        EIC->BindAction(JumpAction, ETriggerEvent::Started, this, &ACharacter::Jump);
    }
}
```

### Material Example
### 材质示例

```cpp
// ❌ Deprecated: Legacy material
// Use standard material graph (still works but not recommended)

// ✅ Substrate Material
// Enable: Project Settings > Engine > Substrate > Enable Substrate
// Use Substrate nodes in material editor
```

### World Partition Example
### World Partition 示例

```cpp
// ❌ Deprecated: Level streaming volumes
// Load/unload levels manually

// ✅ World Partition
// Enable: World Settings > Enable World Partition
// Use Data Layers for streaming
```

### Particle System Example
### 粒子系统示例

```cpp
// ❌ Deprecated: Cascade
UParticleSystemComponent* PSC = CreateDefaultSubobject<UParticleSystemComponent>(TEXT("Particles"));

// ✅ Niagara
UNiagaraComponent* NiagaraComp = CreateDefaultSubobject<UNiagaraComponent>(TEXT("Niagara"));
```

### Audio Example
### 音频示例

```cpp
// ❌ Deprecated: Sound Cue for complex logic
// Use Sound Cue editor nodes

// ✅ MetaSounds
// Create MetaSound Source asset, use node-based audio
```

---

## Summary: UE 5.8 Tech Stack
## 总结：UE 5.8 技术栈

| Feature | Use This (2026) | Avoid This (Legacy) |
|---------|------------------|----------------------|
| **Input** | Enhanced Input | Legacy Input Bindings |
| **Materials** | Substrate | Legacy Material System |
| **Lighting** | Lumen + MegaLights | Lightmaps + Limited Lights |
| **Particles** | Niagara | Cascade |
| **Audio** | MetaSounds | Sound Cue (for logic) |
| **World Streaming** | World Partition | World Composition |
| **Animation Retarget** | IK Rig + Retargeter | Old Retargeting |
| **Geometry** | Nanite (high-poly) | Standard Static Mesh LODs |
| **Logging** | `UE_LOGF` (5.8) | `UE_LOG` (still supported) |
| **Windows device input** | Game Input for Windows | Raw Input plugin (deprecated 5.8) |

| 功能 | 使用此项（2026） | 避免此项（旧版） |
|---------|------------------|----------------------|
| **输入** | Enhanced Input | 旧版输入绑定 |
| **材质** | Substrate | 旧版材质系统 |
| **光照** | Lumen + MegaLights | 光照贴图 + 有限光源 |
| **粒子** | Niagara | Cascade |
| **音频** | MetaSounds | Sound Cue（用于逻辑） |
| **世界流送** | World Partition | World Composition |
| **动画重定向** | IK Rig + Retargeter | 旧重定向方案 |
| **几何** | Nanite（高面数） | 标准静态网格 LOD |
| **日志** | `UE_LOGF`（5.8） | `UE_LOG`（仍受支持） |
| **Windows 设备输入** | Game Input for Windows | Raw Input 插件（5.8 弃用） |

---

**Sources:**
- UE 5.8 release notes, Upgrade Notes and API Change entries: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- 5.8 engine headers, read from a UE 5.8.1 install on 2026-10-17: `Engine/Source/Runtime/Core/Public/Logging/LogMacros.h` (`UE_LOGF`); `Engine/Source/Runtime/Core/Public/HAL/Platform.h` (`UE_PLATFORM_*`); `Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs`; `Engine/Plugins/Experimental/RawInput/RawInput.uplugin` and `Engine/Plugins/GameInputWindows/GameInputWindows.uplugin`; `Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/ActiveGameplayEffectHandle.h` and `.../Public/Abilities/GameplayAbility.h`; `Engine/Source/Runtime/Engine/Classes/Animation/SmartName.h`
- https://docs.unrealengine.com/5.7/en-US/deprecated-and-removed-features/
- https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes

**来源：**
- UE 5.8 发行说明、升级说明与 API 变更条目：https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- 5.8 引擎头文件，于 2026-10-17 从 UE 5.8.1 安装中读取：`Engine/Source/Runtime/Core/Public/Logging/LogMacros.h`（`UE_LOGF`）；`Engine/Source/Runtime/Core/Public/HAL/Platform.h`（`UE_PLATFORM_*`）；`Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs`；`Engine/Plugins/Experimental/RawInput/RawInput.uplugin` 与 `Engine/Plugins/GameInputWindows/GameInputWindows.uplugin`；`Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/ActiveGameplayEffectHandle.h` 与 `.../Public/Abilities/GameplayAbility.h`；`Engine/Source/Runtime/Engine/Classes/Animation/SmartName.h`
- https://docs.unrealengine.com/5.7/en-US/deprecated-and-removed-features/
- https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
