# G最终包 Godot primary/UI 独立复核

Verdict：APPROVED，仅当前冻结G增量的Godot生命周期、相机、briefing呈现及Boss预警呈现范围。无P0–P3新增发现，无必须修复项。不是沿用F结论。

## 绑定与静态范围

当前source-freeze.json共68项逐文件SHA256验证，mismatches=[]；目录hash b4b4a50190f3bf99b182956bc79d0d98c31a3777077de800bd7f483c0a6c5cbc。读取ADR-0009 G实施顺序及最终确认、G baseline-f构建器差异、F staging Chapter差异。Root/UI/Render与F staging逐字节相同；没有场景/Node生命周期新增路径，仍由Root驱动模拟/暂停/相机，UI不持有调度状态。

build_catalog.py:265–300 G1/G2沿用ANCHOR_PROGRESS、WAYPOINT、CLEANSE_HALF；新briefing描述提前侧面接近、护送三路段、净化两组有限交错，与数据变化一致。未新增强制等待或空间触发文案。

## 独立真实Mac图形验证

重新运行当前冻结tests/manual/campaign_camera_lifecycle_test.gd，--campaign-validation且--evidence-root=/tmp/g-ui-evidence，退出0。日志/tmp/g-ui-camera.log；证据/tmp/g-ui-evidence/b4b4a50190f3/camera-lifecycle/1789548996-36235-357285/camera-lifecycle.json。

failures=0：开始tick2；暂停四窗口resize保持tick2与完整snapshot/RNG不变；恢复tick5，save/home/超宽继续tick9均paused=false。范围1280×720、1280×480、576×720，中心误差最大0.00013648。测试settle只有等待，不手工camera更新。使用内存存储验证Root/Arena生命周期，不称磁盘或进程重启证据。

另编写/tmp/g-ui-probe.gd并图形执行（--campaign-validation），退出0，G_UI_PROBE_PASS；日志/tmp/g-ui-probe.log。960×540物理窗口、130%字号，02/03/05/07中英章节卡实际自动换行；通过焦点滚动使卡片完整进入视口。为聚焦锁定卡片，探针仅临时取消按钮disabled，没有激活、修改profile解锁进度或持久化用户档。截图8张/tmp/g-ui-{zh-CN,en}-{02,03,05,07}.png；实际查看英文02/03/05/07、中文03/05/07（中文02在03截图同屏完整可见）。目标卡片说明无截字、横向溢出或正文覆盖，页面边缘非目标卡片被ScrollContainer裁切是正常滚动行为。

Boss夹具复用正常Root/Arena/HUD，在暂停模拟的当前目录Boss阶段制造入口状态，调用实际Chapter.boss；图形截图/tmp/g-ui-boss-warning.png。两枚橙色带八向刻线预警完整可见，位于中央玩家区域，HUD/阶段提示未遮挡。输出真实zone delay=0.9/1.4、pending tick=54/84，未直接绘制假警告。这是定向呈现夹具，不是自然战斗体验或完整动画播放验证。

## Boss预警与屏外生成

campaign_chapter_one.gd:78仅阶段上升清旧timer；81–87先执行/清理原到期landing并在未排空时停止新发布；89–90按1/2/4个zone检查容量，容量不足不写新攻击计数；94–102使用同一位置与54/84tick delay创建zone及landing，保留最多2个pending。campaign_arena_render.gd:145–172由delay决定警告环/刻线；没有新增不经现有渲染的数据路径。

独立重新执行campaign_boss_entry_test.gd：/tmp/g-ui-boss-boundary.log，退出0，112 checks/0 failures，覆盖阶段进入完整延迟、旧pending保留/排空后发布、100tick恢复对照、满zone不发布隐形攻击/容量恢复后重试、致死立即清理。

独立重新执行campaign_package_e_test.gd（当前G目录）：/tmp/g-ui-spawn.log，退出0，465 checks/0 failures、438接受候选。结合当前G相机图形范围验证，未发现早投放绕过原屏外排除。并不把有限候选测试称所有随机状态穷尽证明。

## 正向观察与边界

G复用现有持久状态和呈现记录；预警zone与物理landing在同一入口生成，先容量检查后记攻击，避免有攻击无预警的新增路径。Root/UI无增量，实际当前G图形仍完成暂停/窗口/继续链。文案准确指出新遭遇方向和有限增援，没有将升级数承诺成硬门槛。

无新增建议。新玩家试玩SKIPPED_BY_USER；不推导Windows/Steam、SaveV2、20小时、完整性能或发布验收；battle_ready=false。项目文件未编辑，运行输出/探针/截图仅/tmp。其他专家对调度语义/恢复完整性的裁决仍须独立合并。
