> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-EPIC — Epic Structure Feasibility Review

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: After epics are defined by `/create-epics`, before stories are
broken out — validates the epic structure is producible before `/create-stories`
is invoked

**Context to pass**:
- The epic structure for the layer, inline — every epic's scope summary and
  governing-ADR count. `/create-epics` runs this gate *before* writing any epic
  file, so there are no paths yet.
- Milestone timeline and target dates
- Team capacity (solo / small team / size)
- Layer being epiced (Foundation / Core / Feature / etc.)

**Prompt**:
> "Review this epic structure for production feasibility before story breakdown
> begins. Are the epic boundaries scoped appropriately — could each epic realistically
> complete before a milestone deadline? Are epics correctly ordered by system
> dependency — does any epic require another epic's output before it can start?
> Are any epics underscoped (too small, should merge) or overscoped (too large,
> should split into 2-3 focused epics)? Are the Foundation-layer epics scoped to
> allow Core-layer epics to begin at the start of the next sprint after Foundation
> completes? Return REALISTIC (epic structure is producible), CONCERNS [specific
> structural adjustments before stories are written], or UNREALISTIC [epics must
> be split, merged, or reordered — story breakdown cannot begin until resolved]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC
