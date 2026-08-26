# EnemySystem GDD — Review Log

## Review — 2026-08-25 — Verdict: MAJOR REVISION NEEDED
Scope signal: L
Specialists: game-designer, systems-designer, ai-programmer, performance-analyst, godot-specialist (gdscript), creative-director (synthesis)
Blocking items: 14 | Recommended: F0/F2/F3/R-GS cluster
Summary: 核心机制稳健（池化分离、FSM 驱动精英、数据驱动 behavior_id、GameRoot 7-phase participant）；问题集中在规范/引用/执行/可测量性——尖峰参数矛盾、分离架构对称重复、阶段上限数学错误、零分配契约不可测、AC 门状态非标准、悬空引用。
Prior verdict resolved: First review

## Revision — 2026-08-25 — 14 阻塞项 + F0/F2/F3/R-GS 全部应用（本轮，同会话）

| ID | 拦截器 | 修复位置 |
|---|---|---|
| R1 | 分离算法架构（对称操作 2× 开销） | §3.8 步骤2 / §4.2 — CD 选项 B 变体 `handle≤self` 内联配对去重，写双方，45,753 对操作上限 |
| R2 | 精英 spike 参数矛盾（§3.6 vs §7.3） | §3.6.1/§3.6.2/§7.3 — §7.3 为权威，统一参数名，删 `summon_period_seconds` 死参 |
| R3 | 零分配契约不可测 | AC-E4 — 堆增量→Object Pooling F4 四计数器 + AC-F3 正向控制 |
| R4 | 鬼雾修士 FAN_NEEDLE 退出谓词未定义 | §3.6.2 FSM — 退出=`fan_needle_duration` 计时阈值 |
| R5 | CHARGE 死锁（无 arena 出口）+ 负阶段 | §3.6.1 `arena_boundary_clamp` 触发器 / §4.3 `stage=Max(0,floor(...))` |
| R6 | 尖峰参数与 FAN_NEEDLE 退出耦合 | §3.6.1/§4.6 — 配置就绪门 + overshoot 说明 |
| R7 | set_deferred 禁令理由错误 | §3.4 — 理由改"状态同步正确性"，删"预热摊销"矛盾 |
| R8 | SpatialGrid 禁全量扫描 | AC-E8/E13/E18/E19/E20/E25/E26/E30a — 字面 `rg --glob '*.gd'` + 命中计数断言 |
| R9 | 零分配测量缺失 | AC-E4 — 四计数器 + 正向控制 |
| R10 | 计时子预算不可测 | AC-E2 拆 a(复杂度回归)/b(计时子预算，ADVISORY→发布门) |
| R11 | 死亡载荷存储布局（append 装箱） | §3.11 — SoA 并行 PackedArray，write-index 非 append；AC-E22a 断言 |
| R12 | 阶段倍率上限数学错误 | §7.2 — health 阶段12封顶，damage 阶段13封顶 |
| R13 | 分离收敛性过度承诺 | §3.8/§4.2 — 降级单调+f(簇直径)；`deterministic_axis` 哈希公式；clamp 不变量异常声明 |
| R14 | PLAYER type_mask 误用 | §3.12 — 玩家=查询中心，ENEMY=过滤器；Boss 长形形状圆形查询注意 |
| — | LOD 移除争议（CD 裁定 PA 担忧成立） | §5.12 — 新增"性能压力优雅降级逃逸阀"4 步阶梯（非恢复旧版 LOD） |
| F0 | AC 门状态非标准（OPEN-gate/条件性） | §8 头部 + AC-E2b/E35 — 统一 ADVISORY + 发布门 |
| F2 | 悬空引用 | AC-E3/E29 + §9.1/§9.2/§9.3 修复 |
| F3 | AC 测量性不足 | AC-E10a/b、AC-E11b、AC-E33(a/b/c/d) |
| R-GS R1 | AnimationPlayer `active` 切换不成立 | §3.4 — 改"信号 warmup 期断开 + FSM 计时器轮询" |
| R-GS R7 | "Array.clear() boxes" 措辞错误 | §3.4 — "clear() 不 box；untyped 元素写/append 才 box" |

systems-index 状态：Draft → In Review（待重审）。

