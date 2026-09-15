# Steam Save / Campaign / Mission — 独立 Senior Design Review

日期：2026-09-11。审查身份：fresh creative-director。审查范围：ADR-0006、三份新合同、八章产品任务输入、相关 owner 路由与规划 manifest。未审本轮 PC 输入源码或其工程验收。

**Verdict：NEEDS REVISION。原两组首次报告的七组去重合同 blocker 已关闭；本次独立综合新增一个 P2 产品与 Mission 规则冲突。** JSON v2、终局两阶段事务和章节首次授予方向可保留，不需要推翻架构。不能在这个跨文档差异尚未解决时称本轮全部合同设计通过。

Specialists consulted：两名真实独立工作组审查者，分别覆盖 persistence / Godot-engine / performance / QA，以及 game / systems / economy / UX / QA；本 senior 读取其全部四份报告后另作综合。没有把一名审查者覆盖的多个领域冒充多名已启动专家，也没有模拟额外专家。

Re-review：同一轮首次独立评审内的整改后综合。两组 initial 均建议 NEEDS REVISION，followup 均确认其原 blocker 关闭、未发现新增阻断；下列新增项来源为 creative-director。

## Completeness

| 文档 | 八节 | 评价 |
|---|---|---|
| save-steam-pc.md | 8/8，顺序符合标准 | SP01–SP16 具有可观察预期；预算、设备与 schema 门明确尚未执行 |
| campaign-flow.md | 8/8，顺序符合标准 | CF01–CF13 区分图/事务/普通主线可达/适配启用门 |
| mission-objectives.md | 8/8，顺序符合标准 | MO01–MO12 给出六类目标、终态 oracle、快照与 admission gate；自由破阵顺序尚未表达 |
| ADR-0006 / steam-1.0-campaign.md | 不套 GDD 八节模板 | 分别为架构方向与产品内容输入，不冒充完成实现的系统合同 |

CF08 的首名角色 + safe + 无丹药普通主线可通关是产品验证门，不能以任务图连通替代。SP11/MO12 依赖未冻结预算与 owner，不因暂缺数值成为虚假 AC，但当前绝不能标 PASS。

## Dependency Graph

逐项核实文件存在：

- Save：save-system.md、game-root-scene-flow.md、settlement-system.md、campaign-flow.md、mission-objectives.md、progression-tree.md、zhangtian-bottle.md、config-data-system.md；ADR-0006 存在。全体 required snapshot owner 仍需正式列入实施 manifest。
- Campaign：mission-objectives.md、save-steam-pc.md、game-root-scene-flow.md、settlement-system.md、config-data-system.md、home-ui.md、prep-ui.md、progression-tree.md 均存在；商业来源实际为 `design/steam-1.0-campaign.md`。
- Mission：campaign-flow.md、save-steam-pc.md、game-root-scene-flow.md、settlement-system.md、config-data-system.md、stage-map.md、enemy-system.md、spawn-director.md、damage-system.md、boss-state-machine.md、battle-ui.md、rng-system.md 均存在。
- Character / Codex / Narrative 的独立 GDD 尚未建立，Campaign 已明确交 ST-S03 / ST-S05 / ST-S07 追踪。不存在的实现依赖没有被虚报完成。
- 未发现 `design/gdd/game-concept.md` 或 `design/narrative/`；本次世界观依据为当前 Steam 商业范围与八章故事，不臆测额外 lore 限制。

Save、Settlement、GameRoot、Config、Prep、Home、Progression、Zhangtian 及目标/快照 owner 已有新 profile 路由与 fail-closed 说明。它们是双向认领和实施前置声明，不等于各 owner 的 schema、validator、快照或 adapter 已写完。registry 头部与 `steam-save-mission-contracts-v1.json` 同样明确 `AUTHOR_CONTRACT_ROUTE_NOT_GENERATED`、runtime JSON_V1 / LEGACY、九组 implementation gates OPEN、battle_ready=false；没有把规划记录伪装成 generated ABI。

## Required Before Contract Approval

### D01 — [P2][creative-director] 两个破阵任务要求玩家选择拆除顺序，但唯一 BREAK 合同禁止该行为

证据：

- `design/gdd/mission-objectives.md:26` 只定义 `ordered_target_ids`，要求按定义次序推进，并明确非当前锚点不接受任务伤害推进；`:65` 只允许 matching 当前 target 推进索引。
- `design/steam-1.0-campaign.md:155` 的 S1-M07-07 将“同时压力下选择拆除次序”作为任务差异；`:168` 的 S1-M08-02 要求“利用此前获取的信息选择锚点顺序”。
- 相同差异也记录于 `production/steam-1.0-content-matrix.csv:174`、`:193`，不是单份过期注释。

反例：任务有 A、B、C 三锚点，玩家依据当前压力先选 B。按产品任务差异，这应是有效顺序选择；按唯一现行 BREAK 合同，A 若为当前锚点，B 不接受推进，玩家不能实施该选择。把配置中的固定次序换成 B、A、C 只是作者换了预设，仍没有让玩家作选择。

