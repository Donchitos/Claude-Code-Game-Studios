# Object Pooling — Design Review Log

审查历史。每次 `/design-review` 后追加一条，供未来 re-review 追踪修订闭环。

---

## Review — 2026-08-20 — Verdict: NEEDS REVISION

**Scope signal**: M（revision scope M）
**Review depth**: full
**Specialists**: performance-analyst, game-designer, godot-specialist, qa-lead, systems-designer + creative-director（终审）
**Blocking items**: 7（按 7 主题聚合） | **Recommended**: 18 | **Nice-to-have**: 5
**Prior verdict resolved**: First review（仓库此前无 object-pooling review-log）

**Summary**: 5 位 specialist 对抗性审查未动摇核心机制（primitive borrow_id / slot generation / 定容 / quarantine / resume 三阶段事务经核验在 Godot 4.7.1 可成立）。7 项 BLOCKING 全部是**形式化缺口、测试架构缺口、与 SpatialGrid 防御不对称**——正是 full review 应挖出的真问题，且全部局部可修、不触及公开契约、不阻断下游并行。creative-director 终审 NEEDS REVISION，下游 GDD（Enemy/Projectile/Drop/SpawnDirector）可基于当前公开契约立即并行启动。

### 7 项 BLOCKING（主题聚合）

1. **[A·godot] slot schema 缺 node_ref，instance_id ABA** — L33 只存 `object_instance_id`，ObjectDB 回收后对活对象 N2 执行 reset_for_pool。与 spatial-grid.md R6 对同一威胁防御不对称。
2. **[B·perf+game+systems] 容量/余量协调三方交叉** — F1 输入值未在本 GDD echo（systems）；`max_concurrent_borrowed` 被等同 Grid cap 303，borrowed 范围含 quarantined+release_pending，pause 期间"Pool POOL_EXHAUSTED 但 Grid admission 通过"（game）；pause_overlap=0 与 R6 旧+新并存语义冲突，spare 被隐式挪用（systems）。
3. **[C·godot+perf] R3 零分配是断言非契约** — 4.7 四分配源（set_deferred/create_tween/AnimationPlayer play cache/Array.clear）。AC-F3 positive control 未定义（对比 SpatialGrid AC-B7）。
4. **[D·perf+game+qa] damage_number=96 AoE 峰值 fault 风险** — R1 PRESENTATION 默认 fault，怪潮峰值触发 ControlledGameplayFault，违反 Player Fantasy。EC14 无 AC。
5. **[E·godot] R7 publish 前 no node_ref 复检** — arm→publish 窗口外 queue_free 致脏发布。
6. **[F·systems+qa] F3 release_allowed 单布尔未形式化 status precedence + R2 6 层 precedence 无 AC** — F3 推不出 quarantine > STILL_REGISTERED。
7. **[G·qa] 完全缺两张覆盖矩阵 + EC1/EC11/EC14/EC15 无 AC + AC-F3 positive control 未定义** — 对照 SpatialGrid L1012-1082。

### 用户裁定（design decisions）

- PRESENTATION 默认：drop + telemetry, never fault（返回 OVERFLOW_DROPPED，降级细节归 owner GDD）
- pause_overlap：保留 0，Object Pooling 补证明义务（上界证明归 owner GDD + fixed-seed churn；Config 侧选型可并行）
- 本会话一次性修订 7 项

### Recommended（18 项，非阻塞，实现期/ADR 收口）

