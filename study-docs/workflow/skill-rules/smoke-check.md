# smoke-check — 关键路径冒烟门（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/smoke-check/SKILL.md)（步骤外置在 `references/1-detect-setup.md` ~ `6-write-gate.md`，已全部抽取） ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/smoke-check [sprint | quick] [--platform pc|console|mobile|all]`（参数可组合）
- **一句话职责**："实现完成"与"可交接 QA"之间的门——跑自动化套件、查覆盖缺口、与开发者批量核对关键路径、产出 PASS/FAIL 报告并按裁决放行或拦截。
- **触发前置**：实现已完成；核心规则：**冒烟失败的 build 不进 QA**。`resolve_config --keys automation,workflow,qa.level,testing.strict` 已解析；每个 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`。
- **`qa.level` 档位**：`minimal` → 冒烟可选，FAIL 仅为 advisory 绝不阻塞交接，无游戏测试的项目仅靠 build/launch/关键路径检查（Phase 1 步骤 1）；`standard` → 阶段转换前必须；`full` → 每次 commit 前。与 `workflow` 轴独立。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml`（`commands.test`/`commands.smoke`/`commands.build`/`engine.name`/`engine.path`）回退 `.claude/docs/technical-preferences.md`；引擎 test root（Godot `tests/unit/`+`tests/integration/`、Unity `Assets/Tests/`、Unreal `Source/*/Private/Tests/`）与 `tests/smoke/`；`.github/workflows/`；`production/qa/smoke-tests.md`；最新 `production/qa/qa-plan-*.md`；最新 sprint 计划；story 文件 | 环境/测试存在性/冒烟清单/story 覆盖 |
| 产出 | `production/qa/smoke-[date].md`（写入前须批准） | 门禁报告，驱动 QA 交接 |
| 派生智能体 | 无，主会话直接执行（手工核对经 `AskUserQuestion` 批量问开发者） | — |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 检测测试环境（references/1-detect-setup.md）
R1. 先跑 `bash .claude/scripts/project-coherence.sh` 做**配置一致性**检查——它对比 `project.yaml` 声明与真实项目文件、已装引擎二进制、`commands.*` 所指对象；`commands.test` 指向不存在的 runner 或 `commands.build` 指向无 `export_presets.cfg` 的导出预设会在此失败，读起来像坏 build 实为坏配置。`[DIFFERS]` 行报告进 Environment 节，本身不决定裁决。（Phase 1）
R2. **测试框架检查必须数真实游戏测试文件，禁止只看 `tests/` 目录存在**——`/test-setup` 会创建带占位文件的目录树，目录在≠测试在；以目录为门，零测试无 build 的项目也能过。测试文件 = 引擎 runner 会执行的文件（`*_test.gd` 套件、C# 测试类、Unreal automation 源文件）；markdown 清单不算（`tests/smoke/critical-paths.md` 恒被 `/test-setup` 写出，计入会掩盖本步要抓的零测试态）。（Phase 1）
R3. 无游戏测试文件的分支：`qa.level: minimal` → 记 `WAIVED — qa.level: minimal, no game tests`，跳过 Phase 2 测试运行与整个 Phase 3（各一行说明），仍跑 Phase 2 的 **build check**，继续 Phase 4——无测试项目靠 build/launch/关键路径仍可 PASS，**但绝不能没有运行**：Batch 1 答复本会话未启动 build → 裁决 NOT ASSESSED。`standard`/`full` → **必须给出 `NOT ASSESSED — no game tests found` 裁决而非裸停**（"技能什么都没说"易被读成"没什么问题"；用无裁决替换错裁决也不是改进——诚实结果要点名无法确立什么），提示跑 `/test-setup` 或指出测试所在。（Phase 1）
R4. 引擎检测：`engine.name`（缺失/空/[TO BE CONFIGURED] 回退 `technical-preferences.md`）。然后找 **editor 可执行文件**——三引擎在 Windows/macOS 默认不装进 PATH，裸 `godot` 解析失败不说明引擎未装。取第一个解析到的：`commands.test` 所指（Godot 仅当文件名含 godot——`bash run-tests.sh` 之类 wrapper 不是编辑器）→ `engine.path` → PATH 上引擎名。全不解析 → runner 不可用（Phase 2）；Godot 记 `NOT ASSESSED — Godot executable not found (commands.test, engine.path, PATH)`。另查 CI（`.github/workflows/` 有无引用测试的工作流）、smoke 清单（`production/qa/smoke-tests.md` 或 `tests/smoke/`）、最新 QA plan（无则提示先跑 `/qa-plan sprint`；`workflow: minimal` 无 sprint，QA plan 可选——说明而非推荐）。报告 Environment / Editor / Test directory / CI / QA plan。（Phase 1）

