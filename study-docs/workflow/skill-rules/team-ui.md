# team-ui — UI 功能团队编排（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-ui/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-ui [UI feature description] [--review full|lean|solo]`
- **一句话职责**：编排 UI 团队走完整 UX 管线（上下文收集→UX 规格→UX 评审→视觉设计→实现→三路并行评审→打磨），内部调用 `/ux-design` 与 `/ux-review`。
- **触发前置**：必须提供屏幕或 UI 功能描述（如 `inventory screen`、`main menu`、`combat HUD`）；无参数时直接输出用法指引并退出——不派生智能体、不读任何设计文件，此处不用 `AskUserQuestion`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, team.size`（`resolve_config`；`--review` 覆盖 `review_mode`） | 档位影响见下方注记 |
| 读取 | `design/gdd/game-concept.md`（平台与受众；`rigor: minimal` 时为 `design/game-brief.md`——"Who it's for" 行给受众、不提平台）、`design/player-journey.md`、相关 GDD 的 UI Requirements 节、`design/ux/interaction-patterns.md`、`design/accessibility-requirements.md`（已承诺无障碍档位）、`design/art/art-bible.md`、`design/ux/hud.md`（视觉预算）、`project.yaml` 的 `specialists.ui` 与 `engine.name` | Phase 1a 五输入逐一报告存在/ABSENT；GDD 按节读（Grep `^#` + offset/limit） |
| 读取 | 模板：`ux-spec.md`、`hud-design.md`、`interaction-pattern-library.md`、`accessibility-requirements.md` | Phase 1b 规格与档位模板 |
| 产出 | `design/ux/[feature-name].md`（UX 规格）、`production/ui/[feature-name]/visual-design.md`、`production/ui/[feature-name]/engine-notes.md`、代码根下实现文件、`production/ui/[feature-name]/review-[agent].md`（三路评审各一份）、`design/ux/interaction-patterns.md`（新模式入库） | 每智能体一个文件，保证并行 Phase 4 评审不共享文件；`design/` 下两类写入在 bounded exception 之外 |
| 派生智能体 | `ux-designer`（用户流、线框、无障碍、输入处理）；`ui-programmer`（UI 框架、屏幕、控件、数据绑定、实现）；`art-director`（视觉风格、布局打磨、art bible 一致性）；引擎 UI 专家（`specialists.ui`；缺失时回退 `technical-preferences.md` 的 UI Specialist 行——如 `unity-ui-specialist`、`ue-umg-specialist`、`godot-specialist`）；`accessibility-specialist`（Phase 4 无障碍合规审计） | active set 由 `team.size` 决定（R4） |

resolve_config 配置键及档位影响：
- `review_mode`：本管线无 director gate（任何档位不派生 CD-/TD-/PR-/AD-PHASE-GATE）；阶段门是管线自身决策点。
- `automation`：`collaborative` 逐阶段批准；`guided` 自动推进除非 BLOCKED；`autonomous` 端到端并 `log_decision`；`automation_always_ask` 类别任何模式必问。
- `team.size`：`individual`（默认）= `ui-programmer` + `ux-designer`，其余经这两人咨询；`small` = 加 `accessibility-specialist` + `art-director`；`studio` = 再加引擎 UI 专家 + 对抗性审查轮（Phase 4 评审者被告知 "your job is not to confirm this matches the spec — find where it fails it"，报告注明该轮已跑）。
- **`specialists.ui: null` 表示 UNSET**：按缺失处理并跳过引擎 UI 专家，**绝不把 `null` 当智能体名 spawn**；v1.0 迁移只要任一成员被设置就会写整个 `specialists` 块，故 `null` 常见——且配置读取器会把它返回成非空字符串 `"null"`。

## 3. 核心规则（逐条编号 R1、R2……）

**入口与配置（Phase 0）**
R1. 无参数时直接输出用法指引并退出——不派生智能体、不读设计文件。
R2. 阶段转换点用 `AskUserQuestion` 呈现提案（完整分析写进会话、简短标签捕获决策）；三档 automation 行为同上；active-set 作用域贯穿全管线：非激活智能体经最近核心智能体路由，"phase gate" 指本管线列出的、以 `AskUserQuestion` 结束的任何阶段，无论 automation 模式。
R3. **Step 1 前宣布 active set——收缩永不静默**：spawn 前一行说明实际派生与点名但不派生的智能体；从 team.size 列表和自身管线名单填、不从例子填。默认档收敛成一两个智能体是正确行为，不说明则无法与坏管线区分。

