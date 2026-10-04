> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# LP-FEASIBILITY — Lead Programmer Implementation Feasibility

Agent: `lead-programmer` | Model tier: Sonnet (Tier 2 lead — invoked when a domain specialist's feasibility sign-off is needed)

**Trigger**: After the master architecture document is written (`/create-architecture`
Phase 7b), or when a new architectural pattern is proposed

**Context to pass**:
- Architecture document path
- Technical requirements baseline summary
- ADR list with statuses

**Prompt**:
> "Review this architecture for implementation feasibility. Flag: (a) any decisions
> that would be difficult or impossible to implement with the stated engine and
> language, (b) any missing interface definitions that programmers would need to
> invent themselves, (c) any patterns that create avoidable technical debt or
> that contradict standard [engine] idioms. Return FEASIBLE, CONCERNS [list], or
> INFEASIBLE [blockers that make this architecture unimplementable as written]."

**Verdicts**: FEASIBLE / CONCERNS / INFEASIBLE
