# Config/Data System（配置与运行时快照）

> **Status**: Draft — minimum foundation contract
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-08-19
> **Implements Pillar**: 300敌人、400投射物、300掉落物压力目标可复现、可校验且不靠运行时魔法值
> **Scope**: MVP battle foundation config；本轮只冻结 Object Pooling 与 SpatialGrid 所需数据

## Overview

Config/Data System 把编辑期 Godot Resource 数据校验并发布为每场战斗唯一、不可变的 `BattleConfigSnapshot`。它是 `pool_key`、逐 key 对象池容量、`PoolLimits`、SpatialGrid 数值域与 per-type 注册上限的权威来源；GameRoot 只有在 snapshot 完整通过 checked validation 后，才能按同一份数据预分配 authority carriers、初始化 BattlePoolSet 和 SpatialGrid。CSV/JSON 可以作为离线导入源，但运行时只消费已生成并随构建交付的 `.tres`/Resource，不在战斗中解析文本、热更或静默采用默认值。

## Player Fantasy

玩家不会直接看到配置系统；它带来的体验是同一版本、同一 seed 的怪潮密度和性能压力可以稳定复现，进入试炼时不会因漏配池容量而少怪、因数组不足而漏命中，也不会在升级或暂停恢复时突然卡顿。非法内容必须在开战前被阻止并给出低干扰错误，而不是让玩家在十分钟后才遇到对象耗尽或范围攻击失真。

## Detailed Rules

### R1 — 权威格式、版本与单次发布

- 编辑期权威资产为 Godot 4.7.1 typed Resource（`.tres`）；CSV/JSON只允许通过离线 importer 生成Resource，不能成为release runtime的第二套权威来源。
- 根资源 `BattleConfigManifest` 固定包含：`schema_version`、非零 `content_revision:int64`、artifact `content_hash`、`PoolLimits`、定序 `PoolKeyConfig[]`、`SpatialGridLimits`、定序 `SpatialTypeLimit[]`、Stage/consumer config references。MVP `schema_version=1`；Stage/consumer引用可在foundation fixture中缺省，但不能达到battle_ready。`run_seed`不是内容调谐字段，不进入manifest/content hash。
- `ConfigRepository.build_snapshot(manifest,required_readiness,run_start_request) -> ConfigStatus` 在BOOT/BATTLE_LOADING主线程执行 validate-then-build；BATTLE/BENCHMARK要求`run_start_request.run_seed:int64`存在并逐位复制到snapshot。成功生成新的非零、进程内单调`snapshot_id`并一次替换published snapshot；失败时旧snapshot保持不变。
- `BattleConfigSnapshot` 是本局只读值快照，至少携带 `{snapshot_id,schema_version,content_revision,content_hash,run_seed,...flattened config}`。`run_seed`来源唯一为PREP冻结的`RunStartRequest`，同一局不可更改或重新派生；RNG只消费snapshot副本。
- validator按pool/type ID排序并用固定字段/float位值序列化后重新计算canonical hash；hash输入明确排除`content_hash`自身、编辑器对象instance ID、绝对本地路径与注释，只包含schema/content revision、行为字段及稳定asset UID/contract ID，避免自引用与机器差异。重算值必须与manifest `content_hash`相等。同一`content_revision+content_hash`必须生成逐字段相同的snapshot与diagnostic；revision相同但hash不同、hash相同但revision倒退均为manifest错误。

### R2 — Public status、诊断与校验顺序

- `ConfigStatus` 固定为primitive int enum：`OK`、`INVALID_ARGUMENT`、`SCHEMA_VERSION_MISMATCH`、`REVISION_ERROR`、`DUPLICATE_ID`、`MISSING_REFERENCE`、`LIMIT_EXCEEDED`、`DERIVATION_ERROR`、`ASSET_INVALID`、`ID_EXHAUSTED`、`WRONG_STATE`。只有OK为success。
- 校验顺序固定为：`main-thread/state → manifest/schema/revision/hash → ID uniqueness/order → references/assets → scalar finite/domain → Pool F1与PoolLimits → Spatial limits/type caps → Stage grid derivation → query envelope/readiness → snapshot build/publish`。组合错误返回最先失败层的唯一status。
- build failure不得发布部分数组、部分pool key或“能用的那一半”。诊断保存 `{status,resource_id,field_path,expected,actual,content_revision}`；release UI只显示通用开战失败文案，具体字段仅进入dev log/telemetry。
- validation不得加载网络内容、读取用户存档中的调谐值或依据设备实时性能改写容量。构建artifact、manifest hash和配置revision共同决定行为。

