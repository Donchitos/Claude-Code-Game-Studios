# ADR-0007：完整章节游戏运行时与独立开发档案

## Status

Accepted for implementation — 2026-09-14。作者依据用户“先实现完整游戏吧”及本轮明确的文件写入授权执行主线程决定；这是工程实施授权，不是独立设计审查批准、Steam 发行批准或20小时有效内容认证。team-combat 处于 implementation / integration / validation 阶段。

## Date / Last Verified

2026-09-14。核对本地 Godot 4.7.1 参考、现有生产存档基础、Steam 八章规划与364行内容矩阵。本文的实测范围严格区分纯任务状态、生产战斗集成和发行设备验证。

## Decision Makers

用户决定完整可玩优先于继续扩充合同。主线程选择保留 legacy GameRoot 测试并新增 `src/campaign/*` 完整游戏入口；内容作者实现目录和纯任务状态，Arena、Profile、Root/UI 各由本轮对应 worker 实现。作者不代替技术总监或发行负责人签署批准。

## Summary

将八章64任务与角色、构筑、敌人、事件、丹药、挑战、成就落实到独立可校验的 JSON 目录，以 `CampaignMission` 作为六类目标的唯一运行时权威。新增 `CAMPAIGN_GAMEPLAY_V1` 独立开发档案，复用 STEAM_PC 输入与 ProductionSaveSystem 双槽文件基础，不宣称实现 `STEAM_SAVE_V2` 全部协议。

## Context

现有 legacy 运行时和 Steam 合同测试覆盖不同边界，规划CSV也不是可直接上线的配置。继续新增合同不会自动产生完整游戏；另一方面，将64任务换名或把挑战变成累计击杀成就也不能满足用户要求。因此本轮选择实际实现完整旅程，并把尚未完成的商业质量门明确保留。

原规划拥有内容ID、章节顺序和范围。本轮离线编译保留364项来源记录及 `planning_description`，另写可执行机械参数和对应的玩家说明。技能采用本轮固定24模式；参数、描述与实际实现必须对齐，来源记录不应被UI误当作已经实现的效果承诺。局内4主动+4辅助、每项5级及16进化仍属于实际战斗工作，不以目录数量替代玩法。

## Decision

### 内容与加载

`tools/campaign/build_catalog.py` 离线读取规划、生成并验证 `assets/config/campaign_game.json`；运行时只读取JSON，不解析CSV或Markdown。`--check` 比对生成结果与落盘文件，实现可复现检查。顶层schema为1，名称为“灵枢行纪 / Spirit Nexus”。必需集合为 chapters、missions、characters、skills、passives、evolutions、enemies、elites、bosses、pills、events、challenges、achievements，另保留其余规划类别数组。

固定API：

```gdscript
CampaignCatalog extends RefCounted
static func load_catalog() -> Dictionary
static func validate(data: Dictionary) -> Array[String]
static func lookup(data: Dictionary, kind: String, id: String) -> Dictionary
static func localized(row: Dictionary, locale: String) -> String
```

缺失文件、解析失败、结构或引用错误均返回 `{}`；Root须显示内容错误并拒绝开局。`lookup`按稳定ID查集合，禁止用数组序号当持久身份。JSON数字在Godot解析后为浮点，整型语义通过数值与取整验证，不能用包含整型的预期数组直接比对JSON数组。

JSON文件本身不保存 `content_hash`。`load_catalog` 将原始文件UTF-8文本的 `sha256_text()` 注入 `content_hash`；验证忽略这个派生键。Profile/Arena/Root直接消费此值，不重新序列化后重算。内容任何字节修改都会改变绑定，包括空白；旧局恢复应由Profile明确拒绝不匹配内容，不能静默重开或重新抽取。

### 唯一目标权威

```gdscript
static func create(definition: Dictionary) -> Dictionary
static func advance(state: Dictionary, definition: Dictionary, delta: float,
    player_position: Vector2, enemy_positions: Array,
    target_deaths: Array, escort_position: Vector2) -> void
```

`create`返回纯JSON值：kind、elapsed、progress、completed_ids、completion_order、hold、waypoint、escort_hp、player_alive、finished、victory、reason、extraction_ready、extraction_was_inside、pressure。所有位置留在definition或Arena快照中，Mission状态不持久化Vector2、Node或Callable。`progress`是已完成目标数，不是百分比。

