# project.yaml — Effects Map
# project.yaml — 效果映射

> ## READ ONE SECTION, NEVER THIS WHOLE FILE
> ## 只读一节，绝不要读整个文件
>
> This document is very large, far more than any one lookup needs. It is
> organised as one section per setting, headed `## <key>`, so a reader can take
> only the section it wants.
> 本文档非常大，远远超过任何单次查询所需。它按每个设置一节组织，
> 标题为 `## <key>`，因此读者可以只取自己需要的章节。
>
> **So opening it whole costs many times what you need.** To look up a setting:
> **因此整篇打开的成本是你所需的许多倍。** 要查询一个设置：
>
> ```
> Grep pattern="^## modes.review_mode" path=".claude/docs/effects-map.md" -A 40
> ```
>
> Read the section for your key and stop. The same rule the skills already apply
> to their own reference files — `/gate-check` loads only the row for the target
> phase and says "never load the others" — applies here, and this is the largest
> file in the framework.
> 读取你所需键的章节然后停止。技能已经对其自身参考文件应用的同一规则 —
> `/gate-check` 只加载目标阶段的那一行并说“绝不加载其他行” — 在此适用，
> 而这是框架中最大的文件。
>
> Cite a section of this document, never the whole file. A pointer such as "see
> effects-map.md for full schema" invites a full read of a file this size, and
> the cost of accepting that invitation is silent. Name the `## <key>` section
> you need instead.
> 引用本文档的某一节，绝不要引用整个文件。诸如“完整模式见
> effects-map.md”的指引会诱惑人去整篇读取这种大小的文件，而
> 接受该诱惑的代价是无声的。请改为指明你需要的 `## <key>` 章节。

This document defines what each `project.yaml` setting actually does across
every skill that reads it. It is the tracked, authoritative reference.
本文档定义每个 `project.yaml` 设置在读取它的每个技能中实际做什么。
它是受跟踪的权威参考。

**Purpose:** When a skill reads a setting, this document is the authoritative
source for what each value means for that skill's behavior. Implementers update
this file when adding a new setting or changing how a skill responds to one.
**目的：** 当技能读取某个设置时，本文档是该值对技能行为意味着什么的权威
来源。实现者在添加新设置或更改技能对某个设置的响应方式时更新
本文件。

**Format per setting:**
- Priority chain — which source wins when multiple are present
- Per-value intent — what the value means in plain terms
- Skill behavior table — exactly what changes per skill per value
**每个设置的格式：**
- 优先级链 — 当多个来源存在时哪个胜出
- 按值意图 — 用平实语言说明该值的含义
- 技能行为表 — 每个技能在每个值下究竟如何变化

**Coverage scope:** This document covers the skills most affected by each setting.
Skills not listed (e.g. `ux-review`, `balance-check`, `test-flakiness`, `test-helpers`,
`test-setup`, `soak-test`, `perf-profile`, `launch-checklist`, `release-checklist`,
`skill-test`, `skill-improve`, `vertical-slice`) are not meaningfully affected by
`project.yaml` settings and do not need entries here. Add a skill only when its
behavior genuinely branches on a setting value.
**覆盖范围：** 本文档涵盖受每个设置影响最大的技能。
未列出的技能（例如 `ux-review`、`balance-check`、`test-flakiness`、`test-helpers`、
`test-setup`、`soak-test`、`perf-profile`、`launch-checklist`、`release-checklist`、
`skill-test`、`skill-improve`、`vertical-slice`）不受
`project.yaml` 设置的实质影响，无需在此列出条目。仅当技能的行为确实
根据设置值分支时才添加它。

**Local override pattern:** `project.yaml` is committed to git as the shared team
config. Per-developer overrides live in `project.local.yaml` (gitignored). Priority
chain across all settings: `project.local.yaml` → `project.yaml` → legacy mirror →
`modes.rigor` expansion → hardcoded default. The expansion step applies only to the
six knobs `rigor` fronts (`modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity`, `modes.review_mode`, `team.size`), which for that reason have **no** hardcoded default —
see the `modes.rigor` section.
**本地覆盖模式：** `project.yaml` 作为共享团队配置提交到 git。每位开发者的
覆盖位于 `project.local.yaml`（被 gitignore 忽略）。所有设置的优先级
链：`project.local.yaml` → `project.yaml` → 旧版镜像 →
`modes.rigor` 扩展 → 硬编码默认值。扩展步骤仅适用于
`rigor` 前置的六个旋钮（`modes.workflow`、`docs.density`、`qa.level`、
`modes.story_granularity`、`modes.review_mode`、`team.size`），正因如此它们**没有**硬编码默认值 —
参见 `modes.rigor` 章节。
**Secrets do NOT belong in either file — use environment variables.** See the
"Local Override Pattern" section below for full design including the whitelist of
which settings can be locally overridden.
**秘密不属于这两个文件中的任何一个 — 使用环境变量。** 参见下面的
“本地覆盖模式”章节以获取完整设计，包括哪些设置可以在本地覆盖的白名单。

---

## Local Override Pattern — `project.local.yaml`
## 本地覆盖模式 — `project.local.yaml`

The `project.local.yaml` file lets each developer override specific settings for
their own use without affecting the team. The file is gitignored and never
committed.
`project.local.yaml` 文件让每位开发者为自己覆盖特定设置，
而不影响团队。该文件被 gitignore 忽略且从不
提交。

### How it works
### 工作原理

Priority chain (every setting): `project.local.yaml` → `project.yaml` → hardcoded default
优先级链（每个设置）：`project.local.yaml` → `project.yaml` → 硬编码默认值

If a setting is present in `project.local.yaml`, that value wins. If absent, the
value from `project.yaml` is used. If absent there too, the hardcoded default
takes over.
如果设置在 `project.local.yaml` 中存在，该值胜出。如果缺失，则使用
`project.yaml` 中的值。如果那里也缺失，则由硬编码默认值
接管。

---

### Deep merge semantics
### 深度合并语义

When both files set a nested value, only the explicitly-set key is overridden.
Sibling keys in the same block are preserved.
当两个文件都设置某个嵌套值时，只有显式设置的键被覆盖。
同一块中的兄弟键被保留。

Example:
示例：

`project.yaml`:
`project.yaml`：
```yaml
testing:
  strict:
    logic: true
    integration: true
    visual: false
```

`project.local.yaml` (sparse override):
`project.local.yaml`（稀疏覆盖）：
```yaml
testing:
  strict:
    logic: false
```

Effective config seen by skills: `logic: false, integration: true, visual: false`.
Only the explicitly-set `logic` key is overridden; sibling keys come through from
`project.yaml`.
技能看到的生效配置：`logic: false, integration: true, visual: false`。
只有显式设置的 `logic` 键被覆盖；兄弟键来自
`project.yaml`。

---

### Whitelist — which settings can be locally overridden
### 白名单 — 哪些设置可以在本地覆盖

