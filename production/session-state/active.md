# Session State — 凡人修仙传·掌天试炼

> 会话崩溃或 `/clear` 后，先读本文件恢复上下文。

<!-- STATUS -->
Latest full-campaign delivery checkpoint (2026-09-14): **Playable baseline delivered — 灵枢行纪 / Spirit Nexus**。
普通入口为src/campaign/CampaignGame.tscn，legacy测试保留。最终Content1170 / Profile581 / Combat287 / RootFlow44 / Journey286 / Snapshot301均0失败；
E独立Sequential275/0，真实新档合法成长顺序64/64胜、终局持久化、8次章节磁盘重载。自动玩家战斗active为2115.8秒=35.26分钟，**主线体量明显未达20小时**，不称完整商业游戏完成。
独立评审分层：旧80344全review及其性能证据只绑定旧hash；Russell完成冻结4文件定向源码复核，主线程另匹配SHA，不冒称重做全review；独立UI/lifecycle通过。
最后_safe_focus Variant守卫由主线程检查，Root44及原同帧PCK19/20无错，包内编译方法签名已确认。独立开发档案CAMPAIGN_GAMEPLAY_V1，不是完整STEAM_SAVE_V2。

最终交付：build/SpiritNexus-Windows.zip；本机build/campaign-macos/启动.command（依赖/Applications/Godot.app，并非独立Mac app）。
/tmp隔离PCK启动、JSON/字体/11音频资源及图形验证通过；主线程独立核ZIP CRC和5文件SHA，已实际运行非validation本机GUI。
PCK SHA256：4fdfe7524587f755d8a2ac862183acd64633ee83fd8d17bcec02c23a89f3f67f；
ZIP SHA256：37fc38f0b3950e182717ebb5c9a2404aa4698d01628f536b1a6159098b83461b。
完整证据与manifest见production/playtest-evidence/2026-09-14-campaign-playable.md。
**下一步：扩充有效主线体量、人类试玩，以及Windows实机/Steam/发行品质验证；20h未达，battle_ready=false。**
下方保留全部历史checkpoint，不覆盖本条最终状态。

Latest WP04c recovery-contract checkpoint (2026-09-14): 用户“OK，执行下一步”后完成可信配置相对的SteamRecoveryContract及Save七域可选接线：精确owner/schema/identity/matching-tick、closed shape、完整row/checkpoint UTF-8限额；所有预检先于Preparation callback，单owner后必需joint；回调副本/返回协议/Node生命周期守卫。13战斗责任+5持久feature+6目标清单已盘点，商业provider/schema/budget仍null/OPEN。两真实独立code-review专项初轮发现P1/P2并修复，Godot/GDScript与QA最终限定APPROVED；不是新full design verdict。最终156integration+34unit通过，15脚本本地回归全PASS，Python199/70及清单13/5/6通过，editor import无错误、diff-check通过。最后QA删除checkpoint/payload闭合守卫各3failure/exit1，证明负例非codec/预算遮蔽。证据production/playtest-evidence/2026-09-14-steam-recovery-contract.md及steam-recovery-2026-09-14/。WP04整体PARTIAL，实际JSON v1/legacy Stage，battle_ready=false。下一入口：Mission/Stage六目标定义/恢复及progress revision与pending效果联合语义（先SURVIVE/BREAK）→正式phase/fact容量及剩余商业owner→最大合法slot预算→ECON/adapters→v2事务/任务闭环；Windows/Cloud仍OPEN。下方WP04a/b等是历史checkpoint，本条为最新恢复入口。

Latest WP04a implementation checkpoint (2026-09-11): 用户“继续”后已实现src/persistence/steam_canonical_codec.gd与src/data/steam_campaign_schema.gd，三份assets/schemas/steam结构schema、三个tools/steam工具、9golden+64合成任务fixture。纯校验不持久化、不修改runtime入口；Save仍JSON v1。code-review技能真实Godot/GDScript+QA并行review，修复ASCII ID合法域收缩与跨任务共享grant被拒两P2，独立复核通过；QA增量审机器schema。最新82unit/104integration/70Python schema checks全PASS，5组旧Save/fault/crash/Progression/Home回归PASS，editor import0、diff-check通过。U+0000返回UNSUPPORTED_STRING，不能宣称完整SP01；测试budget不是生产预算；其余5domain/owner snapshots/真实MissionDefinition/ECON/Windows/Cloud仍OPEN，battle_ready=false。详见production/playtest-evidence/2026-09-11-steam-schema-foundation.md及steam-schema-2026-09-11/原始证据。当前下一入口：其余5domain字段/validator/migration与required-owner快照清单→完整最大合法fixture/预算→v2事务与任务接线。下方“尚无任何schema基础”或WP04未开始均为历史状态。

Latest PC+Save/Campaign engineering checkpoint (2026-09-11): 用户授权“关闭PC输入剩余问题，随后确定存档策略与章节目标合同”。STEAM_PC R3–R8作者修复与三真实工作组+fresh senior局部复审完成：APPROVED WITH ADVISORIES，R1/R2本地回归CLOSED；profile99/Meta134/reentry71/surfaces127、macOS graphical139通过，26integration脚本25PASS/1图形SKIP。12截图已查看；极小deadzone长度下溢P3 OPEN。新Windows包build/windows-pc-input-r3-r8，PCK SHA256 d21ce17a010ff9cc9d52ed1847dd56c49ffbda1bd91d0f73fd4d3c8f2fa86bb9；导出/macOS PCK boot/ZIP CRC通过，Windows仍NOT_RUN。详见production/playtest-evidence/2026-09-11-pc-input-r3-r8.md。

New contract checkpoint: ADR-0006已选STEAM_SAVE_V2严格JSON，新增save-steam-pc.md/campaign-flow.md/mission-objectives.md八节GDD（SP16/CF13/MO13）。PREPARED承诺取消、START tick0、boot分派、STAGE_RESULT→COMPLETE持久intent/原请求恢复、语义结果与epoch分离、快速胜利/M01-03唯一备战开放已写；两真实合同组复核关闭原七组blocker。fresh senior另发现BREAK自选顺序与产品差异，作者已补FIXED/PLAYER_CHOICE及三个指定任务、顺序/Stage快照、MO13；专项组增量通过，同一独立senior复核最终APPROVED（仅四文档架构/规则基线，非implementation-ready）。证据design/gdd/reviews/steam-contracts-2026-09-11/。当前runtime仍JSON v1/legacy任务；新owner schema/phase/预算/ECON-MISSION-01/adapter/Windows/Cloud实施门OPEN，battle_ready=false。传播为新profile路由和明确覆写边界，未声称全体owner协议实现。

Current engineering entry: WP04内容domain schema与golden→required-owner恢复/阶段/容量→最大合法fixture预算（含RESULT_PENDING双份域）→短局经济/adapter→Save v2与Mission闭环。完整路线见production/steam-1.0-contract-checkpoint.md；8章64任务/364规划内容与SCOPE-TIME-01保持，最终产品主要内容20小时以上目标不变。下方WP01尚未开始/格式未定等均为历史checkpoint。

Latest Steam 1.0 scope checkpoint (2026-09-11): 用户要求完整、完善、Steam正式发售，选择主要内容20小时以上后“继续”。本轮交付design/steam-1.0-product-scope.md、steam-1.0-campaign.md、production/steam-1.0-content-matrix.csv、steam-1.0-system-migration.md；8章64主线任务、364规划内容ID、原32系统逐项迁移+新增9域、WP00–WP10。同步release-plan/index/MVP来源/ADR-0004/technical-preferences/registry路由。SCOPE-TIME-01：64×13–15分钟仅13.9–16小时，局外4–6小时未经证实，20小时目标仍需第一章与全旅程实测。所有新内容PLANNED，未改游戏代码/生产ABI/既有verdict。下一具体工程入口WP01（PC R3–R8），接着WP02/03 Save策略与章节目标owner设计，再数据/技能/任务闭环；Windows仍NOT_RUN，battle_ready=false。下方记录保留为历史证据。

Current planning task: Steam 1.0 P0 author baseline delivered / Design Review Pending；不再把最小可玩或MVP完成当产品终点。当前恢复入口：production/steam-1.0-system-migration.md。以下旧Epic/Task/Next Steps描述不覆盖本checkpoint。

