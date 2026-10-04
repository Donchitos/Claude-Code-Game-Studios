# UX Specification: [Screen / Flow Name]

> Authoring guidance: .claude/docs/templates/guidance/ux-spec-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g., ux-designer]
> **Last Updated**: [Date]
> **Screen / Flow Name**: [Short identifier used in code and tickets — e.g., `InventoryScreen`, `NewGameFlow`]
> **Platform Target**: [PC | Console | Mobile | All — list all that this spec covers]
> **Related GDDs**: [Links to the GDD sections that generated this UI requirement — e.g., `design/gdd/inventory.md § UI Requirements`]
> **Related ADRs**: [Any architectural decisions that constrain this screen — e.g., `ADR-0012: UI Framework Selection`]
> **Related UX Specs**: [Sibling and parent screens — e.g., `ux-spec-pause-menu.md`, `ux-spec-settings.md`]
> **Accessibility Tier**: Basic | Standard | Comprehensive | Exemplary
> **Template**: UX Spec

> **Note — Scope boundary**: This template covers discrete screens and flows (menus,
> dialogs, inventory, settings, cutscene UI, etc.). For persistent in-game overlays
> that exist during active gameplay, use `hud-design.md` instead. If a screen is a
> hybrid (e.g., a pause menu that overlays the game world), treat it as a screen spec
> and note the overlay relationship in Navigation Position.

---

## 1. Purpose & Player Need

**What player need does this screen serve?**

