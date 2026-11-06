> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# TD-MANIFEST — Control Manifest Review

# TD-MANIFEST — 控制清单评审

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: After control-manifest rules are extracted and previewed
(`/create-control-manifest` Phase 4), before the manifest file is written

**触发**：在控制清单规则被提取并预览之后（`/create-control-manifest` 第 4 阶段），且在清单文件写入之前

**Context to pass**:
- The Control Manifest Preview from Phase 4 (rule counts per layer, full extracted rule list)
- The list of ADRs covered
- Engine version
- Any rules sourced from `technical-preferences.md` or engine reference docs

**需传入的上下文**：
- 第 4 阶段的控制清单预览（各层规则数量、完整提取的规则列表）
- 所覆盖的 ADR 列表
- 引擎版本
- 任何来自 `technical-preferences.md` 或引擎参考文档的规则

**Prompt**:
> "Review this control manifest before it is written. Are all mandatory ADR
> patterns captured and accurately stated? Are the forbidden approaches complete
> and correctly attributed to their source ADR? Were any rules added that lack a
> source ADR or preference document — that is, invented rather than extracted?
> Are the performance guardrails consistent with the constraints the ADRs
> actually set? Return APPROVE, CONCERNS [list the specific rules to revise], or
> REJECT [rules that are wrong or unsourced and must be fixed before the manifest
> is written]."

**提示词**：
> "在控制清单写入之前评审它。所有强制性的 ADR 模式是否都已捕获且表述准确？禁止采用的做法是否完整，并正确归因到其来源 ADR？是否加入了缺少来源 ADR 或偏好文档的规则——也就是说，是凭空编造而非提取而来的？性能护栏是否与 ADR 实际设定的约束一致？返回 APPROVE、CONCERNS［列出需修订的具体规则］，或 REJECT［错误或无来源、必须在清单写入前修正的规则］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
