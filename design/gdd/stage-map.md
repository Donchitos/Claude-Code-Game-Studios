# Stage & Map（单图竞技场与空间配置）

> **Status**: Draft — full-review revised（本轮 /design-review 8 项 BLOCKING 已闭环：arena 改竖屏 22×40、spawn_ring_depth→4.0、Section B 重写、boss 预警约束、AC 归属收窄、F4 上界修正、F3 per-axis、R6 误引修正）
> **Author**: 用户 + Claude Code agents
> **Created**: 2026-08-19
> **Last Updated**: 2026-08-19（full /design-review revision）
> **Implements Pillar**: 单图固定竞技场为 SpatialGrid/Spawn/Boss 提供确定的空间几何与坐标域
> **Scope**: MVP minimum；静态空间几何与 `StageSpatialConfig` schema；不定义波次/时长/奖励/运行时安全区规则

## Overview

Stage & Map 提供本局战斗唯一的静态空间几何：一张固定矩形竞技场的轴对齐包围盒（AABB）、原点居中的世界坐标系、全矩形可行走区、边界内侧出生环带与居中 Boss 子区。它把这些数据封装为 `StageSpatialConfig`，经由 `BattleConfigSnapshot` 在 BATTLE_LOADING 阶段一次性注入 SpatialGrid.init 与 SpawnDirector，作为 SpatialGrid 归格坐标系、越界容忍带 `index_margin` 与（候选）生产 `cell_size` 的权威输入源。Stage 不计算伤害、不决定波次节奏、不管理运行时安全区收缩（毒雾归 BossStateMachine/RiskChoice），也不拥有任何 gameplay Node 生命周期；它只冻结静态几何与数值域，使 300 实体同屏的空间查询坐标基准在开战前即确定、可复现且不依赖运行时魔法值。

- **一句话**：单图固定 arena 的 AABB + 居中坐标 + 静态可行走区 + 出生环带 + Boss 区，是 Config battle_ready 与 SpatialGrid.init 的几何输入源。
- **数据/校验边界**：Stage 拥有几何尺寸与区域数据；Config（`config-data-system.md` R7）拥有 `StageSpatialConfig` 的校验关系与数值域上限；SpatialGrid 消费经 Config snapshot 注入的 `StageSpatialConfig`，不直接读 Stage Resource。
- **不在本 GDD 范围**：生产 `cell_size` 不冻结（遵 Config R6/R7、SpatialGrid F3、J0 OPEN），仅持 spike 锚点 2.0 + 显式 ADR gate；波次/时长/奖励属 WaveConfig/Settlement；运行时安全区收缩（毒雾）属 BossStateMachine/RiskChoice。
- **MVP 拓扑**：1 张固定竞技场，不做循环拼接或世界坐标回绕（设计方案 16.1）。

## Player Fantasy

玩家不会直接看到"Stage 配置"，只会感到战场确定可信：怪潮始终从屏幕边缘内侧涌入而非凭空出现在身上、满屏妖兽下走位与命中判定的坐标基准稳定一致。

Stage 通过冻结 arena 为竖屏比例（`22×40`）使 spawn ring 贴近相机一屏全显的屏幕边缘内侧——**相机固定一屏全显 arena** 是 Stage 声明的 cross-system 约束（归 GameRoot/Camera 实现，见 Deferred Fantasy 表），spawn ring 因此几何对齐屏幕边缘而非游离屏外。Stage 真正独立交付的 fantasy 是**坐标基准一致**：无论怪潮多密，玩家移动、命中、拾取的归格原点与越界容忍带在开战前即冻结、可复现、不漂移。

"怪从屏幕边缘涌入""Boss 居中压场""走到边缘不外滑"的完整体验由 Stage 几何 + 下游（Camera/SpawnDirector/BossStateMachine/PlayerController）共同交付，Stage 不独自背其中任何一句（见 Deferred Fantasy 表）。技术异常时，系统宁可安全停止本局，也不靠放宽 arena 边界、静默收缩可行走区或临时改坐标域来掩盖 Stage 配置错误。

与 SpatialGrid/GameRoot 一致，Stage 的理想表现是"无感"——玩家只感到边界确定、坐标基准可信；玩家从不应察觉到坐标原点、归格基准或 `index_margin` 的存在。

**失败分级**（与 SpatialGrid Player Fantasy 的"正确性失败比性能失败更伤信任"对齐）：
- **空间正确性失败**（"怪穿墙 / Boss 出图 / 生成突袭"）：坐标基准或 spawn 越界错误，破坏"战场可信"，对玩家信任伤害最重。
- **空间性能失败**（"满屏怪时卡"）：`cell_size` / `index_margin` 选型不当致网格查询退化，属 SpatialGrid J 组 gate；Stage 仅提供几何输入，不独自背锅。

## Detailed Rules

### R1 — 单图固定竞技场 AABB 与居中坐标

- MVP 固定为一张竖屏比例竞技场：`arena_size = Vector2(22.0, 40.0)`（宽 22 / 高 40，竖屏 9:16 一屏全显），原点居中，故 `arena_min = Vector2(−11.0, −20.0)`、`arena_max = Vector2(11.0, 20.0)`（均由 F1 从 `arena_size` 派生，非 schema 字段）。`spatial_max_abs_world_coord = 1_000_000.0` 约束的是 `arena_min`/`arena_max` 各坐标分量的绝对值（即 `arena_half` ≤ 1_000_000，`arena_size` ≤ 2_000_000），不是 arena 维度；两条维度 `≥ spatial_min_cell_size = 0.01`（遵 Config R7 域）。
- **竖屏相机约束（cross-system，归 GameRoot/Camera 实现）**：相机固定一屏全显 arena（相机视口高度覆盖 40 高、宽度覆盖 22 宽）。9:16 竖屏一屏全显高 40 时可见宽 = 40×(9/16)=22.5 ≥ 22，故 arena 宽边 22 落在屏幕内、左右各余 ~0.25 单位——spawn ring 贴近屏幕边缘内侧而非游离屏外。此约束使 Player Fantasy 的"怪潮从屏幕边缘内侧涌入"几何可成立。相机方案（固定/跟随/缩放）的具体实现归 GameRoot/Camera GDD，落地时须反向引用本节声明其满足一屏全显约束，否则视为 fantasy 未交付。
- `arena_min` 是 SpatialGrid F1 归格基准原点：`cell_x = floor((index_x − arena_min_x) / CELL_SIZE)`、`cell_y = floor((index_y − arena_min_y) / CELL_SIZE)`。`arena_min` 由 F1 派生（`−arena_size/2`，原点居中固定），不由独立字段存储、不由运行时坐标推导。
- 拓扑为固定竞技场，MVP 不做循环拼接、世界回绕或镜像；查询半径跨越边界时仅返回边界内格子的实体（遵 SpatialGrid R7）。后续多地图/多境界属 Full Vision，不在本 GDD。
- arena AABB 是 `walkable_region`、`spawn_region`、`boss_region` 的公共外接矩形；任何子区域必须 `⊆ arena AABB`，否则 `StageSpatialConfig` 校验失败。

### R2 — 静态可行走区

- MVP 静态可行走区固定为全矩形，等于 arena AABB 的四角多边形，故 `walkable_area = 22.0 × 40.0 = 880.0`，满足 Config R7 的 `0 < walkable_area ≤ arena_w × arena_h`。
- walkable_region 归 Stage 拥有；`walkable_area` 作为 SpatialGrid F4 密度估算输入，不影响 F1 行列数或 F5 的 C（两者由 arena AABB 宽高决定，遵 SpatialGrid G2）。
- 运行时安全区收缩（如碧鳞蟒毒雾压缩可活动范围）**不属静态 walkable**：它是运行时 gameplay 状态，归 BossStateMachine/RiskChoice 在 inactive authority bank 中表达，Stage 不随战斗进度修改 `walkable_region`。若未来需要静态不可走障碍（固定墙/凹陷），必须先修订本节并定义多边形 schema 与 F4 相交面积，**且须同步修订 R5 的 `walkable_region_polygon` schema 契约**（当前 4 顶点/外接矩形==arena AABB 的约束无法表达内部障碍，带洞多边形需外环+内环或单环凹入顶点）——这是 schema breaking change，需提升 `schema_version`，不得在实现中静默改全矩形假设。

### R3 — 边界内侧出生环带

