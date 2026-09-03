# Prep UI（掌天瓶开局准备页）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted UX reviewer / qa-lead）
> **Created / Last Updated**: 2026-09-03
> **Implements Pillar**: 一次只做一个清晰准备决定；可控、不强迫、不自动消费
> **Scope**: MVP Home到Battle之间的掌天瓶选择、NONE路径、effect preview、durable reservation进度、Loading handoff与返回；不含多丹、推荐方案、自动沿用、炼丹小游戏或真实时间等待

## 1. Overview

Prep UI 是有至少一枚可用种子时 `HOME→BATTLE_LOADING` 之间唯一可交互准备页，也是掌天瓶的完整玩家界面。它展示三种种子库存与下一局丹药效果，允许选择恰一种或明确“不服丹”，并把fresh typed command交给GameRoot/Zhangtian/Save；UI只维护草稿、焦点和press identity，不拥有库存、配方、reservation、battle identity或TopState。未解锁或三类available全0时，Home主CTA直接以同一`PrepConfirmCommandV1`的`HOME_DIRECT_NONE`来源提交NONE，不创建一个只供再次确认的Prep页面。

确认丹药后必须等待matching reservation durable success，才能进入Loading；结果不确定时页面冻结并只允许核对。选择NONE仍走同一run-start检查和0-cost reservation identity，但不改变库存。再次挑战与Home主CTA仅在存在可选种子时进入fresh Prep；无可选种子时走direct NONE。无论入口，永不自动沿用上一局选择。

## 2. Player Fantasy

玩家在出发前看一眼储备，做一个像韩立的谨慎决定：“这局我要更快成型、更多容错、还是更高爆发？也可以把药留到以后。”三张卡的代价和效果无需进入详情页就能看懂，确认前随意比较不会扣除任何东西。

催熟应短促而可靠：没有等待计时、失败概率或第三层确认弹窗。选丹路径由选卡和底部CTA构成两步防误触；有库存但选择NONE时，由Prep明确写有“不服丹”的CTA完成确认；无可用种子时，Home主CTA本身就是唯一明确确认，不再多点一次。只有“封签完成”才代表资源已安全预留。异常时宁可停在“待核对”，也不让玩家担心被重复扣药。

## 3. Detailed Design

### 3.1 Owner boundary

- Prep是consumer-only presenter+typed command adapter，不是phase participant，四类gameplay contribution均0。
- 只拥有local selected seed、layout/focus/press generation、卡片与CTA表现。
- Zhangtian拥有三种库存/配方、run-specific projection、preparation allocator与reservation after-image；Save拥有durability与battle identity allocator；GameRoot拥有TopState、run-seed producer编排与Loading；Config拥有静态HerbConfig与projection rules。
- UI不得自行执行`count−1`、加HP/crit/level、调用RNG、创建battle ID、写profile或根据动画结束进入Loading。

### 3.2 Atomic preparation bundle

```text
PrepPresentationBundleV1={
  schema_version:i32=1,top_state:i32,page_generation:i64,
  profile_revision:i64,zhangtian_domain_revision:i64,
  zhangtian_content_revision:i64,config_content_revision:i64,
  save_state_revision:i64,available_seed_counts:i64[3],
  unlocked:i32,recipe_rows:HerbRecipeViewV1[3],
  reservation_attempt:PrepareRunAttemptViewV1,
  geometry:UiGeometrySnapshotV1,
  primary_action_id:i32,block_reason_id:i32,bundle_hash:Hash256
}
```

三recipe row按凝气草/铁灵花/雷元果stable顺序，包含owner已解析的pill stable ID、数值、单位与localization key；本地化字符串不进入bundle hash。所有业务字段来自同一profile/config/Save capture，geometry另以revision/hash关联page generation；任一revision/hash/stable row stale或unknown时，整包不可确认并请求fresh capture，不能保留新库存+旧药效。

`PrepLocalDraftV1={page_generation,selected_seed_id,selected_pill_id,draft_revision}`只属于当前页面，不进入owner bundle/hash。`PrepareRunAttemptViewV1`固定携带`command_id,preparation_id,reservation_id,operation_id,attempt_generation,request_id,result_code,receipt_id,state,view_hash`；UNKNOWN字段/枚举令整包BLOCKED。UI只用这些typed结果匹配late callback、重建和一次性反馈，不从裸state edge猜测成功。

