# SpatialGrid — Design Review Log

审查历史。每次 `/design-review` 后追加一条，供未来 re-review 追踪修订闭环。

---

## Review — 2026-08-19 — Verdict: NEEDS REVISION

**Scope signal**: XL（revision scope M）
**Review depth**: full
**Specialists**: game-designer, systems-designer（超时终止，主审查补做公式边界值检验）, qa-lead, performance-analyst, godot-specialist + creative-director（终审）
**Blocking items**: 8 | **Recommended**: 9 | **Nice-to-have**: 6
**Prior verdict resolved**: First review（仓库此前无 spatial-grid review-log；Status 行"2026-08-19 core-contract short review PASS（5/5）"是上一轮 lean short review，本轮 full depth 复审为首次）

**Summary**: 架构与核心契约成立——RefCounted carrier 冻结、单线程固定 phase 编排、float64 距离原语、PackedArray COW 零分配、状态机 + Paused 三阶段事务经 godot-specialist 核验在 Godot 4.7.1 下可实现（GH-113228 反为正向）。8 项阻塞多为局部补丁，不改公开 API/carrier/查询语义/状态机，故下游 GDD 可基于当前冻结契约并行启动，但本 GDD 须先修订闭环，不得以 NEEDS REVISION 状态被当 Approved 引用。核心分歧裁定：performance-analyst 对 F4 "3.3× 候选收窄"归因错误的指控成立（type_filter 污染 baseline），但"Foundation 不成立"推论不成立——价值须从污染倍率重锚到多查询扇出复合局部性 + type_filter 排除 caller，且须 J0/J4 真机证明。game-designer B-1/B-2（ControlledGameplayFault 体验、CAPACITY_EXCEEDED 幽灵敌人）真属本文档，B-3（tick-end 穿越未命中）defer 到 ProjectileSystem GDD。

### 8 项 BLOCKING

1. **range(out.count) 隐式分配自破零分配契约** [performance-analyst] — AC-B7 消费侧示例代码用 `range()` 即每 query 分配新 PackedInt32Array，positive control 无法捕获。
2. **CAPACITY_EXCEEDED 调用方义务未定 → 幽灵敌人** [game-designer] — 容量满时 SpawnDirector 处理未定，可能生成可见不可索引实体。Section B 缺第三类失败（内容抑制）。
3. **instance_id 可回收致 active handle 误 resolve** [godot-specialist] — owner 违反 remove-before-free 且 id 回收时 is_instance_valid 为 true 却返回错误对象。评估改用 WeakRef。
4. **F4 "3.3× 候选收窄"归因错误** [performance-analyst] — 300 vs 1003 是 type_filter 污染；公平比较 ENEMY-only 遍历 ≈1.0×。与 J 组 EVIDENCE ONLY 矛盾。删除倍率，重锚复合局部性。
5. **Edge Case 覆盖矩阵漏 EC28（声称 27/27 实为 28）** [qa-lead] — EC28（fatal failure→ControlledGameplayFault 不降级空集合）无 AC 映射，核对规则谎称 27/27。
6. **Section B ownership 边界：ControlledGameplayFault 玩家体验未规格化** [game-designer] — fantasy 级承诺甩给 Draft 文档，未抬到硬依赖。
7. **F5/OQ7 无 GDScript 成本 baseline 估算** [performance-analyst] — 粗估 400 投射物 swept×300 候选=120k 距离/frame≈6-18ms 逼近整帧预算；"5-30μs/query"过乐观。spike 前先做桌面 microbench。
8. **AC-J5 措辞含糊可能把确定性不变量降级为 advisory** [qa-lead] — staging_writes=A_stage_success 等纯逻辑不变量须始终 BLOCKING，仅 +K 容差与 K=8 本身 EVIDENCE ONLY。

### Recommended（9 项，非阻塞）

