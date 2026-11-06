---
name: regression-suite
description: "Map test coverage to GDD critical paths, find fixed bugs lacking regression tests, flag drift from new features."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: regression-suite
description: "将测试覆盖映射到 GDD 关键路径，找出缺少回归测试的已修复缺陷，标记新功能带来的覆盖漂移。"
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

以上已解析 — 直接使用。无配置块 → 使用
`.claude/docs/config-resolution.md` 中的默认值。


# Regression Suite

# 回归套件

This skill ensures that every bug fix is backed by a test that would have
caught the original bug — and that the regression suite stays current as the
game evolves. It also detects when new features have been added without
corresponding regression coverage.

本技能确保每个缺陷修复都有能捕获原始缺陷的测试作为支撑 — 并确保回归套件随游戏演进保持最新。它也会检测新功能被加入却没有相应回归覆盖的情况。

A regression suite is not a new test category — it is a **curated list of
tests already in `tests/`** that collectively cover the game's critical paths
and known failure points. This skill maintains that list.

回归套件不是新的测试类别 — 它是**一份经过筛选的、已存在于 `tests/` 中的测试清单**，这些测试共同覆盖游戏的关键路径与已知故障点。本技能维护该清单。

**Output:** `tests/regression-suite.md`

**输出：** `tests/regression-suite.md`

**When to run:**
- After fixing a bug (confirm a regression test was written or identify gap)
- Before a phase gate — at `qa.level: full`, `/gate-check` requires a regression suite
- As part of sprint close to detect coverage drift

**何时运行：**
- 修复缺陷之后（确认已编写回归测试，或识别缺口）
- 阶段门禁之前 — 在 `qa.level: full` 时，`/gate-check` 需要回归套件
- 作为冲刺收尾的一部分，用以检测覆盖漂移

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅就重要事项询问 · 自主模式记录并继续；
`automation_always_ask` 类别始终询问）。

**Workflow tier**: `modes.workflow` as resolved above — supplied by `modes.rigor`
unless set explicitly — per `.claude/docs/workflow-modes.md`; in `audit` mode consider
`workflow_overrides.system_overrides.<system>` per system as each GDD is read. It
sets whether GDD critical paths are mapped or coverage is smoke-only — see Step 2c.

**工作流层级**：如上解析的 `modes.workflow` — 除非显式设置，否则由 `modes.rigor`
提供 — 参见 `.claude/docs/workflow-modes.md`；在 `audit` 模式下，读取每个 GDD 时
按系统考虑 `workflow_overrides.system_overrides.<system>`。它决定是映射 GDD 关键路径，
还是只做冒烟覆盖 — 见步骤 2c。

**`qa.level`**: controls whether the suite is generated at
all. At `minimal`, the regression suite is **not generated** (report that and
stop); at `standard`, generate it at Polish-stage entry; at `full`, at
Production-stage entry. Distinct axis from `workflow`.

**`qa.level`**：控制是否生成套件。在 `minimal` 时不**生成**回归套件（报告并停止）；
在 `standard` 时于打磨阶段入口生成；在 `full` 时于生产阶段入口生成。与 `workflow` 是不同维度。

## 1. Parse Arguments

## 1. 解析参数

**Early `qa.level` guard (resolved above):** if `qa.level: minimal`, the
regression suite is **not generated** — report "Regression suite not generated at
qa.level minimal" and **STOP here, before any scan**, in every mode
(`update` / `audit` / `report`). This is the `qa.level` axis; it is distinct from
the `workflow`-tier `minimal` branch in Step 2c (which only changes the
critical-path *source*, not *whether* the suite runs). Do not enter Step 2c's
`minimal` branch on account of `qa.level`. This stop's verdict is
**NOT ASSESSED** (Section 7) — tests are not required at this level, and nothing
was scanned.

