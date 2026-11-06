# /gate-check — Sections 4 and 4b: Assessment and Director Panel

# /gate-check — 第 4 与 4b 节：评估与导演小组

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 4. Collaborative Assessment

## 4. 协作式评估

**In this file:**

**本文件包括：**

- 4. Collaborative Assessment: unverifiable items are never PASS
- 4b. Director Panel Assessment: `review_mode` decides whether directors spawn, `workflow` decides the panel width
- Gate IDs
- Naming the omissions, and applying the panel to the verdict

- 4. 协作式评估：无法核验的项目绝不为 PASS
- 4b. 导演小组评估：`review_mode` 决定是否生成导演，`workflow` 决定小组的宽度
- 门禁 ID
- 点名被省略的视角，以及将小组结果应用到裁定

For items that can't be automatically verified, **ask the user**:

对于无法自动核验的项目，**询问用户**：

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

- "我无法自动核验核心循环是否好玩。它被试玩过吗？"
- "未找到试玩报告。是否做过非正式测试？"
- "性能剖析数据不可用。你愿意运行 `/perf-profile` 吗？"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.
An answer resolves the item: "no" or "not yet" is a checked, failed item
(CONCERNS or FAIL, naming the skill that closes it — `/design-review [doc]` for
an unreviewed concept or GDD) — except a play question at the Production gate
(a human has played the Vertical Slice; at `minimal`, the core loop is fun on
the current build), where "not yet" means nobody has played it: NOT ASSESSED
(`gate-production.md`). Only an unanswered item or "I don't know" stays
MANUAL CHECK NEEDED, which Section 5 turns into NOT ASSESSED.

**绝不要对无法核验的项目假定 PASS。** 将其标记为 MANUAL CHECK NEEDED。回答会了结该项："no" 或 "not yet" 属于已检查、未通过的项目（CONCERNS 或 FAIL，并点名能了结它的技能——对未评审的概念或 GDD 为 `/design-review [doc]`）——但 Production 门禁上的玩法问题除外（已有人玩过 Vertical Slice；在 `minimal` 下是核心循环在当前构建上是否好玩），对此 "not yet" 意味着没人玩过：NOT ASSESSED（`gate-production.md`）。只有未作答的项目或 "I don't know" 才保持 MANUAL CHECK NEEDED，第 5 节会将其转为 NOT ASSESSED。

This applies to questions about the project's state. Declining an offer to
produce missing data (e.g. `/perf-profile`) leaves the item NOT ASSESSED; at
`performance.enforce: off` it stays out of the verdict.

这适用于关于项目状态的提问。拒绝生成缺失数据的提议（例如 `/perf-profile`）会使该项保持 NOT ASSESSED；在 `performance.enforce: off` 下，它不进入裁定。

---

## 4b. Director Panel Assessment

## 4b. 导演小组评估

The panel is set by **two independent axes**, both resolved in Phase 1: `review_mode`
decides *whether* the panel runs, `workflow` decides *how wide* it is.

小组由**两条独立的轴**决定，二者均在第 1 阶段解析：`review_mode` 决定小组*是否*运行，`workflow` 决定它有多宽。

**Axis 1 — `review_mode` decides whether any director spawns:**
- `solo` → skip the panel entirely. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." Proceed to Phase 5.
- `lean` → run the panel (phase gates always run in lean mode — this is their purpose).
- `full` → run the panel.

**轴 1——`review_mode` 决定是否有任何导演生成：**
- `solo` → 完全跳过小组。在输出中注明："Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." 然后进入第 5 阶段。
- `lean` → 运行小组（阶段门禁在 lean 模式下始终运行——这正是它们的用途）。
- `full` → 运行小组。

**Axis 2 — `workflow` decides the panel width.** Directors are Opus-tier, so the
panel is sized to the project rather than fixed at four. The gate still runs at
every tier; only its breadth scales:

**轴 2——`workflow` 决定小组宽度。** 导演属于 Opus 层级，因此小组按项目规模来确定，而非固定为四人。门禁在每个层级仍会运行；只有其广度随之伸缩：

| `workflow` | Panel | Directors |
|---|---|---|
| `minimal` | 1 | `producer` |
| `standard` | 2 | `technical-director`, `producer` |
| `full` | 4 | `creative-director`, `technical-director`, `producer`, `art-director` |

| `workflow` | 小组人数 | 导演 |
|---|---|---|
| `minimal` | 1 | `producer` |
| `standard` | 2 | `technical-director`, `producer` |
| `full` | 4 | `creative-director`, `technical-director`, `producer`, `art-director` |

`producer` is in every panel — scope and schedule readiness is the one judgment
no tier makes optional. `technical-director` joins at `standard` because that is
the first tier requiring architecture artifacts. `creative-director` and
`art-director` join at `full`, the only tier requiring the full art bible and
UX spec set for them to assess.

