# Settings Guidance — which value to recommend, and when
# 设置指导 — 推荐哪个值，以及何时推荐

The **advisory** layer for project settings. This doc answers two questions no
other doc does:
项目设置的**建议**层。本文档回答其他任何文档都不回答的两个问题：

1. **Which value should a skill recommend** for a given project or user?
1. **针对给定的项目或用户，技能应推荐哪个值？**
2. **When should a skill proactively suggest changing** a setting already set?
2. **技能应在何时主动建议更改**一个已经设置好的值？

## Boundary with its siblings
## 与同类文档的边界

| Doc | Answers | Nature |
|---|---|---|
| `effects-map.md` | What each setting *does* | Descriptive |
| `config-resolution.md` | How a setting *resolves* (precedence chain) | Mechanical |
| **`settings-guidance.md`** (this file) | Which value to *recommend*, and *when* | Prescriptive |

| 文档 | 回答 | 性质 |
|---|---|---|
| `effects-map.md` | 每个设置*做什么* | 描述性 |
| `config-resolution.md` | 设置*如何解析*（优先级链） | 机械性 |
| **`settings-guidance.md`**（本文件） | 推荐*哪个值*，以及*何时* | 规范性 |

Skills reference this doc **on demand**, only at a "recommend a setting" moment.
It is **not** a CLAUDE.md import — advisory content must not ride in per-turn
context.
技能**按需**引用本文档，仅在“推荐一个设置”的时刻引用。
它**不是** CLAUDE.md 的导入内容 — 建议性内容不得搭车进入每回合的
上下文。

---

## 1. The knob that matters most: `modes.rigor`
## 1. 最重要的旋钮：`modes.rigor`

Almost every "what settings should I use?" question reduces to one choice:
`modes.rigor` (`minimal` | `standard` | `full`, default `minimal`). It fronts six
sub-knobs — `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode`, `team.size`. Recommend **rigor**, not the six; let the
expansion do the rest. The full expansion table is in `effects-map.md § modes.rigor`.
几乎每个“我应该用什么设置？”的问题都会归结为一个选择：
`modes.rigor`（`minimal` | `standard` | `full`，默认 `minimal`）。它前置了六个
子旋钮 — `modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity`、
`modes.review_mode`、`team.size`。推荐**严谨度**，而不是这六个；让
扩展去做其余的事。完整的扩展表在 `effects-map.md § modes.rigor`。

`modes.automation` (`collaborative` | `guided` | `autonomous`) is a **separate
axis** — how often skills stop to confirm — and is *not* fronted by rigor. Pick it
by working style, not by game type (see § 5).
`modes.automation`（`collaborative` | `guided` | `autonomous`）是一个**单独的
轴** — 技能多久停下来确认一次 — 并且*不*由严谨度前置。根据工作风格来选择它，
而不是根据游戏类型（见 § 5）。

---

## 2. Archetype → rigor presets
## 2. 原型 → 严谨度预设

Match the project to an archetype; recommend the paired rigor. These are starting
points, not verdicts — the user can always override.
将项目匹配到一个原型；推荐配对的严谨度。这些是起始
点，不是裁决 — 用户始终可以覆盖。

| Archetype | Rigor | Why | Common override |
|---|---|---|---|
| Weekend jam / prototype / throwaway | `minimal` | Shipping beats recording; design lives in the maker's head | Bump one deep system: `workflow_overrides.system_overrides: {combat: full}` |
| Small solo / hobby game (arcade, puzzle, short narrative) | `minimal` → `standard` if it grows | Start light; add rigor when scope proves real | — |
| Focused commercial indie (platformer, roguelike, tactics, deckbuilder) | `standard` | One well-understood loop; enough design to build correctly | "Comprehensive but compact": `rigor: full` + `docs.density: terse` |
| Systems-heavy / long-haul (open-world RPG, colony sim, immersive sim, 4X, survival) | `full` | Many interacting systems; a design mistake costs weeks | Solo dev: keep `full` on disk, set `review_mode: solo` locally |
| Live-service / competitive multiplayer | `full` + domain emphasis | Full pipeline *plus* netcode/security/live-ops | Raise `qa.level` / `testing.strict.*` for the online-critical types |

