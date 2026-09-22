# Progression Tree（功法树）

> 2026-09-22 第四至八章本地交付：40关有限遭遇、区域精英、场地关闭、六种Boss与护送路标XP已实现。最终安全C01和逐章角色备战风险两路线各64/64、结局重启通过，共1235次磁盘恢复/213461tick对照；24套回归、实际PCK续玩/第三章旧包零写入兼容通过。C03固定成长压力99/120，不宣称全角色平衡或商业发行完成；新玩家SKIPPED_BY_USER，battle_ready=false。 见[交付证据](../../production/playtest-evidence/2026-09-22-final-chapters.md)与[ADR-0012](../../docs/architecture/adr-0012-late-campaign-encounters.md)。仅Campaign增量，不改变下方legacy ABI或设计评审裁决。

> 2026-09-15 Campaign开发入口A包：三脉索引0/1/2固定为锋意伤害/体魄生命/采灵拾取，新购买1–5阶要求完成0/8/24/40/56程，原4n价格及已购高阶保留。权威数据为campaign_game.json的progression_unlock_completed；Profile执行购买准入、UI显示同一条件。见[实施证据](../../production/playtest-evidence/2026-09-15-package-a.md)。仅CAMPAIGN_GAMEPLAY_V1实现，不覆盖下方旧profile规则或完整Steam owner合同；独立复审待执行。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：Steam v2保持旧3×5成长原值，章节/内容解锁另属Campaign；新迁移与完成after-image按save-steam-pc.md、campaign-flow.md。具体domain schema/migration/快照预算待本owner冻结，不能因路由声明视为生产接入。

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / economy-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-07 — Save generic mutation V2 ABI传播
> **Implements Pillar**: 少量、明确、不过度替代走位与构筑的永久成长
> **Scope**: MVP三分支五级功法树、功法残页消费、永久档案、下一局战斗投影与满级perk；不含局内技能升级、装备、境界、洗点或商业化

## 1. Overview

Progression Tree 是局外永久成长与“功法残页”唯一业务 owner。它提供青元剑诀、长春功、大衍诀三条互不排斥的五级分支，原子消费统一残页并生成下一局只读战斗投影；SaveSystem只保存该domain的canonical after-image，不解释功法语义。

系统让玩家在每局后选择“下一步更重攻伐、生存还是推演”，但三支最终都能圆满，选择的是先后顺序而非不可逆职业。所有加成只在下一局Config snapshot构建时生效，不热改当前战斗，也不允许永久数值替代走位、构筑与Boss机制。

## 2. Player Fantasy

玩家像韩立一样稳步积累、谨慎补足短板：打不过强敌可先修青元，容错不足可养长春，成型太慢可推大衍。每一级都给出小而可理解的收益，第五级“圆满”提供一次明确的质变，但没有隐藏主修锁、随机词条或付费捷径。

功法页应让玩家五秒内看懂三件事：现在有多少残页、下一层具体得到什么、圆满后改变什么。购买前能预览余额与实际战斗数值，购买后只有 durable receipt 到达才点亮节点；存档不确定时宁可显示“待核对”，也不假装扣款或升级成功。

## 3. Detailed Design

### 3.1 Owner、范围与驱动

- ProgressionTree是app-scope feature service，不是GameRoot七phase participant；四类gameplay contribution均为0。
- 唯一拥有：功法残页余额/收支守恒、三分支level、购买资格/command/receipt、Progression domain codec、下一局投影公式与perk语义。
- 不拥有：终局事实/奖励资格、Save介质、战斗HP/伤害/RNG、SkillDraft局内技能、Home布局或Settlement奖励展示。
- MVP无洗点、退款、装备、境界突破、分支锁、跨分支前置、随机节点、重复可购买节点、prestige或残页兑换。
- 功法页从首局前即可查看；余额0时所有购买自然不可用。首次获得正余额后只显示一次短说明，不自动弹窗打断结算/Home。

### 3.2 Stable IDs 与配置树

`ProgressionBranchIdV1={QINGYUAN=1,LONGCHUN=2,DAYAN=3}`，0为INVALID。`ProgressionEffectIdV1`固定：

| Stable ID | Effect | Per-level | L5 perk |
|---|---|---:|---|
| `QINGYUAN_ATTACK` | 玩家基础攻击投影 | +3% | `QINGYUAN_FAMILY` projectile pierce +1 |
| `LONGCHUN_MAX_HP` | 下一局最大生命 | +3% | 首次非致命跌破30%时恢复10%最大生命 |
| `DAYAN_CRIT_PICKUP` | 暴击率/拾取范围 | +1百分点 / +2% | 每局初始免费刷新+1 |

`ProgressionTreeConfigV1={schema_version=1,content_revision,branch_count=3,branches[3],cost_rows[15],config_hash}`。branch必须按ID升序，每支恰5条target level 1..5成本，`PROVISIONAL-ECONOMY-V1` baseline统一为`4/8/12/16/20`；effect/perk ID不得复用或省略。Config缺行、重行、乱序、unknown ID、成本非正或checked sum失败时，功法页保持只读且新局Config build失败。

三个分支独立：当前level为L时只允许购买同分支`L→L+1`；可以在任意两次购买之间切换分支。第五级从0级起就可预览，购买4→5与perk enable必须在同一after-image发生。

