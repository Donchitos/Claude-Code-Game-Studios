---
name: test-helpers
description: "Generate engine-specific test helper libraries — assertion utilities, factory functions, mocks in the engine's test folder. Reduces boilerplate."
argument-hint: "[system-name | all | scaffold]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-helpers/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: test-helpers
description: "生成引擎特定的测试辅助库 — 断言工具、工厂函数、引擎测试文件夹中的模拟对象。减少样板代码。"
argument-hint: "[system-name | all | scaffold]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-helpers/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

# Test Helpers
# 测试辅助

Writing test cases is faster and more consistent when common setup, teardown,
and assertion patterns are abstracted into helpers. This skill generates a
`tests/helpers/` library tailored to the project's actual engine, language,
and systems — so every developer writes less boilerplate and more assertions.
当常见的 setup、teardown 和断言模式被抽象为辅助函数时，编写测试用例会更快、更一致。
此技能生成一个 `tests/helpers/` 库，针对项目实际的引擎、语言
和系统定制 — 让每位开发者写更少的样板代码和更多的断言。

**Output:** engine-specific helper files in the engine's **helper root** —
the only place its test runner compiles them (`.claude/docs/directory-structure.md`):
**输出：** 引擎 **辅助根** 中的引擎特定辅助文件 —
这是其测试运行器唯一会编译它们的地方（`.claude/docs/directory-structure.md`）：

| Engine | Helper root |
|---|---|
| Godot | `tests/helpers/` |
| Unity | `Assets/Tests/EditMode/Helpers/` — inside the `EditModeTests` assembly `/test-setup` creates. If PlayMode tests need the same helpers, ask before creating `Assets/Tests/Helpers/TestHelpers.asmdef` and referencing it from both test assemblies. |
| Unreal | `Source/<Module>/Private/Tests/Helpers/` |
| 引擎 | 辅助根 |
|---|---|
| Godot | `tests/helpers/` |
| Unity | `Assets/Tests/EditMode/Helpers/` — 位于 `/test-setup` 创建的 `EditModeTests` 程序集内。如果 PlayMode 测试需要相同的辅助函数，在创建 `Assets/Tests/Helpers/TestHelpers.asmdef` 并从两个测试程序集引用它之前先询问。 |
| Unreal | `Source/<Module>/Private/Tests/Helpers/` |

`tests/helpers/` below means the helper root for the project's engine.
下文的 `tests/helpers/` 指项目引擎的辅助根。

**When to run:**
- After `/test-setup` scaffolds the framework (first time)
- When multiple test files repeat the same setup boilerplate
- When starting to write tests for a new system
**何时运行：**
- 在 `/test-setup` 搭建框架之后（首次）
- 当多个测试文件重复相同的 setup 样板代码时
- 当开始为新系统编写测试时

---

## Assertions: use the project's test framework, never bare `assert()`
## 断言：使用项目的测试框架，绝不用裸 `assert()`

**Generated helpers must assert through the configured test framework's assertion
API**, resolved from `testing.framework` — not through GDScript's built-in
`assert()`.
**生成的辅助函数必须通过已配置测试框架的断言 API 进行断言**，该框架从 `testing.framework` 解析 — 而不是通过 GDScript 内置的
`assert()`。

Two things go wrong with a bare `assert()` in a helper, and both are silent:
辅助函数中使用裸 `assert()` 会有两个问题，且两者都是静默的：

1. **It aborts the run instead of failing the test.** A framework assertion
   records a failure and continues, so one broken expectation yields one red test.
   A bare `assert()` halts execution, so the first failure hides every result
   after it.
2. **It is stripped in release builds.** A helper library built on `assert()`
   stops asserting entirely in exactly the build you most want checked, and does
   so without any error — the tests still "pass".
1. **它会中止运行，而不是使测试失败。** 框架断言会
   记录失败并继续，因此一个破损的预期产生一个红色测试。
   裸 `assert()` 会停止执行，因此第一个失败会隐藏其后
   的每个结果。
2. **它会在发布构建中被剥离。** 基于 `assert()` 构建的辅助库
   恰恰会在你最想检查的构建中完全停止断言，而且
   不产生任何错误 — 测试仍然"通过"。

