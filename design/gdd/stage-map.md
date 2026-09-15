# Stage & Map（感知无限战场与有限坐标域）

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。BREAK顺序影响环境须按mission-objectives.md在下一tick消费已提交progress revision，snapshot保存已应用revision和待应用效果，禁止恢复后重放。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: In Review / Re-review Pending — 2026-09-02“感知无限、技术有限”正式方案已传播，须 clean-context 独立复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-09-02
> **Implements Pillar**: 玩家中心镜头下持续延展的战场空间，同时保留确定、可测、可安全失败的技术边界
> **Scope**: MVP production；世界坐标安全域、Camera2D 跟随、地表连续视觉、玩家相对生成几何与 `StageSpatialConfigV2`

## Overview

Stage & Map 正式采用“**感知无限、技术有限**”：镜头持续锁定玩家，地表视觉随镜头无缝延展，敌人由 SpawnDirector 在当前视野外环、相对玩家生成；底层仍使用足够大的有限世界坐标域、固定实体容量和明确的数值安全上限，不实现数学意义上的无限平面，也不使用世界坐标回绕。

Stage 只拥有静态安全域、相机可见尺度、视觉地表连续规则和玩家相对生成环的几何参数。它不决定波次、敌人类型、数量、奖励、伤害或生命周期。`StageSpatialConfigV2` 经 Config 在 BATTLE_LOADING 校验并注入 Stage、SpatialGrid、PlayerController 与 SpawnDirector；任何消费者不得重新解释这些字段。

- **玩法表象**：玩家看不到地图边界；移动多久，地表与怪潮都继续围绕玩家展开。
- **技术事实**：所有玩法中心仍落在 `[-world_safe_half_extent,+world_safe_half_extent]²`，默认半边长 `16_384`；全局绝对坐标硬上限仍为 `1_000_000`。
- **内存事实**：世界域大小不得决定 Grid bucket 数或地表节点数；SpatialGrid 使用固定容量稀疏索引，地表使用固定资源集循环显示。
- **非目标**：不做开放世界探索、持久化地形、程序化关卡内容、无穷坐标、浮点原点回绕或运行时 origin rebasing。

## Player Fantasy

玩家应感到自己一直在辽阔地表上突围，而不是被关在一个 22×40 的盒子里。镜头与角色保持稳定关系，持续移动不会撞上可见墙、黑边或停止刷新的地面；怪物从视野外压入，方向随玩家移动而变化，不再从固定世界边缘赶来。

“无限”只是一项体验承诺，不是数学承诺。正常配置下，30 分钟安全时长内最激进的合法移动、复活迁移、屏外生成和实体追赶都无法触及有限坐标域。若配置或实现破坏该证明，系统在开局前拒绝进入战斗；若运行时出现不可能的越域，进入 `ControlledGameplayFault`，不得用可见空气墙、瞬移回原点或坐标回绕掩盖。

## Detailed Rules

### R1 — 有限世界安全域

- 权威玩法世界域为闭集 `world_safe_aabb=[-H,+H]²`，MVP `H=world_safe_half_extent=16_384.0` world units。
- `spatial_max_abs_world_coord=1_000_000.0` 继续作为所有 checked float64/real_t32 输入的绝对硬上限；`H` 必须 finite、正数且 `H≤spatial_max_abs_world_coord`。
- 世界域不是玩家可感知的地图边界。Config必须证明
  `world_reachability_budget=player_speed_max×max_battle_duration_seconds+max_relative_runtime_extent+world_precision_guard≤H`。
- MVP 技术时长上限 `max_battle_duration_seconds=1_800`；它只限制合法 BattleConfig，不强制本局一定持续 30 分钟。
- `max_relative_runtime_extent`覆盖最大复活外圈、生成/retention外环与查询半径；`world_precision_guard=max_full_footprint_radius+max_single_tick_displacement+4×ulp_real_t32(H)`，只提供足迹/量化冗余，不是玩法margin。
- 不回绕、不镜像、不 modulo 世界位置、不运行时重置玩家坐标。越域不能降级为合法 gameplay。

### R2 — 玩家锁定相机

