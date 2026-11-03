# test-setup — 测试脚手架与 CI/CD（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/test-setup/SKILL.md)（步骤外置在 `references/1-detect.md` ~ `6-summary.md`，已全部抽取） ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/test-setup [force]`
- **一句话职责**：搭建自动化测试基础设施——检测配置引擎、生成对应测试 runner 配置、创建标准目录布局、接好 CI/CD 让每次 push 跑测试。
- **触发前置**：在 Technical Setup 阶段、任何实现开始前跑一次——"sprint 开始时装测试框架花 30 分钟；sprint 四才装，花 3 个 sprint"。`resolve_config --keys automation,workflow,qa.level` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml` 的 `engine.name`（缺失/空/无 `engine:` 块 → 回退 `.claude/docs/technical-preferences.md` 的 `Engine:` 值）；既有状态 glob：`tests/`、`tests/unit/`、`tests/integration/`、`.github/workflows/`、引擎特定（`addons/gdUnit4/bin/GdUnitCmdTool.gd`（大写 U）/ `Assets/Tests/EditMode/` / `Source/*/Private/Tests/`）；Unity 的 `Packages/manifest.json` | 引擎识别 / 已有基础设施探测 / Test Framework 安装检查 |
| 产出 | `tests/` 目录结构（README、占位文件、smoke 种子）+ `production/qa/evidence/.gitkeep` + 引擎特定 runner/asmdef/README + `.github/workflows/tests.yml` | 只创建缺失文件，绝不覆盖既有 |
| 派生智能体 | 无，主会话直接执行 | — |

**test roots（`.claude/docs/directory-structure.md`）**：Godot `tests/unit/` 与 `tests/integration/`；Unity `Assets/Tests/`；Unreal `Source/*/Private/Tests/`——**别处的测试在 Unity/Unreal 从不被编译**。

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 检测引擎与既有状态（references/1-detect.md）
R1. 两处都配不出引擎（`engine.name` 缺失/空且 `technical-preferences.md` 为 `[TO BE CONFIGURED]` 或缺失）→ 停止："Engine not configured. Run `/setup-engine` first, then re-run `/test-setup`."——**引擎检测不可协商，禁止猜**。（Phase 1）
R2. 探测既有测试基础设施（目录、CI、引擎特定工件——它们是 test roots，别处的测试不编译）；报告 "Engine: [engine]. Test directory: [found/not found]. CI workflow: [found/not found]."。全部已存在且**未传 `force`** → 提示 "Re-run with `/test-setup force` to regenerate. Proceeding will not overwrite existing test files." 后早退。**`force` 跳过 "已存在" 早退但从不覆盖**——只创建缺失文件。（Phase 1）

### Phase 2 — 呈现计划（references/2-plan.md）
R3. 按引擎与既有状态展示计划（跳过已存在项）：`tests/unit/` + `tests/integration/`（**仅 Godot**）+ `tests/smoke/`（15 分钟手工门的关键路径清单）+ `tests/README.md`；Unity/Unreal 的 unit/integration 测试改放引擎 test root（Unity `Assets/Tests/EditMode|PlayMode/`、Unreal `Source/<Module>/Private/Tests/`——两者都不编译 `tests/` 下的代码）；`production/qa/evidence/`；引擎特定文件；`.github/workflows/tests.yml`。询问 "May I create these files? I will not overwrite any test files that already exist."——**collaborative 与 guided 都不批准不继续**（`automation-modes.md:81` 对 guided 也门禁新文件写入，两模式答案相同）；autonomous 创建并记录决策、不阻塞。（Phase 2）

### Phase 3 — 创建目录结构（references/3-directories.md）
R4. `tests/README.md` 必须写明：
   - 引擎与版本、Test Framework（GdUnit4 | Unity Test Framework | UE Automation）、CI 路径、Setup 日期；
   - 目录布局（Unity/Unreal 替换 unit/integration 行——测试在引擎 test root，`tests/` 只留 README 与 `smoke/`，**README 中每个 `tests/unit/` 路径都指 test root**）；**手工证据在 `production/qa/evidence/` 而非 `tests/`**——那是所有消费者（`/smoke-check`、`/test-evidence-review`、`/qa-plan`、coding-standards 证据表）读取的地方，`tests/evidence/` 是没人读的目录；
   - Running Tests（引擎命令）；
   - Test Naming：Godot 文件 `[system]_[feature]_test.gd` + 函数 `test_[scenario]_[expected]`；Unity 类 `[System]Tests` 于 `[System]Tests.cs` + 方法 `[Scenario]_[Expected]`；Unreal 类 `F[System][Scenario]Test` + 测试名 `<Project>.[System].[Scenario]`——`<Project>` 是 `commands.test` 过滤器所用的根，**要写出来**：项目名或 `/setup-engine` 所选的不同根；
   - Story Type → Test Evidence 表：Logic → 自动单元测试必须通过 `tests/unit/[system]/`；Integration → 集成测试或 playtest 文档；Visual/Feel → 截图 + lead sign-off 于 `production/qa/evidence/`；UI → 每触碰屏幕的保留截图；Config/Data → smoke 通过 `production/qa/smoke-*.md`；
   - CI 说明：push main 与 PR 自动跑，失败阻塞合并。（Phase 3）
R5. 创建空的 `production/qa/evidence/.gitkeep`——git 不保留空目录，而 `/story-done`、`/smoke-check`、`/test-evidence-review` 在此找截图与 sign-off 记录，完成摘要会列出它，所以它必须存在。（Phase 3）
R6. **Godot 4**：**不写 runner 脚本**——gdUnit4 自带 `res://addons/gdUnit4/bin/GdUnitCmdTool.gd`，CI/`/smoke-check`/`commands.test` 用两行命令：先 `godot --headless --path . --import`，再 `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`。（Phase 3）
   - **必须先 import**：新 clone 无 `.godot/` 类缓存 → exit 1（`GdUnitCmdTool.gd` 未加载，`Failed to load script`）；缓存早于新 `class_name` → 合法代码以 105 失败；
   - **exit code**：**0** 全过、**100** 有失败（于 Godot 4.6.1 + gdUnit4 6.1.3 与 4.7.2 + 6.2.2 验证）；**101** = 全过但泄漏节点——warning 非失败；103/104 = 无法 headless 运行（拒绝 / Godot < 4.3）；105 = 测试脚本不解析；
   - **命令行标志**：`-a res://tests` 跑 `tests/` 下全部套件；`--ignoreHeadlessMode` 必须（否则拒绝 headless）；`--remote-debug tcp://127.0.0.1:0` 也必须（gdUnit4 自己的 `runtest` 脚本就这么传）——无它脚本错误会打开交互调试器永远停在 `debug>` 而非 exit 105；该标志使每次运行打两行关于远程端口的 `ERROR:`——**是预期的，不是失败**。零测试的运行打 `No test cases found` 并 exit 0——**不是 pass**；
   - **目录与安装**：文件夹是**大写 U** 的 `addons/gdUnit4/`。创建 `tests/unit/.gdignore_placeholder` 与 `tests/integration/.gdignore_placeholder`（各一行注释：每系统一个子目录）。README 注记安装 GdUnit4 四步（Asset Store（Godot 4.7 前为 AssetLib）→ 启用插件 → 重启 → 验证 `GdUnitCmdTool.gd` 存在（大写 U））。
