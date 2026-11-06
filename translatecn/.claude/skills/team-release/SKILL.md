---
name: team-release
description: "Orchestrate the release team — release-manager, qa-lead, devops-engineer, producer — to execute a release from candidate to deployment."
argument-hint: "[version number or 'next'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-release/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-release
description: "编排发布团队 — release-manager、qa-lead、devops-engineer、producer — 从候选版本到部署执行一次发布。"
argument-hint: "[version number or 'next'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-release/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Release
# 团队发布

**Argument check:** If no version number is provided:
1. Read `production/session-state/active.md` and the most recent file in `production/milestones/` (if they exist) to infer the target version.
2. If a version is found: report "No version argument provided — inferred [version] from milestone data. Proceeding." Then confirm with `AskUserQuestion`: "Releasing [version]. Is this correct?"
3. If no version is discoverable: use `AskUserQuestion` to ask "What version number should be released? (e.g., v1.0.0)" and wait for user input before proceeding. Do NOT default to a hardcoded version string.
**参数检查：** 若未提供版本号：
1. 读取 `production/session-state/active.md` 与 `production/milestones/` 中最近的文件（若存在），以推断目标版本。
2. 若找到版本：报告"No version argument provided — inferred [version] from milestone data. Proceeding."。然后用 `AskUserQuestion` 确认："Releasing [version]. Is this correct?"
3. 若无法发现任何版本：用 `AskUserQuestion` 询问"What version number should be released? (e.g., v1.0.0)"，并在继续之前等待用户输入。**不要**默认使用硬编码的版本字符串。

When this skill is invoked, orchestrate the release team through a structured pipeline.
调用此技能时，通过结构化流程编排发布团队。

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.
**决策点：** 在每个阶段过渡处，使用 `AskUserQuestion` 将子智能体的提议作为
可选项呈现给用户。在对话中写下智能体的完整分析，然后用简明标签
记录决定。在 `collaborative` 模式下，用户必须批准后才能进入下一阶段。
在 `guided` 模式下，流程自动推进，除非某阶段被 BLOCKED；
在 `autonomous` 模式下，它端到端运行，并通过 `log_decision`
记录每个阶段的结果。`automation_always_ask` 类别中的决策
（`is_always_ask_category` 辅助函数）无论何种模式都总是询问。参见
`.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config
## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,project.stage`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

**Stage check — before anything is spawned.** This skill ships a release, and
`/gate-check release` is the readiness gate that must pass first; only its PASS
sets `project.stage` to `Release`. If the resolved `project.stage` is anything
else — `Polish`, an earlier stage, or not set — stop before Phase 1 and spawn
nothing:
**阶段检查 — 在任何内容被启动之前。** 此技能要发布一个版本，而
`/gate-check release` 是必须先通过的就绪门禁；只有其 PASS
才会将 `project.stage` 设为 `Release`。若解析出的 `project.stage` 是其他
值 — `Polish`、更早的阶段，或未设置 — 则在阶段 1 之前停止，且不启动
任何内容：

> "The release readiness gate has not passed (project.stage: [stage]) — run
> `/gate-check release` first."
> "发布就绪门禁尚未通过（project.stage: [stage]）— 请先运行
> `/gate-check release`。"