- `spawn_region` 为 arena AABB **内侧**环带：外边界 = arena AABB，内边界为 per-axis 矩形 `inner_rect`，`inner_rect_half_x = arena_half_x − spawn_ring_depth`、`inner_rect_half_y = arena_half_y − spawn_ring_depth`（per-axis 派生，详见 F3）。`arena_half_x = 11.0`、`arena_half_y = 20.0`，`spawn_ring_depth` 默认 `4.0`，故默认 `inner_rect = [−7, 7] × [−16, 16]`。
- **spawn 分布策略 Stage 层冻结约束**：spawn 分布须为 **arena-relative 固定方位**（spawn 点相对 arena AABB 边缘，不随玩家位置跟随）；玩家附近须有最小排除距离（spawn 点距玩家 ≥ `spawn_ring_depth`，即贴边时怪距玩家 ≥ 4.0 单位，使"涌入"有运动过程而非"瞬现"）。分布策略的其余细节（单波聚焦 vs 全周均匀、角落降权）归 SpawnDirector GDD。若下游采用 player-relative 跟随分布，则 spawn ring 几何对"从屏幕边缘涌入"fantasy 无贡献，须先修订本节约束——见 Open Questions OQ6。
- spawn 始终落在 AABB 内（`spawn_pos ∈ spawn_region ⊆ arena AABB`），因此 spawn 不产生越界，`index_margin` 无需覆盖 spawn overshoot；这使 `index_margin` 下界可基于已冻结的玩家/敌人移动 overshoot 冻结，而不依赖未定义的 spawn 越界量（见 R5/F5）。
- 生成位置由 SpawnDirector 在 `SPAWN_INTENT` phase 解析；本 GDD 只冻结几何区域与域约束，不冻结波次时间/数量/上限（属 WaveConfig/SpawnDirector GDD）。若 `spawn_ring_depth` 使 `inner_rect_half_x ≤ 0` 或 `inner_rect_half_y ≤ 0`（即环带在任一轴吞没整个 arena），校验失败。
- spawn ring 仅约束生成点；敌人生成后可移动至 arena 任意位置，其越界由 SpatialGrid R7 `index_margin` 与 EnemySystem 移动规则共同处理，不回退 spawn 位置。

### R4 — 居中 Boss 子区

- `boss_region` 为 arena 中心子矩形：`boss_region_center = Vector2(0.0, 0.0)`、`boss_region_half` 默认 `4.0`，故 `boss_region = [−4, 4]²`，面积 `64.0`，`⊆ arena AABB`。
- 碧鳞蟒（守阵妖兽）按设计方案 5.3 于 12:00 在 `boss_region_center` 生成；其两阶段表现、技能预警、毒雾安全区收缩归 BossStateMachine GDD，Stage 只冻结 Boss 生成的几何锚点。
- **boss_region 前期空窗预警约束（Stage 冻结约束，实现 defer BossStateMachine）**：boss_region 在 0:00–12:00 前期空窗（Boss 未生成）期间，BossStateMachine 须在 Boss 生成前 ≥ N 秒（N 由 BossStateMachine GDD 冻结）于 boss_region 发布可感知的预警/驱赶信号，使玩家不会在 12:00 站在 `boss_region_center` 脚下被贴脸扑咬。Stage 冻结此约束的**存在性**（"前期空窗不可对玩家隐形"），预警形式与时机归 BossStateMachine（OQ4）。此约束保护 Player Fantasy 的"Boss 居中压场"——防止 Stage 冻结居中 boss_region 同时无前期信号而惩罚玩家自然驻留中心。
- **前期预警几何地板（Stage-owned derived，供 BossStateMachine justify N 的下界参考）**：Stage 冻结 `boss_region_half=4.0` 与 `player_speed=4.5`（F5 已引用），故玩家从 `boss_region_center` 逃离 boss_region 边界所需最小时间为 `T_escape = boss_region_half / player_speed = 4.0 / 4.5 ≈ 0.89s`。Stage 据此声明 `N` 的**几何下界须 ≥ T_escape**（即 BossStateMachine 冻结的 `N` 不得小于 `T_escape ≈ 0.89s`，否则玩家即使即时反应也无法在 12:00 前离开 boss_region）。`N` 的完整值（含人因反应时间 `T_reaction` 与预警形式，即 `N = T_escape + T_reaction`）与预警形式归 BossStateMachine（OQ4）——Stage 只冻结 `T_escape` 几何地板，不冻结 `T_reaction`（人因参数，依赖预警形式，非 Stage-owned）。此几何地板让 BossStateMachine justify `N` 时有具体下界可对照，而非凭空取值。
- `boss_region` 与 `spawn_region` 的重叠关系见 F4 不重叠校验。MVP 要求 `boss_region ⊆ inner_rect`（默认 `boss_region_half=4.0`、center 居中 → Boss 区完全落在 spawn inner rect `[−7,7]×[−16,16]` 之内，per-axis 校验 `4≤7`（x 轴）∧ `4≤16`（y 轴），spawn ring 不覆盖 Boss 区）。若调整参数使 `boss_region ⊄ inner_rect`（含 center 非居中情形），Stage 校验须拒绝，由 SpawnDirector 显式处理，不在运行时静默。

### R5 — StageSpatialConfig schema 与归属

- `StageSpatialConfig` schema 字段固定为 8 个：`{arena_size: Vector2, walkable_region_polygon: PackedVector2Array, walkable_area: float, spawn_ring_depth: float, boss_region_center: Vector2, boss_region_half: float, cell_size: float, index_margin: float}`。
- **stored vs derived 二选一原则**（遵 creative-director 终审治理法 1）：任何一个量要么是 schema 存储字段（Config 校验其域）、要么是唯一派生量（唯一公式产出），不得两者皆是却无一致性校验。`arena_min`/`arena_max` **不入 schema**，统一由 F1 从 `arena_size` 派生（原点居中固定），所有消费者（含 SpatialGrid F1）按 F1 派生，不读独立字段；故 schema 无 `arena_min` 字段，消除双真相源。
- **walkable 一致性 invariant**：`walkable_area`（stored）与 `walkable_region_polygon`（stored）必须一致——Config build_snapshot 校验 `walkable_area == shoelace(walkable_region_polygon)`（浮点容差内），不一致 → `DERIVATION_ERROR`。MVP 全矩形下两者由 arena AABB 四角派生取等；未来非矩形障碍时 `walkable_area` 改从 polygon 派生（届时先修订 F2）。
- **walkable_region_polygon schema 契约**：MVP 固定为 4 顶点、逆时针（CCW）绕序、首尾不重复（不闭合多边形）、非自交、外接矩形 `== arena AABB`。顶点 Vector2 位值绑定标准导出的 real_t32（遵 Config R1 canonical hash：float 位值参与 hash，排除编辑器 instance ID/本地路径，只含稳定 UID/contract ID）；double-precision 构建须重跑 Stage golden 与 registry audit（与 SpatialGrid F2 同口径）。
- **归属边界**：Stage GDD 拥有上述数据的定义、默认值与玩法语义；Config（`config-data-system.md` R7）只拥有校验关系与数值域上限。Config 校验的 R7 子集为 `{arena_size, walkable_area, cell_size, index_margin}`（外加 walkable 一致性 invariant），约束为：两维度 `≥ spatial_min_cell_size`、四边绝对值 `≤ spatial_max_abs_world_coord`、`spatial_min_cell_size ≤ cell_size ≤ max(arena_w, arena_h)`、`0 < walkable_area ≤ arena_w × arena_h`、`walkable_area == shoelace(walkable_region_polygon)`、`index_margin ≥ index_margin_min`（`index_margin_min` 由 F5 派生、当前 `0.075`，与 AC-D3 一致；此处为语义下界校验，域下界 `≥0` 由 SpatialGrid init 再校验）且 `arena.grow(index_margin)` 不越世界域、`cols/rows = ceil(dim/cell_size) ≤ spatial_max_grid_axis`、`cols × rows ≤ spatial_max_grid_cells`。
- Stage 拥有的扩展字段（`walkable_region_polygon`、`spawn_ring_depth`、`boss_region_center`、`boss_region_half`）由 Stage GDD 定义其域约束（见 F2–F4）；Config 在 build_snapshot 时一并 checked 校验这些字段 finite、非负、子区域 `⊆ arena AABB`、polygon schema（4 顶点/CCW/不闭合/非自交/外接矩形==arena AABB），但不接管其玩法语义。
- 所有 real_t 输入先验证 finite 再进入 checked float64 derivation（遵 Config R7）。任何字段 NaN/Infinity/负数/子区域越界/polygon schema 违规 → `INVALID_ARGUMENT` 或 `LIMIT_EXCEEDED`/`DERIVATION_ERROR`，不得调用 `SpatialGrid.init`。

### R6 — Config→SpatialGrid 注入关系

