---
name: team-ui
description: "Orchestrate the UI team through the UX pipeline — authoring, visual design, implementation, review, polish. Uses /ux-design, /ux-review, studio templates."
argument-hint: "[UI feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-ui/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-ui
description: "通过 UX 流程编排 UI 团队 — 撰写、视觉设计、实现、评审、打磨。使用 /ux-design、/ux-review 与工作室模板。"
argument-hint: "[UI feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-ui/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team UI
# 团队 UI

If no argument is provided, output usage guidance and exit without spawning any agents or reading any design files:
> Usage: `/team-ui [UI feature description] [--review full|lean|solo]` — describe the screen or UI feature to build (e.g., `inventory screen`, `main menu`, `combat HUD`). Do not use `AskUserQuestion` here; output the guidance directly.
若未提供参数，则输出用法指引并退出，不启动任何智能体、也不读取任何设计文件：
> Usage: `/team-ui [UI feature description] [--review full|lean|solo]` — 描述要构建的界面或 UI 功能（例如 `inventory screen`、`main menu`、`combat HUD`）。此处不要使用 `AskUserQuestion`；直接输出该指引。

When this skill is invoked, orchestrate the UI team through a structured pipeline.
调用此技能时，通过结构化流程编排 UI 团队。

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

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

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
- **`individual`** (default): `ui-programmer` + `ux-designer`. Other agents consulted via these two, not spawned separately.
- **`small`**: + `accessibility-specialist` + `art-director`.
- **`studio`**: + engine UI specialist + an adversarial review pass: Phase 4's reviewers are told "your job is not to confirm this matches the spec — find where it fails it", and the report says the pass ran.
**`team.size`**：哪些智能体处于活跃状态（与 review_mode 门禁深度和 workflow 文档相互独立）。
- **`individual`**（默认）：`ui-programmer` + `ux-designer`。其他智能体通过这两者咨询，不单独启动。
- **`small`**：+ `accessibility-specialist` + `art-director`。
- **`studio`**：+ 引擎 UI 专家 + 一轮对抗性评审：阶段 4 的评审者会被告知"你的职责不是确认它符合规范 — 而是找出它不符合之处"，且报告会说明该轮评审已运行。
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.
在 `individual` 下需要非核心智能体时，通过最近的核心活跃智能体路由，并附一条信息性说明。**"阶段门禁"指任何以本流程自身列出的 `AskUserQuestion` 决策点结尾的阶段** — 上文决策点下的某次过渡，或下文流程中写入的某个 **Gate** 步骤 — **无论 `automation` 模式为何。** `guided` 与 `autonomous` 改变的是门禁如何通过（自动推进，或用 `log_decision` 记录），而非它是否为门禁，因此下文有界例外条件 (3) 在任何模式下都成立。被限定为"仅阶段门禁"的智能体只在这些点启动，不在其他点启动。这种活跃集范围限定贯穿下文整个流程：任何点名了活跃集之外智能体的阶段，都通过最近的核心智能体路由，而不是启动它。

**Announce the active set before Step 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:
**在步骤 1 之前宣布活跃集 — 绝不让这种收缩悄无声息。**
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
- **ux-designer** — User flows, wireframes, accessibility, input handling
- **ui-programmer** — UI framework, screens, widgets, data binding, implementation
- **art-director** — Visual style, layout polish, consistency with art bible
- **engine UI specialist** — Validates UI implementation patterns against engine-specific best practices (`specialists.ui` from `project.yaml`; if absent, the UI Specialist line of `## Engine Specialists` in `.claude/docs/technical-preferences.md`)
- **accessibility-specialist** — Audits accessibility compliance at Phase 4
## 团队构成
- **ux-designer** — 用户流程、线框图、可访问性、输入处理
- **ui-programmer** — UI 框架、界面、控件、数据绑定、实现
- **art-director** — 视觉风格、布局打磨、与美术圣经的一致性
- **engine UI specialist** — 对照引擎专属最佳实践验证 UI 实现模式（`project.yaml` 中的 `specialists.ui`；若缺失，则用 `.claude/docs/technical-preferences.md` 中 `## Engine Specialists` 的 UI Specialist 行）
- **accessibility-specialist** — 在阶段 4 审计可访问性合规

