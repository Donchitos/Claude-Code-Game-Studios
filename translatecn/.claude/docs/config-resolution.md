# Config Resolution
# 配置解析

How a skill learns its effective settings. **One command, no prose chain.**
技能如何获知其生效设置。**一条命令，不构成散文式链条。**

## The rule
## 规则

A skill that needs config puts this near the top of its **body** (not frontmatter):
需要配置的技能将其放在其**正文**（不是 frontmatter）靠近顶部的位置：

````markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b`
````

**and** pre-approves exactly that command in its own frontmatter, with its own
directory name in the path:
**并且**在其自身的 frontmatter 中预先批准正是该命令，路径中包含其自己的目录名：

````yaml
allowed-tools: Read, …, Bash(bash "*/.claude/skills/<skill-name>/../../hooks/yaml-helper.sh" resolve_config *)
````

The command runs as preprocessing *before the model sees the skill*, and its
output replaces the placeholder inline. The skill then reads the resolved values
and **does not re-derive them**.
该命令作为预处理在*模型看到技能之前*运行，其输出会就地替换占位符。技能随后读取解析后的值，并**不再重新推导它们**。

Skills that resolve a per-system tier pass the system name: `resolve_config combat`.
解析逐系统层级的技能会传入系统名称：`resolve_config combat`。

## Why the body, not `context:`
## 为什么放在正文，而不是 `context:`

`` !`cmd` `` in the skill body is the documented mechanism. Frontmatter
`context:` accepts only `context: fork` — it does **not** run shell. A
`context: |` block containing `!` commands **never executes**; put the command in
the skill body instead.
技能正文中的 `` !`cmd` `` 是文档记载的机制。Frontmatter 的 `context:` 只接受 `context: fork` — 它**不会**运行 shell。包含 `!` 命令的 `context: |` 块**永远不会执行**；请改为将命令放在技能正文中。

## Why exactly this command — the permission check
## 为什么正是这条命令 — 权限检查

Claude Code permission-checks every injected command **before** the skill
renders. Outside auto mode, anything that does not come back "allow" — including
a command that would normally just prompt — **aborts the whole invocation**, and
the model never sees the skill. A read-only command such as `git status`, which
Claude Code approves on its own, comes back "allow" and runs without a grant. A preloaded skill (`skills:` on an agent) is
checked the same way at agent launch, so a failing bootstrap line stops the agent
from starting. In default
mode, the bootstrap forms behave as follows:
Claude Code 会在技能渲染**之前**对每条注入命令进行权限检查。在自动模式之外，任何未返回 "allow" 的内容 — 包括通常只会提示的命令 — **都会中止整个调用**，模型永远看不到技能。像 `git status` 这样的只读命令，Claude Code 会自行批准，返回 "allow" 并在无授权的情况下运行。预加载技能（智能体上的 `skills:`）在智能体启动时也以相同方式检查，因此失败的引导行会阻止智能体启动。在默认模式下，各引导形式表现如下：

| Bootstrap form | Repo root | Subdirectory | Bash-less agent preloading it |
| 引导形式 | 仓库根目录 | 子目录 | 无 Bash 的智能体预加载它 |
|---|---|---|---|
| `source "${CLAUDE_PROJECT_DIR:-.}/…" && resolve_config` | aborts | aborts | fails to launch |
| `source "${CLAUDE_PROJECT_DIR:-.}/…" && resolve_config` | 中止 | 中止 | 启动失败 |
| same, with a bare `Bash` grant | aborts | — | — |
| 相同，但带裸 `Bash` 授权 | 中止 | — | — |
| `bash "${CLAUDE_PROJECT_DIR}/…"` + grant | runs | aborts | — |
| `bash "${CLAUDE_PROJECT_DIR}/…"` + 授权 | 运行 | 中止 | — |
| **`bash "${CLAUDE_SKILL_DIR}/../../hooks/…"` + per-skill grant** | **runs** | **runs** | **launches** |
| **`bash "${CLAUDE_SKILL_DIR}/../../hooks/…"` + 逐技能授权** | **运行** | **运行** | **启动** |

What that table rules out:
该表排除了哪些做法：

- **No `${VAR:-x}` expansion.** It fails as "Contains expansion", and no grant
  can approve it. `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` are fine: Claude
  Code substitutes them as text before the check.
- **禁止 `${VAR:-x}` 展开。** 它会以 "Contains expansion" 失败，且任何授权都无法批准它。`${CLAUDE_SKILL_DIR}` 和 `${CLAUDE_PROJECT_DIR}` 没问题：Claude Code 在检查前会将它们作为文本替换。
- **No `${CLAUDE_PROJECT_DIR}` for the path.** In a skill it is the directory
  Claude Code was launched from, not the repo root, so it breaks when Claude
  Code is started in a subdirectory.
  `${CLAUDE_SKILL_DIR}` always names the skill's own folder.
- **路径中禁止使用 `${CLAUDE_PROJECT_DIR}`。** 在技能中它是 Claude Code 启动时所在的目录，而不是仓库根目录，因此当 Claude Code 从子目录启动时会失效。`${CLAUDE_SKILL_DIR}` 始终指向技能自己的文件夹。
- **No `source … && …` compound.** Each part must be approved; `bash <file>
  resolve_config` is one command. `yaml-helper.sh` dispatches only
  `resolve_config` when executed, and finds the repo root from its own location.
- **禁止 `source … && …` 复合命令。** 每个部分都必须被批准；`bash <file>
  resolve_config` 是一条命令。`yaml-helper.sh` 在执行时分派只有 `resolve_config`，并从其自身位置找到仓库根目录。
- **The grant is required.** `allowed-tools` is what pre-approves an injected
  command. The pattern must include the literal `"` after the path — a pattern
  ending `…yaml-helper.sh *` does not match.
- **授权是必需的。** `allowed-tools` 才是预先批准注入命令的东西。模式必须在路径后包含字面量 `"` — 以 `…yaml-helper.sh *` 结尾的模式不会匹配。
- **Any non-zero exit aborts too.** The entry point always exits 0; other
  injected commands that can fail end in `|| true`.
- **任何非零退出也会中止。** 入口点始终以 0 退出；其他可能失败的注入命令以 `|| true` 结尾。

Auto mode can approve the old form on its own, which is how v1.1.0 shipped with
it. Test bootstrap changes in default mode, in a project without a
`settings.local.json`.
自动模式可以自行批准旧形式，v1.1.0 就是这样发布的。请在默认模式下、在没有 `settings.local.json` 的项目中测试引导变更。

`disableSkillShellExecution: true` replaces every injected command with a
placeholder message. If a skill sees no config block, it falls back to the
defaults below.
`disableSkillShellExecution: true` 会将每条注入命令替换为占位消息。如果技能看不到配置块，它会回退到下面的默认值。

## The block
## 该块

```
=== CCGS Resolved Config ===
review_mode: lean (production/review-mode.txt)
automation: guided (project.local.yaml)
workflow: standard (project.yaml)
docs.density: balanced (rigor:standard)
story_granularity: balanced (rigor:standard)
qa.level: standard (rigor:standard)
team.size: individual (rigor:standard)
project.stage: Systems Design (production/stage.txt)
automation_always_ask: scope_changes, file_deletions, schema_changes (default)
engine: Godot 4.7 (project.yaml)
testing.strict: logic=true integration=false visual=unset ui=unset config=unset (unset = each skill applies its own default)
system_overrides: combat=full inventory=minimal
notes: none
Values above are fully resolved (local -> yaml -> legacy -> default). Use as-is.
An inline --review flag, if passed, overrides review_mode.
=== end CCGS config ===
```

Every knob line ends with its **provenance** in parentheses. That is what makes a
wrong value diagnosable — `review_mode: solo (rigor:minimal)` when `project.yaml` says
`full` points straight at the problem.
每个旋钮行都以括号中的**来源**结尾。这正是让错误值可诊断的原因 — 当 `project.yaml` 写着 `full` 时出现 `review_mode: solo (rigor:minimal)` 会直接指向问题所在。

## Resolution chain
## 解析链

| Step | Source | Applies to |
| 步骤 | 来源 | 适用于 |
|---|---|---|
| 1 | `project.local.yaml` | any setting on the `/settings --local` whitelist (12 keys — `modes.review_mode`, `modes.automation`, `modes.automation_always_ask`, `team.size`, all five `testing.strict.*`, `performance.enforce`, `features.*`) |
| 1 | `project.local.yaml` | `/settings --local` 白名单上的任何设置（12 个键 — `modes.review_mode`、`modes.automation`、`modes.automation_always_ask`、`team.size`、所有五个 `testing.strict.*`、`performance.enforce`、`features.*`） |
| 2 | `project.yaml` | all keys |
| 2 | `project.yaml` | 所有键 |
| 3 | legacy plain-text mirror | `modes.review_mode` → `production/review-mode.txt`; `project.stage` → `production/stage.txt` |
| 3 | 旧版纯文本镜像 | `modes.review_mode` → `production/review-mode.txt`；`project.stage` → `production/stage.txt` |
| 4 | **`modes.rigor` expansion** | the six knobs `rigor` fronts — `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`, `team.size` |
| 4 | **`modes.rigor` 展开** | `rigor` 前置的六个旋钮 — `modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity`、`modes.review_mode`、`team.size` |
| 5 | documented default | the table below |
| 5 | 文档记录的默认值 | 下表 |

