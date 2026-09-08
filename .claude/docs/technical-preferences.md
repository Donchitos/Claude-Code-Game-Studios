# Technical Preferences

## 第八轮当前合同覆盖（2026-09-08）

ADR 当前逐node contract 为 101 行（其中 BATTLE_PAUSED choice 组与 reason 组互斥，不可同时计入24-row capacity）。

当前实现前口径以本节为准：`DurableReservationV2=1152`、`ZhangtianReservationPayloadV2=724`、`SlotPayloadMax=42244`、`SlotEncodedMax=42456`；RCO V2 11行×RCC 12行=132 fixture；SaveGlobalCodecHashManifestV1为6行。ADR native MPSC row使用68-byte payload（96-byte row，总6208），serial ingress补齐76-byte command；Meta UI Input manifest为8行（含INCREMENT/DECREMENT），Settings持久布尔字段为reduce_motion/reduce_sensory_load/high_contrast/screen_reader_hints。旧1088/42180/42392、84-row、六行Meta UI仅保留在历史记录，不得作为当前实现输入。

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.7.1
- **Language**: GDScript
- **Rendering**: Godot Forward+ (2D 项目下实际走 2D 渲染器)
- **Physics**: Godot Physics 2D (内置 — Jolt 是 3D 选项，本项目 2D 不适用)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (Android, iOS) — 优先竖屏
- **Input Methods**: Touch
- **Primary Input**: Touch (虚拟摇杆移动，攻击自动释放)
- **Gamepad Support**: Meta UI only — mapped D-pad/digital focus、South activate、East back、肩键增减按8-row `MetaUiInputActionManifestV1`进入typed presenter command；战斗移动仍仅Touch VirtualJoystick，unmapped raw axis为0业务命令
- **Touch Support**: Full
- **Platform Notes**: 竖屏单手操作；所有交互必须单手可达；移动端无 hover，不得设计悬停态交互；升级 / 机缘选择时暂停战斗。
- **Meta UI Baseline**: Home/Prep/Settlement采用safe-area响应式纵向布局，内容区最大宽600 logical px、交互目标最小56×56 logical px，并验证100%/115%/130%字体；touch与keyboard/screen-reader focus是两条独立路径。移动端采用`docs/architecture/adr-0001-mobile-accessibility-bridge.md`的`AccessibleScreenSnapshotV2` + Android/iOS原生adapter + typed action回传；248-byte row包含layout generation、logical bounds、visible/clipped与8 typed localization args。action-bearing states固定HOME/PREP/PRE_ACTIVE_CHOICE/BATTLE_PAUSED/SETTLEMENT/CONTROLLED_FAULT；架构路径已冻结，插件实现、能力握手、accessible tree与真机trace仍`BLOCKED-MOBILE-A11Y-RUNTIME`，静态Control属性或桌面读屏不得替代。
- **Prep Safety**: 有可用种子才进入Prep且每次默认NONE；未解锁/available全0时Home与resolved Settlement分别从同一confirmed bundle内128-byte `DirectNoneStartSliceV2`构造`HOME_DIRECT_NONE`/`SETTLEMENT_DIRECT_NONE`，且只接受unlock/claim flag为`0/0或1/1`，不制造空Prep二次确认，也不交叉复用页面generation。不自动沿用、选择或消费丹药；只有Save durable reservation readback成功才进入Loading。`RunStartRequestV2`冻结后不可回写，132-byte seed candidate与pre-active choice逐步写入固定360-byte recovery，以durable config content revision+hash确定性重放；首个聚气offer durable/visible后不得release重抽。
- **Settlement Truth**: 奖励只来自sealed Outcome和matching immutable mutation bundle；durable success前统一显示待保存，UNCERTAIN只允许核对，不以超时或动画完成宣称到账。

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS (中端 Android 设备平均 50 FPS+)
- **Frame Budget**: 16.6 ms
- **Fixed Gameplay Timestep**: `physics/common/physics_ticks_per_second=60`且`Engine.time_scale=1.0`，gameplay只消费`1/60`或技术drain的0；callback delta仅作telemetry
- **Draw Calls**: [待定 — 依赖后续渲染批处理 ADR]
- **Memory Ceiling**: [待定 — 依赖目标设备基准确定]
- **Runtime workload evidence**: 每个测量绑定实际`RuntimeWorkloadManifestV1` row、config/coverage/authority/owner/native-call-allowlist hash、start/end marker、sample protocol与exact operation vector。physics、control pump、complete operation使用不同sample unit；不得用paused `_process`冒充physics tick。`STEADY_ZERO_DELTA`才要求allocator/growth/COW/native-call逐run为0；cold loading/teardown为`COLD_MEASURE_ONLY`，Save为`MEMORY_IO`，二者只测量不宣称零分配。缺row/hash/marker或向量不匹配=`INCONCLUSIVE`。

