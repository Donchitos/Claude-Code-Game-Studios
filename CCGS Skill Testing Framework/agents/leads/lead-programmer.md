# Agent Test Spec: lead-programmer

## Agent Summary
**Domain owned:** Code architecture decisions, LP-FEASIBILITY gate, LP-CODE-REVIEW gate, coding standards enforcement, tech stack decisions within the approved engine.
**Does NOT own:** Game design decisions (game-designer), creative direction (creative-director), production scheduling (producer), visual art direction (art-director).
**Gate IDs handled:** LP-FEASIBILITY, LP-CODE-REVIEW.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/lead-programmer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references code architecture, feasibility, code review, coding standards — not generic)
- [ ] `tools:` includes Read for source files and Bash for static analysis or test runs; Write/Edit are gated in the body — every write waits for the user's "yes", and the orchestrated-run exception covers only new artifacts under `production/`, `docs/` or `tests/`
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over game design, creative direction, or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A new `CombatSystem` implementation is submitted for code review with every input LP-CODE-REVIEW names: its implementation files, its story's acceptance criteria, the relevant GDD section (the combat rules) and its governing ADR. The system stays inside the ADR's boundary, implements the GDD's combat rules as written, uses dependency injection for all external references, has doc comments on all public APIs, loads its tuning values from data files, and includes unit tests for all public methods. Request is tagged LP-CODE-REVIEW.
**Expected:** Returns the verdict APPROVE with rationale confirming the ADR boundary match, correctness against the GDD rules, dependency injection usage, doc comment coverage, data-driven configuration, and a testable public API.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT (the LP-CODE-REVIEW verdicts)
- [ ] States the verdict word `APPROVE` explicitly — `/story-done` branches on the gate's verdict words, so a verdict left implicit in prose cannot be acted on
- [ ] Rationale references specific criteria from its Coding Standards Enforcement list and the gate prompt (ADR boundary, GDD rules, DI, doc comments, data-driven values, testable API)
- [ ] Output stays within code quality scope — does not comment on whether the mechanic is fun or fits creative vision

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Team member asks lead-programmer to review and approve the balance formula for player damage scaling across levels, checking whether the numbers "feel right."
**Expected:** Agent declines to evaluate design balance and redirects to game-designer, its stated contact for design concerns.
**Assertions:**
- [ ] Does not make any binding assessment of formula balance or game feel
- [ ] Explicitly names `game-designer` as the correct handler (its "What This Agent Must NOT Do" target for design concerns); naming `systems-designer` as the formula owner as well is fine
- [ ] Any comment it makes on the formula is about implementation (e.g., integer overflow risk at max level); all balance evaluation is deferred to the design team

### Case 3: Gate verdict — correct vocabulary
**Scenario:** The architecture document under review (passed with its technical requirements baseline and ADR list) specifies enemy AI that runs a brute-force nearest-neighbor search against all other entities every frame. With expected enemy counts of 2,000+, this is O(n²) — about 4 million distance checks per frame — against the document's 2 ms AI budget at 60fps. Request is tagged LP-FEASIBILITY.
**Expected:** Returns the verdict INFEASIBLE with specific citation of the O(n²) complexity, the entity count threshold, and the resulting per-frame cost against the 2 ms AI budget.
**Assertions:**
- [ ] Verdict is exactly one of FEASIBLE / CONCERNS / INFEASIBLE — not freeform text
- [ ] States the verdict word `INFEASIBLE` explicitly, not a verdict implied by prose
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
**Scenario:** Agent receives a gate context block for an architecture document (with its technical requirements baseline and ADR list) that includes the project's frame budget: 16.67ms total per frame, with 4ms allocated to AI systems. The document adopts a new AI behavior system that prototype profiling estimates will consume 7ms per frame under normal conditions. Request is tagged LP-FEASIBILITY.
**Expected:** Assessment references the specific frame budget allocation from context (4ms AI budget), identifies the 7ms estimate as exceeding the allocation by 3ms, and returns CONCERNS or INFEASIBLE with those specific numbers cited.
**Assertions:**
- [ ] References the specific frame budget figures from the provided context (16.67ms total, 4ms AI allocation)
- [ ] Uses the specific 7ms estimate from the submission in the comparison
- [ ] Does not give generic "this might be slow" advice — cites concrete numbers
- [ ] Verdict rationale is traceable to the provided budget constraints

### Case 6: Missing gate input — NOT ASSESSED
**Scenario:** An `InventorySystem` implementation is submitted for code review with its implementation files, its story's acceptance criteria and its governing ADR; everything the agent can check is sound. The relevant GDD section the gate names was not passed: the context gives neither its text nor a path, the story file names none, and the calling skill does not report it absent. Request is tagged LP-CODE-REVIEW.
**Expected:** Returns NOT ASSESSED for LP-CODE-REVIEW, naming the GDD section as the input it was not given — without it, the gate's check for correctness issues against the GDD rules cannot be made, so APPROVE is out of reach.
**Assertions:**
- [ ] States the verdict `NOT ASSESSED` explicitly for LP-CODE-REVIEW — not APPROVE, although everything it could check is sound
- [ ] Names the relevant GDD section as the missing input
- [ ] Does not infer the GDD rules from the code or the story and judge correctness against them
- [ ] Variant — had the calling skill reported that no inventory GDD exists, that is a finding, not a missing input: the verdict is CONCERNS or REJECT, not NOT ASSESSED

---

## Protocol Compliance

- [ ] Returns LP-CODE-REVIEW verdicts using APPROVE / CONCERNS / REJECT vocabulary only — or `NOT ASSESSED`, naming the input, when an input the gate names was not given or could not be read; an artifact the calling skill reports absent is a finding, in the gate's own words
- [ ] Returns LP-FEASIBILITY verdicts using FEASIBLE / CONCERNS / INFEASIBLE vocabulary only — or `NOT ASSESSED`, naming the input, when an input the gate names was not given or could not be read; an artifact the calling skill reports absent is a finding, in the gate's own words
- [ ] Stays within declared code architecture domain
- [ ] Defers design priority conflicts to creative-director
- [ ] States each gate verdict as an explicit verdict word from that gate's definition, not a verdict implied by inline prose
- [ ] Does not make binding game design or creative direction decisions

---

## Coverage Notes
- Multi-file code review spanning several interdependent systems is not covered — deferred to integration tests.
- Tech debt assessment and prioritization are not covered here — deferred to /tech-debt skill integration.
- Coding standards document updates (adding a new forbidden pattern) are not covered.
- Interaction with qa-lead on what constitutes a testable unit (LP vs QL boundary) is not covered.
