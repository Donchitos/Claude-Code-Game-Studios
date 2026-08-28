# RNG System — Design Review Log

审查历史。每次 `/design-review` 后追加一条，供未来 re-review 追踪修订闭环。

---

## Review — 2026-08-24 — Verdict: NEEDS REVISION

**Scope signal**: L（revision scope L）
**Review depth**: full
**Specialists**: 跨文档核验员(Explore)、game-designer、godot-specialist、performance-analyst、systems-designer、qa-lead + creative-director（终审）
**Blocking items**: 10（A 级，全修订闭环）| **Recommended**: B/C 级一并补
**Prior verdict resolved**: First review（仓库此前无 rng-system review-log）

**Summary**: full review 揭示 RNG 的确定性 pillar 部分建立在未验证 Godot 假设上（引擎参考零 RNG 覆盖，`randi_range`/`randf_range` 跨架构行为未核验）；存在系统性跨文档 AC 错引（把 game-root 的可复现诊断 AC-G2 与零增长 AC-G1 误作 spatial-grid AC-G1/G2，把 spatial-grid AC-B7/J3 分配工具误作 AC-G1）；`roll_shuffle_in_place` 因 Godot 4 `Array`/`Packed*` COW 语义使 Fisher-Yates 原地写触发 `_copy_on_write()` 堆分配、违反 R4 零分配，AC-D3 不可满足；F4 浮点域（PackedFloat32Array）有四缺陷（Σw 上溢 +inf 使 `C_j > u` 空集→result OOB / 继承 randf_range FMA 跨架构漂移 / W(float64) 与 C_j(float32) 精度不一致→OOB / 无整数域逃生路径）；AC-E2 per-consumer 归属校验运行时不可实现（API 无 caller 身份参数）；R8 零值窗口未约束消费方（fault 返回的 index 0 与合法高权重结果不可区分）；telemetry schema 缺失且 R3「调用序列」与 R7 telemetry 矛盾（per-roll trace 违反 R4）。creative-director 终审 NEEDS REVISION，但裁定全部为 spec/citation 修复非重设计——设计意图（确定性+流隔离+无 OS 熵+零分配+fail-fast）自洽，一轮修订即可闭合。

### 10 项 BLOCKING（A 级）

1. **[BL-1·qa+跨文档] 跨文档 AC 错引** — 概述/R4/R7/EC7/跨文档块/AC-B1/AC-F3 等 5+ 处把 game-root AC-G1（稳态零增长）/AC-G2（可复现诊断）误引为 spatial-grid AC-G1/G2；spatial-grid AC-G1 实为"每帧反映活动实体当前位置"正确性 AC、AC-G2 实为"完整 physics phase 顺序"事件追踪，均非零增长/可复现诊断。分配工具 spatial-grid AC-B7/J3 被误引为 AC-G1。qa-lead + Explore 独立确认。
2. **[BL-2·godot+perf] roll_shuffle_in_place COW 违 R4** — Godot 4 `Array`/`Packed*` refcount≥2 时写触发 `_copy_on_write()` 堆分配；Fisher-Yates 原地洗牌无法满足 R4 零分配，使 AC-D3 不可满足。
3. **[BL-3·systems] F3/F4 缺 finite 检查 + F4 浮点 +inf OOB** — F3 `randf_range` 未检 isfinite（NaN 比较恒 false 静默产出）；F4 PackedFloat32Array 累积 Σw 上溢 +inf 使 `C_j > u` 空集→result OOB；W(float64) 与 C_j(float32) 精度不一致→OOB。
4. **[BL-4·qa] AC-E2 per-consumer 归属不可实现** — 当前 API 无 caller 身份参数，运行时无法检测 SpawnDirector 误调 CRIT 流；AC-E2 原写"per-consumer 归属校验"不可实现。
5. **[BL-5·systems+game] R8 零值窗口未约束** — fault 返回零值（weighted_pick→index 0）与合法高权重结果（如 weights=[100,1,1] 正常也返回 0）不可区分，仅 fault latch 区分；消费方若未检 has_fault() 即用返回值作 gameplay 决策，零值静默进入 committed state。
6. **[BL-6·godot+qa] AC-A4/A5 不对称 + 漂移源错指** — AC-A4（整数域）未标 ARM 真机 gate，AC-A5（浮点）标了，不对称；A5 漂移源错指 randf() 本身，实际是 randf_range() 的 FMA 收缩（`min+randf()*(max-min)` 可能收缩为 fma ±1 ULP，依赖 `-ffp-contract`）。
7. **[BL-7·systems] F1 derive 缺纯整数约束** — F1 契约未约束 derive 为纯整数运算；若用浮点中间值，stream_seed 跨架构漂移使 AC-A4 整数域保证崩塌。
8. **[BL-8·game] fantasy 混淆玩家面与 dev 面** — "凭种子复现"是 dev/QA 工作流能力，玩家不持 seed 不复现 bug，但原 fantasy 混在一起，下游可能误读为"须向玩家暴露 seed"；缺"故障后玩家无损属 game-root R9"的 caveat。
9. **[BL-9·systems] F2 拒绝采样 vs 委托 Godot 矛盾** — F2 原写"拒绝采样避免 modulo bias"与"对齐 Godot"矛盾；缺 INT_MIN/MAX 全域 range 溢出 edge。
10. **[BL-10·qa+perf] R3 vs R7 telemetry 矛盾 + schema 缺失** — R3 原写"调用序列"暗示 per-roll trace，但 per-roll trace 违反 R4 零分配；R7 telemetry schema 未定义；AC-A1 未区分 unit/integration；AC-F3 引用错（spatial-grid AC-G2）。

### 用户裁定（design decisions）

- **F4 权重数组类型**：迁移到 PackedInt32Array 定点整数权重（消四缺陷 + 解除对 AC-A5 依赖），scale factor K 归 ADR（OQ2）
- **roll_shuffle_in_place**：从 R5 删除（同 roll_gaussian 先例），AC-D3 移除；待下游消费方出现时由 ADR 定义零分配洗牌方案
- **AC-E2**：降级为全局 enum 集校验（与 EC11 同路径），per-consumer 归属改静态分析/lint；R9 收窄「未知 stream_id→fault」
- 本会话一次性修订 10 项 + B/C 级补全

### Recommended（B/C 级，本轮一并补）

- B4 AC-D1/D2 补 chi-square 均匀性（非仅 oracle match）+ AC-D 标 BLOCKING-on-OQ6
- B5 新增 AC-H1（state 往返 set/get + 不破坏确定性）
- C1 game-root R9 scope 延伸注（R9 字面覆盖 pre-run reservation + fault 路径，mid-battle state gate 语义延伸待 SaveSystem）
- C2 object-pooling R3 scope 延伸注（R3 字面是 slot reset，RNG 推广到 roll 路径）
- C3 AC-G1/G2 改名 GATE-G1/G2（区分 testable AC 与 integration/consistency gate）
- C6 fantasy caveat（含于 BL-8）
- M1 INT 溢出 edge / M2 min==max 降级 / M4 负权重 fault / M6 精度（F4 迁 int 消解）/ M7 单射语义 / M9 max_weights per-stream
- P3 AC-B1 whole-tick scope / P5 303+burst fixture / P13 dispatch 禁 Dict[String]
- godot rng-math.md（OQ3）/ state 往返 AC（AC-H1）

---

## 修订闭环 — 2026-08-24

10 项 BLOCKING 已全部写入 `rng-system.md`。逐项核对证据（节标题为修订后文档）：

- **BL-1 跨文档错引更正**：概述/R4/R7/EC7/跨文档块/AC-B1/AC-F3 全部更正为 game-root AC-G1/G2 + spatial-grid AC-B7/J3，并注 spatial-grid AC-G1/G2 实际语义以区分；跨文档块新增"原误引已更正"注。
- **BL-2 shuffle 删除**：R5 删除 `roll_shuffle_in_place`，注 COW 违 R4 + 待消费方/ADR；AC-D3 划除并注。
- **BL-3 finite + F4 迁 int**：F3 加 `!isfinite(min)||!isfinite(max)` fault；F4 迁 PackedInt32Array 定点整数域（int 无 inf/NaN），消 +inf OOB + FMA + 精度 + 无 int 逃生四缺陷。
- **BL-4 AC-E2 降级**：AC-E2 重写为全局 enum 集校验（与 EC11 同路径），per-consumer→静态分析/lint；R9 收窄。
- **BL-5 R8 零值守卫**：R8 补「消费方用返回值前须 has_fault()（或 GameRoot wrap）」；AC-E1 改「不进入下一 phase committed state」+ phase abort 丢弃。
- **BL-6 AC-A4/A5 对称化**：AC-A4/A5 都 OPEN-until-min-spec 真机 + rng-math.md + spike；R3 漂移源更正 = randf_range FMA 收缩（非 randf）；weighted_pick 已 int 不受 A5。
- **BL-7 F1 derive 纯整数**：F1 契约加「纯整数运算（无浮点中间值）」；OQ1 保留 ADR。
- **BL-8 fantasy 拆面**：拆「玩家面」vs「dev 面」+ caveat（玩家无损属 game-root R9）。
- **BL-9 F2 委托澄净**：明确「委托 gen.randi_range（Godot 无偏）；oracle=Godot 快照；AC-A4 spike 失败回退自研拒绝采样」；补 M1 INT 溢出 edge。
- **BL-10 telemetry schema**：R3 改「每流调用计数（int counter，零分配原地 ++）」；R7 补 telemetry schema（run_seed + stream_id + 调用计数 + first-failure state）；AC-F3 改 game-root AC-G2 引用 + schema 定义；AC-A1 拆 unit/integration 消 R3/R7 矛盾。

### 3 OPEN 保持 deferred（合理推迟，非 blocker）

- OQ1 derive 算法 → `/architecture-decision` ADR
- OQ2 max_weights per-stream 值表 → 下游 Drop/SkillDraft GDD
- OQ4 run_seed 来源 → game-designer（PREP UI GDD 前）

（另 OQ3 rng-math.md / OQ5 stream_id 集是否终态 / OQ6 oracle 捕获流程 为 full review 新增 OPEN，各归 owner。）

