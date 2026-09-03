# SpatialGrid（空间网格）

> **Status**: Re-review Pending — core API维持冻结；2026-09-02传播“感知无限、技术有限”的稀疏有限域契约，须独立复审
> **Author**: 用户 + Claude Code agents
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 间接支撑"爽快割草"核心爽点（300 实体不卡顿的前提）
> **Review Mode**: full（game-designer / systems-designer / qa-lead / performance-analyst / godot-specialist + creative-director）

## Overview

SpatialGrid 是战斗场景的稀疏均匀空间索引，把需要被附近查询命中的敌人与掉落物按位置归入固定大小的世界格；投射物默认作为查询调用方而非被索引目标。它覆盖Stage给出的巨大但有限坐标域，却只为固定上限的活动条目与占用格预留内存，不能按虚拟世界面积创建dense bucket。它将常见半径查询从 O(N) 全场遍历缩小为局部相交格与候选扫描；当查询覆盖空格数超过固定枚举上限时，合法降级为扫描至多1000个active entries并做同一精确距离过滤，语义不变。

- **一句话**：按位置把实体分桶的均匀网格，让半径查询只扫描相交格及其候选；期望复杂度 O(相交格数 + 候选数)，最坏仍可能 O(N)。
- **玩家如何交互**：被动/自动——玩家从不直接接触它，只感受它启用的流畅度。
- **为什么存在**：300 实体同屏不卡顿的命根子；没有它，每帧每个技能都遍历全场。

## Player Fantasy

玩家不直接接触 SpatialGrid——它是纯基础设施，玩家感受的是它启用的东西：300 妖兽涌来时飞剑剑阵仍流畅清屏、满屏特效下走位仍跟手、灵气吸取仍即时。换言之，SpatialGrid 服务的"幻想"是**无感**：玩家从未意识到空间查询的存在，只体验到割草该有的爽快与不卡顿。若玩家察觉到"卡了一下"或"范围攻击好像没打中该打的人"，那不是幻想落空，而是 SpatialGrid 失职。

**失败分级（design-review 2026-08-14/19 补充）**：玩家可能感知三类失职——(1) **性能失败**（"卡了一下"）：帧率下降，流畅度幻想落空；(2) **正确性失败**（"范围攻击没打中该打的人"）：查询漏实体，战斗可信度幻想落空；(3) **内容准入失败**（容量已满却仍把新敌人发布到场景）：产生可见但不可索引的“幽灵敌人”。前两类的正确性 AC（B/C/D 组）与性能 AC（J 组）同为 BLOCKING；第三类必须在发布前被 SpawnDirector 抑制，绝不能以幽灵实体降级。普通怪达到容量时该次 spawn intent 可被安全抑制且不打断当前战斗；Boss/阶段必需实体使用预留槽，若预留仍不可用则作为契约故障进入 `ControlledGameplayFault`，不能偷偷少生成关键内容。正向锚点：300 妖兽涌来时飞剑自动锁定、范围清屏、灵气吸取仍即时——这就是 SpatialGrid 成功的证明。

> 2026-08-18 full review 的 `creative-director` 裁决："流畅"与"查询可信"必须同时成立，任何 release 降级都不得缩小玩法查询半径或返回错误集合。

## Detailed Rules

### Core Rules

**R1 — 稀疏均匀空间哈希网格（sparse uniform hash grid）**
- 有限世界域被概念性划分为固定边长`CELL_SIZE`的正方形格；规范signed格坐标为`cell_x=floor(world_x/CELL_SIZE)`、`cell_y=floor(world_y/CELL_SIZE)`，不以相机、玩家或spawn ring为原点，不随玩家移动重编号。
- 世界域大小不得决定运行时bucket数量。Grid只按`MAX_INDEXED_ENTRIES=1000`预分配entry与最多1000个occupied-cell slot；未占用的虚拟格没有Bucket对象或数组。
- 私有实现可选择预分配open-address hash table、sorted cell table或等价零分配结构，但禁止dense `world_width/CELL_SIZE × world_height/CELL_SIZE`数组、运行时Dictionary增长和首次遇到新cell才分配。
- **可表示域是行为契约**：Config V2提供非零snapshot ID、`world_safe_half_extent=16384`、绝对硬上限`MAX_ABS_WORLD_COORD=1_000_000`、`MIN_CELL_SIZE=0.01`、`MAX_INDEXED_ENTRIES=1000`与`MAX_QUERY_CELLS_ENUMERATED=262_144`。`CELL_SIZE`须finite且`≥MIN_CELL_SIZE`；不再以arena维度作为上限。
- Grid init复制`StageSpatialConfigV2`与flattened limits，checked派生world-domain cell坐标上界并验证可装入signed int64。整个Active/Paused生命周期只读保存，禁止保留可变Resource或本地默认。
- insert/stage/query center先验证完整坐标finite且位于`world_safe_aabb`；越域是契约故障，不clamp、不wrap、不suspend到旧位置。以上上限是技术安全域，不是玩家可见地图边界。

**R2 — 统一查询命名空间 + 类型标记**
- 所有空间查询共用同一坐标划分和公开接口。每个已注册条目带类型标记（`ENEMY` / `PROJECTILE` / `DROP`）。格内采用混合列表、按类型子桶或独立类型 bucket 属数据布局 ADR，必须通过 spike 选择。
- 查询时可按类型过滤（例：自动索敌只查 `ENEMY`，灵气吸取只查 `DROP`）。
- **类型标记为位掩码常量**：`ENEMY=1`、`PROJECTILE=2`、`DROP=4`、`ALL=7`。`type_filter` 为 int，匹配条件固定为 `(entry.type_mask & type_filter) != 0`。不得使用从 0 开始的普通 enum 值直接做位运算。
- **`type_filter == 0`（空掩码）行为**：返回 `OK,count=0`（无类型可匹配），不返回全部实体。AC-D1 的"7 种 filter 组合"指 3 单类型 + 3 两类型 + ALL 共 7 个非空子集；空掩码是第 8 种。
- 未知 bit 被忽略；若过滤器没有任何已知 bit 则返回 `OK,count=0`。release warning 按未知 mask 值限频，不能每次查询刷日志。
- 注册条目的 `type_mask` 必须恰好是一个已知 bit（`ENEMY`、`PROJECTILE`、`DROP`）；0、复合 bit 或未知 bit 均是注册错误。组合 mask 只允许用于查询过滤器。
- 当前业务没有以 `PROJECTILE` 为目标的查询；投射物是 `ENEMY` 查询的调用方，默认不注册进 SpatialGrid。只有后续出现清除敌方弹幕等真实消费者，或 spike 证明注册更优时，才启用 `PROJECTILE` 条目。不得仅为"类型齐全"承担 400 投射物的更新和过滤成本。

**R3 — 行为契约：每帧反映实体当前位置**
- **行为**：网格在查询阶段开始前，反映本逻辑帧已经提交的所有活动实体位置。
- `insert_into(..., out_handle, phase_lease_id) -> SpatialStatus` 只创建 pending handle；实体在下一次成功完成的 `sync()` 原子提交后才进入查询快照。`remove(handle_id, phase_lease_id) -> SpatialStatus` 对 active/suspended handle 立即失效；对 pending handle 则取消该次插入。所有 mutation 都返回 primitive int status，调用方不得忽略失败。
- 移动系统在 movement commit 阶段用 `stage_position(handle_id, committed_position, phase_lease_id)` 写入本帧唯一待提交位置；同一 handle 多次 stage 时最后一次值覆盖前值。`sync(phase_lease_id)` 原子应用 pending insert 与 staged position，成功后才发布新的 committed snapshot。
- 具体实现模式（每帧清空重建 vs 增量更新）→ **ADR 待定**，不在此规定。GDD 只约束行为结果：查询得到的实体集合 = 此刻该半径内确实存在的实体。
- 单线程固定阶段：`spawn/despawn intent → movement/position commit → SpatialGrid.sync → query/collision → damage resolution → deferred removals → authoritative collection commit → optional pause barrier`。查询不得发生在 `sync` 中途；同帧死亡/回收在 deferred-removal 阶段立即从网格移除并同步 owner collection 后才允许暂停或下一次查询。
- 所有公开 API 都必须在主线程调用。`init(...)`、`get_config_snapshot_id()`、`reset_to_inactive()`、`teardown()` 是无 lease 的 Scene Flow lifecycle/diagnostic API，只受各自表项的main-thread与Grid state约束，因而不存在 init 前尚无 lease validation state 的 bootstrap 环。Active/Paused operational callback 必须先由 GameRoot 调用 `begin_phase(phase,tick_revision,out_lease)`：Grid 以 checked monotonic increment 生成非零 signed 64-bit `lease_id`，在内部登记 `{lease_id,grid_epoch,tick_revision,phase,open=true}`，并写入 caller-owned `SpatialLeaseBuffer`；同一 Grid 同时最多一个 open lease，禁止嵌套/重入。callback 采用 single-exit cleanup，最终调用 `end_phase(lease_id)`；缓存旧 ID、缺失/关闭 ID、错误 epoch/revision/phase 均返回 `PHASE_ERROR`。这只是**同进程调度协调令牌，不是安全 capability**：signed int 可被同进程代码观察或猜测，Grid 不声称抵御恶意调用者；“只有 GameRoot 调 begin/end”由依赖注入、scene ownership 与 code review 保证。禁止可变共享 Object token；参与者不得在自主 `_physics_process` 开 phase 或调用 Grid，也不能依赖未声明的 Node 执行顺序。暂停控制器使用可在 SceneTree pause 下运行的明确 process mode；战斗参与者使用 pausable mode。
- `phase` 固定为 primitive enum：`SPAWN_INTENT`、`MOVEMENT_COMMIT`、`GRID_SYNC`、`QUERY`、`QUERY_CONSUME`、`DEFERRED_REMOVAL`、`POST_DEFERRED_BARRIER`、`PAUSE_READ`、`RESUME_EXCLUSIVE`。Active phase 在同一 `tick_revision` 内必须按 R3 顺序前进且每种至多开启一次；无工作 phase 也由 GameRoot 显式 begin/end 留下 trace。`init` 成功后固定 `expected_tick_revision=1`、`expected_phase=SPAWN_INTENT`、`snapshot_revision=0`。Active `begin_phase` 只校验 expected pair/no-open 并打开 lease，**不推进** expected pair；只有 matching `end_phase` 才按上述 Active phase 顺序推进。`GRID_SYNC` 只有在 sync=`OK` 时以 checked increment 发布新的 `snapshot_revision`；tick 与 snapshot 是独立单调计数器，数值不要求相等。`POST_DEFERRED_BARRIER` 的 matching end 以 checked increment 生成 next `expected_tick_revision` 并把 phase 重置为 `SPAWN_INTENT`，即使 request_pause 已使 top state 进入 Frozen，也保存该 pair 供恢复后使用。任一 operational/fatal consumer failure 后 GameRoot 仍执行 matching end 做清理，但立即进入 ControlledGameplayFault且不得再 begin，因此内部 phase 推进不可被 gameplay 观察。Active lease/tick/sync-snapshot increment，或 Paused begin/prepare allocator 耗尽时均返回 `ID_EXHAUSTED`，完成已有 matching lease cleanup 后进入 ControlledGameplayFault。唯一清理例外是 `arm_resume_commit` 的 snapshot precheck 耗尽：保持 Prepared，只允许 matching abort/end auto-abort；清理完成后 GameRoot 进入 ControlledGameplayFault，不得重试 resume。
- PausedFrozen 可在同一 frozen `snapshot_revision` 上开启多次**不重叠**的 `PAUSE_READ`，也可开启一次 `RESUME_EXCLUSIVE`；Paused begin 的 revision 参数必须等于 frozen `snapshot_revision`，不改变已保存的 next Active expected pair。RESUME_EXCLUSIVE 一旦 open，同 lease 内才能 prepare/arm/publish/abort，且关闭前禁止新的 pause-read。PausedPrepared/PausedArmed 不接受新的 `begin_phase`。成功 publish 以 arm 时预检的 checked next value发布 `snapshot_revision`；matching resume `end_phase` 只关闭旧 resume lease，不再次增加 tick/snapshot，并保留 barrier 已生成的 next Active `(tick,SPAWN_INTENT)`。lease 未关闭前虽 top state已 Active，任何新 begin 仍因 single-open rule返回 `PHASE_ERROR`。

**R4 — 半径查询**
- 生产行为接口：`query_circle_into(center: Vector2, radius: float, type_filter: int, out_results: SpatialQueryBuffer, phase_lease_id: int) -> int`；返回值是 primitive `SpatialStatus`。`SpatialQueryBuffer` 是调用方在 Active 前创建并跨帧复用的 carrier，内部持有固定容量 `PackedInt64Array handle_ids` 与标量 `count/required_capacity`。status=`OK` 时 `[0,count)` 权威；status=`BUFFER_TOO_SMALL` 时仅 `required_capacity` 权威；其他 status 下均无权威结果。消费者必须用预声明整数索引的 `while i < out.count` 遍历，禁止 `range(out.count)`、`slice()` 或复制成新 Array；`range()` 会为每次消费构造新的迭代容器，违反稳态零分配契约。允许分配新 Array 的便利接口仅限 DEBUG/tooling，不得进入 gameplay/physics 热路径。
- buffer 容量按 Config snapshot中每个已知 type bit 的注册上限求和：`required_capacity(filter)=Σ max_registered[type]`。条目只能有一个 type bit，因此不会重复计数；schema v1固定ENEMY=303、PROJECTILE=0、DROP=300、ALL=603。初始化集成校验必须证明容量覆盖调用点固定 filter 的最大结果数并与snapshot ID一致。容量不足时dev assert；release返回`BUFFER_TOO_SMALL`、写入`required_capacity`、将`count=0`且旧handle内容不具权威性，不把部分集合伪装成成功结果。合法生产配置不得在运行时扩容或静默截断。
- 查询覆盖的格范围由 `radius` 与 `CELL_SIZE` 决定（见 Formulas F1）。
- 查询复杂度：期望 O(覆盖格数 + 候选数)，最坏情况下一个格聚集全部条目时仍为 O(N)；"≤9 格"从来不是帧预算证明。
- debug/test instrumentation 为 SpatialGrid 实例级只读诊断：`last_query_cells_visited`、`last_query_candidates_examined`、`last_query_results_count`。release 不承诺编译删除成员；默认关闭逐查询写入，仅保留限频聚合计数。
- 查询中心必须位于 `world_safe_aabb` 内；半径必须 finite且非负。合法半径可以大于`CELL_SIZE`，release不得clamp或缩小。F2先checked计算相交虚拟格span；若span乘积超过`MAX_QUERY_CELLS_ENUMERATED`或转换可能溢出，改扫描全部active entries（至多1000）并用同一canonical距离过滤，禁止遍历巨大空域。`max_query_radius`仅用于配置审计、CELL_SIZE候选与benchmark，不是正确性上限。
- `query_circle_into` 写入顺序不构成契约；调用方和测试按 stable handle ID 集合消费。需要碰撞形状相交时，调用方用 `gameplay_radius + max_enemy_bound_radius` 做宽相扩张，再以真实 shape/swept test 窄相裁决。
- SpatialGrid 只以条目的 `committed_gameplay_center` 做点查询。Enemy/Drop 等类型的 `conservative_bound_radius` 由其 Config/注册契约提供；消费者必须先扩张宽相，再执行真实 shape/swept 窄相。候选集合不得直接等同最终命中集合。

**R5 — 最近敌人查询**
- 辅助接口：`query_nearest_into(center: Vector2, max_radius: float, type_filter: int, out_result: SpatialNearestBuffer, phase_lease_id: int) -> int`；返回 primitive `SpatialStatus`。调用方在 Active 前预分配并复用 `SpatialNearestBuffer`，其标量字段为 `has_handle` 与 `handle_id`；仅 status=`OK` 时字段权威，`has_handle=false` 才表示半径内确实无匹配条目。
- 用于自动索敌（飞剑锁定最近敌人）。MVP 实现必须扫描 F2 选定路径的**全部相交occupied cells候选**，或在enumeration ceiling触发时扫描全部active entries，以 F2 的规范距离值取全局最小。禁止“螺旋遇到首个实体即返回”；任何未来early-exit都必须先证明未扫描格的距离下界并修订GDD/AC。
- 本接口的距离语义固定为 **committed gameplay center 到查询 center 的中心距离**，不是 shape distance。需要 shape-nearest 或候选窄相回退的消费者必须先调用 circle_into，再自行过滤/排序；不得把本接口结果解释成最近形状。
- 等距时返回 `registration_sequence` 更小的有效 handle；该稳定键不受 bucket 容器、clear-rebuild 顺序或对象池复用影响。若半径内无匹配实体，返回 `status=OK,has_handle=false`。

