# Unity 6.3 — Addressables
# Unity 6.3 — Addressables

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Status:** Production-Ready
**状态：** 生产就绪
**Package:** `com.unity.addressables` (Package Manager)
**包：** `com.unity.addressables`（Package Manager）

---

## Overview
## 概述

**Addressables** is Unity's advanced asset management system that replaces `Resources.Load()`
with async loading, remote content delivery, and better memory control.

**Addressables** 是 Unity 的高级资源管理系统，它以异步加载、远程内容分发和更好的内存控制取代 `Resources.Load()`。

**Use Addressables for:**
- Async asset loading (non-blocking)
- DLC and remote content
- Memory optimization (load/unload on demand)
- Asset dependency management
- Large projects with many assets

**使用 Addressables 的场景：**
- 异步资源加载（非阻塞）
- DLC 与远程内容
- 内存优化（按需加载/卸载）
- 资源依赖管理
- 资源众多的大型项目

**DON'T use Addressables for:**
- Tiny projects (overhead not worth it)
- Assets needed immediately at startup (use direct references)

**不要使用 Addressables 的场景：**
- 极小的项目（开销不值得）
- 启动时立即需要的资源（使用直接引用）

---

## Installation
## 安装

### Install via Package Manager
### 通过 Package Manager 安装

1. `Window > Package Manager`
2. Unity Registry > Search "Addressables"
3. Install `Addressables`

1. `Window > Package Manager`
2. Unity Registry > 搜索 "Addressables"
3. 安装 `Addressables`

---

## Core Concepts
## 核心概念

### 1. **Addressable Assets**
### 1. **可寻址资源（Addressable Assets）**
- Assets marked as "Addressable" (assigned unique keys)
- Can be loaded by key at runtime

- 标记为"可寻址（Addressable）"的资源（分配唯一键）
- 可在运行时按键加载

### 2. **Asset Groups**
### 2. **资源组（Asset Groups）**
- Organize assets (e.g., "UI", "Weapons", "Level1")
- Groups determine build settings (local vs remote)

- 组织资源（例如 "UI"、"Weapons"、"Level1"）
- 资源组决定构建设置（本地还是远程）

### 3. **Async Loading**
### 3. **异步加载**
- All loading is async (non-blocking)
- Returns `AsyncOperationHandle`

- 所有加载均为异步（非阻塞）
- 返回 `AsyncOperationHandle`

### 4. **Reference Counting**
### 4. **引用计数**
- Addressables tracks asset usage
- Must manually release assets when done

- Addressables 跟踪资源的使用情况
- 用完后必须手动释放资源

---

## Setup
## 设置

### 1. Mark Assets as Addressable
### 1. 将资源标记为可寻址

1. Select asset in Project window
2. Inspector > Check "Addressable"
3. Assign key (e.g., "Enemies/Goblin")

1. 在 Project 窗口中选择资源
2. Inspector > 勾选 "Addressable"
3. 分配键（例如 "Enemies/Goblin"）

**OR via script:**
**或通过脚本：**
```csharp
#if UNITY_EDITOR
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;

AddressableAssetSettings.AddAssetEntry(guid, "MyAssetKey", "Default Local Group");
#endif
```

---

### 2. Create Groups
### 2. 创建资源组

`Window > Asset Management > Addressables > Groups`

`Window > Asset Management > Addressables > Groups`

- **Default Local Group**: Bundled with build
- **Remote Group**: Hosted on server (CDN)

- **Default Local Group**：随构建打包
- **Remote Group**：托管在服务器（CDN）上

---

## Basic Loading
## 基本加载

### Load Asset Async
### 异步加载资源

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
### 加载并实例化

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
### 加载多个资源

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
## 资源标签（Tags）

### Assign Labels
### 分配标签

1. `Window > Asset Management > Addressables > Groups`
2. Select asset > Inspector > Labels > Add label (e.g., "Level1", "UI")

1. `Window > Asset Management > Addressables > Groups`
2. 选择资源 > Inspector > Labels > 添加标签（例如 "Level1"、"UI"）

### Load by Label
### 按标签加载

```csharp
// Load all assets with label "Level1"
Addressables.LoadAssetsAsync<GameObject>("Level1", null);
```

---

## Remote Content (DLC)
## 远程内容（DLC）

### Setup Remote Groups
### 设置远程资源组

1. Create new group: `Window > Addressables > Groups > Create New Group > Packed Assets`
2. Group Settings:
   - **Build Path**: `ServerData/[BuildTarget]`
   - **Load Path**: `http://yourcdn.com/content/[BuildTarget]`

1. 创建新资源组：`Window > Addressables > Groups > Create New Group > Packed Assets`
2. 资源组设置：
   - **Build Path**：`ServerData/[BuildTarget]`
   - **Load Path**：`http://yourcdn.com/content/[BuildTarget]`

### Build Remote Content
### 构建远程内容

1. `Window > Asset Management > Addressables > Build > New Build > Default Build Script`
2. Upload `ServerData/` folder to CDN
3. Game loads assets from remote server

1. `Window > Asset Management > Addressables > Build > New Build > Default Build Script`
2. 将 `ServerData/` 文件夹上传到 CDN
3. 游戏从远程服务器加载资源

---

## Preloading / Caching
## 预加载 / 缓存

### Download Dependencies
### 下载依赖项

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
### 检查下载大小

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
## 内存管理

### Release Assets
### 释放资源

```csharp
// ✅ Always release when done
Addressables.Release(handle);

// ✅ For instantiated objects
Addressables.ReleaseInstance(gameObject);
```

### Check Reference Count
### 检查引用计数

```csharp
// Addressables uses reference counting
// Asset is unloaded when refCount == 0
```

---

## Asset References (Inspector-Assigned)
## 资源引用（在检视面板中指派）

### Use AssetReference
### 使用 AssetReference

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
## 场景

### Load Addressable Scene
### 加载可寻址场景

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
## 常见模式

### Lazy Loading (Load on Demand)
### 延迟加载（按需加载）

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
### 场景卸载时清理

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
## 内容目录更新（实时更新）

### Check for Catalog Updates
### 检查目录更新

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
## 性能提示

- **Preload** frequently used assets at startup
- **Release** assets immediately when not needed
- Use **labels** to batch-load related assets
- **Cache** remote content for offline use

- 在启动时**预加载**常用资源
- 不再需要时立即**释放**资源
- 使用**标签**批量加载相关资源
- **缓存**远程内容以供离线使用

---

## Debugging
## 调试

### Addressables Event Viewer
### Addressables 事件查看器

`Window > Asset Management > Addressables > Event Viewer`

`Window > Asset Management > Addressables > Event Viewer`

- Shows all load/release operations
- Memory usage per asset
- Reference counts

- 显示所有加载/释放操作
- 每个资源的内存占用
- 引用计数

### Addressables Profiler
### Addressables 性能分析器

`Window > Asset Management > Addressables > Profiler`

`Window > Asset Management > Addressables > Profiler`

- Real-time asset usage
- Bundle loading stats

- 实时的资源使用情况
- 包（Bundle）加载统计

---

## Migration from Resources
## 从 Resources 迁移

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
## 来源
- https://docs.unity3d.com/Packages/com.unity.addressables@2.0/manual/index.html
- https://learn.unity.com/tutorial/addressables