**下一轮复审焦点**：验证 10 项修订真正闭环、无新引入矛盾（尤其 F4 迁 int 后 F2/F4/AC-D1 联动、telemetry schema 与 AC-A1 边界、AC-G1/G2→GATE- 改名后引用完整性）。建议在新会话 `/design-review design/gdd/rng-system.md`（独立上下文）。

---

## Review — 2026-08-24 (re-review) — Verdict: NEEDS REVISION

**Scope signal**: L（revision effort M 端 — 外科手术式 spec/citation/enforcement 修复）
**Review depth**: full
**Specialists**: systems-designer、qa-lead、game-designer、godot-specialist、performance-analyst、跨文档核验员(Explore) + creative-director（终审）
**Blocking items**: 4（A 级，本轮新发现，均为 spec/citation/enforcement 修复非重设计）| **Recommended**: 18 | **Nice-to-have**: ~14
**Prior verdict resolved**: 上一轮 10 项 blocker 全部修订闭环（跨文档逐条核实，无回归）；本轮新开 4 项

**Summary**: 复审确认上一轮 10 项 A 级 blocker 全部闭环、跨文档引用更正（game-root AC-G1/G2 + spatial-grid AC-B7/J3 + object-pooling AC-F3/R3）经对端文档核实存在且语义匹配、无残留 spatial-grid AC-G1/G2 误引、GATE-G2 未过时。但本轮新发现 4 项 BLOCKING，全为执行层 spec/citation/enforcement 缺口，零新公式/零新 ADR（BL-B bound 走 OQ3 既有 OPEN）、1 新 AC（BL-C state-diff）、1 新 GATE（BL-D GATE-G3）。creative-director 终审 NEEDS REVISION，设计意图（确定性+流隔离+无 OS 熵+零分配+fail-fast）自洽，修订优先级 BL-D→BL-A→BL-C→BL-B（可并行）。1 处 specialist 分歧：BL-C 严重度（qa-lead BLOCKING vs game-designer #5 RECOMMENDED），creative-director 裁决 qa-lead 成立（invariant 已声明非未规格 + 保护确定性 pillar，对齐 spatial-grid 终审"确定性逐项不变量始终 BLOCKING"）。

### 4 项 BLOCKING（A 级）

1. **[BL-A·perf+qa+CD] 零分配 PackedInt32Array 盲区** — F4 迁 PackedInt32Array 使其成 weighted_pick 核心类型，但 R4(line 62)禁止列表与 AC-B1(line 294) positive control 均未明示 PackedInt32Array（Godot `Array`≠`PackedInt32Array`）；`range()` 在 GDScript 返回 PackedInt32Array 是 roll 路径最易踩隐式分配；positive control 未描述构造类型、未分别断言多类型，违 spatial-grid AC-J3 终审原则。Fix: R4 加 Packed*Array；AC-B1 positive control 明示覆盖 Object/Array/PackedInt32Array(含 range() 路径)分别 delta 断言；跨文档块 line 226 显式引 AC-J3 基线。
2. **[BL-B·sys+CD] F4 fault 缺 Σw 上界** — int32 权重 + int64 累积使 W 可远超 INT32_MAX 不溢出、不触发任一现行 fault（`Σw≤0` 只捕获溢到负）；W-1>2^32-1 时 `randi_range` 输出域[,2^32-1]不足致 modulo bias 悄然发生，分布偏离 P(i)=w_i/W 契约，系统不 fault；line 174"一举消除四缺陷"过头。Fix: F4 fault 加 W 上界；Tuning 加 `W_MAX_SAFE`(deferred OQ3)；line 174 更正；OQ3 覆盖大域行为。
3. **[BL-C·qa+CD] fault 路径 gen-state invariant 声明但未约束、未测试** — R7(line 89)声明"所有 fault 路径在 draw 前 latch"，但 R8(line 96)未显式约束 gen state 不推进，全文档无 AC 测试。实现 bug 使 gen state 推进→telemetry 记错 state→game-root AC-G2 复现诊断崩塌且无测试捕获。Fix: R8 补"在任何 gen draw 前 latch，gen state 不推进"；新增 state-diff AC（fault 前后 `get_stream_state` 恒等）；AC-F3(line 359)改可验证陈述指向新 AC。
4. **[BL-D·game+CD] 跨文档单向依赖：has_fault 检查义务悬空** — R8(line 96-97)断言"GameRoot 在 phase 边界检查 has_fault()"，但 game-root GDD 零匹配（grep 确认）；RNG 是 service（无独立 phase 检查机会），检查责任落在调用方。消费方忘守卫+返 success→game-root 放行→零值 commit→fault 被掩盖，违玩家面"故障诚实暴露、不被掩盖"承诺；AC-E1/F3 两既有 AC 可测性亦依赖此义务却未 gate。Fix: 新增 GATE-G3（BLOCKED until game-root 声明 has_fault() 边界检查义务 + 标 RNG 为 fault source）；R8"或由 GameRoot wrap"→强制默认；bidirectional flag(line 230)加 game-root 义务条目；AC-E1/F3 标 BLOCKING on GATE-G3。

### 3 OPEN 保持 deferred（合理推迟，非本轮 blocker）

OQ1 derive 算法→ADR；OQ2 max_weights→下游 GDD；OQ3 rng-math.md Godot 核验（godot-specialist 6 项 RECOMMENDED 均归此，断言强度超证据强度但已 gate）；OQ4 run_seed 来源；OQ6 oracle 捕获。

**下一轮复审焦点**：验证 4 项修订真正闭环、无新引入矛盾（尤其 BL-D GATE-G3 是否已在 game-root 侧响应、BL-A positive control 多类型断言是否与 spatial-grid AC-J3 对齐、BL-C state-diff AC 是否覆盖所有 fault 路径、BL-B W_MAX_SAFE bound 是否在 OQ3 给出）。建议在新会话 `/design-review design/gdd/rng-system.md`（独立上下文，本会话已用较多 context）。

---

## 修订闭环 — 2026-08-24 (re-review)

复审 4 项 BLOCKING 已全部修订写入 `design/gdd/rng-system.md`：

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-A** | R4(line 62) 禁止列表加 `Packed*Array`（含 `range()`→PackedInt32Array）+ `while i<count` 原位迭代；AC-B1(line 294) positive control 明示分别断言 Object/Array/PackedInt32Array(含 range 路径)/Dictionary/StringName 各类 A/B delta>0；跨文档块(line 226) 显式采 AC-J3 多类型分别断言标准 + 增 PackedInt32Array 一路 | 对齐 spatial-grid AC-J3 |
| **BL-B** | F4 fault(line 173) 加 `W-1>2^32-1→R8 fault`；F4 变量表 Σw 行加 `0<W≤W_MAX_SAFE` 上界；line 174 更正"消解四缺陷"+ 补第五风险(int32/int64 上界 modulo bias)+ bound 归 OQ3；Tuning 加 `weighted_pick_W_MAX_SAFE`(deferred OQ3)；line 176 specialist 注记更新；清冗余 finding code | 保守默认 W-1≤2^32-1，精确 bound 待 OQ3/rng-math.md |
| **BL-C** | R8(line 96) latch 句补"在任何 gen draw 前，gen state 不推进"invariant；新增 **AC-E1b** fault 路径 gen-state 不变量 state-diff test（BLOCKING）；AC-F3(line 359) capture 句指向 AC-E1b | 1 新 AC |
| **BL-D** | R8(line 97) "或由 GameRoot wrap"→强制默认；bidirectional flag(line 230) 加 game-root phase 边界 has_fault 检查义务条目 + 消费方二级防御条目；新增 **GATE-G3**(BLOCKED until game-root 声明 has_fault 义务 + 标 fault source)；AC-E1 Then + AC-F3 Gate 标 `on GATE-G3 解阻` | 1 新 GATE |

**复核确认**：4 项均为 spec/citation/enforcement 修复，零新公式/零新 ADR（BL-B bound 走既有 OQ3 OPEN）。文档头部 Status/Last Updated/Review Mode/Creative Director Verdict/Specialist 注记均已同步反映复审。creative-director 修订优先级 BL-D→BL-A→BL-C→BL-B（4 项无相互依赖，已全部写入）。

**仍 OPEN（合理推迟）**：OQ1 derive 算法 ADR / OQ2 max_weights 下游 / OQ3 rng-math.md（含 W_MAX_SAFE 精确 bound）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新。

**下一轮复审焦点**：见上文 re-review 末"下一轮复审焦点"——重点验 GATE-G3 是否已在 game-root 侧响应、BL-A positive control 与 AC-J3 对齐、BL-C state-diff AC 覆盖全 fault 路径、BL-B W_MAX_SAFE bound 在 OQ3 给出。建议新会话 `/design-review design/gdd/rng-system.md`（本会话 context 已较满）。

---

## Review — 2026-08-24 (re-review 2, 三审) — Verdict: NEEDS REVISION

**Scope signal**: L（revision effort M 端 — 外科手术式 spec/citation/enforcement 修复）
**Review depth**: full
**Specialists**: systems-designer、qa-lead、game-designer、godot-specialist、performance-analyst、跨文档核验员(Explore) + creative-director（终审）
**Blocking items**: 4（A 级，本轮新发现，均为 spec/citation/enforcement 修复非重设计）| **Recommended**: —
**Prior verdict resolved**: 上一轮复审 4 项 BLOCKING（BL-A/B/C/D）全部修订闭环（跨文档逐条核实，无回归）；本轮新开 4 项

**Summary**: 三审确认上一轮 BL-A/B/C/D 全部闭环、跨文档引用与 GATE-G2/GATE-G3 状态无回归；但本轮新发现 4 项 BLOCKING（BL-E/F/G/H），均为复审→三审间迁移后规范漂移与引用/执行缺口，零新公式/零新 ADR/零新 GATE（BL-E bound 走既有 OQ3 OPEN、BL-F 漂移源降级 defer rng-math.md）。creative-director 终审 NEEDS REVISION，设计意图（确定性+流隔离+无 OS 熵+零分配+fail-fast）自洽。3 处 specialist 严重度分歧由 creative-director 裁决：BL-E（godot BLOCKING vs systems RECOMMENDED——"名为保守的守卫值实际不保守"+weighted_pick 核心路径静默 modulo bias+零成本修复，godot 成立）；BL-G（cross-doc BLOCKING vs perf RECOMMENDED——"须取 AC-J3 上限"反转严格性+对冻结 AC 事实性误述是 fail-fast 硬门控，cross-doc 成立）；BL-F（godot BLOCKING 但范围限定为消歧义+降级待核验，非"GDScript 层确定无 FMA"）。

