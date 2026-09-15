# Config/Data System（配置与运行时快照）

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：Steam新合同由campaign-flow.md、mission-objectives.md、save-steam-pc.md定义；须生成稳定任务/grant/目标schema、domain validator/migration、最大合法快照与字节/耗时预算、MISSION phase/capacity、ECON-MISSION-01。规划CSV不可直接作runtime配置，缺任一必需注册/预算拒绝新profile。路由manifest为design/registry/manifests/steam-save-mission-contracts-v1.json，仅规划非generated产物。

> **Status**: Re-review Pending — 已同步“感知无限、技术有限”Stage V2、稀疏Grid与Player world-domain契约；须独立full复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-09-08 — Zhangtian第七次独立full review后作者整改传播
> **Implements Pillar**: 300敌人、400投射物、300掉落物压力目标可复现、可校验且不靠运行时魔法值
> **Scope**: MVP battle foundation config；冻结 Pool/Grid、GameRoot orchestration limits、required manifests 与 outcome ABI 所需数据

## Overview

Config/Data System 把编辑期 Godot Resource 数据校验并发布为每场战斗唯一、不可变的 `BattleConfigSnapshot`。它是 `pool_key`、逐 key 对象池容量、`PoolLimits`、SpatialGrid 数值域与 per-type 注册上限的权威来源；GameRoot 只有在 snapshot 完整通过 checked validation 后，才能按同一份数据预分配 authority carriers、初始化 BattlePoolSet 和 SpatialGrid。CSV/JSON 可以作为离线导入源，但运行时只消费已生成并随构建交付的 `.tres`/Resource，不在战斗中解析文本、热更或静默采用默认值。

## Player Fantasy

玩家不会直接看到配置系统；它带来的体验是同一版本、同一 seed 的怪潮密度和性能压力可以稳定复现，进入试炼时不会因漏配池容量而少怪、因数组不足而漏命中，也不会在升级或暂停恢复时突然卡顿。非法内容必须在开战前被阻止并给出低干扰错误，而不是让玩家在十分钟后才遇到对象耗尽或范围攻击失真。

## Detailed Rules

### R1 — 权威格式、版本与单次发布

- 编辑期权威资产为 Godot 4.7.1 typed Resource（`.tres`）；CSV/JSON只允许通过离线 importer 生成Resource，不能成为release runtime的第二套权威来源。
- 根资源 `BattleConfigManifest` 固定包含：`schema_version`、非零 `content_revision:int64`、artifact `content_hash`、`PoolLimits`、定序 `PoolKeyConfig[]`、`SpatialGridLimits`、定序 `SpatialTypeLimit[]`、`RuntimeOrchestrationLimits`、**仅含作者静态基线**的`PlayerStaticConfigV1`、`ProgressionTreeConfigV1`、`HerbConfigV1`、`ZhangtianProjectionRulesV1`、`SettlementRewardManifestV1`、`SettlementRecordManifestV1`、`SettingsConfigV1`、`DropConfigV1`、`LevelingConfigV1`、`EliteBehaviorConfigV1`及其FSM/attack/schedule/presentation表、required participant/phase/service/terminal-precollection-producer manifests、实际5-row `AppServiceTopologyManifestV1`、实际1-row `AppAdapterTopologyManifestV2`、实际25-row `HashPreimageManifestV1`、实际6-row `SaveGlobalCodecHashManifestV1`、实际6-row `AccessibilityHashPreimageManifestV1`、accessibility profile/node/state/predicate manifests、Meta UI Input manifest、6208-byte native MPSC layout manifest、实际5-row `ReservationUpdatePayloadManifestV1`、实际13-row `ReservationReconcileDispositionManifestV2`、实际11-row `ReservationCrashOperationManifestV2`、实际12-row `ReservationCrashCutManifestV2`及其唯一展开132-row fixture、`GameplayCallbackAllowlist`、实际3-row `PauseDrainClosureTypeManifestV1`、实际2-row `FixedPauseClosureCapacityContributionManifestV1`、实际9-row `LoadStatusNormalizationManifestV1`、实际30-row `LoadFailureDispositionManifestV1`及point15的6条subphase fixture、实际54-row `TransitionGuardOracleManifestV1`、实际72-row `TransitionActionOutcomeV1`、实际31-row `TerminalPriorityGoldenV1`、`OwnerOrchestrationCapacityContributionManifest`、`RunOutcomeProducerManifest`、实际12-row `RuntimeWorkloadManifestV1`、实际5-row `AppRootRenderWorkloadManifestV2`、实际4-row `PlayerRuntimeWorkloadSupplementV1`、实际3-row `PlayerPresentationConsumerManifestV1`、实际24-row `PlayerPhase6FaultMatrixV1`、实际33-row `PlayerContextStateMatrixV1`、`NativeAllocationCallAllowlistV1` 与 Stage/consumer references。MVP `schema_version=1`；range notation在导出artifact中必须展开为实际row，全部进入content hash。`run_seed`、reservation/profile identity、`PlayerRunProjectionV1`与run-specific `ZhangtianBattleProjectionV1`不进入静态内容调谐hash。
- app-root扩展manifest另固定包含GameRoot签发的唯一`AppAdapterTopologyManifestV2` row、五行`AppRootRenderWorkloadManifestV2`、六行`AccessibilityHashPreimageManifestV1`、逐screen-state node manifest、八行meta UI InputMap与`LoadInjectionSubphaseV1`及point15六条subphase fixture；Save扩展另含25-row hash preimage、5-row reservation payload、13-row reservation reconcile与132-row crash-cut artifact。它们与五行业务`AppServiceTopologyManifestV1`分开hash，缺失或混表均`INVALID_MANIFEST`。
- `ConfigRepository.build_snapshot(manifest,required_readiness,run_start_request) -> ConfigStatus` 在BOOT/BATTLE_LOADING主线程执行 validate-then-build；BATTLE/BENCHMARK要求`run_start_request.{run_seed,battle_instance_id}:int64`与`{config_content_revision,config_content_hash}`均存在。成功生成新的非零、进程内单调`snapshot_id`并一次替换published snapshot；`snapshot_id`禁止进入durable carrier或跨进程相等判断。重启恢复时只按durable content key解析exact artifact，重新生成local snapshot ID并rebind；artifact缺失/hash不等在marker前保持同reservation为UPDATE_REQUIRED并关闭新局，marker后按orphan CONSUME，绝不换用latest config继续。
- 旧artifact可达性由**根artifact之外**、同release原子签发的`ConfigArtifactRetentionIndexV1={schema_version:i32=1,index_generation:i64,row_count:i32,previous_index_hash:Hash256,rows:ConfigArtifactRetentionRowV1[],index_hash:Hash256}`保证；row固定`{stable_order:i32,content_revision:i64,content_hash:Hash256,resource_uid:i64,artifact_length:i64,artifact_hash:Hash256}`。artifact先独立canonical encode并计算`artifact_hash`，index随后按revision升序引用它们；`index_hash=SHA256("ConfigArtifactRetentionIndexV1\0"||canonical index with final hash ZERO)`，因此index不进入任何被引用artifact的`content_hash/artifact_hash`，不存在自引用。publisher先durable写全部artifact并逐byte readback，再写新index temp、file barrier、atomic replace、directory barrier及readback；只有新index完整包含上一index全部rows且`previous_index_hash`逐位等于上一权威index hash才可发布。缺旧row、同revision异hash、链断裂、路径/UID重定向或任一readback失败都使release gate失败并保留旧index。每个Save schema lifetime最多32条且累计≤16 MiB；突破前必须先签发可逐byte验证的Save/config migration并证明所有unresolved reservation已可迁移。runtime只按该index定位matching旧artifact，不使用LRU或latest替代old。
- `BattleConfigSnapshot` 是本局只读值快照，至少携带 `{snapshot_id,battle_instance_id,schema_version,content_revision,content_hash,run_seed,runtime_orchestration_limits,player_config,drop_config,leveling_config,zhangtian_battle_projection,required_participants,required_service_faults,pause_drain_closure_types,fixed_pause_closure_contributions,load_status_normalization,load_failure_dispositions,transition_guard_oracle,transition_action_outcomes,terminal_priority_golden,owner_capacity_contributions,outcome_producers,runtime_workloads,native_allocation_call_allowlist,...flattened config}`。跨文档 `config_snapshot_id==snapshot_id`。run-specific projection仅由matching durable profile+reservation与静态rules构建，不反写`BattleConfigManifest.content_hash`；各canonical table携带独立hash供runner比较，不允许运行时或fixture补行。
- validator按pool/type ID排序并用固定字段/float位值序列化后重新计算canonical hash；hash输入明确排除`content_hash`自身、编辑器对象instance ID、绝对本地路径与注释，只包含schema/content revision、行为字段及稳定asset UID/contract ID，避免自引用与机器差异。重算值必须与manifest `content_hash`相等。同一`content_revision+content_hash`必须生成逐字段相同的snapshot与diagnostic；revision相同但hash不同、hash相同但revision倒退均为manifest错误。