R7. **Unity**：测试放 **`Assets/Tests/`** 下——Unity 只编译 `Assets/` 与 `Packages/`；`tests/` 下的测试从不编译，运行报 **0 tests、`Passed`、exit 0**（6000.3.23f1 上验证）——**假 pass**。（Phase 3）
   - **Test Framework 检查**：先查 `grep -q 'com.unity.test-framework' Packages/manifest.json`——没有它 `-runTests` 不失败而是**挂起**；缺失时**询问**后添加到 `dependencies`，版本用编辑器自带（Unity 6 各版不同——6000.3.23f1 是 1.6.0、6000.1.0f1 是 1.5.1——**读它而非抄数**：Windows 下 `Unity.exe` 所在文件夹的 `Data/Resources/PackageManager/BuiltInPackages/com.unity.test-framework/package.json` 的 `version`）；
   - **asmdef 双文件**：`Assets/Tests/EditMode/EditModeTests.asmdef`（unit 测试，无 Play Mode：name `EditModeTests`、references `UnityEngine.TestRunner`+`UnityEditor.TestRunner`、includePlatforms `["Editor"]`、overrideReferences true、precompiledReferences `nunit.framework.dll`、autoReferenced false、defineConstraints `UNITY_INCLUDE_TESTS`）与 `Assets/Tests/PlayMode/PlayModeTests.asmdef`（运行中场景的集成测试：同 JSON 但 name `PlayModeTests`、includePlatforms `[]`）；
   - **测试程序集看不见默认 `Assembly-CSharp` 里的代码**——asmdef 只能引用其它 asmdef；游戏脚本没有自己的 asmdef 时，**先询问**再创建（如 `Assets/Scripts/Game.asmdef`）并把 `"Game"` 加进两个测试程序集的 references，否则第一个点名游戏类的测试编译失败。创建前**列脚本用到的包**（Assembly-CSharp 自动引用每个包，asmdef 只引用它命名的——读 using 行加对应程序集，常见 `Unity.InputSystem`/`Unity.TextMeshPro`/`UnityEngine.UI`；只命名项目已装的）；**给其下每个 `Editor/` 文件夹单独 asmdef**（includePlatforms `["Editor"]` + references `["Game"]`）——否则 editor 脚本混入运行时程序集，`using UnityEditor;` 破坏 player build；
   - **运行与解读**：README 记运行命令（**用 editor 可执行文件**——PATH 上的 `Unity` 可能是独立 CLI）：EditMode 与 PlayMode 各一行（`-batchmode -runTests -projectPath . -testPlatform … -testResults …`）。exit **0** 全过、**2** 失败；**1 或 3 也是 FAIL**（1 = 编译错误不写 results 文件；3 = 运行失败）；4（未知 `-testPlatform`）及其它非零同 FAIL。**每次运行前删 `test-results/editmode.xml`**——旧文件绝不能被读成新结果。读 results 的 `<test-run>` 元素：`testcasecount="0"` = 没编译或没找到——报 not assessed，**绝非 pass**。**不加 `-quit`**（`-runTests` 自行退出）；
   - **Play Mode 是第二行**：独立运行、独立 results 文件、同样先删、同样解读——EditMode 运行从不跑 `Assets/Tests/PlayMode/` 里的测试，所以该文件夹有测试时 `/smoke-check` 两个都跑。
