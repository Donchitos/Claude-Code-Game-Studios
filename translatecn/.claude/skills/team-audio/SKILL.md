---
name: team-audio
description: "Orchestrate the audio team — audio-director, sound-designer, technical-artist, gameplay-programmer — direction through implementation."
argument-hint: "[feature or area to design audio for] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-audio/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-audio
description: "编排音频团队 — audio-director、sound-designer、technical-artist、gameplay-programmer — 从方向到实现。"
argument-hint: "[feature or area to design audio for] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-audio/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team Audio

# 音频团队

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-audio [feature or area to design audio for] [--review full|lean|solo]` — specify the feature or area to design audio for (e.g., `combat`, `main menu`, `forest biome`, `boss encounter`). Do not use `AskUserQuestion` here; output the guidance directly.

如果未提供参数，输出用法指导并退出，不派生任何智能体：
> Usage: `/team-audio [feature or area to design audio for] [--review full|lean|solo]` — 指定要为其设计音频的功能或区域（例如 `combat`、`main menu`、`forest biome`、`boss encounter`）。此处不要使用 `AskUserQuestion`；直接输出指导。

When this skill is invoked with an argument, orchestrate the audio team through a structured pipeline.

当带参数调用本技能时，通过结构化流水线编排音频团队。

**Decision Points:** At each step transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next step.
In `guided` mode the pipeline advances automatically unless a step is BLOCKED;
in `autonomous` mode it runs end to end, recording each step outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**决策点：** 在每个步骤转换处，使用 `AskUserQuestion` 将
子智能体的提案作为可选项呈现给用户。在对话中写入智能体的
完整分析，然后用简洁标签捕获决策。
在 `collaborative` 模式下，用户必须批准后才能进入下一步。
在 `guided` 模式下，除非某步骤为 BLOCKED，流水线自动推进；
在 `autonomous` 模式下，它端到端运行，通过
`log_decision` 记录每一步的结果。`automation_always_ask` 类别中的决策
（`is_always_ask_category` 辅助函数）无论模式如何都始终提示。参见
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

`review_mode` 设置总监门禁的深度，而本流水线没有总监门禁：
下面任何阶段在任何 `review_mode` 下都不会派生 CD-、TD-、PR- 或 AD-PHASE-GATE。它的
阶段门禁是流水线自身的决策点（定义于下面的 `team.size` 之下），
而在这些决策点工作的智能体是团队成员，不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

`automation` 驱动上述决策点说明。参见上述决策点说明和
`.claude/docs/automation-modes.md`，了解每种模式如何改变流水线行为。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `sound-designer` only. Other agents consulted via the sound-designer, not spawned separately.
- **`small`**: + `audio-director` + `technical-artist` + `gameplay-programmer`.
- **`studio`**: + `accessibility-specialist` + the primary engine specialist (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**`team.size`**：哪些智能体处于活动状态（与 review_mode 门禁深度和 workflow 文档正交）。
- **`individual`**（默认）：仅 `sound-designer`。其他智能体通过 sound-designer 咨询，不单独派生。
- **`small`**：+ `audio-director` + `technical-artist` + `gameplay-programmer`。
- **`studio`**：+ `accessibility-specialist` + 主引擎专家（如文档所述的完整流水线）。
在 `individual` 下需要非核心智能体时，经由最近的活动核心智能体路由，并附信息性说明。**"阶段门禁"是指本流水线自身列出的、以 `AskUserQuestion` 决策点结束的任何阶段** — 上述决策点下的一个转换，或下面写入流水线的 **Gate** 步骤 — **无论 `automation` 模式为何。** `guided` 和 `autonomous` 改变的是门禁如何通过（自动推进，或用 `log_decision` 记录），而不是它是否为门禁，因此下面的有界例外条件 (3) 在每种模式下都对其成立。被限制为"仅阶段门禁"的智能体只在这些点派生，不在其他点派生。这一活动集范围界定适用于下面的整个流水线：任何点名了活动集之外智能体的阶段，都经由最近的核心智能体路由，而不是派生它。

**Announce the active set before Step 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

**在步骤 1 之前宣告活动集 — 绝不要让这种收缩保持沉默。**
在派生任何东西之前，用一行说明本次运行实际会派生哪些智能体，
以及下面流水线点名但在所解析的 `team.size` 下**不会**派生哪些。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

从紧接上方的 `team.size` 列表和本文件自身流水线点名的智能体来填充它 —
而不是从示例。两个集合因编排器而异。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

下面的流水线读起来像多智能体扇出，而按出厂默认它
是一或两个智能体 — `team-release` 点名十个却运行一个，`team-narrative`
跨五个阶段点名六个却只运行 `writer`。**这种收缩是正确的**：
`team.size` 以严谨度为前置，窄默认正是 token 杠杆。
若不这样说明，读者就无法
分辨一次正确收缩的运行与一条损坏的流水线，而前面那条
"经由最近的核心智能体路由并附信息性说明"的逐智能体规则
在路由时触发，从不说明整次运行的形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

这与本文件其他地方的跳过检查报告是同一条规则：**一项被强制执行却从未呈现的约束，
对阅读输出的人而言，与一项从未被强制执行的约束无法区分。**

1. **Read the argument** for the target feature or area (e.g., `combat`,
   `main menu`, `forest biome`, `boss encounter`).

2. **Gather context**:
   - Read relevant design docs in `design/gdd/` for the feature, by section: find the
     headings you need with the Grep tool (pattern `^#`, content mode) and Read
     those ranges with offset and limit
   - Read the sound bible at `design/audio/sound-bible.md` if it exists. If only
     `design/gdd/sound-bible.md` exists (where earlier versions put it), read that
     and recommend moving it to `design/audio/` — in `design/gdd/` the GDD checks
     count every file as a system GDD. If neither exists,
     say so in one line — "No sound bible at `design/audio/sound-bible.md`; audio
     direction starts from the GDDs alone" — so the gap is visible in the output.
     Carry the gap forward: say so in the audio-director's Step 1 brief, and
     recommend creating a sound bible in Next Steps.
   - Read existing audio asset lists in `assets/audio/`
   - Read any existing sound design docs for this area

