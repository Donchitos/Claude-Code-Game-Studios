---
name: dev-story
description: "Implements one story in code with tests, following its ADRs. Use when the user says to build, implement or start working on a story. Not for checking readiness beforehand or closing the story after."
argument-hint: "[story-path]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/session-state.sh *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(godot *), Bash(mkdir -p production/qa/evidence/*)
model: sonnet
---
---
name: dev-story
description: "在代码中实现一个故事并附带测试，遵循其 ADR。当用户要求构建、实现或开始处理某个故事时使用。不用于事先检查就绪度或事后收尾故事。"
argument-hint: "[story-path]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/session-state.sh *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(godot *), Bash(mkdir -p production/qa/evidence/*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,gate_level,engine_values,specialists,perf_budgets,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.
以上已解析 — 直接使用。无配置块 → 使用
`.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.
使用问题工具提问。若没有该工具，将选项编号列出并结束本轮
以等待。被跳过或忽略的问题不是答案：请用纯文本再次提问。

# Dev Story
# 开发故事

Implements one story: checks it can start, marks it In Progress, hands the code to
the right programmer agent with a brief built from the story, then checks the
result parses and looks right, and hands off.
实现一个故事：检查它能否开始、将其标记为 In Progress、附上一份由故事构建的简报把代码交给
合适的程序员智能体，然后检查结果能否解析、看起来是否正确，并完成交接。

**Writes** (each after an ask that names it): the story's `Status`, `Last Updated`
and `## Files`, and its `production/sprint-status.yaml` entry. The programmer agents
write the code and tests under the code root and test root
(`.claude/docs/code-root-resolution.md`). The session checkpoint and the evidence
stamp are written without an ask.
**写入**（每项都在一次点名它的询问之后进行）：故事的 `Status`、`Last Updated`
和 `## Files`，以及其在 `production/sprint-status.yaml` 中的条目。程序员智能体
在代码根和测试根（`.claude/docs/code-root-resolution.md`）下写入代码和测试。
会话检查点和证据戳记无需询问即可写入。
**Next:** `/story-done [story-path]`; at `standard` and `full`, `/code-review
[files]` first.
**下一步：** `/story-done [story-path]`；在 `standard` 和 `full` 下，先运行 `/code-review
[files]`。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).
询问遵循 `.claude/docs/automation-modes.md`（collaborative 始终询问，guided
就重大选择询问，autonomous 记录并继续；`automation_always_ask`
类别始终询问）。

Checklist (copy it and tick as you go):
清单（抄下来，边做边勾选）：

```
- [ ] Phase 1: story found, tier resolved
- [ ] Phase 2: prerequisites checked (ADR, manifest, dependencies)
- [ ] Phase 3: story marked In Progress (one ask)
- [ ] Phase 4: programmer and engine specialist chosen
- [ ] Phase 5: work handed out with a full brief
- [ ] Phase 6: finished? parse check, run and look, one Run result line
- [ ] Phase 7: summary, ## Files, checkpoint, closing block
```

## Phase 1: The story
## 阶段 1：故事

The text typed after the skill name is the story path. With nothing typed, take the
story the checkpoint in `production/session-state/active.md` names and confirm it:
"Continuing work on [title] — is that correct?" None there: ask "Which story are we
implementing?" with the `TODO` rows of `bash .claude/scripts/story-facts.sh --all`
as options. No story file under `production/epics/` at all: stop with
"No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."
技能名之后输入的文本就是故事路径。若什么都没输入，则取
`production/session-state/active.md` 中检查点所指的故事并确认它：
"Continuing work on [title] — is that correct?" 若其中没有：询问 "Which story are we
implementing?"，并以 `bash .claude/scripts/story-facts.sh --all` 的 `TODO` 行
作为选项。如果 `production/epics/` 下完全没有故事文件：以
"No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."
停止。

