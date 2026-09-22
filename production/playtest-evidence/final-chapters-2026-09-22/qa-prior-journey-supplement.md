# QA 补充：最终旅程证据边界

2026-09-22。对 /tmp/late-qa-final.md 的只读补充。

重新核验 source-freeze.json 共 202 项全部匹配。运行 catalog SHA256 仍为 683d5040e5e7b6cecadae031d54b77530add19fc0ae1256ab93df9df3e6365d8。full_journey 已先构造 filename，再以 evidence+filename 打开输出；safe/alternate/regional 均归档到独立运行目录，原路径问题闭环。

直接读取同 hash 旅程 JSON 与 safe 引擎日志，结果如下：

| 路线 | 实际结果 | 存档恢复 / 逐帧对照 |
|---|---|---|
| C01 safe | 64/64，通过；完成 64，最终 M08-08 胜利 | 580 / 98,025 |
| C03 alternate | 39 胜 / 40 次，M05-08 失败；完成 39 | 449 / 80,588 |
| regional risk | 39 胜 / 40 次，M05-08 失败；该关为 C05，完成 39 | 432 / 75,770 |

safe 日志 /tmp/late-journey-safe-final-engine.log 最后明确记录 ENDING_DISK_RELOAD_PASS 与 FULL_CAMPAIGN_JOURNEY_PASS。此项是作者运行证据的独立读取核验，不冒充 QA 重新执行整个 64 关。

证据目录 production/playtest-evidence/runs/683d5040e5e7/journey-full-campaign：safe 1790045602-75120-195876，alternate 1790045603-75135-202918，regional 1790045778-75691-384801。regional 在本次复核时已经写出失败终态，不再是进行中，也没有覆盖到后面第六至第八章角色。

alt-sweep.json 确为 94/120，但 catalog hash 为 daffb01f5c3a35a0f61b511409335b59996ea1b2afba6e50f9f689685535431b，属于新增护送奖励前的历史压力证据，不得混入当前 hash 的总通过率。

Verdict：前次源码 QA APPROVED WITH SUGGESTIONS 与恢复漏洞闭环仍有效；完整旅程验收尚未达到原定两路线 64/64。当前只能宣布 C01 safe 全通及结局持久化通过。C03 与 regional 的失败须保留，并待后续修正、重新冻结和匹配验证。任何新 hash 或新策略路线的成功都不改写本次两条失败记录。battle_ready=false，新玩家 SKIPPED_BY_USER。
