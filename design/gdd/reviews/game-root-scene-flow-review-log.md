# GameRoot & Scene Flow — Design Review Log

> 本文件记录 `design/gdd/game-root-scene-flow.md` 的 design-review 历史与修订闭环追踪。

---

## Review — 2026-08-28 — Verdict: NEEDS REVISION
Scope signal: M（偏 M-L，producer 核验）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director 终审
Blocking items: 5（CD 排名）| Recommended: ~20 | First review: Yes（GameRoot 首次独立 full review；此前 20 轮为 InputSystem review 期间的 mirror 增量）

### Verdict 摘要
编排模型本身健全（状态机/phase 顺序/事务 rollback/诚实停止 fault 路径/双缓冲引用交换/resume 不可逆点逻辑自洽且与已冻结契约一致），8 节完整。不构成 MAJOR REVISION（无需重做编排模型）。但 5 项 BLOCKING 须本轮解决：RNG 集成缺失（违诚实停止）、TECHNICAL_ABORT 清零与概念 12.1 冲突、权威序列碎片化+scope creep（20 轮 churn 根因）、R3 dirty-patch 隔离 hazard、AC 巨型打包不可测。

### CD 裁定的 3 项设计决策（用户已裁决）
1. **TECHNICAL_ABORT → 授予部分奖励**：按存活/击杀授予与 gameplay failure 等价的部分奖励（灵石/残页/种子），诚实告知异常中断但补偿参照失败结算，需 SaveSystem reservation/commit。
2. **文档架构 → Scoped A**：删除 R1/R7 的 InputSystem 内部 FSM 镜像，保留行为契约+单一权威引用 input-system.md。
3. **R3 → 禁 dirty-patch + 全量 copy 上界 AC**：强制预分配全量 copy，消除 stale-bank 与隔离 hazard。

### CD 裁定的分歧
- **VJ 4.7.1 信号 ABI**：godot-specialist 标 BLOCKING → CD 下调为继承的证据/evidence gate（InputSystem 已 Approved 并把 VJ 实测留为实现 gate，GameRoot 仅引用，不双重计费）。但 `set_disable_input`/`set_pause`/`set_mouse_filter` 同步通知语义是 GameRoot 特有新 evidence gate（REC 级），合并到同一引擎验证 ADR，实现期实测。
- **held-touch「松手重按」**：game-designer 质疑 → CD 维持已确立的诚实化机制（正确性机制：pause 前按住手指若自动 resume 成幽灵移动，违「可信」+诚实停止）。降级为 RECOMMENDED：held-drain UX 反馈 AC + resume 感知预算 AC。
- **文档架构 A vs B**：CD 推荐 scoped A（用户采纳）。

### 5 项 BLOCKING（CD 排名）与处置
1. **RNG GATE-G3 集成缺失** [TD] — ✅ 闭环：Dependencies 表加 RNG 行；R4 phase 模板加 phase 边界 `has_fault()` 检查；R5 fault path 加 RNG 为 fault source + telemetry schema 对齐；AC-G2 联动 RNG fault；R2 BATTLE_LOADING 加 RNG init；跨文档一致性块加 RNG 条目。
2. **TECHNICAL_ABORT 清零 vs 概念 12.1** [gd+sys] — ✅ 闭环：R9 改为授予部分奖励（不伪造结局，但按存活/击杀授予等价部分奖励）；AC-F1 拆为 AC-F1a（persistence/telemetry BLOCKING）+ AC-F1b（UI ADVISORY）；AC-F3 同步部分奖励测试范围。
3. **权威序列碎片化 + scope creep** [TD] — ⏳ pending（Scoped A 删除，待新会话）。
4. **R3 dirty-patch 隔离 hazard + resume wallclock** [perf+sys+TD] — ✅ 部分闭环：R3 强制全量 copy、禁 dirty-patch（消除 stale-bank + 隔离 hazard）；AC-G1b 全量 copy positive control + dirty-patch 反例 + published-immutability spy。resume wallclock 预算 AC 待新会话（与 held-drain UX AC 合流）。
5. **AC 巨型打包不可测** [qa] — ⏳ pending（9 个 AC 拆分，待新会话；依赖 Scoped A 结果）。

### 已闭环的 spec/AC 修复（非 BLOCKING 设计决策，direct-write）
- F1-F4 全部补变量表 + 工作例子（systems BL1）✅
- F1 `published_resolution=∅` 语义改为"不交换 bank、inactive staging 丢弃"（systems BL2）✅
- `published_tick_revision` 字段声明到 ResolutionStagingBank 结构（systems BL5）✅
- F3 drift 修复：phase 重置 SPAWN_INTENT、authority_revision 不变量、resume next-pair 保留（systems REC）✅
- AC-G1 拆为 G1a/b/c/d + Variant boxing/signal/Dict churn 断言 + 全量 copy positive control + dirty-patch 反例 + published-immutability spy（qa BL5 + perf R1/B1 + systems BL3 + TD R5）✅
- AC-B1 拆为 B1a（静态守卫）+ B1b（行为 trace + lease 零分配 SoA）+ participant 禁 `_unhandled_input`/`_input` + body 调用数澄清（qa R3 + perf B2/R2 + godot N3/N4）✅
- AC-F1 拆为 F1a（BLOCKING persistence）+ F1b（ADVISORY UI）（qa BL4）✅
- TECHNICAL_ABORT 部分奖励（覆盖 game-designer BL4）✅
- RNG 集成（覆盖 TD BL1）✅

### 待新会话修订（pending）
- **Scoped A 删除** [TD BL2+BL3]：删除 R1 L25/L29/L31 ~2500词 InputSystem 内部 FSM 镜像 + R7 step10 内部机制 + R7 第17/18轮 override；保留行为契约（调用顺序/可观察 status/tuple 语义），替换为单一权威引用 input-system.md §X。11 处副本→1 处行为契约 + N 处引用。
- **AC 拆分** [qa BL1]：9 个巨型 AC（AC-A2/A2b/D3/D3b/D4/D4b/E1/E2/G1 已部分拆 G1/B1/F1）逐子场景拆分；每个"第N轮补充"Then 拆为独立 AC。依赖 Scoped A 结果。
- **AC 确定性修复** [qa BL2/BL3]：AC-D4 真机依赖改注入式 simulation + 去"100次"magic；AC-A3 去 magic。
- **覆盖缺口补 AC** [qa]：Edge Case 2（pause+death 同 tick→battle-end 优先）/ R8 manual exit=ABANDONED / R8 manual-exit-during-Active latch / fault-UI spam（已并入 AC-F1b）。
- **R6 quarantine 失败路径** [sys BL4]：跨系统 gap（Grid PausedFrozen→Active rollback 边缺失），需 TD 协调 GameRoot↔SpatialGrid↔ObjectPooling 三方同步。
- **held-drain UX 反馈 AC + resume wallclock 预算 AC** [gd BL1 降级 + perf BL3]。
- **pause reason 可区分性 + pause-time presentation 契约 AC** [gd BL2/BL3/REC]。
- **`show_pause_pending_overlay_after_frames=1` 阈值上调或移除**（1 帧=闪烁）[gd BL3]。
- **引擎 evidence gate 标注**：VJ ABI（继承）+ `set_disable_input`/`set_pause`/`set_mouse_filter` 同步通知语义（GameRoot 特有）+ `agile_event_flushing` 路径 + APP_BACKGROUND 通知常量 [godot]——合并到同一引擎验证 ADR，实现期实测。
- **"push_input 在 Control picking 前返回"措辞修正** [godot R4]。
- **"window_input consumer"术语澄清** [godot R5]。

