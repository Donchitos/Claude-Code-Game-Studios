# Zhangtian Bottle — Design Review Log

> 本文件记录 `design/gdd/zhangtian-bottle.md` 的独立 full review 与作者整改，不把静态修订记作复审通过。

## 第八轮作者整改（用户授权，2026-09-08）

本轮针对第八次 clean-context full re-review 的 8 组合同 blocker 完成跨文档传播：

1. 将 `PlayerStaticConfigV1` 与 `PlayerRunProjectionV1` 分离，projection 使用独立 hash，不再污染静态 config hash。
2. 持久化 64-byte `ReservationCreateCorrelationV1`（含 source kind/command/press/attempt/hash），`DurableReservationV2=1152`、`ZhangtianReservationPayloadV2=724`，CreateResultV3 回显五项 correlation；新增 `ReservationUpdateIdentityLeaseV1` 解决 request-id 自引用。
3. RCO 升级 V2 十一个 operation，RCC×RCO 固定 132 行；RRD marker/checkpoint 前置 validator、RESOLVE `FOUND_OLD` 与旧 reservation 保留语义闭合。
4. Save 新增六行 `SaveGlobalCodecHashManifestV1`，SlotPayload/Encoded 上限统一为 42244/42456。
5. ADR 补齐 BATTLE_PAUSED 动态 choice 节点、Settings 四持久布尔字段与 base-focus graph 过滤规则；Input Meta UI 扩为 8 行含 INCREMENT/DECREMENT。
6. native MPSC row 采用 68-byte payload/96-byte row，serial ingress 补齐 76-byte command；shutdown 以有界批次交替 drain，覆盖 33..64 backlog。
7. Boss/Settlement/GameRoot 统一 completed-before/executing/completed-after tick 语义，43200 执行 tick 可生成 Boss 且 survival=43200 合法。
8. 更新 registry、technical preferences、systems-index、session state，并保留所有 runtime/device/generated evidence gate。

当前状态：`In Review / Re-review Pending`。本节是作者整改记录，不构成第九次独立 verdict；generated codec/hash/crash/accessibility artifacts、Godot/GDUnit4、process-kill、Android/iOS、性能、音频、经济与玩家证据仍 OPEN，`battle_ready=false`。

---

## Re-review — 2026-09-08 — 第八次 clean-context full re-review

Verdict：`MAJOR REVISION NEEDED`；Scope signal：XL。由 persistence/engine/QA、UX/accessibility/audio specialists 与 fresh creative-director 独立综合。识别 8 组根 blocker：

1. 静态 Config hash 与 per-run projection 未分层；
2. create restart correlation 与 update identity lease 不完整；
3. crash/reconcile truth 未形成可枚举的 132-row oracle；
4. Save hash manifest 与 1152/42244/42456 容量口径未闭合；
5. accessibility node/choice、Settings、Input 与 MPSC ABI 仍有跨文档漂移；
6. pause 动态 choice 与焦点/并发容量的互斥规则缺失；
7. Boss 43200 tick 的 completed-before/executing/completed-after 语义不一致；
8. registry、session state 与历史旧 ABI 未完成统一传播。

本 verdict 仅记录独立审计结果；随后用户授权完成本文件上方“第八轮作者整改”中的跨文档传播。runtime/device/generated artifact 仍未验证，状态保持 `In Review / Re-review Pending`、`battle_ready=false`。

---

## Re-review — 第七次历史记录（2026-09-08）— Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: seventh fresh-context full re-review
Specialists: persistence/engine/QA、UX/accessibility/audio + fresh independent creative-director synthesis
Prior sixth-round blocker closure: 0 CLOSED / 7 PARTIAL
Creative Director verdict: **MAJOR REVISION NEEDED**
Root blocking groups: 7

### 第七轮7组根 blocker

