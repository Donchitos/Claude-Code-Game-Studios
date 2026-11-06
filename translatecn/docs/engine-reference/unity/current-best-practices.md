# Unity 6.3 LTS — Current Best Practices
# Unity 6.3 LTS — 当前最佳实践

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13

Modern Unity 6 patterns that may not be in the LLM's training data.
These are production-ready recommendations as of Unity 6.3 LTS.

可能未被 LLM 训练数据收录的现代 Unity 6 模式。这些是截至 Unity 6.3 LTS 的生产就绪建议。

---

## Project Setup
## 项目设置

### Use Unity 6.3 LTS for Production
### 生产环境使用 Unity 6.3 LTS
- **Supported Update releases** (6.4+): Latest features, supported only until the next one ships
- **LTS** (6.3): Production-ready, 2-year support (until Dec 2027)

- **受支持更新版本（Supported Update）**（6.4+）：具备最新特性，仅支持到下一个版本发布为止
- **LTS**（6.3）：生产就绪，两年支持（至 2027 年 12 月）

### Choose the Right Render Pipeline
### 选择合适的渲染管线
- **URP (Universal)**: Mobile, cross-platform, good performance ✅ Recommended for most games
- **HDRP (High Definition)**: High-end PC/console, photorealistic
- **Built-in**: Deprecated, avoid for new projects

- **URP（通用）**：移动端、跨平台、性能良好 ✅ 推荐用于大多数游戏
- **HDRP（高清）**：高端 PC/主机、照片级写实
- **Built-in（内置）**：已弃用，新项目应避免使用

---

## Scripting
## 脚本

### Use C# 9+ Features (Unity 6 Supports C# 9)
### 使用 C# 9+ 特性（Unity 6 支持 C# 9）

```csharp
// ✅ Record types for data
public record PlayerData(string Name, int Level, float Health);

// ✅ Init-only properties
public class Config {
    public string GameMode { get; init; }
}

// ✅ Pattern matching
var result = enemy switch {
    Boss boss => boss.Enrage(),
    Minion minion => minion.Flee(),
    _ => null
};
```

### Async/Await for Asset Loading
### 使用 Async/Await 进行资源加载

```csharp
// ✅ Modern async pattern
public async Task<GameObject> LoadEnemyAsync(string key) {
    var handle = Addressables.LoadAssetAsync<GameObject>(key);
    return await handle.Task;
}
```

### Use Source Generators for Serialization (Unity 6+)
### 使用源生成器进行序列化（Unity 6+）

```csharp
// ✅ Source-generated serialization (faster, less reflection)
[GenerateSerializer]
public partial struct PlayerStats : IComponentData {
    public int Health;
    public int Mana;
}
```

---

## DOTS/ECS (Production-Ready in Unity 6.3 LTS)
## DOTS/ECS（在 Unity 6.3 LTS 中已生产就绪）

### Use ISystem (Not ComponentSystem)
### 使用 ISystem（而非 ComponentSystem）

```csharp
// ✅ Modern unmanaged ISystem (Burst-compatible)
public partial struct MovementSystem : ISystem {
    public void OnCreate(ref SystemState state) { }

    public void OnUpdate(ref SystemState state) {
        foreach (var (transform, speed) in
            SystemAPI.Query<RefRW<LocalTransform>, RefRO<MoveSpeed>>()) {
            transform.ValueRW.Position += speed.ValueRO.Value * SystemAPI.Time.DeltaTime;
        }
    }
}
```

### Use IJobEntity for Parallel Jobs
### 使用 IJobEntity 实现并行 Job

```csharp
// ✅ IJobEntity (replaces IJobForEach)
[BurstCompile]
public partial struct DamageJob : IJobEntity {
    public float DeltaTime;

    void Execute(ref Health health, in DamageOverTime dot) {
        health.Value -= dot.DamagePerSecond * DeltaTime;
    }
}

// Schedule it
var job = new DamageJob { DeltaTime = SystemAPI.Time.DeltaTime };
job.ScheduleParallel();
```

---

## Input
## 输入

### Use Input System Package (Not Legacy Input)
### 使用 Input System 包（而非旧版输入）

