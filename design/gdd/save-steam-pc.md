# Steam Save v2

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> Status: Design Baseline APPROVED / Implementation Gates OPEN（2026-09-11独立senior复核；见reviews/steam-contracts-2026-09-11/review-director-followup.md）。Author decision: ADR-0006。Profile: STEAM_SAVE_V2（planned，runtime仍为JSON v1）。不构成格式上线、续局实现或Windows验证。

## Overview

SaveSystem应用服务串行持久化全局进度、备战事务与一个可恢复的当前run。使用严格版本化JSON双槽，目标是任一业务事务只产生旧或新完整结果，未知状态不盲重试；详细平台实现和预算完成前禁止启用v2。

## Player Fantasy

完成任务、花费材料和保存退出都有明确结果。游戏不会因为重启重复扣药、重复发首次奖励或把一个损坏存档静默重置。

## Detailed Rules

### 版本与编码

顶层封装`{format:"STEAM_SAVE_V2", payload_json:string, payload_sha256:hex64}`；hash覆盖payload_json解码后的UTF-8原字节，无BOM。payload中仅使用对象、数组、bool、字符串与null；所有计数/序号是canonical十进制字符串（0或无前导零正数），限制0..2^63−1并checked运算；浮点由domain codec编码为固定16位小写IEEE754 float64位模式hex（最高有效位在左，例如1.0=`3ff0000000000000`，与宿主内存字节序无关），禁止NaN/Inf，−0统一+0。禁止通过JSON数字承载int64。

规范JSON：对象key为schema定义的ASCII名，按ASCII升序；集合型数组按owner规定的稳定ID顺序；有语义的序列（例如BREAK实际completion_order_ids）保留owner定义顺序、不得排序改变语义，禁止依赖Dictionary遍历顺序；无空白；字符串采用UTF-8、仅quote/backslash和控制字符转义，控制字符用小写`\u00xx`。ID限制ASCII；人类文本不进入游戏状态，使用内容key。解析须拒绝重复key、未知字段、非规范数字串、非规范编码和不支持schema，不用宽松解析覆盖重复key后的结果。

### 根payload与owner边界

| 字段 | 类型/约束 | 含义 |
|---|---|---|
| schema | string固定"2" | 根schema |
| profile_id / branch_id | hex32，创建后不可随重试改变 | 档案/云冲突分支身份 |
| revision | decimal u63 | 每次持久事务+1 |
| parent_hash | hex64或新档null | 上一完整payload hash |
| content_revision / content_hash | decimal u63 / hex64 | 内容版本绑定，不等于代码版本 |
| next_run_seq / resolved_run_seq | decimal u63 | 单调签发run、退休高水位；不能用进程generation |
| last_operation | operation_id(hex32), request_hash(hex64), kind(string), base_revision(u63) | 用于同一次未确定IO的reconcile |
| domains | 已注册domain名→{schema:string,payload:object} | 原子after-image集合；未知/缺少必需domain拒绝 |
| migration_source | null或v1来源hash数组+迁移ID | 一次迁移的可核对来源 |

必需domain为`records/progression/campaign/unlocks/preparation/current_run/user_settings`；机器画面/设备选择保存在独立本地设置，不随云档同步。records/progression/preparation沿用其业务owner；本规范不把未定义的payload当有效。每个domain须有schema、validator、最大合法fixture和migration；缺注册项时v2加载/写入返回UNSUPPORTED_SCHEMA，不以空对象补齐。

wire统一为`domains.current_run={schema:"1",payload:{run:null|RunStateV1}}`；下文current_run为空均指`payload.run=null`，不省略必需domain或wrapper。`RunStateV1={run_seq, mission_id, run_status, mission_definition_hash, config_hash, seed, prep_receipt, preparation_checkpoint, checkpoint, terminal_intent}`。run_status仅`PREPARED/RUNNING/SUSPENDED/RESULT_PENDING`；checkpoint为`{checkpoint_seq,active_tick,owner_snapshots}`，owner snapshot每项`{owner_id,schema,revision,payload}`。snapshot必须包含所有实际安装的required owner及未完成ledger/队列，不持久化Node实例ID或原生句柄。其具体payload需各owner正式定义，因此完整续局当前仍BLOCKED。

