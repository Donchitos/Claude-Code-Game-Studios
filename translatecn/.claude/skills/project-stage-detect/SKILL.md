---
name: project-stage-detect
description: "Analyze project state, detect stage, identify gaps, recommend next steps. 'Where are we in development?'"
argument-hint: "[optional: role filter like 'programmer' or 'designer']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh), Bash(bash ".claude/scripts/artifact-check.sh"), Bash(bash ./.claude/scripts/artifact-check.sh), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *)
model: haiku
# Read-only diagnostic skill — no specialist agent delegation needed
---

---
name: project-stage-detect
description: "分析项目状态，检测所处阶段，识别缺口，推荐下一步。'我们在开发中处于什么位置？'"
argument-hint: "[optional: role filter like 'programmer' or 'designer']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh), Bash(bash ".claude/scripts/artifact-check.sh"), Bash(bash ./.claude/scripts/artifact-check.sh), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *)
model: haiku
# 只读诊断技能 —— 无需委派给专家智能体
---

# Project Stage Detection

This skill scans your project to determine its current development stage, completeness
of artifacts, and gaps that need attention. It's especially useful when:
- Starting with an existing project
- Onboarding to a codebase
- Checking what's missing before a milestone
- Understanding "where are we?"

# 项目阶段检测

本技能会扫描你的项目，判断其当前所处的开发阶段、资产（artifact）的完整度，以及需要关注的缺口。它特别适用于以下情形：
- 从已有项目开始
- 熟悉（onboarding）一个代码库
- 在里程碑前检查缺少什么
- 弄清"我们到哪一步了？"

---

## Workflow

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

> **Resolve the tier — do not assume it.** The tier decides what counts as a gap
> at all: at `full` every missing doc is one; at `minimal` none of them are,
> because a brief plus an engine is the normal state and code is the expected
> next step. Guessing high tells a jam project it is missing GDDs, an art bible
> and ADRs — the exact "process feels mismatched to my project" experience
> `modes.rigor` exists to prevent.

**`workflow`** (per `.claude/docs/workflow-modes.md`). The tier governs
which absent documents count as gaps (step 3) — below `full`, optional docs are
not flagged.

## 工作流

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次写文件都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重大事项询问 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

已在上面解析 —— 直接使用。无配置块 → 采用
`.claude/docs/config-resolution.md` 中的默认值。

> **解析档位 —— 不要臆断。** 档位决定了什么才算缺口：
> 在 `full` 下，每份缺失文档都算一个；在 `minimal` 下，它们都不算，
> 因为一份简报加上一个引擎就是正常状态，代码才是预期的下一步。
> 往高里猜会让一个 game jam 项目被告知它缺少 GDD、美术圣经（art bible）
> 和 ADR —— 正是 `modes.rigor` 要避免的那种"流程和我的项目不匹配"的体验。

**`workflow`**（依据 `.claude/docs/workflow-modes.md`）。该档位决定
哪些缺失文档算作缺口（第 3 步）—— 低于 `full` 时，可选文档不会被标记。

### 1. Scan Key Directories

**Start with the deterministic pass — it answers "what exists" for every
catalogued artifact in one call:**

```
Bash: bash .claude/scripts/artifact-check.sh
```

Run it exactly as written — from the project root, relative path, no
arguments, no `cd`, no `2>&1`. This skill's permission grant matches that form;
any other asks the user to approve it.

With no `--phase` it reports every phase, so a single call covers the whole
project: per step, `PRESENT` / `ABSENT` / `SHORT` (with `count=` and `min=`) /
`PATTERN_MISS` / `NO_CHECK`. Use it instead of hand-globbing each artifact
below, and treat its `NO_CHECK` total as the honest bound on what existence
checks can tell you.

It reports observations only — this skill still decides what stage those
observations imply, and the tier still governs which absences are gaps at all
(see the workflow-tier note below).

Then analyze what the script cannot: content quality, counts it does not
track, and the judgement calls.

**Design Documentation** (`design/`):
- Count GDD files in `design/gdd/*.md`
- Check for game-concept.md (or `design/game-brief.md` at `minimal`), game-pillars.md, systems-index.md
- If systems-index.md exists, count total systems vs. designed systems
- Analyze completeness (Overview, Detailed Design, Edge Cases, etc.). Read GDDs
  by section: find the headings you need with the Grep tool (pattern `^#`, content
  mode) and Read those ranges with offset and limit.
