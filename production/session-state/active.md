# Session State — 凡人修仙传·掌天试炼

> 会话崩溃或 `/clear` 后，先读本文件恢复上下文。

<!-- STATUS -->
Epic: 引擎与系统分解
Feature: GameRoot (#1) 第四轮 full re-review → Re-review Pending（用户选择 A 并确认完整变更集，7 个根 BLOCKING 已修订）
Task: 第四轮 verdict 为 MAJOR REVISION NEEDED（scope XL）。根 blocker 为：GameRoot 生命周期/顶层 FSM/SceneTree pause authority；加载与 teardown 依赖 DAG；battle/config/authority/resolution identity 链；immutable outcome 与 mutable Save commit 状态分离；pause/resume pump、复合 reason 仲裁与零效果 drain；phase failure 验收语义；AC-F1~F4 allocation/workload/diagnostic/seed oracle。
→ 已修订：`game-root-scene-flow.md` 主契约与独立 AC；`.claude/docs/technical-preferences.md`；`config-data-system.md`；`input-system.md`；`stage-map.md`；`systems-index.md`；review log。Object Pooling、SpatialGrid、RNG 的冻结公开契约未改。下一步必须运行第五轮独立 `/design-review design/gdd/game-root-scene-flow.md`；当前不得写 Approved/runtime/battle_ready/benchmark_ready。
<!-- /STATUS -->


## EnemySystem design-review 结论（2026-08-25，首轮 full，6 specialist + creative-director 终审）

**Verdict: MAJOR REVISION NEEDED，scope L。** 8 节齐全、依赖图完整（上游全在/下游全 Not Started）、spawn_context v1 冻结质量高、§4.7 index_margin 下界约束是亮点——框架立得住是"修订"非"重做"。9 项必须实现前修订的 BLOCKING：

- **BL1 separation phase 时序自相矛盾** [ai]：§3.10 MOVEMENT_COMMIT(stage)在前、QUERY_CONSUME(算分离)在后，但 §4.1 把 separation_correction 写进 committed_pos 同步累加。分离何时回写未裁定（OQ4 挂起但公式已写死），AC-E10/E11/E7 悬空。**待用户裁定回写时序。**
- **BL2 emit_signal 带参热路径破坏 AC-E4 零分配** [godot×perf]：§3.4 禁 connect/disconnect 未禁 emit_signal；死亡事件3参/技能意图/受击信号在 run_phase 每帧触发，Godot 4 emit 装箱 Variant 数组是稳态分配。**方向已定：死亡/受击走 GameRoot 预分配 staging bank/队列，take_damage 改直接方法调用。**
- **BL3 分离算法4缺陷 + AC-E10 数学不可实现** [sys×ai×perf]：(a)零向量退化 distance=0→Normalize(0)=0→correction=0 永久重合；(b)query_radius 用 max_enemy_bound(shape_bound) 但 overlap 用 sep_radius，语义不一致漏邻居；(c)单遍累加无 clamp + 链式不收敛；(d)AC-E10"单遍 overlap≤0"数学不可实现。**用户已裁决：采纳 CD——保留"无重叠"目标契约，AC-E10 降为 bounded 收敛(N≤3帧≤ε=sep_radius×0.1)，修4缺陷(零向量用确定性单位向量/query语义统一/累加clamp/pair-once去重)，给 k 上界(中心格≈300)计入 AC-E2 预算。**
- **BL4 AC 不可测+术语漂移+编号碰撞+缺10 AC** [qa]：AC-E1/E2(占位)/E3(约为50%)/E4(无positive control)/E10/E11/E13/E17(代码审计可自动化)不可测；AC-E5/E6 用 slot_state=FREE 但 Object Pooling R3 冻结 AVAILABLE；AC-E9 引用 spatial-grid AC-E11 与本 GDD AC-E11 撞号；缺 AC-E28~E36(零距离/版本不匹配/paused resume/召唤cap-full/精英FSM a/b/c/LOD切换/越界clamp/腐毒妖藤静止/Boss阶段切换分离延续)；§8 缺"验收设计 vs 已执行证据"标注。
- **BL5 behavior_id 3 甲壳妖虫"行为剪影"是属性非行为** [gd]：实际行为=直线追踪=behavior 0，违 §2"1-2秒识别"。**待用户裁定给什么可识别行为。**
- **BL6 死亡 VFX 时序 defer ADR 但击杀反馈是 §2 四大幻想层之一** [gd]：reset_for_pool 立即停动画截断死亡动画。**方向已定：死亡特效用独立 VFX 池节点播放，载体立即回池，§9.2 移除 defer。**
- **BL7 精英 FSM prose 不可编码 + §8 无 FSM AC** [ai×qa]：§3.6 无触发谓词/冲刺方向/WEAKENED时长/退出条件，§7.4 无数值；按 coding-standards Logic 类须 BLOCKING 单元测试，须补 AC-E32a/b/c。**方向：补状态机表(每条边{trigger/action/next})+spike锚点数值(标待Config)。**
- **BL8 BLINK落点/召唤cap-full/borrow跨phase 未定义** [ai]：**BLINK 落点待用户裁定；召唤 cap-full 方向已定(逸散VFX+不重试本周期)；borrow 跨 phase 方向已定(intent latch 下一 tick SPAWN_INTENT)。**
- **BL9 LOD 与 stage-map R1"相机固定全显 arena 22×40"矛盾，reduced 路径成死代码** [gd×perf]：**用户已裁决：移除 LOD reduced，删 §3.9/§4.4/AC-E15/16/17，消解 perf R1 预算真空。**

**Specialist 分歧**：(1)分离契约 gd 主张软分离放宽 AC vs sys/ai/perf 主张修算法保契约——CD 裁决采纳后者但 AC-E10 降为 bounded 收敛，**用户已确认**；(2)LOD 存废 gd 主张移除 vs perf 主张入预算——**用户已确认移除**。

**可合理 defer（不阻塞本 GDD）**：节点架构 ADR(OQ1)、knockback_max 归属(OQ2)、max_enemy_bound 数值(OQ3)、borrow→insert 时序(OQ5)、Boss participant 边界(OQ6)、质量比具体数值(defer ADR 但行为方向须可测)。本轮修订可能新增 1 mini-ADR（分离时序+事件传递机制打包，因 BL1+BL2 交叉）。

**当前进度**：用户选择本会话立即修订。9 项 BL 中需用户裁定的设计决策待批量确认（BL1 时序/BL5 behavior3/BL8 BLINK落点）；其余方向已定可直写。registry 3 gated 值(max_enemy_bound/enemy_overshoot_max/separation_radius)声回填但无独立 entry（advisory，回填时补）。

**修订完成（2026-08-25，9 项 BL 全部写入 enemy-system.md）**：
- BL1 separation 时序：下帧 MOVEMENT_COMMIT 生效 + 纳入 staged（§4.1/§4.2，OQ4 ✅RESOLVED）
- BL2 emit_signal 带参热路径：死亡/受击改 GameRoot staging bank + take_damage 直接方法调用（§3.4 零分配契约扩展 + §6.2 下游表）
- BL3 分离算法 4 缺陷：零向量确定性单位向量 + query 语义统一 + 累加 clamp + pair-once 去重；AC-E10 降 bounded 收敛 N≤3 帧≤ε（§4.2/AC-E10a/b）
- BL4 AC 不可测+术语+编号+缺 AC：8 条不可测 AC 重写、FREE→AVAILABLE（AC-E5/E6）、AC-E9 编号消歧、AC-E14/E22/E23 拆分、AC-E15/16/17 移除（LOD）、补 AC-E28~E36（11 条）、§8 加 story-type/gate 标注 + positive control 引用 object-pooling AC-F3（§8 全节重写）
- BL5 behavior 3：甲壳妖虫改贴身毒 aura（§7.4，OQ7 待 performance 核验）
- BL6 死亡 VFX：独立 VFX 池节点播放 + 载体立即回池，§9.2 移除 defer
- BL7 精英 FSM：状态机表 {trigger/action/next} + spike 锚点（§3.6/§7.3）+ AC-E30a/b/c
- BL8 BLINK 落点/召唤 cap-full/borrow：玩家点+seed 偏移 clamp arena（§3.6.2/AC-E30c/E31）+ cap-full 逸散 VFX 不重试（§5.7/AC-E29）+ intent latch 下一 tick（§6.2/OQ5）
- BL9 LOD 移除：删 §3.9/§4.4/§7.3/AC-E15-17，消解 stage-map R1 死代码（§3.9 REMOVED/§7 重编号/§9.1 统一 60fps/§9.3 无 sim-LOD）
- §7.2 加 health/damage cap（违 §2"更乱更密 not 更肉更慢"，AC-E33）；§10 OQ1 加 303 Node2D 性能子问题；status 行 DRAFT→IN REVISION
- 待 re-review：推荐 /clear 后新会话 /design-review enemy-system（本会话 context 已用约 70%+）
<!-- CONSISTENCY-CHECK: 2026-08-24 | GDDs checked: 5 (config-data-system, object-pooling, spatial-grid, stage-map, game-root-scene-flow) | Conflicts found: 0 | 2 STALE REGISTRY resolved (pool_capacity_enemy_elite 4→6, required_pool_capacity notes 320/4/1→320/6/1) | Verdict: PASS after registry update -->
<!-- REVIEW-ALL-GDDS: 2026-08-24 | mode=design-theory (Phase 2 skipped, consistency-check just PASS) | 5 GDDs | Verdict: CONCERNS → 1 Blocking CLOSED | BLOCKING: config EC7/L59/AC-B4 与 object-pooling R1 对 PRESENTATION overflow 行为矛盾（config 说 failure→ControlledFault，object-pooling 说 OVERFLOW_DROPPED）→ 已对齐 config 到 object-pooling R1（pool owner 权威），3 处文案改走 OVERFLOW_DROPPED，不改公开契约 | DEFERRED: enemy_elite F1 max_concurrent=2 语义纯化（reviewer 建议 max_concurrent=4/safety_spare=1）——核查发现会破坏 max_concurrent 三 key 总和(300+2+1=303)与 Grid ENEMY cap 303 对齐→制造反向 Pool/Grid 准入不一致，当前藏入 safety_spare 是有意对齐，故 DEFER 不盲改；4 Warning（灵石无 sink / 替身符 mass-clear CPU 未预算 / 夺宝精英时序歧义 / damage_number=96 AoE 容量）多 DEFERRED 到下游 GDD | Phase 3 设计理论高度一致：Player Fantasy 统一"无感基础设施"、pillar 对齐、无 scope creep、核心循环清晰 -->
<!-- CONSISTENCY-CHECK: 2026-08-24 | GDDs checked: 6 (config-data-system, game-root-scene-flow, object-pooling, rng-system[NEW], spatial-grid, stage-map) | Conflicts found: 0 | Stale registry: 0 | Forward flags: run_seed 未注册（Config 未声明字段，RNG AC-G2 gate BLOCKED）、stream_id 集未注册（API 契约非数值） | Verdict: PASS -->

## 当前任务

**InputSystem (#2 Core, Foundation 层) GDD Designed。** lean /design-system 完成 8 节写入 `design/gdd/input-system.md`（2026-08-25）。核心设计：单摇杆 → 二元归一化移动向量（F1：`out=(mag<deadzone)?ZERO:raw/mag`，幅值 ∈ {0,1}，MVP 不启 analog 量程）；GameRoot 7-phase 参与者（slot 归属 OQ）；BATTLE_ACTIVE 驱动 / BATTLE_PAUSED 冻结 / APP_BACKGROUND 锁定（无挂钟补偿）；attack 自动释放（无攻击输入）；零分配稳态管线（AC-IS25 引 `tools/ci/static_guard_check.py` AST 守卫，与 EnemySystem AC-E4-code 同型）。4 态 IDLE/ACTIVE/FROZEN/BACKGROUND_LOCKED。27 条 AC（AC-IS1..IS27）覆盖 Core Rules 11 + F1 4 + States 四态 + 跨系统 5 + 静态守卫 3。lean 模式跳过 systems-designer（D/E/F/G 节，公式为数学恒等无平衡数值可"发明"；full 复审终审 spike-skip carrier 持留语义 + pause-resume touch 续接）；H 节 qa-lead 单 pass 起草。📌 UX Flag（摇杆 UI + 选择 UI 交互归 ux-designer full 复审）。10 项 Open Question（VirtualJoystick 4.7.1 API 验证 + 内置 vs 自定义 ADR / joystick_mode ADR / input config schema 未冻结 / carrier 归属 / 7-phase slot / deadzone 实测 / 摇杆视觉 UX / analog 预留 / static_guard_check.py 未建）。无新注册表条目（InputSystem 无跨边界数值事实）。systems-index：InputSystem Not Started→Designed，started 7→8、MVP designed 7→8/27。

**下一步**：InputSystem 设计完成，待 /design-review（建议新会话，full 模式：sys-designer 终审 D/E/F/G 节 + qa-lead 复核 AC 覆盖 + ux-designer 终审 📌 UX Flag）。或继续下一个 MVP 系统设计（按 Recommended Design Order #8 PlayerController，但其依赖 InputSystem 已就绪；或 DamageSystem / SpawnDirector 等 Core 层）。

---

### 历史：EnemySystem (#9) R4 复审 Approved（2026-08-25）。5 根因 + G 全闭环，零新公式/零新 ADR/零设计意图变更。修订写入 enemy-system.md（24 处）+ technical-preferences.md L59 + spatial-grid.md（5 处 query_radius + G3 澄清注）。R4 验证 grep 另补修 3 处残留（AC-E19 引用 + spatial-grid L252/L273）。systems-index：EnemySystem In Review→Approved，approved 4→5。详见 review-log。PR #124（fork→Donchitos）待 review/merge。

### 历史：SpatialGrid 第四轮 full 复审 **APPROVED**。8 项 BLOCKING 全部 CLOSED，creative-director 终审通过。标 Approved 前一并修订的 4 项措辞/追溯小改已写入：R-A（F5 L379 "6-18ms 保守"→"乐观下界"+双层低估说明）、R-B（新增 EC29 映射 AC-E11，EC 计数 28→29/29）、R-C（核对表 R4 行补 AC-B0/B4b、R6 行补 AC-E11）、R-D（依赖表 SpawnDirector publish 时序措辞防 ghost）。文档 status 行、systems-index（NEEDS REVISION→Approved，reviewed/approved 1→2）、review-log（追加 APPROVED 条目）均已同步。defer 项（R9 precedence 独立 AC / godot 契约显式化 / AC-J3b Σ gate）归实现期或下一轮 lean follow-up。J0/J1/J2/J4 真机性能 gate 仍 OPEN（无 min-spec 真机），仅 deferred evidence，不影响设计冻结。

## 本会话完成的工作

### 引擎设置（/setup-engine）
- 引擎确定：Godot 4.7.1（从仓库脚手架 4.6 升级）
- 语言：GDScript
- CLAUDE.md 技术栈已更新
- `.claude/docs/technical-preferences.md` 全量填充（移动端竖屏 Touch 输入、GDScript 命名规范、GDUnit4、godot 专家路由）
- `docs/engine-reference/godot/` 全部参考文档更新到 4.7.1（VERSION/breaking-changes/deprecated-apis/current-best-practices + 8 个 modules）
- 4.7 关键发现：内置 VirtualJoystick 节点（摇杆移动可直接用）、`AnimationNodeBlendSpace.sync`→`sync_mode`、`area_mask` 默认值变更、device ID 不再是 0

### 系统分解（/map-systems）
- 系统索引已写入：`design/gdd/systems-index.md`
- 31 个系统，分 5 依赖层 + 4 优先级（MVP 26 / Vertical Slice 3 / Alpha 1）
- Review mode = lean（三个 director gate 均跳过）
- 设计顺序前 5：SpatialGrid → Object Pooling → Config/Data → RNG → GameRoot
- 高风险系统：SpatialGrid、Object Pooling、Config/Data、DamageSystem、BossStateMachine、EnemySystem、SkillDraftSystem

### 首个 GDD（/design-system spatial-grid）
- `design/gdd/spatial-grid.md` 全 8 节完成（A–H + Open Questions）
- 委托 systems-designer 起草 D 节公式（F1–F5），qa-lead 起草 H 节验收标准（11 组 ~35 条）
- 初稿核心决策（已被 2026-08-18 full review 部分替代）：仅保留 uniform-grid 方向与位掩码；旧的 CELL_SIZE 直接绑定、nearest 容器顺序 tie-break、查询半径不变式均不再有效，以下新修订为准
- 头号阻塞：SkillConfig AoE 半径未定义 → CELL_SIZE 终值待定（OQ1）
- 实体注册表新增 `max_query_radius`（formula）；`pickup_radius=1.8` 待 PlayerController GDD 注册后回填 referenced_by

### SpatialGrid full re-review 修订（2026-08-18）
- full review consulted：game-designer、systems-designer、qa-lead、performance-analyst、godot-specialist，creative-director 终审
- 终审：MAJOR REVISION NEEDED；原 2026-08-14 修订仅部分闭环，且无 review log
- 查询正确性：所有 finite/non-negative radius 合法；release 保留请求半径正确扫描，禁止 clamp
- nearest：全局最小距离；等距取 stable registration_sequence，禁止“螺旋遇首即返”
- 坐标：F1 改 arena-min 对齐，正式定义 cols/rows，支持 arena 非 CELL_SIZE 整除
- 生命周期：SpatialHandle/RegistrationEntry、即时 remove、generation、pool release 顺序
- 时序：movement commit → grid sync → query/collision → damage/deferred remove
- 暂停：Paused snapshot + FIFO mutation queue；支持 Paused→TornDown
- 性能：9 格只代表 lookup；F4 改总索引条目，F5 改 O(N+M)/dirty notification 前提；J0 锁定 benchmark manifest
- 当前用户暂无 min-spec Android 真机：真实性能 release gate OPEN

### SpatialGrid second full re-review 修订（2026-08-18）
- 公共 API：circle/nearest/insert 改为 primitive status + caller-owned preallocated carrier；公开 handle 为永不复用的 int ID
- 数值与公式：F3 强制合法 fallback；聚合真实 broadphase radius；radius=0 分量相等、正半径 normalized compare；walkable area>0；index_margin 不得突破世界域
- 生命周期：mutation lookup 与 active resolve 分层；Paused 在完整 tick barrier 冻结，resume 采用 prepare→complete remap→commit/abort
- 查询语义：Projectile broadphase 覆盖完整 swept segment；pickup 固定 Drop center；nearest 固定 center distance
- 错误路径：公开 API status/postcondition 矩阵；任意查询 failure 中止消费并进入 ControlledGameplayFault
- 验收：AC 增至 66 条；J3 allocation positive control、J5 operation 上限、J6 逐调用 oracle 已冻结
- 跨文档：systems-index runtime prerequisites、registry pickup constants/effective max radius、主方案 buffer 表述已同步

## 关键决策

- **概念文档来源**：用 `design/凡人修仙掌天试炼-MVP设计方案.md` 而非标准 `design/gdd/game-concept.md`（方案比标准概念文档更详尽，含数值框架+模块清单+验收标准）
- **SaveSystem 归 Feature 层**：按"要存什么的数据契约"分层（依赖 Progression/Zhangtian 先定义），而非按存档框架归 Foundation
- **VFX 放 Vertical Slice、Analytics 放 Alpha**：音效对爽感更即时放 MVP，特效系统化较重放 VS，埋点后置
- **SpatialGrid CELL_SIZE 临时 2.0**：仅作 spike 锚点；最终从 benchmark sweep 选定，不再直接等于 max_query_radius
- **正确性优先**：radius>CELL_SIZE 不是错误；debug/release 均按原半径返回正确集合，配置审计只告警不改语义
- **Foundation 层 fail-fast 策略**：非法初始化/状态/非有限输入 debug assert；release 返回失败/空并限频上报，不用 magic fallback
- **pickup_radius source**：当前权威来源为 MVP 主方案，registry 已登记 base=1.8/max=1.98；PlayerController GDD 完成后追加 referenced_by
- **GDD 描述行为、ADR 描述实现**：数据布局、结果 buffer、更新策略、nearest 正确算法实现与语言路径由 ADR/spike 选择

## 文件清单

| 文件 | 用途 |
|------|------|
| `CLAUDE.md` | 技术栈 Godot 4.7.1 / GDScript |
| `.claude/docs/technical-preferences.md` | 全量项目偏好 |
| `docs/engine-reference/godot/VERSION.md` | 引擎钉版 + 迁移说明 |
| `docs/engine-reference/godot/breaking-changes.md` | 4.4→4.7 破坏性变更 |
| `docs/engine-reference/godot/deprecated-apis.md` | 弃用/移除 API |
| `docs/engine-reference/godot/current-best-practices.md` | 4.7 新实践 |
| `docs/engine-reference/godot/modules/*.md` | 8 个子系统参考 |
| `design/gdd/systems-index.md` | 31 系统索引（SpatialGrid→In Revision；runtime prerequisites 已注明） |
| `design/gdd/spatial-grid.md` | SpatialGrid GDD 全 8 节 |
| `design/registry/entities.yaml` | 实体注册表（max_query_radius 已注册） |
| `design/凡人修仙掌天试炼-MVP设计方案.md` | 概念来源（只读） |

## 待解问题

- min-spec Android 真机暂无 → J0 benchmark readiness OPEN
- arena、成长后 pickup/target range、SkillConfig AoE、separation、projectile broadphase 未定义 → 阻塞生产 CELL_SIZE ADR，不阻塞正确查询语义
- GameRoot/Stage/Object Pooling/Config 及所有 consumer GDD 尚未创建，当前仍非 integration-ready

## 下一步

建议顺序：
1. ✅ 已完成：8 项 BLOCKING 全部修订写入 spatial-grid.md。
2. ✅ 已完成：第四轮 full 复审 APPROVED + 4 项措辞/追溯小改写入 + systems-index/review-log/active.md 同步。
3. ← 当前：SpatialGrid 设计冻结。下一步可选：进入 Object Pooling GDD 设计（design order #2），或处理 defer 项 lean follow-up。
