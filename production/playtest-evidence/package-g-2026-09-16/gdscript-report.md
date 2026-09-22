# G 最终冻结独立 GDScript / 配置审查

限定 Verdict：APPROVED WITH SUGGESTIONS。未发现确认的 P0/P1/P2 阻断问题。覆盖 G1/G2 已审配置及当前 G3 runtime 增量、相关测试适配；不是全量设计、真人体验或发布批准。

## 冻结与范围

production/playtest-evidence/package-g-2026-09-16/source-freeze.json 全部 SHA256 匹配（FREEZE_MISMATCH=[]）。最终目录 SHA256=b4b4a50190f3bf99b182956bc79d0d98c31a3777077de800bd7f483c0a6c5cbc。G1/G2判断结合本轮重新读取的最终生成器、专项测试与ADR-0009最终实施确认；原F基线相比runtime变化只有Profile已知F hash、Encounter新flag admission、Chapter.boss阶段入场分支。

## G3 核心结论

- campaign_encounter.gd:83：新flag必须为bool且任务拥有boss_chapter。既有valid_chapter_definition进一步限制BOSS任务与完整boss配置。最终目录只在08设置true；false/缺省沿用旧timer行为。
- campaign_chapter_one.gd:75–80：先以已存boss_phase作单调下界，按跨越次数掉落XP，只有phase真实上升且flag打开才清零既有entity.timer。后续同phase重试不重复XP、不再次清timer。没有新增持久字段，numeric_bits已覆盖timer。
- campaign_chapter_one.gd:81–88：旧landing先按原tick/位置执行移除，未排空就返回；排空后才可发布当前phase的完整预警。正常进入phase1最多新增2个landing，phase2最多1个；新flag防止旧+新积压突破2个，既有validator继续约束pending<=2和未来tick上限。
- campaign_chapter_one.gd:90–104 与 Combat.zone:172–176 的容量128一致。先计算本阶段需要1/2/4个zone，容量不足直接返回，不写attacks/first_warning/landings。下一ticktimer为0或负值仍能重试；足够时全部zone可成功入池，不出现部分可见、部分不可见的攻击。
- 终态顺序未改变：Combat跳过已死Boss，_reap与Chapter.advance清pending，Mission终态先于升级发布。Boss死亡不等待预警完成；跨多个phase可直接进入最高当前阶段，并无强制逐阶段表演承诺。
- Profile F hash与真实baseline-f目录一致，目录内容hash绑定新行为；已知F进行中档仍走旧包结束/主动放弃，新包在迁移/写入前拒读。无进行中档路径未变。开发中的G1/G2不是额外承诺的旧发行档兼容层。

## 测试审查及独立复测

Godot v4.7.1.stable.official.a13da4feb，本轮直接执行：

- campaign_boss_entry_test.gd：最终增补后独立复跑130 checks / 0 failures。100项来自待处理攻击恢复后逐tick完整snapshot对照，不能说成130个独立场景；其余覆盖完整54/84 tick预警、旧landing保留、排空后tick85新预警、容量不足、致死立即结束，以及独立_capacity_boundaries helper的flag admission/false模式/125与124精确容量/重试36XP/合法快照。
- campaign_package_g_test.gd：58 PASS。已加入02/07的89/90 tick及JSON恢复相等，以及03/05精确stage value断言；G1关键边界建议已落实。
- campaign_pacing_rewards_test.gd：17/0。Boss夹具先合法推进首tick再伤害，避免tick0 attack/first_warning语义矛盾；没有放宽生产validator。保留跨两phase36XP与恢复不重复发奖。
- campaign_package_c_test.gd：237 PASS。半程谓词使用duplicate的stage显式value1，验证仍支持的CLEANSE_HALF奇数分支；不把它当当前G目录半程投放证据。
- python3 tools/campaign/build_catalog.py --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。
- /tmp/g-final-gdscript-probe.gd 独立新增：flag int/String/null拒绝、非Boss任务flag拒绝；false模式不归零timer；phase2 zone占用125时拒发、124时完整发4个；重试XP仍36且快照合法。全部通过。探针首次误把初始已有zone忽略，修正/tmp填充逻辑到准确总容量后通过，非生产问题。

测试只写/tmp probe，未改项目源码/历史证据。fixture直接调整HP/zone/冷却仅用于边界验证，未冒充自然试玩。

## 非阻断建议

[已关闭：测试增强] 独立probe的新flag坏类型、非Boss、false模式、125/124精确容量边界、重试XP=36与合法快照已纳入正式_capacity_boundaries helper；本轮逐行复核及130/0定向复跑确认，关闭该覆盖建议。

[P3 可维护性] 新/扩展测试仍沿用较长_run和部分无类型helper。可拆分场景及声明参数/返回类型；本次没有由此发现运行缺陷。

G1/G2当前仍保留0/0/1与WAYPOINT0/2/3、CLEANSE_HALF0/0/2/2配置；05 hold6.6未变。ADR-0009最终确认与实现相符。G audit到期observer只读，不能把warning条目/到期条目当命中、强制阶段完成或真人压迫感证明。

battle_ready=false；新玩家试玩SKIPPED_BY_USER；本报告不补齐Windows/Steam、完整故障矩阵、商业Save V2、20小时与性能验收。

## 最终测试增补复核

对比 source-freeze-before-boundary-test.json 与当前 source-freeze.json，仅 tests/integration/campaign_boss_entry_test.gd hash变化；所有当前冻结hash匹配。src/runtime与目录冻结条目无变化。新helper在duplicate任务定义上改flag；容量填充以当前zones.size()<125为准，包含首tick既有zone；释放一个slot后校验完整4-zone发布，故未沿用独立probe初版的计数错误。make后再次configure仍在advance前重建新局，没有跨场景状态污染。保持APPROVED WITH SUGGESTIONS，仅长方法/部分helper类型的非阻断可维护性建议未关闭。
