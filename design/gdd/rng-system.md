# RNG System（随机种子与序列）

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: Re-review Pending — RNG core维持冻结；已同步第七轮OLD/NEW scratch reconcile，随中央契约待第八轮复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-24
> **Last Updated**: 2026-09-08（Zhangtian pre-active scratch OLD/NEW reconcile传播；runtime evidence仍OPEN）
> **Implements Pillar**: 稳定性硬约束（确定性/可复现是其根基）+ 肉鸽选择（随机性是重玩价值来源，但必须可控可复现）
> **Scope**: MVP — 单线程主 physics tick 内的确定性随机；不含赌场式反作弊、网络同步随机或跨线程并发
> **Review Mode**: full（首轮 design-review 6 specialist 对抗评审 + creative-director 终审，修订闭合 10 项 A 级 blocker；复审同 6 specialist + creative-director 终审，修订闭合 4 项新 BLOCKING；三审同 6 specialist + creative-director 终审，修订闭合 4 项新 BLOCKING；四审同 6 specialist + creative-director 终审，修订闭合 6 项新 BLOCKING + 3 项 RECOMMENDED；五审同 6 specialist + creative-director 终审，修订闭合 5 项新 BLOCKING（BL-1..BL-5）+ 22 项 RECOMMENDED；六审同 6 specialist + creative-director 终审，修订闭合 5 项新 BLOCKING（BL-6 减法溢出 / BL-7 COW-on-write / BL-8 AC-E1c 矛盾 / BL-9 set_state re-seed / BL-10 R8→R9）+ 若干同区域 RECOMMENDED；七审（re-review 6）同 6 specialist + creative-director 终审，发现 1 项 BLOCKING（BL-七-1 fault_reason testability 悬空）+ 16 项 RECOMMENDED（P0-P6），修订闭环转 Approved）
> **Creative Director Verdict**: NEEDS REVISION → 修订闭环 — 首轮 10 项 + 复审 4 项 + 三审 4 项 BLOCKING（BL-E/F/G/H）+ 四审 6 项 BLOCKING（BL-I/J/K/L/M/N）+ 3 项 RECOMMENDED + 五审 5 项 BLOCKING（BL-1..BL-5）+ 22 项 RECOMMENDED + 六审 5 项 BLOCKING（BL-6..BL-10）+ 若干同区域 RECOMMENDED + 七审 1 项 BLOCKING（BL-七-1）+ 16 项 RECOMMENDED（P0-P6）同为 spec/testability/hedge/对齐 修复非重设计，设计意图自洽；七审修订闭环，CD 终审 APPROVED（GATE-G2/3/4 + OQ1/3/6 实现前置 gate deferred 不阻止设计签发）
> **Specialist 委托注记**: full review 委托 systems-designer（公式边界值）+ qa-lead（AC 可测性）+ game-designer（player fantasy）+ godot-specialist（Godot 4.7.1 确定性核验）+ performance-analyst（零分配 perf）+ 跨文档核验员。原 lean 模式 deferred 的 D/H specialist 项已全部覆盖。复审（re-review）同 6 specialist + creative-director 终审，发现 4 项新 BLOCKING（BL-A 零分配 PackedInt32Array 盲区 / BL-B F4 Σw 上界 fault / BL-C fault gen-state invariant 未测 / BL-D game-root has_fault 单向依赖→GATE-G3），全为 spec/citation/enforcement 修复，已修订闭环。四审（re-review 3）同 6 specialist + creative-director 终审，发现 6 项新 BLOCKING（BL-I PackedInt64Array 未进 AC-B1 positive control + element-write 禁局部别名未约束 / BL-J AC-E1 fault-injection 缺 W-1>2^31-1 触发 / BL-K AC-A1a/A1b instrumentation 无 positive control 前三轮盲区 / BL-L randi_range 参数类型 int32 假定未核验 / BL-M 拒绝采样假定未核验 + AC-D2 边界待核验 / BL-N FAULTED 终态未声明 + set_stream_state 在 FAULTED 下未约束违承诺②）+ 3 项 RECOMMENDED（GATE-G4 rng-math.md 存在性守卫 / F3 !isfinite(max-min) / 承诺②交叉引用 GATE-G3），全为 spec/citation/enforcement/可测性修复，已修订闭环。五审（re-review 4）同 6 specialist + creative-director 终审，发现 5 项新 BLOCKING（BL-1 `randi_range`/`randf`/`randi` 零分配是假设而非验证违 GATE-G4 / BL-2 FAULTED 终态两条行为无 AC 闭合四审 BL-N 声明-only 未 testability-闭环 / BL-3 AC-E1 Gate 字段与 body 不一致 + 可测内核被捆绑 / BL-4 F2 缺范围上限守卫与 F4 W_MAX_SAFE 不对称 + fallback hang / BL-5 derive GDScript int64 算术移位陷阱未标注）+ 22 项 RECOMMENDED，全为 spec/AC/hedge/testability/boundary-parity 修复——零新公式、零新 ADR（derive 陷阱归既有 OQ1）、零设计意图变更，已修订闭环。六审（re-review 5）同 6 specialist + creative-director 终审，发现 5 项新 BLOCKING（BL-6 F2 fault guard `max-min` 减法溢出可绕过守卫 / BL-7 R4 COW-on-write 与 F4 触发为 Godot 4.7.1 行为断言未 hedge 致 AC-B1 方法论循环失效 / BL-8 AC-E1c "返回 FAULTED 标志不变"与 AC-E1b+R7 三者矛盾回归 / BL-9 R7 set_state 不 re-seed 为 Godot 4.7.1 行为断言未 hedge 致 SaveSystem 跨实例静默腐化 / BL-10 caveat 误引 R8 应为 R9 ControlledGameplayFault 域）+ 若干同区域 RECOMMENDED（QA-2 has_fault 显式断言 / GS-5 GATE-G4 Then 解阻清单 / GS-12 OQ3 源文件 hedging / GD-4 has_fault per-stream/global 双重形式澄清），全为 hedge/citation/testability/对齐 修复——零新公式、零新 ADR（减法溢出+COW+set_state 三项 Godot 4.7.1 行为断言均归既有 OQ3 rng-math.md 核验 + OQ1 ADR）、零设计意图变更，已修订闭环。七审（re-review 6）同 6 specialist + creative-director 终审，发现 1 项 BLOCKING（BL-七-1 R5 未暴露 `get_fault_reason` 致 R6/R7/AC-E1c"fault_reason 不变"声明 testability 悬空）+ 16 项 RECOMMENDED（P0-P6：R5 API 面补齐 8 公共 API 含新增 `get_fault_reason`→`FaultReason` enum / GATE-G4 Then + OQ3 scope 补 EC8 seed= + AC-H1 state 往返核验 / AC-A1c"逐值相异"→"非完全恒等" + AC-H1"fresh 序列"明示 / RNG-EC11-EC12 消歧 + R7 telemetry schema deferred GATE-G3 / R4+F4 禁局部别名扩展函数参数 + R7 first-failure 快照容器 `PackedInt64Array[8]` + AC-B1 manifest 验证+INCONCLUSIVE 三分支+lint 多模式 / F3 randf 输出域 hedge / Player Fantasy 行29 dev 标注+行35 拆"显式暴露且可复现诊断"），全为 spec/testability/hedge/对齐 修复——零新公式、零新 ADR、零设计意图变更，已修订闭环。CD 终审判定转 Approved（GATE-G2/3/4 + OQ1/3/6 为实现前置 gate，前向依赖须 RNG 先 Approved 下游才能引用，不阻止设计签发）。

## Overview

RNG System 是单场战斗中唯一的权威随机源。它从 Config 战斗快照提供的 per-run seed 派生出**独立、可复现的随机流**，服务每个消费子系统（怪潮生成、升级三选一候选池与刷新、暴击判定、掉落权重、雷爆符随机敌人、法宝匣随机提升、夺宝机缘、掌天瓶种子），并通过零分配 API 在 GameRoot physics tick 内消费。它保证三条不变量：

1. **确定性**——相同 run seed + 相同有序调用序列跨运行产生相同结果，支撑 game-root AC-F4 可复现诊断与 MVP「每局生成随机种子，便于复现问题」要求；
2. **流隔离**——任一消费方的调用次数不偏移其他消费方结果，故任一子系统的结果可独立于其他子系统重放；
3. **无 OS 熵**——gameplay stream 禁止调用 `randomize()`，不得引入墙钟/熵源。

本系统不拥有玩法数值（暴击率、掉落权重、候选池规则）——这些归各下游 GDD；RNG 只提供 roll API 与 seed/stream 契约。玩家从不直接感知 RNG 本身，只感知它启用的重玩多样性与"故障可复现而非被掩盖"的诚实性。本系统无上游依赖；下游为 SpawnDirector、SkillDraftSystem、Zhangtian Bottle 及隐式消费方（DamageSystem/DropSystem/雷爆符/法宝匣/夺宝机缘）。

## Player Fantasy

### 玩家面（玩家直接感知）

玩家应感觉 RNG 本身"不存在"——它理想的表现是无感。玩家只感受它启用的两件事：其一是每局不同的怪潮节奏、掉落与三选一候选，让"再来一局"始终新鲜而不重复；其二是当某局出现异常时，玩家可以信任这是一个会被显式暴露、而非被静默重摇或掩盖的异常（而非随机黑箱）。此承诺②（故障诚实暴露）的兑现依赖 **GATE-G3**（game-root phase 边界 `has_fault()` 检查义务）+ 各消费方采纳 phase-staging（见 R8 零值守卫 + 跨文档块 bidirectional flag）；两者均 BLOCKED until 对端更新。

玩家绝不应感到随机性在"针对自己"或"被掩盖"。RNG 的诚实性体现在：所有随机结果都可追溯到一个明确 seed（此可追溯性为 dev/QA 侧能力，玩家不直接感知 seed——见 dev 面；玩家面感知的是"不被针对/不掩盖"的信任），没有任何隐藏熵源在背后偷偷扰动；一次抽签就是一次抽签，不会被静默重摇来"讨好"或"刁难"玩家。

### dev 面（非玩家感知，单独说明）

"凭种子精确复现那一局并定位问题"是 dev/QA 的工作流能力，玩家不持有 seed、不复现 bug——此收益对玩家是间接的（通过版本更新看到 bug 被修）。复现诊断契约（run_seed + 调用计数 + first-failure state 入 telemetry）服务 dev 而非玩家感知，归本节以与玩家面区分，避免下游误读为"须向玩家暴露 seed"。

