# ux-design — UX 规格撰写（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/ux-design/SKILL.md) ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/ux-design [screen/flow name] 或 'hud' 或 'patterns' 或 'accessibility'`
- **一句话职责**：按"逐节撰写"方式为一个屏幕、流程、HUD、交互模式库或全项目无障碍需求产出 UX 规格文档，读取玩家旅程（player journey）作为上下文。
- **触发前置**：无硬性前置（`workflow: minimal` 下不要求但可自愿运行）；主智能体为 `ux-designer`（frontmatter 设定，model: sonnet）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `automation`、`workflow`、`docs.density`（经 `hooks/yaml-helper.sh resolve_config` 解析；无输出块则用 `.claude/docs/config-resolution.md` 默认值） | 决定提问节奏、哪些屏幕需要规格、每节深度 |
| 读取 | 玩家旅程（player journey）、GDD、既有 UX 规格（Phase 2 上下文收集，见 `references/2-gather-context.md`） | 提供设计上下文与决策来源 |
| 读取 | `production/session-state/active.md` | 中断恢复时定位当前屏幕与已完成小节 |
| 读取 | 指南（按需、按节加载）：`ux-spec-guide.md`、`hud-design-guide.md`、`interaction-pattern-library-guide.md`、`accessibility-requirements-guide.md`（均在 `.claude/docs/templates/guidance/`） | 各模式的小节级撰写指导 |
| 产出 | `design/ux/hud.md`（HUD 模式）；`design/ux/interaction-patterns.md`（patterns 模式）；`design/accessibility-requirements.md`（accessibility 模式）；`design/ux/[argument].md`（屏幕/流程规格，文件名 kebab-case） | 逐节增量写入，每节经用户批准后立即落盘 |
| 派生智能体 | `art-director`（视觉/色彩/布局风格）、`ui-programmer`（引擎实现可行性，定稿组件清单前）、`game-designer`（数据归属不明时）、`narrative-director`（UI 中的叙事文本）、`accessibility-specialist`（无障碍标准界定与审计；等级由用户选定、本会话记录） | 智能体只返回分析，不直接写文件；主会话拥有全部文件写入 |

**配置键档位**：
- `workflow`：`full` = 每个屏幕都要 UX 规格；`standard` = 仅核心屏幕（主菜单、HUD、主游戏循环）；`minimal` = 不要求（可自愿运行）。
- `docs.density`（控制每节"深度"，`workflow` 控制"哪些屏幕写规格"；`modes.rigor` 同时设定两者，单独显式设 `docs.density` 可只调深度）：`terse`（默认，经 `rigor: minimal`）= 线框描述 + 交互要点条目；`balanced` = 线框 + 流程段落描述（`rigor: standard`）；`thorough` = 完整散文体，含用户研究摘要与备选流程考量。应用于所撰写的每一节。

## 3. 核心规则（逐条编号 R1、R2……）

**模式与参数解析（Section 1）**
R1. 必须按参数判定四种模式之一并写出对应文件：`hud` → `design/ux/hud.md`；`patterns` → `design/ux/interaction-patterns.md`；`accessibility` → `design/accessibility-requirements.md`；其它任意值（如 `main-menu`、`inventory`）→ `design/ux/[argument].md`。（出处：Section 1）
R2. `accessibility` 是唯一允许写到 `design/ux/` 之外的模式；禁止把 `design/accessibility-requirements.md` "整理"进 `design/ux/`——workflow-catalog、Pre-Production 与 Polish 门禁及 `/architecture-review` 都按该精确路径检查，移动后这些检查将全部失配，Technical Setup → Pre-Production 门禁将无法通过。（出处：Section 1）
R3. 无参数时禁止直接失败，必须用 `AskUserQuestion` 询问"今天要设计什么？"，选项含：指定屏幕/流程（由用户命名）、游戏 HUD、交互模式库、全项目无障碍需求、"不确定——帮我理清"。（出处：Section 1）
R4. 用户命名屏幕时必须把名称规范化为 kebab-case 作文件名（如 "Main Menu" → `main-menu`）。（出处：Section 1）

**阶段执行（Sections 2–5）**
R5. Phase 2（收集上下文）、Phase 3（创建文件骨架）、Phase 4（逐节撰写）、Phase 5（交叉引用检查）的步骤在各自的 `references/*.md` 文件中；进入该阶段时必须立即读取对应文件并遵循之，不得凭主文件行事。会话被压缩（compaction）或恢复后处于该阶段时必须重新读取。（出处：Sections 2–5）
R6. 进入 Phase 4 后必须只读取与 Section 1 判定模式匹配的那一份小节指导文件，禁止加载另外几份：UX 规格 → `references/sections-ux-spec.md`；HUD → `references/sections-hud.md`；交互模式库 → `references/sections-patterns.md`；无障碍 → `.claude/docs/templates/guidance/accessibility-requirements-guide.md`。（出处：Section guidance）
R7. 指南文件必须按节加载、禁止整读——各指南按小节组织，模板中的指针会指明要读的精确小节。（出处：Authoring guidance / Section guidance）
R8. 必须把 `docs.density`（Section 1 解析值）应用于每一节的撰写——它控制各节深度，不决定哪些节存在。（出处：Section 4）

