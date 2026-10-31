# /adopt — Phase 3: Classify and Prioritise Gaps

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Classify and Prioritise Gaps

Organise every gap found across all audits into four severity tiers:

**BLOCKING** — Will cause template skills to silently produce wrong results *right now*.
Examples: ADR missing Status field, systems-index parenthetical status values,
engine not configured when ADRs exist.

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing Engine Compatibility, GDDs missing Acceptance Criteria
(stories can't be generated from them), tr-registry.yaml missing.

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: GDDs missing Tuning Knobs or Formulas sections, stories missing TR-IDs,
sprint-status.yaml missing.

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: Stories missing Manifest Version stamps, GDDs missing Open Questions section.

Count totals per tier. If zero BLOCKING and zero HIGH gaps: report that the project
is template-compatible and only advisory improvements remain.

---
