# 第三章（涨潮）Godot 引擎用法与玩家可读性独立评审

限定 verdict：**CHANGES REQUIRED**。范围仅 ADR-0011 第三章增量的引擎用法、渲染与玩家可读性（briefing/teaching/几何/颜色语义）；不含数值平衡、存档恢复、完整性能与 20 小时验证。本评审不改正式项目：探针在隔离副本（/tmp/ch3-ui-probe-project，独立用户目录 "Ch3 UI Probe 20260917"）运行，证据只在 /tmp 生成；正式 Root/UI 与用户存档零接触。新玩家试玩 SKIPPED_BY_USER，battle_ready=false。

## 证据与方法

- 目录可复现：`python3 tools/campaign/build_catalog.py --check` → CATALOG_REPRODUCIBLE 364 rows / 64 missions；missions[16:24] briefing 与生成器逐字一致。
- 真实渲染探针 `/tmp/ch3-ui-review-probe.gd`，日志 `/tmp/ch3-ui-review-probe.log`（Godot 4.7.1、Apple M4 Compatibility、`--campaign-validation`、退出 0、SCRIPT ERROR=0）。定向呈现夹具：直接注入 zone/拆印状态并摆相机，不推进模拟、不宣称自然解锁。20 张截图 `/tmp/ch3-ui-*.png`。
- 截图为程序化像素断言（本评审环境无法直接目视 PNG）：警告环实测 RGB(211,128,121)，与理论混合值 `0.7*(255,113,87)+0.3*(95,168,211)=(207,129,123)` 吻合，即红 #ff7157 画在蓝底圈上的合成色。
- briefing 卡片 130% 字号中英各 3 张（M18/M20/M24），`min=(36,86..152)`、`size=(1176,…)`，均无截断或横向溢出；8 关 teaching 文本双语经 API 直读并与源码一致。
- 其余结论来自源码静态推导（tick 数学、圆几何、zone ABI），关键算式在对应 finding 中给出。

## Findings

### P0

**P0-1 潮墙齿 zone 单向延伸只覆盖半个战场，boss 核心机制可被整体绕过**（主线程已确认，将改为锚 `(x,-arm_length/2)` 全高对称）
- `src/campaign/campaign_chapter_three.gd:38-41`：齿 zone 生成于 `Vector2(direction*(spacing*(i+1)-40), 0.0)`，随后 `z.angle=PI/2.0; z.length=1250`。`from_angle(PI/2)=(0,1)`，伤害线段（`campaign_combat.gd:307-308` `_zone_contains` line 分支）与绘制线段（`campaign_arena_render.gd:160-162`）一致地从 `(x,0)` 延伸到 `(x,1250)`——只覆盖世界 y≥0 半场（战场 y∈[-320,320]）。
- 像素证据：`m24-wall-active-p1.png` 中墙列 x=815、水线（世界 y=0，屏幕 y=210）以上红像素 6（噪声）、以下 3060。
- 玩法后果：boss 位于 [500,-80]（y<0 半场），玩家全程在 y<0 半场作战即可令潮墙机制完全失效，briefing/teaching 的"从齿列之间的缺口穿越"（`campaign_chapter_three.gd:91`）在该半场无对应现实。修复后 1.3s 预警对 215px 齿距窗口是可躲的（280px/s 移动 1.3s ≈ 364px > 齿中心到最近窗口中心 ~142px）。
- 附带：length=1250 使墙线穿过地面矩形底边（y=320）继续画到 y=1250，视觉溢出场外（同 P1-2 的场外绘制模式）。

### P1

