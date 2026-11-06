# Unity 6.3 — Networking Module Reference
# Unity 6.3 — 网络模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 uses Netcode for GameObjects (UNet deprecated)
**知识盲区：** Unity 6 使用 Netcode for GameObjects（UNet 已弃用）

---

## Overview
## 概述

Unity 6 networking options:
- **Netcode for GameObjects** (RECOMMENDED): Official Unity multiplayer framework
- **Mirror**: Community-driven (UNet successor)
- **Photon**: Third-party service (PUN2)
- **Custom**: Low-level sockets

Unity 6 网络方案：
- **Netcode for GameObjects（推荐）**：Unity 官方多人游戏框架
- **Mirror**：社区驱动（UNet 的后继者）
- **Photon**：第三方服务（PUN2）
- **自定义（Custom）**：底层套接字

**UNet (Legacy)**: Deprecated, do not use.

**UNet（旧版）**：已弃用，请勿使用。

---

## Netcode for GameObjects
## Netcode for GameObjects

### Installation
### 安装
1. `Window > Package Manager`
2. Search "Netcode for GameObjects"
3. Install `com.unity.netcode.gameobjects`

1. `Window > Package Manager`
2. 搜索 "Netcode for GameObjects"
3. 安装 `com.unity.netcode.gameobjects`

---

## Basic Setup
## 基本设置

### NetworkManager
### NetworkManager

```csharp
// Add to scene: GameObject > Add Component > NetworkManager

// Or create custom NetworkManager:
using Unity.Netcode;

public class CustomNetworkManager : MonoBehaviour {
    void Start() {
        NetworkManager.Singleton.StartHost(); // Server + client
        // OR
        NetworkManager.Singleton.StartServer(); // Dedicated server
        // OR
        NetworkManager.Singleton.StartClient(); // Client only
    }
}
```

---

## NetworkObject (Networked GameObjects)
## NetworkObject（联网的 GameObject）

### Mark GameObject as Networked
### 将 GameObject 标记为联网对象

1. Add `NetworkObject` component to GameObject
2. Must be in root of prefab (not nested)
3. Register prefab in `NetworkManager > NetworkPrefabs List`

1. 向 GameObject 添加 `NetworkObject` 组件
2. 必须位于预制体（prefab）的根节点（不能嵌套）
3. 在 `NetworkManager > NetworkPrefabs List` 中注册预制体

### Spawn Network Objects
### 生成网络对象

```csharp
using Unity.Netcode;

public class GameManager : NetworkBehaviour {
    public GameObject playerPrefab;

    [ServerRpc(RequireOwnership = false)]
    public void SpawnPlayerServerRpc(ulong clientId) {
        GameObject player = Instantiate(playerPrefab);
        player.GetComponent<NetworkObject>().SpawnAsPlayerObject(clientId);
    }
}
```

---

## NetworkBehaviour (Networked Scripts)
## NetworkBehaviour（联网脚本）

### NetworkBehaviour Base Class
### NetworkBehaviour 基类

```csharp
using Unity.Netcode;

public class Player : NetworkBehaviour {
    // Called when spawned on network
    public override void OnNetworkSpawn() {
        if (IsOwner) {
            // Only run on owner's client
            GetComponent<Camera>().enabled = true;
        }
    }

    void Update() {
        if (!IsOwner) return; // Only owner can control

        // Handle input
        if (Input.GetKey(KeyCode.W)) {
            MoveServerRpc(Vector3.forward);
        }
    }

    [ServerRpc]
    void MoveServerRpc(Vector3 direction) {
        // Runs on server
        transform.position += direction * Time.deltaTime;
    }
}
```

---

## Network Variables (Synchronized State)
## 网络变量（Network Variables，同步状态）

### NetworkVariable<T>
### NetworkVariable<T>

```csharp
using Unity.Netcode;

public class Player : NetworkBehaviour {
    // ✅ Auto-synced across clients
    private NetworkVariable<int> health = new NetworkVariable<int>(100);

    public override void OnNetworkSpawn() {
        // Subscribe to value changes
        health.OnValueChanged += OnHealthChanged;
    }

    void OnHealthChanged(int oldValue, int newValue) {
        Debug.Log($"Health changed: {oldValue} -> {newValue}");
        UpdateHealthUI(newValue);
    }

    [ServerRpc]
    public void TakeDamageServerRpc(int damage) {
        // Only server can modify NetworkVariable
        health.Value -= damage;
    }
}
```

### NetworkVariable Permissions
### NetworkVariable 权限

```csharp
// Server can write, clients read-only (default)
private NetworkVariable<int> score = new NetworkVariable<int>();

// Owner can write
private NetworkVariable<int> ammo = new NetworkVariable<int>(
    default,
    NetworkVariableReadPermission.Everyone,
    NetworkVariableWritePermission.Owner
);
```

---

## RPCs (Remote Procedure Calls)
## RPC（远程过程调用）

### ServerRpc (Client → Server)
### ServerRpc（客户端 → 服务器）

