# Interaction Pattern Library: [Game Title]

> Authoring guidance: .claude/docs/templates/guidance/interaction-pattern-library-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | Stable | Under Revision
> **Author**: [ux-designer]
> **Last Updated**: [Date]
> **Version**: [1.0]
> **Engine**: [Godot 4.6 / Unity 6 / Unreal Engine 5]
> **UI Framework**: [Godot Control nodes / Unity UI Toolkit / Unreal UMG]
> **Related Documents**:
> - `design/art/art-bible.md` — visual standards (colors, typography, iconography)
> - `design/accessibility-requirements.md` — accessibility commitments per feature
> - `docs/ux/ux-spec-[screen].md` — individual screen specs that reference patterns
>
> **Template**: Interaction Pattern Library

> **Why this document exists**: Every UI screen spec should be able to say
> "uses Button (Primary) pattern" rather than re-specifying hover states,
> press animations, focus behavior, keyboard handling, and screen reader
> announcements from scratch. This library is the single source of truth for
> reusable interaction behaviors. When a screen spec references a pattern name,
> the programmer looks it up here. When the behavior changes, it changes here
> and applies everywhere.
>
> This is a living document. Patterns are added as new screens are designed —
> do not design a new interaction without checking here first. If a new pattern
> is needed, add it here (or propose it to the ux-designer) before writing the
> first screen spec that uses it.
>
> **Status definitions**:
> - **Draft**: Interaction specified but not yet implemented or validated
> - **Stable**: Implemented, tested, and validated in at least one shipped screen
> - **Deprecated**: Being phased out — existing uses will be migrated, do not use in new screens

---

## How to Use This Library

**If you are designing a screen**: Browse the Pattern Catalog Index below before
inventing new interactions. When a standard pattern fits, reference it by name
in the screen spec (e.g., "The confirm button uses Button (Primary) pattern").
When no existing pattern fits, propose a new one — document it here alongside
or before the screen spec that introduces it.

**If you are implementing a screen**: When a screen spec says "use [PatternName]
pattern," find it in this document for the complete specification. The
implementation notes section contains engine-specific guidance. The accessibility
section contains the requirements that are non-negotiable.

**If you are reviewing a screen spec**: Verify that all interactive elements
reference a pattern from this library or include their own full interaction
specification. "Standard button" or "the usual way" is not a valid reference.

**If you are updating a pattern**: Changing a Stable pattern affects every screen
that uses it. Before changing, audit all usages (search screen specs for the
pattern name), determine the impact, get approval from the ux-designer, and
update this document before or simultaneously with any implementation change.

---

## Pattern Catalog Index

