# Godot Input — Quick Reference

Last verified: 2026-08-14 | Engine: Godot 4.7.1

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **内置 `VirtualJoystick` 节点**：Fixed / Dynamic / Following 三模式。移动端摇杆无需自造或第三方插件。
  - 对本项目"虚拟摇杆移动"直接可用
- **鼠标/键盘 device ID 变更**：从 `0` 改为 `InputEvent.DEVICE_ID_MOUSE` / `InputEvent.DEVICE_ID_KEYBOARD`（因某些手柄可能用 0 作 ID）
  - 判断鼠标/键盘时用这些常量，**不要**用 `event.device == 0`
- **"失焦忽略手柄"项目设置**：默认关。开启后窗口失焦时不接收手柄输入。
- **键盘/鼠标带设备 ID**：为未来多设备区分铺路。
- **iOS 陀螺仪/加速计**：控制器陀螺仪输入可读，可做陀螺仪瞄准。
- **iOS SDL3 手柄驱动**：从旧驱动迁移到 SDL3。

### 4.6 Changes
- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs by input method
  - Custom focus implementations may need updating
- **Select Mode keybind changed**: "Select Mode" is now `v` key; old mode renamed "Transform Mode" (`q` key)

### 4.5 Changes
- **SDL3 gamepad driver**: Gamepad handling delegated to SDL library for better cross-platform support
- **Recursive Control disable**: Single property disables mouse/focus for entire node hierarchies

### 4.3 Changes (in training data)
- **InputEventShortcut**: Dedicated event type for menu shortcuts (optional)

## Current API Patterns

### Input Actions (unchanged)
```gdscript
func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector(
        &"move_left", &"move_right", &"move_forward", &"move_back"
    )
    if Input.is_action_just_pressed(&"jump"):
        jump()
```

### Input Events (unchanged)
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
- Not testing both mouse and keyboard focus paths (dual-focus in 4.6)
- Assuming `grab_focus()` affects mouse focus (it only affects keyboard/gamepad in 4.6)
- Using string literals instead of `StringName` (`&"action"`) for action names in hot paths
