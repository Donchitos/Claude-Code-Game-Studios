# /adopt — Phase 4: Build the Migration Plan

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Build the Migration Plan

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, infrastructure before GDD/ADR content (bootstrapping needs correct formats)
3. MEDIUM gaps ordered: GDD gaps before ADR gaps before story gaps (stories depend on GDDs and ADRs)
4. LOW gaps last

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

**Special case — systems-index parenthetical status values:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately before writing the plan.

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/adr-[NNNN]-[slug].md`
List each ADR as a separate checkable item.

**Special case — GDDs missing sections:**
For each affected GDD, list which sections are missing and the fix:
`/design-system retrofit design/gdd/[filename].md`

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Fix ADR formats first (registry depends on reading ADR Status fields)
2. Run `/architecture-review` → bootstraps `tr-registry.yaml`
3. Run `/create-control-manifest` → creates manifest with version stamp
4. Run `/sprint-plan update` → creates `sprint-status.yaml`
5. Run `/gate-check [phase]` (the gate into the phase the project is in; at Concept there is none — Concept is the default stage, nothing to run) → writes `project.stage` in `project.yaml` (and legacy `stage.txt`) authoritatively

**At `workflow: minimal` the plan prescribes none of this sequence.** None of it
is on the minimal path: ADRs are not expected, the brief's build order is the
plan (no `/sprint-plan`), and nothing there runs `/gate-check`. The plan's
Step 3 says so in one line and names the path's next step instead —
`/create-stories` when no stories exist, else `/dev-story`.

**Existing stories** — note explicitly:
> "Existing stories continue to work with all template skills — all new format
> checks auto-pass when the fields are absent. They won't benefit from TR-ID
> staleness tracking or manifest version checks until they're regenerated. This
> is intentional: do not regenerate stories that are already in progress."

---