> Add a row here every time a new pattern is added to this document.
> The "Used In" column is the usages audit trail — update it when new screens
> adopt the pattern.

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| Button (Primary) | Input | Main call-to-action. High visual weight. One per screen. | [Main Menu, Pause Menu, Settings] | Draft |
| Button (Secondary) | Input | Alternative action or cancel. Lower visual weight than Primary. | [All modal dialogs, settings screens] | Draft |
| Button (Destructive) | Input | Irreversible action. Requires confirmation before execution. | [Delete Save, Reset Settings] | Draft |
| Toggle | Input | Binary on/off state selection. | [Accessibility settings, audio settings] | Draft |
| Slider | Input | Continuous value selection. | [Volume controls, brightness, text size] | Draft |
| Dropdown / Select | Input | Selection from a discrete list of options. | [Resolution, language, key binding] | Draft |
| List Item | Layout / Input | Selectable row in a vertical scrollable list. | [Achievements, quest log, settings list] | Draft |
| Grid Item | Layout / Input | Selectable cell in a two-dimensional grid. | [Inventory, ability select, item shop] | Draft |
| Modal Dialog | Feedback / Layout | Blocking overlay requiring explicit player decision. | [Confirmation dialogs, error prompts] | Draft |
| Confirmation Dialog | Feedback / Layout | Specific modal for destructive action confirmation. | [Delete Save, Leave Match, Reset] | Draft |
| Toast / Notification | Feedback | Non-blocking temporary message in a screen corner. | [Achievement unlock, autosave notification] | Draft |
| Tooltip | Feedback | Contextual information on hover or focus. | [Inventory items, ability descriptions, settings] | Draft |
| Progress Bar | Feedback / Layout | Linear progress indicator. | [Loading screen, XP bar, quest progress] | Draft |
| Input Field | Input | Text entry control. | [Player name, search, key binding entry] | Draft |
| Tab Bar | Navigation | Tabbed section navigation within a single screen. | [Character sheet, settings, crafting] | Draft |
| Scroll Container | Layout | Scrollable content region with visible scroll indicator. | [Inventory, lore entries, credits] | Draft |
| Inventory Slot | Game-Specific | Item container in inventory grid (empty, filled, equipped, locked). | [Inventory screen, equipment screen] | Draft |
| Ability / Skill Icon | Game-Specific | Ability button with cooldown, charges, and locked states. | [HUD ability bar, skill tree] | Draft |
| Health / Resource Bar | Game-Specific | Value bar with threshold states and damage flash. | [HUD] | Draft |
| Minimap | Game-Specific | Overview map with player marker and points of interest. | [HUD] | Draft |
| Quest / Objective Tracker | Game-Specific | Active objective display with proximity and completion states. | [HUD] | Draft |
| Dialogue Box | Game-Specific | NPC conversation UI with speaker identification. | [All dialogue sequences] | Draft |
| Context Action Prompt | Game-Specific | Contextual "Press X to [action]" prompt near interactable objects. | [World interaction] | Draft |
| Damage Number | Game-Specific | Floating combat feedback number. | [Combat HUD] | Draft |
| Status Effect Icon | Game-Specific | Buff/debuff indicator with duration. | [HUD status bar, enemy health display] | Draft |
| Notification Banner | Game-Specific | Achievement, level up, item acquired notifications. | [Global overlay] | Draft |
| Screen Push | Navigation | Forward navigation with directional animation. | [All menu navigation] | Draft |
| Screen Pop (Back) | Navigation | Back navigation with reversed animation. | [All menu navigation] | Draft |
| Screen Replace | Navigation | Replace current screen without stacking history. | [Main Menu to Loading Screen] | Draft |
| Modal Open / Close | Navigation | Overlay that dims background screen. | [All modal dialogs] | Draft |
| Tab Switch | Navigation | Same-screen content switch between tabs. | [All tabbed screens] | Draft |
| Focus Management | Navigation | Rules for where focus goes when screens open, close, or change. | [All screens] | Draft |
| Escape / Cancel | Navigation | Universal back behavior across platforms and input methods. | [All screens] | Draft |
| Loading State | Feedback | How screens and components indicate loading in progress. | [All loading states] | Draft |
| Empty State | Feedback | How empty lists and grids are presented. | [Empty inventory, no quests, no saves] | Draft |
| Error State | Feedback | How errors are communicated. | [Save failed, network error, invalid input] | Draft |
| Success Confirmation | Feedback | How completed actions are confirmed. | [Settings saved, item crafted, quest turned in] | Draft |
| Optimistic UI | Feedback | Showing assumed success before system confirmation. | [If online features are present] | Draft |

---

## Standard Control Patterns

> Full reference specifications for every pattern in this section (state tables
> with timing/audio values, accessibility requirements, implementation notes)
> are in `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` —
> load only the pattern(s) currently being specified.

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: [The single most important action on a screen — at most one visible at a time]
**When NOT to Use**: [Alternative/secondary actions; destructive actions; anything not the screen's primary intent]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Default / Hovered / Focused / Pressed / Disabled / Loading] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Keyboard, gamepad, screen reader, colorblind, and touch-target requirements]

**Implementation Notes**: [Engine-specific guidance]

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: [Alternative or cancel action — lower visual weight than Primary]
**When NOT to Use**: [Destructive actions; the screen's most important action]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Same baseline as Button (Primary); note cancel-input mapping in dialogs]

**Implementation Notes**: [Engine-specific guidance; consistent Primary/Secondary positioning]

---

#### Button (Destructive)

**Category**: Input
**Status**: Draft
**When to Use**: [Irreversible actions causing loss of player data or progress]
**When NOT to Use**: [Actions that can be undone or are merely consequential]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly.
> It always triggers a Confirmation Dialog. There are no exceptions.

**Accessibility**: [Screen reader must announce the destructive nature]

**Implementation Notes**: [Engine-specific guidance]

---

#### Toggle

**Category**: Input
**Status**: Draft
**When to Use**: [Binary on/off settings where current state must be visible at a glance]
**When NOT to Use**: [More than two options; one-shot actions; choices needing explanation]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Activation inputs, screen reader switch role/state rules, state label requirements]

**Implementation Notes**: [Engine-specific guidance; motion-reduction behavior]

---

#### Slider

**Category**: Input
**Status**: Draft
**When to Use**: [Continuous value selection where range and relative position matter]
**When NOT to Use**: [Precise value entry; short discrete lists; binary state]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Keyboard step/large-step/min-max inputs, screen reader value announcements, numeric value display requirement]