## Testing

- **Framework**: GDUnit4
- **Minimum Coverage**: 平衡公式、伤害计算、升级经验、敌人阶段倍率 (BLOCKING)
- **Required Tests**: Balance formulas, gameplay systems

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- 稳态(借出/归还/每帧)路径禁 `emit_signal(带参)` / `set_deferred` /
  `call(method_string,…)` / `get_children()`(EnemySystem §3.4 零分配禁令;
  AC-E4-code 静态守卫)
- gameplay phase participant 禁定义 `func _physics_process` / `func _process`（集中
  `run_phase` 驱动；AC-E13）。唯一例外为从BOOT到应用退出保持同一live identity的
  persistent GameRoot：它精确使用 `PROCESS_MODE_ALWAYS`；每个render frame先在所有TopState恰调用一次无gameplay effect的`app_service_result_pump`，再按state选择至多一个互斥pump。仅在
  `SceneTree.paused==false && state in {BATTLE_ACTIVE,PAUSE_PENDING}` 的 `_physics_process(delta: float) -> void`
  驱动普通七phase或恰一次`gameplay_dt=0` allowlist drain，仅在
  `SceneTree.paused==true && state in {PRE_ACTIVE_CHOICE,BATTLE_PAUSED,RESUME_PREPARING}` 的
  `_process(delta: float) -> void` 驱动control pump，并在`BATTLE_LOADING/BATTLE_ENDING/CONTROLLED_FAULT`
  驱动无gameplay effect的lifecycle pump、cleanup checkpoint与frame barrier。GameRoot是`SceneTree.paused`与persistent
  root Window gate、Engine runtime tick-rate/time-scale启动配置的唯一项目writer；pause/unpause必须经私有helper调用并readback。
  participant使用PAUSABLE mode；禁止在Paused跑gameplay、未暂停跑pump、双跑、per-scene
  重建第二GameRoot或由其他节点复制该例外（InputSystem AC-IS2 / GameRoot AC-B1/C6）。
- GameRoot/Config所有runtime orchestration容量下界只能来自`OwnerOrchestrationCapacityContributionManifest`：
  每个required role对`LIFECYCLE_INTENT/FACT_COMMIT/PAUSE_CLOSURE/BLOCKING_CHOICE`逐类exact-once贡献；lifecycle/fact/blocking-choice lower bound等于对应owner checked sum，pause closure等于owner sum再加fixed contribution。`MAX_PENDING_BLOCKING_CHOICES`禁止手填aggregate；`OUTCOME_FIELD`按canonical SoA field由唯一producer逐field贡献。
  canonical排序键固定`{role_stable_order,kind_stable_order,field_stable_order}`且组合唯一。pause closure另加GameRoot cancel与SpatialGrid lease两条fixed contribution；一个lifecycle row最多一个`FINALIZE_POOL_RELEASE` closure，不把unbind/release拆成两条。缺/重行、排序冲突、overflow、低于下界或高于schema hard max均须在allocation前fail closed。
