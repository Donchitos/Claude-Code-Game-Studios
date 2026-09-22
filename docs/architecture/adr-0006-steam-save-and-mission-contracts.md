# ADR-0006：Steam 版本化JSON存档与章节任务事务

## Status

Accepted for architectural direction — 2026-09-11，依据用户“确定存档策略与章节目标合同”的工程授权，由本轮作者选择方案。本ADR及三份新GDD的合同设计基线已获2026-09-11独立senior APPROVED（design/gdd/reviews/steam-contracts-2026-09-11/review-director-followup.md）；实施门仍OPEN，不表示已实现或发行批准。

## Date / Last Verified

2026-09-11。核对当前`src/persistence/save_system.gd`、ADR-0003、save-system/settlement GDD和Steam商业范围。当前运行仍是旧JSON v1，本ADR不自动切换生产格式。

## Decision Makers

用户确认Steam完整产品及20小时以上方向；本轮工程作者作实现方案选择。独立审查结论另记，不虚构技术总监或用户对每个字段的批准。

## Summary

Steam完整版本采用独立的`STEAM_SAVE_V2`版本化JSON持久化协议、单写者、双槽、明确事务身份和故障reconcile。章节任务完成、首次奖励、解锁与本局退休在同一次持久提交中生效；支持暂停后的保存退出和继续本局。

## Context

当前v1已有双槽、hash、写后读回及五个macOS进程结束测试，可复用文件访问基础。旧save-system.md描述固定二进制载荷，排除云档和中途续局；新商业范围包含64任务、角色/图鉴解锁、云档与局内恢复，已经超出其固定domain与大小假设。仅改名、改扩展名或追加一个Dictionary不足以形成商业存档。

## Decision

1. 选择JSON v2方案；沿用可审计的文本封装，新增严格schema、规范序列化、业务域validator、事务与版本迁移。具体持久合同见[Steam Save GDD](../../design/gdd/save-steam-pc.md)。
2. v2是新的格式选择，名称与Input的STEAM_PC v1无关。旧v1文件只通过一次显式迁移进入新profile目录；旧binary GDD的byte/row/槽大小不适用于v2。旧reservation的“先持久化再曝光、消耗与结果一致、uncertain先reconcile”等业务要求继续保留。
3. Windows所有写入由Save应用服务串行化，进程排他锁必须由OS adapter持有；锁实现需Windows验证后才能启用磁盘v2。禁止用“文件存在”当排他锁。
4. 提交完整after-image；向非active槽的临时文件写入、flush/close/readback、替换非active槽并再次读回后，才发布新内存profile。写入开始后的错误视为UNCERTAIN，不得重新扣除资源或以新operation_id重试。
5. 保存退出以完整的、版本绑定的安全tick快照为目标。GameRoot先暂停并在提交边界关闭consumer；所有必需owner捕获可恢复状态，Save成功后才返回首页。捕获缺owner、版本不兼容或超预算时保持暂停，明确提示不能保存退出；不悄悄把它降为“重开同seed”。
6. 章节完成由Campaign负责，局内目标由Mission负责，终局由Settlement提交。Stage的Boss死亡只是目标事实；GameRoot仍拥有全局状态和tick时序。接口见[campaign-flow](../../design/gdd/campaign-flow.md)、[mission-objectives](../../design/gdd/mission-objectives.md)。
7. STEAM_MISSION_V1使用目标证明的胜利（无旧12分钟下限）与M01-03 Campaign唯一备战开放；Settlement/Prep/经济profile传播和短局奖励公式齐备前禁止启用。
8. 先设计完整恢复域，再实现serializer；snapshot性能不达预算时修改捕获方式或降低非必要持久量，不能删掉影响重放和奖励的状态。

### Architecture / Key Interfaces

`Mission tick facts → MissionDecision → Campaign completion plan + feature after-images → Settlement → Save STAGE_RESULT durable intent → Save COMPLETE(base revision, operation identity, complete next image) → durable receipt → UI/next mission`。

`Pause barrier → required-owner snapshots → Save SUSPEND → durable receipt → Home`；继续时 `lock + load + validate → 按持久run状态分派；RUNNING/SUSPENDED instantiate privately → restore all owners → RESUME commit → fresh input barrier → expose；RESULT_PENDING只恢复原COMPLETE请求`。

具体字段、拒绝行为、重复和过期结果由三份GDD定义。公共领域ID保留为字符串，不直接复用Node instance ID、Godot数组位置或进程内generation。

## Alternatives Considered

| 方案 | 优点 | 代价/不选原因 |
|---|---|---|
| 扩展现有二进制合同 | 定长载荷、精确预算、已有大量文档 | 新64任务/续局域会重做byte/codec/golden；当前无完整生产binary实现，迁移风险更大 |
| 原样保留JSON v1只加字段 | 改动少 | 无operation去重、迁移、局内schema、锁与云冲突，无法满足完整产品 |
| 引入数据库 | 事务成熟、查询方便 | 增加Godot/Windows打包与云档快照适配依赖；本项目当前主要读写完整档案，无需先引入 |
| 选用版本化JSON v2 | 复用已有访问基础，内容变更可追踪 | 仍需自行实现规范codec/事务/锁/恢复验证；不是因为JSON而自动安全 |