### 跨文档影响（本轮修订触发的对端 GDD 待核）
- rng-system.md GATE-G3：GameRoot 已登记 has_fault 检查义务，GATE-G3 可解阻（待 RNG 侧确认）。
- technical-preferences.md Forbidden Patterns：AC-G1a/AC-B1b 已引用 participant 注册表 Array 非 Dictionary、禁 get_children —— 无需改 technical-preferences，GDD AC 守卫即可。

Prior verdict resolved: First review（无前序 verdict）。

---

## 修订进度追踪

| 批次 | 状态 | 说明 |
|------|------|------|
| RNG GATE-G3 集成 | ✅ DONE | Dependencies/R2/R4/R5/AC-G2/跨文档块 |
| TECHNICAL_ABORT 部分奖励 | ✅ DONE | R9/AC-F1a/AC-F1b/AC-F3 |
| R3 全量 copy | ✅ DONE | R3/AC-G1b |
| F1-F4 变量表+语义 | ✅ DONE | Formulas 全节重写 |
| AC-G1+AC-B1 守卫 | ✅ DONE | AC-G1a/b/c/d + AC-B1a/b |
| Scoped A 删除 | ⏳ pending | 待新会话（clean context） |
| AC 拆分+确定性+覆盖缺口 | ⏳ pending | 待新会话（依赖 Scoped A） |

---

## Review — 2026-08-28 — Verdict: NEEDS REVISION（第二轮 re-review）
Scope signal: L（偏 M-L，producer 核验）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director 终审
Blocking items: 11（CD 排名 B1-B11）| Recommended: 16 | First review: No（首轮 NEEDS REVISION 2026-08-28 的第二轮独立复审）

### Verdict 摘要
严于首轮（非 MAJOR REVISION——编排模型健全，6 specialist 一致确认无需重做）。首轮 5 BLOCKING 中 3 项闭环（RNG/TECHNICAL_ABORT/R3 全量 copy/F1-F4/AC-G1+AC-B1 守卫）维持无回归（SYS 确认契约层闭合）；2 项 pending（Scoped A + AC 拆分）**未执行且第 17-20 轮向 GameRoot 注入更多 InputSystem 镜像内容反向加重 Scoped A**。本轮新发现 9 项 BLOCKING（B4/B6/B7/B8/B9 新增 + B3/B5/B10/B11 升回/未闭合）。问题集中在 spec 层：权威归属碎片化、AC 不可测、实现可行性 gap（GDScript 装箱）、Player Fantasy 度量缺口、API 名错误。

### 11 项 BLOCKING（CD 排名）与处置
1. **[B1, TD+QA] Scoped A 执行——删 InputSystem 内部 FSM 镜像**：R1 L25/L29/L31 + R7 step10 + R5 + R8 含 ~2500-3500 词内部机制。替换为行为契约 + 单一权威引用 input-system.md。**未执行且反向加重**。⏳ pending（L 级，新会话 clean context）
2. **[B2, QA+TD] 9 巨型 AC 拆分**：AC-A2/A2b/D3/D4/D4b/E1/E2 逐子场景拆为独立 Given/When/Then。**未执行**。⏳ pending（依赖 B1，新会话）
3. **[B3, GD+PERF] resume wallclock budget AC + per-tick orchestration wallclock budget AC 缺失**：Player Fantasy"即时"不可度量。首轮 perf BL3 未闭合。CD 采纳 GD 升回 BLOCKING。⏳ pending
4. **[B4, GD 新增] is_choice_input_blocked() 阻塞 choice 无玩家面反馈 AC**：survivor 自动暂停时手指留 VJ，choice 被吞无反馈，flow 断裂。⏳ pending
5. **[B5, GD] pause reason 可区分性 + presentation 契约 AC**：6 种 pause reason 无玩家面可区分 presentation。首轮 gd BL2/BL3 未闭合，CD 升回 BLOCKING。⏳ pending
6. **[B6, PERF 新增] R3 全量 copy 零装箱 bulk-copy 机制未命名**：PackedInt64Array[i] 返回 Variant→boxing（MAX_INDEXED_ENTRIES=1000×4=4000 次/tick），GDD 声称不违 AC-G1 零增长但未命名机制（dest.clear();dest.append_array(src) C++ memcpy）+ AC-G1b 补 variant_box copy-path positive control。CD 采纳 PERF（SYS"R3 已闭环"判定过窄，只看契约不看 GDScript 可行性）。首轮 R3 闭环遗漏。⏳ pending
7. **[B7, PERF 新增] 三 counter instrument 粒度未定义**：variant_box_events/signal_emit_events/dictionary_lookup_events 捕获边界未决；若捕获函数调用参数装箱则 participant.run_phase(...) 使 AC-G1a 不可满足。须明确捕获来源 + 声明不捕获的"不可避免 GDScript 机制" + 理由 + 每路径 positive control。⏳ pending
8. **[B8, GODOT] set_disable_input API 名修正**：应为 set_gui_disable_input/gui_disable_input（R1 L31 正确，R7/AC-E2 用错名）。静态守卫 pattern 须对齐真实 API 名。⏳ pending（S 端，可本轮修）
9. **[B9, GD] TECHNICAL_ABORT 种子奖励源与概念 12.1 hedge**：概念种子="已拾取"，GDD R9 措辞可被解读为按存活时间等价计算。R9 改分源（灵石=击杀/残页=存活时间/种子=仅已拾取），AC-F1a 补"未拾取种子则种子=0"。CD 从 RECOMMENDED 升 BLOCKING。⏳ pending
10. **[B10, QA] 3 覆盖缺口补 AC**：Edge Case 2 pause+death 同 tick→battle-end 优先 / R8 manual exit=ABANDONED / R8 manual-exit-during-Active latch。首轮未闭合。⏳ pending
11. **[B11, QA] AC 确定性修复**：AC-A3 去"100次"magic + 枚举非法边；AC-D4 去"100次"magic + 真机后台依赖改注入式 simulation。首轮 BL2/BL3 未闭合。**与 B2 耦合**（AC-A3/AC-D4 在 B2 拆分列表内）。⏳ pending

