# [System Name] — Design Document

---
**Status**: Reverse-Documented
**Source**: `[path to implementation code]`
**Date**: [YYYY-MM-DD]
**Verified By**: [User name or "pending review"]
**Implementation Status**: [Fully implemented | Partially implemented | Needs extension]
---

> **⚠️ Reverse-Documentation Notice**
>
> This design document was created **after** the implementation already existed.
> It captures current behavior and clarified design intent based on code analysis
> and user consultation. Some sections may be incomplete where implementation is
> partial or design intent was unclear during reverse-engineering.

---

## 1. Overview

**Purpose**: [What problem does this system solve?]

**Scope**: [What is included/excluded from this system?]

**Current Implementation**: [Brief description of what exists in code]

**Design Intent** (clarified):
- [Intent 1 — why this feature exists]
- [Intent 2 — what player experience it creates]
- [Intent 3 — how it fits into overall game pillars]

---

## 2. Detailed Design

### 2.1 Core Mechanics

[Describe the mechanics as implemented, organized clearly]

**[Mechanic 1 Name]**:
- **Description**: [What it does]
- **Implementation**: [How it works in code]
- **Design Rationale**: [Why it exists — from user clarification]
- **Player-Facing**: [How players experience this]

**[Mechanic 2 Name]**:
- **Description**: [What it does]
- **Implementation**: [How it works]
- **Design Rationale**: [Why it exists]
- **Player-Facing**: [Player experience]

### 2.2 Rules and Formulas

**Formulas Discovered in Code**:

| Formula | Expression | Purpose | Verified? |
|---------|-----------|---------|-----------|
| [Formula 1] | `[mathematical expression]` | [What it calculates] | ✅ / ⚠️ needs tuning |
| [Formula 2] | `[expression]` | [Purpose] | ✅ / ⚠️ needs tuning |

**Clarifications**:
- [Formula X]: Originally [value/approach], user clarified intent is [corrected intent]
- [Formula Y]: Implemented as [X], but should be [Y] — flagged for update

### 2.3 State and Data

**Data Structures** (from code):
- [Data structure 1]: `[fields/properties]`
- [Data structure 2]: `[fields/properties]`

**State Machines** (if applicable):
```
[State diagram or list of states and transitions]
```

**Persistence**:
- Saved: [What is saved to player save file]
- Not saved: [What is session-only or recalculated]

### 2.4 Integration Points

**Dependencies** (systems this depends on):
- [System 1]: [What it provides]
- [System 2]: [What it provides]

**Dependents** (systems that depend on this):
- [System 3]: [How it uses this system]
- [System 4]: [How it uses this system]

**API Surface** (public interface):
- [Method/Function 1]: [Purpose]
- [Method/Function 2]: [Purpose]

---

## 3. Edge Cases

**Handled in Code**:
- ✅ [Edge case 1]: [How it's handled]
- ✅ [Edge case 2]: [How it's handled]

**Not Yet Handled** (discovered during analysis):
- ⚠️ [Edge case 3]: [What happens? Needs implementation]
- ⚠️ [Edge case 4]: [What happens? Needs implementation]

**Unclear** (need user clarification):
- ❓ [Edge case 5]: [What should happen? Pending decision]

---

## 4. Dependencies

**Technical Dependencies**:
- [Dependency 1]: [Why needed]
- [Dependency 2]: [Why needed]

**Design Dependencies** (other design docs):
- [System X Design]: [How they interact]
- [System Y Design]: [How they interact]

**Content Dependencies**:
- [Asset type]: [What's needed]
- [Data files]: [Required config/balance data]

---

## 5. Balance and Tuning

**Current Values** (as implemented):

| Parameter | Current Value | Rationale | Needs Tuning? |
|-----------|--------------|-----------|---------------|
| [Param 1] | [value] | [Why this value] | ✅ / ⚠️ / ❌ |
| [Param 2] | [value] | [Why this value] | ✅ / ⚠️ / ❌ |

**Balance Concerns Identified**:
- ⚠️ [Concern 1]: [What's wrong, suggested fix]
- ⚠️ [Concern 2]: [What's wrong, suggested fix]

**Recommended Balance Pass**:
- Run `$balance-check` on [specific aspect]
- Playtest with focus on [specific scenario]

---

## 6. Acceptance Criteria

**What Exists** (implemented):
- ✅ [Criterion 1]
- ✅ [Criterion 2]
- ⚠️ [Criterion 3] — partially implemented

**What's Missing** (not yet implemented):
- ❌ [Criterion 4] — flagged for future work
- ❌ [Criterion 5] — flagged for future work

**Definition of Done** (when is this system "complete"?):
- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

---

## 7. Open Questions and Follow-Up Work

### Questions Needing User Decision
1. **[Question 1]**: [What needs to be decided?]
   - Option A: [Approach A]
   - Option B: [Approach B]

2. **[Question 2]**: [What needs to be decided?]

### Flagged Follow-Up Work
- [ ] **Update [Formula X]**: Change from exponential to linear (per user clarification)
- [ ] **Implement [Edge Case Y]**: Handle scenario not in current code
- [ ] **Create ADR**: Document why [architectural decision] was chosen
- [ ] **Balance pass**: Run `$balance-check` on progression curve
- [ ] **Extend design doc**: When [related feature] is implemented, update this doc

---

## 8. Version History

| Date | Author | Changes |
|------|--------|---------|
| [Date] | Codex (reverse-doc) | Initial reverse-documentation from `[source path]` |
| [Date] | [User] | Clarified design intent, corrected [X] |

---

**Next Steps**:
1. [Priority 1 task based on gaps identified]
2. [Priority 2 task]
3. [Priority 3 task]

**Related Skills**:
- `$balance-check` — Validate formulas and progression
- `$architecture-decision` — Document technical decisions
- `$code-review` — Ensure code matches clarified design

---

*This document was generated by `$reverse-document design [path]`*
