# Systems Index: 凡人修仙传·掌天试炼（MVP）

> **Status**: Draft
> **Created**: 2026-08-14
> **Last Updated**: 2026-08-25
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
| 1 | GameRoot & Scene Flow | Core | MVP | Draft | design/gdd/game-root-scene-flow.md | SpatialGrid public contract（被编排基础设施；无 gameplay system 前置） |
| 2 | InputSystem | Core | MVP | Not Started | — | — |
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
2. **InputSystem** — 触点输入，无依赖（4.7 内置 VirtualJoystick 节点可直接用）
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
| Design docs started | 7 |
| Design docs reviewed | 6 |
| Design docs approved | 4 |
| MVP systems designed | 7/27 |
| Vertical Slice systems designed | 0/3 |

---

## Next Steps

- [ ] 审阅并批准本系统枚举（已完成枚举/依赖/优先级三轮评审）
- [ ] 先设计 MVP-tier 系统，用 `/design-system [system-name]`（按 Recommended Design Order）
- [ ] 每完成一个 GDD 后跑 `/design-review design/gdd/[system].md`（建议在新会话）
- [ ] MVP 系统 GDD 全部完成后跑 `/gate-check pre-production`
- [ ] 用 `/vertical-slice` 在承诺 Production 前验证最高风险系统（SpatialGrid / Object Pooling / EnemySystem 架构）
