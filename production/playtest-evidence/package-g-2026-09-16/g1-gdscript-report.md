# G1 GDScript / 配置增量独立审查

限定 verdict：APPROVED WITH SUGGESTIONS。未发现 P0/P1/P2 阻断问题，仅对当前 G1 冻结有效；不裁决 G2/G3、真人体验或发布。

## 范围及依据

完整读取新增专项测试、build_catalog.py apply_chapter_one_g1、Profile F hash 路由、ADR-0009 G 说明，并复核 Encounter create/reached/due/advance/valid_state 与现有边界。使用 package-g-2026-09-16/baseline-f 做真实对比。g1-freeze.json 四文件 SHA256 全部匹配。

## 发现与判断

- build_catalog.py:262–273 只作用于 missions[1,6]；value=[0,0,1]，第二段 offset+=90、第三段 offset+=45，每行 interval=45，与 ADR 一致。02 第三段原有第二行 offset90 保留并变为135，没有意外把相对偏移清零。
- JSON 结构化差异精确限于 S1-M01-02/S1-M01-07 的 encounter_stages、briefing、briefing_en。敌人数目、HP/速度/XP、锚点/根区、后七章、首章其余关卡、生成视野边界均未变。
- campaign_encounter.gd:85–101、107–111、184–195 的已有逻辑兼容两个 value0 stage：新局均 stage_tick0；due 在 tick0 返回0，offset90 对应 tick90 首次调度；validator 按每个 stage 独立 ID/计数而非 trigger value 唯一性检查。第三段只有 progress>=1 才启动，value0 的恢复必须保持 trigger0，未放宽语义守卫。
- campaign_profile.gd:9、61 的 PACKAGE_F_CONTENT_HASH 与 baseline-f 原始 JSON SHA256 一致；旧进行中档在设置迁移及写入前拒读，保留旧包结束/主动放弃路由；无进行中档不因历史目录而拒读。
- 专项测试自然 bot 跑低/高成长02/07，额外用大伤害探测未激活锚点免伤，实际HP未变；检查胜利、合法终态快照与07 root_mask=7。高成长为保留档夹具，不是新玩家体验样本。

## 独立验证

Godot 4.7.1.stable.official.a13da4feb：

1. campaign_package_g_test.gd：PACKAGE_G_CHECKS 35 PASS。
2. python3 tools/campaign/build_catalog.py --check：CATALOG_REPRODUCIBLE 364 rows / 64 missions。
3. /tmp/g1-gdscript-probe.gd：两个目标任务 tick0合法快照、tick89第二段count=0、JSON序列化恢复并在tick90第二段count=1、恢复与未恢复完整snapshot相等，均通过。
4. 同一独立探针使用真实 baseline-f JSON/hash 创建 Profile进行中档；新版拒读 LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION，memory Storage profile_snapshot未变；在旧目录 Profile 主动放弃后，新目录可正常加载无进行中档。此条是内存 afterimage 路由探针，不是双槽/PCK兼容或断电验证。

探针第一次用属性语法新增 content_hash 导致 StringName key 被严格 JSON 校验拒绝；在 /tmp 改为与生产 loader 一致的字符串键写法后通过，是探针构造问题。没有修改项目/历史证据。

## 非阻断建议

[P3 测试覆盖] campaign_package_g_test.gd:16–34 检查触发value及最终胜利，但没有直接断言45间隔、90/45附加offset和第二段最早发射tick；错误数值仍可能胜利。建议后续将本次独立探针的0/89/90边界及第三段相对触发tick/offset行差纳入正式专项回归。当前冻结数值和运行结果正确，不作为G1阻断。

[P3 可维护性] apply_chapter_one_g1 是单次生成流水线变换，offset+=及briefing+=不是幂等；当前 build() 只调用一次，无现存重复应用路径。将来若复用该 helper，应注明仅用于fresh data或改为显式赋值，避免把它当通用反复调优入口。

ADR-0009 G1 COMPLIANT；复用了现有状态/触发体系，没有新增快照字段或模拟writer。敌人提前调度并不保证全部实际生成或必然形成路线压迫，仍受原生成排除和 skipped规则约束，不能将调度通过等同真人手感改善。

新玩家试玩 SKIPPED_BY_USER；battle_ready=false；Windows/Steam、完整故障矩阵、商业 Save V2、20小时及性能验收未由本审查补齐。