### R3 — Stable IDs 与资源引用

- `pool_key`固定为非零signed 32-bit int；0保留为NONE。MVP key 1–6 见R4，不能按数组索引、Resource实例ID或scene path临时生成。
- 每个 `PoolKeyConfig` 包含 `{pool_key,stable_name,factory_scene:PackedScene,factory_contract_id,reset_contract_version,criticality,max_concurrent_borrowed,max_pause_replacement_overlap,max_spawn_before_release_overlap,safety_spare,configured_capacity}`。BATTLE readiness要求factory_scene存在且root实现matching contract/version；foundation fixture可使用明确的test factory。
- `criticality`固定为primitive enum：`GAMEPLAY=1`、`PRESENTATION=2`。Config只能声明criticality，不能替下游GDD批准presentation drop policy。
- 同一manifest内pool_key与stable_name不得重复或空缺；factory contract不得为空，factory scene必须通过其required readiness层的存在性/类型检查。按pool_key升序canonicalize后再hash/build，输入Resource数组顺序不改变snapshot结果。
- Spatial type mask沿用 `ENEMY=1`、`PROJECTILE=2`、`DROP=4`、`ALL=7`；`SpatialTypeLimit`的type mask必须恰好一个已知bit且不得重复。

### R4 — MVP 逐 pool_key 基线

以下是MVP schema v1的精确基线；`configured_capacity`逐行等于F1 required capacity：

| pool_key | stable_name | factory contract | criticality | max concurrent | pause overlap | spawn-before-release | spare | configured capacity |
|---:|---|---|---|---:|---:|---:|---:|---:|
| 1 | `enemy_normal` | `EnemyNormalPoolable/v1` | GAMEPLAY | 300 | 0 | 12 | 8 | 320 |
| 2 | `enemy_elite` | `EnemyElitePoolable/v1` | GAMEPLAY | 2 | 0 | 1 | 3 | 6 |
| 3 | `enemy_boss` | `EnemyBossPoolable/v1` | GAMEPLAY | 1 | 0 | 0 | 0 | 1 |
| 4 | `projectile_gameplay` | `ProjectilePoolable/v1` | GAMEPLAY | 400 | 0 | 32 | 16 | 448 |
| 5 | `drop_gameplay` | `DropPoolable/v1` | GAMEPLAY | 300 | 0 | 16 | 4 | 320 |
| 6 | `damage_number` | `DamageNumberPoolable/v1` | PRESENTATION | 64 | 0 | 16 | 16 | 96 |

- 六种普通敌人必须在本基线下共享`EnemyNormalPoolable/v1`的pool/reset contract，以config behavior ID区分；两种精英共享elite contract；Boss独立。若EnemySystem GDD证明必须拆成更多PackedScene/script contract，必须先修订本表、总容量和PoolLimits，不能在实现中私自增加key。
- ENEMY gameplay active压力锚点严格为`300 normal + 2 elite + 1 boss = 303`；PROJECTILE为400；DROP为300。damage number的64是合并后同时可见label上限，不进入SpatialGrid。
- `spawn-before-release`是同一整tick内超过steady concurrent目标的暂态额度，不允许owner把它当永久提高active cap。owner超过该额度前必须通过自身聚合/排队规则保持业务价值，不能要求Pool动态扩容；具体聚合语义由Spawn/Drop/Projectile/Damage GDD承接。
- `damage_number`虽为PRESENTATION，Object Pooling R1 已将该 criticality 的 overflow 默认行为定义为返回 `OVERFLOW_DROPPED`（success 类：丢弃本次借出的新对象、记 telemetry、不动态 instantiate、不触发 ControlledGameplayFault、gameplay 不中断），并以该 safe default 在 damage-number/BattleUI GDD 完成前兜底。Config 不越权细化 drop policy（合并窗口/cap 行为/drop 优先级仍归 owner GDD 显式批准），但 Config 声明 `criticality=PRESENTATION` 即采用该默认 drop 路径，不得错述为"默认 failure → ControlledFault"。