Arena负责实际实体、伤害、敌死亡、玩家生死、护送移动和护送HP；每tick先把 `player_alive` 与 `escort_hp` 写入Mission state，再调用advance。敌位置是仍存活敌人的Vector2；死亡事件是 `definition.target_ids` 中真实死亡字符串，退役、越界、对象池回收不是死亡。advance仅改变state，不生成实体、不发奖励、不写存档。暂停时不调用advance，负数/非有限delta忽略。

| 目标 | 真实推进 | 负边界 |
|---|---|---|
| SURVIVE | 达到target_seconds，随后进入target_positions[0]撤离圈 | 提前站在撤离圈不能直接完成，须离开再进入；时间未达不完成 |
| BREAK | 真实target_deaths满足全部target_ids；FIXED按顺序，PLAYER_CHOICE按实际任意顺序 | 未激活FIXED锚点由Arena保持免伤；乱序死亡不累计；重复事件去重 |
| CLEANSE | 玩家在当前圈且cleanse_enemy_radius内无活敌，hold累至hold_seconds后推进waypoint | 离圈或敌人进入暂停但保留hold；边界上的敌人也阻断 |
| HUNT | 所有指定target_ids真实死亡；支持多个目标 | 普通怪或其他追猎目标死亡不计入；重复事件去重 |
| ESCORT | escort_hp>0，玩家接近护送物，护送物到达当前waypoint，依序推进 | 不可跳路标；玩家离开则不得推进；HP归零优先失败 |
| BOSS | 指定boss_id死亡，计入唯一target_ids | 其他Boss死亡不算；第8章第7任务不触发终局 |

当前BREAK/CLEANSE/ESCORT/SURVIVE目标ID为 `任务ID:T1…Tn`，HUNT当前单目标为 `任务ID:HUNT`；未来多个HUNT可用 `任务ID:HUNT1…HUNTn`，调用方始终读数组，不自行拼ID。BOSS为目录boss_id。PLAYER_CHOICE按最后破坏的锚点索引计算 `pressure = (index+1)/target_count * order_pressure_max`，保存实际completion_order；Arena消费压力以改变后续敌群节奏。

终态优先级明确为：已有终态保持不变；玩家死亡失败；护送物死亡失败；非法定义失败；累计elapsed达到或超过timeout失败；最后才评估目标成功。死亡与胜利同tick由失败获胜，不能靠回调顺序决定。Root/Settlement只在Mission完成后请求Profile结算。

### 解锁、挑战、成就和经济

64任务线性前置，从START可达；`unlock_after`为已完成主线数量，每章8任务、2场景；首次授予ID写在mission.first_grants，Profile负责首次完成与奖励同次提交及幂等。失败和重玩不能重发首次奖励。

24挑战保留真实关卡配置：mission_id、enemy_multiplier、hazard_multiplier、max_skills、allow_pills。Root把challenge_id写入run.loadout，Arena应用限制和压力；仅真实挑战胜利更新 `challenge_wins[id]`，累计击杀不能代替挑战通关。挑战不得成为主线解锁钥匙。

60成就保留原中文名。`rule={stat,target,id?}`支持主线completed，及按ID的character_win、evolution_id、challenge_win；由Profile映射至character_wins、evolution_ids、challenge_wins字典。safe_wins/risk_wins分别要求本局确实选过对应事件并取得胜利。Arena暴露safe_choices/risk_choices；普通events_taken总数无法替代这两个语义。

12丹药有stat、amount、cost、duration，比例增量用小数且玩家说明用百分比，rerolls为本局一次额外刷新。前90秒效果必须由Arena计时移除，暂停不得消耗时限；刷新丹药必须接入真实刷新操作。24事件safe/risk均有reward、damage、pressure，由实际选择消费，不能仅显示不同文字。

### 三阶段 Owner 工作仍须实施

| 阶段 | Owner | 必须完成的实现与证据 |
|---|---|---|
| 1 内容/目标与战斗 | Catalog/Mission + Arena/Combat | 校验JSON、六目标单一权威、24模式/24行为/9Boss、真实实体死亡、64任务可达及正负边界 |
| 2 持久与旅程 | Profile + Root/UI | 独立档案、首次奖励幂等、保存退出/继续真实快照、挑战和按ID成就、双语菜单与结局 |
| 3 集成与发行质量 | 主线程整合 + QA/平台负责人 | 普通新档safe无丹药完整旅程、暂停恢复和故障路径、Windows/Steam输入与保存、性能、资源权利、美术音频、时长玩家实证 |

