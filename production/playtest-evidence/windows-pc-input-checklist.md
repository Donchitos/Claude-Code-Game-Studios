# Windows PC 输入实机验证

状态：NOT_RUN。本机macOS未提供Windows会话/手柄。目标为`build/windows-pc-input-r3-r8/TrialInternal.exe`和同目录PCK；完整hash在2026-09-11-pc-input-r3-r8.md中。此包包含R1–R8局部整改，独立senior局部APPROVED WITH ADVISORIES；Windows实机仍NOT_RUN。

在Windows复制两个产物和`tests/manual/windows-input-validation.ps1`，运行：

```powershell
powershell -File .\windows-input-validation.ps1 -BuildDirectory 'D:\TrialPC' -ControllerModel '实际型号/连接方式'
```

脚本创建新时间戳证据目录，记录OS/CPU/GPU、两个文件hash、退出码和14项NOT_RUN。游戏使用`--input-validation`内存档案，不加载或写入已有进度。原始日志不自动产生输入PASS。

| ID | 操作 | 成功观察 |
| --- | --- | --- |
| W01 | 不用鼠标，Enter从首页开局 | 焦点可见，一次开局 |
| W02 | WASD四向、对角、W+S/A+D后松开 | 对角同速、相反键抵消、松开停止 |
| W03 | 手柄连接后回中30秒，再慢推左轴 | 静止无漂移，越deadzone后满速；记录型号和默认0.20是否适合 |
| W04 | 左轴向左，按D；再同时A+D | 键盘优先右移；A+D停止且不泄漏左轴 |
| W05 | 按住W并P暂停，保持W按R/鼠标继续 | 持续ZERO；释放W后再按才能移动 |
| W06 | 左轴保持偏转并Start暂停，South继续 | 首帧停止且旧偏转不生效；回中后再推才移动 |
| W07 | 移动时AltTab，后台松键，再回窗口 | 自动暂停、后台无模拟、回焦不自动恢复；显式继续后新输入可用 |
| W08 | 左轴偏转时断开，再偏转着重连 | 旧source失效；回中后新输入生效，不崩溃不漂移 |
| W09 | 使用Steam Input把物理布局映射为左轴/South/East，再运行同旅程 | 标准映射仍可移动/选择/返回；记录设置截图与是否重连 |
| W10 | 升级界面Dpad/Tab循环，East/ESC尝试返回，South/Enter选一次 | 焦点不越modal，返回不替选，一次加成 |
| W11 | 首局暂停一次，死亡结算后重开，第一次暂停 | 首击成功，不被上一局command ID拒绝 |
| W12 | 使用手柄完成结算→首页→再次开局 | 全程无需鼠标 |
| W13 | 1280×720、960×540和本机原生分辨率重复暂停/选择 | 焦点、文字、按钮完整可见，截图记录 |
| W14 | 两个手柄同时接入，交替偏转/拔插 | 最小device ID驱动，任一新topology要求neutral；记录设备顺序 |

每项填写PASS/FAIL/NOT_RUN、实际观察、日志/视频/截图文件。没有手柄的case保持NOT_RUN；只启动成功不能将physical_input_verified设true。Windows完整局、低配性能、长时稳定性仍有各自发行门。
