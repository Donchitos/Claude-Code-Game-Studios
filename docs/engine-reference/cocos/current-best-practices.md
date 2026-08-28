# Cocos Creator — Current Best Practices

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

Practices that differ from older Cocos Creator (v2.x) and v3.x early patterns.
For a complete API lookup, see `deprecated-apis.md` and `breaking-changes.md`.

## Project Structure (v3.8)

```
assets/
├── scenes/           # .scene files — main and per-feature scenes
├── scripts/          # .ts files — TypeScript source
│   ├── components/   # @ccclass Components (UI, gameplay, etc.)
│   ├── data/         # Data classes, configs, constants
│   ├── managers/     # Singleton-like manager components
│   └── utils/        # Pure utility functions, no Component deps
├── prefabs/          # .prefab files — reusable UI / entity prefabs
├── textures/         # PNG / JPG / WebP source textures
├── materials/        # .material files — Material assets
├── effects/          # .effect files — custom shaders
├── animations/       # .anim files — AnimationClips
├── audio/            # .mp3 / .ogg / .wav audio clips
├── resources/        # Loaded via resources.load() — KEEP SMALL
└── bundles/          # Each subfolder = one Asset Bundle
    ├── ui-bundle/
    ├── level-1/
    └── characters/
```

### Folder Discipline
- `assets/resources/` is special — only put small config files here (`JsonAsset`, `TextAsset`). Large assets belong in bundles.
- `assets/bundles/<name>/` — each subfolder becomes its own bundle when configured in the build panel
- Keep scripts out of `resources/` — they're always loaded; use bundles for on-demand code

## TypeScript Component Pattern (Modern)

```typescript
import { _decorator, Component, Node, Prefab, instantiate } from 'cc';
const { ccclass, property } = _decorator;

enum EnemyType { Small, Medium, Boss }

@ccclass('EnemySpawner')
export class EnemySpawner extends Component {
    @property({ type: Node, tooltip: "Parent for spawned enemies" })
    public spawnRoot: Node | null = null;

    @property({ type: [Prefab], tooltip: "Enemy prefabs indexed by EnemyType" })
    public enemyPrefabs: Prefab[] = [];

    @property({ type: CCInteger, range: [1, 50, 1] })
    public maxConcurrent: number = 10;

    @property({ type: EnemyData })
    public config: EnemyData | null = null;

    private _activeEnemies: Node[] = [];
    private _spawnTimer: number = 0;

    onLoad() {
        if (!this.spawnRoot) this.spawnRoot = this.node;
    }

    update(dt: number) {
        this._spawnTimer -= dt;
        if (this._spawnTimer <= 0 && this._activeEnemies.length < this.maxConcurrent) {
            this._spawnEnemy(EnemyType.Small);
            this._spawnTimer = 1.0;
        }
    }

    private _spawnEnemy(type: EnemyType): void {
        const prefab = this.enemyPrefabs[type];
        if (!prefab) return;
        const enemy = instantiate(prefab);
        this.spawnRoot!.addChild(enemy);
        this._activeEnemies.push(enemy);
    }
}
```

## Asset Loading — Async / Await Helper

Cocos Creator's API is callback-based. Wrap in Promises for clean async code:

```typescript
// assets/scripts/utils/load-async.ts
import { AssetManager, Asset, resources, JsonAsset } from 'cc';

export function loadBundle(name: string): Promise<AssetManager.Bundle> {
    return new Promise((resolve, reject) => {
        assetManager.loadBundle(name, (err, bundle) =>
            err ? reject(err) : resolve(bundle));
    });
}

export function loadAsync<T extends Asset>(
    bundle: AssetManager.Bundle,
    path: string,
    type: new () => T,
): Promise<T> {
    return new Promise((resolve, reject) => {
        bundle.load(path, type, (err, asset) =>
            err ? reject(err) : resolve(asset as T));
    });
}

export function loadResourceAsync<T extends Asset>(
    path: string,
    type: new () => T,
): Promise<T> {
    return new Promise((resolve, reject) => {
        resources.load(path, type, (err, asset) =>
            err ? reject(err) : resolve(asset as T));
    });
}

// Usage:
// const bundle = await loadBundle('ui-bundle');
// const prefab = await loadAsync(bundle, 'main-menu', Prefab);
```

> **Pattern**: Set up `load-async.ts` early in the project. Wrap every callback API once; reuse everywhere.

## Event Bus (Singleton)

For global events (player death, level complete, currency change):

```typescript
// assets/scripts/managers/event-bus.ts
import { EventTarget } from 'cc';

type EventMap = {
    'player:hit': (damage: number, source: Node | null) => void;
    'player:die': () => void;
    'level:complete': (levelId: number, stars: number) => void;
};

class EventBus {
    private _target = new EventTarget();

    on<K extends keyof EventMap>(event: K, cb: EventMap[K], target?: unknown): void {
        this._target.on(event as string, cb as any, target);
    }

    once<K extends keyof EventMap>(event: K, cb: EventMap[K], target?: unknown): void {
        this._target.once(event as string, cb as any, target);
    }

    off<K extends keyof EventMap>(event: K, cb: EventMap[K], target?: unknown): void {
        this._target.off(event as string, cb as any, target);
    }

    emit<K extends keyof EventMap>(event: K, ...args: Parameters<EventMap[K]>): void {
        this._target.emit(event as string, ...args);
    }
}

export const eventBus = new EventBus();
```

