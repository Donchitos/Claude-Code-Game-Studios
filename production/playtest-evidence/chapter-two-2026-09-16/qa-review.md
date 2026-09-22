# 第二章最终冻结独立QA

Verdict：APPROVED（限定第二章增量代码、相关存档保护和本报告列明的自动QA范围）。本QA发现的问题均已修复并复测关闭，无待修P0/P1/P2/P3项。不代替旧G实际PCK兼容、包内GUI、全量故障矩阵、Windows/Steam或发布批准；新玩家SKIPPED_BY_USER，battle_ready=false。

## 最终绑定

production/playtest-evidence/chapter-two-2026-09-16/source-freeze.json最终共77项，独立重算全部匹配。目录hash为7a6edddb768b4bb813bc52bd0fd334269ebeee7a6228ac55ac0806704801420f。以下独立最终复测在该冻结内容上执行，全部--campaign-validation --evidence-root=/tmp/ch2-qa-aO4Gmv，未修改项目或历史证据。

## 独立最终结果

- campaign_chapter_two_test.gd：246 PASS。覆盖8关定义/初态、HUNT正确精英、缺目标/非法身份负例、六种拆管顺序、预警清除与错thermal标签、炉门伤害与边界、满容量不部分发射/容量恢复完整预警、致死无新增攻击、阶段奖励恢复防重及无成长/保留高成长16场自然输入fixture。mechanics-frozen.log。
- campaign_profile_test.gd：581 checks/0 failures。profile-frozen.log。
- 本QA独立family-negative.gd：缺HUNT目标、非法中段event状态、Boss改family均validate=false。family-frozen.log。
- 本QA独立malformed-publish.gd：缺state/bits的已存坏checkpoint更新设置返回false,error=INVALID_BATTLE_CHECKPOINT，无SCRIPT ERROR。malformed-frozen.log。
- 本QA独立rewrite-final.gd：使用历史失败快照的numeric_bits重建精确值、绑定当前目录/run作为浮点回归fixture，连续5轮真实双槽“加载→Arena.validate_snapshot→update_settings→重建”，每轮snapshot_valid=true且写盘成功。rewrite-frozen.log。该项验证重复序列化，不冒称自然旅程。

## 已关闭问题及修复正确性

1. 初版无目标HUNT快照曾validate/save_run均true，恢复后目标永久缺失。ChapterTwo.valid_state:71–76现在对每target_id强制live或completed耦合，反例拒绝；HUNT身份/phase在81行绑定。
2. Boss phase99和family伪装曾被接受。78–80行按目标身份反向绑定S1-B02/boss，并限制phase0..2；BREAK目标也要求family target。最终独立family负例拒绝。
3. thermal_vent错tag现在必须匹配layout中心、radius、damage、duration且未关闭；六种关闭顺序覆盖实际移除对应预警，不重置其他喷口全局tick周期。
4. Profile多次JSON往返漂移由initialize/_publish深拷贝及每次写盘前codec.restore精确state解决；后者也保护“加载后仅改设置”的再次写盘。codec校验未放宽。shape guard保证坏结构受控拒绝。
5. Profile旧事务夹具因新增codec保护先失败，现TransactionProfile只补空state/numeric_bits树以维持事务隔离。四处跨JSON对象比较改same_values，允许int/float同值但保持递归结构及数值，全部581断言保留；最终独立0失败。旧profile-final或exit0但有ERROR的日志不算最终通过。

## 接受范围与覆盖解释

- 第二章玩家输入、目标、快照仍由Arena/Mission/Profile持有；UI不写热场时钟。门状态由tick推导。炉王阶段增加时timer重置，旧zone警告保留，发射前一次检查phase+1容量；杀死Boss不生成新攻击。
- HUNT阶段奖励从damage入口同步更新entity.phase，Boss奖励在其phase更新时发放，已有phase进入快照防止同阶段重发。无成长/branches5各8场属于明确fixture，不冒充实际旧档迁移或真人体验。
- 中途机缘专项一次性和waypoint>=3已测；正式journey采样event_id/event_done捕获pending/已选恢复。没有声称穷尽全部事件与IO切点。
- E“不改后续章节”改index16合法反映ADR第二章改6/4、第三章以后保持旧曲线；通用combat fixture排除chapter_two有限遭遇，由第二章专项/旅程补实际路径，未删核心目标断言。

## 作者最终目录旅程读取

已读取final/7a6edddb768b/journey-chapter-two下两条结果，均16/16：

| 路线 | 恢复 | 逐tick快照/RNG对照 | active秒 |
|---|---:|---:|---:|
| 安全进化优先 | 146 | 24272 | 469.9833 |
| 第二角色/风险 | 154 | 26847 | 511.35 |

合计300恢复、51119逐tick对照。代码中真实新档完成第一章后通过Profile购买二阶，每关拒第三阶；替代路线选择解锁后的S1-C02。第二章中途护送event_done为真。以上旅程为作者执行、本QA读取审核；不是本QA独立重跑。已追加核对frozen/7a6edddb768b/journey-chapter-two两份完整16关结果，统计与表中相同；最终源码冻结下的作者两路线复跑已完成。本QA未冒称独立执行这两条旅程。

G旧实际包进行中零写拒读、实际新PCK GUI保存重建继续和其他全量回归由主线程记录自身证据；本QA没有独立执行这些包级检查，不能冒称本报告证明了它们。


## 77项最终收尾复核

2026-09-16最终77项freeze逐文件重算全部匹配，运行源码未变化。新增正式精度/奖励probe及ADR第9行8/18XP说明已阅读。三项又在/tmp/ch2-qa-aO4Gmv隔离独立执行：

- campaign_precision_roundtrip_test：20轮真实双槽加载/设置保存，Arena完整snapshot严格相等，陈旧writer拒绝，输出PROFILE_20_RELOAD_SETTINGS_SNAPSHOT_EXACT_AND_STALE_REJECT_PASS。
- campaign_chapter_two_rewards_test：HUNT跨两阶段16XP、Boss跨两阶段36XP；合法快照JSON恢复再调用phase逻辑不重复，输出CH2_PHASE_XP_CROSS_TWO_RESTORE_NO_REPEAT_PASS。
- campaign_terminal_disk_test：自然首关胜利tick4490与超时tick22801，末tick磁盘恢复相等、真实Root同步注入结算IO_ERROR后双槽不变、新Root一次结算、重复和再次重建零写，输出TERMINAL_DISK_PASS。日志为上述suite名加-77.log。

terminal测试111行的same_values(g.profile.data, JSON.parse_string(JSON.stringify(resolved,"",true,true)))比较完整afterimage经历一次实际存储JSON表达后的预期。它没有删字段、截取小数或放宽numeric_bits；此时current_run已清空，没有战斗快照位精度契约。此前内存resolved的统计float与重读磁盘float可能因一次合法JSON舍入不同，因此这一预期转换正确。相邻108行同内存对象完全相等、112行真实槽bytes不变、runs/run_id/wins/completed等一次结算断言全部保留，不属于弱化门槛。

最终限定verdict保持APPROVED，无未关闭QA问题。同步IO_ERROR注入不是部分写入、硬件磁盘故障或进程强杀；新玩家SKIPPED_BY_USER、battle_ready=false继续保留。
