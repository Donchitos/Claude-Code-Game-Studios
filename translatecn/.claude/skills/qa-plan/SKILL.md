---
name: qa-plan
description: "QA test plan for a sprint — classifies stories by Logic/Integration/Visual/UI, covers automated tests, manual cases, smoke scope."
argument-hint: "[sprint | feature: system-name | story: path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/qa-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: qa-plan
description: "冲刺的 QA 测试计划——按 Logic/Integration/Visual/UI 分类故事，涵盖自动化测试、手动用例、冒烟范围。"
argument-hint: "[sprint | feature: system-name | story: path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/qa-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

已在上方解析——按原样使用。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。


# QA Plan
# QA 计划

This skill generates a structured QA plan for a sprint, feature, or individual
story. It reads all in-scope story files and their referenced GDDs, classifies
each story by test type, and produces a plan that tells developers exactly what
to automate, what to verify manually, what the smoke test scope is, and when
to bring in a playtester.

本技能为冲刺、功能或单个故事生成结构化 QA 计划。它读取所有范围内故事文件及其引用的 GDD，按测试类型分类每个故事，并产出计划，准确告诉开发者要自动化什么、手动验证什么、冒烟测试范围是什么，以及何时引入试玩者。

Run this before a sprint begins so the team knows upfront what testing work
is required. A test plan written after implementation is a post-mortem, not a
plan.

在冲刺开始前运行此技能，让团队提前了解需要哪些测试工作。实现之后才写的测试计划是事后剖析，而不是计划。

**Output:** `production/qa/qa-plan-[sprint-slug]-[date].md`