> **caveat**：RNG 的诚实性限于"故障被显式暴露且可复现诊断"（前者=phase 边界 ControlledGameplayFault 屏，GATE-G3；后者=telemetry run_seed+调用计数+first-failure state，AC-G2），不承诺"故障后玩家无损"——后者（reservation/commit 补偿、中途存档恢复）属 game-root R9 SaveSystem 域，非 RNG 职责。
> **caveat（承诺② 罕见性前提）**：故障诚实暴露的前提是故障**罕见**——RNG/R4/R8 fault 应仅触发于契约违规或实现 bug，非正常 gameplay。若故障频繁发生，"诚实暴露"对玩家为负体验（说明版本有严重缺陷须修），非 RNG 设计目标；本系统不制造故障，只保证故障不被静默掩盖。
> **caveat（承诺② 暴露形态）**：故障暴露的玩家面形态——显式 ControlledGameplayFault 屏（可控的故障态而非崩溃/静默吞）——见 game-root R9 ControlledGameplayFault 玩家与持久化域（BL-10/GD-1 修正：原误引 R8——R8 为正常 teardown 顺序，R9 才是 ControlledGameplayFault 玩家面形态/TECHNICAL_ABORT/reservation-commit 域；与行 35 "属 game-root R9 SaveSystem 域" 对齐），非 RNG 定义；RNG 仅保证 fault 被 latch 且 `has_fault()` 可检（GATE-G3 依赖 game-root 落地捕获）。

这契合本项目"无感基础设施"哲学（与 SpatialGrid / Object Pooling 一致），并直接服务稳定性 pillar（确定性 / 可复现）与肉鸽 pillar（可控随机性带来重玩价值）。

## Detailed Rules

### R1 — 唯一权威与无 OS 熵

- RNG System 是单场战斗中唯一的随机源。任何 gameplay 代码不得直接调用 Godot 全局 `randi()`/`randf()`/`randi_range()`/`randf_range()`（用未播种全局 RNG，不可复现），也不得调用 `RandomNumberGenerator.randomize()`（引入 OS 熵）。
- 唯一允许接触 OS 熵的时刻是 `run_seed` 的**建立**：在 PREP/run-start，seed 被生成并记录入不可变 Config 战斗快照。seed 本身可以是 OS 随机（这是记录的起点，合理），但一旦入快照，所有下游派生与调用均确定。
- dev 构建可强制固定 `run_seed` 用于复现；release 由 run-start 生成。强制 seed 是 dev-only tunable，不构成 gameplay 路径。

### R2 — 流隔离与派生

- 每个消费子系统获得一个独立流，由 `stream_seed = derive(run_seed, stream_id)` 派生。`stream_id` 是固定 primitive enum（如 `SPAWN`、`SKILL_DRAFT`、`CRIT`、`DROP`、`LEI_TARGET`、`TREASURE_BOX`、`RISK_CHOICE`、`ZHANGTIAN_HERB`）。`derive` 是文档化的确定性混合函数——具体算法归 `/architecture-decision`，不在 GDD 越权定义。
- 一个流的调用次数与顺序不影响任何其他流的结果。故 SpawnDirector 多调一次 roll 不改变 SkillDraft 候选。
- 流内调用顺序**有影响**（这是确定的、文档化的）：同一流内第 N 次 roll 依赖前 N-1 次。消费方须按稳定顺序调用其流以保可复现（此稳定性是复现的前提，见 R7 telemetry）。

### R3 — 确定性契约

- 契约：`same (run_seed, stream_id, ordered call sequence) → identical result sequence`，跨运行、跨同架构同 Godot 版本一致。
- 确定性是**逐流**的：流内调用顺序是该流调用序列的一部分；**telemetry 记录每流调用计数（per-stream int counter，零分配原地 ++），非 per-roll 明细**——复现依赖 `(run_seed, 调用计数, R2 调用顺序稳定性, 重跑确定代码版本)`，不依赖 per-roll trace（后者会违反 R4 零分配，见 R7）。
- 跨架构（x86 vs ARM）浮点一致性是已知风险，**F3 实现路径为 GDScript 层表达式 `min + gen.randf() * (max - min)`（见 F3），非 Godot 引擎方法 `RandomNumberGenerator.randf_range()`——二者 FMA 行为不同**：引擎方法为单 C++ 表达式可被 `-ffp-contract=fast` 收缩；GDScript 层表达式编译为多 opcode（MULTIPLY→ADD），跨 opcode 是否收缩取决于 GDScript VM 实现。**FMA 漂移是否存在（两路径）均为待核验假设，defer 至 rng-math.md（OQ3）核验 GDScript VM opcode 收缩行为与引擎方法 `-ffp-contract` 行为后再冻结漂移源**——当前不应作为已验证结论。`randf()` 本身（除以 2 的幂）很可能跨架构精确（亦待核验）。整数域 roll（`roll_int_range` / 定点 weighted_pick）不碰浮点算术。gameplay 关键路径（weighted_pick）已默认走整数域（见 F4）；剩余浮点消费方若依赖跨架构确定性，须在 AC-A5 验证，若 rng-math.md 核验存在漂移则迁移该关键路径至整数域 roll 再映射。此项标 OPEN（见 AC-A4/A5 与 Open Questions）。

### R4 — 零分配

- 所有权威生成器在 BATTLE_LOADING 预实例化（每流一个 `RandomNumberGenerator`），另为`SKILL_DRAFT`预实例化唯一scratch generator供pre-active window使用，复用到 BATTLE_ENDING；physics tick与window begin/roll/commit/discard内禁止 `RandomNumberGenerator.new()`。
- roll 方法返回 primitive（int）；`roll_weighted_pick` 返回 index（消费方拥有 weights 数组，RNG 不分配新数组）；累积写入 RNG 持有的该流预分配 PackedInt64Array scratch buffer（F4，BL-I）。禁止 boxing、Dictionary、运行时 StringName、`Array` 与 `Packed*Array`（含 `range()` 返回的 PackedInt32Array、F4 scratch 的 `PackedInt64Array`）构造出现在 roll 路径——消费方与 RNG 内部累积循环均须用 `var i:=0; while i<count` 原位迭代（对齐 spatial-grid AC-J3）；PackedInt64Array scratch 的 element-write 须直接通过 `self.scratch_buffer[i]`，禁局部别名（含函数参数传递路径，如 `helper(self.scratch_buffer)` 内部写入——参数绑定亦使 refcount→2 触发 COW 堆分配，违 R4，见 F4——COW-on-write 触发为 Godot 4.7.1 行为断言待核验 defer rng-math.md/OQ3/GATE-G4，BL-7/GS-4）。**零分配覆盖边界（BL-1，待核验 defer OQ3/rng-math.md）**：上述禁列与 AC-B1 positive control 仅覆盖 **GDScript 侧**构造（boxing/Array/Packed*/Dictionary/StringName）；`gen.randi_range()`/`randf()`/`randi()` 等 Godot **native method 内部**是否分配未经源码核验（positive control 只证能抓 GDScript 侧分配，**不证能抓 C++ 侧 native-method 内部分配**）——若 native method 内部分配，R4 零分配静默崩塌且无 AC 报警（违 fail-fast pillar）。零分配源码核验进 OQ3/rng-math.md scope。另禁原生 String 构造（`str()`/`%`/`+`/`String.num_*` 等 native method 返回 String 的路径）出现在 roll 路径。
- 流句柄 `stream_id` 是 primitive enum，非引用对象——消费方不持生成器实例引用，避免 RefCounted 泄漏。对齐 object-pooling R3（分配源清单）+ game-root AC-F2 零增长。

### R5 — API 面

- `roll_int_range(stream_id, min, max) -> int`：闭区间 [min, max] 均匀整数。
- `roll_float_range(stream_id, min, max) -> float`：[min, max) 均匀浮点。
- `roll_weighted_pick(stream_id, weights: PackedInt32Array) -> int`：按定点整数权重选 index（消费方拥有数组；空数组、`Σw ≤ 0`、含负权重、`len > 声明 max` → 触发 R8 fault）。定点 scale factor K（消费方 authoring/load 时 ×K 缩放）归 ADR。
- `has_fault() -> bool`：无参形式，任一流 FAULTED 即 true（GameRoot 级 phase 边界检查用，R8/GATE-G3）。
- `has_fault(stream_id) -> bool`：逐流形式，该流是否 FAULTED（AC-E1c 逐流观测用；R6 逐流 FAULTED 终态 + R8 GameRoot 级全局检查共存，非二选一，GD-4）。
- `get_stream_state(stream_id) -> int`：取流内部 state（PCG 原始 uint64，R7；往返性见 AC-H1，跨实例可移植性见 AC-H1b）。
- `set_stream_state(stream_id, state)`：存流内部 state（R7；仅 READY 态可调，FAULTED 下→R8 fault，R7 前置）。
- `get_fault_reason(stream_id) -> FaultReason`：返回该流 first-failure 的 fault 类型（BL-七-1，闭合 R6"fault_reason 不变"声明 testability——AC-E1c 通过此 API 观测 fault_reason 不被后续 fault 覆盖；服务承诺②"故障诚实暴露"+ game-root R9 差异化 messaging）。`FaultReason` 为 enum，值集对应 R8 fault 触发条件分类（具体命名归实现，契约：不同触发条件→不同值，first-failure-wins 不可变见 R6/AC-E1c）；流未 FAULTED 时返回 `NONE`。
- pre-active专用window API固定为`begin_pre_active_window(stream_id=SKILL_DRAFT,expected_state,window_id)->int`、既有`roll_*`在window open期间只路由到预分配scratch、`get_pre_active_window_state(window_id)->int`、`commit_pre_active_window(window_id,expected_next_state)->int`与`discard_pre_active_window(window_id)->int`。同一时刻最多1个window；begin先逐位复制权威state到scratch且不改权威cursor，只有matching recovery已由Save双镜像readback后才允许commit一次将scratch state发布为权威。FAILED必须discard后返回且旧state逐位不变；UNCERTAIN保持window冻结并禁止新roll，直到Save的typed update reconcile把selected formal reservation hash与expected old/requested next逐位比较：`RECONCILE_FOUND`且hash=next才commit，`RECONCILE_FOUND_OLD`且hash=old才discard并继续同一reservation，`RECONCILE_NOT_FOUND_UNPROVEN`继续冻结。全reservation `PROVEN_ABSENT`不用于既有reservation上的UPDATE_RECOVERY。wrong stream/ID/state、并发window、重复或顺序错误均R8 fault；normal Active不得调用该API。
- 不提供 `roll_gaussian` 与 `roll_shuffle_in_place`（MVP 无消费方；前者无高斯消费方，后者因 Godot 4 `Array`/`Packed*` 的 COW 语义使 Fisher-Yates 原地写触发 `_copy_on_write()` 堆分配、无法满足 R4 零分配——待下游消费方出现时由 ADR 定义零分配洗牌方案，如 RNG 持预分配 index buffer 返回 index 序列或 PackedArray `ptr()` 写路径）。新增任一 API 须经 AC 批准。
- 不暴露原始 `RandomNumberGenerator` 实例；消费方只通过上述 API + `stream_id` 消费。

### R6 — 生命周期、归属与状态

