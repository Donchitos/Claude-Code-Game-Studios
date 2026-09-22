# ADR-0001: Mobile Accessibility Bridge

## Status

Accepted for post-Steam mobile-port design on 2026-09-03; semantic ABI, fixed capacities, explicit node/state contracts, MPSC-to-serial ingress and mapped Meta UI input were revised after the seventh Zhangtian review on 2026-09-08. The 2026-09-10 authorized amendment adds a one-node `BATTLE_ACTIVE` pause gateway while keeping full active-gameplay semantics out of the first mobile port scope. Runtime and device evidence remain blocking for mobile release.

## Date

2026-09-08 (original decision 2026-09-03)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7.1 |
| **Domain** | UI / Input / Accessibility |
| **Knowledge Risk** | HIGH — engine version is post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/ui.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Godot 4.5+ Control accessibility metadata; 4.7 `AccessibilityServer.AccessibilityLiveMode` type |
| **Verification Required** | Android TalkBack and iOS VoiceOver exported-build tree/action/focus/live-region traces; bridge capability handshake; 4.7.1 API compile check |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | None |
| **Enables** | Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault mobile accessibility implementation |
| **Blocks** | Android/iOS accessibility release evidence until both platform adapters pass validation; does not block the Steam-first desktop baseline |
| **Ordering Note** | Build semantic snapshot and typed action adapter before platform plugins; device evidence cannot be replaced by desktop AccessKit evidence |

## Context

### Problem Statement

Godot Control accessibility metadata alone does not establish that exported Android and iOS builds expose a complete, actionable TalkBack/VoiceOver tree. Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault surfaces require stable roles, selected/disabled state, geometry, reading order, dynamic localized values, live status announcements and activation without giving a native plugin authority over game or profile state.

### Constraints

- Android and iOS are post-Steam port targets, not the first commercial release baseline.
- Godot is pinned to 4.7.1, whose accessibility API is post-training-cutoff and must be verified against the repository engine references and target builds.
- UI presenters remain consumer-only; platform code cannot write inventory, Save, TopState or gameplay authority.
- Touch focus and keyboard/screen-reader focus remain distinct.
- UI rebuild, stale generation and delayed native callbacks must not activate a new screen.

### Requirements

- Expose the same immutable semantic snapshot on both mobile platforms.
- Map native accessibility actions back to existing typed UI commands.
- Preserve deterministic reading order, radio-group position, selected/disabled state and live announcement priority.
- Fail closed when the bridge is unavailable or incompatible; never claim mobile accessibility support from Control properties alone.

## Decision

Adopt an app-scope `MobileAccessibilityBridgeV1` owned by the persistent app root and registered in the separate `AppAdapterTopologyManifestV2` row `MOBILE_ACCESSIBILITY`; it is not one of the five business `AppServiceTopologyManifestV1` rows and not a seven-phase participant. The bridge and platform adapter are constructed once on the main thread after persistent root creation, remain alive across every TopState, are pumped once per render frame in every TopState, stop accepting callbacks before UI presenters detach, drain/retire queued commands, then shut down before the persistent root is freed.

Each action-bearing presenter in `{HOME,PREP,PRE_ACTIVE_CHOICE,BATTLE_ACTIVE,BATTLE_PAUSED,SETTLEMENT,CONTROLLED_FAULT}` publishes a complete immutable `AccessibleScreenSnapshotV2`; `BATTLE_ACTIVE` is intentionally a minimal accessibility gateway containing exactly one enabled `BUTTON/ACTIVATE` pause node and no gameplay HUD rows or live region. All other non-action TopStates publish no interactive snapshot but still drain stale callbacks. The gateway preserves the MVP promise that a screen-reader user can reach pause without claiming full active-gameplay semantics. CONTROLLED_FAULT is always owned by the persistent GameRoot fault presenter, never by a battle-scoped UI node. The bridge validates and copies the snapshot into exactly one platform adapter. Android uses `AndroidAccessibilityAdapterV1` to expose an accessibility node provider for TalkBack, and iOS uses `IOSAccessibilityAdapterV1` to expose UIAccessibility elements for VoiceOver. OS callbacks may arrive on arbitrary platform threads: they enter the fixed 6,208-byte `AccessibilityNativeMpscIngressV1` using the per-slot sequence/CAS protocol below. The successful enqueue CAS position is the checked i64 arrival ticket; a full queue consumes no ticket and leaves no hole. A single adapter-owned serial ingress executor drains tickets in ascending order, allocates the canonical `native_event_sequence` there, and is the only producer allowed to copy fixed commands into the preallocated SPSC mailbox of capacity32. Either queue full, sequence exhaustion or shutdown race fails closed and makes the current interactive screen unavailable; it never allocates, overwrites or silently drops. GameRoot's main-thread render-frame pump is the sole SPSC consumer, drains that mailbox at most once per frame in every TopState, and forwards `AccessibilityActionCommandV2` to the active presenter. Platform callbacks never call Godot Node, SceneTree, signals or business services directly.

The bridge does not infer semantics from visual Node traversal and does not call business services directly. A mobile build that declares screen-reader support must receive `SUPPORTED` from the platform adapter capability handshake before activating any of the seven action-bearing states above, including the one-node `BATTLE_ACTIVE` pause gateway. `UNAVAILABLE` or `INCOMPATIBLE` presents a noninteractive, localized support error and fails the accessibility release gate; it does not silently downgrade to unlabeled Controls.

### MVP active-battle accessibility amendment (2026-09-10)

The previous touch-only boundary for `BATTLE_ACTIVE` is superseded by the authorized MVP gateway decision: `BATTLE_ACTIVE` publishes one `BUTTON/ACTIVATE` node, `BATTLE_ACTIVE_PAUSE`, and no other active-gameplay rows. Its activation is validated as the existing typed pause command and cannot write SceneTree, gameplay or Window state directly. This is a pause gateway, not a claim of full active-battle screen-reader semantics; it still requires the same Android/iOS capability, golden, runtime and device evidence gates.

The gateway command is frozen as `BattleActivePauseCommandV1={schema_version:i32=1,command_id:i64,input_event_id:i64,screen_id:i32=8,screen_generation:i64,layout_generation:i64,node_id:i64=7001,command_kind:i32=1,pause_reason:i32=1,source:i32=1}` where enum value 1 means `PAUSE_REQUESTED`, `MANUAL` and `BATTLE_ACTIVE_ACCESSIBILITY_GATEWAY` respectively. BattleUI/presenter owns snapshot validation and emits this typed value; persistent GameRoot is the sole command owner and sole SceneTree/Window writer. GameRoot accepts it only while `TopState=BATTLE_ACTIVE`, the node is enabled, screen/layout generations match, and `command_id` is the first unseen checked ID; stale, duplicate, disabled or any other node is a zero-effect diagnostic. An accepted command is consumed exactly once, becomes the existing `PAUSE_REQUESTED`/`MANUAL` intent, and then follows the existing Input cancel → pause barrier → SceneTree pause path. The bridge, adapter and BattleUI never call `request_pause`, write `SceneTree` or write `Window` directly.

