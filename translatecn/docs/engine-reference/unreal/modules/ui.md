# Unreal Engine 5.8 — UI Module Reference
# Unreal Engine 5.8 — UI 模块参考

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.7-5.8 UMG and CommonUI improvements (Enhanced Input unified with Common UI in 5.8)

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.7-5.8 的 UMG 与 CommonUI 改进（5.8 中 Enhanced Input 与 Common UI 统一）

> **UE 5.8 changes:** Enhanced Input and Common Input/UI are unified (no
> duplicate data assets; Input Debugger for Enhanced Input UI). Slate:
> `EWindowType::GameWindow` → `EWindowType::Normal`; the "OnlyGameWindow" CVars
> are renamed "OnlyProjectContent" and `bDebugGameWindowOnly` is now
> `bDebugProjectContentOnly`; a module depending on `SlateRHIRender` may also
> need `SlateBaseRenderer`. Source: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** Enhanced Input 与 Common Input/UI 已统一（无需重复数据资产；提供面向 Enhanced Input UI 的 Input Debugger）。Slate：
> `EWindowType::GameWindow` → `EWindowType::Normal`；"OnlyGameWindow" 系列的 CVar
> 重命名为 "OnlyProjectContent"，`bDebugGameWindowOnly` 现在为
> `bDebugProjectContentOnly`；依赖 `SlateRHIRender` 的模块可能还需要
> `SlateBaseRenderer`。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

UE 5.8 UI systems:
- **UMG (Unreal Motion Graphics)**: Visual widget-based UI (RECOMMENDED)
- **CommonUI**: Cross-platform input-aware UI framework (console/PC)
- **Slate**: Low-level C++ UI (engine/editor UI)

UE 5.8 UI 系统：
- **UMG（Unreal Motion Graphics）**：基于可视化控件的 UI（推荐）
- **CommonUI**：跨平台、感知输入的 UI 框架（主机/PC）
- **Slate**：底层 C++ UI（引擎/编辑器 UI）

---

## UMG (Unreal Motion Graphics)
## UMG（Unreal Motion Graphics）

### Create Widget Blueprint
### 创建 Widget Blueprint

1. Content Browser > User Interface > Widget Blueprint
2. Open Widget Designer
3. Drag widgets from Palette: Button, Text, Image, ProgressBar, etc.

1. Content Browser > User Interface > Widget Blueprint
2. 打开 Widget Designer
3. 从 Palette 拖入控件：Button、Text、Image、ProgressBar 等

---

## Basic UMG Setup in C++
## C++ 中的基础 UMG 设置

### Create and Display Widget
### 创建并显示控件

```cpp
#include "Blueprint/UserWidget.h"

UPROPERTY(EditAnywhere, Category = "UI")
TSubclassOf<UUserWidget> HealthBarWidgetClass;

void AMyCharacter::BeginPlay() {
    Super::BeginPlay();

    // Create widget
    UUserWidget* HealthBarWidget = CreateWidget<UUserWidget>(GetWorld(), HealthBarWidgetClass);

    // Add to viewport
    HealthBarWidget->AddToViewport();
}
```

### Remove Widget
### 移除控件

```cpp
HealthBarWidget->RemoveFromParent();
```

---

## Access Widget Elements from C++
## 从 C++ 访问控件元素

### Bind to Widget Elements
### 绑定控件元素

```cpp
UCLASS()
class UMyHealthWidget : public UUserWidget {
    GENERATED_BODY()

public:
    // ✅ Bind to widget elements (must match names in Widget Blueprint)
    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UTextBlock> HealthText;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UProgressBar> HealthBar;

    void UpdateHealth(int32 CurrentHealth, int32 MaxHealth) {
        HealthText->SetText(FText::FromString(FString::Printf(TEXT("%d / %d"), CurrentHealth, MaxHealth)));
        HealthBar->SetPercent((float)CurrentHealth / MaxHealth);
    }
};
```

---

## Common UMG Widgets
## 常用 UMG 控件

### Text Block
### Text Block

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UTextBlock> ScoreText;

ScoreText->SetText(FText::FromString(TEXT("Score: 100")));
ScoreText->SetColorAndOpacity(FLinearColor::Green);
```

### Button
### Button

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UButton> PlayButton;

void NativeConstruct() override {
    Super::NativeConstruct();

    // Bind button click
    PlayButton->OnClicked.AddDynamic(this, &UMyMenuWidget::OnPlayClicked);
}

UFUNCTION()
void OnPlayClicked() {
    UE_LOG(LogTemp, Warning, TEXT("Play clicked"));
}
```

### Image
### Image

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UImage> PlayerAvatar;

PlayerAvatar->SetBrushFromTexture(AvatarTexture);
PlayerAvatar->SetColorAndOpacity(FLinearColor::White);
```

### Progress Bar
### Progress Bar

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UProgressBar> HealthBar;

HealthBar->SetPercent(0.75f); // 75%
HealthBar->SetFillColorAndOpacity(FLinearColor::Red);
```

### Slider
### Slider

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<USlider> VolumeSlider;

