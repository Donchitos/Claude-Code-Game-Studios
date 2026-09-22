# 第三章 QA 补充：旧 production bot 与证据范围

2026-09-17，只读复核；本轮核读源码及作者实际输出，没有冒称独立重跑整旅程。

**结论：两处测试修正合理，限定维持 APPROVED WITH SUGGESTIONS；不能宣称64关全通过。** 未发现本次修正新增的阻塞缺陷。第三章专项与连续前24关证据可以成立；第四章以后的失败必须继续保留，不能被前24关通过覆盖。

当前 source-freeze.json 独立重算162/162项匹配；更新后freeze SHA256 `1cd2d1280e8fb3e7d35c5031e9d21b66a03a54d5163c26f6c907c53edbe90b65`，catalog仍为 `6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a`。上一报告freeze自身SHA已由本值取代。

## 测试改动核验

- `tests/integration/campaign_journey_test.gd:637-639`：仅有clues的任务委托既有 campaign_c_bot.direction；后者:35-37明确按encounter.chapter.clues选择下一线索坐标。旧bot在HUNT分支只追目标位置，猎物尚未生成时无法完成线索前置条件，故原M01-04 timeout不是有效的关卡不可通证据。委托只生成输入，不改实际目录、伤害、目标完成状态或持久化结果；升级选择仍用原_bot_choice。准确措辞应是“clues任务使用既有完整导航函数”，不应说只是替换一个坐标，因为委托也包含该函数的避障评分。
- `campaign_journey_test.gd:607`：重新读取档案与before经过一次真实JSON转换后的完整值树比较，same_values严格比较字典键/大小、数组顺序/长度、叶值；仅把int/float数值等价视为一致，没有epsilon、删字段或放弃统计。这里是章后结算档案（无战斗快照）的磁盘合同，JSON数值舍入是允许的实际序列化语义。该更改不放宽Arena的numeric_bits或逐tick恢复合同。
- production独立每关的finished&&victory断言、sequential失败即停、64完成且ending_seen断言均保留。实读sequential结果仍报告两条失败，证明修正没有将未完成64关变为PASS。

## 已核对的实际结果

来源为 `production/playtest-evidence/chapter-three-2026-09-17/final/6cea8186b024/journey-chapter-three/`：

| 路线 | 完成/胜利 | 恢复数 | 逐tick比较数 |
|---|---:|---:|---:|
| 1789625804-70503-203818 安全 | 24/24 | 221 | 36574 |
| 1789625819-70565-207231 替代 | 24/24 | 282 | 50536 |
| 合计 | 两条均完整 | 503 | 87110 |

run.json显示替代路线包含 `--alternate-build --risk-route`；安全路线两者均无。两者catalog_hash与当前catalog一致。这里报告的是读取作者证据得到的统计，不是本QA另做两条全程独立复跑。每局run_seed已有记录。

来源为最新 `qa-final/6cea8186b024/campaign-qa/`：

- chapter实例1789626034-71173-181099：8/8胜利。
- sequential实例1789626038-71193-190883：尝试46关，45胜，在 S1-M06-06 player_dead；前24关24/24。5个章后完整档案重读比较全部通过。失败两项准确为该关胜利断言与64关持久终局断言。
- all实例1789626034-71174-181099：本次读取时写到32关，31胜，S1-M04-06 player_dead；前24关24/24。这是运行中快照，不能当最终64关统计。最终输出需主线程核实，但已经不能标记本模式全通过。

默认QA矩阵266/0由主线程报告，本补充未另行复跑；不能和production-all未通过混为同一PASS。不同bot、成长档与seed路线的证据不能相互替代。前24关既有机制/恢复限定结论保持，整64关平衡、真人体验、20小时、Windows/Steam及发布验收仍不在本报告通过范围。

新玩家 SKIPPED_BY_USER；battle_ready=false。
