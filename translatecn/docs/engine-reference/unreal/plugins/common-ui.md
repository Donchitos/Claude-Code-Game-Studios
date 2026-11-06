# Unreal Engine 5.8 — CommonUI Plugin
# Unreal Engine 5.8 — CommonUI 插件

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Status:** Production-Ready
**Plugin:** `CommonUI` (built-in, enable in Plugins)

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**状态：** 生产就绪
**插件：** `CommonUI`（内置，在 Plugins 中启用）

> **UE 5.8 changes:** Common Input/UI and Enhanced Input are unified, which
> "removes the need for duplicate data assets", with more reliable event
> processing, better widget binding and an Input Debugger for Enhanced Input
> UI. CommonUI tags are now comparable in Blueprint. The `CommonUI.uplugin` in a
> 5.8.1 install carries no Beta/Experimental flag. Source: UE 5.8 release
> notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** Common Input/UI 与 Enhanced Input 已统一，这"消除了对重复数据资产的需求"，事件处理更可靠、控件绑定更好，并提供了面向 Enhanced Input UI 的 Input Debugger。CommonUI 标签现在可在蓝图中比较。5.8.1 安装中的 `CommonUI.uplugin` 不带 Beta/Experimental 标记。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

**CommonUI** is a cross-platform UI framework that automatically handles input routing
for gamepad, mouse, and touch. It's designed for games that need to work seamlessly
across PC, console, and mobile platforms with minimal platform-specific code.

**CommonUI** 是一个跨平台 UI 框架，可自动处理手柄、鼠标与触摸的输入路由。它面向需要在 PC、主机与移动平台之间无缝运行、且尽量少写平台特定代码的游戏。

**Use CommonUI for:**
- Multi-platform games (console + PC)
- Automatic gamepad/mouse/touch input routing
- Input-agnostic UI (same UI works with any input method)
- Widget focus and navigation
- Action bars and input hints

**使用 CommonUI 的场景：**
- 多平台游戏（主机 + PC）
- 自动路由手柄/鼠标/触摸输入
- 与输入方式无关的 UI（同一套 UI 适用于任何输入方式）
- 控件焦点与导航
- 动作栏与输入提示

**DON'T use CommonUI for:**
- PC-only games with mouse-only UI (standard UMG is simpler)
- Simple UI with no navigation requirements

**不要使用 CommonUI 的场景：**
- 仅面向 PC、只用鼠标操作的 UI 游戏（标准 UMG 更简单）
- 无导航需求的简单 UI

---

## Key Differences from Standard UMG
## 与标准 UMG 的主要区别

| Feature | Standard UMG | CommonUI |
|---------|--------------|----------|
| **Input Handling** | Manual per widget | Automatic routing |
| **Focus Management** | Basic | Advanced navigation |
| **Platform Switching** | Manual detection | Automatic |
| **Input Prompts** | Hardcode icons | Dynamic per platform |
| **Screen Stack** | Manual | Built-in activatable widgets |

| 功能 | 标准 UMG | CommonUI |
|---------|--------------|----------|
| **输入处理** | 每个控件手动处理 | 自动路由 |
| **焦点管理** | 基础 | 高级导航 |
| **平台切换** | 手动检测 | 自动 |
| **输入提示** | 硬编码图标 | 按平台动态显示 |
| **界面栈** | 手动 | 内置可激活控件 |

---

## Setup
## 设置

### 1. Enable Plugin
### 1. 启用插件

`Edit > Plugins > CommonUI > Enabled > Restart`

`Edit > Plugins > CommonUI > Enabled > Restart`

### 2. Configure Project Settings
### 2. 配置项目设置

`Project Settings > Plugins > CommonUI`:
- **Default Input Type**: Gamepad (or auto-detect)
- **Platform-Specific Settings**: Configure input icons per platform

`Project Settings > Plugins > CommonUI`：
- **Default Input Type**：Gamepad（或自动检测）
- **Platform-Specific Settings**：按平台配置输入图标

### 3. Create Common Input Settings Asset
### 3. 创建 Common Input Settings 资产

1. Content Browser > Input > Common Input Settings
2. Configure input data per platform:
   - Default Gamepad Data
   - Default Mouse & Keyboard Data
   - Default Touch Data

1. Content Browser > Input > Common Input Settings
2. 按平台配置输入数据：
   - Default Gamepad Data
   - Default Mouse & Keyboard Data
   - Default Touch Data

---

## Core Widgets
## 核心控件

### CommonActivatableWidget (Screen Management)
### CommonActivatableWidget（界面管理）

Base class for screens/menus that can be activated/deactivated.

可被激活/停用的界面或菜单的基类。

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
### CommonButtonBase（感知输入的按钮）

Replaces standard UMG Button. Automatically handles gamepad/mouse/keyboard input.

取代标准 UMG Button。自动处理手柄/鼠标/键盘输入。

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
### CommonTextBlock（带样式的文本）

Text widget with CommonUI styling support.

支持 CommonUI 样式的文本控件。

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonTextBlock> TitleText;

