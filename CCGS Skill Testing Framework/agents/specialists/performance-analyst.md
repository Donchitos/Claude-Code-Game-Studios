# Agent Test Spec: performance-analyst

## Agent Summary
Domain: Profiling, bottleneck identification, performance metrics tracking, and optimization recommendations.
Does NOT own: implementing optimizations (belongs to the appropriate programmer for that domain).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references profiling / bottleneck analysis / performance metrics)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over implementing any optimization — explicitly identifies itself as analysis/recommendation only

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Analyze this frame time data: CPU 14ms, GPU 8ms, physics 6ms, draw calls 420, scripts 3ms."
**Expected behavior:**
- Identifies the primary bottleneck: CPU is over a 16.67ms (60fps) budget at 14ms total
- Breaks down contributors: physics (6ms, 43% of CPU time) is the top culprit
- Draw calls (420) flags as a secondary concern if the budget limit is lower (e.g., 200 draw calls per technical-preferences.md)
- Produces a prioritized bottleneck report:
  1. Physics — 6ms, reduce simulation frequency or switch broadphase algorithm
  2. Draw calls — 420, implement batching or LOD
  3. Scripts — 3ms, profile hot paths
- Does NOT implement any of these optimizations

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Implement the batching optimization to reduce draw calls from 420 to under 200."
**Expected behavior:**
- Does NOT produce implementation code for batching
- Explicitly states that implementing optimizations belongs to the appropriate programmer (engine-programmer for rendering batching)
- Redirects the implementation to `engine-programmer` with the recommendation context attached
- May produce a requirements brief for the optimization so engine-programmer has a clear target

### Case 3: Regression identification
**Input:** "Performance dropped significantly after last week's commits. Frame time went from 10ms to 18ms."
**Expected behavior:**
- Proposes a bisection strategy to identify the offending commit range
- Requests or reviews the diff of commits in the window to narrow the likely cause
- Identifies affected systems based on what changed (e.g., if physics code was modified, points to physics as the primary suspect)
- Produces a regression report naming the probable commit, the affected system, and the measured delta

### Case 4: Recommendation vs. code quality trade-off
**Input:** "The fastest optimization for the script bottleneck would be to inline all calls and remove abstraction layers."
**Expected behavior:**
- Surfaces the trade-off: inlining improves performance but reduces testability and violates the coding standard requiring unit-testable public methods
- Does NOT recommend the optimization without noting the code quality cost
- Escalates the trade-off to `lead-programmer` for a decision
- May propose a middle path (e.g., profile-guided inlining of only the hottest 2–3 methods) that preserves testability

### Case 5: Context pass — technical-preferences.md budget
**Input:** Technical preferences from context: Target 60fps, frame budget 16.67ms, draw calls max 200, memory ceiling 512MB. Request: "Review the current build profile."
**Expected behavior:**
- References the specific values from the provided context: 16.67ms, 200 draw calls, 512MB
- Compares current measurements against each threshold explicitly
- Labels each metric as WITHIN BUDGET / AT RISK / OVER BUDGET based on the provided numbers
- Does NOT use different budget numbers than those provided in the context

---

## Protocol Compliance

- [ ] Stays within declared domain (profiling, analysis, recommendations — not implementation)
- [ ] Redirects optimization implementation to the correct programmer domain agent
- [ ] Returns structured findings (bottleneck report with severity, measured values, and recommended action owner)
- [ ] Escalates code-quality trade-offs to lead-programmer rather than deciding unilaterally
- [ ] Applies budget thresholds from provided context rather than assumed defaults
- [ ] Labels all findings with a specific action owner (who should implement the fix)

---

## Coverage Notes
- Frame time analysis (Case 1) output should be structured as a report filed in `production/qa/evidence/`
- Regression case (Case 3) confirms the agent investigates cause, not just measures symptoms
- Code quality trade-off (Case 4) verifies the agent does not recommend optimizations that violate coding standards without flagging the conflict