**前置 `qa.level` 守卫（如上解析）：** 若 `qa.level: minimal`，则**不生成**回归套件 — 报告
“Regression suite not generated at qa.level minimal”，并在所有模式（`update` / `audit` / `report`）
下**在此停止，先于任何扫描**。这是 `qa.level` 维度；它不同于步骤 2c 中 `workflow` 层级的 `minimal`
分支（该分支只改变关键路径的*来源*，不改变套件*是否*运行）。不要因 `qa.level` 而进入步骤 2c 的
`minimal` 分支。此停止的判定为 **NOT ASSESSED**（第 7 节）— 该层级不要求测试，且未扫描任何内容。

**Modes:**
- `/regression-suite update` — scan new bug fixes this sprint and check
  for regression test presence; add new tests to the suite manifest
- `/regression-suite audit` — full audit of all GDD critical paths vs.
  existing test coverage; flag paths with no regression test
- `/regression-suite report` — read-only status report (no writes); suitable
  for sprint reviews
- No argument — if a sprint is clearly active (sprint plan exists with in-progress stories), run `update`. If ambiguous or no active sprint is detected, use `AskUserQuestion`:
  - Prompt: "No subcommand specified. Which mode do you want to run?"
  - Options:
    - `[A] update — scan new bug fixes this sprint and add missing regression tests`
    - `[B] audit — full audit of all GDD critical paths vs. existing test coverage`
    - `[C] report — read-only status report (no writes)`

**模式：**
- `/regression-suite update` — 扫描本冲刺新的缺陷修复，检查回归测试是否存在；将新测试加入套件清单
- `/regression-suite audit` — 对所有 GDD 关键路径与既有测试覆盖做完整审计；标记没有回归测试的路径
- `/regression-suite report` — 只读状态报告（不写入）；适合冲刺评审
- 无参数 — 若明显有活跃冲刺（存在冲刺计划且有进行中的故事），运行 `update`。若情况不明或未检测到活跃冲刺，使用 `AskUserQuestion`：
  - 提示：“未指定子命令。你要运行哪种模式？”
  - 选项：
    - `[A] update — 扫描本冲刺新的缺陷修复并补充缺失的回归测试`
    - `[B] audit — 对所有 GDD 关键路径与既有测试覆盖做完整审计`
    - `[C] report — 只读状态报告（不写入）`

---

## 2. Load Context

## 2. 加载上下文

### Step 2a — Load existing regression suite

### 步骤 2a — 加载现有回归套件

Read `tests/regression-suite.md` if it exists. Extract:
- Total registered regression tests
- Last updated date
- Any tests flagged as `STALE` or `QUARANTINED`

若存在 `tests/regression-suite.md` 则读取。提取：
- 已注册回归测试总数
- 最后更新日期
- 任何被标记为 `STALE` 或 `QUARANTINED` 的测试

If it does not exist: note "No regression suite found — will create one."

若不存在：注明“未找到回归套件 — 将创建一个。”

### Step 2b — Load test inventory

### 步骤 2b — 加载测试清单

Glob all test files:
```
tests/unit/**/*_test.*
tests/integration/**/*_test.*
tests/regression/**/*
```

Glob 所有测试文件：
```
tests/unit/**/*_test.*
tests/integration/**/*_test.*
tests/regression/**/*
```

For each file, note the system (from directory path) and file name.
Do not read test file contents unless needed for name-to-test mapping.

对每个文件，记录系统（来自目录路径）与文件名。
除非为名称到测试的映射所需，不要读取测试文件内容。

### Step 2c — Load GDD critical paths

### 步骤 2c — 加载 GDD 关键路径

For `audit` mode: read `design/gdd/systems-index.md` to get all systems, then
scope the scan by each system's workflow tier (resolved above):
- **`full`** — read the GDD and map critical paths from all sections.
- **`standard`** — same, from the required sections (Acceptance Criteria, Edge
  Cases, and Formulas where the system defines numeric rules).
  A system pinned higher via `system_overrides` is mapped at its higher tier.
- **`minimal`** — **skip the GDD critical-path scan**. Instead read the latest
  smoke-check report in `production/qa/smoke-*.md` and take the critical paths it
  exercises as the regression scope (Step 3 maps coverage against those, not GDD
  acceptance criteria). If no smoke report exists, stop with Verdict: **NOT
  ASSESSED — no smoke report to take critical paths from** — there is no
  critical-path source at minimal without one; run `/smoke-check` first.

