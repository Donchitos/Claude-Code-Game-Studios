# Unity 6.3 — Addressables

**Last verified:** 2026-02-13
**Status:** Production-Ready
**Package:** `com.unity.addressables` (Package Manager)

---

## Overview

**Addressables** is Unity's advanced asset management system that replaces `Resources.Load()`
with async loading, remote content delivery, and better memory control.

**Use Addressables for:**
- Async asset loading (non-blocking)
- DLC and remote content
- Memory optimization (load/unload on demand)
- Asset dependency management
- Large projects with many assets

**DON'T use Addressables for:**
- Tiny projects (overhead not worth it)
- Assets needed immediately at startup (use direct references)

---

## Installation

### Install via Package Manager

1. `Window > Package Manager`
2. Unity Registry > Search "Addressables"
3. Install `Addressables`

---

## Core Concepts

### 1. **Addressable Assets**
- Assets marked as "Addressable" (assigned unique keys)
- Can be loaded by key at runtime

### 2. **Asset Groups**
- Organize assets (e.g., "UI", "Weapons", "Level1")
- Groups determine build settings (local vs remote)

### 3. **Async Loading**
- All loading is async (non-blocking)
- Returns `AsyncOperationHandle`

### 4. **Reference Counting**
- Addressables tracks asset usage
- Must manually release assets when done

---

## Setup

### 1. Mark Assets as Addressable

1. Select asset in Project window
2. Inspector > Check "Addressable"
3. Assign key (e.g., "Enemies/Goblin")

**OR via script:**
```csharp
#if UNITY_EDITOR
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;

AddressableAssetSettings.AddAssetEntry(guid, "MyAssetKey", "Default Local Group");
#endif
```

---

### 2. Create Groups

`Window > Asset Management > Addressables > Groups`

- **Default Local Group**: Bundled with build
- **Remote Group**: Hosted on server (CDN)

---

## Basic Loading

### Load Asset Async

```csharp
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

public class AssetLoader : MonoBehaviour {
    async void Start() {
        // ✅ Load asset asynchronously
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>("Enemies/Goblin");
        await handle.Task;

        if (handle.Status == AsyncOperationStatus.Succeeded) {
            GameObject prefab = handle.Result;
            Instantiate(prefab);
        } else {
            Debug.LogError("Failed to load asset");
        }

        // ⚠️ IMPORTANT: Release when done
        Addressables.Release(handle);
    }
}
```

---

### Load and Instantiate

```csharp
async void SpawnEnemy() {
    // ✅ Load and instantiate in one step
    AsyncOperationHandle<GameObject> handle = Addressables.InstantiateAsync("Enemies/Goblin");
    await handle.Task;

    GameObject enemy = handle.Result;
    // Use enemy...

    // ✅ Release when destroying
    Addressables.ReleaseInstance(enemy);
}
```

---

### Load Multiple Assets

```csharp
async void LoadAllWeapons() {
    // Load all assets with label "Weapons"
    AsyncOperationHandle<IList<GameObject>> handle = Addressables.LoadAssetsAsync<GameObject>("Weapons", null);
    await handle.Task;

    foreach (var weapon in handle.Result) {
        Debug.Log($"Loaded: {weapon.name}");
    }

    Addressables.Release(handle);
}
```

---

## Asset Labels (Tags)

### Assign Labels

1. `Window > Asset Management > Addressables > Groups`
2. Select asset > Inspector > Labels > Add label (e.g., "Level1", "UI")

### Load by Label

```csharp
// Load all assets with label "Level1"
Addressables.LoadAssetsAsync<GameObject>("Level1", null);
```

---

## Remote Content (DLC)

### Setup Remote Groups

1. Create new group: `Window > Addressables > Groups > Create New Group > Packed Assets`
2. Group Settings:
   - **Build Path**: `ServerData/[BuildTarget]`
   - **Load Path**: `http://yourcdn.com/content/[BuildTarget]`

### Build Remote Content

1. `Window > Asset Management > Addressables > Build > New Build > Default Build Script`
2. Upload `ServerData/` folder to CDN
3. Game loads assets from remote server

---

## Preloading / Caching

### Download Dependencies