**R6 — 插入/移除**
- 公开 `SpatialHandleId` 是非零、进程内单调递增且永不复用的 signed 64-bit primitive int；0 表示无 handle。`registration_sequence == handle_id`，因此稳定 tie-break 无需额外对象。Grid 内部 `RegistrationEntry` 保存 `{grid_epoch,slot_id,generation,handle_id}`、注册时的**直接 Node identity 引用**、仅作诊断/paused carrier 比对的 `instance_id`、单一 `type_mask`、`committed_gameplay_center`、当前 cell/slot 与 `pending/active/suspended` 状态。MVP registrant 必须是 Node-derived pooled gameplay object；Node 不以 RefCounted 引用计数管理，保存该 identity 不阻止 `queue_free()`，而已释放引用也不会因 ObjectDB 的 instance ID 回收而重定向到新对象。resolve 禁止仅凭 `instance_from_id(instance_id)` 取回对象；必须先验证 entry 保存的 identity `is_instance_valid()`、未 `is_queued_for_deletion()`，再验证其当前 instance ID 仍等于诊断值。不得以强持有 `RefCounted` 延长 gameplay 对象生命周期。**WeakRef 评估（godot-specialist ③ 闭环）**：已评估改用 `WeakRef`（`weakref(node)`）。直接持有 Node identity 与 WeakRef 同为弱引用语义：Node 非 RefCounted、不参与引用计数，`queue_free()` 后 `is_instance_valid(saved_node)=false` 且不重定向到新对象，与 `WeakRef.get_ref()` 返 `null` 等价；直接持有省去一次间接解引用与 WeakRef 对象分配，且 resolve 已强制 saved identity + 当前 instance ID 双校验，WeakRef 无额外安全收益。故不采用 WeakRef。
- handle allocator、grid epoch、slot generation 均使用 checked increment，永不回绕。slot generation 即将耗尽时该 slot 在本 epoch 永久退休；handle ID 或 grid epoch 耗尽时返回 `ID_EXHAUSTED`，拒绝 insert/re-init 并进入 controlled fault，不复用旧值。teardown 先使当前 epoch 与全部 lookup 失效，再释放条目，从行为上排除 ABA 复活。
- `insert_into(object, type_mask, position, out_handle: SpatialHandleBuffer, phase_lease_id: int) -> int` 创建 pending handle；调用方预分配 `SpatialHandleBuffer`。仅 status=`OK/OK_NOOP/OK_REPLACED` 时 `out_handle.handle_id` 权威。fresh object 插入失败时从未建立 Grid ownership/registration，caller 保持对象所有权并可安全返池。完全相同的重复 insert 返回 `OK_NOOP` 与原 handle。**replace 只允许旧 entry 仍为 pending**：不同位置/type 的新记录完整验证成功后，旧 pending handle 立即 stale、创建新 pending handle并返回 `OK_REPLACED`；验证失败则旧 pending 保持不变。旧 entry 为 active/suspended 时，不同位置/type 的重复 insert 固定返回 `INVALID_ARGUMENT`，旧 handle、committed snapshot 与 staged workspace 不变：位置变化必须 `stage_position`，type 变化必须在 owner 接受查询空窗后显式 `remove(old) → insert(new)`。因此 `SYNC_FAILED` 永远可以保留旧 committed snapshot，不会出现“snapshot 仍含已被 replace 失效的 handle”的矛盾。
- `remove(handle)` 使用 entry 记录的旧 cell/slot **立即**失效并从查询结果消失，不按对象当前坐标反推 bucket；clear-rebuild 实现也必须用 tombstone 或即时表移除满足该行为。
- 对象池顺序固定为：同一intent的`LifecycleCommitJournal` row按`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`单调推进；实际调用顺序为`remove(handle)=OK→row=GRID_REMOVED→Object Pool unbind(handle)→row=POOL_UNBOUND→pool release/reset or retire→row=POOL_RELEASED|POOL_RETIRED`。重新借出后创建新borrow generation/handle，再insert。**remove-before-free 是 lifecycle owner 的 BLOCKING 义务**：任何active/pending/suspended registrant都不得先`queue_free`、返池或重新借出；fresh insert failure可release，remove failure不得unbind/release，pending`OK_REPLACED`原子替换Pool binding；完整矩阵以`object-pooling.md` R5为准。`remove=OK`是不可回滚事实：若随后unbind/release/reset失败，旧handle仍stale；GameRoot在首个side effect前arm Phase6AuthorityBatchPlan，visible committed row=0时0 publish、>0时matching end或fault convergence恰一次batch publish，绝不能逐step发布或把旧注册“复活”。若owner违约，entry直接identity必须令resolve返回`OBJECT_INVALID`并触发phase failure/`ControlledGameplayFault`，不得伪称整phase回滚，也不得用可能已回收的instance ID解析另一个Node。失效generation、已回收或queued-for-deletion对象不得出现在结果中。
- SpatialGrid 从不拥有 gameplay 对象的延迟回收。GameRoot/生命周期 owner 负责 pending intent 与 pool release；SpatialGrid 只提交或失效索引。
- handle 校验拆成两层：`lookup_mutable_slot(handle_id, allowed_states)` 校验 epoch/handle/slot/generation，供 Grid 内部 mutation 使用并可按 API 允许 pending/active/suspended；`resolve_active_into(handle_id,out_ref,phase_lease_id)` 仅允许 active，另验证 entry 的直接 Node identity、queued-for-deletion 与诊断 instance ID 一致性，供查询消费者实际使用。stage 允许 pending/active/suspended；remove 允许 pending/active/suspended；query/consumer resolve 只允许 active；removed/旧 epoch 一律 `STALE_HANDLE`。查询返回 handle 后，下游在实际使用对象前必须 resolve，避免查询结束后的同帧 deferred removal 产生 stale use。
- 若走增量更新，O(1) 删除需要 `entry → (cell, slot)` + swap-remove 并修正被交换条目的 slot，或等价 O(1) 容器；仅有 `entity → cell` 反向索引不够。

**R7 — 有限世界域边界处理**
- MVP正式采用Stage V2的大型有限`world_safe_aabb`；它不作为可见arena，不做循环拼接、镜像、位置wrap或runtime origin rebasing。
- 查询圆越过world safe边界时，只考虑域内已注册entry；候选距离仍以真实center计算，不从对侧返回实体。
- `index_margin`与arena suspension语义从V2删除。insert位置必须完整位于world safe domain；active/pending/suspended条目的staged位置越域返回`POSITION_OUT_OF_RANGE`并保持旧snapshot，随后GameRoot进入ControlledGameplayFault。不得把非法位置clamp进边界格、悄悄suspend或继续发布旧位置当作成功。
- Config的Stage reachability proof保证正常局不会到达该边界；因此越域不是普通可恢复玩法分支。Paused quarantine只处理生命周期暂停，不用于吸收世界越域。

**R8 — 约束：高频附近查询不得遍历全场**
- 任何实际查询consumer（DamageSystem/EnemySystem/ProjectileSystem/DropSystem/Weapon/TargetingSystem）执行每帧或高频"附近实体"查询时，必须通过 SpatialGrid，**禁止**遍历全场活动列表（设计方案 15.4 硬性要求）。PlayerController的复活评分例外读取Enemy/Hazard owner发布的定容全量snapshot，不是Grid query，也不授权普通稳态全场遍历。
- 低频、事件触发且语义本来就是全局的效果（如"引灵符吸取当前场上全部灵气"）由拥有权系统遍历其权威 active collection；不得伪装成超大半径热路径查询，也不得促使 SpatialGrid 暴露通用 `get_all_entities()`。
- 此约束是 SpatialGrid 作为独立 Foundation 系统存在的核心理由。

**R9 — Public status、carrier 与 release 消费策略**
- **基类冻结（godot-specialist R3 闭环）**：`SpatialGrid` 与所有公开 carrier（`SpatialQueryBuffer`/`SpatialNearestBuffer`/`SpatialHandleBuffer`/`SpatialResolveBuffer`/`SpatialLeaseBuffer`/`SpatialRemapBuffer`/`AuthoritativeRegistrationBuffer`）均冻结为 **`RefCounted`（非 `Node`）**——不进 SceneTree、不挂父子节点、无 `_ready`/`_physics_process`/`_process` 回调、不被 `SceneTree` 暂停传播命中。Grid 自身不驱动任何帧；全部 phase 推进（`begin_phase`/`end_phase`/`sync`/query/insert/remove/resume 三阶段事务）严格由 `GameRoot`（`Node`，`PROCESS_MODE_ALWAYS`，并以 top state + `SceneTree.paused` + explicit gate 决定是否调用）在主线程显式驱动。GameRoot 只在 `BATTLE_ACTIVE` 传 `gameplay_dt=1/60`；`PAUSE_PENDING` 仅允许一个 `gameplay_dt=0` 的技术 drain tick，其他状态不得推进 Grid gameplay phase。选 `RefCounted` 而非 `Node`/`Resource` 的理由：① carrier 是定容 SoA 数据载体而非场景实体，`Node` 的 transform/signal/processing 开销纯负担；② `RefCounted` 支持 `@tool`/运行时构造且无 SceneTree 耦合，符合"Grid 不创建 carrier、owner 在 Active 前创建并跨帧复用"的 ownership 契约；③ 避免 `Resource` 的 `.tres` 序列化语义干扰（carrier 是运行时对象，非持久化资产）。registrant 仍是 `Node`-derived pooled gameplay object（R2），与 carrier 基类无关。具体 `class_name` 与私有容器布局由 ADR 落地，但基类约束在此冻结，ADR 不得改回 `Node`。
- `SpatialStatus` 固定为 primitive int enum：`OK`、`OK_NOOP`、`OK_REPLACED`、`INVALID_ARGUMENT`、`INVALID_BENCHMARK_INPUT`、`INIT_LIMIT_EXCEEDED`、`POSITION_OUT_OF_RANGE`、`CAPACITY_EXCEEDED`、`BUFFER_TOO_SMALL`、`PENDING_WORK`、`WRONG_STATE`、`PAUSED`、`PHASE_ERROR`、`STALE_HANDLE`、`OBJECT_INVALID`、`SYNC_FAILED`、`REBUILD_FAILED`、`ID_EXHAUSTED`。前三项为 success class，其余为 failure class；V1的`STAGED_FOR_SUSPENSION`不再用于世界越域。调用方按 enum 判定，不按字符串日志判定。
- 所有 out carrier（Query/Nearest/Handle/Resolve/Lease/Remap）均由 owner 在 Active 前创建、定容并复用；Grid 不创建 carrier、不替换其内部数组。carrier 后置条件严格服从 R9 precedence：① main-thread/state/substate/lease 的 early failure **不得读取或写入 carrier**，其物理内容保持原样但全部不权威；②进入 carrier 层后才验证 class、PackedArray 元素类型、parallel-array size 与声明 capacity，malformed carrier 返回 `INVALID_ARGUMENT`、保持原样且不消耗 ID；③ carrier 验证成功后才将适用标量复位为 `count=0/required_capacity=0/has_handle=false/handle_id=0/lease_id=0/transaction_id=0/object=null`，随后再验证 gameplay arguments/entry，因此这些后续 failure 保持已复位零值且不权威。唯一 failure-output 例外是 `BUFFER_TOO_SMALL`：此时 `count=0`、旧数组槽位不权威，但 `required_capacity` 是权威诊断值。测试必须断言 carrier 与内部数组 identity/capacity 不变，并以污染标量覆盖三层 failure。
- Grid 私有的 slot/entry/staging、bucket 与 Paused candidate build workspace 必须在进入 Active 前按批准上限预分配；GameRoot 拥有并预分配 authoritative input、out carrier 与 owner remap staging。Active query、insert/stage/remove/sync 以及 Paused resume prepare/publish 均不得因容器增长分配。ADR 可以选择私有容器，但不能把首次遇到新 cell 的 allocation 延后到 gameplay tick。
- 任一 query failure、`resolve_active_into` failure，或 consumer GDD 明确声明的 fatal narrowphase/domain failure，都必须中止**整个本 tick query/collision phase**，而不只是当前 consumer。所有 consumer 只写本 phase 私有 resolution staging；全部 query、resolve 与窄相成功后，GameRoot 才一次发布 damage/pickup/targeting 结果。普通窄相“不相交/未命中”是合法结果而非 failure。任一较晚 fatal failure 必须丢弃包括先前成功 consumer 在内的全部 staging、关闭 open lease，再进入 `ControlledGameplayFault`；不得映射为空集合、部分集合或缩小半径。MVP 当前没有批准 fallback。该协议已由 `game-root-scene-flow.md` R5/AC-B3承接；实现与集成证据仍是 BLOCKING gate。
- `CAPACITY_EXCEEDED` 只允许作为 fresh insert 的**发布前内容抑制结果**：SpawnDirector 在 borrow/可见化前先以 Config snapshot 的 ENEMY cap=303 做 admission check，并永久为 4 Elite + 1 Boss 保留 5 个槽，普通怪 active+pending 达 298 后不再借出/发布新普通怪。若 admission 与 insert 间仍因同 phase 排序得到 `CAPACITY_EXCEEDED`，caller 必须取消该 spawn intent、保持对象不进 active collection/SceneTree 可见分支并安全返池；现有战斗继续，telemetry 记录 suppressed spawn。阶段必需的 Elite/Boss 命中该 status，或任何 caller 已发布对象后才处理该 status，均是 contract violation：先撤销未发布 candidate并进入 `ControlledGameplayFault`。DROP 等其他类型由各 owner 用同一“先准入、后发布”协议处理。任何情况下都不得留下可见但不可索引实体。
- 生命周期后置条件按操作区分：fresh、从未注册成功的insert failure由caller继续拥有，可返池；pending replace failure保留旧注册且不得释放；remove failure不得释放目标；remove success后owner才可release/queue_free，并推进同一exact-once journal row；`SYNC_FAILED`保持上一个committed snapshot，pending/staged workspace不清空且对象不得按未发布状态推进生命周期，并进入ControlledGameplayFault。Phase 6不是全阶段原子回滚：失败前已推进的rows继续有效，尚未开始的条目不执行；GameRoot用这些rows更新inactive bank，visible committed row=0时不publish、>0时matching end或fault convergence恰一次publish后fault。Paused mutation返回`PAUSED`时frozen registrant必须quarantine到resume publish或teardown，禁止release/reborrow。warning rate-limit key固定为`(status,api,grid_epoch)`，每epoch最多一次；R2未知mask warning例外key为`(unknown_mask_value,api,grid_epoch)`。
- `ControlledGameplayFault` 的玩家可见与持久化行为是本系统硬依赖：进入后立即冻结input/AI/spawn/timer/damage与fault tick新reward publication。若此前尚未seal正常终局，本局Outcome为`TECHNICAL_ABORT`；若`VICTORY/DEFEAT/ABANDONED`已seal，后续Grid/cleanup fault只写独立`RunCompletionStatusV1.completion_fault_code`，Save fault只写attempt状态，不得改写`outcome_kind`。GameRoot按fault前`CommittedGameplayFactLedger`已提交事实构建Outcome，并按Save attempt/reconcile/tombstone策略处理；Grid既不计算也不改写结果。权威细节由`game-root-scene-flow.md` R8-R9维护。

公开 API 的状态与后置条件固定如下；表外组合一律 failure 且内部状态不变：

| API | 合法 Grid/phase | 合法 entry 状态 | success | 主要 failure 与后置条件 |
|---|---|---|---|---|
| `init(config_snapshot,stage_spatial_config)` | Inactive / main thread / no open lease | n/a | `OK`，复制非零snapshot ID/limits并一次性分配 Grid workspace 与 operational lease validation state | `INVALID_ARGUMENT/INIT_LIMIT_EXCEEDED/ID_EXHAUSTED`；snapshot ID=0并保持 Inactive |
| `get_config_snapshot_id()` | Inactive/Active/Paused/TornDown / main thread | n/a | 返回只读scalar；成功init后至teardown前为非零，其他状态为0 | 非主线程=`PHASE_ERROR`；不改变状态 |
| `begin_phase(phase,tick_revision,out_lease)` / `end_phase(lease_id)` | Active 或合法 Paused substate / main thread | n/a | begin 登记唯一 open lease；end 精确关闭 | begin 重入/非法 phase/revision、end 错 ID均 `PHASE_ERROR`；begin allocator exhaustion=`ID_EXHAUSTED`且不打开 lease；matching end 推进所需 revision exhaustion=`ID_EXHAUSTED`、关闭 lease、保持原 expected pair并进入 ControlledGameplayFault；错误 ID end 不关闭当前 lease；Prepared/Armed 下 matching end 先 auto-abort candidate 再关闭 |
| `insert_into(...)` | Active / spawn-intent | 无注册；相同注册；或 pending replace | `OK/OK_NOOP/OK_REPLACED`；写 out handle | fresh 达 per-type/total cap=`CAPACITY_EXCEEDED`，保持未注册且仅允许 caller 按发布前抑制协议处理；active/suspended 的变化式重复 insert=`INVALID_ARGUMENT`；其他验证 failure 保持旧注册，out 权威标量清零 |
| `stage_position(...)` | Active / movement-commit | pending/active/suspended | `OK`；只写 private staged workspace | `POSITION_OUT_OF_RANGE/STALE_HANDLE/PHASE_ERROR`；不改变 staged/committed 数据，phase进入fault convergence |
| `remove(...)` | Active / spawn-intent 或 deferred-removal | pending/active/suspended | `OK`；handle 立即失效 | `STALE_HANDLE/OBJECT_INVALID/PHASE_ERROR`；no-op，owner 不得 release 目标 |
| `sync(...)` | Active / grid-sync | 全部 pending/staged | `OK`；以 checked increment 原子发布下一 snapshot | `SYNC_FAILED/PHASE_ERROR`；旧 snapshot 权威，workspace 保留。snapshot revision 耗尽=`ID_EXHAUSTED`，同样不发布 candidate，matching end cleanup 后进入 ControlledGameplayFault |
| `query_circle_into/query_nearest_into` | Active / query；PausedFrozen / pause-read | 仅扫描 active frozen entries | `OK`；out carrier 权威 | state/lease early failure保持 carrier 原样；carrier/gameplay `INVALID_ARGUMENT` 分别保持原样/复位后零值；`BUFFER_TOO_SMALL` 仅 `required_capacity` 权威；全部 failure 回滚整个 query/collision phase |
| `resolve_active_into(...)` | Active / query-consume；PausedFrozen / pause-read | active | `OK`；out object 权威 | state/lease early failure保持 carrier 原样；carrier 验证后 `STALE_HANDLE/OBJECT_INVALID` 令 object=null 且触发整 phase 回滚 |
| `request_pause(phase_lease_id)` | Active / post-deferred tick barrier | 不允许 pending/staged 未提交 | `OK`；进入 PausedFrozen | `PENDING_WORK/PHASE_ERROR`；保持 Active，不发布半暂停 |
| `resume_from(input,out_remap,resume_lease_id)` | PausedFrozen / resume-exclusive | 见 Paused transaction | `OK`；生成 private candidate + transaction ID，进入 PausedPrepared | validation/build failure 丢弃 candidate并保持 Frozen；已保留的新 ID burn |
| `arm_resume_commit(transaction_id,resume_lease_id)` | PausedPrepared / 同一 resume-exclusive lease | matching candidate | `OK`；完成全部 Grid 最终校验、预检 next snapshot revision并进入 PausedArmed | transaction/lease 不匹配=`PHASE_ERROR`；revision 耗尽=`ID_EXHAUSTED`、保持 Prepared/旧快照，只允许 matching abort/end auto-abort，随后进入 ControlledGameplayFault且不得重试 resume |
| `publish_resume(transaction_id,resume_lease_id)` | PausedArmed / 同一 resume-exclusive lease | owner staging 已完成可回滚引用交换 | matching 调用必为 `OK`；只做预分配引用交换，发布 candidate/revision并进入 Active | transaction/lease 不匹配=`PHASE_ERROR` 且保持 Armed；不存在 matching publish 的其他 failure |
| `abort_resume(transaction_id,resume_lease_id)` | PausedPrepared/PausedArmed / 同一 lease | matching candidate | `OK`；丢弃 candidate并回 PausedFrozen | transaction/lease 不匹配=`PHASE_ERROR`；旧快照不变 |
| `teardown()` | Active/Paused / no open lease；TornDown / idempotent | 任意 | 首次 `OK`，旧 handles 全失效、config snapshot ID清零后TornDown；重复为 `OK_NOOP` | open lease=`PHASE_ERROR`；其他非法 state=`WRONG_STATE` |
| `reset_to_inactive()` | TornDown / main thread / no open lease | n/a | `OK`；清空容器引用与 instrumentation，进入 Inactive | 其他 state=`WRONG_STATE` |

