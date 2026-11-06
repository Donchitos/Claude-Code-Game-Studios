---
name: help
description: "What should I do next? Use when stuck or you don't know what to do."
argument-hint: "[optional: what you just finished, e.g. 'finished design-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/help/../../scripts/story-status.sh"), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *), Bash(git log *)
model: haiku
---
---
name: help
description: "我接下来该做什么？在卡住或不知道该做什么时使用。"
argument-hint: "[optional: what you just finished, e.g. 'finished design-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/help/../../scripts/story-status.sh"), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *), Bash(git log *)
model: haiku
---

# Studio Help — What Do I Do Next?
# 工作室帮助 — 我接下来该做什么？

This skill is read-only — it reports findings but writes no files.
此技能是只读的 — 它报告发现但不写入文件。

This skill figures out exactly where you are in the game development pipeline and
tells you what comes next. It is **lightweight** — not a full audit. For a full
gap analysis, use `/project-stage-detect`.
此技能准确判断你处于游戏开发流水线的哪个位置，并告诉你接下来做什么。它是**轻量级**的 — 并非完整审计。如需完整的差距分析，请使用 `/project-stage-detect`。

## Live Project State
## 实时项目状态

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys project.stage,workflow`

These are resolved before this skill runs. Use them as-is:
这些内容在此技能运行之前已解析。直接使用：

- **`project.stage`** from the config block is the authoritative phase for Step 2
  — it already applies the `project.yaml` → `production/stage.txt` fallback, and
  preserves values containing spaces (`Systems Design`).
- **`workflow`** from the config block is the tier for Steps 2 and 5 — do not
  re-read it.
- If no config block rendered, shell preprocessing is disabled; fall back to the
  defaults in `.claude/docs/config-resolution.md`.
- 配置块中的 **`project.stage`** 是第 2 步的权威阶段
  — 它已应用 `project.yaml` → `production/stage.txt` 的回退，并且
  保留含空格的值（`Systems Design`）。
- 配置块中的 **`workflow`** 是第 2 步和第 5 步的层级 — 不要
  重新读取它。
- 若未渲染配置块，shell 预处理已禁用；请回退到
  `.claude/docs/config-resolution.md` 中的默认值。

---

## Step 1: Read the Catalog
## 步骤 1：读取目录

Read `.claude/docs/workflow-catalog.yaml`. This is the authoritative list of all
phases, their steps (in order), whether each step is required or optional, and
the artifact globs that indicate completion.
读取 `.claude/docs/workflow-catalog.yaml`。这是所有阶段、其步骤（按顺序）、
每个步骤是必需还是可选，以及指示完成的制品 glob 的权威列表。

---

## Step 1b: Find Skills Not in the Catalog
## 步骤 1b：查找不在目录中的技能

After reading the catalog, Glob `.claude/skills/*/SKILL.md` to get the full list
of installed skills. For each file, extract the `name:` field from its frontmatter.
读取目录后，Glob `.claude/skills/*/SKILL.md` 以获取已安装技能的完整列表。
对每个文件，从其 frontmatter 中提取 `name:` 字段。

Compare against the `command:` values in the catalog. Any skill whose name does
not appear as a catalog command is an **uncataloged skill** — still usable but not
part of the phase-gated workflow.
与目录中的 `command:` 值比较。任何名称未作为目录命令出现的技能都是**未编入目录的技能**
— 仍可使用，但不属于阶段门禁工作流的一部分。

Collect these for the output in Step 7 — show them as a footer block:
为步骤 7 的输出收集这些内容 — 将其作为页脚块显示：

```
### Also installed (not in workflow)
- `/skill-name` — [description from SKILL.md frontmatter]
- `/skill-name` — [description]
```

Only show this block if at least one uncataloged skill exists. Limit to the 10
most relevant based on the user's current phase (QA skills in production, team
skills in production/polish, etc.).
仅当至少存在一个未编入目录的技能时才显示此块。根据用户当前阶段
限制为最相关的 10 个（制作阶段的 QA 技能、制作/打磨阶段的团队技能等）。

---

## Step 2: Determine Current Phase
## 步骤 2：确定当前阶段

**First, take `workflow` from the config block above.** If it is `minimal`, the
project is on the minimal path, not the phase ladder: skip the rest of this step,
read the session context (**Step 3**), then go to **Step 4m**. At that tier, do
not map `project.stage` — nothing on the minimal path runs `/gate-check`, so
the stage reads Concept however far the
project has got, and walking the Concept phase would send a project that already
has stories back to the concept doc, art bible and systems map.
**首先，从上方配置块获取 `workflow`。** 如果它是 `minimal`，项目处于最小路径而非阶段阶梯：
跳过本步骤的其余部分，读取会话上下文（**步骤 3**），然后转到 **步骤 4m**。在该层级，不要
映射 `project.stage` — 最小路径上没有任何东西运行 `/gate-check`，因此
无论项目进展到哪里，阶段都读作 Concept，而走一遍 Concept 阶段会把一个已经有
故事的项目送回到概念文档、美术圣经和系统地图。

Otherwise, check in this order:
否则，按此顺序检查：

1. **Take `project.stage` from the config block above** — it is already resolved. Map its value to a catalog phase key:
   - "Concept" → `concept`
   - "Systems Design" → `systems-design`
   - "Technical Setup" → `technical-setup`
   - "Pre-Production" → `pre-production`
   - "Production" → `production`
   - "Polish" → `polish`
   - "Release" → `release`
1. **从上方配置块获取 `project.stage`** — 它已解析。将其值映射到目录阶段键：
   - "Concept" → `concept`
   - "Systems Design" → `systems-design`
   - "Technical Setup" → `technical-setup`
   - "Pre-Production" → `pre-production`
   - "Production" → `production`
   - "Polish" → `polish`
   - "Release" → `release`

2. **If neither is set**, infer phase from artifacts (most-advanced match wins):
   - code root has 10+ source files → `production`
   - `production/epics/**/story-*.md` exists → `pre-production`
   - `docs/architecture/adr-*.md` exists → `technical-setup`
   - `design/gdd/systems-index.md` exists → `systems-design`
   - `design/gdd/game-concept.md` (or `design/game-brief.md`) exists → `concept`
   - Nothing → `concept` (fresh project)
2. **如果两者都未设置**，则根据制品推断阶段（最靠后的匹配胜出）：
   - 代码根有 10 个以上源文件 → `production`
   - `production/epics/**/story-*.md` 存在 → `pre-production`
   - `docs/architecture/adr-*.md` 存在 → `technical-setup`
   - `design/gdd/systems-index.md` 存在 → `systems-design`
   - `design/gdd/game-concept.md`（或 `design/game-brief.md`）存在 → `concept`
   - 什么都没有 → `concept`（新项目）

3. **`workflow`** was taken at the top of this step (per
   `.claude/docs/workflow-modes.md`). It controls whether optional docs are
   surfaced as next steps (Step 5).
3. **`workflow`** 在本步骤开头获取（依据
   `.claude/docs/workflow-modes.md`）。它控制可选文档是否作为后续步骤呈现（步骤 5）。

---

## Step 3: Read Session Context
## 步骤 3：读取会话上下文

Read `production/session-state/active.md` if it exists — but only its STATUS
and CHECKPOINT blocks (schema: `.claude/docs/templates/session-state.md`); the
narrative below them can be long. Find the markers
(`Grep pattern="<!-- /?(STATUS|CHECKPOINT) -->" path="production/session-state/active.md" output_mode="content" -n`)
and `Read` from the first to the last. A file with no markers predates the schema: read its
last `## Session Extract` block instead. Extract:
如果 `production/session-state/active.md` 存在则读取 — 但只读其 STATUS
和 CHECKPOINT 块（模式：`.claude/docs/templates/session-state.md`）；其下的
叙述可能很长。找到标记
（`Grep pattern="<!-- /?(STATUS|CHECKPOINT) -->" path="production/session-state/active.md" output_mode="content" -n`）
并从第一个到最后一个执行 `Read`。没有任何标记的文件早于该模式：改为读取其
最后一个 `## Session Extract` 块。提取：
- What was most recently worked on
- Any in-progress tasks or open questions
- Current epic/feature/task from STATUS block (if present)
- 最近处理了什么
- 任何进行中的任务或未决问题
- STATUS 块中的当前史诗/功能/任务（若存在）

