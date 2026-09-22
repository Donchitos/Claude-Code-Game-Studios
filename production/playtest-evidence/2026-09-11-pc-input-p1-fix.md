# PC 输入两个 P1 修复

## 本轮范围

用户授权“修复”，本轮对应上一轮独立报告的 R1 恢复重入失焦与 R2 升级 modal 焦点外泄。生产修复、针对性回归、合同传播与新版 Windows 验证包已完成。**作者修复与本地验证不覆盖独立 MAJOR REVISION NEEDED verdict；Re-review Pending，battle_ready=false。**

## 修改与证据

| 问题 | 修改 | 原探针复跑结果 |
| --- | --- | --- |
| R1 | GameRoot恢复事务锁阻止嵌套Continue/事务内gameplay tick；Input保持FROZEN完成hide_modal/focus，取得gate、unpause、呈现回调及release返回均复核原battle/state/focus revision；失败重新关闭Input并回到可交互暂停，不恢复已结束/替换owner | resume返回WRONG_STATE，focused=false/tree_paused=true/root=PAUSED/input=FROZEN/ingress=false；回焦后ticks仍0 |
| R2 | modal前背景暂停按钮disabled/FOCUS_NONE，退出后恢复；BOOT清除规格外默认GUI events；显式绑定的release/echo/拒绝设备事件也消费，防止Control fallback | Choice0按六次Up及六次Down始终Choice0，不再进入PauseButton；规范内Tab/ShiftTab/Left/Right/Enter旅程通过 |

Up/Down/KpEnter没有新增为别名，保持现行八行PC binding规格。普通Enter/Space及已映射手柄确认仍由统一dispatcher处理；实际物理控制器未测试。

已同步 PC规格、ADR-0005、GameRoot/BattleUI输入条款、两个review log、systems-index与session-state。源码修改为 `src/core/game_root.gd`、`src/ui/battle_ui.gd`、`src/input/pc_meta_input.gd`；哈希见本目录子文件 `pc-input-p1-fix-2026-09-11/delivery.json`。

## 验证

- 新增 `tests/integration/pc_resume_reentry_test.gd`：acquire、unpause通知、visibility、focus、同回调loss→gain、gate release六个边界，共71 checks，headless与macOS图形均PASS。包括rollback期间递归Continue拒绝、提交期间tick不推进、回焦不模拟及新显式Continue恢复。
- `pc_meta_input_test.gd`：headless36 / graphical40 checks PASS。覆盖普通暂停与升级modal的默认Up/Down/KpEnter、拒绝设备DpadDown、规范内循环focus/选择一次、echo、关闭modal后背景focus恢复及两尺寸暂停截图。
- 原 `pc_input_profile_test.gd` 81 checks PASS。
- 全部25个integration `_test.gd`脚本正常退出：24个PASS、`batched_renderer_visual_test`明确SKIP（要求图形环境）。其它headless PASS只代表各脚本声明的范围，不能替代其图形专属分支。
- 上轮两个原始探针直接复跑，记录为 `pc_resume_reentry_review-after-fix.log`、`pc_ui_bypass_review-after-fix.log`。退出码不是其业务PASS判定，以上实际状态与焦点trace为依据。
- 1280×720与960×540暂停PNG已实际查看，标题、提示、Continue与focus框完整可见；本轮不声称所有界面显示矩阵已覆盖。
- Windows Internal导出exit0；在独立临时目录用macOS Godot加载新PCK，PRODUCTION_BOOT_OK且无SCRIPT ERROR。ZIP CRC验证通过。未运行Windows EXE。
- `git diff --check`通过。

原始日志、JSON与PNG：`production/playtest-evidence/pc-input-p1-fix-2026-09-11/`。日志检查同时要求PASS marker且无SCRIPT ERROR，不仅检查exit0。最初新测试的类型推断错误与事件fixture重复对象警告已修正，再运行取得上述结果。

## Windows 验证包

新版：`build/windows-pc-input-p1-fixed/windows-pc-input-validation.zip`。旧 `build/windows-pc-input/` 保留为修复前包。新ZIP包含EXE/PCK、PowerShell和检查表；在Windows解压后执行：

```powershell
powershell -File .\windows-input-validation.ps1 -BuildDirectory . -ControllerModel '实际型号/连接方式'
```

| 文件 | SHA256 |
| --- | --- |
| EXE | `4e5e07b73a38be1452888ba41c0a7a8729abe601cbf47aca726857b524a79404` |
| PCK | `2e106d23c3a22db1e41fa0c513968aa30c3980f538d307a9a8632cdc9985573e` |
| ZIP | `005be631ce8a66a84767e26a6e6812352edeb41a672d1fe30ace1fcbcafc2e88` |

W01–W14、Windows/物理手柄、PowerShell目标运行、Steam remap、多设备与min-spec仍NOT_RUN/OPEN。本机合成事件不冒充设备证据。

## 剩余工作

独立复审尚未重新执行。上一报告R3–R8仍保留：real_t死区配置极值、抵消generation语义、旧profile传播文字、neutral反馈、完整binding oracle及多界面显示覆盖；本轮仅补齐与两个P1直接相关的回归。完整七phase/持久identity/native ABI、默认帧时间性能门与商业原创化依然独立追踪。
