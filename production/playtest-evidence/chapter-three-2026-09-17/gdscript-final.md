# 第三章最终冻结 — Codex GDScript 独立复核

限定 Verdict：APPROVED WITH SUGGESTIONS。旧潮墙/潮池缺陷及本次复现的阶段快照误拒、弹池部分发射、已知第二章旧档路由遗漏均已关闭；当前冻结未发现未解决的P0/P1/P2代码阻断。本结论仅覆盖第三章修复/配置增量及下述实际执行的验证，不是商业或真人体验批准。

## 最终绑定

- source-freeze：production/playtest-evidence/chapter-three-2026-09-17/source-freeze.json，162项，最终Profile/route-checker修复后再次核对，全部SHA256匹配，MISMATCH=[]。
- catalog SHA256：6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a。
- ADR：docs/architecture/adr-0011-chapter-three-tidal-encounters.md，含2026-09-17恢复与容量补充。
- 已读项目code-review技能、交接、旧GDScript/QA报告；旧报告的通过项没有直接当作本次独立执行证据。

## 关键修复与代码结论

1. 潮墙原点为y=-625、长度1250，碰撞半径覆盖全场高度；原半场漏洞关闭。齿间空隙仍应允许玩家通过，不能再以Boss出生点必须被齿命中作为验收标准。
2. 潮池已有同标签zone时禁止重复发射，淹没后原zone消失才重新完整预警。validator拒绝重复tide_flat并先检查layout索引范围，避免双倍伤害的重复状态被恢复；来源center/radius/damage/duration绑定保留。
3. 原Tide.valid_state严格phase==HP阶段曾真实误拒：自然seed711在tick1064/1259出现post-AI伤害跨阶段。现damage_enemy扣HP后调用boss_damage同步phase/XP/timer，只在AI调用boss时发攻击，旧预警未删除。严格phase验证得以保留，合法帧也匹配。第二章既有滞后一帧状态仍按其合同合法，不要求错误地扩大本轮改动。
4. 第三阶段预检16个zone及12个projectile，任一不足均不推进aim或攻击timer。原399弹池时“16zone+仅1弹”的部分齐射已改为整轮0发布。阶段XP先按跨越事实提交，不因容量重试重复发放。
5. M03-07最终5个后路名额，offset450、interval60；生成器/目录一致。实体自身参数未因该wave校准直接降低。固定sweep.json中选定组合为25个不同种子25胜，包括真实旅程seed1479748453；此为核读主线程产物，不声称本人重跑完整扫描或证明所有种子可胜。
6. Profile已新增CHAPTER_TWO_CONTENT_HASH=7a6edddb768b4bb813bc52bd0fd334269ebeee7a6228ac55ac0806704801420f，置入已知旧档拒读列表，进入任何设置迁移/写入前返回LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION。此前冻结缺该项会误报UNKNOWN_ACTIVE_RUN_CONTENT，现已关闭。
7. route checker现明确识别--chapter-three并取missions[16:24]，不再无声检查首章；其18项只证明静态半径25路线/护送扫掠可达，不证明潮池时序或真人路径体验。

## 本人独立执行

Godot v4.7.1.stable.official.a13da4feb：

- 冻结版campaign_chapter_three_boundary_test.gd：PASS，natural_phase_transitions=2，capacity388/389/400。每tick检查自然Boss phase，阶段变化帧验证完整快照并JSON恢复相等；容量满不消耗侧别/冷却。
- 冻结版campaign_chapter_three_test.gd：1713 PASS，低/满成长各8关自然输入获胜。1713包含重复tick断言，不代表1713种独立玩法场景。
- 冻结版campaign_chapter_three_rewards_test.gd：CH3_THRESHOLD_XP_RESTORE_NO_REPEAT_PASS。
- build_catalog.py --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。
- 最终route checker --chapter-three：CHAPTER_3_ROUTES_PASS checks=18 radius=25 swept_segments=true。
- /tmp/ch3-old-hash-route-probe.gd：最终Profile对已知第二章hash返回指定旧包错误，Storage afterimage前后不变，PASS。该探针是内存路由/零写验证；实际旧PCK四模式链由主线程另验，本人不冒称独立执行。

修复过程独立探针：/tmp/ch3-phase-lag-probe.gd自然跨阶段滞后由2降0且获胜；/tmp/ch3-projectile-cap-probe.gd 399容量由部分齐射变0发布；/tmp/ch3-codex-flood-probe.gd在旧tick460叠加复现场景内最高同池zone数为1，休潮切换后无延长静默。最后一个带保活fixture，只证明调度边界。正式边界/机制套件已把核心复现纳入冻结版回归。

上述测试无SCRIPT ERROR，项目源码/历史证据未由本角色修改，独立探针仅位于/tmp。

## 非阻断建议与边界

- [P3 数据驱动] 墙内沿偏移、伤害倍数/持续时间、池环半径/预警、12弹速度等仍有硬编码；后续统一纳入tide_boss配置，避免规则分散。
- [P3 文档精度] flooded模式现在依赖“无活zone则重发”而非简单tick%240栅格；ADR“由tick与completed_ids派生、不另存时钟”应理解为复用已持久zone寿命，无新增时钟。建议明确过渡段保留旧预警、排空后完整重发，不宣称无预警立即伤害。
- [P3 测试维护] 新boundary脚本长_run及无类型helper可拆分整理；当前编译/定向运行未发现类型错误。
- 不能采纳旧QA中“delay始终等于初始warning_ticks”的建议，因为delay每tick递减；进一步验证应考虑age/激活状态，而非拒绝合法运行时值。

最终Profile和route-checker两项局部变更后重验冻结及定向路径，无需重复与其无依赖的机制套件。本角色未独立运行最终完整1→24双路线、新PCK GUI、Windows/Steam或性能测试；那些结果需由对应证据另行支持。

保持battle_ready=false；新玩家试玩SKIPPED_BY_USER；完整故障矩阵、商业Save V2、20小时和发行验收不因本代码复核通过而关闭。
