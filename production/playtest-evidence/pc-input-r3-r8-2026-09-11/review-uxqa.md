[UX/UI/accessibility/QA 工作组] 本次没有发现新增可复现 P1/P2。建议 **R6、R7、R8 在当前本地 PC 范围 CLOSED；历史 R2/P1 CLOSED**。R1 六边界重入回归通过，生命周期最终结论与引擎组交叉确认。不能据此关闭 Windows PC10、物理手柄或原生无障碍门。

| 项目 | 裁定 | 本轮独立核验 |
| --- | --- | --- |
| R6：neutral 等待提示 | CLOSED，本地范围 | GameRoot 每帧只读 `neutral_required`，覆盖 active/paused/resume；HUD 与 modal 同步更新。普通暂停、升级恢复 held、active topology 回调等待均有断言，释放后 HUD 恢复移动说明且 modal 等待文字移除。 |
| R7：exact binding 与 GUI 旁路 | CLOSED，本地范围 | 独立 EXPECTED 常量比较十行（八行 Meta＋P/R）的具体键码、修饰键、事件数、deadzone、手柄按钮及 device wildcard；检查规格外默认导航 action 清空。真实 Godot 注入 Up/Down/KpEnter、未知设备、echo，并验证焦点与业务结果。 |
| R8：六界面 × 两尺寸 | CLOSED，现有本地图形证据范围 | contact sheet 确有 Home/Active/Pause/Upgrade/Active-neutral/Settlement × 1280×720、960×540 共十二图；另实际查看两张 960×540 原图。文字、三个升级按钮、焦点边框与等待说明可见，未发现遮挡或裁切。 |
| R2/P1：升级焦点进入背景 pause | CLOSED，本地范围 | modal 打开前 pause 被 disabled＋FOCUS_NONE，dispatcher 仅枚举可见 enabled choice；真实默认 GUI 事件回归没有逃逸；关闭后 pause focus 恢复。 |
| R1/P1：恢复回调失焦被覆盖 | 本地回归 PASS | 独立重跑六类边界测试：acquire、unpause、visibility、focus、loss_gain、release；失败后保持暂停，回焦不推进，需要新的 Continue。最终实现完整性裁定交引擎组。 |

具体证据及行号：

- **R6 实现**：`src/ui/battle_ui.gd:70–79` 集中更新 HUD 与 modal 说明；`:82–106` 普通暂停和升级均调用刷新；`src/core/game_root.gd:131–133` 从 InputSystem 读取状态，UI 无额外采样或解门。`tests/integration/pc_ui_surfaces_test.gd:45–79` 覆盖 held → pause → resume → upgrade → release，以及 active topology → release 的出现、位置不变与消失。
- **R7 实现和 oracle**：`src/input/pc_meta_input.gd:19–39` 安装精确表并清默认 GUI 绑定；`:42–49` 拒绝 release、echo、未知手柄并精确匹配；`src/core/game_root.gd:140–148` 在业务拒绝时仍消费绑定事件。`tests/integration/pc_meta_input_test.gd:6–50` 的预期表不引用实现 ROWS，逐字段断言；`:90–128` 检查普通/升级 modal 默认 GUI 绕路、未知设备、焦点循环、一次确认仅升级一次、关闭后背景焦点恢复。
- **R2 修复**：`src/ui/battle_ui.gd:43–50,82–85,95–98,108–113`；dispatcher `src/core/game_root.gd:166–210`。
- **R8 采集与断言**：`tests/integration/pc_ui_surfaces_test.gd:16–29` 为每个尺寸检查控件可见、矩形在 viewport 内、文字最小高度、当前焦点可用；`:38–82` 实际枚举六个界面。`project.godot:16–21` 使用 1280×720 逻辑画布及 canvas_items stretch，这两组图支持两个指定的同宽高比窗口尺寸，不能扩展为任意宽高比的响应布局证明。
- **R1 回归**：`tests/integration/pc_resume_reentry_test.gd:43–102`，修复路径 `src/core/game_root.gd:297–349`。

本轮实际执行结果（不是转述 regression.json）：

```text
Godot Engine v4.7.1.stable.official.a13da4feb
PC_META_INPUT_PASS checks=134 event_route=true physical_device=false renderer=headless
PC_UI_SURFACES_PASS checks=127 renderer=headless physical_device=false
PC_RESUME_REENTRY_PASS checks=71 synthetic_focus=true physical_device=false
```

另新增临时、只读生产代码的 `/tmp/pc_ui_modifier_review.gd`：尝试 Ctrl+Tab 被 exact dispatcher 拒绝后落入默认 Control focus 路径。实际 `action_for=""`、`exact=false`，焦点仍为 Choice0，未复现。此假设撤回，不列问题。

视觉检查：

- contact sheet 中两个尺寸的每个界面均能区分主要行动和当前焦点。
- 原图 `upgrade-960x540.png` 的双行提示与三个双行选择全部在画面内，首项焦点边框清楚；背景 pause 已明显退到 modal 后。
- 原图 `active-neutral-960x540.png` 底部等待说明完整；HUD 与 pause 仍可见。
- 截图证明的是静态可见性。提示消失、单次业务和焦点禁入依靠本轮 headless 断言补充；没有重新运行图形采集，不能称为本轮重新生成的截图。
- native accessibility、Windows 物理键盘、mapped 手柄实际导航、Steam Input remap、导出多分辨率人工旅程均未由这些截图证明；不将它们追加成 R6–R8 新 blocker。

读取范围：

- 全文：`.claude/skills/design-review/SKILL.md`、`CLAUDE.md`、`design/gdd/input-steam-pc.md`、`production/playtest-evidence/2026-09-11-pc-input-independent-review.md`、`src/ui/battle_ui.gd`、`src/input/pc_meta_input.gd`、`tests/integration/pc_meta_input_test.gd`、`tests/integration/pc_ui_surfaces_test.gd`、`tests/integration/pc_resume_reentry_test.gd`、`src/ui/home_screen.gd`。
- 定向：`design/gdd/battle-ui.md` PC profile/提示/modal 条款及相关 focus/AC 段落；`src/core/game_root.gd:75–225,250–349,413–432` 输入路由、提示、pause/resume/gate；`project.godot` 尺寸配置；证据目录清单与 regression.json。
- 图片实际查看：`surfaces-contact-sheet.jpg`、`upgrade-960x540.png`、`active-neutral-960x540.png`。
- 未修改既有源码、设计或证据文件；未启动图形运行。

归档补充：本报告按协调者后续归档指令写入 `production/playtest-evidence/pc-input-r3-r8-2026-09-11/review-uxqa.md`；临时探针原样复制为同目录 `independent-modifier.gd.txt`。首次执行仅保留工具输出，未产生独立日志文件；本次未重跑，不伪造日志。