- F1 303 下界/上界口径统一；F2 "slot 恰一状态"声明为公理；F2 effective_capacity 击穿 fault 触发 API 边界对齐
- F3 borrow_valid 含 RELEASE_PENDING 动机说明；BORROWED_BOUND handle 清零归属
- F4 "pause drain"显式枚举 PAUSE_PENDING/PausedFrozen/PausedPrepared/Armed；teardown 排除与 R3 reset hook 不分配弱不一致澄清
- capacity per-key split authority 标注 owner 背书缺失
- R5 fault-path BOUND→RETIRED binding 处理；R7 prepare workspace 与 published table 别名安全声明；R2 generation/borrow_id 推进原子性
- R3 AVAILABLE 节点树内归属+process_mode；R2 Poolable contract 版本化+@abstract 强制；R3 warmup 1189 Node 帧预算+资源共享；R4 teardown queue_free 顺序；R5 checked increment 与 SpatialGrid 共享 primitive
- AC-E3 不可达 failure 注入方法明确；debug/release artifact 分离；AC-C5 跨文档依赖（SpatialGrid 侧补 sync failure 专属 AC）；AC-F3 100 次 pause 含完整成功路径（已在本轮修订补）；AC-F4 safety_spare 边界
- game R2 capacity 已冻结但 overlap 无具体值（被主题 B 覆盖）；game R3 pause 期间持续怪潮 spawn vs 事件触发 spawn 区分（SpawnDirector pause 行为）
- perf 4 条（加载时间预算/恢复重置突发预算/近耗尽遥测/波次突发 churn）+ 2 Nice-to-have

### Nice-to-have（5 项）

- AC-F4 "立即"时序量化；AC-E1 old/new 同窗口 invariant 显式；dev assert/release bifurcation 显式声明
- slot generation "即将耗尽"判定时机；F3 BORROWED_BOUND 释放前 handle 清零路径形式化

---

## 修订闭环 — 2026-08-20

7 项 BLOCKING 已全部写入 `object-pooling.md`。逐项核对证据（行号为修订后文档）：

- **A slot schema + node_ref**：R2 slot schema 增加 `node_ref`；新增 ABA 窗口说明 + ObjectDB 回收声明 + Node identity 双校验机制（`is_instance_valid && get_instance_id==saved && !is_queued_for_deletion`）；F3 `borrow_valid` 改用 Node identity 双校验；generation/borrow_id 推进原子性补注。不改 public carrier。
- **B F1 source echo + borrowed scope + pause_overlap 语义**：R1 末尾 echo config R4 全表（6 key × 4 输入项 → Σ=1189，标 source）；F1 补 borrowed scope 定义（含 quarantined+release_pending）+ Pool capacity 协调公式（`Grid cap + max(quarantine+pause_new_spawn+overlap) + safety_spare`）+ pause_overlap=0 时 spare 吸收证明义务 + boss 独占插槽不变量 + 303 同时是冻结值与下界锚点。
- **C R3 零分配可验证契约 + AC-F3 positive control**：R3 L58-59 钉 5 条 Godot 4.7 约束（reset phase 在 physics flush 之外 / 禁 set_deferred / create_tween 移出预算 / warmup 预建 track cache / PackedArray.clear）；R9 instrumentation 加 F4 四项 counter；AC-F3 补 positive control 定义（A/B 对照 delta>0 否则 harness 不合格，与 SpatialGrid AC-B7/J3 共享工具）+ ABA 100,000 per-cycle counter + churn 含完整成功路径。
- **D R1 PRESENTATION drop + EC14 + AC-F5**：R1 PRESENTATION 溢出返回 `OVERFLOW_DROPPED`（success）+ telemetry + never fault；PoolStatus enum 加 `OVERFLOW_DROPPED`；EC14 改 drop；新增 AC-F5（AoE 峰值 overflow drop，GAMEPLAY pool 同条件仍 fault）。
- **E R7 publish 复检**：R7 step 4 publish 前复检 `is_instance_valid(node_ref) && !is_queued_for_deletion()`，失败保持 ARMED 进 fault。
- **F F3 分段判定 + precedence + AC-B4**：F3 `release_allowed` 扩展为分段 `release_status` 判定 + 显式 precedence `quarantine > handle > state` + BORROWED_BOUND handle 清零归属；新增 AC-B4（status precedence 表驱动，重点 quarantined AND BOUND → QUARANTINED wins）。
- **G 两张覆盖矩阵 + 4 AC + positive control**：新增 EC→AC 矩阵（16/16）+ 规则/公式→AC 映射表；补 EC1→AC-A4、EC11→AC-E4、EC14→AC-F5、EC15→AC-D3 四个缺失 AC。