**输出：** `production/qa/qa-plan-[sprint-slug]-[date].md`

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`（协作模式总是询问 · 引导模式仅重大问题 · 自主模式记录并继续；`automation_always_ask` 类别总是提示）。

**Workflow tier**: resolve per the GDD's system as each is read (per
`.claude/docs/workflow-modes.md`): `workflow_overrides.system_overrides.<system>`
if the block lists one, else the project value. It sets how many GDD sections
the test plan is mined from — see Phase 2.

**工作流层级**：在读取每个 GDD 时按其系统解析（依据 `.claude/docs/workflow-modes.md`）：如果该块列出了 `workflow_overrides.system_overrides.<system>` 则用它，否则用项目值。它设定测试计划从多少个 GDD 章节中挖掘——见阶段 2。

**`qa.level`**: at `minimal`, produce only a minimal smoke
plan — drop the automated-test-required rows and the test-file DoD; at `standard`,
a full plan per story type; at `full`, also add per-system coverage targets.
Distinct axis from `workflow` (which sets how many GDD sections are mined).
No level drops the Visual/Feel and UI screenshot rows — tests are waived at
`minimal`, the look is not (`.claude/docs/coding-standards.md`).

**`qa.level`**：在 `minimal` 下，仅产出最小冒烟计划——去掉需要自动化测试的行和测试文件 DoD；在 `standard` 下，按故事类型产出完整计划；在 `full` 下，还添加逐系统覆盖目标。与 `workflow` 是不同轴线（后者设定挖掘多少个 GDD 章节）。没有任何层级会去掉 Visual/Feel 和 UI 截图行——测试在 `minimal` 下被豁免，外观则不是（`.claude/docs/coding-standards.md`）。

## Phase 1: Parse Scope
## 阶段 1：解析范围

**Argument:** `$ARGUMENTS` (blank = ask user via AskUserQuestion)

**参数：** `$ARGUMENTS`（空白 = 通过 AskUserQuestion 询问用户）

Determine scope from the argument:

根据参数确定范围：

- **`sprint`** — read the most recent file in `production/sprints/`, extract
  every story file path referenced. If `production/sprint-status.yaml` exists,
  use it as the primary story list and fall back to the sprint plan for story
  metadata.
- **`feature: [system-name]`** — glob `production/epics/*/story-*.md`, filter
  to stories whose file path or title contains the system name. Also check the
  epic index file (`EPIC.md`) in that system's directory.
- **`story: [path]`** — validate that the path exists and load that single file.
- **No argument** — use `AskUserQuestion`:
  - "What is the scope for this QA plan?"
  - Options: "Current sprint", "Specific feature (enter system name)",
    "Specific story (enter path)", "Full epic"

- **`sprint`**——读取 `production/sprints/` 中最近的文件，提取引用的每个故事文件路径。如果 `production/sprint-status.yaml` 存在，将其用作主要故事列表，并回退到冲刺计划获取故事元数据。
- **`feature: [system-name]`**——glob `production/epics/*/story-*.md`，筛选文件路径或标题包含系统名的故事。同时检查该系统目录中的史诗索引文件（`EPIC.md`）。
- **`story: [path]`**——验证路径存在并加载该单个文件。
- **无参数**——使用 `AskUserQuestion`：
  - “此 QA 计划的范围是什么？”
  - 选项："Current sprint"、"Specific feature (enter system name)"、"Specific story (enter path)"、"Full epic"

After resolving scope, report: "Building QA plan for [N] stories in [scope]."

在解析范围后，报告：“正在为 [scope] 中的 [N] 个故事构建 QA 计划。”

If a story file path is referenced but the file does not exist, note it as
MISSING and continue with the remaining stories. Do not fail the entire plan
for one missing file.

如果引用了故事文件路径但文件不存在，将其记为 MISSING 并继续处理剩余故事。不要因为一个缺失文件而使整个计划失败。

> **If the resolved scope contains ZERO stories, stop — do not build a plan.**
> Report `NOT ASSESSED — no stories in scope`, naming which scope was searched
> and which path was empty, and route:
> - no file in `production/sprints/` → "No sprint plan found. Run `/sprint-plan new`."
>   At `workflow: minimal` there are no sprints by design — route instead to
>   `/qa-plan feature: [epic-slug]` or `/qa-plan story: [path]`.
> - a sprint plan exists but references no stories → "Sprint plan `[path]` lists no
>   stories. Run `/create-stories [epic-slug]`."
> - `feature:`/`story:` scope matched nothing → name the glob that came back empty.
>
> **The N=0 guard is mandatory.** Without it an empty scope reports "Building QA
> plan for 0 stories" and continues into Phase 4, producing a plan document with
> empty tables — and **a QA plan for zero stories looks exactly like a completed
> QA plan.** This skill gates the hand-off to manual QA, so a false-clean here
> sends a build to QA on the strength of a plan that tested nothing.
>
> The rule at the top of this block still stands: one missing file among several
> is MISSING-and-continue. This is the different case where there is no *several*.

> **如果解析出的范围包含零个故事，停止——不要构建计划。** 报告 `NOT ASSESSED — no stories in scope`，指出搜索了哪个范围、哪条路径为空，并路由：
> - `production/sprints/` 中没有文件 → “未找到冲刺计划。运行 `/sprint-plan new`。”在 `workflow: minimal` 下按设计没有冲刺——改为路由到 `/qa-plan feature: [epic-slug]` 或 `/qa-plan story: [path]`。
> - 冲刺计划存在但未引用任何故事 → “冲刺计划 `[path]` 未列出故事。运行 `/create-stories [epic-slug]`。”
> - `feature:`/`story:` 范围无匹配 → 指出返回为空的 glob。
>
> **N=0 防护是强制性的。** 没有它，空范围会报告“正在为 0 个故事构建 QA 计划”并继续进入阶段 4，产出一个带空表格的计划文档——而**零个故事的 QA 计划看起来与已完成的 QA 计划一模一样。** 本技能为交接给手动 QA 设门禁，因此此处的虚假干净会基于一份什么都没测试的计划，将构建送去 QA。
>
> 本块顶部的规则仍然成立：数个文件中的一个缺失是 MISSING 并继续。这是不同的情况，即不存在*数个*。

---

## Phase 2: Load Inputs
## 阶段 2：加载输入

Establish the denominator first — glob the in-scope story files and count **N** —
then collect the fields below with **targeted section greps, not a full read of
each story**. A QA plan needs each story's type and acceptance criteria; it does
not need its implementation notes, out-of-scope boundaries or ADR rationale, and
reading N stories whole to reach two sections is where this phase's cost lives:

先确立分母——glob 范围内的故事文件并计数 **N**——然后用**定向章节 grep 而非完整读取每个故事**来收集下方字段。QA 计划需要每个故事的类型和验收标准；它不需要其实现说明、范围边界或 ADR 理由，而为到达两个章节而完整读取 N 个故事，正是此阶段成本所在：

```
Grep pattern="^## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
Grep pattern="^> \*\*(Type|Status|Estimate)\*\*" glob="production/epics/**/story-*.md" output_mode="content"
Grep pattern="^## (Context|Dependencies)" glob="production/epics/**/story-*.md" output_mode="content" -A 8
```

(Scope the globs to the sprint plan's story paths in `sprint` mode.) From those:

（在 `sprint` 模式下将 glob 范围限定到冲刺计划的故事路径。）从这些中：

- **Story title** and story ID — from the file name and path; no read at all
- **Story Type** field — from the header grep (e.g., `Type: Logic`)
- **Acceptance criteria** — the complete numbered/bulleted list, from the first grep
- **GDD / ADR reference** and **Dependencies** — from the `## Context` grep
- **Estimate** — from the header grep if present
- **Implementation files** and **Engine notes** — only needed for stories whose
  test plan actually turns on them; full-read those individual stories