**Implementation Notes**: [Engine-specific guidance]

---

#### Dropdown / Select

**Category**: Input
**Status**: Draft
**When to Use**: [Selection from a discrete list of 3-15 options; only the selection visible at rest]
**When NOT to Use**: [Binary choices; more than ~15 options; when comparing options matters]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [List navigation, combobox role, expanded/collapsed announcements, positioning rules]

**Implementation Notes**: [Engine-specific guidance]

---

#### List Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable row in a vertically scrollable list]
**When NOT to Use**: [Two-dimensional grids; non-selectable content rows]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Focus cycling rules, listitem role and position announcements, minimum row height]

**Implementation Notes**: [Engine-specific guidance; scroll-into-view on focus]

---

#### Grid Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable cell in a two-dimensional grid]
**When NOT to Use**: [Single-column content; non-selectable display cells]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Empty / Populated / Hovered / Focused / Selected / Pressed / Locked / Drag source / Drop target] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Grid dimensions and row/column position announcements, keyboard-reachable tooltips]

**Implementation Notes**: [Engine-specific guidance; custom D-pad cell navigation]

---

#### Modal Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [A decision or acknowledgment that must be resolved before continuing]
**When NOT to Use**: [Non-blocking notifications; information that can wait; dialogs that should allow play behind them]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Opening / Active / Dismissing (confirmed) / Dismissing (cancelled) / Cannot dismiss] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

> **Focus trap rule**: While a modal dialog is open, focus navigation must cycle
> within the dialog only, and focus must return to the trigger element on close.

**Accessibility**: [Dialog role and required title, Escape/Enter mappings, motion-reduction overrides]

**Implementation Notes**: [Engine-specific guidance]

---

#### Confirmation Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Confirming a destructive action — always triggered by Button (Destructive)]
**When NOT to Use**: [Non-destructive confirmations; dialogs with more than two actions]

> **Label rule**: The confirm button must be labeled with the specific action,
> not a generic "OK" or "Yes."

**Structure**:
- Title: [Brief, action-describing]
- Body: [One sentence stating the consequence]
- Confirm button: [Button (Primary) — labeled with the specific action]
- Cancel button: [Button (Secondary) — "Cancel"]
- Default focus: [Cancel — safer default]

**Accessibility**: [Inherits Modal Dialog; alert-dialog announcement; default focus on Cancel is required]

**Implementation Notes**: [Engine-specific guidance]

---

#### Toast / Notification

**Category**: Feedback
**Status**: Draft
**When to Use**: [Brief, non-blocking information requiring no player decision]
**When NOT to Use**: [Decisions; errors requiring action; critical information the player must not miss]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Entering / Displayed / Auto-dismiss / Manual dismiss / Queue overflow] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Announcement without focus, motion-reduction fallback, minimum auto-dismiss timing, never sole channel for actionable info]

**Implementation Notes**: [Engine-specific guidance; queue management and layer ordering]

---

#### Tooltip

**Category**: Feedback
**Status**: Draft
**When to Use**: [Contextual information supplementing a visible label]
**When NOT to Use**: [Information required to complete an action; touch-only platforms without hover]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Hidden / Hover trigger / Focus trigger / Appearing / Displayed / Hiding] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Content accessible without hover, required appearance delay, contrast requirements]

**Implementation Notes**: [Engine-specific guidance; screen-edge repositioning]

---

#### Progress Bar

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Linear progress toward a defined endpoint]
**When NOT to Use**: [Radial progress; rapidly fluctuating values; values with no endpoint]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Default / Value increasing / At maximum / At zero / Indeterminate] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Progressbar role, numeric value + percentage announcements, numeric label requirement, motion-reduction overrides]

**Implementation Notes**: [Engine-specific guidance; indeterminate-mode implementation]

