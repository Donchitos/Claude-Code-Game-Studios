# scope-check — 范围蔓延检测与削减建议（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/scope-check/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/scope-check [feature-name or sprint-N]`（参数为功能名〔可多词〕、sprint 编号或里程碑名）
- **一句话职责**：把原始计划范围与当前实现状态对比，检测、量化并分诊范围蔓延（scope creep）——标记新增项、算出膨胀分数（Bloat Score）、给出削减建议。
- **触发前置**：必须能定位到基线范围文档（GDD / sprint 计划 / 里程碑文档）。本技能**只读**——报告发现但不写任何文件。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 基线文档：功能名 → `design/gdd/[feature].md` 或 `design/` 下匹配文件；sprint 编号（如 `sprint-3`）→ `production/sprints/sprint-003.md`（`/sprint-plan` 写的文件名）或类似；里程碑 → `production/milestones/[name].md`。当前状态：代码库中与该功能/sprint 相关的文件（扫描）、`git log --oneline --since=[start-date]`、TODO/FIXME 注释、进行中 sprint 的活动计划 | 基线 vs 现状；读 GDD 必须按节读（Grep `^#` 定位标题 + Read offset/limit） |
| 产出 | 对比报告（会话内输出）——只读技能，不写文件 | 含 Bloat Score、风险评级、削减建议 |
| 派生智能体 | 无，主会话直接执行 | 无 `resolve_config`；模型档位 haiku |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 找基线
R1. 按参数类型定位基线范围文档（见数据依赖表）；文档不存在时**报告缺失文件并停止**——没有基线就绝不继续对比。（Phase 1）
R2. 读 GDD 必须按节读：先用 Grep（pattern `^#`，content 模式）找到需要的标题，再用 offset/limit 读那些范围——禁止无界全文读。（Phase 1）

### Phase 2 — 读当前状态
R3. 检查实际已实现/进行中的内容：扫描代码库中与该功能/sprint 相关的文件；读相关提交的 git log（`git log --oneline --since=[start-date]`）；检查 TODO/FIXME 注释（未完成范围新增的信号）；功能处于 sprint 中期时检查活动 sprint 计划。（Phase 2）

### Phase 3 — 对比并出报告
R4. 报告结构：`## Scope Check: [名称]` + Generated 日期 → Original Scope（原计划条目清单）→ Current Scope（已实现/进行中条目清单）→ Scope Additions 表（Addition | Source〔commit/person〕| When | Justified?〔Yes/No/Unclear〕| Effort〔S/M/L〕）→ Scope Removals 表（Removed Item | Reason | Impact）→ Bloat Score（Original items / Current items / Items added〔+X%〕/ Items removed / Net scope change〔+/-N，X%〕）→ Risk Assessment（Schedule / Quality / Integration 各 Low/Medium/High + 解释）→ Recommendations（**Cut** 保进度应删项 / **Defer** 可移后续 sprint 项 / **Keep** 真正必要的新增 / **Flag** 需要 producer 或 creative-director 决策的项）。（Phase 3）
R5. **若 Phase 4 将返回 NOT ASSESSED，禁止渲染数字块**：把计数与 Bloat Score 替换为 `[Baseline | Current state] unusable — see verdict`（哪一侧读不到就写哪一侧）并给原因。`Original items: 0 / Net scope change: 0%` 出现在 NOT ASSESSED 裁决上方，会在更早一处重建 Phase 4 要杀掉的"0% 读作 on track"危害——且读者信任数字胜过警告。（Phase 3）

### Phase 4 — 裁决
R6. 按净范围变化给裁决：

   | 净变化 | 裁决 | 含义 |
   |--------|------|------|
   | ≤10% | **PASS** | On Track — 可接受偏差内 |
   | >10–25% | **CONCERNS** | Minor Creep — 定向削减可控 |
   | >25–50% | **FAIL** | Significant Creep — 必须削减或正式延期 |
   | >50% | **FAIL** | Out of Control — 停下、重计划、上报 producer |（Phase 4）
