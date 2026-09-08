# Home UI（黄枫谷洞府首页）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted UX reviewer / qa-lead）
> **Created / Last Updated**: 2026-09-07 — Zhangtian第六次独立full review后作者整改传播
> **Implements Pillar**: 低打扰、目标清晰、谨慎准备；让玩家三秒内找到下一局
> **Scope**: MVP洞府首页、功法/掌天瓶/设置导航、资源摘要、存档恢复阻断与最小Settings domain；不含洞府建设、境界成长、装备、商店、任务、社交或活动入口

## 1. Overview

Home UI 是应用局外入口的consumer-only presenter与typed navigation/settings command adapter。它把同一durable profile revision中的灵石、功法残页、功法进度、种子摘要和设置状态组织成一个安静、清晰的洞府首页，并在Save/Reservation/Archive/Mutation未决时显示唯一恢复路径；它不拥有任何余额、库存、成长、存档或GameRoot状态。

正常闭环固定为 `Home→(有可用种子时Prep；否则direct NONE)→Battle→Settlement→Home/Prep`。首页主CTA按可选库存显示“选择丹药，进入试炼”或“不服丹，开始试炼”；掌天瓶次入口只查看同一库存/规则，不维护第二套业务页。功法为Home下的次级页面，设置为modal/子页。

## 2. Player Fantasy

玩家回到洞府时应立刻获得“收好战果、再做一步准备、马上出发”的稳定感，而不是面对红点、礼包与十几个系统入口。韩立立绘与“筑基初期”只提供氛围，不伪装成可升级境界；真正可操作的只有试炼、功法、掌天瓶和设置。

页面不自动弹出功法树或掌天瓶，不自动花资源。获得新残页或种子只出现一个克制角标；存档异常时用非责备语言说明“正在核对/原文件已保留”，优先保护进度，而不是催促玩家重新开始。

## 3. Detailed Design

### 3.1 Owner boundary 与 information hierarchy

- Home不是GameRoot phase participant；四类gameplay contribution均0。
- 只拥有UI local copy、layout generation、focus/reading order、press identity、页面路由草稿和Settings command。
- 不写TopState、profile/domain、Save attempt、Progression/Zhangtian、音频bus或battle identity；所有动作经typed service command。
- 首页固定信息层级：①进入试炼主CTA；②灵石/残页；③功法/掌天瓶入口；④韩立立绘+静态“筑基初期”；⑤设置。
- 境界文案不可点击、无进度条；MVP不展示装备、宗门、签到、商店、广告、抽卡、邮件或活动占位入口。

### 3.2 Atomic Home bundle

```text
HomePresentationBundleV1={
  schema_version:i32=1,top_state:i32,view_generation:i64,
  profile_revision:i64,settlement_domain_revision:i64,
  progression_domain_revision:i64,zhangtian_domain_revision:i64,
  settings_domain_revision:i64,save_state_revision:i64,
  spirit_stones:i64,cultivation_pages:i64,
  progression_nodes_bought:i32,available_seed_total:i64,
  zhangtian_unlocked:i32,settings_summary:SettingsViewV1,
  config_content_revision:i64,direct_none_allowed:i32,
  direct_none_start_slice:DirectNoneStartSliceV2,
  save_presentation:SavePresentationViewV1,
  unresolved_carrier_bits:i32,archive_ready:i32,bundle_hash:Hash256
}
```

GameRoot/Home adapter只发布来自同一confirmed profile与当前Save scan的sealed bundle；各domain revision不要求数值相等，但必须被同一profile revision/hash包含。任一source stale、负值、unknown state或hash不匹配时，保留上一完整帧或进入noninteractive BLOCKED；禁止显示新残页+旧功法节点、新种子+旧解锁状态。

### 3.3 Normal Home content

