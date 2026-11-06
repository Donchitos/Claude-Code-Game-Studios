> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-PHASE-GATE — Technical Readiness at Phase Transition

# TD-PHASE-GATE — 阶段转换时的技术就绪度

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: At `/gate-check` when `modes.workflow` is `standard` or `full` — the panel narrows by workflow; spawn in parallel with the rest of it (PR-PHASE-GATE, plus CD-PHASE-GATE and AD-PHASE-GATE at `full`)

**触发**：在 `/gate-check` 中当 `modes.workflow` 为 `standard` 或 `full` 时——评审小组按工作流收窄；与其他成员并行发起（PR-PHASE-GATE，且在 `full` 时还包括 CD-PHASE-GATE 与 AD-PHASE-GATE）

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- Architecture document path (if exists)
- Engine reference path
- ADR list

**需传入的上下文**：
- 目标阶段名称以及解析出的 `workflow` 层级
- 目标门禁在解析层级下的必需与推荐产物（来自 `/gate-check` 载入的门禁文件）
- 架构文档路径（如存在）
- 引擎参考文档路径
- ADR 列表

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> technical direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given), not what a later phase will
> need. Is the technical groundwork this phase requires in place and sound —
> entering Systems Design, is the concept feasible on the chosen engine; entering
> Technical Setup, do the systems index and GDDs give enough to architect from;
> entering Pre-Production, is the architecture sound and are the Foundation-layer
> decisions complete enough to begin implementation; entering Production or
> later, is the architecture holding up in the build? Are the high-risk engine
> domains addressed to the depth this phase requires? Are performance budgets
> realistic and documented where this phase requires them?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**提示词**：
> "从技术方向的角度，评审当前项目状态在 [目标阶段] 门禁上的就绪度，并以该门禁在此层级所要求的（即已提供的必需产物清单）为评判依据，而非以之后阶段的需要为准。本阶段所需的技术基础是否到位且可靠——进入系统设计阶段时，概念在所选引擎上是否可行；进入技术搭建阶段时，系统索引与 GDD 是否提供了足以做架构的信息；进入预制作阶段时，架构是否可靠，Foundation 层的决策是否完整到可以开始实现；进入制作或更晚阶段时，架构在构建中是否依然站得住？高风险的引擎领域是否已按本阶段所需的深度处理？性能预算是否现实，并在本阶段要求的地方有文档记录？
> 必需产物若以“none”传入，则构成一个问题项；若以“不在 [阶段] 之前预期”或“在 `workflow: [层级]` 下不要求”传入，则不构成问题项。
> 返回 READY、CONCERNS［清单］或 NOT READY［阻塞项］。"

**Verdicts**: READY / CONCERNS / NOT READY

**裁定**：READY / CONCERNS / NOT READY
