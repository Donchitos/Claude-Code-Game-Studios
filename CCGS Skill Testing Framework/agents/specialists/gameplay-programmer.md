# Agent Test Spec: gameplay-programmer

## Agent Summary
Domain: Game mechanics code, player systems, combat implementation, and interactive features.
Does NOT own: UI implementation (ui-programmer), AI behavior trees (ai-programmer), engine/rendering systems (engine-programmer).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references game mechanics / player systems)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep — excludes tools only needed by orchestration agents
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over UI, AI behavior, or engine/rendering code

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement a melee combo system where three consecutive light attacks chain into a finisher."
**Expected behavior:**
- Produces code or a code scaffold following the project's language (GDScript/C#) and coding standards
- Models the combo as a state machine with an explicit transition table, and keeps the input-window check and finisher trigger as logic unit tests can drive without the full game running (logic separated from presentation)
- References the relevant GDD section if one is provided in context
- Does NOT implement UI feedback or enemy reactions: emits events/signals for them instead of referencing UI code, leaving the UI side to `ui-programmer` and enemy reactions to `ai-programmer`
- Output includes doc comments on all public methods per coding standards

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Build the main menu screen with pause and settings panels."
**Expected behavior:**
- Does NOT produce menu implementation code
- Explicitly states this is outside its domain
- Redirects the request to `ui-programmer`
- Any part it offers is the gameplay side of the gameplay-to-UI event contract the menu consumes (e.g., pause-state events), agreed with `ui-programmer` — never menu code

### Case 3: Domain boundary — threading flag
**Input:** "The combo system is causing frame stutters; can you add threading to spread the input processing?"
**Expected behavior:**
- Does NOT unilaterally implement threading or async systems
- Flags the threading concern to `engine-programmer` with a clear description of the hot path
- Any interim step it offers stays single-threaded (less work per frame in the combo code it owns) and is proposed for approval before any code changes
- Documents the escalation so lead-programmer is aware

### Case 4: Conflict with an Accepted ADR
**Input:** "Change the damage calculation to use floating-point accumulation directly instead of the fixed-point formula in ADR-003."
**Expected behavior:**
- Identifies that the proposed change violates ADR-003 (Accepted status)
- Does NOT silently implement the violation
- Flags the conflict to `lead-programmer` with the ADR reference and the trade-off described
- Implements the change only after ADR-003 is superseded by a new ADR through `/architecture-decision` — which only the user, or technical-director on the user's confirmation, moves to Accepted — never on the original request alone, and not on lead-programmer's approval alone

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
- [ ] Does not modify engine-level systems without lead-programmer approval, and does not write networking code (delegates to network-programmer)
- [ ] Flags ADR violations rather than overriding them silently
- [ ] Makes gameplay values data-driven, never hardcoded
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Combo system test (Case 1) should be validated with a unit test in `tests/unit/gameplay/`
- Threading escalation (Case 3) verifies the agent does not over-reach into engine territory
- ADR conflict (Case 4) confirms the agent respects the architecture governance process
- Cases 1 and 5 together verify the agent implements to spec rather than improvising
