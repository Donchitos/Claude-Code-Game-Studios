# Unreal Engine 5.8 — CommonUI Plugin

**Last verified:** 2026-08-16
**Status:** Production-Ready
**Plugin:** `CommonUI` (built-in, enable in Plugins)

---

## Overview

**CommonUI** is a cross-platform UI framework that automatically handles input routing
for gamepad, mouse, and touch. It's designed for games that need to work seamlessly
across PC, console, and mobile platforms with minimal platform-specific code.

> **UE 5.8 change — Unified Input:** CommonUI input routing is now unified with
> Enhanced Input. One set of Input Actions drives both gameplay and UI; do NOT
> create duplicate CommonUI-specific input data assets. Pre-5.8 guides that show
> separate CommonUI input action data tables are outdated on this point.

**Use CommonUI for:**
- Multi-platform games (console + PC)
- Automatic gamepad/mouse/touch input routing
- Input-agnostic UI (same UI works with any input method)
- Widget focus and navigation
- Action bars and input hints

**DON'T use CommonUI for:**
- PC-only games with mouse-only UI (standard UMG is simpler)
- Simple UI with no navigation requirements

---

## Key Differences from Standard UMG

| Feature | Standard UMG | CommonUI |
|---------|--------------|----------|
| **Input Handling** | Manual per widget | Automatic routing |
| **Focus Management** | Basic | Advanced navigation |
| **Platform Switching** | Manual detection | Automatic |
| **Input Prompts** | Hardcode icons | Dynamic per platform |
| **Screen Stack** | Manual | Built-in activatable widgets |

---

## Setup

### 1. Enable Plugin

`Edit > Plugins > CommonUI > Enabled > Restart`

### 2. Configure Project Settings

`Project Settings > Plugins > CommonUI`:
- **Default Input Type**: Gamepad (or auto-detect)
- **Platform-Specific Settings**: Configure input icons per platform

### 3. Create Common Input Settings Asset

1. Content Browser > Input > Common Input Settings
2. Configure input data per platform:
   - Default Gamepad Data
   - Default Mouse & Keyboard Data
   - Default Touch Data

---

## Core Widgets

### CommonActivatableWidget (Screen Management)

Base class for screens/menus that can be activated/deactivated.

```cpp
#include "CommonActivatableWidget.h"

UCLASS()
class UMyMenuWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

protected:
    virtual void NativeOnActivated() override {
        Super::NativeOnActivated();
        // Menu is now visible and focused
        UE_LOG(LogTemp, Warning, TEXT("Menu activated"));
    }

    virtual void NativeOnDeactivated() override {
        Super::NativeOnDeactivated();
        // Menu is now hidden
        UE_LOG(LogTemp, Warning, TEXT("Menu deactivated"));
    }

    virtual UWidget* NativeGetDesiredFocusTarget() const override {
        // Return widget that should receive focus (e.g., first button)
        return PlayButton;
    }

private:
    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UCommonButtonBase> PlayButton;
};
```

---

### CommonButtonBase (Input-Aware Button)

Replaces standard UMG Button. Automatically handles gamepad/mouse/keyboard input.

```cpp
#include "CommonButtonBase.h"

UCLASS()
class UMyMenuWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

protected:
    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UCommonButtonBase> PlayButton;

    virtual void NativeConstruct() override {
        Super::NativeConstruct();

        // Bind button click (works with any input method)
        PlayButton->OnClicked().AddUObject(this, &UMyMenuWidget::OnPlayClicked);

        // Set button text
        PlayButton->SetButtonText(FText::FromString(TEXT("Play")));
    }

    void OnPlayClicked() {
        UE_LOG(LogTemp, Warning, TEXT("Play clicked"));
    }
};
```

---

### CommonTextBlock (Styled Text)

Text widget with CommonUI styling support.

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonTextBlock> TitleText;

TitleText->SetText(FText::FromString(TEXT("Main Menu")));
```

---

### CommonActionWidget (Input Prompts)

Displays input prompts (e.g., "Press A to Continue", automatically shows correct button icon).

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonActionWidget> ConfirmActionWidget;

// Bind to input action
ConfirmActionWidget->SetInputAction(ConfirmInputActionData);
// Automatically shows correct icon (A on Xbox, X on PlayStation, Enter on PC)
```

---

## Widget Stack (Screen Management)

### CommonActivatableWidgetStack

Manages a stack of screens (e.g., Main Menu → Settings → Controls).

```cpp
#include "Widgets/CommonActivatableWidgetContainer.h"

UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonActivatableWidgetStack> WidgetStack;

// Push new screen onto stack
void ShowSettingsMenu() {
    WidgetStack->AddWidget(USettingsMenuWidget::StaticClass());
}

// Pop current screen (go back)
void GoBack() {
    WidgetStack->DeactivateWidget();
}
```

---

## Input Actions (CommonUI Style)

### Define Input Actions

Create **Common Input Action Data Table**:
1. Content Browser > Miscellaneous > Data Table
2. Row Structure: `CommonInputActionDataBase`
3. Add rows for actions (Confirm, Cancel, Navigate, etc.)

