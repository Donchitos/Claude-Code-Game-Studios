# Cocos Creator UI System — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — UI rewrite
- **`cc.Widget` → `Widget`** (component), **`cc.Sprite` → `Sprite`** — all UI components refactored
- **`UITransform`** is now required on every UI node — defines bounding box for layout, mask, input
- **`Canvas`** simplified — single root Canvas, no nested Canvas trees
- **Screen adaptation**: `view.setDesignResolutionSize()` + `Fit Width` / `Fit Height` flags

### v3.5 — Layout improvements
- `Layout.ResizeMode.CHILDREN` — auto-resize children to fill container
- `Widget` supports both absolute (px) and relative (%) offsets

### v3.8 — RichText & Label additions
- **High Precision Text** — `Label.cacheMode` improvements, sharper text at small sizes
- **RichText** supports more inline tags (size, color, image, link, underline)

### v3.8.6 — UISkew component
- **`UISkew`** component added — rotational skew (different from shear/skew on 2D nodes)
- Node `.x` / `.y` / `.z` accessors restored (use `position` getter for perf-critical loops)

## Current API Patterns

### Canvas hierarchy
```
Canvas (root)
├── SafeAreaContainer (Widget: align all to safe area)
│   ├── HUD (top anchor)
│   ├── BottomNav (bottom anchor)
│   └── CenterPanel (center)
└── FullscreenOverlay (excluded from safe area)
```

### UITransform (mandatory)
```typescript
import { UITransform } from 'cc';

const ui = this.node.getComponent(UITransform)!;
ui.setContentSize(200, 100);
ui.setAnchorPoint(0.5, 0.5);
const width = ui.width;        // current width
const height = ui.height;
```

### Layout (parent auto-arranges children)
```typescript
import { Layout } from 'cc';

const layout = parent.getComponent(Layout)!;
layout.type = Layout.Type.HORIZONTAL;
layout.spacingX = 10;
layout.paddingLeft = 20;
layout.paddingRight = 20;
layout.resizeMode = Layout.ResizeMode.CONTAINER;  // resize parent
layout.horizontalDirection = Layout.HorizontalDirection.LEFT_TO_RIGHT;
```

### Widget (anchor-based responsive positioning)
```typescript
import { Widget } from 'cc';

const w = this.node.getComponent(Widget)!;
w.top = 50;        // 50px from top
w.left = 0;        // anchored left
w.right = 0;       // anchored right
w.bottom = 50;
w.alignMode = Widget.AlignMode.ON_WINDOW_RESIZE;  // when to re-align
```

### ScrollView with recycling (long lists)
- For lists > 20 items, use a recycling pattern (pool item Prefabs, swap data on scroll). See community packages or implement manually — instantiate only visible items + buffer.

### RichText (stylized text)
```typescript
import { RichText } from 'cc';

const rt = this.getComponent(RichText)!;
rt.string = '<color=#ff0000>Red</c> normal <b>bold</b> <img src="coin"/> +10';
```

Supported tags: `<color>`, `<size>`, `<b>`, `<i>`, `<u>`, `<img>`, `<a>`, `<outline>`, `<shadow>`

### Mask (clipping)
```typescript
import { Mask } from 'cc';

const mask = this.getComponent(Mask)!;
mask.type = Mask.Type.GRAPHICS_RECT;  // cheapest — rect clip
// mask.type = Mask.Type.GRAPHICS_ELLIPSE;
// mask.type = Mask.Type.GRAPHICS_STENCIL;  // expensive — breaks batching
```

### Touch input on UI nodes
```typescript
this.node.on(Node.EventType.TOUCH_START, (event: EventTouch) => {
    const uiPos = event.getUILocation();  // UI-space coordinates
}, this);
```

UI nodes auto-receive touch events when they have a `UITransform`, the
touch point is within the bounding box, and no higher-priority node
has captured the event.

## Screen Adaptation (Multi-Resolution)

### Canvas configuration
- **Design Resolution**: pick one and stick to it (e.g., 1280×720 landscape, 720×1280 portrait)
- **Fit Width**: scale to fill width, letterbox or crop height
- **Fit Height**: scale to fill height, letterbox or crop width
- **Both**: fill screen completely, may crop content (use SafeArea for safe content)

### Safe area (notch / cutouts)
```typescript
import { sys, view } from 'cc';

const safeArea = sys.getSafeAreaRect();  // Rect in design resolution
// Apply to top-level UI container via Widget or manual positioning
```

Mini-game platforms: `wx.getSystemInfoSync().safeArea` exposes the same
rect; wire it through a platform shim rather than scattering `wx` calls.

## Common Interactive Components

| Component | Purpose | Key API |
|-----------|---------|---------|
| `Button` | Tappable element | `node.on(Button.EventType.CLICK, ...)` |
| `Toggle` | On/Off state | `toggle.isChecked`, `toggle.checkEvents` |
| `Slider` | Continuous value | `slider.progress` (0..1) |
| `EditBox` | Text input | `editbox.string`, `EditBox.EventType.EDITING_DID_ENDED` |
| `ProgressBar` | Bar / radial fill | `bar.progress` (use `Sprite.Type.FILLED`) |
| `ScrollView` | Scrollable region | `scrollView.scrollToBottom()` etc. |
| `PageView` | Horizontal swipes | `pageView.setCurrentPageIndex(i)` |
| `ToggleContainer` | Group of toggles (radio) | `container.toggleItems` array |

## Common Mistakes
- Missing `UITransform` on a UI node — input and layout silently fail
- Using `setPosition()` instead of `Widget` for anchoring — breaks on resolution change
- Setting `active = false` on a node with a `Layout` — children reflow unexpectedly on enable
- Multiple `Canvas` components in one scene — only one is the "primary"; others are off-screen
- Mask with `GRAPHICS_STENCIL` everywhere — kills batching for the whole UI
- Hard-coded font sizes in pixels — breaks on high-DPI displays
- Touch handlers without `target` argument — `this` binding breaks on callback
- Subscribing to `TOUCH_*` on parent node without `UITransform` — no events fire
- Using `Label.cacheMode = NONE` for large text — slow per-frame rasterization
- Forgetting to `releaseAsset()` UI prefabs when their screen destroys — memory grows
- Adding `EditBox` programmatically — must be a prefab node + component
