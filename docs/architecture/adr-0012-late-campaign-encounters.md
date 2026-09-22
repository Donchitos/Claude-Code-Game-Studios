# ADR-0012 后五章可恢复遭遇

## Decision
在CAMPAIGN_GAMEPLAY_V1之上使用CAMPAIGN_LATE_CHAPTERS_V1快照分支；沿用Encounter的stage_ticks/counts和Objective的completed_ids。布局、有限波次、危险区周期、Boss攻击参数全部来自离线目录。危险区是否关闭由对应目标ID完成派生，关闭不取消既有预警。

六名首领分别使用镜阵、俯冲、孢潮、锚环、封印、核心环弹，阶段只在实际damage_enemy边界推进并释放悟性。一次齐射预检所有zone/projectile预算，容量不足不消费攻击计时或aim。HUNT绑定E04..E08；目标身份/数量、Boss阶段和区域来源恢复时严格检查。所有计时沿用60Hz tick，不添加墙钟。

## Consequences
后40关不再使用旧无限生成；没有抹除旧包和旧hash证据。旧第三章进行中存档只在旧包继续，升级拒绝不写双槽；完成后Home可升级。保留原章节ID、任务类型、固定/自选顺序与成长0/8/24/40/56门槛。不能据此声称商业Save v2、20小时或发行认证。

护送非终点路标在Mission.advance的waypoint推进边界释放12悟性（配置late_waypoint_xp），不存独立计数；恢复同waypoint不会重发。终态优先，不在终点继续给予局内构筑奖励。

固定种子校准：第五章俯冲半宽28、间隔210tick；锚环/封印预警120tick、间隔240tick。第六章普通守点波次不重复堆叠缠根敌人，900tick单次引入一名缠根支援。首领生命与角色伤害未调整；单角色压力失败与全旅程验证分别记录。