TitleText->SetText(FText::FromString(TEXT("Main Menu")));
```

---

### CommonActionWidget (Input Prompts)
### CommonActionWidget（输入提示）

Displays input prompts (e.g., "Press A to Continue", automatically shows correct button icon).

显示输入提示（例如"Press A to Continue"，会自动显示正确的按钮图标）。

```cpp
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonActionWidget> ConfirmActionWidget;

// Bind to input action
ConfirmActionWidget->SetInputAction(ConfirmInputActionData);
// Automatically shows correct icon (A on Xbox, X on PlayStation, Enter on PC)
```

---

## Widget Stack (Screen Management)
## 控件栈（界面管理）

### CommonActivatableWidgetStack
### CommonActivatableWidgetStack

Manages a stack of screens (e.g., Main Menu → Settings → Controls).

管理界面栈（例如 主菜单 → 设置 → 控制）。

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
## 输入动作（CommonUI 风格）

### Define Input Actions
### 定义输入动作

Create **Common Input Action Data Table**:
1. Content Browser > Miscellaneous > Data Table
2. Row Structure: `CommonInputActionDataBase`
3. Add rows for actions (Confirm, Cancel, Navigate, etc.)

创建 **Common Input Action Data Table**：
1. Content Browser > Miscellaneous > Data Table
2. Row Structure：`CommonInputActionDataBase`
3. 为各动作添加行（Confirm、Cancel、Navigate 等）

Example row:
- **Action Name**: Confirm
- **Default Input**: Gamepad Face Button Bottom (A/Cross)
- **Alternate Inputs**: Enter (keyboard), Left Mouse Button

示例行：
- **Action Name**：Confirm
- **Default Input**：Gamepad Face Button Bottom（A/Cross）
- **Alternate Inputs**：Enter（键盘）、鼠标左键

---

### Bind Input Actions in Widget
### 在控件中绑定输入动作

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
## 焦点与导航

### Automatic Gamepad Navigation
### 自动手柄导航

CommonUI automatically handles gamepad navigation (D-Pad/Stick to move between buttons).

CommonUI 自动处理手柄导航（用 D-Pad/摇杆在按钮之间移动）。

```cpp
// In Widget Blueprint:
// - Widgets are automatically navigable if they inherit from CommonButton/CommonUserWidget
// - Focus order is determined by widget hierarchy and layout
```

### Custom Focus Navigation
### 自定义焦点导航

```cpp
// Override focus navigation
virtual UWidget* NativeGetDesiredFocusTarget() const override {
    return FirstButton; // Return widget that should receive focus
}
```

---

## Input Mode (Game vs UI)
## 输入模式（游戏 vs UI）

### Switch Input Mode
### 切换输入模式

```cpp
#include "CommonUIExtensions.h"

// Switch to UI-only mode (pause game, show cursor)
UCommonUIExtensions::PushStreamedGameplayUIInputConfig(this, FrontendInputConfig);

// Return to game mode (hide cursor, resume gameplay)
UCommonUIExtensions::PopInputConfig(this);
```

---

## Platform-Specific Input Icons
## 平台特定的输入图标

### Configure Input Icons
### 配置输入图标

1. Create **Common Input Base Controller Data** asset for each platform:
   - Gamepad (Xbox, PlayStation, Switch)
   - Mouse & Keyboard
   - Touch

2. Assign platform-specific icons:
   - Gamepad Face Button Bottom: `A` (Xbox), `Cross` (PlayStation)
   - Confirm Key: `Enter` icon

3. Assign to **Common Input Settings** asset

1. 为每个平台创建 **Common Input Base Controller Data** 资产：
   - 手柄（Xbox、PlayStation、Switch）
   - 鼠标与键盘
   - 触摸

2. 分配平台特定的图标：
   - Gamepad Face Button Bottom：`A`（Xbox）、`Cross`（PlayStation）
   - 确认键：`Enter` 图标

3. 分配给 **Common Input Settings** 资产

### Automatically Display Correct Icons
### 自动显示正确的图标

```cpp
// CommonActionWidget automatically shows correct icon for current platform
UPROPERTY(meta = (BindWidget))
TObjectPtr<UCommonActionWidget> JumpActionWidget;

JumpActionWidget->SetInputAction(JumpInputActionData);
// Shows "A" on Xbox, "Cross" on PlayStation, "Space" on PC
```

---

## Common Patterns
## 常见模式

### Main Menu with Navigation
### 带导航的主菜单

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
### 带返回操作的暂停菜单

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
## 性能建议

- Use **CommonActivatableWidgetStack** for screen management (automatically handles activation/deactivation)
- Avoid creating/destroying widgets every frame (reuse widgets)
- Use **Lazy Widgets** for complex menus (only create when needed)

- 使用 **CommonActivatableWidgetStack** 管理界面（自动处理激活/停用）
- 避免每帧创建/销毁控件（应复用控件）
- 复杂菜单使用 **Lazy Widgets**（仅在需要时创建）

---

## Debugging
## 调试

### CommonUI Debug Commands
### CommonUI 调试命令

```cpp
// Console commands:
// CommonUI.DumpActivatableTree - Show active widget hierarchy
// CommonUI.DumpActionBindings - Show registered input actions
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/commonui-quickstart-guide-for-unreal-engine/