`bash .claude/scripts/story-facts.sh <story-path>` gives its type, layer, TR-IDs,
ADRs and dependencies. Then read the story in full.
`bash .claude/scripts/story-facts.sh <story-path>` 给出其类型、层级、TR-ID、
ADR 和依赖。然后完整读取该故事。

**Tier.** `workflow` for the story's system, keyed on the GDD filename stem of its
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`; the `[system]` of its TR-ID only when
there is no GDD path): that system's `system_overrides` row if there is one, else the
project value. Say it in your first reply: `Tier: workflow [value]`. That value, never
`rigor` or `qa.level`, picks the Phase 2 column and the closing Next step.
**层级。** 针对故事所属系统的 `workflow`，以其 `GDD:` 路径的 GDD 文件名主干为键
（`design/gdd/<stem>.md` → `<stem>`；仅当没有 GDD 路径时才使用其 TR-ID 的 `[system]`）：
若有该系统对应的 `system_overrides` 行则使用该行，否则使用项目值。在首次回复中说明：`Tier: workflow [value]`。该值 — 而非
`rigor` 或 `qa.level` — 决定第 2 节使用哪一列以及收尾的下一步。

## Phase 2: Can it start?
## 阶段 2：能否开始？

| Input | `full` | `standard` | `minimal` |
|---|---|---|---|
| TR registry `docs/architecture/tr-registry.yaml` | missing: **stop**, "Run `/architecture-review` to bootstrap it" | optional | not expected |
| The ADR the story names | missing, `Proposed`, `Deprecated` or `Superseded`: **stop** | the same, only when the story names one | the same, only when the story names one |
| Control manifest `docs/architecture/control-manifest.md` | missing: warn, go on | missing: warn, go on | not expected |
| 输入 | `full` | `standard` | `minimal` |
|---|---|---|---|
| TR 注册表 `docs/architecture/tr-registry.yaml` | 缺失：**停止**，"Run `/architecture-review` to bootstrap it" | 可选 | 不作要求 |
| 故事所指的 ADR | 缺失、`Proposed`、`Deprecated` 或 `Superseded`：**停止** | 同上，仅当故事指定了 ADR 时 | 同上，仅当故事指定了 ADR 时 |
| 控制清单 `docs/architecture/control-manifest.md` | 缺失：警告，继续 | 缺失：警告，继续 | 不作要求 |

A story whose ADR field reads `N/A — [reason]` names none.
若故事的 ADR 字段为 `N/A — [reason]`，则它未指定任何 ADR。

**The ADR.** `bash .claude/scripts/adr-status.sh <ADR id>` gives its status and
`version`. Stop messages: `Proposed` — "ADR-NNNN is still Proposed. Accept it with
`/architecture-decision accept ADR-NNNN` before implementing." `Deprecated` or
`Superseded` — "ADR-NNNN is [status]; point the story at [successor] (edit its ADR
field; `/create-stories` never rewrites an existing story) before implementing."
`NOT_FOUND` — "ADR file not found. Run `/architecture-decision`, or correct the
story's ADR field."
**ADR。** `bash .claude/scripts/adr-status.sh <ADR id>` 给出其状态和
`version`。停止消息：`Proposed` — "ADR-NNNN is still Proposed. Accept it with
`/architecture-decision accept ADR-NNNN` before implementing。" `Deprecated` 或
`Superseded` — "ADR-NNNN is [status]; point the story at [successor] (edit its ADR
field; `/create-stories` never rewrites an existing story) before implementing。"
`NOT_FOUND` — "ADR file not found. Run `/architecture-decision`, or correct the
story's ADR field。"

**Do not open the ADR.** The story's ADR Decision Summary and Implementation Notes
are what the programmer reads instead. Compare the ADR's `version` with the story's
`ADR Version`:
**不要打开 ADR。** 程序员改读故事的 ADR Decision Summary 和 Implementation Notes。
将 ADR 的 `version` 与故事的 `ADR Version` 比较：

- equal, or the story has no `ADR Version` (written before the stamp), or both are
  `unversioned`: trust the story. Note the last two in the summary ("summary
  trusted unverified").
- they differ, or the ADR is `unversioned` but the story names a date: read
  `references/version-mismatch.md`. On a match, do not load it.
- 相等，或故事没有 `ADR Version`（在戳记之前写入），或两者都是
  `unversioned`：信任故事。在摘要中记下后两种情况（"summary
  trusted unverified"）。
- 两者不同，或 ADR 为 `unversioned` 但故事指定了日期：读取
  `references/version-mismatch.md`。若匹配，则不要加载它。

Never treat an absent stamp as a stale one: unknown falls back to the story, and
`/story-readiness` and `/code-review` are the checks that catch drift later.
绝不把缺失的戳记当作过时的戳记：未知情况回退到故事，
而 `/story-readiness` 和 `/code-review` 是后来捕捉漂移的检查。

**The manifest.** When it exists, compare its `Manifest Version` line with the
story's. They differ: read `references/version-mismatch.md`.
**清单。** 当它存在时，将其 `Manifest Version` 行与故事的比较。若不同：读取 `references/version-mismatch.md`。

**Dependencies.** For each path on the story's Depends on line,
`bash .claude/scripts/story-facts.sh <path>`. Not `COMPLETE`: ask "[this story]
depends on [dependency], which is [status], not Complete. How do you want to go
on?" Options: Proceed anyway — I accept the risk / Stop — I'll finish the
dependency first / It is done, the status was never updated — mark it Complete.
Stop: the story is BLOCKED (Phase 7), no agent. Mark it: ask "May I set [path]
Status to Complete?" first. Proceed: note it under Deviations. `NOT_FOUND`: warn
"Dependency story not found: [path]".
**依赖。** 对故事 Depends on 行上的每个路径，运行
`bash .claude/scripts/story-facts.sh <path>`。若非 `COMPLETE`：询问 "[this story]
depends on [dependency], which is [status], not Complete. How do you want to go
on?" 选项：Proceed anyway — I accept the risk / Stop — I'll finish the
dependency first / It is done, the status was never updated — mark it Complete。
选择 Stop：故事为 BLOCKED（阶段 7），不启动智能体。选择 Mark it：先询问 "May I set [path]
Status to Complete?"。选择 Proceed：在 Deviations 下记录。`NOT_FOUND`：警告
"Dependency story not found: [path]"。

Any stop above: no agent runs. Go to Phase 7 and write the BLOCKED checkpoint.
上述任何停止情况：不启动智能体。转到阶段 7 并写入 BLOCKED 检查点。

## Phase 3: Mark it In Progress
## 阶段 3：标记为 In Progress

Before any agent, ask once: "May I mark this story In Progress? This sets `Status`
and `Last Updated` in [story path] and its entry in `production/sprint-status.yaml`,
and at the end lists the files changed under its `## Files`." Leave the sprint file
out of the question when it does not exist. Put what you will do next before the
question: the question is the last thing in the reply. On yes:
在任何智能体之前，询问一次："May I mark this story In Progress? This sets `Status`
and `Last Updated` in [story path] and its entry in `production/sprint-status.yaml`,
and at the end lists the files changed under its `## Files`。" 当冲刺文件不存在时，
不要在该问题中提及它。把接下来要做的事放在
问题之前：问题应是回复中的最后一项。若回答是：