- Stage scene 拥有恰一个 battle `Camera2D` identity；persistent root `Window` 仍同时是 gameplay render Viewport 与 GUI input Viewport，不创建 per-battle SubViewport。
- 相机可见世界尺寸固定为 `camera_visible_world_size=(22.5,40.0)`；9:16 logical canvas 下半尺寸为 `(11.25,20.0)`。不同物理分辨率只做既有 stretch/safe-area 适配，不改变玩法世界尺度。
- Camera 跟随源只允许是 matching、已发布的 `PlayerMotionCommitCarrierV1.committed_position`。每个 phase-2 玩家位置提交后，Stage presentation driver 在 consumer-open 前把 camera center 更新到同一位置；普通移动无 dead-zone、无 look-ahead、无弹簧延迟。
- 初始化时 camera center 与 Player 初始位置同为 `(0,0)`；复活或其它合法位置跳变在 matching authority publish 后同帧 snap，不跨位置插值。
- Camera transform 是表现状态，不得回写 Player 权威位置、SpatialGrid 或 spawn anchor。SpawnDirector读取同一已发布 Player位置与冻结可见尺度自行派生外环，禁止读取渲染插值后的 camera Node transform。
- GameRoot 继续只校验并保存 non-owning camera引用，不创建相机、不重写 zoom/limit/enabled。Stage 是 camera position 的唯一项目 writer；任何第二 writer、第二 enabled battle camera、runtime reparent/make_current 或 nested Viewport 都是 topology fault。
- Stage assembly 继续匹配 `BattleViewportTopologyManifest`；cleanup 的 gate、detach、frame barrier、destination activation 与 `SAFE_TERMINAL_NONINTERACTIVE` 路径仍以 GameRoot 契约为准，本修订不改变其 ownership。

### R3 — 地表视觉连续延展

- `GroundContinuityRenderer` 只负责视觉：采用世界坐标 UV shader 或 Loading 期预创建的固定 tile 环循环复用，使 camera 可见区及 overscan 始终被覆盖。
- 地表视觉不得提供碰撞、可走区域、spawn 许可或 Grid bucket；视觉 tile 的复用、换位和 UV 相位不改变任何 gameplay identity。
- 运行时地表 Node/mesh/material/backing 数固定，稳态不得实例化、释放、扩容或加载资源。camera 跨 tile 边界时不允许出现缝隙、闪烁、纹理跳相或一帧空白。
- 若使用 tile 环，最小覆盖为 `visible_aabb.grow(ground_overscan)`，且在一次最大合法 camera 位移后仍覆盖下一帧；复活 snap 必须在同一呈现提交中重定位全部固定 tile，而不是逐帧追赶。
- 地表可重复纹理不得暗示世界边界；明显重复节奏属于美术/UX gate，不改变玩法正确性。

### R4 — 玩家相对的视野外生成环

- Stage 只冻结几何，SpawnDirector 拥有采样与时序。对某个已发布玩家位置 `P`：
  - `visible_half = camera_visible_world_size/2`；
  - `spawn_inner_half = visible_half + Vector2(spawn_visibility_padding,spawn_visibility_padding)`；
  - `spawn_outer_half = spawn_inner_half + Vector2(spawn_ring_depth,spawn_ring_depth)`；
  - `spawn_ring(P) = Rect(P,spawn_outer_half) \ interior(Rect(P,spawn_inner_half))`。
- 默认 `spawn_visibility_padding=1.0`、`spawn_ring_depth=4.0`，因此 inner half=`(12.25,21.0)`、outer half=`(16.25,25.0)`。Config须证明`spawn_visibility_padding≥max_spawn_visual_bound`；所有合法生成对象完整presentation bound不得与当前可见AABB相交。
- ring 随玩家位置派生，不存为世界固定区域，不随 camera 插值漂移。SpawnDirector 在 `SPAWN_INTENT` 使用 phase 开始时最新已发布 Player position；同 tick phase-2 后的位置只影响下一 tick spawn anchor。
- Normal 敌人离开 `retention_rect(P)=Rect(P,spawn_outer_half+despawn_margin)` 后由 SpawnDirector提交无奖励退场；默认 `despawn_margin=12.0`。Elite/Boss 不得按普通退场规则静默删除。
- 生成环或 retention rect 任一点若会越过 `world_safe_aabb`，说明 reachability/config proof 已被破坏；普通怪不得改为屏内生成，mandatory spawn 不得 clamp 到可见边缘，统一 fail closed。

### R5 — Boss 与特殊区域

