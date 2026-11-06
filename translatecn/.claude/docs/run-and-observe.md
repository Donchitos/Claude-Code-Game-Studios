# Run and Observe
# 运行与观察

Shared procedure for any skill that closes a story which changes something a
player can see. Used by `/dev-story` (Phase 6) and `/story-done` (Phase 3).
**A parse check is not a run, and a story nobody looked at does not close.**
This file explains how to look.
适用于任何关闭“改变玩家可见内容”的 story 的技能。由 `/dev-story`（Phase 6）
和 `/story-done`（Phase 3）使用。**解析检查不是运行，没人看过的 story 不算关闭。**
本文件解释如何去看。

`.claude/docs/coding-standards.md` is the authority for *what* evidence a story
needs. This file is the procedure for *producing* the visual half of it.
`.claude/docs/coding-standards.md` 是 story *需要什么*证据的权威来源。
本文件是*产出*其中视觉那一半的流程。

## The rule
## 规则

Every story that changes something player-observable is **launched and observed
before it closes**, and the observation is a **retained screenshot** in
`production/qa/evidence/`. Compiling proves the code loads. Tests prove the
logic. Neither proves the text fits in the box.
每个改变玩家可观察内容的 story 都在**关闭前被启动并观察**，
观察结果是一张**保留的截图**，位于
`production/qa/evidence/`。编译证明代码能加载。测试证明
逻辑。两者都不能证明文本能放进框里。

The agent can see images: Claude Code's `Read` tool renders a PNG. The whole
problem is getting a picture out of the engine unattended, and every supported
engine has a native way.
智能体可以看到图像：Claude Code 的 `Read` 工具会渲染 PNG。整个
问题在于无人值守地从引擎中取出图片，而每个受支持的
引擎都有原生的方法。

## The procedure
## 流程

1. **Launch windowed** at a fixed resolution — `1280x720` unless the project
   says otherwise — using `commands.run` from `project.yaml`. Never the
   headless / batch / null-RHI flag: those exist to *skip* rendering.
1. **以窗口模式启动**，固定分辨率 — `1280x720`，除非项目
   另有说明 — 使用 `project.yaml` 中的 `commands.run`。绝不要使用
   无头 / 批处理 / null-RHI 标志：它们的存在就是为了*跳过*渲染。
2. **Launch straight into the scene or map the story touched.** A feature that
   is only reachable through the main menu and three clicks is a feature the
   run will not reach. Stories should be written so their surface is reachable
   from a launch argument (a scene path, a map URL, a `--scene` flag).
2. **直接启动到 story 涉及的场景或地图。** 一个只能通过
   主菜单和三次点击才到达的功能，是本次运行无法到达的功能。
   Story 应写得让它的表层可以通过启动参数到达
   （场景路径、地图 URL、`--scene` 标志）。
3. **Wait, capture, quit.** Let the engine render real frames — 60 is a safe
   floor — capture one, and exit. Each engine's mechanism is below.
3. **等待、捕获、退出。** 让引擎渲染真实帧 — 60 帧是安全
   下限 — 捕获一帧，然后退出。各引擎的机制见下文。
4. **Look.** `Read` the PNG. Compare what is on screen to the acceptance
   criteria. Clipped text, an overflowing panel, a missing element, the wrong
   colour — these are defects, and this is the only step that finds them.
4. **看。** `Read` 该 PNG。将屏幕上的内容与验收
   标准对比。被裁剪的文本、溢出的面板、缺失的元素、错误的
   颜色 — 这些都是缺陷，而这是唯一能发现它们的步骤。
5. **Retain.** Capture straight into the story's evidence folder, so nothing
   needs copying: `mkdir -p production/qa/evidence/[story-slug]`, then pass
   `production/qa/evidence/[story-slug]/[NN]-[what-it-shows].png` as the capture
   path (Godot adds its frame number to the name). `[story-slug]` is the story
   file's name without `.md`: `story-003-light-pickup` for
   `production/epics/core/story-003-light-pickup.md`. Reference the image from
   the evidence doc. A screenshot that was taken and discarded is an
   assertion, not evidence. Beside it, stamp the files it proves:
   `bash .claude/scripts/review-receipts.sh hash <each file the story changed> > production/qa/evidence/[story-slug]/stamp.txt`.
   A later edit to one of them then shows the evidence as older than the code.