### 3.3 Page layout and selection

从上到下固定：返回、`掌天瓶·开局准备`、当前选择摘要、三张灵药卡、`本局不服丹`、底部固定说明与主CTA。

- 每卡显示`种子名 / 库存×N / 丹药名 / 完整下一局效果`。
- 凝气草→聚气丹“开局获得14点等级曲线credit至LV2，并在移动前按第一次普通升级规则选择一次功法（距LV40尚需16538 XP）”；铁灵花→锻体丹“基础最大生命加法+15%，下局X→Y”；雷元果→明心丹“暴击率+8个百分点，下局X→Y”。resolved前后值必须来自matching projection preview，不由UI计算。
- tap合法卡设为唯一selection；再次tap同卡保持选中，只有选择“不服丹”才回NONE，符合四选一radio-group语义。
- 库存0的卡保持可读并标“暂无种子”，点击只给一次低干扰blocked反馈，0 command。
- unlocked=0或三类available全0时，主开局流程不创建Prep页；Home显示“本局无可用丹药，将不服丹出战”，CTA为“不服丹，开始试炼”。玩家从掌天瓶说明入口查看本页时，三卡仅作非交互预览且不得出现第二个开局确认CTA。
- 每次进入/再次挑战初始NONE，不读上次选择、不显示推荐、不自动消费。

### 3.4 Confirmation command

底部CTA随selection变为`不服丹，开始试炼`、聚气丹专用`服用聚气丹，先选功法`，或其他丹药的`服用{丹药名}，开始试炼`。选丹时固定说明“确认后预留1枚种子；进入战斗即消耗，本局结束不返还；技术异常按系统核对结果处理”。不增加第三层modal，也不用“催熟”掩盖即将发生的资源预留。

```text
PrepConfirmCommandV1={
  schema_version:i32=1,command_id:i64,press_id:i64,
  source_surface_id:i32,
  expected_page_generation:i64,expected_profile_revision:i64,
  expected_domain_revision:i64,expected_config_revision:i64,
  selected_seed_id:i32,expected_pill_id:i32,
  expected_save_state_revision:i64,bundle_hash:Hash256
}
```

`source_surface_id={HOME_DIRECT_NONE=1,PREP=2}`。PREP来源只在PREP/DRAFT且selection为NONE或库存>0时可发；HOME来源由同一press先把GameRoot置于noninteractive PREP/STAGED（页面Node创建0），再消费已排队的command，且要求origin为fresh HOME generation、`unlocked=0 OR sum(available)=0`、`selected_seed_id=expected_pill_id=NONE`。二者共同要求Save READY、无unresolved outcome/archive/mutation/reservation、matching bundle与fresh single press。effect/pill由owner从Config重算，不信任UI文字/数值。双击、多触点、键盘+触屏同帧按press identity合并；滑出、cancel、旧generation均0 command。

非开局主动作使用独立封闭命令：`PrepActionCommandV1={schema_version:i32,action_id:i32,command_id:i64,press_id:i64,expected_page_generation:i64,expected_attempt_generation:i64,expected_request_id:i64,bundle_hash:Hash256}`，其中`action_id={CANCEL=1,RECONCILE=2,EXPORT_DIAGNOSTIC=3,PRE_ACTIVE_CANCEL_AND_RELEASE=4}`。每个可见CTA/focus action恰映射一行；UI不得以字符串、按钮名或generic retry猜service操作。

### 3.5 GameRoot reservation transaction

现有`PREP/CONFIRM_RUN→BATTLE_LOADING`不得继续使用无条件guard。新的原子顺序固定：

