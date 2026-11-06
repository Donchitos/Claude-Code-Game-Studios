> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-SYSTEM-BOUNDARY — System Boundary Architecture Review

# TD-SYSTEM-BOUNDARY — 系统边界的架构评审

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After `/map-systems` Phase 3 dependency mapping is agreed but before
GDD authoring begins — validates that the system structure is architecturally
sound before teams invest in writing GDDs against it

**触发**：在 `/map-systems` 第 3 阶段的依赖映射达成一致之后、GDD 撰写开始之前——在团队投入精力据此撰写 GDD 之前，验证系统结构在架构上是可靠的

**Context to pass**:
- Systems index path (or the dependency map summary if index not yet written)
- Layer assignments (Foundation / Core / Feature / Presentation / Polish)
- The full dependency graph (what each system depends on)
- Any bottleneck systems flagged (many dependents)
- Any circular dependencies found and their proposed resolutions

**需传入的上下文**：
- 系统索引路径（若索引尚未写入，则提供依赖映射摘要）
- 层级划分（Foundation / Core / Feature / Presentation / Polish）
- 完整的依赖图谱（每个系统依赖什么）
- 任何被标记的瓶颈系统（依赖方众多）
- 发现的任何循环依赖及其拟定的解决方式

**Prompt**:
> "Review this systems decomposition from an architectural perspective before GDD
> authoring begins. Are the system boundaries clean — does each system own a
> distinct concern with minimal overlap? Are there God Object risks (systems doing
> too much)? Does the dependency ordering create implementation-sequencing problems?
> Are there implicit shared-state problems in the proposed boundaries that will
> cause tight coupling when implemented? Are any Foundation-layer systems actually
> dependent on Feature-layer systems (inverted dependency)? Return APPROVE
> (boundaries are architecturally sound — proceed to GDD authoring), CONCERNS
> [specific boundary issues to address in the GDDs themselves], or REJECT
> [fundamental boundary problems — the system structure will cause architectural
> issues and must be restructured before any GDD is written]."

**提示词**：
> "在 GDD 撰写开始之前，从架构角度评审这份系统分解。系统边界是否干净——每个系统是否拥有彼此独立、重叠最少的关注点？是否存在上帝对象（God Object）风险（系统承担了过多职责）？依赖排序是否会造成实现顺序上的问题？拟定的边界中是否存在隐式共享状态问题，在实现时会导致紧耦合？是否有 Foundation 层的系统实际上依赖于 Feature 层的系统（依赖倒置）？返回 APPROVE（边界在架构上可靠——可进入 GDD 撰写）、CONCERNS［应在 GDD 自身中处理的具体边界问题］，或 REJECT［根本性的边界问题——该系统的结构将引发架构问题，必须在撰写任何 GDD 之前重新组织］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
