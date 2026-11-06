---
name: test-flakiness
description: "Find flaky tests from CI logs — aggregates pass rates, spots intermittent failures, recommends quarantine. After multiple runs."
argument-hint: "[ci-log-path | scan | registry]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(ls -t *), Bash(bash "*/.claude/skills/test-flakiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: test-flakiness
description: "从 CI 日志中找出不稳定测试 — 汇总通过率、识别间歇性失败、建议隔离。在多次运行之后使用。"
argument-hint: "[ci-log-path | scan | registry]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(ls -t *), Bash(bash "*/.claude/skills/test-flakiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重要事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终询问）。

# Test Flakiness Detection

# 测试不稳定性检测

A flaky test is one that sometimes passes and sometimes fails without any code
change. Flaky tests are worse than no tests in some ways — they train the team
to ignore red CI runs, masking genuine failures. This skill identifies them,
explains likely causes, and recommends whether to quarantine or fix each one.

不稳定测试是指在不改动任何代码的情况下有时通过、有时失败的测试。不稳定测试在某些方面比没有测试更糟 —
它们让团队习惯于忽略红色的 CI 运行，从而掩盖真正的失败。本技能识别它们，解释可能原因，
并建议对每一个是隔离还是修复。

**Output:** Updated `tests/regression-suite.md` quarantine section + optional
`production/qa/flakiness-report-[date].md`

**输出：** 更新后的 `tests/regression-suite.md` 隔离小节 + 可选的
`production/qa/flakiness-report-[date].md`

**When to run:**
- Polish phase (tests have had many runs; statistical signal is reliable)
- When developers start dismissing CI failures as "probably flaky"
- After `/regression-suite` identifies quarantined tests that need diagnosis

**何时运行：**
- 打磨阶段（测试已运行多次；统计信号可靠）
- 当开发者开始把 CI 失败当作“可能不稳定”而打发时
- 在 `/regression-suite` 识别出需要诊断的隔离测试之后

---

## 1. Parse Arguments

## 1. 解析参数

**Modes:**
- `/test-flakiness [ci-log-path]` — analyse a specific CI run log file
- `/test-flakiness scan` — scan all available CI logs in `.github/` or
  standard log output directories
- `/test-flakiness registry` — read existing regression-suite.md quarantine
  section and provide remediation guidance for already-known flaky tests
- No argument — auto-detect: run `scan` if CI logs are accessible, else
  `registry`

**模式：**
- `/test-flakiness [ci-log-path]` — 分析特定的 CI 运行日志文件
- `/test-flakiness scan` — 扫描 `.github/` 或标准日志输出目录中所有可用的 CI 日志
- `/test-flakiness registry` — 读取既有 regression-suite.md 的隔离小节，
  为已知的不稳定测试提供修复指引
- 无参数 — 自动检测：若 CI 日志可访问则运行 `scan`，否则运行 `registry`

---

## 2. Locate CI Log Data

## 2. 定位 CI 日志数据

### Option A — GitHub Actions (preferred)

### 方案 A — GitHub Actions（首选）

Check for test result artifacts:
```bash
ls -t .github/ 2>/dev/null
ls -t test-results/ 2>/dev/null
```

检查测试结果产物：
```bash
ls -t .github/ 2>/dev/null
ls -t test-results/ 2>/dev/null
```

For Godot projects: GdUnit4 outputs XML results compatible with JUnit format,
under `reports/` (its default report folder, `res://reports/`). Check `reports/`,
and any `test-results/` you saved runs into, for `.xml` files.

对 Godot 项目：GdUnit4 在 `reports/`（其默认报告文件夹，`res://reports/`）下输出兼容 JUnit
格式的 XML 结果。在 `reports/` 以及你保存运行的任何 `test-results/` 中检查 `.xml` 文件。

For Unity projects: game-ci test runner outputs NUnit XML to `test-results/`
by default.

对 Unity 项目：game-ci 测试运行器默认将 NUnit XML 输出到 `test-results/`。

