> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-ADR — Architecture Decision Review

# TD-ADR — 架构决策评审

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After an individual ADR is authored (`/architecture-decision`), before
it is marked Accepted

**触发**：在单个 ADR 撰写完成之后（`/architecture-decision`），在它被标记为 Accepted 之前

**Context to pass**:
- ADR file path
- Engine version and knowledge gap risk level for the domain
- Related ADRs (if any)

**需传入的上下文**：
- ADR 文件路径
- 引擎版本以及该领域的知识缺口风险等级
- 相关 ADR（如有）

**Prompt**:
> "Review this Architecture Decision Record. Does it have a clear problem statement
> and rationale? Are the rejected alternatives genuinely considered? Does the
> Consequences section acknowledge the trade-offs honestly? Is the engine version
> stamped? Are post-cutoff API risks flagged? Does it link to the GDD requirements
> it covers? Return APPROVE, CONCERNS [specific gaps], or REJECT [the decision is
> underspecified or makes unsound technical assumptions]."

**提示词**：
> "评审这份架构决策记录（ADR）。它是否有清晰的问题陈述与理由？被否决的备选方案是否得到了真正的考量？后果（Consequences）部分是否诚实地承认了权衡取舍？是否标注了引擎版本？是否标出了知识截止之后的 API 风险？是否链接到它所覆盖的 GDD 需求？返回 APPROVE、CONCERNS［具体缺口］，或 REJECT［该决策规定不足，或作出了不可靠的技术假设］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
