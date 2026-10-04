# Unreal Engine 5.8 — UI Module Reference

**Last verified:** 2026-08-16
**Knowledge Gap:** UMG and CommonUI improvements; CommonUI input unified with Enhanced Input in 5.8

---

## Overview

UE 5.8 UI systems:
- **UMG (Unreal Motion Graphics)**: Visual widget-based UI (RECOMMENDED)
- **CommonUI**: Cross-platform input-aware UI framework (console/PC) — input unified with Enhanced Input in 5.8
- **Slate**: Low-level C++ UI (engine/editor UI)

---

## What's New in UE 5.8

- **Unified input**: CommonUI input routing now runs through Enhanced Input — one set of Input Actions for gameplay and UI, no duplicate input data assets
- Subtitle UI: new `QueueSingleSubtitle()` / `QueueSubtitlesFromAsset()` APIs (Beta) with per-platform overrides

---

## UMG (Unreal Motion Graphics)

### Create Widget Blueprint

1. Content Browser > User Interface > Widget Blueprint
2. Open Widget Designer
3. Drag widgets from Palette: Button, Text, Image, ProgressBar, etc.

---

## Basic UMG Setup in C++

### Create and Display Widget

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

```cpp
HealthBarWidget->RemoveFromParent();
```

---

## Access Widget Elements from C++

### Bind to Widget Elements

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

### Text Block

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UTextBlock> ScoreText;

ScoreText->SetText(FText::FromString(TEXT("Score: 100")));
ScoreText->SetColorAndOpacity(FLinearColor::Green);
```

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

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UImage> PlayerAvatar;

PlayerAvatar->SetBrushFromTexture(AvatarTexture);
PlayerAvatar->SetColorAndOpacity(FLinearColor::White);
```

### Progress Bar

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UProgressBar> HealthBar;

HealthBar->SetPercent(0.75f); // 75%
HealthBar->SetFillColorAndOpacity(FLinearColor::Red);
```

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

### Play Animation

```cpp
UPROPERTY(Transient, meta = (BindWidgetAnim))
TObjectPtr<UWidgetAnimation> FadeInAnimation;

void ShowUI() {
    PlayAnimation(FadeInAnimation);
}
```

### Stop Animation

```cpp
StopAnimation(FadeInAnimation);
```

---

## Canvas Panel (Layout)

### Canvas Panel (Absolute Positioning)

```cpp
// Use in Widget Blueprint for absolute positioning
// Anchor widgets to corners/edges for responsive UI
```

### Vertical Box (Stack Vertically)

```cpp
// Auto-stacks children vertically
```

### Horizontal Box (Stack Horizontally)

```cpp
// Auto-stacks children horizontally
```

### Grid Panel (Grid Layout)

```cpp
// Arranges children in a grid
```

---

## World Space UI (3D UI)

### Widget Component (3D UI in World)

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

### Override Keyboard Input

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

### Enable CommonUI Plugin

```cpp
// Enable: Edit > Plugins > CommonUI
// Restart editor
```

### Use CommonUI Widgets

```cpp
// CommonUI widgets:
// - CommonActivatableWidget: Base for screens/menus
// - CommonButtonBase: Input-aware button (gamepad + mouse)
// - CommonTextBlock: Text with styling
```

### CommonActivatableWidget Example

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

### Create HUD

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

### Optimize UMG

```cpp
// Invalidation boxes: Only redraw when content changes
// Add "Invalidation Box" widget to Widget Blueprint

// Disable tick if not needed
bIsFocusable = false;
SetVisibility(ESlateVisibility::Collapsed); // Collapsed = not rendered
```

---

## Debugging

### UI Debug Commands

```cpp
// Console commands:
// widget.debug - Show widget hierarchy
// Slate.ShowDebugOutlines 1 - Show widget bounds
// stat slate - Show Slate performance
```

---

## Sources
- https://docs.unrealengine.com/5.8/en-US/umg-ui-designer-for-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/
