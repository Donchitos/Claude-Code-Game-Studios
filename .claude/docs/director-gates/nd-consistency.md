> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# ND-CONSISTENCY — Narrative Director Consistency Check

Agent: `narrative-director` | Model tier: session (inherit)

**Trigger**: After writer deliverables (dialogue, lore, item descriptions) are
authored, or when a design decision has narrative implications

**Context to pass**:
- Document or content file path(s)
- Narrative bible or tone guide path (if exists)
- Relevant world-building rules
- Character or faction profiles affected

**Prompt**:
> "Review this narrative content for internal consistency and adherence to
> established world rules. Are character voices consistent with their established
> profiles? Does the lore contradict any established facts? Is the tone consistent
> with the game's narrative direction? Return APPROVE, CONCERNS [specific
> inconsistencies to fix], or REJECT [contradictions that break the narrative
> foundation]."

**Verdicts**: APPROVE / CONCERNS / REJECT