- Count narrative docs in `design/narrative/`
- Count level designs in `design/levels/`

**Source Code** (the code root — `src/` Godot, `Assets/` Unity, `Source/` Unreal; resolve per `.claude/docs/code-root-resolution.md`):
- Count source files (language-agnostic)
- Identify major systems (directories with 5+ files)
- Check for core/, gameplay/, ai/, networking/, ui/ directories
- Estimate lines of code (rough scale)
- An unresolved root means none of these ran: report
  `NOT ASSESSED — code root unresolved`, never zero source files — zero files
  reads as a greenfield project, and the source-file rows of the stage table
  cannot be decided without the count

**Production Artifacts** (`production/`):
- Check for active sprint plans. At `workflow: minimal` there are no sprints:
  read the story files' progress through the brief's build order instead, and
  never report a missing sprint plan, milestone or roadmap as a gap
- Look for milestone definitions
- Find roadmap documents

**Prototypes** (`prototypes/`):
- Count prototype directories
- Check for READMEs (documented vs undocumented)
- Assess if prototypes are archived or active

**Architecture Docs** (`docs/architecture/`):
- Count ADRs (Architecture Decision Records)
- Check for overview/index documents

**Tests** (`tests/`):
- Count test files
- Estimate test coverage (rough heuristic)

### 1. 扫描关键目录

**从确定性的一轮检查开始 —— 它一次调用就能回答每个已编目资产"是否存在"：**

```
Bash: bash .claude/scripts/artifact-check.sh
```

完全按原样运行它 —— 从项目根目录、相对路径、不带
参数、不用 `cd`、不用 `2>&1`。本技能的权限授权匹配这种形式；
任何其他形式都会要求用户批准。

不带 `--phase` 时它会报告每个阶段，因此一次调用就覆盖整个
项目：按步骤给出 `PRESENT` / `ABSENT` / `SHORT`（含 `count=` 和 `min=`）/
`PATTERN_MISS` / `NO_CHECK`。用它来替代下面逐个手动 glob 每个资产，
并把它的 `NO_CHECK` 总数当作"存在性检查能告诉你什么"的诚实上限。

它只报告观察结果 —— 这些观察意味着什么阶段仍由本技能判断，
而档位仍决定哪些缺失才算缺口（见下面的工作流档位说明）。

然后分析脚本做不到的事：内容质量、它不追踪的数量，
以及需要判断的取舍。

**设计文档**（`design/`）：
- 统计 `design/gdd/*.md` 中的 GDD 文件数
- 检查 game-concept.md（或在 `minimal` 下的 `design/game-brief.md`）、game-pillars.md、systems-index.md
- 如果 systems-index.md 存在，统计系统总数与已设计系统的数量
- 分析完整度（概述（Overview）、详细设计（Detailed Design）、边界情况（Edge Cases）等）。按节读 GDD：
  用 Grep 工具（pattern `^#`，content 模式）找到你需要的标题，
  再用 offset 和 limit 读取那些范围。
- 统计 `design/narrative/` 中的叙事文档
- 统计 `design/levels/` 中的关卡设计

**源代码**（代码根目录 —— `src/` Godot、`Assets/` Unity、`Source/` Unreal；按 `.claude/docs/code-root-resolution.md` 解析）：
- 统计源文件（语言无关）
- 识别主要系统（含 5 个以上文件的目录）
- 检查 core/、gameplay/、ai/、networking/、ui/ 目录
- 估算代码行数（粗略规模）
- 代码根目录未解析意味着以上都没运行：报告
  `NOT ASSESSED — code root unresolved`，绝不能报零个源文件 —— 零文件
  会被读成全新项目，而阶段表的源文件行
  没有这个计数就无法判定

**制作资产**（`production/`）：
- 检查是否有进行中的冲刺（sprint）计划。在 `workflow: minimal` 下没有冲刺：
  改为通过简报的构建顺序读取故事文件的进度，并且
  绝不把缺失的冲刺计划、里程碑或路线图报告为缺口
- 查找里程碑定义
- 查找路线图文档

**原型**（`prototypes/`）：
- 统计原型目录
- 检查是否有 README（有文档 vs 无文档）
- 评估原型是已归档还是活跃

**架构文档**（`docs/architecture/`）：
- 统计 ADR（架构决策记录（Architecture Decision Records））
- 检查是否有概述/索引文档

