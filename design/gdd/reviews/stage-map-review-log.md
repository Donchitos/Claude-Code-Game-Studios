# Design Review Log — Stage & Map（stage-map.md）

> 修订历史。每次 /design-review 后追加一条，供未来复审追溯"什么变了"。

---

## Review — 2026-08-19 — Verdict: APPROVED（修订闭环后接受）

**复审轮次**：第二轮 full review（第一轮判 NEEDS REVISION，8 项 BLOCKING 已修订闭环）
**Scope signal**: S（小修）
**Specialists**: game-designer / systems-designer / level-designer / performance-analyst / godot-specialist / qa-lead（6 并行对抗性）+ creative-director 终审
**Blocking items**: 1（AC-C3 缺 y 轴越界 fixture）| **Recommended**: 25+（本轮修订 8 项，余 defer）

### Summary

上轮 8 项 BLOCKING 经多专家独立几何重算确认已真正闭环（F3/F4/F6 算术全对、R6 GH-113228 误引修正站得住、4.7 破坏性变更无遗漏、registry 已同步）。本轮新发现经 creative-director 裁定：5 项 BLOCKING 中维持 1 项（AC-C3 per-axis 不重叠校验缺 y 轴孤立越界 fixture，正确性覆盖缺口），降级 4 项为 RECOMMENDED（Boss 预警 N 下界——T_escape 几何地板可冻结但 T_reaction 人因参数归 BossStateMachine；AC-D2 spike 硬编码——已文档化维护步骤，应参数化非设计缺口；AC-A3 与 AC-A1 重复——质量维护；AC-D4 index_margin 值传递——归 Config 集成 AC）。另发现并修正 2 处具体数值错误（F6 有效下界 0.09→实际 0.058；Tuning Knobs arena fallback ×1.78→实际 ×1.833）。本轮修订 11 处闭环后 0 BLOCKING 剩余，接受标 Approved。

### 本轮修订（11 处）

1. AC-C3 补 y 轴孤立越界 fixture `boss_region_center=(0,13)`（x 合法/y 越界），per-axis 两轴独立覆盖 — 闭环 BLOCKING
2. F6 有效下界 0.09→0.058（补精确验算：cs=0.058→262200 超限、cs=0.059→252894 合法，有效下界约 0.0581）— 数值错误修正
3. Tuning Knobs arena fallback ×1.78→880/480≈1.833（补密度提升 83% 说明）— 数值错误修正
4. R4 补 T_escape 几何地板：`T_escape = boss_region_half/player_speed = 4.0/4.5 ≈ 0.89s`，Stage 声明 N 几何下界须 ≥ T_escape；N 完整值（含 T_reaction）与预警形式归 BossStateMachine（OQ4）
5. AC-D2 改参数化：期望值 cols/rows/grid_cells 由 fixture 的 arena_size 与 cell_size 按 F6 派生（非硬编码常量），spike=2.0 作参数集一 case，ADR 选定 cell_size 后只需追加参数不需改 Then
6. AC-A3 合并入 AC-A1（加居中不变式 `arena_min == −arena_max`），删除 AC-A3，覆盖核对表 R1/F1 行更新
7. AC-D3 增源值忠实复制断言：`snapshot.StageSpatialConfig.index_margin == 源 StageConfig.index_margin`，捕获 2.0→0.2 类复制错误
8. R6 COW 描述：`PackedVector2Array` 是 COW **值类型**（写即 unshare，区别于 Array 引用语义）；`.duplicate()` 必须→应（belt-and-suspenders，COW 本身已隔离）
9. AC-F1"证明 init 执行了真复制"→"证明 isolation invariant 成立（mechanism-agnostic，验证 behavior 不验证机制）"
10. R7 补 `changed` 信号注：代码侧 @export 赋值不自动触发，须 setter emit_changed()；dirty flag 流程冗余不强制
11. 覆盖核对表更新：R4 行补 T_escape、R6 行补值传递忠实、R1/F1 行改引 AC-A1

