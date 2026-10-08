# /architecture-decision — Step 4: Guide the Decision Collaboratively

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Guide the decision collaboratively

Before asking anything, derive the skill's best guesses from the context already
gathered (GDDs read, engine reference loaded, existing ADRs scanned). Then present
a **confirm/adjust** prompt using `AskUserQuestion` — not open-ended questions.

**Derive assumptions first:**
- **Problem**: Infer from the title + GDD context what decision needs to be made
- **Alternatives**: Propose 2-3 concrete options from engine reference + GDD requirements
- **Dependencies**: Scan existing ADRs for upstream dependencies. **If the scan is
  inconclusive, present `UNKNOWN — scan inconclusive, please confirm`, never
  `None`.** The two are not interchangeable: `None` asserts that nothing upstream
  constrains this decision, and a user confirming a prefilled list cannot tell an
  assertion from a guess. This field is load-bearing — `/architecture-review`
  flags unaccepted dependencies, `/dev-story` reads it, and the acceptance route
  in Phase 0 **refuses to accept an ADR whose dependencies are not themselves
  Accepted**. A dependency list that defaulted to empty makes that check pass
  while examining nothing. `UNKNOWN` must be resolved during the confirm/adjust
  prompt; it is a prompt state, never a value written to the file
- **GDD linkage**: Extract which GDD systems the title directly relates to
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, GDD linkage, and status. Schema design questions (e.g., "How should spawn timing work?", "Should data be inline or external?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include schema design questions in the assumptions AskUserQuestion widget.

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**Present assumptions with `AskUserQuestion`:**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider:
  A) [option derived from engine reference]
  B) [option derived from GDD requirements]
  C) [option from common patterns]
GDD systems driving this: [list derived from context]
Dependencies: [upstream ADRs if any, otherwise "None"]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the GDD linkage
[D] Add a performance budget constraint
[E] Something else needs changing first
```

Do not generate the ADR until the user confirms assumptions or provides corrections.

**After engine specialist and TD reviews return** (Step 5.5/5.6), if unresolved
decisions remain, present each one as a separate `AskUserQuestion` with the proposed
options as choices plus a free-text escape:

```
Decision: [specific unresolved point]
[A] [option from specialist review]
[B] [alternative option]
[C] Different approach — I'll describe it
```

**ADR Dependencies** — derive from existing ADRs, then confirm:
- Does this decision depend on any other ADR not yet Accepted?
- Does it unlock or unblock any other ADR or epic?
- Does it block any specific epic from starting?

Record answers in the **ADR Dependencies** section. Write "None" for each field if no constraints apply.

---
