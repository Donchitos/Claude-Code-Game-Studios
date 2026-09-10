# GameRoot & Scene Flow（全局根与场景流）

> **Status**: Re-review Pending — 已同步“感知无限、技术有限”Stage V2、Camera follow、SpawnDirector与稀疏Grid边界；待独立full复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-09-10 — 同步InputSystem clean-context full review remediation与BATTLE_ACTIVE pause accessibility gateway；设备工具探测仍阻断真机/可访问性/thermal evidence，不代表下一轮独立full re-review、runtime、performance、Save integration或evidence gate已通过
> **Implements Pillar**: 战斗—暂停选择—结算—再开局的可靠闭环
> **Scope**: MVP minimum；冻结中央编排、状态、身份与跨系统后置条件，不定义各玩法系统内部规则
> **Review Mode**: full；InputSystem 内部 FSM 以 `input-system.md` 为唯一权威

## Overview

第八轮并发/容量覆盖：native MPSC ingress 使用 64-byte header、64 个 96-byte row（其中 68-byte `AccessibilityNativeActionPayloadV1`），总计 6208 bytes；serial ingress 负责补齐 76-byte `AccessibilityActionCommandV2` 并写入 32-row/2476-byte SPSC。shutdown 在 producer retire 后以有界批次交替 drain 两队列，直到均为空才换代。

GameRoot 是应用生命周期内唯一、持续存在的场景流控制器与 gameplay physics phase 编排者。从 `BOOT` 到应用退出恰有一个 GameRoot；HOME、PREP、Battle、Fault 与 Settlement 页面/场景是其可替换 child scope。按 [ADR-GR-001](../../docs/architecture/adr-0002-game-root-persistent-scene.md)，GameRoot 采用 main-scene persistent root，不采用 Autoload；不得按页面或每局重建第二个 GameRoot。

GameRoot 负责合法顶层转换、SceneTree pause authority、固定 participant 调度、本局 authority/resolution bank、加载/清理 DAG，以及 SpatialGrid、Object Pooling、InputSystem、RNG、Stage 与持久化边界协调。它编排但不分配durable battle identity；`battle_instance_id`由Save持久allocator在reservation transaction内唯一产生。它不计算伤害、不生成敌人、不选择技能，也不复制依赖系统的内部 FSM。

## InputSystem remediation sync — 2026-09-10

`MOVEMENT_COMMIT`的Input采样与carrier commit只能由GameRoot调度，生产路径不得由slice harness或PlayerController直接调用`Input.get_vector`。GameRoot必须维持`SceneTree.paused`、`physics_ticks_per_second=60`、`Engine.time_scale=1.0`与`gui_disable_input`的唯一owner边界；BATTLE_ACTIVE的无障碍暂停gateway只生成typed pause command，不是新的phase participant，也不直接写SceneTree/Window。

`BattleActivePauseCommandV1`的唯一owner是persistent GameRoot：它只接受当前`BATTLE_ACTIVE`、enabled node `7001`、matching screen/layout generations与first-unseen `command_id`，并把一次且仅一次的命令转为`PAUSE_REQUESTED(reason=MANUAL)`。Presenter、bridge与adapter只能验证/投递该typed command，不能直接调用pause或写SceneTree/Window；stale、duplicate、disabled及非7001命令均为0 effect。

## Player Fantasy

玩家应感觉进入试炼、暂停选择、恢复和结算都干净、即时、可信。暂停请求在安全 barrier 进入 `PAUSE_PENDING` 并显示输入已锁定后，不再产生新的 gameplay effect；此前已经合法提交的事实不会被伪造回滚。技术故障不会伪装成战败，也不会在保存成功前谎报奖励已经到账。

## Detailed Rules

### R1 — Lifetime、单一 owner 与公开边界

- GameRoot 自 `BOOT` 至应用退出保持同一 live identity。battle-scoped carriers、banks、services、participants、Stage/BattleUI/input child 每局创建并在 Ending/Fault cleanup 完整逻辑 detach；persistent root Window 不随 battle 销毁。逻辑 detach 的可测后置条件固定为：撤销项目 writer 权、断开 gameplay callback/signal、`remove_child()` 后 `is_inside_tree()==false`，再允许 `queue_free()`；HOME/SETTLEMENT 不得持有旧 Node、lease、bank 或 borrow 引用，物理释放只在 frame-end deletion barrier 后宣告完成。
- `AppServiceTopologyManifestV1`固定五个跨页面服务行，schema为`{service_id,stable_order,process_owner=APP_ROOT,thread_model,allowed_top_states,battle_object_policy,app_object_policy,shutdown_order}`。实际canonical rows如下；`ALL`指本文封闭TopState全集，集合按TopState enum升序编码：

| service_id | stable_order | thread_model | allowed_top_states | battle_object_policy | app_object_policy | shutdown_order |
|---|---:|---|---|---|---|---:|
| `SAVE` | 1 | `MAIN_TO_SINGLE_WORKER_TYPED_SPSC_V2` | `ALL` | `FORBIDDEN` | `FORBIDDEN` | 5 |
| `PROGRESSION` | 2 | `MAIN_COMMAND_PROJECTION` | `BOOT,HOME,PREP,BATTLE_LOADING,BATTLE_ENDING,SETTLEMENT,CONTROLLED_FAULT` | `FORBIDDEN` | `FORBIDDEN` | 4 |
| `ZHANGTIAN` | 3 | `MAIN_COMMAND_PROJECTION` | `BOOT,HOME,PREP,BATTLE_LOADING,BATTLE_ENDING,SETTLEMENT,CONTROLLED_FAULT` | `FORBIDDEN` | `FORBIDDEN` | 3 |
| `SETTLEMENT_PROFILE` | 4 | `MAIN_COMMAND_PROJECTION` | `BOOT,HOME,BATTLE_ENDING,SETTLEMENT,CONTROLLED_FAULT` | `FORBIDDEN` | `FORBIDDEN` | 2 |
| `AUDIO_APP` | 5 | `MAIN_PRESENTATION` | `ALL` | `FORBIDDEN` | `PREBUILT_AUDIOSTREAMPLAYER_ONLY` | 1 |

  五者不加入七phase participant表且不随battle child创建/销毁。只有SAVE可拥有durable worker；AUDIO_APP可持有由persistent app root预建并登记的app-scope `AudioStreamPlayer`，但禁止battle Node/RID/Callable或可变battle bank引用；其余四行禁止持有任何Node/RID/Callable。BOOT按stable order构造一次，退出按shutdown order 1→5关闭；缺/重/别名、行值不等或battle teardown后仍持有battle引用均阻断下一局。
- 原生平台桥不伪装成第六个业务service；独立`AppAdapterTopologyManifestV2`固定一行`{adapter_id=MOBILE_ACCESSIBILITY,stable_order=1,process_owner=APP_ROOT,os_callback_thread=NATIVE_ANY,native_ingress=MPSC64_FIXED,spsc_producer_thread=PLATFORM_SERIAL_INGRESS,main_ingress=NATIVE_TO_MAIN_SPSC,queue_capacity=32,pump_top_states=ALL,snapshot_action_top_states={HOME,PREP,PRE_ACTIVE_CHOICE,BATTLE_ACTIVE,BATTLE_PAUSED,SETTLEMENT,CONTROLLED_FAULT},object_policy=PLATFORM_ADAPTER_ONLY,shutdown_order=1}`。bridge只持有平台adapter、64-row fixed MPSC ingress与32-row primitive action SPSC，不持有battle Node/RID/Callable/业务bank。MPSC逐字段ABI以ADR的64-byte header+64×96-byte row=6208 bytes为唯一合同：producer只有slot sequence匹配后CAS推进enqueue才取得arrival ticket，full不推进、不留ticket hole；publish/consume/retire按release/acquire和per-slot sequence，shutdown先accepting=0并等待producer-in-flight=0。唯一serial ingress按ticket ASC drain，并在此处而非OS线程分配`native_event_sequence`，再复制canonical command入SPSC；主线程是唯一consumer。SPSC mailbox用i64单调read/write sequence，固定2476 bytes；full差值32、empty差值0，release/acquire发布。主线程所有TopState每render frame在service result之后恰drain一次；无active snapshot的state只拒绝并计数stale/duplicate，绝不积压至下一页面。页面detach依次停止native接纳→等待producer retire→drain/retire MPSC→drain/retire SPSC→换adapter generation并失效旧行，退出同序后才关闭AUDIO_APP与其余service。缺row、错误线程/容量、任一overflow或adapter shutdown后回调均阻断交互。
- GameRoot 精确使用 `PROCESS_MODE_ALWAYS`。每次`_process(delta)`先在所有TopState中调用一次无gameplay effect的`app_service_result_pump`，排空Save SPSC与其他app-scope结果并执行唯一matching reducer；随后在所有TopState中恰调用一次`app_adapter_action_pump`。后者只在`HOME/PREP/PRE_ACTIVE_CHOICE/BATTLE_ACTIVE/BATTLE_PAUSED/SETTLEMENT/CONTROLLED_FAULT`存在matching active semantic snapshot时转成已有typed UI command，其余state只drain并拒绝stale/disabled action。BATTLE_ACTIVE snapshot仅含pause gateway，不含gameplay HUD。两者同render frame第二次调用均禁止。之后才按互斥state branch选择至多一个state pump：`SceneTree.paused==true && state in {PRE_ACTIVE_CHOICE,BATTLE_PAUSED,RESUME_PREPARING}`驱动control pump；`state in {BATTLE_LOADING,BATTLE_ENDING,CONTROLLED_FAULT}`驱动lifecycle pump；HOME/PREP/SETTLEMENT/BOOT只完成app-scope结果/动作推进，不运行control/lifecycle。`_physics_process(delta)`仅在`SceneTree.paused==false && state in {BATTLE_ACTIVE,PAUSE_PENDING}`进入：`BATTLE_ACTIVE`执行普通七phase；`PAUSE_PENDING`只允许恰一次`gameplay_dt=0` allowlist drain。`PRE_ACTIVE_CHOICE`只处理ordinal1 offer/refresh/commit，不推进gameplay authority或survival tick；同一callback最多命中一个state pump，但app-scope pump不属于该互斥组。
- Save result reducer只接受`SaveExecutorResultRowV3`内完整canonical typed payload，禁止从共享状态补字段。fresh-live完整profile commit success必须来自matching 160-byte `TerminalRunResultV2`或generic profile result，随后才构造124-byte `SaveDurableStampFactV1`交给AUDIO_APP；reservation建立声音只使用matching 204-byte `ReservationCreateResultV3`，release声音只使用`TerminalRunResultV2.terminal_disposition=RELEASED`，CONSUMED明确0返还声。create reducer必须逐位验证source kind/command/press/request hash与operation identity；两种receipt均按120-byte schema验证且ID=request ID，receipt内durable code固定SUCCEEDED而public delivery code可为SUCCEEDED/RECONCILE_FOUND。中间update的0/ZERO32 receipt不发声。RECONCILE_FOUND、boot scan、duplicate callback、UI rebuild与裸domain edge只更新presentation，不生成fresh stamp。任何result kind、payload length、enum、presence、hash或correlation不匹配时声音事件0并锁存diagnostic，不能用“保存成功”布尔值替代typed fact。
- participant 使用 PAUSABLE mode，且不得定义自主 gameplay `_physics_process/_process/_input/_unhandled_input`。PAUSABLE 不等于 signal 或 lifecycle callback 自动冻结：所有项目 signal slot、`_notification`、tree/lifecycle callback 必须属于 load 时冻结的 `GameplayCallbackAllowlist`。每行固定 `{callback_id,source_id,target_participant_id,callback_kind,engine_notification_id,allowed_top_states,writable_latch_ids,consumer_phase,diagnostic_only}`；pause/unpause notification 默认不得写任何权威 gameplay latch。allowlist 只允许写预分配的 control-completion/invalidation/diagnostic latch；HP、position、timer、authority、reward、spawn、remove 及恢复后可生成这些效果的 intent 均禁止。未登记、越权写入或绕过 `run_phase` 是 contract failure。
- MVP 不创建逐局 SubViewport。应用唯一 persistent root `Window` 同时是 `battle_render_viewport` 与 `battle_gui_input_viewport`；GameRoot 是该 root Window `gui_disable_input` 的唯一项目 writer，正确 setter 为 `set_disable_input(bool)`。每局销毁的是 Stage/BattleUI/input child，不是 root Window。pause writer 只能通过 GameRoot 私有 helper 调用 `SceneTree.set_pause(bool)` 并 readback。
- participant 在 BATTLE_LOADING 按稳定 `RequiredParticipantManifest` 注册，Active 后不可增删或重排。每行冻结 `{participant_id,role_id,stable_order,allowed_phases,allowed_success_statuses,owner_contract_id,owner_gdd_path,phase_row_id,required}`；公开调用为 `run_phase(phase,context,lease_id)->int status`。MVP required role 集为 `INPUT/PLAYER/SPAWN/ENEMY/PROJECTILE/DAMAGE/DROP/SKILL_DRAFT/RISK_CHOICE/LEVELING/BATTLE_RULES`；每个 required row 的 `allowed_phases` 与 `allowed_success_statuses` 都必须非空，且 Config 冻结的 `RequiredPhaseCoverageManifest` 对七个 phase 逐项声明非空 required role set。owner GDD 未冻结 phase 行时该 role/phase 保持 BLOCKED，`battle_ready=false`。当前11个role的作者GDD行均已冻结；BATTLE_RULES采用Settlement GDD的`stable_order=11,allowed_phases={DEFERRED_REMOVAL,POST_DEFERRED_BARRIER}`。INPUT actual row固定为`{participant_id=INPUT,role_id=INPUT,stable_order=1,allowed_phases={MOVEMENT_COMMIT,POST_DEFERRED_BARRIER},allowed_success_statuses={OK},owner_contract_id=InputSystem/v1,owner_gdd_path=design/gdd/input-system.md,phase_row_id=INPUT_PHASE_ROW_V1,required=true}`；PLAYER actual row固定为`{participant_id=PLAYER,role_id=PLAYER,stable_order=2,allowed_phases={MOVEMENT_COMMIT,DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=PlayerController/v1,owner_gdd_path=design/gdd/player-controller.md,phase_row_id=PLAYER_PHASE_ROW_V1,required=true}`；SPAWN/DROP/LEVELING/SKILL_DRAFT/RISK_CHOICE及BATTLE_RULES逐字段采用各owner phase row。
- `RequiredServiceFaultManifest` 在load级精确固定 `RNG/INPUT_ASYNC/SPATIAL_GRID/POOL` 四个required manifest row各一次，每行 `{service_id,stable_order,phase_scope,has_fault_api,diagnostic_api,fault_status_enum,diagnostic_schema_id,required}`；`RequiredPhaseCoverageManifest` 再冻结每 phase 要调用的非空 service subset，该phase仅对subset每行exactly-once且必须满足`phase in phase_scope`，不解释为每phase调用全部四service。缺失、替代、重复、unknown、顺序/phase 不符均在 consumer 开放前返回 `INVALID_MANIFEST`。optional subset 可以为空；required participant/service 的全局与逐 phase 集均不得为空，F1 的空集恒真不构成 admission 证据。
- Config冻结 `OwnerOrchestrationCapacityContributionManifest`，封闭kind为`LIFECYCLE_INTENT/FACT_COMMIT/PAUSE_CLOSURE/BLOCKING_CHOICE/OUTCOME_FIELD`，每行 `{required_role_id,capacity_kind,outcome_field_id_or_none,required_max:int64,owner_contract_id,source_gdd_path,role_stable_order,kind_stable_order,field_stable_order}`。canonical全局排序键固定为`{role_stable_order ASC,kind_stable_order ASC,field_stable_order ASC}`，三字段组合必须唯一；owner文件内从1开始的局部序号不得直接充当全局stable order。每个required role对前四类各恰一行（无贡献也显式0），每个Outcome SoA field只允许其R8 canonical producer恰一行；前四类required下界分别为全required role checked sum，Outcome每field下界取唯一producer row。`MAX_PENDING_BLOCKING_CHOICES`精确等于`BLOCKING_CHOICE` checked sum且仍须落在schema域`1..16`，禁止Config直接填写aggregate。缺role/field、重复、unknown、负值、owner contract不匹配、排序键冲突或sum overflow均令`battle_ready=false`。当前未完成owner GDD的贡献行保持缺失并继续阻塞battle_ready，不以0代填。
- PLAYER四条actual contribution固定为`(LIFECYCLE_INTENT,0,kind_order=1)`、`(FACT_COMMIT,2,2)`、`(PAUSE_CLOSURE,0,3)`、`(BLOCKING_CHOICE,0,4)`；四行共同字段为`required_role_id=PLAYER,outcome_field_id_or_none=NONE,owner_contract_id=PlayerController/v1,source_gdd_path=design/gdd/player-controller.md,role_stable_order=2,field_stable_order=0`。Config必须逐字段复制，不得只复制四个数值。
- DROP四条actual contribution固定为`(LIFECYCLE_INTENT,300,kind_order=1)`、`(FACT_COMMIT,300,2)`、`(PAUSE_CLOSURE,300,3)`、`(BLOCKING_CHOICE,0,4)`，共同字段采用`required_role_id=DROP,owner_contract_id=DropSystem/v1,source_gdd_path=design/gdd/drop-leveling-system.md,role_stable_order=7`。LEVELING四类均为0且`role_stable_order=10,owner_contract_id=LevelingSystem/v1`。SKILL_DRAFT `BLOCKING_CHOICE` actual contribution冻结为14（10个Leveling可见窗口+4个Treasure窗口）；RISK_CHOICE四类为`0/0/0/2`且stable order=9，故全局blocking checked sum精确为16。
- GameRoot 独占 SpatialGrid `begin_phase/end_phase`，lease 不得跨同步调用栈缓存。Input callback ABI、gesture/shield bank、三字段 tuple、geometry rebuild 与内部状态迁移只由 `input-system.md` 定义。
- root Window size、safe-area、orientation 到 `INPUT_GEOMETRY_CHANGED` revision 的采集与 canonicalization 归 InputSystem。GameRoot 禁止注册或镜像 geometry event source，只消费 typed revision。
- battle input target 入树前，唯一 GameRoot 在 BOOT 完成 Input accumulated disable/readback、ProjectSettings agile readback、`Engine.physics_ticks_per_second==60` 与 `Engine.time_scale==1.0` readback，以及一次历史 buffer flush；除 GameRoot 启动配置外项目 writer 数必须为0。每个 battle preflight、Active tick 与 resume 激活尾段均只读复核这两个 Engine 全局值；漂移返回 `DEPENDENCY_FAILURE`，consumer保持关闭，不以 callback delta 调整 gameplay 时间。

### R2 — 顶层状态、合法边与 scene assembly

第八轮合同优先级覆盖：reservation 恢复当前只读 `DurableReservationV2`（1152 bytes）及其 64-byte create correlation；旧 V1/1088-byte 表述、84-row crash fixture 与六行 Meta UI 仅属历史审计，不得进入实现输入。当前 fixture 为 RCO V2 11行 × RCC V2 12行 = 132 行，Meta UI 为八行。

| State | 玩家可见页面 | SceneTree pause predicate | 权威行为 |
|---|---|---:|---|
| `BOOT` | 启动遮罩 | false | 最小配置/存档与唯一 Input bootstrap |
| `HOME` | 洞府 | false | 局外入口；不得引用 battle scope |
| `PREP` | 开局准备/预留恢复 | false | 接收唯一 `PrepConfirmCommandV1`，完成持久预留与 handoff |
| `BATTLE_LOADING` | 加载遮罩 | false | 构建 typed battle assembly，consumer/input closed |
| `PRE_ACTIVE_CHOICE` | 首次升级三选一 | true | 只运行预开局 control pump；不得推进移动、存活或战斗 tick |
| `BATTLE_ACTIVE` | 战斗页 | false | 执行完整七 phase tick |
| `PAUSE_PENDING` | 战斗画面+输入锁定反馈 | false | 最多一个零 gameplay-dt drain tick |
| `BATTLE_PAUSED` | 原因对应暂停/选择层 | true | gameplay frozen；control pump 可运行 |
| `RESUME_PREPARING` | 保持暂停层 | true；仅 gated ACTIVE 尾段允许暂时 false | prepare→arm→publish→held-drain→activation |
| `BATTLE_ENDING` | 输入锁定 | false | 安全 teardown，发布 normal/abandoned outcome |
| `SETTLEMENT` | 结算页 | false | 消费 immutable outcome facts 与 Save receipt |
| `CONTROLLED_FAULT` | 技术故障层 | battle child cleanup 中 true；无battle child或移除后 false | 停止新效果；有battle identity时保存fault前事实，支持retry/safe exit |

`CONTROLLED_FAULT`的唯一presentation owner是persistent GameRoot，不是battle-scoped BattleUI。root持有预分配`FaultPresentationBundleV1={schema_version:i32=1,fault_scope:i32,diagnostic_id:i64,profile_present:i32,profile_revision:i64,source_present:i32,source_bundle_hash:Hash256,retry_allowed:i32,safe_exit_allowed:i32,export_diagnostic_allowed:i32,status_localization_key_id:i32,action_generation:i64,bundle_hash:Hash256}`。BOOT/首次启动/坏档前允许`profile_present=0,profile_revision=0`；此时非零revision非法。没有可验证source carrier时`source_present=0,source_bundle_hash=ZERO32`，不得伪造profile或battle hash。root fault presenter从该bundle发布capacity12 snapshot，实际最大6行：标题、状态、诊断摘要、retry、safe exit、export diagnostic；每个action是否存在完全由三个allowed bits决定。action只转成`FaultRetryCommandV1/FaultSafeExitCommandV1/FaultExportDiagnosticCommandV1`并匹配diagnostic/action generation；BattleUI detach或从未创建都不影响该surface。bundle/semantic row manifest、BOOT/Save-corrupt/rebuild与no-profile fixtures缺失时不得开放fault交互。

公开 primitive enum 为封闭 ABI，不允许实现私自追加或别名映射：