**P1-1 "蓝色圈先预警"全线文案与实际渲染不符：预警/涨水呈现均为红色，蓝色仅是恒定位置底圈且被红环覆盖**
- 数据层：`src/campaign/campaign_arena.gd:652` `emit_layout_root` 传入 `"#72cbe8"`，但第 8 参 `hostile=true`；`src/campaign/campaign_arena_render.gd:151` `_zone` 对 hostile zone 一律 `Color("ff7157")`。探针实拍 zone：`color=#72cbe8 hostile=true delay=1.5 ttl=2.5`——蓝色参数从不参与渲染。
- 呈现层：蓝 `#5fa8d3` 只出现在 `_layout` 底圈（`campaign_arena_render.gd:263`，2px 恒定，不随潮池周期变化、不承载任何时序信息）；预警出现时红环（0.7 alpha）与蓝底圈同半径 r=80 叠画，实测 (211,128,121)。
- 文案层四处宣称蓝色=预警：`assets/config/campaign_game.json` M17 briefing"随蓝色预警更换安全滩"/"on the blue warnings"（build_catalog.py:349）、两场景描述"蓝色圈先预警，再涨水"/"Blue rings warn before the surge"（build_catalog.py:342）、teaching 默认分支"蓝色圆圈先预警，再涨水"/"Blue rings warn before the tide surges."（campaign_chapter_three.gd:99）。
- 后果：新玩家第一次遇到潮池会按文案盯蓝圈等它"预警"，但蓝圈永远不变；真正的时序信号（红环出现/变粗）未被任何文本命名。注意此为跨章既有模式（ch2 "Orange rings warn"，同被红覆盖，ch2 冻结评审未核对颜色语义），ch3 把颜色词首次写进 briefing，错位扩大。修复任选其一：让潮池 zone 走非 hostile 呈现色（但伤害语义需另行区分），或把文案统一改为不依赖颜色的表述（"圆圈先预警"）并让预警/active 视觉差足够强（见 P2-4）。

**P1-2 harbor 潮池 roots[0] 中心在战场边界之外，"三片潮池"名不副实且警告环画出场外**
- `tools/campaign/build_catalog.py:335`：roots[0] `[-380,340]`，而 `arena_half_size=[960,640]`（y∈[-320,320]）。`campaign_encounter.gd` 的 `point()` 校验只允许 |y|≤580，未与半场约束对齐，故合法通过。
- 玩家可达区（y≤304，含 16px 半径）只覆盖该池顶部 44px 帽区；池中心在界外 20px。像素证据：`m17-pool-oob.png` 在地面底边（世界 y=320，屏幕 y=530）以下 100px 处（屏幕 640,630）仍采到红环 (211,128,121)——预警环大半悬在地面矩形外的纯背景上。
- 玩法后果：M17 briefing"三片潮池错峰翻涌，随蓝色预警更换安全滩"（build_catalog.py:349）中该池对走位几乎不构成威胁，三池轮转承诺的"安全滩更换"实际只剩两池；视觉上场外弧段无地面参照，读不出"这是一片潮池"。court 布局（±220）无此问题。

**P1-3 拆闸印后同一潮池可出现双存活 zone（主线程已确认，将加"同 flat 存活区跳过"守卫）**
- `campaign_encounter.gd:150-152`：拆印瞬间 `cycle` 由 450 切到 240，emit 条件 `(tick-offset-1)%cycle==0` 的相位与旧 450 周期不对齐。因 240j-450k 可取 30（j=2,k=1），存在 30-tick 窗口：旧周期 zone（存活 delay 90+ttl 150=240 tick）尚未到期，新周期已 emit 第二个同参数 zone。例：root offset=0，旧 emit@451（存活到 691），拆印于 tick 452-480 之间，则新 emit@481 与旧 zone 在 481-691 共存。
- 两个 zone 参数都与 `layout.roots[index]` 匹配，`campaign_chapter_three.gd:66-73` `valid_state` 不拒绝；渲染为同位置双红圈叠画（一个 active 一个 warning），tick 语义（哪个属于当前周期）在恢复与视觉上均不可分。守卫方向正确：emit 前检查该 flat 是否已有存活 zone。

### P2

**P2-4 潮池 warning→active 视觉差异过弱，1.5s 预警期内难以读出状态切换**
- `campaign_arena_render.gd:153,168-173`：预警态=0.08 填充+2px 环+8 根放射短线；active 态=0.17 填充+3px 环。像素分类下 warning 与 active 的红调采样分别为 230/224，无实质差；0.08/0.17 填充落在暗地面上的合成色（(32,39,43) vs (57,43,46)）低于人眼可靠区分阈值。
- 好的一面：放射线是形态（非颜色）差异，对色觉障碍友好；建议反向加强——active 态用显著形态变化（填充跳变/环色变亮/内圈花纹，参照 `roots/thorns/spores` 分支 `campaign_arena_render.gd:174-177` 的做法），让"正在伤害"与"即将伤害"一眼可分。