## Review — 2026-08-25（第二轮 full 复审）— Verdict: NEEDS REVISION (MAJOR)
Scope signal: L
Specialists: game-designer, systems-designer, ai-programmer, performance-analyst, godot-specialist, qa-lead, creative-director (synthesis)
Prior verdict resolved: 部分确认（首轮 14 项 + F0/F2/F3/R-GS 修订成立），新发现批次化 BLOCKING
Summary: 上轮修订主体成立；新问题集中在 spike-gated 冻结范围、escape valve 诚实性、收敛复杂度契约过度承诺、FSM 可编码性补全、零分配代码审计方法论、公式/AC 边界一致性、Player Fantasy 措辞。CD 裁定拆分冻结（行为契约冻结 / 性能 AC spike-gated 未冻结），用户批准 6 批次修订 + 4 项战略决策。

## Revision — 2026-08-25（第二轮，6 批次全部写入）

### 批次1 性能 spike-gating + escape valve 诚实化
| 修订 | 位置 |
|---|---|
| §1 头部状态行 | IN REVISION + 拆分冻结声明（行为契约冻结 / 性能 AC spike-gated 未冻结） |
| §5.12 escape valve | 档1 诚实化为"分离域 distance-LOD"（新 LOD 非 sim-LOD）+ 公平性 trade-off + 残留 overlap 上限守卫 + best-effort 非保证兜底 |
| AC-E1 | 改 spike-gated + max-clustering 子窗口 + P99 ≤ 50ms 防长尾 |
| AC-E2b | 量级警告 100-1000× 非 10-30× + spike-gated 未冻结 + 拆分冻结 |
| §10 OQ1 | 补 Node2D transform commit 成本声明 |
| §10 OQ9（新）| GDScript 可行性 spike 作性能 AC release-gate 升级前置门 |

### 批次2 收敛与复杂度契约重写
| 修订 | 位置 |
|---|---|
| AC-E2a | 重写为确定性操作计数（非耗时）+ 拆 avg-散布(O(N))/max-全聚集(≤45,753,不退化 91,606) + 删耗时回归 |
| AC-E10a | 重写为分段契约 (a)基线单调非增 (b)clamp 全局有界非增 (c)BLINK 帧瞬时增加后收敛 ≤frames_to_epsilon≈68 帧 (d)降级有界残留 |
| AC-E10b | 断言时序拆分（帧1 correction_dir==deterministic_axis / 帧3 distance>0）+ 参数序 h_a<h_b |
| AC-E31 | BLINK 帧语义对齐 AC-E10a(c) |
| §4.2 | clamp 不变量加 AC-E10a(b) 交叉引用 + deterministic_axis 补 GDScript `^`+显式括号+参数序（F-2） |

### 批次3 FSM 可编码性补全
| 修订 | 位置 |
|---|---|
| B1 CHARGE 敌群分离反推死锁 | §3.6.1 — 分离修正仅作用垂直分量 / 投影单调不减阈值守卫；AC-E30b 补敌群场景 |
| B2 BLINK angle 自相矛盾 | §3.6.2 — angle 固定整个 borrow + clamp-collision 同 angle 下周期重试（删"换 angle"） |
| B3 甲壳妖虫 stop/resume | §3.2/§7.4 — normal 桶 + stop_distance/resume_distance 两参 + mini-FSM CHASING/ATTACKING；新增 AC-E30d |
| B4 血傀儡自爆不可跳过 | §3.12/§7.4 — health 跨 30% 阈值即 latch 预警（非停留判定）+ 预警期被击杀仍播自爆 VFX |

### 批次4 零分配 + 代码审计 AC 方法论
| 修订 | 位置 |
|---|---|
| §9.2/§9.4 | emit_signal→staging latch（零分配） |
| AC-E13 | 删空体漏洞 + process_callback→callback_mode_process（4.7）+ 禁定义 _physics_process/_process |
| AC-E18 | regex 具体化（列 per-behavior 类名）+ 文件数 ≤3（基类族） |
| AC-E19 | 注释免疫声明 + dispatch 声明（FSM 数据表不计） |
| AC-E37（新）| GH-115763 typed-return override 须显式 return 守卫 |
| AC-E4-code（新）| 零分配静态守卫正则集（emit_signal/set_deferred/call/get_children） |
| technical-preferences.md | Forbidden Patterns 加稳态禁令 + Allowed Libraries 加 gdtoolkit(gdlint) |