R8. **Unreal**：测试放**游戏模块内** `Source/<Module>/Private/Tests/`（`<Module>` = 主游戏模块，C++ 项目为 `.uproject` 名）。UnrealBuildTool 只编译模块文件夹——`Source/` 直下的 tests 文件夹不是模块，那里的测试**静默不编译**，每次运行报 `No automation tests matched`。创建该处 `README.md`：每个测试文件包 `#if WITH_DEV_AUTOMATION_TESTS` … `#endif`；flags 用 `EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`（**没有 `GameFilter` flag**）；运行方式（Session Frontend → Automation 选 `<Project>.`，或 build editor target 后 headless——fresh checkout 不 build 时编辑器在任何测试前退出）；项目路径必须**绝对**（UE 找不到相对路径，exit 1 "Project file not found"）；Windows 两条命令（UnrealBuildTool.exe build + UnrealEditor-Cmd.exe 跑测试）、Linux（`Engine/Build/BatchFiles/Linux/Build.sh` + `Engine/Binaries/Linux/UnrealEditor` 同参数）、macOS（`Engine/Build/BatchFiles/Mac/Build.sh`；Epic 未文档化 `UnrealEditor.app` 内的命令行编辑器，见 `docs/engine-reference/unreal/current-best-practices.md`）。**读输出不读 exit code**：失败与零匹配都 exit 255；`Result={Fail}` 是失败；`No automation tests matched` = 没有测试被构建或没命名为 `<Project>.…`。测试类命名 `F[System][Scenario]Test`——**一测试一类**，复用类名的第二个测试链接失败；测试名 `"<Project>.[System].[Scenario]"`。（Phase 3）

