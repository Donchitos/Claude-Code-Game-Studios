# /review-all-gdds — Phase 1: Load Everything

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Load Everything

**In this file:**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- Phase 1b — Registry Pre-Load (fast baseline)
- Phase 1c — L1/L2: Section Load

### Phase 1a — L0: Summary Scan (fast, low tokens)

Before reading any full document, use Grep to extract `## Summary` sections
from all GDD files:

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 5
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/gdd/*.md` and count **N**. A scan matching fewer than N means those GDDs
predate `## Summary` — never treat an absent Summary as a system out of scope.
A zero-match scan means "no GDD carries a Summary yet", not "nothing to review".
This review is holistic and loads its in-scope GDDs regardless (see Phase 1c);
the Summary scan only builds the manifest and narrows `since-last-review`, it
never shrinks the review set.

Display a manifest to the user:
```
Found [N] GDDs. Summaries:
  • combat.md — [summary text]
  • inventory.md — [summary text]
  ...
```

For `since-last-review` mode, compute the scope deterministically instead of
reasoning through git history:

```
Bash: bash .claude/scripts/review-scope.sh
```

It prints `PRIOR_REVIEW:`, a `CHANGED:` list, and a `DEPS ...:` list of each
changed GDD's declared dependencies. Use those lists as the scope — the
dependency lines are already the "Key deps" expansion, so no second pass is
needed. If `PRIOR_REVIEW: NONE`, a full review is required; fall back to `full`
mode.

Show the user which GDDs are in scope based on summaries before doing any full
reads. Only proceed to L1 for the `CHANGED` set plus the GDDs named on the
`DEPS` lines.

### Phase 1b — Registry Pre-Load (fast baseline)

Before full-reading any GDD, check for the entity registry:

```
Read path="design/registry/entities.yaml"
```

If the registry exists and has entries, use it as a **pre-built conflict
baseline**: known entities, items, formulas, and constants with their
authoritative values and source GDDs. In Phase 2, grep GDDs for registered
names first — this is faster than reading all GDDs in full before knowing
what to look for.

If the registry is empty or absent: proceed without it. Note in the report:
"Entity registry is empty — consistency checks rely on full GDD reads only.
Run `/consistency-check` after this review to populate the registry."

### Phase 1c — L1/L2: Section Load

Read whole (small, and every part is used):

1. `design/gdd/game-concept.md` — game vision, core loop, MVP definition (or
   `design/game-brief.md`, the one-page brief that replaces it at `rigor: minimal` —
   pitch, core loop, MVP list)
2. `design/gdd/game-pillars.md` if it exists — design pillars and anti-pillars
3. `design/gdd/systems-index.md` — authoritative system list, layers, dependencies, status

Then, for **every in-scope system GDD**, load the sections this review actually
consumes — **not the whole file**:

```
Grep pattern="^## (Dependencies|Detailed Rules|Detailed Design|Formulas|Tuning Knobs|Acceptance Criteria|Player Fantasy)" glob="design/gdd/*.md" output_mode="content" -A 40
```

That list is not a guess — it is exactly the union the Parallel Execution
contract below already enumerates: Phase 2 needs Dependencies, Detailed
Design/Rules, Formulas, Tuning Knobs and Acceptance Criteria; Phase 3 needs
Player Fantasy and progression/reward structure. Overview is narrative restated
by the Summary this skill already scanned in Phase 1a, and Edge Cases feeds no
checklist item here (`/design-review` owns per-GDD completeness). Loading them
put content in three context windows — this one and both sub-agents' — that no
checklist item ever read.

Accept **either** `## Detailed Rules` or `## Detailed Design`; the design standard
and the GDD template disagree on the name and they denote the same section.

**Escalate to a full read of one GDD** when a scanned section cross-references
material outside itself, or when a GDD matched **zero** sections — that GDD
predates the template, and a zero-match there means "unstructured", not "empty".
Never let a zero-match silently drop a system: the scan narrows the *read*, it
never shrinks the *review set*.

Report: "Loaded [N] system GDDs covering [M] systems. Pillars: [list]. Anti-pillars: [list]."

If fewer than 2 system GDDs exist (count the files present; an empty one is handled under NOT ASSESSED in Phase 5, not here), stop:
> "Cross-GDD review requires at least 2 system GDDs. Write more GDDs first,
> then re-run `/review-all-gdds`."

---