### R2 — Public status、诊断与校验顺序

- `ConfigStatus` 固定为primitive int enum：`OK`、`INVALID_ARGUMENT`、`INVALID_MANIFEST`、`SCHEMA_VERSION_MISMATCH`、`REVISION_ERROR`、`DUPLICATE_ID`、`MISSING_REFERENCE`、`LIMIT_EXCEEDED`、`DERIVATION_ERROR`、`ASSET_INVALID`、`ID_EXHAUSTED`、`WRONG_STATE`。只有OK为success。
- 校验顺序固定为：`main-thread/state → manifest/schema/revision/hash → ID uniqueness/order → required role/service/callback/guard/capacity/outcome manifests → references/assets → scalar finite/domain → RuntimeOrchestrationLimits → Pool F1与PoolLimits → Spatial limits/type caps → Stage grid derivation → query envelope/readiness → snapshot build/publish`。组合错误返回最先失败层的唯一status。
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
| 1 | `enemy_normal` | `EnemyNormalPoolable/v1` | GAMEPLAY | 298 | 0 | 12 | 10 | 320 |
| 2 | `enemy_elite` | `EnemyElitePoolable/v1` | GAMEPLAY | 4 | 0 | 1 | 1 | 6 |
| 3 | `enemy_boss` | `EnemyBossPoolable/v1` | GAMEPLAY | 1 | 0 | 0 | 0 | 1 |
| 4 | `projectile_gameplay` | `ProjectilePoolable/v1` | GAMEPLAY | 400 | 0 | 32 | 16 | 448 |
| 5 | `drop_gameplay` | `DropPoolable/v1` | GAMEPLAY | 300 | 0 | 16 | 4 | 320 |
| 6 | `damage_number` | `DamageNumberPoolable/v1` | PRESENTATION | 64 | 0 | 16 | 16 | 96 |

- 六种普通敌人必须在本基线下共享`EnemyNormalPoolable/v1`的pool/reset contract，以config behavior ID区分；两种精英共享elite contract；Boss独立。若EnemySystem GDD证明必须拆成更多PackedScene/script contract，必须先修订本表、总容量和PoolLimits，不能在实现中私自增加key。
- ENEMY gameplay active压力锚点严格为`298 normal + 4 elite + 1 boss = 303`；两次未击杀机缘精英与6:00/10:00固定精英可同时存在。PROJECTILE为400；DROP为300。damage number的64是合并后同时可见label上限，不进入SpatialGrid。
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
| `max_abs_world_coord` | 1,000,000.0 world units | 配置可声明坐标的绝对硬上限；不是可游玩边界 |
| `world_safe_half_extent` | 16,384.0 world units | 本局有限安全域`[-H,H]²`；玩家不可见且不做wrap/rebase |
| `min_cell_size` | 0.01 world units | `cell_size`下限 |
| `max_query_cells_enumerated` | 262,144 | 单次局部格枚举上限；超过即切换全active-entry扫描 |
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
- Stage拥有world safe domain、镜头可见尺寸、生成环、退役边距、地表视觉参数与production `cell_size`。SpatialGrid必须是稀疏occupied-cell索引，内存只随已注册entry/cell增长，不能按world面积预分配。

### R7 — StageSpatialConfigV2 校验关系

- `StageSpatialConfigV2`精确包含 `{schema_version:int32=2,world_safe_half_extent:float64,max_battle_duration_seconds:float64,camera_visible_world_size:Vector2,spawn_visibility_padding:float64,spawn_ring_depth:float64,despawn_margin:float64,ground_tile_world_size:Vector2,ground_overscan:float64,cell_size:float64,max_query_cells_enumerated:int32}`，遵`stage-map.md`。V1或V1/V2混合字段必须`SCHEMA_VERSION_MISMATCH`，不得静默迁移。
- 所有real_t输入先验证finite，再进入checked float64 derivation。必须满足：`0<H≤max_abs_world_coord`、`max_battle_duration_seconds=1800`、镜头两维/生成padding/ring depth/地表tile两维/cell size为正、`despawn_margin≥0`、`ground_overscan≥0`、`min_cell_size≤cell_size`、`1≤max_query_cells_enumerated≤262144`。
- 派生矩形环：`visible_half=0.5×camera_visible_world_size`、`spawn_inner_half=visible_half+spawn_visibility_padding`、`spawn_outer_half=spawn_inner_half+spawn_ring_depth`。必须有`spawn_visibility_padding≥max_spawn_visual_bound`。Config按Stage F1计算`max_relative_runtime_extent`、`world_precision_guard`与`world_reachability_budget`并验证`budget≤H`；失败=`LIMIT_EXCEEDED`，不得靠运行时clamp修复。
- `max_abs_cell_coord=ceil(H/cell_size)`必须可由signed 64-bit cell key安全表示；不派生或分配`rows×cols`。Config只证明数值域安全；production `cell_size`仍须由SpatialGrid F3在完整query envelope和目标设备上benchmark后写回并提升content revision。

