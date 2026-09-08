# SaveSystem（本地存档与崩溃恢复）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-08 — Zhangtian第七次独立full review后作者整改传播；runtime evidence仍OPEN
> **Implements Pillar**: 诚实、可恢复、exact-once 的“战斗—结算—成长—再开局”连续性
> **Scope**: MVP 本地存档、终局 commit/discard、开局 reservation、崩溃恢复、schema/损坏处理与 resolved-run 归档；不含云同步、账号、跨设备、反作弊或战斗中途续局

## 1. Overview

SaveSystem 是应用级唯一 durable persistence owner。它把已验证的永久档案 after-image、sealed `RunOutcomeEnvelopeV1`、`RunCompletionStatusV1`、开局 reservation 与 GameRoot archive journal 写入本地双槽快照，并提供可幂等重试的 commit、reconcile、discard、reservation recovery 与 archive readback。

SaveSystem 不拥有战斗事实、奖励算法、功法树规则、掌天瓶配方、UI 状态或 GameRoot 的 `SaveCommitAttemptV1` reducer。它只回答“哪个持久化事实已经成立”，不能因 callback 超时把未知写成失败，也不能把未 durable 的奖励显示为到账。

MVP 为本地单玩家、单进程写入、无服务端。跨进程恢复是本 GDD 的核心范围；战斗中途存档明确不做，应用异常退出后不得恢复半局战斗。

## 2. Player Fantasy

玩家不需要理解 journal、generation 或 checksum。正常情况下，结算保存快速、安静且只发生一次；异常情况下，界面清楚区分“未开始”“正在保存”“结果待确认”“失败”“已保存”“正在放弃”“已放弃”。

玩家永远不会看到未落盘奖励被宣称到账，也不会因一次 callback 丢失而重复获得奖励。若本地档案损坏或版本过新，系统保留原文件并诚实阻止覆盖，提供恢复/导出诊断路径，而不是静默创建空档。

## 3. Detailed Design

### 3.1 Owner、驱动与非目标

- SaveSystem 是 app-scope service，不是 GameRoot 七 phase participant；四类 gameplay contribution 均为0，不在 `_physics_process` 中执行 I/O。
- 唯一写入入口是串行 `SaveDurableExecutor`；应用级 `durable_write_in_flight <= 1`，GameRoot 仍额外保证 pending outcome commit 总数 `<=1`。
- GameRoot 拥有 runtime `SaveCommitAttemptV1` 与唯一 callback reducer；SaveSystem按操作返回封闭的`SaveOperationResultV2`、`ProfileDomainMutationResultV2`、`ReservationCreateResultV3`、`ReservationUpdateResultV2`或`TerminalRunResultV2`，不得以旧create/V1/V2别名混读。MVP run terminal只返回`TerminalRunResultV2`；reservation create/resolve的receipt统一使用下述`ReservationReceiptV1`，其他operation只使用其自身已版本化result与stamp合同。
- Settlement/Progression/Zhangtian 各自拥有业务规则与 domain codec；SaveSystem 验证注册 schema、hash、revision 与 after-image，但不解释 payload 内部字段。
- 不序列化 Node、Resource 实例 ID、Callable、RID、对象引用、整个 runtime snapshot 或临时 presentation 状态。
- MVP 不支持云同步、跨设备合并、多 profile、热回滚、战斗中途续局、用户手工编辑兼容、加密或反作弊。hash 用于一致性/损坏检测，不构成可信防篡改。

### 3.2 Canonical durable store

固定两个完整槽：`user://save/profile_a.sav` 与 `user://save/profile_b.sav`。无独立 current-pointer；启动时扫描两个槽并选最高合法 `store_generation`。每槽结构为：

```text
SaveSlotV1={
  magic:u64, format_version:i32=1, header_size:i32,
  store_generation:i64, profile_revision:i64,
  next_identity:i64, resolved_outcome_floor:i64,
  payload_length:i64, payload_hash:Hash256,
  header_hash:Hash256,
  payload:SaveStorePayloadV1,
  footer:SaveCommitFooterV1
}

SaveCommitFooterV1={
  magic:u64, format_version:i32=1,
  store_generation:i64, payload_length:i64,
  payload_hash:Hash256, slot_hash:Hash256
}

SaveStorePayloadV1={
  schema_version:i32=1,
  profile:PersistentProfileEnvelopeV1,
  terminal_identity_reservation:TerminalIdentityReservationV1?,
  pending_outcome:PendingOutcomeRecoveryV1?,
  pending_profile_mutation:DurableProfileMutationRecoveryV1?,
  latest_resolution:DurableRunResolutionV2?,
  pending_reservation:DurableReservationV2?,
  active_entry_fact:ActiveEntryFactV1?,
  resolved_archive:ResolvedArchiveStoreV1,
  archive_retire_journal:ArchiveRetireJournalV1?,
  diagnostics:SaveRecoveryDiagnosticV1?
}

DurableRunResolutionV2={
  schema_version:i32=2,resolution_kind:i32,
  reservation_id:i64,battle_instance_id:i64,preparation_id:i64,
  operation_id:i64,request_id:i64,attempt_generation:i64,
  resolved_profile_revision:i64,resolved_domain_revision:i64,
  checkpoint_id:i32,active_entry_present_before:i32,
  outcome_present:i32,terminal_state:i32,
  base_reservation_hash:Hash256,final_reservation_hash:Hash256,
  next_domain_hash:Hash256,durable_receipt_id:i64,receipt_hash:Hash256,
  archive_entry_id:i64,resolution_hash:Hash256
}

SaveRecoveryDiagnosticRowV1={diagnostic_id:i64,source_id:i32,
  result_code:i32,operation_id:i64,request_id:i64,reservation_id:i64,
  store_generation:i64,arg0:i64,arg1:i64}

SaveRecoveryDiagnosticV1={schema_version:i32=1,row_count:i32,
  rows:SaveRecoveryDiagnosticRowV1[31],diagnostic_hash:Hash256}
```

`ReservationResolutionKindV1={CONSUMED=1,RELEASED=2}`，`ReservationTerminalStateV1={CONSUMED=1,RELEASED=2}`；两字段必须逐位表达同一终态。`checkpoint_id`只允许1..7；`active_entry_present_before=1`蕴含checkpoint7，checkpoint1..6必须为0，checkpoint7+marker0作为显式corrupt/reconcile fixture保留给RRD10。`outcome_present`只允许0/1；CONSUMED仅接受checkpoint7+marker1的normal Outcome、ABANDONED/discard或marker-orphan证据，RELEASED仅接受checkpoint1..6+marker0的LFD25 clear failure或sealed TECHNICAL_COMPENSATION。`final_reservation_hash`固定取写入terminal resolution前最后一个1152-byte `DurableReservationV2.reservation_hash`，清除live carrier后不得改写；`archive_entry_id=0`直到后续archive transaction分配并由RETIRE关联，非零值只允许来自matching durable archive row。任何枚举、presence或跨字段关系不合法均在manifest匹配前`CORRUPT`。

`DurableRunResolutionV2`固定264 bytes，是reservation终态的有界durable tombstone；`durable_receipt_id`固定逐位等于同一terminal request的非零`request_id`，`receipt_hash`按下述120-byte receipt deterministic重建。terminal request因此能在写前构造完整resolution，不等待Save另分配ID；duplicate/restart也只从durable request/result字段重建同一receipt。V1 resolution不得按V2读取，只有显式V1→V2 migration及逐byte golden存在时才可升级；当前作者基线无已发布V1产品存档。`SaveRecoveryDiagnosticRowV1`固定64 bytes，diagnostic store最多31行、固定最大2024 bytes，按diagnostic_id升序保留最近行。unknown/duplicate/out-of-order或hash不等均拒绝，不以诊断恢复业务事实。

跨进程 recovery carrier 固定为：

```text
TerminalIdentityReservationV1={
  schema_version:i32=1, battle_instance_id:i64,
  outcome_commit_id:i64, reservation_generation:i64, state:i32
}

PendingOutcomeRecoveryV1={
  schema_version:i32=1, outcome_commit_id:i64,
  outcome_bytes_length:i64, outcome_bytes:u8[], outcome_hash:i64,
  completion_bytes_length:i64, completion_bytes:u8[], completion_hash:i64,
  save_attempt:SaveCommitAttemptV1,
  mutation_bundle_hash:Hash256,
  proposed_profile:PersistentProfileEnvelopeV1?,
  terminal_request:ReservationUpdateRequestV2?,
  recovery_generation:i64
}
```

第八轮容量校正：`ReservationUpdateRequestV2`最大长度为`164+1252=1416` bytes；P=1160/1160/1252/1112/44按五行payload manifest逐kind选择，旧1352上限不得生成artifact。

Save 在终局先 durable reserve `outcome_commit_id`，GameRoot 才能按同一 ID 原子绑定三类 runtime backing；reserve 成功但尚未 seal 时崩溃只消耗 ID，不构造 Outcome。Envelope seal 后、允许离开当前进程前，必须把 canonical Outcome/Completion、初始 attempt 与后续可重试所需的完整 proposed after-image durable stage 到 `pending_outcome` 并 readback。每次 reservation update 前先由Save对当前权威槽签发只读`ReservationUpdateIdentityLeaseV1`；caller只携带其中的candidate identity，真正的attempt/request分配与next recovery仍在目标slot transaction同槽提交，不存在“为分配request ID再发送一个含request ID的request”。tombstone identity同样是lease candidate并在RESOLVE transaction内正式消费。重启发现 unresolved row 时恢复同一 commit/attempt identity并投影为 `SAVE_UNCERTAIN` 或 `DISCARD_PENDING`，不得创建第二份奖励计划。

整数使用 canonical little-endian；字符串为 UTF-8 length-prefix；浮点若由 domain codec 允许，必须 finite、`-0.0` 归一为 `+0.0`、NaN/Infinity 拒绝。数组按 schema 顺序编码，禁止 `Dictionary` 遍历顺序或 `store_var()` 成为 wire ABI。所有 length/count 在分配前做非负、上限与 checked arithmetic 校验。

`Hash256` algorithm ID固定为`SHA256_V1`；Godot 4.7.1实现路径与cross-platform golden仍归 Save codec ADR。包含自身hash字段的对象使用`SELF_ZERO_FIELD`：`SHA256(tag || canonical bytes with that hash field=ZERO)`；外部payload使用`EXTERNAL_PAYLOAD`：`SHA256(tag || payload_bytes)`且zero range为空。64-bit字段取Hash256低64位时按little-endian无符号解释并逐位装入int64。禁止把 Godot `hash()`、资源路径 hash 或未定义自引用 hash 当作槽损坏校验。

`HashPreimageManifestV1={row_id,stable_order,schema_id,tag_ascii_with_nul,hash_mode,exact_length_or_formula,zero_offset,zero_length,nested_rule,owner}`的Zhangtian/Prep/Save actual rows固定如下；offset从canonical object byte 0起算，`NONE`表示没有zero range：

