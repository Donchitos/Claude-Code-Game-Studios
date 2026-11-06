> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# PR-PHASE-GATE — Production Readiness at Phase Transition

# PR-PHASE-GATE — 阶段转换时的制作就绪度

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

智能体：`producer` | 模型层级：Opus | 领域：范围、时间线、依赖、制作风险

**Trigger**: At every `/gate-check` director panel — producer is on the panel at every `modes.workflow`; spawn in parallel with the rest of it (alone at `minimal`, with TD-PHASE-GATE at `standard`, with TD-PHASE-GATE, CD-PHASE-GATE and AD-PHASE-GATE at `full`)

**触发**：在每一次 `/gate-check` 总监小组评审中——无论 `modes.workflow` 为何，`producer` 都在小组中；与其他成员并行发起（在 `minimal` 时单独发起，在 `standard` 时与 TD-PHASE-GATE，在 `full` 时与 TD-PHASE-GATE、CD-PHASE-GATE 及 AD-PHASE-GATE）

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- Sprint and milestone artifacts present — at `minimal`, the Build order in `design/game-brief.md` is the plan (that tier has no sprint plan)
- Team size (`team.size`) and sprint capacity (from the current sprint plan, if one exists)
- Current blocked story count

**需传入的上下文**：
- 目标阶段名称以及解析出的 `workflow` 层级
- 目标门禁在解析层级下的必需与推荐产物（来自 `/gate-check` 载入的门禁文件）
- 已有的冲刺与里程碑产物——在 `minimal` 层级下，`design/game-brief.md` 中的 Build order 就是计划（该层级没有冲刺计划）
- 团队规模（`team.size`）与冲刺产能（若存在当前冲刺计划，则从中获取）
- 当前被阻塞的故事数量

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> production perspective, judged against what this gate requires at this tier
> (the required-artifacts list you were given). Is the scope realistic for the
> stated timeline and team size? Is the work of [target phase] planned to the
> depth this gate requires — from the Production gate on, a sprint plan at
> `standard`/`full` and the brief's Build order at `minimal`; before it, no
> sprint plan is expected — and are its dependencies ordered so the team can
> execute it in sequence? What milestone or schedule risks could derail the start
> of [target phase] (its first two sprints, where the tier plans in sprints)?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**提示词**：
> "从制作的角度，评审当前项目状态在 [目标阶段] 门禁上的就绪度，并以该门禁在此层级所要求的（即已提供的必需产物清单）为评判依据。范围在所述时间线与团队规模下是否现实？[目标阶段] 的工作是否规划到了该门禁所要求的深度——从制作门禁起，`standard`/`full` 需有冲刺计划，`minimal` 需有简报中的 Build order；在此之前则不应期待有冲刺计划——并且其依赖排序是否使团队能够按顺序执行？哪些里程碑或进度风险可能会打乱 [目标阶段] 的启动（即其前两个冲刺，在该层级按冲刺规划的情况下）？
> 必需产物若以“none”传入，则构成一个问题项；若以“不在 [阶段] 之前预期”或“在 `workflow: [层级]` 下不要求”传入，则不构成问题项。
> 返回 READY、CONCERNS［清单］或 NOT READY［阻塞项］。"

**Verdicts**: READY / CONCERNS / NOT READY

**裁定**：READY / CONCERNS / NOT READY
