# Unreal Engine 5.8 — Networking Module Reference
# Unreal Engine 5.8 — 网络模块参考

**Last verified:** 2026-10-18 (Iris status: release notes and plugin flag); 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.7-5.8 networking improvements (Iris production-ready in 5.8)

**最后验证：** 2026-10-18（Iris 状态：发行说明与插件标记）；2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.7-5.8 的网络改进（Iris 在 5.8 中生产就绪）

> **UE 5.8 changes:** Iris "is now production-ready for licensees in UE
> 5.8" (the `Iris.uplugin` in a 5.8.1 install still carries a Beta flag), with
> clearer protocol-mismatch errors and RPC DoS detection re-enabled. Thread-safety
> primitives were added for parallel `NetConnection::Tick`; a target that does
> not need them can drop them with `ExcludeParallelIrisSupport` in
> `TargetRules.cs`. Network Prediction gained optional Iris support. Source: UE
> 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
>
> **The notes and the plugin flag disagree.** Treat Iris as production-ready,
> as the release notes say ("Iris is now production-ready for licensees in UE
> 5.8", Framework > "Iris: Production-Ready Replication System"), and expect
> the editor's plugin list to show it as Beta: `Engine/Plugins/Experimental/Iris/Iris.uplugin`
> in a 5.8.1 install (CL 56057345) has `"IsBetaVersion": true`. Both read
> 2026-10-18.

> **UE 5.8 变更：** Iris "在 UE 5.8 中已对授权方生产就绪"（5.8.1 安装中的 `Iris.uplugin` 仍带有 Beta 标记），
> 协议不匹配错误更清晰，RPC DoS 检测已重新启用。为并行 `NetConnection::Tick` 增加了线程安全原语；
> 不需要这些原语的目标可以在 `TargetRules.cs` 中通过 `ExcludeParallelIrisSupport` 将其去掉。Network Prediction 获得了可选的 Iris 支持。
> 来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
>
> **发行说明与插件标记并不一致。** 请按发行说明的说法将 Iris 视为生产就绪（"Iris is now production-ready for licensees in UE
> 5.8"，Framework > "Iris: Production-Ready Replication System"），同时预期编辑器的插件列表会将其显示为 Beta：5.8.1 安装（CL 56057345）中的 `Engine/Plugins/Experimental/Iris/Iris.uplugin`
> 含有 `"IsBetaVersion": true`。两者均于 2026-10-18 读取。

---

## Overview
## 概述

UE 5.8 networking:
- **Client-Server Architecture**: Server-authoritative (RECOMMENDED)
- **Replication**: Automatic state synchronization
- **RPCs (Remote Procedure Calls)**: Call functions across network
- **Relevancy**: Optimize bandwidth by only replicating relevant actors

UE 5.8 网络：
- **客户端-服务器架构**：服务器权威（推荐）
- **复制（Replication）**：自动状态同步
- **RPC（远程过程调用）**：跨网络调用函数
- **相关性（Relevancy）**：仅复制相关 Actor 以优化带宽

---

## Basic Multiplayer Setup
## 基础多玩家设置

### Enable Replication on Actor
### 在 Actor 上启用复制

```cpp
UCLASS()
class AMyActor : public AActor {
    GENERATED_BODY()

public:
    AMyActor() {
        // ✅ Enable replication
        bReplicates = true;
        bAlwaysRelevant = true; // Always replicate to all clients
    }
};
```

### Network Role Checks
### 网络角色检查

```cpp
// Check role
if (HasAuthority()) {
    // Running on server
}

if (GetLocalRole() == ROLE_AutonomousProxy) {
    // This is the owning client (local player)
}

if (GetRemoteRole() == ROLE_SimulatedProxy) {
    // This is a remote client (other players)
}
```

---

## Replicated Variables
## 复制变量

### Basic Replication
### 基础复制

```cpp
UPROPERTY(Replicated)
int32 Health;

UPROPERTY(Replicated)
FVector Position;

// ✅ Implement GetLifetimeReplicatedProps
void AMyActor::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const {
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME(AMyActor, Health);
    DOREPLIFETIME(AMyActor, Position);
}
```

### Conditional Replication
### 条件复制

```cpp
// Only replicate to owner
DOREPLIFETIME_CONDITION(AMyCharacter, Ammo, COND_OwnerOnly);

// Skip owner (replicate to everyone else)
DOREPLIFETIME_CONDITION(AMyCharacter, TeamID, COND_SkipOwner);

// Only when changed
DOREPLIFETIME_CONDITION(AMyCharacter, Score, COND_InitialOnly);
```

### RepNotify (Callback on Replication)
### RepNotify（复制时的回调）

```cpp
UPROPERTY(ReplicatedUsing=OnRep_Health)
int32 Health;

UFUNCTION()
void OnRep_Health() {
    // Called on clients when Health changes
    UpdateHealthUI();
}

// Implement GetLifetimeReplicatedProps (same as above)
```

---

## RPCs (Remote Procedure Calls)
## RPC（远程过程调用）

### Server RPC (Client → Server)
### Server RPC（客户端 → 服务器）

```cpp
// Client calls, server executes. WithValidation declares Server_TakeDamage_Validate.
UFUNCTION(Server, Reliable, WithValidation)
void Server_TakeDamage(int32 Damage);

void AMyCharacter::Server_TakeDamage_Implementation(int32 Damage) {
    // Runs on server only
    Health -= Damage;

    if (Health <= 0) {
        Server_Die();
    }
}

bool AMyCharacter::Server_TakeDamage_Validate(int32 Damage) {
    // Validate input (anti-cheat)
    return Damage >= 0 && Damage <= 100;
}
```

### Client RPC (Server → Client)
### Client RPC（服务器 → 客户端）

```cpp
// Server calls, client executes
UFUNCTION(Client, Reliable)
void Client_ShowDeathScreen();

void AMyCharacter::Client_ShowDeathScreen_Implementation() {
    // Runs on client only
    ShowDeathUI();
}
```

### Multicast RPC (Server → All Clients)
### Multicast RPC（服务器 → 所有客户端）

```cpp
// Server calls, all clients execute
UFUNCTION(NetMulticast, Reliable)
void Multicast_PlayExplosion(FVector Location);

void AMyActor::Multicast_PlayExplosion_Implementation(FVector Location) {
    // Runs on server and all clients
    UGameplayStatics::SpawnEmitterAtLocation(GetWorld(), ExplosionEffect, Location);
}
```

### RPC Reliability
### RPC 可靠性

```cpp
// Reliable: Guaranteed delivery (important events)
UFUNCTION(Server, Reliable)
void Server_FireWeapon();

// Unreliable: Best-effort delivery (frequent updates, position sync)
UFUNCTION(Server, Unreliable)
void Server_UpdateAim(FRotator AimRotation);
```

---

## Server-Authoritative Pattern (RECOMMENDED)
## 服务器权威模式（推荐）

### Movement Example
### 移动示例

```cpp
class AMyCharacter : public ACharacter {
    UPROPERTY(Replicated)
    FVector ServerPosition;

    void Tick(float DeltaTime) override {
        Super::Tick(DeltaTime);

        if (GetLocalRole() == ROLE_AutonomousProxy) {
            // Client: Send input to server
            FVector Input = GetMovementInput();
            Server_Move(Input);

            // Client-side prediction (move locally)
            AddMovementInput(Input);
        }

        if (HasAuthority()) {
            // Server: Authoritative position
            ServerPosition = GetActorLocation();
        } else {
            // Client: Interpolate toward server position
            FVector NewPos = FMath::VInterpTo(GetActorLocation(), ServerPosition, DeltaTime, 5.0f);
            SetActorLocation(NewPos);
        }
    }

    UFUNCTION(Server, Unreliable)
    void Server_Move(FVector Input);

    void Server_Move_Implementation(FVector Input) {
        // Server validates and applies movement
        AddMovementInput(Input);
    }
};
```

---

## Network Relevancy (Bandwidth Optimization)
## 网络相关性（带宽优化）

### Custom Relevancy
### 自定义相关性

```cpp
bool AMyActor::IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const {
    // Only replicate if within range
    float Distance = FVector::Dist(SrcLocation, GetActorLocation());
    return Distance < 5000.0f;
}
```

### Always Relevant Actors
### 始终相关的 Actor

```cpp
AMyActor() {
    bAlwaysRelevant = true; // Replicate to all clients (e.g., GameState, PlayerController)
    bOnlyRelevantToOwner = true; // Only replicate to owner (e.g., PlayerController)
}
```

---

## Ownership
## 所有权

### Set Owner
### 设置所有者

```cpp
// Assign owner (important for RPCs and relevancy)
MyActor->SetOwner(OwningPlayerController);
```

### Check Owner
### 检查所有者

```cpp
if (GetOwner() == PlayerController) {
    // This actor is owned by this player
}
```

---

## Game Mode & Game State
## Game Mode 与 Game State

### Game Mode (Server Only)
### Game Mode（仅服务器）

```cpp
UCLASS()
class AMyGameMode : public AGameMode {
    GENERATED_BODY()

public:
    // Game mode only exists on server
    // Use for server-side logic (spawning, scoring, rules)
};
```

### Game State (Replicated to All Clients)
### Game State（复制到所有客户端）

```cpp
UCLASS()
class AMyGameState : public AGameState {
    GENERATED_BODY()

public:
    // ✅ Replicate game state to all clients
    UPROPERTY(Replicated)
    int32 RedTeamScore;

    UPROPERTY(Replicated)
    int32 BlueTeamScore;

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override {
        Super::GetLifetimeReplicatedProps(OutLifetimeProps);
        DOREPLIFETIME(AMyGameState, RedTeamScore);
        DOREPLIFETIME(AMyGameState, BlueTeamScore);
    }
};
```

---

## Player Controller & Player State
## Player Controller 与 Player State

### Player Controller (One per Player)
### Player Controller（每个玩家一个）

```cpp
UCLASS()
class AMyPlayerController : public APlayerController {
    GENERATED_BODY()

public:
    // Exists on server and owning client
    // Use for player-specific logic, input handling
};
```

### Player State (Replicated Player Info)
### Player State（复制的玩家信息）

```cpp
UCLASS()
class AMyPlayerState : public APlayerState {
    GENERATED_BODY()

public:
    UPROPERTY(Replicated)
    int32 Kills;

    UPROPERTY(Replicated)
    int32 Deaths;

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override {
        Super::GetLifetimeReplicatedProps(OutLifetimeProps);
        DOREPLIFETIME(AMyPlayerState, Kills);
        DOREPLIFETIME(AMyPlayerState, Deaths);
    }
};
```

---

## Sessions & Matchmaking
## 会话与匹配

### Create Session
### 创建会话

```cpp
#include "OnlineSubsystem.h"
#include "OnlineSessionSettings.h"

void CreateSession() {
    IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get();
    IOnlineSessionPtr Sessions = OnlineSub->GetSessionInterface();

    TSharedPtr<FOnlineSessionSettings> SessionSettings = MakeShareable(new FOnlineSessionSettings());
    SessionSettings->bIsLANMatch = false;
    SessionSettings->NumPublicConnections = 4;
    SessionSettings->bShouldAdvertise = true;

    Sessions->CreateSession(0, FName("MySession"), *SessionSettings);
}
```

### Find Sessions
### 查找会话

```cpp
void FindSessions() {
    IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get();
    IOnlineSessionPtr Sessions = OnlineSub->GetSessionInterface();

    TSharedRef<FOnlineSessionSearch> SearchSettings = MakeShareable(new FOnlineSessionSearch());
    SearchSettings->bIsLanQuery = false;
    SearchSettings->MaxSearchResults = 20;

    Sessions->FindSessions(0, SearchSettings);
}
```

---

## Performance Tips
## 性能建议

### Reduce Bandwidth
### 降低带宽占用

```cpp
// Use unreliable RPCs for frequent updates
UFUNCTION(Server, Unreliable)
void Server_UpdatePosition(FVector Pos);

// Conditional replication (only replicate to relevant clients)
DOREPLIFETIME_CONDITION(AMyActor, Health, COND_OwnerOnly);

// Limit replication frequency
SetReplicationFrequency(10.0f); // Update 10 times per second (default 100)
```

---

## Debugging
## 调试

### Network Debugging
### 网络调试

```cpp
// Console commands:
// stat net - Show network stats
// stat netplayerupdate - Show player update stats
// NetEmulation PktLoss=10 - Simulate 10% packet loss
// NetEmulation PktLag=100 - Simulate 100ms latency

// Draw debug for replication:
UE_LOG(LogNet, Warning, TEXT("Replicating Health: %d"), Health);
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/networking-and-multiplayer-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/actor-replication-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/rpcs-in-unreal-engine/