**测试**（`tests/`）：
- 统计测试文件
- 估算测试覆盖率（粗略启发式）

### 2. Classify Project Stage

Based on scanned artifacts, determine stage. Check `project.stage` in `project.yaml` first (if present); else `production/stage.txt` (legacy fallback) — either is an explicit override from `/gate-check`. Otherwise, auto-detect using these heuristics (check from most-advanced backward):

> **Always run the heuristics, even when a stage is configured — then COMPARE.**
> The configured value is authoritative for what the stage *is*; it is not
> evidence that the artifacts support it. Report both, and when they disagree say
> so explicitly:
>
> > "Configured stage: **Release**. Observed artifacts indicate
> > **Pre-Production** (2 source files, 0 ADRs, no architecture doc, no epics).
> > These disagree — the configured stage may be stale, or work exists outside
> > this repo."
>
> Reading config and reporting it back is not detection. This skill's own
> description promises "analyze project state, detect stage", and a stage
> detector that cannot contradict its input is the one thing it must never be —
> it would report `Release` for a project whose artifacts match its own
> Pre-Production row, four stages below, and say nothing.
>
> **A disagreement makes Stage Confidence CONCERNS** (step 4) — ambiguous
> signals by definition — however complete the artifacts are. One exception: at
> `workflow: minimal` nothing runs `/gate-check`, so the configured stage stays
> where `/start` set it. There, report the observed stage and say the configured
> one is not advanced at this tier; that lag is expected, not a disagreement.

| Stage | Indicators |
|-------|-----------|
| **Concept** | No game concept doc, brainstorming phase |
| **Systems Design** | Game concept exists, systems index missing or incomplete |
| **Technical Setup** | Systems index exists, engine not configured |
| **Pre-Production** | Engine configured, code root has <10 source files |
| **Production** | code root has 10+ source files, active development |
| **Polish** | Explicit only (set by `/gate-check` Production → Polish gate) |
| **Release** | Explicit only (set by `/gate-check` Polish → Release gate) |

### 2. 归类项目阶段

基于扫描到的资产判断阶段。先检查 `project.yaml` 中的 `project.stage`（如果存在）；否则用 `production/stage.txt`（旧版回退）—— 二者之一都是来自 `/gate-check` 的显式覆盖。否则，用以下启发式自动检测（从最进阶的阶段往回检查）：

> **即使已配置阶段，也始终运行启发式 —— 然后 COMPARE（比较）。**
> 配置值对于阶段*是什么*是权威的；它并不是
> 资产支持该阶段的证据。把两者都报告出来，当它们不一致时明确说明：
>
> > "配置阶段：**Release**。观察到的资产表明为
> > **Pre-Production**（2 个源文件，0 个 ADR，无架构文档，无史诗）。
> > 两者不一致 —— 配置的阶段可能已过时，或者有工作存在于
> > 本仓库之外。"
>
> 读取配置再回读它并不等于检测。本技能自己的
> 描述承诺"分析项目状态，检测阶段"，而一个无法反驳其输入的阶段
> 检测器正是它绝不能成为的东西 ——
> 它会对一个资产符合自己 Pre-Production 行（低了四个阶段）的项目报告 `Release`，却一言不发。
>
> **不一致会让阶段置信度（Stage Confidence）变为 CONCERNS**（第 4 步）—— 按定义就是
> 模糊信号 —— 无论资产多么完整。一个例外：在
> `workflow: minimal` 下没有东西运行 `/gate-check`，所以配置阶段仍停留在
> `/start` 设定的位置。在那里，报告观察到的阶段，并说明在该档位下配置阶段
> 不会进阶；这种滞后是预期内的，不算不一致。

| 阶段 | 指标 |
|-------|-----------|
| **Concept（概念）** | 无游戏概念文档，头脑风暴阶段 |
| **Systems Design（系统设计）** | 游戏概念存在，系统索引缺失或不完整 |
| **Technical Setup（技术搭建）** | 系统索引存在，引擎未配置 |
| **Pre-Production（预制作）** | 引擎已配置，代码根目录源文件少于 10 个 |
| **Production（制作）** | 代码根目录有 10 个以上源文件，活跃开发中 |
| **Polish（打磨）** | 仅显式（由 `/gate-check` 的 Production → Polish 门禁设定） |
| **Release（发布）** | 仅显式（由 `/gate-check` 的 Polish → Release 门禁设定） |

