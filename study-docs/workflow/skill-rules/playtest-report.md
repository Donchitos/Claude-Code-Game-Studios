# playtest-report — 结构化试玩报告（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/playtest-report/SKILL.md) ｜ 阶段：Phase 4-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/playtest-report [new|analyze path-to-notes] [--review full|lean|solo]`
- **一句话职责**：生成空白结构化试玩报告模板，或把既有试玩笔记整理成结构化反馈——发现分类路由到设计/平衡/bug/打磨四个去处，经创意总监体验门禁后存档。
- **触发前置**：`new` 模式无前置（纯模板输出）；`analyze` 模式需笔记文件路径；门禁 `full` 档需 `design/gdd/game-concept.md`（或 minimal 档的 `design/game-brief.md`）作支柱参照。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation`（resolve_config；`--review` 覆盖 `review_mode` 本次运行；无块 → `.claude/docs/config-resolution.md` 默认） | `review_mode` 定 CD-PLAYTEST 门禁档（full 派生 / lean、solo 跳过）；`automation` 定提问/写盘行为 |
| 读取 | `analyze` 模式：笔记文件全文 + 既有设计文档（**按章节读**：先 Grep pattern `^#` content 模式找标题，再 Read offset/limit 读所需区间）；`full` 档门禁：`design/gdd/game-concept.md` 的 game pillars 与 core fantasy（minimal 档无此文件 → 传 `design/game-brief.md` 的一句话 pitch 和 "Who it's for / what they feel" 行） | 禁止整读设计文档 |
| 产出 | `production/qa/playtests/playtest-[date]-[tester].md`（用户同意后写，目录不存在则创建）；CONCERNS/REJECT/NOT ASSESSED 时报告内加 `## Creative Director Assessment` 节 | 空白模板模式不落盘 |
| 派生智能体 | `full` 档：`creative-director`（门禁 **CD-PLAYTEST**，读 `.claude/docs/director-gates/cd-playtest.md`——派生智能体读自己的门禁文件，主会话**禁止**读它）；`solo`/`lean` 跳过 | 跳过时注记 "CD-PLAYTEST skipped — Solo mode." / "— Lean mode."（lean 下不是 PHASE-GATE） |

## 3. 核心规则
R1. 模式（Phase 1）：`new` → 生成空白试玩报告模板，**流程到 Phase 2A 即止**——空白模板没有可路由、可评审、可保存的内容；`analyze [path]` → 读原始笔记、把模板填成结构化发现；无参数 → 问 `[A] New blank template` / `[B] Analyze notes — I'll give you the path`。每次 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录并继续；`automation_always_ask` 类别恒问）。门禁检查模式见 `.claude/docs/director-gates.md`；各门禁定义在 `.claude/docs/director-gates/[gate-id].md`——**派生智能体读自己的门禁文件，主会话不读**。（Phase 1）
R2. `new` 模式输出空白模板后停止，裁决 **COMPLETE** — blank template output; nothing saved。（Phase 2A）
R3. Analyze 流程（Phase 2B）：读给定路径的原始笔记；与既有设计文档交叉对照——**按章节读**（Grep pattern `^#` 找标题 + Read offset/limit 区间，禁止整读）；用结构化发现填模板；**任何与设计意图冲突的试玩观察都要旗标**。（Phase 2B）
R4. **缺陷与手感分流铁律**：描述缺陷的观察——崩溃、掉帧、软锁、任何"明明白白坏了"而非"玩起来不好"的东西——进 **Bugs Encountered 表**，不进 Gameplay Flow → Pain points，并在 Phase 3 按_bug_ 路由。**Pain points 只装"玩起来什么感觉"**。（Phase 2B）
R5. 行动路由（Phase 3）：全部发现分四桶并给出路由指令——**Design changes needed**（趣味问题、玩家困惑、坏掉的机制、与 GDD 预期体验冲突的观察）→ "Run `/propagate-design-change [path]` on the affected design document to find downstream impacts before making changes."；**Balance adjustments**（数值不对、难度太尖或太平）→ "Run `/balance-check [system]` to verify the full balance picture before tuning values."；**Bug reports**（可复现的明确实现缺陷）→ "Use `/bug-report` to formally track these."；**Polish items**（不阻塞进度、留待后期的摩擦或手感问题）→ "Add to the polish backlog in `production/` when the team reaches that phase."。（Phase 3）
R6. CD-PLAYTEST 门禁档位检查（分类后、保存前套用）：`solo` → 跳过，注记 "CD-PLAYTEST skipped — Solo mode."，直接进 Phase 4 保存报告；`lean` → 跳过（不是 PHASE-GATE），注记 "CD-PLAYTEST skipped — Lean mode."，直接进 Phase 4；`full` → 正常派生。（Phase 3b）
R7. 派生 `creative-director`（门禁 CD-PLAYTEST，`full` 档）：传入——结构化报告内容、game pillars 与 core fantasy（取自 `design/gdd/game-concept.md`）、本次测试的具体假设。（Phase 3b）
R8. **支柱缺失的降级链**：`game-concept.md` 不存在（minimal 档预期如此，`design/game-brief.md` 顶替它）→ brief 没有 pillars：传它的一句话 pitch 和 "Who it's for / what they feel" 行代替，并说明它们顶替 pillars。**两份文档都不存在 → 在 prompt 里明说："No pillars available — assess against the hypothesis alone."——对 pillars 缄默不言的门禁会自己发明 pillars**。（Phase 3b）
R9. 门禁结果落地：创意总监的评估在**保存前**呈现。**CONCERNS 或 REJECT** → 报告加 `## Creative Director Assessment` 节，记下裁决与反馈；**APPROVE** → 在报告中注记批准；**NOT ASSESSED**（总监缺输入，见 `.claude/docs/director-gates.md`）→ 加同一节**点名缺什么——它不是批准**。（Phase 3b）
R10. 保存（Phase 4）：问 "May I write this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?"；yes → 写文件（目录不存在则创建）。（Phase 4）
R11. 收尾（Phase 5）：裁决 **COMPLETE** — playtest report generated。先处理**最高优先级的发现类别**；设计变更处理完 → 对更新后的 GDD 重跑 `/design-review`；bug 修完 → 重跑 `/bug-triage` 更新优先级。（Phase 5）

