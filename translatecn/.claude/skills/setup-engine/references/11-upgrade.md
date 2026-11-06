# /setup-engine — Section 11: Upgrade Subcommand

# /setup-engine — 第 11 节：升级子命令

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 11. Upgrade Subcommand

**In this file:**

- Step 1 — Read Current Version State
- Step 2 — Fetch Migration Guide
- Step 3 — Pre-Upgrade Audit
- Step 4 — Confirm Before Updating
- Step 5 — Update VERSION.md
- Step 6 — Post-Upgrade Reminder

If invoked as `/setup-engine upgrade [old-version] [new-version]`:

## 11. 升级子命令

**本文件内容：**

- 步骤 1 —— 读取当前版本状态
- 步骤 2 —— 抓取迁移指南
- 步骤 3 —— 升级前审计
- 步骤 4 —— 更新前确认
- 步骤 5 —— 更新 VERSION.md
- 步骤 6 —— 升级后提醒

如果以 `/setup-engine upgrade [old-version] [new-version]` 调用：

### Step 1 — Read Current Version State

Read `docs/engine-reference/<engine>/VERSION.md` to confirm the current pinned
version, risk level, and any migration note URLs already recorded. If
`old-version` was not provided as an argument, use the pinned version from this
file.

### 步骤 1 —— 读取当前版本状态

读取 `docs/engine-reference/<engine>/VERSION.md`，确认当前固定的
版本、风险等级，以及已记录的任何迁移说明 URL。如果
未将 `old-version` 作为参数提供，则使用此
文件中固定的版本。

### Step 2 — Fetch Migration Guide

Use WebSearch and WebFetch to locate the official migration guide between
`old-version` and `new-version`:

- Search: `"[engine] [old-version] to [new-version] migration guide"`
- Search: `"[engine] [new-version] breaking changes changelog"`
- Fetch the migration guide URL from VERSION.md if one is already recorded,
  or use the URL found via search.

Extract: renamed APIs, removed APIs, changed defaults, behavior changes, and
any "must migrate" items.

### 步骤 2 —— 抓取迁移指南

使用 WebSearch 和 WebFetch 定位 `old-version` 与 `new-version` 之间的
官方迁移指南：

- 搜索：`"[engine] [old-version] to [new-version] migration guide"`
- 搜索：`"[engine] [new-version] breaking changes changelog"`
- 如果 VERSION.md 中已记录迁移指南 URL，则抓取它，
  或使用通过搜索找到的 URL。

提取：重命名的 API、移除的 API、更改的默认值、行为变更，以及
任何"必须迁移"的项目。

### Step 3 — Pre-Upgrade Audit

Scan the **code root** (resolve per `.claude/docs/code-root-resolution.md`) for code that uses APIs known to be deprecated or changed in the
target version:

- Use Grep to search for deprecated API names extracted from the migration
  guide (e.g., old function names, removed node types, changed property names)
- List each file that matches, with the specific API reference found

### 步骤 3 —— 升级前审计

扫描**代码根目录**（按 `.claude/docs/code-root-resolution.md` 解析），查找使用了
已知在目标版本中弃用或更改的 API 的代码：

- 使用 Grep 搜索从迁移指南中提取的弃用 API 名称
  （例如旧函数名、被移除的节点类型、更改的属性名）
- 列出每个匹配的文件，以及所发现的特定 API 引用

Present the audit results as a table:

```
Pre-Upgrade Audit: [engine] [old-version] → [new-version]
==========================================================

Files requiring changes:
  File                              | Deprecated API Found       | Effort
  --------------------------------- | -------------------------- | ------
  src/gameplay/player_movement.gd   | old_api_name               | Low
  src/ui/hud.gd                     | removed_node_type          | Medium

Breaking changes to watch for:
  - [change description from migration guide]
  - [change description from migration guide]

Recommended migration order (dependency-sorted):
  1. [system/layer with fewest dependencies first]
  2. [next system]
  ...
```

以表格形式呈现审计结果：

```
Pre-Upgrade Audit: [engine] [old-version] → [new-version]
==========================================================

Files requiring changes:
  File                              | Deprecated API Found       | Effort
  --------------------------------- | -------------------------- | ------
  src/gameplay/player_movement.gd   | old_api_name               | Low
  src/ui/hud.gd                     | removed_node_type          | Medium

Breaking changes to watch for:
  - [change description from migration guide]
  - [change description from migration guide]

Recommended migration order (dependency-sorted):
  1. [system/layer with fewest dependencies first]
  2. [next system]
  ...
```