Only personal-experience settings can be locally overridden. Project-wide facts
(engine, stage, naming conventions, what's required on disk) are locked to
`project.yaml` because divergence between developers would break team coordination.
只有个人体验设置可以在本地覆盖。项目范围的事实
（引擎、阶段、命名约定、磁盘上要求的内容）锁定到
`project.yaml`，因为开发者之间的分歧会破坏团队协调。

The rule for deciding which side a setting belongs on:
决定设置属于哪一侧的规则：

> **If a setting affects what artifacts exist or what they look like on disk,
> it must be locked to `project.yaml`. If a setting only changes your personal
> experience (which agents spawn for you, whether you get prompts, your local
> CI bypass), it can be locally overridden.**
> **如果设置影响磁盘上存在哪些产物或它们的样子，
> 就必须锁定到 `project.yaml`。如果设置只改变你的个人
> 体验（为你生成哪些智能体、你是否收到提示、你的本地
> CI 绕过），就可以在本地覆盖。**

**Locally overridable** (personal experience only — no effect on artifacts on disk):
**可本地覆盖**（仅个人体验 — 对磁盘上的产物无影响）：

| Setting | Why local override makes sense |
|---------|-------------------------------|
| `modes.review_mode` | How much AI review you personally want |
| `modes.automation` | How often the AI prompts you |
| `modes.automation_always_ask` | Your personal safety categories |
| `team.size` | Which agents spawn for your reviews (review depth differs, artifacts don't) |
| `testing.strict.*` (each type) | Whether failures block your local work (CI still enforces project.yaml defaults) |
| `performance.enforce` | Whether budget violations block your local work (CI enforces project defaults) |
| `features.session_state` | Your session tracking preference |
| `features.token_budget_warn_at` | Your personal cost threshold |
| `features.read_guard` | Whether your whole-file reads of large design docs are refused |
| `features.read_guard_kb` | The size over which they are |
| `updates.check` | Whether you see the new-release line; turning it off for you leaves it on for teammates |

| 设置 | 为什么本地覆盖合理 |
|---------|-------------------------------|
| `modes.review_mode` | 你个人想要多少 AI 评审 |
| `modes.automation` | AI 多久提示你一次 |
| `modes.automation_always_ask` | 你个人的安全类别 |
| `team.size` | 为你的评审生成哪些智能体（评审深度不同，产物不变） |
| `testing.strict.*`（每种类型） | 失败是否阻塞你的本地工作（CI 仍执行 project.yaml 默认值） |
| `performance.enforce` | 预算违规是否阻塞你的本地工作（CI 执行项目默认值） |
| `features.session_state` | 你的会话跟踪偏好 |
| `features.token_budget_warn_at` | 你个人的成本阈值 |
| `features.read_guard` | 你对大型设计文档的整文件读取是否被拒绝 |
| `features.read_guard_kb` | 超过多大时被拒绝 |
| `updates.check` | 你是否看到新版本行；为你关闭它不会影响队友 |

**Locked to `project.yaml`** (project-wide — would create artifact divergence if local):
**锁定到 `project.yaml`**（项目范围 — 若为本地将产生产物分歧）：

| Setting | Why it must be project-wide |
|---------|----------------------------|
| `schema_version`, `framework.*` | File metadata, not preferences — **exempt from the report below**, since a `project.local.yaml` carrying `schema_version: 1` is correct as written |
| `project.name`, `version`, `genre`, `kind`, `stage` | Project identity |
| `engine.*`, `specialists.*` | Whole team must use same engine |
| `naming.*` | Code conventions must be consistent across team |
| `platform.*` | Game facts (what platforms it ships on) |
| `performance.target_framerate`, `frame_budget_ms`, `draw_call_limit`, `memory_ceiling_mb` | Game budgets, shared targets |
| `accessibility.target` | Game commitment, project-wide |
| `cadence.*` | Sprint/milestone length affects team coordination |
| `modes.rigor` | Fronts the four below — locked for the same reason they are |
| `modes.workflow` and `workflow_overrides` | Affects which sections are required in authored docs |
| `modes.story_granularity` | Affects how big stories are in repo — team must be consistent |
| `docs.density` | Affects how deep authored docs are — team must produce consistent docs |
| `qa.level` | Affects what test evidence stories must include on disk |
| `qa.coverage_minimum` | Project quality bar |
| `strict_gate_checks` | Affects whether `project.stage` advances — a project-wide write |
| `commands.*` | Build/test commands are project facts |
| `testing.framework` | Whole project uses one framework |

| 设置 | 为什么必须项目范围 |
|---------|----------------------------|
| `schema_version`、`framework.*` | 文件元数据，不是偏好 — **豁免于下面的报告**，因为一个携带 `schema_version: 1` 的 `project.local.yaml` 按原样就是正确的 |
| `project.name`、`version`、`genre`、`kind`、`stage` | 项目身份 |
| `engine.*`、`specialists.*` | 整个团队必须使用同一引擎 |
| `naming.*` | 代码约定必须在团队内保持一致 |
| `platform.*` | 游戏事实（发布到哪些平台） |
| `performance.target_framerate`、`frame_budget_ms`、`draw_call_limit`、`memory_ceiling_mb` | 游戏预算、共享目标 |
| `accessibility.target` | 游戏承诺，项目范围 |
| `cadence.*` | 冲刺/里程碑长度影响团队协调 |
| `modes.rigor` | 前置下面四个 — 因同样的原因被锁定 |
| `modes.workflow` 和 `workflow_overrides` | 影响创作文档中要求哪些章节 |
| `modes.story_granularity` | 影响仓库中 story 的大小 — 团队必须一致 |
| `docs.density` | 影响创作文档的深度 — 团队必须产出风格一致的文档 |
| `qa.level` | 影响 story 必须在磁盘上包含哪些测试证据 |
| `qa.coverage_minimum` | 项目质量门槛 |
| `strict_gate_checks` | 影响 `project.stage` 是否推进 — 项目范围的写入 |
| `commands.*` | 构建/测试命令是项目事实 |
| `testing.framework` | 整个项目使用一个框架 |

> **A locked key written into `project.local.yaml` by hand is reported, not
> swallowed.** `/settings --local` refuses to write one, but the
> file is meant to be hand-edited and that path had no guard: `modes.rigor: full`
> there is a real key with a legal value, so enum validation passes it, and then
> resolution never consults the local file for that path — the setting vanishes
> and the user sees the default they were trying to override, with no error
> anywhere. Every check validated the **value**; nothing validated the
> **location**. `validate_local_scope` in `yaml-helper.sh` now names such keys on
> `resolve_config`'s `notes:` line. It **warns and never reconciles**: it does not
> edit the file, does not begin honouring the key, and does not change
> resolution — a locked setting decides which artifacts exist on disk, so
> applying one quietly would produce exactly the divergence this table prevents.
> A clean file stays silent — you are only told when a key is actually in the
> wrong place.
> **手写进 `project.local.yaml` 的锁定键会被报告，而不是被吞掉。**
> `/settings --local` 拒绝写入一个，但该文件本就打算手工编辑，而那条路径没有护栏：
> 那里的 `modes.rigor: full` 是一个带合法值的真实键，因此枚举校验会放行它，然后
> 解析对该路径从不查阅本地文件 — 设置消失了，用户看到的是他们试图覆盖的
> 默认值，而任何地方都没有错误。每个检查都校验了**值**；没有东西校验
> **位置**。`yaml-helper.sh` 中的 `validate_local_scope` 现在会在
> `resolve_config` 的 `notes:` 行上命名这类键。它**警告而从不调和**：它不
> 编辑文件、不开始遵从该键、也不改变
> 解析 — 锁定设置决定磁盘上存在哪些产物，所以
> 悄悄应用一个恰好会产生此表所防止的分歧。
> 干净的文件保持沉默 — 只有在键确实处于
> 错误位置时才告诉你。

---

### `/settings --local` flag behavior
### `/settings --local` 标志行为

```
/settings workflow=minimal               → writes to project.yaml (team-wide)
/settings --local automation=autonomous  → writes to project.local.yaml (just you)
```

**Behavior rules:**
**行为规则：**

- Default (no flag): writes to `project.yaml`
- 默认（无标志）：写入 `project.yaml`
- `--local` flag: writes to `project.local.yaml` (creates it if absent)
- `--local` 标志：写入 `project.local.yaml`（缺失时创建它）
- `--local` on a locked setting → error:
  > *"`<setting>` cannot be locally overridden — it's a project-wide setting.
  > Use `/settings <setting>=<value>` (no `--local`) to change it for the whole team."*
- 对锁定设置使用 `--local` → 错误：
  > *“`<setting>` 不能在本地覆盖 — 它是项目范围的设置。
  > 使用 `/settings <setting>=<value>`（不加 `--local`）为整个团队更改它。”*
- Writing to `project.yaml` when the same setting is currently locally overridden → warning:
  > *"This setting is currently locally overridden in `project.local.yaml`.
  > Writing to `project.yaml` will not affect your effective value."*
- 当同一设置当前在本地被覆盖时写入 `project.yaml` → 警告：
  > *“此设置当前在 `project.local.yaml` 中被本地覆盖。
  > 写入 `project.yaml` 不会影响你的生效值。”*

---

### Schema validation on read
### 读取时的模式校验

When skills or hooks read either file:
当技能或钩子读取任一文件时：

| Issue | Behavior |
|-------|----------|
| Unknown key (typo or stale setting) | Session-start warning: *"`project.local.yaml` has unknown key `modes.automaton` — typo? Ignored."* Does NOT block (forwards-compat with future settings). |
| Invalid value not in enum (e.g. `automation: chaotic`) | Hard error: skill exits with explanation of valid values. |
| Type mismatch (e.g. integer field set to a string) | Hard error: skill exits with type expected. |

| 问题 | 行为 |
|-------|----------|
| 未知键（拼写错误或过时设置） | 会话启动警告：*“`project.local.yaml` 有未知键 `modes.automaton` — 拼写错误？已忽略。”* 不阻塞（向前兼容未来设置）。 |
| 不在枚举中的无效值（例如 `automation: chaotic`） | 硬错误：技能退出并说明有效值。 |
| 类型不匹配（例如整数字段被设为字符串） | 硬错误：技能退出并说明期望的类型。 |

---

### Creation and error handling
### 创建与错误处理

| Scenario | Behavior |
|----------|----------|
| `/start` on fresh project | Creates `project.yaml` only. Does NOT create `project.local.yaml`. |
| `/settings --local <x>=<y>` when local.yaml doesn't exist | Creates `project.local.yaml` containing just that setting. |
| `project.local.yaml` exists but `project.yaml` doesn't | Hard error: *"`project.yaml` missing — run `/start` to create one. Local overrides require a base."* |
| Both files exist | Read `project.yaml` first, deep-merge `project.local.yaml` on top. Normal operation. |
| Both files set the same key | `project.local.yaml` wins. No prompting. |

| 场景 | 行为 |
|----------|----------|
| 在新项目上运行 `/start` | 仅创建 `project.yaml`。不创建 `project.local.yaml`。 |
| 当 local.yaml 不存在时运行 `/settings --local <x>=<y>` | 创建仅包含该设置的 `project.local.yaml`。 |
| `project.local.yaml` 存在但 `project.yaml` 不存在 | 硬错误：*“`project.yaml` 缺失 — 运行 `/start` 创建一个。本地覆盖需要一个基准。”* |
| 两个文件都存在 | 先读取 `project.yaml`，在其上深度合并 `project.local.yaml`。正常操作。 |
| 两个文件设置同一个键 | `project.local.yaml` 胜出。不提示。 |

---

### Two-developer clash scenarios — and why the whitelist prevents them
### 双开发者冲突场景 — 以及白名单为何防止它们

**File-level conflict (`project.yaml`):**
Standard git merge conflict. Each developer's `project.local.yaml` is gitignored
and never collides with another developer's. Normal git workflow handles team-wide
changes.
**文件级冲突（`project.yaml`）：**
标准 git 合并冲突。每位开发者的 `project.local.yaml` 被 gitignore 忽略，
绝不与另一位开发者的冲突。正常的 git 工作流处理团队范围的
变更。

**Logical inconsistency (prevented by whitelist):**
**逻辑不一致（由白名单防止）：**

Example of what the whitelist prevents:
白名单防止的示例：

> Sarah sets `modes.workflow: minimal` locally to skip GDD requirements. She
> doesn't write GDDs because her local mode doesn't require them. Mike runs
> `/gate-check` with the team's `project.yaml` value, `standard`; gate-check sees missing
> GDDs and fails.
> Sarah 在本地设置 `modes.workflow: minimal` 以跳过 GDD 要求。她
> 不写 GDD，因为她的本地模式不要求它们。Mike 用团队的 `project.yaml` 值 `standard`
> 运行 `/gate-check`；gate-check 看到缺失的
> GDD 并失败。

This can't happen because `modes.workflow` is locked to `project.yaml`. Same
for `qa.level`, `docs.density`, `strict_gate_checks`, `naming.*`, and every
other setting that affects what artifacts exist on disk.
这不会发生，因为 `modes.workflow` 锁定到 `project.yaml`。`qa.level`、
`docs.density`、`strict_gate_checks`、`naming.*` 以及每个
其他影响磁盘上存在哪些产物的设置也是如此。

Personal experience settings (`automation`, `review_mode`, `team.size`,
`testing.strict.*`, `performance.enforce`) can diverge freely without affecting
anyone else.
个人体验设置（`automation`、`review_mode`、`team.size`、
`testing.strict.*`、`performance.enforce`）可以自由分歧而不影响
其他任何人。

---

### Stricter reviewer reviewing a looser reviewer's work
### 更严格的评审者审查更宽松评审者的工作

A common worry: "what if my teammate has stricter review settings than me?
Will their `/gate-check` or `/design-review` flag things in my work?"
一个常见的担忧：“如果我的队友有比我更严格的评审设置呢？
他们的 `/gate-check` 或 `/design-review` 会在我的工作中标记东西吗？”

The answer depends on which kind of difference you're talking about:
答案取决于你谈论的是哪种差异：

**Different review depth, same project requirements (HEALTHY):**
**不同的评审深度，相同的项目要求（健康）：**

- Teammate A: local `review_mode: full`, `automation: collaborative`, `testing.strict.logic: true`
- 队友 A：本地 `review_mode: full`、`automation: collaborative`、`testing.strict.logic: true`
- Teammate B: local `review_mode: solo`, `automation: autonomous`, `testing.strict.logic: false`
- 队友 B：本地 `review_mode: solo`、`automation: autonomous`、`testing.strict.logic: false`
- Both bound by the same project.yaml-locked settings (e.g. `workflow: standard`, `qa.level: standard`)
- 两者都受相同的 project.yaml 锁定设置约束（例如 `workflow: standard`、`qa.level: standard`）

B writes a GDD that meets `workflow: standard` (all 5 required sections present).
B's `/design-review` runs with `review_mode: solo` — fast advisory check, no
specialists spawned. B moves on.
B 写了一份满足 `workflow: standard` 的 GDD（全部 5 个必需章节都在）。
B 的 `/design-review` 以 `review_mode: solo` 运行 — 快速的建议性检查，不
生成专家。B 继续。

Later A reviews the same GDD with `review_mode: full` — spawns 5–15 specialists,
finds polish opportunities and edge cases B's lighter review missed. A files
findings as PR comments or follow-up issues. B addresses the ones that matter.
后来 A 以 `review_mode: full` 评审同一份 GDD — 生成 5–15 个专家，
发现 B 较轻评审遗漏的打磨机会和边缘情况。A 将
发现作为 PR 评论或后续问题提交。B 处理真正重要的那些。

**This is normal team collaboration.** Different reviewers catching different
things is the value of having multiple reviewers. The artifacts on disk are the
same; only review depth differs. Nothing about this scenario creates project-state
divergence.
**这是正常的团队协作。** 不同的评审者捕捉不同的
东西，这正是拥有多个评审者的价值。磁盘上的产物是
相同的；只有评审深度不同。这个场景没有任何东西造成项目状态
分歧。

**Different requirements (PREVENTED by the whitelist):**
**不同的要求（由白名单防止）：**

If `qa.level` were locally overridable:
如果 `qa.level` 可在本地覆盖：

- B sets `qa.level: minimal` locally. B's stories don't include test evidence.
- B 在本地设置 `qa.level: minimal`。B 的 story 不包含测试证据。
- B's `/story-done` accepts the story without evidence. Story marked Complete on disk.
- B 的 `/story-done` 在没有证据的情况下接受 story。Story 在磁盘上被标记为 Complete。
- A pulls. A's `qa.level: standard` requires evidence. A's `/story-done` would have rejected it.
- A 拉取。A 的 `qa.level: standard` 要求证据。A 的 `/story-done` 本会拒绝它。
- A's next `/gate-check` fails because evidence is missing across multiple of B's "Complete" stories.
- A 的下一次 `/gate-check` 失败，因为 B 的多个“Complete”story 都缺少证据。

This is the artifact divergence problem. To prevent it, `qa.level` is locked to
`project.yaml`. The team agrees together on what's required; individuals override
only their personal experience, never the team's standards.
这就是产物分歧问题。为防止它，`qa.level` 锁定到
`project.yaml`。团队共同就要求什么达成一致；个人只覆盖
自己的个人体验，绝不覆盖团队的标准。

**The pattern to remember:**
**要记住的模式：**

| Difference type | Outcome |
|----------------|---------|
| Different review depth (review_mode, team.size) | Stricter reviewer surfaces more findings — healthy. Artifacts unchanged. |
| Different local strictness on failures (testing.strict.*, performance.enforce) | Stricter dev's local /story-done blocks earlier — they fix it locally. CI uses project.yaml defaults so team-wide quality bar stays. |
| Different artifact requirements (workflow, qa.level, docs.density, etc.) | **Can't happen — these are locked.** Team agrees once in project.yaml. |

| 差异类型 | 结果 |
|----------------|---------|
| 不同的评审深度（review_mode、team.size） | 更严格的评审者浮现更多发现 — 健康。产物不变。 |
| 对失败的不同本地严格度（testing.strict.*、performance.enforce） | 更严格开发者的本地 /story-done 更早阻塞 — 他们在本地修复。CI 使用 project.yaml 默认值，因此团队范围的质量门槛保持不变。 |
| 不同的产物要求（workflow、qa.level、docs.density 等） | **不可能发生 — 这些被锁定。** 团队在 project.yaml 中一致同意一次。 |

---

### CI behavior
### CI 行为

CI environments have no `project.local.yaml` — the file is gitignored and never
present in a fresh clone. CI therefore always runs against `project.yaml`
defaults: strict project standards, no developer-specific overrides.
CI 环境没有 `project.local.yaml` — 该文件被 gitignore 忽略，在
全新克隆中从不出现。因此 CI 始终针对 `project.yaml`
默认值运行：严格的项目标准，没有开发者特定的覆盖。

This is intentional and important:
这是有意且重要的：

| Setting | Local default for fast iteration | CI default (`project.yaml`) |
|---------|----------------------------------|------------------------------|
| `modes.review_mode` (locally overridable) | `solo` for one developer | `lean` (a team's usual choice — phase gates always run) |
| `testing.strict.logic` (locally overridable) | `false` for fast WIP commits | `true` (failing tests block CI) |
| `modes.automation` (locally overridable) | `autonomous` for solo flow | `collaborative` (the team's collab protocol, but CI doesn't ask questions anyway — this is mostly a no-op on CI) |

| 设置 | 快速迭代的本地默认值 | CI 默认值（`project.yaml`） |
|---------|----------------------------------|------------------------------|
| `modes.review_mode`（可本地覆盖） | 为单个开发者使用 `solo` | `lean`（团队的常见选择 — 阶段门禁始终运行） |
| `testing.strict.logic`（可本地覆盖） | 为快速 WIP 提交使用 `false` | `true`（失败的测试阻塞 CI） |
| `modes.automation`（可本地覆盖） | 单人流程使用 `autonomous` | `collaborative`（团队的协作协议，但 CI 反正不问问题 — 这在 CI 上大多是无操作） |

A developer can iterate locally with relaxed gates, but CI catches issues using
the strict project defaults. The team's quality bar is enforced at the CI level
regardless of any individual developer's local config.
开发者可以在本地以放宽的门禁迭代，但 CI 使用
严格的项目默认值捕捉问题。团队的质量门槛在 CI 层面执行，
无论任何单个开发者的本地配置如何。

---

### Secrets — never in either file
### 秘密 — 绝不在任一文件中

`project.yaml` and `project.local.yaml` are for **preferences and configuration**,
never for **secrets**. API keys, tokens, and credentials belong in:
`project.yaml` 和 `project.local.yaml` 用于**偏好与配置**，
绝不用于**秘密**。API 密钥、令牌和凭证属于：

- **Environment variables** (preferred for production/CI)
- **环境变量**（生产/CI 首选）
- **`.env` file** (gitignored, local dev)
- **`.env` 文件**（被 gitignore 忽略，本地开发）
- **OS keychain** (when integrating with services that support it)
- **操作系统钥匙串**（与支持它的服务集成时）

When a skill needs an API key (e.g. `/asset-spec` calling Midjourney), it reads
from the environment, not from `project.yaml`. `project.yaml` only stores **which**
generator is used (`art.generator: midjourney`), not the API key for it.
当技能需要 API 密钥时（例如 `/asset-spec` 调用 Midjourney），它从
环境读取，而不是从 `project.yaml`。`project.yaml` 只存储**使用哪个**
生成器（`art.generator: midjourney`），不存储它的 API 密钥。

CI environments typically have no `project.local.yaml` (gitignored, not in the
clone) — so CI always runs against `project.yaml` defaults. This is correct
behavior: strict project defaults for CI, looser developer overrides for local work.
CI 环境通常没有 `project.local.yaml`（被 gitignore 忽略，不在
克隆中）— 所以 CI 始终针对 `project.yaml` 默认值运行。这是正确的
行为：CI 使用严格的项目默认值，本地工作使用更宽松的开发者覆盖。

---

## modes.review_mode
## modes.review_mode

**Controls:** How many specialist and director agents are spawned during skill execution  
**Values:** `full` | `lean` | `solo`  
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `solo`; `standard` yields `lean`; `full` yields `full`)  
**Set by:** `/settings`, or `migrate-v1-config.sh` (which `/adopt` runs) when it carries over a v1.0 `production/review-mode.txt`. `/start` and `/adopt` never write it themselves — unset, it follows `modes.rigor`  
**Read by:** See skill table below
**控制：** 技能执行期间生成多少个专家和总监智能体
**取值：** `full` | `lean` | `solo`
**默认：** *无* — 由 `modes.rigor` 提供（默认的 `minimal` 产出 `solo`；`standard` 产出 `lean`；`full` 产出 `full`）
**由谁设置：** `/settings`，或 `migrate-v1-config.sh`（由 `/adopt` 运行）在沿用 v1.0 的 `production/review-mode.txt` 时设置。`/start` 和 `/adopt` 从不自己写入它 — 未设置时，它遵循 `modes.rigor`
**由谁读取：** 见下面的技能表

**Priority chain (all skills):** inline argument flag → `modes.review_mode` in `project.yaml` → `production/review-mode.txt` (legacy fallback) → `modes.rigor` expansion (no terminal default; `minimal`→`solo`, `standard`→`lean`, `full`→`full`)
**优先级链（所有技能）：** 内联参数标志 → `project.yaml` 中的 `modes.review_mode` → `production/review-mode.txt`（旧版回退）→ `modes.rigor` 扩展（无终端默认值；`minimal`→`solo`、`standard`→`lean`、`full`→`full`）

> **design-review follows the standard chain.** `modes.review_mode` controls
> design-review depth, its inline flag is `--review` for consistency with every
> other review-mode-aware skill, and with nothing set it follows `modes.rigor` like
> them: `solo` at `minimal` (the default), `lean` at `standard`.
> **design-review 遵循标准链。** `modes.review_mode` 控制
> design-review 深度，其内联标志是 `--review`，以与每个
> 其他感知评审模式的技能保持一致，并且在什么也没设置时像它们一样遵循 `modes.rigor`：
> `minimal`（默认）时为 `solo`，`standard` 时为 `lean`。

> **Hotfix / day-one-patch exception:** These skills are emergency or release-critical
> pipelines. They are never gated by `review_mode` — all agents always run.
> **Hotfix / day-one-patch 例外：** 这些技能是紧急或发布关键的
> 流程。它们从不受 `review_mode` 门禁 — 所有智能体始终运行。

> **`review_mode` in the nine `team-*` orchestrators.** `review_mode` sets
> director-gate depth: `full` spawns every director gate a pipeline names, `lean`
> skips director gates unless they are PHASE-GATE type, and `solo` skips gate
> spawning entirely. No team pipeline spawns a PHASE-GATE (`/gate-check` is their
> only spawner), so in the orchestrators
> `lean` and `solo` behave the same, and `full` adds two things:
> `/team-release`'s technical-director release sign-off, and, at
> `team.size: small`, `/team-narrative`'s `localization-lead` and `world-builder`.
> **九个 `team-*` 编排器中的 `review_mode`。** `review_mode` 设置
> 总监门禁深度：`full` 生成流程命名的每个总监门禁，`lean`
> 跳过总监门禁，除非它们是 PHASE-GATE 类型，而 `solo` 完全跳过门禁
> 生成。没有团队流程生成 PHASE-GATE（`/gate-check` 是它们
> 唯一的生成者），因此在编排器中
> `lean` 和 `solo` 行为相同，而 `full` 增加两件事：
> `/team-release` 的技术总监发布签字，以及在
> `team.size: small` 时，`/team-narrative` 的 `localization-lead` 和 `world-builder`。
>
> Outside the orchestrators, the skills in the *Core skills* table below read
> `review_mode` as that table documents.
> 在编排器之外，下面*核心技能*表中的技能按该表记录的方式读取
> `review_mode`。

---

### Value intent
### 取值意图

| Value | Intent |
|-------|--------|
| `full` | All director and specialist gates active. Best for teams, learning, or anyone who wants thorough AI feedback on every decision. |
| `lean` | Phase gates only — per-skill director sign-offs skipped. The `rigor: standard` value. Balances quality with token cost. |
| `solo` | No gates, no director spawns (a pipeline's own review, such as `/team-narrative`'s ND-CONSISTENCY, still runs). Fastest. For confident solo iteration. The default, from `rigor: minimal`. |

| 取值 | 意图 |
|-------|--------|
| `full` | 所有总监和专家门禁启用。最适合团队、学习，或任何想要对每个决策获得详尽 AI 反馈的人。 |
| `lean` | 仅阶段门禁 — 跳过按技能的总监签字。`rigor: standard` 的值。平衡质量与 token 成本。 |
| `solo` | 无门禁、无总监生成（流程自身的评审仍会运行，例如 `/team-narrative` 的 ND-CONSISTENCY）。最快。适合自信的单人迭代。默认值，来自 `rigor: minimal`。 |

---

### Core skills (currently review-mode aware)
### 核心技能（当前感知评审模式）

| Skill | full | lean | solo |
|-------|------|------|------|
| **design-review** | 5–15 specialist agents spawned in Phase 3b | No specialist agents — single-session analysis only | Phases 1–4 only, no delegation, no next-steps prompt |
| **gate-check** | Director panel runs in parallel — **width set by `modes.workflow`**, not by this axis | Director panel runs in parallel — same width rule; phase gates always run | Artifact existence checks only, no directors spawned |
| **design-system** | All section specialists + CD-GDD-ALIGN sign-off gate | Specialists for Sections D and H only (+ G when its knobs interact, + Visual/Audio when visual feedback is central); CD-GDD-ALIGN skipped | No section specialists; CD-GDD-ALIGN skipped |
| **art-bible** | All section specialists + AD-ART-BIBLE sign-off gate | All section specialists, AD-ART-BIBLE skipped | All section specialists, AD-ART-BIBLE skipped |
| **architecture-decision** | Engine specialist + TD-ADR gate | Engine specialist; TD-ADR skipped | Engine specialist; TD-ADR skipped |
| **create-architecture** | TD-ARCHITECTURE + LP-FEASIBILITY agents, in parallel | Both skipped | Both skipped |
| **brainstorm** | CD-PILLARS, AD-CONCEPT-VISUAL, TD-FEASIBILITY, PR-SCOPE | All skipped | All skipped |
| **map-systems** | TD-SYSTEM-BOUNDARY, PR-SCOPE, CD-SYSTEMS | All skipped | All skipped |
| **story-done** | QL-TEST-COVERAGE + LP-CODE-REVIEW | Both skipped | Both skipped |
| **sprint-plan** | PR-SPRINT feasibility check | Skipped | Skipped |
| **create-epics** | PR-EPIC scope check | Skipped | Skipped |
| **create-stories** | QL-STORY-READY + test case specs | Skipped | Skipped |
| **prototype** | CD-PLAYTEST review — APPROVE keeps the recommendation; CONCERNS and REJECT go to the user, who decides | Skipped — the recommendation stands unreviewed | Skipped — the recommendation stands unreviewed |
| **milestone-review** | PR-MILESTONE feasibility check | Skipped — no producer verdict | Skipped — no producer verdict |
| **playtest-report** | CD-PLAYTEST creative assessment | Skipped | Skipped |
| **story-readiness** | QL-STORY-READY acceptance criteria check | Skipped | Skipped |
| **create-control-manifest** | TD-MANIFEST (technical-director) review | Skipped | Skipped |
| **propagate-design-change** | TD-CHANGE-IMPACT (technical-director) review | Skipped | Skipped |

| 技能 | full | lean | solo |
|-------|------|------|------|
| **design-review** | 在 Phase 3b 生成 5–15 个专家智能体 | 无专家智能体 — 仅单会话分析 | 仅 Phase 1–4，无委派，无下一步提示 |
| **gate-check** | 总监小组并行运行 — **宽度由 `modes.workflow` 设定**，不由此轴设定 | 总监小组并行运行 — 同样的宽度规则；阶段门禁始终运行 | 仅产物存在性检查，不生成总监 |
| **design-system** | 所有章节专家 + CD-GDD-ALIGN 签字门禁 | 仅 D 和 H 节的专家（当 G 的旋钮相互作用时加上 G，当视觉反馈是核心时加上 Visual/Audio）；跳过 CD-GDD-ALIGN | 无章节专家；跳过 CD-GDD-ALIGN |
| **art-bible** | 所有章节专家 + AD-ART-BIBLE 签字门禁 | 所有章节专家，跳过 AD-ART-BIBLE | 所有章节专家，跳过 AD-ART-BIBLE |
| **architecture-decision** | 引擎专家 + TD-ADR 门禁 | 引擎专家；跳过 TD-ADR | 引擎专家；跳过 TD-ADR |
| **create-architecture** | TD-ARCHITECTURE + LP-FEASIBILITY 智能体并行 | 两者都跳过 | 两者都跳过 |
| **brainstorm** | CD-PILLARS、AD-CONCEPT-VISUAL、TD-FEASIBILITY、PR-SCOPE | 全部跳过 | 全部跳过 |
| **map-systems** | TD-SYSTEM-BOUNDARY、PR-SCOPE、CD-SYSTEMS | 全部跳过 | 全部跳过 |
| **story-done** | QL-TEST-COVERAGE + LP-CODE-REVIEW | 两者都跳过 | 两者都跳过 |
| **sprint-plan** | PR-SPRINT 可行性检查 | 跳过 | 跳过 |
| **create-epics** | PR-EPIC 范围检查 | 跳过 | 跳过 |
| **create-stories** | QL-STORY-READY + 测试用例规格 | 跳过 | 跳过 |
| **prototype** | CD-PLAYTEST 评审 — APPROVE 保留建议；CONCERNS 和 REJECT 交给用户，由用户决定 | 跳过 — 建议未经评审地保留 | 跳过 — 建议未经评审地保留 |
| **milestone-review** | PR-MILESTONE 可行性检查 | 跳过 — 无制作人裁决 | 跳过 — 无制作人裁决 |
| **playtest-report** | CD-PLAYTEST 创意评估 | 跳过 | 跳过 |
| **story-readiness** | QL-STORY-READY 验收标准检查 | 跳过 | 跳过 |
| **create-control-manifest** | TD-MANIFEST（技术总监）评审 | 跳过 | 跳过 |
| **propagate-design-change** | TD-CHANGE-IMPACT（技术总监）评审 | 跳过 | 跳过 |

---

### Skills that do not read `modes.review_mode`
### 不读取 `modes.review_mode` 的技能

These skills run the same way at `full`, `lean` and `solo`. None of them takes a
`--review` flag.
这些技能在 `full`、`lean` 和 `solo` 下以相同方式运行。它们都不接受
`--review` 标志。

| Skill | What runs at every level |
|-------|--------------------------|
| **review-all-gdds** | Phase 2 consistency pass and Phase 3 design-theory pass, in parallel |
| **architecture-review** | The primary engine specialist is consulted after the engine audit (recorded as NOT ASSESSED when no engine is configured) |
| **dev-story** | Core programmer routing, plus the engine specialist's check of every code story |
| **code-review** | Language, shader and UI specialists when an engine is configured, plus `qa-tester` for Logic and Integration stories |
| **security-audit** | `security-engineer` is spawned to run the audit |

| 技能 | 每个层级下运行的内容 |
|-------|--------------------------|
| **review-all-gdds** | Phase 2 一致性通过和 Phase 3 设计理论通过，并行执行 |
| **architecture-review** | 引擎审计后咨询主引擎专家（未配置引擎时记录为 NOT ASSESSED） |
| **dev-story** | 核心程序员路由，加上引擎专家对每个代码 story 的检查 |
| **code-review** | 配置引擎时的语言、着色器和 UI 专家，加上针对 Logic 和 Integration story 的 `qa-tester` |
| **security-audit** | 生成 `security-engineer` 来运行审计 |

---

### Team orchestration skills (pipeline behavior — different relationship)
### 团队编排技能（流程行为 — 不同关系）

Team skills are execution pipelines, not review gates. In them `review_mode` sets
only director-gate depth; `team.size` picks the agents (see `## team.size`), and a
pipeline's own review steps run in every mode.
团队技能是执行流程，不是评审门禁。在其中 `review_mode` 只设置
总监门禁深度；`team.size` 选择智能体（见 `## team.size`），而
流程自身的评审步骤在每种模式下都运行。

| Skill | full | lean | solo |
|-------|------|------|------|
| **All nine `team-*`** | Every director gate the pipeline names | PHASE-GATE-type gates only | No director gates |
| **team-release** | + technical-director release sign-off before the go/no-go call | Sign-off not run — recorded as `not run (review_mode: lean)` | Sign-off not run — recorded as `not run (review_mode: solo)` |
| **team-narrative** | ND-CONSISTENCY; at `team.size: small`, + `localization-lead` and `world-builder` | ND-CONSISTENCY; at `small`, `narrative-director` + `writer` only | ND-CONSISTENCY still runs when `narrative-director` is active |

| 技能 | full | lean | solo |
|-------|------|------|------|
| **全部九个 `team-*`** | 流程命名的每个总监门禁 | 仅 PHASE-GATE 类型门禁 | 无总监门禁 |
| **team-release** | + 在 go/no-go 决定前的技术总监发布签字 | 不运行签字 — 记录为 `not run (review_mode: lean)` | 不运行签字 — 记录为 `not run (review_mode: solo)` |
| **team-narrative** | ND-CONSISTENCY；在 `team.size: small` 时，+ `localization-lead` 和 `world-builder` | ND-CONSISTENCY；在 `small` 时，仅 `narrative-director` + `writer` | 当 `narrative-director` 激活时 ND-CONSISTENCY 仍运行 |

---

### Special cases and notes
### 特殊情况与说明

- **gate-check** is the only skill where `full` and `lean` behave identically —
  phase gates always run. Only `solo` skips them. This is intentional: phase
  gates are the minimum quality bar, not optional extras. **How many directors
  run is a separate axis** — `modes.workflow` sets panel width (`minimal` → PR
  only, `standard` → TD + PR, `full` → all four), because directors are
  Opus-tier and a small project should not pay for the same four-director panel
  as a large one. Width never softens a verdict: the strictest verdict from
  whoever ran still wins, and `/gate-check` names the perspectives it skipped.
- **gate-check** 是唯一一个 `full` 和 `lean` 行为完全相同的技能 —
  阶段门禁始终运行。只有 `solo` 跳过它们。这是有意的：阶段
  门禁是最低质量门槛，不是可选附加项。**运行多少总监
  是一个单独的轴** — `modes.workflow` 设置小组宽度（`minimal` → 仅 PR，
  `standard` → TD + PR，`full` → 全部四个），因为总监是
  Opus 层级，小项目不应为大项目那样的四人总监小组
  付同样的代价。宽度绝不软化裁决：无论谁运行，最严格的裁决仍然
  胜出，而 `/gate-check` 会指明它跳过的视角。
- **art-bible** always spawns its section specialists regardless of mode — only
  the final sign-off gate is controlled by `review_mode`. Specialist delegation is
  mandatory for the authoring output to be useful, and that has not changed.
  **design-system** is different: `lean` keeps the specialists for its high-risk
  sections only (D and H, plus G and Visual/Audio when they matter) and `solo`
  drafts every section without one, and each skipped spawn is announced by name.
  What sets `art-bible`'s **spawn count** is therefore not `review_mode`
  but (a) `modes.workflow`, via how many sections get authored at all — `standard`
  requires sections 1–4, not all 9, and Phase 1 recommends the tier's set — and
  (b) batching consecutive sections that call the *same* agent with the *same*
  input into one delegation (2–4, and 5–6). Unbatched, sections 5 and 6 spawn
  `art-director` twice with the identical `sections 1–4` brief. Every section is
  still specialist-authored; per-section approval and write-to-file are unchanged.
- **art-bible** 无论模式如何都始终生成其章节专家 — 只有
  最终的签字门禁由 `review_mode` 控制。专家委派对于
  创作产出有用是必需的，这一点没有改变。
  **design-system** 不同：`lean` 只保留其高风险
  章节（D 和 H，加上在重要时的 G 和 Visual/Audio）的专家，而 `solo`
  在没有专家的情况下起草每个章节，且每次跳过的生成都会按名称宣布。
  因此决定 `art-bible` **生成数量** 的不是 `review_mode`，
  而是 (a) `modes.workflow`，通过总共创作多少章节 — `standard`
  要求章节 1–4，而不是全部 9 个，且 Phase 1 推荐该层级的集合 — 以及
  (b) 将调用*相同*智能体、传入*相同*输入的连续章节批处理为
  一次委派（2–4，以及 5–6）。不批处理时，章节 5 和 6 会用完全相同的
  `sections 1–4` 简报生成两次 `art-director`。每个章节
  仍然由专家创作；逐章节批准和写入文件保持不变。
- **dev-story** core programmer routing (gameplay-programmer, ui-programmer, etc.)
  always runs regardless of mode — only the optional engine-specialist escalation
  for HIGH risk stories is gated.
- **dev-story** 核心程序员路由（gameplay-programmer、ui-programmer 等）
  无论模式如何都始终运行 — 只有针对 HIGH 风险 story 的可选引擎专家升级
  被门禁。
- **hotfix** and **day-one-patch** are exempt — all agents always run.
- **hotfix** 和 **day-one-patch** 被豁免 — 所有智能体始终运行。
- When a gate is skipped, skills emit: `"[GATE-ID] skipped — [mode] mode."` before
  proceeding. This is consistent across all skills.
- 当门禁被跳过时，技能会发出：`"[GATE-ID] skipped — [mode] mode."` 然后
  继续。这在所有技能中一致。

---

## modes.rigor
## modes.rigor

**Controls:** How much process the project carries overall — the single question
`/start` asks that sets the six knobs below
**Values:** `minimal` | `standard` | `full`
**Default:** `minimal` — see the rationale block above `_yaml_helper_defaults`
in `.claude/hooks/yaml-helper.sh`. Short version: the heavier tier costs more to
reach working code without producing a better result.
**Set by:** `/start` (Phase 4: inferred from the user's description, shown, saved on a yes), `/settings`
**Read by:** nothing directly — it is read *through* the six knobs it supplies
**控制：** 项目整体承载多少流程 — `/start` 提出的那个设置以下六个旋钮的单一问题
**取值：** `minimal` | `standard` | `full`
**默认：** `minimal` — 见 `.claude/hooks/yaml-helper.sh` 中 `_yaml_helper_defaults`
上方的理由块。简版：更重的层级要花更多成本才能到达可运行的代码，却不产生更好的结果。
**由谁设置：** `/start`（Phase 4：从用户描述推断、展示、在肯定时保存）、`/settings`
**由谁读取：** 无直接读取 — 它*通过*所提供的六个旋钮被读取

**Priority chain:** `modes.rigor` in `project.yaml` → hardcoded default `minimal`
(**locked** — not overridable from `project.local.yaml`, like the four *on-disk*
knobs it fronts — `modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity` — because those five change what artifacts exist on
disk. The two personal-experience knobs it also fronts, `modes.review_mode` and
`team.size`, stay locally overridable.)
**优先级链：** `project.yaml` 中的 `modes.rigor` → 硬编码默认值 `minimal`
（**锁定** — 不能从 `project.local.yaml` 覆盖，就像它前置的四个*磁盘*旋钮 —
`modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity` — 因为这五个
改变磁盘上存在哪些产物。它同时前置的两个个人体验旋钮 `modes.review_mode` 和
`team.size` 仍可本地覆盖。）

---

### Expansion table
### 扩展表

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` *(default)* | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` *（默认）* | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

### It fronts, it does not replace
### 它前置，但不替代

The expansion sits **below every explicit source and above the terminal
default**:
扩展位于**每个显式来源之下、终端默认值之上**：

```
project.local.yaml → project.yaml → legacy file → rigor expansion → default
```

That ordering is the back-compat guarantee, and it is what makes the migration
free. Three consequences worth stating plainly:
该排序是向后兼容的保证，也是使迁移
免费的原因。三个值得直说的后果：

- **An existing `project.yaml` behaves identically.** If it already sets
  `docs.density: terse`, step 2 answers before the expansion is consulted — so
  the value and its reported source (`project.yaml`) are unchanged whether or not
  `rigor` is present. No migration, no `schema_version` bump.
- **现有的 `project.yaml` 行为完全相同。** 如果它已经设置
  `docs.density: terse`，步骤 2 在咨询扩展之前就给出答案 — 所以
  无论 `rigor` 是否存在，该值及其报告的来源（`project.yaml`）都不变。
  无需迁移，无需提升 `schema_version`。
- **Overrides go both ways.** Unlike the `workflow_overrides` **boolean flags** —
  which are additive and stricter-only — an explicit knob may be *looser* than
  the rigor level implies.
  (`workflow_overrides.system_overrides` is also two-directional — it replaces a tier; only the flags are stricter-only.)
  Inheriting the stricter-only rule would make "comprehensive but compact"
  inexpressible, which is the one off-diagonal the docs have always cited.
- **覆盖是双向的。** 与 `workflow_overrides` 的**布尔标志**不同 —
  后者是附加的且仅更严格 — 显式旋钮可以比
  严谨度层级所暗示的*更宽松*。
  （`workflow_overrides.system_overrides` 也是双向的 — 它替换层级；只有标志是仅更严格。）
  继承仅更严格的规则会使“全面但紧凑”
  无法表达，而这是文档一直引用的唯一非对角项。
- **`modes.workflow` keeps `workflow_overrides.system_overrides`.** Per-system
  tiers still beat the rigor-derived project tier. `workflow` was fronted rather
  than folded away precisely because it drives ~5 distinct behaviors and owns the
  only per-system override mechanism.
- **`modes.workflow` 保留 `workflow_overrides.system_overrides`。** 按系统的
  层级仍然胜过从严谨度派生的项目层级。`workflow` 被前置
  而不是折叠掉，正是因为它驱动约 5 种不同行为，并拥有
  唯一的按系统覆盖机制。

The six fronted knobs therefore have **no entry in `_yaml_helper_defaults`**. A
terminal default there would answer before the expansion and make `rigor` a no-op
for anyone who had not also set the sub-knob.
因此这六个被前置的旋钮在 `_yaml_helper_defaults` 中**没有条目**。那里的
终端默认值会在扩展之前给出答案，并使 `rigor` 对任何没有同时设置子旋钮的人
成为无操作。

### Provenance
### 来源

Derived values report their source as `rigor:<level>`, so the vocabulary is
`{project.local.yaml, project.yaml, <legacy path>, rigor:<level>, default,
unset}`. `/settings` renders this as `(derived from rigor: standard)` and
force-appends the five to its view-all list — none of them is a leaf of either
YAML file, so enumerating file leaves alone would hide exactly the settings the
user just chose.
派生值将其来源报告为 `rigor:<level>`，因此词汇表是
`{project.local.yaml, project.yaml, <legacy path>, rigor:<level>, default,
unset}`。`/settings` 将其渲染为 `(derived from rigor: standard)`，并
强制将这五个追加到其全部查看列表 — 它们都不是任一
YAML 文件的叶子，所以仅枚举文件叶子会恰好隐藏
用户刚刚选择的设置。

---

## modes.workflow
## modes.workflow

**Controls:** How much design documentation is required before code can begin —
the tradeoff between token/time cost of documentation and speed of reaching
working code  
**Values:** `full` | `standard` | `minimal`  
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `minimal`; `standard` yields `standard`; `full` yields `full`)  
**Set by:** `/start` (via `modes.rigor`), `/settings`  
**Read by:** See skill tables below
**控制：** 代码开始前需要多少设计文档 —
文档的 token/时间成本与到达可运行代码的速度之间的权衡
**取值：** `full` | `standard` | `minimal`
**默认：** *无* — 由 `modes.rigor` 提供（默认的 `minimal` 产出 `minimal`；`standard` 产出 `standard`；`full` 产出 `full`）
**由谁设置：** `/start`（通过 `modes.rigor`）、`/settings`
**由谁读取：** 见下面的技能表

**Priority chain:** `modes.workflow` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*
**优先级链：** `project.yaml` 中的 `modes.workflow` → `modes.rigor` 扩展 → *（无硬编码默认值）*

> **Why the middle level is `standard`, not `indie`.** A developer-type label
> would conflate "type of developer" with "level of process". `standard`
> describes the *amount of process*, not the user, and pairs cleanly with
> `minimal` and `full`.
> **为什么中间层级是 `standard`，不是 `indie`。** 开发者类型标签
> 会把“开发者类型”与“流程层级”混为一谈。`standard`
> 描述的是*流程的量*，而不是用户，并且与
> `minimal` 和 `full` 搭配得干净。

> **Permissive, not restrictive:** `workflow` controls what is REQUIRED —
> not what is ALLOWED. Any skill can be run at any workflow level. The
> setting changes what gate-check enforces and what completeness checks
> validate, not what the user can invoke.
> **宽容而非限制：** `workflow` 控制什么是必需的 —
> 而不是什么是允许的。任何技能都可以在任何工作流层级运行。该
> 设置改变 gate-check 执行什么以及完整性检查
> 校验什么，而不是用户可以调用什么。

> **`minimal` floor:** Even in minimal mode, engine choice and a filled
> **`design/game-brief.md`** are required before code starts — the brief's
> build-order field is the plan, so there is no separate `sprint-plan` step.
> Both take minutes and prevent real problems downstream. Everything else can
> be skipped.
> **`minimal` 下限：** 即使在 minimal 模式下，引擎选择和填好的
> **`design/game-brief.md`** 也是代码开始前必需的 — 简报的
> 构建顺序字段就是计划，所以没有单独的 `sprint-plan` 步骤。
> 两者都只需几分钟，并能防止下游的真实问题。其他一切都可以
> 跳过。

> **Escape hatches via `workflow_overrides`:** Users who want *almost* the
> standard set with one extra requirement (e.g. always force Edge Cases) use
> `workflow_overrides` rather than escalating to `full`. See next section.
> **通过 `workflow_overrides` 的逃生舱：** 想要*几乎*标准集合
> 再加一个额外要求（例如始终强制 Edge Cases）的用户使用
> `workflow_overrides`，而不是升级到 `full`。见下一节。

---

### Value intent
### 取值意图

| Value | Token/time cost | Required before code | Best for |
|-------|----------------|---------------------|----------|
| `full` | High | All 8 GDD sections per system, full architecture, all ADRs, art bible, UX specs per screen | Projects where design correctness matters more than speed — teams, commercial titles, learning the full pipeline |
| `standard` | Balanced | 5 GDD sections per system, one architecture doc, critical ADRs, game concept, systems index | Projects that have outgrown a brief — several interacting systems, or a design someone else has to implement |
| `minimal` | Low | One-page `design/game-brief.md` + engine choice (build order in the brief = the plan; no separate sprint plan) | **Default.** Get to code fast — small scope, jam projects, or the design already in your head. Raise it when the project grows |

| 取值 | Token/时间成本 | 代码前必需 | 最适合 |
|-------|----------------|---------------------|----------|
| `full` | 高 | 每个系统全部 8 个 GDD 章节、完整架构、全部 ADR、美术圣经、每屏 UX 规格 | 设计正确性比速度更重要的项目 — 团队、商业作品、学习完整流程 |
| `standard` | 平衡 | 每个系统 5 个 GDD 章节、一份架构文档、关键 ADR、游戏概念、系统索引 | 已超出简报范围的项目 — 多个相互作用的系统，或需要别人实现的设计 |
| `minimal` | 低 | 一页 `design/game-brief.md` + 引擎选择（简报中的构建顺序 = 计划；无单独冲刺计划） | **默认。** 快速进入编码 — 小范围、Game Jam 项目，或设计已在脑中。项目增长时提高它 |

**standard required GDD sections:** Overview, Detailed Rules, Edge Cases, Dependencies,
Acceptance Criteria.
**standard 必需的 GDD 章节：** Overview、Detailed Rules、Edge Cases、Dependencies、
Acceptance Criteria。

**standard conditional:** Formulas — required when the system **defines numeric
rules**: rates, curves, thresholds, costs, damage, drop weights, or any value a
balance pass would tune. Optional only when the system defines no such value.
**standard 条件项：** Formulas — 当系统**定义数值规则**时必需：
速率、曲线、阈值、成本、伤害、掉落权重，或任何平衡调整会调节的值。
仅当系统不定义此类值时才可选。

> **The test is what the system defines, not what it is called.** The `Category`
> column in `systems-index.md` is a *hint* — `Gameplay`, `Economy` and
> `Progression` systems almost always qualify — but it is not the test, and a
> `Core`, `UI` or `Persistence` system that defines a numeric rule qualifies too.
> **判断依据是系统定义什么，而不是它被叫作什么。** `systems-index.md` 中的 `Category`
> 列是一个*提示* — `Gameplay`、`Economy` 和 `Progression` 系统几乎总符合 — 但它不是判据，
> 一个定义了数值规则的 `Core`、`UI` 或 `Persistence` 系统同样符合。
>
> Do not restate it as "required when system category is combat, economy,
> progression, or AI". Those four tokens are not the vocabulary `/map-systems`
> writes: `templates/systems-index.md` defines the categories as `Core ·
> Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative ·
> Meta`, and lists **combat and AI as example systems under `Gameplay`**. A
> combat system categorised exactly as the template instructs therefore matched
> none of the four, and Formulas was silently dropped for the system most likely
> to need it. `coding-standards.md` and `rules/design-docs.md` already stated the
> "has math" test; the skills are reconciled to them rather than the other way
> round.
> 不要把它重述为“当系统类别是 combat、economy、progression 或 AI 时必需”。
> 这四个词不是 `/map-systems` 写入的词汇：`templates/systems-index.md` 将类别定义为
> `Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative ·
> Meta`，并列出**combat 和 AI 作为 `Gameplay` 下的示例系统**。因此，一个完全按模板
> 指示分类的战斗系统不匹配这四个中的任何一个，而 Formulas 恰恰在最可能需要它的
> 系统上被静默丢弃了。`coding-standards.md` 和 `rules/design-docs.md` 已经陈述了
> “有数学”的判据；技能被调和到它们，而不是反过来。

> **Edge Cases is required at `standard`.** Skipping it consistently produces
> "wait, what happens if X is null?" debt during implementation. These 5
> required sections are the minimum that produces implementable code.
> **Edge Cases 在 `standard` 时必需。** 一致地跳过它会在实现期间产生
> “等等，如果 X 是 null 会怎样？”的债务。这 5 个
> 必需章节是产生可实现代码的最小值。

> **Art bible is conditional in `standard`.** It is required only if visual
> asset stories exist in the project. Code-focused projects can skip it
> entirely at `standard` level.
> **美术圣经在 `standard` 中是有条件的。** 仅当项目中存在视觉
> 资产 story 时才必需。以代码为主的项目在 `standard` 层级可以完全跳过它。

---

### Authoring skills
### 创作技能

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **design-system** | All 8 sections required | 5 required sections + conditional Formulas; Player Fantasy, Tuning Knobs skipped | Not required — game brief replaces GDDs. Can still be run voluntarily. |
| **art-bible** | All 9 sections required | Required only if visual asset stories exist; sections 1–4 minimum when required | Not required. Can still be run voluntarily. |
| **create-architecture** | Full architecture — all layers, module ownership, data flow, API boundaries, full ADR audit | Simplified — system layer map + critical ADR list only | Not required. Can still be run voluntarily. |
| **ux-design** | UX spec required per screen | Core screens only (main menu, HUD, primary game loop) | Not required. Can still be run voluntarily. |
| **map-systems** | Required before design-system | Required before design-system | Not required |
| **architecture-decision** | All ADRs on required ADR list must be completed | Critical ADRs only — Foundation layer systems | Not required |

| 技能 | full | standard | minimal |
|-------|------|----------|---------|
| **design-system** | 全部 8 个章节必需 | 5 个必需章节 + 条件性 Formulas；跳过 Player Fantasy、Tuning Knobs | 不要求 — 游戏简报替代 GDD。仍可自愿运行。 |
| **art-bible** | 全部 9 个章节必需 | 仅当存在视觉资产 story 时必需；要求时至少章节 1–4 | 不要求。仍可自愿运行。 |
| **create-architecture** | 完整架构 — 所有层、模块归属、数据流、API 边界、完整 ADR 审计 | 简化 — 仅系统层映射 + 关键 ADR 列表 | 不要求。仍可自愿运行。 |
| **ux-design** | 每屏都需要 UX 规格 | 仅核心画面（主菜单、HUD、主要游戏循环） | 不要求。仍可自愿运行。 |
| **map-systems** | design-system 之前必需 | design-system 之前必需 | 不要求 |
| **architecture-decision** | 必需 ADR 列表上的所有 ADR 都须完成 | 仅关键 ADR — Foundation 层系统 | 不要求 |

---

### Review and validation skills
### 评审与校验技能

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **design-review** | All 8 sections validated — any missing section blocks approval | 5 required sections validated; missing optional sections warned but do not block | Not applicable — no GDDs to review |
| **review-all-gdds** | Validates all 8 sections across all GDDs | Validates 5 required sections across all GDDs; optional sections surfaced as advisory only | Not applicable |
| **architecture-review** | Full traceability matrix — all GDDs, all ADRs | Reduced scope — architecture doc + critical ADRs only | Not applicable |
| **consistency-check** | Full entity registry cross-check against all GDD sections | Entity registry check against required sections only | Not meaningful — no GDDs to check |
| **content-audit** | Full content count audit against all GDD specs | Limited audit — only specs in required sections counted | Cannot run — no systems index exists |

| 技能 | full | standard | minimal |
|-------|------|----------|---------|
| **design-review** | 全部 8 个章节被校验 — 任何缺失章节都会阻塞批准 | 校验 5 个必需章节；缺失的可选章节会警告但不阻塞 | 不适用 — 没有 GDD 可评审 |
| **review-all-gdds** | 跨所有 GDD 校验全部 8 个章节 | 跨所有 GDD 校验 5 个必需章节；可选章节仅作为建议性内容浮现 | 不适用 |
| **architecture-review** | 完整可追溯性矩阵 — 所有 GDD、所有 ADR | 缩减范围 — 仅架构文档 + 关键 ADR | 不适用 |
| **consistency-check** | 对照所有 GDD 章节进行完整实体注册表交叉检查 | 仅对照必需章节检查实体注册表 | 无意义 — 没有 GDD 可检查 |
| **content-audit** | 对照所有 GDD 规格进行完整内容计数审计 | 有限审计 — 仅统计必需章节中的规格 | 无法运行 — 不存在系统索引 |

---

### Phase gate enforcement (gate-check)
### 阶段门禁执行（gate-check）

`gate-check` is where workflow has the most visible impact — the artifact
checklists differ per phase per mode.
`gate-check` 是工作流影响最明显的地方 — 每个阶段每个模式的产物
清单都不同。

| Gate | full | standard | minimal |
|------|------|----------|---------|
| Concept → Systems Design | game-concept.md, pillars, Visual Identity Anchor | game-concept.md only | `design/game-brief.md` only (content check, not section check) |
| Systems Design → Technical Setup | systems-index, all MVP GDDs reviewed (8 sections), cross-GDD review | systems-index, 5-section GDDs reviewed, cross-GDD review optional | Not applicable — no gates between brief and code; the gate PASSes with that note |
| Technical Setup → Pre-Production | engine, art bible sections 1–4+, 3+ ADRs, architecture, UX specs started | engine, art bible only if visual assets, critical ADRs, architecture | engine configured (required floor) |
| Pre-Production → Production | sprint plan, complete art bible, epics, UX specs, control manifest; Vertical Slice + its playtest recommended (absent → CONCERNS) | epics, sprint plan; complete art bible, UX specs, control manifest recommended; Vertical Slice recommended | the brief's Build order + stories under `production/epics/`; the Vertical Slice items drop — the core loop is fun and runs end to end, checked on the current build |
| Production → Polish | core mechanics, tests, smoke check, QA sign-off, 3+ playtests | core mechanics, smoke check, playable end to end, 1+ playtest, no open S1 bugs | smoke check, playable end to end, no open S1 bugs |
| Polish → Release | all features, content complete, localization (`/localize qa` per locale), QA, smoke, no open S1–S3 bugs, newest `/security-audit` with no open CRITICAL/HIGH | all features, smoke, no open S1 bugs, the security audit | smoke, no open S1 bugs |

| 门禁 | full | standard | minimal |
|------|------|----------|---------|
| Concept → Systems Design | game-concept.md、支柱、Visual Identity Anchor | 仅 game-concept.md | 仅 `design/game-brief.md`（内容检查，非章节检查） |
| Systems Design → Technical Setup | systems-index、所有 MVP GDD 已评审（8 章节）、跨 GDD 评审 | systems-index、5 章节 GDD 已评审、跨 GDD 评审可选 | 不适用 — 简报与代码之间没有门禁；该门禁带着此说明 PASS |
| Technical Setup → Pre-Production | 引擎、美术圣经章节 1–4+、3+ 个 ADR、架构、UX 规格已开始 | 引擎、仅当有视觉资产时美术圣经、关键 ADR、架构 | 引擎已配置（必需下限） |
| Pre-Production → Production | 冲刺计划、完整美术圣经、epic、UX 规格、控制清单；建议 Vertical Slice + 其试玩（缺失 → CONCERNS） | epic、冲刺计划；建议完整美术圣经、UX 规格、控制清单；建议 Vertical Slice | 简报的 Build order + `production/epics/` 下的 story；Vertical Slice 项被去掉 — 核心循环有趣且端到端可运行，在当前构建上检查 |
| Production → Polish | 核心机制、测试、冒烟检查、QA 签字、3+ 次试玩 | 核心机制、冒烟检查、端到端可玩、1+ 次试玩、无未关闭的 S1 bug | 冒烟检查、端到端可玩、无未关闭的 S1 bug |
| Polish → Release | 所有功能、内容完整、本地化（每种语言 `/localize qa`）、QA、冒烟、无未关闭的 S1–S3 bug、最新的 `/security-audit` 无未关闭的 CRITICAL/HIGH | 所有功能、冒烟、无未关闭的 S1 bug、安全审计 | 冒烟、无未关闭的 S1 bug |

<!-- gate-check reconciliation: at `full` and `standard` the Vertical Slice
     keeps its long-standing "recommended, not blocking → CONCERNS if absent;
     FAIL if built-and-broken" status — the tier table never upgrades it to a
     hard blocker. At `minimal` its items drop, and two checks on the current
     build replace them. The genuinely-required floor item at this gate is the
     sprint plan at `standard`/`full`; at `minimal` there is no separate
     sprint-plan step — the brief's Build order plus stories is the floor at
     `minimal`. -->
<!-- gate-check 校准：在 `full` 和 `standard` 下，Vertical Slice
     保持其长期以来的“建议性、不阻塞 → 缺失则 CONCERNS；
     已构建但损坏则 FAIL”状态 — 层级表从不将其升级为
     硬阻塞项。在 `minimal` 下，其各项被去掉，由当前
     构建上的两项检查替代。此门禁真正必需的下限项是
     `standard`/`full` 下的冲刺计划；在 `minimal` 下没有单独的
     sprint-plan 步骤 — 简报的 Build order 加上 story 就是 `minimal` 下的下限。 -->

**Director panel width** (`/gate-check` Section 4b) is workflow's second effect
here. Directors are Opus-tier, so the panel is sized to the project rather than
fixed at four:
**总监小组宽度**（`/gate-check` Section 4b）是工作流在这里的第二个效果。
总监是 Opus 层级，所以小组按项目规模设定，而不是
固定为四人：

| `workflow` | Panel | Directors |
|---|---|---|
| `full` | 4 | `creative-director`, `technical-director`, `producer`, `art-director` |
| `standard` | 2 | `technical-director`, `producer` |
| `minimal` | 1 | `producer` |

| `workflow` | 小组 | 总监 |
|---|---|---|
| `full` | 4 | `creative-director`、`technical-director`、`producer`、`art-director` |
| `standard` | 2 | `technical-director`、`producer` |
| `minimal` | 1 | `producer` |

`review_mode` remains the axis that decides *whether* the panel runs at all
(`solo` skips it entirely); workflow decides only how wide it is. Narrowing
never softens a verdict — the strictest verdict from whoever ran still wins, and
`/gate-check` names the perspectives that did not run.
`review_mode` 仍然是决定小组*是否*运行的轴（`solo` 完全跳过它）；
工作流只决定它有多宽。缩窄绝不软化裁决 — 无论谁运行，最严格的裁决仍然胜出，
而 `/gate-check` 会指明未运行的视角。

---

### Planning and implementation skills
### 规划与实现技能

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **create-epics** | Requires all GDDs approved (8 sections) | Requires 5-section GDDs approved | **Skipped** (Option A) — no separate epic doc. `/create-stories` reads `design/game-brief.md` directly and synthesizes the implicit epic container itself. |
| **create-stories** | Requires all ADRs on required list present | Requires critical ADRs present | No ADR requirement |
| **dev-story** | Requires TR registry + governing ADR — blocks without them, and on a `Proposed`, `Deprecated` or `Superseded` ADR; a missing control manifest warns | TR registry optional; blocks only on a referenced ADR that is missing, `Proposed`, `Deprecated` or `Superseded` | No TR registry or ADR required — implements against `design/game-brief.md`; a referenced ADR that is missing, `Proposed`, `Deprecated` or `Superseded` still blocks |
| **story-readiness** | Full TR registry + ADR + control manifest validation; any referenced ADR that is missing, `Proposed`, `Deprecated` or `Superseded` BLOCKS | TR registry optional; critical ADR check, and any referenced ADR that is missing, `Proposed`, `Deprecated` or `Superseded` BLOCKS | Acceptance-criteria check (the brief stands in for the GDD); any referenced ADR that is missing, `Proposed`, `Deprecated` or `Superseded` still BLOCKS |
| **story-done** | Full GDD traceability + ADR consistency check | 5-section GDD traceability check | Acceptance criteria check only |
| **qa-plan** | Full test plan derived from all 8 GDD sections | Test plan from 5 required sections | Test plan from acceptance criteria only |
| **regression-suite** | Critical paths mapped from all sections including Edge Cases | Critical paths from required sections (including Edge Cases) | Smoke test coverage only |
| **release-checklist** | Open S1, S2 or S3 bug in `production/qa/bugs/` fails its Quality Gates item | Open S1 fails; open S2/S3 listed as risks | Open S1 fails; open S2/S3 listed as risks |
| **launch-checklist** | Zero open S1–S3 bugs, no exceptions | Zero open S1; S2 or a documented exception | Zero open S1; S2 or a documented exception |
| **team-release** | qa-lead verifies no open S1–S3 bugs | qa-lead verifies no open S1 bugs | qa-lead verifies no open S1 bugs |

| 技能 | full | standard | minimal |
|-------|------|----------|---------|
| **create-epics** | 要求所有 GDD 已批准（8 章节） | 要求 5 章节 GDD 已批准 | **跳过**（Option A）— 没有单独的 epic 文档。`/create-stories` 直接读取 `design/game-brief.md`，并自行合成隐式的 epic 容器。 |
| **create-stories** | 要求必需列表上的所有 ADR 存在 | 要求关键 ADR 存在 | 无 ADR 要求 |
| **dev-story** | 要求 TR 注册表 + 管理 ADR — 没有则阻塞，且遇到 `Proposed`、`Deprecated` 或 `Superseded` ADR 也阻塞；缺失控制清单会警告 | TR 注册表可选；仅当被引用的 ADR 缺失、`Proposed`、`Deprecated` 或 `Superseded` 时阻塞 | 不要求 TR 注册表或 ADR — 针对 `design/game-brief.md` 实现；被引用的 ADR 缺失、`Proposed`、`Deprecated` 或 `Superseded` 仍然阻塞 |
| **story-readiness** | 完整 TR 注册表 + ADR + 控制清单校验；任何被引用的 ADR 缺失、`Proposed`、`Deprecated` 或 `Superseded` 都阻塞 | TR 注册表可选；关键 ADR 检查，且任何被引用的 ADR 缺失、`Proposed`、`Deprecated` 或 `Superseded` 都阻塞 | 验收标准检查（简报代替 GDD）；任何被引用的 ADR 缺失、`Proposed`、`Deprecated` 或 `Superseded` 仍然阻塞 |
| **story-done** | 完整 GDD 可追溯性 + ADR 一致性检查 | 5 章节 GDD 可追溯性检查 | 仅验收标准检查 |
| **qa-plan** | 从全部 8 个 GDD 章节派生的完整测试计划 | 来自 5 个必需章节的测试计划 | 仅来自验收标准的测试计划 |
| **regression-suite** | 从包括 Edge Cases 在内的所有章节映射关键路径 | 从必需章节（包括 Edge Cases）映射关键路径 | 仅冒烟测试覆盖 |
| **release-checklist** | `production/qa/bugs/` 中未关闭的 S1、S2 或 S3 bug 会使其 Quality Gates 项失败 | 未关闭的 S1 失败；未关闭的 S2/S3 列为风险 | 未关闭的 S1 失败；未关闭的 S2/S3 列为风险 |
| **launch-checklist** | 零未关闭的 S1–S3 bug，无例外 | 零未关闭的 S1；S2 或文档化例外 | 零未关闭的 S1；S2 或文档化例外 |
| **team-release** | qa-lead 验证无未关闭的 S1–S3 bug | qa-lead 验证无未关闭的 S1 bug | qa-lead 验证无未关闭的 S1 bug |

---

### Support skills
### 支持技能

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **project-stage-detect** | Checks for all doc types; missing art bible or UX specs flagged as gaps | Adjusts expectations — art bible only flagged if visual-asset stories exist; non-core UX specs not flagged | `design/game-brief.md` + engine present = normal state; no gaps flagged for absent GDDs |
| **adopt** | Full format compliance audit across all doc types | Audit scope reduced to required docs only | `design/game-brief.md` format check only |
| **reverse-document** | Generates full 8-section GDD from code | Generates 5-section GDD from code | Generates `design/game-brief.md` from code |
| **propagate-design-change** | Full cascading impact analysis across all ADRs | Checks critical ADRs for references only | Not applicable |
| **help** | Full artifact detection — surfaces all missing docs as next steps | Adjusts "what's missing" to required docs only — optional docs not surfaced as gaps | `design/game-brief.md` + engine present = next step is code |

| 技能 | full | standard | minimal |
|-------|------|----------|---------|
| **project-stage-detect** | 检查所有文档类型；缺失美术圣经或 UX 规格被标记为缺口 | 调整期望 — 仅当存在视觉资产 story 时才标记美术圣经；非核心 UX 规格不标记 | `design/game-brief.md` + 引擎存在 = 正常状态；缺失 GDD 不标记缺口 |
| **adopt** | 跨所有文档类型的完整格式合规审计 | 审计范围缩减到仅必需文档 | 仅 `design/game-brief.md` 格式检查 |
| **reverse-document** | 从代码生成完整 8 章节 GDD | 从代码生成 5 章节 GDD | 从代码生成 `design/game-brief.md` |
| **propagate-design-change** | 跨所有 ADR 的完整级联影响分析 | 仅检查关键 ADR 的引用 | 不适用 |
| **help** | 完整产物检测 — 将所有缺失文档作为下一步浮现 | 将“缺什么”调整到仅必需文档 — 可选文档不作为缺口浮现 | `design/game-brief.md` + 引擎存在 = 下一步是编码 |

---

### Workflow change mid-project
### 项目中途更改工作流

When `workflow` changes via `/settings`, the skill emits an informational note:
当 `workflow` 通过 `/settings` 更改时，技能会发出一个信息性说明：

> "Workflow changed from [old] to [new]. Run `/content-audit` to see what's now
> required or extra. No automatic migration — existing files stay in place."
> “工作流已从 [旧] 更改为 [新]。运行 `/content-audit` 查看现在要求什么
> 或多出什么。无自动迁移 — 现有文件保持原位。”

No documents are auto-deleted, auto-generated, or blocked. The setting only affects
*new* enforcement going forward.
没有文档被自动删除、自动生成或阻塞。该设置只影响
*新的*后续执行。

---

## workflow_overrides

**Controls:** Opt-in granular requirements that override the chosen workflow level
**Location:** **top level of `project.yaml`** — a sibling of `modes:`, *not* a child of it
**Values:** object with sub-flags (see below)
**Default:** all false / empty
**Set by:** `/settings`
**Read by:** `/design-system`, `/design-review`, `/art-bible`, `/gate-check`, `/review-all-gdds`, `/qa-plan`
**控制：** 可选启用的细粒度要求，用于覆盖所选工作流层级
**位置：** **`project.yaml` 的顶层** — 与 `modes:` 同级，*不是*它的子项
**取值：** 带子标志的对象（见下文）
**默认：** 全部为 false / 空
**由谁设置：** `/settings`
**由谁读取：** `/design-system`、`/design-review`、`/art-bible`、`/gate-check`、`/review-all-gdds`、`/qa-plan`

> **Why the location is called out.** `resolve_config` reads
> `workflow_overrides.system_overrides.*` from the document root
> (`yaml-helper.sh`), and all 14 consuming skill files grep the same top-level
> path. Nested under `modes:` it is still valid YAML, so nothing errors — the
> setting is simply never read. If you copied a `workflow_overrides` block from
> anywhere, check its indentation: it belongs at the document root, never under
> `modes:`.
> **为什么要特别强调位置。** `resolve_config` 从文档根读取
> `workflow_overrides.system_overrides.*`
> （`yaml-helper.sh`），而全部 14 个消费方技能文件都 grep 同一个顶层
> 路径。嵌套在 `modes:` 下它仍是合法 YAML，所以不会报错 —
> 该设置只是永远不会被读取。如果你从任何地方复制了 `workflow_overrides` 块，
> 请检查其缩进：它属于文档根，绝不在 `modes:` 之下。

**Priority chain:** the three `workflow_overrides` **boolean flags**
(`edge_cases`, `tuning_knobs`, `art_bible_strict`) are *additive* on top of the
chosen `workflow` level — they make things stricter, never looser. None of them
has a value that opts out of a requirement the workflow level imposes.
**优先级链：** 三个 `workflow_overrides` **布尔标志**
（`edge_cases`、`tuning_knobs`、`art_bible_strict`）是在所选 `workflow` 层级之上的
*叠加项* — 它们只会让要求更严格，绝不会更宽松。它们中没有任何一个
取值能够豁免工作流层级施加的要求。

> **`workflow_overrides.system_overrides` is not a flag and is not additive — it replaces a tier in both directions.**
> This rule does not extend to it. On a
> `full` project, `system_overrides.inventory: minimal` really does drop that
> system's required sections to zero. Intended — see
> `.claude/docs/workflow-modes.md § workflow_overrides`. Stating the additive
> rule over the whole key is wrong: the guarantee never held for
> `system_overrides`, so do not rely on it as a safety net.
> **`workflow_overrides.system_overrides` 不是标志，也不是叠加项 — 它会在两个方向上替换层级。**
> 该规则不适用于它。在一个
> `full` 项目中，`system_overrides.inventory: minimal` 确实会将该系统
> 的必需章节降为零。这是有意为之 — 参见
> `.claude/docs/workflow-modes.md § workflow_overrides`。把叠加
> 规则套用到整个键上是错误的：该保证从未适用于
> `system_overrides`，因此不要把它当作安全网来依赖。

---

### Fields
### 字段

```yaml
workflow_overrides:
  edge_cases: false          # force Edge Cases section required (no-op at standard since already required; relevant at minimal)
  tuning_knobs: false        # force Tuning Knobs section required (relevant at standard, no-op at full)
  art_bible_strict: false    # force all 9 art bible sections required regardless of asset stories
  system_overrides: {}       # per-system tier overrides — see below
```

### Per-system overrides
### 按系统覆盖

```yaml
workflow_overrides:
  system_overrides:
    combat: full              # combat-system GDD requires full (8 sections) regardless of project workflow
    boss-encounters: full
    inventory: minimal        # inventory needs no GDD — the game brief covers it (minimal = no required sections)
```

`system_overrides` is a map of `system_name: workflow_level`. The named system uses the override; all other systems use the project-level `workflow`.
`system_overrides` 是 `system_name: workflow_level` 的映射。被命名的系统使用该覆盖；所有其他系统使用项目级 `workflow`。

---

### Affected skills
### 受影响的技能

| Skill | How workflow_overrides changes behavior |
|-------|----------------------------------------|
| **design-system** | Reads `system_overrides[system_name]` first; falls back to project `workflow`. Applies override-specific section requirements. |
| **design-review** | Same lookup — validates against the override tier, not the project default, for the named system. |
| **art-bible** | If `art_bible_strict: true`, requires all 9 sections regardless of `workflow` level. |
| **gate-check** | Considers `system_overrides` when validating that all required GDDs are complete. A system at `system_overrides.combat: full` blocks the gate until all 8 sections exist for combat. |
| **review-all-gdds** | Validates each GDD against its effective tier (project workflow + any system override). |

| 技能 | workflow_overrides 如何改变行为 |
|-------|----------------------------------------|
| **design-system** | 先读取 `system_overrides[system_name]`；回退到项目 `workflow`。应用该覆盖特定的章节要求。 |
| **design-review** | 相同的查找 — 对具名系统按覆盖层级而非项目默认值进行校验。 |
| **art-bible** | 若 `art_bible_strict: true`，无论 `workflow` 层级如何都要求全部 9 个章节。 |
| **gate-check** | 在验证所有必需 GDD 是否完成时考虑 `system_overrides`。位于 `system_overrides.combat: full` 的系统会阻塞门禁，直到 combat 的全部 8 个章节都存在。 |
| **review-all-gdds** | 按每个 GDD 的有效层级（项目工作流 + 任何系统覆盖）进行校验。 |

---

## modes.automation

**Controls:** Whether skills ask for decisions and approval before acting, or
recommend and proceed — the tradeoff between user control and speed  
**Values:** `collaborative` | `guided` | `autonomous`  
**Default:** `collaborative`  
**Set by:** `/start`, `/settings`  
**Read by:** All 68 skills that use `AskUserQuestion` or write files
**控制：** 技能是在行动前请求决策与批准，还是给出建议后直接推进 —
用户控制与速度之间的权衡
**取值：** `collaborative` | `guided` | `autonomous`
**默认：** `collaborative`
**由谁设置：** `/start`、`/settings`
**由谁读取：** 所有使用 `AskUserQuestion` 或写入文件的 68 个技能

**Priority chain:** `modes.automation` in `project.yaml` → hardcoded default
**优先级链：** `project.yaml` 中的 `modes.automation` → 硬编码默认值

> **Unlike review_mode and workflow, this setting is not a per-skill table.**
> It defines universal interaction rules that apply across all skills. A
> per-skill breakdown would repeat the same answer 68 times.
> **与 review_mode 和 workflow 不同，该设置不是按技能划分的表格。**
> 它定义适用于所有技能的通用交互规则。按技能
> 拆分只会把同一个答案重复 68 次。

> **Overrides COLLABORATIVE-DESIGN-PRINCIPLE.md:** `guided` and `autonomous`
> modes intentionally relax the Q→O→D→Draft→Approval protocol defined in that
> document. This is opt-in. `collaborative` preserves the protocol exactly.
> **覆盖 COLLABORATIVE-DESIGN-PRINCIPLE.md：** `guided` 和 `autonomous`
> 模式有意放宽该文档中定义的 Q→O→D→Draft→Approval 协议。
> 这是可选启用的。`collaborative` 精确保留该协议。

> **Safety net — `automation_always_ask`:** Even in `autonomous` mode, certain
> categories of decision can be configured to always prompt. See next section.
> **安全网 — `automation_always_ask`：** 即使在 `autonomous` 模式下，某些
> 类别的决策也可以配置为始终提示。见下一节。

---

### Value intent
### 取值意图

| Value | Speed | Control | What changes |
|-------|-------|---------|--------------|
| `collaborative` | Slowest | Full — every decision is the user's | Current behavior. Q→O→D→Draft→Approval strictly followed. |
| `guided` | Balanced | High — major decisions are the user's, minor ones proceed automatically | AI states recommendation and proceeds for minor decisions. AskUserQuestion reserved for major/irreversible decisions. |
| `autonomous` | Fastest | Low — AI decides, logs, and proceeds | No AskUserQuestion (except categories in `automation_always_ask`). No draft review. No write approval. All decisions logged to decision log. |

| 取值 | 速度 | 控制 | 哪些会改变 |
|-------|-------|---------|--------------|
| `collaborative` | 最慢 | 完整 — 每个决策都由用户做 | 当前行为。严格遵循 Q→O→D→Draft→Approval。 |
| `guided` | 均衡 | 高 — 重大决策由用户做，次要决策自动推进 | AI 对次要决策说明建议并推进。AskUserQuestion 仅保留给重大/不可逆决策。 |
| `autonomous` | 最快 | 低 — AI 决策、记录并推进 | 无 AskUserQuestion（`automation_always_ask` 中的类别除外）。无草稿评审。无写入批准。所有决策记录到决策日志。 |

---

### Universal rules per mode
### 每种模式的通用规则

#### collaborative (current behavior — no change)
#### collaborative（当前行为 — 无变化）

- `AskUserQuestion` called for every multi-option decision
- 2–4 options presented with pros/cons for every design choice
- Full draft shown and approved before every file write
- "May I write this to [filepath]?" asked before every write
- "May I create [filepath] with skeleton?" asked before skeleton creation
- Section-by-section approval in multi-section authoring skills
- Multi-file changes require explicit approval of the full changeset
- 每个多选项决策都调用 `AskUserQuestion`
- 每个设计选择都提供 2–4 个选项及其优缺点
- 每次写入文件前都展示完整草稿并获得批准
- 每次写入前都询问“我可以将其写入 [filepath] 吗？”
- 创建骨架前询问“我可以创建带有骨架的 [filepath] 吗？”
- 多章节创作技能中按章节逐一批准
- 多文件变更需要对完整变更集明确批准

#### guided
#### guided

- `AskUserQuestion` called for **major decisions only** (see classification below)
- Minor decisions: AI states recommendation inline and proceeds — e.g.
  *"Going with a static utility pattern here — it fits the existing architecture.
  Continuing unless you want to change direction."*
- Updates to existing files: draft shown briefly before writing — proceeds after a
  short summary, does not wait for explicit "yes"
- "May I write?" asked for **new files only**, and a new file waits for the answer
  — updates to existing files proceed directly
- Still presents options for major decisions but caps at 2 choices with a clear
  recommendation
- Multi-section authoring: writes each approved section immediately, no per-section
  confirmation prompt
- 仅在**重大决策**时调用 `AskUserQuestion`（见下文分类）
- 次要决策：AI 内联说明建议并推进 — 例如
  *“这里采用静态工具类模式 — 它契合现有架构。
  继续推进，除非你想改变方向。”*
- 对现有文件的更新：写入前简要展示草稿 — 简短摘要后即推进，
  不等待明确的“是”
- 仅对**新文件**询问“我可以写入吗？”，且新文件会等待回答
  — 对现有文件的更新直接推进
- 重大决策仍会列出选项，但最多 2 个选择并给出明确建议
- 多章节创作：每个章节一经批准立即写入，无按章节的确认提示

#### autonomous
#### autonomous

- No `AskUserQuestion` calls **except** for categories listed in `automation_always_ask`
- No draft review
- No "May I write?" prompts — writes directly
- Picks the recommended option for every decision without presenting alternatives
- All decisions logged immediately to `production/session-logs/decision-log.md`
  with: timestamp, skill, decision point, option chosen, reasoning
- User reviews decision log post-session to audit choices made
- 不调用 `AskUserQuestion`，**除非**是 `automation_always_ask` 中列出的类别
- 无草稿评审
- 无“我可以写入吗？”提示 — 直接写入
- 对每个决策选取推荐选项，不展示替代方案
- 所有决策立即记录到 `production/session-logs/decision-log.md`
  包含：时间戳、技能、决策点、所选选项、理由
- 用户在会话结束后审阅决策日志，以审计所做选择

#### every mode — a question with no answer
#### 每种模式 — 没有回答的问题

- A question that comes back skipped, dismissed or empty is **not an answer**, in
  every mode and on every tool (a closed question, a headless run that returns
  every question as skipped, a reply that picks nothing)
- Nothing is written, no mode or setting changes and no option is picked on its
  behalf; the question is asked again in plain text, naming what waits on it
- `autonomous`: a question the mode did not require is decided and logged as
  usual; an `automation_always_ask` category or an exempt skill asks again
- Where nobody can answer (CI, headless), the skill stops and reports what is
  waiting rather than choosing
- 返回为跳过、关闭或空的问题**不是回答**，在
  每种模式、每个工具上都是如此（关闭的问题、将每个问题都返回为跳过的无头运行、
  没有选择任何内容的回复）
- 不写入任何内容，不改变任何模式或设置，也不代表它选择任何选项；
  该问题会以纯文本再次提出，并指明它在等待什么
- `autonomous`：该模式不要求的问题照常决策并记录；
  `automation_always_ask` 类别或豁免技能会再次询问
- 在无人能回答的地方（CI、无头环境），技能会停止并报告正在
  等待什么，而不是替其选择

---

### Major vs minor decision classification (guided mode)
### 重大与次要决策分类（guided 模式）

**Major — always use AskUserQuestion in guided mode:**
**重大 — 在 guided 模式下始终使用 AskUserQuestion：**

| Decision type | Example |
|---------------|---------|
| Choosing a system name or document path | "What should we call this system?" |
| Mutually exclusive design directions | "Real-time or turn-based?" |
| Any choice that gates downstream work | Engine choice, architecture approach |
| Scope changes | "Cut this feature or slip the deadline?" |
| Any decision that can't be changed without significant rework | Core loop mechanic |

| 决策类型 | 示例 |
|---------------|---------|
| 选择系统名称或文档路径 | “这个系统应该叫什么？” |
| 互斥的设计方向 | “实时还是回合制？” |
| 任何会门禁下游工作的选择 | 引擎选择、架构方案 |
| 范围变更 | “砍掉这个功能还是推迟截止日期？” |
| 任何不做重大返工就无法更改的决策 | 核心循环机制 |

**Minor — AI recommends and proceeds in guided mode:**
**次要 — AI 在 guided 模式下建议并推进：**

| Decision type | Example |
|---------------|---------|
| Which section to work on next | "Moving to Edge Cases next" |
| Optional section inclusion | "Adding a Visual Notes section — fits the system" |
| Formatting and structure choices | Heading levels, table vs prose |
| Adding detail to an already-decided direction | Sub-options within an approved approach |
| Next-step routing after a phase completes | "Running design-review now" |

| 决策类型 | 示例 |
|---------------|---------|
| 接下来处理哪个章节 | “接下来转到 Edge Cases” |
| 可选章节的纳入 | “添加一个 Visual Notes 章节 — 契合该系统” |
| 格式与结构选择 | 标题层级、表格还是散文 |
| 为已确定的方向补充细节 | 已批准方案内的子选项 |
| 阶段完成后的下一步路由 | “现在运行 design-review” |

---

### Affected skills by category
### 按类别受影响的技能

**Authoring skills — highest impact.** Each pauses 10–15 times per document in
`collaborative`. Drops to 2–3 in `guided`, zero in `autonomous`.
**创作技能 — 影响最大。** 在 `collaborative` 中每个文档暂停 10–15 次。
`guided` 降至 2–3 次，`autonomous` 为零。

`brainstorm`, `design-system`, `art-bible`, `create-architecture`, `ux-design`,
`map-systems`, `architecture-decision`, `create-epics`, `create-stories`,
`sprint-plan`, `prototype`

**Review skills — medium impact.** Pause after presenting findings to ask what
to do next. In `guided` routing decisions proceed automatically. In `autonomous`
the recommended path is taken and logged.
**评审技能 — 中等影响。** 展示发现后暂停，询问接下来做什么。
在 `guided` 中路由决策自动推进。在 `autonomous` 中
采用推荐路径并记录。

`design-review`, `architecture-review`, `gate-check`, `review-all-gdds`,
`story-readiness`, `story-done`, `milestone-review`, `playtest-report`

**Team orchestration skills — medium impact.** Pause between phases for
check-in. In `guided` the pipeline advances automatically unless BLOCKED. In
`autonomous` the full pipeline runs end to end.
**团队协调技能 — 中等影响。** 在阶段之间暂停以
检查。在 `guided` 中流水线自动推进，除非 BLOCKED。在
`autonomous` 中完整流水线端到端运行。

`team-combat`, `team-ui`, `team-audio`, `team-qa`, `team-release`,
`team-narrative`, `team-polish`, `team-level`, `team-live-ops`

**Implementation skills — lower impact.** Pause for architectural questions
before writing code. In `guided` only genuinely ambiguous decisions stop. In
`autonomous` the conventional approach is picked and logged.
**实现技能 — 影响较低。** 写代码前为架构问题暂停。
在 `guided` 中只对真正模糊的决策停下。在
`autonomous` 中选取常规做法并记录。

`dev-story`, `code-review`

**Setup and utility skills — lowest impact.** Pause for initial configuration
or routing questions. In `guided` defaults are applied automatically. In
`autonomous` recommended defaults are taken without prompting.
**设置与工具技能 — 影响最低。** 为初始配置
或路由问题暂停。在 `guided` 中默认值自动应用。在
`autonomous` 中采用推荐默认值而不提示。

`start`, `adopt`, `setup-engine`, `retrospective`, `localize`, `propagate-design-change`,
`asset-spec`, `smoke-check`, `qa-plan`, `story-readiness`

---

### Exemptions — skills that ignore the automation setting
### 豁免 — 忽略自动化设置的技能

These skills always behave as `collaborative` regardless of the setting.
The reasons are noted.
无论该设置如何，这些技能始终表现为 `collaborative`。
原因已注明。

| Skill | Why always collaborative |
|-------|--------------------------|
| **hotfix** | Emergency decisions — user must approve scope and risk before any action |
| **gate-check** | Results must be reviewed — a gate verdict without user acknowledgement defeats the purpose |
| **day-one-patch** | Release-critical — every action needs explicit sign-off |
| **setup-engine** | One-time irreversible choice that affects the entire project |

| 技能 | 为何始终 collaborative |
|-------|--------------------------|
| **hotfix** | 紧急决策 — 任何行动前用户必须批准范围与风险 |
| **gate-check** | 结果必须被审阅 — 没有用户确认的门禁裁决有违初衷 |
| **day-one-patch** | 发布关键 — 每个操作都需要明确签字 |
| **setup-engine** | 影响整个项目的一次性不可逆选择 |

---

### Decision log format (autonomous mode)
### 决策日志格式（autonomous 模式）

Written to `production/session-logs/decision-log.md` — append-only.
写入 `production/session-logs/decision-log.md` — 仅追加。

```markdown
## [timestamp] — [skill-name]

**Decision point:** [what was being decided]
**Options considered:** [list of options that would have been presented]
**Chosen:** [what was picked]
**Reason:** [one-line rationale]
**Category:** [scope_changes | file_deletions | schema_changes | etc., or "minor"]
```

If the file does not exist, it is created. It is never truncated — each session
appends to the existing log.
如果文件不存在，则创建它。它永不被截断 — 每个会话
追加到现有日志中。

---

## modes.automation_always_ask

**Controls:** Decision categories that ALWAYS trigger AskUserQuestion regardless of automation mode
**Values:** list of category names
**Default:** `[scope_changes, file_deletions, schema_changes]`
**Set by:** `/settings`
**Read by:** All skills that respect `modes.automation`
**控制：** 无论自动化模式如何都始终触发 AskUserQuestion 的决策类别
**取值：** 类别名称列表
**默认：** `[scope_changes, file_deletions, schema_changes]`
**由谁设置：** `/settings`
**由谁读取：** 所有遵循 `modes.automation` 的技能

> **Makes `autonomous` safe.** Without this, `autonomous` is "AI does literally
> everything, no questions asked." With it, AI does most things but stops on
> destructive or irreversible decisions you specifically named.
> **让 `autonomous` 变得安全。** 没有它，`autonomous` 就是“AI 字面意义上
> 做所有事，什么都不问”。有了它，AI 做大部分事，但会在
> 你明确指定的破坏性或不可逆决策上停下。

---

### Recognized categories
### 已识别类别

| Category | Examples of decisions in this category |
|----------|----------------------------------------|
| `scope_changes` | Cutting a feature, slipping a deadline, splitting/merging an epic, removing acceptance criteria |
| `file_deletions` | Removing a story, deleting a GDD, removing a system, removing a test file |
| `schema_changes` | Changes to project.yaml, story template, control manifest, ADR template, GDD template |
| `architecture_decisions` | New ADR creation, ADR replacement, system boundary changes |
| `version_bumps` | Engine version change, framework version bump, dependency major version change |
| `external_calls` | Invoking external APIs (asset gen, AI services) when in autonomous mode |

| 类别 | 该类别中决策的示例 |
|----------|----------------------------------------|
| `scope_changes` | 砍掉功能、推迟截止日期、拆分/合并 epic、移除验收标准 |
| `file_deletions` | 移除 story、删除 GDD、移除系统、移除测试文件 |
| `schema_changes` | 对 project.yaml、story 模板、control manifest、ADR 模板、GDD 模板的更改 |
| `architecture_decisions` | 新建 ADR、替换 ADR、系统边界变更 |
| `version_bumps` | 引擎版本变更、框架版本升级、依赖主版本变更 |
| `external_calls` | 在 autonomous 模式下调用外部 API（资产生成、AI 服务） |

The list is a YAML list of these strings. Skills check whether the current decision falls into one of the configured categories and prompt regardless of `automation` value.
该列表是这些字符串的 YAML 列表。技能会检查当前决策是否落入已配置的某个类别，并无论 `automation` 取值如何都进行提示。

---

### Affected skills
### 受影响的技能

| Skill | Categories typically triggered |
|-------|--------------------------------|
| **scope-check** | `scope_changes` |
| **propagate-design-change** | `schema_changes`, `architecture_decisions` |
| **architecture-decision** | `architecture_decisions` |
| **setup-engine** | `version_bumps`, `schema_changes` |
| **story-done** | `file_deletions` (when removing/replacing test files) |
| **asset-spec** | `external_calls` (when calling external generators) |

| 技能 | 通常触发的类别 |
|-------|--------------------------------|
| **scope-check** | `scope_changes` |
| **propagate-design-change** | `schema_changes`、`architecture_decisions` |
| **architecture-decision** | `architecture_decisions` |
| **setup-engine** | `version_bumps`、`schema_changes` |
| **story-done** | `file_deletions`（移除/替换测试文件时） |
| **asset-spec** | `external_calls`（调用外部生成器时） |

---

## modes.story_granularity

**Controls:** How big each story is and how many stories per epic/sprint
**Values:** `coarse` | `balanced` | `fine`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `coarse`; `standard` yields `balanced`; `full` yields `fine`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** `/create-stories`, `/sprint-plan`, `/sprint-status`, `/story-readiness`
**控制：** 每个 story 有多大，以及每个 epic/sprint 有多少 story
**取值：** `coarse` | `balanced` | `fine`
**默认：** *无* — 由 `modes.rigor` 提供（默认的 `minimal` 产出 `coarse`；`standard` 产出 `balanced`；`full` 产出 `fine`）
**由谁设置：** `/start`（通过 `modes.rigor`）、`/settings`
**由谁读取：** `/create-stories`、`/sprint-plan`、`/sprint-status`、`/story-readiness`

**Priority chain:** `modes.story_granularity` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*
**优先级链：** `project.yaml` 中的 `modes.story_granularity` → `modes.rigor` 扩展 → *（无硬编码默认值）*

---

### Value intent
### 取值意图

| Value | Story shape | Stories per sprint | Best for |
|-------|-------------|-------------------|----------|
| `coarse` | 1 story = 1 feature. 3–5 days work each. 5–10 ACs per story. The default, from `rigor: minimal`. | 2–4 | Solo devs, prototyping, "I know what I'm building" |
| `balanced` | 1 story = 1 task. 1–2 days work each. 2–4 ACs per story. The `rigor: standard` value. | 6–10 | Most projects |
| `fine` | 1 story = 1 AC. Hours of work each. Easy code review. Frequent /story-done. | 15–25 | Teams, learning, anything needing fine handoffs |

| 取值 | Story 形态 | 每个 sprint 的 story 数 | 最适合 |
|-------|-------------|-------------------|----------|
| `coarse` | 1 个 story = 1 个功能。每个 3–5 天工作。每个 story 5–10 条 AC。默认值，来自 `rigor: minimal`。 | 2–4 | 单人开发者、原型制作、“我知道自己在做什么” |
| `balanced` | 1 个 story = 1 个任务。每个 1–2 天工作。每个 story 2–4 条 AC。`rigor: standard` 的取值。 | 6–10 | 大多数项目 |
| `fine` | 1 个 story = 1 条 AC。每个数小时工作。代码评审轻松。频繁 /story-done。 | 15–25 | 团队、学习、任何需要精细交接的场景 |

---

### Affected skills
### 受影响的技能

| Skill | coarse | balanced | fine |
|-------|--------|----------|------|
| **create-stories** | Each story carries 5–10 ACs covering an entire feature | Each story carries 2–4 ACs covering one task | Each story carries 1 AC; story name = AC restatement |
| **sprint-plan** | Allocates 2–4 stories per sprint based on velocity. | Allocates 6–10 stories per sprint. | Allocates 15–25 stories per sprint. |
| **sprint-status** | Burn-down reads in feature-sized chunks. | Burn-down reads in task-sized chunks. | Burn-down reads in AC-sized chunks. |

| 技能 | coarse | balanced | fine |
|-------|--------|----------|------|
| **create-stories** | 每个 story 承载 5–10 条 AC，覆盖一整个功能 | 每个 story 承载 2–4 条 AC，覆盖一个任务 | 每个 story 承载 1 条 AC；story 名称 = AC 的重述 |
| **sprint-plan** | 根据速度每个 sprint 分配 2–4 个 story。 | 每个 sprint 分配 6–10 个 story。 | 每个 sprint 分配 15–25 个 story。 |
| **sprint-status** | 燃尽图按功能尺寸的块读取。 | 燃尽图按任务尺寸的块读取。 | 燃尽图按 AC 尺寸的块读取。 |

---

## docs.density

**Controls:** How deep each section in authored docs goes — independent of which sections are required
**Values:** `terse` | `balanced` | `thorough`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `terse`; `standard` yields `balanced`; `full` yields `thorough`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** `/design-system`, `/art-bible`, `/create-architecture`, `/ux-design`, `/map-systems`, `/brainstorm`
**控制：** 撰写文档中每个章节的深入程度 — 与要求哪些章节无关
**取值：** `terse` | `balanced` | `thorough`
**默认：** *无* — 由 `modes.rigor` 提供（默认的 `minimal` 产出 `terse`；`standard` 产出 `balanced`；`full` 产出 `thorough`）
**由谁设置：** `/start`（通过 `modes.rigor`）、`/settings`
**由谁读取：** `/design-system`、`/art-bible`、`/create-architecture`、`/ux-design`、`/map-systems`、`/brainstorm`

**Priority chain:** `docs.density` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*
**优先级链：** `project.yaml` 中的 `docs.density` → `modes.rigor` 扩展 → *（无硬编码默认值）*

> **Distinct from `workflow`, but not independent by default.** `workflow`
> controls which sections exist; `density` controls how deep each section goes.
> `modes.rigor` sets both together, so the diagonal (`rigor: full` → 8
> sections *and* thorough prose) is what you get without asking. The off-diagonal
> is still reachable and is the reason `rigor` overrides both ways: `rigor: full`
> + an explicit `docs.density: terse` gives "all sections but each is compact" —
> the "comprehensive but tight" mode, which neither knob expresses alone.
> **区别于 `workflow`，但默认并不独立。** `workflow`
> 控制存在哪些章节；`density` 控制每个章节深入多少。
> `modes.rigor` 将两者一起设置，因此对角线情形（`rigor: full` → 8
> 个章节*且*详尽散文）就是你无需额外指定得到的。非对角线
> 情形依然可达，这正是 `rigor` 双向覆盖的原因：`rigor: full`
> + 显式的 `docs.density: terse` 得到“所有章节但每个都紧凑” —
> 即“全面但紧凑”模式，任何单个旋钮都无法单独表达。

---

### Value intent
### 取值意图

| Value | Per-section output style |
|-------|--------------------------|
| `terse` | Bullet points. 2–5 lines per section. Skip rationale and narrative framing. Skip preambles like "In this game..." Just facts needed to implement. The default, from `rigor: minimal`. |
| `balanced` | Paragraphs with light rationale. Examples where helpful. The `rigor: standard` value. |
| `thorough` | Full prose. Rationale for every decision. Examples, alternatives considered, design history. |

| 取值 | 每章节输出风格 |
|-------|--------------------------|
| `terse` | 要点列表。每章节 2–5 行。跳过理由和叙事框架。跳过“在这个游戏中……”之类的引言。只写实现所需的事实。默认值，来自 `rigor: minimal`。 |
| `balanced` | 带轻量理由的段落。在有用处给出示例。`rigor: standard` 的取值。 |
| `thorough` | 完整散文。每个决策都有理由。示例、考虑过的替代方案、设计历史。 |

---

### Combination matrix with workflow
### 与 workflow 的组合矩阵

|  | docs.density: terse | balanced | thorough |
|---|---|---|---|
| **workflow: minimal** | Game brief in bullets *(default)* | Game brief in prose | Game brief + rationale |
| **workflow: standard** | 5 sections, bullets | 5 sections, paragraphs | 5 sections + examples |
| **workflow: full** | 8 sections, bullets *(comprehensive but compact)* | 8 sections, paragraphs *(current full)* | 8 sections + rationale + examples |

|  | docs.density: terse | balanced | thorough |
|---|---|---|---|
| **workflow: minimal** | 要点式的游戏简报 *（默认）* | 散文式游戏简报 | 游戏简报 + 理由 |
| **workflow: standard** | 5 个章节，要点 | 5 个章节，段落 | 5 个章节 + 示例 |
| **workflow: full** | 8 个章节，要点 *（全面但紧凑）* | 8 个章节，段落 *（当前 full）* | 8 个章节 + 理由 + 示例 |

---

### Affected skills
### 受影响的技能

| Skill | terse | balanced | thorough |
|-------|-------|----------|----------|
| **design-system** | Each GDD section is 2–5 bullets. Skip Player Fantasy preambles. | Paragraphs with key decisions explained. | Full prose, decision history, alternatives considered. |
| **art-bible** | Each art bible section is a bulleted list of constraints + references. | Paragraphs explaining each visual choice. | Full prose including style explorations, references, rationale per choice. |
| **create-architecture** | Layer diagrams + decision bullets. No essays. | Diagrams + paragraph explanations of layer choices. | Full prose with rationale, trade-offs, alternatives considered per layer. |
| **ux-design** | Wireframe descriptions + interaction bullets. | Wireframes + paragraph descriptions of flows. | Full prose including user research summaries, alternative flow considerations. |
| **map-systems** | One-line system descriptions. | Brief paragraph per system + dependency notes. | Full system-by-system rationale + relationship analysis. |
| **brainstorm** | Pillar bullets + concept bullets. | Pillars + concept with brief rationale. | Pillars + concept + extensive rationale + alternatives. |

| 技能 | terse | balanced | thorough |
|-------|-------|----------|----------|
| **design-system** | 每个 GDD 章节是 2–5 条要点。跳过 Player Fantasy 引言。 | 段落，解释关键决策。 | 完整散文、决策历史、考虑过的替代方案。 |
| **art-bible** | 每个 art bible 章节是约束 + 参考的要点列表。 | 段落，解释每个视觉选择。 | 完整散文，包括风格探索、参考、每个选择的理由。 |
| **create-architecture** | 分层图 + 决策要点。无论文。 | 图 + 段落解释分层选择。 | 完整散文，含每层的理由、权衡、考虑过的替代方案。 |
| **ux-design** | 线框描述 + 交互要点。 | 线框图 + 流程的段落描述。 | 完整散文，包括用户研究摘要、替代流程考量。 |
| **map-systems** | 单行系统描述。 | 每个系统的简短段落 + 依赖说明。 | 完整的逐系统理由 + 关系分析。 |
| **brainstorm** | 支柱要点 + 概念要点。 | 支柱 + 概念及简短理由。 | 支柱 + 概念 + 详尽理由 + 替代方案。 |

---

## testing.framework

**Controls:** Which test framework the project uses — drives test-runner commands and per-engine assumptions in CI
**Values:** engine-specific (see table)
**Default:** auto-populated by `/setup-engine` based on engine choice
**Set by:** `/setup-engine`, `/settings`
**Read by:** `/test-helpers` — the only skill that references it. `/qa-plan`, `/dev-story`, `/regression-suite`, `/test-setup` and `/smoke-check` do **not** name the key, despite being plausible readers.
  *(Derived by grep. A helper-based read such as `session_state_enabled()` would not show up, so treat this list as the verified floor, not a ceiling.)*
**控制：** 项目使用哪个测试框架 — 驱动 CI 中的测试运行器命令和按引擎的假设
**取值：** 引擎相关（见表格）
**默认：** 由 `/setup-engine` 根据引擎选择自动填充
**由谁设置：** `/setup-engine`、`/settings`
**由谁读取：** `/test-helpers` — 唯一引用它的技能。`/qa-plan`、`/dev-story`、`/regression-suite`、`/test-setup` 和 `/smoke-check` 虽然看似合理的读取者，但**并未**命名该键。
  *（通过 grep 推导。像 `session_state_enabled()` 这样的辅助函数式读取不会显现，因此请将该列表视为已验证的下限，而非上限。）*

**Priority chain:** `testing.framework` in `project.yaml` → engine default
**优先级链：** `project.yaml` 中的 `testing.framework` → 引擎默认值

> **Migrated from `technical-preferences.md`.**
> **从 `technical-preferences.md` 迁移而来。**

---

### Engine defaults
### 引擎默认值

| Engine | Default test framework | Alternatives |
|--------|------------------------|--------------|
| Godot | `gdunit4` | `godot-test`, `WAT` |
| Unity | `unity-test-framework` | `nunit`, custom |
| Unreal | `unreal-automation` | Google Test, custom |

| 引擎 | 默认测试框架 | 替代方案 |
|--------|------------------------|--------------|
| Godot | `gdunit4` | `godot-test`、`WAT` |
| Unity | `unity-test-framework` | `nunit`、自定义 |
| Unreal | `unreal-automation` | Google Test、自定义 |

---

### Affected skills
### 受影响的技能

| Skill | How `testing.framework` is used |
|-------|--------------------------------|
| **qa-plan** | Test plan tailored to framework's idioms (assertion style, fixture pattern, parameterized tests) |
| **dev-story** | Test framework name passed to programmer subagent in implementation brief |
| **regression-suite** | Test file naming and discovery patterns match framework conventions |
| **test-setup** | Scaffolds the right test layout for the engine (gdUnit4 under `addons/gdUnit4/` + `tests/` for Godot; `Assets/Tests/` asmdefs for Unity; `Source/<Module>/Private/Tests/` for Unreal) |
| **smoke-check** | Invokes framework-appropriate test runner |

| 技能 | 如何使用 `testing.framework` |
|-------|--------------------------------|
| **qa-plan** | 测试计划贴合框架的惯用法（断言风格、fixture 模式、参数化测试） |
| **dev-story** | 在实现简报中将测试框架名称传给程序员子智能体 |
| **regression-suite** | 测试文件命名与发现模式匹配框架约定 |
| **test-setup** | 为该引擎搭建正确的测试布局（Godot 用 `addons/gdUnit4/` 下的 gdUnit4 + `tests/`；Unity 用 `Assets/Tests/` asmdefs；Unreal 用 `Source/<Module>/Private/Tests/`） |
| **smoke-check** | 调用与该框架相适配的测试运行器 |

---

## testing.strict

**Controls:** Whether failing or missing test evidence blocks a story from
closing, or produces a warning and lets work continue — per test type
**Values:** map of `{logic, integration, visual, ui, config}` → `true | false`
**Default:** `{logic: true, integration: true, visual: true, ui: true, config: false}`
**Set by:** `/settings`
**Read by:** `story-done`, `story-readiness`, `gate-check`, `smoke-check`, `dev-story`, `test-evidence-review`
**控制：** 失败或缺失的测试证据是阻塞 story
关闭，还是产生警告并让工作继续 — 按测试类型
**取值：** `{logic, integration, visual, ui, config}` → `true | false` 的映射
**默认：** `{logic: true, integration: true, visual: true, ui: true, config: false}`
**由谁设置：** `/settings`
**由谁读取：** `story-done`、`story-readiness`、`gate-check`、`smoke-check`、`dev-story`、`test-evidence-review`

> **Per-type, not a single bool.** A global `testing.strict: true|false` forces
> all-or-nothing: either all test failures block or none do. Per-type matches how
> most teams actually work — strict logic and visual gates, an advisory smoke check.
> **按类型，而非单一布尔值。** 全局的 `testing.strict: true|false` 会强制
> 全有或全无：要么所有测试失败都阻塞，要么都不阻塞。按类型更贴合
> 大多数团队的实际工作方式 — 严格的逻辑与视觉门禁，建议性的冒烟检查。

> **Composes with `qa.level`:** `qa.level` controls whether evidence is REQUIRED.
> `testing.strict` controls whether failures BLOCK when evidence exists. If
> `qa.level: minimal`, the strict map is effectively ignored (no evidence required
> means nothing to be strict about).
> **与 `qa.level` 组合：** `qa.level` 控制证据是否被要求。
> `testing.strict` 控制存在证据时失败是否阻塞。如果
> `qa.level: minimal`，strict 映射实际上被忽略（不要求证据
> 意味着没有什么可严格的）。

---

### Value intent per type
### 按类型的取值意图

| Type | `true` | `false` |
|------|--------|---------|
| `logic` (formulas, AI, state machines) | Unit test failures BLOCK — story cannot close | Failures WARN — story can close with warning |
| `integration` (multi-system) | Integration test failures BLOCK | Failures WARN |
| `visual` (animation, VFX, feel) | Missing/failing screenshot evidence BLOCKS (default) | Advisory only — story can close |
| `ui` (menus, HUD, screens) | Missing screenshot of the screen BLOCKS (default) | Advisory only — story can close |
| `config` (balance tuning) | Failing smoke check BLOCKS | Advisory only — story can close (default) |

| 类型 | `true` | `false` |
|------|--------|---------|
| `logic`（公式、AI、状态机） | 单元测试失败阻塞 — story 无法关闭 | 失败警告 — story 可在警告下关闭 |
| `integration`（多系统） | 集成测试失败阻塞 | 失败警告 |
| `visual`（动画、VFX、手感） | 缺失/失败的截图证据阻塞（默认） | 仅建议 — story 可关闭 |
| `ui`（菜单、HUD、画面） | 缺失该画面的截图阻塞（默认） | 仅建议 — story 可关闭 |
| `config`（平衡调参） | 冒烟检查失败阻塞 | 仅建议 — story 可关闭（默认） |

---

### Affected skills
### 受影响的技能

| Skill | strict.[type]: true | strict.[type]: false |
|-------|---------------------|----------------------|
| **story-done** | Story of that type cannot close on test/evidence failure | Story can close; warning logged in story file |
| **story-readiness** | Validates test requirements exist before implementation — blocks if absent | Validates but does not block — surfaces as warnings |
| **gate-check** | CI failures of that type block phase transition | CI failures of that type surfaced as concerns, not blockers |
| **smoke-check** | Failing smoke (config strict) blocks QA handoff | Failing smoke flagged but handoff proceeds |
| **dev-story** | References test requirements — flags story as unverifiable if absent | References test requirements — advisory only |
| **test-evidence-review** | A gap in that type's evidence is a BLOCKING item (the run ends CONCERNS) | The gap is ADVISORY |

| 技能 | strict.[type]: true | strict.[type]: false |
|-------|---------------------|----------------------|
| **story-done** | 该类型的 story 无法因测试/证据失败而关闭 | story 可关闭；警告记录到 story 文件中 |
| **story-readiness** | 在实现前验证测试要求存在 — 缺失则阻塞 | 验证但不阻塞 — 以警告形式呈现 |
| **gate-check** | 该类型的 CI 失败阻塞阶段转换 | 该类型的 CI 失败作为关注点呈现，而非阻塞项 |
| **smoke-check** | 冒烟失败（config 严格）阻塞 QA 交接 | 冒烟失败被标记，但交接继续 |
| **dev-story** | 引用测试要求 — 缺失时将该 story 标记为不可验证 | 引用测试要求 — 仅建议 |
| **test-evidence-review** | 该类型证据缺失是 BLOCKING 项（本轮以 CONCERNS 结束） | 该缺失为 ADVISORY |

> **Unset-key resolution.** Each skill reads `testing.strict.<type>`; if absent
> it reads `testing.strict` as a plain boolean (legacy form); if still absent it
> falls back to a hardcoded default. For `story-done`, `story-readiness`,
> `gate-check`, and `dev-story` the hardcoded default is the per-type default map
> above (logic/integration/visual/ui strict, config advisory). **`smoke-check` is
> the exception**: it is a build-health gate, so an unset `testing.strict.config`
> defaults to *strict* (a FAIL blocks QA hand-off) — preserving its v1.0 behavior.
> Only an explicit `testing.strict.config: false` makes a failing smoke advisory.
> **未设置键的解析。** 每个技能读取 `testing.strict.<type>`；若缺失，
> 则将 `testing.strict` 作为普通布尔值读取（旧版形式）；若仍缺失，
> 则回退到硬编码默认值。对 `story-done`、`story-readiness`、
> `gate-check` 和 `dev-story`，硬编码默认值即上面的按类型默认映射
> （logic/integration/visual/ui 严格，config 建议性）。**`smoke-check` 是
> 例外**：它是构建健康门禁，因此未设置的 `testing.strict.config`
> 默认为*严格*（FAIL 阻塞 QA 交接）— 保持其 v1.0 行为。
> 只有显式的 `testing.strict.config: false` 才让失败的冒烟检查变为建议性。

---

## qa.level

**Controls:** What test evidence is required to mark stories Done
**Values:** `minimal` | `standard` | `full`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `minimal`; `standard` yields `standard`; `full` yields `full`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** `/story-done`, `/story-readiness`, `/dev-story`, `/smoke-check`, `/gate-check`, `/qa-plan`, `/regression-suite`, `/team-qa`, `/test-evidence-review`, `/create-stories`, `/retrospective`, `/test-setup`
**控制：** 将 story 标记为 Done 需要什么测试证据
**取值：** `minimal` | `standard` | `full`
**默认：** *无* — 由 `modes.rigor` 提供（默认的 `minimal` 产出 `minimal`；`standard` 产出 `standard`；`full` 产出 `full`）
**由谁设置：** `/start`（通过 `modes.rigor`）、`/settings`
**由谁读取：** `/story-done`、`/story-readiness`、`/dev-story`、`/smoke-check`、`/gate-check`、`/qa-plan`、`/regression-suite`、`/team-qa`、`/test-evidence-review`、`/create-stories`、`/retrospective`、`/test-setup`

**Priority chain:** `qa.level` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*
**优先级链：** `project.yaml` 中的 `qa.level` → `modes.rigor` 扩展 → *（无硬编码默认值）*

> **Different axis from `testing.strict`.** `qa.level` = what evidence is required.
> `testing.strict` = do failures block. A user wanting "minimal QA" sets
> `qa.level: minimal` and the strict map becomes effectively a no-op.
> **与 `testing.strict` 不同的轴。** `qa.level` = 要求什么证据。
> `testing.strict` = 失败是否阻塞。想要“最小 QA”的用户设置
> `qa.level: minimal`，strict 映射实际上就变成空操作。

---

### Value intent
### 取值意图

| Aspect | minimal | standard | full |
|--------|---------|----------|------|
| Logic stories | No test required, no gap flagged | Unit test required (strict.logic controls block) | Unit test, and every acceptance criterion covered |
| Integration stories | No test required | Integration test or playtest doc required | Same + regression coverage |
| Visual stories | Screenshot + lead sign-off required — the look is never waived (strict.visual controls block) | Same | Same |
| UI stories | Screenshot of each screen touched required — never waived (strict.ui controls block) | Same | Same |
| Config/Data stories | No evidence required | Smoke check advisory | Smoke check required (blocking unless `testing.strict.config: false`) |
| /story-done test gate | Acceptance criteria only, except the UI and Visual/Feel screenshot, which is never waived | Enforced per story type | Enforced for every story type |
| /gate-check phase enforcement | No test gates | Logic + integration must pass | Full coverage + regression suite |
| /dev-story routing prompt | No "Test required: ..." line | Per-type test requirement included | Per-type, and every criterion must be covered |
| Regression suite required by | Never | Polish stage | Production stage |
| Best for | Jam games, throwaway prototypes, fast iteration | Most projects | Commercial, console cert, learning, paranoid teams |

| 方面 | minimal | standard | full |
|--------|---------|----------|------|
| Logic story | 不要求测试，不标记缺口 | 要求单元测试（strict.logic 控制是否阻塞） | 单元测试，且每条验收标准都被覆盖 |
| Integration story | 不要求测试 | 要求集成测试或试玩文档 | 同上 + 回归覆盖 |
| Visual story | 要求截图 + 主管签字 — 外观从不豁免（strict.visual 控制是否阻塞） | 同上 | 同上 |
| UI story | 要求每个被改动画面的截图 — 从不豁免（strict.ui 控制是否阻塞） | 同上 | 同上 |
| Config/Data story | 不要求证据 | 冒烟检查为建议性 | 要求冒烟检查（阻塞，除非 `testing.strict.config: false`） |
| /story-done 测试门禁 | 仅验收标准，但 UI 与 Visual/Feel 截图除外，后者从不豁免 | 按 story 类型执行 | 对每种 story 类型执行 |
| /gate-check 阶段执行 | 无测试门禁 | Logic + integration 必须通过 | 完整覆盖 + 回归套件 |
| /dev-story 路由提示 | 无“Test required: ...”行 | 包含按类型的测试要求 | 按类型，且每条标准都必须被覆盖 |
| 回归套件要求于 | 从不 | Polish 阶段 | Production 阶段 |
| 最适合 | Game jam、一次性原型、快速迭代 | 大多数项目 | 商业项目、主机认证、学习、偏执的团队 |

---

### Affected skills
### 受影响的技能

| Skill | minimal | standard | full |
|-------|---------|----------|------|
| **story-done** | Acceptance criteria check only — no test evidence required, except the UI and Visual/Feel screenshot, which is never waived | Per-type evidence required; strictness from `testing.strict`; more than half the criteria untested blocks | Per-type evidence required; a Config/Data smoke report blocks by default; any untested criterion blocks |
| **story-readiness** | No test requirement validated, except the UI and Visual/Feel screenshot requirement | Test requirement per story type validated | Test requirement + coverage target validated |
| **dev-story** | Routing prompt has no "Test required" line | Per-type test requirement passed to programmer agent | Per-type requirement, and every criterion must be covered by a test |
| **smoke-check** | Optional; with no game tests (WAIVED), `commands.smoke` (else `commands.build`) when set and the launch and critical-path checks carry the verdict; a build nobody launched is NOT ASSESSED | Required before phase transition | Required before every commit |
| **gate-check** | No test enforcement at phase transitions | Logic + integration tests must pass | Full coverage check + regression suite |
| **qa-plan** | Skipped entirely or minimal smoke plan | Full plan per story type | Full plan + coverage targets per system |
| **regression-suite** | Not generated | Generated at Polish stage entry | Generated at Production stage entry |
| **team-qa** | A Logic, Integration or Config/Data story without a test is WAIVED; its acceptance-criteria walk in manual QA is its evidence | The automated test is the evidence for those types | Same |
| **test-evidence-review** | A story with no test evidence is WAIVED, not MISSING; gaps in existing tests are ADVISORY; screenshots never waived | Per-type evidence reviewed; BLOCKING/ADVISORY from `testing.strict` | Same |

| 技能 | minimal | standard | full |
|-------|---------|----------|------|
| **story-done** | 仅验收标准检查 — 不要求测试证据，但 UI 与 Visual/Feel 截图除外，后者从不豁免 | 要求按类型证据；严格程度来自 `testing.strict`；超过一半标准未测试则阻塞 | 要求按类型证据；Config/Data 的冒烟报告默认阻塞；任何未测试的标准都阻塞 |
| **story-readiness** | 不验证测试要求，但 UI 与 Visual/Feel 截图要求除外 | 验证按 story 类型的测试要求 | 验证测试要求 + 覆盖率目标 |
| **dev-story** | 路由提示中没有“Test required”行 | 将按类型的测试要求传给程序员智能体 | 按类型要求，且每条标准都必须被测试覆盖 |
| **smoke-check** | 可选；在无游戏测试（WAIVED）时，若已设置则用 `commands.smoke`（否则 `commands.build`），并由启动与关键路径检查承载裁决；无人启动的构建为 NOT ASSESSED | 阶段转换前必需 | 每次提交前必需 |
| **gate-check** | 阶段转换时无测试执行 | Logic + integration 测试必须通过 | 完整覆盖检查 + 回归套件 |
| **qa-plan** | 完全跳过，或最小冒烟计划 | 按 story 类型的完整计划 | 完整计划 + 每个系统的覆盖目标 |
| **regression-suite** | 不生成 | 在进入 Polish 阶段时生成 | 在进入 Production 阶段时生成 |
| **team-qa** | 没有测试的 Logic、Integration 或 Config/Data story 为 WAIVED；其在手动 QA 中的验收标准走查即其证据 | 自动化测试是这些类型的证据 | 同上 |
| **test-evidence-review** | 没有测试证据的 story 为 WAIVED 而非 MISSING；现有测试中的缺口为 ADVISORY；截图从不豁免 | 按类型评审证据；BLOCKING/ADVISORY 来自 `testing.strict` | 同上 |

---

## qa.coverage_minimum

**Controls:** Minimum code coverage percentage enforced at `qa.level: full`
**Values:** integer 0–100, or `null` for unset
**Default:** `null`
**Set by:** `/settings`
**Read by:** `/gate-check` only. `/story-done` does not reference the key, and no CI runner reads it.
  *(Derived by grep. A helper-based read such as `session_state_enabled()` would not show up, so treat this list as the verified floor, not a ceiling.)*
**控制：** 在 `qa.level: full` 时强制执行的最低代码覆盖率百分比
**取值：** 0–100 的整数，或未设置时为 `null`
**默认：** `null`
**由谁设置：** `/settings`
**由谁读取：** 仅 `/gate-check`。`/story-done` 不引用该键，也没有 CI 运行器读取它。
  *（通过 grep 推导。像 `session_state_enabled()` 这样的辅助函数式读取不会显现，因此请将该列表视为已验证的下限，而非上限。）*

**Priority chain:** `qa.coverage_minimum` in `project.yaml` → no enforcement if `null`
**优先级链：** `project.yaml` 中的 `qa.coverage_minimum` → 若为 `null` 则不强制执行

> **Only meaningful at `qa.level: full`.** Ignored at minimal and standard. A
> non-null value at standard or minimal level emits a warning at session-start:
> *"coverage_minimum is set but qa.level is not full — value will not be enforced."*
> **仅在 `qa.level: full` 时有意义。** 在 minimal 和 standard 时被忽略。在
> standard 或 minimal 层级设置非 null 值会在会话启动时发出警告：
> *“coverage_minimum 已设置但 qa.level 不是 full — 该值不会被强制执行。”*

> **Implementation is engine-specific.** Coverage measurement is different per engine:
> - Godot: gdunit4 coverage report (markdown export)
> - Unity: Unity Test Framework coverage (xml export)
> - Unreal: gcov-style coverage from clang flags
> CCGS does not unify these — gate-check reads the engine-appropriate report.
> **实现是引擎相关的。** 覆盖率测量因引擎而异：
> - Godot：gdunit4 覆盖率报告（markdown 导出）
> - Unity：Unity Test Framework 覆盖率（xml 导出）
> - Unreal：来自 clang 标志的 gcov 风格覆盖率
> CCGS 不统一这些 — gate-check 读取与该引擎相适配的报告。

---

## strict_gate_checks

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is not checked when you set it, and nothing reads it.

> ### 保留 — 未实现
>
> **没有技能或钩子读取该设置。设置它没有任何效果。** 下面
> 描述的是预期设计，而非当前行为。
>
> 你设置该值时它不会被校验，也没有任何东西读取它。

**Controls:** Whether phase gate failures block stage transition or just warn
**Values:** `true` | `false`
**Default:** `true`
**Set by:** `/settings`
**Read by:** nothing yet (intended reader: `/gate-check`)
**控制：** 阶段门禁失败是阻塞阶段转换，还是仅发出警告
**取值：** `true` | `false`
**默认：** `true`
**由谁设置：** `/settings`
**由谁读取：** 目前无（预期读取者：`/gate-check`）

**Priority chain:** `strict_gate_checks` in `project.yaml` → hardcoded default of `true`
**优先级链：** `project.yaml` 中的 `strict_gate_checks` → 硬编码默认值 `true`

> **Different from `review_mode: solo`.** `review_mode: solo` skips the gate
> *entirely* — directors don't even run. `strict_gate_checks: false` runs the
> gate normally but treats the verdict as advisory.
> **区别于 `review_mode: solo`。** `review_mode: solo` *完全*跳过门禁 —
> 总监甚至不运行。`strict_gate_checks: false` 正常运行
> 门禁，但将裁决视为建议性。

---

### Value intent
### 取值意图

| Value | Behavior |
|-------|----------|
| `true` | Default. FAIL or BLOCKING-CONCERNS verdict stops the stage transition. `project.stage` is not advanced. User must address findings and re-run gate. |
| `false` | All gate verdicts are advisory. `/gate-check` still runs and reports findings. `project.stage` advances on user confirmation regardless of verdict. |

| 取值 | 行为 |
|-------|----------|
| `true` | 默认。FAIL 或 BLOCKING-CONCERNS 裁决会停止阶段转换。`project.stage` 不前进。用户必须处理发现并重新运行门禁。 |
| `false` | 所有门禁裁决都是建议性的。`/gate-check` 仍会运行并报告发现。无论裁决如何，`project.stage` 在用户确认后前进。 |

---

### Affected skills
### 受影响的技能

| Skill | true | false |
|-------|------|-------|
| **gate-check** | FAIL verdict stops execution before writing new stage; CONCERNS verdict prompts user but defaults to "stay at current stage." | All verdicts surfaced as informational; user is asked "advance anyway?" with default Yes. |

| 技能 | true | false |
|-------|------|-------|
| **gate-check** | FAIL 裁决在写入新阶段前停止执行；CONCERNS 裁决提示用户但默认为“留在当前阶段”。 | 所有裁决以信息形式呈现；用户被询问“仍然前进吗？”，默认答案为是。 |

---

## team.size

**Controls:** Which agents are active by default — solo devs shouldn't get studio-grade gating on every change
**Values:** `individual` | `small` | `studio`
**Default:** *none* — supplied by `modes.rigor` (`minimal`/`standard` yield `individual`, `full` yields `studio`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** All `team-*` skills, `/gate-check`, all skills that spawn agents via `Agent`
**控制：** 默认哪些智能体是活跃的 — 单人开发者不应在每次变更上都遭遇工作室级门禁
**取值：** `individual` | `small` | `studio`
**默认：** *无* — 由 `modes.rigor` 提供（`minimal`/`standard` 产出 `individual`，`full` 产出 `studio`）
**由谁设置：** `/start`（通过 `modes.rigor`）、`/settings`
**由谁读取：** 所有 `team-*` 技能、`/gate-check`、所有通过 `Agent` 生成智能体的技能

**Priority chain:** `team.size` in `project.local.yaml` → `project.yaml` → the `modes.rigor` expansion (`full` → `studio`, else `individual`) → no terminal default. Locally overridable — it is a personal-experience knob, not an on-disk artifact.
**优先级链：** `project.local.yaml` 中的 `team.size` → `project.yaml` → `modes.rigor` 扩展（`full` → `studio`，否则 `individual`）→ 无终端默认值。可在本地覆盖 — 它是个人体验旋钮，而非磁盘产物。

> **`individual` at `minimal`/`standard`, `studio` at `full`.** CCGS's audience is
> overwhelmingly solo indie developers, so the two lighter rigor tiers resolve
> `team.size` to `individual` — a `minimal` (default) or `standard` project gets one active agent
> per role, not 15 (directors and leads included). Only `rigor: full` opts into the
> full `studio` roster; a smaller team on a big project sets `team.size: small`
> explicitly, which wins over the rigor-derived value.
> **`minimal`/`standard` 为 `individual`，`full` 为 `studio`。** CCGS 的用户
> 绝大多数是单人独立开发者，因此两个较轻的严苛度层级将
> `team.size` 解析为 `individual` — `minimal`（默认）或 `standard` 项目每个角色
> 只有一个活跃智能体，而不是 15 个（含总监和主管）。只有 `rigor: full` 才选用
> 完整的 `studio` 阵容；大项目上的小团队会显式设置 `team.size: small`，
> 它优先于从严苛度推导出的值。

> **Different axis from `workflow`.** `workflow` controls *what docs are required.*
> `team.size` controls *which agents exist to make them.* A solo dev on
> `workflow: full` still doesn't need all 49 agents — they need the same coverage
> from a smaller active set.
> **与 `workflow` 不同的轴。** `workflow` 控制*要求哪些文档。*
> `team.size` 控制*存在哪些智能体来编写它们。* 处于 `workflow: full` 的单人开发者
> 仍不需要全部 49 个智能体 — 他们需要从一个更小的活跃集合中获得相同覆盖。

---

### Active agent set per value
### 每个取值的活跃智能体集合

| Value | Active set | Notes |
|-------|-----------|-------|
| `individual` | Core 8: `producer`, `game-designer`, `gameplay-programmer`, engine-specialist (engine-driven), `technical-artist`, `sound-designer`, `qa-tester`, `writer`. **Default.** | Directors and lead-* run only on explicit invocation (e.g. via `/architecture-decision`). Specialists outside the core 8 routed through their nearest core agent. Each `team-*` skill names its own set per value, which can sit outside the core 8 (`team-release` runs `release-manager`); each skill's own `team.size` list is authoritative, and the Affected skills table below mirrors it. |
| `small` | Core 15: directors (CD, TD, PR) + leads (LP, AD, QL, ND) + game-designer + systems-designer + engine-specialist + technical-artist + sound-designer + qa-tester + ux-designer + writer | `team-*` skills add their `small` set (below); most reach their full pipeline only at `studio`. |
| `studio` | All 49 agents available. Engine sub-specialists (e.g. `unity-dots-specialist` separate from `unity-specialist`) routed when relevant. The adversarial review pass in `team-combat`, `team-ui` and `team-polish`. | Commercial titles, learning the full org chart, large teams with parallel work. |

| 取值 | 活跃集合 | 备注 |
|-------|-----------|-------|
| `individual` | 核心 8 个：`producer`、`game-designer`、`gameplay-programmer`、引擎专家（由引擎驱动）、`technical-artist`、`sound-designer`、`qa-tester`、`writer`。**默认。** | 总监和 lead-* 仅在显式调用时运行（例如通过 `/architecture-decision`）。核心 8 个之外的专家通过其最近的核心智能体路由。每个 `team-*` 技能按取值声明自己的集合，可能位于核心 8 个之外（`team-release` 运行 `release-manager`）；每个技能自己的 `team.size` 列表才是权威，下面的受影响的技能表与之镜像。 |
| `small` | 核心 15 个：总监（CD、TD、PR）+ 主管（LP、AD、QL、ND）+ game-designer + systems-designer + 引擎专家 + technical-artist + sound-designer + qa-tester + ux-designer + writer | `team-*` 技能会增加其 `small` 集合（见下文）；多数只有在 `studio` 时才达到完整流水线。 |
| `studio` | 全部 49 个智能体可用。引擎子专家（例如独立于 `unity-specialist` 的 `unity-dots-specialist`）在相关时路由。`team-combat`、`team-ui` 和 `team-polish` 中的对抗式评审环节。 | 商业作品、学习完整组织架构、并行工作的大型团队。 |

---

### Affected skills
### 受影响的技能

| Skill | individual | small | studio |
|-------|------|-------|--------|
| **team-combat** | Single agent (gameplay-programmer) runs the pipeline; ai-programmer escalated only if AI work flagged | Default pipeline as documented | Default + the primary engine specialist may use its sub-specialists + adversarial review pass (Phase 5's qa-tester looks for how it breaks) |
| **team-narrative** | writer only; narrative-director invoked only on explicit pillar conflict | narrative-director + writer, + localization-lead and world-builder at `review_mode: full` | All six narrative agents, whatever the review mode |
| **team-ui** | ui-programmer + ux-designer | + accessibility-specialist + art-director | + engine UI specialist + adversarial review pass (Phase 4's reviewers look for where it fails its spec) |
| **team-audio** | sound-designer only | + audio-director + technical-artist + gameplay-programmer | + accessibility-specialist + the primary engine specialist |
| **team-level** | level-designer only | + systems-designer + art-director + qa-tester | + narrative-director + world-builder + accessibility-specialist |
| **team-qa** | qa-tester only; qa-lead invoked at phase gates only | qa-lead + qa-tester pipeline | qa-lead + per-story qa-tester spawn + sign-off |
| **team-release** | release-manager only | + producer + devops-engineer + qa-lead + community-manager | + security-engineer + analytics-engineer + localization-lead + performance-analyst, and network-programmer when the game is multiplayer |
| **team-polish** | performance-analyst + technical-artist; no programmer is active, so Phase 2's optimisation list is handed to `/dev-story` | + sound-designer + qa-tester + engine-programmer (implements Phase 2's optimisation list), and tools-programmer when Phase 1 traces a cause to a content authoring tool | engine-programmer, as at small, + adversarial review pass (Phase 5's qa-tester looks for how it breaks) |
| **team-live-ops** | live-ops-designer + economy-designer | + analytics-engineer + community-manager | + writer + narrative-director |
| **gate-check** | Panel width is `modes.workflow`'s axis, not this one (gates always run) — `team.size` affects only specialist depth within each director's review | Same as individual for directors; specialists within directors' reviews use small set | Same plus engine sub-specialists |
| **architecture-decision** | TD-ADR (in `full` review mode) + the primary engine specialist | Same | Same — no sub-specialist or adversarial reviewer at any size |

| 技能 | individual | small | studio |
|-------|------|-------|--------|
| **team-combat** | 单个智能体（gameplay-programmer）运行流水线；仅当标记了 AI 工作时才升级到 ai-programmer | 如文档所述的默认流水线 | 默认 + 主引擎专家可使用其子专家 + 对抗式评审环节（Phase 5 的 qa-tester 寻找它如何被破坏） |
| **team-narrative** | 仅 writer；仅在出现明确的支柱冲突时调用 narrative-director | narrative-director + writer，`review_mode: full` 时另加 localization-lead 和 world-builder | 全部六个叙事智能体，无论评审模式如何 |
| **team-ui** | ui-programmer + ux-designer | + accessibility-specialist + art-director | + 引擎 UI 专家 + 对抗式评审环节（Phase 4 的评审者寻找它在哪里未满足其规格） |
| **team-audio** | 仅 sound-designer | + audio-director + technical-artist + gameplay-programmer | + accessibility-specialist + 主引擎专家 |
| **team-level** | 仅 level-designer | + systems-designer + art-director + qa-tester | + narrative-director + world-builder + accessibility-specialist |
| **team-qa** | 仅 qa-tester；仅在阶段门禁时调用 qa-lead | qa-lead + qa-tester 流水线 | qa-lead + 按 story 生成 qa-tester + 签字 |
| **team-release** | 仅 release-manager | + producer + devops-engineer + qa-lead + community-manager | + security-engineer + analytics-engineer + localization-lead + performance-analyst，游戏为多人时另加 network-programmer |
| **team-polish** | performance-analyst + technical-artist；没有程序员活跃，因此 Phase 2 的优化清单交给 `/dev-story` | + sound-designer + qa-tester + engine-programmer（实现 Phase 2 的优化清单），当 Phase 1 将原因追溯到内容创作工具时另加 tools-programmer | engine-programmer，如 small，+ 对抗式评审环节（Phase 5 的 qa-tester 寻找它如何被破坏） |
| **team-live-ops** | live-ops-designer + economy-designer | + analytics-engineer + community-manager | + writer + narrative-director |
| **gate-check** | 评审组宽度属于 `modes.workflow` 的轴，而非这一轴（门禁始终运行）— `team.size` 只影响每位总监评审内的专家深度 | 对总监而言与 individual 相同；总监评审内的专家使用 small 集合 | 同上，另加引擎子专家 |
| **architecture-decision** | TD-ADR（在 `full` 评审模式下）+ 主引擎专家 | 同上 | 同上 — 无论规模多大都没有子专家或对抗式评审者 |

---

### Special cases
### 特殊情况

- `team.size` does not decide whether directors run: `/gate-check`'s panel follows `review_mode` and `modes.workflow`, and no `team-*` pipeline spawns a director phase gate. In a team skill, a "phase gate" is one of the decision points its own pipeline lists, whatever the `automation` mode.
- `individual` does not disable agents — it just changes which are active by default. Any agent can still be invoked by name.
- When `team.size: individual` and a non-core agent is needed (e.g. `network-programmer` for a multiplayer story), the skill emits an informational note and routes through the nearest active core agent.
- `team.size` 不决定总监是否运行：`/gate-check` 的评审组遵循 `review_mode` 和 `modes.workflow`，且没有任何 `team-*` 流水线生成总监阶段门禁。在团队技能中，“阶段门禁”是其自身流水线列出的决策点之一，无论 `automation` 模式如何。
- `individual` 并不禁用智能体 — 它只改变默认哪些是活跃的。任何智能体仍可按名称调用。
- 当 `team.size: individual` 且需要非核心智能体时（例如多人 story 需要 `network-programmer`），技能会发出信息性说明并通过最近的活跃核心智能体路由。

---

## platform.multiplayer

**Controls:** Whether the project includes real-time online multiplayer — determines
which specialists are routed and which architecture sections are required  
**Values:** `true` | `false`  
**Default:** none — unset is not `false`  
**Set by:** `/settings`  
**Read by:** `security-audit`, `team-release` (and the `security-engineer` agent)
**控制：** 项目是否包含实时在线多人 — 决定
路由哪些专家、要求哪些架构章节
**取值：** `true` | `false`
**默认：** 无 — 未设置不等于 `false`
**由谁设置：** `/settings`
**由谁读取：** `security-audit`、`team-release`（以及 `security-engineer` 智能体）

**Priority chain:** `platform.multiplayer` in `project.yaml` → unset (`platform.*` is locked to `project.yaml`, so `project.local.yaml` cannot set it). Nothing writes it except `/settings`, so on most projects it is unset: `/security-audit` and `/team-release` ask whether the game is multiplayer rather than reading unset as `false`.
**优先级链：** `project.yaml` 中的 `platform.multiplayer` → 未设置（`platform.*` 锁定于 `project.yaml`，因此 `project.local.yaml` 不能设置它）。除 `/settings` 外没有任何东西写入它，所以在多数项目上它未设置：`/security-audit` 和 `/team-release` 会询问游戏是否为多人，而不是把未设置解读为 `false`。

> **Distinct from `platform.online`.** `multiplayer` is *real-time multiplayer
> specifically* (network specialist, netcode review, replication architecture).
> `platform.online` covers everything else online (cloud saves, leaderboards,
> telemetry). See next section.
> **区别于 `platform.online`。** `multiplayer` *特指实时多人*
> （网络专家、netcode 评审、复制架构）。
> `platform.online` 涵盖其他所有在线内容（云存档、排行榜、
> 遥测）。见下一节。

> **This is a project attribute, not a mode.** It describes what the game is,
> not how the pipeline operates. It lives in `platform` alongside `targets`,
> `primary_input`, and `gamepad_support` — not in `modes`.
> **这是项目属性，不是模式。** 它描述游戏是什么，
> 而非流水线如何运作。它位于 `platform` 中，与 `targets`、
> `primary_input` 和 `gamepad_support` 并列 — 不在 `modes` 中。

---

### Value intent
### 取值意图

| Value | Meaning |
|-------|---------|
| `true` | Game has real-time online multiplayer. `/security-audit` runs its netcode category and rates a HIGH finding as release-blocking; `/team-release` adds `network-programmer`'s sign-off. |
| `false` | No real-time multiplayer. `/security-audit` skips the netcode category and says so; `/team-release` does not spawn `network-programmer`. |

| 取值 | 含义 |
|-------|---------|
| `true` | 游戏有实时在线多人。`/security-audit` 运行其 netcode 类别，并将 HIGH 发现评为发布阻塞；`/team-release` 增加 `network-programmer` 的签字。 |
| `false` | 无实时多人。`/security-audit` 跳过 netcode 类别并说明；`/team-release` 不生成 `network-programmer`。 |

---

### Affected skills
### 受影响的技能

| Skill | multiplayer: true | multiplayer: false |
|-------|------------------|-------------------|
| **security-audit** | Includes netcode review — authentication, replication, cheat vectors | Netcode review skipped, and the report says so |
| **team-release** | `network-programmer` included in release sign-off pipeline | `network-programmer` excluded |

| 技能 | multiplayer: true | multiplayer: false |
|-------|------------------|-------------------|
| **security-audit** | 包含 netcode 评审 — 认证、复制、作弊向量 | 跳过 netcode 评审，且报告会说明 |
| **team-release** | 发布签字流水线中包含 `network-programmer` | 排除 `network-programmer` |

No other skill reads this key: `/dev-story`, `/create-architecture` and `/gate-check`
decide networking scope from the story, GDD or architecture in front of them.
没有其他技能读取该键：`/dev-story`、`/create-architecture` 和 `/gate-check`
根据眼前 story、GDD 或架构来决定网络范围。

---

## platform.online

**Controls:** Whether the project has any online features (leaderboards, cloud saves, telemetry, IAP)
**Values:** `true` | `false`
**Default:** none — unset is not `false`
**Set by:** `/settings`
**Read by:** `security-audit`, `team-release` (and the `security-engineer` agent)
**控制：** 项目是否有任何在线功能（排行榜、云存档、遥测、IAP）
**取值：** `true` | `false`
**默认：** 无 — 未设置不等于 `false`
**由谁设置：** `/settings`
**由谁读取：** `security-audit`、`team-release`（以及 `security-engineer` 智能体）

**Priority chain:** `platform.online` in `project.yaml` → unset (`platform.*` is locked to `project.yaml`, so `project.local.yaml` cannot set it). Nothing writes it except `/settings`: `/security-audit` and `/team-release` ask rather than reading unset as `false`.
**优先级链：** `project.yaml` 中的 `platform.online` → 未设置（`platform.*` 锁定于 `project.yaml`，因此 `project.local.yaml` 不能设置它）。除 `/settings` 外没有任何东西写入它：`/security-audit` 和 `/team-release` 会询问，而不是把未设置解读为 `false`。

> **Independent of `platform.multiplayer`.** A single-player game with Steam
> Cloud and leaderboards is `online: true, multiplayer: false`. The two settings
> have different specialist routing implications.
> **独立于 `platform.multiplayer`。** 一个带 Steam
> Cloud 和排行榜的单人游戏是 `online: true, multiplayer: false`。这两个设置
> 在专家路由上有不同含义。

---

### Value intent
### 取值意图

| Value | Meaning |
|-------|---------|
| `true` | Project includes online services (cloud saves, leaderboards, achievements, telemetry, IAP, anything calling external APIs at runtime). `/security-audit` runs Category 2 (network and multiplayer — including a plaintext-token check) when this or `platform.multiplayer` is true or unset; `/team-release` adds a `security-engineer` sign-off. |
| `false` | Project is fully offline. `/security-audit` skips Category 2 only when `platform.multiplayer` is also false. |

| 取值 | 含义 |
|-------|---------|
| `true` | 项目包含在线服务（云存档、排行榜、成就、遥测、IAP、任何运行时调用外部 API 的东西）。当此项或 `platform.multiplayer` 为 true 或未设置时，`/security-audit` 运行类别 2（网络与多人 — 包括明文令牌检查）；`/team-release` 增加 `security-engineer` 签字。 |
| `false` | 项目完全离线。仅当 `platform.multiplayer` 也为 false 时，`/security-audit` 才跳过类别 2。 |

---

### Affected skills
### 受影响的技能

| Skill | online: true | online: false |
|-------|--------------|---------------|
| **security-audit** | Category 2 (network) runs — server authority, packet validation, rate limits, plaintext tokens | Category 2 skipped only when `platform.multiplayer` is also false |
| **team-release** | `security-engineer` sign-off when the game is online or stores player data | No online-driven security sign-off |

| 技能 | online: true | online: false |
|-------|--------------|---------------|
| **security-audit** | 运行类别 2（网络）— 服务器权威、数据包校验、速率限制、明文令牌 | 仅当 `platform.multiplayer` 也为 false 时跳过类别 2 |
| **team-release** | 游戏在线或存储玩家数据时由 `security-engineer` 签字 | 无由在线驱动的安全签字 |

No other skill reads this key: `/create-architecture`, `/dev-story`, `/team-live-ops`
and `/gate-check` decide online scope from the documents in front of them.
没有其他技能读取该键：`/create-architecture`、`/dev-story`、`/team-live-ops`
和 `/gate-check` 根据眼前的文档决定在线范围。

---

## platform.cert_tier

> ### WIRED — this setting is live
>
> `/launch-checklist` and `/release-checklist` both resolve it and branch on its
> four values — `none` emits no certification section, `itch` and `steam` their
> storefront's requirements, `console` full platform certification — and ask which
> platforms are in scope when it is unset.

> ### 已接入 — 该设置已生效
>
> `/launch-checklist` 和 `/release-checklist` 都会解析它，并按它的
> 四个取值分支 — `none` 不输出认证章节，`itch` 和 `steam` 输出各自
> 商店平台的要求，`console` 输出完整平台认证 — 并在其未设置时询问
> 哪些平台在范围内。

**Controls:** Certification target — scopes what `/launch-checklist` asks for
**Values:** `none` | `itch` | `steam` | `console`
**Default:** *none* — unset stays unset, so the skills ask
**Set by:** `/settings` — nothing else writes it, so it stays unset (and the skills ask) until you set it
**Read by:** `/launch-checklist`, `/release-checklist`
**控制：** 认证目标 — 限定 `/launch-checklist` 询问的范围
**取值：** `none` | `itch` | `steam` | `console`
**默认：** *无* — 未设置就保持未设置，因此技能会询问
**由谁设置：** `/settings` — 没有其他东西写入它，因此在你设置之前它保持未设置（且技能会询问）
**由谁读取：** `/launch-checklist`、`/release-checklist`

**Priority chain:** `platform.cert_tier` in `project.yaml` → unset (no default is
substituted: unset is a missing decision, `none` is a made one, and the skills
must tell them apart)
**优先级链：** `project.yaml` 中的 `platform.cert_tier` → 未设置（不替入任何默认值：
未设置是缺失的决策，`none` 是已做的决策，技能必须区分二者）

---

### Value intent
### 取值意图

| Value | Required compliance | Best for |
|-------|---------------------|----------|
| `none` | No certification | Internal releases, alphas, jam games (an explicit choice — unset is not `none`) |
| `itch` | itch.io upload requirements (build size, page setup, age tags) | Indie web/desktop releases |
| `steam` | Steamworks integration, store page, achievements, depot build, system requirements, common content rules | Commercial PC releases |
| `console` | Platform certification (PlayStation/Xbox/Switch) — heavy compliance: TRC/XR/Lotcheck, save data rules, controller mapping rules, age rating boards | Console releases |

| 取值 | 要求的合规项 | 最适合 |
|-------|---------------------|----------|
| `none` | 无认证 | 内部发布、alpha、game jam（一个明确的选择 — 未设置不等于 `none`） |
| `itch` | itch.io 上传要求（构建大小、页面设置、年龄标签） | 独立网页/桌面发布 |
| `steam` | Steamworks 集成、商店页面、成就、depot 构建、系统要求、通用内容规则 | 商业 PC 发布 |
| `console` | 平台认证（PlayStation/Xbox/Switch）— 繁重合规：TRC/XR/Lotcheck、存档数据规则、手柄映射规则、年龄分级机构 | 主机发布 |

---

### Affected skills
### 受影响的技能

| Skill | none | itch | steam | console |
|-------|------|------|-------|---------|
| **launch-checklist** | Internal launch only — no external requirements | + itch.io page setup, butler upload, build size | + Steamworks integration, store page, achievements depot, common content checks | + Platform-specific TRC, certification submission, console save format compliance |
| **release-checklist** | Smoke pass + version bump only | + itch.io page live, build uploaded to butler | + Steam store page live, depot pushed, achievements live | + Platform submission accepted, age rating boards cleared |

| 技能 | none | itch | steam | console |
|-------|------|------|-------|---------|
| **launch-checklist** | 仅内部发布 — 无外部要求 | + itch.io 页面设置、butler 上传、构建大小 | + Steamworks 集成、商店页面、成就 depot、通用内容检查 | + 平台特定 TRC、认证提交、主机存档格式合规 |
| **release-checklist** | 仅冒烟通过 + 版本号提升 | + itch.io 页面上线、构建上传到 butler | + Steam 商店页面上线、depot 推送、成就上线 | + 平台提交被接受、年龄分级机构已通过 |

---

## accessibility.target

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is checked for valid spelling when you set it, and then ignored.
> The accessibility-specialist routing and the Polish-stage audit described
> below **do not happen at any level** — `/team-ui`, `/team-level`,
> `/team-polish` and `/gate-check` do not read this setting, and `/start`
> does not ask for it.

> ### 保留 — 未实现
>
> **没有技能或钩子读取该设置。设置它没有任何效果。** 下面
> 描述的是预期设计，而非当前行为。
>
> 你设置该值时会校验拼写是否有效，然后就忽略它。
> 下面描述的 accessibility-specialist 路由和 Polish 阶段审计
> **在任何层级都不会发生** — `/team-ui`、`/team-level`、
> `/team-polish` 和 `/gate-check` 都不读取该设置，`/start`
> 也不会询问它。

**Controls:** Accessibility commitment level — routes accessibility specialist and gates audit requirements
**Values:** `none` | `standard` | `aaa`
**Default:** `none`
**Set by:** `/settings`
**Read by:** nothing yet (intended readers: `/team-ui`, `/team-level`, `/team-polish`, `/gate-check`)
**控制：** 无障碍承诺级别 — 路由无障碍专家并门禁审计要求
**取值：** `none` | `standard` | `aaa`
**默认：** `none`
**由谁设置：** `/settings`
**由谁读取：** 目前无（预期读取者：`/team-ui`、`/team-level`、`/team-polish`、`/gate-check`）

**Priority chain:** `accessibility.target` in `project.yaml` → hardcoded default of `none`
**优先级链：** `project.yaml` 中的 `accessibility.target` → 硬编码默认值 `none`

> **Default is `none`, not `standard`.** Most CCGS users are solo devs and jam-game
> makers — defaulting to `standard` would auto-spawn the accessibility specialist
> for projects where it's overhead. `/start` does not ask about it; you set it with
> `/settings`.
> **默认是 `none`，不是 `standard`。** 大多数 CCGS 用户是单人开发者和 game jam
> 制作者 — 默认为 `standard` 会为那些无障碍专家纯属开销的项目自动生成
> 该专家。`/start` 不询问它；你用
> `/settings` 设置它。

---

### Value intent
### 取值意图

| Value | Required features | Specialist routing |
|-------|-------------------|--------------------|
| `none` | None enforced | `accessibility-specialist` not spawned |
| `standard` | Colorblind-safe palette, subtitles for any voice content, key remapping | `accessibility-specialist` runs in team-ui, team-level |
| `aaa` | Full Game Accessibility Guidelines: motor, vision, hearing, cognitive categories | `accessibility-specialist` runs in all team-* skills; mandatory audit at Polish stage |

| 取值 | 要求的功能 | 专家路由 |
|-------|-------------------|--------------------|
| `none` | 不强制执行任何功能 | 不生成 `accessibility-specialist` |
| `standard` | 色盲安全调色板、任何语音内容的字幕、按键重映射 | `accessibility-specialist` 在 team-ui、team-level 中运行 |
| `aaa` | 完整 Game Accessibility Guidelines：运动、视觉、听觉、认知类别 | `accessibility-specialist` 在所有 team-* 技能中运行；Polish 阶段强制审计 |

---

### Affected skills
### 受影响的技能

| Skill | none | standard | aaa |
|-------|------|----------|-----|
| **team-ui** | accessibility-specialist not spawned | accessibility-specialist included for HUD/menu reviews | accessibility-specialist included for every screen + accessibility audit pass |
| **team-level** | accessibility-specialist not spawned | accessibility-specialist reviews level for colorblind safety and signposting | accessibility-specialist reviews for full mobility/audio/cognitive considerations |
| **team-polish** | No accessibility pass | Final accessibility pass added | Full accessibility audit required before completion |
| **gate-check** | No accessibility check at any stage | Polish gate checks for the standard required features | Polish gate requires full Game Accessibility Guidelines compliance audit |

| 技能 | none | standard | aaa |
|-------|------|----------|-----|
| **team-ui** | 不生成 accessibility-specialist | HUD/菜单评审包含 accessibility-specialist | 每个画面都包含 accessibility-specialist + 无障碍审计环节 |
| **team-level** | 不生成 accessibility-specialist | accessibility-specialist 评审关卡的色盲安全和指示标识 | accessibility-specialist 评审完整移动/音频/认知考量 |
| **team-polish** | 无无障碍环节 | 增加最终无障碍环节 | 完成前要求完整无障碍审计 |
| **gate-check** | 任何阶段都无无障碍检查 | Polish 门禁检查标准的必需功能 | Polish 门禁要求完整 Game Accessibility Guidelines 合规审计 |

---

## cadence.sprint_length and cadence.milestone_length
## cadence.sprint_length 与 cadence.milestone_length

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> No reference anywhere outside this file.

> ### 保留 — 未实现
>
> **没有技能或钩子读取该设置。设置它没有任何效果。** 下面
> 描述的是预期设计，而非当前行为。
>
> 本文件之外没有任何引用。

**Controls:** Default sprint and milestone durations for planning
**Values:**
- `sprint_length`: `1w` | `2w` | `3w` | `4w` | `none`
- `milestone_length`: `4w` | `6w` | `8w` | `12w`
**Defaults:** `sprint_length: 2w`, `milestone_length: 8w`
**Set by:** `/settings`
**Read by:** nothing yet (intended readers: `/sprint-plan`, `/milestone-review`, `/sprint-status`, future velocity tracking)
**控制：** 规划用的默认 sprint 与里程碑时长
**取值：**
- `sprint_length`：`1w` | `2w` | `3w` | `4w` | `none`
- `milestone_length`：`4w` | `6w` | `8w` | `12w`
**默认值：** `sprint_length: 2w`、`milestone_length: 8w`
**由谁设置：** `/settings`
**由谁读取：** 目前无（预期读取者：`/sprint-plan`、`/milestone-review`、`/sprint-status`、未来的速度跟踪）

**Priority chain:** `cadence.*` in `project.yaml` → hardcoded defaults
**优先级链：** `project.yaml` 中的 `cadence.*` → 硬编码默认值

> **`none` for `sprint_length`** means continuous-flow / kanban-style — no sprint boundaries.
> `/sprint-plan` is then invoked manually as needed. Velocity tracking
> is per-week rather than per-sprint.
> **`sprint_length` 取 `none`** 意味着持续流动 / 看板式 — 无 sprint 边界。
> 届时按需手动调用 `/sprint-plan`。速度跟踪
> 按周而非按 sprint。

---

### Affected skills
### 受影响的技能

| Skill | What changes |
|-------|--------------|
| **sprint-plan** | Capacity calculated as `sprint_length × team.size velocity baseline`. `none` makes the skill emit a continuous-flow plan instead. |
| **milestone-review** | Milestone window for retrospective scope = `milestone_length`. |
| **sprint-status** | Burn-down chart x-axis spans `sprint_length`. |
| **retrospective** | Sprint retro fires at `sprint_length` cadence (or weekly when sprint_length is `none`). |

| 技能 | 哪些会改变 |
|-------|--------------|
| **sprint-plan** | 容量计算为 `sprint_length × team.size velocity baseline`。`none` 会使技能改为输出持续流动计划。 |
| **milestone-review** | 回顾范围的里程碑窗口 = `milestone_length`。 |
| **sprint-status** | 燃尽图 x 轴跨度 = `sprint_length`。 |
| **retrospective** | Sprint 回顾按 `sprint_length` 节奏触发（当 sprint_length 为 `none` 时按周）。 |

---

## performance.target_framerate and performance.frame_budget_ms
## performance.target_framerate 与 performance.frame_budget_ms

**Controls:** The frame-rate target and its per-frame millisecond budget
**Values:** integers (e.g. `60`, `16.67`)
**Default:** none — unset means no budget was ever committed to
**Set by:** the user, by hand or via `/settings`
**Read by:** `/perf-profile`, `/gate-check`, `/team-polish`
**控制：** 帧率目标及其每帧毫秒预算
**取值：** 整数（例如 `60`、`16.67`）
**默认：** 无 — 未设置意味着从未承诺过任何预算
**由谁设置：** 用户手动设置，或通过 `/settings`
**由谁读取：** `/perf-profile`、`/gate-check`、`/team-polish`

## performance.draw_call_limit and performance.memory_ceiling_mb
## performance.draw_call_limit 与 performance.memory_ceiling_mb

**Controls:** Per-frame draw-call ceiling and total memory ceiling
**Values:** integers
**Default:** none — unset means no budget was ever committed to
**Set by:** the user, by hand or via `/settings`
**Read by:** `/perf-profile`, `/gate-check`, `/team-polish`
**控制：** 每帧绘制调用上限和总内存上限
**取值：** 整数
**默认：** 无 — 未设置意味着从未承诺过任何预算
**由谁设置：** 用户手动设置，或通过 `/settings`
**由谁读取：** `/perf-profile`、`/gate-check`、`/team-polish`

> **Every setting needs its own `## ` heading in this file, not just a table
> row.** The dead-settings audit derives what it checks from those headings, so
> a setting mentioned only inside a table is invisible to it — it can neither be
> reported DEAD if it loses its reader, nor caught if it gains one. A setting
> outside the audit's field of view is exactly how a documented-but-dead entry,
> or a working-but-listed-as-dead one, survives unnoticed.
>
> **Unset is not zero and not a default.** A budget nobody set is not a budget
> that was met — `/perf-profile` must report `NOT ASSESSED` for a metric with no
> committed target rather than measuring against a placeholder. A headroom figure
> computed against an invented budget, with no profiler data behind it, reads as
> a pass and is not one; see obligations 1 and 2 in `.claude/rules/skill-authoring.md`.
> **每个设置在本文件中都需要自己的 `## ` 标题，而不仅仅是一行表格
> 记录。** 死设置审计从这些标题推导它检查什么，因此
> 只出现在表格中的设置在它看来是不可见的 — 它既无法在失去
> 读取者时被报告为 DEAD，也无法在获得读取者时被捕获。审计
> 视野之外的设置，正是已记录但已死，或工作正常却被列为已死的条目
> 在无人注意下存活的方式。
>
> **未设置不是零，也不是默认值。** 没人设置的预算不是已被满足
> 的预算 — 对于没有承诺目标的指标，`/perf-profile` 必须报告 `NOT ASSESSED`，
> 而不是对着占位值测量。一个相对凭空发明的预算计算出的余量数字，
> 背后没有 profiler 数据，看起来像通过，但并非通过；见
> `.claude/rules/skill-authoring.md` 中的义务 1 和 2。

## performance.enforce

**Controls:** Whether performance budget violations warn or block
**Values:** `warn` | `block` | `off`
**Default:** `warn`
**Set by:** `/settings`
**Read by:** `/perf-profile`, `/gate-check`, CI runner
**控制：** 性能预算违规是发出警告还是阻塞
**取值：** `warn` | `block` | `off`
**默认：** `warn`
**由谁设置：** `/settings`
**由谁读取：** `/perf-profile`、`/gate-check`、CI 运行器

**Priority chain:** `performance.enforce` in `project.local.yaml` → `project.yaml` → hardcoded default of `warn`, resolved by `resolve_config --keys performance.enforce`
**优先级链：** `project.local.yaml` 中的 `performance.enforce` → `project.yaml` → 硬编码默认值 `warn`，由 `resolve_config --keys performance.enforce` 解析

> **Read it from the resolved block, never from `project.yaml` directly.** The key is on the `/settings --local` whitelist. `/perf-profile` Phase 0 and `/gate-check` Section 3 are the two readers the table above promises — a key that is enum-validated, accepted and displayed while nothing reads it is exactly the failure this warning guards against.
> **从解析后的块中读取它，绝不直接从 `project.yaml` 读取。** 该键在 `/settings --local` 白名单中。`/perf-profile` Phase 0 和 `/gate-check` Section 3 是上表承诺的两个读取者 — 一个被枚举校验、接受并展示、却没有任何东西读取的键，正是该警告所防范的失败情形。

> **Mirrors the `testing.strict` pattern.** Defines what happens when a budget
> defined in `performance.target_framerate`, `frame_budget_ms`, `draw_call_limit`,
> or `memory_ceiling_mb` is exceeded.
> **镜像 `testing.strict` 的模式。** 定义当 `performance.target_framerate`、`frame_budget_ms`、`draw_call_limit`
> 或 `memory_ceiling_mb` 中定义的预算被超出时会发生什么。

---

### Value intent
### 取值意图

| Value | Behavior |
|-------|----------|
| `warn` | Default. Profile runs flag violations as findings. CI logs them but doesn't fail. `/gate-check` surfaces them as concerns, not blockers. |
| `block` | Profile failures block CI. `/gate-check` treats violations as FAIL verdict (Polish stage onward). |
| `off` | Performance budgets are informational only — no profile runs gated, no findings surfaced. |

| 取值 | 行为 |
|-------|----------|
| `warn` | 默认。性能分析运行会将违规标记为发现。CI 记录它们但不会失败。`/gate-check` 将它们作为关注点呈现，而非阻塞项。 |
| `block` | 性能分析失败阻塞 CI。`/gate-check` 将违规视为 FAIL 裁决（Polish 阶段及之后）。 |
| `off` | 性能预算仅供参考 — 不门禁任何性能分析运行，不呈现任何发现。 |

---

## project.stage

**Controls:** The current development phase — determines which gate-check
validates and what artifacts are expected to exist  
**Values:** `Concept` | `Systems Design` | `Technical Setup` | `Pre-Production` | `Production` | `Polish` | `Release`  
**Default:** `Concept`  
**Set by:** `/gate-check` on a PASS, or on a CONCERNS the user explicitly accepts (the accepted risks are recorded); a FAIL never advances it — never set manually  
**Read by:** `gate-check`, `project-stage-detect`, `help`, `day-one-patch`, `team-release`, `launch-checklist`, `release-checklist`, `map-systems`, `team-qa`, `adopt`
**控制：** 当前开发阶段 — 决定哪个 gate-check
校验，以及预期存在哪些产物
**取值：** `Concept` | `Systems Design` | `Technical Setup` | `Pre-Production` | `Production` | `Polish` | `Release`
**默认：** `Concept`
**由谁设置：** `/gate-check` 在 PASS 时，或在用户明确接受的 CONCERNS 时（被接受的风险会被记录）；FAIL 从不推进它 — 绝不手动设置
**由谁读取：** `gate-check`、`project-stage-detect`、`help`、`day-one-patch`、`team-release`、`launch-checklist`、`release-checklist`、`map-systems`、`team-qa`、`adopt`

> **Stage count:** This document uses the
> 7-stage reality implemented by gate-check:
> `Concept | Systems Design | Technical Setup | Pre-Production | Production | Polish | Release`
> **阶段数量：** 本文档使用
> gate-check 实现的 7 阶段现实：
> `Concept | Systems Design | Technical Setup | Pre-Production | Production | Polish | Release`

> **This is a project attribute, not a mode.** It records where the project is
> in its lifecycle. Only `/start` (at onboarding) and `/gate-check` write it —
> `/gate-check` on a PASS verdict with user confirmation, or on a CONCERNS
> verdict whose risks the user explicitly accepts (they are recorded); a FAIL never advances it.
> Never write it manually mid-session except to correct an incorrect auto-detect.
> **这是项目属性，不是模式。** 它记录项目在其生命周期中的位置。
> 只有 `/start`（在入门时）和 `/gate-check` 写入它 —
> `/gate-check` 在 PASS 裁决且用户确认时，或在 CONCERNS
> 裁决且用户明确接受其风险时（会被记录）；FAIL 从不推进它。
> 会话中途绝不手动写入它，除非是为了纠正错误的自动检测。

> **Legacy fallback + dual-write.** Stage is read from `project.stage` in
> `project.yaml` first, then legacy `production/stage.txt`, then artifact
> auto-detection. When `/gate-check` advances the stage it dual-writes BOTH
> `project.yaml` and `production/stage.txt`, so hooks that have not migrated
> still resolve correctly. `/start` also dual-writes the initial stage. The
> legacy `.txt` file is retired at `.claude/scripts/migrate-v1-config.sh --finalize`.
> **旧版回退 + 双写。** 阶段先读取 `project.yaml` 中的 `project.stage`，
> 然后回退到旧版 `production/stage.txt`，再进行产物
> 自动检测。当 `/gate-check` 推进阶段时，它会同时写入
> `project.yaml` 和 `production/stage.txt`，因此尚未迁移的钩子
> 仍能正确解析。`/start` 也会双写初始阶段。旧版 `.txt`
> 文件在 `.claude/scripts/migrate-v1-config.sh --finalize` 时退役。

---

### Stage progression and gate requirements
### 阶段推进与门禁要求

Each row is the gate that must be passed to advance FROM that stage.
每一行是从该阶段前进所必须通过的门禁。

| From stage | Key artifacts required to pass | gate-check writes |
|------------|-------------------------------|-------------------|
| **Concept** | `game-concept.md`, design pillars, Visual Identity Anchor | `Systems Design` |
| **Systems Design** | `systems-index.md`, all MVP GDDs reviewed, cross-GDD consistency check | `Technical Setup` |
| **Technical Setup** | Engine configured, art bible sections 1–4 (at `standard`, only if visual stories exist), 3+ ADRs, architecture doc, traceability index, test framework, accessibility and interaction-pattern docs | `Pre-Production` |
| **Pre-Production** | Epics defined, first sprint plan, UX specs, control manifest (a Vertical Slice is recommended, not required) | `Production` |
| **Production** | Core mechanics implemented, main path playable, smoke check passes, QA sign-off | `Polish` |
| **Polish** | All features complete, content complete, localization, security audit, no open S1–S3 bugs | `Release` |

| 从阶段 | 通过所需的关键产物 | gate-check 写入 |
|------------|-------------------------------|-------------------|
| **Concept** | `game-concept.md`、设计支柱、Visual Identity Anchor | `Systems Design` |
| **Systems Design** | `systems-index.md`、所有 MVP GDD 已评审、跨 GDD 一致性检查 | `Technical Setup` |
| **Technical Setup** | 引擎已配置、art bible 第 1–4 章节（在 `standard` 时，仅当存在视觉 story）、3+ 个 ADR、架构文档、可追溯性索引、测试框架、无障碍与交互模式文档 | `Pre-Production` |
| **Pre-Production** | Epic 已定义、首个 sprint 计划、UX 规格、control manifest（推荐垂直切片，但不要求） | `Production` |
| **Production** | 核心机制已实现、主路径可玩、冒烟检查通过、QA 签字 | `Polish` |
| **Polish** | 所有功能完成、内容完成、本地化、安全审计、无未解决的 S1–S3 缺陷 | `Release` |

Gates adjust per `modes.workflow` — see `modes.workflow` section for what is
required at `standard` and `minimal` levels.
门禁按 `modes.workflow` 调整 — 在 `standard` 和 `minimal` 层级要求什么，
见 `modes.workflow` 章节。

---

### Affected skills
### 受影响的技能

| Skill | How it uses stage |
|-------|------------------|
| **gate-check** | Reads current stage to determine which gate to validate. Writes next stage on PASS, or on a CONCERNS the user explicitly accepts. |
| **project-stage-detect** | Reads `project.stage` first — if set, uses it as authoritative. Falls back to heuristic detection only if absent. |
| **help** | Uses stage to determine "where are you in the pipeline" and surfaces the correct next steps. |
| **sprint-status** | Displays current stage in status summary. |
| **day-one-patch** | Proceeds only when the stage is `Release` or `Polish`; otherwise says it is not appropriate yet. |
| **team-release** | Stops before Phase 1 unless the stage is `Release` ("run `/gate-check release` first"); proceeding takes an explicit override, recorded in the go/no-go record and the report. Never writes the stage. |

| 技能 | 它如何使用阶段 |
|-------|------------------|
| **gate-check** | 读取当前阶段以确定要校验哪个门禁。在 PASS 时，或在用户明确接受的 CONCERNS 时，写入下一阶段。 |
| **project-stage-detect** | 先读取 `project.stage` — 若已设置，则将其作为权威。仅在缺失时回退到启发式检测。 |
| **help** | 使用阶段来确定“你在流水线的哪个位置”，并呈现正确的下一步。 |
| **sprint-status** | 在状态摘要中显示当前阶段。 |
| **day-one-patch** | 仅当阶段为 `Release` 或 `Polish` 时才继续；否则说明尚不适用。 |
| **team-release** | 除非阶段为 `Release`，否则在 Phase 1 前停止（“先运行 `/gate-check release`”）；继续需要显式覆盖，并记录在 go/no-go 记录和报告中。从不写入阶段。 |

---

## project.kind

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> No reference anywhere outside this file.

> ### 保留 — 未实现
>
> **没有技能或钩子读取该设置。设置它没有任何效果。** 下面
> 描述的是预期设计，而非当前行为。
>
> 本文件之外没有任何引用。

**Controls:** What type of project this is — routes skill subsets
**Values:** `game` | `tool` | `engine` | `mod` | `library`
**Default:** `game`
**Set by:** `/start`, `/setup-engine`
**Read by:** Many skills (advisory routing — see below)
**控制：** 这是哪种类型的项目 — 路由技能子集
**取值：** `game` | `tool` | `engine` | `mod` | `library`
**默认：** `game`
**由谁设置：** `/start`、`/setup-engine`
**由谁读取：** 许多技能（建议性路由 — 见下文）

**Priority chain:** `project.kind` in `project.yaml` → hardcoded default of `game`
**优先级链：** `project.yaml` 中的 `project.kind` → 硬编码默认值 `game`

---

### Value intent
### 取值意图

| Value | Meaning | What's deactivated |
|-------|---------|-------------------|
| `game` | Default. Full CCGS framework applies. | Nothing |
| `tool` | Developer tool, not a game | Skip art bible, narrative, level design, playtesting |
| `engine` | Custom engine or library underneath games | Skip game-specific concerns entirely (narrative, art, playtest) |
| `mod` | Mod for an existing game | Skip engine setup; assume parent engine; reduce architecture scope |
| `library` | Reusable library | Emphasize tests + API design; design docs lighter; no asset pipeline |

| 取值 | 含义 | 哪些被停用 |
|-------|---------|-------------------|
| `game` | 默认。适用完整 CCGS 框架。 | 无 |
| `tool` | 开发者工具，不是游戏 | 跳过 art bible、叙事、关卡设计、试玩 |
| `engine` | 游戏之下的自定义引擎或库 | 完全跳过游戏特定关注点（叙事、美术、试玩） |
| `mod` | 现有游戏的模组 | 跳过引擎设置；假定父引擎；缩减架构范围 |
| `library` | 可复用库 | 强调测试 + API 设计；设计文档更轻；无资产管线 |

---

### Affected skills
### 受影响的技能

| Skill | game | tool | engine | mod | library |
|-------|------|------|--------|-----|---------|
| **brainstorm** | Full game-concept output | Tool concept output (user, problem, solution) | Engine concept (target use cases, scope) | Mod concept (what changes) | Library concept (API surface, target consumers) |
| **art-bible** | Required at appropriate workflow level | Skipped | Skipped | Optional (depends on visual scope) | Skipped |
| **map-systems** | Full game systems decomposition | Tool subsystems | Engine subsystems | Modified-system map | Library module map |
| **playtest-report** | Required at appropriate stages | Skipped or replaced with user testing | Skipped | Required (compatibility testing) | Skipped or replaced with API usage testing |
| **setup-engine** | Game engine setup | Skipped or replaced with build tool setup | Self-referential — engine IS the project | Parent engine assumed | Skipped or replaced with library scaffolding |

| 技能 | game | tool | engine | mod | library |
|-------|------|------|--------|-----|---------|
| **brainstorm** | 完整的游戏概念输出 | 工具概念输出（用户、问题、解决方案） | 引擎概念（目标用例、范围） | 模组概念（什么会改变） | 库概念（API 表面、目标消费者） |
| **art-bible** | 在适当工作流层级要求 | 跳过 | 跳过 | 可选（取决于视觉范围） | 跳过 |
| **map-systems** | 完整游戏系统分解 | 工具子系统 | 引擎子系统 | 修改系统映射 | 库模块映射 |
| **playtest-report** | 在适当阶段要求 | 跳过或由用户测试替代 | 跳过 | 要求（兼容性测试） | 跳过或由 API 使用测试替代 |
| **setup-engine** | 游戏引擎设置 | 跳过或由构建工具设置替代 | 自指 — 引擎就是项目 | 假定父引擎 | 跳过或由库脚手架替代 |

---

## engine.name and specialists
## engine.name 与专家

**Controls:** Which engine-specific specialist agents are routed to for code
implementation, review, and architecture validation  
**Values:** `Godot` | `Unity` | `Unreal`  
**Default:** `[UNSET]` — must be configured via `/setup-engine`  
**Set by:** `/setup-engine`  
**Read by:** `dev-story`, `code-review`, `architecture-decision`, `create-architecture`, `team-combat`, `team-ui`, `team-audio`
**控制：** 代码实现、评审和架构校验时路由到哪些引擎特定专家智能体
**取值：** `Godot` | `Unity` | `Unreal`
**默认：** `[UNSET]` — 必须通过 `/setup-engine` 配置
**由谁设置：** `/setup-engine`
**由谁读取：** `dev-story`、`code-review`、`architecture-decision`、`create-architecture`、`team-combat`、`team-ui`、`team-audio`

> **Currently stored in `technical-preferences.md`**, not `project.yaml`. After
> YAML expansion, `engine.name` and the specialist routing table move to
> `project.yaml specialists` block. Skill behavior is unchanged — only the
> source file changes.
> **目前存储在 `technical-preferences.md` 中**，而非 `project.yaml`。YAML 扩展之后，
> `engine.name` 和专家路由表将移到
> `project.yaml specialists` 块。技能行为不变 — 只有
> 源文件改变。

> **This is a project attribute, not a mode.** Engine choice drives specialist
> routing the same way `platform.multiplayer` drives network routing — skills
> respond to a fact about the project, not a process preference.
> **这是项目属性，不是模式。** 引擎选择驱动专家路由，
> 就像 `platform.multiplayer` 驱动网络路由一样 — 技能
> 响应项目的事实，而非流程偏好。

---

### Specialist routing by engine
### 按引擎的专家路由

| Engine | Language/code specialist | Shader specialist | UI specialist | Additional specialists |
|--------|--------------------------|-------------------|---------------|----------------------|
| **Godot** | `godot-gdscript-specialist` (GDScript) or `godot-csharp-specialist` (C#) — driven by `engine.language` | `godot-shader-specialist` | `godot-specialist` | `godot-gdextension-specialist` |
| **Unity** | `unity-specialist` | `unity-shader-specialist` | `unity-ui-specialist` | `unity-addressables-specialist`, `unity-dots-specialist` |
| **Unreal** | `unreal-specialist` | `unreal-specialist` | `ue-umg-specialist` | `ue-gas-specialist`, `ue-blueprint-specialist`, `ue-replication-specialist` |
| **[UNSET]** | No specialist spawned — warning emitted | No specialist spawned | No specialist spawned | None |

| 引擎 | 语言/代码专家 | 着色器专家 | UI 专家 | 附加专家 |
|--------|--------------------------|-------------------|---------------|----------------------|
| **Godot** | `godot-gdscript-specialist`（GDScript）或 `godot-csharp-specialist`（C#）— 由 `engine.language` 驱动 | `godot-shader-specialist` | `godot-specialist` | `godot-gdextension-specialist` |
| **Unity** | `unity-specialist` | `unity-shader-specialist` | `unity-ui-specialist` | `unity-addressables-specialist`、`unity-dots-specialist` |
| **Unreal** | `unreal-specialist` | `unreal-specialist` | `ue-umg-specialist` | `ue-gas-specialist`、`ue-blueprint-specialist`、`ue-replication-specialist` |
| **[UNSET]** | 不生成专家 — 发出警告 | 不生成专家 | 不生成专家 | 无 |

---

### Affected skills
### 受影响的技能

| Skill | How engine.name is used |
|-------|------------------------|
| **dev-story** | Routes code stories to a programmer agent, then hands the changed files to the language specialist (the generic engine specialist when none is set) for an engine-API check. |
| **code-review** | Routes review to language, shader, or UI specialist based on file type being reviewed. |
| **architecture-decision** | Loads `docs/engine-reference/[engine]/VERSION.md` before authoring. Spawns engine specialist to validate ADR for API correctness and post-cutoff compatibility. |
| **create-architecture** | Includes engine-specific constraints and patterns in architecture doc based on engine choice. |
| **team-combat / team-ui / team-audio** | Spawn the engine specialist their pipeline names: team-combat the primary engine specialist (from `team.size: small`), team-ui the engine UI specialist (`specialists.ui`, at `studio`), team-audio the primary engine specialist (at `studio`). The other six `team-*` skills spawn none. |

| 技能 | 如何使用 engine.name |
|-------|------------------------|
| **dev-story** | 将代码 story 路由给程序员智能体，然后将变更文件交给语言专家（未设置时为通用引擎专家）进行引擎 API 检查。 |
| **code-review** | 根据被评审的文件类型，将评审路由给语言、着色器或 UI 专家。 |
| **architecture-decision** | 撰写前加载 `docs/engine-reference/[engine]/VERSION.md`。生成引擎专家以校验 ADR 的 API 正确性和版本截止后的兼容性。 |
| **create-architecture** | 根据引擎选择，在架构文档中包含引擎特定约束与模式。 |
| **team-combat / team-ui / team-audio** | 生成其流水线指定的引擎专家：team-combat 生成主引擎专家（来自 `team.size: small`），team-ui 生成引擎 UI 专家（`specialists.ui`，在 `studio` 时），team-audio 生成主引擎专家（在 `studio` 时）。其他六个 `team-*` 技能不生成任何专家。 |

---

## commands

> **Live since the run-and-observe step.** This block was RESERVED — written by
> `/setup-engine`, read by nothing — through most of v1.1. `test`, `smoke` and
> `build` gained readers as the parse-check and smoke gates landed; `run` gained
> its reader last, when `/dev-story` Phase 6 step 4 started launching the game to
> look at it. The per-skill table at the bottom is now current behaviour, not
> intent. `validate-push.sh` was once named as a reader and never was.
> **自 run-and-observe 步骤起已生效。** 该块曾是 RESERVED — 由
> `/setup-engine` 写入，无人读取 — 贯穿 v1.1 的大部分时间。随着解析检查和冒烟门禁落地，
> `test`、`smoke` 和 `build` 获得了读取者；`run` 最后获得
> 读取者，那是 `/dev-story` Phase 6 第 4 步开始启动游戏
> 去观察它的时候。底部的按技能表现在是当前行为，而非
> 意图。`validate-push.sh` 曾被列为读取者，却从来不是。

**Controls:** Explicit shell commands to build, test, run, and smoke-test the project
**Values:** strings — shell-executable commands
**Default:** `[UNSET]` — populated by `/setup-engine` with engine-typical defaults
**Set by:** `/setup-engine`, `/settings`
**Written by:** `/setup-engine`, `/settings`. **Read by:** `test` — `/smoke-check`, `/hotfix` (narrowed to the affected suite), `/bug-report` (verify mode, narrowed to the affected suite), `/day-one-patch` (targeted fix and, when set, the broader regression — NOT ASSESSED if unset), `/dev-story` (Godot parse-check executable resolution), `/test-setup` (the `<Project>.` filter root on Unreal), `project-coherence.sh`; `smoke` — `/dev-story` (Unity parse check), `/smoke-check` (build check when tests are WAIVED); `build` — `/smoke-check` (build check when tests are WAIVED and `smoke` is unset), `project-coherence.sh`; `run` — `/dev-story` (Phase 6 step 4, the run-and-observe step). `/launch-checklist` and `/regression-suite` name these commands but do not run them.
  *(Derived by grep. A helper-based read would not show up, so treat this list as the verified floor, not a ceiling.)*
**控制：** 用于构建、测试、运行和冒烟测试项目的显式 shell 命令
**取值：** 字符串 — 可由 shell 执行的命令
**默认：** `[UNSET]` — 由 `/setup-engine` 以引擎典型默认值填充
**由谁设置：** `/setup-engine`、`/settings`
**写入者：** `/setup-engine`、`/settings`。**读取者：** `test` — `/smoke-check`、`/hotfix`（收窄到受影响的套件）、`/bug-report`（验证模式，收窄到受影响的套件）、`/day-one-patch`（针对性修复，以及已设置时更广泛的回归 — 未设置则 NOT ASSESSED）、`/dev-story`（Godot 解析检查可执行文件解析）、`/test-setup`（Unreal 上的 `<Project>.` 过滤根）、`project-coherence.sh`；`smoke` — `/dev-story`（Unity 解析检查）、`/smoke-check`（测试被 WAIVED 时的构建检查）；`build` — `/smoke-check`（测试被 WAIVED 且 `smoke` 未设置时的构建检查）、`project-coherence.sh`；`run` — `/dev-story`（Phase 6 第 4 步，run-and-observe 步骤）。`/launch-checklist` 和 `/regression-suite` 提及这些命令但不运行它们。
  *（通过 grep 推导。辅助函数式读取不会显现，因此请将该列表视为已验证的下限，而非上限。）*

**Priority chain:** `commands.*` in `project.yaml` → engine-typical default → no command available
**优先级链：** `project.yaml` 中的 `commands.*` → 引擎典型默认值 → 无可用命令

> **Why explicit:** Without this block, CCGS has to guess engine-typical conventions
> for invoking the project. Better to be explicit per-project — covers cases where
> projects customize their build (e.g., a Godot project using gdunit4 for tests but
> a custom export script for builds).
> **为什么显式：** 没有该块，CCGS 必须猜测调用项目的引擎典型约定。
> 更好的做法是按项目显式 — 覆盖项目自定义构建的情形
> （例如，一个使用 gdunit4 做测试、但用自定义导出脚本做构建的 Godot 项目）。

---

### Fields
### 字段

Each command can be a simple string (used on all OSes) or an OS-aware map:
每条命令可以是简单字符串（在所有操作系统上使用），或感知操作系统的映射：

**Simple form** (one command, used on every OS):
**简单形式**（一条命令，在每个操作系统上使用）：
```yaml
commands:
  build: "godot --headless --export-debug '<PRESET>'"   # ask; see the note below
  test:  "godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode"
  run:   "godot --path . --windowed --resolution 1280x720"
  smoke: "godot --headless --quit-after 5"
```

Note that `build` is the one row the simple form suits least: an export preset
names a *platform*, so a single build string is portable only for a project that
builds one platform. The other three rows are genuinely OS-independent.
请注意 `build` 是简单形式最不适合的一行：导出预设
命名的是一个*平台*，因此单一构建字符串只对只构建
一个平台的项目可移植。其他三行确实与操作系统无关。

**OS-aware form** (different commands per OS):
**感知操作系统的形式**（每个操作系统使用不同命令）：
```yaml
commands:
  build:
    default: "godot --headless --export-debug 'Linux/X11'"
    windows: "godot.exe --headless --export-debug 'Windows Desktop'"
    macos:   "godot --headless --export-debug 'macOS'"
  test:
    default: "godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode"
  run:
    default: "godot --path . --windowed --resolution 1280x720"
  smoke:
    default: "godot --headless --quit-after 5"
```

**Resolution rule:** if the value is a string, use it as-is on any OS. If the
value is a map, skills/hooks read the current OS and pick the matching key
(`linux`, `windows`, `macos`). Fall back to `default` if no OS-specific key
matches.
**解析规则：** 如果值是字符串，则在任何操作系统上原样使用。如果
值是映射，技能/钩子读取当前操作系统并选取匹配的键
（`linux`、`windows`、`macos`）。如果没有匹配的操作系统特定键，
则回退到 `default`。

This solves the Windows/Linux/macOS path-and-binary-name differences without
breaking the whitelist (commands stays locked to project.yaml — the OS-specific
keys are inside the locked file, not a local override).
这解决了 Windows/Linux/macOS 的路径和二进制名称差异，而不会
破坏白名单（commands 仍锁定于 project.yaml — 操作系统特定
键位于锁定文件内部，而非本地覆盖）。

| Field | Purpose |
|-------|---------|
| `build` | Full project build for CI or release. `/smoke-check` runs it only as the WAIVED-path build check when `commands.smoke` is unset; `project-coherence.sh` (which `/smoke-check` runs first) checks the export preset it names, and `/launch-checklist` only asks whether the build produces a valid artifact. |
| `test` | Run the full test suite. Run by `/smoke-check` and, narrowed to the affected suite, by `/hotfix`, `/bug-report` (verify mode) and `/day-one-patch`; `project-coherence.sh` checks the runner it names. `/regression-suite` does **not** run it. |
| `run` | Launch the **game** windowed at a fixed resolution — not the editor. Used by `/dev-story` Phase 6 step 4 to observe the feature and retain a screenshot; see `.claude/docs/run-and-observe.md` for the per-engine capture flags that are appended to it. |
| `smoke` | Minimal "does it boot?" check. Run by `/dev-story` as the Unity parse check (Phase 6 step 2), and by `/smoke-check` as the build check when `qa.level: minimal` waives tests. |

| 字段 | 用途 |
|-------|---------|
| `build` | 用于 CI 或发布的完整项目构建。`/smoke-check` 仅在 `commands.smoke` 未设置时将其作为 WAIVED 路径的构建检查来运行；`project-coherence.sh`（`/smoke-check` 最先运行它）检查它所命名的导出预设，而 `/launch-checklist` 只询问构建是否产出有效产物。 |
| `test` | 运行完整测试套件。由 `/smoke-check` 运行，并由 `/hotfix`、`/bug-report`（验证模式）和 `/day-one-patch` 收窄到受影响的套件运行；`project-coherence.sh` 检查它所命名的运行器。`/regression-suite` **不**运行它。 |
| `run` | 以固定分辨率窗口化启动**游戏** — 而非编辑器。由 `/dev-story` Phase 6 第 4 步用于观察功能并保留截图；各引擎附加的截图捕获标志见 `.claude/docs/run-and-observe.md`。 |
| `smoke` | 最小的“它能启动吗？”检查。由 `/dev-story` 作为 Unity 解析检查（Phase 6 第 2 步）运行，并由 `/smoke-check` 在 `qa.level: minimal` 豁免测试时作为构建检查运行。 |

---

### Engine defaults
### 引擎默认值

When `/setup-engine` runs, it populates `commands` based on engine choice — except
the **build** row, which it must **ask** for. The build artifact is named by a
project-defined string (a Godot export preset, a Unity build target), and no
engine reference in this repo can source it. See `/setup-engine` §"The Godot
`build` row must not hardcode `'Linux/X11'`".
当 `/setup-engine` 运行时，它根据引擎选择填充 `commands` — 但
**build** 行除外，它必须**询问**。构建产物由项目定义的
字符串命名（一个 Godot 导出预设、一个 Unity 构建目标），本仓库中没有任何
引擎参考能提供它。参见 `/setup-engine` §“Godot
`build` 行不得硬编码 `'Linux/X11'`”。

| Engine | build | test | run | smoke |
|--------|-------|------|-----|-------|
| Godot | `godot --headless --export-debug '<PRESET>'` | `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` | `godot --path . --windowed --resolution 1280x720` | `godot --headless --quit-after 5` |
| Unity | `"<Unity editor>" -batchmode -quit -projectPath . -buildTarget <TARGET> -build<PLATFORM>Player Builds/<Target>/<Game>.exe` | `"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml` | `Builds/<Target>/<Game>.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0` | `"<Unity editor>" -batchmode -quit -projectPath . -logFile -` |
| Unreal | `"<UE root>/Engine/Binaries/DotNET/AutomationTool/AutomationTool.exe" BuildCookRun -project="$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -platform=Win64 -build -cook` (confirm per project) | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -ExecCmds="Automation RunTests <project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -windowed -ResX=1280 -ResY=720` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -nullrhi -unattended -stdout -ExecCmds="Quit"` |

| 引擎 | build | test | run | smoke |
|--------|-------|------|-----|-------|
| Godot | `godot --headless --export-debug '<PRESET>'` | `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` | `godot --path . --windowed --resolution 1280x720` | `godot --headless --quit-after 5` |
| Unity | `"<Unity editor>" -batchmode -quit -projectPath . -buildTarget <TARGET> -build<PLATFORM>Player Builds/<Target>/<Game>.exe` | `"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml` | `Builds/<Target>/<Game>.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0` | `"<Unity editor>" -batchmode -quit -projectPath . -logFile -` |
| Unreal | `"<UE root>/Engine/Binaries/DotNET/AutomationTool/AutomationTool.exe" BuildCookRun -project="$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -platform=Win64 -build -cook`（按项目确认） | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -ExecCmds="Automation RunTests <project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -windowed -ResX=1280 -ResY=720` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -nullrhi -unattended -stdout -ExecCmds="Quit"` |

The Unreal row is Windows'. `/setup-engine` writes the Linux block (`Engine/Build/BatchFiles/RunUAT.sh`,
`Engine/Binaries/Linux/UnrealEditor`) on Linux, and on macOS only `build`, leaving `test`, `run` and
`smoke` unset, with a comment in `project.yaml` asking you to set them via `/settings` — see
`docs/engine-reference/unreal/current-best-practices.md`, "Command Line".
Unreal 行是 Windows 的。`/setup-engine` 在 Linux 上写入 Linux 块（`Engine/Build/BatchFiles/RunUAT.sh`、
`Engine/Binaries/Linux/UnrealEditor`），在 macOS 上只写入 `build`，使 `test`、`run` 和
`smoke` 未设置，并在 `project.yaml` 中留一条注释要求你通过 `/settings` 设置它们 — 参见
`docs/engine-reference/unreal/current-best-practices.md` 的“Command Line”。

> **`<PRESET>` and `<TARGET>` are placeholders, not values to copy.** A Godot
> export preset is whatever string the operator typed into `export_presets.cfg`;
> the shipped defaults are per-platform (`Windows Desktop`, `macOS`, `Web`,
> `Linux/X11`). Copying a preset name you do not have gives you a build command
> that fails with `Unknown export preset`; copying one you *do* have, but did not
> mean, gives you a command that succeeds and builds the wrong platform. The
> second is the dangerous one. If no presets exist yet — common, since
> `/setup-engine` usually runs before the project has any — write
> `[TO BE CONFIGURED]` rather than guessing a name.
> **`<PRESET>` 和 `<TARGET>` 是占位符，不是可复制的值。** Godot
> 导出预设是操作者输入到 `export_presets.cfg` 中的任意字符串；
> 随附的默认值按平台而异（`Windows Desktop`、`macOS`、`Web`、
> `Linux/X11`）。复制一个你并不拥有的预设名，会得到一个
> 以 `Unknown export preset` 失败的构建命令；复制一个你*确实*拥有但不是
> 你想要的那个，会得到一个成功却构建了错误平台的命令。后者
> 才是危险的那个。如果尚不存在任何预设 — 这很常见，因为
> `/setup-engine` 通常在项目还没有预设时运行 — 就写
> `[TO BE CONFIGURED]`，而不是猜测一个名称。

Users override per-project as needed via `/settings commands.<field>=<value>` or by editing `project.yaml` directly.
用户按项目需要，通过 `/settings commands.<field>=<value>` 或直接编辑 `project.yaml` 来覆盖。

---

### Affected skills
### 受影响的技能

| Skill | How `commands` is used |
|-------|------------------------|
| **smoke-check** | Runs `commands.test`, or the engine's default when it is unset; on Unreal it builds the editor target first. Critical path for QA hand-off. |
| **launch-checklist** | Emits a checklist **item** asking whether the build produces a valid artifact. It does **not** run `commands.build`; the verification is a human step. |
| **validate-push.sh** | Does **not** read `commands.*`. It warns on pushes to protected branches (`main`/`master`/`release/*`) and runs no build or smoke command — the block path in it is commented out, so it never fails a push. |
| **dev-story** | Phase 6 step 2 is the parse check: `.claude/scripts/godot-parse-check.gd` on Godot, `commands.smoke` on Unity, the editor-target build on Unreal. Phase 6 step 4 runs `commands.run` — the windowed game launch — to observe the feature and retain a screenshot (`.claude/docs/run-and-observe.md`). |
| **regression-suite** | Maps coverage by **globbing test filenames**. It does **not** invoke `commands.test`, so coverage here means "a test file exists", never "a test passed". |

| 技能 | 如何使用 `commands` |
|-------|------------------------|
| **smoke-check** | 运行 `commands.test`，未设置时运行引擎默认值；在 Unreal 上先构建编辑器目标。QA 交接的关键路径。 |
| **launch-checklist** | 发出一个清单**项**，询问构建是否产出有效产物。它**不**运行 `commands.build`；验证是人工步骤。 |
| **validate-push.sh** | **不**读取 `commands.*`。它对推送到受保护分支（`main`/`master`/`release/*`）发出警告，且不运行任何构建或冒烟命令 — 其中的阻止路径已被注释掉，因此它从不会让推送失败。 |
| **dev-story** | Phase 6 第 2 步是解析检查：Godot 上用 `.claude/scripts/godot-parse-check.gd`，Unity 上用 `commands.smoke`，Unreal 上构建编辑器目标。Phase 6 第 4 步运行 `commands.run` — 窗口化游戏启动 — 以观察功能并保留截图（`.claude/docs/run-and-observe.md`）。 |
| **regression-suite** | 通过**通配测试文件名**来映射覆盖。它**不**调用 `commands.test`，因此这里的覆盖意味着“存在测试文件”，而绝非“测试通过”。

---

## naming

**Controls:** Code naming conventions for the project
**Values:** see field list below
**Default:** engine-specific (auto-populated by `/setup-engine`)
**Set by:** `/setup-engine`, `/settings`
**Read by:** `/adopt`, `/architecture-review`, `/asset-spec`,
`/create-architecture`, `/create-control-manifest`, `/dev-story`,
`/vertical-slice` — each reads `naming.*` from `project.yaml` and feeds the
conventions into a brief, manifest or spec. **NOT by `/code-review` and NOT by
`validate-commit.sh`**.
  *(Reader list derived by grep, so treat it as the verified floor rather than
  a ceiling — a skill reading the value through a helper would not show up.)*
**控制：** 项目的代码命名约定
**取值：** 见下面的字段列表
**默认：** 引擎相关（由 `/setup-engine` 自动填充）
**由谁设置：** `/setup-engine`、`/settings`
**由谁读取：** `/adopt`、`/architecture-review`、`/asset-spec`、
`/create-architecture`、`/create-control-manifest`、`/dev-story`、
`/vertical-slice` — 各自从 `project.yaml` 读取 `naming.*`，并将
约定注入简报、清单或规格。**`/code-review` 不读取，`validate-commit.sh` 也不读取**。
  *（读取者列表由 grep 推导，因此请将其视为已验证的下限而非
  上限 — 通过辅助函数读取该值的技能不会显现。）*

> **These conventions are guidance, not a gate.** They reach your project by
> being passed into briefs, manifests and specs for whoever writes the code.
> Nothing checks the result: `/code-review` does not validate files against them
> and `validate-commit.sh` does not warn on violations — neither contains any
> naming logic. If you need enforcement, it has to be added.
>
> **Asset filenames.** `validate-assets.sh` warns when a file under Godot's
> `assets/` has an uppercase letter, a space or a hyphen in its name (it expects
> lowercase with underscores), and it takes no config input. `/asset-spec`
> specifies asset names from `naming.*`. Unity's `Assets/` and Unreal's `Content/`
> are not naming-checked: those engines name assets in PascalCase. On Godot-C#,
> where `/setup-engine` sets `naming.files: PascalCase`, the hook warns on assets
> named exactly as `/asset-spec` specified them. `naming.files` describes
> **source** files by its own examples (`PlayerController.cs`), and no key governs
> asset filenames, so treat the hook's naming warning as advisory there.
> **这些约定是指导，不是门禁。** 它们通过被注入简报、清单和规格，
> 传递给编写代码的人，从而到达你的项目。
> 没有任何东西检查结果：`/code-review` 不根据它们校验文件，
> `validate-commit.sh` 也不对违规发出警告 — 两者都不含任何
> 命名逻辑。如果你需要强制执行，必须自行添加。
>
> **资产文件名。** 当 Godot 的 `assets/` 下的文件名包含大写字母、空格或连字符时，
> `validate-assets.sh` 会发出警告（它期望小写加下划线），
> 且它不接受任何配置输入。`/asset-spec` 从 `naming.*` 指定资产名称。
> Unity 的 `Assets/` 和 Unreal 的 `Content/` 不做命名检查：那些引擎以 PascalCase 命名资产。
> 在 Godot-C# 上，`/setup-engine` 设置 `naming.files: PascalCase`，
> 而钩子会对完全按 `/asset-spec` 指定的方式命名的资产发出警告。`naming.files` 按其自身示例
> （`PlayerController.cs`）描述的是**源**文件，且没有任何键管辖
> 资产文件名，因此在那里请将钩子的命名警告视为建议性。

> **Moved from `technical-preferences.md`**, which is being deleted. Naming
> conventions are project-level facts shared by everyone on the project, so they
> belong in `project.yaml` alongside the rest of your structured config.
> **从 `technical-preferences.md` 迁移而来**，后者正在被删除。命名
> 约定是项目级事实，由项目中的每个人共享，因此它们
> 属于 `project.yaml`，与其余结构化配置并列。

---

### Fields
### 字段

| Field | Values | Godot default | Unity default | Unreal default |
|-------|--------|---------------|---------------|----------------|
| `classes` | `PascalCase` \| `snake_case` \| `camelCase` | PascalCase | PascalCase | PascalCase |
| `variables` | `snake_case` \| `camelCase` | snake_case | camelCase | camelCase |
| `constants` | `SCREAMING_SNAKE` \| `PascalCase` | SCREAMING_SNAKE | SCREAMING_SNAKE | SCREAMING_SNAKE |
| `signals` (Godot) / `events` (Unity, Unreal) | `past_tense` \| `on_event_name` | past_tense | on_event_name | OnEventName |
| `files` | `snake_case` \| `PascalCase` \| `kebab-case` | snake_case | PascalCase | PascalCase |
| `scenes` / `prefabs` | `snake_case` \| `PascalCase` | snake_case | PascalCase | PascalCase |

| 字段 | 取值 | Godot 默认 | Unity 默认 | Unreal 默认 |
|-------|--------|---------------|---------------|----------------|
| `classes` | `PascalCase` \| `snake_case` \| `camelCase` | PascalCase | PascalCase | PascalCase |
| `variables` | `snake_case` \| `camelCase` | snake_case | camelCase | camelCase |
| `constants` | `SCREAMING_SNAKE` \| `PascalCase` | SCREAMING_SNAKE | SCREAMING_SNAKE | SCREAMING_SNAKE |
| `signals`（Godot）/ `events`（Unity、Unreal） | `past_tense` \| `on_event_name` | past_tense | on_event_name | OnEventName |
| `files` | `snake_case` \| `PascalCase` \| `kebab-case` | snake_case | PascalCase | PascalCase |
| `scenes` / `prefabs` | `snake_case` \| `PascalCase` | snake_case | PascalCase | PascalCase |

> **`signals` vs `events`:** Godot uses signals natively; Unity uses C# events
> or UnityEvents; Unreal uses delegates and dynamic multicast. The field stays
> named `signals` in project.yaml for consistency across engines — interpret as
> "event-like callbacks" regardless of engine.
> **`signals` vs `events`：** Godot 原生使用信号；Unity 使用 C# 事件
> 或 UnityEvents；Unreal 使用委托和动态多播。为跨引擎一致，
> 该字段在 project.yaml 中仍命名为 `signals` — 无论哪个引擎，
> 都将其理解为“类事件回调”。

---

### Affected skills
### 受影响的技能

| Skill | How naming is used |
|-------|--------------------|
| **dev-story** | Passes the naming conventions to the programmer subagent as part of the implementation context |
| **create-control-manifest** | Emits the conventions as manifest rows (classes, variables, signals/events, files, constants) |
| **asset-spec** | Specifies asset naming per the configured convention |
| **create-architecture** / **architecture-review** | Read as project config alongside `performance.*` |
| **vertical-slice** / **adopt** | Read as project config; `/adopt` audits conformance at MEDIUM severity |

| 技能 | 如何使用命名 |
|-------|--------------------|
| **dev-story** | 将命名约定作为实现上下文的一部分传给程序员子智能体 |
| **create-control-manifest** | 将约定作为清单行输出（classes、variables、signals/events、files、constants） |
| **asset-spec** | 按已配置的约定指定资产命名 |
| **create-architecture** / **architecture-review** | 与 `performance.*` 一起作为项目配置读取 |
| **vertical-slice** / **adopt** | 作为项目配置读取；`/adopt` 以 MEDIUM 严重度审计一致性 |

No skill or hook validates code *against* these conventions — see the note above.
没有任何技能或钩子*根据*这些约定校验代码 — 见上面的说明。

---

## features.session_state

**Controls:** Whether the harness runs a full session tracking pipeline (hooks,
log files, `active.md` checkpoint) or relies on
skeleton-first output files for recovery  
**Values:** `off` | `on`  
**Default:** `on`  
**Set by:** `/settings`  
**Read by:** Five hooks — `session-start.sh` (its recovery preview only),
`pre-compact.sh`, `session-stop.sh`, `log-agent.sh` and `log-agent-stop.sh`. No skill reads it, and neither does `statusline.sh`.
**控制：** 执行框架是运行完整的会话跟踪流水线（钩子、
日志文件、`active.md` 检查点），还是依赖
骨架优先的输出文件来恢复
**取值：** `off` | `on`
**默认：** `on`
**由谁设置：** `/settings`
**由谁读取：** 五个钩子 — `session-start.sh`（仅其恢复预览）、
`pre-compact.sh`、`session-stop.sh`、`log-agent.sh` 和 `log-agent-stop.sh`。没有技能读取它，`statusline.sh` 也不读取。

> **`on` is the recommended setting.** Long-form skills write self-describing
> skeleton files upfront, which covers much of mid-task recovery on its own; the
> session pipeline adds the checkpoint preview at session start, the session
> archive and the subagent tally. Turn it `off` only to save that preview's
> tokens.
> **`on` 是推荐设置。** 长篇技能会预先写出自描述的
> 骨架文件，这本身已覆盖任务中途恢复的大部分内容；
> 会话流水线增加了会话启动时的检查点预览、会话
> 归档和子智能体统计。只有在要节省该预览的
> token 时才将其设为 `off`。

> **Priority chain:** `features.session_state` in `project.local.yaml` →
> `project.yaml` → hardcoded default of **`on`**. Hooks read it via
> `session_state_enabled()` in `yaml-helper.sh` and exit early when `off`.
> Skills do not read it: `/dev-story` and `/story-done` update the checkpoint in
> `active.md` whatever its value.
> **优先级链：** `project.local.yaml` 中的 `features.session_state` →
> `project.yaml` → 硬编码默认值 **`on`**。钩子通过
> `yaml-helper.sh` 中的 `session_state_enabled()` 读取它，并在 `off` 时提前退出。
> 技能不读取它：无论其取值如何，`/dev-story` 和 `/story-done` 都会更新
> `active.md` 中的检查点。

> **The default is `on`, deliberately.** `.claude/docs/context-management.md`
> tells you to rely on `production/session-state/active.md` as your
> crash-recovery checkpoint, so defaulting this off would quietly take away
> recovery, the session archive and the subagent tally. What `off` saves — the
> checkpoint preview, at most ~750 tokens per session start — is an explicit
> opt-out (`/settings features.session_state=off`), never a silent default.
> **默认值有意为 `on`。** `.claude/docs/context-management.md`
> 告诉你依赖 `production/session-state/active.md` 作为你的
> 崩溃恢复检查点，因此默认关闭它就会悄悄拿走
> 恢复能力、会话归档和子智能体统计。`off` 所节省的 —
> 检查点预览，每次会话启动最多约 750 token — 是一个显式的
> 退出选项（`/settings features.session_state=off`），绝不是静默默认值。

> **`session-start.sh` is gated per-block, not at the top.** Its sprint,
> milestone and git context is not part of the session-state pipeline; only the
> `active.md` recovery preview is gated. Its check also fails OPEN — that hook
> sources `yaml-helper.sh` conditionally, and an undefined function is falsey,
> which would suppress the recovery checkpoint invisibly.
> **`session-start.sh` 是按块门禁的，而非在顶部门禁。** 它的 sprint、
> 里程碑和 git 上下文不属于会话状态流水线；只有
> `active.md` 恢复预览被门禁。它的检查还会失败开放 —
> 该钩子有条件地 source `yaml-helper.sh`，而未定义的函数为假值，
> 这会无形地抑制恢复检查点。

---

### Value intent
### 取值意图

| Value | Intent |
|-------|--------|
| `off` | Recovery via skeleton-first output files. Long-form skills write a complete skeleton (all section headers, empty bodies) before starting. If context clears or compacts, the agent reads the skeleton + relevant docs and resumes. The five session-state hooks do nothing, so no logs; skills still update the checkpoint in `active.md`, but session start does not show it. Saves at most ~750 tokens per session start. |
| `on` | Full session tracking. Session-stop archival, compaction log and agent audit log all active. Adds the checkpoint preview to each session start, capped at 25 lines or 3,000 characters (at most ~750 tokens). Compaction hooks log to disk and add nothing to Claude's context. |

| 取值 | 意图 |
|-------|--------|
| `off` | 通过骨架优先的输出文件恢复。长篇技能在开始前写出完整骨架（所有章节标题、空正文）。如果上下文被清除或压缩，智能体读取骨架 + 相关文档并继续。五个会话状态钩子不做任何事，因此无日志；技能仍会更新 `active.md` 中的检查点，但会话启动不会显示它。每次会话启动最多节省约 750 token。 |
| `on` | 完整会话跟踪。会话停止归档、压缩日志和智能体审计日志全部激活。在每次会话启动时增加检查点预览，上限为 25 行或 3,000 字符（最多约 750 token）。压缩钩子写入磁盘，不向 Claude 的上下文添加任何内容。 |

---

### Hook behavior
### 钩子行为

> **Implementation note:** The feature flag check lives inside each hook script,
> not at the harness level. Every session-state-aware hook calls
> `session_state_enabled()` from `yaml-helper.sh` at its top (an awk read of
> `project.local.yaml`, then `project.yaml`) and exits silently with no output if
> the value is `off` — except `session-start.sh`, which skips only its recovery
> preview. This ensures
> the harness always fires the hook — the hook decides whether to act.
> **实现说明：** 功能标志检查位于每个钩子脚本内部，
> 而非执行框架层。每个感知会话状态的钩子都会在其顶部调用
> `yaml-helper.sh` 中的 `session_state_enabled()`（先 awk 读取
> `project.local.yaml`，再读取 `project.yaml`），若值为 `off` 则静默退出且无输出
> — 但 `session-start.sh` 除外，它只跳过其恢复
> 预览。这确保
> 执行框架总是触发钩子 — 由钩子决定是否行动。

| Hook | session_state: off | session_state: on |
|------|--------------------|-------------------|
| **session-start.sh** | Runs normally (git/sprint context) — skips the `active.md` checkpoint preview | Runs fully, including the `active.md` checkpoint preview |
| **detect-gaps.sh** | Runs unchanged — gap detection is independent of session state | Runs unchanged |
| **pre-compact.sh** | No-op — exits silently (no compaction-log append) | Appends one line to `compaction-log.txt` and prints nothing (PreCompact output never reaches Claude; `session-start.sh` restores context) |
| **session-stop.sh** | No-op — exits silently | Archives `active.md` to `session-log.md` when it has changed, appends commits and uncommitted file names, writes the spawn tally to `session-cost.md`; prints nothing |
| **log-agent.sh** | No-op — exits silently | Appends to agent-audit.log |
| **log-agent-stop.sh** | No-op — exits silently | Appends to agent-audit.log |

| 钩子 | session_state: off | session_state: on |
|------|--------------------|-------------------|
| **session-start.sh** | 正常运行（git/sprint 上下文）— 跳过 `active.md` 检查点预览 | 完整运行，包括 `active.md` 检查点预览 |
| **detect-gaps.sh** | 不变运行 — 缺口检测独立于会话状态 | 不变运行 |
| **pre-compact.sh** | 空操作 — 静默退出（不追加压缩日志） | 向 `compaction-log.txt` 追加一行且不打印任何内容（PreCompact 输出从不到达 Claude；`session-start.sh` 会恢复上下文） |
| **session-stop.sh** | 空操作 — 静默退出 | 当 `active.md` 发生变化时将其归档到 `session-log.md`，追加提交和未提交文件名，将生成统计写入 `session-cost.md`；不打印任何内容 |
| **log-agent.sh** | 空操作 — 静默退出 | 追加到 agent-audit.log |
| **log-agent-stop.sh** | 空操作 — 静默退出 | 追加到 agent-audit.log |

---

### File existence by mode
### 按模式的文件存在情况

| File | session_state: off | session_state: on |
|------|--------------------|-------------------|
| `production/session-state/active.md` | Still written by skills; session start does not show it | Written by skills; session start shows its checkpoint |
| `production/session-logs/session-log.md` | Not written | Append-only archive of each session's `active.md` |
| `production/session-logs/compaction-log.txt` | Not written | Append-only timestamp log of compaction events |
| `production/session-logs/agent-audit.log` | Not written | Append-only log of agent spawn/complete events |

| 文件 | session_state: off | session_state: on |
|------|--------------------|-------------------|
| `production/session-state/active.md` | 仍由技能写入；会话启动不显示它 | 由技能写入；会话启动显示其检查点 |
| `production/session-logs/session-log.md` | 不写入 | 每个会话 `active.md` 的仅追加归档 |
| `production/session-logs/compaction-log.txt` | 不写入 | 压缩事件的仅追加时间戳日志 |
| `production/session-logs/agent-audit.log` | 不写入 | 智能体生成/完成事件的仅追加日志 |

---

### Skeleton-first pattern (session_state: off recovery mechanism)
### 骨架优先模式（session_state: off 的恢复机制）

Long-form skills must write a skeleton file as their first action — before any
section discussion begins. The skeleton contains all section headers with empty
bodies and a `<!-- STATUS: incomplete -->` marker per section.
长篇技能必须将写出骨架文件作为第一个动作 — 在任何
章节讨论开始之前。骨架包含所有章节标题、
空正文，以及每个章节的 `<!-- STATUS: incomplete -->` 标记。

```markdown
# Combat System — GDD

## Overview
<!-- STATUS: incomplete -->

## Player Fantasy
<!-- STATUS: incomplete -->

## Detailed Rules
<!-- STATUS: incomplete -->
...
```

As each section is approved and written, the marker changes to `<!-- STATUS: done -->`.
On recovery (after /clear or compaction), the agent reads the skeleton, identifies
which sections are `done` vs `incomplete`, reads relevant ADRs and the systems index,
and resumes at the first `incomplete` section. No `active.md` needed.
随着每个章节被批准并写入，标记变为 `<!-- STATUS: done -->`。
恢复时（在 /clear 或压缩之后），智能体读取骨架，识别
哪些章节是 `done`、哪些是 `incomplete`，读取相关 ADR 和系统索引，
并从第一个 `incomplete` 章节继续。不需要 `active.md`。

**Skills required to implement skeleton-first:**
**要求实现骨架优先的技能：**

| Skill | Output file | Skeleton written when |
|-------|-------------|----------------------|
| **design-system** | `design/gdd/[system].md` | Before Phase 1 (section discussion) |
| **art-bible** | `design/art/art-bible.md` | From `.claude/docs/templates/art-bible.md`, after asking, when section 1 is approved |
| **create-architecture** | `docs/architecture/architecture.md` | Not skeleton-first: written once at Phase 7 after its ask (an existing document is updated in place) |
| **ux-design** | `design/ux/[screen].md` | Before screen discussion |
| **create-stories** | `production/epics/[epic-slug]/story-NNN-[slug].md` | Not skeleton-first: written in Step 6, after the ask names every file |
| **create-epics** | `production/epics/[epic-slug]/EPIC.md` | Not skeleton-first: written after its per-epic "May I write `production/epics/[epic-slug]/EPIC.md` and add its row to `production/epics/index.md`" ask |
| **map-systems** | `design/gdd/systems-index.md` | Before system enumeration |
| **brainstorm** | `design/gdd/game-concept.md` (`standard`/`full`) · `design/game-brief.md` (`minimal`) | Before concept discussion |

| 技能 | 输出文件 | 何时写入骨架 |
|-------|-------------|----------------------|
| **design-system** | `design/gdd/[system].md` | Phase 1（章节讨论）之前 |
| **art-bible** | `design/art/art-bible.md` | 在询问后，从 `.claude/docs/templates/art-bible.md` 写入，当第 1 章节被批准时 |
| **create-architecture** | `docs/architecture/architecture.md` | 非骨架优先：在其询问后于 Phase 7 一次写入（已存在的文档就地更新） |
| **ux-design** | `design/ux/[screen].md` | 画面讨论之前 |
| **create-stories** | `production/epics/[epic-slug]/story-NNN-[slug].md` | 非骨架优先：在第 6 步写入，在询问中列出每个文件之后 |
| **create-epics** | `production/epics/[epic-slug]/EPIC.md` | 非骨架优先：在其逐 epic 的“我可以写入 `production/epics/[epic-slug]/EPIC.md` 并将其行添加到 `production/epics/index.md` 吗”询问之后写入 |
| **map-systems** | `design/gdd/systems-index.md` | 系统枚举之前 |
| **brainstorm** | `design/gdd/game-concept.md`（`standard`/`full`）· `design/game-brief.md`（`minimal`） | 概念讨论之前 |

> **Note on agents:** `world-builder` and `narrative-director` are agents, not
> invocable skills — they do not have SKILL.md files. Long-form output from these
> agents is produced via the skills above (design-system, art-bible, etc.) which
> are responsible for skeleton-first enforcement.
> **关于智能体的说明：** `world-builder` 和 `narrative-director` 是智能体，而非
> 可调用技能 — 它们没有 SKILL.md 文件。这些智能体的长篇输出
> 通过上述技能（design-system、art-bible 等）产生，这些技能
> 负责骨架优先的执行。

> **Stage detection is always independent of session state.** `statusline.sh`
> auto-detects stage from `project.yaml` `project.stage` or artifact heuristics regardless
> of `session_state` value, and so is the breadcrumb: `statusline.sh` never reads
> `session_state`. (At `workflow: minimal` the status line shows the story count
> instead of the stage.)
> **阶段检测始终独立于会话状态。** 无论
> `session_state` 取值如何，`statusline.sh` 都会从 `project.yaml` 的 `project.stage` 或产物
> 启发式自动检测阶段，面包屑也是如此：`statusline.sh` 从不读取
> `session_state`。（在 `workflow: minimal` 时，状态行显示 story 数量
> 而非阶段。）

| Feature | session_state: off | session_state: on |
|---------|--------------------|-------------------|
| Context % display | Always shown | Always shown |
| Model display | Always shown | Always shown |
| Stage display | From project.yaml or heuristics — except at `workflow: minimal`, where `Minimal · <done>/<total> stories` (or `Minimal · brief` before any story exists) replaces it | Same |
| Epic/Feature/Task breadcrumb | Parsed from the `<!-- STATUS -->` block in `active.md` (not gated) | Parsed from the `<!-- STATUS -->` block in `active.md` |

| 功能 | session_state: off | session_state: on |
|---------|--------------------|-------------------|
| 上下文百分比显示 | 始终显示 | 始终显示 |
| 模型显示 | 始终显示 | 始终显示 |
| 阶段显示 | 来自 project.yaml 或启发式 — 但在 `workflow: minimal` 时，由 `Minimal · <done>/<total> stories`（或在任何 story 存在前的 `Minimal · brief`）替代 | 同上 |
| Epic/Feature/Task 面包屑 | 从 `active.md` 的 `<!-- STATUS -->` 块解析（不受门禁） | 从 `active.md` 的 `<!-- STATUS -->` 块解析 |

---

### Affected skills
### 受影响的技能

Skills interact with session state in two ways: **inference** (reading `active.md`
to resolve a missing argument) and **extraction** (appending a SESSION EXTRACT
block after completing work). Neither is gated: no skill reads `session_state`,
so both happen whatever its value.
技能以两种方式与会话状态交互：**推断**（读取 `active.md`
以解析缺失的参数）和**提取**（在完成工作后追加一个 SESSION EXTRACT
块）。两者都不受门禁：没有技能读取 `session_state`，
因此无论其取值如何，两者都会发生。

#### Inference — skills that read `active.md` to fill in missing arguments
#### 推断 — 读取 `active.md` 以填充缺失参数的技能

When `active.md` holds nothing to infer from, these skills must receive the
argument explicitly. If called without an argument, they should prompt the user
rather than fail silently.
当 `active.md` 中没有任何可供推断的内容时，这些技能必须显式接收
该参数。如果调用时没有参数，它们应提示用户，
而不是静默失败。

| Skill | What it infers from `active.md` | Fallback when nothing is found |
|-------|----------------------------------|---------------------|
| **dev-story** | Active story path (when no arg given) | Prompt user for story path |
| **story-done** | In-progress story path (when no arg given) | Prompt user for story path |
| **team-release** | Target version (when no arg given) | Prompt user for version |
| **team-qa** | Active sprint (when no arg given) | Prompt user for sprint file |
| **help** | Current task and STATUS block for context-aware suggestions | Responds without session context — surfaces next steps from sprint/epics only |

| 技能 | 从 `active.md` 推断什么 | 未找到时的回退 |
|-------|----------------------------------|---------------------|
| **dev-story** | 活跃 story 路径（未给参数时） | 提示用户提供 story 路径 |
| **story-done** | 进行中的 story 路径（未给参数时） | 提示用户提供 story 路径 |
| **team-release** | 目标版本（未给参数时） | 提示用户提供版本 |
| **team-qa** | 活跃 sprint（未给参数时） | 提示用户提供 sprint 文件 |
| **help** | 当前任务和 STATUS 块，用于上下文感知建议 | 无会话上下文地响应 — 仅从 sprint/epic 中呈现下一步 |

#### Extraction — skills that write session state to active.md
#### 提取 — 将会话状态写入 active.md 的技能

These skills write a structured block after completing work, whatever
`session_state` is. `/dev-story` and `/story-done` overwrite
the `<!-- CHECKPOINT -->` block; the others append a SESSION EXTRACT.
无论 `session_state` 取值如何，这些技能都会在完成工作后写入
一个结构化块。`/dev-story` 和 `/story-done` 覆盖
`<!-- CHECKPOINT -->` 块；其他技能则追加一个 SESSION EXTRACT。

| Skill | What it writes to active.md |
|-------|-----------------------------|
| **dev-story** | Checkpoint: story path, next step, blockers, files changed, run result |
| **story-done** | Checkpoint: verdict, story path, next story, tech debt count |
| **architecture-review** | Verdict, TR coverage counts, new TR-IDs, GDD flags, ADR gaps, report path |
| **prototype** | Prototype scope, current phase, key decisions |
| **vertical-slice** | Slice concept, current phase, blocked items |
| **team-qa** | QA phase comment, blocking issues |
| **map-systems** | Task record: systems enumerated, current phase |

| 技能 | 它向 active.md 写入什么 |
|-------|-----------------------------|
| **dev-story** | 检查点：story 路径、下一步、阻塞项、变更文件、运行结果 |
| **story-done** | 检查点：裁决、story 路径、下一个 story、技术债计数 |
| **architecture-review** | 裁决、TR 覆盖计数、新 TR-ID、GDD 标记、ADR 缺口、报告路径 |
| **prototype** | 原型范围、当前阶段、关键决策 |
| **vertical-slice** | 切片概念、当前阶段、阻塞项 |
| **team-qa** | QA 阶段注释、阻塞问题 |
| **map-systems** | 任务记录：已枚举系统、当前阶段 |

---

### Token cost summary
### Token 成本摘要

| Scenario | session_state: off | session_state: on |
|----------|--------------------|-------------------|
| Per session start | ~500 tokens (git/sprint context only) | ~500–1,250 tokens (+ checkpoint preview, at most ~750) |
| Per compaction event | 0 (compaction hook output never reaches Claude) | 0 (logged to disk only) |
| Per session end | 0 | File I/O only (no conversation tokens) |
| Recovery after /clear | Read skeleton + 2–3 docs (~1,000–3,000 tokens) | Read `active.md` (~200–500 tokens) |

| 场景 | session_state: off | session_state: on |
|----------|--------------------|-------------------|
| 每次会话启动 | 约 500 token（仅 git/sprint 上下文） | 约 500–1,250 token（+ 检查点预览，最多约 750） |
| 每次压缩事件 | 0（压缩钩子输出从不到达 Claude） | 0（仅写入磁盘） |
| 每次会话结束 | 0 | 仅文件 I/O（无对话 token） |
| /clear 后的恢复 | 读取骨架 + 2–3 份文档（约 1,000–3,000 token） | 读取 `active.md`（约 200–500 token） |

> **Note:** The `off` recovery cost (reading skeleton + docs) is paid only when
> recovery is actually needed. The `on` session-start cost is paid every session
> whether recovery is needed or not.
> **注意：** `off` 的恢复成本（读取骨架 + 文档）仅在
> 实际需要恢复时才付出。`on` 的会话启动成本则每个会话都要付出，
> 无论是否需要恢复。

---

## features.token_budget_warn_at

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is not checked when you set it, and nothing reads it.
> Nothing warns at any threshold.

> ### 保留 — 未实现
>
> **没有技能或钩子读取该设置。设置它没有任何效果。** 下面
> 描述的是预期设计，而非当前行为。
>
> 你设置该值时它不会被校验，也没有任何东西读取它。
> 没有任何东西在任何阈值发出警告。

**Controls:** Context usage threshold at which session warnings fire
**Values:** float between 0.0 and 1.0
**Default:** `0.7` (warn at 70%)
**Set by:** `/settings`
**Read by:** nothing yet (intended readers: `session-start.sh`, `statusline.sh`)
**控制：** 触发会话警告的上下文使用率阈值
**取值：** 0.0 到 1.0 之间的浮点数
**默认：** `0.7`（在 70% 时警告）
**由谁设置：** `/settings`
**由谁读取：** 目前无（预期读取者：`session-start.sh`、`statusline.sh`）

**Priority chain:** `features.token_budget_warn_at` in `project.yaml` → hardcoded default of `0.7`
**优先级链：** `project.yaml` 中的 `features.token_budget_warn_at` → 硬编码默认值 `0.7`

> Surfaces a warning when session context usage exceeds the threshold. Helps
> cost-conscious users hit `/clear` before runaway sessions. Set to `1.0` to
> disable.
> 当会话上下文使用率超过阈值时呈现警告。帮助
> 关注成本的用户在会话失控前执行 `/clear`。设为 `1.0`
> 可禁用。

---

### Behavior
### 行为

| Threshold | What fires |
|-----------|-----------|
| Below `warn_at` | No warning |
| At or above `warn_at` | `statusline.sh` shows context usage in yellow; next session-start hook emits a one-line note: *"Last session reached [X]% context — consider /clear if continuing work."* |
| At 90%+ | Yellow becomes red regardless of `warn_at` value |

| 阈值 | 触发什么 |
|-----------|-----------|
| 低于 `warn_at` | 无警告 |
| 等于或高于 `warn_at` | `statusline.sh` 以黄色显示上下文使用率；下一次会话启动钩子发出一行说明：*“上次会话达到 [X]% 上下文 — 若继续工作请考虑 /clear。”* |
| 90%+ | 无论 `warn_at` 取值如何，黄色变为红色 |

---

## features.read_guard

**Controls:** Whether a whole-file Read of a large design doc is refused  
**Values:** `on` | `off`; `true` and `false` also work  
**Default:** `on`  
**Set by:** `/settings`  
**Read by:** `validate-read.sh` (PreToolUse Read), through `.claude/scripts/read-guard.sh check`
**控制：** 是否拒绝整文件读取大型设计文档
**取值：** `on` | `off`；`true` 和 `false` 也可用
**默认：** `on`
**由谁设置：** `/settings`
**由谁读取：** `validate-read.sh`（PreToolUse Read），通过 `.claude/scripts/read-guard.sh check`

> **Priority chain:** `features.read_guard` in `project.local.yaml` →
> `project.yaml` → default **`on`**.
> **优先级链：** `project.local.yaml` 中的 `features.read_guard` →
> `project.yaml` → 默认 **`on`**。

A Read with no offset and no limit of a file under `design/`, `docs/architecture/`
or `production/session-state/` that is over `features.read_guard_kb` is refused.
The refusal lists the doc's headings with their line numbers, so the next call
reads one section with offset and limit. A ranged read always passes, so no skill
can get stuck behind the guard; images and PDFs are never checked. It blocks
rather than warns because a warning would let the whole read happen, and the
read is the cost.
对 `design/`、`docs/architecture/`
或 `production/session-state/` 下超过 `features.read_guard_kb` 的文件，
不带 offset 和 limit 的读取会被拒绝。
拒绝信息会列出文档标题及其行号，因此下一次调用
可用 offset 和 limit 读取一个章节。范围读取总是通过，因此没有技能
会被守卫卡住；图像和 PDF 从不检查。它阻塞
而非警告，因为警告会让整次读取发生，而
读取本身就是成本。

---

## features.read_guard_kb

**Controls:** The size over which `features.read_guard` refuses a whole-file read  
**Values:** a whole number of KB (1 KB = 1,024 bytes)  
**Default:** `40`  
**Set by:** `/settings`  
**Read by:** `validate-read.sh`, through `.claude/scripts/read-guard.sh check`
**控制：** 超过该大小时 `features.read_guard` 拒绝整文件读取
**取值：** 整数 KB（1 KB = 1,024 字节）
**默认：** `40`
**由谁设置：** `/settings`
**由谁读取：** `validate-read.sh`，通过 `.claude/scripts/read-guard.sh check`

> **Priority chain:** `features.read_guard_kb` in `project.local.yaml` →
> `project.yaml` → default **`40`**. A value that is not a whole number is
> ignored, and `read-guard.sh check` names it on its `threshold` row.
> **优先级链：** `project.local.yaml` 中的 `features.read_guard_kb` →
> `project.yaml` → 默认 **`40`**。不是整数的值会被
> 忽略，`read-guard.sh check` 会在其 `threshold` 行中指出它。

By file size, not lines: token cost follows bytes, and one table row can be 2 KB.
40 KB is about 10,000 tokens and sits above every shipped template (the largest is
33 KB).
按文件大小，而非行数：token 成本随字节数增长，而一行表格就可能达 2 KB。
40 KB 约为 10,000 token，高于所有随附模板（最大的是
33 KB）。

---

## updates.check

**Controls:** Whether session start tells you that a newer Claude Code Game
Studios release is out  
**Values:** `true` | `false`  
**Default:** `true`  
**Set by:** `/settings` (`/settings --local updates.check=false` turns it off
for you only)  
**Read by:** `session-start.sh`, through `update-check.sh`
**控制：** 会话启动是否告诉你已有更新的 Claude Code Game
Studios 版本  
**取值：** `true` | `false`  
**默认：** `true`  
**由谁设置：** `/settings`（`/settings --local updates.check=false` 仅为你关闭它）  
**由谁读取：** `session-start.sh`，通过 `update-check.sh`

> When a newer release is out, session start shows one line: *"Update: Claude
> Code Game Studios 1.3.0 is out (this project has 1.2.0). What changed and how
> to upgrade: <release page> — to stop this notice: /settings --local
> updates.check=false"*. Nothing is downloaded or changed; upgrading stays your
> call (`UPGRADING.md`).
> 当有更新的版本发布时，会话启动会显示一行：*“更新：Claude
> Code Game Studios 1.3.0 已发布（本项目为 1.2.0）。有什么变化以及如何
> 升级：<release page> — 要停止此通知：/settings --local
> updates.check=false”*。不下载或更改任何内容；升级仍由你决定
> （`UPGRADING.md`）。

> **Priority chain:** `updates.check` in `project.local.yaml` → `project.yaml` →
> default **`true`**. A value other than `true` or `false` is skipped and named
> in the session-start schema errors. The check is also off whenever the `CI`
> environment variable is set: nobody reads session start there.
> **优先级链：** `project.local.yaml` 中的 `updates.check` → `project.yaml` →
> 默认 **`true`**。除 `true` 或 `false` 之外的值会被跳过，并在
> 会话启动的 schema 错误中被指出。每当设置了 `CI`
> 环境变量时检查也会关闭：那里没人读取会话启动。

---

### How it checks
### 它如何检查

- At most once a day, a background job asks GitHub for the latest release
  (`api.github.com/repos/Donchitos/Claude-Code-Game-Studios/releases/latest`)
  and stores the answer in `~/.cache/claude-code-game-studios/latest-release`
  (under `$XDG_CACHE_HOME` when that is set). The file is per user and outside
  every project, so `git status` stays clean and one check covers every project
  on the machine.
- Session start only reads that file. It makes no network call and never waits;
  a new answer shows from the next session on.
- Offline, or with neither `curl` nor `wget`, it stays silent. The cache keeps
  the last answer, plus an `error=` line saying why the last check failed.
- Pre-releases are never offered.
- The version compared is the one the framework's own hook files carry, not
  `framework.version`: an upgrade that keeps your `project.yaml` leaves that
  number behind, and the line would announce the release you already have.
- With `false`, nothing is read and nothing is requested.
- 每天最多一次，后台作业向 GitHub 询问最新版本
  （`api.github.com/repos/Donchitos/Claude-Code-Game-Studios/releases/latest`），
  并将答案存储在 `~/.cache/claude-code-game-studios/latest-release`
  （设置时位于 `$XDG_CACHE_HOME` 下）。该文件按用户划分且位于
  每个项目之外，因此 `git status` 保持干净，一次检查即覆盖机器上的
  每个项目。
- 会话启动只读取该文件。它不发起网络调用，也从不等待；
  新答案从下一次会话开始显示。
- 离线，或既无 `curl` 也无 `wget` 时，它保持静默。缓存保留
  上一个答案，外加一行 `error=` 说明上次检查为何失败。
- 从不提供预发布版本。
- 比较的版本是框架自身钩子文件所携带的版本，而非
  `framework.version`：一次保留你 `project.yaml` 的升级会让那个
  数字落后，而该行会宣布你已经拥有的版本。
- 设为 `false` 时，不读取任何内容，也不请求任何内容。

---

## schema_version

**Controls:** Which version of the project.yaml schema this file conforms to
**Values:** integer
**Default:** `1` (for v1.1 of CCGS)
**Set by:** `/start`, `/adopt`
**Read by:** All skills and hooks that parse project.yaml (for migration safety)
**控制：** 本文件遵循哪个版本的 project.yaml schema
**取值：** 整数
**默认：** `1`（针对 CCGS 的 v1.1）
**由谁设置：** `/start`、`/adopt`
**由谁读取：** 所有解析 project.yaml 的技能和钩子（用于迁移安全）

> Lets future CCGS versions detect and migrate old project.yaml files. The
> migration logic compares `schema_version` in the file against the current
> CCGS's expected version. If newer, warn. If older, run migrations.
> 让未来的 CCGS 版本能够检测并迁移旧的 project.yaml 文件。迁移逻辑
> 将文件中的 `schema_version` 与当前 CCGS 的期望版本进行比较。
> 若更新，则警告。若更旧，则运行迁移。

---

### Migration behavior
### 迁移行为

| project.yaml schema_version | Current CCGS expects | Behavior |
|----------------------------|---------------------|----------|
| Matches expected | — | Normal operation |
| Lower than expected | — | `/adopt` warns and offers migration; skills run with deprecation warnings |
| Higher than expected | — | All skills warn: "This project.yaml was created by a newer CCGS version. Some settings may be ignored." |
| Missing | — | Treated as legacy (pre-v1.1); migration prompted on next `/start` or `/adopt` |

| project.yaml schema_version | 当前 CCGS 期望 | 行为 |
|----------------------------|---------------------|----------|
| 与期望一致 | — | 正常运行 |
| 低于期望 | — | `/adopt` 发出警告并提供迁移；技能在弃用警告下运行 |
| 高于期望 | — | 所有技能警告：“此 project.yaml 由更新的 CCGS 版本创建。部分设置可能会被忽略。” |
| 缺失 | — | 视为旧版（v1.1 之前）；在下次 `/start` 或 `/adopt` 时提示迁移 |

---

## framework

**Controls:** Tracks which CCGS version created or last touched this project
**Values:** `framework.version` (semver string) + `framework.last_upgraded` (ISO date)
**Default:** stamped in the template's `project.yaml` at each release
**Set by:** the template; `/start` (through `set-stage.sh`), `/setup-engine` and `/gate-check` write the block into a `project.yaml` they create, and `migrate-v1-config.sh` (which `/adopt` runs) writes `framework.version` into the one it builds
**Read by:** no skill branches on it — it is file metadata, not a behavioural setting. It appears in `/start`, `/gate-check`, `/settings` and `/setup-engine` as part of the `project.yaml` block they **write or display**, and in `yaml-helper.sh`.
  *(The four skills above were verified to name it; whether each reads it or merely emits it was NOT separated, so this says 'appears in', not 'read by'.)*
**控制：** 记录是哪个 CCGS 版本创建或最后改动此项目
**取值：** `framework.version`（语义化版本字符串）+ `framework.last_upgraded`（ISO 日期）
**默认：** 每次发布时写入模板的 `project.yaml`
**由谁设置：** 模板；`/start`（通过 `set-stage.sh`）、`/setup-engine` 和 `/gate-check` 会将此块写入它们创建的 `project.yaml`，而 `migrate-v1-config.sh`（由 `/adopt` 运行）会把 `framework.version` 写入它构建的那个文件
**由谁读取：** 没有技能根据它分支 — 它是文件元数据，而非行为设置。它出现在 `/start`、`/gate-check`、`/settings` 和 `/setup-engine` 中，作为它们**写入或显示**的 `project.yaml` 块的一部分，也出现在 `yaml-helper.sh` 中。
  *（上面这四个技能已被验证会提及它；但每一个是读取它还是仅输出它并未区分，因此这里说的是“出现于”，而非“由谁读取”。）*

---

### Fields
### 字段

```yaml
framework:
  version: "1.2.0"
  last_upgraded: "2026-10-18"
```

| Field | Purpose |
|-------|---------|
| `version` | The CCGS version that created the project (or was last updated to — see `UPGRADING.md`). |
| `last_upgraded` | ISO date of the most recent template update. |

| 字段 | 用途 |
|-------|---------|
| `version` | 创建该项目（或最后更新到 — 见 `UPGRADING.md`）的 CCGS 版本。 |
| `last_upgraded` | 最近一次模板更新的 ISO 日期。 |

---

### Affected skills
### 受影响的技能

None. No skill or hook reads `framework.version` or `last_upgraded` — `/adopt`
does not consult them and no hook checks their age. They record which template
version the project came from; `UPGRADING.md` is the upgrade path.
无。没有技能或钩子读取 `framework.version` 或 `last_upgraded` — `/adopt`
不会查询它们，也没有钩子检查它们的年龄。它们记录项目来自哪个模板
版本；`UPGRADING.md` 是升级路径。

---

## Migration from v1.0 → v1.1
## 从 v1.0 → v1.1 的迁移

When a v1.0 CCGS project upgrades to v1.1, migration tooling (run via `/adopt`)
converts legacy files to `project.yaml`. This section specifies the intended
behavior.
当一个 v1.0 的 CCGS 项目升级到 v1.1 时，迁移工具（通过 `/adopt` 运行）
会将旧版文件转换为 `project.yaml`。本节规定了预期的行为。

### Detection
### 检测

A project is detected as needing migration when:
- `project.yaml` does **NOT** exist at the repo root, AND
- One or more legacy files exists:
  - `production/stage.txt`
  - `production/review-mode.txt`
  - `.claude/docs/technical-preferences.md`
当以下情况出现时，项目被检测为需要迁移：
- 仓库根目录**不**存在 `project.yaml`，并且
- 存在一个或多个旧版文件：
  - `production/stage.txt`
  - `production/review-mode.txt`
  - `.claude/docs/technical-preferences.md`

### Preservation
### 保留

| Legacy source | Migrates to |
|---------------|-------------|
| `production/stage.txt` (single line) | `project.stage` |
| `production/review-mode.txt` (single line) | `modes.review_mode` |
| `.claude/docs/technical-preferences.md` → "Engine & Language" section | `engine.name`, `engine.version`, `engine.language`, `engine.rendering`, `engine.physics` |
| `technical-preferences.md` → "Input & Platform" section | `platform.targets`, `platform.primary_input`, `platform.gamepad_support`, `platform.touch_support` |
| `technical-preferences.md` → "Naming Conventions" section | `naming.classes`, `naming.variables`, `naming.constants`, `naming.signals`, `naming.files`, `naming.scenes` |
| `technical-preferences.md` → "Performance Budgets" section | `performance.target_framerate`, `performance.frame_budget_ms`, `performance.draw_call_limit`, `performance.memory_ceiling_mb` |
| `technical-preferences.md` → "Testing" section | `testing.framework`, `qa.coverage_minimum` (bare number only — prose is reported for manual entry) |
| `technical-preferences.md` → "Engine Specialists" section | `specialists.code`, `specialists.shader`, `specialists.ui`, `specialists.additional` |

| 旧版来源 | 迁移到 |
|---------------|-------------|
| `production/stage.txt`（单行） | `project.stage` |
| `production/review-mode.txt`（单行） | `modes.review_mode` |
| `.claude/docs/technical-preferences.md` → “Engine & Language”章节 | `engine.name`、`engine.version`、`engine.language`、`engine.rendering`、`engine.physics` |
| `technical-preferences.md` → “Input & Platform”章节 | `platform.targets`、`platform.primary_input`、`platform.gamepad_support`、`platform.touch_support` |
| `technical-preferences.md` → “Naming Conventions”章节 | `naming.classes`、`naming.variables`、`naming.constants`、`naming.signals`、`naming.files`、`naming.scenes` |
| `technical-preferences.md` → “Performance Budgets”章节 | `performance.target_framerate`、`performance.frame_budget_ms`、`performance.draw_call_limit`、`performance.memory_ceiling_mb` |
| `technical-preferences.md` → “Testing”章节 | `testing.framework`、`qa.coverage_minimum`（仅裸数字 — 散文内容会报告以手动录入） |
| `technical-preferences.md` → “Engine Specialists”章节 | `specialists.code`、`specialists.shader`、`specialists.ui`、`specialists.additional` |

**Value rename — `review_mode: none` → `solo`.** v1.0 used `none` for the "no
director reviews" tier; v1.1 renamed that tier to `solo` (the enum is
`full | lean | solo`). Migration **coerces** a legacy `none` to `solo` and reports
the rename in the migration report's Warnings. This is the one documented value
rename, so it is mapped-and-flagged rather than preserved raw: writing `none`
verbatim would produce an enum-invalid `project.yaml` that `resolve_config` rejects
and falls back to the `modes.rigor` value — at `standard` that is `lean`, reviews *on* —
inverting the user's intent. The
`--finalize` preservation check applies the same mapping so it does not falsely
refuse. Every *other* non-v1.1 stage/review value is a fork, not a rename:
preserved raw and flagged for manual resolution, never coerced.
**取值重命名 — `review_mode: none` → `solo`。** v1.0 用 `none` 表示“无
主管评审”层级；v1.1 将该层级重命名为 `solo`（枚举为
`full | lean | solo`）。迁移会将旧版 `none` **强制转换**为 `solo`，并在迁移报告的警告中报告
此重命名。这是唯一有文档记录的取值重命名，因此它被映射并标记，而非原样保留：原样写入 `none`
会生成一个枚举无效的 `project.yaml`，`resolve_config` 会拒绝它
并回退到 `modes.rigor` 的值 — 在 `standard` 下即为 `lean`，评审*开启* —
从而颠倒用户意图。
`--finalize` 保留检查应用同样的映射，因此它不会错误地
拒绝。每一个*其他*非 v1.1 的 stage/review 取值都是分叉，而非重命名：
原样保留并标记以手动解决，绝不强制转换。

Settings absent from the legacy files (new v1.1 settings like `qa.level`,
`docs.density`, `team.size`, etc.) get hardcoded defaults from the v1.1 schema.
旧版文件中缺失的设置（如 `qa.level`、`docs.density`、`team.size` 等
v1.1 新设置）会从 v1.1 schema 获得硬编码默认值。

### Cleanup (optional, non-destructive)
### 清理（可选，非破坏性）

Migration is **non-destructive in v1.1**: legacy files are NOT auto-deleted.
Migration produces `project.yaml` and leaves the legacy files in place. Hooks
and skills read `project.yaml` first; they fall back to the legacy file if a
specific key is missing.
迁移在 v1.1 中是**非破坏性的**：旧版文件不会被自动删除。
迁移生成 `project.yaml`，并保留旧版文件不动。钩子
和技能首先读取 `project.yaml`；如果某个特定键缺失，它们会回退到旧版文件。

Legacy files are deleted only when the user runs
`.claude/scripts/migrate-v1-config.sh --finalize` (driven by `/adopt`, which
detects a v1.0 project automatically at Phase 2g). The cleanup step verifies
that every legacy file's content has been preserved in `project.yaml` before
deleting.
仅当用户运行 `.claude/scripts/migrate-v1-config.sh --finalize`
（由 `/adopt` 驱动，它在阶段 2g 自动检测 v1.0 项目）时，旧版文件才会被删除。
清理步骤会在删除之前验证每个旧版文件的内容都已在 `project.yaml` 中保留。

### Failure modes
### 失败模式

| Problem | Behavior |
|---------|----------|
| Legacy file is malformed (can't parse) | Migration emits warning per file, leaves it untouched, continues with the others. `project.yaml` gets the parseable values + defaults for the rest. |
| Parsed value doesn't match v1.1 enum (e.g. `stage: Alpha` from a fork) | Migration writes the raw value with a `_migration_warning` comment in `project.yaml`. User resolves manually. |
| Both `project.yaml` AND a legacy file exist (split-brain) | Migration tooling refuses to run. Error: "Both project.yaml and legacy files exist — resolve which is authoritative before migrating." |
| Custom sections in forked `technical-preferences.md` | Custom content logged to `production/migration-report.md` as "not migrated — please integrate manually." |

| 问题 | 行为 |
|---------|----------|
| 旧版文件格式错误（无法解析） | 迁移为每个文件输出警告，保持其不动，继续处理其他文件。`project.yaml` 获得可解析的值 + 其余部分的默认值。 |
| 解析出的值与 v1.1 枚举不匹配（例如分叉中的 `stage: Alpha`） | 迁移写入原始值，并在 `project.yaml` 中附上 `_migration_warning` 注释。用户手动解决。 |
| `project.yaml` 和某个旧版文件同时存在（脑裂） | 迁移工具拒绝运行。错误：“Both project.yaml and legacy files exist — resolve which is authoritative before migrating.” |
| 分叉的 `technical-preferences.md` 中的自定义章节 | 自定义内容记录到 `production/migration-report.md`，标注为“not migrated — please integrate manually.” |

### Migration report
### 迁移报告

Every migration run writes `production/migration-report.md`:
每次迁移运行都会写入 `production/migration-report.md`：

- Source files detected
- 检测到的源文件
- Values preserved (per file → per setting)
- 保留的值（按文件 → 按设置）
- Defaults applied (for v1.1-new settings)
- 应用的默认值（针对 v1.1 新设置）
- Warnings encountered (malformed, mismatched enums, etc.)
- 遇到的警告（格式错误、枚举不匹配等）
- Manual review items
- 手动审查项

User reads the report before running `--finalize`.
用户在运行 `--finalize` 之前阅读该报告。

---

## Complete example `project.yaml`
## 完整示例 `project.yaml`

A full project.yaml with every setting, showing sensible defaults for a solo
Godot project. Use this as the reference shape when authoring or migrating.
一个包含每项设置的完整 project.yaml，展示了单人 Godot 项目的合理默认值。
在编写或迁移时，将此作为参考形态。

```yaml
schema_version: 1

framework:
  version: "1.2.0"
  last_upgraded: "2026-10-18"

project:
  name: "Forge Knights"
  genre: "ARPG"
  version: "0.1.0"
  stage: Concept             # Concept | Systems Design | Technical Setup | Pre-Production | Production | Polish | Release
  kind: game                 # game | tool | engine | mod | library

modes:
  review_mode: lean          # full | lean | solo
  workflow: standard         # minimal | standard | full
  automation: collaborative  # collaborative | guided | autonomous
  automation_always_ask:     # decision categories that always prompt regardless of mode
    - scope_changes
    - file_deletions
    - schema_changes
  story_granularity: balanced  # coarse | balanced | fine

# TOP-LEVEL, not nested under `modes:` — resolve_config reads
# `workflow_overrides.system_overrides.*` from the document root
# (yaml-helper.sh), and every skill greps the same top-level path.
# Nesting it under `modes:` parses as valid YAML and is silently never read.
workflow_overrides:
  edge_cases: false          # force GDD Edge Cases section required
  tuning_knobs: false        # force GDD Tuning Knobs section required
  art_bible_strict: false    # force all 9 art bible sections regardless of asset stories
  system_overrides: {}       # { combat: full, inventory: minimal }

docs:
  density: balanced          # terse | balanced | thorough

testing:
  framework: gdunit4         # engine-specific — auto-populated by /setup-engine
  strict:
    logic: true              # unit test failures BLOCK story closure
    integration: true        # integration test failures BLOCK
    visual: true             # missing screenshot BLOCKS
    ui: true                 # missing screenshot BLOCKS
    config: false            # advisory only

qa:
  level: standard            # minimal | standard | full
  coverage_minimum: null     # integer 0-100; only enforced at level: full

strict_gate_checks: true     # phase gate failures block stage transition

team:
  size: individual           # individual | small | studio

platform:
  multiplayer: false         # real-time multiplayer
  online: false              # any online features (leaderboards, cloud, telemetry)
  targets: [PC]              # [PC, Mobile, Web, Console]
  primary_input: "Keyboard/Mouse"
  gamepad_support: "Full"    # Full | Partial | None
  touch_support: "None"      # Full | Partial | None
  cert_tier: none            # none | itch | steam | console

engine:
  name: "Godot"              # Godot | Unity | Unreal — set by /setup-engine
  version: "4.7"
  language: "GDScript"       # GDScript | C# | C++ | Blueprint
  rendering: "Forward+"
  physics: "Jolt"

specialists:                 # auto-populated by /setup-engine
  code: "godot-gdscript-specialist"
  shader: "godot-shader-specialist"
  ui: "godot-specialist"
  additional: ["godot-gdextension-specialist"]

naming:
  classes: PascalCase        # PascalCase | snake_case | camelCase
  variables: snake_case
  constants: SCREAMING_SNAKE
  signals: past_tense        # past_tense | on_event_name (engine-interpreted)
  files: snake_case
  scenes: snake_case

accessibility:
  target: none               # none | standard | aaa

cadence:
  sprint_length: "2w"        # 1w | 2w | 3w | 4w | none
  milestone_length: "8w"     # 4w | 6w | 8w | 12w

performance:
  target_framerate: 60
  frame_budget_ms: 16.67
  draw_call_limit: null
  memory_ceiling_mb: null
  enforce: warn              # warn | block | off

commands:                    # simple string OR OS-aware map per command
  build: "godot --headless --export-debug '<PRESET>'"   # your export_presets.cfg name
  test: "godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode"
  run: "godot --path . --windowed --resolution 1280x720"
  smoke: "godot --headless --quit-after 5"

features:
  session_state: on          # off | on
  token_budget_warn_at: 0.7  # 0.0-1.0; warn at this context % usage
  read_guard: on             # on | off; true and false also work. Refuse whole-file reads of large design docs
  read_guard_kb: 40          # the size, in KB, over which they are refused

updates:
  check: true                # false: no new-release line at session start
```

And a minimal sparse `project.local.yaml` example — a single developer who wants autonomous mode locally:
以及一个最小稀疏的 `project.local.yaml` 示例 — 一位希望在本地使用自主模式的单个开发者：

```yaml
modes:
  automation: autonomous
features:
  session_state: on
```

Only the overridden keys are present; everything else cascades from `project.yaml`.
See "Local Override Pattern" section for full whitelist of what can/cannot be overridden locally.
仅出现被覆盖的键；其余一切都从 `project.yaml` 级联。
关于哪些内容能在本地覆盖、哪些不能的完整白名单，请参阅“本地覆盖模式”章节。