status precedence 固定为：`main-thread → top-level Grid state/Paused substate → open lease/phase → carrier → gameplay argument → entry/object`，且每层的 carrier 物理后置条件按上段执行。非主线程统一 `PHASE_ERROR`；Paused mutation/sync 在读取 lease、参数或 entry 前统一返回 `PAUSED`；Inactive/TornDown 时除表中 lifecycle API 外统一返回 `WRONG_STATE`；进入合法 state/substate 后，缺失/关闭/错误 lease 返回 `PHASE_ERROR`；其后才判 carrier/gameplay `INVALID_ARGUMENT/BUFFER_TOO_SMALL`，最后判 `STALE_HANDLE/OBJECT_INVALID`。PausedFrozen + open RESUME_EXCLUSIVE 调 query/resolve 是合法 substate 下 phase 不匹配，返回 `PHASE_ERROR`；PausedPrepared/PausedArmed 对 query/resolve 是非法 substate，返回 `WRONG_STATE`。例外只有不消费 lease 的 `init/get_config_snapshot_id/begin_phase/end_phase/teardown/reset_to_inactive`，按其表项检查。成功 publish 后重复 `publish_resume` 因已处 Active，固定 `WRONG_STATE`。

**R10 — Consumer geometry contract**

> **命名等价声明（systems-designer B1 闭环）**：R10 文本中出现的 `max_target_bound` 与本 GDD/registry 别处使用的 `max_enemy_bound` 是**同一个保守形状包围半径**——MVP 所有查询目标类型固定为 ENEMY，故 `max_target_bound ≡ max_enemy_bound (when target_type == ENEMY)`。registry 以 `max_enemy_bound` 为权威单一注册名（[[design/registry/entities.yaml]]）；本 GDD 统一改用 `max_enemy_bound`，保留 `max_target_bound` 仅作此等价声明的别名说明，防止"两个名两个真相源"。若未来 Projectile/Damage 查询目标扩展到非 ENEMY 类型（如掉落物、友方），必须为该类型注册独立的 `<type>_bound` 而非复用 `max_target_bound` 名。

- Damage/AoE 使用 `effect_radius + max_enemy_bound` 做 circle broadphase，再执行真实 shape narrowphase。
- Player pickup 在 MVP 固定为 **中心点进入拾取圆**：Drop 的 `committed_gameplay_center` 即拾取点，因此只传 `pickup_radius`，不加 drop bound、不做 shape pickup。若后续改为形状相交，必须同时修订 broadphase 与 narrowphase，不能只扩张半径。
- Projectile swept broadphase 覆盖上一 committed position `p0` 到当前 position `p1` 的整段，且不允许虚构一个 float64 Vector 类型。先读取 `p0x64=float(p0.x)`、`p0y64=float(p0.y)`、`p1x64=float(p1.x)`、`p1y64=float(p1.y)`，再按固定顺序计算 `mid_x64=0.5×p0x64+0.5×p1x64`、`mid_y64=0.5×p0y64+0.5×p1y64`；构造唯一实际查询中心 `swept_center=Vector2(mid_x64,mid_y64)`，随后读回 `center_x64=float(swept_center.x)`、`center_y64=float(swept_center.y)`。`segment_length=spatial_distance_components(p0x64,p0y64,p1x64,p1y64)`，`midpoint_cast_error=spatial_distance_components(mid_x64,mid_y64,center_x64,center_y64)`；不得调用只接受 Vector2 的 helper 伪装 `mid64`，也不得先在 real_t Vector2 中求中点。
- MVP 冻结为 **tick-end discrete target snapshot**：Grid 在本 tick movement commit + sync 后查询 ENEMY，宽相与 swept narrowphase 都把目标 shape 固定在其当前 committed center/shape，不追溯目标从上一 tick 到当前 tick 的运动段。因此 `target_motion_bound=0.0`，registry 名称为 `max_target_motion_bound=0.0`。这是一项明确的 MVP 碰撞采样语义，而不是连续相对运动保证；以后若 Projectile GDD 升级为 relative sweep，必须同时加入目标上一位置、保守非零 motion bound、relative swept narrowphase 与新 golden tests，不能只改 registry 数字。
- 最终以 checked finite arithmetic 得 `swept_query_radius=0.5×segment_length+midpoint_cast_error+projectile_bound+max_enemy_bound+target_motion_bound`。MVP 标准 real_t32 且 R1 `|coordinate|≤1_000_000` 时，中点 cast 每分量误差上界为 `1/32`，故 registry 使用保守 `max_midpoint_cast_error=sqrt(2)/32=0.04419417382415922`；运行时仍使用逐次实际 `midpoint_cast_error`，不能总加上界替代。查询 ENEMY 后执行上述 tick-end discrete swept shape narrowphase；任一加法非 finite/超 R1 domain 返回 `INVALID_ARGUMENT`，不得静默少扩。若 ADR 选择 swept AABB/capsule API，候选集合必须与上述保守定义等价且不得漏段中静态快照目标。
- Enemy separation 使用 `sep_radius+max_separation_radius` 宽相（EnemySystem §4.2 权威形式；`max_separation_radius` 见 enemy §4.6，registry 别名 `separation_radius`；**非** `max_enemy_bound`——后者是 shape 包围半径与 sep_radius 独立 per-type 参数，R4 根因3 B-1-R 修正原 `separation_radius+max_enemy_bound` 误用）、排除自身 handle 后再算实际分离；任何有限目标数/穿透数效果不得按 bucket 返回顺序取前 N 个。

### States and Transitions

SpatialGrid 本身无业务状态机，但其生命周期跟随战斗场景。状态如下：

| 状态 | 触发 | 行为 |
|------|------|------|
| **Inactive** | 初始 / 非战斗场景（洞府首页、结算页） | 网格不分配、不更新；除合法 init 外，operational API 返回 `WRONG_STATE`，不把空集合伪装成有效查询 |
| **Active** | 进入战斗场景 | 初始化网格覆盖竞技场，每帧更新实体位置，响应查询 |
| **PausedFrozen** | GameRoot 在完整 tick 的 deferred removals 与 authoritative collection commit 后，于 barrier `request_pause` | frozen snapshot 与 authoritative collection 共用 `snapshot_revision`；允许 pause-read lease 或一次 resume-exclusive lease。mutation/sync 返回 `PAUSED` |
| **PausedPrepared(tx)** | `resume_from` validate/reserve/build 成功 | frozen snapshot 仍权威；private candidate/remap 与唯一 transaction ID 存在；只允许 matching arm/abort/end-phase auto-abort |
| **PausedArmed(tx)** | `arm_resume_commit` 成功 | Grid candidate 已最终校验但尚未发布；consumer phase 仍关闭；只允许 matching publish/abort/end-phase auto-abort |
| **Torn Down** | 退出战斗（胜利/失败/退场） | 网格资源已释放且旧 handle 全失效；等待 Scene Flow 调用 `reset_to_inactive()`，不隐式回到 Inactive |

转换：`Inactive --init--> Active --request_pause--> PausedFrozen --resume_from--> PausedPrepared --arm--> PausedArmed --publish--> Active`；`Prepared/Armed --abort 或 end_phase auto-abort--> Frozen`；`Active/任一 Paused substate --teardown(no open lease)--> Torn Down --reset_to_inactive--> Inactive`。

### Interactions with Other Systems

| 系统 | 方向 | 数据流 | 接口 |
|------|------|--------|------|
| EnemySystem | 上游→SpatialGrid | 敌人位置/进入/死亡 | `insert_into(enemy, ENEMY, pos, handle_out, lease_id)` / `stage_position(handle_id, pos, lease_id)` / `remove(handle_id, lease_id)` |
| ProjectileSystem | 查询调用方 | 上一/当前 committed position 形成 swept segment；目标按 tick-end committed snapshot 固定，默认不注册投射物 | `query_circle_into(swept_center, 0.5×segment_length+midpoint_cast_error+projectile_bound+max_enemy_bound+0.0, ENEMY, buffer, lease_id)` + tick-end discrete swept narrowphase |
| DropSystem | 上游→SpatialGrid | 掉落物位置/生成/吸取 | `insert_into(drop, DROP, pos, handle_out, lease_id)` / `stage_position(handle_id, pos, lease_id)` / `remove(handle_id, lease_id)` |
| DamageSystem | SpatialGrid→下游 | 范围伤害宽相候选 | `query_circle_into(center, radius+max_bound, ENEMY, buffer, lease_id)` + shape narrowphase |
| Weapon/TargetingSystem | SpatialGrid→下游 | 读取Player已提交位置后执行中心距离自动索敌 | `query_nearest_into(player_pos, target_range, ENEMY, nearest_out, lease_id)` |
| EnemySystem（查询侧） | SpatialGrid→下游 | 敌人间分离/碰撞避免 | `query_circle_into(enemy_pos, sep_radius+max_separation_radius, ENEMY, buffer, lease_id)`（R4 根因3:原 `sep_radius+enemy_bound` 误用 shape bound,改 §4.2 权威形式） |
| ProjectileSystem（查询侧） | SpatialGrid→下游 | 返回覆盖整段运动的宽相敌人候选；下游执行 swept shape 窄相 | `query_circle_into(swept_center, swept_query_radius, ENEMY, buffer, lease_id)` |
| GameRoot & Scene Flow | 控制 | 场景状态驱动网格 Inactive/Active/Paused/TornDown | 状态转换调用 |

**接口归属**：SpatialGrid 拥有注册、位置 staging、同步、索引失效、查询行为与 lease ID 发放/校验；GameRoot/生命周期 owner 拥有 active collection、`begin_phase/end_phase` 调度权、暂停 intent 与对象回收。Enemy/Drop 注册为被查询目标；Projectile 默认只调用覆盖 swept segment 的 ENEMY 宽相查询。Damage、Drop、Weapon/Targeting与Enemy查询侧调用 query_*；PlayerController调用数固定为0。SpatialGrid 不判定伤害、碰撞形状或全局掉落效果。

### Paused Resume Transaction

`AuthoritativeRegistrationBuffer` 是 GameRoot 在 init 时创建、容量固定为 `MAX_INDEXED_ENTRIES` 并跨暂停复用的 caller-owned SoA carrier：`prior_handle_ids: PackedInt64Array`、`object_instance_ids: PackedInt64Array`、`type_masks: PackedInt32Array`、`committed_gameplay_centers: PackedVector2Array` 与标量 `count/capacity`。第 i 条的行为 schema 为 `{prior_handle_id,object_instance_id,type_mask,committed_gameplay_center}`：`prior_handle_id=0` 表示暂停期间新 spawn；非零值必须属于 frozen registration revision 且 object identity 匹配，type 不变是 survivor、type 改变是 validated replace。输入中 object instance ID 与非零 prior handle 均不得重复，`0≤count≤capacity=MAX_INDEXED_ENTRIES`，所有位置/type/object 都必须通过与 insert 相同的验证；Grid 不保存或替换 caller 数组。

Grid 在 init 时预分配容量 `MAX_INDEXED_ENTRIES` 的 private candidate build workspace；GameRoot 预分配上述 authoritative input、容量 `2×MAX_INDEXED_ENTRIES` 的 `SpatialRemapBuffer`，以及不直接覆盖 authoritative collection/target cache 的 owner remap staging。所有 carrier 调用前都验证数组 identity、元素类型、`size==capacity` 与 parallel-array sizes 完全相等；不符返回 `INVALID_ARGUMENT` 且 Grid 不写数组。remap 用三条 `PackedInt64Array` 表示 `{object_instance_id,prior_handle_id,new_handle_id}`，另有 scalar `transaction_id`：survivor 为 old→same、removed 为 old→0、replace 为 old→new、暂停期间 new spawn 为 0→new，因此最坏为旧 1000 条全部 removed + 新 1000 条，共 2000 entries。transaction ID checked monotonic、非零、永不复用；耗尽返回 `ID_EXHAUSTED`。`resume_from(input,out_remap,resume_lease_id)` 开启三阶段事务：

1. **Prepare**：仅在 PausedFrozen + open resume-exclusive lease 合法。先完整验证 input、carrier、容量和 ID 可用性，不改 frozen snapshot；再保留 transaction/new handle ID并构建 candidate。未变化或从 suspended 恢复的 survivor保留原 `handle_id/registration_sequence`；omitted 条目 old→0；新 spawn 0→new；type 变化视为 remove+new并 old→new。成功后写完整 remap/transaction 并进入 PausedPrepared。任何已保留 handle/transaction ID 在后续 build failure/abort 时也永久 burn；旧 epoch/snapshot 不变。
2. **Arm + owner swap**：`arm_resume_commit(tx,lease)` 核对 candidate、frozen revision、lease、capacity，并 checked 计算待发布 `next_snapshot_revision`。任何可失败 Grid 校验都在此结束；failure 保持 Prepared且不改旧快照，GameRoot随后可 abort。matching arm=`OK` 后进入 PausedArmed。所有 consumer phase 关闭时，GameRoot 保存旧 authoritative collection/target-cache 引用，并把完整 staging 引用交换为当前 owner 引用；若 owner swap 自身失败，先恢复旧引用，再 `abort_resume`。
3. **Publish/abort**：owner swap 成功后调用 `publish_resume(tx,lease)`；matching Armed publish 只执行预分配 Grid candidate/revision 的引用交换，契约上**不可失败且必返回 `OK`**，随后进入 Active。owner 新引用此时成为可消费权威状态，但必须等 resume lease `end_phase` 关闭后才允许下一 Active begin。wrong transaction/lease 在交换前返回 `PHASE_ERROR`、保持 Armed；GameRoot恢复旧 owner引用后以正确 tx/lease abort。`abort_resume` 在 Prepared/Armed 均丢弃 candidate回 Frozen。若 GameRoot 在 Prepared/Armed 直接 end，Grid 先 auto-abort；Armed cleanup 路径必须先由 GameRoot恢复 owner引用。成功 publish 后重复 publish按 state-first返回 `WRONG_STATE`。

GameRoot是resume attempt schema唯一owner；Grid只提供`source_grid_snapshot_revision=g`与arm预检的`next_grid_snapshot_revision=g_next`。expected tuple在Grid publish前为`{g,p,a}`、matching Grid publish后为`{g_next,p,a}`；随后Pool publish不改变该Grid轴，authority publish才从`a→a_next`。Grid不得另建第二套authority revision字段或把合法`g→g_next`误判为漂移；Config/Input/background/geometry/pool/topology/Engine等其余轴由GameRoot在每个checkpoint核对。

这里的“原子发布”是**对 gameplay consumer 的逻辑原子性**，不是跨两个 GDScript Object 的硬件事务：唯一依据是 resume-exclusive lease 期间 consumer phase 全关闭、所有 owner 变更均为 O(1) 可回滚引用交换、失败时在开放任何 consumer 前恢复旧引用。`game-root-scene-flow.md` R7已冻结该编排；仍须由其AC-D2/D3/D4集成测试证明，SpatialGrid 单体测试不能代替。

`resume_from` 进入 carrier 层后的 duplicate、非法对象/位置、容量/ID 耗尽或内部构建失败均返回精确 failure status：Grid 回到/保持 PausedFrozen，旧 frozen snapshot、旧 epoch、旧公开 handles 与 authoritative collection revision 均不变；carrier 已验证时 `out_remap.count=0` 且不权威，state/lease 或 malformed-carrier early failure则按 R9 保持 carrier 原样。唯一允许变化是已保留的新 ID 被 burn。`arm_resume_commit` failure 保持 Prepared，wrong publish 保持 Armed，两者不得被本段误读为回 Frozen；其精确后置条件以 API 表与三阶段事务为准。暂停期间不存在 pending/staged 条目；恢复输入是唯一权威来源。Frozen registrant 在成功 publish 或 teardown 前必须 quarantine。PausedFrozen + open resume-exclusive 时 query/resolve=`PHASE_ERROR`；Prepared/Armed 时按 state-first query/resolve=`WRONG_STATE`。teardown 若仍有 open lease 先返回 `PHASE_ERROR`；GameRoot 必须 `end_phase`（必要时 auto-abort）后再 teardown。

## Formulas

本节定义5个核心公式，围绕`CELL_SIZE`、有限world domain、稀疏occupied cells与查询半径展开；`max_query_radius`是跨系统derived审计值，不是tuning knob或合法性上限。

### F1 — Signed World Cell Assignment

The cell assignment formula is:

- `cell_x=floor(world_x/CELL_SIZE)`
- `cell_y=floor(world_y/CELL_SIZE)`
- `max_abs_cell_coord=ceil(world_safe_half_extent/CELL_SIZE)`

初始化先校验world extent与CELL_SIZE finite/positive，再以checked float64除法和checked int64 conversion派生cell坐标包络；任何溢出返回`INIT_LIMIT_EXCEEDED`并保持Inactive。不会为`[-max_abs_cell_coord,+max_abs_cell_coord]²`创建dense数组，该值只用于输入验证。

| Variable | Type | Range | Description |
|---|---|---|---|
| `world_x/world_y` | real_t32→float64 | `[-H,+H]` | 真实committed center，不clamp |
| `CELL_SIZE` | float64 | `[0.01,+∞)` finite | 正方形世界格边长 |
| `cell_x/cell_y` | int64 | checked | signed稀疏cell key |
| occupied cells | int32 | `[0,MAX_INDEXED_ENTRIES]` | 只为至少一个active entry的格占slot |

GDScript必须使用显式floor语义；不得以向零截断代替。示例`CELL_SIZE=2`时，x=`-2.1/-2.0/-0.1/0/1.9/2.0`依次映射`-2/-1/-1/0/0/1`。

### F2 — Query Coverage and Sparse Fallback

查询先按F1得到中心格和`k=ceil(radius/CELL_SIZE)`，所有转换均checked。概念相交范围为`[cx-k,cx+k]×[cy-k,cy+k]`并裁到world safe domain的cell包络。

- `enumerated_cell_count=checked_mul(width_cells,height_cells)`。
- 若checked转换/乘法失败，或`enumerated_cell_count>MAX_QUERY_CELLS_ENUMERATED`，设置`scan_mode=ACTIVE_ENTRY_SCAN`并扫描至多`MAX_INDEXED_ENTRIES`个active entries。
- 否则`scan_mode=SPARSE_CELL_ENUMERATION`，枚举概念cell key但只读取occupied-cell table中的命中bucket；空格不创建对象。
- 两条路径都使用同一canonical距离过滤、type mask与handle结果语义，结果集合必须完全相同。fallback是复杂度保护，不是半径clamp。

`theoretical_cells_saturated=min(enumerated_cell_count,MAX_QUERY_CELLS_ENUMERATED+1)`只作诊断；`actual_cells_visited`在local路径表示查找的概念cell数，在fallback路径固定为0并另记`active_entries_examined`。几何输入按标准real_t32 Vector2位值存储，radius与规范距离用GDScript float64。

