---
name: petquest-gdd-review-role
description: How the user involves qa-lead in PetQuest GDD authoring (numbered systems, /design-system skill, AC review checkpoint)
metadata:
  type: project
---

PetQuest GDDs live in `design/gdd/` and are authored incrementally via the
`/design-system` skill — skeleton first, then one section at a time with user
approval before each section is written to file. Systems are numbered and
cross-referenced by number (e.g., "#11 Parent Approval", "#21 Parent Dashboard
UI") — dependency sections in each doc list upstream/downstream systems by
number and must be bidirectional (if A depends on B, B's doc must reference A
back).

The user routes to qa-lead specifically before drafting the **Acceptance
Criteria** section of a GDD (after Overview/Player Fantasy/Detailed
Design/Formulas/Edge Cases/Dependencies/Tuning Knobs are already written) to
sanity-check that every Core Rule and Edge Case is testable and complete
before AC prose is committed.

**Why:** AC written against an ambiguous or incomplete Core Rule/Edge Case is
dishonest — it looks testable but isn't. The user wants real design gaps
caught at this checkpoint, not just wording polish. See
[[feedback-gdd-ac-review-depth]].

**How to apply:** When asked to review a GDD's draft-Acceptance-Criteria
readiness, read the full doc (not just the section being drafted) and check:
(1) every Core Rule has ≥1 testable GIVEN/WHEN/THEN, (2) every Edge Case is
precise enough to reproduce deterministically (no unstated reset/trigger
conditions), (3) cross-references to other numbered systems are consistent
with what's actually decided there. Flag Core-Rule/Edge-Case-level gaps
separately from AC-wording issues, and propose a default fix so the user only
has to confirm/adjust rather than design from scratch.
