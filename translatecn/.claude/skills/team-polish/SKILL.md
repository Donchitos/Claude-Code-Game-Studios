---
name: team-polish
description: "Orchestrate the polish team — performance-analyst, technical-artist, sound-designer, qa-tester — to optimize and harden a feature or area."
argument-hint: "[feature or area to polish] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-polish/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-polish
description: "编排打磨团队——performance-analyst、technical-artist、sound-designer、qa-tester——以优化并加固某个功能或区域。"
argument-hint: "[feature or area to polish] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-polish/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Polish
# 团队打磨

If no argument is provided, output usage guidance and exit without spawning any agents:
如果没有提供参数，输出用法指引并退出，不启动任何智能体：
> Usage: `/team-polish [feature or area to polish] [--review full|lean|solo]` — specify the feature or area to polish (e.g., `combat`, `main menu`, `inventory system`, `level-1`). Do not use `AskUserQuestion` here; output the guidance directly.
> 用法：`/team-polish [要打磨的功能或区域] [--review full|lean|solo]`——指定要打磨的功能或区域（例如 `combat`、`main menu`、`inventory system`、`level-1`）。此处不要使用 `AskUserQuestion`；直接输出指引。

When this skill is invoked with an argument, orchestrate the polish team through a structured pipeline.
当本技能带参数被调用时，通过一条结构化流水线编排打磨团队。

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.
**决策点：** 在每个阶段转换处，使用 `AskUserQuestion` 将子智能体的提案作为可选项呈现给用户。在对话中写出该智能体的完整分析，然后用简洁标签记录决策。在 `collaborative` 模式下，用户必须批准后才能进入下一阶段。在 `guided` 模式下，除非某阶段为 BLOCKED，流水线自动推进；在 `autonomous` 模式下，它端到端运行，并通过 `log_decision` 记录每个阶段的结果。`automation_always_ask` 类别中的决策（`is_always_ask_category` 辅助函数）无论何种模式都会提示。参见 `.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config
## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
已在上方解析——按原样使用；`--review` 覆盖 `review_mode`。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.
`review_mode` 设定总监门禁的深度，而本流水线没有总监门禁：在任一种 `review_mode` 下，下方没有任何阶段会启动 CD-、TD-、PR- 或 AD-PHASE-GATE。它的阶段门禁是流水线自身的决策点（定义于下方 `team.size` 之下），而在这些决策点工作的智能体是团队成员，不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.
`automation` 驱动上方的决策点说明。有关每种模式如何改变流水线行为，参见上方的决策点说明以及 `.claude/docs/automation-modes.md`。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `performance-analyst` + `technical-artist`. Other agents consulted via these two, not spawned separately. No programmer is active, so the optimisation list's programmer items are not implemented in this run — the report names the list as handed to `/dev-story` (Phase 2).
- **`small`**: + `sound-designer` + `qa-tester` + `engine-programmer`, and `tools-programmer` when Phase 1 traces a cause to a content authoring tool (the full pipeline as documented).
- **`studio`**: the `small` set, `engine-programmer` included, + an adversarial review pass: Phase 5's qa-tester is told "your job is not to confirm this holds — find how it breaks", and the report says the pass ran. This pipeline has no engine specialist to widen; engine-level work stays with `engine-programmer`.

**`team.size`**：哪些智能体处于活动状态（与 review_mode 的门禁深度和工作流文档相互正交）。
- **`individual`**（默认）：`performance-analyst` + `technical-artist`。其他智能体经由这两个智能体咨询，不单独启动。没有程序员处于活动状态，因此优化清单中的程序员事项不会在本次运行中实现——报告会注明该清单已移交至 `/dev-story`（阶段 2）。
- **`small`**：增加 `sound-designer` + `qa-tester` + `engine-programmer`，以及当阶段 1 将某个成因追溯到内容创作工具时增加 `tools-programmer`（即文档所述的完整流水线）。
- **`studio`**：即 `small` 集合（含 `engine-programmer`），外加一轮对抗式评审：阶段 5 会告知 qa-tester“你的职责不是确认它能成立——而是找出它会如何失效”，报告会注明该轮评审已执行。本流水线没有可扩展的引擎专家；引擎层面的工作仍归 `engine-programmer`。

A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.
在 `individual` 下需要的非核心智能体会经由最近的活动核心智能体路由，并附带一条信息性说明。**“阶段门禁”指本流水线自身列出的、以 `AskUserQuestion` 决策点结束的任何阶段**——上方决策点下的某个转换，或下方流水线中写明的某个**门禁（Gate）**步骤——**无论 `automation` 模式为何。** `guided` 与 `autonomous` 改变的是门禁如何通过（自动推进，或用 `log_decision` 记录），而非它是否为门禁，因此下方的有界例外条件 (3) 在任何模式下都对其成立。被限定为“仅限阶段门禁”的智能体只在那些点被启动，不涉其他。此活动集范围划定贯穿下方整个流水线：任何阶段若点名了活动集之外的智能体，都应经由最近的核心智能体路由，而非直接启动它。

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:
**在阶段 1 之前宣布活动集——绝不要让收缩悄无声息。**
在启动任何东西之前，用一行说明本次运行实际会启动哪些智能体，以及下方流水线点名但在所解析的 `team.size` 下**不会**启动哪些智能体。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`
> `活动集（team.size: <已解析值>）：<上文该规模下列出的智能体>。`
> `本次运行不启动：<本流水线点名的其他所有智能体>——经由`
> `<最近的活动核心智能体>咨询。提高 team.size（或 modes.rigor）以扩展。`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.
根据正上方的 `team.size` 列表以及本文件自身流水线点名的智能体来填写它——不要照抄示例。两个集合因编排器而异。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.
下方的流水线读起来像一次多智能体扇出，而在出厂默认下它是一两个智能体——`team-release` 点名十个却只运行一个，`team-narrative` 在五个阶段中点名六个却只单独运行 `writer`。**这种收缩是正确的**：`team.size` 以严谨度为先，而窄默认正是令牌杠杆。若不说明这一点，读者就无法区分一次正确收缩的运行与一条损坏的流水线，而上文那条“经由最近的核心智能体路由并附带信息性说明”的按智能体规则在路由时触发，从不说明运行的整体形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**
这与本文件其他位置关于跳过检查上报的规则相同：**一项被强制执行却从未浮出水面的约束，对阅读输出的人而言，与一项从未被执行的约束无法区分。**