5. **保留。** 直接捕获到 story 的证据文件夹，这样就不需要
   复制：`mkdir -p production/qa/evidence/[story-slug]`，然后传递
   `production/qa/evidence/[story-slug]/[NN]-[what-it-shows].png` 作为捕获
   路径（Godot 会把帧号添加到名称中）。`[story-slug]` 是 story
   文件名去掉 `.md`：`production/epics/core/story-003-light-pickup.md` 对应
   `story-003-light-pickup`。从证据文档中引用该图像。截取后丢弃的截图
   只是断言，不是证据。在它旁边，盖章证明它所证明的文件：
   `bash .claude/scripts/review-receipts.sh hash <each file the story changed> > production/qa/evidence/[story-slug]/stamp.txt`。
   之后对其中一个文件的编辑就会显示证据比代码更旧。
6. **Report** one `Run result:` line in the implementation summary — vocabulary
   below.
6. **报告** 在实现摘要中写一行 `Run result:` — 词汇
   见下文。

## Per engine
## 各引擎

| `engine.name` | Launch | Capture | Output lands in | Never use | Scaffold needed |
|---|---|---|---|---|---|
| Godot 4 | `godot --path . --windowed --resolution 1280x720 <scene>.tscn` | `--write-movie <path>.png --quit-after <N>` | beside the given path, `<name>00000000.png` … | `--headless` | **none** |
| Unity 6 | built player `.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene <Name>` | `ScreenCapture.CaptureScreenshot(<abs path>)` from a bootstrap script | the absolute path you pass | `-batchmode`, `-nographics` | one MonoBehaviour |
| Unreal 5 | `MSYS_NO_PATHCONV=1 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<Game>.uproject" <MapURL> -game -windowed -ResX=1280 -ResY=720` | `HighResShot 1280x720 filename=<abs path>` console command | the path you pass (else `Saved/Screenshots/WindowsEditor/`) | `-nullrhi`, `-unattended` alone | one actor or `-ExecCmds` |

| `engine.name` | 启动 | 捕获 | 输出落在 | 绝不使用 | 需要的脚手架 |
|---|---|---|---|---|---|
| Godot 4 | `godot --path . --windowed --resolution 1280x720 <scene>.tscn` | `--write-movie <path>.png --quit-after <N>` | 给定路径旁边，`<name>00000000.png` … | `--headless` | **无** |
| Unity 6 | 构建出的玩家 `.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene <Name>` | 从引导脚本调用 `ScreenCapture.CaptureScreenshot(<abs path>)` | 你传入的绝对路径 | `-batchmode`、`-nographics` | 一个 MonoBehaviour |
| Unreal 5 | `MSYS_NO_PATHCONV=1 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<Game>.uproject" <MapURL> -game -windowed -ResX=1280 -ResY=720` | `HighResShot 1280x720 filename=<abs path>` 控制台命令 | 你传入的路径（否则为 `Saved/Screenshots/WindowsEditor/`） | `-nullrhi`、单独使用 `-unattended` | 一个 actor 或 `-ExecCmds` |

### Godot 4 — zero scaffold
### Godot 4 — 零脚手架

```
godot --path . --windowed --resolution 1280x720 --write-movie shots/shop.png --quit-after 60 res://scenes/shop.tscn
```

