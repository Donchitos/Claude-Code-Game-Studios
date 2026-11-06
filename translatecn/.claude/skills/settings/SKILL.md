---
name: settings
description: "View or change project config — effective merged values, or set locally in project.local.yaml."
argument-hint: "[key | key=value | --local key=value]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" resolve_setting *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" get_yaml_key *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" validate_yaml_enum *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" validate_enum_value *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" is_locally_overridable *), Bash(bash .claude/scripts/config-set.sh *), Bash(grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md), Bash(grep -E '^## ')
model: sonnet
---
---
name: settings
description: "查看或更改项目配置——生效的合并值，或在 project.local.yaml 中本地设置。"
argument-hint: "[key | key=value | --local key=value]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" resolve_setting *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" get_yaml_key *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" validate_yaml_enum *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" validate_enum_value *), Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" is_locally_overridable *), Bash(bash .claude/scripts/config-set.sh *), Bash(grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md), Bash(grep -E '^## ')
model: sonnet
---

# /settings — view or change project config
# /settings — 查看或更改项目配置

Manages `project.yaml` (team-wide config, committed) and `project.local.yaml`
(per-developer overrides, gitignored). Use this skill to inspect current
settings or change them without manually editing YAML.
管理 `project.yaml`（团队级配置，已提交）与 `project.local.yaml`（每位开发者的覆盖，已 gitignore）。使用本技能查看当前设置，或在不手动编辑 YAML 的情况下更改它们。

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). The approval gates in Phase 4 and
Phase 5 follow the pattern in `.claude/docs/automation-modes.md`. **Note**:
writing to `project.yaml` is a `schema_changes` decision (a default
`automation_always_ask` category), so `/settings` confirms config writes even
in `autonomous` mode unless the user has removed `schema_changes` from their
always-ask list.
**自动化模式**：解析 `modes.automation`（`project.local.yaml` → `project.yaml` → 默认 `collaborative`）。阶段 4 与阶段 5 的批准门禁遵循 `.claude/docs/automation-modes.md` 中的模式。**注意**：写入 `project.yaml` 属于 `schema_changes` 决策（默认的 `automation_always_ask` 类别），因此即便在 `autonomous` 模式下，只要用户没有从其始终询问列表中移除 `schema_changes`，`/settings` 都会确认配置写入。

## Phase 0: Parse Arguments
## 阶段 0：解析参数

Determine which of the four forms the user invoked:
确定用户调用的是四种形式中的哪一种：

| Form | Mode |
|------|------|
| `/settings` (no args) | **View-all** (Phase 2) |
| `/settings <key>` (single arg, no `=`) | **View-one** (Phase 3) |
| `/settings <key>=<value>` (single arg with `=`) | **Set-yaml** (Phase 4) |
| `/settings --local <key>=<value>` (`--local` prefix) | **Set-local** (Phase 5) |

| 形式 | 模式 |
|------|------|
| `/settings`（无参数） | **查看全部**（阶段 2） |
| `/settings <key>`（单参数，不含 `=`） | **查看单个**（阶段 3） |
| `/settings <key>=<value>`（含 `=` 的单参数） | **设置 YAML**（阶段 4） |
| `/settings --local <key>=<value>`（`--local` 前缀） | **本地设置**（阶段 5） |

For Set-yaml and Set-local, `<key>` is a dotted YAML path (e.g.
`modes.review_mode`, `testing.strict.logic`) and `<value>` is the new value.
对于“设置 YAML”和“本地设置”，`<key>` 是点分 YAML 路径（例如 `modes.review_mode`、`testing.strict.logic`），`<value>` 是新值。

**Empty-operand validation:** After splitting the `key=value` operand on
`=`, if either `<key>` or `<value>` is empty, this is malformed — route to
Phase 6 (usage) rather than attempting the write. The rule applies in both
Set-yaml and Set-local routing: for `--local`, strip the `--local` token
first, then check the remaining operand the same way (so `/settings --local =foo`
and `/settings --local key=` both go to Phase 6).
**空操作数校验：** 在按 `=` 拆分 `key=value` 操作数之后，如果 `<key>` 或 `<value>` 任一为空，这就是格式错误——路由到阶段 6（用法），而不是尝试写入。该规则同时适用于“设置 YAML”和“本地设置”的路由：对于 `--local`，先剥去 `--local` 标记，再以相同方式检查剩余操作数（因此 `/settings --local =foo` 和 `/settings --local key=` 都会进入阶段 6）。

