# ADR-[NNNN]: [Title]

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Why this is stated here: stories referencing a `Proposed` ADR are set `Blocked`,
> and epics require `Accepted`, so the field needs a named owner.
> `technical-director` is the role `coordination-rules.md` already escalates
> technical conflicts to, and an ADR is that decision made durable.
>
> This does **not** relax the existing rule that `Status: Accepted` is never set
> without explicit user confirmation — it narrows *which agent* may set it once
> that confirmation exists. An agent that believes an ADR is ready says so and
> escalates; it does not edit this field.

## Date

[YYYY-MM-DD — when this ADR was written]

## Last Verified

[YYYY-MM-DD — when this ADR was last confirmed accurate against the current
engine version and design. Update this date when you re-read and confirm it
is still correct, even if nothing changed.]

## Decision Makers

[Who was involved in this decision]

## Summary

[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether
to read the full decision. Be specific: name the system, the problem, and the
chosen approach.]

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | [e.g. Godot 4.6 / Unity 6 / Unreal Engine 5.7] |
| **Domain** | [Physics / Rendering / UI / Audio / Navigation / Animation / Networking / Core / Input / Scripting] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW — in training data / MEDIUM — near cutoff, verify / HIGH — post-cutoff, must verify] |
| **References Consulted** | [e.g. `docs/engine-reference/godot/modules/physics.md`, `breaking-changes.md`] |
| **Post-Cutoff APIs Used** | [Specific APIs from post-cutoff engine versions this decision depends on, or "None"] |
| **Verification Required** | [Concrete behaviours to test against the target engine version before shipping, or "None"] |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

> **`Layer` is the ADR's own layer, not the referencing epic's — and it is a
> different taxonomy from `Domain`.** Several sites branch on whether an ADR is
> *critical (Foundation-layer)*: `/create-stories`, `/create-epics`,
> `/architecture-decision`, `/story-readiness`, `/propagate-design-change` and
> `gate-pre-production.md`; a missing row counts as critical. At `standard`,
> `/create-stories` **stops** for a missing critical ADR and only **warns** for a
> non-critical one, so this row decides whether a run halts. Do not infer the
> layer from the referencing epic: a Foundation-layer ADR is commonly referenced
> by a Core-layer epic, which would give the wrong answer.
>
> The vocabulary is the same `Foundation / Core / Feature / Presentation` that
> epics and stories already carry — do not invent a fifth value, and do not
> reuse a `Domain` value here. `Domain` says *what part of the engine this
> touches*; `Layer` says *how early in the build it must exist*.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint that isn't captured above] |

## Context

### Problem Statement

[What problem are we solving? Why must this decision be made now? What is the
cost of not deciding?]

### Current State

[How does the system work today? What is wrong with the current approach?]

### Constraints

- [Technical constraints -- engine limitations, platform requirements]
- [Timeline constraints -- deadline pressures, dependencies]
- [Resource constraints -- team size, expertise available]
- [Compatibility requirements -- must work with existing systems]

### Requirements

- [Functional requirement 1]
- [Functional requirement 2]
- [Performance requirement -- specific, measurable]
- [Scalability requirement]

## Decision

[The specific technical decision, described in enough detail for someone to
implement it without further clarification.]

### Architecture

```
[ASCII diagram showing the system architecture this decision creates.
Show components, data flow direction, and key interfaces.]
```

### Key Interfaces

```
[Pseudocode or language-specific interface definitions that this decision
creates. These become the contracts that implementers must respect.]
```

### Implementation Guidelines

[Specific guidance for the programmer implementing this decision.]

## Alternatives Considered

### Alternative 1: [Name]

- **Description**: [How this approach would work]
- **Pros**: [What is good about this approach]
- **Cons**: [What is bad about this approach]
- **Estimated Effort**: [Relative effort compared to chosen approach]
- **Rejection Reason**: [Why this was not chosen]

### Alternative 2: [Name]

[Same structure as above]

## Consequences

### Positive

- [Good outcomes of this decision]

### Negative

- [Trade-offs and costs we are accepting]

### Neutral

- [Changes that are neither good nor bad, just different]

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | [X]ms | [Y]ms | [Z]ms |
| Memory | [X]MB | [Y]MB | [Z]MB |
| Load Time | [X]s | [Y]s | [Z]s |
| Network (if applicable) | [X]KB/s | [Y]KB/s | [Z]KB/s |

## Migration Plan

[If this changes existing systems, the step-by-step plan to migrate.]

1. [Step 1 -- what changes, what breaks, how to verify]
2. [Step 2]
3. [Step 3]

**Rollback plan**: [How to revert if this decision proves wrong]

## Validation Criteria

[How we will know this decision was correct after implementation.]

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Performance criterion]

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| [e.g. `design/gdd/combat.md`] | [e.g. Combat] | [e.g. "Hitbox detection must resolve within 1 frame"] | [e.g. "Jolt physics collision queries run synchronously in _physics_process"] |

> If this is a foundational decision with no direct GDD dependency, write:
> "Foundational — no GDD requirement. Enables: [list what GDD systems this
> decision unlocks or constrains]"

## Related

- [Link to related ADRs — note if supersedes, contradicts, or depends on]
- [Link to relevant code files once implemented]