- `bash .claude/scripts/md-section.sh set-field <story> Status "In Progress"`, then
  `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`. At `minimal` the
  story file is the only record of progress.
- `production/sprint-status.yaml`: this story's entry gets `status: in-progress` and
  the top-level `updated` today. No file: say `Sprint status not updated:
  production/sprint-status.yaml absent`.
- `bash .claude/scripts/md-section.sh set-field <story> Status "In Progress"`，然后
  `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`。在 `minimal` 下，
  故事文件是进度的唯一记录。
- `production/sprint-status.yaml`：该故事的条目获得 `status: in-progress`，
  顶层 `updated` 为今天。若无文件：说明 `Sprint status not updated:
  production/sprint-status.yaml absent`。

Declined: change neither, print `Story not marked In Progress — declined` in the
summary, and go on.
若被拒绝：两者都不改动，在摘要中打印 `Story not marked In Progress — declined`，然后继续。

## Phase 4: Who implements it
## 阶段 4：由谁实现

**Config/Data stories need no agent.** Show each value change as from → to, ask "May
I write [data file]?", and edit it. Go to Phase 6.
**Config/Data 故事不需要智能体。** 以 from → to 形式展示每个值变更，询问 "May
I write [data file]?"，然后编辑它。转到阶段 6。

| Story | Programmer agent |
|---|---|
| Foundation layer, any type | `engine-programmer` |
| Type UI | `ui-programmer` |
| Type Visual/Feel | `gameplay-programmer` |
| Core or Feature, gameplay | `gameplay-programmer` |
| Core or Feature, AI or pathfinding | `ai-programmer` |
| Core or Feature, networking | `network-programmer` |
| 故事 | 程序员智能体 |
|---|---|
| 基础层，任意类型 | `engine-programmer` |
| 类型 UI | `ui-programmer` |
| 类型 Visual/Feel | `gameplay-programmer` |
| Core 或 Feature，玩法 | `gameplay-programmer` |
| Core 或 Feature，AI 或寻路 | `ai-programmer` |
| Core 或 Feature，网络 | `network-programmer` |

