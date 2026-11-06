> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# CD-NARRATIVE — Narrative Consistency Check

# CD-NARRATIVE — 叙事一致性检查

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

智能体：`creative-director` | 模型层级：Opus | 领域：愿景、支柱、玩家体验

**Trigger**: Invoked directly, after narrative GDDs, lore documents, dialogue specs
or world-building documents are authored — no skill spawns it; `/team-narrative`
runs its own review, ND-CONSISTENCY

**触发**：直接调用，在叙事 GDD、背景传说文档、对话规格或世界观构建文档撰写完成之后——没有技能会发起它；`/team-narrative` 运行自己的评审 ND-CONSISTENCY

**Context to pass**:
- Document file path(s)
- Game pillars
- Narrative direction brief or tone guide (if exists at `design/narrative/`)
- Any existing lore that the new document references

**需传入的上下文**：
- 文档文件路径（一个或多个）
- 游戏支柱
- 叙事方向简报或语调指南（若 `design/narrative/` 下存在）
- 新文档所引用的任何既有背景传说

**Prompt**:
> "Review this narrative content for consistency with the game's pillars and
> established world rules. Does the tone match the game's established voice? Are
> there contradictions with existing lore or world-building? Does the content serve
> the player experience pillar? Return APPROVE, CONCERNS [specific inconsistencies],
> or REJECT [contradictions that break world coherence]."

**提示词**：
> "评审这份叙事内容，检查其与游戏支柱及既定世界规则的一致性。语调是否与游戏既定的声音相符？是否与既有背景传说或世界观构建存在矛盾？内容是否服务于玩家体验支柱？返回 APPROVE、CONCERNS［具体的不一致之处］，或 REJECT［破坏世界连贯性的矛盾］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
