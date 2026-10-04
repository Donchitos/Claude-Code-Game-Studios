# Agent Test Spec: creative-director

## Agent Summary
**Domain owned:** Creative vision, game pillars, GDD alignment, systems decomposition feedback, narrative direction, playtest feedback interpretation, phase gate (creative aspect).
**Does NOT own:** Technical architecture or implementation details (delegates to technical-director), production scheduling (producer), visual art style execution (delegates to art-director).
**Gate IDs handled:** CD-PILLARS, CD-GDD-ALIGN, CD-SYSTEMS, CD-NARRATIVE, CD-PLAYTEST, CD-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/creative-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references creative vision, pillars, GDD alignment — not generic)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, WebSearch and `disallowedTools:` lists Bash
- [ ] Model tier is `opus` — frontmatter `model:` reads exactly `opus` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over technical architecture or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** The pillar set for a narrative survival game is submitted for a stress test, with its anti-pillars, core fantasy and unique hook. The hook names its closest comparable — "Like *Don't Starve*, AND ALSO every survivor you lose changes the world for good" — and none of the three pillars is a goal that comparable is built around. It has three pillars — "emergent stories," "meaningful sacrifice," and "lived-in world" — each with a definition and a design test that names a real decision it would settle; the pillars pull against each other (sacrifice vs. a world the player wants to preserve). Request is tagged CD-PILLARS.
**Expected:** Returns `CD-PILLARS: APPROVE` with specific feedback on each pillar, judged by the gate's criteria: is it falsifiable, does it create tension with the others, does it differentiate the game, would it settle a real design disagreement.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT
- [ ] Verdict token is formatted as `CD-PILLARS: APPROVE` (gate ID prefix, colon, verdict keyword)
- [ ] Gives feedback on each of the three pillars by name against the gate's criteria (falsifiability, tension, differentiation from *Don't Starve*), not generic creative advice
- [ ] Output stays within creative scope — does not comment on engine feasibility or sprint schedule

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Developer asks creative-director to review a proposed PostgreSQL schema for storing player save data.
**Expected:** Agent declines to evaluate the schema and redirects to technical-director.
**Assertions:**
- [ ] Does not make any binding decision about the schema design
- [ ] Explicitly names `technical-director` as the correct handler
- [ ] Any comment on the schema is limited to its creative implications (e.g., which player choices a save must remember) — it proposes no table, column, key or query design

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A GDD for the "Crafting" system is submitted with the game's pillars — "curiosity is always rewarded" and "the world remembers" — and its MDA target, Discovery first. Section 4 (Formulas) defines a resource decay formula that punishes exploration — contradicting the Player Fantasy section which calls for "freedom to roam without fear," and working against the curiosity pillar. Every other section serves the pillars, and retuning the formula would resolve the conflict without redesigning the system. Request is tagged CD-GDD-ALIGN.
**Expected:** Returns `CD-GDD-ALIGN: CONCERNS` with specific citation of the contradiction between the formula behavior and the Player Fantasy statement. The fix is stated as a creative constraint; the formula itself is left to the design team.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT — not freeform text
- [ ] Verdict token is formatted as `CD-GDD-ALIGN: CONCERNS`
- [ ] Rationale quotes or directly references GDD Section 4 (Formulas), the Player Fantasy section and the "curiosity is always rewarded" pillar
- [ ] States the fix as a creative constraint (e.g., decay must not punish roaming) and leaves the formula to `game-designer`, its delegate for mechanical design — does not author replacement formula values

### Case 4: Conflict escalation — correct parent
**Scenario:** technical-director raises a concern that the core loop mechanic (real-time branching conversations) is prohibitively expensive to implement and recommends cutting it. creative-director disagrees on creative grounds.
**Expected:** creative-director acknowledges the technical constraint, does not override technical-director's feasibility assessment, but retains authority to define what the creative goal is. For the conflict itself, creative-director is the top-level creative escalation point and defers to technical-director on implementation feasibility while advocating for the design intent. The resolution path is for both to jointly present trade-off options to the user.
**Assertions:**
- [ ] Does not unilaterally override technical-director's feasibility concern
- [ ] Clearly separates "what we want creatively" from "how it gets built"
- [ ] Proposes presenting trade-offs to the user rather than resolving unilaterally
- [ ] Does not claim to own implementation decisions

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the game pillars document (`design/gdd/game-pillars.md`) and a new system GDD for review. The pillars document defines "player authorship," "consequence permanence," and "world responsiveness" as the three core pillars. Request is tagged CD-GDD-ALIGN.
**Expected:** Assessment uses the exact pillar vocabulary from the provided document, not generic creative heuristics. Any approval or concern is tied back to one or more of the three named pillars.
**Assertions:**
- [ ] Uses the exact pillar names from the provided context document
- [ ] Does not generate generic creative feedback disconnected from the supplied pillars
- [ ] References the specific pillar(s) most relevant to the mechanic under review
- [ ] Does not reference pillars not present in the provided document

### Case 6: Missing gate input — NOT ASSESSED
**Scenario:** A complete, internally consistent system GDD is submitted with its Player Fantasy section, but no game pillars: the context gives none, and none of `design/gdd/game-concept.md`, `design/gdd/game-pillars.md` or `design/game-brief.md` exists. Request is tagged CD-GDD-ALIGN.
**Expected:** Returns `CD-GDD-ALIGN: NOT ASSESSED`, naming the game pillars as the input it could not read. Alignment with pillars nobody supplied cannot be judged, so no alignment verdict is given.
**Assertions:**
- [ ] Verdict token is `CD-GDD-ALIGN: NOT ASSESSED` — not APPROVE, although nothing in the GDD itself looks wrong
- [ ] Names the game pillars as the missing input
- [ ] Does not infer pillars from the GDD under review and judge alignment against them

---

## Protocol Compliance

- [ ] Returns the verdict vocabulary the invoked gate's definition file lists — APPROVE / CONCERNS / REJECT for CD-PILLARS, CD-GDD-ALIGN, CD-SYSTEMS, CD-NARRATIVE and CD-PLAYTEST; READY / CONCERNS / NOT READY for CD-PHASE-GATE; `NOT ASSESSED`, naming the input, at any gate when an input the gate names is missing
- [ ] Stays within declared creative domain
- [ ] Escalates conflicts by presenting trade-offs to user rather than unilateral override
- [ ] Uses gate IDs in output (e.g., `CD-PILLARS: APPROVE`) not inline prose verdicts
- [ ] Does not make binding cross-domain decisions (technical, production, art execution)
- [ ] At a phase gate, treats an artifact the target phase requires that the calling skill passes as "none" as a finding (NOT READY or CONCERNS), and one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" as no finding — it judges readiness for the phase being entered, not a later one

---

## Coverage Notes
- Multi-gate scenario (e.g., single submission triggering both CD-PILLARS and CD-GDD-ALIGN) is not covered here — deferred to integration tests.
- CD-PHASE-GATE (the creative director's own readiness review, which `/gate-check` runs at `workflow: full`) has no case yet.
- CD-PLAYTEST (review of a `/playtest-report` report) has no case yet.
- Interaction with art-director on visual-pillar alignment is not covered.