**The engine specialist, for every code story.** From the `specialists` line above:
`code` (`specialists.code`, the language specialist: it tells a Godot C# project
from a GDScript one, which `engine.name` cannot), plus `shader` when the story
touches shaders or materials and `ui` for a UI story; `primary` (the generic engine
specialist) when `code` is `unset`. Name no specialist from memory: the line is the project's
choice. Every value `unset` and no `primary`: say "No engine specialist configured"
and go on without one.
**引擎专家，适用于每个代码故事。** 依据上文的 `specialists` 行：
`code`（`specialists.code`，即语言专家：它能区分 Godot C# 项目和 GDScript 项目，而 `engine.name` 无法做到），
另外当故事涉及着色器或材质时加上 `shader`，UI 故事加上 `ui`；当 `code` 为 `unset` 时使用 `primary`（通用引擎
专家）。不要凭记忆指定专家：该行是项目的
选择。所有值都 `unset` 且没有 `primary`：说明 "No engine specialist configured"
并在没有专家的情况下继续。

## Phase 5: Hand out the work
## 阶段 5：派发工作

Hand the implementation to the programmer agent. The brief points at files; never
paste whole documents into it.
将实现交给程序员智能体。简报指向文件；绝不
把整份文档粘贴进去。

- **Objective:** implement [story path] against its acceptance criteria, within its
  Out of Scope boundaries.
- **Sources:**
  1. The story file. It carries the criteria, the boundaries and the QA test cases.
  2. Each TR-ID (`TR-[system]-NNN`) to look up: in
     `docs/architecture/tr-registry.yaml`, the lines matching `id: <TR-ID>\s*$`.
     Its `requirement` text is the source of truth, not text quoted in the story.
  3. The ADR guidance, **inline**: the story's ADR Decision Summary and
     Implementation Notes. Never the ADR path.
  4. The control manifest's [Layer] Layer Rules, by section.
  5. `naming.*` in `project.yaml` and the `perf_budgets` line above.
  6. The test file path from the story's Test Evidence section.
- **Tests,** by `qa.level`, for Logic and Integration stories:
  - `minimal`: "Do not write a test file for this story — test evidence is waived at
    `qa.level: minimal`." Say it: an omitted line and a forgotten one look the same
    to the agent.
  - `standard`: "Write the test at [path] with the code. Each acceptance criterion
    needs at least one test function." Naming per engine from
    `.claude/rules/test-standards.md`. No random seeds, no time-dependent
    assertions, no external I/O.
  - `full`: the same, and "every criterion must be covered: `/story-done` blocks on
    any untested one."
