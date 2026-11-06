# Godot Input — Quick Reference
# Godot 输入 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

### 4.7 Changes
### 4.7 变更
- **Mouse and keyboard device IDs**: `InputEvent.device` is
  `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (was `0`, which some
  joypads also use). Identify events by type, not `device == 0` (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- **鼠标和键盘设备 ID**：`InputEvent.device` 为 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`（原为 `0`，而某些手柄也使用 `0`）。请按事件类型识别，而非 `device == 0`（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）
- **`VirtualJoystick` node**: on-screen joystick with Fixed, Dynamic and
  Following modes
- **`VirtualJoystick` 节点**：屏幕上的摇杆，具有 Fixed、Dynamic 和 Following 模式
- **Gamepad gyro and accelerometer** readings are available (4.7 release notes: https://godotengine.org/releases/4.7/)
- **手柄陀螺仪和加速度计**的读数可用（4.7 发行说明：https://godotengine.org/releases/4.7/）

### 4.6 Changes
### 4.6 变更
- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
- **双焦点系统**：鼠标/触摸焦点现在与键盘/手柄焦点分离
  - Visual feedback differs by input method
  - 视觉反馈因输入方式而异
  - Custom focus implementations may need updating
  - 自定义焦点实现可能需要更新
- **Select Mode keybind changed**: "Select Mode" is now `v` key; old mode renamed "Transform Mode" (`q` key)
- **Select Mode 快捷键变更**："Select Mode" 现在为 `v` 键；旧模式更名为 "Transform Mode"（`q` 键）

### 4.5 Changes
### 4.5 变更
- **SDL3 gamepad driver**: Gamepad handling delegated to SDL library for better cross-platform support
- **SDL3 手柄驱动**：将手柄处理委托给 SDL 库，以获得更好的跨平台支持
- **Recursive Control disable**: Single property disables mouse/focus for entire node hierarchies
- **递归禁用 Control**：单个属性即可禁用整个节点层级的鼠标/焦点

### 4.3 Changes (in training data)
### 4.3 变更（在训练数据中）
- **InputEventShortcut**: Dedicated event type for menu shortcuts (optional)
- **InputEventShortcut**：用于菜单快捷键的专用事件类型（可选）

## Current API Patterns
## 当前 API 模式

### Input Actions (unchanged)
### 输入动作（未变）
```gdscript
func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector(
        &"move_left", &"move_right", &"move_forward", &"move_back"
    )
    if Input.is_action_just_pressed(&"jump"):
        jump()
```

### Input Events (unchanged)
### 输入事件（未变）
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            handle_click(event.position)
    elif event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            toggle_pause()
```

### Focus Management (4.6 — CHANGED)
### 焦点管理（4.6 — 已变更）
```gdscript
# Mouse/touch and keyboard/gamepad focus are now SEPARATE
# Visual styles may differ depending on which input method is active
# If you have custom focus drawing, test with both input methods

# Standard approach still works:
func _ready() -> void:
    %StartButton.grab_focus()  # Keyboard/gamepad focus

# But be aware: mouse hover focus != keyboard focus in 4.6
```

### Gamepad (4.5+ — SDL3 backend)
### 手柄（4.5+ — SDL3 后端）
```gdscript
# API unchanged, but SDL3 provides:
# - Better device detection across platforms
# - Improved rumble support
# - More consistent button mapping

func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton:
        if event.button_index == JOY_BUTTON_A and event.pressed:
            confirm_selection()
```

## Common Mistakes
## 常见错误
- Not testing both mouse and keyboard focus paths (dual-focus in 4.6)
- 未同时测试鼠标和键盘两条焦点路径（4.6 中的双焦点）
- Assuming `grab_focus()` affects mouse focus (it only affects keyboard/gamepad in 4.6)
- 误以为 `grab_focus()` 会影响鼠标焦点（在 4.6 中它只影响键盘/手柄）
- Using string literals instead of `StringName` (`&"action"`) for action names in hot paths
- 在热路径中使用字符串字面量而非 `StringName`（`&"action"`）来表示动作名称
