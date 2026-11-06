# Automation Modes — Shared Skill Pattern
# 自动化模式 — 共享技能模式

This document defines the standard `modes.automation` pattern for every skill
that uses `AskUserQuestion` or writes files. Skills reference this document
instead of embedding the full mode-handling rules inline — eliminating drift
when the pattern needs updating.
本文档为每个使用 `AskUserQuestion` 或写入文件的技能定义标准的
`modes.automation` 模式。技能引用本文档，而不是内联嵌入完整的模式处理规则 —
从而在模式需要更新时消除漂移。

**Scope**: 68 skills across authoring, review, team orchestration,
implementation, and utility categories. Any skill that gates a decision
through `AskUserQuestion` or writes files should follow this pattern.
**范围**：跨创作、评审、团队编排、实现和实用工具类别的 68 个技能。
任何通过 `AskUserQuestion` 对决策设门禁或写入文件的技能都应遵循此模式。

**Companion spec**: `.claude/docs/effects-map.md`
section `modes.automation` is the source of truth for behavior. This document
is the implementation pattern.
**配套规范**：`.claude/docs/effects-map.md` 中的
`modes.automation` 章节是行为的权威来源。本文档
是实现模式。

> **Do not read `effects-map.md` during a skill run** — it is a very large file, a
> reference for authoring the spec rather than a runtime input, and **this
> document is self-sufficient** for deciding what to ask and what to proceed on.
> If a case genuinely is not covered here, read only its `modes.automation`
> section, never the file.
> **在技能运行期间不要读取 `effects-map.md`** — 它是一个非常大的文件，
> 是编写规范时的参考而非运行时输入，而且**本文档是自足的**，
> 足以决定要询问什么以及继续执行什么。
> 如果某个情况确实未在此覆盖，只读取它的 `modes.automation`
> 章节，绝不要读取整个文件。

---

## How to Use This Document
## 如何使用本文档

In any skill, add a single resolution step at startup and reference the
mode-aware AskUserQuestion pattern below at each gated site.
在任何技能中，在启动时添加一个解析步骤，并在每个设门禁的位置引用
下面的模式感知 AskUserQuestion 模式。

**Startup prelude** (add near Phase 0 / Phase 1):
**启动序曲**（添加在 Phase 0 / Phase 1 附近）：

```
Resolve automation mode (once, store for the run):
1. Read `modes.automation` from `project.local.yaml` (if present) → use that
2. Else read `modes.automation` from `project.yaml` → use that value
3. Else → default to `collaborative`

Pattern reference: `.claude/docs/automation-modes.md`.
```

This resolution is automatic via `get_effective_yaml_key modes.automation` —
the helper deep-merges project.local.yaml on top of project.yaml.
此解析通过 `get_effective_yaml_key modes.automation` 自动完成 —
该辅助函数将 project.local.yaml 深度合并到 project.yaml 之上。

**At each AskUserQuestion site**, follow the pattern table in §Universal
Rules below. The skill author labels each decision as **major** or **minor**
(per the classification matrix in §Major vs Minor) so the pattern can apply
the right rule.
**在每个 AskUserQuestion 位置**，遵循下文 §通用规则 中的模式表。
技能作者将每个决策标记为**重大**或**次要**
（按 §重大 vs 次要 中的分类矩阵），以便模式能够应用正确的规则。

---

## The Three Modes
## 三种模式

| Mode | Speed | Control | What changes |
|------|-------|---------|--------------|
| `collaborative` | Slowest | Full — every decision is the user's | Default. Q→O→D→Draft→Approval strictly followed. |
| `guided` | Balanced | High — major decisions are the user's, minor ones proceed automatically | AI states recommendation and proceeds for minor decisions. AskUserQuestion reserved for major decisions. |
| `autonomous` | Fastest | Low — AI decides, logs, and proceeds | No AskUserQuestion (except `automation_always_ask` categories). All decisions logged. |