| row | schema / tag | mode | length | zero offset/len | nested rule |
|---|---|---|---:|---|---|
| `HPM01` | `HerbConfigV1\0` | SELF | 232 | 200/32 | recipe rows inline |
| `HPM02` | `ZhangtianProjectionRulesV1\0` | SELF | 72 | 40/32 | none |
| `HPM03` | `ZhangtianPreparationSliceV1\0` | SELF | 244 | 212/32 | three recipe views inline |
| `HPM04` | `PrepPresentationBundleV1\0` | SELF | 520 | 488/32 | attempt/geometry inline |
| `HPM05` | `PrepareRunRequestV1\0` | SELF | 180 | 148/32 | config/bundle hashes foreign repeated |
| `HPM06` | `RunStartRecoveryV1\0` | SELF | 360 | 328/32 | semantic offer/loadout hashes foreign repeated |
| `HPM07` | `PrepCommitJournalV1\0` | SELF | 60 | 28/32 | none |
| `HPM08` | `DurableReservationV2\0` | SELF | 1152 | 1120/32 | payload/domain/journal inline；64-byte external create correlation durable |
| `HPM09` | `ZhangtianBattleProjectionV1\0` | SELF | 112 | 80/32 | none |
| `HPM10` | `ZhangtianSeedCandidateV1\0` | SELF | 132 | 100/32 | none |
| `HPM11` | `ActiveEntryFactV1\0` | SELF | 92 | 60/32 | none |
| `HPM12` | `ZhangtianProfileDomainV1\0` | EXTERNAL | 132 | NONE/0 | payload bytes only, no DomainRecord wrapper |
| `HPM13` | `PreActiveOfferSemanticV1\0` | SELF | 252 | 220/32 | three fixed candidate semantic rows inline |
| `HPM14` | `PreActiveLoadoutSemanticV1\0` | SELF | 296 | 264/32 | four active plus four aux rows inline, zero tail canonical |
| `HPM15` | `ReservationUpdateRequestV2\0` | SELF | `164+P` | `132+P`/32 | payload `P` inline; payload_hash foreign repeated |
| `HPM16` | `AdvanceHandoffPayloadV1\0` | EXTERNAL | 1160 | NONE/0 | payload bytes only |
| `HPM17` | `UpdateRecoveryPayloadV1\0` | EXTERNAL | 1160 | NONE/0 | payload bytes only |
| `HPM18` | `MarkActivePayloadV1\0` | EXTERNAL | 1252 | NONE/0 | payload bytes only |
| `HPM19` | `ResolveReservationPayloadV3\0` | EXTERNAL | 1112 | NONE/0 | terminal outcome/disposition fields + profile + resolution inline |
| `HPM20` | `RetireReservationPayloadV1\0` | EXTERNAL | 44 | NONE/0 | payload bytes only |
| `HPM21` | `DurableRunResolutionV2\0` | SELF | 264 | 232/32 | hashes foreign repeated |
| `HPM22` | `SaveDurableStampFactV1\0` | SELF | 124 | 92/32 | receipt hash foreign repeated |
| `HPM23` | `DirectNoneStartSliceV2\0` | SELF | 128 | 96/32 | confirmed bundle fields inline |
| `HPM24` | `ReservationReceiptV1\0` | SELF | 120 | 88/32 | reservation hash foreign repeated |
| `HPM25` | `ReservationCreateRequestV2\0` | SELF | 176 | 144/32 | config/bundle hashes foreign repeated；最终identity尚未分配 |

`SELF`是表格短写，导出值必须是`SELF_ZERO_FIELD`。`P`只允许1160/1160/1252/1112/44并由`ReservationUpdatePayloadManifestV1`按update kind唯一决定；最大值1252，因此`ReservationUpdateRequestV2`最大1416 bytes。任何tag缺末尾NUL、长度/offset不等、row缺失/重复、nested策略不等或给EXTERNAL行提供zero range都在首字节写入前`INVALID_MANIFEST`。以上25条feature/carrier rows已经是设计输入；生成artifact与cross-platform golden尚未执行，继续标`BLOCKED-HASH-CODEC-EVIDENCE`。

Save核心介质hash由独立actual `SaveGlobalCodecHashManifestV1={row_id,stable_order,schema_id,tag_ascii_with_nul,hash_mode,exact_length_or_formula,zero_offset_or_formula,zero_length,nested_rule}`唯一签发，禁止再引用不存在的“既有global manifest”：

| row | schema / tag | mode | length | zero range | nested rule |
|---|---|---|---|---|---|
| `SGH01` | `SaveSlotHeaderV1\0` | SELF_ZERO_FIELD | 120 | header_hash字段offset/32由schema生成器断言 | primitive header fields only |
| `SGH02` | `SaveStorePayloadV1\0` | EXTERNAL_PAYLOAD | `4+8 presence tags+sum(present canonical fields)`，最大42244 | NONE/0 | optional字段按schema order，absent bytes为0 |
| `SGH03` | `SaveSlotV1\0` | EXTERNAL_PAYLOAD | `120+P+92`，最大42456 | NONE/0 | canonical header + payload + footer(slot_hash置零) |
| `SGH04` | `PersistentProfileEnvelopeV1\0` | SELF_ZERO_FIELD | `16+sum(56+domain_payload_length)+32`，作者上限776 | final32/32 | domain ID ASC，nested domain payload hash foreign repeated |
| `SGH05` | `ResolvedRunArchiveV1\0` | SELF_ZERO_FIELD | 72 | final32/32 | no runtime pointer/locale data |
| `SGH06` | `ResolvedArchivePrefixV1\0` | EXTERNAL_PAYLOAD | `32+72` | NONE/0 | `old_prefix_hash || evicted canonical archive row` |

Config admission必须逐行重算SGH01..06的tag、公式、zero range与nested rule；slot hash以`SHA256("SaveSlotV1\0"||canonical header||payload||footer-with-slot-hash-zero)`作为SGH03唯一规则，header hash由SGH01对header bytes（header_hash字段置零）计算，footer duplicate length/generation必须先逐位验证。缺行、range未展开、schema offset改变或expected bytes由被测codec自填均`INVALID_MANIFEST`。

第八轮 schema 约束：所有 `final_reservation_hash`、receipt 与 journal 字段均从 `DurableReservationV2` 读取；历史 `DurableReservationV1` 仅作迁移审计文本，不构成当前可读 schema。

### 3.3 Domain envelope 与永久档案

```text
PersistentProfileEnvelopeV1={
  schema_version:i32=1, profile_revision:i64,
  domain_count:i32, domains:DomainRecordV1[],
  profile_content_hash:Hash256
}

DomainRecordV1={
  domain_id:i32, domain_schema_version:i32,
  content_revision:i64, payload_length:i64,
  payload_hash:Hash256, payload_bytes:u8[]
}
```

- `domain_id` 唯一、升序、来自 `PersistentDomainManifestV1`；未知必需 domain、重复、乱序、unknown schema 或 hash 不匹配均拒绝 load/commit。
- SaveSystem 对 payload 是 schema-aware opaque carrier：只允许已注册 domain codec 完成 decode→validate→canonical re-encode 逐位相等后入档；不得直接保存任意 blob。
- 功法树、掌天瓶、货币/记录、音频与可访问性设置的 actual domain schema 归各 owner。本批次已给出四个V1作者候选：Progression 176 bytes、Zhangtian 132 bytes、Settlement 136 bytes、Settings 60 bytes；actual codec、migration golden与runtime readback仍为 `BLOCKED-PERSISTENT-DOMAIN-CODEC`，不得由Save补默认字段。
- 每次终局 commit 提交一个完整、不可变的 `PersistentProfileEnvelopeV1` after-image，并带 `expected_profile_revision`。SaveSystem 不按 Outcome 猜奖励，也不做增量 patch 合并。

终局请求固定为：

```text
SaveCommitRequestV1={
  schema_version:i32=1, operation_kind:i32,
  outcome_commit_id:i64, attempt_generation:i64, request_id:i64,
  expected_profile_revision:i64,
  outcome_content_hash:i64, completion_content_hash:i64,
  mutation_bundle_hash:Hash256,
  next_profile:PersistentProfileEnvelopeV1
}
```

`mutation_bundle_hash` 绑定 Settlement 冻结的 `SettlementMutationBundleV1` typed mutation/after-image证据；`next_profile.profile_revision=expected_profile_revision+1`。`SaveCommitRequestV1`只保留给没有matching reservation的未来/迁移操作；MVP每局即使选择NONE也必有typed reservation，因此run-terminal对该入口的合法调用数固定为0。MVP唯一外部终局写入是下述`ReservationUpdateRequestV2(update_kind=RESOLVE)`及其`ResolveReservationPayloadV3`，不得先COMMIT再RESOLVE或反向执行第二次介质写。六行reward、三行record与三domain after-image作者映射已签发；codec、generated manifest与runtime integration仍BLOCKED，但不改变Save的原子介质合同。

### 3.4 两槽 commit protocol

启动扫描将槽分类为 `ABSENT | VALID | INVALID | FORWARD_INCOMPATIBLE`。只有完整通过 magic/version/size/header hash/footer duplicate/payload hash/slot hash/canonical decode/domain validation 的槽才是 `VALID`。

正式槽永不原地truncate；每个目标都先写同目录 `profile_{slot}.tmp`。残留temp不是正式槽事实，启动可隔离/删除但不得据此判EMPTY_INIT或durable resolution。写入步骤固定：

1. 在 executor 内重新扫描两槽；若当前选择结果与 request 的 base revision 不匹配，返回失败或既有 durable fact，绝不覆盖。
2. 构造完整 next slot bytes；所有 identity、generation、length、hash 与容量先在内存中 checked reserve。
3. `target_slot = next_store_generation mod 2`；向其temp依次写header、payload、footer，每次 Godot 4.7.1 `FileAccess.store_*` bool均检查。
4. temp执行文件durable barrier、close、reopen全量readback；随后 atomic replace 到正式target并执行父目录metadata durable barrier，再reopen完整验证。此点是该generation首份durable PONR。
5. 用相同generation与逐位相同bytes，经独立temp流程镜像到另一正式槽并再次readback。
6. 只有A/B均为同generation同bytes后才返回`COMMIT_SUCCEEDED/TOMBSTONE_SUCCEEDED`；首份已VALID而镜像未完成只能返回UNCERTAIN/保持DISCARD_PENDING，重启先选高generation并heal mirror，再reconcile既有事实。

PONR前且能证明正式槽未出现新VALID fact才可返回FAILED；PONR后、barrier结果未知或镜像失败只能UNCERTAIN。首次初始化同样走temp→atomic replace→双镜像，因此中断只留下ABSENT正式槽或完整VALID槽，不会由半写正式文件把首次安装永久锁死。平台file/dir barrier与atomic replace语义是implementation前硬gate。

### 3.5 选择公式、identity 与容量

#### F1 — Current slot selection

```text
V = { s | classify(s) = VALID }
current = argmax_s∈V (store_generation(s), slot_id_preference(s))
slot_id_preference(A)=1, slot_id_preference(B)=0
```

`LatestResolutionMax=264`必须由上述`DurableRunResolutionV2`逐字段exact重算；`DiagnosticsMax=2024`必须由`8+31*64+32`重算。`ProfileMutationMax=392`由增加`attempt_generation/request_id`后的324-byte最大request、两枚Hash256与state i32逐项重算；因此`SlotPayloadMax=42244`、`SlotEncodedMax=42456`。generator必须逐项校验，不得依赖65,536-byte总slot余量掩盖单项漂移。

第八轮容量覆盖：`ReservationMax=1152`、`SlotPayloadMax=42244`、`SlotEncodedMax=42456`为当前唯一实现上限；任何旧42180/42392口径均为历史记录，不得生成artifact。

| Variable | Type | Range / rule |
|---|---|---|
| `V` | set | 0..2 VALID slots |
| `store_generation` | int64 | 1..INT64_MAX, checked monotonic |
| `slot_id_preference` | int32 | A=1, B=0，仅相同 bytes 的平局诊断使用 |

两个 VALID 槽 generation 相同且 canonical bytes 不同不是可仲裁平局，必须进入 `STORE_CONFLICT`；相同 bytes 可稳定选 A。

#### F2 — Next generation and profile revision

```text
next_store_generation = checked_add(current.store_generation, 1)
next_profile_revision = checked_add(expected_profile_revision, 1)
```

