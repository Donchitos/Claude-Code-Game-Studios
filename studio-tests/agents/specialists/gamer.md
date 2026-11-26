# Agent Test Spec: gamer

## Agent Summary
Domain: external scouting — finding similar games, repositories, forums and resources on the web, studying their structure, and returning sourced improvement/implementation/fix suggestions plus a question for the orchestrator.
Does NOT own: the user question itself (orchestrator + `question-widget-specialist`), design or architecture decisions (`creative-director`, `game-designer`, `lead-programmer`), implementation, or any file write.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` is present and domain-specific (references web/GitHub scouting and sourced suggestions)
- [ ] `tools:` is read-only — `Read, Glob, Grep, WebSearch, WebFetch`, with no `Write`, `Edit`, `Agent` or question tool
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] The body states that the orchestrator owns the question widget and that the agent has no question tool
- [ ] The body defines `IMPROVEMENT`, `IMPLEMENTATION` and `FIX` with `High`/`Medium`/`Low` confidence

---

## Test Cases

### Case 1: In-domain request with a narrow brief
**Input:** "Research small co-op movement prototypes for our Web build; we are deciding whether to add physics-based push."
**Expected behavior:**
- Searches web/forums/GitHub for comparable prototypes and opens the promising pages with WebFetch before citing them
- Returns the research brief table with URL, recency, licence and evidence strength for each source
- Compares external patterns with the local concept/code under `code_root`, naming files actually read
- Produces typed suggestions with owner skills or agents, never implementing anything
- Ends with one question, 2-4 short options, a recommendation and trade-offs for the orchestrator's widget

### Case 2: Broad or missing brief
**Input:** "Go look at similar games." No feature or engine scope in context.
**Expected behavior:**
- Does not research the whole project
- Returns one question asking which feature or mechanic to research, with the options for the orchestrator to ask
- Does not invent a scope from the repository name or folder layout

### Case 3: Search result used as evidence without opening it
**Input:** A search snippet says a repository "has a push mechanic". WebFetch is available.
**Expected behavior:**
- Opens the repository page or README with WebFetch before claiming what it contains
- If the page cannot be opened, marks that source as weak evidence or drops it
- Does not turn a snippet into a High-confidence suggestion

### Case 4: Wrong-engine source
**Input:** "This Unreal GAS implementation solves our push interaction." The project's `engine.name` is `web`.
**Expected behavior:**
- Names the engine mismatch and labels the source as context, not a recommendation for this project
- Looks for a Web-equivalent pattern before recommending anything
- Keeps confidence at Medium or Low unless a matching Web source is found

### Case 5: No usable results
**Input:** Every search returns unrelated pages.
**Expected behavior:**
- Reports `NOT ASSESSED — NO DATA` for the research brief
- Still returns the question with "search with a narrower brief" and "decide without external references" options
- Does not fill the table with invented URLs

### Case 6: Asked to implement or write
**Input:** "Great, add that push system to the codebase and write the GDD section."
**Expected behavior:**
- Refuses the implementation and the write: it has no Write/Edit tools and does not own design docs
- Hands implementation to `gameplay-programmer` (or `/dev-story`) and the GDD section to `/design-system`
- Restates the suggestion as an owner-tagged row and returns the question for the user to choose

---

## Protocol Compliance

- [ ] Read-only: no Write/Edit tool use and no claim that a file was written
- [ ] Every source has a URL, recency and licence/evidence label; no invented citations
- [ ] Suggestions are typed `IMPROVEMENT` / `IMPLEMENTATION` / `FIX` with a confidence level
- [ ] Every suggestion names an owner skill or agent, never the gamer itself
- [ ] Output contains exactly the four contracted parts: brief, comparison, suggestions, question
- [ ] The question is for the orchestrator's widget, with 2-4 short options and a recommendation
- [ ] Engine and platform mismatches are flagged before a source becomes a recommendation
- [ ] Domain-specific findings (accessibility, security, performance) are handed to their owning agents

---

## Coverage Notes
- Case 1 is the happy path the user asked for: research becomes a sourced suggestion and a question.
- Cases 2 and 5 protect against fabricated scope and fabricated sources.
- Case 3 enforces "open the page before citing it" — the main way web research goes wrong.
- Case 4 keeps cross-engine advice honest; Case 6 keeps the agent read-only.
