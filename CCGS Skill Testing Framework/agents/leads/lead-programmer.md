# Agent Test Spec: lead-programmer

## Agent Summary
**Domain owned:** Code architecture decisions, LP-FEASIBILITY gate, LP-CODE-REVIEW gate, coding standards enforcement, tech stack decisions within the approved engine.
**Does NOT own:** Game design decisions (game-designer), creative direction (creative-director), production scheduling (producer), visual art direction (art-director).
**Model tier:** Sonnet (implementation-level analysis of individual systems).
**Gate IDs handled:** LP-FEASIBILITY, LP-CODE-REVIEW.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/lead-programmer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references code architecture, feasibility, code review, coding standards — not generic)
- [ ] `allowed-tools:` list includes Read for source files; Bash may be included for static analysis or test runs; no write access outside `src/` without explicit delegation
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over game design, creative direction, or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A new `CombatSystem` implementation is submitted for code review. The system uses dependency injection for all external references, has doc comments on all public APIs, follows the project's naming conventions, and includes unit tests for all public methods. Request is tagged LP-CODE-REVIEW.
**Expected:** Returns `LP-CODE-REVIEW: APPROVED` with rationale confirming dependency injection usage, doc comment coverage, naming convention compliance, and test coverage.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / NEEDS CHANGES
- [ ] Verdict token is formatted as `LP-CODE-REVIEW: APPROVED`
- [ ] Rationale references specific coding standards criteria (DI, doc comments, naming, tests)
- [ ] Output stays within code quality scope — does not comment on whether the mechanic is fun or fits creative vision

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Team member asks lead-programmer to review and approve the balance formula for player damage scaling across levels, checking whether the numbers "feel right."
**Expected:** Agent declines to evaluate design balance and redirects to systems-designer.
**Assertions:**
- [ ] Does not make any binding assessment of formula balance or game feel
- [ ] Explicitly names `systems-designer` as the correct handler
- [ ] May note code implementation concerns about the formula (e.g., integer overflow risk at max level), but defers all balance evaluation to systems-designer

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A proposed pathfinding approach for enemy AI uses a brute-force nearest-neighbor search against all other entities every frame. With expected enemy counts of 200+, this is O(n²) per frame at 60fps. Request is tagged LP-FEASIBILITY.
**Expected:** Returns `LP-FEASIBILITY: INFEASIBLE` with specific citation of the O(n²) complexity, the entity count threshold, and the resulting per-frame cost against the target frame budget.
**Assertions:**
- [ ] Verdict is exactly one of FEASIBLE / CONCERNS / INFEASIBLE — not freeform text
- [ ] Verdict token is formatted as `LP-FEASIBILITY: INFEASIBLE`
- [ ] Rationale includes the specific algorithmic complexity and entity count numbers
- [ ] Suggests at least one alternative approach (e.g., spatial hashing, KD-tree) without mandating a choice

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants a mechanic where every NPC maintains a full simulation of needs, schedule, and memory (similar to a full life-sim AI). lead-programmer calculates this will exceed the frame budget by 3x at target NPC counts. game-designer insists the mechanic is core to the game vision.
**Expected:** lead-programmer states the specific frame budget violation with numbers, proposes alternative approaches (e.g., LOD-based simulation, simplified need model), but explicitly defers the "is this worth the cost or should the design change" decision to creative-director as the creative arbiter.
**Assertions:**
- [ ] States the specific frame budget violation (e.g., 3x over budget at N entities)
- [ ] Proposes at least one technically viable alternative
- [ ] Explicitly defers the design priority decision to `creative-director`
- [ ] Does not unilaterally cut or modify the mechanic design

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the project's frame budget: 16.67ms total per frame, with 4ms allocated to AI systems. A new AI behavior system is submitted that profiling estimates will consume 7ms per frame under normal conditions.
**Expected:** Assessment references the specific frame budget allocation from context (4ms AI budget), identifies the 7ms estimate as exceeding the allocation by 3ms, and returns CONCERNS or INFEASIBLE with those specific numbers cited.
**Assertions:**
- [ ] References the specific frame budget figures from the provided context (16.67ms total, 4ms AI allocation)
- [ ] Uses the specific 7ms estimate from the submission in the comparison
- [ ] Does not give generic "this might be slow" advice — cites concrete numbers
- [ ] Verdict rationale is traceable to the provided budget constraints

---

## Protocol Compliance

- [ ] Returns LP-CODE-REVIEW verdicts using APPROVED / NEEDS CHANGES vocabulary only
- [ ] Returns LP-FEASIBILITY verdicts using FEASIBLE / CONCERNS / INFEASIBLE vocabulary only
- [ ] Stays within declared code architecture domain
- [ ] Defers design priority conflicts to creative-director
- [ ] Uses gate IDs in output (e.g., `LP-FEASIBILITY: INFEASIBLE`) not inline prose verdicts
- [ ] Does not make binding game design or creative direction decisions

---

## Coverage Notes
- Multi-file code review spanning several interdependent systems is not covered — deferred to integration tests.
- Tech debt assessment and prioritization are not covered here — deferred to /tech-debt skill integration.
- Coding standards document updates (adding a new forbidden pattern) are not covered.
- Interaction with qa-lead on what constitutes a testable unit (LP vs QL boundary) is not covered.
