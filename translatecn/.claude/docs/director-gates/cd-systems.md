> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# CD-SYSTEMS — Systems Decomposition Vision Check

# CD-SYSTEMS — 系统分解的愿景检查

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

智能体：`creative-director` | 模型层级：Opus | 领域：愿景、支柱、玩家体验

**Trigger**: After the systems index is written by `/map-systems` — validates the
complete system set before GDD authoring begins

**触发**：在 `/map-systems` 写入系统索引之后——在 GDD 撰写开始之前，验证完整的系统集合

**Context to pass**:
- Systems index path (`design/gdd/systems-index.md`)
- Game pillars and core fantasy (from `design/gdd/game-concept.md`; if there is no `design/gdd/game-concept.md`, the pitch and "what they feel" line of `design/game-brief.md`, which has no pillars)
- Priority tier assignments (MVP / Vertical Slice / Alpha / Full Vision)
- Any high-risk or bottleneck systems identified in the dependency map

**需传入的上下文**：
- 系统索引路径（`design/gdd/systems-index.md`）
- 游戏支柱与核心幻想（来自 `design/gdd/game-concept.md`；若没有 `design/gdd/game-concept.md`，则取 `design/game-brief.md` 中的推介语与“他们的感受”一行，该文件没有支柱）
- 优先级层级划分（MVP / Vertical Slice / Alpha / Full Vision）
- 依赖图谱中识别出的任何高风险或瓶颈系统

**Prompt**:
> "Review this systems decomposition against the game's design pillars. Does the
> full set of MVP-tier systems collectively deliver the core fantasy? Are there
> systems whose mechanics don't serve any stated pillar — indicating they may be
> scope creep? Are there pillar-critical player experiences that have no system
> assigned to deliver them? Are any systems missing that the core loop requires?
> Return APPROVE (systems serve the vision), CONCERNS [specific gaps or
> misalignments with their pillar implications], or REJECT [fundamental gaps —
> the decomposition misses critical design intent and must be revised before GDD
> authoring begins]."

**提示词**：
> "对照游戏的设计支柱，评审这份系统分解。完整的 MVP 层级系统集合是否共同交付了核心幻想？是否存在其机制不服务于任何既定支柱的系统——这表明它们可能是范围蔓延？是否存在对支柱至关重要的玩家体验，却没有分配任何系统去交付？是否存在核心循环所需但缺失的系统？返回 APPROVE（系统服务于愿景）、CONCERNS［具体的缺口或错位及其支柱含义］，或 REJECT［根本性缺口——该分解遗漏了关键设计意图，必须在 GDD 撰写开始前修订］。"

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
