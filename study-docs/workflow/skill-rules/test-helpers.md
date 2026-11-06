# test-helpers — 引擎专属测试辅助库（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/test-helpers/SKILL.md) ｜ 阶段：Phase 4-5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/test-helpers [system-name | all | scaffold]`
- **一句话职责**：生成贴合项目实际引擎、语言与系统的 `tests/helpers/` 辅助库（断言工具、工厂函数、场景/世界工具）——把常见 setup/teardown/断言模式抽象成 helper，让开发者少写样板、多写断言。
- **触发前置**：`resolve_config --keys automation` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。运行时机：`/test-setup` 脚手架搭好后（首次）；多个测试文件重复相同 setup 样板时；开始为新系统写测试时。
- **helper root（引擎唯一编译测试辅助的位置，`.claude/docs/directory-structure.md`）**：Godot → `tests/helpers/`；Unity → `Assets/Tests/EditMode/Helpers/`（在 `/test-setup` 创建的 `EditModeTests` 程序集内；PlayMode 测试也需要相同 helper 时，**先询问**再创建 `Assets/Tests/Helpers/TestHelpers.asmdef` 并从两个测试程序集引用）；Unreal → `Source/<Module>/Private/Tests/Helpers/`。文中 `tests/helpers/` 一律指当前引擎的 helper root。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml` 的 `engine.name` / `engine.language` / `testing.framework`（任一缺失/空 → 回退 `.claude/docs/technical-preferences.md` 对应值）；引擎 test root 下既有测试文件（Godot `tests/**/*_test.*`、Unity `Assets/Tests/**/*Tests.cs`、Unreal `Source/*/Private/Tests/**/*.cpp`）；`design/gdd/systems-index.md`；范围内 GDD（按节读）；`docs/architecture/tr-registry.yaml` | 引擎/语言/框架识别 / 既有风格采样 / 系统与数据类型 / 需求到已测系统映射 |
| 产出 | helper root 下：`game_assertions.[ext]`、`game_factory.[ext]`、引擎特定附加（Godot `scene_runner_helper.gd`、Unity `GameFactory.cs`、Unreal `GameTestHelpers.h`）+ 每系统 `[system]_factory.[ext]` | 只生成不存在的文件，绝不覆盖 |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

### 断言纪律（最高优先规则）
R1. **生成的 helper 必须通过配置的测试框架（`testing.framework`）的断言 API 断言，禁止裸 `assert()`**。裸 `assert()` 有两个静默害处：（§断言）
   - ① **中止运行而非使测试失败**——框架断言记录失败并继续，一个坏期望产生一个红测试；裸 `assert()` 停止执行，第一个失败把其后所有结果都藏起来；
   - ② **在 release 构建中被剥离**——建立在 `assert()` 上的 helper 恰好在你最想检查的构建里完全停止断言，且无任何报错——测试仍然"通过"。
R2. **生成代码前必须查所配置框架的断言形式**——禁止把本文件或其它技能示例里的形式当权威（它们是说明性的且已漂移：`assert_eq`、`assert_true`、`assert_that` 在 repo 里都出现过）。**不能确认正确 API 就说明并生成零 helper，禁止猜测**。（§断言）
R3. **helper 禁止继承框架的测试套件基类**——`tests/helpers/` 里继承 suite 类型的文件会被 runner 发现为一个含零测试的测试套件。helper 是普通类；只有真正的测试文件才继承 suite。（§断言）
R4. SKILL.md 的 Godot 示例中 `FAIL_IF(...)` 是**占位符不是 API**——它标记唯一必须先从项目实际框架解析的行；替代为框架真实的失败调用（**向 runner 注册失败并让套件继续**的形式）并删除标记注释。刻意不拼成 `assert_that`/`assert_eq`/`assert_true`（三者都在 repo 里出现过且互不一致，GdUnit4 的 API 不被 `docs/engine-reference/` 覆盖——写出任何一个都是断言无法溯源的 API，恰在本技能职责是阻止这种事的文件里）。**未解析的 `FAIL_IF` 到盘上是 bug；缺失的 helper 是任务**。示例同样受 R1 约束——示例里一个裸 `assert()` 就是 R1 禁止的形式出现在 R1 禁止它六十行之下；规则若不自己贯彻到自己的示例，就没人贯彻它。（§4 Godot）

### 1 — 解析参数
R5. 模式：`[system-name]` — 为特定系统生成 helper（如 `/test-helpers combat`）；`all` — 为所有有测试文件的系统生成；`scaffold` — 只生成基础辅助库（无系统特定 helper），首次运行用；无参数 → 无 helper 存在时跑 `scaffold`，否则 `all`。（§1）

### 2 — 检测引擎与语言
R6. 依次读 `engine.name`（回退 `Engine:` 值）、`engine.language`（回退 `Language:` 值）、`testing.framework`（回退 Testing 节 `Framework:` 值）。两处都配不出引擎 → "Engine not configured. Run `/setup-engine` first."。（§2）

### 3 — 载入既有测试模式
R7. 扫引擎 test root 找已在使用 的模式；取代表性样本（**至多 5 个文件**）读并提取——确保生成的 helper 匹配项目既有风格而非通用模板。另读：`systems-index.md`（哪些系统存在）、范围内 GDD（按节读：Grep `^#` 建标题图 + offset/limit；理解需要测试的数据类型与值）、`docs/architecture/tr-registry.yaml`（需求映射到已测系统）。（§3）
   - setup 模式（`before_each`/`setUp`/fixtures 写法）；
   - 常见断言模式（断言最多的是什么）；
   - 对象创建模式（测试里游戏对象/场景如何实例化）；
   - mock/stub 模式（依赖如何被替换）。