| Variable | Type | Range / rule |
|---|---|---|
| `current.store_generation` | int64 | EMPTY_INIT 时视为0，否则1..INT64_MAX |
| `expected_profile_revision` | int64 | 0..INT64_MAX |
| `next_*` | int64 | checked result；溢出则0 bytes written |

#### F3 — Durable precedence

```text
resolution(commit_id) = lookup(current.pending/latest_resolution,
                               retained_archive,
                               resolved_outcome_floor)
```

| Variable | Type | Range / rule |
|---|---|---|
| `commit_id` | int64 | 1..INT64_MAX，Save 持久化 allocator 永不复用 |
| resolution | enum | NONE / COMMITTED / DISCARDED |
| durable source | enum | current resolution / retained row / resolved floor |

双槽会覆盖早期generation，因此不回看“不再存在的最早槽”。单executor在每次物理写前重扫current resolution；首个通过PONR的COMMITTED或DISCARDED成为唯一事实。retained archive提供原receipt/tombstone；已淘汰且`commit_id<=resolved_outcome_floor`的请求只能拒绝，不能重放after-image。当前可验证记录若出现相反resolution，进入`STORE_CONFLICT`。

#### F4 — Bounded archive capacity

```text
archive_count <= 64
evict_count = max(0, archive_count + append_count - 64)
```

| Variable | Type | Range / rule |
|---|---|---|
| `archive_count` | int32 | 0..64 |
| `append_count` | int32 | 0 or 1；同 operation 重试为0 |
| `evict_count` | int32 | 0 or 1 |

内部schema固定：

```text
ResolvedArchiveStoreV1={
  schema_version:i32=1, capacity:i32=64, count:i32,
  next_archive_sequence:i64,
  archive_prefix_hash:Hash256,
  resolved_operation_floor:i64, resolved_outcome_floor:i64,
  rows:ResolvedRunArchiveV1[64]
}
```

rows按`archive_sequence ASC`占用`[0,count)`。淘汰最旧row前执行`archive_prefix_hash'=H("ArchivePrefixV1" || old_prefix || evicted canonical row)`并推进两个floor；再左移逻辑序列、追加`archive_sequence=next_archive_sequence`并checked+1。容量64是`PROVISIONAL-PRODUCT`诊断/连续性基线，不是玩家战绩容量；若产品要求淘汰后仍返回原receipt/tombstone，floor不足，必须改为更大或无界exact index并做新schema决策。

#### F5 — Canonical byte capacities

```text
OutcomeBytes = 156 + 16*(K+S+D+W+C) + 12*R
PendingOutcomeDerived = 945 + OutcomeBytes
ProfileMutationDerived = 392
KnownDomainRecordsMax = (56+176) + (56+132) + (56+136) + (56+60) = 728
ArchiveRowsBytes = 64 * 72 = 4608
SaveStorePayloadFixed = 4
OptionalPresenceBytes = 8
SlotPayloadMax = SaveStorePayloadFixed + OptionalPresenceBytes
               + CurrentProfileMax
               + TerminalIdentityReservationMax
               + PendingOutcomeMax
               + ProfileMutationMax
               + LatestResolutionMax
               + ReservationMax
               + ActiveEntryFactMax
               + ResolvedArchiveStoreMax
               + ArchiveRetireJournalMax
               + DiagnosticsMax
SlotEncodedMax = SlotHeaderMax + SlotPayloadMax + SlotFooterMax
DiskPeakMin = 3 * SlotMax + FileSystemSafetyMargin

SlotHeaderMax = 120
SlotFooterMax = 92
CurrentProfileMax = NextProfileMax = 776
TerminalIdentityReservationMax = 32
PendingOutcomeMax = 32768
ProfileMutationMax = 392
LatestResolutionMax = 264
ReservationMax = 1152
ActiveEntryFactMax = 92
ResolvedArchiveStoreMax = 4684
ArchiveRetireJournalMax = 48
DiagnosticsMax = 2024
SlotPayloadMax = 42244
SlotEncodedMax = 42456
SlotMax = 65536
FileSystemSafetyMargin = 65536
DiskPeakMin = 262144
```

`SaveCapacityManifestV1`必须恰含上式每个named maximum一行，schema=`{field_id,stable_order,max_bytes,derivation_id,source_schema_id}`；generator逐项重算`PendingOutcomeDerived<=32768`、`ProfileMutationDerived=392`及所有fixed schema bytes，并按当前`ReservationMax=1152`重算`SlotPayloadMax=42244`与`SlotEncodedMax=42456<=65536`。所有derived值均由字段级 checked arithmetic 生成，不得使用旧总量或隐含余量。缺行、重复、实际encoder长度超过field cap、derived不等、top-level字段未映射或仅依赖总slot余量均为`INVALID_MANIFEST/CAPACITY_EXCEEDED`。

| Variable | Type | Range / rule |
|---|---|---|
| `K/S/D/W/C/R` | int32 | Config actual Outcome row capacities；checked，不能统一代1536 |
| `20/64/72/48` | bytes | Completion/SaveAttempt/ResolvedArchive row/RetireJournal canonical no-padding bytes |
| top-level maxima | int64 | 上式逐项覆盖`SaveStorePayloadV1`全部字段；8个optional各占1-byte presence tag，required resolved archive单列，不得遗漏后再靠slot余量兜底 |
| `ProfileMutationMax` | int64 | 同时最多1条pending通用domain mutation；以registered最大domain record与evidence checked sum |
| `KnownDomainRecordsMax` | int64 | 四个已设计domain的canonical `DomainRecordV1`上界之和728；56为wrapper固定字段，仍不含profile envelope、pending与诊断 |
| owner maxima | int64 | 各domain manifest签发后checked sum |
| `ReservationMax` | int64 | 1152 bytes；V2 exact canonical wrapper，不是估算 |
| `SlotMax` | int64 | 65,536 bytes；完整header+payload+footer的V1产品硬上限 |
| `FileSystemSafetyMargin` | int64 | 65,536 bytes；低空间预检保留，不替代真实写入检查 |

峰值按两个正式槽加一个同尺寸temp与固定margin计算。任一checked owner maximum之和或实际canonical编码超过65,536 bytes时，在分配/写入前以`CAPACITY_EXCEEDED`失败；不得截断、压缩后偷偷接受或扩大V1。低空间预检只允许提前失败，不能替代每次write/barrier/replace/readback检查。

第八轮容量覆盖：`SaveCapacityManifestV1` generator必须以`ReservationMax=1152`、`SlotPayloadMax=42244`、`SlotEncodedMax=42456`重算；旧42180/42392仅为历史审计文本，不能进入当前artifact或codec。

### 3.6 Commit、discard 与 reconcile

SaveSystem的非reservation legacy/migration入口才遵循GameRoot旧`SaveOperationResultV2`九个 durable result code，MVP调用数0。MVP run terminal固定使用`ReservationResultCodeV1 + TerminalRunResultV2`，每个fresh-live result逐位返回terminal operation/disposition、profile/domain revision、unlock transition、reservation hash及durable receipt ID/hash，不能只给控制头：

- `COMMIT`：先查同 commit durable resolution。已 COMMITTED 以public `RECONCILE_FOUND`返回逐byte原receipt；已 DISCARDED 返回`WRONG_STATE`且0 mutation；NONE 才校验 base revision、Outcome/Completion hash、mutation bundle 与 next profile，并写 `COMMITTED` after-image。
- `DISCARD`：先查 resolution。已 COMMITTED以`terminal_operation_kind=OUTCOME_COMMIT,result_code=RECONCILE_FOUND`返回同一receipt，写tombstone数0；已DISCARDED以`OUTCOME_DISCARD+RECONCILE_FOUND`返回同一receipt+tombstone；NONE时，若存在matching unresolved reservation，request必须同时携带owner签发的mandatory consume after-image并在同一槽transaction写`DISCARDED+CONSUMED`，否则拒绝。这里“discard不保存奖励/纪录”不等于“撤销已获得的丹药成本”；无reservation的discard才保持profile业务数据逐位不变。
- `RECONCILE`：只扫描 durable store；terminal fact found统一返回相应terminal operation的`RECONCILE_FOUND`及原receipt/tombstone，未找到但证据不完整返回`RECONCILE_NOT_FOUND_UNPROVEN`。既有reservation update另可按`ReservationUpdateReconcileProofV1`返回`RECONCILE_FOUND_OLD`。不得根据runtime carrier、callback cache或目标槽残片推断。
- duplicate request `{operation_kind,commit_id,generation,request_id}` 返回原 durable result；相同 identity 不同 bytes/hash 为 `CONFLICT`，不写。
- callback 丢失只影响可见 carrier，不撤销 durable fact；晚到/重复 callback 由 GameRoot matching reducer `OK_NOOP`。

`next_identity`表示下一未用值，EMPTY_INIT固定为1。分配公式为`allocated_id=current.next_identity; next_identity'=checked_add(current.next_identity,1)`；0保留为不存在。`battle_instance_id(=reservation_id)`、`discard_tombstone_id`、`request_id`、`operation_id`、`outcome_commit_id`均走此allocator，identity reserve必须随对应durable recovery row在同一槽提交；receipt不再单独分配，固定复用并逐位等于其durable `request_id`。`battle_instance_id`必须在首次reservation transaction内与完整base recovery一起durable，GameRoot不得另有内存allocator。`outcome_commit_id`在Envelope seal前独立durable reserve。后续操作崩溃允许跳号，不允许复用。`attempt_generation`是同commit carrier内checked+1，不占用全局identity。

writer 在任何写入前必须持有进程级唯一 `SaveWriterLease`；同一进程由 singleton executor 保证，两个实例/进程竞争时只有取得平台排他锁者可写，另一方进入只读 `WRITER_BUSY`。固定`physical_write_in_flight=1`、`queued_operation_capacity=1`；逻辑timeout不取消仍在执行的物理写，后续reconcile/discard只能排队，并在真正写前重扫最高generation与同commit resolution。Godot 4.7.1 的可靠锁实现尚需 ADR/平台 spike，未闭合前 `BLOCKED-PLATFORM-DURABILITY`。

`SaveExecutorThreadingV3`固定线程拓扑：GameRoot主线程只做schema/identity/revision验证并把不可变canonical byte buffer移交给唯一worker；worker独占`FileAccess`、平台barrier/replace adapter与`HashingContext`，不得访问SceneTree、Node、Resource、Signal、共享可变`PackedByteArray`或业务owner。结果进入预分配容量2的SPSC `SaveExecutorResultMailboxV3`。每个220-byte `SaveExecutorResultRowV3={schema_version:i32=3,result_kind:i32,payload_length:i32,reserved_zero:i32,payload_bytes:u8[204]}`；`result_kind={SAVE_OPERATION=1,PROFILE_MUTATION=2,RESERVATION_CREATE=3,RESERVATION_UPDATE=4,TERMINAL_RUN=5}`，payload必须是对应canonical result，长度不得超过204，unused tail逐byte为0。mailbox header固定44 bytes：`{schema_version:i32=3,process_epoch:i64,executor_generation:i64,capacity:i32=2,read_sequence:i64,write_sequence:i64,overflowed:i32}`，总长484 bytes。这样完整204-byte create V3 result、136-byte update result、160-byte terminal result及其他V2 result均可原样传递，禁止只传控制头后再从共享状态补字段。GameRoot的`app_service_result_pump`在每个render frame、所有TopState中恰排空至多一次，并由唯一reducer验证epoch/generation/result kind、create source correlation、operation/attempt/request及payload schema后发布typed callback。PREP/HOME/SETTLEMENT不得因没有gameplay/control pump而停止Save结果推进。worker不得直接emit signal或回调UI。进程退出先关闭接纳、等待当前物理步骤到可恢复边界、持久状态仍以槽scan为准；平台线程/锁/barrier证据未闭合前保持`BLOCKED-PLATFORM-DURABILITY`。

