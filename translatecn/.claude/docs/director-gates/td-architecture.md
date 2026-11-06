> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-ARCHITECTURE — Architecture Sign-Off

# TD-ARCHITECTURE — 架构签核

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After the master architecture document is drafted (`/create-architecture`
Phase 7), and after any major architecture revision

**触发**：在主架构文档起草完成后（`/create-architecture` 第 7 阶段），以及在任何重大架构修订之后

**Context to pass**:
- Architecture document path (`docs/architecture/architecture.md`)
- Technical requirements baseline (TR-IDs and count)
- ADR list with statuses
- Engine knowledge gap inventory

**需传入的上下文**：
- 架构文档路径（`docs/architecture/architecture.md`）
- 技术需求基线（TR-ID 及数量）
- 带状态的 ADR 列表
- 引擎知识缺口清单

**Prompt**:
> "Review this master architecture document for technical soundness. Check: (1) Is
> every technical requirement from the baseline covered by an architectural decision?
> (2) Are all HIGH risk engine domains explicitly addressed or flagged as open
> questions? (3) Are the API boundaries clean, minimal, and implementable? (4) Are
> Foundation layer ADR gaps resolved before implementation begins? Return APPROVE,
> CONCERNS [list], or REJECT [blockers that must be resolved before coding starts]."

**提示词**：
> "评审这份主架构文档的技术可靠性。检查：(1) 基线中的每项技术需求是否都有对应的架构决策覆盖？(2) 所有 HIGH 风险的引擎领域是否都已明确处理，或被标记为待解问题？(3) API 边界是否干净、最小化且可实现？(4) Foundation 层的 ADR 缺口是否在实现开始前得到解决？返回 APPROVE、CONCERNS［清单］，或 REJECT［必须在编码开始前解决的阻塞项］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