```csharp
// ✅ Input Actions (rebindable, cross-platform)
using UnityEngine.InputSystem;

public class PlayerInput : MonoBehaviour {
    private PlayerControls controls;

    void Awake() {
        controls = new PlayerControls();
        controls.Gameplay.Jump.performed += ctx => Jump();
    }

    void OnEnable() => controls.Enable();
    void OnDisable() => controls.Disable();
}
```

Create Input Actions asset in editor, generate C# class via inspector.

在编辑器中创建 Input Actions 资源，并通过检视面板（inspector）生成 C# 类。

---

## UI
## UI

### Use UI Toolkit for Runtime UI (Production-Ready in Unity 6)
### 使用 UI Toolkit 构建运行时 UI（在 Unity 6 中已生产就绪）

```csharp
// ✅ UI Toolkit (replaces UGUI for new projects)
using UnityEngine.UIElements;

public class MainMenu : MonoBehaviour {
    void OnEnable() {
        var root = GetComponent<UIDocument>().rootVisualElement;

        var playButton = root.Q<Button>("play-button");
        playButton.clicked += StartGame;

        var scoreLabel = root.Q<Label>("score");
        scoreLabel.text = $"High Score: {PlayerPrefs.GetInt("HighScore")}";
    }
}
```

**UXML** (UI structure) + **USS** (styling) = HTML/CSS-like workflow.

**UXML**（UI 结构）+ **USS**（样式）= 类似 HTML/CSS 的工作流。

---

## Asset Management
## 资源管理

### Use Addressables (Not Resources)
### 使用 Addressables（而非 Resources）

```csharp
// ✅ Addressables (async, memory-efficient)
using UnityEngine.AddressableAssets;

public async Task SpawnEnemyAsync(string enemyKey) {
    var handle = Addressables.InstantiateAsync(enemyKey);
    var enemy = await handle.Task;

    // Cleanup: release when destroyed
    Addressables.ReleaseInstance(enemy);
}
```

**Benefits:** Async loading, remote content delivery, better memory control.

**优势：** 异步加载、远程内容分发、更好的内存控制。

---

## Rendering
## 渲染

### Use RenderGraph API for Custom Passes (URP/HDRP)
### 使用 RenderGraph API 实现自定义通道（URP/HDRP）

```csharp
// ✅ RenderGraph API (Unity 6+)
public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData) {
    using (var builder = renderGraph.AddRasterRenderPass<PassData>("My Pass", out var passData)) {
        // Setup pass
        builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            // Execute commands
        });
    }
}
```

**Replaces:** Old `CommandBuffer.Execute()` pattern.

**替代：** 旧的 `CommandBuffer.Execute()` 模式。

**This is URP's API.** `RecordRenderGraph` overrides URP's `ScriptableRenderPass`.
HDRP custom passes are a separate API: a `CustomPass` subclass, run from a Custom
Pass Volume, overrides `Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)`,
`Execute(CustomPassContext ctx)` and `Cleanup()` (HDRP 17.3, *Create a Custom
Pass in a C# script*:
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@17.3/manual/Custom-Pass-Scripting.html).

**这是 URP 的 API。** `RecordRenderGraph` 重写的是 URP 的 `ScriptableRenderPass`。HDRP 的自定义通道是另一套 API：`CustomPass` 子类由 Custom Pass Volume 运行，重写 `Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)`、`Execute(CustomPassContext ctx)` 和 `Cleanup()`（HDRP 17.3，*Create a Custom Pass in a C# script*：https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@17.3/manual/Custom-Pass-Scripting.html）。

---

## Performance
## 性能

### Use Burst Compiler + Jobs System
### 使用 Burst 编译器 + Jobs System

```csharp
// ✅ Burst-compiled job (massive performance gain)
[BurstCompile]
struct ParticleUpdateJob : IJobParallelFor {
    public NativeArray<float3> Positions;
    public NativeArray<float3> Velocities;
    public float DeltaTime;

    public void Execute(int index) {
        Positions[index] += Velocities[index] * DeltaTime;
    }
}

// Schedule
var job = new ParticleUpdateJob {
    Positions = positions,
    Velocities = velocities,
    DeltaTime = Time.deltaTime
};
job.Schedule(positions.Length, 64).Complete();
```

