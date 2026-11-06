> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# AD-ART-BIBLE — Art Bible Sign-Off

# AD-ART-BIBLE — 美术圣经签核

Agent: `art-director` | Model tier: session (inherit) | Domain: Visual identity, art bible, visual production readiness

智能体：`art-director` | 模型层级：session（继承）| 领域：视觉识别、美术圣经、视觉制作就绪度

**Trigger**: After the art bible is drafted (`/art-bible`), before asset production begins

**触发时机**：美术圣经起草完成后（`/art-bible`）、资产制作开始之前

**Context to pass**:
- Art bible path (`design/art/art-bible.md`)
- Game pillars and core fantasy
- Platform and performance constraints (`platform.*` and `performance.*` from `project.yaml`, falling back to `.claude/docs/technical-preferences.md`)
- Visual identity anchor chosen during brainstorm (from `design/gdd/game-concept.md`; if there is no `design/gdd/game-concept.md`, pass the "Art & audio direction" line of `design/game-brief.md` instead)

**需传入的上下文**：
- 美术圣经路径（`design/art/art-bible.md`）
- 游戏支柱与核心幻想
- 平台与性能约束（`project.yaml` 中的 `platform.*` 与 `performance.*`，缺失时回退到 `.claude/docs/technical-preferences.md`）
- 头脑风暴阶段选定的视觉识别锚点（来自 `design/gdd/game-concept.md`；若无 `design/gdd/game-concept.md`，则改为传入 `design/game-brief.md` 中的“Art & audio direction”一行）

**Prompt**:
> "Review this art bible for completeness and internal consistency. Does the color
> system match the mood targets? Does the shape language follow from the visual
> identity statement? Are the asset standards achievable within the platform
> constraints? Does the character design direction give artists enough to work from
> without over-specifying? Are there contradictions between sections? Would an
> outsourcing team be able to produce assets from this document without additional
> briefing? Return APPROVE (art bible is production-ready), CONCERNS [specific
> sections needing clarification], or REJECT [fundamental inconsistencies that must
> be resolved before asset production begins]."

**提示词**：
> “评审这份美术圣经的完整性与内部一致性。色彩系统是否与情绪目标匹配？形状语言是否由视觉识别宣言推导而来？资产标准在平台约束下是否可达成？角色设计方向是否能为美术人员提供足够依据、又不过度规定？各部分之间是否存在矛盾？外包团队能否仅凭本文档、无需额外说明即可产出资产？返回 APPROVE（美术圣经已可投入制作）、CONCERNS [需要澄清的具体章节]，或 REJECT [必须在资产制作开始前解决的根本性不一致]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
