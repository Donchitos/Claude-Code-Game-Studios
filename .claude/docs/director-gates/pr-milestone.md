> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-MILESTONE — Milestone Risk Assessment

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: At milestone review (`/milestone-review`), or when a scope change is
proposed that affects the milestone

**Context to pass**:
- Milestone definition and target date
- Current completion percentage
- Blocked stories count
- Sprint velocity data (if available)

**Prompt**:
> "Review this milestone status. Based on current velocity and blocked story count,
> will this milestone hit its target date? What are the top 3 production risks
> between now and the milestone? Are there scope items that should be cut to protect
> the milestone date vs. items that are non-negotiable? Return ON TRACK, AT RISK
> [specific mitigations], or OFF TRACK [date must slip or scope must cut — provide
> both options]."

**Verdicts**: ON TRACK / AT RISK / OFF TRACK