### Architecture Diagram

```text
Home / Prep / Pre-active / Pause / Settlement / Fault presenter
        |
        | immutable AccessibleScreenSnapshotV2
        v
MobileAccessibilityBridgeV1 (app root, main thread)
        |                         |
        v                         v
AndroidAccessibilityAdapterV1   IOSAccessibilityAdapterV1
        | TalkBack                  | VoiceOver
        +----------- native action --+
                         |
                         v
             AccessibilityActionCommandV2
                         |
                         v
          active presenter typed-command validation
```

### Key Interfaces

```text
AccessibilityRoleV1={HEADING=1,TEXT=2,BUTTON=3,
  RADIO_GROUP=4,RADIO_OPTION=5,STATUS=6,
  ADJUSTABLE=7,SWITCH=8,COMBOBOX=9}

AccessibilityActionV1={ACTIVATE=1,INCREMENT=2,DECREMENT=3,
  BACK=4}

AccessibilityLiveModeV1={OFF=0,POLITE=1,ASSERTIVE=2}

AccessibilityTextArgV1={
  kind:i32(INT64=1,FIXED_MILLI=2,LOCALIZATION_KEY=3),
  i64_value:i64,localization_key_id:i32
}

AccessibleNodeRowV2={
  stable_order:i32,node_id:i64,parent_node_id:i64,role:i32,
  name_localization_key_id:i32,value_localization_key_id:i32,
  state_localization_key_id:i32,enabled:i32,selected:i32,
  set_size:i32,position_in_set:i32,allowed_action_bits:i32,
  live_mode:i32,layout_generation:i64,
  bounds_x:i32,bounds_y:i32,bounds_width:i32,bounds_height:i32,
  visible:i32,clipped:i32,
  name_arg_start:i32,name_arg_count:i32,
  value_arg_start:i32,value_arg_count:i32,
  state_arg_start:i32,state_arg_count:i32,
  arg_count:i32,args:AccessibilityTextArgV1[8]
}

AccessibleScreenSnapshotV2={
  schema_version:i32=2,screen_id:i32,screen_generation:i64,
  profile_revision:i64,source_bundle_hash:Hash256,
  layout_generation:i64,row_count:i32,
  rows:AccessibleNodeRowV2[],initial_focus_node_id:i64,
  snapshot_hash:Hash256
}

AccessibilityActionCommandV2={
  schema_version:i32=2,screen_id:i32,screen_generation:i64,
  layout_generation:i64,node_id:i64,action_id:i32,
  native_event_sequence:i64,snapshot_hash:Hash256
}

AccessibilityNativeActionPayloadV1={
  schema_version:i32=1,screen_id:i32,screen_generation:i64,
  layout_generation:i64,node_id:i64,action_id:i32,
  snapshot_hash:Hash256
}

MobileAccessibilityCapabilityV1={
  platform_id:i32,adapter_version:i32,
  status:i32(SUPPORTED=1,UNAVAILABLE=2,INCOMPATIBLE=3),
  supported_role_bits:i64,supported_action_bits:i64,
  supports_live_modes:i32
}

AccessibilityAdapterMailboxV1={
  schema_version:i32=1,process_epoch:i64,adapter_generation:i64,
  capacity:i32=32,read_sequence:i64,write_sequence:i64,overflowed:i32,
  rows:AccessibilityActionCommandV2[32]
}

AccessibilityNativeMpscHeaderV1={
  schema_version:i32=1,reserved_zero0:i32,
  process_epoch:i64,adapter_generation:i64,
  capacity:i32=64,overflowed:i32,
  enqueue_position:i64,dequeue_position:i64,
  producer_gate_state:i64,reserved_zero1:i64
}

AccessibilityNativeMpscRowV1={
  slot_sequence:i64,payload_length:i32=68,row_state:i32,
  payload:AccessibilityNativeActionPayloadV1,reserved_zero:i32[3]
}

AccessibilityNativeMpscIngressV1={
  header:AccessibilityNativeMpscHeaderV1,
  rows:AccessibilityNativeMpscRowV1[64]
}
```

`AccessibilityTextArgV1`固定16 bytes，`AccessibleNodeRowV2`固定248 bytes，`AccessibilityActionCommandV2`固定76 bytes，`AccessibilityNativeActionPayloadV1`固定68 bytes，SPSC mailbox固定2476 bytes；均canonical little-endian/no-padding。SPSC的`read_sequence/write_sequence`为单调nonnegative i64：相等为空，`write_sequence-read_sequence=32`为满，slot=`sequence mod 32`；producer写完整row后release-publish write sequence，consumer acquire-read后处理并release-publish read sequence。任何差值不在0..32、checked increment耗尽或线程角色违规都fail closed为`ID_EXHAUSTED/ACCESSIBILITY_INGRESS_OVERFLOW`，不得依赖i32 wrap。

MPSC header固定64 bytes、row固定96 bytes、总长`64+64×96=6208` bytes；reserved与unused bytes必须为0。`producer_gate_state`是单个nonnegative atomic i64，bit0为`ACCEPTING`，bits1..62为`IN_FLIGHT`计数，bit63永远0；初始化为1。producer只能以acquire-release CAS把仍带bit0的gate从`g`推进到`g+2`取得一个producer reference，bit0已清或checked `g+2`越界则返回SHUTDOWN/ID_EXHAUSTED且不触碰queue；完成任一路径都以release `fetch_sub(2)`归还引用。shutdown以acquire-release CAS原子清bit0；从这一线性化点起新producer不可能增加计数，再等待acquire读到gate=0，消除了分离accepting/in-flight字段的check-then-increment竞态。

