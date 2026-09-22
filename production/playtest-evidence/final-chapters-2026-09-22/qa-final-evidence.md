# QA 最终证据核验

2026-09-22。独立读取作者运行日志、对应 JSON/run.json，重新核对冻结与逐关经济账；未冒充独立重跑128关。

## 冻结

production/playtest-evidence/final-chapters-2026-09-22/source-freeze.json 共202文件 SHA256全部匹配。当前catalog abc5f36fd15ea1f7623b4fdf46edd035056ff18f413b97e2bac4410708f86b96；两条旅程run.json与结果JSON均为同一完整hash。包含最终Bot400站位与备战入口的测试源码也匹配冻结。

## 完整旅程

| 日志 | 胜利 | 恢复次数 | 逐帧对照 | 结局双槽重开 |
|---|---|---:|---:|---|
| journey-safe-verified.log | 64/64 | 580 | 98,134 | ENDING_DISK_RELOAD_PASS |
| journey-regional-prepared.log | 64/64 | 655 | 115,327 | ENDING_DISK_RELOAD_PASS |

两条日志各包含且仅包含64条 FULL_JOURNEY，任务ID逐行严格对应M01-01至M08-08，无跳关或重复关；全部victory=true。各自记录一次FULL_CAMPAIGN_JOURNEY_PASS、零次FAIL。最终JSON completed=64、branches=[5,5,5]。合计1,235次恢复和213,461次逐帧对照。

safe运行目录 runs/abc5f36fd15e/journey-full-campaign/1790046621-77751-204410，参数仅--validation，角色始终C01，无药。

regional运行目录 runs/abc5f36fd15e/journey-full-campaign/1790046620-77744-219282，参数--validation --regional-build --risk-route --prepared-route，覆盖C01至C08八名角色（逐章合法切换），并非每名角色都独立通全64关。

## 真实资源账

regional仅M08-01/02/05/06四关记录S1-PREP08，对应进入关卡后剩余草药137/92/53/9。以零草药起步，逐关用实际击杀数与目录公式 min(3,floor(kills/20))+3 重新核算64行，在指定四关各扣48，所有行的herbs_remaining与重算完全一致。总扣费192，无负余额；最后胜利后推算余18。safe按同样公式64行全部一致，未扣药，最后胜利后推算余210。这些最终余额是逐行推算，结果JSON未直接存最终草药字段，故不伪称重新打开存档独立读得。

代码上cultivate与begin_run使用真实库存/草药校验和提交，run/loadout绑定药品；没有资源赋值入口。S1-PREP08仅前90秒护甲+7，不是全关永久增益。

## 必须保留的限制

当前hash下 alt-sweep.json 为C03压力99/120，尚有21次失败。旧C03原路线失败、regional裸装旧策略失败、后段C08裸装M08-01/02/05失败都不能被两条新路线成功抹除。历史sweep120/120属于496acbc8旧hash，不拼成当前hash全角色全种子通过。

## Verdict

APPROVED WITH SUGGESTIONS：原定“合法新档两条路线64关、恢复与结局持久化”在明确路线条件下具备完整同hash证据。可声明C01安全线和逐章角色备战风险线全通；不得声明所有角色裸装平衡通过、真人体验通过或商业发行认证。新玩家SKIPPED_BY_USER，battle_ready=false，Steam/Windows实机/商业Save v2及20小时体量仍在边界外。
