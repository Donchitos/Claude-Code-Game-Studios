# Unreal Engine 5.8 — Input Module Reference
# Unreal Engine 5.8 — 输入模块参考

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.7+ uses Enhanced Input as default (legacy input deprecated); UE 5.8 unifies it with Common UI input

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.7+ 默认使用 Enhanced Input（旧版输入已弃用）；UE 5.8 将其与 Common UI 输入统一

> **UE 5.8 changes:** Enhanced Input and Common Input/UI are unified,
> which "removes the need for duplicate data assets"; there is a new Input
> Debugger for Enhanced Input UI. Fixes ship behind CVars that "will be removed
> in a future release": `EnhancedInput.IgnoreHeldKeysOnFlush` (default true) and
> `EnhancedInput.CorrectTouchBoolActionKeys` (default on). The Raw Input plugin
> is deprecated (`"DeprecatedEngineVersion": "5.8"`) in favour of the Game Input
> for Windows plugin (`GameInputWindows`, Beta); the release notes say to set
> `IncludeRedistFiles=True` in the Game Input section of `DefaultEngine.ini` so
> packaging includes `GameInputRedist.msi`. Source: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** Enhanced Input 与 Common Input/UI 已统一，
> 这"消除了对重复数据资产的需求"；并新增了面向 Enhanced Input UI 的 Input Debugger。若干修复置于"将在未来版本中移除"的 CVar 之后：`EnhancedInput.IgnoreHeldKeysOnFlush`（默认 true）与
> `EnhancedInput.CorrectTouchBoolActionKeys`（默认开启）。Raw Input 插件已弃用（`"DeprecatedEngineVersion": "5.8"`），
> 改用 Game Input for Windows 插件（`GameInputWindows`，Beta）；发行说明要求
> 在 `DefaultEngine.ini` 的 Game Input 段中设置 `IncludeRedistFiles=True`，以便打包时包含 `GameInputRedist.msi`。
> 来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

UE 5.8 input systems:
- **Enhanced Input** (RECOMMENDED, default in UE5): Modular, rebindable, context-based
- **Legacy Input**: Deprecated, avoid for new projects

UE 5.8 输入系统：
- **Enhanced Input**（推荐，UE5 默认）：模块化、可重绑定、基于上下文
- **旧版输入**：已弃用，新项目请避免使用

---

## Enhanced Input System
## Enhanced Input 系统

### Setup Enhanced Input
### 设置 Enhanced Input

1. **Enable Plugin**: `Edit > Plugins > Enhanced Input` (enabled by default in UE5)
2. **Project Settings**: `Engine > Input > Default Classes > Default Player Input Class = EnhancedPlayerInput`

1. **启用插件**：`Edit > Plugins > Enhanced Input`（UE5 中默认启用）
2. **项目设置**：`Engine > Input > Default Classes > Default Player Input Class = EnhancedPlayerInput`

---

### Create Input Actions
### 创建 Input Action

1. Content Browser > Input > Input Action
2. Name it (e.g., `IA_Jump`, `IA_Move`)
3. Configure:
   - **Value Type**: Digital (bool), Axis1D (float), Axis2D (Vector2D), Axis3D (Vector)

1. Content Browser > Input > Input Action
2. 命名（例如 `IA_Jump`、`IA_Move`）
3. 配置：
   - **Value Type**：Digital (bool)、Axis1D (float)、Axis2D (Vector2D)、Axis3D (Vector)

Example Input Actions:
- `IA_Jump`: Digital (bool)
- `IA_Move`: Axis2D (Vector2D)
- `IA_Look`: Axis2D (Vector2D)
- `IA_Fire`: Digital (bool)

示例 Input Action：
- `IA_Jump`：Digital (bool)
- `IA_Move`：Axis2D (Vector2D)
- `IA_Look`：Axis2D (Vector2D)
- `IA_Fire`：Digital (bool)

---

### Create Input Mapping Context
### 创建 Input Mapping Context