### 3.6A 通用Profile domain mutation

Home中的Progression购买与未来Zhangtian操作不得伪造`outcome_commit_id`复用终局reducer。Save提供独立ABI：

```text
ProfileDomainMutationRequestV2={
  schema_version:i32=2,operation_id:i64,attempt_generation:i64,
  request_id:i64,domain_id:i32,
  expected_profile_revision:i64,expected_domain_revision:i64,
  mutation_kind:i32,business_operation_id:i64,request_hash:Hash256,
  next_domain_record:DomainRecordV1
}

ProfileDomainMutationResultV2={
  schema_version:i32=2,operation_id:i64,attempt_generation:i64,
  request_id:i64,domain_id:i32,business_operation_id:i64,result_code:i32,
  profile_revision:i64,domain_revision:i64,zhangtian_unlock_transition:i32,
  receipt_id:i64,receipt_hash:Hash256
}

SaveDurableStampFactV1={
  schema_version:i32=1,operation_kind:i32,operation_id:i64,
  attempt_generation:i64,request_id:i64,profile_revision:i64,
  zhangtian_domain_revision:i64,zhangtian_unlock_transition:i32,
  durable_receipt_id:i64,durable_receipt_hash:Hash256,fact_hash:Hash256
}
```

`result_code={SUCCEEDED=1,FAILED=2,UNCERTAIN=3,RECONCILE_FOUND=4,RECONCILE_NOT_FOUND=5,STALE_REVISION=6,CONFLICT=7}`仅属于`ProfileDomainMutationResultV2`，不得被reservation裸复用。每个fresh attempt使用checked非零`attempt_generation`与Save持久allocator分配的非零`request_id`；retry/reconcile保留operation并推进attempt/request，duplicate逐位返回原result。`zhangtian_unlock_transition`只允许0/1：非Zhangtian mutation恒0，Zhangtian mutation逐位来自同transaction合法before/after。Save只验证registered codec/canonical bytes与revision CAS，结构性替换唯一domain并推进profile revision；不解释购买/配方语义。`SaveDurableStampFactV1`固定124 bytes，仅在fresh-live完整profile commit双镜像readback成功后，由Save reducer从同一`ProfileDomainMutationResultV2`、非MVP的`SaveOperationResultV2`或MVP `TerminalRunResultV2`逐字段构造；`operation_kind={OUTCOME_COMMIT=1,PROFILE_MUTATION=2}`，transition只允许0/1并来自同transaction的Zhangtian before/after，`fact_hash`使用SELF_ZERO_FIELD。reconcile、boot scan与duplicate只返回既有receipt，不新建stamp；Audio不得从UI edge、domain revision或裸success bool猜stamp。

每个请求先以同一slot transaction保存`DurableProfileMutationRecoveryV1={request,base_domain_hash,next_domain_hash,state}`，再走temp+双镜像协议。PONR前可证明未写入才FAILED；PONR后/镜像失败为UNCERTAIN。应用级同时最多1个pending profile mutation；它与Outcome/Reservation共用single writer与queue。UNCERTAIN只允许同operation reconcile，FOUND返回原receipt，NOT_FOUND保持UNCERTAIN；不同请求同base revision只有第一个CAS成功，后者不得自动rebase。

### 3.7 开局 reservation

`DurableReservationV2` 保存 `reservation_id=battle_instance_id`、operation kind/state/generation/request/recovery identity、完整业务 domain after-image、64-byte外部create correlation、Zhangtian payload、run-start recovery与journal。任意时刻最多1条 unresolved reservation。V2 canonical wrapper固定1152 bytes；V1/旧660-byte payload不得按新schema读取：

首次创建的唯一外部请求固定为：

```text
ReservationCreateRequestV2={
  schema_version:i32=2,source_kind:i32,
  source_command_id:i64,source_press_id:i64,attempt_generation:i64=1,
  run_seed:i64,expected_profile_revision:i64,expected_domain_revision:i64,
  expected_config_content_revision:i64,expected_config_content_hash:Hash256,
  zhangtian_content_revision:i64,selected_seed_id:i32,selected_pill_id:i32,
  prep_bundle_hash:Hash256,request_hash:Hash256
}
```

该request固定176 bytes并在任何全局identity分配前由GameRoot/Zhangtian共同validate。首次create的pre-durable correlation固定为`{source_kind,source_command_id,source_press_id,attempt_generation=1,request_hash}`；相同correlation同bytes重复调用只能继续/返回同一durable事实，相同correlation不同bytes为`CONFLICT`。Save在同一首次slot transaction内分配`operation_id/request_id/battle_instance_id=reservation_id`，Zhangtian分配`preparation_id`并据此构造内部180-byte `PrepareRunRequestV1`；这些分配结果只由204-byte `ReservationCreateResultV3`返回，其中`operation_id`逐位等于durable `recovery_operation_id/journal.operation_id`。callback丢失或进程重启时caller重发逐位相同的176-byte create request，Save按pre-durable correlation扫描而不是要求caller猜测尚未返回的request ID；所有public create result都回显完整source correlation，找到durable reservation后另返回原allocated identities与receipt，完整absence proof成立才允许fresh create。禁止另造`ReservationCreateRequestV1`、任何pre-V3 create result或在内存先分配最终identity。

```text
DurableReservationV2={
  schema_version:i32=2,reservation_id:i64,battle_instance_id:i64,
  preparation_id:i64,operation_kind:i32,state:i32,
  attempt_generation:i64,request_id:i64,recovery_operation_id:i64,
  base_profile_revision:i64,reserved_profile_revision:i64,
  base_domain_hash:Hash256,reserved_domain_hash:Hash256,
  create_correlation_length:i64=64,create_correlation:ReservationCreateCorrelationV1,
  zhangtian_payload_length:i64=724,zhangtian_payload:u8[724],
  next_domain_record:DomainRecordV1,
  prep_commit_journal:PrepCommitJournalV1,
  reservation_hash:Hash256
}

PrepCommitJournalV1={
  schema_version:i32=1,reservation_id:i64,operation_id:i64,
  checkpoint_id:i32,state:i32,journal_hash:Hash256
}

ActiveEntryFactV1={
  schema_version:i32=1,reservation_id:i64,battle_instance_id:i64,
  run_start_hash:Hash256,active_entry_generation:i64,fact_hash:Hash256
}

ReservationReceiptV1={
  schema_version:i32=1,operation_kind:i32,
  reservation_id:i64,attempt_generation:i64,request_id:i64,
  checkpoint_id:i32,result_code:i32,
  profile_revision:i64,domain_revision:i64,
  reservation_hash:Hash256,receipt_hash:Hash256
}

ReservationResultCodeV1={SUCCEEDED=1,FAILED=2,UNCERTAIN=3,
  RECONCILE_FOUND=4,RECONCILE_NOT_FOUND_UNPROVEN=5,
  STALE_REVISION=6,CONFLICT=7,WRONG_STATE=8,
  INVALID_ARGUMENT=9,PROVEN_ABSENT=10,
  RECONCILE_FOUND_OLD=11,ID_EXHAUSTED=12}

ReservationTerminalDispositionV1={NOT_APPLICABLE=0,CONSUMED=1,RELEASED=2}

ReservationCreateResultV3={
  schema_version:i32=3,source_kind:i32,
  source_command_id:i64,source_press_id:i64,source_request_hash:Hash256,
  operation_id:i64,reservation_id:i64,battle_instance_id:i64,
  preparation_id:i64,attempt_generation:i64,request_id:i64,
  result_code:i32,checkpoint_id:i32,reservation_hash:Hash256,
  profile_revision:i64,domain_revision:i64,unlock_transition:i32,
  durable_receipt_id:i64,receipt_hash:Hash256
}

`ReservationCreateResultV3.attempt_generation`在CREATE结果中严格回显外部`source_attempt_generation`（当前fresh create为1）；allocated request identity由`request_id`表达，避免重复字段使204-byte result膨胀。Save内部 correlation、durable wrapper与public result必须逐位一致。

ReservationUpdateRequestV2={
  schema_version:i32=2,update_kind:i32,reservation_id:i64,
  expected_attempt_generation:i64,attempt_generation:i64,request_id:i64,
  recovery_operation_id:i64,expected_checkpoint_id:i32,next_checkpoint_id:i32,
  expected_reservation_hash:Hash256,payload_schema_id:i32,
  payload_length:i64,payload_hash:Hash256,payload_bytes:u8[],
  request_hash:Hash256
}

ReservationUpdateIdentityLeaseV1={schema_version:i32=1,reservation_id:i64,
  recovery_operation_id:i64,expected_attempt_generation:i64,
  candidate_request_id:i64,candidate_tombstone_id:i64,
  expected_reservation_hash:Hash256,lease_hash:Hash256}

ReservationUpdateResultV2={schema_version:i32=2,update_kind:i32,
  reservation_id:i64,attempt_generation:i64,request_id:i64,
  result_code:i32,checkpoint_id:i32,reservation_hash:Hash256,
  profile_revision:i64,domain_revision:i64,unlock_transition:i32,
  terminal_disposition:i32,durable_receipt_id:i64,receipt_hash:Hash256}

TerminalRunResultV2={schema_version:i32=2,terminal_operation_kind:i32,
  outcome_commit_id:i64,reservation_id:i64,battle_instance_id:i64,
  attempt_generation:i64,request_id:i64,result_code:i32,
  terminal_disposition:i32,checkpoint_id:i32,
  profile_revision:i64,domain_revision:i64,unlock_transition:i32,
  reservation_hash:Hash256,durable_receipt_id:i64,receipt_hash:Hash256,
  discard_tombstone_id:i64}

AdvanceHandoffPayloadV1={next_reservation_length:i64=1152,
  next_reservation_bytes:u8[1152]}
UpdateRecoveryPayloadV1={next_reservation_length:i64=1152,
  next_reservation_bytes:u8[1152]}
MarkActivePayloadV1={next_reservation_length:i64=1152,
  next_reservation_bytes:u8[1152],active_entry_fact:ActiveEntryFactV1}
ResolveReservationPayloadV3={terminal_operation_kind:i32,
  outcome_commit_id:i64,outcome_content_hash:i64,
  completion_content_hash:i64,mutation_bundle_hash:Hash256,
  next_profile_length:i64=776,next_profile_bytes:u8[776],
  resolution:DurableRunResolutionV2,clear_mask:i32}
RetireReservationPayloadV1={resolution_hash:Hash256,
  archive_entry_id:i64,clear_mask:i32}
```