**20-100x faster** than equivalent C# code.

比等价的 C# 代码**快 20-100 倍**。

---

### Use GPU Instancing for Repeated Objects
### 对重复对象使用 GPU 实例化

```csharp
// ✅ GPU Instancing (thousands of objects, minimal draw calls)
Graphics.RenderMeshInstanced(
    new RenderParams(material),
    mesh,
    0,
    matrices // NativeArray<Matrix4x4>
);
```

---

## Memory Management
## 内存管理

### Use NativeContainers (Not Managed Arrays in Jobs)
### 使用 NativeContainers（而非 Job 中的托管数组）

```csharp
// ✅ NativeArray (no GC, Burst-compatible)
NativeArray<int> data = new NativeArray<int>(1000, Allocator.TempJob);
// ... use in job
data.Dispose(); // Manual cleanup required

// ✅ Or use using statement
using var data = new NativeArray<int>(1000, Allocator.TempJob);
// Auto-disposed
```

---

## Multiplayer
## 多人游戏

### Use Netcode for GameObjects (Official)
### 使用 Netcode for GameObjects（官方）

```csharp
// ✅ Unity's official netcode
using Unity.Netcode;

public class Player : NetworkBehaviour {
    private NetworkVariable<int> health = new NetworkVariable<int>(100);

    [ServerRpc]
    public void TakeDamageServerRpc(int damage) {
        health.Value -= damage;
    }
}
```

**Replaces:** UNet (deprecated), MLAPI (renamed to Netcode for GameObjects).

**替代：** UNet（已弃用）、MLAPI（已更名为 Netcode for GameObjects）。

---

## Testing
## 测试

### Use Unity Test Framework (NUnit-based)
### 使用 Unity Test Framework（基于 NUnit）

```csharp
// ✅ Play Mode Test
[UnityTest]
public IEnumerator Player_TakesDamage_HealthDecreases() {
    var player = new GameObject().AddComponent<Player>();
    player.Health = 100;

    player.TakeDamage(25);
    yield return null; // Wait one frame

    Assert.AreEqual(75, player.Health);
}
```

---

## Command Line — Tests
## 命令行 — 测试

Documented (Unity Manual, *Run tests from the command line*; Test Framework
command-line reference):
`<Unity editor> -runTests -batchmode -projectPath <path> -testPlatform <platform> -testResults <file>`.
`-batchmode` removes the need for user input. `-testPlatform` takes `EditMode`,
`PlayMode` (Play Mode tests in the Editor) or a player platform; with no value,
tests run in Edit Mode. `-testResults` defaults to the project root, and the
file follows NUnit's XML format: the `<test-run>` element carries
`testcasecount`, `result`, `passed` and `failed`, and each `<test-case>` a
`fullname` and a `result` of `Passed`, `Failed`, `Inconclusive` or `Skipped`.
Unity defines no common exit codes for test runs.

文档记载（Unity 手册，*Run tests from the command line*；Test Framework 命令行参考）：`<Unity editor> -runTests -batchmode -projectPath <path> -testPlatform <platform> -testResults <file>`。`-batchmode` 免除了用户输入的需要。`-testPlatform` 接受 `EditMode`、`PlayMode`（在编辑器中运行播放模式测试）或某个播放器平台；若不给值，测试在编辑模式下运行。`-testResults` 默认写入项目根目录，文件遵循 NUnit 的 XML 格式：`<test-run>` 元素带有 `testcasecount`、`result`、`passed` 和 `failed`，每个 `<test-case>` 带有 `fullname` 以及取值为 `Passed`、`Failed`、`Inconclusive` 或 `Skipped` 的 `result`。Unity 并未为测试运行定义通用的退出码。

Observed on Unity 6000.3.23f1 — not in the docs:
- `-runTests` exits 0 when every test passes and 2 when one fails; 1 is a
  compile error (no results file is written), 3 a failed run, 4 an unknown
  `-testPlatform`. It exits by itself — no `-quit`.
