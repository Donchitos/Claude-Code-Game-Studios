# Campaign Flow — Steam 1.0

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> Status: Design Baseline APPROVED / Implementation Gates OPEN（2026-09-11独立senior复核；见reviews/steam-contracts-2026-09-11/review-director-followup.md）。Owner: ST-S01。ADR-0006。作者合同，未接生产。

## Overview

管理八章64任务的可用性、首次完成和内容解锁。Campaign只消费Mission最终结果，生成不可变完成计划，由Settlement与Save原子提交；不驱动战斗tick，不直接修改货币或存档。

## Player Fantasy

每次试炼推进清楚的长期目标；失败可以重试当前任务，已完成章节不丢失，玩家不必靠随机掉落或重复刷取才能进入下一章。

## Detailed Rules

### 内容与状态

生产内容必须由Config生成并验证；规划CSV不是runtime输入。`CampaignDefinitionV1={schema,content_revision,content_hash,missions[]}`；任务行`{mission_id,chapter_id,ordinal,prerequisite_id_or_null,mission_definition_hash,first_grants[]}`，schema整数语义采用Save v2字符串codec。64行ID与顺序对应商业矩阵；每章8行，首行前置为前章末行，第一行前置null。全部ID唯一、图无环且可达，否则拒绝加载。

`CampaignDomainV1={schema:"1",domain_revision,completed_mission_ids[],ending_seen:bool}`；completed为按mission ordinal排序的集合。`UnlockDomainV1={schema:"1",domain_revision,unlocked_content_ids[]}`按ASCII排序去重。初始只授予Config定义的START内容，不能靠加载缺域自动补发后续奖励。

可用性由completed集合与前置计算，不保存一个可能与集合矛盾的current_chapter。`LOCKED`前置未完成；`AVAILABLE`前置完成且未完成自身；`COMPLETED`已完成，允许自愿重玩。主线必须先验证completed是合法前缀；未来分支需新schema，当前不能装载破坏前置的集合。

### API与权限

`query_mission(profile_revision,mission_id)->{status,availability,first_grants}`是只读；旧profile revision返回STALE，未知ID返回UNKNOWN_ID。入口还需GameRoot确认无未结束run和Save无UNCERTAIN。

`prepare_completion(snapshot,mission_result)->CampaignCompletionPlanV1`：snapshot含profile/branch/base revision与只读campaign/unlocks；mission_result是Mission的sealed terminal result。验证current_run identity、definition hash、实时交付envelope的当前epoch和任务可用性，不接受任意UI传入胜利bool。结果本体不含epoch；RESULT_PENDING恢复不调用本API重新计划，由Save验证持久intent后Settlement重试原COMPLETE；旧结果不因新epoch改变字节。

`CampaignCompletionPlanV1={schema:"1",profile_id,branch_id,base_profile_revision,run_seq,mission_id,mission_result_hash,first_completion:bool,campaign_after,unlocks_after,grant_ids[]}`。失败结果不加completed/unlock，first_completion=false、grant_ids为空。成功但已完成的任务也不再发首次授予。next domain revision仅内容实际变化时+1，checked溢出拒绝计划。

Campaign只签发内容授予ID，不自行加钱包；各奖励owner计算after-image，由Settlement把完整plan、run退休、记录和prep状态一起提交。只有匹配本run/operation/hash的COMPLETE返回COMMITTED后才把新snapshot交给Home/任务选择并播放解锁表现。STAGE_RESULT的COMMITTED只证明pending请求已保存，绝不曝光完成/解锁；callback身份/版本不匹配忽略，不重新构造“当前最新奖励”。

### 重玩、章节与结局

64任务首次奖励由Config显式列出，不依赖“第几个数组元素”的临时代码推断。常规重复掉落由Drop/Settlement处理，但不改变首次授予集合。safe选择和首名角色必须可完成普通主线，不以挑战、成就、丹药、真实时间或付费锁主线。

前7章M08完成开放下章；第8章M07完成仅开放M08，M08完成后才能播放终局。`ending_seen`只由结局实际完成/用户跳过呈现后提交的DOMAIN_UPDATE更新，不能以它代替M08完成事实；未标记seen时重启可重看，不重发奖励。

### 新Mission与Settlement/备战的profile适配

新任务profile命名`STEAM_MISSION_V1`，不能因输入STEAM_PC已启用而自动启用。它明确覆盖旧Settlement的全局Boss时长校验与首次结算starter规则：合法MissionResult VICTORY由目标条件证明，terminal_tick可小于43200（不强行等12分钟）；上限与超时按任务definition，旧43200..108000胜利窗口不适用。`VICTORY→正常胜利`、`DEFEAT→正常失败`、`ABANDONED→无胜负奖励的放弃`、`TECHNICAL_ABORT→不新发胜负/首次/随机奖励，已committed的stones/pages按旧owner保留，备战按已持久事实补偿`。后两者不产生首次完成；不允许仅为绕过故障补偿改映射。

