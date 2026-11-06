---
name: tech-debt
description: "Track, categorize and prioritize technical debt across the codebase — scans for debt indicators, maintains a register."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: tech-debt
description: "在整个代码库中跟踪、分类并排序技术债 — 扫描债务指标并维护一份登记表。"
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

# Tech Debt
# 技术债



Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

## Phase 1: Parse Subcommand
## 阶段 1：解析子命令

Determine the mode from the argument:
根据参数确定模式：

- `scan` — Scan the codebase for tech debt indicators
- `add` — Add a new tech debt entry manually
- `prioritize` — Re-prioritize the existing debt register
- `report` — Generate a summary report of current debt status
- `scan` — 扫描代码库中的技术债指标
- `add` — 手动新增一条技术债条目
- `prioritize` — 重新排序现有债务登记表
- `report` — 生成当前债务状态的摘要报告

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.
如果未提供子命令，输出用法并停止。裁决：**FAIL** — 缺少必需子命令。

---

## Phase 2A: Scan Mode
## 阶段 2A：扫描模式

Search the **code root** (resolve per `.claude/docs/code-root-resolution.md`:
`src/`, `Assets/` or `Source/` by engine) for debt indicators:
搜索**代码根目录**（按 `.claude/docs/code-root-resolution.md` 解析：
按引擎为 `src/`、`Assets/` 或 `Source/`）中的债务指标：

- `TODO` comments (count and categorize)
- `FIXME` comments (these are bugs disguised as debt)
- `HACK` comments (workarounds that need proper solutions)
- `@deprecated` markers
- Duplicated code blocks (similar patterns in multiple files)
- Files over 500 lines (potential god objects)
- Functions over 50 lines (potential complexity)
- `TODO` 注释（计数并分类）
- `FIXME` 注释（这些是伪装成债务的缺陷）
- `HACK` 注释（需要正式解决方案的临时变通）
- `@deprecated` 标记
- 重复的代码块（多个文件中的相似模式）
- 超过 500 行的文件（潜在上帝对象）
- 超过 50 行的函数（潜在复杂度过高）

Categorize each finding:
对每项发现进行分类：

- **Architecture Debt**: Wrong abstractions, missing patterns, coupling issues
- **Code Quality Debt**: Duplication, complexity, naming, missing types
- **Test Debt**: Missing tests, flaky tests, untested edge cases
- **Documentation Debt**: Missing docs, outdated docs, undocumented APIs
- **Dependency Debt**: Outdated packages, deprecated APIs, version conflicts
- **Performance Debt**: Known slow paths, unoptimized queries, memory issues
- **架构债**：错误的抽象、缺失的模式、耦合问题
- **代码质量债**：重复、复杂、命名、缺少类型
- **测试债**：缺失测试、不稳定测试、未测试的边界情况
- **文档债**：缺失文档、过时文档、未记录的 API
- **依赖债**：过时的包、已弃用的 API、版本冲突
- **性能债**：已知的慢路径、未优化的查询、内存问题

**Before presenting anything, establish that there was something to scan.**
Count the source files the scan actually covered. If the code root is
unresolved, report `NOT ASSESSED — code root unresolved` and stop as below. If
that count is **zero** — the code root is absent, or holds no source files — report:
**在呈现任何内容之前，先确认确实有东西可供扫描。**
统计扫描实际覆盖的源文件数量。如果代码根目录未解析，报告 `NOT ASSESSED — code root unresolved` 并按下文停止。如果该计数为**零** — 代码根目录不存在，或不含源文件 — 报告：

> **NOT ASSESSED — no source files to scan.** The code root contains no code, so
> "no debt indicators found" would be a statement about an empty search, not
> about the codebase. Run this once implementation is under way.
> **NOT ASSESSED — no source files to scan.** 代码根目录不含任何代码，因此
> "no debt indicators found"将是关于一次空搜索的陈述，而不是关于
> 代码库本身。请在实现工作展开后再运行此项。

and stop. Do not write to the register and do not emit a COMPLETE verdict.
然后停止。不要写入登记表，也不要输出 COMPLETE 裁决。

The distinction is the whole point of the scan: **zero findings over 400 files
is a clean codebase; zero findings over zero files is no information at all.**
Rendering both as "COMPLETE — scan findings written to register" reads as the
first. State the denominator whenever findings are reported,
including when it is large and the count is genuinely zero.
这一区别正是扫描的全部意义：**在 400 个文件中零发现是干净的代码库；在零个文件中零发现则完全不是信息。**
把两者都渲染为 "COMPLETE — scan findings written to register" 会让人读成前者。只要报告发现，就要说明分母，
包括分母很大而计数确实为零的情况。