1. 全量验证Prep/Zhangtian/Save/Config、预分配candidate与root input gate。
2. GameRoot取得release路径唯一OS entropy run-seed candidate；Save从持久`next_identity`、Zhangtian从持久`next_preparation_id`分别分配nonzero battle/reservation与preparation identity，并把两个checked+1 allocator写入同一after-image；任一步失败全部回滚。
3. Zhangtian构造seed reserve/NONE count after-image和run-specific projection candidate。
4. Save将1004-byte `DurableReservationV1`（内含276-byte `RunStartRecoveryV1`）、after-image与`PrepCommitJournalV1` checkpoint2写入双槽并readback；未durable不得提交run start。
5. success后从durable recovery逐位冻结`RunStartRequestV2={battle_instance_id,run_seed,reservation_id,preparation_id,selected_pill_id,zhangtian_projection_hash,profile/config revisions}`并推进checkpoint3。
6. source surface拥有的gesture rows先retire全部held touch并撤销input target，推进checkpoint4；严禁调用非BOOT的全局`Input.flush_buffered_events()`。checkpoint5 readback后GameRoot才提交BATTLE_LOADING。

`RunStartRequestV2`冻结后不可回写。Loading全部Config/RNG preflight成功后，Zhangtian把一次logical抽取的candidate/call range写入同一276-byte recovery并推进checkpoint6；若该roll失败，Loading abort并先release reservation。candidate不是UI字段，也不属于Prep提交bundle；进程重启只按durable run seed重建同一logical ordinal，不产生第二候选。

PONR前明确失败回DRAFT且confirmed库存不变；首份可能durable后进入RESERVATION_UNCERTAIN，禁止返回/换药/新confirm，只能同operation reconcile。FOUND恢复完整run-start并沿`PrepCommitJournalV1`继续同一Loading一次，NOT_FOUND保持uncertain；若scan得到RELEASED/CONSUMED/CONFLICT/FUTURE/CORRUPT则分别进入对应typed恢复终态，不得一律当FOUND。

### 3.6 Cancel, load failure and return

- DRAFT返回Home只发送`CANCEL_PREP`，丢弃local selection，0 reservation/battle identity/profile write。
- RESERVING/UNCERTAIN禁止普通返回；系统back手势只朗读“正在核对本次备战”，不创建第二操作。
- RESERVED后若Loading发生LFD01..12、LFD25或LFD27 clear retryable failure，先进入RELEASING并等待durable RELEASE；完成后回fresh Prep/NONE。release未完成时卡片不可消费。
- LFD13..24、LFD26/LFD28或永久写可能成立时进入Fault/reconcile；Prep不得以旧库存重新出现。`ActiveEntryFactV1`已durable不属于LFD27，必须按active orphan consume。
- 首次Active开放前必须durable写matching `ActiveEntryFactV1`。Active后的Victory/Defeat/Abandoned均consume；ABANDONED以零奖励tombstone+mandatory consume持久化，主动退出不返丹。Active marker后无sealed Outcome的跨进程强杀也consume；明确Technical只按sealed compensation。

异常态玩家模型固定为：`RESERVING`标题“正在封签”、无操作且pending音0；`UNCERTAIN/RECONCILING`标题“正在核对本次备战”，主CTA“再次核对”，保留matching identity并允许关闭应用后从Home恢复，普通Back不离页；连续自动核对最多3次、间隔250/500/1000ms，之后停止自动重试但主CTA与“导出诊断”保持可用；`RELEASING`标题“正在返还种子”、无新确认；`BLOCKED`按Save原因提供恢复/更新/导出诊断。每次状态进入只播报一次localization key，rebuild不重复；focus优先落标题/状态摘要，其次唯一可用CTA。

### 3.7 State machine

| State | Meaning | Allowed next |
|---|---|---|
| `UNBOUND` | 未绑定atomic bundle | STAGED, BLOCKED |
| `STAGED` | noninteractive handoff | DRAFT, BLOCKED |
| `DRAFT` | NONE/单卡本地选择 | DRAFT, RESERVING, CANCELLED |
| `RESERVING` | durable operation in flight | RESERVED, DRAFT, UNCERTAIN |
| `UNCERTAIN` | 可能durable | RECONCILING |
| `RECONCILING` | 同operation scan | RESERVED, RELEASED, CONSUMED, UNCERTAIN, BLOCKED |
| `RESERVED` | run-start可提交 | HANDOFF_PENDING, RELEASING |
| `HANDOFF_PENDING` | journal继续freeze/touch-retire/top-state | DETACHING, RELEASING, UNCERTAIN |
| `RELEASING` | load abort返还中 | STAGED, UNCERTAIN |
| `DETACHING` | page touch retirement/input handoff | BATTLE_LOADING, UNCERTAIN |
| `BLOCKED` | corrupt/update/conflict | STAGED |