- **故事标题**和故事 ID——来自文件名和路径；完全无需读取
- **Story Type** 字段——来自头部 grep（例如 `Type: Logic`）
- **验收标准**——完整的编号/项目符号列表，来自第一个 grep
- **GDD / ADR 引用**和**依赖**——来自 `## Context` grep
- **估算**——来自头部 grep（如存在）
- **实现文件**和**引擎说明**——仅对测试计划实际依赖它们的故事才需要；完整读取那些单个故事

**Never treat an absent section as an absent story.** If a story matched no
`## Acceptance Criteria`, full-read that one and say so — a story with no
testable criteria is a QA finding in its own right, not a story to skip.

**绝不要将缺失章节视为缺失故事。** 如果某个故事未匹配 `## Acceptance Criteria`，完整读取那一个并说明——一个没有可测试标准的故事本身就是一项 QA 发现，而不是要跳过的故事。

After reading stories, load supporting context once (not per story):

读取故事后，一次性加载支持性上下文（不是每个故事一次）：

- `design/gdd/systems-index.md` — to understand system priorities and which
  GDDs are approved
- For each unique GDD referenced across all stories: mine test material per that
  system's workflow tier (resolved above) — at `full`, mine all 8 sections; at
  `standard`, mine the test-relevant subset of the required sections
  (**Acceptance Criteria** and **Edge Cases** always, plus **Formulas** for any
  system that defines numeric rules); at `minimal`, **Acceptance
  Criteria only**. Do not load the full GDD
  text. Find the section headings with the Grep tool (pattern `^#`, content mode) and Read
  those ranges with offset and limit. These sections contain the testable requirements, the math
  to verify, and the boundary conditions tests must cover. If an Edge Cases section is absent (or
  not expected at minimal), note per GDD: "No Edge Cases section found — edge case
  coverage will be inferred from acceptance criteria only."
- `docs/architecture/control-manifest.md` — scan for forbidden patterns that
  automated tests should guard against (if the file exists)

- `design/gdd/systems-index.md`——了解系统优先级以及哪些 GDD 已批准
- 对于所有故事中引用的每个唯一 GDD：按该系统的的工作流层级（上方已解析）挖掘测试材料——在 `full` 下挖掘全部 8 个章节；在 `standard` 下挖掘必需章节中与测试相关的子集（**Acceptance Criteria** 和 **Edge Cases** 总是包含，加上任何定义数值规则系统的 **Formulas**）；在 `minimal` 下**仅 Acceptance Criteria**。不要加载完整 GDD 文本。用 Grep 工具（模式 `^#`，内容模式）查找章节标题，并用 offset 和 limit 读取那些范围。这些章节包含可测试需求、要验证的数学以及测试必须覆盖的边界条件。如果缺少 Edge Cases 章节（或在 minimal 下预期没有），按 GDD 注明：“未找到 Edge Cases 章节——边缘情况覆盖将仅从验收标准推断。”
- `docs/architecture/control-manifest.md`——扫描自动化测试应防范的禁止模式（如果文件存在）

If no GDD is referenced in a story, note it as a gap but do not block the plan.
The story will be classified using acceptance criteria alone.

如果故事中未引用任何 GDD，将其记为缺口但不要阻塞计划。该故事将仅使用验收标准分类。

---

## Phase 3: Classify Each Story
## 阶段 3：分类每个故事

For each story, assign a Story Type:

对于每个故事，分配 Story Type：

- **If the story already has a `Type:` field in its header**: accept it as-is. Do NOT re-classify or validate against the criteria below — the Type was set by lead-programmer at story creation and is authoritative. Record it as-is.
- **If the `Type:` field is missing**: infer the type from the acceptance criteria using the table below, and note in the report that the type was inferred (not declared). Flag this as a gap — the story should have its Type declared explicitly before implementation begins.