### Phase 2 — 跑自动化测试（references/2-run-tests.md）
R5. `commands.test` 已设时**优先用它**（项目自己的测试命令，`/setup-engine` 所写、CI 所跑）；缺失才用引擎默认，并在报告中说明跑的哪一个。必须包 timeout（`timeout 900 …`）——**超时（exit 124）是门禁 FAILURE，绝不通过**（运行没完成，什么都没验证）。macOS 无 `timeout`：用 `gtimeout 900`（Homebrew coreutils，同 exit 124）或 `perl -e 'alarm shift; exec @ARGV' 900 …`（exit 142，同为 FAILURE）。（Phase 2）
R6. **Godot 4**：先确认 `addons/gdUnit4/bin/GdUnitCmdTool.gd` 存在（文件夹是**大写 U** 的 `gdUnit4`）——不存在记 `NOT ASSESSED — gdUnit4 not installed`，禁止跑任何东西。无论用 `commands.test` 还是默认，**先 import**（`godot --headless --path . --import`）：新 clone 无 `.godot/` 类缓存则 runner 不加载；缓存早于新 `class_name` 会让合法代码以 105 失败。exit code 裁决（6.1.3 与 6.2.2 上验证）：**0** 全过 PASS——**但零测试上的 exit 0 不是 pass**：gdUnit4 中止也 exit 0，输出含 `No test cases found` → `NOT ASSESSED — no tests found`；**101** 全过但泄漏节点（orphans）→ PASS WITH WARNINGS（点名 orphan 数），不是失败；**100** 有测试失败 FAIL；**105** 脚本不解析 FAIL；**103** 拒绝 headless、**104** Godot < 4.3 → NOT ASSESSED（附原因）；**1** `GdUnitCmdTool.gd` 未加载（通常是跳过了 import；import 后 exit 1 是 FAIL）。每次运行开头两行关于远程端口（`127.0.0.1:0`）的 `ERROR:` 是 `--remote-debug` 生效的表现——**绝不丢该标志**，否则脚本错误会打开交互调试器挂到 `debug>` 提示符直到超时。（Phase 2）
R7. **Unity**：能 headless 跑就跑，禁止跳到读 artifacts。先确认 Test Framework 已装（`grep -q 'com.unity.test-framework' Packages/manifest.json`）——未装不会干净失败而是**挂起**；ABSENT → 记 `NOT ASSESSED — Unity Test Framework not installed` + 一行修复，**禁止转读陈旧 artifacts**（未知时龄的 XML 被报成 pass 比没有门更糟）。默认用 **editor** 可执行文件（PATH 上的 `Unity` 可能是独立 CLI）。无论跑哪个命令，**先删旧 results 文件**：编译错误不写 results，留着旧的会把上次的 pass 读成本次的。exit 0 全过、2 失败；**1 或 3 也是 FAIL**（1 = 编译错误——editor 日志有 `error CS…`；3 = 运行失败）；4（未知 `-testPlatform`）及其它非零也是 FAIL；任何 exit 后无 results 文件是 FAIL。解析 results 的 `<test-run>` 元素取 `testcasecount`/`passed`/`failed`——**`testcasecount="0"` 是 NOT ASSESSED 绝不是 pass**（`Assets/` 外的测试从不编译，Unity 会报 `result="Passed"` + exit 0 的零测试）。（Phase 2）
R8. **Unity Play Mode 是第二次运行**：`-testPlatform EditMode`（默认与 `/setup-engine` 写的 `commands.test`）从不跑 `/test-setup` 脚手架在 `Assets/Tests/PlayMode/` 下的集成测试。该文件夹有测试文件且所跑命令未含 `-testPlatform PlayMode` → 用同样方式跑 Play Mode 到独立 results 文件（先删旧），同样规则解读。每平台单独一行报告（`EditMode: PASS (12/12)`、`PlayMode: FAIL (1 failure)`）；跑不了的按名报告 `PlayMode: NOT RUN — [reason]`——EditMode 结果不覆盖那些测试，不能让自动化行变 PASS。（Phase 2）
R9. **Unreal**：先 build editor target（无论随后跑 `commands.test` 还是默认）——`Binaries/` 不提交，无已编译 game module 时编辑器以 "The game module could not be found"、exit 1 在任何测试前停下。build 是增量的；build 失败是 FAIL。用 `uname -s` 选命令（Linux→Linux、Darwin→macOS、`MINGW*`/`MSYS*`/`CYGWIN*`→Windows）；Windows 用 `UnrealBuildTool.exe` 而非 `Build.bat`（bash 下引擎路径带空格时 Build.bat 失败）。保留 `-stdout -FullStdOutLogOutput`（`commands.test` 缺就在本次运行补上并在报告说明，让用户修 `commands.test`——**绝不未经询问改 `project.yaml`**）。项目给**绝对路径**（UE 5.7 找不到相对 `.uproject`，exit 1 `Project file not found`）；`$(pwd -W 2>/dev/null || pwd)` 给 Git Bash `C:/…` 形式（`$PWD` 在 `MSYS_NO_PATHCONV` 设定时失败）。`<Project>.` 是测试命名根：项目名或 `/setup-engine` 选的不同根。**macOS 无 sourced 测试命令**（Epic 只文档化 `UnrealEditor.app` bundle）→ 跑用户已设并确认的 `commands.test`；没有则记 `NOT ASSESSED — Unreal test command on macOS not sourced`，禁止猜路径。读输出不读 exit code（失败与零匹配都 exit 255）：`Result={Fail}` 任一行 → FAIL；`No automation tests matched` → `NOT ASSESSED — no tests found`（`Source/<Module>/` 外的测试从不编译），不是 FAIL；exit 0 + `Result={Success}` → PASS；其它非零 → FAIL；例外：编辑器从未启动（exit 126/127，`command not found`）→ runner 不可用，NOT ASSESSED。（Phase 2）
R10. 引擎未知/未配置 → 提示跑 `/setup-engine` 后重跑。**runner 不可用**（无可执行文件等）→ 报告 "Status will be recorded as NOT RUN"，开发者从本地 IDE 或 CI 确认前裁决是 **NOT ASSESSED——不是 FAIL 也不是 pass**：未跑的套件不是健康的 build，是未知的 build，两者需要不同后续。解析 runner 输出提取：总测试数、通过数、失败数、失败测试名（最多 10 个，更多则计数）、runner 自身的崩溃或错误输出。（Phase 2）
R11. **Build check（仅 WAIVED 路径）**：无套件可跑时跑项目自身启动检查——`commands.smoke` 优先，否则 `commands.build`，用 Phase 1 解析的可执行文件，同 timeout 规则（900；`commands.build` 用 1800；超时是 FAIL）。Godot 先跑 import。按 `/setup-engine` 文档解读：Godot `smoke` 即使 parse error 也 exit 0——输出中的 `SCRIPT ERROR` 行是 FAIL，`Can't run project: no main scene defined` 也是 FAIL（游戏无法启动）；Unity `smoke` 编译错误 exit 1；其它非零 exit 是 FAIL。记录 `Build check: PASS — [command] exit 0` / `FAIL — [reason]` / `NOT RUN — [原因]`。未跑的 build check 在报告中点名，把裁决留给 Batch 1 的启动检查——**从不独自通过**。（Phase 2）

