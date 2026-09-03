# SpawnDirector（玩家相对屏外生成与退场调度）

> **Status**: Designed / Full Review Pending
> **Author**: 用户 + Codex
> **Created**: 2026-09-02
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 怪潮持续从视野外压入，世界随玩家移动而延展
> **Scope**: MVP production contract；不冻结最终波次平衡表与Boss技能

## Overview

SpawnDirector 是所有敌人生成时机、类型选择、玩家相对生成位置、容量准入和普通敌人离屏退场的唯一 owner。它在每个 `SPAWN_INTENT` phase 读取最新已发布的 Player位置，以 Stage冻结的可见尺度构造屏外矩形环带，再使用 RNG 的固定消费协议生成 `SpawnContextCarrierV2`。EnemySystem只消费context并执行borrow/insert，不自行决定何时或何地刷怪。

本系统不把“无限地图”理解为无限实体或无限内存。全局仍受 Normal 298、Elite 4、Boss 1、ENEMY总数303及有限世界安全域约束；远离玩家且越过retention rect的Normal会无奖励退场，为新怪潮释放槽位。

## Player Fantasy

无论玩家向哪个方向移动，怪物都应从当前视野之外逐步压入，而不是从固定世界边缘、玩家脚下或镜头内突然出现。玩家改变路线后，后续怪潮方向跟着战场中心变化；已经入场的敌人仍按EnemySystem规则追击，不被镜头任意搬运。

退场是技术容量维护，不应被误读成击杀：没有死亡表现、经验、掉落、击杀数或奖励。Elite/Boss不能因离屏被静默删除。

## Detailed Rules

`SpawnStatus`是primitive int enum：`OK`、`OK_NOOP`、`SUPPRESSED_NO_POSITION`、`SUPPRESSED_CAPACITY`为success class；`INVALID_ARGUMENT`、`IDENTITY_MISMATCH`、`CARRIER_INVALID`、`CAPACITY_EXCEEDED`、`RNG_FAULT`、`POSITION_OUT_OF_RANGE`、`DEPENDENCY_FAILURE`、`WRONG_STATE`、`PHASE_ERROR`为failure class。只有Normal intent可返回suppressed success；mandatory intent相同条件须返回对应failure并进入统一fault路径。

### R1 — 唯一生成 owner 与phase

- SpawnDirector以required participant身份只在`SPAWN_INTENT`读写spawn/retire intent；无自主`_process/_physics_process`。
- required participant row固定为`{participant_id=SPAWN,role_id=SPAWN,stable_order=3,allowed_phases={SPAWN_INTENT},allowed_success_statuses={OK,OK_NOOP,SUPPRESSED_NO_POSITION,SUPPRESSED_CAPACITY},owner_contract_id=SpawnDirector/v1,owner_gdd_path=design/gdd/spawn-director.md,phase_row_id=SPAWN_PHASE_ROW_V1,required=true}`。两个suppressed status只允许Normal有损准入，mandatory同条件必须failure。
- phase开始时冻结 `SpawnAnchorViewV1={battle_instance_id,config_snapshot_id,tick_revision,source_player_position_revision,player_position,visible_half,inner_half,outer_half,retention_half}`。
- `player_position`只来自最新matching `PlayerMotionCommitCarrierV1.committed_position`；首tick使用Loading冻结的 `(0,0)`。禁止读取Player Node或Camera transform。
- tick T phase2的新位置从T+1的SPAWN_INTENT起可见，避免同tick读到两个anchor真相源。

### R2 — 屏外矩形环采样

- 生成域使用 Stage F3 的 `outer_rect-inner_rect interior`，相对冻结anchor派生。
- 为避免四角重叠造成概率偏置，矩形环拆成四个不重叠strip：TOP/BOTTOM覆盖outer全宽、厚度`ring_depth`；LEFT/RIGHT只覆盖inner高度、宽度`ring_depth`。
- 每个candidate固定消费3个RNG word：`strip_selector`按四strip面积加权，`axis_u`与`depth_u`映射到strip闭区间。边界归属按`TOP→RIGHT→BOTTOM→LEFT`稳定优先级去重。
- 生成对象的完整presentation bound必须与`visible_aabb`不相交，完整gameplay bound必须位于`world_safe_aabb`内；Config须验证`spawn_visibility_padding≥max_spawn_visual_bound`。不得clamp到可见边缘、重抽到屏内或读取渲染插值位置。
- `spawn_facing`为从spawn point指向anchor的单位向量；零向量理论不可达，若出现则`CARRIER_INVALID`。