Then ask with `AskUserQuestion`, in every `automation` mode — an override is never
taken on the user's behalf: `[A] Stop — I'll run /gate-check release (recommended)`
/ `[B] Proceed anyway — override the stage check`. On `[A]`, end the run: Verdict
**BLOCKED** — release gate not passed. On `[B]`, ask (plain text) why, then record
the override as `Stage override: project.stage was [stage] — release gate not
passed; the user chose to proceed: [reason]` in the Phase 1 brief, in the go/no-go
record (`go-no-go-[version].md`) and in the final report. An override never
changes the stage itself.
然后在每一种 `automation` 模式下都用 `AskUserQuestion` 询问 — 绝不代用户
做出覆盖决定：`[A] Stop — I'll run /gate-check release (recommended)`
/ `[B] Proceed anyway — override the stage check`。选 `[A]` 时，结束运行：裁决
**BLOCKED** — 发布门禁未通过。选 `[B]` 时，用纯文本询问原因，然后将该覆盖记录为
`Stage override: project.stage was [stage] — release gate not
passed; the user chose to proceed: [reason]`，写入阶段 1 简报、go/no-go
记录（`go-no-go-[version].md`）以及最终报告中。覆盖永不
改变阶段本身。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.
`review_mode` 设定总监门禁的深度，而此流程没有总监门禁：
在任何 `review_mode` 下，下文没有任何阶段会启动 CD-、TD-、PR- 或 AD-PHASE-GATE。它的
阶段门禁是流程自身的决策点（在下文 `team.size`
之下定义），而在这些点上工作的智能体是团队成员，不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.
`automation` 驱动上文的决策点说明。参见上文决策点说明与
`.claude/docs/automation-modes.md`，了解每种模式如何改变流程行为。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `release-manager` only. Other agents consulted via the release-manager, not spawned separately.
- **`small`**: + `producer` + `devops-engineer` + `qa-lead` + `community-manager`.
- **`studio`**: + `security-engineer` + `analytics-engineer` + `localization-lead` + `performance-analyst`, and `network-programmer` when the game is multiplayer (the full pipeline as documented).
**`team.size`**：哪些智能体处于活跃状态（与 review_mode 门禁深度和 workflow 文档相互独立）。
- **`individual`**（默认）：仅 `release-manager`。其他智能体通过 release-manager 咨询，不单独启动。
- **`small`**：+ `producer` + `devops-engineer` + `qa-lead` + `community-manager`。
- **`studio`**：+ `security-engineer` + `analytics-engineer` + `localization-lead` + `performance-analyst`，当游戏为多人时再加 `network-programmer`（即文档所载的完整流程）。
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, the stage check, or the Phase 6 deploy question — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.
在 `individual` 下需要非核心智能体时，通过最近的核心活跃智能体路由，并附一条信息性说明。**"阶段门禁"指任何以本流程自身列出的 `AskUserQuestion` 决策点结尾的阶段** — 上文决策点下的某次过渡、阶段检查，或阶段 6 的部署提问 — **无论 `automation` 模式为何。** `guided` 与 `autonomous` 改变的是门禁如何通过（自动推进，或用 `log_decision` 记录），而非它是否为门禁，因此下文有界例外条件 (3) 在任何模式下都成立。被限定为"仅阶段门禁"的智能体只在这些点启动，不在其他点启动。这种活跃集范围限定贯穿下文整个流程：任何点名了活跃集之外智能体的阶段，都通过最近的核心智能体路由，而不是启动它。

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:
**在阶段 1 之前宣布活跃集 — 绝不让这种收缩悄无声息。**
在启动任何内容之前，用一行说明本次运行实际会启动哪些智能体，
以及下文流程点名、但在已解析的 `team.size` 下**不会**启动哪些。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`
> `Active set (team.size: <resolved>): <上文为该规模列出的智能体>.`
> `Not spawned this run: <本流程点名的其他所有智能体> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.
从紧接上文的 `team.size` 列表以及本文件自身流程点名的智能体来填写 — 而不是照抄
示例。两个集合因编排器而异。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.
下文流程读起来像多智能体扇出，但在出厂默认值下它
是一两个智能体 — `team-release` 点名十个而只运行一个，`team-narrative`
在五个阶段中点名六个却只运行 `writer` 一个。**这种收缩是正确的**：
`team.size` 以严谨度为前提，狭窄的默认值是 token 杠杆。
若不说明这一点，读者就无法
分辨正确收缩的运行与损坏的流程，而且上文按智能体的
"通过最近的核心智能体路由并附信息性说明"规则在路由时触发，
从不说明整个运行的整体形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**
这与本文件其他位置的跳过检查报告规则相同：**一项被强制执行却从未呈现的约束，
在阅读输出的人看来，与从未被执行的约束无法区分。**

## Team Composition
- **release-manager** — Release tag, versioning, changelog, patch notes, deployment
- **qa-lead** — Test sign-off, regression suite, release quality gate
- **devops-engineer** — Build pipeline, artifacts, deployment automation
- **security-engineer** — Pre-release security audit (invoke if game has online/multiplayer features or player data)
- **network-programmer** — Netcode stability sign-off (invoke if game has multiplayer)
- **analytics-engineer** — Verify telemetry events fire correctly and dashboards are live
- **localization-lead** — Verify every shipped string is translated
- **performance-analyst** — Benchmark the release build against its performance targets
- **community-manager** — Launch announcement and player-facing messaging, written from the patch notes
- **producer** — Go/no-go decision, stakeholder communication, scheduling
## 团队构成
- **release-manager** — 发布标签、版本管理、变更日志、补丁说明、部署
- **qa-lead** — 测试签署、回归套件、发布质量门禁
- **devops-engineer** — 构建流水线、构建产物、部署自动化
- **security-engineer** — 发布前安全审计（若游戏有在线/多人功能或玩家数据则调用）
- **network-programmer** — 网络代码稳定性签署（若游戏有多人则调用）
- **analytics-engineer** — 核验遥测事件正确触发且仪表盘已上线
- **localization-lead** — 核验每一处随版本发布的字符串均已翻译
- **performance-analyst** — 将发布构建与其性能目标进行基准对比
- **community-manager** — 上线公告与面向玩家的信息，基于补丁说明撰写
- **producer** — Go/no-go 决策、干系人沟通、排期