对 `audit` 模式：读取 `design/gdd/systems-index.md` 获取所有系统，然后按每个系统的工作流层级（如上解析）限定扫描范围：
- **`full`** — 读取 GDD，从所有小节映射关键路径。
- **`standard`** — 同上，但从必需小节（验收标准、边界情形，以及系统定义数值规则时的公式）。
  通过 `system_overrides` 固定为更高层级的系统，按其更高层级映射。
- **`minimal`** — **跳过 GDD 关键路径扫描**。改为读取 `production/qa/smoke-*.md` 中最新的冒烟检查报告，
  以其中涵盖的关键路径作为回归范围（步骤 3 映射覆盖时对照这些，而非 GDD 验收标准）。若不存在冒烟报告，
  以判定停止：**NOT ASSESSED — no smoke report to take critical paths from** — 在 minimal 下没有报告就没有关键路径来源；
  请先运行 `/smoke-check`。

(Tier affects `audit` mode only; `update` and `report` modes are tier-independent.)

（层级仅影响 `audit` 模式；`update` 与 `report` 模式与层级无关。）

Read each GDD by section: find the headings you need with the Grep tool (pattern
`^#`, content mode) and Read those ranges with offset and limit. At `full` that
is every section, read in ranges, since a whole-file Read over 40 KB is refused.

按小节读取每个 GDD：用 Grep 工具（pattern `^#`，content 模式）找到需要的标题，再用 offset 与 limit
读取对应区间。在 `full` 下即所有小节，按区间读取，因为超过 40 KB 的整文件 Read 会被拒绝。

For each in-scope MVP-tier system's GDD, extract:
- Acceptance Criteria (these define the critical paths)
- Formulas section (formulas must have regression tests)
- Edge Cases section (known edge cases should have regression tests)

对每个在范围内的 MVP 层级系统的 GDD，提取：
- 验收标准（这些定义了关键路径）
- 公式小节（公式必须有回归测试）
- 边界情形小节（已知边界情形应有回归测试）

For `update` mode: skip full GDD scan. Instead read the current sprint plan
and story files to find stories with Status: Complete this sprint.

对 `update` 模式：跳过完整 GDD 扫描。改为读取当前冲刺计划与故事文件，找出本冲刺 Status:
Complete 的故事。

### Step 2d — Load closed bugs

### 步骤 2d — 加载已关闭缺陷

Glob `production/qa/bugs/*.md` and filter for bugs with a `Status: Closed`
or `Status: Fixed` field. Note:
- Which story or system the bug was in
- Whether a regression test was mentioned in the fix description

Glob `production/qa/bugs/*.md`，筛选具有 `Status: Closed` 或 `Status: Fixed` 字段的缺陷。记录：
- 缺陷所属的故事或系统
- 修复描述中是否提到回归测试

---

## 3. Map Coverage — Critical Paths

## 3. 映射覆盖 — 关键路径

For `audit` mode only. (At `minimal` the critical paths come from the smoke-check
report identified in Step 2c, not from GDD acceptance criteria — map coverage
against those smoke paths and skip the GDD-criterion loop below.)

仅用于 `audit` 模式。（在 `minimal` 下，关键路径来自步骤 2c 中识别的冒烟检查报告，而非 GDD
验收标准 — 对照这些冒烟路径映射覆盖，并跳过下面的 GDD 标准循环。）

For each GDD acceptance criterion, determine whether a test exists:

对每条 GDD 验收标准，判断是否存在测试：

1. Grep `tests/unit/[system]/` and `tests/integration/[system]/` for file names
   and function names related to the criterion's key noun/verb
2. Assign coverage:

1. 在 `tests/unit/[system]/` 与 `tests/integration/[system]/` 中 Grep 与该标准关键名词/动词
   相关的文件名与函数名
2. 分配覆盖状态：

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file exists that targets this criterion's logic |
| **PARTIAL** | A test exists but doesn't cover all cases (e.g. happy path only) |
| **MISSING** | No test found for this critical path |
| **EXEMPT** | Visual/Feel or UI criterion — not automatable by design |

