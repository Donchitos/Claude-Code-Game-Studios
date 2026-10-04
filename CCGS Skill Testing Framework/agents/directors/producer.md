# Agent Test Spec: producer

## Agent Summary
**Domain owned:** Scope management, sprint planning validation, milestone tracking, epic prioritization, production phase gate.
**Does NOT own:** Game design decisions (creative-director / game-designer), technical architecture (technical-director), creative direction.
**Gate IDs handled:** PR-SCOPE, PR-SPRINT, PR-MILESTONE, PR-EPIC, PR-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/producer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references scope, sprint, milestone, production — not generic)
- [ ] `tools:` includes Write and Edit (it authors sprint plans per its Output Format and maintains the risk register) and Bash only because a preloaded skill needs it (`skills:` includes `scope-check`, which reads `git log`)
- [ ] Model tier is `opus` — frontmatter `model:` reads exactly `opus` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over design decisions or technical architecture

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A sprint plan is submitted for Sprint 7. The plan commits 9 story points across 4 team members over 2 weeks, with dependencies listed and no story larger than 3 days. Historical velocity from the last 3 sprints averages 11.5 points; no backlog debt is carried in, and the milestone constraints add nothing to this sprint. Request is tagged PR-SPRINT.
**Expected:** Returns `PR-SPRINT: REALISTIC` with rationale noting the load sits below historical velocity while keeping the 20% buffer its Sprint Planning Rules require (9 ≤ 80% of 11.5).
**Assertions:**
- [ ] Verdict is exactly one of REALISTIC / CONCERNS / UNREALISTIC
- [ ] Verdict token is formatted as `PR-SPRINT: REALISTIC`
- [ ] Rationale compares the 9 committed points with the 11.5-point velocity and the 20% buffer rule — not a generic "looks achievable"
- [ ] Output stays within production scope — does not comment on whether the stories are well-designed or technically sound

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Team member asks producer to evaluate whether the game's "weight-based inventory" mechanic feels fun and engaging.
**Expected:** Agent declines to evaluate game feel and redirects to game-designer or creative-director.
**Assertions:**
- [ ] Does not make any binding assessment of the mechanic's design quality
- [ ] Explicitly names `game-designer` or `creative-director` as the correct handler
- [ ] Any comment it makes is about production implications only (e.g., which other systems the mechanic depends on) — never whether the mechanic is fun, engaging or well designed

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A scope estimate is submitted for a solo developer with a 4-month timeline. The MVP was two systems (movement and combat), estimated at 3 months. The revised MVP adds three more — crafting, weather, and faction reputation — bringing the estimate to exactly 4 months: the whole timeline, with no buffer left for unplanned work. Each of the three could move to the next scope tier without breaking the MVP. Request is tagged PR-SCOPE.
**Expected:** Returns `PR-SCOPE: OPTIMISTIC` — the gate's middle verdict, with specific adjustments — because the MVP fits only if nothing goes wrong: names the three added systems and recommends which to move to a later scope tier to restore a buffer. Not UNREALISTIC: the estimate does not exceed the timeline, so neither has to be revised.
**Assertions:**
- [ ] Verdict is exactly one of REALISTIC / OPTIMISTIC / UNREALISTIC (the PR-SCOPE verdicts) — not CONCERNS and not freeform text
- [ ] Verdict token is formatted as `PR-SCOPE: OPTIMISTIC`
- [ ] Rationale names the three specific systems that use up the buffer
- [ ] Does not evaluate whether the systems are good design — only whether they fit the plan

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants to add a late-breaking mechanic (dynamic weather affecting all gameplay systems) that technical-director warns will require 3 additional sprints. game-designer and technical-director are in disagreement about whether to proceed.
**Expected:** Producer does not take a side on whether the mechanic is worth adding (design decision) or feasible (technical decision). Producer quantifies the production impact (3 sprints of delay, milestone slip risk), presents the trade-off to the user, and follows coordination-rules.md rule 3: game-designer and technical-director share no parent, and whether the mechanic is worth its cost is a design conflict, so it goes to creative-director, the arbiter of scope questions where creative intent and production capacity collide.
**Assertions:**
- [ ] Quantifies the production impact in concrete terms (sprint count, milestone date slip)
- [ ] Does not make a binding design or technical decision
- [ ] Surfaces the conflict to the user with the scope implications clearly stated
- [ ] Escalates the conflict to `creative-director` per coordination-rules.md rule 3 (no shared parent; a design conflict) — not to technical-director, and not straight to the user as if no escalation target existed

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the current milestone deadline (8 weeks away, two-week sprints) and velocity data from the last 4 sprints (8, 10, 9, 11 points). A sprint plan is submitted with 14 story points in five stories: Player movement (3), Jump buffering (2, depends on Player movement), Enemy patrol AI (5), Pause menu (2) and Save slots (2). Request is tagged PR-SPRINT.
**Expected:** Assessment uses the provided velocity data to show 14 points is well over the ~9.5-point average (and further over it once the 20% buffer is kept), returns `PR-SPRINT: UNREALISTIC` naming stories to defer, and references the 8-week milestone window to assess what the overrun does to the milestone.
**Assertions:**
- [ ] Uses the specific velocity figures from the provided context (not generic estimates)
- [ ] References the 8-week deadline in the capacity assessment
- [ ] Calculates or estimates remaining sprint count within the milestone window (four two-week sprints), as its duty to flag milestone risk at least 2 sprints ahead requires
- [ ] Names the stories to defer from the five supplied, by title, and never keeps Jump buffering while deferring Player movement, which it depends on
- [ ] Does not give generic scope advice disconnected from the supplied deadline and velocity data

