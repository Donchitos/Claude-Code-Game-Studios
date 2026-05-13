# Vertical Slice Report: [Concept Name]

> **Date**: [YYYY-MM-DD]
> **Slice Duration**: [N days]
> **Target Scope**: 3–5 minutes of polished, continuous gameplay
> **Source GDD**: design/gdd/game-concept.md

---

## Validation Question

[The full game loop question this build was proving — both experience AND feasibility:
"Does a player, starting from nothing, experience [core fantasy] within [N] minutes,
without developer guidance — and can we build one such loop in [X] days at
representative quality?"]

---

## Scope Built

[Systems implemented, art quality level, what was intentionally omitted.]

**Systems included:**
- [System 1]
- [System 2]
- [...]

**Art/audio quality level:** [Placeholder / Representative / Near-shipping]
**Shortcuts taken deliberately:** [List]
**What was cut from original scope:** [List]

---

## Build Velocity Log

[Day-by-day record of what was completed. This is your real production rate data —
use it in sprint planning.]

| Day | Completed |
|-----|-----------|
| Day 1 | [What was built] |
| Day 2 | [What was built] |
| Day 3 | [What was built] |
| ... | ... |

**Total elapsed:** [N days] for [scope summary]
**Velocity estimate:** [N hours per equivalent scope unit — e.g., "1 day per combat
encounter, 0.5 days per UI screen"]

---

## Playtest Results

| Attribute | Value |
|-----------|-------|
| Total sessions | [N] |
| Internal testers | [N] |
| External testers | [N — people who had not seen the game, if available] |
| Avg session length | [N minutes (target: [N] minutes)] |
| Time to first meaningful action | [N seconds (target: [N] seconds)] |

---

## Observations

[Specific, non-opinion observations from playtest sessions. Quote testers where useful.]

**Where testers succeeded without guidance:**
- [...]

**Where testers were confused or stuck:**
- [...]

**Emotional reactions observed:**
- [...]

---

## Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Time to first meaningful action | [N sec] | [N sec] |
| Session length | [N min] | [N min] |
| Critical fun blockers found | 0 | [N] |
| Pipeline blockers found | 0 | [N] |
| Architecture surprises | 0 | [N] |

**Feel assessment:** [Specific — "combat feedback weak; no impact sound on hit" not "felt rough"]

---

## Recommendation: [PROCEED / PIVOT / KILL]

[One paragraph with evidence — reference the validation question directly. Did a
player experience the core fantasy within the target time, without developer guidance?
Can the team build at this quality on the projected schedule?]

---

## If Proceeding

**Production requirements** (what must change from slice to production):
- [e.g., "Replace placeholder art with shipped assets"]
- [e.g., "Combat system needs 2 more weapon types"]

**Architecture adjustments needed:**
- [ADR to update or create]

**Sprint velocity estimate based on slice data:**
- [e.g., "1 day per enemy type, 2 days per level section, 0.5 days per UI screen"]

**Scope adjustments from original design:**
- [What the slice revealed about the true production scope]

**Performance targets:** [Confirmed / Revised — list changes if revised]

**Playtest note:** Run `/playtest-report` to structure additional session data
before running `/gate-check pre-production`.

**Next steps:**
1. `/gate-check pre-production` — formally advance to Production
2. `/create-epics layer:foundation` — plan Foundation layer epics
3. `/create-epics layer:core` — plan Core layer epics
4. `/sprint-plan` — use velocity data from this report in the estimate

---

## If Pivoting

[Which GDDs need revision and why — be specific about the failure mode observed.]

**Systems requiring GDD revision:** [List]
**Architecture decisions to revisit:** [List — use `/architecture-decision` to update]
**Core loop change needed:** [What specifically to change]

**Next steps:**
1. `/design-system [mechanic]` — revise affected GDDs
2. `/architecture-decision [decision]` — address architecture issues
3. `/vertical-slice` — re-validate after revisions

---

## If Killing

[Why the full game loop does not work at this quality level. What specifically
prevented the player from experiencing the core fantasy. What to do instead.]

**Next step:** `/brainstorm` to explore a new direction, or `/prototype [new-concept]`
to test a different concept cheaply before investing in another vertical slice.

---

## Lessons Learned

- **What assumptions were broken by building to near-production quality?**
  [...]

- **What surprised us about the pipeline or architecture?**
  [...]

- **What would we change about the slice scope if we ran this again?**
  [...]

---

> *Vertical slice code location: `prototypes/[concept-name]-vertical-slice/`*
> *This code is reference material only. Production implementation is written from scratch.*
> *Never import or refactor this code into production.*
