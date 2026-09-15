# 灵枢行纪 / Spirit Nexus：章节运行时交付证据

日期：2026-09-14。状态：**玩法完整链路基线；64任务顺序实测已通过，主线体量明显未达20小时；独立定向尾差异复核已完成，最终本地试玩包已构建验证**。

用户授权“先实现完整游戏吧”，采用 team-combat implementation。主线程决定保留legacy GameRoot测试，新增 `src/campaign/*` 普通生产入口。本文记录本轮真实代码与验证边界，不把364个目录项、headless探针或开发机启动等同完整商业发行。作者决定见 [ADR-0007](../../docs/architecture/adr-0007-campaign-playable-runtime.md)。

冻结目录SHA-256：`71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca`。此前记录保留各自实际测试hash，不伪装为最终字节版本。

## 启动与档案

从项目目录运行普通图形入口：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios
```

`project.godot` 当前 `run/main_scene` 为 `res://src/campaign/CampaignGame.tscn`。也可用Godot编辑器打开该项目并运行。键鼠/手柄采用既有STEAM_PC输入接线；真实键盘旅程与恢复结果见下方D/独立UI记录。

开发档案是 **CAMPAIGN_GAMEPLAY_V1**，由 `CampaignProfile` 存在ProductionSaveSystem的 `campaign_game` domain；双槽使用 `user://campaign_game_a.save` 与 `user://campaign_game_b.save`，实际 `user://` 由Godot按平台应用数据目录解析。外层仍复用ProductionSaveSystem JSON v1封装、generation与payload SHA256及读回基础，不是完整 `STEAM_SAVE_V2`。新档案不迁移或覆盖legacy进度；具体恢复故障与多平台兼容按对应测试范围报告。

普通图形入口走上述磁盘槽。headless或显式 `-- --campaign-validation` 使用内存存储，不验证正式磁盘续局；不得把headless重启称为已经通过真实磁盘恢复。目录加载对原始UTF-8文件SHA256生成 `catalog.content_hash`；Profile按内容哈希绑定，目录更改后的旧开发档案不应静默重开或清零。

## 实际内容范围

离线生成的目录包含 **364行规划来源内容**，其中：

| 类别 | 实际目录数量 |
|---|---:|
| 章节 / 主线任务 / 场景 / 区域 | 8 / 64 / 16 / 8 |
| 角色 / 主动技能 / 辅助 / 进化 | 8 / 24 / 24 / 16 |
| 普通敌人行为 / 精英 / Boss | 24 / 8 / 9 |
| 丹药 / 可选事件 / 独立挑战 / 成就 | 12 / 24 / 24 / 60 |
| 目标类型 / 成长节点 / UI规划类别 / 难度 | 6 / 15 / 11 / 3 |

这些数目是已加载、校验的配置范围，不表示每个规划效果、美术、故事节点、音频和平台功能均已完成验收。主线64任务保留原前置和六类目标；区别包括地图点位、目标数量、固定/自选顺序、敌群、Boss、章节主题和任务调参。第8章第7任务仅击败S1-B08，第8任务S1-B09才解决最终危机。

24挑战保留mission_id与实际enemy_multiplier/hazard_multiplier/max_skills/allow_pills配置，需真实挑战获胜后记录对应ID；不是24个累计击杀条目。60成就保留原名，角色胜利、进化和挑战按ID判定。Arena/Profile/Root消费验证见下方专项测试；不将其外推为24挑战的玩家自然全通。成长费用已统一base=4/step=4，下一等级n为4×n，无额外刷取门槛。

运行时只读 `assets/config/campaign_game.json`，不会运行时导入规划CSV。可复现命令：

```sh
python3 tools/campaign/build_catalog.py --check
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/campaign_content_test.gd
```

独立QA最终汇总见 [qa-summary.md](campaign-game-2026-09-14/qa-summary.md)，对应源码/内容哈希见 [qa-final-hashes.json](campaign-game-2026-09-14/qa-final-hashes.json)。E确认最终日志无leak error。

## 最终验证结果