- Outcome生产ABI固定为GameRoot canonical 34-row（22 scalar+12 SoA）`RunOutcomeProducerManifest`，`outcome_kind`producer只能是GAME_ROOT，BATTLE_RULES只提交terminal intent；
  float归并只允许按`stable_id ASC,fact_sequence ASC`以float64顺序累加，禁止FMA/reorder并规范化`-0.0`。
  转换guard真值只能来自独立`TransitionGuardOracleManifest`，转换动作失败只能来自实际展开的`TransitionActionOutcomeV1`；load状态须先经封闭的全status normalization，再查disposition，不得从target表或fixture反推。
- PAUSABLE不会冻结普通signal或`_notification` callback。所有signal/notification/tree lifecycle callback
  必须登记在load时冻结的`GameplayCallbackAllowlist`，暂停时只允许写row明确列出的control/
  invalidation/diagnostic latch；不得写恢复后会生成HP/position/timer/authority/reward/spawn/remove的intent。
  未登记callback、同步pause notification内直接权威写或绕过phase均为contract failure。
- MVP不创建逐局SubViewport：应用persistent root `Window`同时是battle render与GUI input
  Viewport；每局只detach/free Stage、BattleUI、Input child。Camera、Host、Shield、VJ、BattleUI
  的`get_viewport()`必须逐项等于该root Window。GameRoot在load冻结唯一字段名的versioned
  `BattleViewportTopologyManifest`；战局中禁止额外`make_current/reparent/set_enabled/custom_viewport`
  writer与nested Window/SubViewport。cleanup在任何old child detach前必须由GameRoot执行`CLEANUP_PRE_ACQUIRE`：
  gate已持有时`REUSED`且不得重复setter，未持有时验证root Window/owner/readback后`ACQUIRED`，acquire/readback
  未持gate时固定最多重试3次；连续失败才进入`ACQUIRE_FAILED_SAFE`，旧writer/callback、新input target、release均为0，只可安装`SAFE_TERMINAL_NONINTERACTIVE`并要求重启。
  `CleanupViewportHandoffManifest`仅证明old child已移交。`ActivationCommitJournalV1`逐点证明frame barrier、expose-or-NA、top-state、ACTIVE-or-safe与release-or-NA；lifecycle pump资格由journal未terminal决定，不因top-state已提交而停止。ACQUIRED/REUSED正常路release恰1，safe路始终release=0。
- 战场空间采用“感知无限、技术有限”：Stage唯一Camera2D逐bit跟随matching已发布Player位置，地表用固定数量tile或world-UV连续表现；SpawnDirector只读Player carrier，在玩家相对视野外环生成。底层使用有限`world_safe_aabb`与稀疏occupied-cell Grid；禁止按世界面积预分配dense grid，禁止把技术域做成可见clamp/wrap/origin-rebase玩法边界。
- `DEFERRED_REMOVAL` 禁止假设整phase可回滚：lifecycle一intent一mutable journal row；damage/heal/death/
  pickup/reward进入独立fact ledger。各side effect exact-once推进但不逐step全量copy；consumer closed下在
  side effect前先arm authority batch plan；visible committed row=0时0 publish，>0时matching end或fault
  convergence恰一次不可失败publish。Pool私有release FSM保证reset/free-stack exact-once，不得复活旧handle/
  borrow或重复side effect。PAUSE_PENDING closure必须引用锁定反馈前已有journal row/lease，禁止锁定后新fact。
- resume point-of-no-return 固定为首次Grid publish；此前可abort Grid/Pool/authority plan，之后必须在
  consumer closed下收敛`Grid→Pool→authority`三次publish。每次arm/publish前核对battle/config/input/
  background/geometry/authority/Grid/Pool/topology identity及Engine 60Hz/time-scale readback，第三次publish前不得开放consumer。
