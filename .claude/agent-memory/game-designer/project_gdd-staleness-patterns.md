---
name: project-gdd-staleness-patterns
description: Recurring gap types found across this repo's design/gdd/ review sessions — check for these first in any new adversarial review.
metadata:
  type: project
---

Two recurring defect patterns keep showing up in this project's GDDs
(observed during the needs-mood-system.md first full review, 2026-07-10).
Worth checking for on every subsequent `/design-review`.

**Why**: the project's GDDs are authored incrementally and cross-patch each
other's "provisional" markers as sibling systems land same-day — this
creates two specific staleness failure modes.

**How to apply**:

1. **Dependency-table lag behind systems-index status.** When a GDD's own
   Upstream/Downstream table says a dependency is "Undesigned" or lists an
   old status marker (e.g. "✅ Designed"), always cross-check
   `design/gdd/systems-index.md` for the current status — sibling GDDs
   often get authored/approved the same day and the referencing GDD isn't
   patched. Also check that every system mentioned in prose (Interactions
   section) actually has a row in the formal Dependencies table AND the
   Cross-References table — found a case (needs-mood-system.md) where
   `build-validation-navigability.md` was discussed in prose as an upstream
   shelter-flag supplier but was missing from both the Dependencies table
   and Cross-References table.

2. **"Why-string" / player-facing explanation ownership is not reconciled
   across GDDs.** Multiple systems in this project (Needs & Mood, Build
   Validation & Navigability, Villager AI distress flags) each independently
   claim to supply a "why is this wrong" explanation string to the same UI
   slot (Villager Info UI), with no documented precedence/composition rule
   when more than one applies simultaneously, and no mechanism for one
   system to distinguish causes that a sibling system collapses into a
   single category (e.g. Villager AI reports only "bed vs ground" to Needs,
   so Needs cannot tell "no bed owned" apart from "bed owned but villager
   currently unreachable/trapped" — the resulting why-string can be
   actively misleading in the trapped case). Check this seam specifically
   whenever a GDD promises a Pillar-4-style "always show why" contract.