**Look up the assertion form for the configured framework before generating
code.** Do not copy the forms in this file or in other skills' examples as
authoritative — they are illustrative and have drifted (`assert_eq`,
`assert_true` and `assert_that` all appear across the repo). If you cannot
confirm the correct API for the project's framework, say so and generate no
helper rather than guessing.
**在生成代码之前，查明已配置框架的断言形式。** 不要将此文件或其他技能示例中的形式当作
权威复制 — 它们只是示例且已发生漂移（`assert_eq`、
`assert_true` 和 `assert_that` 都出现在仓库中）。如果你无法
确认项目框架的正确 API，请说明，并不要生成
辅助函数，而不是猜测。

**Helpers must not extend the framework's test-suite base class.** A file in
`tests/helpers/` that extends the suite type is discovered by the runner as a
test suite containing zero tests. Helpers are plain classes; only real test files
extend the suite.
**辅助函数不得继承框架的测试套件基类。** `tests/helpers/` 中继承套件类型的
文件会被运行器发现为一个包含零个测试的
测试套件。辅助函数是普通类；只有真正的测试文件
才继承套件。

---

## 1. Parse Arguments
## 1. 解析参数

**Modes:**
- `/test-helpers [system-name]` — generate helpers for a specific system
  (e.g., `/test-helpers combat`)
- `/test-helpers all` — generate helpers for all systems with test files
- `/test-helpers scaffold` — generate only the base helper library (no
  system-specific helpers); use this on first run
- No argument — run `scaffold` if no helpers exist, else `all`
**模式：**
- `/test-helpers [system-name]` — 为特定系统生成辅助函数
  （例如 `/test-helpers combat`）
- `/test-helpers all` — 为所有有测试文件的系统生成辅助函数
- `/test-helpers scaffold` — 只生成基础辅助库（不含
  系统特定辅助函数）；首次运行时使用
- 无参数 — 若不存在辅助函数则运行 `scaffold`，否则运行 `all`

---

## 2. Detect Engine and Language
## 2. 检测引擎和语言

Read from `project.yaml` first, falling back to `.claude/docs/technical-preferences.md` for any key that is absent or empty:
先读取 `project.yaml`，对任何缺失或为空的键回退到 `.claude/docs/technical-preferences.md`：
- `engine.name` (else the `Engine:` value)
- `engine.language` (else the `Language:` value)
- `testing.framework` (else `Framework:` from the Testing section)
- `engine.name`（否则使用 `Engine:` 值）
- `engine.language`（否则使用 `Language:` 值）
- `testing.framework`（否则使用 Testing 节的 `Framework:`）

If the engine is not configured in either source: "Engine not configured. Run `/setup-engine` first."
如果两个来源中都未配置引擎："Engine not configured. Run `/setup-engine` first."

---

## 3. Load Existing Test Patterns
## 3. 加载现有测试模式

Scan the engine's test root for patterns already in use (Godot `tests/`, Unity
`Assets/Tests/`, Unreal `Source/<Module>/Private/Tests/`):
扫描引擎测试根中已在使用的模式（Godot `tests/`、Unity
`Assets/Tests/`、Unreal `Source/<Module>/Private/Tests/`）：

```
Glob pattern="tests/**/*_test.*"                  (Godot)
Glob pattern="Assets/Tests/**/*Tests.cs"          (Unity)
Glob pattern="Source/*/Private/Tests/**/*.cpp"    (Unreal)
```

For a representative sample (up to 5 files), read the test files and extract:
- Setup patterns (how `before_each` / `setUp` / fixtures are written)
- Common assertion patterns (what is being asserted most often)
- Object creation patterns (how game objects or scenes are instantiated in tests)
- Mock/stub patterns (how dependencies are replaced)
对代表性样本（最多 5 个文件），读取测试文件并提取：
- Setup 模式（如何编写 `before_each` / `setUp` / fixtures）
- 常见断言模式（最常断言的是什么）
- 对象创建模式（测试中如何实例化游戏对象或场景）
- Mock/stub 模式（如何替换依赖）

This ensures generated helpers match the project's existing style, not a
generic template.
这确保生成的辅助函数匹配项目现有风格，而不是
通用模板。

Also read:
- `design/gdd/systems-index.md` — to know which systems exist
- In-scope GDD(s) — to understand what data types and values need testing. Read
  them by section: find the headings you need with the Grep tool (pattern `^#`,
  content mode) and Read those ranges with offset and limit.
