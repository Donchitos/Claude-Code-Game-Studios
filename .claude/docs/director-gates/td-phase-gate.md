> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-PHASE-GATE — Technical Readiness at Phase Transition

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

**Trigger**: At `/gate-check` when `modes.workflow` is `standard` or `full` — the panel narrows by workflow; spawn in parallel with the rest of it (PR-PHASE-GATE, plus CD-PHASE-GATE and AD-PHASE-GATE at `full`)

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- Architecture document path (if exists)
- Engine reference path
- ADR list

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> technical direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given), not what a later phase will
> need. Is the technical groundwork this phase requires in place and sound —
> entering Systems Design, is the concept feasible on the chosen engine; entering
> Technical Setup, do the systems index and GDDs give enough to architect from;
> entering Pre-Production, is the architecture sound and are the Foundation-layer
> decisions complete enough to begin implementation; entering Production or
> later, is the architecture holding up in the build? Are the high-risk engine
> domains addressed to the depth this phase requires? Are performance budgets
> realistic and documented where this phase requires them?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**Verdicts**: READY / CONCERNS / NOT READY