### 3.3 Persistent domain

```text
ProgressionProfileDomainV1={
  schema_version:i32=1,
  domain_revision:i64,
  progression_content_revision:i64,
  unspent_pages:i64,
  earned_pages_total:i64,
  spent_pages_total:i64,
  upgrade_sequence:i64,
  next_purchase_id:i64,
  branch_count:i32=3,
  branch_levels:i32[3],
  has_last_purchase_receipt:i32,
  last_purchase_receipt:ProgressionPurchaseReceiptV1?
}

ProgressionPurchaseReceiptV1={
  schema_version:i32=1,purchase_id:i64,branch_id:i32,
  from_level:i32,to_level:i32,cost_pages:i64,
  balance_before:i64,balance_after:i64,
  base_domain_revision:i64,next_domain_revision:i64,
  request_hash:Hash256
}
```

- canonical payload固定no-padding 80 bytes base、receipt存在时176 bytes max；整数little-endian，branch_levels物理顺序固定`QINGYUAN,LONGCHUN,DAYAN`。
- 空档固定`revision=0,content_revision=current,unspent=earned=spent=upgrade_sequence=0,next_purchase_id=1,levels={0,0,0},has_receipt=0`。
- 不变量：`0≤level≤5`、`0≤upgrade_sequence≤15`、`unspent_pages+spent_pages_total=earned_pages_total`（checked）、`upgrade_sequence=sum(branch_levels)`、`next_purchase_id=upgrade_sequence+1`。
- 功法残页只在此domain有一个钱包；三分支不得各自建货币。MVP唯一sink是节点购买；当前F3 cap下正常满树余额为0，若迁移/调价后仍有合法余额则原值保留，不兑换灵石/种子。
- `progression_content_revision`记录最后成功mutation所用配置；内容更新不重算已花成本或自动买点，兼容规则须显式migration。

### 3.4 Settlement income

Settlement只能提交typed `ProgressionIncomeGrantV1={schema_version,outcome_commit_id,reward_fact_id,amount,base_domain_revision,next_domain_revision}`。`reward_fact_id`必须唯一指向sealed Outcome的`CULTIVATION_PAGES` committed reward row；Progression验证`amount≥0`，生成`unspent'=unspent+amount,earned'=earned+amount,spent'=spent`完整after-image。

收入与同终局其他永久资源由Save终局commit原子落盘；duplicate/stale outcome由Save outcome identity exact-once拦截。`ABANDONED`固定amount0；`TECHNICAL_ABORT`只能按fault前已提交survival事实。actual reward row ID与公式现由Settlement的`CULTIVATION_PAGES=2`和F2签发；本GDD仍拥有余额cap与第4节校准目标。

### 3.5 Purchase command 与Save通用domain mutation

```text
ProgressionPurchaseCommandV1={
  schema_version:i32=1,purchase_id:i64,branch_id:i32,
  expected_level:i32,target_level:i32,expected_cost_pages:i64,
  expected_profile_revision:i64,expected_domain_revision:i64,
  progression_content_revision:i64,config_hash:Hash256,
  request_hash:Hash256
}
```

购买前必须同时满足：GameRoot HOME、Save READY、无unresolved Outcome/Reservation/archive/mutation、writer可接纳、profile/config revision matching、branch level<5、target=level+1、余额≥Config成本。UI传入的cost只用于correlation，owner必须从matching Config重算。

合法购买先构造完整Progression next-domain：扣残页、加level、spent/sequence/next ID/domain revision checked推进并写receipt，全部成功后才交给Save：

```text
ProfileDomainMutationRequestV2={
  schema_version:i32=2,operation_id:i64,attempt_generation:i64,
  request_id:i64,domain_id:i32,
  expected_profile_revision:i64,expected_domain_revision:i64,
  mutation_kind:i32,business_operation_id:i64,request_hash:Hash256,
  next_domain_record:DomainRecordV1
}
```

`business_operation_id`逐位等于`purchase_id`；每个fresh attempt必须使用checked非零`attempt_generation`与Save持久allocator签发的非零`request_id`。Save结构性替换唯一domain并推进profile revision，不解释payload。`ProfileDomainMutationResultV2`封闭code为`SUCCEEDED=1,FAILED=2,UNCERTAIN=3,RECONCILE_FOUND=4,RECONCILE_NOT_FOUND=5,STALE_REVISION=6,CONFLICT=7`，带matching operation/attempt/request/purchase/profile/domain revision与非零receipt ID/hash；不得伪造`outcome_commit_id`复用终局九code reducer。

Save必须把请求、旧/新revision、next record与operation identity写入`DurableProfileMutationRecoveryV1`，遵守同一temp+双槽协议。UNCERTAIN时冻结全部新购买，只允许同operation reconcile；FOUND采用durable next profile，NOT_FOUND仍UNCERTAIN。FAILED可回READY但必须保持已确认旧profile；不同fresh command同base revision只有第一个CAS成功，失败者不得自动改绑新revision。

### 3.6 Purchase presentation state