R7. **套表之前先确认百分比有意义**。以下任一情况必须输出 **NOT ASSESSED**——绝不是一个算出来的百分比：
   1. 基线文档存在但**未列举任何范围条目**（全是标题、占位符或 `[TO BE CONFIGURED]`）——Phase 1 只在文件*缺席*时停下，这是文件*在场且为空*的情形，更危险：零条目算出 0% 净变化会渲染成 PASS — On Track，而实际什么都没对比、什么都不 on track；
   2. **当前状态无法判定**——无相关源文件、窗口期内无提交、无进行中工作可读；真基线对不可读的现在不是 0% 变化，也不是零当前条目算出的 −100%（表把两者都读作 PASS）；
   3. 分母因任何其它原因为零——从零基线条目算出的百分比不是小数字，是根本不是数字。（Phase 4）
R8. NOT ASSESSED **高于 PASS**（没发生过的对比没有证明范围 on track），**低于 CONCERNS 和 FAIL**（测得的蔓延比不可测的基线更可行动）。裁决醒目输出：`**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**` + `Net change: [+X%] — [On Track / Minor Creep / Significant Creep / Out of Control]`，或 `NOT ASSESSED — [哪一侧读不到，为什么]`。（Phase 4）

### Phase 5 — 后续
R9. 按裁决分支给后续：**PASS** → 无需行动，建议下个里程碑前重跑；**NOT ASSESSED** → 说明哪一侧不可读、什么能修复（填充基线文档，或把技能指向工作实际所在处），**禁止**对同样输入提议重跑——会产出同样的非答案；**CONCERNS** → 主动提出找出削减比最好的 2–3 个新增项，引用 `/sprint-plan update` 正式重定范围（项目无 sprint 计划时——如默认 minimal 工作流——改编辑 brief 的 build order）；**FAIL** → 建议上报 producer，引用 `/sprint-plan update` 重计划或 `/estimate` 重定时间基线。（Phase 5）
R10. 除 NOT ASSESSED 外，每个裁决都以这句话收尾："Run `/scope-check [name]` again after cuts are made to verify the verdict improves."（NOT ASSESSED 以"什么能让它可评估"收尾——同输入重跑只会重复非答案。）（Phase 5）

### 原则
R11. 范围蔓延 = 没有对应削减或延期的新增；新增不都是坏事——有些是发现的需求，但必须被承认并计入。建议削减时优先保留核心玩家体验，舍弃锦上添花项。范围变化必须量化——"感觉变大了"不可行动，"+35% items" 才可行动。（Rules）

## 4. 门禁与裁决
- **裁决词**：`PASS` / `CONCERNS` / `NOT ASSESSED` / `FAIL`（对应 On Track / Minor Creep / 不可评估 / Significant Creep–Out of Control）。
- **阈值**：净变化 ≤10% PASS；>10–25% CONCERNS；>25–50% 与 >50% 均为 FAIL（后者 Out of Control）。
- **排序**：FAIL > CONCERNS > NOT ASSESSED > PASS（NOT ASSESSED 压制 PASS 的假性绿灯，但不压制已测得的蔓延）。
- **消费方**：`/sprint-plan update`（CONCERNS/FAIL 时正式重定范围）、`/estimate`（FAIL 时重定时间基线）；被 `/perf-profile` Phase 5 的选项 B 引用。

## 5. 移植建议
- **可直接移植**：R1（无基线即停）、R5+R7（"零条目基线/不可读现状算出的百分比不是数字"、数字块禁渲染）、R6 阈值表、R8 排序、R11（量化纪律与核心体验优先）。
- **需替换概念**：GDD/sprint 计划/里程碑 → 任何基线工件（PRD、迭代计划、版本路线图）；producer/creative-director → 项目负责人/产品负责人；`/sprint-plan`、`/estimate` → 重计划/重估时长的对应流程；"core player experience" → 产品的核心用户价值。
- **改写示例**：
  - R7 → "计算范围偏差前先验证分母：基线文档存在但零条目、或现状无法判定时，裁决记 NOT ASSESSED——绝不算出百分比。零条目基线产出的 0% 会渲染成 PASS，而实际什么都没对比。"
  - R5 → "当对比结论将是 NOT ASSESSED 时，报告里不得出现数字统计块；用 '[基线|现状] unusable — see verdict' 替换计数与膨胀分——读者会信任数字胜过警告。"

## 6. 关联文档
- 上游：`/sprint-plan`（写 `production/sprints/sprint-00N.md` 基线）、`/brainstorm` 等设计技能（写 GDD 基线）。
- 下游：`/sprint-plan update`（重定范围）、`/estimate`（重定时间基线）；被 `/perf-profile` Phase 5（选项 B：削减功能范围）、`/gate-check` 相关流程引用。
