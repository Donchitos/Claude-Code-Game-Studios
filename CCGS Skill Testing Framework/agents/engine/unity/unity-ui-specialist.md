# Agent Test Spec: unity-ui-specialist

## Agent Summary
Domain: Unity UI Toolkit (UXML/USS), UGUI (Canvas), data binding, runtime UI performance, and UI input event handling.
Does NOT own: UX flow design (ux-designer), visual art style (art-director).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UI Toolkit / UGUI / Canvas / data binding)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UX flow design or visual art direction

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement an inventory UI screen using Unity UI Toolkit."
**Expected behavior:**
- Produces a UXML document defining the inventory panel structure (ListView, item templates, detail panel)
- Produces USS styles for the inventory layout and item states (default, hover, selected)
- Provides C# code binding the inventory data model to the UI via `INotifyValueChanged` or `IBindable`
- Uses `ListView` with `makeItem` / `bindItem` callbacks for the scrollable item list
- Does NOT produce the UX flow design — implements from a provided spec

### Case 2: Out-of-domain redirect
**Input:** "Design the UX flow for the inventory — what happens when the player equips vs. drops an item."
**Expected behavior:**
- Does NOT produce UX flow design
- Explicitly states that interaction flow design belongs to `ux-designer`
- Redirects the request to `ux-designer`
- Notes it will implement whatever flow the ux-designer specifies

### Case 3: UI Toolkit data binding for dynamic list
**Input:** "The inventory list needs to update in real time as items are added or removed from the player's bag."
**Expected behavior:**
- Produces the `ListView` pattern with a bound `ObservableList<T>` or event-driven refresh approach
- Uses `ListView.Rebuild()` or `ListView.RefreshItems()` on the backing collection change event
- Notes the performance considerations for large lists (virtualization via `makeItem`/`bindItem` pattern)
- Does NOT use `QuerySelector` loops to update individual elements as a list refresh strategy — flags that as a performance antipattern

### Case 4: Canvas performance — overdraw
**Input:** "The main menu canvas is causing GPU overdraw warnings; there are many overlapping panels."
**Expected behavior:**
- Identifies overdraw causes: multiple stacked canvases, full-screen overlay panels not culled when inactive
- Recommends:
  - Separate canvases for world-space, screen-space-overlay, and screen-space-camera layers
  - Disable/deactivate panels instead of setting alpha to 0 (invisible alpha-0 panels still draw)
  - Canvas Group + alpha for fade effects, not individual Image alpha
- Notes UI Toolkit alternative if the project is in a migration position

### Case 5: Context pass — Unity version
**Input:** Project context: Unity 2022.3 LTS. Request: "Implement the settings panel with data binding."
**Expected behavior:**
- Uses UI Toolkit with the 2022.3 LTS version of the runtime binding system
- Notes that Unity 2022.3 introduced runtime data binding (as opposed to editor-only binding in earlier versions)
- Does NOT use the Unity 6 enhanced binding API features if they are not available in 2022.3
- Produces code compatible with the stated Unity version, with version-specific API notes

---

## Protocol Compliance

- [ ] Stays within declared domain (UI Toolkit, UGUI, data binding, UI performance)
- [ ] Redirects UX flow design to ux-designer
- [ ] Returns structured output (UXML, USS, C# binding code)
- [ ] Uses the correct Unity UI framework version for the project's Unity version
- [ ] Flags Canvas overdraw as a performance antipattern and provides specific remediation
- [ ] Does not use alpha-0 as a hide/show pattern — uses SetActive() or VisualElement.style.display

---

## Coverage Notes
- Inventory UI (Case 1) should have a manual walkthrough doc in `production/qa/evidence/`
- Dynamic list binding (Case 3) should have an integration test or automated interaction test
- Canvas overdraw (Case 4) verifies the agent knows the correct Unity UI performance patterns
