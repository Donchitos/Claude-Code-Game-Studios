# Agent Test Spec: unity-ui-specialist

## Agent Summary
Domain: Unity UI Toolkit (UXML/USS), UGUI (Canvas), data binding, runtime UI performance, and UI input event handling.
Does NOT own: UX flow design (ux-designer), visual art style (art-director).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UI Toolkit / UGUI / Canvas / data binding)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over UX flow design or visual art direction

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement an inventory UI screen using Unity UI Toolkit."
**Expected behavior:**
- Produces a UXML document defining the inventory panel structure (ListView, item templates, detail panel)
- Produces USS styles for the inventory layout and item states (default, hover, selected)
- Provides C# code binding the inventory data model to the UI through the runtime binding system: a ViewModel implementing `INotifyBindablePropertyChanged`, with the UI reading through bindings and never writing game state
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
- Produces the `ListView` pattern over the inventory's backing collection, virtualized with `makeItem` / `bindItem` so only visible rows exist
- Drives the refresh from the inventory's change event (game state → ViewModel → binding), not from per-frame polling
- Does NOT refresh the list by querying the visual tree for each element — flags per-frame visual-tree queries as an antipattern and caches references instead
- Does NOT create and destroy row elements on each change — reuses rows through the virtualized list

### Case 4: Canvas performance — overdraw
**Input:** "The main menu canvas is causing GPU overdraw warnings; there are many overlapping panels."
**Expected behavior:**
- Confirms the hotspot with a profiler before changing structure (Frame Debugger, Profiler UI module)
- Recommends its documented Canvas remediation:
  - One Canvas per logical UI layer, with frequently changing and static content on separate Canvases
  - Explicit `Canvas.sortingOrder` rather than hierarchy order
  - Shared sprite atlases so panels batch, and Raycast Target disabled on non-interactive elements
  - A `CanvasGroup` to fade or hide a group of elements, not per-Image alpha changes
- Notes that screen-space menus are UI Toolkit territory under its own selection rules (the engine reference also marks UGUI Canvas as superseded for new projects), offered as an option rather than a unilateral rewrite

### Case 5: Context pass — Unity version
**Input:** Project context: Unity 2022.3 LTS. Request: "Implement the settings panel with data binding."
**Expected behavior:**
- Checks the stated version against `docs/engine-reference/unity/VERSION.md`, which pins Unity 6.3 LTS, and asks which editor is actually installed before choosing a binding API
- Does NOT state from memory which Unity version introduced runtime data binding — the engine reference does not document it, so the claim is flagged as unverified
- Does NOT emit the runtime binding system (`INotifyBindablePropertyChanged`) for a 2022.3 editor until that API is confirmed available there
- Keeps the version-independent parts of its pattern regardless: UI reads state, user actions dispatch commands, the panel never writes game state directly

---

## Protocol Compliance

- [ ] Stays within declared domain (UI Toolkit, UGUI, data binding, UI performance)
- [ ] Redirects UX flow design to ux-designer
- [ ] Returns structured output (UXML, USS, C# binding code)
- [ ] Checks the project's Unity version against `docs/engine-reference/unity/VERSION.md` before using version-dependent UI APIs, and asks when the stated version and the pin disagree
- [ ] Flags Canvas overdraw as a performance antipattern and provides specific remediation (Canvas split by layer and update rate, atlasing, Raycast Target off)
- [ ] Hides elements with its documented mechanism — `VisualElement.visible = false` in UI Toolkit, a `CanvasGroup` in UGUI — never by setting each element's alpha to 0
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Inventory UI (Case 1) should have a retained screenshot of each screen touched in `production/qa/evidence/`
- Dynamic list binding (Case 3) should have an integration test or automated interaction test
- Canvas overdraw (Case 4) verifies the agent knows the correct Unity UI performance patterns
