> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Concept → Systems Design


**Required Artifacts:**
- [ ] `design/gdd/game-concept.md` exists and has content
- [ ] Game pillars defined (in concept doc or `design/gdd/game-pillars.md`)
- [ ] Visual Identity Anchor section exists in `design/gdd/game-concept.md` (from brainstorm Phase 4 art-director output)

**Recommended (not blocking):**
- [ ] Concept prototype exists in `prototypes/` with a REPORT.md showing PROCEED verdict
      (`/prototype [core-mechanic]`) — skipping this means GDDs may be written for an
      idea that hasn't been played. Acceptable if the concept is proven by other means.

**Quality Checks:**
- [ ] Game concept has been reviewed (`/design-review` verdict not MAJOR REVISION NEEDED)
- [ ] Core loop is described and understood
- [ ] Target audience is identified
- [ ] Visual Identity Anchor contains a one-line visual rule and at least 2 supporting visual principles

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — game-concept.md + pillars + Visual Identity Anchor all required
- **`standard`** — pillars + Visual Identity Anchor → recommended; `game-concept.md` stays required
- **`minimal`** — gate target is **`design/game-brief.md`** (not `game-concept.md`); the GDD / pillars / Visual Identity Anchor checks **drop** (a brief with content = PASS). `/brainstorm` writes `design/game-brief.md` at this tier (Option A); `game-concept.md` remains the `standard`/`full` concept doc.