1. Content Browser > Input > Input Mapping Context
2. Name it (e.g., `IMC_Default`)
3. Add mappings:
   - `IA_Jump` → Space Bar
   - `IA_Move` → W/A/S/D keys (combine X/Y)
   - `IA_Look` → Mouse XY
   - `IA_Fire` → Left Mouse Button

1. Content Browser > Input > Input Mapping Context
2. 命名（例如 `IMC_Default`）
3. 添加映射：
   - `IA_Jump` → 空格键
   - `IA_Move` → W/A/S/D 键（合并 X/Y）
   - `IA_Look` → 鼠标 XY
   - `IA_Fire` → 鼠标左键

---

### Bind Input in C++
### 在 C++ 中绑定输入

```cpp
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputActionValue.h"

class AMyCharacter : public ACharacter {
public:
    // Input Actions (assign in Blueprint)
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Input")
    TObjectPtr<UInputAction> MoveAction;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Input")
    TObjectPtr<UInputAction> LookAction;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Input")
    TObjectPtr<UInputAction> JumpAction;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Input")
    TObjectPtr<UInputMappingContext> DefaultMappingContext;

protected:
    virtual void BeginPlay() override {
        Super::BeginPlay();

        // Add Input Mapping Context
        if (APlayerController* PC = Cast<APlayerController>(Controller)) {
            if (UEnhancedInputLocalPlayerSubsystem* Subsystem =
                ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(PC->GetLocalPlayer())) {
                Subsystem->AddMappingContext(DefaultMappingContext, 0);
            }
        }
    }

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override {
        Super::SetupPlayerInputComponent(PlayerInputComponent);

        UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent);
        if (EIC) {
            // Bind actions
            EIC->BindAction(JumpAction, ETriggerEvent::Started, this, &ACharacter::Jump);
            EIC->BindAction(JumpAction, ETriggerEvent::Completed, this, &ACharacter::StopJumping);

            EIC->BindAction(MoveAction, ETriggerEvent::Triggered, this, &AMyCharacter::Move);
            EIC->BindAction(LookAction, ETriggerEvent::Triggered, this, &AMyCharacter::Look);
        }
    }

    void Move(const FInputActionValue& Value) {
        FVector2D MoveVector = Value.Get<FVector2D>();

        if (Controller) {
            AddMovementInput(GetActorForwardVector(), MoveVector.Y);
            AddMovementInput(GetActorRightVector(), MoveVector.X);
        }
    }

    void Look(const FInputActionValue& Value) {
        FVector2D LookVector = Value.Get<FVector2D>();

        if (Controller) {
            AddControllerYawInput(LookVector.X);
            AddControllerPitchInput(LookVector.Y);
        }
    }
};
```

---

## Input Triggers
## 输入触发器

### Trigger Types
### 触发器类型

Input Actions can have triggers to control when they fire:
- **Pressed**: When input starts
- **Released**: When input ends
- **Hold**: Hold for duration
- **Tap**: Quick press
- **Pulse**: Repeated firing while held

Input Action 可带有触发器，用于控制其触发时机：
- **Pressed**：输入开始时
- **Released**：输入结束时
- **Hold**：持续按住一段时间
- **Tap**：快速点按
- **Pulse**：按住期间重复触发

### Add Trigger in Editor
### 在编辑器中添加触发器

1. Open Input Action asset
2. Triggers > Add > Select trigger type (e.g., `Hold`)
3. Configure (e.g., Hold Time = 0.5s)

1. 打开 Input Action 资产
2. Triggers > Add > 选择触发器类型（例如 `Hold`）
3. 配置（例如 Hold Time = 0.5s）

---

## Input Modifiers
## 输入修饰器

### Modifier Types
### 修饰器类型

Modifiers transform input values:
- **Negate**: Flip sign (-1 ↔ 1)
- **Dead Zone**: Ignore small inputs
- **Scalar**: Multiply by value
- **Smooth**: Smoothing over time