备战入口及第一批备战内容的唯一首次开放来自Config中S1-M01-03的Campaign grant；START集合不能含备战开放权限，前两任务胜/败与一般第一次结算不能触发旧三starter自动授予或解锁。grant的稳定ID/实际药品映射必须在生产Config中冻结；当前规划ID不冒充runtime实体。已经迁移的库存/成长数值保留，但入口资格仍按新campaign授予，不额外补发旧starter。首次可用时的教学资源也必须作为该grant的经济owner after-image，一次提交、一次授予。

Settlement、Zhangtian、Prep、Drop、GameRoot与Config必须发布本profile的adapter/validator及独立AC后才能启用。短任务重复奖励按任务与有效战斗贡献计算；具体公式、每次/每分钟上下限、零贡献、重玩和失败的收益矩阵尚未冻结，保持ECON-MISSION-01 OPEN，禁止沿用旧全局局长公式投入生产。此数值门不改变合法快速胜利和M01-03开放这两项已选业务规则。

v1旧档的total victories不代表64任务任何一项完成；迁移保留成长与记录，新campaign从首任务开始。内容更新删除任务/授予ID必须提供显式迁移；未知ID不回退到第一任务覆盖进度。

## Formulas

`available(m)=m∈completed OR prerequisite(m)=null OR prerequisite(m)∈completed`；`first_completion=success AND m∉completed`。`after_completed=first_completion ? completed ∪ {m} : completed`；`after_unlocks=first_completion ? unlocks ∪ first_grants(m) : unlocks`。章节完成当且仅当该章8项均在集合内；终局可展示当且仅当S1-M08-08已COMMITTED。

## Edge Cases

重复结果同run不重复授予，过期run由Save RETIRED拒绝；同任务不同run重玩不得再授予首次奖励。保存不确定时不开放下一任务；render先播放奖励再写盘禁止。准备期间profile发生变化时返回STALE并回可交互选择，不在旧plan上补差。正常失败不删除已有completed，主动放弃/技术故障按Settlement规则处理。

## Dependencies

mission-objectives.md、save-steam-pc.md、game-root-scene-flow.md、settlement-system.md、config-data-system.md、home-ui.md、prep-ui.md、progression-tree.md；商业内容来源steam-1.0-campaign.md。Character/Codex/Narrative独立GDD尚未建立，当前由系统迁移表ST-S03/ST-S05/ST-S07追踪，不声称已具实现依赖。

## Tuning Knobs

任务数/章节数/first_grants/内容解锁表在版本化Config；当前工作基线8×8。改变顺序或ID须content revision和migration，不能当普通难度调参。奖励数值仍由经济owner，不在Campaign写死。

## Acceptance Criteria

- CF01 64任务8章合法图通过；重复ID/环/断前置/未知grant拒绝加载且不开战。
- CF02 新档首任务可用，其余锁定；首次提交M01-01后仅M01-02新增可用。
- CF03 任务失败/放弃不增completed/unlocks，不删除先前结果。
- CF04 完成事务前、中、后强杀：首次奖励与completed/unlocks/run退休全旧或全新。
- CF05 同run重复、旧run迟到、同任务不同run重玩，首次grant均至多一次。
- CF06 第8章M07不触发终局；M08持久化后才可播放，重看/跳过不重发奖励。
- CF07 输入旧profile/definition hash或未知任务，零业务修改且返回明确错误。
- CF08 首名角色+safe+无丹药完整普通主线可达，挑战/成就不在前置图。
- CF09 v1迁移保留成长记录但completed为空；未知高版本/内容停用拒绝静默覆盖。
- CF10 每次UI显示下一任务绑定匹配COMPLETE的COMMITTED revision（STAGE_RESULT成功不得开放）；UNCERTAIN期间不开放入口。

- CF11 有非空first_grants时分别验证失败、重玩成功、首次成功：仅最后一类改变completed/unlocks并生成grant。
- CF12 合法目标在43200ticks之前完成可产生正常胜利结算；前两任务正常胜/败均不开放备战、不发旧starter；M01-03首次完成才原子开放，重玩不重授。
- CF13 未注册新Settlement/Prep profile validator或缺ECON-MISSION-01预算/公式时拒绝启用STEAM_MISSION_V1，不能自动落入legacy规则。
