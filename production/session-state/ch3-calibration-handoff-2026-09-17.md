# 第三章 M03-07 校准交接（2026-09-17 暂停点）

用户决定切到 Codex 继续。本文件是本段工作的完整状态，接手者从此处继续。

## 已完成（本轮）

1. **QA 矩阵修复收口**：`tests/integration/campaign_journey_test.gd` 5 处编辑（新增 `generic_mission()` helper 选无 layout/stages/clues 的 ch4+ 通用任务 + 弱敌行改 `d.enemies[0].id`）。旧 hash `c6510253203b` 下 **266/0 PASS**（证据 `runs/c6510253203b/campaign-qa/1789624262-63179-125028/`）。根因：fixture 与 ch1 重设计任务模型不兼容（非生产 bug）。
2. **M03-07 校准已应用到源**：`tools/campaign/build_catalog.py` L355 附近，WARDEN_REAR wave 改为 `wave('WARDEN_REAR','ACTIVE_TICK',0,[9],3,5,300)`（count 8→5、offset 0→300）。**catalog 已重建，新 hash `f7f6c060b35956878815105f19dd7df9c791d142100ba973e45820e40899162f`**，旧 hash 的全部 hash 绑定证据作废待重跑。
3. **探针扫描**（/tmp/ch3_warden_sweep*.gd，均带看门狗跑法）：REAR 数量是主导旋钮；DUEL count 无影响（V4≈V0）；interval 90 更糟（与 DUEL 波叠堆）；enemy_scaling 降 1.0 虽然 8/8 但 warden 弱于 M03-02，叙事倒退，不取。选定 V6（rear5+off300）：选种 8/8（最差边际 4%）、新 16 种子 13/16。失败模式：升级成型前（首升级 tick 180 之前/前后）被 warden 爆发+鳍兽压制。
4. **ch3 旅程（新 hash 下）**：safe 线 **PASS**（M03-07 14.5s 满血）。alt 线 **仍 FAIL**：M03-07 46.7s 阵亡、level 2、kills 1、elite_kills 0（比校准前 34.35s 有延长但仍败）。

## 当前卡点（接手第一步）

alt 旅程失败原因刚定位：`tests/integration/campaign_chapter_three_journey.gd` L19 `seed(977)` 只播全局流；每局 arena 种子来自 `src/campaign/campaign_profile.gd` L198 `"seed": str(randi())`（全局流抽取），**不是 977 本身**，所以探针种子 ≠ 旅程实际种子。已确认：arena 用自有 RNG（campaign_arena.gd L21 `var rng := RandomNumberGenerator.new()`），campaign_c_bot 无全局 rand——**旅程种子可通过只重放 profile 购买/begin_run 序列精确复现**（无需跑战斗）。

复现探针写法：`seed(977)` 后按 journey L20-25 的顺序执行 22 个 index 的 pages/branches 购买 + `profile.begin_run(index)`，记录 index=22 的 `run.seed`，再用该种子配 `completed=22, branches=[2,2,2], character=S1-C03` 跑单局 arena 复现失败，然后决定是否再调一轮（下一候选：offset 300→450、REAR interval 45→60、或接受旅程种子定向验证）。

## 待办队列（按序）

1. 复现 alt 旅程 M03-07 实际种子 → 定向调参或确认 → alt/safe 两线旅程 PASS 落盘 journey.json/journey-alternate.json
2. 新 hash 下重跑绑定套件：QA 矩阵（campaign_journey_test.gd 带 `--qa-production-*` 参数，见文件 L131-544）、pacing_rewards（断言已修 18 checks 待复跑）、chapter_three/rewards 套件、ch2 journey、包 B/C/D/E journey、其余回归批 28 套件
3. legacy_probe 四模式链（带参数：`-- <mode> <stem> [hash]`；旧包 `build/chapter-two-2026-09-16/SpiritNexus-ChapterTwo.pck`，旧 hash `7a6edddb768b4bb813bc52bd0fd334269ebeee7a6228ac55ac0806704801420f`）
4. 收两个复核 agent 结论：GDScript 复核（含 ch2/ch3 boss 断言不对称发现）、UI 复核 verdict（探针在隔离环境 /tmp/ch3-ui-probe-project 可能没跑完）
5. `/tmp/ch3_freeze.sh`（staging→PCK→样例档→manifest）→ PCK GUI 实跑验证 → `design/registry/manifests/campaign-chapter-three-v1.json`（battle_ready=false、new_player_test=SKIPPED_BY_USER、最终 hash）
6. 证据报告 `production/playtest-evidence/2026-09-17-chapter-three.md` 填 TBD；`production/session-state/active.md` 最终更新

## 运行命令模板

```bash
G=/Applications/Godot.app/Contents/MacOS/Godot
# 旅程（必带看门狗防空转）
( $G --headless --path . --script tests/integration/campaign_chapter_three_journey.gd -- --alternate-build --risk-route > /tmp/x.log 2>&1 & p=$!; ( sleep 1800; kill -9 $p ) & w=$!; wait $p; rc=$?; kill $w; exit $rc )
# catalog 重建 + hash
python3 tools/campaign/build_catalog.py
```

## 诚实性红线（不可违背）

- battle_ready=false 维持；新玩家试玩 SKIPPED_BY_USER；自动证据 ≠ 人类试玩/20 小时/Steam 发行验收
- QA 矩阵三轮未跑属回归覆盖缺口，本轮首跑修复——证据报告必须披露
- catalog hash 演进链：44fab78c → c6510253203b → f7f6c060（当前），证据必须绑定最终 hash

## 2026-09-17 Codex接手结果

本交接队列已完成第三章限定收口，见 `production/playtest-evidence/2026-09-17-chapter-three.md`；最终目录6cea8186，两线24/24。旧首领真实seed1479748453，后路5/450/60。新增阶段快照与整轮弹池修复、实际新包/旧包兼容均验证。额外64关检查的后续章节失败明确留存，未伪记PASS。
