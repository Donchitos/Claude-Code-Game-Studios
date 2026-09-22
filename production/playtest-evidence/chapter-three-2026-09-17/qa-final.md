# 第三章最终冻结限定 QA 复验

2026-09-17。**APPROVED WITH SUGGESTIONS，仅限下述机制/恢复/测试诚实性范围**。本轮未发现未解决的 P0/P1/P2 代码缺陷；此前唯一确认 P3 重复潮池已修复并独立闭合。最终两路线旅程及整包回归仍须由主线程分别核实，本报告不预先声称 PASS。新玩家 SKIPPED_BY_USER，battle_ready=false。

冻结 `production/playtest-evidence/chapter-three-2026-09-17/source-freeze.json` 全162项 SHA256 独立计算匹配，0 mismatch；freeze自身SHA `e739e84a44f80de9ef1d6761840f0a57dcef956bf80b056d91d24c62860a3289`，catalog `6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a`。证据 `/tmp/ch3-codex-qa-20260917a/freeze-check.json`。

最终冻结独立复跑（均带 campaign-validation 与隔离 evidence-root）：

- mechanics-final.log：1713 PASS，16场fixture胜利；原1710断言未弱化，增加每闸重复池负例3条，均重建numeric_bits。
- boundary-final.log：CH3_BOUNDARY_PASS natural_phase_transitions=2 capacity=388/389/400。自然Boss战经过两次阶段转换，每次立即JSON恢复完全相等；388弹容纳完整12弹+16zone，389/400弹时不新增zone/弹、不翻aim、不消耗冷却。
- probe-final.log：正式damage_enemy边界phase同步恢复PASS，重建bits的非法phase负例PASS，永久潮池500个连续tick逐点JSON恢复/相同输入下一tick完整快照相等PASS；DUPLICATE_TIDE_ADMITTED=false。
- 所有上述日志无 SCRIPT ERROR/ERROR/FAIL。reward正式测试本次先前已独立PASS，最终新增改动为重复潮池校验/测试，未改变奖励实现。

修复复核：campaign_chapter_three.gd:77-84以seen_flats拒绝同索引第二条zone，同时检查layout根索引；campaign_chapter_three_test.gd:48-51的负例明确重建bits，验证抵达语义层。这关闭中间报告的P3，不再保留为待整改。

保留的纯覆盖/工具建议：journey粗潮汐fingerprint不等于全相位覆盖；失败dump固定/tmp路径可能被并行路线覆盖；旧QA关于delay必须等于初始warning的建议不成立（delay逐tick递减），未来如强化应检查剩余时长/age一致性。全局seed与每局run.seed已经明确区分且旅程现在记录后者；固定seed批次校准属于定向自动证据，不是人类体验，也不替代两条最终连续旅程。

以下中间审查记录仅作发现与闭合沿革，旧“重复潮池已接受”结果已被上文最终复验取代。

---

# 第三章 Codex 独立 QA 复核（校准中间态）

2026-09-17，按 code-review 技能，只读工作树。限定结论：**APPROVED WITH SUGGESTIONS（本次机制与恢复专项）**；整包/最终冻结验收仍 **REVIEW PENDING**，不预支校准后两条 1→24 旅程与最终 hash 的结论。新玩家 SKIPPED_BY_USER，battle_ready=false。

## 实测证据

全部独立输出 `/tmp/ch3-codex-qa-20260917a/`，Godot 4.7.1。执行带 `--campaign-validation --evidence-root=/tmp/ch3-codex-qa-20260917a`，未改项目、未覆盖历史。

- `mechanics.log`：CHAPTER_THREE_CHECKS 1710 PASS，8关×无成长/高成长矩阵16场胜利；无 SCRIPT ERROR。
- `rewards.log`：CH3_THRESHOLD_XP_RESTORE_NO_REPEAT_PASS；无 SCRIPT ERROR。
- `probe.log`：DAMAGE_BOUNDARY_PHASE_RESTORE_PASS；PHASE_NEGATIVES_REBUILT_BITS_PASS；FLOOD_JSON_RESTORE_EVERY_TICK_PASS steps=500。
- 独立探针先让首闸死亡并经一次正式 advance 收束，再连续500个tick：每步 snapshot→JSON→新Arena恢复→两边相同输入推进1tick→完整快照相等；每个潮池始终最多1条活zone。证明这条夹具路线的永久潮池恢复不产生叠池，不能扩写为所有输入/所有关卡恢复证明。
- Boss 经正式 damage_enemy 跨越两个阶段后立即 snapshot，phase=2，可恢复且完全相等；phase -1/0/1/2.5/3 的负例均重新生成 numeric_bits 后被拒，排除了codec先行拒绝造成的假阳性。

