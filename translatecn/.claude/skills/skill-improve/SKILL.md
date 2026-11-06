---
name: skill-improve
description: "Improve a skill via a test-fix-retest loop — static checks, targeted fixes, keep or revert on score change."
argument-hint: "[skill-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/skill-improve/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: skill-improve
description: "通过测试-修复-重测循环改进某个技能 — 静态检查、针对性修复、按分数变化保留或回退。"
argument-hint: "[skill-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/skill-improve/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅在重大选择上询问 · 自主模式记录后继续；
`automation_always_ask` 类别总是询问）。

# Skill Improve
# 技能改进

Runs an improvement loop on a single skill:
test → fix → retest → keep or revert.
对单个技能运行改进循环：
测试 → 修复 → 重测 → 保留或回退。

Its score comes from `/skill-test` static and category checks, which read the
skill rather than run it: a better score means a better-written skill, not proof
that it behaves better. To check behaviour, run the skill on a real request
before and after the change.
其分数来自 `/skill-test` 的静态与类别检查，这些检查是读取技能而非
运行技能：分数更高意味着技能写得更好，而不是其行为更好的证明。
要检查行为，请在变更前后用真实请求运行该技能。

---

## Phase 1: Parse Argument
## 阶段 1：解析参数

Read the skill name from the first argument. If missing, output usage and stop:
从第一个参数读取技能名。若缺失，则输出用法并停止：

```
Usage: /skill-improve [skill-name]
Example: /skill-improve tech-debt
```

Verify `.claude/skills/[name]/SKILL.md` exists. If not, stop with:
"Skill '[name]' not found."
核验 `.claude/skills/[name]/SKILL.md` 存在。若不存在，则以如下信息停止：
"Skill '[name]' not found."

Glob `CCGS Skill Testing Framework/catalog.yaml`. When it exists, say so first:
"`CCGS Skill Testing Framework/` was renamed `studio-tests/` in 1.2.0, and this
skill reads only `studio-tests/`. Move any specs you wrote there; UPGRADING.md
(v1.1.3 → v1.2.0, `studio-tests/`) says how." Then go on.
用 Glob 查找 `CCGS Skill Testing Framework/catalog.yaml`。当它存在时，先说：
"`CCGS Skill Testing Framework/` 在 1.2.0 中已更名为 `studio-tests/`，而此
技能只读取 `studio-tests/`。请把你写在那里的任何规范移过去；UPGRADING.md
（v1.1.3 → v1.2.0，`studio-tests/`）说明了做法。" 然后继续。

---

## Phase 2: Baseline Test
## 阶段 2：基线测试

Run `/skill-test static [name]` and record the baseline score:
- Count of FAILs
- Count of WARNs
- Which specific checks failed (Check 1–7)
运行 `/skill-test static [name]` 并记录基线分数：
- FAIL 的数量
- WARN 的数量
- 哪些具体检查失败（检查 1–7）

Display to the user:
向用户显示：
```
Static baseline:   [N] failures, [M] warnings
Failing: Check 4 (no ask-before-write), Check 5 (no handoff)
```

If the static result is **NOT ASSESSED** (the skill file could not be read or
parsed), stop and report it with its reason: there is no score to improve, and
0 FAILs from a file nobody could read is not a clean result.
若静态结果为 **NOT ASSESSED**（无法读取或解析该技能文件），
则停止并附原因报告它：没有可改进的分数，而且
无人能读取的文件给出的 0 个 FAIL 并不是干净的结果。

If baseline is 0 FAILs and 0 WARNs, note it and proceed to Phase 2b.
若基线为 0 个 FAIL 且 0 个 WARN，注明之并进入阶段 2b。

### Phase 2b: Category Baseline
### 阶段 2b：类别基线

Look up the skill's `category:` field in `studio-tests/catalog.yaml`.
在 `studio-tests/catalog.yaml` 中查找该技能的 `category:` 字段。

If no `category:` field is found, display:
"Category: not yet assigned — skipping category checks."
and skip to Phase 3.
若未找到 `category:` 字段，显示：
"Category: not yet assigned — skipping category checks."
并跳到阶段 3。

If category is found, run `/skill-test category [name]` and record the category baseline:
- Count of FAILs
- Count of WARNs
- Which specific category rubric metrics failed
若找到类别，运行 `/skill-test category [name]` 并记录类别基线：
- FAIL 的数量
- WARN 的数量
- 哪些具体的类别评分项指标失败