### 4 — 生成引擎专属 helper
R8. **Godot 4（GDUnit4/GDScript）** 三个基础 helper（全部断言行按 R4 解析后再发出）：（§4）
   - `game_assertions.gd`：`class_name GameAssertions extends RefCounted`；`assert_in_range`——用于 GDD 定义了边界的公式输出；`assert_signal_emitted`——lambda 按值捕获局部变量，`emitted = true` 在里面只会设 lambda 自己的副本，**改用共享 Dictionary 变异**（`var state := {"emitted": false}`），`...args`（4.5+）接受任意参数数量的信号；`assert_signal_not_emitted`；`assert_node_exists`；
   - `game_factory.gd`：`make_player` 等——用 `set_meta` 元数据模式构造无需场景树的最小对象，字段按需覆盖；
   - `scene_runner_helper.gd`：`load_scene_and_wait`——`host` 是调用方测试套件传的 `self`，加载后 `await host.get_tree().process_frame` 等一帧让 `_ready()` 完成；普通类所以 runner 不会把它发现成零测试套件；输入模拟与帧步进用 gdUnit4 自带的 `scene_runner()`。
R9. **Unity（NUnit/C#）**：`GameAssertions.cs`（`AssertInRange` 用 `Assert.That(value, Is.InRange(min, max), message)`；`AssertEventRaised` 用 `Assert.IsTrue`；`AssertHasComponent` 用 `Assert.IsNotNull`）；`GameFactory.cs`（`MakeGameObject`——`new GameObject(name)`；`MakeScriptableObject<T>`——`ScriptableObject.CreateInstance<T>`，测试后用 `Object.DestroyImmediate` 销毁）。（§4）
R10. **Unreal（C++）**：`GameTestHelpers.h` 宏——`GAME_TEST_ASSERT_IN_RANGE`（`TestTrue` + `FString::Printf`）；`GAME_TEST_ASSERT_VALID`（`IsValid(Ptr)`）；`GAME_TEST_ASSERT_SPAWNED`（`TestNotNull`）；`GameTestHelpers::CreateTestWorld`（`UWorld::CreateWorld(EWorldType::Game, false)` + `GEngine->CreateNewWorldContext`；**teardown 记得 `World->DestroyWorld(false)`**）。（§4）