`--write-movie` is Movie Maker mode: with a `.png` target it writes a frame
sequence and `--quit-after` sets the frame count. Filenames carry **8**
zero-padded digits — `shop00000000.png` through `shop00000059.png` — so take the
last; a `shop.wav` lands beside them. `--fixed-fps` is applied automatically. The
scene path is positional; any `.tscn` can be launched directly, which is how step
2 is satisfied. The frames are recorded at the project's viewport size
(`display/window/size/viewport_width` and `_height`, 1152x648 when unset), not at
`--resolution`, which only sizes the window; the log's `recording movie in
<W>×<H>` line says which. The capture-on-trigger alternative below saves at the
window size.
`--write-movie` 是 Movie Maker 模式：以 `.png` 为目标时，它会写入帧
序列，`--quit-after` 设置帧数。文件名带 **8** 位
零填充数字 — `shop00000000.png` 到 `shop00000059.png` — 所以取
最后一张；`shop.wav` 会落在它们旁边。`--fixed-fps` 自动应用。
场景路径是位置参数；任何 `.tscn` 都可以直接启动，这就是步骤
2 得到满足的方式。帧按项目的视口尺寸记录
（`display/window/size/viewport_width` 和 `_height`，未设置时为 1152x648），
而不是按 `--resolution`，后者只决定窗口大小；日志中的 `recording movie in
<W>×<H>` 行会说明是哪一种。下面的触发器捕获替代方案按
窗口尺寸保存。

Capture-on-trigger alternative, for a state a scene launch cannot reach: an
autoload that on the wanted condition does
`await RenderingServer.frame_post_draw`, then
`get_viewport().get_texture().get_image().save_png(path)`, then
`get_tree().quit()`.
触发器捕获替代方案，适用于场景启动无法到达的状态：
一个 autoload，在所需条件满足时执行
`await RenderingServer.frame_post_draw`，然后
`get_viewport().get_texture().get_image().save_png(path)`，然后
`get_tree().quit()`。

### Unity 6 — one MonoBehaviour
### Unity 6 — 一个 MonoBehaviour

`-batchmode` displays nothing, so the run is either the **built player** or the
editor in play mode. The player is the robust path:
`-batchmode` 不显示任何内容，所以运行要么是**构建出的玩家**，要么是
播放模式下的编辑器。玩家是稳健的路径：

```
Builds/Win64/Game.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene Shop --screenshot C:/abs/path/shop.png --after 60
```

`-screen-*` are Unity's own player arguments. `--scene`, `--screenshot` and
`--after` are **yours**, read by the script below. The template does not ship
it: the first time a Unity story needs a screenshot, `/dev-story` asks to write
it, verbatim, to `Assets/Scripts/ScreenshotOnArg.cs`. It needs no scene edit — it boots itself, and does nothing unless the player
was launched with `--screenshot`:
`-screen-*` 是 Unity 自己的玩家参数。`--scene`、`--screenshot` 和
`--after` 是**你的**，由下面的脚本读取。模板不附带
它：第一次 Unity story 需要截图时，`/dev-story` 请求将它
逐字写入 `Assets/Scripts/ScreenshotOnArg.cs`。它不需要编辑场景 — 它会自行启动，并且除非玩家
以 `--screenshot` 启动，否则什么都不做：

```csharp
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