- `docs/architecture/tr-registry.yaml` — to map requirements to tested systems
另需读取：
- `design/gdd/systems-index.md` — 以了解存在哪些系统
- 范围内的 GDD — 以了解哪些数据类型和值需要测试。按节
  读取：用 Grep 工具（模式 `^#`，content 模式）找到所需标题，
  再用 offset 和 limit 读取相应区间。
- `docs/architecture/tr-registry.yaml` — 以将需求映射到被测试的系统

---

## 4. Generate Engine-Specific Helpers
## 4. 生成引擎特定辅助函数

### Godot 4 (GDUnit4 / GDScript)
### Godot 4（GDUnit4 / GDScript）

> **`FAIL_IF(...)` in the example below is a PLACEHOLDER, not an API.** It marks
> the one line you must resolve from the project's actual test framework before
> emitting any of this, per the rule in §2. Substitute the framework's real
> failure call — the form that **registers a failure with the runner and lets the
> suite continue** — and delete the marker comment.
>
> **It is deliberately not spelled `assert_that`, `assert_eq` or `assert_true`.**
> All three appear somewhere in this repo, they disagree, and **GdUnit4's API is
> not covered by `docs/engine-reference/`** — so writing any of them here would be
> asserting an API this repo cannot source, in the file whose whole job is to stop
> people doing that. If you cannot confirm the correct call for the configured
> framework, §2 already tells you the answer: **generate no helper.** An
> unresolved `FAIL_IF` reaching disk is a bug; a missing helper is a task.
>
> Worked examples must obey §2 too — a bare `assert()` here would be the exact
> form §2 forbids, sixty lines below §2 forbidding it. A rule stated in prose
> does not reach its own worked example unless someone makes it.
> **下文示例中的 `FAIL_IF(...)` 是占位符，不是 API。** 它标记
> 你在输出任何此类内容之前必须从项目实际测试框架中解析的那一行，
> 依据 §2 的规则。替换为框架真正的
> 失败调用 — 即**向运行器登记失败并让
> 套件继续**的形式 — 并删除标记注释。
>
> **它有意不拼写为 `assert_that`、`assert_eq` 或 `assert_true`。**
> 这三者都出现在本仓库某处，彼此不一致，而且 **GdUnit4 的 API
> 未被 `docs/engine-reference/` 覆盖** — 因此在此写出其中任何一个，都等于
> 断言一个本仓库无法溯源的 API，而在这个文件中，其全部职责就是阻止
> 人们那样做。如果你无法确认已配置框架的正确调用，§2 已给出答案：
> **不要生成辅助函数。** 未解析的 `FAIL_IF` 落到磁盘上是缺陷；缺少辅助函数是一个任务。
>
> 示例也必须遵守 §2 — 这里的裸 `assert()` 正是
> §2 禁止的形式，而在 §2 禁止它的六十行之后。以散文陈述的规则
> 不会自动到达其自身的示例，除非有人让它生效。

**Base helper** (`tests/helpers/game_assertions.gd`):
**基础辅助**（`tests/helpers/game_assertions.gd`）：