1. **读取参数**以获取目标功能或区域（例如 `combat`、
   `main menu`、`forest biome`、`boss encounter`）。

2. **收集上下文**：
   - 按章节读取 `design/gdd/` 中与该功能相关的设计文档：用 Grep 工具
     （pattern `^#`，content 模式）找到所需标题，再用 offset 和 limit
     读取那些区间
   - 若存在 `design/audio/sound-bible.md`，读取声音圣经。若仅存在
     `design/gdd/sound-bible.md`（早期版本放置的位置），读取它
     并建议将其移动到 `design/audio/` — 在 `design/gdd/` 中，GDD 检查
     会把每个文件都当作系统 GDD 计数。若两者都不存在，
     用一行说明 — "No sound bible at `design/audio/sound-bible.md`; audio
     direction starts from the GDDs alone" — 使该缺口在输出中可见。
     将该缺口向前传递：在给 audio-director 的步骤 1 简报中说明它，并在 Next Steps 中
     建议创建一份声音圣经。
   - 读取 `assets/audio/` 中既有的音频资产列表
   - 读取该区域任何既有的声音设计文档

## How to Delegate

## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: audio-director` — Sonic identity, emotional tone, audio palette
- `subagent_type: sound-designer` — SFX specifications, audio events, mixing groups
- `subagent_type: accessibility-specialist` — Visual fallbacks and subtitles for critical audio, auditory sensitivity
- `subagent_type: technical-artist` — Audio middleware, bus structure, memory budgets
- `subagent_type: [primary engine specialist]` — Validate audio integration patterns for the engine
- `subagent_type: gameplay-programmer` — Audio manager, gameplay triggers, adaptive music

