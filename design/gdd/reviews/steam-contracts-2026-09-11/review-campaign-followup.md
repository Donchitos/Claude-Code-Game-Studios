# Campaign / Mission 合同独立复核 — 2026-09-11

本组结论：**原四项 blocker 已闭合，本次未发现新增阻断项。建议 fresh creative-director 通过本组的合同复核。** 这不是完整实现批准、生产 profile 启用、Windows 验证或 20 小时时长验收。

本报告来自原独立审查者对修改后文本的复核，不冒充 fresh creative-director，也不声称另有五位专家。本组覆盖 game / systems / economy / UX / QA；最终综合 verdict 由独立 creative-director 给出。

## 原问题关闭证据

| 原问题 | 当前合同证据 | 复核结论 |
|---|---|---|
| P1 sealed 结果恢复 epoch 与不可变字节冲突 | mission-objectives.md:55 区分无 epoch 的持久 MissionResultV1 与带 epoch 的实时 MissionResultDeliveryV1；:61、:69、:91 明确 pending 恢复和 stage 前回退。campaign-flow.md:27 明确 pending 不重新调用 prepare_completion。save-steam-pc.md:63-79 固定持久 intent、原 COMPLETE operation/base/hash/after-image，禁止 pending 期间旁路修改。 | 已关闭。E1 sealed→STAGE_RESULT 持久→E2 恢复保持原结果字节/hash与请求身份；未形成持久 head 的内存结果不冒充已保存。 |
| P1 非法事实封 technical 与 MO09 无结果冲突 | mission-objectives.md:38、:46、:89 区分外部 stale 输入与当前权威批次损坏；整批先验后应用，后者在最终 barrier 封唯一 TECHNICAL_ABORT。 | 已关闭。旧实例回调无效果；当前权威链错 tick/重复/非法值/溢出有确定 technical oracle。 |
| P2 失败也按公式增加 unlock | campaign-flow.md:51 为 completed/unlocks 同时写全 first_completion 条件两分支；:78 CF11 覆盖失败、重玩成功、首次成功。 | 已关闭。success=false 时 after_completed/after_unlocks 均保持旧值；已完成重玩不产生首次 grant。 |
| P1 新任务早胜与旧经济/首次备战解锁不兼容 | campaign-flow.md:39-45 明确 STEAM_MISSION_V1，排除旧胜利 43200..108000 窗口，备战唯一开放来自 M01-03 Campaign grant，明确迁移库存与入口资格分离。:79-80 CF12/13 阻止回退 legacy validator。ADR-0006:31 同步该决定。 | 已关闭合同边界。合法快速胜利与 M01-03 解锁是确定规则；owner adapter、grant 映射和 ECON-MISSION-01 数值仍是启用前门，不能将其未实施重新列作同一 blocker。 |

## 新问题检查

未发现本组职责范围内的新阻断合同冲突。新增 STAGE_RESULT 仅持久化待完成 intent，COMPLETE 才把首次完成、奖励、解锁、记录与退休一起生效；中间状态有独立身份、固定后续 base revision，未引入“先发奖励再落盘”的业务裂缝。原已完成章节不会因 stage 前崩溃回退当前 run checkpoint 而丢失。

旧 GameRoot 的 victory-first 与新 Mission 的 player-death-first 仍由新 profile 边界明确隔离，不将旧 owner 尚未接入新 profile 当成已生效冲突。目标实体、HP、路径、required-owner snapshot、MISSION 阶段与容量缺失继续 fail closed；这些明示实现门不是本轮新缺陷。

**建议项 R-CF01 已关闭：**最终归档前再次核对 campaign-flow.md:41，现已显式保留 committed stones/pages，禁止新发胜负/首次/随机奖励，备战按已持久事实补偿。该表述与旧 settlement-system.md:57、:321 及产品 steam-1.0-campaign.md:196 一致，不存在本组尚未关闭的建议项。

另核对本次同步修改：mission-objectives.md:53 与 save-steam-pc.md:43、:65 已统一“接纳主动放弃请求前未sealed→封ABANDONED→STAGE_RESULT→COMPLETE”，Save 不再暴露第二条 ABANDON 写入路径；ADR-0006:73 同步该事务链。campaign-flow.md:31、:76 明确只有 matching COMPLETE 的 COMMITTED 才开放下一任务，STAGE_RESULT 的成功不能曝光完成/解锁。上述修改均未发现新的本组合同冲突。

## 产品约束与验收

- 商业任务顺序、八章各八项、M08-07 不终局、M08-08 持久完成后终局规则保持不变；前次对完整 CSV 的静态解析结果为 64 唯一任务且全部 START 可达。本轮读取产品约束并核对修订未改变规划图；没有把图连通当成实际游戏可通关。
- 首名角色、safe、无丹药可完成普通主线仍是 CF08 的整章/全流程产品验证门；实际配置、通关和体验证据未生成。
- 三份 GDD 仍为 8/8 节。CF11-13、重写 MO09/MO11、SP13-16 为明确的负例/恢复 fixture 输入；功能 AC 可测不等于测试已执行。
- 20 小时依旧只为目标，steam-1.0-campaign.md:180-182 的实玩时长门保持 OPEN，未因本次合同修改获得额外证明。
- 依赖文件未新增变更；上一轮所有显式 GDD 链接存在，Character/Codex/Narrative 缺口继续明示跟踪。没有声称这些 owner 的 schema 已完成。

## 阅读和执行范围

重新全文读取当前 design/gdd/campaign-flow.md、design/gdd/mission-objectives.md、design/gdd/save-steam-pc.md、docs/architecture/adr-0006-steam-save-and-mission-contracts.md；定点核对 design/steam-1.0-campaign.md 的目标、备战开放、生命周期与旧技术中止边界，以及首轮报告已经取证的旧 Settlement 约束。前次范围包含完整产品文档和整个商业 CSV 的解析，本轮没有重新运行游戏或对所有旧 owner 全文重审。

除获授权写入本复核报告外，未修改主文档、未运行图形、未启动 runtime、未生成运行/设备/性能证据。范围信号仍为 XL；生产实现与发行状态仍由明确 OPEN gates 约束。