| 原型 | 严谨度 | 原因 | 常见覆盖 |
|---|---|---|---|
| 周末 Game Jam / 原型 / 一次性项目 | `minimal` | 交付胜过记录；设计活在制作者脑中 | 提升一个深度系统：`workflow_overrides.system_overrides: {combat: full}` |
| 小型单人/业余游戏（街机、解谜、短叙事） | `minimal` → 若增长则 `standard` | 从轻开始；当范围被证明真实时再增加严谨度 | — |
| 专注的商业独立游戏（平台跳跃、Roguelike、战棋、卡牌构筑） | `standard` | 一个充分理解的循环；足够正确构建的设计 | “全面但紧凑”：`rigor: full` + `docs.density: terse` |
| 系统繁重/长期项目（开放世界 RPG、殖民地模拟、沉浸式模拟、4X、生存） | `full` | 许多相互作用的系统；一个设计错误会耗费数周 | 单人开发者：磁盘上保留 `full`，本地设置 `review_mode: solo` |
| 在线服务/竞技多人 | `full` + 领域侧重 | 完整流程*加上*网络代码/安全/在线运营 | 对在线关键类型提高 `qa.level` / `testing.strict.*` |

**The model:** the table picks a baseline; overrides handle the diagonal. Most real
projects are one baseline plus one or two deliberate exceptions.
**模型：** 该表选定一个基线；覆盖处理对角线。大多数真实
项目是一个基线加上一两个刻意的例外。

---

## 3. Seeding rigor from a described concept
## 3. 根据描述的概念播种严谨度

When the user has described their game (e.g. `/start` Phase 2 free text), map it to
an archetype and **pre-select** the recommendation rather than asking cold. Signals:
当用户已经描述了他们的游戏（例如 `/start` Phase 2 的自由文本），将其映射到
一个原型并**预选**推荐值，而不是冷不丁地询问。信号：

| Concept mentions… | Lean toward |
|---|---|
| open-world, RPG, sim, sandbox, faction, crafting, economy, MMO, multiplayer, "systems" | `full` |
| jam, weekend, prototype, "first game", small, "just trying", experiment | `minimal` |
| "release", "commercial", "on Steam", a single clear core loop | `standard` |
| *ambiguous / nothing above* | `minimal` (the documented default) |

| 概念提到…… | 倾向于 |
|---|---|
| open-world、RPG、sim、sandbox、派系、制作、经济、MMO、multplayer、“systems” | `full` |
| jam、weekend、prototype、“first game”、小、“just trying”、实验 | `minimal` |
| “release”、“commercial”、“on Steam”、单一清晰的核心循环 | `standard` |
| *含糊/以上都没有* | `minimal`（文档化的默认值） |

