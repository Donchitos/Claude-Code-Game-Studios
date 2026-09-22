# F增量独立QA复审

建议 verdict：APPROVED WITH SUGGESTIONS，仅限F增量逻辑、集成与自动证据隔离；不是商业发布裁决。本轮重新审阅并复测，不沿用E verdict。未发现需修复的P0/P1/P2缺陷，亦未证实新增P3产品缺陷。新玩家试玩SKIPPED_BY_USER，不作为阻塞，battle_ready=false。

## 绑定与范围

基线为production/playtest-evidence/package-f-2026-09-16/before.json及其baseline_copy；逐项检查source-freeze.json的63个文件，全部hash匹配。当前catalog SHA256为31f5f97f71efde814a73ae6d9d91e6b8205b5b6dbd15e4dfd48bfbad1e65d569。读取ADR-0009 F扩展、Arena/Encounter/Chapter的相对E增量、evidence helper、正式E journey、upgrade_guard/pacing_rewards和D hunt故障fixture。未修改项目源码、测试或旧证据。

## 已完成的独立执行

Godot 4.7.1，headless，本轮日志和journey artifact位于/tmp/f-qa-review-20260916/。

- upgrade_guard：9 checks，0失败。真实Profile/双槽：missing-choice-tick和missing-choice-bit均拒绝，错误INVALID_BATTLE_CHECKPOINT，两槽原始字节完全不变；重建Storage/Profile/Arena后179 tick无候选，180 tick发布。证据upgrade.log。
- pacing_rewards：17 checks，0失败。线索奖励JSON恢复后不重复、boss阶段恢复不重复、跨两阶段36 XP、满容量合并完整21 XP、吸引半径/速度与06及后章未改、胜利/超时同tick优先于升级。证据pacing.log。
- D hunt真实磁盘故障：日志明确HUNT_CAPACITY_RETRY_EXHAUSTED；save/home及quit均INVALID_BATTLE_CHECKPOINT；两槽不变，新Storage重载后恢复到clues=2且error为空。证据hunt.log，末尾D_ROOT_DISK_GUARD_PASS。测试35–38行在60步循环中合法解决升级/机缘，未关闭升级机制或重写选择状态。
- 正式E journey（现在承载F catalog），安全路线：8/8，77次真实磁盘恢复，13161次逐tick完整快照/RNG相等断言，256.55 active秒；选择次数[6,2,4,2,3,10,2,3]，06自然S1-V01。
- 正式E journey，风险路线：8/8，75次恢复，13037次逐tick断言，263.7667 active秒；选择次数[5,2,4,2,2,11,3,3]，无进化。
- 两条正式旅程并行运行且证据目录不同，均PACKAGE_E_JOURNEY_PASS；合计152恢复、26198次逐tick完整快照比对，无新增失败。

实际artifact：
- /tmp/f-qa-review-20260916/31f5f97f71ef/journey-e/1789543340-28928-176328/journey.json
- /tmp/f-qa-review-20260916/31f5f97f71ef/journey-e/1789543340-28927-183667/journey-alternate.json

## E问题关闭与F证据判断

1. campaign_encounter.gd:179的tutorial选择位与last_upgrade_tick等价校验，配合upgrade_guard双槽负例，关闭本QA在E复审证实的单字段哨兵矛盾问题。它是语义一致性保护，不应宣称抵抗同时伪造多个字段的任意存档篡改。
2. campaign_package_e_journey.gd:78的assert现已位于future循环内部、两个branch推进之后，79行才累加compared_ticks。本次26198可称逐tick相等断言数，E原脚本的窗口末比较口径不再沿用。
3. campaign_evidence.gd:9–19使用content hash/suite/时间-PID-ticks目录，原子make_dir失败不复用，写入run.json；journey/snapshot继承的EVIDENCE已脱离旧日期目录。并行同suite复跑验证目录隔离。全catalog hash与引擎/参数写入manifest；源码绑定由独立source-freeze提供。
4. F新增奖励在保存的clues和单调boss_phase变化时产生，奖励本身进入pickups快照；吸引与拾取继续由Arena拥有。两个合法新档路线未出现恢复重复发奖/候选冷却绕过，短关选择提升有可重复自动路线证据。

## 非阻塞纯覆盖建议（不是已证实产品缺陷）

- campaign_pacing_rewards_test.gd:82–96只证明终态与升级的执行优先级。胜利fixture会直接改elapsed而未同步tick/encounter计数；超时fixture也未预置全部已到期stage计数，所以不能用这两条断言声称该终态快照可通过严格校验并入盘。后续可增加合法可恢复前态→终态→Profile.save_run→重建的专项链路。本轮没有发现正常终态保存失效，不能将此测试范围限制升级为产品缺陷。
- 152次恢复是按阶段/线索/攻击/选择等变化采样，含每关初始恢复；后续分支最多200tick、终态提前停止。26198次断言不是全部状态覆盖、断电/IO切点矩阵、独立进程强杀或Steam/Windows证据。
- 奖励与拾取调优后的自动选择次数可说明这两条bot路线改善，不能替代真人体验或把全部短关观察带宣称通过。

必改项：无。建议保持整体商业/全量恢复/图形与设备证据边界，不因该QA verdict关闭其他未完成范围。