Display to the user:
向用户显示：
```
Category baseline: [N] failures, [M] warnings  ([category] rubric)
```

A category result of **NOT ASSESSED** (a rubric section the skill-test could not
find or apply) is reported with its reason and is not a zero: the category
dimension is then excluded from "already passes" below.
类别结果为 **NOT ASSESSED**（技能测试找不到或无法应用的评分项小节）时，
附原因报告，且不等于零：该类别
维度随后会从下文的"已全部通过"中排除。

If BOTH static and category baselines are 0 FAILs and 0 WARNs — and neither is
NOT ASSESSED — stop:
"This skill already passes all static and category checks. No improvements needed."
若静态与类别基线**均**为 0 个 FAIL 且 0 个 WARN — 且两者都不是
NOT ASSESSED — 则停止：
"This skill already passes all static and category checks. No improvements needed."

---

## Phase 3: Diagnose
## 阶段 3：诊断

Read the full skill: `.claude/skills/[name]/SKILL.md` and every file in its `references/` folder,
if it has one — the longest skills keep each phase there. Name the file each
gap is in.
完整读取该技能：`.claude/skills/[name]/SKILL.md` 及其 `references/` 文件夹中的每个文件
（若存在）— 最长的技能会把每个阶段放在那里。指明每个
缺口所在的文件。

For each failing or warning **static** check, identify the exact gap:
对每项失败或警告的**静态**检查，指出确切的缺口：

- **Check 1 fail** → which frontmatter field is missing
- **Check 2 fail** → how many phases found vs. minimum required
- **Check 3 fail** → no verdict keywords anywhere in the skill body
- **Check 4 fail** → Write or Edit in allowed-tools but no ask-before-write language
- **Check 5 warn** → no follow-up or next-step section at the end
- **Check 6 warn** → `context: fork` set but fewer than 5 phases found
- **Check 7 warn** → argument-hint is empty or doesn't match documented modes
- **检查 1 失败** → 缺少哪个 frontmatter 字段
- **检查 2 失败** → 找到多少个阶段 vs. 所需最低数量
- **检查 3 失败** → 技能正文中任何位置都没有裁决关键词
- **检查 4 失败** → allowed-tools 中有 Write 或 Edit，但没有写入前询问的措辞
- **检查 5 警告** → 结尾没有后续或下一步小节
- **检查 6 警告** → 设置了 `context: fork` 但找到的阶段少于 5 个
- **检查 7 警告** → argument-hint 为空，或与文档所述模式不匹配

For each failing or warning **category** check (if category was assigned in Phase 2b),
identify the exact gap in the skill's text. For example:
- If G2 fails (gate mode, director panel width): skill body does not size the
  PHASE-GATE panel from `modes.workflow` (PR at `minimal`, TD + PR at `standard`,
  all 4 at `full`)
- If A2 fails (authoring, no per-section May-I-write): skill asks once at the end, not
  before each section write
- If T3 fails (team, BLOCKED not surfaced): skill doesn't halt dependent work on blocked agent
对每项失败或警告的**类别**检查（若在阶段 2b 已分配类别），
指出技能文本中的确切缺口。例如：
- 若 G2 失败（门禁模式、总监小组宽度）：技能正文没有依据 `modes.workflow`
  调整 PHASE-GATE 小组的规模（`minimal` 为 PR，`standard` 为 TD + PR，
  `full` 为全部 4 个）
- 若 A2 失败（撰写、无逐小节 May-I-write）：技能在结尾只问一次，而不是
  在每个小节写入之前
- 若 T3 失败（团队、未呈现 BLOCKED）：技能没有因智能体被阻塞而停止其依赖工作

Show the full combined diagnosis to the user before proposing any changes.
在提议任何更改之前，向用户展示完整的综合诊断。

---

## Phase 4: Propose Fix
## 阶段 4：提议修复

Write a targeted fix for each failure and warning. Show the proposed changes
as clearly marked before/after blocks. Only change what is failing — do not
rewrite sections that are passing. In a skill with a `references/` folder, a
fix to a phase's steps goes in that phase's `references/` file, not back into
`SKILL.md`; the question below then names each file the fix changes.
为每项失败与警告撰写针对性修复。以清晰标注的前/后区块
展示拟议更改。只更改失败之处 — 不要
重写已通过的小节。在带有 `references/` 文件夹的技能中，
对某阶段步骤的修复应写入该阶段的 `references/` 文件，而不是写回
`SKILL.md`；下文的问题随后会逐一点名该修复更改的文件。