R2/R3 对应的报告模板（保留原文结构与字段，Phase 2A）：

```markdown
# Playtest Report

## Session Info
- **Date**: [Date] · **Build**: [Version/Commit] · **Duration**: [Time played]
- **Tester**: [Name/ID] · **Platform**: [PC/Console/Mobile]
- **Input Method**: [KB+M / Gamepad / Touch]
- **Session Type**: [First time / Returning / Targeted test]

## Test Focus
[What specific features or flows were being tested]

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Gameplay Flow
### What worked well
### Pain points
- [Issue 1 -- Severity: High/Medium/Low]
### Confusion points
- [Where the player was confused and why]
### Moments of delight

## Bugs Encountered
| # | Description | Severity | Reproducible |

## Feature-Specific Feedback
### [Feature 1]
- **Understood purpose?** [Yes/No]
- **Found engaging?** [Yes/No]
- **Suggestions**: [Tester suggestions]

## Quantitative Data (if available)
- **Deaths**: [Count and locations] · **Time per area**: [Breakdown]
- **Items used**: [What and when]
- **Features discovered vs missed**: [List]

## Overall Assessment
- **Would play again?** [Yes/No/Maybe]
- **Difficulty**: [Too Easy / Just Right / Too Hard]
- **Pacing**: [Too Slow / Good / Too Fast]
- **Session length preference**: [Shorter / Good / Longer]

## Top 3 Priorities from this session
1. [Most important finding] 2. [Second priority] 3. [Third priority]
```

## 4. 门禁与裁决
- **门禁 ID**：CD-PLAYTEST（创意总监玩家体验评审，`.claude/docs/director-gates/cd-playtest.md`）。`full` → 派 `creative-director` 智能体；`solo` → 跳过注记；`lean` → 跳过注记（不是 PHASE-GATE）。
- **门禁裁决**：APPROVE / CONCERNS / REJECT / NOT ASSESSED；CONCERNS、REJECT、NOT ASSESSED 都落成报告内 `## Creative Director Assessment` 节，NOT ASSESSED 明确**不是批准**。
- **技能裁决**：COMPLETE（报告生成/空白模板输出）。
- **防编造**：支柱信息缺失必须显式声明，禁止让门禁在缄默中发明评估基准。

## 5. 移植建议
- **可直接移植**：R1-R2（空白模板即止、不落盘）、R3（交叉对照按章节读）、R4（缺陷与手感分流——"坏了"进 bug 表、"难玩"进痛点）、R5（四桶路由 + 先查下游影响再改设计）、R6-R9（档位检查、缺支柱必须明说防门禁编造、NOT ASSESSED 不是批准）、R10（写前必问）。
- **需替换概念**：playtest/Tester → 试用/内测用户；GDD/game pillars/core fantasy → 产品愿景文档/核心价值主张；`/propagate-design-change`、`/balance-check`、`/design-review` → 变更影响分析/参数核查/设计评审流程；polish backlog → 打磨待办；creative-director → 体验/产品负责人。
- **改写示例**：
  - "试用反馈分四类路由：设计问题先跑变更影响分析再动文档；参数问题先核查全局平衡再调值；可复现缺陷走正式缺陷跟踪；打磨项进待办清单——禁止把缺陷混进体验痛点。"
  - "派体验负责人评审时必须传入产品核心支柱与本次验证假设；支柱文档缺失时在指令中显式声明‘无支柱可用，仅对假设评估’，禁止留空让其自行脑补基准。"

## 6. 关联文档
- 上游：`design/gdd/game-concept.md`（pillars 与 core fantasy，门禁输入）、`design/game-brief.md`（minimal 档顶替）、既有设计文档（analyze 交叉对照）。
- 下游：`/propagate-design-change`（设计变更下游影响）、`/balance-check`（平衡核查）、`/bug-report`（缺陷正式化）、`/design-review`（改后复审）、`/bug-triage`（修后更新优先级）。
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/director-gates/cd-playtest.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`。