**Rules:** these are heuristics, never locks. Always confirm the pre-selection with
the user in their own terms ("Sounds like a big systems game — I'd suggest `full`
rigor; want that?"). If the user has **no concept yet** (exploring), do not seed
`full` — default `minimal`, and revisit once a concept exists.
**规则：** 这些是启发式，绝不是锁定。始终用用户自己的话确认预选
（“听起来像是一个大型系统游戏 — 我建议 `full`
严谨度；要这样吗？”）。如果用户**还没有概念**（在探索），不要播种
`full` — 默认 `minimal`，等有概念后再重新考虑。

"No concept yet" means **no signal**, not a particular onboarding path. A rough
one-line hint is still a description: if it trips the signals above, seed from the
signal. Only fall back to `minimal`-for-exploring when the user has given you
nothing to map. (`/start` Phase 4 applies the same rule when it infers rigor for its
Path A/B branch.)
“还没有概念”意味着**没有信号**，而不是某种特定的入门路径。一个粗略的
一句话提示仍然是描述：如果它触发了上述信号，就根据
信号播种。只有当用户没有给你任何可映射的内容时，才回退到为探索而设的
`minimal`。（`/start` Phase 4 在为其
Path A/B 分支推断严谨度时应用同一规则。）

---

## 4. When to recommend a *change* (adaptive triggers)
## 4. 何时建议*更改*（自适应触发器）

Bidirectional and **threshold-based**. Fire only on a threshold *crossing*, never
every session — that is what keeps this from becoming the nagging the `automation`
modes exist to eliminate.
双向且**基于阈值**。仅在阈值*跨越*时触发，绝不
每个会话都触发 — 这正是防止它变成 `automation`
模式旨在消除的唠叨的原因。

| Trigger (crossing) | Direction | Detectable signal | Suggested action |
|---|---|---|---|
| Project grew past its band | ↑ raise | System-GDD count crosses ~9, or the code root (`src/`, `Assets/` or `Source/`) crosses the Production threshold, while rigor is `minimal` | "You're at N systems on `rigor: minimal` — most projects this size run `standard`. Revisit? → `/settings`" |
| Stage advanced into Production | ↑ raise | `/gate-check` PASS into Production while rigor is `minimal` | Same, offered once at the gate |
| User sounds overwhelmed by process | ↓ lower | Phrases like "too many steps", "so much documentation", "overwhelmed" — *and* rigor is not already `minimal` | "If the required-doc list feels heavy, a lower rigor trims it → `/settings modes.rigor=standard`" |
| Chosen rigor mismatches described scope | flag once | Onboarding pick contradicts the Phase-2 description | State it in one sentence, offer `/settings`, do not re-ask |

| 触发器（跨越） | 方向 | 可检测信号 | 建议动作 |
|---|---|---|---|
| 项目增长超出其区间 | ↑ 提高 | 系统 GDD 数量跨越约 9，或代码根目录（`src/`、`Assets/` 或 `Source/`）跨越 Production 阈值，而严谨度为 `minimal` | “你现在有 N 个系统而 `rigor: minimal` — 大多数这种规模的项目使用 `standard`。要重新考虑吗？→ `/settings`” |
| 阶段推进到 Production | ↑ 提高 | `/gate-check` 在严谨度为 `minimal` 时 PASS 进入 Production | 同上，在门禁处提供一次 |
| 用户听起来被流程压垮 | ↓ 降低 | 诸如“步骤太多”、“文档太多”、“ overwhelmed”的措辞 — *并且* 严谨度尚不是 `minimal` | “如果必需文档列表感觉沉重，更低的严谨度会削减它 → `/settings modes.rigor=standard`” |
| 所选严谨度与描述的范围不匹配 | 标记一次 | 入门时的选择与 Phase 2 的描述矛盾 | 用一句话说明，提供 `/settings`，不要重复询问 |

**Frequency guard:** the crossing *is* the gate. Because the hosts (`/gate-check` on
PASS, `/help` on request) are themselves infrequent, no persistent "already nudged"
state is needed — but never emit the same suggestion twice in one session.
**频率护栏：** 跨越*就是*门禁。因为宿主（PASS 时的 `/gate-check`、
按请求的 `/help`）本身就不频繁，不需要持久的“已提醒过”
状态 — 但绝不要在一个会话中发出两次相同的建议。

---

## 5. Which skills reference this doc, and when
## 5. 哪些技能引用本文档，以及何时引用

| Skill | Moment | Sections used |
|---|---|---|
| `/start` | Phase 4 — inferring rigor for the card | § 2 (presets), § 3 (seed from concept) |
| `/help` | escalation footer when user sounds stuck/overwhelmed | § 4 (lower trigger) |
| `/gate-check` | on PASS into a new stage | § 4 (raise trigger) |
| `/settings` | view output — further reading | § 2 (choosing a value) |

| 技能 | 时机 | 使用章节 |
|---|---|---|
| `/start` | Phase 4 — 为卡片推断严谨度 | § 2（预设）、§ 3（从概念播种） |
| `/help` | 当用户听起来卡住/被压垮时的升级页脚 | § 4（降低触发器） |
| `/gate-check` | 在 PASS 进入新阶段时 | § 4（提高触发器） |
| `/settings` | 查看输出 — 延伸阅读 | § 2（选择值） |

These skills each carry a **one-line pointer** to this doc.
这些技能各自带有一个指向本文档的**一行指针**。

---

## 6. How to phrase a recommendation
## 6. 如何表述建议

- **Recommend, don't dictate.** State the suggestion and the reason in one line;
  the user decides. (`collaborative`/`guided` require this; even `autonomous`
  treats a rigor change as a `schema_changes` decision and asks.)
- **建议，而非命令。** 用一行陈述建议和理由；
  由用户决定。（`collaborative`/`guided` 要求如此；即使 `autonomous`
  也把严谨度变更视为 `schema_changes` 决策并询问。）
- **Always route to `/settings`** — never edit `project.yaml` as a side effect of a
  recommendation.
- **始终路由到 `/settings`** — 绝不在建议的副作用中编辑 `project.yaml`。
- **One line, then stop.** A nudge is a nudge, not a lecture.
- **一行，然后停止。** 提醒就是提醒，不是说教。
