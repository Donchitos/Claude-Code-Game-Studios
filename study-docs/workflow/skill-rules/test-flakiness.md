# test-flakiness — 非确定性测试检测（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/test-flakiness/SKILL.md) ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/test-flakiness [ci-log-path | scan | registry]`
- **一句话职责**：从 CI 日志聚合多次运行的通过率，识别非确定性（flaky）测试——无代码变更时有时过有时失败——解释可能原因并建议隔离（quarantine）或修复。
- **触发前置**：`resolve_config --keys automation` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`；**多次运行之后**才跑——运行时：Polish 阶段（测试跑过很多次，统计信号可靠）；开发者开始把 CI 失败当 "probably flaky" 挥手而过时；`/regression-suite` 识别出待诊断的 quarantined 测试之后。
- **问题定义**：flaky 测试某些方面比没有测试更糟——它训练团队忽略红色 CI，掩盖真实失败。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | CI 测试结果：GitHub Actions artifacts（`ls -t .github/`、`test-results/`）；Godot — GdUnit4 的 JUnit 兼容 XML 在 `reports/`（默认 `res://reports/`）及保存过的 `test-results/`；Unity — game-ci 输出 NUnit XML 到 `test-results/`；Unreal — automation 日志在 `Saved/Logs/`（grep `Result={Success}` / `Result={Fail}`，每测试打 `Test Completed. Result={<status>}`）；或路径参数指定的本地日志文件 | 多次运行的历史结果是 flakiness 判断的唯一数据源 |
| 产出 | 更新 `tests/regression-suite.md` 的 Quarantined Tests 节（只追加）；可选 `production/qa/flakiness-report-[date].md` | 隔离登记 + 完整分析报告 |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

### 1 — 解析参数
R1. 模式：`[ci-log-path]` — 分析特定 CI 运行日志文件；`scan` — 扫描 `.github/` 或标准日志输出目录的全部 CI 日志；`registry` — 读既有 `regression-suite.md` quarantine 节，为已知 flaky 测试给整改指引；无参数自动检测——CI 日志可访问则 `scan`，否则 `registry`。（§1）

### 2 — 定位 CI 日志数据
R2. 找不到任何日志数据 → 停止并询问用户三选一：① 把测试套件至少跑 3 次并收集输出日志；② 查 CI 管道输出并存一份日志到 `test-results/`；③ 跑 `/test-flakiness registry` 查看已在 `tests/regression-suite.md` 里标记为 flaky 的测试。（§2）

### 3 — 解析测试结果
R3. 按格式解析：**JUnit XML**（GdUnit4）——grep `<testcase name=` 取测试名、`<failure`/`<error` 识别失败、解析 `classname` 与 `name` 组成完整标识符；**NUnit XML**（Unity——即 `/smoke-check` 读的 `<test-run>` 文件）——每测试是一个 `<test-case` 元素，`fullname` 属性是标识符，`result` 属性为 `Passed`/`Failed`/`Inconclusive`/`Skipped`，**只有 `Passed` 和 `Failed` 进入历史**；**纯文本日志**——Godot `PASSED`/`FAILED` 邻近测试名、Unreal `Result={Success}`/`Result={Fail}`、Unity `Test passed`/`Test failed`。构建表：`test_id → [run1_result, run2_result, run3_result, ...]`。（§3）