- AC-J3b production query count 低估、缺 Σ candidates_tested 聚合 gate、trace 未要求含聚集工况 [performance-analyst]
- F3 sweep fixture 未冻结聚集工况 + p99 estimator 无方法论 gate [performance-analyst]
- AC-J2 子预算无上界绑定 AC-J1 整帧预算 [qa-lead]
- AC-G4/H5/H7/J6/K5 补 "on downstream integration" gate [qa-lead]
- R10 tick-end 穿越未命中 defer 到 ProjectileSystem 作"已知 feel 妥协" [game-designer → CD 裁定]
- R9 status precedence 缺独立表驱动 AC [qa-lead]
- godot 契约显式化：checked increment 无语言级支持、generation 字段宽度、begin/end 独占无编译期保证、GameRoot 禁 @tool、resolve 流程顺序、query-consume 禁 await [godot-specialist]
- index_margin=cell_size=2.0 边界格密度峰未量化 [performance-analyst]
- R5 nearest 无 hysteresis 致索敌抖动 [game-designer]

### Nice-to-have（6 项）

- AC-K2 API 表面 AST 断言自动化 [qa-lead]
- AC-A1/A4 "ADR review" 从 gate 拆出 [qa-lead]
- F2 澄清"位置 float32 / 距离 float64"分层 [godot-specialist]
- R9 暂停措辞改"4.x process_mode"（4.7 无 SceneTree pause 变更）[godot-specialist]
- 补 4.7 GABE GDExtension ABI 矩阵成本 [godot-specialist]
- Status 行汇总"J0 OPEN → J1–J6 全部 EVIDENCE ONLY/不可判定" [performance-analyst]

### 处理决定

本轮不修订，记录到 `production/session-state/active.md`，在新会话（/clear 后）用干净 context 修订。systems-index 已同步 SpatialGrid 状态为 NEEDS REVISION。

---

## 修订闭环 — 2026-08-19

8 项 BLOCKING 已全部写入 `spatial-grid.md`（文件 mtime 17:57 晚于本 log 17:44，修订在上方"处理决定"记录之后执行，active.md/review-log 此前"待修订"为 stale 文本，本轮已同步）。逐项核对证据（行号以修订后文档为准）：

- **① range 隐式分配**：R4 L56 禁 `range()`/`slice()`/复制成新 Array，强制 `while i < out.count`；AC-B7 L659 positive control 要求观测 range-allocation delta>0；AC-J3 positive control A 同步。
- **② CAPACITY_EXCEEDED 幽灵敌人**：Player Fantasy L21 补第三类失败（内容准入/幽灵敌人）；R9 L97 admission check + Elite/Boss 预留 3 槽 + 返池协议；依赖表 L474 SpawnDirector「保证 active ENEMY≤303」；AC-E11 负向故障注入。
- **③ instance_id 回收**：R6 L72 显式声明 instance_id 可回收 + 直接 Node identity 引用不延长生命周期；L76 remove-before-free 升 BLOCKING 义务；AC-E7 L769 负向 fixture（forced instance-ID reuse）；**WeakRef 评估本轮补齐**（R6 L72 直接持有等价弱引用语义、无额外安全收益、不采用）。
- **④ F4 归因**：F4 L322 删除"3.3×"倍率，重锚"多查询扇出复合局部性 + type_filter 排除 caller"，明确公平基线为 ENEMY-only、中心聚集约 1.0×，标 EVIDENCE ONLY；AC-J4 L960 三基线（Grid/ENEMY-only/all-object）对照。
- **⑤ EC 矩阵**：L1049-1078 共 28 行，EC28→AC-G4/AC-K5；L1080 核对规则声明 28/28。
- **⑥ ControlledGameplayFault 体验**：R9 L99 玩家可见行为契约（冻结 input/AI/spawn、显示故障 UI、TECHNICAL_ABORT、无奖励 cleanup）；L464/L483 列为 SpatialGrid→game-root 硬依赖。
- **⑦ GDScript 成本 baseline**：F5 L368-379 成本常数表（Dictionary/PackedArray/identity/float64 sqrt 等 6 类）+ 未实测 planning bracket；AC-J0a L922 桌面 release microbench 前置 gate。
- **⑧ AC-J5 措辞**：AC-J5 L965-971 三段拆分——确定性逐项不变量始终 BLOCKING、query counter 不变量始终 BLOCKING、`+K` 与 `K=8` 为 EVIDENCE ONLY。