**委派协议（How to Delegate）**
R4. **做简报、不倒上下文**：共享输入只读一次，蒸馏简报内联传入；已读文档绝不传路径；只为没读过且只有该智能体需要的文档传路径。
R5. **每个 agent prompt 以 return contract 结尾**（写 `[path]`、只返回路径 + ≤5 条决策要点 + BLOCKED/CONCERNS 各一行、不重述所读文档）。**实现文件是例外**：写代码的智能体先返回将创建/更改的文件清单，return contract 只在你问过一次且用户同意后才点名（File Write Protocol）。
R6. **路径表**：工作工件入 `production/ui/[feature-name]/`（slug 与 Phase 1b 的 `design/ux/[feature-name].md` 一致）；Phase 2 art-director→`visual-design.md`；Phase 3 引擎 UI 专家→`engine-notes.md`；Phase 3 ui-programmer→代码根（单次实现询问清单所列文件，例外之外）；Phase 4 三路评审→`review-[agent].md` 各一份。UX 规格（Phase 1b）与 pattern library 更新在 `design/` 下、bounded exception 之外：由 `/ux-design` 或该智能体先问再写。
R7. **Bounded exception（三条件同时成立免问直写）**：(1) 路径是你点名的；(2) `production/`、`docs/`、`tests/` 下新工件；(3) 产出阶段被 `AskUserQuestion` 门禁。之外必须问；禁止用"每个 subagent 都问一遍"修复。

**Phase 1a 上下文收集**
R8. 按节读五项输入（Grep `^#` 找标题 + Read offset/limit）：game-concept/brief、`player-journey.md`（玩家到达此屏时的状态与语境）、相关 GDD UI Requirements 节、`interaction-patterns.md`（复用既有模式、不重造）、`accessibility-requirements.md`（已承诺档位：Basic / Standard / Comprehensive / Exemplary）。**设计任何东西之前逐一报告每个文档 present 或 ABSENT。**
R9. **`design/accessibility-requirements.md` 是绝不允许静默缺席的一项**：Phase 3 按它实现、Phase 4 按它设门。文件缺失即无档位，门禁无判据、会在什么都不查的情况下通过——用缺席标准做成的门禁等同永不为假的断言。缺失时：在此说明并向后携带——**Phase 4 必须报告 `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)` 且不得报告无障碍门禁已通过**；ux-designer 显式声明按哪个假设档位设计（让后来者看出是假设而非承诺）；建议跑 `/ux-design accessibility` 建立档位。
R10. concept 文档（game-concept 与 game-brief 均无）、`player-journey.md` 或 `design/ux/hud.md` 缺席**不阻断**，但必须在传给 ux-designer 的简报中点名每个缺失项，让其在知道缺什么语境的前提下设计，而非自行推断。
R11. `design/ux/interaction-patterns.md` 不存在时**立即上浮**："interaction-patterns.md does not exist — no existing patterns to reuse."，`AskUserQuestion` 二选：(a) 先跑 `/ux-design patterns` 建立模式库再继续；(b) 无模式库继续——ui-programmer 把所有模式视为新创并在完成时逐个加入新的 `design/ux/interaction-patterns.md`。**禁止从功能名或 GDD 单独发明或假设模式**；选 (b) 则在 Phase 3 显式指示 ui-programmer；最终汇总报告注明模式库状态（created / absent / updated）。

**Phase 1b UX 规格撰写**
R12. 调用 `/ux-design [feature name]` 或直接委派 ux-designer 产出 `design/ux/[feature-name].md`（按 `ux-spec.md` 模板、填全全部必需节）。HUD 设计改用 `hud-design.md` 模板（即 `/ux-design hud`）；interaction pattern library 在项目启动时跑一次 `/ux-design patterns`、之后引入新模式即更新。