### R8 — Runtime immutable 与 reload policy

- BOOT可以发布不含本局run_seed/battle identity的基础snapshot；每次BATTLE_LOADING必须用manifest+`RunStartRequest.{run_seed,battle_instance_id}`构建本局`BattleConfigSnapshot`，并把同一snapshot ID与battle identity传给GameRoot runtime banks；Pool/Grid/owners继续以同一snapshot ID做Config一致性预检。
- 进入BATTLE_ACTIVE后，Config API只读；Resource changed通知、remote config、dev inspector编辑或文件变化不得修改当前snapshot。请求reload只设置“next battle rebuild”标志。
- pause/resume沿用同一snapshot ID。Pool与Grid必须在init时复制该非零ID并提供无分配、只读scalar getter；owner authority bundle同样携带该ID。Config只引用GameRoot canonical resume attempt schema `{battle_instance_id,config_snapshot_id,input_rebuild_revision,background_required_revision,background_acked_revision,geometry_revision,pool_binding_consumer_checkpoint,source_authority_revision,next_authority_revision,source_grid_snapshot_revision,next_grid_snapshot_revision,pool_epoch,topology_revision,resume_requested_latched}`，其中`pool_binding_consumer_checkpoint∈{CLOSED,POOL_BINDING_CONSUMER_OPEN}`且后者不开放gameplay/Viewport physical input，不得复制旧名或第二套字段。在 arm 与 `Grid→Pool→authority` 三次发布的expected tuple checkpoint分别核对；任一额外变化都保持consumer关闭并进入ControlledGameplayFault。
- Config snapshot teardown不拥有pooled Node或Grid handle；GameRoot先按既定Grid→Pool顺序teardown battle，再释放snapshot引用。

### R9 — Readiness 分级与缺失依赖

- `foundation_ready`：schema、R4/R5/R6全部有效，可进行Object Pooling/SpatialGrid isolated implementation与测试。
- `battle_ready`：foundation_ready，且合法RunStartRequest、`StageSpatialConfigV2/StageWorldDomainViewV2`、factory/reset contract、所有consumer references与玩法上限存在；required role覆盖11个role，七phase participant/service coverage非空，terminal precollection producer coverage complete，四required service exact-once；callback、5-row app service、1-row app adapter、5-row app render workload、6-row accessibility hash、3-row closure、2-row fixed closure、9-row load normalization、30-row load disposition及6条point15 subphase fixture、54-row guard oracle、72-row action outcome、31-row priority golden、25-row hash preimage、5-row reservation payload、13-row reservation reconcile、12-row global workload、4-row Player supplement、Player fault/context matrices与34-row Outcome ABI的row count/order/hash完全匹配。每个required owner对`LIFECYCLE_INTENT/FACT_COMMIT/PAUSE_CLOSURE/BLOCKING_CHOICE`各恰一行（可显式0），每个Outcome SoA field有唯一producer贡献；`outcome_kind`producer必须为GAME_ROOT。空表、缺行、重复/未知、hash或checked sum不匹配均`INVALID_MANIFEST`。当前作者表已枚举，但导出artifact、canonical Hash256 golden、BATTLE_RULES并入后的capacity/workload、`ReviveHazardSnapshotV2`总容量及runtime证据尚未实际生成，继续令`battle_ready=false`。
- `benchmark_ready`：battle_ready，且所有query producer提供完整有效宽相上界、production `cell_size`已确定、min-spec设备与memory/performance manifest完整。只有该级别可关闭SpatialGrid production `cell_size`和pool memory gates。
- 本GDD完成后foundation_ready契约闭环；SpawnDirector运行实现、各owner reset字段、完整query envelope及真机内存仍是明确integration gates，不得用当前spike值伪装battle/benchmark ready。

### R10 — RuntimeOrchestrationLimits 与 manifest 完整性

- `RuntimeOrchestrationLimits` 在 snapshot 中固定携带：`physics_ticks_per_second=60`、`engine_time_scale=1.0`、`max_pending_blocking_choices=checked_sum(required owner BLOCKING_CHOICE rows)`且`1..16`、`max_pending_reasons=3+max_pending_blocking_choices<=19`、diagnostic/lifecycle/pause/fact limits与`max_pending_save_commits=1`。RunOutcome每个SoA满足owner required capacity。所有和/乘法checked；禁止直接填写blocking choice aggregate。
- `fixed_gameplay_dt=1.0/physics_ticks_per_second`；GameRoot只把该值或`0.0`传给gameplay。Godot callback delta仅作telemetry；Engine runtime tick rate/time scale漂移是dependency fault，不成为simulation时间源。
- required manifest schema沿用GameRoot。`PauseDrainClosureTypeManifestV1`必须逐字段等于PDC01..03；fixed manifest必须等于FPCC01..02；load normalization逐字段等于LSN01..09，disposition等于LFD01..30并以LSN覆盖每个non-success class；guard oracle等于实际G00..G24共54行；action outcome等于TA01..72；priority等于TP01..31；workload逐字段等于RW01..12；app adapter topology等于唯一MOBILE_ACCESSIBILITY row，app-root render workload等于ARRW01..05；accessibility hash等于ADR-0001六个screen capacity/length/offset rows；Save hash与reconcile分别等于HPM01..25和RRD01..13。`OwnerOrchestrationCapacityContributionManifest`排序键固定且组合唯一；每个required role对四类capacity各一行，每个Outcome SoA field由唯一producer提供OUTCOME_FIELD行；`RunOutcomeProducerManifest`逐字段等于GameRoot 34-row。全部按canonical order进入hash，不接受runtime补行。
- lifecycle/fact/blocking-choice三类required下界分别等于全required role对应kind的checked sum；pause closure下界等于owner PAUSE_CLOSURE checked sum加FPCC01..02固定贡献，且不要求小于lifecycle intent数。Outcome field下界等于唯一producer required_max。`RuntimeWorkloadManifestV1`只对`STEADY_ZERO_DELTA`要求零allocator/growth/COW/native-call；cold/memory只测量。缺行、排序键冲突、负数、overflow或越界均在首个allocation/side effect前fail closed。

