# /smoke-check — Phase 1: Detect Test Setup

# /smoke-check — 第 1 阶段：检测测试环境

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 1: Detect Test Setup

## 第 1 阶段：检测测试环境

Before running anything, understand the environment:

在运行任何内容之前，先了解环境：

0. **Config coherence**: run `bash .claude/scripts/project-coherence.sh`.

   It compares what `project.yaml` declares against the real project file, the
   installed engine binary, and the files `commands.*` name. This runs first
   because two of its checks are about *this skill's own inputs*: a
   `commands.test` naming a runner that does not exist, or a `commands.build`
   naming an export preset with no `export_presets.cfg`, will fail here and read
   as a broken build rather than as broken config.

   Report any `[DIFFERS]` lines in the report's Environment section. They do not
   by themselves decide the verdict -- but a smoke check run against a project
   whose declared engine is not the installed one is worth saying out loud.

0. **配置一致性**：运行 `bash .claude/scripts/project-coherence.sh`。

   它会将 `project.yaml` 声明的内容与真实的项目文件、已安装的引擎二进制文件，
   以及 `commands.*` 命名的文件进行比对。这一步最先运行，因为其中两项检查
   针对的是*本技能自身的输入*：一个指向不存在运行器的
   `commands.test`，或一个指定的导出预设却没有 `export_presets.cfg` 的
   `commands.build`，会在这里失败，并被读成构建损坏，而不是配置损坏。

   在报告的环境部分报告任何 `[DIFFERS]` 行。它们本身并不决定结论 ——
   但针对一个声明引擎与实际安装引擎不一致的项目运行冒烟测试，
   值得明确说出来。

1. **Test framework check**: verify that **game** test files exist — not merely
   that `tests/` does. Check the engine's **test root** (from step 3; the table
   is in `.claude/docs/directory-structure.md` — Godot `tests/unit/` and
   `tests/integration/`, Unity `Assets/Tests/`, Unreal
   `Source/*/Private/Tests/`) and `tests/smoke/` for actual test files. A
   **test file** is one the engine's test runner executes — a `*_test.gd` suite,
   a C# test class, an Unreal automation test source. Markdown checklists do not
   count: `/test-setup` always writes `tests/smoke/critical-paths.md`, and
   counting it would hide exactly the zero-test state this step exists to catch.
   If none are found **at `qa.level: minimal`**, tests are waived at this level:
   record the automated row as `WAIVED — qa.level: minimal, no game tests`, skip
   the test run in Phase 2 and all of Phase 3 (say so in one line each), run
   Phase 2's **build check**, and go on to Phase 4 — the build check and the
   launch and critical-path checks are the smoke check at this level, so
   a project with no tests can still reach PASS, but never without a run: a
   Batch 1 answer that the build was not launched this session leaves the
   verdict NOT ASSESSED.
   If none are found **at `standard` or `full`**, **deliver a NOT ASSESSED verdict — do not merely stop.**
   "Smoke check: **NOT ASSESSED — no game tests found** under
   [the test root] or `tests/smoke/`. Run `/test-setup` to scaffold the testing
   infrastructure, or point me at where tests live." Then stop.

1. **测试框架检查**：确认存在**游戏**测试文件 —— 而不仅仅是 `tests/`
   存在。检查引擎的**测试根目录**（来自第 3 步；表格在
   `.claude/docs/directory-structure.md` 中 —— Godot 为 `tests/unit/` 和
   `tests/integration/`，Unity 为 `Assets/Tests/`，Unreal 为
   `Source/*/Private/Tests/`）以及 `tests/smoke/` 中是否存在实际的测试文件。
   **测试文件**是指引擎测试运行器会执行的文件 —— 一个 `*_test.gd` 套件、
   一个 C# 测试类、一个 Unreal 自动化测试源文件。Markdown 清单不算：
   `/test-setup` 总会写入 `tests/smoke/critical-paths.md`，把它计算在内
   恰恰会掩盖本步骤存在所要发现的零测试状态。
   如果在 **`qa.level: minimal`** 下没有找到任何测试文件，则在该级别测试被豁免：
   将自动化测试行记为 `WAIVED — qa.level: minimal, no game tests`，跳过
   Phase 2 中的测试运行以及整个 Phase 3（各用一行说明），运行
   Phase 2 的**构建检查**，然后继续 Phase 4 —— 在此级别，构建检查以及
   启动和关键路径检查就是冒烟测试，因此一个没有测试的项目仍然可以达到 PASS，
   但绝不能在未运行的情况下达到：若 Batch 1 的回答是本次会话未启动构建，
   则结论保持 NOT ASSESSED。
   如果在 **`standard` 或 `full`** 下没有找到任何测试文件，**则给出 NOT ASSESSED 结论 —— 不要只是停下来。**
   "Smoke check: **NOT ASSESSED — no game tests found** under
   [the test root] or `tests/smoke/`. Run `/test-setup` to scaffold the testing
   infrastructure, or point me at where tests live." 然后停止。

   > A bare halt is the wrong shape here.
   > This is the state with the **least** information about build health, so it is
   > the last one that should exit without a verdict: the caller gets no
   > machine-readable outcome, and "the skill said nothing" is easy to read as
   > "nothing was wrong". Replacing a *wrong* verdict with *no* verdict is not an
   > improvement either — the honest result is the one that names what could not
   > be established.

   > 在这里直接中止是错误的形式。
   > 这是关于构建健康状况信息**最少**的状态，因此它最不该在没有结论的情况下退出：
   > 调用方得不到任何机器可读的结果，而“技能什么都没说”很容易被理解为
   > “没有任何问题”。用一个*错误*的结论替换成*没有*结论同样不是
   > 改进 —— 诚实的结果应当明确指出哪些内容无法确认。

   > **Do not gate on `tests/` existing.** `/test-setup` creates `tests/unit/`
   > and `tests/integration/` with placeholder files, so the directory tree is
   > present on any project that ran setup — whether or not a single game test
   > was ever written. Count actual test files instead; gated on the directory,
   > a project with no build and zero game tests passes this step.

   > **不要以 `tests/` 是否存在作为闸门。** `/test-setup` 会创建 `tests/unit/`
   > 和 `tests/integration/` 以及占位文件，因此任何运行过搭建的项目都会存在
   > 该目录树 —— 无论是否编写过哪怕一个游戏测试。应当统计实际的测试文件；
   > 若以目录为闸门，一个没有构建且零游戏测试的项目也能通过这一步。