- RNG System 是 battle-scope 服务 participant（不跑独立 physics phase，由其他 participant 在各自 phase 内调用其 API），由 GameRoot 在 BATTLE_LOADING 拥有与初始化，从 Config 快照 `run_seed` 派生全部 `stream_seed` 并实例化生成器。
- 状态机：`UNINIT` →（BATTLE_LOADING 派生+实例化）→ `READY` →（非法参数 R8）→ `FAULTED`；`BATTLE_ENDING` teardown 全部释放。新 battle = 新 run_seed，不继承流状态。**FAULTED 为终态**——一旦 latch，该流不可再调 roll（后续 roll 调用须 R8 fault，fault_reason 已存在不变（可由 R5 `get_fault_reason` 观测，first-failure-wins，AC-E1c 闭合 testability，BL-七-1），保持 FAULTED），仅可转 BATTLE_ENDING teardown；须 teardown 后新 battle 重新初始化，不残留 FAULTED 流（BL-N，违承诺②"不被静默重摇"——FAULTED 流不允许任何路径复活）。
- 消费方在 battle load 时按固定表注册其 `stream_id`，Active 后不可增删（对齐 game-root R1 participant 注册原则）。
- dispatch（stream_id → gen）首选 **int-indexed Array**（stream_id enum → int 索引，零 lookup 分配）；若用 `Dictionary[StringName]`，key 须为**编译期 StringName 字面量**（运行时构造 StringName = 分配）；禁止 `Dictionary[String]`（每 lookup 构造 String = 分配）。

### R7 — 状态取存与 pause/resume

- **前置（BL-N）**：仅 `READY` 态可调 `set_stream_state`；`FAULTED` 下调用→R8 fault（fault_reason 已存在不变（可由 R5 `get_fault_reason` 观测，first-failure-wins，AC-E1c 闭合 testability，BL-七-1），保持 FAULTED 终态；违承诺②"不被静默重摇"——FAULTED 流不允许通过改写 state 复活）。
- 暴露 `get_stream_state(stream_id) -> int` 与 `set_stream_state(stream_id, state)`：取/存内部 state（PCG 原始 uint64，`set_state(v); get_state() == v` 可往返，不重置到 seed——**"不重置到 seed" 为 Godot 4.7.1 行为断言待核验** defer rng-math.md/OQ3/GATE-G4：set_state 内部是否隐式 re-seed 未核验，若 re-seed 则 SaveSystem 跨实例语义破坏；AC-H1 同实例 round-trip 不覆盖此——一个 set_state 内部隐式 re-seed 的实现能通过 AC-H1 却破坏 SaveSystem 跨实例存档/恢复语义，故补 AC-H1b 跨实例可移植性），供 telemetry 与未来 SaveSystem 中途存档。state 往返性见 AC-H1，跨实例可移植性见 AC-H1b。
- pause/resume：BATTLE_PAUSED 冻结 gameplay，流状态随 gameplay 一并冻结于内存，RESUME 不调用 state API——流本就在内存，resume 后继续消费即可。
- 复现只依赖 `(run_seed, 已记录调用计数, R2 调用顺序稳定性)`，不依赖内存 state。`save-system.md`已明确MVP不支持战斗中途存档，因此不持久化RNG runtime state；未来若扩展mid-run save，必须先新立Save/RNG schema与跨实例state证据，不能复用当前终局存档合同。
- **telemetry sidecar（每局至多写一次）**：GameRoot 在 BATTLE_LOADING 预分配 versioned `RngFaultTelemetrySnapshot`，schema 精确为 `{diagnostic_id,battle_instance_id,config_snapshot_id,run_seed,stream_count,stream_ids[8],call_counts[8],pre_fault_states[8],fault_stream_id,fault_reason}`。`call_counts` 为 per-battle 累计 int counter；`pre_fault_states` 是 faulting roll draw 前各流 state；`diagnostic_id` 与 `FailureDiagnosticBank.first` 关联。RNG fault 时，GameRoot 必须在 RNG teardown 前、first failure capture 的同一 cleanup transaction 中恰写一次；无 RNG fault 时 `stream_count=0`。热路径不得创建 Dictionary/String/Array，也不得把 sidecar 字段塞进通用 first-failure row。
- 本 sidecar 支持从故障点恢复重放；从 run 起点的 full replay 由 AC-A1 确定性 + 独立调用序列 instrumentation（测试构建路径，非 telemetry 职责）+ R2 调用顺序稳定性支持。schema 对齐归 GATE-G3；设计侧闭合，runtime evidence OPEN。

### R8 — 非法参数与 fault

- roll 方法在参数合法时**永不失败**，总返回值。
- 非法参数（`min > max`、空/全零/含负权重、`len(weights) > 声明 max`、非有限浮点（仅 `roll_float_range`：`!isfinite(min)||!isfinite(max)`；int_range 的 min/max 与 weighted_pick 的 W 均为 int 无 inf/NaN，见 F2/F4）等）是契约违规：该次 roll 返回定义的零值（int→0 / float→0.0 / pick→0），但 RNG System **立即 latch `fault_reason`（在任何 gen draw 前——fault 路径不推进 gen state，故 `get_stream_state` 在 faulting roll 前后恒等；此 invariant 由 AC-E1b state-diff 测试覆盖）**；GameRoot 在当前 phase 边界检查 `has_fault()`（**无参形式 = 任一流 FAULTED 即 true，GameRoot 级 phase 边界检查用；另有逐流形式 `has_fault(stream_id)` = 该流是否 FAULTED，AC-E1c 逐流观测用——GD-4 澄清：R6 逐流 FAULTED 终态 + R8 GameRoot 级全局检查共存，非二选一**），按 fail-fast 进入 ControlledGameplayFault。
- **零值消费窗口（契约约束）**：消费方在调用 roll 后、使用返回值前**须检查 `has_fault()`**——**默认由 GameRoot wrap roll 调用集中检查**（强制，非可选；game-root 须在 phase 边界检 `has_fault()`，见 GATE-G3），消费方 `has_fault()` 守卫为二级防御。fault 返回的零值（尤其 `weighted_pick` 返回 index 0）可能与合法高权重结果不可区分（如 `weights=[100,1,1]` 正常也返回 0），仅 fault latch 区分——故消费方不得在未检 `has_fault()` 前将返回值用于 gameplay 决策。phase 边界 abort 使 fault tick 的下游影响有界（committed gameplay state 不进入下一 phase，对齐 game-root R4/R5 phase 边界 fault 路径 single-exit cleanup → CONTROLLED_FAULT）；但**本 tick 内消费方若同步使用零值须由消费方守卫**。
- 因 tick 在 fault 后被 abort，零值不会进入下一 phase 的 committed gameplay state——fail-fast 不被掩盖。这与 spatial-grid / game-root 的 fail-fast 哲学一致：错误暴露，非关键系统不掩盖契约违规。

### R9 — 确定性危害清单（禁止项）

- 禁止调用 `randomize()`、全局 `randi()/randf()/randi_range()/randf_range()`、`Time.get_ticks_*`/`OS.*` 时间作种子或随机源（除 R1 的 `run_seed` 建立时刻）。
- 禁止依赖消费方调用**时机**（墙钟）——流内结果只依赖有序调用序列，不依赖"何时"调用。
- 禁止跨流借数：**未知/未注册 `stream_id`（不在固定 8 项 enum 集）→ R8 fault**。注：per-consumer 归属校验（如 SpawnDirector 误调 CRIT）当前 API 无 caller 身份参数无法运行时检测，改为**静态分析/lint** 检测；运行时仅校验 stream_id 属固定 enum 集（与 RNG-EC11 同路径）。
- 禁止在 roll 路径上 `new` 生成器或构造 Array/Dictionary/StringName 作中间值（R4）。
- 消费方不得在 roll 路径上引入 object-pooling R3 分配源清单列举的分配源（`call_deferred`/`create_tween`/signal connect-disconnect/`Array.clear()` boxing/Dictionary/StringName 构造等）。

## Formulas

### F1 — stream_seed 派生

`stream_seed = derive(run_seed, stream_id)`

**变量：**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| run_seed | s | int | 全 int 域（unsigned 64-bit 位模式，GDScript int 仅作载体） | Config 战斗快照提供的 per-run 种子（PREP 建立） |
| stream_id | k | int（enum 映射） | 固定枚举集 | 消费子系统标识（SPAWN/SKILL_DRAFT/...） |
| stream_seed | d | int | 全 int 域（unsigned 位模式传入 RandomNumberGenerator.seed） | 该流 RandomNumberGenerator.seed |

**Output Range:** 全 int 域；**`derive` 为确定性纯函数，零分配、零 OS 依赖、纯整数运算（无浮点中间值——否则 stream_seed 跨架构漂移使 AC-A4 整数域保证崩塌）**。**GDScript int64 陷阱（BL-5，待核验 defer OQ1 ADR；BL-6/SD-1 同类扩展覆盖 `-` 减法）**：GDScript `int` 为 64-bit **signed**，无原生 uint64；`>>` 对负值为**算术移位（符号扩展）**非逻辑右移，`*` 乘法溢出回绕无 documented contract，`-` 减法溢出回绕同样无 documented contract（F2 fault guard `max-min` 可溢出为负绕过守卫，见 F2 BL-6/SD-1）。splitmix64/PCG-DXSM 等依赖 uint64 **逻辑**右移的算法，naive 移植得错误结果——**静默破坏 derive 单射（AC-A3）+ 确定性（AC-A4）**，违 fail-fast pillar（同 BL-1 静默失败模式）。实现须用 32-bit 拆分 / 位掩码（`& 0xFFFFFFFF`）/ MagicMask 路径，或 GDExtension 原生 uint64——具体算法选择归 OQ1 ADR；F2 fault guard 的 overflow-safe 比较式同样归 OQ1 ADR + OQ3 核验 GDScript int64 `-` 减法 contract 后冻结，GDD 不越权定义。
**Example:** run_seed=0x1A2B3C, stream_id=SPAWN(=0) → derive=某确定 int；同输入跨运行恒等。
**契约：** 对固定 `run_seed`，`derive` 对 8 项 `stream_id` 集单射（per-run_seed 8-way 单射——8 个 stream_seed 两两相异）；碰撞概率须可忽略（ADR 给碰撞上界 ≤ 8/2^64），碰撞视为 fault 级异常，见 AC-A3。

### F2 — roll_int_range 分布

`result = gen.randi_range(min, max)`（委托 Godot 内置实现——**无偏性待核验** defer rng-math.md/OQ3，见实现注）

**变量：**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| min | a | int | — | 闭区间下界 |
| max | b | int | b ≥ a | 闭区间上界 |
| result | r | int | [a, b] | 均匀整数（无偏性待核验，见实现注） |

