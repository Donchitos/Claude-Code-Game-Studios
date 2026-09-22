# 后五章 QA 专项复核

2026-09-22。只读源码评审与独立自动探针；不是新玩家试玩或商业发行验收。

## 冻结与范围

初始核验 source-freeze.json 共 202 文件全部 SHA256 匹配，catalog 为 683d5040e5e7b6cecadae031d54b77530add19fc0ae1256ab93df9df3e6365d8。随后作者仅追加 full_journey 的 regional-build 测试路线；复核时该测试文件需更新冻结。运行源码与 catalog 未漂移。

## 初轮问题复核

P2 活目标同时出现在 target_deaths 的问题已修复。Late.valid_state 现要求 target_deaths 与 completed_ids 集合一致，且完成目标不得仍活着。独立原始探针对 21 个 BREAK/HUNT/BOSS 初始快照加入真实活目标 ID，重建 numeric_bits；21 个现均拒绝。此探针使用有效初始基线，排除了测试因其他破坏而提前拒绝的遮蔽。

BREAK 的目标 ordinal 与对应 ID 下标绑定、max_hp 与目录 target_hp 绑定已确认。新 full_journey 结束后重新实例化 Storage/Profile 打开真实双槽，断言 completed=64、ending_seen=true、current_run=null；因此结局持久化检查不再只是内存字段。

## 独立执行

- late_chapters_test：179 checks，0 failures。
- late_boundary_test：309 checks，0 failures，包含关闭危险区保留现有预警、恢复、自然过期，护送初始路标奖励恢复不重发，双阶段奖励，延迟弹幕恢复和反射，382/383/400 弹容量边界。
- package_e_test：466 checks，0 failures。
- pacing_rewards_test：18 checks，0 failures。
- campaign_journey_test 默认通用矩阵：266 checks，0 failures。
- campaign_combat_test：287 checks，0 failures，24 模式/24 行为/9 Boss/6 目标类型。
- 独立自然 Boss 探针：六 Boss 共 9 次阶段转换，实际伤害完成当帧快照恢复一致。探针零成长；四场未取胜，未将其误计为合法成长旅程失败或胜利证明。

日志均在 /tmp/qa-final-*.log。Godot macOS 系统证书读取提示与这些离线检查并存，检查结果及退出码均成功。

## 测试改动合理性

campaign_generic_missions.json 的六条 BREAK/ESCORT/HUNT/CLEANSE/SURVIVE/BOSS 定义与第三章包 staging 的旧目录逐字段完全一致；旧目录 SHA256 为 6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a，与 fixture 声明一致。此处保留通用目标语义用例，而当前生产目录由专用 late/full_journey 检查覆盖，未删除原有断言。

E/pacing 把“后章仍走旧曲线”的过期断言改为 ADR-0012 的 6+4 悟性曲线、180 tick 升级间隔、320/600 吸取参数，符合新合同；未改成无条件接受。护送奖励只由 Mission 实际 waypoint 增量触发，且在非终局条件下发放，没有恢复时补发入口。

## 交付前待完成

作者新增 regional 输出路径表达式曾使 alternate 分支缺 evidence 前缀，已即时反馈；应改为先选 filename 再拼 evidence，并更新仅该测试的冻结。此问题影响证据归档位置，不影响战斗源码。

本复核时 safe/C03 两条完整旅程仍运行，regional 为追加覆盖，不能替代或隐藏其结果。C03 定向扫有章五 Boss/章六 SURVIVE 失败，必须保留；旧 120/120 扫来自新增护送奖励前的旧 hash，只能作为历史校准。必须待最终目录下真实两路线 64/64 及 ENDING_DISK_RELOAD_PASS 后签完整旅程验收。不得以本专项的 fixture PASS 提前替代。

## Verdict

运行源码与测试可测性：APPROVED WITH SUGGESTIONS；初轮必修恢复漏洞已闭环。整包旅程验收：PENDING 作者最终同 hash 旅程和证据归档修正。新玩家 SKIPPED_BY_USER，battle_ready=false；Windows/Steam/真人时长及商业 Save v2 不在本复核证明范围。
