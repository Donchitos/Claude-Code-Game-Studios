# F 增量独立审查 — godot-gdscript-specialist

结论：APPROVE（仅 F 相对 E 的 GDScript/生成器增量）；未发现可确认、需要阻断本增量的 P0/P1/P2 问题。不是全量设计或发布裁决。

## 审查依据

读取 CLAUDE.md、.claude/docs/coding-standards.md、ADR-0009。以 production/playtest-evidence/package-f-2026-09-16/before.json 指向的 baseline_copy 做真实逐文件 diff；当前 source-freeze.json 全部文件 SHA256 匹配，FREEZE_MISMATCH=[]。重点复核 arena、chapter_one、encounter、profile 与 build_catalog.py，读取调用顺序、恢复 validator 与相关测试。

## 关键结论

- campaign_arena.gd:595–610：敌方死亡统一调用 drop_xp；容量满时加完整 amount 并刷新 120 秒寿命。新入口排除非有限坐标、非有限经验与非正经验。按当前合法目录，容量与快照上限一致。
- campaign_arena.gd:612–622：任务可覆盖吸引半径/速度，未配置任务仍走旧值；拾取仍需实际接近，未新增第二个经验账本。
- campaign_chapter_one.gd:14–18、75–81：线索计数先递增后生成球；Boss 以已存 boss_phase 为单调下界并按跨越次数发奖，恢复后相同阶段不重复。最大两次阶段奖励；终态仍由原有 Mission 顺序优先处理，不为升级延长任务。
- campaign_encounter.gd:179：tutorial 第 4 位与 last_upgrade_tick 的双向等价守卫补上重建 numeric_bits 后的语义矛盾检查；并未改变既有 V3 形状。
- campaign_profile.gd:9、60：E 原始目录 hash 与 before.json 相符；在设置迁移或写入前拒读已知旧进行中档。此处仅增加旧 hash 路由，没有改变无进行中档的读取路径。
- build_catalog.py:181–190：首章除 06 外的吸引参数、04/08 奖励写入目录；6/4 与 180 tick 保持不变，后七章未增加奖励/吸引覆盖。生成器 --check 成功。

## 独立执行证据

Godot v4.7.1.stable.official.a13da4feb：

- tests/integration/campaign_pacing_rewards_test.gd：17 checks，0 failures。
- tests/integration/campaign_upgrade_guard_test.gd：9 checks，0 failures；使用 --evidence-root=/tmp/f-gdscript-review-evidence，未覆写历史证据。包含 Profile 拒绝矛盾快照且双槽字节不变，以及恢复后的 179/180 tick 边界。
- /tmp/f-gdscript-independent.gd：独立追加满容量时同时跨两阶段的 36 XP 合并、TTL 刷新、Boss HP 回升不降低阶段/重复发奖、非法输入不改银行、elite _reap 完整 XP 合并；全部断言通过。
- 独立 probe 首次用了 Boss 任务空 elite_ids[0]，在 /tmp 修正为目录精英 ID 后通过；该次是 probe 构造错误，不是生产缺陷。
- python3 tools/campaign/build_catalog.py --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。

## ADR 与质量边界

F 修改与 ADR-0009 F 扩展一致；新 public drop_xp 有文档注释、可直接注入状态验证，玩法奖励和吸引值来自生成目录。测试覆盖支持上述逻辑结论，未把自动化当真人手感证据。本审查不推断其余 E 前代码没有缺陷，不认证完整故障/断电矩阵或平台表现。新玩家试玩 SKIPPED_BY_USER；battle_ready=false 保持。
