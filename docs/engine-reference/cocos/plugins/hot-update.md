# Cocos Creator — Hot Update Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

## Why This File Exists

Cocos Creator has a **first-party hot update flow** (`hot-update.ts`)
that is unique to the engine — neither Unity, Unreal, nor Godot ships an
equivalent out of the box. The flow is `assetManager` + a remote manifest
(JSON) + a content-addressed asset folder. This file documents the
correct 3.8.6 pattern.

## When to Use

- Mobile games where app store review time is too slow for balance /
  content patches
- Mini-game platforms (WeChat / ByteDance / Alipay) where release cycle
  is shorter and iteration is expected
- Live ops: seasonal content, events, limited-time modes

**Do NOT use hot update to bypass app store rules.** Apple and Google
both have policies against loading executable code at runtime. Hot
update in Cocos updates **assets** (textures, prefabs, scripts as data)
— not the engine binary or new API surface. Mini-game platforms have
their own rules; check them.

## Components

| Component | Purpose |
|-----------|---------|
| **Remote server** (e.g., CDN) | Hosts `project.manifest` + versioned asset folders |
| **`project.manifest`** | JSON: version, asset URL pattern, search paths, version list |
| **`version.manifest`** | JSON: latest version + update URL (small, polled frequently) |
| **Local storage** (`jsb.fileUtils`) | Cached assets + manifest on device |
| **`AssetsManager`** (`jsb.AssetsManager`) | The engine API that does the diff + download |

## Flow (3.8.6)

1. App starts → load local `project.manifest`
2. App calls `AssetsManager.checkUpdate()` → fetches remote
   `version.manifest`
3. If newer version available → download `project.manifest` + diff assets
4. On success → call `AssetsManager.applyUpdate()` — replaces search
   path to point to the new assets
5. App restart (or hot-reload if engine supports it) loads the new assets

## Minimal Implementation Sketch

```typescript
import { AssetsManager, native, jsb } from 'cc';

const storagePath = jsb.fileUtils.getWritablePath() + 'hot-update/';
const packageUrl  = 'https://cdn.example.com/your-game/'; // base

const manager = new AssetsManager('', storagePath, packageUrl);
manager.setVersionCompareHandle((a, b) => {
    // Compare semantic versions; default uses string compare which is wrong
    const av = a.split('.').map(Number);
    const bv = b.split('.').map(Number);
    for (let i = 0; i < 3; i++) {
        if (av[i] !== bv[i]) return av[i] - bv[i];
    }
    return 0;
});

manager.checkUpdate((err, isUpdated) => {
    if (err) return console.error(err);
    if (!isUpdated) return console.log('up to date');
    manager.update((err2) => {
        if (err2) return console.error(err2);
        manager.retry();        // continues interrupted download
        // Optional: restart the engine to apply
        // cc.game.restart();
    });
});
```

## Manifest Format

```json
{
    "packageUrl": "https://cdn.example.com/your-game/remote-assets/",
    "remoteVersionUrl": "https://cdn.example.com/your-game/version.manifest",
    "remoteManifestUrl": "https://cdn.example.com/your-game/project.manifest",
    "version": "1.2.3",
    "searchPaths": ["hot-update/"],
    "assets": {
        "assets/scenes/level1": { "md5": "...", "size": 1234, "compressed": true },
        "assets/textures/hero":   { "md5": "...", "size": 5678, "compressed": true }
    }
}
```

## 3.8.6-Specific Notes

- `AssetsManager` is exposed via the `native` module — does **not** work
  in web builds. For web hot update, use the `assetsManager` API +
  `CacheStorage` (different code path; see engine docs).
- The `compressed` flag enables zlib compression in the manifest
  (3.8.6+ default). Old projects with `compressed: false` still work
  but have larger manifests.
- `setMaxConcurrentTask(4)` controls parallel download count — 4 is
  a good default for mobile networks; 8 for WiFi.

## Common Mistakes
- Comparing versions as strings — `"1.10.0" < "1.9.0"` is true; use
  the version compare handle shown above
- Storing the manifest in `assets/` — it gets bundled with the build;
  store it in the writable path
- Hot-updating `js` / `ts` source code on iOS / Android — Apple
  App Store policy violation. Update asset data, not executable
  logic, on these platforms. (Mini-game platforms have their own
  rules and are more permissive.)
- Skipping the `setMaxConcurrentTask` call — defaults to 32; on
  cellular networks this saturates the radio and causes timeouts
- Forgetting `manager.retry()` on transient network failures — first
  error kills the update
- Not hashing the manifest itself — a corrupted manifest downloads
  repeatedly with no progress

## Verified Sources
- Hot update tutorial: <https://docs.cocos.com/creator/3.8/manual/en/advanced-topics/hot-update.html>
- `AssetsManager` API: <https://docs.cocos.com/creator/3.8/api/en/classes/jsb.AssetsManager.html>