If no deprecated APIs are found in the code root, report: "No deprecated API usage
found in the code root — upgrade may be low-risk."

如果在代码根目录中未发现弃用的 API，报告："No deprecated API usage
found in the code root — upgrade may be low-risk."

### Step 4 — Confirm Before Updating

Ask the user before making any changes:

> "Pre-upgrade audit complete. Found [N] files using deprecated APIs.
> Proceed with upgrading VERSION.md to [new-version]?
> (This will update the pinned version and add migration notes — it does NOT
> change any source files. Source migration is done manually or via stories.)"

Wait for explicit confirmation before continuing.

### 步骤 4 —— 更新前确认

在做任何更改之前询问用户：

> "升级前审计完成。发现 [N] 个文件使用了弃用的 API。
> 是否继续将 VERSION.md 升级到 [new-version]？
> （这会更新固定的版本并添加迁移说明 —— 它**不会**
> 更改任何源文件。源迁移需手动完成或通过故事完成。）"

在继续之前等待明确确认。

### Step 5 — Update VERSION.md

After confirmation:

1. Update `docs/engine-reference/<engine>/VERSION.md`:
   - `Engine Version` → `[new-version]`
   - `Project Pinned` → today's date
   - `Last Docs Verified` → today's date
   - Re-evaluate and update the `Risk Level` and `Post-Cutoff Version Timeline`
     table if the new version falls beyond the LLM knowledge cutoff
   - Add a `## Migration Notes — [old-version] → [new-version]` section
     containing: migration guide URL, key breaking changes, deprecated APIs
     found in this project, and recommended migration order from the audit

2. If `breaking-changes.md` or `deprecated-apis.md` exist in the engine
   reference directory, append the new version's changes to those files.

3. If `project.yaml` exists at the repo root and has an `engine` block, Read it
   first, then update `engine.version` to `[new-version]` so the primary config
   store stays in sync with VERSION.md.

### 步骤 5 —— 更新 VERSION.md

在确认之后：

1. 更新 `docs/engine-reference/<engine>/VERSION.md`：
   - `Engine Version` → `[new-version]`
   - `Project Pinned` → 今天的日期
   - `Last Docs Verified` → 今天的日期
   - 如果新版本超出 LLM 知识截止，重新评估并更新 `Risk Level` 和
     `Post-Cutoff Version Timeline` 表
   - 添加 `## Migration Notes — [old-version] → [new-version]` 章节，
     包含：迁移指南 URL、关键破坏性变更、在本项目中发现的
     弃用 API，以及来自审计的推荐迁移顺序

2. 如果引擎参考目录中存在 `breaking-changes.md` 或 `deprecated-apis.md`，
   将新版本的变更追加到这些文件中。

3. 如果仓库根目录存在 `project.yaml` 且其中有一个 `engine` 块，先读取它，
   然后将 `engine.version` 更新为 `[new-version]`，以便主配置
   存储与 VERSION.md 保持同步。

### Step 6 — Post-Upgrade Reminder

After updating VERSION.md, output:

```
VERSION.md updated: [engine] [old-version] → [new-version]

Next steps:
1. Migrate deprecated API usages in the [N] files listed above
2. Run /setup-engine refresh after upgrading the actual engine binary to
   verify no new deprecations were missed
3. Run /architecture-review — the engine upgrade may invalidate ADRs that
   reference specific APIs or engine capabilities
4. If any ADRs are invalidated, run /propagate-design-change to update
   downstream stories
```

### 步骤 6 —— 升级后提醒

更新 VERSION.md 之后，输出：

```
VERSION.md updated: [engine] [old-version] → [new-version]

Next steps:
1. Migrate deprecated API usages in the [N] files listed above
2. Run /setup-engine refresh after upgrading the actual engine binary to
   verify no new deprecations were missed
3. Run /architecture-review — the engine upgrade may invalidate ADRs that
   reference specific APIs or engine capabilities
4. If any ADRs are invalidated, run /propagate-design-change to update
   downstream stories
```

---