### 3. Collaborative Gap Identification

**Surface gaps per the resolved workflow tier:**
- **`full`** — flag every missing doc type (GDDs, art bible, UX specs, ADRs) as a gap.
- **`standard`** — flag only required docs: missing GDDs for built systems and
  missing critical (Foundation-layer) ADRs. Do NOT flag an absent art bible unless
  visual-asset stories exist, and do NOT flag non-core UX specs.
- **`minimal`** — a `design/game-brief.md` + engine present is the normal state. Do NOT flag
  absent GDDs, art bible, UX specs, ADRs, epics or sprint plans as gaps: the brief's build
  order is the plan, and the expected next step is code.

**DO NOT** just list missing files. Instead, **ask clarifying questions** (only
for gaps the tier above says to surface):

- "I see combat code (`<code root>/gameplay/combat/`) but no `design/gdd/combat-system.md`. Was this prototyped first, or should we reverse-document?"
- "You have 15 ADRs but no architecture overview. Should I create one to help new contributors?"
- (`standard`/`full` only) "I see [N] systems under `<code root>/` but no ADRs in `docs/architecture/`. Were those decisions recorded somewhere else, or should we write the critical ones with `/architecture-decision`?"
- (`standard`/`full` only) "No sprint plans in `production/`. Are you tracking work elsewhere (Jira, Trello, etc.)?"
- "I found a game concept but no systems index. Have you decomposed the concept into individual systems yet, or should we run `/map-systems`?"
- "Prototypes directory has 3 projects with no READMEs. Were these experiments, or do they need documentation?"

### 3. 协作式缺口识别

**按已解析的工作流档位呈现缺口：**
- **`full`** —— 把每一种缺失的文档类型（GDD、美术圣经、UX 规格、ADR）都标记为缺口。
- **`standard`** —— 只标记必需的文档：已构建系统缺失的 GDD，以及
  缺失的关键（Foundation 层）ADR。除非存在视觉资产故事，
  否则不要标记缺失的美术圣经，也不要标记非核心 UX 规格。
- **`minimal`** —— 存在 `design/game-brief.md` 加引擎就是正常状态。不要把
  缺失的 GDD、美术圣经、UX 规格、ADR、史诗或冲刺计划标记为缺口：简报的构建
  顺序就是计划，预期的下一步是代码。

**不要**只是罗列缺失文件。而应**提出澄清性问题**（只针对
上述档位说要呈现的缺口）：

- "我看到了战斗代码（`<code root>/gameplay/combat/`），但没有 `design/gdd/combat-system.md`。这是先做的原型，还是应该我们反向补文档？"
- "你有 15 个 ADR，但没有架构概述。要不要我创建一份来帮助新贡献者？"
- （仅 `standard`/`full`）"我在 `<code root>/` 下看到 [N] 个系统，但 `docs/architecture/` 里没有 ADR。这些决策记录在别处了吗，还是应该用 `/architecture-decision` 写下关键的那些？"
- （仅 `standard`/`full`）"`production/` 里没有冲刺计划。你在别处（Jira、Trello 等）跟踪工作吗？"
- "我找到一个游戏概念，但没有系统索引。你已经把概念拆解成一个个系统了吗，还是应该运行 `/map-systems`？"
- "原型目录里有 3 个项目没有 README。这些是实验，还是需要文档？"

### 4. Generate Stage Report

Use template: `.claude/docs/templates/project-stage-report.md`

**Report structure**:
```markdown
# Project Stage Analysis

**Date**: [date]
**Stage**: [Concept/Systems Design/Technical Setup/Pre-Production/Production/Polish/Release]
**Stage Confidence**: [PASS — clearly detected / CONCERNS — ambiguous signals / NOT ASSESSED — a check the stage depends on did not run / FAIL — critical gaps block progress]

## Completeness Overview
- Design: [X%] ([N] docs, [gaps])
- Code: [X%] ([N] files, [systems])
- Architecture: [X%] ([N] ADRs, [gaps])
- Production: [X%] ([status] — at `minimal`: stories complete in the brief's build order, never "no sprint plan")
- Tests: [X%] ([coverage estimate])

## Gaps Identified
1. [Gap description + clarifying question]
2. [Gap description + clarifying question]

## Recommended Next Steps
[Priority-ordered list based on stage and role]
```

