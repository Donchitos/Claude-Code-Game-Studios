# Unreal Engine 5.8 — Navigation Module Reference
# Unreal Engine 5.8 — 导航模块参考

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.7-5.8 navigation improvements

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.7-5.8 的导航改进

> **UE 5.8 changes:** Static meshes can define their own walkable areas
> during navmesh generation (per-mesh area costs, e.g. so AI walks around a
> couch rather than over it), enabled per mesh through a flag and an area class
> setting on NavCollision. Mover gained NavWalking support for Detour Crowd.
> Source: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** 静态网格可以在导航网格生成期间定义自己的可行走区域
> （按网格的区域开销，例如让 AI 绕过沙发而不是从上面走过），通过一个标记以及 NavCollision 上的区域类设置按网格启用。Mover 为 Detour Crowd 增加了 NavWalking 支持。
> 来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

UE 5.8 navigation systems:
- **Nav Mesh**: Automatic pathfinding mesh for AI
- **AI Controller**: Controls AI movement and behavior
- **Behavior Trees**: AI decision-making (covered in AI module)

UE 5.8 导航系统：
- **Nav Mesh**：用于 AI 的自动寻路网格
- **AI Controller**：控制 AI 的移动与行为
- **Behavior Trees**：AI 决策（在 AI 模块中介绍）

---

## Nav Mesh Setup
## Nav Mesh 设置

### Add Nav Mesh Bounds Volume
### 添加 Nav Mesh Bounds Volume

1. Place Actors > Volumes > Nav Mesh Bounds Volume
2. Scale to cover walkable areas
3. Press `P` to toggle Nav Mesh visualization (green overlay)

1. Place Actors > Volumes > Nav Mesh Bounds Volume
2. 缩放以覆盖可行走区域
3. 按 `P` 切换 Nav Mesh 可视化（绿色叠加层）

### Nav Mesh Settings
### Nav Mesh 设置

```cpp
// Project Settings > Engine > Navigation System
// - Generate Navigation Only Around Navigation Invokers: Performance optimization
// - Auto Update Enabled: Rebuild NavMesh when geometry changes
```

---

## AI Controller & Movement
## AI Controller 与移动

### Create AI Controller
### 创建 AI Controller

```cpp
UCLASS()
class AEnemyAIController : public AAIController {
    GENERATED_BODY()

public:
    void BeginPlay() override {
        Super::BeginPlay();

        // Move to location
        FVector TargetLocation = FVector(1000, 0, 0);
        MoveToLocation(TargetLocation);
    }
};
```

### Assign AI Controller to Pawn
### 将 AI Controller 分配给 Pawn

```cpp
UCLASS()
class AEnemyCharacter : public ACharacter {
    GENERATED_BODY()

public:
    AEnemyCharacter() {
        // ✅ Assign AI Controller class
        AIControllerClass = AEnemyAIController::StaticClass();
        AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;
    }
};
```

---

## Basic AI Movement
## 基础 AI 移动

### Move to Location
### 移动到位置

```cpp
AAIController* AIController = Cast<AAIController>(GetController());
if (AIController) {
    FVector TargetLocation = FVector(1000, 0, 0);
    EPathFollowingRequestResult::Type Result = AIController->MoveToLocation(TargetLocation);

    if (Result == EPathFollowingRequestResult::RequestSuccessful) {
        UE_LOG(LogTemp, Warning, TEXT("Moving to location"));
    }
}
```

### Move to Actor
### 移动到 Actor

```cpp
AActor* Target = /* Get target actor */;
AIController->MoveToActor(Target, 100.0f); // Stop 100 units away
```

### Stop Movement
### 停止移动

```cpp
AIController->StopMovement();
```

---

## Path Following Events
## 路径跟随事件

### On Move Completed
### 移动完成时

```cpp
UCLASS()
class AEnemyAIController : public AAIController {
    GENERATED_BODY()

public:
    void BeginPlay() override {
        Super::BeginPlay();

        // Bind to move completed event
        ReceiveMoveCompleted.AddDynamic(this, &AEnemyAIController::OnMoveCompleted);
    }

    UFUNCTION()
    void OnMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result) {
        if (Result == EPathFollowingResult::Success) {
            UE_LOG(LogTemp, Warning, TEXT("Reached destination"));
        } else {
            UE_LOG(LogTemp, Warning, TEXT("Failed to reach destination"));
        }
    }
};
```

---

## Pathfinding Queries
## 寻路查询

### Find Path to Location
### 查找通往某位置的路径

```cpp
#include "NavigationSystem.h"
#include "NavigationPath.h"

UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
if (NavSys) {
    FVector Start = GetActorLocation();
    FVector End = TargetLocation;

    FPathFindingQuery Query;
    Query.StartLocation = Start;
    Query.EndLocation = End;
    Query.NavData = NavSys->GetDefaultNavDataInstance();

    FPathFindingResult Result = NavSys->FindPathSync(Query);

    if (Result.IsSuccessful()) {
        UNavigationPath* NavPath = Result.Path.Get();
        // Use path points: NavPath->GetPathPoints()
    }
}
```

### Check if Location is Reachable
### 检查某位置是否可达