## Team Composition
## 团队构成

- **performance-analyst** — Profiling, memory analysis, frame budget, and the optimisation list — it writes no game code
- **engine-programmer** — Implements the optimisation list's engine-level items: rendering pipeline, memory, resource loading, hot paths (invoke when performance-analyst identifies low-level root causes)
- **technical-artist** — VFX polish, shader optimization, visual quality
- **sound-designer** — Audio polish, mixing, ambient layers, feedback sounds
- **tools-programmer** — Content pipeline tool verification, editor tool stability, automation fixes (Phase 2, when Phase 1 traces a cause to a content authoring tool)
- **qa-tester** — Edge case testing, regression testing, soak testing
- **performance-analyst** — 性能剖析、内存分析、帧预算以及优化清单——它不编写游戏代码
- **engine-programmer** — 实现优化清单中的引擎层面事项：渲染管线、内存、资源加载、热点路径（当 performance-analyst 识别出底层根因时调用）
- **technical-artist** — 视觉特效打磨、着色器优化、视觉质量
- **sound-designer** — 音频打磨、混音、环境音层、反馈音效
- **tools-programmer** — 内容管线工具验证、编辑器工具稳定性、自动化修复（阶段 2，当阶段 1 将某个成因追溯到内容创作工具时）
- **qa-tester** — 边界情况测试、回归测试、浸泡测试

