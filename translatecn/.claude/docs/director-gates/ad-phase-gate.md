> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# AD-PHASE-GATE — Visual Readiness at Phase Transition

# AD-PHASE-GATE — 阶段转换时的视觉就绪度

Agent: `art-director` | Model tier: session (inherit) | Domain: Visual identity, art bible, visual production readiness

智能体：`art-director` | 模型层级：session（继承）| 领域：视觉识别、美术圣经、视觉制作就绪度

**Trigger**: At `/gate-check` when `modes.workflow` is `full` — the panel narrows by workflow, and only the full panel includes art-director; spawn in parallel with CD-PHASE-GATE, TD-PHASE-GATE, and PR-PHASE-GATE

**触发时机**：在 `/gate-check` 中当 `modes.workflow` 为 `full` 时——评审小组按工作流收窄，只有 full 小组才包含 art-director；与 CD-PHASE-GATE、TD-PHASE-GATE 和 PR-PHASE-GATE 并行启动

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- List of all art/visual artifacts present (file paths)
- Visual identity anchor from `design/gdd/game-concept.md` (if present; if there is no `design/gdd/game-concept.md`, the "Art & audio direction" line of `design/game-brief.md`)
- Art bible path if it exists (`design/art/art-bible.md`)

**需传入的上下文**：
- 目标阶段名称与解析得到的 `workflow` 层级
- 目标门禁在解析层级下的必需与推荐产物（来自 `/gate-check` 加载的门禁文件）
- 所有已存在的美术/视觉产物清单（文件路径）
- 来自 `design/gdd/game-concept.md` 的视觉识别锚点（若存在；若无 `design/gdd/game-concept.md`，则取 `design/game-brief.md` 中的“Art & audio direction”一行）
- 美术圣经路径（若存在）（`design/art/art-bible.md`）

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a visual
> direction perspective, judged against what this gate requires at this tier (the
> required-artifacts list you were given). Is the visual identity established and
> documented at the level this phase requires? Are the visual artifacts this phase
> requires in place? Would visual teams be able to begin their work without
> visual direction gaps that cause costly rework later? Are there visual
> decisions that are being deferred past their latest responsible moment?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [specific visual direction gaps that could cause
> production rework], or NOT READY [visual blockers that must exist before this
> phase can succeed — specify what artifact is missing and why it matters at
> this stage]."

**提示词**：
> “从视觉方向视角评审当前项目状态对 [目标阶段] 门禁的就绪情况，并以该门禁在本层级下的要求（即你收到的必需产物清单）为判断基准。视觉识别是否已按本阶段要求的水平建立并形成文档？本阶段所需的视觉产物是否已经到位？视觉团队能否在不存在、且日后会导致高昂返工的视觉方向空白的情况下开始工作？是否存在被推迟到“最晚尽责时刻”之后的视觉决策？
> 某个必需产物被标记为“none”即为一项发现；被标记为“not expected before [phase]”或“not required at `workflow: [tier]`”的，则不算发现。
> 返回 READY、CONCERNS [可能导致制作返工的具体视觉方向空白]，或 NOT READY [本阶段要成功必须先具备的视觉阻塞项——指明缺失哪项产物，以及它为何在此阶段重要]。”

**Verdicts**: READY / CONCERNS / NOT READY

**裁定**：READY / CONCERNS / NOT READY