`producer` 出现在每个小组中——范围与进度的就绪度是任何层级都不会设为可选的那项判断。`technical-director` 在 `standard` 加入，因为那是第一个要求架构产物的层级。`creative-director` 与 `art-director` 在 `full` 加入，那也是唯一要求完整美术圣经与 UX 规格集以供他们评估的层级。

> **Width is not the same as strictness.** A narrower panel does not soften the
> verdict: the escalation rule in `.claude/docs/director-gates.md` is unchanged —
> the strictest verdict returned by *whoever ran* still wins. Do not infer PASS
> from a perspective that was never consulted.

> **宽度不等于严格程度。** 更窄的小组不会软化裁定：`.claude/docs/director-gates.md` 中的升级规则不变——由*实际运行者*返回的最严格裁定仍然胜出。不要从一个从未被咨询的视角推断 PASS。

Before generating the final verdict, spawn the directors for the resolved tier as **parallel subagents** via `Agent` using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all the `Agent` calls simultaneously — do not wait for one before starting the next.

在生成最终裁定之前，按已解析层级为对应导演使用 `.claude/docs/director-gates.md` 中的并行门禁协议，通过 `Agent` 以**并行子智能体**方式生成。同时发出全部 `Agent` 调用——不要等一个返回后再启动下一个。

**Gate IDs:**

**门禁 ID：**

1. **`creative-director`** — gate **CD-PHASE-GATE** (`.claude/docs/director-gates/cd-phase-gate.md`)
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates/td-phase-gate.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates/pr-phase-gate.md`)
4. **`art-director`** — gate **AD-PHASE-GATE** (`.claude/docs/director-gates/ad-phase-gate.md`)

1. **`creative-director`**——门禁 **CD-PHASE-GATE**（`.claude/docs/director-gates/cd-phase-gate.md`）
2. **`technical-director`**——门禁 **TD-PHASE-GATE**（`.claude/docs/director-gates/td-phase-gate.md`）
3. **`producer`**——门禁 **PR-PHASE-GATE**（`.claude/docs/director-gates/pr-phase-gate.md`）
4. **`art-director`**——门禁 **AD-PHASE-GATE**（`.claude/docs/director-gates/ad-phase-gate.md`）

Pass to each the target phase name, the resolved `workflow` tier, the target
gate's required and recommended artifacts at the resolved tier (the loaded gate
file's checklist after its tier reduction and the `qa.level` relaxation — what
this gate asks for, not what a later one will), the list of artifacts present,
and its gate's own context — named here, so this session never has to read the
gate files:

向每一位传入：目标阶段名称、已解析的 `workflow` 层级、目标门禁在已解析层级下的必需与建议产物（即已加载门禁文件在层级削减与 `qa.level` 放松之后的检查清单——是*本*门禁所要求的，而非后续门禁将要求的）、当前存在的产物列表，以及其门禁自身的上下文——在此点名，以便本会话永远不必去读那些门禁文件：

- **CD-PHASE-GATE**: the game pillars and core fantasy (from
  `design/gdd/game-concept.md`, else `design/game-brief.md`).
- **TD-PHASE-GATE**: the architecture document path, the engine reference path
  (`docs/engine-reference/<engine>/VERSION.md`), and the ADR list.
- **PR-PHASE-GATE**: the sprint and milestone artifacts present, `team.size` as
  resolved above (with the current sprint plan's capacity, if a plan exists), and
  the number of stories under `production/epics/` whose status is `Blocked`. At
  `workflow: minimal`, pass the Build order in `design/game-brief.md` as the plan — that
  tier has no sprint plan.
- **AD-PHASE-GATE**: the art and visual artifacts present, the Visual Identity
  Anchor (from `design/gdd/game-concept.md`, else the "Art & audio direction"
  line of `design/game-brief.md`), and the art bible path.

- **CD-PHASE-GATE**：游戏支柱与核心幻想（来自 `design/gdd/game-concept.md`，否则用 `design/game-brief.md`）。
- **TD-PHASE-GATE**：架构文档路径、引擎参考路径（`docs/engine-reference/<engine>/VERSION.md`），以及 ADR 列表。
- **PR-PHASE-GATE**：当前存在的冲刺与里程碑产物、上文解析出的 `team.size`（若存在当前冲刺计划，则连同其容量），以及 `production/epics/` 下状态为 `Blocked` 的故事数量。在 `workflow: minimal` 下，将 `design/game-brief.md` 中的 Build order 作为计划传入——该层级没有冲刺计划。
- **AD-PHASE-GATE**：当前存在的美术与视觉产物、Visual Identity Anchor（来自 `design/gdd/game-concept.md`，否则用 `design/game-brief.md` 的 "Art & audio direction" 行），以及美术圣经路径。

Tell each director to read any GDD, ADR or the art bible by section: find the
headings with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.

告知每一位导演按章节阅读任何 GDD、ADR 或美术圣经：用 Grep 工具（pattern `^#`，content 模式）找出标题，再用 offset 与 limit 读取那些区间。

