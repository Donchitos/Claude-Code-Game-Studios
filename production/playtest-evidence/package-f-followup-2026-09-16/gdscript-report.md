# F follow-up — GDScript 与测试逻辑独立复核

限定 Verdict：APPROVED WITH SUGGESTIONS。仅覆盖新增 campaign_terminal_disk_test.gd、campaign_pacing_audit.gd；没有确认的 P0/P1/P2 阻断问题，不作产品/发布裁决。

## 方法与冻结

读取 code-review SKILL.md、GDScript specialist 规则、项目编码规范与技术偏好，并结合此前读取的 ADR-0009。完整读取新增测试、bot 与证据 helper，核对 Arena.configure/advance/snapshot、Root.ready/continue_run/_sync_battle、Profile.finish_run 真实源路径。新增 test-freeze 与原 F source-freeze 当前均 mismatch=[]。

## 关键审查结果

1. terminal_disk:51–65：timeout 仅更改 duplicate(true) 得到的 navigation 字典，用于 bot 选择移动输入；Arena.mission 由 configure 另行深拷贝且终态前断言与目录相等。没有改模拟 HP/XP/tick/时间阈值来制造终态。
2. terminal_disk:56–82：before 在每次真实 advance 前获取；退出后检查 before.tick+1==terminal.tick，保存合法 before 后 free/reopen Storage/Profile，恢复并使用同一移动向量单步推进，比较包含 numeric_bits/RNG 的完整 canonical snapshot。此处支持首关真实胜利/timeout 的前末 tick 磁盘恢复确定性，不只是任意终态夹具。
3. terminal_disk:9–14、89–112：拒绝 current_run=null 的实际 afterimage commit；Root.continue_run 真实触发 _sync_battle 和 Profile.finish_run。失败后检查 persistence_blocked 与双槽字节未变；新 Root 重试结算，检查 runs=1、wins/completed、run_id 退役，再检查内存、磁盘重复结算零变化及重新载入一致。该注入在 super.commit 前返回 IO_ERROR，只证明同步提交失败路径，不能外推部分写入、进程终止或断电矩阵。输出 scope 已明确 no process kill。
4. make_root 在 --campaign-validation 下先启动内存默认 Storage，然后替换为隔离磁盘 Storage；关闭物理推进。没有写用户战役档。循环内 Root/Arena/Storage 正常释放，成功路径删除双槽，run.json 与报告保留用于证据。
5. pacing_audit:38–55：记录选择发生的 active elapsed，威胁计数为每次固定 1/60 推进后采样；live 排除 target、死亡实体；nearby 使用 320 世界单位，hostile zone 只判断 hostile，可包含远处/预警区。输出 scope 明确这些都不等于真人参与感。max_live_non_target 是采样最大并发，不是累计生成量。
6. pacing_audit:59–71：planned 是完整配置行数总量；attempted 是已触发调度计数，包含 skipped；attempted-skipped 仅代表调度器成功生成数量，不包含任务初始 boss/锚点或追猎专用生成。报告消费者不得把它当全部敌方生成/击杀量。
7. bot 的升级/安全或风险机缘与 branch 购买均走生产 API；alternate 参数改变种子和升级偏好，未篡改 catalog/state。遥测是有限 bot 路线，不能当真人时长或手感验收。

## 独立复测

Godot 4.7.1，两个新脚本均使用 --campaign-validation --evidence-root=/tmp/f-followup-gdscript-evidence：

- terminal-disk/1789547618-33990-214749：PASS。victory tick=4490，elapsed≈74.8333；timeout tick=22801，elapsed≈380.0167。两次 STORAGE_COMMIT_FAILED_2_RELOAD_REQUIRED 均由预期注入触发。重试后 runs=1，奖励 pages 分别为46与1。
- pacing-audit/1789547629-34023-162004：默认路线 PASS，8 个任务成功。选择次数 [6,2,4,2,3,10,2,3]；这里只独立重跑默认路线，未独立执行 alternate/risk 组合。
- 成功后 /tmp 证据目录无遗留 *.save；源码与历史证据未修改。

## 非阻断建议

- [P3 / 标准偏离] terminal_disk:21、28 与 pacing_audit:10 的 helper 参数/返回类型不全，公共 helper 缺文档注释；两个 _run 均超技能 40 行目标且分支较多。可按场景抽取有类型的小 helper，降低后续断言维护难度；没有因此观察到运行错误。
- [覆盖增强] terminal_disk:100–113 已证明只退役/结算一次，但 reward_pages 目前仅记录，未对首次结算的精确奖励构成建立独立 oracle。若要声称奖励公式验证完成，另加 pages/herbs/统计增量期望断言；当前“重复结算零写入”的窄结论成立。
- [证据消费] pacing-audit.json 未直接存 risk-route 布尔，但同目录 run.json 保存完整 arguments，须一起保留；不要脱离 run.json 使用 alternate/risk 路线标签。

ADR-0009 的证据隔离与恢复比较方向一致，没有发现架构禁止模式。本次是集成/遥测测试，文件 IO、真实 Root 生命周期和顺序驱动属于被验证对象，不据单元测试无 IO 规则误判。

新玩家试玩继续 SKIPPED_BY_USER；battle_ready=false。没有真人/Windows/Steam/20小时/商业 Save V2 或完整故障矩阵新增证明。