> **Pattern**: Always document every global event in CLAUDE.md so reviewers can spot the dependencies.

## Object Pooling

```typescript
// assets/scripts/utils/object-pool.ts
import { Node, Prefab, instantiate } from 'cc';

export class ObjectPool {
    private _pool: Node[] = [];
    private _prefab: Prefab;
    private _parent: Node;

    constructor(prefab: Prefab, parent: Node, preload: number = 0) {
        this._prefab = prefab;
        this._parent = parent;
        for (let i = 0; i < preload; i++) {
            const node = instantiate(prefab);
            node.active = false;
            node.parent = this._parent;
            this._pool.push(node);
        }
    }

    get(): Node {
        let node = this._pool.pop();
        if (!node) {
            node = instantiate(this._prefab);
            node.parent = this._parent;
        }
        node.active = true;
        return node;
    }

    release(node: Node): void {
        node.active = false;
        this._pool.push(node);
    }
}
```

> **Pattern**: Pool every Prefab instantiated > 5 times per session (projectiles, enemies, VFX, popups).

## Multi-Platform Configuration

Cocos Creator 3.8.6+ supports per-platform feature-cropping presets:

1. Open **Project Settings → Feature Cropping** (功能裁剪)
2. Create multiple configurations: `web-cropping`, `minigame-cropping`, `native-cropping`
3. In the **Build** panel, select which preset to use for each platform
4. Disable modules unused per target:
   - **Mini-game**: disable 3D physics, particles-heavy modules,某些网络模块
   - **Web 2D**: disable 3D rendering, CharacterController, NavMesh
   - **Native 3D**: enable everything; native builds have no JS size limit
5. Enable "Compress engine internal properties" for ~160KB savings (3.8.6+)

## Mini-Game Specific Considerations

Mini-game platforms (WeChat / ByteDance / Alipay / Baidu / Honor) have unique constraints:

- **Bundle size limit** — main package ≤ 4MB (WeChat), 4MB (ByteDance); use sub-packages
- **Engine separation plugin** — `engine.js` is loaded from a CDN, not bundled; reduces main package size
- **No synchronous file access** — all I/O is async; affects save / load patterns
- **No WebGL 2 guaranteed** — some mini-game platforms default to WebGL 1; check `cc.minigame.webgl1`
- **Limited WebAPI** — `localStorage` works but size limits vary; use `wx.setStorageSync` for larger data
- **Touch input only** — no mouse / keyboard on most platforms; design UI for touch
- **Performance budget tighter** — target 30 FPS on low-end devices, profile aggressively

## Spine Version Selection (3.8.6+)

Cocos Creator 3.8.6 supports both Spine 3.8 and Spine 4.2:
- **Spine 3.8** — legacy, default in older projects
- **Spine 4.2** — modern, adds physics constraints, removes JitterEffect / SwirlEffect

Migration:
1. Open Spine editor, re-export assets in 4.2 format
2. Replace files in `assets/` directory
3. Switch Spine version in **Feature Cropping** panel
4. Restart editor (engine recompiles)
5. Note: Mini-game engine separation plugin does not currently support Spine 4.2

## Box2D Variant Selection (3.8.6+)

For 2D physics, three variants now exist:

| Variant | Best For | Notes |
|---------|---------|-------|
| **TS** (Box2D.js) | Cross-platform consistency, simple games | Slowest on native (no JIT on iOS) |
| **WASM** (Box2D-wasm) | Native perf without native code | Faster than TS, requires WASM support |
| **JSB** (C++ native, new in 3.8.6) | Native iOS / Android 2D physics games | Best perf on iOS (no JIT penalty); requires native build |

Choose in **Project Settings → Physics**.

## Performance Profiling Tools

| Tool | Platform | Use For |
|------|----------|---------|
| **Chrome DevTools** | Web | CPU profiling, memory, GPU profiling via Performance tab |
| **profiler.showStats()** | All | On-screen FPS / draw call / batch info |
| **Xcode Instruments** | iOS native | GPU capture, allocation tracking |
| **Android Studio Profiler** | Android native | CPU, memory, GPU profiling |
| **WeChat DevTools** | WeChat mini game | Mini-game-specific profiling, memory limits |
| **RenderDoc** | All OpenGL/Vulkan | Frame capture, draw call inspection |

## Testing

Cocos Creator has no first-party test framework. Recommended:

- **Unit tests**: Use `vitest` or `jest` against pure TypeScript logic (no Component dependencies)
- **Component tests**: Spin up a minimal scene in headless mode; instantiate component; assert state
- **Integration tests**: Use `cc.AssetManager.loadBundle()` to test bundle loading sequences
- **Smoke tests**: Automated build + launch + first-scene-render check in CI

> **Pattern**: Keep pure logic (no `cc.*` imports) in separate `*.ts` files so they can be unit-tested without the engine runtime.

## When in Doubt

1. Check `deprecated-apis.md` — most "wrong" suggestions are deprecated calls
2. Check `breaking-changes.md` — verify the API exists in v3.8.x
3. Check `modules/*.md` for subsystem-specific notes
4. Use WebSearch with site filter: `site:docs.cocos.com creator 3.8 [your question]`
5. Verify with the forum (https://forum.cocos.org/) for recent issues
