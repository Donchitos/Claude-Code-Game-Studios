# Technical Design: [System Name]

## Document Status
- **Version**: 1.0
- **Last Updated**: [Date]
- **Author**: [Agent/Person]
- **Reviewer**: lead-programmer
- **Related ADR**: [ADR-XXXX if applicable]
- **Related Design Doc**: [Link to game design doc this implements]

## Engine API Surface

| Field | Value |
|-------|-------|
| **Engine** | [e.g. Godot 4.6 / Unity 6 / Unreal Engine 5.4] |
| **APIs Depended On** | [Specific classes/methods/nodes used, version-pinned — e.g. `CharacterBody3D.move_and_slide() (Godot 4.x)`] |
| **References Consulted** | [engine-reference docs read before writing this — e.g. `docs/engine-reference/godot/modules/physics.md`] |
| **Post-Cutoff Features Used** | [Features from engine versions beyond LLM training cutoff, or "None"] |
| **Unverified Assumptions** | [API behaviours assumed but not yet tested against the target version, or "None"] |
| **Engine Upgrade Risk** | [LOW / MEDIUM / HIGH — how fragile is this design if the engine version changes?] |

> **Rule**: If any **Unverified Assumptions** are listed, this document cannot be marked
> as Accepted until those assumptions are validated in the actual engine environment.

## Overview
[2-3 sentence summary of what this system does and why it exists]

## Requirements
### Functional Requirements
- [FR-1]: [Description]
- [FR-2]: [Description]

### Non-Functional Requirements
- **Performance**: [Budget — e.g., "< 1ms per frame"]
- **Memory**: [Budget — e.g., "< 50MB at peak"]
- **Scalability**: [Limits — e.g., "Support up to 1000 entities"]
- **Thread Safety**: [Requirements]

## Architecture

### System Diagram
```
[ASCII diagram showing components and data flow]
```

### Component Breakdown
| Component | Responsibility | Owns |
| --------- | -------------- | ---- |
| [Name] | [What it does] | [What data it owns] |

### Public API
```
[Interface/API definition in pseudocode or target language]
```

### Data Structures
```
[Key data structures with field descriptions]
```

### Data Flow
[Step by step: how data moves through the system during a typical frame]

## Implementation Plan

### Phase 1: [Core Functionality]
- [ ] [Task 1]
- [ ] [Task 2]

### Phase 2: [Extended Features]
- [ ] [Task 3]
- [ ] [Task 4]

### Phase 3: [Optimization/Polish]
- [ ] [Task 5]

## Dependencies
| Depends On | For What |
| ---------- | -------- |
| [System] | [Reason] |

| Depended On By | For What |
| -------------- | -------- |
| [System] | [Reason] |

## Testing Strategy
- **Unit Tests**: [What to test at unit level]
- **Integration Tests**: [Cross-system tests needed]
- **Performance Tests**: [Benchmarks to create]
- **Edge Cases**: [Specific scenarios to test]

## Known Limitations
[What this design intentionally does NOT support and why]

## Future Considerations
[What might need to change if requirements evolve — but do NOT build for this now]
