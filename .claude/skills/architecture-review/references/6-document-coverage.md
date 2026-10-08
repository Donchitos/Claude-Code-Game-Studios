# /architecture-review — Phase 6: Architecture Document Coverage

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Architecture Document Coverage

**If `docs/architecture/architecture.md` does not exist, say so in the report** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— and carry it into the Phase 7 verdict per the trigger list below. Phase 5
already models this for the engine consultation (*"A skipped check that says
nothing is indistinguishable from a check that passed"*); this phase is the one
that did not. Silently producing no Phase 6 findings reads as an architecture
document that was checked and found clean, which is the opposite of what
happened.

If it exists, validate it against GDDs:

- Does every system from `systems-index.md` appear in the architecture layers?
- Does the data flow section cover all cross-system communication defined in GDDs?
- Do the API boundaries support all integration requirements from GDDs?
- Are there systems in the architecture doc that have no corresponding GDD
  (orphaned architecture)?

---
