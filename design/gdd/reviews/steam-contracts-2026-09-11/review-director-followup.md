# Steam 合同 — Senior 增量复核与最终设计裁定

日期：2026-09-11。审查身份：同一独立 creative-director，针对前次 D01 与作者整改增量复核。原始 [review-director.md](review-director.md) 保留，不回写或抹去首次 NEEDS REVISION 历史。

**Senior Verdict：APPROVED — CONTRACT DESIGN BASELINE ONLY。** 本轮 ADR-0006、Save Steam、Campaign Flow、Mission Objectives 的架构与规则基线通过独立综合。前次 D01 已关闭；未发现增量引入的新合同阻断。此结论不批准全部 Steam 产品、全部 legacy GDD、生产启用或完整实现。

## 独立审阅与报告来源

本轮最初的两名真实工作组分别覆盖 persistence / Godot-engine / performance / QA，以及 game / systems / economy / UX / QA；initial 与 followup 四份报告已在首次 senior 报告中综合。随后 senior 新增 D01，作者整改，再由原 game / systems 工作组提交 [review-break-followup.md](review-break-followup.md)，本 senior 读取其报告并独立复核当前文本。

没有把多个领域标签伪装成多个已启动专家。BREAK 增量没有另行启动新的 persistence 工作组；本 senior 对 Save 编码与事务的增量交互独立核对，不声称存在未发生的额外专家复核。

## D01 关闭证据

| 必需闭合面 | 当前证据 | 裁定 |
|---|---|---|
| 玩家可选择拆除次序 | mission-objectives.md:26、:32 定义 FIXED / PLAYER_CHOICE；后者任意未完成合法锚点均可攻击推进，不要求先进入额外选项菜单 | CLOSED |
| 产品映射 | Mission :36、steam-1.0-campaign.md:211、路由 manifest 显式列 S1-M02-07 / S1-M07-07 / S1-M08-02 为 PLAYER_CHOICE，其余当前 BREAK 为 FIXED | CLOSED |
| 状态和完整性 | Mission :32 保存完成集合和实际 completion_order_ids；FIXED 必须定义前缀，PLAYER_CHOICE 必须唯一且与集合相等；每目标至多一次 | CLOSED |
| 同 tick 确定性 | Mission :34 规定 owner stable order / target 定义 ordinal / spawn epoch 产生 fact_sequence，不依赖 callback 到达先后 | CLOSED |
| 快照与环境效果 | Mission :32–34、:67 保存 objective_progress_revision / 实际次序；Stage :3 接认下一 tick 消费及已应用 revision / 待应用效果快照 | CLOSED |
| 序列编码 | Save :19 区分集合稳定排序与语义序列保序，不再将 completion_order_ids 排序抹去玩法事实 | CLOSED |
| 验收 | MO03 / MO13 覆盖双模式、六种跨 tick 排列、同 tick 稳定次序、恢复与产品映射；ADR :91 更新 MO01–MO13 范围 | CLOSED |

原反例 A、B、C 定义序列下，玩家先击破 B：在 PLAYER_CHOICE 合同内现在合法；完成集合按定义序列编码，但实际 order 保留 B 在首位。FIXED 中同样行为仍不推进，权威错序死亡按 fault 处理。两种结果由显式配置区分，程序无需猜测产品意图。

S1-M02-07 原有“破坏顺序改变剩余喷口节奏”也纳入 PLAYER_CHOICE，避免只修最初列出的两个任务而遗漏相同交互。

## 独立边界与交互检查