Latest PC P1 fix checkpoint (2026-09-11): 用户授权修复R1恢复重入与R2 modal焦点外泄，已实现并完成本地验证。恢复事务锁/逐边界复核/安全退回暂停，modal背景FOCUS_NONE与默认GUI旁路关闭；六边界71 checks headless+graphical通过、Meta36/40、Input81通过；25项integration脚本24PASS/1图形SKIP，两尺寸PNG已查看。原探针回焦ticks保持0、Up/Down不再逃至PauseButton。Windows新包build/windows-pc-input-p1-fixed，PCK SHA256 2e106d23c3a22db1e41fa0c513968aa30c3980f538d307a9a8632cdc9985573e；本地PCK启动与ZIP完整性通过，Windows实机NOT_RUN。R3–R8及独立复审/完整ABI/性能门仍OPEN，battle_ready=false。详见2026-09-11-pc-input-p1-fix.md；以下为历史checkpoint。
Latest ordered follow-up checkpoint (2026-09-11): 已按独立full复审→同环境性能A/B→Windows收证检查执行。三真实专家分组全部返回后由fresh creative-director综合，verdict MAJOR REVISION NEEDED；PC05恢复hide_modal重入失焦、PC07默认Up越升级modal均有Godot headless反例，尚未整改。profile隔离/跨局identity局部关闭，real_t边界/generation/传播/neutral反馈/测试覆盖待修。完整tick同夹具12次正式A/B：默认VSync旧/新P95中位数20.579/19.785ms，关闭VSync15.708/15.991ms；未复现输入整改明显性能退步，默认帧时间门仍未过。Windows ZIP CRC及四项内容一致性通过，但当前Darwin无Windows/wine/pwsh，W01–W14仍NOT_RUN。详见2026-09-11-pc-input-independent-review.md、2026-09-11-pc-input-performance-ab.md及对应原始证据目录；battle_ready=false。下方checkpoint为历史记录。
Latest PC input remediation checkpoint (2026-09-11): 用户授权按profile裁定→生命周期→Windows验证顺序推进。ADR-0005/input-steam-pc.md冻结STEAM_PC v1，mobile future-port逐章隔离；生产不实例化VJ，WASD优先、独立mapped stick径向0.20死区，neutral resume、每tick PC context/lease、focus/terminal-first、八Meta binding与第二局7001 identity已实现。24项headless回归通过，输入81 checks、Meta headless26/graphical30；两尺寸暂停截图已查看。Windows新包位于build/windows-pc-input，PCK SHA256 eacc9a9204a87b69215b53f13d014e1a4ae24a8c930c0d475d21eda653233d94；本地PCK启动通过，但Windows物理键盘/手柄仍NOT_RUN，14项检查表与PowerShell收证脚本已备。macOS dense整帧P95/P99=29.838/32.489ms，性能未过；无设备idle输入+lease+Player批均摊P95=2.516us不代表硬件输入或allocation验收。完整七phase/持久identity、独立full re-review、Windows/min-spec仍OPEN，battle_ready=false。详见2026-09-11-pc-input-remediation.md；下方旧checkpoint为历史记录。
Latest InputSystem review checkpoint (2026-09-11): 准确目标`design/gdd/input-system.md`已完成clean-context full re-review；三份真实specialist报告由fresh creative-director综合。8/8章节、35个unique AC，但独立性Y=13/D=20/N=2；最终`BLOCKED / XL`（至少`MAJOR REVISION NEEDED / XL`）。8组去重blocker为Steam/mobile profile、PC deadzone/generation与多tick复用、phase/context/lease ABI、正式GUI route及Shield/VJ stacking、pause/background/resume原子事务、Meta/7001 identity、manifest/AC矛盾与Steam正式平台证据。Stage/render不在本review范围；InputSystem保持In Review/Re-review Pending，implementation/integration/runtime/device verified=false，battle_ready=false。详见input-system-review-log.md末条。
Latest Windows export checkpoint (2026-09-11): 官方Godot 4.7.1模板包SHA512校验通过，仅补装Windows x86_64 debug/release模板，未覆盖已有iOS模板。`Windows Internal` release交叉导出exit 0，得到104MiB PE32+ x86-64 `TrialInternal.exe`（SHA256 `4e5e07b7...a79404`）与14MiB PCK（SHA256 `cb1b09eb...01fc3`）。本机无Wine/Windows设备，未执行Windows启动、物理键盘/手柄、renderer、性能或安装验证；runtime/device verified=false，battle_ready=false。报告2026-09-11-windows-export.md。
Latest batched-renderer checkpoint (2026-09-11): 正式Stage启用固定容量MultiMesh几何批次，普通敌人用同一mesh+INSTANCE_CUSTOM保持数组顺序，飞剑按velocity旋转；Boss存在时敌人回退原路径保留血条/遮挡。旋转、0.75/1/1.25缩放专项逐像素完全一致；319敌+392飞剑三布局最大通道差1且无差值>1像素。Apple M4生产复测ordinary/capacity/Boss/dense屏内命中帧P95=13.862/10.398/13.912/14.753ms，模拟均无>16.67ms帧；dense P99仍22.910ms。22项headless与4项macOS图形检查通过。报告2026-09-11-batched-renderer-production.md；Windows交叉导出已完成，Windows运行/min-spec/长时P99仍OPEN，battle_ready=false。
Superseded dense-batch texture trial (2026-09-11): 隔离dense_batch_probe用生产Stage参考图，对比透明纹理+MultiMesh敌人/友弹，三布局均319敌392弹全部屏内，30预热+180采样，无模拟/存档。纯绘制帧间隔均值约18.2–18.5→8.3–8.5ms，但9473/17554/6399像素不同，飞剑边缘与重叠阴影尚不等价。该纹理候选未接入；上方几何批次checkpoint已取代它。
Latest draw-culling checkpoint (2026-09-11): Stage按实际canvas逆变换viewport剔除完全屏外拾取/毒弹/敌人/友弹，含外圈/尾迹余量和闭边界；Boss预警/雾圈不剔除。macOS三组开关逐像素图一致（1280/960/相机偏移+zoom0.75），碰撞等价与长局回归通过。相同压力帧间隔P95 30.631→18.041ms，Stage _draw CPU均值3.811→2.310ms；仍不稳定60FPS。批量绘制值得隔离评估，但本轮未实现，须保留重叠顺序/阴影混合并增屏内密集样本。报告2026-09-11-draw-culling.md；battle_ready=false。
Latest render-breakdown checkpoint (2026-09-11): 完成同319敌/392弹夹具分段计时与3种显示状态×VSync开关对照，各120预热+600采样。默认正常均值26.107ms=填充0.042+模拟4.777+统计0.002+等待21.286；Stage _draw CPU均值3.811ms包含在等待内。隐藏Stage均值8.396ms，隐藏全部战斗内容8.376ms。关闭VSync正常仍25.347ms、隐藏Stage5.823ms，主瓶颈不在夹具或VSync，应优先分析Stage绘制/提交路径。等待不等于纯GPU；无GPU profiler和多轮置信区间，不宣称稳定60FPS。本次仅诊断，生产参数/绘制未改。报告2026-09-11-render-breakdown.md，battle_ready=false。
Latest spatial-optimization checkpoint (2026-09-11): 飞剑改为Grid包围圆候选+原精确扫掠，完整段/最大敌半径/保守余量，碰撞前同步新生pending；Grid单元查找改预分配线性探测hash表。160×80全遍历oracle一致，负坐标hash冲突/删除重建专项已通过。相同319敌+392友弹压力headless模拟P95 45.539→4.609ms；图形模拟P95 44.123→4.973ms，帧间隔P95 67.411→28.842ms。模拟达预算但整帧仍不达稳定60FPS，不改玩法参数。下一步拆分渲染/等待/夹具开销，补密集命中压力。报告production/playtest-evidence/2026-09-11-projectile-optimization.md；battle_ready=false。
Latest performance checkpoint (2026-09-11): 用户确认前期不无聊、升级明显、扣血提示可见、暂停升级结算重开流畅、字体界面正常；死亡原因是否清楚仍未明确。新增performance_probe完成headless和macOS图形三场景各120预热+600采样。319敌+392友弹人工压力：headless模拟P95 45.539ms，图形模拟P95 44.123ms/帧间隔P95 67.411ms，600/600超60FPS模拟预算，性能门未过。普通开局与Boss二阶段轻载图形帧间隔P95 13.439/14.226ms。静态内存原始采样已记录，不作泄漏结论。首要优化对象为逐弹遍历全敌的125048候选检查/tick；下一步空间候选筛选后同夹具复测。报告production/playtest-evidence/2026-09-11-performance-baseline.md，battle_ready=false。
Latest font-fix checkpoint (2026-09-11): 用户截图发现“击杀/敌潮”中的缺字框；GameRoot共享主题从SystemFont改为随包NotoSansCJKsc-Regular.otf，保留官方OFL.txt与来源/hash，Windows Internal导出include加入许可证。font_coverage_test禁用系统fallback扫描src gd/tscn，178个不同CJK字全部覆盖；macos_graphical_test两尺寸通过，960×540实际截图已查看，“击杀/敌潮”正常。旧窗口需重启；此修复不代表完整UI/所有Unicode/Windows验收。
Latest macOS-test checkpoint (2026-09-11): 用户确认Windows电脑暂不在身边，先测macOS，Steam/Windows发行优先级不变。17个既有integration *_test全部通过（含5个真实Save进程kill case，FaultNotice错误为预期注入）；新增macos_graphical_test在Apple M4/macOS OpenGL Compatibility通过，合成Input action移动、暂停冻结、释放后恢复不漂移，1280×720与960×540截图已查看。新增macos_playtest.gd普通首页临时档案入口，未读写真实进度；不是独立.app签名/公证、物理键盘/手柄或Windows验收。battle_ready=false。
Latest crash/export checkpoint (2026-09-11): 实际macOS子进程在before_open/after_open/after_store/after_flush/after_readback五个生产Save checkpoint自SIGKILL；分别恢复generation 1/1/1/2/2，旧有效槽字节不变，汇总/测试domain一致，临时文件清理完成。这是5点进程结束证据，不是断电/完整kill矩阵。FaultNotice实际截图发现未显示，已修正add_child后布局和z_index，1280×720截图已查看、故障开局/购买门测试通过。Windows Internal此前缺模板的阻断已由上方Windows export checkpoint关闭；Windows实机验证仍待安排。battle_ready=false。
Latest save-safety checkpoint (2026-09-10): JSON双槽基础层改为已有文件均无效时CORRUPT_PROFILE拒绝初始化，不创建空档覆盖；同代不同内容拒绝；选择物理非active槽写入保留有效恢复槽；完整payload hash读回，IO/读回失败锁住本实例后续写入且不发布内存。主页购买/结算/加载失败进入可见FaultNotice，提示备份目录、关闭重启确认结果，不提供清档按钮。save_system_test故障夹具、home_progression_test、long_run_test通过；完整binary ABI、跨进程锁、断电/process-kill与原子持久化仍OPEN，battle_ready=false。
Latest hazard-query checkpoint (2026-09-10): 当前Stage快照已补普通敌人/召唤接触圆、扑咬预警走廊与当帧实际扫掠段、扇毒预警与释放扇形；query_danger按stage/tick验证后返回warnings/exposures，无效查询valid=false。只是几何暴露，不计算接触冷却/扑咬已命中限制/毒雾间隔等最终扣血资格，不保证下帧安全，也未接正式Revive/Damage ABI。hazard_query_test、weapon_publication_test、long_run_test通过；保持battle_ready=false。
Latest publication checkpoint (2026-09-10): 飞剑改为Stage拥有的32行预分配pending，T冻结origin/velocity/damage，T+1交付后才运动；错帧拒绝，满容量计数丢弃，不重试；teardown清pending。新增毒弹/毒雾 detached Dictionary快照，stage instance ID+Active tick匹配读取，推进先失效、成功tick末发布、销毁拒绝；当前不包含扑咬/扇毒/普通接触，也未接正式Damage hazard consumer。weapon_publication_test、long_run_test、projectile_lifecycle_test通过。完整typed ABI、Pool与hazard接线、性能仍OPEN，battle_ready=false。
Latest combat-lifecycle checkpoint (2026-09-10): 伤害批次增加单次提交门、提交后禁止追加、contact+attack合计溢出零写；飞剑先裁剪到当前玩家中心回收圆，再判定有效末段命中，最后回收（闭边界相切计命中，起点已越界直接回收）。Stage teardown清空友弹/毒弹/pending/拾取并关闭模拟入口，可重复清理。combat_protocol_test、projectile_lifecycle_test、long_run_test、hit_feedback_test、production_lifecycle_test通过；仅当前适配层修正，不等于完整Damage/Projectile ABI。完整typed intent/receipt、Weapon T+1发布、独立Projectile Pool生命周期、危险快照仍OPEN；battle_ready=false。
Latest player-feedback checkpoint (2026-09-10): 用户真人反馈：扑咬/扇毒预警明显、移速容易控制；受伤效果不明显，只能看血量。本轮保持速度/预警/伤害参数不变，补0.24秒角色亮色红圈、1.4秒扣血浮字与HUD来源（碰撞/扑咬/扇毒/毒弹/圈外毒雾），失败页保留致命来源或超时原因。提示跟随Active tick，冷却阻挡/无效伤害不触发，重开清空。combat_protocol_test、hit_feedback_test、production_battle_loop_test PASS；hit-feedback-preview.png已实际渲染并查看，仅静态效果验证，新动态效果待用户复测。未关闭完整Damage ABI/独立复审等门，battle_ready=false。
Latest tuning checkpoint (2026-09-10): 普通100HP模拟完成3 seed×2策略：站桩Boss三败；按预警躲避三胜，剩88/77.2/77.2 HP。修正碰撞冷却吞Boss伤害、飞剑扫掠/扇形角落判定、T+1来源绑定、召唤固定48-word与0/2事务；移速暂限600px/s。实际Godot扇形截图已查看，真人手感待反馈；提供临时存档boss_practice.gd（R开始）。详情production/playtest-evidence/2026-09-10-combat-tuning.md。本条取代下方固定双召唤与旧烟测数值描述；完整typed ABI/危险快照/正式Spawn manifest仍OPEN，battle_ready=false。
Latest implementation checkpoint (2026-09-10): 已执行长局敌潮与Boss接入，取代本段下方75秒/隔离Boss/不可达残页描述。默认8段敌潮到720秒，43200 Active tick唯一Boss出场，900秒超时判败；Boss死亡判胜、结算存页，90秒自然收入可达。新增boss_combat_test与long_run_test，完整自动高HP烟测到734.33秒胜利、Lv25/1401击杀。Boss使用当前Stage Pool/Grid，392友弹+8毒弹，312/444动作轮转；60px/unit兼容几何与固定双召唤为初版适配，完整Spawn RNG/身份、Damage/Projectile ABI、危险快照、平衡/视觉/性能/独立复审仍OPEN。battle_ready=false。
Release strategy: 2026-09-10用户已调整为Steam PC商业完整版优先（Windows首要验证目标），后续再做Android、iOS与微信小游戏/其他小游戏适配；当前工作名及凡人相关名称仅限内部设计，商业Steam build前必须原创化改名并清理第三方IP元素。详见`docs/architecture/adr-0004-steam-first-release-strategy.md`。
Epic: 引擎与系统分解
Feature: 正式战斗切片核心系统设计
Task: 两个PC P1已作者修复并本地复测；下一步处理R3–R8与独立复审，Windows设备收证等待实机
Current section: STEAM_PC v1 / R1+R2 author-fixed locally verified / Independent Re-review Pending / Windows NOT_RUN
File: `design/gdd/input-system.md` + `design/gdd/game-root-scene-flow.md` + `design/gdd/battle-ui.md` + `docs/architecture/adr-0001-mobile-accessibility-bridge.md` + `docs/architecture/adr-0002-game-root-persistent-scene.md` + `design/registry/manifests/supported-touch-event-ordering-v1.yaml` + corresponding registry/index/review logs
Review mode: 三个真实clean-context专家分组已全部返回，由fresh creative-director综合；报告和探针已归档。常规作者回归不覆盖本次反例，无批准。
Status: 2026-09-10对准确目标`design/gdd/input-system.md`完成新的clean-context独立full re-review：6 specialists并行返回后由fresh creative-director综合，结论为`BLOCKED / XL`，修订级别至少`MAJOR REVISION NEEDED / XL`。用户随后授权整改；本轮已将正式生产调用链拆为GameRoot调度Input/Gameplay、InputSystem内部读取movement actions并执行F1、补入FROZEN/consumer-close/shield bank/fault observer、VJ candidate replacement、root gate/readback/flush、7001 payload生产接线与exactly-once smoke断言，统一102 node count并修正生产geometry offset。Steam迁移后，正式项目已建立1280×720 PC窗口、WASD/手柄左摇杆 movement profile，并完成首页/战斗/结算自适应布局；正常战斗循环回归已覆盖交互升级。SpatialGrid与Object Pool已从独立spike推进到Stage敌人运行路径：生成取得borrow+pending handle，移动后sync，自动飞剑用Grid nearest，死亡/teardown按Grid remove→Pool unbind→release；正常战斗逐帧守恒断言与83-kill烟测基线通过。当前仍未闭合的正式F2 provider、完整resume/touch事务、Meta真实binding/native accessibility、workload schema/hash/marker/threshold、Grid完整phase lease/Projectile与Drop查询/Pool quarantine、Progression战斗效果/Home UX、完整Save、Boss正式集成、平台与runtime/performance/UX证据保持BLOCKED。`git diff --check`、Godot 4.7.1 root parse、production lifecycle、production smoke、normal battle loop、spatial grid、object pool、save、progression、boss FSM均通过；仍保持`In Review / Re-review Pending`、`implementation-ready=false`、`integration-ready=false`、`runtime/device verified=false`、`battle_ready=false`。
Runtime checkpoint: SaveSystem基础层已接入persistent GameRoot：Steam运行使用双槽本地档案、payload SHA-256、generation选择与写后读回，headless按DisplayServer使用内存档；结算在一个profile写入中提交纪录与Progression after-image，独立测试覆盖损坏最新槽回退。ProgressionSystem基础层已覆盖90秒里程碑收入、统一钱包守恒、三支五级购买、Save通用domain写入与下一局投影；Home已提供余额/等级/成本与二次确认，下一局已消费青元attack、长春max HP/L5一次恢复及大衍pickup。crit、青元L5 pierce、大衍L5 refresh仍待对应owner；同步UI尚无UNCERTAIN/reconcile。当前正式切片仅75秒，短于首个90秒收入里程碑，实际经济闭环不可达。
Boss checkpoint: 隔离BossStateMachine核心已覆盖43200 tick唯一调度、120 Active tick入场门、50% phase6 receipt exact-once锁存、90 tick阶段转换、pause不补帧、外圆毒域半径、8向弹道与lethal优先；尚未接入Enemy/Spawn/Projectile/Damage/BATTLE_RULES或75秒后的长局内容，不能视为正式Boss战。
Constraints: 保留已有dirty worktree与历史记录；不得把vertical-slice harness、PC输入回归或Grid/Pool首段运行接线扩大解释为完整生产集成、Steam release、真机、性能或`battle_ready`证据。当前Stage仍使用pixel-space兼容参数，`world_half_extent=1,000,000`只防止现有360 px/s切片提前越域，不等于Stage V2的16,384 world-unit可达性证明；正式world scale迁移仍OPEN。Steam-first只改变发行优先级，不关闭现有设计复审、runtime、generated artifact、PC输入/UI、性能、玩家体验或IP清理门；下一轮整改需针对本次新blocker重新获得用户授权；本作者上下文不修改独立评审结论、不自批准。
Evidence boundary: 双槽JSON与Progression基础层尚不满足`save-system.md`冻结的65,536-byte binary codec、reservation、process-kill reconcile、完整多domain事务；Progression仍缺crit/pierce/refresh owner、购买不确定态、90秒以上可达内容、视觉人工验收与经济试玩。Boss隔离FSM也不等于正式战斗集成。不得称Save/Progression/Boss完整实现或runtime verified。
<!-- /STATUS -->