| 验证 | 本轮结果 | 证据边界 / 来源 |
|---|---|---|
| 离线生成重现 | PASS，364 rows / 64 missions | 内容Owner实际执行 `--check` |
| Catalog/Mission内容集成 | PASS，1170 checks / 0 failures | 内容OwnerGodot 4.7.1；64定义可达、六目标正负边界、哈希/引用、JSON恢复；不是64关真实战斗通关 |
| Catalog/Mission编译 | PASS | 各脚本Godot `--check-only` |
| CampaignProfile | PASS，581 checks / 0 failures | 保留C原515；新增事件胜利收益同事务/重复/回滚、fullscreen严格字段、旧6设置真磁盘受控迁移；内容Owner实测 |
| Arena/Combat | 主线程285/0；B新增自然进化后287 checks PASS | 24模式/24行为/9Boss/6目标；下面单列自然进化证据，均不是生产64关通关 |
| Root/UI启动、真实输入流程与图形 | PASS，D Root 44 checks / 0 failures | 真InputEventKey自然撤离75.033秒，首通奖励48；菜单双语两尺寸截图；独立UI/lifecycle APPROVED，见独立UI证据 |
| 独立Engine恢复与codec | PASS：9条反例、真磁盘237→437 tick、11恶意codec反例 | 独立engine回传；/tmp真实双槽→全新Storage/Profile→恢复后200tick exact，恶意codec全部拒绝 |
| 最终全套回归（主线程） | 全exit0，无SCRIPT ERROR/ERROR/leak | Content1170 / Profile581 / Combat287 / RootFlow44 / Journey286 / Snapshot301；catalog可复现364/64、diff-check通过 |
| 独立QA Snapshot r7 | PASS，301 checks / 0 failures | E独立：普通/待选/非字典序状态分别恢复后200真实tick，全canonical exact及numeric-bits攻击；不替代64任务旅程 |
| 独立QA生产首章逐关 | PASS，8/8胜 | E使用16方向bot和原始目录独立进入首8任务；不是新档顺序推进 |
| 独立QA Profile顺序64任务 | PASS，275 checks / 0 failures，64/64胜 | E真实新档、合法奖励/成长、顺序前置，persisted_completed=64；每8关真磁盘重载，共8次；不是人类20h时长实测 |
| 既有PC输入 / Meta / Resume | PASS，99 / 134 / 71 | 主线程本轮回传；legacy范围，不替代新入口旅程 |
| 既有SaveSystem | PASS | 内容Owner在full_precision变更后实际重跑，dual_slot/hash/readback/fallback |
| 既有SaveCrash | PASS，5切点 | 内容Owner实际重跑，macOS子进程SIGKILL/137为预期 |
| 既有SteamDomains | PASS，95 checks / 0 failures | 内容Owner在序列化精度变更后实际重跑 |
| 既有FaultSurface | PASS，expected_injected_error | 主线程本轮回传；预期注入错误不当作无错误启动 |
| 既有Recovery | PASS，156 | 主线程本轮回传；既有恢复合同边界 |

内容测试真实覆盖：未知ID/重复死亡、FIXED乱序、PLAYER_CHOICE顺序持久化、净化敌人边界与中断保留、护送离队/路标/HP、玩家死亡与完成同tick、超时优先、多HUNT全目标要求、终态不可重复推进、JSON roundtrip后继续同任务。JSON测试比较数值语义，不要求解析后int/float类型一致。

## 集成修复与当前平衡诊断

- `ProductionSaveSystem`仅将payload/envelope序列化切至`JSON.stringify(value, "", true, true)`；Profile内部归一化与字节预算同精度，旧schema和双槽协议不变。E指出JSON parser仍可能产生1ULP，B负责lossless float快照编码；独立engine已实测/tmp双槽237tick保存→全新Storage/Profile→恢复推进200tick到437，exact通过；另11个恶意codec输入全部拒绝。这是lossless编码加真实磁盘旅程的证据，不仅是full_precision开关。
- Profile事件收益现在仅任务胜利时兑现到灵页，和run退休/奖励同一次提交；失败不兑现事件承诺。非法数值/超出合法事件奖励上界/选择计数不一致拒绝，重复结算不重发，IO失败不发布新状态。
- fullscreen是持久严格bool，默认false。唯一兼容迁移只接纳schema1且settings准确旧6字段，补false后完整校验再事务持久；真实磁盘测试保留进度、seed、待选/已选内容，未知/损坏字段仍拒绝，迁移IO失败不发布。
- E首章真实目录bot r1为**0/8**（旧hash `96f6701ecf6f132e8ae8edfadcce1c70bcce1e5d45993e42ccc7e0290820ad65`）：M01在34.62秒死亡，仅level2/kills15；M03护送18.45秒毁坏；Boss11.20秒死亡。该结果是bot/平衡诊断，不证明玩家绝不可能通关，但不能据此发布“完整可玩已验”。历史诊断见`campaign-game-2026-09-14/qa-production-chapter-r1.log`；matrix文件已更新为后续8/8结果，不把新版矩阵当旧失败原始数据。
- 内容/Arena联调发现mission.enemy_scaling原本是最终倍率，却被再次乘ordinal后+1，导致首关约2倍/终关约97倍；B已修成最终倍率直接乘。实际目录调整新手生命160、普通伤害起始2、剑伤24、首Boss650HP/6伤害、护送首章490HP；xp_base2/step1，普通/精英/Boss/目标XP=3/12/24/6，B消费掉落配置。任务时间未增加。新版完整新档64任务顺序通关已由E验证，见下方。B已返回至少一个自然进化路径，见下。

