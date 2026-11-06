> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.

> 门禁定义，由 `/gate-check` **仅为目标阶段**加载。绝不加载其余五个——每次调用只适用一个门禁。


# Gate: Concept → Systems Design

# 门禁：Concept → Systems Design


**Required Artifacts:**

**必需产物：**

- [ ] `design/gdd/game-concept.md` exists and has content
- [ ] Game pillars defined (in concept doc or `design/gdd/game-pillars.md`)
- [ ] Visual Identity Anchor section exists in `design/gdd/game-concept.md` (from brainstorm Phase 4 art-director output)

- [ ] `design/gdd/game-concept.md` 存在且有内容
- [ ] 游戏支柱已定义（在概念文档或 `design/gdd/game-pillars.md` 中）
- [ ] `design/gdd/game-concept.md` 中存在 Visual Identity Anchor 章节（来自头脑风暴第 4 阶段 art-director 的输出）

**Recommended (not blocking):**

**建议项（不阻塞）：**

- [ ] Concept prototype exists in `prototypes/` with a REPORT.md showing PROCEED verdict
      (`/prototype [core-mechanic]`) — skipping this means GDDs may be written for an
      idea that hasn't been played. Acceptable if the concept is proven by other means.

- [ ] `prototypes/` 中存在概念原型，其 REPORT.md 显示 PROCEED 裁定（`/prototype [core-mechanic]`）——跳过这一步意味着 GDD 可能是为一个从未被玩过的想法而写。若该概念已通过其他方式得到验证，则可以接受。

**Quality Checks:**

**质量检查：**

- [ ] Game concept has been reviewed (`/design-review` verdict not MAJOR REVISION NEEDED)
- [ ] Core loop is described and understood
- [ ] Target audience is identified
- [ ] Visual Identity Anchor contains a one-line visual rule and at least 2 supporting visual principles

- [ ] 游戏概念已评审（`/design-review` 裁定不是 MAJOR REVISION NEEDED）
- [ ] 核心循环已被描述并为人所理解
- [ ] 目标受众已明确
- [ ] Visual Identity Anchor 含有一行视觉规则以及至少 2 条支撑性视觉原则

## Workflow tier reductions

## 工作流层级削减

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

上述检查清单是 **`full` 基线**。在较低层级，应用对应已解析层级的削减；未被点名的项目保持上述状态。削减只会 *放松* 要求——`workflow_overrides` 是唯一会新增要求的东西。

- **`full`** — game-concept.md + pillars + Visual Identity Anchor all required
- **`standard`** — pillars + Visual Identity Anchor → recommended; `game-concept.md` stays required
- **`minimal`** — gate target is **`design/game-brief.md`** (not `game-concept.md`); the GDD / pillars / Visual Identity Anchor checks **drop** (a brief with content = PASS). `/brainstorm` writes `design/game-brief.md` at this tier (Option A); `game-concept.md` remains the `standard`/`full` concept doc.

- **`full`**——game-concept.md + 支柱 + Visual Identity Anchor，全部为必需
- **`standard`**——支柱 + Visual Identity Anchor → 转为建议；`game-concept.md` 仍为必需
- **`minimal`**——门禁目标为 **`design/game-brief.md`**（而非 `game-concept.md`）；GDD / 支柱 / Visual Identity Anchor 检查**被丢弃**（简报有内容 = PASS）。`/brainstorm` 在此层级写出 `design/game-brief.md`（选项 A）；`game-concept.md` 仍是 `standard`/`full` 的概念文档。
