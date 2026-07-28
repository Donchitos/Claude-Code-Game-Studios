---
name: feedback-schema-enforcement-gap-check
description: When a schema/Rule declares a type, range, or conditional constraint on a field, verify the validation checklist (States table) AND the Acceptance Criteria actually test it — declared constraints with no enforcement path are a silent hole
metadata:
  type: feedback
---

When a GDD's schema table declares a constraint on a field (a type, a range
like "int ≥ 0", or a conditional cross-field rule like "required for category
X, must be none for category Y"), do not assume the constraint is enforced
just because it's written in the schema. Cross-check three places
independently:

1. The state machine's validation/Validating-state "Checks:" list (or
   equivalent) — does it explicitly name this constraint?
2. The Acceptance Criteria — is there a GIVEN/WHEN/THEN that would fail if
   the constraint were silently violated?
3. The Edge Cases — is the violation behavior (halt vs. warn vs. ignore)
   actually specified?

A constraint that appears in the schema table's prose but in NONE of the
above three places will pass boot validation silently if violated — the
schema is decorative, not enforced.

**Why:** Found in `design/gdd/resource-item-database.md` (2026-07-10 first
full review). Rule 4's schema table declares `tier: int ≥ 0` and
`material_family: "Yes for building materials... none for non-material
items"` (a conditional cross-field rule), but the States table's Validating
row only checks "known category, known material family" (enum membership,
not the cross-field conditional) and "required fields present" (presence,
not range) — never `tier ≥ 0`, never the category↔material_family pairing.
No Edge Case and no Acceptance Criterion tests either. A `building_material`
entry with `material_family: none`, or any entry with `tier: -5`, would pass
boot silently despite both being explicitly-declared-invalid per the schema
prose. This directly contradicts the GDD's own repeated "fail loudly at
boot, never launch with a partially valid database" ethos (Edge Cases,
States table Failed-state behavior) — the ethos is real, the enforcement
inventory just doesn't match the schema's claims.

**How to apply:** For every row in a schema/data-definition table with a
type or range annotation, or a conditional requirement written in the Notes
column, grep the States/Validating checklist and the AC list for a matching
check. If either is silent, flag it — even if the doc's Formulas section
explicitly disclaims owning any formulas (boolean validation invariants are
not formulas, but they still need an enforcement point and a test).

Related: a validation *warning* (not a hard failure) has its own failure
mode worth checking — if the field triggering the warning is mandatory-
present on ALL entries of a class (e.g., "required-present... only
meaningful when X is true"), the warning will fire on every single entry of
that class, every boot, forever. A warning that always fires on valid,
expected data isn't a warning — it's noise, and it usually signals a
misplaced "required-present" rule that should instead exempt the
inapplicable case. See also [[feedback-directional-asymmetry-check]] — this
is the schema-table analogue of the same "declared but not wired up" family
of defect.
