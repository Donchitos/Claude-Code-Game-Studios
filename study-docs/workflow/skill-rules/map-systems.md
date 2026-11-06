# map-systems — 把概念分解为系统索引（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/map-systems/SKILL.md) ｜ 阶段：Phase 1-2 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/map-systems [next | system-name] [--review full|lean|solo]`
- **一句话职责**：把概念分解为单个系统、映射依赖、排定设计优先级、创建系统索引；`next` 模式则从索引挑最高优先级未设计系统并交给 `/design-system`
- **触发前置**：`design/gdd/game-concept.md` 存在（`minimal` 档下为 `design/game-brief.md`）；两者皆无必须失败并提示先跑 `/brainstorm`。`workflow: full/standard` 下本技能是 `/design-system` 的前置；`minimal` 下非必需（brief 替代索引）但仍可自愿运行

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, workflow, docs.density, project.stage` | `--review` 覆盖 `review_mode`；无块用 `.claude/docs/config-resolution.md` 默认 |
| 读取 | `design/gdd/game-concept.md`（或 minimal 的 brief） | 分解的原料，**必读** |
| 读取 | `design/gdd/game-pillars.md`、既有 `systems-index.md`、Glob `design/gdd/*.md` | 可选：约束优先级；存在则 resume；查已有 GDD |
| 产出 | `design/gdd/systems-index.md` | 按模板 `.claude/docs/templates/systems-index.md`；含枚举表、依赖图、推荐设计顺序、高风险系统、进度跟踪器 |
| 产出 | `production/session-state/active.md` | 不存在则创建，写入任务/状态/文件/下一步 |
| 派生智能体 | `technical-director`（TD-SYSTEM-BOUNDARY）、`producer`（PR-SCOPE）、`creative-director`（CD-SYSTEMS） | 均经 `Agent` 派生、各读自己的门禁文件，父会话不读 |

**docs.density 档位**：`terse`（默认，via `rigor: minimal`）= 单行系统描述；`balanced`（`rigor: standard`）= 每系统一小段+依赖注记；`thorough` = 逐系统完整理由+关系分析。`workflow` 决定哪些节存在，`docs.density` 决定每节深度。`modes.rigor` 同时设两者；单独调深度须显式设 `docs.density`。

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 1 读取概念**
R1. 必读 `design/gdd/game-concept.md`（minimal 时读 `design/game-brief.md`）；两者皆无则带清晰错误信息失败："No game concept found. Run `/brainstorm` first…"。读文档必须按节读：Grep `^#` 找标题、Read 对应范围。
R2. 系统索引已存在时：读它、向用户呈现当前状态，并问"The systems index already exists with [N] systems ([M] designed, [K] not started). What would you like to do?"（Update the index with new systems / Design the next undesigned system / Review and revise priorities）——更新而非重建。

**Phase 2 系统枚举**
R3. 先扫概念提取**显式系统**（来源：Core Mechanics 最显式、Core Loop、Technical Considerations、MVP Definition），再为每个显式系统推断**隐式系统**，并在对话文本中解释每个隐式系统为何需要（带例子）。源文件给出的推断模式：Inventory 蕴含 item database、equipment slots、weight/capacity 规则、inventory UI、存档序列化；Combat 蕴含伤害计算、生命、命中检测、状态效果、敌人 AI、战斗 UI、死亡/重生；Open world 蕴含 streaming/chunking、LOD、fast travel、地图/小地图、POI 跟踪、世界状态持久化；Multiplayer 蕴含网络层、大厅/匹配、状态同步、反作弊、网络 UI；Crafting 蕴含配方库、材料收集、制作 UI、成败机制、配方发现；Dialogue 蕴含对话树、对话 UI、选择跟踪、NPC 状态、本地化钩子；Progression 蕴含 XP、升级机制、技能树、解锁跟踪、进度 UI、进度存档。
R4. 按类别呈现枚举：每系统显示 Name、Category、一句话描述、显式还是隐式；用 AskUserQuestion 问：缺系统吗？该合并或拆分吗？列出的系统里有这游戏**不需要**的吗？`collaborative` 迭代到用户批准；`guided` 问一次、应用答案、不循环；`autonomous` 不问，用 `log_decision` 记录枚举及推断后继续。

**Phase 3 依赖映射**
R5. 依启发式映射依赖：输入/输出依赖（A 产 B 需的数据）、结构依赖（A 提供 B 插入的框架）、UI 依赖（每个 gameplay 系统有依赖它的 UI 系统，但 UI 在 gameplay 系统之后设计）。
R6. 按**五层**排序：Foundation（零依赖，最先设计）、Core（仅依赖 Foundation）、Feature（依赖 Core）、Presentation（包装 gameplay 的 UI/反馈）、Polish（元系统、教程、分析、无障碍）。
R7. 检测**循环依赖**：发现必须向用户高亮并提出解法（接口抽象、同时设计、以两系统间契约打破循环）。
R8. 呈现分层依赖图并高亮：循环依赖、**瓶颈系统**（多系统依赖=高风险）、无依赖者（叶节点=低风险、可晚设计）；问"依赖顺序对吗？有漏或该删的依赖吗？"
R9. **表格契约**：`templates/systems-index.md` 的 Systems Enumeration 是固定列表格——**禁止给它加列**（这是 schema 变更而非格式选择）。消费者不按位置解析：`gdd-structure-check.sh:51`、`review-scope.sh:40` 只按文件名匹配；`/design-system` §6/§7 按**列名**用 `Category` 列——`Category` 是绝不能改名或删除的列。`balanced`/`thorough` 的散文放 `## Overview`（balanced 每系统一段，thorough 加关系分析）和 `## Dependency Map` 层注记。`terse` 时表格+一段 `## Overview` 即全部输出。

**Phase 4 优先级分配**
R10. 按启发式初排四档：**MVP**（概念 "Required for MVP" 节的系统+其 Foundation 层依赖）、**Vertical Slice**（一个区域完整体验所需）、**Alpha**（其余 gameplay 系统）、**Full Vision**（Polish、meta、nice-to-have）；表格呈现并用 AskUserQuestion 问"这些分配符合你的愿景吗"。
R11. 理由措辞：两张表都**没有 Why 列**（Systems Enumeration 列为 `# / Name / Category / Priority / Status / Design Doc / Depends On`；Recommended Design Order 列为 `Order / System / Priority / Layer / Agent(s) / Est. Effort`），理由只活在对话与索引 `## Overview` 段落，**禁止为它发明列**。理由必须混合技术必要性与玩家体验论证（纯技术理由不足），并引用所服务的 pillar。源文件给出的范例句式：
   - "Required for the core loop — without it the player's main choice has no consequence (Pillar [N]: [pillar name])"
   - "This is where [system]'s identity is established — the stat definitions here are what make it feel different from [the sibling system]"
   - "Foundation for every later economy decision — the player must understand costs before any of the choices built on top of it mean anything"
   **括号占位必须从本项目填充**，禁止照搬别的项目的示例词汇。
R12. 设计顺序 = 依赖排序 × 优先级：MVP Foundation → MVP Core → MVP Feature → Vertical Slice Foundation/Core → 依此类推；这是团队写 GDD 的顺序。

**Phase 5 写索引**
R13. 用模板起草：填枚举表、依赖图、推荐设计顺序、高风险系统、进度跟踪器（初始全 "Not Started"，除非 GDD 已存在）。
R14. 呈现摘要（按类别系统总数、MVP 系统数、设计顺序前 3 系统、高风险项）后按 automation 档写盘：`collaborative` 问"May I write the systems index to `design/gdd/systems-index.md`?"，等 yes 才写；`guided` 对**新**索引同样问"May I write?"，对**已存在**索引呈现摘要、指明目标路径后**不等 yes 直接写**，事后说明写了什么。
R15. 写盘后更新 `production/session-state/active.md`（不存在则创建）：Task: Systems decomposition；Status: Systems index created；File: design/gdd/systems-index.md；Next: Design individual system GDDs。结尾打 `Verdict: COMPLETE`（用户拒写则 `Verdict: BLOCKED — user did not approve the write`）。

**Phase 6/7 交接**
R16. 进入单个系统设计的三个入口：用户在索引完成后说 yes、`/map-systems [system-name]`、`/map-systems next`（选设计顺序中最高优先级未设计系统）。选定后调用 `/design-system [system-name]`——它承担完整的 GDD 创作过程：从概念/索引/依赖 GDD 收集上下文、立即创建文件骨架、逐节协作走完全部必需节、交叉引用既有文档防矛盾、按类型路由专家智能体、每节批准后立即写盘、完成后（在新会话）跑 `/design-review`、更新系统索引。**禁止在本技能内重复 /design-system 的工作流**——本技能拥有系统*索引*，`/design-system` 拥有单个系统 *GDD*。每轮完成后问：继续下一个 / 换一个 / 停止。
R17. 索引完成后用 AskUserQuestion 提供后续：[A] `/design-system [设计顺序第一个]`；[B] `/gate-check systems-design`（**仅当 `project.stage` 仍是 Concept 时提供**）；[C] `/gate-check technical-setup`（MVP 系统有 GDD 后）；[D] 停止。单个 GDD 完成后建议：新会话跑 `/design-review design/gdd/[system].md`、全部 MVP GDD 完成后跑 `/gate-check technical-setup`。

**协作协议与上下文**
R18. `collaborative`（默认）下每步遵循 Question → Options → Decision → Draft → Approval；每个决策点用 AskUserQuestion（枚举/依赖/优先级/写盘四类问题**各自独立成问**，每个都等答案再走下一步）；每次写盘前问"May I write to [filepath]?"；每系统设计完后增量更新索引；每个里程碑后写 `active.md`。**绝不**未经审查就自动生成完整系统列表并写盘；**绝不**未经用户确认就开始设计某系统；**始终**展示枚举、依赖、优先级供用户验证。
R19. 上下文窗口达到或超过 **70%** 时必须附加提示：索引已存到 `design/gdd/systems-index.md`，开新会话跑 `/map-systems next` 继续。

## 4. 门禁与裁决（如适用）
三个门禁均为**技能内门禁**（在 `full` review 模式下于本技能运行，不在 `/gate-check` 里）；`solo` 与 `lean` 都跳过（非 PHASE-GATE）并注记 `"<GATE> skipped — Solo mode."`（或 Lean mode）：

| 门禁 ID | 审查者 | 时机 | 传入内容 | 裁决处理 |
|---------|--------|------|----------|----------|
| TD-SYSTEM-BOUNDARY | `technical-director` | 依赖映射获批后、优先级分配前 | 依赖图（每系统→依赖）、层分配、瓶颈系统、循环依赖及解法 | REJECT：与用户修订边界、展示修订后依赖图，**之后才**进优先级；CONCERNS：在索引内联注记后继续；NOT ASSESSED 不是 APPROVE：命名缺失输入补齐重跑，或以 `TD-SYSTEM-BOUNDARY: NOT ASSESSED — [input]` 注记进索引草案 |
| PR-SCOPE | `producer` | 优先级获批后、写索引前 | full vision scope（全部系统）、MVP 定义（MVP 档系统）、scope tiers（每档系统数×平均复杂度的实施量）、项目时间线、团队规模 | 答 REALISTIC / OPTIMISTIC / UNREALISTIC。UNREALISTIC：提供修订优先级档的选项；OPTIMISTIC：展示建议调整并问是否应用，拒则注记后继续；NOT ASSESSED（常缺 team size 或 timeline）不是 REALISTIC：命名缺失补齐重跑，或以 `PR-SCOPE: NOT ASSESSED — [input]` 注记继续 |
| CD-SYSTEMS | `creative-director` | 索引写盘后 | 索引路径；pillars 与 core fantasy（来自 concept，minimal 时用 brief 的 pitch 与 "what they feel" 行）；四档优先级分配；高风险与瓶颈系统 | REJECT：GDD 创作开始前与用户修订系统集；CONCERNS：展示并问 `Revise the system set` / `Accept — record them in the index` / `Discuss further`——选 Accept 即视为同意记录为 `> **Creative Director Note**`，置于 `## Priority Tiers` 表**正下方**并命名所涉档位（如 `(MVP): …`；模板只有 Priority Tiers 定义表、无每档小节，**不要**指使写手找"档位小节顶部"）；NOT ASSESSED 不是 APPROVE：命名缺失补齐重跑，或经询问后记录 `> **Creative Director Note**: CD-SYSTEMS NOT ASSESSED — [input]` 于同一位置 |

## 5. 移植建议
- **可直接移植**：R1（缺上游文档即失败并指路）、R3-R4（显式/隐式分解+用户确认）、R6-R7（分层排序与循环检测）、R10/R12（里程碑档位+设计顺序推导）、R14（新文件要问、更新文件声明后直写）、R18（问题分立、逐个等答案）、R19（70% 上下文预警）。
- **需替换概念**：系统/Category 五层 → 模块/服务分层；systems-index → 架构组件清单或 WBS；`/design-system` → 模块规格说明书流程；`/gate-check` → 阶段准入评审；director 门禁 → 技术评审人/产品评审人角色。
- **改写示例**：
  - "分解产物是一张固定列契约表：消费者按列名（而非位置）读取 `Category` 列。禁止向该表添加列——加列是 schema 变更，须走契约变更流程；各条目的说明性散文写入 `## Overview` 段落。"
  - "依赖映射获批后、进入排期前，必须由技术负责人评审依赖图与循环依赖；REJECT 时先修订并重新展示依赖图，评审通过前禁止排期。"

## 6. 关联文档
- 上游：`/brainstorm`（概念书）
- 下游：`/design-system`（单个系统 GDD）、`/design-review`、`/gate-check systems-design`、`/gate-check technical-setup`
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/templates/systems-index.md`
