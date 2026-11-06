# /smoke-check — Phase 4: Run Manual Smoke Checks

# /smoke-check — 第 4 阶段：运行人工冒烟检查

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 4: Run Manual Smoke Checks

## 第 4 阶段：运行人工冒烟检查

**In this file:**

**本文件内容：**

- Checklist source: name it in the report
- Batch 1 — Core stability
- Batch 2 — Sprint changes and regression
- Batch 3 — Data integrity and performance
- Platform batches: PC, console, mobile

- 清单来源：在报告中注明
- Batch 1 —— 核心稳定性
- Batch 2 —— 冲刺变更与回归
- Batch 3 —— 数据完整性与性能
- 平台批次：PC、主机、移动端

Draw the smoke test checklist from, in priority order (and name the one you used in the report):
1. The QA plan's "Smoke Test Scope" section (if QA plan was found in Phase 1)
2. `production/qa/smoke-tests.md` (if it exists)
3. `tests/smoke/` directory contents (if it exists)
4. The standard fallback list below (used only when none of the above exist)

按以下优先级顺序获取冒烟测试清单（并在报告中注明你使用的来源）：
1. QA 计划的 "Smoke Test Scope" 章节（如果 Phase 1 中找到了 QA 计划）
2. `production/qa/smoke-tests.md`（如果存在）
3. `tests/smoke/` 目录内容（如果存在）
4. 下方的标准兜底清单（仅当上述来源都不存在时使用）

**Name the source you used in the report**, on its own line — *"Checklist source:
`production/qa/smoke-tests.md`"*, or *"Checklist source: standard fallback list —
no QA plan scope, no `production/qa/smoke-tests.md`, no `tests/smoke/`."* The
fallback is a real fallback, so nothing is silently skipped here, but without
that line a report drawn from the generic list reads the same as one drawn from
this project's own smoke definitions. `/gate-check` validates a smoke report's
claims against the repo, and it cannot weigh them without knowing what the
checklist was drawn from.

**在报告中注明你使用的来源**，单独一行 —— *"Checklist source:
`production/qa/smoke-tests.md`"*，或 *"Checklist source: standard fallback list —
no QA plan scope, no `production/qa/smoke-tests.md`, no `tests/smoke/`."*
兜底是真正的兜底，因此这里不会静默跳过任何内容；但如果没有这一行，
基于通用清单写出的报告与基于本项目自身冒烟定义写出的报告看起来会一模一样。
`/gate-check` 会对照仓库核验冒烟报告的陈述，而若不知道清单的来源，
它就无法对这些陈述进行权衡。

Tailor batches 2 and 3 to the actual systems identified from the sprint or QA
plan. Replace bracketed placeholders with real mechanic names from the current
sprint's stories.

根据冲刺或 QA 计划中识别出的实际系统，裁剪 Batch 2 和 Batch 3。
用当前冲刺故事中的真实机制名称替换方括号占位符。

Use `AskUserQuestion` to batch-verify. Keep to at most 3 calls.

使用 `AskUserQuestion` 进行批量验证。最多保持 3 次调用。

**Batch 1 — Core stability (always run):** one call, two questions — an empty
failure list means nothing unless somebody launched the build.
```
question: "Did you launch the current build this session?"
multiSelect: false
options:
  - "Yes — I launched it and checked the items below"
  - "No — I have not launched the current build this session"

question: "Core stability — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Game does not launch or crashes before reaching the main menu"
  - "New game / session fails to start"
  - "Main menu does not respond to inputs"
  - "Crash or hang observed during basic navigation"
```

**Batch 1 —— 核心稳定性（始终运行）：** 一次调用，两个问题 —— 除非有人启动了构建，
否则空的失败清单毫无意义。
```
question: "Did you launch the current build this session?"
multiSelect: false
options:
  - "是 —— 我启动了它并检查了下列项目"
  - "否 —— 本次会话我没有启动当前的构建"

question: "核心稳定性 —— 选择任何 FAILED 的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "游戏无法启动，或在到达主菜单之前崩溃"
  - "新游戏 / 会话无法开始"
  - "主菜单不响应输入"
  - "在基本导航过程中观察到崩溃或卡死"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

对于任何被选中的项目，在生成报告之前请用户简要描述失败的具体情况。

If the build was **not launched**, the Batch 1 checks could not be executed:
record them as `NOT RUN — build not launched this session`, skip Batches 2 and
3 and any platform batch (say so — they need a running build), and ignore the
unselected failure list. The verdict is then NOT ASSESSED unless something else
FAILED.

如果构建**未启动**，则 Batch 1 的检查无法执行：
将它们记为 `NOT RUN — build not launched this session`，跳过 Batch 2、Batch 3
以及任何平台批次（要说明这一点 —— 它们需要运行中的构建），并忽略
未选中的失败清单。此时结论为 NOT ASSESSED，除非有其他内容
失败。

**Batch 2 — Sprint changes and regression (always run):**
```
question: "Sprint changes and regression — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "[Primary mechanic this sprint] — FAILED"
  - "[Second notable change this sprint, if any] — FAILED"
  - "Regression in a previous sprint's feature — FAILED"
  - "Other unexpected breakage observed — FAILED"