### 16 项 RECOMMENDED（condensed）
- [SYS] R7 step9 resume 不可逆点 Pool publish 复检失败 hedge；drain tick phase failure fault 语义明确；POST_DEFERRED_BARRIER failure 后 DEFERRED_REMOVAL 已 publish 不回滚——R5 措辞 hedge；loading failure cleanup 后 Input 状态 UNARMED vs TERMINATED 明确；非 RNG fault 路径 RNG teardown telemetry 写入明确。
- [TD] 全文 12+ 处"第N轮 override/补充"脚手架折叠（Scoped A 执行时一并）；R5+R7 实现级 invariant（atomic-commit 技术）defer ADR + evidence hedge。
- [PERF] AC-B1b lease SoA 处方跨 GDD 越权——改引用 SpatialGrid lease 零分配契约 + 简化为单标量 current_lease_id+lease_open；held-drain per-iteration 零分配守卫（AC-G1c 显式三 counter）+ shield/held bank 容器处方（预分配 SoA 禁 Dictionary）。
- [QA] AC-G1d 补 positive control；AC-G1a 三 counter positive control fixture 构造方式描述；AC-G1b"byte-identical"观测方法明确；AC-D2"玩家HP"观测点明确；AC-B1b/AC-G2 去 magic；AC-B1a static_guard_check.py 实现前置依赖标注。
- [GD] show_pause_pending_overlay_after_frames=1 上调 3 帧或淡入；fault UI 文案加"（非战斗失败）"显式区分；RESUME_PREPARING"必要时"触发条件定义 / fault 页折叠式奖励摘要；held-drain 自动暂停 flow 断裂 playtest。
- [GODOT] 两阶段激活 ADR 写明 contingency（set_pause/set_mouse_filter 不同步则 redesign）+ 4.6 dual-focus 影响评估；INPUT_GEOMETRY_CHANGED 检测 signal pin；Host _notification 对 NOTIFICATION_PAUSED/UNPAUSED fall-through 明确；agile_event_flushing 真实性二选一确认；is_using_accumulated_input readback API evidence gate；pending R4"push_input Control picking 前返回"措辞修正；pending R5"window_input consumer"术语澄清；第 17-20 轮同步断言 inline hedge。

### Specialist 分歧（CD 已裁决，双方呈现）
1. **TD vs SYS — Scoped A 严重度**：TD=BLOCKING（架构 churn 根因，未自愈，不可签发）；SYS="文档架构优化，非一致性 issue"。CD 采纳 TD（维度不同不矛盾——SYS 谈契约正确性成立，TD 谈可维护性/churn 也成立；churn 根因未消除 + QA AC 拆分依赖它→BLOCKING）。
2. **GD vs 首轮 CD — UX AC 严重度**：首轮 held-drain UX 降 RECOMMENDED；GD 主张 #1(wallclock)/#3(pause presentation) 升回 BLOCKING + #2(choice feedback) 新增 BLOCKING；PERF 也把 wallclock 标 BLOCKING。CD 采纳 GD+PERF（Player Fantasy"即时/可信"核心承诺 + 概念"谨慎"情绪要求设计门而非 defer）→ B3/B4/B5。
3. **PERF vs SYS — R3 boxing**：SYS"R3 全量 copy 已闭环/消除 dirty-write 泄漏"（契约层）；PERF 发现 GDScript 实现层 boxing gap（PackedInt64Array[i] 返回 Variant，未命名零装箱机制）。CD 采纳 PERF（SYS"闭环"判定过窄，只看契约逻辑不看 GDScript 实现可行性）→ B6 新 BLOCKING。
4. **QA vs 事实 — AC-K5 断引用**：QA 标 BLOCKING 称 SpatialGrid 无 K 组；CD 核实 spatial-grid.md line 1007 存在 AC-K5（`### K. 架构约束`）。CD 驳回——QA 事实错误，AC-C1 引用有效，非 BLOCKING。

### CD 高级裁决
**CD-GAME-ROOT-FLOW-R2: NEEDS REVISION**（严于首轮，非 MAJOR REVISION）。编排模型健全（6 specialist 一致），问题在 spec 层。11 BLOCKING 须闭环才能签发。B1+B2 为 L 级强耦结构重写，建议新会话 clean context 执行；B3-B11 多为 hedge/补 AC/具体修（S-M 端），可本轮或新会话。8 项引擎验证以 GATE-OQ ADR 形式 defer 实现期实测。sys BL4 quarantine 可标闭合（已通过 fault 路径，不需 PausedFrozen→Active rollback 边）。全 BLOCKING 闭环后须第三轮 re-review。

### 引擎验证 defer（GATE-OQ ADR，实现期实测）
set_gui_disable_input / set_pause 同步传播 / set_mouse_filter 4.6 dual-focus / INPUT_GEOMETRY_CHANGED 检测 signal / agile_event_flushing 真实性 / is_using_accumulated_input readback / NOTIFICATION_PAUSED/UNPAUSED Host 处理 / VJ ABI 继承。

Prior verdict resolved: 部分回归 + 新发现。首轮 5 BLOCKING 中 3 闭环维持无回归；2 pending 未执行且 Scoped A 反向加重；新增 9 项 BLOCKING。

---

## Review — 2026-08-28 — Verdict: NEEDS REVISION（第三轮 full re-review）

Scope signal: XL（规范收敛与跨文档传播；非架构重做）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director 终审
Prior verdict: 第二轮 NEEDS REVISION
Creative Director verdict: **NEEDS REVISION；不构成 MAJOR REVISION**

### 前序 11 项闭环审计

- B1 Scoped A、B2 AC 拆分、B3 wallclock gates、B4 choice-blocked feedback、B5 pause presentation、B7 instrumentation 边界、B9 seed reward source、B10 覆盖缺口、B11 注入式确定性：修订目标已落入主文或主体闭合。
- B6：前序“`PackedArray[i]` 装箱等于 heap allocation、`clear()+append_array()`必然零分配”的证据链不成立。第三轮不沿用该结论，改为预分配 `AuthorityCopyManifest`、禁止 resize/clear/append/COW alias，并以容量/identity/growth counters + runtime evidence gate 验证；不能由语法臆断 native allocation。
- B8：**false positive**。Godot 4.7.1 `Viewport.gui_disable_input` 属性的 setter 正是 `set_disable_input(bool)`；不得改成不存在的 `set_gui_disable_input`。第二轮对应 blocker 作废。