影响：两任务的差异化玩法无法按现有合同交给程序实现；若默认为自由顺序，会违反 Mission 进度与恢复规则；若默认为固定顺序，会删去产品已写的玩家决策。该差异与 snapshot schema 或平台实现暂缺无关，是两条已选文本要求直接冲突。

最小关闭条件：作者明确二选一并传播至 Mission、产品任务表和 CSV。可将两任务明确改为固定次序下的路线/输出窗口选择；或保留顺序选择，给 BREAK 增加显式模式，定义合法事实、多目标同 tick 的稳定处理、进度表示、快照恢复和 AC。不能只把“ordered”改名而继续保留非当前目标拒绝规则。此报告不替作者改主文档。

当前 P0=0、P1=0、P2 blocker=1。修正 D01 后应做针对性独立复核；原已关闭项不因该产品差异自动全部重开。

## 原问题逐项裁定

| 去重问题 | 当前证据 | Senior 裁定 |
|---|---|---|
| sealed epoch 与重启身份矛盾 | Mission :55 将持久 result 与实时 Delivery 分开；Campaign :27 pending 不重新计划；Save :63–79 恢复原 intent | CLOSED |
| START / RUNNING / RESULT_PENDING boot 不闭合 | Save :61 tick 0 全 owner checkpoint；:63 原 COMPLETE 请求持久化；:69–79 状态分派和 crash 边界 | CLOSED |
| PREPARED 取消绕过 offer 承诺 | Save :59 UPDATE_PREPARATION 先持久曝光；取消须当前 revision 下的 owner 资格；:119 SP14 | CLOSED |
| 必需 current_run domain 与 null shape 冲突 | Save :37 统一 wrapper；:120 SP15 验空档及退休档 | CLOSED |
| 坏事实 technical 与无结果 oracle 相反 | Mission :38、:46、:89 区分外部 stale 与当前权威批次损坏，整批验证后应用 | CLOSED |
| 失败公式仍授予 unlock | Campaign :51 明确 first_completion 两分支；:78 CF11 覆盖失败/重玩/首次成功 | CLOSED |
| 快速胜利 / M01-03 开放与旧 Settlement 冲突 | Campaign :39–45 选择 STEAM_MISSION_V1，排除旧 43200 tick 下限和首次胜败 starter；CF12/13 与 owner 路由 fail closed | CLOSED，具体经济矩阵仍 OPEN |

两组 followup 提出的放弃接纳顺序、STAGE_RESULT 的 COMMITTED 不等于奖励到账、技术故障保留既有 committed stones/pages，也均已正确闭合。Save kind 无独立 ABANDON 写入路径，GameRoot 接纳未 sealed 的请求后封 ABANDONED，再走统一 stage / complete；未发现与 Mission/ADR 相反的二次提交入口。

SaveResult 已包含 INVALID_CONFIG；SP03 使用 COMPLETE；float64 位模式方向有 1.0 示例；读取组合区分坏档、未来 schema、IO 失败与缺失；同 branch/revision 的异 hash 云候选不会按 branch_id 去重。没有因此再开相同 blocker。

## 独立事务与边界检查

- 令 stage base 为 r：STAGE_RESULT 写 r+1，持久 intent 的 COMPLETE base 固定 r+1，COMPLETE 写 r+2；pending 禁止其他 mutation，因此该 base 不会被合法插队交易改变。
- COMPLETE 的 after-image 内 current_run.payload.run=null，不再携带 terminal_intent，hash 不递归。stage 与 complete operation 在首次 IO 前各自固定；同进程 uncertain 必须 reconcile。
- stage 前崩溃只证明旧 checkpoint，允许回退；stage 后恢复原 intent；complete 后先选新 head，旧槽 pending 不能再次发奖。文本没有承诺未持久内存结果不丢。
- Campaign 失败与重玩边界代入 first_completion=false，completed / unlocks 不变；首次成功才更新集合和 grant。新档合法前缀为空，前置图不会因旧总胜利数获得额外任务完成。
- Mission 当前规则的同 tick 优先级明确 fault → player death → escort death → completion → timeout，故 timeout 等 tick 完成可胜、死亡仍败；新 profile 与 legacy victory-first 被显式隔离。
- 暂停快照要求 matching tick 的全 required owner、输入恢复 fresh-neutral；“完整快照”没有被偷偷替换为同 seed 重开。

## Required Before Production Enablement（已披露的实施门）

以下保持 OPEN/BLOCKED，不计作 D01 的新增文本冲突，也不因本次 review 自动关闭：