```gdscript
## Game-specific assertion utilities for [Project Name] tests.
## Domain-specific helpers built on the project's test framework.
##
## Usage (static — no instance needed):
##   GameAssertions.assert_in_range(entity.health, 0, entity.max_health, "health")

class_name GameAssertions
extends RefCounted

## Assert a value is within the inclusive range [min_val, max_val].
## Use for any formula output that has defined bounds in a GDD.
static func assert_in_range(
    value: float,
    min_val: float,
    max_val: float,
    label: String = "value"
) -> void:
    # FRAMEWORK ASSERT — resolve per the rule above; do not emit `assert()`.
    FAIL_IF(
        not (value >= min_val and value <= max_val),
        "%s %.2f is outside expected range [%.2f, %.2f]" % [label, value, min_val, max_val]
    )

## Assert a signal was emitted during a callable block.
## Usage: assert_signal_emitted(entity, "health_changed", func(): entity.take_damage(10))
static func assert_signal_emitted(
    obj: Object,
    signal_name: String,
    action: Callable
) -> void:
    # A lambda captures a local by value: `emitted = true` inside it would set
    # the lambda's own copy. Mutate a Dictionary it shares instead. `...args`
    # (4.5+) accepts a signal with any number of arguments.
    var state := {"emitted": false}
    obj.connect(signal_name, func(...args): state.emitted = true)
    action.call()
    # FRAMEWORK ASSERT — resolve per the rule above; do not emit `assert()`.
    FAIL_IF(not state.emitted, "Expected signal '%s' to be emitted, but it was not." % signal_name)

## Assert that a callable does NOT emit a signal.
static func assert_signal_not_emitted(
    obj: Object,
    signal_name: String,
    action: Callable
) -> void:
    var state := {"emitted": false}  # a Dictionary, as above
    obj.connect(signal_name, func(...args): state.emitted = true)
    action.call()
    # FRAMEWORK ASSERT — resolve per the rule above; do not emit `assert()`.
    FAIL_IF(state.emitted, "Expected signal '%s' NOT to be emitted, but it was." % signal_name)

## Assert a node exists at path within a parent.
static func assert_node_exists(parent: Node, path: NodePath) -> void:
    # FRAMEWORK ASSERT — resolve per the rule above; do not emit `assert()`.
    FAIL_IF(
        not parent.has_node(path),
        "Expected node at path '%s' to exist." % str(path)
    )
```

**Factory helper** (`tests/helpers/game_factory.gd`):
**工厂辅助**（`tests/helpers/game_factory.gd`）：

```gdscript
## Factory functions for creating test game objects.
## Returns minimal objects configured for unit testing (no scene tree required).
##
## Usage: var player = GameFactory.make_player(health: 100)

class_name GameFactory
extends RefCounted

## Create a minimal player-like object for testing.
## Override fields as needed.
static func make_player(health: int = 100) -> Node:
    var player = Node.new()
    player.set_meta("health", health)
    player.set_meta("max_health", health)
    return player
```

**Scene helper** (`tests/helpers/scene_runner_helper.gd`):
**场景辅助**（`tests/helpers/scene_runner_helper.gd`）：

```gdscript
## Utilities for scene-based integration tests. For input simulation and frame
## stepping, use gdUnit4's own `scene_runner()` from inside the suite.

class_name SceneRunnerHelper
extends RefCounted

## Load a scene under `host` — the calling test suite, which passes `self` —
## and wait one frame for _ready() to complete. A plain class, so the runner
## never discovers this file as a suite with zero tests.
static func load_scene_and_wait(host: Node, scene_path: String) -> Node:
    var scene: Node = load(scene_path).instantiate()
    host.add_child(scene)
    await host.get_tree().process_frame
    return scene
```

---

### Unity (NUnit / C#)
### Unity（NUnit / C#）

**Base helper** (`Assets/Tests/EditMode/Helpers/GameAssertions.cs`):
**基础辅助**（`Assets/Tests/EditMode/Helpers/GameAssertions.cs`）：

```csharp
using NUnit.Framework;
using UnityEngine;

/// <summary>
/// Game-specific assertion utilities for [Project Name] tests.
/// Extends NUnit's Assert with domain-specific helpers.
/// </summary>
public static class GameAssertions
{
    /// <summary>
    /// Assert a value is within an inclusive range [min, max].
    /// Use for any formula output defined in GDD Formulas sections.
    /// </summary>
    public static void AssertInRange(float value, float min, float max, string label = "value")
    {
        Assert.That(value, Is.InRange(min, max),
            $"{label} ({value:F2}) is outside expected range [{min:F2}, {max:F2}]");
    }

    /// <summary>Assert a UnityEvent or C# event was raised during an action.</summary>
    public static void AssertEventRaised(ref bool wasCalled, System.Action action, string eventName)
    {
        wasCalled = false;
        action();
        Assert.IsTrue(wasCalled, $"Expected event '{eventName}' to be raised, but it was not.");
    }

    /// <summary>Assert a component exists on a GameObject.</summary>
    public static void AssertHasComponent<T>(GameObject obj) where T : Component
    {
        var component = obj.GetComponent<T>();
        Assert.IsNotNull(component,
            $"Expected GameObject '{obj.name}' to have component {typeof(T).Name}.");
    }
}
```

**Factory helper** (`Assets/Tests/EditMode/Helpers/GameFactory.cs`):
**工厂辅助**（`Assets/Tests/EditMode/Helpers/GameFactory.cs`）：

