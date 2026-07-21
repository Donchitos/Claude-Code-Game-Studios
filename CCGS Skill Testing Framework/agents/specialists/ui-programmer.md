# Agent Test Spec: ui-programmer

## Agent Summary
Domain: Menu screens, HUDs, inventory screens, dialogue boxes, UI framework code, and data binding.
Does NOT own: UX flow design (ux-designer), visual style direction (art-director / technical-artist).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references menus / HUDs / UI framework / data binding)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UX flow design or visual art direction

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement the inventory screen from the UX spec in `design/ux/inventory-flow.md`."
**Expected behavior:**
- Reads the UX spec before producing any code
- Produces implementation using the project's configured UI framework (UI Toolkit, UGUI, UMG, or Godot Control nodes)
- Implements all states defined in the spec (default, hover, selected, empty-slot, locked-slot)
- Binds inventory data to UI elements via the project's data model, not hardcoded values
- Includes doc comments on public UI API per coding standards

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Design the inventory interaction flow — what happens when the player equips, drops, or combines items."
**Expected behavior:**
- Does NOT produce interaction flow design or user flow diagrams
- Explicitly states that UX flow design belongs to `ux-designer`
- Redirects the request to `ux-designer`
- Notes that once the flow spec is ready, it can implement it

### Case 3: Custom animation coordination
**Input:** "The item selection in the inventory needs a custom bounce animation when selected."
**Expected behavior:**
- Recognizes that defining the animation curve and feel is within technical-artist territory
- Does NOT invent animation parameters (timing, easing) without a spec
- Coordinates with `technical-artist` for an animation spec (duration, easing curve, overshoot amount)
- Once the spec is provided, produces the implementation binding the animation to the selection state

### Case 4: Ambiguous UX spec — flags back
**Input:** The UX spec states "show item details on selection" but does not define what happens when an empty slot is selected.
**Expected behavior:**
- Identifies the ambiguity in the spec (empty slot selection state is undefined)
- Does NOT make an arbitrary implementation decision for the undefined state
- Flags the ambiguity back to `ux-designer` with the specific question: "What should the detail panel show when an empty inventory slot is selected?"
- May propose two common options (hide panel / show placeholder) to help ux-designer decide quickly

### Case 5: Context pass — engine UI toolkit
**Input:** Engine context provided: project uses Godot 4.6 with Control node UI. Request: "Implement a scrollable item list for the inventory."
**Expected behavior:**
- Uses Godot's `ScrollContainer` + `VBoxContainer` + `ItemList` (or equivalent) pattern, not Canvas or UGUI
- Does NOT produce Unity UGUI or Unreal UMG code for a Godot project
- Checks the engine version reference (4.6) for any Control node API changes from 4.4/4.5 before using specific APIs
- Produces GDScript or C# code consistent with the project's configured language

---

## Protocol Compliance

- [ ] Stays within declared domain (menus, HUDs, UI framework, data binding)
- [ ] Redirects UX flow design to ux-designer
- [ ] Coordinates with technical-artist for animation specs before implementing animations
- [ ] Flags ambiguous UX specs back to ux-designer rather than making arbitrary implementation decisions
- [ ] Returns structured output (implementation code, data binding patterns, state machine for UI states)
- [ ] Uses the correct engine UI toolkit for the project — never cross-engine code

---

## Coverage Notes
- Inventory implementation (Case 1) should have a UI interaction test or manual walkthrough doc in `production/qa/evidence/`
- Animation coordination (Case 3) confirms the agent does not invent feel parameters without a spec
- Ambiguous spec (Case 4) verifies the agent routes spec gaps back to the authoring agent rather than guessing
