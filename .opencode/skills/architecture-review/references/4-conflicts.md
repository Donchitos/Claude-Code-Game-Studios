# /architecture-review — Phase 4: Cross-ADR Conflict Detection

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other ADR to detect contradictions. A conflict
exists when:

- **Data ownership conflict**: Two ADRs claim exclusive ownership of the same data
- **Integration contract conflict**: ADR-A assumes System X has interface Y, but
  ADR-B defines System X with a different interface
- **Performance budget conflict**: ADR-A allocates N ms to physics, ADR-B allocates
  N ms to AI, together they exceed the total frame budget
- **Dependency cycle**: ADR-A says System X initialises before Y; ADR-B says Y
  initialises before X
- **Architecture pattern conflict**: ADR-A uses event-driven communication for a
  subsystem; ADR-B uses direct function calls to the same subsystem
- **State management conflict**: Two ADRs define authority over the same game state
  (e.g. both Combat ADR and Character ADR claim to own the health value)

For each conflict found:

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / State]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

After conflict detection, analyse the dependency graph across all ADRs.

**Build the graph deterministically — do not trace it by hand:**

```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It collects every `Depends On` edge, finds the cycles and the order, and emits
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `UNFILLED_DEPS:` / `CYCLE:` /
`BLOCKED_BY_CYCLE:` / `ORDER:`. A model tracing A→B→C→A across
a dozen ADRs eventually misses an edge; the algorithm cannot. It reports
observations, not a verdict — you apply the meaning below.

**`NO_DEPS_SECTION` and `UNFILLED_DEPS` are load-bearing**: they make "no cycles
because the graph is clean" distinguishable from "no cycles because half the ADRs
declare no dependencies, or left the template's placeholder in the row". Report
the second case as a structural gap, never as a clean graph, and name each
`UNFILLED_DEPS` ADR as unfilled: what it depends on is unknown, not none.

Then interpret:

1. **Topological sort**: the `ORDER:` row, as emitted — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
   Do not re-sort it by hand. An ADR in `NO_DEPS_SECTION` or `UNFILLED_DEPS` sits
   in it as if it depended on nothing: mark it so.
2. **Flag unresolved dependencies**: cross the `EDGES:` list against the `## Status`
   values already scanned in Phase 1b. If ADR-A depends on an ADR that is still
   `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
3. **Cycle detection**: every `CYCLE:` line the script emitted is a
   `DEPENDENCY CYCLE` — report each one, with the edges its line shows (one of
   them is the edge to cut). A `BLOCKED_BY_CYCLE:` ADR is on no cycle: it waits
   for one to break, so list it as blocked, never as part of the cycle, and never
   suggest cutting its own edges. Do not re-derive them by hand:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
4. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---