1. 204-byte create result尚未形成完整合同：缺pre-durable source correlation、durable operation/recovery identity与allocator耗尽结果，callback loss后caller无法安全区分同一次create。
2. durable receipt内的事实码与public delivery/reconcile码混用；GameRoot DISCARDED presence/reducer存在冲突、重复row与历史code残留。
3. pre-active scratch RNG在UNCERTAIN后只写“reconcile”，未按selected formal OLD/NEW事实规定discard或commit scratch。
4. AC-ZB04把0奖励的早败Defeat也纳入Victory/Defeat正随机收益率量词，导致分母/比较域不成立。
5. 12条crash cut只冻结介质阶段，84条跨7种operation的profile/reservation/marker/resolution/receipt/tombstone expected truth不能唯一推导。
6. 七个accessibility profile仍只是group maxima，不是逐node/逐state ABI；Settlement“全部明细”的分页source/command/focus边界不完整。
7. MPSC64只写拓扑名，没有header/slot sequence/CAS publish/full/no-hole/shutdown producer retirement的可实现并发ABI。

### 第七轮作者整改（用户于2026-09-08回复“继续”）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | `ReservationCreateResultV3`固定204 bytes，完整回显source kind/command/press/request hash，返回durable operation/reservation/battle/preparation/request identity并封闭`ID_EXHAUSTED`；Save row/mailbox升级220/484 bytes | codec、allocator exhaustion与callback-loss runtime待证 |
| 2 | `ReservationReceiptV1.result_code`固定durable `SUCCEEDED`；public result独立允许`SUCCEEDED/RECONCILE_FOUND`。GameRoot total reducer统一DISCARDED为matching非零receipt+tombstone并清除重复/历史code | generated reducer matrix与restart trace待证 |
| 3 | 新增`ReservationUpdateReconcileProofV1`：selected next hash只返回FOUND并commit scratch，selected old hash且attempt absence proof完整只返回FOUND_OLD并discard scratch，UNPROVEN继续冻结 | 双槽/temp/writer与RNG runtime fault injection待证 |
| 4 | AC-ZB04只对43200..108000 ticks的有随机奖励Victory/Defeat比较rate；早败Defeat仅验证quantity=0并明确排除rate cohort | 经济模拟与玩家样本待执行 |
| 5 | 新增7-row `ReservationCrashOperationManifestV1`与12-row `ReservationCrashCutManifestV2`，以笛卡尔积唯一生成84条operation×cut expected truth | 84-row generated fixture、平台barrier与process-kill待执行 |
| 6 | ADR区分7-row profile预算、94-row逐node合同与34-row逐state variant；Settings role/action、Input本地focus边界与Settlement typed 6-row detail pagination均有actual schema/AC | native adapter、TalkBack/VoiceOver、gamepad与UI automation待证 |
| 7 | 冻结64-byte MPSC header、64×96-byte rows、6208-byte总长，单atomic producer gate及slot sequence/CAS/full不推进/no-hole/shutdown retirement协议 | 原子内存序、burst/overflow与detach真机trace待证 |

### 当前状态

**In Review / Re-review Pending**。本轮仅是第七次独立verdict后的作者静态整改，不构成第八次独立通过。作者合同已跨Save、GameRoot、RNG、SkillDraft、Zhangtian、Settlement、Input、Audio、Prep、Config、ADR、registry、technical preferences与systems index传播。静态复核通过：两份YAML parse、246个entity name唯一、`git diff --check`、25 HPM/5 RUP/13 RRD/7 RCO/12 RCC、7 profile/94 node/34 state rows及stable ID/order；byte arithmetic为204-byte create、220-byte mailbox row、484-byte mailbox、64-byte MPSC header、96-byte MPSC row、6208-byte MPSC total、76-byte page view与72-byte page command，current-contract stale ABI扫描为0。generated manifests、Hash256/codec/migration golden、Godot/GDUnit4、真实process-kill、Android/iOS accessibility/gamepad、性能、音频与经济/玩家证据均未执行；`battle_ready=false`。下一步必须在fresh context执行第八次full re-review。

