> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-FEASIBILITY — Technical Feasibility Assessment

# TD-FEASIBILITY — 技术可行性评估

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After biggest technical risks are identified during scope/feasibility
(brainstorm Phase 6, or any early-stage concept with technical unknowns)

**触发**：在范围/可行性阶段识别出最大技术风险之后（头脑风暴第 6 阶段，或任何存在技术未知项的早期概念）

**Context to pass**:
- Concept's core loop description
- Platform target
- Engine choice (or "undecided")
- List of identified technical risks

**需传入的上下文**：
- 概念的核心循环描述
- 目标平台
- 引擎选择（或“未定”）
- 已识别的技术风险列表

**Prompt**:
> "Review these technical risks for a [genre] game targeting [platform] using
> [engine or 'undecided engine']. Flag any HIGH risk items that could invalidate
> the concept as described, any risks that are engine-specific and should influence
> the engine choice, and any risks that are commonly underestimated by solo
> developers. Return VIABLE (risks are manageable), CONCERNS [list with mitigation
> suggestions], or HIGH RISK [blockers that require concept or scope revision]."

**提示词**：
> "评审这款面向 [平台] 的 [品类] 游戏使用 [引擎或‘未定引擎’] 的技术风险。标出任何可能使所述概念失效的 HIGH 风险项、任何属于引擎特有且应影响引擎选择的风险，以及任何常被单打独斗的开发者低估的风险。返回 VIABLE（风险可控）、CONCERNS［清单并附缓解建议］，或 HIGH RISK［需要修改概念或范围的阻塞项］。"

**Verdicts**: VIABLE / CONCERNS / HIGH RISK

**裁定**：VIABLE / CONCERNS / HIGH RISK