### 4 项 BLOCKING（A 级）

1. **[BL-E·godot+CD] W_MAX_SAFE 边界名为保守实不保守** — 复审 BL-B 修复将保守默认设为 `W-1 ≤ 2^32-1`，但 Godot `randi_range(int, int)` 两参数为 32-bit **有符号**整型（int32，最大 INT32_MAX=2^31-1），非 uint32 2^32-1。W-1>2^31-1 时 GDScript int64→int32 截断为负→`randi_range` 内部 SWAP→输出域错乱+modulo bias 悄然发生，名为保守的守卫值未守住。Fix: 保守默认收紧为 `W-1 ≤ 2^31-1=INT32_MAX`；`2^32-1` 仅作 relaxation 路径（须 F2 回退自研拒绝采样基于 `gen.randi()` uint32，归 OQ3）；F4 scratch buffer `int`→`PackedInt64Array`（与 int64 累积器同类型，C_j 不溢出，refcount=1 零 COW）。
2. **[BL-F·godot+CD] FMA 漂移源未核验却作既定结论** — 复审 BL-6/R3 漂移源更正为"`randf_range` 的 FMA 收缩"作为已验证定位，但 F3 实现路径为 GDScript 层表达式 `min + gen.randf() * (max - min)`（编译为多 opcode MULTIPLY→ADD），与 Godot 引擎方法 `RandomNumberGenerator.randf_range()`（单 C++ 表达式，受 `-ffp-contract` 影响）的 FMA 行为不同；两路径是否收缩均未核验，不应作既定结论。Fix: 两路径均降级为待核验假设，defer 至 rng-math.md(OQ3) 核验 GDScript VM opcode 收缩与引擎方法 `-ffp-contract` 行为后再冻结漂移源；weighted_pick 已整数域不受影响。
3. **[BL-G·cross-doc+CD] AC-J3 引用反转严格性 + 对冻结 AC 事实性误述** — 复审 BL-A 修复写"RNG AC-B1 采用 spatial-grid AC-J3 多类型分别断言标准…须取 AC-J3 上限"，但 AC-J3 实际仅 2 个 positive control（A=`range(out.count)` 即 PackedInt32Array 路径、B="1 Object+1 Array" Object/Array 捆绑，不含 Dictionary/StringName）；"须取 AC-J3 上限"反转了严格性方向（RNG 应自定更严，非取较松上限），且对已冻结 AC 事实性误述是 fail-fast 硬门控。Fix: 改写为"参考并加强 AC-J3 思路"，RNG AC-B1 扩展为 5 类各自独立 A/B（Object/Array/PackedInt32Array 含 `range()`/Dictionary/StringName），删"须取 AC-J3 上限"。
4. **[BL-H·sys+qa+CD] R8 `!isfinite(W)` 对 int W 为死路径** — 复审 BL-C 修复在 R8 故障条件写"非有限浮点 `!isfinite(min)||!isfinite(max)||!isfinite(W)`"，但 weighted_pick 的 W 为 int64 累积权重和，无 IEEE inf/NaN，`!isfinite(W)` 是永假死路径，掩盖真实故障条件（int 截断）。Fix: `!isfinite` 仅限 `roll_float_range`（min/max 为 float）；int_range 的 min/max 与 weighted_pick 的 W 均为 int 无 inf/NaN，移除死路径。

### OPEN 保持 deferred

OQ1 derive 算法→ADR；OQ2 max_weights→下游 GDD；OQ3 rng-math.md Godot 核验（含 W_MAX_SAFE 精确 bound + FMA 两路径漂移核验）；OQ4 run_seed 来源；OQ5 stream_id 终态；OQ6 oracle 捕获。跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新。

**下一轮复审焦点**：验证 BL-E/F/G/H 修订真正闭环、无新引入矛盾（尤其 BL-E `2^31-1` 边界在 F4 变量表/fault/为何整数域/Tuning/AC-E1b 五处一致、BL-F 两路径"待核验"在 R3/F3/AC-A5 三处一致、BL-G AC-J3 引用在跨文档块/AC-B1 两处一致、BL-H `!isfinite` 仅限 float_range 在 R8/AC-E1b 一致）。建议新会话 `/design-review design/gdd/rng-system.md`（独立上下文，本会话 context 已满）。

---

## 修订闭环 — 2026-08-24 (re-review 2, 三审)

三审 4 项 BLOCKING 已全部修订写入 `design/gdd/rng-system.md`：

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-E** | L167 变量表 Σw 行：保守默认 `W-1 ≤ 2^31-1=INT32_MAX`（匹配 `randi_range(int,int)` int32 参数域）；L173 fault：`W-1>2^31-1` 超界→int64→int32 截断为负→SWAP→输出域错乱+modulo bias；L174 为何整数域：同步 `2^31-1` + 明确 int64 累积不溢但 int32 参数截断；L243/L244 Tuning K 与 W_MAX_SAFE 同步；L339 AC-E1b Given 同步；L171 scratch buffer `int`→`PackedInt64Array`（int64 元素与累积器同类型，refcount=1 零 COW）。`2^32-1` 仅作 relaxation 路径归 OQ3 | grep 确认 `2^32-1` 仅残留于"放宽至/更松上界"语境（4 处） |
| **BL-F** | L57 R3：F3=GDScript 层表达式 vs 引擎方法 `randf_range` FMA 行为不同，两路径均降级待核验 defer rng-math.md(OQ3)；L157 F3 跨架构风险：同步降级 + weighted_pick 整数域不受影响；L174 历史论据"继承 randf_range FMA 漂移"标注待核验；L288 AC-A5：漂移源待核验，两路径 defer rng-math.md | grep 确认无"FMA 收缩"既定断言残留 |
| **BL-G** | L226 跨文档块：改写为"参考并加强 AC-J3 思路"（AC-J3 实际仅 2 阳性对照 A=range/B=Object+Array 捆绑，无 Dictionary/StringName），RNG AC-B1 扩展 5 类独立 A/B，删"须取 AC-J3 上限"；L297 AC-B1：同步改写 | grep 确认无"须取 AC-J3 上限"残留 |
| **BL-H** | L96 R8：`!isfinite` 仅限 `roll_float_range`（min/max），int_range/weighted_pick 的 W 为 int 无 inf/NaN 移除死路径；L339 AC-E1b Given：`!isfinite（仅 float_range）`、`W-1>2^31-1（仅 weighted_pick）` | grep 确认无 `!isfinite(W)` 残留 |

**复核确认**：4 项均为 spec/citation/enforcement 修复，零新公式/零新 ADR/零新 GATE（BL-E bound 走既有 OQ3 OPEN、BL-F 漂移源降级 defer rng-math.md）。文档头部 Status/Last Updated/Creative Director Verdict 均已同步反映三审。creative-director 修订优先级 BL-E/F/G/H 并行（4 项无相互依赖，已全部写入）。

**仍 OPEN（合理推迟）**：OQ1 derive 算法 ADR / OQ2 max_weights 下游 / OQ3 rng-math.md（含 W_MAX_SAFE 精确 bound + FMA 两路径漂移核验）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新。

**下一轮复审焦点**：见上文三审末"下一轮复审焦点"——重点验 BL-E `2^31-1` 五处一致、BL-F 待核验三处一致、BL-G AC-J3 引用两处一致、BL-H `!isfinite` 仅限 float_range 两处一致。建议新会话 `/design-review design/gdd/rng-system.md`（本会话 context 已满）。

---

## Review — 2026-08-24 (re-review 3, 四审)

四审 verdict: **NEEDS REVISION**。三审 4 项（BL-E/F/G/H）全闭环无回归（6/6 specialist 独立核实 + 三审末"下一轮复审焦点"4 项一致性确认通过）。本轮新发现 **6 项 BLOCKING + 3 项 RECOMMENDED**，全为 spec/citation/enforcement/可测性修复非重设计（零新公式/零新 ADR/2 新 AC/1 新 GATE）。6 specialist 对抗审查（game-designer/systems-designer/qa-lead/performance-analyst/godot-specialist/creative-director 终审）。

### BLOCKING（6）

1. **[BL-I·perf+CD] PackedInt64Array 未进 AC-B1 positive control + element-write 禁局部别名未约束** — 三审 BL-E 把 F4 scratch buffer 从 `int` 迁到 `PackedInt64Array`（int64 元素与累积器同类型，refcount=1 零 COW），但 AC-B1 positive control 的多类型列表仍为 5 类（Object/Array/PackedInt32Array/Dictionary/StringName），未含 `PackedInt64Array`——该类型构造一路无 guard，若 harness 漏测则 R4 零分配约束的该类型 regression 无 guard。另：`PackedInt64Array` 的 element-write 若经局部别名 `var alias := scratch_buffer` 再 `alias[i]=v`，refcount→2 触发 COW 堆分配（违 R4），此约束未在 R4/F4 文本声明亦无 AC 覆盖。Fix: AC-B1 positive control 扩展为 6 类独立 A/B（加 `PackedInt64Array` 构造一路）+ 新增 COW-on-write element-write positive control（造局部别名写入断言 harness 能观测 delta>0）；R4 禁止列表加 F4 scratch 的 `PackedInt64Array` + element-write 须直接 `self.scratch_buffer[i]` 禁局部别名；跨文档块同步补注 RNG AC-B1 覆盖 `PackedInt64Array` 而 AC-J3 未含。**CD 裁决**：采纳 perf 框架（qa+sys 主张"同型模式"论据不采——BL-A 的 `PackedInt32Array` 针对 `range()` 在 roll 路径构造，BL-E 的 `PackedInt64Array` 是 BATTLE_LOADING 预分配非 roll 路径，非同型）。严重度分歧：qa+sys BLOCKING vs perf 中高→CD 规则 BLOCKING。

