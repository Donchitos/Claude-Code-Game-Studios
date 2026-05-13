# Agent Test Spec: cocos-ui-specialist

## Agent Summary
Domain: Cocos Creator UI system — UITransform (mandatory on all UI nodes), Layout (Horizontal / Vertical / Grid), Widget (anchored positioning), Canvas configuration, multi-resolution adaptation, Mask, RichText, ScrollView recycling, safe area handling, and mini-game UI quirks.
Does NOT own: gameplay code, shader / Effect files, TypeScript component patterns (delegates to cocos-ts-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UITransform / Layout / Widget / Canvas / multi-resolution / mini-game UI)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition does not claim authority over gameplay code or shader authoring

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create a HUD layout with a top bar (player health, score) and a bottom navigation bar, anchored to screen edges."
**Expected behavior:**
- Produces a node hierarchy:
  ```
  Canvas (root)
  ├── SafeAreaContainer (Widget: align all to safe area)
  │   ├── TopBar (Widget: top=50, left=0, right=0)
  │   │   ├── HealthLabel (Label component)
  │   │   └── ScoreLabel (Label component)
  │   └── BottomNav (Widget: bottom=50, left=0, right=0)
  │       ├── Button1
  │       └── Button2
  ```
- Notes that every UI node requires a `UITransform` component (mandatory since v3.0)
- Uses `Widget` for anchored positioning (not `setPosition()`)
- Wraps content in a `SafeAreaContainer` with Widget aligned to all edges — handles notch / cutout
- Does NOT use `cc.Widget` (removed in v3.0) — uses `Widget` ES module import

### Case 2: Out-of-domain redirect
**Input:** "Implement the player movement script with WASD controls."
**Expected behavior:**
- Does NOT produce gameplay movement code
- Explicitly states that gameplay / character controller implementation belongs to `cocos-ts-specialist` or `gameplay-programmer`
- May note that UI-side touch / button input for virtual joysticks IS within its domain
- Redirects the request appropriately

### Case 3: UITransform missing — silent failure
**Input:** "I added a touch handler on a UI node but `TOUCH_START` events aren't firing."
**Expected behavior:**
- Identifies the most common cause: missing `UITransform` component on the node
- Explains that UI nodes auto-receive touch events only when:
  1. They have a `UITransform` (defines hit area bounding box)
  2. The touch point falls within the bounding box
  3. No higher-priority node has captured the event
- Provides the fix: `this.node.getComponent(UITransform) ?? this.node.addComponent(UITransform)`
- Notes that the node must have non-zero width / height for hit detection
- Lists other common causes: parent has `Mask` with `GRAPHICS_STENCIL` blocking events, node is `active = false`, or `UITransform` content size is zero

### Case 4: Multi-resolution adaptation
**Input:** "The game looks correct on 16:9 devices but stretches on 18:9 / 21:9 phones. How do I fix this?"
**Expected behavior:**
- Identifies this as a screen adaptation issue
- Explains the Canvas configuration:
  - **Fit Width**: scales to fill width, letterbox / crop height (best for portrait)
  - **Fit Height**: scales to fill height, letterbox / crop width (best for landscape)
  - **Both**: fills screen completely, may crop content (use SafeArea for safe content)
- Recommends based on game orientation:
  - Landscape 16:9 game on 18:9 / 21:9 phones → use **Fit Height**, design for 16:9 baseline, add edge content for wider screens
  - Portrait game → use **Fit Width**
- Shows `view.setDesignResolutionSize()` configuration
- Recommends using `Widget` with relative offsets (not absolute pixels) for responsive layout
- Notes mini-game platform differences: WeChat provides `wx.getSystemInfoSync().safeArea` for notch handling

### Case 5: ScrollView recycling for long lists
**Input:** "I have a 1000-item inventory list. Instantiating all items destroys performance."
**Expected behavior:**
- Identifies this as a recycling pattern requirement
- Produces a recycling approach:
  - Pool item Prefabs (use `ObjectPool` pattern)
  - Track visible items based on scroll position
  - Recycle items that scroll out of view
  - Update content on item reuse (don't destroy / instantiate)
- Notes that Cocos Creator has no built-in recycling ListView (community packages exist)
- Provides a sketch implementation using `ScrollView.scrollTop` and item height calculation
- Warns against `Mask` with `GRAPHICS_STENCIL` for the list container (breaks batching for the whole subtree — use `GRAPHICS_RECT` instead)
- Recommends pooling every Prefab instantiated > 5 times per session

---

## Protocol Compliance

- [ ] Stays within declared domain (UI system: UITransform, Layout, Widget, Canvas, multi-resolution, Mask, mini-game UI)
- [ ] Redirects gameplay code to cocos-ts-specialist or gameplay-programmer
- [ ] Redirects shader / visual effects to cocos-shader-specialist
- [ ] Never produces code without `UITransform` on UI nodes (mandatory since v3.0)
- [ ] Uses `Widget` for anchored positioning, never `setPosition()` for responsive UI
- [ ] Distinguishes between `GRAPHICS_RECT` Mask (cheap) and `GRAPHICS_STENCIL` Mask (expensive, breaks batching)
- [ ] Handles safe area for notch / cutout devices on mobile and mini-game platforms

---

## Coverage Notes
- HUD layout (Case 1) verifies the agent produces correct v3.0+ UI hierarchy with UITransform and Widget
- Missing UITransform (Case 3) confirms the agent catches the most common v3.0+ UI bug
- Multi-resolution (Case 4) verifies the agent understands Canvas adaptation modes and platform differences
- Recycling (Case 5) confirms the agent applies performance patterns for long lists, not naive instantiation