```csharp
using UnityEngine;

/// <summary>
/// Factory methods for creating minimal test objects without loading scenes.
/// </summary>
public static class GameFactory
{
    /// <summary>Create a minimal GameObject with a named component for testing.</summary>
    public static GameObject MakeGameObject(string name = "TestObject")
    {
        var go = new GameObject(name);
        return go;
    }

    /// <summary>
    /// Create a ScriptableObject of type T for data-driven tests.
    /// Dispose with Object.DestroyImmediate after test.
    /// </summary>
    public static T MakeScriptableObject<T>() where T : ScriptableObject
    {
        return ScriptableObject.CreateInstance<T>();
    }
}
```

---

### Unreal Engine (C++)
### Unreal Engine（C++）

**Base helper** (`Source/<Module>/Private/Tests/Helpers/GameTestHelpers.h`):
**基础辅助**（`Source/<Module>/Private/Tests/Helpers/GameTestHelpers.h`）：

```cpp
#pragma once

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"

/**
 * Game-specific assertion macros and helpers for [Project Name] automation tests.
 * Include in any test file that needs domain-specific assertions.
 *
 * Usage:
 *   GAME_TEST_ASSERT_IN_RANGE(TestName, DamageValue, 10.0f, 50.0f, TEXT("Damage"));
 */

// Assert a float value is within inclusive range [Min, Max]
#define GAME_TEST_ASSERT_IN_RANGE(TestName, Value, Min, Max, Label) \
    TestTrue( \
        FString::Printf(TEXT("%s (%.2f) in range [%.2f, %.2f]"), Label, Value, Min, Max), \
        (Value) >= (Min) && (Value) <= (Max) \
    )

// Assert a UObject pointer is valid (not null, not garbage collected)
#define GAME_TEST_ASSERT_VALID(TestName, Ptr, Label) \
    TestTrue( \
        FString::Printf(TEXT("%s is valid"), Label), \
        IsValid(Ptr) \
    )

// Assert an Actor is in the world (spawned successfully)
#define GAME_TEST_ASSERT_SPAWNED(TestName, ActorPtr, ClassName) \
    TestNotNull( \
        FString::Printf(TEXT("Spawned actor of class %s"), TEXT(#ClassName)), \
        ActorPtr \
    )

/**
 * Helper to create a minimal test world.
 * Remember to call World->DestroyWorld(false) in teardown.
 */
namespace GameTestHelpers
{
    inline UWorld* CreateTestWorld(const FString& WorldName = TEXT("TestWorld"))
    {
        UWorld* World = UWorld::CreateWorld(EWorldType::Game, false);
        FWorldContext& WorldContext = GEngine->CreateNewWorldContext(EWorldType::Game);
        WorldContext.SetCurrentWorld(World);
        return World;
    }
}
```

---

## 5. Generate System-Specific Helpers
## 5. 生成系统特定辅助函数

For `[system-name]` or `all` modes, generate a helper per system:
对于 `[system-name]` 或 `all` 模式，为每个系统生成一个辅助函数：

Read only the GDD sections this needs — `Grep pattern="^## ([0-9]+\. )?(Formulas|Edge Cases|Detailed Rules|Detailed Design)" path="design/gdd/[system].md" output_mode="content" -A 30` (the optional number matches a reverse-documented GDD's `## 4. Formulas`) — rather than a full read (every peer skill section-greps GDDs; in `all` mode a full read multiplies across each system's 400+-line GDD). Extract:
只读取此项所需的 GDD 节 — `Grep pattern="^## ([0-9]+\. )?(Formulas|Edge Cases|Detailed Rules|Detailed Design)" path="design/gdd/[system].md" output_mode="content" -A 30`（可选数字匹配反向文档化 GDD 的 `## 4. Formulas`） — 而不是完整读取（每个同级技能都按节 grep GDD；在 `all` 模式下，完整读取会在每个系统 400 多行的 GDD 上成倍放大）。提取：
- Data types (entity types, component names)
- Formula variables and their bounds
- Common test scenarios mentioned in Edge Cases
- 数据类型（实体类型、组件名）
- 公式变量及其边界
- Edge Cases 中提到的常见测试场景

