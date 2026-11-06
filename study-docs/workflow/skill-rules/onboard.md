# onboard — 新成员入职文档（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/onboard/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/onboard [role|area]`
- **一句话职责**：为新贡献者或新智能体生成按角色定制的入职文档——项目状态、约定、该角色相关的优先事项。
- **触发前置**：`CLAUDE.md` 与 `.claude/agents/` 存在（随框架分发，无技能创建它们；缺任一 → 报告为安装缺失）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`automation`（resolve `modes.automation`，`project.local.yaml` → `project.yaml` → 默认 `collaborative`） | 每次提问与每次文件写遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录并继续；`automation_always_ask` 类别恒问） |
| 读取 | `CLAUDE.md`（项目概览与标准）；`.claude/agents/` 中该角色的 agent 定义（指定角色时）；按角色扫描——程序员：代码根（按 `.claude/docs/code-root-resolution.md` 解析）；设计师：`design/`；叙事：`design/narrative/`；QA：`tests/`（`/test-setup` 创建）；制作：`production/`（当前冲刺与里程碑）；无角色：`design/`、`docs/architecture/`、`production/` 顶层 + 代码根 + `production/session-state/active.md`（存在时）；git log（可得时，看近期动量） | 快技能（haiku 模型） |
| 产出 | `production/onboarding/onboard-[role]-[date].md`（用户同意后写，目录不存在则创建） | 结构化入职文档 |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则
R1. **输入不足先检查，再谈产出**：列出本技能读的全部输入（数据文件、既有报告、profiler 输出、测试结果、registry、源码），逐项记 `FOUND`/`ABSENT`（禁止 "assumed present"）；某节必需输入 ABSENT → 该节记 `NOT ASSESSED — NO DATA`，禁止估算、禁止从相邻产物推断、禁止留空给读者填；**全部**必需输入 ABSENT → 停止并以 `NOT ASSESSED — NO DATA` 作为整体裁决，点名缺什么、哪个技能产它。（Insufficient input）
R2. `NOT ASSESSED` 是**成功**的正确答案——它是对"数据怎么说"在无数据时的正确回答。要防的失效模式很具体：裁决枚举里没有"跑不了"状态的报告会产出**假性干净通过**——零资产零标准的项目返回 COMPLIANT 的资产审计、零 profiler 数据且从未设预算却报 ">99% headroom against a 16.67ms budget" 的性能画像。**证据缺失不等于无问题**：因无可扫文件而零命中的扫描什么都没验证——必须说清是哪一种，读者无法从绿色结果分辨。（Insufficient input）
R3. 加载项目上下文（Phase 1）：读 `CLAUDE.md` 取项目概览与标准；指定角色时读 `.claude/agents/` 里对应的 agent 定义。**`CLAUDE.md` 与 `.claude/agents/` 随框架分发——无技能创建它们；缺任一 → 报告为安装缺失**。（Phase 1）
R4. 按角色扫描（Phase 2）：**程序员** → 扫代码根（按 `.claude/docs/code-root-resolution.md` 解析）看架构、模式、关键文件——**解析不出代码根 = 该扫描没有运行**，它喂的节记 `NOT ASSESSED — code root unresolved`，**禁止猜一个 `src/`**；**设计师** → 扫 `design/` 的既有设计文档；**叙事** → 扫 `design/narrative/` 的世界观与剧情文档；**QA** → 扫 `tests/` 的既有测试覆盖（`/test-setup` 创建它）；**制作** → 扫 `production/` 的当前冲刺与里程碑。（Phase 2）
R5. **无角色或领域参数** → 通用导向：列 `design/`、`docs/architecture/`、`production/` 与代码根的**顶层**，读 `production/session-state/active.md`（存在时），并说明指定角色可以聚焦下一轮（例如 `/onboard programmer`）。（Phase 2）
R6. 读近期变更（git log 可得时）了解当前动量。（Phase 2）
R7. 入职文档模板（Phase 3）各节要求：**Current State of Your Area**——已建成什么、进行中什么、接下来计划什么；**按路径点名 Phase 2 找到的每一项**（设计师角色即每份既有 GDD 与设计文档），没找到就**明说没找到**。**Current Standards and Conventions** 只收 `CLAUDE.md` 与 agent 定义中该角色相关的约定。First Tasks 按"先读 → 再 review → 从小任务起步"三步。（Phase 3）
R8. 保存（Phase 4）：先向用户呈现入职文档；问 "May I write this to `production/onboarding/onboard-[role]-[date].md`?"；yes → 写文件（目录不存在则创建）。（Phase 4）
R9. 收尾（Phase 5）：裁决 **COMPLETE** — onboarding document generated。三条建议：新贡献者首次会话**之前**把入职文档发给ta；跑 `/sprint-status` 展示当前进度；需要下一步指引时跑 `/help`。（Phase 5）