`ReservationReceiptV1`固定120 bytes、little-endian/no-padding，`operation_kind={CREATE_RESERVATION=1,RESOLVE_RESERVATION=2}`。receipt内`result_code`是**durable fact code**，只允许`SUCCEEDED`；它不复制public delivery code。`receipt_hash=SHA256("ReservationReceiptV1\0" || canonical receipt with bytes88..119=ZERO)`。所有durable receipt固定`durable_receipt_id=request_id`且非零；receipt内`request_id`必须与ID逐位相等。CREATE receipt的checkpoint/hash逐位取双镜像readback后的`DurableReservationV2.prep_commit_journal.checkpoint_id/reservation_hash`；RESOLVE receipt取durable `SUCCEEDED`、resolution checkpoint与`DurableRunResolutionV2.final_reservation_hash`，profile/domain revision取同transaction next profile。初始CREATE双镜像readback成功后，Save从已持久reservation逐字段生成同一receipt，并由`ReservationCreateResultV3`返回。public result可为`SUCCEEDED`或`RECONCILE_FOUND`，但两者必须携带逐byte相同的原receipt；reconcile绝不改写receipt内的durable fact code。terminal RESOLVE要求caller提交的`DurableRunResolutionV2`已携带同一request ID与可预计算receipt hash，Save验证后在同一transaction写入。中间`ADVANCE_HANDOFF/UPDATE_RECOVERY/MARK_ACTIVE/RETIRE`不签发业务成功音receipt，result的`terminal_disposition=NOT_APPLICABLE,durable_receipt_id=0,receipt_hash=ZERO32`；`RESOLVE`不再返回普通update result，而返回固定160-byte `TerminalRunResultV2`。`TerminalOperationKindV1={OUTCOME_COMMIT=1,OUTCOME_DISCARD=2,PREACTIVE_RELEASE=3,TECHNICAL_COMPENSATION=4,ORPHAN_CONSUME=5}`；CONSUMED只允许1/2/5，RELEASED只允许3/4。FAILED/UNCERTAIN/WRONG_STATE/ID_EXHAUSTED同样规范receipt为0/ZERO32，reconcile found只恢复原receipt而不新签发。任一enum、presence、revision、checkpoint、reservation hash或self-hash不等为`CONFLICT`且首字节写入0。

结果presence固定：CREATE V3的所有结果都必须逐位回显`{source_kind,source_command_id,source_press_id,attempt_generation,source_request_hash}`。SUCCEEDED/RECONCILE_FOUND还必须返回`operation_id==DurableReservationV2.recovery_operation_id==PrepCommitJournalV1.operation_id`、全部allocated identity、checkpoint、reservation hash、revision与非零receipt；其他result code令operation/allocated/result payload字段为0/ZERO32，但64-byte durable create correlation保持非零且与原176-byte request逐位相等。`RECONCILE_FOUND_OLD`只属于既有reservation的update reconcile，不允许用于CREATE。非RESOLVE update的SUCCEEDED/RECONCILE_FOUND/RECONCILE_FOUND_OLD必须`terminal_disposition=NOT_APPLICABLE`且receipt为0/ZERO32；其中FOUND返回matching next reservation hash，FOUND_OLD返回matching expected-old reservation hash。RESOLVE的FOUND_OLD也返回`TerminalRunResultV2(result_code=RECONCILE_FOUND_OLD,terminal_disposition=NOT_APPLICABLE,durable_receipt_id=0,receipt_hash=ZERO32)`并保持旧reservation/载荷不变，caller仅可用同一identity lease重试；不得被reducer吞成OK_NOOP。terminal SUCCEEDED/RECONCILE_FOUND必须返回matching outcome/reservation identity、CONSUMED或RELEASED、checkpoint/hash/revision及非零receipt；OUTCOME_DISCARD可额外返回非零matching tombstone，其他operation tombstone为0。unknown result code或任一不适用字段非零均为invalid callback，不改变GameRoot carrier。

`ZhangtianReservationPayloadV2`固定724 bytes，内含112-byte battle projection、360-byte `RunStartRecoveryV1`、64-byte外部create correlation与32-byte内部prepare hash；wrapper不再重复保存recovery。`ReservationCreateCorrelationV1={schema_version:i32=1,source_kind:i32,source_command_id:i64,source_press_id:i64,source_attempt_generation:i64=1,create_request_hash:Hash256}`固定64 bytes，`create_request_hash`逐位等于外部176-byte request的hash。`PrepCommitJournalV1`固定60 bytes，`ActiveEntryFactV1`固定92 bytes。wrapper的`next_domain_record`必须为Zhangtian的188-byte record；任一length或内外重复identity/hash不等均在写前`CONFLICT`。`DurableReservationV2.prep_commit_journal`是唯一持久Prep journal；`SaveStorePayloadV1`不存在顶层副本，decode若发现旧/额外同名field必须按schema拒绝，不能比较后择一。

`RunStartRecoveryV1`固定360 bytes、little-endian、no-padding：`{schema_version:i32,reservation_id:i64,battle_instance_id:i64,run_seed:i64,preparation_id:i64,selected_seed_id:i32,selected_pill_id:i32,source_profile_revision:i64,source_domain_revision:i64,config_content_revision:i64,config_content_hash:Hash256,zhangtian_content_revision:i64,projection_hash:Hash256,prep_commit_operation_id:i64,handoff_checkpoint:i32,candidate_present:i32,candidate_seed_id:i32,rng_call_begin:i64,rng_call_end:i64,pre_active_choice_state:i32,pre_active_choice_request_id:i64,pre_active_offer_hash:Hash256,pre_active_choice_command_id:i64,pre_active_loadout_hash:Hash256,pre_active_skill_draft_rng_cursor:i64,next_level_request_sequence:i64,pre_active_offer_revision:i64,pre_active_refreshes_used:i32,pre_active_free_refreshes_remaining:i32,pre_active_selected_candidate_id:i64,pre_active_semantic_generation:i64,pre_active_draft_ordinal:i32,pre_active_required_rule_bits:i32,pre_active_reinforcement_miss_streak:i32,pre_active_committed_loadout_revision:i64,recovery_hash:Hash256}`。`pre_active_semantic_generation=1`是durable语义字段，不接收process-local session/bank/presentation generation。`PreActiveChoiceStateV1={NOT_STARTED=0,OFFER_DURABLE=1,CHOICE_DURABLE=2,SKIPPED=3}`；`prep_commit_operation_id`逐位等于wrapper `recovery_operation_id`。Save保证canonical携带与逐位readback；offer/candidate/loadout确定性重建与hash验证由SkillDraft/Zhangtian执行，禁止把hash当可逆数据。

`PrepCommitJournalV1.checkpoint_id`唯一枚举固定`RESERVATION_DURABLE=1,RUN_START_FROZEN=2,PREP_TOUCH_RETIRED=3,LOADING_COMMITTED=4,SEED_CANDIDATE_DURABLE=5,PRE_ACTIVE_CHOICE_DURABLE_OR_SKIPPED=6,ACTIVE_ENTRY_DURABLE=7`，只能单调前进。不存在memory-only checkpoint；首次reservation transaction原子提交domain after-image、battle/preparation allocator、base recovery与checkpoint1。之后callback丢失或重启继续同一nested journal，不重新分配。

`ReservationUpdateKindV1={ADVANCE_HANDOFF=1,UPDATE_RECOVERY=2,MARK_ACTIVE=3,RESOLVE=4,RETIRE=5}`。`ReservationUpdatePayloadManifestV1={row_id,stable_order,update_kind,payload_schema_id,exact_length,required_fields,forbidden_fields,clear_mask_rule}`的actual presence rows固定为：

| row | order / kind | schema / bytes | required canonical content | forbidden / clear rule |
|---|---|---|---|---|
| `RUP01` | `1 / ADVANCE_HANDOFF` | `AdvanceHandoffPayloadV1 / 1160` | next reservation length+bytes | active/profile/resolution/retire fields；clear NONE |
| `RUP02` | `2 / UPDATE_RECOVERY` | `UpdateRecoveryPayloadV1 / 1160` | next reservation length+bytes | active/profile/resolution/retire fields；clear NONE |
| `RUP03` | `3 / MARK_ACTIVE` | `MarkActivePayloadV1 / 1252` | next reservation + 92-byte active fact | profile/resolution/retire fields；clear NONE |
| `RUP04` | `4 / RESOLVE` | `ResolveReservationPayloadV3 / 1112` | terminal operation/outcome hashes + 776-byte next profile + 264-byte resolution | next-reservation/retire fields；clear exactly PENDING_RESERVATION|ACTIVE_ENTRY |
| `RUP05` | `5 / RETIRE` | `RetireReservationPayloadV1 / 44` | resolution hash + already-durable archive entry ID | next-reservation/active/profile/new-resolution fields；clear exactly LATEST_RESOLUTION |

其他schema/length、缺payload、跨kind字段、错误clear mask或out-of-band mutable bytes均为`INVALID_ARGUMENT`。`ReservationUpdateRequestV2`的fixed prefix为132 bytes，随后inline payload，再以末尾32-byte `request_hash`结束，故总长为`164+payload_length`且当前上限为1416 bytes（最大payload 1252）；旧1352仅为历史审计值。`payload_hash=SHA256(payload tag||payload_bytes)`，request self-hash覆盖prefix+payload并将末尾hash置零。

每次合法修改同一reservation都必须先持有matching `ReservationUpdateIdentityLeaseV1`，由Save在读取当前权威槽时以`{reservation_id,recovery_operation_id,expected_attempt_generation,expected_reservation_hash}`签发candidate request/tombstone ID；该lease不产生业务写入，且不可跨generation复用。真正update使用`attempt_generation=checked_add(old,1)`和lease中的candidate `request_id`，CAS同时匹配old generation、checkpoint与reservation hash，并在同一slot transaction消费lease、递增Save allocator、写入next recovery；Save只写payload携带的canonical bytes，不向业务owner回读或重算after-image。ADVANCE/UPDATE的next reservation必须逐字段验证旧identity、合法单调journal/recovery和payload hash；MARK_ACTIVE额外要求92-byte marker matching；RESOLVE要求完整terminal operation/outcome/completion/mutation binding、776-byte next profile、264-byte resolution、`clear_mask=PENDING_RESERVATION|ACTIVE_ENTRY`并在唯一同槽transaction写奖励或tombstone、终态、after-image并清live carrier；不得另调`SaveCommitRequestV1`。RETIRE只在matching resolution已经被同hash的durable archive entry吸收后接受，`clear_mask=LATEST_RESOLUTION`且不改profile/archive bytes。相同`{reservation_id,attempt_generation,request_id}`同payload逐位返回原typed result；RESOLVE返回`TerminalRunResultV2`，其他kind返回`ReservationUpdateResultV2`。同update identity异payload为`CONFLICT`。checkpoint不得倒退或跳过；同checkpoint只允许`UPDATE_RECOVERY`推进其内部offer revision且必须匹配old recovery hash。

`ReservationUpdateReconcileProofV1={schema_version:i32=1,reservation_id:i64,attempt_generation:i64,request_id:i64,expected_old_reservation_hash:Hash256,requested_next_reservation_hash:Hash256,selected_formal_reservation_hash:Hash256,temp_status:i32,writer_quiescent:i32,result_code:i32}`是进程内typed scan结果。对已有reservation的update reconcile，只有三种非错误结论：selected formal hash等于requested next且matching update identity/payload时返回`RECONCILE_FOUND`；selected formal hash等于expected old、两正式槽与temp均证明requested update未形成更高或同代正式事实且writer quiescent时返回`RECONCILE_FOUND_OLD`；任一证据不完整返回`RECONCILE_NOT_FOUND_UNPROVEN`。`RECONCILE_FOUND_OLD`不是全reservation absence，不清volatile reservation correlation、不回fresh Prep，只允许discard该次scratch/request并从同一old reservation继续。result必须逐位回传被选择的formal reservation hash；caller先与old/next hash比较，再决定discard/commit，禁止把裸FOUND解释为总是next。

- PREP reserve 将开局资源扣除/锁定 after-image 与 `RESERVED` 事实放在同一槽 transaction；未 durable 不得进入 Loading。
- Zhangtian从持久`next_preparation_id`分配preparation identity并在同一after-image checked+1；NONE只保持count不变，仍推进domain/profile revision和allocator。
- 首次开放Active gameplay前必须把matching `ActiveEntryFactV1` durable/readback；marker存在而无sealed Outcome的跨进程恢复固定CONSUME，marker不存在的retryable load failure才允许RELEASE。
- `CONSUMED` 由 sealed Outcome 的matching `ReservationDisposition.CONSUME`、ABANDONED/discard的mandatory consume，或`ActiveEntryFactV1`存在且无sealed Outcome的boot recovery exact-once推进；三者必须先查同reservation既有durable resolution，首个合法事实获胜。
- `RELEASED` 与 `TECHNICAL_COMPENSATION` 由 owner 提供完整 profile after-image，Save 原子提交；Save 不自行计算补偿。
- `UNCERTAIN` 仅靠 durable scan/reconcile 恢复；未 resolved 时关闭新局入口。
- 主动 `ABANDONED` 不补偿：零奖励tombstone与mandatory consume after-image同槽提交；用户discard普通结果也不得撤销matching reservation成本。`TECHNICAL_ABORT` 仅接受 sealed disposition 与 fault-before-fact owner bundle。

