---
name: onboard
description: "Onboarding doc for a new contributor or agent — project state, conventions, priorities relevant to the specified role."
argument-hint: "[role|area]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/onboard/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

---
name: onboard
description: "面向新贡献者或智能体的入门文档 —— 项目状态、约定、与指定角色相关的优先事项。"
argument-hint: "[role|area]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/onboard/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次写文件都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重大事项询问 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

# Onboard

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

# 入门（Onboard）

## 输入不足 —— 在产出任何报告前检查此项

**如果本技能所需的输入不存在，答案就是"无法运行" ——
而不是一份填满的报告。** 先检查，若检查失败就停下。

1. 列出本技能读取的输入（数据文件、既有报告、性能剖析器输出、
   测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT` —— 而不是"假定存在"。
3. 如果某一节所需的任何输入是 ABSENT，该节就是
   **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻资产推断它，
   也不要留下一张强制表格让下一个读模板的人去填。
4. 如果**所有**必需输入都是 ABSENT，停下并把
   **`NOT ASSESSED — NO DATA`** 作为整体结论报告，点名缺失了什么以及
   哪个技能会产出它。

**`NOT ASSESSED` 的结论是一种成功。** 当没有数据时，它是对
"数据说明了什么？"正确而有用的回答。它防范的失败模式很具体：
一份结论枚举里没有"无法运行"状态的报告会产生
**虚假的干净通过** —— 在既无资产也无标准的项目上返回 COMPLIANT 的资产审计，
或是在零剖析器数据、从未设定预算的情况下，报告"相对 16.67ms 预算有 >99% 余量"的性能剖析。

**证据的缺失从来不是缺失的证据。** 一次因为没有任何文件可扫描而
零匹配的扫描，并没有验证任何东西。说清楚到底发生了这两种情况中的哪一种 ——
读者无法从一个绿色的结果中分辨。

---

## Phase 1: Load Project Context

Read CLAUDE.md for project overview and standards.

Read the relevant agent definition from `.claude/agents/` if a specific role is specified.

`CLAUDE.md` and `.claude/agents/` ship with the framework — no skill creates them. If either is missing, report it as missing from the install.

---

## 阶段 1：加载项目上下文

读取 CLAUDE.md 以了解项目概述和标准。

若指定了具体角色，从 `.claude/agents/` 读取相关的智能体定义。

`CLAUDE.md` 和 `.claude/agents/` 随框架一同提供 —— 没有技能会创建它们。若其中任一缺失，报告它属于安装缺失。

---

## Phase 2: Scan Relevant Area

- For programmers: scan the code root (resolve per `.claude/docs/code-root-resolution.md`) for architecture, patterns, key files. An unresolved root means the scan did not run: the sections it feeds read `NOT ASSESSED — code root unresolved`, never a guess at `src/`
- For designers: scan `design/` for existing design documents
- For narrative: scan `design/narrative/` for world-building and story docs
- For QA: scan `tests/` for existing test coverage (`/test-setup` creates it)
- For production: scan `production/` for current sprint and milestone
- **No role or area given**: a general orientation — list the top level of `design/`,
  `docs/architecture/`, `production/` and the code root, read
  `production/session-state/active.md` if it exists, and say that a role would
  focus the next pass (e.g. `/onboard programmer`)

Read recent changes (git log if available) to understand current momentum.

---

## 阶段 2：扫描相关区域

- 对于程序员：扫描代码根目录（按 `.claude/docs/code-root-resolution.md` 解析），了解架构、模式、关键文件。代码根目录未解析意味着扫描未运行：它所喂养的各节读作 `NOT ASSESSED — code root unresolved`，绝不用 `src/` 来猜测
- 对于设计师：扫描 `design/` 中已有的设计文档
- 对于叙事：扫描 `design/narrative/` 中的世界观构建和故事文档
- 对于 QA：扫描 `tests/` 中已有的测试覆盖（`/test-setup` 会创建它）
- 对于制作：扫描 `production/` 中的当前冲刺和里程碑
- **未给出角色或区域**：做一次通用导览 —— 列出 `design/`、
  `docs/architecture/`、`production/` 和代码根目录的顶层，读取
  `production/session-state/active.md`（若存在），并说明给出角色会
  让下一轮更聚焦（例如 `/onboard programmer`）

读取最近的改动（若有 git log）以了解当前势头。

---

## Phase 3: Generate Onboarding Document

```markdown
# Onboarding: [Role/Area]

## Project Summary
[2-3 sentence summary of what this game is and its current state]

