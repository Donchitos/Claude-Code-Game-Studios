# 统一危险位置查询适配

## 范围与语义

Stage tick末快照新增contacts和attacks。contacts记录非Boss敌人（含召唤）的当前位置、半径、Grid身份；attacks包含扑咬/扇毒预警，以及本tick扑咬扫掠段和扇毒释放几何。预警走廊长度324px沿冻结轴；扇毒复用CombatGeometry闭边界扇形判定。

`query_danger(stage_id, tick, position, radius)`返回valid、warnings、exposures。旧tick/外部Stage/销毁/非法位置或半径返回valid=false，不得把它解释为安全。

这是时点几何查询，而非Damage receipt：exposures不考虑碰撞冷却、扑咬单段已命中、毒雾60tick间隔等最终伤害资格。扑咬/扇毒为当tick攻击几何，毒弹/接触为tick末存活实体位置；已命中消失的毒弹不在快照，因此不支持历史受伤重建。也不预测下一帧移动或给出安全复活保证。正式Damage/Revive consumer、typed ABI及性能仍OPEN。

每tick开始清除攻击几何；Boss死亡不发布Boss攻击；teardown清空。查询仅读快照，不写HP或改变攻击流程、移速、预警和伤害参数。当前Dictionary适配有分配成本，尚未做目标平台性能验收。

## 验证

Godot 4.7.1：hazard_query_test通过，覆盖真实Boss update路径的扑咬/扇毒释放、预警与暴露分离、扇形背面、普通接触、恢复帧清除、旧tick/非法半径/销毁拒绝。weapon_publication_test和long_run_test回归通过。git diff --check通过。

production_battle_loop_test普通战斗、升级暂停/恢复与结算回归通过。

仍为In Review / Re-review Pending，battle_ready=false；不是完整商业版本验收。