### Phase 3 — 检查测试覆盖（references/3-coverage.md）
R12. story 清单来源优先级：QA plan（其 Test Summary 表列出每 story 的期望测试文件路径）→ `production/sprints/` 最新 sprint 计划。`quick` 参数 → 整个跳过本阶段并注记 "Coverage scan skipped — run `/smoke-check sprint` for full coverage analysis."。（Phase 3）
R13. 每 story：从文件路径提取 system slug（如 `production/epics/combat/story-001.md` → `combat`）；glob `tests/unit/[system]/` 与 `tests/integration/[system]/` 找名字含 story slug 或紧密相关词的文件；查 story 文件的 `Test file:` 头字段或 "Test Evidence" 节。覆盖状态五值：**COVERED**（找到匹配该 story 系统与范围的测试文件）/ **MANUAL**（Visual/Feel 或 UI 类型且找到测试证据文档）/ **MISSING**（Logic 或 Integration story 无匹配测试文件）/ **EXPECTED**（Config/Data——无需测试文件，抽查即可）/ **UNKNOWN**（story 文件缺失或不可读）。MISSING 是 advisory gap——不导致 FAIL 但必须在报告中显著出现，且必须在 `/story-done` 完全关闭前解决。（Phase 3）

### Phase 4 — 手工冒烟检查（references/4-manual-checks.md）
R14. 冒烟清单来源优先级：QA plan 的 "Smoke Test Scope" 节 → `production/qa/smoke-tests.md` → `tests/smoke/` 目录内容 → 标准回退清单（仅前三者都不存在时）。**必须在报告中单独一行点名所用来源**——回退是真实回退（没有条目被静默跳过），但不写这行，通用清单生成的报告与项目自身 smoke 定义生成的报告读起来一样；`/gate-check` 要对照 repo 验证 smoke 报告的主张，不知道清单出处就无法掂量。Batch 2/3 按实际系统裁剪，方括号占位符换成当前 sprint 的真实机制名。（Phase 4）
R15. 用 `AskUserQuestion` 批量核对，**至多 3 次调用**。**Batch 1 核心稳定性（恒跑）**：一次调用两个问题——本会话是否启动过当前 build（空失败清单无意义，除非有人启动过 build）；核心稳定性失败项多选（启动崩溃/新游戏失败/主菜单无响应/基本导航崩溃挂起）。任何选中项在生成报告前要求用户简述。**build 未启动** → Batch 1 记 `NOT RUN — build not launched this session`，跳过 Batch 2、3 与平台批次（说明它们需要运行中的 build），忽略未选的失败清单，裁决 NOT ASSESSED（除非另有 FAILED）。（Phase 4）
R16. **Batch 2 sprint 变更与回归（恒跑）**：本 sprint 主机制、其它显著变更、上 sprint 特性回归、其它意外损坏的多选失败项。**Batch 3 数据完整性与性能（`quick` 除外）**：存/读档失败或 N/A（未实现）、帧率掉帧、本次未查性能。每响应**逐字记录**供 Phase 5 报告。（Phase 4）
R17. **平台批次（仅 `--platform` 时）**：PC（键盘、鼠标/光标可见性、窗口/全屏、分辨率）；Console（手柄、TV 安全区外 UI/文字裁剪、给手柄用户显示键鼠回退、冷启动）；Mobile（触摸、横竖屏切换、前后台切换、目标设备性能/热节流）。任一平台的 FAIL 计入整体 FAIL。（Phase 4）