**实现：** 委托 `RandomNumberGenerator.randi_range(min, max)`（**Godot 内部实现待核验** defer rng-math.md/OQ3：训练数据表明 Godot ~4.3 用 simple modulo `randi()%range` 存在 modulo bias，**非**"内置无偏、拒绝采样"——此为作事实的未核验断言；rng-math.md 须核验 4.7.1 实际实现）。oracle = Godot 4.7.1 `randi_range` 输出快照（OQ6 规范捕获）。若 AC-A4 spike 发现 Godot `randi_range` 跨架构不稳定，或核验为 modulo 实现，回退为自研拒绝采样基于 `gen.randi()`（纯整数运算，可证跨架构一致），oracle 相应切换。
**Output Range:** [min, max] 闭区间，均匀（无偏性待核验，见实现注）。
**Example:** min=0, max=99 → 每个 int 期望概率 1/100（无偏性待核验，见实现注）。
**fault:** `min > max` → R8 fault；`max - min > RANGE_MAX_SAFE`（保守默认 2^31-1=INT32_MAX，对称 F4 `W_MAX_SAFE`——防 `gen.randi()` 返回 uint32（输出域 [0, 2^32-1]，**待核验** defer rng-math.md/OQ3）在 range>2^32 时输出域塌缩；更严重者 F2 回退自研拒绝采样 fallback 路径在 `range = 2^32+1` 时 `floor(2^32/range)=0`→空 unbiased range→**无限循环挂起**，违 fail-fast。保守值 2^31-1≪2^32 安全，值对称 F4，精确 bound 待 OQ3 核验 `randi()` 输出域后放宽）→ R8 fault。**减法溢出 bypass（BL-6/SD-1，BL-5 int64 陷阱同类，待核验 defer OQ3 rng-math.md/OQ1 ADR）**：`max - min` 在 GDScript int64 two's complement 下可溢出为负（min=INT64_MIN、max=0 → max-min 溢出为 INT64_MIN 负值 → `负值 > 2^31-1` 为 false → 守卫静默不触发 → `randi_range(INT64_MIN, 0)` 以 range=2^63 越界调用，输出域塌缩/hang，违 fail-fast）；BL-5 int64 陷阱 hedge 原仅覆盖 `*` 乘法与 `>>` 移位溢出，**未覆盖 `-` 减法溢出**（`-` overflow 回绕 contract 同样无 documented guarantee，同 silent-failure 模式）。实现须用 overflow-safe 比较式（不直接计算 `max-min`，如分段判定 / unsigned bit_cast，**具体形式归 OQ1 ADR + OQ3 核验 GDScript int64 减法 contract 后冻结**）；AC-E1/AC-E1b 须注入 `min=INT64_MIN,max=0` 与 `min=-1,max=INT64_MAX` 溢出 bypass 用例。
**Edge（M1）：** `range = max - min + 1` 在 min=INT_MIN/max=INT_MAX 全 int 域时**有符号溢出**——委托 Godot 时由其内部算术处理（**unsigned vs signed、modulo vs 拒绝采样均待核验** defer rng-math.md/OQ3；"unsigned 内部算术规避"与"拒绝采样"为未核验断言，见实现注）；若回退自研须用 unsigned bit_cast 或拒绝采样 fallback（**fallback 在 range>2^32 时 hang，由 RANGE_MAX_SAFE fault 守卫，见 fault 行**）。

### F3 — roll_float_range 分布

`result = min + gen.randf() * (max - min)`

**变量：**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| min | a | float | 有限 | 下界 |
| max | b | float | b ≥ a，有限 | 上界 |
| result | r | float | [a, b) | 均匀浮点 |

**Output Range:** [min, max) 半开区间，均匀（`randf` ∈ [0,1)——**`randf()` 输出域 [0,1) 为 Godot 行为断言待核验** defer rng-math.md/OQ3/GATE-G4）。
**Example:** min=0.0, max=1.0 → r ∈ [0,1)。
**fault:** `min > max` 或 `!isfinite(min)` 或 `!isfinite(max)` 或 `!isfinite(max - min)`（min/max 各自有限但量级极大时差值溢出 float64（GDScript `float`=double）为 +inf，后续 `randf()*inf` 产出 inf/NaN）→ R8 fault（IEEE NaN 比较恒 false，须显式 isfinite 检查，否则 NaN/INF 静默产出且 `has_fault()` 不触发）。
**Edge（M2）：** `min == max` 非 fault——返回 `min + randf()*0 = min`（恒定输出）。消费方笔误（如 `[5.0,5.0]`）会得常量；int_range 的 `min==max` 是合法单值区间，float_range 的 `min==max` 几乎必然是笔误，消费方自检。
**跨架构风险：** 见 R3——FMA 漂移源待核验（F3 为 GDScript 层表达式，与引擎方法 `randf_range` 的 FMA 行为不同，两路径均 defer 至 rng-math.md/OQ3 核验后再冻结）；weighted_pick 已整数域不受影响。

### F4 — roll_weighted_pick 归一（定点整数域）

`result = pick_index_by_cumulative_int(gen, weights)`

**变量：**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| weights | w | PackedInt32Array | n≥1, w_i ≥ 0, Σw > 0 | 消费方拥有的定点整数权重数组（authoring/load 时 ×K 缩放） |
| Σw | W | int | 0 < W ≤ W_MAX_SAFE（保守默认 W-1 ≤ 2^31-1=INT32_MAX，**参数类型待核验** defer rng-math.md/OQ3（训练数据表明 Godot 4.x `randi_range` 参数为 int64 非假定的 int32；保守值安全，见 F4 fault）；保 `randi_range(0, W-1)` 输出域覆盖；超界→R8 fault。放宽至 W-1≤2^32-1 须 F2 回退自研拒绝采样基于 `gen.randi()` uint32，归 OQ3） | 整数权重和（int64 累积精确，无 IEEE inf/NaN；上界守卫防输出域塌缩+modulo bias（机制待核验，见 F4 fault）） |
| result | i | int | [0, n-1] | 选中 index |

**Output Range:** [0, n-1]，`P(i) = w_i / W`。
**机制：** 累积分布 `C_j = Σ_{t≤j} w_t`（int 累积，与 W 同精度——int 域天然一致），取 `u = roll_int_range(0, W-1)`（整数域，无 FMA、无 +inf），`result = min{ j : C_j > u }`。累积写入 RNG 持有的**该流预分配 PackedInt64Array scratch buffer**（int64 元素，与 int64 累积器同类型，C_j 不溢出；refcount=1 不触发 COW（**COW-on-write 触发堆分配为 Godot 4.7.1 行为断言待核验** defer rng-math.md/OQ3/GATE-G4：4.7 引入"packed array 元素不再触发整个 packed array 属性的 setter"相邻变更，4.7.1 下 PackedInt64Array 局部别名 element-write 是否仍触发 `_copy_on_write()` 堆分配须核验；若 COW 实际不触发，AC-B1 COW-on-write positive control 永卡 INCONCLUSIVE、禁局部别名约束失 regression guard，违 fail-fast pillar，同 BL-1 静默失败模式）——**实现约束：element-write 须直接通过 `self.scratch_buffer[i]`，禁局部别名（含函数参数传递路径，如 `helper(self.scratch_buffer)` 内部写入——参数绑定亦 increment refcount→2 触发 `_copy_on_write()` 堆分配，违 R4）**（`var s = self.scratch_buffer` 会 increment refcount→2 触发 `_copy_on_write()` 堆分配，违 R4；此约束由 AC-B1 COW-on-write positive control 验证）；BATTLE_LOADING 按注册时声明的 max weights 长度预分配），roll 路径零分配。
**Example:** weights=[700,200,100]（×100 缩放，W=1000）→ P=[0.7, 0.2, 0.1]。
**fault:** 空数组 / `Σw ≤ 0` / `any(w_i < 0)` / `len(weights) > 声明 max` / `W-1 > 2^31-1`（保守上界守卫——**Godot `randi_range` 参数类型与内部机制待核验**，defer rng-math.md/OQ3：训练数据表明 Godot 4.x 参数实为 **int64 非假定的 int32**，故"int64→int32 截断为负→内部 SWAP"机制很可能虚构；真实风险更可能是 `randi()` 返回 uint32（输出域 [0, 2^32-1]），W-1>2^32-1 时 `randi()%W==randi()` 输出域塌缩——真实上界为 uint32 输出域 2^32-1 而非 int32 参数域 2^31-1。**保守默认 W-1≤2^31-1 本身安全**（W≤2^31≪2^32 无 modulo bias），值无需改，仅 rationale 待核验。更松上界前提待 OQ3 核验参数类型后定，见下"为何整数域"注）→ R8 fault。
**为何整数域（修订）：** 原 PackedFloat32Array 方案有四缺陷——Σw 上溢 +inf 使 `C_j > u` 空集→result OOB、继承 randf_range FMA 跨架构漂移（待核验，见 R3）、W(float64) 与 C_j(float32) 精度不一致→OOB、无整数域逃生路径。迁 PackedInt32Array 消解此四缺陷。**但 int32 元素 + int64 累积器引入第五风险**：W（int64 累积）可超 INT32_MAX 不溢出 int64，但 Godot `randi_range` 参数类型与内部机制**待核验**（见 fault 行——训练数据表明参数为 int64 非假定的 int32，"int64→int32 截断→SWAP"很可能虚构，真实风险为 `randi()` uint32 输出域 modulo 塌缩）——由上界 fault 条件守卫（`W-1 > 2^31-1` → R8 fault，见 fault 行）。**保守默认 W-1≤2^31-1 本身安全**（W≤2^31≪2^32 无 modulo bias，值无需改，仅 rationale 待核验）；更松上界 W-1≤2^32-1 的前提待 OQ3/rng-math.md 核验参数类型后冻结 `W_MAX_SAFE`。F4 不依赖 AC-A5（浮点域），但仍依赖 AC-A4（整数域 `randi_range` 跨架构一致性）。定点 scale factor K 与 max_weights_length 留 ADR/下游。

> **full review specialist 已委托**：systems-designer 已逐公式代入边界值核验（Σw 上溢 +inf OOB / FMA 跨架构漂移 / float 精度不一致 OOB / 无 int 逃生 / Σw 上界 modulo bias 等），上述 fault 条件与 edge 已闭合。生产前建议人工复核 F1 `derive` 算法（OQ1 ADR）与 F4 定点 scheme（K 与 max 上界，OQ2）及 `W_MAX_SAFE` bound（OQ3）。

## Edge Cases

1. **If** `roll_int_range`/`roll_float_range` 收到 `min > max`：**Then** 该次 roll 返回零值，RNG System 立即 latch fault，GameRoot 在 phase 边界进入 ControlledGameplayFault；零值不进入下一 phase committed state（消费方须 `has_fault()` 守卫本 tick 内同步使用）。
2. **If** `roll_weighted_pick` 收到空数组、`Σw ≤ 0` 或含负权重：**Then** R8 fault 路径（返回 index 0，latch fault，phase 边界 abort tick）。
3. **If** `weights` 长度超过该流注册时声明的 max：**Then** R8 fault。scratch buffer 在 BATTLE_LOADING 按 max 预分配，运行时永不扩容（R4 零分配）。
4. **If** `derive(run_seed, stream_id)` 对固定 run_seed 的 8 项 stream_id 产生重复 stream_seed：**Then** 这是 fault 级 invariant 违反——`derive` 须对固定 run_seed 的 8 项单射；碰撞意味着 ADR 选的算法错误，AC-A3 强制验证单射性（分析论证 + 采样）。
5. **If** 调用不在固定 8 项 enum 集的未知/未注册 `stream_id`：**Then** R8 fault（与 RNG-EC11 同路径）。per-consumer 归属（消费方误调非自己注册的流）由静态分析/lint 检测，运行时不校验。
6. **If** pause intent 在一个跨 tick 的多 roll spawn 序列中途触发（如 5 roll 跨 5 tick，进行到第 3 tick 后 pause）：**Then** 已完成的 roll 保留，未完成的 roll 随 resume 从冻结 state 继续（R7：state 冻结于内存）；无 roll 丢失或被重摇。注：pause 在 tick 边界处理，单 tick 内多 roll burst 原子完成不可中途打断——AC-F2 验证跨 tick 序列场景。
7. **If** GameRoot mid-battle 进入 ControlledGameplayFault：**Then** RNG 在 BATTLE_ENDING fault cleanup 时 teardown；各流 state + 调用计数写入 first-failure telemetry（供 game-root AC-F4 可复现诊断）。
8. **If** `run_seed = 0` 或低熵值：**Then** 非 fault。`RandomNumberGenerator` 接受 seed=0 为合法（低熵但确定）起始态（Godot seed setter 对 0 的特殊处理须在 rng-math.md 核验）。dev 可强制 seed=0 作已知基线，无特殊处理。
9. **If** 两局共享同一 `run_seed`（dev 强制 seed 或 OS 罕见碰撞）：**Then** 两局序列完全一致——这是确定性契约本身，非 bug。release OS seed 碰撞概率可忽略；dev 强制 seed 为复现意图。
10. **If** 关键路径检测到 `roll_float_range` 跨架构 FMA 漂移：**Then** 该消费方改用整数域 roll + 映射（R3）。weighted_pick 已默认整数域（F4），不受此影响。此为运行期发现的风险，由 AC-A5 在签发前验证。
11. **(RNG-EC11) If** content revision 删除/重命名某 `stream_id` enum：**Then** battle load 校验注册 `stream_id` 集合与固定 enum 集一致；未知 id → fault（契约违规，不静默 skip）。
12. **(RNG-EC12) If** 注册声明的 max weights 长度对后续 content revision 的 weights 数组太小：**Then** 注册期校验失败（battle load 失败，返回 PREP），不在 roll 期失败。max 是 tuning knob。
13. **If** 应用进入后台（APP_BACKGROUND）：**Then** RNG state 随 gameplay 一并冻结（R7）；恢复后继续序列，不在后台 re-seed（后台不是新 battle）。

