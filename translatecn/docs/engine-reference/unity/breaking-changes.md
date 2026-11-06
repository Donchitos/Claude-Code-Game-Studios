# Unity 6.3 LTS — Breaking Changes
# Unity 6.3 LTS — 破坏性变更

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13

This document tracks breaking API changes and behavioral differences between Unity 2022 LTS
(likely in model training) and Unity 6.3 LTS (current version). Organized by risk level.

本文档跟踪 Unity 2022 LTS（可能包含在模型训练数据中）与 Unity 6.3 LTS（当前版本）之间的破坏性 API 变更与行为差异。按风险等级组织。

## HIGH RISK — Will Break Existing Code
## 高风险 — 会破坏现有代码

### Entities/DOTS API Complete Overhaul
### Entities/DOTS API 全面重构
**Versions:** Entities 1.0+ (Unity 6.0+)
**版本：** Entities 1.0+（Unity 6.0+）

```csharp
// ❌ OLD (pre-Unity 6, GameObjectEntity pattern)
public class HealthComponent : ComponentData {
    public float Value;
}

// ✅ NEW (Unity 6+, IComponentData)
public struct HealthComponent : IComponentData {
    public float Value;
}

// ❌ OLD: ComponentSystem
public class DamageSystem : ComponentSystem { }

// ✅ NEW: ISystem (unmanaged, Burst-compatible)
public partial struct DamageSystem : ISystem {
    public void OnCreate(ref SystemState state) { }
    public void OnUpdate(ref SystemState state) { }
}
```

**Migration:** Follow Unity's ECS migration guide. Major architectural changes required.

**迁移：** 遵循 Unity 的 ECS 迁移指南。需要进行重大架构调整。

---

### Input System — Legacy Input Deprecated
### Input System — 旧版输入已弃用
**Versions:** Unity 6.0+
**版本：** Unity 6.0+

```csharp
// ❌ OLD: Input class (deprecated)
if (Input.GetKeyDown(KeyCode.Space)) { }

// ✅ NEW: Input System package
using UnityEngine.InputSystem;
if (Keyboard.current.spaceKey.wasPressedThisFrame) { }
```

**Migration:** Install Input System package, replace all `Input.*` calls with new API.

**迁移：** 安装 Input System 包，将所有 `Input.*` 调用替换为新 API。

---

### URP/HDRP Renderer Feature API Changes
### URP/HDRP 渲染器功能（Renderer Feature）API 变更
**Versions:** Unity 6.0+
**版本：** Unity 6.0+

```csharp
// ❌ OLD: ScriptableRenderPass.Execute signature
public override void Execute(ScriptableRenderContext context, ref RenderingData data)

// ✅ NEW: Uses RenderGraph API
public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
```

**Migration:** Update custom render passes to use RenderGraph API.

**迁移：** 将自定义渲染通道（render pass）更新为使用 RenderGraph API。

---

## MEDIUM RISK — Behavioral Changes
## 中等风险 — 行为变更

### Addressables — Asset Loading Returns
### Addressables — 资源加载返回值
**Versions:** Unity 6.2+
**版本：** Unity 6.2+

Asset loading failures now throw exceptions by default instead of returning null.
Add proper exception handling or use `TryLoad` variants.

资源加载失败现在默认抛出异常，而不再返回 null。请添加适当的异常处理，或使用 `TryLoad` 变体。

```csharp
// ❌ OLD: Silent null on failure
var handle = Addressables.LoadAssetAsync<Sprite>("key");
var sprite = handle.Result; // null if failed

// ✅ NEW: Throws on failure, use try/catch or TryLoad
try {
    var handle = Addressables.LoadAssetAsync<Sprite>("key");
    var sprite = await handle.Task;
} catch (Exception e) {
    Debug.LogError($"Failed to load: {e}");
}
```

---

### Physics — Default Solver Iterations Changed
### 物理 — 默认求解器迭代次数变更
**Versions:** Unity 6.0+
**版本：** Unity 6.0+

Default solver iterations increased for better stability.
Check `Physics.defaultSolverIterations` if you rely on old behavior.

为提升稳定性，默认求解器迭代次数已提高。如果你依赖旧行为，请检查 `Physics.defaultSolverIterations`。

---

## LOW RISK — Deprecations (Still Functional)
## 低风险 — 弃用（仍然可用）

### UGUI (Legacy UI)
### UGUI（旧版 UI）
**Status:** Deprecated but supported
**Replacement:** UI Toolkit

**状态：** 已弃用但仍受支持
**替代方案：** UI Toolkit

UGUI still works but UI Toolkit is recommended for new projects.

UGUI 仍然可用，但新项目推荐使用 UI Toolkit。

---

### Legacy Particle System
### 旧版粒子系统
**Status:** Deprecated
**Replacement:** Visual Effect Graph (VFX Graph)

**状态：** 已弃用
**替代方案：** Visual Effect Graph（VFX Graph）

---

### Old Animation System
### 旧版动画系统
**Status:** Deprecated
**Replacement:** Animator Controller (Mecanim)

**状态：** 已弃用
**替代方案：** Animator Controller（Mecanim）

---

## Platform-Specific Breaking Changes
## 平台特定的破坏性变更

### WebGL
### WebGL
- **Unity 6.0+**: WebGPU is now the default (WebGL 2.0 fallback available)
- Update shaders for WebGPU compatibility

- **Unity 6.0+**：WebGPU 现为默认选项（可回退至 WebGL 2.0）
- 更新着色器以兼容 WebGPU

### Android
### Android
- **Unity 6.0+**: Minimum API level raised to 24 (Android 7.0)

- **Unity 6.0+**：最低 API 级别提高到 24（Android 7.0）

### iOS
### iOS
- **Unity 6.0+**: Minimum deployment target raised to iOS 13

- **Unity 6.0+**：最低部署目标提高到 iOS 13

---

## Migration Checklist
## 迁移清单

When upgrading from 2022 LTS to Unity 6.3 LTS:

- [ ] Audit all DOTS/ECS code (complete rewrite likely needed)
- [ ] Replace `Input` class with Input System package
- [ ] Update custom render passes to RenderGraph API
- [ ] Add exception handling to Addressables calls
- [ ] Test physics behavior (solver iterations changed)
- [ ] Consider migrating UGUI to UI Toolkit for new UI
- [ ] Update WebGL shaders for WebGPU
- [ ] Verify minimum platform versions (Android/iOS)

从 2022 LTS 升级到 Unity 6.3 LTS 时：

- [ ] 审计所有 DOTS/ECS 代码（很可能需要完全重写）
- [ ] 用 Input System 包替换 `Input` 类
- [ ] 将自定义渲染通道更新为 RenderGraph API
- [ ] 为 Addressables 调用添加异常处理
- [ ] 测试物理行为（求解器迭代次数已变更）
- [ ] 考虑为新 UI 将 UGUI 迁移到 UI Toolkit
- [ ] 更新 WebGL 着色器以支持 WebGPU
- [ ] 核实最低平台版本（Android/iOS）

---

**Sources:**
- https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/upgrade-guide.html

**来源：**
- https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/upgrade-guide.html
