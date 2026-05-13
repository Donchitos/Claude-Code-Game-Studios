# Cocos Creator Input — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — Input module restructured
- `cc.eventManager` → per-node event subscription (`node.on(...)`)
- `cc.SystemEvent` → `SystemEvent` singleton via `input` global
- Multi-touch disabled by default; enable via `macro.ENABLE_MULTI_TOUCH = true`

### v3.5 — Gamepad support added
- `input.on(Input.EventType.CONTROLLERButtonDown, ...)` for native gamepad events
- Gamepad polling via `input.getController(deviceId)`

### v3.8 — Accelerometer / Compass additions
- `input.setAccelerometerEnabled(true)` and `input.on(Input.EventType.DEVICEMOTION, ...)`

## Current API Patterns

### Touch events (mobile / mini-game / web)
```typescript
import { _decorator, Component, Node, EventTouch, SystemEventType } from 'cc';
const { ccclass } = _decorator;

@ccclass('TouchHandler')
export class TouchHandler extends Component {
    onLoad() {
        this.node.on(Node.EventType.TOUCH_START, this._onTouchStart, this);
        this.node.on(Node.EventType.TOUCH_MOVE, this._onTouchMove, this);
        this.node.on(Node.EventType.TOUCH_END, this._onTouchEnd, this);
        this.node.on(Node.EventType.TOUCH_CANCEL, this._onTouchCancel, this);
    }

    onDestroy() {
        this.node.off(Node.EventType.TOUCH_START, this._onTouchStart, this);
        // ... others
    }

    private _onTouchStart(event: EventTouch) {
        const uiPos = event.getUILocation();    // UI space
        const worldPos = event.getLocation();   // screen space
        const touchId = event.getID();
    }
}
```

### Mouse events (web / desktop)
```typescript
import { EventMouse } from 'cc';

this.node.on(Node.EventType.MOUSE_DOWN, (event: EventMouse) => {
    if (event.getButton() === EventMouse.BUTTON_LEFT) { /* ... */ }
    if (event.getButton() === EventMouse.BUTTON_RIGHT) { /* ... */ }
});

this.node.on(Node.EventType.MOUSE_MOVE, (event: EventMouse) => {
    const delta = event.getDelta();  // Vec2 movement since last frame
});

this.node.on(Node.EventType.MOUSE_WHEEL, (event: EventMouse) => {
    const scroll = event.getScrollY();  // Vertical scroll amount
});
```

### Global input via `input` singleton
```typescript
import { input, Input, EventKeyboard, KeyCode } from 'cc';

input.on(Input.EventType.KEY_DOWN, (event: EventKeyboard) => {
    if (event.keyCode === KeyCode.SPACE) {
        // jump
    }
});

input.on(Input.EventType.KEY_UP, (event: EventKeyboard) => {
    // ...
});
```

### Gamepad (native / web)
```typescript
import { input, Input, EventController } from 'cc';

input.on(Input.EventType.CONTROLLERButtonDown, (event: EventController) => {
    const deviceId = event.deviceId;
    const button = event.button;
});
```

### Multi-touch
```typescript
import { macro } from 'cc';
macro.ENABLE_MULTI_TOUCH = true;  // Enable in onLoad of first scene
```

## Platform Quirks

| Platform | Touch | Mouse | Gamepad | Multi-touch | Keyboard |
|----------|-------|-------|---------|-------------|----------|
| Web (Desktop) | ✓ | ✓ | Partial | ✓ | ✓ |
| Web (Mobile) | ✓ | ✗ | ✗ | ✓ | ✗ |
| WeChat Mini Game | ✓ | ✗ | ✗ | Variable | ✗ |
| Native iOS | ✓ | ✗ | ✓ (MFi) | ✓ | ✓ (with keyboard accessory) |
| Native Android | ✓ | ✗ | ✓ | ✓ | Variable |

## Common Mistakes
- Subscribing in `update()` — creates a new listener every frame (memory leak)
- Using `cc.eventManager` (removed in 3.0) — use `node.on()` or `input.on()`
- Forgetting `target` argument — `this` binding breaks in callback
- Touch events on a node without `UITransform` — silently fail (no hit area)
- Not disabling multi-touch when single-touch game — accidental multi-touch input
- Using `cc.sys.platform` checks scattered through game code — centralize in a platform layer
- Mixing `getLocation()` (screen) and `getUILocation()` (UI space) — coordinate mismatch
