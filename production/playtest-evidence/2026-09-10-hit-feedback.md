# 受伤反馈修正

## 真人反馈

用户确认扑咬/扇毒预警明显、移动容易控制；受伤效果不明显，只能看血量。本轮不调整移速、Boss预警时间、伤害或难度。

## 实现

- 已接受伤害后角色亮色与红圈持续0.24秒；头顶实际扣除血量（恢复前、不超过剩余HP）浮字持续1.4秒。
- HUD显示本次聚合伤害来源；同时命中的不同来源并列，不伪装成单一来源。
- 结算保留致命来源，存活超时显示未及时击败首领；来源只是本轮展示数据，不改存档格式。
- 提示使用战斗Active时钟，暂停冻结；无效伤害/碰撞冷却阻挡不触发；新局清空。
- 无全屏闪烁、镜头震动、音频新增。当前使用可变字符串展示适配，不等于完整typed Damage receipt ABI。

## 验证

Godot 4.7.1：combat_protocol_test、hit_feedback_test、production_battle_loop_test通过。覆盖来源、实际伤害量、阻挡不触发、计时、重置、暂停冻结与结算跨teardown来源保留。

`capture_boss_preview.gd -- --hit-feedback`使用临时存档和人工伤害注入生成`hit-feedback-preview.png`，1280×720实际渲染已查看：文字、数字和受击圈可见。不是自动攻击命中或动态真人验收证据。新增受伤效果待用户重新启动练习后复测。

状态仍为In Review / Re-review Pending，battle_ready=false。
