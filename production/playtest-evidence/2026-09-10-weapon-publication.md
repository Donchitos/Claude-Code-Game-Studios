# 飞剑下一帧发布与危险快照适配

## 实现范围

- Stage维护32行预分配Weapon pending；T记录原点、速度、伤害，T+1在攻击更新前交付。期间移动/升级不改变已发布数值。
- pending超32行计丢弃；交付遇active容量满计丢弃，不延迟重试。现有392友弹+8毒弹容量不变。不是完整Weapon capability/Spawn intent ABI。
- 暂停不推进Stage tick。错帧交付返回失败，由现有BattleScope/GameRoot错误路径处理；teardown清空pending。
- tick开始使旧快照失效，成功tick末发布毒弹位置/速度/半径/剩余寿命及毒雾中心/安全半径/伤害周期。读取要求Stage实例ID和当前tick一致，返回深拷贝；销毁后读取为空。
- 快照是当前时点的展示/查询适配，不是下一tick无伤保证；不含扑咬、扇毒或普通敌人接触，尚未接入正式Damage/Revive hazard consumer。Dictionary分配和deep-copy尚无性能验收，不称完整零分配协议。

## 验证

Godot 4.7.1 headless：weapon_publication_test覆盖T/T+1隔离、冻结伤害、暂停、错帧、容量、快照复制隔离/身份/时效、毒弹过期、Boss死亡清雾和teardown；long_run_test与projectile_lifecycle_test回归通过。

production_battle_loop_test普通战斗/升级暂停恢复/结算回归通过；git diff --check通过。

移速、预警和伤害配置未改；发射延后一战斗tick是本次有意的时序变化，真人手感尚未复测。保持In Review / Re-review Pending与battle_ready=false。
