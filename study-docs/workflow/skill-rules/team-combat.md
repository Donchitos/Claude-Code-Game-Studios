# team-combat — 战斗功能团队编排（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-combat [combat feature description] [--review full|lean|solo]`
- **一句话职责**：编排战斗团队（设计→架构→并行实现→集成→验证→签核六阶段）把一个战斗功能从设计文档做到实现并通过 QA 验证。
- **触发前置**：必须提供战斗功能描述（如 `melee parry system`、`ranged weapon spread`）；无参数时只输出用法提示并立即停止——不派生任何 subagent、不读任何文件。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, team.size, workflow`（`resolve_config` 解析，`--review` 覆盖 `review_mode`） | 档位影响见下方注记；无配置块默认值见 `.claude/docs/config-resolution.md` |
| 读取 | `.claude/docs/templates/game-design-document.md`、`project.yaml` 的 `engine.name`、既有系统文档（集成点识别） | Phase 1 GDD 模板；引擎专家名派生；Phase 2 架构需对照既有系统 |
| 产出 | `production/combat/[feature]-gdd-draft.md`（设计草稿）、`design/gdd/[feature].md`（最终 GDD，编排器亲自写）、`docs/architecture/[feature]-sketch.md`、`docs/architecture/[feature]-engine-notes.md`、`production/combat/[feature]-audio-events.md`、代码根与 `assets/` 下实现文件、`production/qa/test-cases/[feature]-cases.md`、`production/qa/bugs/BUG-[NNNN].md` | 每阶段点名具体路径（R10）；QA 两处路径由 `/team-qa` 固定 |
| 派生智能体 | `game-designer`（设计机制、定义公式与边缘情形）；`gameplay-programmer`（核心玩法代码；Phase 2 出架构草图）；`ai-programmer`（NPC/敌人 AI 行为，仅功能涉及 AI 时）；`technical-artist`（VFX、shader 效果、视觉反馈）；`sound-designer`（音频事件、打击音、环境战斗音频）；主引擎专家 `<engine>-specialist`（由 `engine.name` 派生：Godot→`godot-specialist`、Unity→`unity-specialist`、Unreal→`unreal-specialist`；回退 `technical-preferences.md` 的 `## Engine Specialists` Primary 行）——验证架构与实现模式符合引擎惯例；`qa-tester`（写测试用例并验证实现） | active set 由 `team.size` 决定（R4）；`studio` 档另可引入引擎子专家（由主专家 prompt 中的 `tools:` 授权） |

resolve_config 配置键及档位影响：
- `review_mode`：仅调 director-gate 深度；**本管线无 director gate**——任何档位都不派生 CD-/TD-/PR-/AD-PHASE-GATE，阶段门是管线自己的决策点，工作其上的是团队成员而非总监门禁。
- `automation`：驱动 Decision Points——`collaborative` 用户逐阶段批准；`guided` 自动推进除非阶段 BLOCKED；`autonomous` 端到端运行并以 `log_decision` 记录各阶段结果。
- `workflow`：决定 Phase 1 设计文档体量（同 `/design-system`）：`full` = `## Summary` + 全部 8 节；`standard` = Overview、Detailed Design、Edge Cases、Dependencies、Acceptance Criteria，且只要机制定义数值规则就加 Formulas（战斗机制几乎总有）；`minimal` = game brief 即设计记录、GDD 可选——仍起草上述五节并告知用户在此层级可选。
- `team.size`：决定哪些智能体激活（与 review_mode 门禁深度、workflow 文档正交）：`individual`（默认）= `gameplay-programmer` 独跑管线，仅当功能标记 AI 工作才升级派生 `ai-programmer`，其余成员经 gameplay-programmer 咨询不单独派生；`small` = 完整管线；`studio` = 完整管线 + 引擎子专家 + 对抗性审查轮（Phase 5 的 qa-tester 被告知 "your job is not to confirm this works — find how it breaks"，报告注明该轮已跑）。

## 3. 核心规则（逐条编号 R1、R2……）

