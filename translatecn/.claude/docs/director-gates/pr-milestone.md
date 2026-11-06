> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# PR-MILESTONE — Milestone Risk Assessment

# PR-MILESTONE — 里程碑风险评估

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

智能体：`producer` | 模型层级：Opus | 领域：范围、时间线、依赖、制作风险

**Trigger**: At milestone review (`/milestone-review`), or when a scope change is
proposed that affects the milestone

**触发时机**：里程碑评审时（`/milestone-review`），或提出影响该里程碑的范围变更时

**Context to pass**:
- Milestone definition and target date
- Current completion percentage
- Blocked stories count
- Sprint velocity data (if available)

**需传入的上下文**：
- 里程碑定义与目标日期
- 当前完成百分比
- 受阻故事数量
- 冲刺速率数据（若有）

**Prompt**:
> "Review this milestone status. Based on current velocity and blocked story count,
> will this milestone hit its target date? What are the top 3 production risks
> between now and the milestone? Are there scope items that should be cut to protect
> the milestone date vs. items that are non-negotiable? Return ON TRACK, AT RISK
> [specific mitigations], or OFF TRACK [date must slip or scope must cut — provide
> both options]."

**提示词**：
> “评审此里程碑状态。基于当前速率与受阻故事数量，该里程碑能否按期达成目标日期？从现在到里程碑之间，排名前三的制作风险是什么？哪些范围项应被削减以保住里程碑日期，哪些又是不可谈判的？返回 ON TRACK、AT RISK [具体缓解措施]，或 OFF TRACK [日期必须推迟或范围必须削减——给出两种方案]。”

**Verdicts**: ON TRACK / AT RISK / OFF TRACK

**裁定**：ON TRACK / AT RISK / OFF TRACK
