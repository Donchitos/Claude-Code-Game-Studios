> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# TD-CHANGE-IMPACT — Design Change Impact Review

# TD-CHANGE-IMPACT — 设计变更影响评审

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After the Design Change Impact Report is produced
(`/propagate-design-change` Phase 6), before the resolution workflow begins

**触发时机**：设计变更影响报告产出后（`/propagate-design-change` 第 6 阶段）、解决流程开始之前

**Context to pass**:
- The full Design Change Impact Report from Phase 6 — change summary, every
  affected ADR with its Still Valid / Needs Review / Likely Superseded
  classification, and the recommended actions

**需传入的上下文**：
- 第 6 阶段的完整设计变更影响报告——变更摘要、每个受影响 ADR 及其 Still Valid / Needs Review / Likely Superseded 分类，以及建议采取的行动

**Prompt**:
> "Review this design-change impact assessment before any ADR is revised. Are the
> impact classifications correct — in particular, is any ADR under-classified
> (marked Still Valid when the change actually contradicts its assumptions)? Are
> the recommended actions architecturally sound? Were any cascading effects on
> other ADRs or systems missed — decisions that depend on the ones already
> flagged? Return APPROVE, CONCERNS [the specific ADRs or recommendations to
> revisit], or REJECT [the assessment must be re-analyzed before resolution
> begins — say what was missed]."

**提示词**：
> “在任何 ADR 被修订之前，评审此设计变更影响评估。影响分类是否正确——尤其是，是否有 ADR 被低估分类（变更实际已与其假设相矛盾，却被标记为 Still Valid）？建议行动在架构上是否稳妥？是否遗漏了对其他 ADR 或系统的连锁影响——即那些依赖于已标记决策的其他决策？返回 APPROVE、CONCERNS [需要重新审视的具体 ADR 或建议]，或 REJECT [解决流程开始前必须重新分析该评估——说明遗漏了什么]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