## How to Delegate
## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: release-manager` — Release tag, versioning, changelog, patch notes, deployment
- `subagent_type: qa-lead` — Test sign-off, regression suite, release quality gate
- `subagent_type: devops-engineer` — Build pipeline, artifacts, deployment automation
- `subagent_type: security-engineer` — Security audit for online/multiplayer/data features
- `subagent_type: analytics-engineer` — Telemetry event verification and dashboard readiness
- `subagent_type: community-manager` — Launch communication, written from the patch notes
- `subagent_type: producer` — Go/no-go decision, stakeholder communication
- `subagent_type: network-programmer` — Netcode stability sign-off (invoke if game has multiplayer)
- `subagent_type: localization-lead` — Translation completeness sign-off (Phase 4)
- `subagent_type: performance-analyst` — Performance benchmarks against targets (Phase 4)
使用 `Agent` 工具将每位团队成员作为子智能体启动：
- `subagent_type: release-manager` — 发布标签、版本管理、变更日志、补丁说明、部署
- `subagent_type: qa-lead` — 测试签署、回归套件、发布质量门禁
- `subagent_type: devops-engineer` — 构建流水线、构建产物、部署自动化
- `subagent_type: security-engineer` — 针对在线/多人/数据功能的安全审计
- `subagent_type: analytics-engineer` — 遥测事件核验与仪表盘就绪
- `subagent_type: community-manager` — 上线沟通，基于补丁说明撰写
- `subagent_type: producer` — Go/no-go 决策、干系人沟通
- `subagent_type: network-programmer` — 网络代码稳定性签署（若游戏有多人则调用）
- `subagent_type: localization-lead` — 翻译完整性签署（阶段 4）
- `subagent_type: performance-analyst` — 对照目标进行性能基准测试（阶段 4）

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.
**为每个智能体做简报 — 不要倾倒上下文。** 将共享输入**读取一次**，并以内联方式传递提炼后的简报：每个智能体实际需要的那些行，绝不把你已读过的文档路径交出去（智能体拿到路径会重读整个文件）。只有在你尚未读过、且只有该智能体需要的文档时才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.
**每个智能体提示词都以返回契约结尾：** "将你的完整输出写入 `[path]` — 该具名路径即你在下文有界例外下的写入授权，因此无需单独的批准提示即可写入。**只**返回 (1) 已写入的路径，(2) 不超过 5 条要点的决策摘要，(3) 任何 BLOCKED/CONCERNS 项，每项一行。不要复述你读过的文档。" 没有它，智能体会把它读到的所有内容都回传进本次会话。

**Substitute a real path for `[path]`.** One file per agent under
`production/releases/`, except the two whose homes are fixed elsewhere. An active
agent standing in for one outside the active set writes that agent's file:
**为 `[path]` 代入真实路径。** 每个智能体在
`production/releases/` 下一个文件，只有两个的家固定在别处。活跃
智能体代替活跃集之外的某个智能体时，写入被代替者的文件：

