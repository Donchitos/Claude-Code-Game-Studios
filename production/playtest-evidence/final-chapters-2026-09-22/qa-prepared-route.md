# QA 补充：合法备战路线

2026-09-22。202文件 source-freeze 当前全部匹配，包括修改后的 Bot 和 full_journey；catalog仍为 abc5f36fd15ea1f7623b4fdf46edd035056ff18f413b97e2bac4410708f86b96。

结论：APPROVED WITH SUGGESTIONS。--prepared-route 是合法消耗品路线，不是往存档注入装备或降低运行时伤害。

已逐条核实：

- 只有第八章 CLEANSE/BREAK/SURVIVE 使用 S1-PREP08，具体 M08-01/02/05/06 四关；其他关卡传空 pill。
- 每次调用真实 Profile.cultivate，再调用 begin_run(index,pill)。cultivate 验证解锁与现存草药，扣除目录cost48，增加一件库存并提交；begin_run校验库存后扣除一件，并把pill_id放入持久化run/loadout。
- S1-PREP08 在完成32关时解锁，第八章已有资格。效果是本局前90秒护甲+7，并非永久+7。四次使用至少需消耗192实际所得草药；没有在测试中赋值herbs、库存或运行时玩家护甲。
- 测试保持真正新Profile起步，每关真实胜利后finish_run结算收益；cultivate/出战若失败仍会assert失败，不存在库存不足时跳过或赊账分支。
- 行证据保留pill_id和herbs_remaining；恢复从真实Storage/Profile重开，加载持久化loadout，不绕过扣费。
- 胜利、逐帧恢复、completed64、ending_seen、current_run为空的断言均保留。

证据表述限制：safe-verified及regional-prepared全新档旅程本次审查时仍未作为QA核验完成，不提前声称64/64。regional-tail 14/17以及C08裸装在M08-01/02/05的失败必须保留；准备后的第八章定向8/8只证明该配置下fixture可达，不能单独代替完整合法经济旅程。即使新路线64/64，通过范围也应写为“C01安全线与逐章角色备战风险线”，不能写“所有角色/裸装平衡全部通过”，原C03压力失败仍属限制。

本项为只读代码/合同核验，没有独立重跑64关。新玩家SKIPPED_BY_USER，battle_ready=false。