---

## Re-review — 2026-09-07 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: sixth fresh-context full re-review
Specialists: game/economy/systems、persistence/engine/QA、UX/accessibility/audio + fresh independent creative-director synthesis
Prior fifth-round blocker closure: 3 CLOSED (static only) / 4 PARTIAL
Creative Director verdict: **MAJOR REVISION NEEDED**
Root blocking groups: 7

### 第六轮7组根 blocker

1. terminal reward/profile commit与reservation RESOLVE仍是两个Save事实；worker mailbox没有完整typed terminal payload，create前identity与result enum也未封闭，reducer/audio无法可靠区分CONSUMED与RELEASED。
2. pre-active refresh先推进权威RNG而durable history只记成功；失败重试会分叉，且升级后恢复没有旧config artifact的保留上界与发布约束。
3. Player Fantasy宣称Victory净库存优势，但现有证明只覆盖random gross grant rate，未计服丹成本、NONE、胜率、局长与999上限饱和。
4. 六个action-bearing screen只有snapshot capacity，没有逐状态semantic node composition；Settings角色不够，CONTROLLED_FAULT presenter owner悬空。
5. arbitrary native thread直接汇入SPSC与single producer矛盾；上游容量/arrival order/sequence owner未定义，mapped gamepad支持又与Input“raw gamepad无movement”措辞冲突。
6. process-kill AC只引用抽象写入阶段，没有可枚举的实际cut-point manifest与逐operation expected old/new/uncertain/heal oracle。
7. Save/Config/technical preferences/ADR/registry/systems-index残留V1/V2、HPM22/24、旧SPSC、resolution256、cancel与`NO_GRANT`等当前合同漂移。

### 第六轮作者整改（用户于2026-09-07回复“继续”）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | MVP terminal冻结为唯一`ReservationUpdateRequestV2(RESOLVE)+1112-byte ResolveReservationPayloadV3`同槽transaction；新增160-byte `TerminalRunResultV2`、完整typed mailbox、176-byte create correlation/result封闭枚举与terminal invariant validator | codec、writer、kill/reconcile runtime待证 |
| 2 | RNG/SkillDraft冻结唯一`PreActiveRngWindowLeaseV1` scratch window：durable readback后才commit权威cursor，FAILED discard，UNCERTAIN reconcile；Config新增append-only旧artifact retention，32 artifacts/16 MiB上限，突破须migration | replay/hash/migration golden待生成 |
| 3 | 产品承诺收窄为Victory random gross grant-rate优势；net flow独立覆盖服丹/NONE、胜率、局长与饱和，不再把gross证明写成净库存保证 | balance simulation与玩家验证待执行 |
| 4 | ADR新增ASN01..07逐状态node profile与ADJUSTABLE/SWITCH/COMBOBOX角色；Settlement detail固定6-row分页，CONTROLLED_FAULT由persistent GameRoot presenter拥有 | native plugin、TalkBack/VoiceOver与真机trace待证 |
| 5 | native入口冻结为MPSC64 arrival ticket→唯一serial sequence allocator→SPSC32；六行Meta UI keyboard/mapped-gamepad只产typed UI command，raw axis与movement carrier写入为0 | platform concurrency/gamepad exported-build证据待证 |
| 6 | 新增12-stage×7-operation=`84`行`ReservationCrashCutManifestV1`，覆盖old/new/uncertain/heal，process-kill AC只接受实际展开fixture | crash harness与平台barrier证据待执行 |
| 7 | 当前合同统一到V3 terminal、264-byte resolution、25-row HPM、396-byte typed Save mailbox、七node profile、六行Meta UI Input、封闭terminal/result enum；清除current `NO_GRANT`与cancel漂移 | generated canonical artifacts仍OPEN |

### 当前状态