## Dependencies

### 上游

| Dependency | RNG 使用方式 | 当前状态 |
|---|---|---|
| Config / Data | 消费 `run_seed`（PREP 建立、BATTLE_LOADING 逐位冻结入不可变战斗快照）；在 BATTLE_LOADING 派生全部 `stream_seed` 并实例化生成器 | `config-data-system.md` 已声明 RunStartRequest→BattleConfigSnapshot 单一来源；runtime evidence OPEN |
| GameRoot & Scene Flow | 在 BATTLE_LOADING 被初始化为服务 participant；每个phase边界检查`has_fault()`；pause/resume不re-seed；telemetry 写 first-failure | `game-root-scene-flow.md` 第三轮修订已承接；第四轮复审 pending |

**无硬编排依赖**（systems-index 标"无依赖"指无前置系统须先完成）；Config 的 `run_seed` 是数据依赖。

### 下游（depended on by）

| Dependent | 使用的 RNG 服务 | 当前状态 |
|---|---|---|
| SpawnDirector(#10) | SPAWN 流：怪潮数量/波次/精英生成时机 roll | 未设计 |
| SkillDraftSystem(#15) | SKILL_DRAFT 流：每页3次无放回权重抽取+2次display permutation=5 calls；免费刷新共享同流；Dayan L5令单session最多4页/20 calls，否则3页/15；候选scratch上界12。pre-active base/refresh必须通过R5唯一scratch window，durable recovery双镜像成功后commit，FAILED discard，UNCERTAIN reconcile；普通Active沿用权威流且fault不重摇 | In Review / Re-review Pending；window runtime/golden待证 |
| Zhangtian Bottle(#22) | ZHANGTIAN_HERB 流：BATTLE_LOADING preflight后以预分配`PackedInt32Array([1,1,1])`调用`roll_weighted_pick`，max len=3，先查fault再读index，成功call delta恰1；canonical index `0/1/2→NINGQI_GRASS/TIELING_FLOWER/LEIYUAN_FRUIT`，132-byte候选（含durable config content revision+hash）写入360-byte `RunStartRecoveryV1`并经独立durable injection point后才继续；跨进程只在content key相等时rebind；VICTORY仅合法ticks43200..108000 expose数量3，DEFEAT仅`survival_ticks>=43,200`时expose数量1 | Zhangtian In Review / Re-review Pending；runtime replay OPEN |
| DamageSystem(#11，隐式) | CRIT 流：暴击判定 roll（5%，见 MVP 136） | 未设计 |
| DropSystem(#16，隐式) | DROP 流：掉落权重 roll（DropConfig，定点 int 权重） | 未设计 |
| 雷爆符(隐式) | LEI_TARGET 流：周期打击随机敌人 | 未设计 |
| 法宝匣(隐式) | TREASURE_BOX 流：随机提升未满技能 | 未设计 |
| RiskChoiceSystem(#17，隐式) | RISK_CHOICE 流：每个已提交TREASURE分支对behavior 6/7权重1/1精确一次weighted pick；SAFE 0次，最多2 calls/run | Designed / Full Review Pending |

### 跨文档一致性契约（须尊重的已冻结决策）

- **object-pooling R3**（零分配分配源清单）：RNG R4/R9 遵守——tick 内不 new 生成器、roll 路径无 boxing/Dictionary/Array/StringName/原生 String 构造。注：object-pooling R3 字面作用域是 slot reset hook，RNG 推广到 roll 路径——分配源清单一致，scope 为语义延伸。
- **game-root AC-F4**（可复现诊断）：RNG R3/R7 遵守——`(run_seed, stream_id, 调用计数)` 可复现 + first-failure 时各流 state 入 telemetry。
- **game-root R6/R7**（pause/resume）：RNG R7 遵守——BATTLE_PAUSED 流 state 冻结于内存，RESUME 不调 state API，无 roll 丢失/重摇。
- **game-root R9 / SaveSystem**：RNG R7 遵守——Save作者GDD已裁决MVP不支持中途存档；当前终局/跨进程恢复合同不得持久化或恢复mid-battle RNG state。未来扩展须新立契约与跨实例证据。
- **game-root R1**（participant 注册）：RNG R6 遵守——battle load 按固定表注册 `stream_id`，Active 后不可增删。
- **game-root R4/R5**（phase 边界 fault 路径）：RNG R8 遵守——single-exit cleanup → CONTROLLED_FAULT，committed effect 随 phase abort 丢弃（前提消费方采纳 phase-staging，BLOCKING on 下游消费方落地）。
- **spatial-grid AC-B7/J3 / object-pooling AC-F3**（共享 allocation harness）：RNG AC-B1 复用同一 allocation 测试工具（契约见 object-pooling AC-F3，其明示共享对象为 spatial-grid AC-B7/J3）；RNG AC-B1 positive control 参考并加强 spatial-grid **AC-J3** 思路：AC-J3 实际仅 2 个 positive control（A=`range(out.count)` 即 PackedInt32Array 路径、B="1 Object+1 Array" Object/Array 捆绑于同一 control，不含 Dictionary/StringName）；RNG AC-B1 扩展为 Object/Array/PackedInt32Array(含 `range()` 路径)/Dictionary/StringName/PackedInt64Array/原生 String **7 类各自独立 A/B 路径** delta>0（F4 迁 int 后 PackedInt32Array 为 weighted_pick 核心；object-pooling AC-F3 单一 Dictionary/Object 松标准不足以覆盖）。（修订：原误引为 spatial-grid AC-G1，已更正——AC-G1 是"每帧反映活动实体当前位置"的正确性 AC，非分配工具。）（BL-I 同步：RNG AC-B1 新增第 6 类 `PackedInt64Array`（F4 scratch buffer 类型）+ COW-on-write element-write positive control（禁局部别名约束可测）；**BL-1 同步：新增第 7 类 原生 String（`str()`/`%`/`+` 等 native method 返回 String 路径）+ COW-on-write parity 覆盖消费方 PackedInt32Array weights 别名写入（归消费方 GDD，AC-B1 提供范式参考）**；spatial-grid AC-J3 未含此类型/此 control，故 RNG AC-B1 非简单复用 AC-J3 而是加强扩展。）

### bidirectional 一致性 flag

- **Config GATE-G2（DESIGN-SIDE CLOSED）**：Config 已声明 `run_seed` 从 RunStartRequest 逐位冻结进每局 snapshot 并标 RNG 为消费方；仍需实现/集成证据。
- **GameRoot GATE-G3（DESIGN-SIDE CLOSED）**：GameRoot R4 已声明每个 phase 边界集中检查 service `has_fault()` 并将 RNG 作为 fault source；仍需实现/集成证据。
- **各下游消费方 GDD 须补**：roll 返回值用于 gameplay 决策（扣血/消耗/生成）前必须先检 `has_fault()`（二级防御，默认由 game-root wrap 兜底）；fault 零值不得进入 committed gameplay state。8 消费方落地时跟踪覆盖。
- 下游 8 个消费方的 `stream_id` 枚举集须在各 GDD 设计时与 RNG R2 固定 enum 集一致——任一消费方 GDD 引入新 stream_id 时同步回 RNG R2/R5。下游 DropConfig/SkillDraft 候选池改用定点 int 权重（F4），其 GDD 须声明 scale factor K 对齐。

## Tuning Knobs

RNG System 没有玩法数值旋钮（暴击率/掉落权重/候选池规则归各下游 GDD）。以下均为安全/配置旋钮，不能用于掩盖确定性契约错误：

| Setting | MVP value | Owner | Rule |
|---|---|---|---|
| `forced_run_seed` | null（dev 可设固定 int） | Build config / dev menu | dev-only 复现工具；release 必为 null；release 非空=契约违规（R1 无 OS 熵的运行期保证） |
| `max_weights_length_per_stream` | SKILL_DRAFT=12、RISK_CHOICE=2、ZHANGTIAN_HERB=3已冻结；其余per-stream仍依赖Drop等下游 | Config / performance ADR | 各流scratch上界；Zhangtian必须复用预分配`PackedInt32Array([1,1,1])`，太小/超长→battle load fault。整体仍PARTIAL-OPEN（OQ2） |
| `weighted_pick_scale_factor_K` | 待 ADR 冻结 | `/architecture-decision` | 定点整数权重缩放因子（消费方 float 权重 ×K → int）；K 须大到保精度且 Σw ≤ W_MAX_SAFE（保守 W-1≤2^31-1，见 F4——int64 累积器不溢，约束在 `randi_range` 参数域，**参数类型待核验** defer rng-math.md/OQ3）；归 ADR，**当前 OPEN** |
| `weighted_pick_W_MAX_SAFE` | 待 OQ3 冻结（保守默认 W-1 ≤ 2^31-1=INT32_MAX） | OQ3 / rng-math.md | Σw 上界守卫值；超界→R8 fault 防输出域塌缩+modulo bias（**参数类型与机制待核验**，见 F4 fault——训练数据表明 `randi_range` 参数为 int64 非 int32，"int32 截断"很可能虚构，真实风险为 `randi()` uint32 输出域 modulo；BL-B/BL-E）；保守默认 2^31-1 本身安全（值无需改）。精确 bound 待 OQ3/rng-math.md 核验参数类型后放宽（更松 W-1≤2^32-1 须 F2 回退自研基于 `gen.randi()` uint32），**当前 OPEN** |
| `roll_int_range_RANGE_MAX_SAFE` | 待 OQ3 冻结（保守默认 max-min ≤ 2^31-1=INT32_MAX） | OQ3 / rng-math.md | `roll_int_range` 范围上界守卫（对称 F4 `W_MAX_SAFE`，BL-4）；超界→R8 fault 防 `randi()` uint32 输出域塌缩 + fallback 拒绝采样 hang（**`randi()` 输出域待核验** defer rng-math.md/OQ3，见 F2 fault）。保守默认 2^31-1 本身安全；精确 bound 待 OQ3 核验后放宽，**当前 OPEN** |
| `stream_id` enum 集 | 固定 8 项（SPAWN/SKILL_DRAFT/CRIT/DROP/LEI_TARGET/TREASURE_BOX/RISK_CHOICE/ZHANGTIAN_HERB） | RNG + 下游各 GDD | 契约，非数值旋钮；新增/重命名须经下游 GDD + RNG R2/R5 同步，battle load 校验未知 id（RNG-EC11） |
| `derive` 算法 | 待 ADR 冻结 | `/architecture-decision` | `stream_seed` 派生函数；须单射、确定性、零分配、**纯整数运算**；F1 契约由 AC 验证，算法本身归 ADR，**当前 OPEN**（OQ1） |

无帧预算/内存旋钮——RNG 的成本由 R4 零分配约束（生成器数 = stream_id 集大小，固定）与 F4 scratch buffer 预分配共同决定，不随 tick 增长。

## Acceptance Criteria

### A. 确定性契约

**AC-A1a 跨运行确定性（unit）**
- Given: RNG 单元，注入有序调用序列 fixture（stream_id × call_index × args）
- When: 用相同 run_seed 重放
- Then: 相同 `(run_seed, stream_id, 有序调用序列)` 跨运行产生逐值恒等的结果序列
- 验证: deterministic replay artifact；调用序列由独立测试构建 instrumentation 记录（**非 R7 telemetry 职责**，以消 R3 vs R7 矛盾） | Gate: BLOCKING

**AC-A1b 完整 battle 重放（integration）**
- Given: 完整 battle（8 消费方落地后）
- When: 用相同 run_seed + 相同玩家输入重放
- Then: 全部 stream 全部 roll 逐值恒等
- 验证: end-to-end replay | Gate: BLOCKING on 下游 8 消费方 GDD 落地

**AC-A1c instrumentation 正确性 positive control（unit，BL-K）**
- Given: 同一有序调用序列 fixture，用两个不同 run_seed（seed_A、seed_B，均确定）各跑一次
- When: 对比独立测试构建 instrumentation 记录的两个结果序列
- Then: instrumentation 记录到 seed_A 与 seed_B 的结果序列非完全恒等（至少一位置相异，证明能观测真实差异，非固定返回同一记录的假阳性）；记录的 roll 计数 == 注入 fixture 的 roll 调用次数（每次 `roll_*` API 调用 +1，无论返回值是否被消费方使用——防 drop + counter-increment 漏洞；无漏记/多记，qa⑯ 指定口径），args == fixture args（无错记）
- 验证: instrumentation positive control（与 AC-B1 同范式）；若 instrumentation 确定地漏记某 roll，跨运行记录仍恒等会致 AC-A1a/A1b 假阳性 PASS，本 AC 捕获 | Gate: BLOCKING

**AC-A2 流隔离**
- Given: 两流 A(SPAWN)、B(SKILL_DRAFT) 从同一 run_seed 派生
- When: A 流消费方多调 100 次 roll 后，再调 B 流首次 roll
- Then: B 流首次 roll 结果等于"A 流调 0 次"时 B 流首次 roll 结果——A 的调用次数不偏移 B
- 验证: isolation fixture | Gate: BLOCKING

**AC-A3 derive 单射性**
- Given: 固定 8 项 stream_id 集
- When: 对抗性 run_seed 集（含 0/INT_MIN/INT_MAX/2^31/0xDEADBEEF/低 Hamming weight 值）× 全 8 stream_id 计算 derive
- Then: 每个 run_seed 下 8 个 stream_seed 两两相异（per-run_seed 8-way 单射）；任一碰撞=fault 级 invariant 违反
- 验证: (a) 分析论证（**non-automated，归 OQ1 ADR**——ADR 给碰撞概率上界 ≤ 8/2^64）；(b)(c) 经验采样（**automated regression**——N≥10^6 + 对抗 seed manifest；采样仅 regression 证据，单射证明靠 (a) 分析论证） | Gate: BLOCKING before derive() ADR frozen（OQ1）——(a) 随 ADR 签发，(b)(c) 为 ADR 后 regression（qa⑰ 拆分）

**AC-A4 整数域跨架构确定性**
- Given: 同 run_seed，x86(桌面 dev) 与 min-spec ARM(中端 Android/iOS) 各跑同调用序列
- When: 对比 `roll_int_range` 与 `roll_weighted_pick`（定点整数域）结果序列
- Then: 逐值恒等
- 验证: (i) cross-arch replay（**automated，deferred until min-spec 真机**）；(ii) godot-specialist 分析证明 `randi()/randi_range()` 跨架构逐位一致（**non-automated，归 rng-math.md + ADR**；含 `randi()` 输出域 uint32/uint64 核验 → BL-4 RANGE_MAX_SAFE bound） | Gate: BLOCKING before sign-off（与 AC-A5 对称，都 deferred until 真机 + rng-math.md + spike；qa⑱ 拆分 automated vs non-automated）

**AC-A5 浮点跨架构确定性**
- Given: 同 run_seed，x86 与 min-spec ARM 各跑同调用序列
- When: 对比 `roll_float_range` 结果序列
- Then: 逐值恒等；若检测到 FMA 漂移，该关键路径消费方迁移到整数域 roll+映射（R3）
- 验证: (i) cross-arch replay（**automated，deferred until min-spec 真机，OQ3**）；(ii) 漂移源核验（**non-automated，归 rng-math.md**：F3 为 GDScript 层表达式，见 F3/R3，与引擎方法 `randf_range` 的 FMA 行为不同，两路径均 defer 至 rng-math.md 核验后再冻结） | Gate: BLOCKING before sign-off（qa⑱ 拆分 automated vs non-automated）
- 注：`roll_weighted_pick` 已默认整数域（F4），不受 AC-A5 约束；AC-A5 仅覆盖剩余浮点消费方。

### B. 零分配

**AC-B1 steady-state 零增长**
- Given: 全部生成器与 scratch buffer 在 BATTLE_LOADING 预分配
- When: release 跑 10,000 Active ticks，固定 seed replay，峰值 303 ENEMY + 300 DROP + 400 projectile（对齐 spatial-grid AC-J6 fixture），含 wave 边界 burst（50 spawn roll + 20 drop roll 连发）；**另含 BATTLE_LOADING段（ZHANGTIAN_HERB在全部preflight后消费恰1次）+ BATTLE_PAUSED段（SKILL_DRAFT/RISK_CHOICE流消费），或附consumer-coverage manifest记录各流调用计数>0**——防非Active流被fixture漏测（perf）
- Then: **whole-tick** allocation counter=0（含 RNG 自身 + 消费方 roll 路径构造）；无 `RandomNumberGenerator.new()`、无 boxing/Dictionary/Array/StringName 构造出现在 roll 路径
- 验证: allocation instrumentation + positive control（须先 PASS 证明 harness 能观测分配——positive control 须**分别**断言 `Object`/`Array`/`PackedInt32Array`（含 `for i in range(n)` 路径）/`Dictionary`/`StringName`/`PackedInt64Array`（F4 scratch buffer 类型，BL-I）/原生 String（`str()`/`%`/`+` 等 native method 返回 String 的路径，BL-1）多类型创建，每类独立 A/B 路径（唯一差异为该类型一次创建）observed allocation delta>0；任一类型未覆盖→harness 不合格→结果 INCONCLUSIVE 修 harness 重跑，非系统 PASS/FAIL；参考 spatial-grid AC-J3 positive control 思路并加强为 7 类独立 A/B（AC-J3 实际仅 range(A)+Object+Array 捆绑于 B 两 control，无 Dictionary/StringName/PackedInt64Array；RNG AC-B1 扩展覆盖），非 object-pooling AC-F3 单一类型松标准；**另须 COW-on-write element-write positive control**：对预分配 `PackedInt64Array` 造局部别名 `var alias := scratch_buffer` 后 `alias[i] = v` 写入，断言 harness 能观测到分配 delta>0（refcount→2 触发 COW 堆分配——验证 BL-I/R4 "禁局部别名"约束可被测；若 harness 观测不到此 delta，INCONCLUSIVE 须区分三分支：(i) harness bug（能观测其他类型 delta 但漏 COW→修 harness 重跑）；(ii) COW 实际不触发（Godot 4.7.1 行为断言假→约束本身失效，转 GATE-G4 核验，非 harness 问题）；(iii) 技术上无法观测（C++ 侧 `_copy_on_write()` 无 GDScript 钩点）。**COW-on-write 触发本身为 Godot 4.7.1 行为断言待核验 defer rng-math.md/OQ3/GATE-G4（BL-7/GS-4）**；(iii) 分支退化方案为静态分析/lint 禁多类别名模式 + 代码审查（与 AC-C2/AC-E2 per-consumer 同 non-automated 路径）：lint 须覆盖 (a) 显式别名 `var alias := scratch_buffer`、(b) 隐式类型别名 `var alias = self.scratch_buffer`、(c) 函数参数传递 `helper(scratch_buffer)` 内部写入、(d) 方法返回值别名 `var x = get_buffer()`（若返回 PackedArray）——单一模式 lint 会漏 (b)(c)(d) 路径））。**parity（perf⑦）**：同范式 COW-on-write control 亦覆盖消费方 PackedInt32Array weights 别名写入（消费方 `var w = weights; w[i]=v` 触发 COW 堆分配，违 R4——此约束归消费方 GDD，AC-B1 仅提供 control 范式参考，消费方落地时复用）。与 spatial-grid AC-B7/J3 / object-pooling AC-F3 共享 allocation 测试工具 | Gate: BLOCKING before implementation Done
- 注：scratch buffer sizing 正确性 BLOCKING on max_weights frozen（OQ2）；零运行时分配部分可先行验证。

### C. 无 OS 熵

**AC-C1 gameplay 无熵源**
- Given: release 构建、`forced_run_seed=null`
- When: 全 battle 运行（固定 seed battle + 3 配置 peak/min/mid）
- Then: 无 `randomize()` 调用、无全局 `randi/randf`、无 `Time.get_ticks_*/OS.*` 作随机源；唯一 OS 熵触点是 run_seed 建立（PREP）
- 验证: (a) 静态 grep 白名单审计（白名单仅 run_seed 建立点，manifest 固化）；(b) runtime 插桩；(c) 间接路径（call/funcref）专项审查 | Gate: BLOCKING

**AC-C2 release 强制 seed 检测**
- Given: release 构建
- When: 任何路径设 `forced_run_seed` 非 null
- Then: 构建期 guard（CI 静态检查：release 配置 grep `forced_run_seed\s*=\s*(?!null)` 非空即构建失败）+ runtime assert → ControlledGameplayFault（不静默生效，qa⑮ 指定机制）
- 验证: (a) 构建期注入非 null→构建失败；(b) runtime 注入非 null→ControlledGameplayFault | Gate: BLOCKING

### D. 分布与 API

**AC-D1 weighted_pick 归一**
- Given: 固定 seed，weights=[700,200,100]（×100 缩放，W=1000，scale factor 见 F4/ADR——对齐 F4 示例，原 ×1000 与 F4 ×100 不一致已更正，qa⑬/systems㉑）
- When: 重放该流 N 次 roll
- Then: (i) oracle match 前 M=1000 roll 逐值恒等（M=roll 匹配计数，避免与 F4 scale-factor K 命名冲突，qa⑬）；(ii) statistical sanity N≥10^5 chi-square p>.01 期望 7:2:1（**若 oracle 自带 modulo bias 待核验 OQ3，(i) oracle match PASS 但 (ii) chi-square 可能 FAIL——此冲突 defer OQ3 像 AC-D2(iii)；weighted_pick 整数域本身无 modulo bias，但 oracle 若由 Godot `randi_range` 生成则继承其 bias，qa⑫**）
- 验证: deterministic oracle + 独立 chi-square（非仅 oracle match——oracle 自身可能有 bias） | Gate: BLOCKING before oracle frozen（OQ6）

**AC-D2 int_range 均匀无偏**
- Given: 固定 seed，[0,99]
- When: 重放
- Then: (i) 结果序列与 Godot `randi_range` oracle 恒等；(ii) chi-square 均匀性 N≥10^5；(iii) modulo-bias 专项（选不整除 `randi()` 输出域的 range，频次偏差在 modulo bias 理论上界内——**bound 待核验** defer rng-math.md/OQ3：若 Godot 用拒绝采样则上界≈0，若 simple modulo 则上界=(输出域 mod range)/输出域；"拒绝采样理论上界"为未核验断言，见 F2）
- 验证: oracle + 独立统计 | Gate: BLOCKING before oracle frozen（OQ6）+ modulo bias bound 核验（OQ3，见 Then (iii)，qa⑲）

~~**AC-D3 shuffle_in_place 合法置换**~~ — *已移除：`roll_shuffle_in_place` 从 R5 删除（Godot 4 COW 使原地写触发堆分配，无法满足 R4；待消费方 + ADR 定义零分配洗牌方案，见 R5 注与 Review Log）。*

### E. 非法参数与 fault

**AC-E1 非法参数 latch fault（RNG 级，testable now）**
- Given: 各注入 `min>max`、空 weights、`Σw≤0`、含负权重、`len(weights)>max`、`!isfinite(min)||!isfinite(max)||!isfinite(max-min)`（仅 float_range，显式三子类对齐 AC-E1b）、`W-1>2^31-1`（仅 weighted_pick）、`max-min>RANGE_MAX_SAFE`（仅 int_range，BL-4）、`max-min` 减法溢出 bypass（`min=INT64_MIN,max=0` / `min=-1,max=INT64_MAX`——`max-min` 溢出为负使 `>RANGE_MAX_SAFE` 守卫静默不触发，仅 int_range，BL-6/SD-1）
- When: 调对应 roll
- Then: (1) roll 返回零值（int→0 / float→0.0 / pick→0）；(2) RNG 立即 latch `fault_reason` 且 `has_fault(stream_id)` 转 true（流进入 FAULTED 终态——此显式断言保证 AC-E1c Given "已 FAULTED" 前置可建立，QA-2；gen-state 不变量见 AC-E1b，FAULTED 终态不可复活见 AC-E1c）
- 验证: fault-injection table | Gate: BLOCKING（RNG 级 fault latch + 零值返回，无外部依赖，testable now）
- 注（拆分 BL-3）：原 AC-E1 Then 混 4 断言，(3)(4) 为 gated 状态拖累可测内核无法独立签发——现拆出：(3) "GameRoot phase 边界 `has_fault()`→ControlledGameplayFault + 零值不进下一 phase committed state" → 见 **GATE-G3**（game-root has_fault 检查义务落地后才可测）；(4) "消费方 `has_fault()` 守卫本 tick 内同步零值" → 见 **bidirectional flag**（各下游消费方 GDD 落地，见 Dependencies 跨文档块）。本 AC-E1 仅签发 RNG 级 (1)(2)，独立于 game-root/消费方落地。

**AC-E1b fault 路径 gen-state 不变量**
- Given: 任一 fault 触发参数（`min>max`、空/全零/含负 weights、`len>max`、`!isfinite`（含 `max-min` 差值溢出，仅 float_range）、`W-1>2^31-1`（仅 weighted_pick）、`max-min>RANGE_MAX_SAFE`（仅 int_range，BL-4）、`max-min` 减法溢出 bypass（`min=INT64_MIN,max=0`/`min=-1,max=INT64_MAX`，仅 int_range，BL-6/SD-1——验证 overflow-safe 守卫对该用例触发 fault 而非静默放行）），任一流处于 READY，state=s（**此 AC 仅覆盖 READY→fault 的 gen-state 不变量；FAULTED→fault 的终态不可复活见 AC-E1c**）
- When: 调对应 roll 触发 fault
- Then: `get_stream_state(stream_id)` 在 faulting roll 调用前 == 调用后（== s）；fault 路径不推进 gen state（R8 invariant：在任何 gen draw 前 latch）
- 验证: state-diff test（fault injection × 各 roll 类型，前后 snapshot 对比） | Gate: BLOCKING
- 注：此 invariant 保护 telemetry first-failure state 正确性（AC-F3 capture 时机）→ game-root AC-F4 可复现诊断；实现 bug（先 draw 再检参）会破此不变量且 schema test 抓不到。

**AC-E1c FAULTED 终态不可复活（unit，BL-2）**
- Given: 任一流已处于 FAULTED（由任一 AC-E1/E1b fault 参数触发 latch 后），fault_reason=F
- When: (i) 对该 FAULTED 流再调任一 roll（`roll_int_range`/`roll_float_range`/`roll_weighted_pick`）；(ii) 对该 FAULTED 流调 `set_stream_state(id, 任意 state)`
- Then: (i)(ii) 均→R8 fault（fault_reason 仍为 F 不变，流保持 FAULTED 终态，**不允许任何路径复活**——违承诺②"不被静默重摇"的可测根）；`has_fault(stream_id)` 保持 true 不变（流仍 FAULTED 终态，FAULTED 态观测统一走 `has_fault()`），`get_stream_state(id)` 仍返回 PCG 原始 state ==s（与 AC-E1b/R7 一致——**不引入"FAULTED 标志"返回语义**：get_stream_state 始终返回 PCG uint64，FAULTED 不改变其返回值；BL-8/QA-1 修正原"返回 FAULTED 标志不变"与 AC-E1b"fault 后 ==s"+R7 PCG-uint64 三者矛盾）
- 验证: fault-revival-prohibition test（先注入 fault A 使流 FAULTED 并 `get_fault_reason(id)` 记 reason_A，再分别注入 (i) 不同 fault 的 roll 调用 (ii) `set_stream_state(id, 任意 state)`，断言 `get_fault_reason(id)` 仍 == reason_A（first-failure-wins，fault_reason 不被后续 fault 覆盖——通过 R5 `get_fault_reason` API 闭合 testability，BL-七-1）+ `has_fault(stream_id)` 仍 true（流仍 FAULTED）+ `get_stream_state(id)` 仍 ==s（PCG state 未因 fault 改语义）） | Gate: BLOCKING
- 注：此 AC 闭合四审 BL-N "声明-only、未 testability-闭环"——R6/R7 声明了 FAULTED 终态行为（FAULTED 后再 roll→fault / set_stream_state on FAULTED→fault）但无 AC 覆盖；一个静默 reset state on FAULTED 的实现能通过当前全部 AC，本 AC 捕获。

**AC-E2 未知 stream_id fault**
- Given: 调用不在固定 8 项 enum 集的 stream_id
- When: 调 `roll_*(stream_id=未知, ...)`
- Then: R8 fault（与 RNG-EC11 同路径，全局 enum 集校验）
- 验证: adversarial registration test | Gate: BLOCKING
- 注：per-consumer 归属校验（消费方误调非自己注册的流）当前 API 无 caller 身份无法运行时检测，改为静态分析/lint。

### F. 生命周期与 pause/resume

**AC-F1 battle-scope 生命周期**
- Given: BATTLE_LOADING → Active → BATTLE_ENDING，再开新 battle
- When: 跑两场 battle
- Then: 第二场从新 run_seed 派生，不继承第一场流 state；BATTLE_ENDING 全部生成器释放，无泄漏（RandomNumberGenerator 实例计数=0）
- 验证: lifecycle integration + leak check（对齐 object-pooling AC-F3 leak 方法） | Gate: BLOCKING before derive() ADR frozen（OQ1，"不继承 state" 需 oracle）

**AC-F2 pause/resume 不丢 roll**
- Given: 一个 5-roll spawn 序列跨 5 tick（一 roll/tick），第 3 tick 后 pause intent 触发
- When: BATTLE_PAUSED → resume
- Then: 前 3 roll 结果保留，后 2 roll 从冻结 state 继续且与"无 pause 连续跑"序列逐值恒等；无 roll 丢失或重摇
- 验证: pause-interrupt replay | Gate: BLOCKING

**AC-F3 first-failure telemetry**
- Given: 任一 fault 路径触发
- When: GameRoot 捕获 first failure 并在 RNG teardown 前执行 cleanup transaction
- Then: versioned `RngFaultTelemetrySnapshot` 精确写入 R7 全字段一次，`diagnostic_id` 等于通用 first row，`battle/config identity` 与本局 snapshot 相等，`pre_fault_states` 等于 faulting draw 前 instrumentation snapshot；重复 fault/cleanup 不覆盖或二次写。非 RNG fault 控制组 `stream_count=0`
- 验证: sidecar schema/identity/exact-once test + AC-E1b state-diff + teardown-order spy | Gate: BLOCKING on GATE-G3 runtime integration
- 注：本 telemetry 支持从故障点恢复重放；从 run 起点的 full replay 由 AC-A1 + R2 调用顺序稳定性支持，非本 telemetry 职责。当前消费方引用为 game-root AC-F4。

### G. SaveSystem 与 Config 集成 gate

> 本节为 integration/consistency **gate**（非 testable AC），前置依赖未就绪前 BLOCKED。

**GATE-G1 中途存档 gate**
- Given: SaveSystem明确MVP不提供mid-battle state持久化契约
- When: 任何中途存档 story
- Then: story为OUT OF MVP且不得实现；未来若修订范围，先版本化Save/RNG schema并测试中途存档恢复各流state各一次
- 验证: SaveSystem scope contract test | Gate: RESOLVED FOR MVP / BLOCKED for future expansion

**GATE-G2 Config run_seed 字段 gate**
- Given: Config GDD 已声明 `run_seed` 字段与 RNG 消费方，但实现尚不存在
- When: RNG 依赖 run_seed 建立
- Then: 文档字段、单一来源与不可变性保持一致；实现前仍须通过 Config AC-D4
- 验证: consistency-check + Config AC-D4 | Gate: DESIGN-SIDE CLOSED / RUNTIME OPEN

**GATE-G3 game-root has_fault 检查义务 gate**
- Given: game-root GDD 已声明 phase 边界检查 RNG `has_fault()` 义务并标 RNG 为 service fault source
- When: RNG fault latch 后须被 game-root 在 phase 边界捕获进 ControlledGameplayFault
- Then: 每个phase注入fault都在matching end后进入ControlledGameplayFault，fault零值不进入下一phase committed state；RNG sidecar 在 RNG teardown 前恰写一次并关联 first diagnostic
- 验证: GameRoot AC-B3/AC-F4 integration + AC-F3 teardown-order spy | Gate: DESIGN-SIDE CLOSED / RUNTIME OPEN

**GATE-G4 rng-math.md 存在性 gate**
- Given: `docs/engine-reference/godot/` 现无 `rng-math.md`（grep 零命中），但 GDD 多处对 Godot 行为作事实断言（randi_range 参数类型、拒绝采样 vs simple modulo、FMA 行为、seed= 处理、state 往返性、`randi()` 输出域 uint32/uint64、native method `randi_range`/`randf`/`randi` 内部零分配、GDScript `>>` 算术 vs 逻辑移位、int64 `*` 溢出回绕 contract、int64 `-` 减法溢出回绕 contract（BL-6/SD-1→F2 fault guard bypass）、set_state 不隐式 re-seed（BL-9/GS-3→SaveSystem 跨实例语义）、PackedInt64Array COW-on-write element-write 触发堆分配（BL-7/GS-4——4.7 "packed array 元素不再触发整个 packed array 属性 setter" 相邻变更须核验 4.7.1 仍触发）
- When: 这些断言若作事实陈述而未经核验，LLM 训练数据截止 May 2025（Godot ~4.3）很可能虚构 4.4-4.7 行为
- Then: rng-math.md 创建并由 godot-specialist 核验前，任何 Godot 行为断言不得作事实陈述，须 hedge 为"待核验 defer rng-math.md/OQ3"；rng-math.md 落地（解阻 OQ3）同时解阻 randi_range 参数类型核验、拒绝采样 vs simple modulo 核验、BL-1（native method 零分配源码核验）、BL-4（`randi()` 输出域→RANGE_MAX_SAFE/W_MAX_SAFE bound 核验）、BL-5（int64 `*`/`>>` 算术移位/溢出 contract→derive 实现路径核验）、BL-6（int64 `-` 减法溢出 contract→F2 fault guard overflow-safe 形式核验）、BL-7（PackedInt64Array COW-on-write 4.7.1 触发核验→AC-B1 COW control 可测性）、BL-9（set_state 不 re-seed 核验→AC-H1b 跨实例可移植性）、EC8（seed=0 setter 特殊处理核验→EC8 低熵 seed 非故障契约）、AC-H1（state 为 PCG 原始 uint64 往返性核验→AC-H1 round-trip 可测性）及 BL-F 同型先例的 rationale 核验
- 验证: consistency-check / 人工核验 rng-math.md 存在 + 内容覆盖断言清单 | Gate: BLOCKING before sign-off（结构守卫，RECOMMENDED 升级，GATE-G4）

### H. state 往返性（新增）

**AC-H1 state 往返**
- Given: 任一流处于 READY，state=s
- When: `set_stream_state(id, s)` 后 `get_stream_state(id)`
- Then: 返回 == s；且 set 不破坏确定性（set 后序列 == 从该 state 起的 fresh 序列，即同实例重新 `set_stream_state(s)` 后从该 state 起消费的序列——与 AC-H1b 新实例 set 同 state 后序列一致，二者均要求 state 为 PCG 原始 uint64 且 set 不 re-seed）
- 验证: round-trip test（须在 rng-math.md 核验 Godot 4.7.1 RandomNumberGenerator.state 为 PCG 原始 uint64 后） | Gate: BLOCKING before sign-off

**AC-H1b 跨实例 state 可移植性（unit，BL-9/GS-3）**
- Given: 流 A 实例 gen_A 处于 READY，state=s（已消费若干 roll）；新实例 gen_B（同 run_seed、同 stream_id 派生，未消费）
- When: `gen_B.set_stream_state(s)` 后消费 gen_B 序列
- Then: gen_B 序列 == gen_A 从 state=s 起的 fresh 序列（state 可跨实例移植，set 不隐式 re-seed）；若不成立则 set_state 内部隐式 re-seed，SaveSystem 跨实例存档/恢复语义破坏
- 验证: cross-instance portability test（须在 rng-math.md 核验 set_state 不 re-seed + state 序列化跨实例语义后） | Gate: BLOCKING before sign-off（gated on GATE-G4 rng-math.md；同实例往返见 AC-H1，此 AC 覆盖 SaveSystem 真实路径的跨实例 gap）

> **full review specialist 已委托**：qa-lead 已逐 AC 核验可测性——AC-A5 自相矛盾已通过对称化消解、AC-D oracle 未决已标 BLOCKING-on-OQ6、AC-E2 不可实现已降级为全局 enum 校验、AC-F2 场景已澄清为跨 tick、AC-G1/G2 已改名 GATE- 区分 testable AC。当前状态：derive ADR（OQ1）/ ARM 真机（OQ3）/ oracle（OQ6）/ GATE-G2 解阻前，多数 BLOCKING 级 AC deferred evidence；实现前须先解 OQ1+OQ3+OQ6 并解阻 GATE-G2。

## Open Questions

| # | Question | Owner | Target | Affects |
|---|---|---|---|---|
| 1 | `derive()` 选 splitmix / PCG-DXSM / 其他？须单射、确定性、零分配、纯整数运算、跨架构一致。**GDScript int64 陷阱（BL-5；BL-6/SD-1 同类覆盖 `-` 减法）**：int 为 64-bit signed 无原生 uint64，`>>` 对负值算术移位（符号扩展）、`*` 与 `-` 溢出回绕无 contract——naive 移植依赖 uint64 逻辑右移的算法（splitmix64/PCG-DXSM）静默破坏单射+确定性；`-` 减法溢出另使 F2 fault guard `max-min` 可被绕过（BL-6/SD-1）。ADR 须选 32-bit 拆分 / 位掩码 / GDExtension 原生 uint64 路径之一并核验；F2 fault guard overflow-safe 比较式一并归此 ADR + OQ3 核验 GDScript int64 `-` 减法 contract。需 ADR 冻结算法 | `/architecture-decision` | 实现前 | AC-A3/A4, F1, F2 fault guard, BL-5, BL-6 |
| 2 | `max_weights_length_per_stream`：SKILL_DRAFT=12、RISK_CHOICE=2已冻结；Drop等其余流仍待下游上界 | Config + 下游 Drop GDD | 下游 GDD 签发前 | AC-B1, F4 scratch buffer sizing |
| 3 | Godot 4.7.1 `RandomNumberGenerator.randi()/randf()/randf_range()` 跨架构（x86↔ARM）逐位一致性？须补 `docs/engine-reference/godot/modules/rng-math.md`（疑 `random_pcg.*` 源文件，待核验）核验算法、state 往返、FMA 行为。**另须核验（BL-1/BL-4/BL-5/BL-6/BL-7/BL-9）**：(a) `randi()` 输出域 uint32 vs uint64（→RANGE_MAX_SAFE/W_MAX_SAFE bound）；(b) native method（`randi_range`/`randf`/`randi`）内部零分配（→R4 零分配覆盖边界）；(c) GDScript `>>` 算术 vs 逻辑移位 + int64 `*` 溢出回绕 + int64 `-` 减法溢出回绕 contract（→derive 实现路径 + F2 fault guard overflow-safe 形式）；(d) PackedInt64Array COW-on-write element-write 触发堆分配（4.7 packed-array setter 相邻变更须核验 4.7.1 仍触发，→R4 BL-I/AC-B1 COW control/禁局部别名）；(e) set_state 不隐式 re-seed（→SaveSystem 跨实例语义/AC-H1b）；(f) `RandomNumberGenerator.seed = 0` setter 特殊处理（EC8→低熵 seed 非故障契约核验）。weighted_pick 已整数域（不受 float 影响）；剩余浮点消费方哪些是"关键路径"须迁移到整数域 | godot-specialist + QA | min-spec 真机到位后 + rng-math.md 落地 | AC-A4/A5, R3, AC-H1/AC-H1b, BL-1/BL-4/BL-5/BL-6/BL-7/BL-9 |
| 4 | `run_seed` 来源已裁决：release仅PREP/run-start的OS entropy producer，dev build可显式`forced_run_seed`；玩家输入seed/每日seed不属于MVP | game-designer | CLOSED-DESIGN；实现证据OPEN | R1, Tuning forced_run_seed |
| 5 | stream_id 集是否 8 项即终？BossStateMachine 可能需独立流（boss 攻击模式随机）；SkillDraft 刷新是否需独立 refresh 流。须在各下游 GDD 落地前 resolved（一旦内容耦合进 enum 集，后续拆流破坏跨版本复现） | RNG + 下游各 GDD | 各下游 GDD 落地时 | R2/R5 enum 集, Tuning |
| 6 | 固定 seed 分布 oracle 的规范捕获流程？F2 已定（委托 Godot `randi_range`，oracle=Godot 快照）；F4 weighted_pick oracle=定点 int 序列。参考序列如何冻结与版本化、跨架构 oracle 是否须分平台捕获（int 跨平台一致；float 须分平台） | qa-lead + godot-specialist | AC 签发前 | AC-D1/D2 |

> **Visual/Audio 与 UI 节跳过**：RNG 是纯 Foundation/Core 基础设施，玩家不直接感知（见 Player Fantasy "无感"），无 VFX/音频/UI 需求——参照 spatial-grid / object-pooling / config 体例不设此节。

---

## Review Log（full design-review 2026-08-24）

**Verdict**: NEEDS REVISION → 修订闭环
**Scope signal**: L
**Specialists**: 跨文档核验员(Explore)、game-designer、godot-specialist、performance-analyst、systems-designer、qa-lead、creative-director
**Blocking items**: 10（A 级，全修订闭环）| **Recommended**: B/C 级一并补
**Summary**: full review 揭示确定性 pillar 建立在未验证 Godot 假设（引擎参考零 RNG 覆盖）、系统性跨文档 AC 错引（spatial-grid vs game-root）、`roll_shuffle_in_place` COW 使 AC-D3 不可满足、F4 浮点域多缺陷（+inf 上溢 / FMA / 精度不一致 / 无 int 逃生）、AC-E2 per-consumer 不可实现、R8 零值窗口、telemetry schema 缺失等。修订全部为 spec/citation 修复非重设计：跨文档引用更正（game-root AC-G1/G2 + spatial-grid AC-B7/J3）、shuffle 删除、F4 迁定点整数权重（PackedInt32Array）、AC-E2 降级全局 enum 校验、R8 补消费方 `has_fault()` 守卫、AC-A4/A5 对称化 + 漂移源更正（FMA in randf_range）、F1 derive 纯整数约束、fantasy 拆玩家/dev 面、F2 委托 Godot 澄清、telemetry 改 per-stream 计数器 + schema 定义、AC-G1/G2 改名 GATE-、补 AC-H1 state 往返、AC-D 补 chi-square。3 个 OPEN（derive ADR / max_weights 下游 / run_seed 来源）保持 deferred。
**Prior verdict resolved**: First review.