读取结束时 catalog SHA256 `6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a`；Tide源码 `7b8a75e3cc0a424834a56ffc856f0e2d5def232e86d7d542fe8a96b12aaace76`；mechanics测试 `41fae576634e70f854542fff796383eb754653a1dd55742c7c72c1cdf814dcd3`；journey测试 `e77db4632a35bc45033300ee0ccbe7094160b763fb94e8a539af37eda9984cc0`。主线程同期校准，以上不是最终冻结凭证。

## 已确认非阻塞问题

**P3：重复同一 tide_flat 的人工坏快照可被接受。** `src/campaign/campaign_chapter_three.gd:76-83` 逐条校验池索引和几何，但没有集合唯一性。独立探针在上述正常永久潮池快照中复制一个合法zone并重建 numeric_bits，输出 `DUPLICATE_TIDE_ADMITTED=true`。这样恢复会保留两份伤害源，违反正常 Encounter 的“同池最多1条”约束。正常writer未观察到此问题，因此评级为主动篡改/异常状态入场强化，不是正常恢复阻塞。最小建议：valid_state按 tide_flat 建seen集合拒重；补重建bits的负例及合法单条正例。

## 测试诚实性与恢复语义

1. journey:19 的711/977是全局随机流种子，:25 begin_run 生成每局 run.seed，:29 Arena使用后者。直接Arena(seed=977)不等于替代路线M03-07。当前:106已记录run_seed，这是必要的可复现性修复；仍要用最终全旅程重跑结果，不把抽样seed通关率当成路线通过。
2. 当前 damage_enemy 调用 boss_damage 在伤害边界同步phase/奖励，再由boss AI发招。这正面解决了AI之后 projectile/zone造成伤害的保存窗口。仅添加“phase等于HP派生值”的validator会误拒该窗口，旧QA未考虑此时序，当前实现已补齐。
3. 机制负例中错目标字符串不改变numeric bits；清空实体、错潮池tag、错family、phase回退均重建bits。它们确实能触及语义校验，不是单靠sidecar不一致获得拒绝。
4. 旧QA建议直接绑定zone.delay等于warning_ticks/60不可照搬：`campaign_combat.gd:254-257`每tick递减delay，正常恢复值本就不等于初始值。若强化应验证剩余delay与age及允许浮点边界，而非初值相等。
5. 已有hunt timer中断、Boss112+16容量正例、永久潮池持续500tick检查都是净增强；原reward夹具仍使用手工降血并直接调用Tide辅助函数，不单独证明生产damage入口，本次独立探针已补Boss入口的及时保存窗口。
6. 包E把第三章默认XP假设迁至第四章，并对第三章新增局部6+4曲线断言，符合ADR0011局部经济决定；不能把旧未实现内容默认值当永久合同。

## 纯覆盖与证据建议（不新增代码缺陷）

- journey:57 的 tick%450>=90 只有粗二值，并未逐一标记三池错峰、active→rest、破闸后240周期；当前200tick逐tick重放窗口与本次500tick逐点恢复不能称全边界覆盖。建议日后按每池实际phase/活zone边界采样。
- journey:80/:98 使用共享 `/tmp/ch3-failed-restore.json`，两路线失败可能互相覆盖诊断文件。建议改到各自evidence目录。
- 安全路线与替代路线必须披露完整flags，替代角色不自动代表risk-route；run.json参数为准。恢复逐tick对照是确定性证据，bot胜利不是体验或难度合理性结论。
- 最终hash尚需绑定两路线完成输出及作者矩阵/终局/精度等结果；旧QA的44fab78cd781与交接f7f6c... verdict不可直接移植到新内容。