**In Review / Re-review Pending**。本轮仅是第六次独立verdict后的作者静态整改，不构成第七次独立通过。静态复核通过：两份YAML parse、243个entity name唯一、`git diff --check`、25-row hash preimage、5-row reservation payload、13-row reconcile、12-row crash stage与7个node profile；byte arithmetic复算为176-byte create request、144-byte create result、136-byte update result、160-byte terminal result、1112-byte RESOLVE payload、176-byte mailbox row与396-byte mailbox。generated manifests、Hash256/codec/migration golden、Godot/GDUnit4、真实process-kill、Android/iOS accessibility/gamepad、性能、音频与经济/玩家证据均未执行；`battle_ready=false`。下一步必须在fresh context执行第七次full re-review。

---

## Re-review — 2026-09-07 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: fifth fresh-context full re-review
Specialists: systems/persistence、UX/UI/QA/accessibility + fresh independent creative-director synthesis
Prior fourth-round blocker closure: 0 CLOSED / 6 PARTIAL
Creative Director verdict: **MAJOR REVISION NEEDED**
Root blocking groups: 7

### 第五轮7组根 blocker

1. pre-active cancel/offer PONR仍非total：guard enum缺值，玩家cancel在首份snapshot前不可达，LFD25却可能在offer已经可见后release。
2. 跨进程replay仍混入process-local generation，且`candidate_id`没有确定性生成规则。
3. Save result V1/V2口径冲突；initial reservation没有receipt result，terminal resolution要求Save写入时另分配receipt而形成循环，reservation NOT_FOUND会永久锁死。
4. hash manifest未覆盖128-byte direct-NONE、120-byte receipt与无障碍snapshot前像。
5. Config同时宣称56/72/5与54/70/3，canonical count不唯一。
6. held room与lifetime room相等时`cap_disposition`没有total结果。
7. 六个无障碍screen没有固定row capacity；NATIVE_ANY多producer与SPSC冲突，i32 index会wrap，gamepad支持声明互相矛盾。

### 第五轮作者整改（用户于2026-09-07回复“授权”）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | 删除玩家pre-durable cancel event/guard/action；readback前interactive snapshot/action=0；LFD25只接受明确`NOT_STARTED_CLEAR`，write possible/durable/visible统一LFD26 | kill/fault runtime matrix待证 |
| 2 | `pre_active_semantic_generation=1`与runtime generation分离；candidate ID固定由offer revision与slot checked计算 | deterministic replay golden待生成 |
| 3 | 统一V2 result；新增120-byte `ReservationReceiptV1`与`ReservationCreateResultV2`，receipt ID=request ID；13-row reconcile新增严格`PROVEN_ABSENT`安全清理 | 双槽/temp/平台writer crash harness待证 |
| 4 | Save HPM扩为24行，补direct-NONE与receipt；ADR新增独立6-row `AccessibilityHashPreimageManifestV1` | cross-platform Hash256 golden待生成 |
| 5 | canonical current counts统一为54 guard / 72 action / 5 app-render | generated Config artifact待生成 |
| 6 | 新增`PARTIAL_BOTH=6`并冻结total precedence | economy boundary simulation待证 |
| 7 | 六屏capacity固定16/16/12/24/24/12；mailbox改2476-byte i64 sequence与单一serial producer；mapped gamepad focus/activation正式支持 | Android/iOS、gamepad与真机trace待证 |

### 当前状态

**In Review / Re-review Pending**。本轮是第五次独立verdict后的作者整改，不构成第六次独立通过。静态检查通过：两份YAML parse、237个entity name唯一、`git diff --check`、54-row guard、72-row action、5-row app render、24-row hash preimage、5-row reservation payload、13-row reconcile；算术复算为120-byte receipt、248-byte accessibility row、76-byte action、2476-byte mailbox，以及六屏snapshot 4076/4076/3084/6060/6060/3084 bytes与对应hash offset。generated artifacts、Hash256/codec/migration golden、Godot/GDUnit4、kill/crash、真机无障碍、gamepad、性能、音频和经济/体验测试仍未执行。`battle_ready=false`；下一步必须在fresh context执行第六次full re-review。