`row_state={EMPTY=0,WRITING=1,PUBLISHED=2}`。初始化row `i.slot_sequence=i,row_state=EMPTY,payload_length=0`并清零payload/reserved，enqueue/dequeue=0。持有producer reference后读取enqueue position `p`，仅当slot=`p mod 64`的acquire `slot_sequence==p`时以CAS把enqueue从p推进到p+1；CAS成功才获得arrival ticket p，先将row_state置WRITING，再写完整68-byte payload和length，最后置PUBLISHED并release-store `slot_sequence=p+1`后归还producer reference。`slot_sequence<p`表示full：atomic置overflowed、归还引用并失败，**不得推进enqueue或消耗ticket**；`slot_sequence>p`表示竞争，重读position。serial consumer只在slot acquire sequence=`dequeue+1`且row_state=PUBLISHED/payload_length=68时读取完整payload，在serial ingress中以checked `native_event_sequence`补齐76-byte `AccessibilityActionCommandV2`后再写SPSC；处理后清零payload/length/reserved、置EMPTY，再release-store `slot_sequence=dequeue+64`并推进dequeue，禁止越过未publish slot。shutdown在gate归零后按序drain/retire MPSC与SPSC，最后才更换adapter generation；overflowed由serial/main acquire读取并关闭当前screen，native producer不得直接调用UI。任一CAS/sequence checked overflow、payload length/state错误或generation不等fail closed。adapter generation只可在两队列完全drain/retire后重置为新空代次，禁止带未读row换代。

Role field profile是封闭ABI：`ADJUSTABLE`必须以value args依次编码current/min/max/step并只允许INCREMENT/DECREMENT；`SWITCH`以`selected∈{0,1}`表达checked state并只允许ACTIVATE；`COMBOBOX`以`set_size/position_in_set`和value localization表达当前选项，允许INCREMENT/DECREMENT/ACTIVATE。BUTTON/RADIO/STATUS等旧role不得冒充这三类控件；不适用字段必须为0。Settings的四个音量使用ADJUSTABLE，canonical domain为0..100 integer percent且step=5；四个bool使用SWITCH；font scale的COMBOBOX固定100/115/130%、locale按Config stable locale row，二者都采用inline cycle，INCREMENT/DECREMENT环内移动、ACTIVATE提交当前值，不打开popup/list，因此不创建额外node。该映射复用现有8-entry typed arg tail，不改变248-byte V2 schema；Android/iOS adapter必须映射为平台对应adjustable/checkable/selectable语义，而不是普通button文本。

shutdown容量闭环：停止接纳并等待`IN_FLIGHT=0`后，serial ingress以有界批次交替执行“MPSC→SPSC搬运”和“GameRoot主线程排空SPSC”，直到两队列均为空再retire/generation reset；MPSC backlog为33..64时不得一次性塞入32-row SPSC，SPSC满只暂停搬运并等待下一帧继续。

固定screen row capacity与exact snapshot bytes如下；presenter必须分配完整tail，`row_count<=capacity`，unused rows逐byte为0，运行时不得增长：

| row / order | screen | capacity C | snapshot bytes `108+248*C` | snapshot_hash zero offset `76+248*C` |
|---|---|---:|---:|---:|
| AHP01 / 1 | HOME | 16 | 4076 | 4044 |
| AHP02 / 2 | PREP | 16 | 4076 | 4044 |
| AHP03 / 3 | PRE_ACTIVE_CHOICE | 12 | 3084 | 3052 |
| AHP04 / 4 | BATTLE_PAUSED | 24 | 6060 | 6028 |
| AHP05 / 5 | SETTLEMENT | 24 | 6060 | 6028 |
| AHP06 / 6 | CONTROLLED_FAULT | 12 | 3084 | 3052 |
| AHP07 / 7 | BATTLE_ACTIVE | 1 | 356 | 324 |

独立`AccessibilityHashPreimageManifestV1={row_id,stable_order,screen_id,tag_ascii_with_nul,hash_mode,capacity,exact_length,zero_offset,zero_length}`必须恰含上述七行，tag固定`AccessibleScreenSnapshotV2\0`、mode=`SELF_ZERO_FIELD`、zero_length=32，并逐行按公式重算；它不并入Save的25-row `HashPreimageManifestV1`。missing/duplicate、screen/capacity/length/offset漂移在publish前`INVALID_MANIFEST`。

`AccessibleScreenProfileManifestV1={profile_id,screen_id,state_variant,group_order,group_role,max_rows,required,pagination_rule,owner_gdd}`只汇总screen/group的容量预算，actual profiles固定如下；逐node语义只能来自其后的`AccessibleNodeContractV1`，不得把本汇总表当成node contract。每个profile按group order展开stable node IDs，checked sum必须≤对应capacity，未列group不得由实现临时追加：

| profile | screen/state | canonical group maxima | checked total / capacity |
|---|---|---|---:|
| ASN01 | HOME/READY_OR_RECOVERY | title1 + status1 + primary CTA1 + secondary navigation3 + balances3 + settings entry1 | 10 / 16 |
| ASN02 | HOME/SETTINGS | title1 + status1 + volume adjustable4 + font/locale combobox2 + boolean switches4 + apply1 + back1 | 14 / 16 |
| ASN03 | PREP/ALL | back1 + title1 + summary1 + radio group1 + options4 + cost/status2 + primary CTA1 | 11 / 16 |
| ASN04 | PRE_ACTIVE_CHOICE/ALL | disabled back1 + title1 + status1 + radio group1 + candidate options3 + refresh1 + commit1 | 9 / 12 |
| ASN05 | BATTLE_PAUSED/ALL | base21（含reason4）；choice可见时以B22–B28七行替换B16–B19四行 | 24 / 24 |
| ASN06 | SETTLEMENT/ALL | title1 + save status1 + primary CTA1 + reward rows6 + core stats3 + detail page status1 + detail window rows6 + prev/next2 + resolved navigation2 | 23 / 24 |
| ASN07 | CONTROLLED_FAULT/ALL | title1 + status1 + diagnostic summary1 + retry1 + safe exit1 + export diagnostic1 | 6 / 12 |
| ASN08 | BATTLE_ACTIVE/ALL | pause gateway1 | 1 / 1 |

`AccessibleNodeContractV1={profile_id,row_id,stable_order,node_id,parent_node_id,role,allowed_actions,focus_previous_node_id,focus_next_node_id,localization_key,state_rule}`的actual rows固定如下。`-`表示0/NONE；focus previous/next是完整reading/focus序中的相邻node，disabled row仍保留位置但不能激活。动态文本只通过对应localization key的typed args变化，不能改node identity。

