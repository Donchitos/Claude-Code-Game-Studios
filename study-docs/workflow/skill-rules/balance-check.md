# balance-check — 数值平衡分析（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/balance-check/SKILL.md) ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/balance-check [system-name|path-to-data-file]`
- **一句话职责**：在公式与数据中找出平衡异常值、断裂的进度曲线、退化策略与经济失衡。
- **触发前置**：配置经 `resolve_config --keys automation` 解析；`AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `assets/data/` 与 `design/balance/` 中已识别域的相关文件；`design/registry/entities.yaml`（存在时优先）；`design/gdd/` 中该系统的 GDD | 数据 / 平衡目标（registry 的 constants/formulas 是权威跨文档数值） |
| 产出 | 会话内分析报告；经用户选择后写 `design/balance/balance-check-[system]-[date].md`（需要时创建目录，日期 YYYY-MM-DD） | 报告含 Data Sources 节记录全部读过文件 |
| 派生智能体 | 无，主会话直接执行。（注：`game-designer` 会预载本技能以子代理运行） | 子代理模式下无 `AskUserQuestion`，见 R12 |

resolve_config：本技能只解析 `automation` 键，用于决定收尾交互方式；无平衡相关档位键。

## 3. 核心规则（逐条编号 R1、R2……）

### 输入不足前置检查
R1. 产出任何报告前先核对本技能所需输入的存在性：
   1. 列出全部输入（数据文件、先前报告、profiler 输出、测试结果、registry、源代码）；
   2. 逐项记 `FOUND` 或 `ABSENT`（不是"假设存在"）；
   3. 某节必需输入 ABSENT 时该节记 **`NOT ASSESSED — NO DATA`**——禁止估算、禁止从相邻工件推断、禁止把必填格留给下次读模板的人；
   4. **每一个**必需输入都 ABSENT 时停止并整体报告 `NOT ASSESSED — NO DATA`，点名缺了什么、哪个技能产出它。（Insufficient input）
R2. `NOT ASSESSED` 裁决是成功——它是"数据说什么"在无数据时的正确答案。禁止缺"无法运行"态的裁决枚举产生假性干净通过。"无证据"绝不是"不存在证据"：零文件可扫的扫描没有验证任何东西，必须说明是哪一种。（Insufficient input）

### Phase 1-3 — 定域、读数据、读目标
R3. 从 `$ARGUMENTS` **整串**（数据文件路径可能含空格）判定平衡域：Combat（武器/技能 DPS、time-to-kill、伤害类型交互）/ Economy（资源水龙头与水槽、获取速率、物品定价）/ Progression（XP/战力曲线、死区、战力尖峰）/ Loot（稀有度分布、保底计时、库存压力）/ 文件路径（直接载入并按内容推断域）。无参数时询问用户检查哪个系统。（Phase 1）
R4. 读取已识别域在 `assets/data/` 与 `design/balance/` 的相关文件，并记录每一个读过的文件——它们将出现在报告的 Data Sources 节。（Phase 2）
R5. registry 优先：`design/registry/entities.yaml` 存在时在 GDD **之前**读——其 `constants` 与 `formulas` 节持有跨 GDD 命名值与输出范围（即平衡目标，已蒸馏，各带 `source:` GDD 与 `revised:` 日期）：
   ```
   Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 6
   ```
   凡 registry 列出的常量或公式，其预期值取自 registry——这是 GDD 不得矛盾的权威跨文档数值。registry 不存在或无条目（在 `/design-system` 填充前是空桩，属默认态）时跳过，仅用 GDD。（Phase 3）
R6. 然后读 `design/gdd/` 中该系统的 GDD 以理解设计意图目标、调参钮（tuning knobs）与预期值域——补 registry 未供之项，这是"正确"行为的基线；按节读（Grep `^#` 找标题 + Read offset/limit）。数据文件 FOUND 但 registry 与 GDD 都给不出本域目标时，按目标评判的节（Outliers Detected，以及域有曲线时的 Progression Analysis）记 `NOT ASSESSED — NO DATA`，各自点名缺了什么（在 `design/gdd/` 找过哪份 GDD、registry 缺失还是为空），并点名产出两者的 `/design-system`。（Phase 3）

### Phase 4 — 分析
R7. 每个域都必须先把每个值与其目标比较：对数据文件中的每个命名值，取 Phase 3 的目标（registry 常量的 `value`、registry 公式的 `output_range`、或 GDD 所述范围）比较；超范围的值是 Outliers Detected 的一行（如 `player_damage_base` 140 对 90–110）；任何地方都无目标的值既非在范围内也非异常——列入 Values That Need Attention，标 `no stated range — not judged`。（Phase 4）
R8. 域特定检查必须执行：
   - **Combat**——计算每个战力档的全部武器/技能 DPS；查各档 time-to-kill；找严格支配其它所有选项的支配项；查防御选项可否造成不可杀状态；验证伤害类型/抗性交互平衡。
   - **Economy**——带流量映射全部资源水龙头与水槽；随时间投影资源积累；查无限资源循环；验证金币水槽随金币产出缩放；查是否有永不值得购买的物品。
   - **Progression**——绘 XP 曲线与战力曲线；查死区（过久无有意义进展）；查战力尖峰（能力突跳）；验证内容门与预期玩家战力对齐；查跳过/肝策略是否破坏预期节奏。
   - **Loot**——计算各稀有度档期望获取时间；核保底计时数学；验证无掉落在任何阶段严格无用；查库存压力对获取速率。（Phase 4）

