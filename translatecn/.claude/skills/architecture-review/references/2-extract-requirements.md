# /architecture-review — Phase 2: Extract Technical Requirements
# /architecture-review — 阶段 2：提取技术需求

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 2: Extract Technical Requirements from Every GDD
## 阶段 2：从每个 GDD 中提取技术需求

### Pre-load the TR Registry
### 预加载 TR 注册表

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.
在提取任何需求之前，读取 `docs/architecture/tr-registry.yaml`（若存在）。
按 `id` 以及规范化后的 `requirement` 文本（小写、去除首尾空白）为现有条目
建立索引。这可防止跨评审运行发生 ID 重新编号。

Then read the Technical Requirements Baseline in `docs/architecture/architecture.md`
if it exists. `/create-architecture` numbers each requirement the registry did not
hold as `(provisional)`, from the registry's next free ID, and ADRs written from
the baseline may already cite those IDs.
然后读取 `docs/architecture/architecture.md` 中的技术需求基线（若存在）。
`/create-architecture` 会把注册表未持有的每项需求标记为 `(provisional)`，
并从注册表的下一个空闲 ID 开始编号，且基于该基线编写的 ADR 可能已经引用了
这些 ID。

For each requirement you extract, the matching rule is:
对于你提取的每项需求，匹配规则如下：

1. **Exact/near match** to an existing registry entry for the same system →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the GDD wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
1. **与同一系统的现有注册表条目精确/近似匹配** → 原样复用该条目的 TR-ID。
   仅当 GDD 的措辞发生变化（意图相同、表述更清晰）时，才更新注册表中的
   `requirement` 文本 — 并添加 `revised: [date]` 字段。
2. **Match to a provisional baseline row** (same system, same intent) → keep that
   ID when the registry holds no entry with it, active or retired: registering it
   is what makes it permanent. When the ID is taken, assign the next available one
   and list the rename (`TR-[system]-004 (provisional) → TR-[system]-006`) in the
   report, so the ADRs and stories that cite it can be updated.
2. **与临时基线行匹配**（同一系统、同一意图）→ 当注册表中没有持有该 ID 的条目
   （无论活跃还是已退役）时，保留该 ID：登记它才能使其永久化。当该 ID 已被
   占用时，分配下一个可用 ID，并在报告中列出重命名
   （`TR-[system]-004 (provisional) → TR-[system]-006`），以便引用它的 ADR
   和故事得以更新。
3. **No match** → assign a new ID: next available `TR-[system]-NNN` for that
   system, starting from the highest existing sequence + 1, skipping any ID a
   provisional baseline row holds.
3. **无匹配** → 分配新 ID：下一个可用的 `TR-[system]-NNN`（针对该系统），从
   现有最高序号 + 1 开始，跳过任何被临时基线行持有的 ID。
4. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[system]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).
4. **有歧义**（部分匹配、意图不明）→ 询问用户：
   > "'[新需求文本]'是否与
   > `TR-[system]-NNN: [现有文本]` 指的是同一项需求，还是一项新需求？"
   用户回答："Same requirement"（复用 ID）或 "New requirement"（新 ID）。

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the GDD intentionally.
对于注册表中 `status: deprecated` 的任何需求 — 跳过它。
它是被有意从 GDD 中移除的。

For each GDD, read it and extract all **technical requirements** — things the
architecture must provide for the system to work. A technical requirement is any
statement that implies a specific architectural decision.
对每个 GDD，阅读它并提取所有**技术需求** — 架构必须提供、以便系统正常运行
的内容。技术需求是任何隐含某个具体架构决策的陈述。

Categories to extract:
需提取的类别：

| Category | Example |
|----------|---------|
| **Data structures** | "Each entity has health, max health, status effects" → needs a component/data schema |
| **Performance constraints** | "Collision detection must run at 60fps with 200 entities" → physics budget ADR |
| **Engine capability** | "Inverse kinematics for character animation" → IK system ADR |
| **Cross-system communication** | "Damage system notifies UI and audio simultaneously" → event/signal architecture ADR |
| **State persistence** | "Player progress persists between sessions" → save system ADR |
| **Threading/timing** | "AI decisions happen off the main thread" → concurrency ADR |
| **Platform requirements** | "Supports keyboard, gamepad, touch" → input system ADR |

| 类别 | 示例 |
|----------|---------|
| **数据结构** | "每个实体都有生命值、最大生命值、状态效果" → 需要组件/数据模式 |
| **性能约束** | "碰撞检测必须在 200 个实体下以 60fps 运行" → 物理预算 ADR |
| **引擎能力** | "角色动画使用反向运动学" → IK 系统 ADR |
| **跨系统通信** | "伤害系统同时通知 UI 和音频" → 事件/信号架构 ADR |
| **状态持久化** | "玩家进度在会话之间持久保存" → 存档系统 ADR |
| **线程/时序** | "AI 决策在主线程之外进行" → 并发 ADR |
| **平台需求** | "支持键盘、手柄、触摸" → 输入系统 ADR |

For each GDD, produce a structured list:
对每个 GDD，产出一份结构化清单：

```
GDD: [filename]
System: [system name]
Technical Requirements:
  TR-[GDD]-001: [requirement text] → Domain: [Physics/Rendering/etc]
  TR-[GDD]-002: [requirement text] → Domain: [...]
```

This becomes the **requirements baseline** — the complete set of what the
architecture must cover.
这将构成**需求基线** — 架构必须覆盖的完整集合。

---
