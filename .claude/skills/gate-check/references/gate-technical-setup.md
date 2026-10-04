> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Systems Design → Technical Setup


**Required Artifacts:**
- [ ] Systems index exists at `design/gdd/systems-index.md` with at least MVP systems enumerated
- [ ] All MVP-tier GDDs exist in `design/gdd/` and individually pass `/design-review`
- [ ] A cross-GDD review report exists in `design/gdd/` (from `/review-all-gdds`)

**Quality Checks:**
- [ ] All MVP GDDs pass individual design review (8 required sections, no MAJOR REVISION NEEDED verdict)
- [ ] `/review-all-gdds` verdict is not FAIL (cross-GDD consistency and design theory checks pass). A NOT ASSESSED verdict does not satisfy this: that review could not compare the GDDs, so this item is NOT ASSESSED for the gate
- [ ] All cross-GDD consistency issues flagged by `/review-all-gdds` are resolved or explicitly accepted
- [ ] System dependencies are mapped in the systems index and are bidirectionally consistent
- [ ] MVP priority tier is defined
- [ ] No stale GDD references flagged (older GDDs updated to reflect decisions made in later GDDs)

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — systems-index + all MVP GDDs at 8 sections + cross-GDD review report all required
- **`standard`** — MVP GDDs validated at the **5 standard sections** (+ conditional Formulas); cross-GDD review report → recommended
- **`minimal`** — **gate not applicable** — no gate between brief and code; auto-PASS with a note (see below)

> **`minimal` "not applicable" gate.** The Systems Design → Technical Setup gate
> has no meaning at `minimal` (no GDDs exist by design). Return a PASS verdict
> with the note: *"No design gate at minimal workflow — minimal skips the
> Systems Design phase; advancing brief → code."* The Section 6 stage write still
> applies on user confirmation. Do NOT flag absent GDDs as blockers. This is the
> named exception to Section 2b's rule that a gate with no required artifacts left
> may not PASS; the director panel does not run for it.