| Phase / agent | Writes to | Destination fixed by |
|---|---|---|
| 1 producer | `production/releases/release-plan-[version].md` | this skill |
| 2 release-manager | `production/releases/release-checklist-[version].md` | `/release-checklist` |
| 3 qa-lead | `production/releases/qa-gate-[version].md` | this skill |
| 3 devops-engineer | `production/releases/build-[version].md` | this skill |
| 3 security-engineer | `production/releases/security-signoff-[version].md` | this skill |
| 3 network-programmer | `production/releases/netcode-signoff-[version].md` | this skill |
| 4 localization-lead | `production/releases/localization-signoff-[version].md` | this skill |
| 4 performance-analyst | `production/releases/performance-signoff-[version].md` | this skill |
| 4 analytics-engineer | `production/releases/analytics-signoff-[version].md` | this skill |
| 5 go/no-go | `production/releases/go-no-go-[version].md` | this skill |
| 6 release-manager | `docs/patch-notes/[version].md` | `/patch-notes` |
| 6 community-manager | `production/releases/announcement-[version].md` | this skill |
| 7 release-manager | `production/releases/release-report-[version].md` | this skill |
| 阶段 / 智能体 | 写入到 | 目标位置由谁确定 |
|---|---|---|
| 1 producer | `production/releases/release-plan-[version].md` | 本技能 |
| 2 release-manager | `production/releases/release-checklist-[version].md` | `/release-checklist` |
| 3 qa-lead | `production/releases/qa-gate-[version].md` | 本技能 |
| 3 devops-engineer | `production/releases/build-[version].md` | 本技能 |
| 3 security-engineer | `production/releases/security-signoff-[version].md` | 本技能 |
| 3 network-programmer | `production/releases/netcode-signoff-[version].md` | 本技能 |
| 4 localization-lead | `production/releases/localization-signoff-[version].md` | 本技能 |
| 4 performance-analyst | `production/releases/performance-signoff-[version].md` | 本技能 |
| 4 analytics-engineer | `production/releases/analytics-signoff-[version].md` | 本技能 |
| 5 go/no-go | `production/releases/go-no-go-[version].md` | 本技能 |
| 6 release-manager | `docs/patch-notes/[version].md` | `/patch-notes` |
| 6 community-manager | `production/releases/announcement-[version].md` | 本技能 |
| 7 release-manager | `production/releases/release-report-[version].md` | 本技能 |

> **Every one of those thirteen outputs needs a stated destination.**
> `production/releases/` is where `/release-checklist` already writes, and
> `docs/patch-notes/[version].md` is where `/patch-notes` already writes, so the
> release record lands in one place regardless of which skill produced it.
>
> **A separate file per agent, not one appended record.** Phase 3 and Phase 4
> spawn agents in parallel; two agents appending to one file race, and the loser's
> section vanishes silently.
> **那十三个输出每一个都需要一个明确的目标位置。**
> `production/releases/` 是 `/release-checklist` 已经写入的地方，而
> `docs/patch-notes/[version].md` 是 `/patch-notes` 已经写入的地方，因此
> 无论由哪个技能产出，发布记录都落在一处。
>
> **每个智能体一个单独文件，而不是一份追加记录。** 阶段 3 与阶段 4
> 并行启动智能体；两个智能体向同一文件追加会产生竞争，败者的
> 小节会静默消失。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.
> **为何这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问"May I write this to [filepath]?"。在此启动的子智能体**不询问**即写入，这是有意的、有界的例外，而非疏忽 — 与 `consistency-check` 向 `active.md` 追加时已做出的同类决定。该例外仅在以下三者全部成立时有效：(1) 路径是**你**在提示词中点名的，因此用户在批准该阶段时也批准了目标位置；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新制品，绝不是对既有源码或配置的编辑；(3) 产出它的阶段本身在流程推进之前受 `AskUserQuestion` 门禁约束。超出这三者，智能体必须询问。**不要通过逐子智能体询问来"修复"这一点** — 每个阶段每个智能体一次提问会让编排器无法使用，这正是例外存在的原因。

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 3 agents can run simultaneously).
在流程允许之处并行启动独立智能体（例如，阶段 3 的各智能体可同时运行）。

## Pipeline
## 流程

### Phase 1: Release Planning
### 阶段 1：发布规划
Delegate to **producer**:
- Confirm all milestone acceptance criteria are met
- Identify any scope items deferred from this release
- Set the target release date and communicate to team
- Output: release authorization with scope confirmation
委派给 **producer**：
- 确认所有里程碑验收标准均已满足
- 识别本次发布中推迟的任何范围条目
- 设定目标发布日期并通知团队
- 输出：附范围确认的发布授权

