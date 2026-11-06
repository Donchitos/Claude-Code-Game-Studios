---
name: ux-design
description: "Section-by-section UX spec authoring for a screen, flow or HUD. Reads the player journey to provide context; also project-wide accessibility."
argument-hint: "[screen/flow name] or 'hud' or 'patterns' or 'accessibility'"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: ux-design
description: "为某个界面、流程或 HUD 逐小节撰写 UX 规格。读取玩家旅程以提供上下文；也覆盖全项目无障碍。"
argument-hint: "[screen/flow name] or 'hud' or 'patterns' or 'accessibility'"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,docs.density`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.
以上已解析——按原样使用。没有配置块 → 使用
`.claude/docs/config-resolution.md` 中的默认值。

# UX Design
# UX 设计

When this skill is invoked:
当此技能被调用时：

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅重大项 · 自主模式记录并继续；
`automation_always_ask` 类别总是提示）。

**Authoring guidance**: the skeletons below are self-contained — author from them
directly. When a section needs depth (worked examples, pattern catalogs,
accessibility criteria), the matching guide has it:
**撰写指导**：下方的骨架是自包含的——直接依据它们撰写。当某个小节需要深度（完整示例、模式目录、
无障碍准则）时，对应的指南提供了这些内容：

| Producing | Guide |
|---|---|
| UX spec | `.claude/docs/templates/guidance/ux-spec-guide.md` |
| HUD design | `.claude/docs/templates/guidance/hud-design-guide.md` |
| Interaction patterns | `.claude/docs/templates/guidance/interaction-pattern-library-guide.md` (routes to three topic files) |
| Accessibility requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

| 产出 | 指南 |
|---|---|
| UX 规格 | `.claude/docs/templates/guidance/ux-spec-guide.md` |
| HUD 设计 | `.claude/docs/templates/guidance/hud-design-guide.md` |
| 交互模式 | `.claude/docs/templates/guidance/interaction-pattern-library-guide.md`（路由到三个主题文件） |
| 无障碍需求 | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

**Load a guide per-section, never whole** — each is organised by section and the
pointers in the templates name the exact section to read.
**按小节加载指南，绝不整份加载**——每份都按小节组织，模板中的
指针会点名需要读取的确切小节。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — a UX spec is required per screen.
- `standard` — core screens only (main menu, HUD, primary game loop).
- `minimal` — not required. Can still be run voluntarily.
**`workflow`**（见 `.claude/docs/workflow-modes.md`）：
- `full` — 每个界面都需要一份 UX 规格。
- `standard` — 仅核心界面（主菜单、HUD、主要游戏循环）。
- `minimal` — 非必需。仍可自愿运行。

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which screens are specced. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = wireframe descriptions +
interaction bullets; `balanced` = wireframes + paragraph descriptions of flows
(`rigor: standard`); `thorough` = full prose including user-research summaries and
alternative flow considerations. Apply it to every section you author.
**`docs.density`**——它控制每个小节的*深度*，而 `workflow`
控制哪些界面被撰写规格。`modes.rigor` 会同时设置两者；显式设置
`docs.density` 可单独改变深度：`terse`（默认，经由 `rigor: minimal`）= 线框图描述 +
交互项目符号；`balanced` = 线框图 + 流程的段落化描述
（`rigor: standard`）；`thorough` = 完整正文，包括用户研究摘要和
替代流程考量。将其应用于你撰写的每个小节。

## 1. Parse Arguments & Determine Mode
## 1. 解析参数并确定模式

Four authoring modes exist based on the argument:
根据参数共存在四种撰写模式：

| Argument | Mode | Output file |
|----------|------|-------------|
| `hud` | HUD design | `design/ux/hud.md` |
| `patterns` | Interaction pattern library | `design/ux/interaction-patterns.md` |
| `accessibility` | Project-wide accessibility requirements | `design/accessibility-requirements.md` |
| Any other value (e.g., `main-menu`, `inventory`) | UX spec for a screen or flow | `design/ux/[argument].md` |
| No argument | Ask the user | (see below) |

| 参数 | 模式 | 输出文件 |
|----------|------|-------------|
| `hud` | HUD 设计 | `design/ux/hud.md` |
| `patterns` | 交互模式库 | `design/ux/interaction-patterns.md` |
| `accessibility` | 全项目无障碍需求 | `design/accessibility-requirements.md` |
| 任何其他值（例如 `main-menu`、`inventory`） | 某个界面或流程的 UX 规格 | `design/ux/[argument].md` |
| 无参数 | 询问用户 | （见下文） |

> **`accessibility` is the only mode that writes outside `design/ux/`.** Its
> output is a project-wide standard the per-screen specs consult, not a spec for
> one screen — `.claude/docs/workflow-catalog.yaml`, the Pre-Production and
> Polish gates, and `/architecture-review` all check
> `design/accessibility-requirements.md` at that exact path. Do not "tidy" it
> under `design/ux/`: every one of those checks would stop matching, and the
> Technical Setup → Pre-Production gate would become unpassable.
> **`accessibility` 是唯一会写入 `design/ux/` 之外的模式。** 它的
> 输出是全项目标准，供各界面规格参考，而不是某个单一界面的规格——
> `.claude/docs/workflow-catalog.yaml`、前期制作和
> 打磨门禁，以及 `/architecture-review` 都会在该确切路径检查
> `design/accessibility-requirements.md`。不要把它"整理"到
> `design/ux/` 下：那些检查每一个都会停止匹配，而
> 技术设置 → 前期制作门禁将变得无法通过。

**If no argument is provided**, do not fail — ask instead. Use `AskUserQuestion`:
- "What are we designing today?"
  - Options: "A specific screen or flow (I'll name it)", "The game HUD", "The interaction pattern library", "The project-wide accessibility requirements", "I'm not sure — help me figure it out"
**如果未提供参数**，不要失败——改为询问。使用 `AskUserQuestion`：
- "What are we designing today?"
  - 选项："A specific screen or flow (I'll name it)"、"The game HUD"、"The interaction pattern library"、"The project-wide accessibility requirements"、"I'm not sure — help me figure it out"

If the user selects "I'll name it" or types a screen name, normalize it to kebab-case
for the filename (e.g., "Main Menu" becomes `main-menu`).
如果用户选择 "I'll name it" 或输入一个界面名称，将其规范化为 kebab-case
用作文件名（例如 "Main Menu" 变为 `main-menu`）。

---

## 2. Gather Context (Read Phase)
## 2. 收集上下文（读取阶段）

**Read `references/2-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/2-gather-context.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 3. Create File Skeleton
## 3. 创建文件骨架

