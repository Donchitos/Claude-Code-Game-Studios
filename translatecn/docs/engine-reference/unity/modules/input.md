# Unity 6.3 — Input Module Reference
# Unity 6.3 — 输入模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 uses new Input System (legacy Input deprecated)
**知识盲区：** Unity 6 使用新的 Input System（旧版 Input 已弃用）

---

## Overview
## 概述

Unity 6 input systems:
- **Input System Package** (RECOMMENDED): Cross-platform, rebindable, modern
- **Legacy Input Manager**: Deprecated, avoid for new projects

Unity 6 输入系统：
- **Input System 包（推荐）**：跨平台、可重绑定、现代化
- **旧版 Input Manager**：已弃用，新项目应避免使用

---

## Key Changes from 2022 LTS
## 相对 2022 LTS 的关键变更

### Legacy Input Deprecated in Unity 6
### Unity 6 中旧版输入已弃用

```csharp
// ❌ DEPRECATED: Input class
if (Input.GetKeyDown(KeyCode.Space)) { }

// ✅ NEW: Input System package
using UnityEngine.InputSystem;
if (Keyboard.current.spaceKey.wasPressedThisFrame) { }
```

**Migration Required:** Install `com.unity.inputsystem` package.

**需要迁移：** 安装 `com.unity.inputsystem` 包。

---

## Input System Package Setup
## Input System 包设置

### Installation
### 安装
1. `Window > Package Manager`
2. Search "Input System"
3. Install package
4. Restart Unity when prompted

1. `Window > Package Manager`
2. 搜索 "Input System"
3. 安装包
4. 按提示重启 Unity

### Enable New Input System
### 启用新 Input System
`Edit > Project Settings > Player > Active Input Handling`:
- **Input System Package (New)** ✅ Recommended
- **Both** (for migration period)

`Edit > Project Settings > Player > Active Input Handling`：
- **Input System Package (New)** ✅ 推荐
- **Both**（迁移期间使用）

---

## Input Actions (Recommended Pattern)
## Input Actions（推荐模式）

### Create Input Actions Asset
### 创建 Input Actions 资源

1. `Assets > Create > Input Actions`
2. Name it (e.g., "PlayerControls")
3. Open asset, define actions:

1. `Assets > Create > Input Actions`
2. 命名（例如 "PlayerControls"）
3. 打开资源，定义动作（action）：

```
Action Maps:
  Gameplay
    Actions:
      - Move (Value, Vector2)
      - Jump (Button)
      - Fire (Button)
      - Look (Value, Vector2)
```

4. **Generate C# Class**: Check "Generate C# Class" in Inspector
5. Click "Apply"

4. **生成 C# 类**：在 Inspector 中勾选 "Generate C# Class"
5. 单击 "Apply"

### Use Generated Input Class
### 使用生成的 Input 类

```csharp
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour {
    private PlayerControls controls;

    void Awake() {
        controls = new PlayerControls();

        // Subscribe to actions
        controls.Gameplay.Jump.performed += ctx => Jump();
        controls.Gameplay.Fire.performed += ctx => Fire();
    }

    void OnEnable() => controls.Enable();
    void OnDisable() => controls.Disable();

    void Update() {
        // Read continuous input
        Vector2 move = controls.Gameplay.Move.ReadValue<Vector2>();
        transform.Translate(new Vector3(move.x, 0, move.y) * Time.deltaTime);

        Vector2 look = controls.Gameplay.Look.ReadValue<Vector2>();
        // Apply camera rotation
    }

    void Jump() {
        Debug.Log("Jump!");
    }

    void Fire() {
        Debug.Log("Fire!");
    }
}
```

---

## Direct Device Access (Quick & Dirty)
## 直接访问设备（快速简易方式）

### Keyboard
### 键盘

```csharp
using UnityEngine.InputSystem;

void Update() {
    // Current state
    if (Keyboard.current.spaceKey.isPressed) { }

    // Just pressed this frame
    if (Keyboard.current.spaceKey.wasPressedThisFrame) { }

    // Just released this frame
    if (Keyboard.current.spaceKey.wasReleasedThisFrame) { }
}
```

### Mouse
### 鼠标

```csharp
using UnityEngine.InputSystem;

void Update() {
    // Mouse position
    Vector2 mousePos = Mouse.current.position.ReadValue();

    // Mouse delta (movement)
    Vector2 mouseDelta = Mouse.current.delta.ReadValue();

    // Mouse buttons
    if (Mouse.current.leftButton.wasPressedThisFrame) { }
    if (Mouse.current.rightButton.isPressed) { }

    // Scroll wheel
    Vector2 scroll = Mouse.current.scroll.ReadValue();
}
```

### Gamepad
### 手柄

```csharp
using UnityEngine.InputSystem;

void Update() {
    Gamepad gamepad = Gamepad.current;
    if (gamepad == null) return; // No gamepad connected

    // Buttons
    if (gamepad.buttonSouth.wasPressedThisFrame) { } // A/Cross
    if (gamepad.buttonWest.wasPressedThisFrame) { }  // X/Square

    // Sticks
    Vector2 leftStick = gamepad.leftStick.ReadValue();
    Vector2 rightStick = gamepad.rightStick.ReadValue();

    // Triggers
    float leftTrigger = gamepad.leftTrigger.ReadValue();
    float rightTrigger = gamepad.rightTrigger.ReadValue();

    // D-Pad
    Vector2 dpad = gamepad.dpad.ReadValue();
}
```

