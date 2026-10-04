> Authoring guidance for ux-spec.md. Load only the part covering the section currently being authored — not the whole file at once.

# UX Specification Template — Authoring Guidance

Guidance is organized by template section number. When authoring a section of a
project's UX spec, read only that section's guidance below.

---

## Section 1 — Purpose & Player Need

> **Why this section exists**: Every screen must justify its existence from the
> player's perspective. Screens that are designed from a developer perspective ("display
> the save data") produce cluttered, confusing interfaces. Screens designed from the
> player's perspective ("let the player feel confident their progress is safe before they
> put the controller down") produce purposeful, calm interfaces. Write this section before
> touching any layout decisions — it is the filter through which every subsequent choice
> is evaluated.

**Authoring the player need**:

[One paragraph. Name the real human need, not the system function. Consider: what would
a player say they want when they open this screen? What would frustrate them if it did
not work? That frustration describes the need.

Example — bad: "Displays the player's current items and equipment."
Example — good: "Lets the player understand what they're carrying and quickly decide what
to take into the next encounter, without breaking their mental model of the game world.
The inventory is the player's planning tool between moments of action."]

**Authoring the player goal**:

[One sentence. Specific enough that you could write an acceptance criterion for it.
Example: "Find the item they are looking for within three button presses and equip it
without navigating to a separate screen."]

**Authoring the game goal**:

[One sentence. This is what the system needs from this interaction. Example: "Record the
player's equipment choices and relay them to the combat system before the next encounter
loads." This section prevents UI that looks good but fails to serve the system it is
part of.]

---

## Section 2 — Player Context on Arrival

> **Why this section exists**: Screens do not exist in isolation. A player opening the
> inventory mid-combat is in a completely different cognitive and emotional state than
> a player opening it after clearing a dungeon. The same information architecture can
> feel oppressively complex in one context and trivially simple in another. Document the
> context so that design decisions — what to show first, what to hide, what to animate,
> what to simplify — are calibrated to the actual player arriving at this screen, not
> an abstract user.

**Worked example answers for the context table**:

| Question | Answer |
|----------|--------|
| What was the player just doing? | [e.g., Completed a combat encounter / Pressed Esc from exploration / Triggered a story cutscene] |
| What is their emotional state? | [e.g., High tension — just narrowly survived / Calm — exploring between objectives] |
| What cognitive load are they carrying? | [e.g., High — actively tracking enemy positions / Low — no active threats] |
| What information do they already have? | [e.g., They know they just picked up an item but haven't seen its stats yet] |
| What are they most likely trying to do? | [e.g., Check if the new item is better than their current weapon — primary use case] |
| What are they likely afraid of? | [e.g., Missing something, making an irreversible mistake, losing track of where they were] |

**Authoring the emotional design target**:

[One sentence describing the feeling the player should have while using this screen.
Example: "Confident and in control — the player should feel like they have complete
information and complete authority over their choices, with no ambiguity about outcomes."]

---

## Section 3 — Navigation Position

> **Why this section exists**: A screen that does not know where it sits in the
> navigation hierarchy cannot define its entry/exit transitions, its back-button
> behavior, or its relationship to the game's pause state. Navigation position also
> reveals architectural problems early — if this screen is reachable from eight
> different places, that is a complexity flag that should be resolved in design, not
> implementation.

**Worked example — reachability table**:

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [e.g., Main Menu → Play] | [Player selects "New Game"] | [Primary entry point] |
| [e.g., Pause Menu → Resume] | [Player presses Start from any gameplay state] | [Secondary entry] |
| [e.g., Game event] | [Tutorial system forces open first time only] | [Systemic entry — must not break if player dismisses] |

---

## Section 4 — Entry & Exit Points

> **Why this section exists**: Entry and exit define the screen's contract with the
> rest of the navigation system. Every entry point must have a corresponding exit point.
> Transitions that are undefined become bugs — the player finds themselves stuck, or the
> game state becomes inconsistent. Fill this table completely before implementation
> begins. Empty cells are a sign that design work is unfinished.

**Worked example — entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [e.g., Player presses Inventory button] | [Gameplay / Exploration state] | [Overlay push — game pauses] | [Current player loadout, inventory contents] | [Works from any non-combat state] |
| [e.g., Item pickup prompt accepted] | [Gameplay / Item Pickup dialog] | [Replace dialog with full inventory] | [Newly acquired item pre-highlighted] | [The new item should be visually distinguished on open] |
| [e.g., Quest system directs player to inventory] | [Gameplay / Quest Update notification] | [Overlay push] | [Quest-relevant item ID for highlight] | [Screen should deep-link to the relevant item] |

**Worked example — exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [e.g., Player closes inventory (Back/B/Esc)] | [Previous state — Exploration] | [Overlay pop — game resumes] | [Updated equipment loadout committed] | [Changes must be committed before transition begins] |
| [e.g., Player selects "Equip" on item] | [Same screen, updated state] | [In-place state change] | [Loadout change event fired] | [No navigation, just a state refresh] |
| [e.g., Player navigates to Map from inventory shortcut] | [Map Screen] | [Replace] | [No data] | [Inventory state is preserved if player returns] |

---

## Section 5 — Layout Specification

> **Why this section exists**: The layout specification is the handoff artifact between
> UX design and UI programming. It does not need to be pixel-perfect — it needs to
> communicate hierarchy (what is important), proximity (what belongs together), and
> proportion (what is big vs. small). ASCII wireframes achieve this without requiring
> design software. A programmer who reads this section should be able to build the
> correct structure without guessing. An artist who reads it should know where
> visual weight should be concentrated.
>
> Draw the layout at one standard resolution (e.g., 1920x1080). Note adaptations
> for other resolutions separately.

**Worked example — wireframe (5.1)**:

```
Example:
┌──────────────────────────────────────────────┐
│  [← Back]        INVENTORY         [Options] │  ← HEADER ZONE
├──────────────────────────────────────────────┤
│ ┌──────────────┐  ┌─────────────────────────┐│
│ │ CATEGORY NAV │  │  ITEM DETAIL PANEL      ││  ← CONTENT ZONE
│ │  ● Weapons   │  │  Item Name              ││
│ │    Armor     │  │  {item icon}            ││
│ │    Consumable│  │  Stats comparison       ││
│ │    Key Items │  │  Description text...    ││
│ ├──────────────┤  └─────────────────────────┘│
│ │ ITEM GRID    │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ ...          │                             │
│ └──────────────┘                             │
├──────────────────────────────────────────────┤
│   [Equip]     [Drop]     [Compare]  [Close]  │  ← ACTION BAR
└──────────────────────────────────────────────┘
```

**Worked example — layout zones table (5.2)**:

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| [e.g., Header Zone] | [Top bar: navigation, screen title, global actions] | [Full width, ~10% height] | [No] | [Truncate long screen names with ellipsis] |
| [e.g., Category Nav] | [Left panel: item category tabs] | [~25% width, ~75% height] | [Yes — vertical if categories exceed panel] | [Scroll indicator appears at bottom of list] |
| [e.g., Item Grid] | [Center: grid of item icons for selected category] | [~45% width, ~75% height] | [Yes — vertical] | [Page-based: 4x4 grid, next page on overflow] |
| [e.g., Detail Panel] | [Right: stats and description for selected item] | [~30% width, ~75% height] | [Yes — vertical for long descriptions] | [Fade at bottom, scroll to reveal] |
| [e.g., Action Bar] | [Bottom: context-sensitive actions for selected item] | [Full width, ~15% height] | [No] | [Actions collapse to icon-only below 4] |

**Worked example — component inventory table (5.3)**:

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [e.g., Back Button] | [Button] | [Header] | [Returns to previous screen] | [Yes] | [Yes — standard NavButton component] |
| [e.g., Screen Title Label] | [Text] | [Header] | [Displays "INVENTORY" or context name] | [Yes] | [Yes — ScreenTitle component] |
| [e.g., Category Tab] | [Toggle Button] | [Category Nav] | [Filters item grid by category] | [Yes] | [No — new component needed] |
| [e.g., Item Slot] | [Icon + Frame] | [Item Grid] | [Represents one inventory slot, empty or filled] | [Yes] | [No — new component] |
| [e.g., Item Name Label] | [Text] | [Detail Panel] | [Shows selected item's name] | [Yes] | [Yes — BodyText component] |
| [e.g., Stat Comparison Row] | [Compound — label + value + delta] | [Detail Panel] | [Shows stat value vs. currently equipped] | [Yes] | [No — new component] |
| [e.g., Equip Button] | [Primary Button] | [Action Bar] | [Equips selected item in appropriate slot] | [Yes] | [Yes — PrimaryAction component] |
| [e.g., Empty State Message] | [Text + Icon] | [Item Grid] | [Shown when category has no items] | [Yes] | [Yes — EmptyState component] |

**Worked example — primary focus element on open**: [e.g., The first item in the Item Grid — or, if deep-linked, the highlighted item. If the grid is empty, focus lands on the first Category Tab.]

---

## Section 6 — States & Variants

> **Why this section exists**: A screen is not a single picture — it is a set of
> states, each of which must look correct and behave correctly. Screens that are
> designed only in their "happy path" state ship with broken empty states, invisible
> loading indicators, and crashes when data is missing. Document every state before
> implementation. The states table is also the test matrix for QA.

**Worked example table**:

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| [Loading] | [Screen is opening, data not yet available] | [Item Grid shows skeleton/shimmer placeholders; Action Bar buttons disabled] | [No interactions possible except Close] | [Should not be visible >500ms under normal conditions; if it is, investigate data fetch performance] |
| [Empty — no items in category] | [Player switches to a category with zero items] | [Item Grid replaced by EmptyState component: icon + "Nothing here yet."] | [Action Bar shows no item actions; Drop/Equip/Compare all hidden] | [Do not show disabled buttons — remove them. Disabled buttons with no tooltip are confusing.] |
| [Populated — items present] | [Category has at least one item] | [Item Grid fills with item slots; first slot is auto-focused] | [All item actions available for selected item] | [Default and most common state] |
| [Item Selected] | [Player navigates to an item slot] | [Detail Panel populates; selected slot has focus ring; Action Bar updates to item's valid actions] | [Equip/Drop/Compare enabled based on item type] | [Equip is disabled if item is already equipped — show a "Equipped" badge instead] |
| [Confirmation Pending — Drop] | [Player selects Drop action] | [Confirmation dialog overlays the screen] | [All background interactions suspended until dialog resolves] | [Use a modal confirmation, not an inline toggle. Items cannot be recovered after dropping.] |
| [Error — data load failed] | [Inventory data could not be retrieved] | [Item Grid shows error state: icon + "Couldn't load items." + Retry button] | [Only Retry and Close are available] | [Log the error; do not expose technical details to player] |
| [Item Newly Acquired] | [Screen opened from item pickup deep-link] | [Newly acquired item has a visual "New" badge; Detail Panel pre-populated with that item] | [Same as Item Selected but with badge until player navigates away] | [Badge persists until the player manually navigates off that slot once] |

---

## Section 7 — Interaction Map

> **Why this section exists**: This section is the source of truth for what every
> input does on this screen. It forces the designer to think through every input
> method (mouse, keyboard, gamepad, touch) and every interactive state (hover, focus,
> pressed, disabled). Gaps in this table are bugs waiting to happen. The
> interaction map is also the input for the accessibility audit — if an action is
> only reachable by mouse, it will fail the keyboard and gamepad columns.

**Worked example — navigation inputs (7.1)**:

| Input | Platform | Action | Visual Response | Audio Cue | Notes |
|-------|----------|--------|-----------------|-----------|-------|
| [Arrow keys / D-Pad] | [All] | [Move focus within active zone] | [Focus ring moves to adjacent element] | [Soft navigation tick] | [Wrap at edges within zone; do not cross zones with arrows alone] |
| [Tab / R1] | [KB / Gamepad] | [Move focus to next zone (Category → Grid → Detail → Action Bar)] | [Focus ring jumps to first element in next zone] | [Distinct zone-change tone] | [Shift+Tab / L1 goes backward] |
| [Mouse hover] | [PC] | [Show hover state on interactive elements] | [Highlight / underline / color shift] | [None] | [Hover does NOT move focus — only click does] |
| [Mouse click] | [PC] | [Select and focus the clicked element] | [Pressed state flash, then selected/focused] | [Soft click] | [Right-click opens context menu if applicable; otherwise no-op] |
| [Touch tap] | [Mobile] | [Select and activate in one gesture] | [Press ripple] | [Soft click] | [Treat tap as click + confirm for low-risk actions; require explicit confirm for destructive actions] |

**Worked example — action inputs (7.2)**:

| Input | Platform | Context (What must be focused) | Action | Response | Animation | Audio Cue | Notes |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [Enter / A button / Left click] | [All] | [Item slot focused] | [Select item → populate Detail Panel] | [Detail panel slides in or updates in place] | [Panel fade/slide in, 120ms] | [Soft select tone] | [If item already selected: no-op] |
| [Enter / A button] | [All] | [Equip button focused] | [Equip selected item] | [Button animates press; item badge updates to "Equipped"; previously equipped item loses badge] | [Badge swap, 80ms] | [Equip success sound] | [Fires EquipItem event to Inventory system] |
| [Triangle / Y button / Right-click] | [All] | [Item slot focused] | [Open item context menu] | [Context menu appears adjacent to item slot] | [Popover, 80ms] | [Menu open sound] | [Context menu contains: Equip, Drop, Inspect, Compare] |
| [Square / X button] | [Gamepad] | [Item slot focused] | [Quick-equip without opening detail] | [Equip animation plays inline on slot] | [Slot flash, 80ms] | [Equip success sound] | [Convenience shortcut; does not change screen state] |
| [Esc / B button / Back] | [All] | [Any, screen level] | [Close screen and return to previous state] | [Screen exit transition plays] | [Slide out, 200ms] | [Back/close tone] | [Commits all changes before closing. No discard — inventory is not a draft.] |
| [F / L2] | [KB / Gamepad] | [Any] | [Toggle filter panel] | [Sort/filter overlay opens] | [Slide in from right, 200ms] | [Panel open tone] | [If no items in category, filter is disabled] |

**Worked example — state-specific behaviors (7.3)**:

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [Loading] | [All item and action inputs disabled] | [No data to act on; prevent race conditions] |
| [Confirmation dialog open] | [Only Confirm and Cancel inputs active] | [Modal — background is locked] |
| [Error state] | [Only Retry and Close active] | [No data available to navigate] |

---

## Section 8 — Data Requirements

> **Why this section exists**: The separation between UI and game state is the most
> important architectural boundary in a game's UI system. UI reads data; it does not
> own it. UI fires events; it does not write state directly. This section defines
> exactly what data this screen needs to display, where it comes from, and how
> frequently it updates. Filling this table before implementation prevents two
> common failure modes: (1) UI developers reaching into systems they should not touch,
> and (2) systems not knowing they need to expose data until a UI is half-built.

**Worked example table**:

| Data Element | Source System | Update Frequency | Who Owns It | Format | Null / Missing Handling |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [e.g., Item list] | [Inventory System] | [On screen open; on InventoryChanged event] | [InventorySystem] | [Array of ItemData structs: id, name, icon_path, category, stats, is_equipped] | [Empty array → show Empty State. Never null — system must return array.] |
| [e.g., Equipped loadout] | [Equipment System] | [On screen open; on EquipmentChanged event] | [EquipmentSystem] | [Dict mapping slot_id → item_id] | [Unequipped slot has null value — UI shows empty slot icon] |
| [e.g., Item stat comparisons] | [Stats System] | [On item selection change] | [StatsSystem] | [Dict mapping stat_name → {current, new, delta}] | [If no item selected, detail panel shows placeholder. Stats system must handle this gracefully.] |
| [e.g., Player currency] | [Economy System] | [On screen open only — inventory does not show live currency] | [EconomySystem] | [Int — gold pieces] | [If currency system not active for this game mode, hide the currency row entirely] |
| [e.g., Newly acquired item flag] | [Inventory System] | [On screen open] | [InventorySystem] | [Array of item_ids flagged as new] | [If empty array, no badges shown] |

---

## Section 9 — Events Fired

> **Why this section exists**: This is the other half of the UI/system boundary.
> Where Section 8 defines what the UI reads, this section defines what the UI
> communicates back to the game. Specifying events at design time prevents UI
> programmers from writing game logic, and prevents game programmers from being
> surprised by what the UI does. Every destructive or state-changing player action
> must appear in this table.

**Worked example table**:

| Player Action | Event Fired | Payload | Receiver System | Notes |
|---------------|-------------|---------|-----------------|-------|
| [Player equips an item] | [EquipItemRequested] | [{item_id: string, target_slot: string}] | [Equipment System] | [Equipment System validates the action and fires EquipmentChanged if successful; UI listens for EquipmentChanged to update its display] |
| [Player drops an item] | [DropItemRequested] | [{item_id: string, quantity: int}] | [Inventory System] | [Fires only after player confirms the drop dialog. Inventory System removes the item and fires InventoryChanged.] |
| [Player opens item compare] | [ItemCompareOpened] | [{item_a_id: string, item_b_id: string}] | [Analytics System] | [No game-state change — analytics event only. Compare view is purely local UI state.] |
| [Player closes screen] | [InventoryScreenClosed] | [{session_duration_ms: int}] | [Analytics System] | [Fires on every close regardless of reason. Used for engagement metrics.] |
| [Player navigates between categories] | [InventoryCategoryChanged] | [{category: string}] | [Analytics System] | [Analytics only. No game state change.] |

---

## Section 10 — Transitions & Animations

> **Why this section exists**: Transitions are not decoration — they communicate
> hierarchy and causality. A screen that slides in from the right implies the
> player has moved forward. A screen that fades implies a context break. Inconsistent
> transitions make navigation feel broken even when it is technically correct.
> This section ensures transitions are specified intentionally, not left to the
> developer's discretion, and that accessibility settings (reduced motion) are
> planned for from the start.

**Worked example table**:

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [Screen enter] | [Screen pushed onto stack] | [Slide in from right] | [250] | [Ease out cubic] | [No — must complete before interaction is enabled] | [Yes — instant appear at 0ms] |
| [Screen exit — Back] | [Player presses Back] | [Slide out to right] | [200] | [Ease in cubic] | [No] | [Yes — instant disappear] |
| [Screen exit — Forward] | [Player navigates to child screen] | [Slide out to left] | [200] | [Ease in cubic] | [No] | [Yes — instant] |
| [Detail panel update] | [Player selects a new item] | [Cross-fade content] | [120] | [Linear] | [Yes — if player navigates quickly, previous animation cancels] | [Yes — instant swap] |
| [Loading → Populated] | [Data arrives after load] | [Skeleton shimmer fades out, content fades in] | [180] | [Ease out] | [No] | [Yes — instant reveal] |
| [Action Bar button press] | [Player activates a button] | [Scale down 95% on press, return on release] | [60 down / 60 up] | [Ease out / ease in] | [Yes — if released early, returns to normal] | [No — this is tactile feedback, not decorative motion] |
| [Confirmation dialog open] | [Player initiates destructive action] | [Background dims 60% opacity; dialog scales up from 95%] | [150] | [Ease out] | [No] | [Yes — instant appear, no scale] |
| [New item badge appear] | [Screen opens with newly acquired item] | [Badge pops from 0% to 110% to 100% scale] | [200 total] | [Ease out back] | [No] | [Yes — instant appear at 100% scale] |

---

## Section 11 — Input Method Completeness Checklist

> **Why this section exists**: Input completeness is not optional — it is a
> certification requirement for console platforms and a legal risk area for
> accessibility laws in multiple markets. Fill this checklist before marking
> the spec as Approved. Any unchecked item blocks implementation start.

---

## Section 12 — Accessibility

> **Why this section exists**: Accessibility requirements must be specified at design
> time because retrofitting them is expensive and often architecturally impractical.
> This section documents requirements specific to this screen. Project-wide standards
> live in `design/accessibility-requirements.md` — consult it before filling this
> section so you do not duplicate or contradict project-level commitments.

**Worked example — text contrast table**:

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|---------------|---------------|-------|
| [e.g., Item name in Detail Panel] | [Dark panel background ~#1a1a1a] | [4.5:1 (WCAG AA normal text)] | [TBD — verify in implementation] | [ ] |
| [e.g., Category tab label — inactive] | [Mid-grey tab background] | [4.5:1] | [TBD] | [ ] |
| [e.g., Category tab label — active] | [Accent color background] | [4.5:1] | [TBD] | [ ] |
| [e.g., Action button label] | [Button color (varies by state)] | [4.5:1] | [TBD] | [ ] |
| [e.g., Stat comparison delta (positive)] | [Detail panel] | [4.5:1 — do NOT rely on green color alone] | [TBD] | [ ] |

**Worked example — colorblind mitigations table**:

| Element | Colorblind Risk | Mitigation |
|---------|----------------|------------|
| [e.g., Stat delta indicators (red/green for worse/better)] | [Red-green colorblindness (Deuteranopia) — most common form] | [Add arrow icons (↑ / ↓) and +/- prefix in addition to color. Color is a redundant, not sole, indicator.] |
| [e.g., Item rarity color coding (grey/green/blue/purple/orange)] | [Multiple types — rarity color is a common industry failure] | [Add rarity name text label below icon. Color is supplemental only.] |

**Worked example — focus order**:

[e.g.,
1. Back button (Header)
2. Options button (Header)
3. Category Tab 1 — Weapons
4. Category Tab 2 — Armor
5. Category Tab 3 — Consumables
6. Category Tab 4 — Key Items
7. Item Slot [0,0]
8. Item Slot [0,1] ... (grid traverses left-to-right, top-to-bottom)
9. Last item slot
10. Equip button (Action Bar)
11. Drop button (Action Bar)
12. Compare button (Action Bar)
13. Close button (Action Bar)
→ Cycles back to Back button

Focus does not enter the Detail Panel — it is a display panel driven by item focus, not independently navigable.]

**Worked example — screen reader announcements table**:

| State Change | Announcement Text | Announcement Timing |
|--------------|------------------|---------------------|
| [Screen opens] | ["Inventory screen. [N] items. [Active category] selected."] | [On screen focus settle] |
| [Player focuses an item slot] | ["[Item name]. [Category]. [Rarity]. [Key stats summary]. [Equipped / Not equipped]."] | [On focus arrival] |
| [Player equips an item] | ["[Item name] equipped to [slot name]."] | [After EquipmentChanged event confirmed] |
| [Player drops an item] | ["[Item name] dropped."] | [After InventoryChanged event confirmed] |
| [Category changes] | ["[Category name]. [N] items."] | [On category tab focus] |
| [Empty state shown] | ["No items in [category name]."] | [When empty state renders] |

**Authoring the cognitive load assessment**:

[Estimate the number of information streams the player is simultaneously tracking while
using this screen. For this screen: (1) item grid position, (2) item detail stats,
(3) current equipment loadout for comparison, (4) available actions, (5) item category.
That is 5 concurrent streams — within the standard 7±2 limit, but at the higher end.
Mitigation: detail panel auto-updates on navigation so the player never needs to
manually retrieve item info. Reduce active decisions by surfacing stat comparison
automatically.]

---

## Section 13 — Localization Considerations

> **Why this section exists**: UI built without localization in mind breaks on first
> translation. German text is typically 30–40% longer than English. Arabic and Hebrew
> require right-to-left layout mirroring. Japanese and Chinese text may be significantly
> shorter than English, creating awkward whitespace. These issues are cheap to plan for
> and expensive to fix after a layout is built and shipped. Every text element should
> have an explicit max-character count and a plan for overflow.

**Worked example table**:

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behavior | Overflow Behavior | Risk |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [e.g., Screen title "INVENTORY"] | [9 chars] | [16 chars] | [78%] | [Mirror to right, or center — acceptable] | [Truncate with ellipsis — title is not critical content] | [Low] |
| [e.g., Item name] | [~15 chars avg, max ~35 "Enchanted Dragon Scale Gauntlets"] | [50 chars] | [43%] | [Right-align in RTL layouts] | [Truncate with tooltip showing full name on hover/focus] | [Medium — long fantasy item names are common] |
| [e.g., Item description] | [~80–120 chars] | [200 chars] | [67%] | [Right-align, wrap normally] | [Scroll within Detail Panel — no truncation] | [Low — panel is scrollable] |
| [e.g., Action button "Equip"] | [5 chars] | [14 chars] | [180%] | [Button layout mirrors; text right-aligns] | [Shrink font to 90% minimum, then truncate] | [Medium — "Ausrüsten" in German is 9 chars] |
| [e.g., Category tab "Consumables"] | [11 chars] | [18 chars] | [64%] | [Mirror tab position] | [Abbreviate: "Consum." — define abbreviations per language in loc file] | [High — long localized tab labels are a known problem] |

---

## Section 14 — Acceptance Criteria

> **Why this section exists**: Acceptance criteria are the contractual definition of
> "done." Without them, implementation is complete when the developer says it is.
> With them, implementation is complete when a QA tester can verify every item on
> this list. Write criteria that a tester can verify independently, without asking the
> designer what they meant. Every criterion should be binary — pass or fail, not
> subjective.

**Worked example criteria (inventory screen)** — note how each is screen-specific
and independently verifiable:

- [ ] Navigation between items produces no perceptible frame drop (maintain target framerate ±5fps)
- [ ] All states (Loading, Empty, Populated, Error, Confirmation) render correctly
- [ ] Item grid scrolls smoothly without frame drops when all item slots are populated
- [ ] Inventory changes persist correctly after screen is closed and reopened
- [ ] Screen handles InventoryChanged events fired by other systems while it is open without crashing
- [ ] Stat comparison does not rely on color alone as the sole differentiator
- [ ] Screen reader announces item name and key stats on focus (verify with platform screen reader)

---

## Section 15 — Open Questions

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [e.g., Should item comparison be automatic (always showing equipped stats) or player-triggered (press Compare)?] | [ux-designer] | [Sprint 4, Day 3] | [Pending] |
| [e.g., Do we support controller cursor (free aim) in the item grid, or d-pad-only grid navigation?] | [lead-programmer + ux-designer] | [Sprint 4, Day 3] | [Pending — depends on ADR-0015 input model decision] |
| [e.g., What is the game's item drop policy — permanent loss or drop-to-world?] | [systems-designer] | [Requires GDD update] | [Blocked on inventory GDD Edge Cases section] |
| [e.g., Maximum inventory size — does the grid have a hard cap or is it infinite-scroll?] | [economy-designer] | [Sprint 3, Day 5] | [Pending] |