Anything else that doesn't match the four forms above → Phase 6 (usage).
任何其他不匹配上述四种形式的内容 → 阶段 6（用法）。

## Phase 1: Load Helper
## 阶段 1：加载辅助脚本

All four subcommands need `yaml-helper.sh`. Run each helper call as its own
plain command:
四个子命令都需要 `yaml-helper.sh`。将每次辅助调用作为它自己的普通命令运行：

```bash
bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" <helper call>
```

`<helper call>` is the function each phase below names, for example
`resolve_setting modes.review_mode` or `validate_yaml_enum project.yaml`. The
helper moves to the project root itself, so those `project.yaml` and
`project.local.yaml` arguments resolve when the session was started in a
subfolder, and it keeps the function's exit status. `is_locally_overridable`
also prints its `0` or `1`. Run the call exactly as shown: do not `source` the
file, wrap it in `cd ... &&` or append `; echo $?`. This skill pre-approves the
plain form only, and a compound command asks the user every time.
`<helper call>` 是下方各阶段点名的函数，例如 `resolve_setting modes.review_mode` 或 `validate_yaml_enum project.yaml`。该辅助脚本会自行移动到项目根目录，因此当会话是从子文件夹启动时，那些 `project.yaml` 和 `project.local.yaml` 参数也能正确解析，并且它会保留函数的退出状态。`is_locally_overridable` 还会打印其 `0` 或 `1`。完全按所示运行调用：不要 `source` 该文件，不要用 `cd ... &&` 包裹它，也不要追加 `; echo $?`。本技能只预批准普通形式，而复合命令每次都会询问用户。

If `.claude/hooks/yaml-helper.sh` is missing, this is not a CCGS project.
Report the error and exit.
如果 `.claude/hooks/yaml-helper.sh` 缺失，这就不是 CCGS 项目。报告该错误并退出。

## Phase 1b: Reserved-setting detection
## 阶段 1b：保留设置检测

Some settings are fully documented and settable, and **no skill
or hook reads them** — setting one changes nothing. **This skill must say so.**
Returning an ordinary success lets a user reasonably believe the behaviour the
setting describes is now enforced — an accessibility tier being the case that
motivates this. (The key is not named here on purpose; see the note below.)
The banner exists only in
`.claude/docs/effects-map.md`, which someone
configuring their project will never open. A setting that does nothing must never look
exactly like one that works — `.claude/rules/skill-authoring.md` obligation 3.
有些设置文档齐全且可设置，但**没有任何技能或钩子读取它们**——设置其中一个不会改变任何东西。**本技能必须说明这一点。** 返回一个普通的成功会使用户合理地相信该设置所描述的行为现已生效——无障碍层级就是促成这一点的案例。（此处有意不点名该键；见下方注释。）该横幅只存在于 `.claude/docs/effects-map.md` 中，而配置自己项目的人永远不会打开它。一个什么都不做的设置，绝不能看起来和一个能用的设置一模一样——`.claude/rules/skill-authoring.md` 义务 3。

Derive the set; do not hardcode it (obligation 5):
推导该集合；不要硬编码它（义务 5）：

```bash
grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md | grep -E '^## '
```

**Match the banner HEADING (`> ### RESERVED`), never the bare word "RESERVED".**
`platform.cert_tier`'s section *mentions* the banner in prose, to record that it
carried one and later became a live setting. A looser match re-reports a working
setting as dead — the direction that understates what the framework does, and
why the dead-settings gate asserts both directions.
**匹配横幅的标题（`> ### RESERVED`），绝不匹配裸词“RESERVED”。** `platform.cert_tier` 的章节在散文中*提及*该横幅，以记录它曾带有横幅、后来成了生效设置。更宽松的匹配会把一个可用的设置重新报告为已死——这种方向会低估框架的功能，也正是死设置门禁要双向断言的原因。

A heading may name **two keys joined by " and "** — split on that separator so
both are captured, or the second one silently escapes the set. Let
`RESERVED_SET` be the result.
一个标题可能点名**由“ and ”连接的两个键**——按该分隔符拆分，以便两者都被捕获，否则第二个会悄无声息地逃出该集合。令 `RESERVED_SET` 为该结果。