| 模式 | 速度 | 控制 | 变化内容 |
|------|-------|---------|--------------|
| `collaborative` | 最慢 | 完全 — 每个决策由用户做出 | 默认。严格遵循 Q→O→D→Draft→Approval。 |
| `guided` | 平衡 | 高 — 重大决策由用户做出，次要决策自动继续 | AI 陈述建议并继续处理次要决策。AskUserQuestion 保留给重大决策。 |
| `autonomous` | 最快 | 低 — AI 决策、记录并继续 | 不使用 AskUserQuestion（除 `automation_always_ask` 类别外）。所有决策都记录。 |

**Default**: `collaborative`. New projects start here.
**默认**：`collaborative`。新项目从这里开始。

**Set by**: `/start`, `/settings`.
**由谁设置**：`/start`、`/settings`。

---

## Universal Rules per Mode
## 每种模式的通用规则

### Collaborative (current v1.0 behavior — no change)
### Collaborative（当前 v1.0 行为 — 无变化）

- `AskUserQuestion` called for every multi-option decision
- `AskUserQuestion` 对每个多选项决策调用
- 2–4 options presented with pros/cons for every design choice
- 每个设计选择都提供 2–4 个选项及优缺点
- Full draft shown and approved before every file write
- 每次写文件前展示并批准完整草稿
- "May I write this to [filepath]?" asked before every write
- 每次写入前询问“我可以把它写入 [filepath] 吗？”
- Section-by-section approval in multi-section authoring skills
- 多章节创作技能中逐章节批准
- Multi-file changes require explicit approval
- 多文件变更需要明确批准

### Guided
### Guided（引导）

- `AskUserQuestion` called for **major decisions only** (see classification below)
- `AskUserQuestion` 仅对**重大决策**调用（见下面的分类）
- Minor decisions: AI states recommendation inline and proceeds — e.g.
  > *"Going with a static utility pattern here — it fits the existing architecture. Continuing unless you want to change direction."*
- 次要决策：AI 内联陈述建议并继续 — 例如
  > *“这里采用静态工具模式 — 它契合现有架构。继续推进，除非你想改变方向。”*
- Updates to existing files: draft shown briefly before writing — proceeds after a short summary, does not wait for explicit "yes"
- 更新现有文件：写入前简要展示草稿 — 简短摘要后继续，不等待明确的“是”
- "May I write?" asked for **new files only**, and a new file waits for the answer — updates to existing files proceed directly
- “我可以写入吗？”仅对**新文件**询问，且新文件会等待答案 — 现有文件的更新直接继续
- Still presents options for major decisions but caps at 2 choices with a clear recommendation
- 重大决策仍提供选项，但最多 2 个选择并附明确建议
- Multi-section authoring: writes each approved section immediately, no per-section confirmation
- 多章节创作：每个已批准章节立即写入，不做逐章节确认

### Autonomous
### Autonomous（自主）

- No `AskUserQuestion` calls **except** for categories listed in `modes.automation_always_ask`
- **除** `modes.automation_always_ask` 中列出的类别外，不调用 `AskUserQuestion`
- No draft review
- 不审查草稿
- No "May I write?" prompts — writes directly
- 不提示“我可以写入吗？” — 直接写入
- Picks the recommended option for every decision without presenting alternatives
- 为每个决策选择推荐选项，不提供替代方案
- All decisions logged via `log_decision` (helper in yaml-helper.sh) to
  `production/session-logs/decision-log.md`
- 所有决策通过 `log_decision`（yaml-helper.sh 中的辅助函数）记录到
  `production/session-logs/decision-log.md`
- User reviews decision log post-session to audit choices made
- 用户在会话后审查决策日志以审计所做的选择

### Every mode: a question with no answer
### 每种模式：没有答案的问题

A question that comes back **skipped, dismissed or empty is not an answer**, in
every mode and on every tool: the user closing the question, a headless run that
returns every question as skipped, a reply that picks nothing.
一个返回**被跳过、被忽略或为空的问题不是答案**，在
每种模式和每个工具上都是如此：用户关闭问题、一次无头运行
将每个问题都返回为跳过、一个什么都没选的回复。