### 4 — 识别 flaky 测试
R4. **定义**：测试在结果历史中同时出现 PASS 与 FAIL，且两次运行之间无代码变更。（§4）
R5. **flakiness 阈值**：**High** — 失败率 > 25% → 立即 quarantine；**Moderate** — 5–25% → 调查并尽快修复；**Low/suspected** — 1–5% → 监控，可能是真实的罕见失败。（§4）
R6. **运行数下限**：**少于 3 次运行时，任何发现都是 *suspected*，无论失败率多少**。两次运行中失败一次读作 50%，但那只是一个数据点：不隔离，标 suspected，并询问是否有更多运行数据。上面的梯队与 quarantine 从 3 次起才适用。（§4）
R7. 逐 flaky 测试做**原因分类**并给修复方向：
   | 原因 | 症状 | 修复方向 |
   |------|------|---------|
   | Timing/async | await 信号或计时器后失败；通过率随系统负载变化 | 加显式 await/同步；避免基于时间的延迟 |
   | Order dependency | 跑在特定其它测试之后失败；单独跑通过 | 加正确的 setup/teardown；确保测试隔离 |
   | Random seed | 无模式间歇失败；涉及 RNG | 传显式 seed；测试中不用 `randf()` |
   | Resource leak | 越到运行后期越常失败 | 修 teardown 清理；查 orphan nodes（Godot）或对象处置（Unity） |
   | External state | 先前测试留下的文件/场景/全局量存在时失败 | 把测试与文件系统隔离；用内存 mock |
   | Floating point | `== 0.5` 这类比较失败 | 用 epsilon 比较（`is_equal_approx`、`Assert.AreApproximately`） |
   | Scene/prefab load race | 场景尚未就绪时失败 | 实例化后 await 一帧；`await get_tree().process_frame` |
   用 Grep 查测试文件中的 timing 调用、`randf`、全局状态访问或浮点相等比较来收窄原因。（§4）

### 5 — 建议行动
R8. **Quarantine（High）**："立即隔离。用引擎自有机制跳过、记入 `tests/regression-suite.md` 的 quarantine 节、修好根因后再移除隔离。" 跳过机制按引擎（**只命名项目引擎的那一个**）：Godot (gdUnit4) GDScript — 测试函数上的 skip 参数 `func test_x(_do_skip := true, _skip_reason := "flaky: [cause]")`（gdUnit4 在 `addons/gdUnit4/src/core/GdUnitTestSuiteScanner.gd` 读参数名 `do_skip` 与 `skip_reason`，前导 `_` 允许，6.2.2 起如此；为安装的版本确认）；Godot (gdUnit4) C# — **NOT SOURCEABLE**（C# 测试属性不在 `addons/gdUnit4/` 源中，`docs/engine-reference/godot/` 不覆盖）——记入 quarantine 节并询问用户其 C# 测试如何跳过，**禁止发明属性**；Unity (NUnit) — `[Ignore("flaky: [cause]")]`（NUnit 3 要求给理由）；Unreal — **NOT SOURCEABLE**（`docs/engine-reference/unreal/` 未文档化跳过 automation 测试的方法）——记入 quarantine 节并询问用户其 CI 如何排除测试，**禁止发明 flag**。（§5）
R9. **Investigate and fix soon（Moderate）**："此测试间歇不可靠。根因似乎是 [cause]。建议修复：[基于原因分类的具体修复]。**先不要隔离——直接修测试**。" **Monitor（Low/suspected）**："此测试显示疑似 flakiness。先收集更多运行数据再隔离。在回归套件中标注为 'suspected'。"（§5）

### 6 — 生成报告
R10. 会话内摘要：Runs analysed / Tests tracked，加三节：（§6）
   - **Flaky Tests Found** 表：Test / System / Fail Rate / Confidence（`confirmed` 或 `suspected (fewer than 3 runs)`）/ Likely Cause / Recommendation，如 "Quarantine + fix async"、"Fix: use epsilon compare"、"Collect more runs before acting"；
   - **Clean Tests**：N 个测试跨 N 次运行结果一致——未检出 flakiness；
   - **Data Limitations**：可用运行少于 5 次时注记——运行越少统计置信越低。