- **Output:** the files created or changed, the test functions written, any
  question or blocker, and whether it finished.
- **Boundaries:** write code only under the resolved code root and tests only under
  the test root. Code root unresolved: write nothing and report it. Touch no file
  outside the story's scope: report the need instead. Doc comments on public APIs.
  An architectural choice the ADR does not cover: report the plan, don't decide it.
  No helper or abstraction for a one-time use, no error handling for cases that
  cannot happen (validate at input and data-file boundaries only), and general logic,
  never a value special-cased so a test passes.
- **目标：** 按验收标准实现 [story path]，并遵守其
  Out of Scope 边界。
- **来源：**
  1. 故事文件。它包含标准、边界和 QA 测试用例。
  2. 每个要查询的 TR-ID（`TR-[system]-NNN`）：在
     `docs/architecture/tr-registry.yaml` 中匹配 `id: <TR-ID>\s*$` 的行。
     其 `requirement` 文本是事实来源，而不是故事中引用的文本。
  3. ADR 指导，**内联**：故事的 ADR Decision Summary 和
     Implementation Notes。绝不要给 ADR 路径。
  4. 控制清单的 [Layer] Layer Rules，按节。
  5. `project.yaml` 中的 `naming.*` 以及上文的 `perf_budgets` 行。
  6. 故事 Test Evidence 节中的测试文件路径。
- **测试**，按 `qa.level`，针对逻辑和集成故事：
  - `minimal`："Do not write a test file for this story — test evidence is waived at
    `qa.level: minimal`。" 要说出来：省略一行与忘记一行
    对智能体来说看起来一样。
  - `standard`："Write the test at [path] with the code. Each acceptance criterion
    needs at least one test function。" 命名按引擎依据
    `.claude/rules/test-standards.md`。不使用随机种子、不使用依赖时间的
    断言、不使用外部 I/O。
  - `full`：同上，并加上 "every criterion must be covered: `/story-done` blocks on
    any untested one。"
- **输出：** 创建或更改的文件、编写的测试函数、任何
  问题或阻塞项，以及是否完成。
- **边界：** 只在已解析的代码根下写代码，只在测试根下写测试。
  代码根未解析：什么都不写并报告。不要触碰故事范围之外的文件：
  改为报告需要。在公共 API 上写文档注释。
  ADR 未覆盖的架构选择：报告计划，不要做决定。
  不为一次性使用创建辅助函数或抽象，不为不可能发生的情况添加错误处理
  （只在输入和数据文件边界验证），使用通用逻辑，
  绝不为了让测试通过而对某个值特例处理。

**Say what the brief leaves out, to both readers.** Inputs Phase 2 found absent
(the TR registry, an ADR, the manifest) are left out: tell the agent "No [input] is
passed — it does not exist at this tier; do not go looking for it", and tell the
user one line before handing out: `Briefing omits: [inputs] — implementing against
the acceptance criteria and the [GDD | brief].`
**向双方读者说明简报省略了什么。** 阶段 2 发现缺失的输入
（TR 注册表、ADR、清单）会被省略：告诉智能体 "No [input] is
passed — it does not exist at this tier; do not go looking for it"，并在派发前
向用户说明一行：`Briefing omits: [inputs] — implementing against
the acceptance criteria and the [GDD | brief].`

**Then hand the engine check to the specialist** once the programmer reports.
Brief: check the changed files for engine-API use that is wrong or changed in
[engine + version], against `docs/engine-reference/<engine>/`; return a list of
file, line, problem, fix; edit nothing. A problem that breaks a criterion goes back
to the programmer once; the rest go in the summary.
**然后在程序员报告后把引擎检查交给专家。**
简报：对照 `docs/engine-reference/<engine>/`，检查更改的文件中是否有在
[engine + version] 中错误或已变更的引擎 API 用法；返回一份
文件、行、问题、修复的列表；不要编辑任何内容。破坏某个标准的问题会退回
给程序员一次；其余进入摘要。

