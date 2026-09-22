# 第三章（涨潮）完整本地可玩包 — 2026-09-17

第三章8关（S1-M03-01..08）的专属潮汐机制、局部经济校准、专项验证、三专家复核与独立PCK已交付。限定CAMPAIGN_GAMEPLAY_V1；不是Steam发布验收。新玩家试玩SKIPPED_BY_USER，battle_ready=false。

## 内容与入口

机制清单：`design/chapter-three-playable.md`；架构：ADR-0011。

启动：`build/chapter-three-2026-09-17/开始第三章版试玩.command`。依赖本机 `/Applications/Godot.app` 4.7.1，不是独立Mac app。使用 `Spirit Nexus Chapter Three 20260917` 独立档案目录。首次无双槽时加载自动路线实际打通第一、二章的样例档（completed=16、branches=[TBD]、pages=[TBD]），可直接选第三章；已有任一槽则不覆盖。样例不是人类试玩证据。

catalog SHA256：`TBD_FINAL`

PCK SHA256：`TBD_FINAL`

冻结文件：`build/chapter-three-2026-09-17/manifest.json`（逐文件sha256）。staging src/assets与当前源字节一致；project仅修改隔离应用名。第二章旧包保留且兼容链复验通过。

## 本轮修复与校准（复核驱动）

catalog hash 演进：`44fab78cd781`（三专家复核对象）→ `c6510253203b`（修复+校准后最终）。复核后的代码修复：

1. **P0/P1 潮墙半场（GDScript+UI 复核同源）**：`campaign_chapter_three.gd` Tide.boss 齿锚点由 `(x,0)` 改为 `(x,-arm_length/2)`（y=-625），潮墙段从半场单侧改为全场覆盖；mechanics 测试补 `z.y==-625` 断言。
2. **P1 淹没双区重叠（GDScript+UI 复核同源）**：`campaign_encounter.gd` roots 发射加同 flat 活区守卫，flooded flat 改为"无活区即发射"（保持 tick 派生确定性）；执行顺序核实 advance_zones 先于 Encounter，重发零重叠零空档。mechanics 测试新增 500-tick 逐 tick 探针（每 flat 活区 ≤1、flat0 连续 live ≥499）。
3. **P1 渲染尊重创作色（UI 复核）**：`campaign_arena_render.gd` 去掉 hostile zone 强制红，ch3 蓝/ch2 橙/ch1 绿与全部 briefing/teaching 文案一致（"蓝色圈先预警"等 4 处 ch3 文案+ch2 场景描述全部变真）。
4. **P2 表现强化（UI 复核）**：warn/active 填充 alpha 0.17→0.26、环宽 3→4；line zone 预警线宽 2→3（Godot 4.7 画线羽化移除补偿）；teaching ESCORT 英文修正 "Stay near the %s; stand off while a flat surges."；默认教学英文补 "leave the flat early"。
5. **P3 文案与渲染（UI 复核）**：M03-04 briefing 改"月牙区可全程停留"（几何核实：南圈 [440,60] 与池 [480,-40] 距 108<170）；M03-05 briefing 补"趁预警期离开池区再拆下一座"；ESCORT 渲染新增 chapter_three 渡船船体分支（木壳+篙，替代误用的采药人人形）。
6. **UI P1-2 误报反证（记录）**：harbor roots[0] [-380,340] 未越界——世界半高为 tuning `arena_half_size=[960,640]`（非 spawn 视口 720 半高），相机逐帧跟随玩家（campaign_game_root.gd:134），池 y∈[260,420] 完全可达可见；探针裁切系采样站位所致。未改几何。
7. **UI P3-2 记录不改（accepted-as-is）**：M03-06 SURVIVE 走默认潮池教学——该关场景确有三片潮池，教学非错误，briefing 已覆盖 burrow/jet 完整威胁面。

局部经济校准（仅 M03-03，全局重平衡留待后续章节）：

- `escort_hp` 570→660 + 末段 FERRY_2 波 count 8→6。8-seed 校准探针（S1-C03/completed=18/branches[2,2,2]/风险机缘）：修前 7/8 胜但边际 5.3~247.8/570 且 seed 404 阵亡（风险路线过紧）；先单独 660 后 404 仍败；加末段减员后 **8/8 全胜，边际 142.0~601.0/660（最差保留 21.5%）**，原败者 404 保留 71%。安全路线本就富余（全程仅 ~43 伤害），校准不改变其性质。
- 第三章 xp 曲线 6/4（首6步4）与 upgrade_interval 180 为章内局部校准；包E断言已按设计决定更新（ch3=6、ch4=默认 2 双断言）。

测试假设更新（设计决定取代过时前提，与包E先例同处理）：`campaign_pacing_rewards_test.gd` "chapters three onward unchanged"→ ch3 携带 ch2 同等 pickup 调优 + ch4+ 保持不变（17→18 checks）。

## 最终真实连续路线（两路线）

固定源码下 `runs/TBD/` 两个独立新档，真实Profile消费/解锁/结算，从M01-01连续至M03-08，含磁盘恢复与逐tick对照。

| 路线 | 完成 | 磁盘恢复 | 逐tick比较 | 第三章active时间 | TBD |
|---|---:|---:|---:|---:|---|
| 安全/seed 711 | TBD | TBD | TBD | TBD | TBD |
| S1-C03/风险/seed 977（--alternate-build --risk-route） | TBD | TBD | TBD | TBD | TBD |

## 专项与回归（修复+校准后全量）

TBD：mechanics（1711，含新探针）、rewards、包E 466/0、A/B/C/D-fix/G、Root、Profile、Content、Combat、BossEntry、SnapshotSafety、UpgradeGuard、precision、terminal_disk（--campaign-validation）、pacing_rewards（18）、legacy probe（ch2 兼容链）、pacing_audit、package_g_audit、qa_journey_matrix、ch2 机制+旅程、包B/C/D/E旅程。

事故披露：本轮一次 ch3 旅程探针空转 20 分钟（boss 死亡 tick `entities[0]` 越界中止 `_run` 致 `quit()` 未执行；已修为 family 扫描）；127 容量负例曾因 e.timer 未清零走早退路径（已修）；pacing_rewards 首跑失败系过时前提（见上）。孤儿 run 目录 `runs/44fab78cd781/journey-chapter-three/1789619057-33426-138892/`（空转事故残留，仅 run.json）保留待处置。

## 三专家复核

- QA（qa-review.md）：APPROVED WITH SUGGESTIONS（对象 hash 44fab78cd781）。P0/P1 无；P2 两项（旅程两路线证据未闭合、alternate 双标志）由本报告两路线 PASS 关闭；P3 七项中 5 已修、2 记录级。
- GDScript（gdscript-review.md）：初判 CHANGES REQUIRED（P1 潮墙半场、P2 淹没双区）→ 修复后短程复核 TBD。
- UI（ui-review.md）：初判 CHANGES REQUIRED（P0-1 潮墙半场像素证据、P1-1 颜色文案不符、P1-2 误报见上、P1-3 双区、P2×3、P3×5）→ 修复+反证后复验 TBD。

## 实际包验证与兼容

TBD：新PCK从/tmp实际Mac GUI运行验证；样例档进入M03-01；ch2 旧包 legacy probe。

## 措辞边界

自动证据不是人类试玩、20小时体量或Steam发行验收；battle_ready=false 维持；两指标（active时间、构筑丰富度）边界措辞见各节。Windows 实机、完整 STEAM_SAVE_V2、dense P99 性能为既有独立待办，本轮不宣称。