> Deliberately phrased without naming those keys. The dead-settings gate asserts
> that a setting on the allowlist has **no** readers, and it counts any skill
> file that spells the key. Naming them here to illustrate the split would make
> `/settings` register as a reader of two settings nothing reads, and the gate
> would fail — correctly. Spelling a dead path out while explaining why not to
> use it trips the same wire. Reword instead of adding an exemption: the
> strictness is the point, so do not re-introduce the literal names to make an
> example clearer.
> 有意不点名那些键来表述。死设置门禁断言白名单上的某个设置**没有**读者，并统计任何拼写出该键的技能文件。在此点名它们以说明拆分方式，会使 `/settings` 被登记为两个无人读取的设置的读者，门禁就会失败——而且是正确地失败。在解释为何不要使用某个已死路径时把它拼写出来，会触发同一根线。改写措辞，而不是添加豁免：严格性正是重点，所以不要为了让一个示例更清楚而重新引入字面名称。

Never refuse a write to a reserved key. Storing the value a user intends is
legitimate; storing it *silently* is the defect.
绝不要拒绝对保留键的写入。存储用户意图的值是正当的；*静默地*存储才是缺陷。

## Phase 2: View-all Mode
## 阶段 2：查看全部模式

(when no arguments)
（无参数时）

1. Confirm `project.yaml` exists. If missing, report:
   > "No `project.yaml` found — run `/start` to create one."
   And exit.

2. Check if `project.local.yaml` exists.

3. Run `validate_yaml_enum project.yaml` and capture any errors.
   If `project.local.yaml` exists, also run `validate_yaml_enum project.local.yaml`.
   Tag each error with its source file so the user can tell them apart.

4. **Enumerate leaves.** Use the `Read` tool to read both YAML files as
   text. Walk through each file's structure and collect every leaf key
   into a deduplicated list of dotted paths. A leaf is a `key: value`
   line whose value is non-empty (a scalar or inline-array) — NOT a
   parent block that introduces a nested map. Maintain insertion order
   per file; merge by appending leaves from `project.local.yaml` that
   aren't already present from `project.yaml`. The resulting list is
   the set of leaves to display.

   **Then append the rigor family** — `modes.rigor`, `modes.workflow`,
   `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`,
   `team.size` — for any of the seven the merged list does not already
   contain. These are normally leaves of neither file: `modes.rigor` has a
   terminal default and the other six are supplied by the rigor expansion
   (`modes.review_mode` and `team.size` may also appear as file leaves when set
   locally, but must still be appended so their *derived* value shows). Enumerating
   only file leaves would hide exactly the settings a user just chose, in the one
   view meant to show them.

