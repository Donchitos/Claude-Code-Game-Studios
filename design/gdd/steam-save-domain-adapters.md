# Steam 存档域与战斗恢复适配 — WP04b

状态：WP04b Local Adapter + WP04c Recovery Contract / Limited Independent Code Review APPROVED；完整商业 owner、迁移与预算门 OPEN。设计复核采用 lean 文档检查，本文件不继承 ADR-0006 基线的完整设计批准。

> WP04c 两路独立代码复核已通过；详见 `production/playtest-evidence/2026-09-14-steam-recovery-contract.md`。批准仅覆盖TEST/LEGACY合同与接线，不新增full design verdict或关闭商业实施门。

## Overview

承接 ADR-0006，新增 records、progression、preparation、current_run、user_settings 五域结构与联合语义校验，和当前单舞台 `LEGACY_STAGE_PC_V1` 战斗捕获/恢复适配器。七域结构可被严格检查；只有已注册 owner 能验证其 payload，缺失返回 UNSUPPORTED_SCHEMA。此适配器没有启用 Steam Save v2 写入器，也没有将旧生存舞台冒充 64 任务与六种目标的完整实现。商业目标仍为主要内容 20 小时以上。

## Player Fantasy

玩家退出后能保留本局位置、构筑、升级选择与 Boss 进度；已投入的资源不会因为恢复而退回、重抽或重复授予。读取可疑状态时保留原档案，不用空域补齐未知状态。

## Detailed Rules

### 域结构与分工

精确字段/必需键/未知字段规则以 `assets/schemas/steam/*-domain-v1.schema.json` 为机器结构合同；语义入口是 `src/data/steam_save_domains.gd`。全部计数为 u63 字符串，bool 保留 bool，记录秒数为 canonical float64 hex。

| 域 | 当前结构与内建校验 | 仍需 owner 实现 |
|---|---|---|
| records | 分离 legacy_records 与迁移后 mission_records；胜/败/放弃/技术中断总和、灵石三账守恒 | Settlement 各种结果的精确增量、奖励与退休事务 |
| progression | 三个稳定分支 ID、0–5 级、页账、购买序号；latest purchase 的内部价差与终身支出/当前余额相容 | 交易请求身份、历史内容变更的迁移策略 |
| preparation | 稳定 seed ledger、单 reservation、seed→recipe 配对；库存与章节入口分离 | 真实候选/RNG/选择/投入/消耗 owner 的语义验证与持久承诺 |
| user_settings | 四路 0–100 音量、100/115/130 字号、四 bool 辅助选项、Config locale | UI 持久化接线；设备/图形/键位不被随意放入云域 |
| current_run | PREPARED/RUNNING/SUSPENDED/RESULT_PENDING 的身份、承诺、checkpoint 与 intent 结构 | 全部商业 required owners；完整 COMPLETE 正常请求 hash/after-image 判定 |

`last_purchase_receipt.kind` 区分 LEGACY_V1 与 V2。旧 runtime 没有 request_hash/base_revision，禁止迁移时伪造。历史 receipt 的 next_domain_revision 可以小于当前 domain_revision；收入不能使最后购买凭证失效。v2 只做历史账相容性，不按当前新价格重算旧 spent。**本轮新增迁移所需结构，但尚未实现并验证 v1→v2 磁盘迁移器。**

迁移后的库存可以非零且 legacy_starter_claimed=true，同时 Campaign 尚未给出 M01-03 prep grant；只有实际 PILL reservation 才要求入口资格和配方配对。活动 run 与 reservation/preparation checkpoint 必须同 identity。空 offer 无 hash/selection；非空 offer hash 与语义数组绑定，候选 ID 唯一。运行态不允许未选择的已曝光 offer。取消资格从持久 offer/choice/handoff 推导，不能由 caller bool 放行。

`initialize` 要求显式内容 revision/hash、完整且与 Campaign 相等的 mission hash map、seed_caps、recipe_seeds、locale_ids、offer/loadout/refresh 上限、required_owner_ids、owner_validators，以及 preparation_validator/complete_validator 槽位。没有生产默认值。两个语义 provider 可以缺失，但活动 run / RESULT_PENDING 的使用分别返回 UNSUPPORTED_SCHEMA。测试中的 TEST-* 目录和 mock provider 不进入生产注册表。