| 状态 | 含义 |
|--------|---------|
| **COVERED** | 存在针对该标准逻辑的测试文件 |
| **PARTIAL** | 存在测试，但未覆盖所有情形（例如仅正常路径） |
| **MISSING** | 未找到该关键路径的测试 |
| **EXEMPT** | 视觉/手感或 UI 标准 — 按设计不可自动化 |

3. Elevate MISSING items that correspond to formulas or state machines to
   **HIGH PRIORITY** gap — these are the most likely regression sources.

3. 将对应公式或状态机的 MISSING 项升级为 **HIGH PRIORITY** 缺口 — 这些是最可能的回归来源。

---

## 4. Map Coverage — Fixed Bugs

## 4. 映射覆盖 — 已修复缺陷

For each closed bug:

对每个已关闭缺陷：

1. Extract the system slug from the bug's metadata
2. Grep `tests/unit/[system]/` and `tests/integration/[system]/` for a test
   that references the bug ID or the specific failure scenario
3. Assign:
   - **HAS REGRESSION TEST** — a test was found that would catch this bug
   - **MISSING REGRESSION TEST** — bug was fixed but no test guards against recurrence

1. 从缺陷元数据提取系统 slug
2. 在 `tests/unit/[system]/` 与 `tests/integration/[system]/` 中 Grep 引用缺陷 ID 或特定
   故障场景的测试
3. 分配：
   - **HAS REGRESSION TEST** — 找到可捕获该缺陷的测试
   - **MISSING REGRESSION TEST** — 缺陷已修复，但没有测试防止其复发

For MISSING REGRESSION TEST items:
- Flag them as regression gaps
- Suggest the test file path: `tests/unit/[system]/[bug-slug]_regression_test.[ext]`
- Note: "Without this test, this bug can silently return in a future sprint."

对 MISSING REGRESSION TEST 项：
- 将其标记为回归缺口
- 建议测试文件路径：`tests/unit/[system]/[bug-slug]_regression_test.[ext]`
- 注明：“没有此测试，该缺陷可能在未来的冲刺中悄无声息地复现。”

---

## 5. Detect Coverage Drift

## 5. 检测覆盖漂移

Coverage drift occurs when the game grows but the regression suite doesn't.

当游戏在增长而回归套件未跟上时，便发生覆盖漂移。

Check for drift indicators:
- Stories completed this sprint with no corresponding test files in `tests/`
- New systems added to `systems-index.md` since the last regression-suite update
- GDD sections added or revised since the regression suite was last updated
  (use Grep on GDD file modification hints if available, or ask the user)
- `tests/regression-suite.md` last-updated date vs. current date — if gap >
  2 sprints, flag as likely stale

检查漂移指标：
- 本冲刺完成的故事在 `tests/` 中却没有对应测试文件
- 自上次回归套件更新以来 `systems-index.md` 新增的系统
- 自回归套件上次更新以来新增或修订的 GDD 小节
  （若有 GDD 文件修改线索则用 Grep，否则询问用户）
- `tests/regression-suite.md` 的最后更新日期与当前日期 — 若间隔超过
  2 个冲刺，标记为可能已过期

---

## 6. Generate Report and Suite Manifest

## 6. 生成报告与套件清单

### Report format (in conversation)

### 报告格式（在对话中）

```
## Regression Suite Status

**Mode**: [update | audit | report]
**Existing registered tests**: [N]
**Test files scanned**: [N]

### Critical Path Coverage (audit mode only)
| System | Total ACs | Covered | Partial | Missing | Exempt |
|--------|-----------|---------|---------|---------|--------|
| [name] | [N] | [N] | [N] | [N] | [N] |

**Coverage rate (non-exempt)**: [N]%

### Bug Regression Coverage
| Bug ID | System | Severity | Has Regression Test? |
|--------|--------|----------|----------------------|
| BUG-NNNN | [system] | S[N] | YES / NO ⚠ |

**Bugs without regression tests**: [N]

### Coverage Drift Indicators
[List new systems or stories with no test coverage, or "None detected."]

### Recommended New Regression Tests
| Priority | System | Suggested Test File | Covers |
|----------|--------|---------------------|--------|
| HIGH | [system] | `tests/unit/[system]/[slug]_regression_test.[ext]` | BUG-NNNN / AC-[N] |
| MEDIUM | [system] | `tests/unit/[system]/[slug]_test.[ext]` | [criterion] |
```