---

## Re-review — 2026-09-07 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: full / clean context
Specialists: game/economy、systems/persistence/Godot/performance、UX/UI/QA/audio/accessibility + fresh independent creative-director synthesis
Prior third-round blocker closure: 1 CLOSED / 2–6 PARTIAL
Creative Director verdict: **MAJOR REVISION NEEDED**
Root blocking groups: 6

### 第四轮6组根 blocker

1. SkillDraft把process-local snapshot/bank/generation身份混入跨进程offer/loadout恢复语义，缺稳定durable semantic carrier。
2. Prep/Zhangtian声明`PRE_ACTIVE_CANCEL_AND_RELEASE`，但GameRoot没有对应event、guard与transition。
3. reservation update/terminal resolution/audio result只有控制头，缺实际mutation payload、revision与可恢复receipt ID。
4. `HashPreimageManifestV1`仍是规则 prose，没有actual row/tag/length/offset/nested策略，且未覆盖新增update/resolution schema。
5. Outcome seed、Settlement requested/applied、starter与direct-NONE存在多个真相；unlock/claim合法组合和无丹重开文案未闭合。
6. mobile accessibility的adapter pump state与semantic row ABI不一致：PRE_ACTIVE_CHOICE不可操作，row缺bounds与动态本地化参数。

Systems specialist提出“Boss 120-tick arrival lock令tick43200 Victory不可达”；creative-director核对Boss GDD后不采为blocker，因为arrival lock只禁Boss动作，玩家攻击/死亡判定仍可发生。`survival_ticks==43200 && boss_spawned==0`作为recommended schedule guard已传播，避免恢复/重复tick补发。

### 第四轮作者整改（用户于2026-09-07回复“授权”）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | 新增252-byte `PreActiveOfferSemanticV1`与296-byte `PreActiveLoadoutSemanticV1`；durable hash排除process-local ID并在新进程按content key rebind | cross-process codec/replay runtime待证 |
| 2 | GameRoot新增`PRE_ACTIVE_CANCEL_REQUESTED`、`PRE_ACTIVE_CANCEL_ALLOWED`、G25 T/F、transition与TA71/72；仅首个offer durable/visible前可release | Save/UI kill matrix待证 |
| 3 | `ReservationUpdateRequestV2`内联5类canonical payload；V2 results返回revision/unlock/receipt；terminal写含nonzero receipt ID的264-byte resolution并清live carrier | generated codec/crash harness待证 |
| 4 | Save签发22-row actual `HashPreimageManifestV1`，逐行冻结tag、length/formula、zero range与nested rule | cross-platform Hash256 golden待生成 |
| 5 | Outcome seed只封存random gross；Settlement 64-byte applied row唯一承载starter/cap/applied；flag只允许0/0或1/1；direct-NONE升级128-byte V2，CTA/读屏明确“不服丹，再次挑战” | economy simulation/UX/device待证 |
| 6 | ADR/registry升级`AccessibleScreenSnapshotV2`：248-byte row含layout generation、bounds、visible/clipped与8 typed args；六个action-bearing TopState、all-state drain及5-row render workload闭合 | Android/iOS plugin、tree与真机trace待证 |

### 当前状态

**In Review / Re-review Pending**。本轮是第四次独立verdict后的作者整改，不构成第五次独立通过。静态检查已通过：YAML parse、`git diff --check`、56-row guard、72-row action、5-row app render、22-row hash preimage、5-row reservation payload、12-row reconcile；算术复算为264-byte resolution、64-byte applied reward、248-byte accessibility row、76-byte action、2468-byte mailbox、42180-byte slot payload与42392-byte encoded max。generated artifacts、Hash256/codec/migration golden、Godot/GDUnit4、kill/crash、真机无障碍、性能、音频和经济/体验测试仍未执行。`battle_ready=false`；下一步必须在fresh context执行第五次full re-review。

