> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# ND-CONSISTENCY — Narrative Director Consistency Check

# ND-CONSISTENCY — 叙事总监一致性检查

Agent: `narrative-director` | Model tier: session (inherit)

智能体：`narrative-director` | 模型层级：session（继承）

**Trigger**: After writer deliverables (dialogue, lore, item descriptions) are
authored, or when a design decision has narrative implications

**触发时机**：编剧交付物（对白、设定、物品描述）撰写完成后，或某项设计决策具有叙事影响时

**Context to pass**:
- Document or content file path(s)
- Narrative bible or tone guide path (if exists)
- Relevant world-building rules
- Character or faction profiles affected

**需传入的上下文**：
- 文档或内容文件路径
- 叙事圣经或基调指南路径（若存在）
- 相关的世界构建规则
- 受影响的角色或阵营档案

**Prompt**:
> "Review this narrative content for internal consistency and adherence to
> established world rules. Are character voices consistent with their established
> profiles? Does the lore contradict any established facts? Is the tone consistent
> with the game's narrative direction? Return APPROVE, CONCERNS [specific
> inconsistencies to fix], or REJECT [contradictions that break the narrative
> foundation]."

**提示词**：
> “评审此叙事内容的内部一致性，及其对既定世界规则的遵循。角色声音是否与其既定档案一致？设定是否与任何既定事实相矛盾？基调是否与游戏的叙事方向一致？返回 APPROVE、CONCERNS [需要修正的具体不一致]，或 REJECT [动摇叙事根基的矛盾]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