- 应用最多保留1个未完成Save commit；成功或durable discard tombstone完成前禁止开始新run；callback必须
  matching commit/generation/request，uncertain先reconcile。ABANDONED不产出奖励、
  纪录、教程或对有意消耗的prep资源作补偿；TECHNICAL_ABORT只允许fault前已提交事实+技术补偿。normal
  outcome envelope seal后byte-identical，cleanup fault只写独立RunCompletionStatus，Save fault只写attempt状态。
  DISCARD_PENDING timeout/lost callback保持同tombstone identity，可在Settlement/Fault/Home retry或reconcile；
  `SaveCommitAttemptV1`存在性矩阵固定：NOT_STARTED的attempt/generation/request均0且in_flight=0；SAVE_PENDING的
  attempt/generation/request均非零且in_flight=1；SAVE_UNCERTAIN/SAVE_FAILED/SAVE_SUCCEEDED保留这些ID且
  in_flight=0，其中仅SAVE_SUCCEEDED要求非零receipt；DISCARD_PENDING保留非零tombstone且in_flight可0/1，
  DISCARDED保留非零tombstone且in_flight=0。MVP run terminal唯一callback carrier为160-byte `TerminalRunResultV2`；旧`SaveOperationResultV1`禁止读取，`SaveOperationResultV2`只保留非reservation迁移路径且MVP调用数0，不并入
  immutable outcome或伪装成Save attempt常驻字段。
  callback reducer必须覆盖`source_state×operation_kind×public_result_code`；durable receipt code固定SUCCEEDED且reconcile不改其bytes。DISCARD若发现commit已durable必须以`OUTCOME_COMMIT+RECONCILE_FOUND`转SAVE_SUCCEEDED，`RECONCILE_NOT_FOUND_UNPROVEN`在SAVE路径回UNCERTAIN，在DISCARD路径保持DISCARD_PENDING。
  所有ID先checked reserve并一次提交；失败不得部分覆盖旧carrier。`ResolvedRunArchiveV1`须有实际schema/hash/readback；`ArchiveRetireJournalV1`以expected mask与retired bitset支持partial retry，archive-entry guard与carriers-retired guard必须分离。PreOutcome reservation使用独立state/recovery carrier与CTA，不借用Outcome disposition。
