# 2026-09-11 Steam PC 输入整改与验证交付

## 结果与范围

已按用户指定顺序完成profile裁定、PC输入与生命周期适配，再导出Windows验证包。Windows物理键盘/手柄尚未运行，不能宣称三阶段全部验收。基线`e45f135`加本轮未提交改动；历史独立full verdict不变，`battle_ready=false`。

ADR-0005冻结STEAM_PC v1：WASD held优先、独立mapped左轴、0.20闭径向死区、二元满速；pause/focus/topology变化后全部来源中立才能接受新移动，恢复首tick ZERO。每局独立carrier/context，每实际fixed tick采样、验证lease、消费一次；terminal先退休输入。Meta统一分发并显式管理焦点；7001 screen generation按battle递增，解决第二局首个暂停被旧高水位拒绝。

Mobile touch合同逐章标记future-port；PC不创建VJ、不分配touch bank。ASN05修正为nonchoice21、choice21−4+7=24；原本已有互斥规则，不应把28个union rows误认成同时可见。

## 本地验证

环境：macOS / Apple M4 / Godot 4.7.1 stable，图形OpenGL Compatibility。没有已知映射手柄。测试采用临时内存档案。

| 检查 | 结果 | 证据边界 |
| --- | --- | --- |
| 全部`tests/integration/*_test.gd` | 24项headless PASS | 当前生产适配层，不等于完整合同 |
| pc_input_profile_test | 81 checks PASS | 轴fixture与真实action状态；死区、仲裁、neutral、hitch、focus回调、跨局ID |
| pc_meta_input_test | headless26 / graphical30 checks PASS | Godot事件注入完整键盘UI旅程，不是物理设备 |
| PC09截图 | 1280×720、960×540已渲染并查看 | pc-pause-1280x720.png / pc-pause-960x540.png；Windows待测 |
| profile/config/AC/ASN静态比对 | PASS：8章节/10 AC，union28/nonchoice21/choice24 | 作者文档及manifest，不是native generated证明 |
| Godot编辑器导入、Windows export | exit0 | PE32+ x86-64格式与打包成立，不代表Windows能运行 |
| macOS Godot加载导出PCK | PRODUCTION_BOOT_OK / exit0 | 只验证包内入口/资源在本地引擎启动 |
| diff whitespace | git diff --check PASS | 静态检查 |

复跑示例（在仓库根目录；替换为实际Godot可执行路径）：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/integration/pc_input_profile_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/integration/pc_meta_input_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/integration/pc_meta_input_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/integration/pc_input_workload_probe.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/integration/performance_probe.gd -- --dense --pc-input
```

PC06目前只覆盖软件invalidation/neutral，不声称真实最小device ID、未知设备拒绝、Steam重映射或hotplug均已实测。PC04局部context并不关闭全部七phase ABI。PC07的gamepad绑定可静态核对，但真实手柄导航需Windows补证。

## 性能原始记录

- `pc-input-workload-macos.json`：20预热+600采样batch，每batch128 ticks；idle PC poll+lease+Player均摊CPU P50/P95/P99为2.273/2.516/3.195us，79360次采样/消费一致。mapped_device_count=0。这是批均摊测量，不是最坏单tick延迟；静态内存前后值包含夹具，不能证明零分配或无泄漏。
- `performance-graphical-dense-pc-input.json`：120预热+600密集战斗样本，319敌/峰390友弹；720 Input与720 Player消费一致。模拟P95/P99=7.027/7.439ms，max8.151ms，无模拟样本超过16.67ms；整帧P95/P99=29.838/32.489ms，**未达到稳定60 FPS**。
- 第一次dense测量与导出并行，作为受干扰试跑舍弃；上述JSON为导出完成后的复跑。相较历史14.753ms，当前整帧明显更慢，但没有同环境旧版A/B或profiler，不能归因于Input；性能门继续OPEN，本轮未据此改战斗或渲染参数。

## Windows交付及hash

新包路径`build/windows-pc-input/`；旧`build/windows-internal/`保留。必须成对复制EXE与PCK，游戏内容更新体现在PCK，EXE模板hash不变是正常的。

可直接传输同目录`windows-pc-input-validation.zip`，内含EXE、PCK、PowerShell脚本及检查表；ZIP完整性检查通过。Windows解压后在该目录执行`powershell -File .\windows-input-validation.ps1 -BuildDirectory . -ControllerModel '实际型号'`。

| 文件 | SHA256 |
| --- | --- |
| TrialInternal.exe | 4e5e07b73a38be1452888ba41c0a7a8729abe601cbf47aca726857b524a79404 |
| TrialInternal.pck | eacc9a9204a87b69215b53f13d014e1a4ae24a8c930c0d475d21eda653233d94 |
| assets/config/production_defaults.json | 57ae5c6a58a9806d758d433a8614efa35bfc20deee048532e1346e94d2408728 |
| design/registry/manifests/release-input-profiles-v1.json | 65e327043e63c9f7b024155ed41f75655e602cac39460ae7aba7b7e975ea809f |

运行`tests/manual/windows-input-validation.ps1`并按`windows-pc-input-checklist.md`完成W01–W14。脚本使用`--input-validation`，不加载/写入原进度，建立独立时间戳记录、硬件信息、hash、日志和NOT_RUN清单；不会把退出码自动转换成物理输入PASS。当前无pwsh/Wine/Windows会话，PowerShell脚本本身未在目标环境执行。

## 剩余门

Windows物理键盘/手柄/多控制器、Steam Input remap、AltTab/hotplug/held、完整菜单旅程、分辨率与低配/长时性能等待设备。完整GameRoot七phase、持久identity、typed native UI等仍未完成，当前7001为受校验Dictionary adapter。Mobile F2/touch/native accessibility/thermal独立future-port。design-review solo自查影响了real_t公式澄清与证据拆分，未产生独立批准；fresh-context full re-review仍需执行。
