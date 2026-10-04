> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-MANIFEST — Control Manifest Review

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

**Trigger**: After control-manifest rules are extracted and previewed
(`/create-control-manifest` Phase 4), before the manifest file is written

**Context to pass**:
- The Control Manifest Preview from Phase 4 (rule counts per layer, full extracted rule list)
- The list of ADRs covered
- Engine version
- Any rules sourced from `technical-preferences.md` or engine reference docs

**Prompt**:
> "Review this control manifest before it is written. Are all mandatory ADR
> patterns captured and accurately stated? Are the forbidden approaches complete
> and correctly attributed to their source ADR? Were any rules added that lack a
> source ADR or preference document — that is, invented rather than extracted?
> Are the performance guardrails consistent with the constraints the ADRs
> actually set? Return APPROVE, CONCERNS [list the specific rules to revise], or
> REJECT [rules that are wrong or unsourced and must be fixed before the manifest
> is written]."

**Verdicts**: APPROVE / CONCERNS / REJECT