自然进化证据（B作者测试，经主线程回传）：`test_natural_evolution`使用真实当前catalog、fresh completed=0、seed=42；不改HP/XP/实体，只用movement与公开choose APIs。在25.55秒、22击杀、level11、HP160时，S1-A01=5 / S1-P01=5 → S1-V01。B总计287 checks通过，E独立复跑同样287/0。这证明**至少首配方可自然获得**，不证明16配方全部自然可达，也不等同该局/全章通关；其它配方与完整旅程继续验证。

D已回传图形截图/日志目录为 `production/playtest-evidence/campaign-game-2026-09-14/`：`boot.log`、`graphical.log`、`home-1280-zh.png`、`chapters-1280-zh.png`、`home-960-en-130.png`、`settings-960-en-130.png`。D报告英文130%首页标题布局已修；D最新完整Root流程44/0，真实InputEventKey自然失败与75.033秒首通、保存精确恢复、IO锁/重载、5项UI复审断言通过，退出音频清理后无资源警告。图形还覆盖双尺寸battle/pause/draft/settings及20秒battle-active；event-unlocked-visual-fixture在35.016秒、boss-warning-visual-fixture在0.783秒截图，使用原目录/合法loadout/真实advance且有“非通关证据”水印。这些截图不能当相应Boss或事件通关。独立UI/lifecycle最终APPROVED，无P1/P2；原5项及旧6设置迁移通过，最终Root/Audio差异复核通过。日志归档见 [独立UI证据](campaign-game-2026-09-14/independent-ui/README.md)。

## 真实目录顺序旅程与体量

E的 [顺序旅程原始结果](campaign-game-2026-09-14/qa-production-sequential.json) / [日志](campaign-game-2026-09-14/qa-production-sequential-r1.log) 使用冻结catalog `71d615...`，从真实新档依序完成64任务。自动玩家只操作移动与合法选择，通过Profile真实前置、结算和分支购买，不直接修改completed；8次章节磁盘重载后最终completed64、boss_defeated、ending完成。275 checks/0 failures，64/64胜。

实测战斗active为 **2115.8秒 / 35.26分钟**。各章约247.5、192.8、295.3、215.3、276.9、290.9、259.5、337.6秒。这个结果证明完整推进链路可运行，同时清楚显示当前主线体量远未达到20小时。它不是人类首次游玩的阅读/决策体验时长，不能将自动加速运行的墙钟时间或未测剧情预算补进来。

## 独立engine最终评审

独立reviewer `01a09f37-603d-7513-8d7e-a4ab59584c1c` 对组合hash `80344...` 给出 **APPROVED WITH SUGGESTIONS**，该版本评审范围内没有剩余已确认P1/P2。此后B修改的Arena/render/validation/Combat四文件已由fresh独立reviewer Russell（`01a09f4c-f5a1-7fc0-8899-7a65b54c290f`）完成定向源码复核，无新增P1/P2；范围为freshloadout、8模式count、seal/flame/render/validator。Reviewer未独立校SHA，主线程另对4个冻结SHA精确匹配。详见 [尾差异证据](campaign-game-2026-09-14/independent-engine/final-delta-review.md)。这是旧80344全review＋新4文件定向复核＋主线程SHA绑定，不宣称重做全review。原始最终日志、验证脚本、逐文件hash已复制到 [independent-engine](campaign-game-2026-09-14/independent-engine/README.md)，由内容Owner只做证据归档。组合hash `80344fabc5d84fbbde69d9471485faaee986a7e5159cd11e7ff3d633807a62b8` 在该轮运行前后一致；其中catalog为`595708...`，早于最终纯文案冻结`71d615...`，保留此差别，不把旧日志重新标成新hash。

- 9条针对性反例通过；lossless codec 11个恶意输入全部拒绝；真实磁盘237→437 tick exact通过。
- transient grid与全扫描oracle比对1000次，0失败。
- Rootflow44/0：真实按键约75秒获胜，首通奖励48。D最新流程为75.033秒；先前73.45秒属于历史运行，不能混成同一观测。
- 仅退出阶段观察到2 ObjectDB与1 resource未释放警告，建议调查测试cleanup；这不证明稳态内存泄漏。

Apple M4 / Godot 4.7.1，180敌人×400投射物，warmup120 tick、采样600；并发开发测试环境下的**CPU tick**耗时：

| 分布 | p50 | p95 | max |
|---|---:|---:|---:|
| Distributed | 5.922ms | 12.112ms | 37.535ms |
| Clustered | 8.783ms | 13.580ms | 18.451ms |

以上不是FPS、渲染/IO性能、Windows实机或最低配置认证；不将macOS CPU指标外推为发行帧率承诺。

