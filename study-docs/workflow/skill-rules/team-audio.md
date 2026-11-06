# team-audio — 音频团队编排（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-audio/SKILL.md) ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-audio [feature or area to design audio for] [--review full|lean|solo]`
- **一句话职责**：编排音频团队（音频方向→音效设计+音频无障碍并行→技术实现并行→代码集成→汇编音频设计文档）为一个功能或区域建立从方向到实现的音频设计。
- **触发前置**：必须提供功能或区域（如 `combat`、`main menu`、`forest biome`、`boss encounter`）；无参数时直接输出用法指引并退出——不派生智能体，此处不用 `AskUserQuestion`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, team.size`（`resolve_config`；`--review` 覆盖 `review_mode`） | 档位影响见下方注记 |
| 读取 | `design/gdd/` 下与该功能相关的设计文档（按节读：Grep `^#` + Read offset/limit）；**声音 bible**：`design/audio/sound-bible.md`（旧版本放在 `design/gdd/sound-bible.md`——存在则读它并建议迁移）；`assets/audio/` 既有音频资产清单；该区域既有声音设计文档 | 声音 bible 缺失时的缺口处理见 R6 |
| 产出 | 草稿（subagent 写，`production/audio/[feature]/` 下）：`direction.md`、`sfx-spec.md`、`accessibility.md`、`integration-plan.md`、`engine-notes.md`；代码根与引擎测试根下实现文件（Step 4）；定稿：`design/audio/audio-[feature].md`（编排器汇编后亲写） | 草稿为工作记录；`[feature]` = 参数 slug；`design/audio/` 不存在时写文件即创建它 |
| 派生智能体 | `audio-director`（声音身份、情绪基调、音频色板）；`sound-designer`（SFX 规格、音频事件、混音组）；`accessibility-specialist`（关键音频的视觉替代与字幕、听觉敏感）；`technical-artist`（音频中间件、总线结构、内存预算）；主引擎专家 `<engine>-specialist`（由 `engine.name` 派生：Godot→`godot-specialist`、Unity→`unity-specialist`、Unreal→`unreal-specialist`；回退 `technical-preferences.md` 的 Primary 行）——验证音频集成模式符合引擎惯例；`gameplay-programmer`（音频管理器、玩法触发器、自适应音乐） | active set 由 `team.size` 决定（R4） |

resolve_config 配置键及档位影响：
- `review_mode`：本管线无 director gate（任何档位不派生 CD-/TD-/PR-/AD-PHASE-GATE）；阶段门是管线自身决策点。
- `automation`：`collaborative` 逐步批准；`guided` 自动推进除非 BLOCKED；`autonomous` 端到端并 `log_decision`；`automation_always_ask` 类别任何模式必问。
- `team.size`：`individual`（默认）= 仅 `sound-designer`，其余经其咨询；`small` = 加 `audio-director` + `technical-artist` + `gameplay-programmer`；`studio` = 再加 `accessibility-specialist` + 主引擎专家（完整管线照文档跑）。

## 3. 核心规则（逐条编号 R1、R2……）

**入口与配置（Phase 0）**
R1. 无参数时直接输出用法指引并退出——不派生智能体。
R2. 每个步骤转换点用 `AskUserQuestion` 呈现 subagent 提案（完整分析写进会话、简短标签捕获决策）；三档 automation 行为同 §2 注记。Active-set 作用域贯穿全管线：非激活智能体经最近核心智能体路由（附 informational note）；"phase gate" 指本管线列出的、以 `AskUserQuestion` 结束的任何阶段，无论 automation 模式。
R3. **Step 1 前宣布 active set——收缩永不静默**：spawn 前一行说明实际派生与点名但不派生的智能体；从 team.size 列表和自身管线名单填、不从例子填。默认档收敛成单智能体是正确行为——不说明则无法与坏管线区分。

**步骤 0 读取参数与收集语境**
R4. 读取目标功能/区域参数；收集语境：`design/gdd/` 相关设计文档按节读；读 `assets/audio/` 既有音频资产清单与该区域既有声音设计文档。
R5. 声音 bible 读取规则：`design/audio/sound-bible.md` 存在则读；只有旧位置 `design/gdd/sound-bible.md` 存在（早期版本放那里）则读它并**建议迁移到 `design/audio/`**——在 `design/gdd/` 里 GDD 检查会把每个文件都算作系统 GDD；两处都没有时**用一行说明**："No sound bible at `design/audio/sound-bible.md`; audio direction starts from the GDDs alone"——让缺口在输出里可见，并把缺口**向后携带**：在 audio-director 的 Step 1 简报里说明，并在 Next Steps 建议创建声音 bible。