- Save durable介质固定为单writer+两个完整自校验槽，不使用独立current-pointer；槽含generation、canonical payload、Hash256与重复footer，只有flush/close后reopen逐位readback通过才可返回durable success。sealed Outcome/Completion、attempt、proposed profile必须作为`PendingOutcomeRecoveryV1`先落盘，重启只靠slot scan恢复。任一损坏槽存在时另一VALID槽只作只读恢复候选，显式恢复完成前禁止覆盖和新局；双坏、未来schema、同generation异payload或commit/tombstone冲突均fail closed。平台排他writer lock、durable barrier与kill-process证据未闭合前保持BLOCKED，不得以FileAccess返回OK代替durability。
- 第八轮覆盖上述历史 Save 线程段：当前终局使用 `DurableReservationV2=1152`、`ReservationUpdateRequestV2(RESOLVE)+ResolveReservationPayloadV3`，MPSC native payload 为 68 bytes；容量为 `SlotPayloadMax=42244`、`SlotEncodedMax=42456`，crash fixture 为 RCO V2 11行 × RCC V2 12行 = 132 行，Meta UI 为八行。旧 1088/42180/42392/84-row/六行仅保留审计，不得生成实现输入。
- 下方原 Save 线程长段为第七轮历史快照，仅供审计追溯；其“当前固定”数值已被本条第八轮覆盖，不得作为实现输入。
- Save线程拓扑固定：主线程只验证并移交不可变canonical bytes；唯一worker独占FileAccess、barrier/replace adapter与HashingContext，禁止访问Node/SceneTree/Resource/Signal或共享可变PackedArray；结果只进484-byte、capacity2的typed SPSC mailbox，每个220-byte row含204-byte完整canonical result payload，由GameRoot `app_service_result_pump`在所有TopState每render frame恰排空至多一次。create V3 result必须回显source kind/command/press/request hash及operation identity；其余按epoch/generation/result kind/operation/attempt/request唯一reduce，worker不得直调UI。MVP终局只允许`ReservationUpdateRequestV2(RESOLVE)+1112-byte ResolveReservationPayloadV3`一次同槽写，不得另发SaveCommit。历史快照值`ReservationMax=1088,LatestResolutionMax=264,DiagnosticsMax=2024,SlotPayloadMax=42180,SlotEncodedMax=42392,SlotMax=65536,FileSystemSafetyMargin=65536,DiskPeakMin=262144`，超限写前失败，不动态扩容；reservation update只接受5-row payload manifest，hash只接受25-row preimage manifest（含176-byte create request），crash fixture由7-row operation truth×12-row cut truth唯一展开84行。
- app-scope服务固定`SAVE/PROGRESSION/ZHANGTIAN/SETTLEMENT_PROFILE/AUDIO_APP`五个actual canonical row，由persistent app root按stable order一次构造、shutdown order关闭，不加入七phase participant。全部禁止battle Node/RID/Callable/可变bank引用；仅AUDIO_APP可持有预建app-scope AudioStreamPlayer，仅SAVE拥有worker，其余服务不得持有Node/RID/Callable。
- app-scope平台adapter与业务service分表：`AppAdapterTopologyManifestV2`当前唯一actual row为`MOBILE_ACCESSIBILITY`，生命周期为persistent root create后构造、所有TopState render-frame pump、presenter detach前停止接纳并drain、root free前shutdown。`AccessibleNodeRowV2`固定248 bytes并携带layout generation、logical bounds与8个typed localization args；action-bearing states固定HOME/PREP/PRE_ACTIVE_CHOICE/BATTLE_PAUSED/SETTLEMENT/CONTROLLED_FAULT，必须匹配7 profile、94 node与34 state-variant actual rows。任意native线程只写6208-byte预分配MPSC64 ingress；producer先在单atomic i64 gate上以CAS同时验证ACCEPTING并增加IN_FLIGHT，再按per-slot sequence/CAS取得无hole ticket并release publish，完成后归还gate reference；shutdown原子清ACCEPTING并等待同一gate归零后drain，禁止分离check/increment竞态。唯一PLATFORM_SERIAL_INGRESS acquire按ticket排序、分配checked i64 native event sequence，再写capacity32、2476-byte SPSC。任一上/下游overflow、stale layout、epoch/generation/thread违规均fail closed，不覆盖、不动态扩容。四个Meta focus action只改presenter focus，activate/back才汇入owner business command；CONTROLLED_FAULT由persistent GameRoot fault presenter拥有。路径与证据门见`docs/architecture/adr-0001-mobile-accessibility-bridge.md`。
- Progression Tree使用唯一`ProgressionProfileDomainV1`保存统一功法残页与QINGYUAN/LONGCHUN/DAYAN 0..5等级；购买走独立generic ProfileDomainMutation ABI，不伪造outcome ID。battle projection只在Loading从同一durable profile revision构建：青元attack写Damage Attack输入一次、长春maxHP沿用加法比例且L5低血恢复由Damage→Player phase6原子消费、Dayan暴击为百分点加法/拾取半径1.8..1.98/L5初始refresh3。Active不得热改。青元pierce workload、长春receipt、SkillDraft 20-call上限、残页reward owner与balance/device证据未闭合前保持BLOCKED/OPEN。
- Godot 4.7.1 VirtualJoystick callback ABI 固定为引擎signal `pressed()`与
  `released(input_vector: Vector2)`；项目adapter用direct `Callable.bind(epoch)`形成
  `_on_vj_pressed(callback_epoch: int) -> void`与
  `_on_vj_released(input_vector: Vector2, callback_epoch: int) -> void`，保存同一Callable
  身份用于精确disconnect。不存在独立VJ `canceled` signal；shield使用
  `_gui_input(event: InputEvent) -> void`，Host lifecycle使用
  `_notification(what: int) -> void`。`callbacks_armed`、`runtime_ingress_armed`与
  `shield_bank_service_enabled`必须分离：callbacks只表示initialize成功至teardown的adapter生命周期；
  runtime ingress只允许ACTIVE的新VJ press/generation/movement路径；shield bank service只允许
  LOCK_PENDING/FROZEN/RESUME_LOCKED的consumer-closed bank/FSM。状态组合固定为IDLE=`true/false/false`、
  ACTIVE=`true/true/false`、三种locked state=`true/false/true`、TERMINATED=`false/false/false`。
  ACTIVE进入普通pause、fatal cleanup或async safe-close时，必须先由InputSystem唯一私有
  `commit_consumer_closed()`以Godot主线程callback-observable atomicity提交完整
  `state=LOCK_PENDING、callbacks/runtime/service=true/false/true`，再调用shield STOP property setter，
  最后执行action/carrier clear。这里“原子”只允许连续写预分配typed primitive backing fields，区间内
  禁止函数调用、Godot property setter、signal、Callable与`await`；`ACTION_CLEAR_FAILED`保持LOCK_PENDING
  tuple并进入fault，不得回滚ACTIVE。IDLE load/fault/async cleanup始终保持`true/false/false`与
  PREACTIVE_DISCARD，绝不临时开启bank service；既有locked state保持`true/false/true`。
  teardown在任何filter setter、disconnect、remove_child或queue_free前先单一局部提交
  `TERMINATED + false/false/false`、清bank并撤销bank/choice/pending latch写权；随后同步callback
  只能追加suppressed diagnostic，不得重填latch或bank。
  UNARMED及callbacks已arm但Input仍为IDLE时，VJ保持不可命中，shield touch只执行
  `accept_event()`并走`PREACTIVE_DISCARD`，项目owned gesture/bank/action/carrier/
  pending-status零写；允许引擎Viewport handled/touch-focus变化。Host lifecycle虚回调
  在preactive期间只可写预分配、无需trusted tick的invalidation latch，确保
  APP_BACKGROUND/geometry事件不会静默丢失。任何battle input节点入树前，唯一GameRoot bootstrap
  恰调用一次`Input.set_use_accumulated_input(false)`并readback false；`project.godot`冻结
  `input_devices/buffering/agile_event_flushing=false`，GameRoot通过ProjectSettings只读验证。
  随后在BOOT的Home/Battle input target、consumer、callback、Input polling与`window_input` consumer
  均未激活时恰调用一次`Input.flush_buffered_events()`；flush中的项目Control callback、scene transition、
  choice/movement/gameplay effect为0，四movement action随后`pressed=false/raw=0`，但不宣称Godot
  InputMap/cache/pressed状态零修改。本局后续Input setter、flush与ProjectSettings runtime mutation均为0；
  initialize与每个ACTIVE `PRE_ACQUIRE`分别验证Input accumulated实时readback与ProjectSettings agile冻结值，
  任一漂移都以`INVALID_CONFIG`失败且不写Viewport。
  `IDLE→ACTIVE`与resume ACTIVE尾段按`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→release`
  阶段矩阵执行。true setter在bool置true前同步drop focus/leave/tooltip及可能的focused-Control
  `_gui_input`，所以setter-in-flight不宣称Viewport delivery=0。生产callback只可写typed invalidation
  latch/diagnostic且禁止直接注入InputEvent；hostile harness或引擎入口仍交付合法ScreenTouch时，loading
  由shield `accept_event()`后PREACTIVE_DISCARD且bank保持0，resume由STOP shield在既有
  `shield_bank_service_enabled=true`下按current-epoch FSM `accept_event()`并更新held bank，但callback不得写
  runtime/service两个enable字段，VJ/action/carrier/choice/movement generation/gameplay consumer/top-state
  effect仍为0。true返回/readback后的first observer发现held时以`HELD_ONLY_RETURN_TO_DRAIN`回drain，
  不继续ACTIVE或升级technical fault；press与terminal均在setter返回前完成、bank回空且其他条件clean时
  可继续。true返回/readback后到false调用前才由Viewport gate保证零投递。Input在
  `GATE_HELD`中执行filter activation guard并以单一局部提交原子置ACTIVE/runtime=true/shield-service=false，GameRoot再提交
  BATTLE_ACTIVE/consumer/foreground block。唯一私有release helper持有false setter call-site，
  reason只允许`ACTIVATION_SUCCESS`、`HELD_ONLY_RETURN_TO_DRAIN`、
  `LOAD_ABORT_OR_FAULT_CLEANUP`；pre-acquire failure release=0。其他节点禁止写gate；activation
  生产callback禁止调用`Input.parse_input_event`、`Input.flush_buffered_events`、
  `Viewport.push_input/push_unhandled_input`或等价直接注入入口；hostile runtime harness仅证明containment。
  true setter直接call-site只允许存在于支持`PRE_ACQUIRE/CLEANUP_PRE_ACQUIRE`的唯一acquire helper；
  cleanup取得成功后必须一直持有至handoff predicate成立，safe failure不得伪造release。GameRoot的APP_BACKGROUND resume gate必须以latest required/acked revision配对，每个新
  background revision都使旧Continue失效，duplicate同revision不重复确认。

