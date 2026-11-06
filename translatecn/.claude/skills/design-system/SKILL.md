---
name: design-system
description: "Section-by-section GDD authoring for one system — walks through each required section, cross-references dependencies."
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/design-system/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---
---
name: design-system
description: "针对单个系统的逐节 GDD 编写 — 走查每个必需节，并交叉引用依赖。"
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/design-system/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/registry.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 会覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Design System
# 设计系统

When this skill is invoked:
当此技能被调用时：

## 1. Parse Arguments & Validate
## 1. 解析参数并验证

**Read `references/1-parse-arguments.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/1-parse-arguments.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 2. Gather Context (Read Phase)
## 2. 收集上下文（读取阶段）

**Read `references/2-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/2-gather-context.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 3. Create File Skeleton
## 3. 创建文件骨架

**Read `references/3-file-skeleton.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/3-file-skeleton.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 4. Section-by-Section Design
## 4. 逐节设计

**Read `references/4-section-design.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/4-section-design.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 5. Post-Design Validation
## 5. 设计后验证

**Read `references/5-post-design.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/5-post-design.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 6. Specialist Agent Routing
## 6. 专家智能体路由

This skill delegates to specialist agents for domain expertise. The main session
orchestrates the overall flow; agents provide expert content.
此技能将领域专业知识委托给专家智能体。主会话负责编排整体流程；智能体提供专家内容。

**Rows here are finer-grained than the nine `Category` values on purpose** — the
right specialist for combat is not the right specialist for pathfinding, and both
are `Gameplay`. Resolve in two steps: take the system's `Category` from
`systems-index.md`, then pick the row within it that matches what the system
actually does. Every category has at least one row, so nothing falls through.
**此处的行比九个 `Category` 值更细粒度，这是有意为之** — 适合战斗的专家并不适合寻路，而两者都属于 `Gameplay`。分两步解析：从 `systems-index.md` 取出系统的 `Category`，然后在该类别内选择与系统实际行为匹配的行。每个类别至少有一行，因此不会有遗漏。

| `Category` | Rows below to choose from |
|---|---|
| `Gameplay` | Combat/damage/health · AI/pathfinding/behavior · Animation/character movement · Character systems · Camera/input/controls |
| `Core` | Foundation/Infrastructure · Camera/input/controls |
| `Persistence` | Foundation/Infrastructure |
| `Economy` | Economy/loot/crafting |
| `Progression` | Progression/XP/skills |
| `UI` | UI systems · Visual effects (when the system is HUD-adjacent VFX) |
| `Audio` | Audio systems |
| `Narrative` | Dialogue/quests/lore |
| `Meta` | Foundation/Infrastructure (analytics, tutorial plumbing) · UI systems (accessibility options screens) |
| `Category` | 可从以下各行中选择 |
|---|---|
| `Gameplay` | 战斗/伤害/生命值 · AI/寻路/行为 · 动画/角色移动 · 角色系统 · 摄像机/输入/控制 |
| `Core` | 基础/基础设施 · 摄像机/输入/控制 |
| `Persistence` | 基础/基础设施 |
| `Economy` | 经济/掉落/制作 |
| `Progression` | 成长/经验值/技能 |
| `UI` | UI 系统 · 视觉效果（当该系统是 HUD 邻近的 VFX 时） |
| `Audio` | 音频系统 |
| `Narrative` | 对话/任务/世界观 |
| `Meta` | 基础/基础设施（分析、教程管线） · UI 系统（无障碍选项界面） |

If two rows fit, spawn the union of their Primary agents and say why.
如果两行都适用，则启动它们主责智能体的并集，并说明理由。

| System type | Primary Agent | Supporting Agent(s) |
|----------------|---------------|---------------------|
| **Foundation/Infrastructure** (event bus, save/load, scene mgmt, service locator) | `systems-designer` | `gameplay-programmer` (feasibility), `engine-programmer` (engine integration) |
| Combat, damage, health | `game-designer` | `systems-designer` (formulas), `ai-programmer` (enemy AI), `art-director` (hit feedback visual direction, VFX intent) |
| Economy, loot, crafting | `economy-designer` | `systems-designer` (curves), `game-designer` (loops) |
| Progression, XP, skills | `game-designer` | `systems-designer` (curves), `economy-designer` (sinks) |
| Dialogue, quests, lore | `game-designer` | `narrative-director` (story), `writer` (content), `art-director` (character visual profiles, cinematic tone) |
| UI systems (HUD, menus) | `game-designer` | `ux-designer` (flows), `ui-programmer` (feasibility), `art-director` (visual style direction), `technical-artist` (render/shader constraints) |
| Audio systems | `game-designer` | `audio-director` (direction), `sound-designer` (specs) |
| AI, pathfinding, behavior | `game-designer` | `ai-programmer` (implementation), `systems-designer` (scoring) |
| Level/world systems | `game-designer` | `level-designer` (spatial), `world-builder` (lore) |
| Camera, input, controls | `game-designer` | `ux-designer` (feel), `gameplay-programmer` (feasibility) |
| Animation, character movement | `game-designer` | `art-director` (animation style, pose language), `technical-artist` (rig/blend constraints), `gameplay-programmer` (feel) |
| Visual effects, particles, shaders | `game-designer` | `art-director` (VFX visual direction), `technical-artist` (performance budget, shader complexity), `systems-designer` (trigger/state integration) |
| Character systems (stats, archetypes) | `game-designer` | `art-director` (character visual archetype), `narrative-director` (character arc alignment), `systems-designer` (stat formulas) |
| 系统类型 | 主责智能体 | 支持智能体 |
|----------------|---------------|---------------------|
| **基础/基础设施**（事件总线、存档/读档、场景管理、服务定位器） | `systems-designer` | `gameplay-programmer`（可行性），`engine-programmer`（引擎集成） |
| 战斗、伤害、生命值 | `game-designer` | `systems-designer`（公式），`ai-programmer`（敌人 AI），`art-director`（受击反馈视觉方向、VFX 意图） |
| 经济、掉落、制作 | `economy-designer` | `systems-designer`（曲线），`game-designer`（循环） |
| 成长、经验值、技能 | `game-designer` | `systems-designer`（曲线），`economy-designer`（消耗） |
| 对话、任务、世界观 | `game-designer` | `narrative-director`（故事），`writer`（内容），`art-director`（角色视觉档案、过场基调） |
| UI 系统（HUD、菜单） | `game-designer` | `ux-designer`（流程），`ui-programmer`（可行性），`art-director`（视觉风格方向），`technical-artist`（渲染/着色器约束） |
| 音频系统 | `game-designer` | `audio-director`（方向），`sound-designer`（规格） |
| AI、寻路、行为 | `game-designer` | `ai-programmer`（实现），`systems-designer`（评分） |
| 关卡/世界系统 | `game-designer` | `level-designer`（空间），`world-builder`（世界观） |
| 摄像机、输入、控制 | `game-designer` | `ux-designer`（手感），`gameplay-programmer`（可行性） |
| 动画、角色移动 | `game-designer` | `art-director`（动画风格、姿态语言），`technical-artist`（骨骼/混合约束），`gameplay-programmer`（手感） |
| 视觉效果、粒子、着色器 | `game-designer` | `art-director`（VFX 视觉方向），`technical-artist`（性能预算、着色器复杂度），`systems-designer`（触发器/状态集成） |
| 角色系统（属性、原型） | `game-designer` | `art-director`（角色视觉原型），`narrative-director`（角色弧线一致性），`systems-designer`（属性公式） |

**When delegating via the `Agent` tool**:
**通过 `Agent` 工具委托时**：
- Provide: system name, game concept summary, dependency GDD excerpts, the specific
  section being worked on, and what question needs expert input
- The agent returns analysis/proposals to the main session
- The main session presents the agent's output to the user via `AskUserQuestion`
- The user decides; the main session writes to file
- Agents do NOT write to files directly — the main session owns all file writes
- 提供：系统名、游戏概念摘要、依赖 GDD 摘录、当前正在处理的具体节，以及需要专家输入的问题
- 智能体将分析/提案返回给主会话
- 主会话通过 `AskUserQuestion` 向用户呈现智能体的输出
- 由用户做决定；主会话写入文件
- 智能体**不**直接写入文件 — 主会话拥有所有文件写入权

---

## 7. Recovery & Resume
## 7. 恢复与续跑

If the session is interrupted (compaction, crash, new session):
如果会话被中断（压缩、崩溃、新会话）：

1. Read `production/session-state/active.md` — it records the current system and
   which sections are complete
2. Read `design/gdd/[system-name].md` — sections with real content are done;
   sections with `[To be designed]` still need work. Read it by section: find the
   headings with the Grep tool (pattern `^#`, content mode) and Read those
   ranges with offset and limit.
