# Agent Test Spec: creative-director

## Agent Summary
**Domain owned:** Creative vision, game pillars, GDD alignment, systems decomposition feedback, narrative direction, playtest feedback interpretation, phase gate (creative aspect).
**Does NOT own:** Technical architecture or implementation details (delegates to technical-director), production scheduling (producer), visual art style execution (delegates to art-director).
**Model tier:** Opus (multi-document synthesis, high-stakes phase gate verdicts).
**Gate IDs handled:** CD-PILLARS, CD-GDD-ALIGN, CD-SYSTEMS, CD-NARRATIVE, CD-PLAYTEST, CD-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/creative-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references creative vision, pillars, GDD alignment — not generic)
- [ ] `allowed-tools:` list is read-heavy; should not include Bash unless justified by a creative workflow need
- [ ] Model tier is `opus` per coordination-rules.md (directors with gate synthesis = Opus)
- [ ] Agent definition does not claim authority over technical architecture or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A game concept document is submitted for pillar review. The concept describes a narrative survival game built around three pillars: "emergent stories," "meaningful sacrifice," and "lived-in world." Request is tagged CD-PILLARS.
**Expected:** Returns `CD-PILLARS: APPROVE` with rationale citing how each pillar is represented in the concept and any reinforcing or weakening signals found in the document.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT
- [ ] Verdict token is formatted as `CD-PILLARS: APPROVE` (gate ID prefix, colon, verdict keyword)
- [ ] Rationale references the three specific pillars by name, not generic creative advice
- [ ] Output stays within creative scope — does not comment on engine feasibility or sprint schedule

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Developer asks creative-director to review a proposed PostgreSQL schema for storing player save data.
**Expected:** Agent declines to evaluate the schema and redirects to technical-director.
**Assertions:**
- [ ] Does not make any binding decision about the schema design
- [ ] Explicitly names `technical-director` as the correct handler
- [ ] May note whether the data model has creative implications (e.g., what player data is tracked), but defers structural decisions entirely

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A GDD for the "Crafting" system is submitted. Section 4 (Formulas) defines a resource decay formula that punishes exploration — contradicting the Player Fantasy section which calls for "freedom to roam without fear." Request is tagged CD-GDD-ALIGN.
**Expected:** Returns `CD-GDD-ALIGN: CONCERNS` with specific citation of the contradiction between the formula behavior and the Player Fantasy statement.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT — not freeform text
- [ ] Verdict token is formatted as `CD-GDD-ALIGN: CONCERNS`
- [ ] Rationale quotes or directly references GDD Section 4 (Formulas) and the Player Fantasy section
- [ ] Does not prescribe a specific formula fix — that belongs to systems-designer

### Case 4: Conflict escalation — correct parent
**Scenario:** technical-director raises a concern that the core loop mechanic (real-time branching conversations) is prohibitively expensive to implement and recommends cutting it. creative-director disagrees on creative grounds.
**Expected:** creative-director acknowledges the technical constraint, does not override technical-director's feasibility assessment, but retains authority to define what the creative goal is. For the conflict itself, creative-director is the top-level creative escalation point and defers to technical-director on implementation feasibility while advocating for the design intent. The resolution path is for both to jointly present trade-off options to the user.
**Assertions:**
- [ ] Does not unilaterally override technical-director's feasibility concern
- [ ] Clearly separates "what we want creatively" from "how it gets built"
- [ ] Proposes presenting trade-offs to the user rather than resolving unilaterally
- [ ] Does not claim to own implementation decisions

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the game pillars document (`design/gdd/pillars.md`) and a new mechanic spec for review. The pillars document defines "player authorship," "consequence permanence," and "world responsiveness" as the three core pillars.
**Expected:** Assessment uses the exact pillar vocabulary from the provided document, not generic creative heuristics. Any approval or concern is tied back to one or more of the three named pillars.
**Assertions:**
- [ ] Uses the exact pillar names from the provided context document
- [ ] Does not generate generic creative feedback disconnected from the supplied pillars
- [ ] References the specific pillar(s) most relevant to the mechanic under review
- [ ] Does not reference pillars not present in the provided document

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVE / CONCERNS / REJECT vocabulary only
- [ ] Stays within declared creative domain
- [ ] Escalates conflicts by presenting trade-offs to user rather than unilateral override
- [ ] Uses gate IDs in output (e.g., `CD-PILLARS: APPROVE`) not inline prose verdicts
- [ ] Does not make binding cross-domain decisions (technical, production, art execution)

---

## Coverage Notes
- Multi-gate scenario (e.g., single submission triggering both CD-PILLARS and CD-GDD-ALIGN) is not covered here — deferred to integration tests.
- CD-PHASE-GATE (full phase advancement) involves synthesizing multiple sub-gate results; this complex case is deferred.
- Playtest report interpretation (CD-PLAYTEST) is not covered — a dedicated case should be added when the playtest-report skill produces structured output.
- Interaction with art-director on visual-pillar alignment is not covered.