2. **[BL-J·qa+CD] AC-E1 fault-injection 缺 W-1>2^31-1 触发条件** — 三审 BL-E 把 fault 条件收紧为 `W-1>2^31-1`，但 AC-E1（fault-injection 单元测试）的 Given 未含此触发条件，fault-injection 无法覆盖该路径。Fix: AC-E1 Given 加 `W-1>2^31-1`（仅 weighted_pick）。

3. **[BL-K·qa+CD] AC-A1a/A1b instrumentation 无 positive control（前三轮盲区）** — AC-A1a/A1b 确定性依赖"独立测试构建 instrumentation 记录调用序列"，但 instrumentation 本身从未被 positive control 验证能正确观测真实差异——若 instrumentation 确定地漏记某 roll，跨运行记录仍恒等会致 AC-A1a/A1b 假阳性 PASS。此为前三轮共同盲区（确定性 pillar 的验证基准本身未被验证）。Fix: 新增 AC-A1c instrumentation 正确性 positive control（用两不同确定 run_seed 跑同一 fixture，断言 instrumentation 记录的两结果序列逐值相异 + roll 计数/args 无漏记多记错记）。

4. **[BL-L·godot+CD] GS-1 randi_range 参数类型 int32 假定未核验（质疑 rationale 非质疑值）** — 三审 BL-E 把保守默认收紧为 `2^31-1=INT32_MAX`，rationale 是"randi_range(int,int) 参数为 int32"。但该参数类型未核验（LLM 训练数据截止 May 2025，Godot 4.4-4.7 超出训练数据），"int64→int32 截断→SWAP"很可能虚构——真实风险更可能是 `randi()` uint32 输出域 modulo 塌缩。**保守值 `2^31-1` 仍安全（无论参数类型如何都保守），仅 rationale 须 hedge**。Fix: F4 fault/为何整数域/变量表参数类型/变量表上界守卫/Tuning W_MAX_SAFE/K 全部 hedge 为"参数类型待核验 defer rng-math.md/OQ3"，保留 `2^31-1` 值。**CD 裁决**：质疑 rationale 不质疑值（BL-F 同型先例 + hedge 不一致须统一）。

5. **[BL-M·godot+CD] GS-2 拒绝采样假定未核验 + AC-D2 边界待核验（分布 pillar 验证基准错误，后果最重）** — F2 委托 Godot `randi_range` 实现，GDD 多处假定 Godot 内置无偏拒绝采样，但该实现未核验——训练数据表明 Godot ~4.3 用 simple modulo `randi()%range` 存在 modulo bias。AC-D2（chi-square 分布均匀性）的边界依赖此实现：若拒绝采样则上界≈0，若 simple modulo 则上界=(输出域 mod range)/输出域。Fix: F2 实现/变量表/Output Range/Example/Edge(M1)/AC-D2(iii) 边界全部 hedge 为"Godot 内部实现待核验 defer rng-math.md/OQ3"。

6. **[BL-N·game-designer+CD] FAULTED 终态未声明 + set_stream_state 在 FAULTED 下行为未约束（违承诺②"不被静默重摇"）** — R6 状态机画了 UNINIT→READY→FAULTED，但未声明 FAULTED 为终态——若 FAULTED 后仍可调 `set_stream_state` 改写 state，等于通过改 state 复活 Faulted 流，违承诺②"不被静默重摇或掩盖"。Fix: R6 显式声明 FAULTED 为终态（一旦 latch 不可再调 roll，仅可转 BATTLE_ENDING teardown，须 teardown 后新 battle 重新初始化）；R7 `set_stream_state` 加前置（仅 READY 可调，FAULTED 下调用→R8 fault）。**CD 裁决**：从 RECOMMENDED 升级 BLOCKING（违玩家面承诺②）。

### RECOMMENDED（3，一并处理）

7. **[GATE-G4·godot+CD] rng-math.md 不存在的结构守卫** — 多处 Godot 行为断言（参数类型/拒绝采样 vs modulo/FMA/seed= 处理/state 往返）因 `rng-math.md` 不存在（`docs/engine-reference/godot/` grep 零命中）而无法核验。Fix: 新增 GATE-G4 rng-math.md 存在性 gate——核验前任何 Godot 行为断言须 hedge"待核验 defer rng-math.md"，rng-math.md 落地（OQ3）同时解阻候选4/5/BL-F rationale。RECOMMENDED 升级结构守卫。

8. **[F3 !isfinite(max-min)] — 三审 BL-H 移除了 !isfinite(W) 死路径，但 min/max 各自有限时差值仍可能溢出 float32 为 +inf。Fix: F3 fault 加 !isfinite(max-min)（min/max 各自有限但量级极大时差值溢出），后续 randf()*inf 产出 inf/NaN；AC-E1b Given 同步。**

9. **[承诺②交叉引用 GATE-G3] — Player Fantasy 承诺②（故障诚实暴露）的兑现依赖 GATE-G3（game-root has_fault 检查义务）+ 消费方 phase-staging，两者均 BLOCKED。Fix: Player Fantasy 承诺②后加交叉引用。**

### OPEN 保持 deferred

OQ1 derive 算法→ADR；OQ2 max_weights→下游 GDD；OQ3 rng-math.md Godot 核验（含 randi_range 参数类型 + 拒绝采样 vs modulo + W_MAX_SAFE 精确 bound + FMA 两路径漂移）；OQ4 run_seed 来源；OQ5 stream_id 终态；OQ6 oracle 捕获。跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新。

**下一轮复审焦点**：验证 BL-I 6 类+COW control 在 AC-B1/跨文档块两处一致、BL-J AC-E1/AC-E1b 同步、BL-K AC-A1c 与 AC-A1a/b 衔接、BL-L hedge 在 F4 五处一致、BL-M hedge 在 F2 六处一致、BL-N FAULTED 终态在 R6/R7 一致、GATE-G4 断言清单完整、承诺②交叉引用。建议新会话第五轮 `/design-review design/gdd/rng-system.md`（独立上下文，本会话 context 已满）。

---

## 修订闭环 — 2026-08-24 (re-review 3, 四审)

四审 6 项 BLOCKING + 3 项 RECOMMENDED 已全部修订写入 `design/gdd/rng-system.md`：

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-I** | R4(L62): `int` scratch buffer→`PackedInt64Array` + 禁止列表加 F4 scratch `PackedInt64Array` + element-write 须直接 `self.scratch_buffer[i]` 禁局部别名（refcount→2 触发 COW）；L171 F4 机制加实现约束（AC-B1 COW-on-write positive control 验证）；AC-B1(L297) positive control 扩展 6 类独立 A/B（加 `PackedInt64Array` 构造一路）+ 新增 COW-on-write element-write positive control（造局部别名 `var alias:=scratch_buffer` 后 `alias[i]=v` 断言 harness 观测 delta>0）；跨文档块 L226 同步补注 RNG AC-B1 覆盖 `PackedInt64Array` 而 AC-J3 未含 | grep 确认 `PackedInt64Array` 在 R4/F4/AC-B1/跨文档块四区一致 |
| **BL-J** | AC-E1(L333) Given 加 `W-1>2^31-1`（仅 weighted_pick）；F3(L155) fault 加 `!isfinite(max-min)`（min/max 各自有限但量级极大时差值溢出 float32 为 +inf）；AC-E1b(L339) Given 同步 `!isfinite`（含 max-min 差值溢出，仅 float_range）| grep 确认 AC-E1/AC-E1b 触发条件对称 |
| **BL-K** | 新增 AC-A1c instrumentation 正确性 positive control（AC-A1b 后、AC-A2 前，unit，BLOCKING）— 用两不同确定 run_seed（seed_A/seed_B）跑同一 fixture，断言 instrumentation 记录的两结果序列逐值相异（证明能观测真实差异非假阳性）+ roll 计数==fixture 计数（无漏记多记）+ args==fixture args（无错记）| grep 确认 AC-A1c 在 AC-A1b 与 AC-A2 间 |
| **BL-L** | F4 fault(L173)/为何整数域(L174)/变量表参数类型(L167a)/变量表上界守卫(L167b)/Tuning W_MAX_SAFE(L244)/Tuning K(L243) 全部 hedge 为"参数类型待核验 defer rng-math.md/OQ3：训练数据表明 Godot 4.x 参数为 int64 非假定 int32，'int64→int32 截断→SWAP'很可能虚构，真实风险为 randi() uint32 输出域 modulo 塌缩"，保留 `2^31-1` 值 | grep 确认 `2^31-1` 值保留、rationale 全 hedge |
| **BL-M** | F2 实现(L136)/变量表 result(L134)/Output Range(L137)/Example(L138)/Edge(M1)(L140)/AC-D2(iii) 边界(L325) 全部 hedge 为"Godot 内部实现待核验 defer rng-math.md/OQ3：训练数据表明 Godot ~4.3 用 simple modulo `randi()%range` 存在 modulo bias，非'内置无偏、拒绝采样'" | grep 确认无"内置无偏/拒绝采样"既定断言残留 |
| **BL-N** | R6(L76) 状态机后显式声明 FAULTED 为终态（一旦 latch 不可再调 roll，fault_reason 已存在不变保持 FAULTED，仅可转 BATTLE_ENDING teardown，须 teardown 后新 battle 重新初始化不残留 FAULTED 流，违承诺②"不被静默重摇"）；R7(L82) `set_stream_state` 加前置（仅 READY 可调，FAULTED 下调用→R8 fault，fault_reason 已存在不变保持 FAULTED 终态，违承诺②——FAULTED 流不允许通过改写 state 复活）| grep 确认 FAULTED 终态在 R6/R7 一致 |
| **GATE-G4** | 新增 GATE-G4 rng-math.md 存在性 gate（GATE-G3 后、### H 前）— rng-math.md 创建并核验前任何 Godot 行为断言不得作事实陈述须 hedge"待核验 defer rng-math.md/OQ3"，落地同时解阻候选4/5/BL-F rationale | grep 确认 GATE-G4 在 GATE-G3 与 ### H 间 |
| **F3 !isfinite(max-min)** | 见 BL-J（F3 L155 + AC-E1b L339）| — |
| **承诺②交叉引用** | Player Fantasy(L27) 承诺②后加交叉引用 GATE-G3（game-root phase 边界 has_fault 检查义务）+ 消费方 phase-staging（R8 零值守卫 + 跨文档块 bidirectional flag），两者均 BLOCKED until 对端更新 | grep 确认交叉引用在承诺②末 |