// Run-and-observe capture: Game.exe --scene Shop --screenshot C:/abs/shop.png --after 60
public class ScreenshotOnArg : MonoBehaviour
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot()
    {
        if (Arg("--screenshot") == null) return;
        var go = new GameObject(nameof(ScreenshotOnArg));
        DontDestroyOnLoad(go);
        go.AddComponent<ScreenshotOnArg>();
    }

    static string Arg(string name)
    {
        var args = System.Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
            if (args[i] == name) return args[i + 1];
        return null;
    }

    IEnumerator Start()
    {
        var scene = Arg("--scene");
        if (!string.IsNullOrEmpty(scene)) yield return SceneManager.LoadSceneAsync(scene);
        int after = int.TryParse(Arg("--after"), out var n) ? n : 60;
        for (int i = 0; i < after; i++) yield return null;
        yield return new WaitForEndOfFrame();
        ScreenCapture.CaptureScreenshot(Arg("--screenshot"));
        for (int i = 0; i < 3; i++) yield return null;   // the file is written after the frame
        Application.Quit();
    }
}
```

Pass an **absolute** path — the relative base differs between editor and
player. `--scene` must be in the build settings. Building the player first
costs 1–3 minutes on a small project; that is the price of looking at the thing
you ship rather than the editor.
传入**绝对**路径 — 相对基准在编辑器和
玩家之间不同。`--scene` 必须在构建设置中。先构建玩家
在小型项目上要花 1–3 分钟；这就是看你所交付的东西
而不是编辑器的代价。

### Unreal 5 — one actor, or `-ExecCmds`
### Unreal 5 — 一个 actor，或 `-ExecCmds`

```
MSYS_NO_PATHCONV=1 timeout 60 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/Game.uproject" /Game/Maps/Shop -game -windowed -ResX=1280 -ResY=720
```

That line is Windows'. On Linux the same arguments go to
`"<UE root>/Engine/Binaries/Linux/UnrealEditor"` (no `MSYS_NO_PATHCONV` needed);
on macOS Epic documents only the `UnrealEditor.app` bundle, so run the map from
the editor or a command you have confirmed (see
`docs/engine-reference/unreal/current-best-practices.md`, "Command Line").
那一行是 Windows 的。在 Linux 上，同样的参数传给
`"<UE root>/Engine/Binaries/Linux/UnrealEditor"`（不需要 `MSYS_NO_PATHCONV`）；
在 macOS 上 Epic 只记录了 `UnrealEditor.app` 包，所以从
编辑器或你已确认的命令运行地图（参见
`docs/engine-reference/unreal/current-best-practices.md` 的 "Command Line"）。

`-game` runs standalone without the editor UI. The map is a **positional URL
immediately after the `.uproject`** — not a console command. **The
`MSYS_NO_PATHCONV=1` prefix is required on Windows:** Claude Code runs commands
in Git Bash, which rewrites any argument beginning with `/` as a Windows path, so
`/Game/Maps/Shop` reaches the engine as `C:/Program Files/Git/Game/Maps/Shop`
and the game stops on a "map not found" dialog nobody can see. Alternatively
pass the map through `-ExecCmds="open /Game/Maps/Shop"`, which is not converted.
**The project path must be absolute** — with `MSYS_NO_PATHCONV` set, only
`$(pwd -W 2>/dev/null || pwd)` gives one: a relative `Game.uproject` is not
found, and the launch waits on an error dialog forever (verified on 5.7). There
is no `-unattended` on this line, so every failure is a dialog nobody clicks:
always run it under `timeout`. Capture is the
`HighResShot` console command, fired either from a dev actor (`Execute Console
Command` on BeginPlay after a short delay, then `quit`) or from the launch line:
`-game` 独立运行，不需要编辑器 UI。地图是**紧跟在 `.uproject`
之后的位置 URL** — 不是控制台命令。**在 Windows 上必须加
`MSYS_NO_PATHCONV=1` 前缀：** Claude Code 在 Git Bash 中运行命令，
Git Bash 会把任何以 `/` 开头的参数重写为 Windows 路径，所以
`/Game/Maps/Shop` 会以 `C:/Program Files/Git/Game/Maps/Shop` 的形式到达引擎，
游戏会停在没人能看到的“找不到地图”对话框上。或者
通过 `-ExecCmds="open /Game/Maps/Shop"` 传递地图，它不会被转换。
**项目路径必须是绝对的** — 设置 `MSYS_NO_PATHCONV` 后，只有
`$(pwd -W 2>/dev/null || pwd)` 能给出一个：相对路径的 `Game.uproject` 找不到，
启动会永远等待一个错误对话框（在 5.7 上验证）。这一行
没有 `-unattended`，所以每次失败都是一个没人点击的对话框：
始终在 `timeout` 下运行它。捕获是
`HighResShot` 控制台命令，既可以由开发 actor 触发（在短暂延迟后的 BeginPlay 中
`Execute Console Command`，然后 `quit`），也可以从启动行触发：

```
-ExecCmds="HighResShot 1280x720 filename=C:/abs/path/shop.png"
```

The size (or a multiplier such as `2`) comes **before** `filename=`:
`HighResShot filename=…` alone is rejected as bad input and saves nothing.
Without `filename=` the file lands in `Saved/Screenshots/WindowsEditor/`.
**Do not put `Quit` in the same `-ExecCmds` list** — it runs on the same
frame, before the file is written, and leaves nothing on disk. `-ExecCmds` has
no delay, so let `timeout` end the launch (exit 124 is expected) and check the
file exists; a dev actor can instead wait a second, then `quit`. The Blueprint node `Take High Res Screenshot` is editor-only and
does not work in a `-game` launch.
尺寸（或诸如 `2` 的乘数）在 `filename=` **之前**：
单独的 `HighResShot filename=…` 会作为错误输入被拒绝，什么也保存不了。
没有 `filename=` 时，文件落在 `Saved/Screenshots/WindowsEditor/`。
**不要把 `Quit` 放在同一个 `-ExecCmds` 列表中** — 它会在同一帧
运行，在文件写入之前，磁盘上什么也不会留下。`-ExecCmds` 没有
延迟，所以让 `timeout` 结束启动（预期退出码 124）并检查
文件是否存在；开发 actor 则可以等待一秒，然后 `quit`。蓝图节点 `Take High Res Screenshot` 仅限编辑器，
在 `-game` 启动中不起作用。

### Any engine — OS capture fallback
### 任何引擎 — 操作系统捕获回退

On Windows, PowerShell with `System.Drawing` can `CopyFromScreen` into a bitmap
and save it. It needs a visible desktop and the game window on top, and it
captures whatever is there — it cannot be told "the shop panel". Use it when the
engine-native path is unavailable, and say so in the run result. Linux CI with
no display needs `xvfb-run` in front of the launch; `--headless` is not a
substitute.
在 Windows 上，带有 `System.Drawing` 的 PowerShell 可以 `CopyFromScreen` 到
位图并保存它。它需要可见的桌面和置于顶层的游戏窗口，而且它
捕获那里的一切 — 无法告诉它“商店面板”。在引擎原生路径
不可用时使用它，并在运行结果中说明。没有显示器的 Linux CI 需要在
启动前加 `xvfb-run`；`--headless` 不是
替代品。

## The `Run result:` line
## `Run result:` 行

Exactly one of three shapes, in the implementation summary:
三种形态中的恰好一种，写在实现摘要中：

- **`Run result: OBSERVED — <what was on screen, one line>`** with the retained
  path. *"Shop panel renders, all 6 slots inside the frame, prices legible at
  720p — `production/qa/evidence/shop-panel/01-shop-open.png`."*
- **`Run result: OBSERVED — <屏幕上有什么，一行>`**，附保留
  路径。*“商店面板渲染，全部 6 个槽位在帧内，720p 下价格可读 —
  `production/qa/evidence/shop-panel/01-shop-open.png`。”*
- **`Run result: NOT VERIFIED — <reason>`**. Engine binary not found,
  `commands.run` unset, launch crashed, screenshot empty. This is a **blocker**
  at the default gate level for Visual/Feel and UI stories, not a note — a
  story nobody looked at does not close. Under an explicit
  `testing.strict.visual`/`.ui: false` it is recorded and the story may close
  with the gap in `## Completion Notes`.