### Phase 5 — 输出与裁决
R9. 报告结构：`## Balance Check: [System Name]`、Data Sources Analyzed（读过文件清单）、Health Summary、Outliers Detected（表：Item/Value | Expected Range | Actual | Issue）、Degenerate Strategies Found（策略及为何有害）、Progression Analysis（曲线健康度的图描述或表）、Recommendations（表：Priority | Issue | Suggested Fix | Impact）、Values That Need Attention（带建议调整与理由）。（Phase 5）
R10. Health Summary 按最差发现首匹配：
   - **CRITICAL ISSUES**——存在退化策略（一个选择支配所有替代项）、停滞或无法完成的进度、或无水槽的经济循环；
   - **CONCERNS**——仅一次调参可修的异常或曲线问题且无 critical 级发现；
   - **NOT ASSESSED**——无物可分析（无数据路径）、需要目标的节是 `NOT ASSESSED — NO DATA`、或某值无既判范围可评——点名是哪种；它低于两个发现裁决（测得的问题比缺口更可行动）、高于 HEALTHY；
   - **HEALTHY**——每个值都对既述目标评判过，无异常、无退化策略、进度在既述目标内。（Phase 5）

### Phase 6 — 修复与验证循环
R11. 呈现报告后用 `AskUserQuestion`：
   - Prompt："Balance check complete. What would you like to do next?"
   - `[A] Fix highest-priority issue now — walk me through it`
   - `[B] Save report to design/balance/balance-check-[system]-[date].md`
   - `[C] Stop here — I'll review the findings manually`（Phase 6）
R12. 作为子代理运行时（`game-designer` 预载本技能且子代理无 `AskUserQuestion`）：以问题加这三个选项的短列表结束回复并停止——由调用方问用户并把答案传回。（Phase 6）
R13. 选 [A]：问先处理哪个问题（按 Recommendations 表的 Priority 行引用）；引导用户更新 `assets/data/` 中相关数据文件或 `design/balance/` 中公式；每次修复后提供重跑相关平衡检查以验证未引入新异常；修复改动了 GDD 定义的调参钮或被 ADR 引用的值时必须提醒：
   > "This value is defined in a design document. Run `/propagate-design-change [path]` on the affected GDD to find downstream impacts before committing."（Phase 6）
R14. 选 [B]：写报告到 `design/balance/balance-check-[system]-[date].md`（需要时创建目录；[date] 用当前日期 YYYY-MM-DD 格式），确认已写后以 "Re-run `/balance-check` after fixes to verify." 收尾。选 [C]：汇总未决问题后以同一句收尾。（Phase 6）

## 4. 门禁与裁决
- **裁决词（Health Summary）**：`NOT ASSESSED` / `HEALTHY` / `CONCERNS` / `CRITICAL ISSUES`。
- **排序（按最差发现，首匹配）**：CRITICAL ISSUES > CONCERNS > NOT ASSESSED > HEALTHY（NOT ASSESSED 低于两个发现裁决——测得的问题比缺口更可行动——高于 HEALTHY）。
- **取最严原则**：任一 critical 级发现（支配策略 / 停滞或不可完成的进度 / 无水槽经济循环）即整体 CRITICAL ISSUES。
- **消费方**：Recommendations 表驱动修复循环；`/propagate-design-change` 消费调参钮变更的下游影响。

## 5. 移植建议
- **可直接移植**：R1-R2（输入不足检查）、R7（每值对目标比较 + 无目标值单列不判异常）、R10（最差发现首匹配 + NOT ASSESSED 排位）、R12（子代理无交互组件时的问答协议）、R13 的设计值变更提醒模式。
- **需替换概念**：Combat/Economy/Progression/Loot 四域 → 任何有目标值的数据域（定价表、限流配置、缓存 TTL、SLA 预算）；`design/balance/` → 基准/阈值目录；GDD 调参钮 → 配置文档中的可调参数；registry → 跨文档权威值登记表。
- **改写示例**：
  - R7 → "对数据文件中的每个命名值，从权威登记表或设计文档取其目标范围并比较；超范围记入异常表；任何地方都无目标的值单列为'无既判范围——不评判'，不得臆断其异常。"
  - R10 → "健康度裁决按最差发现首匹配：CRITICAL ISSUES > CONCERNS > NOT ASSESSED > HEALTHY；NOT ASSESSED 低于两个发现裁决、高于 HEALTHY——测得的问题比缺口更可行动。"

## 6. 关联文档
- 上游：`/design-system`（产出 GDD 与 registry 的 constants/formulas，即平衡目标来源）。
- 下游：`/propagate-design-change`（调参钮变更的下游影响传播）、`/balance-check` 自身重跑验证。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`。