## How to Delegate
## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
使用 `Agent` 工具将每位团队成员作为子智能体启动：
- `subagent_type: performance-analyst` — Profiling, memory analysis, the optimisation list
- `subagent_type: engine-programmer` — Engine-level fixes from the optimisation list: rendering, memory, resource loading
- `subagent_type: technical-artist` — VFX polish, shader optimization, visual quality
- `subagent_type: sound-designer` — Audio polish, mixing, ambient layers
- `subagent_type: tools-programmer` — Content pipeline and editor tool fixes from the optimisation list
- `subagent_type: qa-tester` — Edge case testing, regression testing, soak testing
- `subagent_type: performance-analyst` — 性能剖析、内存分析、优化清单
- `subagent_type: engine-programmer` — 优化清单中的引擎层面修复：渲染、内存、资源加载
- `subagent_type: technical-artist` — 视觉特效打磨、着色器优化、视觉质量
- `subagent_type: sound-designer` — 音频打磨、混音、环境音层
- `subagent_type: tools-programmer` — 优化清单中的内容管线与编辑器工具修复
- `subagent_type: qa-tester` — 边界情况测试、回归测试、浸泡测试

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.
**为每个智能体撰写简报——不要倾倒上下文。** 将共享输入**只读一次**，并内联传入一份提炼过的简报：只传每个智能体真正需要的那些行，对于你已经读过的文档绝不要给文件路径（拿到路径的智能体会重新读取整份文件）。只有当你尚未读过、且只有该智能体需要某份文档时，才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.
**以返回契约结束每个智能体提示词：**“将你的完整输出写入 `[path]`——在下方有界例外下，该具名路径就是你的写入授权，因此无需另行请求批准即可写入。**仅**返回 (1) 已写入的路径，(2) 不超过 5 条的决策摘要，(3) 任何 BLOCKED/CONCERNS 事项，每项一行。不要复述你读过的文档。”没有它，智能体就会把它读过的一切都回灌到本次会话中。**实现文件是例外：** 编写代码或资产的智能体会首先返回它将创建或更改的文件，而它的返回契约只有在你就整个集合询问过一次且用户同意后才点名这些文件（文件写入协议）——是那个答复，而非有界例外，授权了这些写入。

**Substitute a real path for `[path]` — this skill's destination is
`production/polish/`.** Name it per agent, one file each:
**用真实路径替换 `[path]`——本技能的目的地是 `production/polish/`。** 按智能体逐一命名，每个智能体一个文件：

| Agent | Writes to |
|---|---|
| performance-analyst | `production/polish/[area]-report-[date].md` |
| technical-artist | `production/polish/[area]-render-notes-[date].md` |
| engine-programmer | `production/polish/[area]-engine-fixes-[date].md` |
| tools-programmer | `production/polish/[area]-tool-fixes-[date].md` |
| sound-designer | `production/polish/[area]-audio-notes-[date].md` |
| qa-tester | `production/polish/[area]-verification-[date].md` |

| 智能体 | 写入位置 |
|---|---|
| performance-analyst | `production/polish/[area]-report-[date].md` |
| technical-artist | `production/polish/[area]-render-notes-[date].md` |
| engine-programmer | `production/polish/[area]-engine-fixes-[date].md` |
| tools-programmer | `production/polish/[area]-tool-fixes-[date].md` |
| sound-designer | `production/polish/[area]-audio-notes-[date].md` |
| qa-tester | `production/polish/[area]-verification-[date].md` |