### R3 — 固定尝试预算与阻挡

- 每个spawn intent最多8个candidate，RNG消费量固定为`8×3` word；即使第1个成功，余下word仍以discard方式推进，保证结果不因早停改变后续RNG流。
- `SpawnIntentBankV2.capacity=23`。合法最大值是`max(12 Wave Normal+9 Elite summon+1 Elite+1 Boss,12 Wave Normal+9 Elite summon+2 Boss summon)=23`：Boss的2-child cluster只在43200 Boss与21600/36000 fixed Elite row均已消费后的P2出现。可逐intent复用的`SpawnCandidateWorkspaceV1.capacity=8`，`NormalRetireIntentBankV1.capacity=300`；全部在Loading期精确定容，required±1均拒绝，单tick最多消费`23×24=552`个spawn-position RNG words。未来若允许12:00后新mandatory Elite/Boss或Boss child>2，必须先升级本容量。
- candidate依次检查：world domain → strict offscreen → Stage/hazard禁生区 → 与Player最小表面净空 → mandatory内容规则。
- Normal在8次均失败时返回`SUPPRESSED_NO_POSITION`并记录telemetry，当前战斗继续；Elite/Boss等mandatory intent无合法点时进入`ControlledGameplayFault`，不得屏内降级。
- 禁生区producer与容量尚未冻结前，相应production gate保持BLOCKED；不得以空默认掩盖。

### R4 — 容量准入与发布顺序

- ENEMY总cap=303，永久保留4 Elite+1 Boss槽；Normal `active+pending≤298`。该class hard cap从battle load即生效，不允许先发布300只Normal再可见退役让位。
- 准入顺序固定为：验证identity/type并计算cap结果 → 无论cap结果仍为该scheduled intent消费/验证或discard固定24 words → cap成功才Pool borrow candidate → Enemy reset/context bind → SpatialGrid pending insert → sync成功 → authority publish时接入可见SceneTree分支与active collection。cap-full不得用早停改变RNG cursor。
- fresh insert `CAPACITY_EXCEEDED`时Normal安全返池并记`suppressed_capacity`；mandatory intent撤销未发布candidate后fault。任何未获有效Grid handle的Enemy不得可见或可交互。
- 同一tick召唤intent、波次intent和Boss intent按 `{priority(BOSS>ELITE>SUMMON>NORMAL), producer_stable_order, summon_source_rank(ELITE_SUMMON=1,BOSS_SUMMON=2,NA=0), intent_sequence}`稳定排序；reserved槽不能被Normal抢占，同为SUMMON时Elite cluster先于Boss cluster，不能runtime抢槽改序。
- `EliteSummonClusterIntentV1`在准入前稳定展开三个child；三只鬼雾修士最坏展开9行。cluster采用0或3原子语义：任一child候选/容量失败时三者均不publish、72 words仍完整消费并聚合一次`SUMMON_DISSIPATED`；不得以priority静默裁掉已形成的Wave row来掩盖23-row intake不足。
- `BossSummonClusterIntentV1`只在Boss P2展开两个behavior0 child，使用summoner-local `[1.5,2.5]` ring与BOSS_SUMMON provenance；同样0或2原子，失败仍消费48 words、本周期不重试。该cluster为non-mandatory Normal压力，不得挤占Elite/Boss reserved槽或将cap-full升级为Boss缺失fault。

### R5 — `SpawnContextCarrierV2`

沿用EnemySystem冻结的10字段payload，不增加Dictionary：

`{behavior_id:int32,spawn_position:Vector2,spawn_facing:Vector2,spawn_time_seconds:float64,spawn_seed:int64,spawn_provenance:int32,source_choice_id:int64,stage_snapshot_id:int64,max_hp_multiplier:float64,base_damage_multiplier:float64}`。

