> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CD-SYSTEMS — Systems Decomposition Vision Check

Agent: `creative-director` | Model tier: Opus | Domain: Vision, pillars, player experience

**Trigger**: After the systems index is written by `/map-systems` — validates the
complete system set before GDD authoring begins

**Context to pass**:
- Systems index path (`design/gdd/systems-index.md`)
- Game pillars and core fantasy (from `design/gdd/game-concept.md`; if there is no `design/gdd/game-concept.md`, the pitch and "what they feel" line of `design/game-brief.md`, which has no pillars)
- Priority tier assignments (MVP / Vertical Slice / Alpha / Full Vision)
- Any high-risk or bottleneck systems identified in the dependency map

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

**Verdicts**: APPROVE / CONCERNS / REJECT
