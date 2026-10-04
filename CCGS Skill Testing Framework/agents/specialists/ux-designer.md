# Agent Test Spec: ux-designer

## Agent Summary
Domain: User experience flows, interaction design, information architecture, input handling design, and onboarding UX.
Does NOT own: visual art style (art-director), UI implementation code (ui-programmer).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UX flows / interaction design / information architecture)
- [ ] `tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over visual art direction or UI implementation code

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Design the inventory management flow for a survival game."
**Expected behavior:**
- Before drafting, asks clarifying questions (core player goal, constraints such as input methods and scope, reference games) and presents 2-4 flow options with pros/cons grounded in UX theory (e.g., mental models, progressive disclosure, Fitts's Law), with a recommendation and the final choice deferred to the user
- The drafted flow maps each step and transition: open, browse, select item, sub-actions (equip/drop/combine), close — and names the friction points it removes
- Specifies button assignments and contextual actions for each input method in scope (keyboard/mouse, gamepad, touch if applicable)
- Specifies player feedback for each action (visual, audio, haptic) so the player always knows what happened and why
- Checks the flow against the agent's Accessibility Checklist (keyboard-only, gamepad-only, not reliant on color alone, readable at minimum font size)
- Does NOT produce visual design (colors, icons) or implementation code
- Asks "May I write this to [filepath]?" before writing the spec

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Implement the inventory screen in GDScript with drag-and-drop support."
**Expected behavior:**
- Does NOT produce implementation code
- Explicitly states that UI code implementation belongs to `ui-programmer`
- Redirects the request to `ui-programmer`
- Offers the part of the request it does own: the drag-and-drop interaction design (drag affordance, valid/invalid drop feedback, and a non-drag equivalent so the screen stays usable with gamepad only and keyboard only) for ui-programmer to implement against

### Case 3: Flow depth conflict — simplification
**Input:** "The lead designer says the current 5-step crafting flow is too deep; maximum 3 steps allowed."
**Expected behavior:**
- Presents 2-4 ways to reach a 3-step flow, each with pros/cons and a recommendation, and defers the choice to the user
- For each option, shows which of the 5 steps are merged or removed and what each removed step did for the player, so the usability cost of the collapse is visible
- Does NOT drop a step whose player goal has nowhere else to happen without saying so
- Flags any required use case the 3-step limit cannot serve for user input, and proposes an alternative (e.g., progressive disclosure of advanced options)

### Case 4: Accessibility conflict
**Input:** "The onboarding flow uses a timed prompt (auto-advances after 3 seconds) to keep pace, but this conflicts with accessibility requirements for user-controlled timing."
**Expected behavior:**
- Identifies the conflict: an auto-advancing prompt takes timing out of the player's control
- Does NOT keep the auto-advance to preserve pace — accessibility requirements are not overridden for aesthetics
- Coordinates with `accessibility-specialist`, which owns the WCAG criterion that applies (SC 2.2.1 Timing Adjustable), to agree on a compliant solution
- Presents alternatives as options with pros/cons — player-advanced prompt, skip or pause control, a setting to disable auto-advance — and shows how each keeps the onboarding's information pacing

### Case 5: Context pass — player mental model research
**Input:** Playtest research provided in context: "Players consistently expected the 'Crafting' option to be inside the Inventory screen, not in a separate top-level menu." Request: "Redesign the navigation IA for crafting."
**Expected behavior:**
- References the specific player expectation from the research (crafting expected inside inventory)
- Presents IA options with pros/cons and recommends one that places crafting inside the inventory screen (e.g., a tab or panel), deferring the final choice to the user
- Does NOT recommend a design that contradicts the stated player mental model without explicit justification
- The WHY behind the recommendation cites the playtest finding and names it as the players' mental model

---

## Protocol Compliance

- [ ] Stays within declared domain (UX flows, interaction design, IA, onboarding)
- [ ] Redirects code implementation to ui-programmer, visual style to art-director
- [ ] Presents 2-4 options with pros/cons and a recommendation before drafting, and defers the decision to the user
- [ ] Coordinates with accessibility-specialist when a flow conflicts with an accessibility requirement
- [ ] Grounds recommendations in provided player research when it is given, citing it in the rationale, rather than in assumed behavior
- [ ] Documents rationale for flow decisions against user goals
- [ ] Asks "May I write this to [filepath]?" before writing

---

## Coverage Notes
- Inventory flow (Case 1) should be written to `design/ux/` as a spec for ui-programmer to implement against
- Mental model case (Case 5) verifies the agent applies research evidence, not intuition
- Accessibility coordination (Case 4) confirms the agent does not override accessibility requirements for UX aesthetics