Present the findings to the user.
向用户呈现发现。

Ask: "May I write these findings to `docs/tech-debt-register.md`?"
询问："我可以把这些发现写入 `docs/tech-debt-register.md` 吗？"

If yes, update the register, never overwriting it. **Match before appending:** a
finding with the same file and the same kind of debt as an existing `Open` entry
updates that entry instead of adding a duplicate. An existing `Open` entry whose
pattern is no longer in its file is proposed as `Resolved [date]` — list those and
include them in the same approval. Verdict: **COMPLETE** — scan findings written to register.
如果是，更新登记表，绝不覆盖它。**追加前先匹配：** 与现有 `Open` 条目具有相同文件和相同债务类型的发现，会更新该条目而不是新增重复项。现有 `Open` 条目若其模式已不在对应文件中，则提议为 `Resolved [date]` — 列出这些条目，并纳入同一次批准。裁决：**COMPLETE** — 扫描发现已写入登记表。

If no, stop here. Verdict: **BLOCKED** — user declined write.
如果否，到此停止。裁决：**BLOCKED** — 用户拒绝写入。

---

## Phase 2B: Add Mode
## 阶段 2B：新增模式

Ask the user for the description and affected files (plain text prompts).
向用户询问描述和受影响的文件（纯文本提示）。

**Run as a subagent?** `lead-programmer` preloads this skill, and a subagent has
no `AskUserQuestion`. Return the three questions below (category, effort,
impact) in one reply, each as a short list of its options, and stop: whoever
called you asks the user. Nothing goes into the register until the answers
come back.
**作为子智能体运行？** `lead-programmer` 会预加载此技能，而子智能体没有
`AskUserQuestion`。在一条回复中返回下面三个问题（类别、工作量、
影响），每个问题附上其选项的简短列表，然后停止：调用你的主体会去询问用户。
在答案返回之前，任何内容都不会写入登记表。

Then use `AskUserQuestion` to collect the **category**:
然后使用 `AskUserQuestion` 收集**类别**：
- Prompt: "What category does this tech debt belong to?"
- Options:
  - `[A] Architecture Debt — wrong abstractions, missing patterns, coupling issues`
  - `[B] Code Quality Debt — duplication, complexity, naming, missing types`
  - `[C] Test Debt — missing tests, flaky tests, untested edge cases`
  - `[D] Documentation Debt — missing/outdated docs, undocumented APIs`
  - `[E] Dependency Debt — outdated packages, deprecated APIs, version conflicts`
  - `[F] Performance Debt — known slow paths, memory issues, unoptimized queries`
- 提示："这条技术债属于哪个类别？"
- 选项：
  - `[A] Architecture Debt — 错误的抽象、缺失的模式、耦合问题`
  - `[B] Code Quality Debt — 重复、复杂、命名、缺少类型`
  - `[C] Test Debt — 缺失测试、不稳定测试、未测试的边界情况`
  - `[D] Documentation Debt — 缺失/过时的文档、未记录的 API`
  - `[E] Dependency Debt — 过时的包、已弃用的 API、版本冲突`
  - `[F] Performance Debt — 已知的慢路径、内存问题、未优化的查询`

Then use `AskUserQuestion` to collect the **estimated fix effort**:
然后使用 `AskUserQuestion` 收集**预计修复工作量**：
- Prompt: "What is the estimated effort to fix this item?"
- Options:
  - `[A] S — Small (under 1 day)`
  - `[B] M — Medium (1–3 days)`
  - `[C] L — Large (3–7 days)`
  - `[D] XL — Extra Large (over 1 week)`
- 提示："修复此项的预计工作量是多少？"
- 选项：
  - `[A] S — 小（1 天以内）`
  - `[B] M — 中（1–3 天）`
  - `[C] L — 大（3–7 天）`
  - `[D] XL — 特大（超过 1 周）`

Then use `AskUserQuestion` to collect the **impact if left unfixed** — the
register's Impact column, which `/tech-debt prioritize` scores:
然后使用 `AskUserQuestion` 收集**若不修复的影响** — 即登记表的 Impact 列，`/tech-debt prioritize` 会为其评分：
- Prompt: "What does this cost if it is never fixed?"
- Options: `[A] Low` / `[B] Med` / `[C] High` / `[D] Critical`
- 提示："如果永远不修复，这会带来什么代价？"
- 选项：`[A] Low` / `[B] Med` / `[C] High` / `[D] Critical`

