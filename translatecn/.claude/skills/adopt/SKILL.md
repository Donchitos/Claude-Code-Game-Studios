---
name: adopt
description: "Brownfield audit — do existing artifacts actually work? Numbered migration plan. Unlike /project-stage-detect, checks compliance not existence."
argument-hint: "[focus: full | gdds | adrs | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/gdd-structure-check.sh *), Bash(bash .claude/scripts/migrate-v1-config.sh --dry-run*)
model: sonnet
---
---
name: adopt
description: "存量项目审计——现有产物真的能用吗？编号的迁移计划。与 /project-stage-detect 不同，它检查合规性而非存在性。"
argument-hint: "[focus: full | gdds | adrs | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/gdd-structure-check.sh *), Bash(bash .claude/scripts/migrate-v1-config.sh --dry-run*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow`

Resolved above — use as-is. `/adopt` also inspects `project.yaml` and the legacy
config files directly when reporting and writing migration state; that raw
inspection is deliberate and separate from the resolved values above.
已在上方解析——按原样使用。`/adopt` 在上报和写入迁移状态时也会直接检查 `project.yaml` 与遗留配置文件；这种原始检查是有意为之的，并且与上方已解析的值分开。

# Adopt — Brownfield Template Adoption
# 采纳——存量项目模板采纳

This skill audits an existing project's artifacts for **format compliance** with
the template's skill pipeline, then produces a prioritised migration plan.
本技能审计现有项目的产物是否与模板的技能流水线**格式合规**，然后产出一份按优先级排列的迁移计划。

**This is not `/project-stage-detect`.**
`/project-stage-detect` answers: *what exists?*
`/adopt` answers: *will what exists actually work with the template's skills?*
**这不是 `/project-stage-detect`。**
`/project-stage-detect` 回答：*存在什么？*
`/adopt` 回答：*存在的东西真的能与模板的技能配合工作吗？*

A project can have GDDs, ADRs, and stories — and every format-sensitive skill
will still fail silently or produce wrong results if those artifacts are in the
wrong internal format.
一个项目可以有 GDD、ADR 和故事——但如果这些产物的内部格式不对，每一个对格式敏感的技能仍会静默失败或产出错误结果。

**Output:** `docs/adoption-plan-[date].md` — a persistent, checkable migration plan.
**产出：** `docs/adoption-plan-[date].md`——一份持久、可核查的迁移计划。

**Argument modes:**

**Audit mode:** `$ARGUMENTS` (blank = `full`)

- **No argument / `full`**: Complete audit — all artifact types
- **`gdds`**: GDD format compliance only
- **`adrs`**: ADR format compliance only
- **`stories`**: Story format compliance only
- **`infra`**: Infrastructure artifact gaps only (registry, manifest, sprint-status, stage.txt)
**参数模式：**

**审计模式：** `$ARGUMENTS`（留空 = `full`）

- **无参数 / `full`**：完整审计——所有产物类型
- **`gdds`**：仅 GDD 格式合规
- **`adrs`**：仅 ADR 格式合规
- **`stories`**：仅故事格式合规
- **`infra`**：仅基础设施产物的缺口（注册表、清单、sprint-status、stage.txt）

---

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` → `project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`（collaborative 始终询问 · guided 仅重大问题 · autonomous 记录并继续；`automation_always_ask` 类别始终提示）。

**`workflow`** (per `.claude/docs/workflow-modes.md`). It scopes the Phase 2 audit and
Phase 3 severity: `full` audits all doc types at full structure; `standard` audits
only the required docs/sections (optional sections are informational, not gaps);
`minimal` is a `design/game-brief.md` format check — GDDs/ADRs/UX are not expected. See Phase 2.
**`workflow`**（依据 `.claude/docs/workflow-modes.md`）。它限定阶段 2 审计与阶段 3 严重程度：`full` 以完整结构审计所有文档类型；`standard` 仅审计必需的文档/章节（可选章节仅供参考，不算缺口）；`minimal` 是一次 `design/game-brief.md` 格式检查——不期望有 GDD/ADR/UX。见阶段 2。

## Phase 1: Detect Project State
## 阶段 1：检测项目状态

**Read `references/1-detect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/1-detect.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 2: Format Audit
## 阶段 2：格式审计

**Read `references/2-format-audit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/2-format-audit.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 3: Classify and Prioritise Gaps
## 阶段 3：对缺口分类并排定优先级

**Read `references/3-classify.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/3-classify.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 4: Build the Migration Plan
## 阶段 4：构建迁移计划

**Read `references/4-migration-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/4-migration-plan.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 5: Present Summary and Ask to Write
## 阶段 5：呈现摘要并询问是否写入

**Read `references/5-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/5-summary.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 6: Write the Adoption Plan
## 阶段 6：写入采纳计划

**Read `references/6-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/6-write.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 7: Offer First Action
## 阶段 7：提供首个行动

**Read `references/7-first-action.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/7-first-action.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.
**适用于 `collaborative` 模式（默认）。** 对于 `guided` 和 `autonomous` 模式，参见 `.claude/docs/automation-modes.md`——以下规则描述的是 collaborative 模式的要求，而非普遍行为。

1. **Read silently** — complete the full audit before presenting anything
2. **Show the summary first** — let the user see scope before asking to write
3. **Ask before writing** — always confirm before creating the adoption plan file
4. **Offer, don't force** — the plan is advisory; the user decides what to fix and when
5. **One action at a time** — after handing off the plan, offer one specific next step,
   not a list of six things to do simultaneously
6. **Never regenerate existing artifacts** — only fill gaps in what exists;
   do not rewrite GDDs, ADRs, or stories that already have content
1. **静默读取**——在呈现任何内容之前完成完整审计
2. **先展示摘要**——让用户在询问是否写入之前看到范围
3. **写入前询问**——在创建采纳计划文件之前始终确认
4. **提供，而非强加**——计划是建议性的；由用户决定修复什么以及何时修复
5. **一次一个行动**——移交计划后，提供一个具体的下一步，而不是同时要做六件事的清单
6. **绝不重新生成现有产物**——只填补现有内容中的缺口；不要重写已有内容的 GDD、ADR 或故事