| profile | row/order | node | parent | role/actions | focus prev→next | localization/state rule |
|---|---|---:|---:|---|---|---|
| ASN01 | H01/1 | 1001 | 0 | HEADING/- | 0→1002 | HOME_TITLE/ALWAYS |
| ASN01 | H02/2 | 1002 | 0 | STATUS/- | 1001→1003 | HOME_STATUS/BY_VARIANT |
| ASN01 | H03/3 | 1003 | 0 | BUTTON/ACTIVATE | 1002→1004 | HOME_PRIMARY/BY_VARIANT |
| ASN01 | H04/4 | 1004 | 0 | BUTTON/ACTIVATE | 1003→1005 | HOME_NAV_PROGRESSION/READY_ONLY |
| ASN01 | H05/5 | 1005 | 0 | BUTTON/ACTIVATE | 1004→1006 | HOME_NAV_SETTINGS/ALWAYS |
| ASN01 | H06/6 | 1006 | 0 | BUTTON/ACTIVATE | 1005→1007 | HOME_NAV_DIAGNOSTIC/RECOVERY_ONLY |
| ASN01 | H07/7 | 1007 | 0 | TEXT/- | 1006→1008 | HOME_BALANCE_STONE/ALWAYS |
| ASN01 | H08/8 | 1008 | 0 | TEXT/- | 1007→1009 | HOME_BALANCE_PAGE/ALWAYS |
| ASN01 | H09/9 | 1009 | 0 | TEXT/- | 1008→1010 | HOME_BALANCE_SEED/ALWAYS |
| ASN01 | H10/10 | 1010 | 0 | BUTTON/ACTIVATE | 1009→0 | HOME_SETTINGS_ENTRY/ALWAYS |
| ASN02 | S01/1 | 1101 | 0 | HEADING/- | 0→1102 | SETTINGS_TITLE/ALWAYS |
| ASN02 | S02/2 | 1102 | 0 | STATUS/- | 1101→1103 | SETTINGS_STATUS/BY_VARIANT |
| ASN02 | S03/3 | 1103 | 0 | ADJUSTABLE/INC+DEC | 1102→1104 | SETTINGS_MASTER_VOLUME/ALWAYS |
| ASN02 | S04/4 | 1104 | 0 | ADJUSTABLE/INC+DEC | 1103→1105 | SETTINGS_MUSIC_VOLUME/ALWAYS |
| ASN02 | S05/5 | 1105 | 0 | ADJUSTABLE/INC+DEC | 1104→1106 | SETTINGS_SFX_VOLUME/ALWAYS |
| ASN02 | S06/6 | 1106 | 0 | ADJUSTABLE/INC+DEC | 1105→1107 | SETTINGS_UI_VOLUME/ALWAYS |
| ASN02 | S07/7 | 1107 | 0 | COMBOBOX/INC+DEC+ACTIVATE | 1106→1108 | SETTINGS_FONT_SCALE/INLINE_CYCLE |
| ASN02 | S08/8 | 1108 | 0 | COMBOBOX/INC+DEC+ACTIVATE | 1107→1109 | SETTINGS_LOCALE/INLINE_CYCLE |
| ASN02 | S09/9 | 1109 | 0 | SWITCH/ACTIVATE | 1108→1110 | SETTINGS_REDUCE_MOTION/ALWAYS |
| ASN02 | S10/10 | 1110 | 0 | SWITCH/ACTIVATE | 1109→1111 | SETTINGS_REDUCE_SENSORY_LOAD/ALWAYS |
| ASN02 | S11/11 | 1111 | 0 | SWITCH/ACTIVATE | 1110→1112 | SETTINGS_HIGH_CONTRAST/ALWAYS |
| ASN02 | S12/12 | 1112 | 0 | SWITCH/ACTIVATE | 1111→1113 | SETTINGS_SCREEN_READER_HINTS/ALWAYS |
| ASN02 | S13/13 | 1113 | 0 | BUTTON/ACTIVATE | 1112→1114 | SETTINGS_APPLY/DIRTY_ONLY |
| ASN02 | S14/14 | 1114 | 0 | BUTTON/BACK | 1113→0 | SETTINGS_BACK/ALWAYS |
| ASN03 | P01/1 | 2001 | 0 | BUTTON/BACK | 0→2002 | PREP_BACK/DRAFT_ONLY |
| ASN03 | P02/2 | 2002 | 0 | HEADING/- | 2001→2003 | PREP_TITLE/ALWAYS |
| ASN03 | P03/3 | 2003 | 0 | STATUS/- | 2002→2004 | PREP_SUMMARY/BY_VARIANT |
| ASN03 | P04/4 | 2004 | 0 | RADIO_GROUP/- | 2003→2005 | PREP_OPTIONS/ALWAYS |
| ASN03 | P05/5 | 2005 | 2004 | RADIO_OPTION/ACTIVATE | 2004→2006 | PREP_NONE/SELECTABLE |
| ASN03 | P06/6 | 2006 | 2004 | RADIO_OPTION/ACTIVATE | 2005→2007 | PREP_QI_PILL/IN_STOCK |
| ASN03 | P07/7 | 2007 | 2004 | RADIO_OPTION/ACTIVATE | 2006→2008 | PREP_IRON_PILL/IN_STOCK |
| ASN03 | P08/8 | 2008 | 2004 | RADIO_OPTION/ACTIVATE | 2007→2009 | PREP_MIND_PILL/IN_STOCK |
| ASN03 | P09/9 | 2009 | 0 | TEXT/- | 2008→2010 | PREP_COST/BY_SELECTION |
| ASN03 | P10/10 | 2010 | 0 | STATUS/- | 2009→2011 | PREP_SAVE_STATUS/BY_VARIANT |
| ASN03 | P11/11 | 2011 | 0 | BUTTON/ACTIVATE | 2010→0 | PREP_PRIMARY/DRAFT_ONLY |
| ASN04 | C01/1 | 3001 | 0 | BUTTON/BACK | 0→3002 | PREACTIVE_BACK/ALWAYS_DISABLED |
| ASN04 | C02/2 | 3002 | 0 | HEADING/- | 3001→3003 | PREACTIVE_TITLE/ALWAYS |
| ASN04 | C03/3 | 3003 | 0 | STATUS/- | 3002→3004 | PREACTIVE_STATUS/BY_VARIANT |
| ASN04 | C04/4 | 3004 | 0 | RADIO_GROUP/- | 3003→3005 | PREACTIVE_OPTIONS/OFFER_READY |
| ASN04 | C05/5 | 3005 | 3004 | RADIO_OPTION/ACTIVATE | 3004→3006 | PREACTIVE_CANDIDATE_1/OFFER_READY |
| ASN04 | C06/6 | 3006 | 3004 | RADIO_OPTION/ACTIVATE | 3005→3007 | PREACTIVE_CANDIDATE_2/OFFER_READY |
| ASN04 | C07/7 | 3007 | 3004 | RADIO_OPTION/ACTIVATE | 3006→3008 | PREACTIVE_CANDIDATE_3/OFFER_READY |
| ASN04 | C08/8 | 3008 | 0 | BUTTON/ACTIVATE | 3007→3009 | PREACTIVE_REFRESH/CAN_REFRESH |
| ASN04 | C09/9 | 3009 | 0 | BUTTON/ACTIVATE | 3008→0 | PREACTIVE_COMMIT/HAS_SELECTION |
| ASN05 | B01/1 | 4001 | 0 | HEADING/- | 0→4002 | PAUSE_TITLE/ALWAYS |
| ASN05 | B02/2 | 4002 | 0 | STATUS/- | 4001→4003 | PAUSE_STATUS/BY_VARIANT |
| ASN05 | B03/3 | 4003 | 0 | BUTTON/ACTIVATE | 4002→4004 | PAUSE_CONTINUE/CONTINUE_ALLOWED |
| ASN05 | B04/4 | 4004 | 0 | BUTTON/ACTIVATE | 4003→4005 | PAUSE_EXIT/EXIT_ALLOWED |
| ASN05 | B05/5 | 4005 | 0 | BUTTON/BACK | 4004→4006 | PAUSE_CANCEL_CONFIRM/CONFIRM_ONLY |
| ASN05 | B06/6 | 4006 | 0 | TEXT/- | 4005→4007 | PAUSE_HP/ALWAYS |
| ASN05 | B07/7 | 4007 | 0 | TEXT/- | 4006→4008 | PAUSE_LEVEL/ALWAYS |
| ASN05 | B08/8 | 4008 | 0 | TEXT/- | 4007→4009 | PAUSE_XP/ALWAYS |
| ASN05 | B09/9 | 4009 | 0 | TEXT/- | 4008→4010 | PAUSE_ATTACK/ALWAYS |
| ASN05 | B10/10 | 4010 | 0 | TEXT/- | 4009→4011 | PAUSE_CRIT/ALWAYS |
| ASN05 | B11/11 | 4011 | 0 | TEXT/- | 4010→4012 | PAUSE_SPEED/ALWAYS |
| ASN05 | B12/12 | 4012 | 0 | TEXT/- | 4011→4013 | PAUSE_SKILL_1/PRESENT_IF_FILLED |
| ASN05 | B13/13 | 4013 | 0 | TEXT/- | 4012→4014 | PAUSE_SKILL_2/PRESENT_IF_FILLED |
| ASN05 | B14/14 | 4014 | 0 | TEXT/- | 4013→4015 | PAUSE_SKILL_3/PRESENT_IF_FILLED |
| ASN05 | B15/15 | 4015 | 0 | TEXT/- | 4014→4016 | PAUSE_SKILL_4/PRESENT_IF_FILLED |
| ASN05 | B16/16 | 4016 | 0 | STATUS/- | 4015→4017 | PAUSE_REASON_1/PRESENT_IF_ACTIVE |
| ASN05 | B17/17 | 4017 | 0 | STATUS/- | 4016→4018 | PAUSE_REASON_2/PRESENT_IF_ACTIVE |
| ASN05 | B18/18 | 4018 | 0 | STATUS/- | 4017→4019 | PAUSE_REASON_3/PRESENT_IF_ACTIVE |
| ASN05 | B19/19 | 4019 | 0 | STATUS/- | 4018→4020 | PAUSE_REASON_4/PRESENT_IF_ACTIVE |
| ASN05 | B20/20 | 4020 | 0 | BUTTON/ACTIVATE | 4019→4021 | PAUSE_PREVIOUS_SECTION/HAS_PREVIOUS |
| ASN05 | B21/21 | 4021 | 0 | BUTTON/ACTIVATE | 4020→4022 | PAUSE_NEXT_SECTION/HAS_NEXT |
| ASN05 | B22/22 | 4022 | 0 | RADIO_GROUP/- | 4021→4023 | PAUSE_CHOICE_GROUP/CHOICE_VISIBLE |
| ASN05 | B23/23 | 4023 | 4022 | RADIO_OPTION/ACTIVATE | 4022→4024 | PAUSE_CHOICE_1/CANDIDATE_1 |
| ASN05 | B24/24 | 4024 | 4022 | RADIO_OPTION/ACTIVATE | 4023→4025 | PAUSE_CHOICE_2/CANDIDATE_2 |
| ASN05 | B25/25 | 4025 | 4022 | RADIO_OPTION/ACTIVATE | 4024→4026 | PAUSE_CHOICE_3/CANDIDATE_3 |
| ASN05 | B26/26 | 4026 | 4022 | RADIO_OPTION/ACTIVATE | 4025→4027 | PAUSE_CHOICE_4/CANDIDATE_4 |
| ASN05 | B27/27 | 4027 | 0 | BUTTON/ACTIVATE | 4026→4028 | PAUSE_CHOICE_REFRESH/CAN_REFRESH |
| ASN05 | B28/28 | 4028 | 0 | BUTTON/ACTIVATE | 4027→0 | PAUSE_CHOICE_COMMIT/HAS_SELECTION |
| ASN06 | T01/1 | 5001 | 0 | HEADING/- | 0→5002 | SETTLEMENT_TITLE/ALWAYS |
| ASN06 | T02/2 | 5002 | 0 | STATUS/- | 5001→5003 | SETTLEMENT_SAVE_STATUS/BY_VARIANT |
| ASN06 | T03/3 | 5003 | 0 | BUTTON/ACTIVATE | 5002→5004 | SETTLEMENT_PRIMARY/BY_VARIANT |
| ASN06 | T04/4 | 5004 | 0 | TEXT/- | 5003→5005 | SETTLEMENT_REWARD_1/PRESENT_IF_NONZERO |
| ASN06 | T05/5 | 5005 | 0 | TEXT/- | 5004→5006 | SETTLEMENT_REWARD_2/PRESENT_IF_NONZERO |
| ASN06 | T06/6 | 5006 | 0 | TEXT/- | 5005→5007 | SETTLEMENT_REWARD_3/PRESENT_IF_NONZERO |
| ASN06 | T07/7 | 5007 | 0 | TEXT/- | 5006→5008 | SETTLEMENT_REWARD_4/PRESENT_IF_NONZERO |
| ASN06 | T08/8 | 5008 | 0 | TEXT/- | 5007→5009 | SETTLEMENT_REWARD_5/PRESENT_IF_NONZERO |
| ASN06 | T09/9 | 5009 | 0 | TEXT/- | 5008→5010 | SETTLEMENT_REWARD_6/PRESENT_IF_NONZERO |
| ASN06 | T10/10 | 5010 | 0 | TEXT/- | 5009→5011 | SETTLEMENT_CORE_1/ALWAYS |
| ASN06 | T11/11 | 5011 | 0 | TEXT/- | 5010→5012 | SETTLEMENT_CORE_2/ALWAYS |
| ASN06 | T12/12 | 5012 | 0 | TEXT/- | 5011→5013 | SETTLEMENT_CORE_3/ALWAYS |
| ASN06 | T13/13 | 5013 | 0 | STATUS/- | 5012→5014 | SETTLEMENT_PAGE_STATUS/ALWAYS |
| ASN06 | T14/14 | 5014 | 0 | TEXT/- | 5013→5015 | SETTLEMENT_DETAIL_1/PAGE_SLOT |
| ASN06 | T15/15 | 5015 | 0 | TEXT/- | 5014→5016 | SETTLEMENT_DETAIL_2/PAGE_SLOT |
| ASN06 | T16/16 | 5016 | 0 | TEXT/- | 5015→5017 | SETTLEMENT_DETAIL_3/PAGE_SLOT |
| ASN06 | T17/17 | 5017 | 0 | TEXT/- | 5016→5018 | SETTLEMENT_DETAIL_4/PAGE_SLOT |
| ASN06 | T18/18 | 5018 | 0 | TEXT/- | 5017→5019 | SETTLEMENT_DETAIL_5/PAGE_SLOT |
| ASN06 | T19/19 | 5019 | 0 | TEXT/- | 5018→5020 | SETTLEMENT_DETAIL_6/PAGE_SLOT |
| ASN06 | T20/20 | 5020 | 0 | BUTTON/ACTIVATE | 5019→5021 | SETTLEMENT_PREVIOUS_PAGE/HAS_PREVIOUS |
| ASN06 | T21/21 | 5021 | 0 | BUTTON/ACTIVATE | 5020→5022 | SETTLEMENT_NEXT_PAGE/HAS_NEXT |
| ASN06 | T22/22 | 5022 | 0 | BUTTON/ACTIVATE | 5021→5023 | SETTLEMENT_HOME/RESOLVED_ONLY |
| ASN06 | T23/23 | 5023 | 0 | BUTTON/ACTIVATE | 5022→0 | SETTLEMENT_RETRY/RESOLVED_ONLY |
| ASN07 | F01/1 | 6001 | 0 | HEADING/- | 0→6002 | FAULT_TITLE/ALWAYS |
| ASN07 | F02/2 | 6002 | 0 | STATUS/- | 6001→6003 | FAULT_STATUS/BY_VARIANT |
| ASN07 | F03/3 | 6003 | 0 | TEXT/- | 6002→6004 | FAULT_DIAGNOSTIC/BY_VARIANT |
| ASN07 | F04/4 | 6004 | 0 | BUTTON/ACTIVATE | 6003→6005 | FAULT_RETRY/RETRYABLE_ONLY |
| ASN07 | F05/5 | 6005 | 0 | BUTTON/ACTIVATE | 6004→6006 | FAULT_SAFE_EXIT/EXIT_ALLOWED |
| ASN07 | F06/6 | 6006 | 0 | BUTTON/ACTIVATE | 6005→0 | FAULT_EXPORT/DIAGNOSTIC_AVAILABLE |
| ASN08 | A01/1 | 7001 | 0 | BUTTON/ACTIVATE | 0→0 | BATTLE_ACTIVE_PAUSE/ALWAYS |

