# F增量独立 Godot primary/UI 复核

结论：APPROVED（仅F增量Godot/UI范围；原P3已关闭，无遗留阻塞或建议项）。本轮重新核对F，不继承E批准。项目文件零编辑；独立输出仅/tmp。

## 身份与范围

- 已读ADR-0009 F扩展、before.json、source-freeze.json，逐文件SHA256复核63项，mismatches=[]。
- 当前目录hash：31f5f97f71efde814a73ae6d9d91e6b8205b5b6dbd15e4dfd48bfbad1e65d569。
- 相对before实际变化：Arena、Chapter、Encounter、Profile、build_catalog及生成JSON。Root/UI/Render/场景/Combat hash与before相同，未引入新节点或新的生命周期owner。

## 正式相机测试与独立运行

读取tests/manual/campaign_camera_lifecycle_test.gd全文：12–14只等process_frame和frame_post_draw；34–38通过root.size真实触发窗口变化，并比较完整snapshot（含RNG）。没有_update_camera_view、force_update_scroll或手工camera.position/zoom写入。39–49走Root resume/save_and_home/continue_run公开路径。故修复了原E图形夹具人为刷新相机的证明缺口。

本评审独立运行当前冻结测试，真实Mac图形（Godot4.7.1，Apple M4 Compatibility）；命令：
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios --script res://tests/manual/campaign_camera_lifecycle_test.gd -- --campaign-validation --evidence-root=/tmp/f-ui-review-20260916

退出码0，failures=0。日志/tmp/f-ui-camera.log；证据/tmp/f-ui-review-20260916/31f5f97f71ef/camera-lifecycle/1789543339-28920-409144/camera-lifecycle.json。
开始tick2；四次暂停resize始终tick2且snapshot相等；恢复tick4；save/home/超宽继续tick7。可见范围1280×720、1280×480、576×720；最大中心误差0.00013648。测试由--campaign-validation使用内存持久化，不冒称磁盘/进程重启测试；save/home确实销毁旧Arena并重建新Arena，Root保持。

## 首次发现及复核关闭

P3：tests/manual/campaign_camera_lifecycle_test.gd:39–42目前仅调用resume并inspect几何，未显式断言paused==false或tick增长；相同问题见47–49继续后。假如将来resume成为no-op而几何保持正常，测试可能仍通过。本次真实日志明确paused=false与tick增长，故是未来回归敏感度建议，不是现存恢复失败。建议增加恢复前后tick/paused断言；暂停处也直接断言paused，避免仅依靠快照不变间接证明。

## 经验球呈现、briefing与架构

- campaign_arena.gd:604–611 drop_xp使用现有state.pickups，满容量把完整amount合入已有球并刷新ttl；没有直接写player.xp。617–620依现有吸引/接近逻辑才入账。
- campaign_arena_render.gd:32–35直接遍历同一pickups画绿色圆晕与亮色菱形；F未替换视觉实现。04线索Chapter:15–18在新线索位置生成，08 Chapter:75–79在Boss位置按跨越阶段生成；单调boss_phase与clues保留在既有快照，显示层不持有奖励状态。
- build_catalog.py:181–188只对01–05/07–08赋320/600；04中文明确“每条线索8点，靠近绿色光点吸引拾取”，英文Each clue releases 8 XP; approach green motes…；08中英均明确每次阶段突破18点。措辞与可见掉落一致，不承诺即时到账或额外强制战斗时间。
- UI章节卡campaign_ui.gd:325使用localized(mission,"briefing")及自动换行按钮；F无新增显示路径。已查看当前F 800×1000英文HUD作者截图，未见积压文字遮住中心；这不是04/08新文案完整人工交互走查。
- 逻辑仍在Arena/Chapter，Root仅相机/调度、UI只读呈现；没有跨层新增权威写或Node生命周期改变。drop_xp有API注释与有限容量，参数从目录读取。没有性能实测，不能称零分配或帧预算通过。

## 限定

上述P3已完成整改和独立复跑，不再列为未完成建议。
经验球真实拾取/恢复奖励防重的完整负向矩阵由对应GDScript/QA专家裁决，本报告不替代其结果。新玩家试玩SKIPPED_BY_USER；F不是发布验收，不推出Windows/Steam、商业SaveV2、20小时、完整IO或性能验收；battle_ready=false。

## 最终增量复核（同日）

对比source-freeze-before-ui-assertions.json与source-freeze.json，唯一hash变化是tests/manual/campaign_camera_lifecycle_test.gd；重新验证全部63项，mismatches=[]。运行源码和目录hash保持。

当前测试33/49行明确断言暂停；41–46行记录恢复前tick、等待两个physics_frame并断言非暂停且tick增长；50–58行记录保存tick并对continue作相同断言。没有引入手工相机刷新。这直接关闭原P3。

独立真实Mac图形重跑最终脚本，命令与前次相同但evidence-root=/tmp/f-ui-review-20260916-final；退出码0，failures=0。日志/tmp/f-ui-camera-final.log；最终证据/tmp/f-ui-review-20260916-final/31f5f97f71ef/camera-lifecycle/1789543484-29221-492142/camera-lifecycle.json。暂停四次resize保持tick2且完整snapshot相等；resume tick5、continued tick9均paused=false；最大中心误差0.00013648，可见范围未超界。此最终证据替代首次相机复跑作为当前脚本的批准依据。

最终限定verdict：APPROVED，仅本专家F增量Godot/UI范围。保留上文平台、内存存储夹具和发布验收边界，battle_ready=false。