## 仍未证明的完成条件

- **主线体量明显未达20小时。** 当前自动玩家64任务战斗active总计2115.8秒，即35.26分钟；不是20h的玩家实测或等效证明。不延长等待/强制重刷凑时长，需继续增加有效内容与体验迭代。
- 普通新档/首角色/无丹药/安全事件选择的真实目录**自动玩家顺序64任务已通过**，合法结算与成长且每章真实磁盘重载；仍不能替代人类可用性、难度公平性或20h有效内容验收。
- **Windows实机、最低配置性能、手柄设备与输入旅程：未验证。** macOS开发机/headless结果不能替代。
- **Steam API、Steam Cloud、多实例锁、商用安装更新与完整STEAM_SAVE_V2：未验证/未完成，不宣称上线。**
- 完整美术音频品质、无障碍设备、素材权利、正式本地化校对和发行质量门仍需专门验收。

本轮交付目标是让完整游戏链路实际落地并可继续实测；Root早期44checks/2fail为历史，D最新已44/0并通过真实InputEventKey自然撤离（75.033秒）。E新版首8关独立逐关8/8胜；E新档Profile顺序64任务已64/64胜，persisted_completed=64、终局boss_defeated；不改completed，仅合法结算/分支购买，每8关真实磁盘重载。UI/lifecycle最终已APPROVED；B冻结后的engine定向尾差异已完成；最终包另包含下述主线程检查的焦点防御修复。独立性能/grid结果只按原hash范围记录。

当前不能称正式发售版本、20小时已达标或 `battle_ready=true`。


## 最终试玩包与同帧焦点回归

- [Windows ZIP](../../build/SpiritNexus-Windows.zip)：只含SpiritNexus.exe、SpiritNexus.pck、PLAY.md、OFL.txt、manifest.json，共5文件；CRC检查通过，未混入历史包或测试日志。Windows EXE为x86_64 PE，未在Windows实机执行。
- [本机Mac启动.command](../../build/campaign-macos/启动.command) 与同目录SpiritNexus.pck；依赖 `/Applications/Godot.app/Contents/MacOS/Godot`，不是独立Mac app。脚本从/tmp加载PCK，目录/文件参数均引号转义；实际通过该脚本启动验证。
- 中文PLAY.md包含操控、双槽保存位置、35.26分钟基线与未达20h说明；OFL字体许可随两包分发。

初次包探针暴露同帧pause→savehome释放焦点按钮后，typed Button参数在进入`_safe_focus`前转换失败。不能用增加等待帧掩盖，因为连续pending升级也可触发相同时序。最终源码只将该参数改Variant，并先is_instance_valid、再Button类型检查、再访问；恢复原同帧探针，不加帧绕过。RootFlow44/0后重新导出，原探针从仓库外/tmp加载新PCK：headless19/0、OpenGL图形20/0，均无ERROR/leak；原始JSON哈希、字体和11音频的import/remap、OFL、编译脚本与普通入口均可用，且实际启动任务/暂停保存退出成功。Mac启动脚本另19/0。最终直接检查PCK编译脚本方法签名，PACK_FOCUS_VARIANT true，确认包内包含Variant守卫。

最终UI文件mtime 2026-09-14 17:43:52，新PCK 17:44:48，确认包晚于修复；构建前后99个输入文件SHA256完全一致。完整清单见 [Windows manifest](../../build/campaign-windows/manifest.json) / [Mac manifest](../../build/campaign-macos/manifest.json)。退出IO注入警告在Root测试中为预期，包启动日志无此注入。

| 对象 | SHA256 |
|---|---|
| 构建source inventory | `d146926d855514d249bb21a98a3922bbaee114a980be6bd32ecabac3da555eea` |
| 内容JSON | `71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca` |
| 修复后campaign_ui.gd | `7c106fc670aef126907a84ae49dae327bc99edc4361ca5d28e90350cdbb12a97` |
| 两平台共用PCK | `4fdfe7524587f755d8a2ac862183acd64633ee83fd8d17bcec02c23a89f3f67f` |
| Windows EXE | `dbec5101014e4c9bbb9ee045a85de227966fcfa0a6453879796b3927b8bedffc` |
| Windows ZIP | `37fc38f0b3950e182717ebb5c9a2404aa4698d01628f536b1a6159098b83461b` |

包验证日志和原同帧探针保留在build/campaign-windows，未装入ZIP。定向review不重新声明全部源代码独立审查，PCK在Mac图形运行也不替代Windows试玩、Steam上线或20小时内容目标。

主线程最终另独立核包：ZIP CRC无错误，5项准确，ZIP内EXE/PCK SHA匹配最新导出，Mac/Windows PCK一致；本机非validation启动脚本已实际启动OpenGL Apple M4。此核对不替代Windows实机。
