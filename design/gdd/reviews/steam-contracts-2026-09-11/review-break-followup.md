# BREAK 顺序模式增量独立复核 — 2026-09-11

结论：**本次增量通过本组合同复核，未发现新增阻断项。** 产品要求的玩家选择拆除次序已由明确模式承接；最终综合仍由 fresh creative-director 完成。仅评审该增量，不重开已通过的无关事项，也不构成实现或运行验证。

## 产品与规则一致性

- mission-objectives.md:26、:32、:36 定义 FIXED / PLAYER_CHOICE 两种模式。FIXED 只允许当前锚点；PLAYER_CHOICE 允许玩家攻击任意未完成锚点，不通过额外菜单假造次序选择。
- S1-M02-07、S1-M07-07、S1-M08-02 显式采用 PLAYER_CHOICE，分别保留改变喷口节奏、选择拆除次序和利用信息选择锚点顺序的产品差异；steam-1.0-campaign.md:211 同步映射，:20 和 CSV 的 BREAK 类别说明不再要求所有任务固定顺序。
- 对 CSV 作只读解析：13 项 BREAK，三个指定 PLAYER_CHOICE ID 均确实属于 BREAK，其余 10 项为当前 FIXED。CSV 仍是规划输入，生产 Config 必须显式生成模式；当前 CSV 未增 order_mode 列不构成缺少 runtime 配置的伪装。

## 顺序、快照与事务检查

- completed_target_ids 是按定义顺序编码的集合；completion_order_ids 是不可重排的实际顺序。FIXED 为定义前缀；PLAYER_CHOICE 要求唯一且与完成集合相同。零目标/重复定义目标拒绝，单目标有唯一合法排列，三目标有六个可由不同 tick 的操作产生的排列。重复死亡不能额外计数。
- 同 tick 多死亡使用 owner stable order、target 定义 ordinal、spawn epoch 产生确定 fact_sequence，避免 callback 抵达顺序决定持久状态。同 tick 的确定排序与跨 tick 玩家能选择六种排列并不矛盾。
- MissionSnapshot 新增 objective_progress_revision；完整合法批次实际改变进度才 checked +1，为 Stage 消费提供明确版本。旧/stale 输入、无改变或整体校验失败不能先发布部分进度，保持已有整批事实验证合同。
- Stage 下一 tick 消费已提交 progress revision，快照持有已应用 revision 和待应用效果；mission-objectives.md 的该规则与 stage-map.md:3 路由一致。恢复不重新挑顺序、不重放已应用效果，缺 required 状态仍拒绝恢复。具体效果和容量仍通过 MO12 fail-closed 门冻结，未声称本次已实现。
- save-steam-pc.md:19 明确集合与语义序列不同：集合稳定排序，completion_order_ids 保留 owner 顺序。没有“为了 canonical 编码把玩家实际顺序排序抹掉”的冲突。
- 未 sealed 的完整 checkpoint 恢复保存已选顺序及 Stage 账本；已进入 RESULT_PENDING 的 run 不恢复可玩场景，继续重试原 COMPLETE。新增顺序不会重算旧 sealed 结果或首次奖励，既有 STAGE_RESULT / COMPLETE 事务身份保持不变。
- save-steam-pc.md:101 现将 RESULT_PENDING 的当前域、完整 complete_next_domains、编码临时量及 readback 峰值纳入最大负载门；没有把较小 RUNNING 快照的预算证明当成 pending 预算证明。

## 验收可执行性

MO03 可以分别用三目标固定前缀、乱序权威死亡、跨 tick 六排列、重复/旧 epoch、缺模式和集合/order 不匹配构造独立 fixture。MO13 覆盖同 tick 确定顺序、部分完成后的恢复、Stage 已应用/待应用状态与三项产品模式映射；ADR-0006:91 的范围同步为 MO01–MO13。上述 AC 是可执行测试的合同输入，本次没有执行这些 runtime 测试。

后续 owner adapter 的实现测试应实际扰动 callback 到达先后，并分别在 Stage 效果应用前/后暂停恢复，断言相同 order、hash、revision 和效果次数；这是已有 MO13 的展开，不是新增产品决策或新的阻断项。

## 阅读及操作范围

读取当前 Mission 的 BREAK 定义、事实批次、终态、快照、公式及 MO03/MO13；产品文档的 BREAK 任务与补充映射；完整 CSV 解析中筛选 BREAK；Stage 新路由；Save canonical 编码、恢复/终态事务及新增预算说明；ADR AC 对应范围。未全文重审其他 owner 或其他已关闭问题。

仅写入获授权的本报告，未修改主文档、未运行图形或游戏、未生成设备/性能证据。生产目标实体/Stage adapter、配置、容量、snapshot schema/validator/migration 与 Windows 设备门继续 OPEN。