```

**Batch 2 —— 冲刺变更与回归（始终运行）：**
```
question: "冲刺变更与回归 —— 选择任何 FAILED 的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "[本冲刺的主要机制] —— FAILED"
  - "[本冲刺的第二项显著变更（若有）] —— FAILED"
  - "此前冲刺功能的回归 —— FAILED"
  - "观察到的其他意外损坏 —— FAILED"
```

For any selected item, ask the user to briefly describe what broke before generating the report.

对于任何被选中的项目，在生成报告之前请用户简要描述哪里坏了。

**Batch 3 — Data integrity and performance (run unless `quick` argument):**
```
question: "Data integrity and performance — select any items that FAILED or were skipped (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Save / load — FAILED (data loss or corruption observed)"
  - "Save / load — N/A (save system not yet implemented)"
  - "Frame rate drops or hitches observed — FAILED"
  - "Performance not checked this session"
```

**Batch 3 —— 数据完整性与性能（除非传入 `quick` 参数，否则运行）：**
```
question: "数据完整性与性能 —— 选择任何 FAILED 或被跳过的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "存档 / 读档 —— FAILED（观察到数据丢失或损坏）"
  - "存档 / 读档 —— 不适用（存档系统尚未实现）"
  - "观察到帧率下降或卡顿 —— FAILED"
  - "本次会话未检查性能"
```

For any FAILED item selected, ask the user to describe what broke before generating the report.

对于任何被选中的 FAILED 项目，在生成报告之前请用户描述哪里坏了。

Record each response verbatim for the Phase 5 report.

为 Phase 5 的报告逐字记录每个回答。

**Platform Batches** *(run only if `--platform` argument was provided)*:

**平台批次** *(仅当提供了 `--platform` 参数时运行)*：

**PC platform** (`--platform pc` or `--platform all`):
```
question: "PC Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Keyboard controls — FAILED (describe issue after)"
  - "Mouse input or cursor visibility — FAILED (describe issue after)"
  - "Windowed / fullscreen mode — FAILED (describe issue after)"
  - "Resolution change — FAILED (describe issue after)"
```

**PC 平台**（`--platform pc` 或 `--platform all`）：
```
question: "PC 平台 —— 选择任何 FAILED 的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "键盘控制 —— FAILED（之后描述问题）"
  - "鼠标输入或光标可见性 —— FAILED（之后描述问题）"
  - "窗口 / 全屏模式 —— FAILED（之后描述问题）"
  - "分辨率切换 —— FAILED（之后描述问题）"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

对于任何被选中的项目，在生成报告之前请用户简要描述失败的具体情况。

**Console platform** (`--platform console` or `--platform all`):
```
question: "Console Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Gamepad input — FAILED (describe issue after)"
  - "UI outside TV safe zone / text clipped — FAILED (describe what is clipped after)"
  - "Keyboard/mouse fallback shown to gamepad user — FAILED (describe after)"
  - "Cold start (no prior save) — FAILED (describe issue after)"
```

**主机平台**（`--platform console` 或 `--platform all`）：
```
question: "主机平台 —— 选择任何 FAILED 的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "手柄输入 —— FAILED（之后描述问题）"
  - "UI 超出电视安全区 / 文字被裁切 —— FAILED（之后描述被裁切的内容）"
  - "向手柄玩家显示了键盘/鼠标的回退方案 —— FAILED（之后描述）"
  - "冷启动（无先前存档）—— FAILED（之后描述问题）"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

对于任何被选中的项目，在生成报告之前请用户简要描述失败的具体情况。

**Mobile platform** (`--platform mobile` or `--platform all`):
```
question: "Mobile Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Touch controls — FAILED (describe issue after)"
  - "Orientation change (portrait ↔ landscape) — FAILED (describe what breaks after)"
  - "Background / foreground transition (home button) — FAILED (describe issue after)"
  - "Performance / thermal throttling on target device — FAILED (describe after)"
```

**移动平台**（`--platform mobile` 或 `--platform all`）：
```
question: "移动平台 —— 选择任何 FAILED 的项目（若全部通过则保持全部未选中）："
multiSelect: true
options:
  - "触摸控制 —— FAILED（之后描述问题）"
  - "方向切换（竖屏 ↔ 横屏）—— FAILED（之后描述损坏的内容）"
  - "后台 / 前台切换（Home 键）—— FAILED（之后描述问题）"
  - "目标设备上的性能 / 热降频 —— FAILED（之后描述）"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

对于任何被选中的项目，在生成报告之前请用户简要描述失败的具体情况。

---
