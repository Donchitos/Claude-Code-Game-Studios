# /smoke-check — Phase 3: Check Test Coverage

# /smoke-check — 第 3 阶段：检查测试覆盖

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 3: Check Test Coverage

## 第 3 阶段：检查测试覆盖

Draw the story list from, in priority order:
1. The QA plan found in Phase 1 (its Test Summary table lists expected test
   file paths per story)
2. The current sprint plan from `production/sprints/` (most recently modified
   file)
3. If the `quick` argument was passed, skip this phase entirely and note:
   "Coverage scan skipped — run `/smoke-check sprint` for full coverage
   analysis."

按以下优先级顺序获取故事清单：
1. Phase 1 中找到的 QA 计划（其 Test Summary 表列出了每个故事预期的测试
   文件路径）
2. `production/sprints/` 中当前的冲刺计划（最近修改的
   文件）
3. 如果传入了 `quick` 参数，则完全跳过本阶段，并注明：
   "Coverage scan skipped — run `/smoke-check sprint` for full coverage
   analysis."

For each story in scope:

对范围内的每个故事：

1. Extract the system slug from the story's file path
   (e.g., `production/epics/combat/story-001.md` → `combat`)
2. Glob `tests/unit/[system]/` and `tests/integration/[system]/` for files
   whose name contains the story slug or a closely related term
3. Check the story file itself for a `Test file:` header field or a
   "Test Evidence" section

1. 从故事的文件路径中提取系统 slug
   （例如 `production/epics/combat/story-001.md` → `combat`）
2. Glob `tests/unit/[system]/` 和 `tests/integration/[system]/`，查找名称
   包含该故事 slug 或密切相关术语的文件
3. 检查故事文件本身是否含有 `Test file:` 头部字段或
   "Test Evidence" 章节

Assign a coverage status to each story:

为每个故事分配一个覆盖状态：

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file was found matching this story's system and scope |
| **MANUAL** | Story type is Visual/Feel or UI; a test evidence document was found |
| **MISSING** | Logic or Integration story with no matching test file |
| **EXPECTED** | Config/Data story — no test file required; spot-check is sufficient |
| **UNKNOWN** | Story file missing or unreadable |

| 状态 | 含义 |
|--------|---------|
| **COVERED** | 找到了与该故事所属系统和范围匹配的测试文件 |
| **MANUAL** | 故事类型为 Visual/Feel 或 UI；找到了测试证据文档 |
| **MISSING** | Logic 或 Integration 故事，但没有匹配的测试文件 |
| **EXPECTED** | Config/Data 故事 —— 无需测试文件；抽查即可 |
| **UNKNOWN** | 故事文件缺失或无法读取 |

MISSING entries are advisory gaps. They do not cause a FAIL verdict but must
appear prominently in the report and must be resolved before `/story-done` can
fully close those stories.

MISSING 条目属于提示性缺口。它们不会导致 FAIL 结论，但必须在
报告中显著呈现，并且必须在 `/story-done` 能够完全关闭这些故事之前
得到解决。

---
