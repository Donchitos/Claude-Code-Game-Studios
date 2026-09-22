# Input Vertical Slice

这是正式生产输入路径的最小可运行切片，不是完整游戏，也不是现有 `prototypes/zhangtian-trial-concept` 的替代品。

## 当前覆盖

- Godot 4.7.1 正式 `project.godot`
- 四个空 event-list movement actions，deadzone 固定为 `0.0`
- 内置 `VirtualJoystick` Dynamic / When Touched
- `InputSystem → MovementIntentCarrier` typed 写入
- `MOVEMENT_COMMIT`、pause/resume、revision rebuild、teardown 最小状态链
- headless smoke：`tests/input_vertical_slice_smoke.gd`
- headless touch-order fixture：`tests/input_touch_order_fixture.gd`
- 已安装并固定 GDUnit4 v6.2.1（`addons/gdUnit4`），状态合同：`tests/input_system_gdunit4_test.gd`
- GDUnit4 真实场景触摸顺序：`tests/input_touch_order_gdunit4_test.gd`
- VJ claim/reset/rebuild/reentrancy 合同：状态合同测试中的专用用例
- 最小 BattleUI slice、8 行 Meta UI 与 `DirectionalFocusNeighborManifestV1`：`src/battle_ui_slice.gd`、`src/directional_focus_manifest.gd`
- `GameRootSlice → root Viewport.gui_disable_input → BattleUICanvasLayer → BattleUI/VJ` 路由与 activation gate：`src/input_slice_root.gd`、`main.tscn`
- battle child lifecycle：`pause_battle_scope`、`resume_battle_scope`、`replace_battle_scope`、`teardown_battle_scope`，并验证 root/Viewport identity 保持不变
- 统一检查入口与机器可读报告：`tools/ci/run_checks.py`

## 尚未声称

本切片尚未覆盖完整 GameRoot/BattleUI 生产集成、Android/iOS 真机 touch-order、TalkBack/VoiceOver、完整 accessibility runtime、性能/thermal 或玩家 UX 证据。这里的 GameRoot、BattleUI、Viewport route 和 manifest 仅是最小 harness，不是生产验收；当前环境没有 `adb`，且 `xcrun simctl` 不可用，因此真机/模拟器证据保持 OPEN。

## 运行

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path production/input-vertical-slice --script res://tests/input_vertical_slice_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path production/input-vertical-slice --script res://tests/input_vertical_slice_contract.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path production/input-vertical-slice --script res://tests/input_touch_order_fixture.gd
python3 production/input-vertical-slice/tools/ci/static_guard_check.py
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/input_system_gdunit4_test.gd -rd evidence/gdunit4
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/input_touch_order_gdunit4_test.gd -rd evidence/gdunit4
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/battle_ui_gdunit4_test.gd -rd evidence/gdunit4
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/game_root_viewport_gdunit4_test.gd -rd evidence/gdunit4
python3 production/input-vertical-slice/tools/ci/run_checks.py --write-report
/Applications/Godot.app/Contents/MacOS/Godot --path production/input-vertical-slice --editor
```

运行窗口中：`P` 暂停、`R` 恢复、`B` 触发同 revision rebuild 检查。