- 顶部safe-area：灵石完整值、功法残页完整值、设置按钮。
- 中部：韩立立绘、“当前：筑基初期”；没有境界系统入口。
- 下部单手区：available_seed_total>0时主CTA `选择丹药，进入试炼`；否则为`不服丹，开始试炼`。次级卡为 `功法`、`掌天瓶`。
- 功法卡只显示`总进度 x/15`及`可研习/三脉圆满`；完整树沿Progression GDD。
- 掌天瓶未解锁显示`首局正常结算后开启`；仅首个durable正常`VICTORY|DEFEAT`结算令confirmed domain从locked转unlocked，`ABANDONED|TECHNICAL_ABORT`不解锁。已解锁显示`可用种子 N`，其中三种confirmed count各`0..999`且排除reservation中的数量。available>0时主CTA进入Prep；未解锁或available=0时主CTA直接提交明确NONE，Prep页面创建0。掌天瓶说明入口可展示非交互药效预览，但不得制造第二个开局确认步骤。
- 每入口至多一个静态角标；首次durable positive balance/seed/unlock可置一次“新”，查看后只更新presentation preference，不影响业务资源。

### 3.4 Navigation commands

`HomeDestinationV1={PREP=1,PROGRESSION=2,SETTINGS=3}`。UI只发送：

```text
HomeNavigationCommandV1={
  schema_version:i32=1,command_id:i64,destination_id:i32,
  expected_top_state:i32,expected_view_generation:i64,
  expected_profile_revision:i64,bundle_hash:Hash256,press_id:i64
}
```

合法导航要求TopState HOME、root input gate已释放给Home、Save READY、无pending outcome/reservation/archive/profile mutation，且destination当前可达。available>0的主CTA只创建PREP destination，不分配battle ID、不抽seed、不扣种子。未解锁或available=0时，Home adapter只从同一confirmed bundle内128-byte `DirectNoneStartSliceV2`逐字段构造唯一`PrepConfirmCommandV1{source_surface_id=HOME_DIRECT_NONE,selected_seed_id=NONE,expected_pill_id=NONE}`；slice只接受`zhangtian_unlocked/starter_seed_grant_claimed=0/0或1/1`，locked时available必须0。source generation、profile/domain/config content revision+hash、save revision、available/两flag与slice hash任一不匹配均为0 command，禁止临时跨owner拼字段。GameRoot由同一press先进入noninteractive PREP/STAGED、创建Prep页面Node=0，再消费该command并与Prep来源共享同一Save/Zhangtian reservation路径。same press/payload coalesce一次，旧generation、滑出release、cancel或第二touch为0 command。

### 3.5 Save and recovery states

| State | Home message | Allowed actions |
|---|---|---|
| `READY` | 正常首页 | available>0→Prep；available=0→HOME_DIRECT_NONE；功法/设置 |
| `HEAL_REQUIRED` | 正在检查本地存档 | noninteractive；自动heal/readback |
| `SAVE_PENDING` | 上一局正在保存 | 等待；设置可session-preview |
| `SAVE_UNCERTAIN` | 上一局保存结果待确认 | 主CTA核对；低强调重试/放弃按Save规则 |
| `SAVE_FAILED` | 上一局进度尚未写入 | 主CTA重试；放弃需二次确认 |
| `DISCARD_PENDING` | 正在确认放弃上一局进度 | 主CTA核对/继续放弃 |
| `RESERVATION_UNCERTAIN` | 开局资源状态待确认 | 只核对/重试matching reservation |
| `RECOVERY_REQUIRED` | 找到一份可验证备份，恢复前不覆盖 | 恢复可验证备份；导出诊断 |
| `CORRUPT_BLOCKED` | 存档无法验证，原文件已保留 | 导出诊断；无静默新档 |
| `UPDATE_REQUIRED` | 存档来自较新版本，不会覆盖 | 导出诊断；真实更新入口存在才显示检查更新 |
| `STORE_CONFLICT` | 两份存档相互冲突，尚未选择 | 重新检测；导出诊断；不得手选覆盖 |