> **`specialists.ui: null` means UNSET.** Treat it as absent and skip the engine
> UI specialist; never spawn `null` as an agent name. The v1.0 migration writes
> the whole `specialists` block whenever any one member is set, so `null` here is
> ordinary — and the config reader returns it as the non-empty string `"null"`.
> **`specialists.ui: null` 表示未设置。** 将其视为缺失并跳过引擎
> UI 专家；绝不把 `null` 作为智能体名启动。v1.0 迁移只要设置了
> `specialists` 块中的任一成员就会写入整个块，因此这里的 `null` 很
> 常见 — 而且配置读取器会把它作为非空字符串 `"null"` 返回。

**Templates used by this pipeline:**
- `ux-spec.md` — Standard screen/flow UX specification
- `hud-design.md` — HUD-specific UX specification
- `interaction-pattern-library.md` — Reusable interaction patterns
- `accessibility-requirements.md` — Committed accessibility tier and requirements
**此流程使用的模板：**
- `ux-spec.md` — 标准界面/流程 UX 规范
- `hud-design.md` — HUD 专属 UX 规范
- `interaction-pattern-library.md` — 可复用交互模式
- `accessibility-requirements.md` — 已承诺的可访问性层级与要求

## How to Delegate
## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: ux-designer` — User flows, wireframes, accessibility, input handling
- `subagent_type: ui-programmer` — UI framework, screens, widgets, data binding
- `subagent_type: art-director` — Visual style, layout polish, art bible consistency
- `subagent_type: [UI engine specialist]` — Engine-specific UI pattern validation (e.g., unity-ui-specialist, ue-umg-specialist, godot-specialist)
- `subagent_type: accessibility-specialist` — Accessibility compliance audit
使用 `Agent` 工具将每位团队成员作为子智能体启动：
- `subagent_type: ux-designer` — 用户流程、线框图、可访问性、输入处理
- `subagent_type: ui-programmer` — UI 框架、界面、控件、数据绑定
- `subagent_type: art-director` — 视觉风格、布局打磨、美术圣经一致性
- `subagent_type: [UI engine specialist]` — 引擎专属 UI 模式验证（例如 unity-ui-specialist、ue-umg-specialist、godot-specialist）
- `subagent_type: accessibility-specialist` — 可访问性合规审计

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.
**为每个智能体做简报 — 不要倾倒上下文。** 将共享输入**读取一次**，并以内联方式传递提炼后的简报：每个智能体实际需要的那些行，绝不把你已读过的文档路径交出去（智能体拿到路径会重读整个文件）。只有在你尚未读过、且只有该智能体需要的文档时才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.
**每个智能体提示词都以返回契约结尾：** "将你的完整输出写入 `[path]` — 该具名路径即你在下文有界例外下的写入授权，因此无需单独的批准提示即可写入。**只**返回 (1) 已写入的路径，(2) 不超过 5 条要点的决策摘要，(3) 任何 BLOCKED/CONCERNS 项，每项一行。不要复述你读过的文档。" 没有它，智能体会把它读到的所有内容都回传进本次会话。**实现文件是例外：** 编写代码或资产的智能体先返回它将创建或更改的文件，且其返回契约只有在你就该集合询问一次、用户同意之后（文件写入协议）才点名它们 — 授权这些写入的是那个同意，而不是有界例外。

**Substitute a real path for `[path]`.** Working artifacts go under
`production/ui/[feature-name]/`, the slug Phase 1b's `design/ux/[feature-name].md`
uses. One file per agent, so the parallel Phase 4 reviews never share one:
**为 `[path]` 代入真实路径。** 工作制品放在
`production/ui/[feature-name]/` 下，即阶段 1b 的 `design/ux/[feature-name].md`
所使用的 slug。每个智能体一个文件，因此并行的阶段 4 评审绝不会共用一个：