[One paragraph — the real human need from the player's perspective, not the system function. See guide Section 1 for good/bad examples.]

**The player goal** (what the player wants to accomplish):

[One sentence, specific enough to write an acceptance criterion for.]

**The game goal** (what the game needs to communicate or capture):

[One sentence — what the system needs from this interaction.]

---

## 2. Player Context on Arrival

| Question | Answer |
|----------|--------|
| What was the player just doing? | [Prior activity / triggering state] |
| What is their emotional state? | [Tension / calm / urgency] |
| What cognitive load are they carrying? | [High / low + what they are tracking] |
| What information do they already have? | [Known context on arrival] |
| What are they most likely trying to do? | [Primary use case] |
| What are they likely afraid of? | [Risks and anxieties to design against] |

**Emotional design target for this screen**:

[One sentence describing the feeling the player should have while using this screen.]

---

## 3. Navigation Position

**Screen hierarchy** (use indentation to show parent-child relationships):

```
[Root — e.g., Main Menu]
  └── [Parent Screen — e.g., Settings]
        └── [This Screen — e.g., Audio Settings]
              ├── [Child Screen — e.g., Advanced Audio Options]
              └── [Child Screen — e.g., Speaker Test Dialog]
```

**Modal behavior**: [Modal (blocks everything behind it, requires explicit dismiss) | Non-modal (game continues behind it) | Overlay (renders over game world, game paused) | Overlay-live (renders over game world, game continues)]

> If this screen is modal: document the dismiss behavior. Can it be dismissed by pressing
> Back/B? By pressing Escape? By clicking outside it? Can it be dismissed at all, or
> must the player complete it? Undismissable modals are high-friction — justify them.

**Reachability — all entry points**:

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [Entry point] | [Trigger] | [Notes] |

---

## 4. Entry & Exit Points

> Every entry point must have a corresponding exit point. Empty cells are a sign
> that design work is unfinished. See guide Section 4 for worked examples.

**Entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [Trigger] | [Source] | [Transition] | [Data in] | [Notes] |

**Exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [Exit action] | [Destination] | [Transition] | [Data out / committed] | [Notes] |

---

## 5. Layout Specification

### 5.1 ASCII Wireframe

```
[Draw the screen layout using ASCII art. Suggested characters:
 ┌ ┐ └ ┘ │ ─    for borders
 ╔ ╗ ╚ ╝ ║ ═    for emphasized/modal borders
 [ ]              for interactive elements (buttons, inputs)
 { }              for content areas (lists, grids, images)
 ...              for scrollable content
 ●                for the focused element on open

See guide Section 5 for a completed example wireframe.]
```

### 5.2 Layout Zones

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| [Zone] | [Contents and purpose] | [% width x % height] | [Yes/No] | [Overflow handling] |

### 5.3 Component Inventory

> List every discrete UI component on this screen. This table drives the implementation
> task list — each row becomes a component to build or reuse.

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [Component] | [Type] | [Zone] | [Purpose] | [Yes/No] | [Yes — pattern/component name, or No — new] |

**Primary focus element on open**: [Element that receives focus when the screen opens, including deep-link and empty-state cases]

### 5.4 Information Hierarchy

[What the player must see first on this screen, what second, and what can wait
behind a tab, a scroll or a button — in that order, with the reason for each.]

---

## 6. States & Variants

> Document every state before implementation — at minimum: loading, empty,
> populated, and error. The states table is also the test matrix for QA.
> See guide Section 6 for a worked example.

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| [Loading / Empty / Populated / Selected / Confirmation / Error / other] | [Trigger] | [Visual changes] | [Behavioral changes] | [Notes] |

---

## 7. Interaction Map

> Cover every input method for the platform target (mouse, keyboard, gamepad,
> touch). Gaps in this table are bugs waiting to happen. See guide Section 7.

### 7.1 Navigation Inputs

| Input | Platform | Action | Visual Response | Audio Cue | Notes |
|-------|----------|--------|-----------------|-----------|-------|
| [Input] | [Platform] | [Action] | [Visual response] | [Audio] | [Notes] |

### 7.2 Action Inputs

| Input | Platform | Context (What must be focused) | Action | Response | Animation | Audio Cue | Notes |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [Input] | [Platform] | [Focus context] | [Action] | [Response] | [Animation + timing] | [Audio] | [Notes] |

### 7.3 State-Specific Behaviors

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [State] | [Which inputs are disabled] | [Why] |

---

## 8. Data Requirements

> UI reads data; it does not own it. UI fires events; it does not write state
> directly. Every displayed data element needs a source system and owner.
> See guide Section 8 for a worked example.

| Data Element | Source System | Update Frequency | Who Owns It | Format | Null / Missing Handling |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [Data element] | [System] | [When it updates — specific trigger, not "realtime"] | [Owning system — never the UI] | [Type/shape] | [What shows when data is unavailable] |

> **Rule**: This screen must never write directly to any system listed above. All
> player actions fire events (see Section 9). Systems update their own data and
> notify the UI.

---

## 9. Events Fired

> Every destructive or state-changing player action must appear in this table.
> See guide Section 9 for a worked example.

| Player Action | Event Fired | Payload | Receiver System | Notes |
|---------------|-------------|---------|-----------------|-------|
| [Action] | [EventName] | [{fields}] | [System] | [Validation/response flow, or "analytics only"] |

---

## 10. Transitions & Animations

> Specify at least the screen enter and exit transitions, plus reduced-motion
> behavior for each. See guide Section 10 for a worked example.

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [Screen enter / exit / in-screen transition] | [Trigger] | [Type] | [ms] | [Easing] | [Yes/No] | [Yes/No + fallback] |

---

## 11. Input Method Completeness Checklist

> Fill this checklist before marking the spec as Approved. Any unchecked item
> blocks implementation start.

**Keyboard**
- [ ] All interactive elements are reachable using Tab and arrow keys alone
- [ ] Tab order follows visual reading order (left-to-right, top-to-bottom within each zone)
- [ ] Every action achievable by mouse is also achievable by keyboard
- [ ] Focus is visible at all times (no element where focus ring disappears)
- [ ] Focus does not escape the screen while it is open (focus trap for modals)
- [ ] Esc key closes or cancels (and does not quit the game from within a screen)

**Gamepad**
- [ ] All interactive elements reachable with D-Pad and left stick
- [ ] Face button mapping documented and consistent with platform conventions (see Section 7.2)
- [ ] No action requires analog stick precision that cannot be replicated with D-Pad
- [ ] Trigger and bumper shortcuts documented if used
- [ ] Controller disconnection while screen is open is handled gracefully

**Mouse**
- [ ] Hover states defined for all interactive elements
- [ ] Clickable hit targets are at minimum 32x32px (44x44px preferred)
- [ ] Right-click behavior defined (context menu or no-op — not undefined)
- [ ] Scroll wheel behavior defined in all scrollable zones

**Touch (if applicable)**
- [ ] All touch targets are minimum 44x44px
- [ ] Swipe gestures do not conflict with system-level swipe navigation
- [ ] All actions achievable with one hand in portrait orientation
- [ ] Long-press behavior defined if used

---

## 12. Accessibility

> Project-wide standards live in `design/accessibility-requirements.md` — consult it
> before filling this section so you do not duplicate or contradict project-level
> commitments.
>
> Accessibility Tiers in this project:
> - Basic: WCAG 2.1 AA text contrast, keyboard navigable, no motion-only information
> - Standard: Basic + screen reader support, colorblind-safe, focus management
> - Comprehensive: Standard + reduced motion support, text scaling, high contrast mode
> - Exemplary: Comprehensive + cognitive load management, AAA equivalent, certified

**Text contrast requirements for this screen**:

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|---------------|---------------|-------|
| [Text element] | [Background] | [Ratio — 4.5:1 WCAG AA baseline] | [TBD] | [ ] |

**Colorblind-unsafe elements and mitigations**:

| Element | Colorblind Risk | Mitigation |
|---------|----------------|------------|
| [Element] | [Risk type] | [Non-color redundant indicator] |

**Focus order** (Tab key sequence, numbered):

[Numbered focus sequence covering every interactive element, including cycle behavior and any panels focus does not enter — see guide Section 12 for an example]

**Screen reader announcements for key state changes**:

| State Change | Announcement Text | Announcement Timing |
|--------------|------------------|---------------------|
| [State change] | ["Announcement"] | [When it fires] |

**Cognitive load assessment**:

[Count the concurrent information streams the player tracks on this screen; compare against the 7±2 limit and state mitigations — see guide Section 12 for an example]

---

## 13. Localization Considerations

**General rules for this screen**:
- All text elements must tolerate a minimum of 40% expansion from English baseline
- RTL layout (Arabic, Hebrew): mirrored layout required — document which elements mirror and which do not
- CJK languages (Japanese, Korean, Chinese): text may be 20-30% shorter — verify layouts do not look broken with less text
- Do not use text in images — all text must be from localization strings

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behavior | Overflow Behavior | Risk |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [Text element] | [chars] | [max chars] | [%] | [Mirror/align behavior] | [Truncate/scroll/shrink strategy] | [Low/Medium/High] |

---

## 14. Acceptance Criteria

> Write criteria a QA tester can verify independently, without asking the designer
> what they meant. Every criterion should be binary — pass or fail, not subjective.

**Performance**
- [ ] Screen opens (first frame visible) within [200]ms of trigger on minimum-spec hardware
- [ ] Screen is fully interactive (all data loaded) within [500]ms of trigger on minimum-spec hardware
- [ ] Navigation between elements produces no perceptible frame drop (maintain target framerate ±5fps)

**Layout & Rendering**
- [ ] Screen displays correctly (no overlap, no cutoff, no overflow) at minimum supported resolution [specify]
- [ ] Screen displays correctly at maximum supported resolution [specify]
- [ ] Screen displays correctly at 4:3, 16:9, 16:10, and 21:9 aspect ratios if targeting PC
- [ ] No text overflow or truncation in English within defined max-character bounds
- [ ] No text overflow or truncation in the longest-translation language [specify — typically German]
- [ ] All states documented in Section 6 render correctly
- [ ] Scrollable zones scroll smoothly without frame drops when fully populated

**Input**
- [ ] All interactive elements reachable by keyboard using Tab and arrow keys only
- [ ] All interactive elements reachable by gamepad using D-Pad and face buttons only
- [ ] All interactive elements reachable by mouse without keyboard
- [ ] No action requires simultaneous input that is not documented in Section 7
- [ ] Focus is visible at all times on keyboard and gamepad navigation
- [ ] Focus does not escape the screen while it is open

**Events & Data**
- [ ] All events in Section 9 fire with correct payloads on all exit paths (verify with debug logging)
- [ ] Screen does not write directly to any game system (verify: no direct state mutation calls)
- [ ] Changes made on this screen persist correctly after it is closed and reopened
- [ ] Screen handles data-change events fired by other systems while it is open without crashing

**Accessibility**
- [ ] All text passes minimum contrast ratios specified in Section 12
- [ ] No information relies on color alone as the sole differentiator
- [ ] Screen reader announces documented state changes (verify with platform screen reader)
- [ ] Reduced motion setting results in instant transitions (no animated transitions)
- [ ] High contrast mode (if applicable to Accessibility Tier) renders without visual breakage

**Localization**
- [ ] No text element overflows its container in any supported language
- [ ] RTL layout renders correctly (if RTL is a target language)
- [ ] All text elements are driven by localization strings — no hardcoded display text

---

## 15. Open Questions

> Track unresolved design questions here. Each question should have a clear owner
> and a deadline. An Approved spec must have zero open questions — move to a decision
> or explicitly document the deferral rationale.

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