### R5 — PoolLimits

MVP schema v1冻结：

| Limit | Value | Semantics |
|---|---:|---|
| `max_pool_keys` | 16 | 单个BattlePoolSet可声明的非零key数上限 |
| `max_capacity_per_key` | 512 | 任一key的configured capacity上限 |
| `max_total_capacity` | 1536 | checked `Σconfigured_capacity` 上限 |

- 当前六key总容量固定为`320+6+1+448+320+96=1191`，在总上限内保留345个slot给后续经GDD批准的VFX/特殊对象key。`enemy_elite` 容量 6 由 MVP 方案 5.3 两固定精英 + 8.1"冒险夺宝"持久化精英驱动（最坏 4 并发）。
- 这些值是防止损坏配置导致无界实例化的结构硬上限，不是目标Android内存达标证据。正式production仍须报告1191个实际PackedScene实例、Pool workspace与双bank的峰值内存；未取得min-spec设备证据前memory gate保持OPEN。
- 修改任一PoolLimit必须提升schema或content revision，并同时重跑Object Pooling AC-A/F、SpatialGrid压力fixture与GameRoot load/fault tests。线上或单局内热改禁止。

### R6 — SpatialGridLimits 与 per-type caps

MVP schema v1冻结：

| Field | Value | Owner/consumer semantics |
|---|---:|---|
| `max_abs_world_coord` | 1,000,000.0 world units | 任一arena边、insert/stage/query center的绝对坐标上限 |
| `min_cell_size` | 0.01 world units | arena维度与CELL_SIZE共同下限 |
| `max_grid_axis` | 4096 | rows和cols各自上限 |
| `max_grid_cells` | 262,144 | checked `rows×cols`上限 |
| `max_indexed_entries` | 1000 | Grid slot/candidate workspace硬上限 |
| `max_registered[ENEMY]` | 303 | normal+elite+Boss |
| `max_registered[PROJECTILE]` | 0 | MVP投射物只作为查询caller，不注册 |
| `max_registered[DROP]` | 300 | 地面掉落物 |
| `cell_size_spike_anchor` | 2.0 world units | 仅isolated benchmark候选，不是production值 |
| `max_midpoint_cast_error` | 0.04419417382415922 | `sqrt(2)/32`，real_t32 swept配置上界 |
| `max_target_motion_bound` | 0.0 world units/tick | MVP tick-end discrete target snapshot |

- `Σmax_registered=603≤max_indexed_entries=1000`。`max_indexed_entries`控制private slot、authoritative carrier与resume workspace；per-type cap控制insert准入与query carrier required capacity，两者都必须检查。
- `required_query_capacity(ALL)=603`；GameRoot/consumer至少预分配ENEMY 303、DROP 300、ALL 603的carrier。`SpatialRemapBuffer.capacity=2×max_indexed_entries=2000`。
- `max_query_radius`是所有enabled consumer有效宽相半径的checked derived值，不是合法查询半径cap。当前只冻结pickup 1.98、midpoint cast error和target motion语义；Skill/Enemy/Projectile GDD未提供的producer字段不得按0吞掉，见R9 readiness。
- Stage拥有arena AABB、walkable region、production CELL_SIZE与index_margin。Config schema只冻结它们的校验关系；当前`CELL_SIZE=2.0/index_margin=2.0`仍只是spike fixture，不能写成MVP地图production值。

### R7 — StageSpatialConfig 校验关系