> **Why `production/` and not `docs/`.** These are date-stamped measurements of
> one run, the same shape as `production/qa/smoke-[date].md` — not durable
> specifications like `docs/architecture/`. Keeping them beside the other
> point-in-time process artifacts is what makes a later comparison possible.
>
> The `[path]` contract above has a precondition: the path is one *you* named, so
> a concrete destination must be stated here or every run invents one. Unlike
> `/team-qa` and `/team-narrative`, whose destinations are fixed by their
> consumers, this location has no reader in the repo and was chosen deliberately.
> **Nothing reads `production/polish/` yet** — say so when reporting, so the user
> knows the report is a record rather than an input to a later gate.
> **为何用 `production/` 而非 `docs/`。** 这些是针对单次运行、带日期戳的度量，与 `production/qa/smoke-[date].md` 形态相同——不是像 `docs/architecture/` 那样的耐久规格说明。把它们与其他时点性流程产物放在一起，才能使后续比较成为可能。
>
> 上方的 `[path]` 契约有一个前提：路径是*你*命名的，因此必须在此处声明一个具体目的地，否则每次运行都会自行发明一个。与 `/team-qa` 和 `/team-narrative` 不同（后两者的目的地由其使用者固定），该位置在仓库中没有读者，是有意选定的。**目前没有任何东西读取 `production/polish/`**——上报时请说明这一点，让用户知道该报告是一份记录，而非后续门禁的输入。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.
> **为何这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问“我可以把它写入 [filepath] 吗？”。此处启动的子智能体**不询问**即写入，这是一项有意为之、有界的例外，而非疏忽——与 `consistency-check` 追加到 `active.md` 时所采用的呼叫相同。该例外仅在以下三项全部为真时成立：(1) 路径是**你**在提示词中命名的，因此用户在批准该阶段时就批准了目的地；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不是对现有源代码或配置的编辑；(3) 产生它的阶段本身在流水线推进前已由 `AskUserQuestion` 把关。在这三项之外，智能体必须询问。**不要通过逐个子智能体询问来“修复”这一点**——每个智能体每个阶段都来一次提示会让编排器无法使用，这正是该例外存在的原因。

Launch independent agents in parallel where the pipeline allows it (e.g., Phases 3 and 4 can run simultaneously).
在流水线允许时并行启动相互独立的智能体（例如，阶段 3 和阶段 4 可以同时运行）。

## Pipeline
## 流水线

### Phase 1: Assessment
### 阶段 1：评估
Delegate to **performance-analyst**:
委派给 **performance-analyst**：
- Profile the target feature/area using `/perf-profile`
- Identify performance bottlenecks and frame budget violations
- Measure memory usage and check for leaks
- Benchmark against target hardware specs
- Output: performance report with the prioritized **optimisation list** — for each item, the change, its expected gain against the budget, and its owner (technical-artist for rendering-side changes, engine-programmer for engine systems and hot paths, tools-programmer for a content authoring tool, otherwise the programmer who owns the system)
- 使用 `/perf-profile` 对目标功能/区域进行性能剖析
- 识别性能瓶颈与帧预算违规
- 测量内存占用并检查泄漏
- 对照目标硬件规格进行基准测试
- 产出：含按优先级排列的**优化清单**的性能报告——对每一项给出变更、其相对预算的预期收益，以及其所有者（渲染侧变更归 technical-artist，引擎系统与热点路径归 engine-programmer，内容创作工具归 tools-programmer，否则归拥有该系统的程序员）

### Phase 2: Optimization
### 阶段 2：优化
performance-analyst writes no game code ("recommend and assign", its agent file),
so Phase 2 implements its Phase 1 list through the owners in the active set:
performance-analyst 不编写游戏代码（其智能体文件中写着“建议并指派”），因此阶段 2 通过活动集内的所有者来实现其阶段 1 清单：
- **engine-programmer** — spawned only when Phase 1 identified engine-level root causes (rendering pipeline, resource loading, memory allocator, hot paths in core loops): implement those items, fix allocation pressure, verify gameplay behavior is unchanged. Output: engine-level fixes with before/after metrics and profiler validation
- **tools-programmer** — only when Phase 1 traced a cause to a content authoring tool: fix the tool. Output: tool fixes with before/after metrics
- **technical-artist** — rendering-side items (draw calls, overdraw, particles, shaders, LOD) join its Phase 3 brief
- **engine-programmer** — 仅当阶段 1 识别出引擎层面的根因（渲染管线、资源加载、内存分配器、核心循环中的热点路径）时启动：实现这些事项、修复分配压力、验证玩法行为不变。产出：带有前后对比指标与剖析器验证的引擎层面修复
- **tools-programmer** — 仅当阶段 1 将某个成因追溯到内容创作工具时：修复该工具。产出：带有前后对比指标的工具修复
- **technical-artist** — 渲染侧事项（draw call、过度绘制、粒子、着色器、LOD）并入其阶段 3 简报

