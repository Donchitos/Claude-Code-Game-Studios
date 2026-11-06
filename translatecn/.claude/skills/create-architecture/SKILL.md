---
name: create-architecture
description: "Author the architecture blueprint before code is written. Validates decisions against the pinned engine, flags knowledge gaps."
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---
---
name: create-architecture
description: "在写代码之前编写架构蓝图。对照已固定的引擎验证决策，标记知识缺口。"
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Create Architecture
# 创建架构

This skill produces `docs/architecture/architecture.md` — the master architecture
document that translates all approved GDDs into a concrete technical blueprint.
It sits between design and implementation, and must exist before sprint planning begins.
此技能产出 `docs/architecture/architecture.md` — 主架构
文档，将所有已批准的 GDD 转化为具体技术蓝图。
它位于设计与实现之间，且必须在冲刺规划开始之前存在。

**Distinct from `/architecture-decision`**: ADRs record individual point decisions.
This skill creates the whole-system blueprint that gives ADRs their context.
**与 `/architecture-decision` 不同**：ADR 记录单个点决策。
此技能创建为 ADR 提供上下文的整体系统蓝图。

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.
完整检查模式参见 `.claude/docs/director-gates.md`。各门禁定义位于 `.claude/docs/director-gates/[gate-id].md` — 被启动的智能体读取它自己的门禁文件；不要在父会话中读取它。

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅在重大选择上询问 · 自主模式记录后继续；
`automation_always_ask` 类别总是询问）。

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = layer diagrams + decision bullets,
no essays; `balanced` = diagrams + paragraph explanations of layer choices
(`rigor: standard`); `thorough` = full prose with rationale, trade-offs, and alternatives
considered per layer. Apply it to every section you author.
**`docs.density`** — 它控制每个小节*深度*，而 `workflow`
控制存在哪些小节。`modes.rigor` 会同时设定这两者；单独设定
`docs.density` 可只改变深度：`terse`（默认，经由 `rigor: minimal`）= 层图 + 决策要点，
不含长篇论述；`balanced` = 图 + 对各层选择的段落解释
（`rigor: standard`）；`thorough` = 完整散文，包含理由、权衡以及每层
考虑过的替代方案。将其应用于你编写的每个小节。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full architecture: all layers, module ownership, data flow, API
  boundaries, full ADR audit.
- `standard` — simplified: system layer map + critical ADR list only.
- `minimal` — not required. Can still be run voluntarily.
**`workflow`**（参见 `.claude/docs/workflow-modes.md`）：
- `full` — 完整架构：所有层、模块归属、数据流、API
  边界、完整 ADR 审计。
- `standard` — 简化：仅系统层图 + 关键 ADR 列表。
- `minimal` — 不需要。仍可自愿运行。

**Argument modes:**
- **No argument / `full`**: Full guided walkthrough — all sections, start to finish
- **`layers`**: Focus on the system layer diagram only
- **`data-flow`**: Focus on data flow between modules only
- **`api-boundaries`**: Focus on API boundary definitions only
- **`adr-audit`**: Audit existing ADRs for engine compatibility gaps only
**参数模式：**
- **无参数 / `full`**：完整引导式走查 — 所有小节，从头到尾
- **`layers`**：只聚焦系统层图
- **`data-flow`**：只聚焦模块间的数据流
- **`api-boundaries`**：只聚焦 API 边界定义
- **`adr-audit`**：只审计既有 ADR 的引擎兼容性缺口

---

## Phase 0: Load All Context
## 阶段 0：加载全部上下文

**Read `references/0-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/0-load-context.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 1: System Layer Mapping
## 阶段 1：系统分层映射

**Read `references/1-layers.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/1-layers.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 2: Module Ownership Map
## 阶段 2：模块归属映射

**Read `references/2-module-ownership.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/2-module-ownership.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 3: Data Flow
## 阶段 3：数据流

**Read `references/3-data-flow.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/3-data-flow.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 4: API Boundaries
## 阶段 4：API 边界

**Read `references/4-api-boundaries.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/4-api-boundaries.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 5: ADR Audit + Traceability Check
## 阶段 5：ADR 审计 + 可追溯性检查

**Read `references/5-adr-audit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/5-adr-audit.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 6: Missing ADR List
## 阶段 6：缺失 ADR 列表

**Read `references/6-missing-adrs.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/6-missing-adrs.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 7: Write the Master Architecture Document
## 阶段 7：写入主架构文档

**Read `references/7-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/7-write.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Phase 8: Handoff
## 阶段 8：交接

