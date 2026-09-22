# Steam 合同修正后的独立精确复核

日期：2026-09-11。专家范围：persistence / Godot-engine / performance / QA。

本报告全文复读当前 ADR-0006、save-steam-pc.md、campaign-flow.md、mission-objectives.md，并核对首次报告的四项 blocker。只读主文档；仅按授权写入本归档。没有运行 serializer、故障注入、Godot 集成或 Windows/Steam 平台测试，不把文档审查当作实现证据。最终 verdict 留给 fresh creative-director 综合所有专家报告。

## 复核结论

**首次报告的四项合同 blocker 已关闭。当前复核未发现新增、可证明的 P1 持久化硬冲突。** 新的 STAGE_RESULT → COMPLETE 拆分有明确的身份、base revision、持久恢复载体和曝光边界，可以作为实现前合同方向继续推进；仅留一项 P3 实施测量建议见下文。

这是专家的合同复核结论，不是最终批准、生产启用、续局 ready、runtime verified 或设备验证结论。所有已披露的 owner schema、预算、adapter 与验证门继续 OPEN/BLOCKED。

## 原 blocker 逐项关闭

| 原问题 | 当前证据 | 结论 |
|---|---|---|
| sealed result 持久 epoch 与重启 epoch 相冲突 | Mission :55 的结果本体不含 epoch；实时交付另用 MissionResultDeliveryV1；Campaign :27 明确 pending 恢复不重新计划；Save :77、:121 保留原 durable 结果身份 | CLOSED |
| RUNNING / RESULT_PENDING boot、tick 0 和 terminal 请求恢复未定义 | Save :61 强制 START 原子提交 tick 0 全 owner checkpoint；:63 冻结完整 terminal_intent；:69–79 给出状态分派、崩溃前后边界；:118、:121 增加 AC | CLOSED |
| PREPARED 可取消绕过已曝光随机 offer 承诺 | Save :59 明确 UPDATE_PREPARATION 先持久同页与不可取消承诺；CANCEL_PREPARE 需 owner 基于当前 revision 验证资格；:61 规定 START 在 pre-active 解决后；:119 加入 AC | CLOSED |
| current_run null 与必需 domain wrapper 冲突 | Save :37 唯一 wire 为 domains.current_run={schema:"1",payload:{run:null|RunStateV1}}；:120 覆盖空档与退休档 | CLOSED |

行号分别指 design/gdd/mission-objectives.md、design/gdd/campaign-flow.md、design/gdd/save-steam-pc.md 的本次复核快照。

## 新两阶段事务检查

1. **身份与 hash 不递归。** Save :63 的 stage operation 与 complete operation 不同且首次尝试前冻结。complete_next_domains 将 current_run 清空，因此不会把 terminal_intent 嵌回自身。complete_request_hash 可在 stage 前计算。
2. **revision 边界成立。** 若 stage base 为 r，stage head 为 r+1，complete_base_revision 固定 r+1；COMPLETE 成功 head 为 r+2。pending 期间禁止其他 mutation（:65），不会合法地插入另一笔交易破坏该 base。
3. **完整原子结果。** STAGE_RESULT 只持久 pending 意图；campaign/unlocks/奖励等最终 after-images 随 COMPLETE 原子生效。Campaign :31 和 CF10 :76 已明确只有匹配本 run/operation/hash 的 COMPLETE COMMITTED 可曝光完成/解锁，STAGE_RESULT COMMITTED 不能充当到账凭证。复核过程中发现的这一潜在混淆现已关闭。
4. **崩溃边界诚实。** stage 前只有内存 sealed，Save :79 / Mission :69 明确允许回旧 checkpoint，不声称未保存结果已持久。stage 后、complete 前恢复同 intent；complete 后先裁定新 head，不能用旧槽 pending 再写一遍。
5. **技术中止。** Save :65 指向 STAGE_RESULT → COMPLETE 与 owner 补偿，禁止改名 ABANDON 绕过；Campaign :41 明确新 profile 的结果映射。具体补偿 validator 仍是已披露的 owner 交付门。
6. **准备与恢复。** PREPARED 不经 RESUME 绕过 START；RUNNING 与 SUSPENDED 从完整 checkpoint 恢复，RESUME 不重扣药（Save :72–77）。tick 0 可恢复不等于仅凭 seed 重开，文档要求全 required owner 快照。