---

#### Input Field

**Category**: Input
**Status**: Draft
**When to Use**: [Text entry — player name, search, precise numeric values, key binding capture]
**When NOT to Use**: [Selecting from known options; console-primary flows where virtual keyboards add friction]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Default / Hovered / Focused / Typing / Value present / Limit reached / Clear / Validation error / Validated / Disabled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Standard editing shortcuts, textbox role, visible label requirement (placeholder is not a label)]

**Implementation Notes**: [Engine-specific guidance; virtual keyboard handling]

---

#### Tab Bar

**Category**: Navigation
**Status**: Draft
**When to Use**: [Dividing one screen's content into discrete sections, one visible at a time — max 5-6 tabs]
**When NOT to Use**: [More than 6 tabs; content needing simultaneous visibility; navigation between screens]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Inactive / Active / Hovered / Focused / Activated / Shoulder-button switch] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [ARIA tab panel pattern (tab/tablist/tabpanel), active-tab distinction beyond color]

**Implementation Notes**: [Engine-specific guidance; shoulder-button shortcut handling]

---

#### Scroll Container

**Category**: Layout
**Status**: Draft
**When to Use**: [Content exceeding the visible area of its container]
**When NOT to Use**: [Content better paginated; infinite scroll without loading/end states]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| [Content fits / Scrollable / Scrolling / Scrollbar drag / Keyboard scroll / Gamepad scroll / Boundary / Focus follows scroll] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |

**Accessibility**: [Auto-scroll to keep focused items in view, scroll position announcements, scrollbar as required indicator]

**Implementation Notes**: [Engine-specific guidance; ensure-visible on focus change]

---

## Game-Specific UI Patterns

> Full reference specifications for every pattern in this section are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-game-specific.md` — load only the
> pattern(s) currently being specified.

---

#### Inventory Slot

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Every item container in the inventory grid — empty, populated, equipped, locked]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Empty / Populated / Focused / Selected / Drag source / Locked / Highlighted / Cooldown overlay] | [Visual treatment] | [Behavioral notes] |

**Accessibility**: [Non-color alternatives for stack counts and quality tiers; keyboard-reachable tooltip; locked-state announcement]

**Implementation Notes**: [Engine-specific guidance]

---

#### Ability / Skill Icon

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [HUD ability bar buttons, skill tree nodes, any availability-state ability display]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Available / On cooldown / Charges remaining / Out of resource / Locked / Active / Just activated] | [Visual treatment] | [Behavioral notes] |

**Accessibility**: [Numeric alternatives for cooldown/charge information; names and descriptions exposed to screen readers]

**Implementation Notes**: [Engine-specific guidance]

---

#### Health / Resource Bar

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Any continuously varying critical player resource in the HUD]

**States and behaviors**:

| Event | Visual | Audio | Duration |
|-------|--------|-------|---------|
| [Decrease / Increase / Below threshold / At zero / Maximum / Overflow] | [Visual treatment] | [Sound category] | [Duration] |

**Accessibility**: [Numeric value access; non-color backups for threshold states]

**Implementation Notes**: [Engine-specific guidance; ghost-bar technique]

---

#### Dialogue Box

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [All dialogue that has a speaker — NPC conversation, voiced narrative, character-delivered tutorial text]

**Structure**: [Speaker identification, dialogue text body, advance prompt, optional skip/voice/subtitle indicators]

**States and behaviors**:

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|---------|
| [Line entering / Revealing / Line complete / Advancing / Choices appearing / Closing / Skipping all] | [Visual treatment] | [Input trigger] | [Response] | [Duration] |

**Accessibility**: [Subtitles on by default, configurable typewriter speed, no auto-advance, navigable choices with position announcements]

**Implementation Notes**: [Engine-specific guidance; dialogue data format]

---

#### Context Action Prompt

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [A prompt near an interactable object indicating what the player can do]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Appearing / Idle / Holding / Cannot interact / Disappearing] | [Visual treatment] | [Behavioral notes] |

**Accessibility**: [Text label alongside button icon; positioning must not overlap critical HUD]

**Implementation Notes**: [Engine-specific guidance; input-method-aware icon swapping]

---

#### Damage Number

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Floating feedback numbers above combat participants]

**Variants**:

| Variant | Visual | Notes |
|---------|--------|-------|
| [Normal / Critical / Healing / Miss / Status damage] | [Visual treatment] | [Behavioral notes] |

**Behavior**: [Float trajectory, fade timing, overlap staggering, maximum simultaneous numbers]

**Accessibility**: [Supplementary-only feedback; disable option; game fully playable when disabled]

**Implementation Notes**: [Engine-specific guidance; object pooling]

---

## Navigation Patterns

> Full reference specifications for this section and the next are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` — load
> only the pattern(s) currently being specified.

