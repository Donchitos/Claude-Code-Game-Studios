# /dev-story — Phase 4: Implement

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Implement

Spawn the chosen programmer agent(s) via `Agent` with the full context package:

Brief the agent with file paths and targeted reading instructions — do not serialize document content into the `Agent` prompt. The agent reads what it needs directly.

> **Tier note (from Phase 2):** items 2–4 below assume the `full` baseline. At
> `standard`, include the TR registry only if it exists and the governing ADR
> only where the story references one — at any tier, a story whose ADR field
> reads `N/A` has no item 3. At `minimal`, the TR registry, ADR, and
> control manifest are typically absent — **omit items 2–4 and brief the agent to
> implement against the story's Acceptance Criteria and the GDD/brief** (the
> story file from item 1). Never instruct the agent to read a file Phase 2
> confirmed missing.
>
> **Say which items you dropped, and say it to both readers.** The rule item 7
> already carries applies unchanged to items 2–4: *an omitted item and a
> forgotten one are indistinguishable to the agent.* They are equally
> indistinguishable to the user reading the Phase 6 summary.
> - **To the agent**, in the prompt: *"No TR registry entry is passed for this
>   story — `docs/architecture/tr-registry.yaml` does not exist at this tier.
>   Implement against the story's Acceptance Criteria and the GDD/brief. Do not
>   go looking for it."* Same form for an absent ADR or control manifest.
> - **To the user**, one line before spawning: `Briefing omits: TR registry
>   (absent), ADR guidance (story references no ADR), control manifest
>   (absent) — implementing against acceptance criteria + GDD.`
>
> Without this, a `standard` run where the registry legitimately does not exist
> and one where `/architecture-review` was supposed to bootstrap it and nobody
> did produce **identical output**.

1. **Story file**: `[story-path]` — the agent reads this one file; it carries the acceptance criteria, Out of Scope boundaries, and QA test cases
2. **GDD requirement**: look up TR-ID `[TR-XXX-NNN]` in `docs/architecture/tr-registry.yaml` — use the `requirement` field as source of truth
3. **ADR guidance**: pass the story's `**ADR Decision Summary**` and `## Implementation Notes` **inline in the prompt** — do not pass the ADR path. Phase 2 already established that this summary is current; handing the agent a path makes it re-read the whole ADR in its own context, paying the cost this skill just avoided. After mismatch option `[A]`, pass the guidance freshly read from the ADR's `## Decision` (the text [A] just wrote into the story), never the stale summary the story carried before; after `[B]`, pass the story's summary and tell the agent it predates the current ADR.
4. **Control manifest**: `docs/architecture/control-manifest.md` — read rules for the **[layer]** layer only
5. **Engine preferences**: `naming.*` and `performance.*` from `project.yaml` (for any key absent or empty, fall back to `.claude/docs/technical-preferences.md`)
6. **Test file path**: `[path from story's Test Evidence section]` — this file must be created as part of implementation
7. **Test requirement** (Logic and Integration stories only; **omit this entire item at `qa.level: minimal`** — tests are not required there. When you omit it for a Logic or Integration story, tell the agent so explicitly — never a UI, Visual/Feel or Config/Data story, which this item never covered: *"Do not write a test file for this story — test evidence is waived at `qa.level: minimal`."* An omitted item and a forgotten one are indistinguishable to the agent, and a programmer briefed with no test instruction may write tests anyway, or may silently assume they were meant to): The test file MUST be created at `[path from the story's Test Evidence section]`. Write the test alongside the implementation — do not defer it. At `qa.level: standard`/`full` the story cannot be closed via `/story-done` without this file present. Each acceptance criterion must have at least one test function covering it. Test naming per engine, from `.claude/rules/test-standards.md`: Godot `test_[scenario]_[expected]` in `[system]_[feature]_test.gd`; Unity `[Scenario]_[Expected]` in a `[System]Tests` class; Unreal `<Project>.[System].[Scenario]`. No random seeds, no time-dependent assertions, no external I/O.
8. **Explicit instruction**: implement this story following the ADR guidelines, respect the manifest rules, stay within the story's Out of Scope boundaries. Write clean, doc-commented public APIs.

The agent should:
- Create or modify files under the **resolved code root** following the ADR guidelines. Resolve it per `.claude/docs/code-root-resolution.md` — `src/` is the Godot row, `Assets/Scripts/<System>/` is Unity's, `Source/<Module>/<System>/` is Unreal's. **If the code root cannot be resolved, do not write: report it and stop.** Selecting the engine specialist above is NOT the same as resolving the code root
- Respect all Required and Forbidden patterns from the control manifest
- Stay within the story's Out of Scope boundaries (do not touch unrelated files)
- Write clean, doc-commented public APIs

### Config/Data stories (no agent needed)

For Type: Config/Data stories, no programmer agent is required. The implementation
is editing a data file. Read the story's acceptance criteria, show the specified
changes as from → to values, and ask "May I write to [data file path]?" before
editing it directly. Note which values were changed and what they changed from/to.

### Visual/Feel stories

Spawn `gameplay-programmer` to implement the code/animation calls. The *look*
half of the acceptance criteria — layout, clipping, presence, colour — is
verified in Phase 6 step 4 by launching the build and retaining a screenshot;
it is not deferred. The *feel* half — timing, weight, responsiveness — is not
something a still can show: say which half the run covered, and leave feel to
`/team-qa`.

---
