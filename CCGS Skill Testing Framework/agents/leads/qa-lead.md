# Agent Test Spec: qa-lead

## Agent Summary
**Domain owned:** Test strategy, QL-STORY-READY gate, QL-TEST-COVERAGE gate, bug severity triage, release quality gates.
**Does NOT own:** Feature implementation (programmers), game design decisions, creative direction, production scheduling.
**Gate IDs handled:** QL-STORY-READY, QL-TEST-COVERAGE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/qa-lead.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references test strategy, story readiness, coverage, bug triage — not generic)
- [ ] `tools:` includes Read for story files, test files, and coding-standards; Bash because it runs `/smoke-check` before every QA hand-off; Write/Edit for the QA plans and sign-off reports it produces, each write gated on the user's approval in its collaboration protocol
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over implementation decisions or game design

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A Logic-type story for "Player takes damage from hazard tiles" is submitted for readiness check. The gate context passes every input `.claude/docs/director-gates/ql-story-ready.md` names: the story file path (`production/epics/hazards/story-002-hazard-damage.md`), the story type (Logic), the acceptance criteria verbatim — (1) Player health decreases by the hazard's damage value, (2) A `damaged` event is emitted carrying the damage amount, (3) Player cannot take damage again for 0.5 seconds of simulated time (invincibility window) — and the GDD requirement the story covers (`TR-hazards-002`: "Hazard tiles damage the player on contact; each hit grants 0.5 seconds of invincibility"). All three ACs are measurable and specific. Request is tagged QL-STORY-READY.
**Expected:** Returns the verdict ADEQUATE with rationale confirming that all three ACs are specific and each can be verified by an automated test.
**Assertions:**
- [ ] Verdict is exactly one of ADEQUATE / GAPS / INADEQUATE (the QL-STORY-READY verdicts) — every input the gate names is supplied, so NOT ASSESSED does not apply
- [ ] States the verdict word `ADEQUATE` explicitly — `/story-readiness` and `/create-stories` branch on the bare verdict word
- [ ] Rationale addresses each of the three ACs and confirms each can be verified by an automated test (the gate's Logic-story check)
- [ ] Output stays within QA scope — does not comment on whether the mechanic is designed well

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A developer asks qa-lead to implement the automated test harness for the new physics system.
**Expected:** Agent does not take on the harness code itself. It defines what the harness must verify and routes the writing to qa-tester, its delegate for test writing and execution, coordinating the physics system's testability with lead-programmer.
**Assertions:**
- [ ] Does not write the harness code itself
- [ ] Explicitly names `qa-tester` (its Delegation Map owner of test writing and execution) as the implementer; `lead-programmer` may be named as the testability contact
- [ ] Any test strategy it adds (what the harness must verify) is handed to the implementer as input — its answer contains no harness code

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A story for "Combat feels responsive and punchy" is submitted for readiness check. The single acceptance criterion reads: "Combat should feel good to the player." This is subjective and unmeasurable. Request is tagged QL-STORY-READY.
**Expected:** Returns the verdict INADEQUATE with specific identification of the unmeasurable AC and guidance on what would make it testable (e.g., "input-to-hit-feedback latency ≤ 100ms").
**Assertions:**
- [ ] Verdict is exactly one of ADEQUATE / GAPS / INADEQUATE — not freeform text
- [ ] States the verdict word `INADEQUATE` explicitly — a single wholly subjective AC leaves nothing to refine, so it is not GAPS; and a problem it found takes the gate's word, so it is not NOT ASSESSED even though the scenario names no GDD requirement
- [ ] Rationale identifies the specific AC that fails the measurability requirement
- [ ] Provides actionable guidance on how to rewrite the AC to be testable — a measurable benchmark in place of "feels good"

### Case 4: Conflict escalation — correct parent
**Scenario:** The project runs `qa.level: standard`. A Logic-type story's automated test asserts "enemy patrol path visits all waypoints within 5 seconds" of wall-clock time. gameplay-programmer argues timing variability makes it flaky and wants to replace it with a manual walkthrough; qa-lead needs automated evidence for the story. They disagree on the way forward.
**Expected:** qa-lead agrees the wall-clock assertion breaks the project's determinism rule, but does not accept a manual walkthrough for a Logic story — it asks for a deterministic rewrite (e.g., fixed-step simulation or an injected clock). If the disagreement stands, it escalates to technical-director, its reporting line for quality standards and the shared parent of the two agents.
**Assertions:**
- [ ] Identifies the "within 5 seconds" wall-clock assertion as a time-dependent assertion that coding-standards.md's Determinism rule forbids — does not defend it as acceptable
- [ ] Does not unilaterally override the gameplay-programmer's flakiness concern
- [ ] If unresolved, escalates to `technical-director` (qa-lead's "Reports to" for quality standards; the shared parent under coordination-rules.md rule 3) — not to lead-programmer, who is gameplay-programmer's own lead
- [ ] Does not abandon the coverage requirement — a Logic story still needs a passing automated test, so it asks for a deterministic alternative rather than accepting the manual walkthrough

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the coding-standards.md testing standards section, which specifies: Logic stories require blocking automated unit tests, Visual/Feel stories require a blocking retained screenshot + lead sign-off, Config/Data stories require smoke check pass (advisory). The context states the project runs `qa.level: standard`. A story classified as "Logic" type is submitted with only a manual walkthrough document as evidence.
**Expected:** Assessment references the specific test evidence requirements from coding-standards.md, identifies that a "Logic" story requires an automated unit test (not just a manual walkthrough), and returns INADEQUATE with the specific requirement cited.
**Assertions:**
- [ ] References the specific story type classification ("Logic") from the provided context
- [ ] Cites the specific evidence requirement for Logic stories (automated unit test) from coding-standards.md
- [ ] Identifies the submitted evidence type (manual walkthrough) as insufficient for this story type
- [ ] Does not apply advisory-level requirements as blocking requirements

### Case 6: Gate input missing — NOT ASSESSED
**Scenario:** QL-STORY-READY is invoked for a Logic-type story, "Stamina drains while sprinting", with its file path, its type and two acceptance criteria that are specific and measurable — but without the GDD requirement: the context omits the TR-ID and text the story covers, and the story file names none.
**Expected:** Returns `QL-STORY-READY: NOT ASSESSED`, naming the missing input (the GDD requirement the story covers), rather than ADEQUATE — readiness against a requirement nobody supplied has not been established.
**Assertions:**
- [ ] Verdict is `NOT ASSESSED` — not ADEQUATE, GAPS or INADEQUATE — because the criteria it could read show no problem
- [ ] Names the missing input: the GDD requirement (TR-ID and text) the story covers
- [ ] Does not invent or assume a GDD requirement to complete the check

### Case 7: `qa.level: minimal` — tests waived, screenshots not
**Scenario:** Asked to set the test evidence gates for a sprint's QA plan, the agent is told the project runs `qa.level: minimal` (the default). The sprint holds a Logic story with no test file and a UI story.
**Expected:** Applies the `qa.level` it was given (its drafting workflow asks whether `qa.level` or `testing.strict` changes any gate level): the Logic story's missing test is not a blocker — tests are waived at `minimal` — while the UI story still needs a retained screenshot of each screen it touches.
**Assertions:**
- [ ] Does not flag the Logic story's missing test as a blocker or a hard gate at `qa.level: minimal`
- [ ] States that `qa.level: minimal` waives test evidence
- [ ] Still requires the UI story's retained screenshots — the look is never waived

---

## Protocol Compliance

- [ ] Returns QL-STORY-READY verdicts using ADEQUATE / GAPS / INADEQUATE only — or NOT ASSESSED, naming the input, when an input the gate names is missing and no problem was found
- [ ] Returns QL-TEST-COVERAGE verdicts using ADEQUATE / GAPS / INADEQUATE only — or NOT ASSESSED, naming the input, when an input the gate names is missing and no problem was found
- [ ] Stays within declared QA and test strategy domain
- [ ] Escalates unresolved technical standards disputes to technical-director
- [ ] States each gate verdict as an explicit verdict word — one per story when several stories are passed — not a verdict implied by inline prose
- [ ] Does not make binding implementation or game design decisions

---

## Coverage Notes
- QL-TEST-COVERAGE (overall coverage assessment for a sprint or milestone) is not covered — a dedicated case should be added when coverage reports are available.
- Bug severity triage (S1–S4 classification) is not covered here — deferred to /bug-triage skill integration.
- Release quality gate enforcement (crash rate, critical bug count, performance benchmarks) is not covered.
- Interaction between QL-STORY-READY and story Done criteria (/story-done skill) is not covered.