唯一规范标量距离原语为 `spatial_distance_components(ax64,ay64,bx64,by64)`，四个输入已是 finite float64。操作顺序固定为：`dx=ax64-bx64`、`dy=ay64-by64`、`adx=abs(dx)`、`ady=abs(dy)`、`m=max(adx,ady)`、`n=min(adx,ady)`；若 `m==0` 返回 `0.0`，否则 `q=n/m`、返回 `m*sqrt(1.0+q*q)`。Vector2 wrapper `spatial_distance_value(a,b)` 只执行 `spatial_distance_components(float(a.x),float(a.y),float(b.x),float(b.y))`。`spatial_distance_le(a,b,r)` 在 `r==0` 时仅以两个 float64 分量差均等于 0 命中，否则以 `spatial_distance_value(a,b)<=r` 判定。circle精确过滤、nearest排序、R10 segment/cast error全部必须调用该原语或wrapper；不得混入`distance_to`、`length_squared`或real_t中间距离。nearest仅在规范`d`数值相等时进入handle tie-break。local enumeration与active-entry fallback必须逐entry调用相同过滤，禁止fallback直接接受全部active entries。

| Variable | Type | Range | Description |
|---|---|---|---|
| `radius` | float64 | `[0,+∞)` finite | 合法查询半径 |
| `CELL_SIZE` | float64 | `[0.01,+∞)` finite | 同F1 |
| `MAX_QUERY_CELLS_ENUMERATED` | int32 | 262144 | local空格枚举硬上限 |
| `active_entries_examined` | int32 | `[0,1000]` | fallback实际扫描条目数 |

`radius=0`访问1个概念格；内部center且`0<radius≤CELL_SIZE`通常为9，随后25/49。靠近world safe边界时裁剪后可更少；极大finite radius稳定进入active-entry fallback。

**悬崖效应（性能信号，不是错误）：** `radius=2.0` 理论 9 格，`radius=2.01` 理论 25 格。系统必须保持结果正确，再由配置审计/benchmark 提醒跨档成本。

**示例：** 灵气吸取查询，`radius=1.8`、`CELL_SIZE=2.0`：
- `ceil(1.8 / 2.0) = ceil(0.9) = 1`
- `theoretical_cells_saturated=9`（正常远离技术域边界时actual也为9）

对比（假设性，技能半径未设计）：若某技能 `radius = 6.0`，`CELL_SIZE = 2.0` → `ceil(3.0) = 3` → `(7)² = 49` 格；若 `CELL_SIZE = 6.0` → 9 格。

### F3 — CELL_SIZE 初始候选与选型（Cell Size Candidate Selection）

令 `effective_hot_query_radii = {r | r 是生产调用真正传给 Grid 的半径，finite 且 r>0}`。它聚合中心拾取 `pickup_radius`、中心索敌 `target_range`、checked `skill_effect_radius+max_enemy_bound`、Weapon密集落点的checked `target_range+skill_effect_radius+max_enemy_bound`、checked `separation_radius+max_separation_radius`（R4 根因3 修正原 `separation_radius+max_enemy_bound`——shape bound 与 sep_radius 独立；`separation_radius`==`max_separation_radius` registry 别名,故 = 2×max_sep = 分离查询半径全局上界,与 G3/enemy §4.2 一致）、checked `0.5×max_segment_length+max_midpoint_cast_error+projectile_bound+max_enemy_bound+max_target_motion_bound` 等 **有效宽相半径**，不得只记录玩法原始半径。每个源值及每一步加乘都先验证 finite/非负/不溢出；任一非法项使配置审计返回 `INVALID_BENCHMARK_INPUT`，不得跳过该 consumer 或让 `max()` 吞掉 NaN。若集合非空，`CELL_SIZE_candidate = max(effective_hot_query_radii)`；若集合为空则使用 `CELL_SIZE_SPIKE_ANCHOR = 2.0`，绝不生成 0 大小格。

benchmark sweep以checked multiply生成`{0.5×candidate,candidate,1.25×candidate,CELL_SIZE_SPIKE_ANCHOR}`并逐项执行F1 validation、过滤、去重。某个乘积非finite/超域时只淘汰该候选并记录diagnostic；集合最终至少保留合法spike anchor，否则是初始化域错误。每个候选用相同fixed-seed、相同消费者query mix逐tick记录：

`combined_grid_phase_time = grid_sync_self_time + Σ(all_grid_query_self_time_in_tick)`

先淘汰任何结果集不等于 golden oracle、发生运行时分配、触发 buffer overflow 或超出内存上限的候选；令合格候选的全局最低值为 `p99_min`。若 `p99_min>0`，tie group 定义为 `candidate_p99≤p99_min×1.02`；若 `p99_min=0`，tie group 只含 p99=0 的候选。只在该固定 tie group 内依次以较低 peak memory、较少 candidates examined、较小 CELL_SIZE 破平，禁止非传递的 pairwise “相差 2%”比较。

其中 `max_query_radius` 是所有依赖系统查询半径的全集上界：

`max_query_radius = checked_max(pickup_radius_max, target_range_max, checked_add(max_skill_effect_radius,max_enemy_bound), checked_sum(target_range_max,max_skill_effect_radius,max_enemy_bound), checked_add(separation_radius,max_separation_radius), checked_sum(checked_mul(0.5,max_projectile_segment_length),max_midpoint_cast_error,max_projectile_bound,max_enemy_bound,max_target_motion_bound), ...)`

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 格子边长 | `CELL_SIZE` | float | `[0.01,+∞)` finite且int64 cell包络可表示 — **主 tuning knob** | 由真机 benchmark + ADR 选定 |
| 最大查询半径 | `max_query_radius` | float | [0,+∞) — derived | 所有生产调用有效宽相半径的全集上界；配置审计与 benchmark 输入，不限制合法查询 |
| 灵气吸取半径上限 | `pickup_radius_max` | float | 1.98（1.8×(1+5×2%)） | 当前 MVP 大衍诀五级的已知上限；Progression GDD 须复核叠加语义 |
| 最大索敌范围 | `target_range_max` | float | 未定义 | 包含大衍神念成长后的硬上限 |
| 技能有效宽相半径 | `max_skill_effect_radius+max_enemy_bound` | float | **未设计** | SkillConfig + EnemyConfig；见 Open Questions |
| 分离有效宽相半径 | `separation_radius+max_separation_radius` | float | 未定义 | EnemySystem 碰撞避免调用半径（= 2×max_sep 全局上界，registry `separation_radius`==`max_separation_radius`；R4 根因3 修正原 `separation_radius+max_enemy_bound`；与 G3/enemy §4.2 一致） |
| 投射物有效宽相半径 | `0.5×max_segment_length+max_midpoint_cast_error+max_projectile_bound+max_enemy_bound+max_target_motion_bound` | float | segment/projectile/enemy bound 未定义；MVP `max_midpoint_cast_error=sqrt(2)/32`、`max_target_motion_bound=0` | ProjectileSystem tick-end discrete swept 候选查询半径；所有项 checked finite |

**WHY：** 大 CELL_SIZE 减少 cell lookup 却增加格内候选，小 CELL_SIZE 相反；因此 `max_query_radius` 只是候选启发式，不能证明最优或 O(1)。所有 sweep case 必须返回完全相同的正确结果集合。

**张力（Tension）：**
- `CELL_SIZE` 过大（远大于典型查询半径）：常见查询通常只访问 9 个理论格，但每格候选显著增加；总成本仍可能上升。
- `CELL_SIZE` 过小：大半径查询访问更多格，但候选桶更稀疏；这是允许且必须实测的权衡。

**输出范围 / tuning 范围：** `[MIN_CELL_SIZE,+∞)`中的checked合法值；实际sweep由下游半径分布生成，不以world-domain宽度作为候选，也不把未经设计的6.0当硬上限。
- **临时 spike 锚点：`CELL_SIZE = 2.0`**，与当前已知 `pickup_radius_max=1.98` 接近；不是生产承诺。
- **最终值待定：** 下游半径、稀疏数据布局和 min-spec 真机锁定后由 ADR 记录。

**示例：**
- 当前已知 query=1.8 时，以 2.0 为 sweep 锚点。
- 若后续 `max_skill_effect_radius+max_enemy_bound=5.0`，加入 2.5/5.0/6.25 等候选实测；不得未经测试直接把 CELL_SIZE 上调到 5.0。

### F4 — Occupied-Cell Density

大世界不存在有玩法意义的“全域平均格密度”；用世界面积作分母会把密度稀释成误导值。运行时只报告：

- `occupied_cell_count=count(bucket entry_count>0)`，范围`[0,N_indexed]`；
- `average_entries_per_occupied_cell = N_indexed/occupied_cell_count`（N=0时定义为0）；
- `max_bucket_occupancy=max(bucket entry_count)`（N=0时为0）；
- query级`cells_looked_up/candidates_examined/results_written/active_entries_examined`。

这些量不预测怪潮峰值，也不证明查询耗时。300敌人围绕玩家聚集是expected workload；AC-J4继续使用occupancy 32/64/128/300、玩家相对spawn trace，以及Grid/ENEMY-only/all-object三组公平基线。世界坐标跨度变化不得改变bucket slot容量。

### F5 — 每帧更新成本（Per-Frame Update Cost）

两种实现模式的成本公式（具体选型为 ADR 待定，GDD 不规定；见 Detailed Rules R3）。

**模式 A — 每帧清空重建（Clear-Rebuild）：**

The update_cost_clear_rebuild formula is defined as:

`update_cost_clear_rebuild = O(N_start + A_stage_success + I + R + C)`

**模式 B1 — 轮询式增量更新：** `O(N_start + A_stage_success + I + R + M×remove_cost + T_suspend + T_resume)`，包含 staging overwrite、sync 轮询与 deferred removal。

**模式 B2 — dirty-notification 增量更新：** `O(A_stage_success + D + I + R + M×remove_cost + T_suspend + T_resume)`；`A_stage_success` 约束每次 last-write-wins staging write，`D` 约束 sync 时唯一 dirty entry。

只有维护 `entry → (cell,slot)` 并 swap-remove（或等价 O(1) 容器）时 `remove_cost=O(1)`；仅有 `entry→cell` 不能推出 O(1)。是否采用 B2 属帧调度/数据布局 ADR。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| tick 起点有效注册数 | `N_start` | int | [0,1000] | `SPAWN_INTENT begin` 时 pending+active+suspended 的唯一有效 handle 数；即使本 tick 无 intent，该 phase 仍建立窗口起点 |
| tick起点occupied cell数 | `C` | int | `[0,N_start]` | 仅实际非空稀疏bucket数，不是world虚拟格总数 |
| 成功 stage 调用数 | `A_stage_success` | int | [0,+∞) | tick 内返回 `OK` 的 stage 调用总数；同 handle重复调用逐次计数 |
| dirty 条目数 | `D` | int | [0,N_start+I] | 窗口内至少一次成功 `stage_position` 的唯一 handle 数；重复 stage 不重复计数 |
| 跨格条目数 | `M` | int | [0,D] | F1 最终 cell 发生变化的条目数 |
| insert 数 | `I` | int | [0,1000] | 窗口内成功创建的新 pending handle 数；pending replace 的旧 handle另计 R |
| remove/cancel 数 | `R` | int | [0,N_start+I] | 窗口内立即失效的唯一 handle 数，含 active/suspended remove 与 pending cancel |
| sync 前 remove/cancel | `R_pre_sync` | int | [0,R] | SPAWN_INTENT 到 GRID_SYNC publish 前发生的 remove/cancel 数 |
| deferred remove | `R_deferred` | int | [0,R] | query/damage 后 DEFERRED_REMOVAL phase 的 remove 数；`R=R_pre_sync+R_deferred` |
| 有 bucket 的 remove | `R_bucket` | int | [0,R] | R 中失效前为 active、实际需要 bucket removal 的数；其余 `R_nonbucket=R−R_bucket` 为 pending/suspended invalidation |
| active→suspended | `T_suspend` | int | [0,D] | sync 成功时离开 bucket 的条目数 |
| suspended→active | `T_resume` | int | [0,D] | sync 成功时进入 bucket 的条目数 |
| 同格 center write | `W_same` | int | [0,D] | active→active 且 cell 不变、但 committed center 更新的条目数 |
| sync 边界权威 active 数 | `N_sync_active` | int | [0,1000] | GRID_SYNC 返回后的权威 snapshot active 数：成功时为新 snapshot，failure 时为仍权威的旧 snapshot；clear-rebuild 的尝试性 bucket insert 不以该值作上界 |
| 窗口结束权威 active 数 | `N_end_active` | int | [0,1000] | 正常 tick 为 DEFERRED_REMOVAL + authoritative collection commit 后的 active 数；fatal 提前结束时为进入 ControlledGameplayFault 前仍权威 snapshot 的 active 数，因此任何窗口都有定义 |

**输出范围：**
- **唯一整 tick 观测窗口**固定为 `SPAWN_INTENT begin → DEFERRED_REMOVAL end → authoritative collection commit`；它覆盖 pre-sync remove、每次 stage workspace overwrite、sync 结构更新及 damage-driven deferred remove。若本 tick 没有任何 intent/movement/remove，显式空 phase 仍给出 `N_start` 与零事件计数。每次 insert 按当时 live registrations 检查容量，任意事件前缀均满足 live≤MAX；窗口最终 `0≤N_start+I−R≤MAX_INDEXED_ENTRIES`。
- 若 sync/query/resolve/narrowphase 在正常终点前 fatal failure，窗口在 matching phase end 完成清理并进入 ControlledGameplayFault 时提前终止；所有已发生/尝试的 Grid 操作仍计数，未开启的后续 phase计 0，不能因事务回滚而倒扣 counter；`N_sync_active/N_end_active` 均读取当时仍权威 snapshot，不能留空或读取未发布 candidate。
- 每次成功 stage 必有且仅有一次 `staging_write`，因此 `staging_writes=A_stage_success`；sync 只对 D 个唯一最终值提交，last-write-wins 不得把先前调用成本藏入 D。
- 模式 A：只允许清理`C≤N_start`个occupied buckets后重建；dense清空整个world虚拟格域不合法。
- 模式 B1：即使 M=0 仍须 `O(N_start)` 检查；same-cell write、suspend/resume 不能藏在 M 中。
- 模式 B2：静止且无事件时可接近 O(0)，但依赖可靠 dirty 通知；重复 stage 成本按 A 线性，全部 dirty 时 sync 部分退化到 O(N_start+I)。

**GDScript 成本常数与先验预算：** 以上大 O 不包含 Variant/refcount、bucket clear、swap-remove、Dictionary lookup、PackedArray 读写、float64 距离运算与结果写入。不能用“5–30μs/query”作为统一常数：query 成本随 `cells_visited/candidates_tested/results_written` 线性变化。OQ7 主策略 spike 前必须先完成 AC-J0a 的桌面 release microbench，分别测出下表净成本；在实测前只使用保守 planning bracket，不据此判通过：

| primitive | baseline 计量单位 | OQ7 前必须产出的统计 | 未实测 planning bracket（EVIDENCE ONLY） |
|---|---:|---|---:|
| `Dictionary[Vector2i]` hit / miss | ns/op | p50/p95/p99 + allocation delta | 不预填伪精确值 |
| `PackedInt64Array` read / write | ns/op | p50/p95/p99 + resize/create counter | 不预填伪精确值 |
| entry Variant/Node identity validation | ns/candidate | p50/p95/p99 | 不预填伪精确值 |
| float64 squared-distance（无 sqrt） | ns/candidate | p50/p95/p99 | 与下项分开 |
| float64 distance（含 sqrt） | ns/candidate | p50/p95/p99 | 与 squared 分开 |
| swap-remove + reverse-slot fixup | ns/move | p50/p95/p99 + writes | 不预填伪精确值 |

聚合估算固定为 `T_query ≈ cells_visited×C_lookup + candidates_tested×(C_read+C_filter+C_distance) + results_written×C_write`，不得只乘“query 数”。在 baseline 实测前，review 给出的 400 个 projectile query × 300 候选 = 120,000 candidate checks/frame 采用 **6–18ms/frame** 的 planning bracket；**此为乐观下界而非保守上界**——它只计 projectile×enemy 的 `C_distance`（sqrt）分量，未含 300 enemy separation / DROP pickup / skill AoE 等其他 consumer 的候选，也未含每候选的 `C_read+C_filter`（PackedArray 读 + type mask 判定）、每 query 的 `cells_visited×C_lookup`（400 query × 9 cells = 3,600 lookup）与 `results_written×C_write` 项；全 consumer + 全分量相加后真实 query budget 可达该值的 1.5–3×。**不得据此判定“query 子预算有余量”**；它只是风险下界，不是已测性能事实，也不能替代 J0/J2 真机 gate。桌面 baseline 与 operation counters 必须同时记录，主 spike 才能区分算法项与 GDScript/Variant 常数项。

**跨格概率估算（仅规划用）：** `speed≥0`、`fps>0`、`d=speed/fps`，单轴 `p=clamp(0.637d/CELL_SIZE,0,1)`，双轴并集近似 `p_cross=2p−p²`（独立近似，有效域 `d≪CELL_SIZE`）。该式不得作为正确性或验收 gate；实际 `M` 与 active population 由 instrumentation 分别报告。

**示例：** 300 敌人、`speed=4.5`、60fps、CELL_SIZE=2：`d=0.075`，`p≈0.0239`，`p_cross≈0.0472`，所以 `M_enemy≈14.2`。这是方向均匀/轴独立近似，不再同时保留 7 或 22 的冲突结果。

### 公式汇总

**Tuning Knobs vs Derived**

| 量 | 分类 | 所属 / 来源 | 说明 |
|----|------|------------|------|
| `CELL_SIZE` | **TUNING KNOB**（主） | SpatialGrid | F3 benchmark + ADR 的输出 |
| `world_safe_half_extent` / `MAX_QUERY_CELLS_ENUMERATED` | **TECHNICAL LIMITS**（外部） | Stage/Config V2 | 16384 / 262144；不按world面积分配bucket |
| `max_query_radius` | **DERIVED**（跨系统聚合） | 由 F3 定义，输入来自多 GDD | 配置审计/benchmark 输入，不限制查询正确性 |
| `max_midpoint_cast_error=sqrt(2)/32` | **DERIVED CAP** | R1 domain + MVP real_t32 export | projectile midpoint Vector2 cast 的配置上界；runtime 使用实际 error |
| `max_target_motion_bound=0` | **MVP CONTRACT** | R10 tick-end discrete sampling | 不提供 continuous relative-sweep 保证；升级需联动公式与窄相测试 |
| `pickup_radius_base=1.8` / `pickup_radius_max=1.98` | **TUNING KNOB / DERIVED**（外部） | PlayerStats / Progression / Config | 当前 MVP 基值与五级大衍诀上限；DropSystem实际消费，SpatialGrid仅引用 |
| `max_skill_effect_radius+max_enemy_bound` | **未设计** | SkillConfig + EnemyConfig | F3 的关键缺失有效宽相输入 |
| `cell_x`, `cell_y` | DERIVED | F1 | 运行时逐实体计算 |
| `theoretical_cells_saturated/actual_cells_visited` | DERIVED | F2 | 查询覆盖诊断 |
| `occupied_cell_count` / `average_entries_per_occupied_cell` / `max_bucket_occupancy` | DERIVED | F4 | 稀疏密度与性能证据 |
| `N_start`, `C`, `A_stage_success`, `D`, `M`, `I`, `R_pre_sync`, `R_deferred`, `R_bucket`, `T_suspend`, `T_resume`, `W_same`, `N_sync_active`, `N_end_active` | DERIVED（运行时状态） | F5 | 更新成本核算与 instrumentation |

