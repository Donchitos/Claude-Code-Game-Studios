# 战斗调参与协议验证 — 2026-09-10

状态：本地自动模拟与渲染检查完成，真人操作反馈待采集；非商业发行验收。

## 本轮修正

- 普通碰撞取当tick最大碰撞伤害并受碰撞冷却控制；Boss招式/毒弹/毒域单独累加，再一次提交HP、致命与长春恢复。碰撞冷却不再吞Boss攻击；无效/非有限批次零写入。
- 飞剑使用线段扫掠，选择最早碰撞；同距离按Grid handle稳定判定。扇形使用圆弧/边界线段的精确距离，修复角落扩张造成误伤。
- 毒弹T+1请求绑定Boss handle与action generation；旧来源拒绝。召唤消费固定48个randi word，在相对90–150px环内选择两个位置，检查完整世界边界、玩家净空、当前毒域和彼此重叠；容量不足仍消费48字，整组0或2，初始化异常回滚已插入成员。teardown清除pending与毒弹。
- 移速上限新增配置600px/s。此前循环选择成长可达1547.93px/s。该上限仍为待真人校准的临时参数。
- 长春charge在同一Player实例reset_run时恢复初始值。

## 普通血量模拟

100 HP、初始永久成长0、seed 101/202/303，完整运行敌潮；升级循环选择0/1/2。通过直接提供方向驱动游戏固定tick，未使用高血量。此为自动策略模拟，不验证实际按键操作或人类反应时间。

| Seed | 首次升级秒 | 站桩决战结束秒 | 站桩结果 | 躲避策略结束秒 | 躲避剩余HP |
|---|---:|---:|---|---:|---:|
| 101 | 15.80 | 731.02 | 失败，Boss剩45 HP | 742.78 | 88.0 |
| 202 | 15.62 | 731.55 | 失败，Boss剩52 HP | 739.05 | 77.2 |
| 303 | 15.52 | 731.77 | 失败，Boss剩50 HP | 739.57 | 77.2 |

躲避策略读取招式状态，在扑咬预警时横移、扇形预警时后退、毒弹期间切向移动、毒域外返回中心。三组均Lv25通关。样本只用于发现实现问题，不足以估计真人胜率或证明难度合理。此前共用碰撞冷却时站桩也能通关，相关旧结果不再用作难度依据。

复现：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/balance_probe.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/balance_probe.gd -- --dodge
```

## 图像与真人练习

`boss-fan-preview.png`由Godot实际渲染生成，时间定位到扇形预警，图中1000000 HP属于截图fixture，未用于上述普通血量模拟。已检查扇面方向/轮廓与玩家位置。动态预警持续时间、操作反馈和多危险可读性仍需真人试玩。

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script production/playtest-evidence/boss_practice.gd
```

练习为100 HP、Lv25、24次循环升级，时间定位到Boss入场前一tick，使用临时内存存档；初始暂停，按R开始，WASD移动，P暂停。关闭窗口即可退出；不写正式进度。重点反馈：扑咬能否看清方向、扇毒能否及时躲开、600px/s是否过快、失败是否能理解原因。结算后重试按钮仍走常规长局；再次启动脚本可重开短练习。

## 证据与剩余协议

combat_protocol_test、long_run_test（含stale batch与召唤守恒）、原有集成测试通过；最终高血量自动烟测733.58秒、Lv25、1470击杀通关，仍仅作为生命周期回归。

上述是Stage适配层协议修正。完整Damage/Projectile的typed ABI、Config hash/epoch绑定、正式伤害事件归因、ReviveHazard多owner快照、四方向入场、完整Spawn stream manifest、过程强杀恢复及独立复审仍未完成；boss-ready/商业发行状态不提升。