### R11 — PlayerConfig、PLAYER actual rows 与精确定容

`PlayerStaticConfigV1`最小schema固定为：

`{schema_version:int32=1,player_speed:float64=4.5,base_max_hp:float64=100,player_collision_diameter:float64,revive_hp_ratio:float64=0.35,revive_relocation_radius:float64,revive_outer_ring_multiplier:int32=2,revive_candidate_capacity:int32=17,enemy_threat_capacity:int32=303,revive_clear_workspace_capacity:int32=300,player_fact_capacity:int32=2,player_transient_event_capacity:int32=1,player_critical_event_capacity:int32=2,revive_hazard_capacity:int32}`。

`PlayerRunProjectionV1={schema_version:i32=1,battle_instance_id:i64,config_content_revision:i64,config_content_hash:Hash256,source_profile_revision:i64,zhangtian_reservation_id:i64,long_chun_level:i32,iron_body_pill_consumed:i32,progression_max_hp_bonus_ratio:f64,preparation_max_hp_bonus_ratio:f64,resolved_starting_max_hp:f64,projection_hash:Hash256}`是独立run-specific carrier。`projection_hash=SHA256("PlayerRunProjectionV1\0"||canonical projection with final hash ZERO)`；它绑定静态content key、profile revision与reservation identity，但绝不反写`BattleConfigManifest.content_hash`。

- `player_collision_diameter`与`revive_relocation_radius`必须finite且分别落入Player GDD冻结域；`player_speed/revive_hp_ratio/outer multiplier/candidate/threat/clear/fact/transient-event/critical-event`逐值精确等于上述常量，artifact required−1或required+1均`INVALID_MANIFEST`，不得以“至少够用”接受漂移；Player initialize对已构造snapshot再作防御性复核，失败返回PlayerStatus `INVALID_CONFIG`，两层status不得混用。
- Config在静态artifact通过后，接收matching profile/reservation签发的`long_chun_level∈{0..5}`与`iron_body_pill_consumed∈{0,1}`，构造`PlayerRunProjectionV1`：`progression_max_hp_bonus_ratio=0.03×long_chun_level`、`preparation_max_hp_bonus_ratio=iron_body_pill_consumed?0.15:0`，再按Player F3A计算`resolved_starting_max_hp=base_max_hp×(1+progression+preparation)`。所有输入/中间值/结果必须finite，结果必须在`[1,1,000,000]`；否则`INVALID_ARGUMENT`且静态manifest仍不变。三字段只进入run projection hash与本局snapshot，Active不得热改maxHP。
- `revive_hazard_capacity`必须为正整数，并逐字段等于所有hazard producer经worst-case workload证明的actual contribution checked sum。对应schema固定为`ReviveHazardSnapshotV2`：保留V1 header/identity/window并增加`shape_codes`，封闭enum至少含`CIRCLE/EXTERIOR_CIRCLE`；V1、unknown shape、缺array或parallel-array长度不等于capacity均`INVALID_MANIFEST`。当前总式为`400+EnemyNonProjectile_H+2+Stage_H`；未知项、workload或值未冻结时`battle_ready=false`，Config不得暂填402或从303/300任意推导。
- 清除不配置独立距离旋钮。MVP所有NORMAL必须声明`shape_code=CIRCLE`，且`enemy_shape_bound`逐bit等于实际玩法碰撞圆半径；Player只按`player_radius + enemy_shape_bound`判断真实重叠/相切。非圆NORMAL或额外clear-distance字段均使battle load失败。
- 标准Godot export的position/direction ABI为real_t32 `Vector2`；Config标量与计算域为float64。validator必须分别检查real_t32可表示/canonical边界与float64 finite/domain，不以float64 ULP替代runtime ABI。
- artifact manifest必须登记export template precision=`single`及Player inward-rounding bit-golden hash；double-precision模板、±0/subnormal/最大finite golden不匹配或Stage parent/canvas identity contract缺失均令Player consumer reference无效。

INPUT participant actual row必须逐字段为`{participant_id=INPUT,role_id=INPUT,stable_order=1,allowed_phases={MOVEMENT_COMMIT,POST_DEFERRED_BARRIER},allowed_success_statuses={OK},owner_contract_id=InputSystem/v1,owner_gdd_path=design/gdd/input-system.md,phase_row_id=INPUT_PHASE_ROW_V1,required=true}`。

INPUT owner contribution actual rows共同字段为`{required_role_id=INPUT,outcome_field_id_or_none=NONE,owner_contract_id=InputSystem/v1,source_gdd_path=design/gdd/input-system.md,role_stable_order=1,field_stable_order=0}`，四行分别为`{LIFECYCLE_INTENT,0,1}`、`{FACT_COMMIT,0,2}`、`{PAUSE_CLOSURE,0,3}`、`{BLOCKING_CHOICE,0,4}`。Input只声明phase participant与零业务字段贡献，不得借此拥有GameRoot顶层状态、Player fact或Choice authority。

PLAYER participant actual row必须逐字段为`{participant_id=PLAYER,role_id=PLAYER,stable_order=2,allowed_phases={MOVEMENT_COMMIT,DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=PlayerController/v1,owner_gdd_path=design/gdd/player-controller.md,phase_row_id=PLAYER_PHASE_ROW_V1,required=true}`。

PLAYER owner contribution actual rows共同字段为`required_role_id=PLAYER,outcome_field_id_or_none=NONE,owner_contract_id=PlayerController/v1,source_gdd_path=design/gdd/player-controller.md,role_stable_order=2,field_stable_order=0`，四行分别为`{LIFECYCLE_INTENT,0,kind_stable_order=1}`、`{FACT_COMMIT,2,2}`、`{PAUSE_CLOSURE,0,3}`、`{BLOCKING_CHOICE,0,4}`。Config只复制/验证actual rows，不补字段、不把Player row与Damage row合并。

### R12 — Terminal precollection、Player typed artifacts 与 workload supplement

