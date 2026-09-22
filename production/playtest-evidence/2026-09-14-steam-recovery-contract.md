# WP04c：恢复合同与商业责任盘点 — 2026-09-14

本轮完成 WP04b 之后的显式恢复合同增量，并完成两路独立代码复核。**WP04 整体仍 PARTIAL**；实际运行仍 JSON v1 / legacy Stage，`battle_ready=false`。

## 已实现

- `SteamRecoveryContract`：从可信安装配置绑定profile、任务定义/config hash、精确owner集合、owner schema与closed state shape；对整个owner row和checkpoint计canonical UTF-8字节，预算显式给出。
- 先完成全部metadata/shape/byte与provider生命周期预检，再调用Preparation、每owner、最后联合validator；缺provider或非法输入返回明确status。回调获得深拷贝；不提供对外部副作用的沙箱保证。
- `SteamSaveDomains` 可选安装Recovery；binding来自已校验的root/run，不能由快照自报。注册版本2可通过完整Save校验；旧三参兼容路径仍仅支持owner版本1。Preparation和Complete均安全验证返回协议并隔离输入。
- 商业责任清单：13战斗恢复责任、5持久feature、6目标overlay，分别列出必须保存的pending状态和barrier前必须消费完的状态。所有商业provider/schema/上限仍null/OPEN。责任ID不冒充已安装runtime owner ID。
- 已同步相关owner GDD路由、ADR-0006、registry、systems-index、工程检查点和会话恢复入口。发现并修正旧WP04b不存在的报告引用，改指向实际原始证据目录。

## 验证

| 检查 | 结果 |
|---|---|
| 新恢复合同集成 | 156 checks / 0 failures |
| 新纯逻辑单元 | 34 checks / 0 failures；含中文/引号/反斜线UTF-8完整row边界 |
| 本地回归 | 15脚本全部PASS；包括以上两个及codec82、schema104、domains95、snapshot764、capacity1905 |
| 旧行为回归 | Save双槽/故障面/5强杀点、Progression/Home、生产生命周期/长局/PC重入均PASS |
| Python生成物 | domain199 / schema70 checks PASS；结构校验不等于商业语义 |
| 恢复清单 | 13/5/6 PASS；另12项正反例检查，禁止缺项/重复/假provider或预算准入 |
| Godot editor import | 完成，无SCRIPT ERROR/ERROR日志 |
| 独立复核 | Godot/GDScript + QA均APPROVED，仅局部代码范围 |
| QA变异测试 | 删除checkpoint或payload字段闭合：各3 failures、exit1，无脚本异常 |
| diff whitespace | git diff --check PASS |

环境为本机macOS、Godot 4.7.1.stable.official.a13da4feb；没有Windows实机测试。脚本验证除了exit code还检查成功摘要及SCRIPT ERROR，避免Godot异常仍exit0被误判。所有最新回归/审查证据位于 [steam-recovery-2026-09-14](steam-recovery-2026-09-14/)，主回归见 `regression-summary.json`、独立结论见 `independent-review.md`。

容量回归沿用已有 `steam_snapshot_capacity_test.gd` 的输出目录，刷新了该测试的压力样本和measurement；本轮measurement另归档为 `legacy-capacity-rerun.json`。这些构造样本不是自然可达商业最大状态，不冻结生产上限。原始九月十一日复审日志仍保留。

## 尚未完成与下一入口

1. 按责任清单补真实 Mission/Stage 六目标定义与快照；优先SURVIVE/BREAK，验证Mission进度revision与Stage已应用/待生效环境效果一致，绑定正式MISSION阶段与fact容量。
2. 逐项安装剩余商业owner（完整SkillDraft/Loadout、Preparation、SettlementComplete、内容feature等），明确逻辑引用恢复与pending账本。
3. 从真实内容/容量上限生成最大合法fixture，计入完整slot转义、RESULT_PENDING双份域、编码临时量和目标Windows捕获/IO/恢复峰值；目前仅有测试/适配限额。
4. 再完成短局经济与profile adapters、Save v2事务/迁移/锁、Campaign任务闭环和Windows/Cloud验证。

本轮没有启用v2磁盘入口，也没有将64行合成fixture当成可玩任务；20小时以上、8章64任务的商业目标保持。未执行commit或push。