An **enum-invalid value does not win** — the chain continues past it and the
rejected value is named on the `notes:` line. A typo degrades to the documented
default rather than propagating a nonsense mode into every skill.
**枚举无效的值不会胜出** — 解析链会越过它继续，被拒绝的值会在 `notes:` 行中指明。拼写错误会降级为文档记录的默认值，而不是把荒谬的模式传播到每个技能中。

> **Step 4 sits below every explicit source and above the terminal default, and
> that ordering is the whole back-compat guarantee.** A `project.yaml` that
> already sets `docs.density: terse` resolves exactly as it did before `rigor`
> existed, because step 2 answers first. Invert steps 4 and 5 and `rigor` becomes
> a no-op; hoist step 4 above step 2 and it silently overrides settings people
> already have.
>
> Derived values report their provenance as **`rigor:<level>`**, so the source
> vocabulary is `{project.local.yaml, project.yaml, <legacy path>, rigor:<level>,
> default, unset}`. `docs.density: balanced (rigor:standard)` says the value was
> never written down anywhere — it follows the project's rigor level and will
> move if that level moves.
> **步骤 4 位于每个显式来源之下、终端默认值之上，而这一排序就是整个向后兼容的保证。** 已经设置 `docs.density: terse` 的 `project.yaml` 解析结果与 `rigor` 存在之前完全一样，因为步骤 2 先作答。颠倒步骤 4 和 5，`rigor` 就变成空操作；把步骤 4 提升到步骤 2 之上，它就会静默覆盖人们已有的设置。
>
> 派生值将其来源报告为 **`rigor:<level>`**，因此来源词汇表为 `{project.local.yaml, project.yaml, <legacy path>, rigor:<level>,
> default, unset}`。`docs.density: balanced (rigor:standard)` 表示该值从未在任何地方写下 — 它跟随项目的严谨度层级，并会随该层级的移动而移动。

> **Read scope == write whitelist.** Anything `/settings --local` may *write*
> is also *read* during resolution. If the read scope were ever narrower,
> `/settings --local modes.review_mode=solo` would write a value
> that `/settings` accepted and displayed and every skill then ignored. The
> test suite asserts the two lists stay in step — adding a setting to one
> without the other reproduces that bug.
>
> This matches the spec: `effects-map.md` § "Local Override Pattern" has always
> stated the chain applies to *every* setting. The narrow read scope was an
> implementation gap, not a design.
> **读取范围 == 写入白名单。** `/settings --local` 可以*写入*的任何内容，在解析期间也会被*读取*。如果读取范围曾经更窄，`/settings --local modes.review_mode=solo` 就会写入一个 `/settings` 接受并显示、但每个技能随后都忽略的值。测试套件断言这两个列表保持一致 — 只向其中一个添加设置而不添加到另一个，就会重现该 bug。
>
> 这与规范一致：`effects-map.md` 的 "Local Override Pattern" 一节一直声明该链适用于*每个*设置。狭窄的读取范围是实现缺口，而非设计。