**Read `references/3-file-skeleton.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/3-file-skeleton.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 4. Section-by-Section Authoring
## 4. 逐小节撰写

**Read `references/4-authoring.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/4-authoring.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

### Section guidance — read the ONE file for the active mode
### 小节指南——只读取当前模式对应的那一个文件

Per-section authoring guidance lives in its own file per mode. **When you reach
Phase 4, read only the file matching the mode resolved in Section 1; never load
the other two.**
逐小节的撰写指南按模式各自存于独立文件中。**当你进入
阶段 4 时，只读取与第 1 节中解析出的模式相匹配的那个文件；绝不加载
另外两个。**

| Mode | Guidance file |
|------|---------------|
| UX Spec (screen or flow) | `references/sections-ux-spec.md` |
| HUD Design | `references/sections-hud.md` |
| Interaction Pattern Library | `references/sections-patterns.md` |
| Accessibility Requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

| 模式 | 指南文件 |
|------|---------------|
| UX 规格（界面或流程） | `references/sections-ux-spec.md` |
| HUD 设计 | `references/sections-hud.md` |
| 交互模式库 | `references/sections-patterns.md` |
| 无障碍需求 | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

> The accessibility guidance lives under `templates/guidance/` rather than this
> skill's `references/` because the template it documents
> (`.claude/docs/templates/accessibility-requirements.md`) is consumed by
> `/ux-review` and the gate files too. Same rule applies: load only the part
> covering the section you are authoring, never the whole file.
> 无障碍指南位于 `templates/guidance/` 下而非本
> 技能的 `references/` 中，因为它所记录的模板
> （`.claude/docs/templates/accessibility-requirements.md`）也被
> `/ux-review` 和门禁文件使用。同样的规则适用：只加载
> 覆盖你正在撰写的小节的那部分，绝不加载整个文件。

Apply `docs.density` (Section 1) to whatever that file tells you to author — it
controls the depth of each section, not which sections exist.
将 `docs.density`（第 1 节）应用于该文件告诉你要撰写的任何内容——它
控制每个小节的深度，而不是存在哪些小节。

## 5. Cross-Reference Check
## 5. 交叉引用检查

**Read `references/5-crossref-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/5-crossref-handoff.md` 并遵循它**——本阶段的步骤在该文件中，不在此处。如果对话在本阶段被压缩或恢复，请重新读取它。

## 7. Recovery & Resume
## 7. 恢复与续做

If the session is interrupted (compaction, crash, new session):
如果会话被中断（压缩、崩溃、新会话）：

1. Read `production/session-state/active.md` — it records the current screen
   and which sections are complete.
2. Read `design/ux/[filename].md` — sections with real content are done;
   sections with `[To be designed]` still need work.
3. Resume from the next incomplete section — no need to re-discuss completed ones.
1. 读取 `production/session-state/active.md`——它记录了当前界面
   以及哪些小节已完成。
2. 读取 `design/ux/[filename].md`——有真实内容的小节已完成；
   含有 `[To be designed]` 的小节仍需处理。
3. 从下一个未完成的小节继续——无需重新讨论已完成的小节。

This is why incremental writing matters: every approved section survives any
disruption.
这就是增量写入重要的原因：每个已批准的小节都能在任何
中断中留存。

---

## 8. Specialist Agent Routing
## 8. 专家智能体路由

This skill uses `ux-designer` as the primary agent (set in frontmatter). For
specific sub-topics, additional context or coordination may be needed:
此技能使用 `ux-designer` 作为主智能体（在 frontmatter 中设置）。对于
特定子主题，可能需要额外的上下文或协调：