**P2-5 teaching ESCORT 条中英行为指引不一致**
- `campaign_chapter_three.gd:95`：中文"靠近渡船才能前进；潮池涨水时先离队等待"给出明确动作（离队）；英文 "Stay near %s; hold it back while a flat surges."——"hold it back" 语义歧义（可读作"挡住渡船/阻挡敌人"），未传达"离队等待"。几何上该指引有真实实践点：渡船航路第三段与池 [480,-40] 伤害圈相交（最近点 (486.6,24.1) 距池心 64.4 < 80+24 判定半径），玩家须在渡船入池前离队（>180px）停船等退潮，英文玩家得不到这个指令。另实拍英文为 "Stay near Ferry"（escort_label_en='Ferry' 直接代入），缺冠词。
- 建议：英文改为 "Stay near the ferry to move; step away and let it wait out a surge."

**P2-6 齿墙预警线 2px 抗锯齿在 4.7 画线变更下更细，全场级威胁的预警可见性偏弱**
- `campaign_arena_render.gd:162`：line zone 预警态 `draw_line(..., 2 if warning else 5, true)`。Godot 4.7 移除了 CanvasItem 画线抗锯齿羽化（docs/engine-reference/godot/breaking-changes.md Rendering 行，GH-105122），2px 抗锯齿线比 4.3 时代更细。对一条覆盖半场（修复后全场）的致死墙，1.3s 预警期的主要信号是一根 2px 细线；对照 ch1 `boss_chapter` 落点用 65-105px 半径圆预警（campaign_chapter_one.gd:97），形态强度差距明显。建议预警态加粗或附虚线/齿根标记。

### P3

**P3-7 teaching 默认条英文缺行动指引**：`campaign_chapter_three.gd:99` 中文"蓝色圆圈先预警，再涨水；提前离开潮池"有动作（提前离开），英文 "Blue rings warn before the tide surges." 止于描述。补 "leave before it floods."

**P3-8 M22（穿越潜鳍群）教学与该关主要威胁不匹配**：M22 为 SURVIVE，走默认潮池分支；其 briefing（build_catalog.py:354）与敌人组合（S1-N08 jet+S1-N09 burrow，地面跃出与直线喷流）才是主威胁。沿用 ch2 M9 的默认分支模式（一致），但该关潮池只是背景之一，教学引导与实际压力源错位。

**P3-9 M19 briefing"退潮窗口内完成停留"是次优描述**：南圈 [440,60] r90 与池 [480,-40] r80 圆心距 107.7，相叠成月牙；池 y≤40 而净化圈南弧 y∈(40,150] 常驻池外，玩家全程站月牙（`campaign_mission.gd:86-92` hold 判定只要求在圈内+附近无敌）即可完成 7.8s，无需等退潮。文案保守不误导，可保留。

**P3-10 渡船护送物绘制沿用 ch1 采药人人形+篙造型，与"渡船/开船/sail on"文案语义错位**：`campaign_arena_render.gd:129-134` scene_layout_id 分支画人形（无船体/波浪元素）。ch1 采药人、ch2 炉工为人形一致成立；ch3 文案是船（Ferry/渡船/harbor waypoints），视觉是徒步人。建议加船底弧线或波浪标记。

**P3-11 M20 briefing 未提示拆印时机**：三闸印 target 位于 court 潮池正中心（target_positions=roots centers，build_catalog.py:353），站池拆印会被淹没（active 2.5s 内 ~5 次×4 伤害）。伤害可承受、退潮窗 3.5s 足够拆 147HP 锚，属可发现的节奏而非坑；文案加半句"趁退潮拆印"更友好。

**P3-12 底圈/淹没内圈 2px/3px 抗锯齿线在 4.7 下更细**：`campaign_arena_render.gd:263-265`。底圈（ch2 已审模式沿用）与新增内圈均为细线；作为位置标记影响小，但若 P1-1 修复选择"让底圈承载状态"则需同步加粗。

## 复核重点结论