- **`Run result: NOT VERIFIED — <原因>`**。引擎二进制未找到、
  `commands.run` 未设置、启动崩溃、截图为空。在 Visual/Feel 和 UI story 的
  默认门禁级别下，这是**阻塞项**，不是备注 —
  没人看过的 story 不算关闭。在明确的
  `testing.strict.visual`/`.ui: false` 下，它会被记录，story 可以在
  `## Completion Notes` 中留有缺口的情况下关闭。
- **`Run result: N/A — <reason>`**, only for a story with genuinely nothing
  observable — a pure data migration, a save-format change with no surface.
  Say why. "It's a Logic story" is not a reason: a damage formula has a number
  on screen somewhere.
- **`Run result: N/A — <原因>`**，仅用于确实没有任何
  可观察内容的 story — 纯数据迁移、没有表层的存档格式变更。
  说明原因。“这是一个 Logic story”不是理由：伤害公式在某处
  屏幕上有一个数字。

The run is **not waived at `qa.level: minimal`**. Tests are waived there; the
look is not. It is the cheapest verification in the pipeline and the one
whose absence produces a well-tested game that looks wrong.
该运行**在 `qa.level: minimal` 时不豁免**。测试在那里豁免；
观察不豁免。它是流程中最便宜的验证，也是
缺失时会产生一个测试完善但外观错误的游戏的那一项。

