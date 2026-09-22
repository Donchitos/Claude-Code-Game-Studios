# 战斗协议增量：伤害批次与弹体回收

## 本轮范围

保持移速、预警、伤害数值与受击表现参数不变；补当前Stage适配层的可复现缺口，不改正式GDD或独立评审结论。

- Damage batch：clear开始新批次，一次commit后拒绝重交或追加；分别有限但合计溢出的contact+attack拒绝写入；只在实际应用伤害后启动碰撞冷却。
- 飞剑回收：保持现有玩家中心回收圆语义，不改为累计射程。裁剪本帧运动至圆周，执行闭边界扫掠判定，再回收越界弹；已在圆外的起点直接回收，不允许重新进入。
- teardown：先关闭Stage模拟入口，清空友弹、毒弹、两种pending与拾取，再释放敌人Grid/Pool；重复teardown仍安全。

## 自动验证

Godot 4.7.1 headless：

- combat_protocol_test：重复提交/追加无二次扣血，合计溢出零写，原碰撞/来源/恢复顺序检查通过。
- projectile_lifecycle_test：末段命中、圆外不命中、端点相切、起点越界、所有弹体通道清理、关闭后拒绝模拟与重复teardown通过。敌人HP设100用于多次非致命命中夹具。
- long_run_test：90秒收益、Boss出场、暂停、真实飞剑击杀、结算回归通过。
- hit_feedback_test：提示来源、暂停冻结、失败来源跨teardown保留通过。
- production_lifecycle_test：persistent root/viewport与战斗替换通过。
- production_battle_loop_test：普通战斗、升级暂停/恢复、结算通过。

完整typed Damage intent/receipt、跨批次身份、Weapon T+1发布、Projectile独立Pool owner、hazard snapshot与目标平台性能尚未实现/验证。此结果不是完整协议或商业发行验收；仍In Review / Re-review Pending，battle_ready=false。