<!-- CURRENT_INPUT_VERTICAL_SLICE -->
2026-09-09已完成当前实现验证 checkpoint：

- ADR-GR-001固定main-scene persistent GameRoot；root Window/Viewport、pause writer、`gui_disable_input` writer及app pump保持同一identity。
- `InputSystem`、`VirtualJoystickHost`、`BattleUI`绑定到`BattleScope_<generation>`；支持pause/resume/replace/teardown，replacement在`ACTIVATION_SUCCESS`后才释放Viewport gate。
- 统一报告 `production/input-vertical-slice/evidence/input_vertical_slice_check_report.json` 状态为`PASS`；本地9/9检查通过，GDUnit4无error/failure/flaky/skipped/orphan。
- 设备探测为`adb=false`、`simctl=false`，因此Android/iOS、TalkBack/VoiceOver、性能/thermal证据保持`BLOCKED`，不得据此宣称完整集成或`battle_ready`。
- 独立复审已于2026-09-10完成，结果记入`design/gdd/reviews/input-system-review-log.md`；本轮授权整改已完成，下一步执行新的clean-context独立full re-review。
<!-- /CURRENT_INPUT_VERTICAL_SLICE -->

<!-- EIGHTH_REMEDIATION_CURRENT -->
第八次独立 verdict 为 `MAJOR REVISION NEEDED / XL`；本轮已完成用户授权的8组跨文档合同整改：hash 分层、create correlation/identity lease、1152/724-byte reservation、11×12=132 crash oracle、Save 六行 SGH、ADR 101-row（互斥choice）动态 choice/Settings/Input/MPSC ABI 与 43200 tick 边界。状态继续 `In Review / Re-review Pending`，`battle_ready=false`；generated/runtime/device/性能/经济证据及第九次独立复审仍 OPEN。
<!-- /EIGHTH_REMEDIATION_CURRENT -->

## Zhangtian第七轮full review后作者整改（2026-09-08）

**Verdict与授权**：第七次fresh-context full re-review由persistence/engine/QA、UX/accessibility/audio specialists与全新creative-director独立综合，结论为`MAJOR REVISION NEEDED / XL`。第六轮7组闭合矩阵为0项CLOSED、7项PARTIAL；用户回复“继续”，授权按报告的完整跨文档范围推进。本作者上下文不能批准自身。

**Save、恢复与crash oracle**：`ReservationCreateResultV3`固定204 bytes并回显pre-durable source correlation、durable operation/recovery identity及全部allocated identity；result enum封闭到12 codes并含`ID_EXHAUSTED`。120-byte receipt只保存durable SUCCEEDED，public delivery code独立表达SUCCEEDED/RECONCILE_FOUND。update UNCERTAIN按selected formal next/old hash唯一返回FOUND/FOUND_OLD并commit/discard scratch；7-row operation truth×12-row cut truth唯一生成84-row crash fixture。worker row/mailbox为220/484 bytes。

**可访问语义、输入与并发**：ADR将group预算更名为7-row `AccessibleScreenProfileManifestV1`，另冻结94-row `AccessibleNodeContractV1`与34-row `AccessibleScreenStateVariantManifestV1`。Settings控件role/action逐类固定；Settlement新增typed detail source/page/command与AC，window capacity6。Input四个focus动作只生成presenter-local command，ACTIVATE/BACK验证node后才进入owner command gate。native入口冻结64-byte header、64×96-byte row的6208-byte MPSC，明确CAS ticket、release/acquire publication、full不推进、producer-in-flight与shutdown drain顺序。

**经济量词、静态证据与边界**：AC-ZB04只在43200..108000 ticks的有随机奖励Victory/Defeat cohort比较gross rate；早败quantity0不进入rate分母。两份YAML parse、246个entity name唯一、HPM/RUP/RRD/RCO/RCC=25/5/13/7/12、a11y profile/node/state=7/94/34、204/220/484-byte Save与64/96/6208-byte MPSC算术、stale扫描和`git diff --check`均通过。当前仍只是作者静态合同传播；generated Config/hash/codec/crash/a11y/InputMap artifact、cross-platform golden、Godot/GDUnit4、平台barrier/process-kill、Android/iOS TalkBack/VoiceOver、gamepad、性能、正式音频、经济模拟与目标玩家试玩均未执行。状态保持`In Review / Re-review Pending`、`battle_ready=false`；下一步必须在fresh context执行第八次full re-review。

## Zhangtian第六轮full review后作者整改（2026-09-07）

**Verdict与授权**：第六次fresh-context full re-review由game/economy/systems、persistence/engine/QA、UX/accessibility/audio specialists与全新creative-director独立综合，结论为`MAJOR REVISION NEEDED / XL`。第五轮7组闭合矩阵为3项仅静态CLOSED、4项PARTIAL；用户回复“继续”，授权按报告的完整跨文档范围推进。本作者上下文不能批准自身。

**Save与恢复**：MVP每局含NONE都使用176-byte `ReservationCreateRequestV2`，pre-durable duplicate/reconcile按source correlation，不要求caller猜未返回request ID。终局只允许`ReservationUpdateRequestV2(RESOLVE)+1112-byte ResolveReservationPayloadV3`一次同槽写reward/tombstone、next profile、264-byte resolution与live-carrier clear，返回160-byte `TerminalRunResultV2`；worker→main改为396-byte typed mailbox。reservation result code/disposition/presence、RRD前置invariant与12-stage×7-operation=84-row crash-cut作者manifest已冻结。

**RNG、配置与经济**：pre-active base/refresh使用scratch `PreActiveRngWindowLeaseV1`，只有recovery双镜像durable后才发布cursor/offer/revision；FAILED不消费权威RNG，UNCERTAIN只reconcile。`ConfigArtifactRetentionManifestV1`在同Save schema lifetime append-only，最多32个artifact/16 MiB，突破前必须先有migration。产品承诺收窄为Victory random gross grant-rate优势；net flow另覆盖服丹/NONE、胜率、局长和饱和，不再宣称任意Victory净库存必优于Defeat。