```cpp
UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
FNavLocation OutLocation;
bool bReachable = NavSys->ProjectPointToNavigation(TargetLocation, OutLocation);

if (bReachable) {
    UE_LOG(LogTemp, Warning, TEXT("Location is reachable"));
}
```

---

## Nav Mesh Modifiers
## Nav Mesh 修饰器

### Nav Modifier Volume (Block/Allow Areas)
### Nav Modifier Volume（阻挡/允许区域）

1. Place Actors > Volumes > Nav Modifier Volume
2. Configure Area Class (e.g., NavArea_Null to block, NavArea_LowHeight for crouching)

1. Place Actors > Volumes > Nav Modifier Volume
2. 配置 Area Class（例如 NavArea_Null 用于阻挡，NavArea_LowHeight 用于蹲伏）

---

## Custom Nav Areas
## 自定义导航区域

### Create Custom Nav Area
### 创建自定义导航区域

```cpp
UCLASS()
class UNavArea_Jump : public UNavArea {
    GENERATED_BODY()

public:
    UNavArea_Jump() {
        DefaultCost = 10.0f; // Higher cost = AI avoids unless necessary
        FixedAreaEnteringCost = 100.0f; // One-time cost to enter
    }
};
```

### Use Custom Nav Area
### 使用自定义导航区域

```cpp
// Assign to Nav Modifier Volume or geometry
```

---

## Nav Mesh Generation
## Nav Mesh 生成

### Rebuild Nav Mesh at Runtime
### 在运行时重建 Nav Mesh

```cpp
UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
NavSys->Build(); // Rebuild entire NavMesh
```

### Dynamic Nav Mesh (Moving Obstacles)
### 动态 Nav Mesh（移动障碍物）

```cpp
// Enable: Project Settings > Navigation System > Runtime Generation = Dynamic

// Mark actor as dynamic obstacle:
UStaticMeshComponent* Mesh = /* Get mesh */;
Mesh->SetCanEverAffectNavigation(true);
Mesh->bDynamicObstacle = true;
```

---

## Nav Links (Off-Mesh Connections)
## Nav Link（网格外连接）

### Nav Link Proxy (Jump, Teleport)
### Nav Link Proxy（跳跃、传送）

1. Place Actors > Navigation > Nav Link Proxy
2. Set up start and end points
3. Configure:
   - **Direction**: One-way or bidirectional
   - **Smart Link**: Animate character during traversal

1. Place Actors > Navigation > Nav Link Proxy
2. 设置起点与终点
3. 配置：
   - **Direction**：单向或双向
   - **Smart Link**：在穿越过程中为角色播放动画

---

## Crowd Management
## 人群管理

### Detour Crowd (Avoid Overlapping)
### Detour Crowd（避免重叠）

```cpp
// Enable: Character Movement Component > Avoidance Enabled = true

// Configure avoidance group and flags
UCharacterMovementComponent* MoveComp = GetCharacterMovement();
MoveComp->SetAvoidanceGroup(1);
MoveComp->SetGroupsToAvoid(1);
MoveComp->SetAvoidanceEnabled(true);
```

---

## Performance Tips
## 性能建议

### Nav Mesh Optimization
### Nav Mesh 优化

```cpp
// Reduce tile size for large worlds:
// Project Settings > Navigation System > Cell Size = 19 (default)

// Use Navigation Invokers for dynamic generation:
// Only generate NavMesh around players/important actors
```

---

## Debugging
## 调试

### Visualize Nav Mesh
### 可视化 Nav Mesh

```cpp
// Console commands:
// show navigation - Toggle NavMesh visualization
// p - Toggle NavMesh (editor viewport)

// Draw debug path:
if (NavPath) {
    for (int i = 0; i < NavPath->GetPathPoints().Num() - 1; i++) {
        DrawDebugLine(GetWorld(), NavPath->GetPathPoints()[i], NavPath->GetPathPoints()[i + 1], FColor::Green, false, 5.0f, 0, 5.0f);
    }
}
```

---

## Common Patterns
## 常见模式

### Patrol Between Waypoints
### 在路径点之间巡逻

```cpp
UPROPERTY(EditAnywhere, Category = "AI")
TArray<AActor*> PatrolPoints;

int32 CurrentPatrolIndex = 0;

void OnMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result) {
    if (Result == EPathFollowingResult::Success) {
        // Move to next waypoint
        CurrentPatrolIndex = (CurrentPatrolIndex + 1) % PatrolPoints.Num();
        MoveToActor(PatrolPoints[CurrentPatrolIndex]);
    }
}
```

### Chase Player
### 追逐玩家

```cpp
void Tick(float DeltaTime) {
    Super::Tick(DeltaTime);

    AAIController* AIController = Cast<AAIController>(GetController());
    APawn* PlayerPawn = GetWorld()->GetFirstPlayerController()->GetPawn();

    if (AIController && PlayerPawn) {
        float Distance = FVector::Dist(GetActorLocation(), PlayerPawn->GetActorLocation());

        if (Distance < 1000.0f) {
            // Chase player
            AIController->MoveToActor(PlayerPawn, 100.0f);
        } else {
            // Stop chasing
            AIController->StopMovement();
        }
    }
}
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/navigation-system-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/ai-in-unreal-engine/