**委派协议（How to Delegate）**
R6. **做简报、不倒上下文**：共享输入只读一次、蒸馏简报内联传入；已读文档绝不传路径；只为没读过且只有该智能体需要的文档传路径。
R7. **每个 agent prompt 以 return contract 结尾**（写 `[path]`、只返回路径 + ≤5 条决策要点 + BLOCKED/CONCERNS 各一行、不重述所读文档）。**实现文件是例外**：写代码或资产的智能体先返回将创建/更改的文件清单；其 return contract 只在你问过一次且用户同意后才点名（File Write Protocol）。
R8. **路径表**：工作工件入 `production/audio/[feature]/`（`[feature]` = 参数 slug——小写、空格转连字符，与 "Save to" 步骤同一 slug），每智能体一个文件、并行步骤不共享（§2 表）；Step 4 gameplay-programmer 写代码根与引擎测试根——单次实现询问清单所列文件，**在 bounded exception 之外**。这些是工作草稿；持久记录是你汇编的音频设计文档。
R9. **Bounded exception（三条件同时成立免问直写）**：(1) 路径是你点名的；(2) `production/`、`docs/`、`tests/` 下新工件；(3) 产出阶段被 `AskUserQuestion` 门禁。之外必须问；禁止用"每个 subagent 都问一遍"修复。

**Step 1 音频方向（audio-director）**
R10. 委派 `audio-director`：定义本功能/区域的**声音身份**；情绪基调与音频色板；音乐方向（自适应层、stems、转场）；音频优先级与混音目标；自适应音频规则（战斗强度、探索、张力）。产出 `direction.md`。

**Step 2 音效设计与音频无障碍（两路并行）**
R11. 委派 `sound-designer`：为**每个**音频事件写详细 SFX 规格；定义声音分类（ambient、UI、gameplay、music、dialogue）；逐声音参数（音量范围、音高变化、衰减）；带触发条件的音频事件清单；混音组与 ducking 规则。产出 `sfx-spec.md`。
R12. 并行委派 `accessibility-specialist`：识别承载关键玩法信息的音频事件（受击、敌人临近、目标完成）——为听障玩家要求视觉替代；字幕需求（哪些事件要 captions、文本格式、屏上时长）；**任何玩法状态都不得仅靠音频传达**（全部必须有视觉替代）；审查事件清单中可能伤及听觉敏感玩家的高频警报与突发巨响。产出并入音频事件规格的无障碍需求清单（`accessibility.md`）。
R13. **BLOCKING 规则**：承载关键玩法信息的音频事件若既无视觉提示也无字幕，在报告中标 **BLOCKING**、不是建议项。**用户解决或在该决策点显式接受之前，Step 3 不得开始**——决策点提供修复选项（视觉提示、字幕或触觉替代）与停止；被接受的缺口列入汇总的 open questions。

**Step 3 技术实现（两路并行）**
R14. 委派 `technical-artist`：音频中间件集成设计（Wwise/FMOD/原生）；音频总线结构与路由；逐平台音频资产内存预算；流式 vs 预加载资产策略；音频驱动的视觉效果。产出 `integration-plan.md`。
R15. 并行 spawn 主引擎专家验证集成方案：拟议中间件集成是否引擎地道（如 Godot 内建 AudioStreamPlayer vs FMOD、Unity Audio Mixer vs Wwise、Unreal MetaSounds vs FMOD）；应采用的引擎音频节点/组件模式；钉定引擎版本中已知的音频系统变更。产出引擎音频集成注记（`engine-notes.md`），**与 technical-artist 的计划合并**。未配置引擎则跳过 spawn，但必须记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``——什么都不说的跳过检查与通过了的检查无法区分。
R16. Step 3 各 Agent 调用同时发出后再等结果（并行）。

**Step 4 代码集成（gameplay-programmer）**
R17. 委派 `gameplay-programmer`：实现音频管理器系统或审查既有；把音频事件接到玩法触发器；实现自适应音乐系统（如有规格）；搭建音频遮挡/混响区；为音频事件触发器写单元测试。实现文件走 File Write Protocol（先返回清单、问一次、yes 后写）。

**汇编、落盘与汇报**
R18. 汇编结合全部团队产出的音频设计文档；保存到 `design/audio/audio-[feature].md`——**但先问**：`design/` 不在 bounded exception 覆盖的三个目录（`production/`、`docs/`、`tests/`）之内，被交此路径的 subagent 必须先问。**禁止靠扩大例外来解决**，而是沿用 `team-level` 模式：你已持有每个 subagent 的输出，自己汇编并 `AskUserQuestion` 直接问 "May I write the audio design to `design/audio/audio-[feature].md`?"，批准后写入；subagent 工作工件留在例外够得着的 `production/`。`design/audio/` 不存在时写文件即创建该目录。
R19. 汇总输出：音频事件数、估算资产数、实现任务、团队成员之间的 open questions。
R20. 裁决：**COMPLETE**——音频设计文档已产出且团队管线完成；引擎验证被跳过（无引擎）时**绝不裸 COMPLETE**——**COMPLETE — engine validation NOT ASSESSED ([reason])**（引擎专家从未审查集成计划）；依赖未解决（如关键无障碍缺口或缺失 GDD 且用户未处理）→ **BLOCKED — [reason]**。

