# G1增量独立QA

Verdict：APPROVED，仅限G1调度调整、已有恢复契约及F旧内容hash拒读分支；不是G2/G3或整体发布批准。无已证实P0/P1/P2/P3缺陷，无必改项。新玩家SKIPPED_BY_USER，battle_ready=false。

## 冻结与实现核对

production/playtest-evidence/package-g-2026-09-16/g1-freeze.json四项SHA256全部匹配。目录hash为0ae0a6ad59ad1208df092ece6fcf509f55604013f4ac902e47f661fa63852533。与baseline-f对比，build_catalog新增apply_chapter_one_g1：仅02/07 stage value为[0,0,1]，所有row interval45；第二stage offset在旧值基础加90，第三加45。02第三stage第二row原offset90→135，未错误覆盖成45。Profile增加F hash到已有写入前拒读分支。既有Arena/Encounter/Chapter模拟规则未更改。

## 独立复测

Godot4.7.1，所有命令带--campaign-validation --evidence-root=/tmp/g1-qa-SmXzIz。未修改工作树和历史证据。

1. campaign_package_g_test.gd：PACKAGE_G_CHECKS 35 PASS。02/07各验证普通与completed64/branches[5,5,5]保留高进度loadout；初始化stage_ticks=[0,0,-1]，下一锚点提前受击HP不变；四次完整推进均victory且终态快照validate通过，07根区root_mask=7。高进度是明确夹具，不冒称新档自然成长或实际旧存档迁移。
2. 正式真实磁盘journey安全进化优先路线：8/8，79恢复，13572次逐tick完整快照/RNG比对，270.60 active秒；各关选择[6,4,4,2,3,10,3,3]，06自然S1-V01。
3. 正式journey alternate+risk路线：8/8，75恢复，13025次逐tick比对，267.1667 active秒；选择[5,3,4,2,2,11,3,3]，未进化。
4. 新写/tmp隔离F旧catalog fixture：以baseline-f完整catalog的原hash创建30tick进行中快照并真实双槽保存。G1 Profile.initialize拒绝并返回LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION，两槽原始bytes完全不变；旧catalog Profile主动abandon后，G1读取无进行中profile通过。输出G1_F_HASH_GUARD_PASS。该项是当前source+旧catalog边界夹具，不是旧F PCK实际运行证据。临时probe首版因使用dot新增StringName键而被JSON保护拒绝；已更正为String键后通过，不属于产品问题。

证据路径：
- /tmp/g1-qa-SmXzIz/g.log
- /tmp/g1-qa-SmXzIz/journey.log
- /tmp/g1-qa-SmXzIz/risk-journey.log
- /tmp/g1-qa-SmXzIz/legacy.gd 与 legacy.log
- /tmp/g1-qa-SmXzIz/0ae0a6ad59ad/journey-e/1789548318-35016-328494/journey.json
- /tmp/g1-qa-SmXzIz/0ae0a6ad59ad/journey-e/1789548318-35014-327859/journey-alternate.json

## 作者遥测审计与边界

读取作者G1两路线run.json确认safe带--qa-production-evolution、risk带--alternate-build --risk-route；所查02/07结果：safe分别15.2333s/19.4667s、4/3选择、32/18 attempted、5/7 skipped；risk分别13.7833s/19.1333s、3/3选择、32/18 attempted、4/8 skipped。两任务均通关，与提前调度允许敌人更早接近的实现一致。attempted并不保证全部成功生成，skipped保留屏外生成候选/容量等已有政策；不能据此声称每段设计敌人都必定出现。

未发现测试路径软锁或恢复重复调度；79+75恢复及26597逐tick断言仅覆盖两条合法bot路径与所选恢复点。高难度、所有角色/丹药/挑战组合、完整断电/IO矩阵、所有高进度真实存档和真人体验不在本次证明范围。G1测试的冻结锚点免伤、根区关闭、终态验证及正式双路线恢复已满足本轮限定QA。
