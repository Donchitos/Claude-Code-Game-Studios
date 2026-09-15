# Steam 1.0 系统迁移与首批工作包

日期：2026-09-11。状态：Working Baseline / Author Planning Only。关联[商业范围](../design/steam-1.0-product-scope.md)、[章节任务](../design/steam-1.0-campaign.md)、[内容矩阵](steam-1.0-content-matrix.csv)。

本表记录T03设计影响与后续工作包状态；不把规划条目当生产ABI、数值或实现。`L01–L32`对应原系统索引1–32；`ST-S01–09`是新增商业工作域，不是已批准系统或运行participant。新域的拆分仍可在系统设计时合并，但责任不能遗漏。

## 原32系统逐项处置

| 工作ID | 既有系统 / owner GDD | 处置 | 商业版必须补齐的设计 | 验收关联 |
|---|---|---|---|---|
| L01 | GameRoot / game-root-scene-flow.md | 修订 | 章节入口/任务结果/保存退出/继续，正确区分任务胜利与全局结局；保留persistent root | R03/R04/R09 |
| L02 | InputSystem / input-system.md + input-steam-pc.md | 收敛并扩展 | R3–R8局部独立通过附P3；接着新屏幕/改键/手柄旅程；mobile future-port继续隔离 | R05 |
| L03 | SpatialGrid / spatial-grid.md | 保留核心，扩展workload | 锚点、护送目标、区域与更多技能的查询/注册域；不直接加cap | R06 |
| L04 | Object Pooling / object-pooling.md | 保留核心，扩展族 | 目标实体、构造物、VFX生命周期和完整压力表 | R06/R09 |
| L05 | Config/Data / config-data-system.md | 扩展 | 稳定内容ID、章节/任务schema、版本校验、技能扩池、生成工具、停用兼容 | R01/R03 |
| L06 | Stage & Map / stage-map.md | 修订 | 16场景、环境危险、任务锚点、短护送路线与玩家相对世界的兼容；无隐式地图边界回退 | R01/R06 |
| L07 | RNG / rng-system.md | 扩展上下文 | 新任务身份、内容revision、恢复可重放；事件池变化不污染战斗流 | R03/R04 |
| L08 | Player / player-controller.md | 扩展 | 8角色起手/被动、各perk消费、输入租约；属性边界保持owner一致 | R02/R05 |
| L09 | Enemy / enemy-system.md | 扩内容与审核 | 24行为、目标选择、控制免疫、目标任务与退役一致性 | R01/R02 |
| L10 | SpawnDirector / spawn-director.md | 修订 | 按任务目标调度；追猎/护送/破阵的生成、召唤与目标存续 | R01/R06 |
| L11 | Damage / damage-system.md | 扩展 | 多目标受击、锚点/护送物HP、角色被动、反射/状态、同tick终态优先级 | R02/R09 |
| L12 | Buff / 并入damage-system.md | 继续合并 | 24辅助、12丹药、角色被动的叠加/来源和上限，不另生第二数值owner | R02 |
| L13 | Projectile / projectile-system.md | 扩展 | 回旋/链式/反射/延迟/召唤弹道、T+1身份、目标过滤与预算 | R02/R06 |
| L14 | Weapon / weapon-system.md | 扩展 | 24主动/16进化、5级消费、原六技能语义迁移与新能力工作量 | R01/R02 |
| L15 | SkillDraft / skill-draft-system.md | 扩展 | 进度过滤、24+24候选、保底/刷新/进化、4+4槽不变；全部合法域重新推导 | R02/R03 |
| L16 | Drop / drop-leveling-system.md | 扩展 | 主线一次奖励与重复掉落分离；不同任务目标奖励owner | R02/R03 |
| L17 | RiskChoice / risk-choice-system.md | 扩展 | 24模板，教学开关，非生存任务触发时点与完成/退出归属 | R01/R02 |
| L18 | Boss / boss-state-machine.md | 扩展并修订调度 | 9Boss，指定任务死亡事实，不再所有任务固定720秒出Boss | R01/R09 |
| L19 | Elite / elite-enemies.md | 扩展 | 8精英，主线/风险/挑战来源身份与奖励去重 | R01/R02 |
| L20 | Leveling/XP / drop-leveling-system.md | 同owner修订 | 任务长短不同的升级节奏、成长债务、候选耗尽，不直接套线性runtime曲线 | R02 |
| L21 | Progression / progression-tree.md | 保留3×5并扩联结 | 每perk接入；属性与章节/角色解锁分开，旧档命名迁移 | R02/R03 |
| L22 | Zhangtian / zhangtian-bottle.md | 机制保留、原创化和扩展 | 灵药备战12效果、任务间消费、reservation恢复、无需真实时间等待 | R02/R03 |
| L23 | Save / save-system.md + save-steam-pc.md | ADR-0006选择JSON v2 | 版本化域、局内保存、两阶段终局、迁移/云冲突合同已写；schema/预算/adapter待实施 | R03/R04/R10 |
| L24 | BattleUI / battle-ui.md | 扩展 | 六目标进度、目标受伤、构筑/状态说明、信息优先级、各类modal | R05/R07 |
| L25 | Settlement / settlement-system.md | 修订 | 任务结果与章节结果分开、首次授予、解锁、退出/故障与exact-once | R02/R03 |
| L26 | Home / home-ui.md | 扩展 | 章节地图、角色/任务入口、存档继续、明确下一目标 | R01/R05 |
| L27 | Prep / prep-ui.md | 扩展 | 角色/任务/药品信息、预检、取消/不确定态与重复提交 | R03/R05 |
| L28 | Audio / audio-feedback.md | 从合同到正式制作 | 全内容SFX/BGM/voice预算和混音、重要预警优先；不假定新增内容仍能用旧voice表 | R06/R07 |
| L29 | VFX / 未有独立GDD | 首发必需，新增设计 | 状态/危险/攻击/奖励的正式表现与预算；几何占位不能证明完成 | R06/R07 |
| L30 | Tutorial / 未有独立GDD | 首发必需，新增设计 | 首章渐进教学、后续新机制提示、跳过/重看/存档标记 | R08 |
| L31 | Perf & LOD / 未有独立GDD | 首发必需，定义性能域 | Windows低配与完整frame workload；名称含LOD不代表重新加入旧已移除的模拟LOD | R06 |
| L32 | Analytics / 未有独立GDD | 收敛为开发验证 | 本地可导出任务/时长/流派报告；不默认接远程跟踪SDK或强制联网 | R02/R08 |

