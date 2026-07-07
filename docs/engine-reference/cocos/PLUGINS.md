# Cocos Creator — Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

Cocos Creator's engine core ships with built-in modules (rendering, audio,
physics, UI). Optional plugins live alongside the engine and are either
selected at build time (Feature Cropping), or imported as extension packages
via the Cocos Dashboard / extension store. This directory documents the
plugins most projects touch.

## Bundled Plugins (selectable in Feature Cropping)

These ship with the engine and are enabled/disabled per platform preset
(`Project Settings → Feature Cropping → Presets`).

| Plugin | Reference | Notes |
|--------|-----------|-------|
| **Spine** (3.8 / 4.2) | [plugins/spine.md](plugins/spine.md) | 3.8.6 supports both Spine versions side-by-side. Choose in Feature Cropping. |
| **DragonBones** | [plugins/dragonbones.md](plugins/dragonbones.md) | Older runtime still maintained; lighter than Spine for 2D skeletal animation. |
| **TiledMap** | [plugins/tiled-map.md](plugins/tiled-map.md) | Built-in `TiledMap` component for Tiled (.tmx / .tsx) tile maps. Foundation for 2D pathfinding. |
| **Box2D** (TS / WASM / JSB) | [plugins/box2d.md](plugins/box2d.md) | Three runtime variants. Pick per platform in `Project Settings → Physics`. |
| **Particle System 2D** | (covered in `modules/rendering.md`) | CPU/GPU particles; not a separate plugin file. |
| **WebSocket** | (covered in `modules/networking.md`) | Native WebSocket; not separate. |

## Project-Side Plugins (extension packages)

These are not part of the engine binary; they are npm packages or Cocos
extension packages installed into the project.

| Plugin | Reference | Notes |
|--------|-----------|-------|
| **Hot Update** (`hot-update` / `@cocos/hot-update`) | [plugins/hot-update.md](plugins/hot-update.md) | Cocos's built-in asset hot-update flow (assetManager + manifest). Unique to Cocos. |

## When to Add a New Plugin File

Add a new `plugins/<name>.md` when:

1. The plugin has a non-trivial setup (not just `npm install`).
2. Multiple Cocos versions have meaningful plugin behavior changes.
3. The plugin has engine-specific patterns the agents must know (e.g.,
   Spine physics, Box2D JSB bridging).
4. The plugin is **bundled** (selectable in Feature Cropping) and changes
   which 3.8.6 features are available.

A short npm-style dependency that "just works" does not need its own file —
add it to the relevant module doc instead.

## How Agents Use These Files

`cocos-specialist` and the sub-specialists are instructed to:

1. Read this index when a task involves a bundled plugin
2. Read the relevant `plugins/<name>.md` for the plugin's 3.8.6 quirks
3. Cross-reference with the engine module file (e.g., Spine animation
   patterns live in `modules/animation.md`; Spine runtime setup lives here)
4. Use WebSearch to verify any plugin API newer than 3.8.6 — bundled
   plugins ship updates independently of the engine release schedule

## Version Awareness

Plugin features can be introduced in patch versions (3.8.4, 3.8.5, 3.8.6)
without a major engine bump. Always check the "Last verified" date on the
plugin file and the `VERSION.md` of the engine.