**无障碍、输入与音频**：ADR新增七个screen-state node profile；Settlement detail固定6-row分页，Settings以ADJUSTABLE/SWITCH/COMBOBOX表达。CONTROLLED_FAULT改由persistent GameRoot fault presenter拥有并支持no-profile sentinel。native入口固定MPSC64→serial ticket order/sequence allocator→capacity32 SPSC；Input冻结六行Meta UI keyboard/mapped-gamepad action，战斗移动仍仅Touch。Audio只在typed terminal disposition=RELEASED时播放返还声；正常fresh-live未静音路径exactly1，只有kill窗口0..1。

**静态验证、证据边界与下一步**：两份YAML已用plain `YAML.load_file`解析；registry共243个entity name且唯一；HPM/RUP/RRD/crash-stage/node-profile作者行数为25/5/13/12/7；create request/result、update result、terminal result、RESOLVE payload、Save row/mailbox byte arithmetic分别为176/144/136/160/1112/176/396；`git diff --check`通过。当前仍仅为作者静态合同传播；generated Config/hash/codec/crash/a11y/InputMap artifact、cross-platform golden、Godot/GDUnit4、平台barrier/process-kill、Android/iOS TalkBack/VoiceOver、gamepad、性能、正式音频、经济模拟与目标玩家试玩均未执行。状态保持`In Review / Re-review Pending`、`battle_ready=false`；下一步必须在fresh context执行第七次full re-review。

## Zhangtian第五轮full review授权整改（2026-09-07）

**Verdict与范围**：第五次fresh-context full re-review经systems/persistence、UX/UI/QA/accessibility specialists与fresh creative-director独立综合，结论仍为`MAJOR REVISION NEEDED`、scope XL。第四轮6组blocker为0 CLOSED / 6 PARTIAL；用户回复“授权”，批准对本轮7组根blocker做完整跨文档作者整改。本会话不能批准自身。

**状态机与持久语义**：删除玩家pre-durable cancel公开event/guard/action；base offer readback前interactive snapshot/action为0，LFD25只处理明确NOT_STARTED_CLEAR，任一write possible/readback unknown/durable/visible事实归LFD26。`pre_active_semantic_generation=1`不再混用runtime generation；candidate ID按`(offer_revision-1)*4+slot+1` checked生成。

**Save/Hash/经济**：Save统一版本化result，新增120-byte `ReservationReceiptV1`与`ReservationCreateResultV2`，receipt ID固定等于request ID，终态不再循环分配；reconcile从12扩13行，只有双正式槽、temp、writer quiescent完整proof可清volatile correlation。Save HPM从22扩24行并覆盖direct-NONE/receipt；无障碍hash由独立6-row manifest承载。`cap_disposition`新增PARTIAL_BOTH并固定total precedence。

**Config与无障碍**：author current counts统一为54 guard/72 action/5 app-render。六屏row capacity固定HOME16/PREP16/PRE_ACTIVE12/BATTLE_PAUSED24/SETTLEMENT24/CONTROLLED_FAULT12，snapshot exact bytes为4076/4076/3084/6060/6060/3084；mailbox改2476 bytes、i64 read/write sequence、NATIVE_ANY先marshal到唯一PLATFORM_SERIAL_INGRESS producer，主线程sole consumer。mapped gamepad focus/activation正式支持，raw unmapped axis为0 business command。

**静态验证与下一步**：`git diff --check`、两份YAML parse与237个entity name唯一性通过；54 guard、72 action、5 app-render、24 hash-preimage、5 reservation-payload、13 reconcile rows匹配。generated canonical artifact、Hash256/codec/migration golden、Godot/GDUnit4、进程强杀、Android/iOS无障碍、gamepad、性能、音频与经济/体验证据仍未执行。状态保持`In Review / Re-review Pending`、`battle_ready=false`；下一步在fresh context执行第六次`/design-review design/gdd/zhangtian-bottle.md --depth full`。

## Zhangtian第四轮full review授权整改（2026-09-07）

**Verdict与范围**：第四次clean-context full review由game/economy、systems/persistence/Godot/performance、UX/UI/QA/audio/accessibility specialists及fresh creative-director综合，结论仍为`MAJOR REVISION NEEDED`、scope XL。第三轮6组blocker仅第1组CLOSED，其余PARTIAL；用户回复“授权”，批准对本轮6组根blocker做完整跨文档作者整改。本会话不能批准自身。

**持久语义与生命周期**：SkillDraft新增252-byte `PreActiveOfferSemanticV1`与296-byte `PreActiveLoadoutSemanticV1`，durable hash排除snapshot/bank/generation等process-local identity并在新进程按config content key rebind。GameRoot新增`PRE_ACTIVE_CANCEL_REQUESTED`、`PRE_ACTIVE_CANCEL_ALLOWED`及transition，首个offer durable/visible前才可release；guard/action作者表为56/72 rows。

**Save/Hash/Audio ABI**：`ReservationUpdateRequestV2`只接受5-row manifest定义的inline canonical payload；V2 result返回profile/domain revision、unlock transition与durable receipt ID/hash。terminal transaction写264-byte `DurableRunResolutionV2`并清live reservation/marker；Save签发22-row actual `HashPreimageManifestV1`。容量复算为`SlotPayloadMax=42180,SlotEncodedMax=42392`。Audio只能从matching V2 result/124-byte stamp取得receipt identity，不能由UI或裸success推断。

**经济、direct-NONE与无障碍**：Outcome seed仅封存random gross；Settlement的64-byte `AppliedRewardRowV1`是starter、cap disposition与applied amount唯一真相，unlock/claim只接受0/0或1/1。Home/Settlement direct NONE升级128-byte `DirectNoneStartSliceV2`，无种子重开视觉与读屏均明确“不服丹，再次挑战”。ADR/registry升级`AccessibleScreenSnapshotV2`：248-byte rows含layout generation、logical bounds、visible/clipped与8 typed args；HOME/PREP/PRE_ACTIVE_CHOICE/BATTLE_PAUSED/SETTLEMENT/CONTROLLED_FAULT为六个action-bearing states，其余state仍drain；app render workload为5 rows。

**静态验证与下一步**：`git diff --check`、两份YAML parse与229个entity name唯一性通过；56 guard、72 action、5 app-render、22 hash-preimage、5 reservation-payload、12 reconcile rows匹配；264/64/248/76/2468/42180/42392-byte算术复算一致。generated canonical artifact、Hash256/codec/migration golden、Godot/GDUnit4、进程强杀、Android/iOS无障碍、性能、音频与经济/体验证据仍未执行。状态保持`In Review / Re-review Pending`、`battle_ready=false`；下一步在fresh context执行第五次`/design-review design/gdd/zhangtian-bottle.md --depth full`。

## Zhangtian第三轮full review授权整改（2026-09-04）

**Verdict与范围**：第三次clean-context full review由game/economy、systems/persistence、QA/UX/engine specialists及creative-director综合，结论仍为`MAJOR REVISION NEEDED`、scope XL。用户回复“授权”，批准对6组根blocker做完整跨文档作者整改；本会话不能批准自身。

**冻结修订**：Victory合法tick域为43200..108000，其余outcome为0..108000；胜败随机速率用`3*T_defeat>T_victory`交叉乘法，normal Settlement先consume reservation再以post-consume held room与lifetime room发奖。首个聚气offer durable/visible后，Back/关闭/重启只能恢复同一offer，不能release后fresh重抽。跨进程持久身份改为`config_content_revision+config_content_hash`，process-local snapshot ID不落盘；candidate/recovery/payload/reservation为132/360/660/1088 bytes。

**ABI与表现闭合**：Save新增generation/checkpoint/hash CAS的reservation update、12-row reconcile V2、256-byte terminal resolution和terminal transaction清live reservation/marker；hash manifest区分SELF_ZERO_FIELD与EXTERNAL_PAYLOAD。Home/Settlement direct NONE各嵌入124-byte `DirectNoneStartSliceV1`。Save fresh-live成功签发124-byte `SaveDurableStampFactV1`，Audio只消费真实operation/attempt/request/receipt identity。无障碍bridge单列`AppAdapterTopologyManifestV1`，native callback只进capacity32 SPSC，并由所有meta TopState render-frame pump处理；SkillDraft session RNG registry修正为1..20。

**证据边界与下一步**：本轮只有文档、YAML与算术/旧口径静态检查；generated codec/hash/capacity artifact、Godot/GDUnit4、进程强杀、Android/iOS无障碍、性能、音频资产和经济/体验测试仍未执行。状态保持`In Review / Re-review Pending`、`battle_ready=false`。下一步必须在fresh context再次执行`/design-review design/gdd/zhangtian-bottle.md --depth full`。

## Zhangtian full review 方案A整改（2026-09-03）

**第二轮静态裁决传播**：UI唯一业务命令仍为`PrepConfirmCommandV1`，Home与Settlement再次挑战均按available分流：有库存进Prep、无库存同press经noninteractive PREP直接NONE。Save/Zhangtian在durable reservation事务内分配持久identity；固定336-byte `RunStartRecoveryV1`、636-byte Zhangtian payload、1064-byte reservation、100-byte candidate与七checkpoint，journal只存在于DurableReservation nested一份。pre-active choice按offer revision/refresh/selected candidate/session/config/loadout字段确定性重放；callback丢失/重启继续同一handoff，Active后无Outcome强杀按消费收敛。

**玩法/经济裁决**：聚气丹仍为credit14/普通ordinal1预开局选择。合法结算域固定0..108,000 Active ticks；VICTORY发candidate×3，DEFEAT仅`survival_ticks>=43,200`发×1，首次正常结算三类starter各1且单独计cohort，版本`PROVISIONAL-ECONOMY-V4`。因此最慢合法Victory随机速率3/30=0.10，高于最快eligible Defeat的1/12。held cap只约束每类available+reserved≤999，lifetime earned/consumed受int64与守恒约束。

**接口/表现裁决**：修正`DomainRecordV1.payload_hash`并补journal hash、candidate/slice exact schema与top-level capacity枚举；GameRoot五行app-service topology现有actual rows，所有TopState每render frame调用一次app-service result pump。`AUDIO_APP`是唯一可持有预建app-scope AudioStreamPlayer的服务；`SAVE_DURABLE_STAMP`把unlock transition作为payload bit，无异步join/timeout。ADR-0001冻结immutable semantic tree→Android/iOS native adapter→typed action架构；runtime/device仍BLOCKED。

**验证边界与下一步**：文档/YAML/编号/diff静态检查已完成：336/100/52/244/636/1064-byte结构和42156/42368/262144容量算术复算一致，30-row load、54-row guard、5-row app-service topology连续完整；另外将Settlement零库存来源独立为`SETTLEMENT_DIRECT_NONE`，避免伪用HOME generation。仍需生成canonical artifact、Hash256/codec/migration golden与运行时容量checked-sum，并提交Godot 4.7.1 crash/device/accessibility/performance与经济试玩证据。下一动作是在新的clean context再次执行`/design-review design/gdd/zhangtian-bottle.md --depth full`；本轮不得称Approved、implementation-ready、runtime verified或battle_ready。

## 剩余四系统批量作者设计（2026-09-03）

**结果（作者基线，已被上方full-review整改段更新）**：新增`zhangtian-bottle.md`、`settlement-system.md`、`home-ui.md`与`prep-ui.md`；当前均为`In Review / Re-review Pending`。MVP枚举现28/28获得作者设计覆盖；Buff仍按既有决策并入Damage，不另造GDD。