### Phase 2: Release Candidate
### 阶段 2：发布候选版本
Delegate to **release-manager**:
- Bump version numbers in all relevant files on `main`; the commit carrying the bump is the release candidate. Development is trunk-based — a release is a tag on `main` (applied in Phase 6), not a branch
- Confirm the release checklist from Polish (`/release-checklist`, run before `/gate-check release`) is complete for this candidate; run it now only if none exists
- Cut a `release/[version]` branch from the candidate only if this release needs stabilising (a freeze, platform certification) — bug fixes only there, and every fix lands on `main` as well
- Output: release candidate commit (plus the `release/*` branch, if one was cut) and checklist
委派给 **release-manager**：
- 在 `main` 上所有相关文件中提升版本号；承载该提升的提交即发布候选版本。开发基于主干 — 一次发布是 `main` 上的一个标签（在阶段 6 应用），而不是分支
- 确认来自打磨阶段（Polish）的发布检查清单（`/release-checklist`，在 `/gate-check release` 之前运行）对该候选版本是完整的；仅当不存在时才现在运行它
- 仅当本次发布需要稳定化（冻结、平台认证）时，才从候选版本切出 `release/[version]` 分支 — 仅在那里做缺陷修复，且每项修复也要落到 `main`
- 输出：发布候选提交（以及 `release/*` 分支，若切出过）与检查清单

### Phase 3: Quality Gate (parallel)
### 阶段 3：质量门禁（并行）
Delegate in parallel:
- **qa-lead**: Execute full regression test suite. Test all critical paths. Verify no open bugs at the severities `/gate-check release` blocks for this `workflow`: S1 at every tier, S2 and S3 too at `full`. Sign off on quality.
- **devops-engineer**: Build release artifacts for all target platforms. Verify builds are clean and reproducible. Run automated tests in CI.
- **security-engineer** *(if game has online features, multiplayer, or player data)*: Conduct pre-release security audit. Review authentication, anti-cheat, data privacy compliance. Sign off on security posture.
- **network-programmer** *(if game has multiplayer)*: Sign off on netcode stability. Verify lag compensation, reconnect handling, and bandwidth usage under load.
并行委派：
- **qa-lead**：执行完整回归测试套件。测试所有关键路径。核验在 `/gate-check release` 针对此 `workflow` 所阻塞的严重级别下没有未解决缺陷：每个 tier 的 S1，`full` 下的 S2 与 S3 也是。对质量予以签署。
- **devops-engineer**：为所有目标平台构建发布产物。核验构建干净且可复现。在 CI 中运行自动化测试。
- **security-engineer** *（若游戏有在线功能、多人或玩家数据）*：开展发布前安全审计。审查认证、反作弊、数据隐私合规。对安全态势予以签署。
- **network-programmer** *（若游戏有多人）*：对网络代码稳定性予以签署。核验延迟补偿、重连处理以及负载下的带宽使用。

When either agent is in the active set, decide its condition from `platform.online` and `platform.multiplayer` in `project.yaml`, plus whether the game stores player data. A key that is absent is not a `false`: ask the user rather than assume an offline game. An agent skipped on these grounds says so by name in the Phase 3 output — e.g. `security-engineer: not spawned — platform.online: false, platform.multiplayer: false, no player data`.
当任一智能体在活跃集中时，根据 `project.yaml` 中的 `platform.online` 与 `platform.multiplayer`，以及游戏是否存储玩家数据来决定其条件。缺失的键不等于 `false`：要询问用户，而不是假定为离线游戏。因这些理由被跳过的智能体会在阶段 3 输出中按名称说明 — 例如 `security-engineer: not spawned — platform.online: false, platform.multiplayer: false, no player data`。

### Phase 4: Localization, Performance, and Analytics
### 阶段 4：本地化、性能与分析
Delegate (can run in parallel with Phase 3 if resources available):
- Verify all strings are translated (delegate to **localization-lead** if available)
- Run performance benchmarks against targets (delegate to **performance-analyst** if available)
- **analytics-engineer**: Verify all telemetry events fire correctly on release build. Confirm dashboards are receiving data. Check that critical funnels (onboarding, progression, monetization if applicable) are instrumented.
- Output: localization, performance, and analytics sign-off — one file per agent (table above)
委派（若有资源，可与阶段 3 并行运行）：
- 核验所有字符串均已翻译（若有 **localization-lead** 则委派给它）
- 对照目标运行性能基准测试（若有 **performance-analyst** 则委派给它）
- **analytics-engineer**：核验所有遥测事件在发布构建上正确触发。确认仪表盘正在接收数据。检查关键漏斗（新手引导、进度、若适用的商业化）是否已埋点。
- 输出：本地化、性能与分析签署 — 每个智能体一个文件（见上表）