- Do not write a file, change a mode or setting, or pick an option on its behalf.
- 不要写入文件、更改模式或设置，或代表它选择某个选项。
- Ask again in plain text, say what is waiting on the answer, and wait.
- 用纯文本再次询问，说明有什么在等待该答案，然后等待。
- In `autonomous`, a question the mode did not require can be decided as usual:
  pick the recommended option and log it via `log_decision`. A question in an
  `automation_always_ask` category, or in an exempt skill, is the user's: ask
  again and wait.
- 在 `autonomous` 中，模式不要求的问题可以照常决定：
  选择推荐选项并通过 `log_decision` 记录。属于
  `automation_always_ask` 类别或在豁免技能中的问题则属于用户：再次
  询问并等待。
- Where nobody can answer (CI, a headless run), stop and report what is waiting
  rather than choosing.
- 在无人能回答的地方（CI、无头运行），停止并报告有什么在等待，
  而不是做选择。

---

## Major vs Minor Decision Classification
## 重大 vs 次要决策分类

Skills label each gated decision as **major** or **minor** before applying
the mode rules.
技能在应用模式规则之前，将每个设门禁的决策标记为**重大**或**次要**。

### Major — always use AskUserQuestion in guided mode
### 重大 — 在 guided 模式下始终使用 AskUserQuestion

| Decision type | Example |
|---------------|---------|
| Choosing a system name or document path | "What should we call this system?" |
| Mutually exclusive design directions | "Real-time or turn-based?" |
| Any choice that gates downstream work | Engine choice, architecture approach |
| Scope changes | "Cut this feature or slip the deadline?" |
| Any decision that can't be changed without significant rework | Core loop mechanic |

| 决策类型 | 示例 |
|---------------|---------|
| 选择系统名称或文档路径 | “这个系统应该叫什么？” |
| 互斥的设计方向 | “实时还是回合制？” |
| 任何对下游工作设置门禁的选择 | 引擎选择、架构方案 |
| 范围变更 | “砍掉这个功能还是推迟截止日期？” |
| 任何不大幅返工就无法更改的决策 | 核心循环机制 |

### Minor — AI recommends and proceeds in guided mode
### 次要 — 在 guided 模式下 AI 建议并继续

| Decision type | Example |
|---------------|---------|
| Which section to work on next | "Moving to Edge Cases next" |
| Optional section inclusion | "Adding a Visual Notes section — fits the system" |
| Formatting and structure choices | Heading levels, table vs prose |
| Adding detail to an already-decided direction | Sub-options within an approved approach |
| Next-step routing after a phase completes | "Running design-review now" |

| 决策类型 | 示例 |
|---------------|---------|
| 下一步处理哪个章节 | “接下来转到 Edge Cases” |
| 可选章节的纳入 | “添加一个 Visual Notes 章节 — 契合该系统” |
| 格式与结构选择 | 标题层级、表格还是散文 |
| 为已决定的方向补充细节 | 已批准方案内的子选项 |
| 阶段完成后的下一步路由 | “现在运行 design-review” |

---

## `automation_always_ask` Categories
## `automation_always_ask` 类别

Even in `autonomous` mode, certain decision categories ALWAYS trigger
`AskUserQuestion`. The configured list lives at
`modes.automation_always_ask` in `project.yaml`.
即使在 `autonomous` 模式下，某些决策类别也始终触发
`AskUserQuestion`。配置的列表位于
`project.yaml` 的 `modes.automation_always_ask`。

**Default** (when unset): `[scope_changes, file_deletions, schema_changes]`.
**默认**（未设置时）：`[scope_changes, file_deletions, schema_changes]`。

### Recognized categories
### 已识别的类别

**This table is the set you may configure, NOT the set that always asks.** Only
the categories actually listed in `modes.automation_always_ask` — the three
defaults above, unless the project overrides them — interrupt an `autonomous`
run. The other rows do nothing until a project opts into them. Read the resolved
list with `resolve_config` rather than assuming a row here is active. Treating a
category the project never configured, such as `architecture_decisions`, as
active reports rule violations the project never asked for.
**此表是你可以配置的集合，而不是始终询问的集合。** 只有
实际列在 `modes.automation_always_ask` 中的类别 — 即上述三个
默认值，除非项目覆盖它们 — 才会中断 `autonomous`
运行。其他行在项目选择启用之前不起作用。用 `resolve_config` 读取解析后的
列表，而不是假定这里的某一行已激活。把项目从未配置的类别（例如
`architecture_decisions`）当作已激活，会报告项目从未要求的规则违规。