修饰器用于变换输入值：
- **Negate**：翻转符号（-1 ↔ 1）
- **Dead Zone**：忽略小幅输入
- **Scalar**：乘以某个值
- **Smooth**：随时间平滑

### Add Modifier in Editor
### 在编辑器中添加修饰器

1. Open Input Action asset
2. Modifiers > Add > Select modifier (e.g., `Negate`)
3. Configure

1. 打开 Input Action 资产
2. Modifiers > Add > 选择修饰器（例如 `Negate`）
3. 配置

---

## Input Mapping Contexts (Context Switching)
## Input Mapping Context（上下文切换）

### Multiple Contexts
### 多个上下文

```cpp
// Define contexts
UPROPERTY(EditAnywhere, Category = "Input")
TObjectPtr<UInputMappingContext> DefaultContext;

UPROPERTY(EditAnywhere, Category = "Input")
TObjectPtr<UInputMappingContext> VehicleContext;

// Switch context
void EnterVehicle() {
    if (APlayerController* PC = Cast<APlayerController>(Controller)) {
        if (UEnhancedInputLocalPlayerSubsystem* Subsystem =
            ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(PC->GetLocalPlayer())) {
            Subsystem->RemoveMappingContext(DefaultContext);
            Subsystem->AddMappingContext(VehicleContext, 0);
        }
    }
}
```

---

## Legacy Input (Deprecated)
## 旧版输入（已弃用）

### Legacy Input Bindings
### 旧版输入绑定

```cpp
// ❌ DEPRECATED: Do not use for new projects

void AMyCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    // Legacy action binding
    PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);

    // Legacy axis binding
    PlayerInputComponent->BindAxis("MoveForward", this, &AMyCharacter::MoveForward);
}

void MoveForward(float Value) {
    AddMovementInput(GetActorForwardVector(), Value);
}
```

**Migration:** Use Enhanced Input instead.

**迁移：** 请改用 Enhanced Input。

---

## Gamepad Input
## 手柄输入

### Gamepad with Enhanced Input
### 使用 Enhanced Input 的手柄输入

```cpp
// Input Mapping Context:
// - IA_Move → Gamepad Left Thumbstick
// - IA_Look → Gamepad Right Thumbstick
// - IA_Jump → Gamepad Face Button Bottom (A/Cross)

// No code changes needed, just add gamepad mappings to Input Mapping Context
```

---

## Touch Input (Mobile)
## 触摸输入（移动端）

### Touch Input with Enhanced Input
### 使用 Enhanced Input 的触摸输入

```cpp
// Input Mapping Context:
// - IA_Move → Touch (virtual thumbstick)
// - IA_Look → Touch (swipe)

// Use Touch Interface asset for virtual controls
```

---

## Rebinding Input at Runtime
## 运行时重绑定输入

### Change Key Mapping
### 更改按键映射

```cpp
#include "PlayerMappableInputConfig.h"

// Get subsystem
UEnhancedInputLocalPlayerSubsystem* Subsystem = /* Get subsystem */;

// Get player mappable keys
FPlayerMappableKeySlot KeySlot = FPlayerMappableKeySlot(/*..*/);
FKey NewKey = EKeys::F; // Rebind to F key

// Apply new mapping
Subsystem->AddPlayerMappedKey(/*..*/);
```

---

## Input Debugging
## 输入调试

### Debug Input
### 调试输入

```cpp
// Console commands:
// showdebug input - Show input debug info

// Log input values:
UE_LOG(LogTemp, Warning, TEXT("Move Input: %s"), *MoveVector.ToString());
```

---

## Common Patterns
## 常见模式

### Check if Key Pressed (Quick & Dirty)
### 检查按键是否按下（快捷做法）

```cpp
// For debugging only (not recommended for gameplay)
if (GetWorld()->GetFirstPlayerController()->IsInputKeyDown(EKeys::SpaceBar)) {
    // Space bar is down
}
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/enhanced-input-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/enhanced-input-action-and-input-mapping-context-in-unreal-engine/