- header/bank另绑定battle/config/tick/anchor position revision与intent sequence；payload保持Enemy carrier v2 contract。
- 普通/fixed/Boss intent的两个倍率必须为1.0且`source_choice_id=0`；RiskChoice mandatory intent必须逐字段复制matching risk identity、stage snapshot与1.30/1.30，不得由SpawnDirector重算或热改。
- `spawn_seed`由run seed、spawn stream id与intent sequence固定派生；position采样消费独立spawn-position stream，禁止与掉落/战斗RNG串流。
- `spawn_time_seconds`来自GameRoot固定tick时间，不读wall clock。

### R6 — Normal离屏退场

- 每个SPAWN_INTENT以同一anchor评估Normal中心是否在闭集`retention_rect`内；边界上保留，严格外侧进入retire intent。
- retire reason固定为`OFFSCREEN_RETIRE`：不写DEATH fact，不播放死亡，不增加kill/XP/drop/reward/record。
- retire走Enemy/GameRoot既有`LifecycleCommitJournal`：Grid remove → Pool unbind → release/retire，exact-once并计入ENEMY lifecycle上界。
- SPAWN owner四类orchestration contribution均为0；普通退役journal row固定归ENEMY，fresh spawn不伪装成phase-6 lifecycle row。共同字段`{required_role_id=SPAWN,owner_contract_id=SpawnDirector/v1,source_gdd_path=design/gdd/spawn-director.md,role_stable_order=3,field_stable_order=0}`，四行依次为`{LIFECYCLE_INTENT,0,kind_stable_order=1}`、`{FACT_COMMIT,0,2}`、`{PAUSE_CLOSURE,0,3}`、`{BLOCKING_CHOICE,0,4}`。
- Elite/Boss不适用本规则；召唤物是否按Normal退场由其class配置显式声明，禁止默认继承。
- 为避免camera高速/复活snap一次清退大量合法追兵，只有当Normal在当前anchor下严格越界才退场；不要求连续N tick。复活snap属于合法战场中心迁移，旧远端Normal退场是预期结果但不产奖励。

### R7 — Pause、resume、terminal与fault

- PAUSE_PENDING/Paused/Resume/Ending/Fault不生成新spawn或retire gameplay intent；drain只收敛既有journal。
- resume后首个SPAWN_INTENT使用resume publish后的最新Player位置与同一config snapshot。
- terminal winner已确定后不再产生普通波次；必须生成的结算表现不属于Enemy spawn。
- runtime anchor/ring/domain不一致、RNG revision错误、mandatory no-position、mandatory capacity miss或ghost publish均进入ControlledGameplayFault。

### R8 — 波次边界

- SpawnDirector拥有调度算法，但本版只冻结接口：`WaveScheduleViewV1`必须给出每个intent的`due_tick,behavior_id,class_code,count,producer_stable_order`。
- 当前MVP 0:00–12:00普通/精英节奏与12:00 Boss锚点来自主方案；精确每波数量、权重、压力曲线仍为`OPEN-BALANCE`，不得宣称已冻结。
- 波次“数量请求”不保证实际生成数量；Normal可能因容量或8候选均失败被有损抑制，telemetry必须区分原因。
- `FIXED_ELITE_1={due_tick=21600,behavior_id=6,class=ELITE,count=1}`与`FIXED_ELITE_2={due_tick=36000,behavior_id=7,class=ELITE,count=1}`由Elite GDD冻结；其余Normal波次仍`OPEN-BALANCE`。Summon child使用summoner-local ring `[1.5,2.5]`而非屏外四strip，但仍逐child固定8次/24 words、world/hazard/Player净空guard与完整footprint检查。
- `BOSS_FINAL={due_tick=43200,behavior_id=8,class=BOSS,count=1}`由Boss GDD冻结。43200后新普通Wave row为0，仅已有敌人和Boss P2召虫继续；该互斥是23-row容量证明的一部分，Config若出现违例必须拒绝。

## Formulas

### F1 — 四strip面积与采样

设inner half=`(ix,iy)`、outer half=`(ox,oy)`、`d=ring_depth`：

