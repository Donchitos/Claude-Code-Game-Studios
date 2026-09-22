# F followup独立QA复审

Verdict：APPROVED（仅限本次两个新增测试及其声明的覆盖范围）。未发现P0/P1/P2/P3确定性缺陷；无必改项。可关闭上一轮F QA报告中“胜利/超时需要合法前态→终态→双槽恢复链”的特定非阻塞覆盖建议；不扩大为全部终态、全部恢复或发布验收。

## 冻结绑定

读取并验证production/playtest-evidence/package-f-followup-2026-09-16/test-freeze.json，两项SHA256全部匹配；同时检查F source-freeze.json的63项全部匹配。catalog保持31f5f97f71efde814a73ae6d9d91e6b8205b5b6dbd15e4dfd48bfbad1e65d569。

本轮未修改工作树。独立命令均使用Godot 4.7.1 --headless --path . --script tests/integration/<test>.gd -- --campaign-validation --evidence-root=/tmp/f-followup-qa-RbgvoB；风险审计另加--alternate-build --risk-route。三进程均exit 0。

## 终态测试审阅与复跑

campaign_terminal_disk_test.gd:53–64将timeout策略只写入深拷贝navigation.target_seconds。此副本仅传Bot.direction，Arena仍使用正式catalog mission；64行检查Arena mission与原定义相同。未直接改写Arena状态、经验、HP、时钟、计数或目录。

- 57–66行按正常输入推进，保存最后一步之前的真实快照；确认它非终态且与终态相差一个tick。
- 69–82行严格validate前态、Profile真实双槽保存、销毁并新建Storage/Profile/Arena、重复末tick输入、完整快照/RNG/numeric_bits一致、验证并保存终态。
- 91–103行通过真实Root.continue_run→_sync_battle→Profile.finish_run调用链处理终态；首次注入结算失败保持两槽字节不变，新Root重试后current_run清空、runs=1、last_resolved_run_id匹配、completed/wins与结果匹配。
- 106–112行重复continue与finish_run后，内存profile和双槽字节均不变；第三个Root重建仍保持已结算状态，不能再次continue。

独立运行结果：

| 场景 | 终态tick | active秒 | 原因 | level | HP | 结算pages | runs |
|---|---:|---:|---|---:|---:|---:|---:|
| victory | 4490 | 74.8333333333304 | extracted | 7 | 160 | 46 | 1 |
| timeout | 22801 | 380.01666666665 | timeout | 7 | 160 | 1 | 1 |

两行preterminal_replay_equal、settlement_failure_zero_write、duplicate_settlement_zero_write均为true，日志TERMINAL_DISK_PASS。

证据：
- /tmp/f-followup-qa-RbgvoB/terminal.log
- /tmp/f-followup-qa-RbgvoB/31f5f97f71ef/terminal-disk/1789547602-33965-249509/terminal-disk.json

该故障覆盖的精确边界：RejectSettlement在commit_domain_after_images入口、命中结算afterimage时同步返回IO_ERROR，真实Root/Profile响应这次失败，正常存储路径与成功重试仍写真实双槽。它没有执行物理磁盘写失败、部分写入、断电、跨进程强杀或全部IO切点；不能将“实际Root结算调用链”写成“真实磁盘硬件故障”。

## pacing audit审阅与复跑

审计脚本通过正常新档顺序推进8关，使用真实升级选择/事件选择/战斗输入；直接读取状态形成遥测，不改变模拟。两条路线均8/8并PACING_AUDIT_PASS。

| 路线 | active秒合计 | 各关选择次数 | planned | attempted | skipped |
|---|---:|---|---:|---:|---:|
| 默认safe | 255.25 | [6,2,4,2,3,10,2,3] | 311 | 291 | 74 |
| alternate+risk | 263.76666666666057 | [5,2,4,2,2,11,3,3] | 311 | 290 | 68 |

默认审计没有--qa-production-evolution，与上一轮强制偏好进化的bot参数不同，其255.25秒不应替换上一轮256.55秒journey证据。run.json保存参数可辨别。已读取作者pacing-audit/1789547528-33703-160776/run.json，确认其安全路线确带--qa-production-evolution；作者另一份1789547539-33798-163146/run.json带--alternate-build --risk-route。因此默认路线是第三种选择策略，不是作者数据不一致。

planned/attempted/skipped属于encounter计划行与实际到期尝试计数，不能当作整个关卡所有实体的生成统计（场景目标、Boss、hunt目标另有路径）。nearby_enemy_seconds明确是非target活实体320世界单位范围；hostile_zone_seconds包含远处或预警中的敌对zone，不能等同受击危险时长。脚本scope已经明确相邻敌人/zone指标不是human engagement。

证据：
- /tmp/f-followup-qa-RbgvoB/pacing.log
- /tmp/f-followup-qa-RbgvoB/pacing-risk.log
- /tmp/f-followup-qa-RbgvoB/31f5f97f71ef/pacing-audit/1789547602-33966-181917/pacing-audit.json
- /tmp/f-followup-qa-RbgvoB/31f5f97f71ef/pacing-audit/1789547602-33967-175641/pacing-audit.json

本审计不带恢复对照，不能拿其遥测计数冒充新增恢复覆盖。新玩家试玩继续SKIPPED_BY_USER，不作为阻塞；battle_ready=false，真人体验、Windows/Steam、性能及完整恢复矩阵等边界不变。