**关键冻结（以本节上方第二轮裁决为准）**：掌天瓶采用三seed/三pill、每丹cost1、held cap999、132-byte domain；Loading preflight后恰1次logical均匀candidate并持久化，VICTORY发×3、Boss线DEFEAT发×1、首次正常结算另给三类各1。聚气丹起始curve credit14/LV2/XP0并在Active前完成可恢复普通ordinal1选择，锻体+15% maxHP，明心+8个百分点crit。Settlement拥有BATTLE_RULES stable11/phase6+7、`0/6/0/0` contribution、6-row reward、3-row record和136-byte domain。Home提供恢复阻断、direct NONE和60-byte Settings domain；RunStartRequest不可回写，candidate/pre-active写同一durable recovery。

**传播与证据边界**：已同步主概念、RNG、GameRoot、Save、Config、Damage、SkillDraft、Settlement、Home、Prep、Audio、technical preferences、registry与systems-index。静态作者合同不等于独立评审或实现验收；canonical导出artifact、owner/workload/capacity checked-sum、四domain codec/migration、Godot/GDUnit4、crash/device/performance、移动端读屏bridge与玩家测试尚未闭合，`battle_ready=false`。

**下一步**：先完成全仓库静态一致性检查，再在clean context分别执行四份`--depth full`复审；根据verdict整改后才进入pre-production gate/开发拆解。

## Progression Tree 作者设计（2026-09-03）

**结果**：新增`design/gdd/progression-tree.md`，状态`Designed / Full Review Pending`。冻结QINGYUAN/LONGCHUN/DAYAN三分支各五级、统一功法残页钱包、176-byte Progression domain、逐级原子购买/generic Save mutation、下一局不可变battle projection、九条公式与30项证据化AC。无洗点、退款、分支锁、装备/境界/prestige；选择仅决定先后顺序。

**经济与perk**：采用`PROVISIONAL-ECONOMY-V1`成本4/8/12/16/20，单支60/全树180；每5400 committed Active ticks（90秒）1页、cap8、无胜利bonus、ABANDONED=0，以正常结算中位数6..8页校准8..10局一支/23..30局全树。青元每级attack+3%、L5青元family projectile pierce+1；长春每级maxHP+3%、L5首次非致命严格跌破30%时恢复10%H；大衍每级crit+1百分点/pickup+2%、L5初始refresh 2→3。

**传播与阻断**：已同步Save generic domain mutation、Config、GameRoot、Player、Damage、Weapon、Drop/Leveling、SkillDraft、RNG、technical preferences、registry与systems-index。SkillDraft单session最大page/call已由3/15升级4/20。BattleRules/Settlement actual reward row、Save codec/runtime、青元hit/workload容量、长春phase6 consume receipt、Home UX、30局目标玩家试玩、Godot/runtime/device及clean-context full review仍BLOCKED/OPEN，`battle_ready=false`。

**下一步**：按依赖顺序设计Zhangtian Bottle；Progression Tree应在clean context执行`/design-review design/gdd/progression-tree.md --depth full`。

## SaveSystem 作者设计（2026-09-03）

**结果**：新增`design/gdd/save-system.md`，状态`Designed / Full Review Pending`。冻结Save为app-scope唯一durable persistence owner、非phase participant；采用单writer、temp原子替换与A/B同generation双镜像，无current-pointer，只有file/directory barrier、正式槽reopen及双副本逐位readback成功才回success。sealed Outcome/Completion、Save attempt与proposed after-image先作为durable pending carrier落盘，支持同commit跨进程reconcile。

**一致性与恢复合同**：commit与discard按首次durable fact而非callback顺序仲裁；commit先落盘则discard返回既有receipt且不写tombstone，tombstone先落盘则晚到commit永久stale。开局reservation、64-row滚动resolved archive、ArchiveRetireJournal partial retry、identity checked allocator、schema migration与前向不兼容均纳入同一双槽transaction。任一损坏槽存在时另一VALID槽只作只读恢复候选，显式恢复并readback前禁止覆盖/新局；双坏、同generation异payload、未来schema或resolution冲突均fail closed，不静默清档。

**保持阻断**：Progression/Zhangtian/Settlement/Settings实际persistent domain与mutation schema、Hash256/canonical codec ADR、`max_slot_bytes`、平台排他writer lock和真实durable barrier、Godot4.7.1 Android/iOS kill/reboot/低空间/性能、Home/Settlement UX、migration corpus及clean-context full review仍BLOCKED/OPEN。当前只有静态作者设计，`battle_ready=false`。

**下一步**：按依赖顺序设计Progression Tree；SaveSystem应在clean context执行`/design-review design/gdd/save-system.md --depth full`。

## Audio Feedback 作者设计（2026-09-03）

**结果**：完成`design/gdd/audio-feedback.md`，状态`Designed / Full Review Pending`。Audio是consumer-only调度owner，不成为phase participant；沿用`PLAYER_AUDIO stable_order=3 / ack bit=0b100`，区分transient准入处置ACK与REVIVE/DEATH critical完成/fallback后ACK。冻结8级priority、6个关键保留voice、22个预建voice provisional基线、10-bus树、stable merge/steal/variant/duck、pause/terminal/mute/mono/fallback语义与20项证据化AC。

**纠错与传播**：明确voice node 22不等于event bank容量；`H_audio`必须由所有producer的per-sealed-capture rows checked sum，当前保持BLOCKED。消除/登记Weapon-vs-Projectile cast、Damage-vs-Enemy death、Leveling-vs-SkillDraft升级三类潜在双响owner缺口；同步GameRoot、Config、technical preferences、Player、Damage、Weapon、Projectile、Risk、Elite、Boss、BattleUI、registry与systems-index。Bus树实际为10个节点（含Master与SFX父级），未沿用专项初稿“9-bus”误计数。

**保持阻断**：非Player audio event rows/maxima/ACK、正式semantic owner table、Sound Bible与streams/fallback、LUFS/peak/duck/merge最终值、Godot4.7.1 pause/finished/device行为、BattleRules/Settlement handoff、shield ABI、min-spec audio-thread/underrun/内存、mono/扬声器/耳机/静音用户证据及clean-context full review。当前只有静态作者设计，`battle_ready=false`。

**下一步**：按推荐顺序设计SaveSystem；Audio应在clean context执行`/design-review design/gdd/audio-feedback.md --depth full`。

## BattleUI 作者设计（2026-09-03）

**结果**：完成`design/gdd/battle-ui.md`，状态`Designed / Full Review Pending`。冻结BattleUI为consumer-only presenter+typed command adapter，不成为phase participant或gameplay truth owner；GameRoot按同一sealed capture提供跨owner `source_revision_vector`，各revision不要求数值相等但必须逐项matching，禁止新HP+旧XP/Boss的拼帧与Node introspection。

**交互与表现合同**：冻结顶部竖屏HUD、1/2/3/4行choice、全屏`ChoiceGestureSurface`和持久`ChoiceTouchDrain`；owner committed、所有touch terminal且Input即时blocked=false前不得完成pause reason。方向先跟踪1 Boss+4 Elite后聚合，reward-bearing Elite不得隐藏。Damage数字分开登记64同时可见与96 Pool，不把pool容量冒充可见数。Player revive首帧原子35%HP+SPENT，`VICTORY+lethal`只显示胜利，UNSAFE使用非颜色危险语义。21项AC覆盖atomic bundle、ACK、输入唯一性、pause矩阵、动态字体、色弱/静音、min-spec与证据真实性。

**传播与边界**：已同步GameRoot、Input、Config、technical preferences、registry与systems-index。Leveling/Weapon/Boss/Elite/Risk/Damage正式HUD/presentation views、touch平台manifest与bank容量、choice priority、treasure exhaustion、project.godot/BattleUI scene、移动端screen reader、Art/VFX/Audio、min-spec/真机/用户测试及clean-context full review仍BLOCKED/OPEN。当前只完成文档静态设计，`battle_ready=false`，不能称implementation-ready或runtime verified。

**下一步**：按推荐顺序设计Audio Feedback；BattleUI应在clean context执行`/design-review design/gdd/battle-ui.md --depth full`。

## BossStateMachine 作者设计（2026-09-03）

**结果**：新增`design/gdd/boss-state-machine.md`，状态`Designed / Full Review Pending`。冻结43200 completed Active ticks的玩家相对mandatory入场与120t首伤门；P1用最短312t纯动作轮转教授扑咬/扇毒/八向毒弹，50% crossing按release PONR/当前bite segment安全节拍exact-once排队，下一合法MOVEMENT_COMMIT进入90t PHASE_SHIFT；若arrival未结束则保留pending至120t门后。P2用最短444t纯动作轮转、双扑咬、0/2噬灵虫与外圆毒域，TRACK门外时间另计；毒域在进入phase break时冻结Player事件anchor、break结束后以10→4.5/3600t收束并每60t最多伤害一次。Boss死亡同tick提供lethal projection输入，无FATAL时Boss+Player同死仍VICTORY；核心灵药`CORE_HERB`与传送阵只作sealed Outcome后的不可交互结算表现。

**架构修正与传播**：BossStateMachine是Enemy stable-order4内部typed capability，不新增BOSS participant，也不冒充尚未设计完整的BATTLE_RULES。Boss projectile pending/active contribution均8、nonprojectile revive hazard=2、direct damage rows=2。Boss召虫2只且仅在fixed Elite/Boss schedule已消费后的P2出现，因此`max(12+9+1+1,12+9+2)=23`，Spawn 23/552无需再次扩容。旧危险圆V1无法表示圆外毒雾，现将Player/Damage/Config契约版本化为`ReviveHazardSnapshotV2`，shape支持`CIRCLE/EXTERIOR_CIRCLE`。已同步Enemy、Spawn、Config、Projectile、Damage、Player、Stage、Drop、Elite、GameRoot、registry与systems-index。

**保持阻断**：Weapon与behavior2/4 Normal远程的Projectile pending/active枚举、Enemy nonprojectile与Stage hazard总量、Damage cone shape、BATTLE_RULES phase/contribution/death→reward预留、完整WaveSchedule与Boss平衡、behavior5自爆合同、BattleUI/Audio/VFX/Art Bible、GameRoot workload重生成、Godot/GDUnit4、min-spec真机/性能/UX及clean-context full review证据。当前仅作者文档与静态传播，`battle_ready=false`。

**下一步**：按推荐顺序设计BattleUI；BossStateMachine应在clean context运行`/design-review design/gdd/boss-state-machine.md --depth full`，本轮systems/QA/art authoring输入不构成独立verdict。

## Elite Enemies 作者设计（2026-09-03）

**结果**：新增`design/gdd/elite-enemies.md`，状态`Designed / Full Review Pending`。将behavior 6/7内容唯一owner从Enemy基础设施拆出：所有fixed/Risk Elite有60 Active ticks入场无伤门；巨甲蜈蚣为24t预警、三段同轴6-unit冲刺、段间6t断点与150t破绽；鬼雾修士为360t周期、18t落点预警、30t魂针预警、三针T+1 Projectile原子batch、24t后摇与三血傀儡0/3原子cluster。fixed 6:00/10:00、Risk 1.30倍率/45秒持续与Drop 160/300/240+宝匣边界均已接线。

**架构修正与传播**：三只鬼修可同tick召唤9只，旧Spawn intake14无法同时容纳12 Wave Normal+9 summon+Elite+Boss；现升级`SpawnIntentBankV2=23`与552 position words，不改298/4/1 active cap或Pool容量。魂针Enemy Projectile contribution冻结为9，但仍须与Weapon/Boss闭合32总额。Enemy death staging升级为8字段并加入`source_choice_id`，使两次Risk抽同一behavior时仍可唯一join。已同步Enemy、Spawn、Config、Projectile、Damage、Drop/Leveling、RiskChoice、registry与systems-index。

