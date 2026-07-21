# ADR: [Decision Name]

---
**Status**: Reverse-Documented
**Source**: `[path to implementation code]`
**Date**: [YYYY-MM-DD]
**Decision Makers**: [User name or "inferred from code"]
**Implementation Status**: [Deployed | Partial | Planned]
---

> **⚠️ Reverse-Documentation Notice**
>
> This Architecture Decision Record was created **after** the implementation already
> existed. It captures the current implementation approach and clarified rationale
> based on code analysis and user consultation. Some context may be reconstructed
> rather than contemporaneously documented.

---

## Context

**Problem Statement**: [What problem did this implementation solve?]

**Background** (inferred from code):
- [Context 1 — why this problem needed solving]
- [Context 2 — constraints at the time]
- [Context 3 — alternatives that were likely considered]

**System Scope**: [What parts of the codebase does this affect?]

**Stakeholders**:
- [Role 1]: [Their concern or requirement]
- [Role 2]: [Their concern or requirement]

---

## Decision

**Approach Taken** (as implemented):

[Describe the architectural approach found in the code]

**Key Implementation Details**:
- [Detail 1]: [How it works]
- [Detail 2]: [Pattern or structure used]
- [Detail 3]: [Notable design choice]

**Clarified Rationale** (from user):
- [Reason 1 — why this approach was chosen]
- [Reason 2 — what problem it solves]
- [Reason 3 — what benefit it provides]

**Code Locations**:
- `[file/path 1]`: [What's there]
- `[file/path 2]`: [What's there]

---

## Alternatives Considered

*(These may be inferred or clarified with user)*

### Alternative 1: [Approach Name]

**Description**: [What this alternative would have been]

**Pros**:
- ✅ [Advantage 1]
- ✅ [Advantage 2]

**Cons**:
- ❌ [Disadvantage 1]
- ❌ [Disadvantage 2]

**Why Not Chosen**: [Reason — from user clarification or inference]

### Alternative 2: [Approach Name]

**Description**: [What this alternative would have been]

**Pros**:
- ✅ [Advantage 1]
- ✅ [Advantage 2]

**Cons**:
- ❌ [Disadvantage 1]
- ❌ [Disadvantage 2]

**Why Not Chosen**: [Reason]

### Alternative 3: [Status Quo / No Change]

**Description**: [What "doing nothing" would mean]

**Why Not Acceptable**: [Why the problem needed solving]

---

## Consequences

### Positive Consequences (Benefits Realized)

✅ **[Benefit 1]**: [How the implementation provides this]

✅ **[Benefit 2]**: [Impact]

✅ **[Benefit 3]**: [Impact]

### Negative Consequences (Trade-offs Accepted)

⚠️ **[Trade-off 1]**: [What was sacrificed or made harder]

⚠️ **[Trade-off 2]**: [Limitation or cost]

⚠️ **[Trade-off 3]**: [Complexity or maintenance burden]

### Neutral Consequences (Observations)

ℹ️ **[Observation 1]**: [Emergent property or side effect]

ℹ️ **[Observation 2]**: [Unexpected outcome]

---

## Implementation Notes

**Patterns Used**:
- [Pattern 1]: [Where and why]
- [Pattern 2]: [Where and why]

**Dependencies Introduced**:
- [Dependency 1]: [Why needed]
- [Dependency 2]: [Why needed]

**Performance Characteristics**:
- Time complexity: [O(n), etc.]
- Space complexity: [Memory usage]
- Bottlenecks: [Known performance concerns]

**Thread Safety**:
- [Thread safety approach — single-threaded, mutex-protected, lock-free, etc.]

**Testing Strategy**:
- [How this is tested — unit tests, integration tests, etc.]
- Coverage: [Estimated or measured]

---

## Validation

**How We Know This Works**:
- ✅ [Evidence 1 — e.g., "6 months in production without issues"]
- ✅ [Evidence 2 — e.g., "handles 10k entities at 60 FPS"]
- ⚠️ [Evidence 3 — e.g., "works but needs monitoring"]

**Known Issues** (discovered during analysis):
- ⚠️ [Issue 1]: [Problem and potential fix]
- ⚠️ [Issue 2]: [Problem and potential fix]

**Risks**:
- [Risk 1]: [Potential problem if X happens]
- [Risk 2]: [Scalability concern]

---

## Open Questions

**Unresolved During Reverse-Documentation**:
1. **[Question 1]**: [What's unclear about the decision or implementation?]
   - Needs clarification from: [Who]
   - Impact if unresolved: [Consequence]

2. **[Question 2]**: [What needs to be decided for future work?]

---

## Follow-Up Work

**Immediate**:
- [ ] [Task 1 — e.g., "Add missing unit tests"]
- [ ] [Task 2 — e.g., "Document edge case handling"]

**Short-Term**:
- [ ] [Task 3 — e.g., "Refactor X for clarity"]
- [ ] [Task 4 — e.g., "Add performance monitoring"]

**Long-Term**:
- [ ] [Task 5 — e.g., "Revisit decision when Y is available"]

---

## Related Decisions

**Depends On** (ADRs this builds upon):
- [ADR-XXX]: [Related decision]

**Influences** (ADRs affected by this):
- [ADR-YYY]: [How this impacts it]

**Supersedes**:
- [ADR-ZZZ]: [Old decision this replaces, if any]

**Superseded By**:
- [None yet | ADR-WWW if this decision is later replaced]

---

## References

**Code Locations**:
- `[path/file 1]`: [Primary implementation]
- `[path/file 2]`: [Related code]

**External Resources**:
- [Article/Book]: [Relevant pattern or technique reference]
- [Documentation]: [Engine or library docs consulted]

**Design Documents**:
- [GDD Section]: [If this implements a design]

---

## Version History

| Date | Author | Changes |
|------|--------|---------|
| [Date] | Codex (reverse-doc) | Initial reverse-documentation from `[source path]` |
| [Date] | [User] | Clarified rationale for [X] |

---

## Status Legend

- **Proposed**: Under discussion, not implemented
- **Accepted**: Decided, implementation in progress
- **Deprecated**: No longer recommended, but may exist in code
- **Superseded**: Replaced by another decision
- **Reverse-Documented**: Created after implementation (this document)

---

**Current Status**: **Reverse-Documented**

---

*This ADR was generated by `$reverse-document architecture [path]`*

---

## Appendix: Code Snippets

**Key Implementation Pattern**:

```[language]
[Code snippet showing the core pattern or decision]
```

**Rationale**: [Why this code structure embodies the decision]

**Alternative Approach** (not chosen):

```[language]
[Code snippet showing what the alternative would look like]
```

**Why Not**: [Why the implemented approach was preferred]