### 批次5 公式/AC 边界一致性
| 修订 | 位置 |
|---|---|
| F-1 | §4.7 index_margin_min 公式取 max(enemy_overshoot_max, elite_charge_overshoot) |
| F-2 | §4.2 deterministic_axis 参数序 h_a<h_b（批次2 已处理） |
| F-3 | AC-E33(d) 改明指封顶点 stage=12 |
| F-5 | §4.1 last_known_direction 初始化 + 非零帧更新语义 |
| F-6 | §4.2 不变量记号 Vector2 类型修正（等大反向+投影长度和） |
| F-7 | §3.10 QUERY_CONSUME 措辞统一（下帧 MOVEMENT_COMMIT 叠加） |
| F-9 | 新增 AC-E11c pair-once 去重守卫 |
| F-11 | §3.11 write-index reset 语义 + 消费者每帧全量读契约 |

### 批次6 Player Fantasy 措辞
| 修订 | 位置 |
|---|---|
| M/B-F3 | §2 改"5 种鲜明剪影 + 1 种基线参照(噬灵虫)" |
| R-F13 | §4.3 删 advisory "cap 可设 3.5 左右"（与 §7.2 冻结 3.0 矛盾） |

systems-index 状态：In Review（待第三轮重审）。

## 待办（下一会话）— ✅ 已执行（2026-08-25 第三轮复审，本会话）
- ~~ /clear 后新会话运行 `/design-review enemy-system`（--depth full）验证第二轮 6 批次修订是否真正成立 ~~ → 已执行，第二轮 B1-B6 全部成立无回归
- ~~ 重审 Phase 1 读本 log 跟踪第二轮 6 批次修复 ~~ → 已执行

## Review — 2026-08-25（第三轮 full 复审）— Verdict: NEEDS REVISION (MAJOR)
Scope signal: L
Specialists: game-designer, systems-designer, ai-programmer, performance-analyst, godot-specialist, qa-lead, creative-director (synthesis)
Prior verdict resolved: 第二轮 6 批次（B1-B6）修订经 6 specialist 独立对抗性核实全部成立，无回归
Summary: 第二轮修订主体稳固；本轮新发现 9 项 BLOCKING + IC-1 措辞澄清 + 4 项 RECOMMENDED（AI-3/4/5/6），全为 spec/citation/传播/testability/归属 修复非重设计（零新公式/零新 ADR/零设计意图变更）。CD 合并 13 项确认 BLOCKING → 9 项根因。2 项分歧（IC-1/IC-2）CD 裁决：IC-1 → RECOMMENDED（措辞矛盾不影响数值）；IC-2 → BLOCKING（文档一致性，裁定块"本帧"权威 vs stale"下帧"措辞，并入 B-9）。

