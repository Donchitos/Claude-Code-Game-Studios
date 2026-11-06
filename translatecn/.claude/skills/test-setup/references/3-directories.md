# /test-setup — Phase 3: Create Directory Structure

# /test-setup — 第 3 阶段：创建目录结构

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 3: Create Directory Structure

## 第 3 阶段：创建目录结构

**In this file:**

**本文件内容：**

- `tests/README.md`
- `production/qa/evidence/.gitkeep`
- Engine-specific files

- `tests/README.md`
- `production/qa/evidence/.gitkeep`
- 引擎特定文件

After approval, create the following files:

获得批准后，创建以下文件：

### `tests/README.md`

### `tests/README.md`

````markdown
# Test Infrastructure

**Engine**: [engine name + version]
**Test Framework**: [GdUnit4 | Unity Test Framework | UE Automation]
**CI**: `.github/workflows/tests.yml`
**Setup date**: [date]

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

[Unity/Unreal — replace the unit/integration lines: unit and integration tests
live under the engine's test root, `Assets/Tests/EditMode|PlayMode/[System]/`
or `Source/<Module>/Private/Tests/[System]/`; `tests/` keeps this README and
`smoke/`. Every `tests/unit/` path below means that test root.]

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

[Engine-specific command — see below]

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Godot**: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`
- **Unity**: class `[System]Tests` in `[System]Tests.cs`, method `[Scenario]_[Expected]`
  — `CombatTests.cs` → `BaseAttack_ReturnsExpectedDamage()`
- **Unreal**: class `F[System][Scenario]Test`, test name `<Project>.[System].[Scenario]`
  — `FCombatBaseAttackTest` → `<Project>.Combat.BaseAttack`
  [`<Project>` is the root the filter in `commands.test` uses — write it out:
  the project name, or the distinct root `/setup-engine` chose]

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
````

````markdown
# 测试基础设施

**引擎**：[引擎名称 + 版本]
**测试框架**：[GdUnit4 | Unity Test Framework | UE Automation]
**CI**：`.github/workflows/tests.yml`
**搭建日期**：[date]

## 目录结构

```
tests/
  unit/           # 隔离的单元测试（公式、状态机、逻辑）
  integration/    # 跨系统测试以及存档/读档测试
  smoke/          # 供 /smoke-check 闸门使用的关键路径测试清单
```

[Unity/Unreal —— 替换 unit/integration 两行：单元测试和集成测试位于
引擎的测试根目录下，即 `Assets/Tests/EditMode|PlayMode/[System]/`
或 `Source/<Module>/Private/Tests/[System]/`；`tests/` 只保留本 README 和
`smoke/`。下文出现的每个 `tests/unit/` 路径都指该测试根目录。]

```
production/qa/
  evidence/       # 截图日志和人工测试签核记录