## Edge Cases

按边界来源分组。所有 outcome 均为明确行为，无"优雅处理"等含糊表述。

### A. 参数边界（公式层）

1. **If** `radius = 0`：**Then** 只访问中心格并走专用分支，以 `entry.center.x == center.x && entry.center.y == center.y` 的分量精确相等判定；不得计算平方距离。任一分量存在最小可表示正偏移都不得返回。浮点边界容差属于上游玩法 shape/narrowphase，不在点查询中暗加 epsilon。
2. **If** `radius < 0`：**Then** dev assert；release 返回 `INVALID_ARGUMENT`、保持输出 buffer 内容不具权威性并限频上报，绝不 clamp 成另一个合法查询。
3. **If** `CELL_SIZE`或world-domain参数违反F1 finite/范围/int64 cell包络：**Then** dev assert；release init返回`INIT_LIMIT_EXCEEDED`、保持Inactive，不分配部分sparse table。
4. **If** insert/stage position或query center/radius含NaN/Infinity，或center越过world safe domain：**Then** dev assert；release返回`INVALID_ARGUMENT/POSITION_OUT_OF_RANGE`并保持旧snapshot；GameRoot进入fault convergence，不clamp、不suspend、不wrap。

### B. 归格边界

5. **If** 实体恰在世界格边界：**Then** 归入右/下侧的较高signed格；无双归。
6. **If** 实现用向零截断替代floor：**Then** 负坐标会归错格；规范实现使用`floori()`/等价floor，AC-A2覆盖正负边界。

### C. 有限世界域边界

7. **If** center/完整bound仍在world safe domain：**Then** 使用真实位置归入signed cell；不因接近技术边界改变集合。
8. **If** 查询圆跨越world safe边界：**Then** 只返回域内已注册entry，不回绕、不镜像；中心本身越域则失败。
9. **If** radius极大或概念cell数超过枚举上限：**Then** 走F2 active-entry fallback，扫描≤1000条并保持同一精确集合，不计算/枚举巨大空域。

### D. 实体生命周期

10. **If** 同一对象重复 insert 且 type/position 完全相同：**Then** 返回 `OK_NOOP` 与原 pending/active/suspended handle。若任一项不同：旧 entry 为 pending 时才允许 validate 后 `OK_REPLACED` 为新 pending；旧 entry 为 active/suspended 时固定 `INVALID_ARGUMENT` 且旧 snapshot/handle/staging 不变。位置变化必须 stage；type 变化必须显式 remove→insert，并由 owner接受规范查询空窗。
11. **If** `remove()` 收到无效、旧 epoch 或已移除 handle：**Then** 返回 `STALE_HANDLE` 且 no-op；有效 handle 被 remove 后立即不可查询，不能等下一次 clear-rebuild。
12. **If** 查询发生在 sync 中途，或合法 query phase 中发生 query/resolve/fatal narrowphase failure：**Then** dev assert（仅对不可达 phase 违例）；release 不把 failure 伪装成空集合；GameRoot 必须回滚整个 query/collision phase staging、关闭 lease并聚合上报。合法 no-hit 仍是 `OK`，不触发回滚。正常 phase ordering 应使 sync 中途查询入口不可达。

### E. 查询行为

13. **If** 空网格合法查询：**Then** circle 为 `OK,out.count=0` / nearest 为 `OK,out.has_handle=false`，覆盖格诊断仍按 F2 记录。
14. **If** `type_filter` 在半径内无匹配类型实体：**Then** 返回 `OK,count=0`，不返回其他类型实体。
15. **If** `query_nearest_into` 查到多个等距敌人：**Then** 返回有效 `registration_sequence` 最小者；插入顺序扰动、bucket swap-remove 或 clear-rebuild 不改变同一组稳定 handle 的结果。
16. **If** `query_nearest_into` 半径内无匹配实体：**Then** 返回 `status=OK,out.has_handle=false`（R5 已定）。
17. **If** `query_circle_into` 中心点所在格为空且邻格也无匹配：**Then** 返回 `OK,count=0`，与 case 13 一致。

### F. 状态转换

18. **If** Active 时调用 insert/remove：**Then** insert 在下个成功 sync 前不可查询；remove active handle 立即失效，remove pending handle 取消插入。
19. **If** 请求 Paused：**Then** GameRoot 先完成当前 tick 的 sync、damage、deferred removals 与 authoritative collection commit，再在 barrier 冻结同 revision snapshot；若仍有 pending/staged work，`request_pause` 返回 `PENDING_WORK` 并保持 Active。Frozen mutation/sync 返回 `PAUSED`。恢复按 prepare→arm→可回滚 owner swap→publish；任一步失败/abort/end-phase auto-abort 均恢复 Frozen 旧 snapshot/handles/revision，publish 成功并关闭 lease 后才开放下一 Active consumer。
20. **If** Inactive/TornDown 时调用 API：**Then** mutation 返回 `WRONG_STATE`；circle/nearest 返回 `WRONG_STATE` 而非合法空结果；warning 按 `(status,api,grid_epoch)` 每 epoch 最多一次。
21. **If** 运行时（网格 Active 期间）改变 `CELL_SIZE`：**Then** 不支持热更。`CELL_SIZE` 在网格 `Active` 期间固定，仅在 `Inactive → Active` 转换时配置。若需变更，须 `teardown → reset_to_inactive → init(new_size)` 全网格重建（所有实体重新归桶）。

### G. 容量分布

22. **If** 怪潮聚集致 bucket occupancy 达 32/64/128/300：**Then** 查询保持正确，instrumentation 记录候选量与 p99；不得用“平均×5–10”替代 synthetic/实测 fixture。
23. **If** world-domain参数非法、dense bucket容量与world面积相关或occupied-cell slots超过1000：**Then** 阻止Active；不得以减少world extent掩盖内存设计错误。

### H. 依赖未完成

24. **If** SkillConfig 尚未定义 AoE/索敌/成长后半径：**Then** CELL_SIZE=2.0 只作为 spike 锚点；所有合法半径查询仍保持正确。下游配置完成后更新 max_query_radius 并重跑 sweep，而非直接同步放大 CELL_SIZE。

25. **If** F3原始候选经合法域过滤后为空：**Then** 使用并验证`CELL_SIZE_SPIKE_ANCHOR=2.0`；若仍失败则readiness以初始化域错误终止。
26. **If** `N_indexed=0`：**Then** F4 occupied count、平均与max occupancy均为0，不除零；非零N时occupied count必须位于`[1,N]`。
27. **If** 高速投射物只在运动段中部与目标的 tick-end committed shape 相交且目标位于 endpoint circle 外：**Then** R10 swept broadphase 仍必须把目标纳入候选，并由 tick-end discrete swept narrowphase 判定最终命中；不得据此声称会命中只与目标历史运动段相交的 relative-sweep case。
28. **If** 任意生产 query/resolve 返回 failure，或 consumer 报告 fatal narrowphase/domain failure：**Then** 本 tick 尚未提交的 damage/pickup/targeting 均不生效，GameRoot 进入 ControlledGameplayFault；禁止把 carrier 零值或旧槽位当作空结果继续游戏。普通 no-hit 仍为合法结果并继续 phase。
29. **If** 普通怪 active+pending 达容量（ENEMY cap=303，普通怪 effective 298），或阶段必需 Elite/Boss 命中 reserved 槽不可用：**Then** 普通怪 spawn intent 被 SpawnDirector 在 borrow/可见化前 admission 抑制、对象不进可见 SceneTree 分支/active collection、无 handle 且安全返池，现有战斗继续并记 suppressed-spawn telemetry；Elite/Boss 无预留可用则撤销未发布 candidate 后进入 `ControlledGameplayFault`。任何情况下不得留下可见但不可索引的“幽灵敌人”（R9/AC-E11）。

## Dependencies

### 上游依赖

