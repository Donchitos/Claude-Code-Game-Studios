# Unreal Engine 5.8 — Breaking Changes
# Unreal Engine 5.8 — 破坏性变更

**Last verified:** 2026-10-17 (UE 5.8 Changes, Substrate/MegaLights versions, Platform-Specific, Migration Checklist); 2026-02-13 (rest of file, written against 5.7)

**最后验证：** 2026-10-17（UE 5.8 变更、Substrate/MegaLights 版本、平台特定内容、迁移检查清单）；2026-02-13（文件其余部分，基于 5.7 编写）

This document tracks breaking API changes and behavioral differences between Unreal Engine 5.3
(likely in model training) and Unreal Engine 5.8 (current version). Organized by risk level.
Changes new in 5.8 come first, under **UE 5.8 Changes**.

本文档跟踪 Unreal Engine 5.3（可能存在于模型训练数据中）与 Unreal Engine 5.8（当前版本）之间的破坏性 API 变更与行为差异。按风险等级组织。5.8 新增的变更排在前面，位于 **UE 5.8 变更** 之下。

## UE 5.8 Changes
## UE 5.8 变更

Sourced from the UE 5.8 release notes (Upgrade Notes and API Change entries) and
the 5.8 engine source; the sources are listed at the end of this file.

来源为 UE 5.8 发行说明（升级说明与 API 变更条目）以及 5.8 引擎源码；来源列于本文档末尾。

### HIGH RISK — Will Break Existing Code
### 高风险 — 会破坏现有代码

| Change | What breaks | Do this |
|--------|-------------|---------|
| **C++20 is the minimum** | A target that sets `CppStandard = CppStandardVersion.Cpp17` (or `Cpp14`): both are now obsolete, "no longer allowed, code will not compile with this version" | Remove the override, or set `CppStandardVersion.Default` (= `Cpp20`) |
| **PhysicsMover removed from Mover** | Code using the unsupported PhysicsMover / NetworkPhysicsLiaison code in the Mover plugin | Use the ChaosMover plugin ("Equivalent functionality is there for every PhysicsMover feature") |
| **Deprecated animation symbols removed** | Non-reflected `UE_DEPRECATED` items from 5.0-5.6 in Animation, Control Rig, Persona and Live Link (e.g. FSmartName-taking constructors, `UMotionWarpingComponent::GetCharacterOwner`) | Use the replacements their deprecation messages named; `GetCharacterOwner` → `GetOwnerAdapter()->GetActor()` / `GetActorOwner()` |
| **`LexToString(bool)` no longer catches other types** | A type that only converted implicitly to `bool` now fails to compile in `LexToString` | Add an explicit cast, or a real `LexToString` overload for the type |
| **MetaSound node metadata** | `FNodeClassMetadata::DefaultInterface` now takes `FClassInterface`, not `FVertexInterface`; deprecated input/output node helpers removed from `IDataTypeRegistry` | Update custom MetaSound node classes |
| **Slate window type** | `EWindowType::GameWindow` | Use `EWindowType::Normal`; a module depending on `SlateRHIRender` may also need `SlateBaseRenderer` |
| **`FSharedEventRef` reset mode** | It used `EEventMode::AutoReset` whatever the constructor argument; `ManualReset` is now honoured | Check call sites that pass `ManualReset` |

