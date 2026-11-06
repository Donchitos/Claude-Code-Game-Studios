---
name: architecture-decision
description: "Create an ADR documenting a technical decision: context, alternatives considered, consequences."
argument-hint: "[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(wc -c *), Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---
---
name: architecture-decision
description: "创建一份记录技术决策的 ADR：背景、考虑过的备选方案、后果。"
argument-hint: "[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(wc -c *), Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析——按原样使用；`--review` 会覆盖 `review_mode`。没有配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Architecture Decision
# 架构决策

When this skill is invoked:
当此技能被调用时：

## 0. Parse Arguments — Detect Retrofit / Acceptance Mode
## 0. 解析参数——检测改造 / 接受模式

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.
完整的检查模式见 `.claude/docs/director-gates.md`。各门禁定义位于 `.claude/docs/director-gates/[gate-id].md`——被派生的智能体读取自己的门禁文件；不要在父会话中读取它。

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅重大项 · 自主模式记录并继续；
`automation_always_ask` 类别总是提示）。

**`team.size`**: which agents validate this ADR (orthogonal to review_mode/workflow).
- **`individual`** (default): `technical-director` (TD-ADR) + the engine-specialist.
- **`small`** and **`studio`**: the same two. This skill spawns no engine
  sub-specialist and no adversarial reviewer at any size.
**`team.size`**：哪些智能体验证此 ADR（与 review_mode/workflow 正交）。
- **`individual`**（默认）：`technical-director`（TD-ADR）+ 引擎专家。
- **`small`** 和 **`studio`**：同样这两位。此技能在任何规模下都不派生引擎
  子专家，也不派生对抗性评审者。

**`docs.density`** — it controls the *depth* of the ADR's prose sections, not
which sections the skeleton emits (that is fixed). `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary ADR verbosity alone:
`terse` (the default, via `rigor: minimal`) = decision + alternatives as bullets, one line of rationale each;
`balanced` = paragraph per section with light rationale (`rigor: standard`); `thorough` =
full prose with trade-offs and worked rationale in Decision, Alternatives, and
Consequences. Apply it to the prose sections; the Engine Compatibility, ADR
Dependencies, and GDD Requirements tables are structural and stay whole at every
density.
**`docs.density`**——它控制 ADR 正文各小节的*深度*，而非骨架会输出哪些小节（那是固定的）。`modes.rigor` 会随 `workflow` 一并设置它；显式设置 `docs.density` 可单独改变 ADR 的详略程度：
`terse`（默认，经由 `rigor: minimal`）= 以项目符号列出决策 + 备选方案，每条一行理由；
`balanced` = 每个小节一段，附简要理由（`rigor: standard`）；`thorough` =
完整正文，在决策、备选方案和后果中给出权衡与展开的理由。将其应用于正文小节；引擎兼容性、ADR
依赖和 GDD 需求表格是结构性的，在任何详略程度下都保持完整。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — all ADRs on the required ADR list must be completed.
- `standard` — critical ADRs only (Foundation-layer systems).
- `minimal` — not required. Can still be run voluntarily.
**`workflow`**（见 `.claude/docs/workflow-modes.md`）：
- `full` — 必需 ADR 清单上的所有 ADR 都必须完成。
- `standard` — 仅关键 ADR（基础层系统）。
- `minimal` — 非必需。仍可自愿运行。

**If the argument starts with `retrofit` followed by a file path**
**如果参数以 `retrofit` 开头并后跟文件路径**

**Read `references/0-retrofit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/0-retrofit.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

**If the argument starts with `accept` followed by an ADR id**
**如果参数以 `accept` 开头并后跟 ADR 编号**

**Read `references/0-accept.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/0-accept.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

If NOT in retrofit or acceptance mode, proceed to Step 1 below (normal ADR authoring).
如果不是改造或接受模式，继续下方第 1 步（常规 ADR 撰写）。

**No-argument guard**: If no argument was provided (title is empty), ask before
running Phase 0:
**无参数保护**：如果未提供参数（标题为空），在运行阶段 0 之前先询问：

> "What technical decision are you documenting? Please provide a short title
> (e.g., `event-system-architecture`, `physics-engine-choice`)."
> "你在记录什么技术决策？请提供一个简短标题
> （例如 `event-system-architecture`、`physics-engine-choice`）。"

Use the user's response as the title, then proceed to Step 1.
将用户的回答作为标题，然后继续第 1 步。

---

## 1. Load Engine Context (ALWAYS FIRST)
## 1. 加载引擎上下文（总是第一步）

**Read `references/1-engine-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/1-engine-context.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 2. Determine the next ADR number
## 2. 确定下一个 ADR 编号

Scan `docs/architecture/` for existing ADRs to find the next number.
扫描 `docs/architecture/` 中的现有 ADR 以找到下一个编号。