This tells you what the user just finished or is stuck on — use it to personalize
the output. It runs at every tier: at `minimal` it is the only read of the
checkpoint Step 4m relies on (a checkpoint saying "Next step: /story-done" means
the work is written). From here, `minimal` goes to **Step 4m**, not Step 4.
这告诉你用户刚完成了什么或卡在哪里 — 用它来个性化
输出。它在每个层级都会运行：在 `minimal` 下，它是步骤 4m 所依赖的检查点的
唯一读取（检查点写着 "Next step: /story-done" 意味着工作已写入）。从这里开始，`minimal` 转到 **步骤 4m**，而不是步骤 4。

---

## Step 4: Check Step Completion for the Current Phase
## 步骤 4：检查当前阶段各步骤的完成情况

For each step in the current phase (from the catalog):
对当前阶段中的每个步骤（来自目录）：

### Artifact-based checks
### 基于制品的检查

**Resolve these deterministically — one call, not a glob per step:**
**确定性地解析这些内容 — 一次调用，而不是每个步骤一次 glob：**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [current-phase]
```

Run it exactly as written, here and below: from the project root, with the
relative path — no absolute path, no `cd`, no `2>&1`. This skill's permission
grant matches that form; any other asks the user to approve it.
按原样运行它，此处及下文皆然：从项目根目录，使用
相对路径 — 不要绝对路径、不要 `cd`、不要 `2>&1`。此技能的权限
授予与这种形式匹配；任何其他形式都需要用户批准。

It evaluates every `glob`, `pattern`, `min_count` and `any_of` in the catalog
against the working tree and reports one line per step. Map its statuses:
它对照工作树评估目录中的每个 `glob`、`pattern`、`min_count` 和 `any_of`，
并为每个步骤报告一行。映射其状态：

| status | Report as |
|---|---|
| `PRESENT` | **Complete** |
| `ABSENT` | **Incomplete** |
| `SHORT` | **Incomplete** — say how far short (`count=`/`min=` are given) |
| `PATTERN_MISS` | **Incomplete** — the file exists but lacks its marker; say so, since "missing" would send the user to recreate a file they already have |
| `NO_CHECK` | **MANUAL** if the step carries a `note=`, else **UNKNOWN** — completion is not trackable (e.g. repeatable implementation work) |
| 状态 | 报告为 |
|---|---|
| `PRESENT` | **完成** |
| `ABSENT` | **未完成** |
| `SHORT` | **未完成** — 说明差多少（给出了 `count=`/`min=`） |
| `PATTERN_MISS` | **未完成** — 文件存在但缺少其标记；要说明这一点，因为 "missing" 会引导用户重新创建他们已有的文件 |
| `NO_CHECK` | 若该步骤带有 `note=` 则为 **人工**，否则为 **未知** — 完成情况不可跟踪（例如可重复的实现工作） |

Do not re-derive any of this with Glob/Grep. `any_of` in particular is a list of
**alternatives** — one match is enough — and hand-evaluating it risks a false
"incomplete": `engine-setup` is satisfied by `engine.name`
in `project.yaml` **or** by the legacy `Engine:` line in
`.claude/docs/technical-preferences.md`, and the script reports which alternative
matched (`alt=`/`match=`).
不要用 Glob/Grep 重新推导这些内容。尤其是 `any_of` 是一个
**备选**列表 — 一项匹配即足够 — 手工评估它会有虚假
"incomplete" 的风险：`engine-setup` 可由 `project.yaml` 中的 `engine.name`
满足，**或**由 `.claude/docs/technical-preferences.md` 中的旧版 `Engine:` 行
满足，脚本会报告匹配的是哪个备选
（`alt=`/`match=`）。

**`NO_CHECK` never means done.** The script prints a `NO_CHECK:` total before the
rows; if most of a phase is NO_CHECK, say that plainly rather than implying the
phase is nearly complete.
**`NO_CHECK` 从不意味着已完成。** 脚本会在各行之前打印 `NO_CHECK:` 总数；
如果某个阶段大部分都是 NO_CHECK，请直说，而不是暗示该阶段接近完成。

### Special case: production phase — read `sprint-status.yaml`
### 特例：制作阶段 — 读取 `sprint-status.yaml`

When the current phase is `production`, check for `production/sprint-status.yaml`
before doing any glob-based story checks. If it exists, read it directly:
当当前阶段为 `production` 时，在执行任何基于 glob 的故事检查之前，先检查 `production/sprint-status.yaml`。
如果它存在，直接读取：

- Stories with `status: in-progress` → surface as "currently active"
- Stories with `status: ready-for-dev` → surface as "next up"
- Stories with `status: done` → count as complete
- Stories with `status: blocked` → surface as blocker with the `blocker` field
- 状态为 `status: in-progress` 的故事 → 呈现为 "当前活跃"
- 状态为 `status: ready-for-dev` 的故事 → 呈现为 "下一个"
- 状态为 `status: done` 的故事 → 计为完成
- 状态为 `status: blocked` 的故事 → 连同 `blocker` 字段呈现为阻塞项

This gives precise per-story status without markdown scanning. Skip the glob
artifact check for the `implement` and `story-done` steps — the YAML is authoritative.
这样无需扫描 markdown 即可获得精确的逐故事状态。对 `implement` 和 `story-done` 步骤跳过 glob
制品检查 — YAML 是权威来源。

### Special case: `repeatable: true` (non-production)
### 特例：`repeatable: true`（非制作阶段）

For repeatable steps outside production (e.g. "System GDDs"), the artifact
check tells you whether *any* work has been done, not whether it's finished.
Label these differently — show what's been detected, then note it may be ongoing.
对于制作阶段之外的可重复步骤（例如 "System GDDs"），制品
检查告诉你*是否*做了任何工作，而不是是否已完成。
将这些标注得不同 — 显示已检测到的内容，然后注明它可能仍在进行中。

---

## Step 4m: The Minimal Path (`workflow: minimal` only)
## 步骤 4m：最小路径（仅 `workflow: minimal`）

At `minimal` the route is the catalog's `paths.minimal`, not a phase: engine →
`design/game-brief.md` → stories → `/dev-story` ↔ `/story-done`. Resolve it in
one call:
在 `minimal` 下，路线是目录的 `paths.minimal`，而不是某个阶段：引擎 →
`design/game-brief.md` → 故事 → `/dev-story` ↔ `/story-done`。通过一次调用解析：

```
Bash: bash .claude/scripts/artifact-check.sh --path minimal
```

Map the statuses exactly as in Step 4. `implement` and `story-done` are
`NO_CHECK` by design — the story status lines below are their check. The next
step is the first of these that applies:
完全按步骤 4 的方式映射状态。`implement` 和 `story-done` 按设计是
`NO_CHECK` — 下文的故事状态行就是它们的检查。下一步是其中第一个适用的：
1. `engine-setup` not PRESENT → `/setup-engine`
2. `game-brief` not PRESENT → `/reverse-document design [code root]` when the
   code root already holds the game (10 or more source files, the test Step 2
   uses for `production`): at `minimal` it writes `design/game-brief.md` from
   what is built. Otherwise `/brainstorm` (at `minimal` it writes the one-page
   brief), which on a built game would start a new idea.
3. `create-stories` not PRESENT → `/create-stories` with no argument (at
   `minimal` it builds the stories straight from the brief's MVP list)
4. Stories exist → the list below was printed by `.claude/scripts/story-status.sh`
   before you read this skill: one line per unfinished story, **already in
   the route's order** — `IN_REVIEW`, then `IN_PROGRESS`, then `TODO` (a
   `Ready` or `Not Started` story) in build order — then `BLOCKED`, `OTHER`,
   `NO_STATUS` and the `COMPLETE` count:
1. `engine-setup` 不为 PRESENT → `/setup-engine`
2. `game-brief` 不为 PRESENT → 当代码根已包含游戏（10 个以上源文件，即步骤 2
   用于判断 `production` 的测试）时，运行 `/reverse-document design [code root]`：
   在 `minimal` 下它会根据已构建的内容写入 `design/game-brief.md`。否则运行 `/brainstorm`（在 `minimal` 下它写入单页
   简报），但对于已构建的游戏，这会开启一个新想法。
3. `create-stories` 不为 PRESENT → 无参数运行 `/create-stories`（在
   `minimal` 下它直接从简报的 MVP 列表构建故事）
4. 故事已存在 → 下面的列表由 `.claude/scripts/story-status.sh` 在你读取此技能之前
   打印：每个未完成故事一行，**已按
   路线顺序排列** — `IN_REVIEW`，然后 `IN_PROGRESS`，然后按构建顺序的 `TODO`（
   `Ready` 或 `Not Started` 故事） — 然后是 `BLOCKED`、`OTHER`、
   `NO_STATUS` 以及 `COMPLETE` 计数：

!`bash "${CLAUDE_SKILL_DIR}/../../scripts/story-status.sh"`

   **Next up is the story on the first `IN_REVIEW`, `IN_PROGRESS` or `TODO`
   line.** The list is already current; do not run the script again, and do
   not re-read or re-rank the story files:
   an `In Review` story is closed before an `In Progress` one continues — its
   work is written, and `/story-done` is quick.
   - `IN_REVIEW` → its work is written and waiting to be closed:
     `/story-done [path]`
   - `IN_PROGRESS` → it is **not** done — whatever the code or commits
     suggest, only `/story-done` makes a story Complete. Recommend
     `/story-done [path]` only if the user, `active.md` or the git log says
     its implementation is written; otherwise `/dev-story [path]` to carry on
   - `TODO` → `/dev-story [path]`
   - a `BLOCKED` story → name it and its blocker; it is never Next up
   - **no `IN_REVIEW`, `IN_PROGRESS` or `TODO` line, but `BLOCKED`, `OTHER` or
     `NO_STATUS` lines remain** → nothing can be built next, and the build
     order is **not** done. Name each of those stories with its status as
     written, and a blocked story's blocker (read it from that story's file).
     Next up is clearing the first of them: resolve its blocker, or give an
     `OTHER` or `NO_STATUS` story a `Status:` line the route reads (`Ready`
     once it can be built)
   - **every story `Complete` (or `Done`)** → the brief's build order is done.
     Say so, and offer three ways on: play the build; add the next stories from
     the brief with `/create-stories`; or, if the game has outgrown a one-page
     brief, `/settings` to raise `modes.rigor`.
   **下一个是第一条 `IN_REVIEW`、`IN_PROGRESS` 或 `TODO`
   行上的故事。** 列表已是最新；不要再运行脚本，也不要
   重新读取或重新排序故事文件：
   `In Review` 故事会先于 `In Progress` 故事被继续 — 它的
   工作已写入，而 `/story-done` 很快。
   - `IN_REVIEW` → 其工作已写入，等待收尾：
     `/story-done [path]`
   - `IN_PROGRESS` → 它**没有**完成 — 无论代码或提交
     暗示什么，只有 `/story-done` 才能使故事完成。仅当用户、`active.md` 或 git 日志说明
     其实现已写入时，才建议 `/story-done [path]`；否则用 `/dev-story [path]` 继续
   - `TODO` → `/dev-story [path]`
   - `BLOCKED` 故事 → 点名它及其阻塞项；它永不是下一个
   - **没有 `IN_REVIEW`、`IN_PROGRESS` 或 `TODO` 行，但仍有 `BLOCKED`、`OTHER` 或
     `NO_STATUS` 行** → 接下来无法构建任何东西，且构建
     顺序**没有**完成。按原样点名每个故事及其状态，
     以及被阻塞故事的阻塞项（从该故事文件中读取）。
     下一个是清除其中第一个：解决其阻塞项，或为
     `OTHER` 或 `NO_STATUS` 故事添加路线会读取的 `Status:` 行（一旦可构建即为
     `Ready`）
   - **每个故事都 `Complete`（或 `Done`）** → 简报的构建顺序已完成。
     说明这一点，并提供三种继续方式：游玩构建；用
     `/create-stories` 从简报添加接下来的故事；或者，如果游戏已超出一页
     简报的规模，用 `/settings` 提高 `modes.rigor`。

**At `minimal`, never present any of these as required or as a blocker:** the
game concept doc, art bible, systems map, GDDs, `/create-epics`, a sprint plan,
`/gate-check`, or sprint close-out (`/smoke-check`, `/team-qa`,
`/retrospective`). The brief replaces the design docs and its build order
replaces the sprint plan (`.claude/docs/workflow-modes.md` — `minimal` floor).
Every one of them still runs if the user asks for it; mention one only when the
user's argument asks about it.
**在 `minimal` 下，绝不将以下任何内容呈现为必需或阻塞项：** 游戏概念文档、美术圣经、系统地图、GDD、`/create-epics`、冲刺计划、
`/gate-check`，或冲刺收尾（`/smoke-check`、`/team-qa`、
`/retrospective`）。简报替代设计文档，其构建顺序
替代冲刺计划（`.claude/docs/workflow-modes.md` — `minimal` 底线）。
如果用户要求，它们每一个仍会运行；仅在用户的参数问及时才提及。

Then skip Steps 5 and 8, and present with the `minimal` shape in Step 7.
然后跳过步骤 5 和 8，并以步骤 7 中的 `minimal` 形态呈现。

---

## Step 5: Find Position and Identify Next Steps
## 步骤 5：定位并确定后续步骤

From the completion data, determine:
根据完成数据，确定：

1. **Last confirmed complete step** — the furthest completed required step
2. **Current blocker** — the first incomplete *required* step (this is what the
   user must do next)
3. **Optional opportunities** — incomplete *optional* steps that can be done
   before or alongside the blocker. **Surface these per the workflow tier**: at
   `full`, list all of them; at `standard`, list an optional doc only if it is
   required for the current system/phase (do not flag genuinely-optional docs as
   gaps). At `minimal` this step does not run — Step 4m replaces it
4. **Upcoming required steps** — required steps after the current blocker
   (show as "coming up" so user can plan ahead)
1. **最后确认完成的步骤** — 最远的已完成必需步骤
2. **当前阻塞项** — 第一个未完成的*必需*步骤（这是用户
   接下来必须做的）
3. **可选机会** — 可以在阻塞项之前或与之同时完成的未完成*可选*步骤。
   **按工作流层级呈现这些内容**：在
   `full` 下，列出全部；在 `standard` 下，仅当可选文档是当前系统/阶段所需时才列出
   （不要把真正可选的文档标记为
   缺口）。在 `minimal` 下此步骤不运行 — 步骤 4m 替代它
4. **即将到来的必需步骤** — 当前阻塞项之后的必需步骤
   （显示为 "coming up"，以便用户提前规划）

If the user provided an argument (e.g. "just finished design-review"), use that
to advance past the step they named even if the artifact check is ambiguous.
如果用户提供了参数（例如 "just finished design-review"），即使制品检查模糊，
也用它来越过他们指名的步骤。

---

## Step 6: Check for In-Progress Work
## 步骤 6：检查进行中的工作

If `active.md` shows an active task or epic:
- Surface it prominently at the top: "It looks like you were working on [X]"
- Suggest continuing it or confirm if it's done
如果 `active.md` 显示有活跃任务或史诗：
- 在顶部显著呈现："It looks like you were working on [X]"
- 建议继续它，或确认它是否已完成

---

## Step 7: Present Output
## 步骤 7：呈现输出

Keep it **short and direct**. This is a quick orientation, not a report.
保持**简短直接**。这是快速定位，不是报告。

```
## Where You Are: [Phase Label]

