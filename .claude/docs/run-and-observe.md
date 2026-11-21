# Run and Observe

Shared procedure for any skill that closes a story which changes something a
player can see. Used by `/dev-story` (Phase 6) and `/story-done` (Phase 3).
**A parse check is not a run, and a story nobody looked at does not close.**
This file explains how to look.

`.claude/docs/coding-standards.md` is the authority for *what* evidence a story
needs. This file is the procedure for *producing* the visual half of it.

## The rule

Every story that changes something player-observable is **launched and observed
before it closes**, and the observation is a **retained screenshot** in
`production/qa/evidence/`. Compiling proves the code loads. Tests prove the
logic. Neither proves the text fits in the box.

The agent can see images: Claude Code's `Read` tool renders a PNG. The whole
problem is getting a picture out of the engine unattended, and every supported
engine has a native way.

## The procedure

1. **Launch windowed** at a fixed resolution — `1280x720` unless the project
   says otherwise — using `commands.run` from `project.yaml`. Never the
   headless / batch / null-RHI flag: those exist to *skip* rendering. The one
   exception is a browser game: headless Chrome and Edge render real frames
   (the Web row below).
2. **Launch straight into the scene or map the story touched.** A feature that
   is only reachable through the main menu and three clicks is a feature the
   run will not reach. Stories should be written so their surface is reachable
   from a launch argument (a scene path, a map URL, a `--scene` flag).
3. **Wait, capture, quit.** Let the engine render real frames — 60 is a safe
   floor — capture one, and exit. Each engine's mechanism is below.
4. **Look.** `Read` the PNG. Compare what is on screen to the acceptance
   criteria. Clipped text, an overflowing panel, a missing element, the wrong
   colour — these are defects, and this is the only step that finds them.
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
6. **Report** one `Run result:` line in the implementation summary — vocabulary
   below.

## Per engine

| `engine.name` | Launch | Capture | Output lands in | Never use | Scaffold needed |
|---|---|---|---|---|---|
| Godot 4 | `godot --path . --windowed --resolution 1280x720 <scene>.tscn` | `--write-movie <path>.png --quit-after <N>` | beside the given path, `<name>00000000.png` … | `--headless` | **none** |
| Unity 6 | built player `.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene <Name>` | `ScreenCapture.CaptureScreenshot(<abs path>)` from a bootstrap script | the absolute path you pass | `-batchmode`, `-nographics` | one MonoBehaviour |
| Unreal 5 | `MSYS_NO_PATHCONV=1 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<Game>.uproject" <MapURL> -game -windowed -ResX=1280 -ResY=720` | `HighResShot 1280x720 filename=<abs path>` console command | the path you pass (else `Saved/Screenshots/WindowsEditor/`) | `-nullrhi`, `-unattended` alone | one actor or `-ExecCmds` |
| Web (a browser game) | `bash .claude/scripts/page-shot.sh <page>.html <path>.png --query <state>`; a web project's page is `dist-single/index.html`, after `npm run build:single` | the same command: headless Chrome, Edge or Chromium | the path you pass | `commands.run` (a dev server) | **none** |

### Web — headless Chrome or Edge

```
bash .claude/scripts/page-shot.sh index.html production/qa/evidence/shop-panel/01-shop-open.png --query scene=shop --wait 2000
```

