# Agent Test Spec: ue-umg-specialist

## Agent Summary
- **Domain**: UMG widget hierarchy design, data binding patterns, CommonUI input routing and action tags, widget styling (WidgetStyle assets), UI optimization (widget pooling, ListView, invalidation)
- **Does NOT own**: UX flow and screen navigation design (ux-designer), gameplay logic (gameplay-programmer), backend data sources (game code), server communication
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; defers UX flow decisions to ux-designer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UMG, widget hierarchy, CommonUI)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UX flow, navigation architecture, or gameplay data logic

---

## Test Cases

### Case 1: In-domain request — inventory widget with data binding
**Input**: "Create an inventory widget that shows a grid of item slots. Each slot should display item icon, quantity, and rarity color. It needs to update when the inventory changes."
**Expected behavior**:
- Produces a UMG widget structure: a parent WBP_Inventory containing a UniformGridPanel or TileView, with a child WBP_InventorySlot widget per item
- Describes data binding approach: either Event Dispatchers on an Inventory Component triggering a refresh, or a ListView with a UObject item data class implementing IUserObjectListEntry
- Specifies how rarity color is driven: a WidgetStyle asset or a data table lookup, not hardcoded color values
- Output includes the widget hierarchy, binding pattern, and the refresh trigger mechanism

### Case 2: Out-of-domain request — UX flow design
**Input**: "Design the full navigation flow for our inventory system — how the player opens it, transitions to character stats, and exits to the pause menu."
**Expected behavior**:
- Does not produce a navigation flow or screen transition architecture
- States clearly: "Navigation flow and screen transition design is owned by ux-designer; I can implement the UMG widget structure once the flow is defined"
- Does not make UX decisions (back button behavior, transition animations, modal vs. fullscreen) without a UX spec

### Case 3: Domain boundary — CommonUI input action mismatch
**Input**: "Our inventory widget isn't responding to the controller Back button. We're using CommonUI."
**Expected behavior**:
- Identifies the likely cause: the widget's Back input action tag does not match the project's registered CommonUI InputAction data asset
- Explains the CommonUI input routing model: widgets declare input actions via `CommonUI_InputAction` tags; the CommonActivatableWidget handles routing
- Provides the fix: verify that the widget's Back action tag matches the registered tag in the project's CommonUI input action data table
- Distinguishes this from a hardware input binding issue (which would be Enhanced Input territory)

### Case 4: Widget performance issue — many widget instances per frame
**Input**: "Our leaderboard widget creates 500 individual WBP_LeaderboardRow instances at once. The game hitches for 300ms when opening the leaderboard."
**Expected behavior**:
- Identifies the root cause: 500 widget instantiations in a single frame causes a construction hitch
- Recommends switching to ListView or TileView with virtualization — only visible rows are constructed
- Explains the IUserObjectListEntry interface requirement for ListView data objects
- If ListView is not appropriate, recommends pooling: pre-instantiate a fixed number of rows and recycle them with new data
- Output is a concrete recommendation with the specific UMG component to use, not a vague "optimize it"

### Case 5: Context pass — CommonUI setup already configured
**Input context**: Project uses CommonUI with the following registered InputAction tags: UI.Action.Confirm, UI.Action.Back, UI.Action.Pause, UI.Action.Secondary.
**Input**: "Add a 'Sort Inventory' button to the inventory widget that works with CommonUI."
**Expected behavior**:
- Uses UI.Action.Secondary (or recommends registering a new tag like UI.Action.Sort if Secondary is already allocated)
- Does NOT invent a new InputAction tag without noting that it must be registered in the CommonUI data table
- Does NOT use a non-CommonUI input binding approach (e.g., raw key press in Event Graph) when CommonUI is the established pattern
- References the provided tag list explicitly in the recommendation

---

## Protocol Compliance

- [ ] Stays within declared domain (UMG structure, data binding, CommonUI, widget performance)
- [ ] Redirects UX flow and navigation design requests to ux-designer
- [ ] Returns structured findings (widget hierarchy + binding pattern) rather than freeform opinions
- [ ] Uses existing CommonUI InputAction tags from context; does not invent new ones without flagging registration requirement
- [ ] Recommends virtualized lists (ListView/TileView) before widget pooling for large collections

---

## Coverage Notes
- Case 3 (CommonUI input routing) requires project to have CommonUI configured; test is skipped if project does not use CommonUI
- Case 4 (performance) is a high-impact failure mode — 300ms hitches are shipping-blocking; prioritize this test case
- Case 5 is the most important context-awareness test for UI pipeline consistency
- No automated runner; review manually or via `$skill-test`
