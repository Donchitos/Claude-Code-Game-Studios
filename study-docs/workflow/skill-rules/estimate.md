# estimate — 工作量与风险评估（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/estimate/SKILL.md) ｜ 阶段：Phase 4-5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/estimate [task-description]`
- **一句话职责**：从复杂度、依赖、速率与风险出发估算任务工作量，产出带置信度等级的结构化估算（乐观/预期/悲观三档 + 推荐预算 + 风险表 + 建议拆解）。
- **触发前置**：任务描述可估算——**过于含糊必须先问清再继续**。本技能只读（仅 Read/Glob/Grep 三工具），不写任何文件。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `CLAUDE.md`（技术栈、编码规范、架构模式、已有估算指引）；`design/gdd/` 相关设计文档（任务涉及已记录特性/系统时，按章节读：Grep `^#` 找标题 + offset/limit 读区间）；受影响代码文件（Grep 计数：非空行、分支行）；`production/sprints/` 历史冲刺数据（相似已完成任务与历史速率） | 全部只读测量 |
| 产出 | 无文件——纯回复中的结构化估算报告 | 只读技能；`Verdict: COMPLETE — estimate generated` |
| 派生智能体 | 无，主会话直接执行 | 无 resolve_config（本技能不解析配置键） |

## 3. 核心规则
R1. 理解任务：从参数读任务描述；**描述含糊到无法有意义估算时，先请求澄清再继续**。读 `CLAUDE.md` 取项目上下文；任务关联已记录特性/系统时按章节读 `design/gdd/`（禁止整读）。（Phase 1）
R2. 代码测量以 Grep 计数为准（Read/Glob/Grep 是仅有工具，这些计数就是度量）：**规模**——`Grep pattern="[^[:space:]]" path="[file]" output_mode="count"` 得非空行数；**分支**——`Grep pattern="(^|[^A-Za-z0-9_])(if|elif|for|foreach|while|match|switch|case|catch)([^A-Za-z0-9_]|$)|&&|[|][|]" path="[file]" output_mode="count"` 得含分支或布尔运算符的行数，该计数**近似**圈复杂度（注释与字符串也计入）——必须以"近似"报告，**禁止称作实测复杂度**；**依赖**——各文件引入了什么（GDScript `preload`/`load(`、C# `using`、C++ `#include`）以及被哪些文件引用。Grep 数不了的文件（缺失、二进制、不可读）必须记入 Notes and Assumptions，**禁止直接从合计里漏掉**。（Phase 2）
R3. 还须识别：与其它系统的集成点；受影响区域的既有测试覆盖；`production/sprints/` 中相似已完成任务与历史速率。**没有冲刺历史时必须在 Notes and Assumptions 写明**："No sprint history found; this estimate is not calibrated to the team's velocity"——并把它当作置信度里的一个风险，**禁止变成对数字的静默加垫**。（Phase 2）
R4. 复杂度三因素分析：**代码复杂度**——受影响文件的规模与分支（Phase 2 的 Grep 计数）、依赖数量与耦合度、触及核心/引擎代码还是叶子/特性代码、能沿用既有模式还是需要新模式；**范围**——触及的系统数、新写 vs 改动、所需新测试覆盖量、数据迁移或配置变更；**风险**——新技术或不熟的库、需求不清或有歧义、依赖未完成的工作、跨系统集成复杂度、性能敏感。（Phase 3）
R5. 估算报告按标准结构输出：Task Estimate 头 + Generated 日期；Task Description（1-2 句重述）；Complexity Assessment 表（Systems affected / Files likely modified / Size of affected files——`[N] non-blank lines; M branch lines`，注明 Grep counts、branch lines 近似复杂度 / New code vs modification 比例 / Integration points / Test coverage needed（Low/Medium/High）/ Existing patterns available（Yes/Partial/No））+ 关键受影响文件清单；Effort Estimate 三档表（Optimistic——一切顺利无意外 / Expected——正常节奏、小问题、一轮评审 / Pessimistic——重大未知浮出、被卡一天）+ **Recommended budget: [Y days]**（取 Expected）；Confidence（High/Medium/Low，说明是哪些因素决定了本任务的置信度）；Risk Factors 表（Risk/Likelihood/Impact/Mitigation）；Dependencies 表（Dependency/Status/Impact if Delayed）；Suggested Breakdown 表（Research/spike、Core implementation、Testing and validation 三段 + Total）；Notes and Assumptions。（Phase 4）
R5 对应的输出模板（保留原文格式约定）：

