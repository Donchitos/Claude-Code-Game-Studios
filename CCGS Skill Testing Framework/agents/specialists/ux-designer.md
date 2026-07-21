# Agent Test Spec: ux-designer

## Agent Summary
Domain: User experience flows, interaction design, information architecture, input handling design, and onboarding UX.
Does NOT own: visual art style (art-director), UI implementation code (ui-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UX flows / interaction design / information architecture)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over visual art direction or UI implementation code

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Design the inventory management flow for a survival game."
**Expected behavior:**
- Produces a user flow diagram (states and transitions) for the inventory: open, browse, select item, sub-actions (equip/drop/combine), close
- Defines all interaction states (default, hover, selected, empty-slot, locked-slot)
- Specifies input mappings for each action (keyboard, gamepad if applicable)
- Notes cognitive load considerations (e.g., maximum items visible without scrolling)
- Does NOT produce visual design (colors, icons) or implementation code

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Implement the inventory screen in GDScript with drag-and-drop support."
**Expected behavior:**
- Does NOT produce implementation code
- Explicitly states that UI code implementation belongs to `ui-programmer`
- Redirects the request to `ui-programmer`
- Notes that the UX flow spec should be provided to ui-programmer as the implementation reference

### Case 3: Flow depth conflict — simplification
**Input:** "The lead designer says the current 5-step crafting flow is too deep; maximum 3 steps allowed."
**Expected behavior:**
- Produces a revised 3-step flow that collapses the original 5-step sequence
- Shows clearly what was merged or removed and why each collapse is safe from a usability standpoint
- Does NOT simply remove steps without addressing the user's goal at each removed step
- Flags if the 3-step constraint makes any required use case impossible and proposes an alternative

### Case 4: Accessibility conflict
**Input:** "The onboarding flow uses a timed prompt (auto-advances after 3 seconds) to keep pace, but this conflicts with accessibility requirements for user-controlled timing."
**Expected behavior:**
- Identifies the conflict with WCAG 2.1 2.2.1 (Timing Adjustable)
- Does NOT override the accessibility requirement to preserve pace
- Coordinates with `accessibility-specialist` to agree on a compliant solution
- Proposes alternatives: pause-on-hover, skip button, settings option to disable auto-advance

### Case 5: Context pass — player mental model research
**Input:** Playtest research provided in context: "Players consistently expected the 'Crafting' option to be inside the Inventory screen, not in a separate top-level menu." Request: "Redesign the navigation IA for crafting."
**Expected behavior:**
- References the specific player expectation from the research (crafting expected inside inventory)
- Restructures the information architecture to place crafting as a tab or panel within the inventory screen
- Does NOT produce a design that contradicts the stated player mental model without explicit justification
- Notes the research source in the rationale for the design decision

---

## Protocol Compliance

- [ ] Stays within declared domain (UX flows, interaction design, IA, onboarding)
- [ ] Redirects code implementation to ui-programmer, visual style to art-director
- [ ] Returns structured findings (state diagrams, flow steps, input mappings) not freeform opinions
- [ ] Coordinates with accessibility-specialist when flows have timing or cognitive load constraints
- [ ] Designs flows based on provided user research, not assumed behavior
- [ ] Documents rationale for flow decisions against user goals

---

## Coverage Notes
- Inventory flow (Case 1) should be written to `design/ux/` as a spec for ui-programmer to implement against
- Mental model case (Case 5) verifies the agent applies research evidence, not intuition
- Accessibility coordination (Case 4) confirms the agent does not override accessibility requirements for UX aesthetics
