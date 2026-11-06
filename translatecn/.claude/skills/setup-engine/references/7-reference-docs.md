# /setup-engine — Section 7: Populate Engine Reference Docs

# /setup-engine — 第 7 节：填充引擎参考文档

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 7. Populate Engine Reference Docs

**In this file:**

- First: does a reference set already exist for this engine?
- Sourcing rule for everything written in this section
- If WITHIN training data (LOW RISK):
- If BEYOND training data (MEDIUM or HIGH RISK):

## 7. 填充引擎参考文档

**本文件内容：**

- 首先：该引擎是否已存在一套参考？
- 本节所写一切内容的溯源规则
- 如果在训练数据范围内（LOW RISK）：
- 如果超出训练数据（MEDIUM 或 HIGH RISK）：

### First: does a reference set already exist for this engine?

**Check before doing anything else.** The template ships
`docs/engine-reference/godot/`, `unity/` and `unreal/` **already populated**, so
"the directory exists and pins a version" is the state of *every* fresh project,
not an edge case. Both branches below say "create", and following either one
literally on a pre-populated directory either overwrites curated content or
leaves `project.yaml` and the CLAUDE.md-imported reference disagreeing.

Read `docs/engine-reference/<engine>/VERSION.md` and compare its
**Engine Version** to the version chosen in Section 3:

### 首先：该引擎是否已存在一套参考？

**在做任何事之前先检查。** 模板随附的
`docs/engine-reference/godot/`、`unity/` 和 `unreal/` **已经填充**，因此
"目录存在且固定了某个版本"是*每个*全新项目的状态，
而非边缘情况。下面的两个分支都说"创建"，若在已预填充的目录上
照字面执行其中任何一个，要么覆盖精心整理的内容，
要么让 `project.yaml` 与 CLAUDE.md 导入的参考彼此不一致。

读取 `docs/engine-reference/<engine>/VERSION.md`，将其
**Engine Version** 与第 3 节选定的版本进行比较：

- **No directory, or no `VERSION.md`** → create, using the risk branch below.
- **Same version** → nothing to regenerate. Refresh `Last Docs Verified` only if you
  actually re-verified against the docs this run. Do not restamp a date you did
  not check. The one row still written is `Installed at pin time`, from
  Section 3 — its probe result is recorded whatever the outcome, after asking
  "May I record `Installed at pin time: [result]` in
  `docs/engine-reference/<engine>/VERSION.md`?" (it is a tracked file).
- **Directory pins an OLDER version than the one chosen** → **update, do not
  replace.** This is the common case. Show the changes below, then ask "May I
  update the `docs/engine-reference/<engine>/` files for [version]?" before editing.
  1. Edit `VERSION.md` in place: new **Engine Version**, new **Project Pinned**
     and **Last Docs Verified**, the `Installed at pin time` row from Section 3,
     and a new row in the post-cutoff timeline for each version added.
  2. **Append** to `breaking-changes.md`, `deprecated-apis.md` and
     `current-best-practices.md` under a heading naming the version span
     (`## 4.6 → 4.7`). Never truncate the older spans — a project migrating
     across two versions still needs the earlier one.
  3. Re-grade the older timeline rows if the cutoff moved past them.
- **Directory pins a NEWER version than the one chosen** → stop and ask. Someone
  pinned forward deliberately, or the version choice is wrong. Do not silently
  downgrade a curated reference.

- **没有目录，或没有 `VERSION.md`** → 创建，使用下面的风险分支。
- **版本相同** → 无需重新生成。仅在你本次确实对照文档重新验证过时，
  才刷新 `Last Docs Verified`。不要为你没有核查的日期重新盖章。仍然会写入的唯一一行是
  `Installed at pin time`，来自第 3 节 —— 无论结果如何都会记录其探测结果，
  前提是先询问"我可以把 `Installed at pin time: [result]` 记录到
  `docs/engine-reference/<engine>/VERSION.md` 中吗？"（它是一个受跟踪的文件）。
- **目录固定的版本比所选版本更旧** → **更新，而非替换。** 这是常见情况。
  展示下面的更改，然后在编辑前询问"我可以更新 `docs/engine-reference/<engine>/`
  下针对 [version] 的文件吗？"
  1. 就地编辑 `VERSION.md`：新的 **Engine Version**、新的 **Project Pinned**
     和 **Last Docs Verified**、来自第 3 节的 `Installed at pin time` 行，
     以及在截止后时间线中为每个新增版本添加一行。
  2. 在 `breaking-changes.md`、`deprecated-apis.md` 和
     `current-best-practices.md` 中以命名版本区间的标题
     （`## 4.6 → 4.7`）**追加**内容。绝不要截断较早的区间 —— 跨两个版本
     迁移的项目仍然需要较早的那一段。
  3. 如果截止日期已越过较早的时间线行，重新评级它们。
