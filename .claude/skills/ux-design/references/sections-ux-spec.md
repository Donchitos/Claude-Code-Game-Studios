> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — UX Spec Mode


#### Section A: Purpose & Player Need

This section is the foundation. Every other decision flows from it.

**Questions to ask**:
- "What player goal does this screen serve? What is the player trying to DO here?"
- "What would go wrong if this screen didn't exist or was hard to use?"
- "Complete this sentence: 'The player arrives at this screen wanting to ___.' "

Cross-reference the player journey context gathered in Phase 2. The stated purpose
must align with the journey phase and emotional state.

---

#### Section B: Player Context on Arrival

**Questions to ask**:
- "When in the game does a player first encounter this screen?"
- "What were they just doing immediately before reaching this screen?"
- "What emotional state should the design assume? (calm, stressed, curious, time-pressured)"
- "Do players arrive at this screen voluntarily, or are they sent here by the game?"

Offer to map this against the journey phases if the player journey doc exists.

---

#### Section B2: Navigation Position

Where does this screen sit in the game's navigation hierarchy? This is a one-paragraph orientation map — not a full flow diagram.

**Questions to ask**:
- "Is this screen accessed from the main menu, from pause, from within gameplay, or from another screen?"
- "Is it a top-level destination (always reachable) or a context-dependent one (only accessible in certain states)?"
- "Can the player reach this screen from more than one place in the game?"

Present as: "This screen lives at: [root] → [parent] → [this screen]" plus any alternate entry paths.

---

#### Section B3: Entry & Exit Points

Map every way the player can arrive at and leave this screen.

**Questions to ask**:
- "What are all the ways a player can reach this screen?" (List each trigger: button press, game event, redirect from another screen, etc.)
- "What can the player do to exit? What happens when they do?" (Back button, confirm action, timeout, game event)
- "Are there any exits that are one-way — where the player cannot return to this screen without starting over?"

Present as two tables:

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| [screen/event] | [how] | [state/data they arrive with] |

| Exit Destination | Trigger | Notes |
|---|---|---|
| [screen/event] | [how] | [any irreversible state changes] |

---

#### Section C: Layout Specification

This is the largest and most interactive section. Work through it in sub-sections:

**Sub-section 1 — Information Hierarchy** (establish this before any layout):
- Ask the user to list every piece of information this screen must communicate.
- Then ask them to rank the items: "What is the single most important thing a player
  needs to see first? What is second? What can be discovered rather than immediately visible?"
- Present the resulting hierarchy for approval before moving to zones.

**Sub-section 2 — Layout Zones**:
- Based on the information hierarchy, propose rough screen zones (header, content
  area, action bar, sidebar, etc.).
- Offer 2-3 zone arrangements with rationale for each. Reference platform and
  input context gathered from game concept.
- Use `AskUserQuestion` to capture the choice:
  - "Which zone arrangement fits best?"
  - Options: [the 2-3 named arrangements you just presented] + "None — build a custom arrangement"

**Sub-section 3 — Component Inventory**:
- For each zone, list the UI components it contains. For each component, note:
  - Component type (button, list, card, stat display, input field, etc.)
  - Content it displays
  - Whether it is interactive
  - If it uses an existing pattern from the library (reference by pattern name)
  - If it introduces a new pattern (flag for later addition to the library)

**Sub-section 4 — ASCII Wireframe**:
- Offer to generate an ASCII wireframe based on the zone layout and component list.
- Use `AskUserQuestion`: "Want an ASCII wireframe as part of this spec?"
  - Options: "Yes, include one", "No, I'll attach a separate file"
- If yes, produce the wireframe in conversation first. Ask for feedback before
  writing it to file.

---

#### Section D: States & Variants

Guide the user to think beyond the happy path.

**Questions to ask** (work through these one at a time):
- "What does this screen look like the very first time a player sees it, when there
  is no data yet? (empty state)"
- "What happens when something goes wrong — an error, a failed action, a missing
  resource? (error state)"
- "Is there ever a loading wait on this screen? If so, what does it show? (loading state)"
- "Are there any player progression states that change what this screen shows? For
  example, locked content, premium content, or tutorial-mode overlays?"
- "Does this screen behave differently on any supported platform? (platform variant)"

Present the collected states as a table for approval:

| State / Variant | Trigger | What Changes |
|-----------------|---------|--------------|
| Default | Normal load | — |
| Empty | No data available | [content area description] |
| [etc.] | [trigger] | [changes] |

---

#### Section E: Interaction Map

For each interactive component identified in the Layout Specification, define:
- The action (tap, click, press, hold, scroll, drag)
- The platform input(s) that trigger it (mouse click, gamepad A, keyboard Enter)
- The immediate feedback (visual, audio, haptic)
- The outcome (navigation target, state change, data write)

Use the input methods resolved in Phase 2h — do
not ask the user again. State them upfront: "Mapping interactions for:
[Input Methods resolved in Phase 2h]. Covering [Gamepad Support] gamepad support."