### 第三轮根 blocker（CD 去重）

1. **Fault reward source conflict**：Grid fault tick“不得产生新奖励”与 GameRoot TECHNICAL_ABORT 补偿表述混淆；须限定为只能从 fault 前已提交事实结算。
2. **Run identity chain incomplete**：Config 缺 `RunStartRequest.run_seed→BattleConfigSnapshot` 单一来源；resume 前缺 owner/Grid/Pool `config_snapshot_id` 一致性复核；settlement 缺完整 RunOutcome envelope。
3. **Authority/resolution publish token incomplete**：仅有 published revision，无法证明 consumer 已消费同一稳定 bank；须加入 consumed revision 与禁止 alias/COW 的 copy manifest。
4. **Grid→Pool publish failure domain invalid**：matching Pool publish 若仍调用 Node/重新校验就可能在 Grid 已 publish 后失败，造成无法回滚的半提交；最终 Node identity/capacity 验证必须前移到 arm，matching publish 收窄为不可失败纯发布。
5. **Pause lifecycle observer invalid**：`PROCESS_MODE_ALWAYS` Host/shield/VJ 不能作为 `NOTIFICATION_UNPAUSED` 必达观察者；`set_pause(false)` 返回后由 GameRoot 显式执行 post-unpause observer，通知语义另用 pausable probe 取证。
6. **Geometry relay missing**：Control Host 不应被假定接收 Window-only resize/safe-area 通知；须由 InputSystem-owned Window/Viewport relay canonicalize geometry 并 typed-forward invalidation。

### 同根追踪缺口

- diagnostics 容器需预分配且不得依赖 runtime growth；GATE-OQ 必须进入主 GDD，不得只存在 review log。
- Config `max_query_radius` 的 separation 项须与调用侧显式同形为 `separation_radius+max_separation_radius`。
- Stage camera 由 Stage owner 持有，GameRoot 只在 BATTLE_LOADING 注册/注入，不反向吞并 owner。
- TECHNICAL_ABORT 与正常结算均须通过 `RunOutcomeEnvelope`；Save commit 必须有 PENDING/SUCCESS/FAILURE 玩家面，不得把构造 outcome 当作已持久化。

### 用户裁决与修订结果

用户选择 **A：允许更新全部 blocker 与追踪文件**。已完成：

- `game-root-scene-flow.md` 重写为唯一编排契约：保留七 phase，删除 Input FSM 镜像；加入 safe-boundary pause、RunStartRequest/run_seed、snapshot ID preflight、AuthorityCopyManifest、published/consumed revision、FailureDiagnosticBank、RunOutcomeEnvelope、Save commit 状态、GATE-OQ 与独立 AC A1-F4/GATE-F5。
- `config-data-system.md`：冻结 run_seed 单一来源与 snapshot 逐位复制；修正 max_query_radius separation 项；补 AC-D4。
- `object-pooling.md`：arm 完成最终 Node identity/capacity 验证；matching publish 无 Node API、不可失败；补 AC-E3 fixture。
- `input-system.md`：移除 ALWAYS 节点 unpause 通知 oracle；冻结 GameRoot explicit second observer 与 Window/Viewport geometry relay。
- `stage-map.md`：Stage scene 重新确认为唯一 Camera2D 规格/identity owner，GameRoot 只注册/注入。
- `spatial-grid.md`、`rng-system.md`、registry：同步 fault/reward 边界、GATE 引用、run_seed 消费关系及显式 separation 公式。

### 当前状态

**Re-review Pending**。本次只完成设计文档与追踪闭环，尚未经过第四轮独立 full re-review；未执行 Godot runtime、真机性能、Save integration、项目 asset 或 GATE-OQ harness，因此不得标记 Approved、implementation-ready、battle-ready 或 benchmark-ready。

Prior verdict resolved: 第二轮目标已大部闭合，B6/B8 证据纠偏；第三轮新根 blocker 已修订但尚未独立验收。

---

## Review — 2026-08-28 — Verdict: MAJOR REVISION NEEDED（第四轮 full re-review）

Scope signal: XL（中央FSM/lifetime/DAG/identity与AC重写；七phase核心保留）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director终审
Blocking items: 7个去重根因 | Recommended: 7项
Prior verdict: 第三轮 NEEDS REVISION

### Verdict 摘要

第三轮6个修订目标均已落文，但系统性闭环仅3 CLOSED + 3 PARTIAL。Creative Director裁定七phase、Grid→Pool不可逆点、Input单一权威和fault-before-reward方向可保留；中央文档仍缺可枚举FSM与实际pause-on、GameRoot lifetime、合法load/teardown DAG、battle/publication/persistence identity、paused pump/reason仲裁，以及多个会false pass/fail的AC，因此升级为MAJOR REVISION NEEDED，scope XL。

### 7个根 BLOCKING

1. GameRoot lifetime、顶层FSM、CONTROLLED_FAULT边与`SceneTree.set_pause(true)` authority未闭合。
2. Loading/teardown不是依赖DAG，遗漏BOOT Input bootstrap与Stage typed Camera/Viewport assembly。
3. battle/config/authority/resolution identity与exact-once bank token链未闭合。
4. immutable `RunOutcomeEnvelope`与mutable Save commit state冲突，缺稳定commit identity。
5. paused/resume pump、复合reason仲裁与drain零gameplay-effect证明不足。
6. phase failure AC错误要求回滚此前合法publish，failure矩阵不可独立定位。
7. AC-F1～F4存在错误allocation/diagnostic/seed oracle或空workload假通过路径。

### 用户授权与修订结果

用户选择A并确认完整变更集及四项设计决策：persistent GameRoot；独立`battle_instance_id`与`outcome_commit_id`；pause reason按`priority→intent_sequence`；immutable outcome facts与mutable Save attempt分离，save失败安全退出HOME但不得谎报到账。

已修订：

- `game-root-scene-flow.md`：新增persistent lifetime、显式adjacency、pause truth table与唯一writer、typed load/cleanup DAG、Stage Camera/Viewport assembly、authority/resolution完整token、paused pump checkpoints、reason queue、held-drain substate、normal/fault Save状态、pre-battle fault无虚假outcome边界、即时Pending锁定反馈、F1-F6与row-addressable AC。
- `technical-preferences.md`：同步persistent GameRoot与SceneTree pause writer边界。
- `config-data-system.md`：逐位冻结`battle_instance_id`，明确`snapshot_id==config_snapshot_id`及DAG。
- `input-system.md`：同步GameRoot公共pump/checkpoint/pause义务，不复制Input私有FSM。
- `stage-map.md`：补typed Camera2D assembly、Viewport/active camera identity与AC-E3。
- `systems-index.md`、`active.md`：同步当前状态与下一步。