`ReservationAbsenceProofV1={schema_version:i32=1,writer_quiescent:i32,slot_a_status:i32,slot_a_generation:i64,slot_a_payload_hash:Hash256,slot_b_status:i32,slot_b_generation:i64,slot_b_payload_hash:Hash256,temp_status:i32,selected_generation:i64,pending_reservation_present:i32,active_marker_present:i32,latest_resolution_present:i32}`是进程内scan result，不持久化也不自hash。只有唯一writer已quiescent、A/B正式槽均完整通过header/payload/footer/hash验证、按generation选择出的权威快照与另一正式槽的最新已知语义都证明不存在matching pending reservation/marker/resolution、temp明确ABSENT或完整验证后不高于selected generation，且三个presence位全为0时，Save才签发`PROVEN_ABSENT`；任一槽损坏/未来版/冲突、temp可能更新、writer busy或generation/hash无法闭合都只能是`NOT_FOUND_UNPROVEN`。proof只允许清GameRoot的matching volatile correlation，不写档案、不回收或复用旧identity。

`ReservationReconcileDispositionManifestV2`只在前置invariant validator通过后按stable order执行首个matching row，schema=`{row_id,stable_order,scan_status,marker_present,outcome_class,checkpoint_range,config_content_status,target,write_kind,new_run_count}`。前置validator固定要求：RESERVED时`checkpoint∈1..7`；checkpoint1..6必须`marker_present=0`，checkpoint7允许`marker_present=0|1`，其中0只进入RRD10 corrupt、1才允许Outcome/Active恢复；CONSUMED/RELEASED时live marker必须0；terminal resolution的kind/state/presence满足§3.2封闭矩阵；任一矛盾直接`CORRUPT`。scan只有通过上述proof validator才可取`PROVEN_ABSENT`；actual rows固定为：

