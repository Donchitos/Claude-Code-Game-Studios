# QA 增量复核：后章固定种子校准

2026-09-22。基于 202 文件 source-freeze；全部 SHA256 重新核验匹配。当前 catalog 为 abc5f36fd15ea1f7623b4fdf46edd035056ff18f413b97e2bac4410708f86b96。

配置与恢复兼容性审查：

- M05-08 dive 的 radius=28、cooldown_ticks=210，warning_ticks 仍为90。生成器与 Late.valid_definition 的严格期望同步，执行器使用 cfg.radius 和 cfg.cooldown_ticks，因此配置实际生效。
- M07-08 anchors 与 M08-07 seals 的 warning_ticks=120、cooldown_ticks=240。生成器、目录与验证器一致。改变的是现有 zone 的 delay 与 Boss timer，没有新建恢复计时状态。Nexus 延迟弹幕仍为90tick，未突破现有 projectile.delay<=1.5 的上限。
- M06 SURVIVE 现为10组普通有限波次，每组4名（N16/N18），间隔105tick；第一组额外一名 N17 rooter，offset900、count1。普通波次不再抽到 rooter，支援不循环。此处沿用既有第六章 CLEANSE/ESCORT/BREAK 的限单支援方式。
- 阶段悟性、死亡/完成目标一致性、反射恢复、奖励去重以及整轮容量预检实现未因本次参数校准放宽。ADR-0012 已记录新的数值与证据边界。

独立执行当前冻结：

- campaign_late_chapters_test：179 checks，0 failures，退出0。
- campaign_late_boundary_test：309 checks，0 failures，退出0。

日志 /tmp/qa-tuned-campaign_late_chapters_test.log 与 /tmp/qa-tuned-campaign_late_boundary_test.log。本次未重新执行完整64关旅程，也未独立重跑作者所述两个定向坏种子；不得把作者描述改写成 QA 亲自执行的证据。

Verdict：增量代码/配置 QA APPROVED WITH SUGGESTIONS，无新增阻断发现。先前 catalog683d5040 的 safe64/64、C03和regional各39/40依然是历史事实；不能迁移成 abc5f36f 的旅程结论。作者正在新hash重跑safe/regional，应以实际最终JSON与ENDING_DISK_RELOAD_PASS收口。C03同种子仍败须保留在限制中，不以regional的后续结果删除该失败。battle_ready=false。
