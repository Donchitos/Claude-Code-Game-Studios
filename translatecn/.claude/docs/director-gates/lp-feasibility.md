> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# LP-FEASIBILITY — Lead Programmer Implementation Feasibility

# LP-FEASIBILITY — 主程实现可行性

Agent: `lead-programmer` | Model tier: Sonnet (Tier 2 lead — invoked when a domain specialist's feasibility sign-off is needed)

智能体：`lead-programmer` | 模型层级：Sonnet（第 2 层主管——在需要领域专家签署可行性时调用）

**Trigger**: After the master architecture document is written (`/create-architecture`
Phase 7b), or when a new architectural pattern is proposed

**触发**：在主架构文档写入之后（`/create-architecture` 第 7b 阶段），或在提出新的架构模式时

**Context to pass**:
- Architecture document path
- Technical requirements baseline summary
- ADR list with statuses

**需传入的上下文**：
- 架构文档路径
- 技术需求基线摘要
- 带状态的 ADR 列表

**Prompt**:
> "Review this architecture for implementation feasibility. Flag: (a) any decisions
> that would be difficult or impossible to implement with the stated engine and
> language, (b) any missing interface definitions that programmers would need to
> invent themselves, (c) any patterns that create avoidable technical debt or
> that contradict standard [engine] idioms. Return FEASIBLE, CONCERNS [list], or
> INFEASIBLE [blockers that make this architecture unimplementable as written]."

**提示词**：
> "从实现可行性的角度评审这份架构。标出：(a) 在所述引擎与语言下难以实现或无法实现的任何决策；(b) 任何缺失的接口定义，会让程序员不得不自行发明；(c) 任何会造成可避免技术债、或违背 [引擎] 标准惯用做法的模式。返回 FEASIBLE、CONCERNS［清单］，或 INFEASIBLE［使该架构按现有写法无法实现的阻塞项］。"

**Verdicts**: FEASIBLE / CONCERNS / INFEASIBLE

**裁定**：FEASIBLE / CONCERNS / INFEASIBLE
