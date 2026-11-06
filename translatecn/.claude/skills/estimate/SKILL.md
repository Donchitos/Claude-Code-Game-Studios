---
name: estimate
description: "Estimate task effort from complexity, dependencies, velocity, risk. Structured estimate with confidence levels."
argument-hint: "[task-description]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: sonnet
---
---
name: estimate
description: "依据复杂度、依赖、速度与风险估算任务工作量。带置信等级的结构化估算。"
argument-hint: "[task-description]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: sonnet
---

# Estimate

# 估算

## Phase 1: Understand the Task

## 阶段 1：理解任务

Read the task description from the argument. If the description is too vague to estimate meaningfully, ask for clarification before proceeding.

从参数读取任务描述。若描述过于含糊、无法进行有意义的估算，请先请求澄清再继续。

Read CLAUDE.md for project context: tech stack, coding standards, architectural patterns, and any estimation guidelines.

阅读 CLAUDE.md 以获取项目上下文：技术栈、编码规范、架构模式，以及任何估算指引。

Read relevant design documents from `design/gdd/` if the task relates to a documented feature or system. Read them by section: find the headings you need with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit.

若任务涉及已记录的功能或系统，从 `design/gdd/` 读取相关设计文档。按小节读取：用 Grep 工具（pattern `^#`，content 模式）找到需要的标题，再用 offset 与 limit 读取对应区间。

---

## Phase 2: Scan Affected Code

## 阶段 2：扫描受影响的代码

Identify files and modules that would need to change:

找出需要改动的文件与模块：