### 当前状态

**Re-review Pending**。修订只闭环第四轮明列根因，尚未经过第五轮独立full re-review；无Godot runtime、Save integration、project asset、真机performance或GATE-OQ证据，不得标Approved、implementation-ready、battle-ready或benchmark-ready。

Prior verdict resolved: 第四轮7根BLOCKING已按授权修订，待第五轮独立复审验证。

---

## Review — 2026-08-28 — Verdict: MAJOR REVISION NEEDED（第五轮 full re-review）

Scope signal: XL（pause drain、phase-6 commit、resume authority、viewport、outcome/save 与证据门）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director终审
Blocking items: 9个去重根因
Prior verdict: 第四轮 MAJOR REVISION NEEDED，修订后 Re-review Pending

### Verdict 摘要

第四轮补入的 persistent lifetime、typed DAG、identity、reason queue 与 Save attempt 方向可保留，但第五轮在逐状态/逐 checkpoint 对抗复核中发现 9 个会形成 dead state、半提交、空表假通过或错误结算的根 blocker。Creative Director 判定继续 `MAJOR REVISION NEEDED`；不推翻七 phase 与 Input 私有 FSM 单一权威。

### 9个根 BLOCKING

1. `PAUSE_PENDING` 无实际可运行 callback，且误以为 PAUSABLE 会冻结普通 signal callback。
2. typed FSM/event/status/fault cleanup 不可枚举，缺 pause-off finalizer 与 bootstrap retry/safe-exit 边。
3. required participant/service manifest 允许空表，`all(empty)==true` 可伪造 battle-ready。
4. resume latch 分裂，attempt 未完整捕获 config/authority identity，publish checkpoint 不足。
5. phase 6 `remove→release` 中途失败无法整体回滚，旧文未定义 committed partial facts。
6. battle render Viewport 与 GUI input Viewport 拓扑不确定，per-battle SubViewport 会引入独立输入路由。
7. FailureDiagnosticBank/RNG telemetry 容量、schema、关联与 teardown 前 capture 不闭合。
8. `RunOutcomeEnvelope` producer/primitive ABI 与 Save pending/backpressure/player truth 不完整。
9. capacity/numeric/evidence AC 存在空 workload、错误样本域与 false-pass/false-fail。

### 用户裁决（方案 A）

用户同意推荐方案并授权写入全部受影响文件，冻结六项设计决策：

1. 保留顶层 `PAUSE_PENDING`；GameRoot 允许且仅允许一个 `gameplay_dt=0` 技术 drain tick。
2. phase 6 使用预分配、逐 intent exact-once `LifecycleCommitJournal`。
3. MVP 使用 persistent root `Window` 同时承担 render 与 GUI input Viewport；不创建 per-battle SubViewport。
4. 应用最多 1 个 pending Save commit；成功或显式 discard 前阻止新 run。
5. `ABANDONED` 无奖励、纪录、教程，也不补偿玩家有意消耗的 prep 资源。
6. physics 固定 60 Hz，gameplay `dt=1/60`；callback delta 仅校验 cadence。

### 修订结果

- `game-root-scene-flow.md`：补 `TopEvent/GameRootStatus` adjacency、required manifests、single Pending drain、signal allowlist、exact-once lifecycle journal、failure diagnostic/RNG sidecar、`AuthorityResumeCommitPlan`、Grid→Pool→authority 三次 publish、canonical `RunOutcomeEnvelopeV1`、单 pending Save backpressure、outcome matrix与扩展 AC。
- `technical-preferences.md`、`input-system.md`：同步唯一 ALWAYS GameRoot、dt=0 drain、PAUSABLE signal边界、persistent root Window、唯一 resume latch与三次 publish；Input 私有 FSM 不复制。
- `config-data-system.md`：新增 `RuntimeOrchestrationLimits`、required participant/service/outcome manifests、60 Hz/reason/diagnostic/journal/save limits 与完整性 AC。当前仅 Input/Enemy owner contract 已冻结，故 battle-ready 仍 false。
- `stage-map.md`：typed assembly 改为 `{stage_root,stage_camera}` + 注入 root Window；禁止 per-battle SubViewport；`PackedVector2Array` 强制 `.duplicate()`。
- `spatial-grid.md`、`object-pooling.md`、`enemy-system.md`：phase-6 remove/release/retire 成功是不可回滚 committed facts；第 N 条 failure 从 journal 收敛 authority，禁止复活旧 handle/borrow 或重复 reset/free-stack push。
- `rng-system.md`：冻结 versioned `RngFaultTelemetrySnapshot` 与 RNG teardown 前 exact-once capture/diagnostic关联。
- registry、systems-index、session state：登记60 Hz、fixed dt、reason公式、single pending Save、diagnostic下界；所有受影响文档回到 In Review/Re-review Pending。

### 当前状态

**Re-review Pending**。第五轮 9 根 blocker 已按用户授权完成设计修订，但尚未经过第六轮独立 full re-review。仓库仍无足够 runtime/project asset/Save integration/min-spec performance/GATE-OQ evidence；不得标记 Approved、implementation-ready、battle-ready 或 benchmark-ready。

Prior verdict resolved: 第五轮明列根因已落入主契约与跨文档传播；待第六轮独立复审验证是否真正闭环。

---

## Review — 2026-08-28 — Verdict: MAJOR REVISION NEEDED（第六轮 full re-review）

Scope signal: XL（callback/topology、phase-6 authority、Enemy时序、Outcome ABI、Save不确定提交与证据门）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director终审
Blocking items: 8个去重根因
Prior verdict: 第五轮 MAJOR REVISION NEEDED，修订后 Re-review Pending

### Verdict 摘要

第五轮的persistent GameRoot、单次Pending drain、typed load/cleanup DAG与三段resume骨架可保留。第六轮对callback可达面、phase-6不可逆事实、Outcome逐字段ABI和Save完成竞态继续做对抗复核，发现8个根blocker；Creative Director裁定仍为`MAJOR REVISION NEEDED`、scope XL。用户选择完整变更集并采用推荐终局、Outcome ABI和Save策略。

### 8个根 BLOCKING

