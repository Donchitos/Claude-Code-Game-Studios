---
paths:
  - "src/ui/**"
---

# UI Code Rules

- UI must NEVER own or directly modify game state — display only, use commands/events to request changes
- All UI text must go through the localization system — no hardcoded user-facing strings
- Support both keyboard/mouse AND gamepad input for all interactive elements
- All animations must be skippable and respect user motion/accessibility preferences
- UI sounds trigger through the audio event system, not directly
- UI must never block the game thread
- Scalable text and colorblind modes are mandatory, not optional
- Test all screens at minimum and maximum supported resolutions

## Web (PixiJS / Three.js)

Web projects have a UI option no other engine has — the DOM — and it is almost
always the right choice.

### DOM vs canvas
- **Default to the DOM.** It provides accessibility, text layout, focus
  management, and internationalization for free. Use canvas UI only when the
  element must live inside the rendered scene (world-anchored HUD, damage
  numbers, shader-driven elements)
- Canvas content is **completely invisible to screen readers**. Any information
  conveyed only in-canvas requires a DOM equivalent or an `aria-live` region

### Layout
- Use `100dvh`, never `100vh` — mobile browser chrome makes `vh` wrong and causes
  layout shift as the address bar hides
- Respect `env(safe-area-inset-*)` for notches and home indicators
- `pointer-events: none` on the UI overlay container, re-enabled on actual
  controls, so clicks reach the canvas
- Minimum 44×44px touch targets; inputs need ≥16px font or iOS auto-zooms

### Input
- Use **Pointer Events**, not separate mouse and touch handlers — one path covers
  mouse, touch, and pen
- Gamepad has no event API; poll `navigator.getGamepads()` in the game loop
- Clear held input state on `blur` and `visibilitychange`, or the player returns
  from a tab switch to a stuck movement key

### Performance
- Only animate `transform` and `opacity`. Animating layout properties forces
  reflow every frame, which surfaces as game stutter — layout and the game loop
  share a thread
- Never use `transition: all`
- Update HUD values on change (event-driven), never per frame — a per-frame
  `textContent` write is a per-frame layout invalidation
- Batch DOM reads and writes separately to avoid layout thrashing

See `docs/engine-reference/web/modules/ui.md` and `modules/input.md`.