| ID | 根因 | 修复位置 |
|---|---|---|
| B-1 | 跨文档传播回归（F-1 max 形式未传 stage-map/spatial-grid/registry；CD-2 query_radius separation 项 sep+bound 与 enemy §4.2 sep+max_sep 矛盾） | stage-map F5 公式+变量表 / spatial-grid G2b+G3 / registry index_margin_lower_bound+max_query_radius expression（owner 文档 8 处传播） |
| B-2 | Config 虚引（§4.7 R6 称 elite_charge≤剩余 margin 为 Config build_snapshot blocking 校验，config 无此校验） | §4.7 R6 — 虚引降 advisory，实引 index_margin≥index_margin_min 保留指向 stage-map R5 |
| B-3 | IC-3 CHARGE 双实现（B1 fix 同时保留"仅垂直分量"+"投影单调不减阈值守卫"两 canonical） | §3.6.1 — 删投影守卫，canonical=仅垂直分量 |
| B-4 | normal 桶 mini-FSM 系统性缺失（B3 fix 只补甲壳妖虫 1/5，其余 4 无状态表/参数/AC）+ 状态存储/驱动归属悬空 | §3.4 carrier 加 mini_fsm_state 字段 / §3.6 normal 桶 driver 注 / §7.4 补 4 套状态表+参数 / §8.11 新增 AC-E30e/f/g/h |
| B-5 | 血傀儡自爆伤害归属未声明（B4 fix 只补预警 latch，未提伤害归 Combat） | §3.12 — 自爆伤害归 Combat/DamageSystem，EnemySystem 只 latch self-destruct intent，payload {borrow_id,behavior_id=5,self_destruct_position,radius,spawn_seed} |
| B-6 | AC-E4 守卫体系（positive control Dictionary 对照不可靠 + 四计数器语义未定义 + AC-E4-code regex 未覆盖全禁令） | AC-E4 — positive control 改注入匹配 pool 级守卫已知分配源 + 四计数器语义 + 守卫范围声明 / AC-E4-code regex 扩 13+ 禁令 |
| B-7 | AC-E10a(c) frames_to_epsilon 作精确值（§4.2 已降级非定值 3，frames_to_epsilon 仍 spike 精确） | AC-E10a(c) — 改 advisory spike ~68 帧，精确 defer OQ9 |
| B-8 | AC-E19 软 gate（裸 rg 守卫不可靠，FSM 数据表/注释免疫未声明） | AC-E19 — 改 typed carrier 静态断言 + gdlint AST 规则（裸 rg 仅候选定位） |
| B-9 | IC-2 时序 stale（§3.8 step3/§3.10/§10 OQ4 仍"下帧 MOVEMENT_COMMIT"，与裁定块"本帧"矛盾；OQ4 "≤3 帧"stale） | §3.8 step3 / §3.10 / §10 OQ4 — "下帧"→"本帧"，删"≤3 帧"stale |
| IC-1 | §4.2 L485 "不二次规范化"措辞与 known-answer 矛盾（XOR 非对称 vs 规范化序） | §4.2 — 加术语澄清"规范化指 from_angle 输出单位向量 vs 参数序" + known-answer 断言加固 |
| AI-3 | SUMMON_BLOOD_PUPPET 0 tick 瞬时语义未显式 | §3.6.2 L284 + §10 OQ10 — 显式确认 latch 即进 TRACK |
| AI-4 | blink_offset_radius 是否 seed 派生未明 | §3.6.2 L290 + §10 OQ11 — 建议 seed 派生 radius |
| AI-5 | 精英技能 latch 与 Combat pull 同 phase 顺序未裁定 | §10 OQ12 — 建议 latch-before-pull 顺序 |
| AI-6 | Boss 阶段切换节拍点语义 + 属性生效帧时机未定义 | §5.6 + §10 OQ13 — defer #18 |

## Revision — 2026-08-25（第三轮，9 BLOCKING + IC-1 + 4 RECOMMENDED 全部本轮闭环写入）
- **enemy-system.md 17 处修订**：§3 状态行 / §3.2 B3 fix 注 / §3.4 carrier mini_fsm_state / §3.6 normal 桶 driver 注 / §3.6.1 B1 fix 删投影守卫 / §3.6.2 AI-3/AI-4 注 / §3.8 step3 B-9 / §3.10 B-9 / §3.12 B-5 自爆归属 / §4.2 IC-1 术语澄清 / §4.7 R6 B-2 虚引降 advisory / §5.6 AI-6 节拍点 defer / §7.4 B-4 四套状态表+参数 / §8 AC-E4 B-6 / §8 AC-E4-code B-6 regex / §8.11 AC-E30e/f/g/h B-4 / §10 OQ4 B-9 + OQ10-13 AI-3/4/5/6
- **owner 文档 B-1 传播 8 处**：stage-map.md F5 公式 max 形式 + 变量表（elite_charge_overshoot 行）；spatial-grid.md G2b L524+L527 引用 + G3 L262+L533 separation 项；registry entities.yaml index_margin_lower_bound expression+variables+notes + max_query_radius expression
- systems-index 状态：In Review（待用户验收/四审）。

### 跨文档传播检查清单（CD 盲区2 建议，第三轮复审登记）
本轮 B-1 暴露流程问题：enemy §4.7 F-1 max 形式修订（第二轮）未传播到 owner 文档（stage-map/spatial-grid/registry），第三轮才发现。为防第四轮复审再犯，登记检查清单：
- 任何跨系统数值公式修订（owner 公式表达式变更），须同步传播到：① registry entities.yaml source expression + variables + notes；② 消费者 GDD 引用该公式的文本；③ spatial-grid 等下游派生公式。
- design-review 阶段 3 一致性检查须 grep 跨文档同公式（如 `checked_add(player_overshoot` / `checked_add(separation_radius`）确认所有引用点形式一致。
- 本轮 B-1 已传播闭合：stage-map F5 / spatial-grid G2b+G3 / registry index_margin_lower_bound + max_query_radius 共 8 处。

