> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# PR-SPRINT — Sprint Feasibility Review

# PR-SPRINT — 冲刺可行性评审

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

智能体：`producer` | 模型层级：Opus | 领域：范围、时间线、依赖、制作风险

**Trigger**: Before finalising a sprint plan (`/sprint-plan`), and after any
mid-sprint scope change

**触发时机**：最终确定冲刺计划之前（`/sprint-plan`），以及任何冲刺中途范围变更之后

**Context to pass**:
- Proposed sprint story list (titles, estimates, dependencies)
- Team capacity (hours available)
- Current sprint backlog debt (if any)
- Milestone constraints

**需传入的上下文**：
- 拟定的冲刺故事清单（标题、估算、依赖）
- 团队产能（可用工时）
- 当前冲刺积压债务（若有）
- 里程碑约束

**Prompt**:
> "Review this sprint plan for feasibility. Is the story load realistic for the
> available capacity? Are stories correctly ordered by dependency? Are there hidden
> dependencies between stories that could block the sprint mid-way? Are any stories
> underestimated given their technical complexity? Return REALISTIC (plan is
> achievable), CONCERNS [specific risks], or UNREALISTIC [sprint must be
> descoped — identify which stories to defer]."

**提示词**：
> “评审此冲刺计划的可行性。故事负载对可用产能而言是否现实？故事是否按依赖正确排序？故事之间是否存在可能中途阻塞冲刺的隐藏依赖？是否有故事因技术复杂度而被低估？返回 REALISTIC（计划可达成）、CONCERNS [具体风险]，或 UNREALISTIC [冲刺必须缩减范围——指明哪些故事应推迟]。”

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

**裁定**：REALISTIC / CONCERNS / UNREALISTIC