**恢复与续作（Section 7）**
R9. 会话中断（压缩、崩溃、新会话）后必须按序恢复：先读 `production/session-state/active.md`（记录当前屏幕与已完成小节）；再读 `design/ux/[filename].md`——有真实内容的小节视为已完成，仍为 `[To be designed]` 的小节待做；从下一个未完成小节继续，禁止重新讨论已完成小节。（出处：Section 7）
R10. 必须增量写入：每个获批准的小节立即写入文件，使任何中断都不丢失已批准内容。（出处：Section 7 / Collaborative Protocol）

**专家智能体协作（Section 8）**
R11. 通过 `Agent` 工具委派时必须提供：屏幕名、游戏概念摘要、需要专家意见的具体问题；智能体返回分析后由本会话呈现给用户，用户决策，本会话写文件；禁止让智能体直接写文件。（出处：Section 8）
R12. 组件清单定稿前必须就实现可行性咨询 `ui-programmer`；数据归属不明时咨询 `game-designer`；无障碍等级由用户在 `/ux-design accessibility` 中选定并记录，等级标准由 `accessibility-specialist` 定义与审计——某条要求的判定标准不清时必须咨询之。（出处：Section 8）

**协作协议（collaborative 模式，默认；guided/autonomous 见 `.claude/docs/automation-modes.md`）**
R13. 每个小节必须走"提问 → 选项 → 决策 → 草稿 → 批准"循环；每个决策点用 `AskUserQuestion`：Phase 2 问"准备好开始还是需要更多上下文？"，Phase 3 问"可以创建骨架吗？"，Phase 4 每节问设计问题/方案选项/草稿批准，Phase 5 问"运行交叉引用检查？接下来做什么？"。（出处：Collaborative Protocol）
R14. 写骨架前和每节写入前必须先问"可以写入 [filepath] 吗？"；每次小节写入后必须更新会话状态（session state）。（出处：Collaborative Protocol）
R15. 美学问题必须让用户裁决：布局或视觉选择归结为个人口味时，列出选项并询问；禁止以"标准做法"为由自行选定布局——用户就是创意总监。（出处：Aesthetic deference）
R16. GDD 需求与可用屏幕空间冲突时必须浮出冲突并给出解决选项；禁止静默丢弃需求，禁止不加标注地静默扩张布局。（出处：Conflict surfacing）
R17. 禁止一次性自动生成完整规格再作为既成事实呈现；禁止未经用户批准写任何小节；禁止不加标注地与既有已批准 UX 规格矛盾；必须始终标明决策来源（GDD 需求、玩家旅程、用户选择）。（出处：Collaborative Protocol）
R18. 每次 `AskUserQuestion` 必须遵循 `.claude/docs/automation-modes.md`（collaborative 恒提问 · guided 仅重大事项 · autonomous 记录后继续；`automation_always_ask` 类别恒提问）。（出处：开头约定）

**收尾**
R19. 全部小节批准写入后裁决为 **COMPLETE**；推荐后续步骤：`/ux-review [filename]` 验证规格、`/ux-design [next-screen]` 继续设计其余屏幕、全部关键屏幕获批后 `/gate-check production`。（出处：Verdict / Recommended Next Steps）

## 4. 门禁与裁决
- 本技能自身无门禁智能体；技能内裁决词为 **COMPLETE**（UX 规格逐节撰写并获批准）。
- 下游关联门禁：`/gate-check production` 要求关键屏幕有已批准 UX 规格；Pre-Production 与 Polish 门禁检查 `design/accessibility-requirements.md` 存在于精确路径（见 R2）。

## 5. 移植建议
- **可直接移植**：R3、R4、R5–R10、R13–R19（逐节批准、增量写入、状态文件恢复、专家咨询不代写、冲突浮出、美学让渡、来源标注）均为与游戏无关的通用协作纪律。
- **需替换概念**：GDD → 各领域的需求文档（PRD/需求条目）；玩家旅程 → 用户旅程地图；HUD/屏幕 → 页面/视图/看板；引擎约束（`ui-programmer`）→ 前端/平台实现专家；`design/ux/` → 项目的 UX 文档目录。
- **改写示例**：
  - "每个设计小节必须走提问→选项→决策→草稿→批准循环；禁止在用户批准前写入任何小节，禁止一次性生成完整规格作为既成事实呈现。"
  - "全局规范文档（如无障碍要求）必须固定在其被门禁引用的精确路径，禁止为目录整洁而移动——移动即导致所有引用检查失配。"

## 6. 关联文档
- 上游：玩家旅程（`design/player-journey.md`）、GDD；指南：`.claude/docs/templates/guidance/ux-spec-guide.md`、`hud-design-guide.md`、`interaction-pattern-library-guide.md`、`accessibility-requirements-guide.md`
- 规范文档：`.claude/docs/automation-modes.md`、`workflow-modes.md`、`config-resolution.md`、`.claude/docs/workflow-catalog.yaml`
- 下游：`/ux-review`（规格校验）、`/gate-check production`、`/team-ui`（实现管线）