**In progress:** [from active.md, if any]

### ✓ Done
- [completed step name]
- [completed step name]

### → Next up (REQUIRED)
**[Step name]** — [description]
Command: `[/command]`

### ~ Also available (OPTIONAL)
- **[Step name]** — [description] → `/command`
- **[Step name]** — [description] → `/command`

### Coming up after that
- [Next required step name] (`/command`)
- [Next required step name] (`/command`)

---
Approaching **[next phase]** gate → run `/gate-check` when ready.
```

**At `minimal`** use this shape instead — no phase label, no gate line. `N`
counts only stories whose status line says `Complete` or `Done`, and only those
go under ✓ Done. `N` and `M` are the two numbers on the `COMPLETE` line; it
names no finished story, so ✓ Done gives their count, not their titles:
**在 `minimal` 下**改用此形态 — 无阶段标签、无门禁行。`N`
只统计状态行为 `Complete` 或 `Done` 的故事，且只有这些
进入 ✓ Done。`N` 和 `M` 是 `COMPLETE` 行上的两个数字；它
不点名任何已完成故事，因此 ✓ Done 给出的是它们的数量而非标题：

```
## Where You Are: Minimal path — [N] of [M] stories complete

**In progress:** [from active.md, if any]

### ✓ Done
- Engine: [engine] · Game brief · [N] stories

