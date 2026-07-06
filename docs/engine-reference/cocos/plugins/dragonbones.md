# Cocos Creator — DragonBones Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

## Why This File Exists

DragonBones is the older 2D skeletal animation runtime that ships with
Cocos Creator (the engine originated as a fork of Cocos2d-x, which
bundled DragonBones). It is lighter than Spine but has a smaller
feature set. Most new projects choose Spine; DragonBones remains
relevant for projects that already have DragonBones-authored assets or
need the smaller runtime.

The runtime is bundled with the engine; no installation is required.

## When to Use DragonBones vs Spine

| Choose | When |
|--------|------|
| **DragonBones** | Existing DragonBones assets to migrate; need the smallest runtime; team familiar with DragonBones editor |
| **Spine 3.8** | Existing Spine assets (legacy) |
| **Spine 4.2** | New projects; need physics constraints; need shared texture atlas |

Both runtimes can coexist in the same project; assets are tagged
separately and there is no runtime conflict.

## Importing Assets

1. Export from DragonBones editor as `.json` (skeleton) + `.png` (texture)
2. Drop into `assets/dragonbones/`
3. Cocos auto-imports; creates a `dragonBones.ArmatureDisplay` component
4. Add the component to a scene node, assign the skeleton asset

```typescript
import { dragonBones, ArmatureDisplay } from 'cc';

const arm = this.getComponent(ArmatureDisplay)!;
arm.playAnimation('walk', 0);   // name, loop (-1 = loop, 0 = once)
```

## API Quick Reference

| Method | Purpose |
|--------|---------|
| `arm.playAnimation(name, loop)` | Play animation |
| `arm.animation.gotoAndPlayByFrame(name, frame, loop)` | Frame-accurate playback |
| `arm.armature().getSlot(name)` | Access slot for runtime swap |
| `arm.armature().replaceTexture(newTexture)` | Hot-swap the texture atlas |
| `arm.buildArmature(name)` | Rebuild armature from new skeleton data |

## Performance Notes
- DragonBones is **significantly lighter** than Spine on mobile
  (smaller runtime, less per-frame CPU for simple skeletons)
- For complex skeletons with > 30 bones and many IK constraints,
  Spine outperforms DragonBones
- All DragonBones meshes are batched into a single draw call by default

## Common Mistakes
- Confusing `ArmatureDisplay` (Cocos component) with `Armature`
  (DragonBones runtime object) — `arm.armature()` returns the
  underlying runtime object
- Calling `playAnimation` with a name that doesn't exist — silently
  fails, no console error
- Hot-swapping textures without checking the texture size — different
  sizes cause vertex buffer re-uploads (perf hit)
- Mixing DragonBones and Spine assets on the same node — different
  components, not interchangeable

## Verified Sources
- DragonBones editor: <https://dragonbones.github.io/>
- Cocos DragonBones guide: <https://docs.cocos.com/creator/3.8/manual/en/editor/components/dragonbones.html>