### Phase 5: Go/No-Go
### 阶段 5：Go/No-Go
Before delegating, get the **technical-director** release sign-off. The producer
cannot spawn agents, so the orchestrator does: spawn `technical-director` at
`review_mode: full` only — this is a director review, not a PHASE-GATE, so `lean`
and `solo` skip it. Ask for GO, CONCERNS or NO-GO on the release candidate's
technical state, or NOT ASSESSED naming what it could not read. When it is not
spawned, the go/no-go record says `technical-director sign-off: not run
(review_mode: <mode>)` instead of listing it as given; a NOT ASSESSED answer is
recorded as such and never counted as a sign-off.
在委派之前，取得 **technical-director** 的发布签署。producer
不能启动智能体，因此由编排器来做：仅在
`review_mode: full` 时启动 `technical-director` — 这是总监评审，不是 PHASE-GATE，因此
`lean` 与 `solo` 跳过它。就发布候选版本的技术状态请求 GO、CONCERNS 或 NO-GO，
或 NOT ASSESSED 并指明它读不到的内容。当它未被启动时，go/no-go 记录写为
`technical-director sign-off: not run
(review_mode: <mode>)`，而不是把它列为已给出；NOT ASSESSED 的答复按原样
记录，绝不计为签署。

Delegate to **producer**, passing every sign-off collected so far:
- Collect sign-off from: qa-lead, release-manager, devops-engineer, security-engineer (if spawned in Phase 3), network-programmer (if spawned in Phase 3), and technical-director (if spawned above)
- Carry a stage-check override, if there was one, into the go/no-go record as its `Stage override:` line
- Evaluate any open issues — are they blocking or can they ship?
- Make the go/no-go call
- Output: release decision with rationale
委派给 **producer**，传入目前收集到的所有签署：
- 从以下收集签署：qa-lead、release-manager、devops-engineer、security-engineer（若在阶段 3 启动）、network-programmer（若在阶段 3 启动）以及 technical-director（若在上文启动）
- 若存在阶段检查覆盖，则将其作为 `Stage override:` 行带入 go/no-go 记录
- 评估任何未决问题 — 它们是阻塞性的，还是可以发布？
- 做出 go/no-go 决定
- 输出：附理由的发布决定

**If producer declares NO-GO:**
- Surface the decision immediately: "PRODUCER: NO-GO — [rationale, e.g., S1 bug found in Phase 3]."
- Use `AskUserQuestion` with options:
  - Fix the blocker and re-run the affected phase
  - Defer the release to a later date
  - Override NO-GO with documented rationale (user must provide written justification)
- **Skip Phase 6 entirely** — do not tag, deploy to staging, deploy to production, or spawn community-manager.
- Produce a partial report summarizing Phases 1–5 and what was skipped (Phase 6) and why.
- Verdict: **BLOCKED** — release not deployed.
**若 producer 宣布 NO-GO：**
- 立即呈现该决定："PRODUCER: NO-GO — [rationale, e.g., S1 bug found in Phase 3]."
- 使用 `AskUserQuestion`，选项为：
  - 修复阻塞项并重跑受影响的阶段
  - 将发布推迟到更晚的日期
  - 以有记录的理据覆盖 NO-GO（用户必须提供书面理由）
- **完全跳过阶段 6** — 不要打标签、不要部署到预发布环境、不要部署到生产，也不要启动 community-manager。
- 产出一份部分报告，总结阶段 1–5 以及被跳过的内容（阶段 6）及原因。
- 裁决：**BLOCKED** — 发布未部署。

After the user selects "Override NO-GO with documented rationale":
- Ask (plain text, not widget): "Please describe the justification for overriding the NO-GO verdict. This will be embedded in the release record."
- Wait for the user's written justification.
- Embed the justification text in the partial approval record before Phase 6: append a "⚠️ Override Justification: [user's text]" field.
- Only then proceed to Phase 6.
在用户选择"Override NO-GO with documented rationale"之后：
- 询问（纯文本，而非控件）："请说明覆盖 NO-GO 裁决的理由。这将嵌入发布记录中。"
- 等待用户的书面理由。
- 在阶段 6 之前将理由文本嵌入部分批准记录：追加一个 "⚠️ Override Justification: [user's text]" 字段。
- 只有在此之后才进入阶段 6。

### Phase 6: Deployment (if GO)
### 阶段 6：部署（若为 GO）