任何状态最多一个interactive page generation和一个root Window input target。Prep使用page-owned固定槽gesture FSM，identity为`{page_generation,touch_index,press_sequence}`，只有matching inside-release可创建command；outside/system cancel/第二触点吞掉且command0，keyboard/gamepad/accessibility使用独立synthetic activation sequence并按command key去重。页面离开前旧callback全部撤销、全部held row retired；Battle必须fresh touch。

### 3.8 Interactions with other systems

| System | Input | Output / boundary |
|---|---|---|
| Home/Settlement | navigation handoff | fresh Prep/NONE；resolved后进入 |
| Zhangtian | atomic view、recipe、reserve result | typed selection/confirm；UI不写domain |
| SaveSystem | readiness/reservation/reconcile | 只有durable RESERVED后Loading |
| GameRoot | PREP state/input gate/run transaction | command；GameRoot拥有identity/transition |
| Config/RNG | recipe/projection/seed candidate | UI不直接调用；Loading preflight |
| Player/Damage/Leveling/SkillDraft | — | 只在battle snapshot消费丹效 |
| Input/Audio | press lifecycle/semantic cues | fresh-touch drain；preview≠业务success |

## 4. Formulas

### F1 — Selected preparation count

The `prep_selected_pill_count` formula is defined as:

`selected_count = selected_seed_id==NONE ? 0 : 1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Selected seed | `S` | enum | NONE or 3 stable IDs | local draft identity |

**Output Range:** exactly0 or1；unknown ID使bundle invalid，不clamp为NONE。

**Example:** 铁灵花selected count=1；只有点击“不服丹”才回NONE并为0。

### F2 — Post-reserve preview count

The `prep_remaining_seed_preview` formula is defined as:

`remaining = available_count - selected_count`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Available | `A` | int64 | selected时≥1 | confirmed owner value |
| Selected count | `C` | int32 | 0 or1 | F1 |

**Output Range:** 0..INT64_MAX；只作预览，UI不写回。

**Example:** 铁灵花库存1、已选时显示“进入后剩余0”。

### F3 — Prep content width

The `prep_content_width` formula is defined as:

`content_width = min(600, safe_width - 2×max(12,0.02×min(safe_width,safe_height)))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Safe dimensions | `W,H` | float64 | positive finite | cutout/inset后的logical size |

**Output Range:** positive..600 logical px；≤0不激活页面。

**Example:** safe width720/height1280时margin14.4，content width600并居中。

### F4 — Bottom CTA safe offset

The `prep_bottom_cta_offset` formula is defined as:

`bottom_offset = safe_bottom_inset + 12`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Safe bottom inset | `I` | float64 | ≥0 finite | gesture/Home indicator inset |

**Output Range:** ≥12 logical px；CTA高度≥64、hit target≥56。

**Example:** bottom inset24时CTA距物理底边36 logical px。

## 5. Edge Cases

- **If 全库存0或未解锁**：NONE合法，三卡仍可读效果；不阻断首局。
- **If 已选卡库存由fresh bundle变0**：selection清回NONE并播报一次，不自动换另一药。
- **If tap selected card again**：保持该radio选中，0业务写入；只有“不服丹”切回NONE。
- **If切换100次未确认**：profile/reservation/RNG/业务音均0。
- **If confirm时bundle任一revision stale**：0 command，整包刷新，不用新库存+旧药效。
- **If double/multitouch/keyboard race**：同press最多一个command/battle identity/reservation。
- **If press滑出/cancel**：0 command。
- **If NONE确认**：0 seed delta、effect presence显式NONE；仍完成service-side run gate。
- **If seed count为negative/corrupt/overflow**：整页BLOCKED，不显示成“暂无”。
- **If identity分配耗尽**：PONR前0副作用并留PREP，不wrap。
- **If reserve PONR前失败**：回DRAFT/old confirmed bundle；不显示已消耗。
- **If reserve PONR后未知**：只reconcile，back/换药/再次确认均0。
- **If load retryable failure**：release durable完成后才回可交互Prep，种子只返一次。
- **If Active后主动退出**：不返丹；页面不能用“无奖励”推断release。
- **If TECHNICAL_ABORT**：仅按sealed disposition，UI不自行补偿。
- **If旧Prep callback晚到**：page generation mismatch→NOOP，不进入第二battle。
- **If held touch跨页面**：page-owned retire后Battle fresh touch前movement=0；全局Input flush调用数0。
- **If字体130%/长locale**：详情scroll但库存、仅下一局、代价和CTA始终可见。