- **如果故事头部已有 `Type:` 字段**：按原样接受。不要重新分类或对照下方标准验证——Type 由 lead-programmer 在创建故事时设定，具有权威性。按原样记录。
- **如果缺少 `Type:` 字段**：使用下表从验收标准推断类型，并在报告中注明类型是推断的（而非声明的）。将此标记为缺口——故事应在实现开始前显式声明其 Type。

| Story Type | Classification Indicators |
|---|---|
| **Logic** | Acceptance criteria reference calculations, formulas, numerical thresholds, state transitions, AI decisions, data validation, buff/debuff stacking, economy transactions, or any testable computation |
| **Integration** | Criteria involve two or more systems interacting, signals or events propagating across system boundaries, save/load round-trips, network sync, or persistence |
| **Visual/Feel** | Criteria reference animation behaviour, VFX, shader output, "feels responsive", perceived timing, screen shake, particle effects, audio sync, or visual feedback quality |
| **UI** | Criteria reference menus, HUD elements, buttons, screens, dialogue boxes, inventory panels, tooltips, or any player-facing interface element |
| **Config/Data** | Changes are limited to balance tuning values, data files, or configuration — no new code logic is involved |

| 故事类型 | 分类指标 |
|---|---|
| **Logic** | 验收标准涉及计算、公式、数值阈值、状态转换、AI 决策、数据验证、增益/减益叠加、经济交易，或任何可测试的计算 |
| **Integration** | 标准涉及两个或更多系统交互、信号或事件跨系统边界传播、存/读档往返、网络同步或持久化 |
| **Visual/Feel** | 标准涉及动画行为、VFX、着色器输出、"feels responsive"、感知时机、屏幕震动、粒子效果、音频同步或视觉反馈质量 |
| **UI** | 标准涉及菜单、HUD 元素、按钮、屏幕、对话框、物品栏面板、提示框，或任何面向玩家的界面元素 |
| **Config/Data** | 更改仅限于平衡调优值、数据文件或配置——不涉及新代码逻辑 |

**Mixed stories** (e.g., a story that adds both a formula and a UI display):
assign the primary type based on which acceptance criteria carry the highest
implementation risk, and note the secondary type. Mixed Logic+Integration or
Visual+UI combinations are the most common.

**混合故事**（例如，同时添加公式和 UI 显示的故事）：根据哪些验收标准承载最高实现风险来分配主要类型，并注明次要类型。混合 Logic+Integration 或 Visual+UI 组合最常见。

After classifying all stories, produce a classification summary table in
conversation before proceeding to Phase 4. This gives the user visibility into
how tests will be allocated.

在分类所有故事后，在进入阶段 4 之前于对话中产出一份分类摘要表。这使用户能了解测试将如何分配。

---

## Phase 4: Generate Test Plan
## 阶段 4：生成测试计划

Assemble the full QA plan document. Use this structure:

组装完整 QA 计划文档。使用此结构：

````markdown
# QA Plan: [Sprint/Feature Name]
**Date**: [date]
**Generated by**: /qa-plan
**Scope**: [N stories across [N systems]]
**Engine**: [engine name — `engine.name` from project.yaml if present and non-empty, else the Engine field from .claude/docs/technical-preferences.md, else "Not configured"]
**Sprint File**: [path to sprint plan if applicable]

---

## Test Summary

| Story | Type | Automated Test Required | Manual Verification Required |
|-------|------|------------------------|------------------------------|
| [story title] | Logic | Unit test — `tests/unit/[system]/` | None |
| [story title] | Integration | Integration test — `tests/integration/[system]/` | Smoke check |
| [story title] | Visual/Feel | None (not automatable) | Screenshot + lead sign-off |
| [story title] | UI | None (verified by its screenshots) | Retained screenshot of each screen touched |
| [story title] | Config/Data | Data validation test | Spot-check in-game values |

---

## Automated Tests Required

*(At `qa.level: minimal`, omit this entire section and blank the Test Summary's
"Automated Test Required" column — automated tests are not required there; list
manual/smoke verification only.)*

### [Story Title] — [Type]
**Test file path**: `tests/[unit|integration]/[system]/[story-slug]_test.[ext]`
**What to test**:
- [Specific formula or rule from the GDD Formulas section]
- [Each named state transition or decision branch]
- [Each side effect that should or should not occur]