### 事务API（规范接口，非现有函数）

`commit(base_profile_revision, operation_id, request_hash, kind, next_domains) -> SaveResult`。

kind封闭为`MIGRATE/PREPARE/UPDATE_PREPARATION/CANCEL_PREPARE/START/SUSPEND/RESUME/STAGE_RESULT/COMPLETE/DOMAIN_UPDATE`。请求hash覆盖规范化的kind/base_revision/next_domains及profile/branch身份。相同operation_id+hash只允许一个待处理请求；同ID不同hash返回CONFLICT且零写。一个未确定事务未reconcile前拒绝全部新mutation。新档首次提交以不存在profile为base revision=0，写revision=1、parent_hash=null，kind为DOMAIN_UPDATE；迁移用MIGRATE。成功后新档next_run_seq=1、resolved_run_seq=0、current_run=null。

`SaveResult={status,operation_id,request_hash,profile_id,branch_id,revision,head_hash}`；status为`COMMITTED/PROVEN_OLD/UNCERTAIN/CONFLICT/INVALID/INVALID_CONFIG/UNSUPPORTED_SCHEMA/LOCK_BUSY/TOO_LARGE/RETIRED`。只有COMMITTED可曝光after-image；PROVEN_OLD仅表示在锁内确认未生效且无写者仍在途，可按相同operation继续。旧run_seq≤resolved_run_seq返回RETIRED、零业务效果，不伪造重复成功receipt。请求必须与当前run或允许的全局domain一致。

### 单写者与IO顺序

在OS排他锁内读取当前合法head并比较base revision；捕获的after-image不可变。按`validate/encode → 写非active槽.tmp → flush/close → tmp完整读回 → 替换非active槽 → 完整读回 → 发布内存结果`提交。active槽的有效旧字节保持到新head验证完成。旧tmp不直接当commit真值。

首次可能写字节之前错误为INVALID/LOCK_BUSY等确定未写；之后无法证明状态的错误为UNCERTAIN并关闭写入。reconcile必须持锁，等待旧worker终止，读实际两槽：匹配同operation+hash的新head→COMMITTED；仍为相同base且无新head→PROVEN_OLD；不同已提交分支/请求→CONFLICT；读失败→UNCERTAIN。异常时不改ID重扣药，不以timeout证明未提交。

两槽同profile/branch且存在直接parent关系时取有效子head；同revision不同hash或祖先关系不明保留两份并冲突，不只按数字大小覆盖。不同profile/branch进入显式选择流程。SHA256仅检测一致性，不是反作弊签名。

读取组合：两槽相同合法hash视作同一head；初建仅一槽合法且另一槽不存在时可用；一槽校验确定损坏、另一槽合法时保留坏档副本后可恢复合法槽；任一槽读取权限/IO失败返回UNCERTAIN不覆盖；任一槽为不支持的更高schema返回UNSUPPORTED_SCHEMA不回落旧档写入；双坏阻断。缺失、确定损坏、未知schema和不可读必须分别报告。

### run与一次性奖励

PREPARE持久签发run_seq并记录备战占用，`preparation_checkpoint`由备战owner保存reservation/seed/offer revision及承诺状态。`checkpoint`在PREPARED可为null，`terminal_intent`为null。随机offer曝光前必须由UPDATE_PREPARATION持久化同一页及不可取消承诺；Back/关闭/重启只能恢复该页。CANCEL_PREPARE要求PREPARED且owner基于当前revision验证`cancellation_allowed=true`（无已承诺offer/不可逆选择）；否则返回INVALID，零释放，保留同reservation。合法取消原子释放未消费占用、退休run并清current_run。不得只看PREPARED枚举判断可取消。

START仅在所有pre-active选择已解决、备战owner完成预检、隐藏BattleScope完整构建后，将选定备战消耗与RUNNING、tick=0的全required-owner checkpoint一起提交，成功后才曝光战场。START后不能返药重抽。SUSPEND只在GameRoot暂停且所有required owner完成同tick稳定快照后提交，成功后退出到首页。