## 首次推荐项与读取/云冲突复核

- INVALID_CONFIG 已进入 SaveResult 封闭 status（Save :45）；SP03 已使用合法 kind COMPLETE（:107）。CLOSED。
- float64 明确最高有效位在左及 1.0 的 hex 示例（Save :17），不再依赖宿主字节序。CLOSED。
- 两槽组合明确区分缺失、确定损坏、未知高 schema、读取失败；高 schema 不回落旧档覆盖，读取失败为 UNCERTAIN，同 hash 是同 head（Save :55）。CLOSED。保留坏档副本的实际 IO 失败处理仍需 adapter 实现验证，不能由本文推出 PASS。
- 同 branch_id、同 revision、异 hash 明确保留两个候选；选择后保留所选 branch_id，以所选 hash 作下一 parent，不按 branch_id 去重或自动合并（Save :85）。CLOSED。此保守规则可能让后续同步重复要求选择，是明确的体验取舍，不是幂等破坏。
- 迁移仍保留源字节、同代冲突阻断、激活 marker 不是真值；旧胜利不映射章节。没有发现本次改动引入迁移重复授予或序号回绕路径。真实 migration fixture 尚待实现。

## 复核过程发现并已关闭的放弃顺序歧义

**[P2][persistence / QA] CLOSED。** Save :65 已明确“未 sealed”仅为 GameRoot 接纳主动放弃请求的前置；接纳后封 ABANDONED，统一经 STAGE_RESULT → COMPLETE 持久化。Save :43 移除独立 ABANDON kind；Mission :53 与 ADR :73 同步。这样不会把本次刚封的放弃结果误判为先前已存在的终态，也不产生第二条竞争写入路径。

Campaign :41 同时明确技术中止保留旧 owner 已 committed 的 stones/pages、按持久备战事实补偿，不新发胜负/首次/随机奖励。该表述与旧业务语义衔接清楚，不能靠把技术中止改名放弃规避。

## 实施期建议，不作为新增合同 blocker

**[P3][performance / QA] 最大负载 fixture 显式包含 RESULT_PENDING。**

来源：Save :63 新增完整 complete_next_domains，:115 与 ADR :61 仍以“最大合法快照”概述预算。

pending head 同时携带当前域、恢复点和最终域集合，可能比单个 SUSPENDED checkpoint 更大。现有“完整合法最大值”原则已经涵盖它，不构成合同冲突；建议实施任务明确分别测 START、SUSPEND、RESULT_PENDING、COMPLETE 的最大合法编码量与峰值内存，并按真实最大值冻结预算。

## 8 节、AC 与依赖

- Save、Campaign、Mission 仍为 **8/8** 节。ADR 按 ADR 模板检查，不套 GDD 八节。
- Save **SP01–SP16**：新增 boot、承诺页、wire、pending 身份 AC 覆盖原 blocker；测试性成立。
- Campaign **CF01–CF13**：CF10 精确绑定 COMPLETE，CF11 首次 grant 分支明确；CF12/13 限定新 profile 规则与启用门。
- Mission **MO01–MO12**：MO09 区分外部 stale 与当前权威坏批次，MO11 增加 E1 → stage → E2 的 byte-identical 恢复用例。
- 初次报告已逐项验证的现存依赖文件仍是本次依赖集合。新 profile 的 owner adapter、validator、snapshot 与 phase/capacity 传播没有被宣称完成。

本轮没有因为缺现成 schema、golden、预算、Windows 或 Cloud 证据而重新打开已关闭的设计矛盾；这些仍是独立实施/启用门，必须在生产前完成。

## 审阅快照 SHA-256

本报告的判断基于以下字节；后续改动需由下一阶段检查确认。

```text
ddeebb4b587ec0a5f1be54f614ee02e4b1e945dab14a45157ad36d12b47aaa8a  docs/architecture/adr-0006-steam-save-and-mission-contracts.md
34a9b26629640e4525b97724b0c9b1fe4abb2f23ae2f636f013ee5bd7c17fc0e  design/gdd/save-steam-pc.md
442c4d9903dd469581f5c411cd76b37caaae43e082421f7bdee49f2b3b88c785  design/gdd/campaign-flow.md
773c604d8693ae77d9e27162677a2d5a4f03a51d4e21c851efc0f94457351f73  design/gdd/mission-objectives.md
```