> **A key OUTSIDE the whitelist, hand-written into `project.local.yaml`, is
> reported rather than swallowed.** `/settings --local` refuses to
> write one, but the file exists to be edited by hand, so that path needs its own
> guard. `modes.rigor: full` written there is a real key with a legal value, so
> `validate_yaml_enum` passes it — and then resolution never consults the local
> file for that path, so the setting vanishes and the user sees the default they
> were trying to override, with no error anywhere. Every check in the chain
> validated the **value**; nothing validated the **location**.
>
> `validate_local_scope` now names such keys on `notes:`. It **warns and never
> reconciles**, the same shape as the stage-mirror check: it does not edit the
> file, does not begin honouring the key, and does not change resolution. A
> locked setting is locked because it decides which artifacts exist on disk, so
> a helper that quietly applied one would let two developers' checkouts diverge
> — the exact thing the whitelist prevents. The user moves the key to
> `project.yaml` or deletes it.
>
> `schema_version` and `framework.*` are exempt: `effects-map.md` classes them as
> file metadata rather than preferences, and a `project.local.yaml` carrying
> `schema_version: 1` is correct as written.
> **白名单之外、手工写入 `project.local.yaml` 的键会被报告，而不是被吞掉。** `/settings --local` 拒绝写入这样的键，但该文件的存在就是为了手工编辑，因此那条路径需要自己的防护。写在那里 `modes.rigor: full` 是一个具有合法值的真实键，所以 `validate_yaml_enum` 会通过它 — 然而解析从不为该路径查阅本地文件，于是该设置消失，用户看到他们试图覆盖的默认值，且任何地方都没有报错。链中的每项检查都验证了**值**；没有任何检查验证**位置**。
>
> `validate_local_scope` 现在会在 `notes:` 上指出这类键。它**发出警告且从不调和**，与阶段镜像检查的形式相同：它不编辑文件、不开始遵从该键，也不改变解析。被锁定的设置之所以被锁定，是因为它决定磁盘上存在哪些产物，因此一个悄悄应用其中某一项的辅助程序会让两位开发者的检出产生分歧 — 这正是白名单所防止的事情。用户需将该键移到 `project.yaml` 或删除它。
>
> `schema_version` 和 `framework.*` 属于豁免项：`effects-map.md` 将它们归类为文件元数据而非偏好，而携带 `schema_version: 1` 的 `project.local.yaml` 按原样就是正确的。

## Defaults
## 默认值

| Knob | Default |
| 旋钮 | 默认值 |
|---|---|
| `modes.automation` | `collaborative` |
| `modes.automation` | `collaborative` |
| `modes.rigor` | `minimal` |
| `modes.rigor` | `minimal` |
| `modes.automation_always_ask` | `scope_changes`, `file_deletions`, `schema_changes` |
| `modes.automation_always_ask` | `scope_changes`、`file_deletions`、`schema_changes` |