- Stage 不被 SpatialGrid 或 GameRoot 直接读取 Resource；`StageSpatialConfig` 经 `BattleConfigManifest` 的 Stage reference 引用，在 BATTLE_LOADING 由 `ConfigRepository.build_snapshot(manifest, BATTLE)` 校验并打包进 immutable `BattleConfigSnapshot`（遵 Config R8）。
- GameRoot 按 R2 BATTLE_LOADING 固定顺序执行：`Config build(battle_ready) → 以同一 snapshot ID 预分配 carriers → SpatialGrid.init(config_snapshot, stage_spatial_config) → BattlePoolSet.init → lifecycle owner warmup → 全体 snapshot ID 一致性预检 → BATTLE_ACTIVE`。Stage 数据随 snapshot 一次性注入，不在 Active 期间重新读取 Resource。
- SpatialGrid.init 复制 snapshot 内的 `StageSpatialConfig` 值（含 `arena_size`、`cell_size`、`index_margin`、`walkable_region_polygon`）到只读内部状态，整个 Active/Paused 生命周期不再持有可变 Stage Resource 引用（遵 SpatialGrid R1、Config R8）。`arena_min`/`arena_max` 不读字段，由 F1 从 `arena_size` 派生。
- **PackedVector2Array 不可变语义**（遵 SpatialGrid R1/AC-F1）：GDScript 中 `PackedVector2Array` 是 **COW 值类型**（写时复制，写即 unshare）——`var poly_copy = stage.walkable_region_polygon` COW 共享底层数据，但对任一方的写触发 CowData unshare、writer 拿新 buffer、另一方保留原值（区别于 `Array` 的真引用语义：`Array` 的 `var b = a` 共享 buffer 且 mutation 互通，必须 `.duplicate()` 才能隔离）。SpatialGrid.init 对 `walkable_region_polygon` **应**执行真复制（`.duplicate()`）存入私有只读状态作为防御性约定（belt-and-suspenders，消除 COW 共享的推理负担；COW 本身亦提供等价隔离，`.duplicate()` 非绝对必须但为推荐防御实践）；Vector2 元素为值类型，`.duplicate()` 等价深复制。**注**：4.7 GH-113228（packed array 元素 setter 不触发脚本自定义 setter）仅影响有 `set` setter 的脚本属性副作用链，**不**改变 `PackedVector2Array` 本身的 COW 值语义——本 schema 的 `walkable_region_polygon` 无自定义 setter，GH-113228 不触发；Stage 域不依赖 4.7 任何破坏性变更。Vector2 字段（`arena_size`/`boss_region_center`）为值类型，直接赋值即拷贝。
- Stage 数据与 Pool/Grid 的 snapshot ID 必须一致；若预检发现不一致，GameRoot 进入 `ControlledGameplayFault`（遵 GameRoot R2）。
- `battle_ready` readiness 要求 `StageSpatialConfig` 完整存在且通过 R7 校验（遵 Config R9）；Stage reference 缺失或校验失败使 snapshot 停在 `foundation_ready`，不进入 BATTLE_ACTIVE。

### R7 — 不可热改与 teardown 重建

- Stage 几何在 `BATTLE_ACTIVE` 期间 immutable：arena/cell_size/index_margin/walkable/spawn/boss 区域均不可运行时修改。Resource 在 Active 中被编辑/替换不影响当前 snapshot（遵 Config R8），只标记 next battle rebuild。**next battle rebuild 标记的监听 owner 归 `ConfigRepository`**：它持有 `StageSpatialConfig` 引用并监听其 `changed` 信号置 dirty flag；SpatialGrid 不持有可变 Resource 引用（遵 R6）。下一场 BATTLE_LOADING 本就从 Resource 重建 snapshot，故"标记"在流程上冗余（重建天然拾取最新值），dirty flag 仅为审计/诊断用。**注（godot-specialist）**：Godot 4.x 的 `Resource.changed` 信号**不会**在代码侧直接赋值 `@export` 属性时自动触发——编辑器 inspector 路径可能经 UndoRedo/inspector 机制间接触发但不可靠地覆盖代码侧 mutation；若需 dirty flag 在代码侧编辑也置位，`StageSpatialConfig` 的 `@export` 须带 `set` 块显式 `emit_changed()`。因 dirty flag 流程上冗余（不影响 correctness，下一场重建天然拾取最新值），本 GDD 不强制 setter 模式，仅记录此引擎行为以避免实现者误以为 dirty flag 是可靠 invariant。
- 改 arena 或 cell_size 必须 `teardown → reset_to_inactive → init(new_stage_spatial_config)`（遵 SpatialGrid Edge Case 21）；因 Stage 经 snapshot 注入，实际路径是退出本局、下一场 BATTLE_LOADING 用新 StageConfig 重建。
- 运行时 `init` 重建热改请求的 `WRONG_STATE` 返回归 SpatialGrid（遵 SpatialGrid R7/AC-H6，warning rate-limit key 固定为 `(status,api,grid_epoch)`，每 epoch 最多一次）；Stage 在 Active 期间只保证 snapshot 逐字段不变（见 AC-F1），不 clamp/不静默替换 Resource；dev assert。
- Stage 不拥有 pooled Node 或 Grid handle；teardown 顺序仍由 GameRoot 按 `Grid teardown → Pool teardown → Grid reset → snapshot release` 执行（遵 GameRoot R8），Stage 只负责在下一场提供新几何。

## Formulas

本节定义 6 个公式，全部以已冻结 Stage 参数为输入并使用 checked float64 arithmetic；变量、输出范围与示例逐项给出。F6 引用 Config R7，Stage 不重定义。

### F1 — arena AABB 与居中 min

竞技场原点居中，AABB 由 `arena_size` 派生。

The arena_aabb formula is defined as:

- `arena_half_x = arena_size.x / 2`；`arena_half_y = arena_size.y / 2`
- `arena_min = Vector2(−arena_half_x, −arena_half_y)`
- `arena_max = Vector2(+arena_half_x, +arena_half_y)`

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 竞技场尺寸 | `arena_size` | Vector2 | x/y 均 `≥ spatial_min_cell_size` 且边绝对值 `≤ spatial_max_abs_world_coord` | 冻结 `(22.0, 40.0)`（竖屏比例） |
| 竞技场半边 | `arena_half_x/arena_half_y` | float | `≥ spatial_min_cell_size/2` | `arena_size / 2`；冻结 `(11.0, 20.0)` |
| 竞技场最小角 | `arena_min` | Vector2 | 各分量绝对值 `≤ spatial_max_abs_world_coord` | SpatialGrid F1 归格原点；冻结 `(−11.0, −20.0)` |
| 竞技场最大角 | `arena_max` | Vector2 | 同上 | 冻结 `(11.0, 20.0)` |

**输出范围：** `arena_min` 各分量 `∈ [−spatial_max_abs_world_coord, 0]`，`arena_max` 各分量 `∈ [0, spatial_max_abs_world_coord]`。任一步 checked 溢出或非 finite → `DERIVATION_ERROR`。

**示例：** `arena_size=(22,40)` → `arena_half=(11,20)` → `arena_min=(−11,−20)`、`arena_max=(11,20)`。

### F2 — walkable_area

MVP 全矩形可行走区面积。

The walkable_area formula is defined as:

`walkable_area = checked_mul(arena_size.x, arena_size.y)`

必须满足 `0 < walkable_area ≤ arena_size.x × arena_size.y`（全矩形时取等）。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 竞技场尺寸 | `arena_size` | Vector2 | 同 F1 | 冻结 `(22.0, 40.0)` |
| 可行走面积 | `walkable_area` | float | `(0, arena_size.x × arena_size.y]` | SpatialGrid F4 输入；冻结 `880.0` |

**输出范围：** `walkable_area > 0`。`≤ 0`、非 finite 或大于 AABB 面积 → `INVALID_BENCHMARK_INPUT`（遵 SpatialGrid F4 estimator 域），不除零、不输出 NaN。

**示例：** `arena_size=(22,40)` → `walkable_area = 880.0`。

### F3 — spawn ring 几何

边界内侧出生环带，per-axis 派生（支持非正方形 arena）。

The spawn_ring formula is defined as:

- `arena_half_x = arena_size.x / 2`；`arena_half_y = arena_size.y / 2`
- `inner_rect_half_x = arena_half_x − spawn_ring_depth`；`inner_rect_half_y = arena_half_y − spawn_ring_depth`
- `inner_rect = [−inner_rect_half_x, inner_rect_half_x] × [−inner_rect_half_y, inner_rect_half_y]`（闭集；其边界点归属 inner_rect 而非 spawn_region，arena AABB 边界点归属 spawn_region）
- `spawn_region = arena AABB \ inner_rect`（AABB 内、inner rect 之外的 per-axis 环带）
- `arena_area = checked_mul(arena_size.x, arena_size.y)`；`inner_rect_area = checked_mul(2 × inner_rect_half_x, 2 × inner_rect_half_y)`
- `spawn_ring_area = checked_sub(arena_area, inner_rect_area)`，且 `spawn_ring_area > 0` 校验（`≤ 0 → INVALID_ARGUMENT`）

合法性要求：`inner_rect_half_x > 0 ∧ inner_rect_half_y > 0`（即 `spawn_ring_depth < min(arena_half_x, arena_half_y)`），否则环带在某一轴吞没整个 arena。`inner_rect ⊆ arena AABB` 在 per-axis 派生下自动成立（`spawn_ring_depth > 0` 时）。若未来引入非矩形障碍，须先修订 polygon schema（见 R2）。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 竞技场半边 | `arena_half_x/arena_half_y` | float | 同 F1 | 冻结 `(11.0, 20.0)` |
| 环带深度 | `spawn_ring_depth` | float | `(0, min(arena_half_x, arena_half_y))` — tuning knob | 冻结默认 `4.0` |
| 内框半边 | `inner_rect_half_x/inner_rect_half_y` | float | `(0, arena_half_x/arena_half_y)` | `arena_half − spawn_ring_depth`；默认 `(7.0, 16.0)` |
| 环带面积 | `spawn_ring_area` | float | `(0, arena_area)` | 诊断/规划用；非玩法命中范围 |