使用 `Agent` 工具将每个团队成员派生为子智能体：
- `subagent_type: audio-director` — 音效身份、情绪基调、音频调色板
- `subagent_type: sound-designer` — SFX 规格、音频事件、混音编组
- `subagent_type: accessibility-specialist` — 关键音频的视觉替代与字幕、听觉敏感度
- `subagent_type: technical-artist` — 音频中间件、总线结构、内存预算
- `subagent_type: [primary engine specialist]` — 针对引擎验证音频集成模式
- `subagent_type: gameplay-programmer` — 音频管理器、玩法触发、自适应音乐

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**为每个智能体写简报 — 不要倾倒上下文。** 只读取共享输入**一次**，并内联传递一份提炼过的简报：每个智能体实际需要的那几行，绝不给你已经读过的文档传文件路径（拿到路径的智能体会重读整个文件）。只为你未读过且只有该智能体需要的文档传递路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.

**在每个智能体提示末尾加上返回契约：** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." 若没有它，智能体会把它读过的一切重新返回本会话。**实现文件是例外：** 编写代码或资产的智能体先返回它将创建或更改的文件，且其返回契约仅在你一次性询问该集合、用户回答 yes 之后才点名它们（File Write Protocol）— 是那个回答，而非有界例外，授权这些写入。

**Substitute a real path for `[path]`.** Working artifacts go under
`production/audio/[feature]/`, where `[feature]` is the argument as a slug —
lowercase, spaces → hyphens (`boss encounter` → `boss-encounter`), the same slug
the "Save to" step uses. One file per agent, so parallel steps never share one:

| Step / agent | Writes to |
|---|---|
| 1 audio-director | `production/audio/[feature]/direction.md` |
| 2 sound-designer | `production/audio/[feature]/sfx-spec.md` |
| 2 accessibility-specialist | `production/audio/[feature]/accessibility.md` |
| 3 technical-artist | `production/audio/[feature]/integration-plan.md` |
| 3 engine specialist | `production/audio/[feature]/engine-notes.md` |
| 4 gameplay-programmer | the code root and the engine's test root — the files the one implementation ask lists (File Write Protocol), outside the bounded exception |

**用真实路径替换 `[path]`。** 工作产物放在
`production/audio/[feature]/` 下，其中 `[feature]` 是参数构成的 slug —
小写、空格 → 连字符（`boss encounter` → `boss-encounter`），与
"Save to" 步骤使用的 slug 相同。每个智能体一个文件，因此并行步骤绝不共享同一个：

| 步骤 / 智能体 | 写入至 |
|---|---|
| 1 audio-director | `production/audio/[feature]/direction.md` |
| 2 sound-designer | `production/audio/[feature]/sfx-spec.md` |
| 2 accessibility-specialist | `production/audio/[feature]/accessibility.md` |
| 3 technical-artist | `production/audio/[feature]/integration-plan.md` |
| 3 engine specialist | `production/audio/[feature]/engine-notes.md` |
| 4 gameplay-programmer | 代码根目录和引擎的测试根目录 — 单次实现询问所列的文件（File Write Protocol），在有界例外之外 |

These are working drafts; the durable record is the audio design document you
compile from them.

这些是工作草稿；持久记录是你从它们编译出的音频设计文档。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问 "May I write this to [filepath]?"。此处派生的子智能体**不**询问就写入，这是经过深思熟虑的有界例外，而非疏漏 — 与 `consistency-check` 追加到 `active.md` 时已做的同一决定。该例外仅在以下三者同时成立时适用：(1) 路径是**你**在提示中点名的，因此用户在批准该阶段时即批准了目的地；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不是对既有源码或配置的编辑；(3) 产出它的阶段本身在流水线推进前由 `AskUserQuestion` 门控。三者之外，智能体必须询问。**不要通过逐子智能体询问来"修复"这一点** — 每阶段每智能体一次提示会让编排器不可用，这正是该例外存在的原因。

3. **Orchestrate the audio team** in sequence:

3. **按顺序编排音频团队**：

### Step 1: Audio Direction (audio-director)

### 步骤 1：音频方向（audio-director）

Spawn the `audio-director` agent to:
- Define the sonic identity for this feature/area
- Specify the emotional tone and audio palette
- Set music direction (adaptive layers, stems, transitions)
- Define audio priorities and mix targets
- Establish any adaptive audio rules (combat intensity, exploration, tension)