### 捕获和恢复

`SteamBattleSnapshot.capture(scope, limits)` 只在 PAUSED、完整 Scope tick 已结束、input lease 已关闭、Stage tick 相等、伤害批次已消费、没有 terminal/fault/teardown 时同步复制。stage 的本 tick XP/kills 产物已经由 Scope 消费，不再持久化为待发收益。

wire 的 owner 字段为 scope/player/stage/boss/fsm/rng/references/enemies/projectiles/pickups/hostile/weapon；字段清单由 `shape(config)` 显式枚举，禁止反射所有 Node 属性。保存 fixed-step accumulator、玩家本局全部属性、invulnerability/长春、敌人与弹道顺序、Boss 动作/FSM/代际、待发武器/环弹/召唤。weapon 无 pending 时 due_tick 规范化为 0；无 pending 的 ring/summon 引用规范化为 0。

Enemy `entity_id` 与 Pool borrow/Grid handle/Godot instance ID 分离。新生成分配单调逻辑序号；swap-remove 同时搬移 ID。恢复先按逻辑 ID 排序创建新 binding，随后按原 SoA 顺序回填；Boss/ring/summon 引用映射为新 handle，后续新实体排序高于已有实体。计数器有 tick/容量因果上界，空数组也不能绕过 next ID>=1。

Player 构筑由冻结 Config/progression projection 与实际已应用升级次数重建核对；不能凭空多剑/取得一次待升级。XP 不能超过已计击杀能提供的量。未生成 Boss 必须处于初始 FSM，且启用 Boss 时 tick<43200。速度/位置/计时器需满足此 profile 的生成与固定步长范围，不能仅验证浮点有限。

生成敌人使用的逻辑 viewport 在 configure 时取得，随快照冻结；调整显示窗口不再重抽生成几何。这个规则仅作用于当前 legacy Stage，不替代正式 StageWorldDomain 合同。

RNG 保存 seed **和当前 state** 的完整 64-bit 原始位模式（16 hex，包括最高位为 1 的负 int 表示），恢复顺序 seed→state。RNG 绑定 engine version 和具体 commit hash；adapter 的 config_hash 使用 Godot var_to_bytes 的精确配置身份，仅对当前 build 的适配有效，不冒充 ConfigDataSystem 的跨平台 canonical content hash。

`restore` 只接受全新 CREATED/空 Stage；先完整验证，再构建。失败时丢弃隐藏实例，不触碰旧战场/磁盘。成功后仍 PAUSED，输入使用新 context/generation 与 fresh-neutral。危险视图在新 Stage epoch 重建；上一 tick 已消费的扑咬轨迹/扇毒释放提示不重播，不是第二次伤害事实。HUD/camera、渲染缓存、伤害浮字、旧输入 held state 和 query scratch 不落盘。

### 商业接入门

调用方仍必须按 ADR-0006 的 GameRoot hidden-build/磁盘事务/曝光顺序接线；单独调用适配器不会切换 Home 或恢复真实玩家档案。完整 Mission、SkillDraft/Loadout、Preparation、SettlementComplete、Character/Codex/Narrative 未安装时不得启用 STEAM_MISSION_V1 / STEAM_SAVE_V2。

### WP04c：显式恢复合同（2026-09-14）

`src/data/steam_recovery_contract.gd` 实现相对于**可信、预先安装配置**的 checkpoint 校验；manifest 不能来自待加载存档或由其删减。配置固定 `schema="1" / recovery_profile / mission_id / mission_definition_hash / config_hash / owners / max_checkpoint_bytes`；每个 owner 固定 `owner_id / schema / state_shape / max_snapshot_bytes`。owner ID 严格排序且唯一，schema 是正 u63 字符串，所有字节上限显式提供、正数且不超过调用方 codec 工具上限。注册后复制配置和 shape，不接受重新注册。现仅允许 `TEST_ONLY / LEGACY_ADAPTER_ONLY`，这两个 scope 均不能开启商业存档。

