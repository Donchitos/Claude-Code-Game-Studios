# 第三章完整本地可玩包 — 2026-09-17

第三章8关（M03-01..08）已完成本地玩法、校准、两条连续旅程、限定独立复核和实际PCK交付。额外64关压力检查仍有后续章节失败，不能称全游戏通过。范围CAMPAIGN_GAMEPLAY_V1；新玩家试玩SKIPPED_BY_USER，battle_ready=false。

## 启动与内容

`build/chapter-three-2026-09-17/开始第三章版试玩.command`，依赖本机 `/Applications/Godot.app` 4.7.1，不是独立Mac应用。

首次无任一双槽文件时加载自动实际打通前16关的样例档：completed=16、branches=[1,1,1]、pages=1017；在营地可购买二阶成长或选择已解锁的第三角色。样例不是人类试玩，也没有合成解锁。已有任一槽则不覆盖，独立目录 `Spirit Nexus Chapter Three 20260917`。

8关：涨潮口生存、账册狩猎、渡船护送、旧港净化、水闸印永久淹池、潜鳍群生存、深庭祭卫决斗、沉潮双鳍。规则见 `design/chapter-three-playable.md` 与 ADR-0011。

Catalog SHA256：`6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a`

PCK SHA256：`b9746276b48eda130e8531b02be54e18d749863314777149abd6cf1d9e4316b3`

源码冻结：`chapter-three-2026-09-17/source-freeze.json`（162项）。包文件校验：`build/chapter-three-2026-09-17/manifest.json`。staging src/assets与当前源码字节一致，project仅隔离名称变化；第二章旧PCK保留。

## 交接问题闭合

源hash演进：44fab78c → c6510253203b → f7f6c060（交接时）→ 6cea8186（本轮最终）。所有最终旅程使用6cea8186；旧hash日志仅为历史。

1. 精确复现M03-07失败：全局seed977的第23次randi抽取为 `1479748453`，不是单局seed977。相同S1-C03、completed22、branches[2,2,2]、风险输入在46.6833秒失败，与交接一致。旅程现逐关记录实际run_seed。
2. 校准采用后路5只、offset450、interval60，保留祭卫强度（1.176 > M03-02的1.136）。预先固定25种子（包含真实失败种子）×6候选；交接配置21/25，新配置25/25。全部候选及失败记录保留 `codex-calibration/sweep.json`，不是人类成功率或任意随机种子保证。真实替代路线该关80.90秒通关。
3. GDScript独立复核抓到Boss阶段快照P1：enemyAI之后projectile/zone伤害跨阈值，phase落后一帧却被校验器拒绝。现由真实damage_enemy边界同步phase/18XP/下轮冷却，不提前发攻击、不删除已有预警、不放宽phase断言。自然两次阶段转换立即JSON恢复验证通过。
4. 末期齐射P2：原只预检16个zone，弹池399时只发1/12弹却消耗侧别/冷却。现同时检查12弹容量，388允许完整齐射，389/400不部分发射、不翻侧、不消费冷却。
5. 已有潮墙锚y=-625全高、hostile保留蓝/橙/绿色、渡船船体、永久潮池活区守卫等修复重新复核。快照额外拒绝重复tide_flat及越界索引，防重复伤害。旧“池越界”结论确为把世界半高640误当视口半高；未借此改地图。
6. Profile补第二章旧内容hash的明确旧包路由；实际旧包链验证零写拒接管。

交接阶段M03-03 escort_hp660与FERRY_2六只沿用，不再次扩大调参。全球成长成本/资源富余仍未重平衡。净化正式hold7.8秒，修正旧设计表7.2秒笔误。

## 最终真实连续两路线

原始JSON均在 `chapter-three-2026-09-17/final/6cea8186b024/journey-chapter-three/`，从新Profile自然连续完成第一至第三章。实际双槽重建，恢复后最多200tick同输入全snapshot/RNG对照。

| 路线 | 完成 | 磁盘恢复 | 逐tick对照 | 第三章active时间 | 第三章逐关升级选择 |
|---|---:|---:|---:|---:|---|
| 安全C01/全局711 |24/24|221|36574|306.98秒|6,2,3,2,5,7,2,4|
| 第三角色C03/风险/全局977 |24/24|282|50536|672.32秒|6,2,4,3,5,7,2,4|