`AccessibleScreenStateVariantManifestV1={variant_id,profile_id,owner_state,enabled_action_nodes,initial_focus_node_id,live_node_id,state_localization_key}`固定为以下35条actual rows；`{}`是canonical空集合，不是省略：

| variant/order | profile | owner state | enabled action nodes | initial focus | live node | state localization key |
|---|---|---|---|---:|---:|---|
| AHV01/1 | ASN01 | READY | {1003,1004,1005,1010} | 1003 | 1002 | HOME_READY_STATUS |
| AHV02/2 | ASN01 | RESERVATION_RECOVERY | {1005,1006,1010} | 1006 | 1002 | HOME_RECOVERY_STATUS |
| AHV03/3 | ASN01 | SAVE_UNCERTAIN | {1005,1006,1010} | 1006 | 1002 | HOME_SAVE_UNCERTAIN_STATUS |
| AHV04/4 | ASN01 | UPDATE_REQUIRED | {1005,1006,1010} | 1006 | 1002 | HOME_UPDATE_REQUIRED_STATUS |
| AHV05/5 | ASN01 | CORRUPT_OR_CONFLICT | {1005,1006,1010} | 1006 | 1002 | HOME_CONFLICT_STATUS |
| AHV06/6 | ASN02 | CLEAN | {1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1114} | 1103 | 1102 | SETTINGS_CLEAN_STATUS |
| AHV07/7 | ASN02 | DIRTY | {1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1113,1114} | 1103 | 1102 | SETTINGS_DIRTY_STATUS |
| AHV08/8 | ASN02 | APPLYING | {1114} | 1114 | 1102 | SETTINGS_APPLYING_STATUS |
| APV01/9 | ASN03 | DRAFT | {2001,2005,2006,2007,2008,2011} | 2005 | 2010 | PREP_DRAFT_STATUS |
| APV02/10 | ASN03 | RESERVING | {} | 2010 | 2010 | PREP_RESERVING_STATUS |
| APV03/11 | ASN03 | UNCERTAIN | {} | 2010 | 2010 | PREP_UNCERTAIN_STATUS |
| APV04/12 | ASN03 | RELEASING | {} | 2010 | 2010 | PREP_RELEASING_STATUS |
| APV05/13 | ASN03 | BLOCKED | {2001} | 2001 | 2010 | PREP_BLOCKED_STATUS |
| ACV01/14 | ASN04 | OFFER_READY | {3005,3006,3007,3008,3009} | 3005 | 3003 | PREACTIVE_OFFER_READY_STATUS |
| ACV02/15 | ASN04 | REFRESH_PENDING | {} | 3003 | 3003 | PREACTIVE_REFRESH_PENDING_STATUS |
| ACV03/16 | ASN04 | COMMIT_PENDING | {} | 3003 | 3003 | PREACTIVE_COMMIT_PENDING_STATUS |
| ACV04/17 | ASN04 | UNCERTAIN_OR_RECOVERING | {} | 3003 | 3003 | PREACTIVE_RECOVERING_STATUS |
| ACV05/18 | ASN04 | BLOCKED | {} | 3003 | 3003 | PREACTIVE_BLOCKED_STATUS |
| ABV01/19 | ASN05 | MANUAL | {4003,4004,4020,4021} | 4003 | 4002 | PAUSE_MANUAL_STATUS |
| ABV02/20 | ASN05 | EXIT_CONFIRM | {4003,4005} | 4005 | 4002 | PAUSE_EXIT_CONFIRM_STATUS |
| ABV03/21 | ASN05 | BLOCKING_CHOICE_OR_BACKGROUND | {4020,4021,4022,4023,4024,4025,4026,4027,4028} | 4020 | 4002 | PAUSE_BLOCKING_STATUS |
| ABV04/22 | ASN05 | GEOMETRY_OR_RESUME_PENDING | {} | 4002 | 4002 | PAUSE_PENDING_STATUS |
| ATV01/23 | ASN06 | NOT_STARTED | {5003,5020,5021} | 5003 | 5002 | SETTLEMENT_NOT_STARTED_STATUS |
| ATV02/24 | ASN06 | SAVE_PENDING | {5020,5021} | 5002 | 5002 | SETTLEMENT_SAVE_PENDING_STATUS |
| ATV03/25 | ASN06 | SAVE_UNCERTAIN | {5003,5020,5021} | 5003 | 5002 | SETTLEMENT_SAVE_UNCERTAIN_STATUS |
| ATV04/26 | ASN06 | SAVE_FAILED | {5003,5020,5021} | 5003 | 5002 | SETTLEMENT_SAVE_FAILED_STATUS |
| ATV05/27 | ASN06 | DISCARD_PENDING | {5020,5021} | 5002 | 5002 | SETTLEMENT_DISCARD_PENDING_STATUS |
| ATV06/28 | ASN06 | SAVE_SUCCEEDED | {5003,5020,5021,5022,5023} | 5003 | 5002 | SETTLEMENT_SAVE_SUCCEEDED_STATUS |
| ATV07/29 | ASN06 | DISCARDED | {5003,5020,5021,5022,5023} | 5003 | 5002 | SETTLEMENT_DISCARDED_STATUS |
| ATV08/30 | ASN06 | DISCARD_CONFIRM | {5003} | 5003 | 5002 | SETTLEMENT_DISCARD_CONFIRM_STATUS |
| AAV01/31 | ASN08 | GAMEPLAY | {7001} | 7001 | 0 | BATTLE_ACTIVE_STATUS |
| AFV01/32 | ASN07 | NO_PROFILE | {6005,6006} | 6005 | 6002 | FAULT_NO_PROFILE_STATUS |
| AFV02/33 | ASN07 | PRE_BATTLE_RETRYABLE | {6004,6005,6006} | 6004 | 6002 | FAULT_PRE_BATTLE_STATUS |
| AFV03/34 | ASN07 | BATTLE_SAFE_EXIT | {6005,6006} | 6005 | 6002 | FAULT_BATTLE_STATUS |
| AFV04/35 | ASN07 | CORRUPT_OR_CONFLICT | {6005,6006} | 6005 | 6002 | FAULT_CONFLICT_STATUS |