| 变更 | 破坏点 | 处理方式 |
|--------|-------------|---------|
| **最低要求 C++20** | 设置了 `CppStandard = CppStandardVersion.Cpp17`（或 `Cpp14`）的目标：两者现已废弃，"不再允许，代码无法使用该版本编译" | 移除该覆盖设置，或设为 `CppStandardVersion.Default`（= `Cpp20`） |
| **Mover 中移除 PhysicsMover** | 使用 Mover 插件中不受支持的 PhysicsMover / NetworkPhysicsLiaison 代码的代码 | 改用 ChaosMover 插件（"每个 PhysicsMover 功能都有等效实现"） |
| **移除已弃用的动画符号** | Animation、Control Rig、Persona 与 Live Link 中来自 5.0-5.6 的非反射 `UE_DEPRECATED` 项（例如接收 FSmartName 的构造函数、`UMotionWarpingComponent::GetCharacterOwner`） | 使用其弃用信息中指定的替代方案；`GetCharacterOwner` → `GetOwnerAdapter()->GetActor()` / `GetActorOwner()` |
| **`LexToString(bool)` 不再捕获其他类型** | 仅能隐式转换为 `bool` 的类型现在在 `LexToString` 中编译失败 | 添加显式类型转换，或为该类型提供真正的 `LexToString` 重载 |
| **MetaSound 节点元数据** | `FNodeClassMetadata::DefaultInterface` 现在接受 `FClassInterface` 而非 `FVertexInterface`；`IDataTypeRegistry` 中已弃用的输入/输出节点辅助函数被移除 | 更新自定义 MetaSound 节点类 |
| **Slate 窗口类型** | `EWindowType::GameWindow` | 使用 `EWindowType::Normal`；依赖 `SlateRHIRender` 的模块可能还需要 `SlateBaseRenderer` |
| **`FSharedEventRef` 重置模式** | 无论构造函数参数为何，它都使用 `EEventMode::AutoReset`；现在 `ManualReset` 会被正确遵循 | 检查传入 `ManualReset` 的调用点 |

### MEDIUM RISK — Behavioral Changes
### 中风险 — 行为变更

- **Windows audio backend**: default switched from XAudio2 to WASAPI (also used on Xbox); XAudio2 stays available as an opt-in fallback. Epic: "No changes are required on the developers end."
- **Mobile renderer**: multi-pass deferred rendering is the default path across mobile platforms; forward rendering is opt-in. Materials with the 'Use Half Precision' override revert to Default (listed in the message log).
- **Zen cooked output**: Zenserver as Cooked Output Store is on by default; an existing project with the Zen store disabled stays off until it is enabled in project settings. `AllowRemoteNetworkService` became `RemoteNetworkService` (`None` / `Unsecured` / `GeneratedStaticKey`, not true/false).
- **Lumen**: height fog is now applied to reflection ray hits by default (`r.Lumen.HeightFog 1`).
- **Audio voice limit**: `au.EnableRelativeRenderCostVoiceLimit` is on by default, so fewer sounds may play under the same voice count; revisit voice-count tuning.
- **Enhanced Input fixes behind CVars**: held keys are ignored on flush (`EnhancedInput.IgnoreHeldKeysOnFlush`, default true) and touch bool action keys are corrected (`EnhancedInput.CorrectTouchBoolActionKeys`, default on). Both CVars "will be removed in a future release".
- **Blueprint local variables**: a function local variable with the same name as a member variable can inherit the wrong default; rename such locals.

- **Windows 音频后端**：默认从 XAudio2 切换为 WASAPI（Xbox 上也使用）；XAudio2 仍可作为可选的回退方案。Epic 表示："开发者端无需任何改动。"
- **移动端渲染器**：多通道延迟渲染成为各移动平台的默认路径；前向渲染变为可选。带有"Use Half Precision"覆盖的材质会恢复为 Default（列于消息日志中）。
- **Zen 烘焙输出**：Zenserver 作为 Cooked Output Store 默认开启；已禁用 Zen 存储的现有项目会保持关闭，直到在项目设置中启用。`AllowRemoteNetworkService` 变为 `RemoteNetworkService`（`None` / `Unsecured` / `GeneratedStaticKey`，而非 true/false）。
- **Lumen**：高度雾现在默认应用于反射光线命中（`r.Lumen.HeightFog 1`）。
- **音频声道上限**：`au.EnableRelativeRenderCostVoiceLimit` 默认开启，因此在相同声道数下可播放的声音可能更少；请重新评估声道数调优。
- **Enhanced Input 的修复置于 CVar 之后**：刷新时会忽略按住的按键（`EnhancedInput.IgnoreHeldKeysOnFlush`，默认 true），触摸布尔动作按键得到修正（`EnhancedInput.CorrectTouchBoolActionKeys`，默认开启）。这两个 CVar "将在未来版本中移除"。
- **蓝图局部变量**：与成员变量同名的函数局部变量可能继承错误的默认值；请重命名此类局部变量。

---

## HIGH RISK — Will Break Existing Code
## 高风险 — 会破坏现有代码