Generate `tests/helpers/[system]_factory.[ext]` with factory functions
specific to that system's objects.
生成 `tests/helpers/[system]_factory.[ext]`，其中包含针对该系统对象的工厂函数。

Example pattern for a `combat` system (Godot/GDScript):
`combat` 系统的示例模式（Godot/GDScript）：

```gdscript
## Factory and assertion helpers for Combat system tests.
## Generated by /test-helpers combat on [date].
## Based on: design/gdd/combat.md

class_name CombatTestFactory
extends RefCounted

const DAMAGE_MIN := 0
const DAMAGE_MAX := 999  # From GDD: damage formula upper bound

## Create a minimal attacker object for damage formula tests.
static func make_attacker(attack: float = 10.0, crit_chance: float = 0.0) -> Node:
    var attacker = Node.new()
    attacker.set_meta("attack", attack)
    attacker.set_meta("crit_chance", crit_chance)
    return attacker

## Create a minimal target object for damage receive tests.
static func make_target(defense: float = 0.0, health: float = 100.0) -> Node:
    var target = Node.new()
    target.set_meta("defense", defense)
    target.set_meta("health", health)
    target.set_meta("max_health", health)
    return target

## Assert damage output is within GDD-specified bounds.
static func assert_damage_in_bounds(damage: float) -> void:
    GameAssertions.assert_in_range(damage, DAMAGE_MIN, DAMAGE_MAX, "damage")
```

---

## 6. Write Output
## 6. 写出输出

Present a summary of what will be created:
呈现将要创建的内容摘要：

```
## Test Helpers to Create

Base helpers (engine: [engine], helper root: [helper root]):
- [helper root]/game_assertions.[ext]
- [helper root]/game_factory.[ext]
[engine-specific extras]

System helpers ([mode]):
- [helper root]/[system]_factory.[ext]  ← from [system] GDD
```

Ask: "May I write these helper files to `[helper root]`?"
询问："我可以把这些辅助文件写入 `[helper root]` 吗？"

**Never overwrite existing files.** If a file already exists, report:
"Skipping `[path]` — already exists. Remove the file manually if you want it
regenerated."
**绝不覆盖现有文件。** 如果文件已存在，报告：
"Skipping `[path]` — already exists. Remove the file manually if you want it
regenerated."

After writing: Verdict: **COMPLETE** — helper files created.
写入后：裁决：**COMPLETE** — 辅助文件已创建。

"Helper files created. To use them in a test:
- Godot: `class_name` is auto-imported — no explicit import needed
- Unity: Add `using` directive or reference the test assembly
- Unreal: `#include \"Tests/Helpers/GameTestHelpers.h\"` (from inside the module)"
"Helper files created. To use them in a test:
- Godot: `class_name` is auto-imported — no explicit import needed
- Unity: Add `using` directive or reference the test assembly
- Unreal: `#include \"Tests/Helpers/GameTestHelpers.h\"` (from inside the module)"

---

## Collaborative Protocol
## 协作协议

- **Never overwrite existing helpers** — they may contain hand-written
  customisations. Only generate new files that don't exist yet
- **Generated code is a starting point** — the generated factory functions use
  metadata patterns for simplicity; adapt to the actual class structure once
  the code exists
- **Helpers should reflect the GDD** — bounds and constants in helpers should
  trace to GDD Formulas sections, not invented values
- **Ask before writing** — always confirm before creating files in `tests/`
- **绝不覆盖现有辅助函数** — 它们可能包含手写的
  自定义内容。只生成尚不存在的新文件
- **生成的代码是起点** — 生成的工厂函数为简化而使用
  元数据模式；一旦代码存在，请适配实际的类结构
- **辅助函数应反映 GDD** — 辅助函数中的边界和常量应
  可溯源到 GDD Formulas 节，而非臆造的值
- **写入前先询问** — 在 `tests/` 中创建文件前始终确认

## Next Steps
## 后续步骤

- Run `/test-setup` if the test framework has not been scaffolded yet.
- Use `/dev-story` to implement stories — helpers reduce boilerplate in new test files.
- Run `/skill-test` to validate other skills that may need helper coverage.
- 如果测试框架尚未搭建，运行 `/test-setup`。
- 使用 `/dev-story` 实现故事 — 辅助函数可减少新测试文件中的样板代码。
- 运行 `/skill-test`，验证其他可能需要辅助函数覆盖的技能。
