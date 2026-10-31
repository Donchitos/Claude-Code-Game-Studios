# /create-architecture — Phase 4: API Boundaries

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: API Boundaries

Define the public contracts between modules. For each boundary:

- What is the interface a module exposes to the rest of the system?
- What are the entry points (functions/signals/properties)?
- What invariants must callers respect?
- What must the module guarantee to callers?

Write in pseudocode or the project's actual language (from technical preferences).
These become the contracts programmers implement against.

**Engine awareness check**: If any interface uses engine-specific types (e.g.
`Node`, `Resource`, `Signal` in Godot), flag the version and verify the type
exists and has not changed signature in the target engine version.

Get user approval on the API boundaries, then record them in
`production/session-state/active.md`; they are written at Phase 7.

---