Pass each context item as one of three things, so no director has to guess:
- **Present** — its path or value (`0` blocked stories is a value).
- **"none"** — the target gate (or an earlier one) requires or recommends it at
  this tier and it does not exist (no architecture document at
  `/gate-check pre-production`). For the director that is a fact about the
  project to judge, not a missing input.
- **"not expected before [phase]"** — the target gate does not ask for it yet;
  name the phase whose gate first does (the architecture document and ADRs
  before Pre-Production, the sprint plan before Production). One this tier never
  requires is "not required at `workflow: [tier]`" (any sprint plan at
  `minimal`). Neither is ever passed as "none", and neither is a finding — a
  director judges readiness for the phase being entered, not a later one.

将每个上下文条目作为以下三者之一传入，以便任何导演都无需猜测：
- **Present（存在）**——其路径或值（`0` 个阻塞故事也是一个值）。
- **"none"（无）**——目标门禁（或更早的门禁）在此层级要求或建议它，但它并不存在（在 `/gate-check pre-production` 处没有架构文档）。对导演而言，那是关于项目的一个待判断事实，而不是缺失的输入。
- **"not expected before [phase]"（在 [阶段] 之前不预期）**——目标门禁尚未要求它；点名其门禁首次要求它的那个阶段（架构文档与 ADR 在 Pre-Production 之前，冲刺计划在 Production 之前）。此层级从不要求的则写作 "not required at `workflow: [tier]`"（`minimal` 下的任何冲刺计划）。后两者都绝不以 "none" 传入，也都不是一项发现——导演判断的是即将进入的阶段的就绪度，而不是更晚阶段的。

**Name the omissions in the output.** Below the Director Panel summary, when the
panel ran narrower than four, state which perspectives did not run and how to get
them — e.g. "Panel: 2 of 4 (`workflow: standard`). Creative and Art perspectives
not consulted. Raise `modes.rigor` to `full` (or set `modes.workflow: full`) for
the complete panel." Name the setting the config block shows as `workflow`'s
source: when `modes.workflow` is set on its own, raising `modes.rigor` does not
change it. Never point to `--review full` for this — `--review` decides whether
the panel runs, not how wide it is. A silently narrow panel reads as a clean bill
of health from reviewers who never looked.

**在输出中点名被省略的视角。** 在 Director Panel 摘要之下，当小组运行得比四人更窄时，说明哪些视角没有运行以及如何获得它们——例如 "Panel: 2 of 4 (`workflow: standard`). Creative and Art perspectives not consulted. Raise `modes.rigor` to `full` (or set `modes.workflow: full`) for the complete panel." 点名配置块中作为 `workflow` 来源显示的那个设置：当 `modes.workflow` 被单独设置时，提高 `modes.rigor` 并不会改变它。绝不要为此指向 `--review full`——`--review` 决定小组是否运行，而不是它有多宽。一个悄无声息地变窄的小组，读起来就像是从未看过的人给出的一份健康证明。

**Collect every response from the directors that ran, then present the Director Panel summary** (one row per director that ran; name the ones `workflow` left out):

**收集所有已运行导演的每一份回复，然后呈现 Director Panel 摘要**（每个实际运行的导演一行；点名 `workflow` 省略掉的那些）：

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Art Director:       [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]
```

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Art Director:       [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]
```

（摘要模板保持原样：CREATIVE DIRECTOR（创意总监）、TECHNICAL DIRECTOR（技术总监）、PRODUCER（制作人）、ART DIRECTOR（美术总监）；[feedback] 为反馈内容。）

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (no override turns a FAIL into a stage change — Section 6)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- Any director returns NOT ASSESSED (and none returned NOT READY or CONCERNS) → verdict at best NOT ASSESSED; name the input that director said was missing — it never counts as READY
- Every director that ran returns READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

**应用到裁定：**
- 任何导演返回 NOT READY → 裁定最低为 FAIL（没有任何覆盖能把 FAIL 变成阶段变更——第 6 节）
- 任何导演返回 CONCERNS → 裁定最低为 CONCERNS
- 任何导演返回 NOT ASSESSED（且无人返回 NOT READY 或 CONCERNS）→ 裁定至多为 NOT ASSESSED；点名该导演所说缺失的输入——它绝不算作 READY
- 每个实际运行的导演都返回 READY → 有资格 PASS（仍受第 3 节的产物与质量检查约束）

---
