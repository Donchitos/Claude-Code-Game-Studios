# architecture-review — ADR 依赖拓扑与引擎兼容校验（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/architecture-review/SKILL.md) ｜ 阶段：Phase 3 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/architecture-review [focus: full | coverage | consistency | engine | rtm | single-gdd path/to/gdd.md]`
- **一句话职责**：构建 GDD 需求 → ADR 的追溯矩阵（Traceability Matrix），找出覆盖缺口、跨 ADR 冲突与引擎兼容问题；是 Technical Setup 与 Pre-Production 之间的质量门。
- **触发前置**：需已有一批 ADR（`docs/architecture/adr-*.md`）与 GDD；**必须在与 `/architecture-decision` 不同的全新会话中运行**（评审者须独立于撰写上下文）。model: opus。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `automation`、`workflow`（经 `hooks/yaml-helper.sh resolve_config`） | 提问节奏、评审范围 |
| 读取 | 全部 GDD（Phase 2 从每个 GDD 提取技术需求）、全部 ADR、架构文档、引擎参考与钉定版本（Phase 1，`references/1-load.md`） | 追溯与兼容校验输入 |
| 产出 | 评审报告（Phase 7，`references/7-report.md`）；追溯索引写入/更新（Phase 8，`references/8-write.md`）；`rtm` 模式额外产出 `docs/architecture/requirements-traceability.md`（完整 GDD 需求 → ADR → Story → Test 链） | 写入前须用户批准 |
| 派生智能体 | 各 Phase 可派生（步骤在 references 文件中）；可用脚本：`review-receipts.sh check/hash`、`adr-dep-graph.sh`、`registry.sh validate` | 依赖拓扑、评审收据与 TR 注册表校验 |

**配置键档位**：
- `workflow`：`full` = 跨全部 GDD 与全部 ADR 的完整追溯矩阵；`standard` = 缩小范围（仅架构文档 + 关键 ADR）；`minimal` = 不适用（无架构文档要求）。

## 3. 核心规则（逐条编号 R1、R2……）

**参数模式**
R1. 必须按参数确定评审焦点：无参数/`full` = 全阶段完整评审；`coverage` = 仅追溯（哪些 GDD 需求无 ADR 覆盖）；`consistency` = 仅跨 ADR 冲突检测；`engine` = 仅引擎兼容审计；`single-gdd [path]` = 单个 GDD 的架构覆盖评审；`rtm` = 需求追溯矩阵——在标准矩阵上扩展 story 文件路径与测试文件路径，产出 `docs/architecture/requirements-traceability.md` 的完整 GDD 需求 → ADR → Story → Test 链，用于 Production 阶段（story 与测试已存在时）。（出处：Argument modes）

**阶段执行**
R2. Phase 1–9（全量加载 / 逐 GDD 提取技术需求 / 构建追溯矩阵 / 跨 ADR 冲突检测 / 引擎兼容交叉核对 / 架构文档覆盖 / 输出评审报告 / 写入并更新追溯索引 / 移交）的步骤各在 `references/1-load.md` 至 `references/9-handoff.md` 中；进入各阶段时必须立即读取对应文件并遵循之；会话压缩或恢复后处于该阶段必须重读。（出处：Phases 1–9）
R3. 每次 `AskUserQuestion` 必须遵循 `.claude/docs/automation-modes.md`（collaborative 恒提问 · guided 仅重大事项 · autonomous 记录后继续；`automation_always_ask` 类别恒提问）。（出处：automation 段）

**错误恢复协议（Error Recovery Protocol）**
R4. 派生智能体返回后必须先核实交付物：返回契约若指名了路径，必须先确认该路径在磁盘上存在，再视该阶段为完成——**指名的交付物不在磁盘上就是失败阶段，无论回复读起来多流畅**。智能体可能耗完整个阶段、返回貌似可信的引言却什么都没写（这既非 BLOCKED 也非报错也非"未完成"，下述触发器不会命中）；此时必须点名未满足的契约让它续作，上下文通常还在。（出处：Error Recovery Protocol）
R5. 任何派生智能体返回 BLOCKED、报错或未完成时：必须立即浮出、禁止越过它所阻塞的依赖继续，且**总是产出部分报告**（本技能的重试范围 = 更少 GDD / 单系统）。完整流程见 `.claude/docs/error-recovery-protocol.md`。（出处：Error Recovery Protocol）

**协作协议（collaborative 模式，默认；guided/autonomous 见 `.claude/docs/automation-modes.md`）**
R6. 必须静默读取，禁止叙述每次文件读；任何写入批准前必须先展示完整追溯矩阵，让用户看到状态。（出处：Collaborative Protocol 第 1–2 条）
R7. 禁止猜测：需求有歧义时必须询问，如"[X] 是技术需求还是设计偏好？"。（出处：Collaborative Protocol 第 3 条）
R8. 批准前必须先展示将写入的内容（报告、ADR 更新节、systems-index 行）内联在会话中；禁止请求写入用户尚未看过的内容。（出处：Collaborative Protocol 第 4 条）
R9. 写入批准必须用 `AskUserQuestion` 结构化工具（带标签选项 [A]/[B]/[C]："现在写 / 先看完整草稿 / 暂不写"），纯文本"可以吗？"不足够；多文件变更集必须列全每个文件及其改动后一次性分组询问，禁止逐文件单独纯文本提问。（出处：Collaborative Protocol 第 5 条）
R10. 裁决为建议性（non-blocking）：用户可自行决定是否带着 CONCERNS 甚至 FAIL 的发现继续。（出处：Collaborative Protocol 第 6 条）

## 4. 门禁与裁决
- 本技能即 Technical Setup → Pre-Production 的质量门；裁决词四档（见 description）：**PASS / CONCERNS / NOT ASSESSED / FAIL**。
- 裁决不阻断：报告与风险呈现给用户，继续与否由用户决定（R10）。
- 派生智能体失败的处理遵循 R4–R5（核实交付物在盘、部分报告兜底）。

## 5. 移植建议
- **可直接移植**：R1 的多维焦点模式（覆盖/一致性/兼容/单文档/全链追溯）、R4–R5（"指名交付物不在盘 = 失败阶段"与部分报告兜底——对任何派生智能体工作流都极有价值）、R6–R10（展示矩阵再写、歧义必问、结构化写批准、裁决建议性）。
- **需替换概念**：GDD 技术需求 → 需求文档中的可实现条目；ADR → 技术决策记录；引擎兼容 → 框架/依赖版本兼容；TR-ID → 需求追溯编号；Story/Test → 任务/测试用例路径；Pre-Production 门禁 → 项目立项/开工评审。
- **改写示例**：
  - "派生智能体返回后必须先核实其指名的交付物已落盘，再视阶段完成——不在盘即失败，无论回复多流畅；随后点名未满足的契约要求续作。"
  - "评审裁决是建议性的：即使 FAIL，也只能记录风险、呈现发现，由用户决定是否继续。"

## 6. 关联文档
- 上游：`/architecture-decision`（产出 ADR；必须分会话运行）、`/create-architecture`（产出架构文档与必需 ADR 清单）
- 下游：Pre-Production 门禁（`/gate-check pre-production`）；`rtm` 模式供 Production 阶段使用
- 规范文档：`.claude/docs/error-recovery-protocol.md`、`automation-modes.md`、`workflow-modes.md`
- 脚本：`.claude/scripts/review-receipts.sh`、`adr-dep-graph.sh`、`registry.sh`