1. `GameplaySignalAllowlist`未覆盖Godot虚回调/notification，暂停通知仍可能越权写gameplay状态。
2. `BattleViewportTopologyManifest`、唯一Camera/Viewport writer和resume期间拓扑revision未冻结。
3. required participant的逐phase coverage与required service精确集合仍可能空表/漏phase假通过。
4. phase 6把lifecycle步骤与gameplay facts混在journal中，且逐step authority publish/copy成本和故障收敛不闭合。
5. Enemy在QUERY_CONSUME计算后声称回写同tick更早的MOVEMENT_COMMIT，七phase因果顺序不可实现。
6. normal terminal seal、同tick Boss victory/player death优先级与cleanup fault是否改写outcome未冻结。
7. `RunOutcomeEnvelopeV1`缺完整typed SoA、跨平台canonical float64/enum/int ABI与producer manifest。
8. Save callback丢失/超时后的不确定提交、attempt correlation、reconcile与discard tombstone先后竞态未闭合；容量/证据schema也缺可证明上限。

### 用户裁决（完整变更集）

1. 同tick Boss胜利与玩家死亡并发时，`VICTORY`优先。
2. 正常Outcome一旦seal，后续cleanup/Save fault不改写`outcome_kind`，只写独立`completion_fault_code`。
3. Outcome ABI：ID/count/tick/amount为int64，enum为int32；damage totals/candidate值为finite IEEE754 float64 little-endian，`-0`规范化为`+0`，NaN/Infinity拒绝。
4. Save使用attempt generation/request correlation、`SAVE_UNCERTAIN` reconcile与durable discard tombstone；success先于tombstone则成功有效，tombstone先持久化则迟到callback为stale。
5. phase 6 lifecycle每intent一条mutable row，Pool私有release FSM承接reset/free-stack exact-once；gameplay facts进入独立`CommittedGameplayFactLedger`；每个phase end/fault convergence最多一次batch authority copy/publish。
6. Enemy separation correction在tick T phase 5计算，tick T+1 phase 2消费。

### 修订结果

- `game-root-scene-flow.md`：冻结closed enum/guard-aware transition、callback allowlist、Engine 60Hz/time_scale readback、Viewport topology、load failure disposition、phase-6 journal+fact ledger+single batch、normal terminal seal、Outcome ABI、Save reconcile/tombstone及对应AC/evidence schema。
- `config-data-system.md`、registry、technical preferences：同步required phase/service coverage、callback/topology/load manifests、所有runtime carrier上限、Engine全局量和Save/Outcome边界。
- `input-system.md`、`stage-map.md`：同步callback writable set、MANUAL退出安全暂停、resume expected tuple、拓扑冻结与Stage gate不等于全局battle-ready。
- `object-pooling.md`、`spatial-grid.md`、`enemy-system.md`：同步一intent一row、Pool私有release FSM、独立fact ledger、phase-6单batch authority；Enemy改为T→T+1分离修正。
- `systems-index.md`与session state同步；所有受影响设计仍为In Review/Re-review Pending。

### 当前状态

**Re-review Pending**。第六轮8个根blocker已按授权完成静态设计修订，尚未经过第七轮独立full re-review。仓库仍缺完整Godot runtime/project asset、Save integration、target Android和benchmark/evidence artifact；不得标记Approved、implementation-ready、battle-ready或benchmark-ready。

Prior verdict resolved: 第六轮明列8项已落入中央契约与跨文档传播；待第七轮独立复审验证。

---

## Review — 2026-08-31 — Verdict: MAJOR REVISION NEEDED（第七轮收敛性 full re-review）

Scope signal: XL（typed FSM、topology cleanup handoff、phase-6 exact publish、terminal/Outcome/Save ABI）
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, technical-director + creative-director终审
Blocking items: 6个去重根因
Prior verdict: 第六轮 MAJOR REVISION NEEDED，修订后 Re-review Pending

### 闭环审计

第六轮8项经终审裁定为3 CLOSED + 5 PARTIAL：callback/notification、required coverage与Enemy T→T+1已闭合；Viewport topology、phase-6 authority、terminal seal、Outcome ABI、Save活性仍为PARTIAL。runtime/project asset/Save GDD/真机/benchmark缺失继续是OPEN evidence gate，不是本轮MAJOR的原因。

### 6个根 BLOCKING

1. `TransitionKey`只有bool guard且转换表无显式status，无法区分同一PAUSE_REQUESTED下Grid OK/PENDING两个合法target。
2. cleanup在release root Window gate前已detach Host/Shield/VJ/BattleUI，却仍要求按旧BattleViewportTopologyManifest逐字段readback，合法handoff会自报drift。
3. phase 6只要求publish<=1，允许有COMMITTED row仍0 publish；PAUSE_PENDING closure也未绑定锁定前事实provenance。
4. normal-end与fatal同barrier缺总序，sealed cleanup fault无可表达的FINISHED出边，outcome commit ID失败也无终局收敛。
5. Outcome两组SoA重复`damage_totals`，count/enum/completeness/offset/producer rows与DEFEAT死亡原因未冻结为唯一wire ABI。
6. DISCARD_PENDING tombstone timeout/lost callback无retry/reconcile活性；Settlement/Fault TopEvent、Save carrier presence/type/overflow与数值码不完整。

### 用户授权与第七轮修订结果

用户回复“继续”，视为对上一条完整6项变更集的修订授权。已完成：

- `game-root-scene-flow.md`：新增封闭`TransitionGuardId`与显式status表；冻结fatal>normal总序、cleanup FINISHED边、outcome ID failure；拆分Battle topology与CleanupViewportHandoffManifest；phase6新增side-effect前arm plan及visible-row 0/恰1 publish；pause closure绑定锁定前journal/lease；Outcome冻结22 scalar+12 SoA runtime/wire ABI、enum/bit/offset/producer/death cause；Save冻结versioned carrier、presence、retry/reconcile/discard活性与三UI状态self-transition。
- `config-data-system.md`：允许run_seed完整int64含0，只要求battle identity非零；新增PauseDrainClosureTypeManifest/容量、allowed success status与Outcome具体field/bit manifest验证。
- `input-system.md`、`stage-map.md`、technical preferences：统一`topology_revision`字段与cleanup handoff边界。
- `spatial-grid.md`、`object-pooling.md`、`enemy-system.md`：同步Phase6AuthorityBatchPlan与visible committed row exact publish，不改变既有公开API或Enemy T→T+1时序。
- performance/diagnostic追踪项同步为明确sample单位、operation vector、完整counter header与单一饱和flag。

### 当前状态

**Re-review Pending**。第七轮6根BLOCKING已按授权完成静态设计修订，但尚未经过第八轮独立full re-review；未创建SaveSystem/BattleUI GDD，未执行Godot runtime、target Android、Save integration或benchmark/evidence gate。不得标记Approved、implementation-ready、battle_ready或benchmark-ready。

Prior verdict resolved: 第七轮明列6项已落文并传播，待第八轮独立复审验证是否真正收敛。