---

## Re-review — 2026-09-04 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: full / clean context
Specialists: game/economy、systems/persistence、QA/UX/engine + independent creative-director synthesis
Prior 11 blocker closure: 5 CLOSED / 6 PARTIAL
Creative Director verdict: **MAJOR REVISION NEEDED**
Root blocking groups: 6

### 第三轮6组根 blocker

1. 经济总函数不完整：Victory tick下界/零分母、consume与grant顺序、终身int64耗尽未定义。
2. 聚气pre-active首个offer可通过取消/release获得fresh seed无限重抽。
3. 跨进程恢复持久化process-local `config_snapshot_id`，不能稳定rebind相同配置内容。
4. reservation后续update/reconcile/retire ABI缺generation/checkpoint/hash CAS与终态清理。
5. hash/wire/capacity manifest仍不可直接生成，且LFD 28/30、SkillDraft RNG 15/20存在传播漂移。
6. app-scope direct-NONE、durable audio identity、mobile accessibility adapter lifecycle与render-frame workload不完整。

### 第三轮作者整改（用户于2026-09-04回复“授权”）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | Victory域43200..108000；速率oracle改checked交叉乘法；normal Settlement先consume再按post-consume held/lifetime room发奖 | 经济模拟/玩家试玩待证 |
| 2 | 首个offer durable/visible成为取消PONR；之后Back/关闭/重启只恢复同一页，release重抽为WRONG_STATE | kill/UI runtime待证 |
| 3 | durable key改为`config_content_revision+config_content_hash`；process-local snapshot ID不落盘；candidate/recovery升级132/360 bytes | config artifact留存与跨进程golden待证 |
| 4 | Save新增ReservationUpdate request/result、generation/checkpoint/hash CAS、12-row reconcile V2、256-byte terminal resolution与terminal clear | codec/crash harness待证 |
| 5 | hash mode显式区分SELF_ZERO_FIELD/EXTERNAL_PAYLOAD；payload/reservation改660/1088 bytes；SkillDraft registry修正1..20；LFD subphase/workload签发 | generated artifacts/runtime checked-sum待证 |
| 6 | Home/Settlement嵌入124-byte direct-NONE slice；Save签发124-byte durable audio stamp；无障碍bridge单列app-adapter row、capacity32 native SPSC与3-row render workload | Godot/Android/iOS/audio/device证据待证 |

### 当前状态

**In Review / Re-review Pending**。这是被评文档作者上下文中的授权整改，不是新的独立通过。静态校验覆盖YAML parse、diff whitespace、旧口径搜索、132/360/660/1088/256/2024/42156/42368字节算术与关键manifest计数；尚未生成codec/hash/capacity artifacts，也未运行Godot/GDUnit4、进程强杀、真机无障碍、性能、音频或经济/体验测试。`battle_ready=false`；必须在fresh context再次执行full review。

---

## Re-review — 2026-09-03 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL
Depth: full / clean context
Specialists: systems/QA、product/UX、Godot/performance + clean-context creative-director synthesis
Prior verdict resolved: No — 上轮9组中仅ledger/cap与RNG/Damage消费2组完整闭合，7组仍不完整
Creative Director verdict: **MAJOR REVISION NEEDED**
Blocking groups: 11

### Clean-context 11组 blocker