- `TopState={BOOT,HOME,PREP,BATTLE_LOADING,PRE_ACTIVE_CHOICE,BATTLE_ACTIVE,PAUSE_PENDING,BATTLE_PAUSED,RESUME_PREPARING,BATTLE_ENDING,SETTLEMENT,CONTROLLED_FAULT}`；
- `FaultScope={NONE,PRE_BATTLE,BATTLE}`；`ResumeSubstate={NONE,RESUME_HELD_DRAIN}`；
- `OutcomeReadiness={UNAVAILABLE_PRE_CARRIER,READY}`；`OutcomeBindingState={UNBOUND,BOUND,IDENTITY_UNAVAILABLE}`；`FaultCompletionExposure={NOT_EXPOSED,EXPOSED}`；`ExposureRequirement={NOT_APPLICABLE,OUTCOME,PREOUTCOME}`；
- `PreOutcomeCleanupState={PENDING=1,CLEANUP_SUCCEEDED=2,CLEANUP_FAULTED=3}`；`PreOutcomeReservationState={NONE=0,RESERVED=1,RELEASE_PENDING=2,RELEASED=3,CONSUME_PENDING=4,CONSUMED=5,UNCERTAIN=6,HANDOFF_PENDING=7,ACTIVE_MARK_PENDING=8,ACTIVE_RESERVED=9,CANDIDATE_PENDING=10,PRE_ACTIVE_CHOICE_PENDING=11}`；`CleanupSubstate={NONE,PRE_ACQUIRE,GATE_RETRY_WAIT,ACQUIRE_FAILED_SAFE,DETACHING,DESTINATION_STAGED,FRAME_BARRIER_WAIT,EXPOSURE_COMMIT,DESTINATION_ACTIVE,SAFE_TERMINAL,DONE}`；`DestinationUIState={NONE,STAGED_NONINTERACTIVE,ACTIVE,SAFE_TERMINAL_NONINTERACTIVE}`；
- `LoadInjectionPoint:int32={CONFIG_BUILD=1,OUTCOME_BACKING_INIT=2,OUTCOME_READY_VALIDATE=3,RNG_INIT=4,STAGE_ASSEMBLY=5,INPUT_INIT=6,GRID_INIT=7,POOL_INIT=8,OWNER_WARMUP=9,MANIFEST_VALIDATE=10,IDENTITY_PREFLIGHT=11,ROOT_GATE_ACQUIRE=12,PRE_ACTIVE_CHOICE=13,ACTIVE_ENTRY_DURABLE=14,SEED_CANDIDATE_DURABLE=15}`；`LoadInjectionSubphaseV1={NONE=0,CANONICAL_ENCODE=1,WORKER_WRITE=2,DURABLE_READBACK=3}`。point15 fixture必须分别使用subphase1/2/3；其他point只允许NONE。unknown组合在执行前`INVALID_MANIFEST`，不得追加实现私有值。
- `TopEvent={BOOTSTRAP_SUCCEEDED,BOOTSTRAP_FAILED,RETRY_BOOTSTRAP,SAFE_EXIT_HOME,START_RUN,CANCEL_PREP,CONFIRM_RUN,PREP_RESERVATION_DURABLE,PREP_RESERVATION_FAILED,PREP_RESERVATION_UNCERTAIN,PRE_ACTIVE_CHOICE_REQUIRED,PRE_ACTIVE_CHOICE_COMMITTED,PRE_BATTLE_FAILURE_LATCHED,LOAD_SUCCEEDED,LOAD_ABORT_RETRYABLE,LOAD_FAILED_UNCERTAIN,PAUSE_REQUESTED,PAUSE_DRAIN_SUCCEEDED,RESUME_REQUESTED,RESUME_PREP_ABORTED,RESUME_POST_PUBLISH_HELD,RESUME_ACTIVATED,RESUME_POST_PUBLISH_FAILED,BATTLE_END_LATCHED,FATAL_FAILURE_LATCHED,OUTCOME_CLEANUP_FINISHED,RETURN_HOME,RETRY_RUN,RETRY_SAVE_COMMIT,RECONCILE_SAVE_COMMIT,DISCARD_PENDING_COMMIT,RETRY_DISCARD_TOMBSTONE,RETRY_PREOUTCOME_RESERVATION,RECONCILE_PREOUTCOME_RESERVATION}`；
- `GameRootStatus={OK,OK_NOOP,WRONG_STATE,INVALID_ARGUMENT,INVALID_MANIFEST,CAPACITY_EXCEEDED,LIMIT_EXCEEDED,ID_EXHAUSTED,DEPENDENCY_FAILURE}`。

`TransitionGuardId:int32` 是封闭 ABI：`{ALWAYS=0,ARCHIVE_ENTRY_READY=1,LOAD_RETRYABLE_DISPOSITION=2,GRID_PAUSE_OK=3,GRID_PAUSE_PENDING=4,CAN_START_RESUME=5,RESUME_PRE_PUBLISH_ABORTABLE=6,RESUME_POST_PUBLISH_HELD=7,RESUME_ACTIVATION_CLEAN=8,RESUME_POST_PUBLISH_FAULT=9,NORMAL_TERMINAL_UNSEALED=10,NORMAL_TERMINAL_SEALED=11,CLEANUP_FINISHED=12,SAVE_RETRYABLE=13,SAVE_RECONCILABLE=14,SAVE_DISCARDABLE=15,DISCARD_PENDING_RETRYABLE=16,FAULT_SAFE_EXIT_READY=17,LOAD_READY=18,PREOUTCOME_RESERVATION_RECOVERABLE=19,CARRIERS_RETIRED=20,PREP_COMMIT_READY=21,PREP_RESERVATION_HANDOFF_READY=22,PRE_ACTIVE_CHOICE_READY=23,ACTIVE_ENTRY_DURABLE=24}`。每个 guard 由独立纯查询返回 bool；`GRID_PAUSE_OK` 与 `GRID_PAUSE_PENDING` 是两个互斥 discriminator，不得压成同一个 bool 含义。

新增 guard 谓词固定：`PREP_COMMIT_READY`要求命令 identity、profile/config revision、静态 recipe revision 与本地 draft 全部 matching，且无未解决 mutation/reservation；`PREP_RESERVATION_HANDOFF_READY`仅在 `PrepCommitJournal=RESERVATION_DURABLE`、完整 `RunStartRecoveryV1` readback matching、reservation=`HANDOFF_PENDING|RESERVED` 且无 in-flight 时为真；`PRE_ACTIVE_CHOICE_READY`要求普通第1次升级选择已 durable commit；`ACTIVE_ENTRY_DURABLE`要求既有`LOAD_READY=true`、matching `ActiveEntryFactV1` 已持久化且 reservation=`ACTIVE_RESERVED`。pre-active base offer尚未durable时不发布页面或玩家动作；其clear failure只由load disposition oracle触发系统级release，不进入公开transition guard ABI。

guard谓词域固定：`ARCHIVE_ENTRY_READY`只接受(a)不存在任何battle/pre-outcome/outcome/completion/save carrier且无未完成ArchiveRetireJournal，或(b)Save已`SAVE_SUCCEEDED/DISCARDED`且可创建/继续同一archive operation；unresolved Save 或 reservation 恒false。`CARRIERS_RETIRED`只在journal=`CARRIERS_RETIRED|COMPLETED`、retired bitset等于expected mask且所有旧carrier/identity均物理不存在时true；二者不得互相替代。`LOAD_RETRYABLE_DISPOSITION`精确等于R2 canonical disposition；`LOAD_READY`要求全部load checkpoint成功、root gate held、Input/GameRoot activation journal到达可提交点且consumer仍关闭。`PREOUTCOME_RESERVATION_RECOVERABLE`只接受reservation state=`RELEASE_PENDING|UNCERTAIN`、无in-flight且PreOutcome fault已经可见。`CAN_START_RESUME`精确等于F4；四个RESUME guard分别对应点前可abort、点后held、clean activation与点后fault；`CLEANUP_FINISHED`要求(a)`outcome_readiness=READY && outcome_binding_state=BOUND`时`RunCompletionStatus in {CLEANUP_SUCCEEDED,CLEANUP_FAULTED}`，或(b)`outcome_readiness=READY && outcome_binding_state=IDENTITY_UNAVAILABLE`或`outcome_readiness=UNAVAILABLE_PRE_CARRIER`时`PreOutcomeFaultCompletionV1.cleanup_state in {CLEANUP_SUCCEEDED,CLEANUP_FAULTED}`且逻辑Outcome/Completion/Save carrier均不存在，并且`cleanup_substate=EXPOSURE_COMMIT`、destination UI=`STAGED_NONINTERACTIVE`、pause-off、frame barrier已完成、`fault_completion_exposure=NOT_EXPOSED`；该guard不要求转换动作尚未产生的ACTIVE/DONE。`FAULT_SAFE_EXIT_READY`接受(a)正常激活完成、`cleanup_substate=DONE`且required exposure已满足，或(b)三次gate reacquire均失败后进入`SAFE_TERMINAL`、UI=`SAFE_TERMINAL_NONINTERACTIVE`、input target=0、pause=false；两者都要求cleanup逻辑完成。其余Save guard沿R9 total reducer定义。谓词不得读取或修改UI文案作为真相源。

合法转换键固定为 `TransitionKey={top_state,resume_substate,fault_scope,top_event,guard_id,guard_result}`。`TransitionGuardOracleManifestV1` 为独立权威，行schema为 `{row_id,stable_order,guard_id,input_values,expected_bool,mutual_exclusion_group_id}`；canonical hash覆盖以下54行的UTF-8规范化字节，fixture只能引用`row_id`，不得运行时补字段或从转换表反推真值：

| row_id | order | guard | input_values（该guard允许读取的完整字段集） | expected | mutex |
|---|---:|---|---|---:|---|
| `G00_T` | 0 | `ALWAYS` | `{}` | true | 0 |
| `G01_T` | 1 | `ARCHIVE_ENTRY_READY` | `{unresolved=0,carrier=NONE,journal=NONE}` | true | 0 |
| `G01_F` | 2 | `ARCHIVE_ENTRY_READY` | `{unresolved=1,carrier=SAVE_UNCERTAIN,journal=NONE}` | false | 0 |
| `G02_T` | 3 | `LOAD_RETRYABLE_DISPOSITION` | `{disposition=LFD01}` | true | 0 |
| `G02_F` | 4 | `LOAD_RETRYABLE_DISPOSITION` | `{disposition=LFD13}` | false | 0 |
| `G03_T` | 5 | `GRID_PAUSE_OK` | `{grid=OK}` | true | 1 |
| `G03_F` | 6 | `GRID_PAUSE_OK` | `{grid=PENDING_WORK}` | false | 1 |
| `G04_T` | 7 | `GRID_PAUSE_PENDING` | `{grid=PENDING_WORK}` | true | 1 |
| `G04_F` | 8 | `GRID_PAUSE_PENDING` | `{grid=OK}` | false | 1 |
| `G05_T` | 9 | `CAN_START_RESUME` | `{resume_latched=1,choices=COMPLETE,manual=CONFIRMED,background=ACKED,geometry=CLEAN,input=CLEAN,held=0,service_fault=0}` | true | 0 |
| `G05_F` | 10 | `CAN_START_RESUME` | `{resume_latched=1,choices=COMPLETE,manual=CONFIRMED,background=ACKED,geometry=CLEAN,input=CLEAN,held=1,service_fault=0}` | false | 0 |
| `G06_T` | 11 | `RESUME_PRE_PUBLISH_ABORTABLE` | `{publish_count=0,rollback_ready=1}` | true | 2 |
| `G06_F` | 12 | `RESUME_PRE_PUBLISH_ABORTABLE` | `{publish_count=1,rollback_ready=1}` | false | 2 |
| `G07_T` | 13 | `RESUME_POST_PUBLISH_HELD` | `{publish_count=3,held=1,fault=0}` | true | 3 |
| `G07_F` | 14 | `RESUME_POST_PUBLISH_HELD` | `{publish_count=3,held=0,fault=0}` | false | 3 |
| `G08_T` | 15 | `RESUME_ACTIVATION_CLEAN` | `{publish_count=3,held=0,fault=0,activation_clean=1}` | true | 3 |
| `G08_F` | 16 | `RESUME_ACTIVATION_CLEAN` | `{publish_count=3,held=0,fault=1,activation_clean=0}` | false | 3 |
| `G09_T` | 17 | `RESUME_POST_PUBLISH_FAULT` | `{publish_count=1,fault=1}` | true | 2 |
| `G09_F` | 18 | `RESUME_POST_PUBLISH_FAULT` | `{publish_count=0,fault=1}` | false | 2 |
| `G10_T` | 19 | `NORMAL_TERMINAL_UNSEALED` | `{normal_terminal_sealed=0}` | true | 4 |
| `G10_F` | 20 | `NORMAL_TERMINAL_UNSEALED` | `{normal_terminal_sealed=1}` | false | 4 |
| `G11_T` | 21 | `NORMAL_TERMINAL_SEALED` | `{normal_terminal_sealed=1}` | true | 4 |
| `G11_F` | 22 | `NORMAL_TERMINAL_SEALED` | `{normal_terminal_sealed=0}` | false | 4 |
| `G12_T` | 23 | `CLEANUP_FINISHED` | `{readiness=READY,binding=BOUND,completion=CLEANUP_SUCCEEDED,cleanup_substate=EXPOSURE_COMMIT,destination_ui=STAGED_NONINTERACTIVE,pause=0,frame_barrier_done=1,exposure=NOT_EXPOSED}` | true | 0 |
| `G12_F` | 24 | `CLEANUP_FINISHED` | `{readiness=READY,binding=BOUND,completion=CLEANUP_SUCCEEDED,cleanup_substate=FRAME_BARRIER_WAIT,destination_ui=STAGED_NONINTERACTIVE,pause=0,frame_barrier_done=0,exposure=NOT_EXPOSED}` | false | 0 |
| `G13_T` | 25 | `SAVE_RETRYABLE` | `{save=SAVE_FAILED,in_flight=0,visible=1}` | true | 0 |
| `G13_F` | 26 | `SAVE_RETRYABLE` | `{save=SAVE_FAILED,in_flight=1,visible=1}` | false | 0 |
| `G14_T` | 27 | `SAVE_RECONCILABLE` | `{save=SAVE_UNCERTAIN,in_flight=0,visible=1}` | true | 0 |
| `G14_F` | 28 | `SAVE_RECONCILABLE` | `{save=SAVE_PENDING,in_flight=1,visible=1}` | false | 0 |
| `G15_T` | 29 | `SAVE_DISCARDABLE` | `{save=SAVE_UNCERTAIN,visible=1}` | true | 0 |
| `G15_F` | 30 | `SAVE_DISCARDABLE` | `{save=SAVE_SUCCEEDED,visible=1}` | false | 0 |
| `G16_T` | 31 | `DISCARD_PENDING_RETRYABLE` | `{save=DISCARD_PENDING,in_flight=0,visible=1}` | true | 0 |
| `G16_F` | 32 | `DISCARD_PENDING_RETRYABLE` | `{save=DISCARD_PENDING,in_flight=1,visible=1}` | false | 0 |
| `G17_T` | 33 | `FAULT_SAFE_EXIT_READY` | `{cleanup_substate=DONE,destination_ui=ACTIVE,pause=0,exposure=EXPOSED,unresolved_carrier_allowed=1}` | true | 0 |
| `G17_F` | 34 | `FAULT_SAFE_EXIT_READY` | `{cleanup_substate=DONE,destination_ui=ACTIVE,pause=0,exposure=NOT_EXPOSED,unresolved_carrier_allowed=1}` | false | 0 |
| `G01_R` | 35 | `ARCHIVE_ENTRY_READY` | `{unresolved=0,carrier=SAVE_SUCCEEDED,journal=NONE}` | true | 0 |
| `G12_P` | 36 | `CLEANUP_FINISHED` | `{readiness=UNAVAILABLE_PRE_CARRIER,binding=UNBOUND,preoutcome_cleanup=CLEANUP_FAULTED,logical_terminal_carriers=0,cleanup_substate=EXPOSURE_COMMIT,destination_ui=STAGED_NONINTERACTIVE,pause=0,frame_barrier_done=1,exposure=NOT_EXPOSED}` | true | 0 |
| `G12_I` | 37 | `CLEANUP_FINISHED` | `{readiness=READY,binding=IDENTITY_UNAVAILABLE,preoutcome_cleanup=CLEANUP_SUCCEEDED,logical_terminal_carriers=0,cleanup_substate=EXPOSURE_COMMIT,destination_ui=STAGED_NONINTERACTIVE,pause=0,frame_barrier_done=1,exposure=NOT_EXPOSED}` | true | 0 |
| `G12_X` | 38 | `CLEANUP_FINISHED` | `{readiness=UNAVAILABLE_PRE_CARRIER,binding=UNBOUND,preoutcome_cleanup=PENDING,logical_terminal_carriers=0,cleanup_substate=EXPOSURE_COMMIT,destination_ui=STAGED_NONINTERACTIVE,pause=0,frame_barrier_done=1,exposure=NOT_EXPOSED}` | false | 0 |
| `G17_S` | 39 | `FAULT_SAFE_EXIT_READY` | `{cleanup_substate=SAFE_TERMINAL,destination_ui=SAFE_TERMINAL_NONINTERACTIVE,pause=0,input_target=0,exposure_requirement=NOT_APPLICABLE}` | true | 0 |
| `G18_T` | 40 | `LOAD_READY` | `{load_checkpoints=ALL_OK,activation_checkpoint=READY_TO_COMMIT,gate=HELD,consumer_open=0}` | true | 0 |
| `G18_F` | 41 | `LOAD_READY` | `{load_checkpoints=ALL_OK,activation_checkpoint=INPUT_ACTIVE_COMMITTED,gate=LOST,consumer_open=0}` | false | 0 |
| `G19_T` | 42 | `PREOUTCOME_RESERVATION_RECOVERABLE` | `{reservation=UNCERTAIN,in_flight=0,preoutcome_visible=1}` | true | 0 |
| `G19_F` | 43 | `PREOUTCOME_RESERVATION_RECOVERABLE` | `{reservation=UNCERTAIN,in_flight=1,preoutcome_visible=1}` | false | 0 |
| `G20_T` | 44 | `CARRIERS_RETIRED` | `{journal=CARRIERS_RETIRED,retired_bits=EXPECTED,remaining_carriers=0}` | true | 0 |
| `G20_F` | 45 | `CARRIERS_RETIRED` | `{journal=ARCHIVE_COMMITTED,retired_bits=PARTIAL,remaining_carriers=1}` | false | 0 |
| `G21_T` | 46 | `PREP_COMMIT_READY` | `{command=MATCHING,draft=VALID,revisions=MATCHING,unresolved=0}` | true | 0 |
| `G21_F` | 47 | `PREP_COMMIT_READY` | `{command=MATCHING,draft=VALID,revisions=STALE,unresolved=0}` | false | 0 |
| `G22_T` | 48 | `PREP_RESERVATION_HANDOFF_READY` | `{journal=RESERVATION_DURABLE,recovery=MATCHING,reservation=HANDOFF_PENDING,in_flight=0}` | true | 0 |
| `G22_F` | 49 | `PREP_RESERVATION_HANDOFF_READY` | `{journal=ABSENT,recovery=MISSING,reservation=UNCERTAIN,in_flight=0}` | false | 0 |
| `G23_T` | 50 | `PRE_ACTIVE_CHOICE_READY` | `{choice_kind=ORDINARY_LEVEL_UP,ordinal=1,commit=DURABLE}` | true | 0 |
| `G23_F` | 51 | `PRE_ACTIVE_CHOICE_READY` | `{choice_kind=ORDINARY_LEVEL_UP,ordinal=1,commit=PENDING}` | false | 0 |
| `G24_T` | 52 | `ACTIVE_ENTRY_DURABLE` | `{load_ready=1,active_entry=MATCHING_DURABLE,reservation=ACTIVE_RESERVED}` | true | 0 |
| `G24_F` | 53 | `ACTIVE_ENTRY_DURABLE` | `{load_ready=1,active_entry=MISSING,reservation=ACTIVE_MARK_PENDING}` | false | 0 |

转换实现必须从当前权威prestate计算guard，公开入口不得接受调用方传入`guard_result`。下表每行显式冻结完整source/target tuple、唯一status且合法行的guard result恒为true；guard=false、guard id不匹配或未列完整key一律返回`WRONG_STATE`且零副作用。

`ResourceIdentityManifest` 固定为 `{game_root_instance_id,battle_instance_id,config_snapshot_id,stage_root_instance_id,stage_camera_instance_id,root_window_instance_id,published_authority_bank_id,authority_revision,published_resolution_token,grid_snapshot_revision,pool_epoch,input_epoch,topology_revision,viewport_gate_owned,scene_tree_paused,normal_terminal_sealed,outcome_readiness,outcome_binding_state,fault_completion_exposure,outcome_commit_id,cleanup_substate,destination_ui_state,save_state,save_attempt_generation,save_request_id,reservation_id,reservation_state,preparation_id,prep_commit_checkpoint,active_entry_generation}`。非法边必须逐字段不变。

合法边以本表为唯一枚举权威；`Source/Target` tuple固定写作`{top,substate,scope}`，无wildcard：