```markdown
## Task Estimate: [Task Name]
Generated: [Date]

### Task Description
[Restate the task clearly in 1-2 sentences]

### Complexity Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Systems affected | [List] | [Core, gameplay, UI, etc.] |
| Files likely modified | [Count] | [Key files listed below] |
| Size of affected files | [N non-blank lines; M branch lines] | Grep counts; branch lines approximate complexity |
| New code vs modification | [Ratio] | |
| Integration points | [Count] | [Which systems interact] |
| Test coverage needed | [Low / Medium / High] | |
| Existing patterns available | [Yes / Partial / No] | |

**Key files likely affected:**
- `[path/to/file1]` -- [what changes here]

### Effort Estimate

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | [X] | Everything goes right, no surprises |
| Expected | [Y] | Normal pace, minor issues, one round of review |
| Pessimistic | [Z] | Significant unknowns surface, blocked for a day |

**Recommended budget: [Y days]**

### Confidence: [High / Medium / Low]

[Explain which factors drive the confidence level for this specific task.]

### Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

### Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|

### Suggested Breakdown

| # | Sub-task | Estimate | Notes |
|---|----------|----------|-------|
| 1 | [Research / spike] | [X days] | |
| 2 | [Core implementation] | [X days] | |
| 3 | [Testing and validation] | [X days] | |
| | **Total** | **[Y days]** | |

### Notes and Assumptions
- [Key assumption that affects the estimate]
- [Any caveats about scope boundaries]
```

R6. 报告后附简短摘要：推荐预算、置信度等级、**单一最大风险因素**。（Phase 4）
R7. 后续步骤指引：置信度 Low → 承诺前先做限时 spike（`/prototype`）；任务 **> 10 天** → 建议用 `/create-stories` 拆成更小的故事；要排期 → 跑 `/sprint-plan update` 加入下个冲刺（项目没有冲刺计划时——如默认 minimal 工作流——改为加进 brief 的 build order）。（Phase 5）
R8. 估算纪律（Guidelines）：**永远给区间**（乐观/预期/悲观），禁止单一数字；推荐预算取 Expected 而非 Optimistic；**按半天取整**——对超过一天的任务用小时估算意味着虚假精度；**禁止静默加垫**——风险要显式点名，让团队自己决定；方法未定或核心需求仍 TBD 时置信度一律 Low——**建立在未做决策之上的区间只是猜测**。（Guidelines）

## 4. 门禁与裁决
- 本技能无门禁、无派生智能体、无裁决分支：唯一出口是 `Verdict: COMPLETE — estimate generated`（只读、必产出）。
- 内置质量约束见 R8（区间必给、预算取预期、半天取整、禁静默 padding、Low 置信度触发条件）。

## 5. 移植建议
- **可直接移植**：全部规则与游戏无关——R1（含糊先问清）、R2（Grep 计数测量法、近似≠实测、数不了的文件进假设）、R3（无历史速率须声明并计入风险、禁静默加垫）、R4（三因素清单）、R5-R6（报告结构与摘要三要素）、R7（Low→spike、>10 天→拆分、排期路径）、R8（估算纪律五条）。
- **需替换概念**：`design/gdd/` → 领域设计文档目录；`CLAUDE.md` → 项目根的 AGENTS.md/CLAUDE.md；`production/sprints/` → 历史迭代数据；GDScript/C#/C++ 的依赖语法 → 目标语言的 import/include 形态；`/prototype`、`/create-stories`、`/sprint-plan` → 对应的原型/拆卡/排期流程；brief build order → 无迭代流程时的任务序列。
- **改写示例**：
  - "估算永远给乐观/预期/悲观三档，推荐预算取预期档并按半天取整；任何风险不得以暗中加大数字的方式吸收，必须显式列入风险表。"
  - "方法尚未选定或核心需求仍是 TBD 时，置信度一律标 Low，并建议先做限时技术验证再承诺数字。"

## 6. 关联文档
- 上游：`CLAUDE.md`（项目上下文）、`design/gdd/`（规格）、`production/sprints/`（速率校准）。
- 下游：`/prototype`（Low 置信度时）、`/create-stories`（>10 天拆分）、`/sprint-plan update`（排期入冲）。