## 6. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| Zhangtian | canonical slice/internal request/reservation/effects | In Review / Re-review Pending；runtime/codec待证 |
| GameRoot | PREP journal/guard/Loading handoff | 静态整改传播中；generated tables/runtime BLOCKED |
| SaveSystem | durable reservation/release/reconcile | 基础Designed；Zhangtian payload待接 |
| Config/RNG | recipe rules/dynamic projection/Loading seed draw | max_weights=3与静态/动态边界已裁决；artifact待生成 |
| Player/Damage/Leveling/SkillDraft | 丹药consumer | 部分已有；聚气/明心待传播 |
| Home/Settlement | resolved navigation | In Review / Re-review Pending |
| Input/Audio | touch drain/focus/cues | Designed；正式row/device evidence待接 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| cards | 3 + explicit NONE | FIXED MVP | recipe/schema change required |
| default selection | NONE every entry | UX LOCKED | 不自动沿用 |
| card/CTA target | ≥56 / 64 logical px | UX PROVISIONAL | 真机≥48dp |
| content max width | 600 | UX PROVISIONAL | wide-screen user test |
| safe gap | 12 | shared UI | 不做per-device magic numbers |
| confirm layers | 选丹=selection+CTA；NONE=explicit CTA | UX LOCKED | 不加第三modal |
| reservation in flight | 1 | HARD LIMIT | follows Save |

## 8. Visual / Audio / UI Requirements

三种种子/丹药必须有不同剪影、材质与文字，不只换颜色。选中=勾+实体边框+“已选择”；缺货=空篓/锁轮廓+“暂无”；uncertain=双环待核对。底部CTA固定safe-area内，长内容只滚动中段。

选卡为短纸/玉轻触，表达“选中”而非“已消耗”；按钮press无业务成功重音。fresh-live durable reservation edge的封签声为at-most-once，crash窗口0..1；pending/uncertain/failed默认音频静默，reconcile/rebuild/unmute不补播。reduce sensory关闭瓶液循环/墨迹扫屏/数值滚动，音画不门控Loading。

📌 **UX Flag**：无种子、单/多种、NONE、pending、uncertain、release、长locale/cutout需`/ux-design`。

📌 **Asset Spec**：掌天瓶、三种草药/丹药、选择/封签/核对状态需正式asset spec。

## 9. Acceptance Criteria

