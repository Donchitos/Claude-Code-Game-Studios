> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-SYSTEM-BOUNDARY — System Boundary Architecture Review

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

**Trigger**: After `/map-systems` Phase 3 dependency mapping is agreed but before
GDD authoring begins — validates that the system structure is architecturally
sound before teams invest in writing GDDs against it

**Context to pass**:
- Systems index path (or the dependency map summary if index not yet written)
- Layer assignments (Foundation / Core / Feature / Presentation / Polish)
- The full dependency graph (what each system depends on)
- Any bottleneck systems flagged (many dependents)
- Any circular dependencies found and their proposed resolutions

**Prompt**:
> "Review this systems decomposition from an architectural perspective before GDD
> authoring begins. Are the system boundaries clean — does each system own a
> distinct concern with minimal overlap? Are there God Object risks (systems doing
> too much)? Does the dependency ordering create implementation-sequencing problems?
> Are there implicit shared-state problems in the proposed boundaries that will
> cause tight coupling when implemented? Are any Foundation-layer systems actually
> dependent on Feature-layer systems (inverted dependency)? Return APPROVE
> (boundaries are architecturally sound — proceed to GDD authoring), CONCERNS
> [specific boundary issues to address in the GDDs themselves], or REJECT
> [fundamental boundary problems — the system structure will cause architectural
> issues and must be restructured before any GDD is written]."

**Verdicts**: APPROVE / CONCERNS / REJECT