### Phase 4 — 创建 CI/CD 工作流（references/4-ci.md）
R9. `.github/workflows/tests.yml`（push main + PR 触发）按引擎生成：
   - **Godot**：`godot-gdunit-labs/gdUnit4-action@v1`，**必须** `permissions: contents: read + checks: write`——新仓库 token 只读，没有 `checks: write` 即使全过 job 也失败；保护 main 时**要求 `Run GdUnit4 Tests` job 检查而非 `test-results`**——该 check run 在测试失败时也结论成功。`godot-version` 必须是完整版本号如 4.7.2（`godot --version` 显示的；`VERSION.md` 的 "4.7" 不是）；`version: 'installed'` 跑 `addons/` 里提交的 gdUnit4——没有它 action 会删掉那份装最新 release，可能不匹配你的测试。paths 给 `tests/unit` + `tests/integration`；artifact 上传 `reports/`。
   - **Unity**：`game-ci/unity-test-runner@v4` 两个 step（editmode / playmode 各自 `artifactsPath`）；**`UNITY_LICENSE` secret 必须手动配置**——在首次 CI 运行前加进 GitHub 仓库 secrets，不尝试自动化许可证管理。
   - **Unreal**：`runs-on: [self-hosted, windows]`（UE 需装编辑器的本地 runner；`windows` 标签把 job 挡在仓库可能有的 Linux self-hosted runner 之外）。每步 `shell: bash --noprofile --norc -eo pipefail "{0}"`——Windows runner 给 bash 传脚本路径不加引号，纯 `shell: bash` 在 runner 文件夹带空格时每步失败。先 **Build Editor Target**（`Binaries/` 被 gitignore，fresh checkout 无编译好的游戏模块——无此步编辑器以 "The game module could not be found" 在任何测试前停；用 `UnrealBuildTool.exe` 不用 `Build.bat`——bash 下 Build.bat 在引擎路径带空格时失败）。再 **Run Automation Tests**（`-nullrhi -nosound -ExecCmds="Automation RunTests [ProjectName].; Quit" -unattended -stdout -FullStdOutLogOutput`——没有 `-stdout -FullStdOutLogOutput` 编辑器什么都不打，结果只在 `Saved/Logs/`）。runner 上设 `UE_ROOT` 指向引擎文件夹（如 `C:/Program Files/Epic Games/UE_5.8`）；`[ProjectName]Editor` 是 `Source/[ProjectName]Editor.Target.cs` 里的 editor target；`actions/checkout@v7` 与 `actions/upload-artifact@v7` 跑在 Node.js 24 上、需要 Actions Runner 2.327.1+——首次运行前更新 self-hosted runner。（Phase 4）

### Phase 5 — 冒烟测试种子（references/5-smoke-seed.md）
R10. 创建 `tests/smoke/critical-paths.md`：Purpose（QA 交接前 10-15 项检查 15 分钟内跑完）；Run via `/smoke-check`（该技能读此文件）；Update 指引（新核心系统实现时加条目）。四节：**Core Stability（恒跑）** 3 项（启动到主菜单不崩溃；主菜单能开新游戏/会话；主菜单响应所有输入不冻结）；**Core Mechanic（每 sprint 更新）**——占位项 + 注释示例；**Data Integrity** 2 项（存档无错完成、读档恢复正确状态——存读系统实现后）；**Performance** 2 项（目标硬件无可感知掉帧（60fps 目标）、核心循环实现后 5 分钟游玩无内存增长）。（Phase 5）