## Consequences / Risks

- 新增serializer、Save adapter、migration和故障矩阵工作量。JSON整档写入有CPU/磁盘成本，保存发生于受控暂停或结算，禁止每帧写盘。
- 历史v1与binary档不混读；未实现且未验证的binary档只提示不支持，不尝试猜格式转换。
- 完整快照意味着Player、Enemy、Spawn、Projectile、Drop、Weapon、SkillDraft、Mission、RNG及未完成事实均有schema和恢复AC；缺任何必需域时续局门OPEN。
- 断电保证不能由FileAccess.flush或进程kill测试推出；Windows原子替换/锁/缓存与断电是独立设备验证项。
- 云冲突不自动按更大revision覆盖。档案身份、分支与可证明祖先优先；并发分支保留两份并让玩家选择。

## Performance Implications

v2总编码上限与捕获帧耗时由配置预算manifest冻结；未冻结时禁止生产启用v2。必须覆盖全内容最大合法快照，不能沿用旧65,536字节或任意填一个新上限。首个实施任务先生成worst-case fixture测量JSON编码、内存、磁盘写回和恢复时间，计入R03/R04/R06。

## Migration Plan

1. 备份v1两槽原字节；只读执行现有校验，双坏/同代冲突保持阻断，不创建空档。
2. 构造新profile ID，首次写入以base revision=0、next revision=1、parent_hash=null执行MIGRATE；迁移record和3×5成长原值。当前v1不具有章节完成事实：新campaign从第一任务开始，旧全局胜利不映射为任何章节通关。向玩家说明这一差异。
3. 新格式使用独立目录；保存迁移来源hash及迁移operation，完整读回后再记录激活marker。marker仅为可验证指针，不是数据真值；崩溃后可扫描迁移receipt恢复同一个profile，不能重复迁移发奖励。
4. 全部迁移故障切点通过才替换生产入口。回滚保留v1备份和v2档；旧程序不能写入v2，也不自动把新进度写回旧档。

## Validation Criteria

- 新旧合法档迁移、损坏/冲突拒绝、重复迁移不重复授予。
- Prepare/UpdatePreparation/CancelPrepare/Start/Suspend/Resume/StageResult/Complete各事务（主动放弃也封结果走StageResult→Complete）在每个IO切点为旧或新完整状态，重复/未知结果处理一致。
- 同tick胜负优先级、首次奖励与下章解锁原子提交；恢复不重抽、不重复消耗。
- Windows进程锁、替换/读回、满盘、只读、强杀、多实例和云分支冲突；最大内容快照预算。

## ADR Dependencies

依赖ADR-0002 persistent root、ADR-0003 runtime、ADR-0004 Steam策略、ADR-0005 PC输入。启用WP02/03/04/06的设计；正式实现仍要求对应GDD独立review及预算/schema齐备。

## Engine Compatibility

Godot 4.7.1/GDScript。已读本地Input/UI参考与当前Save FileAccess/DirAccess源码使用。本ADR不假定新的引擎API；Windows锁和原子替换需平台adapter及真实系统验证。引擎升级后重新验证codec/float转换与文件行为。

## GDD Requirements Addressed

| GDD | 要求 | 本决定 |
|---|---|---|
| save-steam-pc.md | SP01–SP16 | v2身份、事务、恢复与迁移 |
| campaign-flow.md | CF01–CF13 | 首次完成/解锁和结果提交 |
| mission-objectives.md | MO01–MO13 | 六目标事实、终态与快照 |
| save-system.md / settlement-system.md | 先持久化后曝光、uncertain、一次奖励 | v2保留业务语义，格式和新增范围由新profile承接 |

## WP04b implementation evidence (2026-09-11)

Five domain structures/shared invariants and the legacy Stage recovery adapter are implemented locally; see `design/gdd/steam-save-domain-adapters.md` and `production/playtest-evidence/steam-domains-2026-09-11/`. This does not approve a complete commercial snapshot budget or install the v2 durable writer, migration, Preparation/Settlement/Mission owners. `LEGACY_STAGE_PC_V1` freezes spawn viewport and uses fresh logical-identity rebinding, exact engine-commit RNG state, and explicit owner admission. Production remains JSON v1 / legacy mission.

## WP04c recovery contract increment (2026-09-14)

`SteamRecoveryContract` adds trusted-config-relative owner/schema/binding/byte preflight, isolated semantic callbacks and mandatory cross-owner validation; optional Save-domain integration derives identity from the validated root/run. The new adapter payload is explicitly `{binding,state}`, not an implicit reinterpretation of WP04b bare payloads. Complete-row and checkpoint ceilings are explicit test/adapter limits, not release budgets. The commercial responsibility inventory separates persisted pending work from same-tick work required empty at capture. No commercial owner installation, v2 writer activation or Windows certification is introduced. This implementation increment does not inherit a new full design approval; see `production/playtest-evidence/2026-09-14-steam-recovery-contract.md` (limited independent code review APPROVED).