## Phase 6: Check the result
## 阶段 6：检查结果

**Did the agent finish?** It stopped early, hit a limit, or its report ends
mid-task: the story is **INCOMPLETE**. Say so as the headline, list what exists,
name the breakage, offer to resume the agent. Never print "Implementation Complete"
over it, and leave the status as it is.
**智能体完成了吗？** 它提前停止、触及限制，或其报告在任务中途结束：
故事为 **INCOMPLETE**。把它作为标题说明，列出已有内容，
点名断裂处，提议恢复该智能体。绝不在这之上打印 "Implementation Complete"，
并保持状态不变。

**Did it write what it said?** First verify the artifact: a file the agent's report
names that is not on disk is a failed step, however fluent the report: resume the agent and name the missing
file. A report of BLOCKED, an error, or "cannot complete": say so at once, go no
further past what it blocks, and give a partial report
(`.claude/docs/error-recovery-protocol.md`). Scope too large: split it with
`/create-stories`. The ADR and the story disagree: report the conflict; never guess.
**它写的内容与所述一致吗？** 首先验证产物：智能体报告点名但磁盘上不存在的文件
是失败的步骤，无论报告多么流畅：恢复该智能体并点名缺失的
文件。报告为 BLOCKED、错误或 "cannot complete"：立即说明，
不要越过它阻塞的范围继续，并给出部分报告
（`.claude/docs/error-recovery-protocol.md`）。范围过大：用
`/create-stories` 拆分它。ADR 与故事不一致：报告冲突；绝不猜测。

**Is the test there?** At `qa.level: standard` and `full`, for a Logic or Integration
story, look for the file at the Test Evidence path. Missing: at the type's BLOCKING
level on the `gate_level` line, flag "story unverifiable — test required before
`/story-done`"; at ADVISORY, note it as a recommendation. At `minimal` there is
nothing to check: tests are waived.
**测试在那儿吗？** 在 `qa.level: standard` 和 `full` 下，对于逻辑或集成
故事，在 Test Evidence 路径查找该文件。缺失时：若该类型在 `gate_level` 行上为 BLOCKING
级别，标记 "story unverifiable — test required before
`/story-done`"；若为 ADVISORY，则作为建议记录。在 `minimal` 下
无需检查：测试被豁免。

**Does it parse?** Run the check whose exit code answers it, and report the
command, the exit code and any error lines:
**能解析吗？** 运行其退出码能回答此问题的检查，并报告
命令、退出码和任何错误行：

- **Godot:** `godot --headless --path . --import` once, then
  `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<each changed .gd>`.
  Exit 1 means a script did not load; its `PARSE FAIL:` line names it. Never use
  `--check-only`, and `--import` alone is no parse check. The executable is the one
  `commands.test` names when its file name says godot (a wrapper such as `bash
  run-tests.sh` is not the editor), else `engine.path`, else `godot`. Never search the disk for
  one: when none of the three runs, the check is not verified.
- **Unity, Unreal:** read `references/engine-checks.md`.
- **No engine executable:** `parse NOT VERIFIED — engine binary not available`.
  Never infer from reading the code that it parses.
- **Godot：** 先运行一次 `godot --headless --path . --import`，然后运行
  `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<each changed .gd>`。
  退出码 1 表示某个脚本未加载；其 `PARSE FAIL:` 行会点名它。绝不要使用
  `--check-only`，单独使用 `--import` 也不是解析检查。可执行文件是
  文件名含 godot 时 `commands.test` 所指的那个（诸如 `bash
  run-tests.sh` 的包装器不是编辑器），否则是 `engine.path`，再否则是 `godot`。绝不要到磁盘上搜索
  可执行文件：当这三者都未运行时，该检查未经验证。
- **Unity、Unreal：** 读取 `references/engine-checks.md`。
- **无引擎可执行文件：** `parse NOT VERIFIED — engine binary not available`。
  绝不通过阅读代码来推断它能解析。