**Read `references/8-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/8-handoff.md` 并遵循它** — 此阶段的步骤在那个文件里，不在此处。若会话在此阶段被压缩或恢复，请重读它。

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.
**适用于 `collaborative` 模式（默认）。** 对于 `guided` 与
`autonomous` 模式，参见 `.claude/docs/automation-modes.md` — 以下规则
描述的是协作模式的要求，而非通用行为。

This skill follows the collaborative design principle at every phase:
此技能在每个阶段都遵循协作设计原则：

1. **Load context silently** — do not narrate file reads
2. **Present findings** — show the knowledge gap inventory and layer proposals
3. **Ask before deciding** — present options for each architectural choice
4. **Draft before approval** — show the content inline before asking to write it.
   Never ask approval for a section the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] (write now /
   show full draft first / not yet). For multi-file changesets, list every file
   and what changes, then ask once grouped — not separate plain-text asks per file.
6. **One write, after every section is approved** — the document is written once,
   at Phase 7; Phase 7b's Step 4 only updates its Document Status, after its own
   ask. Record each approved section's decisions in
   `production/session-state/active.md` as you go, so a crash loses no decision.
   A revision that Phase 7b forces is written the same way — once, after its
   re-drafted sections are approved — and an update (Phase 0e) writes only the
   sections it chose.
1. **静默加载上下文** — 不要叙述文件读取
2. **呈现发现** — 展示知识缺口清单与分层提议
3. **决定前询问** — 为每个架构选择呈现选项
4. **批准前起草** — 在请求写入之前内联展示内容。
   绝不要为用户尚未见过的小节请求批准。
5. **使用 `AskUserQuestion` 进行写入批准** — 纯文本的"May I?"并不
   足够。使用带标注选项 [A]/[B]/[C] 的结构化工具（立即写入 /
   先展示完整草稿 / 暂不）。对于多文件变更集，列出每个文件
   及其更改，然后一次性成组询问 — 而不是逐文件分别纯文本询问。
6. **在每个小节获批后一次性写入** — 文档只写一次，
   在阶段 7；阶段 7b 的步骤 4 仅在其自身询问之后更新其 Document Status。
   边做边把每个获批小节的决策记录在
   `production/session-state/active.md` 中，这样即使崩溃也不会丢失决策。
   阶段 7b 强制进行的修订以同样方式写入 — 一次，在其
   重新起草的小节获批之后 — 而更新（阶段 0e）只写入
   它所选择的小节。

Never make a binding architectural decision without user input. If the user is
unsure, present 2-4 options with pros/cons before asking them to decide.
绝不在没有用户输入的情况下做出有约束力的架构决策。若用户
不确定，先呈现 2–4 个选项及利弊，再请他们决定。

---

## Recommended Next Steps
## 推荐的后续步骤

- Run `/architecture-decision [title]` for each required ADR listed in Phase 6 — Foundation layer ADRs first
- Run `/architecture-review` — bootstraps the Requirements Traceability Matrix and TR registry from the ADRs just written, and gives each provisional TR-ID its permanent one. Required before the Pre-Production gate.
- Run `/test-setup` to scaffold `tests/unit/`, `tests/integration/`, CI workflow, and an example test (required for gate-check)
- Run `/ux-design` to initialize `design/ux/interaction-patterns.md` and `design/accessibility-requirements.md` (required for gate-check)
- Run `/create-control-manifest` once the required ADRs are written to produce the layer rules manifest
- Run `/gate-check pre-production` when all required ADRs, `/test-setup`, and `/ux-design` are complete
- 为阶段 6 中列出的每个必需 ADR 运行 `/architecture-decision [title]` — 先 Foundation 层的 ADR
- 运行 `/architecture-review` — 从刚写好的 ADR 引导建立需求可追溯性矩阵与 TR 注册表，并为每个临时 TR-ID 赋予永久 ID。在预制作（Pre-Production）门禁之前为必需项。
- 运行 `/test-setup` 以搭建 `tests/unit/`、`tests/integration/`、CI 工作流以及一个示例测试（gate-check 所需）
- 运行 `/ux-design` 以初始化 `design/ux/interaction-patterns.md` 与 `design/accessibility-requirements.md`（gate-check 所需）
- 在必需 ADR 写好后运行 `/create-control-manifest`，产出层规则清单
- 当所有必需 ADR、`/test-setup` 与 `/ux-design` 均已完成时，运行 `/gate-check pre-production`
