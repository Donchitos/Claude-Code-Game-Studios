# /prototype — Phase 9: Summary and Next Steps

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 9: Summary and Next Steps

Output a summary: the hypothesis, the result, and the final recommendation.
Link to `prototypes/[concept-name]-concept/REPORT.md`.

**If PROCEED:**
Your concept prototype validated the core idea. Now design it properly, informed by
what you just learned.

At `workflow: minimal`: `/create-stories` (from the brief), then `/dev-story`
on the first story — the rest of this list is the `standard`/`full` path.

Recommended path (in order, `standard`/`full`):
1. `/design-review design/gdd/game-concept.md` — validate the concept doc against what the prototype revealed
2. `/gate-check` — confirm readiness to advance to Systems Design
3. `/art-bible` — define visual identity (optional but worth doing before GDDs)
4. `/map-systems` — decompose the concept into all game systems
5. `/design-system [mechanic]` — GDD for each MVP system; use prototype learnings
   in the Tuning Knobs and Formulas sections
6. `/review-all-gdds` — cross-system consistency check

**Note:** If you used the HTML path and feel is still uncertain, consider running
a quick engine path prototype targeting feel before writing GDDs.

**If PIVOT:**

Before routing to the next prototype, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

1. "What specifically worked in this prototype that we should preserve in the next version?"
2. "What is the single most important thing to change?"

Ask: "May I write this to `prototypes/[concept-name]-concept/PIVOT-NOTE.md`?"

If yes, write the file with: original hypothesis, what to keep, what to change, and
the revised hypothesis for the next prototype. The next `/prototype` run picks it
up at the start of Phase 1.

- Run `/prototype [revised-concept]` to test the adjusted direction
- Or `/brainstorm [hint]` if the concept needs more fundamental rethinking

**If KILL:**

Before moving on, run this check to confirm the verdict is sound and not temporary frustration:

- [ ] Core mechanic still unclear to testers after 2+ playtests?
- [ ] No "fun moment" (smile, laugh, or retry by choice) observed in any session?
- [ ] 3+ PIVOT iterations on the same concept with no clear improvement?
- [ ] Concept only works when heavily explained or when the dev guides the player?
- [ ] Building this feels like obligation, not excitement?

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → consider one more focused PIVOT before killing.

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this concept to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

```
## [Concept Name] — YYYY-MM-DD
- **Kill reason:** [specific blocker — not "it was boring" but "players never understood the core action"]
- **What worked:** [2-3 things worth carrying forward to future concepts]
- **What failed:** [the specific mechanic, design decision, or scope issue]
- **Next time:** [one explicit action to try differently on a similar concept]
```

This file exists so the same mistake doesn't get made twice on the next concept.

- Run `/brainstorm open` or `/brainstorm [new-hint]` to explore a different concept
- The prototype report is the deliverable — no further action needed

**If NOT ASSESSED (nobody has played it):**

There is no fun evidence yet, so PROCEED, PIVOT and KILL are all unreachable —
report NOT ASSESSED and stop here rather than guess.

- Play it, then run `/prototype [same concept]` again
- The report and the concept index row read NOT ASSESSED until a playtest happens

---

---