**保持阻断**：Weapon+Elite+Boss Projectile pending/active checked sum、Damage intent与revive hazard总量、behavior5接近/30%HP自爆及友伤合同、完整WaveSchedule与数值、BattleUI/Audio/VFX P0 fallback、GameRoot workload重生成、Godot/GDUnit4、min-spec真机/性能/UX与clean-context full review证据。当前仅作者文档与静态传播，`battle_ready=false`。

**下一步**：按推荐顺序设计BossStateMachine；Elite Enemies应在clean context运行`/design-review design/gdd/elite-enemies.md --depth full`，本轮systems/QA/art authoring输入不构成独立verdict。

## RiskChoiceSystem 作者设计（2026-09-03）

**结果**：新增`design/gdd/risk-choice-system.md`。冻结4:00/8:00两条completed-gameplay-tick机缘、stable order9、owner contribution `0/0/0/2`、SkillDraft14+RiskChoice2=global blocking16，以及Risk Outcome scalar slot1/ids2/results2。SAFE提交25% max-HP recovery与600 Active ticks `RISK_WARD`（0.80 incoming multiplier，provisional balance）；TREASURE每次精确1个RISK_CHOICE weighted roll、生成HP/base damage×1.30的mandatory Elite，45秒=2700 Active ticks后仍追击且240 XP+宝匣资格不变。

**架构裁决与传播**：旧合同允许两只risk+两只fixed Elite最坏4并发，但Enemy/Spawn/Grid active cap只有2。现统一保持ENEMY总cap303，class hard cap改为Normal298+Elite4+Boss1；Pool F1改为Normal`298+0+12+10=320`、Elite`4+0+1+1=6`，query/owner总容量303不变。Spawn context升级为10-field V2以携带provenance、choice/stage identity与两个倍率。已同步GameRoot、Config、Damage、Enemy、Spawn、SpatialGrid、Object Pooling、Drop/Leveling、SkillDraft、registry与systems-index。

**保持阻断**：BattleUI/Input touch drain与copy table；WaveSchedule/4 Elite压力、ward/权重/XP平衡；40级宝匣耗尽补偿；GameRoot workload重生成；Elite生产资产与首击预警；Godot/GDUnit4、allocator guard、min-spec、真机、UX/audio及独立full review证据。当前仅作者设计与静态传播，`battle_ready=false`。

**下一步**：按推荐顺序设计Elite Enemies；RiskChoice应在clean context运行`/design-review design/gdd/risk-choice-system.md --depth full`，本轮systems/QA/visual authoring specialist输入不构成独立verdict。

## DropSystem + Leveling/XP 合并作者设计（2026-09-03）

**结果**：新增`design/gdd/drop-leveling-system.md`，保留Drop/Leveling双owner边界并冻结stable order 7/10。Drop拥有300 active/320 pool、290 XP+10 special硬分槽、606-row award ledger、300-row materialize/pickup plan、固定每eligible Normal death一次DROP RNG及逐fact prefix PONR；Leveling逐PICKUP fact应用`T(L)=8+5L+ceil(3L²/5)`，硬上限40、总XP16552、39-row debt、10-row visible window。SkillDraft同步为真实3/2/1选一与1/3/5固定RNG calls，queue冻结为10 level+4 treasure=14。

**跨文档传播**：Enemy death staging从4字段升级为7字段；GameRoot/Config接纳DROP/LEVELING rows与owner contributions；Damage接纳0.30 max-HP回春边界；registry与systems-index同步。独立qa-lead对初稿提出的PONR prefix收敛、逐fact归因、carrier定容、精英XP→宝匣子序、核心灵药唯一owner、cooldown revision等gap已回写合同与AC。

**保持阻断**：`BLOCKED-WORKLOAD-REGEN`（GameRoot `{1,303,384,503}` 与400 Projectile/300 Drop权威cap冲突，须整表重生成）；`BLOCKED-BLAST-ABI`；`BLOCKED-TREASURE-EXHAUSTION`；WaveSchedule/15分钟平衡、BattleUI/UX、Godot/GDUnit4、min-spec/performance/runtime证据OPEN。原`BLOCKED-RISK-CAPACITY`已由上方RiskChoice设计闭合为`RESOLVED-RISK-CAPACITY`；当前仍仅作者设计与静态传播，状态保持Designed / Full Review Pending，`battle_ready=false`。

**下一步**：按已授权批次设计RiskChoiceSystem；本合并GDD应在clean context运行`/design-review design/gdd/drop-leveling-system.md --depth full`，不得把本轮specialist/qa authoring pass视作独立verdict。

## “感知无限、技术有限”正式架构裁决（2026-09-02）

**Decision**：Camera2D锁定matching已发布Player位置；地表以固定数量tile重定位或world-UV shader形成无限延展观感；SpawnDirector在玩家相对视野外矩形环生成。底层使用大型有限`world_safe_aabb=[-16384,16384]²`与1800秒技术时限，不实现数学无限、坐标wrap、runtime origin rebasing或可见边界clamp。

- Stage V2冻结22.5×40可见尺寸、padding 1、ring depth 4、despawn margin 12，并发布`StageWorldDomainViewV2`。
- Player合法移动原样提交，越技术域fail closed；17个复活候选不clamp，全量readback+domain验证后才评分/PONR。
- SpatialGrid改为signed cell坐标的稀疏occupied-cell索引；最多1000 entries，局部query枚举超过262144格时扫描active entries，禁止按world面积建dense array。
- SpawnDirector新增V1 GDD：上一tickPlayer anchor、四strip环采样、固定8 attempts×3 RNG words=24 words、cap admission、普通敌远距无奖励退役；elite/Boss距离豁免。
- Enemy移除撞墙/arena clamp与旧margin语义；GameRoot冻结Player publish→Stage camera follow及T-1 spawn anchor时序；Config/registry同步V2 schema和数值。

**证据边界**：已做Markdown/YAML与旧术语静态检查；尚未进行clean-context独立full review、Godot运行、GDUnit4、长局数值精度、稀疏Grid性能、固定RNG trace、相机/地表视觉或移动真机验证。下一步分别复审Stage V2、SpatialGrid V2、PlayerController、SpawnDirector，再复审GameRoot传播。

## 最小可玩灰盒切片（2026-09-02）

**验证假设**：玩家通过单手移动、自动飞剑、追击敌人与灵气升级，能在30秒内形成清晰的“走位→击杀→变强”正反馈。

**范围**：竖屏竞技场、触摸/鼠标拖动与WASD、自动索敌飞剑、一种追击敌人、灵气掉落、三选一升级；达到Lv.4结束本轮。正式GameRoot、Pool、Grid、Save、Boss、局外成长、美术音频与生产架构均明确删除。

**当前证据**：本机Godot 4.7.1运行`--headless --smoke-test`，20.88秒完成闭环，Lv.4、39击杀、exit 0。该证据只证明工程加载与自动状态链可运行；触摸响应、走位压力、攻击反馈与实际乐趣仍待用户试玩。

**下一步**：打开`prototypes/zhangtian-trial-concept/project.godot`实际试玩；反馈是否能完成一轮、首次升级耗时、最好/最差手感点，再决定PROCEED或PIVOT。

### PIVOT 1 — 玩家中心镜头（2026-09-02）

首次试玩确认移动跟手、飞剑数量成长反馈明确，但固定窗口边界让空间像盒子，削弱走位价值。灰盒已改为Camera2D持续以玩家为中心、敌人在当前视野外围生成、世界网格随玩家延展且无可感知边界。第二轮自动验证在25.85秒完成Lv.4、45击杀、exit 0；真实空间感待用户复测。

### Iteration 2 — 75秒完整Demo结论（2026-09-02）

**Verdict: PROCEED。** 用户实际完成试玩并确认：铁背妖狼容易辨认；最后25秒敌潮压力合理；升级与胜利结算清楚。结合自动闭环证据（75秒、Lv.4、134击杀、首次升级14.67秒、exit 0），当前灰盒已验证移动、自动飞剑、成长反馈、双敌人压力和完整胜负闭环。尚未验证正式资产、音频、移动真机性能、生产架构或长局平衡。

## PlayerController 第四轮 lean re-review 与获批整改（2026-09-02）

**Verdict: MAJOR REVISION NEEDED；3组blocker已按用户“修订，授权”完成静态整改，Full Re-review Pending。** lean模式未委派specialist或creative-director。

- HP/maxHP owner闭环：Config在Loading按`base×(1+0.03×long_chun_level+(iron_body_pill?0.15:0))`冻结起始maxHP；战斗内Longchun/Buff/RiskChoice只提交typed intent，由provisional PlayerRecoveryResolver在phase5发布A/B resolution，Player在phase6固定damage→lethal→heal clamp并提交canonical HEAL fact。
- Presentation闭环：`PlayerPresentationFrameV1`改为matching已发布motion+HUD的allocation-free copy-out join，无第三套bank/selector；Player one-shot capability统一提交optional motion、HUD、optional transient、optional critical PUBLISHED，再由GameRoot做Node mirror。
- REVIVE_CLEAR归属闭环：Player只写私有intent bank并调用scoped resolver；journal backing、sequence与Grid/Pool副作用归Enemy/GameRoot，row固定`participant_id=ENEMY`并计入ENEMY 303，PLAYER lifecycle contribution保持0。
- 传播范围：Player、GameRoot、Config、Enemy、technical preferences、registry、systems-index与本session state；新增PWM04、PCM33、AC-PC54–57、OQ-PC13。

**证据边界**：仅完成Markdown/YAML静态契约与一致性检查；Damage/Recovery/Hazard/BattleUI正式GDD、实现、runtime、Godot/GDUnit4、真机、性能、UX/audio证据仍BLOCKED/OPEN。下一步必须在clean context独立执行`/design-review design/gdd/player-controller.md --depth full`。

## PlayerController 第二轮 full re-review 与获批整改（2026-09-02）

**Verdict: MAJOR REVISION NEEDED，scope XL；Re-review Pending。** 本轮9个specialist视角及独立creative-director把首轮7组均判为PARTIAL，去重为7根blocker：terminal因果、phase6 typed I/O/双selector、Resolution token+PONR reservation、Godot数值/ownership/sort、复活候选总序、VICTORY/Critical event transport、AC/workload可执行性。

用户回复`A,授权`，按终审裁定执行：安全等级与surface clearance优先，`clear_count ASC`只在二者相同后破平；不让少清怪压过安全。

本轮9文件范围：Player、GameRoot、Config、Stage、Enemy、technical-preferences、registry、systems-index、active session。冻结内容包括：phase5后`TerminalPrecollectionViewV1`；canonical Resolution token；Player phase6 prepared output与one-shot motion capability；PONR前完整journal/fact/capability reservation；motion `batch_authority_revision`；Loading期binary32 inward helper与identity parent chain；Enemy current+swept九array snapshot；完整tuple原地sort；UNSAFE frame/HUD/P0投影；capacity 1 transient + capacity 2 retained critical ledger；PWM01..03与fault/context actual matrices。

未创建DamageSystem/ReviveHazard/BattleUI GDD，未创建Player review log，未改代码。`revive_hazard_capacity`、tooling、Godot/GDUnit4、export artifact、真机/performance/UX/audio evidence仍BLOCKED/OPEN。下一步必须在clean context执行第三轮`/design-review design/gdd/player-controller.md --depth full`。

## PlayerController 首轮 full review 与获批整改（2026-09-01）