- `StageSpatialConfig`至少包含 `{arena_size:Vector2,walkable_region_polygon:PackedVector2Array,walkable_area:float,spawn_ring_depth:float,boss_region_center:Vector2,boss_region_half:float,cell_size:float,index_margin:float}`（8字段，遵 stage-map.md R5）。`arena_min`/`arena_max` **不入 schema**，由 F1 从 `arena_size` 派生，Config 不校验独立字段、消费者按 F1 派生。所有real_t输入先验证finite，再进入checked float64 derivation。
- 必须满足：两条arena维度`≥min_cell_size`；四条arena边绝对值`≤max_abs_world_coord`；`min_cell_size≤cell_size≤max(arena_w,arena_h)`；`0<walkable_area≤arena_w×arena_h`；`walkable_area == shoelace(walkable_region_polygon)`（浮点容差内，不一致→`DERIVATION_ERROR`）；`walkable_region_polygon` schema：MVP 4 顶点、CCW 绕序、首尾不重复、非自交、外接矩形==arena AABB，位值绑定标准 real_t32 导出（遵 R1 canonical hash，double 精度构建重跑 golden）；`index_margin≥0`且checked `arena.grow(index_margin)`仍在世界坐标域。
- `cols=max(1,ceil(arena_w/cell_size))`、`rows=max(1,ceil(arena_h/cell_size))`；必须满足`cols/rows≤max_grid_axis`且checked `cols×rows≤max_grid_cells`。任何失败=`LIMIT_EXCEEDED`或`DERIVATION_ERROR`，不得调用SpatialGrid.init。
- Config只证明输入满足安全域；production CELL_SIZE仍须由SpatialGrid F3在真实arena、完整query envelope和目标设备上benchmark后写回StageConfig并提升content revision。

### R8 — Runtime immutable 与 reload policy

- BOOT可以发布不含本局run_seed的基础snapshot；每次BATTLE_LOADING必须用manifest+`RunStartRequest.run_seed`构建本局`BattleConfigSnapshot`，并把同一snapshot ID传给GameRoot、BattlePoolSet、SpatialGrid及所有owner。
- 进入BATTLE_ACTIVE后，Config API只读；Resource changed通知、remote config、dev inspector编辑或文件变化不得修改当前snapshot。请求reload只设置“next battle rebuild”标志。
- pause/resume沿用同一snapshot ID。Pool与Grid必须在init时复制该非零ID并提供无分配、只读scalar getter；owner authority bundle同样携带该ID。若owner、Grid或Pool报告的snapshot ID不同，GameRoot在开放consumer前或resume publish前进入ControlledGameplayFault；不得尝试合并两版配置。
- Config snapshot teardown不拥有pooled Node或Grid handle；GameRoot先按既定Grid→Pool顺序teardown battle，再释放snapshot引用。

### R9 — Readiness 分级与缺失依赖

- `foundation_ready`：schema、R4/R5/R6全部有效，可进行Object Pooling/SpatialGrid isolated implementation与测试。
- `battle_ready`：foundation_ready，且合法`RunStartRequest.run_seed`、StageSpatialConfig、所有enabled pool factory/reset contract、Wave/Enemy/Projectile/Drop/Skill consumer references和其玩法上限全部存在。GameRoot只允许battle_ready snapshot进入BATTLE_ACTIVE。
- `benchmark_ready`：battle_ready，且所有query producer提供完整有效宽相上界、production arena/CELL_SIZE已确定、min-spec设备与memory/performance manifest完整。只有该级别可关闭SpatialGrid production CELL_SIZE和pool memory gates。
- 本GDD完成后foundation_ready契约闭环；Stage arena、各owner reset字段、spawn/overlap enforcement、完整query envelope及真机内存仍是明确integration gates，不得用当前spike值伪装battle/benchmark ready。

## Formulas

### F1 — Per-key required capacity

`required_capacity_k = max_concurrent_borrowed_k + max_pause_replacement_overlap_k + max_spawn_before_release_overlap_k + safety_spare_k`

所有变量均为非负int并逐步checked add；输出范围`[0,max_capacity_per_key]`。R4逐行结果为`320/6/1/448/320/96`，总和1191。任一步overflow、required大于configured或configured大于per-key上限均为`LIMIT_EXCEEDED`。

### F2 — Pool structural limits

`pool_key_count = count(unique nonzero pool_key)`

