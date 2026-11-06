> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# AD-VISUAL — Art Director Visual Consistency Review

# AD-VISUAL — 美术总监视觉一致性评审

Agent: `art-director` | Model tier: session (inherit)

智能体：`art-director` | 模型层级：session（继承）

**Trigger**: After art direction decisions are made, when new asset types are
introduced, or when a tech art decision affects visual style

**触发时机**：美术方向决策确定后、引入新资产类型时，或技术美术决策影响视觉风格时

**Context to pass**:
- Art bible path (if exists at `design/art/art-bible.md`)
- The specific asset type, style decision, or visual direction being reviewed
- Reference images or style descriptions
- Platform and performance constraints

**需传入的上下文**：
- 美术圣经路径（若存在于 `design/art/art-bible.md`）
- 正在评审的具体资产类型、风格决策或视觉方向
- 参考图或风格描述
- 平台与性能约束

**Prompt**:
> "Review this visual direction decision for consistency with the established art
> style and production constraints. Does it match the art bible? Is it achievable
> within the platform's performance budget? Are there asset pipeline implications
> that create technical risk? Return APPROVE, CONCERNS [specific adjustments], or
> REJECT [style violation or production risk that must be resolved first]."

**提示词**：
> “评审此视觉方向决策与既定美术风格及制作约束的一致性。它是否与美术圣经相符？在平台的性能预算内是否可达成？是否存在会造成技术风险的资产管线影响？返回 APPROVE、CONCERNS [具体调整建议]，或 REJECT [必须先行解决的风格违背或制作风险]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