Every implementing agent in Phases 2–4 first returns the files it will create or
change, and you ask once for the whole Phase 2–4 set before any is edited (File
Write Protocol).
阶段 2–4 中的每个实施智能体都会先返回它将创建或更改的文件，而你在任何编辑发生之前，就整个阶段 2–4 集合询问一次（文件写入协议）。

**An item whose owner is not in the active set is not implemented in this run.**
At `team.size: individual` that is every programmer item, since no programmer is
active; at any size it includes an item owned by a programmer this pipeline does
not name (e.g. gameplay-programmer for a gameplay-script hot spot). The report
lists those items with their owners under
"Optimisation list handed to `/dev-story`: `production/polish/[area]-report-[date].md`".
A metric they target that is over budget stays a known problem at Phase 6.
**所有者不在活动集内的事项不会在本次运行中实现。** 在 `team.size: individual` 下，这就是每一个程序员事项，因为没有程序员处于活动状态；在任何规模下，这还包括归本流水线未点名的某个程序员所有的事项（例如玩法脚本热点归 gameplay-programmer）。报告会在“移交至 `/dev-story` 的优化清单：`production/polish/[area]-report-[date].md`”下列出这些事项及其所有者。它们所针对的、超出预算的指标在阶段 6 仍是已知问题。

### Phase 3: Visual Polish (parallel with Phase 2)
### 阶段 3：视觉打磨（与阶段 2 并行）
Delegate to **technical-artist**:
委派给 **technical-artist**：
- Review VFX for quality and consistency with art bible
- Optimize particle systems and shader effects
- Add screen shake, camera effects, and visual juice where appropriate
- Ensure effects degrade gracefully on lower settings
- Output: polished visual effects
- 审阅视觉特效的质量以及与美术圣经的一致性
- 优化粒子系统与着色器效果
- 在适当之处添加屏幕震动、镜头效果与视觉“汁水感”
- 确保效果在较低设置下优雅降级
- 产出：打磨后的视觉特效

### Phase 4: Audio Polish (parallel with Phase 2)
### 阶段 4：音频打磨（与阶段 2 并行）
Delegate to **sound-designer**:
委派给 **sound-designer**：
- Review audio events for completeness (are any actions missing sound feedback?)
- Check audio mix levels — nothing too loud or too quiet relative to the mix
- Add ambient audio layers for atmosphere
- Verify audio plays correctly with spatial positioning
- Output: audio polish list and mixing notes
- 审阅音频事件的完整性（是否有任何动作缺少音效反馈？）
- 检查音频混音电平——相对整体混音没有过响或过轻之处
- 添加环境音层以营造氛围
- 验证音频在空间定位下正确播放
- 产出：音频打磨清单与混音说明