### Substrate Material System (Production-Ready in 5.7)
### Substrate 材质系统（5.7 中生产就绪）

**Versions:** UE 5.5 (Beta), 5.7 (production-ready; enabled automatically for new projects)

**版本：** UE 5.5（Beta）、5.7（生产就绪；新项目自动启用）

Substrate replaces the legacy material system with a modular, physically accurate framework.

Substrate 以模块化、物理准确的框架取代旧版材质系统。

```cpp
// ❌ OLD: Legacy material nodes (still work but deprecated)
// Standard material graph with Base Color, Metallic, Roughness, etc.

// ✅ NEW: Substrate material layers
// Use Substrate nodes: Substrate Slab, Substrate Blend, etc.
// Modular material authoring with true physical accuracy
```

**Migration:** New projects created in 5.7+ start with Substrate on. An existing project keeps its setting: enable it in `Project Settings > Engine > Rendering > Substrate > Substrate materials` (`r.Substrate`, editor restart required) and rebuild materials using Substrate nodes.

**迁移：** 5.7+ 创建的新项目默认开启 Substrate。现有项目保持其设置：在 `Project Settings > Engine > Rendering > Substrate > Substrate materials` 中启用（`r.Substrate`，需要重启编辑器），并使用 Substrate 节点重建材质。

---

### PCG (Procedural Content Generation) API Overhaul
### PCG（程序化内容生成）API 重构

**Versions:** UE 5.7 (production-ready)

**版本：** UE 5.7（生产就绪）

PCG framework reached production-ready status with major API changes.

PCG 框架达到生产就绪状态，同时伴随重大 API 变更。

```cpp
// ❌ OLD: Experimental PCG API (pre-5.7)
// Old node types, unstable API

// ✅ NEW: Production PCG API (5.7+)
// Use FPCGContext, IPCGElement, new node types
// Stable API, production-ready workflow
```

**Migration:** Follow PCG migration guide in 5.7 docs. Expect significant refactoring for experimental PCG code.

**迁移：** 遵循 5.7 文档中的 PCG 迁移指南。实验性 PCG 代码预计需要大量重构。

---

### MegaLights Rendering System
### MegaLights 渲染系统

**Versions:** UE 5.5 (introduced), 5.7 (Beta), 5.8 (production-ready)

**版本：** UE 5.5（引入）、5.7（Beta）、5.8（生产就绪）

New lighting system for many shadow-casting dynamic lights.

面向大量投射阴影的动态光源的新光照系统。

```cpp
// ❌ OLD: Limited dynamic lights (clustered forward shading)
// Max ~100-200 dynamic lights before performance degrades

// ✅ NEW: MegaLights (5.5+, production-ready in 5.8)
// Many shadow-casting lights at a consistent, low GPU cost
// Enable: Project Settings > Engine > Rendering > Direct Lighting > MegaLights
//   (r.MegaLights.EnableForProject, default 0)
```

**Migration:** No code changes needed, but lighting behavior may differ. Test scenes after enabling.

**迁移：** 无需修改代码，但光照行为可能有所不同。启用后请测试场景。

---

## MEDIUM RISK — Behavioral Changes
## 中风险 — 行为变更

### Enhanced Input System (Now Default)
### Enhanced Input 系统（现为默认）

**Versions:** UE 5.1+ (recommended), 5.7 (default)

**版本：** UE 5.1+（推荐）、5.7（默认）

Enhanced Input is now the default input system.

Enhanced Input 现在是默认输入系统。

```cpp
// ❌ OLD: Legacy input bindings (deprecated)
InputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);

// ✅ NEW: Enhanced Input
SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent);
    EIC->BindAction(JumpAction, ETriggerEvent::Started, this, &ACharacter::Jump);
}
```

**Migration:** Replace legacy input bindings with Enhanced Input actions.

**迁移：** 将旧版输入绑定替换为 Enhanced Input 动作。

---

### Nanite Default Enabled
### Nanite 默认启用

**Versions:** UE 5.0+ (optional), 5.7 (encouraged)

**版本：** UE 5.0+（可选）、5.7（推荐采用）

Nanite virtualized geometry is now the recommended workflow for static meshes.