终态采用两次有身份的持久提交：GameRoot封结果并停tick；Settlement收集Campaign及各经济owner的不可变after-image，用STAGE_RESULT先写RESULT_PENDING。其`terminal_intent={sealed_result,result_hash,complete_operation_id,complete_base_revision,complete_request_hash,complete_next_domains}`；其中complete_base_revision固定为本次STAGE_RESULT将写入的revision（checked base+1），complete_next_domains是已经验证的完整完成后域集合，内含current_run.payload.run=null，因而不递归嵌套intent。COMPLETE请求hash按正常API计算。STAGE_RESULT自己的operation身份与后续COMPLETE不同，均在首次尝试前固定；stage未reconcile不得提交COMPLETE。

RESULT_PENDING期间禁止其它domain mutation/云替换/恢复战斗。COMPLETE只能使用已持久intent中的原operation、base、hash和after-image，不能根据新Config/新钱包重算；原子更新campaign、首次奖励、unlocks、records/progression、prep终态、current_run清空和resolved_run_seq。任一domain失败整体拒绝。主动放弃只有在GameRoot接纳请求时为未sealed的RUNNING/SUSPENDED才允许；接纳后封ABANDONED，同样走STAGE_RESULT→COMPLETE，退休run、不发胜负奖励且不自动返还确定消耗。Save不另设ABANDON写入kind。若请求到达时已有sealed则GameRoot返回ALREADY_TERMINAL（业务返回，不是SaveResult别名）。技术中止也通过STAGE_RESULT→COMPLETE走owner补偿，不得改为放弃规避；PREPARED承诺页不得借主动放弃取消。

### 启动恢复分派

| 已验证head的run状态 | 唯一恢复动作 |
|---|---|
| null | 显示最新持久进度；已退休run的迟到请求返回RETIRED，不再次奖励 |
| PREPARED | 恢复同一reservation/seed/offer/承诺点；允许取消仅按owner资格；不扣第二次药 |
| RUNNING | 只从其最后完整checkpoint恢复（START至少有tick 0）；提示崩溃回退，暂停等待玩家继续 |
| SUSPENDED | 从该checkpoint恢复，暂停等待玩家继续 |
| RESULT_PENDING | 不创建可玩的BattleScope；验证持久intent和各域后重试同一COMPLETE，成功后呈现结算 |

RUNNING/SUSPENDED的RESUME都在隐藏的新BattleScope完整验证/恢复后提交RUNNING，保留同一恢复点、不重扣备战，成功后才曝光；失败不覆盖最后合法head。PREPARED不会通过RESUME跳过START。新runtime epoch只供新事件交付，durable结果身份无epoch。输入来源/focus/设备不恢复成按住，遵循ADR-0005 fresh-neutral门。

在STAGE_RESULT形成合法head之前强杀，磁盘只证明旧RUNNING/SUSPENDED恢复点，允许回退重玩，不能声称内存sealed已经保存；同一次进程内未确定stage仍须reconcile。stage持久而COMPLETE未持久时必须恢复原intent。COMPLETE已持久但callback丢失时，读到run已退休及新进度，不重发。两槽读取必须先裁定新旧head，不能仅凭旧槽的pending再次写。非保存退出崩溃不保证最后一帧，UI明确显示恢复点。

### 迁移与云档

v1迁移按ADR-0006，保留原档，迁移后重新读回；旧胜利不当章节完成，3分支数值不重置。v2未知更高版本只读保留、禁止降级覆盖。

云档只传闭合并验证过的v2档案快照；应用正在运行且持锁时不直接热替换。相同hash无操作；可证明单步parent关系可前进；两个离线分支保留两份，由玩家选择一个branch继续，禁止按钱包或revision做自动union。即使两份branch_id相同且revision相同、hash不同，也按两个候选head展示，不按branch_id去重；明确选择后保留该候选branch_id，以其hash为下一事务唯一parent，未选中候选完整导出留存。branch_id不靠一次选择改写；以后再遇到未选候选仍须冲突选择，不自动合并。未选中分支保留导出备份；不能把两份各自消耗的备战/奖励合并增益。