---

## Review — 2026-08-31 — Verdict: MAJOR REVISION NEEDED（第八轮 full re-review）

Scope signal: XL（六维转换真值、早期Fault totality、cleanup gate、Outcome/Save/capacity与AC oracle）
Specialists: technical-director、performance-analyst + creative-director终审
Blocking items: 8个去重根因
Prior verdict: 第七轮 MAJOR REVISION NEEDED，修订后 Re-review Pending

### Verdict 摘要

第七轮已修复typed guard ID、topology/handoff分段、phase-6 visible-row谓词、terminal总序、Outcome字段冲突与Save discard入口；第八轮继续按完整source tuple与可证伪AC审计，确认这些方向可保留，但发现转换表仍未形成真正六维唯一真值、Config前Fault无carrier、cleanup未保证先持有root Window gate、Enemy验收仍可用`<=1`假通过、Outcome manifest仅声明数量而非实际34行、Save resolved carrier无退休边、容量下界缺owner逐行贡献，以及四组AC缺正例或覆盖不足。Creative Director维持`MAJOR REVISION NEEDED`、scope XL。

### 8个根 BLOCKING

1. canonical transition rows未逐行冻结完整`{top_state,resume_substate,fault_scope,event,guard_id,guard_result}` source/target，guard真值也缺独立oracle。
2. BATTLE_LOADING在Config/Outcome carrier创建前的Fault没有total completion pipeline，可能永远无法expose/退出。
3. ending/fault cleanup未保证detach前取得persistent root Window gate，合法旧input callback仍可能穿过handoff窗口。
4. Enemy phase-6验收只断言copy/publish `<=1`，不能证明visible committed row为0时0 publish、为正时恰1 publish与revision `+1`。
5. `RunOutcomeProducerManifest`只声称22+12行，未给实际canonical 34-row producer/bit/mask/capacity/order；float reduction顺序未冻结。
6. Save仅定义state字段presence，未定义callback result carrier与resolved archive→retire边，新run仍可能被已完成carrier永久阻塞。
7. orchestration required capacity仍来自抽象“owner max”，缺每个required role逐类贡献、exact coverage与checked sum schema。
8. AC-B1/C1/D2/E3及性能workload存在缺positive control、未覆盖全部并发子集、零值fixture或空operation vector的false-pass/false-fail路径。

### 用户授权与第八轮修订结果

用户选择方案A，并明确“按推荐方案全部执行”。已按该范围修订：

- `game-root-scene-flow.md`：冻结完整source/target transition rows、独立`TransitionGuardOracleManifest`及`FAULT_SAFE_EXIT_READY`；新增`OutcomeReadiness`、`PreOutcomeFaultCompletionV1`与Fault exposure total pipeline；cleanup加入`CLEANUP_PRE_ACQUIRE`和`ACQUIRED/REUSED/ACQUIRE_FAILED_SAFE`；实际列出canonical 34-row Outcome producer manifest与float64稳定归并；Save加入`SaveOperationResultV1`、全state presence matrix、`ResolvedRunArchiveV1` archive→retire；新增required owner前三类逐role贡献、Outcome逐SoA field贡献与`RuntimeWorkloadManifest`；重写相关AC positive control/全子集/非零fixture。
- `config-data-system.md`：snapshot/hash/readiness同步独立guard oracle、owner capacity contribution与canonical 34-row Outcome exact-match验证。
- `input-system.md`、`stage-map.md`、technical preferences：同步cleanup gate先取得/复用/安全失败、destination tuple及唯一Home/Prep/Fault/Settlement target；不复制Input私有FSM。
- `enemy-system.md`：phase-6集成验收改为fact-only/lifecycle-only/both/neither和visible row 1/N/capacity，明确0/恰1 publish与revision delta。
- registry、systems-index、session state：同步容量/Save生命周期、Round 8 verdict、Re-review Pending与下一步。

### 当前状态

**Re-review Pending**。第八轮8根blocker已按授权完成静态设计修订，但尚未经过第九轮独立full re-review；未执行Godot runtime、Save integration、project asset、target Android或benchmark evidence。未创建SaveSystem/BattleUI GDD，required owner contribution仍未全部落地，因此不得标记Approved、implementation-ready、battle_ready或benchmark-ready。

Prior verdict resolved: 第八轮明列8项已落入中央契约与受影响文档，待第九轮独立复审验证。

---

## Review — 2026-08-31 — Verdict: MAJOR REVISION NEEDED（第九轮收敛性 full re-review）

Scope signal: XL（oracle可执行性、identity bootstrap、cleanup活性、Save totality、owner authority与evidence workload）
Specialists: game/QA、systems/performance、Godot/technical + creative-director独立终审
Blocking items: 6个去重根因
Prior verdict: 第八轮 MAJOR REVISION NEEDED，修订后 Re-review Pending；第八轮8项复核为3 CLOSED / 5 PARTIAL

### Verdict 摘要

第八轮建立的完整transition tuple、PreOutcome方向、cleanup gate、34-row Outcome、Save carrier与owner contribution骨架均可保留，但仍有六处不能被独立fixture证明或会卡住实际收敛：guard/load oracle没有实际行；Loading/Outcome backing与identity形成自举；cleanup缺持续driver与staged UI激活FSM；Save reducer/retire不是total exact-once；`outcome_kind` producer与owner贡献未闭合；allocation workload把cold/Save误纳入零分配且缺copy expected vector。Creative Director维持`MAJOR REVISION NEEDED`、scope XL。

### 6个根 BLOCKING

1. `TransitionGuardOracleManifest`与load disposition只声明schema/行数，缺canonical input values、稳定顺序和实际row。
2. Loading先需要carrier READY、carrier又依赖Config/identity，终局ID耗尽没有不递归的完成路径。
3. Ending/Fault cleanup缺ALWAYS lifecycle driver、staged noninteractive destination与frame-barrier后激活点；safe failure语义跨文档冲突。
4. Save缺`source_state×operation×durable_result` total reducer、`RECONCILE_NOT_FOUND`语义与可重试archive-retire journal。
5. `outcome_kind`错误归BATTLE_RULES；required owner缺`BLOCKING_CHOICE`及Input/Enemy实际贡献行。
6. runtime workload未区分steady/cold/memory-I/O，cold loading/teardown/Save会被错误要求零分配；authority copy expected counter也未进入manifest。

### 用户授权与第九轮修订结果

用户选择方案A并明确“批准全部执行”。已按授权范围修订10个既有文件：