Nanite 虚拟化几何现在是静态网格的推荐工作流。

```cpp
// Enable Nanite on static mesh:
// Static Mesh Editor > Details > Nanite Settings > Enable Nanite Support
```

**Migration:** Convert high-poly meshes to Nanite. Test performance on target platforms.

**迁移：** 将高面数网格转换为 Nanite。在目标平台上测试性能。

---

## LOW RISK — Deprecations (Still Functional)
## 低风险 — 弃用（仍然可用）

### Legacy Material System
### 旧版材质系统

**Status:** Deprecated but supported
**Replacement:** Substrate Material System

**状态：** 已弃用但受支持
**替代方案：** Substrate 材质系统

Legacy materials still work, but Substrate is recommended for new projects.

旧版材质仍然可用，但新项目推荐使用 Substrate。

---

### Old World Partition (UE4 Style)
### 旧版 World Partition（UE4 风格）

**Status:** Deprecated
**Replacement:** World Partition (UE5+)

**状态：** 已弃用
**替代方案：** World Partition（UE5+）

Use UE5's World Partition system for large worlds.

大型世界请使用 UE5 的 World Partition 系统。

---

## Platform-Specific Breaking Changes
## 平台特定的破坏性变更

UE 5.8 toolchain and SDK requirements come from the 5.8 release notes'
*Platform SDK Upgrades* table.

UE 5.8 的工具链与 SDK 要求来自 5.8 发行说明的 *Platform SDK Upgrades* 表。

### Windows
### Windows

- **UE 5.8**: Visual Studio 2022 v17.14 or newer is the minimum; Visual Studio 2026 is recommended (MSVC 14.38 minimum, 14.50 recommended)
- **UE 5.8**: Windows SDK 10.0.22621.0 minimum, 10.0.26100.0 default; LLVM Clang 18.1.8 minimum
- **UE 5.7**: DirectX 12 is now default (was DX11 in older versions)
- Update shaders for DX12 compatibility

- **UE 5.8**：最低要求 Visual Studio 2022 v17.14 或更新版本；推荐 Visual Studio 2026（MSVC 最低 14.38，推荐 14.50）
- **UE 5.8**：Windows SDK 最低 10.0.22621.0，默认 10.0.26100.0；LLVM Clang 最低 18.1.8
- **UE 5.7**：DirectX 12 现为默认（旧版本中使用 DX11）
- 为兼容 DX12 更新着色器

### macOS
### macOS

- **UE 5.5+**: Metal 3 required (minimum macOS 13)
- **UE 5.8**: Minimum OS macOS Sonoma 14.0; Xcode 15.2 minimum, 15.4 or newer recommended (macOS target)

- **UE 5.5+**：要求 Metal 3（最低 macOS 13）
- **UE 5.8**：最低操作系统 macOS Sonoma 14.0；Xcode 最低 15.2，推荐 15.4 或更新版本（macOS 目标）

### Linux
### Linux

- **UE 5.8**: Ubuntu 22.04, Rocky Linux 8 or Red Hat Linux 8 or newer recommended; compiler clang 20.1.8

- **UE 5.8**：推荐 Ubuntu 22.04、Rocky Linux 8 或 Red Hat Linux 8 及更新版本；编译器 clang 20.1.8

### Mobile
### 移动端

- **UE 5.8**: Android minimum install SDK level 26 (Android 8.0+); NDK r27c; minimum SDK for compiling UE 34, recommended 35; Gradle 8.7, AGP 8.5.2
- **UE 5.8**: iOS / iPadOS / tvOS SDK 17 or later; Xcode 26.0 minimum, 26.1.1 recommended (iOS targets)
- **UE 5.8**: iOS Shader Model 6 is Experimental

- **UE 5.8**：Android 最低安装 SDK 级别 26（Android 8.0+）；NDK r27c；编译 UE 的最低 SDK 为 34，推荐 35；Gradle 8.7、AGP 8.5.2
- **UE 5.8**：iOS / iPadOS / tvOS SDK 17 或更高；Xcode 最低 26.0，推荐 26.1.1（iOS 目标）
- **UE 5.8**：iOS Shader Model 6 为实验性

---

## Migration Checklist
## 迁移检查清单