- Tests outside `Assets/` are never compiled: the run reports
  `testcasecount="0"`, `result="Passed"` and exits 0 — a false pass.
- Without the `com.unity.test-framework` package, `-runTests` hangs rather
  than failing.
- `Unity` on `PATH` may be Unity's separate CLI, not the editor; it rejects
  `-batchmode` and `-version` with exit 2. Name the editor executable by its
  full path.
- `-batchmode -quit -projectPath . -logFile -` exits 1 on a compile error and
  0 when clean.

在 Unity 6000.3.23f1 上观察到 — 文档中并无记载：
- 所有测试通过时 `-runTests` 退出码为 0，有一个测试失败时为 2；1 表示编译错误（不会写出结果文件），3 表示运行失败，4 表示未知的 `-testPlatform`。它会自行退出 — 无需 `-quit`。
- `Assets/` 之外的测试永远不会被编译：运行会报告 `testcasecount="0"`、`result="Passed"` 并以 0 退出 — 这是一次虚假的通过。
- 未安装 `com.unity.test-framework` 包时，`-runTests` 会挂起而非失败。
- `PATH` 上的 `Unity` 可能是 Unity 独立的 CLI，而非编辑器；它会以退出码 2 拒绝 `-batchmode` 和 `-version`。请使用完整路径指定编辑器可执行文件。
- `-batchmode -quit -projectPath . -logFile -` 在编译错误时退出码为 1，干净时退出码为 0。

Sources:
- Run tests from the command line: https://docs.unity3d.com/6000.3/Documentation/Manual/test-framework/run-tests-from-command-line.html
- Test Framework command-line arguments: https://docs.unity3d.com/Packages/com.unity.test-framework@1.4/manual/reference-command-line.html
- NUnit test result XML format: https://docs.nunit.org/articles/nunit/technical-notes/usage/Test-Result-XML-Format.html

来源：
- Run tests from the command line: https://docs.unity3d.com/6000.3/Documentation/Manual/test-framework/run-tests-from-command-line.html
- Test Framework command-line arguments: https://docs.unity3d.com/Packages/com.unity.test-framework@1.4/manual/reference-command-line.html
- NUnit test result XML format: https://docs.nunit.org/articles/nunit/technical-notes/usage/Test-Result-XML-Format.html

---

## Debugging
## 调试

### Use Logging Best Practices
### 使用日志记录最佳实践

```csharp
// ✅ Structured logging (Unity 6+)
using UnityEngine;

Debug.Log($"Player {playerName} scored {score} points");

// ✅ Conditional compilation for debug code
#if UNITY_EDITOR || DEVELOPMENT_BUILD
    Debug.DrawRay(transform.position, direction, Color.red);
#endif
```

---

## Summary: Unity 6 Tech Stack
## 总结：Unity 6 技术栈

| Feature | Use This (2026) | Avoid This (Legacy) |
|---------|------------------|----------------------|
| **Input** | Input System package | `Input` class |
| **UI** | UI Toolkit | UGUI (Canvas) |
| **ECS** | ISystem + IJobEntity | ComponentSystem |
| **Rendering** | URP + RenderGraph | Built-in pipeline |
| **Assets** | Addressables | Resources |
| **Jobs** | Burst + IJobParallelFor | Coroutines for heavy work |
| **Multiplayer** | Netcode for GameObjects | UNet |

| 特性 | 使用这个（2026） | 避免这个（旧版） |
|---------|------------------|----------------------|
| **输入** | Input System 包 | `Input` 类 |
| **UI** | UI Toolkit | UGUI（Canvas） |
| **ECS** | ISystem + IJobEntity | ComponentSystem |
| **渲染** | URP + RenderGraph | 内置管线 |
| **资源** | Addressables | Resources |
| **Job** | Burst + IJobParallelFor | 用协程处理繁重工作 |
| **多人游戏** | Netcode for GameObjects | UNet |

---

**Sources:**
- https://docs.unity3d.com/6000.0/Documentation/Manual/BestPracticeGuides.html
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/index.html

**来源：**
- https://docs.unity3d.com/6000.0/Documentation/Manual/BestPracticeGuides.html
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/index.html
