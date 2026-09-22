# 后五章 GDScript 独立复核

结论：**APPROVED WITH SUGGESTIONS（限定代码与本地可恢复机制范围）**。

## 绑定
- source-freeze：production/playtest-evidence/final-chapters-2026-09-22/source-freeze.json。
- 独立重算 202 个文件 SHA256，全部匹配。
- catalog：683d5040e5e7b6cecadae031d54b77530add19fc0ae1256ab93df9df3e6365d8。
- 范围：campaign_late_chapters、Encounter/Arena/Combat/Validation late 增量，生成器、ADR-0012，以及新增护送奖励。不是全游戏最终验收或独立设计批准。

## 初轮问题复核
1. P1 延迟弹反射后存档拒绝：已解决。倒数结束立即移除 delay 字段，shield 跳过仍处于预警的弹丸；预警后反射符合现有 projectile schema。独立重跑正式边界测试，反射状态验证及 JSON 恢复完全相同。
2. P2 固定拆除 ordinal 与目标身份失联：已解决。Late.valid_state 将 ordinal 绑定 target_ids 索引、max_hp 绑定 target_hp；原 ordinal 变体拒绝测试通过。位置不绑定静态坐标，避免错误拒绝运行时位移。
3. 目标死亡记录与 completed_ids 集合一致性已加入，结合通用唯一性检查，可阻止恢复后注入已死亡目标以跳过实际击杀。

## 新增护送奖励
late_waypoint_xp 严格限定为 ESCORT 的 12；奖励在 Mission.advance 前后 waypoint 差分边界发放，终态不发放，没有独立可重放奖励计数。已有测试验证首个路标恢复后不重发。
独立追加 /tmp/late-waypoint-review.gd：对后五章所有护送任务，在每个路标之前 JSON 恢复，推进真实 Arena.advance，比较两分支完整 snapshot，验证合法 snapshot、准确 waypoint 推进及终局胜利。30 个路标转换通过。该探针通过设置位置直接触发边界，属于恢复夹具，不是玩家旅程或难度证据。

## 独立执行结果
- campaign_late_chapters_test：179 checks / 0 failures。
- campaign_late_boundary_test：309 checks / 0 failures。
- WAYPOINT_REPLAY_PASS transitions=30。
- 所有 Godot 子进程退出码 0，设定 60 或 90 秒超时，显式 /tmp log-file。
- Godot 输出 macOS system CA certificates 环境警告；未出现 GDScript 编译或断言错误。
- 日志：/tmp/review-campaign_late_chapters_test.log、/tmp/review-campaign_late_boundary_test.log、/tmp/late-waypoint-review.log。

## 架构与建议
符合 ADR-0012 的共享 tick/Encounter 持久计数、实际伤害时提交 Boss 阶段、齐射容量原子预检和目标身份约束。没有遗留 P1/P2。
建议后续将 late_boss 的几何分支拆为小 helper，减少一行多条语句；属于可读性优化，不要求在本轮已冻结源码上继续扩改。

本复核不证明新玩家体验、完整 64 关平衡、20 小时时长、Windows、Steam 或商业 Save v2。全流程/打包证据仍由对应任务汇总。源码变化后本结论需重新匹配 hash。