派生 `audio-director` 智能体以：
- 定义该功能/区域的音效身份
- 指定情绪基调与音频调色板
- 设置音乐方向（自适应层、分轨、转场）
- 定义音频优先级与混音目标
- 建立任何自适应音频规则（战斗强度、探索、紧张感）

### Step 2: Sound Design and Audio Accessibility (parallel)

### 步骤 2：声音设计与音频无障碍（并行）

Spawn the `sound-designer` agent to:
- Create detailed SFX specifications for every audio event
- Define sound categories (ambient, UI, gameplay, music, dialogue)
- Specify per-sound parameters (volume range, pitch variation, attenuation)
- Plan audio event list with trigger conditions
- Define mixing groups and ducking rules

派生 `sound-designer` 智能体以：
- 为每个音频事件创建详细的 SFX 规格
- 定义声音类别（环境、UI、玩法、音乐、对话）
- 指定逐声音参数（音量范围、音高变化、衰减）
- 规划带触发条件的音频事件列表
- 定义混音编组与闪避规则

Spawn the `accessibility-specialist` agent in parallel to:
- Identify which audio events carry critical gameplay information (damage received, enemy nearby, objective complete) and require visual alternatives for hearing-impaired players
- Specify subtitle requirements: which audio events need captions, what text format, on-screen duration
- Check that no gameplay state is communicated by audio alone (all must have a visual fallback)
- Review the audio event list for any that could cause issues for players with auditory sensitivities (high-frequency alerts, sudden loud events)
- Output: audio accessibility requirements list integrated into the audio event spec

并行派生 `accessibility-specialist` 智能体以：
- 识别哪些音频事件承载关键玩法信息（受到伤害、敌人在附近、目标完成），并需要为听障玩家提供视觉替代
- 指定字幕需求：哪些音频事件需要字幕、文本格式、屏幕停留时长
- 检查没有玩法状态仅由音频传达（全部必须有视觉回退）
- 审查音频事件列表，找出任何可能给听觉敏感玩家带来问题的项（高频警报、突然的巨响事件）
- 输出：整合进音频事件规格的音频无障碍需求列表

A gameplay-critical audio event with no visual cue or subtitle is labelled
**BLOCKING** in the report, not advisory. Step 3 does not start until the user
resolves it or explicitly accepts it at the Step 2 decision point, which offers
the fix (a visual cue, subtitle or haptic fallback) and a stop; an accepted gap
is listed among the open questions in the summary.

没有视觉提示或字幕的玩法关键音频事件在报告中标记为
**BLOCKING**，而非建议性。步骤 3 要等到用户在步骤 2 决策点
解决它或明确接受它之后才启动，该决策点提供
修复方案（视觉提示、字幕或触觉回退）和停止选项；被接受的缺口
列在摘要的开放问题中。

### Step 3: Technical Implementation (parallel)

### 步骤 3：技术实现（并行）

Spawn the `technical-artist` agent to:
- Design the audio middleware integration (Wwise/FMOD/native)
- Define audio bus structure and routing
- Specify memory budgets for audio assets per platform
- Plan streaming vs preloaded asset strategy
- Design any audio-reactive visual effects

派生 `technical-artist` 智能体以：
- 设计音频中间件集成（Wwise/FMOD/原生）
- 定义音频总线结构与路由
- 指定各平台音频资产的内存预算
- 规划流式加载 vs 预加载资产策略
- 设计任何音频响应的视觉效果

