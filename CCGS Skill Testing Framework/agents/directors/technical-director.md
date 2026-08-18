# Agent Test Spec: technical-director

## Agent Summary
**Domain owned:** System architecture decisions, technical feasibility assessment, ADR oversight and approval, engine risk evaluation, technical phase gate.
**Does NOT own:** Game design decisions (creative-director / game-designer), creative direction, visual art style, production scheduling (producer).
**Model tier:** Opus (multi-document synthesis, high-stakes architecture and phase gate verdicts).
**Gate IDs handled:** TD-SYSTEM-BOUNDARY, TD-FEASIBILITY, TD-ARCHITECTURE, TD-ADR, TD-ENGINE-RISK, TD-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/technical-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references architecture, feasibility, ADR — not generic)
- [ ] `allowed-tools:` list may include Read for architecture documents; Bash only if required for technical checks
- [ ] Model tier is `opus` per coordination-rules.md (directors with gate synthesis = Opus)
- [ ] Agent definition does not claim authority over game design decisions or creative direction

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** An architecture document for the "Combat System" is submitted. It describes a layered design: input layer → game logic layer → presentation layer, with clearly defined interfaces between each. Request is tagged TD-ARCHITECTURE.
**Expected:** Returns `TD-ARCHITECTURE: APPROVE` with rationale confirming that system boundaries are correctly separated and interfaces are well-defined.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT
- [ ] Verdict token is formatted as `TD-ARCHITECTURE: APPROVE`
- [ ] Rationale specifically references the layered structure and interface definitions — not generic architecture advice
- [ ] Output stays within technical scope — does not comment on whether the mechanic is fun or fits the creative vision

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Writer asks technical-director to review and approve the dialogue scripts for the game's opening cutscene.
**Expected:** Agent declines to evaluate dialogue quality and redirects to narrative-director.
**Assertions:**
- [ ] Does not make any binding decision about the dialogue content or structure
- [ ] Explicitly names `narrative-director` as the correct handler
- [ ] May note technical constraints that affect dialogue (e.g., localization string limits, data format), but defers all content decisions

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A proposed multiplayer mechanic requires raycasting against all active entities every frame to detect line-of-sight. At expected player counts (1000 entities in a large zone), this is O(n²) per frame. Request is tagged TD-FEASIBILITY.
**Expected:** Returns `TD-FEASIBILITY: CONCERNS` with specific citation of the O(n²) complexity and the entity count that makes this infeasible at target framerate.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT — not freeform text
- [ ] Verdict token is formatted as `TD-FEASIBILITY: CONCERNS`
- [ ] Rationale includes the specific algorithmic complexity concern and the entity count threshold
- [ ] Suggests at least one alternative approach (e.g., spatial partitioning, interest management) without mandating which to choose

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants to add a real-time physics simulation for every inventory item (hundreds of items on screen simultaneously). technical-director assesses this as technically expensive and proposes simplifying the simulation. game-designer disagrees, arguing it is essential to the game feel.
**Expected:** technical-director clearly states the technical cost and constraints, proposes alternative implementation approaches that could achieve a similar feel, but explicitly defers the final design priority decision to creative-director as the arbiter of player experience trade-offs.
**Assertions:**
- [ ] Expresses the technical concern with specifics (e.g., performance budget, estimated cost)
- [ ] Proposes at least one alternative that could reduce cost while preserving intent
- [ ] Explicitly defers the "is this worth the cost" decision to creative-director — does not unilaterally cut the feature
- [ ] Does not claim authority to override game-designer's design intent

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the target platform constraints: mobile, 60fps target, 2GB RAM ceiling, no compute shaders. A proposed architecture includes a GPU-driven rendering pipeline.
**Expected:** Assessment references the specific hardware constraints from the context, identifies the compute shader dependency as incompatible with the stated platform constraints, and returns a CONCERNS or REJECT verdict with those specifics cited.
**Assertions:**
- [ ] References the specific platform constraints provided (mobile, 2GB RAM, no compute shaders)
- [ ] Does not give generic performance advice disconnected from the supplied constraints
- [ ] Correctly identifies the architectural component that conflicts with the platform constraint
- [ ] Verdict includes rationale tied to the provided context, not boilerplate warnings

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVE / CONCERNS / REJECT vocabulary only
- [ ] Stays within declared technical domain
- [ ] Defers design priority conflicts to creative-director
- [ ] Uses gate IDs in output (e.g., `TD-FEASIBILITY: CONCERNS`) not inline prose verdicts
- [ ] Does not make binding game design or creative direction decisions

---

## Coverage Notes
- TD-ADR (Architecture Decision Record approval) is not covered — a dedicated case should be added when the /architecture-decision skill produces ADR documents.
- TD-ENGINE-RISK assessment for specific engine versions (e.g., Godot 4.6 post-cutoff APIs) is not covered — deferred to engine-specialist integration tests.
- TD-PHASE-GATE (full technical phase advancement) involving synthesis of multiple sub-gate results is deferred.
- Multi-domain architecture reviews (e.g., touching both TD-ARCHITECTURE and TD-ENGINE-RISK simultaneously) are not covered here.