本表中的GDD短名均相对`design/gdd/`，不存在的明确标记未有。现有32项中“Designed”“Merged”不因本表升级审批状态。

## 商业版新增工作域

| ID | 域与归属 | 需冻结的关键规则 | 前置 |
|---|---|---|---|
| ST-S01 | Campaign Flow / 章节推进 | 任务图、前置、首次完成/解锁、重试、章节节点，稳定内容ID | L01/L05/L23/L25 |
| ST-S02 | Mission Objectives / 任务目标 | 六目标状态机、计时、失败/完成优先级、目标实体与恢复 | L06/L09/L10/L11/L23 |
| ST-S03 | Character Loadout / 角色装配 | 8角色起手/被动、可用条件、投影、换角与存档 | L08/L11/L14/ST-S01 |
| ST-S04 | Challenge Rules / 难度挑战 | 3难度/24挑战、规则modifier、正常主线不受可选完成约束 | ST-S01/ST-S02/L05 |
| ST-S05 | Codex & Achievements / 图鉴成就 | 内容发现、配方揭示、60条件、离线记录与补发，不重复授予 | ST-S01/L14/L23/L25 |
| ST-S06 | Frontend & Settings / 前端设置 | 11类屏幕、改键、输入焦点、语言/可读性/窗口配置；各业务owner仍独立 | L02/L24/L26/L27 |
| ST-S07 | Narrative Nodes / 章节节点 | 32节点意图、玩家选择/反馈、剧情文案与可跳过呈现，不锁额外主线 | ST-S01/ST-S06/L23 |
| ST-S08 | Steam Platform / 平台发行 | 构建上传、成就、云档、离线/Overlay/更新；机器设置与进度分离 | L23/ST-S05/ST-S06 |
| ST-S09 | Localization & Asset Pipeline / 文本资产 | 中英文键、字体/排版、内容ID到资源、来源台账、导入和缺失阻断 | L05/L28/L29/ST-S06 |

ST-S01/02已有campaign-flow.md、mission-objectives.md八节合同，关联save-steam-pc.md和ADR-0006；两独立组复核与fresh senior综合完成，四文档合同基线APPROVED，实施门OPEN。其余7域尚无系统GDD。系统数量记为**既有32 + 商业新增9（2域已写合同、7域待设计）**，不记为41项已完成设计。设计时允许调整拆分，同时保持ID别名/迁移记录，不以删行掩盖范围。

## 既有机制到商业内容的迁移入口