3. Resume from the next incomplete section — no need to re-discuss completed ones
1. 读取 `production/session-state/active.md` — 它记录当前系统以及哪些节已完成
2. 读取 `design/gdd/[system-name].md` — 有实际内容的节视为已完成；
   含 `[To be designed]` 的节仍需处理。按节读取：用 Grep 工具（模式 `^#`，content 模式）
   找到各标题，再用 offset 和 limit 读取相应区间。
3. 从下一个未完成的节继续 — 无需重新讨论已完成的节

This is why incremental writing matters: every approved section survives any
disruption.
这正是增量写入的意义所在：每个已批准的节都能在任何中断中幸存。

---

## Collaborative Protocol
## 协作协议

**In `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see the per-mode rules in `.claude/docs/automation-modes.md` — the
"Never" lines below describe what collaborative mode requires, not what
applies universally.
**处于 `collaborative` 模式（默认）。** 对于 `guided` 和 `autonomous`
模式，请参阅 `.claude/docs/automation-modes.md` 中各模式的规则 — 下文的
"Never" 各行描述的是协作模式的要求，而非普遍适用的规则。

This skill follows the collaborative design principle at every step:
此技能在每一步都遵循协作设计原则：

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): Design questions, approach options, draft approval
   - Phase 5: "May I update the entity registry? May I update the systems
     index? What's next?" — **not** "Run design review?": §5c forbids offering
     `/design-review` inline, because the reviewing agent must not inherit this
     session's design history. Phase 5c presents the hand-off; it never asks.
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write
6. **Cross-referencing**: Every section checks existing GDDs for conflicts
7. **Specialist routing**: Complex sections get expert agent input, presented to
   the user for decision — never written silently
1. 每一节都遵循**提问 -> 选项 -> 决策 -> 草稿 -> 批准**
2. 在每个决策点使用 **AskUserQuestion**（解释 -> 记录模式）：
   - 阶段 2："可以开始了吗，还是需要更多上下文？"
   - 阶段 3："我可以创建骨架吗？"
   - 阶段 4（每一节）：设计问题、方案选项、草稿批准
   - 阶段 5："我可以更新实体注册表吗？我可以更新系统
     索引吗？下一步是什么？" — **而不是**"要运行设计评审吗？"：§5c 禁止内联提供
     `/design-review`，因为评审智能体不得继承本会话的设计历史。阶段 5c 呈现的是交接；它从不提问。
3. 在创建骨架之前以及每次写入某节之前，都要问 **"我可以写入 [filepath] 吗？"**
4. **增量写入**：每一节在获批后立即写入文件
5. **会话状态更新**：每次写入某节之后
6. **交叉引用**：每一节都检查现有 GDD 是否存在冲突
7. **专家路由**：复杂节获取专家智能体输入，并呈现给用户决策 — 绝不静默写入

**Never** auto-generate the full GDD and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved GDD without flagging the conflict.
**Always** show where decisions come from (dependency GDDs, pillars, user choices).
**绝不**自动生成完整 GDD 并把它作为既成事实呈现。
**绝不**在未经用户批准的情况下写入某一节。
**绝不**在未标记冲突的情况下与已批准的现有 GDD 相矛盾。
**始终**说明决策的来源（依赖 GDD、支柱、用户选择）。

## Context Window Awareness
## 上下文窗口感知

This is a long-running skill. After writing each section, check if the status line
shows context at or above 70%. If so, append this notice to the response:
这是一个长时间运行的技能。每写完一节后，检查状态栏显示的上下文是否达到或超过 70%。如果是，请在响应末尾追加此提示：

> **Context is approaching the limit (≥70%).** Your progress is saved — all approved
> sections are written to `design/gdd/[system-name].md`. When you're ready to continue,
> open a fresh Claude Code session and run `/design-system [system-name]` — it will
> detect which sections are complete and resume from the next one.
> **上下文即将达到上限（≥70%）。** 您的进度已保存 — 所有已批准的
> 节都已写入 `design/gdd/[system-name].md`。当您准备继续时，
> 请打开新的 Claude Code 会话并运行 `/design-system [system-name]` — 它会
> 检测哪些节已完成，并从下一节继续。

---

## Recommended Next Steps
## 建议的后续步骤

- Run `/design-review design/gdd/[system-name].md` in a **fresh session** to validate the completed GDD independently
- Run `/consistency-check` to verify this GDD's values don't conflict with other GDDs
- Run `/map-systems next` to move to the next highest-priority undesigned system
- Run `/gate-check technical-setup` when all MVP GDDs are authored and reviewed
- 在**新会话**中运行 `/design-review design/gdd/[system-name].md`，以独立验证已完成的 GDD
- 运行 `/consistency-check`，以确认此 GDD 的数值与其他 GDD 不冲突
- 运行 `/map-systems next`，转移到下一个优先级最高的未设计系统
- 当所有 MVP GDD 都已编写并评审后，运行 `/gate-check technical-setup`