```

> **人工证据存放在 `production/qa/evidence/` 下，而不是 `tests/`** —— 所有
> 使用方都是从那里读取的。

## 运行测试

[引擎特定命令 —— 见下文]

## 测试命名

命名遵循引擎的语言（`.claude/rules/test-standards.md`）：
- **Godot**：文件为 `[system]_[feature]_test.gd`，函数为 `test_[scenario]_[expected]`
  —— `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`
- **Unity**：类为 `[System]Tests`，位于 `[System]Tests.cs`，方法为 `[Scenario]_[Expected]`
  —— `CombatTests.cs` → `BaseAttack_ReturnsExpectedDamage()`
- **Unreal**：类为 `F[System][Scenario]Test`，测试名为 `<Project>.[System].[Scenario]`
  —— `FCombatBaseAttackTest` → `<Project>.Combat.BaseAttack`
  [`<Project>` 是 `commands.test` 中过滤器所用的根 —— 请完整写出：
  项目名称，或 `/setup-engine` 选择的独立根]

## 故事类型 → 测试证据

| 故事类型 | 所需证据 | 位置 |
|---|---|---|
| Logic | 自动化单元测试 —— 必须通过 | `tests/unit/[system]/` |
| Integration | 集成测试或试玩文档 | `tests/integration/[system]/` |
| Visual/Feel | 截图 + 负责人签核 | `production/qa/evidence/` |
| UI | 每个改动界面的留存截图 | `production/qa/evidence/` |
| Config/Data | 冒烟测试通过 | `production/qa/smoke-*.md` |

## CI

每次推送到 `main` 以及每个拉取请求都会自动运行测试。
测试套件失败会阻止合并。
````

The README and this skill's completion summary name the same evidence path —
`production/qa/evidence/` is where `/smoke-check`, `/test-evidence-review`,
`/qa-plan` and the evidence table in `.claude/docs/coding-standards.md` read,
so a `tests/evidence/` would be a directory nothing reads.

README 与本技能的完成摘要命名的是同一条证据路径 ——
`/smoke-check`、`/test-evidence-review`、`/qa-plan` 以及
`.claude/docs/coding-standards.md` 中的证据表都从 `production/qa/evidence/`
读取，因此 `tests/evidence/` 会是一个无人读取的目录。

### `production/qa/evidence/.gitkeep`

### `production/qa/evidence/.gitkeep`

Create it empty. Git does not keep an empty directory, and this is where
`/story-done`, `/smoke-check` and `/test-evidence-review` look for screenshots and
sign-off records — the completion summary lists it, so it must exist.

将其创建为空文件。Git 不会保留空目录，而 `/story-done`、`/smoke-check` 和
`/test-evidence-review` 正是在这里查找截图和签核记录 —— 完成摘要中列出了它，
因此它必须存在。

### Engine-specific files

### 引擎特定文件

#### Godot 4 (`Engine: Godot`)

#### Godot 4（`Engine: Godot`）

**Do not write a runner script.** gdUnit4 ships its own command-line runner,
`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`. The command CI, `/smoke-check`
and `commands.test` use is:

**不要编写运行器脚本。** gdUnit4 自带命令行运行器
`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`。CI、`/smoke-check`
和 `commands.test` 使用的命令是：

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first. A fresh clone has no `.godot/` class cache, and a run
without one exits **1** — `GdUnitCmdTool.gd` did not load (`Failed to load
script`), so no test ran. A cache older than a new `class_name` fails valid
code with 105. The CI action imports on its own.

请先运行导入。全新克隆没有 `.godot/` 类缓存，缺少它时运行会以 **1** 退出 ——
`GdUnitCmdTool.gd` 未能加载（`Failed to load script`），因此没有任何测试运行。
早于新增 `class_name` 的缓存会让有效代码以 105 失败。CI action 会自行导入。

Exit code **0** when every test passes and **100** when any fails — verified
on Godot 4.6.1 with gdUnit4 6.1.3 and on Godot 4.7.2 with gdUnit4 6.2.2.
**101** means every test passed but a test
leaked nodes: a warning, not a failure. 103 and 104 mean gdUnit4 could not run
(headless refused, Godot older than 4.3); 105 means a test script does not parse. `-a res://tests` runs every suite
under `tests/`; `--ignoreHeadlessMode` is required because gdUnit4 otherwise
refuses to run headless. `--remote-debug tcp://127.0.0.1:0` is required too —
it is what gdUnit4's own `runtest` script passes. Without it a script error
opens Godot's interactive debugger, and the run waits at a `debug>` prompt
forever instead of exiting 105. The flag makes every run print two `ERROR:`
lines about the remote port (`127.0.0.1:0`); they are expected, not a failure.
A run that finds no tests prints `No test cases found` and exits 0 — that is
not a pass. The folder is `addons/gdUnit4/` with a **capital U**.

当所有测试通过时退出码为 **0**，任一测试失败时为 **100** —— 已在
Godot 4.6.1 + gdUnit4 6.1.3 以及 Godot 4.7.2 + gdUnit4 6.2.2 上验证。
**101** 表示所有测试都通过，但有测试泄漏了节点：这是警告，不是失败。
103 和 104 表示 gdUnit4 无法运行（拒绝无头模式、Godot 版本早于 4.3）；
105 表示某个测试脚本无法解析。`-a res://tests` 会运行 `tests/` 下的
所有套件；`--ignoreHeadlessMode` 是必需的，否则 gdUnit4 会拒绝以无头模式运行。
`--remote-debug tcp://127.0.0.1:0` 同样是必需的 ——
gdUnit4 自带的 `runtest` 脚本就是这样传的。缺少它时，脚本错误会
打开 Godot 的交互式调试器，运行会永远停在 `debug>` 提示符处，
而不会以 105 退出。该标志会让每次运行都打印两行与远程端口（`127.0.0.1:0`）
相关的 `ERROR:` —— 这是预期输出，不是失败。
未找到任何测试的运行会打印 `No test cases found` 并以 0 退出 —— 那
不算通过。文件夹名为 `addons/gdUnit4/`，其中的 U 为**大写**。