When upgrading from UE 5.3 to UE 5.8:

从 UE 5.3 升级到 UE 5.8 时：

- [ ] Remove any `CppStandardVersion.Cpp17` / `Cpp14` override (5.8 requires C++20)
- [ ] Install a 5.8 toolchain (Visual Studio 2022 17.14+ or 2026 on Windows; Xcode 26 for iOS)
- [ ] Move PhysicsMover usage to ChaosMover
- [ ] Rebuild and fix calls to deprecated APIs removed in 5.8 (see **UE 5.8 Changes**)
- [ ] Review Substrate materials (convert if ready for new system)
- [ ] Audit PCG usage (update to production API if using experimental)
- [ ] Test MegaLights performance (enable and benchmark)
- [ ] Migrate legacy input to Enhanced Input
- [ ] Convert high-poly meshes to Nanite
- [ ] Update shaders for DX12 (Windows) or Metal 3 (macOS)
- [ ] Verify minimum platform versions (5.8: Android install SDK 26 / Android 8.0, iOS SDK 17, macOS Sonoma 14)
- [ ] Test Lumen and Nanite performance on target hardware

- [ ] 移除所有 `CppStandardVersion.Cpp17` / `Cpp14` 覆盖设置（5.8 要求 C++20）
- [ ] 安装 5.8 工具链（Windows 上 Visual Studio 2022 17.14+ 或 2026；iOS 需 Xcode 26）
- [ ] 将 PhysicsMover 的用法迁移到 ChaosMover
- [ ] 重新构建并修复对 5.8 中已移除的弃用 API 的调用（见 **UE 5.8 变更**）
- [ ] 审查 Substrate 材质（如已准备好采用新系统则进行转换）
- [ ] 审计 PCG 用法（若使用实验性版本则更新到生产 API）
- [ ] 测试 MegaLights 性能（启用并做基准测试）
- [ ] 将旧版输入迁移到 Enhanced Input
- [ ] 将高面数网格转换为 Nanite
- [ ] 为 DX12（Windows）或 Metal 3（macOS）更新着色器
- [ ] 核实最低平台版本（5.8：Android 安装 SDK 26 / Android 8.0、iOS SDK 17、macOS Sonoma 14）
- [ ] 在目标硬件上测试 Lumen 与 Nanite 性能

---

**Sources:**
- UE 5.8 release notes (Upgrade Notes, API Change entries, Platform SDK Upgrades, WASAPI, Mobile Renderer, Zenserver as Cooked Output Store): https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- 5.8 engine source, read from a UE 5.8.1 install on 2026-10-17: `Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs` (`Cpp14`/`Cpp17` marked `[Obsolete("Deprecated in UE5.8 ...")]`, `Minimum = Cpp20`); `Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp` (Substrate defaults for new and existing projects); `Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h` and `Engine/Source/Runtime/Renderer/Private/MegaLights/MegaLights.cpp` (MegaLights setting and default)
- Substrate Beta in 5.5, MegaLights Beta in 5.7: https://forums.unrealengine.com/t/unreal-engine-5-5-released/2117936 , https://forums.unrealengine.com/t/unreal-engine-5-7-released/2673913
- https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
- https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-projects-to-newer-versions-of-unreal-engine

**来源：**
- UE 5.8 发行说明（升级说明、API 变更条目、Platform SDK Upgrades、WASAPI、Mobile Renderer、Zenserver as Cooked Output Store）：https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- 5.8 引擎源码，于 2026-10-17 从 UE 5.8.1 安装中读取：`Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs`（`Cpp14`/`Cpp17` 标记为 `[Obsolete("Deprecated in UE5.8 ...")]`，`Minimum = Cpp20`）；`Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp`（新项目与现有项目的 Substrate 默认值）；`Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h` 与 `Engine/Source/Runtime/Renderer/Private/MegaLights/MegaLights.cpp`（MegaLights 设置与默认值）
- 5.5 中的 Substrate Beta、5.7 中的 MegaLights Beta：https://forums.unrealengine.com/t/unreal-engine-5-5-released/2117936 ，https://forums.unrealengine.com/t/unreal-engine-5-7-released/2673913
- https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
- https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-projects-to-newer-versions-of-unreal-engine