generated artifact必须再展开每个variant/node/action组合为独立row，不允许range token进入artifact。节点合同允许互斥动态组：`PAUSE_CHOICE_*`七行（B22–B28，含group、四candidate、refresh、commit）只在`choice_visible=1`时出现，并替换同一variant中的B16–B19四个`PAUSE_REASON_*`行。非choice上界为B01–B21共21；choice上界为B01–B15、B20–B28共24，即21−4+7=24。presenter必须按每variant展开并证明可见行数≤24。未列variant、node/action不属于enabled集合却被激活、initial focus不可见/disabled或live node缺失均`INVALID_MANIFEST`。此为MOBILE_TOUCH future-port计数澄清，不代表native运行证据。

焦点图规则：`focus_previous_node_id/focus_next_node_id`仅是完整reading顺序的base邻接；presenter发布时按`visible`与动态predicate过滤不可见`PAGE_SLOT`/条件行并重连剩余可见节点，disabled行仍保留可读位置但不可激活。四个focus action只移动该图，不产生业务command。

方向焦点另有唯一 canonical `DirectionalFocusNeighborManifestV1={profile_id,variant_id,node_id,left_node_id,right_node_id,algorithm_version}`；它只对当前variant中`allowed_actions`含focus且`visible=1`的node生成一行。`left/right`按同一variant的可见、enabled focusable node集合计算：先最小化主轴距离，再最小化横向距离，最后按`stable_order`升序破平；无候选写`0`。presenter每次variant/dynamic predicate变化必须按该算法重建并逐行匹配golden，`FOCUS_LEFT/RIGHT`只沿对应字段移动，禁止交给Godot自动猜测或退化为previous/next；缺row、算法版本、候选或golden不匹配均`INVALID_MANIFEST`。

