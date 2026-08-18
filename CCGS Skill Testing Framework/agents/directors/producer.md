# Agent Test Spec: producer

## Agent Summary
**Domain owned:** Scope management, sprint planning validation, milestone tracking, epic prioritization, production phase gate.
**Does NOT own:** Game design decisions (creative-director / game-designer), technical architecture (technical-director), creative direction.
**Model tier:** Opus (multi-document synthesis, high-stakes phase gate verdicts).
**Gate IDs handled:** PR-SCOPE, PR-SPRINT, PR-MILESTONE, PR-EPIC, PR-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/producer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references scope, sprint, milestone, production — not generic)
- [ ] `allowed-tools:` list is primarily read-focused; Bash only if sprint/milestone files require parsing
- [ ] Model tier is `opus` per coordination-rules.md (directors with gate synthesis = Opus)
- [ ] Agent definition does not claim authority over design decisions or technical architecture

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A sprint plan is submitted for Sprint 7. The plan includes 12 story points across 4 team members over 2 weeks. Historical velocity from the last 3 sprints averages 11.5 points. Request is tagged PR-SPRINT.
**Expected:** Returns `PR-SPRINT: REALISTIC` with rationale noting the plan is within one standard deviation of historical velocity and capacity appears matched.
**Assertions:**
- [ ] Verdict is exactly one of REALISTIC / CONCERNS / UNREALISTIC
- [ ] Verdict token is formatted as `PR-SPRINT: REALISTIC`
- [ ] Rationale references the specific story point count and historical velocity figures
- [ ] Output stays within production scope — does not comment on whether the stories are well-designed or technically sound

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Team member asks producer to evaluate whether the game's "weight-based inventory" mechanic feels fun and engaging.
**Expected:** Agent declines to evaluate game feel and redirects to game-designer or creative-director.
**Assertions:**
- [ ] Does not make any binding assessment of the mechanic's design quality
- [ ] Explicitly names `game-designer` or `creative-director` as the correct handler
- [ ] May note if the mechanic's scope has production implications (e.g., dependencies on other systems), but defers all design evaluation

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A new feature proposal adds three new systems (crafting, weather, and faction reputation) to a milestone that was scoped for two systems only. None of these additions appear in the current milestone plan. Request is tagged PR-SCOPE.
**Expected:** Returns `PR-SCOPE: CONCERNS` with specific identification of the three unplanned systems and their absence from the milestone scope document.
**Assertions:**
- [ ] Verdict is exactly one of REALISTIC / CONCERNS / UNREALISTIC — not freeform text
- [ ] Verdict token is formatted as `PR-SCOPE: CONCERNS`
- [ ] Rationale names the three specific systems being added out of scope
- [ ] Does not evaluate whether the systems are good design — only whether they fit the plan

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants to add a late-breaking mechanic (dynamic weather affecting all gameplay systems) that technical-director warns will require 3 additional sprints. game-designer and technical-director are in disagreement about whether to proceed.
**Expected:** Producer does not take a side on whether the mechanic is worth adding (design decision) or feasible (technical decision). Producer quantifies the production impact (3 sprints of delay, milestone slip risk), presents the trade-off to the user, and follows coordination-rules.md conflict resolution: escalate to the shared parent (in this case, surface the conflict for user decision since creative-director and technical-director are both top-tier).
**Assertions:**
- [ ] Quantifies the production impact in concrete terms (sprint count, milestone date slip)
- [ ] Does not make a binding design or technical decision
- [ ] Surfaces the conflict to the user with the scope implications clearly stated
- [ ] References coordination-rules.md conflict resolution protocol (escalate to shared parent or user)

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the current milestone deadline (8 weeks away) and velocity data from the last 4 sprints (8, 10, 9, 11 points). A sprint plan is submitted with 14 story points.
**Expected:** Assessment uses the provided velocity data to project whether 14 points is achievable, and references the 8-week milestone window to assess whether the current sprint's scope leaves adequate buffer.
**Assertions:**
- [ ] Uses the specific velocity figures from the provided context (not generic estimates)
- [ ] References the 8-week deadline in the capacity assessment
- [ ] Calculates or estimates remaining sprint count within the milestone window
- [ ] Does not give generic scope advice disconnected from the supplied deadline and velocity data

---

## Protocol Compliance

- [ ] Returns verdicts using REALISTIC / CONCERNS / UNREALISTIC vocabulary only
- [ ] Stays within declared production domain
- [ ] Escalates design/technical conflicts by quantifying scope impact and presenting to user
- [ ] Uses gate IDs in output (e.g., `PR-SPRINT: REALISTIC`) not inline prose verdicts
- [ ] Does not make binding game design or technical architecture decisions

---

## Coverage Notes
- PR-EPIC (epic-level prioritization) is not covered — a dedicated case should be added when the /create-epics skill produces structured epic documents.
- PR-MILESTONE (milestone health review) is not covered — deferred to integration with /milestone-review skill.
- PR-PHASE-GATE (full production phase advancement) involving synthesis of multiple sub-gate results is deferred.
- Multi-sprint burn-down and velocity trend analysis are not covered here.