## Your Role
[What this role does on this project, key responsibilities, who you report to]

## Project Architecture
[Relevant architectural overview for this role]

### Key Directories
| Directory | Contents | Your Interaction |
|-----------|----------|-----------------|

### Key Files
| File | Purpose | Read Priority |
|------|---------|--------------|

## Current Standards and Conventions
[Summary of conventions relevant to this role from CLAUDE.md and agent definition]

## Current State of Your Area
[What has been built, what is in progress, what is planned next. Name what
Phase 2 found by path — for a designer, each existing GDD and design doc — or
say it found none]

## Current Sprint Context
[What the team is working on now and what is expected of this role]

## Key Dependencies
[What other roles/systems this role interacts with most]

## Common Pitfalls
[Things that trip up new contributors in this area]

## First Tasks
[Suggested first tasks to get oriented and productive]

1. [Read these documents first]
2. [Review this code/content]
3. [Start with this small task]

## Questions to Ask
[Questions the new contributor should ask to get fully oriented]
```

---

## 阶段 3：生成入门文档

```markdown
# Onboarding: [Role/Area]

## Project Summary
[2-3 sentence summary of what this game is and its current state]

## Your Role
[What this role does on this project, key responsibilities, who you report to]

## Project Architecture
[Relevant architectural overview for this role]

### Key Directories
| Directory | Contents | Your Interaction |
|-----------|----------|-----------------|

### Key Files
| File | Purpose | Read Priority |
|------|---------|--------------|

## Current Standards and Conventions
[Summary of conventions relevant to this role from CLAUDE.md and agent definition]

## Current State of Your Area
[What has been built, what is in progress, what is planned next. Name what
Phase 2 found by path — for a designer, each existing GDD and design doc — or
say it found none]

## Current Sprint Context
[What the team is working on now and what is expected of this role]

## Key Dependencies
[What other roles/systems this role interacts with most]

## Common Pitfalls
[Things that trip up new contributors in this area]

## First Tasks
[Suggested first tasks to get oriented and productive]

1. [Read these documents first]
2. [Review this code/content]
3. [Start with this small task]

## Questions to Ask
[Questions the new contributor should ask to get fully oriented]
```

```markdown
# 入门：[Role/Area]

## 项目摘要
[用 2-3 句话概括这个游戏是什么及其当前状态]

## 你的角色
[该角色在本项目中做什么、关键职责、向谁汇报]

## 项目架构
[与该角色相关的架构概述]

### 关键目录
| 目录 | 内容 | 你的交互方式 |
|-----------|----------|-----------------|

### 关键文件
| 文件 | 用途 | 阅读优先级 |
|------|---------|--------------|

## 当前标准与约定
[来自 CLAUDE.md 和智能体定义中、与该角色相关的约定摘要]

## 你所在领域的当前状态
[已构建了什么、正在进行什么、下一步计划什么。按路径点名
阶段 2 发现的内容 —— 对设计师而言，是每份已有的 GDD 和设计文档 —— 或
说明它没有找到任何内容]

## 当前冲刺上下文
[团队现在在做什么，以及对该角色的期望]

## 关键依赖
[该角色交互最多的其他角色/系统]

## 常见陷阱
[新贡献者在该领域容易踩的坑]

## 首批任务
[建议的、用于熟悉上手并产生产出的首批任务]

1. [先阅读这些文档]
2. [审阅这段代码/内容]
3. [从这个小任务开始]

## 需要提出的问题
[新贡献者为完全熟悉情况应提出的问题]
```

---

## Phase 4: Save Document

Present the onboarding document to the user.

Ask: "May I write this to `production/onboarding/onboard-[role]-[date].md`?"

If yes, write the file, creating the directory if needed.

---

## 阶段 4：保存文档

向用户呈现入门文档。

询问："我可以把它写入 `production/onboarding/onboard-[role]-[date].md` 吗？"

如果是，写文件，必要时创建目录。

---

## Phase 5: Next Steps

Verdict: **COMPLETE** — onboarding document generated.

- Share the onboarding doc with the new contributor before their first session.
- Run `/sprint-status` to show the new contributor current progress.
- Run `/help` if the contributor needs guidance on what to work on next.

## 阶段 5：下一步

结论：**COMPLETE** —— 入门文档已生成。

- 在新贡献者的首次会话之前，把入门文档分享给他们。
- 运行 `/sprint-status` 向新贡献者展示当前进度。
- 如果贡献者需要关于接下来做什么的指引，运行 `/help`。