**复核确认**：9 项均为 spec/citation/enforcement/可测性修复，零新公式/零新 ADR/2 新 AC（AC-A1c + AC-B1 COW-on-write element-write control）/1 新 GATE（GATE-G4）。3 OPEN 保持 deferred（OQ1/OQ2/OQ4/OQ5/OQ6 + OQ3 rng-math.md）。文档头部 Status/Last Updated/Creative Director Verdict 待同步反映四审。creative-director 修订优先级 BL-I/J/K/L/M/N + GATE-G4/F3/承诺② 并行（9 项无相互依赖，已全部写入）。

**仍 OPEN（合理推迟）**：OQ1 derive 算法 ADR / OQ2 max_weights 下游 / OQ3 rng-math.md（含 randi_range 参数类型 + 拒绝采样 vs modulo + W_MAX_SAFE 精确 bound + FMA 两路径漂移核验）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off。

**下一轮复审焦点**：见上文四审末"下一轮复审焦点"——重点验 BL-I 6 类+COW control 两处一致、BL-J AC-E1/E1b 对称、BL-K AC-A1c 衔接、BL-L hedge 五处一致、BL-M hedge 六处一致、BL-N FAULTED 终态 R6/R7 一致、GATE-G4 断言清单、承诺②交叉引用。建议新会话第五轮 `/design-review design/gdd/rng-system.md`（本会话 context 已满）。

---

## Review — 2026-08-24 (re-review 4, 五审) — Verdict: NEEDS REVISION

**Scope signal**: L（revision effort M 端 — 外科手术式 spec/AC/hedge/testability/boundary-parity 修复）
**Review depth**: full
**Specialists**: 跨文档核验员(Explore,在飞)、game-designer、systems-designer、qa-lead、godot-specialist、performance-analyst + creative-director（终审,Opus）
**Blocking items**: 5（BL-1..BL-5，本轮新发现，全为 spec/AC/hedge/testability/boundary-parity 修复非重设计）| **Recommended**: 22 | **Nice-to-have**: 11
**Prior verdict resolved**: 四审 9 项（BL-I..N + GATE-G4/F3/承诺②）全部修订闭环无回归（6 specialist 独立核实 + 四审末"下一轮复审焦点"8 项一致性确认通过 7/8——BL-N"声明-only 未 testability-闭环"为本轮 BL-2 源）；本轮新开 5 项

**Summary**: 五审确认四审 9 项全部闭环、无跨文档引用/GATE 状态回归；本轮新发现 5 项 BLOCKING，全为 hedging-completeness/testability/boundary-parity 空间的更微妙缺口，零新公式/零新 ADR（BL-5 derive int64 陷阱归既有 OQ1 ADR）/1 新 AC（AC-E1c FAULTED 终态不可复活）/0 新 GATE。creative-director 终审 NEEDS REVISION，设计意图（确定性+流隔离+无 OS 熵+零分配+fail-fast）保持自洽。2 处 specialist 严重度分歧由用户裁定均采 CD BLOCKING：BL-4（systems RECOMMENDED vs CD BLOCKING——parity BL-B/BL-E + fallback 拒绝采样 hang 独立于 MVP 消费方 + GDD 自陈"rigorous boundary"）、BL-5（godot RECOMMENDED vs CD 主张 BLOCKING——silent-failure + pillar-invariant 模式同 BL-1，4 轮漏检的 genuinely NEW 议题支持升级）。BL-2 揭示的四审 BL-N"声明-only、未 testability-闭环"是本轮唯一 prior-closure 回退，属 testability pattern 深化非新问题类。模式与前轮一致：每轮发现更少更微妙，均在 hedging/testability/boundary-parity 空间，不在核心设计。

### 5 项 BLOCKING

1. **[BL-1·perf+CD 确认] `randi_range`/`randf`/`randi` 零分配是假设而非验证（违 GATE-G4）** — R4(line 62)将"零分配"作事实陈述，但 `gen.randi_range()` 内部 C++ 实现可能分配未 hedge（对比无偏性/FMA/state 往返均已 hedge）。6 类 positive control 只证 harness 能抓 GDScript 侧分配，**不证能抓 C++ 侧 native-method 内部分配**——若 native method 内部分配，R4 零分配静默崩塌且无 AC 报警（违 fail-fast pillar）。Fix: hedge R4/F2 零分配 + 零分配源码核验进 OQ3/rng-math.md scope + 原生 String 进禁列/positive control。
2. **[BL-2·qa+CD 确认] FAULTED 终态两条行为无 AC（闭合四审 BL-N"声明-only 未 testability-闭环"）** — R6/R7 声明 FAULTED 终态行为（FAULTED 后再 roll→fault / set_stream_state on FAULTED→fault），但无 AC 测试。AC-E1b Given="任一流处于 READY"只覆盖 READY→fault，不覆盖 FAULTED-revival-prohibition。承诺②"不被静默重摇"的可测根（FAULTED 不可复活）无测试——一个静默 reset state on FAULTED 的实现能通过当前全部 AC。Fix: 新增 AC-E1c FAULTED 终态不可复活 + AC-E1b Given 注"仅覆盖 READY→fault，FAULTED→fault 见 AC-E1c"。
3. **[BL-3·qa+CD 确认] AC-E1 Gate 字段与 body 不一致 + 可测内核被捆绑** — AC-E1 Gate=BLOCKING（暗示现在可测），但 Then body="BLOCKING on 各消费方落地 + on GATE-G3 解阻"——AC-E1 是唯一 Gate 字段不反映 body 依赖的 AC（AC-F3 正确标注）。Then 混 4 断言：(1)(2) RNG 级 fault latch（现在可测）被 (3)(4) 的 gated 状态拖累无法独立签发。Fix: 拆 AC-E1——(1)(2) 留为可测 AC-E1（BLOCKING no dep）；(3) 移入 GATE-G3；(4) 移入消费方 bidirectional flag。
4. **[BL-4·systems→CD 升级] F2 缺范围上限守卫（与 F4 W_MAX_SAFE 不对称）+ fallback hang** — F4 有 `W-1>2^31-1`→fault 防 uint32 输出域塌缩，F2（公开 API）无等效。`roll_int_range(0, 2^32)`：委托路径静默塌缩；fallback 拒绝采样路径无限循环挂起（`floor(2^32/(2^32+1))=0`→空 unbiased range→hang）。【用户裁定采 CD BLOCKING】Fix: F2 加 `max-min>RANGE_MAX_SAFE`（保守 2^31-1，对称 F4）+ Tuning 加 `roll_int_range_RANGE_MAX_SAFE`。
5. **[BL-5·godot→CD 主张升 BLOCKING] `derive()` GDScript int64 算术移位陷阱未标注** — splitmix64/PCG-DXSM 依赖 uint64 逻辑右移，但 GDScript `>>` 对负 int64 是算术移位（符号扩展），naive 移植得错误结果；int64 乘法溢出回绕无 documented contract。F1 契约"纯整数运算"作事实陈述未 hedge 此 GDScript-specific 陷阱。naive port 静默破坏 derive 单射（AC-A3）+ 确定性（AC-A4）。【4 轮漏检 genuinely NEW 议题；用户裁定采 CD BLOCKING】Fix: F1 契约加注 + 归 OQ1 ADR（选 32-bit 拆分/位掩码/GDExtension 路径）。

### 22 项 RECOMMENDED（一并补）

- game-designer(3): ①玩家面行27"可复现技术状态"越界到 dev 能力→改"故障被显式暴露而非静默掩盖"；②承诺②罕见性前提未声明→补 caveat；③"故障诚实暴露"玩家面体验形态未触 fantasy 层→补方向性描述（归 game-root ControlledGameplayFault 域）。
- godot-specialist(2): ④`randi()` uint32 输出域断言未 hedge/未进 GATE-G4 清单（与 BL-1 同类 hedging gap）；⑤= BL-5。
- performance-analyst(5): ⑥原生 String 未入 R4 禁列/positive control；⑦COW control 未覆盖消费方 PackedInt32Array weights；⑧SKILL_DRAFT/RISK_CHOICE/ZHANGTIAN_HERB 在"10k Active tick"可能不执行→fixture 加 pause/resume+battle-end 或 consumer-coverage manifest；⑨计数器 per-tick vs 累计语义未明→指定 per-battle 累计；⑩`Dictionary[StringName]` dispatch key 驻留未锁→强制编译期字面量或首选 int-indexed Array。
- qa-lead(9): ⑪AC-E1 `!isfinite` 浮点笼统→显式三子类对齐 AC-E1b；⑫AC-D1(ii) chi-square 与 (i) oracle 在 oracle 自带 modulo bias 时不可同时满足→defer OQ3 像 AC-D2(iii)；⑬AC-D1 `K=1000` 与 F4 scale-factor K 命名冲突→改 `M=1000` roll 匹配计数；⑭AC-F3"足够供"非可测语言→移出 Then；⑮AC-C2"构建期 guard"机制未指定→指定 CI grep+runtime assert；⑯AC-A1c"roll 计数"测量口径未定义→按 `roll_*` API 调用次数计；⑰AC-A3 混 ADR 分析论证(非自动)与经验采样(自动)→拆分；⑱AC-A4/A5 混分析证明与 cross-arch replay→拆分 automated vs non-automated；⑲AC-D2 Gate 漏标 OQ3。
- systems-designer(3): ⑳= BL-4；㉑AC-D1 K 冲突(=⑬)+ F4 示例 ×100 vs AC-D1 ×1000 不一致→统一 + 标 float 权重；㉒F3 行156"float32"→"float64"（GDScript float=double）。

### OPEN 保持 deferred

OQ1 derive 算法→ADR（+ BL-5 int64 陷阱）；OQ2 max_weights→下游 GDD；OQ3 rng-math.md Godot 核验（+ BL-1 native method 零分配源码 + BL-4 `randi()` 输出域 + BL-5 int64 移位 contract）；OQ4 run_seed 来源；OQ5 stream_id 终态；OQ6 oracle 捕获。跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off。