5. **For each leaf**, perform three reads and one check:
   - `resolve_setting <path>` → `<value>`, TAB, `<source>`. This walks the
     whole chain (`project.local.yaml` → `project.yaml` → legacy file →
     `rigor` expansion → default), so it is the only read that can report
     a derived value or name what supplied it.
   - `get_yaml_key project.yaml <path>` → yaml-only value (needed only to
     show what a local override is shadowing)
   - `is_locally_overridable <path>` → 0 (overridable) or 1 (locked)

   Compute the **source annotation** from `<source>`:

   | `<source>` | Annotation |
   |---|---|
   | `project.local.yaml`, yaml-only value non-empty | `(LOCAL OVERRIDE — yaml has: <yamlvalue>)` |
   | `project.local.yaml`, yaml-only value empty | `(project.local.yaml)` |
   | `project.yaml` | `(project.yaml)` |
   | a legacy file path (e.g. `production/review-mode.txt`) | `(<path>, legacy)` |
   | `rigor:<level>` | `(derived from rigor: <level>)` |
   | `default` | `(default)` |
   | `unset` | skip the leaf (don't print unset keys) |

   Append `, locked` to the annotation when `is_locally_overridable`
   returned 1.

   **Append `, reserved` when the leaf is in `RESERVED_SET` (Phase 1b)**, and
   print this line with the legend below the block:

   ```
   reserved = stored, but nothing reads it. Setting it changes
   no behaviour today.
   ```

   > **All four phases must carry the reserved marking — view-one, view-all,
   > and both write paths.** Marking view-one and the writes while leaving
   > view-all — **the most-used form of this skill** — unmarked means a user who
   > set a reserved key sees it listed beside working settings with an ordinary
   > `(project.yaml)` annotation, in the view most people actually run. Guard
   > all four: view-one and view-all are twins in exactly the way the two write
   > paths are.

6. **Print**, grouped by top-level section (`framework`, `modes`,
   `engine`, etc.) in the order leaves first appeared. The grouping is
   determined by the dotted path, not by which file the leaf came from
   — e.g. `modes.automation` groups under `modes:` even if only
   `project.local.yaml` defines it. Within each section, indent leaves
   by 2 spaces; nest further for sub-blocks (e.g. `testing.strict.*`).
   Example output:

```
project.yaml: present
project.local.yaml: present

Schema validation: ok

Effective config:

framework:
  version: 1.2.0            (project.yaml, locked)

modes:
  review_mode: lean         (project.yaml)
  automation: autonomous    (LOCAL OVERRIDE — yaml has: collaborative)
  rigor: full               (project.yaml, locked)
  workflow: full            (derived from rigor: full, locked)
  story_granularity: fine   (derived from rigor: full, locked)

docs:
  density: terse            (project.yaml, locked)

qa:
  level: full               (derived from rigor: full, locked)

engine:
  name: Godot               (project.yaml, locked)
  version: 4.7              (project.yaml, locked)

testing:
  strict:
    logic: false            (LOCAL OVERRIDE — yaml has: true)
    integration: true       (project.yaml)

locked = cannot be overridden in project.local.yaml (project-wide setting).
It does NOT mean fixed: a derived value can still be set explicitly with
/settings <key>=<value>, and an explicit value wins over rigor.
```

Print that two-line legend after the config block whenever any rendered
line carries `locked`. Without it users read `locked` as "immutable" and
conclude a rigor-derived knob cannot be changed — the opposite of what
Phase 3's view-one tells them for the same knob ("an explicit value wins
over rigor"). The two views must not leave contradictory impressions of
the same knob's mutability.
每当渲染出的任何一行带有 `locked` 时，就在配置块之后打印那两行图例。没有它，用户会把 `locked` 读作“不可变”，并断定一个由严谨度推导出的旋钮无法更改——这与阶段 3 的“查看单个”对同一个旋钮所告知的内容（“显式值优先于严谨度”）正好相反。这两种视图绝不能在同一个旋钮的可变性上留下相互矛盾的印象。

The `docs.density` line above is the precedence rule made visible: an
explicit `project.yaml` value keeps winning over the level `rigor` would
otherwise derive, so "comprehensive but compact" stays expressible.
上方 `docs.density` 一行就是优先级规则的可见化：显式的 `project.yaml` 值始终优先于 `rigor` 原本会推导出的层级，因此“全面但紧凑”始终可表达。

If schema errors exist, print them in this form before the effective
config block:
如果存在模式错误，在生效配置块之前以这种形式打印它们：

```
Schema validation: ERRORS
  [project.yaml] modes.review_mode: 'chaotic' is not a valid value (expected: full|lean|solo)
  [project.local.yaml] engine.name: 'Pygame' is not a valid value (expected: Godot|Unity|Unreal)
```

## Phase 3: View-one Mode
## 阶段 3：查看单个模式

(when single arg, no `=`)
（单参数、不含 `=` 时）

**If `<key>` is in `RESERVED_SET`, print this BEFORE the value block** — above,
not below. A caveat under a value reads as a footnote on a working setting:
**如果 `<key>` 在 `RESERVED_SET` 中，就在值块之前打印这条**——在上面，而不是下面。值下面的警示读起来像对一个可用设置的脚注：

> **`<key>` is RESERVED — nothing reads it.** The value below is stored; it
> changes no behaviour today.
> **`<key>` 是保留的——没有东西读取它。** 下方存储的值；它今天不会改变任何行为。

Let `<key>` be the argument. Perform four reads:
令 `<key>` 为参数。执行四次读取：

1. `resolve_setting <key>` → `<value>`, TAB, `<source>` (effective value + provenance)
2. `get_yaml_key project.yaml <key>` → yaml-only value
3. `get_yaml_key project.local.yaml <key>` → local-only value (skip if file absent)
4. `is_locally_overridable <key>` → 0 (overridable) or 1 (locked)
1. `resolve_setting <key>` → `<value>`、TAB、`<source>`（生效值 + 来源）
2. `get_yaml_key project.yaml <key>` → 仅 YAML 的值
3. `get_yaml_key project.local.yaml <key>` → 仅本地值（文件不存在则跳过）
4. `is_locally_overridable <key>` → 0（可覆盖）或 1（锁定）

Determine the **source** from `<source>` (same table as Phase 2 step 5)
and the **Locally overridden** status:
- `yes` if the local-only value is non-empty
- `no` otherwise
从 `<source>` 确定**来源**（与阶段 2 第 5 步相同的表）以及**本地是否覆盖**状态：
- 若仅本地值非空则为 `yes`
- 否则为 `no`

Print:
打印：

```
<key>

  Effective value: <effective-value or "(not set)" if <source> is unset>
  Source: <project.yaml | project.local.yaml | project.local.yaml (overrides project.yaml) | derived from rigor: <level> | default>
  Locally overridden: <yes | no>
  Whitelist: <"can be locally overridden" if is_locally_overridable returned 0, else "locked — project-wide">
```

When both files set the key (the LOCAL OVERRIDE case), add two more
lines under Source:
当两个文件都设置了该键时（LOCAL OVERRIDE 情形），在 Source 下再添加两行：

```
  project.yaml value: <yamlvalue>
  project.local.yaml value: <localvalue>
```

When `<source>` is `rigor:<level>`, add one line under Source so the user
knows the value is settable and how:
当 `<source>` 为 `rigor:<level>` 时，在 Source 下添加一行，让用户知道该值可设置以及如何设置：

```
  Set explicitly with: /settings <key>=<value>   (an explicit value wins over rigor)
```

When the effective value is empty (key not set anywhere), print just:
当生效值为空（该键在任何地方都未设置）时，只打印：

```
<key>

  Effective value: (not set)
  Locally overridden: no
  Whitelist: <"can be locally overridden" | "locked — project-wide">
```

## Phase 4: Set-yaml Mode
## 阶段 4：设置 YAML 模式

(when `<key>=<value>`, no `--local`)
（当 `<key>=<value>`、不含 `--local` 时）

1. **Schema validation**: call `validate_enum_value <key> <value>`. If
   it returns 1, the stderr line is shown to the user verbatim
   (`Invalid value '<value>' for '<key>'. Allowed: ...`) and the skill
   exits without writing. If it returns 0, the value is either valid
   or the key has no enum constraint — proceed.

1b. **Known-key check**: run, from the project root as in Phase 1,
   `bash .claude/scripts/config-set.sh <key> <value> --dry-run` and read its
   `known` row. If it says `yes`, proceed. If it says `no`, nothing in CCGS reads
   that key, so writing it changes nothing; it is most often a typo. Do not
   write yet: say so, and ask via `AskUserQuestion` with the options
   `Use <nearest> instead` (only when the row ends `nearest: <key>`),
   `Write <key> anyway`, `Cancel`. Continue only on an explicit choice; with
   `Use <nearest> instead`, start this phase again with that key. A skipped or
   empty answer cancels.

2. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print
   BEFORE the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Then continue to the approval gate as normal. Phase 5 carries the identical
   warning. Warning on one write path and not the other leaves a silent route
   to the same outcome, which is the whole failure this guards against.

3. **Shadow warning**: read `get_yaml_key project.local.yaml <key>`. If
   it returns a non-empty value, print BEFORE the approval prompt:
   > "Note: this setting is currently locally overridden in `project.local.yaml` (value: `<localvalue>`). Writing to `project.yaml` will not change your effective value."

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``Set `<key>=<value>` in `project.yaml`?``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write** using the `Edit` tool. The edit strategy depends on what
   already exists in `project.yaml`:

   **Case A — key exists**: Read `project.yaml`. Locate the line
   `<lastsegment>: <oldvalue>` and the line immediately above it that
   introduces its parent block (e.g. `modes:` for `modes.review_mode`).
   Construct the `Edit` with `old_string` that includes the parent
   block line PLUS the leaf line, so the match is unique even if
   `<lastsegment>: <oldvalue>` appears elsewhere. Example for
   `modes.review_mode=full`:
   ```
   old_string:
     modes:
       review_mode: lean
   new_string:
     modes:
       review_mode: full
   ```

   **Case B — parent block exists, leaf doesn't**: Find the last line
   of the parent block. Use `Edit` to append the new leaf line at the
   correct indentation, using the last existing leaf as the `old_string`
   anchor.

   **Case C — parent block doesn't exist**: Append a new top-level
   block at end-of-file (deterministic — always end-of-file, never
   between blocks). Use `Edit` with the last non-empty line of the
   file as `old_string` and append the new block after it.

   **Case D — file structure is unusual** (commented-out keys with the
   same name, ambiguous nesting, malformed YAML): STOP and ask via
   `AskUserQuestion`:
   > "Couldn't find a clean insertion point for `<key>` in `project.yaml`. Show me what to do."

6. Confirm: ``Set `<key>=<value>` in `project.yaml`.``

   **When `<key>` is `modes.rigor`**, the write also moves six other
   knobs, so print what they resolve to now — re-read each with
   `resolve_setting` rather than reciting the expansion table, since any
   of them may carry an explicit value that still wins:

   ```
   Set modes.rigor=full in project.yaml. It now supplies:
     modes.workflow: full            (derived from rigor: full)
     docs.density: terse             (project.yaml — explicit, unchanged)
     qa.level: full                  (derived from rigor: full)
     modes.story_granularity: fine   (derived from rigor: full)
     modes.review_mode: full         (derived from rigor: full)
     team.size: studio               (derived from rigor: full)
   ```
1. **模式校验**：调用 `validate_enum_value <key> <value>`。如果返回 1，将 stderr 行原样展示给用户（`Invalid value '<value>' for '<key>'. Allowed: ...`），技能退出而不写入。如果返回 0，该值要么有效，要么该键没有枚举约束——继续。

1b. **已知键检查**：如阶段 1 所述从项目根目录运行 `bash .claude/scripts/config-set.sh <key> <value> --dry-run`，并读取其 `known` 行。若为 `yes`，继续。若为 `no`，CCGS 中没有任何东西读取该键，因此写入它不会改变任何东西；这通常是拼写错误。先不要写入：说明这一点，并通过 `AskUserQuestion` 询问，选项为 `Use <nearest> instead`（仅当该行以 `nearest: <key>` 结尾时）、`Write <key> anyway`、`Cancel`。只在明确选择后继续；选择 `Use <nearest> instead` 时，用那个键重新开始本阶段。被跳过或空白的回答即取消。

2. **保留警告**：如果 `<key>` 在 `RESERVED_SET` 中（阶段 1b），在批准提示之前打印：
   > “注意：`<key>` 是保留的——没有技能或钩子读取它，所以设置它不会改变任何行为。无论哪种方式，你的值都会被存储。”

   然后照常继续到批准门禁。阶段 5 带有完全相同的警告。在一条写入路径上警告而另一条不警告，就会给相同结果留下一条静默路径，而这正是此处要防范的整个失败。

3. **遮蔽警告**：读取 `get_yaml_key project.local.yaml <key>`。如果它返回非空值，在批准提示之前打印：
   > “注意：此设置当前在 `project.local.yaml` 中被本地覆盖（值：`<localvalue>`）。写入 `project.yaml` 不会改变你的生效值。”

4. **批准门禁**：使用 `AskUserQuestion`：
   - 提示：``Set `<key>=<value>` in `project.yaml`?``
   - 选项：`[A] Yes, write` / `[B] No, cancel`

5. **写入**，使用 `Edit` 工具。编辑策略取决于 `project.yaml` 中已存在的内容：

   **情形 A——键已存在**：读取 `project.yaml`。定位行 `<lastsegment>: <oldvalue>` 以及它正上方引入其父块的那一行（例如 `modes.review_mode` 的 `modes:`）。构造 `Edit`，`old_string` 包含父块行**加上**叶行，这样即便 `<lastsegment>: <oldvalue>` 出现在别处，匹配也是唯一的。`modes.review_mode=full` 的示例：
   ```
   old_string:
     modes:
       review_mode: lean
   new_string:
     modes:
       review_mode: full
   ```

   **情形 B——父块存在，叶不存在**：找到父块的最后一行。使用 `Edit` 以正确缩进追加新的叶行，并用最后现有的叶作为 `old_string` 锚点。

   **情形 C——父块不存在**：在文件末尾追加一个新的顶层块（确定性——始终在文件末尾，绝不在块之间）。使用 `Edit`，以文件的最后一个非空行作为 `old_string`，并在其后追加新块。

   **情形 D——文件结构异常**（同名的注释掉的键、嵌套有歧义、YAML 格式错误）：停止，并通过 `AskUserQuestion` 询问：
   > “无法在 `project.yaml` 中为 `<key>` 找到干净的插入点。告诉我该怎么做。”

6. 确认：``Set `<key>=<value>` in `project.yaml`.``

   **当 `<key>` 为 `modes.rigor` 时**，该写入还会带动另外六个旋钮，因此打印它们现在解析出的结果——用 `resolve_setting` 逐一重新读取，而不是照念扩展表，因为它们中任何一个都可能带有仍然优先的显式值：

   ```
   Set modes.rigor=full in project.yaml. It now supplies:
     modes.workflow: full            (derived from rigor: full)
     docs.density: terse             (project.yaml — explicit, unchanged)
     qa.level: full                  (derived from rigor: full)
     modes.story_granularity: fine   (derived from rigor: full)
     modes.review_mode: full         (derived from rigor: full)
     team.size: studio               (derived from rigor: full)
   ```

## Phase 5: Set-local Mode
## 阶段 5：本地设置模式

(when `--local <key>=<value>`)
（当 `--local <key>=<value>` 时）

1. **Whitelist check**: call `is_locally_overridable <key>`.
   - If it returns 1 (locked), print one line:
     > ``<key> cannot be locally overridden — it's a project-wide setting. Use `/settings <key>=<value>` (no `--local`) to change it for the whole team.``
   - Exit without writing.

2. **Schema validation**: call `validate_enum_value <key> <value>`. If
   it returns 1, show the stderr message verbatim and exit without
   writing.

2a. **Known-key check**: as in Phase 4 step 1b, with `--local` before
   `<key>`: if the `known` row says `no`, ask before writing, offering the `nearest:` key
   when the row names one.

2b. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print
   BEFORE the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Identical to Phase 4 step 2, and deliberately so. Both write paths reach the
   same file-of-record for a user's intent; warning on one only would leave
   `--local` as the silent route.

3. **Base check**: if `project.yaml` doesn't exist:
   > "Cannot create `project.local.yaml` — `project.yaml` is missing. Run `/start` to create one first."
   Exit. (Local overrides require a base, per spec.)

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``Set `<key>=<value>` in `project.local.yaml` (your personal override, gitignored)?``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write**:
   - If `project.local.yaml` doesn't exist, use `Write` to create it
     with the new setting wrapped in its parent block(s). Minimal
     example for `--local modes.automation=autonomous`:
     ```yaml
     # project.local.yaml — per-developer overrides (gitignored)
     modes:
       automation: autonomous
     ```
   - If it exists, use `Edit` with the same Case A/B/C strategy from
     Phase 4 step 4.

6. Confirm: ``Set `<key>=<value>` in `project.local.yaml` (your override).``
1. **白名单检查**：调用 `is_locally_overridable <key>`。
   - 若返回 1（锁定），打印一行：
     > ``<key> cannot be locally overridden — it's a project-wide setting. Use `/settings <key>=<value>` (no `--local`) to change it for the whole team.``
   - 退出而不写入。

2. **模式校验**：调用 `validate_enum_value <key> <value>`。如果返回 1，原样展示 stderr 消息并退出而不写入。

2a. **已知键检查**：与阶段 4 第 1b 步相同，在 `<key>` 之前带 `--local`：如果 `known` 行为 `no`，在写入前询问，并在该行点名时提供 `nearest:` 键。

2b. **保留警告**：如果 `<key>` 在 `RESERVED_SET` 中（阶段 1b），在批准提示之前打印：
   > “注意：`<key>` 是保留的——没有技能或钩子读取它，所以设置它不会改变任何行为。无论哪种方式，你的值都会被存储。”

   与阶段 4 第 2 步完全相同，且是有意如此。两条写入路径都会到达用户意图的同一记录文件；只在一条上警告会让 `--local` 成为静默路径。

3. **基础检查**：如果 `project.yaml` 不存在：
   > “无法创建 `project.local.yaml`——`project.yaml` 缺失。先运行 `/start` 创建一个。”
   退出。（按规范，本地覆盖需要一个基础。）

4. **批准门禁**：使用 `AskUserQuestion`：
   - 提示：``Set `<key>=<value>` in `project.local.yaml` (your personal override, gitignored)?``
   - 选项：`[A] Yes, write` / `[B] No, cancel`

5. **写入**：
   - 如果 `project.local.yaml` 不存在，使用 `Write` 创建它，将新设置包裹在其父块中。`--local modes.automation=autonomous` 的最小示例：
     ```yaml
     # project.local.yaml — per-developer overrides (gitignored)
     modes:
       automation: autonomous
     ```
   - 如果它已存在，使用 `Edit`，采用与阶段 4 第 4 步相同的 A/B/C 策略。

6. 确认：``Set `<key>=<value>` in `project.local.yaml` (your override).``

## Phase 6: Usage
## 阶段 6：用法

When the argument doesn't match any of the four valid forms (or has
empty operands), print:
当参数不匹配任何四种有效形式（或含有空操作数）时，打印：