**结论**：7 项全部闭环。修订不改公开契约（pool_key/borrow_id/generation/slot carrier/reset hook 签名/状态机不变；PoolStatus 仅 additive 新增 OVERFLOW_DROPPED）。重审结果见下条目。

---

## 重审 — 2026-08-20 — Verdict: NEEDS REVISION

**Scope signal**: M
**Review depth**: full（re-review，沿用首轮同一 5 specialist + creative-director 组合做 apples-to-apples 复核）
**Specialists**: performance-analyst, game-designer, godot-specialist, qa-lead, systems-designer + creative-director（终审）
**Blocking items**: 3（均为首轮修订引入的新缺陷）| **Recommended/defer**: ~20
**Prior verdict resolved**: No（重审判 NEEDS REVISION，需三审）

**Summary**: 首轮 7 BLOCKING 修订中，B-fix 新增的 F1 协调公式与 F-fix 新增的 F3 release_status 分段各自引入新形式化缺陷，4/5 specialist（systems/godot/perf/qa）判 NEEDS REVISION，creative-director 独立读 GDD F1/F3 原文复核两处矛盾均 CONFIRMED。game-designer 独判其角度（Player Fantasy/feel）闭环，creative-director 裁定其自限范围不足以覆盖公式/伪代码层 BLOCKING。核心机制（primitive borrow_id/slot generation/定容/quarantine/resume 三阶段事务）5 专家一致确认在 Godot 4.7.1 稳固，不需 MAJOR REVISION（无重设计/无新 ADR/无公开契约变更）。Pillar"无复用幽灵/稳定"直接受威胁（#2 僵尸 slot 可携 freed node、#1 pause 期 POOL_EXHAUSTED 或 boss 无法生成），属 pillar 级。

### 3 项 BLOCKING（修订引入，已二次修订写入）

1. **[systems+perf+CD] F1 L161 协调公式算术失效**：`Pool capacity = Grid_cap + max(quarantine + pause_new_spawn + spawn_before_release) + safety_spare`——Grid_cap（per-type cap=active+pending）已含 PausedFrozen 期间 frozen 的 quarantine BOUND 实体，再加 quarantine 项 = double-counting（enemy_normal pause 峰值公式=620 vs configured 320）；非 Grid 键 projectile/damage_number Grid_cap=0 丢 max_concurrent（48≠448、32≠96）；boss Q=1 → 2>1 与 R1 L38 boss 不变量冲突、spare=0 无法吸收，L165 证明义务不可满足。
2. **[systems+godot+qa+CD] F3 L179 borrow_valid 死分支**：borrow_valid AND 链含 is_instance_valid(node_ref) → node 失效时 borrow_valid=false → step 1 STALE_BORROW → step 2 OBJECT_INVALID 永不可达，抵触 R2 L44/EC3 L215/AC-B3 L311/AC-B4 L317；按字面实现 release 路径 node 失效不 retire、不 fault（STALE_BORROW 不在 R9 L147 故障列表），slot 停僵尸态，削弱 A 主题 ABA 防御。A-fix 与 F-fix 互相抵消。
3. **[qa+CD] F3 L185 precedence 文本与伪代码矛盾**：文本 `quarantine > handle > state` 但伪代码 step 4（RELEASE_PENDING=state）先于 step 5（BOUND=handle），实际 `quarantine > state > handle`。

### 二次修订闭环（已写入 object-pooling.md）

- **#1 F1**：删除 L161 协调公式；L159 scope 改为"quarantined 已计入 max_concurrent_borrowed、非额外项，禁 Grid_cap+quarantine 重述，权威公式回归 L155 required_capacity"。
- **#2 F3**：拆 borrow_valid = borrow_identity_valid（epoch+state+borrow_id）AND node_alive（node_ref 三校验）；伪代码 step 1 `!borrow_identity_valid → STALE_BORROW`、step 2 `!node_alive → OBJECT_INVALID`（退休+fault）；补"OBJECT_INVALID 触发 slot 退休 + GAMEPLAY fault（与 R2/EC3/AC-B3/AC-B4 一致）"。
- **#3 F3**：precedence 文本改 `quarantine > state > handle` 对齐伪代码 + 补措辞解释。

