---
name: skill-test
description: "Validate skill files for structural compliance and behavioral correctness. Four modes: static linter, spec, category rubric, audit."
argument-hint: "static [skill-name | all] | spec [skill-or-agent-name] | category [skill-or-agent-name | all] | audit"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/skill-test/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/agent-check.sh*), Bash(bash .claude/scripts/compat-inventory.sh*)
model: sonnet
---
---
name: skill-test
description: "验证技能文件的结构合规性与行为正确性。四种模式：静态检查器、规格、类别评分表、审计。"
argument-hint: "static [skill-name | all] | spec [skill-or-agent-name] | category [skill-or-agent-name | all] | audit"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/skill-test/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/agent-check.sh*), Bash(bash .claude/scripts/compat-inventory.sh*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重大事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终提示）。

# Skill Test

# 技能测试

Validates skills (`.claude/skills/*/SKILL.md`) and agents (`.claude/agents/*.md`)
for structural compliance and behavioral correctness. No external dependencies —
runs entirely within the existing skill/hook/template architecture.

验证技能（`.claude/skills/*/SKILL.md`）与智能体（`.claude/agents/*.md`）
的结构合规性与行为正确性。无外部依赖 —
完全在既有的技能/钩子/模板架构内运行。

**Four modes:**

**四种模式：**

| Mode | Command | Purpose | Token Cost |
|------|---------|---------|------------|
| `static` | `/skill-test static [name\|all]` | Structural linter — 7 compliance checks per skill, plus agent, delegation and compatibility observations | Low (~1k/skill) |
| `spec` | `/skill-test spec [name]` | Behavioral verifier — evaluates assertions in a skill's or agent's test spec | Medium (~5k each) |
| `category` | `/skill-test category [name\|all]` | Category rubric — checks a skill or agent against its category-specific metrics | Low (~2k each) |
| `audit` | `/skill-test audit` | Coverage report — skills, agent specs, last test dates | Low (~3k total) |

| 模式 | 命令 | 用途 | Token 开销 |
|------|------|------|------------|
| `static` | `/skill-test static [name\|all]` | 结构检查器 — 每个技能 7 项合规检查，外加智能体、委派与兼容性观察项 | 低（约 1k/技能） |
| `spec` | `/skill-test spec [name]` | 行为验证器 — 评估技能或智能体测试规格中的断言 | 中（每个约 5k） |
| `category` | `/skill-test category [name\|all]` | 类别评分表 — 按类别专属指标检查技能或智能体 | 低（每个约 2k） |
| `audit` | `/skill-test audit` | 覆盖率报告 — 技能、智能体规格、最近测试日期 | 低（总计约 3k） |

**What a pass proves.** Every mode reads files; none runs the skill. `static`:
the file has the structure a skill needs, not that it behaves. `spec`: read
closely, the instructions cover each case, not that Claude follows them when it
runs. `category`: the skill meets its category's rubric as written. `audit`:
which skills and agents have specs, and when each was last checked. What a skill
does shows only when it runs: a real request in a throwaway copy of the project,
on each model you use, with and without the skill (Anthropic's Agent Skills best
practices, "Build evaluations first").

**通过能证明什么。** 每种模式都只读取文件；没有任何一种会实际运行技能。`static`：
文件具备技能所需的结构，而不是它行为正确。`spec`：仔细阅读后，
指令覆盖了每个用例，而不是 Claude 在运行时会遵循它们。`category`：技能按其
类别评分表的字面要求达标。`audit`：哪些技能和智能体有规格，以及各自最近一次检查的时间。技能实际做什么，
只有运行它时才看得出来：在项目的一次性副本中发起真实请求，
在你使用的每个模型上，分别带技能和不带技能（Anthropic 的 Agent Skills 最佳实践，"Build evaluations first"）。

---

## Phase 1: Parse Arguments

## 阶段 1：解析参数

Determine mode from the first argument:

根据第一个参数确定模式：

- `static [name]` → run 7 structural checks on one skill, or the agent observations on one agent
- `static all` → run 7 structural checks on all skills (Glob `.claude/skills/*/SKILL.md`), plus the observations for every agent
- `spec [name]` → read the skill or agent + its test spec, evaluate assertions
- `category [name]` → run category-specific rubric from `studio-tests/quality-rubric.md`
- `category all` → run category rubric for every skill and every agent that has a `category:` in catalog
- `audit` (or no argument) → read catalog, list all skills and agents, show coverage

- `static [name]` → 对一个技能运行 7 项结构检查，或对一个智能体运行观察项
- `static all` → 对所有技能运行 7 项结构检查（Glob `.claude/skills/*/SKILL.md`），外加对每个智能体的观察项
- `spec [name]` → 读取技能或智能体 + 其测试规格，评估断言
- `category [name]` → 运行 `studio-tests/quality-rubric.md` 中类别专属的评分表
- `category all` → 对目录中每个带 `category:` 的技能和智能体运行类别评分表
- `audit`（或无参数）→ 读取目录，列出所有技能和智能体，显示覆盖率

If the argument is unrecognized, output usage and stop.

如果参数无法识别，输出用法并停止。

**The old spec folder.** Glob `CCGS Skill Testing Framework/catalog.yaml`. When
it exists, say so first: "`CCGS Skill Testing Framework/` was renamed
`studio-tests/` in 1.2.0, and this skill reads only `studio-tests/`. Move any
specs you wrote there; UPGRADING.md (v1.1.3 → v1.2.0, `studio-tests/`) says how."
Then go on with `studio-tests/`.

**旧规格文件夹。** Glob `CCGS Skill Testing Framework/catalog.yaml`。当它
存在时，先说明："`CCGS Skill Testing Framework/` 在 1.2.0 中已更名为
`studio-tests/`，而本技能只读取 `studio-tests/`。请移动你写在那里的任何
规格；UPGRADING.md（v1.1.3 → v1.2.0，`studio-tests/`）说明了方法。"
然后继续使用 `studio-tests/`。

**Resolve the name before `spec` or `category`.** Look it up in
`studio-tests/catalog.yaml`: an entry under `skills:` is a skill
(`.claude/skills/[name]/SKILL.md`); an entry under `agents:` is an agent
(`.claude/agents/[name].md`). With no catalog entry, use whichever of those two
files exists. Only when neither exists, report "'[name]' is neither a skill in
`.claude/skills/` nor an agent in `.claude/agents/`." and stop. A name that is
also an ordinary word is still a name: `/skill-test spec help` tests the `/help`
skill, never a request for this skill's usage.

**在 `spec` 或 `category` 之前先解析名称。** 在
`studio-tests/catalog.yaml` 中查找：`skills:` 下的条目是技能
（`.claude/skills/[name]/SKILL.md`）；`agents:` 下的条目是智能体
（`.claude/agents/[name].md`）。若目录中无条目，则使用这两个文件中存在的那个。
只有当两者都不存在时，才报告 "'[name]' 既不是 `.claude/skills/` 中的技能，
也不是 `.claude/agents/` 中的智能体。"并停止。一个同时也是普通单词的名称仍然是名称：
`/skill-test spec help` 测试的是 `/help` 技能，绝不是对本技能用法的请求。

The 7 checks lint SKILL.md structure, so they are skills-only. Given an agent
name, `static` runs only the observations below: an agent file has no
phases or verdict keywords to lint. Never report the agent as missing.

这 7 项检查针对 SKILL.md 的结构，因此仅适用于技能。给定智能体
名称时，`static` 只运行下面的观察项：智能体文件没有可供检查的阶段
或结论关键词。绝不要报告该智能体缺失。

---

## Phase 2A: Static Mode — Structural Linter

## 阶段 2A：静态模式 — 结构检查器

For each skill being tested, read its `SKILL.md` and every file in its `references/` folder
fully, and run all 7 checks on them as one skill — the longest skills keep each
phase in `references/`. The frontmatter checks (1, 6 and 7) read `SKILL.md`.

对每个被测技能，完整读取其 `SKILL.md` 及 `references/` 文件夹中的每个文件，
并将它们作为一个技能运行全部 7 项检查 — 最长的技能把每个阶段放在
`references/` 中。前置元数据检查（1、6、7）读取 `SKILL.md`。

### Check 1 — Required Frontmatter Fields

### 检查 1 — 必需的前置元数据字段

The file must contain all of these in the YAML frontmatter block:
- `name:`
- `description:`
- `argument-hint:`
- `user-invocable:`
- `allowed-tools:`

文件必须在 YAML 前置元数据块中包含以下全部字段：
- `name:`
- `description:`
- `argument-hint:`
- `user-invocable:`
- `allowed-tools:`

**FAIL** if any are absent. A file whose frontmatter does not parse fails Check 1
too — malformed YAML is a structural defect this check exists to catch, not an
unassessable file; see the per-skill result rule below.

**FAIL** 如果任一缺失。前置元数据无法解析的文件也会使检查 1 失败 —
格式错误的 YAML 是此检查存在就是为了捕捉的结构缺陷，而不是一个无法评估的文件；
参见下面的逐技能结果规则。

### Check 2 — Multiple Phases

### 检查 2 — 多个阶段

The skill must have ≥2 numbered phase headings. Look for patterns like:
- `## Phase N` or `## Phase N:`
- `## N.` (numbered top-level sections)
- At least 2 distinct `##` headings if phases aren't explicitly numbered

**FAIL** if fewer than 2 phase-like headings are found.

技能必须具有 ≥2 个带编号的阶段标题。查找诸如以下的模式：
- `## Phase N` 或 `## Phase N:`
- `## N.`（编号的顶级章节）
- 如果阶段未显式编号，则至少有 2 个不同的 `##` 标题

**FAIL** 如果找到的类阶段标题少于 2 个。

### Check 3 — Verdict Keywords

### 检查 3 — 结论关键词

The skill must communicate a clear outcome. Accept any of:

- **Gate / review verdicts** — `PASS`, `FAIL`, `CONCERNS`, `APPROVED`,
  `BLOCKED`, `COMPLETE`, `READY`, `COMPLIANT`, `NON-COMPLIANT`
- **Go / no-go verdicts** — `PROCEED`, `PIVOT`, `KILL`, `GO`, `NO-GO`
- **Severity scales** — `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Audit skills rank
  findings by severity instead of issuing one verdict for the whole run.

**FAIL** if none are present **and** the skill produces an assessment — its
description or body promises a review, audit, check, gate, or readiness
judgement.

**WARN** (never FAIL) if none are present and the skill's output is an artifact
or a value rather than a judgement. `/settings` is the reference case: it prints
and writes configuration and has no verdict to give. Do not invent one to
satisfy this check.

技能必须传达清晰的结果。接受以下任一：
- **门禁/评审结论** — `PASS`、`FAIL`、`CONCERNS`、`APPROVED`、
  `BLOCKED`、`COMPLETE`、`READY`、`COMPLIANT`、`NON-COMPLIANT`
- **Go / no-go 结论** — `PROCEED`、`PIVOT`、`KILL`、`GO`、`NO-GO`
- **严重度刻度** — `CRITICAL`、`HIGH`、`MEDIUM`、`LOW`。审计技能通过对发现
  按严重度排序来表达，而不是为整次运行给出单一结论。

**FAIL** 如果全都不存在**并且**该技能产出一个评估 — 它的
描述或正文承诺了评审、审计、检查、门禁或就绪判定。

**WARN**（绝不 FAIL）如果全都不存在，且技能的输出是产物
或一个值而非判定。`/settings` 是参照案例：它打印
并写入配置，没有可给出的结论。不要为了
满足此检查而虚构一个。

> A narrower list — gate verdicts only, hard FAIL on anything else — would wrongly
> fail skills for reasons that are not their fault: `/prototype` and
> `/vertical-slice` advertise `PROCEED`/`PIVOT`/`KILL` in their own descriptions,
> `/adopt` and `/security-audit` rank by severity, and `/settings` has no verdict
> by design. A linter that produces false failures on legitimate patterns stops
> being trusted.

> 一个更窄的清单 — 只认门禁结论，其他一律硬性 FAIL — 会错误地
> 因不属于技能自身过错的理由判定其失败：`/prototype` 和
> `/vertical-slice` 在自己的描述中宣称 `PROCEED`/`PIVOT`/`KILL`，
> `/adopt` 和 `/security-audit` 按严重度排序，而 `/settings` 按设计就没有结论。
> 一个对合法模式产生误报失败检查器会失去信任。

### Check 4 — Collaborative Protocol Language

### 检查 4 — 协作协议语言

The skill must contain ask-before-write language. Look for:
- `"May I write"` (canonical form)
- `"before writing"` or `"approval"` near file-write instructions
- `"ask"` + `"write"` in close proximity (within same section)

**WARN** if absent (some read-only skills legitimately skip this).
**FAIL** if `allowed-tools` includes `Write` or `Edit` but no ask-before-write language is found.

技能必须包含"写入前询问"的语言。查找：
- `"May I write"`（规范形式）
- 文件写入指令附近的 `"before writing"` 或 `"approval"`
- 同一章节内位置接近的 `"ask"` + `"write"`

**WARN** 如果缺失（某些只读技能合理地跳过此项）。
**FAIL** 如果 `allowed-tools` 包含 `Write` 或 `Edit`，但未找到写入前询问的语言。

### Check 5 — Next-Step Handoff

### 检查 5 — 下一步交接

The skill must end with a recommended next action or follow-up path. Look for:
- A final section mentioning another skill (e.g., `/story-done`, `/gate-check`)
- "Recommended next" or "next step" phrasing
- A "Follow-Up" or "After this" section

**WARN** if absent.

技能必须以一种推荐的后续动作或跟进步伐结束。查找：
- 提及另一个技能的最终章节（例如 `/story-done`、`/gate-check`）
- "Recommended next" 或 "next step" 的措辞
- "Follow-Up" 或 "After this" 章节

**WARN** 如果缺失。

### Check 6 — Fork Context Complexity

### 检查 6 — 分叉上下文复杂度

If frontmatter contains `context: fork`, the skill should have ≥5 phase headings
(`##` level or numbered Phase N headers). Fork context is for complex multi-phase
skills; simple skills should not use it.

**WARN** if `context: fork` is set but fewer than 5 phases found.

如果前置元数据包含 `context: fork`，技能应具有 ≥5 个阶段标题
（`##` 级别或编号的 Phase N 标题）。分叉上下文用于复杂的多阶段
技能；简单技能不应使用它。

**WARN** 如果设置了 `context: fork` 但找到的阶段少于 5 个。

### Check 7 — Argument Hint Plausibility

### 检查 7 — 参数提示合理性

`argument-hint` must be non-empty. If the skill body mentions multiple modes
(e.g., "Mode A | Mode B"), the hint should reflect them. Cross-reference the
hint against the first phase's "Parse Arguments" section.

**WARN** if hint is `""` or if documented modes don't match hint.

`argument-hint` 必须非空。如果技能正文提及多种模式
（例如 "Mode A | Mode B"），提示应反映它们。将
提示与第一阶段 "Parse Arguments" 章节交叉比对。

**WARN** 如果提示为 `""`，或文档化模式与提示不匹配。

### Agent and Delegation Observations (not scored)

### 智能体与委派观察项（不计分）

Run `bash .claude/scripts/agent-check.sh --skill [name]` for a skill,
`bash .claude/scripts/agent-check.sh --agent [name]` for an agent, or
`bash .claude/scripts/agent-check.sh` once for `static all`. It prints
observations, never a verdict, and nothing here changes a skill's verdict. Report
them under `Observations:`, judging each:

- **`DELEGATION:`** a part of the skill that hands work to an agent. Read it and
  say whether the brief gives an objective, an output format, the tools and
  sources, and boundaries, and whether it hands the agent a job of only a few
  tool calls or a re-check of the skill's own work. Its `markers:` are word
  counts that show where to look, not a grade.
- **`AGENT:`** the model, effort and turn limit as set, and the tools beside the
  description: name any tool the job in the description does not need.
- **`NOTE:`** frontmatter that does not parse; `asks-user` (an agent has no
  question tool, so its questions belong at the end of its report); a setting
  that is ignored or does more than it says (`agent-type-list`, `preload-off`,
  `disallowed-specifier`, `memory-grants`).
- **`OVERLAP:`** two descriptions that share distinctive words: say whether each
  still singles out its agent, or which request would reach the wrong one.

对技能运行 `bash .claude/scripts/agent-check.sh --skill [name]`，
对智能体运行 `bash .claude/scripts/agent-check.sh --agent [name]`，或
对 `static all` 运行一次 `bash .claude/scripts/agent-check.sh`。它打印
观察项，从不给出结论，此处任何内容都不会改变技能的结论。将它们报告在
`Observations:` 下，并逐项判断：

- **`DELEGATION:`** 技能中把工作交给智能体的部分。阅读它并
  说明该简报是否给出了目标、输出格式、工具与
  来源、以及边界，以及它交给智能体的任务是否只有少量
  工具调用，或是对技能自身工作的复核。其 `markers:` 是显示
  应查看何处词数统计，不是评分。
- **`AGENT:`** 模型、算力和轮次上限的设置值，以及描述旁边的
  工具：指出描述中的任务不需要的任何工具。
- **`NOTE:`** 无法解析的前置元数据；`asks-user`（智能体没有
  提问工具，因此其问题应放在报告末尾）；被
  忽略或所做多于所言的设置（`agent-type-list`、`preload-off`、
  `disallowed-specifier`、`memory-grants`）。
- **`OVERLAP:`** 两个共享特征词的描述：说明各自
  是否仍能单独指向其智能体，或哪个请求会到达错误的那个。

If the script cannot run, write `Observations: not run (<reason>)`. Never leave
the section out: a missing section reads the same as a clean one.

如果脚本无法运行，写 `Observations: not run (<reason>)`。绝不省略
该章节：缺失的章节读起来与干净的章节相同。

### Compatibility Observations (not scored)

### 兼容性观察项（不计分）

Run `bash .claude/scripts/compat-inventory.sh --skill [name]` for a skill,
`bash .claude/scripts/compat-inventory.sh --agent [name]` for an agent, or
`bash .claude/scripts/compat-inventory.sh` once for `static all`. Each `FOUND:`
line is a place the file depends on something only Claude Code provides, with
its feature: questions, subagents, skill-loading, shell-lines, arguments,
frontmatter, instructions, hooks, settings or tools. Claude Code runs all of
them, so none is a defect and none changes a verdict. Report them under
`Compatibility:`, one line per feature with its constructs and line numbers;
for `static all`, give the `COUNT:` totals by feature instead. A `NOT FOUND:`
line means the name matched no file: say so. If the script cannot run, write
`Compatibility: not run (<reason>)`.

对技能运行 `bash .claude/scripts/compat-inventory.sh --skill [name]`，
对智能体运行 `bash .claude/scripts/compat-inventory.sh --agent [name]`，或
对 `static all` 运行一次 `bash .claude/scripts/compat-inventory.sh`。每条 `FOUND:`
行都是该文件依赖 Claude Code 独有功能的位置，并带有其
功能名：问题、子智能体、技能加载、shell 行、参数、
前置元数据、指令、钩子、设置或工具。Claude Code 运行其中
全部，因此没有一条是缺陷，也没有一条会改变结论。将它们报告在
`Compatibility:` 下，每个功能一行，附其构造与行号；
对于 `static all`，改为按功能给出 `COUNT:` 总计。一条 `NOT FOUND:`
行意味着该名称未匹配任何文件：要说明这一点。如果脚本无法运行，写
`Compatibility: not run (<reason>)`。

---

### Static Mode Output Format

### 静态模式输出格式

For a single skill:
```
=== Skill Static Check: /[name] ===

Check 1 — Frontmatter Fields:    PASS
Check 2 — Multiple Phases:       PASS (7 phases found)
Check 3 — Verdict Keywords:      PASS (PASS, FAIL, CONCERNS)
Check 4 — Collaborative Protocol: PASS ("May I write" found)
Check 5 — Next-Step Handoff:     WARN (no follow-up section found)
Check 6 — Fork Context Complexity: PASS (8 phases, context: fork set)
Check 7 — Argument Hint:         PASS

Observations (not scored):
  Delegation, "Phase 3: Implementation" (line 202): ux-designer, ui-programmer.
    The brief names the output file and limits but no sources to read.

Compatibility (not scored):
  questions: AskUserQuestion (lines 13, 88) · shell-lines: shell-line (line 10)
  frontmatter: allowed-tools, argument-hint, model, user-invocable (lines 4-7)

Verdict: WARNINGS (1 warning, 0 failures)
Recommended: Add a "Follow-Up Actions" section at the end of the skill.
```

For a single agent there is no verdict, only observations:
```
=== Agent Static Check: qa-lead ===

Model: inherit · Effort: unset · Turn limit: 20
Tools: Read, Glob, Grep, Write, Edit, Bash. Fits the job (it writes test plans).
Observations (not scored):
  asks-user (lines 31, 52): tells the agent to get approval before writing.
  overlap with qa-tester (creation, regression, test): each still singled out.
Compatibility (not scored):
  frontmatter: tools, tools-string, model, maxTurns (lines 4-6)
```

A WARN or FAIL line names its cause in parentheses, and any verdict other than
COMPLIANT ends with a `Recommended:` line naming the fix.

WARN 或 FAIL 行在括号中说明其原因，任何非
COMPLIANT 的结论都以一行 `Recommended:` 结尾，指明修复方法。

The single-skill `Verdict:` is one of four values, the same as the `static all`
Result column: **COMPLIANT** (no warnings, no failures), **WARNINGS** (warnings,
no failures), **NON-COMPLIANT** (any FAIL), or **NOT ASSESSED** (the file could
not be read or parsed, or its checks could not run — name the reason).

单技能的 `Verdict:` 是四个值之一，与 `static all` 的
Result 列相同：**COMPLIANT**（无警告、无失败）、**WARNINGS**（有警告、
无失败）、**NON-COMPLIANT**（任一 FAIL），或 **NOT ASSESSED**（文件
无法读取或解析，或检查无法运行 — 指明原因）。

For `static all`, produce a summary table then list any non-compliant skills:
```
=== Skill Static Check: All 74 Skills ===

Skill                  | Result       | Issues
-----------------------|--------------|-------
gate-check             | COMPLIANT    |
design-review          | COMPLIANT    |
story-readiness        | WARNINGS     | Check 5: no handoff
...

Summary: 48 COMPLIANT, 3 WARNINGS, 1 NON-COMPLIANT, 1 NOT ASSESSED
Aggregate Verdict: N WARNINGS / N FAILURES / N NOT ASSESSED

Agents (observations, not scored): 49 read
  asks-user: N agents · agent-type-list: N · preload-off: N · frontmatter: N
  Overlap pairs: [each pair, with whether both are still singled out]
  Delegation blocks: N in N skills; [the ones whose brief lacks a part]

Compatibility (not scored): N FOUND lines in N of N files read
  [feature]: [construct] N files, N hits; ...   (one line per feature)
```

**`NOT ASSESSED` is a per-skill result here, not only an aggregate line.** A skill
whose file is missing or otherwise unreadable (permissions, not found), so no
check could even start, is reported as `NOT ASSESSED` with the reason — never
omitted from the table and never counted as COMPLIANT. Ranked **above
COMPLIANT**, **below WARNINGS and NON-COMPLIANT**. A file that *was* read but
whose frontmatter does not parse is a different case: Check 1 fails on it (see
above), so it is reported **NON-COMPLIANT**, not NOT ASSESSED — the defect is in
the skill, not in the linter's access to it.

**`NOT ASSESSED` 在此处是逐技能结果，而不仅是一行汇总。** 一个
文件缺失或因其他原因无法读取（权限、未找到）、以致任何
检查都无法开始的技能，报告为 `NOT ASSESSED` 并附原因 — 绝不
从表格中省略，也绝不计为 COMPLIANT。其排名**高于
COMPLIANT**、**低于 WARNINGS 和 NON-COMPLIANT**。一个*被*读取了但
前置元数据无法解析的文件是另一种情况：检查 1 在其上失败（见
上文），因此它报告为 **NON-COMPLIANT**，而非 NOT ASSESSED — 缺陷在
技能中，而不在检查器对它的访问中。

**And state the denominator.** `All 74 Skills` in the header must be the number
actually examined, not the number that exist: report `[N] of [M] skills checked`
whenever they differ. A summary whose counts silently sum to less than its own
title is the failure this skill is supposed to catch in others.

**并且要说明分母。** 标题中的 `All 74 Skills` 必须是实际
检查的数量，而不是存在的数量：只要二者不同，就报告 `[N] of [M] skills checked`。
一份计数悄悄小于其自身标称总量的摘要，正是本技能本应在他人身上捕捉的失败。

No file writes in static mode.

静态模式下不写入任何文件。

---

## Phase 2B: Spec Mode — Behavioral Verifier

## 阶段 2B：规格模式 — 行为验证器

### Step 1 — Locate Files

### 步骤 1 — 定位文件

Use the skill or agent file resolved in Phase 1.
Look up the spec path from `studio-tests/catalog.yaml` — use the
`spec:` field on the matching `skills:` or `agents:` entry.

使用阶段 1 中解析出的技能或智能体文件。
从 `studio-tests/catalog.yaml` 查找规格路径 — 使用匹配的 `skills:` 或 `agents:` 条目上的
`spec:` 字段。

If either is missing:
- Missing skill or agent: the Phase 1 message.
- Missing spec path in catalog: "No spec path set for '[name]' in catalog.yaml."
- Spec file not found at path: "Spec file missing at [path]. Run `/skill-test audit`
  to see coverage gaps."

如果两者中任一缺失：
- 缺少技能或智能体：使用阶段 1 的消息。
- 目录中缺少规格路径："No spec path set for '[name]' in catalog.yaml."
- 在路径处未找到规格文件："Spec file missing at [path]. Run `/skill-test audit`
  to see coverage gaps."

### Step 2 — Read Both Files

### 步骤 2 — 读取两个文件

Read the skill — its `SKILL.md` and every file in its `references/` folder — or
the agent file, and the test spec file, completely.

完整读取技能 — 其 `SKILL.md` 及 `references/` 文件夹中的每个文件 — 或
智能体文件，以及测试规格文件。

### Step 3 — Evaluate Assertions

### 步骤 3 — 评估断言

**Evaluate against what the model running it can see.** A skill runs in a
session, and a spawned agent in its own context, and both have the project's
`CLAUDE.md` loaded along with every file it imports on an `@path` line (a
spawned agent quotes `coordination-rules.md` word for word without reading it).
Read those files too. A rule stated there counts for every skill and agent —
cite the file it came from. Where the skill's or agent's own file contradicts
it, the own file wins: it is the more specific instruction.

**依据运行它的模型所能看到的内容来评估。** 技能在
会话中运行，被派生的智能体在自己上下文中运行，两者都加载了项目的
`CLAUDE.md` 以及它通过 `@path` 行导入的每个文件（被
派生的智能体会逐字引用 `coordination-rules.md` 而无需读取它）。
也要读取那些文件。其中陈述的规则对每个技能和智能体都算数 —
引用它来自的文件。若技能或智能体自身的文件与它矛盾，
以自身文件为准：它是更具体的指令。

**For an agent**, the spec's sections are evaluated against the agent file —
and against every skill its frontmatter lists under `skills:`, which Claude
Code loads into the agent at launch:

**对于智能体**，规格的各章节依据智能体文件评估 —
并依据其前置元数据在 `skills:` 下列出的每个技能（Claude
Code 在启动时将其加载进智能体）：

- **Static Assertions** — check each against the agent's frontmatter and body.
  An assertion that names a literal value (a `model:` alias, a frontmatter key,
  a tool name) is an exact comparison with the file: `model: inherit` does not
  satisfy "Model tier is `sonnet`", and a near match is FAIL, never PARTIAL.
- **Test Cases** — evaluate each case's expected behavior against the agent's
  written instructions, the same way a skill's are evaluated below. A case
  that names a gate ID (`LP-FEASIBILITY`, `CD-PILLARS`, …) is that gate's
  invocation: the spawning skill has the agent read
  `.claude/docs/director-gates/[gate-id].md` first, so that file's Prompt and
  Verdicts are the agent's instructions for the case — read it too.
- **Redirect and escalation cases** — the agent is asked for work another role
  owns, or meets a conflict it cannot settle. The case is met when the loaded
  `coordination-rules.md` covers the step — rule 2 (no binding decisions
  outside its domain), rule 3 (escalate a conflict to the shared parent) or
  rule 5 (no files outside its directories without delegation) — **and** the
  agent's own file names the owning role in its collaborator, delegation,
  escalation or "must not" lists. Cite both; do not require the agent to
  restate the redirect in its own words. It is a FAIL when the agent's file
  claims that work for itself, or when no loaded file names who owns it.
- **Protocol Compliance** — use the spec's own `## Protocol Compliance` list in
  place of the four skill checks below.

- **静态断言** — 逐项依据智能体的前置元数据和正文检查。
  一个指明字面值的断言（`model:` 别名、前置元数据键、
  工具名）是对文件的精确比对：`model: inherit` 不
  满足 "Model tier is `sonnet`"，近似匹配是 FAIL，绝非 PARTIAL。
- **测试用例** — 依据智能体编写的指令评估每个用例的预期行为，
  方式与下面评估技能时相同。一个指明门禁 ID（`LP-FEASIBILITY`、`CD-PILLARS` 等）的用例
  就是该门禁的调用：派生它的技能会让智能体先读取
  `.claude/docs/director-gates/[gate-id].md`，因此该文件的 Prompt 和
  Verdicts 就是智能体对该用例的指令 — 也要读取它。
- **重定向与升级用例** — 智能体被要求承担另一个角色
  拥有的工作，或遇到它无法解决的冲突。当已加载的
  `coordination-rules.md` 覆盖了该步骤时，该用例即满足 — 规则 2（不在其领域之外
  作约束性决策）、规则 3（将冲突升级给共同父级）或
  规则 5（未经委派不触碰其目录之外的文件）— **并且**
  智能体自身的文件在其协作者、委派、
  升级或"不得"列表中指明了拥有该职责的角色。引用二者；不要要求智能体
  用自己的话重述该重定向。当智能体的文件
  将该项工作据为己有，或没有任何已加载文件指明谁拥有它时，是 FAIL。
- **协议合规** — 使用规格自有的 `## Protocol Compliance` 列表，
  替代下面的四项技能检查。

**For a skill**, check each of the spec's **Static Assertions** against the
skill's frontmatter and body (`SKILL.md` and its `references/` files) the same
way; a literal value is an exact comparison. `/skill-test static` runs only its
7 fixed checks, so a spec's own static lines — a verdict keyword, a phase, "May
I write" before a named file — are evaluated here or nowhere.

**对于技能**，以同样方式依据技能的前置元数据和正文（`SKILL.md` 及其 `references/` 文件）
检查规格的每条**静态断言**；字面值是精确比对。`/skill-test static` 只运行其
7 项固定检查，因此规格自有的静态条目 — 一个结论关键词、一个阶段、命名文件之前的 "May
I write" — 要么在这里评估，要么哪里都不评估。

The rest of this step applies to skills and agents alike.

本步骤的其余部分对技能和智能体同样适用。

For each **Test Case** in the spec:

1. Read the **Fixture** description (assumed state of project files)
2. Read the **Expected behavior** steps
3. Read each **Assertion** checkbox

对规格中的每个**测试用例**：

1. 读取 **Fixture** 描述（假定的项目文件状态）
2. 读取 **Expected behavior** 步骤
3. 读取每个 **Assertion** 复选框

A case with no **Fixture** reads its **Input** as the fixture; a case with no
**Assertions** list treats each **Expected behavior** bullet as an assertion —
most agent specs are written this way, and a case verdict is not left undefined
just because it has no separate checklist.

没有 **Fixture** 的用例将其 **Input** 读作 fixture；没有
**Assertions** 列表的用例将每条 **Expected behavior** 条目视为一条断言 —
大多数智能体规格就是这样写的，且不会仅因为用例没有单独的清单
就让其判定悬而未决。

For each assertion, evaluate whether the skill's written instructions, if
followed correctly given the fixture state, would satisfy it. This is a
Claude-evaluated reasoning check, not code execution.

对每条断言，评估技能的书面指令在给定 fixture 状态并按正确方式
遵循时，是否能够满足它。这是一个由 Claude 评估的推理检查，而非代码执行。

Mark each assertion:
- **PASS** — skill instructions clearly satisfy this assertion
- **PARTIAL** — skill instructions partially address it, but with ambiguity
- **FAIL** — skill instructions would NOT satisfy this assertion given the fixture
- **NOT ASSESSED** — the assertion could not be evaluated at all: it names a
  fixture state the spec never defines, depends on runtime behavior no static
  read can settle, or references a file or section that does not exist (a file
  that is merely silent on the behaviour is FAIL or PARTIAL, not this). Rank it
  **above PASS** (an assertion nobody could evaluate has not been satisfied) and
  **below PARTIAL and FAIL** (an ambiguity somebody identified is more actionable
  than one nobody could reach). Do not resolve an unevaluable assertion to PASS
  because the skill "probably" handles it — that judgement is what the spec exists
  to replace.

标记每条断言：
- **PASS** — 技能指令明确满足该断言
- **PARTIAL** — 技能指令部分涉及它，但存在歧义
- **FAIL** — 给定 fixture 时，技能指令不会满足该断言
- **NOT ASSESSED** — 该断言完全无法评估：它指明了一个
  规格从未定义的 fixture 状态，依赖任何静态阅读都无法确定的运行时行为，
  或引用了一个不存在的文件或章节（对某行为仅仅保持沉默的文件
  属于 FAIL 或 PARTIAL，不是此项）。其排名**高于 PASS**
  （没有人能评估的断言尚未被满足），并
  **低于 PARTIAL 和 FAIL**（有人指出的歧义比没人能触及的
  更可行动）。不要因为技能"大概"处理了它，就把无法评估的断言判定为 PASS —
  规格存在正是为了取代那种判断。

For a skill's **Protocol Compliance** section (always present), evaluate each line
of the spec's own list against the skill's files exactly as you evaluate a case
assertion — PASS, PARTIAL, FAIL or NOT ASSESSED. Specs put rules there that no
case repeats ("covered by the protocol compliance assertions above"), so a
list that is not evaluated is a set of rules nobody checks. These four checks are
the floor, added when the list does not already cover them:
- Check whether the skill requires "May I write" before file writes
- Check whether the skill presents findings before requesting approval
- Check whether the skill ends with a recommended next step
- Check whether the skill avoids auto-creating files without approval

对于技能的 **Protocol Compliance** 章节（始终存在），依据技能文件评估规格自有列表的
每一行，完全按照评估用例断言的方式 — PASS、PARTIAL、FAIL 或 NOT ASSESSED。规格会把没有
用例重复的规则放在那里（"covered by the protocol compliance assertions above"），因此一个
未被评估的列表就是一组没人检查的规则。这四项检查是
底线，在列表尚未覆盖它们时补上：
- 检查技能是否在文件写入前要求 "May I write"
- 检查技能是否在请求批准前呈现发现
- 检查技能是否以推荐的下一步结束
- 检查技能是否避免未经批准自动创建文件

### Step 4 — Build Report

### 步骤 4 — 构建报告

```
=== Skill Spec Test: /[name] ===
Date: [date]
Spec: studio-tests/skills/[category]/[name].md

Static Assertions:
  [PASS] [assertion text]
  [NOT ASSESSED] [assertion text]
     Reason: [why it could not be evaluated]

Case 1: [Happy Path — name]
  Fixture: [summary]
  Assertions:
    [PASS] [assertion text]
    [FAIL] [assertion text]
       Reason: The skill's Phase 3 says "..." but the fixture state means "..."
  Case Verdict: FAIL

Case 2: [Edge Case — name]
  ...
  Case Verdict: PASS

Protocol Compliance:
  [PASS] Uses "May I write" before file writes
  [PASS] Presents findings before asking approval
  [PARTIAL] No explicit next-step handoff at end

Overall Verdict: FAIL (1 case failed, 1 protocol line partial)
```

A Case Verdict is the worst result among its assertions, and the Overall
Verdict the worst across the static assertions, the cases and Protocol
Compliance, in this order:
FAIL, PARTIAL, NOT ASSESSED, PASS. An assertion nobody could evaluate keeps the
overall result from reading PASS.

用例判定是其断言中最差的结果，而总
判定是静态断言、用例和协议
合规中最差者，按此顺序：
FAIL、PARTIAL、NOT ASSESSED、PASS。一条没人能评估的断言会阻止
总体结果读作 PASS。

For an agent, the header is `=== Agent Spec Test: [name] ===`, `Spec:` is its
path under `studio-tests/agents/`, and a `Static Assertions:`
block comes before Case 1.

对于智能体，标题为 `=== Agent Spec Test: [name] ===`，`Spec:` 是其在
`studio-tests/agents/` 下的路径，并且在 Case 1 之前有一个 `Static Assertions:`
块。

### Step 5 — Offer to Write Results

### 步骤 5 — 提议写入结果

"May I write these results to `studio-tests/results/skill-test-spec-[name]-[date].md`
and update `studio-tests/catalog.yaml`?"

"May I write these results to `studio-tests/results/skill-test-spec-[name]-[date].md`
and update `studio-tests/catalog.yaml`?"

If yes:
- Write results file to `studio-tests/results/`
- Update the skill's or agent's entry in `studio-tests/catalog.yaml`:
  - `last_spec: [date]`
  - `last_spec_result: PASS|PARTIAL|FAIL|NOT ASSESSED` — the Overall Verdict

若同意：
- 将结果文件写入 `studio-tests/results/`
- 更新技能或智能体在 `studio-tests/catalog.yaml` 中的条目：
  - `last_spec: [date]`
  - `last_spec_result: PASS|PARTIAL|FAIL|NOT ASSESSED` — 总判定

---

## Phase 2D: Category Mode — Rubric Evaluation

## 阶段 2D：类别模式 — 评分表评估

### Step 1 — Locate Skill and Category

### 步骤 1 — 定位技能与类别

Use the skill or agent file resolved in Phase 1.
Look up the `category:` field on its `skills:` or `agents:` entry in
`studio-tests/catalog.yaml`.

使用阶段 1 中解析出的技能或智能体文件。
在 `studio-tests/catalog.yaml` 中查找其 `skills:` 或 `agents:` 条目上的 `category:` 字段。

If neither file exists: the Phase 1 message.
If no `category:` field: "No category assigned for '[name]' in catalog.yaml.
Add `category: [name]` to its entry first."

如果两个文件都不存在：使用阶段 1 的消息。
如果无 `category:` 字段："No category assigned for '[name]' in catalog.yaml.
Add `category: [name]` to its entry first."

For `category all`: collect every skill and every agent with a `category:` field
and process each, reporting skills and agents in separate tables.
`category: utility` skills are evaluated against U1 (static checks pass) and U2
(gate mode correct if applicable) only — skip to the static mode for U1.
Cross-check against `.claude/skills/*/SKILL.md` and `.claude/agents/*.md`
(Audit mode's Step 2 glob): list any skill or agent missing from the catalog, or
catalogued with no `category:`, by name as **NOT ASSESSED** — never silently
excluded from the run.

对于 `category all`：收集每个带 `category:` 字段的技能和智能体
并逐一处理，将技能和智能体分别在独立的表格中报告。
`category: utility` 技能仅依据 U1（静态检查通过）和 U2
（门禁模式在适用时正确）评估 — U1 则跳到静态模式。
对照 `.claude/skills/*/SKILL.md` 和 `.claude/agents/*.md`
（审计模式的步骤 2 glob）交叉检查：按名称列出任何未出现在目录中、或
已收录但没有 `category:` 的技能或智能体，标为 **NOT ASSESSED** — 绝不要悄悄
将其排除在运行之外。

### Step 2 — Read Rubric Section

### 步骤 2 — 读取评分表章节

Read `studio-tests/quality-rubric.md`.
Extract the section matching the category (e.g., `### gate`, `### team`; an
agent's category is under `## Agent Categories`, e.g. `### director`).
If the rubric has no section for the category, the result is **NOT ASSESSED**:
name the missing section, and never borrow another category's metrics.

读取 `studio-tests/quality-rubric.md`。
提取与该类别匹配的章节（例如 `### gate`、`### team`；智能体的
类别位于 `## Agent Categories` 下，例如 `### director`）。
如果评分表没有该类别对应的章节，结果为 **NOT ASSESSED**：
指明缺失的章节，绝不借用其他类别的指标。

### Step 3 — Read Skill

### 步骤 3 — 读取技能

Read the skill's `SKILL.md` and every file in its `references/` folder, or the
agent's `.claude/agents/[name].md`, fully,
and the project context Phase 2B Step 3 describes — a metric met by a rule in
`CLAUDE.md` or a file it imports is met, citing that file. Its rule for
redirect and escalation cases decides the domain, deferral and escalation
metrics too (D2, D3, L2, S1–S3, O2).

完整读取技能的 `SKILL.md` 及其 `references/` 文件夹中的每个文件，或
智能体的 `.claude/agents/[name].md`，
以及阶段 2B 步骤 3 描述的项目上下文 — 若某项指标由
`CLAUDE.md` 或其导入文件中的规则满足，即视为满足，并引用该文件。其面向
重定向与升级用例的规则也决定了领域、延后与升级
指标（D2、D3、L2、S1–S3、O2）。

### Step 4 — Evaluate Rubric Metrics

### 步骤 4 — 评估评分表指标

For each metric in the category's rubric table:
1. Check whether the skill's or agent's written instructions clearly satisfy the criterion
2. Mark PASS, FAIL, WARN, or NOT ASSESSED (the metric could not be evaluated — name why)
3. For FAIL/WARN/NOT ASSESSED, identify the exact gap in the text (quote the
   relevant section, note its absence, or name what could not be evaluated)

对类别评分表中的每项指标：
1. 检查技能或智能体的书面指令是否明确满足该标准
2. 标记 PASS、FAIL、WARN 或 NOT ASSESSED（该指标无法评估 — 指明原因）
3. 对 FAIL/WARN/NOT ASSESSED，指出文本中的确切差距（引用
   相关章节、注明其缺失，或指明什么无法评估）

### Step 5 — Output Report

### 步骤 5 — 输出报告

For an agent, the header is `=== Agent Category Check: [name] ([category]) ===`.

对于智能体，标题为 `=== Agent Category Check: [name] ([category]) ===`。

```
=== Skill Category Check: /[name] ([category]) ===

Metric G1 — Review mode read:      PASS
Metric G2 — Director panel width:  FAIL
  Gap: Phase 3 spawns only CD-PHASE-GATE at `workflow: full`; TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE absent
Metric G3 — Lean mode: PHASE-GATE only: PASS
Metric G4 — Solo mode: no directors:    PASS
Metric G5 — No auto-advance:       PASS

Verdict: FAIL (1 failure, 0 warnings)
Fix: Size the Phase 3 panel from `modes.workflow` — PR at `minimal`, TD + PR at
     `standard`, all four at `full` — and name any perspective a narrower panel leaves out.
```

The category verdict, first match wins: **FAIL** when any metric fails; else
**WARNINGS** when any metric warns; else **NOT ASSESSED** when any metric could
not be evaluated (a rubric section missing, a file unreadable); else **PASS**
when every metric passes — the same ranking as static and spec mode. It is
`last_category_result` in the catalog.

类别结论，最先匹配者胜出：**FAIL** 当任何指标失败；否则
**WARNINGS** 当任何指标警告；否则 **NOT ASSESSED** 当任何指标无法
评估（评分表章节缺失、文件不可读）；否则 **PASS**
当每项指标都通过 — 与静态模式和规格模式相同的排名。它是
目录中的 `last_category_result`。

### Step 6 — Offer to Update Catalog

### 步骤 6 — 提议更新目录

"May I update `studio-tests/catalog.yaml` to record this category check
(`last_category`, `last_category_result`) for [name]?"

"May I update `studio-tests/catalog.yaml` to record this category check
(`last_category`, `last_category_result`) for [name]?"

---

## Phase 2C: Audit Mode — Coverage Report

## 阶段 2C：审计模式 — 覆盖率报告

### Step 1 — Read Catalog

### 步骤 1 — 读取目录

Read `studio-tests/catalog.yaml`. If missing, note that catalog doesn't exist
yet (first-run state).

读取 `studio-tests/catalog.yaml`。如果缺失，注明目录尚不存在
（首次运行状态）。

### Step 2 — Enumerate All Skills and Agents

### 步骤 2 — 枚举所有技能和智能体

Glob `.claude/skills/*/SKILL.md` to get the complete list of skills.
Extract skill name from each path (directory name).

Glob `.claude/agents/*.md` for the complete list of agents — the repo itself,
not the catalog, is the covered set (`.claude/rules/skill-authoring.md` §5:
gates derive their covered set, they do not enumerate it). Compare both globs
against the catalog's `skills:`/`agents:` entries and report any skill or agent
missing from the catalog by name, so an uncatalogued one cannot drop out silently.

Glob `.claude/skills/*/SKILL.md` 以获取完整的技能列表。
从每个路径提取技能名称（目录名）。

Glob `.claude/agents/*.md` 以获取完整的智能体列表 — 被覆盖的集合是仓库本身，
而非目录（`.claude/rules/skill-authoring.md` §5：
门禁派生其覆盖集合，而不是枚举它）。将两个 glob 与
目录的 `skills:`/`agents:` 条目比对，并按名称报告任何
不在目录中的技能或智能体，使未被收录者无法悄悄落空。

### Step 3 — Build Skill Coverage Table

### 步骤 3 — 构建技能覆盖表

For each skill:
- Check if a spec file exists (use the `spec:` path from catalog, or glob `studio-tests/skills/*/[name].md`)
- Look up `last_static`, `last_static_result`, `last_spec`, `last_spec_result`,
  `last_category`, `last_category_result`, `category` from catalog (or mark as
  "never" / "—" if not in catalog)
- Priority comes from catalog `priority:` field (critical/high/medium/low)

对每个技能：
- 检查是否存在规格文件（使用目录中的 `spec:` 路径，或 glob `studio-tests/skills/*/[name].md`）
- 从目录查找 `last_static`、`last_static_result`、`last_spec`、`last_spec_result`、
  `last_category`、`last_category_result`、`category`（或若不在目录中，
  标为 "never" / "—"）
- 优先级来自目录的 `priority:` 字段（critical/high/medium/low）

### Step 3b — Build Agent Coverage Table

### 步骤 3b — 构建智能体覆盖表

For each agent in catalog's `agents:` section:
- Check if a spec file exists (use the `spec:` path from catalog, or glob `studio-tests/agents/*/[name].md`)
- Look up `last_spec`, `last_spec_result`, `last_category`,
  `last_category_result`, `category` from catalog

对目录 `agents:` 章节中的每个智能体：
- 检查是否存在规格文件（使用目录中的 `spec:` 路径，或 glob `studio-tests/agents/*/[name].md`）
- 从目录查找 `last_spec`、`last_spec_result`、`last_category`、
  `last_category_result`、`category`

### Step 4 — Output Report

### 步骤 4 — 输出报告

```
=== Skill Test Coverage Audit ===
Date: [date]

SKILLS (74 total)
Specs written: 73 (99%) | Never static tested: 74 | Never category tested: 74

Skill                  | Cat      | Has Spec | Last Static | S.Result | Last Cat | C.Result | Priority
-----------------------|----------|----------|-------------|----------|----------|----------|----------
gate-check             | gate     | YES      | never       | —        | never    | —        | critical
design-review          | review   | YES      | never       | —        | never    | —        | critical
...

AGENTS (49 total)
Agent specs written: 49 (100%)

Agent                  | Category   | Has Spec | Last Spec   | Result | Last Cat | C.Result
-----------------------|------------|----------|-------------|--------|----------|----------
creative-director      | director   | YES      | never       | —      | never    | —
technical-director     | director   | YES      | never       | —      | never    | —
...

Top 5 Priority Gaps (skills with no spec, critical/high priority):
(none if all specs are written)

Skill coverage:  73/74 specs (99%)
Agent coverage:  49/49 specs (100%)
```

No file writes in audit mode.

审计模式下不写入任何文件。

Offer: "Would you like to run `/skill-test static all` to check structural
compliance across all skills? `/skill-test category all` to run category rubric
checks? Or `/skill-test spec [name]` to run a specific behavioral test?"

提议："Would you like to run `/skill-test static all` to check structural
compliance across all skills? `/skill-test category all` to run category rubric
checks? Or `/skill-test spec [name]` to run a specific behavioral test?"

---

## Phase 3: Recommended Next Steps

## 阶段 3：推荐的后续步骤

After any mode completes, offer contextual follow-up:

任何模式完成后，提供上下文相关的跟进：

- After `static [name]`: "Run `/skill-test spec [name]` to validate behavioral
  correctness if a test spec exists."
- After `static all` with failures: "Address NON-COMPLIANT skills first. Run
  `/skill-test static [name]` individually for detailed remediation guidance."
- After `spec [name]` PASS: "Update `studio-tests/catalog.yaml` to record this
  pass date. Consider running `/skill-test audit` to find the next spec gap."
- After `spec [name]` FAIL: "Review the failing assertions and update the skill
  or agent, or the test spec, to resolve the mismatch."
- After `audit`: "Start with the critical-priority gaps. Use the spec template
  at `studio-tests/templates/skill-test-spec.md` (agents:
  `agent-test-spec.md`) to create new specs."

- `static [name]` 之后："若存在测试规格，运行 `/skill-test spec [name]` 以验证行为
  正确性。"
- 带失败的 `static all` 之后："先处理 NON-COMPLIANT 技能。逐个运行
  `/skill-test static [name]` 以获取详细整改指导。"
- `spec [name]` 为 PASS 之后："更新 `studio-tests/catalog.yaml` 以记录本次
  通过日期。考虑运行 `/skill-test audit` 以找出下一个规格缺口。"
- `spec [name]` 为 FAIL 之后："审查失败的断言，并更新技能
  或智能体，或测试规格，以解决不一致。"
- `audit` 之后："从关键优先级缺口开始。使用
  `studio-tests/templates/skill-test-spec.md` 处的规格模板（智能体：
  `agent-test-spec.md`）来创建新规格。"