- Measure size and branching with Grep, per affected file — Read, Glob and Grep
  are this skill's only tools, so these counts are the measurement:
  - **Size:** `Grep pattern="[^[:space:]]" path="[file]" output_mode="count"` —
    non-blank lines.
  - **Branching:** `Grep pattern="(^|[^A-Za-z0-9_])(if|elif|for|foreach|while|match|switch|case|catch)([^A-Za-z0-9_]|$)|&&|[|][|]" path="[file]" output_mode="count"` —
    lines holding a branch or a boolean operator. The count
    approximates cyclomatic complexity (comments and strings count too); report
    it as that, never as a measured complexity.
  - **Dependencies:** what each file pulls in — `preload`/`load(` (GDScript),
    `using` (C#), `#include` (C++) — and which other files reference it.
  - Name any file Grep could not count (missing, binary, unreadable) under Notes
    and Assumptions rather than leaving it out of the totals.
- Identify integration points with other systems
- Check for existing test coverage in the affected areas
- Read past sprint data from `production/sprints/` for similar completed tasks and historical velocity.
  **If there is none**, say so under Notes and Assumptions — "No sprint history found;
  this estimate is not calibrated to the team's velocity" — and treat that as a risk
  in the confidence level, not as a silent padding of the figures.

- 对每个受影响文件用 Grep 测量规模与分支 — Read、Glob 与 Grep 是本技能仅有的工具，因此这些计数即为测量手段：
  - **规模：** `Grep pattern="[^[:space:]]" path="[file]" output_mode="count"` — 非空行数。
  - **分支：** `Grep pattern="(^|[^A-Za-z0-9_])(if|elif|for|foreach|while|match|switch|case|catch)([^A-Za-z0-9_]|$)|&&|[|][|]" path="[file]" output_mode="count"` — 包含分支或布尔运算符的行。该计数近似圈复杂度（注释与字符串也会计入）；应按此报告，绝不可当作已测量的复杂度。
  - **依赖：** 每个文件引入的内容 — `preload`/`load(`（GDScript）、`using`（C#）、`#include`（C++）— 以及其他哪些文件引用了它。
  - 将任何 Grep 无法计数的文件（缺失、二进制、不可读）列在「备注与假设」下，而不是将其排除在总计之外。
- 识别与其他系统的集成点
- 检查受影响区域现有的测试覆盖
- 从 `production/sprints/` 读取以往冲刺数据，寻找类似已完成任务与历史速度。
  **若没有**，请在「备注与假设」下说明 — “未找到冲刺历史；此估算未按团队速度校准” — 并将其视为置信等级中的一项风险，而不是悄悄夸大数据。

---

## Phase 3: Analyze Complexity Factors

## 阶段 3：分析复杂度因素

**Code Complexity:**
- Size and branching of the affected files (Phase 2's Grep counts)
- Number of dependencies and coupling level
- Whether this touches core/engine code vs leaf/feature code
- Whether existing patterns can be followed or new patterns are needed

**代码复杂度：**
- 受影响文件的规模与分支（阶段 2 的 Grep 计数）
- 依赖数量与耦合程度
- 是否触及核心/引擎代码而非叶子/功能代码
- 能否沿用既有模式，或需要新模式

**Scope:**
- Number of systems touched
- New code vs modification of existing code
- Amount of new test coverage required
- Data migration or configuration changes needed

**范围：**
- 触及的系统数量
- 新代码与修改既有代码的比例
- 需要的新测试覆盖量
- 所需的数据迁移或配置变更

**Risk:**
- New technology or unfamiliar libraries
- Unclear or ambiguous requirements
- Dependencies on unfinished work
- Cross-system integration complexity
- Performance sensitivity

**风险：**
- 新技术或不熟悉的库
- 不清晰或含糊的需求
- 对未完成工作的依赖
- 跨系统集成的复杂度
- 性能敏感性

---

## Phase 4: Generate the Estimate

## 阶段 4：生成估算

```markdown
## Task Estimate: [Task Name]
Generated: [Date]

### Task Description
[Restate the task clearly in 1-2 sentences]

### Complexity Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Systems affected | [List] | [Core, gameplay, UI, etc.] |
| Files likely modified | [Count] | [Key files listed below] |
| Size of affected files | [N non-blank lines; M branch lines] | Grep counts; branch lines approximate complexity |
| New code vs modification | [Ratio] | |
| Integration points | [Count] | [Which systems interact] |
| Test coverage needed | [Low / Medium / High] | |
| Existing patterns available | [Yes / Partial / No] | |

**Key files likely affected:**
- `[path/to/file1]` -- [what changes here]

### Effort Estimate

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | [X] | Everything goes right, no surprises |
| Expected | [Y] | Normal pace, minor issues, one round of review |
| Pessimistic | [Z] | Significant unknowns surface, blocked for a day |

**Recommended budget: [Y days]**

### Confidence: [High / Medium / Low]

[Explain which factors drive the confidence level for this specific task.]

### Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

### Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|

### Suggested Breakdown

| # | Sub-task | Estimate | Notes |
|---|----------|----------|-------|
| 1 | [Research / spike] | [X days] | |
| 2 | [Core implementation] | [X days] | |
| 3 | [Testing and validation] | [X days] | |
| | **Total** | **[Y days]** | |

### Notes and Assumptions
- [Key assumption that affects the estimate]
- [Any caveats about scope boundaries]
```

```markdown
## 任务估算：[任务名称]
生成日期：[日期]

### 任务描述
[用 1-2 句话清晰重述任务]

### 复杂度评估

| 因素 | 评估 | 备注 |
|--------|-----------|-------|
| 受影响系统 | [列表] | [核心、玩法、UI 等] |
| 可能修改的文件 | [数量] | [下方列出的关键文件] |
| 受影响文件规模 | [N 非空行；M 分支行] | Grep 计数；分支行近似复杂度 |
| 新代码 vs 修改 | [比例] | |
| 集成点 | [数量] | [哪些系统交互] |
| 所需测试覆盖 | [低 / 中 / 高] | |
| 可用既有模式 | [是 / 部分 / 否] | |

**可能受影响的关键文件：**
- `[path/to/file1]` -- [此处变更什么]

### 工作量估算

| 场景 | 天数 | 假设 |
|----------|------|------------|
| 乐观 | [X] | 一切顺利，无意外 |
| 预期 | [Y] | 正常节奏，小问题，一轮评审 |
| 悲观 | [Z] | 出现重大未知，阻塞一天 |

**建议预算：[Y 天]**

### 置信度：[高 / 中 / 低]

[解释哪些因素驱动了此特定任务的置信等级。]

### 风险因素

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|-----------|--------|------------|

### 依赖

| 依赖项 | 状态 | 延迟的影响 |
|-----------|--------|-------------------|

### 建议拆分

| # | 子任务 | 估算 | 备注 |
|---|----------|----------|-------|
| 1 | [调研 / spike] | [X 天] | |
| 2 | [核心实现] | [X 天] | |
| 3 | [测试与验证] | [X 天] | |
| | **合计** | **[Y 天]** | |

### 备注与假设
- [影响估算的关键假设]
- [关于范围边界的任何注意事项]
```

Output the estimate with a brief summary: recommended budget, confidence level, and the single biggest risk factor.

输出估算并附简短摘要：建议预算、置信等级，以及单一最大风险因素。

This skill is read-only — no files are written. Verdict: **COMPLETE** — estimate generated.

本技能为只读 — 不写入任何文件。判定：**COMPLETE** — 估算已生成。

---

## Phase 5: Next Steps

## 阶段 5：后续步骤

- If confidence is Low: recommend a time-boxed spike (`/prototype`) before committing.
- If the task is > 10 days: recommend breaking it into smaller stories via `/create-stories`.
- To schedule the task: run `/sprint-plan update` to add it to the next sprint (if the project has no sprint plan, as on the default minimal workflow, add it to the brief's build order instead).

- 若置信度为低：建议在承诺之前进行限时 spike（原型验证，`/prototype`）。
- 若任务超过 10 天：建议通过 `/create-stories` 将其拆分为更小的故事。
- 安排任务：运行 `/sprint-plan update` 将其加入下一冲刺（若项目没有冲刺计划，如在默认的 minimal 工作流下，则改为加入简报的构建顺序）。

### Guidelines

### 指引

- Always give a range (optimistic / expected / pessimistic), never a single number
- The recommended budget should be the expected estimate, not the optimistic one
- Round to half-day increments — estimating in hours implies false precision for tasks longer than a day
- Do not pad estimates silently — call out risk explicitly so the team can decide
- Confidence is Low whenever the approach is undecided or the core requirements are still TBD — a range built on an unmade decision is a guess

- 始终给出区间（乐观 / 预期 / 悲观），绝不给出单一数字
- 建议预算应为预期估算，而非乐观估算
- 以半天为增量取整 — 以小时估算会给超过一天的任务带来虚假的精确度
- 不要悄悄夸大估算 — 明确说出风险，让团队自行决定
- 只要方法未定或核心需求仍待定，置信度即为低 — 建立在未做决策之上的区间只是猜测