修订不改公开契约（pool_key/borrow_id/generation/slot carrier/reset hook 签名/状态机不变）。

### defer 项（不本轮修，归实现期/ADR/owner GDD）

- **C 主题 R3 零分配补全**（perf+godot）：call_deferred 未禁、signal connect/disconnect、运行时 StringName 构造、Dictionary resize/clear、4.7 Animation.length float→double、packed-array setter 语义；"4.7 下须钉"措辞多为通用 Godot 行为。
- **AC-F3 positive control 强化到 AC-J3 严格度**（perf+qa）：双独立 control + 量化阈值 + manifest + 显式拒绝恒零 monitor。
- **F4 counter 双层粒度**（perf）：自定义=0 且平台 allocation_events_delta=0。
- **perf 6 项**：teardown 峰值内存/时长 AC、1189 Node warmup 帧预算、近耗尽遥测、pause drain 突发帧预算、spawn_before_release 告警、telemetry 来源分类。
- **godot 5 项**：R2 API 枚举漏 arm/abort_resume/begin_quarantine、R3 reparent 无运行时防御、R8 parent.queue_free 窄窗口、R2 未搬运 R6 WeakRef 论证、L47 carrier instance_from_id ABA。
- **qa S3 剩余**：AC-D3 "POOL_EXHAUSTED/WRONG_STATE" 析取非确定、AC-F3 三个 ABA counter 未在 R9 instrumentation。
- **game ADVISORY（defer owner GDD）**：DamageSystem 直接 Node 引用 mutation 需补 borrow_id 校验义务、PRESENTATION criticality 跨域审查机制、L157 "303/400/300 是 Config 冻结值"表述歧义；NICE-TO-HAVE：damage_number=96 game-feel 论证、AC-F5 "gameplay 不中断"冗余、telemetry 来源分类。

**待三审**：/clear 后跑 `/design-review design/gdd/object-pooling.md --depth full` 验证 3 项二次修订闭环。三审过则标 Approved 并同步 systems-index（approved 2→3）。

---

## 三审 — 2026-08-20 — Verdict: NEEDS REVISION → 修订闭环 → Approved

**Scope signal**: M（修订工作量）；系统整体 L
**Review depth**: full（5 specialist + creative-director 终审，沿用同组合 apples-to-apples）
**Specialists**: game-designer, systems-designer, performance-analyst, godot-specialist, qa-lead + creative-director（终审）
**Blocking items**: 7（本轮）| **Recommended/defer**: ~15
**Prior verdict resolved**: Yes（二审 3 BLOCKING 经 systems 逐公式代入确认闭环；本轮 7 BLOCKING 均为新发现/回归，已全部修订）

**Summary**: 3 项二次修订（F1 公式回归、F3 双校验拆分、F3 precedence 文本）经 systems-designer 逐公式代入边界值确认闭环（required=configured 四 key 全等、OBJECT_INVALID 可达且退休+fault 链与 R2/EC3/AC-B3/AC-B4 一致）。本轮 7 BLOCKING 全为局部可修、不改公开契约核心、不需新 ADR，故 NEEDS REVISION 非 MAJOR。核心机制（primitive borrow_id/slot generation/定容/quarantine/resume 三阶段事务）5 专家一致确认 Godot 4.7.1 稳固。game-designer 本轮正确扩展到设计意图（enemy_elite 容量 vs MVP 8.1 冒险夺宝持久化），creative-director 确认其扩展得当。creative-director 终审 NEEDS REVISION，user 一次性修订全部 7 项 + 2 advisory 后标 Approved。

### 7 项 BLOCKING（已修订写入）