| State | Valid entry | Allowed exit / exact result |
|---|---|---|
| `READY` | profile/config/save均可用 | 选择next node→CONFIRMING；不可购则保持并给具体原因 |
| `CONFIRMING` | matching preview打开 | 取消→READY且0写；确认→MUTATION_PENDING |
| `MUTATION_PENDING` | request staged/in-flight | success→READY(new profile)；failed→READY(old profile)；timeout→MUTATION_UNCERTAIN |
| `MUTATION_UNCERTAIN` | 同operation可能durable | reconcile found→READY(new)；not found保持；禁止取消/新购/新局 |
| `READ_ONLY_BLOCKED` | Save恢复/升级/冲突、Config非法 | 依赖恢复后→READY；0 purchase CTA |

同帧双击只coalesce成同一command；即便余额足够买两级，也必须等新profile publish后由fresh press创建下一级command。durable success后无撤销/退款；防误触由确认层承担。

### 3.7 Next-run battle projection

```text
ProgressionBattleProjectionV1={
  schema_version:i32=1,source_profile_revision:i64,
  source_domain_revision:i64,progression_content_revision:i64,
  qingyuan_level:i32,longchun_level:i32,dayan_level:i32,
  attack_bonus_ratio:f64,max_hp_bonus_ratio:f64,
  crit_bonus_points:f64,pickup_bonus_ratio:f64,
  qingyuan_extra_pierce:i32,longchun_charge_count:i32,
  longchun_threshold_ratio:f64,longchun_recovery_ratio:f64,
  extra_free_refreshes:i32,projection_hash:Hash256
}
```

Config在BATTLE_LOADING只从一个durable profile/domain revision生成并逐字段hash。Player、Damage、Weapon、Drop、SkillDraft只读matching projection；Active、Paused、Resume或late Save callback均不得热改。本局结束后释放projection与战斗carrier，不修改永久domain。

- 青元攻击只写Damage F1的`attack A`来源，禁止再写`generic_damage_multiplier`造成双算。
- 青元L5的+1 pierce作用于`QINGYUAN_FAMILY`所有会生成projectile hit链的基础/升级/进化形态；剑阵纯环绕direct tick不凭空获得pierce。Weapon/Projectile/Damage actual hit/workload容量重算前该perk integration为BLOCKED。
- 长春L5令Player每局初始化`longchun_charge_count=1`。Damage以post-damage非致命严格crossing产生typed recovery resolution；Player phase6把实际恢复与charge 1→0原子提交。
- 大衍L5令SkillDraft初始free refresh为3而非2；只在初始snapshot事务写入一次，刷新不会创建新blocking choice。

### 3.8 Longchun emergency recovery

触发条件固定：matching damage batch前`hp_before≥0.30*max_hp`，伤害后`0<hp_after_damage<0.30*max_hp`，lethal=false，charge=1且terminal winner未抑制。恰等30%不触发；已经低于30%后继续受伤不触发。

Damage生成`LONGCHUN_EMERGENCY/MAX_HP_RATIO=0.10` recovery contribution并按现有damage→lethal→nonlethal recovery顺序结算；同tick其他recovery仍按Damage canonical priority聚合。Player只有在matching resolution实际提交时才把charge消费为0；PONR前fault保持1，PONR后由GameRoot收敛，不允许扣charge但不加HP。致命伤不触发也不消费；替身符复活到35%后，后续首次合法crossing仍可触发。每局无论pause/revive最多一次。

## 4. Formulas

### F1 — Node cost

The `progression_node_cost` formula is defined as:

`cost(target_level) = 4 × target_level`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Target level | `T` | int32 | 1–5 | 本次购买后的level |
| Cost | `C` | int64 | 4–20 | Config实际row，公式golden |

**Output Range:** 4 to 20 pages；T不在1..5时拒绝，不clamp。

**Example:** 购买第4级：`4×4=16`页。

### F2 — Branch cumulative cost

The `progression_branch_spent` formula is defined as:

`branch_spent(level) = Σ(k=1..level)(4k) = 2 × level × (level + 1)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Branch level | `L` | int32 | 0–5 | 已购买层数 |
| Cumulative spent | `S` | int64 | 0–60 | 单支累计成本 |

**Output Range:** 0 to 60 pages；三支总成本180。

**Example:** L=3时`2×3×4=24`页；L=5时60页。

### F3 — Settlement page grant target

The `progression_page_grant` formula is defined as:

```text
raw_pages = outcome_kind == ABANDONED
    ? 0
    : min(8, floor(committed_survival_ticks / 5400))
grant_room = max(0, remaining_tree_cost - unspent_pages)
granted_pages = min(raw_pages, grant_room)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Committed survival ticks | `t` | int64 | 0–INT64_MAX | 仅sealed committed Active ticks，60Hz |
| Milestone ticks | `M` | int64 | 5400 | 90秒一个完整里程碑 |
| Raw pages | `R` | int64 | 0–8 | 不加胜利bonus |
| Remaining tree cost | `Crem` | int64 | 0–180 | 当前Config下所有未购节点cost checked sum |
| Unspent pages | `B` | int64 | 0–180 | durable余额 |
| Granted pages | `G` | int64 | 0–8 | 实际写入domain金额 |

**Output Range:** 0 to 8 pages；ABANDONED恒0，TECHNICAL_ABORT只取fault前完整里程碑，全树或余额已足够购买剩余节点时为0。