这些Owner不是文档占位批准；只有对应代码和实际证据完成，才能报告对应层的完成。第三阶段并不因本ADR Accepted而自动通过。

## Consequences

既有legacy GameRoot及其测试保留；新入口不把legacy测试PASS挪作章节运行证据。独立开发档案避免把新章节状态写入旧格式，允许完整玩法持续迭代。代价是同时维护两条运行边界，商业v2迁移/云冲突/Windows进程锁仍须后续真实实现和验证。

初版SURVIVE采用约一分钟至两分钟的可调时段，其余目标主动完成，不按13–15分钟机械填表。没有20小时主线有效时长实证；不足时应增加有效体验，不能延长等待或强制重刷来充数。当前可绘制战斗表现也不自动等同最终商业美术。

## ADR Dependencies

沿用ADR-0004 Steam-first与ADR-0005 STEAM_PC方向；复用ADR-0003已存在的ProductionSaveSystem双槽基础。ADR-0006保留商业STEAM_SAVE_V2目标和后续责任；本决定没有废弃该协议，也没有把其未实现Owner标成完成。新开发档案不是v2兼容实现，不自动迁移legacy档案。

## Engine Compatibility

Godot 4.7.1 / GDScript / Core。已读 `docs/engine-reference/godot/VERSION.md` 和 `current-best-practices.md`，使用RefCounted、JSON、FileAccess、Vector2、String SHA256等已有API。实际命令使用 `/Applications/Godot.app/Contents/MacOS/Godot`，引擎标识 `4.7.1.stable.official.a13da4feb`。引擎或目录序列化改变后重测数字转换、哈希与恢复；Windows文件锁/Steam Cloud证据不能由macOS headless代替。

## Validation Criteria / Evidence

2026-09-14内容Owner已实际执行：

- `python3 tools/campaign/build_catalog.py --check`：CATALOG_REPRODUCIBLE，364条来源内容、64任务。
- Godot headless `tests/integration/campaign_content_test.gd`：1170 checks，0 failures。覆盖64任务/16场景可达与解锁、六目标成功和负边界、错ID/重复死亡/乱序锚点/死亡同tick/超时、净化中断、护送HP、多个HUNT、JSON快照恢复、非法目录与引用、精确文件哈希。
- Catalog/Mission分别 `--check-only` 编译成功。

Profile追加实测581 checks/0 failures：事件胜利收益同事务、fullscreen持久化、准确旧6设置的真磁盘受控迁移。Save序列化仅改full_precision，旧SaveSystem/5强杀切点/FaultSurface/SteamDomains95/Recovery156重跑通过。Arena lossless float编码另获独立engine真磁盘验证：/tmp双槽237tick→全新Storage/Profile→恢复后200tick到437 exact通过，11恶意codec输入拒绝；证据来自真实IO与编码，不仅是JSON完整精度。

测试的JSON roundtrip按值递归比较数字语义，随后继续同一个任务直到终态；不要求JSON解析后int/float运行时类型一致。上述实测是内容/纯目标状态证据；生产Arena是否逐tick调用此权威、真实输入操作、Profile IO故障、商业资源质量与平台门由对应Owner报告，不在这里虚构通过。

## GDD Requirements Addressed

| 来源 | 要求 | 实现路径 |
|---|---|---|
| design/steam-1.0-product-scope.md | 完整八章、构筑、角色、敌人、事件、丹药、独立挑战 | 离线目录与并行生产运行时，商业完成条件继续保留 |
| design/steam-1.0-campaign.md | 64任务前置、六目标、最后两Boss区分 | 明确ID、目标参数、Mission权威与遍历测试 |
| design/gdd/mission-objectives.md | 真实目标事实、顺序、边界、恢复 | CAMPAIGN_GAMEPLAY_V1独立实现与本文显式同tick优先级 |
| design/gdd/campaign-flow.md | 首次解锁、结果与任务状态 | 目录前置/first_grants驱动Profile持久结算 |
| design/gdd/save-steam-pc.md | 商业持久边界 | 保留v2责任，明确本次开发档案不代表v2协议完成 |

## Alternatives Considered

继续只补合同不能交付用户要玩的完整旅程。把64任务套同一生存计时或把可选挑战改为累计击杀记录会削减已授权范围，已明确排除。直接让运行时读规划CSV会把未实现叙述当运行配置，因此采用离线转换、结构验证与有参数的独立JSON。