Work through components one at a time rather than asking for all at once.
For navigation actions (going to another screen), verify the target matches
an existing UX spec or note it as a spec dependency.

---

#### Section E2: Events Fired

For every player action in the Interaction Map, document the corresponding event the game or analytics system should fire — or explicitly note "no event" if none applies.

**Questions to ask**:
- "For each action, should the game fire an analytics event, trigger a game-state change, or both?"
- "Are there any actions that should NOT fire an event — and is that a deliberate choice?"

Present as a table alongside the Interaction Map:

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| [action] | [EventName] or none | [data passed with event] |

Flag any action that modifies persistent game state (save data, progress, economy) — these need explicit attention from the architecture team.

---

#### Section E3: Transitions & Animations

Specify how the screen enters and exits, and how it responds to state changes.

**Questions to ask**:
- "How does this screen appear? (fade in, slide from right, instant pop, scale from button)"
- "How does it dismiss? (fade out, slide back, cut)"
- "Are there any in-screen state transitions that need animation? (loading spinner, success state, error flash)"
- "Is there any animation that could cause motion sickness — and does the game have a reduced-motion option?"

Minimum required:
- Screen enter transition
- Screen exit transition
- At least one state-change animation if the screen has multiple states

---

#### Section F: Data Requirements

Cross-reference the GDD UI Requirements sections gathered in Phase 2.

For each piece of information the screen displays, ask:
- "Where does this data come from? Which system owns it?"
- "Does this screen need to write data back, or is it read-only?"
- "Is any of this data time-sensitive or real-time? (health bars, cooldown timers)"

Flag any case where the UI would need to own or manage game state as an architectural
concern. UX specs define what the UI needs; they do not dictate how the data is
delivered. That is an architecture decision.

Present the data requirements as a table:

| Data | Source System | Read / Write | Notes |
|------|--------------|--------------|-------|
| [item] | [system] | Read | — |
| [item] | [system] | Write | [concern if any] |

---

#### Section F2: Input Method Completeness Checklist

One checklist block per input method in the spec's **Platform Target** line —
keyboard, gamepad, mouse, touch; drop the blocks for methods this game does not
support and say so. Take the items from section 11 of
`.claude/docs/templates/ux-spec.md` (reachability, tab/d-pad order, visible
focus, focus trap for modals, Esc/back behavior, hit-target sizes, controller
disconnect). Tick an item only when the Interaction Map above already specifies
it; an unticked item is an open implementation question — list it under Open
Questions rather than ticking it.

---

#### Section G: Accessibility

Cross-reference `design/accessibility-requirements.md` if it exists.

Walk through the ux-designer agent's standard checklist for this screen:
- Keyboard-only navigation path through all interactive elements
- Gamepad navigation order (if applicable)
- Text contrast and minimum readable font sizes
- Color-independent communication (no information conveyed by color alone)
- Screen reader considerations for any non-text elements
- Any motion or animation that needs a reduced-motion alternative

If no accessibility tier has been defined for this project, note the gap in the UX spec's Open Questions section:
> "Accessibility tier not yet defined — consider WCAG-AA as a baseline. Run `/gate-check` to see whether this blocks any phase gates."
Then continue to the next section without stopping.

---

#### Section H: Localization Considerations

Document constraints that affect how this screen behaves when text is translated.

**Questions to ask**:
- "Which text elements on this screen are the longest? What is the maximum character count that fits the layout?"
- "Are there any elements where text length is layout-critical — e.g., a button label that must stay on one line?"
- "Are there any elements that display numbers, dates, or currencies that need locale-specific formatting?"

Note: aim to flag any element where a 40% text expansion (common in translations from English to German or French) would break the layout. Mark those as HIGH PRIORITY for the localization engineer.

---

#### Section I: Acceptance Criteria

Write at least 5 specific, testable criteria that a QA tester can verify without reading any other design document. These become the pass/fail conditions for `/story-done`.

**Format**: Use checkboxes. Each criterion must be verifiable by a human tester:

```
- [ ] Screen opens within [X]ms from [trigger]
- [ ] [Element] displays correctly at [minimum] and [maximum] values
- [ ] [Navigation action] correctly routes to [destination screen]
- [ ] Error state appears when [condition] and shows [specific message or icon]
- [ ] Keyboard/gamepad navigation reaches all interactive elements in logical order
- [ ] [Accessibility requirement] is met — e.g., "all interactive elements have focus indicators"
```

**Minimum required**:
- 1 performance criterion (load/open time)
- 1 navigation criterion (at least one entry or exit path verified)
- 1 error/empty state criterion
- 1 accessibility criterion (per committed tier)
- 1 criterion specific to this screen's core purpose

Use `AskUserQuestion` to confirm:
- "Do these acceptance criteria cover what would make this screen 'done' for your QA process?"
- Options: "Yes — these are solid", "Add one more criterion", "Remove or rephrase one"