```
Usage:
  /settings                          — view all effective config
  /settings <key>                    — view a single setting
  /settings <key>=<value>            — change a setting (project.yaml)
  /settings --local <key>=<value>    — change a setting locally
                                       (project.local.yaml, gitignored)

Examples:
  /settings modes.review_mode
  /settings modes.review_mode=full
  /settings --local modes.automation=autonomous
```

## Notes
## 说明

- All YAML writes go through `Edit` (existing keys/blocks) or `Write`
  (new files). The skill does not depend on `yq` or any external YAML library.
- The whitelist is enforced in `yaml-helper.sh`
  (`is_locally_overridable` function). To extend it, edit the
  `_yaml_helper_locally_overridable` constant — do not duplicate the list here.
- **Derived values are not stored anywhere.** `modes.workflow`, `docs.density`,
  `qa.level`, `modes.story_granularity`, `modes.review_mode` and `team.size` have no
  terminal default; when no file sets them their value comes from the `modes.rigor`
  expansion in `yaml-helper.sh`
  (`_yaml_helper_rigor_expansion`). Report them via `resolve_setting` — a
  `get_yaml_key` read returns empty and would render them "(not set)" while every
  skill is in fact acting on a real value.
- The schema-validation enum constants are in `yaml-helper.sh`
  (`_yaml_helper_enums`). `validate_enum_value` is the single-key
  validator for pending writes; `validate_yaml_enum` validates whole
  files (used by `session-start.sh`).