Present the complete new entry to the user.
向用户呈现完整的新条目。

**Match before appending:** if an existing `Open` entry already has the same
file and the same category, show it to the user and ask whether to update that
entry instead of adding a duplicate.
**追加前先匹配：** 如果现有 `Open` 条目已经具有相同文件和相同类别，向用户展示它，并询问是更新该条目而不是新增重复项。

Ask: "May I append this entry to `docs/tech-debt-register.md`?" (or, on a match,
"May I update the existing entry instead?")
询问："我可以把这条目追加到 `docs/tech-debt-register.md` 吗？"（或者在匹配时，
"我可以改为更新现有条目吗？"）

If yes, append the entry (or update the matched one). Verdict: **COMPLETE** — entry added to register.
如果是，追加该条目（或更新匹配的条目）。裁决：**COMPLETE** — 条目已添加到登记表。

If no, stop here. Verdict: **BLOCKED** — user declined write.
如果否，到此停止。裁决：**BLOCKED** — 用户拒绝写入。

---

## Phase 2C: Prioritize Mode
## 阶段 2C：优先级排序模式

Read the debt register at `docs/tech-debt-register.md`. If it does not exist:
Verdict: **NOT ASSESSED** — no register at `docs/tech-debt-register.md`; run
`/tech-debt scan` first. Stop.
读取 `docs/tech-debt-register.md` 处的债务登记表。如果它不存在：
裁决：**NOT ASSESSED** — `docs/tech-debt-register.md` 处没有登记表；请先运行
`/tech-debt scan`。停止。

Score each item from its own columns: `impact ÷ effort`, with Impact `Low` 1,
`Med` 2, `High` 3, `Critical` 4 and Effort `S` 1, `M` 2, `L` 3, `XL` 4, rounded to
one decimal and written to Priority. Higher scores first; ties go to the older
`Added` date. An item whose Impact or Effort is `—` gets no score: list it after
the scored items as "not scored — [column] not judged" rather than guessing one.
根据每项自身的列为其评分：`impact ÷ effort`，其中 Impact `Low` 1、
`Med` 2、`High` 3、`Critical` 4，Effort `S` 1、`M` 2、`L` 3、`XL` 4，四舍五入
到一位小数并写入 Priority。分数高者在前；分数相同则较早的
`Added` 日期优先。Impact 或 Effort 为 `—` 的条目不计分：将其列在
已计分条目之后，标注 "not scored — [column] not judged"，而不是猜测一个分数。

Re-sort the register by priority score and recommend which items to include in the next sprint (at `workflow: minimal`, which has no sprints, which to build next).
按优先级分数重新排序登记表，并建议将哪些条目纳入下一个冲刺（在 `workflow: minimal` 下没有冲刺，则建议接下来构建哪些）。

Present the re-prioritized register to the user.
向用户呈现重新排序后的登记表。

Ask: "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"
询问："我可以把重新排序后的登记表写回 `docs/tech-debt-register.md` 吗？"

If yes, write the updated file. Verdict: **COMPLETE** — register re-prioritized and saved.
如果是，写入更新后的文件。裁决：**COMPLETE** — 登记表已重新排序并保存。

If no, stop here. Verdict: **BLOCKED** — user declined write.
如果否，到此停止。裁决：**BLOCKED** — 用户拒绝写入。

---

## Phase 2D: Report Mode
## 阶段 2D：报告模式

Read the debt register. If it does not exist: Verdict: **NOT ASSESSED** — no
register to report on; run `/tech-debt scan` first. Stop.
读取债务登记表。如果它不存在：裁决：**NOT ASSESSED** — 没有
可报告的登记表；请先运行 `/tech-debt scan`。停止。

Generate summary statistics:
生成摘要统计：

- Open items by category, and total estimated fix effort for them
- Items added and items resolved during the current sprint, from each entry's
  `Added` date and its `Resolved [date]` status
- Trending direction (growing / stable / shrinking) — added vs resolved in that window
- 按类别统计的 Open 条目，以及它们预计修复工作量的总和
- 当前冲刺期间新增和解决的条目，依据每个条目的
  `Added` 日期及其 `Resolved [date]` 状态
- 趋势方向（增长 / 稳定 / 缩小）— 该窗口内的新增与解决对比

Flag any items that have been in the register for more than 3 sprints.
标记任何在登记表中存在超过 3 个冲刺的条目。