| Phase / agent | Writes to |
|---|---|
| 2 art-director | `production/ui/[feature-name]/visual-design.md` |
| 3 engine UI specialist | `production/ui/[feature-name]/engine-notes.md` |
| 3 ui-programmer | the code root — the files the one implementation ask lists (File Write Protocol), outside the bounded exception |
| 4 ux-designer, art-director, accessibility-specialist | `production/ui/[feature-name]/review-[agent].md`, one each |
| 阶段 / 智能体 | 写入到 |
|---|---|
| 2 art-director | `production/ui/[feature-name]/visual-design.md` |
| 3 engine UI specialist | `production/ui/[feature-name]/engine-notes.md` |
| 3 ui-programmer | 代码根 — 由那一次实现提问列出的文件（文件写入协议），在有界例外之外 |
| 4 ux-designer、art-director、accessibility-specialist | `production/ui/[feature-name]/review-[agent].md`，各自一个 |

The UX spec itself (Phase 1b) and any pattern-library update are under `design/`,
outside the bounded exception: `/ux-design` or the agent asks before writing them.
UX 规范本身（阶段 1b）以及任何模式库更新都在 `design/` 下，
在有界例外之外：`/ux-design` 或相关智能体在写入它们之前会询问。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.
> **为何这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问"May I write this to [filepath]?"。在此启动的子智能体**不询问**即写入，这是有意的、有界的例外，而非疏忽 — 与 `consistency-check` 向 `active.md` 追加时已做出的同类决定。该例外仅在以下三者全部成立时有效：(1) 路径是**你**在提示词中点名的，因此用户在批准该阶段时也批准了目标位置；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新制品，绝不是对既有源码或配置的编辑；(3) 产出它的阶段本身在流程推进之前受 `AskUserQuestion` 门禁约束。超出这三者，智能体必须询问。**不要通过逐子智能体询问来"修复"这一点** — 每个阶段每个智能体一次提问会让编排器无法使用，这正是例外存在的原因。

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 4 review agents can run simultaneously).
在流程允许之处并行启动独立智能体（例如，阶段 4 的评审智能体可同时运行）。

## Pipeline
## 流程

### Phase 1a: Context Gathering
### 阶段 1a：上下文收集

Before designing anything, read and synthesize. Read each GDD by section: find the
headings you need with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.
在设计任何内容之前，先阅读并综合。按小节读取每个 GDD：用 Grep 工具（模式 `^#`，
content 模式）找到你需要的标题，再用 offset 与 limit 读取那些
范围。
- `design/gdd/game-concept.md` — platform targets and intended audience (or
  `design/game-brief.md`, the one-page brief that replaces it at `rigor: minimal` —
  its "Who it's for" line gives the audience; it names no platform)
- `design/player-journey.md` — player's state and context when they reach this screen
- All GDD UI Requirements sections relevant to this feature
- `design/ux/interaction-patterns.md` — existing patterns to reuse (not reinvent)
- `design/accessibility-requirements.md` — committed accessibility tier (Basic, Standard, Comprehensive or Exemplary)
- `design/gdd/game-concept.md` — 平台目标与目标受众（或
  `design/game-brief.md`，即在 `rigor: minimal` 时取代它的一页式简报 —
  其"Who it's for"一行给出受众；它不点名平台）
- `design/player-journey.md` — 玩家到达此界面时的状态与上下文
- 所有与此功能相关的 GDD UI Requirements 小节
- `design/ux/interaction-patterns.md` — 可复用的既有模式（不要重新发明）
- `design/accessibility-requirements.md` — 已承诺的可访问性层级（Basic、Standard、Comprehensive 或 Exemplary）

