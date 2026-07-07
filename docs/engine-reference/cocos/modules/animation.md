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

> **3.8.6 plugin selection** — Cocos Creator supports **Spine 3.8** and
> **Spine 4.2** side-by-side. Switch in `Project Settings → Feature
> Cropping`. See [`../plugins/spine.md`](../plugins/spine.md) for the
> full migration / mini-game compatibility matrix.

## Skeletal Animation Component

For generic 3D skeletal animation (FBX / glTF skeletons), use the
`SkeletalAnimation` component:

```typescript
import { SkeletalAnimation } from 'cc';

const anim = this.getComponent(SkeletalAnimation)!;
anim.play('run');                    // play by name
anim.crossFade('walk', 0.25);        // blend
anim.pause();
anim.resume();
```

- `SkeletalAnimation` is a **3D node component** — requires the node to
  have a `MeshRenderer` + `SkinnedMeshRenderer` + skeleton
- The legacy `Animation` component still works for 2D / property tracks
  but is **not** the recommended path for 3D character animation

## Marionette (3.8 State Machine Replacement)

The old `AnimationController` was renamed to **Marionette** in 3.8.
Marionette is a node-graph state machine authored in the editor under
`Window → Animation → Marionette`. It supports:

- **States** — animation clips with entry / exit transitions
- **Transitions** — guard conditions, blend durations, interruption
  modes (None / Current / Next / Both)
- **Sub-state machines** — nested state groups
- **Blend trees (1D / 2D)** — parameter-driven blend between clips
- **Variables** — bool / int / float / trigger parameters exposed to
  scripts

```typescript
import { animation, AnimationGraph } from 'cc';

const graph = this.getComponent(AnimationGraph)!;

// Set a Marionette variable (declared in the graph asset)
graph.setValue('speed', 1.5);     // float
graph.setValue('isJumping', true); // bool
graph.setTrigger('attack');       // trigger
```

> **Anti-pattern** — Don't use `marionette` as a magic API. Always
> declare the variable / trigger in the Marionette graph first; setting
> an undeclared variable is a silent no-op.

## Programmatic Animation (Curves / Tracks)

For property tweens on non-3D nodes (UI, 2D), use the lower-level
`animation` module:

```typescript
import { Animation, AnimationClip, animation } from 'cc';

@ccclass('SpriteFader')
export class SpriteFader extends Component {
    @property({ type: Sprite })
    public sprite: Sprite | null = null;

    onLoad() {
        const clip = new AnimationClip('fade-in');
        const track = new animation.VectorTrack({
            binding: { component: this.sprite, property: 'color' },
            values: [new Color(255, 255, 255, 0), new Color(255, 255, 255, 255)],
            keys: [0.0, 0.5],
        });
        clip.addTrack(track);
        const anim = this.addComponent(Animation);
        anim.defaultClip = clip;
        anim.play();
    }
}
```

## Common Mistakes
- Using `cc.AnimationClip.createWithSpriteFrames()` (removed in 3.0) — use editor
- Tween target `x` / `y` / `z` directly (removed in 3.0) — use `position: v3(...)`
- Loading `AnimationClip` via `cc.loader.loadRes()` (removed) — use `resources.load()` or bundles
- Forgetting `skeleton.setToSetupPose()` before `setAnimation()` — old pose bleeds through
- Spine 4.2 features (physics, JitterEffect removed) without checking version compatibility
- Using `Animation` component on a 3D skinned mesh — use `SkeletalAnimation` instead
- Long-running `tween.start()` without `.stop()` — leaks on scene unload