1. **集合与次序分离成立。** 对三个唯一目标，跨 tick 的六种完成排列均能满足 PLAYER_CHOICE 的集合终态；已完成目标不再贡献一次进度。空/重复定义目标和集合/order 不一致属于预检或快照拒绝，不借空集获胜。FIXED 保持有序前缀，无新增默认自由模式。
2. **同 tick 稳定规则不否定玩家顺序选择。** 跨 tick 的实际操作可产生不同次序；同 tick 无先后证据的多死亡采用确定排序，不以线程或回调偶然时序决定环境分支。其稳定 owner/ordinal/epoch 数据仍需生产 manifest 冻结。
3. **进度发布没有先应用半个坏批次。** 新 revision 只在完整合法 batch 实际改变进度时 checked +1；既有整批先验证、外部 stale 零效果、权威坏批次 TECHNICAL_ABORT 规则继续成立。Stage 消费已提交 revision，不根据未验证的单个回调先改环境。
4. **环境效果跨暂停边界可恢复。** Mission 已提交 revision 与 Stage 已应用 revision 可以处于相邻进度，待应用效果进入 matching-tick snapshot；恢复后处理待应用效果、拒绝重放已应用 revision。此设计承认下一 tick 延迟，没有要求两个 owner 的进度 revision 数值必须相等。具体效果字段/容量尚待 owner schema，并由 MO12 fail closed。
5. **结果提交与环境恢复没有混为同一路径。** 未 sealed 的 RUNNING/SUSPENDED checkpoint 恢复实际拆除顺序及 Stage 账本；RESULT_PENDING 不再创建可玩 BattleScope，仍只重试原 COMPLETE。最后一锚点导致终局时，Stage 的下一战斗 tick 不被当作奖励提交前置，因此不会为了消费环境效果重新开战或重算结果。
6. **持久 hash 保留原业务顺序。** Save 的集合与语义序列规则与 Mission 一致；结果继续绑定 objective_progress_hash，运行 epoch 仍仅在实时 envelope 中。增量没有往持久结果重新加入 epoch，也没有修改 pending 请求 identity / base / after-image。
7. **STAGE_RESULT → COMPLETE 原子边界保持。** stage base r → pending r+1 → complete r+2；pending 禁止其他 mutation，complete 使用已验证且 current_run=null 的最终域集合。stage 的 COMMITTED 仍不曝光任务完成/解锁，Campaign 未因本次增量改变首次奖励计算。
8. **预算建议已进入明确要求。** Save :101 将 RESULT_PENDING 当前域 + 完整 complete_next_domains 的双份数据、编码临时量和 readback 峰值纳入最大负载。此前 P3 建议的文字补充已完成；实际预算数值与测量证据仍 OPEN，不能因补充这一句就标测量 PASS。

本次没有发现新增 P0 / P1 / P2 合同 blocker。具体目标效果、Stage adapter、codec 等尚未实现，属于明确的实施门，不重复作为已修复 D01 的剩余缺陷。

## 完整性、依赖与静态产品核对

三份 GDD 仍保持八节标准结构。SP01–SP16、CF01–CF13、MO01–MO13 是本次合同验收范围；新增 AC 具有确定输入与预期，但没有执行其 runtime 测试。

前次已核实的显式依赖未删除；新增 Stage 顺序效果已由 Stage 头部路由认领。registry 的 author-route manifest 增加 BREAK 双模式及三任务映射，同时保留 JSON_V1 / LEGACY runtime、全部实施门 OPEN 与 battle_ready=false。未将该 JSON 路由文件当成 generated 生产配置。

本 senior 再次解析完整 CSV：364 规划行，64 个唯一任务，八章各八项，START 到末任务的前置链不变；13 个 BREAK 中三个明确 PLAYER_CHOICE、其余十个 FIXED。三个自由任务确实都引用 BREAK；产品正文与 CSV 类别说明不再强制全部固定次序。CSV 未新增 runtime order_mode 列不构成阻断，因为模式权威映射已经明确，生产 Config 仍必须显式生成并校验，不允许运行时从描述猜测。

## Required Before Implementation / Production Enablement

本次批准允许以这些架构与规则作为后续 owner 细化的基线；以下门必须继续保留，不能将该批准升级为完整 implementation-ready：

