# /setup-engine — Section 3: Look Up Current Version

# /setup-engine — 第 3 节：查询当前版本

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 3. Look Up Current Version

Once the engine is chosen:

- If version was provided, use it
- If no version provided, use WebSearch to find the latest stable release:
  - Search: `"[engine] latest stable version [current year]"`
  - Confirm with the user: "The latest stable [engine] is [version]. Use this?"

## 3. 查询当前版本

选定引擎之后：

- 如果已提供版本，则使用它
- 如果未提供版本，则用 WebSearch 查找最新的稳定版本：
  - 搜索：`"[engine] latest stable version [current year]"`
  - 与用户确认："最新的稳定版 [engine] 是 [version]。使用它吗？"

### Check the chosen version against what is actually installed

A version found by web search is what exists, not what the developer has. Pinning
one they cannot run means every later instruction — build, test, smoke, the
engine reference docs — targets an engine that is not on the machine.

Probe for the binary (Bash), and treat failure as unknown, never as absent:

| Engine | Probe |
|--------|-------|
| Godot | `godot --version`, else look for `godot`/`Godot_v*` on PATH or in the platform's usual install location (macOS: the binary inside the bundle, `Godot.app/Contents/MacOS/Godot`) |
| Unity | The Hub's editor directory, then that editor's `-version` — `C:/Program Files/Unity/Hub/Editor/<version>/Editor/Unity.exe` on Windows, `/Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity` on macOS, `/home/<user>/Unity/Hub/Editor/<version>/Editor/Unity` on Linux. Not bare `Unity`: on `PATH` it may be Unity's separate CLI, which rejects `-version` |
| Unreal | The launcher's install directory (`UE_<version>` folders under `C:/Program Files/Epic Games/` on Windows); elsewhere, ask where the engine was built or installed. The editor is not on `PATH` by default |

### 将所选版本与实际安装的版本进行核对

网页搜索找到的版本是"存在的版本"，而非"开发者拥有的版本"。固定一个他们无法运行的
版本，意味着之后每一条指令 —— 构建、测试、冒烟、引擎参考文档 —— 都指向一台机器上
并不存在的引擎。

探测该二进制文件（Bash），并把探测失败视为"未知"，绝不视为"不存在"：

| 引擎 | 探测方式 |
|--------|-------|
| Godot | `godot --version`，否则在 PATH 或平台常用安装位置中查找 `godot`/`Godot_v*`（macOS：bundle 内的二进制，`Godot.app/Contents/MacOS/Godot`） |
| Unity | Hub 的编辑器目录，然后是那个编辑器的 `-version` —— Windows 上为 `C:/Program Files/Unity/Hub/Editor/<version>/Editor/Unity.exe`，macOS 上为 `/Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity`，Linux 上为 `/home/<user>/Unity/Hub/Editor/<version>/Editor/Unity`。不要用裸 `Unity`：它在 `PATH` 上可能是 Unity 单独的 CLI，会拒绝 `-version` |
| Unreal | 启动器的安装目录（Windows 上 `C:/Program Files/Epic Games/` 下的 `UE_<version>` 文件夹）；在其他平台，询问引擎是在哪里构建或安装的。编辑器默认不在 `PATH` 上 |

Keep the executable the probe found (for Godot, whether bare `godot --version`
ran — that is, `godot` is on `PATH`): Section 5.5.1 writes it into `commands.*`
and `engine.path`.

保留探测找到的可执行文件（对 Godot 而言，即裸 `godot --version` 是否运行过 ——
也就是说，`godot` 是否在 `PATH` 上）：第 5.5.1 节会把它写入 `commands.*`
和 `engine.path`。

Then:
- **Match** — say so in one line and continue.
- **Mismatch** — state both versions and ask, offering three options: pin the
  installed version, pin the newer one and upgrade later, or pin the newer one
  deliberately. Record the answer; do not pick silently.
- **Not found / probe failed** — report `installed version NOT DETERMINED` and
  continue with the chosen version. Do **not** report this as "no engine
  installed": a probe that could not run has not established absence.

然后：
- **一致** —— 用一行说明并继续。
- **不一致** —— 说明两个版本并询问，提供三个选项：固定已安装的版本、固定较新的
  版本并稍后升级，或有意识地固定较新的版本。记录答案；不要悄悄自行决定。
- **未找到 / 探测失败** —— 报告 `installed version NOT DETERMINED`，并以所选版本
  继续。**不要**将其报告为"未安装引擎"：无法运行的探测并没有确认其不存在。

Whatever the outcome, write it into Section 7's `VERSION.md` as an
`Installed at pin time` row, so a later reader can tell a deliberate
version-ahead pin from an accident.

无论结果如何，都将其作为 `Installed at pin time` 行写入第 7 节的 `VERSION.md`，
以便后续读者能区分"有意超前固定版本"和"意外"。

---
