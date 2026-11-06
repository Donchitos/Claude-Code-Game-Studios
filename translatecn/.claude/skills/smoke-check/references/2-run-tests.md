# /smoke-check — Phase 2: Run Automated Tests

# /smoke-check — 第 2 阶段：运行自动化测试

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 2: Run Automated Tests

## 第 2 阶段：运行自动化测试

**In this file:**

**本文件内容：**

- `commands.test` first
- Godot 4
- Unity: Edit Mode, then Play Mode as a second run
- Unreal Engine: build first, commands per OS, macOS
- Unknown engine / not configured
- Test runner not available here
- Build check (the WAIVED path only)

- 优先使用 `commands.test`
- Godot 4
- Unity：先 Edit Mode，再以第二遍运行 Play Mode
- Unreal Engine：先构建，按操作系统给出命令，macOS
- 未知引擎 / 未配置
- 此处测试运行器不可用
- 构建检查（仅 WAIVED 路径）

**Run `commands.test` from `project.yaml` when it is set** — it is the
project's own test command, the one `/setup-engine` wrote and CI runs. Use the
per-engine default below only when `commands.test` is absent, and say in the
report which of the two you ran. Wrap it in a timeout (`timeout 900 …`): **a
timeout (exit 124) is a gate FAILURE, never a pass** — the run never completed
and nothing was verified. macOS has no `timeout`: use `gtimeout 900 …` from
Homebrew's `coreutils` (same exit 124), or, with nothing installed,
`perl -e 'alarm shift; exec @ARGV' 900 …`, which exits 142 when time runs out —
a FAILURE the same way. Then read the result for the engine. On every engine
one outcome looks like success and is not; each is named below.

**当 `project.yaml` 中设置了 `commands.test` 时，运行它** —— 它是项目自己的
测试命令，即 `/setup-engine` 写入、CI 所运行的那条。仅当 `commands.test`
缺失时才使用下方按引擎给出的默认命令，并在报告中说明你运行的是两者中的哪一个。
为它加上超时（`timeout 900 …`）：**超时（退出码 124）是闸门失败，绝不是通过** ——
运行从未完成，也没有任何内容得到验证。macOS 没有 `timeout`：请使用 Homebrew
`coreutils` 提供的 `gtimeout 900 …`（同样以 124 退出），或者在什么都没安装时使用
`perl -e 'alarm shift; exec @ARGV' 900 …`，它在超时时以 142 退出 ——
同样是失败。然后按引擎读取结果。在每种引擎上，都有一种结果看似成功实则不然；
下面逐一说明。

**Godot 4** — first check that `addons/gdUnit4/bin/GdUnitCmdTool.gd` exists —
the folder has a **capital U**. If it does not, report
`NOT ASSESSED — gdUnit4 not installed at addons/gdUnit4/` instead of running
anything. Then import, whether you run `commands.test` or the
default. A fresh clone has no `.godot/` class cache, and without it gdUnit4's
runner does not load; a cache that predates a new `class_name` fails valid
code with 105. The import takes seconds when nothing changed (`godot` below is
the executable Phase 1 step 3 resolved):
```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode 2>&1
```
gdUnit4's exit code gives the verdict (run on 6.1.3 and 6.2.2):
- **0** — every test passed: PASS. **But exit 0 over zero tests is not a pass:**
  gdUnit4 aborts and still exits 0, so if the output says `No test cases found`,
  the verdict is `NOT ASSESSED — no tests found`.
- **101** — every test passed but a test leaked nodes (orphans): PASS WITH
  WARNINGS, naming the orphan count from the output. Not a failure.
- **100** — a test failed: FAIL. **105** — a test script does not parse: FAIL.
- **103** — gdUnit4 refused to run headless (`--ignoreHeadlessMode` missing);
  **104** — Godot older than 4.3: `NOT ASSESSED`, with that reason.