**输出范围：** `inner_rect_half_x ∈ (0, arena_half_x)`、`inner_rect_half_y ∈ (0, arena_half_y)`。`spawn_ring_depth ≤ 0`、`≥ min(arena_half_x, arena_half_y)`、使 `spawn_ring_area ≤ 0` 或非 finite → `INVALID_ARGUMENT`，spawn ring 不退化。

**示例：** `arena_half=(11,20)`、`spawn_ring_depth=4` → `inner_rect=[−7,7]×[−16,16]`、`arena_area=880`、`inner_rect_area=14×32=448`、`spawn_ring_area = 880 − 448 = 432.0`。

### F4 — boss_region 几何

居中 Boss 子矩形与不重叠校验。

The boss_region formula is defined as:

- `boss_region_min = boss_region_center − Vector2(boss_region_half, boss_region_half)`
- `boss_region_max = boss_region_center + Vector2(boss_region_half, boss_region_half)`
- `boss_region_area = checked_mul(2 × boss_region_half, 2 × boss_region_half)`
- 不重叠校验（MVP，覆盖 schema 允许的非居中 `boss_region_center` 定义域）：`boss_region ⊆ inner_rect`，per-axis 显式包含——`|boss_region_center.x| + boss_region_half ≤ inner_rect_half_x ∧ |boss_region_center.y| + boss_region_half ≤ inner_rect_half_y`。此式对居中 `(0,0)` 与非居中 center 均成立；仅 `boss_region_half ≤ min(inner_rect_half)`（旧式）在非居中下不充分，不得单独使用。确保 spawn ring 不覆盖 Boss 区。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Boss 中心 | `boss_region_center` | Vector2 | `\|center.x\| ≤ inner_rect_half_x − boss_region_half ∧ \|center.y\| ≤ inner_rect_half_y − boss_region_half`（binding 约束，由不重叠校验推导） | 冻结 `(0.0, 0.0)` |
| Boss 半边 | `boss_region_half` | float | `(0, min(inner_rect_half_x, inner_rect_half_y)]` — tuning knob | 冻结默认 `4.0` |
| Boss 区域面积 | `boss_region_area` | float | `(0, arena_area)` | 诊断用；Boss 行为归 BossStateMachine |
| 内框半边 | `inner_rect_half_x/inner_rect_half_y` | float | F3 输出 | 不重叠校验输入 |

**输出范围：** `boss_region ⊆ arena AABB` 且（MVP）`boss_region ⊆ inner_rect`。任一不满足 → `INVALID_ARGUMENT`。`boss_region_half ≤ 0`、非 finite 或使 Boss 区越界 → 校验失败。

**示例：** `boss_region_half=4` → `boss_region=[−4,4]²`、`boss_region_area=64.0`；`inner_rect_half=(7,16)`，per-axis 校验 `0+4≤7`（x）∧ `0+4≤16`（y），不重叠校验通过。

### F5 — index_margin 下界

越界容忍带下界公式。因 spawn 在 AABB 内侧（R3），下界不含 spawn overshoot，只覆盖移动/knockback/形状扩张。

The index_margin_lower_bound formula is defined as:

`index_margin_min = checked_add(player_overshoot, max(enemy_overshoot_max, elite_charge_overshoot), knockback_max, max_enemy_bound)`

其中：
- `player_overshoot = player_speed / physics_ticks_per_second`；冻结 `player_speed=4.5`、`physics_ticks_per_second=60` → `0.075`
- `enemy_overshoot_max`：普通敌人单 tick 最大越界位移，EnemySystem GDD §4.6 已定义（`max(per-type base move_speed) × (1/60) × 1.35`，数值待 Config 调参）
- `elite_charge_overshoot`：精英冲刺单 tick 最大越界，EnemySystem GDD §4.6/§4.7 已定义（`max(per-type charge_speed) × (1/60) × 1.35`，spike 18.0→单 tick 0.405）；与 `enemy_overshoot_max` 取大者进入下界（并发时刻不同，非相加——F-1 fix 传播，第三轮复审 B-1）
- `knockback_max`：击退等强位移单 tick 最大越界，gated 到 Combat/DamageSystem GDD（未定义）
- `max_enemy_bound`：敌人 conservative shape bound 半径，EnemySystem GDD §4.6 已定义（`max(per-type shape_bound)`，数值待 Config 调参）

当前配置值沿用 `spatial` spike 锚点 `index_margin=2.0`（见 Config R6/Tuning Knobs G2b），安全高于已冻结下界 `0.075`；生产收紧值在 EnemySystem/Combat GDD 提供上述 gated 项后回填并重跑 SpatialGrid F3 sweep。

**PARTIAL 标注**：F5 为 4 项 `checked_add`（含 `max()`），当前 2/4 inputs（`knockback_max`、`elite_charge_overshoot` 数值）gated 未定义；`enemy_overshoot_max`/`max_enemy_bound` EnemySystem §4.6 已定义公式（数值待 Config）。下界 `index_margin_min=0.075` 系 gated 项在回填前按 `0` 处理的结果（即 `0.075 + max(0,0) + 0 + 0`）；`checked_add(undefined,...)` 语义上为 undefined，此处显式约定 "gated 项回填前视为 0"。gated 项回填（EnemySystem/Combat GDD）须触发 schema 级 invalidation（`battle_ready` cache 失效），并重跑 SpatialGrid F3 sweep，不得直接把 spike `2.0` 当生产承诺。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 玩家越界 | `player_overshoot` | float | `[0, +∞)` | 已冻结 `0.075` |
| 普通敌越界 | `enemy_overshoot_max` | float | `[0, +∞)` — gated 数值 | EnemySystem §4.6 已定义公式,数值待 Config |
| 精英冲刺越界 | `elite_charge_overshoot` | float | `[0, +∞)` — gated 数值 | EnemySystem §4.6/§4.7,与 enemy_overshoot_max 取大者 |
| 击退越界 | `knockback_max` | float | `[0, +∞)` — gated | Combat/DamageSystem 未定义 |
| 敌人形状半界 | `max_enemy_bound` | float | `[0, +∞)` — gated 数值 | EnemySystem §4.6 已定义公式,数值待 Config |
| 容忍带下界 | `index_margin_min` | float | `[0, +∞)` | checked sum 含 max();当前下界 `0.075` |
| 容忍带配置值 | `index_margin` | float | `[index_margin_min, min(MAX_ABS − max_abs_arena_x, MAX_ABS − max_abs_arena_y)]` | Stage 拥有；当前 `2.0` spike |

**输出范围：** `index_margin ≥ index_margin_min ≥ 0`，且 `arena.grow(index_margin)` 四边不越 `spatial_max_abs_world_coord`（遵 Config R7、SpatialGrid R1）。任一加法非 finite/超域 → `INVALID_ARGUMENT`/`INIT_LIMIT_EXCEEDED`。

**示例：** 当前只 `player_overshoot=0.075` 已知 → `index_margin_min=0.075`；配置 `index_margin=2.0 ≥ 0.075`，合法。EnemySystem 提供后若 `enemy_overshoot_max=0.05`、`knockback_max=0.1`、`max_enemy_bound=0.3` → `index_margin_min=0.525`，需回填并复核 `2.0` 是否仍为合理生产值或重跑 F3 sweep。

### F6 — cols/rows（引用 Config R7，不重定义）

Stage 不重定义行列数；引用 Config R7 / SpatialGrid F4 已冻结公式。

`cols = max(1, ceil(arena_size.x / cell_size))`

`rows = max(1, ceil(arena_size.y / cell_size))`

`grid_cells = checked_mul(cols, rows)`

必须满足 `cols/rows ≤ spatial_max_grid_axis = 4096` 且 `grid_cells ≤ spatial_max_grid_cells = 262_144`（遵 Config R7）。Stage 仅提供 `arena_size` 与（spike）`cell_size` 输入，不承担 grid 上限语义。

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 竞技场尺寸 | `arena_size` | Vector2 | F1 | 冻结 `(22.0, 40.0)` |
| 格子边长 | `cell_size` | float | `[spatial_min_cell_size, max(arena_size.x, arena_size.y)]` — spike `2.0` | 生产值 deferred 到 SpatialGrid F3 ADR |
| 行列数 | `cols/rows` | int | `[1, 4096]` | 引用 Config R7 |
| 总格数 | `grid_cells` | int | `[1, 262144]` | 引用 Config R7 |

**输出范围：** `cols/rows/grid_cells` 满足上述上限。Stage 提供的 `cell_size=2.0`（spike）→ `cols=ceil(22/2)=11`、`rows=ceil(40/2)=20`、`grid_cells=220`，仅为 fixture，非生产承诺。注意 `cell_size` 声称域下界 `[spatial_min_cell_size, ...]`=0.01 受 `grid_cells ≤ 262144` 隐式约束：对 22×40 arena，有效下界由 `ceil(22/cs)×ceil(40/cs) ≤ 262144` 决定（约 `cs ≥ 0.058`；精确验算：`cs=0.058`→`380×690=262200>262144` 拒绝，`cs=0.059`→`373×678=252894≤262144` 合法，故有效下界约 `0.0581`），声称域 0.01 会被 F6 自身上限拒绝为 `LIMIT_EXCEEDED`。