## Review — 2026-08-25（第四轮 full 复审 R4）— Verdict: NEEDS REVISION
Scope signal: M（小于 R3 的 L）
Specialists: game-designer, systems-designer, ai-programmer, performance-analyst, godot-gdscript-specialist, qa-lead, creative-director (synthesis)
Prior verdict resolved: R3 的 9 BLOCKING（B-1..B-9）+ IC-1 + AI-3/4/5/6 经 R4 核实全部本轮闭环写入、无回归
Summary: R3 修订稳固无回归；本轮新发现 5 项 BLOCKING 根因 + G 陈旧残留，全为 spec/citation/testability/implementability 修复非重设计（零新公式/零新 ADR/零设计意图变更）。CD 合并 ~10 项发现 → 5 根因。2 项分歧 CD 裁决：A（gdlint-AST 工具链存在性）qa-lead=BLOCKING 实测证据 vs gdscript=RECOMMENDED → **BLOCKING**（虚假覆盖比无覆盖更糟）；G（§4.1 L478 stale"下帧"）ai-programmer=BLOCKING vs systems-designer=RECOMMENDED → **RECOMMENDED**（规范裁定块在同节上方 10 行，低歧义残留，本轮一并修）。performance-analyst 判 0 BLOCKING（split-freeze 诚实）——CD 予以正确限定：性能维度确实无阻塞，但可测性/可实现性/跨文档一致性维度有设计阻塞，范围不同无矛盾。

| 根因 | 描述 | 来源 | 修复位置 |
|---|---|---|---|
| 根因1 | 静态守卫 AC 方法论不可测：gdlint 无自定义规则/插件 API（qa-lead 实测 gdtoolkit 4.5. 确认），AC-E19(3)/E37/E4-code 引用虚构 gdlint-AST gate；AC-E4-code 正则缺 `.emit(`/`Callable(`/`String(` 等 + 人工 carve-out 非确定性 CI gate + 无 positive control | qa-lead BL-1/BL-2/BL-3 + gdscript R-6/B-GS-1 | enemy AC-E4-code 重写为主门控 `tools/ci/static_guard_check.py`（gdtoolkit.parser AST 脚本，已验证可导入可解析）+ 正则补齐 + 移除人工 carve-out + positive control；AC-E19(3)/E37/E13/E4 改引用；technical-preferences.md L59 修正错误主张 |
| 根因2 | §4.2 pair-once 伪代码不可实现：`b.correction -= push` 中 b 是 int 句柄（spatial-grid R4 PackedInt64Array handle_ids）非 carrier 引用；句柄→载体解析未文档化；clamp 在 per-enemy 循环内致顺序竞态；成本漏计 ~45,753 次 resolve_active_into | ai-programmer B-10 | §4.2 伪代码重写：声明 BATTLE_LOADING 预分配 handle→carrier 解析（spatial-grid R6 resolve_active_into）+ 拆 ACCUMULATE（配对写双方累加不 clamp）/ COMMIT（全累加后统一 clamp）两子步消除竞态；§3.4 载体加 `separation_correction` 字段；§3.8 补 resolve 调用入 AC-E2b 子预算 |
| 根因3 | 跨文档 separation query_radius 形式不一致：spatial-grid L133/159/252/273/474 用 `sep+max_enemy_bound`（shape bound，与 sep_radius 独立 per-type），与 enemy §4.2 权威形式 `sep+max_separation_radius` 矛盾（R3 B-1-R 仅标 L133/159/474 三处，R4 验证 grep 另发现 L252 effective_hot_query_radii 聚合 + L273 调谐表两处残留，共 5 处） | systems-designer B-1-R（B-1 残留） | spatial-grid L133/159/252/273/474 同步为 `sep_radius+max_separation_radius`；G3/registry separation 项经核实为正确全局上界（2×max_sep=max-sep 敌人的 §4.2 形式），不改仅加澄清注；enemy AC-E8 关闭"须同步"项 |
| 根因4 | B-4 mini-FSM 不完整：载体表只加 `mini_fsm_state` 无 timer/counter 字段（FSM 谓词依赖计时器/charge_count 无处存）；铁背妖狼 FSM CHARGE 行 `charge_count++` 是蜈蚣模板复制残留（狼 §7.4 spike 无 charge_count，单冲锋）+ CHARGE/RECOVER 双出口无区分谓词 | ai-programmer B-11 + game-designer B-GD-1 | §3.4 载体加 `mini_fsm_phase_timer`/`mini_fsm_counter` 字段；§3.6 L222 声明 timer 存 `mini_fsm_phase_timer`；§7.4 狼 CHARGE 行删 charge_count、单冲锋直接 RECOVER；AC-E30e 删"charge_count 累加" |
| 根因5 | 血傀儡 FSM 触发跨阶段机制未声明：FSM 驱动 MOVEMENT_COMMIT vs take_damage 跨越检测 DEFERRED_REMOVAL（更晚 phase），1 帧延迟未声明；§3.12 L433 与 §7.4 L897 双 latch 歧义 | ai-programmer B-12 | §3.12 声明：take_damage 设 `mini_fsm_event_flag`（权威 latch 点）+ latch 预警 VFX intent，FSM 下帧 MOVEMENT_COMMIT 轮询消费触发迁移，1-tick 跨相延迟（类击退）；§7.4 L897 CHASING 行改为轮询 flag 不二次 latch；§3.4 载体加 `mini_fsm_event_flag` 字段 |
| G | §4.1 L478 变量列表注 stale"下帧生效语义"，与同节 L468 规范裁定块"本帧"矛盾（B-9 残留） | ai-programmer B-13 / systems-designer R-1 | §4.1 L478"下帧"→"本帧" |