**Run it and look** (`.claude/docs/run-and-observe.md`). For every story a player
can see (every Visual/Feel and UI story, and any other with a surface): launch
straight into the scene the story touched, capture a screenshot straight into
`production/qa/evidence/[story-slug]/` (`[story-slug]` is the story file's name
without `.md`; `mkdir -p` the folder first), stamp it with
`bash .claude/scripts/review-receipts.sh hash <each changed file> > production/qa/evidence/[story-slug]/stamp.txt`,
then open the image and compare it with the criteria. Not waived at `qa.level:
minimal`. Report exactly one line, plain text starting `Run result:` (no bold:
`/story-done` reads it as written):
**运行并观察**（`.claude/docs/run-and-observe.md`）。对于每个玩家能看到的故事
（每个 Visual/Feel 和 UI 故事，以及任何其他具有可见表面的故事）：直接启动到
故事涉及的场景，直接将截图捕获到
`production/qa/evidence/[story-slug]/`（`[story-slug]` 是故事文件名
去掉 `.md`；先 `mkdir -p` 该文件夹），用
`bash .claude/scripts/review-receipts.sh hash <each changed file> > production/qa/evidence/[story-slug]/stamp.txt`
为它盖上戳记，然后打开图片并与标准对比。在 `qa.level:
minimal` 下不放宽。只报告一行，以 `Run result:` 开头的纯文本（不加粗：
`/story-done` 按原样读取）：

- `Run result: OBSERVED — <what was on screen>` with the retained path;
- `Run result: NOT VERIFIED — <reason>` (no engine, nothing captured); at the
  default gate level this blocks a Visual/Feel or UI story at `/story-done`;
- `Run result: N/A — <reason>` for a story with nothing observable; the reason says
  why nothing is (`/story-done` does not accept "it's a Logic story").
- `Run result: OBSERVED — <what was on screen>`，附保留路径；
- `Run result: NOT VERIFIED — <reason>`（无引擎，未捕获任何内容）；在
  默认门禁级别下，这会在 `/story-done` 处阻塞 Visual/Feel 或 UI 故事；
- `Run result: N/A — <reason>` 用于没有任何可观察内容的故事；原因需说明
  为何没有可观察内容（`/story-done` 不接受 "it's a Logic story"）。

Only the feel half of a Visual/Feel criterion (timing, weight) is DEFERRED to
`/team-qa`: a still cannot show it.
Visual/Feel 标准中只有手感部分（时机、重量）会 DEFERRED 到
`/team-qa`：静态画面无法呈现它。

This skill pre-approves `godot` on PATH. An engine run through `engine.path` or
the executable `commands.test` names asks first: the user approves it once, or
adds `Bash(<that executable> *)` to `.claude/settings.local.json`.
此技能预先授权 PATH 上的 `godot`。通过 `engine.path` 或
`commands.test` 所指可执行文件运行的引擎会先询问：用户批准一次，或在
`.claude/settings.local.json` 中添加 `Bash(<that executable> *)`。

## Phase 7: Summary, files, checkpoint
## 阶段 7：摘要、文件、检查点

```
## Implementation Complete: [title]

**Files changed**:
- `[code root path]` — created / modified ([what])
- `[test path]` — [N] test functions
**Test evidence**: waived at `qa.level: minimal` — no test was required or written   (Logic/Integration at minimal, instead of the test line)
**Verification**: [command] — [exit code and result | parse NOT VERIFIED — <reason>]

**Acceptance criteria**:
- [x] [criterion] — [file:function | test name | OBSERVED in <image path>]
- [ ] [criterion] — DEFERRED: feel, needs a playtest
**Deviations**: [None | files outside scope, an accepted dependency or version risk]
**Engine risks**: [None | the specialist's findings]
**Blockers**: [None | each]
```