- **目录固定的版本比所选版本更新** → 停止并询问。有人
  有意向前固定，或者版本选择有误。不要悄悄降级一份精心整理的参考。

### Sourcing rule for everything written in this section

**Never fill a gap from training data. Write the gap down instead.**

The whole purpose of these files is to be the thing agents consult *instead of*
their training data. A confidently wrong entry here is worse than no entry: it
produces work that looks verified and is not.

- Every claim must come from a page you fetched this run. Record the URL.
- If the official docs do not state something the template asks for — a release
  date, a subsystem's behaviour, web-export specifics — write
  **`NOT SOURCEABLE — <what>, not stated at <url>`** and move on.
- A `NOT SOURCEABLE` line is a successful outcome, not a failure to finish.
- Do not infer one fact from an adjacent one. "The migration guide lists no
  physics change" is not "the physics default is unchanged"; if you record the
  inference, label it as an inference and name what it rests on.

### 本节所写一切内容的溯源规则

**绝不要用训练数据填补缺口。而是把缺口写下来。**

这些文件的全部意义就在于成为智能体*代替*其训练数据去查阅的东西。
这里一条自信却错误的条目比没有条目更糟：它
产出看似已验证、实则未验证的成果。

- 每一项断言都必须来自你本次抓取的页面。记录 URL。
- 如果官方文档没有陈述模板所要求的内容 —— 一个发布日期、
  某个子系统的行为、Web 导出的具体细节 —— 就写
  **`NOT SOURCEABLE — <what>, not stated at <url>`** 然后继续。
- 一行 `NOT SOURCEABLE` 是成功的结果，而非未能完成。
- 不要从相邻事实推断出一个事实。"迁移指南未列出
  物理改动"并不等于"物理默认值未变"；如果你记录了
  该推断，请标明它是推断，并说明它依据什么。

### If WITHIN training data (LOW RISK):

Ask: "May I create `docs/engine-reference/<engine>/VERSION.md`?" Wait for
confirmation, then create this minimal file:

### 如果在训练数据范围内（LOW RISK）：

询问："我可以创建 `docs/engine-reference/<engine>/VERSION.md` 吗？" 等待
确认，然后创建以下最小文件：

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **Installed at pin time** | [Section 3 result — the installed version, or NOT DETERMINED] |
| **LLM Knowledge Cutoff** | [the cutoff from the Section 6 coverage table] |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **Installed at pin time** | [Section 3 result — the installed version, or NOT DETERMINED] |
| **LLM Knowledge Cutoff** | [the cutoff from the Section 6 coverage table] |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

Do NOT create breaking-changes.md, deprecated-apis.md, etc. — they would
add context cost with minimal value.

**不要**创建 breaking-changes.md、deprecated-apis.md 等 —— 它们会
增加上下文成本而价值极小。

### If BEYOND training data (MEDIUM or HIGH RISK):

Create the full reference doc set by searching the web:

1. **Search for the official migration/upgrade guide**:
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **Fetch and extract** from official documentation:
   - Breaking changes between each version from the training cutoff to current
   - Deprecated APIs with replacements
   - New features and best practices

### 如果超出训练数据（MEDIUM 或 HIGH RISK）：

通过搜索网络来创建完整的参考文档集：

1. **搜索官方迁移/升级指南**：
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **从官方文档抓取并提取**：
   - 从训练截止到当前每个版本之间的破坏性变更
   - 已弃用的 API 及其替代方案
   - 新功能和最佳实践

Ask: "May I create the engine reference docs under `docs/engine-reference/<engine>/`?"

Wait for confirmation before writing any files.

询问："我可以创建 `docs/engine-reference/<engine>/` 下的引擎参考文档吗？"

在写入任何文件之前等待确认。

3. **Create the full reference directory**:
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **Populate each file** using real data from the web searches, following
   the format established in existing reference docs. Every file must have
   a "Last verified: [date]" header.

5. **For module files**: Only create modules for subsystems where significant
   changes occurred. Don't create empty or minimal module files.

3. **创建完整的参考目录**：
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **填充每个文件**，使用来自网络搜索的真实数据，遵循
   现有参考文档中确立的格式。每个文件都必须有
   一个 "Last verified: [date]" 头部。

5. **对于模块文件**：只为发生了重大
   变更的子系统创建模块。不要创建空白或内容极少的模块文件。

---