| Source tuple | Event | Guard / result | Target tuple | Status | Required action / failure edge |
|---|---|---|---|---|---|
| `{BOOT,NONE,NONE}` | `BOOTSTRAP_SUCCEEDED` | `ALWAYS/true` | `{HOME,NONE,NONE}` | `OK` | 发布最小局外依赖 |
| `{BOOT,NONE,NONE}` | `BOOTSTRAP_FAILED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,PRE_BATTLE}` | `OK` | pause=false |
| `{CONTROLLED_FAULT,NONE,PRE_BATTLE}` | `RETRY_BOOTSTRAP` | `ALWAYS/true` | `{BOOT,NONE,NONE}` | `OK` | 清pre-battle diagnostic；battle identity仍为0 |
| `{CONTROLLED_FAULT,NONE,PRE_BATTLE}` | `SAFE_EXIT_HOME` | `ALWAYS/true` | `{HOME,NONE,NONE}` | `OK` | 无outcome/commit/reward文案 |
| `{HOME,NONE,NONE}` | `START_RUN` | `ARCHIVE_ENTRY_READY/true` | `{PREP,NONE,NONE}` | `OK` | 无carrier直接进入；resolved carrier按journal archive→retire并以`CARRIERS_RETIRED=true`完成动作 |
| `{PREP,NONE,NONE}` | `CANCEL_PREP` | `ALWAYS/true` | `{HOME,NONE,NONE}` | `OK` | draft request失效 |
| `{PREP,NONE,NONE}` | `CONFIRM_RUN` | `PREP_COMMIT_READY/true` | `{PREP,NONE,NONE}` | `OK` | 接收唯一 `PrepConfirmCommandV1`；HOME/SETTLEMENT direct NONE各自验证原页面generation后由同一press进入noninteractive PREP且不渲染页面；Save/Zhangtian同槽分配battle/reservation/preparation identities，写360-byte recovery与唯一nested journal checkpoint1 |
| `{PREP,NONE,NONE}` | `PREP_RESERVATION_DURABLE` | `PREP_RESERVATION_HANDOFF_READY/true` | `{BATTLE_LOADING,NONE,NONE}` | `OK` | 从durable recovery冻结`RunStartRequestV2`并继续同一handoff；不得重新分配identity或重复扣减 |
| `{PREP,NONE,NONE}` | `PREP_RESERVATION_FAILED` | `ALWAYS/true` | `{PREP,NONE,NONE}` | `OK` | PONR前清理candidate；PONR后仅按sealed技术补偿路径release |
| `{PREP,NONE,NONE}` | `PREP_RESERVATION_UNCERTAIN` | `ALWAYS/true` | `{PREP,NONE,NONE}` | `OK` | 保留同一correlation与恢复CTA，关闭再次确认和新局入口 |
| `{PREP,NONE,NONE}` | `PRE_BATTLE_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,PRE_BATTLE}` | `OK` | battle identity/outcome/reservation均为0；pause=false |
| `{BATTLE_LOADING,NONE,NONE}` | `PRE_ACTIVE_CHOICE_REQUIRED` | `ALWAYS/true` | `{PRE_ACTIVE_CHOICE,NONE,NONE}` | `OK` | 仅聚气丹路径；创建普通level-up ordinal=1三选一，base page不消耗刷新 |
| `{PRE_ACTIVE_CHOICE,NONE,NONE}` | `PRE_ACTIVE_CHOICE_COMMITTED` | `PRE_ACTIVE_CHOICE_READY/true` | `{BATTLE_LOADING,NONE,NONE}` | `OK` | 持久选择结果，唯一helper pause-off/readback后恢复Loading；玩家主动刷新才消耗刷新次数 |
| `{PRE_ACTIVE_CHOICE,NONE,NONE}` | `LOAD_ABORT_RETRYABLE` | `LOAD_RETRYABLE_DISPOSITION/true` | `{PREP,NONE,NONE}` | `OK` | consumer保持关闭，durable RELEASE后pause-off/readback并返回fresh Prep |
| `{PRE_ACTIVE_CHOICE,NONE,NONE}` | `LOAD_FAILED_UNCERTAIN` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 保留同一reservation/recovery identity，按pre-active技术故障收敛 |
| `{BATTLE_LOADING,NONE,NONE}` | `LOAD_SUCCEEDED` | `ACTIVE_ENTRY_DURABLE/true` | `{BATTLE_ACTIVE,NONE,NONE}` | `OK` | `ACTIVE_ENTRY_DURABLE`同时要求`LOAD_READY=true`；先持久化matching `ActiveEntryFactV1`并转`ACTIVE_RESERVED`，再完成ActivationCommitJournal与consumer/input reasoned release |
| `{BATTLE_LOADING,NONE,NONE}` | `LOAD_ABORT_RETRYABLE` | `LOAD_RETRYABLE_DISPOSITION/true` | `{PREP,NONE,NONE}` | `OK` | reservation与pre-outcome carrier exact-once release |
| `{BATTLE_LOADING,NONE,NONE}` | `LOAD_FAILED_UNCERTAIN` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 依据outcome_readiness选择pre-outcome或technical cleanup |
| `{BATTLE_ACTIVE,NONE,NONE}` | `PAUSE_REQUESTED` | `GRID_PAUSE_OK/true` | `{BATTLE_PAUSED,NONE,NONE}` | `OK` | 完成Pool/Input/pause-on后发布Paused |
| `{BATTLE_ACTIVE,NONE,NONE}` | `PAUSE_REQUESTED` | `GRID_PAUSE_PENDING/true` | `{PAUSE_PENDING,NONE,NONE}` | `OK` | `pause_drain_consumed=false`，输入锁定 |
| `{PAUSE_PENDING,NONE,NONE}` | `PAUSE_DRAIN_SUCCEEDED` | `ALWAYS/true` | `{BATTLE_PAUSED,NONE,NONE}` | `OK` | drain后Grid必须OK；第二次pending=fatal |
| `{BATTLE_PAUSED,NONE,NONE}` | `RESUME_REQUESTED` | `CAN_START_RESUME/true` | `{RESUME_PREPARING,NONE,NONE}` | `OK` | 捕获唯一attempt |
| `{RESUME_PREPARING,NONE,NONE}` | `RESUME_PREP_ABORTED` | `RESUME_PRE_PUBLISH_ABORTABLE/true` | `{BATTLE_PAUSED,NONE,NONE}` | `OK` | 点前恢复old owner并关闭candidate/lease |
| `{RESUME_PREPARING,NONE,NONE}` | `RESUME_POST_PUBLISH_HELD` | `RESUME_POST_PUBLISH_HELD/true` | `{RESUME_PREPARING,RESUME_HELD_DRAIN,NONE}` | `OK` | 无open resource |
| `{RESUME_PREPARING,NONE,NONE}` | `RESUME_ACTIVATED` | `RESUME_ACTIVATION_CLEAN/true` | `{BATTLE_ACTIVE,NONE,NONE}` | `OK` | Input/GameRoot commit后reasoned release |
| `{RESUME_PREPARING,RESUME_HELD_DRAIN,NONE}` | `RESUME_ACTIVATED` | `RESUME_ACTIVATION_CLEAN/true` | `{BATTLE_ACTIVE,NONE,NONE}` | `OK` | terminal后只重跑ACTIVE尾段 |
| `{RESUME_PREPARING,NONE,NONE}` | `RESUME_POST_PUBLISH_FAILED` | `RESUME_POST_PUBLISH_FAULT/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 完成保存tx后fault，禁止rollback |
| `{RESUME_PREPARING,RESUME_HELD_DRAIN,NONE}` | `RESUME_POST_PUBLISH_FAILED` | `RESUME_POST_PUBLISH_FAULT/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | held-drain fault收敛后进入Fault |
| `{BATTLE_ACTIVE,NONE,NONE}` | `BATTLE_END_LATCHED` | `ALWAYS/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | 安全barrier进入Ending |
| `{PAUSE_PENDING,NONE,NONE}` | `BATTLE_END_LATCHED` | `ALWAYS/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | consumer/input closed，先unpause/readback |
| `{BATTLE_PAUSED,NONE,NONE}` | `BATTLE_END_LATCHED` | `ALWAYS/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | consumer/input closed，先unpause/readback |
| `{RESUME_PREPARING,NONE,NONE}` | `BATTLE_END_LATCHED` | `ALWAYS/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | 收敛attempt后unpause/readback |
| `{RESUME_PREPARING,RESUME_HELD_DRAIN,NONE}` | `BATTLE_END_LATCHED` | `ALWAYS/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | 清held尾段并unpause/readback |
| `{BATTLE_LOADING,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 按outcome_readiness选择终局carrier |
| `{BATTLE_ACTIVE,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 先pause-on/readback，再cleanup |
| `{PAUSE_PENDING,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 保持input closed，pause-on/readback |
| `{BATTLE_PAUSED,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 已paused，不重复setter |
| `{RESUME_PREPARING,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 按point-before/after规则收敛 |
| `{RESUME_PREPARING,RESUME_HELD_DRAIN,NONE}` | `FATAL_FAILURE_LATCHED` | `ALWAYS/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | held-drain停止并收敛 |
| `{BATTLE_ENDING,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `NORMAL_TERMINAL_UNSEALED/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 保留committed facts，停止normal publish |
| `{BATTLE_ENDING,NONE,NONE}` | `FATAL_FAILURE_LATCHED` | `NORMAL_TERMINAL_SEALED/true` | `{BATTLE_ENDING,NONE,NONE}` | `OK` | outcome_kind不改；first completion fault写入 |
| `{BATTLE_ENDING,NONE,NONE}` | `OUTCOME_CLEANUP_FINISHED` | `CLEANUP_FINISHED/true` | `{SETTLEMENT,NONE,NONE}` | `OK` | ActivationCommitJournal从EXPOSURE逐点收敛至COMPLETED；每点可重入 |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `OUTCOME_CLEANUP_FINISHED` | `CLEANUP_FINISHED/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | expose technical/pre-outcome并沿journal收敛；safe terminal不伪装ACTIVE |
| `{SETTLEMENT,NONE,NONE}` | `RETURN_HOME` | `ALWAYS/true` | `{HOME,NONE,NONE}` | `OK` | unresolved保留；resolved carrier archive→retire |
| `{SETTLEMENT,NONE,NONE}` | `RETRY_RUN` | `ARCHIVE_ENTRY_READY/true` | `{PREP,NONE,NONE}` | `OK` | carrier archive→retire且`CARRIERS_RETIRED=true`后，available>0才创建fresh Prep/NONE；available=0则同press走`SETTLEMENT_DIRECT_NONE`的noninteractive PREP且页面Node=0 |
| `{SETTLEMENT,NONE,NONE}` | `RETRY_SAVE_COMMIT` | `SAVE_RETRYABLE/true` | `{SETTLEMENT,NONE,NONE}` | `OK` | 同commit ID、至多一个in-flight |
| `{SETTLEMENT,NONE,NONE}` | `RECONCILE_SAVE_COMMIT` | `SAVE_RECONCILABLE/true` | `{SETTLEMENT,NONE,NONE}` | `OK` | 查询durable commit/tombstone事实 |
| `{SETTLEMENT,NONE,NONE}` | `DISCARD_PENDING_COMMIT` | `SAVE_DISCARDABLE/true` | `{SETTLEMENT,NONE,NONE}` | `OK` | 二次确认后进入DISCARD_PENDING |
| `{SETTLEMENT,NONE,NONE}` | `RETRY_DISCARD_TOMBSTONE` | `DISCARD_PENDING_RETRYABLE/true` | `{SETTLEMENT,NONE,NONE}` | `OK` | 复用同一tombstone identity |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `RETRY_SAVE_COMMIT` | `SAVE_RETRYABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 仅EXPOSED technical outcome；不重复发奖 |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `RECONCILE_SAVE_COMMIT` | `SAVE_RECONCILABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 查询durable事实 |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `DISCARD_PENDING_COMMIT` | `SAVE_DISCARDABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 二次确认后进入DISCARD_PENDING |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `RETRY_DISCARD_TOMBSTONE` | `DISCARD_PENDING_RETRYABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 复用同一tombstone identity |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `SAFE_EXIT_HOME` | `FAULT_SAFE_EXIT_READY/true` | `{HOME,NONE,NONE}` | `OK` | 必须已EXPOSED；unresolved保留，resolved archive→retire |
| `{HOME,NONE,NONE}` | `RETRY_SAVE_COMMIT` | `SAVE_RETRYABLE/true` | `{HOME,NONE,NONE}` | `OK` | 不开放新局 |
| `{HOME,NONE,NONE}` | `RECONCILE_SAVE_COMMIT` | `SAVE_RECONCILABLE/true` | `{HOME,NONE,NONE}` | `OK` | 查询durable commit/tombstone事实 |
| `{HOME,NONE,NONE}` | `DISCARD_PENDING_COMMIT` | `SAVE_DISCARDABLE/true` | `{HOME,NONE,NONE}` | `OK` | 二次确认后进入DISCARD_PENDING |
| `{HOME,NONE,NONE}` | `RETRY_DISCARD_TOMBSTONE` | `DISCARD_PENDING_RETRYABLE/true` | `{HOME,NONE,NONE}` | `OK` | 复用同一tombstone identity |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `RETRY_PREOUTCOME_RESERVATION` | `PREOUTCOME_RESERVATION_RECOVERABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 复用reservation/recovery identity，发起exact-once release retry |
| `{CONTROLLED_FAULT,NONE,BATTLE}` | `RECONCILE_PREOUTCOME_RESERVATION` | `PREOUTCOME_RESERVATION_RECOVERABLE/true` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `OK` | 查询reservation durable事实，不构造Outcome/Save |
| `{HOME,NONE,NONE}` | `RETRY_PREOUTCOME_RESERVATION` | `PREOUTCOME_RESERVATION_RECOVERABLE/true` | `{HOME,NONE,NONE}` | `OK` | 保持新局入口关闭，复用同一reservation/recovery identity |
| `{HOME,NONE,NONE}` | `RECONCILE_PREOUTCOME_RESERVATION` | `PREOUTCOME_RESERVATION_RECOVERABLE/true` | `{HOME,NONE,NONE}` | `OK` | 查询reservation durable事实；仅RELEASED可retire |

转换动作本身也属于canonical execution outcome，不得把动作失败伪装成上表`OK`。`TransitionActionOutcomeV1={row_id,stable_order,source_tuple,event,action_checkpoint,injected_status,returned_status,target_tuple,expected_journal_state,side_effect_count}`的canonical hash覆盖以下72条实际行；不存在运行时展开、通配符或`|`简写：

| row | source / event | checkpoint | injected → returned | target | journal / committed effects |
|---|---|---|---|---|---|
| `TA01` | `PREP/CONFIRM_RUN` | `ALLOCATE_BATTLE_INSTANCE_ID` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA02` | `PREP/CONFIRM_RUN` | `BIND_PREOUTCOME_BACKING` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA03` | `BATTLE_ENDING/FATAL_FAILURE_LATCHED` | `ALLOCATE_OUTCOME_COMMIT_ID` | `ID_EXHAUSTED→ID_EXHAUSTED` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `IDENTITY_UNAVAILABLE/1` |
| `TA04` | `BATTLE_LOADING/LOAD_SUCCEEDED` | `ACTIVATION_COMMIT` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `ActivationCommitJournal最高已提交点/按点计` |
| `TA05` | `HOME/START_RUN` | `ARCHIVE_PREPARE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA06` | `HOME/START_RUN` | `ARCHIVE_COMMIT` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `PREPARED/1` |
| `TA07` | `HOME/START_RUN` | `RETIRE_CARRIERS` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `ARCHIVE_COMMITTED/2` |
| `TA08` | `SETTLEMENT/RETRY_RUN` | `ARCHIVE_PREPARE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA09` | `SETTLEMENT/RETRY_RUN` | `ARCHIVE_COMMIT` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `PREPARED/1` |
| `TA10` | `SETTLEMENT/RETRY_RUN` | `RETIRE_CARRIERS` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `ARCHIVE_COMMITTED/2` |
| `TA11` | `SETTLEMENT/RETURN_HOME` | `ARCHIVE_PREPARE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA12` | `SETTLEMENT/RETURN_HOME` | `ARCHIVE_COMMIT` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `PREPARED/1` |
| `TA13` | `SETTLEMENT/RETURN_HOME` | `RETIRE_CARRIERS` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `ARCHIVE_COMMITTED/2` |
| `TA14` | `SETTLEMENT/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA15` | `SETTLEMENT/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA16` | `SETTLEMENT/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA17` | `SETTLEMENT/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA18` | `CONTROLLED_FAULT(BATTLE)/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA19` | `CONTROLLED_FAULT(BATTLE)/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA20` | `CONTROLLED_FAULT(BATTLE)/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA21` | `CONTROLLED_FAULT(BATTLE)/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA22` | `HOME/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA23` | `HOME/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA24` | `HOME/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA25` | `HOME/RETRY_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA26` | `SETTLEMENT/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA27` | `SETTLEMENT/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA28` | `SETTLEMENT/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA29` | `SETTLEMENT/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA30` | `CONTROLLED_FAULT(BATTLE)/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA31` | `CONTROLLED_FAULT(BATTLE)/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA32` | `CONTROLLED_FAULT(BATTLE)/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA33` | `CONTROLLED_FAULT(BATTLE)/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA34` | `HOME/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA35` | `HOME/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA36` | `HOME/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA37` | `HOME/RECONCILE_SAVE_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA38` | `SETTLEMENT/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA39` | `SETTLEMENT/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA40` | `SETTLEMENT/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA41` | `SETTLEMENT/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA42` | `CONTROLLED_FAULT(BATTLE)/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA43` | `CONTROLLED_FAULT(BATTLE)/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA44` | `CONTROLLED_FAULT(BATTLE)/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA45` | `CONTROLLED_FAULT(BATTLE)/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA46` | `HOME/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA47` | `HOME/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA48` | `HOME/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA49` | `HOME/DISCARD_PENDING_COMMIT` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA50` | `SETTLEMENT/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA51` | `SETTLEMENT/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA52` | `SETTLEMENT/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA53` | `SETTLEMENT/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA54` | `CONTROLLED_FAULT(BATTLE)/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA55` | `CONTROLLED_FAULT(BATTLE)/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA56` | `CONTROLLED_FAULT(BATTLE)/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA57` | `CONTROLLED_FAULT(BATTLE)/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA58` | `HOME/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `INVALID_ARGUMENT→INVALID_ARGUMENT` | 原source | `NONE/0` |
| `TA59` | `HOME/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `LIMIT_EXCEEDED→LIMIT_EXCEEDED` | 原source | `NONE/0` |
| `TA60` | `HOME/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA61` | `HOME/RETRY_DISCARD_TOMBSTONE` | `REQUEST_VALIDATE_OR_ALLOCATE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `NONE/0` |
| `TA62` | `PREP/CONFIRM_RUN` | `ZHANGTIAN_ALLOCATE_PREPARATION_ID` | `ID_EXHAUSTED→ID_EXHAUSTED` | 原source | `NONE/0` |
| `TA63` | `PREP/CONFIRM_RUN` | `RESERVATION_WRITE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `PONR前PrepCommitJournal=ABSENT/0；任何可能写入转PREP_RESERVATION_UNCERTAIN并只scan` |
| `TA64` | `PREP/PREP_RESERVATION_UNCERTAIN` | `RESERVATION_RECONCILE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `PrepCommitJournal保留/0` |
| `TA65` | `PREP/PREP_RESERVATION_DURABLE` | `RUN_START_RECOVERY_FREEZE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `RESERVATION_DURABLE/0` |
| `TA66` | `PREP/PREP_RESERVATION_DURABLE` | `PAGE_TOUCH_RETIRE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `RESERVATION_DURABLE/0` |
| `TA67` | `PREP/PREP_RESERVATION_DURABLE` | `LOADING_COMMIT` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | 原source | `RESERVATION_DURABLE/0` |
| `TA68` | `BATTLE_LOADING/PRE_ACTIVE_CHOICE_REQUIRED` | `PRE_ACTIVE_OFFER_BUILD` | `CLEAR_FAILURE→DEPENDENCY_FAILURE` | `{PREP,NONE,NONE}` | `LFD25系统级durable RELEASE完成后发布fresh Prep；interactive offer/action=0` |
| `TA69` | `BATTLE_LOADING/PRE_ACTIVE_CHOICE_REQUIRED` | `PRE_ACTIVE_OFFER_BUILD` | `WRITE_POSSIBLE_OR_READBACK_UNKNOWN→DEPENDENCY_FAILURE` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `LFD26；同reservation/recovery保留并转UNCERTAIN，fresh Prep=0` |
| `TA70` | `PRE_ACTIVE_CHOICE/PRE_ACTIVE_CHOICE_COMMITTED` | `CHOICE_DURABLE_COMMIT` | `CLEAR_FAILURE→DEPENDENCY_FAILURE` | `{PRE_ACTIVE_CHOICE,NONE,NONE}` | `保留同一durable offer；玩家可重试同一command，refresh/loadout不变` |
| `TA71` | `PRE_ACTIVE_CHOICE/PRE_ACTIVE_CHOICE_COMMITTED` | `CHOICE_DURABLE_COMMIT` | `WRITE_POSSIBLE_OR_READBACK_UNKNOWN→DEPENDENCY_FAILURE` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `同reservation/recovery转UNCERTAIN；不得重选、release或发布Active` |
| `TA72` | `BATTLE_LOADING/LOAD_SUCCEEDED` | `ACTIVE_ENTRY_DURABLE` | `DEPENDENCY_FAILURE→DEPENDENCY_FAILURE` | `{CONTROLLED_FAULT,NONE,BATTLE}` | `ACTIVE_MARK_PENDING或UNCERTAIN/0；按LFD27/28与readback事实收敛` |

72行本身是唯一expected。TA01/02、TA14..61及TA62失败时ResourceIdentityManifest逐字段不变；TA05..13允许ArchiveRetireJournal单调前进，TA63..72允许`PrepCommitJournal/ActiveEntryFact/reservation resolution`仅按已持久化checkpoint单调前进，但top-state不得伪装成功，已durable checkpoint不得回滚或重复；TA03明确是终局commit identity失败，不得与battle identity分配失败混为一行。

BOOT/HOME/PREP 中尚未发布 `battle_instance_id` 的前置故障不得构造逻辑 `RunOutcomeEnvelope`或`outcome_commit_id`；只记录启动诊断。BOOT预留固定、无逻辑identity的PreOutcome/Outcome/Completion/Save backing。UI唯一业务命令类型是`PrepConfirmCommandV1`，其中不得携带`preparation_id`。GameRoot验证命令后请求PREP release路径的唯一OS entropy producer给出run seed；Save在首次reservation transaction内从持久`next_identity`分配非零`battle_instance_id=reservation_id`，Zhangtian同时从持久`next_preparation_id`分配preparation identity，两个allocator、NONE或pill after-image、360-byte base recovery及唯一nested journal checkpoint1同槽原子提交。recovery持久`{config_content_revision,config_content_hash}`，不持久process-local snapshot ID。NONE不改三种药量但仍推进domain/profile revision与两个allocator。成功readback后，同一handoff从recovery生成`RunStartRequestV2={battle_instance_id,run_seed,reservation_id,preparation_id,selected_pill_id,zhangtian_projection_hash,profile_revision,config_content_revision,config_content_hash}`进入Loading。PONR前可证明未写入才回滚内存candidate；PONR后unknown保留同identity在PREP/UNCERTAIN且禁止第二次confirm。Loading全部Config/RNG preflight成功后把132-byte`ZhangtianSeedCandidateV1`的canonical字段写入同一recovery并以checkpoint5 durable；candidate encode/write/readback使用point15的三个`LoadInjectionSubphaseV1` fixture，不得回写RunStartRequest，同run retry或跨进程恢复不得产生第二logical draw。进入Loading后最小逻辑carrier为`PreOutcomeFaultCompletionV1={schema_version:int32=1,battle_instance_id:int64,diagnostic_id:int64,load_injection_point_id:int32,load_injection_subphase_id:int32,reservation_id:int64,reservation_state:PreOutcomeReservationState,reservation_recovery_operation_id:int64,cleanup_state:PreOutcomeCleanupState}`。正常终局仲裁仍为VICTORY优先；seal后故障不改normal outcome。

reservation恢复以Save的`DurableReservationV2`（1152 bytes）为真相源，并由固定360-byte app-scope `RunStartRecoveryV1`与七checkpoint `PrepCommitJournalV1`驱动；完整field schema、`PreActiveChoiceStateV1`数值和deterministic replay协议以Zhangtian/Save GDD为准。跨进程只匹配`{config_content_revision,config_content_hash}`，并逐位比较252-byte offer/296-byte loadout semantic hash；新process-local snapshot/bank/generation仅在exact content rebind后用于本进程。唯一journal只存在于`DurableReservationV2.prep_commit_journal`。每次修改必须走Save `ReservationUpdateRequestV2`的generation/checkpoint/hash CAS及五行typed payload presence matrix；create V3返回的`operation_id`必须逐位等于后续`recovery_operation_id`。`PreOutcomeReservationRecoveryV1={schema_version:int32=1,reservation_id:int64,battle_instance_id:int64,state:PreOutcomeReservationState,operation_kind:int32,in_flight:int32,attempt_generation:int64,request_id:int64,recovery_operation_id:int64}`仅负责release/reconcile，且`recovery_operation_id==RunStartRecoveryV1.prep_commit_operation_id`。callback须matching全部correlation，否则`OK_NOOP`。既有reservation update UNCERTAIN必须按selected formal reservation hash唯一裁定：next hash=`RECONCILE_FOUND`，old hash且attempt absence proof完整=`RECONCILE_FOUND_OLD`，UNPROVEN继续冻结；全reservation PROVEN_ABSENT不用于该分支。`RELEASED/CONSUMED`是durable终态，terminal `UNCERTAIN`按前置invariant validator+13-row `ReservationReconcileDispositionManifestV2`恢复；首个Active tick前必须写/readback `ActiveEntryFactV1`及checkpoint7。terminal consume/release只允许唯一`ReservationUpdateRequestV2(RESOLVE)`携带`ResolveReservationPayloadV3`，在同一slot transaction原子写奖励或tombstone、264-byte latest resolution与完整next profile并清除pending reservation/active marker；MVP不得另发`SaveCommitRequestV1`。Active orphan固定consume，只有sealed技术补偿或LFD25证明base offer尚未开始的系统clear failure允许release。HOME/Fault显示“开局资源状态待确认”并关闭新局入口；非法reservation state不得伪装为已消费或技术补偿。

BOOT 先在任何 battle input target/consumer/callback/polling 入树前完成一次 Input bootstrap并预留上述unbound backing。每次 BATTLE_LOADING固定且唯一的创建DAG为：

第八轮整改覆盖：reservation恢复实现必须改用`DurableReservationV2`（1152 bytes）及64-byte `ReservationCreateCorrelationV1`；上一行中的`DurableReservationV1`/1088-byte口径仅为历史记录，禁止作为当前schema读取。MPSC native payload为68 bytes并由serial ingress补齐76-byte command，Meta UI Input manifest为8行。

`Config最小schema→BOOT reserve unbound PreOutcome/Outcome/Completion/Save backing→PREP接收PrepConfirmCommandV1→生成release run_seed candidate→Save+Zhangtian同槽分配battle/reservation/preparation identities、domain after-image、360-byte recovery与checkpoint1并readback→checkpoint2冻结RunStartRequest→checkpoint3 retire Prep touch→checkpoint4提交Loading→bind PreOutcome→按durable config content key build/rebind process-local snapshot→初始化并验证Outcome/Completion/Save backing→RNG init(snapshot.run_seed)→ZHANGTIAN_HERB恰1 logical call→point15 encode/write/readback三subphase并以checkpoint5持久132-byte candidate→Stage/Input/Grid/Pool/owners初始化与identity preflight→聚气丹按360-byte recovery重建/持久PRE_ACTIVE_CHOICE，非聚气skip，以checkpoint6收敛→root Window gate acquire→持久化/readback ActiveEntryFact与checkpoint7并转ACTIVE_RESERVED→Input ACTIVE publish→GameRoot local commit→ACTIVATION_SUCCESS release`。首个offer durable/可见后不允许release换取fresh seed；Back、重启只恢复同一offer。不得出现RNG早于Outcome READY、process-local snapshot ID持久化、第二份Prep journal或第二条可选DAG。

Stage camera 必须满足 `stage_camera.get_viewport()==root_window`、`root_window.get_camera_2d()==stage_camera`，且 Host/Shield/VJ/BattleUI 的 `get_viewport()` 也逐项等于同一 root Window；Camera registry中不得存在第二个enabled battle camera。load时冻结唯一 `BattleViewportTopologyManifest={topology_revision,battle_instance_id,config_snapshot_id,stage_world_view_generation,root_window_instance_id,stage_root_instance_id,stage_root_parent_instance_id,stage_camera_instance_id,stage_camera_parent_instance_id,current_camera_instance_id,ground_presenter_instance_id,host_instance_id,host_parent_instance_id,shield_instance_id,shield_parent_instance_id,vj_instance_id,vj_parent_instance_id,battle_ui_instance_id,battle_ui_parent_instance_id,host_viewport_instance_id,shield_viewport_instance_id,vj_viewport_instance_id,battle_ui_viewport_instance_id,enabled_camera_count,nested_viewport_count}`；所有跨文档只允许使用字段名 `topology_revision`，不得另造 `viewport_topology_revision` 或简称字段。GameRoot只保存non-owning assembly引用，不写camera `zoom/position/limit/enabled`；Stage是camera transform/ground presentation唯一writer。每个成功MOVEMENT_COMMIT后，Stage只读matching已发布`PlayerMotionCommitCarrierV1.position`，在Grid sync/Spawn下tick读取前把camera中心逐bit设为该值并重定位固定数量地表tile或更新world-UV shader；不得插值、clamp、读Node mirror或把camera位置反写authority。Stage owner之外 `make_current/reparent/set_enabled/custom_viewport` 与创建nested Window/SubViewport的项目writer数必须为0。完整battle manifest在BATTLE_LOADING preflight、每个ACTIVE callback进入七phase前、resume全部checkpoint及cleanup开始前逐字段readback；任一非预期漂移使consumer保持关闭并进入fault。

cleanup开始后，预期detach会主动终止完整battle manifest的相等性要求，禁止再拿旧Host/Shield/VJ/BattleUI identity判drift。GameRoot的ALWAYS `lifecycle_pump`是Loading activation、Ending/Fault cleanup与frame barrier唯一推进者，participant/UI不得自行越级；其调度资格是`ActivationCommitJournal/CleanupSubstate尚未terminal`，不依赖当前TopState，所以目标top-state先提交后仍可继续收敛。`CleanupSubstate`单向FSM固定为`NONE→PRE_ACQUIRE→(GATE_RETRY_WAIT→PRE_ACQUIRE，最多3次|DETACHING)→DESTINATION_STAGED→FRAME_BARRIER_WAIT→EXPOSURE_COMMIT→DESTINATION_ACTIVE→DONE`；三次失败后固定`ACQUIRE_FAILED_SAFE→SAFE_TERMINAL→DONE`。`ACQUIRED/REUSED`从PRE_ACQUIRE直接进入DETACHING，任一重复checkpoint返回`OK_NOOP`。

`PRE_ACQUIRE`若gate已owned则`acquire_mode=REUSED/acquire_count=0`；若未owned则经同一helper执行`set_disable_input(true)`+readback。setter/readback失败先撤销全部旧input callback/target writer并令root Window无项目input target，再进入`GATE_RETRY_WAIT`；lifecycle pump按固定attempt 1..3重试且每次记录readback，不使用wallclock/backoff。第三次失败进入`ACQUIRE_FAILED_SAFE`、release_count=0；此路只安装视觉可见但`DestinationUIState=SAFE_TERMINAL_NONINTERACTIVE`的最小“输入保护失败，请重新启动”UI，其Control均`mouse_filter=IGNORE`、focus owner=0、项目input callback=0，不能声明`new_ui_is_unique_input_target=true`，不得自动返回可交互HOME/Settlement。失败不伪装成held gate。

预分配 `CleanupViewportHandoffManifest={topology_revision,battle_instance_id,root_window_instance_id,destination_top_state,destination_ui_role_id,old_host_detached,old_shield_detached,old_vj_detached,old_battle_ui_detached,old_gameplay_callback_count,new_ui_root_instance_id,new_ui_viewport_instance_id,new_ui_is_unique_input_target,cleanup_gate_acquire_mode,cleanup_gate_acquire_count,cleanup_gate_release_count,viewport_gate_owned,scene_tree_paused}` 只证明旧battle已移交、destination已staged，不授权交互。`ActivationCommitJournalV1={schema_version:int32=1,operation_id:int64,battle_instance_id:int64,destination_top_state:int32,exposure_requirement:ExposureRequirement,state:int32,gate_attempt_count:int32,old_detached:int32,frame_barrier_done:int32,carrier_exposed:int32,ui_activated:int32,top_state_committed:int32,gate_released:int32}` 的state按`PREPARED→OLD_DETACHED→FRAME_BARRIER_DONE→EXPOSURE_DONE_OR_NA→UI_ACTIVE_OR_SAFE→TOP_STATE_COMMITTED→GATE_RELEASED_OR_NA→COMPLETED`单调推进；每步先写可重入证据再发下一fallible Godot操作，重入只重试首个未完成点。`DestinationActivationManifest={schema_version:int32=1,battle_instance_id:int64,destination_top_state:int32,destination_ui_role_id:int32,new_ui_root_instance_id:int64,new_ui_viewport_instance_id:int64,old_nodes_physically_invalid:int32,old_gameplay_callback_count:int32,scene_tree_paused:int32,exposure_requirement:ExposureRequirement,outcome_or_preoutcome_exposed:int32,new_ui_is_unique_input_target:int32,destination_ui_state:DestinationUIState}`是最终激活唯一权威：正常路径在旧Node frame-end失效、pause=false、required carrier exact-once expose、目标top-state commit均已由journal证明后激活唯一input target；retryable Loading返回PREP使用`NOT_APPLICABLE`且不要求暴露carrier。任一条件失败保持staged并由lifecycle pump继续，不得丢失推进资格。

`ACQUIRED/REUSED`只有在DestinationActivationManifest最终验证通过后才reasoned release一次，要求release前gate owned且release_count最终恰1；`ACQUIRE_FAILED_SAFE`始终gate=false、input target=0、release_count=0，并以`SAFE_TERMINAL_NONINTERACTIVE`诚实终止。activation success只接受完整Battle manifest；cleanup handoff、activation journal与destination activation各用各自manifest，不得互换。

任一失败只清理已创建资源，按依赖 DAG 收敛而非机械逆序：

`consumer/input close→PRE_ACQUIRE（失败时固定重试至3次）或ACQUIRE_FAILED_SAFE writer撤销→owner rollback/teardown→close/abort leases+candidates→SpatialGrid teardown并使旧handle失效→Pool teardown(grid_invalidated=true)→Grid reset→Input terminal + Host/Shield/VJ/BattleUI gameplay callback撤销并逻辑detach→目标UI正常路STAGED_NONINTERACTIVE/safe路SAFE_TERMINAL_NONINTERACTIVE→冻结并验证CleanupViewportHandoffManifest→Stage child逻辑detach→可释放的banks/RNG/config snapshot release（sealed Outcome/Completion/Save或PreOutcome保留到required expose）→若SceneTree仍paused则唯一helper set_pause(false)+readback→frame-end deletion barrier后验证queued Node物理失效→ActivationCommitJournal逐点完成expose-or-NA、目标top-state、UI activate-or-safe、gate release-or-NA→cleanup_substate=DONE`。

每个cleanup节点固定 `{created_guard,idempotent_status,failure_policy}`。依赖前项未满足时不得越过会访问其资源的后项；可继续的cleanup failure写suppressed diagnostic，不覆盖root cause。所有公开load返回值先经实际9行 `LoadStatusNormalizationManifestV1={row_id,stable_order,raw_status,normalized_class}` 归一化，canonical rows为：`LSN01/OK/SUCCESS`、`LSN02/OK_NOOP/SUCCESS`、`LSN03/WRONG_STATE/CALLER_ERROR`、`LSN04/INVALID_ARGUMENT/CALLER_ERROR`、`LSN05/INVALID_MANIFEST/CONTRACT_ERROR`、`LSN06/CAPACITY_EXCEEDED/CAPACITY_ERROR`、`LSN07/LIMIT_EXCEEDED/CAPACITY_ERROR`、`LSN08/ID_EXHAUSTED/IDENTITY_ERROR`、`LSN09/DEPENDENCY_FAILURE/DEPENDENCY_ERROR`；缺status/重复/unknown不得进入LFD，直接为contract failure。Config另冻结实际 `LoadFailureDispositionManifestV1`，行schema为`{row_id,stable_order,injection_point,status_class,permanent_write_acquired,pre_active_offer_persistence_class,cleanup_result,target_event,reservation_state,outcome_readiness,outcome_binding_state}`；`pre_active_offer_persistence_class={NOT_APPLICABLE=0,NOT_STARTED_CLEAR=1,DURABLE_OR_WRITE_POSSIBLE=2}`，LFD25固定为1、LFD26固定为2，其余行固定为0。LFD25还要求`offer_visible_count=0`且interactive snapshot/action=0；任一encode/write/readback无法证明clear，或任一durable/visible事实成立，必须归LFD26。`status_class=NON_SUCCESS`表示逐一覆盖LSN03..09七类且每个fixture必须携带对应LSN row，不能只测`DEPENDENCY_FAILURE`。canonical 30 rows如下，每个point恰两行：

| row_id | point | injected condition | permanent | cleanup | event | reservation | readiness/binding |
|---|---|---|---:|---|---|---|---|
| `LFD01` | `CONFIG_BUILD` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD02` | `OUTCOME_BACKING_INIT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD03` | `OUTCOME_READY_VALIDATE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD04` | `RNG_INIT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD05` | `STAGE_ASSEMBLY` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD06` | `INPUT_INIT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD07` | `GRID_INIT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD08` | `POOL_INIT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD09` | `OWNER_WARMUP` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD10` | `MANIFEST_VALIDATE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD11` | `IDENTITY_PREFLIGHT` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD12` | `ROOT_GATE_ACQUIRE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD13` | `CONFIG_BUILD` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD14` | `OUTCOME_BACKING_INIT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD15` | `OUTCOME_READY_VALIDATE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `UNAVAILABLE_PRE_CARRIER/UNBOUND` |
| `LFD16` | `RNG_INIT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD17` | `STAGE_ASSEMBLY` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD18` | `INPUT_INIT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD19` | `GRID_INIT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD20` | `POOL_INIT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD21` | `OWNER_WARMUP` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD22` | `MANIFEST_VALIDATE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD23` | `IDENTITY_PREFLIGHT` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD24` | `ROOT_GATE_ACQUIRE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD25` | `PRE_ACTIVE_CHOICE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD26` | `PRE_ACTIVE_CHOICE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD27` | `ACTIVE_ENTRY_DURABLE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD28` | `ACTIVE_ENTRY_DURABLE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |
| `LFD29` | `SEED_CANDIDATE_DURABLE` | `NON_SUCCESS` | 0 | `ALL_OK` | `LOAD_ABORT_RETRYABLE` | `RELEASED` | `READY/UNBOUND` |
| `LFD30` | `SEED_CANDIDATE_DURABLE` | `NON_SUCCESS` | 1 | `FAULTED` | `LOAD_FAILED_UNCERTAIN` | `UNCERTAIN` | `READY/UNBOUND` |

stable_order等于row ID数字后缀1..30，以上就是进入canonical hash的实际row。LFD01..12、LFD25、LFD27、LFD29是可证明PONR前/marker前的clear failure，可在durable release后回PREP；其余进入Battle Fault。LFD25是base offer publish前的系统失败回滚，不是玩家转换；LFD26覆盖offer write可能、readback未知、durable或visible任一事实，禁止release。LFD29/30各按`LoadInjectionSubphaseV1={CANONICAL_ENCODE,WORKER_WRITE,DURABLE_READBACK}`展开三条fixture，point/subphase组合进入fixture hash；任一永久写可能成立只能走LFD30/UNCERTAIN。ActiveEntry已经durable时不属于LFD27，必须按active orphan consume收敛。终局identity分配失败不属于LoadInjectionPoint，走`TA01`与`IDENTITY_UNAVAILABLE`分支。

### R3 — Battle identity、authority/resolution bank 与 exact-once token

- PREP 每次确认新局都分配非零、应用生命周期内单调且不复用的 `battle_instance_id:int64`；耗尽=`ID_EXHAUSTED`。`run_seed`可以重复，不是identity。`config_snapshot_id`是 `BattleConfigSnapshot.snapshot_id` 的跨文档同义名，仅表示本局Config实例，也不是持久化幂等键。
- 两个等容量 `BattleAuthorityBundle` 在load预分配，header固定为 `{battle_instance_id,config_snapshot_id,bank_id in {0,1},authority_revision}`。初始published authority revision=0；`authority_revision` **只按成功authority bank publish次数** checked `+1`，不按journal行或内部side effect递增。一次DEFERRED_REMOVAL最多一次batch publish；一次Paused choice publish与一次resume authority publish各最多一次。未发布不递增，耗尽=`ID_EXHAUSTED`。
- 每次`BattleAuthorityBundle` full-copy都必须逐字段复制capacity1的Player HP/life slice，即使PLAYER本phase为no-op；由GameRoot authority reader提供`PlayerHpAuthorityViewV1={schema_version=1,battle_instance_id,config_snapshot_id,authority_bank_id,authority_revision,player_id,current_hp,max_hp,life_state,view_generation,valid}`的caller-owned copy-out。它不是HUD或第三套backing，revision精确等于当前published bundle；Drop只读该view判断回春掉落资格。stale expected revision、旧generation或teardown后读取必须拒绝且out不变。
- `AuthorityCopyManifest` 枚举每个 primitive SoA 字段及独立 authoritative count。A/B carrier预resize并独占backing；Active/Paused禁止 `clear/resize/append_array/duplicate/slice`、共享COW alias、容器替换和dirty-patch。每字段逐index复制 `[0,count)`，tail非权威。
- 两个 `ResolutionStagingBank` header固定为 `{battle_instance_id,resolution_bank_id,source_authority_revision,tick_revision,resolution_publish_revision}`。matching QUERY_CONSUME publish checked increment并产生唯一 `ResolutionPublishTokenV1={battle_instance_id,resolution_bank_id,source_authority_revision,tick_revision,resolution_publish_revision}`；owner row逐字段复制该tuple，禁止另建scalar resolution token。
- DEFERRED_REMOVAL 仅当published token逐字段匹配当前battle、published bank、source authority与tick，且 `consumed_token!=published_token` 时开始消费。消费前原子复制完整token到 `consumed_token`；同token二次消费为0。跨battle、错bank、错authority或错tick token均fault。
- DEFERRED_REMOVAL 使用 load 时定容、**一 intent 一 mutable row** 的 `LifecycleCommitJournal`：`{battle_instance_id,tick_revision,lifecycle_sequence,participant_id,object_instance_id,prior_handle_id,borrow_id,effect_kind,commit_state,batch_authority_revision}`。公开 `commit_state={RESERVED,GRID_REMOVED,POOL_UNBOUND,POOL_RELEASED,POOL_RETIRED}` 单调推进且每个状态最多进入一次；Pool内部 `RELEASE_PENDING→RESET_COMPLETED→AVAILABLE_COMMITTED|RETIRED_COMMITTED` 由Pool私有slot FSM exact-once保证，GameRoot不把reset/free-stack内部checkpoint伪造成多条公开journal row。任何failure不得降低state、恢复旧handle/borrow或重放已完成API；未开始/仅RESERVED行可丢弃。
- lifecycle journal **不承载 gameplay fact**。同一phase另用预分配 `CommittedGameplayFactLedger`，每行固定 `{battle_instance_id,tick_revision,fact_sequence,producer_role_id,fact_kind,subject_id,source_id,value_i64,value_f64,commit_state,batch_authority_revision}`；`fact_kind={DAMAGE,HEAL,DEATH,PICKUP,REWARD}`，`commit_state={RESERVED,COMMITTED}`。DAMAGE/HEAL只使用finite canonical `value_f64`，其中HEAL记录Player实际应用且clamp后的正恢复量；PICKUP/REWARD只使用checked `value_i64`，DEATH用稳定subject/source ID；未COMMITTED行不得进入authority或Outcome。
- BATTLE_RULES的核心灵药使用capacity1预分配`CoreHerbRewardStageBankV1`，只在matching terminal precollection winner为VICTORY的phase6写入。其row按Drop/Leveling GDD R3映射到通用ledger：`fact_sequence=reserved_fact_sequence`、`producer_role_id=BATTLE_RULES`、`fact_kind=REWARD`、`subject_id=item_id`、`source_id=source_enemy_id`、`value_i64=1`、`value_f64=0`。phase7不得新建fact，只以fact sequence+precollection token+source death sequence join staging/COMMITTED fact；最终同token sealed VICTORY才进入Outcome，其他技术审计fact不结算。
- phase 5除Damage resolution外，由唯一`PlayerRecoveryResolver`即DamageSystem把Longchun/Buff/RiskChoice typed intent稳定聚合到预分配A/B `PlayerRecoveryResolutionV1`并发布唯一selector。Paused期间只可冻结RiskChoice intent，不能改HP；该intent最早在resume后的首个Active deferred batch消费。Player phase6固定按`DAMAGE→lethal判定→仅非致命时HEAL clamp`处理；致命同tick恢复抑制且不结转，实际DAMAGE+HEAL的fact sequence固定前者小于后者，最终HP/HUD只发布一次。DamageSystem作者契约已建立，仍待独立full review。
- phase 5 matching resolution publish后、任何phase-6 side effect前，GameRoot执行无副作用 terminal precollection：要求BATTLE_RULES及所有Config列明的terminal contender producer对同一`ResolutionPublishTokenV1`各提交恰一条typed preview（可显式NONE），收齐后用独立`TerminalPriorityGoldenV1`冻结 `TerminalPrecollectionViewV1={schema_version=1,battle_instance_id,config_snapshot_id,tick_revision,source_authority_revision,resolution_bank_id,resolution_publish_revision,contender_mask,precollected_winner,producer_coverage_hash,precollection_token,valid}`。Boss只暴露getter-only lethal projection；Settlement GDD中的`BattleOutcomeRulesV1`以matching current Boss HP与final damage无副作用产生VICTORY preview，并在phase6/7提交最多6条terminal reward facts与3条record candidates。缺/重/stale producer、hash或capacity不匹配在phase6前fault；runtime integration仍BLOCKED。
- phase 6 在任何side effect前构造并arm预分配 `Phase6AuthorityBatchPlanV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,next_authority_revision:int64,inactive_authority_bank_id:int32,resolution_bank_id:int32,resolution_publish_revision:int64,recovery_bank_id:int32,recovery_publish_revision:int64,terminal_precollection_token:int64,authority_copy_manifest_hash:int64,plan_generation:int64,armed:bool,valid:bool}`。`plan_generation`初始化为0，每次合法arm前checked `+1`，耗尽在任何copy/side effect前返回`ID_EXHAUSTED`；view只在matching batch内valid，batch结束或teardown先置`valid=false`再推进generation。对participant只暴露逐字段相同、getter-only的`Phase6AuthorityBatchPlanViewV1`；`valid=false`或任一phase不匹配字段不得冒充unbound，unbound只用`null`。每次普通phase-6 arm都按`AuthorityCopyManifest`把published bank所有field的`[0,count)`完整复制到inactive bank恰一次并验证header/count/capacity；`committed_authority_visible_rows=0`也必须执行该次copy，只是不publish。arm失败时journal/fact commit与side effect均为0。随后按journal/fact ledger的已提交行就地更新inactive bank，不向consumer逐step发布。定义 `committed_authority_visible_rows` 为本batch中已进入 `GRID_REMOVED/POOL_UNBOUND/POOL_RELEASED/POOL_RETIRED` 的lifecycle row与所有COMMITTED fact row之和；其为0时authority publish=0/revision不变，`>0`时matching end或fault convergence用已arm plan恰publish一次且不可失败、revision精确`+1`。若中途failure且已有不可逆行，则停止后续intent，以已提交rows完成该唯一publish：normal terminal seal前进入TECHNICAL_ABORT，seal后保持normal outcome并写RunCompletionStatus。Pool reset/release failure发生在Grid remove后时，journal推进到Pool公开API能证明的最高终态；不可信slot固定`POOL_RETIRED`。batch publish后所有本batch committed row写同一`batch_authority_revision`；禁止旧authority继续引用stale handle/borrow。
- PLAYER复活是phase-6明确特化：Player先把完整clear identity写入私有`ReviveClearIntentBankV1`，再通过注入的`ReviveClearLifecycleResolverCapabilityV1`请求Enemy/GameRoot resolver为全部identity预留并验证N条journal row及checked sequence；所有row固定`participant_id=ENEMY`并计入ENEMY 303 lifecycle capacity，PLAYER contribution恒为0。journal backing与Grid/Pool副作用不暴露给Player。preflight同时消费matching terminal precollection，完成17点/enemy-swept/hazard评分、reserve非零DAMAGE fact，并arm Player authority/motion/HUD/event tuple与one-shot commit capability。只有全部reservation/capability成功后，DAMAGE fact首次进入`COMMITTED`才成为唯一`revive_point_of_no_return`；所有`REVIVE_CLEAR` row只能在该点后由同一resolver按完整tuple总序推进，PONR后禁止新建row/sequence/capability。点前失败时fact/lifecycle/player输出均零公开；点后故障必须在consumer closed下收敛已预留journal与armed tuple，再按`BattleAuthorityBundle selector→optional motion selector→HUD selector→optional transient event selector→optional critical ledger PUBLISHED transition→Node mirror`固定顺序提交一次，全部共享`batch_authority_revision`且arm后不可失败，最后才开放presentation readers。任何Player HUD publish都要求先把当前motion完整复制到inactive bank、写入同一next authority revision并切motion selector；因此此时motion不是optional，只有Player无HUD/authority输出的no-op才可省略。`PlayerPresentationFrameV1`没有独立bank/selector，只由matching已发布motion+HUD allocation-free copy-out联结生成。禁止以首条Grid remove作为PONR。
- Grid `snapshot_revision`、GameRoot `authority_revision`、`tick_revision`、Config `snapshot_id` 与Input/background/geometry revision是独立轴，不得统称 `snapshot revision`。
- `FailureDiagnosticBank` 在load预分配：1个first槽、固定 `MAX_SUPPRESSED_DIAGNOSTICS=C` 槽与overflow counter，域固定 `C:int64>=1`。first/suppressed schema固定为 `{diagnostic_id,battle_instance_id,state,tick_revision,phase,status,api_id,participant_id,config_snapshot_id}`；热路径只写primitive稳定ID，字符串格式化在gameplay停止后进行。suppressed attempt counter使用checked int64，耗尽时固定饱和到`INT64_MAX`并置`diagnostic_counter_saturated=true`，不覆盖first。
- RNG fault另写load时预分配、versioned `RngFaultTelemetrySnapshot`：`{diagnostic_id,battle_instance_id,config_snapshot_id,run_seed,stream_count,stream_ids[8],call_counts[8],pre_fault_states[8],fault_stream_id,fault_reason}`。它在RNG teardown前、first failure capture的同一cleanup transaction中恰写一次，以`diagnostic_id`与first槽关联；无RNG fault时`stream_count=0`。该sidecar不扩展first热路径schema。
- resume前构造预分配 `AuthorityResumeCommitPlan={battle_instance_id,config_snapshot_id,source_authority_revision,next_authority_revision,inactive_bank_id,field_counts,manifest_hash,armed}`。arm必须在任何不可逆publish前验证inactive authority header/count、manifest完整性、checked revision，以及Config/owners/Grid/Pool的battle/config identity。consumer closed后顺序固定为 `owner candidate reference swap(reversible)→matching Grid publish(point-of-no-return)→matching Pool publish→authority bank/header publish→close lease/quarantine→Input/GameRoot activation`；后三次matching publish在arm后均不可失败。点后invalidation仍用保存plan完成三publish再fault。

第八轮 tick 边界覆盖：GameRoot 每个 Active tick 在 phase1 读取 `completed_before_tick`，定义 `executing_tick_ordinal=completed_before_tick+1`；phase7 结算并写 `completed_after_tick`。Boss due=43200 由 executing ordinal 命中，phase7 survival 累加后同 tick Victory 的 `survival_ticks=43200` 合法。

### R4 — 唯一 Active tick

| Order | Phase | 行为 | publish point |
|---:|---|---|---|
| 1 | `SPAWN_INTENT` | SpawnDirector以上一tick已发布Player位置生成offscreen-ring spawn；执行已latch spawn/fresh insert/cancel | 无 |
| 2 | `MOVEMENT_COMMIT` | Input carrier→Player/Enemy committed position；matching Player motion publish后Stage camera/ground presentation跟随 | Player owner-local motion selector；camera非authority |
| 3 | `GRID_SYNC` | `SpatialGrid.sync` | sync=`OK` 发布 Grid snapshot |
| 4 | `QUERY` | consumer 写 caller-owned query buffers | 无 |
| 5 | `QUERY_CONSUME` | resolve+narrowphase→inactive resolution；matching publish后执行无副作用terminal precollection | matching end=`OK` 后发布resolution与matching immutable precollection |
| 6 | `DEFERRED_REMOVAL` | damage/death/pickup/remove→release；只消费matching precollection | journal/fact逐步exact-once；visible committed row为0则0 publish，>0则matching end或fault convergence恰一次batch publish |
| 7 | `POST_DEFERRED_BARRIER` | metrics、seal已预收集terminal/phase6 disposition、处理pause | matching end生成next tick pair；禁止首次发现VICTORY/FATAL |

每phase固定 `begin→RequiredPhaseCoverageManifest指定的RequiredParticipantManifest稳定行→指定RequiredServiceFaultManifest枚举行→matching end`。仅该phase required participant/service集合均非空、每行exactly-once、全部status属于manifest success class、matching end=`OK`且无service fault才进入下一phase；缺失在load失败，不能在tick内当空集处理。

phase failure只丢弃当前phase尚未提交的staging并阻止未来phase；此前phase已经成功发布的Grid/resolution/authority事实保持。phase 6 的journal/fact commit是显式例外：所有已推进的不可逆事实保留，并在consumer保持关闭时收敛到一次batch authority publish；不得伪造整tick/整phase rollback或逐step开放consumer。`PENDING_WORK`只允许来自pause barrier。

### R5 — Failure、rollback 与不可逆点

- query/resolve/fatal narrowphase failure 丢弃整个 query transaction；published bank不变，普通 no-hit 仍是 success。
- first failure保存R3固定schema；cleanup failure按注入顺序写suppressed槽，不覆盖root cause。
- pause/resume 中所有可失败 Grid/Pool/owner/authority/config validation 必须在 arm 完成。第一次 matching Grid publish 是不可逆点；matching Grid、Pool与authority publish均必须不可失败并用保存plan/tx收敛。
- 点前 failure 恢复 old owner、abort candidates/authority plan、关闭 lease；点后异常完成尚未完成的 Grid/Pool/authority matching publish、lease/quarantine cleanup，再进入 `CONTROLLED_FAULT`，禁止伪造双向 rollback。
- failure发生在phase 6/7且normal terminal尚未seal时，phase 5以及phase 6 lifecycle/fact ledger已COMMITTED的事实可进入TECHNICAL_ABORT；当前失败点之后的未提交staging不得进入。normal terminal已seal时保持原outcome_kind，仅写completion fault。

### R6 — Pause intent、reason queue、drain 与 pause-on

pause source固定为 `MANUAL/LEVEL_UP/TREASURE_CHOICE/RISK_CHOICE/APP_BACKGROUND/INPUT_GEOMETRY_CHANGED`。GameRoot持有预分配pending-reason队列，每项含 `{reason,priority,intent_sequence,owner_intent_id,completed_or_acked}`；排序为 `priority DESC→intent_sequence ASC`。容量由Config冻结的 `MAX_PENDING_BLOCKING_CHOICES` 派生：`MAX_PENDING_REASONS=3+MAX_PENDING_BLOCKING_CHOICES`，三项singleton为MANUAL/APP_BACKGROUND/INPUT_GEOMETRY_CHANGED。singleton按reason合并；background/geometry只保留latest required revision；choice按唯一owner intent ID排队且不得覆盖。capacity不足、重复choice ID或`intent_sequence` checked耗尽返回`CAPACITY_EXCEEDED/INVALID_ARGUMENT/ID_EXHAUSTED`并进入fault，禁止静默丢弃或扩容。

Active中的主动退出请求不直接显示可交互确认框：先设置 `manual_exit_pending=true` 并复用 `MANUAL` pause reason，完成相同安全barrier、Input lock与pause-on后才在BATTLE_PAUSED显示 destructive confirmation。确认产生 `ABANDONED`；取消只清 `manual_exit_pending`，保持普通MANUAL暂停，玩家再按Continue恢复。确认框存在期间 gameplay effect=0、底层摇杆/choice命中=0。

优先级为 `BATTLE_END > BLOCKING_CHOICE > APP_BACKGROUND > INPUT_GEOMETRY_CHANGED > MANUAL`。presentation每次只显示队首原因，但其他reason不得丢失。`resume_requested_latched` 是GameRoot拥有的唯一幂等resume intent：choice-only/geometry-only在完成全部前置条件后自动置true；含MANUAL或APP_BACKGROUND时仅合法Continue/readiness可置true；点前rollback与held保留，ACTIVE成功、Ending或Fault cleanup才清除。`can_start_resume`必须同时要求该latch为true、全部choice完成、manual已确认、latest background revision已ack、geometry已处理、Input clean且held=false。

barrier顺序：`collect/sort intent→Input cancel→Grid request_pause→matching end→Pool quarantine→Input FROZEN publish→SceneTree.set_pause(true)→readback true→GameRoot BATTLE_PAUSED commit→pause UI publish`。

`PENDING_WORK`允许恰一个下一次physics callback中的零gameplay-dt drain tick。Config冻结实际 `PauseDrainClosureTypeManifestV1`，行schema为`{row_id,closure_kind,owner_role_id,allowed_source_commit_states,authority_visible,stable_order}`，恰为三行：`PDC01/CANCEL/GAME_ROOT/{PENDING}/0/1`、`PDC02/FINALIZE_POOL_RELEASE/POOL/{GRID_REMOVED,POOL_UNBOUND}/1/2`、`PDC03/CLOSE_LEASE/SPATIAL_GRID/{OPEN,CLOSE_PENDING}/0/3`；不得增加类型或由fixture生成。`FINALIZE_POOL_RELEASE`对一个LifecycleCommitJournal row只算一个closure，并从当前最高公开state exact-once推进至`POOL_RELEASED`或`POOL_RETIRED`；内部unbind/reset/free-stack checkpoint不得再消耗第二个closure。另冻结实际 `FixedPauseClosureCapacityContributionManifestV1` 两行：`FPCC01/GAME_ROOT/CANCEL/1/role_order=1/kind_order=1`、`FPCC02/SPATIAL_GRID/CLOSE_LEASE/1/role_order=12/kind_order=3`。最终容量严格为`checked_sum(required owner PAUSE_CLOSURE rows)+checked_sum(FPCC01..02)`，不得与`MAX_LIFECYCLE_INTENTS_PER_TICK`直接比较；schema上限独立校验。`request_pause=PENDING_WORK`返回前，GameRoot在预分配 `PauseDrainClosureSet` 中冻结动态行 `{closure_id,closure_kind,source_tick_revision,source_lifecycle_sequence,source_lease_id,source_commit_state,pause_request_tick_revision}`；每行必须引用pause锁定反馈发布前已经存在且已获准收敛的journal row或lease，`source_tick_revision<=pause_request_tick_revision`，不得引用新fact、fresh intent或锁定后创建的row。

进入Pending时置`pause_drain_consumed=false`；Pending callback原子置true后仍留下七phase matching trace，但只允许按上述set完成closure。closure可推进其既有lifecycle row并按`Phase6AuthorityBatchPlanV1`使authority delta精确非零，但不得创建新的gameplay fact、奖励、伤害、死亡或可见spawn/remove意图；因此锁定反馈后的变化只兑现pause前已提交/已启动的技术收敛事实。除此之外fresh borrow、spawn/query/narrowphase/damage/pickup/reward、movement、gameplay timer与新intent均为0，其他participant返回`OK_NOOP`。缺失/额外/重复closure ID、source revision/row不匹配或非manifest kind均进入fault。drain不推进`tick_revision/survival_ticks`；drain末尾再次`request_pause`必须为OK。第二次pending、第二个Pending callback或任一failure进入ControlledFault。

| Reason | 标题/短提示 | 完成条件 |
|---|---|---|
| `MANUAL` | “试炼暂停” | Continue确认 |
| `LEVEL_UP` | “境界提升：选择一项” | choice exact-once完成 |
| `TREASURE_CHOICE` | “法宝机缘：选择一项” | choice exact-once完成 |
| `RISK_CHOICE` | “机缘抉择：选择一项” | choice exact-once完成 |
| `APP_BACKGROUND` | “已安全暂停，准备好后继续” | latest background revision确认 |
| `INPUT_GEOMETRY_CHANGED` | “界面已调整” | geometry处理完成；无manual/background时可自动 |

所有可交互Control（choice、Continue、退出确认、Save/reconcile/discard、reservation恢复）在press前读取各自typed blocked predicate。若拒绝，intent=0；本blocked episode首个拒绝press在被按控件邻近位置显示一次具体原因（held时“请先松开移动手指”，gate/recovery未就绪时显示对应状态），后续不重复，predicate恢复false时清除。键盘、手柄、触控必须共享同一episode与反馈计数，不能只覆盖choice按钮。

### R7 — Paused control pump 与 resume checkpoints

- 每个 `BATTLE_PAUSED/RESUME_PREPARING` control-pump iteration固定执行：`service_pending_input_fault→读取typed input/background/geometry revisions→更新pending reason completion/ack→检查choice/held→若can_start_resume且无attempt则启动/继续attempt`。任一async fault不得等玩家再次点击才被观察。
- `PAUSE_READ`只读lease必须matching end，且不得与`RESUME_EXCLUSIVE`重叠。choice mutation只写inactive authority bank；frozen/removed Node保持quarantine。
- 每个attempt只捕获一次 `{battle_instance_id,config_snapshot_id,input_rebuild_revision,background_required_revision,background_acked_revision,geometry_revision,pool_binding_consumer_checkpoint,source_authority_revision,next_authority_revision,source_grid_snapshot_revision,next_grid_snapshot_revision,pool_epoch,topology_revision,resume_requested_latched}`。`pool_binding_consumer_checkpoint`只能取`CLOSED`或`POOL_BINDING_CONSUMER_OPEN`，后者仅证明Pool binding/quarantine已收敛，不开放gameplay或Viewport physical input。逐checkpoint expected tuple固定为：prepare/arm/首次publish前=`{g,p,CLOSED,a}`；matching Grid publish后=`{g_next,p,CLOSED,a}`；matching Pool publish后=`{g_next,p,CLOSED,a}`且Pool transaction state为PUBLISHED；matching authority publish后=`{g_next,p,POOL_BINDING_CONSUMER_OPEN,a_next}`。任何额外revision变化才是invalidation，不能把合法`g→g_next`误判为fault。Grid prepare前、各arm前、三次publish之间、cleanup后、held-drain每iteration、unpause返回后、Input ACTIVE前和root Window release前还逐项readback Config/owners/Grid/Pool identity、Engine 60Hz/time_scale及BattleViewportTopologyManifest。
- 固定事务：`resume_requested_latched gate→Input RESUME_LOCKED/cancel→optional rebuild→Grid resume_from→Pool prepare→AuthorityResumeCommitPlan prepare→Grid arm→Pool arm(final Node/capacity check)→authority plan arm→owner candidate swap→matching Grid publish→matching Pool publish→matching authority publish→end/quarantine cleanup→root Window PRE_ACQUIRE/SET_TRUE_IN_FLIGHT/GATE_HELD→set_pause(false) return→GameRoot explicit observer→Input ACTIVE→GameRoot ACTIVE并清resume latch→ACTIVATION_SUCCESS release`。
- 首次matching publish前发现revision/invalidation/held：fault-free恢复old owner、abort candidates/authority plan、matching close lease、Input回FROZEN、保持SceneTree paused并回`BATTLE_PAUSED`，且保留`resume_requested_latched`。首次publish后发现invalidation/failure：用保存plan/tx完成Grid/Pool/authority三publish与cleanup后fault，禁止rollback。
- 首次publish后仅出现合法held touch时，顶层仍为 `RESUME_PREPARING`，substate=`RESUME_HELD_DRAIN`；candidate/authority plan/lease/quarantine必须为0，SceneTree保持paused，UI一次显示“请松开移动手指以继续”。terminal后因latch仍true自动重跑ACTIVE尾段，不重跑Grid/Pool/authority transaction。
- `set_pause(false)`返回后显式observer若发现held-only，先由唯一pause helper重新`set_pause(true)`并readback，再回held-drain；若发现fault/invalidation则保持root Window input gate与consumer closed并走fault。

### R8 — Battle end、immutable outcome 与 commit identity

`outcome_kind`冻结为 `VICTORY/DEFEAT/ABANDONED/TECHNICAL_ABORT`。FATAL/VICTORY/PAUSE contender必须在phase5后terminal precollection中对matching resolution token冻结；phase6可追加DEFEAT或非终局REVIVE disposition，phase7只把同一precollection token与phase6 committed disposition seal为最终结果。唯一总序仍为`FATAL_FAILURE > VICTORY > DEFEAT > ABANDONED > PAUSE`；victory与death同barrier时VICTORY优先，`victory+death+fatal`固定为TECHNICAL_ABORT，且不得由participant调用顺序决定。任何phase7首次出现的FATAL/VICTORY视为producer coverage contract failure，不能回头消费/恢复替身符。Active manual exit必须先按R6安全暂停，Pausing/Paused confirmation才可产生ABANDONED。manual confirm必须明确显示“本局奖励、纪录与教程进度均不结算，已消耗的开局准备资源不补偿”。

terminal precollection与phase6仲裁还生成与同一`batch_authority_revision`绑定的player-facing presentation projection。`VICTORY+lethal`保留DAMAGE/DEATH committed facts、HP=0、`DEATH_LATCHED`与death cause供统计/结算，但唯一`presentation_winner=VICTORY`；Player event bank不得发布HIT/DEATH/REVIVE事件，BattleUI/visual/audio不得显示死亡pose、死亡重音、DEFEAT或pause UI。required consumer精确采用Player GDD的三行`PlayerPresentationConsumerManifestV1`与`required_ack_mask=0b111`；所有consumer须先通过reader把同revision已发布motion+HUD逐字段copy-out为Player frame，再联结precollection winner并读或以其stable-order bit exact-once ack事件；跨revision/frame无效时不得ack，未全ACK不得覆盖对应transient/critical row。表现抑制不反向删除runtime facts。

Player presentation transport固定为容量1的transient DAMAGE A/B bank与容量2的retained critical ledger（REVIVE、terminal DEATH各至多一条）。每个注册consumer在下一次transient publish前必须ack；critical row在全部consumer ACKED前不得覆盖。REVIVE+pause时presentation host仍为PAUSABLE且无独立process callback，仅由既有persistent GameRoot ALWAYS control pump显式调用typed presentation-only advance；它不写gameplay authority，pause overlay同步显示已提交HP/符/safety，完成后才ack。未ack覆盖、critical overflow或未先join matching winner/frame即ack均进入battle fault。MOVE音频只从连续frame边沿派生，不占fact/event sequence。

`TerminalPriorityGoldenV1`与实现判定代码独立，bit固定`FATAL=16,VICTORY=8,DEFEAT=4,ABANDONED=2,PAUSE=1`，行schema为`{row_id,stable_order,input_mask,expected_winner}`。以下31行是canonical artifact，stable_order等于mask：

| rows | input_mask（十进制） | expected_winner |
|---|---|---|
| `TP01` | 1 | `PAUSE` |
| `TP02`,`TP03` | 2,3 | `ABANDONED`,`ABANDONED` |
| `TP04`,`TP05`,`TP06`,`TP07` | 4,5,6,7 | `DEFEAT`,`DEFEAT`,`DEFEAT`,`DEFEAT` |
| `TP08`,`TP09`,`TP10`,`TP11` | 8,9,10,11 | `VICTORY`,`VICTORY`,`VICTORY`,`VICTORY` |
| `TP12`,`TP13`,`TP14`,`TP15` | 12,13,14,15 | `VICTORY`,`VICTORY`,`VICTORY`,`VICTORY` |
| `TP16`,`TP17`,`TP18`,`TP19` | 16,17,18,19 | `FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE` |
| `TP20`,`TP21`,`TP22`,`TP23` | 20,21,22,23 | `FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE` |
| `TP24`,`TP25`,`TP26`,`TP27` | 24,25,26,27 | `FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE` |
| `TP28`,`TP29`,`TP30`,`TP31` | 28,29,30,31 | `FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE`,`FATAL_FAILURE` |

每个逗号分隔项是一条独立row并逐项进入canonical hash；fixture只能引用单个row_id，禁止调用production priority函数生成expected winner。

GameRoot在teardown前从已提交authority/fact ledger **construct+seal** 一次immutable、versioned `RunOutcomeEnvelopeV1`；BATTLE_RULES只提交terminal intent，最终`outcome_kind`由GameRoot按priority oracle产生。完成cleanup、pause-off且旧battle Node物理失效后才将sealed envelope **expose** 给Settlement/Save。construct、seal、expose是三个不同checkpoint，禁止把cleanup后的expose误写为teardown后回读owner。

completion不修改immutable envelope。`RunCompletionStatusV1={schema_version:int32=1,state:int32,completion_fault_code:int32,outcome_commit_id:int64}` backing在BOOT预留；`state={CLEANUP_PENDING=1,CLEANUP_SUCCEEDED=2,CLEANUP_FAULTED=3}`，0为INVALID。只有终局commit ID原子绑定成功后才以同一ID初始化为PENDING；cleanup期间first-fault-wins写code，cleanup DAG、pause-off、frame barrier与destination stage完成后单调seal。`BOUND`路径通过`OUTCOME_CLEANUP_FINISHED/CLEANUP_FINISHED`与sealed envelope一同expose；`IDENTITY_UNAVAILABLE`路径不初始化它，改用PreOutcome cleanup state。Save failure只进入`SaveCommitAttempt`，不反向修改Envelope或已sealed completion status。

`RunOutcomeEnvelopeV1` 明确拆分 runtime carrier 与 wire codec。GDScript runtime中的所有scalar `int`按64-bit承载；标记为int32的字段在写入carrier及encode前都必须检查`INT32_MIN..INT32_MAX`，不得依赖窄化wrap。封闭enum数值固定为：`OutcomeKind={INVALID=0,VICTORY=1,DEFEAT=2,ABANDONED=3,TECHNICAL_ABORT=4}`；`ReservationDisposition={INVALID=0,CONSUME=1,NONE_NO_COMPENSATION=2,TECHNICAL_COMPENSATION=3}`。`death_cause_code:int32`与`technical_failure_code:int32`的0均为NONE，正值由各自owner manifest冻结且不可复用/别名。

V1 canonical scalar顺序固定为：`schema_version:int32=1,outcome_kind:int32,reservation_disposition:int32,death_cause_code:int32,technical_failure_code:int32,outcome_commit_id:int64,battle_instance_id:int64,reservation_id:int64,run_seed:int64,config_snapshot_id:int64,authority_revision:int64,survival_ticks:int64,level:int64,producer_completeness_bits:int64,technical_diagnostic_id:int64,death_source_id:int64,committed_kill_type_count:int64,skill_damage_count:int64,damage_source_count:int64,risk_choice_count:int64,reward_fact_count:int64,record_count:int64`。不得使用`*_count`通配符生成字段；上述名字就是唯一field ID。

Config冻结容量的 SoA runtime ABI 与canonical顺序固定为：`committed_kill_type_ids:int64`、`committed_kill_counts:int64`、`skill_ids:int64`、`skill_damage_totals:float64`、`damage_source_ids:int64`、`source_damage_totals:float64`、`risk_choice_ids:int64`、`risk_choice_results:int32`、`reward_fact_ids:int64`、`reward_amounts:int64`、`record_ids:int64`、`record_candidate_values:float64`。每个数组只encode对应count的`[0,count)`；count必须非负且`count<=capacity<=schema_hard_max`。整数aggregation checked，overflow使seal失败并进入fault。float64必须finite，canonicalization先把`-0.0`归一为`+0.0`，NaN/±INF拒绝；同一stable ID允许多条fact时必须按`(stable_id ASC,fact_sequence ASC)`进行不并行、不重排、禁止FMA的逐项float64加法，输出再规范化`-0`，不得仅按容器遍历顺序归约。DEFEAT必须携带非零`death_cause_code`与可为0的`death_source_id`（环境/未知稳定来源为0）；其他outcome两字段均为0。

wire codec固定little-endian、无padding：先按上述scalar顺序encode，再按上述12个SoA顺序encode。`offset(field_0)=0`，`offset(field_i)=offset(field_{i-1})+encoded_size(field_{i-1})`；int32=4 bytes、int64/float64=8 bytes、SoA `encoded_size=count*element_size`，所有乘加checked。禁止Dictionary、String、Node/Resource引用、共享Array/PackedArray backing或teardown后回读owner；同一sealed字段快照必须byte-identical。codec schema/version/hash与最终byte length进入验收artifact。

`producer_completeness_bits`只使用低8位：bit0=`CORE_IDENTITY`、bit1=`TERMINAL_FACTS`、bit2=`KILL_FACTS`、bit3=`SKILL_DAMAGE`、bit4=`SOURCE_DAMAGE_AND_DEATH_CAUSE`、bit5=`RISK_RESULTS`、bit6=`REWARD_FACTS`、bit7=`RECORD_CANDIDATES`，高位必须0。outcome mask固定`OM_VICTORY=1,OM_DEFEAT=2,OM_ABANDONED=4,OM_TECHNICAL=8`；组合`ALL=15,V_D_T=11,V_D=3`。`RunOutcomeProducerManifest`唯一权威就是下列34行，schema为 `{schema_version,field_id,primitive_type,producer_role_id,completeness_bit_index,mandatory_for_outcome_mask,capacity_source,schema_hard_max,stable_order}`；Config只复制并验证其canonical hash，不得另造第二张表：

| order | field_id | primitive | producer | bit | mask | capacity_source / hard_max |
|---:|---|---|---|---:|---:|---|
| 0 | `schema_version` | int32 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 1 | `outcome_kind` | int32 | GAME_ROOT | 1 | 15 | scalar / 1 |
| 2 | `reservation_disposition` | int32 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 3 | `death_cause_code` | int32 | DAMAGE | 4 | 11 | scalar / 1 |
| 4 | `technical_failure_code` | int32 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 5 | `outcome_commit_id` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 6 | `battle_instance_id` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 7 | `reservation_id` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 8 | `run_seed` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 9 | `config_snapshot_id` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 10 | `authority_revision` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 11 | `survival_ticks` | int64 | BATTLE_RULES | 1 | 15 | scalar / 1 |
| 12 | `level` | int64 | BATTLE_RULES | 1 | 15 | scalar / 1 |
| 13 | `producer_completeness_bits` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 14 | `technical_diagnostic_id` | int64 | GAME_ROOT | 0 | 15 | scalar / 1 |
| 15 | `death_source_id` | int64 | DAMAGE | 4 | 11 | scalar / 1 |
| 16 | `committed_kill_type_count` | int64 | ENEMY | 2 | 11 | scalar / 1 |
| 17 | `skill_damage_count` | int64 | DAMAGE | 3 | 11 | scalar / 1 |
| 18 | `damage_source_count` | int64 | DAMAGE | 4 | 11 | scalar / 1 |
| 19 | `risk_choice_count` | int64 | RISK_CHOICE | 5 | 3 | scalar / 1 |
| 20 | `reward_fact_count` | int64 | BATTLE_RULES | 6 | 11 | scalar / 1 |
| 21 | `record_count` | int64 | BATTLE_RULES | 7 | 3 | scalar / 1 |
| 22 | `committed_kill_type_ids` | int64[] | ENEMY | 2 | 11 | `OUTCOME_KILL_ROWS` / 1536 |
| 23 | `committed_kill_counts` | int64[] | ENEMY | 2 | 11 | `OUTCOME_KILL_ROWS` / 1536 |
| 24 | `skill_ids` | int64[] | DAMAGE | 3 | 11 | `OUTCOME_SKILL_ROWS` / 1536 |
| 25 | `skill_damage_totals` | float64[] | DAMAGE | 3 | 11 | `OUTCOME_SKILL_ROWS` / 1536 |
| 26 | `damage_source_ids` | int64[] | DAMAGE | 4 | 11 | `OUTCOME_DAMAGE_SOURCE_ROWS` / 1536 |
| 27 | `source_damage_totals` | float64[] | DAMAGE | 4 | 11 | `OUTCOME_DAMAGE_SOURCE_ROWS` / 1536 |
| 28 | `risk_choice_ids` | int64[] | RISK_CHOICE | 5 | 3 | `OUTCOME_RISK_ROWS` / 1536 |
| 29 | `risk_choice_results` | int32[] | RISK_CHOICE | 5 | 3 | `OUTCOME_RISK_ROWS` / 1536 |
| 30 | `reward_fact_ids` | int64[] | BATTLE_RULES | 6 | 11 | `OUTCOME_REWARD_ROWS` / 1536 |
| 31 | `reward_amounts` | int64[] | BATTLE_RULES | 6 | 11 | `OUTCOME_REWARD_ROWS` / 1536 |
| 32 | `record_ids` | int64[] | BATTLE_RULES | 7 | 3 | `OUTCOME_RECORD_ROWS` / 1536 |
| 33 | `record_candidate_values` | float64[] | BATTLE_RULES | 7 | 3 | `OUTCOME_RECORD_ROWS` / 1536 |

RISK_CHOICE actual producer capacity由`risk-choice-system.md`冻结为`risk_choice_count` scalar slot 1、`risk_choice_ids/results`各2；本表1536仅是schema hard max，Config不得据此过分配本地risk backing。结果enum固定为SAFE、及时击杀、迟杀、终局存活与技术故障五类。

每个outcome必须满足其mask覆盖的全部行，非mandatory组仍存在于carrier但count=0且bit=0；同组count scalar与两条SoA必须由同一producer transaction提交。缺行、重复field/order、类型/bit/mask/容量不匹配、同stable ID缺fact_sequence总序或mandatory bit未齐均不得seal，并继续令`battle_ready=false`。

`outcome_commit_id`在Ending/Fault gameplay停止后、任何normal/technical envelope seal前创建一次，是跨Save retry稳定的opaque identity；生成算法与跨进程持久化归Save ADR。ID allocation与BOOT backing binding是单一prepare/commit checkpoint，先validate全部字段，成功时同时置`outcome_binding_state=BOUND`、初始化Envelope/Completion/Save header；任一步失败时逻辑carrier创建数0。`ID_EXHAUSTED`固定置`outcome_binding_state=IDENTITY_UNAVAILABLE`，normal terminal保持unsealed并进入`CONTROLLED_FAULT(BATTLE)`；不得递归构造technical envelope，改以PreOutcome completion完成cleanup和safe exit，Outcome/Save attempt为0，fault UI显示“本局结果无法安全保存”。开局reservation在PREP以`reservation_id=battle_instance_id`建立；LOAD_ABORT_RETRYABLE exact-once release，LOAD_FAILED_UNCERTAIN才可进入technical compensation。Envelope seal时冻结一一映射`{reservation_id→outcome_commit_id,reservation_disposition}`；此前不得使用commit ID。technical字段与completion只保存复制后的稳定code/diagnostic ID，不引用待teardown bank。

GameRoot拥有facts envelope、source revision与producer completeness；各gameplay owner提供字段。Settlement/Save不得在teardown后读取battle Node或猜测重建。缺mandatory producer时不发布Settlement success，story保持BLOCKED。

保存状态不在immutable envelope内。Save coordinator按同一commit ID拥有versioned runtime carrier：`SaveCommitAttemptV1={schema_version:int32=1,state:int32,operation_kind:int32,in_flight:int32,outcome_commit_id:int64,attempt_count:int64,attempt_generation:int64,request_id:int64,receipt_id:int64,discard_tombstone_id:int64}`。封闭数值码为 `state={NOT_STARTED=0,SAVE_PENDING=1,SAVE_UNCERTAIN=2,SAVE_SUCCEEDED=3,SAVE_FAILED=4,DISCARD_PENDING=5,DISCARDED=6}`、`operation_kind={NONE=0,COMMIT=1,RECONCILE=2,DISCARD=3}`；`in_flight`只能0/1。`outcome_commit_id`在所有state非零且不变；其余ID以0表示尚不存在，不得笼统要求始终非零。

逐state canonical presence固定如下；`PRESERVE`表示与前一合法state逐位相同，`NZ`为非零，未列自由度一律不存在：

| state | operation_kind | in_flight | attempt_count / generation / request | receipt_id | tombstone_id |
|---|---|---:|---|---:|---:|
| `NOT_STARTED` | `NONE` | 0 | `0 / 0 / 0` | 0 | 0 |
| `SAVE_PENDING` | `COMMIT|RECONCILE` | 1 | `NZ / NZ / NZ` | 0 | 0 |
| `SAVE_UNCERTAIN` | `COMMIT|RECONCILE`（PRESERVE） | 0 | `PRESERVE / PRESERVE / PRESERVE` | 0 | 0 |
| `SAVE_FAILED` | `COMMIT` | 0 | `PRESERVE / PRESERVE / PRESERVE` | 0 | 0 |
| `SAVE_SUCCEEDED` | `COMMIT|RECONCILE`（最后durable success操作） | 0 | `PRESERVE / PRESERVE / PRESERVE` | `NZ` | 0 |
| `DISCARD_PENDING` | `DISCARD|RECONCILE` | `0|1` | `NZ / NZ / NZ` | 0 | `NZ`且PRESERVE |
| `DISCARDED` | `DISCARD|RECONCILE`（最后durable tombstone操作） | 0 | `PRESERVE / PRESERVE / PRESERVE` | `NZ`且PRESERVE | `NZ`且PRESERVE |

`outcome_commit_id`在全部state始终非零且不变。MVP唯一outcome callback carrier是Save GDD固定160-byte `TerminalRunResultV2`；`terminal_operation_kind={OUTCOME_COMMIT,OUTCOME_DISCARD,PREACTIVE_RELEASE,TECHNICAL_COMPENSATION,ORPHAN_CONSUME}`、`result_code=ReservationResultCodeV1`、`terminal_disposition={CONSUMED,RELEASED}`共同形成封闭判别，禁止继续使用`SaveOperationResultV1`或把旧`SaveOperationResultV2`作为MVP run result。fresh-live OUTCOME_COMMIT/OUTCOME_DISCARD success必须disposition=CONSUMED并携带matching profile/domain revision、transition 0/1及非零receipt ID/hash；PREACTIVE_RELEASE/TECHNICAL_COMPENSATION必须RELEASED；receipt ID逐位等于durable request ID。RECONCILE_FOUND只恢复原result且不签发fresh stamp。OUTCOME_DISCARD success可有matching非零tombstone，其他kind tombstone=0。unknown schema/enum、类型错误、非matching correlation或presence违反均为stale/invalid response，不改变carrier。每次外发前先validate全部字段、checked计算next count/generation并分配request/tombstone identity，全部成功后才一次提交新carrier并发送；任一耗尽/分配失败保持旧carrier byte-identical、`in_flight=0`，不得出现counter已推进而request缺失。

合法request边固定为：`NOT_STARTED|SAVE_FAILED→SAVE_PENDING(COMMIT)`、`SAVE_UNCERTAIN→SAVE_PENDING(RECONCILE|COMMIT)`、`SAVE_UNCERTAIN|SAVE_FAILED→DISCARD_PENDING`，以及`DISCARD_PENDING→DISCARD_PENDING(DISCARD|RECONCILE)`。这里COMMIT/DISCARD/RECONCILE都是对同一个durable `ReservationUpdateRequestV2(RESOLVE)` identity的投影，不产生第二类介质写。matching callback只由下列total reducer决定；`presence`写作`receipt/tombstone`，`P`为原值保持，`NZ`为matching非零值：

| source | terminal operation | result code / durable fact | target | presence | returned status |
|---|---|---|---|---|---|
| `SAVE_PENDING` | `OUTCOME_COMMIT` | `SUCCEEDED / CONSUMED` | `SAVE_SUCCEEDED` | `NZ/0` | `OK` |
| `SAVE_PENDING` | `OUTCOME_COMMIT` | `FAILED` | `SAVE_FAILED` | `0/0` | `OK` |
| `SAVE_PENDING` | `OUTCOME_COMMIT` | `UNCERTAIN` | `SAVE_UNCERTAIN` | `0/0` | `OK` |
| `SAVE_PENDING` | `OUTCOME_COMMIT` | `RECONCILE_FOUND / CONSUMED` | `SAVE_SUCCEEDED` | `NZ/0` | `OK` |
| `SAVE_PENDING` | `OUTCOME_DISCARD` | `RECONCILE_FOUND / CONSUMED` | `DISCARDED` | `NZ/NZ` | `OK` |
| `SAVE_PENDING` | `OUTCOME_COMMIT` | `RECONCILE_NOT_FOUND_UNPROVEN` | `SAVE_UNCERTAIN` | `0/0` | `OK` |
| `DISCARD_PENDING` | `OUTCOME_DISCARD` | `SUCCEEDED / CONSUMED` | `DISCARDED` | `NZ/NZ` | `OK` |
| `DISCARD_PENDING` | `OUTCOME_DISCARD` | `FAILED|UNCERTAIN` | `DISCARD_PENDING` | `0/P` | `OK`（`in_flight=0`） |
| `DISCARD_PENDING` | `OUTCOME_COMMIT` | `RECONCILE_FOUND / CONSUMED` | `SAVE_SUCCEEDED` | `NZ/0` | `OK` |
| `DISCARD_PENDING` | `OUTCOME_DISCARD` | `RECONCILE_FOUND / CONSUMED` | `DISCARDED` | `NZ/NZ` | `OK` |
| `DISCARD_PENDING` | `OUTCOME_DISCARD` | `RECONCILE_NOT_FOUND_UNPROVEN` | `DISCARD_PENDING` | `0/P` | `OK`（`in_flight=0`） |
| 任意 | 任意 | 其余组合、unknown或correlation/presence不匹配 | 原state | 原值 | `OK_NOOP` |

`RECONCILE_NOT_FOUND_UNPROVEN`语义冻结：它仅证明查询时未发现durable terminal fact，不证明先前写入失败；SAVE路径回`SAVE_UNCERTAIN`，discard路径保持`DISCARD_PENDING`并复用同一tombstone identity。timeout/lost callback使用同一目标语义。每个callback必须携带matching`{terminal_operation_kind,outcome_commit_id,reservation_id,attempt_generation,request_id}`；stale/duplicate callback为`OK_NOOP`。

timeout/lost callback不直接判永久失败，commit/reconcile进入SAVE_UNCERTAIN；discard保持可重试的DISCARD_PENDING。precedence按**持久化事实顺序**而非callback到达顺序：若commit success先持久化，即使receipt callback迟到，reconcile/tombstone响应也必须返回既有success并转SAVE_SUCCEEDED、不得写tombstone；若tombstone先持久化，则转DISCARDED，后续旧generation callback/commit request永远stale且后端不得再接受该commit。Settlement、CONTROLLED_FAULT(BATTLE)与HOME使用R2同一组retry/reconcile/discard self-transition，不得各自复制第二套状态机。具体跨进程介质/原子写算法归Save GDD，但该correlation、presence与precedence不得由实现另行决定。

`SAVE_SUCCEEDED/DISCARDED`是resolved但carrier仍可见的终态。app history唯一schema为`ResolvedRunArchiveV1={schema_version:int32=1,archive_sequence:int64,archive_entry_hash:int64,operation_id:int64,outcome_commit_id:int64,resolution_kind:int32,receipt_or_tombstone_id:int64,outcome_content_hash:int64,completion_content_hash:int64,save_carrier_hash:int64}`；canonical bytes含全部字段，append后必须按`operation_id+outcome_commit_id` readback逐字段相等，重复operation只能返回原entry不得追加。archive→retire由预分配`ArchiveRetireJournalV1={schema_version:int32=1,operation_id:int64,outcome_commit_id:int64,state:int32,checkpoint_id:int32,resolution_kind:int32,receipt_or_tombstone_id:int64,expected_retired_carrier_mask:int32,retired_carrier_bits:int32}`驱动；bit固定`OUTCOME=1,COMPLETION=2,SAVE=4,BATTLE_IDENTITY=8,PREOUTCOME_IDENTITY=16`，expected mask在PREPARED冻结，随后每个carrier物理消失后exact-once OR对应bit。封闭state为`PREPARED=1→ARCHIVE_COMMITTED=2→CARRIERS_RETIRED=3→COMPLETED=4`，只允许单调前进。`RETURN_HOME/RETRY_RUN/START_RUN`首次调用分配稳定operation_id并写PREPARED；复制archive并durable/readback一致后写ARCHIVE_COMMITTED；`retired_carrier_bits==expected_mask`且剩余carrier=0后写CARRIERS_RETIRED；验证`CARRIERS_RETIRED=true`后写COMPLETED并提交top-state。任一checkpoint失败返回`DEPENDENCY_FAILURE`、不倒退journal；重试复用operation_id，从首个未完成checkpoint继续。若故障发生在archive durable之后，禁止重复append；部分retire按bitset继续。unresolved state与reservation不确定的PreOutcome不得启动journal，继续阻止新局；跨进程介质归Save GDD。

**SaveSystem static propagation（2026-09-03）**：Save内部介质采用temp原子替换与同generation A/B双镜像；sealed Outcome/Completion、Save attempt与proposed after-image先形成durable `PendingOutcomeRecoveryV1`。BOOT hydrate若无resolution，将遗留`SAVE_PENDING(in_flight=1)`规范化为`SAVE_UNCERTAIN/in_flight=0`并PRESERVE关联字段，将`DISCARD_PENDING/in_flight=1`规范化为同state/in_flight=0并保留tombstone；找到resolution则直接恢复合法终态presence。outcome commit ID须在seal前由Save持久allocator reserve；逻辑timeout不取消物理writer，reconcile/discard排队且执行前重扫durable resolution。archive row自hash采用domain-separated zero-field preimage；标准BOUND resolved retire mask=31，跨process epoch只在archive/resolution/readback与空carrier registry验证后按固定bit序补齐物理消失证据。codec、平台排他锁/file+dir barrier/atomic replace与真机kill仍BLOCKED。

**Progression Tree static propagation（2026-09-03）**：Progression是HOME app-scope service、四类gameplay contribution均0。购买只在Save READY且无Outcome/Reservation/archive/profile-mutation unresolved时，通过独立`ProfileDomainMutationRequest/Recovery/ResultV1`串行CAS；不得伪造outcome ID或把UNCERTAIN当FAILED。下一局Config从同一durable profile revision投影青元attack/穿透、长春maxHP/低血charge与大衍crit/pickup/refresh；当前battle不热改。残页`PROVISIONAL-ECONOMY-V1`建议每5400 committed Active ticks 1页、cap8、ABANDONED=0且无胜利bonus；actual `CULTIVATION_PAGES=2` reward row现归BATTLE_RULES/Settlement签发，经济与runtime evidence仍BLOCKED。

**Zhangtian/Settlement/Home/Prep static propagation（2026-09-07）**：CONFIRM_RUN采用唯一`PrepConfirmCommandV1`并构造176-byte `ReservationCreateRequestV2`；Save同槽分配全部identity。聚气pre-active draw使用scratch RNG lease，只有offer/recovery双镜像durable后才发布cursor/revision，FAILED不消费权威cursor。MVP终局只允许`ReservationUpdateRequestV2(RESOLVE)+1112-byte ResolveReservationPayloadV3`一次写入奖励/tombstone、next profile、264-byte resolution并清live carrier，返回160-byte typed terminal result；第二Save commit为0。经济只承诺Victory random gross grant-rate，net flow另由服丹/NONE、胜率、局长与饱和模拟。Config保留append-only旧artifact；ADR由七个screen-state node profile、八行Meta UI Input、MPSC64→serial→SPSC与root-owned fault presenter闭合静态合同。所有generated/runtime/crash/device/full re-review证据仍OPEN，`battle_ready=false`。

第八轮传播覆盖上述历史段：当前 Save/ADR/Input 口径分别为 DurableReservationV2 1152 bytes、MPSC 68-byte native payload/6208 total、Meta UI 8 rows、ADR 101 node contracts（pause choice rows 与 reason rows 互斥）；RCO V2×RCC V2 生成132条 fixture。下述历史数值不作为实现输入。

玩家面/收益矩阵固定如下；具体数值仍由owner/Config提供：

| outcome | 标题分类 | 允许reward source | 纪录/教程 | reservation |
|---|---|---|---|---|
| `VICTORY` | 试炼成功 | 全部已提交胜利与局内事实 | eligible | 正常消费 |
| `DEFEAT` | 试炼失败 | 已提交击杀灵石、存活tick残页；仅`survival_ticks>=43,200`时追加Loading冻结的随机种子1枚 | 3项record候选；教程按owner规则 | 正常消费 |
| `ABANDONED` | 主动退出 | 零奖励bundle与tombstone | none | 同一durable事务强制消费；discard不得取消药丸成本 |
| `TECHNICAL_ABORT` | 试炼异常中断（非战败） | fault前已提交击杀/存活/拾取事实 + reservation技术补偿 | none | 按一一映射补偿 |

### R9 — ControlledGameplayFault、Save retry 与安全退出

- TECHNICAL_ABORT不写胜负、死亡原因、纪录或教程完成度；禁止fault tick未提交staging进入奖励。故障页主标题必须含“异常中断（非战败）”，战败/死亡原因/新纪录控件出现数为0。
- `UNAVAILABLE_PRE_CARRIER` 的Loading fault不是TECHNICAL_ABORT：只expose `PreOutcomeFaultCompletionV1`与“进入战局时发生异常，未生成战局结算”，奖励/死亡/纪录/Save控件均为0；reservation state若为RELEASED则可retire，若为RELEASE_PENDING/UNCERTAIN则保留identity、阻止新局并提供恢复CTA，不能伪造补偿。
- 部分奖励来源：灵石=reward-eligible已提交死亡；功法残页=已提交存活tick；种子在VICTORY总是采用Loading已冻结candidate，DEFEAT仅`survival_ticks>=43,200`采用，TECHNICAL_ABORT/ABANDONED不新增种子。MVP无三种种子的战场pickup。开局灵药reservation以battle identity建立并一一映射到同一outcome commit；retry不得重复补发或重复扣除。
- normal Settlement与fault UI都必须诚实显示 `NOT_STARTED/SAVE_PENDING/SAVE_UNCERTAIN/SAVE_SUCCEEDED/SAVE_FAILED/DISCARD_PENDING/DISCARDED`。`NOT_STARTED`固定显示“尚未开始保存”与唯一“开始保存”CTA，不显示retry/reconcile/discard或已到账文案；成功前“奖励已到账/已保存”出现数=0；失败/不确定按同一commit ID retry或reconcile。
- normal/fault safe exit都只在battle cleanup与pause-off完成后进入HOME。若commit仍PENDING/UNCERTAIN/FAILED/DISCARD_PENDING，最多一个immutable envelope+attempt保留于当前进程；HOME显示“本局进度尚未保存”，永久资源不可见为到账，`START_RUN/RETRY_RUN`返回`WRONG_STATE`。玩家只能按同一commit ID重试/reconcile，或二次确认discard并等待durable tombstone完成；关闭应用前必须警告可能丢失。Save作者GDD现已冻结durable pending carrier与双槽跨进程恢复合同；实际codec/平台durability/runtime integration仍BLOCKED。
- fault/Settlement/HOME pending UI的重复render/callback不得启动第二个并发commit；应用级任意时刻pending commit总数≤1、同一commit最多一个in-flight attempt。只有DISCARDED终态才保证旧generation callback stale且奖励永久不可见；SAVE_SUCCEEDED终态则显示唯一receipt。
- resolved终态退出/再挑战按R8 `ResolvedRunArchiveV1` exact-once archive→retire；archive失败不得清carrier或开放新局。pre-outcome unresolved identity、SAVE_PENDING/UNCERTAIN/FAILED/DISCARD_PENDING均不得通过`ARCHIVE_ENTRY_READY`；只有journal bitset完整且carrier为0才通过`CARRIERS_RETIRED`。

### R10 — Engine/Performance Evidence Gates

| Gate | Owner | Artifact / pass condition | Failure contingency |
|---|---|---|---|
| `GATE-OQ-INPUT` | InputSystem | Godot 4.7.1 callback/Window relay trace；真实 background/safe-area/orientation | 修订 Input GDD/relay，不由 GameRoot镜像 workaround |
| `GATE-OQ-VIEWPORT` | GameRoot+Input | set_disable_input与set_pause同步重入、reasoned release trace | redesign activation/pause observer |
| `GATE-OQ-ALLOC` | Performance | release artifact；allocator/container growth/COW/unexpected-allocation-capable-native-call四维observer各自paired baseline与独立positive control | native维须有冻结allowlist与捕获边界；任一维不可观察则该维与总gate=INCONCLUSIVE |
| `GATE-OQ-TIME` | Producer+Performance | min-spec、production manifest、timer、thermal、warmup/sample、percentile算法与p95/p99；每个玩家面span同时报`first_visible`与`first_interactive`：confirm→battle、pause intent→lock/choice、resume confirm→battle、end latch→settlement/fault；并显式报告`visible_to_interactive_delta` | 阈值未冻结保持OPEN，不发明数值；安全终端的interactive为N/A且必须注明 |
| `GATE-OQ-MEMORY` | Producer+Performance | min-spec上双authority/resolution、journal/reason/diagnostic/outcome carriers、Grid/Pool workspace与1191 Node的BATTLE_LOADING/peak RSS/heap报告 | 结构定容不等于memory PASS；预算未冻结保持OPEN |
| `GATE-OQ-STATIC` | QA | `project.godot`、GDUnit4、`tools/ci/static_guard_check.py` 实际存在且通过 | implementation-ready=false |

## Formulas

### F1 — Transaction commit

`admission_ready = global_required_participant_count>0 AND every_required_role_manifest_row_exactly_once AND global_service_manifest_rows_exactly_once{RNG,INPUT_ASYNC,SPATIAL_GRID,POOL} AND every_required_phase_has_nonempty_required_participant_rows AND every_required_phase_has_nonempty_required_service_rows AND every_required_row_allowed_phases_nonempty AND every_required_row_allowed_success_statuses_nonempty AND no_unknown_or_duplicate_row`

`transaction_success(phase) = admission_ready AND every_participant_row_in_phase_coverage_called_exactly_once AND every_service_id_in_phase_coverage_called_exactly_once AND phase in service_manifest[service_id].phase_scope AND all(status(ci) in participant_manifest[ci].allowed_success_statuses) AND matching_end==OK AND no_enumerated_service_fault`

`ci`域为当前phase的稳定participant行；global exact-once只描述load时四个service manifest row各出现一次，不等于每phase调用四个service。每phase只调用coverage列出的非空service subset且各一次。数学上空集 `all(empty)=true`，但任一required phase participant/service set为空显式令`admission_ready=false`并在load失败。optional-only phase不替代required coverage。success只发布当前transaction；failure保持当前transaction未提交目标bank identity/revision不变，前序phase及phase 6已提交的lifecycle/fact rows按R3 exact publish谓词收敛。

### F2 — Pause drain

ProjectSettings与Engine runtime均冻结 `physics_ticks_per_second=60`，并冻结 `Engine.time_scale=1.0`；BOOT/load/pre-tick/resume尾段readback，项目其他writer数0。`FIXED_GAMEPLAY_DT=1.0/60.0`。callback `physics_dt`不进入玩法乘法，只作telemetry；non-finite/non-positive、runtime tick-rate或time-scale漂移进入ControlledFault。其余rounding偏差只记录，不以未冻结tolerance制造fatal。`extra_pause_drain_ticks in {0,1}`；普通ACTIVE tick才有`gameplay_dt=FIXED_GAMEPLAY_DT`，Pending/Paused/Resume/Fault均为0，技术drain不推进tick/survival。

### F3 — Revision axes

- `tick_revision`：每局初值1；POST_DEFERRED_BARRIER成功checked `+1`。
- `grid_snapshot_revision`：Grid init为0；仅Grid sync/resume publish按其GDD递增。
- `authority_revision`：GameRoot init为0；每次authority publish checked `+1`。
- resolution token：精确绑定 `{battle_instance_id,bank_id,source_authority_revision,tick_revision}`。
- `config_snapshot_id`：Config snapshot identity，pause/resume不变。

任何int64 checked increment耗尽=`ID_EXHAUSTED`，不回绕。pause/resume不额外增加tick，但合法Paused authority mutation publish会增加authority revision。

### F4 — Pause ordering and resume predicate

`reason_order = sort(priority DESC,intent_sequence ASC)`。

`can_start_resume = resume_requested_latched AND all_choices_completed AND manual_confirmed_if_present AND background_acked==background_required AND geometry_clean AND input_clean AND held_count==0 AND no_service_fault`。

### F5 — Runtime metrics

测量类别封闭为`MeasurementClass={STEADY_ZERO_DELTA=1,COLD_MEASURE_ONLY=2,MEMORY_IO=3}`，采样单位封闭为`SampleUnit={PHYSICS_TICK=1,CONTROL_PUMP_ITERATION=2,COMPLETE_OPERATION=3}`。每个测量必须引用冻结并哈希的 `RuntimeWorkloadManifestV1={workload_id,measurement_class,config_hash,coverage_manifest_hash,authority_manifest_hash,owner_capacity_contribution_hash,native_call_allowlist_hash,seed,entity_layout_id,query_mix_id,sample_unit,ticks_per_sample,measured_driver_iterations,measured_tick_count,warmup_samples,measured_samples,independent_runs,expected_active_counts,expected_query_calls,expected_candidates,expected_results,expected_separation_pairs,expected_resolves,expected_journal_rows,expected_fact_rows,expected_authority_copy_count,expected_authority_elements_copied,expected_authority_publishes,expected_pause_pump_iterations,expected_closure_count,expected_reason_enqueues,expected_reason_coalesces,expected_held_drain_iterations,expected_resume_checkpoints,expected_load_resources,expected_teardown_resources,expected_save_requests,start_postcondition_id,end_postcondition_id}`。下表的fixture精确固定`active={player,enemy,projectile,drop}`，向量精确固定`{query,candidate,result,separation,resolve,journal,fact,copy,elements,publish,pump,closure,reason,coalesce,held,checkpoint,load,teardown,save}`；每次driver iteration均须等于该向量，不能按范围解释：

`SampleUnit`升级为V2并追加`RENDER_FRAME=4`；V1三值保持原编号。render-frame app-scope热路径不混入下方battle RW rows，而由独立`AppRootRenderWorkloadManifestV2`签发。

| workload | class / path | unit; ticks; driver/ticks | warmup / samples / runs | active | exact operation vector |
|---|---|---|---|---|---|
| `RW01` | `STEADY_ZERO_DELTA/FULL_SEVEN_PHASE` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{687,4096,2048,303,303,303,303,1,1536,1,0,0,0,0,0,0,0,0,0}` |
| `RW02` | `STEADY_ZERO_DELTA/PHASE6_VISIBLE_0` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,1,1536,0,0,0,0,0,0,0,0,0,0}` |
| `RW03` | `STEADY_ZERO_DELTA/PHASE6_VISIBLE_1` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,1,0,1,1536,1,0,0,0,0,0,0,0,0,0}` |
| `RW04` | `STEADY_ZERO_DELTA/PHASE6_VISIBLE_MAX` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,1536,1536,1,1536,1,0,0,0,0,0,0,0,0,0}` |
| `RW05` | `STEADY_ZERO_DELTA/AUTHORITY_FULL_COPY` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,1,1536,0,0,0,0,0,0,0,0,0,0}` |
| `RW06` | `STEADY_ZERO_DELTA/MAX_JOURNAL_FACT_CHURN` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,1536,1536,1,1536,1,0,0,0,0,0,0,0,0,0}` |
| `RW07` | `STEADY_ZERO_DELTA/PAUSED_IDLE_PUMP` | `CONTROL_PUMP_ITERATION;0;1000/0` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0}` |
| `RW08` | `STEADY_ZERO_DELTA/HELD_DRAIN` | `CONTROL_PUMP_ITERATION;0;1000/0` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,3,0,0,0}` |
| `RW09` | `STEADY_ZERO_DELTA/REASON_STORM` | `PHYSICS_TICK;1;1000/1000` | `120/1000/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,0,0,0,0,0,19,3,0,0,0,0,0}` |
| `RW10` | `COLD_MEASURE_ONLY/BATTLE_LOADING` | `COMPLETE_OPERATION;0;30/0` | `3/30/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,13,1191,0,0}` |
| `RW11` | `COLD_MEASURE_ONLY/BATTLE_TEARDOWN` | `COMPLETE_OPERATION;0;30/0` | `3/30/3` | `{1,303,384,503}` | `{0,0,0,0,0,0,0,0,0,0,0,305,0,0,0,8,0,1191,0}` |
| `RW12` | `MEMORY_IO/SAVE_COMMIT_RECONCILE` | `COMPLETE_OPERATION;0;30/0` | `3/30/3` | `{0,0,0,0}` | `{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2}` |

`AppRootRenderWorkloadManifestV2={row_id,stable_order,top_state,sample_unit=RENDER_FRAME,service_mailbox_rows,adapter_mailbox_rows,matching_rows,stale_rows,duplicate_rows,expected_service_drains=1,expected_adapter_drains=1,expected_typed_commands,expected_allocator_events=0,expected_allocator_bytes=0,expected_container_growth=0,expected_cow=0,start_postcondition_id,end_postcondition_id}`固定五行：

| row | state / input | expected |
|---|---|---|
| `ARRW01_EMPTY` | `HOME;service=0;adapter=0` | drains=`1/1`; commands0 |
| `ARRW02_SAVE_BURST` | `SETTLEMENT;service=2(one matching,one stale);adapter=0` | drains=`1/1`; matching reducer1; commands0 |
| `ARRW03_A11Y_BURST` | `PREP;service=0;adapter=32(16 matching,8 stale,8 duplicate)` | drains=`1/1`; typed commands16 |
| `ARRW04_PREACTIVE_A11Y` | `PRE_ACTIVE_CHOICE;service=0;adapter=32(16 matching,8 stale,8 duplicate)` | drains=`1/1`; typed Draft commands16 |
| `ARRW05_NO_SNAPSHOT_DRAIN` | `BATTLE_ACTIVE;service=0;adapter=32(all stale/disabled)` | drains=`1/1`; typed commands0; queue ends empty |

每行预热120 frame、测量1000 frame、3个独立run；记录main-thread p50/p95/p99/max、allocator events/bytes、growth、COW与queue high-water。33-row overflow是独立positive control：有active snapshot时必须置overflow sticky、typed command0并使页面noninteractive；无snapshot时同样锁存diagnostic且drain旧行。所有TopState `expected_adapter_drains=1`，任何state积压跨页面action均为FAIL。

**`BLOCKED-WORKLOAD-REGEN`**：RW01..11当前active向量中的`384 PROJECTILE/503 DROP`与已冻结的`400 PROJECTILE active`、`300 DROP active/320 pool/300 Grid`冲突，因此整张workload表当前只能视为stale fixture，不具production hash，Config admission必须拒绝。必须从owner上界重新生成active向量、operation向量、authority count与hash；禁止只把503替为300。表中的1191仍只是六个Pool configured capacity之和，不能继续解释为active gameplay对象数。

`AuthorityCopyManifest`字段count的checked sum在Config构建时必须等于重生成表内值，否则对应row不是production manifest而是`INCONCLUSIVE`；active总数必须逐类相等，不以总和替代。`RW11 closure`也必须随owner贡献与新fixture整体重算。每行start/end postcondition仍冻结：RW01..06/09=`PHASE_BEGIN/POST_DEFERRED_BARRIER_COMMITTED`，RW07=`PAUSED_PUMP_BEGIN/PAUSED_PUMP_IDLE`，RW08=`HELD_DRAIN_BEGIN/HELD_DRAIN_ITERATION_COMMITTED`，RW10=`LOAD_REQUEST_ACCEPTED/BATTLE_ACTIVE_INTERACTIVE`，RW11=`ENDING_LATCHED/DESTINATION_ACTIVE_OR_SAFE_TERMINAL`，RW12=`SAVE_COMMIT_SENT/RECONCILE_TERMINAL`。

`PlayerRuntimeWorkloadSupplementV1`是RuntimeWorkloadManifest的Config-hashed子artifact，实际四行`PWM01_PLAYER_STEADY_MOVEMENT/PWM02_PLAYER_DAMAGE_BATCH/PWM03_PLAYER_REVIVE_MAX/PWM04_PLAYER_RECOVERY_ONLY`逐字段采用Player GDD定义并分别绑定parent RW01。PWM01/02/04必须在相同1191-active fixture测量；PWM03同时包含Player isolated COMPLETE_OPERATION与叠加RW01 active counts的full-integration结果。hazard count `H`未由唯一owner展开前PWM03不具production hash、`battle_ready=false`。所有Player STEADY row逐run要求`allocator_events/allocator_bytes/container_growth/cow/unexpected allocation-capable native calls`分别为0，不接受净分配抵消。

结果记录 `{artifact_id,artifact_hash,raw_sample_artifact_hash,workload_manifest_hash,config_content_hash,participant_manifest_hash,authority_manifest_hash,owner_capacity_contribution_hash,native_call_allowlist_hash,device_manifest,clock_id,time_unit,observer_name,observer_version,measurement_class,workload_id,baseline_id,sample_unit,ticks_per_sample,measured_driver_iterations,measured_tick_count,start_marker_id,end_marker_id,timer_resolution,thermal_state,warmup_samples,measured_samples,independent_runs,all_runs_pass_rule,percentile_method,p50,p95,p99,max,authority_copy_count,authority_elements_copied,journal_rows_committed,fact_rows_committed,query_calls,candidate_count,result_count,separation_pair_count,resolve_count,pause_pump_iterations,closure_count,reason_enqueue_count,reason_coalesce_count,held_drain_iterations,resume_checkpoint_count,load_resource_count,teardown_resource_count,save_request_count,allocator_events,allocator_bytes,container_growth_events,cow_events,unexpected_allocation_capable_native_calls,peak_rss_bytes}`。`NativeAllocationCallAllowlistV1={row_id,stable_order,symbol,library_build_id,allowed_measurement_classes,expected_call_count}`在采样前hash冻结；steady表默认allowlist为空，任一native allocation-capable symbol调用即unexpected，cold/memory只能使用实际列出的精确call count。observer必须在start marker写入后、首个被测调用前清零counter，在end postcondition成立后、任何UI/log分配前封存；start/end marker各exactly once。

只有`STEADY_ZERO_DELTA`要求allocator/container growth/COW/unexpected-allocation-capable-native-call四维逐run delta=0并各有单维positive control；`COLD_MEASURE_ONLY`只报告时间、资源counter与allocation观测值，不断言零；`MEMORY_IO`报告I/O/Save latency、request与memory指标，也不断言零。每个sample耗时=`end_timestamp-start_timestamp`，每run percentile由该run的1000或30个sample按nearest-rank计算；跨run gate要求三run各自通过，禁止先合并样本。paired baseline除唯一positive-control维度外输入相同且该维delta>0。要求timer_resolution finite且positive、counter为非负checked integer、`0<=p50<=p95<=p99<=max<INF`。缺artifact/raw samples/marker/allowlist hash/required positive control/observer/production manifest，或向量任一字段不匹配时=`INCONCLUSIVE`。desktop结果只能`SPIKE_ONLY`。

### F6 — Diagnostic capacity

对数学上的suppressed尝试总数 `A∈ℕ` 与固定容量 `C:int64=MAX_SUPPRESSED_DIAGNOSTICS`，要求`1<=C<=MAX_SUPPRESSED_DIAGNOSTICS_SCHEMA`：

`suppressed_attempt_count=min(A,INT64_MAX)`；`stored_suppressed=min(A,C)`；`suppressed_overflow_count=min(max(0,A-C),INT64_MAX)`；attempt与overflow分别以saturating increment实现，任一达到INT64_MAX后保持不变并置唯一flag `diagnostic_counter_saturated=true`。

FailureDiagnosticBank header固定 `{schema_version:int32=1,capacity:int64,suppressed_attempt_count:int64,stored_suppressed:int64,suppressed_overflow_count:int64,diagnostic_counter_saturated:int32}`；first槽保持首次值，前 `min(A,C)` 条按注入顺序保存；attempt/stored/overflow三个counter口径独立，bank identity与size始终不变。

## Edge Cases

1. pause与death/victory/fatal同tick：按`FATAL>VICTORY>DEFEAT>ABANDONED>PAUSE`仲裁，不展示choice UI；无fatal时victory与death同barrier为VICTORY；normal terminal seal后fatal只写completion fault。
2. pause request立即OK：跳过PAUSE_PENDING，完成Pool/Input/pause-on后直接BATTLE_PAUSED。
3. drain后仍PENDING：ControlledFault；不执行第二个drain。
4. phase 6/7 failure：保留phase 3/5及phase 6所有已提交lifecycle/fact rows，只丢失败点之后未执行side effect与未提交staging；visible committed row=0时0 authority publish，>0时fault convergence恰一次publish。
5. cross-battle或错bank resolution token：消费0、进入fault；不得碰旧bank。
6. same-tick多choice：按intent sequence逐个展示，每个effect exact-once。
7. manual+choice/background：choice完成不自动resume，直到manual/background条件也满足。
8. resume首次publish前新revision/held：rollback至Paused；点后invalidation收敛后fault，点后held进入substate drain。
9. fault UI spam：应用级pending commit总数≤1、同commit ID最多一个in-flight Save attempt；callback须matching generation/request。
10. Save callback丢失/失败后safe exit：HOME显示unsaved pending/uncertain，不显示已到账；新局被阻止；discard tombstone callback丢失保持同ID的DISCARD_PENDING，可在Settlement/Fault/HOME retry或reconcile，durable终态前警告。
11. Stage camera missing/disabled/wrong root Window/Host或VJ Viewport错配/竞争active camera：Grid/Input init调用数0，load cleanup收敛。
12. Load cleanup只跳过未创建资源，不改变DAG中已创建资源的依赖顺序。
13. paused下hostile gameplay signal或pause/unpause `_notification`：callback只可写allowlist control/invalidation/diagnostic latch；暂停及resume后首个完整tick的未批准权威effect均为0。
14. reason queue capacity+1或intent sequence耗尽：不扩容、不覆盖旧reason，进入ControlledFault。
15. load后camera make_current/reparent/nested Viewport或Engine time_scale/tick-rate漂移：resume/Active开放为0，记录root fault并收敛cleanup。
16. cleanup预期detach Host/Shield/VJ/BattleUI：停止旧Battle manifest相等性比较，改验CleanupViewportHandoffManifest；不得把合法handoff报成runtime topology drift或在旧UI仍可命中时release gate。
17. Config/Outcome carrier ready前Loading uncertain fault：只生成pre-outcome completion；FINISHED self-edge后可见但Outcome/Save为0，不得卡在未列转换。
18. normal Ending/Fault cleanup开始时gate已释放：执行`PRE_ACQUIRE`恰一次；已持gate路径复用，acquire失败路径先撤销旧writer并以inert staged UI收敛，最终激活仍等待frame barrier/expose/top-state commit。
19. SAVE_SUCCEEDED/DISCARDED carrier仍存在时START/RETRY：先archive→retire再开局；archive失败保持原state与carrier，返回DEPENDENCY_FAILURE。

## Dependencies

| Dependency | GameRoot 使用方式 | Design state / gate |
|---|---|---|
| Godot 4.7.1 | SceneTree、Viewport、Window lifecycle | engine evidence OPEN |
| Config/Data | battle-ready snapshot、run_seed、`snapshot_id/config_snapshot_id`同义identity | GDD存在；runtime evidence OPEN |
| Stage | V2 typed assembly、Stage-owned Camera2D/ground presenter、`StageWorldDomainViewV2`与persistent root Window render identity | Re-review Pending；Camera/ground asset与runtime evidence OPEN |
| SpatialGrid | sparse occupied-cell phase/pause/resume/query/teardown | V2 contract Re-review Pending；integration OPEN |
| SpawnDirector | 上tickPlayer anchor、固定RNG消费、spawn/normal retire intent | Full Review Pending；runtime integration OPEN |
| Object Pooling | lifecycle/quarantine/resume binding | 第三轮传播修订后 Re-review Pending；integration OPEN |
| InputSystem | movement、pause cancel、choice gate、typed geometry revision、BATTLE_ACTIVE pause gateway | Re-review Pending；2026-09-10 independent verdict `MAJOR REVISION NEEDED / XL`，授权整改中；integration OPEN |
| PlayerController | typed contexts、damage/recovery views、motion/HUD/event banks、DAMAGE/HEAL/DEATH facts、REVIVE/DEFEAT intents | 第四轮lean整改已传播；下一轮独立full Re-review Pending，Damage/Recovery/Hazard/BattleUI集成BLOCKED |
| RNG | run_seed、service fault | core RNG frozen；sidecar propagation Re-review Pending，GATE-G2/G3 runtime OPEN |
| SaveSystem | outcome commit identity、reservation/commit/retry、archive/retire persistence | `design/gdd/save-system.md` Designed / Full Review Pending；codec/domain/platform durability/runtime integration BLOCKED |
| SettlementSystem/BattleUI | outcome、pause/fault/unsaved presentation | 两份作者GDD均已冻结consumer-only、atomic bundle、durable状态与touch-drain门；actual capture/copy/service binding仍BLOCKED。 |
| Audio Feedback | `AudioFrameBundleV1` sealed capture、PLAYER_AUDIO bit0b100、Active/control presenter tick、winner与teardown | Designed / Full Review Pending；非Player event bank/capacity、paused playback、assets/mix/runtime仍BLOCKED |

下游 participant 包括 Player、Enemy、Spawn、Damage、Projectile、Drop、SkillDraft、RiskChoice、Leveling；不得自主编排 phase。跨文档 owner 改动必须同步 registry、owner GDD 与本节 gate，不在 GameRoot 复制内部实现。

## Tuning Knobs

| Setting | Value | Rule |
|---|---:|---|
| `MAX_PAUSE_DRAIN_TICKS` | 1 | 固定安全上限，不可调高掩盖pending泄漏 |
| `pause_pending_lock_feedback` | `IMMEDIATE`（固定） | 进入Pending同一控制迭代立即显示，不等待多帧淡入；离开Pending立即reset |
| `physics/common/physics_ticks_per_second` | 60（固定） | gameplay只使用`1/60`固定dt；BOOT readback |
| `Engine.time_scale` | 1.0（固定） | 唯一GameRoot启动配置；load/pre-tick/resume readback |
| `MAX_PENDING_REASONS` | `3+MAX_PENDING_BLOCKING_CHOICES` | Config build时checked派生；singleton coalesce |
| `MAX_PENDING_BLOCKING_CHOICES` | required owner `BLOCKING_CHOICE` rows的checked sum，且`1..16` | 禁止手填aggregate；缺owner row使battle_ready=false |
| `MAX_PAUSE_DRAIN_CLOSURES` | `checked_sum(owner PAUSE_CLOSURE)+checked_sum(FPCC01..02)`，schema `1..1538` | preallocated；一个lifecycle intent至多一个`FINALIZE_POOL_RELEASE` closure，另加GameRoot cancel与Grid lease固定贡献 |
| orchestration capacities | `OwnerOrchestrationCapacityContributionManifest` checked sum..finite schema maximum | Config在任何allocation前校验；缺/重owner contribution或checked sum失败使battle_ready=false |
| `MAX_SUPPRESSED_DIAGNOSTICS` | `1..MAX_SUPPRESSED_DIAGNOSTICS_SCHEMA` | 必须在load定容；overflow只做saturating counter |
| app-scope pending commit | 1 | 未retry成功或discard前禁止新局 |
| wallclock p95/p99 | OPEN | 由目标设备 benchmark manifest 冻结，不在设计评审中发明 |

## Acceptance Criteria

2026-09-10 InputSystem remediation clarification：`app_adapter_action_pump`在`BATTLE_ACTIVE`也必须运行，但只接受`BATTLE_ACTIVE_PAUSE`一节点gateway；因此旧的“BATTLE_ACTIVE无snapshot”描述被本条覆盖。该gateway不改变七phase、pause barrier或owner边界，真实平台无障碍验证仍为BLOCKED。

同理，GameRoot的无障碍静态计数以ADR-0001当前actual为准：7 hash rows、8 profiles、102 nodes、35 state variants；`BATTLE_ACTIVE`只计入1-row pause gateway，不能被旧的6-screen/34-variant历史文字当作通过证据。

所有failure fixture使用稳定row schema：`{fixture_id,source_state,resume_substate,fault_scope,top_event,guard_id,guard_result,outcome_readiness,outcome_binding_state,fault_completion_exposure,injection_point,participant_id,service_id,api_id,injected_status,created_resource_prefix,expected_root_status,expected_top_state,expected_substate,expected_fault_scope,expected_participant_calls,expected_service_calls,matching_end_count,grid_snapshot_delta,grid_publish_count,pool_publish_count,authority_publish_count,authority_revision_delta,resolution_token_delta,lifecycle_rows_committed,fact_rows_committed,rollback_owner,input_state,consumer_open_count,cleanup_substate,destination_ui_state,cleanup_gate_acquire_mode,cleanup_gate_acquire_count,cleanup_gate_release_count,viewport_gate_owned,pause_setter_sequence,open_lease_count,published_frozen_quarantine_count,transaction_quarantine_count,cleanup_trace,remaining_resource_count,first_diagnostic,suppressed_count}`。每row独立运行；transition expected只来自canonical transition/action rows，guard expected只来自`TransitionGuardOracleManifestV1`，load disposition只来自`LoadFailureDispositionManifestV1`；fixture不得自填另一真相或以“首/中/末”代替稳定ID。

上述fixture schema升级为V2：在`injection_point`后固定插入`injection_subphase_id:LoadInjectionSubphaseV1`；旧无subphase row不得进入production hash。point15必须为每个LFD29/30各展开encode/write/readback三row，其他point只允许subphase NONE；expected仍只来自同一LFD row与PONR bit，不由fixture自填。

### A. Lifetime、Scene Flow 与 Loading DAG

**AC-A1 persistent root与合法边**：分别执行persistent identity、两局battle-scope replacement、R2合法边与72条TransitionActionOutcome实际行；GameRoot/root Window identity恰一个，battle child/bank/service每局identity不同。HOME/SETTLEMENT中旧Node、lease、authority/resolution bank、borrow、gameplay callback与writer引用数为0；显示/Save保留的immutable sealed Outcome/Completion/Save或PreOutcome carrier允许存在且不计为旧battle引用。frame-end barrier后queued battle Node失效。Gate: BLOCKING。

**AC-A2 typed转换全集与独立guard oracle**：由R2表生成转换全集；逐行执行`TransitionGuardOracleManifestV1`实际54行并核canonical hash，入口只接event并从权威prestate求guard。特别断言GRID两个guard互斥、archive-entry与carriers-retired不混用、Prep handoff、ActiveEntry、LOAD_READY及CLEANUP/SAFE_EXIT exposure边界；pre-active offer clear/uncertain PONR只来自LFD25/26，不存在玩家cancel guard/event。未声明tuple、错误guard或oracle=false均WRONG_STATE且ResourceIdentity byte-identical；`TransitionActionOutcomeV1`实际72行逐checkpoint注入，动作失败按canonical target与journal断言。Gate: BLOCKING。

**AC-A2b app-service topology与result pump**：逐字段验证`AppServiceTopologyManifestV1`恰为§R1五行，BOOT只按stable order构造一次、退出按shutdown order1→5；除AUDIO_APP预建app-scope AudioStreamPlayer外，任一service持有Node/RID/Callable，或任一行持有battle对象/可变bank均失败。向484-byte Save mailbox分别注入五种result kind、0/actual/205 payload length、非零unused tail、完整204-byte create V3/136-byte update/160-byte terminal result及stale结果，并在全部TopState推进；create逐字段破坏source correlation/operation identity，下一render frame必须恰调用一次`app_service_result_pump`且只由matching typed reducer推进，禁止共享状态补字段。同帧第二drain、worker直调UI、gameplay/survival delta均为0。Gate: BLOCKING。

**AC-A2c app-adapter ingress与render workload**：逐字段验证`AppAdapterTopologyManifestV2`唯一MOBILE_ACCESSIBILITY row、ADR七行screen hash/capacity、8 profile/102 node/35 variant actual rows、Input八行Meta UI action。在全部TopState从多个native/background线程注入matching/stale/duplicate/disabled与64/65-row MPSC、32/33-row SPSC burst，逐字段验证6208-byte MPSC header/row、slot sequence、CAS linearization、full不推进enqueue/不留ticket hole、单atomic producer gate的acquire/retire与stop-accepting shutdown；PLATFORM_SERIAL_INGRESS按ticket ASC唯一分配native event sequence并写2476-byte SPSC，主线程sole consumer每render frame恰drain一次。八行Meta UI action均经同一owner gate：FOCUS_*只移动focus且业务command0，ACTIVATE/BACK/INCREMENT/DECREMENT分别匹配对应presenter command与enabled/disabled gate；逐variant验证initial focus、neighbor、enabled/action/localization并执行ARRW01..05。PRE_ACTIVE_CHOICE back/cancel command0，BATTLE_ACTIVE只允许`7001/BATTLE_ACTIVE_PAUSE` gateway并拒绝任何其他gameplay HUD action；任一队列overflow、sequence MAX或allocator/growth/COW正控令screen noninteractive。detach严格停止接纳→producer retire→MPSC drain/retire→SPSC drain/retire后才换generation，shutdown后的callback为0 command。Gate: BLOCKING。

**AC-A3 Loading成功、outcome readiness与identity E2E**：验证唯一DAG与BOOT固定backing identity；CONFIRM_RUN在battle ID分配或PreOutcome backing bind失败时保持PREP、OutcomeBindingState=UNBOUND且零副作用，成功后PreOutcome携带matching battle identity但OutcomeBindingState仍UNBOUND。逐LoadInjectionPoint验证READY前逻辑Outcome/Save=0，READY后backing header一致且terminal binding仍UNBOUND；终局commit ID+三carrier原子绑定成功才BOUND。ID耗尽置IDENTITY_UNAVAILABLE、逻辑Outcome/Completion/Save=0并由PreOutcome完成cleanup/safe exit，不递归构造technical envelope。owner identity mismatch时ACTIVE/Settlement publish=0。Gate: BLOCKING。

**AC-A4 Stage/root Window assembly与cleanup handoff**：合法Stage唯一Camera C并逐字段验证BattleViewportTopologyManifest。cleanup从Active Ending、Paused Fault、Resume Fault与partial Loading逐行跑完整CleanupSubstate/ActivationCommitJournal FSM；覆盖ACQUIRED/REUSED、gate第1/2次失败后成功，以及连续3次失败进入ACQUIRE_FAILED_SAFE。safe路UI必须`SAFE_TERMINAL_NONINTERACTIVE`、input target=0、callback/writer=0、release=0并显示restart-required；正常路四detach、pause-off、frame barrier、required exposure与journal未全满足前不得ACTIVE。逐checkpoint故障重入后lifecycle pump仍可达，已提交点不重放。三类manifest/journal互换或字段破坏均失败。Gate: BLOCKING。

**AC-A4b Camera/ground follow**：连续移动、ZERO、复活位移与暂停/恢复fixture中，只有成功发布的matching Player motion可驱动Stage camera；正常tick camera中心逐bit等于published position，失败tick/暂停保持旧值，复活在phase-6整批commit后恰更新一次。地表始终覆盖`camera_visible_world_size+2×ground_overscan`且活跃tile/node数固定；断言无camera smoothing、limit、位置clamp、Node mirror回读或随路程增长的节点数。Gate: BLOCKING。

**AC-A5 Loading failure disposition+DAG**：逐行执行展开后的30个`LoadFailureDispositionManifestV1` row并核hash；expected event、reservation、readiness/binding与cleanup trace只来自canonical row。retryable行reservation与PreOutcome逻辑carrier恰release一次；uncertain行不得回PREP。特别覆盖`SEED_CANDIDATE_DURABLE` encode/write/readback、`PRE_ACTIVE_CHOICE`与`ACTIVE_ENTRY_DURABLE`的clear/uncertain两分支，marker已durable则走active orphan consume而非release。只清理created prefix，Grid invalidation先于Pool teardown，destination先staged、frame barrier/expose/top-state commit后才ACTIVE，held gate最后release，末端pause=false。终局ID失败只走TA/IDENTITY_UNAVAILABLE，不混入load oracle。Gate: BLOCKING。

**AC-A6 pre-battle fault**：BOOT bootstrap failure、首次启动无profile、Save corrupt与PREP `PRE_BATTLE_FAILURE_LATCHED`逐row进入`CONTROLLED_FAULT(PRE_BATTLE)`；battle identity、`RunOutcomeEnvelope/outcome_commit_id/reward reservation/Save attempt`创建数均0，SceneTree pause=false。persistent root构造matching `FaultPresentationBundleV1`，no-profile时`profile_present=0,profile_revision=0`，无source时hash=ZERO32；按ASN07发布最多6行并只生成allowed retry/safe-exit/export typed command。BattleUI未创建/已detach不影响页面，stale diagnostic/action generation为0 command，retry或safe exit不显示战局已保存/奖励到账。Gate: BLOCKING。

### B. Physics and Transaction

**AC-B1 静态单owner与callback allowlist**：AST/scene审计唯一persistent GameRoot callbacks、pause/root Window/Engine time-scale writer；GameRoot geometry event-source registration=0；participant自主process/input callback=0；所有signal/notification/tree callback均精确匹配GameplayCallbackAllowlist且body只写row列出的latch。hostile paused emit与PAUSED/UNPAUSED notification逐participant正控只改变批准的control/diagnostic latch；暂停期间及resume ACTIVE开放前边界的`unauthorized_callback_effect_count=0`。随后执行首个完整正常ACTIVE tick作为独立正控，必须按manifest调用participant且position/timer至少一项合法变化；该变化不得被误判为callback越权。脚本不存在前implementation prerequisite OPEN。Gate: BLOCKING before Done。

**AC-B2 七phase与真实drain callback**：逐phase缺participant/service row均在load INVALID_MANIFEST；合法非空coverage执行七组matching begin/end。真实`_physics_process`注入PENDING_WORK后，下一callback恰执行一次`gameplay_dt=0` drain。分别运行(a)无closure全零；(b)非空批准closure ID集合，只有对应journal/Pool/authority精确delta非零，tick/survival及其他effect为0。第二次pending/failure到Fault，第三次callback participant调用0。Gate: BLOCKING。

**AC-B2b Spawn anchor时序**：给定Player在tick T phase-2发布新位置，tick T phase-1只能使用T-1位置，tick T+1 phase-1恰使用T位置；8次attempt总消费固定24个RNG words。所有成功普通spawn完整足迹位于相对矩形环且首帧不与camera visible rect相交；cap-full、全部候选无效及退役分支仍维持固定消费，且normal退役不产出DEATH/掉落/奖励。Gate: BLOCKING。

**AC-B3 phase-specific failure、ledger与batch authority**：按真实coverage对每phase begin/participant/service/end注入。phase 1–5/7未提交publish=0、未来phase调用=0；phase 6先验证BatchPlan arm失败时side effect=0，再在每个lifecycle API与fact commit前后注入，断言一intent一row单调、Pool私有reset/free-stack exact-once、fact kind/payload/commit精确、N后side effect=0。`committed_authority_visible_rows=0`时authority publish=0/revision delta=0；为1、N及capacity时，无论matching success或fault convergence都恰publish=1/revision delta=1，published bank逐字段等于ledger/journal golden且所有本batch committed row共享该revision；cleanup重放不降state、不重复。Gate: BLOCKING。

**AC-B4 resolution exact-once bank identity**：A/B bank写不同sentinel；tick T只允许消费token指定bank，effect前consumed token完整匹配；二次consume=0，读取旧/错bank=0；publish failure不生成T token且不能消费T-1。Gate: BLOCKING。

**AC-B5 revision boundary**：初值、无变更不publish、phase-6多row单batch、Paused choice publish、resume publish、failure保持、overflow、跨battle stale token逐row验证R3/F3全部revision轴；authority revision只等于实际bank publish次数。Gate: BLOCKING。

### C. Pause、Reason 与 Presentation

**AC-C1 pause/终局/fault priority**：phase5 matching resolution后对`{FATAL,VICTORY,PAUSE}`producer coverage的missing/duplicate/stale/order permutation及全部mask逐行预收集；phase6再注入DEFEAT/REVIVE，phase7只seal同一precollection token。expected winner只来自独立31-row priority golden，choice UI打开数0；因此victory+death=VICTORY、victory+death+fatal=TECHNICAL_ABORT、ABANDONED不得压过任何更高项，phase7首次VICTORY/FATAL必须fault而不得回滚已执行Player事务。normal seal后再注入fatal保持envelope byte-identical且RunCompletionStatus fault code非零。另注入outcome commit ID exhaustion，normal seal/Save attempt=0、不得递归建technical envelope并走固定safe-exit fault文案。Gate: BLOCKING。

**AC-C2a drain无批准closure**：closure set为空时HP、position、gameplay timer、spawn/query/damage/pickup/reward/borrow/authority/tick/survival全部不变；每个禁止effect有独立ACTIVE positive control。Gate: BLOCKING。

**AC-C2b drain批准closure**：给定PauseDrainClosureTypeManifest与稳定closure set，每行必须精确引用锁定反馈前已有的source tick/journal row/lease及允许commit state；只有对应cancel/unbind/release/lease与按visible-row谓词恰0或1次batch authority delta可非零，新fact row与锁定后新row=0。未列effect、tick/survival、fresh intent均0；缺ID、额外/重复ID、source revision晚于pause、row/state不匹配或非manifest kind均fault。Gate: BLOCKING。

**AC-C3 reason queue/latch/容量矩阵**：覆盖逐项、所有pairwise、`manual+choice+background`、`choice+background+geometry`、三choice同tick、duplicate/coalesced background revision、capacity与capacity+1、intent sequence耗尽。每row冻结presentation/ack/complete顺序、resume_requested_latched set/clear、attempt count与effect token；manual/background残留时attempt=0，点前rollback保留已有latch。Gate: BLOCKING。

**AC-C4 blocked choice feedback**：首拒绝intent=0且视觉/可访问性反馈恰一次；重复不播，predicate false清除，下一episode可再次播。Gate: BLOCKING。

**AC-C5 geometry owner与background deterministic**：静态证明GameRoot不注册Window/Viewport geometry source；只由Input relay注入typed revision。覆盖new/duplicate/coalesce/foreground/background sequence与expected forward count；真机只作GATE-OQ evidence。Gate: BLOCKING。

**AC-C6 pause truth table与同步notification**：逐row验证 `{state,substate,fault_scope,source_state,battle_child_present,paused_before,setter_sequence,notification_sequence,readback_sequence,paused_after,root_callback,participant_can_process,root_window_gate}`，含PRE_BATTLE fault、partial-loading battle fault、Active/Pending/Paused/Resume/Ending。PAUSABLE gameplay probe、ALWAYS control、hostile signal与逐participant PAUSED/UNPAUSED notification给正负对照，setter调用栈内权威mutation=0。Gate: BLOCKING。

### D. Resume

**AC-D1 pump与expected tuple checkpoints**：无玩家输入也每iteration service async fault；对battle/config/input/background/geometry/authority/Grid/topology/Engine轴×每checkpoint逐row注入。合法Grid publish精确接受`g→g_next`，额外`g+2`才fault；无resume latch时attempt=0，点前rollback保留latch，点后完成三publish后fault，ACTIVE/root Window开放=0。Gate: BLOCKING。

**AC-D2 prepare/arm failure rows**：Grid/Pool/authority prepare+arm、identity/topology/Engine gate、owner swap逐row注入；正控固定`old_authority_borrow_count in {1,capacity}`且每个borrow有唯一sentinel，old owner恢复、candidate/plan/lease与`transaction_quarantine_count=0`，`published_frozen_quarantine_count`精确等于旧非零borrow数且sentinel不变，authority revision不变；另保留0 borrow为独立空控制行，不得用其证明quarantine保留。Gate: BLOCKING。

**AC-D3a wrong Grid tx（point-before）**：首次matching Grid publish前wrong tx=`PHASE_ERROR`，恢复old owner、以matching abort回Paused，不执行Pool/authority publish。Gate: BLOCKING。

**AC-D3b/c point-after wrong Pool/authority key**：Grid已matching publish后wrong Pool tx或authority plan保持armed；立即用保存的正确tx/plan完成剩余Pool/authority publish并fault，不恢复old owner。matching publish阶段Node API与可失败validation调用数0。Gate: BLOCKING。

**AC-D4 point-after failure rows**：Grid→Pool、Pool→authority、三publish后、cleanup、unpause observer逐row注入；保存plan完成剩余publish，first diagnostic保留root，cleanup错误进suppressed；不恢复old owner。Gate: BLOCKING。

**AC-D5 explicit unpause observer**：ALWAYS Host未收到UNPAUSED仍成功；set_pause(false)返回后GameRoot显式复核。held-only先repause/readback后入drain；fault/invalidation ACTIVE publish=0。Gate: BLOCKING。

**AC-D6 held-drain substate**：点后held时top state始终RESUME_PREPARING、substate=RESUME_HELD_DRAIN、open resource=0、反馈恰一次、pump持续、resume latch保持true；current-epoch release/cancel后自动尾段retry一次并仅在成功ACTIVE清latch，stale terminal不解锁。Gate: BLOCKING。

### E. Ending、Outcome 与 Save

**AC-E1 immutable canonical envelope ABI与Fault FINISHED**：用独立V1 golden逐行验证实际34-row manifest及wire bytes，并确认`outcome_kind`唯一producer=GAME_ROOT、BATTLE_RULES只提供terminal intent。BOOT backing不算逻辑carrier；terminal ID绑定成功时Envelope/Completion/Save同checkpoint初始化且binding=BOUND。normal/technical经各自FINISHED边exact-once expose；另跑UNAVAILABLE与IDENTITY_UNAVAILABLE PreOutcome路径，逻辑Outcome/Completion/Save为0且Fault self-edge仍EXPOSED。cleanup success/fault保持sealed bytes不变，Settlement/Fault回读Node次数0。Gate: BLOCKING on producers。

**AC-E2 manual exit**：Active请求必须先走MANUAL安全pause，BATTLE_PAUSED后才显示确认；modal期间gameplay与底层input命中0。确认产生ABANDONED且reward/record/tutorial/reservation compensation=0；取消清manual_exit_pending但保持MANUAL暂停，Continue后按正常resume。Gate: BLOCKING。

**AC-E3 TECHNICAL_ABORT facts与reservation**：分别以非零committed kill、survival、pickup及组合例运行并夹带staging poison；只有COMMITTED/已发布facts计入。retryable load abort reservation exact-once RELEASED，READY且BOUND的uncertain path映射TECHNICAL_COMPENSATION；UNAVAILABLE或IDENTITY_UNAVAILABLE PreOutcome路径奖励、Outcome与Save均为0。`reservation_id→outcome_commit_id`仅在BOUND时一一对应；非战败标题出现1次，战败/死亡/纪录控件0次。Gate: BLOCKING on Save integration。

**AC-E4a Save total reducer与retire journal**：四类outcome逐项执行全部7个state、presence matrix及total reducer每行，包含discard请求发现既有commit时`OUTCOME_COMMIT+RECONCILE_FOUND→SAVE_SUCCEEDED`；对operation/in-flight/count/generation/request/receipt/tombstone与correlation逐项破坏，unknown/stale必须OK_NOOP。分别验证SAVE与DISCARD上下文的`RECONCILE_NOT_FOUND_UNPROVEN`目标，并断言DISCARDED为matching非零receipt+tombstone、无重复reducer row。0/1/MAX/MAX+1验证validate+allocate全成才提交并以`ID_EXHAUSTED`封闭返回。SAVE_SUCCEEDED/DISCARDED各运行三种离开event与ArchiveRetireJournal四checkpoint成功/失败/重试；ResolvedRunArchive逐字段readback、operation_id稳定、durable archive不重复append，逐bit partial retire继续exact-once，COMPLETED后`CARRIERS_RETIRED=true`。Gate: BLOCKING on Save/BattleUI。

**AC-E4b discard、丢callback与late success仲裁**：二次确认后进入DISCARD_PENDING；分别注入(a)success durable fact与receipt都先于tombstone，(b)success durable fact先但receipt callback丢失/迟到，(c)tombstone durable fact先于late callback/request，(d)tombstone timeout/暂时失败/成功但callback丢失，及重复callback。a/b均由同commit ID reconcile为SUCCEEDED且tombstone写入数0；c为DISCARDED且后端拒绝late commit、旧callback no-op；d保持同tombstone ID且in-flight=0，Settlement/Fault/HOME均可retry discard或reconcile，下一请求只推进generation/request。完成前新run=WRONG_STATE。Gate: BLOCKING on Save/BattleUI。

**AC-E5 teardown DAG rows**：Active/Paused/Prepared/Armed/Fault/Ending逐row验证created-prefix、lifecycle_pump持续推进、CleanupSubstate与ActivationCommitJournal单调/idempotent、成功/复用/三次失败safe terminal路径、Grid→Pool→Grid reset与旧UI逻辑detach。正常路先STAGED_NONINTERACTIVE，required条件齐全后才ACTIVE；safe路始终SAFE_TERMINAL_NONINTERACTIVE且release=0。逐checkpoint重复不得重取/release、回验旧Battle manifest、二次commit或丢失sealed carrier。Gate: BLOCKING。

### F. Copy、Allocation、Diagnostics 与 Time

**AC-F1a copy completeness**：独立owner schema golden与AuthorityCopyManifest字段/type/capacity集合精确相等；A/B不同sentinel连续两轮交替，每字段write count=count、tail poison不权威、inactive mutation不影响published，漏字段或dirty-patch被外部oracle捕获。Gate: BLOCKING。

**AC-F1b forbidden operation static guard**：以稳定pattern ID逐项fixture拒绝Active/Paused中的clear/resize/append_array/duplicate/slice、容器替换、source/destination同identity、局部alias写回与跨bank backing共享；不声称其必然分配。Gate: BLOCKING before Done。

**AC-F1c backing isolation evidence**：使用经ADR/引擎spike确认可观察的identity或mutation isolation方法；无可靠observer=`INCONCLUSIVE`，不得PASS。Gate: BLOCKING before Done。

**AC-F2 workload-class evidence**：首先以已冻结owner cap验证当前`{1,303,384,503}` fixture被Config拒绝为`BLOCKED-WORKLOAD-REGEN`，不得运行后伪称production证据。整表重生成后，release artifact/hash+Config/coverage/authority/owner/native-allowlist/Player-supplement hash+observer/version逐字段匹配；再逐RW01..12与PWM01..04运行并核sample protocol与exact operation vector。RW07/08必须由control pump iteration驱动，physics tick计数为0；RW01..09及PWM steady rows要求allocator events/bytes、growth、COW、unexpected native-call逐run分别为0及positive control；RW10/11 cold与RW12 Save不得作零分配断言。PWM03的1000次revive必须使用1000个fresh battle或pre-armed immutable fixture，load/reset在marker外；isolated与full integration分开报告。visible 0/1/max每次phase6 arm都full-copy恰1，publish仅0/1。缺重生成row/hash/展开hazard或不匹配=`INCONCLUSIVE`。Gate: BLOCKING before Done。

**AC-F3 diagnostic capacity**：先验证`1<=C<=schema max`；对数学attempt A={0,C-1,C,C+1,C+3}验证F6 attempt/stored/overflow三公式、完整header、first不变、schema/顺序、bank identity/size与allocator delta。另分别将attempt与overflow counter seed为INT64_MAX-1/MAX后注入，验证各自saturating recurrence与唯一`diagnostic_counter_saturated` flag，不在int64中计算会先溢出的C+3。Gate: BLOCKING。

**AC-F4a deterministic root diagnostic**：固定同一battle/config identity fixture，两次只比较`state/tick/phase/status/api/participant`稳定字段；逐项扰动时仅对应字段变化。Gate: BLOCKING。

**AC-F4b cross-battle identity**：两局允许battle/config/diagnostic ID不同；仅`battle_instance_id/config_snapshot_id`与本局ResourceIdentityManifest对应字段相等，diagnostic ID要求本局非零唯一且first=sidecar，其余state/tick/status/RNG字段分别取各自fixture/instrumentation oracle，禁止“所有字段等于manifest”。Gate: BLOCKING。

**AC-F4d fixed tick/time-scale/topology globals**：覆盖Engine tick rate 60/59、time_scale 1/0/0.5/NaN、callback delta NaN/±INF/0/negative/finite rounding drift，以及load后camera/reparent/nested Viewport漂移。只有60+1.0且topology manifest匹配可进入/保持Active；有限rounding drift只telemetry，不改变`1/60` gameplay dt。Gate: BLOCKING。

**AC-F4c RNG telemetry sidecar**：固定identity下比较`run_seed/stream_ids/call_counts/pre_fault_states/fault_stream/fault_reason`；只改seed时run_seed变化，位置字段可不变；验证与first相同diagnostic ID、teardown前capture及GATE-G3。Gate: BLOCKING。

**GATE-F5 wallclock evidence**：分别报告orchestration self/E2E、authority copy、phase6 max journal churn、pause-on/drain、clean resume、pre-point rollback、post-point held-drain soak、setter-in-flight return-to-drain、cold loading/teardown/Save，以及四个玩家面span。须满足F5 production-scale manifest与样本域；设备/threshold未冻结时OPEN，不阻止设计修订但阻止Done/benchmark-ready。

## Open Questions

| ID | 问题 | Owner | 关闭条件 | 当前状态 |
|---|---|---|---|---|
| OQ1 | GameRoot落地为Autoload还是main-scene persistent root？ | Technical Director | ADR-GR-001；行为不得偏离R1 lifetime | DESIGN ANSWERED / IMPLEMENTATION EVIDENCE OPEN |
| OQ2 | battle/outcome identity的具体生成与持久化算法？ | Technical Director + Save | ADR-GR-001 + Save ADR；满足不复用与retry稳定 | OPEN/BLOCKED on Save |
| OQ3 | Godot Input callback、Window relay与background/orientation顺序？ | InputSystem | GATE-OQ-INPUT目标平台trace | OPEN |
| OQ4 | Viewport/pause setter同步重入是否满足observer契约？ | GameRoot + Input | GATE-OQ-VIEWPORT hostile harness | OPEN |
| OQ5 | copy、diagnostics、steady tick是否零allocator/growth/COW？ | Performance | GATE-OQ-ALLOC release evidence | OPEN |
| OQ6 | min-spec p95/p99阈值？ | Producer + Performance | 冻结完整manifest并通过GATE-OQ-TIME | OPEN |
| OQ7 | project asset、GDUnit4与静态守卫是否已落地？ | QA | GATE-OQ-STATIC artifacts存在且通过 | OPEN |
| OQ8 | SaveSystem如何跨进程恢复pending commit并保证永久资源原子性？ | SaveSystem | Save GDD已冻结双槽+durable pending/precedence；仍需AC-E3/E4 integration与真机kill trace | DESIGN ANSWERED / RUNTIME BLOCKED |
