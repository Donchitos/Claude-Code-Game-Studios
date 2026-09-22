# macOS测试与临时试玩入口

用户暂时无法使用Windows电脑，因此先在本机macOS测试；不改变Steam PC商业完整版优先策略。

## 已执行

- 17个既有tests/integration/*_test.gd全量headless回归通过：Boss combat/FSM、combat protocol、hazard query、hit feedback、home progression、long run、object pool、production battle loop/lifecycle、progression、projectile lifecycle、save crash/fault surface/system、spatial grid、weapon publication。
- 新增macos_graphical_test.gd在实际macOS窗口（Apple M4，OpenGL 4.1 Compatibility）通过。Input.action_press/release由夹具合成，经过现有Input→GameRoot→BattleScope移动路径；验证暂停不推进位置/tick、释放后恢复不漂移。
- 1280×720、960×540截图已查看，HUD、暂停按钮、受击提示在画面内。首次缩放断言把逻辑画布坐标与物理像素比较导致误报，已改为逻辑viewport范围比较，未改变游戏布局。
- 图形夹具关闭自动物理泵、手动推进短序列，不是实际帧率基准或真人输入验收。

## 普通流程试玩

命令：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script production/playtest-evidence/macos_playtest.gd
```

窗口标题“macOS内部试玩 · 临时存档 · 关闭不保存”。从首页点击进入试炼，WASD/方向键移动，P暂停、R恢复；升级时选择一项。正常HP、无自动升级/自动走位。临时profile在启动前设置，禁止真实存档读写；进度仅本次进程有效。

短Boss练习仍可使用boss_practice.gd（R开始）。本次打开普通试玩，不关闭用户已有其他游戏窗口。

macOS导出模板同样未安装（本机模板目录仅ios.zip），因此本次使用已安装Godot运行，不提供或宣称独立.app、签名/公证、Gatekeeper、Intel Mac、真实手柄或Windows验证通过。battle_ready=false。