**Phase 1c UX 评审**
R13. 规格完成后调用 `/ux-review design/ux/[feature-name].md`。**Gate：裁决不是 APPROVED 不得进 Phase 2。** NEEDS REVISION → ux-designer 在**同一份规格**里修复被标记的问题——规格保留并修订、绝不丢弃——然后重跑评审；用户可显式接受 NEEDS REVISION 风险继续，但必须是自觉决策：先用 `AskUserQuestion` 呈现具体 concerns 再问是否继续。
R14. **NOT ASSESSED 同样阻断、同样可被用户覆盖**；其修复是**输入而非修订**：呈现 `/ux-review` 无法评估的维度及各自缺失的输入（如未承诺档位 → `/ux-design accessibility`）——缺输入重跑评审只会得到同一裁决，故先提议产出输入。
R15. 用户越过 NEEDS REVISION 或 NOT ASSESSED 继续时，最终报告记录该覆盖：裁决、留下的 concerns 或未评估维度、以及用户选择继续这一事实。

**Phase 2 视觉设计**
R16. 委派 `art-director`：审阅**完整** UX 规格（流程、线框、交互模式、无障碍注记——不只是线框图）；按 art bible 施加视觉处理（色彩、字体、间距、动画风格）；验证视觉设计保住无障碍合规（核对色彩对比度；**颜色绝不能是状态的唯一指示**——形状、文字或图标必须强化）；列出美术管线需要的全部资产（指定尺寸的图标、背景纹理、字体、装饰元素——精确尺寸与格式要求）；与已实现 UI 屏幕保持一致。产出带风格注记与资产清单的视觉设计规格（`visual-design.md`）。

**Phase 3 实现**
R17. 实现前先 spawn 引擎 UI 专家（`specialists.ui`，缺失回退 UI Specialist 行）审 UX 规格与视觉设计规格：本屏该用哪个引擎 UI 框架（Unity UI Toolkit vs UGUI、Godot Control nodes vs CanvasLayer、Unreal UMG vs CommonUI）；拟议布局/交互模式的引擎坑；推荐的控件/节点结构。产出引擎实现注记，**在 ui-programmer 动手前**交接。未配置引擎则跳过并记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。
R18. 委派 `ui-programmer`：按 UX 规格与视觉设计规格实现；**用 `design/ux/interaction-patterns.md` 里的既有模式、不重造**——某模式接近合用需改动时记下偏差并交 ux-designer 审；**UI 永不拥有或修改游戏状态**——只做显示、所有玩家操作以事件发出；全部文本走本地化系统、**无硬编码玩家可见字符串**；同时支持键盘/鼠标与手柄两种输入；按已承诺档位实现无障碍特性；接好对游戏状态的数据绑定；实现中产生新交互模式时，**在标记实现完成前**加入 `design/ux/interaction-patterns.md`。

**Phase 4 评审（并行）**
R19. 三路并行，**全部回报后才进 Phase 5**：`ux-designer`（实现符合线框与交互规格；测键盘-only 与手柄-only 导航；无障碍特性功能正常）；`art-director`（与 art bible 视觉一致；在最低与最高支持分辨率下检查）；`accessibility-specialist`（对照 `design/accessibility-requirements.md` 已承诺档位核验合规，**违规即标 blocker**；该文件缺席即无判据——报告 `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)` 且**不得报告门禁通过**；携带 Phase 1a 记录的假设档位并直说那是假设）。各评审写 `review-[agent].md`。

**Phase 5 打磨**
R20. 处理全部评审反馈；验证动画可跳过且尊重玩家的动态减弱偏好；确认 UI 声音经音频事件系统触发（**无直接音频调用**）；在全部支持分辨率与宽高比下测试；核验 `design/ux/interaction-patterns.md` 已更新（本功能引入的新模式都已入库）；确认所有 HUD 元素遵守 `design/ux/hud.md` 定义的视觉预算（元素数、屏幕区域分配、最大不透明度值）。

**错误恢复与文件写入协议**
R21. **先验证工件**：return contract 点了路径就先查在不在盘上——**点名却不在盘上的工件是失败阶段，无论回应读起来多流畅**；恢复它并点名未满足的契约。
R22. 任何智能体 BLOCKED/出错/无法完成：立即上浮、不越过被阻塞依赖、**永远产出部分报告**；被跳过智能体的节保持具名缺口。常见阻塞：输入缺失→重定向到创建技能；ADR Proposed→不实现、定后 `/architecture-decision accept ADR-NNNN`；范围太大→`/create-stories` 拆分；ADR 与 story 冲突→上浮不猜。
R23. File Write Protocol：经 `Agent` spawn 的 subagent 走 bounded exception；**实现文件**（ui-programmer 代码根下的代码）在例外之外——先返回文件清单、为集合问一次、yes 后才写。**子技能（`/ux-design`）不是 subagent、例外够不着它们**——它们遵循常规 Collaboration Protocol、写前先问。**本编排器不直接写任何文件。**