**入口与配置（Phase 0）**
R1. 无参数时输出用法提示（Usage: `/team-combat [combat feature description] [--review full|lean|solo]` …）后**立即停止**——不 spawn 任何 subagent、不读任何文件。
R2. 每个阶段转换点用 `AskUserQuestion` 呈现 subagent 的提案（完整分析写进会话，决策用简短标签捕获）；`collaborative` 模式必须批准才进下一阶段；`guided` 自动推进除非阶段 BLOCKED；`autonomous` 端到端运行并 `log_decision` 记录；`automation_always_ask` 类别（`is_always_ask_category` helper）任何模式都必问。
R3. 配置按 resolve_config 结果原样使用。Active-set 作用域贯穿全管线：`individual` 下需要的非核心智能体经最近的核心智能体路由（附 informational note），不单独派生；**"phase gate" 指本管线自己列出的、以 `AskUserQuestion` 决策点结束的任何阶段**（Decision Points 转换或管线内 Gate 步骤），无论 `automation` 模式——guided/autonomous 改变的是门如何通过（自动推进 / log_decision 记录），不是它是否是门，故 bounded exception 条件 (3) 在每个模式下都成立。
R4. **Phase 1 前宣布 active set——收缩永不静默**：spawn 任何东西前用一行说明本次实际派生哪些智能体、管线点名但不派生哪些（"Active set (team.size: …)" / "Not spawned this run: … — consulted through … Raise team.size (or modes.rigor) to widen."），从本文件的 team.size 列表和自身管线名单填、不从例子填。多智能体扇出在默认档收敛成一两个智能体是**正确行为**（team.size 是前置的 rigor 控制、窄默认是 token 杠杆）——不说出来，读者无法区分正确收缩与坏掉的管线。

**委派协议（How to Delegate）**
R5. 用 `Agent` 工具 spawn 各团队成员；管线允许处并行（Phase 3 各实现智能体可同时跑）。
R6. **给智能体做简报、不倒上下文**：共享输入只读一次，把蒸馏后的简报内联传入——只传该智能体真正需要的行；已读文档绝不传路径（拿到路径的智能体会重读全文）；只为没读过且只有该智能体需要的文档传路径。
R7. **每个 agent prompt 以 return contract 结尾**："Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."——没有它，智能体会把读过的全部内容倒回本会话。
R8. **实现文件是例外**：写代码或资产的智能体先返回将创建/更改的文件清单；其 return contract 只在你问过一次且用户同意后才点名这些文件（File Write Protocol）——授权写入的是那个回答，不是 bounded exception。
R9. **每个阶段点名一个具体产出路径**（§2 表）。Phase 6 是口头状态汇报，无路径也无需。Phase 2 的两个 `docs/architecture/` 条目是**判断题不是惯例**：该目录放 ADR（`adr-NNNN-*.md`），sketch 是 ADR 前身而非 ADR，且仓库中没有任何东西读这两个文件——汇报时要说明 sketch 是记录而非后续门禁的输入。
R10. **Bounded exception（三条件同时成立，subagent 免问直写）**：(1) 路径是你在 prompt 里点名的（用户批准阶段即批准目的地）；(2) 是 `production/`、`docs/` 或 `tests/` 下的**新**工件，绝不编辑既有源码或配置；(3) 产出该工件的阶段本身被 `AskUserQuestion` 门禁。三条件之外必须问。**禁止用"每个 subagent 都问一遍"来修复**——每智能体每阶段一个 prompt 会让编排器不可用。

**Phase 1 设计**
R11. 委派 `game-designer`：从 `.claude/docs/templates/game-design-document.md` 为 `design/gdd/[feature].md` 创建/更新设计文档，含 `## Summary` 与 workflow 要求的节（`full`：机制概览、玩家幻想、详细规则、带变量定义的公式、边缘情形、依赖、带安全范围的 tuning knobs、验收标准）；草稿写到 `production/combat/[feature]-gdd-draft.md`。
R12. `design/` 在 bounded exception 之外——game-designer 只起草，**你**写最终 GDD（`/team-level`、`/team-narrative` 同款模式）：Phase 1 决策点呈现草稿并问 "May I write the design document to `design/gdd/[feature].md`?"，批准后写入；**该回答之前 `design/` 下什么都不写**。