---

#### Screen Push / Pop / Replace

**Category**: Navigation
**Status**: Draft

These three patterns define how screens enter and exit the navigation stack.

| Pattern | Trigger | Animation | Stack Behavior | Focus Behavior |
|---------|---------|-----------|---------------|----------------|
| [Push / Pop / Replace] | [Trigger] | [Animation] | [Stack behavior] | [Focus behavior] |

**Animation durations**: [Push/Pop and Replace durations + easing]

**Motion reduction**: [Fallback behavior]

**Implementation Notes**: [Engine-specific guidance; screen stack manager and return-focus storage]

---

#### Focus Management

**Category**: Navigation
**Status**: Draft

> Focus management is the most common keyboard and gamepad accessibility failure
> in game UIs. These rules must be implemented consistently.

| Rule | Description |
|------|-------------|
| [Screen open / close, modal open / close, element disabled / destroyed, Tab order, D-pad spatial navigation, focus visibility] | [Rule description] |

---

#### Escape / Cancel

**Category**: Navigation
**Status**: Draft

> The "go back" action is the most-used navigation input in all menu systems.
> It must be consistent across every screen with no exceptions.

| Platform | Input | Behavior |
|----------|-------|---------|
| [Platform] | [Input] | [Behavior] |

**Rules**: [Never override "go back / cancel"; every screen defines its Escape behavior explicitly in its UX spec]

---

## Feedback and Loading Patterns

---

#### Loading State

**Category**: Feedback
**Status**: Draft

| Scope | Pattern | Notes |
|-------|---------|-------|
| [Full screen (initial) / Full screen (transition) / Component inline / Background async] | [Pattern] | [Notes] |

**Accessibility**: [Screen reader loading/loaded announcements; loading screens navigable]

---

#### Empty State

**Category**: Feedback
**Status**: Draft

> Every empty list and grid must have a designed empty state. The empty state
> is not an error — it is a starting point.

| Location | Empty State Content | Notes |
|----------|--------------------|----|
| [Location] | [Icon + message + sub-message or action] | [Notes] |

**Rule**: Every empty state must include an icon, a message, and either a sub-message or an action button.

---

#### Error State

**Category**: Feedback
**Status**: Draft

| Error Type | Pattern | Tone |
|-----------|---------|------|
| [Input validation / Operation failed / System error / Soft error] | [Pattern] | [Tone guidance] |

**Principle**: Error messages are never the player's fault. They tell the player what happened and what to do next.

---
## Animation Standards

> These timing values apply to ALL patterns in this library. When a pattern says
> "150ms ease-out," the easing function is defined here. Consistency in timing
> makes the UI feel like a single designed system rather than a collection of
> individual decisions.

| Animation Type | Duration (ms) | Easing Function | Notes |
|---------------|--------------|----------------|-------|
| Button hover / focus enter | 80 | ease-out | Fast — snappy, not sluggish |
| Button hover / focus exit | 60 | ease-in | Slightly faster exit than entry |
| Button press scale down | 60 | ease-in | Immediate feedback |
| Button press scale up (release) | 80 | ease-out | Slightly bouncy feel |
| Screen push (enter) | 250 | ease-in-out | Screen slides in from right |
| Screen pop (exit) | 250 | ease-in-out | Screen slides out to right |
| Modal open | 200 | ease-out | Expands from center |
| Modal close | 150 | ease-in | Collapses faster than it opens |
| Toast enter | 200 | ease-out | Slides in from screen edge |
| Toast exit | 200 | ease-in | |
| Tab switch | 150 | ease-in-out | Content cross-fades or slides |
| Tooltip appear | 120 | ease-out | After 300-400ms delay |
| Tooltip disappear | 80 | ease-in | |
| Progress bar fill | 300 | ease-out | Value changes animate smoothly |
| Value flash (damage, gain) | 100ms on + 100ms off | linear | Brief, attention-catching |
| Dialogue text reveal (per character) | 30ms per character | linear | Configurable in accessibility settings |
| HUD damage flash | 80 | linear | White or red overlay, immediate |