### Touch (Mobile)
### 触摸（移动端）

```csharp
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;

void OnEnable() {
    EnhancedTouchSupport.Enable();
}

void Update() {
    foreach (var touch in UnityEngine.InputSystem.EnhancedTouch.Touch.activeTouches) {
        Debug.Log($"Touch at {touch.screenPosition}");
    }
}
```

---

## Input Action Callbacks
## Input Action 回调

### Action Callbacks (Event-Driven)
### 动作回调（事件驱动）

```csharp
// started: Input began (e.g., trigger pressed slightly)
controls.Gameplay.Fire.started += ctx => Debug.Log("Fire started");

// performed: Input action triggered (e.g., button fully pressed)
controls.Gameplay.Fire.performed += ctx => Debug.Log("Fire performed");

// canceled: Input released or interrupted
controls.Gameplay.Fire.canceled += ctx => Debug.Log("Fire canceled");
```

### Context Data
### 上下文数据

```csharp
controls.Gameplay.Move.performed += ctx => {
    Vector2 value = ctx.ReadValue<Vector2>();
    float duration = ctx.duration; // How long input held
    InputControl control = ctx.control; // Which device/control triggered it
};
```

---

## Control Schemes & Device Switching
## 控制方案与设备切换

### Define Control Schemes in Input Actions Asset
### 在 Input Actions 资源中定义控制方案

```
Control Schemes:
  - Keyboard&Mouse (Keyboard, Mouse)
  - Gamepad (Gamepad)
  - Touch (Touchscreen)
```

### Auto-Switch on Device Change
### 设备变更时自动切换

```csharp
controls.Gameplay.Move.performed += ctx => {
    if (ctx.control.device is Keyboard) {
        Debug.Log("Using keyboard");
    } else if (ctx.control.device is Gamepad) {
        Debug.Log("Using gamepad");
    }
};
```

---

## Rebinding (Runtime Key Mapping)
## 重绑定（运行时按键映射）

### Interactive Rebind
### 交互式重绑定

```csharp
using UnityEngine.InputSystem;

public void RebindJumpKey() {
    var rebindOperation = controls.Gameplay.Jump.PerformInteractiveRebinding()
        .WithControlsExcluding("Mouse") // Exclude mouse bindings
        .OnComplete(operation => {
            Debug.Log("Rebind complete");
            operation.Dispose();
        })
        .Start();
}
```

### Save/Load Bindings
### 保存/加载绑定

```csharp
// Save
string rebinds = controls.SaveBindingOverridesAsJson();
PlayerPrefs.SetString("InputBindings", rebinds);

// Load
string rebinds = PlayerPrefs.GetString("InputBindings");
controls.LoadBindingOverridesFromJson(rebinds);
```

---

## Action Types
## 动作类型

### Button (Press/Release)
### Button（按下/松开）
- Single press/release
- Example: Jump, Fire

- 单次按下/松开
- 示例：Jump、Fire

### Value (Continuous)
### Value（连续值）
- Continuous value (float, Vector2)
- Example: Move, Look, Aim

- 连续值（float、Vector2）
- 示例：Move、Look、Aim

### Pass-Through (Immediate)
### Pass-Through（即时）
- No processing, immediate value
- Example: Mouse position

- 不经处理，即时取值
- 示例：鼠标位置

---

## Processors (Input Modifiers)
## 处理器（输入修饰器）

### Scale
### Scale（缩放）

```csharp
// In Input Actions asset: Action > Properties > Processors > Add > Scale
// Multiply input by value (e.g., invert Y-axis)
```

### Invert
### Invert（反转）

```csharp
// In Input Actions asset: Action > Properties > Processors > Add > Invert
// Flip input sign
```

### Dead Zone
### Dead Zone（死区）

```csharp
// In Input Actions asset: Action > Properties > Processors > Add > Stick Deadzone
// Ignore small stick movements
```

---

## PlayerInput Component (Simplified Setup)
## PlayerInput 组件（简化设置）

### Automatic Input Setup
### 自动输入设置

```csharp
// Add Component: Player Input
// Assign Input Actions asset
// Behavior: Send Messages / Invoke Unity Events / Invoke C# Events

// Send Messages example:
public class Player : MonoBehaviour {
    public void OnMove(InputValue value) {
        Vector2 move = value.Get<Vector2>();
        // Handle movement
    }

    public void OnJump(InputValue value) {
        if (value.isPressed) {
            Jump();
        }
    }
}
```

---

## Debugging
## 调试

### Input Debugger
### Input 调试器
- `Window > Analysis > Input Debugger`
- See active devices, input values, action states

- `Window > Analysis > Input Debugger`
- 查看活动设备、输入值、动作状态

---

## Sources
## 来源
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/QuickStartGuide.html