合计503恢复、87110次逐tick对照。24关后三阶购买成功、四阶仍拒；第三角色只在16关合法解锁后选用。两线是作者自动执行、QA读取复核，不冒称QA独立跑完；不是玩家平均时长，更不是20小时体量证据。

## 回归结果与未通过项

最终目录下37个回归入口已执行。常规与本章34项PASS；旧production chapter/all/sequential最初因M01-04 bot不走线索失败。补测试导航后chapter8/8 PASS，all/seq的前24关均通过；后续失败保留，不隐藏或删除胜利断言。

通过重点：
- 第三章1713 PASS；恢复奖励PASS；新增自然phase+388/389/400容量边界PASS。
- 第二章246，奖励与16关旅程PASS；Profile581/0、精确20次重载/设置写盘、陈旧写入拒绝PASS。
- A135/B132/C237/D40/E466/G58、BossEntry130、Combat287、Content1170、Root44、Snapshot225、UpgradeGuard9、pacing_rewards18均通过。
- 胜利/超时终局磁盘、死亡双槽、非法狩猎拒盘；B/C/D/E旅程、pacing/G审计通过。
- 默认QA完整矩阵266/0；production evolution模式通过。三章通路分别26/29/18检查，通过真实支持的chapter参数；旧route工具忽略--chapter-three而跑首章的问题已修。

额外64关检查（`qa-final/`）：
- independent all **54/64**；失败M04-06、M06-01/03/04/06/08、M07-05/08、M08-07/08，前24/24。
- sequential **45胜/46尝试**，止于M06-06，64关终局断言未达，前24/24。
- M06-06用实际seed1345899233和实际到达loadout在旧第二章PCK、新第三章PCK分别重跑，两者同为40.55秒死亡，HP/伤害/击杀/构筑统计相同（`later-chapter-*-v2.log`）。仅这一例确认旧包也有，不能把其它9例未经对照全部断言为旧问题。

后续章节失败列为全游戏平衡/路线待办，不属于第三章新增玩法通过证据，也不为凑64/64修改未授权后续章数值。

## 测试诚实性与历史披露

- 默认QA矩阵此前三轮未执行，是实际覆盖缺口；交接修正generic_mission挑选通用任务及敌人ID后，本轮最终目录重新266/0。
- 旧production导航不理解clues，修复仅委托现有clue bot，未改任务、HP或输出；sequential章后完整afterimage以一次磁盘JSON表示做same_values，保留所有progress/64终局断言。QA补充复核确认合理。
- Claude阶段旅程曾空转20分钟（Boss死亡后entities[0]越界）及容量负例timer早退，交接已修；旧孤儿目录仅run.json，不计PASS。
- 最终旅程/机制在加第二章旧hash名单之前启动，后者仅影响跨hash初始化；最终包该改动以实际旧PCK链专测。最后测试导航改动只影响额外production入口，独立chapter-three旅程无变化。最终freeze含这些差异，未借旧运行冒称所有字节完全相同。
- 旧初判报告保留；交接含TBD的草稿另存 `claude-handoff-report-draft.md`。最终采用下述新复核，不沿用旧hash verdict。

## 独立复核与实际包

真实Godot/UI最终APPROVED，GDScript/QA最终APPROVED WITH SUGGESTIONS；见 `gdscript-final.md`、`ui-final.md`、`qa-final.md`、`qa-supplement.md`。非阻断建议：进一步覆盖潮汐所有phase与更完善失败dump命名。不是新全仓full design review。

UI真实Mac小窗960×540/130%字号中英文、全高清晰潮墙、蓝潮/橙热区、渡船、月牙区及淹池检查通过。隔离UI的Profile旧hash名单差异在报告中披露，不作为完整包兼容证据。

最终PCK从/tmp非validation实际Mac GUI：加载真实16关样例→M03-01运行120tick→保存→重建Root→继续同关同tick，通过且截图已查看，只删除测试自建隔离槽。

旧第二章PCK创建活动档→新PCK明确拒绝且双槽hash不变→旧PCK恢复并显式测试放弃→新PCK正常读Home，四模式链PASS。无自动迁移/放弃用户活动战斗。

## 保留边界

新玩家SKIPPED_BY_USER；battle_ready=false。Windows/Steam、完整STEAM_SAVE_V2、全故障矩阵、dense P99性能、全游戏经济和20小时内容目标仍OPEN。第三章本地交付不代表这些已完成。