**Phase 2 架构**
R13. 委派 `gameplay-programmer`（涉及 AI 时加 `ai-programmer`）：按节读设计文档（Grep `^#` 找标题 + Read offset/limit）；设计代码架构（类结构、接口、数据流）；识别与既有系统的集成点；产出带文件清单和接口定义的架构草图（`docs/architecture/[feature]-sketch.md`）。
R14. 再 spawn 主引擎专家验证拟议架构：类/节点/组件结构是否引擎地道（如 Godot 节点层级、Unity MonoBehaviour vs DOTS、Unreal Actor/Component）；是否有引擎原生系统应替代自研；拟用 API 在钉定引擎版本中是否弃用/变更。产出引擎架构注记（`docs/architecture/[feature]-engine-notes.md`），**Phase 3 开始前并入架构**。
R15. 未配置引擎则跳过专家 spawn，但必须在本轮输出记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``——什么都不说的跳过检查与通过了的检查无法区分。
R16. 架构门 `AskUserQuestion` 三选：`[A] Proceed — spawn implementation agents` / `[B] Revise the architecture first` / `[C] Stop here`；**仅 [A] 才 spawn 实现智能体**。guided/autonomous 下这是常规阶段转换——除非架构草图 BLOCKED 否则推进（autonomous 用 `log_decision` 记录）；该门不是 release-critical 或不可逆决策，遵循标准管线规则。

**Phase 3 实现（并行）**
R17. 并行委派：`gameplay-programmer`（核心战斗机制代码）、`ai-programmer`（AI 行为，仅当功能涉及 NPC 反应）、`technical-artist`（VFX 与 shader）、`sound-designer`（音频事件清单与混音注记 → `production/combat/[feature]-audio-events.md`）。
R18. 代码、VFX、shader 工作在 bounded exception 之外：各智能体先返回将创建/更改的文件，你为**整个集合问一次**，yes 之后才写（File Write Protocol）。

**Phase 4 集成**
R19. 把玩法代码、AI、VFX、音频接在一起；确保所有 tuning knobs 已暴露且数据驱动；验证功能与既有战斗系统协同工作。**Gate**：`AskUserQuestion` 呈现集成结果并确认后才进 Phase 5。

**Phase 5 验证**
R20. 委派 `qa-tester`：从验收标准写测试用例（`production/qa/test-cases/[feature]-cases.md`，目的地由 `/team-qa` Phase 4 固定）；测试设计中记录的全部边缘情形；验证性能影响在预算内；为发现的问题提 bug 报告（`production/qa/bugs/BUG-[NNNN].md`，由 `/team-qa` Phase 5 固定）。

**Phase 6 签核**
R21. 收集全体成员结果；报告功能状态 **COMPLETE / NEEDS WORK / BLOCKED**；列出未决问题及其负责人。

**错误恢复与文件写入协议**
R22. **先验证工件**：return contract 点了路径，就先检查路径存在再当阶段完成——**点名却不在盘上的工件是失败阶段，无论回应读起来多流畅**（智能体可能烧掉整个阶段、返回一段像样的前言却什么都没写——既非 BLOCKED 也非错误也非"无法完成"）。恢复它并点名未满足的契约；上下文通常还在。
R23. 任何智能体返回 BLOCKED、出错或无法完成：**立即上浮、不越过它阻塞的依赖推进、永远产出部分报告**；被跳过智能体的节保持具名缺口——绝不用自己的内容填充。完整流程见 `.claude/docs/error-recovery-protocol.md`。
R24. 常见阻塞：输入文件缺失（story 找不到、GDD 不存在）→ 重定向到创建它的技能；ADR 状态是 Proposed → 不实现，定了之后用 `/architecture-decision accept ADR-NNNN` 接受；范围太大 → 用 `/create-stories` 拆成两个 story；ADR 与 story 指令冲突 → 上浮冲突，不猜。
R25. File Write Protocol：草稿/草图/QA 工件（路径表中 `production/`、`docs/`、`tests/` 目的地）走 bounded exception 免问直写；**实现文件**（Phase 3 代码/VFX/shader 及任何 Phase 4 集成编辑，代码根与 `assets/` 下）在例外之外——每个实现智能体先返回文件清单（每个附一行摘要），为整个集合问一次（"May I have [agents] write these [N] files?"），yes 后才写；对既有文件的编辑**永远在清单上**，绝不因 Phase 3 前的门而被暗示。**唯一例外是设计文档**：编排器自己在 Phase 1 的 "May I write …?" 之后写 `design/gdd/[feature].md`，此外不写任何文件。