1. [persistence / engine / QA] 各 domain 与 required owner 的 schema、validator、迁移、完整最大合法 fixture、codec/golden、所有事务的真实故障切点。
2. [performance / QA] 全内容字节、峰值内存、捕获/编码/写回/恢复时间预算；没有冻结预算时必须拒绝 v2。
3. [systems / game / QA] 目标 entity / HP / 路径 / lifecycle、MISSION phase、事实批次与容量的正式 owner 传播及实际接线。
4. [economy / systems] ECON-MISSION-01：短局成功/失败/放弃/技术故障/重玩/零贡献的奖励公式与上下限，M01-03 grant 到资源的稳定映射，Settlement / Prep 等 profile adapter 与拒绝 legacy fallback 的 AC。
5. [engine / persistence / QA] Windows 锁、原子替换、满盘/权限/多实例/强杀、版本更新恢复；Steam Cloud adapter 与真实分支冲突证据。macOS JSON v1 的旧强杀结果不替代这些证据。
6. [creative-director / game / UX / QA] 第一章与完整流程试玩、首名角色 safe 无丹药可达、实际内容时长与重复感；Character / Codex / Narrative 等新域仍有未完成设计。

## Recommended Revisions / Nice-to-Have

- [P3][performance / QA，来源 review-save-followup] 最大负载测量显式列出 START、SUSPEND、RESULT_PENDING、COMPLETE。pending 同时持有原域、恢复点与最终域集合，很可能决定峰值预算；“完整合法最大值”原则已经覆盖，属于实施测量建议。
- [P3][creative-director] 收尾追踪更新时，注明产品文档中的“Save ADR 尚待裁定”、迁移表“新增域均无 GDD”和 session 的先前计划 checkpoint 为历史状态，并链接本次新合同。当前技术文档权威和未启用边界明确，因此这些落后的进度描述不另作行为 blocker；本报告不修改其状态。

## Specialist Disagreements

两组 followup 都认为其覆盖范围内没有新增 blocker；本 senior 同意其七组原问题关闭结论，但额外发现 D01，因此不采纳“本轮全部合同可通过”的整体建议。D01 是产品任务差异与统一规则的可复现冲突，不能由 owner 尚未实现的通用 gate 代替决策。双方报告均完整保留，没有删去较乐观的结论。

## 产品约束与证据边界

本 senior 重新解析完整 CSV：364 规划行、64 唯一 mission、八章各八项、first_available_after 严格连接 START 到最终任务；第八章 M07 不终局，M08 持久完成后终局。该静态证据支持任务图，不证明64项内容已制作或实际通关。

主要内容20小时以上仍为用户目标。64×13–15分钟仅约13.9–16小时，主动目标还可能更短；32叙事节点没有4–6小时实玩依据。SCOPE-TIME-01 保持 OPEN，必须按商业范围规定，以至少八名首次完整通关玩家的有效内容时间中位数及范围验收，不计失败重试/挂机/可选挑战，不靠加等待补足。

本次定点读取 `src/persistence/save_system.gd:15`，PROFILE_SCHEMA_VERSION 仍为1，`:96` 仍为 JSON.stringify 路径。没有运行游戏、serializer、性能、故障注入、Windows 或 Cloud 测试。本文不构成 runtime verified、implementation-ready、发行批准或 battle_ready。

## Senior Verdict [creative-director]

**NEEDS REVISION — 仅 D01 一项 P2 合同修订阻断。** 当前架构已能清楚表达持久结果、一次奖励、恢复状态和新旧 profile 分界。剩余真实文本问题是两个任务的玩家顺序选择尚不能被 BREAK 合同承载；应先让产品承诺和状态机一致，再裁定合同层通过。

Rough scope signal：**XL**（持久化、任务、章节、经济、全 required snapshot owner、Windows / Cloud 跨系统；producer 应在 sprint planning 前重新核工作量）。XL 是总体实现规模，不表示 D01 必须进行大规模架构重做。

## 审阅快照与执行范围

全文读取 CLAUDE.md、design/CLAUDE.md、design-review SKILL.md、ADR-0006、三份新 GDD、八章任务图、商业产品范围、系统迁移表、四份真实独立报告及路由 manifest；定点核对 owner、registry、systems-index、session state、技术偏好与当前 Save 版本。只写本报告，未改主文档或源码；以下 hash 锁定裁定时字节，后续整改不改变本报告的历史反例。

```text
ddeebb4b587ec0a5f1be54f614ee02e4b1e945dab14a45157ad36d12b47aaa8a  docs/architecture/adr-0006-steam-save-and-mission-contracts.md
34a9b26629640e4525b97724b0c9b1fe4abb2f23ae2f636f013ee5bd7c17fc0e  design/gdd/save-steam-pc.md
442c4d9903dd469581f5c411cd76b37caaae43e082421f7bdee49f2b3b88c785  design/gdd/campaign-flow.md
773c604d8693ae77d9e27162677a2d5a4f03a51d4e21c851efc0f94457351f73  design/gdd/mission-objectives.md
35153c3096fdc56b7ab1059c6027ba19866d282517aa649db05f227cc30b6176  design/steam-1.0-campaign.md
4147588d345132d41ae1e3a6c4e5e1a81fa25a2b72d0306fc8a03931cb1e23ba  production/steam-1.0-content-matrix.csv
c6ad7281fc2c2b75f08824c32de2a11bf9eded9fbdf40af78e1608359c3ba85e  design/registry/manifests/steam-save-mission-contracts-v1.json
```