Output the report to the user. This mode is read-only — no files are written. Verdict: **COMPLETE** — debt report generated.
向用户输出报告。此模式为只读 — 不写入任何文件。裁决：**COMPLETE** — 债务报告已生成。

---

## Phase 3: Next Steps
## 阶段 3：后续步骤

- Run `/sprint-plan` to schedule high-priority debt items into the next sprint (at `workflow: minimal`, which has no sprints, add them to the brief's build order instead).
- Run `/tech-debt report` at the start of each sprint to track debt trends over time.
- 运行 `/sprint-plan`，将高优先级债务条目排入下一个冲刺（在 `workflow: minimal` 下没有冲刺，则改为将它们加入简报的构建顺序）。
- 在每个冲刺开始时运行 `/tech-debt report`，以跟踪债务随时间的变化趋势。

### Debt Register Format
### 债务登记表格式

```markdown
## Technical Debt Register
Last updated: [Date]
Total items: [N] | Estimated total effort: [T-shirt sizes summed]

| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
| TD-001 | [Cat] | [Description] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Open / Resolved YYYY-MM-DD / Accepted — reason] | [YYYY-MM-DD] | [Sprint to fix or "Backlog"] |
```

Every skill that adds a row — this one, and `/story-done` when it logs
deviations as debt — writes all ten columns in this order, and a skill that
creates the file writes the header and table head above first:
每个添加行的技能 — 本技能，以及 `/story-done` 在将偏差记录为债务时 — 都按此顺序写入全部十列，而创建文件的技能会先写入上方的标题和表头：

- **ID** — `TD-` and three digits, one above the highest ID already in the
  register (`TD-001` in a new one). IDs are never reused.
- **Category** — one of the six categories under Scan Mode, written without
  "Debt": `Architecture`, `Code Quality`, `Test`, `Documentation`, `Dependency`,
  `Performance` — the spelling `/story-done` writes, so Report Mode groups them once.
- **Description** — what the debt is and why it was taken on.
- **Files** — the affected paths, comma-separated; `—` when the debt has no single file.
- **Effort** — `S`, `M`, `L` or `XL`, as in Add Mode; `—` if not yet estimated.
- **Impact** — `Low`, `Med`, `High` or `Critical`: the cost if left unfixed; `—`
  if not yet judged.
- **Priority** — the score `/tech-debt prioritize` writes; `—` until it runs.
- **Status** — `Open` when added. `Resolved YYYY-MM-DD` records the day the debt
  was fixed; `Accepted — reason` records a conscious decision to keep it.
- **Added** — the day the row was written, `YYYY-MM-DD`. Report Mode counts items
  added and resolved from this date and the `Resolved` date.
- **Sprint** — the sprint scheduled to fix it, or `Backlog`.
- **ID** — `TD-` 加三位数字，比登记表中已有的最高 ID 大一位
  （新表中为 `TD-001`）。ID 永不复用。
- **Category** — 扫描模式下的六个类别之一，写入时不带
  "Debt"：`Architecture`、`Code Quality`、`Test`、`Documentation`、`Dependency`、
  `Performance` — 即 `/story-done` 写入的拼写，因此报告模式只需统一归并一次。
- **Description** — 该债务是什么，以及为何承担它。
- **Files** — 受影响的路径，以逗号分隔；当债务没有单一文件时为 `—`。
- **Effort** — `S`、`M`、`L` 或 `XL`，与新增模式相同；若尚未估算则为 `—`。
- **Impact** — `Low`、`Med`、`High` 或 `Critical`：若不修复的代价；若
  尚未判断则为 `—`。
- **Priority** — `/tech-debt prioritize` 写入的分数；在其运行之前为 `—`。
- **Status** — 新增时为 `Open`。`Resolved YYYY-MM-DD` 记录债务
  被修复的日期；`Accepted — reason` 记录有意识地保留它的决定。
- **Added** — 写入该行的日期，`YYYY-MM-DD`。报告模式根据此日期和 `Resolved` 日期
  统计新增和解决的条目。
- **Sprint** — 计划修复该债务的冲刺，或 `Backlog`。

### Rules
### 规则
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info)
- "Scan" should run at least once per sprint to catch new debt
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason
- 技术债本身并非坏事 — 它是一种工具。登记表跟踪的是有意识的决策。
- 每条债务条目都必须解释为何被接受（截止日期、原型、信息缺失）
- "Scan" 每个冲刺至少运行一次，以捕获新的债务
- 超过 3 个冲刺未采取行动的条目，应要么被修复，要么在有记录理由的情况下被有意识地接受
