# Agent Test Spec: qa-lead

## Agent Summary
**Domain owned:** Test strategy, QL-STORY-READY gate, QL-TEST-COVERAGE gate, bug severity triage, release quality gates.
**Does NOT own:** Feature implementation (programmers), game design decisions, creative direction, production scheduling.
**Model tier:** Sonnet (individual system analysis — story readiness and coverage assessment).
**Gate IDs handled:** QL-STORY-READY, QL-TEST-COVERAGE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/qa-lead.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references test strategy, story readiness, coverage, bug triage — not generic)
- [ ] `allowed-tools:` list is read-focused; may include Read for story files, test files, and coding-standards; Bash only if running test commands is required
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over implementation decisions or game design

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A story for "Player takes damage from hazard tiles" is submitted for readiness check. The story has three acceptance criteria: (1) Player health decreases by the hazard's damage value, (2) A damage visual feedback plays, (3) Player cannot take damage again for 0.5 seconds (invincibility window). All three ACs are measurable and specific. Request is tagged QL-STORY-READY.
**Expected:** Returns `QL-STORY-READY: ADEQUATE` with rationale confirming that all three ACs are present, specific, and testable.
**Assertions:**
- [ ] Verdict is exactly one of ADEQUATE / INADEQUATE
- [ ] Verdict token is formatted as `QL-STORY-READY: ADEQUATE`
- [ ] Rationale references the specific number of ACs (3) and confirms each is measurable
- [ ] Output stays within QA scope — does not comment on whether the mechanic is designed well

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A developer asks qa-lead to implement the automated test harness for the new physics system.
**Expected:** Agent declines to implement the test code and redirects to the appropriate programmer (gameplay-programmer or lead-programmer).
**Assertions:**
- [ ] Does not write or propose code implementation
- [ ] Explicitly names `lead-programmer` or `gameplay-programmer` as the correct handler for implementation
- [ ] May define what the test should verify (test strategy), but defers the code writing to programmers

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A story for "Combat feels responsive and punchy" is submitted for readiness check. The single acceptance criterion reads: "Combat should feel good to the player." This is subjective and unmeasurable. Request is tagged QL-STORY-READY.
**Expected:** Returns `QL-STORY-READY: INADEQUATE` with specific identification of the unmeasurable AC and guidance on what would make it testable (e.g., "input-to-hit-feedback latency ≤ 100ms").
**Assertions:**
- [ ] Verdict is exactly one of ADEQUATE / INADEQUATE — not freeform text
- [ ] Verdict token is formatted as `QL-STORY-READY: INADEQUATE`
- [ ] Rationale identifies the specific AC that fails the measurability requirement
- [ ] Provides actionable guidance on how to rewrite the AC to be testable

### Case 4: Conflict escalation — correct parent
**Scenario:** gameplay-programmer and qa-lead disagree on whether a test that asserts "enemy patrol path visits all waypoints within 5 seconds" is deterministic enough to be a valid automated test. gameplay-programmer argues timing variability makes it flaky; qa-lead believes it is acceptable.
**Expected:** qa-lead acknowledges the technical flakiness concern and escalates to lead-programmer for a technical ruling on what constitutes an acceptable determinism standard for automated tests.
**Assertions:**
- [ ] Escalates to `lead-programmer` for the technical ruling on determinism standards
- [ ] Does not unilaterally override the gameplay-programmer's flakiness concern
- [ ] Frames the escalation clearly: "this is a technical standards question, not a QA coverage question"
- [ ] Does not abandon the coverage requirement — asks for a deterministic alternative if the current approach is ruled flaky

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the coding-standards.md testing standards section, which specifies: Logic stories require blocking automated unit tests, Visual/Feel stories require screenshots + lead sign-off (advisory), Config/Data stories require smoke check pass (advisory). A story classified as "Logic" type is submitted with only a manual walkthrough document as evidence.
**Expected:** Assessment references the specific test evidence requirements from coding-standards.md, identifies that a "Logic" story requires an automated unit test (not just a manual walkthrough), and returns INADEQUATE with the specific requirement cited.
**Assertions:**
- [ ] References the specific story type classification ("Logic") from the provided context
- [ ] Cites the specific evidence requirement for Logic stories (automated unit test) from coding-standards.md
- [ ] Identifies the submitted evidence type (manual walkthrough) as insufficient for this story type
- [ ] Does not apply advisory-level requirements as blocking requirements

---

## Protocol Compliance

- [ ] Returns QL-STORY-READY verdicts using ADEQUATE / INADEQUATE vocabulary only
- [ ] Returns QL-TEST-COVERAGE verdicts using ADEQUATE / INADEQUATE vocabulary only (or PASS / FAIL for release gates)
- [ ] Stays within declared QA and test strategy domain
- [ ] Escalates technical standards disputes to lead-programmer
- [ ] Uses gate IDs in output (e.g., `QL-STORY-READY: INADEQUATE`) not inline prose verdicts
- [ ] Does not make binding implementation or game design decisions

---

## Coverage Notes
- QL-TEST-COVERAGE (overall coverage assessment for a sprint or milestone) is not covered — a dedicated case should be added when coverage reports are available.
- Bug severity triage (P0/P1/P2 classification) is not covered here — deferred to /bug-triage skill integration.
- Release quality gate behavior (PASS / FAIL vocabulary variant) is not covered.
- Interaction between QL-STORY-READY and story Done criteria (/story-done skill) is not covered.