### Phase 5: Hardening
### 阶段 5：加固
Delegate to **qa-tester**:
委派给 **qa-tester**：
- Test all edge cases: boundary conditions, rapid inputs, unusual sequences
- Soak test: run the feature for extended periods checking for degradation
- Stress test: maximum entities, worst-case scenarios
- Regression test: verify polish changes haven't broken existing functionality — each Phase 2–4 change by name, engine-level fixes included
- Test on minimum spec hardware (if available)
- Output: test results with any remaining issues
- 测试所有边界情况：边界条件、快速输入、异常序列
- 浸泡测试：长时间运行该功能，检查是否出现性能退化
- 压力测试：最大实体数量、最坏情况场景
- 回归测试：验证打磨变更没有破坏现有功能——逐一按名称核对阶段 2–4 的每项变更，包括引擎层面修复
- 在最低规格硬件上测试（若有）
- 产出：带有任何遗留问题的测试结果

### Phase 6: Sign-off
### 阶段 6：签核
- Collect results from all team members
- Compare performance metrics against budgets
- Report: READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK
- List every remaining issue with its severity (S1–S4), the measured gap where there is one (e.g. "9 ms against a 6 ms budget — 3 ms over"), and a recommendation; a regression also names the broken behavior and the polish change that caused it
- 收集所有团队成员的结果
- 将性能指标与预算进行对比
- 报告：READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK
- 列出每个遗留问题及其严重程度（S1–S4）、有实测差距时给出该差距（例如“相对 6 ms 预算为 9 ms——超出 3 ms”），以及一条建议；回归问题还要点名被破坏的行为以及导致它的那次打磨变更

**NOT ASSESSED ranks above READY FOR RELEASE and below NEEDS MORE WORK.** A known
problem — a metric over budget, an unresolved regression — makes it NEEDS MORE
WORK whatever else went unchecked. Otherwise, if any part of the scope could not
be checked, the result is NOT ASSESSED, never READY FOR RELEASE, and the report
names each gap:
**NOT ASSESSED 的等级高于 READY FOR RELEASE、低于 NEEDS MORE WORK。** 一个已知问题——超预算的指标、未解决的回归——就会使其成为 NEEDS MORE WORK，无论其他还有什么未检查。除此之外，如果范围的任何一部分无法检查，结果就是 NOT ASSESSED，绝不是 READY FOR RELEASE，且报告会点名每个缺口：
- A metric with no committed budget. `performance.target_framerate`,
  `performance.frame_budget_ms`, `performance.draw_call_limit` and
  `performance.memory_ceiling_mb` have no default, and `/perf-profile` reports an
  unset one as NOT ASSESSED — nothing was compared, so no budget was met.
- A phase that did not run: BLOCKED, skipped, or its agent outside the active set.
  At `team.size: individual`, sound-designer's audio polish and qa-tester's
  hardening are only consulted through the active agents, not run, and Phase 2's
  programmer items are handed to `/dev-story` rather than implemented.
- 没有已提交预算的指标。`performance.target_framerate`、`performance.frame_budget_ms`、`performance.draw_call_limit` 和 `performance.memory_ceiling_mb` 没有默认值，而 `/perf-profile` 会将未设置的一项上报为 NOT ASSESSED——没有做任何比较，因此没有满足任何预算。
- 未运行的阶段：BLOCKED、被跳过，或其智能体在活动集之外。在 `team.size: individual` 下，sound-designer 的音频打磨与 qa-tester 的加固仅经由活动智能体咨询，并不运行，而阶段 2 的程序员事项移交至 `/dev-story` 而非实现。

## Error Recovery Protocol
## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.
**首先，验证产物。** 如果返回契约点名了某个路径，在视该阶段为完成之前先检查该路径是否存在——**一个被命名却不在磁盘上的产物就是失败的阶段，无论回复读起来多么流畅。** 智能体可能烧掉整整一个阶段，什么也没写，却返回一段可信的开场白；这既不是 BLOCKED，也不是错误，也不是“无法完成”，因此下方的触发条件永远不会激发。带着未满足的契约恢复它；上下文通常仍在。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.
如果任何被启动的智能体返回 BLOCKED、报错或无法完成：**立即将它浮出水面，不要越过它所阻塞的依赖继续推进，并始终产出一份部分报告。** 被跳过智能体的章节仍是一个点名的缺口——绝不要用你自己的内容填充它。完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
常见阻塞：
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- 输入文件缺失（找不到故事、GDD 不存在）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦它被决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆分为两个故事
- ADR 与故事之间的指令冲突 → 把冲突浮出水面，不要猜测