**无已实现的代码硬依赖**，但存在四个必须注入的集成契约：Stage V2有限world-domain与sparse enumeration ceiling、GameRoot phase/暂停调度/**ControlledGameplayFault 玩家与持久化路径**、生命周期owner的active collection/对象池回收、Config snapshot提供的数值域/per-type数量/conservative bound上限。当前只允许foundation isolated spike，不允许声明battle/integration story ready。Paused binding/quarantine与teardown顺序分别以`object-pooling.md` R6–R8和`game-root-scene-flow.md` R7–R9为集成权威。

### 下游依赖（架构硬依赖 — 缺则无法工作）

以下系统在 systems-index 中将 SpatialGrid 列为 Depends On，其 GDD 完成后须在各自 Dependencies 节反向引用 SpatialGrid 并说明所用的查询接口：

| 系统 | 层级 | 用途 | 调用接口 | GDD 状态 |
|------|------|------|----------|----------|
| EnemySystem | Core | 敌人位置入格 / 排除 self 的分离查询 | `insert_into/stage_position/remove(handle_id)` / `query_circle_into(pos, sep_radius+max_separation_radius, ENEMY, buffer, lease_id)`（R4 根因3:原 `sep_radius+max_enemy_bound` 误用 shape bound,改 §4.2 权威形式） | In Review |
| SpawnDirector | Core | per-type admission、普通怪抑制、Elite/Boss 预留，保证已发布 ENEMY active+pending≤303 | Config cap precheck → Enemy owner borrow/insert → 仅 insert 返回 OK 且后续 sync 成功发布后，owner 才把对象接入可见 SceneTree分支与active collection；`CAPACITY_EXCEEDED`按R9/AC-E11处理 | Designed / Full Review Pending |
| DamageSystem | Core | 范围伤害宽相候选 | `query_circle_into(center, effect_radius+max_bound, ENEMY, buffer, lease_id)` + shape narrowphase | 未设计 |
| ProjectileSystem | Core | 以整段 swept motion 发起敌人宽相；默认不注册投射物 | `query_circle_into(swept_center, swept_query_radius, ENEMY, buffer, lease_id)` + swept narrowphase | Designed / Full Review Pending |
| Weapon/TargetingSystem | Core | 读取Player motion view后按攻击节奏索敌 | nearest 用 `query_nearest_into`；密集落点用 `query_circle_into(target_range+effect_radius+max_enemy_bound,ENEMY,...)` 后完整窄相评分 | Designed / Full Review Pending；半径数值待 SkillConfig |

### 运行时输入与控制契约

| 系统 | 用途 | 调用接口 | 契约状态 |
|------|------|----------|----------------|
| DropSystem | 掉落物注册 / 读取Player motion view执行中心点本地灵气吸取；引灵符全场效果走Drop active collection | `insert_into/stage_position/remove(handle_id)` / `query_circle_into(pos,pickup_radius,DROP,buffer,lease_id)` | 本地吸取硬依赖SpatialGrid；pickup数值来自PlayerStats/Progression/Config |
| PlayerController | 只发布motion/HUD/event view，不注册、不查询、不remove | 无；Grid API调用计数必须为0 | Player首轮full review整改完成，Re-review Pending |
| GameRoot & Scene Flow | phase coordination、snapshot revision、phase-6 lifecycle journal+fact ledger、Paused transaction 与 ControlledGameplayFault 玩家/持久化路径 | 独占`begin_phase/end_phase`调度权；phase 6 visible committed row=0则0 publish、>0则matching end/fault convergence恰一次batch authority publish；resume在consumer-closed window执行Grid→Pool→authority三次发布 | `design/gdd/game-root-scene-flow.md` seventh remediation，Re-review Pending；实现/集成证据未完成 |
| Config/Data | 数值域、type caps、carrier/workspace上限、snapshot ID 与 orchestration limits | Stage schema v2固定world half 16384、abs hard cap 1000000、min cell 0.01、query-enumeration ceiling 262144、entry 1000及303/0/300；Grid init逐项复核 | `design/gdd/config-data-system.md` Re-review Pending |

**一致性核对结论**：DropSystem 的本地吸取不可降级为高频全场遍历，因此是 SpatialGrid 硬依赖；`systems-index.md` 已同步该边。引灵符全场效果仍走 DropSystem 权威 active collection。

### 待设计的下游 GDD

PlayerController已完成首轮full review整改，EnemySystem处于In Review。
SpawnDirector、DamageSystem、ProjectileSystem 与 Weapon/TargetingSystem 已有作者设计但均待独立复审；DropSystem仍未设计。这意味着：
- 当前 `max_query_radius` 下界由已知 `pickup_radius_max = 1.98` 支撑（F3）
- `max_enemy_bound`、`separation_radius`、projectile segment/bound、成长后 target range、技能 AoE 半径均未定义
- ProjectileSystem 的 MVP moving-target 语义已在 R10 冻结为 tick-end discrete snapshot，`max_target_motion_bound=0`；其 GDD 仍须提供最大单 tick segment 与 projectile/target bound，并原样采用 scalar midpoint/cast-error 契约。GameRoot phase-wide resolution rollback、Paused owner-reference swap 与故障路径已在其最小GDD冻结，但实现/集成测试仍是 BLOCKING gate
- 上述 GDD 完成时，须回填 `max_query_radius` 并重跑 CELL_SIZE benchmark sweep（见 Open Questions）
- 不再依赖未定义的领域 `Entity` 基类；本 GDD 固定 registrant 为 Node-derived pooled gameplay object、公开 handle 为 primitive int、内部保存不延长 Node 生命周期的直接 identity并仅以 instance ID 作诊断/paused carrier 比对。具体 carrier `class_name` 与 bucket 容器由 API/data-layout ADR 落地。

### 双向一致性要求

依 design-docs 规则"if system A depends on B, B's doc must mention A"：
- 本 GDD 已列出外部注入契约与下游交互系统；DropSystem 的 systems-index 依赖边已同步
- 待下游 GDD 设计完成时，**反向校验**：每个下游系统的 Dependencies 节必须反向引用 `spatial-grid.md`，否则触发一致性失败

## Tuning Knobs

### 系统拥有的旋钮

**G1 — `CELL_SIZE`（格子边长）** — **主旋钮**
- **类型**：float，世界单位
- **合法范围**：`[0.01,+∞)`中的finite值，且world-domain cell key可安全转换为int64；生产sweep范围待下游半径冻结
- **临时 spike 锚点**：2.0（与当前 pickup_radius_max=1.98 接近，仅供对照）
- **影响维度**：性能（非玩法）。决定F2局部枚举与bucket候选密度；world-domain合法性独立，因此CELL_SIZE不改变结果集合。
- **调谐依据**：F3 多候选 benchmark；以聚合查询/update p99、候选数和 allocation 为准，不再直接等于 max_query_radius。
- **调谐时机**：仅 `Inactive → Active` 转换时可配置；运行时不可热更（见 Edge Case 21）

**G2 — `world_safe_half_extent` / `MAX_QUERY_CELLS_ENUMERATED`** — 外部技术上限（Stage/Config拥有）
- 默认分别为16384与262144。前者限制合法中心域，后者只决定何时从local cell enumeration切到active-entry scan。
- 二者都不是玩法边界；改变它们不得改变任一合法query结果集合。

### 外部引用旋钮（其他系统拥有，本系统读取）

**G3 — `max_query_radius`（最大查询半径）** — derived（跨系统聚合）
- **类型**：float，世界单位
- **定义**：`checked_max(pickup_radius_max, target_range_max, checked_add(max_skill_effect_radius,max_enemy_bound), checked_sum(target_range_max,max_skill_effect_radius,max_enemy_bound), checked_add(separation_radius,max_separation_radius), checked_sum(checked_mul(0.5,max_projectile_segment_length),max_midpoint_cast_error,max_projectile_bound,max_enemy_bound,max_target_motion_bound), ...)`
- **separation 项澄清（2026-08-28 传播修订）**：公式显式使用 `checked_add(separation_radius,max_separation_radius)`，与调用侧 `sep_radius+max_separation_radius` 同形。registry 旧名 `separation_radius` 当前冻结为 EnemySystem §4.6 的同一全局上界，故预算值仍等于`2×max_separation_radius`；显式双变量避免未来 per-caller 值与全局上界分离时发生契约漂移。
- **MVP projectile 固定项**：production export 为 real_t32，故 `max_midpoint_cast_error=sqrt(2)/32=0.04419417382415922`；target sampling 为 tick-end discrete，故 `max_target_motion_bound=0.0`。这两项必须出现在 registry expression 中，即使后一项数值为零也不得省略语义字段。
- **当前下界**：1.98（仅 pickup_radius_max 支撑，其他输入未设计）
- **影响维度**：生成 CELL_SIZE sweep 候选、发现异常配置与规划 workload；不限制合法查询。
- **调谐归属**：非单一系统拥有——其值为多个 GDD 的查询半径聚合；规范 expression 与已冻结 projectile 常量登记在 `design/registry/entities.yaml`。

**G4 — `pickup_radius_base=1.8 / pickup_radius_max=1.98`（灵气吸取半径）** — 外部值（PlayerStats / Progression / Config 拥有）
- **类型**：float，世界单位
- **当前值**：基值 1.8；按大衍诀五级、每级基于基础值 +2% 的 MVP 口径，已知上限 `1.8×1.10=1.98`
- **影响维度**：作为 `max_query_radius` 的下界输入（F3）与灵气吸取查询半径（Section C）。
- **调谐归属**：PlayerStats / Progression / Config拥有，DropSystem消费，SpatialGrid仅引用。注册表候选。

### 非旋钮的 derived 量（仅列出，不调谐）

`cell_x/cell_y`（F1）、`theoretical_cells_saturated/actual_cells_visited`（F2）、`average_entries_per_grid_cell/expected_entries_in_cell_i`（F4）及 F5 全部运行时计数均为 derived，不直接调谐。

## Visual/Audio Requirements

SpatialGrid 是纯数据基础设施，无视觉表现、无音频反馈。

- **视觉**：不渲染网格线、不显示格内实体——玩家不可见。调试可视化（网格边界、格内实体计数热力图）属开发工具，归 `tools/debug`，非游戏视觉资产，不在本 GDD 约束范围。
- **音频**：无音频。网格更新与查询均静默，不触发任何声音事件。

## UI Requirements

无 UI。SpatialGrid 无任何玩家面向的界面元素。玩家从不直接接触网格——只感受它启用的流畅度（见 Player Fantasy）。

## Acceptance Criteria

Given-When-Then 格式。Logic 行为用 GDUnit4 debug unit/integration；真实 release 分支与性能只能用导出的 benchmark/smoke artifact。当前仓库尚无 project.godot、GDUnit4 addon、export preset 和 min-spec 真机，因此这些是**验收设计**而非已执行证据；脚手架与设备锁定列为 J0 实现前置 gate。

### A. 归格与网格结构（R1, F1, F3）

**AC-A1 均匀格行为（不锁私有容器）**
- Given: SpatialGrid 已初始化
- When: 对相同坐标和 CELL_SIZE 重复归格，并对相邻边界两侧取样
- Then: 归格稳定、每个世界点唯一归属、相邻格边界间距为 CELL_SIZE；底层容器由 ADR 决定
- 验证: unit test（公开 world_to_cell 行为）+ ADR review | Gate: BLOCKING

**AC-A2 signed floor归格**
- Given: `CELL_SIZE=2`，x=`-2.1/-2.0/-0.1/0/1.9/2.0`
- When: world_to_cell
- Then: 依次为`-2/-1/-1/0/0/1`；向零截断实现失败
- 验证: table-driven unit | Gate: BLOCKING

**AC-A3 finite domain与稀疏初始化**
- Given: 合法/零snapshot ID、world half、CELL_SIZE及int64 cell包络边界
- When: init
- Then: 合法输入只预分配entry/occupied-cell固定容量；非法/overflow返回`INVALID_ARGUMENT/INIT_LIMIT_EXCEEDED`、getter=0且保持Inactive；bucket容量不随world面积变化
- 验证: debug + release smoke + allocation counters | Gate: BLOCKING

**AC-A4 CELL_SIZE选型证据**
- Given: 下游半径分布、稀疏数据布局与min-spec真机已锁定
- When: 运行F3 sweep
- Then: ADR记录每候选`sync+aggregate queries` p99、peak memory、候选量、fallback率与allocation，并按F3唯一选定
- 验证: release benchmark + ADR | Gate: BLOCKING before production implementation

**AC-A5 空半径集合fallback**
- Given: effective radii为空或全0
- When: 生成F3候选
- Then: 至少保留合法2.0 spike anchor，不追加world-width/dense 1×1候选，不含0/NaN/Infinity
- 验证: unit | Gate: BLOCKING

**AC-A6 F4 occupied密度**
- Given: N=0、100条分布于1/4/100个occupied cells及跨度10/30000单位fixture
- When: 计算F4
- Then: N=0输出全0；其余平均分别100/25/1，max occupancy与fixture一致；坐标跨度不改变预分配容量
- 验证: formula + integration | Gate: BLOCKING

**AC-A7 有效宽相聚合**
- Given: pickup=1.98、skill=4+enemy_bound=1、separation=0.5+bound=1、projectile segment=8/cast-error cap/projectile bound=0.2/enemy bound=1/target motion=0及非法值
- When: 聚合max_query_radius
- Then: 合法上界为`5.24419417382416`；非法/overflow返回`INVALID_BENCHMARK_INPUT`，不影响F4的occupied统计
- 验证: formula unit | Gate: BLOCKING

### B. query_circle_into 查询正确性（R4, F2）

**AC-B0 空网格合法查询返回空结果（EC13/EC17 覆盖，qa-lead BL-2 闭环）**
- Given: SpatialGrid 已 init 为 Active 但网格中**无任何已 sync 的活动实体**（两种 fixture：①init 后从未 insert；②曾 insert+sync 后全部 remove+sync 清空）
- When: 分别调用 `query_circle_into(center, radius≥0, type_filter∈{ENEMY,ALL}, buffer, lease_id)` 与 `query_nearest_into(center, max_radius≥0, type_filter, nearest_out, lease_id)`
- Then: circle返回`OK,count=0`；nearest返回`OK,has_handle=false`。local路径记录`actual_cells_visited≥1`，巨大半径fallback记录`actual_cells_visited=0,active_entries_examined=0`；不得crash或创建空bucket。
- 验证: unit test（两种空网格 fixture × circle/nearest × 多 radius/filter）| Gate: BLOCKING

**AC-B1 半径查询返回半径内实体**
- Given: 网格中已插入位于 (0,0)、(1,0)、(3,0) 的三个实体
- When: 使用足量复用 buffer 调用 query_circle_into(center=(0,0), radius=2.0, type_filter=ALL)
- Then: `status=OK,count=2`，buffer 含 (0,0) 与 (1,0)；(3,0) 不返回
- 验证: unit test | Gate: BLOCKING

**AC-B2 边界语义为含边界（≤）**
- Given: 按 F2 固定操作顺序算得的规范距离 `d` 恰好等于 radius
- When: query_circle_into
- Then: **含算法边界**——`d≤radius` 即返回；不额外用 epsilon 扩张，也不声称等价于任意精度实数圆
- 验证: unit test（边界值用例）| Gate: BLOCKING

**AC-B3 radius 跨 CELL_SIZE 后仍正确**
- Given: CELL_SIZE = 2.0
- When: query_circle_into with radius = 2.0（= CELL_SIZE）
- Then: `theoretical_cells_saturated=9`；远离技术域边界时`actual_cells_visited=9`
- When: query_circle_into radius=2.01，且在距离 2.005 放置目标 E
- Then: `theoretical_cells_saturated=25`，E 必须返回；debug/release 的结果 ID 集合一致，绝不 clamp
- 验证: unit test 读取实例诊断 + release export smoke 对比 golden result set | Gate: BLOCKING

**AC-B4 radius = 0 只返回中心点实体**
- Given: 中心格内有 E0 与 center 两分量位值完全重合；E1/E2 分别仅在 x/y 上增加目标 export artifact 的 `Vector2/real_t` 下一可表示值（标准构建为 float32 nextafter，double-precision 构建则为 float64 nextafter）
- When: query_circle_into(center, radius=0, ...)
- Then: 专用分量相等分支仅返回 E0；E1/E2 即使平方距离下溢为 0 也不得返回，访问 1 格
- 验证: unit test | Gate: BLOCKING

**AC-B4b 正半径规范距离比较不平方溢出/下溢**
- Given: manifest 固定 export template 与 `real_t`；radius 取 GDScript float64 最小正值、普通值与 far-corner 前一可表示值；Vector2 目标按该 artifact 的 real_t 位值构造轴向/对角 fixture，并包含 raw `radius²`/`distance_squared` 会下溢的输入
- When: query_circle_into 严格按 F2 `spatial_distance_le` 的 float64 提升和操作顺序执行
- Then: status/result 与冻结的算法表逐项一致；`d==radius` 命中，算法表判外的目标不命中，不生成 Infinity/NaN；debug/release 同 artifact 得到相同 canonical handle set
- 验证: independent table-driven reference function + query unit + exported release golden set | Gate: BLOCKING

**AC-B5 radius < 0 明确失败**
- Given: 任意已初始化网格
- When: query_circle_into(center, radius=−1.0, ...)
- Then: debug assert；release 返回 `INVALID_ARGUMENT,out.count=0,out.required_capacity=0`，旧槽位不权威并限频上报；不得按 0 半径执行
- 验证: debug assert test + release strategy/black-box smoke | Gate: BLOCKING

**AC-B6 复用缓冲区容量与零分配**
- Given: max_registered 为 ENEMY=303/PROJECTILE=0/DROP=300；调用方给 ENEMY buffer capacity=303、ALL buffer capacity=603 与错误的 602
- When: 在 Active 之前执行集成容量校验，并在 Active 中连续 10,000 次查询
- Then: 303/603 均通过且稳态 allocation/query=0；602 在进入 Active 前失败。强制绕过校验时返回 `BUFFER_TOO_SMALL,out.count=0,out.required_capacity=603`，旧槽位不权威、不截断、不扩容
- 验证: unit + integration allocation instrumentation/code review | Gate: BLOCKING

**AC-B7 primitive status + caller-owned carrier 不分配**
- Given: circle buffer、nearest/handle/resolve/lease carrier 均在 Active 前创建，phase coordination token 为 primitive int lease ID，handle 以 PackedInt64Array/int 表示
- When: 对同一 carrier 连续执行 10,000 次 circle/nearest/resolve，消费者使用预声明 `var i: int = 0` 与 `while i < out.count`/`i += 1` 原位读取；另跑唯一差异为 `for i in range(out.count)` 的 range-allocation positive control
- Then: API 返回 primitive int status；正式路径 carrier/数组 identity 与 capacity 不变，不创建 Result/Dictionary/Array/迭代容器且不调用 slice；range positive control 必须观测到 allocation/allocated-bytes delta>0 并失败，若未观测到则 allocation harness 不合格
- 验证: exported release allocation test + code review | Gate: BLOCKING

### C. query_nearest_into 查询正确性（R5）

**AC-C1 全局最近实体返回**
- Given: 先扫描格中实体距 center=1.4，后扫描相邻格实体距 center=0.1，另有 2.5
- When: query_nearest_into(center, max_radius=3.0, type_filter=ALL, out_result, lease_id)
- Then: local与强制active-entry fallback两条路径均返回0.1者；不能因先遇到1.4或bucket顺序提前返回
- 验证: unit test | Gate: BLOCKING

**AC-C2 无匹配返回 has_handle=false**
- Given: max_radius 内无实体
- When: query_nearest_into(center, max_radius, ...)
- Then: `status=OK,out.has_handle=false,out.handle_id=0`
- 验证: unit test | Gate: BLOCKING

**AC-C3 等距确定性（稳定 registration_sequence）**
- Given: A、B 等距，A.registration_sequence < B.registration_sequence
- When: query_nearest_into(center, ...)
- Then: 始终返回 A
- 验证: unit test 主动打乱 bucket/重建顺序与 swap-remove，结果仍为 A | Gate: BLOCKING

**AC-C4 max_radius 边界语义**
- Given: 实体恰好位于 max_radius 上
- When: query_nearest_into
- Then: 按 AC-B2 同一语义含边界（≤）
- 验证: unit test | Gate: BLOCKING

**AC-C5 跨帧确定性（等距场景不抖动）**
- Given: 一组等距实体保持位置不变，连续 `N=120` 帧 sync + query_nearest_into
- When: 比较各帧返回值
- Then: 连续 N 帧返回同一 stable handle；容器迭代序变化不影响结果
- 验证: 参数化 unit test（连续帧 + 顺序扰动）| Gate: BLOCKING

**AC-C6 nearest 参数错误与极大半径**
- Given: max_radius分别为负数、NaN、Infinity、刚好触发enumeration ceiling与`1e100`
- When: query_nearest_into
- Then: 负数/NaN/Infinity返回`INVALID_ARGUMENT`；合法大finite值走active-entry fallback并返回全局最近，不发生int转换溢出或语义缩小
- 验证: debug assert + release unit/black-box | Gate: BLOCKING

**AC-C7 center-nearest 与 shape-nearest 不混用**
- Given: A 的 center 更近但大形状边缘更远，B 的 center 更远但形状边缘更近
- When: 调用 query_nearest_into，并另用 circle candidates 执行 shape-distance oracle
- Then: nearest_into 按 center distance 返回 A；需要 shape-nearest 的 consumer 必须采用候选+oracle 返回 B，不能把 nearest_into 解释成 shape-nearest
- 验证: unit + PlayerController integration contract test | Gate: BLOCKING on downstream integration

### D. 类型过滤（R2）

**AC-D1 类型掩码组合**
- Given: 同一格内有 ENEMY、PROJECTILE、DROP 各一
- When: query_circle_into(center, radius, type_filter=ENEMY, buffer)
- Then: `status=OK` 且仅返回 ENEMY 实体
- 验证: unit test（7 个非空子集 + filter=0 返回 `OK,count=0`；未知 bit 8 被忽略并限频 warning，ALL|8 等价 ALL）| Gate: BLOCKING

**AC-D2 非匹配类型不入过滤结果**
- Given: 实体类型为 DROP
- When: query_circle_into(center, radius, type_filter=ENEMY|PROJECTILE, buffer)
- Then: 不返回该 DROP 实体
- 验证: unit test | Gate: BLOCKING

**AC-D3 注册类型必须为单一已知 bit**
- Given: type_mask 分别为 0、ENEMY|DROP、8、ENEMY
- When: insert
- Then: 前三者 debug assert/release `INVALID_ARGUMENT` 且不创建 handle；ENEMY 返回 `OK` pending handle
- 验证: unit test | Gate: BLOCKING

### E. 插入 / 删除与幂等（R6）

**AC-E1 insert 后可被查询到**
- Given: 空网格
- When: insert 实体 E 于 (x,y)，在 sync 前查询一次，再完成 sync 后查询一次
- Then: insert 返回 `status=OK` 的 pending handle；sync 前结果不含 E，成功 sync 后 `query_circle_into(x,y,0,...)` 返回 E
- 验证: unit test | Gate: BLOCKING

**AC-E2 remove 后不再被查询到**
- Given: 网格含实体 E
- When: remove(handle_E) 后、未执行下一次 sync 前立即查询
- Then: query_circle_into 返回结果不含 E，resolve(handle_E) 为 invalid
- 验证: unit test | Gate: BLOCKING

**AC-E2b phase 6 第 N 条失败保持 exact-once committed facts**
- Given: 预分配journal可容纳本tick全部lifecycle intents且每intent恰一row，依次处理多个active/pending/suspended handle，并在第N条的Grid remove、Pool unbind、release/reset前后分别注入failure
- When: GameRoot 执行 DEFERRED_REMOVAL
- Then: 每个intent仍只有一row且state按`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`单调推进；旧handle永久stale，失败点后未开始条目不执行。Pool私有release FSM证明reset/free-stack各至多一次；GameRoot在side effect前arm plan，visible committed row=0时0 publish、>0时matching end或fault convergence恰一次publish，cleanup不重复remove/release也不复活旧snapshot
- 验证: N-position fault injection + journal/authority golden trace | Gate: BLOCKING

**AC-E3 重复 insert 幂等**
- Given: 实体 E 分别处于 pending、active、suspended
- When: 再次 insert E（同位置/type），以及以新位置/type提交变化
- Then: 相同契约在三态均返回 `OK_NOOP` 与原 handle；仅 pending 允许合法变化并返回 `OK_REPLACED`（旧 pending stale、新 pending 尚不可查询）；active/suspended 的变化式 insert 固定 `INVALID_ARGUMENT` 且旧 handle/snapshot/staging 不变。位置变化必须 stage；type 变化由 owner 显式 remove→insert并接受空窗
- 验证: unit test | Gate: BLOCKING

**AC-E4 remove 不存在实体幂等**
- Given: handle 从未有效、已移除或 epoch/generation 不匹配
- When: remove(handle)
- Then: 返回 `STALE_HANDLE` 且 no-op，bucket/entry/诊断计数不变；owner 不得据此释放任何对象
- 验证: unit test | Gate: BLOCKING

**AC-E5 跨格移动后查询反映新位置（行为断言，实现无关）**
- Given: 实体 E 在格 A
- When: `stage_position(handle_E, 格B位置)` 后 SpatialGrid.sync 完成
- Then: query_circle_into(格A位置,0,...) 不返回 E；query_circle_into(格B位置,0,...) 返回 E。内部移动方式仍由 ADR 决定。
- 验证: unit test | Gate: BLOCKING
- 备注: 增量更新的内部引用列表移动验证归 AC-J5（复杂度 perf test），不在此。

**AC-E6 非有限坐标拒绝插入（Edge Case 4）**
- Given: 实体坐标含 NaN 或 Infinity
- When: insert 该实体
- Then: 本次 insert 失败且不污染网格；对象恢复 finite 坐标并重新 insert 后可以正常查询
- 验证: unit test（NaN、+Inf、−Inf 三组 + 混合）| Gate: BLOCKING

**AC-E7 stale handle 不因 slot/对象池复用而复活**
- Given: 正常路径中 E1 的 handle H1 已 remove，随后同一 slot 与同一对象实例均被池复用为 E2，新 handle 为 H2；负向 fixture 中 owner 违约，未 remove H1 就 queue_free E1，并强制 ObjectDB 复用旧 instance ID 给 E3
- When: 分别 resolve/remove H1 与 H2，并执行违约 resolve、teardown→reset_to_inactive→re-init 后再次检查旧 handle
- Then: 正常路径 H1 始终 stale，不能解析或移除 E2，H2 在当前 epoch 有效；违约路径因 entry 保存的直接 Node identity 已 invalid 而返回 `OBJECT_INVALID`、回滚整 phase并进入 `ControlledGameplayFault`，绝不能 resolve 为复用同一 instance ID 的 E3；旧 epoch 的所有 handle 在 re-init 后仍 stale
- 验证: unit test（slot reuse + same object reuse + epoch change）+ forced instance-ID reuse/object lifetime negative fixture | Gate: BLOCKING

**AC-E8 非法 staged position 不产生ghost或可恢复降级**
- Given: pending E0、active E1位于合法格A，输入NaN/Infinity或world-domain外位置
- When: stage
- Then: 返回`INVALID_ARGUMENT/POSITION_OUT_OF_RANGE`，staged workspace与旧snapshot不变，sync不会发布非法位置；GameRoot关闭phase并fault，禁止suspend后继续游戏
- 验证: unit + fault integration | Gate: BLOCKING

**AC-E9 primitive handle、弱对象引用与计数器耗尽**
- Given: Node-derived pooled E 被注册/移除/同实例复用；另以测试钩子把 slot generation、handle allocator、grid epoch 分别置于最大值前一位
- When: 查询 carrier、resolve、复用 slot、teardown/reset_to_inactive/re-init 与再次 insert
- Then: 公开 handle 始终是非零 int 且不复用；Grid 不延长 queue_free 后 Node 生命周期；旧 handle 永远 stale；各计数器耗尽均返回 `ID_EXHAUSTED` 并拒绝回绕
- 验证: unit + object lifetime/overflow regression test | Gate: BLOCKING

**AC-E10 API × entry state status 矩阵**
- Given: 同一逻辑 entry 依次处于 pending/active/suspended/removed/old-epoch
- When: 分别调用 stage/remove/resolve_active/query consume
- Then: status 与 R9 precedence/矩阵逐格一致；stage/remove 可操作前三态，pending 非法 stage 的 postcondition 按 E8；resolve 只接受 active，removed/old-epoch 返回 STALE_HANDLE；fresh insert failure 可由 caller 返池，replace/remove failure 不得释放，sync failure 保留 workspace
- 验证: table-driven unit test | Gate: BLOCKING

**AC-E11 CAPACITY_EXCEEDED 不产生幽灵实体**
- Given: ENEMY cap=303，SpawnDirector 为 4 Elite + 1 Boss 预留 5 槽；普通怪 active+pending 已为 298。另设 admission check 后同 phase 其他 participant 抢占容量、以及阶段必需 Elite/Boss 无预留可用的故障注入
- When: 尝试生成普通怪与 Boss，并让 `insert_into` 返回 `CAPACITY_EXCEEDED`
- Then: 普通怪 intent 被抑制，对象不进入可见 SceneTree 分支、不进入 owner active collection、无 handle且安全返池，现有战斗继续并记录 suppressed-spawn telemetry；Boss case 不发布 Boss，回收未发布 candidate 后进入 `ControlledGameplayFault`。任一 fixture 中 SpatialGrid query set、owner active set与可见可交互实体集合一致，不存在可见但不可索引对象
- 验证: SpawnDirector+Enemy owner+Pool+SpatialGrid deterministic integration | Gate: BLOCKING on SpawnDirector integration

### F. 边界处理（R7）

**AC-F1 world-domain含边界**
- Given: center分别位于world safe四边/四角canonical边界、内侧next-representable与外侧next-representable
- When: insert/stage/query
- Then: 边界及内侧合法且原值归格；外侧返回`POSITION_OUT_OF_RANGE`并触发fault，不clamp、不suspend
- 验证: bit-golden unit + integration | Gate: BLOCKING

**AC-F1b world/domain cell包络不溢出**
- Given: world half、CELL_SIZE与绝对硬上限的边界/overflow组合
- When: init派生max_abs_cell_coord
- Then: 合法值装入int64且只分配固定sparse容量；非法返回`INIT_LIMIT_EXCEEDED`，不生成Infinity或dense allocation
- 验证: unit + release black-box | Gate: BLOCKING

**AC-F2 查询跨技术域不回绕**
- Given: 查询中心靠近world safe边界，圆覆盖边界外；对侧有实体
- When: query_circle_into
- Then: 只返回同侧域内命中，不从对侧回绕/镜像；中心越域则失败
- 验证: unit | Gate: BLOCKING

**AC-F3 坐标跨度与CELL_SIZE不改变玩法集合**
- Given: 同一相对实体布局分别平移到原点、(10000,10000)，并用两个合法CELL_SIZE/local与fallback路径
- When: 执行相同相对查询
- Then: canonical object结果集合和nearest winner一致；预分配容量不随跨度变化
- 验证: parameterized golden-set + allocation counters | Gate: BLOCKING

### G. 行为契约与帧时序（R3）

**AC-G1 每帧反映所有活动实体当前位置**
- Given: 一帧内多个实体发生移动
- When: 对唯一 handle 集调用 stage_position 后 SpatialGrid.sync 完成
- Then: 所有活动实体已按最新位置重归格；后续查询基于最新位置
- 验证: unit test（移动/同格移动/跨格/insert/remove → sync → 查询）| Gate: BLOCKING

**AC-G2 完整 physics phase 顺序**
- Given: 一帧的执行序列
- When: GameRoot 执行一个真实 physics tick
- Then: event trace 严格为 `spawn/despawn_intent → movement_committed → grid_sync_started → grid_sync_finished → consumer_query → damage_resolution → deferred_remove → authoritative_collection_committed → optional_pause_barrier`，sync 区间内无 query
- 验证:
  - (a) unit：`_is_syncing` guard 拒绝重入/中途查询。
  - (b) integration：GameRoot spy 记录并断言完整 event trace。
  - (c) manual：确认所有参与者在同一 main-thread physics phase，不依赖隐式 Node 顺序。
  Gate: BLOCKING
- 备注: GameRoot最小GDD已冻结该trace；(b) 仍是其实现集成 story 的 BLOCKING gate，本系统 unit 只证明 guard。

**AC-G3 单一 main-thread orchestrator**
- Given: Enemy/Projectile/Drop 参与真实 integration scene
- When: init 后运行首 tick、第二 tick与一次 pause→prepare→arm→publish→resume end；每个 callback 调 `begin_phase→calls→end_phase`，并注入 duplicate begin、错误 phase/revision、错误 ID end、sync failure与计数器最大值
- Then: init 后唯一首 pair=`(1,SPAWN_INTENT)`、snapshot=0；begin 不推进 pair，matching Active end 才推进；sync=`OK` 才递增 snapshot；错误 end不关闭/不推进；POST barrier end checked生成 next tick/`SPAWN_INTENT`。Paused lease只匹配 frozen snapshot，不改保存的 next Active pair；matching publish递增 snapshot，resume end只关闭lease，随后首个 Active begin必须使用保存的 next pair。旧/关闭 lease重放均 `PHASE_ERROR`，任一 revision overflow=`ID_EXHAUSTED`，failure 后不得开启下一 phase
- 验证: integration test + scene/code review | Gate: BLOCKING on GameRoot integration

**AC-G4 查询 failure 不推进 gameplay**
- Given: Damage 与 Pickup 已成功写入本 phase staging，最后一个 consumer 分别被注入 query `BUFFER_TOO_SMALL/WRONG_STATE/PHASE_ERROR`、resolve `STALE_HANDLE/OBJECT_INVALID` 与 downstream 明确声明的 fatal narrowphase domain error；另设普通 narrowphase no-hit control
- When: GameRoot 执行 query/collision phase
- Then: 每种 fatal case 都丢弃包括先前成功 consumer 在内的整 phase staging，本 tick提交效果为0、lease关闭且下一 consumer/phase不执行；state/lease early failure carrier保持污染值但不被读，carrier层后 failure遵循R9 reset规则。普通 no-hit 继续 phase且提交合法“未命中”结果，不进入 fault
- 验证: deterministic GameRoot integration | Gate: BLOCKING

### H. 状态机

**AC-H1 合法转换**
- Given: 各初始状态
- When: 触发转换
- Then: 合法边为 `Inactive--init→Active`、`Active--request_pause→PausedFrozen`、`Frozen--resume_from→Prepared--arm→Armed--publish→Active`、`Prepared/Armed--abort或end_phase auto-abort→Frozen`、`Active/任一 Paused substate--teardown(no open lease)→TornDown`、`TornDown--reset_to_inactive→Inactive`
- 验证: top-state×Paused-substate 转换矩阵 unit test，并断言 prepare/arm/publish/abort/auto-abort/teardown/reset side effects；TornDown 下重复 teardown 是唯一批准的 `OK_NOOP` 自调用 | Gate: BLOCKING

**AC-H2 非法转换 fail-fast**
- Given: 处于某状态
- When: 触发任一非法边或除重复 teardown 外的未定义自转换
- Then: 主线程但 top state/substate 不允许该转换时固定 `WRONG_STATE`；合法 state/substate 下 lease/transaction 错误固定 `PHASE_ERROR`。特别地 Frozen+open RESUME query/resolve=`PHASE_ERROR`，Prepared/Armed query/resolve=`WRONG_STATE`；两类 early failure均不触碰 carrier。成功 publish后重复 publish=`WRONG_STATE`
- 验证: debug matrix assert test + release strategy/smoke | Gate: BLOCKING

**AC-H3 Inactive / TornDown 状态返回 WRONG_STATE**
- Given: SpatialGrid 处于 Inactive 或 TornDown
- When: 调用 insert/stage/remove/sync/query_circle_into/query_nearest_into
- Then: 均返回 `WRONG_STATE`，不得把空结果伪装成合法查询；内部数据不变，warning 按 `(status,api,grid_epoch)` 每 epoch 一次
- 验证: unit test | Gate: BLOCKING

**AC-H4 TornDown 后可重建（→Inactive）**
- Given: 已 TornDown 的网格
- When: Scene Flow 在主线程且无 open operational lease 时调用 `reset_to_inactive()`，随后 `init(new_config)`
- Then: grid_epoch 已变化，所有旧 handle、pending/staged data、bucket 引用和 instrumentation 已清空，可重新 init；对象释放仍由生命周期 owner 完成
- 验证: unit test | Gate: BLOCKING

**AC-H5 Paused 态查询返回冻结快照（Edge Case 19）**
- Given: 同 tick 发生灵气拾取触发升级、敌人死亡与 deferred remove，E survivor、F pause 期间 spawn、G pause 期间 remove
- When: GameRoot 完成该 tick 后进入 PausedFrozen，mutation 返回 PAUSED；随后 capture→prepare→arm，在 consumer-closed window 按 `Grid publish→Pool publish→authority publish` 提交并 end_phase
- Then: Frozen pause-read 返回旧 snapshot；Frozen+resume-exclusive open 的 query/resolve=`PHASE_ERROR`，Prepared/Armed=`WRONG_STATE`，均不触碰 carrier；PAUSED remove 不允许 release/reborrow。arm 与三次 publish 前均验证 frozen config/identity；E 保留 sequence，F 获新 handle，G 旧 handle stale；matching Grid publish 必为 OK，只有 authority publish 完成且 lease 关闭后才开放下一 Active begin，期间无重复XP、ghost或目标跳变
- 验证: unit + deterministic GameRoot integration | Gate: BLOCKING

**AC-H6 Active 期间禁止热改 CELL_SIZE**
- Given: SpatialGrid 为 Active，已有有效 handle
- When: 请求改变 CELL_SIZE
- Then: debug assert；release 返回 `WRONG_STATE` + 限频 warning，旧 CELL_SIZE、bucket 和查询结果不变。只有 `teardown→reset_to_inactive→init(new_size)→Active` 可生效
- 验证: debug unit + release strategy test | Gate: BLOCKING

**AC-H7 resume_from validate-then-publish 失败原子性**
- Given: Paused frozen snapshot，分别构造 duplicate object/handle、非法位置、invalid Node、容量超限、ID耗尽与内部 rebuild failure 输入
- When: prepare 后分别执行显式/auto abort、错误 tx/lease arm/publish、arm snapshot-revision耗尽、owner swap failure、matching Grid publish，并由 GameRoot 在 Pool/authority publish checkpoint 注入 config/identity mismatch
- Then: Grid prepare/arm 前失败保持旧 Frozen；arm 耗尽=`ID_EXHAUSTED`并保持Prepared，仅允许 matching abort/end auto-abort，清理后进入 ControlledGameplayFault且不得重试 resume；wrong tx/lease=`PHASE_ERROR`且不交换。matching Armed Grid publish 无可注入内部 failure、必为`OK`并发布预检 revision；其后 Pool/authority failure 不“回滚”已发布 Grid，而由 GameRoot 的 AuthorityResumeCommitPlan 完成 fail-closed 收敛且 consumer 始终关闭。三次发布完成后重复 Grid publish=`WRONG_STATE`。abort后 remap 旧值不权威，已保留 handle/transaction ID 永久 burn
- 验证: table-driven unit + integration | Gate: BLOCKING

### I. 查询覆盖与正确性验证（F2 / F3）

**AC-I1 安全覆盖诊断与实际访问一致**
- Given: 多个world-domain/CELL_SIZE/center（原点、负格、技术域边/角）和radius={0,0.5CS,CS,1.01CS,3CS,ceiling前后}
- When: circle/nearest 查询
- Then: local路径`actual_cells_visited≤MAX_QUERY_CELLS_ENUMERATED`且诊断1/9/25/49正确；fallback路径`actual_cells_visited=0,active_entries_examined≤1000`；两者golden set无漏/重
- 验证: 参数化 unit test，读取实例级诊断 | Gate: BLOCKING

**AC-I2 radius > CELL_SIZE 的 debug/release 结果相同**
- Given: CELL_SIZE=2、radius=5，目标分布在距离 1/2.5/4.9/5.1
- When: debug 与 release artifact 查询
- Then: 两者都返回 1/2.5/4.9，排除 5.1；不得 assert、clamp 或缩小玩法语义
- 验证: debug unit golden set + release export black-box golden set | Gate: BLOCKING

**AC-I3 canonical fallback阈值与极大finite半径**
- Given: 合法domain/CELL_SIZE/center；radius取enumerated count等于/大于262144、`1e100`、最大finite，并含target=(1,1)、radius=1.41421355舍入分歧fixture
- When: debug/release 调用 circle/nearest
- Then: 等于ceiling可local枚举，大于ceiling与极大值走active-entry fallback；不发生int/平方溢出。舍入分歧target不命中，全部结果与同一`spatial_distance_value`暴力oracle一致
- 验证: unit + release black-box golden set | Gate: BLOCKING

### J. 性能标准（硬约束）

**AC-J0a 桌面 GDScript primitive baseline（OQ7 主 spike 前置）**
- Given: 与目标 Godot 4.7.1 项目相同 real_t/export mode 的桌面 release artifact，固定 CPU/power mode；为 `Dictionary[Vector2i]` hit/miss、PackedInt64Array read/write、Node identity validation、float64 squared-distance、float64 sqrt distance、swap-remove+reverse-slot fixup 各准备无分配 microbench 与 empty-loop baseline
- When: 每 primitive 先 warmup 10 batch，再测 1000 batch×10,000 ops；以 paired `test−empty` 计算净 ns/op，记录 p50/p95/p99/max、allocation events/bytes、create/resize counters、artifact hash与环境。距离 fixture 使用相同 finite domain，sqrt 与无 sqrt 必须分开；不得把多 primitive 混成一个“query 常数”
- Then: 六类成本表全部有非负、可复现的三轮结果，正式路径 allocation/create/resize delta=0，positive control 可观测；据此代入 F5 的 `T_query` 公式并报告 120,000 candidate checks/frame 的桌面估算。该结果仅校准 OQ7 workload、仍为 EVIDENCE ONLY，不能替代 AC-J0/J2 Android 真机 gate；缺任一 primitive 或 harness 失去 positive-control 观测能力时，禁止启动更新策略主 spike
- 验证: desktop exported release microbenchmark artifact + reproducible manifest | Gate: BLOCKING before OQ7 strategy spike（非 production sign-off）

**AC-J0 benchmark readiness gate**
- Given: 准备宣称任何真机性能 AC 通过
- When: 检查 benchmark manifest
- Then: 必须填写精确 Android SKU/SoC/RAM/OS、Godot/export preset、`physics_ticks_per_second`、分辨率/画质、VSync/帧率上限、系统 power mode、world-domain与坐标跨度、seed/布局、query mix、local/fallback比例、F5计数、warmup、采样时长、重复次数、设备温度与artifact hash。当前用户暂无min-spec真机，故Android performance gate **OPEN**；桌面只能作相对spike。
- 验证: manifest review | Gate: BLOCKING before production performance sign-off；不阻塞设计修订和孤立 spike

**AC-J1 满载实体规模（1003 活动对象）— 集成 release gate**
- Given: 场上298普通敌人+4 Elite+1 Boss（303 ENEMY索引目标）+400投射物调用方+300 DROP索引目标=1003活动对象；manifest分别记录per-type上限与实际索引数
- When: 持续运行于 min-spec 基准设备
- Then: mean≤20ms、p95≤20ms、p99≤33.3ms、>50ms 帧占比≤0.1%，不得出现连续 2 帧 >50ms；目标 mean≤16.6ms
- 验证: J0 锁定的 release artifact，warmup 后每组≥60s、至少3轮 | Gate: BLOCKING（集成 release gate；J0 OPEN 时不可判定）
- 备注: 此为整帧预算上限（集成级），SpatialGrid 须在其中占子预算份额（见 AC-J2/J3/J3b）。本 AC 归 release gate，非 SpatialGrid 孤立 unit/perf gate。

**AC-J2 SpatialGrid 子预算冻结**
- Given: J0 就绪、F3/data-layout/update-strategy spike 完成
- When: technical-director 评审 update + 聚合查询 self-time
- Then: frame-budget ADR 写出 `sync self-time`、`aggregate query self-time`、`combined grid phase time` 的具体 p50/p95/p99 数值阈值与 profiler 归因；阈值冻结前所有 timing 仅标 `EVIDENCE ONLY`
- 验证: benchmark report + frame-budget ADR | Gate: BLOCKING before implementation story Done

**AC-J3 查询 microbenchmark 方法**
- Given: 固定 candidate occupancy/radius/filter/result API；timing 每 batch=10,000 calls、warmup=10 batch、**measurement=1000 batch**（performance-analyst B2 闭环：n=100 估 p99 方差过大，nearest-rank p99 on n=1000=第 999 排序值，且 p99 判定须 3 轮独立采样中位数一致）；allocation 另跑 10 组相邻 paired batch（每组先 empty baseline 10,000 calls，再 test 10,000 calls）；同 artifact 含两个独立 positive control：A 为 consumer 每 query 使用 `range(out.count)`，B 为每 query 故意创建 1 Object+1 Array
- When: profiler-off timing 以每个 batch 的总时长/10,000 形成 **1000 个 per-call-normalized 样本**；profiler-on allocation 对每组记录整数 `allocation_events/allocated_bytes/create_counter/resize_counter`，delta 固定为 `test-baseline`，不得把负值 clamp 后掩盖 harness 不稳定
- Then: timing 的 p50/p95/p99/max 明确是上述 1000 个 batch-normalized 样本的 nearest-rank percentile（**p99 = 第 999 排序值，须 3 轮独立采样中位数一致方为有效判定**），并报告 cells/candidates/results；正式路径 10 组中 carrier identity/capacity 均不变、自定义 create/resize counter 精确为 0，且每组平台 `allocation_events_delta=0`、`allocated_bytes_delta=0`，任一非零或负 delta 都 fail 并重查 harness。positive control A 的 allocation/bytes delta 必须 >0；positive control B 每组 observed **Object create delta ≥ calls 数且 Array create delta ≥ calls 数**（即总 create delta ≥2×calls 数）、allocated-bytes delta>0；两者都必须 fail，证明工具能观察 range 迭代容器与显式对象分配。manifest 固定 allocation 工具/版本/采样配置，不接受可能恒为 0 的泛化 monitor
- 验证: exported release benchmark scene + positive-control artifact + 经 allocation-observability ADR 批准的平台 profiler | Gate: BLOCKING evidence for AC-J2

**AC-J3b 每帧聚合查询预算**
- Given: production workload 由固定 seed 的 Enemy/Projectile/Drop/Skill 消费者 trace 导出；另保留 700/1000/1500 queries/frame 作为 stress tiers。manifest 写明各调用方比例、半径、filter、结果数与 buffer capacity
- When: 一帧内所有 query_circle_into / query_nearest_into 合计
- Then: 报告聚合 self-time p50/p95/p99、allocation/frame；production trace 与 stress tiers 分开判读，并满足 AC-J2 冻结后的对应子预算
- 验证: release benchmark | Gate: BLOCKING after AC-J2 threshold frozen

**AC-J4 怪潮峰值密度不卡顿**
- Given: synthetic bucket occupancy=32/64/128/300、中心3×3聚集、边界聚集和全桶 adversarial；后续追加 EnemySystem 固定 seed 实测分布。每个 workload 用相同 303 ENEMY snapshot/query mix 同时运行 SpatialGrid、直接遍历 ENEMY authoritative collection、遍历全部 1003 活动对象后三态 type filter 三个基线
- When: 在峰值密度区域高频查询
- Then: 分别报告三组 `candidates_tested/result_items_written/aggregate self-time` 与置信区间，不把 DROP/projectile caller 混进 ENEMY-only 公平基线，也不预设候选收窄倍率；中心3×3全聚集时明确允许 Grid≈ENEMY-only 约1.0×。SpatialGrid combined phase p99 仍须不超过 AC-J2/ADR 子预算；其多查询扇出/复合局部性收益在 J0/J2 前仅 EVIDENCE ONLY。整帧使用 AC-J1 的 mean/p95/p99/长帧规则
- 验证: synthetic release benchmark（现在可建，J2 前仅 EVIDENCE ONLY）+ EnemySystem integration benchmark（后续）| Gate: BLOCKING after J0/J2

**AC-J5 更新策略复杂度符合声明（F5）**
- Given: 按 F5 完整 tick 窗口生成 `N_start/C/A_stage_success/D/M/I/R_pre_sync/R_deferred/R_bucket/T_suspend/T_resume/W_same/N_sync_active/N_end_active` 倍增与事件顺序矩阵。至少包含无 intent 空 tick、同一 handle 分别 stage 1/2/8/100000 次、insert→cancel、remove→insert、sync 前 remove、damage 后 deferred remove、same-cell、cross-cell、active↔suspended、成功 sync 与 fatal sync/query cleanup
- When: 记录 `staging_writes/entities_inspected/cells_cleared/cross_cell_updates/bucket_removals/bucket_inserts/entry_state_writes/slot_table_writes/candidates_tested/result_items_written` 及时间；`structural_operations` 固定为前八个结构计数之和，每个高层 staging/entry/cell 动作计数一次，不统计容器私有机器指令
- Then（**始终 BLOCKING 的确定性不变量，不受 OQ7/J0/K 标定状态影响**）：所有策略必须满足 `staging_writes=A_stage_success`；insert→cancel 必须观测 pending slot 创建与失效，same-cell committed-center write必须进入 `entry_state_writes`，suspend/resume 与 pending cancel不得归零，重复 stage 成本不得藏入 D。增量 B1/B2 必须满足 `cells_cleared=0`、`cross_cell_updates≤M`、`bucket_removals≤M+T_suspend+R_bucket`、`bucket_inserts≤M+T_resume+I`、`W_same≤entry_state_writes≤D+I+R`、`slot_table_writes≤3M+2T_suspend+T_resume+2I+3R_bucket+(R−R_bucket)`；B1 的 `entities_inspected≤N_start+D+I+R`，B2 的 `≤D+I+R`。clear-rebuild 必须满足 `entities_inspected≤N_start+D+I+R`、`cells_cleared≤C`、`cross_cell_updates=0`、`bucket_removals≤R_bucket`、`bucket_inserts≤N_start+I−R_pre_sync`、`W_same≤entry_state_writes≤D+I+R`、`slot_table_writes≤I+2R_bucket+(R−R_bucket)+(N_start+I−R_pre_sync)`；成功 sync 还必须满足 `N_end_active≤N_sync_active≤N_start+I−R_pre_sync`。任一逐项矩阵点超界立即 fail，不能由总数或性能结果豁免。
- Then（**同样始终 BLOCKING 的 query counter 不变量**）：`candidates_tested≤Σ(被扫格 active entry 数)` 且 `result_items_written≤out carrier capacity`；`BUFFER_TOO_SMALL` 时 `result_items_written=0` 且 `required_capacity=实际命中数`。这两个 counter 不计入 K，超界或漏计立即 fail。
- Then（**仅 EVIDENCE ONLY 的经验 allowance**）：`structural_operations≤上述适用逐项 RHS 之和+K` 中的 `+K` 及暂定 `K=8` 只覆盖 lease/generation/epoch bookkeeping、counter reset、sub-phase 切换等未被逐项模型命名的固定编排残差；它不降级前两条确定性不变量。在 OQ7 选定策略前，只有这条“总和+K”判据为 EVIDENCE ONLY。策略选定后，以 N=1003/聚集工况的残差分布标定最终 K（须≤8；超界则修订 F5 模型，不能放大 K），随 frame-budget ADR 升为所选策略的 BLOCKING gate。若报告宣称某策略“显著更快”，combined p99 改善必须同时≥10%且大于两方案 95% CI half-width 之和
- 验证: operation-counter test + release timing | Gate: BLOCKING after strategy ADR

**AC-J6 满载 churn 下正确性与性能同时成立**
- Given: 固定 seed replay 含 303 ENEMY、300 DROP、400 projectile callers，并持续执行无 intent 空 tick、spawn、pending insert/replace/cancel、同 handle重复 stage、same-cell/cross-cell stage、active↔suspended、sync 前 remove、damage 后 deferred remove、对象池同实例/同 slot 复用、Paused prepare/arm/abort/publish 与大型 Boss/移动目标 swept bound 查询
- When: 同一输入分别运行暴力 O(N) oracle 与 release SpatialGrid；逐 API call 比较 status/count/required_capacity、circle canonical object set、exact nearest winner、resolve 结果、resume remap 与 downstream swept hit set
- Then: `false_negative_count=false_positive_count=duplicate_count=wrong_nearest_count=stale_handle_count=bad_remap_count=unexpected_phase_error_count=buffer_overflow_count=0`；同时满足 AC-J2/J4 子预算，Active steady state 与使用预分配 workspace 的 pause/resume publication 均 allocation/frame=0
- 验证: deterministic integration replay + release benchmark（相同 seed/artifact manifest）| Gate: BLOCKING before implementation story Done

### K. 架构约束（R8 禁止高频附近查询遍历全场）

**AC-K1 依赖系统通过查询接口获取附近实体**
- Given: 范围攻击 / AI 等依赖系统需要附近实体
- When: 实现该系统
- Then: 高频附近查询必须通过 circle_into/nearest_into，并检查 status；生命周期系统可以持有权威 active collection，低频全局语义效果可遍历该集合
- 验证: 各下游 integration story 注入 SpatialGrid spy + code review；不以 grep 单独判定 | Gate: BLOCKING on downstream integration，非 SpatialGrid 单体

**AC-K2 SpatialGrid 不暴露全量迭代接口**
- Given: SpatialGrid 公开 API
- When: 审查接口
- Then: 不提供 get_all_entities() / iterate_all() 这类全量遍历接口（调试用接口须显式标注 DEBUG_ONLY）
- 验证: manual（代码审查）| Gate: BLOCKING

**AC-K3 宽相候选与真实形状命中职责分离**
- Given: 小型敌人、大型 Boss 和非圆形目标跨格/位于 AoE 边缘；另有仅与 projectile p0→p1 段中部相交的静态快照目标。数值 fixture 使用 real_t32 `p0=(999999.9375,-999999.9375)`、`p1=(1000000.0,-1000000.0)`，其 scalar midpoint 两分量分别落在相邻 real_t32 值中间，使 `midpoint_cast_error=sqrt(2)/32`；moving-target fixture 同时记录目标上一与 tick-end committed shape
- When: Damage 使用 `effect_radius+max_bound`；Projectile 严格按 R10 的四个 float64 scalar、中点乘加顺序、Vector2 cast/readback 与 canonical distance helper，加入实际 midpoint_cast_error，并以 `target_motion_bound=0` 执行 tick-end discrete swept narrowphase
- Then: 段中静态快照目标与依赖 cast-error 扩张的边界目标均进入候选且最终命中；未相交候选由窄相排除。moving-target oracle 只以 tick-end committed shape 判定，不能声称连续 relative hit；endpoint-only、先用 Vector2/real_t 求中点、漏 cast error、偷偷加入上一目标位置、或直接把 Grid 候选当最终命中的实现不得通过。fixture 还必须断言 runtime actual error≤registry `sqrt(2)/32` cap
- 验证: downstream integration golden scenes | Gate: BLOCKING on Damage/Projectile integration

**AC-K4 pickup 与 nearest 几何语义**
- Given: Drop shape 边缘进入但 center 仍在 pickup_radius 外，以及 AC-C7 的两名敌人
- When: DropSystem读取Player motion view执行pickup，Weapon/TargetingSystem读取同一view执行自动索敌
- Then: MVP pickup 只在 Drop center≤pickup_radius 时发生，不使用 drop bound；nearest_into 返回 center-nearest。若需求改为 shape 语义，未同步 broadphase+narrowphase+AC 的实现不得通过
- 验证: Player/Drop/Weapon integration golden scene | Gate: BLOCKING on downstream integration

**AC-K5 query/resolve/fatal narrowphase failure 的 release 消费策略**
- Given: 分别对每个 query failure status、`resolve_handle` 的 `STALE_HANDLE/OBJECT_INVALID` 和 fatal narrowphase failure 注入一次，并让同 phase 较早 consumer 已写 staging、out carrier 保留故意污染的旧槽位；另设合法 no-hit 的 `OK,count=0/has_handle=false` 控制组
- When: Damage/Projectile/Drop/Weapon/Enemy consumer 在 release artifact 执行
- Then: 任一注入 failure 都使所有调用方中止整个 query/collision phase且不读取旧槽位，较早与当前 consumer 的 staging 全部回滚，lease 关闭，不提交部分效果；GameRoot 进入 ControlledGameplayFault；没有任何 failure status 被映射为空集合。合法 no-hit 控制组保持 `OK`、提交该 phase 的其他合法 staging且不触发 ControlledGameplayFault
- 验证: release integration strategy test | Gate: BLOCKING

### 覆盖核对表

| 规则/公式 | 覆盖标准 |
|---|---|
| R1 均匀哈希网格 / 可表示域 | AC-A1, AC-A3, AC-F1b, AC-I3 |
| R2 统一查询命名空间+类型标记 | AC-D1~D3 |
| R3 行为契约/帧时序 | AC-G1~G4 |
| R4 query_circle_into（缓冲区、实例诊断、合法半径） | AC-B0, AC-B1~B7, AC-B4b, AC-I2~I3 |
| R5 query_nearest_into | AC-C1~C7 |
| R6 insert/remove/handle epoch | AC-E1~E11 |
| R7 有限world-domain / 不回绕 / 不clamp | AC-F1~F3 |
| R8 禁止遍历全场 | AC-K1~K2 |
| R9 status/carrier/release policy | AC-B6~B7, AC-E10, AC-G3~G4, AC-K5 |
| R10 consumer geometry | AC-C7, AC-K3~K4 |
| F1 signed world归格 / checked limits | AC-A2, AC-A3 |
| F2 理论/实际覆盖格 | AC-B3, AC-I1 |
| F3 CELL_SIZE benchmark 选型 | AC-A4, AC-A5, AC-A7, AC-J2~J5 |
| F4 occupied-cell密度与峰值 | AC-A6~A7, AC-J4 |
| F5 复杂度对比 | AC-J5, AC-E5 |
| 状态机 | AC-H1~H7 |
| Edge Case 4（NaN/Infinity / 超域） | AC-A3, AC-E6, AC-E8 |
| Edge Case 7（world-domain边界） | AC-F1 |
| Edge Case 9（enumeration ceiling fallback） | AC-I3 |
| Edge Case 12（查询穿插增量更新） | AC-G2(b) |
| Edge Case 19（Paused 快照/恢复事务） | AC-H5, AC-H7 |
| Edge Case 21（CELL_SIZE 运行时不可热更） | AC-H6 |
| Edge Case 23（world-domain或sparse容量非法） | AC-A3, AC-J0 |
| radius = 0 / < 0 | AC-B4, AC-B5 |
| CELL_SIZE ≤ 0 | AC-A3 |
| 幂等（重复 insert / remove 不存在） | AC-E3, AC-E4 |
| 等距确定性 + 跨帧稳定 | AC-C3, AC-C5 |
| 非 Active 态明确 WRONG_STATE | AC-H3 |
| 满载 correctness + performance 联合 | AC-J6 |

### Edge Case 覆盖矩阵（qa-lead BL-3 闭环）

> 逐条核对 29 个 Edge Case 与 AC 的映射，使覆盖可静态验证无遗漏。每行一个 EC，标主覆盖 AC（含本轮新增 AC-B0）。多 AC 覆盖时按"行为主断言"在前、"边界/负向断言"在后排列。

| EC# | Edge Case 摘要 | 覆盖 AC |
|-----|---------------|---------|
| 1 | radius=0 只返回中心点、分量精确相等 | AC-B4, AC-B4b |
| 2 | radius<0 dev assert / release INVALID_ARGUMENT | AC-B5 |
| 3 | CELL_SIZE/world-domain违反finite/int64包络 → INIT_LIMIT_EXCEEDED | AC-A3, AC-F1b, AC-J0 |
| 4 | NaN/Infinity/超world safe domain | AC-A3, AC-E6, AC-E8 |
| 5 | 实体恰在格边界归右/下侧高索引格 | AC-A2 |
| 6 | 向零截断 vs floori() 归格 | AC-A2 |
| 7 | center位于world-domain边界/内外next-representable | AC-F1 |
| 8 | 查询圆跨技术域不回绕/不镜像 | AC-F2, AC-B3 |
| 9 | 概念cell数超过ceiling走active-entry fallback | AC-I3 |
| 10 | 同对象重复 insert（同值 OK_NOOP / 异值 OK_REPLACED 或 INVALID_ARGUMENT） | AC-E3, AC-E4 |
| 11 | remove 无效/旧 epoch/已移除 handle → STALE_HANDLE no-op | AC-E2, AC-E4, AC-E7 |
| 12 | sync 中途查询 / phase failure 回滚整 phase | AC-G2, AC-G3 |
| 13 | 空网格合法查询返回空结果 | AC-B0 |
| 14 | type_filter 半径内无匹配类型 → OK,count=0 | AC-D2, AC-B2 |
| 15 | nearest 等距取最小 registration_sequence 稳定 tie-break | AC-C3, AC-C5 |
| 16 | nearest 半径内无匹配 → has_handle=false | AC-C2, AC-C4 |
| 17 | 中心格空且邻格无匹配 → OK,count=0 | AC-B0, AC-B2 |
| 18 | Active 时 insert sync 前不可查询 / remove active 立即失效 | AC-E1, AC-E7 |
| 19 | Paused 冻结 snapshot / resume prepare→arm→publish 事务 | AC-H5, AC-H7 |
| 20 | Inactive/TornDown 调 API → WRONG_STATE（非合法空结果） | AC-H3, AC-B6 |
| 21 | CELL_SIZE 运行时不可热更，须 teardown→reset→init 重建 | AC-H6 |
| 22 | 怪潮聚集 bucket occupancy 32/64/128/300 保持正确 | AC-J4, AC-J6 |
| 23 | world-domain非法或bucket容量随world面积增长 → 阻止Active | AC-A3, AC-J0 |
| 24 | SkillConfig 未定义时 CELL_SIZE=2.0 仅 spike 锚点 | AC-A4, AC-A7 |
| 25 | F3候选为空 → 保留合法2.0 spike anchor | AC-A5, AC-F3 |
| 26 | F4 N=0不除零；occupied count合法 | AC-A6, AC-A7 |
| 27 | 投射物段中相交/endpoint 外目标 → swept broadphase 仍纳入候选 | AC-K3, AC-C7 |
| 28 | query/resolve/fatal narrowphase failure → rollback 整 phase并进入 ControlledGameplayFault，不降级为空集合 | AC-G4, AC-K5 |
| 29 | 容量满普通怪 spawn 抑制 / Boss 预留不可用 → 不产生可见不可索引幽灵实体 | AC-E11 |

**核对规则**：上表 29 行必须与 Edge Cases 节的编号 1–29 一一对应，不得缺号或重号；任一 EC 若标"无 AC 覆盖"即触发新增 AC，不得留空。qa-lead 在 review-log 记录本矩阵的行数核对（29/29）。

## Open Questions

### 性能输入待冻结（高优先级）

**OQ1 — SkillConfig/成长后的完整有效宽相半径分布**
- 影响：F3 sweep workload 与 max_query_radius 未完整；必须同时提供 effect radius 与目标 conservative bound。**不影响查询正确性**，只阻塞生产 CELL_SIZE ADR。
- 触发：SkillConfig GDD 完成。
- 缓解：CELL_SIZE=2.0 仅作 spike 锚点，合法大半径仍按 F2 正确扫描。

**OQ2 — 稀疏bucket私有布局与production CELL_SIZE**
- 已冻结：Stage V2 world half=16384、entry cap=1000、query enumeration ceiling=262144；world面积不得决定bucket容量。
- 仍OPEN：open-address table / sorted table /等价结构、load factor、tombstone与production cell size，须ADR+真机benchmark。

### F3 输入缺失（中优先级）

**OQ3 — separation / projectile segment+bound / target range 数值**
- 影响：F3 workload 与候选 sweep 仍不完整；swept broadphase、scalar midpoint、real_t32 cast-error 上界与 tick-end discrete target sampling 已冻结，ProjectileSystem 只剩最大单 tick segment、projectile bound、target bound 的生产数值待提供。`max_target_motion_bound=0` 与 `max_midpoint_cast_error=sqrt(2)/32` 不再是 open question。
- 触发：EnemySystem GDD、ProjectileSystem GDD 完成。
- 缓解：`max_query_radius` 当前下界仅由 `pickup_radius_max = 1.98` 支撑；上述 GDD 完成时回填。

### → 架构决策（ADR 触发点，非 GDD 决策）

**OQ4 — 数据布局 + F5 更新策略选型**【→ ADR】
- 问题：私有稀疏bucket采用预分配open-address/sorted table、mixed/per-type；更新采用occupied-clear-rebuild / polling incremental / dirty-notification incremental。public carriers已冻结，dense world array被本修订禁止。
- 归属：架构决策，归 `/architecture-decision`。GDD 已冻结零分配、public carrier 表示、调用方 ownership、容量校验与溢出行为；ADR 只选择满足这些行为的私有容器/算法。
- 影响 AC-J5：选定策略后据此细化判据。
- 触发：进入 SpatialGrid 实现阶段，由 technical-director 主导 ADR。

**OQ5 — query_nearest_into 正确实现模式**【→ ADR】
- 当前决策：MVP固定扫描全部相交occupied cells/candidates；超过enumeration ceiling时扫描全部active entries。普通first-hit/未证明early exit不进入本轮ADR。
- 未来触发：只有 profiling 证明 nearest 为瓶颈，且新 GDD/AC 冻结 expanded boundary-cell 下界并通过 margin golden fixture 后，才可另开 best-first ADR。全局最近与等距 stable registration_sequence 不变。

### GDScript 可行性验证（高优先级 — ADR 前置）

**OQ7 — 纯 GDScript 性能可行性 spike**【→ ADR 前置】
- 问题：优化后的 GDScript 在 J0/J3b/J4 固定 workload 下能否满足 AC-J2 批准后的子预算？当前 5–30μs 与 700–1500 仅是假设/工作负载档位，不是证据。
- 归属：先做 GDScript release baseline；只有 SpatialGrid attributable p99 在同一 manifest 下连续 3 次超过已批准子预算，且排除分配、fixture 与 profiler 开销后，才触发 **GDExtension 成本/收益 ADR**，不自动决定迁移。
- 若进入 GDExtension，ADR 必须计入 godot-cpp/SCons、Android/iOS 各架构 debug/release library、CI/export smoke 和跨 native boundary 成本。
- 触发：进入 SpatialGrid 实现阶段前，由 technical-director 主导早期 spike。
- 缓解：spike 未跑前，公共 GDScript API/载体行为保持不变；下游系统不得假设私有 bucket 算法，GDExtension 只能作为满足同一契约的后备实现。

**OQ8 — min-spec Android 真机**【J0 OPEN】
- 当前：用户暂无可锁定真机，禁止虚构 SKU 或宣称 release gate 已通过。
- 触发：获得可重复使用的真机后填写 SKU/SoC/RAM/OS，并冻结 benchmark manifest。
- 缓解：桌面或任意设备可以比较方案相对趋势，但只能标记 spike evidence。