**Stage Confidence — first match wins:** **FAIL** if critical gaps block
progress; else **CONCERNS** if the signals that were gathered are ambiguous —
they fit more than one stage, or the configured and observed stages disagree
(step 2); else **NOT ASSESSED** if a check the stage depends on did not run —
name it (an unresolved code root, two candidate roots included, leaves the
source-file count, and so the table's Production row, undecided); else
**PASS**. NOT ASSESSED outranks PASS — a stage nobody could check is not a
clearly detected one — and ranks below CONCERNS and FAIL, so a known problem is
never buried behind it.

### 4. 生成阶段报告

使用模板：`.claude/docs/templates/project-stage-report.md`

**报告结构**：
```markdown
# Project Stage Analysis

**Date**: [date]
**Stage**: [Concept/Systems Design/Technical Setup/Pre-Production/Production/Polish/Release]
**Stage Confidence**: [PASS — clearly detected / CONCERNS — ambiguous signals / NOT ASSESSED — a check the stage depends on did not run / FAIL — critical gaps block progress]

## Completeness Overview
- Design: [X%] ([N] docs, [gaps])
- Code: [X%] ([N] files, [systems])
- Architecture: [X%] ([N] ADRs, [gaps])
- Production: [X%] ([status] — at `minimal`: stories complete in the brief's build order, never "no sprint plan")
- Tests: [X%] ([coverage estimate])

## Gaps Identified
1. [Gap description + clarifying question]
2. [Gap description + clarifying question]

## Recommended Next Steps
[Priority-ordered list based on stage and role]
```

```markdown
# 项目阶段分析

**日期**：[date]
**阶段**：[Concept/Systems Design/Technical Setup/Pre-Production/Production/Polish/Release]
**阶段置信度**：[PASS —— 清晰检测到 / CONCERNS —— 信号模糊 / NOT ASSESSED —— 阶段所依赖的一项检查未运行 / FAIL —— 关键缺口阻碍进展]

## 完整度概览
- 设计：[X%]（[N] 份文档，[gaps]）
- 代码：[X%]（[N] 个文件，[systems]）
- 架构：[X%]（[N] 个 ADR，[gaps]）
- 制作：[X%]（[status] —— 在 `minimal` 下：故事已按简报的构建顺序完成，绝不说"没有冲刺计划"）
- 测试：[X%]（[coverage estimate]）

## 已识别缺口
1. [缺口描述 + 澄清问题]
2. [缺口描述 + 澄清问题]

## 推荐的下一步
[基于阶段和角色的优先级排序列表]
```

**阶段置信度 —— 首个匹配者胜出：** 若关键缺口阻碍进展，则为 **FAIL**；否则，若收集到的信号模糊 —— 它们符合不止一个阶段，或配置阶段与观察阶段不一致（第 2 步），则为 **CONCERNS**；否则，若阶段所依赖的一项检查未运行 —— 点名它（一个未解析的代码根目录，包括有两个候选根目录，会让源文件计数、进而让阶段表的 Production 行悬而未决）—— 则为 **NOT ASSESSED**；否则为 **PASS**。NOT ASSESSED 的优先级高于 PASS —— 没人能检查的阶段算不上清晰检测到的阶段 —— 且排在 CONCERNS 和 FAIL 之下，因此已知问题绝不会被它掩埋。

### 5. Role-Filtered Recommendations (Optional)

If user provided a role argument (e.g., `/project-stage-detect programmer`):

**Programmer**:
- Focus on architecture docs, test coverage, missing ADRs
- Code-to-docs gaps

**Designer**:
- Focus on GDD completeness, missing design sections
- Prototype documentation

**Producer**:
- Focus on sprint plans, milestone tracking, roadmap
- Cross-team coordination docs

**General** (no role):
- Holistic view of all gaps
- Highest-priority items across domains

### 5. 按角色过滤的推荐（可选）

如果用户提供了角色参数（例如 `/project-stage-detect programmer`）：

**Programmer（程序员）**：
- 关注架构文档、测试覆盖率、缺失的 ADR
- 代码与文档之间的缺口

**Designer（设计师）**：
- 关注 GDD 完整度、缺失的设计章节
- 原型文档

**Producer（制作人）**：
- 关注冲刺计划、里程碑跟踪、路线图
- 跨团队协作文档

**General（通用，无角色）**：
- 所有缺口的整体视图
- 跨领域最高优先级的条目

### 6. Request Approval Before Writing

**Collaborative protocol**:
```
I've analyzed your project. Here's what I found:

[Show summary]

Gaps identified:
1. [Gap 1 + question]
2. [Gap 2 + question]

Recommended next steps:
- [Priority 1]
- [Priority 2]
- [Priority 3]

May I write the full stage analysis to production/project-stage-report.md?
```

Wait for user approval before creating the file.

### 6. 写入前请求批准

**协作协议**：
```
I've analyzed your project. Here's what I found:

[Show summary]

Gaps identified:
1. [Gap 1 + question]
2. [Gap 2 + question]

Recommended next steps:
- [Priority 1]
- [Priority 2]
- [Priority 3]

May I write the full stage analysis to production/project-stage-report.md?
```

```
我已经分析过你的项目。以下是我的发现：

[显示摘要]

已识别缺口：
1. [缺口 1 + 问题]
2. [缺口 2 + 问题]

推荐的下一步：
- [优先级 1]
- [优先级 2]
- [优先级 3]

我可以把完整的阶段分析写入 production/project-stage-report.md 吗？
```

在创建文件前等待用户批准。

---

## Example Usage

```bash
# General project analysis
/project-stage-detect

# Programmer-focused analysis
/project-stage-detect programmer

# Designer-focused analysis
/project-stage-detect designer
```

---

## Follow-Up Actions

After generating the report, suggest relevant next steps — **only for gaps the
resolved workflow tier surfaces** (step 3). At `standard`/`minimal`, do not
suggest authoring optional docs (e.g. don't suggest `/reverse-document` for an
absent GDD at `minimal`, where code is the expected next step):

- **No `design/game-brief.md` at `minimal`?** → `/reverse-document design <code root>`
  when the code root already holds the game (10 or more source files): it writes
  the brief from what is built. With little or no code, `/brainstorm`.
- **Concept exists but no systems index?** → `/map-systems` to decompose into systems
- **Missing design docs?** → `/reverse-document design <code root>/[system]`
- **Missing architecture docs?** → `/architecture-decision` or `/reverse-document architecture`
- **Prototypes need documentation?** → `/reverse-document concept prototypes/[name]`
- **No sprint plan?** → `/sprint-plan` (not at `rigor: minimal`, where the brief's build order is the plan)
- **Approaching milestone?** → `/milestone-review`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Question First**: Ask about gaps, don't assume
2. **Present Options**: "Should I create X, or is it tracked elsewhere?"
3. **User Decides**: Wait for direction
4. **Show Draft**: Display report summary
5. **Get Approval**: "May I write to production/project-stage-report.md?"

**Never** silently write files. **Always** show findings and ask before creating artifacts.

## 示例用法

```bash
# General project analysis
/project-stage-detect

# Programmer-focused analysis
/project-stage-detect programmer

# Designer-focused analysis
/project-stage-detect designer
```

---

## 后续操作

生成报告后，建议相关的下一步 —— **只针对已解析工作流档位所呈现的缺口**（第 3 步）。在 `standard`/`minimal` 下，不要建议编写可选文档（例如在 `minimal` 下、代码才是预期下一步时，不要为缺失的 GDD 建议 `/reverse-document`）：

- **在 `minimal` 下没有 `design/game-brief.md`？** → 当代码根目录已经承载游戏（10 个或更多源文件）时，用 `/reverse-document design <code root>`：
  它会根据已构建的内容写出简报。代码很少或没有时，用 `/brainstorm`。
- **概念存在但没有系统索引？** → 用 `/map-systems` 拆解成系统
- **缺少设计文档？** → `/reverse-document design <code root>/[system]`
- **缺少架构文档？** → `/architecture-decision` 或 `/reverse-document architecture`
- **原型需要文档？** → `/reverse-document concept prototypes/[name]`
- **没有冲刺计划？** → `/sprint-plan`（在 `rigor: minimal` 下不用，那里简报的构建顺序就是计划）
- **临近里程碑？** → `/milestone-review`

---

## 协作协议

本技能遵循协作式设计原则：

1. **先提问**：就缺口提问，不要臆断
2. **呈现选项**："我该创建 X，还是它在别处被跟踪？"
3. **用户决定**：等待指示
4. **展示草稿**：显示报告摘要
5. **获得批准**："我可以写入 production/project-stage-report.md 吗？"

**绝不**静默写文件。**始终**先展示发现并在创建资产前询问。
