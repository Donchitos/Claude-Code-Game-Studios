# /smoke-check — Phase 5: Generate Report

# /smoke-check — 第 5 阶段：生成报告

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 5: Generate Report

## 第 5 阶段：生成报告

**In this file:**

**本文件内容：**

- The report template, with the verdict rules
- `NOT ASSESSED` and where it ranks

- 报告模板，以及结论规则
- `NOT ASSESSED` 及其排序位置

Assemble the full smoke check report:

组装完整的冒烟检查报告：

````markdown
## Smoke Check Report
**Date**: [date]
**Sprint**: [sprint name / number, or "Not identified"]
**Engine**: [engine]
**QA Plan**: [path, or "Not found — run /qa-plan first"]
**Argument**: [sprint | quick | blank]

---

### Automated Tests

**Status**: [PASS ([N] tests, [N] passing) | PASS WITH WARNINGS ([N] tests
passing; [the runner's warning, e.g. [N] orphan nodes leaked]) | FAIL ([N]
failures, or did not complete: [timeout | compile, parse or build error | no
results file]) | NOT ASSESSED ([reason, e.g. zero tests executed, runner could
not run]) | NOT RUN ([reason]) | WAIVED (qa.level: minimal — no game tests)]

[Unity: one Status line per test platform — `EditMode:` and `PlayMode:`.]

[WAIVED only:] **Build check**: [PASS — `[command]` exit 0 | FAIL — [reason] |
NOT RUN — [commands.smoke and commands.build unset | executable not found]]

[If FAIL, list failing tests:]
- `[test name]` — [brief failure description from runner output]

[If NOT RUN:]
"Manual confirmation required: did tests pass in your local IDE or CI? This
will determine whether the automated test row contributes to a FAIL verdict."

---

### Test Coverage

| Story | Type | Test File | Coverage Status |
|-------|------|-----------|----------------|
| [title] | Logic | `tests/unit/[system]/[slug]_test.[ext]` | COVERED |
| [title] | Visual/Feel | `production/qa/evidence/[slug]-screenshots.md` | MANUAL |
| [title] | Logic | — | MISSING ⚠ |
| [title] | Config/Data | — | EXPECTED |

**Summary**: [N] covered, [N] manual, [N] missing, [N] expected.

[If `quick`:] "Coverage: not checked (quick run) — run `/smoke-check sprint`
before hand-off." in place of the table and summary.

---

### Manual Smoke Checks

- [x] Build launched this session — yes [or: `NOT RUN — build not launched this session`; the batches below were not asked]
- [x] Game launches without crash — PASS
- [x] New game starts — PASS
- [x] [Core mechanic] — PASS
- [ ] [Other check] — FAIL: [user's description]
- [x] Save / load — PASS
- [-] Performance — not checked this session

---

### Missing Test Evidence

Stories that must have test evidence before they can be marked COMPLETE via
`/story-done`:

- **[story title]** (`[path]`) — Logic story has no test file.
  Expected location: `tests/unit/[system]/[story-slug]_test.[ext]`

[If none:] "All Logic and Integration stories have test coverage."
[If `quick`:] "Not checked (quick run)." — never the line above, which a quick
run has not shown.

---

### Platform-Specific Results *(only if `--platform` was provided)*

| Platform | Checks Run | Passed | Failed | Platform Verdict |
|----------|-----------|--------|--------|-----------------|
| PC | [N] | [N] | [N] | PASS / FAIL |
| Console | [N] | [N] | [N] | PASS / FAIL |
| Mobile | [N] | [N] | [N] | PASS / FAIL |

**Platform notes**: [any platform-specific observations not captured in pass/fail]

Any platform with one or more FAIL checks contributes to the overall FAIL verdict.

---

### Verdict: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[Verdict rules — first matching rule wins:]

**FAIL** if ANY of:
- Automated test suite ran and reported one or more test failures
- The automated suite did not complete: a timeout, a compile, parse or build
  error, or no results file after the run (Phase 2 names each engine's form)
- The build check (WAIVED path) failed: a non-zero exit, a timeout, or a Godot
  `SCRIPT ERROR` or no-main-scene line
- Any Batch 1 (core stability) check returned FAIL
- Any Batch 2 (primary sprint mechanic or regression check) returned FAIL

**NOT ASSESSED** if ANY of:
- The automated suite is **unconfirmed NOT RUN** — nobody has reported a result
- The runner could not run (gdUnit4 103 or 104, gdUnit4 or the Unity Test
  Framework not installed), or it ran and executed zero tests
  (`No test cases found`, `testcasecount="0"`, `No automation tests matched`)
- Unity Play Mode tests exist and are `PlayMode: NOT RUN`, unconfirmed — the
  Edit Mode result does not cover them
- A Batch 1 or Batch 2 check could not be executed (no build, engine not
  configured, platform unavailable) as opposed to executing and failing —
  including a Batch 1 answer that the build was not launched this session
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suite passes matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 3 was offered and skipped** ("Performance not checked this session").
  It is not a FAIL, not an execution failure, and not "PASS or N/A", so without
  this line it matches no rule at all and renders as `[-]` beside a PASS

**PASS WITH WARNINGS** if ALL of:
- Automated tests PASS or PASS WITH WARNINGS, WAIVED at `qa.level: minimal`, or
  NOT RUN **and the developer has confirmed the result from their local IDE or CI**
- All Batch 1 and Batch 2 smoke checks PASS
- At least one warning: a Logic/Integration story with MISSING test evidence,
  a runner warning on a passing suite (gdUnit4 101 — orphan nodes leaked), or
  a NOT RUN suite the developer confirmed

**PASS** if ALL of:
- Automated tests PASS, or WAIVED (`qa.level: minimal` and no game tests exist —
  the build check, when `commands.smoke` or `commands.build` is set, and the
  launch and critical-path batches below then carry the verdict)
- All smoke checks in all batches PASS or N/A
- No MISSING test evidence entries

[On a `quick` run, any verdict carries the label: `PASS (quick — coverage and
Batch 3 not checked)`. A quick run can pass; it never reads as a full one.]
````

````markdown
## 冒烟检查报告
**日期**：[date]
**冲刺**：[冲刺名称 / 编号，或 "Not identified"]
**引擎**：[engine]
**QA 计划**：[路径，或 "Not found — run /qa-plan first"]
**参数**：[sprint | quick | blank]

---

### 自动化测试

**状态**：[PASS（[N] 个测试，[N] 个通过）| PASS WITH WARNINGS（[N] 个测试
通过；[运行器的警告，例如泄漏了 [N] 个孤儿节点]）| FAIL（[N]
个失败，或未完成：[timeout | 编译、解析或构建错误 | 无
结果文件]）| NOT ASSESSED（[原因，例如执行了零个测试、运行器
无法运行]）| NOT RUN（[原因]）| WAIVED（qa.level: minimal —— 无游戏测试）]

[Unity：每个测试平台一行状态 —— `EditMode:` 和 `PlayMode:`。]

[仅 WAIVED 时：] **构建检查**：[PASS —— `[command]` 退出码 0 | FAIL —— [原因] |
NOT RUN —— [commands.smoke 和 commands.build 均未设置 | 找不到可执行文件]]

[若为 FAIL，列出失败的测试：]
- `[test name]` —— [来自运行器输出的简要失败描述]

[若为 NOT RUN：]
"Manual confirmation required: did tests pass in your local IDE or CI? This
will determine whether the automated test row contributes to a FAIL verdict."

---

### 测试覆盖

| 故事 | 类型 | 测试文件 | 覆盖状态 |
|-------|------|-----------|----------------|
| [title] | Logic | `tests/unit/[system]/[slug]_test.[ext]` | COVERED |
| [title] | Visual/Feel | `production/qa/evidence/[slug]-screenshots.md` | MANUAL |
| [title] | Logic | — | MISSING ⚠ |
| [title] | Config/Data | — | EXPECTED |

**汇总**：[N] 已覆盖，[N] 人工，[N] 缺失，[N] 预期。

[若为 `quick`：] 用 "Coverage: not checked (quick run) — run `/smoke-check sprint`
before hand-off." 替代表格和汇总。

---

### 人工冒烟检查

- [x] 本次会话已启动构建 —— 是 [或：`NOT RUN — build not launched this session`；下方批次未被询问]
- [x] 游戏启动不崩溃 —— PASS
- [x] 新游戏可以开始 —— PASS
- [x] [核心机制] —— PASS
- [ ] [其他检查] —— FAIL：[用户的描述]
- [x] 存档 / 读档 —— PASS
- [-] 性能 —— 本次会话未检查

---

### 缺失的测试证据

在能够通过 `/story-done` 标记为 COMPLETE 之前必须有测试证据的故事：

- **[story title]**（`[path]`）—— Logic 故事没有测试文件。
  预期位置：`tests/unit/[system]/[story-slug]_test.[ext]`

[若没有：] "All Logic and Integration stories have test coverage."
[若为 `quick`：] "Not checked (quick run)." —— 绝不能用上一行，因为快速
运行并未展示该结果。

---

### 平台特定结果 *(仅当提供了 `--platform` 时)*

| 平台 | 运行的检查数 | 通过 | 失败 | 平台结论 |
|----------|-----------|--------|--------|-----------------|
| PC | [N] | [N] | [N] | PASS / FAIL |
| Console | [N] | [N] | [N] | PASS / FAIL |
| Mobile | [N] | [N] | [N] | PASS / FAIL |

**平台备注**：[未在通过/失败中体现的任何平台特定观察]

任何有一个或多个 FAIL 检查的平台都会促成总体 FAIL 结论。

---

### 结论：[PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[结论规则 —— 首个匹配的规则生效：]

**FAIL**，如果满足以下任一条件：
- 自动化测试套件已运行，并报告了一个或多个测试失败
- 自动化套件未完成：超时、编译、解析或构建
  错误，或运行后没有结果文件（Phase 2 说明了各引擎的具体形式）
- 构建检查（WAIVED 路径）失败：非零退出码、超时，或 Godot
  的 `SCRIPT ERROR` 或无主场景行
- 任何 Batch 1（核心稳定性）检查返回 FAIL
- 任何 Batch 2（冲刺主要机制或回归检查）返回 FAIL

**NOT ASSESSED**，如果满足以下任一条件：
- 自动化套件**未被确认地处于 NOT RUN 状态** —— 没有任何人报告结果
- 运行器无法运行（gdUnit4 103 或 104，gdUnit4 或 Unity Test
  Framework 未安装），或它运行了但执行了零个测试
  （`No test cases found`、`testcasecount="0"`、`No automation tests matched`）
- 存在 Unity Play Mode 测试且为 `PlayMode: NOT RUN` 且未确认 ——
  Edit Mode 的结果并不覆盖它们
- Batch 1 或 Batch 2 的检查无法执行（没有构建、引擎未
  配置、平台不可用），而不是执行后失败 ——
  包括 Batch 1 的回答是本次会话未启动构建
- **任何故事的覆盖行是 `UNKNOWN`**（Phase 3：故事文件缺失或
  无法读取）。一个没人能读取的故事并不是没有缺口的故事 —— 如果没有
  这一行，*每一*行都是 UNKNOWN 且套件通过的运行会匹配
  **PASS**，因为 PASS 只要求“没有 MISSING 条目”
- **Batch 3 被提供但被跳过**（"Performance not checked this session"）。
  它既不是 FAIL，也不是执行失败，也不是“PASS 或 N/A”，因此如果没有
  这一行，它根本不匹配任何规则，并会在 PASS 旁边渲染为 `[-]`

**PASS WITH WARNINGS**，如果满足以下全部条件：
- 自动化测试为 PASS 或 PASS WITH WARNINGS、在 `qa.level: minimal` 下为 WAIVED，或
  为 NOT RUN **且开发者已从其本地 IDE 或 CI 确认了结果**
- 所有 Batch 1 和 Batch 2 冒烟检查均 PASS
- 至少有一条警告：某个 Logic/Integration 故事存在 MISSING 测试证据、
  通过的套件上有运行器警告（gdUnit4 101 —— 泄漏了孤儿节点），或
  开发者已确认的 NOT RUN 套件

**PASS**，如果满足以下全部条件：
- 自动化测试为 PASS，或为 WAIVED（`qa.level: minimal` 且不存在游戏测试 ——
  此时若设置了 `commands.smoke` 或 `commands.build`，则由构建检查
  以及下方的启动和关键路径批次来承载结论）
- 所有批次中的所有冒烟检查均 PASS 或 N/A
- 没有 MISSING 测试证据条目

[在 `quick` 运行中，任何结论都会带上标签：`PASS (quick — coverage and
Batch 3 not checked)`。快速运行可以判为通过；但它永远不会被读成一次完整运行。]
````

**`NOT ASSESSED` — the build nobody could check.** Rank: it **outranks PASS and
PASS WITH WARNINGS** and **ranks below FAIL**. A suite that never ran has not
shown the build is healthy; a suite that ran and failed is the more actionable
finding and must not be demoted behind one that did not run.

**`NOT ASSESSED` —— 无人能够检查的构建。** 排序：它**高于 PASS 和
PASS WITH WARNINGS**，且**低于 FAIL**。从未运行的套件并未
表明构建是健康的；运行过并失败的套件是更具可操作性的发现，
绝不能把它降级到某个未运行套件之后。

The rule below — **never treat NOT RUN as an automatic FAIL** — still holds:
NOT ASSESSED is not a FAIL, and it ranks below one. But an unrun suite never
resolves to a *pass* verdict while waiting for a confirmation that may never
come. Confirmed NOT RUN (the developer reports the
result from their own IDE or CI) still lands at PASS WITH WARNINGS, because
somebody did look.

下面的规则 —— **绝不要把 NOT RUN 当作自动 FAIL** —— 仍然成立：
NOT ASSESSED 不是 FAIL，其排序在 FAIL 之下。但一个未运行的套件在等待
可能永远不会到来的确认时，绝不会变成*通过*结论。已确认的 NOT RUN
（开发者从自己的 IDE 或 CI 报告结果）仍然落在 PASS WITH WARNINGS，因为
确实有人查看过了。

---