- `TerminalPrecollectionProducerManifestV1`逐row冻结所有可对当前resolution产生`FATAL/VICTORY/PAUSE` contender的required producer，字段为`{producer_role_id,owner_contract_id,allowed_bits,stable_order,source_gdd_path}`；每个producer每token恰一条typed preview，可显式NONE。GameRoot只以这些actual rows的coverage hash接受precollection，禁止fixture补producer或phase7晚发现VICTORY。
- `StageWorldDomainViewV2`、`PlayerMotionCommitCarrierBankV1`、`PlayerDamageResolutionViewV1`、`PlayerRecoveryResolutionViewV1`、`EnemyThreatSnapshotViewV1`、`ReviveHazardSnapshotViewV2`、16-field `Phase6AuthorityBatchPlanV1/ViewV1`、`Phase6PlayerBankBindingsV1`及其七个nested binding/bank/capability、`TerminalPrecollectionViewV1`、`Phase6PlayerPreparedOutputV1`、HUD/transient/critical wrapper schema逐字段采用Player/Stage/GameRoot GDD。`PlayerPresentationFrameV1`只允许由matching motion+HUD allocation-free copy-out联结生成，不得登记第三套backing/selector。phase不适用的RefCounted payload只允许`null`；缺schema、writable backing alias、可写view、空壳对象冒充unbound、generation或teardown失效规则均为`INVALID_MANIFEST`。
- `PlayerRuntimeWorkloadSupplementV1`实际行恰为`PWM01..04`并按`workload_id`排序；PWM01/02/04的parent必须为RW01且使用相同1191-active counts，PWM03的`H`必须展开为hazard owner actual capacity。四行hash进入BattleConfig content hash与GameRoot RuntimeWorkload observer header。
- `PlayerPhase6FaultMatrixV1`必须逐字段等于Player GDD的PFM01–24，`PlayerContextStateMatrixV1`必须逐字段等于PCM01–33；row-id、stable order、checkpoint、status、tx、writer vector和completion全部进入content hash。行数非24/33、缺行、多行、未知行或hash不匹配均`INVALID_MANIFEST`。实现代码不得读取expected status/writer vector；Config只验证schema/coverage/hash，不把oracle表注入production判定路径。
- `PlayerPresentationConsumerManifestV1`实际三行固定为`PLAYER_VISUAL/BATTLE_UI/PLAYER_AUDIO`，stable order为1/2/3，`ack_word_capacity=1`且V1 `required_ack_mask=0b111`；每个consumer使用bit `1 << (stable_order-1)`。Player transient/critical event容量分别精确为1/2；consumer manifest hash、required/acked mask与event bank/ledger header必须逐字段matching。缺consumer、重复consumer、未知bit、bitset不足或Critical P0 fallback缺失均使battle load失败。

### R13 — SpawnDirector actual rows 与精确定容

- SPAWN participant row逐字段等于SpawnDirector R1：stable order 3，只允许`SPAWN_INTENT`，normal suppression status不得用于mandatory intent。
- `spawn_candidate_attempts=8`、`max_spawn_intents_per_tick=23`、`max_normal_retire_intents_per_tick=300`；23来自`max(12 Wave+9 Elite summon+1 Elite+1 Boss,12 Wave+9 Elite summon+2 Boss summon)`。Boss召虫只在43200 Boss与fixed Elite rows均已消费后的P2合法，12:00后新普通Wave row为0；这一schedule互斥必须进入hash。candidate workspace=8、单tickspawn-position RNG word上限552，required±1均`INVALID_MANIFEST`；不改变298/4/1 active cap或Pool容量。
- SPAWN四条owner contribution actual row共同字段为`required_role_id=SPAWN,owner_contract_id=SpawnDirector/v1,source_gdd_path=design/gdd/spawn-director.md,role_stable_order=3,field_stable_order=0`，四类`LIFECYCLE_INTENT/FACT_COMMIT/PAUSE_CLOSURE/BLOCKING_CHOICE` required_max均为0、kind stable order依次1..4。Normal退役的最多300条journal row归ENEMY contribution，禁止双计到SPAWN。
- `max_spawn_visual_bound`、禁生区producer/capacity与完整WaveSchedule仍缺失时`battle_ready=false`；Config不得以0或空表补齐。

### R14 — DropSystem + Leveling/XP actual rows 与精确定容

- DROP participant逐字段等于`DROP_PHASE_ROW_V1`：stable order 7，allowed phases为`SPAWN_INTENT/QUERY/QUERY_CONSUME/DEFERRED_REMOVAL`；LEVELING逐字段等于`LEVELING_PHASE_ROW_V1`：stable order 10，只允许`DEFERRED_REMOVAL`。owner contract分别为`DropSystem/v1`与`LevelingSystem/v1`，共同source为`design/gdd/drop-leveling-system.md`。
- DROP四条owner contribution actual row按kind 1..4为`300/300/300/0`；LEVELING四类均为0。SKILL_DRAFT的`BLOCKING_CHOICE` actual required max冻结为14，来源为10-row Leveling可见窗口+4-row Drop treasure窗口；Leveling其余29条升级债务留在39-row debt bank，不重复计入并发blocking choice。RISK_CHOICE四类actual row为`0/0/0/2`，故全局blocking checked sum精确为16。
- `DropConfigV1`必须逐字段冻结behavior/provenance XP表、100000 utility权重与checked sum、`PlayerHpAuthorityViewV1` eligibility revision、5400/7200/10800 gameplay-tick cooldown、3/2/1 run cap、290/3/2/1/4 subtype caps、606-row award bank、300-row materialize/pickup plan、DropPoolable reset与blast ABI版本。`LevelingConfigV1`必须冻结`T(L)=8+5L+ceil(3L²/5)`、level cap40、cumulative cap16552、39-row debt、10-row可见窗口、300-row apply dispositions与terminal policy。
- `PlayerHpAuthorityViewV1`必须逐字段等于Player/GameRoot定义且从每次full-copy后的published authority slice派生，不得绑定可能落后revision的HUD bank。BATTLE_RULES必须预分配capacity1 `CoreHerbRewardStageBankV1`并验证stable非零item ID及staging→通用REWARD ledger映射；缺row/header/join字段使`battle_ready=false`。
- Config必须验证同一death的award kind order`XP=1,UTILITY=2,TREASURE_BOX=3`、Enemy 8-field death staging schema（含`source_choice_id`）、SkillDraft普通offer n=1/2/3时RNG calls=1/3/5；缺任一schema/capability/hash不得补默认。
- 当前RW01..11的`{1,303,384,503}`与已冻结`PROJECTILE active=400`、`DROP active/Grid=300,pool=320`冲突，整张RuntimeWorkloadManifest必须连同operation vector/authority count/hash重生成；只改503或继续把1191 pool slots称为active object数均`INVALID_MANIFEST`并保持`BLOCKED-WORKLOAD-REGEN`。

### R15 — RiskChoice actual rows 与精确定容