### Phase 5 — 生成报告（references/5-report.md）
R18. 报告节：（Phase 5）
   - **Automated Tests**：Status：PASS / PASS WITH WARNINGS / FAIL（失败数，或未完成：timeout | 编译/解析/build 错误 | 无 results 文件）/ NOT ASSESSED（原因如零测试、runner 无法跑）/ NOT RUN（原因）/ WAIVED（qa.level: minimal — no game tests）；Unity 每测试平台一行；WAIVED 时加 Build check 行；
   - **Test Coverage 表**（含 UNKNOWN）；
   - **Manual Smoke Checks**（`[x]`/`[ ]`/`[-]` 状态）；
   - **Missing Test Evidence**：无则 "All Logic and Integration stories have test coverage."；**`quick` 时写 "Not checked (quick run)."——绝不是上面那行**，quick 没展示过它；
   - **Platform-Specific Results**（仅 `--platform`，含每平台 verdict）；
   - **Verdict**。
R19. **裁决首匹配**：
   - **FAIL**——任一：套件跑了且有失败；套件未完成（timeout、编译/解析/build 错误、运行后无 results 文件）；WAIVED 路径 build check 失败（非零 exit、超时、Godot `SCRIPT ERROR` 或无主场景行）；任何 Batch 1 检查 FAIL；任何 Batch 2 检查 FAIL。
   - **NOT ASSESSED**——任一：套件**未确认的 NOT RUN**（无人报告结果）；runner 不能跑（gdUnit4 103/104、gdUnit4 或 Unity Test Framework 未装）或跑了但零测试（`No test cases found`、`testcasecount="0"`、`No automation tests matched`）；PlayMode 测试存在且 `PlayMode: NOT RUN` 未确认；Batch 1/2 检查**不能执行**（无 build、引擎未配置、平台不可用）——区别于执行了且失败，含 Batch 1 答复本会话未启动 build；**任何 story 覆盖行 UNKNOWN**（没人能读的 story 不是无缺口的 story——没有这条，全是 UNKNOWN 且套件通过的运行会匹配 PASS，因为 PASS 只要求"无 MISSING"）；**Batch 3 被提供但被跳过**（"Performance not checked this session"——不是 FAIL、不是执行失败、也不是 "PASS or N/A"，没有这条它不匹配任何规则，渲染成 PASS 旁的 `[-]`）。
   - **PASS WITH WARNINGS**——全部满足：自动化 PASS / PASS WITH WARNINGS / WAIVED / NOT RUN **且开发者已从本地 IDE 或 CI 确认结果**；全部 Batch 1/2 PASS；至少一个 warning（MISSING 测试证据、通过套件上的 runner warning（gdUnit4 101 orphan 泄漏）、或开发者已确认的 NOT RUN 套件）。
   - **PASS**——全部满足：自动化 PASS 或 WAIVED（build check + 启动与关键路径批次承载裁决）；全部批次 PASS 或 N/A；无 MISSING 证据条目。（Phase 5）