| Topic | Coordinate with |
|-------|----------------|
| Visual aesthetics, color, layout feel | `art-director` — UX spec defines zones; art defines how they look |
| Implementation feasibility (engine constraints) | `ui-programmer` — before finalizing component inventory |
| Gameplay data requirements | `game-designer` — when data ownership is unclear |
| Narrative/lore visible in the UI | `narrative-director` — for flavor text, item names, lore panels |
| Accessibility tier decisions | Recorded by this session (`/ux-design accessibility`; the user picks the tier) against the criteria `accessibility-specialist` defines and audits — consult it when a requirement's criterion is unclear |

| 主题 | 与之协调 |
|-------|----------------|
| 视觉美学、色彩、布局感觉 | `art-director`——UX 规格定义区域；美术定义它们的外观 |
| 实现可行性（引擎约束） | `ui-programmer`——在最终确定组件清单之前 |
| 玩法数据需求 | `game-designer`——当数据归属不明确时 |
| UI 中可见的叙事/世界观 | `narrative-director`——用于风味文本、物品名称、世界观面板 |
| 无障碍层级决策 | 由本会话记录（`/ux-design accessibility`；由用户选择层级），依据 `accessibility-specialist` 定义并审计的准则——当某项需求的准则不明确时咨询它 |

When delegating to another agent via the `Agent` tool:
- Provide: screen name, game concept summary, the specific question needing expert input
- The agent returns analysis to this session
- This session presents the agent's output to the user
- The user decides; this session writes to file
- Agents do NOT write to files directly — this session owns all file writes
通过 `Agent` 工具委派给另一个智能体时：
- 提供：界面名称、游戏概念摘要、需要专家输入的特定问题
- 智能体将分析返回给本会话
- 本会话将智能体的输出呈现给用户
- 用户决定；本会话写入文件
- 智能体**不**直接写入文件——本会话拥有所有文件写入

---

## Collaborative Protocol
## 协作协议

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see the per-mode rules in `.claude/docs/automation-modes.md` — the steps below
describe what collaborative mode requires, not what applies universally.
**在 `collaborative` 模式下（默认）。** 对于 `guided` 和 `autonomous` 模式，
参见 `.claude/docs/automation-modes.md` 中的各模式规则——下方步骤
描述的是协作模式的要求，而非普遍适用的内容。

This skill follows the collaborative design principle at every step:
此技能在每一步都遵循协作设计原则：

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): design questions, approach options, draft approval
   - Phase 5: "Run cross-reference check? What's next?"
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write
1. 每个小节都遵循 **问题 -> 选项 -> 决策 -> 草稿 -> 批准**
2. 在每个决策点使用 **AskUserQuestion**（说明 -> 捕获模式）：
   - 阶段 2："Ready to start, or need more context?"
   - 阶段 3："May I create the skeleton?"
   - 阶段 4（每个小节）：设计问题、方案选项、草稿批准
   - 阶段 5："Run cross-reference check? What's next?"
3. 在骨架之前以及每次小节写入之前询问 **"May I write to [filepath]?"**
4. **增量写入**：每个小节在批准后立即写入文件
5. **会话状态更新**：每次小节写入之后

**Aesthetic deference**: When layout or visual choices come down to personal taste,
present the options and ask. Do not select a layout because it is "standard" — always
confirm. The user is the creative director.
**美学尊重**：当布局或视觉选择取决于个人品味时，
呈现选项并询问。不要因为某个布局"标准"就选择它——始终
确认。用户是创意总监。

**Conflict surfacing**: When a GDD requirement and the available screen real estate
conflict, surface the conflict and present resolution options. Never silently drop
a requirement. Never silently expand the layout without flagging it.
**冲突呈现**：当 GDD 需求与可用屏幕空间
冲突时，呈现该冲突并提供解决方案选项。绝不静默丢弃
一项需求。绝不静默扩展布局而不标记它。

**Never** auto-generate the full spec and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved UX spec without flagging the conflict.
**Always** show where decisions come from (GDD requirements, player journey, user choices).
**绝不**自动生成完整规格并把它当作既成事实呈现。
**绝不**在未经用户批准的情况下写入某个小节。
**绝不**在未标记冲突的情况下与现有已批准的 UX 规格相矛盾。
**始终**展示决策的来源（GDD 需求、玩家旅程、用户选择）。

Verdict: **COMPLETE** — UX spec written and approved section by section.
判定：**COMPLETE**——UX 规格已逐小节撰写并获得批准。

---

## Recommended Next Steps
## 推荐的后续步骤

- Run `/ux-review [filename]` to validate this spec before it enters the implementation pipeline
- Run `/ux-design [next-screen]` to continue designing remaining screens or flows
- Run `/gate-check production` once all key screens have approved UX specs
- 运行 `/ux-review [filename]`，在此规格进入实现管线之前进行校验
- 运行 `/ux-design [next-screen]`，继续设计剩余界面或流程
- 一旦所有关键界面都已有获批的 UX 规格，运行 `/gate-check production`