```csharp
async void PreloadLevel() {
    // Download all assets in group without loading into memory
    AsyncOperationHandle handle = Addressables.DownloadDependenciesAsync("Level1");
    await handle.Task;

    // Now "Level1" assets are cached, load instantly
    Addressables.Release(handle);
}
```

### Check Download Size

```csharp
async void CheckDownloadSize() {
    AsyncOperationHandle<long> handle = Addressables.GetDownloadSizeAsync("Level1");
    await handle.Task;

    long sizeInBytes = handle.Result;
    Debug.Log($"Download size: {sizeInBytes / (1024 * 1024)} MB");

    Addressables.Release(handle);
}
```

---

## Memory Management

### Release Assets

```csharp
// ✅ Always release when done
Addressables.Release(handle);

// ✅ For instantiated objects
Addressables.ReleaseInstance(gameObject);
```

### Check Reference Count

```csharp
// Addressables uses reference counting
// Asset is unloaded when refCount == 0
```

---

## Asset References (Inspector-Assigned)

### Use AssetReference

```csharp
using UnityEngine.AddressableAssets;

public class EnemySpawner : MonoBehaviour {
    // ✅ Assign in Inspector (drag & drop)
    public AssetReference enemyPrefab;

    async void SpawnEnemy() {
        AsyncOperationHandle<GameObject> handle = enemyPrefab.InstantiateAsync();
        await handle.Task;

        GameObject enemy = handle.Result;
        // Use enemy...

        enemyPrefab.ReleaseInstance(enemy);
    }
}
```

---

## Scenes

### Load Addressable Scene

```csharp
using UnityEngine.SceneManagement;

async void LoadScene() {
    AsyncOperationHandle<SceneInstance> handle = Addressables.LoadSceneAsync("MainMenu", LoadSceneMode.Additive);
    await handle.Task;

    SceneInstance sceneInstance = handle.Result;
    // Scene loaded

    // Unload scene
    await Addressables.UnloadSceneAsync(handle).Task;
}
```

---

## Common Patterns

### Lazy Loading (Load on Demand)

```csharp
Dictionary<string, AsyncOperationHandle<GameObject>> loadedAssets = new();

async Task<GameObject> GetAsset(string key) {
    if (!loadedAssets.ContainsKey(key)) {
        var handle = Addressables.LoadAssetAsync<GameObject>(key);
        await handle.Task;
        loadedAssets[key] = handle;
    }
    return loadedAssets[key].Result;
}
```

---

### Cleanup on Scene Unload

```csharp
void OnDestroy() {
    // Release all handles
    foreach (var handle in loadedAssets.Values) {
        Addressables.Release(handle);
    }
    loadedAssets.Clear();
}
```

---

## Content Catalog Updates (Live Updates)

### Check for Catalog Updates

```csharp
async void CheckForUpdates() {
    AsyncOperationHandle<List<string>> handle = Addressables.CheckForCatalogUpdates();
    await handle.Task;

    if (handle.Result.Count > 0) {
        Debug.Log("Updates available");
        await Addressables.UpdateCatalogs(handle.Result).Task;
    }

    Addressables.Release(handle);
}
```

---

## Performance Tips

- **Preload** frequently used assets at startup
- **Release** assets immediately when not needed
- Use **labels** to batch-load related assets
- **Cache** remote content for offline use

---

## Debugging

### Addressables Event Viewer

`Window > Asset Management > Addressables > Event Viewer`

- Shows all load/release operations
- Memory usage per asset
- Reference counts

### Addressables Profiler

`Window > Asset Management > Addressables > Profiler`

- Real-time asset usage
- Bundle loading stats

---

## Migration from Resources

```csharp
// ❌ OLD: Resources.Load (synchronous, blocks frame)
GameObject prefab = Resources.Load<GameObject>("Enemies/Goblin");

// ✅ NEW: Addressables (async, non-blocking) — keep the handle so it can be released
AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>("Enemies/Goblin");
GameObject prefab = await handle.Task;
// ... when the asset is no longer needed:
Addressables.Release(handle);
```

---

## Sources
- https://docs.unity3d.com/Packages/com.unity.addressables@2.0/manual/index.html
- https://learn.unity.com/tutorial/addressables