R20. `quick` 运行的任何裁决带标签 `PASS (quick — coverage and Batch 3 not checked)`——quick 可以过，**绝不读作完整运行**。（Phase 5）
R21. **NOT ASSESSED 排序：高于 PASS 与 PASS WITH WARNINGS，低于 FAIL**——没跑的套件没证明 build 健康；跑了且失败的套件是更可行动的发现，不得被降级到没跑的后面。**绝不把 NOT RUN 当自动 FAIL**（NOT ASSESSED 不是 FAIL，排在 FAIL 下）；但未跑套件在等待可能永不到来的确认时绝不解析为 pass。**已确认的 NOT RUN**（开发者从自己 IDE 或 CI 报告结果）仍落 PASS WITH WARNINGS——因为有人看过了。（Phase 5）

### Phase 6 — 写入与门禁（references/6-write-gate.md）
R22. 会话展示完整报告后询问写入 `production/qa/smoke-[date].md`，**批准后才写**。（Phase 6）
R23. **先应用 `qa.level`**：`minimal` 时 FAIL 无论 `testing.strict.config` 一律 **advisory**（跳过门禁解析，交付 advisory-FAIL 话术——冒烟在 minimal 可选且从不阻塞交接）。否则解析门禁级别，从技能顶部已解析配置块读（合并 `project.local.yaml` 覆盖 `project.yaml`——读该块不读文件，否则开发者本地覆盖被静默忽略）：① `testing.strict.config` 为 `true`（大小写不敏感）→ blocking，`false` → advisory，`unset` → 落到 ②；② `testing.strict` 纯布尔（legacy 单值形式）`true`/`false` 适用；③ 否则默认 **blocking**——smoke-check 是 build 健康门禁，未设时默认严格。仅 `true`/`false`（大小写不敏感）被识别；存在但是其它值（`maybe`、`1`、`yes`）按 unset 处理继续下一步，并向用户呈现未识别的值。（Phase 6）
R24. 按裁决交付：**FAIL + blocking** → 不解决不交接 QA，修复后重跑再门禁；**FAIL + advisory**（`testing.strict.config: false`）→ 不阻塞交接但发布前解决，附 QA 交接指引（把 `production/qa/qa-plan-[sprint].md` 分享给 qa-tester agent 开始手工验证）；**NOT ASSESSED** → 逐项点名不能执行的检查与原因、每项给一个可行动修复（如 "confirm the suite result from your IDE or CI"、"run `/setup-engine`"、"produce a build"）——**本结果不受 `testing.strict.config` 管辖**：该设置决定*失败*是否阻塞，对从未产出结果的检查无话可说；把未跑读成 advisory-所以-没事正是该裁决要防的替换——说清什么查不了，让用户决定，禁止代替用户解析成 pass 或 FAIL；**PASS WITH WARNINGS** → build 可交手工 QA，advisory 项在受影响 story 跑 `/story-done` 前解决；**PASS** → 干净通过，附 QA 交接指引。（Phase 6）