**下一轮复审焦点**：验证 5 项修订真正闭环、无新引入矛盾（尤其 BL-1 零分配 hedge 在 R4/GATE-G4/OQ3 三处一致 + 原生 String 在 R4/AC-B1/跨文档块三处一致；BL-2 AC-E1c 与 AC-E1b Given 衔接；BL-3 AC-E1 拆分后 (3)→GATE-G3/(4)→bidirectional flag 引用完整；BL-4 RANGE_MAX_SAFE 在 F2 fault/Edge/Tuning/OQ3 四处一致；BL-5 int64 陷阱在 F1 契约/OQ1 两处一致）。建议新会话第六轮 `/design-review design/gdd/rng-system.md`（独立上下文，本会话 context 已满）。

---

## 修订闭环 — 2026-08-24 (re-review 4, 五审)

五审 5 项 BLOCKING + 22 项 RECOMMENDED 已全部修订写入 `design/gdd/rng-system.md`：

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-1** | R4(L62) 加"零分配覆盖边界"hedge（positive control 只证 GDScript 侧不证 native method 内部）+ 零分配源码核验进 OQ3/rng-math.md scope + 原生 String 进禁列；GATE-G4(L403) Given 加 `randi()` 输出域/native method 零分配/`>>` 移位/int64 溢出断言 + Then 解阻 BL-1/BL-4/BL-5；OQ3(L424) scope 加 (a)`randi()` 输出域 (b)native method 零分配 (c)int64 移位/溢出 contract；AC-B1(L307) positive control 加第 7 类原生 String + COW-on-write parity 覆盖消费方 PackedInt32Array weights；跨文档块(L223/229) 禁列加 String + "5类→7类" + BL-1/BL-I 同步注 | hedge + scope 一致 |
| **BL-2** | 新增 **AC-E1c** FAULTED 终态不可复活（AC-E1b 后，unit，BLOCKING）— 先注入 fault 使流 FAULTED，再分别注入 (i)roll (ii)set_stream_state，断言 fault_reason 不变+流仍 FAULTED+不产生新 roll 推进；AC-E1b Given 注"仅覆盖 READY→fault，FAULTED→fault 见 AC-E1c" | 1 新 AC |
| **BL-3** | AC-E1(L339) 拆分——(1)(2) roll 返回零值+latch fault_reason 留为 RNG 级 AC-E1（BLOCKING no dep，testable now）；(3) GameRoot phase 边界 has_fault→ControlledGameplayFault+零值不进下一 phase → 见 GATE-G3；(4) 消费方 has_fault 守卫 → 见 bidirectional flag；AC-E1 Given 同步显式三子类 `!isfinite`(qa⑪)+ `max-min>RANGE_MAX_SAFE`(BL-4)；AC-E1b Given 加 `max-min>RANGE_MAX_SAFE` | Gate 字段反映 body |
| **BL-4** | F2 fault(L140) 加 `max-min>RANGE_MAX_SAFE`（保守 2^31-1，对称 F4 W_MAX_SAFE，防 `randi()` uint32 输出域塌缩+fallback 拒绝采样 hang）；F2 Edge(L141) 注 fallback hang 由 RANGE_MAX_SAFE 守卫；Tuning(L246) 加 `roll_int_range_RANGE_MAX_SAFE`（deferred OQ3）；AC-E1/AC-E1b Given 加 `max-min>RANGE_MAX_SAFE` 触发；AC-A4 验证加 `randi()` 输出域核验→BL-4 bound | 对称 F4 |
| **BL-5** | F1 契约(L122) 加 GDScript int64 陷阱 hedge（int 64-bit signed 无 uint64，`>>` 算术移位、`*` 溢出回绕无 contract，naive 移植 splitmix64/PCG-DXSM 静默破坏单射+确定性，须 32-bit 拆分/位掩码/GDExtension，归 OQ1 ADR）；OQ1(L422) 加 int64 陷阱 scope；GATE-G4/OQ3 同步 | 归既有 OQ1 ADR |

**RECOMMENDED 22 项落点**（见上 22 项列表，均已在对应行写入）：game-designer① 行27 措辞 + ②③ caveats；perf⑨ R7 per-battle 累计 + ⑩ R6 int-indexed Array 首选 + ⑧ AC-B1 fixture pause/battle-end + ⑥ String + ⑦ COW PackedInt32Array parity；qa⑫ AC-D1(ii) defer OQ3 + ⑬ AC-D1 K→M + ⑭ AC-F3 移"足够供" + ⑮ AC-C2 机制 + ⑯ AC-A1c 口径 + ⑰ AC-A3 拆分 + ⑱ AC-A4/A5 拆分 + ⑲ AC-D2 Gate 补 OQ3；systems㉑ AC-D1 scale 对齐 F4 + ㉒ F3 float32→float64。

**复核确认**：5 项 BLOCKING + 22 RECOMMENDED 全为 spec/AC/hedge/testability/boundary-parity 修复——**零新公式、零新 ADR**（BL-5 derive 陷阱归既有 OQ1 ADR）、零设计意图变更、1 新 AC（AC-E1c FAULTED 不可复活）、0 新 GATE。3-4 项依赖既有 GATE-G3/GATE-G4/OQ1/OQ3 gate。文档头部 Status/Last Updated/Review Mode/Creative Director Verdict/Specialist 注记均已同步反映五审。creative-director 修订优先级 BL-3（解锁 BL-2）→BL-2→BL-1→BL-4→BL-5（5 项已全部写入）。

**仍 OPEN（合理推迟）**：OQ1 derive 算法 ADR（+BL-5 int64 陷阱）/ OQ2 max_weights 下游 / OQ3 rng-math.md（含 randi_range 参数类型 + 拒绝采样 vs modulo + W_MAX_SAFE/RANGE_MAX_SAFE 精确 bound + FMA 两路径漂移 + native method 零分配源码 + int64 移位/溢出 contract 核验）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off。11 项 Nice-to-have（game-designer 无感张力 / godot R7 PCG 表征 vs AC-H1 hedge 不一致 + GATE-G4 scope 显式化 + 4.7 GH-113228 已知声明 / perf per-stream counter 存储 + dispatch Array 预设 / qa 跨文档块"5类"stale[已顺带修] + AC-B1 引 AC-J6/bidirectional flag AC-J3 + AC-H1 对抗性 state + AC-C1(c) 非自动标 + AC-F1 实例计数=0 机制）deferred advisory，不阻塞。

**下一轮复审焦点**：见上文五审末"下一轮复审焦点"——重点验 BL-1 零分配 hedge 三处一致 + String 三处一致、BL-2 AC-E1c 衔接、BL-3 拆分引用完整、BL-4 RANGE_MAX_SAFE 四处一致、BL-5 int64 陷阱两处一致。建议新会话第六轮 `/design-review design/gdd/rng-system.md`（本会话 context 已满）。

---

## Review — 2026-08-25 (re-review 5, 六审) — Verdict: NEEDS REVISION

**Scope signal**: L（S-scope hedge/citation/testability/对齐 修复）
**Review depth**: full
**Specialists**: 跨文档核验员(Explore)、game-designer、systems-designer、qa-lead、godot-specialist、performance-analyst + creative-director（终审,Opus）
**Blocking items**: 5（BL-6..BL-10，本轮新发现，全为 hedge/citation/testability/对齐 修复非重设计）| **Recommended**: 4（QA-2/GS-5/GS-12/GD-4） | **Nice-to-have**: 0
**Prior verdict resolved**: 五审 5 项（BL-1..BL-5）+ 22 项 RECOMMENDED 全部修订闭环无回归（6 specialist 独立核实 + 五审末"下一轮复审焦点"5 项一致性确认通过）；本轮新开 5 项

**Summary**: 六审确认五审全部闭环、无跨文档引用/GATE 状态回归；本轮新发现 5 项 BLOCKING，全为 hedging-completeness/testability/internal-consistency 空间的更微妙缺口，零新公式/零新 ADR（BL-6 减法溢出 + BL-7 COW-on-write + BL-9 set_state re-seed 三项 Godot 4.7.1 行为断言均归既有 OQ3 rng-math.md 核验 + OQ1 ADR）/1 新 AC（AC-H1b 跨实例状态可移植性）/0 新 GATE。creative-director 终审 NEEDS REVISION，设计意图（确定性+流隔离+无 OS 熵+零分配+fail-fast）保持自洽。1 处 specialist 严重度分歧（GS-4 vs PA-4，COW-on-write 4.7.1 未 hedge）由 CD 裁定 BLOCKING 胜出——PA 论据"AC-B1 会捕获 F4 COW"为循环依赖（AC-B1 捕获能力取决于 COW positive control 产生正向信号，若 COW 不触发则信号失败→计数器未校准→AC-B1 亦无法捕获 F4 COW），同 BL-1 升级先例。BL-8 揭示的五审 AC-E1c"返回 FAULTED 标志不变"与 AC-E1b"fault 后 ==s"+R7 PCG-uint64 三者矛盾是本轮唯一 prior-closure 回退，属 testability pattern 深化非新问题类。模式与前轮一致：每轮发现更少更微妙，均在 hedging/testability/对齐 空间，不在核心设计。

### 5 项 BLOCKING