新合同的 owner payload **显式采用绑定封装** `{binding,state}`，并非把旧 WP04b 裸 payload 自动解释为新格式。外层仍为 `{owner_id,schema,revision,payload}`。binding 为 `{recovery_profile,profile_id,branch_id,run_seq,mission_id,mission_definition_hash,config_hash,active_tick}`；revision 属于各 owner，自身语义校验决定其含义，不强制等于 tick。旧进程 instance epoch 不持久化，恢复时仍由 GameRoot 新签发。

完整顺序：checkpoint canonical UTF-8 限额与封闭字段 → **全部** owner 精确集合/顺序、schema、revision、binding、封闭 state shape 与每条完整 row 字节 → 每 owner 语义 → 必需的联合语义 → 返回合法。任何预检失败均不调用语义回调（包括 Save 的 Preparation）；联合 validator 缺失不使用默认 OK。所有回调在预检末尾及各调用点检查有效性，防止 Node provider 释放后调用。回调只能返回单键 `{status}`，状态封闭；每次获得单独深拷贝，不得修改输入或其他 owner 的快照。Callable 不是沙箱，回调不得修改外部状态仍是实现审查要求。

`SteamSaveDomains.initialize(..., recovery)` 可安装本合同，required-owner 集合必须与其已有 context 相等；运行态从已校验的 Save 根和 run 构造 binding 后调用新检查器，不信任 owner 自报身份，不回退旧 callback。三参数旧入口仅保留既有 WP04b 测试/适配兼容性；它没有商业准入资格。owner snapshot 的结构 schema 允许规范 u63 版本，由可信 Recovery 注册确定实际接受版本；旧三参数路径仍只接受版本1。Preparation 和 SettlementComplete 同样使用隔离副本和严格返回协议。实际磁盘读取器仍 JSON v1，生产 GameRoot 未接入。

