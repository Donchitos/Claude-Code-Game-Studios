# Architecture Traceability Index

<!-- Living document — updated by $architecture-review after each review run.
     Do not edit manually unless correcting an error. -->

## Document Status

- **Last Updated**: [YYYY-MM-DD]
- **Engine**: [e.g. Godot 4.6]
- **GDDs Indexed**: [N]
- **ADRs Indexed**: [M]
- **Last Review**: [link to docs/architecture/architecture-review-[date].md]

## Coverage Summary

| Status | Count | Percentage |
|--------|-------|-----------|
| ✅ Covered | [X] | [%] |
| ⚠️ Partial | [Y] | [%] |
| ❌ Gap | [Z] | [%] |
| **Total** | **[N]** | |

---

## Traceability Matrix

<!-- One row per technical requirement extracted from a GDD.
     A "technical requirement" is any GDD statement that implies a specific
     architectural decision: data structures, performance constraints, engine
     capabilities needed, cross-system communication, state persistence. -->

| Req ID | GDD | System | Requirement Summary | ADR(s) | Status | Notes |
|--------|-----|--------|---------------------|--------|--------|-------|
| TR-[gdd]-001 | [filename] | [system name] | [one-line summary] | [ADR-NNNN] | ✅ | |
| TR-[gdd]-002 | [filename] | [system name] | [one-line summary] | — | ❌ GAP | Needs `$architecture-decision [title]` |

---

## Known Gaps

Requirements with no ADR coverage, prioritised by layer (Foundation first):

### Foundation Layer Gaps (BLOCKING — must resolve before coding)
- [ ] TR-[id]: [requirement] — GDD: [file] — Suggested ADR: "[title]"

### Core Layer Gaps (must resolve before relevant system is built)
- [ ] TR-[id]: [requirement] — GDD: [file] — Suggested ADR: "[title]"

### Feature Layer Gaps (should resolve before feature sprint)
- [ ] TR-[id]: [requirement] — GDD: [file] — Suggested ADR: "[title]"

### Presentation Layer Gaps (can defer to implementation)
- [ ] TR-[id]: [requirement] — GDD: [file] — Suggested ADR: "[title]"

---

## Cross-ADR Conflicts

<!-- Pairs of ADRs that make contradictory claims. Must be resolved. -->

| Conflict ID | ADR A | ADR B | Type | Status |
|-------------|-------|-------|------|--------|
| CONFLICT-001 | ADR-NNNN | ADR-MMMM | Data ownership | 🔴 Unresolved |

---

## ADR → GDD Coverage (Reverse Index)

<!-- For each ADR, which GDD requirements does it address? -->

| ADR | Title | GDD Requirements Addressed | Engine Risk |
|-----|-------|---------------------------|-------------|
| ADR-0001 | [title] | TR-combat-001, TR-combat-002 | HIGH |

---

## Superseded Requirements

<!-- Requirements that existed in a GDD when an ADR was written, but the GDD
     has since changed. The ADR may need updating. -->

| Req ID | GDD | Change | Affected ADR | Status |
|--------|-----|--------|-------------|--------|
| TR-[id] | [file] | [what changed] | ADR-NNNN | 🔴 ADR needs update |

---

## How to Use This Document

**When writing a new ADR**: Add it to the "ADR → GDD Coverage" table and mark
the requirements it satisfies as ✅ in the matrix.

**When approving a GDD change**: Scan the matrix for requirements from that GDD
and check whether the change invalidates any existing ADR. Add to "Superseded
Requirements" if so.

**When running `$architecture-review`**: The skill will update this document
automatically with the current state.

**Gate check**: The Pre-Production gate requires this document to exist and to
have zero Foundation Layer Gaps.