**This phase always requires explicit user approval regardless of
`modes.automation` — including `autonomous` mode.** Production deployment is
irreversible and high-stakes; it is NOT covered by the configurable
`automation_always_ask` categories, so this skill guards it unconditionally.
Before tagging or deploying, use `AskUserQuestion`:
- Prompt: "Producer verdict is GO. Execute Phase 6 — tag, deploy to staging,
  deploy to production?"
- Options: `[A] Yes, deploy` / `[B] Staging only — hold production` / `[C] Stop here`
**此阶段无论 `modes.automation` 为何，都始终需要用户明确批准 —
包括 `autonomous` 模式。** 生产部署是不可逆且高风险的；它**不**受可配置的
`automation_always_ask` 类别覆盖，因此此技能无条件地守护它。
在打标签或部署之前，使用 `AskUserQuestion`：
- 提示："Producer verdict is GO. Execute Phase 6 — tag, deploy to staging,
  deploy to production?"
- 选项：`[A] Yes, deploy` / `[B] Staging only — hold production` / `[C] Stop here`

Only after explicit approval, delegate to **release-manager** + **devops-engineer**:
- Tag the release in version control
- Finalize the changelog drafted in Polish (`/changelog`), adding what changed since the gate
- Deploy to staging for final smoke test
- Deploy to production (only if the user approved production above)
- Human team action: Monitor dashboards and error rates for 48 hours post-release. Schedule a follow-up retrospective using `/retrospective` at the 48-hour mark.
仅在明确批准之后，委派给 **release-manager** + **devops-engineer**：
- 在版本控制中为发布打标签
- 定稿打磨阶段起草的变更日志（`/changelog`），补充自门禁以来的更改
- 部署到预发布环境做最终冒烟测试
- 部署到生产（仅当用户在上文批准了生产部署）
- 人类团队动作：发布后 48 小时内监控仪表盘与错误率。在 48 小时节点用 `/retrospective` 安排一次后续回顾。

In parallel with deployment, delegate to **release-manager**:
- Finalize the patch notes drafted in Polish using `/patch-notes [version]` — release-manager carries that skill and the Bash access its `git log` step needs; `community-manager` has neither
与部署并行，委派给 **release-manager**：
- 使用 `/patch-notes [version]` 定稿打磨阶段起草的补丁说明 — release-manager 携带该技能以及其 `git log` 步骤所需的 Bash 访问权限；`community-manager` 两者都没有

Then hand those patch notes to **community-manager**:
- Prepare launch announcement (store page updates, social media, community post)
- Draft known issues post if any S3+ issues shipped
- Output: all player-facing release communication, ready to publish on deploy confirmation
然后将这些补丁说明交给 **community-manager**：
- 准备上线公告（商店页面更新、社交媒体、社区帖子）
- 若发布了任何 S3+ 问题，起草已知问题帖
- 输出：所有面向玩家的发布沟通内容，在部署确认后即可发布

