# team-level — 关卡设计团队编排（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-level/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-level [level name or area to design] [--review full|lean|solo]`
- **一句话职责**：编排关卡团队（叙事+视觉方向→布局与遭遇→系统集成→制作概念+无障碍→QA 规划→汇编关卡设计文档）完成一个完整区域的设计。
- **触发前置**：必须提供关卡或区域名（如 `forest temple`、`tutorial village`、`final boss arena`）；无参数时直接输出用法指引并退出——不派生智能体、不读设计文件，此处不用 `AskUserQuestion`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, team.size`（`resolve_config`；`--review` 覆盖 `review_mode`） | 档位影响见下方注记 |
| 读取 | `design/gdd/game-concept.md`（或 `rigor: minimal` 的 `design/game-brief.md`，两者任一存在即读）、`design/gdd/game-pillars.md`、`design/levels/` 既有关卡文档、`design/narrative/` 相关叙事文档、区域所属地区/阵营的世界观文档、`design/art/art-bible.md`（存在时，Step 1 art-director 读） | 全部按节读：Grep `^#` 找标题 + Read offset/limit |
| 产出 | 草稿（subagent 写，`production/levels/[level-name]/` 下）：`narrative.md`、`lore.md`、`visual-direction.md`、`layout.md`、`systems.md`、`production-concepts.md`、`accessibility.md`；`production/qa/test-cases/[level-name]-cases.md`（Step 5 qa-tester）；定稿：`design/levels/[level-name].md`（编排器汇编后亲写） | 草稿为工作记录，持久记录是汇编成的关卡设计文档；`[level-name]` = 参数 slug |
| 派生智能体 | `narrative-director`（叙事目的、角色、情感弧线）；`world-builder`（lore 语境、环境叙事、世界规则）；`level-designer`（空间布局、节奏、遭遇、导航）；`systems-designer`（敌人组合、掉落表、难度平衡）；`art-director`（视觉主题、色板、光照、资产需求；Step 1 方向性 + Step 4 制作概念两轮）；`accessibility-specialist`（导航清晰度、色盲安全、认知负荷）；`qa-tester`（测试用例、边界测试、试玩清单） | active set 由 `team.size` 决定（R4） |

resolve_config 配置键及档位影响：
- `review_mode`：本管线无 director gate（任何档位不派生 CD-/TD-/PR-/AD-PHASE-GATE）；阶段门是管线自身决策点。
- `automation`：`collaborative` 逐步批准；`guided` 自动推进除非 BLOCKED；`autonomous` 端到端并 `log_decision`；`automation_always_ask` 类别任何模式必问。
- `team.size`：`individual`（默认）= 仅 `level-designer`，其余经其咨询；`small` = 加 `systems-designer` + `art-director` + `qa-tester`；`studio` = 再加 `narrative-director` + `world-builder` + `accessibility-specialist`（完整管线照文档跑）。

## 3. 核心规则（逐条编号 R1、R2……）

**入口与配置（Phase 0）**
R1. 无参数时直接输出用法指引并退出——不派生智能体、不读设计文件。
R2. 每个步骤转换点用 `AskUserQuestion` 呈现 subagent 提案（完整分析写进会话、简短标签捕获决策）；三档 automation 行为同 §2 注记。Active-set 作用域贯穿全管线：非激活智能体经最近核心智能体路由（附 informational note）；"phase gate" 指本管线列出的、以 `AskUserQuestion` 结束的任何阶段（Decision Points 转换或管线内 Gate 步骤），无论 automation 模式。
R3. **Step 1 前宣布 active set——收缩永不静默**：spawn 前一行说明实际派生与点名但不派生的智能体；从 team.size 列表和自身管线名单填。默认档收敛成单智能体是正确行为——不说明则无法与坏管线区分。

**步骤 0 读取参数与收集语境**
R4. 读取目标关卡/区域参数；按节收集语境（Grep `^#` + Read offset/limit）：game-concept 或 game-brief（任一存在）、`design/gdd/game-pillars.md`、`design/levels/` 既有关卡文档、`design/narrative/` 相关叙事文档、区域所属地区/阵营的世界观文档。

**委派协议（How to Delegate）**
R5. **做简报、不倒上下文**：共享输入只读一次、蒸馏简报内联传入；已读文档绝不传路径；只为没读过且只有该智能体需要的文档传路径。
R6. **每个 agent prompt 以 return contract 结尾**（写 `[path]`、只返回路径 + ≤5 条决策要点 + BLOCKED/CONCERNS 各一行、不重述所读文档）。
R7. **路径表**：工作工件入 `production/levels/[level-name]/`（slug 见 R22），每智能体一个文件，保证并行步骤不共享文件（§2 表）；Step 5 qa-tester 的测试用例写 `production/qa/test-cases/[level-name]-cases.md`（测试用例、边缘情形、试玩清单、验收标准）。这些是工作草稿；持久记录是你从中汇编的关卡设计文档（`design/levels/[level-name].md`）。
R8. **Bounded exception（三条件同时成立免问直写）**：(1) 路径是你点名的；(2) `production/`、`docs/`、`tests/` 下新工件，绝不编辑既有源码或配置；(3) 产出阶段被 `AskUserQuestion` 门禁。之外必须问；禁止用"每个 subagent 都问一遍"修复。

