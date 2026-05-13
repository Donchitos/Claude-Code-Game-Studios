# Concept Prototype Report: [Concept Name]

> **Date**: [YYYY-MM-DD]
> **Prototype Path**: [HTML / Engine / Paper]
> **Concept File**: design/gdd/game-concept.md (if exists)

---

## Hypothesis

[The falsifiable hypothesis this prototype set out to test:
"If the player [does X], they will feel [Y] — evidenced by [measurable signal Z]."]

---

## Riskiest Assumption Tested

[What was identified as the biggest risk in the concept, and whether it proved out.]

---

## Approach

[What was built, how long it took, what shortcuts were taken deliberately.]

**Path chosen:** [HTML / Engine / Paper]
**Reason for path:** [Why this path was appropriate for this hypothesis]

**Shortcuts taken (intentional):**
- [e.g., hardcoded values, placeholder art, no menus, etc.]

---

## Result

[What actually happened — specific observations, not opinions. Quote playtesters
directly where possible.]

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | [HTML / Engine / Paper] |
| Iterations to playable | [N — Engine path only; N/A otherwise] |
| Prototype duration | [e.g., 4 hours] |
| Playtesters | [N internal / N external] |
| Feel assessment | [Specific — "response felt sluggish at 200ms" not "felt bad"] |
| Hypothesis verdict | [CONFIRMED / PARTIALLY CONFIRMED / REFUTED] |

---

## Recommendation: [PROCEED / PIVOT / KILL]

[One paragraph explaining the recommendation with evidence from the result above.]

---

## If Proceeding

[What the prototype revealed that should directly inform GDD writing:]

- **Core tuning values discovered:** [e.g., "jump height of 3.5 units felt best"]
- **Assumptions confirmed:** [What the concept doc assumed that proved true]
- **Assumptions disproved:** [What the concept doc assumed that proved wrong]
- **Emergent mechanics:** [Behaviors that appeared during testing worth formalizing]

> Note: If HTML path was used and feel is uncertain, consider an engine prototype
> targeting feel specifically before committing to GDDs.

**Next steps:**
1. `/design-review design/gdd/game-concept.md`
2. `/gate-check`
3. `/map-systems`
4. `/design-system [mechanic]` (use learnings in Tuning Knobs and Formulas sections)

---

## If Pivoting

[What alternative direction the results suggest — what felt almost right and what
to adjust. Be specific about what to change, not just that something needs changing.]

**Pivot direction:** [What to try differently]
**What to keep:** [What worked and should be preserved]
**Next step:** `/prototype [revised-concept]`

---

## If Killing

[Why this concept does not work — what specific signal led to this verdict.
This report is the deliverable; no further action needed on this concept.]

**Next step:** `/brainstorm [new-direction]`

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  [...]

- **What surprised us that didn't show up in the brainstorm?**
  [...]

- **What would we test differently next time?**
  [...]

---

> *Prototype code location: `prototypes/[concept-name]-concept/`*
> *This code is throwaway. Never refactor into production.*