- 旧的世界原点 `boss_region=[-4,4]²` 与“Boss 居中压场”不再是 production 契约。
- Boss/精英的入场位置同样相对当前 Player anchor，必须在视野外生成并先给出可感知预警；具体方向、预警时长、登场运动和是否允许特殊 reposition 归 BossStateMachine + SpawnDirector。
- 运行时毒雾或安全区可相对玩家/战斗事件定义，但不得重新建立固定世界 arena 边界。Boss P2已选择阶段事件点冻结anchor并使用`EXTERIOR_CIRCLE`，其hazard必须进入`ReviveHazardSnapshotV2`。

### R6 — `StageSpatialConfigV2` schema 与归属

`StageSpatialConfigV2` 字段精确为：

`{schema_version:int32=2, world_safe_half_extent:float64, max_battle_duration_seconds:float64, camera_visible_world_size:Vector2, spawn_visibility_padding:float64, spawn_ring_depth:float64, despawn_margin:float64, ground_tile_world_size:Vector2, ground_overscan:float64, cell_size:float64, max_query_cells_enumerated:int32}`。

- 删除 V1 的 `arena_size`、`walkable_region_polygon`、`walkable_area`、`boss_region_center`、`boss_region_half` 与 `index_margin`。V1 artifact 不得被 V2 consumer 接受。
- Config 拥有 schema、finite/domain、canonical hash 与 cross-field reachability 校验；Stage 拥有字段玩法语义；SpatialGrid消费世界域、cell size与查询枚举上限；SpawnDirector消费可见尺度与生成/退场参数。
- Config 派生只读 `StageWorldDomainViewV2={schema_version=2,battle_instance_id,config_snapshot_id,view_generation,world_safe_min:Vector2,world_safe_max:Vector2,camera_visible_world_size:Vector2,spawn_inner_half:Vector2,spawn_outer_half:Vector2,despawn_margin:float64,valid:bool}`。
- 所有 Vector2 必须绑定标准 single-precision export 的 real_t32实际位值；cross-field 计算使用固定 float64 顺序后构造/readback。double-precision template 必须重跑 golden 并提升 artifact identity。

### R7 — 注入、不可热改与 teardown

- BATTLE_LOADING 顺序保持 `Config+manifests → carriers/banks → Stage scene/Camera → Input → SpatialGrid → Pool → owners → identity preflight → BATTLE_ACTIVE`。
- Stage、Player、Grid、SpawnDirector读取同一 `config_snapshot_id` 的 V2 view；任一V1/V2混用、revision不匹配或派生值不一致都在开放 consumer 前失败。
- V2全部字段在 Active/Paused immutable。Resource编辑只影响下一场 battle；当前局不重新 init、不平滑迁移世界域、不热改 camera尺度或生成环。
- teardown先关闭 spawn/camera/ground writers，再按 GameRoot DAG失效 view、Grid handles、Pool与Stage child；persistent root Window保留。

## Formulas

### F1 — 世界安全域与可达性

`world_safe_min=(-H,-H)`；`world_safe_max=(H,H)`。

`max_player_travel=player_speed_max×max_battle_duration_seconds`

`max_relative_runtime_extent=max(2×revive_relocation_radius, length(spawn_outer_half)+despawn_margin+max_enemy_bound, max_query_radius+max_indexed_bound)`

`world_precision_guard=max_full_footprint_radius+max_single_tick_displacement+4×ulp_real_t32(H)`

`world_reachability_budget=max_player_travel+max_relative_runtime_extent+world_precision_guard`

合法配置必须满足所有中间值finite/non-negative且`world_reachability_budget≤H`。默认`H=16384`、`player_speed_max=4.5`、时长上限1800时，单纯玩家行程上界为8100，给相对运行包络和precision guard留出大于8000的余量；完整数值仍须待Enemy/Projectile/Skill上界进入Config后由artifact逐项证明。

### F2 — Camera 可见 AABB

`visible_half=camera_visible_world_size/2`

`visible_aabb(P)=[P-visible_half,P+visible_half]`

camera center必须逐bit等于matching Player committed position；渲染插值只可作用于明确的presentation child且不得成为spawn/Grid输入。

### F3 — 生成与退场矩形

`inner_half=visible_half+(padding,padding)`

`outer_half=inner_half+(ring_depth,ring_depth)`

`spawn_ring(P)=outer_rect(P)-interior(inner_rect(P))`

`retention_half=outer_half+(despawn_margin,despawn_margin)`

要求 `padding>0`、`ring_depth>0`、`despawn_margin≥0`；所有派生分量 finite 且严格递增。

### F4 — 地表固定覆盖