- RISK_CHOICE participant逐字段等于`RISK_CHOICE_PHASE_ROW_V1`：stable order 9，仅允许`POST_DEFERRED_BARRIER`，success statuses为`OK/OK_NOOP`，owner/source为`RiskChoiceSystem/v1`与`design/gdd/risk-choice-system.md`。
- 四类owner contribution按kind 1..4精确为`0/0/0/2`；Outcome producer rows精确为`risk_choice_count=1 scalar slot`、`risk_choice_ids=2`、`risk_choice_results=2`，field stable order分别19/28/29。Config不得把schema hard max1536当作Risk本地容量。
- `RiskChoiceConfigV1`恰有两条event：due ticks `{14400,28800}`、两分支`SAFE/TREASURE`、恢复0.25、ward 600 ticks/0.80、risk Elite HP与base damage倍率1.30、behavior 6/7权重1/1、challenge2700 ticks、XP240、treasure eligible=true；缺行、多行、重复ID/due、非法权重/数值均`INVALID_MANIFEST`且不补默认。
- ENEMY class caps逐字段冻结为`normal=298,elite=4,boss=1,total=303`。对应Pool F1 rows为`298+0+12+10=320`与`4+0+1+1=6`；仍沿用ENEMY query capacity303，不把pool spare计作active容量。
- 两次risk treasure+两次fixed Elite treasure使每局宝匣provenance最多4，闭合Drop active/window cap4；第5个配置在battle load失败。宝匣耗尽后的奖励内容仍由SkillDraft/Drop保持`BLOCKED-TREASURE-EXHAUSTION`。

### R16 — Elite Enemies content rows 与 producer上界

- `EliteBehaviorConfigV1`恰有behavior 6/7两行并按ID排序；两行须引用完整FSM/attack/reward/presentation hash与预分配`EliteRuntimeStateV1`。所有duration使用整数gameplay ticks，禁止seconds/ticks双别名同时生效。
- fixed schedule恰为`{21600,behavior6}`与`{36000,behavior7}`；共同arrival lock=60 ticks。蜈蚣三段6-unit/18 speed、24t telegraph、6t link、300t cooldown、150t weakened；鬼修360t period、18t blink预警、30t魂针预警、24t后摇、三针、三召唤。balance值按Elite GDD的PROVISIONAL标记进入revision/hash，不能省略。
- Elite不是新participant/owner contribution。Elite hostile Projectile上界为9；Boss为8。global pending仍须加入Weapon与behavior2/4 Normal远程并证明`<=32`。Elite summon最多9 child，Boss P2最多2 child，按R13 schedule互斥共同保持23-row/552-word上界。
- Enemy death staging schema升级为8字段并含`source_choice_id`；Risk行必须为matching非零ID，fixed/summon为0。缺Elite表、presentation P0 fallback、Projectile/Damage/hazard总量或完整WaveSchedule仍令`battle_ready=false`。

### R17 — BossStateMachine content、shape ABI 与 producer上界

- `BossBehaviorConfigV1`恰有behavior8一行；`BossScheduleV1`恰含`{due_tick=43200,class=BOSS,count=1}`，到点guard必须是`survival_ticks==43200 && boss_spawned==0`并在同一commit置位，禁止用`>=43200`在恢复/重复tick补发第二只。120-tick arrival lock只限制Boss动作，不限制玩家攻击或死亡判定，因此不阻断43200 tick后达成VICTORY。Boss为ENEMY stable-order4内部typed capability，不新增participant或owner contribution；缺capability时不得以基础追踪Boss进入production。
- Boss profile须逐字段冻结120t arrival、P1 312t最短纯动作轮转、50% crossing与90t PHASE_SHIFT、P2 444t最短纯动作轮转、bite/fan/ring/fog/summon attack row及presentation hash；TRACK门外时间另计。所有时长只用Active gameplay ticks；base stats/伤害倍率保留PROVISIONAL-BALANCE标记但仍进入revision/hash。
- Boss projectile pending/active contribution均为8；Elite为9，另需加入Weapon与behavior2/4 Normal projectile上界并验证总pending<=32、active<=400。缺任一producer枚举时`battle_ready=false`。
- Boss direct damage单tick上界2，non-projectile revive hazard上界2，Boss summon为0/2 behavior0 cluster且BOSS_SUMMON奖励全0。`BossSummonClusterIntentV1`与12:00后schedule互斥证明必须逐字段验证；否则不能继续沿用23/552。
- `ReviveHazardSnapshotV2`在V1 header/window基础上新增`shape_codes`，封闭enum至少含`CIRCLE/EXTERIOR_CIRCLE`。Player/Damage/Config schema版本、copy-out和hash必须一致；V1、unknown shape或以大圆冒充外圆毒域均`INVALID_MANIFEST`。总hazard公式为`400+EnemyNonProjectile_H+2+Stage_H`，后两项未冻结前`revive_hazard_capacity`继续BLOCKED，不得暂填402。
- 扇形毒液要求typed cone area shape；Damage仅支持circle的旧artifact必须load失败。BATTLE_RULES的Boss lethal projection→VICTORY preview→Boss DEATH→核心灵药REWARD phase row、owner contribution与预留顺序现由Settlement作者GDD冻结；Config仍须生成actual rows/hash，本文Boss配置不得替它补默认。

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

### F4 — Sparse cell-domain derivation

`max_abs_cell_coord = ceil(world_safe_half_extent / cell_size)`

输出必须是signed 64-bit安全整数；cell key由signed `(cx,cy)`稳定编码。运行时只保存occupied cells且`occupied_cell_count≤max_indexed_entries`，禁止按`(2×max_abs_cell_coord+1)²`分配dense grid。局部query预计枚举cell数超过`max_query_cells_enumerated`时扫描最多1000个active entries，仍按相同过滤、排序与容量契约输出。

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
11. **If** Stage V2任一real_t含NaN/Infinity，`H/cell_size`无效或cell key不能安全表示：**Then** DERIVATION_ERROR/LIMIT_EXCEEDED，不调用Grid init。
12. **If** 1800秒可达包络加生成环、退役边距与最大bound越过world safe domain：**Then** LIMIT_EXCEEDED，不缩短生成环或clamp运行时位置。
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
| StageConfig | V2 world domain、镜头/生成环、地表参数、`cell_size` | `design/gdd/stage-map.md` In Review/Re-review Pending；生产 `cell_size`仍由性能证据gated |
| RunStartRequest / RNG | PREP冻结`RunStartRequestV2`；Loading preflight后RNG另冻结`ZhangtianSeedCandidateV1`，不得回写request | GameRoot/RNG/Zhangtian GDD已登记；runtime evidence OPEN |
| Owner configs | Wave/Enemy/Projectile/Drop/Skill/Player/RiskChoice上限、factory/reset contract、participant phase rows、outcome producer rows | Input/Player/Spawn/Enemy/Projectile/Damage/Drop/SkillDraft/RiskChoice/Leveling owner contract已冻结；BattleRules、hazard producer与其余证据缺失继续阻塞 battle_ready |

### 下游

