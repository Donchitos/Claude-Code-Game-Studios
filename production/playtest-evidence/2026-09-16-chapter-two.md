# 第二章完整本地可玩包 — 2026-09-16

第二章8关的专属玩法、跨章成长接续、恢复保护、专项复核与独立PCK已交付。限定CAMPAIGN_GAMEPLAY_V1；不是Steam发布验收。新玩家试玩SKIPPED_BY_USER，battle_ready=false。

## 内容与入口

机制清单：`design/chapter-two-playable.md`；架构：ADR-0010。

启动：`build/chapter-two-2026-09-16/开始第二章版试玩.command`。依赖本机 `/Applications/Godot.app` 4.7.1，不是独立Mac app。使用 `Spirit Nexus Chapter Two 20260916` 独立档案目录。首次无双槽时加载自动路线实际完成第一章的样例档（completed=8、branches=[1,1,1]、pages=464），可直接选第二章；已有任一槽则不覆盖。样例不是人类试玩证据。

catalog SHA256：`7a6edddb768b4bb813bc52bd0fd334269ebeee7a6228ac55ac0806704801420f`

PCK SHA256：`444b64a6ea9fe91f319b886aeb120dc20788a8f34c6c7326522d0d3b371bc325`

冻结文件：`chapter-two-2026-09-16/source-freeze.json`。staging src/assets与当前源字节一致；project仅修改隔离应用名。旧G包保留。

## 最终真实连续路线

固定源码下 `frozen/7a6edddb768b/journey-chapter-two/` 两个独立新档，真实Profile消费/解锁/结算，从M01-01连续至M02-08。每次恢复重建双槽Storage/Profile/Arena，并比较后续最多200tick的完整snapshot含RNG。

| 路线 | 完成 | 磁盘恢复 | 逐tick比较 | 第二章active时间 | 第二章逐关升级选择 |
|---|---:|---:|---:|---:|---|
| 安全/进化优先 |16/16|146|24272|201.73秒|6,4,2,2,1,1,2,4|
| 第二角色/风险 |16/16|154|26847|243.77秒|6,4,3,2,1,1,4,4|

总计300恢复、51119逐tick对照。二阶成长只在8关后合法购买，三阶每关尝试均拒绝；替代路线真实解锁并切S1-C02。两路线炉工中途机缘均触发。单次短关1次选择仍存在，不宣称所有短关已达到丰富构筑。自动active时间排除读说明/选择思考，且显著短于商业体量目标；不是玩家平均耗时或20小时完成证据。

## 专项与回归

- 第二章246 PASS：8关初始快照、无成长/旧满成长16次自然目标胜利；六拆管顺序及预警取消、错热区标签拒绝、缺失狩猎目标拒绝、Boss假family拒绝、门窗伤害比例、整轮容量/致死守卫、中段机缘一次。
- Profile581/0；独立20次真实磁盘重载→设置写入→完整快照一致，陈旧writer拒写。正式收录 `campaign_precision_roundtrip_test.gd`。
- 跨两阶段悟性16/36与恢复不重发PASS，正式收录 `campaign_chapter_two_rewards_test.gd`。
- 第一章A135/B132/C237/D40/E465（438 accepted候选）/G58；Boss入口130/0、悟性17/0、升级守卫9/0。
- 全目录1170/0、Combat287/0、Root44/0、Snapshot225/0；路线26+29 footprint checks。
- `terminal-final-v2.log`：真实自然胜利与主动超时，终局前1tick磁盘重放相同；结算IO拒写保留双槽；重建一次结算；重复零写。
- 玩家/护送死亡落盘、狩猎错误快照拒盘回归通过。全部PASS以日志显式标记与错误检查为准，不只看进程退出码。

## 实际包验证与兼容

- 新PCK从/tmp实际Mac GUI运行，非validation模式：首关120tick保存→Root重建→继续PASS；从样例档进入M02-01同样120tick保存重建PASS，截图已查看。仅删除本次创建的隔离测试槽。
- 旧G PCK实际创建活动战斗→新PCK拒绝且双槽SHA不变→旧PCK恢复并显式测试放弃→新PCK正常读Home，全链PASS；`compatibility.json`记录。没有迁移/自动放弃用户活动战斗。
- UI独立960×540/130%字号中英文briefing和HUD；冷却匣、炉工及炉门开闭形态检查通过。

## 独立复核和本轮修复

三个真实专家：Godot/UI APPROVED；QA APPROVED；GDScript APPROVED WITH SUGGESTIONS。报告为同目录 `ui-review.md`、`qa-review.md`、`gdscript-review.md`，不是新的全仓full design verdict。

已修：炉门被主体覆盖；热区tag未绑定源坐标/伤害/持续时间；HUNT/BOSS缺失目标和Boss伪装family恢复；Profile额外JSON往返导致浮点镜像漂移。处理为deep-copy及每次写入前从精确sidecar还原，没有引入容差。隔离事务fixture补合法镜像树，跨JSON的整档断言比较完整语义值；终局已结算统计按一次磁盘JSON表示比较。所有失败历史日志保留；`journey-first/safe-v2/v3`、旧regression中的terminal失败是已修历史，最终看frozen两路线、mechanics-final、profile-final-v3、terminal-final-v2。早期回归脚本对缺文件退出0/故意故障字样的分类不可靠，最终按上述逐suite显式标记核验。

仍有非阻断建议：Boss几何常数进一步数据化、未来自定义layout容量校验、更广故障/设备矩阵。全游戏成长价格/资源富余、第三章以后内容扩充、20小时、Windows/Steam、完整商业STEAM_SAVE_V2及性能仍未完成。
