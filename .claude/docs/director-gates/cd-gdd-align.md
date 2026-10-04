> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CD-GDD-ALIGN — GDD Pillar Alignment Check

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

**Trigger**: After a system GDD is authored (design-system, or any workflow that
produces a GDD)

**Context to pass**:
- GDD file path
- Game pillars (from `design/gdd/game-concept.md` or `design/gdd/game-pillars.md`; if there is neither, `design/game-brief.md` has no pillars — pass its pitch and "what they feel" line)
- MDA aesthetics target for this game
- System's stated Player Fantasy section

**Prompt**:
> "Review this system GDD for pillar alignment. Does every section serve the stated
> pillars? Are there mechanics or rules that contradict or weaken a pillar? Does
> the Player Fantasy section match the game's core fantasy? Return APPROVE, CONCERNS
> [specific sections with issues], or REJECT [pillar violations that must be
> redesigned before this system is implementable]."

**Verdicts**: APPROVE / CONCERNS / REJECT