1. **[BL-6·systems+CD 确认] F2 fault guard `max-min` 减法溢出可绕过守卫** — F2 fault guard 用 `max-min > RANGE_MAX_SAFE`（2^31-1）防 uint32 输出域塌缩，但 `max-min` 在 GDScript int64 two's complement 下可溢出为负（`min=INT64_MIN, max=0` → `max-min` 溢出为 INT64_MIN 负值），`负值 > 2^31-1` 为 false → 守卫静默不触发，塌缩路径畅通（与 BL-5 int64 `*`/`>>` 陷阱同类，`-` 减法溢出回绕无 documented contract）。Fix: F2 附加减法溢出 bypass hedge + 路由 OQ1 ADR + OQ3 核验 overflow-safe 比较式；AC-E1/AC-E1b Given 注入 `min=INT64_MIN,max=0` / `min=-1,max=INT64_MAX` 情况。
2. **[BL-7·godot→CD 升级] R4 COW-on-write 与 F4 触发为 Godot 4.7.1 行为断言未 hedge（致 AC-B1 方法论循环失效）** — R4 禁局部别名与 F4 COW-on-write 触发堆分配均依赖"PackedInt64Array refcount→2 触发 COW"这一 Godot 4.7.1 行为断言未 hedge（4.7 引入"packed array 元素不再触发整个 packed array 属性的 setter"相邻变更，COW 是否仍触发须核验）。若 COW 实际不触发，AC-B1 COW-on-write positive control 永卡 INCONCLUSIVE、禁局部别名约束失 regression guard，违 fail-fast pillar（同 BL-1 静默失败模式）。PA 评为 RECOMMENDED（"AC-B1 会捕获 F4 COW"），CD 裁定 BLOCKING——PA 论据为循环依赖。【用户裁定采 CD BLOCKING】Fix: R4 声明 + F4 + AC-B1 三处附加 `defer rng-math.md/OQ3/GATE-G4` hedge + AC-B1 退化方案（静态分析/lint 禁别名 + 代码审查）。
3. **[BL-8·qa+CD 确认] AC-E1c "返回 FAULTED 标志不变"与 AC-E1b+R7 三者矛盾回归** — 五审新增 AC-E1c 原文"返回 FAULTED 标志不变"与 AC-E1b"fault 后 get_stream_state 仍 ==s"+R7 PCG 内部 state 为 uint64 三者矛盾——PCG state 既为 uint64 原始值无 FAULTED 标志位，AC-E1c"返回标志不变"语义不成立。Fix: AC-E1c 重写为 `has_fault(stream_id)` 仍 true（流仍 FAULTED 终态）+ `get_stream_state(id)` 仍 ==s（与 AC-E1b/R7 一致，不引入"FAULTED 标志"返回语义）；验证更新断言两者。
4. **[BL-9·godot+CD 确认] R7 set_state 不 re-seed 为 Godot 4.7.1 行为断言未 hedge（致 SaveSystem 跨实例静默腐化）** — R7 AC-H1 依赖"set_stream_state(s) 后从 s 起的序列 == fresh gen 从 s 起的序列"，即 set_state 不隐式 re-seed。此为 Godot 4.7.1 行为断言未 hedge——若 set_state 内部隐式 re-seed，SaveSystem 跨实例存档恢复静默腐化（存档 state s 加载后序列 ≠ fresh gen 从 s 起序列），AC-H1 假阳性通过。Fix: R7 附加 hedge `defer rng-math.md/OQ3/GATE-G4` + 新增 AC-H1b 跨实例状态可移植性测试（gen_B.set_stream_state(s) → gen_B 序列 == gen_A 从 state=s 起的 fresh 序列，BLOCKING）。
5. **[BL-10·跨文档+CD 确认] caveat 误引 R8 应为 R9 ControlledGameplayFault 域** — Player Fantasy caveat"故障暴露形态见 game-root R8 ControlledGameplayFault 域"误引——game-root R8 为正常 teardown 顺序，R9 才是 ControlledGameplayFault 玩家面形态/TECHNICAL_ABORT/reservation-commit 域（与行 35"属 game-root R9 SaveSystem 域"对齐）。Fix: caveat `R8` → `R9 ControlledGameplayFault 玩家与持久化域`。

### 4 项 RECOMMENDED（一并补）

- qa-lead(1): ①= BL-8 的 has_fault 显式断言补强（AC-E1 Then 显式断言 RNG 立即 latch fault_reason 且 has_fault(stream_id) 转 true，保证 AC-E1c Given"已 FAULTED"前置可建立）。
- godot-specialist(2): ②= BL-7 的 GATE-G4 Then 解阻清单修正（移除孤儿"候选4/5"引用，改用断言名称）+ 解阻 BL-6/BL-7/BL-9；③= BL-7 的 OQ3 源文件 hedging（"引用 random_pcg.h/cpp"→"疑 random_pcg.* 源文件，待核验"）。
- game-designer(1): ④= BL-8 的 has_fault per-stream/global 双重形式澄清（R8 注无参形式=任一流 FAULTED 即 true，GameRoot 级 phase 边界用；逐流形式 has_fault(stream_id)=该流是否 FAULTED，AC-E1c 逐流观测用——R6 逐流 FAULTED 终态 + R8 GameRoot 级全局检查共存，非二选一）。

### OPEN 保持 deferred

OQ1 derive 算法→ADR（+ BL-5 int64 `*`/`>>` 陷阱 + BL-6 `-` 减法溢出 + F2 fault guard overflow-safe 形式）；OQ2 max_weights→下游 GDD；OQ3 rng-math.md Godot 核验（+ BL-1 native method 零分配 + BL-4 `randi()` 输出域 + BL-5 int64 移位/溢出 + BL-6 int64 `-` 减法溢出 + BL-7 PackedInt64Array COW-on-write 4.7.1 触发 + BL-9 set_state 不隐式 re-seed）；OQ4 run_seed 来源；OQ5 stream_id 终态；OQ6 oracle 捕获。跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off。

**下一轮复审焦点**：验证 5 项修订真正闭环、无新引入矛盾（尤其 BL-6 `-` hedge 在 F2/AC-E1/AC-E1b/OQ1/OQ3 五处对齐一致；BL-7 COW hedge 在 R4/F4/AC-B1/GATE-G4/OQ3 五处一致 + 退化方案可执行；BL-8 AC-E1c 重定后与 AC-E1b+R7 三者一致；BL-9 set_state hedge 在 R7/AC-H1b/GATE-G4/OQ3 四处一致 + AC-H1b 跨实例可测；BL-10 R9 对齐在 caveat/行 35 两处一致）。建议新会话第七轮 `/design-review design/gdd/rng-system.md`（独立上下文，本会话 context 已满）。

---

## 修订闭环 — 2026-08-25 (re-review 5, 六审)

六审 5 项 BLOCKING + 4 项 RECOMMENDED 已全部修订写入 `design/gdd/rng-system.md`：

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-6 / SD-1** | F2 fault(L142) 附加减法溢出 bypass hedge（`min=INT64_MIN,max=0` / `min=-1,max=INT64_MAX` 下 `max-min` 溢出为负绕过守卫，仅 int_range，BL-5 int64 陷阱同类，defer OQ1 ADR + OQ3 核验 overflow-safe 比较式）；F1 契约(L124) BL-5 framing 扩展覆盖 `-` 减法；AC-E1 Given(L343) + AC-E1b Given(L350) 注入两溢出情况；OQ1(L433) 扩展覆盖 `-` + Affects 列加 BL-6 | hedge 三处对齐 + AC 注入情况 |
| **BL-7 / GS-4** | R4 COW 声明(L64) + F4(L174) + AC-B1 COW 控制(L307) 三处附加 `defer rng-math.md/OQ3/GATE-G4` hedge（4.7"packed array 元素不再触发整个 packed array 属性 setter"相邻变更须核验 4.7.1 仍触发 COW；若不触发 AC-B1 永卡 INCONCLUSIVE、禁局部别名失 regression guard，同 BL-1 静默失败）；AC-B1 加 INCONCLUSIVE 退化方案（静态分析/lint 禁 `var alias := scratch_buffer` + 代码审查）；GATE-G4 Given(L414) 断言清单加 PackedInt64Array COW-on-write；GATE-G4 Then(L416) 解阻 BL-7；OQ3(L435) scope 加 (d) COW-on-write | hedge 三处一致 + 退化方案 |
| **BL-8 / QA-1** | AC-E1c(L359) 重写为 `has_fault(stream_id)` 仍 true（流仍 FAULTED 终态，FAULTED 态观测统一走 has_fault()）+ `get_stream_state(id)` 仍 ==s（与 AC-E1b/R7 一致，不引入"FAULTED 标志"返回语义）；验证更新断言 has_fault 仍 true + get_stream_state 仍 ==s；R8 has_fault()(L100) 加 per-stream/global 澄清（GD-4）；AC-E1 Then(L345) 显式断言 has_fault(stream_id) 转 true（QA-2） | AC-E1c 与 AC-E1b+R7 三者一致 |
| **BL-9 / GS-3** | R7(L85) set_state 不 re-seed hedge（`defer rng-math.md/OQ3/GATE-G4`，set_state 内部是否隐式 re-seed 未核验，致 SaveSystem 跨实例静默腐化）；新增 **AC-H1b** 跨实例状态可移植性测试（AC-H1 后，unit，BLOCKING）— gen_B.set_stream_state(s) → gen_B 序列 == gen_A 从 state=s 起的 fresh 序列，由 GATE-G4 rng-math.md 限制；GATE-G4 Given(L414) 断言清单加 set_state 不 re-seed；GATE-G4 Then(L416) 解阻 BL-9；OQ3(L435) scope 加 (e) set_state 不 re-seed | hedge + 1 新 AC |
| **BL-10 / GD-1** | Player Fantasy caveat(L37) `R8` → `R9 ControlledGameplayFault 玩家与持久化域`（R8=teardown，R9=ControlledGameplayFault 玩家面/TECHNICAL_ABORT/reservation-commit，与行 35 对齐） | R9 对齐两处一致 |

**RECOMMENDED 4 项落点**（见上 4 项列表，均已在对应行写入）：qa① AC-E1 Then has_fault 显式断言；godot② GATE-G4 Then 解阻清单修正（移除孤儿引用 + 解阻 BL-6/BL-7/BL-9）+ ③ OQ3 源文件 hedging；gd④ R8 has_fault per-stream/global 双重形式澄清。

**复核确认**：5 项 BLOCKING + 4 RECOMMENDED 全为 hedge/citation/testability/对齐 修复——**零新公式、零新 ADR**（BL-6 减法溢出 + BL-7 COW + BL-9 set_state 三项 4.7.1 行为断言均归既有 OQ3 rng-math.md 核验 + OQ1 ADR）、零设计意图变更、1 新 AC（AC-H1b 跨实例状态可移植性）、0 新 GATE。3-4 项依赖既有 GATE-G3/GATE-G4/OQ1/OQ3 gate。文档头部 Status/Last Updated/Review Mode/Creative Director Verdict/Specialist 注记均已同步反映六审。creative-director 修订优先级 BL-10→BL-8（解锁 QA-2/GD-4）→BL-6→BL-9（解锁 AC-H1b）→BL-7（5 项已全部写入）。