### 决策（AskUserQuestion）
- 根因1 门控替换：用户选 **自定义 CI AST 脚本**（tools/ci/static_guard_check.py，gdtoolkit.parser）+ 运行时零分配（已有）双重门控。gdtoolkit.parser 经实测验证可独立导入（`from gdtoolkit.parser import parser` → `parser.parse(src)` 返回 Lark Tree，`standalone_call` 节点可遍历区分注释/字符串/调用），区别于 gdlint 不存在的插件 API。

### 修订写入（R4，5 根因 + G 全部本轮闭环）
- **enemy-system.md**：L3 状态头 / AC-E4-code 重写 / AC-E19(3) / AC-E37 / AC-E13 / AC-E4 / AC-E8 / §4.2 伪代码重写 / §3.4 载体字段补齐（separation_correction + mini_fsm_phase_timer + mini_fsm_counter + mini_fsm_event_flag）/ §3.6 L222 timer 存储 / §3.12 跨阶段机制+双 latch / §7.4 狼 FSM 表 + 血傀儡 CHASING 行 / §3.8 resolve 成本注 / §4.1 G / AC-E30e
- **technical-preferences.md**：L59-62 gdlint 错误主张修正
- **spatial-grid.md**：L133/159/252/273/474 query_radius 同步 + G3 separation 项澄清注
- systems-index 状态：In Review（待用户验收/五审）。

### 验收（2026-08-25）：APPROVED

用户验收 R4 修订通过，EnemySystem 标 Approved。

- R3 的 9 项（B-1..B-9）+ IC-1 + AI-3/4/5/6 经 R4 核实全部闭环无回归。
- R4 5 根因（静态守卫 AC 方法论 / pair-once 伪代码可实现性 / 跨文档 query_radius 形式 / mini-FSM 载体字段 / 血傀儡跨阶段触发机制）+ G 陈旧残留全部闭环。
- R4 最终验证 grep 另补修 3 处残留（AC-E19 引言行 L1136 gdlint / spatial-grid L252+L273 separation_radius+max_enemy_bound）；B-1 残留实为 spatial-grid 5 处（L133/159/252/273/474）而非 R3 标注的 3 处——跨文档传播检查清单此次又漏 2 处，已补入根因3 行。
- 零新公式 / 零新 ADR / 零设计意图变更。拆分冻结：行为契约冻结 / 性能 AC（AC-E1/E2b）spike-gated 未冻结。
- systems-index：EnemySystem In Review→Approved；reviewed 仍 7、approved 4→5。

### RECOMMENDED（非阻塞，本轮登记未写入）
- performance-analyst R-PA-1/2/3/6：量级估算偏乐观（全聚集 ~3× 高估、QUERY phase 成本未估、P99 不覆盖峰值帧、指令数偏低 ~30-45 非 20-30）。结论（GDScript 难撑 60fps）在所有修正下不变；OQ9 spike 应基于非乐观估算规划。已记为量级警示，归 OQ9 spike 前置输入。
- 其余 gdscript/qa-lead RECOMMENDED（AC-E13 func 审计缺 regex 细节、callback_mode_process 弃用未验证、AC-E18 CharMarionette 不映射等）登记 review-log，实现期处理。
