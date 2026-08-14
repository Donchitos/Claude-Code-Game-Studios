# Agent Test Spec: web-ui-specialist

## Agent Summary
Domain: DOM-overlay vs in-canvas UI decisions, HTML/CSS layout, pointer/keyboard/gamepad/touch input, accessibility, responsive layout and safe areas, UI performance.
Does NOT own: game state (gameplay systems), interaction design and flows (ux-designer), visual style (art-director), rendering engine decisions (renderer specialists).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references UI, input, and accessibility
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section noting `100dvh` and pointer events supersede older guidance
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — DOM vs canvas decision
**Input:** "Build the settings menu with volume sliders and a keybinding list."
**Expected behavior:**
- Chooses the **DOM**, not canvas, and explains why (accessibility, focus, text input, native controls come free)
- Uses semantic elements (`<button>`, `<label>`, `<dialog>`) before ARIA
- Includes `100dvh` (never `100vh`) and `env(safe-area-inset-*)`
- Sets `pointer-events: none` on the overlay container with `auto` on controls
- Includes a focus trap and focus restoration for the dialog

### Case 2: Out-of-domain request — redirects correctly
**Input:** "When the player takes damage, should health regenerate automatically after 5 seconds?"
**Expected behavior:**
- Does NOT make the design decision
- Redirects to `game-designer`
- May offer to implement the HUD representation once the rule is decided

### Case 3: Input handling correctness
**Input:** "Add touch and mouse support for dragging units."
**Expected behavior:**
- Uses **Pointer Events**, not separate `mousedown`/`touchstart` paths
- Uses `setPointerCapture` so the drag survives leaving the canvas
- Adds `touch-action: manipulation` to eliminate the 300ms tap delay
- Does not call `preventDefault()` on the whole document

### Case 4: UI performance regression
**Input:** "The game stutters whenever the score updates."
**Expected behavior:**
- Identifies per-frame `textContent` writes as per-frame layout invalidation
- Recommends event-driven updates (`healthChanged` / `scoreChanged`) instead of per-frame writes
- Notes that layout and the game loop share a thread, which is why this shows as game stutter
- Checks for `transition: all` or animation of layout properties as a secondary cause

### Case 5: Context pass — accessibility requirement
**Input:** Context states the project must meet WCAG AA. Request: "Add the low-health warning — the screen edge pulses red."
**Expected behavior:**
- Flags that color alone is insufficient — adds a text or icon indicator
- Adds an `aria-live` region because canvas content is invisible to screen readers
- Respects `prefers-reduced-motion` with a reduced variant rather than disabling the cue
- Verifies 4.5:1 contrast for any accompanying text

---

## Protocol Compliance

- [ ] Stays within declared domain (UI implementation, input, accessibility)
- [ ] Never owns or directly mutates game state — dispatches commands/events instead
- [ ] Routes all user-facing text through the localization system
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Defaults to the DOM and justifies any in-canvas UI choice
- [ ] Does not add UI frameworks without technical-director sign-off

---

## Coverage Notes
- Case 1 tests the DOM-vs-canvas default, which is the decision unique to web among the four engines
- Case 5 verifies the agent treats canvas as inaccessible by default rather than assuming parity with DOM
- Case 4 confirms the agent understands that UI cost and game frame time are coupled on the web