对 tile 方案：`tile_cols=ceil((visible_width+2×overscan)/tile_width)+2`，`tile_rows` 同理；Node总数固定为 `tile_cols×tile_rows`。`+2`用于一次边界跨越的双侧缓冲，不是运行时扩容许可。shader方案须以同一可见覆盖与UV连续 golden验收。

## Edge Cases

1. Player持续向同一方向移动：camera持续锁定，地表与spawn ring同步平移，无可见边界。
2. Player在单tick跨过地表tile边界：视觉覆盖连续，gameplay坐标不改变。
3. 复活发生位置跳变：Player、camera、ground在同一published revision snap；spawn anchor下一`SPAWN_INTENT`使用新位置。
4. 物理分辨率/安全区改变：Input/UI按其契约重建；world visible size不静默改变。
5. V2任一字段NaN/Infinity/非正或schema错误：BATTLE_LOADING fail closed。
6. reachability proof失败：`battle_ready=false`，不得缩短玩家移动或偷偷加空气墙。
7. runtime gameplay中心/完整bound越过world safe domain：当前phase失败并进入ControlledGameplayFault；不得clamp、wrap或继续索引旧位置。
8. spawn ring部分越域：normal spawn抑制并升级为配置故障；mandatory spawn直接fault；都不得改在屏内生成。
9. camera writer重复、第二active camera、reparent或revision drift：consumer保持关闭并走GameRoot fault cleanup。
10. tile/material缺失：Stage load失败；不得显示纯色空洞继续战斗。
11. Normal离开retention rect后又回入：若退场intent已提交则旧identity终止；只能通过新borrow/new handle重新进入。
12. Elite/Boss离开retention rect：不适用Normal退场；由其owner继续模拟或按正式特殊规则处理。

## Dependencies

| System | Direction | Contract |
|---|---|---|
| Config/Data | upstream | build/hash `StageSpatialConfigV2`、reachability与precision proof |
| GameRoot | orchestration | Stage assembly、topology manifest、phase/lifecycle与fault cleanup |
| PlayerController | upstream runtime | matching `PlayerMotionCommitCarrierV1`；camera与spawn anchor唯一位置源 |
| SpatialGrid | downstream | finite world domain、CELL_SIZE、sparse-query enumeration ceiling |
| SpawnDirector | downstream | player-relative offscreen ring、retention rect、domain guard |
| EnemySystem | downstream | 消费SpawnContext；不得arena clamp；Normal退场由SpawnDirector intent |
| BossStateMachine | downstream | 43200玩家相对入场；P2在进入phase break时冻结Player事件anchor，break结束后启用EXTERIOR_CIRCLE毒域；不依赖世界原点boss region |
| InputSystem/BattleUI | topology peer | 共用persistent root Window；不取得camera writer权 |

### Integration gates

- `StageSpatialConfigV2`尚未有runtime实现或Godot asset，故仅为静态设计证据。
- SpawnDirector本文同日建立GDD，仍需full review与实现证据。
- Enemy/Boss/Projectile/Skill上界未全部冻结前，F1完整reachability proof与`battle_ready`保持BLOCKED。
- Camera跟随、地表无缝与不同分辨率体验必须真机/可视回归，Markdown无法证明。

## Tuning Knobs

| Knob | MVP value | Owner | Notes |
|---|---:|---|---|
| `world_safe_half_extent` | 16384.0 | Stage/Config | 技术上限，不是玩家边界 |
| `max_battle_duration_seconds` | 1800 | Config | 安全证明上限，不是固定胜负时长 |
| `camera_visible_world_size` | (22.5,40.0) | Stage | 锁定玩法视野尺度 |
| `spawn_visibility_padding` | 1.0 | Stage | 保证严格屏外 |
| `spawn_ring_depth` | 4.0 | Stage | 屏外生成带厚度 |
| `despawn_margin` | 12.0 | SpawnDirector/Stage | Normal离屏保留距离 |
| `ground_tile_world_size` | (8.0,8.0) spike | Art/Stage | 仅视觉，生产值待素材 |
| `ground_overscan` | 2.0 spike | Stage | 须覆盖一次合法相机位移 |
| `cell_size` | 2.0 spike | SpatialGrid ADR | 生产值待benchmark |
| `max_query_cells_enumerated` | 262144 | Config/SpatialGrid | 超过时扫描固定active entries，不遍历巨大空域 |

## Acceptance Criteria

以下均为验收设计，不是已执行证据。