### 5 — 生成系统特定 helper
R11. `[system-name]` 或 `all` 模式：（§5）
   - **只读 GDD 所需节**——`Grep pattern="^## ([0-9]+\. )?(Formulas|Edge Cases|Detailed Rules|Detailed Design)" path="design/gdd/[system].md" -A 30`（可选数字匹配反向文档 GDD 的 `## 4. Formulas`）而非全读（每个同级技能都节选 GDD；`all` 模式下全读会乘上每个系统 400+ 行的 GDD）；
   - 提取：数据类型（实体类型、组件名）、公式变量及边界、Edge Cases 提到的常见测试场景；
   - 生成 `tests/helpers/[system]_factory.[ext]`——工厂函数 + 从 GDD 来的常量边界（如 `DAMAGE_MIN`/`DAMAGE_MAX` 注明 "From GDD"）+ 调 `GameAssertions` 的边界断言（如 `assert_damage_in_bounds`）。

### 6 — 写输出
R12. 先展示待创建摘要（基础 helper + 系统 helper 各自路径与来源 GDD），询问 "May I write these helper files to `[helper root]`?"。**绝不覆盖既有文件**——已存在则报 "Skipping `[path]` — already exists. Remove the file manually if you want it regenerated."。写后 Verdict：**COMPLETE** — helper files created，附使用说明（Godot：`class_name` 自动导入无需显式 import；Unity：加 `using` 指令或引用测试程序集；Unreal：模块内 `#include "Tests/Helpers/GameTestHelpers.h"`）。（§6）

### 协作协议
R13. 协作底线：
   - **绝不覆盖既有 helper**——它们可能有手写定制；只生成还不存在的新文件；
   - **生成代码是起点**——工厂函数为简洁用元数据模式；代码存在后适配实际类结构；
   - **helper 必须反映 GDD**——helper 中的边界和常量要能追溯到 GDD Formulas 节，禁止发明数值；
   - **写前询问**——在 `tests/` 下创建文件前恒确认。

## 4. 门禁与裁决
- **裁决词**：`COMPLETE` — helper files created（无其它出口；引擎未配置时重定向 `/setup-engine`，不能确认框架 API 时零产出并说明）。
- 本技能无独立门禁；其产物质量由 R1-R3 的断言纪律约束——违规 helper 会造成"release 构建静默不断言"与"零测试套件被发现"两类假绿。
- **消费方**：`/dev-story`（写测试时用 helper 减样板）、`/regression-suite`（建议经 `/test-helpers` 补写缺失回归测试）、`/test-evidence-review`（断言过薄时建议跑本技能看脚手架断言模式）。

## 5. 移植建议
- **可直接移植**：R1（框架断言 vs 裸 assert 的两条静默害处——中止运行 / release 剥离）、R2（不能确认 API 就零产出而非猜测——示例漂移的教训）、R3（helper 不得继承测试套件基类，否则被发现为零测试套件）、R4（占位符纪律与"规则必须贯彻到自己的示例"）、R11（按节 grep 而非全读大规格文档，`all` 模式下成本相乘）、R13（常量必须溯源到规格文档，禁止发明数值）。
- **需替换概念**：三引擎 helper 模板 → 你的语言断言库/fixture 工厂（pytest fixtures + 自定义断言、testify suite、JUnit helpers）；GDD Formulas 边界 → 规格/契约中的数值约束；`set_meta` 元数据对象 → 最小可测构造（test double、builder）；`scene_runner()` → 框架的场景/容器启动器。
- **改写示例**：
  - R1 → "测试辅助库必须通过项目所配置测试框架的断言 API 报告失败，禁止语言内建的 assert：内建 assert 会中止整个运行（首个失败吞掉其后全部结果），并在 release 构建中被编译器剥离——辅助库恰恰在最需要检查的构建里静默停止断言。"
  - R3 → "测试辅助文件必须是普通类/函数模块，禁止继承框架的测试套件基类：放在测试目录里又继承套件类型的文件会被 runner 识别为一个含零个测试的套件，污染测试发现。"

## 6. 关联文档
- 上游：`/test-setup`（脚手架与 helper root 的来源）、`/setup-engine`（引擎/语言/框架配置）。
- 下游：`/dev-story`（实现 story 时使用 helper）、`/regression-suite`（补写回归测试的推荐工具）、`/skill-test`（验证其它技能是否需要 helper 覆盖）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/directory-structure.md`、`.claude/docs/technical-preferences.md`、`docs/architecture/tr-registry.yaml`。