**错误恢复与文件写入协议**
R21. **先验证工件**：return contract 点了路径就先查路径存在——**点名却不在盘上的工件是失败阶段，无论回应读起来多流畅**（智能体可能烧掉整个阶段返回像样的前言却什么都没写）；恢复它并点名未满足的契约，上下文通常还在。
R22. 任何智能体 BLOCKED/出错/无法完成：立即上浮、不越过被阻塞的依赖、**永远产出部分报告**；被跳过智能体的节保持具名缺口——绝不用自己的内容填充。完整流程见 `.claude/docs/error-recovery-protocol.md`。常见阻塞：输入文件缺失→重定向到创建它的技能；ADR Proposed→不实现、定后 `/architecture-decision accept ADR-NNNN`；范围太大→`/create-stories` 拆分；ADR 与 story 冲突→上浮冲突，不猜。
R23. File Write Protocol：每智能体工件（SFX 规格、集成计划等）由产出它的 subagent 写，走 bounded exception 免问直写；**实现文件**（gameplay-programmer 的音频集成代码、代码根或 `assets/` 下任何东西）在例外之外——智能体先返回将创建/更改的文件、你为集合问一次、yes 后才写；**唯一例外是最终汇编的音频设计文档**——编排器已持有每份输入，自己汇编并在自己的 "May I write …?" 之后写 `design/audio/audio-[feature].md`。
R24. 后续：实现开始前与 audio-director 复核音频设计文档；设计批准后用 `/dev-story` 实现音频管理器与事件系统；音频资产创建后跑 `/asset-audit` 核验命名与格式合规；**若无声音 bible，下一次音频 pass 前先建一个**：请 `audio-director` 智能体从 `.claude/docs/templates/sound-bible.md` 起草 `design/audio/sound-bible.md`、以本轮 Step 1 方向为起点（它在 `design/` 下写入前会先问）。

## 4. 门禁与裁决
- 本管线无 director gate；自身决策点：Step 2 决策点（关键音频无障碍缺口为 **BLOCKING**，用户解决或显式接受前 Step 3 不开始——R13）、定稿写入批准（R18）。
- 裁决词：**COMPLETE / COMPLETE — engine validation NOT ASSESSED ([reason]) / BLOCKED — [reason]**；任何被跳过的检查必须出现在裁决行，禁止裸 COMPLETE。
- 无障碍缺口语义：游戏关键音频事件缺视觉提示或字幕 = BLOCKING（不是 advisory）；被用户接受的缺口必须列入 open questions。

## 5. 移植建议
- **可直接移植**：R1-R3（无参即停 + active set 显式宣布）、R5（规范文档缺失必须一行可见并向后携带进简报与后续建议）、R6-R9（简报不倒上下文 + return contract + bounded exception 三条件）、R13（关键信息通道的无障碍缺口是 BLOCKING 不是建议）、R15（跳过的引擎检查记 NOT ASSESSED）、R18（目标目录在写例外之外时靠先问解决、禁止扩大例外）、R21-R22（工件验证 + 部分报告）、R20（裁决词携带未评估项）。
- **需替换概念**：音频方向/声音身份 → 产品的感官或风格方向（视觉语言、文案语气）；声音 bible → 领域规范文档（design tokens、风格指南）；音频事件清单 → 事件/信号清单；中间件（Wwise/FMOD）→ 平台基础设施（消息队列、CDN）；混音组与 ducking → 资源调度与降级策略；引擎专家 → 平台专家；视觉替代/字幕 → 关键信息的冗余通道（听觉↔视觉）。
- **改写示例**：
  - "承载关键操作信息的信号若只有单一感官/单一通道传达（无冗余替代），一律标 BLOCKING 而非建议——用户解决或显式接受之前，后续阶段不得开始；被接受的缺口列入报告的未决问题。"
  - "领域规范文档缺失时必须用一行明说（『无 X 规范，方向仅从现有规格出发』），把缺口带进负责方向的智能体简报并在收尾建议补建——静默的缺口与不存在的缺口在读者眼中无法区分。"

## 6. 关联文档
- 上游：`design/gdd/` 系统设计文档、`design/audio/sound-bible.md`（或旧位置 `design/gdd/sound-bible.md`）。
- 下游：`/dev-story`（音频管理器与事件系统实现）、`/asset-audit`（资产命名与格式合规）、`/team-polish`。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`、`.claude/docs/technical-preferences.md`、`.claude/docs/templates/sound-bible.md`。
