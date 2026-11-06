# Unity 6.3 LTS — Deprecated APIs
# Unity 6.3 LTS — 弃用的 API

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13

Quick lookup table for deprecated APIs and their replacements.
Format: **Don't use X** → **Use Y instead**

弃用 API 及其替代方案的快速查询表。
格式：**不要使用 X** → **改用 Y**

---

## Input
## 输入

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `Input.GetKey()` | `Keyboard.current[Key.X].isPressed` | New Input System |
| `Input.GetKeyDown()` | `Keyboard.current[Key.X].wasPressedThisFrame` | New Input System |
| `Input.GetMouseButton()` | `Mouse.current.leftButton.isPressed` | New Input System |
| `Input.GetAxis()` | `InputAction` callbacks | New Input System |
| `Input.mousePosition` | `Mouse.current.position.ReadValue()` | New Input System |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `Input.GetKey()` | `Keyboard.current[Key.X].isPressed` | 新 Input System |
| `Input.GetKeyDown()` | `Keyboard.current[Key.X].wasPressedThisFrame` | 新 Input System |
| `Input.GetMouseButton()` | `Mouse.current.leftButton.isPressed` | 新 Input System |
| `Input.GetAxis()` | `InputAction` 回调 | 新 Input System |
| `Input.mousePosition` | `Mouse.current.position.ReadValue()` | 新 Input System |

**Migration:** Install `com.unity.inputsystem` package.

**迁移：** 安装 `com.unity.inputsystem` 包。

---

## UI
## UI

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `Canvas` (UGUI) | `UIDocument` (UI Toolkit) | UI Toolkit is now production-ready |
| `Text` component | `TextMeshPro` or UI Toolkit `Label` | Better rendering, fewer draw calls |
| `Image` component | UI Toolkit `VisualElement` with background | More flexible styling |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `Canvas`（UGUI） | `UIDocument`（UI Toolkit） | UI Toolkit 现已生产就绪 |
| `Text` 组件 | `TextMeshPro` 或 UI Toolkit 的 `Label` | 渲染效果更好，绘制调用更少 |
| `Image` 组件 | 带背景的 UI Toolkit `VisualElement` | 样式更灵活 |

**Migration:** UGUI still works, but UI Toolkit is recommended for new projects.

**迁移：** UGUI 仍然可用，但新项目推荐使用 UI Toolkit。

---

## DOTS/Entities
## DOTS/Entities

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `ComponentSystem` | `ISystem` (unmanaged) | Entities 1.0+ complete rewrite |
| `JobComponentSystem` | `ISystem` with `IJobEntity` | Burst-compatible |
| `GameObjectEntity` | Pure ECS workflow | No GameObject conversion |
| `EntityManager.CreateEntity()` (old signature) | `EntityManager.CreateEntity(EntityArchetype)` | Explicit archetype |
| `ComponentDataFromEntity<T>` | `ComponentLookup<T>` | Entities 1.0+ rename |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `ComponentSystem` | `ISystem`（非托管） | Entities 1.0+ 完全重写 |
| `JobComponentSystem` | 配合 `IJobEntity` 的 `ISystem` | 兼容 Burst |
| `GameObjectEntity` | 纯 ECS 工作流 | 无需 GameObject 转换 |
| `EntityManager.CreateEntity()`（旧签名） | `EntityManager.CreateEntity(EntityArchetype)` | 显式指定原型 |
| `ComponentDataFromEntity<T>` | `ComponentLookup<T>` | Entities 1.0+ 中的重命名 |

**Migration:** See Entities package migration guide. Major refactor required.

**迁移：** 参见 Entities 包迁移指南。需要进行重大重构。

---