### Suite manifest format (`tests/regression-suite.md`)

### 套件清单格式（`tests/regression-suite.md`）

> **Before computing coverage, check the denominator.** If the GDD
> glob returns **zero critical paths**, or the test globs return **zero test
> files**, do not emit a percentage — report
> `Coverage: NOT ASSESSED — [no GDDs found | no test files found]` and name which
> side was empty and the skill that produces it (`/map-systems` and
> `/design-system` for GDDs, `/test-setup` for the test scaffold).
>
> A percentage computed from an empty denominator is not a low score; it is not a
> number. `0%` reads as "measured and terrible" and `100%` as "measured and
> perfect" — both are claims about a comparison that never happened. This is the
> same defect `/scope-check` carries a Phase 4 guard against, in the same words:
> *"a percentage computed from no baseline items is not a small number; it is not
> a number."*

> **计算覆盖率之前，先检查分母。** 若 GDD
> glob 返回**零条关键路径**，或测试 glob 返回**零个测试
> 文件**，不要输出百分比 — 报告
> `Coverage: NOT ASSESSED — [no GDDs found | no test files found]`，并说明哪
> 一侧为空，以及由哪个技能产生它（GDD 由 `/map-systems` 与
> `/design-system` 产生，测试脚手架由 `/test-setup` 产生）。
>
> 用空分母计算出的百分比不是低分；它根本不是一个
> 数字。`0%` 读起来像“测过，很糟”，`100%` 像“测过，
> 完美” — 两者都是对一场从未发生的比较的断言。这
> 与 `/scope-check` 在阶段 4 守卫所针对的缺陷相同，措辞也一样：
> *“用零基线项计算出的百分比不是一个小数字；它根本
> 不是一个数字。”*

The manifest is a curated index — not the tests themselves, but a registry
of which tests should always pass before a release:

清单是一份经过筛选的索引 — 不是测试本身，而是登记哪些测试应在发布前始终通过的注册表：

```markdown
# Regression Suite Manifest

> Last Updated: [date]
> Total registered tests: [N]
> Coverage: [N]% of GDD critical paths

## How to run

[Engine-specific command to run all regression tests]

## Registered Regression Tests

### [System Name]

| Test File | Test Function (if known) | Covers | Added |
|-----------|--------------------------|--------|-------|
| `tests/unit/[system]/[file]_test.[ext]` | `test_[scenario]` | AC-N / BUG-NNNN | [date] |

## Known Gaps

Tests that should exist but don't yet:

| Priority | System | Suggested Path | Covers | Reason Not Yet Written |
|----------|--------|----------------|--------|------------------------|
| HIGH | [system] | `tests/unit/[system]/[path]` | BUG-NNNN | Bug fixed without test |

## Quarantined Tests

Tests that are flaky or disabled (do not run in CI):

| Test File | Function | Reason | Quarantined Since |
|-----------|----------|--------|-------------------|
| (none) | | | |
```

---

## 7. Write Output

## 7. 写入输出

In `update` or `audit` mode, ask: "May I write/update `tests/regression-suite.md` with the current
regression suite manifest?"

在 `update` 或 `audit` 模式下，询问：“我可以将当前回归套件清单写入/更新到 `tests/regression-suite.md` 吗？”

For `update` mode: append new entries; never remove existing entries
(use `Edit` with targeted insertions).
For `audit` mode: rewrite the full manifest with updated coverage data.
For `report` mode: do not write anything.

对 `update` 模式：追加新条目；绝不删除既有条目
（使用 `Edit` 做定点插入）。
对 `audit` 模式：用更新后的覆盖数据重写完整清单。
对 `report` 模式：不写入任何内容。