**结论**：7 项上一会话已闭环，③ WeakRef 评估本轮补齐。修订不改公开 API/carrier/查询语义/状态机。待重跑 `/design-review design/gdd/spatial-grid.md --depth full` 验证；复审通过后标 Approved 并同步 systems-index。

---

## Review — 2026-08-19 — Verdict: APPROVED

**Scope signal**: S（4 项措辞/追溯小改，零结构/零公式/零 AC 行为变更）
**Review depth**: full
**Specialists**: performance-analyst, game-designer, godot-specialist, qa-lead, systems-designer + creative-director（终审）
**Blocking items**: 0 | **Recommended**: 4（同批修订）+ 3（defer） | **Nice-to-have**: 11
**Prior verdict resolved**: Yes — 第三轮 NEEDS REVISION 的 8 项 BLOCKING 全部 CLOSED

**Summary**: 8 项 BLOCKING 全部闭环（①range 三层设防、②幽灵敌人 admission+预留+返池无残留、③WeakRef 评估段落补到位且 4.7.1 论断准确、④F4 归因 1.0× 数学正确公平基线 303 ENEMY-only、⑤EC 矩阵 28/28、⑥ControlledGameplayFault 硬依赖+文案符合韩立气质、⑦6 类 primitive 成本表+AC-J0a 前置 gate、⑧AC-J5 三段拆分无歧义）。核心契约（RefCounted carrier、单线程 phase 编排、float64 距离原语、Paused 三阶段事务、幽灵敌人抑制）在 Godot 4.7.1 下可成立且未改公开语义，下游 GDD 可基于当前冻结契约并行启动。creative-director 终审 APPROVED。

### 标 Approved 前一并修订的 4 项小改（本轮已写入）

- **R-A** [perf] F5 L379 "6-18ms 保守 bracket" 改为"乐观下界/风险下界"，补双层低估说明（只算 projectile×enemy 的 C_distance 项，未含其他 consumer 与 C_read/C_filter/C_lookup/C_write 项，真实可达 1.5-3×），禁止据此判 query 子预算有余量。
- **R-B** [qa] AC-E11（BLOCKING 级行为）原在 EC 矩阵与核对表双悬空 → 新增 EC29「容量满普通怪 spawn 抑制 / Boss 预留不可用 → 不产生幽灵实体」并映射 AC-E11；EC 节同步加 EC29，矩阵计数 28→29/29。
- **R-C** [qa] 覆盖核对表 R4 行补 AC-B0/AC-B4b，R6 行补 AC-E11（AC-E1~E10 → E1~E11）。
- **R-D** [game] 依赖表 L474 SpawnDirector "仅 insert success 后 publish" 改为"仅 insert 返回 OK 且后续 sync 成功发布后才接入可见 SceneTree/active collection（实际 publish 在 DEFERRED_REMOVAL authority bundle commit）"，防跳过 sync 直接 publish 的 ghost 风险。

### defer 的 Recommended（实现期/下一轮 lean follow-up）

- R9 status precedence 6 层独立表驱动 AC（现由 AC-E10/H2/G3 隐式覆盖）
- godot 契约显式化（GameRoot 禁 @tool / checked increment 无语言级支持 / query-consume 禁 await / generation 字段宽度 / GH-113228 正向依赖说明）
- AC-J3b 补 Σ candidates_tested 聚合 gate；F3 sweep 补聚集 fixture + p99 方法论
- 其余 11 项 Nice-to-have（见各 specialist 报告）

**处理决定**：4 项小改已全部写入 `spatial-grid.md`，文档 status 行已更新为 Approved；`systems-index.md` SpatialGrid 状态 NEEDS REVISION→Approved，progress tracker reviewed 1→2/approved 1→2。J0/J1/J2/J4 真机性能 gate 仍 OPEN（用户暂无 min-spec 真机），仅标记为 deferred evidence，不影响设计冻结。