For Unreal projects: automation logs go to `Saved/Logs/`. Grep for
`Result={Success}` and `Result={Fail}` — each test prints
`Test Completed. Result={<status>}`
(`docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

对 Unreal 项目：自动化日志写入 `Saved/Logs/`。Grep `Result={Success}` 与
`Result={Fail}` — 每个测试打印
`Test Completed. Result={<status>}`
（`docs/engine-reference/unreal/current-best-practices.md`，“Command Line”）。

### Option B — Local log files

### 方案 B — 本地日志文件

If a path argument is provided, read that file directly.

若提供了路径参数，直接读取该文件。

### Option C — No log data available

### 方案 C — 无可用日志数据

If no logs found:
> "No CI log data found. To detect flaky tests, this skill needs test result
> history from multiple runs. Options:
> 1. Run the test suite at least 3 times and collect the output logs
> 2. Check CI pipeline output and save a log to `test-results/`
> 3. Run `/test-flakiness registry` to review tests already flagged as flaky
>    in `tests/regression-suite.md`"

若未找到日志：
> “未找到 CI 日志数据。要检测不稳定测试，本技能需要多次运行的测试结果
> 历史。选项：
> 1. 至少运行 3 次测试套件并收集输出日志
> 2. 检查 CI 流水线输出并保存日志到 `test-results/`
> 3. 运行 `/test-flakiness registry`，审阅 `tests/regression-suite.md`
>    中已标记为不稳定的测试”

Stop and ask the user which option to pursue.

停止并询问用户选择哪一方案。

---

## 3. Parse Test Results

## 3. 解析测试结果

For each CI log or result file found, parse:

对找到的每个 CI 日志或结果文件，解析：

**JUnit XML format** (GdUnit4):
- Grep for `<testcase name=` to get test names
- Grep for `<failure` or `<error` to identify failures
- Parse `classname` and `name` attributes for full test identifiers

**JUnit XML 格式**（GdUnit4）：
- Grep `<testcase name=` 获取测试名称
- Grep `<failure` 或 `<error` 以识别失败
- 解析 `classname` 与 `name` 属性以获得完整测试标识符

**NUnit XML format** (Unity — the file whose `<test-run>` element `/smoke-check`
reads):
- Each test is a `<test-case` element; its `fullname` attribute is the identifier
- Its `result` attribute is `Passed`, `Failed`, `Inconclusive` or `Skipped`
  (`docs/engine-reference/unity/current-best-practices.md`, "Command Line");
  only `Passed` and `Failed` enter the history

**NUnit XML 格式**（Unity — `/smoke-check` 读取其 `<test-run>` 元素的文件）：
- 每个测试是一个 `<test-case` 元素；其 `fullname` 属性是标识符
- 其 `result` 属性为 `Passed`、`Failed`、`Inconclusive` 或 `Skipped`
  （`docs/engine-reference/unity/current-best-practices.md`，“Command Line”）；
  只有 `Passed` 与 `Failed` 进入历史

**Plain text logs**:
- Grep for pass/fail patterns:
  - Godot: `PASSED` / `FAILED` adjacent to test names
  - Unreal: `Result={Success}` / `Result={Fail}`
  - Unity: `Test passed` / `Test failed`

**纯文本日志**：
- Grep 通过/失败模式：
  - Godot：测试名旁边的 `PASSED` / `FAILED`
  - Unreal：`Result={Success}` / `Result={Fail}`
  - Unity：`Test passed` / `Test failed`

Build a table: `test_id → [run1_result, run2_result, run3_result, ...]`

构建一张表：`test_id → [run1_result, run2_result, run3_result, ...]`

---

## 4. Identify Flaky Tests

## 4. 识别不稳定测试

A test is **flaky** if it appears in the result history with both PASS and
FAIL outcomes across runs with no code changes between them.

若某测试在结果历史中，在彼此之间无代码变更的多次运行里同时出现 PASS 与 FAIL 结果，则它是**不稳定的**。

Flakiness thresholds:
- **High flakiness**: Fails in >25% of runs — quarantine immediately
- **Moderate flakiness**: Fails in 5–25% of runs — investigate and fix soon
- **Low/suspected flakiness**: Fails in 1–5% of runs — monitor; may be
  genuinely rare failure

不稳定性阈值：
- **高不稳定性**：在超过 25% 的运行中失败 — 立即隔离
- **中等不稳定性**：在 5–25% 的运行中失败 — 尽快调查并修复
- **低/疑似不稳定性**：在 1–5% 的运行中失败 — 观察；可能是真正的罕见失败

**With fewer than 3 runs, every finding is *suspected*, whatever its fail rate.**
One failure in two runs reads as 50%, but it is one data point: do not
quarantine it, label it suspected, and ask whether more run data is available.
The tiers above, and quarantine, apply from 3 runs up.

**运行少于 3 次时，每个发现都是*疑似*，无论其失败率如何。**
两次运行中一次失败读起来是 50%，但那只是一个数据点：不要隔离它，将其标为疑似，
并询问是否有更多运行数据。上述层级与隔离，从 3 次运行起适用。

For each flaky test, classify the likely cause:

对每个不稳定测试，归类可能原因：

### Cause classification

### 原因分类

| Cause | Symptoms | Fix direction |
|-------|----------|---------------|
| **Timing / async** | Fails after awaiting signals or timers; pass rate correlates with system load | Add explicit await/synchronisation; avoid time-based delays |
| **Order dependency** | Fails when run after specific other tests; passes in isolation | Add proper setup/teardown; ensure test isolation |
| **Random seed** | Fails intermittently with no pattern; involves RNG | Pass explicit seed; don't use `randf()` in tests |
| **Resource leak** | Fails more often later in a test run | Fix cleanup in teardown; check orphan nodes (Godot) or object disposal (Unity) |
| **External state** | Fails when a file, scene, or global exists from a prior test | Isolate test from file system; use in-memory mocks |
| **Floating point** | Fails on comparisons like `== 0.5` | Use epsilon comparison (`is_equal_approx`, `Assert.AreApproximately`) |
| **Scene/prefab load race** | Fails when scenes are not yet ready | Await one frame after instantiation; use `await get_tree().process_frame` |

| 原因 | 症状 | 修复方向 |
|-------|----------|---------------|
| **时序 / 异步** | 在等待信号或计时器后失败；通过率与系统负载相关 | 添加显式 await/同步；避免基于时间的延迟 |
| **顺序依赖** | 在特定其他测试之后运行时失败；单独运行则通过 | 添加恰当的 setup/teardown；确保测试隔离 |
| **随机种子** | 无规律间歇性失败；涉及 RNG | 传入显式种子；测试中不要用 `randf()` |
| **资源泄漏** | 在测试运行后段更频繁失败 | 修复 teardown 中的清理；检查孤儿节点（Godot）或对象释放（Unity） |
| **外部状态** | 当先前测试遗留的文件、场景或全局对象存在时失败 | 将测试与文件系统隔离；使用内存中的 mock |
| **浮点** | 在 `== 0.5` 之类的比较上失败 | 使用 epsilon 比较（`is_equal_approx`、`Assert.AreApproximately`） |
| **场景/预制体加载竞争** | 场景尚未就绪时失败 | 实例化后等待一帧；使用 `await get_tree().process_frame` |

Use Grep to check the test file for timing calls, randf, global state access,
or equality comparisons on floats to narrow down the cause.

用 Grep 检查测试文件中的时序调用、randf、全局状态访问或浮点相等比较，以缩小原因范围。

---

## 5. Recommend Action

## 5. 建议行动

For each flaky test:

对每个不稳定测试：

**Quarantine (High flakiness):**
> "Quarantine this test immediately. Skip it with the engine's own mechanism,
> log it in the `tests/regression-suite.md` quarantine section, and fix the root
> cause before removing quarantine."

**隔离（高不稳定性）：**
> “立即隔离此测试。用引擎自带的机制跳过它，
> 将其记录到 `tests/regression-suite.md` 的隔离小节，并在解除隔离前
> 修复根因。”

Skip mechanisms, by engine — name only the one for the project's engine:
- **Godot (gdUnit4), GDScript**: a skip parameter on the test function —
  `func test_x(_do_skip := true, _skip_reason := "flaky: [cause]")`. gdUnit4 reads
  the argument names `do_skip` and `skip_reason` (a leading `_` is allowed) in
  `addons/gdUnit4/src/core/GdUnitTestSuiteScanner.gd`, as of gdUnit4 6.2.2;
  confirm them there for the installed version.
- **Godot (gdUnit4), C#**: **NOT SOURCEABLE** — gdUnit4's C# test attributes are
  not in the `addons/gdUnit4/` source, and `docs/engine-reference/godot/` does not
  cover them. Log it in the quarantine section and ask the user how their C#
  tests are skipped; do not invent an attribute.
- **Unity (NUnit)**: `[Ignore("flaky: [cause]")]` — NUnit 3 requires the reason
- **Unreal**: **NOT SOURCEABLE** — `docs/engine-reference/unreal/` documents no way
  to skip an automation test. Log it in the quarantine section and ask the user
  how their CI excludes a test; do not invent a flag.

跳过机制，按引擎 — 只写出项目所用引擎的那一项：
- **Godot（gdUnit4），GDScript**：在测试函数上加跳过参数 —
  `func test_x(_do_skip := true, _skip_reason := "flaky: [cause]")`。gdUnit4 在
  `addons/gdUnit4/src/core/GdUnitTestSuiteScanner.gd` 中读取参数名 `do_skip` 与 `skip_reason`
  （允许前置 `_`），截至 gdUnit4 6.2.2；请针对已安装版本在该处确认。
- **Godot（gdUnit4），C#**：**无法溯源** — gdUnit4 的 C# 测试特性不在 `addons/gdUnit4/`
  源码中，且 `docs/engine-reference/godot/` 未涵盖它们。将其记录到隔离小节，并询问用户的 C#
  测试如何跳过；不要凭空发明特性。
- **Unity（NUnit）**：`[Ignore("flaky: [cause]")]` — NUnit 3 要求给出理由
- **Unreal**：**无法溯源** — `docs/engine-reference/unreal/` 未记录跳过自动化测试的方法。
  将其记录到隔离小节，并询问用户的 CI 如何排除测试；不要凭空发明标志。

**Investigate and fix soon (Moderate):**
> "This test is intermittently unreliable. Root cause appears to be [cause].
> Suggested fix: [specific fix based on cause classification]. Do not quarantine
> yet — fix the test directly."

**尽快调查并修复（中等）：**
> “此测试间歇性不可靠。根因似乎是 [cause]。
> 建议修复：[基于原因分类的具体修复]。暂不要隔离 —
> 直接修复该测试。”

**Monitor (Low/suspected):**
> "This test shows suspected flakiness. Collect more run data before
> quarantining. Note it as 'suspected' in the regression suite."

**观察（低/疑似）：**
> “此测试显示出疑似不稳定性。在隔离前收集更多运行数据。
> 在回归套件中将其记为‘suspected’。”

---

## 6. Generate Reports

## 6. 生成报告

### In-conversation summary

### 对话内摘要

```
## Flakiness Detection Results

**Runs analysed**: [N]
**Tests tracked**: [N]

### Flaky Tests Found

| Test | System | Fail Rate | Confidence | Likely Cause | Recommendation |
|------|--------|-----------|------------|--------------|----------------|
| [test_name] | [system] | [N]% | confirmed | Timing | Quarantine + fix async |
| [test_name] | [system] | [N]% | confirmed | Float comparison | Fix: use epsilon compare |
| [test_name] | [system] | [N]% | suspected (fewer than 3 runs) | Order dependency | Collect more runs before acting |

### Clean Tests (no flakiness detected)

[N] tests ran across [N] runs with consistent results — no flakiness detected.

### Data Limitations

[Note if fewer than 5 runs were available — fewer runs = less statistical confidence]
```

---

## 7. Update Regression Suite + Optional Report File

## 7. 更新回归套件 + 可选报告文件

Ask: "May I update the quarantine section of `tests/regression-suite.md`
with the flaky tests found?"

询问：“我可以把发现的不稳定测试更新到 `tests/regression-suite.md`
的隔离小节吗？”

If yes: use `Edit` to append entries to the Quarantined Tests table.
Never remove existing quarantine entries — only add new ones.

若同意：用 `Edit` 向 Quarantined Tests 表追加条目。
绝不删除既有隔离条目 — 只新增。

Ask (separately): "May I write a full flakiness report to
`production/qa/flakiness-report-[date].md`?"

（另行）询问：“我可以将完整的不稳定性报告写入
`production/qa/flakiness-report-[date].md` 吗？”

The full report includes per-test analysis with cause details and
engine-specific fix snippets.

完整报告包含逐测试分析，附带原因细节与引擎特定的修复片段。

After writing:

写入之后：

- For each quarantined test: "Add the engine-specific skip annotation to
  disable this test in CI. Re-enable after the root cause is fixed."
- For fix-eligible tests: "The fix for [test] is straightforward —
  change the equality comparison on line [N] to use `is_equal_approx`."
- Summary: "Once all quarantine annotations are applied, CI should run green.
  Schedule fix work for the [N] quarantined tests before the release gate."

- 对每个被隔离的测试：“添加引擎特定的跳过注解以在 CI 中禁用该测试。根因修复后重新启用。”
- 对可修复的测试：“针对 [test] 的修复很直接 — 将第 [N] 行的相等比较改为 `is_equal_approx`。”
- 摘要：“一旦应用所有隔离注解，CI 应能跑绿。在发布门禁之前为 [N] 个被隔离的测试安排修复工作。”

---

## Collaborative Protocol

## 协作协议

- **Never delete test files** — quarantine means annotate + list, not remove
- **Statistical confidence matters** — with < 3 runs, flag findings as
  "suspected" not "confirmed"; ask if more run data is available
- **Fix is always the goal** — quarantine is temporary; surface the fix
  direction even when recommending quarantine
- **Ask before writing** — both the regression-suite update and the report
  file require explicit approval. On write: Verdict: **COMPLETE** — flakiness report written. On decline: Verdict: **BLOCKED** — user declined write.
- **Flakiness in CI is a team problem** — surface the list and recommended
  actions clearly; do not just silently quarantine without the team knowing

- **绝不删除测试文件** — 隔离意味着注解 + 列出，而非移除
- **统计置信度很重要** — 运行少于 3 次时，将发现标为“suspected”而非“confirmed”；
  询问是否有更多运行数据
- **修复始终是目标** — 隔离是临时的；即使建议隔离，也要指出修复方向
- **写入前先询问** — 回归套件更新与报告文件都需要明确批准。写入时：判定：**COMPLETE** — 不稳定性报告已写入。被拒绝时：判定：**BLOCKED** — 用户拒绝写入。
- **CI 中的不稳定性是团队问题** — 清楚呈现清单与建议行动；不要在团队不知情时悄悄隔离