- **AC-PR01 `[L/I][BLOCKING]` — GIVEN**任意Prep interaction，**WHEN**选/确认/取消，**THEN**UI业务/TopState/RNG writer调用0，只发typed command。
- **AC-PR02 `[I][BLOCKING]` — GIVEN**HOME READY且库存分别为0或>0，**WHEN**按主CTA，**THEN**0库存只发一次`HOME_DIRECT_NONE`且Prep页面创建0；>0库存先STAGED后进入唯一interactive Prep，selection NONE且0 battle carrier/扣种。
- **AC-PR03 `[L/I][BLOCKING]` — GIVEN**合法/缺/重/unknown recipe rows，**WHEN**capture，**THEN**恰三行stable mapping，invalid整包不可确认。
- **AC-PR04 `[I][BLOCKING]` — GIVEN**三卡/库存/NONE，**WHEN**选择切换，**THEN**F1只0/1、再次tap保持同radio、显式NONE才清除、确认前0 durable side effect。
- **AC-PR05 `[L][BLOCKING]` — GIVEN**库存0/1/MAX及selection，**WHEN**F2，**THEN**0卡不可confirm，合法preview精确且不写profile。
- **AC-PR06 `[L][BLOCKING]` — GIVEN**四档safe dimensions/cutout，**WHEN**F3/F4，**THEN**content≤600、CTA不被gesture遮挡，非法尺寸不激活。
- **AC-PR07 `[I][BLOCKING]` — GIVEN**fresh/stale bundle与fresh/cancelled press，**WHEN**confirm，**THEN**只有全matching fresh release发送一次command，owner重算pill/effect。
- **AC-PR08 `[I][BLOCKING]` — GIVEN**double/multitouch/keyboard+touch/slide-out，**WHEN**input terminal，**THEN**同press最多1 command，其余0。
- **AC-PR09 `[I][BLOCKING]` — GIVEN**PrepCommitJournal八checkpoint、candidate与pre-active子步骤逐点故障，**WHEN**执行§3.5，**THEN**PONR前全部回滚；durable后按total disposition恢复同一identity或先release，第二identity/candidate/Loading=0。
- **AC-PR10 `[C/I][BLOCKING]` — GIVEN**Save完整reservation fault matrix、callback loss与全部scan结果，**WHEN**reserve/reconcile，**THEN**RESERVED恢复同一run一次，NOT_FOUND保持冻结，RELEASED/CONSUMED/CONFLICT/FUTURE/CORRUPT进入唯一typed状态。
- **AC-PR11 `[I][BLOCKING]` — GIVEN**NONE confirm，**WHEN**run transaction，**THEN**0 inventory delta、explicit no-pill projection、唯一run identity且不绕Save gate。
- **AC-PR12 `[I][BLOCKING]` — GIVEN**LFD01..12，**WHEN**load abort，**THEN**release exact-once后fresh Prep；durable前可消费页面次数0。
- **AC-PR13 `[I][BLOCKING]` — GIVEN**normal outcomes/Abandoned/Technical/Active强杀，**WHEN**reservation resolve，**THEN**V/D/A与Active marker orphan consume，Technical只按sealed compensation；奖励discard不撤销成本。
- **AC-PR14 `[I][BLOCKING]` — GIVEN**三丹/NONE matching snapshot，**WHEN**Loading，**THEN**level/HP/crit逐值按Zhangtian公式且Active不热改。
- **AC-PR15 `[I][BLOCKING]` — GIVEN**聚气丹，**WHEN**入局，**THEN**LV2/xp0/curve-credit14+ordinal1普通choice在PRE_ACTIVE_CHOICE完成后才LOAD_READY，movement/survival此前为0，失败不发布半状态。
- **AC-PR16 `[I][BLOCKING]` — GIVEN**旧page callback/多触点/cancel/held touch，**WHEN**detach→Battle，**THEN**page-owned rows全部retire、全局flush0、旧command/movement0且需fresh touch。
- **AC-PR17 `[UX/A][OPEN-EVIDENCE]` — GIVEN**portrait/cutout、130%字体、英文+30%、灰阶/色弱/静音及签发后的Android/iOS读屏bridge，**WHEN**各状态，**THEN**库存/效果/仅下局/代价/CTA不裁切且touch≥56px、reading/focus/live announcement稳定；bridge ADR未签发时本项保持BLOCKED而非以Control属性PASS。
- **AC-PR18 `[R/M/E][BLOCKING]` — GIVEN**1000次reserve/release fault/race与target devices，**WHEN**签收，**THEN**codec/crash/device/performance证据分层；动画一次或截图不得PASS。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-PR01 | 聚气丹prebattle choice的首次操作体验？ | UX/Balance | PROVISIONAL，目标玩家测试 |
| OQ-PR02 | RunStartRequestV2、Loading seed pre-draw与reservation recovery？ | GameRoot/RNG/Save | BLOCKED runtime |
| OQ-PR03 | safe-area/dual-focus与TalkBack/VoiceOver bridge/back手势顺序？ | Engine/Input | BLOCKED architecture ADR + device spike |
| OQ-PR04 | 三卡正式UX/asset/audio？ | UX/Art/Audio | BLOCKED |
| OQ-PR05 | clean-context full review？ | Review team | OPEN |

## 11. Handoff

本文冻结“有可选种子才进入Prep、无可选种子Home direct NONE”的单一路由、NONE默认、三卡选择、typed actions、两步选丹确认、durable reservation gate、Loading failure release与fresh-touch handoff。它没有证明Godot UI、移动端读屏bridge、Save crash、聚气丹首局体验或资产完成。

状态保持`In Review / Re-review Pending`；应在fresh context运行`/design-review design/gdd/prep-ui.md --depth full`。