Settings 的持久布尔节点必须与 `home-ui.md` 的 `reduce_motion/reduce_sensory_load/high_contrast/screen_reader_hints` 四字段逐位一致；不得把测试用的 mono audio 或 haptics 开关冒充持久 Settings 合同。

SETTLEMENT的“全部非零技能伤害/承伤/Risk/纪录”先按其GDD稳定总序构造只读detail source，再以固定window capacity6分页；当前snapshot只含当前页6行及page X/Y status，上一页/下一页在边界时保留可读但disabled。翻页只改presentation generation，不改Outcome/Save事实。任何source row必须在某一页恰出现一次，页数与索引checked；不得截断、top-N冒充全部或运行时扩容。每个profile的generated semantic golden必须逐row等于上述node与variant manifests，并冻结typed localization args/bounds；仅验证`row_count<=capacity`不能PASS。

Keyboard与mapped gamepad只允许来自Input GDD的8-row `MetaUiInputActionManifestV1`。四个focus action只生成presenter-local `MetaUiNavigationCommandV1`并沿同一focus graph移动focus，业务命令为0；ACTIVATE/BACK/INCREMENT/DECREMENT在目标node验证后才与native accessibility action汇入同一owner typed business command。`MetaUiNavigationCommandV1`不得编码成`AccessibilityActionCommandV2`，因为native action直接指定node且不存在focus方向。PRE_ACTIVE_CHOICE的back row存在但disabled，ADR不再授权cancel command。