At `qa.level: standard` and `full`, add: "Run your test suite and confirm the new
tests pass before `/story-done`: it checks that the test file exists, and runs
nothing." At `minimal` leave that out: there are no tests to run. For a Visual/Feel
or UI story with no retained image, add: "A retained screenshot under
`production/qa/evidence/[story-slug]/` is required before `/story-done`" (and, for
Visual/Feel, the sign-off in `production/qa/evidence/[story-slug]-evidence.md`).
在 `qa.level: standard` 和 `full` 下，添加："Run your test suite and confirm the new
tests pass before `/story-done`: it checks that the test file exists, and runs
nothing。" 在 `minimal` 下省略此句：没有测试要运行。对于没有保留图像的 Visual/Feel
或 UI 故事，添加："A retained screenshot under
`production/qa/evidence/[story-slug]/` is required before `/story-done`"（并且对于
Visual/Feel，还包括 `production/qa/evidence/[story-slug]-evidence.md` 中的签核）。

**`## Files`.** Replace the section's body with the list of changed code and test
files, one per line, as the Phase 3 ask said:
`bash .claude/scripts/md-section.sh replace <story> "Files"` with the list on stdin.
A story with no such section: add `## Files` and the list at its end, with a file
edit, never a shell command (a shell write skips the project's write checks). Skip
this when the Phase 3 ask was declined.
**`## Files`。** 用更改的代码和测试文件列表替换该节正文，每行一个，正如阶段 3 的询问所述：
`bash .claude/scripts/md-section.sh replace <story> "Files"`，列表通过 stdin 传入。
若故事没有该节：用文件编辑在其末尾添加 `## Files` 和列表，
绝不用 shell 命令（shell 写入会跳过项目的写入检查）。当阶段 3 的询问被拒绝时，
跳过此项。

**The checkpoint**, on every outcome. Pipe the block to
`bash .claude/scripts/session-state.sh checkpoint`, which replaces the old one:
**检查点**，在每种结果下都要写。将块通过管道传给
`bash .claude/scripts/session-state.sh checkpoint`，它会替换旧的检查点：

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /dev-story — [story path] ([title])
**Next step:** [the Next step below]
**Blocked on:** [nothing, or the blocker]
**Files in progress:** [changed files, comma-separated]
**Run result:** [OBSERVED — … | NOT VERIFIED — … | N/A — …, as in the closing block: /story-done reads it here]
**Open questions:** [none, or one line each]
```

**The run's last reply ends with this block**, the only place the `Run result:` line
is printed: print it nowhere else in the reply. The Next step goes by the tier you stated in Phase 1 (the `workflow` line,
never `rigor` or `qa.level`). The Next step: at `minimal`, `/story-done [path]`. At `standard` and `full`,
`/code-review [files]`, then `/story-done [path]`. INCOMPLETE: `/dev-story [path]`
to resume. BLOCKED: the action that unblocks it (`/architecture-decision accept
ADR-NNNN`, the dependency to finish, the diff to review).
**本轮的最后一条回复以此块结尾**，这是打印 `Run result:` 行的唯一位置：
不要在回复的其他任何地方打印它。下一步依据你在阶段 1 说明的层级（`workflow` 行，
绝不是 `rigor` 或 `qa.level`）。下一步：在 `minimal` 下，`/story-done [path]`。在 `standard` 和 `full` 下，
`/code-review [files]`，然后 `/story-done [path]`。INCOMPLETE：`/dev-story [path]`
以恢复。BLOCKED：解除阻塞的操作（`/architecture-decision accept
ADR-NNNN`、要完成的依赖、要评审的差异）。

```
Story: [path] — [Implemented | INCOMPLETE — <breakage> | BLOCKED — <reason>]
Run result: [OBSERVED — … | NOT VERIFIED — … | N/A — …]
Next step: [Implemented, Tier: workflow minimal → /story-done [path] | Implemented, Tier: workflow standard or full → /code-review [changed files], then /story-done [path] | INCOMPLETE → /dev-story [path] to resume | BLOCKED → the unblocking action]
```