`total_pool_capacity = checked_sum(configured_capacity_k)`

必须满足`pool_key_count≤16`、每key`configured_capacity≤512`、`total_pool_capacity≤1536`。示例：当前`count=6,total=1191`合法；新增一个capacity=346的key得到1537，必须在实例化前失败。

### F3 — Query carrier capacity

`required_query_capacity(filter) = Σ max_registered[type]`，仅对`filter & type != 0`的已知single-bit type求和。

MVP结果：`ENEMY=303`、`PROJECTILE=0`、`DROP=300`、`ENEMY|PROJECTILE=303`、`ENEMY|DROP=603`、`PROJECTILE|DROP=300`、`ALL=603`、空/纯未知mask=0。每步checked sum且输出`[0,603]`。

### F4 — Grid dimension derivation

`cols = max(1,ceil(arena_w/cell_size))`

`rows = max(1,ceil(arena_h/cell_size))`

`grid_cells = checked_mul(cols,rows)`

输出必须满足`1≤cols,rows≤4096`及`1≤grid_cells≤262144`。示例fixture`arena=40×40,cell_size=2`得到`20×20=400`；这只是fixture，不冻结production arena。

### F5 — Query envelope 与 readiness

`max_query_radius = checked_max(pickup_radius_max,target_range_max,checked_add(max_skill_effect_radius,max_enemy_bound),checked_add(separation_radius,max_separation_radius),checked_sum(0.5×max_projectile_segment_length,max_midpoint_cast_error,max_projectile_bound,max_enemy_bound,max_target_motion_bound),...)`

`separation_radius`是单个调用者的最大分离半径，`max_separation_radius`是候选邻居上界；MVP registry 将二者冻结为同一全局上界，因此该项等于`2×max_separation_radius`，不得退回shape bound `max_enemy_bound`。

enabled producer的每个required变量必须present、finite且非负；缺失不是0，而是令`benchmark_ready=false`。已冻结输入只有`pickup_radius_max=1.98`、`max_midpoint_cast_error=0.04419417382415922`、`max_target_motion_bound=0`；因此本GDD不宣称完整production max_query_radius。

## Edge Cases

1. **If** schema version不是1：**Then** 返回SCHEMA_VERSION_MISMATCH，0个snapshot字段发布。
2. **If** revision相同但hash不同或revision倒退：**Then** 返回REVISION_ERROR，保留旧snapshot。
3. **If** pool/type ID重复、为0或未知：**Then** 返回DUPLICATE_ID/INVALID_ARGUMENT，不按“最后一个覆盖”。
4. **If** factory/reset contract引用缺失：**Then** 返回MISSING_REFERENCE，不创建任何Node。
5. **If**任一capacity负数、checked sum overflow、required>configured或突破PoolLimits：**Then** LIMIT_EXCEEDED，不调用Pool init。
6. **If** current六key总量被误算为1190或1192：**Then** golden manifest失败；权威值固定1191。
7. **If** presentation key未获drop policy批准：**Then** criticality仍为PRESENTATION，exhaustion按 Object Pooling R1 默认返回 `OVERFLOW_DROPPED`（丢弃本次借出、记 telemetry、不 fault、gameplay 不中断）；drop policy 细节（合并窗口/cap/优先级）由 owner GDD 细化，Config 不越权批准，也不得改述为 fault 路径。
8. **If** PROJECTILE max_registered被设为400：**Then** manifest失败；400是pool/query-caller压力，不是MVP Grid注册数。
9. **If** per-type cap总和603但ALL carrier只有602：**Then** BATTLE_LOADING失败，不进入Active、不运行时扩容。
10. **If** max_indexed_entries低于603或remap carrier低于2000：**Then** LIMIT_EXCEEDED，snapshot不具battle_ready。
11. **If** arena/cell含NaN、Infinity、0、负数或网格行列/总格数超限：**Then** DERIVATION_ERROR/LIMIT_EXCEEDED，不调用Grid init。
12. **If** index_margin使grow后任一边越过±1,000,000：**Then** LIMIT_EXCEEDED，不clamp配置值。
13. **If** enabled query producer缺失上界：**Then** foundation snapshot可用于isolated test，但battle/benchmark readiness为false；不把缺失值当0。
14. **If** radius大于derived max_query_radius但API输入合法：**Then** Config不拒绝或clamp；derived值只做审计与benchmark规划。
15. **If** Resource在Active中被编辑/替换：**Then** 当前snapshot逐字段不变，只标记next battle rebuild。
16. **If** pause/resume发现snapshot ID不一致：**Then** consumer保持关闭并进入ControlledGameplayFault，不混合版本。
17. **If** snapshot ID allocator耗尽：**Then** ID_EXHAUSTED，不发布新snapshot、不复用旧ID。
18. **If** min-spec内存实测失败但结构limits仍合法：**Then** benchmark_ready保持false；必须优化scene footprint或修订容量，不得宣称production ready。