1. **[systems+qa 交叉确认] AC-B4 L317 precedence 与 F3 矛盾** —— 二审改 F3 precedence 文本却未同步 AC-B4（incomplete-fix 回归），两份文本给互斥 oracle。已改 `quarantine>state>handle` + 组合枚举由笛卡尔积改为每分支≥1 代表输入+3 边界 case。
2. **[qa] AC-D3 析取非确定 + 执行机制缺口** —— R4"Pool 不识别 phase"与 R8/EC15"不新 borrow"之间无执行机制。user 裁决 A（GameRoot phase-gate）：Pool 不加状态，AC-D3 改 trace gate 证明；R8 L140 补"拦截归 GameRoot"。
3. **[qa] AC-F3 ABA counter 未在 R9 声明** —— 断言 `stale_rejected==same_slot_reuse_count==borrow_id_monotonic_increase==100,000` 但 R9 无此 counter。已补 3 个全局 ABA counter 声明。
4. **[godot] B1 borrow carrier 缺 node_ref，契约不可实现** —— owner 无安全 API 取 Node，被迫 instance_from_id（R2 禁止的 ABA 入口）。已 R2 carrier 补 node_ref 字段（additive）+ R4 step2 显式来源。
5. **[game] F-1 enemy_elite capacity=4 与冒险夺宝持久化冲突** —— MVP 5.3 两固定精英 + 8.1 持久化精英最坏 4 并发吃满 capacity=4。user 裁决 A（提至 6：safety_spare 1→3、Σ=6、1189→1191），同步 config-data-system.md 10 处。
6. **[perf C1+godot] R3 零分配契约漏 4 项真实分配源** —— 漏 call_deferred/signal connect-disconnect/运行时 StringName/Dictionary。creative-director 裁定 C1 BLOCKING（契约完整性），C2/C3 降 RECOMMENDED。已 R3 L68 补 4 项禁止。
7. **[perf N1] R3 L68(c) Tween 措辞矛盾** —— "warmup 预建 Tween 复用"与"kill 后不可 restart"矛盾。已改 AnimationPlayer 优先 + Tween stop 而非 kill-restart。

### specialist 分歧裁定（creative-director）

- **C 主题零分配契约严重度**（最大争议）：perf 判 C1/C2/C3 全 BLOCKING vs godot 判全 RECOMMENDED。CD 拆分裁定：C1（漏 4 源）=BLOCKING 本轮修；C2（positive control 弱于 AC-J3）=RECOMMENDED（已 delta>0 可证伪，对齐是 polish）；C3（F4 无平台 profiler）=RECOMMENDED（实现期复用 spatial-grid 共享 harness）。双方各对一半。
- **game-designer F-1 范围**：CD 确认本轮正确扩展到设计意图，但因 capacity 归 Config 需 user 裁决。

### 顺带 advisory（2 项，本轮写入）

- R3 L70 禁 `free()`（同帧 ABA 真正来源，queue_free 帧末释放）。
- R2 L44 三校验短路求值顺序（is_instance_valid 在前）+ "双校验"→"三校验"。
- AC-A1 加"通过≠memory gate 通过"；AC-B4 组合枚举显式化。

### defer 项（归实现期/owner GDD/lean follow-up）

- C2/C3：AC-F3 positive control 对齐 AC-J3 量化形式 / F4 counter 平台 profiler 交叉验证（共享 harness，实现期解决）。
- systems #2：F1 safety_spare 双重职责（churn+pause）/"净增"定义。
- systems #3/#4：F3 脏残留 handle diagnostic。
- godot R1：ABA 威胁模型同帧/跨帧措辞拆分。
- godot R11：Area2D monitoring toggle 成本 vs set_deferred 禁令→collision mask 替代（defer owner GDD）。
- perf F3a：AC-F3 pause 路径 N/M/K 配比冻结。
- perf P2：OVERFLOW_DROPPED telemetry 限频策略。
- qa #7：carrier 6 层 precedence 非 release API postcondition AC。
- qa #8：AC-E1 三系统 integration joint vs sliced。
- W1：1191 Node warmup 内存/帧预算 spike（min-spec 真机 gate OPEN）。

**结论**：7 BLOCKING 全部闭环。公开契约仅 carrier 扩 1 字段（node_ref，additive），PoolStatus/状态机/核心机制不变。标 Approved，同步 systems-index（object-pooling In Review→Approved、approved 2→3）。creative-director 建议剩余均为局部收尾，无需再起 5-specialist full 复审。