Create `tests/unit/.gdignore_placeholder` with content:
`# Unit tests go here — one subdirectory per system (e.g., tests/unit/combat/)`

创建 `tests/unit/.gdignore_placeholder`，内容为：
`# Unit tests go here — one subdirectory per system (e.g., tests/unit/combat/)`

Create `tests/integration/.gdignore_placeholder` with content:
`# Integration tests go here — one subdirectory per system`

创建 `tests/integration/.gdignore_placeholder`，内容为：
`# Integration tests go here — one subdirectory per system`

Note in the README: **Installing GdUnit4**
```
1. Open Godot → Asset Store (AssetLib before Godot 4.7) → search "GdUnit4" → install it
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: res://addons/gdUnit4/bin/GdUnitCmdTool.gd exists (capital U)
```

在 README 中注明：**安装 GdUnit4**
```
1. 打开 Godot → Asset Store（Godot 4.7 之前为 AssetLib）→ 搜索 "GdUnit4" → 安装它
2. 启用插件：Project → Project Settings → Plugins → GdUnit4 ✓
3. 重启编辑器
4. 验证：res://addons/gdUnit4/bin/GdUnitCmdTool.gd 存在（U 为大写）
```

#### Unity (`Engine: Unity`)

#### Unity（`Engine: Unity`）

Tests live under **`Assets/Tests/`** — Unity compiles only `Assets/` and
`Packages/`. A test under `tests/` is never compiled, and the run then reports
**0 tests, `Passed`, exit 0** (verified on 6000.3.23f1): a false pass.

测试位于 **`Assets/Tests/`** 下 —— Unity 只编译 `Assets/` 和
`Packages/`。放在 `tests/` 下的测试永远不会被编译，运行时则会报告
**0 个测试、`Passed`、退出码 0**（已在 6000.3.23f1 上验证）：这是一次假通过。

First check the Test Framework package:
`grep -q 'com.unity.test-framework' Packages/manifest.json`. Without it
`-runTests` does not fail — it hangs. If absent, ask to add
`"com.unity.test-framework"` to `dependencies` at the version your editor
bundles. Unity 6 releases bundle different ones — 1.6.0 in 6000.3.23f1, 1.5.1 in
6000.1.0f1 — so read it rather than copy a number: on Windows it is the
`version` in `Data/Resources/PackageManager/BuiltInPackages/com.unity.test-framework/package.json`
under the folder that holds `Unity.exe`.

首先检查 Test Framework 包：
`grep -q 'com.unity.test-framework' Packages/manifest.json`。缺少它时
`-runTests` 不会失败 —— 而是会挂起。如果缺失，请询问是否将
`"com.unity.test-framework"` 加入 `dependencies`，版本使用你的编辑器
内置的版本。Unity 6 各版本内置的版本各不相同 —— 6000.3.23f1 为 1.6.0，
6000.1.0f1 为 1.5.1 —— 所以要读取它，而不是照抄某个数字：在 Windows 上，它是
`Unity.exe` 所在文件夹下
`Data/Resources/PackageManager/BuiltInPackages/com.unity.test-framework/package.json`
中的 `version`。

