# Zhangtian Bottle — Design Review Log

> 本文件记录 `design/gdd/zhangtian-bottle.md` 的独立 full review 与作者整改，不把静态修订记作复审通过。

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
