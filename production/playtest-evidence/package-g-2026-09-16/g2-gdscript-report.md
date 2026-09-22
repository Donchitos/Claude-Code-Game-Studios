# G2 GDScript / 调度与 observer 独立审查

限定 verdict：APPROVED WITH SUGGESTIONS。当前最终 G2 freeze 未发现 P0/P1/P2 阻断；不覆盖被否决 experiment1、不预先批准 G3、不作体验或发布裁决。

## 冻结与差异

g2-freeze.json 的5个文件 SHA256 全部匹配。以 g1-catalog.json 作结构化对比，仅03、05的 encounter_stages 与双语briefing变化；05 hold_seconds=6.6 以及HP/速度/XP/视野边界没有变更。生成器 --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。

## 代码结论

- build_catalog.py:276–286：03保留旧0/1/3三个stage对象并分别置WAYPOINT值0/2/3，行数为8、8+4、8+4，总32不增量。附加行的45/30 offset及全行45 interval满足当前说明；未重复使用同一个stage引用，移除旧中间段没有残留被调度对象。
- build_catalog.py:287–294：05仍有4个唯一stage ID，值[0,0,2,2]，每对共享触发时刻但独立counts；每对第二个stage所有行offset+30，保留原第二行90偏移。因此两对实际offset为[0,90]与[30,120]，并非所有敌人同tick出现。
- Encounter.reached(CLEANSE_HALF)要求当前区hold>0后才触发偶数值；新局05的两个value0不会因值为0而提前在开局触发。valid_state既有CLEANSE_HALF例外允许真实入圈时刻，支持配对相同trigger_tick；03 value0仍必须tick0，value2/3随真实waypoint递增触发。没有新增快照字段或runtime writer。
- campaign_package_g_test.gd新增03/05自然输入旅程，检查03在第1tick仍只有初段已触发、后两段时刻递增，05两对同tick触发且后一对晚于前一对；终态快照合法并胜利。没有修改HP/时间/hold或调度状态制造成功。

## 新 G audit observer 边界

campaign_package_g_audit.gd只读取 old_landings 深拷贝、推进前后状态，不修改Boss、追猎或任务。landing ID由tick/x/y序列化组成，按首次出现记录当时phase；现有landing未来tick和有限延迟避免跨攻击碰撞。boss_warnings统计的是落点预警entry，phase1一轮有2个，不能当攻击轮数。boss_observed_landings统计的是旧列表到期且该步之后Boss仍存活的entry；不等于伤害命中，也不是直接插桩位置落地。致死同tick被排除，这一点在输出scope里明确。

hunt_phases记录每tick后的状态变迁，包含刚生成时phase0；不代表每项完成了一次完整冲锋。先前的 chapter.hits 是内部计数，不能代替新落点observer。威胁时间仍仅是320单位内活着非target/任意hostile zone的采样累计，不当真人体验。

## 独立执行

Godot 4.7.1：

- campaign_package_g_test.gd：PACKAGE_G_CHECKS 48 PASS。
- campaign_package_g_audit.gd 默认路线：8关 PASS；独立证据 /tmp/g2-gdscript-evidence/aaa6f439ff53/g-pacing-audit/1789548636-35506-168857/。
- 本次03：planned=attempted=32，skipped=2；三段trigger_seconds约0/6.15/13.7167，elapsed≈20.1833。
- Boss observer实际记录9条预警entry、8条存活条件下到期entry；phase2警告due992而kill_tick948，未伪报phase2落地。这正是G3前应保留的证据边界。

## 非阻断建议

[P3 覆盖] 专项只检查stage相对时序和最终合法性，建议将03 8/12/12总量、WAYPOINT [0,2,3]、05 [0,0,2,2]以及offset/interval精确值加入正式断言。现有实现与目录已独立核对正确，但错误调优值未必导致当前旅程失败。

[P3 证据健壮性] observer可以补充旧到期entry确已从新landings移除的断言，进一步避免未来scheduler回归时仍把“到期”叫作“观察到落地”。当前源实现会处理并移除到期landing，且scope明确仅due-entry观察，因此当前数据不是已确认误计。

ADR-0009 G2方向一致，沿用现有WAYPOINT/CLEANSE_HALF，无额外等待或空间谓词。该审查只说明最终G2逻辑/配置与限定自动证据可信，不保证压迫感目标达成。SKIPPED_BY_USER、battle_ready=false 保持。