### 3 处分级分歧裁决（creative-director）

- **Boss 预警 N 下界**：level-designer→BLOCKING / game-designer→RECOMMENDED → 裁 **RECOMMENDED**。T_escape（≈0.89s）几何派生可冻结（Stage-owned），但 T_reaction 人因反应时间依赖预警形式归 BossStateMachine，非 Foundation 数据层。R4 补 T_escape 派生作下游 justify 锚点。
- **AC-D2 spike 硬编码**：qa-lead→BLOCKING / game-designer→RECOMMENDED → 裁 **RECOMMENDED**。AC-D2 已显式标注"ADR 后须更新期望值"是文档化维护步骤非隐藏陷阱；GDD 表达验证意图，实现者可参数化。Then 改参数化表述。
- **qa-lead 独有 3 BLOCKING**（AC-A3/AC-C3/AC-D4）：AC-C3 **维持 BLOCKING**（per-axis 正确性覆盖缺口，补一 fixture 闭环）；AC-A3/AC-D4 **降 RECOMMENDED**（质量维护/归 Config 集成 AC）。

### 共性根因（creative-director 识别，待后续治理）

- **根因 A**：spike 值在 AC 中被当冻结契约使用（AC-D2 硬编码、F6 prose 用 spike 推导陈旧值）— AC 的 Then 对 spike 量应一律"从 fixture 派生"表述
- **根因 B**：Stage-owned 边界在"行为前置条件"处模糊（R4 T_escape 未记录、AC-D3 验域不验值）— Stage 应显式记录几何地板与值传递契约锚点
- **根因 C**：per-axis 非对称性在文档与 AC 覆盖不完整（74/26 边带、36/20 环带、AC-C3 只 x 轴 fixture）— 从旧 40×40 迁 22×40 后 per-axis 后果未全面 propagate
- **根因 D**：cross-doc 示例值 propagate 滞后（已记账归 /propagate-design-change；两处数值错误本轮修正）

### 待办 RECOMMENDED（未本轮处理，无 BLOCKING，不阻塞 Approved）

- player_speed=4.5 registry 注册（双真相源风险）
- "9:16 比例"标签误导（arena 22:40 非 9:16，相机视口才是）
- spawn_ring_depth 语义复用（环带深度与玩家最小排除距离耦合）
- R3"固定方位"歧义（arena-relative vs 单一方向）
- F5 gated 项上界未约束 + index_margin_min 超域退化未显式说明
- per-axis 非对称文档（spawn ring 74/26 边带、短/长边 36/20 环带）
- spawn_ring_depth 变更规则缺 perf benchmark 要求（J4 边界聚集）
- cell_size 与 index_margin 协同变更路径（应同批次锁定）
- AC-D2.5 缺 shoelace=0 共线退化 + 正向 CCW 起始顶点 fixture
- AC-B1 status 归属混淆、AC-C1 缺 inner_rect 边中点 + 临界 fixture + spawn_ring_area 不对称
- AC-E2"派生值 snapshot ID"表述模糊
- spawn ring 角落降权 + arena fallback 视觉尺度效应未记录
- R5 polygon schema 缺"4 顶点==四角"显式校验
- 多项 NICE-TO-HAVE（ASCII 布局图、index_margin 反向缩放数值例、OQ1 sweep 退化具体化等）

### 跨文档 propagate 项（归 /propagate-design-change，本轮记账未动）

- spatial-grid.md F4 `arena_walkable_area`/`walkable_region` 仍标"外部 TUNING KNOB/未定义/生产值待定" → 更新为指向 stage-map 已冻结值（880.0、arena=22×40）并补 `referenced_by: stage-map.md`
- config-data-system.md F4 示例 `arena=40×40,cell_size=2` → 更新为 `22×40`

**Prior verdict resolved**: 是 — 第一轮 NEEDS REVISION 的 8 项 BLOCKING 全部闭环（多专家独立几何重算验证）；本轮新增 1 BLOCKING（AC-C3）已修订闭环。

---