**Step 1 叙事 + 视觉方向（三路并行）**
R9. **三个 Agent 调用同时发出后再等结果**：`narrative-director`（本区域叙事目的——此处发生哪些故事节拍；关键角色、对白触发器、lore 元素；情感弧线——玩家进入时/进行中/离开时应感受什么）；`world-builder`（区域 lore 语境——历史、阵营存在、生态；环境叙事机会；影响本区域玩法的任何世界规则）；`art-director`（本区域**视觉主题目标——它们是布局的输入、不是布局的输出**；色温与光照情绪——与相邻区域如何区分；形状语言方向——棱角要塞？有机洞穴？衰败的宏伟？;定位玩家用的主要视觉地标；`design/art/art-bible.md` 存在时按节读并把全部方向锚定在既有 art bible 上）。
R10. **art-director 的 Step 1 视觉目标必须作为显式约束传给 Step 2 的 level-designer**——布局决策发生在视觉方向之内，不在它之前。**Gate**：`AskUserQuestion` 呈现三份产出（叙事 brief、lore 基础、视觉方向目标）并确认后才进 Step 2。

**Step 2 布局与遭遇设计（level-designer）**
R11. 带完整 Step 1 输出（叙事 brief、lore 基础、**视觉方向目标——布局必须在这些目标内工作、不得矛盾**）委派 `level-designer`：空间布局（关键路径、可选路径、秘密）且主动路线对齐 Step 1 视觉地标目标；节奏曲线（张力峰值、休息区、探索区）与叙事情感弧线协调；按难度递进放置遭遇；环境谜题或导航挑战；寻路用的兴趣点与地标——**必须与 art-director 指定的视觉地标一致**；入口/出口及与相邻区域的连接。
R12. **相邻区域依赖检查**：布局产出后，对 level-designer 引用的每个相邻区域检查 `design/levels/`；被引用区域的 `.md` 不存在时上浮："Level references [area-name] as an adjacent area but `design/levels/[area-name].md` does not exist."，`AskUserQuestion` 二选：(a) 带占位引用继续——连接在关卡文档中标记 **UNRESOLVED** 并列入汇总报告的 open cross-level dependencies 节；(b) 暂停、先跑 `/team-level [area-name]` 建立该区域。**禁止为缺失的相邻区域发明内容。** **Gate**：呈现 Step 2 布局（含未解决的相邻区域依赖）确认后才进 Step 3。

**Step 3 系统集成（systems-designer）**
R13. 委派 `systems-designer`：敌人组合与遭遇公式；掉落表与奖励放置；相对预期玩家等级/装备平衡难度；区域专属机制或环境危害；资源分布（治疗拾取、存档点、商店）。**Gate**：呈现 Step 3 产出确认后才进 Step 4。

**Step 4 制作概念 + 无障碍（两路并行）**
R14. art-director 的方向性 pass（视觉主题、色彩目标、情绪）已在 Step 1 完成；本轮是**给定既定布局后逐位置的制作概念**。带 Step 2 定稿布局委派 `art-director`：关键空间（入口、关键遭遇区、地标、出口）的逐位置概念规格；本区域独有 vs 全局共享的美术资产；逐关键空间的视线与光照设置（此时是布局知情的、非方向性的）；本区域布局特有的 VFX 需求（天气体积、粒子、氛围效果）；把布局与 Step 1 目标冲突的位置标记为**生产风险**上浮。
R15. 并行委派 `accessibility-specialist`：导航清晰度（玩家能否不依赖颜色自行定向）；关键路径导引在颜色之外是否使用形状/图标/声音线索；谜题机制的认知负荷——**标记任何要求同时持有超过 3 个状态的项**；关键玩法区域对色盲玩家的足够对比度。产出带严重度的无障碍关切清单（**BLOCKING / RECOMMENDED / NICE TO HAVE**）。**等两路都返回才继续。**
R16. **Gate**：呈现两份 Step 4 结果；accessibility-specialist 返回任何 **BLOCKING** 关切时显著突出，并提供：(a) 回到 level-designer 与 art-director 重设计被标记元素后再进 Step 5；(b) 记录为已知无障碍缺口、带着显式落入最终报告的关切继续进 Step 5。**未获用户确认任何 BLOCKING 无障碍关切前不得进 Step 5。**

**Step 5 QA 规划（qa-tester）**
R17. 委派 `qa-tester`：为关键路径写测试用例；识别边界与边缘情形（sequence breaks、softlocks）；为区域建试玩清单；定义关卡完成的验收标准（写 `production/qa/test-cases/[level-name]-cases.md`）。