- **1** — Godot's own error: `GdUnitCmdTool.gd` did not load (`Failed to load
  script`), so no test ran. Usually the import above was skipped; after it,
  exit 1 is a FAIL.

**Godot 4** —— 首先检查 `addons/gdUnit4/bin/GdUnitCmdTool.gd` 是否存在 ——
该文件夹的 U 为**大写**。如果不存在，报告
`NOT ASSESSED — gdUnit4 not installed at addons/gdUnit4/`，而不要运行
任何内容。然后执行导入，无论你运行的是 `commands.test` 还是
默认命令。全新克隆没有 `.godot/` 类缓存，缺少它时 gdUnit4 的
运行器无法加载；早于新增 `class_name` 的缓存会让有效代码
以 105 失败。没有变化时导入只需几秒（下面的 `godot` 是
Phase 1 第 3 步解析出的可执行文件）：
```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode 2>&1
```
gdUnit4 的退出码给出结论（已在 6.1.3 和 6.2.2 上运行）：
- **0** —— 所有测试通过：PASS。**但零测试下的退出码 0 不算通过：**
  gdUnit4 会中止并且仍然以 0 退出，因此如果输出显示 `No test cases found`，
  结论为 `NOT ASSESSED — no tests found`。
- **101** —— 所有测试通过，但有测试泄漏了节点（孤儿节点）：PASS WITH
  WARNINGS，并注明输出中的孤儿节点数量。这不是失败。
- **100** —— 有测试失败：FAIL。**105** —— 某个测试脚本无法解析：FAIL。
- **103** —— gdUnit4 拒绝以无头模式运行（缺少 `--ignoreHeadlessMode`）；
  **104** —— Godot 版本早于 4.3：`NOT ASSESSED`，并附上该原因。
- **1** —— Godot 自身的错误：`GdUnitCmdTool.gd` 未能加载（`Failed to load
  script`），因此没有测试运行。通常是因为跳过了上面的导入；执行导入后
  若仍为退出码 1，则为 FAIL。

Every run opens with two `ERROR:` lines about the remote port
(`127.0.0.1:0`) — that is the `--remote-debug` flag working, not a failure.
Never drop the flag: without it a script error opens Godot's interactive
debugger and the run hangs at a `debug>` prompt until the timeout.

每次运行都以两行与远程端口（`127.0.0.1:0`）相关的 `ERROR:` 开头 —— 那是
`--remote-debug` 标志在起作用，不是失败。绝不要去掉该标志：缺少它时，
脚本错误会打开 Godot 的交互式调试器，运行会停在 `debug>` 提示符处直到超时。

**Unity:**
Unity **can** run tests headlessly via shell. Do not skip to reading artifacts.

**Unity：**
Unity **可以**通过 shell 以无头方式运行测试。不要跳过运行直接去读取产物。

First confirm the Unity Test Framework is installed. A project without it does
not fail cleanly — it **hangs** until something kills it:
```bash
grep -q 'com.unity.test-framework' Packages/manifest.json && echo present || echo ABSENT
```
If ABSENT, report `NOT ASSESSED — Unity Test Framework not installed` and
give the one-line fix (add `com.unity.test-framework` to `Packages/manifest.json`).
**Do not fall through to reading stale artifacts** — an unknown-age XML
reported as a pass is worse than no gate.

首先确认已安装 Unity Test Framework。没有它的项目不会干净地失败 ——
而是会**挂起**，直到有东西将其终止：
```bash
grep -q 'com.unity.test-framework' Packages/manifest.json && echo present || echo ABSENT
```
如果为 ABSENT，报告 `NOT ASSESSED — Unity Test Framework not installed`，并
给出一行修复方法（将 `com.unity.test-framework` 加入 `Packages/manifest.json`）。
**不要退回到读取过期的产物** —— 把一个时间不明的 XML 报告为通过，
比没有闸门更糟。

If present, the default is (the **editor** executable — `Unity` on `PATH` may be
Unity's separate CLI). Delete the old results file first, whether you run
`commands.test` or this default:
```bash
rm -f test-results/editmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
```
Exit 0 when every test passes, 2 on a failure. **Exit 1 or 3 is a FAIL**: 1
means the project did not compile (the editor log has the `error CS…` lines),
3 that the run itself failed; 4 (an unknown `-testPlatform`) or any other
non-zero exit is a FAIL too. A compile error writes no results file — which
is why the old one is deleted first: left in place, the last run's pass is read
as this run's. After any exit, no results file is a FAIL. Parse the `<test-run>`
element of the results file for `testcasecount`, `passed` and `failed`. **`testcasecount="0"`
is NOT ASSESSED, never a pass**: tests outside `Assets/` are never compiled, and
Unity then reports `result="Passed"` with exit 0 over zero tests.

如果已存在，默认命令为（使用**编辑器**可执行文件 —— `PATH` 上的 `Unity`
可能是 Unity 独立的 CLI）。无论你运行 `commands.test` 还是这个默认命令，
都先删除旧的结果文件：
```bash
rm -f test-results/editmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
```
所有测试通过时退出码为 0，失败时为 2。**退出码 1 或 3 均为 FAIL**：1
表示项目未编译（编辑器日志中有 `error CS…` 行），3 表示运行本身失败；
4（未知的 `-testPlatform`）或任何其他非零退出码同样为 FAIL。编译错误不会写出
结果文件 —— 这正是先删除旧文件的原因：若保留在原处，上一次运行的通过结果
会被读成本次运行的结果。无论以何种方式退出，只要没有结果文件即为 FAIL。解析
结果文件中的 `<test-run>` 元素，取出 `testcasecount`、`passed` 和 `failed`。
**`testcasecount="0"` 为 NOT ASSESSED，绝不算通过**：`Assets/` 之外的测试
永远不会被编译，Unity 随后会在零测试的情况下报告 `result="Passed"` 且退出码为 0。

**Play Mode is a second run.** `-testPlatform EditMode` — this default, and
`commands.test` as `/setup-engine` writes it — never runs the integration tests
`/test-setup` scaffolds under `Assets/Tests/PlayMode/`. When that folder holds a
test file and the command you ran did not already pass `-testPlatform PlayMode`,
run Play Mode the same way, into its own results file, and read it by the same
rules:
```bash
rm -f test-results/playmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
Report each platform on its own line — `EditMode: PASS (12/12)`,
`PlayMode: FAIL (1 failure)`. A Play Mode run that could not be made is
reported by name, `PlayMode: NOT RUN — [reason]`: the Edit Mode result does not
cover those tests, so it cannot make the automated-test row a PASS.