- `A_top=A_bottom=2×ox×d`
- `A_left=A_right=2×iy×d`
- `A_total=2A_top+2A_left`

`strip_selector`按上述面积区间选择；横向strip中`x=lerp(-ox,+ox,axis_u)`，`|y|=lerp(iy,oy,depth_u)`；纵向strip中`y=lerp(-iy,+iy,axis_u)`，`|x|=lerp(ix,ox,depth_u)`；最后加anchor并构造/readback real_t32。

### F2 — Spawn facing

`spawn_facing=normalize_f64(anchor-spawn_position)`后构造/readbackVector2；结果必须finite且长度满足EnemySystem契约。

### F3 — Retention

`outside = abs(enemy.x-anchor.x)>retention_half.x || abs(enemy.y-anchor.y)>retention_half.y`。严格大于才退场，等号保留。

## Edge Cases

1. Player持续移动：每tick生成环跟随最新published anchor，不锁世界原点。
2. 同tickPlayer移动：当前spawn使用旧anchor，下一tick使用新anchor。
3. 复活snap：下一tick新spawn围绕复活点，旧远端Normal可无奖励退场。
4. candidate位于visible边界：因padding>0，合法配置不可达；若发生则拒绝该candidate。
5. 8次无位置：Normal抑制，mandatory fault；不无限重试。
6. Normal容量298：普通spawn抑制，4个Elite与1个Boss预留不受影响。
7. Grid insert后sync失败：对象仍不可见，进入统一fault convergence，不发布ghost。
8. Normal恰在retention边界：保留；下一次严格越界才retire。
9. Elite/Boss越界retention：不退场，交其owner处理。
10. pause期间收到召唤：intent latch到resume后合法SPAWN_INTENT，identity/tick按GameRoot规则重绑。
11. RNG/anchor revision stale：整intent失败，不用“最新值”替换。
12. ring接近world limit：reachability violation，不clamp或屏内生成。

## Dependencies

| System | Contract | Status |
|---|---|---|
| GameRoot | SPAWN_INTENT lease、fixed tick、pause/terminal、journal与fault | Re-review Pending |
| Stage & Map | `StageSpatialConfigV2`、offscreen ring、retention与world domain | Re-review Pending |
| PlayerController | latest published committed position | Full Re-review Pending |
| Config/Data | cap、behavior、wave、RNG stream、schema/hash | Re-review Pending |
| RNG | fixed stream/word consumption与spawn_seed派生 | Re-review Pending |
| EnemySystem | 10-field `SpawnContextCarrierV2`、borrow/reset/insert、retire lifecycle | In Review |
| Object Pooling | candidate borrow与safe return | In Review |
| SpatialGrid | admission/insert/sync/remove与sparse world domain | Re-review Pending |
| Elite Enemies | fixed 21600/36000、三鬼修最多9 summon child与summoner-local ring | Designed / Full Review Pending |
| BossStateMachine | 43200 mandatory intent、P2 0/2 summon、预警与特殊越域处理 | Designed / Full Review Pending |

## Tuning Knobs

| Knob | Value | Owner |
|---|---:|---|
| `spawn_visibility_padding` | 1.0 | Stage |
| `spawn_ring_depth` | 4.0 | Stage |
| `spawn_candidate_attempts` | 8 fixed | SpawnDirector |
| `max_spawn_intents_per_tick` | 23 fixed | SpawnDirector/Config/Elite |
| `max_normal_retire_intents_per_tick` | 300 fixed | SpawnDirector/Config |
| `despawn_margin` | 12.0 | SpawnDirector/Stage |
| `normal_enemy_cap` | 298 | Config |
| `elite_reserved_cap` | 4 | Config |
| `boss_reserved_cap` | 1 | Config |

波次频率、敌人权重和压力曲线保持`OPEN-BALANCE`。

## Acceptance Criteria