**示例：** `arena_size=(22,40)`、`cell_size=2.0` → `cols=ceil(22/2)=11`、`rows=ceil(40/2)=20`、`grid_cells=220`。

## Edge Cases

按来源分组。所有 outcome 为明确行为，无"优雅处理"等含糊表述。Stage 只拥有静态几何与域约束；运行时越界判定属 SpatialGrid，生成时机属 SpawnDirector，Boss 行为属 BossStateMachine。

### A. 边界与坐标域

1. **If** 实体因移动/击退越出 arena AABB 但点到 AABB 欧氏最短距离 `≤ index_margin`：**Then** 由 SpatialGrid R7 用 clamp 后位置归桶、真实 committed center 精确过滤；Stage 只提供 `index_margin` 值，不参与运行时判定。
2. **If** 实体越出 arena 且距离 `> index_margin`：**Then** pending insert 失败、active 在 sync 后 suspended 并从查询快照排除（遵 SpatialGrid R7）；Stage 不放宽 `index_margin` 来掩盖。
3. **If** `index_margin` 使 `arena.grow(index_margin)` 任一边越过 `spatial_max_abs_world_coord`：**Then** Config R7 返回 `LIMIT_EXCEEDED`，不 clamp 配置值，Grid init 保持 Inactive。
4. **If** arena 参数含 NaN/Infinity/0、负数，或任一维度 `< spatial_min_cell_size`：**Then** 返回 `DERIVATION_ERROR`/`LIMIT_EXCEEDED`，不调用 `SpatialGrid.init`、不分配部分网格、不使用魔法默认值。

### B. 子区域合法性

5. **If** `spawn_ring_depth ≤ 0` 或 `≥ arena_half`（环带吞没整个 arena 或退化）：**Then** 返回 `INVALID_ARGUMENT`，spawn ring 不退化为 0 或全 arena；SpawnDirector 不得在运行时绕过。
6. **If** `boss_region` 越出 arena AABB，或 `boss_region_half ≤ 0`、非 finite：**Then** 返回 `INVALID_ARGUMENT`，Boss 生成锚点不发布。
7. **If** `boss_region` 与 spawn ring 重叠（`boss_region ⊄ inner_rect`，即 `|boss_region_center.x|+boss_region_half > inner_rect_half` 或 y 同理——Boss 区伸出 spawn 内框，含居中与非居中 center 情形）：**Then** MVP 校验失败；SpawnDirector 必须显式处理，不在运行时静默让 spawn 覆盖 Boss 区或反之。
8. **If** `walkable_area ≤ 0`、非 finite 或 `> arena AABB 面积`：**Then** SpatialGrid F4 estimator 返回 `INVALID_BENCHMARK_INPUT`，不执行除法、不输出 NaN/Infinity；不影响已初始化 Grid 的查询正确性。

### C. 配置与热改

9. **If** `StageSpatialConfig` reference 缺失，或 R5 扩展字段（`walkable_region_polygon`/`spawn_ring_depth`/`boss_region_center`/`boss_region_half`）非法：**Then** snapshot 停在 `foundation_ready`，不达 `battle_ready`，GameRoot 不开放 BATTLE_ACTIVE 输入（遵 Config R9、GameRoot R2）。
10. **If** Active 中编辑 Stage Resource（arena/cell_size/index_margin/walkable/spawn/boss 区域）：**Then** 当前 snapshot 逐字段不变，只标记 next battle rebuild（遵 Config R8）；运行时热改请求 release 返回 `WRONG_STATE` + 限频 warning，dev assert。
11. **If** 需变更 arena 或 cell_size：**Then** 必须退出本局、下一场 BATTLE_LOADING 用新 `StageConfig` 重建（`teardown → reset_to_inactive → init(new_stage_spatial_config)`，遵 SpatialGrid Edge Case 21）；不允许单局内 `init` 重建或热替换坐标基准。

## Dependencies

### 上游/被注入契约

| Dependency | Stage 使用方式 | 当前状态 |
|---|---|---|
| Godot Resource/PackedScene | `StageConfig` 作为 typed `.tres`，含 `StageSpatialConfig` 字段，经 manifest 引用 | 引擎已固定；Resource class 实现未开始 |
| Config/Data | Stage 经 `BattleConfigManifest` 引用打包进 immutable `BattleConfigSnapshot`；Config R7 校验 Stage 字段域上限 | `design/gdd/config-data-system.md` Draft；R7 Stage 校验关系已冻结 |
| GameRoot | BATTLE_LOADING 按 R2 顺序注入 Stage 数据到 `SpatialGrid.init(config_snapshot, stage_spatial_config)` | `design/gdd/game-root-scene-flow.md` Draft |

### 下游消费者

- **SpatialGrid**：`init(config_snapshot, stage_spatial_config)` 消费 `arena_min`/`arena_size`/`cell_size`/`index_margin`；Stage 是归格坐标基准与越界容忍带输入源。`design/gdd/spatial-grid.md` core contract 已冻结；Stage 不参与运行时归格/查询判定。
- **SpawnDirector**：消费 `spawn_region`（边界内侧环带）决定生成点；GDD 未设计。Stage 只冻结几何区域，不冻结波次时间/数量/上限（属 WaveConfig/SpawnDirector）。
- **BossStateMachine**：消费 `boss_region_center`/`boss_region_half` 作为碧鳞蟒生成锚点；GDD 未设计。Boss 两阶段表现、技能预警、毒雾安全区收缩归其拥有，不在 Stage。
- **EnemySystem**：未来提供 `enemy_overshoot_max`/`knockback_max`/`max_enemy_bound`，回填 F5 `index_margin` 下界与生产收紧值；GDD 未设计。当前 `index_margin=2.0` 为 spike 锚点，下界仅 `player_overshoot=0.075` 已知。
- **PlayerController**：玩家移速 `4.5` 提供 `player_overshoot` 输入（`4.5/60=0.075`）；GDD 未设计。

### Integration gates

- Stage 几何与 `StageSpatialConfig` schema 已冻结；但生产 `cell_size` 与 `index_margin` 收紧值仍依赖 SpatialGrid F3 benchmark + min-spec 真机（遵 SpatialGrid J0 OPEN）。
- SpawnDirector/BossStateMachine/EnemySystem GDD 未完成前，spawn 时机、Boss 阶段切换、enemy bound 项仍为 gated；Stage 不在实现中猜值或用本地默认覆盖 snapshot（遵 Config R8）。
- F5 `index_margin` 下界的 `enemy_overshoot_max`/`knockback_max`/`max_enemy_bound` 三项缺失使 `index_margin` 生产值无法完全冻结，但不阻塞 Stage 静态几何与 spike 配置的正确性。

### Deferred Fantasy 表（Player Fantasy 依赖但 Stage 不独自拥有的机制）

Section B 的三句空间 fantasy 由 Stage 几何 + 下游共同交付。为避免"空头承诺"，此处显式点名 owning GDD 与 defer 契约，并标注 Stage 已冻结的耦合约束；Stage 不在实现中猜值或本地默认化：

| Fantasy 句 | 依赖机制 | owning GDD | defer 契约 |
|---|---|---|---|
| "怪潮从屏幕边缘内侧涌入而非凭空出现在身上" | 相机/视野（相机固定一屏全显 arena）+ spawn 分布策略（arena-relative 固定方位） | GameRoot/Camera（相机）；SpawnDirector（分布策略） | **Stage 已冻结耦合约束**：arena 竖屏比例 22×40 使 spawn ring 对齐相机一屏全显的屏幕边缘内侧（R1）；spawn 分布 arena-relative 固定方位 + 玩家最小排除距离（spawn 距玩家 ≥ 4.0，R3）。相机实现归 GameRoot/Camera GDD，须反向引用本节声明满足一屏全显；分布策略细节归 SpawnDirector。下游若改相机为跟随或分布为 player-relative，须先修订 R1/R3 约束。 |
| "走到边缘不外滑" | 玩家边界 clamp（arena AABB 物理约束玩家 clamp 还是碰撞墙） | GameRoot/PlayerController | walkable_region 是"可行走区"非"碰撞墙"；玩家是否被 clamp 在 AABB 内归 GameRoot/PlayerController GDD。Stage 不独自背"不外滑"承诺。 |
| "Boss 居中压场" | Boss 登场演出/预警/驱赶（boss_region 0:00–12:00 前期空窗） | BossStateMachine | **Stage 已冻结耦合约束**：boss_region 前期空窗预警约束（R4，Boss 生成前 ≥ N 秒须有预警/驱赶信号），防止玩家 12:00 贴脸扑咬。Boss 两阶段表现、预警形式、时机、"移动后是否回中"归 BossStateMachine GDD（OQ4）。Stage 不独自背"压场"持续行为承诺。 |

上述三机制在 owning GDD 落地前为 gated；Stage 在 Open Questions 已记录 OQ3/OQ4。下游 GDD 完成时须反向引用本表，否则触发跨文档一致性失败（遵 design-docs 规则）。

### 跨文档一致性