**Edge cases to cover**:
- Zero/minimum input values (e.g., 0 damage, empty inventory)
- Maximum/boundary input values (e.g., max level, stat cap)
- Invalid or null input (e.g., missing target, dead entity)
- [Any edge case explicitly called out in the GDD Edge Cases section]

**Estimated test count**: ~[N] unit tests

[If no GDD formula reference was found for this story, note:]
*No formula found in referenced GDD — test cases must be derived from acceptance
criteria directly. Review the GDD Formulas section before writing tests.*

---

## Manual QA Checklist

### [Story Title] — [Type]
**Verification method**: [Screenshot + designer sign-off | Playtest session |
Manual step-through | Comparison against reference footage]
**Who must sign off**: [designer / lead-programmer / qa-lead / art-director]
**Evidence to capture**: [screenshot of X | video clip of Y | written playtest
notes | side-by-side comparison]

Checklist:
- [ ] [Specific observable condition — concrete and falsifiable]
- [ ] [Another condition]
- [ ] [Every acceptance criterion translated into a manual check item]

*If any criterion uses subjective language ("feels", "looks", "seems"), it must
be supplemented with a specific benchmark or a playtest protocol note.*

---

## Smoke Test Scope

Critical paths to verify before any QA hand-off for this sprint:

1. Game launches to main menu without crash
2. New game / new session can be started
3. [Primary mechanic introduced or changed this sprint]
4. [Any system with a regression risk from this sprint's changes]
5. Save / load cycle completes without data loss (if save system exists)
6. Performance is within budget on target hardware (no new frame spikes)

*Smoke tests are verified by the developer via `/smoke-check`. Reference this
list when running that skill.*

---

## Playtest Requirements

| Story | Playtest Goal | Min Sessions | Target Player Type |
|-------|--------------|--------------|-------------------|
| [story] | [What question must the session answer?] | [N] | [new player / experienced] |

**Sign-off requirement**: Playtest notes must be written with `/playtest-report` to
`production/qa/playtests/` (naming the story) and reviewed by
the [designer / qa-lead] before the story can be marked COMPLETE.

If no stories require playtest validation: *No playtest sessions required for
this sprint.*

---

## Definition of Done — This Sprint

A story is DONE when ALL of the following are true (at `qa.level: minimal`, drop
the test-file and smoke rows below — tests are waived there; the screenshot and
sign-off rows stay at every level, because the look is not):

- [ ] All acceptance criteria verified — via automated test result OR documented
      manual evidence (screenshot, video, or playtest notes with sign-off)
- [ ] Test file exists at the specified path for all Logic and Integration stories *(qa.level standard/full)*
- [ ] Retained screenshot of each screen touched, in `production/qa/evidence/`, for all Visual/Feel and UI stories *(every qa.level)*
- [ ] Signed-off evidence doc at `production/qa/evidence/[story-slug]-evidence.md` for all Visual/Feel stories *(every qa.level)*
- [ ] Smoke check passes (run `/smoke-check sprint` before QA hand-off) *(qa.level standard/full)*
- [ ] No regressions introduced
- [ ] Code reviewed (via `/code-review` or documented peer review)
- [ ] Story file updated to `Status: Complete` (via `/story-done`)
````

````markdown
# QA 计划：[Sprint/Feature Name]
**日期**：[date]
**生成者**：/qa-plan
**范围**：[N stories across [N systems]]
**引擎**：[engine name — `engine.name` from project.yaml if present and non-empty, else the Engine field from .claude/docs/technical-preferences.md, else "Not configured"]
**冲刺文件**：[path to sprint plan if applicable]

---

## 测试摘要

| 故事 | 类型 | 需要自动化测试 | 需要手动验证 |
|-------|------|------------------------|------------------------------|
| [story title] | Logic | Unit test — `tests/unit/[system]/` | None |
| [story title] | Integration | Integration test — `tests/integration/[system]/` | Smoke check |
| [story title] | Visual/Feel | None (not automatable) | Screenshot + lead sign-off |
| [story title] | UI | None (verified by its screenshots) | Retained screenshot of each screen touched |
| [story title] | Config/Data | Data validation test | Spot-check in-game values |

---

## 需要的自动化测试

*(在 `qa.level: minimal` 下，省略整个此章节并将测试摘要的 "Automated Test Required" 列留空——那里不要求自动化测试；仅列出手动/冒烟验证。)*

### [Story Title] — [Type]
**测试文件路径**：`tests/[unit|integration]/[system]/[story-slug]_test.[ext]`
**测试内容**：
- [Specific formula or rule from the GDD Formulas section]
- [Each named state transition or decision branch]
- [Each side effect that should or should not occur]

**要覆盖的边缘情况**：
- 零/最小输入值（例如 0 伤害、空物品栏）
- 最大/边界输入值（例如最高等级、属性上限）
- 无效或空输入（例如缺失目标、死亡实体）
- [Any edge case explicitly called out in the GDD Edge Cases section]

**估计测试数量**：约 [N] 个单元测试

[如果此故事未找到 GDD 公式引用，注明：]
*在引用的 GDD 中未找到公式——测试用例必须直接从验收标准推导。在编写测试前评审 GDD Formulas 章节。*

---

## 手动 QA 检查清单

### [Story Title] — [Type]
**验证方法**：[Screenshot + designer sign-off | Playtest session | Manual step-through | Comparison against reference footage]
**谁必须签核**：[designer / lead-programmer / qa-lead / art-director]
**要捕获的证据**：[screenshot of X | video clip of Y | written playtest notes | side-by-side comparison]

检查清单：
- [ ] [Specific observable condition — concrete and falsifiable]
- [ ] [Another condition]
- [ ] [Every acceptance criterion translated into a manual check item]

*如果任何标准使用主观语言（"feels"、"looks"、"seems"），必须补充具体基准或试玩协议说明。*

---

## 冒烟测试范围

在本冲刺任何 QA 交接前要验证的关键路径：

1. 游戏启动到主菜单不崩溃
2. 新游戏 / 新会话可以开始
3. [本冲刺引入或更改的主要机制]
4. [因本冲刺更改而有回归风险的任何系统]
5. 存 / 读档循环完成且无数据丢失（如果存在存档系统）
6. 在目标硬件上性能在预算内（没有新的帧尖峰）

*冒烟测试由开发者通过 `/smoke-check` 验证。运行该技能时参考此列表。*

---

## 试玩要求

| 故事 | 试玩目标 | 最少场次 | 目标玩家类型 |
|-------|--------------|--------------|-------------------|
| [story] | [What question must the session answer?] | [N] | [new player / experienced] |

**签核要求**：试玩笔记必须通过 `/playtest-report` 写入 `production/qa/playtests/`（命名该故事），并由 [designer / qa-lead] 评审后故事才能标记为 COMPLETE。

如果没有任何故事需要试玩验证：*本冲刺不需要试玩场次。*

---

## 完成定义——本冲刺

当以下全部为真时，故事才算 DONE（在 `qa.level: minimal` 下，去掉下方的测试文件和冒烟行——测试在那里被豁免；截图和签核行在每个层级都保留，因为外观不是可豁免的）：

- [ ] 所有验收标准已验证——通过自动化测试结果或记录在案的手动证据（截图、视频或带签核的试玩笔记）
- [ ] 所有 Logic 和 Integration 故事的测试文件存在于指定路径 *(qa.level standard/full)*
- [ ] 所有 Visual/Feel 和 UI 故事在 `production/qa/evidence/` 中保留每个触及屏幕的截图 *(every qa.level)*
- [ ] 所有 Visual/Feel 故事在 `production/qa/evidence/[story-slug]-evidence.md` 有已签核证据文档 *(every qa.level)*
- [ ] 冒烟检查通过（在 QA 交接前运行 `/smoke-check sprint`）*(qa.level standard/full)*
- [ ] 未引入回归
- [ ] 代码已评审（通过 `/code-review` 或记录在案的同行评审）
- [ ] 故事文件更新为 `Status: Complete`（通过 `/story-done`）
````

When generating content, use the actual story titles, GDD formula text, and
acceptance criteria extracted in Phase 2. Do not use placeholder text — every
test entry should reflect the real requirements of these specific stories.

生成内容时，使用阶段 2 提取的真实故事标题、GDD 公式文本和验收标准。不要使用占位文本——每个测试条目都应反映这些具体故事的真实需求。

---

## Phase 5: Write Output
## 阶段 5：写入输出

Show the complete plan in conversation (or a summary if the plan is very long),
then ask two questions together using `AskUserQuestion`:

在对话中展示完整计划（如果计划非常长则展示摘要），然后使用 `AskUserQuestion` 一起询问两个问题：

```
question: "Ready to write the QA plan. Choose output options:"
multiSelect: true
options:
  - "Write QA plan to production/qa/qa-plan-[sprint-slug]-[date].md"
  - "Also back-fill test case specs into each story file's ## QA Test Cases section (Recommended — enables /dev-story and /code-review traceability)"
```

If "Write QA plan" is selected: write the plan file exactly as generated — do not truncate.

如果选择 "Write QA plan"：完全按生成内容写入计划文件——不要截断。

If "Also back-fill story files" is selected: for each Logic and Integration story in scope, edit the story file at its path. Find the `## QA Test Cases` section and replace its content with the test case specs generated in Phase 4 for that story. If a story has no `## QA Test Cases` section, append it before `## Test Evidence`. For Visual/Feel and UI stories, write the manual verification steps instead of test specs.

如果选择 "Also back-fill story files"：对于范围内每个 Logic 和 Integration 故事，编辑其路径处的故事文件。找到 `## QA Test Cases` 章节，并用阶段 4 为该故事生成的测试用例规格替换其内容。如果故事没有 `## QA Test Cases` 章节，在 `## Test Evidence` 之前追加它。对于 Visual/Feel 和 UI 故事，写入手动验证步骤而不是测试规格。

After writing:

写入后：

"QA plan written to `production/qa/qa-plan-[sprint-slug]-[date].md`.

"QA 计划已写入 `production/qa/qa-plan-[sprint-slug]-[date].md`。

Next steps:
- Share this plan with the team before sprint implementation begins
- Once all sprint stories are implemented, run `/smoke-check sprint` to gate QA hand-off — not yet, only after implementation is complete
- For Logic/Integration stories, create the test files at the listed paths
  before marking stories done — `/story-done` checks for them"

后续步骤：
- 在冲刺实现开始前与团队分享此计划
- 一旦所有冲刺故事实现完毕，运行 `/smoke-check sprint` 为 QA 交接设门禁——不是现在，只在实现完成之后
- 对于 Logic/Integration 故事，在标记故事完成前在所列路径创建测试文件——`/story-done` 会检查它们

Silently append to `production/session-state/active.md` (create the file if it does not exist):

静默追加到 `production/session-state/active.md`（如果文件不存在则创建它）：

```
<!-- QA-PLAN: [date] | System: [system/sprint identifier] | Plan written: production/qa/qa-plan-[identifier]-[date].md -->
```

Close with the verdict: **COMPLETE** — QA plan written (or **COMPLETE** — QA plan
shown, not written, if the write was declined). The only other outcome is the
`NOT ASSESSED — no stories in scope` path in Phase 1.

以结论结束：**COMPLETE**——QA 计划已写入（或如果拒绝写入，则为 **COMPLETE**——QA 计划已展示但未写入）。唯一其他结果是阶段 1 中的 `NOT ASSESSED — no stories in scope` 路径。

---

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

**适用于 `collaborative` 模式（默认）。** 对于 `guided` 和 `autonomous` 模式，参见 `.claude/docs/automation-modes.md`——以下规则描述协作模式的要求，而非通用行为。

- **Never write the plan without asking** — Phase 5 requires explicit approval.
- **Classify conservatively**: when a story is ambiguous between Logic and
  Integration, classify it as Integration — it requires both unit and
  integration tests.
- **Do not invent test cases** beyond what acceptance criteria and GDD formulas
  support. If a formula is absent from the GDD, flag it rather than guessing.
- **Playtest requirements are advisory**: the user decides whether a playtest
  is warranted for borderline Visual/Feel stories. Flag the case; do not mandate.
- Use `AskUserQuestion` for scope selection when no argument is provided.
  Keep all other phases non-interactive — present findings, then ask once to
  approve the write.

- **绝不在未询问的情况下写入计划**——阶段 5 需要明确批准。
- **保守分类**：当故事在 Logic 和 Integration 之间有歧义时，将其分类为 Integration——它同时需要单元测试和集成测试。
- **不要编造测试用例**超出验收标准和 GDD 公式支持的范围。如果 GDD 中缺少公式，标记它而不是猜测。
- **试玩要求是建议性的**：用户决定是否有必要对边缘 Visual/Feel 故事进行试玩。标记该情况；不要强制。
- 当未提供参数时，使用 `AskUserQuestion` 选择范围。保持所有其他阶段非交互——呈现发现，然后询问一次以批准写入。