Spawn the **primary engine specialist** in parallel (`<engine>-specialist` derived from `engine.name` — Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`; fall back to the Primary line of `## Engine Specialists` in `.claude/docs/technical-preferences.md`) to validate the integration approach:
- Is the proposed audio middleware integration idiomatic for the engine? (e.g., Godot's built-in AudioStreamPlayer vs FMOD, Unity's Audio Mixer vs Wwise, Unreal's MetaSounds vs FMOD)
- Any engine-specific audio node/component patterns that should be used?
- Known audio system changes in the pinned engine version that affect the integration plan?
- Output: engine audio integration notes to merge with the technical-artist's plan

并行派生**主引擎专家**（由 `engine.name` 推导的 `<engine>-specialist` — Godot→`godot-specialist`，Unity→`unity-specialist`，Unreal→`unreal-specialist`；回退到 `.claude/docs/technical-preferences.md` 中 `## Engine Specialists` 的 Primary 行）以验证集成方案：
- 提议的音频中间件集成对该引擎是否地道？（例如 Godot 内置的 AudioStreamPlayer vs FMOD、Unity 的 Audio Mixer vs Wwise、Unreal 的 MetaSounds vs FMOD）
- 是否有应使用的引擎专属音频节点/组件模式？
- 所锁定引擎版本中已知的音频系统变更是否影响集成计划？
- 输出：引擎音频集成说明，与 technical-artist 的计划合并

If no engine is configured, skip the specialist spawn. **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.

如果未配置引擎，跳过专家派生。**在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一项什么都不说的跳过检查与一项通过的检查无法区分；读者无法分辨从未寻求过引擎指导。

### Step 4: Code Integration (gameplay-programmer)

### 步骤 4：代码集成（gameplay-programmer）

Spawn the `gameplay-programmer` agent to:
- Implement audio manager system or review existing
- Wire up audio events to gameplay triggers
- Implement adaptive music system (if specified)
- Set up audio occlusion/reverb zones
- Write unit tests for audio event triggers

派生 `gameplay-programmer` 智能体以：
- 实现音频管理器系统或评审既有的
- 将音频事件接入玩法触发
- 实现自适应音乐系统（若已指定）
- 设置音频遮挡/混响区域
- 为音频事件触发编写单元测试

4. **Compile the audio design document** combining all team outputs.

4. **编译音频设计文档**，合并所有团队输出。

5. **Save to** `design/audio/audio-[feature].md` — **but ask first.** `design/` is
   NOT one of the three directories the bounded write exception covers
   (`production/`, `docs/`, `tests/`), so a sub-agent handed this path must
   prompt. Do not
   resolve that by widening the exception. Instead, follow the same pattern
   `team-level` uses: **you** already hold every sub-agent's output, so compile
   the document yourself and ask directly via `AskUserQuestion` — "May I write the
   audio design to `design/audio/audio-[feature].md`?" — then write it on
   approval. Sub-agent working artifacts stay under `production/` where the
   exception does reach them.

5. **保存到** `design/audio/audio-[feature].md` — **但先询问。** `design/` 不是
   有界写入例外覆盖的三个目录之一
   （`production/`、`docs/`、`tests/`），因此拿到此路径的子智能体必须
   提示。不要
   通过扩大例外来解决这一点。相反，沿用
   `team-level` 使用的同一模式：**你**已经持有每个子智能体的输出，因此自己编译
   文档并通过 `AskUserQuestion` 直接询问 — "May I write the
   audio design to `design/audio/audio-[feature].md`?" — 然后在
   批准后写入。子智能体的工作产物留在 `production/` 下，例外确实覆盖那里。

   Note: If `design/audio/` does not exist, writing the file creates it.

   注意：若 `design/audio/` 不存在，写入文件会创建它。

6. **Output a summary** with: audio event count, estimated asset count,
   implementation tasks, and any open questions between team members.

6. **输出摘要**，包含：音频事件数量、估算资产数量、
   实现任务，以及团队成员之间的任何开放问题。

Verdict: **COMPLETE** — audio design document produced and team pipeline finished.

结论：**COMPLETE** — 音频设计文档已产出，团队流水线已完成。

If the engine validation was skipped (no engine configured), the verdict says
so — never a plain COMPLETE:

如果引擎验证被跳过（未配置引擎），结论要说明
这一点 — 绝不是单纯的 COMPLETE：

Verdict: **COMPLETE — engine validation NOT ASSESSED ([reason])** — audio design document produced; the engine specialist never reviewed the integration plan.

结论：**COMPLETE — engine validation NOT ASSESSED ([reason])** — 音频设计文档已产出；引擎专家从未评审集成计划。

If the pipeline stops because a dependency is unresolved (e.g., critical accessibility gap or missing GDD not resolved by the user):

如果流水线因依赖未解决而停止（例如关键无障碍缺口或缺失的 GDD 未被用户解决）：

Verdict: **BLOCKED** — [reason]

结论：**BLOCKED** — [reason]

## File Write Protocol

## 文件写入协议

Per-agent artifacts (SFX specs, integration plans) are written by the sub-agent
that produced them, under the **bounded exception** documented above under "Why
this does not violate the Collaboration Protocol" — the path is one you named, the
artifact is new under `production/`, `docs/` or `tests/`, and the phase is gated by
an `AskUserQuestion`. A sub-agent does **not** prompt per write inside those bounds;
outside them it must ask. **Implementation files** — gameplay-programmer's audio
integration code, anything under the code root or `assets/` — are outside those
bounds: the agent returns the files it will create or change, you ask once for the
set, and it writes after a yes. The **one exception is the final compiled audio design
document**: the orchestrator already holds every input, so it compiles and writes
`design/audio/audio-[feature].md` itself after its own "May I write …?" prompt
(the "Save to" step above).

逐智能体产物（SFX 规格、集成计划）由产出它们的子智能体写入，
依据上面"Why this does not violate the Collaboration Protocol"中记录的**有界例外** — 路径是你点名的，产物是
`production/`、`docs/` 或 `tests/` 下的新文件，且该阶段由
`AskUserQuestion` 门控。子智能体在这些边界内**不会**逐次写入都提示；
边界之外它必须询问。**实现文件** — gameplay-programmer 的音频
集成代码、代码根目录或 `assets/` 下的任何内容 — 在这些
边界之外：智能体返回它将创建或更改的文件，你一次性询问该
集合，它在得到 yes 后写入。**唯一的例外是最终编译的音频设计
文档**：编排器已持有每个输入，因此它在自己的 "May I write …?" 提示（上面的
"Save to" 步骤）之后自行编译并写入
`design/audio/audio-[feature].md`。

## Next Steps

## 后续步骤

- Review the audio design doc with the audio-director before implementation begins.
- Use `/dev-story` to implement the audio manager and event system once the design is approved.
- Run `/asset-audit` after audio assets are created to verify naming and format compliance.
- If there was no sound bible, create one before the next audio pass: ask the
  `audio-director` agent to draft `design/audio/sound-bible.md` from
  `.claude/docs/templates/sound-bible.md`, starting from this run's Step 1
  direction (it asks before writing under `design/`).

- 在实现开始前，与 audio-director 一起评审音频设计文档。
- 设计获批后，使用 `/dev-story` 实现音频管理器和事件系统。
- 音频资产创建后，运行 `/asset-audit` 验证命名与格式合规性。
- 若没有声音圣经，在下一次音频工作之前创建一份：让
  `audio-director` 智能体依据
  `.claude/docs/templates/sound-bible.md` 起草 `design/audio/sound-bible.md`，从本次运行的步骤 1
  方向开始（它在写入 `design/` 之前会询问）。

## Error Recovery Protocol

## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

**首先，验证产物。** 如果返回契约点名了路径，在把该阶段视为完成之前检查
该路径是否存在 — **一个被点名却不在磁盘上的产物就是一个失败的阶段，无论回应读起来多流畅。**
智能体可以耗费一整个阶段、什么都没写却返回一段看似合理的前言，
这既不是 BLOCKED，也不是错误，也不是"无法完成"，因此下面的触发器
永远不会触发。恢复它并指明未满足的契约；上下文
通常还在那里。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

如果任何被派生的智能体返回 BLOCKED、出错或无法完成：**立即呈现它，
不要越过它所阻断的依赖继续推进，并始终产出一份
部分报告。** 被跳过智能体的章节保持为具名缺口 — 绝不用你自己的内容填充它。完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

常见阻断项：
- 输入文件缺失（未找到故事、缺少 GDD）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦它被决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆分为两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测
