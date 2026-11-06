# Phase 7: Logging advisory deviations as tech debt

# 阶段 7：将建议性偏差记录为技术债

Read only when the user picks "Close and log the advisory deviations as tech debt".

仅当用户选择"关闭并将建议性偏差记录为技术债"时才读取。

Add one row per advisory deviation to `docs/tech-debt-register.md`, in the table
`/tech-debt` keeps, so `/tech-debt report` can date it from its `Added` column:

在 `docs/tech-debt-register.md` 中为每个建议性偏差添加一行，放在 `/tech-debt` 维护的表格中，以便 `/tech-debt report` 能从其 `Added` 列确定日期：

```
| TD-[next free NNN] | [category] | [deviation] — from [story path] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | — | Open | [YYYY-MM-DD] | Backlog |
```

- **ID:** one above the highest TD number already in the file, three digits;
  `TD-001` in a new file.
- **Category:** one of Architecture, Code Quality, Test, Documentation, Dependency,
  Performance.
- **Effort and Impact:** your estimate from the deviation.
- **Priority:** `—` until `/tech-debt prioritize` scores it.
- **Added:** today.

- **ID：** 比文件中现有最高 TD 编号大 1，三位数字；新文件中为 `TD-001`。
- **类别：** Architecture、Code Quality、Test、Documentation、Dependency、Performance 之一。
- **工作量和影响：** 你根据偏差做出的估算。
- **优先级：** 在 `/tech-debt prioritize` 为其评分之前为 `—`。
- **添加日期：** 今天。

The file starts with a `## Technical Debt Register` heading, a `Last updated:
[date]` line, a `Total items: [N] | Estimated total effort: [sizes summed]` line and
the table header:

文件以 `## Technical Debt Register` 标题开头，然后是 `Last updated: [date]` 行、`Total items: [N] | Estimated total effort: [sizes summed]` 行，以及表格表头：

```
| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
```

When the file does not exist, create it that way. When it does, update those two
lines, and add the table header first if it has none.

当文件不存在时，按该方式创建它。当它存在时，更新那两行，如果它没有表格表头，则先添加表头。