**输出与后续**
R26. 汇总报告覆盖：设计完成状态、各成员实现状态、测试结果、未决问题。裁决：**COMPLETE**（战斗功能已设计、实现并验证）；引擎验证被跳过时**绝不给光秃秃的 COMPLETE**——**COMPLETE — engine validation NOT ASSESSED ([reason])**；**NEEDS WORK**（每个阶段都跑了，但 Phase 5 留下未解决的失败或 bug，报告逐项列出及负责人）；**BLOCKED**（一个或多个阶段无法完成，或智能体被跳过；产出部分报告并列出未决项）。
R27. 后续：收 story 前对实现的战斗代码跑 `/code-review`；跑 `/balance-check` 验证战斗公式与调参值；需要 VFX/音频/性能打磨时跑 `/team-polish`。

## 4. 门禁与裁决
- 本管线**无 director gate**（任何 `review_mode` 都不派生 CD-/TD-/PR-/AD-PHASE-GATE）；阶段门是管线自身决策点：Phase 1 GDD 写入批准（R12）、Phase 2 架构门 [A]/[B]/[C]（R16）、Phase 4 集成 Gate（R19）——工作其上的是团队成员而非总监门禁。
- 裁决词：**COMPLETE / COMPLETE — engine validation NOT ASSESSED ([reason]) / NEEDS WORK / BLOCKED**；任何被跳过的检查都必须出现在裁决行，禁止裸 COMPLETE。
- `studio` 档对抗性审查：Phase 5 qa-tester 的任务是 "find how it breaks" 而非 "confirm this works"，报告注明该轮已跑。

## 5. 移植建议
- **可直接移植**：R1（无参即停）、R3-R4（active-set 作用域 + 收缩必须显式宣布）、R5-R8（简报不倒上下文 + return contract + 实现文件例外）、R9-R10（每阶段点名产出路径 + bounded exception 三条件）、R15（跳过的检查记 NOT ASSESSED）、R22-R23（点名工件不在盘上=失败阶段；部分报告、具名缺口）、R26（裁决词携带未评估项）。
- **需替换概念**：战斗功能 → 任一功能域（支付流程、数据管道、权限模块）；GDD 模板 → 领域设计文档模板；引擎专家 → 平台/框架专家（前端框架、云平台专家）；tuning knobs → 可配置参数；`/balance-check` → 领域数值校验；班底角色 → 对应领域专家组合。
- **改写示例**：
  - "编排多智能体流水线前必须先宣布 active set：一行列出本次实际派生的智能体与管线点名但不派生的智能体。收缩是正确的成本控制，但未显式宣布的收缩与坏掉的流水线在读者眼中无法区分。"
  - "子智能体返回后先验证其声明的产出路径是否在磁盘上——点名却不在盘上的工件即为失败阶段，无论其回应读起来多流畅。任何被跳过的检查必须在最终裁决中显式标注 NOT ASSESSED，禁止以光秃秃的『完成』收尾。"

## 6. 关联文档
- 上游：GDD/设计文档（Phase 1 引用模板）；`engine.name` 配置。
- 下游：`/code-review`、`/balance-check`、`/team-polish`；`/team-qa`（消费 `production/qa/test-cases/` 与 `production/qa/bugs/` 路径约定）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`、`.claude/docs/templates/game-design-document.md`、`.claude/docs/technical-preferences.md`。