### Phase 7: Post-Release
### 阶段 7：发布后
- **release-manager**: Generate release report (what shipped, what was deferred, metrics)
- **producer**: Update milestone tracking, communicate to stakeholders
- **qa-lead**: Monitor incoming bug reports for regressions
- **community-manager**: Publish all player-facing communication, monitor community sentiment
- **analytics-engineer**: Confirm live dashboards are healthy; alert if any critical events are missing
- Keep the 48-hour monitoring window from Phase 6: bugs, dashboards and community sentiment are watched for 48 hours after release (release-manager's own watch runs to its 72h report)
- Schedule post-release retrospective if issues occurred
- **release-manager**：生成发布报告（发布了什么、推迟了什么、指标）
- **producer**：更新里程碑跟踪，向干系人沟通
- **qa-lead**：监控流入的缺陷报告以发现回归
- **community-manager**：发布所有面向玩家的沟通内容，监控社区情绪
- **analytics-engineer**：确认线上仪表盘健康；若有任何关键事件缺失则告警
- 保留阶段 6 的 48 小时监控窗口：发布后 48 小时内持续观察缺陷、仪表盘与社区情绪（release-manager 自身的观察延续到其 72 小时报告）
- 若发生问题，安排发布后回顾

## Error Recovery Protocol
## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.
**首先，核验制品。** 若返回契约点名了路径，则在将该阶段视为完成之前检查
该路径存在 — **不在磁盘上的具名制品就是失败的阶段，无论回答读起来多么流畅。**
智能体可能耗掉整个阶段、什么都没写却返回一段貌似合理的开场白，那
既不是 BLOCKED，也不是错误，也不是"无法完成"，因此下文的触发条件
永远不会触发。以未满足的契约点名恢复它；上下文
通常仍在。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.
若任何被启动的智能体返回 BLOCKED、出错或无法完成：**立即呈现它，
不要越过它所阻塞的依赖继续推进，并始终产出部分报告。** 完整流程：
`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; accept it with `/architecture-decision accept ADR-NNNN` once decided
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
常见阻塞项：
- 输入文件缺失（未找到故事、GDD 缺失）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实施；一旦决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆成两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测

## File Write Protocol
## 文件写入协议

All file writes (release checklists, changelogs, patch notes, deployment scripts) are
delegated to sub-agents and sub-skills. The two follow **different** rules, and the
distinction matters here more than anywhere else in the pipeline:
所有文件写入（发布检查清单、变更日志、补丁说明、部署脚本）都
委派给子智能体与子技能。二者遵循**不同**的规则，而这一
区别在此处比流程中任何其他地方都更重要：

- **Sub-agents spawned via `Agent`** follow the **bounded exception** documented above
  under "Why this does not violate the Collaboration Protocol" — the path is one you
  named, the artifact is new under `production/`, `docs/` or `tests/`, and the phase
  is gated by an `AskUserQuestion`. A sub-agent does **not** prompt per write inside
  those bounds; outside them it must ask.
- **Sub-skills** are not sub-agents and the exception does not reach them. They
  follow the normal Collaboration Protocol and ask before writing.
- **通过 `Agent` 启动的子智能体**遵循上文"Why this does not violate the Collaboration Protocol"
  下记录的**有界例外** — 路径是你点名的、制品是 `production/`、`docs/` 或 `tests/`
  下的新文件，且该阶段受 `AskUserQuestion` 门禁约束。在这些界限之内，子智能体
  **不会**逐次写入提示；超出界限则必须询问。
- **子技能**不是子智能体，例外不及于它们。它们
  遵循常规协作协议，写入前询问。

This orchestrator does not write files directly. Nothing here authorises an
outward-facing or irreversible action — tags, pushes, builds and storefront changes
require explicit confirmation regardless of which rule above applies.
此编排器不直接写文件。此处任何内容都不授权
面向外部或不可逆的动作 — 标签、推送、构建与商店页面更改
无论适用上述哪条规则，都需要明确确认。

## Output
## 输出

A summary report covering: release version, scope, quality gate results, go/no-go decision, deployment status, and monitoring plan.
一份总结报告，涵盖：发布版本、范围、质量门禁结果、go/no-go 决定、部署状态与监控计划。

Verdict: **COMPLETE** — release executed and deployed.
Verdict: **BLOCKED** — release halted; the stage check stopped it, go/no-go was NO, or a hard blocker is unresolved.
裁决：**COMPLETE** — 发布已执行并部署。
裁决：**BLOCKED** — 发布已中止；阶段检查阻止了它、go/no-go 为 NO，或有硬性阻塞项未解决。

## Next Steps
## 后续步骤

- Monitor post-release dashboards for 48 hours.
- Run `/retrospective` if significant issues occurred during the release.
- `project.stage` reads `Release` unless the stage check was overridden: `/gate-check release` is the Polish → Release readiness gate, run before this skill. After an override the stage still reads what it did. Only `/gate-check` changes `project.stage` (on a PASS, or a CONCERNS whose risks the user accepted), so this skill never writes it or `production/stage.txt`. `Release` is the terminal stage in the `project.stage` enum — there is no post-launch stage value. Record live/post-launch status in the release report, not in `project.stage`.
- 发布后监控仪表盘 48 小时。
- 若发布期间发生重大问题，运行 `/retrospective`。
- 除非阶段检查被覆盖，`project.stage` 读作 `Release`：`/gate-check release` 是 Polish → Release 的就绪门禁，在此技能之前运行。覆盖之后，阶段仍读作它原本的值。只有 `/gate-check` 会改变 `project.stage`（在 PASS 时，或用户接受了其风险的 CONCERNS 时），因此此技能绝不写入它或 `production/stage.txt`。`Release` 是 `project.stage` 枚举中的终止阶段 — 没有发布后阶段值。将线上/发布后状态记录在发布报告中，而不是 `project.stage`。