**The six knobs `rigor` fronts have no terminal default at all.** `modes.workflow`,
`docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode` and `team.size` are
deliberately absent from `_yaml_helper_defaults`: a default there would answer at step 5 before the
expansion at step 4 ever ran, making `rigor` a no-op for anyone who had not also
set the sub-knob. Their effective values come from the rigor level:
**`rigor` 前置的六个旋钮根本没有终端默认值。** `modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity`、`modes.review_mode` 和 `team.size` 被有意排除在 `_yaml_helper_defaults` 之外：那里的默认值会在步骤 4 的展开运行之前就于步骤 5 作答，从而使 `rigor` 对任何未同时设置子旋钮的人变成空操作。它们的生效值来自严谨度层级：

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` (default) | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `minimal`（默认） | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

Because `rigor` itself defaults to `minimal`, an unconfigured project resolves
these six to the lean row. That default was `standard`; it changed because the
heavier tier costs more to reach working code without producing a better
result. See the rationale block above `_yaml_helper_defaults`
in `.claude/hooks/yaml-helper.sh` for the reasoning and the ordering
constraint. Raising the tier is one question in `/start` or one `/settings`
call, and `settings-guidance.md § 4`'s upward triggers are written to fire from
this starting state. (`team.size` is the one knob the flip does not move:
`minimal` and `standard` both yield `individual`, and only `full` opts into the
`studio` roster.)
由于 `rigor` 本身默认为 `minimal`，未配置的项目会将这六项解析为精简行。该默认值原本是 `standard`；它之所以改变，是因为更重的层级要达到可运行代码的成本更高，却没有产生更好的结果。推理过程和排序约束见 `.claude/hooks/yaml-helper.sh` 中 `_yaml_helper_defaults` 上方的理由块。提高层级只需在 `/start` 中回答一个问题或调用一次 `/settings`，而 `settings-guidance.md § 4` 的向上触发条件是按照从这个起始状态触发来编写的。（`team.size` 是翻转不会改变的唯一旋钮：`minimal` 和 `standard` 都产出 `individual`，只有 `full` 才选择加入 `studio` 名册。）

> **The flip DOES reach existing projects.** A `project.yaml` that sets some of
> the six explicitly but never sets `rigor` keeps its explicit values and takes
> the new `minimal` row for the rest -- so an unset `qa.level` that used to
> resolve `standard` now resolves `minimal`.
> Pin the old behaviour by setting `modes.rigor: standard` explicitly; see
> UPGRADING.md.
> **该翻转确实会影响现有项目。** 一个显式设置了六项中的部分、但从未设置 `rigor` 的 `project.yaml` 会保留其显式值，其余项则采用新的 `minimal` 行 -- 因此过去解析为 `standard` 的未设置 `qa.level` 现在解析为 `minimal`。通过显式设置 `modes.rigor: standard` 来固定旧行为；见 UPGRADING.md。

`modes.workflow` is **fronted, not replaced**: it keeps
`workflow_overrides.system_overrides`, which still beats the derived value.
Setting any of the six explicitly overrides just that one and leaves
its siblings on the rigor level, which is how "comprehensive but compact"
(`rigor: full` + `docs.density: terse`) stays expressible. Two of the six —
`modes.review_mode` and `team.size` — are personal-experience knobs that also
remain overridable from `project.local.yaml` (that source sits above the
expansion), unlike the four on-disk knobs, which are locked.
`modes.workflow` 是**被前置，而非被替换**：它保留 `workflow_overrides.system_overrides`，后者仍然胜过派生值。显式设置六项中的任何一项只会覆盖那一项，并让其同类项留在严谨度层级上，这就是"全面但紧凑"（`rigor: full` + `docs.density: terse`）仍可表达的方式。六项中的两项 — `modes.review_mode` 和 `team.size` — 是个人体验旋钮，也仍可从 `project.local.yaml` 覆盖（该来源位于展开之上），不同于四个磁盘上的旋钮，后者是锁定的。

> **Keep this table in step with the helper.** Every knob listed here must carry
> the value `_yaml_helper_defaults` returns (read it through `get_yaml_default`),
> and none of the six fronted knobs may appear in it.
> **让该表与辅助程序保持一致。** 这里列出的每个旋钮都必须带有 `_yaml_helper_defaults` 返回的值（通过 `get_yaml_default` 读取它），并且六个前置旋钮中的任何一个都不得出现在其中。

**`testing.strict.*` has no central default on purpose.** Its unset default
differs per skill by design: `/smoke-check` treats unset as **blocking** (it is a
build-health gate), while `/story-done` and `/dev-story` apply the per-story-type
table in `.claude/docs/coding-standards.md`. The `testing.strict` line therefore
reports only the *configured state* (`unset` where absent). The `gate_level` line
(below) applies that table and names `/smoke-check`'s own default beside `config`.
**`testing.strict.*` 故意没有中心默认值。** 其未设置时的默认值按设计因技能而异：`/smoke-check` 将未设置视为**阻塞**（它是一个构建健康门禁），而 `/story-done` 和 `/dev-story` 应用 `.claude/docs/coding-standards.md` 中按故事类型的表。因此 `testing.strict` 行只报告*已配置状态*（缺省处为 `unset`）。`gate_level` 行（下方）应用该表，并在 `config` 旁指明 `/smoke-check` 自己的默认值。

**The `engine` line is reported from `project.yaml` only.** The `engine_values`
line (below) adds the per-field fallback to `.claude/docs/technical-preferences.md`,
which also remains the sole source for forbidden patterns and allowed libraries —
those never migrated.
**`engine` 行仅从 `project.yaml` 报告。** `engine_values` 行（下方）为每个字段增加了回退到 `.claude/docs/technical-preferences.md` 的能力，该文件也仍然是禁止模式和允许库的唯一来源 — 这些从未迁移。

## Derived lines (named only)
## 派生行（仅在指名时）

Six more lines answer steps skills would otherwise work out by hand. Each prints
**only when named** in `--keys`; the full block never includes them. Each value carries its source in parentheses, and YAML `null`
or `~` reads as unset (the reader returns them as strings, which are not empty).
另有六行回答技能否则需要手工推算的步骤。每个行**仅在 `--keys` 中指名时**输出；完整块从不会包含它们。每个值在括号中带有其来源，YAML 的 `null` 或 `~` 读作未设置（读取器将它们作为字符串返回，而字符串不是空的）。

| Label | What it prints |
| 标签 | 输出内容 |
|---|---|
| `gate_level` | The gate level per story type: `testing.strict.<type>` (`project.local.yaml`, then `project.yaml`), then the plain `testing.strict: true\|false`, then the default table in `coding-standards.md`. `gate_level: logic=blocking(default) integration=advisory(project.yaml) visual=blocking(default) ui=blocking(default) config=advisory(default; /smoke-check: blocking)` |
| `gate_level` | 按故事类型的门禁级别：先 `testing.strict.<type>`（`project.local.yaml`，然后 `project.yaml`），再是普通的 `testing.strict: true\|false`，最后是 `coding-standards.md` 中的默认表。`gate_level: logic=blocking(default) integration=advisory(project.yaml) visual=blocking(default) ui=blocking(default) config=advisory(default; /smoke-check: blocking)` |
| `engine_values` | `engine.name`, `.version` and `.language`, each falling back to `technical-preferences.md` (its Engine line holds name and version together). `engine_values: name=Godot(project.yaml) version=4.7(project.yaml) language=GDScript(project.yaml)` |
| `engine_values` | `engine.name`、`.version` 和 `.language`，各自回退到 `technical-preferences.md`（其 Engine 行将名称和版本放在一起）。`engine_values: name=Godot(project.yaml) version=4.7(project.yaml) language=GDScript(project.yaml)` |
| `specialists` | The engine specialists: `primary` from the engine, the rest from the `specialists` block, where `null` is unset and never an agent name; `technical-preferences.md` only when the block is absent. `specialists: primary=godot-specialist(engine.name) code=godot-gdscript-specialist shader=unset ui=godot-specialist additional=none (project.yaml; unset = skip that specialist)` |
| `specialists` | 引擎专家：`primary` 来自引擎，其余来自 `specialists` 块，其中 `null` 是未设置，绝不是智能体名称；仅当该块缺失时才用 `technical-preferences.md`。`specialists: primary=godot-specialist(engine.name) code=godot-gdscript-specialist shader=unset ui=godot-specialist additional=none (project.yaml; unset = skip that specialist)` |
| `review_gate` | Whether a skill's own director gate and the PHASE-GATEs run at the resolved `review_mode` (`director-gates.md`): `solo` none, `lean` the PHASE-GATEs only, `full` all. `review_gate: skill-gates=skip phase-gates=run (review_mode lean, rigor:standard; a --review flag overrides)` |
| `review_gate` | 技能自身的总监门禁和 PHASE-GATE 是否在解析后的 `review_mode` 下运行（`director-gates.md`）：`solo` 全不运行，`lean` 仅 PHASE-GATE，`full` 全部运行。`review_gate: skill-gates=skip phase-gates=run (review_mode lean, rigor:standard; a --review flag overrides)` |
| `input_methods` | The input methods from the `platform` block, each listed once: keyboard/mouse when `PC` or `Web` is a target, gamepad and touch when their support is Full or Partial, plus the primary input, where a primary input such as `Keyboard`, `Controller` or `Touchscreen` is read as keyboard/mouse, gamepad or touch; else `technical-preferences.md`'s Input Methods line. `input_methods: keyboard/mouse, gamepad (project.yaml platform; primary: Gamepad)` |
| `input_methods` | 来自 `platform` 块的输入方式，每种只列一次：当 `PC` 或 `Web` 是目标平台时列 keyboard/mouse，当手柄和触摸支持为 Full 或 Partial 时列 gamepad 和 touch，再加上主输入方式，其中 `Keyboard`、`Controller` 或 `Touchscreen` 之类的主输入被读作 keyboard/mouse、gamepad 或 touch；否则使用 `technical-preferences.md` 的 Input Methods 行。`input_methods: keyboard/mouse, gamepad (project.yaml platform; primary: Gamepad)` |
| `perf_budgets` | The four `performance.*` budgets (`target_framerate`, `frame_budget_ms`, `draw_call_limit`, `memory_ceiling_mb`), from `project.yaml` only: they are not locally overridable. `perf_budgets: target_framerate=60 frame_budget_ms=16.67 draw_call_limit=unset memory_ceiling_mb=unset (project.yaml)` |
| `perf_budgets` | 四个 `performance.*` 预算（`target_framerate`、`frame_budget_ms`、`draw_call_limit`、`memory_ceiling_mb`），仅来自 `project.yaml`：它们不可本地覆盖。`perf_budgets: target_framerate=60 frame_budget_ms=16.67 draw_call_limit=unset memory_ceiling_mb=unset (project.yaml)` |

## Failure modes
## 失败模式

`resolve_config` **always exits 0 and always emits a complete block.** Each
condition below degrades to defaults and is named on `notes:`:
`resolve_config` **始终以 0 退出，并始终输出一个完整的块。** 下面的每种情况都会降级为默认值，并在 `notes:` 上被指名：

| Condition | Behavior |
| 情况 | 行为 |
|---|---|
| `project.yaml` absent | legacy → defaults; `notes: project.yaml absent` |
| `project.yaml` 缺失 | 旧版 → 默认值；`notes: project.yaml absent` |
| `project.yaml` **empty** | defaults; `notes: project.yaml is EMPTY`. Distinct from absent on purpose — a truncated write or an interrupted `/setup-engine` looks like this |
| `project.yaml` **为空** | 默认值；`notes: project.yaml is EMPTY`。故意与缺失区分 — 被截断的写入或中断的 `/setup-engine` 就会像这样 |
| Malformed YAML | unparseable keys resolve empty and fall through |
| YAML 格式错误 | 无法解析的键解析为空并向下贯穿 |
| Tab-indented lines | rejected, and the **line numbers are named** on `notes:` |
| 制表符缩进的行 | 被拒绝，且**行号会在 `notes:` 上被指名** |
| CRLF line endings | parsed correctly (the Windows default) |
| CRLF 行尾 | 正确解析（Windows 默认） |
| UTF-8 BOM | parsed correctly; the BOM does not poison the first key |
| UTF-8 BOM | 正确解析；BOM 不会污染第一个键 |
| 3-space indent | parsed correctly; the parser is indent-tolerant |
| 3 空格缩进 | 正确解析；解析器容忍缩进 |
| Key present, value empty | treated as **unset**; falls through to the next source, never to `""` |
| 键存在、值为空 | 视为**未设置**；向下贯穿到下一个来源，绝不到 `""` |
| Enum-invalid value | chain continues; rejected value named in `notes:` |
| 枚举无效的值 | 链继续；被拒绝的值在 `notes:` 中被指名 |
| Duplicate key (two `modes:` blocks, or `rigor:` twice in one block) | a repeated block is **merged**, so every key in either block is read; a key set twice takes the **last** value. Named on `notes:` with its lines — ``duplicate key `modes` (lines 2, 9): read here as one merged block, …`` |
| 重复键（两个 `modes:` 块，或一个块中两次 `rigor:`） | 重复的块会被**合并**，因此两个块中的每个键都会被读取；设置两次的键取**最后**一个值。在 `notes:` 上连同其行号被指名 — ``duplicate key `modes` (lines 2, 9): read here as one merged block, …`` |
| `project.local.yaml` without a base | `validate_local_yaml_base` message on `notes:` |
| 没有基础配置的 `project.local.yaml` | `notes:` 上出现 `validate_local_yaml_base` 消息 |
| Locked key in `project.local.yaml` | ignored as always, but now **named** on `notes:` — `local: not locally overridable, ignored — modes.rigor (move to project.yaml or delete)` |
| `project.local.yaml` 中的锁定键 | 一如既往被忽略，但现在会在 `notes:` 上被**指名** — `local: not locally overridable, ignored — modes.rigor (move to project.yaml or delete)` |
| No Python interpreter | legacy files and defaults only; **explicitly noted** on `notes:` |
| 无 Python 解释器 | 仅使用旧版文件和默认值；在 `notes:` 上**明确注明** |
| No block at all | shell preprocessing disabled (`disableSkillShellExecution`) — use the defaults table above |
| 完全没有块 | shell 预处理被禁用（`disableSkillShellExecution`）— 使用上方的默认值表 |
| A task notice where the block should be ("Command did not complete within its 120s timeout and was moved to the background") | the settings line ran past Claude Code's 120-second limit for a skill's `!` line, because every process start was slowed — usually by antivirus real-time scanning of the project folder. The settings exist: read each key yourself from `project.local.yaml`, then `project.yaml`, then the defaults table above |
| 本应是块的位置出现任务通知（"Command did not complete within its 120s timeout and was moved to the background"） | 设置行超过了 Claude Code 对技能 `!` 行的 120 秒限制，因为每次进程启动都被拖慢 — 通常是项目文件夹的杀毒软件实时扫描。设置是存在的：自行从 `project.local.yaml`、再 `project.yaml`、最后上方的默认值表读取每个键 |
| Bootstrap line not approved, or exits non-zero | **not a degraded state — the skill never renders at all.** See "Why exactly this command" above |
| 引导行未获批准，或非零退出 | **不是降级状态 — 技能根本不会渲染。** 见上文的 "Why exactly this command" |

A skill must never treat a missing block as "config is unset in an interesting
way". It means the block did not render; the defaults apply. The exception is
that task notice: the settings line ran out of time, not the settings, so read
the files as that row says instead of taking the defaults. If it keeps
happening, exclude the project folder from real-time scanning.
技能绝不能把缺失的块当作"配置以一种有趣的方式未设置"。它意味着块没有渲染；默认值适用。例外的是那个任务通知：超时的是设置行，而不是设置，所以按该行所述读取文件，而不是采用默认值。如果持续发生，请将项目文件夹排除在实时扫描之外。

### An input that resolves without a note
### 一种不带注释即可解析的输入

Here `resolve_config` follows a fixed rule and emits no note, so it does not tell
you that something you wrote was not used.
这里 `resolve_config` 遵循一条固定规则且不发出注释，因此它不会告诉你你写的内容未被使用。

| Input | What happens | Note emitted |
| 输入 | 会发生什么 | 发出的注释 |
|---|---|---|
| **Wrong shape** — a list where a scalar belongs (`rigor:` followed by `- standard`) | key resolves empty, falls through to the default | **none** |
| **形状错误** — 在应放标量的地方放了列表（`rigor:` 后跟 `- standard`） | 键解析为空，向下贯穿到默认值 | **无** |

An enum-*invalid* value is announced (`modes.workflow: 'medium' is not a valid
value … — ignored, chain continued`), and so is a duplicate key. A wrong shape
is not: the key is present but resolves to nothing, which is also what a key
with an empty value does on purpose (the "Key present, value empty" row above),
and `resolve_config` does not tell the two apart. When a setting seems ignored,
check the structure of its key in the file: one scalar on the key's own line and
no list under it. `/settings` shows the value that is actually in effect.
枚举*无效*的值会被公布（`modes.workflow: 'medium' is not a valid
value … — ignored, chain continued`），重复键也是如此。形状错误则不会：键存在但解析为空，这也正是空值键故意为之的行为（上方"键存在、值为空"行），而 `resolve_config` 无法区分两者。当某个设置似乎被忽略时，检查文件中其键的结构：键所在行只有一个标量，其下没有列表。`/settings` 显示实际生效的值。

Merging a repeated block and taking the last value of a repeated key are fixed
rules here, but most other YAML tools keep only the last block. Combine repeated
blocks rather than rely on the merge.
合并重复块并取重复键的最后一个值在这里是固定规则，但大多数其他 YAML 工具只保留最后一个块。请合并重复块，而不要依赖该合并。

## Why not inject at session start
## 为什么不在会话开始时注入

`resolve_config` is also safe to call from a hook, but session-start does **not**
call it. The block would cost tokens on every session whether or not any skill
needs config, and it would go stale mid-session as `/settings` writes land. The
per-skill body call is fresher and only loads where it is used. Session start
still prints the resolved review mode and any schema errors, which is the part a
human reads.
`resolve_config` 也可以安全地从钩子调用，但会话启动**不会**调用它。该块会在每个会话中消耗 token，无论是否有任何技能需要配置，而且随着 `/settings` 写入落地，它会在会话中途过时。逐技能正文调用更新鲜，且只在用到的地方加载。会话启动仍会打印解析后的评审模式和任何模式错误，这是人类会阅读的部分。

## Testing
## 测试

The resolution chain, the legacy reader, enum fall-through, block shape and
every failure mode above are covered by the framework's own test suite under
`tests/`, along with the `modes.rigor` expansion and its precedence in both
directions. Two properties are asserted that are easy to lose:
解析链、旧版读取器、枚举贯穿、块形状以及上述每种失败模式都由框架自身在 `tests/` 下的测试套件覆盖，连同 `modes.rigor` 展开及其两个方向上的优先级。其中断言了两个容易丢失的性质：

- The local **read** scope and the `/settings --local` **write** whitelist stay
  in step. If they drift, `/settings` accepts and displays a value that every
  skill then ignores.
- 本地**读取**范围与 `/settings --local` 的**写入**白名单保持一致。如果它们漂移，`/settings` 会接受并显示一个随后被每个技能忽略的值。
- The expansion is *reachable* (`/start` asks about it) and *legible*
  (`/settings` reports derived values rather than "(not set)"). A correct
  expansion nobody is asked about and no view displays would be worth nothing.
- 该展开是*可达的*（`/start` 会询问它）且*可读的*（`/settings` 报告派生值而不是 "(not set)"）。一个无人被询问、也没有任何视图显示的正确展开将毫无价值。