## File Write Protocol
## 文件写入协议

All file writes (performance reports, test results, evidence docs) are delegated to
sub-agents spawned via `Agent`. Those writes follow the **bounded exception**
documented above under "Why this does not violate the Collaboration Protocol" —
the path is one you named, the artifact is new under `production/`, `docs/` or
`tests/`, and the phase is gated by an `AskUserQuestion`. A sub-agent does **not**
prompt per write inside those bounds; outside them it must ask. The optimization
and polish changes of Phases 2–4 edit existing code, shaders, audio or assets, so
they are outside those bounds: each implementing agent returns the files it will
create or change, you ask once for the whole Phase 2–4 set ("May I have [agents]
change these [N] files?"), and each edits only after a yes — one ask for the set,
not one per phase. This orchestrator does not write files directly.
所有文件写入（性能报告、测试结果、证据文档）都委派给通过 `Agent` 启动的子智能体。这些写入遵循上文“为何这不违反协作协议”中记录的有界例外——路径是你命名的、产物是 `production/`、`docs/` 或 `tests/` 下的新文件、且该阶段已由 `AskUserQuestion` 把关。子智能体在这些边界内**不**逐次写入提示；在边界之外则必须询问。阶段 2–4 的优化与打磨变更会编辑现有代码、着色器、音频或资产，因此位于这些边界之外：每个实施智能体返回它将创建或更改的文件，你就整个阶段 2–4 集合询问一次（“我可以让 [agents] 更改这 [N] 个文件吗？”），每个智能体仅在得到肯定答复后才编辑——对整个集合只问一次，而非每个阶段一次。本编排器不直接写文件。

## Output
## 输出

A summary report covering: performance before/after metrics, visual polish changes, audio polish changes, test results, any optimisation list handed to `/dev-story`, and release readiness assessment.
一份摘要报告，涵盖：性能前后对比指标、视觉打磨变更、音频打磨变更、测试结果、任何移交至 `/dev-story` 的优化清单，以及发布就绪评估。

## Next Steps
## 后续步骤

- If READY FOR RELEASE: run `/release-checklist` for the final pre-release validation.
- If NEEDS MORE WORK: schedule remaining issues in `/sprint-plan update` (at `workflow: minimal`, which has no sprints, add them to the brief's build order) and re-run `/team-polish` after fixes.
- If NOT ASSESSED: supply what was missing — commit the unset `performance.*` budgets in `project.yaml` (`/settings`), or run the phases that did not run (raise `team.size`) — then re-run `/team-polish`. Do not treat the area as release-ready.
- If the report handed an optimisation list to `/dev-story`: implement those items there, then re-run `/team-polish` to measure the gain.
- Run `/gate-check` for a formal phase gate verdict before handing off to release.
- 若为 READY FOR RELEASE：运行 `/release-checklist` 进行最终的发布前验证。
- 若为 NEEDS MORE WORK：在 `/sprint-plan update` 中安排遗留问题（在 `workflow: minimal` 下没有冲刺，可将它们加入简报的构建顺序），并在修复后重新运行 `/team-polish`。
- 若为 NOT ASSESSED：补齐缺失的东西——在 `project.yaml` 中提交未设置的 `performance.*` 预算（`/settings`），或运行那些未运行的阶段（提高 `team.size`）——然后重新运行 `/team-polish`。不要将该区域视为发布就绪。
- 若报告将优化清单移交给了 `/dev-story`：在那里实现这些事项，然后重新运行 `/team-polish` 以测量收益。
- 在移交至发布之前，运行 `/gate-check` 以取得正式的阶段门禁判定。
