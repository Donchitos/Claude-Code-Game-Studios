# Cocos Creator — Spine Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

## Why This File Exists

Spine support in Cocos Creator is a **bundled plugin** (selectable in
Feature Cropping), not an engine module. It was significantly upgraded in
3.8.6 to support both Spine 3.8 and Spine 4.2 side-by-side. The
`modules/animation.md` file covers general animation patterns; this file
covers Spine-specific setup, migration, and 3.8.6-only features.

## Version Selection

| Spine Version | Status in 3.8.6 | Key Capabilities |
|---------------|-----------------|------------------|
| **Spine 3.8** | Legacy (default in older projects) | Standard skeleton animation, no physics |
| **Spine 4.2** | Modern (default in new 3.8.6 projects) | Physics constraints, removed `JitterEffect` / `SwirlEffect` runtime support |

Switch in `Project Settings → Feature Cropping → Spine`. **Restart the
editor** after switching — engine recompiles the Spine runtime.

> **Mini-game engine separation plugin does not currently support Spine 4.2.**
> If the project ships to a mini-game platform with the engine separation
> plugin enabled, stay on Spine 3.8 for now, or disable the separation
> plugin (sacrifices ~200KB of main package size).

## Importing Assets

1. Export from Spine editor in the target version (3.8 or 4.2)
2. Drop `.json` / `.skel` / `.atlas` / `.png` files into `assets/spine/`
3. Cocos auto-detects and creates a `SkeletonData` asset
4. Drag `SkeletonData` onto a `sp.Skeleton` component on a scene node

```typescript
import { sp } from 'cc';

const skeleton = this.node.getComponent(sp.Skeleton)!;
skeleton.setAnimation(0, 'attack', false);   // trackIndex, animName, loop
skeleton.addAnimation(0, 'idle', true, 0.2); // 0.2s delay
```

## 3.8.6 Additions

### Spine 4.2 Physics Constraints
Spine 4.2 introduces physics constraints (collision, hinge). Cocos Creator
3.8.6 supports these at runtime — make sure assets are re-exported from
Spine 4.2 editor.

### Shared Texture Atlas
3.8.6 allows multiple `SkeletonData` to share a single texture atlas,
saving memory and draw call overhead. Set in the `SkeletonData` import
inspector under "Atlas Sharing".

### Removed Effects
`JitterEffect` and `SwirlEffect` were removed in Spine 4.2. If a 3.8
project used these, the runtime will log a warning and the effect will
be silently dropped on Spine 4.2.

## Migration (3.8 → 4.2)

1. Open Spine editor, re-export assets in 4.2 format
2. Replace files in `assets/spine/` (keep the original 3.8 files in a
   `legacy/` subfolder until verified)
3. Switch Spine version in `Feature Cropping`
4. Restart editor — engine recompiles
5. Run the project and check console for `JitterEffect` /
   `SwirlEffect` warnings
6. Update any custom shaders that referenced removed effect properties

## Common Mistakes
- Skipping editor restart after version switch → runtime still uses old
  Spine code, but assets are 4.2 format → silent animation break
- Mixing 3.8 and 4.2 assets in the same bundle → version mismatch
  errors at load time
- Calling `setToSetupPose()` after `setAnimation()` — should be **before**
- Forgetting `skeleton.invalidAnimationCache()` after swapping
  `SkeletonData` at runtime — old animation events still fire

## API Quick Reference (Stable)

| Method | Purpose |
|--------|---------|
| `skeleton.setAnimation(track, name, loop)` | Play animation on track |
| `skeleton.addAnimation(track, name, loop, delay)` | Queue animation |
| `skeleton.setToSetupPose()` | Reset skeleton to bind pose |
| `skeleton.invalidAnimationCache()` | Clear cached animation state |
| `skeleton.setSkin(name)` | Swap skin at runtime |
| `skeleton.setAttachment(slot, name)` | Swap single attachment |

Full Spine runtime API: <https://en.spine.api.com/spine-api-reference>