商业责任盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`：13 个战斗恢复责任、5 类持久 feature、6 种目标的特有状态。这里是责任 ID，**不是**已冻结的 runtime owner ID；owner 合并/拆分须随真实 MissionDefinition 与 Config 安装表确定。每项分别列出必须持久化的 pending 状态，以及合法 capture barrier 要求为空的当 tick 中间状态。合法 T+1 武器/召唤/环境工作必须保存，不能为获得空队列而丢弃。BREAK 的 Mission progress revision 与 Stage 已应用/待应用效果必须由联合 validator 校验。

所有商业 provider/schema/容量仍为 null/OPEN，清单校验 PASS 不等于实现或安装完成。下一具体入口是 Mission/Stage 六目标定义与快照、进度 revision 与待生效环境效果的联合验证，再逐项补齐剩余责任。正式上限仍需最大合法商业 fixture、完整 slot（包含 JSON 转义）、RESULT_PENDING 双份域和目标 Windows 性能证据。

## Formulas

- u63 checked sum：逐项从 total 扣除，任何 part>remaining 拒绝，最终 remaining=0；不以先加后检查制造溢出。
- progression upgrade_sequence=三个等级之和；next_purchase_id=sequence+1；receipt.from+1=to，cost<=lifetime spent，balance_after<=当前余额；receipt revision 自身 base+1=next<=当前 revision。
- preparation earned=available+reserved+consumed；available+reserved<=该 seed Config cap；全 seed reserved 合计<=1。
- 当前升级已消费 XP：`n*xp_base+n*(n−1)/2*xp_per_level`，n=level−1；加剩余 XP 不超过 kills。
- 当前容量：Enemy 320；friendly=400−8=392；hostile 8；Pickup 300；Weapon pending 32。来源为 production_defaults 与 Stage 常量，不是完整商业所有 owner 的总和。
- slot bytes=`UTF8(canonical({format,payload_json,payload_sha256})).size`；外层转义必须计入。RESULT_PENDING 同时携带当前七域和完整 complete_next_domains；后者 current_run.run=null，因此不重复嵌套战斗。

## Edge Cases

未知字段/版本、数字 JSON、非 finite/-0、f32 不可精确读回、重复/悬空身份、错 tick、数组超量、未完成 offer、递归 intent 拒绝。未知 owner 不接受 `{}` 替代。

ring_pending 与 8 条存活 hostile 不能同时构造；分别测 full/ring/summon/bite/phase_pending。容量压力夹具只证明构造状态的校验/恢复与字节开销，不证明自然游玩可到达，更不证明商业最大值。RESULT_PENDING 样本经过结构校验与 codec/IO probe，未通过尚缺的 SettlementComplete 语义，不能用于实际提交。

## Dependencies

`save-steam-pc.md`、`campaign-flow.md`、`mission-objectives.md`、`progression-tree.md`、`zhangtian-bottle.md`、`home-ui.md`、`player-controller.md`、`stage-map.md`、`boss-state-machine.md`、`object-pooling.md`、`spatial-grid.md`、`rng-system.md`、`weapon-system.md`、`projectile-system.md`、`drop-leveling-system.md`、`game-root-scene-flow.md`、`config-data-system.md`；本轮相关 owner 文件均追加适配路由，原商业 owner 合同仍保留。

## Tuning Knobs

测试显式 8,000,000-byte / depth 48 是工具保护上限，**不是生产预算**。不把当前观测最大值加任意安全系数冻结为发行上限。商业预算需 Config manifest 冻结每个任务目标/阶段 fact/技能构筑/候选/图鉴条目的最大数量和 ID/文本长度，生成真正最大合法状态后测量。

当前优化前 codec/capture/restore 的几十毫秒及全封装百毫秒级开销只能安排在暂停/加载流程，尚未达到可批准的最低配置指标；进度 UI 阈值需目标 Windows 设备实测。

## Acceptance Criteria

- SDA01：五域缺字段/错类型/未知字段/u63 overflow 被拒；Python 与 Godot 均测。
- SDA02：历史购买后收入仍合法；终身 spent 不足覆盖 receipt 拒绝。
- SDA03：迁移库存保留但不提前开放备战；实际 PILL 配方配对与 gate 必须成立。
- SDA04：PREPARED 承诺一致；运行态未完成 offer 拒绝；缺 Preparation provider 拒绝。
- SDA05：同 tick required-owner 精确集合；缺 owner、重复 owner、错版本/身份拒绝。
- SDA06：RESULT_PENDING after-image 无递归，缺 SettlementComplete 拒绝；真实 transaction 验收 OPEN。
- SDA07：暂停 capture→canonical codec→fresh restore→600 tick 与未中断分支逐项一致。
- SDA08：五种压力切点各恢复后 50 tick 一致；T+1 队列、召唤 RNG、bite 已命中与 fog 59→60 保留。
- SDA09：越界、零 ID、超大有限速度、伪升级/构筑、晚 tick 无 Boss、巨大 timer、计数耗尽拒绝。
- SDA10：失败验证不改变 fresh scope；成功 teardown 后 Pool/Grid 借出计数为零；旧输入不复用。
- SDA11：记录 payload/slot 双层字节、完整 seven-domain after-image、capture/restore、codec/flush/readback耗时、可观察内存与进程峰值，明确测量边界。
- SDA12：完整商业 owner/最大可达状态、v1 磁盘迁移、Save v2 OS锁/kill/断电/云冲突/Windows 与正式 GDD full review 仍 OPEN；battle_ready=false。

- SDA13（WP04c）：后一个 owner 的身份/版本/shape/字节错误时，所有语义 callback 调用次数为零。
- SDA14（WP04c）：owner 完整 row 与 checkpoint UTF-8 恰好上限接受，超过一字节拒绝；这些上限不是商业预算。
- SDA15（WP04c）：callback 修改副本不影响原输入；错误返回类型拒绝；缺联合 validator 拒绝，同 tick 不相容的联合状态拒绝。
- SDA16（WP04c）：Save 根/run 与 payload 绑定不符拒绝；配置副本不能被调用方删减 owner；任何 checkpoint OK 后 production_admission 仍关闭。