除READY外，进入试炼、功法购买与掌天瓶消费全部由service guard关闭，不能只依赖按钮disabled。恢复页必须把keyboard/gamepad focus放到唯一主恢复CTA并播报状态+可执行动作；返回READY时按原navigation intent恢复焦点，不能自动触发CTA。Settings中的即时静音/减弱动效可作session-local安全覆盖，但持久化失败时明确“本次设置尚未保存”。

### 3.6 Settings persistent domain

```text
SettingsProfileDomainV1={
  schema_version:i32=1,domain_revision:i64,
  settings_content_revision:i64,
  volume_percent:i32[4],
  font_scale_id:i32,reduce_motion:i32,
  reduce_sensory_load:i32,high_contrast:i32,
  screen_reader_hints:i32,locale_id:i32
}
```

顺序固定Master/Music/SFX/UI，volume 0..100；font scale ID固定100/115/130三档；四个bool字段只允许0/1，locale来自Config stable enum。canonical payload固定60 bytes。首次空档默认100/80/80/80、font100、bool0、locale=system-supported mapping；默认值必须来自Config/schema，不读设备音量回写profile。

设置提交走Save generic `ProfileDomainMutationRequestV2`，每个fresh attempt携带nonzero `attempt_generation/request_id`并按同一identity接收`ProfileDomainMutationResultV2`，同样遵守revision CAS/PONR/UNCERTAIN。slider drag只作local audio preview；release/Apply形成一个command。四个volume row必须使用ADR `ADJUSTABLE` role并提供current/min/max/step，四个bool使用`SWITCH`，font scale/locale使用`COMBOBOX`；不得降级成普通button文字。durable success后才更新confirmed settings；取消恢复confirmed值。screen reader是否可用是runtime capability，不因profile bool而声称已接入。

### 3.7 Lifecycle and input states

```text
UNBOUND → STAGED_NONINTERACTIVE → READY
READY → NAVIGATING → DETACHED
READY → SETTINGS_DRAFT → SETTINGS_PENDING → READY|SETTINGS_UNCERTAIN
ANY → BLOCKED
BLOCKED → STAGED_NONINTERACTIVE → READY（依赖真实恢复后）
```

从Battle/Settlement/Fault切回时，Home先STAGED；旧battle Node物理失效、required carrier exposure/archive/retire完成、root Window gate与activation journal齐全后才READY。HOME是ADR-0001 action-bearing TopState：每个confirmed bundle/layout generation发布完整`AccessibleScreenSnapshotV2`，固定capacity16、exact bytes4076。ASN01 READY/RECOVERY最大10行；ASN02 SETTINGS最大14行，其中volume4、font/locale2、bool4各用封闭role profile，apply/back各1。248-byte rows必须携带safe-area logical bounds、visible/clipped与余额/状态typed localization args，unused tail全零。旧Home/layout generation callback为NOOP。mouse/touch与八行Meta UI keyboard/mapped-gamepad focus分别验证；不能只设置一种focus。架构路径已冻结，Android TalkBack/iOS VoiceOver插件实现、能力握手、tree与真机trace保持`BLOCKED-MOBILE-A11Y-RUNTIME`。

### 3.8 Interactions with other systems

| System | Input | Output / boundary |
|---|---|---|
| GameRoot | HOME state、activation/gate、unresolved bits | typed navigation；Home不改TopState |
| SaveSystem | atomic profile + presentation/recovery | recovery CTA/settings mutation；Home不判durability |
| Settlement | resolved handoff/last result badge | archive完成后激活；不重播奖励 |
| Progression | balance/progress/view route | 功法入口；购买仍归Progression |
| Zhangtian/Prep | unlock/seed total | 两入口同一Prep destination |
| Audio Feedback | UI click/settings preview/durable edge | Home不直接操作bus tree |
| Config/Input | layout/theme/locale/touch manifest | responsive generation与typed press |

## 4. Formulas

### F1 — Home safe margin

The `home_safe_margin` formula is defined as:

`margin = max(12, 0.02 × min(safe_width, safe_height))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Safe width | `W` | float64 | >0 | cutout/inset后的logical width |
| Safe height | `H` | float64 | >0 | cutout/inset后的logical height |

**Output Range:** ≥12 logical px；非finite/≤0不激活页面。

**Example:** 720×1280且无额外inset时margin=`max(12,14.4)=14.4`。

### F2 — Progression summary

The `home_progression_summary` formula is defined as:

`nodes_bought = qingyuan_level + longchun_level + dayan_level`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Branch levels | `Q,L,D` | int32 | each 0–5 | same Progression domain revision |

**Output Range:** 0..15；checked sum失败则bundle invalid。

**Example:** 2/3/1显示`总进度 6/15`。

### F3 — Available seed summary

The `home_available_seed_total` formula is defined as:

`seed_total = checked_sum(available_seed_counts[0..2])`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Available counts | `a_i` | int64[3] | each ≥0 | Zhangtian confirmed domain |

**Output Range:** 0..INT64_MAX checked；不含reserved/consumed。

**Example:** `[1,0,2]`显示`可用种子 3`。

### F4 — Volume percentage to decibels

The `settings_volume_db` formula is defined as:

`db = volume_percent==0 ? MUTE : max(-40, 20×log10(volume_percent/100))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Display volume | `V` | int32 | 0–100 | Master/Music/SFX/UI之一 |

**Output Range:** V=0为mute；V=1..100映射[-40,0] dB，结果finite。

**Example:** V=50得到约−6.02dB；V=1 clamp为−40dB；V=0不以−∞传给引擎。

## 5. Edge Cases

- **If 首次安装A/B均不存在**：Save双镜像EMPTY_INIT成功后显示0资源；主CTA同press走`HOME_DIRECT_NONE`，创建Prep页面0并直接进入共享reservation链；temp残片不算旧档。
- **If store scan/heal/reconcile未完成**：Home只能STAGED/BLOCKED，新局/购买/消费为0。
- **If 一槽坏一槽有效**：不自动覆盖坏槽；RECOVERY_REQUIRED完成前只读。
- **If 两槽坏、未来schema或冲突**：保留bytes并显示对应阻断，绝不静默清档。
- **If bundle任一domain stale**：整帧保持旧值或不可用，不局部刷新。
- **If数值为合法INT64_MAX**：完整无损可读/读屏；compact格式不得成为唯一值。
- **If数值negative/overflow**：domain invalid，不clamp成0。
- **If主CTA双击、键盘+触屏同帧**：同press identity至多一个PREP command。
- **If START_RUN成功且available>0**：只进入Prep，battle identity/RNG/seed mutation均0；实际确认仍由Prep发出。
- **If掌天瓶未解锁或available=0**：主CTA同press走`HOME_DIRECT_NONE`且Prep页面创建0；掌天瓶卡只作说明入口，不伪装库存入口或增加二次确认。
- **If Progression/Zhangtian mutation PONR前失败**：旧bundle不变，可fresh retry。
- **If mutation PONR后不确定**：冻结业务CTA，只同operation核对，不乐观更新。
- **If durable success晚到/重建**：新bundle显示一次，成功/解锁音不重播。
- **If settings drag后取消**：session preview恢复confirmed值，profile写0。
- **If settings durable失败/uncertain**：confirmed profile不变；session安全覆盖可留但明确未保存。
- **If页面旋转/resize**：推进layout generation；旧touch/focus callback为NOOP。
- **If 130%字体或长locale**：卡片增高/页面滚动，主CTA和阻断原因不得裁切。
- **If reduce sensory/mute**：所有状态仍由文字、图形、focus与value成立。