| Category | Examples of decisions in this category |
|----------|----------------------------------------|
| `scope_changes` | Cutting a feature, slipping a deadline, splitting/merging an epic, removing acceptance criteria |
| `file_deletions` | Removing a story, deleting a GDD, removing a system, removing a test file |
| `schema_changes` | Changes to project.yaml, story template, control manifest, ADR template, GDD template |
| `architecture_decisions` | New ADR creation, ADR replacement, system boundary changes |
| `version_bumps` | Engine version change, framework version bump, dependency major version change |
| `external_calls` | Invoking external APIs (asset gen, AI services) when in autonomous mode |

| 类别 | 该类别中的决策示例 |
|----------|----------------------------------------|
| `scope_changes` | 砍掉功能、推迟截止日期、拆分/合并 epic、移除验收标准 |
| `file_deletions` | 移除 story、删除 GDD、移除系统、移除测试文件 |
| `schema_changes` | 更改 project.yaml、story 模板、控制清单、ADR 模板、GDD 模板 |
| `architecture_decisions` | 新建 ADR、替换 ADR、系统边界变更 |
| `version_bumps` | 引擎版本变更、框架版本升级、依赖主版本变更 |
| `external_calls` | 在自主模式下调用外部 API（资产生成、AI 服务） |

### Helper
### 辅助函数

```bash
is_always_ask_category <category>
```

Returns 0 if the named category is in `modes.automation_always_ask`,
1 otherwise. Skills use this at decision points that fall into any
of the six categories above.
如果指定的类别在 `modes.automation_always_ask` 中则返回 0，
否则返回 1。技能在落入上述六个类别中任何一个的决策点使用它。

---

## Exemptions — Skills That Ignore the Automation Setting
## 豁免 — 忽略自动化设置的技能

These skills always behave as `collaborative` regardless of the setting:
这些技能无论设置如何都始终表现为 `collaborative`：

| Skill | Why always collaborative |
|-------|--------------------------|
| `hotfix` | Emergency decisions — user must approve scope and risk before any action |
| `gate-check` | Results must be reviewed — a gate verdict without acknowledgement defeats the purpose |
| `day-one-patch` | Release-critical — every action needs explicit sign-off |
| `setup-engine` | One-time irreversible choice that affects the entire project |

| 技能 | 为什么始终是 collaborative |
|-------|--------------------------|
| `hotfix` | 紧急决策 — 用户必须在任何行动前批准范围和风险 |
| `gate-check` | 结果必须被审查 — 未经确认的门禁裁决会失去意义 |
| `day-one-patch` | 发布关键 — 每个操作都需要明确签字 |
| `setup-engine` | 一次性不可逆的选择，影响整个项目 |

These skills do NOT add the automation prelude described above. They keep
the v1.0 Q→O→D→Draft→Approval protocol exactly.
这些技能**不**添加上述自动化序曲。它们精确保持
v1.0 的 Q→O→D→Draft→Approval 协议。

---

## Decision Log Format (Autonomous Mode)
## 决策日志格式（自主模式）

When `autonomous` mode skips an `AskUserQuestion`, the skill calls
`log_decision` to write a structured entry. Format per entry:
当 `autonomous` 模式跳过一个 `AskUserQuestion` 时，技能调用
`log_decision` 写入结构化条目。每条条目的格式：

```markdown
## [timestamp] — [skill-name]

**Decision point:** [what was being decided]
**Options considered:** [list of options that would have been presented]
**Chosen:** [what was picked]
**Reason:** [one-line rationale]
**Category:** [scope_changes | file_deletions | schema_changes | … or "minor"]
```

Written to `production/session-logs/decision-log.md` (append-only, never
truncated, created if absent). The user reviews the log post-session to
audit choices made.
写入 `production/session-logs/decision-log.md`（仅追加、绝不
截断、缺失时创建）。用户在会话后审查日志以
审计所做的选择。

### Helper
### 辅助函数

```bash
log_decision "<skill-name>" "<decision-point>" "<options>" "<chosen>" "<reason>" "<category>"
```