## Dependencies

### 上游/格式基础

| Dependency | Config/Data 使用方式 | 当前状态 |
|---|---|---|
| Godot 4.7.1 Resource | typed `.tres`、PackedScene/Resource引用、构建artifact | 引擎已固定；具体Resource class实现未开始 |
| Build/import pipeline | 可选CSV/JSON离线导入、canonical hash、schema migration | 未设计；不阻塞手写fixture Resource |
| StageConfig | arena、walkable area、CELL_SIZE、index_margin | `design/gdd/stage-map.md` Draft；静态几何/schema 已冻结，生产 CELL_SIZE/index_margin 收紧值 gated |
| RunStartRequest / RNG | PREP生成`run_seed`，Config逐位冻结进每局snapshot，RNG只消费snapshot副本 | GameRoot/RNG GDD已登记；runtime evidence OPEN |
| Owner configs | Wave/Enemy/Projectile/Drop/Skill上限、factory/reset contract | GDD未设计；battle/benchmark gate |

### 下游

- Object Pooling消费R3–R5，不得自行发明key或容量。
- SpatialGrid消费R6–R7及F3–F5，不得把derived max_query_radius当合法性cap。
- GameRoot只发布同一snapshot ID，按Config→carriers→Grid→Pool→owners顺序进入BATTLE_ACTIVE；失败清理按owner→Grid invalidation→Pool teardown→Grid reset→snapshot release收敛。
- Enemy/Projectile/Drop/Damage/BattleUI必须承接R4的active/overlap与factory/reset contract；若需求突破基线，先修订Config而非运行时fallback。
- SaveSystem只保存稳定content revision/业务数据，不序列化Resource实例ID或整个runtime snapshot。

### Integration gates

- 单图arena尺寸、walkable region、production CELL_SIZE/index_margin尚未冻结。
- Enemy/Projectile/Drop/Skill GDD尚未提供完整shape bounds、query radii、每tickspawn/聚合规则和reset字段。
- `max_total_capacity=1536`与当前1191 Node尚无min-spec Android内存实测；只关闭无界配置风险，不关闭memory/performance gate。

## Tuning Knobs

| Setting | Baseline | Classification | Change rule |
|---|---:|---|---|
| six `configured_capacity` values | 320/6/1/448/320/96 | LOCKED MVP baseline | content revision + Pool/Grid/GameRoot regression |
| `max_pool_keys` | 16 | HARD LIMIT | schema/ADR + memory evidence |
| `max_capacity_per_key` | 512 | HARD LIMIT | schema/ADR + memory evidence |
| `max_total_capacity` | 1536 | HARD LIMIT | schema/ADR + memory evidence |
| Spatial numeric/grid limits | R6 exact values | HARD LIMIT | SpatialGrid contract revision + golden tests |
| per-type registered caps | 303/0/300 | LOCKED MVP baseline | owner GDD + carrier/workspace resize evidence |
| Stage `cell_size/index_margin` | production TBD | Stage/performance tuning | only BATTLE_LOADING; F3 benchmark required |
| query producer maxima | partial/TBD | derived audit inputs | owning GDD supplies; missing blocks readiness |