void NativeConstruct() override {
    Super::NativeConstruct();
    VolumeSlider->OnValueChanged.AddDynamic(this, &UMyWidget::OnVolumeChanged);
}

UFUNCTION()
void OnVolumeChanged(float Value) {
    // Value is 0.0 - 1.0
    UE_LOG(LogTemp, Warning, TEXT("Volume: %f"), Value);
}
```

### EditableTextBox (Input Field)
### EditableTextBox（输入框）

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UEditableTextBox> PlayerNameInput;

void NativeConstruct() override {
    Super::NativeConstruct();
    PlayerNameInput->OnTextChanged.AddDynamic(this, &UMyWidget::OnNameChanged);
}

UFUNCTION()
void OnNameChanged(const FText& Text) {
    FString PlayerName = Text.ToString();
}
```

---

## UMG Animations
## UMG 动画

### Play Animation
### 播放动画

```cpp
UPROPERTY(Transient, meta = (BindWidgetAnim))
TObjectPtr<UWidgetAnimation> FadeInAnimation;

void ShowUI() {
    PlayAnimation(FadeInAnimation);
}
```

### Stop Animation
### 停止动画

```cpp
StopAnimation(FadeInAnimation);
```

---

## Canvas Panel (Layout)
## Canvas Panel（布局）

### Canvas Panel (Absolute Positioning)
### Canvas Panel（绝对定位）

```cpp
// Use in Widget Blueprint for absolute positioning
// Anchor widgets to corners/edges for responsive UI
```

### Vertical Box (Stack Vertically)
### Vertical Box（垂直堆叠）

```cpp
// Auto-stacks children vertically
```

### Horizontal Box (Stack Horizontally)
### Horizontal Box（水平堆叠）

```cpp
// Auto-stacks children horizontally
```

### Grid Panel (Grid Layout)
### Grid Panel（网格布局）

```cpp
// Arranges children in a grid
```

---

## World Space UI (3D UI)
## 世界空间 UI（3D UI）

### Widget Component (3D UI in World)
### Widget Component（世界中的 3D UI）

```cpp
#include "Components/WidgetComponent.h"

UWidgetComponent* HealthBarWidget = CreateDefaultSubobject<UWidgetComponent>(TEXT("HealthBar"));
HealthBarWidget->SetupAttachment(RootComponent);
HealthBarWidget->SetWidgetClass(HealthBarWidgetClass);
HealthBarWidget->SetWidgetSpace(EWidgetSpace::World); // 3D world space
HealthBarWidget->SetDrawSize(FVector2D(200, 50));
```

---

## Input Handling in UMG
## UMG 中的输入处理

### Override Keyboard Input
### 覆盖键盘输入

```cpp
UCLASS()
class UMyWidget : public UUserWidget {
    GENERATED_BODY()

public:
    virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override {
        if (InKeyEvent.GetKey() == EKeys::Escape) {
            // Handle Escape key
            CloseMenu();
            return FReply::Handled();
        }
        return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
    }
};
```

---

## CommonUI (Cross-Platform Input)
## CommonUI（跨平台输入）

### Enable CommonUI Plugin
### 启用 CommonUI 插件

```cpp
// Enable: Edit > Plugins > CommonUI
// Restart editor
```

### Use CommonUI Widgets
### 使用 CommonUI 控件

```cpp
// CommonUI widgets:
// - CommonActivatableWidget: Base for screens/menus
// - CommonButtonBase: Input-aware button (gamepad + mouse)
// - CommonTextBlock: Text with styling
```

### CommonActivatableWidget Example
### CommonActivatableWidget 示例

```cpp
UCLASS()
class UMyMenuWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

public:
    virtual void NativeOnActivated() override {
        Super::NativeOnActivated();
        // Menu activated (shown)
    }

    virtual void NativeOnDeactivated() override {
        Super::NativeOnDeactivated();
        // Menu deactivated (hidden)
    }
};
```

---

## HUD Class (Alternative to UMG)
## HUD 类（UMG 的替代方案）

### Create HUD
### 创建 HUD

```cpp
UCLASS()
class AMyHUD : public AHUD {
    GENERATED_BODY()

public:
    virtual void DrawHUD() override {
        Super::DrawHUD();

        // Draw text
        DrawText(TEXT("Score: 100"), FLinearColor::White, 50, 50);

        // Draw texture
        DrawTexture(CrosshairTexture, Canvas->SizeX / 2, Canvas->SizeY / 2, 32, 32);
    }
};
```

---

## Performance Tips
## 性能建议

### Optimize UMG
### 优化 UMG

```cpp
// Invalidation boxes: Only redraw when content changes
// Add "Invalidation Box" widget to Widget Blueprint

// Disable tick if not needed
bIsFocusable = false;
SetVisibility(ESlateVisibility::Collapsed); // Collapsed = not rendered
```

---

## Debugging
## 调试

### UI Debug Commands
### UI 调试命令

```cpp
// Console commands:
// widget.debug - Show widget hierarchy
// Slate.ShowDebugOutlines 1 - Show widget bounds
// stat slate - Show Slate performance
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/umg-ui-designer-for-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/