Ask: "May I write this improved version to `.claude/skills/[name]/SKILL.md`?"
询问："May I write this improved version to `.claude/skills/[name]/SKILL.md`?"

If the user says no, stop here.
若用户说否，就此停止。

---

## Phase 5: Write and Retest
## 阶段 5：写入与重测

Record the current content of each file the fix changes — the exact text, kept
in this conversation — so Phase 6 can restore it.
记录该修复更改的每个文件的当前内容 — 确切文本，保留在
本次会话中 — 以便阶段 6 可以恢复它。

Write the improved skill to `.claude/skills/[name]/SKILL.md`, and to each
`references/` file the fix changes.
将改进后的技能写入 `.claude/skills/[name]/SKILL.md`，以及该修复更改的每个
`references/` 文件。

Re-run `/skill-test static [name]` and record the new static score — measured by that run, never stated from the edit.
If a category was assigned, also re-run `/skill-test category [name]` and record the new category score.
重跑 `/skill-test static [name]` 并记录新的静态分数 — 由该次运行测得，绝不凭编辑自行宣称。
若已分配类别，还要重跑 `/skill-test category [name]` 并记录新的类别分数。

Display the comparison:
显示对比：
```
Static:   Before [N] failures, [M] warnings  →  After [N'] failures, [M'] warnings
Category: Before [N] failures, [M] warnings  →  After [N'] failures, [M'] warnings  (if applicable)
Combined: [before] → [after] (improved / no change / worse)
```

`[before]` and `[after]` are the Phase 6 combined counts — failures plus
warnings, both dimensions — e.g. `Combined: 3 → 0 (improved)`.
`[before]` 与 `[after]` 是阶段 6 的综合计数 — 失败加
警告，两个维度 — 例如 `Combined: 3 → 0 (improved)`。

---

## Phase 6: Verdict
## 阶段 6：裁决

Count the combined failure total: static FAILs + category FAILs + static WARNs + category WARNs.
**A re-test that comes back NOT ASSESSED** (for example, the edit broke the
frontmatter so the file no longer parses) is never an improvement, whatever its
counts: take the "did not improve" branch below.
统计综合失败总数：静态 FAIL + 类别 FAIL + 静态 WARN + 类别 WARN。
**重测返回 NOT ASSESSED**（例如编辑破坏了
frontmatter，文件不再可解析）永远不是改进，无论其
计数如何：走下文的"未改进"分支。

**If combined score improved (combined failure count is lower than baseline):**
Report: "Score improved. Changes kept."
Show a summary of what was fixed in each dimension.
**若综合分数改进（综合失败计数低于基线）：**
报告："Score improved. Changes kept."
展示每个维度中修复内容的摘要。

**If combined score is the same or worse:**
Report: "Combined score did not improve."
Show what changed and why it may not have helped.
Ask: "May I restore `.claude/skills/[name]/SKILL.md` to the content it had before this run?"
— naming every file Phase 5 wrote.
If yes: write the content recorded in Phase 5 back to each file with Write; if no, leave the files as written. Never
`git checkout` it — that returns the last *committed* version and discards any edits
made before this run that were not yet committed.
**若综合分数相同或更差：**
报告："Combined score did not improve."
展示更改了什么，以及为何它可能没有帮助。
询问："May I restore `.claude/skills/[name]/SKILL.md` to the content it had before this run?"
— 并点名阶段 5 写入的每个文件。
若答是：用 Write 将阶段 5 记录的内容写回每个文件；若答否，则保持文件为已写入状态。绝不
对它执行 `git checkout` — 那会返回最后*已提交*的版本，并丢弃本次运行之前
做出但尚未提交的任何编辑。

---

## Phase 7: Next Steps
## 阶段 7：后续步骤

- Run `/skill-test static all` to find the next skill with failures.
- Run `/skill-improve [next-name]` to continue the loop on another skill.
- Run `/skill-test audit` to see overall coverage progress.
- 运行 `/skill-test static all` 找出下一个有失败的技能。
- 运行 `/skill-improve [next-name]` 在另一个技能上继续该循环。
- 运行 `/skill-test audit` 查看整体覆盖进展。