## Rendering
## 渲染

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `CommandBuffer.DrawMesh()` | RenderGraph API | URP/HDRP render passes |
| `OnPreRender()` / `OnPostRender()` | `RenderPipelineManager` callbacks | SRP compatibility |
| `Camera.SetReplacementShader()` | Custom render pass | Not supported in SRP |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `CommandBuffer.DrawMesh()` | RenderGraph API | URP/HDRP 渲染通道 |
| `OnPreRender()` / `OnPostRender()` | `RenderPipelineManager` 回调 | 兼容 SRP |
| `Camera.SetReplacementShader()` | 自定义渲染通道 | SRP 中不支持 |

---

## Physics
## 物理

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `Physics.RaycastAll()` | `Physics.RaycastNonAlloc()` | Avoid GC allocations |
| `Rigidbody.velocity` (direct write) | `Rigidbody.AddForce()` | Better physics stability |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `Physics.RaycastAll()` | `Physics.RaycastNonAlloc()` | 避免 GC 分配 |
| `Rigidbody.velocity`（直接赋值） | `Rigidbody.AddForce()` | 更好的物理稳定性 |

---

## Asset Loading
## 资源加载

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `Resources.Load()` | Addressables | Better memory control, async loading |
| Synchronous asset loading | `Addressables.LoadAssetAsync()` | Non-blocking |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `Resources.Load()` | Addressables | 更好的内存控制、异步加载 |
| 同步资源加载 | `Addressables.LoadAssetAsync()` | 非阻塞 |

---

## Animation
## 动画

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Legacy Animation component | Animator Controller | Mecanim system |
| `Animation.Play()` | `Animator.Play()` | State machine control |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| 旧版 Animation 组件 | Animator Controller | Mecanim 系统 |
| `Animation.Play()` | `Animator.Play()` | 状态机控制 |

---

## Particles
## 粒子

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Legacy Particle System | Visual Effect Graph | GPU-accelerated, more performant |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| 旧版粒子系统 | Visual Effect Graph | GPU 加速，性能更佳 |

---

## Scripting
## 脚本

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `WWW` class | `UnityWebRequest` | Modern async networking |
| `Application.LoadLevel()` | `SceneManager.LoadScene()` | Scene management |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| `WWW` 类 | `UnityWebRequest` | 现代异步网络 |
| `Application.LoadLevel()` | `SceneManager.LoadScene()` | 场景管理 |

---

## Platform-Specific
## 平台特定

### WebGL
### WebGL
| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| WebGL 1.0 | WebGL 2.0 or WebGPU | Unity 6+ defaults to WebGPU |

| 弃用 | 替代方案 | 备注 |
|------------|-------------|-------|
| WebGL 1.0 | WebGL 2.0 或 WebGPU | Unity 6+ 默认使用 WebGPU |

---

## Quick Migration Patterns
## 快速迁移模式

### Input Example
### 输入示例
```csharp
// ❌ Deprecated
if (Input.GetKeyDown(KeyCode.Space)) {
    Jump();
}

// ✅ New Input System
using UnityEngine.InputSystem;
if (Keyboard.current.spaceKey.wasPressedThisFrame) {
    Jump();
}
```

### Asset Loading Example
### 资源加载示例
```csharp
// ❌ Deprecated
var prefab = Resources.Load<GameObject>("Enemies/Goblin");

// ✅ Addressables
var handle = Addressables.LoadAssetAsync<GameObject>("Enemies/Goblin");
await handle.Task;
var prefab = handle.Result;
```

### UI Example
### UI 示例
```csharp
// ❌ Deprecated (UGUI)
GetComponent<Text>().text = "Score: 100";

// ✅ TextMeshPro
GetComponent<TextMeshProUGUI>().text = "Score: 100";

// ✅ UI Toolkit
rootVisualElement.Q<Label>("score-label").text = "Score: 100";
```

---

**Sources:**
- https://docs.unity3d.com/6000.0/Documentation/Manual/deprecated-features.html
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Migration.html

**来源：**
- https://docs.unity3d.com/6000.0/Documentation/Manual/deprecated-features.html
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Migration.html