**Motion reduction overrides**: When motion reduction mode is enabled (see accessibility-requirements.md), all slide and scale animations are replaced with fades. Fade durations are reduced by 50%. Looping animations (indeterminate spinners, pulsing indicators) are replaced with static equivalents.

---

## Sound Standards

> Every interactive event should have audio feedback. Sound is a primary feedback
> channel, not a decoration. The sounds defined here are event categories — the
> specific audio assets are defined in `design/audio/sound-bible.md` (or
> `design/gdd/sound-bible.md`, where earlier versions put it). This table maps
> interaction events to sound categories so the sound designer and UI programmer
> use the same vocabulary.

| Interaction Event | Sound Category | Notes |
|------------------|---------------|-------|
| Button hover / focus | UI Hover | Subtle, short (< 80ms), non-fatiguing on rapid navigation. Hades uses a very quiet, high-frequency click that disappears into background on rapid nav. |
| Button (Primary) confirm | UI Confirm — Primary | Slightly more prominent than secondary confirm. The "yes, let's go" sound. |
| Button (Secondary) cancel / back | UI Cancel | Subtly downward in pitch. The "going back" sound. Mass Effect uses a clean, distinct swoosh for back navigation. |
| Button (Destructive) — opening confirmation | UI Warning | Distinct from standard confirm. Brief attention-catching sound. |
| Confirmation dialog — confirm destructive | UI Confirm — Destructive | Final, slightly weighted. The action is being taken. |
| Toggle ON | UI Toggle On | Brief, snappy, slightly bright. Celeste's accessibility toggles have a satisfying click-on sound. |
| Toggle OFF | UI Toggle Off | Same click family, slightly flatter. |
| Slider adjust | UI Slider | Subtle continuous sound while dragging. A single click per D-pad step. Never fatiguing. |
| Dropdown open | UI Expand | Brief, directional (opening feel). |
| Dropdown close / select | UI Select | Confirmation feel. |
| Tab switch | UI Tab | Horizontal movement feel. Distinct from vertical navigation. |
| Modal open | UI Modal Open | More prominent than standard navigation — draws attention. |
| Modal close (cancel) | UI Modal Close | Returns to previous context. |
| Toast — informational | UI Notification | Background-level, non-intrusive. |
| Toast — achievement | UI Achievement | Celebratory but not overlong. The player should feel rewarded, not interrupted. |
| Toast — warning | UI Warning — Toast | Distinct from error. Alert, not alarming. |
| Error state | UI Error | Friendly but clear. Not a harsh buzzer. Dark Souls uses a subtle dull thud for failed actions — communicates "no" without being harsh. |
| Success confirmation | UI Success | Clean and satisfying. |
| Ability activate | Gameplay — Ability Activate | In-world feel, distinct from pure UI. Part of game feel, not menu feel. |
| Damage received | Gameplay — Damage | See sound-bible.md for full specification. |
| Item pickup | Gameplay — Item Acquire | Brief, rewarding. |
| Level up / rank up | Gameplay — Progression | Celebratory, appropriately prominent. |
| Dialogue advance | UI Dialogue | Subtle, matches typewriter rhythm if typewriter is active. |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does the engine's accessibility node system support screen reader announcements for toast notifications without requiring focus? Verify against engine-reference/godot/ for Godot 4.6.] | [ux-designer] | [Before first menu implementation] | [Unresolved] |
| [What is the platform-correct confirm/cancel button mapping for Nintendo Switch release? Nintendo first-party convention differs from Xbox/PlayStation.] | [producer] | [Before platform certification submission] | [Unresolved] |
| [Should damage numbers be pooled as Label3D nodes or rendered in a SubViewport? Verify performance budget in coordination with technical-director.] | [lead-programmer, ux-designer] | [Before combat HUD implementation] | [Unresolved] |
| [What is the maximum number of simultaneous toast notifications before the queue becomes visually overwhelming? Needs playtesting.] | [ux-designer] | [First playtesting session] | [Unresolved] |
| [Add question] | [Owner] | [Deadline] | [Resolution] |
