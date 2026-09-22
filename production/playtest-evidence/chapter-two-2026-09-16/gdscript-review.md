# 第二章最终冻结 GDScript 独立复核

限定 Verdict：APPROVED WITH SUGGESTIONS。原审查的2项功能P2及Profile事务测试回归均已关闭；本轮未发现新的P0/P1/P2阻断。只裁决该冻结下的代码/配置和限定自动验证，不代表商业或真人体验批准。

## 冻结

production/playtest-evidence/chapter-two-2026-09-16/source-freeze.json 共75项，全部SHA256匹配，MISMATCH=[]。目录hash前缀7a6edddb。生成器 --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。

## 修复与最终增量复核

- 炉门矩形/关闭线已移到Boss主体绘制之后，遮挡代码缺陷关闭；图形证据的视觉质量仍归GUI验收。
- thermal_vent与layout root的中心/radius/damage/duration绑定，错误合法编号不再被当作有效来源。六种管线顺序测试增加错配标签并重建numeric_bits的负例。
- target presence与completed_ids双向约束，缺失未完成目标拒绝；BOSS目标绑定boss family/id、BREAK目标绑定target family；HUNT绑定S1-E02及当前HP对应phase，Boss phase限定整数0..2。原审查的目标身份漏洞不再存在。
- Profile.initialize/_publish使用deep-copy保留已验证数据，写盘前按有效numeric_bits重建精确state；state/numeric_bits形状检查先于直接访问。没有放宽Codec的精确镜像规则。
- TransactionProfile测试通过覆写save_run给原最小夹具补空state/numeric_bits树，仍调用super.save_run与真实交易写盘；仅事务隔离测试重写checkpoint语义。原581个断言保留，4处跨JSON相等使用same_values，只有int/float数值等价，无近似容差，没有屏蔽真实字段差异。
- E通用“后续章仍使用原升级规则”样本移至第三章index16符合第二章正式采用6/4+180tick的改变。combat通用目标夹具排除chapter_two避免用不执行专有有限遭遇的通用夹具冒充第二章验收；第二章8关低/高成长另有专用自然输入旅程。此调整有对应覆盖而非简单删除失败断言。
- 新hunt_damage在真实伤害后按已存entity.phase发8×跨阶段数经验，Boss阶段发18×跨阶段数；沿用可见拾取入口，写phase后恢复不会重发。阶段奖励放在玩家位置，不要求敌人死亡后才获得；致死不推迟终态。快照沿用实体phase而未引入第二奖励账本。

## 独立复跑

Godot v4.7.1.stable.official.a13da4feb：

1. campaign_profile_test.gd：581 checks / 0 failures。此前Invalid access state与挂起回归已消失。
2. campaign_chapter_two_test.gd：246 PASS；第二章低/满成长各8关胜利，包含错标签/缺目标/Boss family负例、六顺序喷口关闭、门窗边界、容量及致死路径。
3. /tmp/ch2-profile-roundtrip-probe.gd：真实磁盘首关300tick快照，20次重开Storage/Profile+设置写盘+完整snapshot恢复一致；并发旧Profile更新仍STALE_PROFILE_RELOAD_REQUIRED。PASS，临时双槽已删除。
4. /tmp/ch2-phase-xp-probe.gd：HUNT/Boss一次跨两阶段分别16/36XP，JSON快照恢复后同phase更新不重复奖励；Arena.validate_snapshot通过。PASS。该测试直接设HP是边界fixture，不是自然试玩。
5. 先前同轮修复后的独立错标签probe返回WRONG_VENT_ACCEPTED false；最终源码仍维持对应绑定逻辑，正式246项测试也覆盖它。

这些复跑是本角色实际执行，不将主线程的完整1→16/PCK/GUI结果冒称为本人独立执行。未修改项目源码/配置或历史证据；新增probe仅在/tmp。

## 非阻断建议

- [P3 数据驱动] chapter_two.boss仍将偏移160/100、radius75、倍率1.2与duration0.4写在函数里；后续转入furnace_boss配置便于统一调优/校验。
- [P3 文档同步] ADR-0010目前未明确最终新增hunt 8XP/阶段、Boss18XP/阶段及玩家位置生成球。建议补记这些影响节奏的最终规则，便于下次复审确认期望。
- [P3 正式负向覆盖] 将独立phase XP跨两阶段/恢复不重发、精确Boss容量125/126与20轮设置写盘probe纳入正式套件，避免未来只靠自然旅程间接发现。
- [P3 防御性] valid_state按thermal索引访问layout.roots；当前固定两张layout均3 roots，安全。若未来放开布局作者配置，应同步要求roots恰3或先检查index<roots.size()，避免校验器面对不匹配自定义目录时访问越界。

保留battle_ready=false、新玩家试玩SKIPPED_BY_USER；本报告不补齐Windows/Steam、完整故障矩阵、商业Save V2、20小时与性能验收。
