# Cocos Creator Animation — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since 3.8.0

### 3.8.0+ Changes
- **Procedural Animation system added** — programmatic animation clips via `AnimationClip` API
- **AnimationClip format extended** — backward-compatible; old clips still load
- **State machine improvements** — `AnimationController` (state machine) enhanced with sub-state machines and transitions
- **Animation retargeting** — retarget clips between skeletons with different proportions

### 3.8.6 Changes
- **Spine 4.2 support** — alongside Spine 3.8 (choose in Project Settings)
- **Spine physics** — Spine 4.2 physics constraints supported
- **`Tween.toString()`** — added for easier debugging

## Current API Patterns

### AnimationClip (legacy timeline)
```typescript
import { Animation, AnimationClip, animation } from 'cc';

@ccclass('AnimExample')
export class AnimExample extends Component {
    @property({ type: AnimationClip })
    public clip: AnimationClip | null = null;

    onLoad() {
        const anim = this.getComponent(Animation)!;
        anim.defaultClip = this.clip;
        anim.play();
    }
}
```

### AnimationController (state machine)
```typescript
const anim = this.getComponent(Animation)!;
anim.play('idle');
anim.crossFade('run', 0.2);  // 200ms blend
anim.setValue('speed', 1.5);  // Set animator parameter
```

### Tween (programmatic, code-only)
```typescript
import { tween, Vec3 } from 'cc';

tween(this.node)
    .to(0.5, { position: new Vec3(0, 100, 0) }, { easing: 'quadOut' })
    .call(() => console.log('done'))
    .start();
```

> **3.0 change**: `tween(node).to(1, { x: 100 })` is invalid (no top-level `x`).
> Use `position: new Vec3(100, 0, 0)`.

### Spine (3.8.6)
```typescript
import { sp } from 'cc';
const skeleton = this.getComponent(sp.Skeleton)!;
skeleton.setAnimation(0, 'attack', false);
skeleton.addAnimation(0, 'idle', true, 0.2);
```

## Common Mistakes
- Using `cc.AnimationClip.createWithSpriteFrames()` (removed in 3.0) — use editor
- Tween target `x` / `y` / `z` directly (removed in 3.0) — use `position: v3(...)`
- Loading `AnimationClip` via `cc.loader.loadRes()` (removed) — use `resources.load()` or bundles
- Forgetting `skeleton.setToSetupPose()` before `setAnimation()` — old pose bleeds through
- Spine 4.2 features (physics, JitterEffect removed) without checking version compatibility
