> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# PR-SCOPE — Scope and Timeline Validation

# PR-SCOPE — 范围与时间线验证

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

智能体：`producer` | 模型层级：Opus | 领域：范围、时间线、依赖、制作风险

**Trigger**: After scope tiers are defined (brainstorm Phase 6, map-systems Phase
4, or any workflow that produces an MVP definition and timeline estimate)

**触发**：在范围分级定义完成之后（头脑风暴第 6 阶段、map-systems 第 4 阶段，或任何产出 MVP 定义与时间线估算的工作流）

**Context to pass**:
- Full vision scope description
- MVP definition
- Timeline estimate
- Team size (solo / small team / etc.)
- Scope tiers (what ships if time runs out)

**需传入的上下文**：
- 完整的愿景范围描述
- MVP 定义
- 时间线估算
- 团队规模（单人 / 小团队 / 等）
- 范围分级（时间不够时交付什么）

**Prompt**:
> "Review this scope estimate. Is the MVP achievable in the stated timeline for
> the stated team size? Are the scope tiers correctly ordered by risk — does each
> tier deliver a shippable product if work stops there? What is the most likely
> cut point under time pressure, and is it a graceful fallback or a broken product?
> Return REALISTIC (scope matches capacity), OPTIMISTIC [specific adjustments
> recommended], or UNREALISTIC [blockers — timeline or MVP must be revised]."

**提示词**：
> "评审这份范围估算。在所述时间线与所述团队规模下，MVP 是否可实现？各范围分级的风险排序是否正确——若在此处停止工作，每一级是否仍能交付可发布的产品？在时间压力下最可能的削减点在哪里，它是一个体面的退路还是一款残缺的产品？返回 REALISTIC（范围与产能匹配）、OPTIMISTIC［建议的具体调整］，或 UNREALISTIC［阻塞项——时间线或 MVP 必须修改］。"

**Verdicts**: REALISTIC / OPTIMISTIC / UNREALISTIC

**裁定**：REALISTIC / OPTIMISTIC / UNREALISTIC