依 design-docs 规则"if system A depends on B, B's doc must mention A"：
- 本 GDD 已列出上游 Config/GameRoot 与下游 SpatialGrid/SpawnDirector/BossStateMachine/EnemySystem/PlayerController 契约。
- `config-data-system.md`（R6/R7 Stage 校验关系、Dependencies 上游表）与 `game-root-scene-flow.md`（R2 BATTLE_LOADING 顺序、Dependencies Stage 行）已引用 Stage 契约；本 GDD 完成后，建议把这两份依赖表中"Stage | GDD未设计"状态格更新为 Draft 指向 `design/gdd/stage-map.md`（仅状态同步，不推翻已冻结契约）。
- 待 SpawnDirector/BossStateMachine/EnemySystem GDD 设计完成时，须反向引用 `stage-map.md` 并说明所消费的 `StageSpatialConfig` 字段，否则触发一致性失败。
- **本轮 revision 待 propagate 项**（arena 40×40→22×40、spawn_ring_depth 2.0→4.0 连锁示例值）：`spatial-grid.md` F4 的 `arena_walkable_area`/`walkable_region` 仍标"外部 TUNING KNOB / 关卡设计未定义 / 生产值待定"，须更新为指向 stage-map 已冻结值（walkable_area=880.0、arena=22×40）并补 `referenced_by: stage-map.md`；`config-data-system.md` F4 示例 `arena=40×40,cell_size=2` 须更新为 `22×40`。这两份 GDD 的示例值 propagate 属 `/propagate-design-change` 范畴，本轮在 stage-map 记账，避免一次性改 4 份 GDD 超出本轮 scope。

## Tuning Knobs

Stage 拥有的旋钮按"数据 owner / 变更规则"分类。`cell_size` 与 `index_margin` 的生产值显式 deferred，不在本 GDD 冻结为玩法承诺。

| Setting | Type | Owner | Baseline | 安全范围 | 影响维度 | 变更规则 |
|---|---|---|---|---|---|---|
| `arena_size` | Vector2 | Stage（关卡设计） | `(22.0, 40.0)` | x/y 均 `≥ spatial_min_cell_size`，`arena_min`/`arena_max` 分量 `≤ spatial_max_abs_world_coord`；MVP 竖屏比例（22:40）以对齐相机一屏全显 | 坐标域、归格基准、F4 密度、屏幕边缘对齐 | 退出本局 + 新 StageConfig revision；重跑 Config R7 + SpatialGrid F3/F4 |
| `spawn_ring_depth` | float | Stage（关卡/Spawn） | `4.0` | `(0, min(arena_half_x, arena_half_y))` = `(0, 11)` | spawn 分布；玩家贴边最小生成距离；与 `index_margin` 解耦 | 下一 battle 随 revision；不单局热改 |
| `boss_region_half` | float | Stage（关卡/Boss） | `4.0` | `(0, min(inner_rect_half_x, inner_rect_half_y)]` = `(0, 7]` | Boss 生成锚点范围 | 下一 battle 随 revision；与 BossStateMachine 协同 |
| `boss_region_center` | Vector2 | Stage | `(0.0, 0.0)` | `\|center.x\| ≤ inner_rect_half_x − boss_region_half ∧ \|center.y\| ≤ inner_rect_half_y − boss_region_half` | Boss 生成点 | 下一 battle 随 revision |
| `index_margin` | float | Stage（存储与值）；下界由 SpatialGrid F5 派生，输入 gated 到 EnemySystem/Combat/PlayerController | `2.0`（spike） | `[index_margin_min, min(spatial_max_abs_world_coord − arena_half_x, spatial_max_abs_world_coord − arena_half_y)]` | 越界容忍带、SpatialGrid 查询边界 | 下一 battle 随 revision；F5 下界 gated 项回填后重跑 SpatialGrid F3 sweep |
| `cell_size` | float | SpatialGrid（F3 ADR 输出，Stage schema 存储槽） | `2.0`（spike） | `[spatial_min_cell_size, max(arena_size.x, arena_size.y)]`（有效下界受 `grid_cells ≤ 262144` 隐式约束） | 网格行列 / 格内候选密度 | **生产值 deferred 到 SpatialGrid F3 ADR + J0**；本 GDD 不冻结生产值，Stage 不拥有其调谐权，仅持 schema slot 与 spike 锚点 |

### 非旋钮的 frozen / derived 量（仅列出，不调谐）

- `arena_min` / `arena_max`（F1 derived from `arena_size`，原点居中固定，不是独立旋钮）
- `walkable_area`（F2 derived，全矩形时 `= arena_size.x × arena_size.y`，不由独立值设定）
- `inner_rect_half_x` / `inner_rect_half_y`（F3 derived，`arena_half − spawn_ring_depth` per-axis）
- `index_margin_min`（F5 derived lower bound，非魔法值，随 gated 项回填而变）
- `cols` / `rows` / `grid_cells`（F6 引用 Config R7，非 Stage 旋钮）

### 关键说明

- `arena_size` 是 Stage 唯一真正冻结的玩法几何（`(22.0, 40.0)` 竖屏比例）；`spawn_ring_depth`/`boss_region_half` 为 spike 默认值，可在下一 battle 随 revision 调整。注意：`arena_size` 亦受 SpatialGrid J0 真机检验——若 J0 证明任何合法 `cell_size` 下 `arena=22×40` 无法满足 16.6ms 子预算，需走关卡 revision（改 arena）而非纯 perf ADR（改 cell_size），两条路径都记录在此。arena fallback 须注意密度非线性：放大 arena（如 22×40→28×50）降密度但削弱割草爽感且需 creative-director 联签；缩小 arena（如 22×40→16×30）严格恶化密度（`880/480≈1.833` 倍，即 16×30 下同数量敌人密度提升约 83%，与 fallback 目的相反），不应作为 perf fallback 方向。
- **双重 2.0 巧合**：当前 `index_margin=2.0`、`cell_size=2.0` 数值相等（`spawn_ring_depth=4.0` 已解耦，不再参与巧合），系 spike 阶段巧合，**非耦合约束**。`index_margin==cell_size` 使越界容忍带恰 1 格宽、边界格候选密度达峰值（correctness 已被 SpatialGrid R5/R7 精确距离过滤覆盖，perf 边界聚集归 SpatialGrid J4 adversarial case）；`spawn_ring_depth=4.0` 在 cell_size=2.0 下使生成环 2 格厚。注意 `index_margin` 与 `cell_size` 在查询成本上隐含耦合（margin 带以格计宽度 `= ceil(index_margin/cell_size)` 随 cell_size 反向缩放），二者非完全独立调谐轴；`spawn_ring_depth` 与 `cell_size` 在 spawn 环密度上同样耦合（环厚度以格计 `= ceil(spawn_ring_depth/cell_size)`）。调谐任一旋钮须复核联合密度。
- `cell_size` 显式标注**生产值不属于本 GDD**：遵 SpatialGrid F3 ADR + J0 真机 benchmark 选定，Stage 只持 schema slot 与 spike 锚点 `2.0`；不得未经 benchmark 直接把 `cell_size` 设为 `max_query_radius` 或任意值。
- `index_margin` 的安全范围下界是 derived `index_margin_min`（当前 `0.075`，仅含已冻结 `player_overshoot`），不是魔法百分比；其 gated 项（`enemy_overshoot_max`/`knockback_max`/`max_enemy_bound`）回填后须重跑 SpatialGrid F3 sweep，不能直接把 spike `2.0` 当生产承诺。
- 所有 Stage 旋钮均不可在 `BATTLE_ACTIVE` 期间热改（遵 Config R8、R7）；变更路径统一为退出本局 → 下一场 BATTLE_LOADING 用新 StageConfig revision 重建。

## Acceptance Criteria

Given-When-Then 格式。Logic 校验用 GDUnit4 debug unit/integration；当前仓库尚无 Godot 工程，因此为验收设计而非已执行证据。Gate 多数 BLOCKING；真机性能归 SpatialGrid J0 OPEN，不在本 GDD 单独 gate。

### A. arena AABB 与坐标域（R1, F1）

**AC-A1 arena AABB golden + 居中不变式**
- Given: StageConfig `arena_size = (22.0, 40.0)`
- When: 按 F1 派生 arena AABB
- Then: `arena_min = (−11.0, −20.0)`、`arena_max = (11.0, 20.0)`，逐字段精确；满足 `arena_min`/`arena_max` 各分量 `≤ spatial_max_abs_world_coord`、维度 `≥ spatial_min_cell_size`；且居中不变式 `arena_min == −arena_max`（逐分量）成立（即 `arena_min == −arena_size/2 ∧ arena_max == arena_size/2`，原点居中固定）；该 `arena_min` 作为 SpatialGrid F1 归格原点输入（归格公式 `cell_x=floor((x−arena_min_x)/CELL_SIZE)` 与边界 clamp 的运行时行为归 spatial-grid.md AC，本 GDD 仅验证 Stage 拥有的派生值正确性，不重复 SpatialGrid 归格/clamp AC）
- 验证: golden value unit | Gate: BLOCKING

