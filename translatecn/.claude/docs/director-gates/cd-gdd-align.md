> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# CD-GDD-ALIGN — GDD Pillar Alignment Check

# CD-GDD-ALIGN — GDD 支柱对齐检查

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

智能体：`creative-director` | 模型层级：Opus | 领域：愿景、支柱、玩家体验

**Trigger**: After a system GDD is authored (design-system, or any workflow that
produces a GDD)

**触发时机**：系统 GDD 撰写完成后（design-system，或任何产出 GDD 的工作流）

**Context to pass**:
- GDD file path
- Game pillars (from `design/gdd/game-concept.md` or `design/gdd/game-pillars.md`; if there is neither, `design/game-brief.md` has no pillars — pass its pitch and "what they feel" line)
- MDA aesthetics target for this game
- System's stated Player Fantasy section

**需传入的上下文**：
- GDD 文件路径
- 游戏支柱（来自 `design/gdd/game-concept.md` 或 `design/gdd/game-pillars.md`；若两者皆无，`design/game-brief.md` 中没有支柱——传入其电梯陈述与“what they feel”一行）
- 本游戏的 MDA 美学目标
- 系统所述的 Player Fantasy 章节

**Prompt**:
> "Review this system GDD for pillar alignment. Does every section serve the stated
> pillars? Are there mechanics or rules that contradict or weaken a pillar? Does
> the Player Fantasy section match the game's core fantasy? Return APPROVE, CONCERNS
> [specific sections with issues], or REJECT [pillar violations that must be
> redesigned before this system is implementable]."

**提示词**：
> “评审此系统 GDD 的支柱对齐情况。每个章节是否都服务于所述的支柱？是否存在与某支柱相矛盾或削弱它的机制或规则？Player Fantasy 章节是否与游戏的核心幻想相符？返回 APPROVE、CONCERNS [存在问题的具体章节]，或 REJECT [必须在本系统可实施之前重新设计的支柱违背]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