**Example:** 存活10:27即37620 ticks，`floor(37620/5400)=6`；若剩余成本4且余额2，则实际grant=2。

本式是`PROVISIONAL-ECONOMY-V1`且actual owner为BattleRules/Settlement。它要求正常结算局平均实际grant中位数6..8，才能支持一支8..10局、全树23..30局；设计文档数学推演不能替代试玩。

### F4 — Atomic purchase after-image

The `progression_purchase_after_image` formula is defined as:

```text
next_balance = balance - cost
next_level = level + 1
next_spent = spent_pages_total + cost
next_upgrade_sequence = upgrade_sequence + 1
next_purchase_id = purchase_id + 1
next_domain_revision = domain_revision + 1
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Balance | `B` | int64 | C–180 | 已确认余额 |
| Cost | `C` | int64 | 4–20 | F1/Config matching成本 |
| Current level | `L` | int32 | 0–4 | 目标分支当前级 |
| Spent total | `S` | int64 | 0–176 before purchase | 历史实际消费 |
| Upgrade sequence | `U` | int64 | 0–14 before purchase | 全树已购节点数 |
| Purchase ID | `P` | int64 | 1–15 | 当前next unused local ID |
| Domain revision | `D` | int64 | 0–INT64_MAX | 乐观并发revision |

**Output Range:** balance保持0..180、level 1..5、spent 4..180、sequence 1..15；任一guard/checked arithmetic失败则整份after-image为0写入。

**Example:** B=20、青元L2、C=12时输出B'=8、L'=3，spent/sequence/revision各checked+1。

### F5 — Qingyuan attack projection

The `progression_resolved_attack` formula is defined as:

`resolved_attack = base_attack × (1 + 0.03 × qingyuan_level)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base attack | `A0` | float64 | 10 MVP；finite >=0 | registry/Config基础攻击 |
| Qingyuan level | `Q` | int32 | 0–5 | durable分支level |
| Bonus ratio | `Bq` | float64 | 0–0.15 | 加法百分比 |

**Output Range:** baseline 10 to 11.5；通用schema上限由Config签发，非finite/越界拒绝。

**Example:** Q=3：`10×1.09=10.9`。结果只进入Damage F1的A，不再进入Mg。

### F6 — Longchun maximum HP projection

The `progression_resolved_max_hp` formula is defined as:

`resolved_max_hp = base_max_hp × (1 + 0.03 × longchun_level + preparation_max_hp_bonus_ratio)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base maximum HP | `H0` | float64 | 100 MVP；[1,1,000,000] | Player base |
| Longchun level | `L` | int32 | 0–5 | durable分支level |
| Preparation bonus | `Bp` | float64 | 0 or 0.15 | 锻体丹已消费投影 |

**Output Range:** baseline 100 to 130（L5+锻体丹）；最终必须finite且位于Player `[1,1,000,000]`。

**Example:** L5且使用锻体丹：`100×(1+0.15+0.15)=130`，不是132.25。

### F7 — Dayan critical chance

The `progression_resolved_crit_chance` formula is defined as:

`resolved_crit_chance = base_crit_chance + 0.01 × dayan_level`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base crit chance | `C0` | float64 | 0.05 MVP；[0,1] | Damage基础值 |
| Dayan level | `D` | int32 | 0–5 | durable分支level |
| Added points | `Bd` | float64 | 0–0.05 | 百分点加法，不是倍率 |

**Output Range:** baseline 0.05 to 0.10；超出[0,1]时fail closed，不clamp。

**Example:** D=4：`0.05+0.04=0.09`；Damage仍使用strict `u<C`。

### F8 — Dayan pickup radius

The `progression_pickup_radius` formula is defined as:

`pickup_radius = pickup_radius_base × (1 + 0.02 × dayan_level)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base radius | `R0` | float64 | 1.8 world units | registry权威值 |
| Dayan level | `D` | int32 | 0–5 | durable分支level |
| Bonus ratio | `Br` | float64 | 0–0.10 | 对base的加法百分比 |

**Output Range:** 1.8 to 1.98 world units；查询buffer仍由DROP cap300决定。

**Example:** D=3：`1.8×1.06=1.908`；D=5为1.98。

### F9 — Max-level perk projection

The `progression_max_perks` formula is defined as:

```text
qingyuan_extra_pierce = qingyuan_level == 5 ? 1 : 0
longchun_charge_count = longchun_level == 5 ? 1 : 0
extra_free_refreshes = dayan_level == 5 ? 1 : 0
initial_free_refreshes = 2 + extra_free_refreshes
longchun_threshold_hp = 0.30 × resolved_max_hp
longchun_raw_recovery = 0.10 × resolved_max_hp
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Branch levels | `Q/L/D` | int32 | 0–5 | 三支level |
| Base refreshes | `F0` | int32 | 2 | SkillDraft基础值 |
| Resolved max HP | `H` | float64 | [1,1,000,000] | F6输出 |

**Output Range:** pierce/charge/extra refresh各0或1，initial refresh 2或3；threshold=0.30H，raw recovery=0.10H。

**Example:** 三支L5且H=115：pierce=1、charge=1、refresh=3、threshold=34.5、raw recovery=11.5。

## 5. Edge Cases

- **If level为0/4/5**：0可买1；4可原子买5并启用perk；5返回`MAXED`且余额/revision不变。
- **If target不是current+1**：返回`STALE_LEVEL`，不允许跳级、批量购买或由双击自动买两层。
- **If balance为cost−1/cost/cost+1**：分别拒绝/余额归零成功/保留1成功；绝不出现负余额。
- **If 两个分支command基于同profile revision**：Save按到达串行CAS仅一个成功，另一条`STALE_REVISION`；不自动rebase。
- **If 同purchase ID同payload重复100次**：coalesce/返回原pending或receipt，扣款和升级各至多一次；同ID异payload为CONFLICT。
- **If Save在PONR前明确失败**：确认数据保持旧值并回READY；可由fresh press重建command，不显示已研习。
- **If Save结果不确定或callback丢失**：冻结购买与新局，仅reconcile同operation；不得先回滚UI再重买。
- **If durable success晚于UI重建**：用receipt/profile revision投影一次新状态；成功动画/音频不重播。
- **If Settlement重复提交同outcome残页**：Save outcome identity拒绝二次income；earned/balance只推进一次。
- **If ABANDONED或不足完整90秒**：grant=0；不补齐里程碑、不显示虚假“+0奖励”卡片。
- **If TECHNICAL_ABORT**：只用fault前committed完整90秒里程碑；不加胜利页、不读未提交tick。
- **If 余额已足够购买所有剩余节点**：后续grant被无损cap到0；不强迫消费、不转换其他货币。
- **If 全树已满**：全部purchase CTA关闭，当前基线正常路径余额为0、后续残页收入0；迁移/调价留下的合法非零余额保留，不自动清零、兑换或prestige/reset。
- **If 青元L5后技能升级或进化**：QINGYUAN_FAMILY projectile仍+1 pierce；纯环绕direct伤害不获得虚构穿透。
- **If 青元perk使hit/workload超出旧容量**：battle load fail closed；不得截断最后一次命中或只在压力下关闭perk。
- **If HP恰等30%**：长春不触发；只有从`>=30%`经非致命伤害到`<30%`才触发。
- **If 致命伤直接越过30%**：长春不触发、不消费charge，不代替替身符；复活后仍可后续触发。
- **If 同tick另有恢复**：crossing以伤害后、恢复前HP判断；所有恢复由Damage canonical顺序聚合，Player只发布一次最终HP。
- **If 已低于30%再受伤或治疗后仍低于30%**：不构成新的crossing；每局charge最多消费一次。
- **If 大衍L5新局初始化失败**：整个SkillDraft初始snapshot不发布，不能出现loadout已建但刷新仍2或3的半状态。
- **If 当前战斗中购买/迁移/late reconcile改变profile**：当前battle projection逐位不变，仅下一局读新revision。
- **If level、余额、count、ID或hash语义非法**：Save按CORRUPT_BLOCKED/UPDATE_REQUIRED保留原bytes；Progression不得clamp或重建空档。
- **If Config成本更新**：已购等级/历史spent不追溯重算；新成本只作用后续节点，必须经content revision与migration/经济公告策略。
- **If 玩家取消确认页**：0 request、0 ID reserve、0写盘、0音频；提交后不提供伪取消。

## 6. Dependencies

| Dependency | Direction / interface | Current status |
|---|---|---|
| SaveSystem | Progression提供domain codec/after-image；Save提供generic mutation、reconcile与durability | generic mutation ABI已静态反向传播；crash/runtime evidence BLOCKED |
| Config/Data | 提供15-row成本/effect/perk manifest，构建matching battle projection | manifest/copy边界已静态传播；actual codec/hash/runtime BLOCKED |
| BattleRules / Settlement | sealed survival reward row→ProgressionIncomeGrant→终局after-image | Designed / Full Review Pending；F3仍为provisional economy |
| PlayerController | 读取resolved maxHP与longchun charge，phase6原子应用恢复+消费 | maxHP已接；charge/receipt BLOCKED |
| DamageSystem | 读取resolved attack/crit，检测Longchun crossing并产出唯一recovery resolution | 基础公式已在；Progression/Longchun ABI BLOCKED |
| Weapon/Projectile | QINGYUAN_FAMILY projectile额外pierce1及worst-case hit rows | pierce形态与容量重算 BLOCKED |
| Drop/SpatialGrid | matching actual pickup radius 1.8..1.98；DROP buffer仍300 | max值已冻结，per-level projection接线 BLOCKED |
| SkillDraft/RNG | initial refresh 2或3；每页RNG不变，单session最大pages 3→4/calls15→20 | 已静态传播；runtime replay BLOCKED |
| Home UI | 功法页、确认、pending/uncertain/reconcile、无障碍 | Designed / Full Review Pending；runtime/UX evidence OPEN |
| Audio Feedback | durable purchase/圆满一次性语义事件 | event ABI/assets仍BLOCKED |

Progression不依赖Leveling/XP：局内等级和局外功法等级是不同domain。Zhangtian与Progression同为Save domain client，彼此不读写；并发时只通过Save profile revision CAS仲裁。掌天种子/药丸按每种cap999的稳定loadout资源处理，不与残页构造稀缺兑换或互相补偿；任一cap饱和不得阻塞Progression mutation或正常终局Save。

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| branch count / levels | 3 / 5 | FIXED MVP | 改动需产品scope+schema migration |
| node costs | 4/8/12/16/20 | PROVISIONAL-ECONOMY-V1 | Settlement+30局试玩后锁定 |
| survival milestone | 5400 ticks / 90 sec | PROVISIONAL-ECONOMY-V1 | 不得提高速死每分钟效率 |
| pages per run cap | 8 | PROVISIONAL-ECONOMY-V1 | 与成本/局数目标联调 |
| attack per Qingyuan level | +0.03 | CONCEPT LOCKED | 平衡可修订需全构筑回归 |
| maxHP per Longchun level | +0.03 | CONCEPT LOCKED | 与Player F3A一致 |
| crit points per Dayan level | +0.01 | CONCEPT LOCKED | 是百分点，不是倍率 |
| pickup ratio per Dayan level | +0.02 | CONCEPT LOCKED | L5必须1.98 |
| Qingyuan L5 extra pierce | +1 | CONCEPT LOCKED | workload重算前integration BLOCKED |
| Longchun threshold/recovery | 0.30 / 0.10 maxHP | CONCEPT LOCKED | strict crossing、非致命、每局一次 |
| base / max Dayan refresh | 2 / 3 | CONCEPT LOCKED | SkillDraft/RNG传播 |
| domain payload max | 176 bytes | FIXED V1 | schema改变需migration |

所有战斗效果虽来自概念锁定，仍缺15分钟胜率/构筑/走位实测；“CONCEPT LOCKED”不等于balance verified。

## 8. Visual / Audio / UI Requirements

功法页是Home内的次级页面，不新增第五个主导航。采用三张纵向紧凑分支卡，而不是需要缩放/拖拽的大树图；顶部持续显示功法残页和总进度`x/15`。

每张卡必须同时显示分支定位、当前累计效果、0/5层级轨、下一层效果/成本与从首级即可见的圆满perk。大衍必须分别显示暴击与拾取范围，详情可显示`1.80→1.98`；不得只写“推演提升”。

购买确认bottom sheet显示：当前→目标效果、本次成本、现有余额、购买后余额；4→5单独列圆满perk。唯一主CTA“研习”，次操作“暂不研习”。提交后显示“正在记录本次研习…”，不可重复购买或开新局；UNCERTAIN显示“研习结果待核对，确认前不会再次扣除残页”。

只有durable success才减少画面余额、点亮节点并发布一次成功反馈。普通升级反馈短于局内进化；单支圆满可有一次克制的墨迹连线/印章和短音，三脉圆满不额外赠送未设计总加成。reconcile found/UI重建不得重播。

状态不能只靠颜色：已研习=实体印记+勾；next=描边+“可研习”；未来层=锁+“先研习上一层”；圆满=完整印章+“圆满”。触控目标≥48dp，130%字体、720×1280窄屏、灰阶/常见色弱、静音均需成立。

结算页只提供次级“前往研习”，获得残页不自动弹窗。Home入口可显示“可研习”角标、`总进度6/15`或“三脉圆满”；Save未决时显示“功法变更待确认”，不得写“已研习”。正式界面需后续`/ux-design`，本节不是完成资产/UX证据。

## 9. Acceptance Criteria

- **AC-PT01 `[L/C][BLOCKING]` — GIVEN** 3 branch与15 cost/effect rows的合法/缺/重/乱序fixture，**WHEN** Config加载，**THEN** 仅QINGYUAN/LONGCHUN/DAYAN各5级与唯一perk通过，非法表在UI/Save写前失败。
- **AC-PT02 `[L/C][BLOCKING]` — GIVEN** 单钱包与伪造分支钱包，**WHEN** decode/入账/购买，**THEN** 只有非负int64功法残页权威，`unspent+spent=earned`逐次成立。
- **AC-PT03 `[L/C][BLOCKING]` — GIVEN** target level1..5，**WHEN**求cost与累计，**THEN**逐级4/8/12/16/20、累计4/12/24/40/60，三支总180；0/负/overflow配置拒绝。
- **AC-PT04 `[L][BLOCKING]` — GIVEN** domain合法与unknown/duplicate/trailing/hash/length异常bytes，**WHEN** encode→decode→re-encode，**THEN**合法逐位相同且max176 bytes，非法在allocation/write前拒绝。
- **AC-PT05 `[L][BLOCKING]` — GIVEN** level0..5、balance为cost−1/cost/cost+1及matching/stale revisions，**WHEN**购买，**THEN**只允许0..4的next level且余额足够、Save READY、revision matching路径。
- **AC-PT06 `[L/I][BLOCKING]` — GIVEN** typed command matching/stale/conflict/cross-profile，**WHEN**提交，**THEN**owner从Config重算cost；stale 0写且要求刷新，同ID异payload CONFLICT。
- **AC-PT07 `[L/I][BLOCKING]` — GIVEN**合法L/B/C，**WHEN**购买durable，**THEN**level+1、balance−C、spent+ C、sequence/ID/revision+1与receipt处于同一after-image；PONR前失败旧档逐位不变。
- **AC-PT08 `[I][BLOCKING]` — GIVEN**同command点击/callback/rebuild/restart重放100次，**WHEN**处理，**THEN**最多一次扣款、一次升级、一个receipt、一次成功反馈。
- **AC-PT09 `[I][BLOCKING]` — GIVEN**不同分支两个command使用同profile revision并乱序，**WHEN**Save串行CAS，**THEN**仅一条成功，另一STALE/BUSY且不自动rebase。
- **AC-PT10 `[I][BLOCKING]` — GIVEN**余额足够两级且同分支双击，**WHEN**提交，**THEN**只coalesce 0→1；1→2必须新profile publish后fresh press。
- **AC-PT11 `[I][BLOCKING]` — GIVEN**Profile mutation在PONR前可证明失败，**WHEN**返回FAILED，**THEN**confirmed balance/level不变，可fresh retry且“已研习”出现数0。
- **AC-PT12 `[I][BLOCKING]` — GIVEN**首槽可能durable但callback丢失/镜像失败，**WHEN**恢复，**THEN**同operation进入UNCERTAIN并冻结购买/新局；FOUND应用一次，NOT_FOUND仍不判FAILED。
- **AC-PT13 `[I][BLOCKING]` — GIVEN**终局commit、功法购买与未来掌天瓶mutation竞争，**WHEN**Save处理，**THEN**physical writer≤1、每项写前重扫profile revision，局外购买使用generic mutation ABI而非伪outcome ID。
- **AC-PT14 `[I][BLOCKING]` — GIVEN**Save temp write、首份PONR、mirror、readback、callback各故障点，**WHEN**重启scan/reconcile，**THEN**只恢复完整旧或新profile，不存在币/等级撕裂。
- **AC-PT15 `[L/I][BLOCKING]` — GIVEN** level−1/0/4/5/6，**WHEN**购买，**THEN**0与4合法推进，4→5同transaction启用perk，5返回MAXED，非法持久值拒绝而非clamp。
- **AC-PT16 `[L/I][BLOCKING]` — GIVEN**三支均5，**WHEN**打开/重复购买/新结算，**THEN**15节点持久、purchase CTA全关、grant=0、无兑换/reset/prestige，三perk仅投影下一局。
- **AC-PT17 `[L/C][BLOCKING]` — GIVEN**青元0..5，**WHEN**构建projection，**THEN**attack=10×(1+0.03Q)，L5=11.5且只写Damage Attack A一次。
- **AC-PT18 `[I][BLOCKING]` — GIVEN**青元4/5及family基础/升级/进化执行，**WHEN**生成projectile plan，**THEN**仅L5的QINGYUAN_FAMILY projectile pierce+1，direct tick/其他family不变；容量未重算时load失败。
- **AC-PT19 `[L/I][BLOCKING]` — GIVEN**长春0..5×锻体丹false/true，**WHEN**新snapshot build，**THEN**沿用Player F3A，L5无丹115、有丹130，current=max且Active不热改。
- **AC-PT20 `[L/I][BLOCKING]` — GIVEN**长春4/5、charge0/1及30%±epsilon/致命/重复crossing，**WHEN**Damage+Player结算，**THEN**仅L5首次非致命严格跌破触发0.10H并与charge消费原子；致命0恢复。
- **AC-PT21 `[L/I][BLOCKING]` — GIVEN**大衍0..5与u位于C−ε/C/C+ε，**WHEN**Damage判暴击，**THEN**C=.05+.01D、L5=.10，strict u<C且每eligible hit仍恰1 roll。
- **AC-PT22 `[L/I][BLOCKING]` — GIVEN**大衍0..5与Drop在radius内/相切/外ε，**WHEN**查询，**THEN**radius=1.8×(1+.02D)、L5=1.98，相切命中且buffer保持DROP cap300。
- **AC-PT23 `[L/I][BLOCKING]` — GIVEN**大衍4/5 fresh battle，**WHEN**SkillDraft初始化并消费刷新，**THEN**charges分别2/3，L5序列3→2→1→0，每次exact-once；最大单session页4、RNG calls20。
- **AC-PT24 `[I][BLOCKING]` — GIVEN**battle A snapshot冻结后profile购买/迁移/reconcile，**WHEN**A继续/暂停/恢复，**THEN**七个projection字段逐位不变；battle B只读durable新revision。
- **AC-PT25 `[I][BLOCKING]` — GIVEN**BATTLE_LOADING后late mutation试图写Player/Damage/Weapon/Drop/SkillDraft，**WHEN**处理，**THEN**battle authority写入0、无HP补差/新增刷新/中途pierce或crit变化，只标next-run revision。
- **AC-PT26 `[L/I][BLOCKING]` — GIVEN**registered migration steps与未来/损坏schema，**WHEN**加载，**THEN**已知step按golden幂等迁移且不发奖励/自动购买；未知走UPDATE_REQUIRED/CORRUPT_BLOCKED并保留bytes。
- **AC-PT27 `[L][BLOCKING]` — GIVEN**0..12分钟及ABANDONED/TECHNICAL/Victory，**WHEN**F3求grant，**THEN**每完整5400 tick一页、cap8、无胜利bonus、ABANDONED 0、technical只取committed milestone。
- **AC-PT28 `[L/I][BLOCKING]` — GIVEN**currency/cost/grant/revision/purchase ID在0/1/MAX−1/MAX且战斗投影非finite/越界，**WHEN**运算，**THEN**全部checked，失败前0 mutation/write/sound，不wrap/clamp。
- **AC-PT29 `[UX/E][OPEN-EVIDENCE]` — GIVEN**冻结成本/产出与至少30名目标新玩家，**WHEN**完整成长试玩，**THEN**正常结算实际grant中位数6..8、首支圆满中位数8..10局/P75≤12、全树≤30局，且早死每分钟效率不高于完整局。
- **AC-PT30 `[E][BLOCKING]` — GIVEN**静态GDD/schema、mock Save、crash harness、真机与试玩artifact，**WHEN**签收，**THEN**分别标STATIC/UNIT/CRASH-RUNTIME/DEVICE/BALANCE；按钮变灰或一次正常存档不得宣称exact-once/平衡通过。

## 10. Open Questions / Evidence Gates

| ID | Question / gate | Owner | Closure evidence | Status |
|---|---|---|---|---|
| OQ-PT01 | F3残页reward row、5400tick里程碑与cap8是否由BattleRules/Settlement接纳？ | BattleRules/Settlement | GDD + golden + replay | BLOCKED |
| OQ-PT02 | generic ProfileDomainMutation/Recovery/Result V1反向纳入Save并经crash review？ | SaveSystem | Save修订 + AC-PT07..14 | PARTIAL：静态ABI已传播，crash review待办 |
| OQ-PT03 | 青元family各形态pierce语义与hit/workload新容量？ | Weapon/Projectile/Damage | Config rows + pressure trace | BLOCKED |
| OQ-PT04 | 长春recovery contribution priority与Player charge PONR receipt？ | Damage/Player/GameRoot | phase5→6 integration trace | BLOCKED |
| OQ-PT05 | SkillDraft 2→2/3 refresh及15→20 calls传播是否完整？ | SkillDraft/RNG/Config | static rows + runtime replay | PARTIAL：静态传播完成，runtime replay待办 |
| OQ-PT06 | ProgressionBattleProjection完整Config schema/hash/copy table？ | Config | artifact + mismatch tests | PARTIAL：静态manifest已传播，codec/test待办 |
| OQ-PT07 | 4/8/12/16/20与每90秒1页是否满足真实新手节奏？ | Economy/QA | AC-PT29预注册试玩 | PROVISIONAL |
| OQ-PT08 | Home功法页、确认/uncertain/无障碍UX与资产？ | Home UI/UX/Art/Audio | UX spec + user test | BLOCKED |
| OQ-PT09 | V1后成本变更如何处理历史spent与余额？ | Product/Economy/Save | migration policy | OPEN before external test |
| OQ-PT10 | clean-context full review与runtime/device证据？ | review team | independent verdict + artifacts | OPEN |

## 11. Handoff

本文冻结三分支×五级、统一残页domain、购买after-image、下一局projection、九条公式、24类edge case与30项AC。`PROVISIONAL-ECONOMY-V1`给出可试玩的4/8/12/16/20成本和90秒里程碑，但不把理论局数当作平衡通过。

Zhangtian、Settlement、Home与Prep作者GDD现已补齐并完成本轮静态传播。本文状态保持`In Review / Re-review Pending`；Save generic mutation、跨系统runtime/device/balance与clean-context full review未闭合前，不得称implementation-ready、runtime verified或battle_ready。


## 2026-09-16 第二章实现增量

第二章8关已实现固定矿轨与有限遭遇、喷口逐一关闭、冷却匣/炉工护送、中途机缘、指定熔脊行者及炉门弱点三阶段Boss。机制/验收见 `design/chapter-two-playable.md`、`docs/architecture/adr-0010-chapter-two-thermal-encounters.md`；交付证据见 `production/playtest-evidence/2026-09-16-chapter-two.md`。快照CAMPAIGN_CHAPTER2_V1，局外仍CAMPAIGN_GAMEPLAY_V1；第一章8关后开放二阶/第二角色。固定tick派生热场/门窗；Profile保留精确数值并在重写前重建数值镜像，避免多次JSON舍入。此增量不改变第三章以后2+1经验基线，也不声称全游戏经济、商业Save v2或发行验收完成。新玩家试玩SKIPPED_BY_USER，battle_ready=false。


## 2026-09-17 第三章限定交付

第三章8关潮汐内容已实现并完成两条新档1→24连续旅程；规则见 `design/chapter-three-playable.md`、ADR-0011，最终证据见 `production/playtest-evidence/2026-09-17-chapter-three.md`。CAMPAIGN_CHAPTER3_V1；章内经验6/4、180tick升级间隔，覆盖本文件先前“第三章以后不变”的历史表述（第四章以后仍旧基线）。Boss伤害边界同步阶段/悟性、末期整轮zone+projectile容量预检；永久淹池单区且恢复不重复。24关开放三阶，资源富余未全局重平衡。额外64关独立54/64，连续止M06-06，不能称全游戏验收。新玩家SKIPPED_BY_USER，battle_ready=false。