- Object Pooling消费R3–R5，不得自行发明key或容量。
- SpatialGrid消费R6–R7及F3–F5，不得把derived max_query_radius当合法性cap。
- GameRoot只发布同一process-local snapshot ID，按唯一DAG执行`Config最小schema→BOOT unbound backing→PREP命令/release run-seed candidate→Save+Zhangtian同槽分配battle/reservation/preparation identities、domain after-image、360-byte recovery与唯一nested journal checkpoint1→以durable config content revision+hash构造本进程完整snapshot+run projection→Outcome backing READY→RNG logical draw→SEED_CANDIDATE_DURABLE injection point+checkpoint5→Stage→Input→Grid→Pool→owners→deterministic replay/durable pre-active choice或skip/checkpoint6→ActiveEntryFact/checkpoint7 durable→activation`；跨进程snapshot ID可变化但content key必须逐位相等。失败cleanup由lifecycle pump按staged destination、pause-off、frame barrier、expose、top-state commit、最终激活/held gate release收敛，不释放persistent root Window。
- Enemy/Projectile/Drop/Damage/BattleUI必须承接R4的active/overlap与factory/reset contract；BattleUI作者GDD现已冻结damage label同时可见64、pool96及`OVERFLOW_DROPPED`语义，但Damage presentation bank/merge/ACK仍BLOCKED。若需求突破基线，先修订Config而非运行时fallback。

**BattleUI static propagation（2026-09-03）**：Config snapshot后续必须登记`BattleUiFrameBundleV1` source-binding manifest、scene/topology identity、1 Boss+4 Elite方向identity cap5、foreground card cap4、pending count max16、damage label visible64/pool96，以及从`SupportedTouchEventOrderingManifest.max_concurrent_touches`派生的choice touch bank。最后一项当前为BLOCKED且禁止填默认。BattleUI不成为phase participant，四类gameplay contribution均为0；各producer HUD view、choice priority、text/glyph/native-allocation allowlist和P0 fallback未完整签发前`battle_ready=false`。

**Audio Feedback static propagation（2026-09-03）**：Audio不成为phase participant，四类gameplay contribution均为0；继续使用`PLAYER_AUDIO stable_order=3, ack_bit=0b100`。Config后续必须登记`AudioFrameBundleV1` source-binding、`BattleAudioEventBankV1`、`AudioPriorityManifestV1`、`AudioCueProfileV1`、bus/effect/asset/import/fallback/duck/voice manifests及native-allocation allowlist。关键保留voice结构值为6；总voice node 22是`PROVISIONAL-AUDIO-CAPACITY`，不得作为event bank容量。`H_audio`只能由各producer同一sealed capture最大audio rows的checked sum生成；当前rows/包含关系未签全，禁止用22/303/400/606代填，继续令`battle_ready=false`。

**SaveSystem static propagation（2026-09-07）**：Config必须登记`PersistentDomainManifestV1`、每domain codec/schema/version/max-bytes、连续migration step、canonical `SHA256_V1` hash mode与实际25-row `HashPreimageManifestV1`、5-row `ReservationUpdatePayloadManifestV1`、13-row `ReservationReconcileDispositionManifestV2`、golden vectors、两槽介质版本与总slot byte checked sum。Save固定2个正式完整槽、同目录temp、单writer、pending outcome/reservation各最多1；success前要求同generation同bytes双镜像。receipt使用120-byte `ReservationReceiptV1`且ID逐位等于durable request ID；resolved archive 64 rows为`PROVISIONAL-PRODUCT`。容量常量固定`ReservationMax=1152,LatestResolutionMax=264,DiagnosticsMax=2024,SlotPayloadMax=42244,SlotEncodedMax=42456,SlotMax=65536,FileSystemSafetyMargin=65536,DiskPeakMin=262144`；`SlotPayloadMax`必须逐项列出SaveStorePayload全部top-level字段与8个optional presence tag，任一generated owner checked sum或实际编码超限在写前失败。这些值不允许由Resource实例或运行时Dictionary推导。四个domain payload作者上限为176/132/136/60 bytes，对应已知DomainRecord总和728 bytes；actual codec/migration/golden与generated checked-sum仍保持`BLOCKED-PERSISTENT-DOMAIN-CODEC/CAPACITY-EVIDENCE`。

**Progression Tree static propagation（2026-09-03）**：`ProgressionTreeConfigV1`必须有3个stable branch、每支5个actual cost/effect rows，`PROVISIONAL-ECONOMY-V1`成本为4/8/12/16/20。`ProgressionBattleProjectionV1`从同一durable profile/domain revision构建：青元attack ratio `0.03Q`、长春maxHP ratio `0.03L`、大衍crit points `0.01D`与pickup ratio `0.02D`、L5 perk分别pierce1/longchun charge1/extra refresh1；Active不热改。Progression domain payload max176 bytes并进入PersistentDomainManifest。SkillDraft初始refresh必须从固定2升级为`2或3`，单session最大page/call从3/15升级为4/20。青元hit workload、长春recovery ABI、BattleRules残页reward row与5400tick/cap8经济仍BLOCKED，缺任一actual row令battle_ready=false。

**Zhangtian/Settlement/Home/Prep static propagation（2026-09-07）**：静态`HerbConfigV1={seed_kind_count=3,seed_held_cap=999,defeat_seed_eligible_ticks=43200,victory_min_ticks=43200,max_active_ticks=108000,victory_seed_quantity=3,starter_seed_grant_per_kind=1,seed_weights=[1,1,1],recipe_rows[3],config_hash}`与`ZhangtianProjectionRulesV1`固定三seed→三pill一对一、cost1及`PROVISIONAL-ECONOMY-V6`。只承诺Victory random gross grant-rate严格高于eligible Defeat；net flow必须另覆盖服丹/NONE、胜率、局长与饱和，不得把gross证明称为净库存优势。flag合法矩阵只有`unlocked/claimed=0/0或1/1`，locked ledger全零；normal settlement先consume reservation，再以post-consume held room与`INT64_MAX-earned` lifetime room饱和发奖，held/lifetime room tie固定`PARTIAL_BOTH`。Outcome seed只冻结random gross；starter、cap disposition与唯一applied truth进入64-byte `AppliedRewardRowV1`。run-specific projection、scratch RNG lease、176-byte create request、唯一terminal V3 payload、config artifact retention、semantic node/input manifests按各owner GDD；导出artifact/Hash256 golden与runtime evidence尚未生成，完成前`BLOCKED-MANIFEST-REGEN`且`battle_ready=false`。
- SaveSystem只保存稳定content revision/业务数据，不序列化Resource实例ID或整个runtime snapshot。

### Integration gates