1. Settlement将survival record/input上限写成43,200，与Boss恰在43,200入场冲突；seed/min blanket invariant缺Victory时长域与starter cohort排除。
2. 276-byte recovery只有offer/loadout hash，不能恢复actual selected skill，也没有完整确定性重建协议。
3. 顶层`SaveStorePayloadV1.prep_commit_journal`与reservation nested journal形成两个持久真相源。
4. Hash/schema/capacity manifest不可生成：`DomainRecordV1.domain_hash`字段不存在、漏journal hash、candidate/slice schema不完整、SlotPayloadMax漏top-level字段。
5. Home边界与Settlement again仍残留“零库存进Prep”。
6. GameRoot在PREP/HOME/SETTLEMENT不运行Save mailbox reducer，worker结果可能永久无人排空。
7. `AppServiceTopologyManifestV1`只有口号没有actual 5 rows，且全禁Node与AUDIO_APP预建player需求冲突。
8. app audio缺`SAVE_DURABLE_STAMP`事件/producer/identity，以及stamp/unlock顺序、超时、重复、kill、mute的total handling。
9. checkpoint1被同时描述为memory-only与可持久化；seed candidate durable缺独立LoadInjectionPoint和PONR/UNCERTAIN rows。
10. Android TalkBack/iOS VoiceOver未选择原生桥或缩减MVP范围。
11. 主概念仍有“首次通关”残文、首次Victory同类数量错误，且BossStateMachine/Progression Tree未列为显式依赖。

### 第二轮方案A作者整改（用户于2026-09-03授权）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | survival合法域0..108,000；Victory随机candidate×3、Boss线Defeat×1，starter单独cohort；边界保证0.10>1/12 seed/min | 经济模拟/试玩待证 |
| 2 | recovery扩为336 bytes，持久offer revision、refresh、selected candidate、session/rule/config/loadout revision，并冻结SkillDraft deterministic replay | codec/kill/runtime待证 |
| 3 | 删除SaveStorePayload顶层journal；仅`DurableReservationV1.prep_commit_journal`为真相源 | slot scan/runtime待证 |
| 4 | 修正`payload_hash`、补journal hash；签发100-byte candidate、52-byte recipe view、244-byte slice、636-byte payload、1064-byte reservation；SlotPayloadMax枚举全部top-level字段 | generated golden/checked-sum待证 |
| 5 | Home安装/未解锁边界和Settlement again按available分流；零库存用origin-specific direct NONE、Prep页面0 | UX/E2E待证 |
| 6 | 新增all-TopState每render frame一次`app_service_result_pump`，与state control/lifecycle pump分层 | mailbox/runtime测试待证 |
| 7 | GameRoot签发actual 5-row topology；AUDIO_APP唯一允许持有预建app-scope AudioStreamPlayer，所有服务禁battle对象 | Godot teardown/perf待证 |
| 8 | 音频改为唯一`SAVE_DURABLE_STAMP`，unlock只作payload bit；固定coalesce preimage与total disposition，无异步join/timeout | asset/mix/device待证 |
| 9 | journal改为七个全部durable checkpoint；补`SEED_CANDIDATE_DURABLE=15`与LFD29/30 encode/write/readback覆盖 | crash matrix待证 |
| 10 | 新增Accepted ADR-0001，冻结immutable semantic tree→Android/iOS adapter→typed action；注册接口/禁用模式 | 插件/能力握手/真机待证 |
| 11 | 主概念改为首次正常Victory/Defeat与正确叠加数量；显式加入BossStateMachine、Progression Tree依赖 | 两依赖自身full review待完成 |

### 当前状态

**In Review / Re-review Pending**。本轮是被评文档作者上下文中的整改，不构成独立通过。静态复算已覆盖336/100/52/244/636/1064-byte结构、42156-byte payload、42368-byte encoded maximum（低于65536-byte slot硬上限）、30-row load、54-row guard、5-row app-service topology、YAML与diff whitespace；Settlement direct NONE另有独立surface identity，避免复用HOME generation。`battle_ready=false`；下一步必须在新的clean context再次执行full review。

---

## Review — 2026-09-03 — Verdict: MAJOR REVISION NEEDED

Scope signal: XL（经济、持久化恢复、跨系统ABI、UX/无障碍、音频与线程拓扑跨文档收口）  
Depth: full  
Specialists: game/economy/systems/UX/QA/performance/Godot/technical specialist reports + creative-director综合  
Prior verdict source: 仓库中此前无本GDD正式review log；本轮按目标GDD、session state与依赖文档重建前序设计事实，不能算已有独立通过。  
Creative Director verdict: **MAJOR REVISION NEEDED**  
Blocking groups: 9

