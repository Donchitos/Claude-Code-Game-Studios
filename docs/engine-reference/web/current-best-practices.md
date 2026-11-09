# Web — Current Best Practices

Last verified: 2026-10-29 | Engine: Web (Vite 8.3, TypeScript 7.0)

What every browser game must get right, whatever library it uses. The model
knows most of these APIs; it gets the rules around them wrong. Library pages:
`threejs.md`, `phaser.md`, `pixijs.md`.

**Grades:** **[S]** sourced — read in the named primary source on the date
above; **[M]** measured on a real machine; **[J]** judgment.

## Sharp canvas on every screen

- The canvas's drawing buffer is its CSS size times `devicePixelRatio`, or it
  is blurry on high-density screens. Set `canvas.width`/`height` from the CSS
  size × `devicePixelRatio`, and scale drawing by the same factor. **[S]** (1)
- Re-measure on resize with a `ResizeObserver` on the canvas.
  `devicePixelContentBoxSize` gives exact device pixels in Chrome, Edge and
  Firefox, but **not in Safari**: fall back to `contentBoxSize` ×
  `devicePixelRatio`. **[S]** (2)
- A pixel-art game renders to a small fixed buffer and scales it up with
  `image-rendering: pixelated` on the canvas (and `imageSmoothingEnabled =
  false` when drawing it). **[J]**

## Sound starts after a gesture

- An `AudioContext` created before the user interacts starts `"suspended"`;
  call `resume()` from an input handler. **[S]** (3, 4)
- Only these events grant activation: `keydown` (not Esc), `mousedown`,
  `pointerdown` **from a mouse only**, `pointerup` from touch or pen, and
  `touchend`. A touch `pointerdown` does **not** — unlocking audio there
  fails on phones. `mousemove` never does. **[S]** (5)
- So unlock in `pointerup`, `click` or `keydown`, once, and show a "tap to
  start" screen so the first input has somewhere to go. **[J]**

## Touch, mouse and pen

- `touch-action: none` on the canvas stops the browser panning and zooming,
  so the game gets the pointer events. **[S]** (6)
- Pointer Events cover mouse, touch and pen in one model; use them instead of
  separate mouse and touch handlers. `setPointerCapture()` keeps a drag's
  events on the element after the pointer leaves it. **[S]** (7, 8)

## Keyboard

- `KeyboardEvent.code` is the physical key (`KeyW` is the same key on AZERTY's
  Z), `key` is the character produced. Movement reads `code`; text entry and
  shown key names read `key`. **[S]** (9)

## Fullscreen and pointer lock

- `requestFullscreen()` needs a user gesture (transient activation) and
  returns a Promise. **[S]** (10)
- **iPhone Safari cannot make a canvas fullscreen**: the API is on iPad only,
  with an overlay button that cannot be hidden and a swipe down that exits.
  Design the phone layout to fit the visible viewport instead. **[S]** (11)
- `requestPointerLock()` needs a user gesture. Returning a Promise is a
  proposed spec change that not every browser implements: listen for
  `pointerlockchange` and `pointerlockerror`. `{ unadjustedMovement: true }`
  (raw mouse input) works in Chrome and Edge 88+ (not on Linux), Firefox 152+
  and Safari 18.4+. **[S]** (12, 11)

## Time and the hidden tab

- `requestAnimationFrame` pauses in background tabs and hidden iframes; its
  callback gets a `DOMHighResTimeStamp`. **[S]** (13)
- The first frame after a hidden period has a huge delta. Clamp the delta (or
  run a fixed step with a capped catch-up) and pause on `visibilitychange`
  (`document.visibilityState === 'hidden'`). **[S]** for the event (14);
  **[J]** for the clamp.

## Gamepads

- `navigator.getGamepads()` returns an empty list until the user presses a
  button on the pad; listen for `gamepadconnected` and poll the pads each
  frame. **[S]** (15)

## Threads and shared memory

- `SharedArrayBuffer` (threaded WebAssembly, some physics and audio worklets)
  needs a secure, cross-origin-isolated page: `Cross-Origin-Opener-Policy:
  same-origin` and `Cross-Origin-Embedder-Policy: require-corp` (or
  `credentialless`). Check `window.crossOriginIsolated`. **[S]** (16, 17)
- itch.io has an opt-in "SharedArrayBuffer support" checkbox (Embed Options,
  Frame Options). With it on, iframes inside the game's itch.io page (such as
  YouTube videos in comments) do not load. **[S]** (18) — an itch.io
  announcement, not its HTML5 docs.

## WebGPU

- `navigator.gpu` exists only in secure contexts. Shipped by default in
  Chrome and Edge 113+ (Windows, macOS, ChromeOS), Chrome Android 121+,
  Firefox 141+ on Windows, and Safari 26; Linux is still in progress. Keep a
  WebGL path. **[S]** (19, 20)
- Not verified: WebGPU in headless Chrome. A check that needs it reports NOT
  ASSESSED.

## Opening a build from disk (`file://`)

- A page opened from `file://` runs classic and inline module scripts, but
  Chrome refuses a module script loaded from a file and `fetch()` of a local
  file. **[M]** (Chrome, 2026-10-29) MDN: CORS needs `http`/`https`, and
  browsers give local files an opaque origin. **[S]** (21)
- So Vite's normal build (one module script file) does not run from disk; the
  single-file build (`vite-plugin-singlefile`, everything inlined) does. Checks
  open that one. Assets must be imported in the code so they are inlined: the
  plugin does not inline the `public/` folder. **[S]** (22)
- `base: './'` in `vite.config.ts` makes the folder build work from any path,
  itch.io included. **[J]**

## Sources

1. https://developer.mozilla.org/en-US/docs/Web/API/Window/devicePixelRatio ("Correcting resolution in a canvas")
2. https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry/devicePixelContentBoxSize ; compat: github.com/mdn/browser-compat-data `api/ResizeObserverEntry.json`
3. https://developer.chrome.com/blog/autoplay (Web Audio note)
4. https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Autoplay
5. https://html.spec.whatwg.org/multipage/interaction.html (activation triggering input event)
6. https://developer.mozilla.org/en-US/docs/Web/CSS/touch-action
7. https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events
8. https://developer.mozilla.org/en-US/docs/Web/API/Element/setPointerCapture
9. https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code
10. https://developer.mozilla.org/en-US/docs/Web/API/Element/requestFullscreen
11. github.com/mdn/browser-compat-data `api/Element.json`
12. https://developer.mozilla.org/en-US/docs/Web/API/Element/requestPointerLock
13. https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame
14. https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event
15. https://w3c.github.io/gamepad/ ; https://developer.mozilla.org/en-US/docs/Web/API/Gamepad_API
16. https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer
17. https://developer.mozilla.org/en-US/docs/Web/API/Window/crossOriginIsolated
18. https://itch.io/t/2025776/experimental-sharedarraybuffer-support
19. https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API
20. https://web.dev/blog/webgpu-supported-major-browsers
21. https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS/Errors/CORSRequestNotHttp
22. https://github.com/richardtallent/vite-plugin-singlefile (README, Caveats)