- `game-root-scene-flow.md`：加入实际35-row guard oracle、24-row load disposition、31-rowpriority golden、TransitionActionOutcome；冻结BOOT unbound backing、OutcomeBindingState/PreOutcome identity-exhaustion收敛；加入ALWAYS lifecycle pump、CleanupSubstate、staged destination与DestinationActivationManifest；补Save total reducer和ArchiveRetireJournalV1；`outcome_kind` producer改GAME_ROOT；加入BLOCKING_CHOICE与12-row workload/class/sample/copy expected契约并重写相关AC。
- `config-data-system.md`：同步实际row/hash、四类owner contribution、唯一backing/READY DAG与workload class验证。
- `input-system.md`、`stage-map.md`：同步lifecycle pump、safe路径inert staged UI、frame barrier/expose/top-state之后才激活；Input补四条0贡献。
- `enemy-system.md`：仅从既有303 active cap和behavior 0..8导出303/303/303/0与9/9实际贡献，无新增调参。
- `technical-preferences.md`、registry、systems-index、session state：同步公共约束与追踪。

### 当前状态

**Re-review Pending**。第九轮6根blocker已按授权完成静态设计修订，但尚未经过第十轮独立full re-review；未执行Godot runtime、Save integration、project asset、target Android或benchmark evidence，未创建SaveSystem/BattleUI GDD，其他required owner贡献仍缺失，因此不得标记Approved、implementation-ready、battle_ready或benchmark-ready。

Prior verdict resolved: 第九轮明列6项已落入中央契约与受影响文档，待第十轮独立复审验证。

---

## 第十轮 full re-review — 2026-08-31

Verdict: **MAJOR REVISION NEEDED**
Scope signal: XL
Specialists: game/UX/UI/economy、systems/QA/performance、Godot/technical + creative-director独立终审
Blocking items: 6个去重根因

### 复审结论

第九轮方向均可保留，但实际可执行性仍存在六个根缺口：guard/load/action oracle不是封闭total表；PreOutcome reservation没有独立恢复载体；cleanup gate失败路径与fallible activation可能失活；Pool closure把一个journal row拆成unbind/release两条导致容量不足；Save缺durable-discard reducer、实际archive schema与partial-retire bitset，且NOT_STARTED玩家面缺失；RW01..12只有名称/类别且RW07/08错误使用physics tick单位。Creative Director维持MAJOR REVISION NEEDED。

### 用户授权与修订结果

用户选择A并明确“批准全部执行”。按批准的11文件范围完成：

- GameRoot：46-row guard oracle、9-row load status normalization、24-row disposition、61-row action outcome；battle ID与terminal commit ID失败分离。
- PreOutcome：独立reservation state/recovery carrier、retry/reconcile self-edge与HOME/Fault CTA。
- Cleanup：ActivationCommitJournal单调checkpoint、lifecycle pump按journal活性驱动、gate固定最多3次重试；连续失败进入`SAFE_TERMINAL_NONINTERACTIVE`并要求重启。
- Pause drain：PDC缩为3行，Pool使用单`FINALIZE_POOL_RELEASE`；容量为owner贡献加GameRoot/Grid两条fixed contribution，schema上限1538。
- Save：新增durable commit already found reducer、实际`ResolvedRunArchiveV1`、expected/retired bitset、archive-entry与carriers-retired guard分离、NOT_STARTED UI。
- Evidence/UX：RW01..12实际向量与sample protocol、RW07/08 control-pump unit、native allowlist hash/marker；所有可交互Control blocked feedback与visible-to-interactive latency。
- Config/Input/Stage/Enemy/Pool/technical preferences/registry/systems-index/session state同步镜像；未修改只读概念源，未创建Save/BattleUI GDD。

### 当前状态

**Re-review Pending**。本轮仅完成静态设计修订与一致性检查，不等于Godot runtime、Save integration、project asset、target Android或benchmark evidence通过；其他required owner贡献仍缺失，`battle_ready=false`。下一步必须在clean context运行第十一轮独立full review。

## Implementation checkpoint — 2026-09-09 — ADR-GR-001 Persistent Root Decision

按执行顺序完成第 1 步：通过 `ADR-GR-001` 固定 GameRoot 采用 `main-scene persistent root`，不采用 Autoload。`run/main_scene` 指向唯一 root scene；页面与 battle 只作为可替换 child scope，root Window/Viewport、pause writer、`gui_disable_input` writer 与 app pump 均保持同一 GameRoot identity。已同步 GameRoot GDD、systems-index 与 architecture registry；OQ1 改为 `DESIGN ANSWERED / IMPLEMENTATION EVIDENCE OPEN`。

当前 vertical slice 的 root 已改名为 `GameRoot` 并继续保留为 scaffold。该决策关闭的是落地方式，不关闭完整 lifecycle、Save、设备、可访问性或性能证据门。

## Implementation checkpoint — 2026-09-09 — Battle Scope Lifecycle Binding

按顺序执行第 2 步：将 `InputSystem`、`VirtualJoystickHost` 与 `BattleUI` 收入 `BattleScope_<generation>` child；GameRoot 保持 root scene、root Viewport 与 live identity 不变。新增 `pause_battle_scope`、`resume_battle_scope`、`replace_battle_scope` 与 `teardown_battle_scope`，replacement 先持有 Viewport gate、teardown 旧 Input/VJ、移除并 queue-free 旧 scope，再创建新 generation 并只通过 `ACTIVATION_SUCCESS` 释放 gate；teardown 则保持 gate held，等待下一页 owner 接管。

GDUnit4 lifecycle suite 覆盖 root/Viewport identity 不变、两次 battle replacement、pause/resume、旧 scope detach、单 VJ 后置与 teardown 后 gate held。首次测试发现并修复了手工拆子节点导致的 28 个 orphan；修复后 suite 为 `4 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`。

这仍是 vertical-slice lifecycle harness，不等价于完整 GameRoot 七 phase、Save、Settlement、Fault 或真实项目 production scene；对应 integration/runtime/device gates 继续 OPEN。

## Implementation checkpoint — 2026-09-09 — Ordered Execution: Device Evidence Boundary

第 3 步已执行能力探测并写入 `production/input-vertical-slice/evidence/input_vertical_slice_check_report.json`：当前环境没有 `adb`，`xcrun simctl` 不可用，设备工具状态为 `BLOCKED`。因此没有执行 Android/iOS 真机或模拟器 touch trace，也没有声称 TalkBack/VoiceOver 或 thermal/performance 证据；本地 Godot/GDUnit4 场景证据继续有效，但不能替代目标设备证据。

当前有序执行结果为：OQ1 设计决策已关闭；vertical-slice GameRoot/BattleUI/Viewport lifecycle harness 已通过；设备、语义可访问性、性能/thermal 以及完整生产集成仍是下一阻塞门。`battle_ready=false` 保持不变。

---