Example row:
- **Action Name**: Confirm
- **Default Input**: Gamepad Face Button Bottom (A/Cross)
- **Alternate Inputs**: Enter (keyboard), Left Mouse Button

---

### Bind Input Actions in Widget

```cpp
#include "Input/CommonUIActionRouterBase.h"

UCLASS()
class UMyWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

protected:
    virtual void NativeOnActivated() override {
        Super::NativeOnActivated();

        // Bind input action
        FBindUIActionArgs BindArgs(ConfirmInputAction, FSimpleDelegate::CreateUObject(this, &UMyWidget::OnConfirm));
        BindArgs.bDisplayInActionBar = true; // Show in action bar
        RegisterUIActionBinding(BindArgs);
    }

    void OnConfirm() {
        UE_LOG(LogTemp, Warning, TEXT("Confirmed"));
    }

private:
    UPROPERTY(EditDefaultsOnly, Category = "Input")
    FDataTableRowHandle ConfirmInputAction;
};
```

---

## Focus & Navigation

### Automatic Gamepad Navigation

CommonUI automatically handles gamepad navigation (D-Pad/Stick to move between buttons).

```cpp
// In Widget Blueprint:
// - Widgets are automatically navigable if they inherit from CommonButton/CommonUserWidget
// - Focus order is determined by widget hierarchy and layout
```

### Custom Focus Navigation

```cpp
// Override focus navigation
virtual UWidget* NativeGetDesiredFocusTarget() const override {
    return FirstButton; // Return widget that should receive focus
}
```

---

## Input Mode (Game vs UI)

### Switch Input Mode

```cpp
#include "CommonUIExtensions.h"

// Switch to UI-only mode (pause game, show cursor)
UCommonUIExtensions::PushStreamedGameplayUIInputConfig(this, FrontendInputConfig);

// Return to game mode (hide cursor, resume gameplay)
UCommonUIExtensions::PopInputConfig(this);
```

---

## Platform-Specific Input Icons

### Configure Input Icons

1. Create **Common Input Base Controller Data** asset for each platform:
   - Gamepad (Xbox, PlayStation, Switch)
   - Mouse & Keyboard
   - Touch

2. Assign platform-specific icons:
   - Gamepad Face Button Bottom: `A` (Xbox), `Cross` (PlayStation)
   - Confirm Key: `Enter` icon

3. Assign to **Common Input Settings** asset

### Automatically Display Correct Icons

```cpp
// CommonActionWidget automatically shows correct icon for current platform
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonActionWidget> JumpActionWidget;

JumpActionWidget->SetInputAction(JumpInputActionData);
// Shows "A" on Xbox, "Cross" on PlayStation, "Space" on PC
```

---

## Common Patterns

### Main Menu with Navigation

```cpp
UCLASS()
class UMainMenuWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

protected:
    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UCommonButtonBase> PlayButton;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UCommonButtonBase> SettingsButton;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UCommonButtonBase> QuitButton;

    virtual void NativeConstruct() override {
        Super::NativeConstruct();

        PlayButton->OnClicked().AddUObject(this, &UMainMenuWidget::OnPlayClicked);
        SettingsButton->OnClicked().AddUObject(this, &UMainMenuWidget::OnSettingsClicked);
        QuitButton->OnClicked().AddUObject(this, &UMainMenuWidget::OnQuitClicked);
    }

    virtual UWidget* NativeGetDesiredFocusTarget() const override {
        return PlayButton; // Focus "Play" button when menu opens
    }

    void OnPlayClicked() { /* Start game */ }
    void OnSettingsClicked() { /* Open settings */ }
    void OnQuitClicked() { /* Quit game */ }
};
```

---

### Pause Menu with Back Action

```cpp
UCLASS()
class UPauseMenuWidget : public UCommonActivatableWidget {
    GENERATED_BODY()

protected:
    UPROPERTY(EditDefaultsOnly, Category = "Input")
    FDataTableRowHandle BackInputAction; // Assign "Cancel" action in Blueprint

    virtual void NativeOnActivated() override {
        Super::NativeOnActivated();

        // Bind "Back" input (B/Circle/Escape)
        FBindUIActionArgs BindArgs(BackInputAction, FSimpleDelegate::CreateUObject(this, &UPauseMenuWidget::OnBack));
        RegisterUIActionBinding(BindArgs);
    }

    void OnBack() {
        DeactivateWidget(); // Close pause menu
    }
};
```

---

## Performance Tips

- Use **CommonActivatableWidgetStack** for screen management (automatically handles activation/deactivation)
- Avoid creating/destroying widgets every frame (reuse widgets)
- Use **Lazy Widgets** for complex menus (only create when needed)

---

## Debugging

### CommonUI Debug Commands

```cpp
// Console commands:
// CommonUI.DumpActivatableTree - Show active widget hierarchy
// CommonUI.DumpActionBindings - Show registered input actions
```

---

## Sources
- https://docs.unrealengine.com/5.8/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/commonui-quickstart-guide-for-unreal-engine/
