> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.

> 门禁定义，由 `/gate-check` **仅为目标阶段**加载。绝不加载其余五个——每次调用只适用一个门禁。


# Gate: Systems Design → Technical Setup

# 门禁：Systems Design → Technical Setup


**Required Artifacts:**

**必需产物：**

- [ ] Systems index exists at `design/gdd/systems-index.md` with at least MVP systems enumerated
- [ ] All MVP-tier GDDs exist in `design/gdd/` and individually pass `/design-review`
- [ ] A cross-GDD review report exists in `design/gdd/` (from `/review-all-gdds`)

- [ ] 系统索引存在于 `design/gdd/systems-index.md`，且至少枚举了 MVP 系统
- [ ] 所有 MVP 层级的 GDD 都存在于 `design/gdd/`，且各自通过 `/design-review`
- [ ] `design/gdd/` 中存在跨 GDD 评审报告（来自 `/review-all-gdds`）

**Quality Checks:**

**质量检查：**

- [ ] All MVP GDDs pass individual design review (8 required sections, no MAJOR REVISION NEEDED verdict)
- [ ] `/review-all-gdds` verdict is not FAIL (cross-GDD consistency and design theory checks pass). A NOT ASSESSED verdict does not satisfy this: that review could not compare the GDDs, so this item is NOT ASSESSED for the gate. Nor does a focus-run report (its `Focus:` line names one pass only): the other pass never ran, so the item stays open until a review runs both
- [ ] All cross-GDD consistency issues flagged by `/review-all-gdds` are resolved or explicitly accepted
- [ ] System dependencies are mapped in the systems index and are bidirectionally consistent
- [ ] MVP priority tier is defined
- [ ] No stale GDD references flagged (older GDDs updated to reflect decisions made in later GDDs)

- [ ] 所有 MVP GDD 都通过了单独的设计评审（8 个必需章节，无 MAJOR REVISION NEEDED 裁定）
- [ ] `/review-all-gdds` 裁定不是 FAIL（跨 GDD 一致性与设计理论检查均通过）。NOT ASSESSED 裁定不满足这一条：那次评审无法比较各 GDD，因此该项对本门禁为 NOT ASSESSED。只做单次评审的报告也不满足（其 `Focus:` 行只指明一次评审）：另一次评审从未运行，因此该项保持未了结，直到有一次评审同时完成两者
- [ ] `/review-all-gdds` 标记的所有跨 GDD 一致性问题都已解决或被明确接受
- [ ] 系统依赖已在系统索引中映射，且双向一致
- [ ] MVP 优先级层级已定义
- [ ] 未标记出陈旧的 GDD 引用（较旧的 GDD 已更新以反映后续 GDD 中做出的决策）

## Workflow tier reductions

## 工作流层级削减

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

上述检查清单是 **`full` 基线**。在较低层级，应用对应已解析层级的削减；未被点名的项目保持上述状态。削减只会 *放松* 要求——`workflow_overrides` 是唯一会新增要求的东西。

- **`full`** — systems-index + all MVP GDDs at 8 sections + cross-GDD review report all required
- **`standard`** — MVP GDDs validated at the **5 standard sections** (+ conditional Formulas); cross-GDD review report → recommended
- **`minimal`** — **gate not applicable** — no gate between brief and code; auto-PASS with a note (see below)

- **`full`**——系统索引 + 全部 MVP GDD 达到 8 个章节 + 跨 GDD 评审报告，全部为必需
- **`standard`**——MVP GDD 按 **5 个标准章节**（+ 条件性的 Formulas）校验；跨 GDD 评审报告 → 转为建议
- **`minimal`**——**门禁不适用**——简报与代码之间没有门禁；带说明自动 PASS（见下文）

> **`minimal` "not applicable" gate.** The Systems Design → Technical Setup gate
> has no meaning at `minimal` (no GDDs exist by design). Return a PASS verdict
> with the note: *"No design gate at minimal workflow — minimal skips the
> Systems Design phase; advancing brief → code."* The Section 6 stage write still
> applies on user confirmation. Do NOT flag absent GDDs as blockers. This is the
> named exception to Section 2b's rule that a gate with no required artifacts left
> may not PASS; the director panel does not run for it.

> **`minimal` 的"不适用"门禁。** Systems Design → Technical Setup 门禁在 `minimal` 下没有意义（按设计不存在 GDD）。返回 PASS 裁定并附说明：*"No design gate at minimal workflow — minimal skips the Systems Design phase; advancing brief → code."*（minimal 工作流下没有设计门禁——minimal 跳过 Systems Design 阶段；从简报推进到代码。）第 6 节的阶段写入在用户确认后仍然适用。**不要**把缺失的 GDD 标记为阻塞项。这是第 2b 节"已无必需产物的门禁不得 PASS"规则的点名例外；导演小组不会为它运行。