**AC-A2 arena 非法输入 fail-fast**
- Given: arena_size 分别含 NaN/Infinity、0、负数、维度 `< spatial_min_cell_size`、边 `> spatial_max_abs_world_coord`
- When: build_snapshot 校验 StageSpatialConfig
- Then: 返回 `DERIVATION_ERROR`/`LIMIT_EXCEEDED`；不调用 `SpatialGrid.init`、不分配部分网格、不使用魔法默认值；旧 snapshot 保持
- 验证: boundary table test | Gate: BLOCKING

### B. walkable 与 F4 域（R2, F2）

**AC-B1 walkable_area 域**
- Given: 全矩形 walkable_region=arena AABB
- When: 计算 walkable_area
- Then: `walkable_area = 880.0`，满足 `0 < walkable_area ≤ arena_w × arena_h`（取等）；若 area `≤ 0`/非 finite/`> AABB 面积` → `INVALID_BENCHMARK_INPUT`，不除零、不输出 NaN/Infinity
- 验证: formula unit + boundary test | Gate: BLOCKING

### C. spawn ring 与 boss 区（R3/R4, F3/F4）

**AC-C1 spawn ring 内侧不越界**
- Given: `spawn_ring_depth=4.0`、`arena_half=(11,20)`、`inner_rect_half=(7,16)`
- When: per-axis 派生 spawn ring，并对固定 fixture 点集逐点判定 `∈ spawn_region`：4 边中点 (±10,0)/(0,±19)、4 角内侧 (±10,±19)、inner_rect 边界点 (±7,±16)、inner_rect 内部点 (0,0)
- Then: `inner_rect=[−7,7]×[−16,16]`（闭集，边界点归 inner_rect）；8 个环带 fixture 点全部 `⊆ arena AABB ∧ ∈ spawn_region`；inner_rect 边界点与内部点（如 (0,0)）`∉ spawn_region`；`spawn_ring_depth ≤ 0` 或 `≥ min(arena_half_x, arena_half_y)=11` 或使 `spawn_ring_area ≤ 0` → `INVALID_ARGUMENT`，spawn ring 不退化为 0 或全 arena
- 验证: 表驱动 geometry unit（固定 fixture 点集，确定性）| Gate: BLOCKING

**AC-C2 boss_region 几何**
- Given: `boss_region_center=(0,0)`、`boss_region_half=4.0`
- When: 派生 boss_region
- Then: `boss_region = [−4, 4]²`、`boss_region_area = 64.0`、`⊆ arena AABB`；`boss_region_half ≤ 0`/非 finite/使 Boss 区越界 → `INVALID_ARGUMENT`
- 验证: geometry unit | Gate: BLOCKING

**AC-C3 boss 与 spawn ring 不重叠（per-axis 两轴独立覆盖）**
- Given: 默认参数 `boss_region_half=4.0`、`boss_region_center=(0,0)`、`inner_rect_half=(7,16)`；另设三类越界 fixture：
  - x 轴孤立越界 `boss_region_half=8.0`（`|0|+8=8>7` x 越界，`|0|+8=8≤16` y 合法）；
  - x 轴孤立越界 `boss_region_center=(5,0)`（非居中使 `|5|+4=9>7` x 越界，y 轴 `0+4≤16` 合法但 x 失败）；
  - **y 轴孤立越界 `boss_region_center=(0,13)`**（x 轴 `0+4=4≤7` 合法，y 轴 `13+4=17>16` 越界，证明 per-axis 校验 y 轴独立不被 x 轴检查掩盖）。
- When: 按 F4 per-axis 不重叠校验 `|center.x|+half ≤ inner_rect_half_x ∧ |center.y|+half ≤ inner_rect_half_y` 校验四组 fixture
- Then: 默认参数通过（`0+4≤7`（x）∧ `0+4≤16`（y））；三类越界 fixture（x 轴 half=8、x 轴 center=(5,0)、y 轴 center=(0,13)）均 → `INVALID_ARGUMENT`，不静默让 spawn 覆盖 Boss 区；y 轴 fixture 确保漏检 y 轴的 buggy 实现不通过
- 验证: 表驱动 geometry unit（含 x/y 两轴孤立越界 fixture，per-axis 独立覆盖）| Gate: BLOCKING

### D. StageSpatialConfig schema 与 Config 校验（R5, F5/F6）

**AC-D1 schema 字段完整**
- Given: StageSpatialConfig 应含 R5 全部 8 字段：`arena_size`、`walkable_region_polygon`、`walkable_area`、`spawn_ring_depth`、`boss_region_center`、`boss_region_half`、`cell_size`、`index_margin`（注意：`arena_min` 不入 schema，由 F1 派生）
- When: build_snapshot 校验
- Then: 全字段 present 且 finite；缺失或非法扩展字段（`walkable_region_polygon`/`spawn_ring_depth`/`boss_region_center`/`boss_region_half`）→ snapshot 停 `foundation_ready`，不达 `battle_ready`，GameRoot 不开放 BATTLE_ACTIVE
- 验证: schema validation test | Gate: BLOCKING

**AC-D2 Config R7 校验关系一致（参数化）**
- Given: 参数化 fixture `(arena_size=(22,40), cell_size, index_margin)`，其中 `cell_size` 取 `{spike=2.0, ADR 选定值占位}`、`index_margin` 取 `{spike=2.0}`、`walkable_area=880.0`（全矩形）。spike case 作为参数集的一项，ADR 选定 cell_size 后只需在参数集追加新值，**不需修改本 AC 的 Then 期望值**（期望值由 fixture 的 cell_size 按 F6 派生，非硬编码常量）。
- When: Config R7 子集校验同一 StageSpatialConfig
- Then: `cols=max(1,ceil(arena_size.x/cell_size))`、`rows=max(1,ceil(arena_size.y/cell_size))`、`grid_cells=cols×rows`（由 fixture 的 `arena_size` 与 `cell_size` 按 F6 派生，非硬编码）；`arena.grow(index_margin)` 后 AABB 四边 `|·| ≤ spatial_max_abs_world_coord`；`walkable_area ≤ arena_w×arena_h`；`walkable_area == shoelace(walkable_region_polygon)`（4 顶点 CCW arena AABB 四角）；`cols/rows ≤ spatial_max_grid_axis=4096`、`grid_cells ≤ spatial_max_grid_cells=262_144`，与 `design/registry/entities.yaml` 逐项一致。spike case（cell_size=2.0）下派生值 `cols=11`、`rows=20`、`grid_cells=220`、`arena.grow(2.0)=[−13,13]×[−22,22]` 作为参数化的一组已知输出断言
- 验证: cross-config consistency test（参数化，含 spike 2.0 作为其中一个 case；断言派生公式与 registry 上限一致，不断言硬编码常量）| Gate: BLOCKING

**AC-D2.5 walkable_region_polygon schema 契约**
- Given: 一组 `walkable_region_polygon` 变体 fixture：3 顶点、5 顶点、CW 顺时针绕序、闭合多边形（首==尾顶点）、自交多边形、外接矩形 ≠ arena AABB
- When: build_snapshot 校验 `walkable_region_polygon` schema
- Then: 全部返回 `INVALID_ARGUMENT` 或 `DERIVATION_ERROR`，snapshot 停 `foundation_ready` 不达 `battle_ready`；shoelace ≤ 0（CW 退化）同样拒绝
- 验证: polygon schema boundary table | Gate: BLOCKING

**AC-D3 index_margin 域与下界**
- Given: `index_margin=2.0`（spike）、`index_margin_min=0.075`（F5，仅 player_overshoot）
- When: 校验 index_margin
- Then: `index_margin ≥ index_margin_min` 且 `arena.grow(index_margin)` 四边不越 `spatial_max_abs_world_coord`；`index_margin < index_margin_min` 或 grow 越域 → `LIMIT_EXCEEDED`，不 clamp 配置值；且 `snapshot.StageSpatialConfig.index_margin == 源 StageConfig.index_margin`（逐字段忠实复制，捕获 2.0→0.2 类复制错误——错误值可能域合法但非源值，此断言确保值传递忠实；Config→snapshot 完整复制正确性的集成证据归 config-data-system.md AC）
- 验证: boundary unit + field-level copy fidelity | Gate: BLOCKING

### E. Config→SpatialGrid 注入（R6）

**AC-E1 Stage reference 完整性（Stage-owned 不变式）**
- Given: 合法 Config foundation 数据 + 合法/非法 StageConfig fixture（逐项注入：Stage reference 缺失、R5 扩展字段 `walkable_region_polygon`/`spawn_ring_depth`/`boss_region_center`/`boss_region_half` 非法、arena 非法、polygon schema 违规）
- When: Config build_snapshot 校验 StageSpatialConfig
- Then: 合法 fixture → snapshot 达 `battle_ready`；任一非法 fixture → snapshot 停 `foundation_ready` 不达 `battle_ready`，且 `SpatialGrid.init` 调用计数=0（spy 断言），GameRoot 不开放 BATTLE_ACTIVE
- 验证: Stage reference validation unit + init-call-count spy | Gate: BLOCKING（BATTLE_LOADING 注入顺序、carrier/Pool/owner 层 failure、snapshot ID 跨 Pool/Grid 一致性的集成证据归 game-root-scene-flow.md AC-A2/D3，本 GDD 不重复）