### Phase 6 — 收尾摘要（references/6-summary.md）
R11. 写完全部文件后报告：创建的文件清单（README / test root 目录或引擎 test root / smoke 种子 / evidence/.gitkeep / 引擎特定 / CI）+ Next steps：（Phase 6）
   - ① 引擎特定安装步骤；
   - ② 在 test root 写第一个测试（Godot `tests/unit/[system]/[system]_[feature]_test.gd`、Unity `Assets/Tests/EditMode/[System]Tests.cs`、Unreal `Source/<Module>/Private/Tests/[System]Test.cpp`）；
   - ③ 首个 sprint 前跑 `/qa-plan sprint` 分类 story 并设证据要求（`workflow: minimal`——默认——跳过：没有 sprint；`qa.level: minimal` 也默认：测试豁免、`/dev-story` 不写——用 `/settings` 调高 `qa.level` 才会写）；
   - ④ 每次 QA 交接前 `/smoke-check`。

   **Gate note**：Technical Setup → Pre-Production 门禁现在要求引擎 test root + `.github/workflows/tests.yml` + 至少一个示例测试文件（`workflow: minimal` 只要求引擎）。Verdict：**COMPLETE** — test framework scaffolded and CI/CD wired up。

### 协作协议
R12. **绝不覆盖既有测试文件**——只创建缺失的；runner 文件已存在就原样留下。**创建文件前总是询问**——Phase 2 需明确批准。**引擎检测不可协商**——未配置就停止并重定向 `/setup-engine`，禁止猜。**`force` 只跳过 "already exists" 早退，从不覆盖**——意为"目录已存在也把缺失文件补齐"。Unity CI 的 `UNITY_LICENSE` secret 必须手动配置，禁止尝试自动化许可证管理。

## 4. 门禁与裁决
- **裁决词**：`COMPLETE`（脚手架搭好且 CI/CD 接通）；引擎未配置时无裁决、直接重定向 `/setup-engine`。
- **门禁关联**：本技能的产物是 `/gate-check` Technical Setup → Pre-Production 门禁的检查对象（test root + CI 工作流 + 至少一个示例测试）。
- **写入门禁**：所有文件创建都经 Phase 2 批准（collaborative 与 guided 同样要求；autonomous 记录后继续）。

## 5. 移植建议
- **可直接移植**：R2（`force` 语义——补齐缺失而非重建/覆盖）、R6-R8 中与具体引擎无关的通用陷阱——"零测试 + exit 0 = 假 pass"、"删旧结果文件防上次 pass 被读成这次"、"测试必须在构建系统真正编译的目录里（否则静默不编译，每次报零匹配）"、"挂起比失败更危险（依赖缺失时先查再跑）"、R12 全部。
- **需替换概念**：三引擎分支 → 你的语言/框架（pytest+GitHub Actions、Jest+CI、Go test 等）——逐条换算"看起来像成功却不是"的清单；`production/qa/evidence/` → 工件的证据目录；`commands.test` → 项目测试命令配置键；`/setup-engine` → 环境初始化流程；`/smoke-check` → 冒烟门。
- **改写示例**：
  - R7 → "测试必须放在构建系统实际编译的目录中。放在约定之外的目录不会报错——它们被静默跳过，每次运行报告零测试且退出码为成功。脚手架建立后必须验证：跑一次空套件确认结果是'零测试'而非'通过'。"
  - R9 → "CI 工作流的最小权限必须包含结果上报所需的写权限（如 checks: write），否则即使全部测试通过 job 也会失败；且分支保护应要求具体测试 job 的检查，而不是结果 artifact 的检查——后者在测试失败时也可能显示为成功。"

## 6. 关联文档
- 上游：`/setup-engine`（引擎与 `commands.*` 配置来源）。
- 下游：`/qa-plan`（story 分类与证据要求）、`/smoke-check`（读 `tests/smoke/critical-paths.md` 与 test root）、`/test-helpers`（在 test root 生成辅助库）、`/dev-story`（按 `qa.level` 写测试）、`/gate-check`（Technical Setup 门禁）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/directory-structure.md`、`.claude/rules/test-standards.md`、`docs/engine-reference/`。