### 协作协议（collaborative 模式）
R25. 绝不把 NOT RUN 当自动 FAIL——记录之，让开发者在 Phase 4 手工确认；未确认的 NOT RUN 产出 NOT ASSESSED，不是 FAIL 也不是 pass。绝不自动修失败——报告并说明必须解决什么，禁止改源代码或测试文件。PASS WITH WARNINGS 不阻塞 QA 交接——记 advisory gap 留给 `/story-done` 跟进。`quick` 用于修完特定失败后的快速复查。所有手工核对用 `AskUserQuestion`。绝不未经询问写报告——Phase 6 需明确批准。

## 4. 门禁与裁决
- **裁决词**：`PASS` / `PASS WITH WARNINGS` / `NOT ASSESSED` / `FAIL`（自动化行另有 `NOT RUN`、`WAIVED`；覆盖行 `COVERED`/`MANUAL`/`MISSING`/`EXPECTED`/`UNKNOWN`）。
- **排序（首匹配）**：FAIL > NOT ASSESSED > PASS WITH WARNINGS > PASS；已确认 NOT RUN → PASS WITH WARNINGS；`quick` 裁决恒带 "not checked" 标签。
- **门禁执行**：FAIL 由 `testing.strict.config` → `testing.strict` → 默认 **blocking** 三级解析；`qa.level: minimal` 恒 advisory；NOT ASSESSED 不受门禁设置管辖。
- **消费方**：`/gate-check`（验证 smoke 报告主张）、`/story-done`（MISSING 证据须先解决）、QA 交接（qa-tester agent 手工验证）。

## 5. 移植建议
- **可直接移植**：R2（数真实测试文件而非目录存在）、R3（零测试时给 NOT ASSESSED 而非裸停）、R5（超时即 FAILURE + macOS 替代）、R7（先删旧 results 文件——防上次 pass 被读成这次）、R10（NOT RUN≠FAIL≠pass 的三态）、R14（报告点名清单来源）、R15（"本会话启动过 build 吗"作为 Batch 1 第一问）、R19 的 UNKNOWN 与 Batch 3-skipped 两条 NOT ASSESSED 触发、R21（NOT ASSESSED 排序哲学）、R23（三级门禁解析 + 未识别值当 unset）。
- **需替换概念**：引擎三分支（Godot/Unity/Unreal exit code 表）→ 换成你的测试框架/CI 的退出码与"看起来像成功的假成功"清单（零测试 exit 0 是通用陷阱）；平台批次 → 目标环境维度（浏览器/移动 OS/区域）；qa-tester agent → 手工验证角色；`/story-done` → 任务完结流程。
- **改写示例**：
  - R7 → "运行测试前先删除上一次的结果文件：编译失败不产出新结果，旧文件留在原地会把上次的通过读成本次的通过——未知时龄的结果被当作通过，比没有门禁更糟。"
  - R21 → "门禁裁决排序为 FAIL > NOT ASSESSED > 各级通过：未运行的检查排在失败之下（已知缺陷比未知更可行动）、一切通过之上（未验证不等于验证通过）。等待人工确认的未运行检查绝不解析为通过。"

## 6. 关联文档
- 上游：`/qa-plan`（Smoke Test Scope 与 Test Summary 来源）、`/test-setup`（测试脚手架与 `tests/smoke/critical-paths.md` 种子）、`/setup-engine`（`commands.test` 等命令的写出方）。
- 下游：`/story-done`（MISSING 证据阻塞关闭）、`/gate-check`（阶段门验证 smoke 报告）、QA 交接（qa-tester agent）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/directory-structure.md`、`.claude/docs/coding-standards.md`、`docs/engine-reference/`。