| row | scan | marker | outcome | checkpoint/config | target / write |
|---|---|---:|---|---|---|
| RRD01 | CONFLICT | * | * | * | STORE_CONFLICT / NONE |
| RRD02 | FUTURE | * | * | * | UPDATE_REQUIRED / NONE |
| RRD03 | CORRUPT | * | * | * | CORRUPT_BLOCKED / NONE |
| RRD04 | NOT_FOUND_UNPROVEN | * | * | * | UNCERTAIN / NONE |
| RRD05 | RELEASED | 0 | NONE | * | FRESH_PREP / NONE |
| RRD06 | CONSUMED | 0 | ANY_OR_NONE | * | RESOLVED_DESTINATION / NONE |
| RRD07 | RESERVED | 1 | NORMAL_OR_ABANDONED | 7/* | CONSUMED / RESOLVE_CONSUME |
| RRD08 | RESERVED | 0 | TECHNICAL_COMPENSATION | 1..6/* | RELEASED / RESOLVE_RELEASE |
| RRD09 | RESERVED | 1 | NONE | 7/* | CONSUMED / ORPHAN_CONSUME |
| RRD10 | RESERVED | 0 | NONE | 7/* | CORRUPT_BLOCKED / NONE |
| RRD11 | RESERVED | 0 | NONE | 1..6/EXACT_AVAILABLE | CONTINUE_SAME_HANDOFF / NONE |
| RRD12 | RESERVED | 0 | NONE | 1..6/UNAVAILABLE_OR_MISMATCH | UPDATE_REQUIRED / NONE |
| RRD13 | PROVEN_ABSENT | 0 | NONE | * | FRESH_PREP_CLEAR_VOLATILE / NONE |

`*`是该row在前置invariant已通过后显式不参与判定的字段，不是缺省分支。13行全部`new_run_count=0`；RRD05或RRD13完成后也只能启用fresh Prep，必须等待玩家新的press才可创建新局。RRD13只在上述proof逐字段有效时清matching volatile correlation；RRD04永久保持UNCERTAIN且不可借UI重试降级。RESOLVE/ORPHAN事务必须通过`ResolveReservationPayloadV3`原子写`latest_resolution=DurableRunResolutionV2`、应用owner after-image、清除`pending_reservation`与`active_entry_fact`；archive只保留resolution/archive row，不保留live marker。duplicate从latest resolution返回逐位相同的`durable_receipt_id+receipt_hash`，terminal reservation不得复活。

`ReservationCrashOperationManifestV2={operation_id,stable_order,request_schema,result_kind,old_profile_presence,new_profile_presence,old_reservation_presence,new_reservation_presence,old_marker_presence,new_marker_presence,old_resolution_presence,new_resolution_presence,success_receipt_policy,success_tombstone_policy}`固定十一个物理operation的业务真值：

| op | request / result | profile old→new | reservation old→new | marker old→new | resolution old→new | success receipt / tombstone |
|---|---|---|---|---|---|---|
| `RCO01 CREATE` | CreateV2 / CreateResultV3 | 1→1 MUTATE | 0→1 | 0→0 | 0→0 | NONZERO / 0 |
| `RCO02 ADVANCE_HANDOFF` | UpdateV2 / UpdateResultV2 | 1→1 SAME | 1→1 MUTATE | 0→0 | 0→0 | 0 / 0 |
| `RCO03 UPDATE_RECOVERY` | UpdateV2 / UpdateResultV2 | 1→1 SAME | 1→1 MUTATE | 0→0 | 0→0 | 0 / 0 |
| `RCO04 MARK_ACTIVE` | UpdateV2 / UpdateResultV2 | 1→1 SAME | 1→1 MUTATE | 0→1 | 0→0 | 0 / 0 |
| `RCO05 RESOLVE_OUTCOME_COMMIT` | UpdateV2 / TerminalRunResultV2 | 1→1 MUTATE | 1→0 | 1→0 | 0→1 | NONZERO / 0 |
| `RCO06 RESOLVE_OUTCOME_DISCARD` | UpdateV2 / TerminalRunResultV2 | 1→1 MUTATE | 1→0 | 1→0 | 0→1 | NONZERO / NONZERO |
| `RCO07 RESOLVE_PREACTIVE_RELEASE` | UpdateV2 / TerminalRunResultV2 | 1→1 MUTATE | 1→0 | 0→0 | 0→1 | NONZERO / 0 |
| `RCO08 RESOLVE_TECHNICAL_COMPENSATION` | UpdateV2 / TerminalRunResultV2 | 1→1 MUTATE | 1→0 | 0→0 | 0→1 | NONZERO / 0 |
| `RCO09 RESOLVE_ORPHAN_CONSUME` | UpdateV2 / TerminalRunResultV2 | 1→1 MUTATE | 1→0 | 1→0 | 0→1 | NONZERO / 0 |
| `RCO10 RETIRE` | UpdateV2 / UpdateResultV2 | 1→1 SAME | 0→0 | 0→0 | 1→0 | 0 / 0 |
| `RCO11 PROFILE_DOMAIN_MUTATION` | ProfileMutationV2 / ProfileMutationResultV2 | 1→1 MUTATE | N/A→N/A | N/A→N/A | N/A→N/A | owner result / 0 |

`ReservationCrashCutManifestV2={row_id,stable_order,cut_stage,initial_callback_code,selected_fact_set,old_reconcile_code,new_reconcile_code,temp_disposition,heal_required}`固定12个stage rows。每个generated fixture由`RCC stage × RCO operation`逐字段笛卡尔展开；presence、result schema、receipt/tombstone只允许从RCO行取得，selected fact与public/reconcile code只允许从RCC行取得，不得由generator或被测codec补默认：

| stage | cut stage | initial callback | selected fact set | if OLD / if NEW | temp / heal |
|---|---|---|---|---|---|
| RCC01 | request validate前 | FAILED | OLD | FAILED / INVALID | NONE / NONE |
| RCC02 | recovery/identity同槽stage前 | FAILED | OLD | FAILED / INVALID | NONE / NONE |
| RCC03 | target temp header中 | FAILED | OLD | FAILED / INVALID | DISCARD | NONE |
| RCC04 | target temp payload中 | FAILED | OLD | FAILED / INVALID | DISCARD | NONE |
| RCC05 | target temp footer后、file barrier前 | FAILED | OLD | FAILED / INVALID | DISCARD | NONE |
| RCC06 | file barrier后、formal replace前 | FAILED | OLD | FAILED / INVALID | DISCARD | NONE |
| RCC07 | formal replace后、directory barrier前 | UNCERTAIN | OLD_OR_NEW | FOUND_OLD / FOUND | RESCAN | SELECTED_NEW_ONLY |
| RCC08 | directory barrier后、formal readback前 | UNCERTAIN | OLD_OR_NEW | FOUND_OLD / FOUND | RESCAN | SELECTED_NEW_ONLY |
| RCC09 | 首个formal VALID readback后 | UNCERTAIN | NEW | INVALID / FOUND | DISCARD | MIRROR |
| RCC10 | mirror temp任一步 | UNCERTAIN | NEW | INVALID / FOUND | DISCARD_OR_RESCAN | MIRROR |
| RCC11 | 双formal同generation同bytes后、callback前 | UNCERTAIN | NEW | INVALID / FOUND | NONE | NONE |
| RCC12 | success callback发布完成后 | SUCCEEDED | NEW | INVALID / DUPLICATE_SAME_RESULT | NONE | NONE |

`INVALID`表示该selected fact不属于该stage的合法fixture而非public code。FOUND_OLD映射reservation update为`RECONCILE_FOUND_OLD`、CREATE为`PROVEN_ABSENT`、PROFILE_DOMAIN_MUTATION为其typed NOT_FOUND proof；FOUND映射对应result的typed `RECONCILE_FOUND`。每条132-row artifact固定输入old/new slot bytes与hash、temp状态、writer状态、operation/request identity、预期selected generation，以及由RCO派生的profile/reservation/marker/resolution/receipt/tombstone expected presence。RCC07/08不猜rename可见性，而对scan实际选出的OLD或NEW应用同一行中唯一对应分支，永不拼接。callback loss归RCC11；RCC12只表示success callback已发布，消除旧`SUCCEEDED_OR_FOUND`联合oracle。short write、ENOSPC、barrier/replace/readback error分别注入RCC03..10；预期bytes不得由被测codec自填。两份manifest及132条展开结果进入Config content hash；缺RCO/RCC字段、未展开、平台barrier未验证或positive control未触发时只可`INCONCLUSIVE`。

掌天瓶132-byte domain、持久battle/preparation allocator、Prep exact-one/NONE reserve after-image、360-byte run-start recovery、1152-byte reservation wrapper、七checkpoint单一nested journal、Active marker、唯一terminal request与132-row reservation crash-cut fixture作者表已完成静态合同整改；generated codec/crash artifact与runtime readback仍保持 `BLOCKED-RESERVATION-INTEGRATION`。本节继续唯一拥有介质与exact-once边界。

### 3.8 Resolved archive 与 carrier retire

SaveSystem 持久化 GameRoot 的 `ResolvedRunArchiveV1` 与 `ArchiveRetireJournalV1`，不改变字段或 bit：`OUTCOME=1, COMPLETION=2, SAVE=4, BATTLE_IDENTITY=8, PREOUTCOME_IDENTITY=16`。

标准BOUND resolved outcome的`expected_retired_carrier_mask=31`。`checkpoint_id`封闭值为`PREPARED_DURABLE=1, ARCHIVE_DURABLE=2, OUTCOME_RETIRED=3, COMPLETION_RETIRED=4, SAVE_RETIRED=5, BATTLE_ID_RETIRED=6, PREOUTCOME_RETIRED=7, CARRIERS_RETIRED=8, COMPLETED_DURABLE=9`；它不改变既有journal四态，只标记最后完成checkpoint。

- 只有 `SAVE_SUCCEEDED` 或 `DISCARDED` 可创建 archive row；unresolved Save/Reservation 不得开始。
- `(operation_id,outcome_commit_id)` 是幂等键。重复 append 返回原 row；字段任一不同为 conflict。
- archive row 与 journal `ARCHIVE_COMMITTED` 必须在同一 durable slot transaction，readback逐字段一致后 GameRoot 才退役 runtime carriers。
- runtime 按固定bit顺序`1→2→4→8→16`退役；每确认一项物理不存在，GameRoot exact-once OR bit 后请求持久化 journal；Save 不主动释放 Node/carrier。
- `retired_carrier_bits==expected_retired_carrier_mask` 后才允许 `CARRIERS_RETIRED→COMPLETED`；部分失败从首个未完成 checkpoint 继续。
- 重启时若 journal 未 COMPLETED，恢复同一 operation 并阻止新局；若 runtime carrier 已物理不存在，GameRoot 使用持久化 bit 与 presence oracle继续，不能重建或重放奖励。
- 若 `process_epoch` 已变化且 journal 至少为 `ARCHIVE_COMMITTED`，启动恢复器先验证 pending outcome/reservation均已resolved、app carrier registry为空，再把“上一进程已不存在”的 expected carrier bits exact-once OR入journal；它只完成退役证据，不重建carrier、不重放业务side effect。

### 3.9 Startup、损坏与迁移

启动 total outcome：

| Slot A/B | Outcome | 行为 |
|---|---|---|
| 两者 ABSENT | `EMPTY_INIT` | 创建 schema V1 空 profile；只适用于从未存在任何存档证据 |
| 两个同generation同bytes VALID | `READY` | 稳定选A作为current，双镜像健康 |
| 两个不同generation VALID | `HEAL_REQUIRED` | 选高generation；先镜像heal，再hydrate/reconcile，不回退低generation |
| 单个 VALID、另一正式槽 ABSENT | `HEAL_REQUIRED` | 选VALID并先补镜像；首次初始化/中断恢复均适用 |
| 一槽 INVALID、另一槽 VALID | `RECOVERY_REQUIRED` | VALID仅作为只读恢复候选；保留坏槽，禁止写入/新局，显式恢复并readback后才READY |
| 任一 FORWARD_INCOMPATIBLE 且无可证明更新的 VALID | `UPDATE_REQUIRED` | 只读保留全部 bytes，禁止覆盖/新局 |
| 无 VALID 且存在 INVALID | `CORRUPT_BLOCKED` | 不创建空档、不覆盖；提供导出诊断/恢复入口 |
| 同 generation 不同 VALID 或冲突 resolution | `STORE_CONFLICT` | fail closed，禁止写入与新局 |

temp文件永不参与正式槽分类；`ABSENT+ABSENT+temp残片`仍可隔离temp后按EMPTY_INIT重试，因为任何durable正式事实都不曾成立。若可读的forward-version header generation高于已知VALID，必须UPDATE_REQUIRED，不能回退旧版覆盖。

boot hydrate normalization固定：无durable resolution时，槽内`SAVE_PENDING(in_flight=1)`投影为`SAVE_UNCERTAIN,in_flight=0`，attempt_count/generation/request/operation均PRESERVE；`DISCARD_PENDING(in_flight=1)`投影为同state且`in_flight=0`并保留tombstone。若scan找到matching resolution，直接hydrate合法`SAVE_SUCCEEDED`或`DISCARDED`presence。该规则只恢复GameRoot既有七态，不创建第二套reducer。

向后 migration 仅允许 registry 中连续、纯确定性 `vN→vN+1` step。migration 前保留源 bytes，目标按普通 commit protocol 写入并 readback；失败继续保留原版。前向未知 schema 永不降级写回。migration 不得发奖励、推进 reservation、生成 outcome resolution 或重置 identity。

应用启动必须先恢复 store，再恢复 unresolved reservation/save/archive journal，最后才允许 Home 新局 gate。进程内 callback cache 不能替代 durable scan。

### 3.10 状态反馈与音频边界

SaveSystem 只发布 typed `SavePresentationViewV1={state,reason_code,recoverable,primary_action,secondary_action,close_warning,profile_revision}`；BattleUI/Home/Settlement 决定布局和本地化。

| State | 玩家文案语义 | 可用动作 |
|---|---|---|
| `NOT_STARTED` | 尚未开始保存 | 开始保存 |
| `SAVE_PENDING` | 正在保存 | 无重复提交；可等待 |
| `SAVE_UNCERTAIN` | 保存结果待确认 | 主CTA“核对保存结果”；重试保存/放弃为低强调次级且放弃需二次确认 |
| `SAVE_FAILED` | 保存失败，进度尚未写入 | 重试保存；放弃需二次确认 |
| `SAVE_SUCCEEDED` | 已保存/奖励已到账 | 继续；唯一 receipt |
| `DISCARD_PENDING` | 正在确认放弃 | typed view只给一个主CTA“继续放弃”或“核对放弃结果”；关闭前警告 |
| `DISCARDED` | 已放弃本局进度 | 继续；不得显示奖励到账 |

`CORRUPT_BLOCKED/UPDATE_REQUIRED/STORE_CONFLICT` 使用非战败、非责备语言，关闭新局与覆盖写。AudioFeedback 只消费 durable state edge；pending 循环音默认0，success最多一次轻提示，失败/不确定不使用惩罚性重音。静音时所有状态仍由文字、图标与CTA独立成立。

## 4. Edge Cases

| Case | Exact outcome |
|---|---|
| 首次安装两个槽均不存在 | 唯一 `EMPTY_INIT`；创建 revision0 空档，不误报恢复 |
| 写temp/replace/镜像任意byte后断电 | temp残片隔离；正式槽只取VALID最高generation，高低generation先heal后reconcile |
| flush返回成功但readback失败 | `COMMIT_UNCERTAIN`；不回调成功，重启/reconcile扫描 |
| callback丢失 | durable fact保留；同commit reconcile返回FOUND |
| callback重复或乱序 | Save返回同事实；GameRoot correlation不匹配为OK_NOOP |
| commit先durable、discard后到 | 返回`OUTCOME_COMMIT+RECONCILE_FOUND`与原receipt；tombstone写入数0 |
| tombstone先durable、commit后到 | commit拒绝；profile不变；返回原tombstone事实 |
| 同request identity换payload/hash | CONFLICT；0 bytes written |
| expected profile revision陈旧 | STALE_REVISION；不做last-write-wins或merge |
| 一槽坏、另一槽有效 | RECOVERY_REQUIRED；有效槽只读，显式恢复完成前禁止新局/覆盖 |
| 两槽皆坏 | CORRUPT_BLOCKED；不静默清档 |
| 发现未来schema | UPDATE_REQUIRED；只读保留，不降级覆盖 |
| generation/identity/revision溢出 | ID_EXHAUSTED；旧槽逐位不变，0 bytes written |
| archive append成功、callback前崩溃 | 重启按幂等键找到原row，不重复append |
| retire只完成部分bits后崩溃 | 从持久化bitset继续，已退役项不重放 |
| unresolved Save/Reservation时请求新局 | WRONG_STATE；显示恢复CTA |
| ABANDONED提交奖励bundle | 奖励/纪录请求拒绝；若有matching reservation，只允许零奖励tombstone+mandatory consume after-image同槽提交 |
| TECHNICAL_ABORT含未提交staging | bundle validator拒绝；不猜测补偿 |
| hash校验通过但domain decode失败 | INVALID/CORRUPT_BLOCKED，不接受“hash通过即合法” |
| 用户静音/后台切换 | 不改变durable结果；恢复后从scan truth呈现 |

## 5. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| GameRoot | Outcome/Completion/Save carrier、result reducer、reservation、archive/retire journal | 静态ABI已冻结；独立复审与runtime integration OPEN |
| Config/Data | PersistentDomain/codec/migration/capacity manifests与稳定content revision | manifest尚未落地，BLOCKED |
| SettlementSystem | outcome→typed mutation bundle→完整profile after-image | Designed / Full Review Pending；codec/runtime integration BLOCKED |
| Progression Tree | `ProgressionProfileDomainV1`、购买after-image与generic domain mutation | Designed / Full Review Pending；codec/runtime/crash integration BLOCKED |
| Zhangtian Bottle / Prep | 灵药domain、reservation/consume/release/compensation after-image | In Review / Re-review Pending；crash/runtime integration BLOCKED |
| Home/BattleUI | presentation view、CTA、损坏/升级/退出警告 | 两者作者GDD已冻结；runtime/UX evidence OPEN |
| Audio Feedback | durable edge one-shot提示、静音等价 | Designed / Full Review Pending |
| Godot 4.7.1 | FileAccess bool返回、flush/close/rename与平台durability语义 | bool返回已有本地参考；durability/Android kill测试OPEN |

## 6. Tuning Knobs

| Setting | Baseline | Classification | Change rule |
|---|---:|---|---|
| save slots | 2 | FIXED MVP | 改动需新介质ADR与全部crash-point复测 |
| concurrent durable writers | 1 | HARD LIMIT | 不可调高 |
| pending outcome commits | 1 | HARD LIMIT | 与GameRoot固定一致 |
| unresolved reservations | 1 | HARD LIMIT | 新局gate前必须resolved |
| resolved archive rows | 64 | PROVISIONAL-PRODUCT | 产品/支持策略裁决后锁定；变更需migration + rolling-prefix oracle复测 |
| max slot bytes | 65,536 | FIXED V1 | ReservationMax=1152、LatestResolutionMax=264、SlotPayloadMax=42244、SlotEncodedMax=42456、margin=65,536、DiskPeakMin=262,144；generated checked-sum须逐项覆盖全部top-level payload field |
| save latency p95/p99 | OPEN | EVIDENCE GATE | min-spec Android cold/warm/storage-pressure实测 |
| retry timeout | OPEN | UX/runtime gate | 不用timeout判定durable失败，只触发UNCERTAIN/reconcile |

## 7. Acceptance Criteria

- **AC-SV01 — Given** 两个正式槽均ABSENT且temp为无/任意残片；**When** 首次启动；**Then** 隔离temp后通过temp+双镜像唯一创建revision0空档；任一正式槽有INVALID证据则不得走EMPTY_INIT。验证：fixture files + byte snapshot。Gate: BLOCKING。
- **AC-SV02 — Given** 两个VALID槽generation不同；**When** scan；**Then** 选择较高者、先heal同generation镜像再开放写入。相同generation相同bytes选A，相同generation不同bytes为STORE_CONFLICT。验证：selection oracle。Gate: BLOCKING。
- **AC-SV03 — Given** 一次完整commit；**When** 在temp header/payload/footer每个byte边界、file barrier、atomic replace、directory barrier、首份readback、镜像各checkpoint前后注入kill；**Then** 重启只选择旧完整或新完整generation，从不选择temp/torn槽；只有双镜像readback后可回success。验证：exhaustive crash harness。Gate: BLOCKING。
- **AC-SV04 — Given** Godot任一`store_*`返回false、close/flush/readback失败；**When** commit；**Then** 不返回SUCCEEDED；能证明未durable为FAILED，否则UNCERTAIN，旧槽逐位不变。验证：I/O fault adapter。Gate: BLOCKING。
- **AC-SV05 — Given** 非canonical integer/float/string/array、NaN/Infinity/-0、length overflow、domain乱序/重复及每个自hash字段；**When** encode/decode；**Then** domain-separated zero-field preimage与golden逐位一致，非法输入fail closed且0 bytes written。验证：golden/negative codec corpus。Gate: BLOCKING。
- **AC-SV06 — Given** valid request；**When** checked_add在generation/revision/identity任一处溢出；**Then** ID_EXHAUSTED，旧槽与runtime request carrier逐位不变。验证：0/1/MAX/MAX+1边界。Gate: BLOCKING。
- **AC-SV07 — Given** COMMIT形成durable fact但callback丢失；**When** 同commit RECONCILE；**Then** 返回`OUTCOME_COMMIT+RECONCILE_FOUND`与原SUCCEEDED durable receipt逐byte相同，profile只推进一次。验证：process restart trace。Gate: BLOCKING。
- **AC-SV08 — Given** COMMIT未形成可验证fact；**When** reconcile；**Then** 返回`RECONCILE_NOT_FOUND_UNPROVEN`，GameRoot保持SAVE_UNCERTAIN而非FAILED。验证：reducer integration。Gate: BLOCKING。
- **AC-SV09 — Given** commit先durable；**When** discard先于success callback到达；**Then** 返回`OUTCOME_COMMIT+RECONCILE_FOUND`、matching receipt、tombstone=0、profile保持已提交。验证：durable-order matrix。Gate: BLOCKING。
- **AC-SV10 — Given** tombstone先durable；**When** 旧或新generation commit/late callback到达；**Then** DISCARDED事实获胜、0 profile mutation、旧callback OK_NOOP。验证：durable-order matrix。Gate: BLOCKING。
- **AC-SV11 — Given** `ReservationResultCodeV1`全部12个code、五个terminal operation、三种disposition与非法组合；**When** 逐个返回；**Then** 与GameRoot total reducer逐行一致，durable receipt code固定SUCCEEDED，public reconcile code不改receipt，correlation/presence任一破坏均不改carrier。验证：cross-GDD generated matrix。Gate: BLOCKING。
- **AC-SV12 — Given** duplicate operation/request；**When** bytes相同或不同；**Then** 相同以public `RECONCILE_FOUND`返回原receipt/tombstone且不追加，不同报`CONFLICT`且0写入。验证：idempotency corpus。Gate: BLOCKING。
- **AC-SV13 — Given** 陈旧expected_profile_revision或after-image revision不等于base+1；**When** commit；**Then** `STALE_REVISION`且不merge、不重算奖励。验证：revision race fixture。Gate: BLOCKING。
- **AC-SV14 — Given** ABANDONED、DEFEAT、VICTORY、TECHNICAL_ABORT各sealed envelope及用户discard；**When** Settlement bundle/tombstone提交；**Then** Save只接受owner validator签发的完整after-image；ABANDONED/普通discard奖励变化为0但matching reservation mandatory consume，technical未提交staging拒绝。验证：outcome/bundle/discard fixtures。Gate: BLOCKED on Settlement runtime。
- **AC-SV15 — Given** seed/NONE reservation各state、唯一nested PrepCommitJournal七checkpoint、candidate/pre-active/Active marker前后kill与callback丢失、11-row `ReservationCrashOperationManifestV2`×12-row `ReservationCrashCutManifestV2`唯一展开的132-row fixture，以及双槽/temp/writer absence proof正反例；**When** reserve/update/consume/release/compensate/reconcile/retire；**Then**扣除或返还与fact同槽原子、每次合法更新以generation/checkpoint/hash CAS exact-once，只接受5-row payload manifest携带的真实mutation bytes，360-byte recovery按durable config content identity与252/296-byte semantic hash恢复同一132-byte candidate/offer/selected choice/loadout/RNG cursor；UPDATE_RECOVERY reconcile按selected formal hash唯一返回FOUND或FOUND_OLD，marker orphan consume，前置invariant validator早于13-row reconcile首匹配，unproved NOT_FOUND保持UNCERTAIN、proved absence只清volatile correlation；CREATE V3回显source correlation/operation identity，CREATE与RESOLVE使用120-byte receipt且receipt ID=request ID，唯一`ResolveReservationPayloadV3` terminal transaction写奖励/tombstone、264-byte resolution并清live reservation/marker，duplicate返回同typed result，unresolved时新局WRONG_STATE。验证：reservation state/132-row crash matrix。Gate: BLOCKED on Zhangtian/Prep runtime。
- **AC-SV16 — Given** 一槽INVALID、另一槽VALID；**When** 启动；**Then** RECOVERY_REQUIRED、VALID仅作只读候选，坏槽保留且新局/写入关闭；显式恢复写入安全目标并readback后才READY。验证：corruption corpus。Gate: BLOCKING。
- **AC-SV17 — Given** 两槽INVALID、未来schema或冲突resolution；**When** 启动；**Then** 分别CORRUPT_BLOCKED/UPDATE_REQUIRED/STORE_CONFLICT，不创建空档、不覆盖、新局关闭。验证：startup total table。Gate: BLOCKING。
- **AC-SV18 — Given** 每条连续migration step；**When** 在每个write/readback checkpoint kill；**Then** 原版始终可恢复，目标仅在完整验证后生效，migration不改变奖励/reservation/identity语义。验证：version matrix。Gate: BLOCKED on migration manifest。
- **AC-SV19 — Given** resolved archive append；**When** callback丢失、重复operation、容量64→65；**Then** 原row不重复，最旧row进入prefix hash/floor，新row逐字段readback一致。验证：archive oracle。Gate: BLOCKING。
- **AC-SV20 — Given** ArchiveRetireJournal每个checkpoint与任意partial bitset；**When** 失败/重启/重试；**Then** operation_id稳定、state单调、已完成bit不重放；跨process epoch仅在archive/resolution/readback与空carrier registry均验证后补齐物理消失bit，全mask前不开放新局。验证：power-set fixture。Gate: BLOCKING。
- **AC-SV21 — Given** NOT_STARTED至DISCARDED七态；**When** Settlement/Fault/Home重复render与点击；**Then** 文案/CTA严格符合表，成功前“已到账/已保存”出现数0，任意时刻最多一个write/in-flight。验证：UI automation + service counters。Gate: BLOCKED on UI owners。
- **AC-SV22 — Given** mute、后台切换、应用被系统杀死；**When** 恢复；**Then** durable truth不变，音频不影响ACK/恢复，presentation来自新scan而非callback cache。验证：lifecycle/device test。Gate: OPEN runtime。
- **AC-SV23 — Given** min-spec Android正常、低空间、慢存储与强杀场景；**When** 执行cold/warm commit/reconcile；**Then** 无ANR、无丢档，记录p50/p95/p99与slot bytes；阈值未签发前结果仅MEASURED/INCONCLUSIVE。验证：device benchmark。Gate: OPEN device evidence。
- **AC-SV24 — Given** 当前仓库仅GDD；**When** 静态schema/registry/diff检查通过；**Then** 只证明authoring consistency，不证明Godot API durability、runtime、migration、性能或玩家体验。验证：evidence classification。Gate: BLOCKING on honest sign-off。
- **AC-SV25 — Given** durable pending carrier保存`SAVE_PENDING(in_flight=1)`、`DISCARD_PENDING(in_flight=1)`或matching resolution；**When** 新process boot hydrate；**Then** 分别归一为SAVE_UNCERTAIN/同DISCARD_PENDING且in_flight=0并PRESERVE IDs，或直接hydrate合法resolved presence。验证：boot matrix。Gate: BLOCKING。
- **AC-SV26 — Given** 旧物理write超时仍运行、后续reconcile/discard入队及第二实例竞争；**When** executor逐项取得lease；**Then** 物理write≤1、queue≤1，每项写前重扫resolution，只有首个PONR形成事实，未获lease实例0写入。验证：two-instance race + delayed I/O。Gate: BLOCKED on platform lease。

## 8. Visual / Audio / UI Notes

- 正常保存不弹全屏确认；只在失败、不确定、放弃、损坏或版本不兼容时要求注意。
- 放弃必须二次确认，明确“本局未保存进度将不会到账”；确认后仍要等待 durable tombstone，不能按钮按下即返回首页。
- 检出损坏槽时先进入阻断式恢复页；只有候选槽重新提交并readback成功后才显示“已从可验证备份恢复”，且不承诺无法验证的最新进度已恢复。
- 损坏/版本过新页面保留“导出诊断”入口；MVP是否提供用户可选恢复副本由Home UI决定，默认不允许覆盖原文件。
- Audio只对首次durable success播放一次低强度反馈；reconcile发现既有success不得重复庆祝。

## 9. Open Questions / Evidence Gates

| ID | Question / gate | Owner | Closure evidence | Status |
|---|---|---|---|---|
| OQ-SV01 | 四个persistent domain的实际schema、最大bytes与migration steps？ | Progression/Zhangtian/Settlement/Settings | 四个V1 schema/max bytes已作者冻结；actual codec与连续migration golden仍BLOCKED | PARTIAL |
| OQ-SV02 | Settlement mutation bundle exact schema与outcome逐字段映射？ | Settlement | GDD + AC-SV14 | AUTHOR CONTRACT DONE；generated/runtime BLOCKED |
| OQ-SV03 | `SHA256_V1` canonical codec和golden vectors？ | Save ADR | algorithm已裁决；ADR实现路径 + cross-platform corpus | PARTIAL / BLOCKED-HASH-CODEC |
| OQ-SV04 | Godot 4.7.1 file/dir barrier 与 Android/iOS kill 后durability边界？ | Godot specialist | source/docs + device crash harness | BLOCKED before implementation |
| OQ-SV05 | 两槽/temp路径、atomic replace、目录创建与平台错误码映射？ | Save ADR | implementation spike | BLOCKED before implementation |
| OQ-SV06 | `max_slot_bytes` 与低空间预检上限？ | Config/Performance | V1已签65,536/65,536/262,144；generated checked-sum与device evidence | PARTIAL |
| OQ-SV07 | 64-row archive retention是否满足诊断与隐私需求？ | Product/QA | playtest/support decision | OPEN |
| OQ-SV08 | Home损坏/恢复/升级页与无障碍copy？ | Home UI/UX | 作者流程/copy已设计；localized prototype + user test仍OPEN | PARTIAL |
| OQ-SV09 | RNG state跨实例保存是否需要？ | Product/RNG | MVP mid-run save decision | RESOLVED: MVP不支持mid-run save |
| OQ-SV10 | clean-context full review与runtime证据？ | review team | independent verdict + test artifacts | OPEN |
| OQ-SV11 | 平台排他writer lock与process epoch证据如何实现？ | Save ADR / Godot specialist | two-instance race + kill test | BLOCKED |

## 10. Handoff

本文给出“跨进程介质”的完整作者候选合同：单执行器、temp原子替换、同generation双镜像、自校验footer、durable pending carrier、启动scan/归一化、durable-first precedence、exact-once reservation/archive与fail-closed损坏策略。四个domain作者schema现已闭合；它仍没有关闭Hash/codec ADR、Godot平台durability、迁移golden、min-spec或独立复审gate。

Progression、Zhangtian、Settlement与Settings四个V1 domain及generic/terminal mutation静态ABI均已有作者候选。下一步是生成manifest/codec并分别做clean-context full review；本文状态保持 `In Review / Re-review Pending`，在OQ-SV01–11与runtime evidence闭合前不得称implementation-ready、runtime verified或battle_ready。
