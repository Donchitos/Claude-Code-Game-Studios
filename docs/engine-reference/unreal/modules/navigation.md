# Unreal Engine 5.8 — Navigation Module Reference

**Last verified:** 2026-08-16
**Knowledge Gap:** 5.8 adds per-mesh walkable surface control; StateTree and Mass improvements

---

## Overview

UE 5.8 navigation systems:
- **Nav Mesh**: Automatic pathfinding mesh for AI
- **AI Controller**: Controls AI movement and behavior
- **Behavior Trees**: AI decision-making (covered in AI module)
- **StateTree**: Modern AI logic authoring — 5.8 adds starting states and compiler extensions
- **Mass**: Large-scale AI/crowds — major multi-core overhaul in 5.8 (`MassCore`)

---

## What's New in UE 5.8

- **Per-mesh walkable surface control** during navmesh generation
- **StateTree**: starting states and compiler extensions for improved authoring
- **Mass framework overhaul**: lock-free scheduling, sparse fragment system, multi-core optimization via the `MassCore` module
- **MetaHuman Crowd (Experimental)**: Mass-orchestrated MetaHuman crowds

---

## Nav Mesh Setup

### Add Nav Mesh Bounds Volume

1. Place Actors > Volumes > Nav Mesh Bounds Volume
2. Scale to cover walkable areas
3. Press `P` to toggle Nav Mesh visualization (green overlay)

### Nav Mesh Settings

```cpp
// Project Settings > Engine > Navigation System
// - Generate Navigation Only Around Navigation Invokers: Performance optimization
// - Auto Update Enabled: Rebuild NavMesh when geometry changes
```

---

## AI Controller & Movement

### Create AI Controller

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

### Move to Location

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

```cpp
AActor* Target = /* Get target actor */;
AIController->MoveToActor(Target, 100.0f); // Stop 100 units away
```

### Stop Movement

```cpp
AIController->StopMovement();
```

---

## Path Following Events

### On Move Completed

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

### Find Path to Location

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

### Nav Modifier Volume (Block/Allow Areas)

1. Place Actors > Volumes > Nav Modifier Volume
2. Configure Area Class (e.g., NavArea_Null to block, NavArea_LowHeight for crouching)

---

## Custom Nav Areas

### Create Custom Nav Area

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

```cpp
// Assign to Nav Modifier Volume or geometry
```

---

## Nav Mesh Generation

### Rebuild Nav Mesh at Runtime

```cpp
UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
NavSys->Build(); // Rebuild entire NavMesh
```

### Dynamic Nav Mesh (Moving Obstacles)

```cpp
// Enable: Project Settings > Navigation System > Runtime Generation = Dynamic

// Mark actor as dynamic obstacle:
UStaticMeshComponent* Mesh = /* Get mesh */;
Mesh->SetCanEverAffectNavigation(true);
Mesh->bDynamicObstacle = true;
```

---

## Nav Links (Off-Mesh Connections)

### Nav Link Proxy (Jump, Teleport)

1. Place Actors > Navigation > Nav Link Proxy
2. Set up start and end points
3. Configure:
   - **Direction**: One-way or bidirectional
   - **Smart Link**: Animate character during traversal

---

## Crowd Management

### Detour Crowd (Avoid Overlapping)

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

### Nav Mesh Optimization

```cpp
// Reduce tile size for large worlds:
// Project Settings > Navigation System > Cell Size = 19 (default)

// Use Navigation Invokers for dynamic generation:
// Only generate NavMesh around players/important actors
```

---

## Debugging

### Visualize Nav Mesh

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

### Patrol Between Waypoints

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
- https://docs.unrealengine.com/5.8/en-US/navigation-system-in-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/ai-in-unreal-engine/