## 6. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| GameRoot/Input | HOME activation、root gate、unique target | 静态传播待完成；runtime/cutout BLOCKED |
| SaveSystem | atomic profile、generic settings mutation、recovery | 基础Designed；60-byte domain/UX runtime待接 |
| Settlement | resolved archive/retire handoff | In Review / Re-review Pending；runtime待接 |
| Progression | balance/progress/page route | Designed；正式Home/功法UX待做 |
| Zhangtian/Prep | unlock/seed route | In Review / Re-review Pending |
| Audio/Config | bus settings/theme/locale/layout | Audio Designed；actual manifests/assets待接 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| reference canvas | 720×1280 canvas_items/expand | PROJECT LOCKED | 改动需全UI回归 |
| safe margin | F1 | shared BattleUI | 不复制设备魔数 |
| main CTA height | 64 logical px | UX PROVISIONAL | touch仍≥56 |
| secondary touch target | ≥56 logical px | UX LOCKED | 目标≥48dp真机核验 |
| font scales | 100/115/130% | UX PROVISIONAL | 需locale/device测试 |
| resource badges per entry | max1 | UX LOCKED | 禁止红点堆叠 |
| settings volumes | 100/80/80/80 | PROVISIONAL MIX | Sound Bible后冻结 |
| dB floor | −40dB then mute | PROVISIONAL MIX | 手机/耳机听测 |
| Settings domain max | 60 bytes | FIXED V1 | 变更需migration |

## 8. Visual / Audio / UI Requirements

背景表现为安静洞府与韩立立绘，额外宽度只延展背景，正文列宽约600基准像素并居中。主CTA位于下部单手区；资源、按钮和阻断面板全部叠加safe-area。成功/待核对/损坏分别使用印章、双环、裂纹档案图形加文字，不用红绿作为唯一差异。

Home常态不播放入页声；普通navigation仅轻UI click。Settings preview沿Audio bus，但业务success只在durable receipt首次前台到达时一次；pending无循环、reconcile/rebuild不重播。reduce sensory关闭背景循环动效、墨迹扫屏和重复震动。

📌 **UX Flag**：Home正常/首次/角标/Settings及全部Save阻断态必须另行`/ux-design`。

📌 **Asset Spec**：洞府背景、韩立Home立绘、资源/功法/掌天瓶/状态图标需正式asset spec。

## 9. Acceptance Criteria