---

## 3. Gather context
## 3. 收集上下文

**Read `references/3-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/3-gather-context.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 4. Guide the decision collaboratively
## 4. 协作式引导决策

**Read `references/4-decide.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/4-decide.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 5. Generate the ADR
## 5. 生成 ADR

**Read `references/5-generate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/5-generate.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 6. Closing Next Steps
## 6. 收尾及后续步骤

After the ADR is written (and registry optionally updated), close with `AskUserQuestion`.
在 ADR 写入（并可选更新注册表）之后，用 `AskUserQuestion` 收尾。

Before generating the widget:
1. Read the `## Required ADRs` section of `docs/architecture/architecture.md` (by section) and list `docs/architecture/adr-*.md`: a required ADR with no file is still unwritten. Without `architecture.md`, look for ADRs flagged in technical-preferences.md or systems-index.md as prerequisites
2. Check if all prerequisite ADRs are now written. If yes, include a "Start writing GDDs" option.
3. List ALL remaining priority ADRs as individual options — not just the next one or two.
在生成该控件之前：
1. 按小节读取 `docs/architecture/architecture.md` 的 `## Required ADRs` 部分，并列出 `docs/architecture/adr-*.md`：一个必需但无文件的 ADR 仍是未写入的。没有 `architecture.md` 时，查找在 technical-preferences.md 或 systems-index.md 中被标记为先决条件的 ADR
2. 检查所有先决 ADR 现在是否都已写入。如果是，加入一个"开始撰写 GDD"选项。
3. 将所有剩余的优先 ADR 列为单独的选项——而不只是接下来的一两个。

Widget format:
控件格式：

```
ADR-[NNNN] written and registry updated. What would you like to do next?
[1] Write [next-priority-adr-name] — [brief description from prerequisites list]
[2] Write [another-priority-adr] — [brief description]  (include ALL remaining ones)
[N] Start writing GDDs — run `/design-system [first-undesigned-system]` (only show if all prerequisite ADRs are written)
[N+1] Stop here for this session
```

If there are no remaining priority ADRs and no undesigned GDD systems, offer only "Stop here" and suggest running `/architecture-review` in a fresh session.
如果没有剩余的优先 ADR 也没有未设计的 GDD 系统，只提供"停在这里"，并建议在一个全新会话中运行 `/architecture-review`。

**Always include this fixed notice in the closing output (do NOT omit it):**
**在收尾输出中始终包含这条固定提示（不要省略它）：**

> To validate ADR coverage against your GDDs, open a **fresh Claude Code session**
> and run `/architecture-review`.
>
> **Never run `/architecture-review` in the same session as `/architecture-decision`.**
> The reviewing agent must be independent of the authoring context to give an unbiased
> assessment. Running it here would invalidate the review.
> 要对照你的 GDD 验证 ADR 覆盖情况，请打开一个**全新的 Claude Code 会话**
> 并运行 `/architecture-review`。
>
> **绝不要在与 `/architecture-decision` 相同的会话中运行 `/architecture-review`。**
> 评审智能体必须独立于撰写上下文，才能给出无偏见的
> 评估。在此处运行会使评审失效。

**Do NOT unblock stories here.** This ADR is `Proposed` — Step 5 guarantees it,
and a story blocked *pending this decision* is still pending it. Unblocking on
authoring defeats the guard at the moment it becomes relevant: the pipeline
appears to flow while running on decisions nobody has accepted.
**不要在此处解除故事的阻塞。** 此 ADR 是 `Proposed`——第 5 步保证了这一点，
而一个*搁置于此决策*的故事仍处于搁置状态。在撰写时就解除阻塞，恰好在其变得相关的时刻破坏了这道防护：管线
看起来在流动，实则运行在无人接受的决策之上。

Instead, tell the user what is now waiting on acceptance:
相反，告诉用户现在有什么在等待接受：

> "ADR-NNNN is written and `Proposed`. [N] stories remain `Blocked` pending it.
> Run `/architecture-decision accept ADR-NNNN` when the decision is settled —
> that is what moves them to `Ready`."
> "ADR-NNNN 已写入并处于 `Proposed`。仍有 [N] 个故事因它而 `Blocked`。
> 当决策确定后，运行 `/architecture-decision accept ADR-NNNN`——
> 那才是将它们移至 `Ready` 的操作。"

List the blocked stories by path so the cost of leaving it Proposed is visible.
(Acceptance has consequences enforced across many skills and an authority
recorded in only a few, so the route between them must stay explicit.)
按路径列出被阻塞的故事，让将其留在 Proposed 的代价可见。
（接受所带来的后果在许多技能中被强制执行，而权威记录只在少数几处，
因此它们之间的路径必须保持明确。）