## What a still can and cannot show
## 静帧能显示和不能显示的内容

**Can:** layout, clipping, overflow, presence, alignment, colour, legibility,
that the right screen appeared at all. This is where shipped visual defects
actually live.
**能：** 布局、裁剪、溢出、存在性、对齐、颜色、可读性、
正确的屏幕是否出现。这正是已交付视觉缺陷
实际所在之处。

**Cannot:** timing, responsiveness, weight, animation curves, audio sync — the
"feel" half of Visual/Feel. Godot's `--write-movie` gives a frame sequence; the
other engines need OS video capture. Feel stays a human check in `/team-qa`.
Say which half the screenshot covered.
**不能：** 时序、响应性、重量感、动画曲线、音频同步 — Visual/Feel 的
“手感”那一半。Godot 的 `--write-movie` 给出帧序列；
其他引擎需要操作系统视频捕获。手感在 `/team-qa` 中仍是人工检查。
说明截图覆盖了哪一半。

## Reaching the state
## 到达该状态

A screenshot of the title screen verifies nothing about depth 2. Either launch
the scene/map directly (Godot scene arg, Unreal map URL, Unity `--scene`) or
give the bootstrap a debug argument that sets state (`--gold=500 --depth=2`).
Write stories so their surface is reachable one of those ways; a story that is
not is a story that will be marked `NOT VERIFIED` every time.
标题画面的截图对第 2 层什么都验证不了。要么直接启动
场景/地图（Godot 场景参数、Unreal 地图 URL、Unity `--scene`），要么
给引导脚本一个设置状态的调试参数（`--gold=500 --depth=2`）。
编写 story 时要让其表层能通过上述任一方式到达；不能到达的 story
是每次都会被标记为 `NOT VERIFIED` 的 story。

## Finding the engine
## 找到引擎

None of the three engines installs onto `PATH` on Windows. `engine.path` in
`project.yaml` is where the editor lives; resolve it before concluding "no
engine on this machine". Absence of a path is not absence of an engine.
这三个引擎在 Windows 上都不会安装到 `PATH`。`project.yaml` 中的 `engine.path`
是编辑器所在位置；在得出“这台机器上没有引擎”的结论之前先解析它。
路径缺失并不等于引擎缺失。

---

*Commands above were run on Windows with Godot 4.6.1 (gdUnit4 6.1.3) and the
Godot ones again on 4.7.2 (gdUnit4 6.2.2), Unity
6000.3.23f1 and Unreal Engine 5.7; the Unreal Linux and macOS notes come from
Epic's documentation. `docs/engine-reference/<engine>/` is
the project's pinned authority; check it before trusting a version-qualified
claim here.*
*上述命令在 Windows 上以 Godot 4.6.1（gdUnit4 6.1.3）运行，Godot 相关命令
又在 4.7.2（gdUnit4 6.2.2）、Unity
6000.3.23f1 和 Unreal Engine 5.7 上运行；Unreal 的 Linux 和 macOS 说明来自
Epic 的文档。`docs/engine-reference/<engine>/` 是
项目固定的权威来源；在信任此处任何带版本限定的说法之前先检查它。*