**A web project (`engine.name: Web`)** is shot from its single-file build, never
from the dev server (`commands.run` never exits): `npm run build:single`, then
`page-shot.sh dist-single/index.html <path>.png --query <state>`. A page opened
from disk cannot load the folder build's module script; the single file has
everything inlined. A one-shot is shot as it is, from its own `index.html`. An
existing project with no `build:single` (`/setup-engine web`, W1) is shot from
its own build's `index.html` with `--file-access`, so its module scripts and its
own image and data loads work from disk; a build that asks for files from the
root (`/assets/…`, Vite's default `base`) still cannot run from disk, and that
look is `NOT VERIFIED`.

Headless is allowed here and only here: a headless browser draws the page with
its real renderer, where an engine's headless mode swaps in a dummy one.
`--wait` is page time before the picture, so 2000 is two seconds of play. The
script prints the page's console and an `uncaught` count beside the picture;
with no browser found it prints `not_assessed`, which is `NOT VERIFIED`.
Reach the state with the address (`--query scene=shop`). The browser sets the
window to its final size just before the picture: a page that draws only once
must draw again on `resize`, or the picture is blank. WebGL uses the machine's
GPU; `--software` draws it in software (SwiftShader), the same with a GPU or
none, and is what the self-check's runs use. In software a 3D page that draws
every frame is about forty times slower. `--profile <dir>` keeps the browser profile, so a second run finds what the
page saved. A one-shot's small check plays a few scripted keys this way
(`/prototype`), a short run of minutes; how the game plays is the person's
check, not headless's.

### Godot 4 — zero scaffold

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

Capture-on-trigger alternative, for a state a scene launch cannot reach: an
autoload that on the wanted condition does
`await RenderingServer.frame_post_draw`, then
`get_viewport().get_texture().get_image().save_png(path)`, then
`get_tree().quit()`.

### Unity 6 — one MonoBehaviour

`-batchmode` displays nothing, so the run is either the **built player** or the
editor in play mode. The player is the robust path:

```
Builds/Win64/Game.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene Shop --screenshot C:/abs/path/shop.png --after 60
```

`-screen-*` are Unity's own player arguments. `--scene`, `--screenshot` and
`--after` are **yours**, read by the script below. The template does not ship
it: the first time a Unity story needs a screenshot, `/dev-story` asks to write
it, verbatim, to `Assets/Scripts/ScreenshotOnArg.cs`. It needs no scene edit — it boots itself, and does nothing unless the player
was launched with `--screenshot`:

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

### Unreal 5 — one actor, or `-ExecCmds`

```
MSYS_NO_PATHCONV=1 timeout 60 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/Game.uproject" /Game/Maps/Shop -game -windowed -ResX=1280 -ResY=720
```

That line is Windows'. On Linux the same arguments go to
`"<UE root>/Engine/Binaries/Linux/UnrealEditor"` (no `MSYS_NO_PATHCONV` needed);
on macOS Epic documents only the `UnrealEditor.app` bundle, so run the map from
the editor or a command you have confirmed (see
`docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

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

### Any engine — OS capture fallback

On Windows, PowerShell with `System.Drawing` can `CopyFromScreen` into a bitmap
and save it. It needs a visible desktop and the game window on top, and it
captures whatever is there — it cannot be told "the shop panel". Use it when the
engine-native path is unavailable, and say so in the run result. Linux CI with
no display needs `xvfb-run` in front of the launch; `--headless` is not a
substitute. Inside Claude Code's sandbox `xvfb-run` fails too: see below.

### Inside Claude Code's sandbox (Linux, WSL2)

With Claude Code's sandbox on, a shell command on Linux or WSL2 cannot open a
Unix socket, and a game window needs one to reach the screen. Godot stops with
`Unable to create DisplayServer, all display drivers failed`, an engine's window
is refused the same way, and Chrome stops with `socket() failed: Operation not
permitted`. That is the sandbox, not the game.

- **An engine:** run that one launch again outside the sandbox (the Bash tool's
  `dangerouslyDisableSandbox`). Claude Code asks you first, as for any command
  outside the sandbox; everything else stays inside it. Refused, or turned off
  with `allowUnsandboxedCommands: false`:
  `Run result: NOT VERIFIED — the sandbox refused the game's window`.
- **A web page:** `page-shot.sh` falls back to a headless shell, which runs in
  the sandbox. When it finds none, its `not_assessed` row says so: install one
  once, outside the sandbox, since it goes to your home folder:
  `npx playwright install chromium-headless-shell`. Then take the shot again.

## The `Run result:` line

Exactly one of three shapes, in the implementation summary:

- **`Run result: OBSERVED — <what was on screen, one line>`** with the retained
  path. *"Shop panel renders, all 6 slots inside the frame, prices legible at
  720p — `production/qa/evidence/shop-panel/01-shop-open.png`."*
- **`Run result: NOT VERIFIED — <reason>`**. Engine binary not found,
  `commands.run` unset, launch crashed, screenshot empty. This is a **blocker**
  at the default gate level for Visual/Feel and UI stories, not a note — a
  story nobody looked at does not close. Under an explicit
  `testing.strict.visual`/`.ui: false` it is recorded and the story may close
  with the gap in `## Completion Notes`.
- **`Run result: N/A — <reason>`**, only for a story with genuinely nothing
  observable — a pure data migration, a save-format change with no surface.
  Say why. "It's a Logic story" is not a reason: a damage formula has a number
  on screen somewhere.

The run is **not waived at `qa.level: minimal`**. Tests are waived there; the
look is not. It is the cheapest verification in the pipeline and the one
whose absence produces a well-tested game that looks wrong.

## What a still can and cannot show

**Can:** layout, clipping, overflow, presence, alignment, colour, legibility,
that the right screen appeared at all. This is where shipped visual defects
actually live.

**Cannot:** timing, responsiveness, weight, animation curves, audio sync — the
"feel" half of Visual/Feel. Godot's `--write-movie` gives a frame sequence; the
other engines need OS video capture. Feel stays a human check in `/team-qa`.
Say which half the screenshot covered.

## Reaching the state

A screenshot of the title screen verifies nothing about depth 2. Either launch
the scene/map directly (Godot scene arg, Unreal map URL, Unity `--scene`) or
give the bootstrap a debug argument that sets state (`--gold=500 --depth=2`).
Write stories so their surface is reachable one of those ways; a story that is
not is a story that will be marked `NOT VERIFIED` every time.

## Finding the engine

None of the three engines installs onto `PATH` on Windows. `engine.path` in
`project.yaml` is where the editor lives; resolve it before concluding "no
engine on this machine". Absence of a path is not absence of an engine.

---

*Commands above were run on Windows with Godot 4.6.1 (gdUnit4 6.1.3) and the
Godot ones again on 4.7.2 (gdUnit4 6.2.2), Unity
6000.3.23f1 and Unreal Engine 5.7; the Unreal Linux and macOS notes come from
Epic's documentation. `docs/engine-reference/<engine>/` is
the project's pinned authority; check it before trusting a version-qualified
claim here.*
