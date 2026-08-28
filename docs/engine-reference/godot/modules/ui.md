# Godot UI — Quick Reference

Last verified: 2026-08-14 | Engine: Godot 4.7.1

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **Control 偏移变换**：Control 节点可平移/旋转/缩放而不影响容器布局（类似 CSS `transform`）。
- **`RichTextLabel` 图片 API 大改**：`add_image`/`update_image` 的 `width_in_percent`/`height_in_percent`（bool）→ `width_unit`/`height_unit`（`ImageUnit` 类型）；width/height `int` → `float`。`UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT`。源码级破坏（GH-112617）。
  - 新增 `[img height=1em]` 等字体尺寸相关图片缩放。
- **`Control.accessibility_live` 类型变更**：`DisplayServer.AccessibilityLiveMode` → `AccessibilityServer.AccessibilityLiveMode`（GH-116839）。
- **`TreeItem.select()` 新增 `set_as_cursor` 可选参数**：兼容（GH-119367）。
- **PopupMenu 搜索栏**：长列表可选显示搜索栏。
- **RichTextLabel `img=`/`font=` 标签解析改进**。
- **`OptionButton` 宽度匹配弹出菜单**。
- **无障碍地标导航**：屏幕阅读器可提供 UI 区域上下文。

### 4.6 Changes
- **Dual-focus system**: Mouse/touch focus is now SEPARATE from keyboard/gamepad focus
  - Visual feedback differs by input method
  - Custom focus implementations may need updating
- **TabContainer**: Tab properties editable directly in Inspector
- **TileMapLayer scene tile rotation**: Scene tiles can be rotated like atlas tiles

### 4.5 Changes
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **Recursive Control behavior**: Disable mouse/focus for entire node hierarchies
  with a single property
- **Screen reader support**: Control nodes work with AccessKit
- **Live translation preview**: Test different locales in-editor
- **`RichTextLabel.push_meta`**: Added optional `tooltip` parameter (from 4.4)

### 4.4 Changes
- **`GraphEdit.connect_node`**: Added optional `keep_alive` parameter

## Current API Patterns

### Theme and Style (4.6)
```gdscript
# Editor uses new "Modern" theme by default
# For game UI, use custom themes as before:
var theme := Theme.new()
theme.set_color(&"font_color", &"Label", Color.WHITE)
theme.set_font_size(&"font_size", &"Label", 24)
```

### Focus Management (4.6 — CHANGED)
```gdscript
# Keyboard/gamepad focus (grab_focus still works)
func _ready() -> void:
    %StartButton.grab_focus()

# IMPORTANT: In 4.6, mouse hover is separate from keyboard focus
# Both can be active simultaneously on different controls
# Test your UI with BOTH mouse and keyboard/gamepad

# Focus neighbors (unchanged)
%Button1.focus_neighbor_bottom = %Button2.get_path()
%Button1.focus_neighbor_right = %Button3.get_path()
```

### FoldableContainer (4.5 — NEW)
```gdscript
# Accordion-style collapsible container
# Add as parent of content you want to make collapsible
# Children show/hide when header is clicked
# Configure via editor properties or code
```

### Recursive Disable (4.5 — NEW)
```gdscript
# Disable all mouse/focus interactions for a hierarchy
# Useful for disabling entire menu sections
%SettingsPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
# In 4.5+, this can propagate recursively to children
```

### Localization-Ready UI (best practice)
```gdscript
# Use tr() for all visible strings
label.text = tr("MENU_START_GAME")

# Use auto-wrap for labels (text length varies by language)
label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# Test with live translation preview in editor (4.5+)
```

## Common Mistakes
- Assuming `grab_focus()` affects mouse focus (keyboard/gamepad only in 4.6)
- Not testing UI with both mouse and gamepad after upgrading to 4.6
- Hardcoding strings instead of using `tr()` for localization
- Not using `FoldableContainer` for collapsible UI (new in 4.5, cleaner than custom)