### Case 6: Missing gate input — NOT ASSESSED
**Scenario:** A sprint plan is submitted with five stories — titles, estimates and dependencies, correctly ordered — and the milestone constraints, but no team capacity: the context gives none, and `production/sprints/` holds no earlier sprint to derive a velocity from. Request is tagged PR-SPRINT.
**Expected:** Returns `PR-SPRINT: NOT ASSESSED`, naming team capacity as the input it could not read. Whether a story load is realistic depends on the capacity it is measured against, so no feasibility verdict is given.
**Assertions:**
- [ ] Verdict token is `PR-SPRINT: NOT ASSESSED` — not REALISTIC, and not UNREALISTIC by assumption
- [ ] Names team capacity as the missing input
- [ ] Does not invent a capacity or velocity figure to judge the load against

### Case 7: Phase gate at `minimal` — the brief's Build order is the plan
**Scenario:** `/gate-check production` at `workflow: minimal` runs the panel with `review_mode: lean` set explicitly, so the producer is spawned alone for PR-PHASE-GATE. The context gives the target phase (Production), the tier, and the gate's required artifacts at that tier: a filled `design/game-brief.md` with its Build order, and stories under `production/epics/`. Both are present — the Build order lists four MVP features, the first three independent and the fourth depending on the first, and there is one story per feature in that order, none Blocked. `team.size` is `individual`; the brief states a six-week target for the MVP. The sprint plan and sprint capacity are passed as "not required at `workflow: minimal`".
**Expected:** Returns `PR-PHASE-GATE: READY` — the Build order is the plan at this tier, its dependency is ordered, and four stories fit a solo developer's six weeks. The absent sprint plan and velocity are not findings.
**Assertions:**
- [ ] Verdict is exactly one of READY / CONCERNS / NOT READY (the PR-PHASE-GATE verdicts), formatted as `PR-PHASE-GATE: READY`
- [ ] Judges the Build order as the plan, and checks its dependency order (the fourth feature after the first)
- [ ] Does not raise the missing sprint plan or velocity as a concern, and does not answer NOT ASSESSED for them — they were passed as "not required at `workflow: minimal`"
- [ ] Does not invent a sprint capacity to judge the load against

---

## Protocol Compliance

- [ ] Returns the verdict vocabulary the invoked gate's definition file lists — REALISTIC / CONCERNS / UNREALISTIC for PR-SPRINT and PR-EPIC; REALISTIC / OPTIMISTIC / UNREALISTIC for PR-SCOPE; ON TRACK / AT RISK / OFF TRACK for PR-MILESTONE; READY / CONCERNS / NOT READY for PR-PHASE-GATE; `NOT ASSESSED`, naming the input, at any gate when an input the gate names is missing
- [ ] Stays within declared production domain
- [ ] Escalates design/technical conflicts by quantifying scope impact and presenting to user
- [ ] Uses gate IDs in output (e.g., `PR-SPRINT: REALISTIC`) not inline prose verdicts
- [ ] Does not make binding game design or technical architecture decisions
- [ ] At a phase gate, treats an artifact the target phase requires that the calling skill passes as "none" as a finding (NOT READY or CONCERNS), and one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" as no finding — it judges readiness for the phase being entered, not a later one

---

## Coverage Notes
- PR-EPIC (the epic-structure review `/create-epics` runs before it writes any epic) has no case yet.
- PR-MILESTONE (milestone health review) is not covered — deferred to integration with /milestone-review skill.
- PR-PHASE-GATE is covered at `minimal` (Case 7); a `standard`/`full` Production gate judged against a sprint plan has no case yet.
- Multi-sprint burn-down and velocity trend analysis are not covered here.