`safety_spare`不能用来掩盖泄漏；high watermark、pool exhaustion和retirement必须单独观测。Config值可以在下一battle随content revision改变，但当前battle不可热更。

## Acceptance Criteria

### A. Schema and Atomic Snapshot

**AC-A1 canonical build与原子发布**
- Given: 字段相同但Resource数组顺序不同的两个schema v1 manifest
- When: 分别build snapshot
- Then: canonical字段/hash结果相同；每次成功只发布一个新snapshot ID；consumer看不到部分表
- 验证: deterministic Resource test | Gate: BLOCKING

**AC-A2 schema/revision/hash failure保持旧snapshot**
- Given: 已发布snapshot，随后输入wrong schema、revision倒退、same revision/different hash
- When: build
- Then: 精确status；旧snapshot identity/content不变；0个Pool/Grid init调用
- 验证: table-driven repository test | Gate: BLOCKING

**AC-A3 reference failure无部分实例化**
- Given: 首/中/末pool key的factory/reset contract或Stage reference缺失
- When: BATTLE_LOADING validate
- Then: MISSING_REFERENCE/ASSET_INVALID；0个Node创建、0个Grid workspace创建、GameRoot不开放input
- 验证: asset fault injection | Gate: BLOCKING

### B. Pool Baseline and Limits

**AC-B1 六key逐项golden**
- Given: R4 baseline manifest
- When: build snapshot
- Then: key/name/contract/criticality/四项F1输入/configured capacity逐字段等于表；required结果320/6/1/448/320/96，总量1191
- 验证: golden snapshot test | Gate: BLOCKING

**AC-B2 PoolLimits边界**
- Given: keys/per-key/total分别等于16/512/1536及各自大1，另注入checked overflow
- When: validate
- Then: 等于上限可通过其本层检查；大1/overflow=LIMIT_EXCEEDED且实例化计数0
- 验证: boundary table test | Gate: BLOCKING

**AC-B3 gameplay压力与pool key映射**
- Given: 300 normal、2 elite、1 Boss、400 projectile、300 drop及64 merged damage labels
- When: owner按stable key borrow到各steady cap并执行R4 overlap fixture
- Then: 无key串池；steady+overlap不耗尽；超过configured精确POOL_EXHAUSTED且不动态instantiate
- 验证: Config+Pool integration | Gate: BLOCKING

**AC-B4 PRESENTATION overflow 默认 drop（对齐 Object Pooling R1/EC14/AC-F5）**
- Given: `damage_number`（PRESENTATION，capacity=96）全部 BORROWED 且无 BattleUI/Damage drop-policy GDD
- When: 再请求 borrow PRESENTATION key
- Then: 返回 `OVERFLOW_DROPPED`（success 类），丢弃本次借出的新对象、记 telemetry、不动态 instantiate、不触发 ControlledGameplayFault、gameplay 不中断；drop policy 细节（合并窗口/cap/优先级）由 owner GDD 细化；GAMEPLAY pool 同条件仍 `POOL_EXHAUSTED` + fault
- 验证: 与 Object Pooling AC-F5 共享 fixture | Gate: BLOCKING（AC-F5 已在 Object Pooling 冻结；drop policy 细节归 owner GDD）

### C. Spatial Limits and Derived Carriers

**AC-C1 SpatialGridLimits逐字段golden**
- Given: R6 baseline Resource
- When: build snapshot并传给Grid init harness
- Then: 1,000,000/0.01/4096/262144/1000、type caps303/0/300、cast error和motion bound逐字段一致；任一大1或非法finite值在Grid allocation前失败
- 验证: Config+Grid boundary test | Gate: BLOCKING

**AC-C2 八种filter required capacity**
- Given: ENEMY=303/PROJECTILE=0/DROP=300及所有8种known subset含空mask
- When: 计算F3
- Then: 结果精确为303/0/300/303/603/300/603/0；ALL carrier603通过、602在BATTLE_LOADING失败
- 验证: exhaustive mask unit | Gate: BLOCKING

