# Zhangtian Bottle — Design Review Log

> 本文件记录 `design/gdd/zhangtian-bottle.md` 的独立 full review 与作者整改，不把静态修订记作复审通过。

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