- Player phase-6 terminal因果固定为：matching QUERY_CONSUME resolution publish后、任何DEFERRED_REMOVAL side effect前，GameRoot收齐Config列明producer对同一`ResolutionPublishTokenV1`的typed `FATAL/VICTORY/PAUSE/NONE` preview并冻结`TerminalPrecollectionViewV1`；Player只消费该不可变view决定VICTORY suppression/REVIVE/DEFEAT。phase7只seal同一precollection token与phase6 disposition，禁止首次发现VICTORY/FATAL或回滚已执行复活。
- Player复活PONR前必须完成17点current+swept enemy/hazard评分、完整clear tuple copy与固定原地binary-insertion sort，再通过`ReviveClearLifecycleResolverCapabilityV1`让Enemy/GameRoot预留全部N条journal row/checked sequence；row固定`participant_id=ENEMY`并计入ENEMY 303，PLAYER lifecycle contribution恒为0。DAMAGE fact row及bundle/motion/HUD/event one-shot capability全部reservation后，DAMAGE fact首次COMMITTED才是唯一PONR；点后不得分配row/sequence/capability，只由resolver按保存plan收敛journal，再按`bundle→motion?→HUD→transient?→critical PUBLISHED?→Node`提交。Player不持journal backing、不执行Grid/Pool副作用。
- Player real_t32 inward boundary helper只在Loading运行：float64 exact边界构造/readback最近binary32，越域时用符号感知IEEE-754 next-f32向域内推进并规范化`-0`；artifact必须是single-precision Vector2 ABI。Player gameplay root parent CanvasItem chain必须identity或由已验证ADR替代；selector后Node mirror/readback失败只fault，不回滚权威。RefCounted/PackedArray只读/独占用private backing、caller-owned copy-out与mutation-isolation证明，不返回alias。
- Player clear canonical key固定`{enemy_id,object_instance_id,spatial_handle_id,borrow_id}`，不假定enemy_id单字段唯一；n≤300 binary insertion sort的comparison/row-move各≤44,850，禁止Array/Callable/native sort。候选总序固定`safety rank(SAFE_UNCONSTRAINED>SAFE>UNSAFE)→surface score DESC→clear_count ASC→index ASC`，clear count不得压过安全/净空。
- 复活危险快照统一使用`ReviveHazardSnapshotV2`：`CIRCLE`按圆内及相切危险，`EXTERIOR_CIRCLE`按玩家完整足迹越出安全圆危险且内切安全；Player按shape计算signed surface clearance。V1、unknown shape或用大外接圆冒充外圆危险必须fail closed；总容量只能由Projectile、Enemy non-projectile、Boss与Stage contribution checked sum得出。
- Player presentation使用capacity=1 transient DAMAGE bank与capacity=2 retained critical ledger；`PlayerPresentationFrameV1`不是第三套A/B bank，而是matching已发布motion+HUD的allocation-free caller-owned copy-out join。所有consumer必须先join matching frame/winner再ack；未ack transient不得覆盖，critical REVIVE/DEATH保留至全consumer ACKED。Presentation host保持PAUSABLE且无独立process callback；REVIVE+pause只由既有persistent GameRoot ALWAYS control pump调用typed presentation-only advance完成预加载P0 cue，不得写gameplay。UNSAFE必须在frame/HUD/P0 fallback以非颜色危险形态区分；VICTORY winner抑制HIT/DEATH/REVIVE/pause表现但不删除统计fact。
- Player HP mutation固定唯一归Player：Config在Loading解析并冻结`resolved_starting_max_hp=base×(1+0.03×long_chun_level+(iron_body_pill?0.15:0))`；Active无maxHP热改。战斗内Longchun/Buff/RiskChoice只提交typed recovery intent，由唯一resolver在phase5聚合，phase6按`damage→lethal→仅非致命heal clamp`应用；致命同tick恢复抑制且不结转，实际HEAL使用canonical fact。
- BattleUI固定为consumer-only presenter与typed command adapter，不是phase participant且不拥有gameplay `_process/_physics_process`。HUD只能消费GameRoot同一sealed capture形成的跨owner revision vector；各source revision不要求数值相等，但逐项identity/revision/generation必须matching，禁止Node introspection与新旧拼帧。Choice触控由全屏ALWAYS `ChoiceGestureSurface`在UI→shield→VJ固定顺序中按touch identity消费；bank容量必须来自`SupportedTouchEventOrderingManifest.max_concurrent_touches`，owner committed、全部touch terminal且Input即时blocked predicate=false前不得完成pause reason。被动HUD/marker为IGNORE，interactive overlay为STOP；不得只靠z_index。Active/Paused节点、卡片、marker与damage label预实例化，动态文本/native allocation必须进显式allowlist与真机预算。
- Audio Feedback固定为consumer-only音频调度owner，不是phase participant；Active/control均由GameRoot显式presenter tick驱动。PLAYER_AUDIO继续使用stable order3/bit0b100，transient在STARTED/MERGED/EXPLICITLY_DROPPED/AUTHORIZED_SILENT处置后ACK，critical在播放或批准fallback完成后ACK；仅enqueue/play调用前不得ACK。预建bus/player/stream/callback，稳态禁load/new player/new Tween/Callable/容器增长；不要依赖Godot `max_polyphony`做优先级或缺bus自动回退Master。4.7.1 `AudioStreamPlayer.area_mask`默认0，当前不依赖Area bus override；pause/stream_paused/finished/device switch必须目标build验证。

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **gdtoolkit**(gdlint + gdformat)—GDScript 静态 linter/formatter。用于代码
  审计 AC 的静态守卫(注释免疫、空体判定、typed-return override 检测)。**R4 修正
  (2026-08-25,qa-lead 实测 gdtoolkit 4.5.0 确认)**:gdlint 本身**无自定义规则/插件 API**
  (`never-returning-function` 等规则在 DEFAULT_CONFIG 为注释行未实现),故 grep 不可靠处
  **不**由"gdlint/AST 规则"守卫——改由 `tools/ci/static_guard_check.py` 自定义 CI AST 脚本
  守卫(用 `gdtoolkit.parser` 库:`from gdtoolkit.parser import parser` → Lark Tree 遍历)。
  受影响 AC:AC-E19(3)/AC-E37/AC-E4-code(AC-E13 的 `func` 定义归 rg 正则、
  `callback_mode_process` 归场景审计)。非运行时依赖,仅 CI/本地工具链。安装:`pip install gdtoolkit`

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
