# Web — UI Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** `100vh` is wrong on mobile (use `100dvh`); canvas content is invisible to assistive technology

---

## The Core Decision: DOM or Canvas

Web games have a UI option no other engine has — the DOM. It is almost always
the right choice.

| Use the DOM for | Use canvas for |
|-----------------|----------------|
| Menus, settings, dialogs, forms | HUD anchored to world objects |
| Anything with text input | Damage numbers, floating labels |
| Anything needing a screen reader | Elements needing shader effects |
| Native scrolling and focus | Elements inside the rendered scene |

**Default to the DOM.** It provides accessibility, text layout, input handling,
focus management, and internationalization for free. Rebuilding any of that in
canvas is expensive and usually worse. Reach for canvas UI only when the element
must live inside the rendered scene.

### Layering
```html
<div id="app">
  <canvas id="game"></canvas>
  <div id="ui"></div>   <!-- absolutely positioned over the canvas -->
</div>
```
```css
#ui { position: absolute; inset: 0; pointer-events: none; }
#ui > * { pointer-events: auto; }   /* re-enable on actual controls */
```
`pointer-events: none` on the container is what lets clicks pass through to the
canvas everywhere except on actual UI elements.

---

## Viewport and Layout

```css
#app {
  height: 100dvh;              /* NOT 100vh — mobile chrome makes vh wrong */
  padding: env(safe-area-inset-top) env(safe-area-inset-right)
           env(safe-area-inset-bottom) env(safe-area-inset-left);
}
```

`100vh` on mobile measures the viewport as if browser chrome were hidden, so the
bottom of the layout sits under the address bar and shifts as it hides. `dvh`
tracks the actual visible height.

Other requirements:
- Minimum 44×44 px touch targets — expand the hit area, not the visual
- Inputs need ≥16px font or iOS auto-zooms on focus
- Handle `orientationchange` and `resize` together, debounced

---

## Accessibility

Canvas content is **completely invisible** to screen readers. Any information
conveyed only in-canvas has no accessible equivalent unless you build one.

- Semantic elements first: `<button>`, `<a>`, `<label>`, `<dialog>`. ARIA only when nothing fits
- Icon-only buttons require `aria-label`
- Every interactive element keyboard-reachable with a visible `:focus-visible` ring
- Focus traps in modals per WAI-ARIA; restore focus to the trigger on close
- Minimum 4.5:1 contrast; never signal state by color alone
- Respect `prefers-reduced-motion` — offer a reduced variant, don't just disable
- Use an `aria-live` region for important state changes announced only visually

```html
<div aria-live="polite" class="sr-only" id="announcer"></div>
```

---

## Performance — UI Must Not Cost Frames

### Animate only compositor properties
```css
/* ✅ GPU-composited */
transition: transform 150ms ease, opacity 150ms ease;

/* ❌ Forces layout every frame */
transition: all 150ms ease;
```
Animating `width`, `height`, `top`, or `left` triggers reflow on every frame,
which shows up as game stutter — the layout and the game loop share a thread.

### Update on change, not per frame
```ts
// ❌ Per-frame layout invalidation
function render() { healthEl.textContent = String(hp); }

// ✅ Event-driven
events.on('healthChanged', ({ current }) => {
  healthEl.textContent = String(current);
});
```

### Avoid layout thrashing
Batch DOM reads, then writes. Interleaving them forces synchronous layout on
each read:

```ts
// ❌ read → write → read → write forces layout twice
// ✅ read all, then write all
const widths = els.map((el) => el.offsetWidth);
els.forEach((el, i) => { el.style.transform = `translateX(${widths[i]}px)`; });
```

---

## State

**UI never owns game state.** It reads and dispatches.

```ts
// ✅ UI dispatches intent; the game decides
button.addEventListener('click', () => events.emit('pauseRequested', {}));
```

All user-facing text goes through the localization system. See `../modules/`
and the project's localization setup — hardcoded strings block translation and
fail review.

---

## In-Canvas UI (PixiJS)

When UI genuinely belongs in the scene:

- `BitmapText` for anything updating per frame (scores, timers, damage numbers). Canvas `Text` re-rasterizes and re-uploads a texture on every content change
- Pixi v8 offers `SplitText` and tagged inline styling — prefer these to stacking multiple `Text` objects
- Provide a DOM equivalent for any information conveyed only in-canvas

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Layout shifts / cut off on mobile | `100vh` instead of `100dvh` |
| Clicks don't reach the canvas | Missing `pointer-events: none` on the UI container |
| Game stutters when the HUD updates | Per-frame `textContent` writes, or animating layout properties |
| Screen reader announces nothing | Information only in canvas |
| Content under the notch | Missing `env(safe-area-inset-*)` |
| iOS zooms on input focus | Input font smaller than 16px |

---

## Sources

- https://developer.mozilla.org/en-US/docs/Web/CSS/length#viewport-percentage_lengths
- https://www.w3.org/WAI/ARIA/apg/
- https://pixijs.com/
