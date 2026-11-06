> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# CD-PHASE-GATE — Creative Readiness at Phase Transition

# CD-PHASE-GATE — 阶段转换时的创意就绪度

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

智能体：`creative-director` | 模型层级：Opus | 领域：愿景、支柱、玩家体验

**Trigger**: At `/gate-check` when `modes.workflow` is `full` — the panel narrows by workflow, and only the full panel includes creative-director; spawn in parallel with TD-PHASE-GATE, PR-PHASE-GATE and AD-PHASE-GATE

**触发时机**：在 `/gate-check` 中当 `modes.workflow` 为 `full` 时——评审小组按工作流收窄，只有 full 小组才包含 creative-director；与 TD-PHASE-GATE、PR-PHASE-GATE 和 AD-PHASE-GATE 并行启动

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- List of all artifacts present (file paths)
- Game pillars and core fantasy

**需传入的上下文**：
- 目标阶段名称与解析得到的 `workflow` 层级
- 目标门禁在解析层级下的必需与推荐产物（来自 `/gate-check` 加载的门禁文件）
- 所有已存在产物的清单（文件路径）
- 游戏支柱与核心幻想

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> creative direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given). Are the game pillars
> faithfully represented in the design artifacts this phase requires? Does the
> current state preserve the core fantasy? Do any design decisions in the GDDs,
> architecture or build that exist so far compromise the intended player
> experience?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**提示词**：
> “从创意方向视角评审当前项目状态对 [目标阶段] 门禁的就绪情况，并以该门禁在本层级下的要求（即你收到的必需产物清单）为判断基准。游戏支柱是否在本阶段所需的设计产物中得到忠实体现？当前状态是否保住了核心幻想？迄今已有的 GDD、架构或构建中的任何设计决策，是否损害了预期的玩家体验？
> 某个必需产物被标记为“none”即为一项发现；被标记为“not expected before [phase]”或“not required at `workflow: [tier]`”的，则不算发现。
> 返回 READY、CONCERNS [清单]，或 NOT READY [阻塞项]。”

**Verdicts**: READY / CONCERNS / NOT READY

**裁定**：READY / CONCERNS / NOT READY