**仍 OPEN（合理推迟）**：OQ1 derive 算法 ADR（+BL-5 int64 `*`/`>>` 陷阱 + BL-6 `-` 减法溢出 + F2 fault guard overflow-safe 形式）/ OQ2 max_weights 下游 / OQ3 rng-math.md（含 randi_range 参数类型 + 拒绝采样 vs modulo + W_MAX_SAFE/RANGE_MAX_SAFE 精确 bound + FMA 两路径漂移 + native method 零分配源码 + int64 移位/溢出/减法 contract + PackedInt64Array COW-on-write 4.7.1 触发 + set_state 不隐式 re-seed 核验）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off。

**下一轮复审焦点**：见上文六审末"下一轮复审焦点"——重点验 BL-6 `-` hedge 五处对齐、BL-7 COW hedge 三处一致 + 退化方案可执行、BL-8 AC-E1c 与 AC-E1b+R7 三者一致、BL-9 AC-H1b 跨实例可测、BL-10 R9 对齐两处一致。建议新会话第七轮 `/design-review design/gdd/rng-system.md`（本会话 context 已满）。

---

## Review — 2026-08-25 — Verdict: APPROVED

**Scope signal**: L（revision scope S 端）
**Review depth**: full
**Specialists**: 跨文档核验员、game-designer、godot-specialist、performance-analyst、systems-designer、qa-lead + creative-director（终审 + 修订后复核）
**Blocking items**: 1（BL-七-1，全修订闭环）| **Recommended**: 16（P0-P6，全修订闭环）
**Prior verdict resolved**: 六审 NEEDS REVISION（5 项 BL-6..BL-10 + 4 RECOMMENDED 全闭环无回归）

**Summary**: 七审为收敛评审。六审 5 项 + 4 RECOMMENDED 全闭环无回归（6 specialist 独立核实 + 六审末"下一轮复审焦点"5 项一致性全通过）。本轮新发现 1 项 BLOCKING（BL-七-1）+ 16 项 RECOMMENDED，全为 spec/testability/hedge/对齐 修复——零新公式/零新 ADR/零设计意图变更。BL-七-1 为 BL-2 类型可测试性残留（R5 未暴露 `get_fault_reason` 致 R6/R7/AC-E1c"fault_reason 不变"声明 testability 悬空），采纳选项 A：R5 新增 `get_fault_reason(stream_id) -> FaultReason` + 补齐 8 公共 API + `FaultReason` enum（值集对应 R8 触发条件分类，first-failure-wins，具体命名归实现，流未 FAULTED 返回 NONE），AC-E1c 验证改用该 API 闭合。16 项 RECOMMENDED 按 P0-P6 分组闭合。**修订后 creative-director 复核 APPROVED**：17 项逐项闭合 + 无回归（FaultReason↔R8 触发条件、get_fault_reason↔first-failure-wins、get_fault_reason↔has_fault↔NONE、RNG-EC 消歧无遗漏、COW 三分支↔GATE-G4 hedge 五项交叉自洽核验通过）。GATE-G2/3/4 + OQ1/3/6 确认为实现前置 gate，不阻止设计签发。RNG System 正式签发 Approved。

### 1 项 BLOCKING

1. **[BL-七-1·qa-lead, CD 引 BL-2 先例裁决] fault_reason 不可测** — R5 API 面仅列 3 roll 方法 + stream_id，但 R6/R7/R8/AC-E1c/AC-F3/AC-H1/H1b 实际使用 `has_fault()`/`has_fault(stream_id)`/`get_stream_state`/`set_stream_state`——全部缺失（R-七-4）；更关键：R6"fault_reason 已存在不变"+ AC-E1c"断言 fault_reason 不变"声明 testability 悬空（无 API 观测 fault_reason，BL-2 类型残留）。**采纳选项 A**：R5 新增 `get_fault_reason(stream_id) -> FaultReason`（闭合 testability + 服务承诺②"故障诚实暴露" + game-root R9 差异化 messaging）+ 补齐 8 公共 API + `FaultReason` enum（值集对应 R8 触发条件分类，first-failure-wins，流未 FAULTED 返回 NONE）。AC-E1c 验证改用 `get_fault_reason`（注入 fault A→reason_A；再注入 B→断言仍 reason_A）。R6/R7 声明注"可由 get_fault_reason 观测"。R-七-6 移除 AC-E1c 冗余"不产生新 roll 值推进"。

### 16 项 RECOMMENDED（P0-P6，全修订闭环）

- **P0**: R-七-4（R5 API 面补齐 8 公共 API，与 BL-七-1 单一连贯编辑）；R-七-6（AC-E1c 移除冗余"不产生新 roll 值推进"）。
- **P1**: R-七-3 + godot R-1 + systems NH-2（GATE-G4 Then 解阻清单补 EC8 seed= + AC-H1 state 往返，与 Given 断言清单一一对应；OQ3 scope 加 (f) seed= 处理）。
- **P2**: R-七-1（AC-A1c"逐值相异"→"非完全恒等(至少一位置相异)"）；R-七-2（AC-H1"fresh 序列"明示=同实例重新 set_stream_state(s) 后消费序列）。
- **P3**: cross-doc R-1（RNG-EC11/EC12 消歧，7 处引用全前缀 RNG-，Edge Case 11/12 标题加标注）；cross-doc R-2（R7 telemetry schema 对齐归 GATE-G3，本轮注 deferred）。
- **P4**: perf R-1（R4+F4 禁局部别名扩展覆盖函数参数传递 `helper(self.scratch_buffer)`）；perf R-2（R7 first-failure 快照存储容器明示预分配 `PackedInt64Array[8]`）；perf R-3（AC-B1 manifest 验证方式明示运行时 instrumentation 各流 roll 计数>0）；perf R-4（AC-B1 COW INCONCLUSIVE 三分支：harness bug/COW 不触发/技术不可观测）；R-七-5（COW lint 扩展覆盖显式别名/隐式类型/函数参数/方法返回值四模式）。
- **P5**: systems R-1（F3 `randf()` 输出域 [0,1) hedge defer rng-math.md/OQ3/GATE-G4）。
- **P6**: game-designer R-1（行 29"可追溯 seed"标注 dev/QA 侧能力）；game-designer R-2（行 35"诚实性"拆"故障被显式暴露且可复现诊断"，前者挂 GATE-G3 后者挂 AC-G2）。

### 修订闭环落点

| ID | 修复落点 | 验证 |
|----|---------|------|
| **BL-七-1 / R-七-4** | R5 API 面(L67-74) 补齐 8 公共 API 含新增 `get_fault_reason(stream_id)->FaultReason` + `FaultReason` enum 契约；AC-E1c 验证(L365) 改用 `get_fault_reason` 闭合；R6(L78)+R7(L84) 声明注"可由 R5 get_fault_reason 观测，AC-E1c 闭合 testability" | CD 复核：FaultReason↔R8 触发条件一致 + get_fault_reason↔first-failure-wins↔has_fault↔NONE 三者逻辑等价 |
| **R-七-6** | AC-E1c 验证(L365) 移除冗余"不产生新 roll 值推进" | 验证节聚焦三断言 |
| **P1** | GATE-G4 Then(L421) 解阻清单补 EC8 + AC-H1；OQ3(L446) scope 加 (f) seed=0 setter 特殊处理 | Given 断言清单与 Then 解阻清单一一对应 |
| **P2** | AC-A1c(L278)"逐值相异"→"非完全恒等"；AC-H1(L429)"fresh 序列"显式定义 | 措辞精确化 |
| **P3** | RNG-EC11/EC12 消歧（7 处引用 + 2 标题）；R7 telemetry(L94) 注 deferred GATE-G3 | grep 确认无裸 EC11/EC12 残留 |
| **P4** | R4(L64)+F4(L179) 禁局部别名扩展函数参数；R7(L92) 快照容器 `PackedInt64Array[8]`；AC-B1(L310) manifest 验证 + (L312) INCONCLUSIVE 三分支 + lint 四模式 | 零分配边界闭合 |
| **P5** | F3(L161) `randf()` 输出域 hedge | 与 F2/R3 hedge 体例一致 |
| **P6** | Player Fantasy 行29 dev/QA 标注 + 行35 拆"显式暴露且可复现诊断" | 玩家面/dev 面拆分清晰 |

**复核确认**：1 项 BLOCKING + 16 项 RECOMMENDED 全为 spec/testability/hedge/对齐 修复——**零新公式、零新 ADR、零设计意图变更**、0 新 AC（AC-E1c 改用 get_fault_reason 验证，非新 AC）、0 新 GATE。文档头部 Status/Last Updated/Review Mode/Creative Director Verdict/Specialist 注记均已同步反映七审 APPROVED。

**CD 修订后复核 APPROVED**：creative-director 独立复核 17 项逐项闭合 + 无回归（FaultReason↔R8 触发条件、get_fault_reason↔first-failure-wins、get_fault_reason↔has_fault↔NONE、RNG-EC 消歧无遗漏、COW 三分支↔GATE-G4 hedge 五项交叉自洽核验通过）。GATE-G2/3/4 + OQ1/3/6 确认为实现前置 gate，不阻止设计签发。

**仍 OPEN（合理推迟，实现前置 gate）**：OQ1 derive 算法 ADR / OQ2 max_weights 下游 / OQ3 rng-math.md（含 (a)-(f) 核验项）/ OQ4 run_seed 来源 / OQ5 stream_id 终态 / OQ6 oracle 捕获；跨文档 gate GATE-G2(Config run_seed) + GATE-G3(game-root has_fault) 仍 BLOCKED until 对端更新；GATE-G4(rng-math.md 存在性) BLOCKING before sign-off（实现前置，不阻止设计签发）。

**签发判定**：RNG System GDD 正式签发 **Approved**。可进入实现前置 gate 解阻阶段（Config 补 run_seed / game-root 补 has_fault 检查义务 / rng-math.md 创建核验）。下一系统设计 EnemySystem(#9)。
