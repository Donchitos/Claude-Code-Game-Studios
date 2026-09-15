# Steam工程合同检查点 — 2026-09-11

用户范围：完整、完善、Steam正式发售，主要内容20小时以上；本轮工程顺序为关闭PC剩余问题→确定存档策略→确定章节目标合同。

## 本轮交付与状态

| 交付 | 当前结果 | 证据 |
|---|---|---|
| PC输入R1–R8 | 本地CLOSED，fresh senior局部APPROVED WITH ADVISORIES | playtest-evidence/2026-09-11-pc-input-r3-r8.md |
| Save策略 | ADR-0006选择严格版本化JSON v2；双槽/单写者/迁移/云冲突、完整恢复 | ../docs/architecture/adr-0006-steam-save-and-mission-contracts.md |
| Save合同 | 8节、SP01–SP16；START tick0、承诺页、启动恢复、STAGE_RESULT→COMPLETE | ../design/gdd/save-steam-pc.md |
| Campaign合同 | 8节、CF01–CF13；64线性任务、首次奖励、M01-03开放备战、最终M08-08终局 | ../design/gdd/campaign-flow.md |
| Mission合同 | 8节、MO01–MO13；六目标、同tick优先级、BREAK固定/自选顺序、完整快照边界 | ../design/gdd/mission-objectives.md |
| 合同复审 | 两真实分组及fresh senior完成；原问题与BREAK差异关闭，四文档合同基线APPROVED，实施门OPEN | ../design/gdd/reviews/steam-contracts-2026-09-11/ |

## WP04a实现检查点（2026-09-11续做）

编码与章节数据validation基础已实现并独立代码复核：82单元/104集成/70结构检查及5组旧存档成长回归通过。三份机器schema、9组跨编码器golden与64行合成fixture已交付；详见[WP04a报告](playtest-evidence/2026-09-11-steam-schema-foundation.md)。这不是64个可玩任务或完整v2快照。U+0000适配限制、其余五domain及required-owner快照仍OPEN，WP04整体PARTIAL。下一工程入口为这些域的字段/validator/migration和战斗恢复清单，再生成完整最大fixture测预算。

## WP04c 恢复合同增量（2026-09-14）

补齐可信配置相对的owner集合/schema/身份同tick/完整row和checkpoint容量预检、隔离callback和必需联合语义检查，并可安装到七域validator。最终156集成/34单元、15本地回归脚本通过；两路独立code review限定APPROVED。报告 `production/playtest-evidence/2026-09-14-steam-recovery-contract.md`。商业责任盘点为13战斗责任、5持久feature和6目标overlay；全部商业实现及容量仍OPEN。WP04b独立证据已核对（95/764/1905 checks）；会话旧摘要停在WP04a，不再作为当前边界。

下一入口：按责任清单实现 Mission/Stage 六目标定义与恢复状态（优先SURVIVE/BREAK）；完成阶段与fact容量、跨owner pending一致性，再补其余商业owner、完整最大合法slot fixture及ECON/Save v2事务。恢复合同合法只说明相对于已安装合同合法，不能把缺失商业owner改称完整。

## 关键决定

- 当前运行仍JSON v1。JSON v2使用独立profile和规范codec，保留旧成长记录，旧胜利数不映射为章节完成；未知/损坏存档保留并阻止覆盖。
- run准备、承诺offer、完整初始恢复点、保存退出、启动恢复和终局退休分别有明确路径。终态先持久完整intent，再用原身份提交全域after-image；只有COMPLETE确认后曝光奖励。
- 封存结果的持久身份与进程epoch分离。重启不改结果字节、不重算首次奖励；StageResult尚未持久时允许回退最后checkpoint，不能宣称最后一帧已保存。
- 主动目标及时胜利，不套旧12分钟下限。前三任务的备战开放与旧首次结算starter分开；首次grant归Campaign，资源计算归经济owner。
- BREAK的M02-07/M07-07/M08-02允许自选拆除次序，其余固定。顺序改变环境的已应用与待应用状态必须一起保存。

## 下一工程入口及验收顺序

| 顺序 | 具体产物 | 验收证据 |
|---|---|---|
| 1 | WP04内容与domain schema：稳定ID、版本/定义hash、严格codec、validator、迁移；保留完整商业范围 | golden正反例、64任务/grant引用校验、未知/重复/溢出拒绝；规划CSV不得直接runtime载入 |
| 2 | required-owner快照与MISSION阶段/容量：Player/世界/实体/技能/掉落/RNG/备战/任务及队列 | matching-tick capture→restore一致性；缺owner或非法schema拒绝；阶段/生命周期绑定 |
| 3 | 最大合法快照fixture和预算（含RESULT_PENDING双份domain） | 编码/readback/恢复耗时、峰值内存、字节上限；以测量冻结预算，不能借旧binary大小 |
| 4 | ECON-MISSION-01与Settlement/Prep/Drop新profile adapter | 短局胜/败/重玩/零贡献数值矩阵、M01-03唯一解锁、早胜合法、技术故障不丢committed收益 |
| 5 | Save v2实现与Windows持久化adapter | OS锁、所有IO切点、stage/complete前后强杀、同请求重试、迁移与云分支；新格式满足门后切入口 |
| 6 | Campaign/Mission实现并接完整任务闭环 | 新档→准备→目标→结果→首次奖励→退出/恢复→下一任务；先SURVIVE/BREAK验证消费链，再其余目标 |

以上是实现依赖排序，不把第一批闭环作为产品终点。第一章8任务成品和全程试玩继续用于检验内容生产方式与SCOPE-TIME-01，后续完成其余章节/技能/资产/发行要求。

## 尚未关闭

PC极小合法deadzone长度下溢P3；完整七phase/native ABI；Windows物理输入/低配长时性能；新profile schema/预算/adapter/经济数值；真实续局/云档；正式美术音频与20小时通关实证。`battle_ready=false`。

本轮已向旧Save/Settlement/备战/UI/Config/战斗snapshot owners传播新profile边界，并登记作者路由manifest。路由不等于所有owner具体合同已重写，作者static检查不等于generated/runtime/device通过。