1. **玩家可读性时序**：潮池 90tick(1.5s) 预警→150tick(2.5s) 涨水→210tick(3.5s) 休潮、周期 450tick、三池 offset 0/150/300 完美轮转（active 窗 91-240/241-390/391-540 互斥，任一时刻至多一池翻涌、恒有至少两个安全滩），"更换安全滩"几何成立；1.5s 预警（280px/s×1.5≈420px）逃离 80px 半径池充分。齿墙 1.3s 预警在修复 P0-1 后可躲（见 P0-1 算式）。三色章节区分（绿/橙/蓝）对红绿色盲的绿-橙难分仅存在于跨章不同场切换，非玩法依赖；章内功能色对 蓝(底圈)/红(hostile)/金(撤离) 在各色觉类型下可分，敌对 zone 统一红使危险识别不依赖色相——真正的错位是"蓝色=预警"文案语义（P1-1），色觉健全玩家同样受影响。弱项集中在 warn→active 视觉差（P2-4）。
2. **引擎 API 正确性**：draw_arc/draw_line/Color 字符串构造（含 # 前缀与 6 位 hex）均正确且与 ch1/ch2 调用模式一致；`emit_layout_root` hostile=true 是伤害语义（advance_zones 对玩家/渡船结算）的正确用法，非 API 错误——问题在渲染分支使 color 参数失效（P1-1）。4.7.1 注意点：画线抗锯齿羽化移除影响所有细线（P2-6/P3-12）；本路径未触及 4.7 其余破坏性变更（Animation.length/SyncMode/area_mask/device ID 等）。
3. **布局几何**：渡船航路三段分别贴近三池（最近距 120/120/64px），第三段与池 [480,-40] 伤害圈相交——"涨水时先离队等待"有真实实践点（见 P2-5）；净化南圈月牙常驻安全成立（见 P3-9）。硬伤为 harbor 池0 出界（P1-2）。court 三池（±220）全部在场内，M21 拆印后 flooded 池（周期 240）与其余两池（周期 450）active 窗出现 90-60tick 重叠，"安全空间随拆印递减"与 briefing 一致。
4. **教学文本与机制对应**：六条分支（tide_boss/tide_flats/ESCORT/CLEANSE/HUNT/默认）与八关 kind 映射完整、无超前、无遗漏；tide_flats 进度 `%d/3` 取 `objective.progress`（已拆数）正确；HUNT 阈值跨越（不存计数、phase 字段归 burrow、恢复不重发、阶段突破重置 timer 打断回潜）与 ADR-0011 及 teaching 表述一致；boss 侧别交替 `e.aim ∈ {0,±1}` 与 valid_state 一致，容量预检 `zones+columns*walls+pools ≤ 128` 满足"不部分发射"（phase2 恰 16，探针实拍 zones=16/projectiles=12）。弱项为 M22 默认分支（P3-8）。
5. **教学/briefing 中英一致性**：briefing 八关中英语义一致、130% 字号无溢出；teaching 六条中五条一致，ESCORT 条不一致（P2-5）、默认条英文缺动作（P3-7）。

## 与 ch1/ch2 的一致性

潮池 ABI（emit_layout_root→poison zone→tide_flat 标记）与 ch1 layout_root/ch2 thermal_vent 同构，valid_state 三章对照完备（chapter 互斥、target 身份、rest_waypoint 时机）；潮池 tick 全部由 `state.tick` 与 `completed_ids` 派生、无第二时钟，advance 的 1/60 锁定与 scene_layout 校验一致。"橙圈/蓝圈"颜色-文案错位是 ch2 已冻结的既有模式，ch3 复制并首次写入 briefing，本评审按 ch3 增量如实列出（P1-1）。

## 限定

数值（池伤 4、墙伤 9.6×0.8s、悟性 8/18）、存档逐 tick 恢复、chapter-two 旧包兼容、真实 PCK GUI、性能与真人试玩不在本评审范围。P0-1 与 P1-3 主线程已确认修复方案；P1-1/P1-2/P2 组建议在修复后复验渲染。本评审不写正式项目任何文件，探针证据保留于 /tmp（截图 20 张、日志、探针脚本），可复查。
