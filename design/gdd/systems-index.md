# Systems Index: 凡人修仙传·掌天试炼（MVP）

> **Status**: Draft
> **Created**: 2026-08-14
> **Last Updated**: 2026-08-28
> **Source Concept**: design/凡人修仙掌天试炼-MVP设计方案.md
> **Review Mode**: lean（TD-SYSTEM-BOUNDARY / PR-SCOPE / CD-SYSTEMS 三个 director gate 均跳过）
>
> 2026-08-19: 新增 Stage & Map（#6, Foundation/MVP/Draft）；系统总数 31→32、MVP designed 4→5。
> 2026-08-19: Stage & Map 第二轮 full design-review 通过（NEEDS REVISION→修订闭环→Approved）；Design docs reviewed 0→1、approved 0→1。
> 2026-08-19: SpatialGrid 第四轮 full design-review 通过（8 项 BLOCKING 全部闭环 + 4 项措辞/追溯小改）；NEEDS REVISION→修订闭环→Approved；Design docs reviewed 1→2、approved 1→2。
> 2026-08-20: Object Pooling 首轮 full design-review（NEEDS REVISION, scope M）；7 项 BLOCKING 主题聚合（instance_id ABA / 容量余量协调 / 零分配可验证 / damage_number fault / R7 publish 复检 / F3 precedence / 覆盖矩阵）已修订写入；不改公开契约，下游 GDD 可基于当前契约并行启动。Design docs reviewed 2→3。
> 2026-08-20: Object Pooling 重审 full design-review（NEEDS REVISION, scope M）——首轮 B-fix 协调公式与 F-fix release_status 分段各自引入新形式化缺陷（F1 协调公式 double-count quarantine + 非 Grid 键丢 max_concurrent + boss 2>1 与 L38 不变量冲突；F3 borrow_valid 死分支使 OBJECT_INVALID 不可达、削弱 ABA 防御；F3 precedence 文本与伪代码矛盾），4/5 specialist（systems/godot/perf/qa）判 NEEDS REVISION + creative-director 独立读原文复核 CONFIRMED。3 项已二次修订写入（F1 删协调公式回归 L155 required_capacity + L159 改 scope 措辞；F3 拆 borrow_identity_valid/node_alive + 伪代码 step1/step2 + precedence quarantine>state>handle + OBJECT_INVALID 退休fault）。核心机制与公开契约未变，待三审。approved 仍 2、reviewed 仍 3、object-pooling 仍 In Review。
> 2026-08-20: Object Pooling 三审 full design-review 通过（NEEDS REVISION→修订闭环→Approved, scope M）。3 项二次修订（F1/F3/precedence）经 systems-designer 逐公式代入边界值确认闭环。本轮 7 BLOCKING 全为局部可修、不改公开契约核心、不需新 ADR：BL-1 AC-B4 precedence 同步 F3（二审 incomplete-fix 回归）；BL-2 AC-D3 改 GameRoot phase-gate（user 裁决 A）；BL-3 R9 补 3 ABA counter；BL-4 R2 carrier 补 node_ref 字段；BL-5 enemy_elite capacity 4→6（user 裁决 A，safety_spare 1→3、Σ=6、1189→1191，同步 config-data-system.md 10 处）；BL-6 R3 补 4 零分配禁止项（call_deferred/signal/StringName/Dictionary）；N1 R3 Tween 措辞矛盾。+2 advisory（R3 禁 free()、R2 三校验短路顺序）。creative-director 终审 NEEDS REVISION，核心机制 Godot 4.7.1 稳固。carrier 扩 1 字段（node_ref，additive），PoolStatus/状态机不变。Design docs approved 2→3；object-pooling In Review→Approved。defer 项（C2/C3 positive control 对齐、systems #2、godot R1/R11、perf F3a/P2、qa #7/#8、W1）归实现期/owner GDD/lean follow-up。
> 2026-08-24: /review-all-gdds (design-theory) 完成 CONCERNS→1 Blocking 闭环：config EC7/L59/AC-B4 与 object-pooling R1 对 PRESENTATION overflow 行为矛盾（config 说 failure→ControlledFault，object-pooling 说 OVERFLOW_DROPPED）→ 对齐 config 到 object-pooling R1（pool owner 权威），3 处文案改走 OVERFLOW_DROPPED，不改公开契约。F1 enemy_elite 语义纯化经核查会破坏 max_concurrent 三 key 总和(300+2+1=303)=Grid ENEMY cap 303 对齐→DEFER 不盲改。4 Warning 多 DEFERRED 下游 GDD。
> 2026-08-24: RNG System (#7 Core, lean) GDD 8 节完成→Designed。独立派生子流（SPAWN/SKILL_DRAFT/CRIT/DROP/LEI_TARGET/TREASURE_BOX/RISK_CHOICE/ZHANGTIAN_HERB 8 流）+确定性契约+零分配+fail-fast（非法参数 latch fault）。derive() 算法 deferred ADR，max_weights_length 待下游上界，跨架构浮点 AC-A5 min-spec 真机 gate OPEN。无新注册表条目（RNG 无跨边界数值事实）；run_seed 字段归 Config Phase 5 注册（AC-G2 gate）。Design docs started 5→6、MVP systems designed 5→6/27。
> 2026-08-24: RNG System (#7) full design-review（NEEDS REVISION, scope L）→修订闭环（10 项 A 级 blocker 全闭合，spec/citation 修复非重设计）→待新会话复审。跨文档 AC 错引更正（game-root AC-G1/G2 + spatial-grid AC-B7/J3）、shuffle 删除（COW 违 R4）、F4 迁 PackedInt32Array 定点整数权重（消 +inf OOB/FMA/精度/无 int 逃生四缺陷）、AC-E2 降级全局 enum 校验、R8 补消费方 has_fault() 守卫、AC-A4/A5 对称化+漂移源更正（FMA in randf_range）、F1 derive 纯整数约束、fantasy 拆玩家/dev 面、F2 委托 Godot randi_range、telemetry 改 per-stream 调用计数+schema、AC-G1/G2 改名 GATE-、补 AC-H1 state 往返+AC-D chi-square。3 OPEN（derive ADR/max_weights 下游/run_seed 来源）deferred。Design docs reviewed 3→4；approved 仍 3；RNG Designed→In Review。
> 2026-08-24: RNG System (#7) full 复审 re-review（NEEDS REVISION, scope L / revision-effort M 端）— 上一轮 10 项 A 级 blocker 全部闭环无回归（跨文档逐条核实）；本轮新发现 4 项 BLOCKING 全为 spec/citation/enforcement 修复非重设计（零新公式/零新 ADR/1 新 AC/1 新 GATE）：BL-A 零分配 PackedInt32Array 检测盲区（R4/AC-B1 未明示+positive control 未分别断言多类型，违 spatial-grid AC-J3 原则）、BL-B F4 fault 缺 Σw 上界（int64 累积 W 超 INT32_MAX 不 fault 致 randi_range 输出域不足 modulo bias）、BL-C fault gen-state invariant 声明(R7)未约束未测（telemetry 可静默记错 state→AC-G2 复现诊断崩塌）、BL-D game-root has_fault 单向依赖（R8 断言 game-root 检查 has_fault() 但 game-root GDD 零匹配→消费方忘守卫则 fault 被掩盖，违玩家面故障诚实承诺 + AC-E1/F3 可测性依赖）→提议 GATE-G3。1 specialist 分歧（BL-C 严重度 qa-lead BLOCKING vs game-designer RECOMMENDED）creative-director 裁决 qa-lead 成立。修订优先级 BL-D→BL-A→BL-C→BL-B（可并行）。RNG 保持 In Review；reviewed 仍 4、approved 仍 3。
> 2026-08-24: RNG System (#7) full 三审 re-review 2（NEEDS REVISION, scope L / revision-effort M 端）— 复审 4 项（BL-A/B/C/D）全闭环无回归；本轮新发现 4 项 BLOCKING（BL-E/F/G/H）全为迁移后规范漂移与引用/执行修复非重设计（零新公式/零新 ADR/零新 GATE）：BL-E W_MAX_SAFE 边界 2^32-1→2^31-1=INT32_MAX + scratch int→PackedInt64Array、BL-F FMA 漂移源两路径降级待核验 defer rng-math.md、BL-G AC-J3 "须取上限"反转严格性+事实性误述→改写为参考并加强+5 类独立 A/B、BL-H R8 !isfinite(W) 对 int W 死路径→移除。2 specialist 严重度分歧 CD 裁决：BL-E godot 成立、BL-G cross-doc 成立、BL-F 范围限消歧义+降级。RNG 保持 In Review；reviewed 仍 4、approved 仍 3。
> 2026-08-24: RNG System (#7) full 四审 re-review 3（NEEDS REVISION, scope L / revision-effort M 端）— 三审 4 项（BL-E/F/G/H）全闭环无回归（6/6 specialist 独立核实 + 三审末"下一轮复审焦点"4 项一致性确认）；本轮新发现 6 项 BLOCKING + 3 项 RECOMMENDED 全为 spec/citation/enforcement/可测性修复非重设计（零新公式/零新 ADR/2 新 AC/1 新 GATE）：BL-I PackedInt64Array 未进 AC-B1 positive control + element-write 禁局部别名未约束、BL-J AC-E1 fault-injection 缺 W-1>2^31-1 触发条件、BL-K AC-A1a/A1b instrumentation 无 positive control（前三轮盲区，确定性 pillar 验证基准未被验证）、BL-L randi_range 参数类型 int32 假定未核验（质疑 rationale 非值，保留 2^31-1）、BL-M 拒绝采样假定未核验 + AC-D2 边界待核验（分布 pillar 验证基准错误，后果最重）、BL-N FAULTED 终态未声明 + set_stream_state 在 FAULTED 下未约束（违承诺②"不被静默重摇"，CD 从 RECOMMENDED 升级 BLOCKING）；RECOMMENDED GATE-G4 rng-math.md 存在性守卫 + F3 !isfinite(max-min) + 承诺②交叉引用 GATE-G3。2 specialist 严重度分歧 CD 裁决：BL-I 采纳 perf 框架（qa+sys"同型模式"论据不采——BL-A PackedInt32Array 针对 range() roll 路径构造 vs BL-E PackedInt64Array BATTLE_LOADING 预分配非同型）、BL-N 从 RECOMMENDED 升级 BLOCKING（违玩家面承诺②）。9 项已全部修订闭环写入 rng-system.md（2 新 AC: AC-A1c instrumentation positive control + AC-B1 COW-on-write element-write control；1 新 GATE: GATE-G4 rng-math.md 存在性）。RNG 保持 In Review；reviewed 仍 4、approved 仍 3。
> 2026-08-24: RNG System (#7) full 五审 re-review 4（NEEDS REVISION, scope L / revision-effort M 端）— 四审 9 项（BL-I..N + GATE-G4/F3/承诺②）全闭环无回归（6 specialist 独立核实 + 四审末"下一轮复审焦点"8 项一致性确认通过 7/8，BL-N 声明-only 未 testability-闭环为本轮 BL-2 源）。本轮新发现 5 项 BLOCKING + 22 项 RECOMMENDED 全为 spec/AC/hedge/testability/boundary-parity 修复非重设计（零新公式/零新 ADR/1 新 AC AC-E1c FAULTED 终态不可复活/0 新 GATE）：BL-1 randi_range/randf/randi 零分配是假设而非验证（positive control 只证 GDScript 侧不证 native method 内部，违 GATE-G4）、BL-2 FAULTED 终态两条行为无 AC（闭合四审 BL-N 声明-only 未 testability-闭环）、BL-3 AC-E1 Gate 字段与 body 不一致+可测内核被捆绑（(3)→GATE-G3/(4)→消费方 bidirectional flag 拆出，AC-E1 仅留 RNG 级 (1)(2)）、BL-4 F2 缺范围上限守卫与 F4 W_MAX_SAFE 不对称+fallback 拒绝采样 hang、BL-5 derive GDScript int64 算术移位陷阱未标注（4 轮漏检 NEW 议题，归 OQ1 ADR）。2 specialist 严重度分歧用户裁定均采 CD BLOCKING：BL-4（systems RECOMMENDED vs CD BLOCKING，parity+hang+哲学）、BL-5（godot RECOMMENDED vs CD 主张 BLOCKING，silent-failure+pillar-invariant 同 BL-1）。5 项 + 22 RECOMMENDED 已全部修订闭环写入 rng-system.md。RNG 保持 In Review；reviewed 4→5、approved 仍 3。
> 2026-08-25: RNG System (#7) full 六审 re-review 5（NEEDS REVISION, scope L / revision-effort S 端）— 五审 5 项（BL-1..BL-5）+ 22 项 RECOMMENDED 全闭环无回归（6 specialist 独立核实 + 五审末"下一轮复审焦点"5 项一致性确认）。本轮新发现 5 项 BLOCKING + 4 项 RECOMMENDED 全为 hedge/citation/testability/对齐 修复非重设计（零新公式/零新 ADR/1 新 AC AC-H1b 跨实例状态可移植性/0 新 GATE）：BL-6 F2 fault guard `max-min` 减法溢出可绕过守卫（int64 two's complement 下 `min=INT64_MIN,max=0` 溢出为负→守卫静默不触发，BL-5 int64 陷阱同类覆盖 `-` 减法）、BL-7 R4 COW-on-write 与 F4 触发为 Godot 4.7.1 行为断言未 hedge 致 AC-B1 方法论循环失效（若 COW 不触发 AC-B1 positive control 永卡 INCONCLUSIVE）、BL-8 AC-E1c "返回 FAULTED 标志不变"与 AC-E1b+R7 三者矛盾回归（PCG state 为 uint64 无标志位，重写为 has_fault 仍 true + get_stream_state 仍 ==s）、BL-9 R7 set_state 不 re-seed 为 4.7.1 行为断言未 hedge 致 SaveSystem 跨实例静默腐化（新增 AC-H1b 跨实例可移植性测试）、BL-10 caveat 误引 R8 应为 R9 ControlledGameplayFault 玩家与持久化域。1 specialist 严重度分歧 CD 裁决：BL-7（godot BLOCKING vs performance RECOMMENDED，PA "AC-B1 会捕获 F4 COW" 为循环依赖，同 BL-1 升级先例）。RECOMMENDED：QA-2 AC-E1 Then 显式断言 has_fault 转 true、GS-5 GATE-G4 Then 解阻清单修正（移除孤儿引用 + 解阻 BL-6/BL-7/BL-9）、GS-12 OQ3 源文件 hedging、GD-4 has_fault per-stream/global 双重形式澄清。5 项 + 4 RECOMMENDED 已全部修订闭环写入 rng-system.md（1 新 AC: AC-H1b 跨实例状态可移植性）。RNG 保持 In Review；reviewed 5→6、approved 仍 3。
> 2026-08-25: RNG System (#7) full 七审 re-review 6（APPROVED, scope L / revision-effort S 端）— 六审 5 项（BL-6..BL-10）+ 4 项 RECOMMENDED 全闭环无回归（6 specialist 独立核实 + 六审末"下一轮复审焦点"5 项一致性确认）。本轮新发现 1 项 BLOCKING（BL-七-1 fault_reason 不可测——R5 未暴露 `get_fault_reason` 致 R6/R7/AC-E1c"fault_reason 不变"声明 testability 悬空，采纳选项 A：R5 新增 `get_fault_reason` + 补齐 8 公共 API + `FaultReason` enum）+ 16 项 RECOMMENDED（P0-P6：R5 API 面 / GATE-G4 Then+OQ3 scope 补 seed=+state 往返 / AC-A1c+AC-H1 措辞 / RNG-EC11-12 消歧 + R7 telemetry deferred GATE-G3 / R4+F4 禁局部别名扩展函数参数 + R7 first-failure 快照容器 + AC-B1 manifest+INCONCLUSIVE 三分支+lint 多模式 / F3 randf hedge / Player Fantasy 行29/35 措辞），全为 spec/testability/hedge/对齐 修复——零新公式/零新 ADR/零设计意图变更，已修订闭环。**修订后 creative-director 复核 APPROVED**（17 项逐项闭合 + 无回归：FaultReason↔R8 触发条件、get_fault_reason↔first-failure-wins、get_fault_reason↔has_fault↔NONE、RNG-EC 消歧无遗漏、COW 三分支↔GATE-G4 hedge 五项交叉自洽核验通过；GATE-G2/3/4+OQ1/3/6 实现前置 gate 不阻止签发）。RNG In Review→Approved；approved 3→4。GATE-G2（Config run_seed）+GATE-G3（game-root has_fault）+GATE-G4（rng-math.md 存在性）+ OQ1/3/6 deferred 至实现期/对端 GDD 更新。

> 2026-08-25: EnemySystem (#9 Core, lean) GDD 10 节完成→Designed。scope：6 普通敌人（共享 EnemyNormalPoolable/v1，behavior_id 0-5 数据驱动）+ 2 精英（EnemyElitePoolable/v1，FSM 归本 GDD，behavior_id 6-7）+ Boss 载体（EnemyBossPoolable/v1，阶段切换 defer BossStateMachine #18，behavior_id 8）。冻结 spawn_context schema v1（5 primitive：behavior_id/spawn_position/spawn_facing/spawn_time_seconds/spawn_seed）。行为契约：直线追踪（不完整寻路）+ 位置修正分离（SpatialGrid query，非刚体碰撞）+ 两级屏幕外 LOD（full/reduced）+ 对象池零分配 reset + GameRoot 7-phase participant。High-Risk 节点架构（Node2D 手动更新 vs CharacterBody2D 物理驱动）defer /architecture-decision ADR。registry 回填 max_enemy_bound/enemy_overshoot_max/separation_radius owner 至 max_query_radius + index_margin_lower_bound referenced_by（数值待 Config 调参后重跑 F3 sweep）；knockback_max 归属声明 Combat/DamageSystem（Open Question #2）。8 项 Open Question（节点 ADR/knockback 归属/max_enemy_bound 上界/分离时序/borrow-insert 时序/Boss participant 边界/腐毒妖藤静态/精英 FSM 充分性）。Design docs started 6→7、MVP systems designed 6→7/27。待新会话 /design-review。

> 2026-08-25: EnemySystem (#9) full 第二轮 design-review（NEEDS REVISION, scope L）→修订闭环（6 批次 B1-B6：性能 spike-gating+escape valve 诚实化 / 收敛复杂度契约重写 / FSM 可编码性补全 / 零分配代码审计 AC 方法论 / 公式边界一致性 / Player Fantasy 措辞）→待第三轮重审。CD 裁定拆分冻结（行为契约冻结 / 性能 AC spike-gated 未冻结）。Design docs reviewed 6→7；approved 仍 4；EnemySystem Designed→In Review。

> 2026-08-25: EnemySystem (#9) full 第三轮 design-review（NEEDS REVISION, scope L / revision-effort S 端）— 第二轮 6 批次（B1-B6）经 6 specialist 独立对抗性核实全部成立无回归；本轮新发现 9 项 BLOCKING + IC-1 措辞 + 4 项 RECOMMENDED（AI-3/4/5/6）全为 spec/citation/传播/testability/归属 修复非重设计（零新公式/零新 ADR/零设计意图变更）：B-1 跨文档传播回归（F-1 max 形式未传 stage-map/spatial-grid/registry + query_radius separation 项矛盾）/ B-2 Config 虚引 / B-3 IC-3 CHARGE 双实现 / B-4 normal 桶 mini-FSM 系统性缺失+状态存储悬空 / B-5 血傀儡自爆伤害归属 / B-6 AC-E4 守卫体系 / B-7 frames_to_epsilon 上界 / B-8 AC-E19 软 gate / B-9 IC-2 时序 stale。9 项 + IC-1 + 4 RECOMMENDED 已全部修订闭环写入 enemy-system.md（17 处）+ owner 文档 B-1 传播 8 处（stage-map/spatial-grid/registry）。CD 盲区2 登记"跨文档传播检查清单"防第四轮再犯。EnemySystem 保持 In Review；reviewed 仍 7、approved 仍 4。待用户验收/四审。

> 2026-08-25: EnemySystem (#9) full 第四轮 design-review（NEEDS REVISION, scope M / revision-effort S 端）— 第三轮 9 项（B-1..B-9）+ IC-1 + AI-3/4/5/6 经 6 specialist 独立对抗性核实全部本轮闭环写入、无回归；本轮新发现 5 项 BLOCKING 根因 + G 陈旧残留，全为 spec/citation/testability/implementability 修复非重设计（零新公式/零新 ADR/零设计意图变更）：根因1 静态守卫 AC 方法论不可测（qa-lead 实测 gdtoolkit 4.5.0 确认 gdlint 无自定义规则/插件 API，AC-E19(3)/E37/E4-code 引用虚构 gdlint-AST gate；AC-E4-code 正则缺 .emit(/Callable(/String( 等 + 人工 carve-out 非确定性 + 无 positive control）→ 改 `tools/ci/static_guard_check.py` 自定义 CI AST 脚本用 gdtoolkit.parser（实测可导入可解析 Lark Tree）/ 根因2 pair-once 伪代码不可实现（b 是 int 句柄非 carrier 引用，spatial-grid R4 PackedInt64Array handle_ids）→ 声明 handle→carrier 解析（R6 resolve_active_into）+ 拆 ACCUMULATE/COMMIT 两子步消除 clamp 竞态 / 根因3 跨文档 separation query_radius 形式不一致（spatial-grid L133/159/474 用 sep+max_enemy_bound 与 enemy §4.2 sep+max_separation_radius 矛盾，B-1 残留）→ 同步；G3/registry separation 项经核实为正确全局上界（2×max_sep）不改 / 根因4 mini-FSM 载体 timer/counter 悬空（B-4 只加 mini_fsm_state）+ 铁背妖狼 FSM charge_count 蜈蚣模板残留 → 载体补 mini_fsm_phase_timer/mini_fsm_counter + 狼表删 charge_count 单冲锋 / 根因5 血傀儡跨阶段触发机制未声明（FSM MOVEMENT_COMMIT vs take_damage DEFERRED_REMOVAL 不同相）+ 双 latch → mini_fsm_event_flag 字段 + 1-tick 跨相延迟 + §3.12 权威 latch / G §4.1 L478 stale"下帧"残留。2 项 specialist 严重度分歧 CD 裁决：根因1（qa-lead BLOCKING 实测证据 vs gdscript RECOMMENDED）→ BLOCKING（虚假覆盖比无覆盖更糟）；G（ai-programmer BLOCKING vs systems-designer RECOMMENDED）→ RECOMMENDED（规范裁定块在同节上方 10 行低歧义，本轮一并修）。performance-analyst 判 0 BLOCKING（split-freeze 诚实）CD 予以正确限定：性能维度无阻塞但可测性/可实现性/跨文档一致性维度有设计阻塞，范围不同无矛盾。5 根因 + G 已全部修订闭环写入 enemy-system.md（AC-E4-code/E19/E37/E13/E4/E8 + §4.2 伪代码 + §3.4 载体 4 字段 + §3.6/§3.12/§7.4/§4.1 + AC-E30e）+ 跨文档（technical-preferences.md L59 + spatial-grid.md L133/159/474/G3 注）。EnemySystem 保持 In Review；reviewed 仍 7、approved 仍 4。待用户验收/五审。
> 2026-08-25: EnemySystem (#9) full 第四轮 design-review **验收通过 → APPROVED**。用户验收 R4 5 根因 + G 修订：R3 的 9 项（B-1..B-9）+ IC-1 + AI-3/4/5/6 经核实无回归；R4 5 根因（静态守卫 AC 方法论 / pair-once 伪代码可实现性 / 跨文档 query_radius 形式 / mini-FSM 载体字段 / 血傀儡跨阶段触发机制）+ G 陈旧残留全部闭环。R4 最终验证 grep 另补修 3 处残留（AC-E19 引言行 L1136 gdlint / spatial-grid L252+L273 separation_radius+max_enemy_bound，B-1 残留实为 spatial-grid 5 处非 3 处）。零新公式/零新 ADR/零设计意图变更。拆分冻结：行为契约冻结 / 性能 AC（AC-E1/E2b）spike-gated 未冻结。EnemySystem In Review→Approved；reviewed 仍 7、approved 4→5。defer 项（performance-analyst R-PA-1/2/3/6 量级估算警示归 OQ9 spike 前置 / 其余 gdscript/qa-lead RECOMMENDED 归实现期）登记 review-log。

> 2026-08-25: InputSystem (#2 Core, lean) GDD 8 节完成→Designed。单摇杆→二元归一化移动向量（F1：raw=thumb−origin; mag=|raw|; out=(mag<deadzone)?ZERO:raw/mag，幅值∈{0,1}，MVP 不启用 analog 量程）。GameRoot 7-phase 参与者（slot 归属 OQ），BATTLE_ACTIVE 驱动 / BATTLE_PAUSED 冻结 / APP_BACKGROUND 锁定（无挂钟补偿），attack 自动释放（无攻击输入）。零分配稳态管线（禁 emit_signal(带参)/set_deferred/call/get_children，AC-IS25 引 tools/ci/static_guard_check.py AST 守卫，与 EnemySystem AC-E4-code 同型）。27 条 AC（AC-IS1..IS27）覆盖 Core Rules 11 + F1 4 + States 四态 + 跨系统 5 + 静态守卫 3。4 态：IDLE/ACTIVE/FROZEN/BACKGROUND_LOCKED。lean 模式跳过 systems-designer（D/E/F/G 节 sys-designer 未咨询，公式为数学恒等无平衡数值；full 复审终审 spike-skip carrier 持留语义 + pause-resume touch 续接）。10 项 Open Question（VirtualJoystick 4.7.1 API 验证+内置 vs 自定义 ADR / joystick_mode 选择 ADR / input config schema 未冻结 / carrier 归属 / 7-phase slot / deadzone 默认值实测 / 摇杆视觉 UX / analog 预留 / static_guard_check.py 未建）。📌 UX Flag（摇杆 UI + 选择 UI 交互归 ux-designer full 复审）。无新注册表条目（InputSystem 无跨边界数值事实）。Design docs started 7→8、MVP systems designed 7→8/27。待新会话 /design-review。

> 2026-08-26: InputSystem (#2) full 首轮 design-review（NEEDS REVISION, scope L / revision-effort M 端）— 7 specialist（game-designer/systems-designer/qa-lead/performance-analyst/godot×2[gdscript+primary]/ux-designer）+ CD 终审。15 项 BLOCKING 全为 Fantasy 诚实化 + 跨系统契约重定向 + AC 可测性/provisional 标注 + 守卫域 hedge 修复非重设计（零新公式/零新 ADR/2 新 AC AC-IS18b+AC-IS28/不改公开契约主体）。CD 裁定 2 项设计决策（UX-B2 选择 UI=底部弹起面板 / GP-B1 输入获取=内置 VirtualJoystick 轮询 provisional）+ 3 项裁定（GP-B2/B3/B4 context schema/phase slot/carrier 归属降 RECOMMENDED 契约重定向；spike-skip 采纳 gd BLOCKING 但解决方向=Fantasy 诚实化+PC 读侧归属；VirtualJoystick API 验证 defer ADR1 但结构性缺口本轮闭环）。本轮修订已全部闭环写入 input-system.md：Player Fantasy 三承诺诚实化（"按下即起"→"拖动出死区即起"/"松手即归零"拆 InputSystem+PC 两域/"零吞并"→有界例外）+ 4 承诺边界 / Core Rules 3-12（含 R8 无 hover、CR3 provisional 获取机制+origin 前置守卫、CR7 守卫域声明+内置节点 carve-out）/ Edge A4 deadzone `<=0` 守卫 + A2 边界滞回 + B1 press-claim 非 Godot 原生 hedge + C 暂停/后台触摸交接 / F1 origin 前置守卫 + `raw/mag`→`raw.normalized()` + deadzone Range + out Range unit circle∪{ZERO} / Dependencies 跨系统契约重定向 + carrier schema + origin clamp / UI Requirements 底部弹起面板 + 可达区量化 + base ring/thumb/hit alpha / AC 27→29 条（IS18 拆 IS18a/b + IS2/IS23/IS26/IS27 补 positive control + AST + IS23 正则收窄删 MOUSE_MOTION 注释免疫 + IS3/IS21/IS22/IS24 标 PROVISIONAL-待 ADR1 + IS1 断言方式明确 + IS9 `==0`→`<=0` + IS16 删 SpatialGrid 引用 + IS19 carrier==ZERO + IS25 守卫域 hedge+_gui_input 非稳态例外+carve-out + IS26 删 `{[^}]*movement}` 字面量 + 新增 AC-IS28 [V] 无插值层）/ OQ1 scope 扩展 allocation 源码核验。InputSystem Designed→In Review；reviewed 6→7、approved 仍 4。PROVISIONAL AC 待 ADR1。待 re-review（建议新会话 /clear 后）。

> 2026-08-26: InputSystem 第三轮 full re-review（MAJOR REVISION NEEDED, scope L）确认核心数据路径`VirtualJoystick→4 empty-binding actions→get_vector(0)→binary carrier`可保留，当时发现控制面8组BLOCKING。用户裁定D1-A：普通pause保留内置claim至release，APP_BACKGROUND由`VirtualJoystickHost`重建唯一节点并推进gesture epoch；D2-A：摇杆几何使用safe viewport比例、不依赖设备DPI。本轮修订已闭环并同步InputSystem与GameRoot：InputStatus/API表、gesture FSM、空event list+唯一writer、pause→cancel→Grid顺序、resume hook、foreground preflight、F2几何、灰盒Fantasy AC及有限静态守卫/OPEN性能证据。状态保持In Review，待full re-review；review log与session-state本次未改。

> 2026-08-26: InputSystem 第四轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 3路专项（systems+QA / Godot+GDScript+performance / game+UX+UI+gameplay）与creative-director终审确认：第三轮8组BLOCKING仅性能可证性完整关闭，其余7组主体修订成立但实现边界仍开；核心路径与D1-A/D2-A继续保留，无需重选架构。用户批准D3-A..D7-A及仅修改3文件，本轮已修订`input-system.md`与`game-root-scene-flow.md`：D3 GameRoot typed state publish+首press竞态AC；D4 trusted void carrier/private commit helper+status precedence；D5 active VJ几何不可变、离树candidate、旧node不可命中/remove/queue_free、APP_BACKGROUND与safe geometry invalidation全状态矩阵；D6合法ScreenTouch语义、scale-first finite归一化、display→window→Canvas转换与45% region公式；D7 Host只读choice gate及AC-IS28 immutable fixture schema/AC-IS29逐tick事件表。InputSystem保持In Review，待新会话独立full re-review；按用户范围review log与session-state仍未改。

> 2026-08-26: InputSystem 第五轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— Systems/QA、Godot/GDScript/performance、game/UX/UI/gameplay 三路独立复核 + Creative Director终审确认核心数据路径继续保留；D3-A..D6-A部分关闭，D7-A实现契约关闭但UX验收未关。终审去重为7项implementation blocker与4项integration/acceptance gate：resume-abort缺typed rollback、cancel仅按tick幂等、release bool覆盖fresh press、async safe-close与publish failure后置冲突、window physical→viewport stretch逆变换缺失、ScreenTouch AC来源要求不可辨识、callback writer allowlist禁止必要hit-route disable，以及GameRoot foreground drain口径、自动blocking-choice旅程、AC-IS28人体样本协议和缺失下游资产。用户批准修改4文件；已修订`input-system.md`与`game-root-scene-flow.md`，并补齐`systems-index.md`与`reviews/input-system-review-log.md`追踪；状态为Re-review Pending，文档修订不等于独立验收通过。PlayerController/BattleUI/project asset/static guard仍是integration gates，本轮未创建或修改。

> 2026-08-27: InputSystem 第六轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director按安全交付口径裁定第五轮7项为3 CLOSED + 4 PARTIAL，并发现普通pause `mouse_filter=IGNORE`会吞Godot touch-focus release的新实现缺口。用户选择A并批准修改4文件；本轮已同步`input-system.md`与`game-root-scene-flow.md`：普通pause冻结全movement-rect new-press shield且保留claimed VJ release、resume首次Grid/Pool matching publish不可逆边界、async latch一次capture+ack与teardown逃生、`pressed || raw!=0` action clear、完整cancel state×reason矩阵、precision-aware F2 roundtrip容差、AC-IS25旅程/participant/fixture分母及AC-IS27证据协议。`systems-index.md`与review log同步追踪；状态继续Re-review Pending，未经新独立full review不得记Approved。PlayerController/BattleUI/project asset/static guard/真机性能仍为integration/evidence gates。

> 2026-08-27: InputSystem 第七轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— Systems/QA、Godot/GDScript/performance、game/UX/UI/gameplay三路与Creative Director确认第六轮6项为5 CLOSED + 1 PARTIAL；核心路径`VirtualJoystick→4 empty-binding actions→F1→typed carrier`继续保留。终审去重为6项implementation blocker与5项integration gate。用户选择A并批准修改4文件；本轮已同步Host唯一typed/ALWAYS shield owner与`{shield_epoch,touch_index}` held-touch生命周期、teardown首观察async latch时同调用TERMINATED、`ACTION_CLEAR_FAILED`仍强制carrier/pending release安全清理、Host rebuild严格clean precondition、支持平台同index事件有序性manifest/真机trace边界，以及不可逆点前`disable→dirty cancel→verify→abort/close→rollback`。AC-IS25补三选一/二选一全部row与physical-device manifest，AC-IS27补动态VFX/真实手指阈值，AC-IS28冻结timeout公式与owner。状态继续Re-review Pending；若目标Android/iOS违反同index顺序保证，须重开raw-touch identity或自定义摇杆架构。下游资产与真机性能仍为integration/evidence gates。
> 2026-08-27: InputSystem 第八轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director确认第七轮原6项按目标6/6 CLOSED，但发现5组新implementation blocker：resume开始后合法shield press可使ACTIVE publish WRONG_STATE并误升technical fault、system edge gesture/touch cancel缺terminal活性、shield capacity与Paused async latch无必达observer、AC-IS2漏shield ALWAYS且initialize无法内省`accept_event()`、第二次dirty cancel失败后的candidate/lease emergency cleanup歧义。用户选择A并批准修改4文件；本轮已同步不可逆点前fault-free回Paused/点后无lease `RESUME_HELD_DRAIN`、release/cancel与residual navigation gesture inset manifest、按max concurrent touch定容的稀疏bank及`service_pending_input_fault`、effective filter+accept-event行为AC，以及cancel failure的fault-abort/matching-close/teardown顺序。核心路径与binary手感不变；状态继续Re-review Pending，修订不等于通过。PlayerController/BattleUI/project asset、SupportedTouchEventOrderingManifest真机trace、静态守卫、latency/物理热区与min-spec性能继续为integration/evidence gates。
> 2026-08-27: InputSystem 第九轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director按当前实现契约裁定第八轮5项为3 CLOSED + 2 PARTIAL，并去重出5组implementation blocker：async latch pending-first与safe-clear tick无可信来源、shield bank缺pressed/terminal FSM且manifest违例oracle过宽、AC-IS24误要求Godot void callback返回int、GameRoot paused pump exact process mode与AC-IS2 allowlist矛盾、pre-irreversible held rollback后自动resume intent活性未冻结。用户选择A并批准修改4文件；本轮已同步InputSystem内部`safe_close_tick_revision`、完整fixed-slot bank FSM、status-returning API精确allowlist、唯一GameRoot=`PROCESS_MODE_ALWAYS`，以及幂等`resume_requested_latched`在terminal后自动单次重试且不重复choice effect。核心路径与binary/no-hysteresis不变；状态继续Re-review Pending，修订不等于独立复审通过。平台manifest/trace、PlayerController/BattleUI、project asset、UX latency/物理热区、静态守卫与min-spec性能继续为integration/evidence gates。

> 2026-08-27: InputSystem 第十轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director裁定第九轮5项为3 CLOSED + 2 PARTIAL；核心路径与binary/no-hysteresis继续保留。终审去重为4组implementation blocker：无latch `service_pending_input_fault`与trusted tick推进冲突、choice/manual/lifecycle pause reason到resume intent的来源与优先级不完整、唯一GameRoot主动process与项目全局禁令冲突，以及geometry fingerprint仅凭未冻结hash判幂等。用户选择A并批准修改5文件；本轮已冻结无latch service真正no-op、完整pause reason→幂等resume latch矩阵、唯一GameRoot `_physics_process`七phase/`_process`paused pump例外，以及fingerprint命中后完整canonical field bits复核，并同步technical preferences。状态继续Re-review Pending，修订不等于独立复审或运行时通过；平台manifest/trace、PlayerController/BattleUI、project asset、choice terminal ownership、UX/静态守卫/min-spec性能继续为integration/evidence gates。

> 2026-08-27: InputSystem 第十一轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director确认第十轮4项 remediation 全部4/4 CLOSED，核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`继续保留；本轮新增4组implementation blocker：seed前引擎虚回调缺UNARMED隔离、Godot callback ABI/epoch Callable身份未冻结、rebuild精确status与candidate-config canonical identity不完整、APP_BACKGROUND自动恢复缺玩家readiness。用户已预先授权复审后直接修复；本轮同步五文件，冻结UNARMED→seed→exact connect→arm、pressed()/released(Vector2)及无独立canceled signal、完整rebuild status/config identity，以及background需单一Continue而纯geometry可自动。状态继续Re-review Pending；choice terminal ownership、PlayerController/BattleUI、project asset、平台manifest/trace、UX/静态守卫/min-spec性能仍为integration/evidence gates。

> 2026-08-27: InputSystem 第十二轮 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director裁定第十一轮4项为2 CLOSED + 2 PARTIAL；callback ABI与rebuild behavior identity按原目标关闭，UNARMED与APP_BACKGROUND readiness因新边界为PARTIAL。终审去重为2组implementation blocker：callbacks arm后的IDLE→ACTIVE窗口会把加载期早按登记为held并使正常publish误fault，同时preactive background可能被零写吞掉；以及Continue后、ACTIVE前的新background revision会复用旧generic latch绕过新readiness。用户选择A并批准修改五文件；本轮冻结`callbacks_armed/runtime_ingress_armed`分离、PREACTIVE_DISCARD与preactive lifecycle latch，以及per-background required/acked revision gate。状态继续Re-review Pending；核心binary移动路径不变，修订不等于新复审通过。

> 2026-08-27: InputSystem 第十三轮收敛 full re-review（NEEDS REVISION, scope L / revision-effort S）— Systems/QA与Gameplay/UX判定第十二轮2/2 CLOSED；Godot/GDScript/performance沿完整R7执行时序发现同根B1，Creative Director终审采纳并裁定1 CLOSED + 1 PARTIAL：preactive ingress/lifecycle已关闭；per-background readiness的required/acked模型及首次publish前路径已关闭，但不可逆点后的两次publish之间、双publish后、cleanup后、held-drain与ACTIVE尾段缺少attempt revision复核，可能清`foreground_input_blocked`并误开ACTIVE。用户批准修改四文件；本轮固定每个resume attempt的input/background revision与geometry快照，在全部可重入边界统一复核，首次publish后发现invalidation必须用保存tx完成matching publish/cleanup后fault，ACTIVE尾段仅在revision快照、pending fault与held全部干净时开放。AC-D4b/E1/E2与AC-IS11b/12b同步扩充。状态继续Re-review Pending；核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`不变，修订不等于新复审或运行时通过。

> 2026-08-27: InputSystem 第十四轮收敛 full re-review（NEEDS REVISION, scope L / revision-effort M）— Systems/QA与Gameplay/UX判定第十三轮B1已关闭，Godot/GDScript/performance按Godot 4.7.1同步调用链发现最终激活尾段仍可重入：`SceneTree.set_pause(false)`同步传播`NOTIFICATION_UNPAUSED`，`Control.set_mouse_filter()`同步更新mouse-over并可能派发mouse enter/exit notification/signal。Creative Director采纳为同一ACTIVE安全不变量的最后缺口，裁定第十三轮1项为CLOSED后新增1项BLOCKING。用户批准修改四文件；本轮冻结两阶段激活（Input/consumer仍关闭时先unpause并吸收同步通知→复核）及Input activation guard（切shield/VJ hit route时callback仅latch→setter返回后复核→局部提交ACTIVE），`foreground_input_blocked`仅在publish OK后清除；AC-D4b/E1/E2与AC-IS11b/12b/17同步注入。状态继续Re-review Pending；核心binary移动、shield、三系统resume transaction不变，修订不等于新复审或运行时通过。

> 2026-08-27: InputSystem 第十五轮收敛 full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director裁定第十四轮activation blocker为PARTIAL：unpause后的observer已关闭，但`Control.set_mouse_filter()`先写新filter再同步更新mouse-over，Host的runtime bool无法阻止内置VJ原生`_gui_input`/action writer，故第十四轮“guard期间物理route峰值0”不可由原方案成立。终审选择Viewport物理gate：唯一GameRoot checked独占目标battle Viewport并设`gui_disable_input=true`，吸收focus/leave callback后复核，resume再unpause并复核；Input filter guard与Input/GameRoot局部ACTIVE提交均在Viewport disabled下完成，最后以false setter唯一开放。failure保持gate至battle input teardown且PREP/ControlledFault/Home UI接管后恢复；同一协议覆盖`IDLE→ACTIVE`，并静态禁止其他writer与activation callback直接注入InputEvent。用户批准修改五文件；状态继续Re-review Pending，核心binary移动、shield、Grid/Pool resume transaction不变，文档修订不等于独立复审或运行时通过。

> 2026-08-27: InputSystem 第十六轮Viewport activation closure full re-review（NEEDS REVISION, scope L / revision-effort M）— 三路专项与Creative Director裁定第十五轮blocker为PARTIAL：true setter返回后的Viewport物理gate已关闭filter窗口，但Godot默认accumulated input可让gate-held期间事件延迟到false后派发；同时setter内部callback发生在bool置true前，旧AC把该窗口误写成Viewport零投递，并残留ACTIVE publish即route=1及pre-acquire failure保持gate true的矛盾。用户选择A并批准修改五文件；本轮冻结GameRoot在BOOT唯一关闭并readback Input accumulated buffering、在所有项目input target激活前一次性flush历史buffer，`project.godot`冻结agile buffering=false且GameRoot只读验证，并同步`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→reasoned release`矩阵。Input ACTIVE只准备runtime topology，物理route仅在`ACTIVATION_SUCCESS` false返回后0→1；held-only和load/fault cleanup使用独立release reason，pre-acquire failure不写Viewport。状态继续Re-review Pending，修订不等于新full review或运行时通过。

> 2026-08-27: InputSystem 第十七轮Viewport activation closure full re-review（NEEDS REVISION, scope L / revision-effort S）— 三路专项与Creative Director裁定第十六轮两项为1 CLOSED + 1 PARTIAL：Input accumulated/agile buffer越gate的设计契约已关闭；五阶段主时序、route开放点与release reason成立，但`SET_TRUE_IN_FLIGHT` hostile合法ScreenTouch会命中STOP shield并按既有FSM accept/写held bank，旧AC却同时要求accept/bank零写，形成唯一implementation blocker。用户批准修改五文件；本轮采用containment + held drain：loading走PREACTIVE_DISCARD且bank为0，resume写current-epoch held bank并由true返回后的first observer以`HELD_ONLY_RETURN_TO_DRAIN`回drain，VJ/action/carrier/generation/choice/gameplay consumer/top-state仍零写。BOOT flush项目effect口径收窄，不冒充Godot InputMap/cache零修改。状态继续Re-review Pending，修订不等于新full review或运行时通过。

> 2026-08-28: InputSystem 第十八轮聚焦Viewport activation closure full re-review（NEEDS REVISION, scope L / revision-effort S）— 三路专项与Creative Director确认第十七轮ScreenTouch containment blocker已CLOSED，但发现唯一新implementation blocker：旧契约以`runtime_ingress_armed`同时门控ACTIVE gameplay与consumer-closed shield bank service，导致RESUME_LOCKED要求runtime=false时无法合法记录setter-in-flight held touch。用户批准修改五文件；本轮拆分`callbacks_armed`（adapter生命周期）、`runtime_ingress_armed`（仅ACTIVE新VJ press/generation/movement）与`shield_bank_service_enabled`（仅LOCK_PENDING/FROZEN/RESUME_LOCKED bank/FSM），冻结IDLE=`true/false/false`、ACTIVE=`true/true/false`、locked=`true/false/true`、TERMINATED=`false/false/false`及ACTIVE guard原子翻转。状态继续Re-review Pending，尚未经过修订后的独立full review，亦不代表运行时、integration或evidence gate通过。

> 2026-08-28: InputSystem 第十九轮聚焦“三字段 closure”独立full re-review（NEEDS REVISION, scope L / revision-effort S）— Systems/QA、Godot/GDScript/performance、game/UX/UI/accessibility与Creative Director裁定第十八轮三字段职责拆分主体成立但整体closure为PARTIAL；终审把普通cancel、async safe-close、IDLE cleanup与teardown的状态表外瞬态去重为1个callback-observable consumer-close/terminal transaction blocker。用户批准修改五文件；本轮冻结ACTIVE在任何Godot setter/action clear前先由唯一纯标量commit原子发布`LOCK_PENDING + true/false/true`，随后STOP/clear且`ACTION_CLEAR_FAILED`不回滚；IDLE cleanup/async始终`true/false/false`、locked始终`true/false/true`；teardown先提交`TERMINATED + false/false/false`并撤销bank/latch写权，再做route/node cleanup。核心binary移动、Viewport activation、held-drain与Grid/Pool resume transaction不变。状态继续Re-review Pending；本次文档修订不等于新独立复审、实现、运行时或evidence gate通过。

> 2026-08-28: InputSystem 第二十轮聚焦closure确认通过（APPROVED, scope L / confirmation effort XS）— 仅复核第十九轮唯一callback-observable consumer-close/terminal transaction blocker及其两处残留旧顺序。Edge Cases C与AC-IS10现均冻结`前置验证→commit_consumer_closed()原子发布LOCK_PENDING + true/false/true→shield STOP→action/carrier clear`；与Input Core/API/AC、GameRoot及technical preferences一致，旧STOP-first解释已消除，BLOCKING=0。InputSystem GDD标记Approved，Design docs approved 4→5；该批准不代表implementation-ready、integration-ready、运行AC或真机/性能证据通过，既有下游与project asset gates继续OPEN。
> 2026-08-28: GameRoot & Scene Flow (#1 Core) 首轮独立 full design-review（NEEDS REVISION, scope M）— 6 specialist + creative-director 终审。编排模型健全（7-phase 顺序/双缓冲引用交换/事务 rollback/诚实停止 fault 路径自洽，8 节完整），不构成 MAJOR REVISION。17 聚合发现去重为 5 BLOCKING：RNG GATE-G3 集成缺失（违诚实停止）/ TECHNICAL_ABORT 清零与概念 12.1 冲突 / 权威序列碎片化+scope creep（20 轮 churn 根因）/ R3 dirty-patch 隔离 hazard / AC 巨型打包不可测。CD 裁定 3 设计决策（用户已裁决）：TECHNICAL_ABORT 授予部分奖励 / Scoped A 删除 InputSystem 内部 FSM 镜像 / R3 禁 dirty-patch 强制全量 copy。本轮 5/7 修订批次闭环写入 game-root-scene-flow.md：RNG 集成（Dependencies/R2/R4/R5/AC-G2/跨文档块）/ TECHNICAL_ABORT 部分奖励（R9/AC-F1a/F1b/AC-F3）/ R3 全量 copy（R3/AC-G1b）/ F1-F4 变量表+语义 / AC-G1+AC-B1 守卫拆分。pending：Scoped A 删除（~2500词镜像）+ 9 巨型 AC 拆分（强耦合 L 级，待 /clear 新会话 clean context）。CD 裁定 VJ ABI 为继承的 evidence gate（非新设计阻挡项）；held-touch「松手重按」维持正确性机制降 RECOMMENDED。GameRoot Draft→In Review，Design docs reviewed 7→8；approved 仍 5。详见 reviews/game-root-scene-flow-review-log.md。

> 2026-08-28: GameRoot & Scene Flow (#1 Core) 第二轮 full design-review（NEEDS REVISION, scope L 偏 M-L）— 6 specialist + creative-director 终审。严于首轮（非 MAJOR REVISION——编排模型健全，6 方一致确认无需重做）。首轮 5 BLOCKING 中 3 闭环（RNG/TECHNICAL_ABORT/R3 全量 copy/F1-F4/AC-G1+AC-B1 守卫）维持无回归；2 pending（Scoped A+AC 拆分）未执行且第 17-20 轮注入更多 InputSystem 镜像反向加重 Scoped A。本轮 11 BLOCKING：B1 Scoped A 执行（删 ~2500-3500 词内部 FSM 镜像，TD 唯一硬阻塞，新会话 clean context）/ B2 9 巨型 AC 拆分（依赖 B1，新会话）/ B3 resume+per-tick wallclock AC（GD+PERF，首轮 perf BL3 未闭合）/ B4 is_choice_input_blocked() 玩家面反馈 AC（GD 新缺口）/ B5 pause-reason presentation AC（GD 升回）/ B6 R3 零装箱 bulk-copy 机制未命名（PERF 新发现，PackedInt64Array[i]→Variant 装箱，SYS"R3 已闭环"判定过窄）/ B7 三 counter instrument 粒度未定义（PERF）/ B8 set_disable_input API 名→set_gui_disable_input（GODOT，S 端）/ B9 TECHNICAL_ABORT 种子源与概念 12.1 hedge（GD，种子=仅已拾取非按存活时间）/ B10 3 覆盖缺口补 AC（QA）/ B11 AC 确定性去 magic+注入式（QA，与 B2 耦合）。16 RECOMMENDED。CD 驳回 QA 的 AC-K5 断引用 BLOCKING（事实错误，spatial-grid.md line 1007 存在 AC-K5）。sys BL4 quarantine 可标闭合。8 项引擎验证以 GATE-OQ ADR defer 实现期实测。B1+B2 建议新会话 clean context，B3-B11 可本轮或新会话（用户选新会话执行全部 11 项）；全 BLOCKING 闭环后须第三轮 re-review。GameRoot 保持 In Review；reviewed 仍 8、approved 仍 5。详见 reviews/game-root-scene-flow-review-log.md。

---

## Overview

移动端竖屏单手俯视角割草生存 Roguelite，玩家扮演筑基初期韩立在黄枫谷秘境中
单摇杆移动、自动御剑、击杀怪潮、收集灵气升级构筑功法，在两次"避险或夺宝"的
风险抉择中保存实力，最终击败守阵妖兽碧鳞蟒带回灵药。局外通过功法残页永久强化、
掌天瓶催熟灵药携带下局增益，形成"战斗—结算—成长—备战—再开局"闭环。

机械范围以"300 普通敌人 + 400 投射物 + 300 掉落物同屏、中端 Android 50FPS+"为
硬性能约束，因此对象池、空间网格、屏幕外降频是 Foundation 级刚需，而非可选优化。
MVP 只验证三件事：①移动躲避+自动御剑+功法进化的爽快度；②避险或夺宝的风险决策
是否体现韩立谨慎气质；③掌天瓶催熟→下局增益的局外循环是否简单明确。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | GameRoot & Scene Flow | Core | MVP | In Review | design/gdd/game-root-scene-flow.md | SpatialGrid public contract（被编排基础设施；无 gameplay system 前置）。第二轮 full design-review（2026-08-28, NEEDS REVISION, scope L 偏 M-L）：严于首轮（非 MAJOR REVISION——编排模型健全，6 specialist 一致确认无需重做）。首轮 5 BLOCKING 中 3 闭环维持无回归（RNG GATE-G3 集成/TECHNICAL_ABORT 部分奖励/R3 全量 copy/F1-F4/AC-G1+AC-B1 守卫）；2 pending（Scoped A 删 ~2500-3500 词 InputSystem 内部 FSM 镜像 + 9 巨型 AC 拆分）未执行且第 17-20 轮注入更多镜像反向加重。本轮 11 BLOCKING：B1 Scoped A 执行（TD 唯一硬阻塞）/ B2 9 巨型 AC 拆分（依赖 B1）/ B3 resume+per-tick wallclock AC（GD+PERF 升回）/ B4 is_choice_input_blocked 玩家面反馈 AC（GD 新缺口）/ B5 pause-reason presentation AC（GD 升回）/ B6 R3 零装箱 bulk-copy 机制未命名（PERF 新发现，GDScript PackedInt64Array[i]→Variant 装箱）/ B7 三 counter instrument 粒度未定义（PERF）/ B8 set_disable_input→set_gui_disable_input（GODOT）/ B9 TECHNICAL_ABORT 种子源 hedge（GD）/ B10 3 覆盖缺口 AC（QA）/ B11 AC 确定性去 magic+注入式（QA，与 B2 耦合）。CD 驳回 QA AC-K5 断引用（事实错误）。sys BL4 quarantine 闭合。8 引擎验证 GATE-OQ ADR defer。B1+B2 建议新会话 clean context；用户选新会话执行全部 11 项；闭环后须第三轮 re-review。详见 reviews/game-root-scene-flow-review-log.md |
| 2 | InputSystem | Core | MVP | Approved | design/gdd/input-system.md | GameRoot（唯一ALWAYS编排节点及typed delta callbacks、BOOT中Input accumulated=false唯一runtime setter+target前一次flush、ProjectSettings agile=false只读验证、目标battle Viewport gate唯一writer、UNARMED/IDLE/ACTIVE/locked/TERMINATED的`callbacks_armed/runtime_ingress_armed/shield_bank_service_enabled`固定tuple、PREACTIVE_DISCARD/lifecycle abort、ACTIVE先纯标量原子发布LOCK_PENDING完整tuple再STOP/clear的callback-observable consumer-close、terminal-first teardown、paused fault service、choice/manual/geometry/background resume矩阵、per-background required/acked readiness、attempt-captured revision全边界复核、`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT(ScreenTouch shield containment)→GATE_HELD→Input/GameRoot局部ACTIVE→reasoned release`的loading/resume物理gate、first-observer held-drain、resume不可逆点+held drain）；Godot 4.7.1 VirtualJoystick pressed()/released(Vector2)+exact epoch-bound Callable、Input buffering与Viewport gate；immutable candidate-config与geometry双canonical identity、精确rebuild status；Project InputMap/Settings、supported touch-order/cancel/max-touch/gesture-inset manifest；BattleUI choice terminal/resume gate、全row可达性与PlayerController fantasy fixture为integration gates；Config schema仅未来可选迁移 |
| 3 | SpatialGrid | Core | MVP | Approved | design/gdd/spatial-grid.md | —（无代码依赖）；Runtime prerequisites: GameRoot phase、Stage/Spawn arena、Object Pooling lifecycle、Config limits/bounds |
| 4 | Object Pooling (inferred) | Core | MVP | Approved | design/gdd/object-pooling.md | Config per-key capacities；Runtime coordination: GameRoot/SpatialGrid lifecycle |
| 5 | Config/Data System | Core | MVP | Draft | design/gdd/config-data-system.md | Godot Resource/build import；Runtime consumers: GameRoot/Object Pooling/SpatialGrid/owners |
| 6 | Stage & Map | Core | MVP | Approved | design/gdd/stage-map.md | Config snapshot（校验与域）；GameRoot BATTLE_LOADING 注入 |
| 7 | RNG System | Core | MVP | Approved | design/gdd/rng-system.md | —（无代码依赖）；Runtime: Config run_seed 数据依赖、GameRoot battle-scope ownership；下游 SpawnDirector/SkillDraft/Zhangtian + 隐式（Damage/Drop/雷爆符/法宝匣/RiskChoice） |
| 8 | PlayerController | Gameplay | MVP | Not Started | — | InputSystem, SpatialGrid, Object Pooling, Config |
| 9 | EnemySystem | Gameplay | MVP | Approved | — | SpatialGrid, Object Pooling, Config |
| 10 | SpawnDirector | Gameplay | MVP | Not Started | — | EnemySystem, Config, RNG |
| 11 | DamageSystem | Gameplay | MVP | Not Started | — | SpatialGrid, Config |
| 12 | BuffSystem | Gameplay | MVP | Not Started | — | DamageSystem |
| 13 | ProjectileSystem | Gameplay | MVP | Not Started | — | Object Pooling, SpatialGrid, DamageSystem |
| 14 | WeaponSystem | Gameplay | MVP | Not Started | — | ProjectileSystem, BuffSystem, Config |
| 15 | SkillDraftSystem | Gameplay | MVP | Not Started | — | WeaponSystem, Config, RNG |
| 16 | DropSystem | Economy | MVP | Not Started | — | EnemySystem, Object Pooling, SpatialGrid, Config |
| 17 | RiskChoiceSystem | Gameplay | MVP | Not Started | — | SpawnDirector, EnemySystem, PlayerController |
| 18 | BossStateMachine | Gameplay | MVP | Not Started | — | EnemySystem, DamageSystem, SpawnDirector |
| 19 | Elite Enemies | Gameplay | MVP | Not Started | — | EnemySystem, DropSystem, Config |
| 20 | Leveling/XP (inferred) | Progression | MVP | Not Started | — | DropSystem, PlayerController, SkillDraftSystem |
| 21 | Progression Tree (功法树) | Progression | MVP | Not Started | — | SaveSystem, Config |
| 22 | Zhangtian Bottle (掌天瓶) | Progression | MVP | Not Started | — | SaveSystem, Config, RNG |
| 23 | SaveSystem | Persistence | MVP | Not Started | — | Config |
| 24 | BattleUI | UI | MVP | Not Started | — | PlayerController, SkillDraftSystem, RiskChoiceSystem, GameRoot |
| 25 | SettlementSystem | UI | MVP | Not Started | — | DamageSystem, EnemySystem, Leveling, SaveSystem |
| 26 | Home UI (洞府首页) | UI | MVP | Not Started | — | Progression Tree, Zhangtian Bottle, GameRoot |
| 27 | Prep UI (掌天瓶准备页) | UI | MVP | Not Started | — | Zhangtian Bottle, GameRoot |
| 28 | Audio Feedback | Audio | MVP | Not Started | — | DamageSystem, WeaponSystem, GameRoot |
| 29 | VFX System (inferred) | UI | Vertical Slice | Not Started | — | WeaponSystem, DamageSystem, Object Pooling |
| 30 | Tutorial | Meta | Vertical Slice | Not Started | — | BattleUI, SkillDraftSystem, RiskChoiceSystem, GameRoot |
| 31 | Perf & LOD (inferred) | Meta | Vertical Slice | Not Started | — | EnemySystem, SpawnDirector, VFX |
| 32 | Analytics | Meta | Alpha | Not Started | — | SettlementSystem, SkillDraftSystem, RiskChoiceSystem |

**显式 vs 隐式标注**：名称带 "(inferred)" 的系统是设计文档未单列但游戏必需的隐藏系统（#4 对象池、#19 升级经验、#28 特效、#30 性能降级）。其余 27 个源自设计方案第 15.2 节模块清单或各章节明述。

---

## Categories

本项目用到的功能域分类（未用到的 Narrative 类已移除——方案第 20 节排除剧情对话树）：

| Category | Description | Project Systems |
|----------|-------------|-----------------|
| **Core** | 全局基础与框架 | GameRoot & Scene Flow, InputSystem, SpatialGrid, Object Pooling, Config/Data, Stage & Map, RNG |
| **Gameplay** | 让游戏好玩的核心机制 | PlayerController, EnemySystem, SpawnDirector, DamageSystem, BuffSystem, ProjectileSystem, WeaponSystem, SkillDraftSystem, RiskChoiceSystem, BossStateMachine, Elite Enemies |
| **Progression** | 玩家长期成长 | Leveling/XP, Progression Tree, Zhangtian Bottle |
| **Economy** | 资源产出与消耗 | DropSystem |
| **Persistence** | 存档与连续性 | SaveSystem |
| **UI** | 玩家面向信息显示 | BattleUI, SettlementSystem, Home UI, Prep UI, VFX System |
| **Audio** | 声音系统 | Audio Feedback |
| **Meta** | 核心循环外的元系统 | Tutorial, Perf & LOD, Analytics |

---

## Priority Tiers

| Tier | Definition | Target | Count |
|------|------------|--------|-------|
| **MVP** | 核心循环运转必需，缺则无法测"是否好玩" | 阶段一+二+三（局内循环+局外循环） | 27 |
| **Vertical Slice** | 一个完整打磨区域的体验 | 阶段四（表现与测试） | 3 |
| **Alpha** | 全功能粗版 | MVP 验证后 | 1 |
| **Full Vision** | 打磨、边缘情况、内容完整 | — | 0 |

---

## Dependency Map

按依赖序分层。设计/构建从上到下；同层独立系统可并行。

### Foundation Layer（无 gameplay 代码依赖）

本层可分别做 isolated design/spike；“无 gameplay 代码依赖”不等于 integration-ready 无前置。Config已冻结foundation limits；SpatialGrid/Object Pooling的battle-ready仍须Stage arena、owner query/reset/spawn上限与GameRoot编排闭环。

1. **GameRoot & Scene Flow** — 全局根与场景状态机；无 gameplay system 前置，按 SpatialGrid 已冻结 public contract编排 phase/pause/resume
2. **InputSystem** — 使用4.7.1内置VirtualJoystick；运行时依赖唯一ALWAYS GameRoot的typed state publish/phase/lifecycle及目标battle Viewport input gate唯一所有权。BOOT先关闭Input accumulated、只读验证ProjectSettings agile=false并在项目input target激活前一次性flush；UNARMED→trusted tick seed→exact epoch-bound Callable connect→callbacks arm但runtime ingress与shield bank service均closed。三字段严格分工：callbacks=adapter生命周期、runtime=仅ACTIVE gameplay ingress、shield service=仅consumer-closed bank/FSM；loading/resume ACTIVE均按`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT(ScreenTouch由shield containment)→GATE_HELD→Input/GameRoot局部ACTIVE→reasoned release`开放，Host bool不得替代物理gate。loading containment在service=false下走PREACTIVE_DISCARD，resume containment在runtime=false/service=true下写held bank并由first observer回drain，VJ/gameplay effect为0；ACTIVE guard原子翻转为runtime=true/service=false。PREACTIVE_DISCARD/lifecycle abort、paused fault service、不可逆resume+held-drain及choice/manual/geometry/background矩阵继续有效。纯foreground geometry可自动恢复；APP_BACKGROUND以latest required/acked revision要求玩家readiness/Continue，新revision会使旧确认失效且该press不兼作movement。rebuild使用immutable candidate-config与geometry完整canonical identity并返回精确status。可isolated code spike，但manifest真机trace通过前不具备implementation-ready；PlayerController/BattleUI GDD、choice touch terminal gate、全row/物理设备UX证据与project logical canvas/InputMap/scene Viewport route资产完成前不具备integration-ready状态
3. **SpatialGrid** — 纯空间查询数据结构，无 gameplay 代码依赖；isolated spike 可独立进行，但 integration-ready 前必须注入 GameRoot phase capability、Stage/Spawn arena+margin、Object Pooling lifecycle 与 Config per-type limits/bounds
4. **Object Pooling** — typed预分配池，无 gameplay 代码前置；按GameRoot/SpatialGrid public contract同步binding、Paused quarantine与teardown，六key capacity由Config snapshot注入
5. **Config/Data System** — Resource(.tres)→immutable battle snapshot；无 gameplay 代码前置，foundation schema/limits已冻结，Stage/owner数据仍待补齐
6. **Stage & Map** — 单图固定竞技场几何与 `StageSpatialConfig`；无 gameplay 代码依赖，静态几何/schema 已冻结，生产 `cell_size`/`index_margin` 收紧值 gated（遵 SpatialGrid F3/J0）
7. **RNG System** — 种子与随机序列，无依赖

### Core Layer（依赖 Foundation）

1. **PlayerController** — 依赖 InputSystem, SpatialGrid, Object Pooling, Config
2. **EnemySystem** — 依赖 SpatialGrid, Object Pooling, Config
3. **SpawnDirector** — 依赖 EnemySystem, Config, RNG
4. **DamageSystem** — 依赖 SpatialGrid, Config
5. **BuffSystem** — 依赖 DamageSystem
6. **ProjectileSystem** — 依赖 Object Pooling, SpatialGrid, DamageSystem
7. **WeaponSystem** — 依赖 ProjectileSystem, BuffSystem, Config
8. **SkillDraftSystem** — 依赖 WeaponSystem, Config, RNG

### Feature Layer（依赖 Core）

1. **DropSystem** — 依赖 EnemySystem, Object Pooling, SpatialGrid, Config
2. **RiskChoiceSystem** — 依赖 SpawnDirector, EnemySystem, PlayerController
3. **BossStateMachine** — 依赖 EnemySystem, DamageSystem, SpawnDirector
4. **Elite Enemies** — 依赖 EnemySystem, DropSystem, Config
5. **Leveling/XP** — 依赖 DropSystem, PlayerController, SkillDraftSystem
6. **Progression Tree** — 依赖 SaveSystem, Config
7. **Zhangtian Bottle** — 依赖 SaveSystem, Config, RNG
8. **SaveSystem** — 依赖 Config（注：存档"框架"可视为 Foundation，但"要存什么的数据契约"依赖 Progression/Zhangtian/Leveling 先定义，故按内容契约归 Feature 层）

### Presentation Layer（依赖 Feature/Core）

1. **BattleUI** — 依赖 PlayerController, SkillDraftSystem, RiskChoiceSystem, GameRoot
2. **SettlementSystem** — 依赖 DamageSystem, EnemySystem, Leveling, SaveSystem
3. **Home UI** — 依赖 Progression Tree, Zhangtian Bottle, GameRoot
4. **Prep UI** — 依赖 Zhangtian Bottle, GameRoot
5. **Audio Feedback** — 依赖 DamageSystem, WeaponSystem, GameRoot
6. **VFX System** — 依赖 WeaponSystem, DamageSystem, Object Pooling

### Polish Layer（依赖一切）

1. **Tutorial** — 依赖 BattleUI, SkillDraftSystem, RiskChoiceSystem, GameRoot
2. **Perf & LOD** — 依赖 EnemySystem, SpawnDirector, VFX
3. **Analytics** — 依赖 SettlementSystem, SkillDraftSystem, RiskChoiceSystem

---

## Recommended Design Order

依赖序 × 优先级。MVP Foundation → MVP Core → MVP Feature → MVP Presentation → MVP 局外 → VS → Alpha。

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | SpatialGrid | MVP | Foundation | systems-designer + technical-director | M |
| 2 | Object Pooling | MVP | Foundation | technical-director + gameplay-programmer | M |
| 3 | Config/Data System | MVP | Foundation | game-designer + systems-designer | M |
| 4 | RNG System | MVP | Foundation | systems-designer | S |
| 5 | GameRoot & Scene Flow | MVP | Foundation | technical-director | M |
| 6 | Stage & Map | MVP | Foundation | game-designer + systems-designer | S |
| 7 | InputSystem | MVP | Foundation | ux-designer + gameplay-programmer | S |
| 8 | PlayerController | MVP | Core | gameplay-programmer + systems-designer | M |
| 9 | EnemySystem | MVP | Core | ai-programmer + systems-designer | L |
| 10 | SpawnDirector | MVP | Core | systems-designer | M |
| 11 | DamageSystem | MVP | Core | systems-designer | M |
| 12 | BuffSystem | MVP | Core | systems-designer | M |
| 13 | ProjectileSystem | MVP | Core | gameplay-programmer | M |
| 14 | WeaponSystem | MVP | Core | systems-designer + gameplay-programmer | L |
| 15 | SkillDraftSystem | MVP | Core | systems-designer + economy-designer | L |
| 16 | DropSystem | MVP | Feature | economy-designer | M |
| 17 | Leveling/XP | MVP | Feature | systems-designer | M |
| 18 | RiskChoiceSystem | MVP | Feature | game-designer + systems-designer | M |
| 19 | Elite Enemies | MVP | Feature | ai-programmer + systems-designer | M |
| 20 | BossStateMachine | MVP | Feature | ai-programmer + systems-designer | L |
| 21 | BattleUI | MVP | Presentation | ui-programmer + ux-designer | L |
| 22 | Audio Feedback | MVP | Presentation | audio-director + sound-designer | M |
| 23 | SaveSystem | MVP | Feature | gameplay-programmer | M |
| 24 | Progression Tree | MVP | Feature | systems-designer + economy-designer | M |
| 25 | Zhangtian Bottle | MVP | Feature | systems-designer | M |
| 26 | SettlementSystem | MVP | Presentation | ui-programmer + systems-designer | M |
| 27 | Home UI | MVP | Presentation | ui-programmer + ux-designer | S |
| 28 | Prep UI | MVP | Presentation | ui-programmer + ux-designer | S |
| 29 | VFX System | Vertical Slice | Presentation | technical-artist + godot-shader-specialist | L |
| 30 | Tutorial | Vertical Slice | Polish | ux-designer + game-designer | M |
| 31 | Perf & LOD | Vertical Slice | Polish | performance-analyst + technical-director | L |
| 32 | Analytics | Alpha | Polish | analytics-engineer | M |

**估算说明**：S = 1 会话，M = 2-3 会话，L = 4+ 会话（一个会话 = 一次聚焦设计对话产出一个完整 GDD）。

---

## Circular Dependencies

- **无环依赖。**

已核查的"疑似环"实际为单向：
- GameRoot → SpatialGrid public API、SpatialGrid runtime prerequisite → GameRoot phase：前者是调用方向，后者是运行时注入要求；SpatialGrid 不导入或回调 GameRoot，因此不存在代码依赖环。
- lifecycle owner → SpatialGrid/Object Pooling public API，GameRoot只编排调用顺序；Object Pooling不调用SpatialGrid、两者都不回调GameRoot，因此binding/quarantine事务不形成代码依赖环。
- Leveling ↔ SaveSystem、Progression ↔ SaveSystem：SaveSystem 提供读写框架，Leveling/Progression 调用它，不反向依赖（SaveSystem 不需要知道经验值/功法树的内部逻辑，只序列化传入的数据）。

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **SpatialGrid** | Technical | 300 实体同屏范围查询的命根子；选错数据结构（如每帧遍历全场）直接卡死中端机 | 阶段一灰盒最先做，用 300 占位敌人压测，定下网格 cell 大小与查询半径契约 |
| **Object Pooling** | Technical | 8 个系统依赖；池设计（预分配量、归还策略、泛型 vs 类型池）影响全局 | 阶段一与 SpatialGrid 同步建，先定池接口契约再写业务系统 |
| **Config/Data System** | Technical | 14 个系统依赖 Resource 结构；配置 schema 一旦定型，后期改字段牵连广 | schema v1先冻结Pool/Spatial foundation切片与snapshot/version规则；其余Stage/owner类别按readiness gate逐类补齐，不一次性伪冻结全部9类 |
| **DamageSystem** | Design + Technical | 伤害公式 + 伤害数字合并 + 结算占比展示；公式乘区设计影响平衡可解释性（方案 14.1 强调"不引入大量独立乘区"） | 公式先单元测试（BLOCKING 证据），伤害占比展示在结算前用占位数据验证可读性 |
| **BossStateMachine** | Design | 碧鳞蟒两阶段 + 毒雾压缩安全区 + 预警可读性；阶段切换与毒雾缩圈时序易出错 | 阶段三单独验证，两阶段用有限状态机先纸面走查状态转换图 |
| **EnemySystem** | Technical | 6 种普通敌人 + 精英 + Boss 共用还是分立架构；Godot 默认节点架构（CharacterBody2D+Area2D+动画）在 300 实体下吃力 | 需架构 ADR 定"轻量节点 + 手动更新"vs 物理驱动碰撞——这是 Godot 4 下高实体同屏的关键技术决策 |
| **SkillDraftSystem** | Design | 升级三选一候选池 + 保底 + 进化条件；权重与保底逻辑易出"永远最优解"（方案 21 节风险之一） | 候选池生成逻辑先数据驱动可配置，用埋点/试玩验证"两种机缘选择均有玩家使用" |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 32 |
| Design docs started | 8 |
| Design docs reviewed | 8 |
| Design docs approved | 5 |
| MVP systems designed | 8/27 |
| Vertical Slice systems designed | 0/3 |

---

## Next Steps

- [ ] 审阅并批准本系统枚举（已完成枚举/依赖/优先级三轮评审）
- [ ] 先设计 MVP-tier 系统，用 `/design-system [system-name]`（按 Recommended Design Order）
- [ ] 每完成一个 GDD 后跑 `/design-review design/gdd/[system].md`（建议在新会话）
- [ ] MVP 系统 GDD 全部完成后跑 `/gate-check pre-production`
- [ ] 用 `/vertical-slice` 在承诺 Production 前验证最高风险系统（SpatialGrid / Object Pooling / EnemySystem 架构）
