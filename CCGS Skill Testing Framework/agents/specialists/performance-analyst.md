# Agent Test Spec: performance-analyst

## Agent Summary
Domain: Profiling, bottleneck identification, performance metrics tracking, and optimization recommendations.
Does NOT own: implementing optimizations (belongs to the appropriate programmer for that domain).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references profiling / bottleneck analysis / performance metrics)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over implementing any optimization — explicitly identifies itself as analysis/recommendation only

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Analyze this frame time data: CPU 14ms, GPU 8ms, physics 6ms, draw calls 420, scripts 3ms."
**Expected behavior:**
- Identifies the primary bottleneck: the frame is CPU-bound (CPU 14ms vs GPU 8ms) — inside a 16.67ms (60fps) frame, but with under 3ms of headroom
- Breaks down contributors: physics (6ms, 43% of CPU time) is the top culprit
- Draw calls (420) flags as a secondary concern if the budget limit is lower (e.g., 200 draw calls per the project's `performance.draw_call_limit`)
- Produces a prioritized bottleneck report:
  1. Physics — 6ms, reduce simulation frequency or switch broadphase algorithm
  2. Draw calls — 420, implement batching or LOD
  3. Scripts — 3ms, profile hot paths
- Does NOT implement any of these optimizations

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Implement the batching optimization to reduce draw calls from 420 to under 200."
**Expected behavior:**
- Does NOT produce implementation code for batching
- Explicitly states that implementing optimizations belongs to the owner of the system — `technical-artist`, whose rendering optimization covers batching (naming `engine-programmer` as well, for an engine-level rendering change the batching needs, is fine)
- Redirects the implementation to `technical-artist`, handing over its recommendation as the brief: the target (under 200 draw calls), estimated impact, and implementation cost

### Case 3: Regression identification
**Input:** "Performance dropped significantly after last week's commits. Frame time went from 10ms to 18ms."
**Expected behavior:**
- Compares profiles of a build from before the window (~10ms) and after it (~18ms); if no profile exists for either build, asks for or proposes the captures instead of guessing
- Localizes the 8ms delta to the frame-time categories that grew (gameplay logic, rendering, physics, AI, audio), not to a cause guessed from commit messages or diffs alone
- Names a suspect commit or system only when a profile supports it (e.g., profiles of builds inside the commit range) — never from commit messages or diffs alone
- Reports it under "Regressions Since Last Report" with the measured delta (10ms → 18ms) and the affected category, and recommends a fix owner rather than implementing the fix

### Case 4: Recommendation vs. code quality trade-off
**Input:** "The fastest optimization for the script bottleneck would be to inline all calls and remove abstraction layers."
**Expected behavior:**
- Surfaces the trade-off: inlining improves performance but reduces testability and violates the coding standard requiring unit-testable public methods
- Does NOT recommend the optimization without noting the code quality cost
- Escalates the trade-off to `technical-director`, the agent it reports to, for a decision
- Presents the options with their trade-offs — e.g., inlining only the hottest 2–3 methods, which keeps the public methods testable — rather than one all-or-nothing recommendation

### Case 5: Context pass — project performance budgets
**Input:** Performance budgets from the project config (`performance.*` in `project.yaml`) provided in context: Target 60fps, frame budget 16.67ms, draw calls max 200, memory ceiling 512MB. Request: "Review the current build profile."
**Expected behavior:**
- References the specific values from the provided context: 16.67ms, 200 draw calls, 512MB
- Compares current measurements against each threshold explicitly, in its Performance Report Format (Budget / Actual / Status tables for frame time and memory)
- Labels each metric's Status as OK or OVER based on the provided numbers
- Does NOT use different budget numbers than those provided in the context

---

## Protocol Compliance

- [ ] Stays within declared domain (profiling, analysis, recommendations — not implementation)
- [ ] Redirects optimization implementation to the owner of the system (technical-artist for rendering optimizations such as batching, engine-programmer for engine systems) rather than implementing it
- [ ] Returns structured findings in its Performance Report Format (budget/actual/status tables, top bottlenecks with impact and recommendation, regressions)
- [ ] Escalates code-quality trade-offs to technical-director rather than deciding unilaterally
- [ ] Applies budget thresholds from provided context rather than assumed defaults
- [ ] Names who should implement each recommended optimization ("recommend and assign") instead of implementing it
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Frame time analysis (Case 1) output follows the agent's Performance Report Format; when run under `/perf-profile` or `/team-polish`, the report is written to `production/polish/`
- Regression case (Case 3) confirms the agent localizes the cause from profiles across builds, not just measures symptoms or guesses from diffs
- Code quality trade-off (Case 4) verifies the agent does not recommend optimizations that violate coding standards without flagging the conflict
