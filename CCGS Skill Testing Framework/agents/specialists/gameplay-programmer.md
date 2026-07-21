# Agent Test Spec: gameplay-programmer

## Agent Summary
Domain: Game mechanics code, player systems, combat implementation, and interactive features.
Does NOT own: UI implementation (ui-programmer), AI behavior trees (ai-programmer), engine/rendering systems (engine-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references game mechanics / player systems)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UI, AI behavior, or engine/rendering code

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement a melee combo system where three consecutive light attacks chain into a finisher."
**Expected behavior:**
- Produces code or a code scaffold following the project's language (GDScript/C#) and coding standards
- Defines combo state tracking, input window timing, and finisher trigger logic as separate, testable methods
- References the relevant GDD section if one is provided in context
- Does NOT implement UI feedback (delegates to ui-programmer) or AI reaction (delegates to ai-programmer)
- Output includes doc comments on all public methods per coding standards

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Build the main menu screen with pause and settings panels."
**Expected behavior:**
- Does NOT produce menu implementation code
- Explicitly states this is outside its domain
- Redirects the request to `ui-programmer`
- May note that if the pause menu requires reading gameplay state it can provide the state API surface

### Case 3: Domain boundary — threading flag
**Input:** "The combo system is causing frame stutters; can you add threading to spread the input processing?"
**Expected behavior:**
- Does NOT unilaterally implement threading or async systems
- Flags the threading concern to `engine-programmer` with a clear description of the hot path
- May produce a non-threaded refactor to reduce work per frame as a safe interim step
- Documents the escalation so lead-programmer is aware

### Case 4: Conflict with an Accepted ADR
**Input:** "Change the damage calculation to use floating-point accumulation directly instead of the fixed-point formula in ADR-003."
**Expected behavior:**
- Identifies that the proposed change violates ADR-003 (Accepted status)
- Does NOT silently implement the violation
- Flags the conflict to `lead-programmer` with the ADR reference and the trade-off described
- Will implement only after explicit override decision from lead-programmer or technical-director

### Case 5: Context pass — implements to GDD spec
**Input:** GDD for "PlayerCombat" provided in context. Request: "Implement the stamina drain formula from the combat GDD."
**Expected behavior:**
- Reads the formula section of the provided GDD
- Implements the exact formula as written — does NOT invent new variables or adjust coefficients
- Makes stamina drain a data-driven value (external config), not a hardcoded constant
- Notes any edge cases from the GDD's edge-cases section and handles them in code

---

## Protocol Compliance

- [ ] Stays within declared domain (mechanics, player systems, combat)
- [ ] Redirects out-of-domain requests to correct agent (ui-programmer, ai-programmer, engine-programmer)
- [ ] Returns structured findings (code scaffold, method signatures, inline comments) not freeform opinions
- [ ] Does not modify files outside `src/gameplay/` or `src/core/` without explicit delegation
- [ ] Flags ADR violations rather than overriding them silently
- [ ] Makes gameplay values data-driven, never hardcoded

---

## Coverage Notes
- Combo system test (Case 1) should be validated with a unit test in `tests/unit/gameplay/`
- Threading escalation (Case 3) verifies the agent does not over-reach into engine territory
- ADR conflict (Case 4) confirms the agent respects the architecture governance process
- Cases 1 and 5 together verify the agent implements to spec rather than improvising