- domain / required owner 的 schema、validator、migration、快照字段、最大合法 fixture、codec / generated golden 与真实故障矩阵。
- MISSION phase、事实聚合与目标实体/HP/路线/lifecycle、Stage 已应用和待应用效果的正式 adapter / 容量与恢复验证。
- 全内容存档字节、内存与捕获/编码/写回/恢复性能预算，包含 pending 双份数据及临时峰值。
- ECON-MISSION-01 短任务奖励矩阵、零贡献/重玩/失败/放弃/技术故障规则的经济公式与上下限；M01-03 grant 实际映射及 Settlement / Prep 等新 profile validator。
- Windows OS 锁、文件替换、多实例、满盘/权限/强杀/更新恢复及 Steam Cloud adapter 与冲突验证。
- runtime 集成、实际全任务玩法与输入旅程、Windows 设备与性能证据。

当前 Save runtime 仍为 JSON v1；本复核未运行游戏、serializer、故障注入、性能、Windows 或 Cloud 测试。

20小时以上主要内容仍为产品目标，SCOPE-TIME-01 仍 OPEN；本次修改只保留三个任务的选择性，不增加已证实内容时长。第一章与至少八名首次完整通关玩家的有效时长验收、首名角色 safe 无丹药可达、完整内容与资产质量门均未由此次合同评审证明。`battle_ready=false`。

## Specialist Disagreements

原 senior 与两组 followup 的差异是 D01：前者发现产品自由顺序与固定合同冲突。整改后，真实 BREAK 专项报告认为已关闭，本 senior 独立验证后同意。当前在本次增量范围内没有未解决的专家分歧；历史不同结论保留于原报告。

## 最终裁定与范围

**APPROVED — 仅 ADR-0006 + save-steam-pc.md + campaign-flow.md + mission-objectives.md 的合同设计基线。** 七组初始去重 blocker 与 D01 均已关闭；没有新的设计层阻断。

总体实现范围仍 **XL**，后续应依序完成 owner schemas / 配置与预算 / adapter / runtime / Windows 与 Cloud 证据。该 verdict 不改变其他旧系统的独立评审状态，不是全部商业产品设计批准，不是发布批准。

本次只新建本报告，未改主文档、源码或首次 senior 报告。标题中的“followup”表示同一独立 senior 的针对性复核，没有声称又创建了一位 fresh reviewer。

## 审阅快照 SHA-256

```text
6380884b4b01f1cca68f63f64f6e80791c5a5ddca82699a9e2011cd3ca2c91ed  docs/architecture/adr-0006-steam-save-and-mission-contracts.md
ead5b4a98690541c51bf0e29149e94cbcc79e59e41eaccf89060990abf8c8a5e  design/gdd/save-steam-pc.md
442c4d9903dd469581f5c411cd76b37caaae43e082421f7bdee49f2b3b88c785  design/gdd/campaign-flow.md
07aae9fda0e3b1de500ba95cd646f6c63531050ff2c3b10df4047f1c7b602960  design/gdd/mission-objectives.md
f8c90281d31a4b48387c07bb3f5b5bd2b0cf6ef4f73de4e5aa3adb63291a1da9  design/steam-1.0-campaign.md
6ca7a1c95da7cf8092e1268fa5a67c1e0abeb76bb95509ff25b803d185c1ae73  production/steam-1.0-content-matrix.csv
6c4362e0706a66ff0ef6dc0dde4c2ea7e062f41cb77c9eb3d3662ce7600dd74b  design/gdd/stage-map.md
02f7c9b3733bcc0368f8e87a9b1376caf2d7bee40bfc852232eb2eb40e00113b  design/registry/manifests/steam-save-mission-contracts-v1.json
f2a1f6b459981843c2932dc7d31e21619f02028f6032fdeacf8eda3c3a7fb401  design/gdd/reviews/steam-contracts-2026-09-11/review-break-followup.md
64971268f2b8c3787adb3e717b3e02de730b0df9ae017a7ec4885b5a8989bc84  design/gdd/reviews/steam-contracts-2026-09-11/review-director.md
```