- **AC-SM01 `[U]` V2 schema**：Given V2合法fixture及逐字段缺失/多余/V1字段fixture，When Config build，Then仅精确V2字段集成功；V1与混合schema失败，Grid/Player/Spawn init调用数0。
- **AC-SM02 `[U]` 可达性证明**：Given边界值、Enemy/Projectile/Skill完整上界与checked overflow fixture，When执行F1，Then合法默认值`world_reachability_budget≤16384`；等号允许，超过/NaN/overflow均`LIMIT_EXCEEDED`且`battle_ready=false`。
- **AC-SM03 `[I][R]` camera锁定**：Given连续直线、对角、ZERO、复活snap各120帧，When读取published Player carrier与camera，Then每帧camera center逐bit匹配对应committed position，无dead-zone/look-ahead/第二writer；复活不出现中间旧位置帧。
- **AC-SM04 `[V][R]` 地表无缝**：Given水平/垂直/对角各连续移动至少10个tile跨度及一次最大复活snap，When录制camera输出，Then可见区覆盖率100%，无缝隙/黑边/一帧空白，tile/material identity总数固定且runtime create/free/resize为0。
- **AC-SM05 `[U][I]` 屏外环几何**：Given P取原点、四象限和接近reachability极值，When按F3构造ring并采样四strip边界/角点，Then所有点在outer rect内且严格不在visible AABB，最小可见间距≥1.0；world-fixed ring实现不得通过。
- **AC-SM06 `[I]` tick anchor时序**：Given tick T的SPAWN_INTENT后Player在phase2移动，When观察T与T+1 spawn context，ThenT只使用phase开始前已发布位置，T+1使用T新位置；不得读取Camera Node插值值。
- **AC-SM07 `[I]` Normal退场**：GivenNormal依次处于retention边界内、边界上、边界外，When SpawnDirector评估，Then前两者保留，外侧提交无奖励retire；Elite/Boss相同fixture不走Normal退场。
- **AC-SM08 `[U][I]` 无边界降级**：Given配置proof失败、runtime中心/完整bound越域及spawn ring越域，When执行，Then分别load fail或ControlledGameplayFault；clamp、wrap、传送原点、屏内spawn和继续使用旧bucket的计数均为0。
- **AC-SM09 `[I]` 稀疏内存独立性**：Given相同603 indexed entries分别分布在原点附近与跨度30000单位的位置，When初始化/同步Grid与ground，Then预分配容量、bucket slot上限和ground node数相同，不与world area或虚拟cell总数成比例。
- **AC-SM10 `[I]` topology/cleanup**：Given合法camera、第二camera、wrong Viewport、runtime reparent与cleanup handoff fixtures，When GameRoot执行load/active/cleanup，Then合法路径唯一writer/identity稳定；非法路径consumer=0并按既有ActivationCommitJournal收敛，persistent root Window不被销毁。
- **AC-SM11 `[S][I]` 跨文档stale guard**：Givenproduction GDD/registry，When扫描旧契约，Then不存在“固定22×40 arena边界”“相机一屏全显arena”“arena-relative spawn”“full_footprint_clamp”“boss世界原点region”作为生效规则；22.5×40只允许表示camera visible size。
- **AC-SM12 `[M][OPEN]` 体验验证**：Given目标移动设备与production ground asset，When玩家连续单向移动5分钟并经历普通潮/精英/Boss入场，Then无玩家报告可见边界或固定刷怪边，且重复纹理/眩晕/锁镜舒适度记录齐全；缺真机与素材则INCONCLUSIVE。

## Open Questions

1. **OPEN-PERF**：production `cell_size` 与稀疏bucket私有布局仍须SpatialGrid ADR + min-spec真机benchmark。
2. **BLOCKED-BOUNDS**：Enemy/Projectile/Skill完整 `max_relative_runtime_extent` 输入未全部冻结，F1 production proof不可关闭。
3. **OPEN-ART**：ground tile/world-UV素材、抗重复处理与低端机shader路径未冻结。
4. **BOSS-GDD-DESIGNED / INTEGRATION-BLOCKED**：Boss已冻结玩家相对入场、120t门、phase事件anchor与外圆毒域；仍待Spawn/Player/Damage V2集成、独立full review和runtime证据。
5. **RE-REVIEW-PENDING**：本次为跨文档作者修订；未经clean-context full review，不得把Stage或关联系统标记Approved/implementation-ready/runtime verified。