Create `Assets/Tests/EditMode/EditModeTests.asmdef` — unit tests, no Play Mode:
```json
{
  "name": "EditModeTests",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

创建 `Assets/Tests/EditMode/EditModeTests.asmdef` —— 单元测试，不使用 Play Mode：
```json
{
  "name": "EditModeTests",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

Create `Assets/Tests/PlayMode/PlayModeTests.asmdef` — integration tests in a
running scene: the same JSON with `"name": "PlayModeTests"` and
`"includePlatforms": []`.

创建 `Assets/Tests/PlayMode/PlayModeTests.asmdef` —— 在运行场景中执行的
集成测试：使用相同的 JSON，但 `"name": "PlayModeTests"`，
`"includePlatforms": []`。

> **A test assembly cannot see code in the default `Assembly-CSharp`.** An
> `.asmdef` can reference only other `.asmdef`s. If the game's scripts have no
> `.asmdef` of their own, ask before creating one (e.g. `Assets/Scripts/Game.asmdef`)
> and add `"Game"` to both test assemblies' `references`. Without it the first
> test that names a game class fails to compile. Moving scripts into an
> `.asmdef` changes what they can see, so before creating it:
>
> - **List the packages the scripts use.** `Assembly-CSharp` references every
>   package on its own; an `.asmdef` references only what it names. Read the
>   scripts' `using` lines and add the matching assemblies — commonly
>   `"Unity.InputSystem"`, `"Unity.TextMeshPro"`, `"UnityEngine.UI"`:
>   `{ "name": "Game", "references": ["Unity.InputSystem", "Unity.TextMeshPro"] }`.
>   Name only packages the project has installed.
> - **Give each `Editor/` folder under it its own `.asmdef`** with
>   `"includePlatforms": ["Editor"]` and `"references": ["Game"]`. Otherwise
>   editor scripts join the runtime assembly, and `using UnityEditor;` breaks the
>   player build.

> **测试程序集看不到默认 `Assembly-CSharp` 中的代码。** 一个
> `.asmdef` 只能引用其他 `.asmdef`。如果游戏脚本没有自己的
> `.asmdef`，请在创建之前先询问（例如 `Assets/Scripts/Game.asmdef`），
> 并在两个测试程序集的 `references` 中加入 `"Game"`。否则，第一个引用游戏类的
> 测试将无法编译。将脚本移入 `.asmdef` 会改变它们能看到的内容，因此在创建它之前：
>
> - **列出脚本所使用的包。** `Assembly-CSharp` 会自动引用每个
>   包；而 `.asmdef` 只引用它显式命名的内容。读取脚本的 `using` 行，并加入
>   对应的程序集 —— 常见的有 `"Unity.InputSystem"`、`"Unity.TextMeshPro"`、
>   `"UnityEngine.UI"`：
>   `{ "name": "Game", "references": ["Unity.InputSystem", "Unity.TextMeshPro"] }`。
>   只命名项目已安装的包。
> - **为它下面的每个 `Editor/` 文件夹提供各自的 `.asmdef`**，并设置
>   `"includePlatforms": ["Editor"]` 和 `"references": ["Game"]`。否则
>   编辑器脚本会加入运行时程序集，`using UnityEditor;` 会破坏
>   播放器构建。

Note in the README: **Running Unity tests** (use the editor executable —
`Unity` on `PATH` may be Unity's separate CLI, not the editor)
```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
Exit **0** when every test passes, **2** when any fails. Exit 1 or 3 is a FAIL
too: 1 is a compile error, which writes no results file, and 3 a failed run.
So is 4 (an unknown `-testPlatform`), and any other non-zero exit.
Delete `test-results/editmode.xml` before each run so an old file is never read
as a new result. Read the `<test-run>`
element of the results file: `testcasecount="0"` means nothing was compiled or
found — report it as not assessed, never as a pass. Do not add `-quit`;
`-runTests` exits by itself. Play Mode is the second line: a separate run with
its own results file, read the same way, and deleted before each run the same
way. An Edit Mode run never runs the tests in `Assets/Tests/PlayMode/`, so
`/smoke-check` runs both whenever that folder holds tests.

在 README 中注明：**运行 Unity 测试**（使用编辑器可执行文件 ——
`PATH` 上的 `Unity` 可能是 Unity 独立的 CLI，而不是编辑器）
```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
当所有测试通过时退出码为 **0**，任一测试失败时为 **2**。退出码 1 或 3 同样
算 FAIL：1 表示编译错误，此时不会写出结果文件；3 表示运行本身失败。
4（未知的 `-testPlatform`）以及任何其他非零退出码也算。
每次运行前删除 `test-results/editmode.xml`，以免旧文件被当作
新结果读取。读取结果文件中的 `<test-run>`
元素：`testcasecount="0"` 表示没有编译到或找到任何测试 ——
应报告为未评估，绝不能报告为通过。不要添加 `-quit`；
`-runTests` 会自行退出。Play Mode 是第二行命令：一次独立运行，
有自己的结果文件，阅读方式相同，并且同样在每次运行前删除。
Edit Mode 运行永远不会执行 `Assets/Tests/PlayMode/` 中的测试，因此
只要该文件夹中有测试，`/smoke-check` 就会两者都运行。

#### Unreal Engine (`Engine: Unreal` or `Engine: UE5`)

#### Unreal Engine（`Engine: Unreal` 或 `Engine: UE5`）

Tests live **inside the game module**: `Source/<Module>/Private/Tests/`, where
`<Module>` is the primary game module (for a C++ project, the `.uproject` name).
UnrealBuildTool compiles only module folders — a tests folder directly under
`Source/` is not a module, so a test there is silently never built and every
run reports `No automation tests matched`.

测试位于**游戏模块内部**：`Source/<Module>/Private/Tests/`，其中
`<Module>` 是主游戏模块（对于 C++ 项目，就是 `.uproject` 的名称）。
UnrealBuildTool 只编译模块文件夹 —— 直接放在
`Source/` 下的 tests 文件夹不是模块，因此其中的测试会被静默地从不构建，每次
运行都会报告 `No automation tests matched`。

Create `Source/<Module>/Private/Tests/README.md`. `<Project>.` in it — and
`[ProjectName].` in the CI filter below — is the test root the filter in
`commands.test` uses: the project name, or the distinct root `/setup-engine`
chose when the project's name is also an engine area. Write that root:
```markdown
# Unreal Automation Tests
Tests use the UE Automation Testing Framework and compile with this module.
Wrap each test file in `#if WITH_DEV_AUTOMATION_TESTS` … `#endif`.
Flags: `EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`
(there is no `GameFilter` flag).

Run via: Session Frontend → Automation → select "<Project>." tests
Or headlessly from the project root, after building the editor target — on a
fresh checkout the editor exits before any test runs:
"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"
"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput
The project path must be absolute: UE does not find a relative one (exit 1,
"Project file not found"). Those two lines are Windows'. On Linux build with
`Engine/Build/BatchFiles/Linux/Build.sh <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"` and run
the tests with `Engine/Binaries/Linux/UnrealEditor` and the same arguments; on
macOS build with `Engine/Build/BatchFiles/Mac/Build.sh <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"`
— Epic documents no command-line editor inside `UnrealEditor.app` for the test
run (see `docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

Read the output, not the exit code: a failing test and a run that matched nothing both exit 255.
`Result={Fail}` is a failure; `No automation tests matched` means no test was
built or named `<Project>.…`.

Test class naming: F[System][Scenario]Test — one class per test; a second
test reusing a class name fails to link
Test name: "<Project>.[System].[Scenario]"
```

创建 `Source/<Module>/Private/Tests/README.md`。其中的 `<Project>.` —— 以及
下方 CI 过滤器中的 `[ProjectName].` —— 是 `commands.test` 中过滤器所用的
测试根：项目名称，或者当项目名称本身也是引擎领域时 `/setup-engine`
选择的独立根。请写出该根：
```markdown
# Unreal 自动化测试
测试使用 UE Automation Testing Framework，并随本模块一起编译。
将每个测试文件包裹在 `#if WITH_DEV_AUTOMATION_TESTS` … `#endif` 中。
标志位：`EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`
（没有 `GameFilter` 标志）。

运行方式：Session Frontend → Automation → 选择 "<Project>." 测试
或在构建编辑器目标之后，从项目根目录以无头方式运行 —— 在全新检出上，
编辑器会在任何测试运行之前退出：
"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"
"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput
项目路径必须是绝对路径：UE 找不到相对路径（退出码 1，
"Project file not found"）。这两行是 Windows 的写法。在 Linux 上使用
`Engine/Build/BatchFiles/Linux/Build.sh <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"` 构建，
并用 `Engine/Binaries/Linux/UnrealEditor` 和相同参数运行测试；在
macOS 上使用 `Engine/Build/BatchFiles/Mac/Build.sh <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"` 构建
—— Epic 没有为测试运行记录 `UnrealEditor.app` 内部的命令行编辑器
（见 `docs/engine-reference/unreal/current-best-practices.md` 的 "Command Line"）。

读取输出，而不是退出码：失败的测试和没有匹配到任何测试的运行都会以 255 退出。
`Result={Fail}` 表示失败；`No automation tests matched` 表示没有测试被
构建，或没有测试被命名为 `<Project>.…`。

测试类命名：F[System][Scenario]Test —— 每个测试一个类；第二个
测试复用同一个类名会导致链接失败
测试名称："<Project>.[System].[Scenario]"
```

---
