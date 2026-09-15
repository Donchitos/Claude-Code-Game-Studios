本组结论：在 **STEAM_PC R3–R8及R1/R2回归范围**内，未发现新的确认阻断项。R1–R7的指定本地问题支持关闭；R8的几何/引擎部分通过，截图视觉结果由UX/QA组裁定。此结论不是Windows、完整ABI或最终性能验收。

本组为一个独立专家工作组，覆盖Godot/GDScript与performance；没有将域标签冒充多个独立agent。

| 项目 | 本组裁定 | 核心证据 |
|---|---|---|
| R1 | 本地回归 CLOSED | [game_root.gd:297](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/core/game_root.gd:297)事务锁；305–349逐边界复核并暂停收敛。既有六边界71 checks PASS；新增release期间结束/替换探针各11 checks PASS，旧恢复尾段未覆盖ENDING/第二局，旧context retired。 |
| R2 | 本地回归 CLOSED | [battle_ui.gd:82](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/ui/battle_ui.gd:82)、95–113将背景按钮移出modal焦点域并恢复；[pc_meta_input.gd:19](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/pc_meta_input.gd:19)清默认GUI绑定；真实Godot事件回归未复现Up/Down/KpEnter外泄。 |
| R3 | CLOSED | [input_system.gd:33](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/input_system.gd:33)先验证float64再转换real_t并二次验证，全部早于carrier/callback发布；0.999999999和1e-50运行时被拒绝。 |
| R4 | CLOSED | [input_system.gd:112](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/input_system.gd:112)保留已有KEYBOARD epoch；ZERO carrier仍generation=-1。新增24 checks反向序列探针通过，细节如下。 |
| R5 | 指定传播点 CLOSED | [input-system.md:426](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/design/gdd/input-system.md:426)明确键盘action和独立mapped轴；558分别列PC零VJ/零touch bank与MOBILE_TOUCH后置条件；未用mobile缺口阻断PC。 |
| R6 | CLOSED | [game_root.gd:131](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/core/game_root.gd:131)只读owner值；[battle_ui.gd:70](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/ui/battle_ui.gd:70)仅值变化时更新文本。自然ALWAYS `_process`在暂停时刷新，未新增Input采样或清neutral门；恢复中立tick后HUD和modal旧说明均清除。 |
| R7 | 本地binding/路由 CLOSED | [pc_meta_input_test.gd:20](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/tests/integration/pc_meta_input_test.gd:20)独立表验证具体key/modifier/count/deadzone、joy button和device=-1；device919能匹配wildcard，但`action_for`拒绝，默认GUI无后门。已知非零物理device接受路径仍属于Windows设备门。 |
| R8 | 本域部分 CLOSED | [pc_ui_surfaces_test.gd:16](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/tests/integration/pc_ui_surfaces_test.gd:16)覆盖Home/Active/Pause/Upgrade/Active-neutral/Settlement × 两尺寸，可见性/矩形/文本高度/焦点检查127 PASS。本组未运行图形、未查看PNG，不签署视觉结论。 |

独立执行证据，均为`Godot 4.7.1.stable.official.a13da4feb`，exit0、有PASS marker、无SCRIPT ERROR：

- `pc_input_profile_test.gd`：99 checks。
- `pc_meta_input_test.gd`：134 checks。
- `pc_resume_reentry_test.gd`：71 checks。
- `pc_ui_surfaces_test.gd`：127 checks，headless。
- [/tmp/pc_r3r8_engine_probe.gd](/tmp/pc_r3r8_engine_probe.gd)：24 checks。覆盖NONE→抵消ZERO不发布generation0；keyboard抵消保epoch；keyboard抵消→pad增代；pad→抵消退休→pad再增代；i64 generation耗尽返回错误且carrier清零。
- [/tmp/pc_r3r8_engine_lifecycle_probe.gd](/tmp/pc_r3r8_engine_lifecycle_probe.gd)：11 checks。真实render pump暂停提示及release回调结束旧局。
- [/tmp/pc_r3r8_engine_replacement_probe.gd](/tmp/pc_r3r8_engine_replacement_probe.gd)：11 checks。release回调替换旧局，第二局正常ACTIVE。

性能审查：R3只在初始化增加real_t校验；R4仅改变既有采样分支中的source赋值；device=-1只改变BOOT绑定。R6新增每render frame的只读调用，文本赋值在neutral变化或modal呈现时发生，未新增节点、Input采样或控制器扫描。控制器采样仍为每tick O(已知设备数)，见[pc_input_source.gd:24](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/pc_input_source.gd:24)。这些是静态成本判断，**不是allocation-free或帧预算通过证明**。既有A/B冻结的是此前版本，不能转作当前R3–R8版本性能验收；本组遵令未做性能压测。

读取范围：PC GDD全文、CLAUDE.md、design-review skill、ADR-0005全文、两份历史独立/P1报告全文；`src/input/*.gd`全部正文、GameRoot/BattleUI正文、四个目标测试全文；BattleScope输入/暂停/恢复/teardown和Player消费函数；InputSystem GDD的profile路由、426与558及相关命中段；既有性能A/B报告。未声称阅读全文InputSystem长篇mobile合同、完整Player/Stage/Save实现或所有依赖GDD。生产源码及既有文件未修改；新增probe仅位于`/tmp`。

Windows物理设备/Steam remap、完整七phase与持久identity/native ABI、最终性能继续单列OPEN/NOT_RUN，由fresh creative-director结合其它工作组形成最终verdict。

<oai-mem-citation>
<citation_entries>
MEMORY.md:162-175|note=[kept current target and historical review evidence boundaries separate]
</citation_entries>
<rollout_ids>
01a08544-4656-7522-b1d1-98636bfc83bf
</rollout_ids>
</oai-mem-citation>