After writing (if approved):

写入之后（若已批准）：

- For each HIGH priority gap: "Consider creating the missing regression test
  before the next sprint. Run `/test-helpers` to scaffold the test file."
- If bug regression gaps > 0: "These bugs can silently return without regression
  tests. The next sprint should include a story to write the missing tests."
- If coverage drift detected: "Regression suite may be drifting. Consider
  running `/regression-suite audit` at the next sprint boundary."

- 对每个 HIGH 优先级缺口：“考虑在下一冲刺前创建缺失的回归测试。运行 `/test-helpers` 搭建测试文件脚手架。”
- 若缺陷回归缺口 > 0：“这些缺陷在没有回归测试的情况下可能悄无声息地复现。下一冲刺应包含一个故事来编写缺失的测试。”
- 若检测到覆盖漂移：“回归套件可能正在漂移。考虑在下一冲刺边界运行 `/regression-suite audit`。”

At `workflow: minimal`, which has no sprints, say "next story" for "next sprint" in the three lines above.

在 `workflow: minimal` 下没有冲刺，上面三行中的“下一冲刺”改为“下一个故事”。

Verdict, first match wins:
- **NOT ASSESSED** — the Section 1 stop at `qa.level: minimal`: "Regression
  suite not generated at qa.level minimal". Tests are not required at this
  level; nothing was scanned or written.
- **NOT ASSESSED** — the `minimal` stop above: no smoke report to take critical
  paths from; name `/smoke-check` as the fix.
- **NOT ASSESSED** — coverage came back `Coverage: NOT ASSESSED — [reason]` (no GDDs or
  no test files); name the reason. Never report COMPLETE over a coverage figure
  that was not computed.
- **BLOCKED** — `update` or `audit` mode and the user declined the write.
- **COMPLETE** — `update` / `audit`: regression suite updated; `report`: coverage
  report shown (report mode writes nothing).

判定，首个匹配者胜出：
- **NOT ASSESSED** — 第 1 节在 `qa.level: minimal` 的停止：“Regression
  suite not generated at qa.level minimal”。该层级不要求测试；未扫描或写入任何内容。
- **NOT ASSESSED** — 上述 `minimal` 停止：没有冒烟报告可从中获取关键
  路径；将 `/smoke-check` 指为修复方式。
- **NOT ASSESSED** — 覆盖结果返回 `Coverage: NOT ASSESSED — [reason]`（无 GDD 或
  无测试文件）；说明原因。绝不可在一个未计算的覆盖率数字上报告 COMPLETE。
- **BLOCKED** — 处于 `update` 或 `audit` 模式且用户拒绝写入。
- **COMPLETE** — `update` / `audit`：回归套件已更新；`report`：已展示覆盖
  报告（report 模式不写入任何内容）。

---

## Collaborative Protocol

## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

**适用于 `collaborative` 模式（默认）。** 关于 `guided` 与
`autonomous` 模式，见 `.claude/docs/automation-modes.md` — 以下规则
描述的是协作模式的要求，而非普遍行为。

- **Never remove existing regression tests from the manifest** without
  explicit user approval — removing a test that was deliberately written is a
  regression risk itself
- **Gaps are advisory, not blocking** — surface them clearly but do not prevent
  other work from proceeding (except at `qa.level: full`, where phase gates require the regression suite)
- **Quarantine is not deletion** — tests with intermittent failures should be
  quarantined (noted in manifest) but not removed; they should be fixed by
  `/test-flakiness`
- **Ask before writing** — always confirm before creating or updating the manifest

- **绝不在未获用户明确批准的情况下从清单中移除既有回归测试** — 移除一个有意编写的测试
  本身就是一项回归风险
- **缺口是提示性的，不构成阻塞** — 清楚呈现它们，但不阻止其他工作继续
  （除 `qa.level: full` 下阶段门禁要求回归套件的情况）
- **隔离不是删除** — 间歇性失败的测试应被隔离（在清单中注明）而非移除；它们应由
  `/test-flakiness` 修复
- **写入前先询问** — 创建或更新清单之前始终确认