**Play Mode 是第二遍运行。** `-testPlatform EditMode` —— 这个默认命令，以及
`/setup-engine` 写入的 `commands.test` —— 永远不会运行
`/test-setup` 在 `Assets/Tests/PlayMode/` 下搭建的集成测试。当该文件夹中
存在测试文件，且你运行的命令尚未传入 `-testPlatform PlayMode` 时，
请以同样的方式运行 Play Mode，写入它自己的结果文件，并按相同的
规则读取：
```bash
rm -f test-results/playmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
为每个平台单独报告一行 —— `EditMode: PASS (12/12)`、
`PlayMode: FAIL (1 failure)`。未能执行的 Play Mode 运行应
按名称报告，即 `PlayMode: NOT RUN — [reason]`：Edit Mode 的结果并不
覆盖那些测试，因此它无法让自动化测试行变为 PASS。

**Unreal Engine** — build the editor target first, whether you then run
`commands.test` or the default. `Binaries/` is not committed, and without a
built game module the editor stops with "The game module could not be found",
exit 1, before running any test. The build is incremental — seconds when
nothing changed; a failed build is a FAIL.

**Unreal Engine** —— 先构建编辑器目标，无论随后运行的是
`commands.test` 还是默认命令。`Binaries/` 未提交，若没有已构建的
游戏模块，编辑器会以 "The game module could not be found" 停止，
退出码为 1，且在运行任何测试之前就停止。构建是增量的 —— 没有变化时只需几秒；
构建失败即为 FAIL。

**Pick the commands for this machine** with `uname -s`: `Linux` → Linux,
`Darwin` → macOS, anything else (`MINGW*`, `MSYS*`, `CYGWIN*`) → Windows. The
Windows forms below were run on UE 5.7; the Linux and macOS forms come from
Epic's documentation — `docs/engine-reference/unreal/current-best-practices.md`,
"Command Line", has them with their sources. On Windows use
`UnrealBuildTool.exe`, not `Build.bat`: run from bash, `Build.bat` fails on an
engine path with spaces.
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# macOS (timeout: see the macOS note above)
gtimeout 1800 "<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
```
Then the default. Keep `-stdout -FullStdOutLogOutput`; when `commands.test`
lacks them, add them to the command for this run only: without them the editor
prints nothing, and the lines below are only in `Saved/Logs/<Project>.log`.
Give the project as an **absolute** path — when `commands.test` passes a
relative one, run it with the absolute path instead: UE 5.7
does not find a relative `<Project>.uproject` and exits 1 (`Project file not
found`). `$(pwd -W 2>/dev/null || pwd)` gives the `C:/…` form in Git Bash and
the plain path elsewhere; `$PWD` alone fails when `MSYS_NO_PATHCONV` is set.
Either way, say in the report what you changed and tell the user to fix
`commands.test` in `project.yaml` — never edit `project.yaml` without asking.
`<Project>.` in the filter is the root the tests are named under: the project
name, or the distinct root `/setup-engine` chose when the project's name is
also an engine area — read one test's name string under
`Source/*/Private/Tests/` if unsure.
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Binaries/Linux/UnrealEditor" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
```
**macOS has no sourced test command.** Epic documents only the
`UnrealEditor.app` bundle, not a command-line editor inside it. Run a
`commands.test` the user has set and confirmed; with none, report
`NOT ASSESSED — Unreal test command on macOS not sourced; set commands.test to the editor command you use`
instead of guessing a path.
Read the output, not the exit code: a failing test and a run that matched nothing both exit 255.
- `Result={Fail}` on any line → FAIL.
- `No automation tests matched` → `NOT ASSESSED — no tests found` (tests
  outside `Source/<Module>/` are never built), not FAIL.
- Exit 0 with `Result={Success}` lines → PASS.
- Any other non-zero exit (`Project file not found`, `The game module … could
  not be found`) → FAIL: no test ran. The exception: the editor never started (exit 126 or 127, `command not found`) — that is the runner not being
  available, below, and `NOT ASSESSED`.

**用 `uname -s` 为本机选择命令**：`Linux` → Linux，
`Darwin` → macOS，其他任何值（`MINGW*`、`MSYS*`、`CYGWIN*`）→ Windows。
下面的 Windows 写法已在 UE 5.7 上运行过；Linux 和 macOS 的写法来自
Epic 的文档 —— `docs/engine-reference/unreal/current-best-practices.md` 的
"Command Line" 中给出了这些命令及其出处。在 Windows 上使用
`UnrealBuildTool.exe`，而不是 `Build.bat`：从 bash 运行 `Build.bat` 时，
引擎路径中若有空格会导致失败。
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# macOS (timeout: see the macOS note above)
gtimeout 1800 "<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
```
然后运行默认命令。保留 `-stdout -FullStdOutLogOutput`；当 `commands.test`
缺少它们时，仅为本次运行将其加入命令：没有它们，编辑器
不会打印任何内容，下列内容只存在于 `Saved/Logs/<Project>.log` 中。
将项目作为**绝对**路径传入 —— 当 `commands.test` 传入的是
相对路径时，改用绝对路径运行它：UE 5.7
找不到相对的 `<Project>.uproject`，会以 1 退出（`Project file not
found`）。`$(pwd -W 2>/dev/null || pwd)` 在 Git Bash 中给出 `C:/…` 形式，
在其他环境中给出普通路径；当设置了 `MSYS_NO_PATHCONV` 时，单用 `$PWD` 会失败。
无论哪种情况，都要在报告中说明你改了什么，并告知用户去修正
`project.yaml` 中的 `commands.test` —— 未经询问绝不要编辑 `project.yaml`。
过滤器中的 `<Project>.` 是测试命名所用的根：项目
名称，或者当项目名称本身也是引擎领域时 `/setup-engine` 选择的独立根 ——
如果不确定，可在 `Source/*/Private/Tests/` 下读取某个测试的命名字符串。
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Binaries/Linux/UnrealEditor" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
```
**macOS 没有可依据的测试命令。** Epic 只记录了
`UnrealEditor.app` 包，而没有记录其中的命令行编辑器。请运行用户已设置并
确认过的 `commands.test`；若没有，则报告
`NOT ASSESSED — Unreal test command on macOS not sourced; set commands.test to the editor command you use`，
而不要猜测一个路径。
读取输出，而不是退出码：失败的测试和没有匹配到任何测试的运行都会以 255 退出。
- 任意一行出现 `Result={Fail}` → FAIL。
- `No automation tests matched` → `NOT ASSESSED — no tests found`
  （`Source/<Module>/` 之外的测试永远不会被构建），而不是 FAIL。
- 退出码 0 且出现 `Result={Success}` 行 → PASS。
- 任何其他非零退出码（`Project file not found`、`The game module … could
  not be found`）→ FAIL：没有测试运行。例外：编辑器从未启动（退出码 126 或 127，`command not found`）——
  那属于下方所说的运行器不可用，结论为 `NOT ASSESSED`。

**Unknown engine / not configured:**
"Engine not configured in `project.yaml` or
`.claude/docs/technical-preferences.md`. Run `/setup-engine` to specify the
engine, then re-run `/smoke-check`."

**未知引擎 / 未配置：**
"Engine not configured in `project.yaml` or
`.claude/docs/technical-preferences.md`. Run `/setup-engine` to specify the
engine, then re-run `/smoke-check`."

**If the test runner is not available in this environment** (no editor
executable resolved in Phase 1 step 3, runner script not found, etc.), report
clearly:

**如果此环境中测试运行器不可用**（Phase 1 第 3 步未解析出编辑器
可执行文件、未找到运行器脚本等），请清晰地报告：

"Automated tests could not be executed — engine executable not found (checked
`commands.test`, `engine.path` and `PATH`; set `engine.path`, or put the
editor's full path in `commands.test`). Status will be recorded as NOT RUN.
Confirm test results from your local IDE
or CI pipeline. Until you do, the verdict is NOT ASSESSED — not FAIL, and not
a pass either: nothing has been observed about this build yet."

"Automated tests could not be executed — engine executable not found (checked
`commands.test`, `engine.path` and `PATH`; set `engine.path`, or put the
editor's full path in `commands.test`). Status will be recorded as NOT RUN.
Confirm test results from your local IDE
or CI pipeline. Until you do, the verdict is NOT ASSESSED — not FAIL, and not
a pass either: nothing has been observed about this build yet."

Do not treat NOT RUN as an automatic FAIL. Record it, and let the developer's
manual confirmation in Phase 4 resolve it. Until that confirmation arrives the
verdict is **NOT ASSESSED** (see the verdict rules in Phase 5), which ranks
above both pass values and below FAIL. An unrun suite is not a healthy build; it
is an unknown one, and the two need different follow-ups.

不要把 NOT RUN 当作自动 FAIL。记录它，并让开发者在 Phase 4 中的
人工确认来解决它。在该确认到达之前，结论为 **NOT ASSESSED**（参见 Phase 5
中的结论规则），它排在两个通过值之上、FAIL 之下。未运行的套件不是健康的构建；
它是一个未知的构建，两者需要不同的后续处理。

Parse runner output and extract:
- Total tests run
- Passing count
- Failing count
- Names of any failing tests (up to 10; if more, note the count)
- Any crash or error output from the runner itself

解析运行器输出并提取：
- 运行的测试总数
- 通过数量
- 失败数量
- 任何失败测试的名称（最多 10 个；若更多，注明数量）
- 运行器自身产生的任何崩溃或错误输出

**Build check — the WAIVED path only** (`qa.level: minimal`, no game tests;
Phase 1 step 1). With no suite to run, run the project's own boot check:
`commands.smoke` when set, else `commands.build` when set, with the executable
Phase 1 step 3 resolved, under the same timeout rules (`timeout 900`, or
`timeout 1800` for `commands.build`; a timeout is a FAIL). On Godot, run the
import line above first. Read the result as `/setup-engine` documents it:
Godot `smoke` exits 0 even on a parse error, so a `SCRIPT ERROR` line in its
output is a FAIL, and so is `Can't run project: no main scene defined` — the
game cannot launch; Unity `smoke` exits 1 on a compile error; any other
non-zero exit is a FAIL. Record `Build check: PASS — [command] exit 0`,
`FAIL — [reason]`, or `NOT RUN — [commands.smoke and commands.build unset |
executable not found]`. A build check that did not run is named in the report
and leaves the launch in Batch 1 to carry the verdict; it never passes on its
own.

**构建检查 —— 仅 WAIVED 路径**（`qa.level: minimal`，无游戏测试；
Phase 1 第 1 步）。没有可运行的套件时，运行项目自身的启动检查：
若设置了 `commands.smoke` 则运行它，否则若设置了 `commands.build` 则运行它，
使用 Phase 1 第 3 步解析出的可执行文件，遵循相同的超时规则（`timeout 900`，
或对 `commands.build` 使用 `timeout 1800`；超时即为 FAIL）。在 Godot 上，
先运行上面的导入行。按 `/setup-engine` 的文档说明读取结果：
Godot 的 `smoke` 即使在解析错误时也以 0 退出，因此其输出中的 `SCRIPT ERROR`
行即为 FAIL，`Can't run project: no main scene defined` 同理 ——
游戏无法启动；Unity 的 `smoke` 在编译错误时以 1 退出；任何其他
非零退出码均为 FAIL。记录 `Build check: PASS — [command] exit 0`、
`FAIL — [reason]`，或 `NOT RUN — [commands.smoke and commands.build unset |
executable not found]`。未运行的构建检查会在报告中注明，
并把结论交由 Batch 1 中的启动检查来承载；它本身永远不会判为通过。

---