### 7 — 更新回归套件 + 可选报告文件
R11. 询问 "May I update the quarantine section of `tests/regression-suite.md` with the flaky tests found?"——批准则用 `Edit` 向 Quarantined Tests 表**追加**条目；**绝不移除既有 quarantine 条目，只加新的**。另**单独**询问 "May I write a full flakiness report to `production/qa/flakiness-report-[date].md`?"（完整报告含逐测试分析与引擎特定修复片段）。（§7）
R12. 写入后：每个 quarantined 测试 → "加上引擎特定的 skip 注解在 CI 中禁用此测试；根因修复后重新启用"；可修测试 → 给具体修复（如 "把第 [N] 行的相等比较改成 `is_equal_approx`"）；摘要 → "全部 quarantine 注解应用后 CI 应转绿。release gate 前为 [N] 个 quarantined 测试安排修复工作。"。（§7）

### 协作协议
R13. 协作底线：
   - **绝不删除测试文件**——quarantine 意为 注解 + 列出，不是移除；
   - **统计置信重要**——< 3 次运行把发现标 "suspected" 不标 "confirmed"；询问是否有更多运行数据；
   - **修复永远是目标**——quarantine 是临时的；即使建议隔离也要浮出修复方向；
   - **写前询问**——回归套件更新与报告文件两处都需明确批准：写 → Verdict **COMPLETE** — flakiness report written；拒 → Verdict **BLOCKED** — user declined write；
   - **CI 里的 flakiness 是团队问题**——清晰浮出清单与建议行动，禁止背着团队静默隔离。

## 4. 门禁与裁决
- **裁决词**：`COMPLETE` — flakiness report written / `BLOCKED` — user declined write。
- **置信分级**：`confirmed`（≥ 3 次运行）vs `suspected`（< 3 次）——quarantine 只对 confirmed 生效。
- **行动分级（首匹配）**：失败率 > 25% → quarantine 立即；5–25% → 修而不隔离；1–5% → 监控。
- **消费方**：`tests/regression-suite.md`（Quarantined Tests 节——`/regression-suite` 维护同一文件）、CI（skip 注解生效处）、release gate（修复排期）。

## 5. 移植建议
- **可直接移植**：R4（flaky 定义 = 无代码变更下的混合结果）、R6（样本量下限——"2 次里 1 次失败读作 50%，但只是一个数据点"）、R7 原因表（timing/顺序依赖/随机种子/资源泄漏/外部状态/浮点/加载竞态——引擎无关）、R8 的 NOT SOURCEABLE 纪律（查不到跳过机制就问用户，禁止发明 API）、R11（隔离登记只追加）、R13（隔离≠删除；修复永远是目标；团队可见）。
- **需替换概念**：JUnit/NUnit XML/纯文本三种格式 → 你的 CI 结果格式（JSON 报告、testng、go test -json）；`tests/regression-suite.md` → 项目的测试登记文档；引擎 skip 机制 → 框架的跳过原语（`@pytest.mark.skip`、`test.skip()`、JUnit `@Disabled`）；`randf()`/orphan nodes → 语言对应的随机源/资源清理陷阱。
- **改写示例**：
  - R6 → "非确定性判定的统计置信随样本数增长：少于 3 次运行的任何发现一律标注 suspected 并询问是否有更多历史数据，禁止据此隔离——两次运行一次失败读作 50% 失败率，但它只是一个数据点。"
  - R8 → "推荐跳过机制时只引用能为当前项目版本溯源的 API；文档未覆盖的机制标 NOT SOURCEABLE 并直接询问团队现有做法，禁止发明注解或参数——一条错误的跳过写法会让测试静默继续跑或编译失败。"

## 6. 关联文档
- 上游：`/regression-suite`（quarantine 节的创建方与同文件维护者）、`/smoke-check`（NUnit `<test-run>` 同源读取）、CI（`/test-setup` 配置的结果产出）。
- 下游：`tests/regression-suite.md` 的 Quarantined Tests 节、`production/qa/bugs/`（修复排期）、release gate。
- 引用：`.claude/docs/automation-modes.md`、`docs/engine-reference/godot/`、`docs/engine-reference/unity/current-best-practices.md`、`docs/engine-reference/unreal/current-best-practices.md`。