```csharp
// Client calls, server executes
[ServerRpc]
void FireWeaponServerRpc() {
    // Runs on server
    Debug.Log("Server: Weapon fired");
}

// Call from client:
if (IsOwner && Input.GetKeyDown(KeyCode.Space)) {
    FireWeaponServerRpc();
}
```

### ClientRpc (Server → All Clients)
### ClientRpc（服务器 → 所有客户端）

```csharp
// Server calls, all clients execute
[ClientRpc]
void PlayExplosionClientRpc(Vector3 position) {
    // Runs on all clients
    Instantiate(explosionPrefab, position, Quaternion.identity);
}

// Call from server:
[ServerRpc]
void ExplodeServerRpc(Vector3 position) {
    // Server logic
    DealDamageToNearbyPlayers(position);

    // Notify all clients
    PlayExplosionClientRpc(position);
}
```

### RPC Parameters
### RPC 参数

```csharp
// ✅ Supported: Primitives, structs, strings, arrays
[ServerRpc]
void SetNameServerRpc(string playerName) { }

[ClientRpc]
void UpdateScoresClientRpc(int[] scores) { }

// ❌ Not supported: MonoBehaviour, GameObject (use NetworkObjectReference)
```

---

## Network Ownership
## 网络所有权

### Check Ownership
### 检查所有权

```csharp
if (IsOwner) {
    // This client owns this NetworkObject
}

if (IsServer) {
    // Running on server
}

if (IsClient) {
    // Running on client
}

if (IsLocalPlayer) {
    // This is the local player object
}
```

### Transfer Ownership
### 转移所有权

```csharp
// Server transfers ownership
NetworkObject netObj = GetComponent<NetworkObject>();
netObj.ChangeOwnership(newOwnerClientId);
```

---

## NetworkObjectReference (Pass GameObjects in RPCs)
## NetworkObjectReference（在 RPC 中传递 GameObject）

```csharp
using Unity.Netcode;

[ServerRpc]
void AttackTargetServerRpc(NetworkObjectReference targetRef) {
    if (targetRef.TryGet(out NetworkObject target)) {
        // Got the target object
        target.GetComponent<Health>().TakeDamage(10);
    }
}

// Call:
NetworkObject targetNetObj = target.GetComponent<NetworkObject>();
AttackTargetServerRpc(targetNetObj);
```

---

## Client-Server Architecture
## 客户端-服务器架构

### Server-Authoritative Pattern (RECOMMENDED)
### 服务器权威模式（推荐）

```csharp
public class Player : NetworkBehaviour {
    private NetworkVariable<Vector3> position = new NetworkVariable<Vector3>();

    void Update() {
        if (IsOwner) {
            // Client: Send input to server
            Vector3 input = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
            MoveServerRpc(input);
        }

        // All clients: Sync to networked position
        transform.position = position.Value;
    }

    [ServerRpc]
    void MoveServerRpc(Vector3 input) {
        // Server: Validate and apply movement
        position.Value += input * Time.deltaTime * moveSpeed;
    }
}
```

---

## Network Transport
## 网络传输

### Unity Transport (Default)
### Unity Transport（默认）

```csharp
// Configured in NetworkManager:
// - Transport: Unity Transport
// - Address: 127.0.0.1 (localhost) or server IP
// - Port: 7777 (default)
```

### Connection Events
### 连接事件

```csharp
void Start() {
    NetworkManager.Singleton.OnClientConnectedCallback += OnClientConnected;
    NetworkManager.Singleton.OnClientDisconnectCallback += OnClientDisconnected;
}

void OnClientConnected(ulong clientId) {
    Debug.Log($"Client {clientId} connected");
}

void OnClientDisconnected(ulong clientId) {
    Debug.Log($"Client {clientId} disconnected");
}
```

---

## Performance Tips
## 性能提示

### Reduce Network Traffic
### 减少网络流量
- Use `NetworkVariable` for state that changes infrequently
- Batch multiple changes before syncing
- Use delta compression for large data

- 对不常变化的状态使用 `NetworkVariable`
- 在同步前批量合并多处变更
- 对大数据使用增量压缩

### Prediction & Reconciliation
### 预测与协调
- Run movement locally for responsiveness
- Reconcile with server authoritative state
- Use interpolation for smooth movement

- 在本地运行移动逻辑以保证响应性
- 与服务器权威状态进行协调（reconciliation）
- 使用插值实现平滑移动

---

## Debugging
## 调试

### Network Profiler
### 网络性能分析器
- `Window > Analysis > Network Profiler`
- Monitor bandwidth, RPC calls, variable updates

- `Window > Analysis > Network Profiler`
- 监控带宽、RPC 调用、变量更新

### Network Simulator (Test Latency/Packet Loss)
### 网络模拟器（测试延迟/丢包）
- `NetworkManager > Network Simulator`
- Add artificial lag and packet loss for testing

- `NetworkManager > Network Simulator`
- 添加人为延迟和丢包以进行测试

---

## Sources
## 来源
- https://docs-multiplayer.unity3d.com/netcode/current/about/
- https://docs-multiplayer.unity3d.com/netcode/current/learn/bossroom/