### → Next up
**[Story NNN: title]** — [what it delivers]
Command: `/story-done [story-path]` for an In Review story, or an In Progress one whose work is written; otherwise `/dev-story [story-path]`

### Coming up after that
- [the next Ready stories in build order, at most 3]
```

**Formatting rules:**
- `✓` for confirmed complete
- `→` for the current required next step (only one — the first blocker)
- `~` for optional steps available now
- Show commands inline as backtick code
- If a step has no command (e.g. "Implement Stories"), explain what to do instead of showing a slash command
- For MANUAL steps, ask the user: "I can't tell if [step] is done — has it been completed?"
**格式规则：**
- `✓` 表示确认完成
- `→` 表示当前必需的下一步（只有一个 — 第一个阻塞项）
- `~` 表示现在可用的可选步骤
- 命令以内联反引号代码显示
- 如果某步骤没有命令（例如 "Implement Stories"），说明该做什么，而不是显示斜杠命令
- 对于人工步骤，询问用户："I can't tell if [step] is done — has it been completed?"

Verdict: **COMPLETE** — next steps identified.
裁决：**COMPLETE** — 已确定后续步骤。

---

## Step 8: Gate Warning (if close)
## 步骤 8：门禁警告（若接近）

Skip this step at `minimal` — the minimal path has no phase gates.
在 `minimal` 下跳过此步骤 — 最小路径没有阶段门禁。

After the current phase's steps, check if the user is likely approaching a gate:
在当前阶段的步骤之后，检查用户是否可能接近某个门禁：
- If all required steps in the current phase are complete (or nearly complete),
  add: "You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."
- If multiple required steps remain, skip the gate warning — it's not relevant yet.
- 如果当前阶段所有必需步骤都已完成（或接近完成），
  添加："You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."
- 如果还剩多个必需步骤，跳过门禁警告 — 它尚不相关。

---

## Step 9: Escalation Paths
## 步骤 9：升级路径

After the recommendations, if the user seems stuck or confused, add:
在建议之后，如果用户似乎卡住或困惑，添加：

```
---
Need more detail?
- `/project-stage-detect` — full gap analysis with all missing artifacts listed
- `/gate-check` — formal readiness check for your next phase
- `/start` — re-orient from scratch
- `/settings` — if the process feels mismatched to your project, adjust
  `modes.rigor`. Apply the change-triggers in
  `.claude/docs/settings-guidance.md § 4`: a **lower** tier when the user sounds
  overwhelmed by process (and rigor isn't already `minimal`), or a **higher** tier
  when the project has outgrown it (many systems, or in Production on
  `workflow: minimal`)
```

Only show this if the user's input suggested confusion (e.g. "I don't know", "stuck",
"lost", "not sure"). Don't show it for simple "what's next?" queries. Show the
`/settings` rigor line only when a `settings-guidance.md § 4` trigger actually
fires — the user sounds overwhelmed (and rigor isn't already `minimal`), or the
project has outgrown its tier — not on every confused query. At `minimal`, leave
out the `/gate-check` line: the minimal path has no phase gates (Step 4m).
仅在用户输入暗示困惑时显示（例如 "I don't know"、"stuck"、
"lost"、"not sure"）。不要为简单的 "what's next?" 查询显示它。仅当 `settings-guidance.md § 4` 触发条件实际
触发时才显示 `/settings` 精度行 — 用户听起来不堪重负（且精度还不是 `minimal`），或
项目已超出其层级 — 而不是在每个困惑查询时都显示。在 `minimal` 下，省略
`/gate-check` 行：最小路径没有阶段门禁（步骤 4m）。

---

## Collaborative Protocol
## 协作协议

- **Never auto-run the next skill.** Recommend it, let the user invoke it.
- **Ask about MANUAL steps** rather than assuming complete or incomplete.
- **Match the user's tone** — if they sound stressed ("I'm totally lost"), be
  reassuring and give one action, not a list of six.
- **One primary recommendation** — the user should leave knowing exactly one thing
  to do next. Optional steps and "coming up" are secondary context.
- **绝不自动运行下一个技能。** 推荐它，让用户自行调用。
- **询问人工步骤**，而不是假定完成或未完成。
- **匹配用户的语气** — 如果他们听起来有压力（"I'm totally lost"），要
  给予安抚并给出一个行动，而不是六项列表。
- **一个主要建议** — 用户离开时应确切知道接下来要做的一件事。
  可选步骤和 "coming up" 是次要上下文。