Rows are canonical by `stable_order ASC`; IDs and generations are positive checked integers。bounds使用当前safe-area内容坐标系的logical pixel整数，width/height必须正，interactive row必须`visible=1,clipped=0`且action point位于bounds内；每次reflow递增`layout_generation`并原子替换整棵tree。三个localization key分别通过start/count指向同一8-entry typed arg tail，范围不重叠、count和总量checked，禁止把预格式化动态String或视觉label猜测成可访问值。A snapshot is published atomically only after every row, parent relation, role/action combination, localization key+args, bounds, initial focus target and layout generation validates. A native action matching the current snapshot is consumed at most once by `{process_epoch,adapter_generation,screen_generation,layout_generation,native_event_sequence}`. Stale layout, stale screen, duplicate, unknown, invisible/clipped or disabled-node actions produce no typed business command。第33条未排空callback、sequence exhaustion、epoch/generation不匹配或producer/consumer线程违规均fail closed：锁存adapter diagnostic、停用交互screen并进入localized support error；不得覆盖未读command、动态扩容或静默丢弃后继续声称SUPPORTED。键盘与gamepad focus是presenter-local导航，activation/back与无障碍action在owner command gate后产生相同typed业务命令；未经Input mapping的raw gamepad axis只产生0 business command，不得被误报为“gamepad不支持”。

## Alternatives Considered

### Alternative 1: Rely only on Godot Control accessibility metadata

- **Pros**: Least custom platform code.
- **Cons**: Does not presently prove exported Android/iOS tree, action, focus or live-region behavior for this project.
- **Rejection Reason**: It cannot close the target-platform evidence gap and makes semantics dependent on scene-tree inspection.

### Alternative 2: Remove mobile screen-reader support from MVP

- **Pros**: No native bridge implementation cost.
- **Cons**: Narrows an existing mobile accessibility requirement and leaves key meta flows inaccessible.
- **Rejection Reason**: The authorized remediation keeps Android/iOS accessibility in MVP scope.

### Alternative 3: Platform plugins call Save or UI services directly

- **Pros**: Fewer adapter hops.
- **Cons**: Gives native callbacks business authority, bypasses generation checks and creates stale-callback races.
- **Rejection Reason**: Violates presenter-only ownership and typed-command boundaries.

## Consequences

### Positive

- One cross-platform semantic contract and one stale-action defense.
- Native adapters remain replaceable without changing business commands.
- Accessibility semantics are testable independently from visual layout.

### Negative

- Requires Kotlin/Android and Swift/iOS adapter work plus exported-device testing.
- Snapshot construction and localization-state coverage add authoring overhead.

### Risks

- Godot 4.7.1 accessibility APIs or export hooks may differ from assumptions; compile and exported-build spikes are mandatory.
- Native focus and Godot dual-focus may diverge; traces must validate both paths without sharing mutable focus state.
- Live announcements can become noisy; only state changes listed by each GDD may use POLITE/ASSERTIVE.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `home-ui.md` | Stable reading order, recovery status and primary CTA | Immutable Home snapshot plus typed activation |
| `prep-ui.md` | Four-option radio semantics, stock/disabled state and live Save status | RADIO_GROUP/RADIO_OPTION rows and status live modes |
| `skill-draft-system.md` | Pre-active ordinary level-up choice before movement/survival | Full semantic choice rows, dynamic localized values and choose action；back可读但disabled，cancel command为0 |
| `battle-ui.md` | Paused battle controls | Bounds-aware paused snapshot and typed resume/settings actions；不拥有root fault surface |
| `settlement-system.md` | Result-first reading order, Save state and resolved navigation | Ordered snapshot and generation-bound actions |
| `game-root-scene-flow.md` | Controlled-fault recovery and stale callback retirement | Persistent root-owned FaultPresentationBundle/snapshot plus all-TopState pump |
| `zhangtian-bottle.md` | Mobile TalkBack/VoiceOver architecture decision | Chooses native adapters without giving them inventory authority |

## Performance Implications

- **CPU**: Rebuild only on screen/bundle generation changes, never per gameplay tick.
- **Memory**: Each 248-byte row and eight-entry arg tail is covered by fixed per-screen row maxima in UI manifests; runtime maxima remain to be measured.
- **Load Time**: Adapter capability handshake occurs before interactive meta UI activation.
- **Network**: None.

## Migration Plan

1. Add the engine-independent semantic structs and validators.
2. Make Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault presenters emit complete V2 snapshots from existing immutable presentation bundles.
3. Implement Android and iOS adapters behind the same bridge interface.
4. Add stale/duplicate action tests, then exported-device TalkBack/VoiceOver tree and interaction traces.
5. Keep `BLOCKED-MOBILE-A11Y-RUNTIME` until both target platform evidence sets pass.

## Validation Criteria

- Schema tests reject missing, duplicate, cyclic, unordered, stale or unsupported rows/actions.
- All seven action-bearing TopStates publish expected semantic-tree goldens at 100/115/130% text, long locale, cutout and documented state combinations; row counts fit the fixed 16/16/12/24/24/12/1 capacities, exact snapshot lengths and self-hash offsets match the seven-row manifest, and non-action TopStates publish no interactive snapshot but still drain stale commands. The BATTLE_ACTIVE golden contains exactly the pause gateway node and no gameplay HUD rows.
- Golden rows verify exact bounds, `layout_generation`, visible/clipped state and typed localization args; reflow followed by an old native callback produces zero business commands.
- TalkBack and VoiceOver can reach, identify and activate every enabled control in documented order; disabled items remain readable but not activatable.
- Arbitrary-thread native callbacks first pass the fixed 6208-byte MPSC64 ingress; 64/65-row concurrent bursts逐slot验证CAS only-on-free、full不推进enqueue、不产生ticket hole、payload-before-release-publish与consumer acquire。Only the serial ingress allocates checked i64 `native_event_sequence` and writes SPSC; stale/duplicate callbacks produce zero business commands, 32/33-row SPSC bursts prove downstream full/overflow, and either sequence exhaustion fails closed without wrap. Shutdown proves stop-accepting→producer-in-flight=0→MPSC drain/retire→SPSC drain/retire before generation reset，并注入producer已increment、CAS前/后、payload publish前/后的race。
- Keyboard and mapped gamepad focus/activation reach every enabled control through the same typed command path; an unmapped native raw axis produces zero business commands.
- Capability `UNAVAILABLE/INCOMPATIBLE` never activates an unlabeled interactive screen.
- Godot 4.7.1 `AccessibilityServer.AccessibilityLiveMode` usage compiles and behaves as recorded on target exports.

## Related Decisions

- `design/gdd/home-ui.md`
- `design/gdd/prep-ui.md`
- `design/gdd/settlement-system.md`
- `design/gdd/zhangtian-bottle.md`
- `.claude/docs/technical-preferences.md`
