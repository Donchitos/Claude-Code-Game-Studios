# Phase 7: Logging advisory deviations as tech debt

Read only when the user picks "Close and log the advisory deviations as tech debt".

Add one row per advisory deviation to `docs/tech-debt-register.md`, in the table
`/tech-debt` keeps, so `/tech-debt report` can date it from its `Added` column:

```
| TD-[next free NNN] | [category] | [deviation] — from [story path] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | — | Open | [YYYY-MM-DD] | Backlog |
```

- **ID:** one above the highest TD number already in the file, three digits;
  `TD-001` in a new file.
- **Category:** one of Architecture, Code Quality, Test, Documentation, Dependency,
  Performance.
- **Effort and Impact:** your estimate from the deviation.
- **Priority:** `—` until `/tech-debt prioritize` scores it.
- **Added:** today.

The file starts with a `## Technical Debt Register` heading, a `Last updated:
[date]` line, a `Total items: [N] | Estimated total effort: [sizes summed]` line and
the table header:

```
| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
```

When the file does not exist, create it that way. When it does, update those two
lines, and add the table header first if it has none.