**Verdict: MAJOR REVISION NEEDED，scope L；Re-review Pending。** 真实委派9名specialist并由creative-director综合，去重为7组blocker：复活防滥用与hazard遗漏、typed orchestration ABI、real_t32/float64与publish topology、PONR先remove后fact风险、Damage/Enemy provisional carriers与容量、VICTORY+lethal表现投影、AC不可执行/可假阳性。

用户批准四项决策：

- `D1-A`：只清与复活后玩家足迹真实重叠/相切的NORMAL；300仅容量压力。
- `D2-A`：中心+内圈8+外圈8共17候选；读取next-tick hazard；无SAFE点时选择最大最小surface clearance并标`UNSAFE_FALLBACK`，无无敌。
- `D3-A`：VICTORY为victory+lethal唯一玩家面winner；保留死亡统计fact，抑制死亡pose/音效/败北/pause UI。
- `D4-A`：F7使用`distance-required_separation`真实表面净空，不用平方margin。

获批写入范围严格为10个既有文件：Player、GameRoot、Config、Input、Enemy、SpatialGrid、Stage、systems-index、registry、active session。未创建DamageSystem/BattleUI GDD、未改代码、未更新`design/gdd/reviews/player-controller-review-log.md`（该log需另行授权）。

本轮修订还冻结：typed init/phase/teardown contexts与first-error precedence；Player motion/HUD/event A/B read model；PLAYER participant actual row与四条owner contribution actual rows；Damage presence/count bank；Enemy threat完整lifecycle identity A/B snapshot；provisional `ReviveHazardSnapshotV1`且禁止Config补默认容量；非零DAMAGE fact commit为复活唯一PONR，clear rows只能在其后推进；有界预分配stable-ID canonical sort作为revive one-shot唯一sort allowlist；精确定容required±1均失败；AC41/50/51/53改为可复现实验协议。

**证据边界**：本轮只完成文档与registry静态修订。下一步必须在clean context独立运行`/design-review design/gdd/player-controller.md --depth full`；在新verdict为APPROVED前保持Re-review Pending。


## EnemySystem design-review 结论（2026-08-25，首轮 full，6 specialist + creative-director 终审）

**Verdict: MAJOR REVISION NEEDED，scope L。** 8 节齐全、依赖图完整（上游全在/下游全 Not Started）、spawn_context v1 冻结质量高、§4.7 index_margin 下界约束是亮点——框架立得住是"修订"非"重做"。9 项必须实现前修订的 BLOCKING：

- **BL1 separation phase 时序自相矛盾** [ai]：§3.10 MOVEMENT_COMMIT(stage)在前、QUERY_CONSUME(算分离)在后，但 §4.1 把 separation_correction 写进 committed_pos 同步累加。分离何时回写未裁定（OQ4 挂起但公式已写死），AC-E10/E11/E7 悬空。**待用户裁定回写时序。**
- **BL2 emit_signal 带参热路径破坏 AC-E4 零分配** [godot×perf]：§3.4 禁 connect/disconnect 未禁 emit_signal；死亡事件3参/技能意图/受击信号在 run_phase 每帧触发，Godot 4 emit 装箱 Variant 数组是稳态分配。**方向已定：死亡/受击走 GameRoot 预分配 staging bank/队列，take_damage 改直接方法调用。**
- **BL3 分离算法4缺陷 + AC-E10 数学不可实现** [sys×ai×perf]：(a)零向量退化 distance=0→Normalize(0)=0→correction=0 永久重合；(b)query_radius 用 max_enemy_bound(shape_bound) 但 overlap 用 sep_radius，语义不一致漏邻居；(c)单遍累加无 clamp + 链式不收敛；(d)AC-E10"单遍 overlap≤0"数学不可实现。**用户已裁决：采纳 CD——保留"无重叠"目标契约，AC-E10 降为 bounded 收敛(N≤3帧≤ε=sep_radius×0.1)，修4缺陷(零向量用确定性单位向量/query语义统一/累加clamp/pair-once去重)，给 k 上界(中心格≈300)计入 AC-E2 预算。**
- **BL4 AC 不可测+术语漂移+编号碰撞+缺10 AC** [qa]：AC-E1/E2(占位)/E3(约为50%)/E4(无positive control)/E10/E11/E13/E17(代码审计可自动化)不可测；AC-E5/E6 用 slot_state=FREE 但 Object Pooling R3 冻结 AVAILABLE；AC-E9 引用 spatial-grid AC-E11 与本 GDD AC-E11 撞号；缺 AC-E28~E36(零距离/版本不匹配/paused resume/召唤cap-full/精英FSM a/b/c/LOD切换/越界clamp/腐毒妖藤静止/Boss阶段切换分离延续)；§8 缺"验收设计 vs 已执行证据"标注。
- **BL5 behavior_id 3 甲壳妖虫"行为剪影"是属性非行为** [gd]：实际行为=直线追踪=behavior 0，违 §2"1-2秒识别"。**待用户裁定给什么可识别行为。**
- **BL6 死亡 VFX 时序 defer ADR 但击杀反馈是 §2 四大幻想层之一** [gd]：reset_for_pool 立即停动画截断死亡动画。**方向已定：死亡特效用独立 VFX 池节点播放，载体立即回池，§9.2 移除 defer。**
- **BL7 精英 FSM prose 不可编码 + §8 无 FSM AC** [ai×qa]：§3.6 无触发谓词/冲刺方向/WEAKENED时长/退出条件，§7.4 无数值；按 coding-standards Logic 类须 BLOCKING 单元测试，须补 AC-E32a/b/c。**方向：补状态机表(每条边{trigger/action/next})+spike锚点数值(标待Config)。**
- **BL8 BLINK落点/召唤cap-full/borrow跨phase 未定义** [ai]：**BLINK 落点待用户裁定；召唤 cap-full 方向已定(逸散VFX+不重试本周期)；borrow 跨 phase 方向已定(intent latch 下一 tick SPAWN_INTENT)。**
- **BL9 LOD 与 stage-map R1"相机固定全显 arena 22×40"矛盾，reduced 路径成死代码** [gd×perf]：**用户已裁决：移除 LOD reduced，删 §3.9/§4.4/AC-E15/16/17，消解 perf R1 预算真空。**

**Specialist 分歧**：(1)分离契约 gd 主张软分离放宽 AC vs sys/ai/perf 主张修算法保契约——CD 裁决采纳后者但 AC-E10 降为 bounded 收敛，**用户已确认**；(2)LOD 存废 gd 主张移除 vs perf 主张入预算——**用户已确认移除**。

**可合理 defer（不阻塞本 GDD）**：节点架构 ADR(OQ1)、knockback_max 归属(OQ2)、max_enemy_bound 数值(OQ3)、borrow→insert 时序(OQ5)、Boss participant 边界(OQ6)、质量比具体数值(defer ADR 但行为方向须可测)。本轮修订可能新增 1 mini-ADR（分离时序+事件传递机制打包，因 BL1+BL2 交叉）。

**当前进度**：用户选择本会话立即修订。9 项 BL 中需用户裁定的设计决策待批量确认（BL1 时序/BL5 behavior3/BL8 BLINK落点）；其余方向已定可直写。registry 3 gated 值(max_enemy_bound/enemy_overshoot_max/separation_radius)声回填但无独立 entry（advisory，回填时补）。

**修订完成（2026-08-25，9 项 BL 全部写入 enemy-system.md）**：
- BL1 separation 时序：下帧 MOVEMENT_COMMIT 生效 + 纳入 staged（§4.1/§4.2，OQ4 ✅RESOLVED）
- BL2 emit_signal 带参热路径：死亡/受击改 GameRoot staging bank + take_damage 直接方法调用（§3.4 零分配契约扩展 + §6.2 下游表）
- BL3 分离算法 4 缺陷：零向量确定性单位向量 + query 语义统一 + 累加 clamp + pair-once 去重；AC-E10 降 bounded 收敛 N≤3 帧≤ε（§4.2/AC-E10a/b）
- BL4 AC 不可测+术语+编号+缺 AC：8 条不可测 AC 重写、FREE→AVAILABLE（AC-E5/E6）、AC-E9 编号消歧、AC-E14/E22/E23 拆分、AC-E15/16/17 移除（LOD）、补 AC-E28~E36（11 条）、§8 加 story-type/gate 标注 + positive control 引用 object-pooling AC-F3（§8 全节重写）
- BL5 behavior 3：甲壳妖虫改贴身毒 aura（§7.4，OQ7 待 performance 核验）
- BL6 死亡 VFX：独立 VFX 池节点播放 + 载体立即回池，§9.2 移除 defer
- BL7 精英 FSM：状态机表 {trigger/action/next} + spike 锚点（§3.6/§7.3）+ AC-E30a/b/c
- BL8 BLINK 落点/召唤 cap-full/borrow：玩家点+seed 偏移 clamp arena（§3.6.2/AC-E30c/E31）+ cap-full 逸散 VFX 不重试（§5.7/AC-E29）+ intent latch 下一 tick（§6.2/OQ5）
- BL9 LOD 移除：删 §3.9/§4.4/§7.3/AC-E15-17，消解 stage-map R1 死代码（§3.9 REMOVED/§7 重编号/§9.1 统一 60fps/§9.3 无 sim-LOD）
- §7.2 加 health/damage cap（违 §2"更乱更密 not 更肉更慢"，AC-E33）；§10 OQ1 加 303 Node2D 性能子问题；status 行 DRAFT→IN REVISION
- 待 re-review：推荐 /clear 后新会话 /design-review enemy-system（本会话 context 已用约 70%+）
<!-- CONSISTENCY-CHECK: 2026-08-24 | GDDs checked: 5 (config-data-system, object-pooling, spatial-grid, stage-map, game-root-scene-flow) | Conflicts found: 0 | 2 STALE REGISTRY resolved (pool_capacity_enemy_elite 4→6, required_pool_capacity notes 320/4/1→320/6/1) | Verdict: PASS after registry update -->
<!-- REVIEW-ALL-GDDS: 2026-08-24 | mode=design-theory (Phase 2 skipped, consistency-check just PASS) | 5 GDDs | Verdict: CONCERNS → 1 Blocking CLOSED | BLOCKING: config EC7/L59/AC-B4 与 object-pooling R1 对 PRESENTATION overflow 行为矛盾（config 说 failure→ControlledFault，object-pooling 说 OVERFLOW_DROPPED）→ 已对齐 config 到 object-pooling R1（pool owner 权威），3 处文案改走 OVERFLOW_DROPPED，不改公开契约 | DEFERRED: enemy_elite F1 max_concurrent=2 语义纯化（reviewer 建议 max_concurrent=4/safety_spare=1）——核查发现会破坏 max_concurrent 三 key 总和(300+2+1=303)与 Grid ENEMY cap 303 对齐→制造反向 Pool/Grid 准入不一致，当前藏入 safety_spare 是有意对齐，故 DEFER 不盲改；4 Warning（灵石无 sink / 替身符 mass-clear CPU 未预算 / 夺宝精英时序歧义 / damage_number=96 AoE 容量）多 DEFERRED 到下游 GDD | Phase 3 设计理论高度一致：Player Fantasy 统一"无感基础设施"、pillar 对齐、无 scope creep、核心循环清晰 -->
<!-- CONSISTENCY-CHECK: 2026-08-24 | GDDs checked: 6 (config-data-system, game-root-scene-flow, object-pooling, rng-system[NEW], spatial-grid, stage-map) | Conflicts found: 0 | Stale registry: 0 | Forward flags: run_seed 未注册（Config 未声明字段，RNG AC-G2 gate BLOCKED）、stream_id 集未注册（API 契约非数值） | Verdict: PASS -->

