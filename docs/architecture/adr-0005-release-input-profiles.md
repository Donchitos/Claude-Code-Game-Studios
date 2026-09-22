# ADR-0005: Release input profiles 与 PC 生命周期

## Status

Accepted — 2026-09-11，依据用户授权裁定并整改 Steam/mobile profile 与 PC 输入语义。设计接受不等于独立评审或平台验收通过。

## Context

ADR-0004确定Windows优先，但touch-only F1与PC双采样、零手柄死区、每局UI命令重置和暂停持键恢复不一致。需要分别定义可执行PC规格和移动端future-port规格。

## Decision

- `STEAM_PC`为唯一生产启用profile；配置版本1。输入以`input-steam-pc.md`为当前PC权威。`input-system.md`的原touch章节逐章标记`MOBILE_TOUCH`，保留移动端合同。生产不实例化VJ，不分配touch bank，不用移动manifest的null值猜容量。
- 键盘`move_*`只绑定WASD；单独读取映射后的控制器左轴。任一键盘方向action按住时键盘优先，包括相反键抵消为ZERO；无键盘输入时选已知控制器中device ID最小者。对摇杆一次径向死区判断`length<=0.20`输出ZERO，其余finite非零向量scale-first归一化。0.20是配置默认值而非设备测试结论。
- 每次完整中立→非零、或来源切换时checked递增source generation。PC不借用VJ claim/gesture epoch。每个实际60Hz模拟tick先Input后Player，禁止多个补帧消费同一carrier；输入/消费绑定同一预分配PC context与lease。该PC运行适配不宣称完整七phase商业ABI已实现。
- 暂停先原子关闭Input标量状态、清carrier，再取得Viewport gate并冻结SceneTree。恢复在gate内先unpause（Input仍关闭），校验焦点revision，再开放Input；第一tick输出ZERO。恢复后所有键盘方向action松开、所有已知控制器摇杆回中后才接纳新移动。held-only保持等待，不触发fault。
- 失焦立即暂停，回焦保持暂停，玩家显式继续；控制器连接变化退休当前source并重新要求中立。Ending/fault/replacement先退休输入与context再清理节点。
- BattleUI command identity按battle generation分区；screen generation来自GameRoot，每局计数从1开始，GameRoot在新generation重置replay高水位。拒绝旧generation、重复、零/负ID、非当前screen命令。
- 八个Meta action由明确binding表安装；GameRoot单一输入路由在GUI默认消费前分发，重复/echo不会再次激活。Home、Battle/Upgrade、Settlement都有明确可见enabled focus序列。原P/R入口转为同一Meta规则，保留键位兼容。

## Consequences

Steam可独立实现、测试和导出。Mobile的F2、VJ/shield、native a11y、touch-order与thermal仍是future-port gate；本轮不放宽这些合同。按住输入跨暂停必须松开再按，UI显示该要求。多控制器默认仅最小device ID驱动，设备排序变化会重新要求中立。

## ADR Dependencies

依赖ADR-0004和ADR-GR-001；与ADR-0001 mobile accessibility无实现依赖。先规格/配置，后生产生命周期，最后Windows物理设备验证。

## Engine Compatibility

Godot 4.7.1，已读取本地`docs/engine-reference/godot/modules/input.md`及VERSION。使用InputMap、Input.get_vector/get_joy_axis/get_connected_joypads/is_joy_known、Window focus signals和Viewport GUI gate。实际引擎导入、事件注入、场景测试与Windows导出均须执行。

## GDD Requirements Addressed

InputSystem review 2026-09-11 B1/B2/B4/B5/B6：profile、漂移/采样、touch隔离、held resume、7001 identity。PC context只解决输入→玩家的tick身份，不关闭其余系统phase/Save世界身份合同。

## Validation

PC规格AC逐条绑定测试或Windows操作记录。保留`In Review/Re-review Pending`和`battle_ready=false`，平台结果只能由实际Windows设备填写。


## 2026-09-11 授权 P1 整改补充（独立复审待进行）

- R1：恢复事务锁覆盖所有setter/focus/gate边界，禁止嵌套Continue与事务内gameplay tick；Input保持FROZEN完成hide_modal与焦点转移，逐边界验证battle/state/focus revision后才激活。gate release返回再复核；失败关闭Input、恢复暂停UI与可交互gate，回焦不自动继续，不覆盖terminal/replacement owner。
- R2：modal期间背景pause按钮disabled/FOCUS_NONE；BOOT清除规格外Godot默认GUI action events，未列出的Up/Down/KpEnter不增加新binding。显式表匹配的release/echo/拒绝设备也消费，避免Control fallback。
- 此项补充只对应两个P1及回归，不关闭独立MAJOR REVISION NEEDED，也不覆盖剩余P2、完整ABI或Windows门。

## 2026-09-11 R3–R8整改语义

- real_t转换后死区仍须在(0,1)，否则初始化零发布；相反键抵消保留现有keyboard epoch，完整释放或不同source退休后新非零输入才增代。
- PC Meta手柄binding显式device=-1匹配所有设备，再由action_for拒绝未知映射来源；不得隐式只绑定device0。
- UI只读neutral_required；普通暂停、升级、恢复/active hotplug覆盖提示，解除后同步清理。PC与MOBILE_TOUCH的IG-IS4后置条件分别验证。
- 见本轮R3–R8证据报告；独立复审结论与Windows硬件门另记。