**AC-C3 Grid dimension checked derivation**
- Given: 合法40×40/CS2、axis=4096边界、cells=262144边界及大1/overflow/NaN/Infinity
- When: 计算F4
- Then: fixture=20×20/400；等于上限成功；非法项精确失败且不生成部分bucket
- 验证: numeric boundary unit | Gate: BLOCKING

**AC-C4 PROJECTILE不注册**
- Given: Pool有400 gameplay projectiles
- When: build spatial type limits及执行压力fixture
- Then: projectile pool capacity=448但max_registered[PROJECTILE]=0；Grid indexed目标仍仅ENEMY+DROP最多603，不混淆1003活动对象与索引数
- 验证: cross-config invariant test | Gate: BLOCKING

**AC-C5 resume carrier容量**
- Given: max_indexed_entries=1000
- When: 预分配AuthoritativeRegistrationBuffer与SpatialRemapBuffer
- Then: 容量分别1000和2000且runtime identity固定；1999在BATTLE_LOADING失败，不延后到Paused
- 验证: GameRoot+Grid allocation test | Gate: BLOCKING

### D. Readiness and Runtime Immutability

**AC-D1 缺失query producer不按0聚合**
- Given: pickup与cast常量存在，但Skill/Enemy/Projectile任一required envelope字段缺失
- When: 计算F5/readiness
- Then: foundation_ready可为true，battle/benchmark_ready为false；diagnostic指出缺失field path；不发布伪完整max_query_radius
- 验证: required-field matrix | Gate: BLOCKING

**AC-D2 Active热改只影响下一局**
- Given: battle使用snapshot S，随后编辑源Resource capacity/cell size
- When: Active、pause/resume及下一场load
- Then: 当前局所有consumer仍报告S且值不变；本局无resize/reinit；下一场仅在完整rebuild成功后使用新snapshot
- 验证: runtime mutation integration | Gate: BLOCKING

**AC-D3 snapshot ID不一致fail closed**
- Given: GameRoot/Pool/Grid中一方注入不同snapshot ID
- When: BATTLE_LOADING或resume预检
- Then: consumer保持关闭、WRONG_STATE/ControlledFault；不合并或选择“较新”版本
- 验证: three-system fault injection | Gate: BLOCKING

**AC-D4 run_seed单一来源与不可变性**
- Given: manifest相同而RunStartRequest seed分别为S1/S2，另构造缺失seed与Active期间篡改source request
- When: 分别build BATTLE snapshot并初始化RNG、pause/resume
- Then: snapshot逐位携带对应S1/S2且content_hash不因seed变化；缺失seed不达battle_ready；本局RNG/GameRoot读取值始终等于snapshot seed，source request后改不影响本局；resume不重新派生seed
- 验证: Config+GameRoot+RNG integration | Gate: BLOCKING

### E. Diagnostics and Production Gates

**AC-E1 deterministic diagnostic precedence**
- Given: 同一manifest同时含schema、duplicate key、capacity overflow和missing asset错误
- When: 重放三次
- Then: 按R2顺序始终先返回同一status/field path；修复一层后才暴露下一层
- 验证: deterministic error ladder | Gate: BLOCKING

**AC-E2 release诊断不泄漏内部对象**
- Given: 任一Config failure
- When: dev与release build分别显示/记录
- Then: dev含resource/field/value；release UI只有通用开战失败，telemetry含revision/hash/status但无Node地址、绝对本地路径或堆栈
- 验证: UI/log schema inspection | Gate: BLOCKING

**AC-E3 structural limits不冒充memory通过**
- Given: 当前1191 slots、总硬上限1536且没有min-spec内存artifact
- When: gate-check
- Then: foundation_ready可通过，但benchmark/production memory gate明确OPEN；只有记录设备、build hash、每key实例内存和peak总量后才能关闭
- 验证: manifest audit | Gate: BLOCKING before production commitment

**AC-E4 cross-document consistency**
- Given: Config、Object Pooling、SpatialGrid、GameRoot与registry
- When: consistency check提取pool keys/capacities、PoolLimits、Spatial limits/type caps
- Then: 所有重复值完全一致；不存在Object/Grid本地默认覆盖Config snapshot
- 验证: static registry/GDD consistency test | Gate: BLOCKING