Wraps the format above. Skills call this at every decision point in
autonomous mode, including ones where the chosen value differs from
the recommended default (so the audit trail is complete).
封装上述格式。技能在自主模式的每个决策点调用它，
包括所选值不同于推荐默认值的情况（以便审计轨迹完整）。

### What to log, and at what granularity
### 记录什么，以及以什么粒度

These rules keep autonomous logs consistent across runs:
这些规则使自主日志在各次运行之间保持一致：

- **Log every decision that would have shown an `AskUserQuestion` widget** —
  including option/framing choices, not only final approvals. The
  framing/options decisions (which approach, which formula, which edge
  cases) are usually the most informative entries; do not log only the
  rote "approve this section" steps.
- **记录每个本应显示 `AskUserQuestion` 组件的决策** —
  包括选项/框架选择，而不仅是最终批准。框架/选项决策
  （哪种方案、哪个公式、哪些边缘情况）通常是最有信息量的条目；
  不要只记录机械的“批准此章节”步骤。
- **Collapse a single multi-tab widget into ONE entry.** List each tab's
  choice under **Chosen** rather than emitting one entry per tab.
- **将单个多标签组件折叠为一条条目。** 在 **Chosen** 下列出每个标签的
  选择，而不是为每个标签发一条条目。
- **Do NOT log conversational answers the model synthesizes for itself**
  (e.g. internal Q&A while drafting a section) — only log what would have
  been an explicit user decision.
- **不要记录模型为自己合成的对话式答案**
  （例如起草章节时的内部问答）— 只记录本应是明确用户决策的内容。
- **Do NOT emit a separate entry for routine "may I write?" file gates** —
  fold the write into the decision it implements (autonomous mode writes
  directly anyway).
- **不要为常规的“我可以写入吗？”文件门禁单独发条目** —
  把写入折叠进它所实现的决策中（自主模式本来就直接写入）。

### Categorizing data-file writes
### 对数据文件写入进行分类

The most common categorization mistake is treating a data-file append as a
`schema_changes` decision:
最常见的分类错误是将数据文件追加当作
`schema_changes` 决策：

- **Appending facts to a registry or index** — e.g.
  `design/registry/entities.yaml`, `design/gdd/systems-index.md` — is
  **`minor`**. It adds data without altering a *template*.
- **向注册表或索引追加事实** — 例如
  `design/registry/entities.yaml`、`design/gdd/systems-index.md` — 属于
  **`minor`**。它添加数据而不改动*模板*。
- **`schema_changes`** means editing the *structure* of `project.yaml` or a
  template (story / ADR / GDD / control-manifest template). These are
  always-ask.
- **`schema_changes`** 意味着编辑 `project.yaml` 的*结构*或某个
  模板（story / ADR / GDD / control-manifest 模板）。这些是
  始终询问的。
- **When genuinely unsure** between `minor` and an always-ask category,
  prefer the always-ask category and prompt — failing safe.
- **当确实不确定** 是 `minor` 还是某个始终询问的类别时，
  优先选择始终询问的类别并提示 — 安全失败。

---

## The Pattern Skills Apply at Each AskUserQuestion Site
## 技能在每个 AskUserQuestion 位置应用的模式

```
At each decision point in this skill:

1. Classify the decision: major or minor (see §Major vs Minor above).
2. Check whether the decision falls into an `automation_always_ask`
   category: scope_changes, file_deletions, schema_changes,
   architecture_decisions, version_bumps, external_calls.
3. Apply the mode rule:

   collaborative:           AskUserQuestion always.
   guided + major:          AskUserQuestion with capped options + recommendation.
   guided + minor:          State recommendation inline, proceed.
   autonomous + always_ask: AskUserQuestion (regardless of mode).
   autonomous + other:      Pick recommended, log via log_decision, proceed.
4. If the question comes back skipped, dismissed or empty, it is not an
   answer: see §Every mode: a question with no answer.
```

This is the contract. Skills that follow this pattern produce
consistent behavior across all three automation modes.
这就是契约。遵循此模式的技能在所有三种自动化模式下
产生一致的行为。