- production `cell_size`与稀疏cell容器实现尚未由min-spec性能证据冻结。
- SpawnDirector虽已有V1静态契约，尚无runtime实现、固定RNG消费与视野外生成证据。
- Enemy/Projectile/Drop/Skill GDD尚未提供完整shape bounds、query radii、每tickspawn/聚合规则和reset字段。
- Revive hazard唯一producer、next-tick active语义、shape bounds与`revive_hazard_capacity`尚未冻结，Player复活production路径保持BLOCKED。
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
| Stage `cell_size` | production TBD | Stage/performance tuning | only BATTLE_LOADING; F3 benchmark required |
| query producer maxima | partial/TBD | derived audit inputs | owning GDD supplies; missing blocks readiness |
| `physics_ticks_per_second` | 60 | LOCKED MVP baseline | schema/content revision + deterministic replay |
| `engine_time_scale` | 1.0 | LOCKED ENGINE GLOBAL | GameRoot唯一writer + pre-tick/resume readback |
| Player exact capacities | candidate/threat/clear/fact=`17/303/300/2` | LOCKED ABI | required±1均拒绝；修改需Player/GameRoot/Config ABI revision |
| `revive_hazard_capacity` | 未冻结 | OWNER-DERIVED BLOCKER | hazard workload + exact A/B bank evidence；禁止默认值 |
| `max_pending_reasons` | `3+max_pending_blocking_choices` | DERIVED HARD LIMIT | checked build；Input/GameRoot consistency |
| `max_pending_blocking_choices` | 四类贡献中`BLOCKING_CHOICE` required rows checked sum，1..16 | OWNER-DERIVED + SCHEMA MAX | 禁止手填aggregate；缺owner row则battle_ready=false |
| `max_suppressed_diagnostics` | 1..16 | SCHEMA HARD LIMIT | preallocated bank + saturating counter evidence |
| `max_lifecycle_intents_per_tick` | owner required..1536 | OWNER-DERIVED + SCHEMA MAX | Pool/owner manifest + batch authority AC |
| `max_pause_drain_closures` | `checked_sum(owner PAUSE_CLOSURE)+2`，范围1..1538 | OWNER-DERIVED + FIXED CONTRIBUTION + SCHEMA MAX | PDC01..03 + FPCC01..02 + provenance AC |
| `max_fact_commits_per_tick` | owner required..24576 | OWNER-DERIVED + SCHEMA MAX | producer manifest + fact ledger AC |
| Outcome SoA capacities | owner required..1536/field | OWNER-DERIVED + SCHEMA MAX | V1 ABI + aggregate allocation preflight |
| `max_pending_save_commits` | 1 | LOCKED APP LIMIT | Save/GameRoot ABI revision |

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
- Given: 298 normal、4 elite、1 Boss、400 projectile、300 drop及64 merged damage labels
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
- Given: GameRoot/Pool/Grid/owner 中一方注入不同 snapshot ID，或在 resume capture、arm、Grid publish、Pool publish、authority publish 任一 checkpoint 篡改 config identity
- When: BATTLE_LOADING或resume预检/提交
- Then: consumer保持关闭、WRONG_STATE/ControlledFault；已完成的 journal/publish 事实按 GameRoot authority plan 收敛，不合并或选择“较新”版本，不开放一帧旧 consumer
- 验证: checkpoint-complete fault injection | Gate: BLOCKING

**AC-D4 run identity单一来源与不可变性**
- Given: manifest相同而RunStartRequest分别为`{battle_instance_id=B1,run_seed=S1}`/`{B2,S2}`，并覆盖`run_seed={0,INT64_MIN,INT64_MAX}`；另构造缺失/零battle identity与Active期间篡改source request
- When: 分别build BATTLE snapshot并初始化RNG、pause/resume
- Then: snapshot逐位携带对应B/S且content_hash不因两者变化；run_seed=0及完整int64域均合法，只有缺失/零battle_instance_id不达battle_ready；`config_snapshot_id==snapshot_id`且不存在第二ID；本局RNG读取run_seed、GameRoot bank header读取battle identity均与snapshot相等，source request后改不影响本局；resume不重新派生
- 验证: Config+GameRoot+RNG integration | Gate: BLOCKING

**AC-D5 orchestration limits、逐phase coverage与有限容量**
- Given: 合法完整表，以及空/缺/重复的participant/service/coverage/callback、PDC 3行、LFD 30行、guard 54行、action 72行、priority 31行、workload 12行、app-root render workload 5行、Save hash 25行、accessibility hash 6行、reservation reconcile 13行、owner contribution或Outcome 34行；任一required owner四类贡献或SoA producer贡献缺失/负数/overflow、outcome_kind producer非GAME_ROOT、hash不匹配，以及各capacity边界fixture
- When: build battle snapshot
- Then: 只有required owner四类逐kind exact-once覆盖、Outcome SoA逐field唯一producer、blocking choices aggregate恰为checked sum、全部实际oracle/workload/Outcome表逐行等于GameRoot且hash一致时生成battle-ready snapshot；其余在创建Stage/Pool/Grid Node前确定失败；全局及逐phase`all(empty)`不得成功
- 验证: exhaustive manifest matrix + boundary unit | Gate: BLOCKING

**AC-D6 exact artifact retention**
- Given: previous `ConfigArtifactRetentionIndexV1`含1/31/32 rows、累计长度恰小于/等于16 MiB，以及新release缺旧row、同revision异hash、artifact先后写失败、index temp/file barrier/replace/directory barrier/readback失败、链hash错误、UID重定向、第33条或超16 MiB
- When: publisher按artifact-first/index-last协议签发，并在带unresolved checkpoint1..6 reservation的升级恢复中读取旧content key
- Then: 只有所有artifact先durable且新index append-only包含全部旧rows、`previous_index_hash`matching、row≤32/bytes≤16 MiB时才原子发布；index不进入artifact hash，恢复逐位加载matching旧artifact并生成新local snapshot ID。任一失败保留上一权威index且release gate失败；突破上限前必须有独立migration golden与reservation迁移证据
- 验证: previous→next chained-index matrix + artifact/index cut-point fixture + upgrade recovery fixture | Gate: BLOCKING

**AC-D7 app-root/accessibility/save扩展manifest**
- Given: 8-row Meta UI Input、7 profile/动态choice node contract/34 state accessibility actual rows、6208-byte MPSC layout、25 HPM、5 RUP、13 RRD、11 RCO与12 RCC V2唯一展开132-row crash fixture的合法/缺/重/乱序/范围未展开版本
- When: build manifest
- Then: 只接受全部actual rows、stable order与owner/hash匹配的artifact；range notation、漏node/variant、MPSC slot/publication字段、RCO operation expected field、pre-V3 create/result mailbox、pre-V3 RESOLVE、cancel action或未定义NO_GRANT均`INVALID_MANIFEST`
- 验证: generated manifest/golden diff | Gate: BLOCKING

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