**AC-E2 Stage 侧 snapshot ID 一致性（Stage-owned 不变式）**
- Given: Stage 数据随 snapshot S 注入 SpatialGrid.init
- When: 读取 SpatialGrid 消费的 Stage 派生值与其绑定 snapshot ID
- Then: Stage 侧派生值 snapshot ID == 注入时 snapshot S 的 ID；跨 Pool/Grid ID 不一致检测归 GameRoot（遵 GameRoot R2/AC-D3），本 GDD 仅验证 Stage 侧 ID 与注入一致
- 验证: Stage-side snapshot ID unit | Gate: BLOCKING

### F. 不可热改与 teardown（R7）

**AC-F1 Active 期间 Stage snapshot 逐字段不可变（含 PackedVector2Array mutation 隔离）**
- Given: battle 使用 snapshot S（含 StageSpatialConfig 全部字段）；SpatialGrid.init 已用 S 初始化
- When: 在 BATTLE_ACTIVE 进入后、每次 pause/resume 状态切换点、以及 Resource 编辑事件触发后，读取 SpatialGrid 消费的 Stage 派生值；并显式 mutate S 的 `walkable_region_polygon` 某顶点（如 `S.walkable_region_polygon[0] = Vector2(999, 999)`）及编辑 arena_size/cell_size/index_margin/spawn_ring_depth/boss_region_center/boss_region_half
- Then: 当前局 `arena_min`/`arena_max`/`cell_size`/`index_margin`/`spawn_region`/`boss_region` 逐字段等于 S 中的值，无 reinit、无字段漂移；Grid 内部读出的 `walkable_region_polygon` 对应顶点仍等于 init 时原值（证明 **isolation invariant 成立**——mutation 不影响 Grid 私有状态；`.duplicate()` 真复制或 COW 值类型的写时复制均满足此 invariant，本 AC 验证 behavior 不验证 mechanism，GDScript 不暴露 CowData buffer identity 故无法在测试层区分二者）；Resource 编辑只标记 next battle rebuild；运行时 `init` 重建请求的 `WRONG_STATE` 返回归 SpatialGrid AC-H6，本 AC 不重复断言
- 验证: snapshot immutability + polygon mutation isolation unit（事件驱动采样，非时间轮询）| Gate: BLOCKING

**AC-F2 改 arena/cell_size 须重建**
- Given: 需变更 arena 或 cell_size
- When: 尝试单局内 `init` 重建 vs 退出本局新 battle 重建
- Then: 单局内 `init` 重建 → `WRONG_STATE`；合法路径为 `teardown → 下一场 BATTLE_LOADING 用新 StageConfig revision 重建`（遵 SpatialGrid Edge Case 21）
- 验证: lifecycle unit | Gate: BLOCKING

### 覆盖核对表

| 规则/公式 | 覆盖标准 |
|---|---|
| R1 单图固定 arena AABB / 居中坐标 / 竖屏相机约束 | AC-A1（含居中不变式）, AC-A2（归格/clamp 运行时行为归 spatial-grid AC） |
| R2 静态可行走区 / polygon schema 升级路径 | AC-B1 |
| R3 边界内侧出生环带 / 分布策略约束 | AC-C1 |
| R4 居中 Boss 子区 / 不重叠 / 前期空窗预警约束 / T_escape 几何地板 | AC-C2, AC-C3（前期预警实现归 BossStateMachine，Stage 仅冻结约束存在性与 T_escape 几何地板；T_escape 派生见 R4 文字） |
| R5 StageSpatialConfig schema / 归属 / polygon schema 契约 | AC-D1, AC-D2, AC-D2.5 |
| R6 Config→SpatialGrid 注入 / 值传递忠实 | AC-D3（源值断言）, AC-E1, AC-E2 |
| R7 不可热改 / teardown 重建 | AC-F1, AC-F2 |
| F1 arena AABB 与居中 min | AC-A1（含居中不变式 arena_min==−arena_max） |
| F2 walkable_area | AC-B1 |
| F3 spawn ring 几何 | AC-C1 |
| F4 boss_region 几何 | AC-C2, AC-C3 |
| F5 index_margin 下界 / 域 | AC-D3 |
| F6 cols/rows（引用 Config R7） | AC-D2 |
| Edge Case 1–2（运行时越界判定，Stage 不参与） | 归 SpatialGrid R7 AC；Stage 不持有 AC |
| Edge Case 3（index_margin grow 越域） | AC-D3 |
| Edge Case 4（arena NaN/非法） | AC-A2 |
| Edge Case 5（spawn ring 退化） | AC-C1 |
| Edge Case 6（boss_region 越界/非法） | AC-C2 |
| Edge Case 7（boss 与 spawn 重叠） | AC-C3 |
| Edge Case 8（walkable_area 非法） | AC-B1 |
| Edge Case 9（配置缺失） | AC-D1 |
| Edge Case 10（Active 热改） | AC-F1 |
| Edge Case 11（变更须重建） | AC-F2 |

## Open Questions

### OQ1 — 生产 cell_size 未冻结
- **影响**：F6 行列数与 SpatialGrid F3 sweep 无生产值；**不阻塞 Stage 静态几何与查询正确性**，只阻塞生产 CELL_SIZE ADR。
- **归属/触发**：SpatialGrid F3 ADR + J0 真机 benchmark；本 GDD 不冻结，仅持 spike 锚点 `2.0`。
- **缓解**：spike `2.0` 合法，SpatialGrid 查询仍按真实半径正确扫描；ADR 选定后回填并提升 StageConfig revision。
- **附加风险（perf）**：当前 F3 sweep 候选在仅已知半径（pickup_radius_max=1.98）下退化（候选带 0.99–2.475），无法对 spike cell_size=2.0 产生有意义 benchmark；SkillConfig/EnemySystem/ProjectileSystem GDD 落地（提供 `max_skill_effect_radius`/`max_enemy_bound` 等有效宽相半径）前，F3 sweep 不可作为生产 cell_size 选型依据。

### OQ2 — index_margin 生产收紧值未定
- **影响**：F5 下界仅 `player_overshoot = 4.5/60 = 0.075` 已冻结，`enemy_overshoot_max`/`knockback_max`/`max_enemy_bound` 三项 gated。
- **归属/触发**：EnemySystem / Combat GDD 完成后回填。
- **缓解**：当前配置 `index_margin = 2.0` spike 安全高于下界 `0.075`；gated 项回填后须重跑 SpatialGrid F3 sweep，不得直接把 `2.0` 当生产承诺。

### OQ3 — SpawnDirector 波次/数量/时机未设计
- **影响**：spawn ring 几何已冻结，但生成节奏、数量上限、时间表属 WaveConfig/SpawnDirector。
- **归属/触发**：SpawnDirector / WaveConfig GDD。
- **缓解**：Stage 只提供内侧环带几何区域，不猜时机；SpawnDirector GDD 完成后反向引用 stage-map.md。

### OQ4 — BossStateMachine 两阶段/毒雾安全区收缩未设计
- **影响**：boss_region 锚点已冻结，Boss 两阶段表现、技能预警、毒雾压缩可活动范围归 BossStateMachine/RiskChoice。
- **归属/触发**：BossStateMachine GDD。
- **缓解**：Stage 不随战斗进度修改 walkable_region；毒雾属运行时安全区，由 BossStateMachine 在 inactive authority bank 表达。**前期空窗预警约束已冻结**（R4）：Boss 生成前 ≥ N 秒 boss_region 须有预警/驱赶信号，N 与信号形式归 BossStateMachine；Stage 冻结约束存在性，防止玩家 12:00 站在 boss_region_center 脚下被贴脸扑咬。

### OQ6 — spawn 分布策略部分冻结
- **影响**：spawn ring 几何已冻结（per-axis `inner_rect=[−7,7]×[−16,16]`，`spawn_ring_depth=4.0` 使玩家贴边时怪距玩家 ≥ 4.0 单位，缓解贴脸生成）。
- **已冻结约束（Stage 层，R3）**：spawn 分布须为 arena-relative 固定方位；玩家附近须有最小排除距离（spawn 点距玩家 ≥ `spawn_ring_depth=4.0`）。若下游采用 player-relative 跟随分布，spawn ring 几何对"从屏幕边缘涌入"fantasy 无贡献，须先修订 R3 约束。
- **未冻结（归 SpawnDirector）**：单波聚焦方向 vs 全周均匀、角落是否降权、波次节奏、数量上限、时间表。
- **归属/触发**：SpawnDirector / WaveConfig GDD；level-designer 须参与冻结分布策略细节。
- **缓解**：Stage 已冻结 arena-relative 与最小排除距离两项核心约束，其余归 SpawnDirector；SpawnDirector GDD 完成时须反向引用 stage-map.md 并声明分布策略。

### OQ5 — Stage Resource 与 manifest 引用实现未开始
- **影响**：StageConfig（`.tres`）如何被 Config importer/validator 加载与引用进 manifest 尚无实现。
- **归属/触发**：Config build/import pipeline ADR。
- **缓解**：手写 fixture Resource 可行；不阻塞 Stage GDD 契约冻结。