- `project.local.yaml` is gitignored. These
  overrides never propagate to teammates.
- For **which value to choose** for a given game type or situation — and when to
  suggest changing one — see `.claude/docs/settings-guidance.md` (advisory presets
  + change triggers). `effects-map.md` says what each setting does; that doc says
  which to pick.
- 所有 YAML 写入都通过 `Edit`（现有键/块）或 `Write`（新文件）进行。本技能不依赖 `yq` 或任何外部 YAML 库。
- 白名单在 `yaml-helper.sh` 中强制执行（`is_locally_overridable` 函数）。要扩展它，请编辑 `_yaml_helper_locally_overridable` 常量——不要在此处复制该列表。
- **派生值不存储在任何地方。** `modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity`、`modes.review_mode` 和 `team.size` 没有终极默认值；当没有文件设置它们时，其值来自 `yaml-helper.sh` 中的 `modes.rigor` 扩展（`_yaml_helper_rigor_expansion`）。通过 `resolve_setting` 上报它们——`get_yaml_key` 读取会返回空，并会把它们渲染为“(not set)”，而实际上每个技能都在依据一个真实值行事。
- 模式校验的枚举常量在 `yaml-helper.sh` 中（`_yaml_helper_enums`）。`validate_enum_value` 是针对待写入的单键校验器；`validate_yaml_enum` 校验整个文件（由 `session-start.sh` 使用）。
- `project.local.yaml` 已 gitignore。这些覆盖永远不会传播给队友。
- 关于在给定的游戏类型或情境下**该选哪个值**——以及何时建议更改某个值——参见 `.claude/docs/settings-guidance.md`（建议性预设 + 更改触发条件）。`effects-map.md` 说明每个设置做什么；那份文档说明该选哪个。