## Formulas

`next_revision=checked(base_revision+1)`；`new_run=next_run_seq`后checked递增；`resolved_run_seq<current_run.run_seq<next_run_seq`。`hash=SHA256(UTF8(canonical_payload))`。encoded bytes与每domain容量由Config预算manifest提供，正整数且不超过平台验证值；没有预算时INVALID_CONFIG，不继承旧binary上限。

## Edge Cases

双坏档/不支持schema不自动新建；同ID不同请求拒绝；旧callback和过期run零mutation；满盘、只读、锁竞争、flush/替换后故障须区分确定与不确定。捕获期间目标死亡/新事实到达不得混用revision；先完成暂停barrier再捕获。序号耗尽拒绝新事务并提示维护，不wrap。内容停用需明确迁移，找不到任务/技能时不自动换成另一个ID。

## Dependencies

ADR-0006、save-system.md业务恢复语义、game-root-scene-flow.md、settlement-system.md、campaign-flow.md、mission-objectives.md、progression-tree.md、zhangtian-bottle.md、config-data-system.md及所有snapshot owner。Windows锁/文件adapter与Steam Cloud实现尚待建立。

## Tuning Knobs

序列化总字节预算、每owner snapshot容量、捕获/写回耗时预算、UI进度显示阈值由Config/性能验证冻结；它们不能改变一次性奖励/UNCERTAIN/版本规则。最大负载必须覆盖RESULT_PENDING同时携带当前域与完整complete_next_domains的双份数据、编码临时量和readback峰值，不能只测RUNNING快照。当前无可用于生产的v2预算manifest。

## Acceptance Criteria

- SP01 编码：重复key/未知字段/非finite浮点/非规范int64/序号溢出拒绝；跨编码器golden逐字节一致。
- SP02 幂等：相同待处理ID+hash不第二次写，不同hash零写CONFLICT；迟到旧run返回RETIRED无奖励。
- SP03 原子完成：COMPLETE每个IO切点重启，任务位、首次奖励、解锁、药品、记录和current_run只出现全旧/全新。
- SP04 reconcile：tmp写、flush、replace、readback各注入失败；锁内唯一判断COMMITTED/PROVEN_OLD/UNCERTAIN，不以timeout替代磁盘证据。
- SP05 migration：合法v1保留进度原值，章节为空；双坏/同代冲突不覆盖；重复迁移只产生同一个v2profile。
- SP06 suspend：所有required owner齐备才成功，缺失/超预算保持暂停；成功后重启还原matching tick/构筑/目标/RNG/实体状态。
- SP07 resume：恢复失败不覆盖SUSPENDED，成功后first input tick ZERO；hold输入不能自动移动。
- SP08 并发：两个Windows进程同profile仅一写者，释放锁后重读revision；不得并行commit。
- SP09 云冲突：祖先可证明才前进，离线兄弟分支保留两份；不合并重复药品/奖励。
- SP10 schema：不支持高版本/停用内容/缺owner拒绝且原字节不改，提供明确诊断。
- SP11 最大负载：完整合法最大快照满足冻结字节、内存与时间预算；缺预算即门未过。
- SP12 设备：Windows强杀/满盘/权限/更新/恢复证据绑定release hash；macOS五点v1测试不得替代。

- SP13 boot矩阵：START读回后首帧前强杀回到tick 0；RUNNING强杀回最后checkpoint；stage前回旧恢复点、stage后恢复原intent、COMPLETE后回新档且零重奖。
- SP14 承诺页：offer持久曝光后取消返回INVALID且重启同页；合法取消重试至多释放一次。
- SP15 wire：空档与退休档均为`{"payload":{"run":null},"schema":"1"}`域wrapper；PREPARED/SUSPENDED只替换run值，不改变wrapper层级。
- SP16 pending：E1封结果、stage持久、E2重启，sealed字节/hash与COMPLETE身份不变；pending期间其它mutation拒绝，不重算奖励。
