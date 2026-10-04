> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Technical Setup → Pre-Production


**Required Artifacts:**
- [ ] Engine chosen (CLAUDE.md Technology Stack is not `[CHOOSE]`)
- [ ] Project config populated (`project.yaml` has engine/naming/performance set, or legacy `.claude/docs/technical-preferences.md` populated)
- [ ] Art bible exists at `design/art/art-bible.md` with at least Sections 1–4 (Visual Identity Foundation)
- [ ] At least 3 Architecture Decision Records in `docs/architecture/` covering
      Foundation-layer systems (scene management, event architecture, save/load)
- [ ] Engine reference docs exist in `docs/engine-reference/[engine]/`
- [ ] Test framework initialized: the engine's test root exists — `tests/unit/` and `tests/integration/` (Godot), `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` (Unity), or `Source/<Module>/Private/Tests/` (Unreal); see `.claude/docs/directory-structure.md`
- [ ] CI/CD test workflow exists at `.github/workflows/tests.yml` (or equivalent)
- [ ] At least one example test file exists to confirm the framework is functional
- [ ] Master architecture document exists at `docs/architecture/architecture.md`
- [ ] Architecture traceability index exists at `docs/architecture/requirements-traceability.md`
- [ ] `/architecture-review` has been run (a review report file exists in `docs/architecture/`)
- [ ] `design/accessibility-requirements.md` exists with accessibility tier committed
- [ ] `design/ux/interaction-patterns.md` exists (pattern library initialized, even if minimal)

**Quality Checks:**
- [ ] Architecture decisions cover core systems (rendering, input, state management)
- [ ] Technical preferences have naming conventions and performance budgets set
- [ ] Accessibility tier is defined and documented (even "Basic" is acceptable — undefined is not)
- [ ] At least one screen's UX spec started (often the main menu or core HUD is designed during Technical Setup)
- [ ] All ADRs have an **Engine Compatibility section** with engine version stamped
- [ ] All ADRs have a **GDD Requirements Addressed section** with explicit GDD linkage
- [ ] No ADR references APIs listed in `docs/engine-reference/[engine]/deprecated-apis.md`
- [ ] All HIGH RISK engine domains (per VERSION.md) have been explicitly addressed
      in the architecture document or flagged as open questions
- [ ] Architecture traceability matrix has **zero Foundation layer gaps**
      (all Foundation requirements must have ADR coverage before Pre-Production)

**ADR Circular Dependency Check**: run the deterministic graph builder rather than
reading every ADR to trace the graph by hand — a manual trace across a dozen ADRs
eventually misses an edge; the script cannot:
```
Bash: bash .claude/scripts/adr-dep-graph.sh
```
It prints `ADRS`, `EDGES` (one `adr-A -> adr-B` per Depends-On reference),
`NO_DEPS_SECTION` (ADRs with no Depends On), and a `CYCLE:` line per node in any
dependency cycle.
- **Any `CYCLE:` lines → FAIL**: "Circular ADR dependency: [the nodes on the
  `CYCLE:` lines]. Neither can reach Accepted while the cycle exists. Remove one
  'Depends On' edge to break the cycle."
- No `CYCLE:` lines → this check passes. But the acyclic result is only as
  trustworthy as the dependency sections are complete: if `NO_DEPS_SECTION` lists
  many ADRs, surface that as a CONCERNS note rather than a clean pass.

**Engine Validation** (read `docs/engine-reference/[engine]/VERSION.md` first):
- [ ] ADRs that touch post-cutoff engine APIs are flagged with Knowledge Risk: HIGH/MEDIUM
- [ ] `/architecture-review` engine audit shows no deprecated API usage
- [ ] All ADRs agree on the same engine version (no stale version references)

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — engine + art bible §1–4+ + 3+ ADRs + architecture + UX specs started + accessibility doc + traceability index all required
- **`standard`** — art bible required **only if visual-asset stories exist**; ADRs reduced to **critical (Foundation-layer) only**; UX-specs-started, accessibility doc, interaction-patterns, traceability index → recommended
- **`minimal`** — only **engine configured** required (the minimal floor); everything else **drops**