- **AC-SD01 `[U]` anchor来源**：GivenPlayer carrier、Camera transform各自注入不同值，When运行SPAWN_INTENT，Then只使用matching published carrier；Node/Camera读取次数0。
- **AC-SD02 `[U]` ring采样**：Given固定RNG words与四strip边界，When执行F1，Then位置落在唯一strip、严格屏外、完整位于world domain，物理顺序变化不改变结果。
- **AC-SD03 `[U]` 固定RNG消费**：Given第1/第8次成功与8次全失败，When比较stream cursor，Then三者均精确推进24 words；后续intent结果一致。
- **AC-SD03b `[U][I]` 精确定容**：Givenintent/candidate/retire容量为required−1/required/required+1，WhenConfig build与满载tick执行，Then仅`23/8/300`成功；23 intents总消费552 words且容器identity/size不变，越界写与runtime growth为0。
- **AC-SD03c `[U][I]` Elite召唤cluster**：Given最多3个matching鬼雾修士同tick各召3只、Normal剩余槽0/2/3/9及第N个candidate失败，When展开并准入，Then每cluster只能0或3、全失败仍每child24 words、本周期重试0、一次聚合逸散；三cluster+12 Wave+Elite+Boss恰为23行。
- **AC-SD03d `[U][I]` Boss召唤与互斥容量**：GivenBoss P2的0/2 cluster、Normal剩余0/1/2、三鬼修cluster、43200前后schedule及非法12:00后mandatory row，When展开并准入，ThenBoss cluster只为0或2且失败仍48 words；两类合法23-row workload均通过，非法重叠在Config load拒绝而不是runtime越界。
- **AC-SD04 `[I]` tick时序**：GivenT phase2发生大位移，When观察T/T+1，ThenT spawn anchor不变、T+1逐bit等于新Player位置。
- **AC-SD05 `[I]` 严格屏外**：Given四边、四角、padding边界与多分辨率fixture，When对象首次authority publish，Then其完整可见bounds不与当前visible AABB相交；屏内闪现帧数0。
- **AC-SD06 `[I]` capacity/ghost**：GivenNormal 297/298与reserved 4 Elite+1 Boss、admission后竞争及Grid CAPACITY_EXCEEDED，When生成，Thencap正确、suppression reason正确；最坏`298+4+1=303`合法，可见集、owner active集、Grid set逐identity相等。
- **AC-SD07 `[I]` retire语义**：GivenNormal在retention内/边/外及Elite/Boss外侧，When评估，Then仅外侧Normal产生OFFSCREEN_RETIRE；DEATH/kill/XP/drop/reward/record与死亡表现均0。
- **AC-SD08 `[I]` lifecycle exact-once**：Given0/1/300 retire及第N步failure，Whenjournal收敛，Then每identity一row、Grid remove→unbind→release单调，重放无额外副作用。
- **AC-SD09 `[I]` pause/resume**：Givenpause期间普通波次与召唤intent，Whenresume，ThenPaused新增spawn/retire为0；合法latch只在首个resume后SPAWN_INTENT执行一次。
- **AC-SD10 `[U][I]` world limit**：Givenring/retention越域、anchor stale与mandatory no-position，When执行，ThenNormal不得屏内/clamp生成，mandatory走fault；wrap/recenter计数0。
- **AC-SD11 `[R][OPEN]` 零分配**：Given满载303敌人、每tick候选与retire scan，Whenrelease运行10000 tick，Thencarrier/backing identity固定，allocation/container growth/COW为0；缺观察工具则INCONCLUSIVE。
- **AC-SD12 `[M][OPEN]` 玩家体验**：Givenproduction资产与目标设备，When连续多方向移动并记录普通/精英/Boss入场，Then无可见凭空刷怪、固定世界边缘或奖励性退场误读；缺素材/真机/样本则INCONCLUSIVE。

## Open Questions

1. **OPEN-BALANCE**：完整WaveSchedule、类型权重与压力曲线未冻结。
2. **BLOCKED-HAZARD/BOUNDS**：Stage/hazard禁生区唯一producer/capacity及`max_spawn_visual_bound`未冻结。
3. **BLOCKED-BOSS-GDD**：Boss玩家相对入场、预警与mandatory no-position体验未冻结。
4. **OPEN-PERF**：8候选×高频spawn与303 retire scan的min-spec预算未测。
5. **FULL-REVIEW-PENDING**：本文为首次作者设计，尚未经过specialist + creative-director独立full review。