R7 对应的文档模板（保留原文结构与表列，Phase 3）：

```markdown
# Onboarding: [Role/Area]

## Project Summary
[2-3 sentence summary of what this game is and its current state]

## Your Role
[What this role does on this project, key responsibilities, who you report to]

## Project Architecture
[Relevant architectural overview for this role]

### Key Directories
| Directory | Contents | Your Interaction |

### Key Files
| File | Purpose | Read Priority |

## Current Standards and Conventions
[Summary of conventions relevant to this role from CLAUDE.md and agent definition]

## Current State of Your Area
[What has been built, what is in progress, what is planned next. Name what
Phase 2 found by path — for a designer, each existing GDD and design doc — or
say it found none]

## Current Sprint Context
[What the team is working on now and what is expected of this role]

## Key Dependencies
[What other roles/systems this role interacts with most]

## Common Pitfalls
[Things that trip up new contributors in this area]

## First Tasks
1. [Read these documents first]
2. [Review this code/content]
3. [Start with this small task]

## Questions to Ask
[Questions the new contributor should ask to get fully oriented]
```

## 4. 门禁与裁决
- 本技能无审查门禁、无派生智能体。内含裁决：
- **技能裁决**：COMPLETE — onboarding document generated。
- **无数据裁决**：`NOT ASSESSED — NO DATA`（按节，或输入全缺时整体）；代码根解析失败专用 `NOT ASSESSED — code root unresolved`。

## 5. 移植建议
- **可直接移植**：R1-R2（NOT ASSESSED 反假性通过）、R3（框架文件缺失报告为安装缺失）、R4（按角色扫描 + 代码根解析不出就记 NOT ASSESSED、禁止猜目录）、R5（无参数给通用导向 + 提示角色聚焦）、R7（Key Files 表带 Read Priority、Current State 必须按路径点名或明说没找到）、R8（写前必问）、R9（先发文档再开工）。
- **需替换概念**：`CLAUDE.md` / `.claude/agents/` → `AGENTS.md` / 角色定义目录；GDD/`design/` → 领域文档目录；`production/session-state/active.md` → 当前工作状态文件；`/test-setup`、`/sprint-status`、`/help` → 测试初始化/进度查看/指引流程；程序员/设计师/叙事/QA/制作 → 各项目角色集。
- **改写示例**：
  - "入职文档的‘你的领域现状’一节必须逐项列出扫描实际找到的文件路径，一项都没找到就明说没有——禁止留空或泛泛而谈。"
  - "代码根解析失败时相关章节记 NOT ASSESSED — code root unresolved，禁止猜测目录结构填充内容。"

## 6. 关联文档
- 上游：`CLAUDE.md` 与 `.claude/agents/`（框架自带的角色定义）、`/test-setup`（创建 `tests/`）。
- 下游：`/sprint-status`（展示当前进度）、`/help`（下一步指引）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/code-root-resolution.md`。
