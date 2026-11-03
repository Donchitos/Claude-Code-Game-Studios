# team-narrative — 叙事内容团队编排（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-narrative/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-narrative [narrative content description] [--review full|lean|solo]`
- **一句话职责**：编排叙事团队（叙事方向→世界观/对白/视觉并行→关卡叙事整合→一致性审查→打磨并行→定稿）产出剧情、世界设定与叙事驱动的内容，全程守住既有 canon（正典）。
- **触发前置**：必须提供叙事内容描述（如 `boss encounter cutscene`、`faction intro dialogue`、`tutorial narrative`）；无参数时直接输出用法指引并退出——不派生任何智能体，且此处**不用** `AskUserQuestion`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, team.size`（`resolve_config` 解析，`--review` 覆盖 `review_mode`；无配置块默认值见 `.claude/docs/config-resolution.md`） | 档位影响见下方注记 |
| 读取 | 叙事 bible 或 tone guide、`design/narrative/` 下的角色与阵营文件、世界规则 | **先读 canon**（R6）；不存在时必须先问用户，禁止让智能体发明 canon |
| 产出 | 草稿（subagent 写）：`production/narrative/[content-slug]/` 下 `brief.md`、`lore-[topic].md`、`dialogue-[scene-slug].md`、`visual-direction.md`、`level-integration.md`、`i18n-review.md`；定稿（编排器写）：`design/narrative/[content-slug]-brief.md`、`design/narrative/lore/[topic].md`、`design/narrative/dialogue/[scene-slug].md`、`design/narrative/[content-slug]-visual-direction.md`、`design/narrative/[content-slug]-level-integration.md`（i18n-review 留在 `production/`——是评审不是设计文档） | 草稿在 bounded exception 内免问直写；`design/narrative/` 在例外之外，由编排器批准后亲写；草稿保留为工作记录 |
| 派生智能体 | `narrative-director`（故事弧线、角色设计、对白策略、叙事愿景；Phase 4 以 ND-CONSISTENCY 门禁身份复审）；`writer`（对白、lore 条目、物品描述、游戏内文本）；`world-builder`（世界规则、阵营设计、历史、地理、环境叙事）；`art-director`（角色视觉设计、环境视觉叙事、过场/ cinematic 基调）；`level-designer`（服务叙事的关卡布局、节奏、环境叙事节拍）；`localization-lead`（本地化就绪——标记不可本地化字符串、文化假设、i18n 缺口） | active set 由 `team.size` 决定（R4）；默认档只有 `writer` 一人跑全管线 |

resolve_config 配置键及档位影响：
- `review_mode`：本管线无 director gate（不派生 CD-/TD-/PR-/AD-PHASE-GATE）；**唯一例外是 Phase 4 的 ND-CONSISTENCY——它在每个 review_mode 都跑**：它是管线自己的审查而非可选的总监门禁，`review_mode` 从不跳过它（`team.size` 仍决定谁跑它）。
- `automation`：驱动 Decision Points——`collaborative` 逐阶段批准；`guided` 自动推进除非 BLOCKED；`autonomous` 端到端并 `log_decision`。
- `team.size`：`individual`（默认）= 仅 `writer`；`narrative-director` 仅在显式 pillar 冲突时调用；其余经 writer 咨询。`small` = `narrative-director` + `writer`，且 `review_mode: full` 时加 `localization-lead` 与 `world-builder`（`lean`/`solo` 下经 writer 咨询）。`studio` = 全部六名成员，无论 `review_mode`。

## 3. 核心规则（逐条编号 R1、R2……）

**入口与配置（Phase 0）**
R1. 无参数时直接输出用法指引（不用 `AskUserQuestion`）并退出，不派生任何智能体。
R2. 每个阶段转换点用 `AskUserQuestion` 呈现 subagent 提案（完整分析写进会话，决策用简短标签捕获）；`collaborative` 必须批准；`guided` 自动推进除非 BLOCKED；`autonomous` 端到端并 `log_decision`；`automation_always_ask` 类别任何模式必问。
R3. Active-set 作用域贯穿全管线：非激活智能体经最近的核心智能体路由（附 informational note），不单独派生；"phase gate" 指本管线自己列出的、以 `AskUserQuestion` 决策点结束的任何阶段（Decision Points 转换或管线内 Gate 步骤），无论 `automation` 模式。
R4. **Phase 1 前宣布 active set——收缩永不静默**：spawn 前一行说明本次实际派生哪些智能体、管线点名但不派生哪些（"Active set (team.size: …)" / "Not spawned this run: … — consulted through … Raise team.size (or modes.rigor) to widen."）；从 team.size 列表和本文件管线名单填、不从例子填。默认档收敛成单智能体（如本技能：六名点名、默认只跑 `writer` 一人）是正确行为——不显式说明，读者无法区分正确收缩与坏掉的管线。

**委派协议（How to Delegate）**
R5. **先读 canon**：Phase 1 前读存在的共享输入——叙事 bible 或 tone guide、`design/narrative/` 下角色与阵营文件、世界规则。**绝不叫智能体发明 canon**：一个都不存在时就直说并先问用户，之后才开始起草。
R6. **做简报、不倒上下文**：共享输入只读一次，把蒸馏后的简报内联传入——只传该智能体真正需要的行；已读文档绝不传路径；只为没读过且只有该智能体需要的文档传路径。
R7. **每个 agent prompt 以 return contract 结尾**："Write your full output to `[path]` — … Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."
R8. **草稿/定稿双轨路径表**（草稿在 `production/narrative/[content-slug]/`、定稿在 `design/narrative/`，见 §2）。**定稿目的地不是自由选择**：`design/narrative/` 被 `/asset-spec`、`/design-review`、`/localize`、`/onboard`、`/project-stage-detect`、`/team-level` 和 `cd-narrative` 总监门禁读取——写到别处的工件对这七者全部不可见。return contract 有前提：路径必须是你点名的——只写契约不点具体目的地，每次运行都会自造一个，契约即失效。
R9. **Bounded exception（三条件同时成立，subagent 免问直写）**：(1) 路径是你点名的；(2) 是 `production/`、`docs/`、`tests/` 下的新工件，绝不编辑既有源码或配置；(3) 产出阶段被 `AskUserQuestion` 门禁。三条件之外必须问；**禁止用"每个 subagent 都问一遍"修复**。

**Phase 1 叙事方向**
R10. 委派 `narrative-director`：定义本内容的叙事目的（服务哪个故事节拍）；识别涉及角色、动机及与整体弧线的关系；定情绪基调与节奏目标；指明 lore 依赖或新引入的 lore。产出带故事需求的叙事 brief（`brief.md`）。

**Phase 2 世界基础（并行）**
R11. **三个 Agent 调用同时发出后再等结果**：`world-builder`（为本内容相关的阵营/地点/历史创建或更新 lore 条目；与既有 lore 交叉核对矛盾；为新条目定 canon level）；`writer`（用 voice profiles 起草角色对白；**每行不超 120 字符**；变量用命名占位符；本地化就绪）；`art-director`（关键角色的视觉设计方向——剪影、视觉原型、辨识特征；每个关键空间的环境视觉叙事——道具构图、光照注记、空间安排；过场/脚本序列的基调色板与 cinematic 方向）。
R12. **Phase gate**：收齐三份产出后、开始 Phase 3 前应用 Decision Points 规则——呈现 lore、对白、视觉方向摘要，`collaborative` 用 `AskUserQuestion` 捕获批准（`guided` 无 BLOCKED 即自动推进；`autonomous` 用 `log_decision`）。

**Phase 3 关卡叙事整合**
R13. 委派 `level-designer`：审阅叙事 brief 与 lore 基础；在关卡中设计环境叙事元素；放置叙事触发器、对白区域、发现点；确保节奏同时服务玩法与故事。产出 `level-integration.md`。

**Phase 4 一致性审查（ND-CONSISTENCY）**
R14. 用 `Agent` spawn `narrative-director` 执行门禁 **ND-CONSISTENCY**（`.claude/docs/director-gates/nd-consistency.md`）。本阶段**每个 review_mode 都跑**。传入该门禁列出的上下文（Phase 2–3 草稿路径、叙事 bible 或 tone guide、世界规则、受影响角色与阵营档案——已在此点名，故本会话**不读门禁文件**），另加两项：确认叙事节奏与关卡设计对齐；检查所有 mystery 都有记录在案的 "true answers"。
R15. 按裁决行动：**APPROVE** → Phase 5。**CONCERNS** → 列出不一致项并 `AskUserQuestion` 问是修订（re-spawn 负责的智能体）还是接受。**REJECT** → 不开始 Phase 5，先修矛盾。**NOT ASSESSED [缺失输入]** → 点名缺失输入、补齐后重跑门禁，或把 `ND-CONSISTENCY: NOT ASSESSED — [input]` 带进报告的一致性审查结果；**绝不读作 APPROVE**。
R16. **`team.size: individual` 时门禁不 spawn**（narrative-director 不在激活集）：由 `writer` 按相同标准自检草稿，输出必须点名："ND-CONSISTENCY not run — narrative-director is not active at `team.size: individual`; consistency self-checked by writer."——自检不是门禁裁决，报告**不得**把它呈现为裁决。

**Phase 5 打磨（并行）**
R17. 每个 Agent 调用发出后再等结果：`writer`（终审自查——无一行超出对白框约束、全部文本用 string key 而非原始字符串、占位符变量名一致）；`localization-lead`（i18n 合规——string key 命名规范；标记带硬编码格式、活不过翻译的字符串；为膨胀语言核对字符上限余量——**德语/芬兰语典型 +30%**；确认无需要 locale 变体的文化假设）；`world-builder`（为全部新 lore 条目定稿 canon level）。

**定稿（Write the finals）**
R18. 你持有每一份草稿：按路径表列定稿清单，`AskUserQuestion` **一次性**问 "May I write these [N] narrative documents to `design/narrative/`?"，批准后写入；`production/narrative/[content-slug]/` 下的草稿保留为工作记录。

**错误恢复与文件写入协议**
R19. **先验证工件**：return contract 点了路径就先查路径存在——**点名却不在盘上的工件是失败阶段，无论回应读起来多流畅**。恢复它并点名未满足的契约；上下文通常还在。
R20. 任何智能体 BLOCKED/出错/无法完成：立即上浮、不越过被阻塞的依赖、**永远产出部分报告**；被跳过智能体的节保持具名缺口——绝不用自己的内容填充。完整流程见 `.claude/docs/error-recovery-protocol.md`。
R21. 常见阻塞：输入文件缺失 → 重定向到创建它的技能；ADR 状态 Proposed → 不实现，定了后 `/architecture-decision accept ADR-NNNN`；范围太大 → `/create-stories` 拆分；ADR 与 story 冲突 → 上浮冲突，不猜。
R22. File Write Protocol：subagent 把草稿写到 `production/narrative/` 下你点名的路径，走 bounded exception 免问直写；**唯一例外是 `design/narrative/` 下的定稿**——你持有全部草稿，故由你在 "Write the finals" 的单次询问后亲写。

**输出与后续**
R23. 汇总报告覆盖：叙事 brief 状态、创建/更新的 lore 条目、写出的对白行数、关卡叙事整合点、一致性审查结果、未解决矛盾——**含用户选择不修的每个本地化问题，按 string key 列出**。裁决：**COMPLETE**；ND-CONSISTENCY 曾答 NOT ASSESSED 且被带入报告时**绝不给光秃秃的 COMPLETE**——**COMPLETE — consistency NOT ASSESSED ([input])**；依赖未解决（如 lore 矛盾或前置缺失且用户未处理）→ **BLOCKED — [reason]**。
R24. 后续：对叙事文档跑 `/design-review` 做一致性校验；对白定稿后跑 `/localize extract` 提取新字符串；跑 `/dev-story` 在引擎内实现对白触发与叙事事件。

## 4. 门禁与裁决
- **ND-CONSISTENCY**（Phase 4，叙事总监一致性门禁）：每个 `review_mode` 都跑（管线自己的审查，`review_mode` 从不跳过；`team.size` 决定谁来跑）；传入门禁文件列出的上下文 + 节奏对齐与 mystery "true answers" 两项附加检查。
- 裁决词：**APPROVE / CONCERNS / REJECT / NOT ASSESSED [缺失输入]**——REJECT 阻断 Phase 5；NOT ASSESSED 绝不读作 APPROVE；CONCERNS 由用户选修订或接受。
- `individual` 档的 writer 自检必须显式声明"非门禁裁决"（R16）。
- 汇总裁决：**COMPLETE / COMPLETE — consistency NOT ASSESSED ([input]) / BLOCKED — [reason]**；任何 NOT ASSESSED 必须出现在裁决行，禁止裸 COMPLETE。

## 5. 移植建议
- **可直接移植**：R1（无参即停）、R4（active set 显式宣布）、R5（先读 canon、禁止发明 canon）、R6-R8（简报不倒上下文 + 双轨草稿/定稿路径表 + 目的地被下游固定不可自选）、R11（120 字符行限、命名占位符）、R15-R16（门禁裁决处理 + 自检不是裁决）、R17（德语/芬兰语 +30% 膨胀余量）、R19-R20（工件验证 + 部分报告）、R23（用户不修的本地化问题按 string key 落账）。
- **需替换概念**：叙事 bible/tone guide → 品牌 voice 指南/内容规范；canon level → 官方事实分级（canonical / draft / deprecated）；`design/narrative/` → 内容仓目录；对白 120 字符限 → UI 文案长度约束；localization-lead → i18n/内容合规角色；ND-CONSISTENCY → 领域一致性审查门禁。
- **改写示例**：
  - "委派任何内容生成智能体之前必须先读既有的正典文档（风格指南、术语表、既有内容）；正典不存在时先向用户确认，禁止让智能体发明正典。产出写到下游技能会读取的固定目录——写到别处的工件对所有下游消费者不可见。"
  - "一致性审查门禁在每个运行档位都必须执行，任何档位都不得跳过；无人执行门禁时由单一执行者自检，但输出必须显式声明『门禁未运行，此为自检』——自检永远不是门禁裁决。审查未获得必需输入时记 NOT ASSESSED，且绝不允许被读作通过。"

## 6. 关联文档
- 上游：`/asset-spec`、`/design-review`、`/localize`、`/onboard`、`/project-stage-detect`、`/team-level` 与 `cd-narrative` 门禁（均为 `design/narrative/` 的读者）。
- 下游：`/design-review`（文档一致性校验）、`/localize extract`（字符串提取）、`/dev-story`（对白触发与叙事事件实现）。
- 引用：`.claude/docs/director-gates/nd-consistency.md`、`.claude/docs/director-gates.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`。
