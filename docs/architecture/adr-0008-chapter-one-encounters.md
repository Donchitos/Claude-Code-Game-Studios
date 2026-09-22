# ADR-0008：Campaign首章布局与可恢复遭遇

## 状态

2026-09-15，用户授权B包后的工程决定；本地验证通过，独立复审待做。仅适用ADR-0007的Campaign开发入口，不改变STEAM_SAVE_V2与既有StageSpatialConfigV2合同。

## 决定与归属

- `CampaignEncounter`是Arena内部无独立Node生命周期的执行器。Mission继续独占目标进度与胜负；Catalog校验配置，Arena依次完成战斗、Mission、Encounter，再允许取快照。
- 首章8关复用2个固定布局：路线、圆形障碍、风带、根区。01–03配置有限遭遇阶段；04–08专属任务改造留在C包，首章不再周期抽取全表精英。
- B支持ACTIVE_TICK、ANCHOR_PROGRESS、WAYPOINT。阶段最多16、每阶段4行、每行8次；间隔至少15 tick。未实现枚举拒绝加载。
- 每行保存已消费次数；阶段保存触发tick；另存skipped、tutorial和last_tick。last_tick保证同tick重复调用不再产生普通敌或根区。容量满或无合法候选时消费普通生成并记skipped，恢复不补发。
- 固定60Hz active tick；接受的近似1/60输入归一为1/60，暂停/选择不推进。根区使用72/120/240 tick预警/生效/间歇，沿用现有Combat伤害规则。
- 风带只缩放主动移动速度，顺/逆/横为1.15/0.9/1，不推移静止玩家或护送目标。教学提示为非模态，不阻止终态。

## 快照与兼容

首章战斗快照schema为`CAMPAIGN_CHAPTER1_V2`，其它章节保持原schema；外层仍是`CAMPAIGN_GAMEPLAY_V1`开发档案。content_hash、definition_hash、RNG与numeric_bits继续沿用。联合验证固定布局、触发阈值、已消费次数和matching tick，拒绝可导致恢复重触发的矛盾状态。没有引入商业Save v2 owner或伪造旧ABI。

改目录前已导出可运行A版PCK，hash列入已知旧版。新版在设置迁移前只读拒绝旧进行中任务；玩家回创建任务的保留版本完成或主动放弃后再升级。不重写旧run hash，不自动弃局。

## 边界与代价

生成点从有限地图周缘按玩家相对方向抽样，距离至少620，最多16次尝试，避开障碍。此实现保证距离和方向，尚不保证任意窗口/缩放下都在视野外；较大窗口的可见生成需后续镜头/生成几何整改。不得冒称实现正式Stage的视野外环合同。

保留旧XP曲线。首章经验实验、04–08专属阶段、关键目标延迟生成容量、关闭根区掩码不在B版已实现状态中。教学/布局采用几何占位表现。

## 验证

见[实施证据](../../production/playtest-evidence/2026-09-15-package-b.md)。覆盖真实磁盘保存恢复、200 tick连续性、真实A版PCK兼容、三关新档顺序旅程及Mac图形截图。没有新独立verdict、真人试玩或Windows/Steam验证，battle_ready=false。

## 2026-09-15 C包扩展：04–08

用户明确继续C包，新增`CampaignChapterOne`作为Encounter内部辅助执行器，仍由Arena拥有状态，不新增全局系统或独立Mission权威。目录与B不同，保留实际B PCK并加入已知hash保护；外层开发档案和首章快照schema名称不变，content/definition hash严格隔离版本。

- 新增CLUE_PROGRESS和CLEANSE_HALF；后者以区域序号与hold_seconds的一半为阈值，完成该区后仍保持已触发，不在hold清零时重置。
- `encounter.chapter`闭合11字段：clues、hunt_spawned、retry、root_mask、boss_phase、first_warning[3]、attacks[3]、hits[3]、kill_tick、landings[最多2]、error。未启用C的任务不能携带C状态/定义。
- 04线索在step尾按顺序接触；第1处机缘延后到升级队列清空才显示，第3处才生成指定E01，保留原target_id。普通敌最多占cap−1；若其它实体占满，最多60次active tick重试，耗尽后暂停并报错，失败状态拒绝持久化，保留上次可靠档案，不判胜利或自动弃局。
- 04关闭35秒机缘兜底，候选严格为已开放RISK01–03。风险数值沿用目录；有限遭遇不依赖周期生成计时，因而压力应用于之后生成敌人的HP/伤害倍数（1+pressure），不追溯已出现敌人，不改阶段已消费索引。UI明确说明此含义。
- 07任务进度与root_mask在同一step提交；删除已关闭区域的现存预警/生效zone，并禁止未来生成。每个布局zone携带layout_root索引；下一锚点只有下一个战斗step才可能被攻击。
- 08按HP选择三阶段，无新增免伤门；预警zone和实体落点tick一起保存。第二阶段两次落点，第三阶段一次扑袭加三片根区。hits记录当前Boss阶段的玩家受伤次数（包含场景伤害，并非仅Boss命中归因）；kill_tick记录Boss实际死亡tick。
- 06明确配置一次E01行并校验次数；普通/精英非关键遭遇在无合法候选或满cap时仍可记跳过，不为生成它们阻止撤离。任务必需的04猎物使用上述保留名额/重试协议。

C包保留旧经验曲线与B的有限周缘生成几何，不解决任意窗口视野外保证。完整证据见[2026-09-15 C包报告](../../production/playtest-evidence/2026-09-15-package-c.md)。独立verdict、真人、Windows、Steam、商业Save v2仍未补齐。

## 2026-09-15 D整改待独立复测

D-S01：CampaignProfile.save_run在任何写入前验证Arena恢复语义及当前run的seed/loadout；失败返回INVALID_BATTLE_CHECKPOINT，保持双槽不变。错误页提供重新加载已保存进度，不自动弃局。
D-S03：Mission在有效active tick计时后处理死亡，保持死亡优先于超时，与Arena.elapsed一致。
D-S02/D-S04：战斗HUD限制两行加生命/悟性条，构筑与完整提示移入暂停页；当前线索/活猎物共享navigation_target，撤离开放显示金色指引和方向/距离。没有新增持久字段或配置hash变化。
自动/图形验证见production/playtest-evidence/package-d-fix-2026-09-15；P00仅本人自报玩完，新增真人1、新玩家0，不能代替至少3名新玩家。独立复测待返回，D OPEN，battle_ready=false。

### D整改复审状态更新

2026-09-15 D整改独立复审：3名真实专家全部返回后fresh资深综合APPROVED WITH SUGGESTIONS，仅限D-S01～04；四项原缺陷限定关闭，隔离Campaign开发持久档可开展新玩家探索测试。P00本人自报完成1名，新玩家0；D总OPEN / In Review，battle_ready=false。剩余至少3新玩家、延期XP/3秒间隔/任意窗口视野外生成、完整恢复矩阵和平台/产品门槛。当前入口build/package-d-fix-2026-09-15/开始D修订版试玩.command；证据production/playtest-evidence/2026-09-15-package-d-fix.md与package-d-fix-2026-09-15/senior-report.md。以下旧D限制为历史，被本次限定放行取代。