**Report the status of every document above before designing anything.** Phase 1a
reads five inputs, and any of them can be absent. List each as
present or ABSENT.
**在设计任何内容之前，报告上述每份文档的状态。** 阶段 1a
读取五项输入，其中任何一项都可能缺失。将每项列为
存在或 ABSENT。

**`design/accessibility-requirements.md` is the one that must not pass silently.**
It carries the committed accessibility tier, which **Phase 3 implements against**
and **Phase 4 gates on** ("verify compliance against the committed accessibility
tier … flag any violations as blockers"). If the file is missing there is no tier,
so that gate has no criterion and would pass while checking nothing — a gate made
of an absent standard, the same shape as an assertion that can never fail. When it
is absent:
- Say so here, and carry it forward: **Phase 4 must report
  `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`
  and must NOT report the accessibility gate as passed.**
- The ux-designer states which tier they designed against as an explicit
  assumption, so a later reader can see it was assumed rather than committed.
- Recommend `/ux-design accessibility` to establish the tier.
**`design/accessibility-requirements.md` 是那个绝不能静默通过的。**
它承载已承诺的可访问性层级，**阶段 3 据此实现**，
**阶段 4 据此设门禁**（"核验对照已承诺的可访问性
层级 …… 将任何违规标记为阻塞项"）。若文件缺失，就没有层级，
因此该门禁没有标准，会在什么都没检查的情况下通过 — 一道由缺失标准构成的门禁，
与一个永远不会失败的断言形态相同。当它缺失时：
- 在此说明，并向后传递：**阶段 4 必须报告
  `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`
  且**不得**将可访问性门禁报告为已通过。**
- ux-designer 将其设计时依据的层级作为明确的
  假设陈述出来，以便后来的读者看到它是假设的而非已承诺的。
- 建议运行 `/ux-design accessibility` 来确立该层级。

Absence of a concept doc (neither `design/gdd/game-concept.md` nor
`design/game-brief.md`), `design/player-journey.md` or `design/ux/hud.md` is not
blocking, but name each missing one in the brief you
pass to the ux-designer so they design knowing what context they lack, rather
than inferring it.
概念文档缺失（既无 `design/gdd/game-concept.md` 也无
`design/game-brief.md`）、`design/player-journey.md` 或 `design/ux/hud.md` 缺失不构成
阻塞，但要在你传给 ux-designer 的简报中点名每一个缺失项，
以便他们在知道自己缺少什么上下文的情况下设计，而不是
去推断它。

**If `design/ux/interaction-patterns.md` does not exist**, surface the gap immediately:
> "interaction-patterns.md does not exist — no existing patterns to reuse."
**若 `design/ux/interaction-patterns.md` 不存在**，立即呈现该缺口：
> "interaction-patterns.md does not exist — no existing patterns to reuse."

Then use `AskUserQuestion` with options:
- (a) Run `/ux-design patterns` first to establish the pattern library, then continue
- (b) Proceed without the pattern library — ui-programmer will treat all patterns created as new and add each to a new `design/ux/interaction-patterns.md` at completion
然后使用 `AskUserQuestion`，选项为：
- (a) 先运行 `/ux-design patterns` 建立模式库，然后继续
- (b) 不借助模式库继续 — ui-programmer 会将所有创建的模式视为新模式，并在完成时逐个加入新建的 `design/ux/interaction-patterns.md`

Do NOT invent or assume patterns from the feature name or GDD alone. If the user chooses (b), explicitly instruct ui-programmer in Phase 3 to treat all patterns as new and document them in `design/ux/interaction-patterns.md` when implementation is complete. Note the pattern library status (created / absent / updated) in the final summary report.
**不要**仅凭功能名或 GDD 就发明或假定模式。若用户选择 (b)，在阶段 3 明确指示 ui-programmer 将所有模式视为新模式，并在实现完成时将它们记录在 `design/ux/interaction-patterns.md` 中。在最终总结报告中注明模式库状态（已创建 / 缺失 / 已更新）。

Summarize the context in a brief for the ux-designer: what the player is doing, what they need, what constraints apply, and which existing patterns are relevant.
将上下文总结成给 ux-designer 的简报：玩家正在做什么、他们需要什么、适用哪些约束，以及哪些既有模式相关。

### Phase 1b: UX Spec Authoring
### 阶段 1b：UX 规范撰写

Invoke `/ux-design [feature name]` skill OR delegate directly to ux-designer to produce `design/ux/[feature-name].md` following the `ux-spec.md` template.
调用 `/ux-design [feature name]` 技能，或直接委派给 ux-designer，按 `ux-spec.md` 模板产出 `design/ux/[feature-name].md`。

If designing the HUD, use the `hud-design.md` template instead of `ux-spec.md`.
若设计 HUD，则使用 `hud-design.md` 模板而非 `ux-spec.md`。

> **Notes on special cases:**
> - For HUD design specifically, invoke `/ux-design` with `argument: hud` (e.g., `/ux-design hud`).
> - For the interaction pattern library, run `/ux-design patterns` once at project start and update it whenever new patterns are introduced during later phases.
> **特殊情况说明：**
> - 专门针对 HUD 设计，调用 `/ux-design` 并传入 `argument: hud`（例如 `/ux-design hud`）。
> - 对于交互模式库，在项目开始时运行一次 `/ux-design patterns`，并在后续阶段引入新模式时随时更新它。

Output: `design/ux/[feature-name].md` with all required spec sections filled.
输出：`design/ux/[feature-name].md`，所有必需的规范小节均已填写。

### Phase 1c: UX Review
### 阶段 1c：UX 评审

After the spec is complete, invoke `/ux-review design/ux/[feature-name].md`.
规范完成后，调用 `/ux-review design/ux/[feature-name].md`。

**Gate**: Do not proceed to Phase 2 until the verdict is APPROVED. If the verdict is NEEDS REVISION, the ux-designer must address the flagged issues in the same spec — it is kept and revised, never discarded — and re-run the review. The user may explicitly accept a NEEDS REVISION risk and proceed, but this must be a conscious decision — present the specific concerns via `AskUserQuestion` before asking whether to proceed.
**门禁**：在裁决为 APPROVED 之前，不得进入阶段 2。若裁决为 NEEDS REVISION，ux-designer 必须在同一份规范中处理被标记的问题 — 该规范被保留并修订，绝不丢弃 — 然后重跑评审。用户可以明确接受 NEEDS REVISION 的风险并继续，但这必须是有意识的决定 — 在询问是否继续之前，通过 `AskUserQuestion` 呈现具体关切。

A **NOT ASSESSED** verdict blocks the same way, and the user may override it the same way. Its fix is an input, not a revision: present the dimensions `/ux-review` could not assess and the missing input for each (e.g. `/ux-design accessibility` for an uncommitted tier). Re-running the review without that input returns the same verdict, so offer to produce the input first.
**NOT ASSESSED** 裁决以同样方式阻塞，用户也可用同样方式覆盖它。它的修复方式是补充输入，而非修订：呈现 `/ux-review` 无法评估的维度以及每项缺失的输入（例如对未承诺的层级运行 `/ux-design accessibility`）。在没有该输入的情况下重跑评审会得到相同裁决，因此应先提议产出该输入。

When the user proceeds past NEEDS REVISION or NOT ASSESSED, the final report records the override: the verdict, the concerns or unassessed dimensions left open, and that the user chose to proceed.
当用户越过 NEEDS REVISION 或 NOT ASSESSED 继续时，最终报告记录该覆盖：裁决、被搁置的关切或未评估维度，以及用户选择继续这一事实。

### Phase 2: Visual Design
### 阶段 2：视觉设计

Delegate to **art-director**:
- Review the full UX spec (flows, wireframes, interaction patterns, accessibility notes) — not just the wireframe images
- Apply visual treatment from the art bible: colors, typography, spacing, animation style
- Check that visual design preserves accessibility compliance: verify color contrast ratios, and confirm color is never the only indicator of state (shape, text, or icon must reinforce it)
- Specify all asset requirements needed from the art pipeline: icons at specified sizes, background textures, fonts, decorative elements — with precise dimensions and format requirements
- Ensure consistency with existing implemented UI screens
- Output: visual design spec with style notes and asset manifest
委派给 **art-director**：
- 审阅完整的 UX 规范（流程、线框图、交互模式、可访问性说明）— 不只是线框图图像
- 应用美术圣经中的视觉处理：颜色、字体、间距、动画风格
- 检查视觉设计保持可访问性合规：核验颜色对比度比值，并确认颜色绝不是状态的唯一指示（形态、文字或图标必须强化它）
- 明确说明美术流程所需的所有资产要求：指定尺寸的图标、背景纹理、字体、装饰元素 — 附精确尺寸与格式要求
- 确保与既有已实现 UI 界面的一致性
- 输出：附风格说明与资产清单的视觉设计规范

### Phase 3: Implementation
### 阶段 3：实现

Before implementation begins, spawn the **engine UI specialist** (`specialists.ui` from `project.yaml`; if absent, the UI Specialist line of `## Engine Specialists` in `.claude/docs/technical-preferences.md`) to review the UX spec and visual design spec for engine-specific implementation guidance:
- Which engine UI framework should be used for this screen? (e.g., UI Toolkit vs UGUI in Unity, Control nodes vs CanvasLayer in Godot, UMG vs CommonUI in Unreal)
- Any engine-specific gotchas for the proposed layout or interaction patterns?
- Recommended widget/node structure for the engine?
- Output: engine UI implementation notes to hand off to ui-programmer before they begin
在实现开始之前，启动 **engine UI specialist**（`project.yaml` 中的 `specialists.ui`；若缺失，则用 `.claude/docs/technical-preferences.md` 中 `## Engine Specialists` 的 UI Specialist 行），审阅 UX 规范与视觉设计规范以获得引擎专属实现指导：
- 此界面应使用哪个引擎 UI 框架？（例如 Unity 中的 UI Toolkit 与 UGUI、Godot 中的 Control 节点与 CanvasLayer、Unreal 中的 UMG 与 CommonUI）
- 对拟议布局或交互模式是否有引擎专属陷阱？
- 推荐的引擎控件/节点结构？
- 输出：引擎 UI 实现说明，供 ui-programmer 在开始前接手

If no engine is configured, skip this step. **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.
若未配置引擎，跳过此步骤。**在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一个什么都不说的跳过检查，与一个已通过的检查无法区分；读者无法分辨引擎指导从未被寻求过。

Delegate to **ui-programmer**:
- Implement the UI following the UX spec and visual design spec
- **Use patterns from `design/ux/interaction-patterns.md`** — do not reinvent patterns that are already specified. If a pattern almost fits but needs modification, note the deviation and flag it for ux-designer review.
- **UI NEVER owns or modifies game state** — display only; emit events for all player actions
- All text through the localization system — no hardcoded player-facing strings
- Support both input methods (keyboard/mouse AND gamepad)
- Implement accessibility features per the committed tier in `design/accessibility-requirements.md`
- Wire up data binding to game state
- **If any new interaction pattern is created during implementation** (i.e., something not already in the pattern library), add it to `design/ux/interaction-patterns.md` before marking implementation complete
- Output: implemented UI feature
委派给 **ui-programmer**：
- 按 UX 规范与视觉设计规范实现 UI
- **使用 `design/ux/interaction-patterns.md` 中的模式** — 不要重新发明已指定的模式。若某模式几乎契合但需要修改，记录该偏离并标记给 ux-designer 评审。
- **UI 绝不拥有或修改游戏状态** — 只做显示；为所有玩家动作发出事件
- 所有文本都经由本地化系统 — 不得硬编码面向玩家的字符串
- 支持两种输入方式（键盘/鼠标**与**手柄）
- 按 `design/accessibility-requirements.md` 中已承诺的层级实现可访问性功能
- 接好与游戏状态的数据绑定
- **若实现期间创建了任何新的交互模式**（即模式库中尚不存在的内容），在将实现标记为完成之前将其加入 `design/ux/interaction-patterns.md`
- 输出：已实现的 UI 功能

### Phase 4: Review (parallel)
### 阶段 4：评审（并行）

Delegate in parallel:
- **ux-designer**: Verify implementation matches wireframes and interaction spec. Test keyboard-only and gamepad-only navigation. Check accessibility features function correctly.
- **art-director**: Verify visual consistency with art bible. Check at minimum and maximum supported resolutions.
- **accessibility-specialist**: Verify compliance against the committed accessibility tier documented in `design/accessibility-requirements.md`. Flag any violations as blockers. **If that file is absent there is no committed tier, so this gate has no criterion: report `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)` and do NOT report the gate as passed**. Carry forward whatever tier Phase 1a recorded as assumed, and say plainly that it was assumed.
并行委派：
- **ux-designer**：核验实现符合线框图与交互规范。测试仅键盘与仅手柄导航。检查可访问性功能正常工作。
- **art-director**：核验与美术圣经的视觉一致性。在最小与最大支持分辨率下检查。
- **accessibility-specialist**：核验对照 `design/accessibility-requirements.md` 中记录的已承诺可访问性层级的合规性。将任何违规标记为阻塞项。**若该文件缺失，就没有已承诺的层级，因此此门禁没有标准：报告 `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`，且**不得**将门禁报告为已通过**。传递阶段 1a 记录为假设的任何层级，并明确说明它是假设的。

All three review streams must report before proceeding to Phase 5.
三条评审流都必须在进入阶段 5 之前提交报告。

### Phase 5: Polish
### 阶段 5：打磨

- Address all review feedback
- Verify animations are skippable and respect the player's motion reduction preferences
- Confirm UI sounds trigger through the audio event system (no direct audio calls)
- Test at all supported resolutions and aspect ratios
- **Verify `design/ux/interaction-patterns.md` is up to date** — if any new patterns were introduced during this feature's implementation, confirm they have been added to the library
- **Confirm all HUD elements respect the visual budget** defined in `design/ux/hud.md` (element count, screen region allocations, maximum opacity values)
- 处理所有评审反馈
- 核验动画可跳过，并尊重玩家的减少动态偏好
- 确认 UI 音效通过音频事件系统触发（无直接音频调用）
- 在所有支持的分辨率与宽高比下测试
- **核验 `design/ux/interaction-patterns.md` 是最新的** — 若在此功能实现期间引入了任何新模式，确认它们已加入该库
- **确认所有 HUD 元素遵守 `design/ux/hud.md` 中定义的视觉预算**（元素数量、屏幕区域分配、最大不透明度值）

## Quick Reference — When to Use Which Skill
## 快速参考 — 何时使用哪个技能

- `/ux-design` — Author a new UX spec for a screen, flow, or HUD from scratch
- `/ux-review` — Validate a completed UX spec before implementation
- `/team-ui [feature]` — Full pipeline from concept through polish (calls `/ux-design` and `/ux-review` internally)
- `/quick-design` — Small UI changes that don't need a full new UX spec
- `/ux-design` — 从零为某个界面、流程或 HUD 编写新的 UX 规范
- `/ux-review` — 在实现之前验证已完成的 UX 规范
- `/team-ui [feature]` — 从概念到打磨的完整流程（内部调用 `/ux-design` 与 `/ux-review`）
- `/quick-design` — 不需要完整新 UX 规范的小型 UI 改动

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
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.
若任何被启动的智能体返回 BLOCKED、出错或无法完成：**立即呈现它，
不要越过它所阻塞的依赖继续推进，并始终产出部分报告。** 被跳过智能体的小节
仍是一个具名缺口 — 绝不要用你自己的内容填补它。完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
常见阻塞项：
- 输入文件缺失（未找到故事、GDD 缺失）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实施；一旦决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆成两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测

## File Write Protocol
## 文件写入协议

All file writes (UX specs, interaction pattern library updates, implementation files) are
delegated to sub-agents and sub-skills. The two follow **different** rules:
所有文件写入（UX 规范、交互模式库更新、实现文件）都
委派给子智能体与子技能。二者遵循**不同**的规则：

- **Sub-agents spawned via `Agent`** (e.g. `ui-programmer`) follow the **bounded
  exception** documented above under "Why this does not violate the Collaboration
  Protocol" — the path is one you named, the artifact is new under `production/`,
  `docs/` or `tests/`, and the phase is gated by an `AskUserQuestion`. A sub-agent
  does **not** prompt per write inside those bounds; outside them it must ask.
  **Implementation files** (ui-programmer's code under the code root) are outside
  those bounds: ui-programmer returns the files it will create or change, you ask
  once for the set, and it writes after a yes.
- **Sub-skills** (`/ux-design`) are not sub-agents and the exception does not reach
  them. They follow the normal Collaboration Protocol and ask before writing.
- **通过 `Agent` 启动的子智能体**（例如 `ui-programmer`）遵循上文"Why this does not
  violate the Collaboration Protocol"下记录的**有界例外** — 路径是你点名的、制品是
  `production/`、`docs/` 或 `tests/` 下的新文件，且该阶段受 `AskUserQuestion` 门禁约束。
  在这些界限之内，子智能体**不会**逐次写入提示；超出界限则必须询问。
  **实现文件**（ui-programmer 在代码根下的代码）在这些界限之外：
  ui-programmer 返回它将创建或更改的文件，你就该集合询问一次，它在得到同意后才写入。
- **子技能**（`/ux-design`）不是子智能体，例外不及于它们。
  它们遵循常规协作协议，写入前询问。

This orchestrator does not write files directly.
此编排器不直接写文件。

## Output
## 输出

A summary report covering: UX spec status, UX review verdict, visual design status, implementation status, accessibility compliance, input method support, interaction pattern library update status, and any outstanding issues.
一份总结报告，涵盖：UX 规范状态、UX 评审裁决、视觉设计状态、实现状态、可访问性合规、输入方式支持、交互模式库更新状态，以及任何未决问题。

Verdict: **COMPLETE** — UI feature delivered through full pipeline (UX spec → visual → implementation → review → polish).
裁决：**COMPLETE** — UI 功能已通过完整流程交付（UX 规范 → 视觉 → 实现 → 评审 → 打磨）。

If the accessibility gate (no committed tier) or the engine validation (no engine
configured) was NOT ASSESSED, the verdict names each one — never a plain COMPLETE:
若可访问性门禁（无已承诺层级）或引擎验证（未配置引擎）为
NOT ASSESSED，则裁决逐一命名它们 — 绝不是单纯的 COMPLETE：

Verdict: **COMPLETE — [accessibility | engine validation] NOT ASSESSED ([reason])** — UI feature delivered; the named check could not run.
裁决：**COMPLETE — [accessibility | engine validation] NOT ASSESSED ([reason])** — UI 功能已交付；所点名的检查无法运行。

Verdict: **BLOCKED** — pipeline halted; surface the blocker and its phase before stopping.
裁决：**BLOCKED** — 流程已中止；在停止之前呈现阻塞项及其所在阶段。

## Next Steps
## 后续步骤

- Run `/ux-review` on the final spec if not yet approved.
- Run `/code-review` on the UI implementation before closing stories.
- Run `/team-polish` if visual or audio polish pass is needed.
- 若最终规范尚未获批，运行 `/ux-review`。
- 在关闭故事之前对 UI 实现运行 `/code-review`。
- 若需要视觉或音频打磨，运行 `/team-polish`。