2. **CI check**: check whether `.github/workflows/` contains a workflow file
   referencing tests. Note in the report whether CI is configured.

2. **CI 检查**：检查 `.github/workflows/` 中是否包含引用测试的工作流文件。
   在报告中注明 CI 是否已配置。

3. **Engine detection**: read `engine.name` from `project.yaml`; if that key
   is absent or empty (including when `project.yaml` has no `engine:` block),
   fall back to the `Engine:` value in `.claude/docs/technical-preferences.md`
   (a `[TO BE CONFIGURED]` value means not configured). Store this for test
   command selection in Phase 2.

3. **引擎检测**：从 `project.yaml` 读取 `engine.name`；如果该键
   缺失或为空（包括 `project.yaml` 没有 `engine:` 块的情况），
   则回退到 `.claude/docs/technical-preferences.md` 中的 `Engine:` 值
   （`[TO BE CONFIGURED]` 表示未配置）。保存该值，用于 Phase 2 中的测试
   命令选择。

   Then find the **editor executable** — none of the three engines installs
   onto `PATH` by default on Windows or macOS, so a bare `godot` that does not
   resolve says nothing about whether the engine is installed. Take the first
   that resolves (the file exists, or `command -v` finds it): the executable
   `commands.test` names (its quoted path or first word; on Godot, only when its
   file name says godot, since a wrapper such as `bash run-tests.sh` is not the
   editor), else the editor
   `engine.path` records, else the engine's name on `PATH` (`godot`). Use it
   wherever Phase 2 writes `godot` or `"<Unity editor>"`, quoting a path with a
   space; on Unreal, `<UE root>` is `engine.path`. If none resolves, the test
   runner is not available (Phase 2) — on Godot,
   `NOT ASSESSED — Godot executable not found (commands.test, engine.path, PATH)`.

   然后找到**编辑器可执行文件** —— 这三款引擎在 Windows 或 macOS 上默认都不会
   安装到 `PATH`，因此一个无法解析的裸 `godot` 并不能说明引擎是否已安装。
   取第一个能解析到的（文件存在，或 `command -v` 能找到）：`commands.test`
   命名的可执行文件（其引号内的路径或第一个词；在 Godot 上，仅当其
   文件名包含 godot 时才算，因为 `bash run-tests.sh` 这类包装脚本不是
   编辑器），否则取 `engine.path` 记录的编辑器，否则取引擎在 `PATH` 上的名称
   （`godot`）。在 Phase 2 写出 `godot` 或 `"<Unity editor>"` 的所有位置都使用它，
   含空格的路径要加引号；在 Unreal 上，`<UE root>` 即 `engine.path`。
   如果都解析不到，则测试运行器不可用（Phase 2）—— 在 Godot 上，
   `NOT ASSESSED — Godot executable not found (commands.test, engine.path, PATH)`。

4. **Smoke test list**: check whether `production/qa/smoke-tests.md` or
   `tests/smoke/` exists. If a smoke test list is found, load it for use in
   Phase 4. If neither exists, smoke tests will be drawn from the current QA
   plan (Phase 4 fallback).

4. **冒烟测试清单**：检查 `production/qa/smoke-tests.md` 或
   `tests/smoke/` 是否存在。如果找到了冒烟测试清单，则加载它以供
   Phase 4 使用。如果两者都不存在，冒烟测试将从当前的 QA
   计划中提取（Phase 4 的兜底方案）。

5. **QA plan check**: glob `production/qa/qa-plan-*.md` and take the most
   recently modified file. If found, note the path — it will be used in
   Phase 3 and Phase 4. If not found, note: "No QA plan found. Run
   `/qa-plan sprint` before smoke-checking for best results." (At `workflow: minimal`,
   which has no sprints, a QA plan is optional — say so rather than recommend one.)

5. **QA 计划检查**：glob `production/qa/qa-plan-*.md` 并取最近修改的文件。
   如果找到，记录其路径 —— 将在 Phase 3 和 Phase 4 中使用。如果未找到，
   则注明："No QA plan found. Run `/qa-plan sprint` before smoke-checking for best results."
   （在 `workflow: minimal` 模式下，没有冲刺，QA 计划是可选的 ——
   应当说明这一点，而不是建议用户去创建一份。）

Report findings before proceeding: "Environment: [engine]. Editor: [the
resolved executable / not found]. Test directory:
[found / not found]. CI configured: [yes / no]. QA plan: [path / not found]."

在继续之前报告检查结果："Environment: [engine]. Editor: [the
resolved executable / not found]. Test directory:
[found / not found]. CI configured: [yes / no]. QA plan: [path / not found]."

---
