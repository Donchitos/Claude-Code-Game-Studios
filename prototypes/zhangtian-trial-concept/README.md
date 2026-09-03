<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: 玩家能否在75秒三段敌潮中，通过走位、自动飞剑与升级撑到胜利结算？ -->
<!-- Date: 2026-09-02 -->

# 掌天试炼：最小可玩切片

这是隔离的 Godot 灰盒原型，不是正式生产代码。第一轮已验证移动、自动飞剑和升级成长反馈；当前版本扩展为一个75秒完整Demo回合，验证三段敌潮压力、两种敌人和胜负结算。

## 运行

使用 Godot 4.7.1 打开本目录的 `project.godot`，然后运行项目。

也可以在 macOS 终端执行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/prototypes/zhangtian-trial-concept --editor
```

## 操作

- 触摸或鼠标：按住任意位置并拖动。
- 键盘：WASD 或方向键。
- 镜头始终以韩立为中心，灰盒世界不设置可感知边界。
- 升级弹窗和HUD会跟随当前窗口尺寸重新布局；调整窗口宽高后仍保持居中。
- 飞剑自动索敌、自动攻击。
- 拾取绿色灵气后升级；每次从三项强化中选择一项。
- 0—20秒为低阶妖虫试探；20—50秒混入高速铁背妖狼；50—75秒进入终局高压。
- 撑过75秒获得胜利；体力归零则失败。
- 按 `R` 可随时重开。

## 明确不包含

正式 GameRoot、对象池、空间网格、Save、Boss、局外成长、正式资产、音频和生产架构全部不在本原型范围内。原型代码不得被正式 `src/` 引用或直接重构为生产代码。

## 自动冒烟验证

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/prototypes/zhangtian-trial-concept -- --smoke-test
```

成功要求为存活75秒且至少达到Lv.4；通过时输出 `SMOKE_PASS`、首次升级时间并以状态码0退出。
