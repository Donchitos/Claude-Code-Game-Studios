> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# CD-PLAYTEST — Player Experience Validation

# CD-PLAYTEST — 玩家体验验证

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

智能体：`creative-director` | 模型层级：Opus | 领域：愿景、支柱、玩家体验

**Trigger**: After playtest reports are generated (`/playtest-report`), or after
any session that produces player feedback

**触发**：在试玩报告生成之后（`/playtest-report`），或在任何产出玩家反馈的测试场次之后

**Context to pass**:
- Playtest report — its file path, or its content inline when the calling skill
  reviews before saving (`/playtest-report` does)
- Game pillars and core fantasy statement
- The specific hypothesis being tested

**需传入的上下文**：
- 试玩报告——其文件路径；或当调用技能在保存前进行评审时（`/playtest-report` 会这样做），直接内联其内容
- 游戏支柱与核心幻想陈述
- 正在测试的具体假设

**Prompt**:
> "Review this playtest report against the game's design pillars and core fantasy.
> Is the player experience matching the intended fantasy? Are there systematic issues
> that represent pillar drift — mechanics that feel fine in isolation but undermine
> the intended experience? Return APPROVE (core fantasy is landing), CONCERNS [gaps
> between intended and actual experience], or REJECT [core fantasy is not present —
> redesign needed before further playtesting]."

**提示词**：
> "对照游戏的设计支柱与核心幻想，评审这份试玩报告。玩家体验是否符合预期的幻想？是否存在系统性问题，体现出支柱漂移——即某些机制单独看没问题，却削弱了预期体验？返回 APPROVE（核心幻想已落地）、CONCERNS［预期体验与实际体验之间的差距］，或 REJECT［核心幻想未体现——需在进一步试玩前重新设计］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