### 9组根 blocker

1. seed ledger把999同时写成库存cap与终身earned/consumed cap，和守恒式矛盾。
2. 4分钟Defeat可形成高于Victory的seed/min farm，且“稳定供给”承诺与无pity随机来源不一致。
3. Prep journal、checkpoint与slot transaction边界不一致；battle identity没有durable allocator。
4. Loading seed candidate与`PRE_ACTIVE_CHOICE`缺跨进程恢复，callback loss/restart可能重抽或重选。
5. wire schema/hash tag/capacity未闭合；`RunStartRecoveryV1`不完整，`ReservationMax/SlotMax`未签发。
6. RNG canonical index与Zhangtian stable IDs冲突；Damage没有正式明心丹typed consumer。
7. 无种子仍要求额外Prep点击，CTA语义误导，恢复动作/focus/radio/移动端读屏架构不完整。
8. app-scope service与Save worker/main-thread拓扑不完整。
9. app-scope音频以presentation generation参与去重、producer重叠、unlock/Save stamp未合并且AC编号重复。

### 方案A作者整改（用户于2026-09-03授权）

| Blocker | 作者级修订 | 当前边界 |
|---|---|---|
| 1 | cap改为`available+reserved<=999`；earned/consumed为checked lifetime int64，继续满足守恒 | 静态合同完成；codec/golden待证 |
| 2 | `PROVISIONAL-ECONOMY-V3`：Victory candidate×2，Boss线Defeat×1，首次正常结算三类starter各1；文案改为胜利偏置可积累随机储备 | 需经济模拟与目标玩家试玩 |
| 3 | Save持久allocator同事务分配`battle_instance_id=reservation_id`；Zhangtian分配preparation ID；八checkpoint唯一枚举 | crash harness/runtime待证 |
| 4 | 固定276-byte `RunStartRecoveryV1`覆盖candidate、RNG range、pre-active offer/choice/loadout/cursor/next sequence | 跨进程实现与kill matrix待证 |
| 5 | `SHA256_V1` preimage manifest；576-byte Zhangtian payload、1004-byte reservation、65,536-byte slot与262,144-byte disk peak minimum | generated codec/hash/capacity checked-sum待证 |
| 6 | RNG index固定`NINGQI_GRASS/TIELING_FLOWER/LEIYUAN_FRUIT`；Damage新增`DamagePreparationInputV1`及AC-DM29 | runtime integration待证 |
| 7 | 有种子进Prep、无种子Home direct NONE；补`PrepActionCommandV1`、真实玩家文案与focus/reading规则；移动读屏明确architecture blocker | UX prototype、TalkBack/VoiceOver ADR/真机待证 |
| 8 | GameRoot新增五行`AppServiceTopologyManifestV1`；Save固定main→worker→SPSC mailbox→唯一reducer | Godot/platform线程与durability待证 |
| 9 | `AppAudioSemanticEventV2`移除presentation generation去重依赖，固定唯一producer/semantic key；unlock与Save stamp按operation coalesce；AC重编号 | asset/mix/device/runtime待证 |

### 传播范围

`zhangtian-bottle.md`、`save-system.md`、`game-root-scene-flow.md`、`prep-ui.md`、`home-ui.md`、`settlement-system.md`、`config-data-system.md`、`rng-system.md`、`skill-draft-system.md`、`damage-system.md`、`audio-feedback.md`、主MVP概念、technical preferences、registry、systems-index与session state。

### 当前状态

**In Review / Re-review Pending**。方案A只完成作者上下文中的跨文档整改与静态一致性校验；尚无clean-context独立verdict，未执行Godot/GDUnit4、进程强杀、真机、性能、移动端读屏、音频资产或经济/体验验证。`battle_ready=false`，不得称Approved、implementation-ready或runtime verified。

---