**输出与后续**
R24. 汇总报告覆盖：UX 规格状态、UX 评审裁决、视觉设计状态、实现状态、无障碍合规、输入方式支持、模式库更新状态、未决问题。裁决：**COMPLETE**；无障碍门禁（无承诺档位）或引擎验证（无引擎）NOT ASSESSED 时**绝不裸 COMPLETE**——**COMPLETE — [accessibility | engine validation] NOT ASSESSED ([reason])**；**BLOCKED**——管线中止，停下前上浮阻塞项及其所在阶段。
R25. 快速索引：`/ux-design` 从零写新 UX 规格；`/ux-review` 实现前校验完成的规格；`/team-ui` 全管线（内部调用前两者）；`/quick-design` 不需要全新规格的小 UI 改动。后续：规格未批则跑 `/ux-review`；收 story 前对 UI 实现跑 `/code-review`；需要视觉/音频打磨跑 `/team-polish`。

## 4. 门禁与裁决
- 本管线无 director gate；自身门禁：Phase 1c **UX 评审门**（裁决非 APPROVED 不进 Phase 2，NEEDS REVISION 修同一份规格、NOT ASSESSED 补输入；用户覆盖须自觉决策并落账 R15）、Phase 4 **无障碍门**（对照已承诺档位、违规即 blocker、无档位即 NOT ASSESSED 且不得记通过）。
- 裁决词：汇总裁 **COMPLETE / COMPLETE — [accessibility | engine validation] NOT ASSESSED ([reason]) / BLOCKED**；UX 评审裁决 APPROVED / NEEDS REVISION / NOT ASSESSED；任何被跳过的检查必须出现在裁决行，禁止裸 COMPLETE。

## 5. 移植建议
- **可直接移植**：R1-R3（无参即停 + active set 显式宣布）、R4-R7（简报不倒上下文 + return contract + bounded exception 三条件）、R8-R9（输入逐一报告存在性；缺席标准不得静默通过门禁——"用缺席标准做成的门禁等同永不为假的断言"）、R11（禁止无模式库时发明模式）、R13-R15（同一份规格保留修订、NOT ASSESSED 补输入而非重跑、用户覆盖落账）、R18（UI 只显示不发令、文本全走本地化、双输入支持）、R19（三路评审全部回报）、R23（子技能不受 subagent 例外覆盖）、R24（裁决词携带未评估项）。
- **需替换概念**：GDD/UX 规格 → 产品需求文档/界面规格；art bible → 设计系统/品牌规范；交互模式库 → 组件模式库；无障碍档位（Basic/Standard/Comprehensive/Exemplary）→ 项目自定的合规等级（如 WCAG 级别）；引擎 UI 专家 → 平台/框架专家（Web 前端框架、移动端专家）；HUD 视觉预算 → 界面信息密度预算。
- **改写示例**：
  - "实现阶段所对照、评审阶段所设门的每项标准都必须有落盘的承诺文档；该文档缺失时评审必须记 NOT ASSESSED 且禁止报告门禁通过——用缺席标准做成的门禁会在什么都不查的情况下通过，等同永不为假的断言。"
  - "UI 层永不拥有或修改业务状态——只做展示，所有用户操作以事件发出；全部玩家可见文本走本地化系统，禁止硬编码字符串。已定义的交互模式必须复用，需偏离时记录偏差并交设计者审查。"

## 6. 关联文档
- 上游：`/ux-design`（规格与模式库）、`/ux-review`（Phase 1c 评审门）、`design/accessibility-requirements.md`（承诺档位）。
- 下游：`/code-review`（UI 实现）、`/team-polish`（视觉/音频打磨）、`/quick-design`（小改动）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`、`.claude/docs/technical-preferences.md`、模板 `ux-spec.md` / `hud-design.md` / `interaction-pattern-library.md` / `accessibility-requirements.md`。