| 既有内部工作名 | 商业规划ID / 工作名 | 处理 |
|---|---|---|
| 青元剑气 | S1-A01 巡光飞剑 | 继承自动飞剑方向；穿透/索敌规则owner复核 |
| 火弹术 | S1-A04 流焰珠 | 继承爆破方向；新地带和进化不是仅改名 |
| 玄铁飞盾 | S1-A07 回环刃 | 继承环绕防御方向；反击被动另设计 |
| 机关傀儡 | S1-A10 机关弩台 | 继承召唤方向；部署/退役/目标过滤另设计 |
| 雷爆符 | S1-A13 鸣雷签 | 雷击到链式能力有行为变更，按新工作量处理 |
| 乙木灵藤 | S1-A16 缚根环 | 继承控制方向，Boss免控替代效果需明确 |
| 青元/长春/大衍3分支 | S1-TREE01/02/03 锋意/守元/灵识 | 只给原创命名方向，旧存档域和分支ID不变，最终迁移走Save |
| 掌天瓶备战 | L22 灵药备战 / S1-PREP01–12 | 保留选择/消耗/恢复目标，专有名词清理与正式素材另验收 |

P2实现“六技能基础”应按这六个映射验证，不等于矩阵编号A01–A06；章节解锁继续遵循矩阵，开发提前实现不代表玩家提前获得。

## 首批工作包与依赖

| ID | 阶段 / 交付 | 可验收结果 | 前置 / 状态 |
|---|---|---|---|
| WP00 | P0：商业范围+章节+内容ID+迁移 | 364行唯一ID、64任务可达、引用完整；SCOPE-TIME-01明确OPEN | 本轮作者交付；独立评审未运行 |
| WP01 | P1：PC输入收敛 | R3–R8逐项处置、原反例回归、完整UI路径与独立复审 | R1–R8本地CLOSED / fresh senior APPROVED WITH ADVISORIES；极小阈值P3/Windows/完整ABI/性能仍OPEN |
| WP02 | P1：Save策略ADR | 两种候选对任务/备战/进度/云档的能力对比、具体选择、迁移与故障矩阵 | ADR-0006已选择JSON v2；Save合同基线获独立senior APPROVED；runtime仍v1 |
| WP03 | P0→P1：章节/目标owner设计 | ST-S01/ST-S02八节GDD与实体/状态/结果语义；列清6目标边界 | 两份八节GDD及ADR/Save合同基线独立senior APPROVED；实现门OPEN |
| WP04 | P1：内容数据管线 | schema/内容修订/ID校验、候选池、资源引用、停用迁移 | PARTIAL：WP04a codec+Campaign/Unlock schema已独立代码复核，82/104/70检查通过；其它5域/owner快照/真实内容/预算仍OPEN，不得直接导入规划CSV |
| WP05 | P2：六技能消费链 | 六旧方向映射、各等级、合法候选、进化/掉落完整正负例 | WP04+L11/L13/L14/L15合同 |
| WP06 | P2：任务与备战闭环 | 新档→任务→备战→胜负→首次奖励→重启→下一任务，无重复消费 | WP02/WP03/WP05；先SURVIVE+BREAK，再其它目标 |
| WP07 | P1→P3：正式呈现规范 | 角色/敌人/地形/特效/声音样板及预算，PC清晰可读 | 规范可早开始，批量制作依赖WP06稳定行为 |
| WP08 | P3：第一章成品 | 8任务、2场景、正式资产与全链路；首次玩家章节时间/重复感报告 | WP06/WP07；决定后7章生产配方，关闭或整改SCOPE-TIME-01的预测风险 |
| WP09 | P4：第2–8章生产 | 按章内容清单全部实现并测试，原章无回归 | WP08；每章增量预算，不能一口气扩满全部容量 |
| WP10 | P1→P6：Windows/Steam发行链 | 持续Windows包、硬件/存档/性能证据、商店和RC门 | 设备/后台需可用；与内容迭代同步 |

执行顺序：WP01先关闭现有明确缺陷；WP02与WP03设计输入互相协调，先约定所需持久语义再冻结格式；WP04→WP05→WP06→WP08→WP09。WP07/WP10在相关条件具备时穿插开展，不等待全内容结束。

WP00只完成P0的作者基线，不能宣称P0正式gate已通过。WP01本地整改已闭合，WP02/WP03合同已写且复核原问题关闭；下一工程入口为WP04的schema/fixture/预算与owner合同传播，然后实现Save v2和任务闭环。暂不列不具资源依据的周数或发售日期。

## 合同传播清单

每个新增域正式设计时，需逐项完成：主owner GDD → 受影响owner GDD → `design/registry/entities.yaml`权威事实 → generated schema/manifest与golden → `systems-index.md`状态 → session state → 对应代码/验证。移动端仅保留future-port要求，Steam设计的变化不证明移动兼容。

registry头部与steam-save-mission-contracts-v1.json记录新profile路由、操作/状态/域及OPEN门；该manifest为作者规划，非generated产物；没有注册364项为生产实体，没有修改容量/byte大小/已有ID。文档命名或状态更新不得重新计算并宣称先前独立review批准仍有效。