- **AC-HM01 `[L/I][BLOCKING]` — GIVEN**任意Home bundle，**WHEN**render/navigation，**THEN**UI只写copy/focus/typed command，五类业务/TopState writer调用均0。
- **AC-HM02 `[I][BLOCKING]` — GIVEN**boot scan/heal/reconcile/archive任一未完成，**WHEN**stage Home，**THEN**noninteractive且新局/购买/消费为0。
- **AC-HM03 `[I][BLOCKING]` — GIVEN**READY matching profile，**WHEN**capture，**THEN**灵石/残页/功法/seed/settings来自同profile revision；stale轴不拼帧。
- **AC-HM04 `[L/I][BLOCKING]` — GIVEN**branch levels0..5，**WHEN**F2，**THEN**summary0..15；invalid/overflow拒绝整包。
- **AC-HM05 `[L/I][BLOCKING]` — GIVEN**seed counts0/1/MAX，**WHEN**F3，**THEN**checked exact sum且不含reserved；overflow bundle invalid。
- **AC-HM06 `[L][BLOCKING]` — GIVEN**volume0/1/50/100及非法，**WHEN**F4，**THEN**mute/−40/约−6.02/0dB；非法不应用。
- **AC-HM07 `[I][BLOCKING]` — GIVEN**HOME READY fresh press、available分别为0或>0、两flag合法/非法组合及128-byte `DirectNoneStartSliceV2`任一字段/hash单轴stale，**WHEN**点主CTA，**THEN**0库存只从同一confirmed Home bundle内合法slice发一次`HOME_DIRECT_NONE`并创建Prep页面0；stale、非法flag、locked非零库存或跨owner拼接发0 command；>0库存只创建PREP navigation一次且battle ID/RNG/库存写为0。
- **AC-HM08 `[I][BLOCKING]` — GIVEN**double/multitouch/slide-out/cancel/stale generation，**WHEN**terminal input，**THEN**同press最多1 command，其余0。
- **AC-HM09 `[I][BLOCKING]` — GIVEN**Save/Reservation/Mutation/Archive全部阻断态，**WHEN**展示/CTA，**THEN**逐态文案与唯一service action匹配，UI disabled不可绕过guard。
- **AC-HM10 `[I][BLOCKING]` — GIVEN**Progression/Zhangtian concurrent commands同profile revision，**WHEN**Save CAS，**THEN**仅一个成功，Home刷新整包且不自动重发另一条。
- **AC-HM11 `[C/I][BLOCKING]` — GIVEN**settings generic mutation每个PONR fault，**WHEN**Apply，**THEN**成功前confirmed profile不变；unknown只reconcile同operation。
- **AC-HM12 `[I][BLOCKING]` — GIVEN**Home/Settlement/Fault handoff，**WHEN**cleanup，**THEN**旧callback撤销、Home先STAGED、journal齐全后唯一ACTIVE。
- **AC-HM13 `[UX/A][OPEN-EVIDENCE]` — GIVEN**四档portrait/cutout、130%字体、英文+30%、灰阶/色弱/静音与签发后的移动端读屏bridge，**WHEN**所有Home态，**THEN**主CTA/余额/原因/设置不裁切，touch≥56px且reading/focus/live announcement稳定；bridge缺失时不得PASS。
- **AC-HM14 `[R/M][BLOCKING]` — GIVEN**最大profile/locale及10000次预热后update，**WHEN**性能测试，**THEN**project-side每帧Node/container/String growth为0并提交p50/p95/p99/max及positive control。
- **AC-HM15 `[E][OPEN-EVIDENCE]` — GIVEN**目标新玩家，**WHEN**首次Home，**THEN**3秒内找到进入试炼且不把“筑基初期”误认成可升级系统；无自动消费/弹页。
- **AC-HM16 `[E][BLOCKING]` — GIVEN**STATIC/RUNTIME/DEVICE证据集，**WHEN**签收，**THEN**分层标记；截图、按钮变灰或一次启动成功不得代替runtime/accessibility。
- **AC-HM17 `[I][BLOCKING]` — GIVEN**首个VICTORY/DEFEAT/ABANDONED/TECHNICAL、重复receipt与UI rebuild，**WHEN**更新Home，**THEN**仅首个durable正常结算产生一次locked→unlocked；后两类与重复均不解锁，rebuild/unmute不补播历史成功声。
- **AC-HM18 `[I][A][BLOCKING]` — GIVEN**全部恢复态、keyboard/gamepad/screen-reader hint与READY往返，**WHEN**显示CTA，**THEN**唯一主动作、focus、播报与service guard逐态matching；恢复READY只还原焦点，不自动执行命令。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-HM01 | Settings默认音量与−40dB floor？ | Audio/Product | PROVISIONAL |
| OQ-HM02 | UPDATE_REQUIRED是否有真实平台更新CTA？ | Release/Product | OPEN；无入口则只导出诊断 |
| OQ-HM03 | 角标read-state是否需要持久化？ | UX/Save | 默认session-local；OPEN |
| OQ-HM04 | Settings codec/migration/slot capacity？ | Save/Config | BLOCKED |
| OQ-HM05 | Godot 4.7.1 safe-area/dual-focus与TalkBack/VoiceOver bridge？ | Engine/QA | ADR-0001路径已冻结；runtime/device BLOCKED |
| OQ-HM06 | 正式UX/Art/Sound与用户测试？ | UX/Art/Audio | BLOCKED |
| OQ-HM07 | clean-context full review？ | Review team | OPEN |

## 11. Handoff

本文冻结Home信息层级、有库存进Prep/无库存direct NONE的单一路由、atomic profile bundle、Save恢复阻断、60-byte Settings domain与音量映射。它不构成最终UX、资产、移动端读屏/safe-area或性能证明。

状态保持`In Review / Re-review Pending`；应在fresh context运行`/design-review design/gdd/home-ui.md --depth full`。
