# Agent Test Spec: cocos-ui-specialist

## Agent Summary
Domain: Cocos Creator UI subsystem — UITransform / Layout / Widget / Mask / RichText / Sprite & SpriteAtlas / Label / ScrollView, screen adaptation via Canvas, multi-resolution strategy, cross-platform input (touch, mouse, gamepad), UI batching, and mini-game-specific UI quirks (safe area, notch, virtual button).
Does NOT own: TypeScript-side non-UI game logic (delegates to cocos-ts-specialist), Effect / Material authored for a UI element (delegates to cocos-shader-specialist), high-level rendering or asset pipeline architecture (delegates to cocos-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references UITransform / Layout / Widget / Canvas / multi-resolution / mini-game UI)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition does not claim authority over TypeScript game logic, shader authoring, or engine architecture
- [ ] Agent definition references `docs/engine-reference/cocos/VERSION.md` for version awareness
- [ ] Agent definition references `docs/engine-reference/cocos/modules/ui.md` for Canvas / multi-resolution API

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "I need a screen-adapted HUD with a top-bar pinned to screen top and a chat panel that fills the bottom safe area. Target: iOS + WeChat Mini Game."
**Expected behavior:**
- Recommends a `Canvas` root with `Fit Height` or `Fit Width` policy (not just `No Scale`)
- Uses `Widget` for top-bar pinning (target: top, left, right, with top = 0 offset)
- Uses `safeAreaInsets` via `view.getSafeAreaRect()` (3.8+ stable API) for the chat panel bottom
- Calls out iOS notch / dynamic island implication
- Calls out WeChat Mini Game safe-area behavior (may report zero on some devices; recommend manual margin fallback)
- Mentions `Layout` for the chat panel's children, not absolute positions
- Notes that `UITransform` (not `Node.size`) is the correct way to read/set dimensions
- Does NOT produce the full ChatPanel.ts implementation — defers TS to `cocos-ts-specialist`

### Case 2: Out-of-domain redirect
**Input:** "Write a TypeScript component that loads SpriteFrames asynchronously and assigns them to a Sprite."
**Expected behavior:**
- Identifies that runtime asset loading + component wiring is `cocos-ts-specialist` territory
- May note the *UI-side* contract: "the Sprite expects a `SpriteFrame`, and the caller should pass it via `sprite.spriteFrame = frame`"
- May name the asset-bundle recommendation (e.g., `resources/ui_bundle/`) so the TS specialist can wire it
- Does NOT produce the `await assetManager.loadBundle(...)` chain itself
- Redirects appropriately

### Case 3: UI batching anti-pattern
**Input:** "I have a ScrollView with 200 list items, each with a Label and a Sprite. Frame time is 16ms just on the list."
**Expected behavior:**
- Diagnoses UI batching failure: every Label uses a different bitmap font / every Sprite is in a different atlas
- Recommends `SpriteAtlas` for all UI icons and a single shared `.fnt` for all Labels
- Recommends `Label.useSDF = true` for runtime-tinted labels (3.x default)
- Mentions `ScrollView.content` + `Layout` for view recycling, with `item.children[i]` re-skinning (avoiding `instantiate`)
- Notes that `UI` static-batching is gated by `setStatic(true)` on the Canvas root
- References the `docs/engine-reference/cocos/modules/ui.md` performance table
- Does NOT recommend switching to a different engine (out of scope)

### Case 4: Mini-game UI quirk
**Input:** "On WeChat Mini Game my safe area is wrong on iPhone 15 Pro — the bottom controls get hidden by the home indicator."
**Expected behavior:**
- Identifies that `view.getSafeAreaRect()` in 3.8.6 reports device safe area, but the home indicator overlay is sometimes not included
- Recommends a `getVisibleSize()` + `getFrameSize()` fallback that explicitly adds bottom margin on iOS X+ devices
- References the `safeAreaInsets` example in `docs/engine-reference/cocos/modules/ui.md`
- Suggests testing with `wx.getSystemInfoSync().safeArea` for cross-check during development
- Does NOT suggest disabling the safe area (would break App Store guidelines)
- May mention `view.setDesignResolutionSize` and the implications of `Show All` vs `Fit Width` for safe-area math

### Case 5: Context pass — multi-resolution + 2D character customization screen
**Input:** Project context: Cocos Creator 3.8.6. Request: "I need a character preview screen with a background, equipment slots, and a 'Done' button. Must work on iPhone SE (small) and iPad Pro 12.9 (large), plus 1080×1920 Android phone."
**Expected behavior:**
- Suggests `Canvas` with `Fit Width` policy (keeps width fixed, scales height — best for portrait mobile)
- Recommends `Widget` anchoring for the Done button (bottom-right inset, NOT a fixed Y position)
- Recommends `Layout` (Type: VERTICAL) for the equipment slots row, with `ResizeMode: Container` so slot spacing scales
- Notes that 2D character preview should be a separate `UIRenderTexture` to avoid re-rendering on every equipment change
- Flags that iPad Pro 12.9 wide aspect ratio means `Fit Width` will leave big top/bottom bars — recommend `Show All` with extra "letterbox" art layer for the iPad case
- Asks whether the project is mini-game first or native first (different safe-area behaviors)
- Does NOT produce full component code — defers TS to `cocos-ts-specialist`

---

## Protocol Compliance

- [ ] Stays within declared domain (UITransform / Layout / Widget / Mask / RichText / Sprite / Label / ScrollView / Canvas / multi-resolution / input)
- [ ] Redirects TypeScript-side non-UI logic to cocos-ts-specialist
- [ ] Redirects UI Material / Effect work to cocos-shader-specialist
- [ ] Redirects high-level rendering / asset pipeline architecture to cocos-specialist
- [ ] Always uses `UITransform` (not deprecated `Node.size` / `setContentSize`) in 3.x examples
- [ ] Always treats `Canvas` + `Widget` as the screen-adaptation primitive, not fixed `setPosition`
- [ ] Always considers safe area on iOS / WeChat / ByteDance mini-game targets
- [ ] Flags Cocos Creator version-gated UI features (`safeAreaInsets` stable in 3.8+, `UISkew` 3.8.6+, 2D Assembler refactor 3.7.x) and confirms version before suggesting them

---

## Coverage Notes
- UI batching failure (Case 3) is the single most common UI performance bug — verifies the agent catches it and gives a concrete fix path
- Mini-game safe-area (Case 4) ensures the agent handles the platform-specific edge cases (WeChat safe area not matching iOS home indicator)
- Multi-resolution context (Case 5) verifies the agent applies Canvas policy + Widget + Layout primitives correctly and stays within its lane (UI structure, not full TS implementation)