**汇编、落盘与汇报**
R18. **汇编关卡设计文档时编排器自己动手——禁止 re-spawn `level-designer` 并把全部输出原样重发**：第二次 spawn 要付出一个新智能体的开销加上编排器已持有上下文的完整重传，只为搬运它已经拿着的文本。按关卡设计模板格式汇编后，`AskUserQuestion` 直接问 "May I write the compiled level design to `design/levels/[level-name].md`?"，批准后写入。
R19. 落盘 `design/levels/[level-name].md` 必须在那次批准之后；`[level-name]` = 参数 slug——小写、空格转连字符（`forest dungeon` → `forest-dungeon.md`）；相邻区域检查中的 `[area-name]` 同样方式 slug 化。
R20. 汇总输出：区域概览、遭遇数量、估算资产清单、叙事节拍、跨团队依赖或开放问题、**open cross-level dependencies**（被引用但尚未设计的相邻区域，逐个标记 UNRESOLVED）、无障碍关切及其解决状态。

**错误恢复与文件写入协议**
R21. **先验证工件**：return contract 点了路径就先查路径存在——**点名却不在盘上的工件是失败阶段，无论回应读起来多流畅**；恢复它并点名未满足的契约，上下文通常还在。
R22. 任何智能体 BLOCKED/出错/无法完成：立即上浮、不越过被阻塞的依赖、**永远产出部分报告**；被跳过智能体的节保持具名缺口——绝不用自己的内容填充。完整流程见 `.claude/docs/error-recovery-protocol.md`。常见阻塞：输入文件缺失→重定向到创建它的技能；ADR Proposed→不实现、定后 `/architecture-decision accept ADR-NNNN`；范围太大→`/create-stories` 拆分；ADR 与 story 冲突→上浮冲突，不猜。
R23. File Write Protocol：每智能体工件（叙事文档、测试清单等）由产出它的 subagent 写，走 bounded exception 免问直写；**唯一例外是最终汇编的关卡设计文档**——编排器已持有每一份输入，自己汇编、在自己的 "May I write …?" 之后写入；re-spawn 一个智能体只为写编排器已持有的文本纯属开销。
R24. 裁决：**COMPLETE**——关卡设计文档已产出且全部团队输出已汇编；**BLOCKED**——一个或多个智能体被阻塞、或有智能体被跳过（error-recovery-protocol 第 5 步）；产出部分报告并列出未决项。
R25. 后续：跑 `/design-review design/levels/[level-name].md` 校验完成的关卡设计文档；设计批准后跑 `/dev-story` 实现关卡内容；跑 `/qa-plan` 生成本关卡 QA 测试计划。

## 4. 门禁与裁决
- 本管线无 director gate；自身 Gate 步骤：Step 1 三产出确认（R10）、Step 2 布局+依赖确认（R12）、Step 3 系统产出确认（R13）、Step 4 双产出确认且 **BLOCKING 无障碍关切必须获用户确认**（R16）、定稿写入批准（R18）。
- 无障碍关切严重度：**BLOCKING / RECOMMENDED / NICE TO HAVE**；BLOCKING 未获用户确认不得进下一步。
- 裁决词：**COMPLETE / BLOCKED**；被跳过的智能体按 error-recovery-protocol 第 5 步处理时只能 BLOCKED，并附部分报告。

## 5. 移植建议
- **可直接移植**：R1-R3（无参即停 + active set 显式宣布）、R5-R8（简报不倒上下文 + return contract + 每智能体一个文件 + bounded exception 三条件）、R9-R10（方向先行：视觉/规范目标是布局的输入不是输出，必须作为显式约束下传）、R12（相邻依赖检查 + UNRESOLVED 占位 + 禁止发明缺失内容）、R15-R16（BLOCKING 严重度分级 + 用户确认门）、R18（编排器亲自汇编，禁止 re-spawn 智能体搬运已持有的文本）、R21-R22（工件验证 + 部分报告）、R20（未决跨域依赖显式列出）。
- **需替换概念**：关卡 → 任一空间/结构化交付物（站点地图、门店布局、课程结构）；视觉地标 → 关键导航锚点；相邻区域依赖 → 模块间依赖；art bible → 品牌/设计规范；敌人组合与掉落表 → 内容配比与资源分配；无障碍 → 可访问性/合规约束；sequence breaks、softlocks → 边界滥用与死锁场景。
- **改写示例**：
  - "方向性规范（视觉/结构/基调）必须在布局设计之前产出，并作为显式约束传给布局设计者——布局决策发生在方向之内，不在它之前；寻路锚点必须与方向阶段指定的地标一致。"
  - "交付物引用了尚不存在的相邻模块时，禁止为其发明内容：要么以 UNRESOLVED 占位并列入报告的未决依赖，要么暂停、先建立被引用模块。汇编最终文档由编排者亲自完成——重新派生一个智能体只为搬运编排者已持有的文本纯属开销。"

## 6. 关联文档
- 上游：`design/narrative/`（`/team-narrative` 产出）、`design/art/art-bible.md`、`design/gdd/game-pillars.md`。
- 下游：`/design-review design/levels/[level-name].md`、`/dev-story`（实现关卡内容）、`/qa-plan`（QA 测试计划）、`/team-narrative`（缺失相邻区域可先跑）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`。