## 历史快照：InputSystem 初稿阶段

**InputSystem (#2 Core, Foundation 层) GDD Designed。** lean /design-system 完成 8 节写入 `design/gdd/input-system.md`（2026-08-25）。核心设计：单摇杆 → 二元归一化移动向量（F1：`out=(mag<deadzone)?ZERO:raw/mag`，幅值 ∈ {0,1}，MVP 不启 analog 量程）；GameRoot 7-phase 参与者（slot 归属 OQ）；BATTLE_ACTIVE 驱动 / BATTLE_PAUSED 冻结 / APP_BACKGROUND 锁定（无挂钟补偿）；attack 自动释放（无攻击输入）；零分配稳态管线（AC-IS25 引 `tools/ci/static_guard_check.py` AST 守卫，与 EnemySystem AC-E4-code 同型）。4 态 IDLE/ACTIVE/FROZEN/BACKGROUND_LOCKED。27 条 AC（AC-IS1..IS27）覆盖 Core Rules 11 + F1 4 + States 四态 + 跨系统 5 + 静态守卫 3。lean 模式跳过 systems-designer（D/E/F/G 节，公式为数学恒等无平衡数值可"发明"；full 复审终审 spike-skip carrier 持留语义 + pause-resume touch 续接）；H 节 qa-lead 单 pass 起草。📌 UX Flag（摇杆 UI + 选择 UI 交互归 ux-designer full 复审）。10 项 Open Question（VirtualJoystick 4.7.1 API 验证 + 内置 vs 自定义 ADR / joystick_mode ADR / input config schema 未冻结 / carrier 归属 / 7-phase slot / deadzone 实测 / 摇杆视觉 UX / analog 预留 / static_guard_check.py 未建）。无新注册表条目（InputSystem 无跨边界数值事实）。systems-index：InputSystem Not Started→Designed，started 7→8、MVP designed 7→8/27。

**下一步**：InputSystem 设计完成，待 /design-review（建议新会话，full 模式：sys-designer 终审 D/E/F/G 节 + qa-lead 复核 AC 覆盖 + ux-designer 终审 📌 UX Flag）。或继续下一个 MVP 系统设计（按 Recommended Design Order #8 PlayerController，但其依赖 InputSystem 已就绪；或 DamageSystem / SpawnDirector 等 Core 层）。

---

### 历史：EnemySystem (#9) R4 复审 Approved（2026-08-25）。5 根因 + G 全闭环，零新公式/零新 ADR/零设计意图变更。修订写入 enemy-system.md（24 处）+ technical-preferences.md L59 + spatial-grid.md（5 处 query_radius + G3 澄清注）。R4 验证 grep 另补修 3 处残留（AC-E19 引用 + spatial-grid L252/L273）。systems-index：EnemySystem In Review→Approved，approved 4→5。详见 review-log。PR #124（fork→Donchitos）待 review/merge。

### 历史：SpatialGrid 第四轮 full 复审 **APPROVED**。8 项 BLOCKING 全部 CLOSED，creative-director 终审通过。标 Approved 前一并修订的 4 项措辞/追溯小改已写入：R-A（F5 L379 "6-18ms 保守"→"乐观下界"+双层低估说明）、R-B（新增 EC29 映射 AC-E11，EC 计数 28→29/29）、R-C（核对表 R4 行补 AC-B0/B4b、R6 行补 AC-E11）、R-D（依赖表 SpawnDirector publish 时序措辞防 ghost）。文档 status 行、systems-index（NEEDS REVISION→Approved，reviewed/approved 1→2）、review-log（追加 APPROVED 条目）均已同步。defer 项（R9 precedence 独立 AC / godot 契约显式化 / AC-J3b Σ gate）归实现期或下一轮 lean follow-up。J0/J1/J2/J4 真机性能 gate 仍 OPEN（无 min-spec 真机），仅 deferred evidence，不影响设计冻结。

## 本会话完成的工作

### 引擎设置（/setup-engine）
- 引擎确定：Godot 4.7.1（从仓库脚手架 4.6 升级）
- 语言：GDScript
- CLAUDE.md 技术栈已更新
- `.claude/docs/technical-preferences.md` 全量填充（移动端竖屏 Touch 输入、GDScript 命名规范、GDUnit4、godot 专家路由）
- `docs/engine-reference/godot/` 全部参考文档更新到 4.7.1（VERSION/breaking-changes/deprecated-apis/current-best-practices + 8 个 modules）
- 4.7 关键发现：内置 VirtualJoystick 节点（摇杆移动可直接用）、`AnimationNodeBlendSpace.sync`→`sync_mode`、`area_mask` 默认值变更、device ID 不再是 0

### 系统分解（/map-systems）
- 系统索引已写入：`design/gdd/systems-index.md`
- 31 个系统，分 5 依赖层 + 4 优先级（MVP 26 / Vertical Slice 3 / Alpha 1）
- Review mode = lean（三个 director gate 均跳过）
- 设计顺序前 5：SpatialGrid → Object Pooling → Config/Data → RNG → GameRoot
- 高风险系统：SpatialGrid、Object Pooling、Config/Data、DamageSystem、BossStateMachine、EnemySystem、SkillDraftSystem

### 首个 GDD（/design-system spatial-grid）
- `design/gdd/spatial-grid.md` 全 8 节完成（A–H + Open Questions）
- 委托 systems-designer 起草 D 节公式（F1–F5），qa-lead 起草 H 节验收标准（11 组 ~35 条）
- 初稿核心决策（已被 2026-08-18 full review 部分替代）：仅保留 uniform-grid 方向与位掩码；旧的 CELL_SIZE 直接绑定、nearest 容器顺序 tie-break、查询半径不变式均不再有效，以下新修订为准
- 头号阻塞：SkillConfig AoE 半径未定义 → CELL_SIZE 终值待定（OQ1）
- 实体注册表新增 `max_query_radius`（formula）；`pickup_radius=1.8` 待 PlayerController GDD 注册后回填 referenced_by

### SpatialGrid full re-review 修订（2026-08-18）
- full review consulted：game-designer、systems-designer、qa-lead、performance-analyst、godot-specialist，creative-director 终审
- 终审：MAJOR REVISION NEEDED；原 2026-08-14 修订仅部分闭环，且无 review log
- 查询正确性：所有 finite/non-negative radius 合法；release 保留请求半径正确扫描，禁止 clamp
- nearest：全局最小距离；等距取 stable registration_sequence，禁止“螺旋遇首即返”
- 坐标：F1 改 arena-min 对齐，正式定义 cols/rows，支持 arena 非 CELL_SIZE 整除
- 生命周期：SpatialHandle/RegistrationEntry、即时 remove、generation、pool release 顺序
- 时序：movement commit → grid sync → query/collision → damage/deferred remove
- 暂停：Paused snapshot + FIFO mutation queue；支持 Paused→TornDown
- 性能：9 格只代表 lookup；F4 改总索引条目，F5 改 O(N+M)/dirty notification 前提；J0 锁定 benchmark manifest
- 当前用户暂无 min-spec Android 真机：真实性能 release gate OPEN

### SpatialGrid second full re-review 修订（2026-08-18）
- 公共 API：circle/nearest/insert 改为 primitive status + caller-owned preallocated carrier；公开 handle 为永不复用的 int ID
- 数值与公式：F3 强制合法 fallback；聚合真实 broadphase radius；radius=0 分量相等、正半径 normalized compare；walkable area>0；index_margin 不得突破世界域
- 生命周期：mutation lookup 与 active resolve 分层；Paused 在完整 tick barrier 冻结，resume 采用 prepare→complete remap→commit/abort
- 查询语义：Projectile broadphase 覆盖完整 swept segment；pickup 固定 Drop center；nearest 固定 center distance
- 错误路径：公开 API status/postcondition 矩阵；任意查询 failure 中止消费并进入 ControlledGameplayFault
- 验收：AC 增至 66 条；J3 allocation positive control、J5 operation 上限、J6 逐调用 oracle 已冻结
- 跨文档：systems-index runtime prerequisites、registry pickup constants/effective max radius、主方案 buffer 表述已同步

## 关键决策

- **概念文档来源**：用 `design/凡人修仙掌天试炼-MVP设计方案.md` 而非标准 `design/gdd/game-concept.md`（方案比标准概念文档更详尽，含数值框架+模块清单+验收标准）
- **SaveSystem 归 Feature 层**：按"要存什么的数据契约"分层（依赖 Progression/Zhangtian 先定义），而非按存档框架归 Foundation
- **VFX 放 Vertical Slice、Analytics 放 Alpha**：音效对爽感更即时放 MVP，特效系统化较重放 VS，埋点后置
- **SpatialGrid CELL_SIZE 临时 2.0**：仅作 spike 锚点；最终从 benchmark sweep 选定，不再直接等于 max_query_radius
- **正确性优先**：radius>CELL_SIZE 不是错误；debug/release 均按原半径返回正确集合，配置审计只告警不改语义
- **Foundation 层 fail-fast 策略**：非法初始化/状态/非有限输入 debug assert；release 返回失败/空并限频上报，不用 magic fallback
- **pickup_radius source**：当前权威来源为 MVP 主方案，registry 已登记 base=1.8/max=1.98；PlayerController GDD 完成后追加 referenced_by
- **GDD 描述行为、ADR 描述实现**：数据布局、结果 buffer、更新策略、nearest 正确算法实现与语言路径由 ADR/spike 选择

## 文件清单

| 文件 | 用途 |
|------|------|
| `CLAUDE.md` | 技术栈 Godot 4.7.1 / GDScript |
| `.claude/docs/technical-preferences.md` | 全量项目偏好 |
| `docs/engine-reference/godot/VERSION.md` | 引擎钉版 + 迁移说明 |
| `docs/engine-reference/godot/breaking-changes.md` | 4.4→4.7 破坏性变更 |
| `docs/engine-reference/godot/deprecated-apis.md` | 弃用/移除 API |
| `docs/engine-reference/godot/current-best-practices.md` | 4.7 新实践 |
| `docs/engine-reference/godot/modules/*.md` | 8 个子系统参考 |
| `design/gdd/systems-index.md` | 31 系统索引（SpatialGrid→In Revision；runtime prerequisites 已注明） |
| `design/gdd/spatial-grid.md` | SpatialGrid GDD 全 8 节 |
| `design/registry/entities.yaml` | 实体注册表（max_query_radius 已注册） |
| `design/凡人修仙掌天试炼-MVP设计方案.md` | 概念来源（只读） |

## 待解问题

- min-spec Android 真机暂无 → J0 benchmark readiness OPEN
- arena、成长后 pickup/target range、SkillConfig AoE、separation、projectile broadphase 未定义 → 阻塞生产 CELL_SIZE ADR，不阻塞正确查询语义
- GameRoot/Stage/Object Pooling/Config 及所有 consumer GDD 尚未创建，当前仍非 integration-ready

## 下一步

建议顺序：
1. ✅ 已完成：75秒灰盒Demo自动闭环与用户实际试玩，Verdict=`PROCEED`。
2. ← 当前：将原型结果记录为报告并冻结为参考基线；不得把`prototypes/`代码直接迁入生产`src/`。
3. 下一步建议：先做一轮低成本表现优化（命中闪白、击杀消散、轻量震动、基础音效），保持玩法系统不扩张；之后再决定是否按正式架构从零实现生产切片。
